#include "polly/DependenceInfo.h"
#include "polly/PolyhedralInfo.h"
#include "polly/ScopInfo.h"
#include "polly/Support/GICHelper.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Pass.h"
#include "llvm/Support/Debug.h"
#include "isl/schedule.h"
#include "isl/schedule_node.h"
#include "polly/LinkAllPasses.h"

// 最终调度结构示意
// domain
//  └── band [bi, bj, bk]   ← 可并行（coincident）
//        └── band [i, j, k] ← 内部 tile
//              └── sequence / leaf


using namespace llvm;
using namespace polly;

#define DEBUG_TYPE "matmul-tiling"

namespace {
class MatMulTilingPass : public FunctionPass {
public:
  static char ID;
  MatMulTilingPass() : FunctionPass(ID) {}

  bool runOnFunction(Function &F) override {
    auto *SI = getAnalysis<ScopInfoWrapperPass>().getSI();
    auto &DI = getAnalysis<DependenceInfoWrapperPass>();
    auto &LI = getAnalysis<LoopInfoWrapperPass>().getLoopInfo();
    auto &PI = getAnalysis<PolyhedralInfo>();

    for (auto &It : *SI) {
      Scop *S = It.second.get();
      if (!S || S->isToBeSkipped())
        continue;

      LLVM_DEBUG(dbgs() << "Processing SCoP in region: " << It.first->getNameStr() << "\n");

      // 手动设置调度 { [i, j, k] -> [i, j, k] }
      // 获取当前 SCoP 的语句域
      isl::union_set Domain = S->getDomains();
      // assert(S->getSize() == 1 && "Expected only one statement (matmul)");


      // 从 union_set 中提取第一个 statement 的 isl::set（假设只有一个矩阵乘法语句）
      isl_set_list *List = isl_union_set_get_set_list(Domain.get());
      if (isl_set_list_n_set(List) == 0) {
        LLVM_DEBUG(dbgs() << "Error: SCoP has no statements.\n");
        return false;
      }
      // 取第一个语句对应的 set
      // isl::set OneStmt = isl::manage(isl_set_list_get_set(List, 0));
      isl::set OneStmt;
      for (int i = 0; i < isl_set_list_n_set(List); ++i) {
        isl::set SSet = isl::manage(isl_set_list_get_set(List, i));
        std::string Name = SSet.get_tuple_name();
        // if (Name.find("Stmt2") != std::string::npos || Name.find("Stmt") != std::string::npos) {
        //   OneStmt = SSet;
        //   break;
        // }

        // 保证是我们想要的矩阵乘法语句
        if (Name.find("Stmt") != std::string::npos &&
            isl_set_dim(SSet.get(), isl_dim_set) >= 3) {
            OneStmt = SSet;
            break;
        }
      }
      isl_set_list_free(List);// 手动释放 list，避免内存泄漏

      if (!OneStmt) {
        LLVM_DEBUG(dbgs() << "No suitable matmul statement found.\n");
        return false;
      }

      // 获取调度空间（例如 { [i,j,k] }）
      isl::space Space = OneStmt.get_space();

      // 构造恒等 schedule：Stmt[i,j,k] -> [i,j,k]
      isl::multi_aff MA = isl::multi_aff::identity(Space.map_from_set());

      // 构建 map（MA → map → union_map）
      isl::map Map = isl::map::from_multi_aff(MA);
      isl::union_map NewSchedule = isl::union_map(Map);

      // 将手动构造的原始调度设置到 SCoP 中
      S->setSchedule(NewSchedule); // 替换原调度

      // 获取新的 schedule tree
      isl::schedule Schedule = S->getScheduleTree();

      // 进入 domain -> band[i,j,k]
      // 从调度树根节点进入：domain → band[i,j,k]
      isl_schedule_node *Node = isl_schedule_get_root(Schedule.get());
      Node = isl_schedule_node_child(Node, 0);

      // 确保当前节点是 band 类型
      if (!Node || isl_schedule_node_get_type(Node) != isl_schedule_node_band) {
        LLVM_DEBUG(dbgs() << "Not a band node under domain\n");
        if (Node) isl_schedule_node_free(Node);
        continue;
      }

      // 获取当前 band 的维度数量
      unsigned NumDims = isl_schedule_node_band_n_member(Node);
      LLVM_DEBUG(dbgs() << "Number of band dimensions: " << NumDims << "\n");

      // 如果维度不足 3，则跳过
      if (NumDims < 3) {
        LLVM_DEBUG(dbgs() << "Less than 3 dims — cannot tile\n");
        isl_schedule_node_free(Node);
        continue;
      }

      // 设置 tile size = 32
      // 获取 band 的空间，用于构造 tile size
      isl_space *BandSpace = isl_schedule_node_band_get_space(Node);

      // 初始化 tile size = [0, 0, 0]
      isl_multi_val *TileSizes = isl_multi_val_zero(BandSpace);

      // 设置前 3 个维度的 tile size 为 32
      for (unsigned i = 0; i < 3; ++i) {
        isl_val *SizeVal = isl_val_int_from_si(S->getIslCtx().get(), 32);
        TileSizes = isl_multi_val_set_val(TileSizes, i, SizeVal);
      }

      // 应用 tiling 操作，Node 中 now 存的是 tiled 结构：[bi,bj,bk][i,j,k]
      Node = isl_schedule_node_band_tile(Node, TileSizes);
      if (!Node) {
        LLVM_DEBUG(dbgs() << "Tiling failed\n");
        continue;
      }

      // 进入外层块 band: [bi, bj, bk]
      // 进入外层 tile band（[bi, bj, bk]）
      Node = isl_schedule_node_child(Node, 0);
      bool IsPermutable = false;

      // 如果还是 band 节点，设置可并行性
      if (Node && isl_schedule_node_get_type(Node) == isl_schedule_node_band) {
        unsigned BlockDims = isl_schedule_node_band_n_member(Node);
        if (BlockDims >= 2) {
          // 设置外层 band 为可交换（permutable）
          Node = isl_schedule_node_band_set_permutable(Node, 1);

          // 标记 bi, bj 可并行（coincident）
          Node = isl_schedule_node_band_member_set_coincident(Node, 0, isl_bool_true); // bi
          Node = isl_schedule_node_band_member_set_coincident(Node, 1, isl_bool_true); // bj
          IsPermutable = true;
        }
      }

      // 重新生成调度
      Schedule = isl::manage(isl_schedule_node_get_schedule(Node));
      isl_schedule_node_free(Node);// 手动释放 node，避免泄漏

      // 应用新调度到 SCoP 中
      S->setSchedule(Schedule.get_map());

      LLVM_DEBUG({
        dbgs() << "Optimized Schedule Applied\n";
        dbgs() << "  Statements: " << S->getSize() << "\n";
        dbgs() << "  Permutable: " << (IsPermutable ? "Yes" : "No") << "\n";
      });
    }

    return false; // 不修改 LLVM IR
  }

  void print(raw_ostream &OS, const Module *) const override {
    auto *SI = getAnalysis<ScopInfoWrapperPass>().getSI();
    for (auto &It : *SI) {
      Scop *S = It.second.get();
      if (!S || S->isToBeSkipped()) continue;
      OS << "Schedule: " << stringFromIslObj(S->getSchedule().get()) << "\n";
    }
  }

  void getAnalysisUsage(AnalysisUsage &AU) const override {
    AU.addRequired<ScopInfoWrapperPass>();
    AU.addRequired<DependenceInfoWrapperPass>();
    AU.addRequired<LoopInfoWrapperPass>();
    AU.addRequired<PolyhedralInfo>();
    AU.setPreservesAll();
  }
};
}

char MatMulTilingPass::ID;
Pass *polly::createMatMulTilingPass() { return new MatMulTilingPass(); }

INITIALIZE_PASS_BEGIN(MatMulTilingPass, "matmul-tiling",
                      "Polly - Apply tiling to matrix multiplication loops.",
                      false, false)
INITIALIZE_PASS_END(MatMulTilingPass, "matmul-tiling",
                    "Polly - Apply tiling to matrix multiplication loops.",
                    false, false)


