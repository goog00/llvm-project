
#include "polly/LinkAllPasses.h"
#include "polly/ScheduleTreeTransform.h"
#include "polly/ScopPass.h"
#include "llvm/Pass.h"
#include "llvm/Support/raw_ostream.h"
#include "isl/isl-noexceptions.h"
#include "isl/schedule_type.h"

/*
=== Schedule Tree Before Tiling ===
Node type: domain
  Node type: mark("Loop with Metadata")
    Node type: band[{ Stmt4[i0, i1, i2] -> [(i0)]; Stmt2[i0, i1] -> [(i0)] }]
      Node type: mark("Loop with Metadata")
        Node type: band[{ Stmt4[i0, i1, i2] -> [(i1)]; Stmt2[i0, i1] -> [(i1)] }]
          Node type: sequence
            Node type: filter { Stmt2[i0, i1] }
              Node type: leaf
            Node type: filter { Stmt4[i0, i1, i2] }
              Node type: mark("Loop with Metadata")
                Node type: band[{ Stmt4[i0, i1, i2] -> [(i2)] }]
                  Node type: leaf
Node type: mark("Loop with Metadata")
=== Schedule Tree After Tiling ===
Node type: domain
  Node type: mark("Loop with Metadata")
    Node type: mark("tile size - Tiles")
      Node type: band[{ Stmt2[i0, i1] -> [(i0 - (i0) mod 32)]; Stmt4[i0, i1, i2] -> [(i0 - (i0) mod 32)] }]
        Node type: mark("tile size - Points")
          Node type: band[{ Stmt2[i0, i1] -> [((i0) mod 32)]; Stmt4[i0, i1, i2] -> [((i0) mod 32)] }]
            Node type: mark("Loop with Metadata")
              Node type: band[{ Stmt4[i0, i1, i2] -> [(i1)]; Stmt2[i0, i1] -> [(i1)] }]
                Node type: sequence
                  Node type: filter { Stmt2[i0, i1] }
                    Node type: leaf
                  Node type: filter { Stmt4[i0, i1, i2] }
                    Node type: mark("Loop with Metadata")
                      Node type: band[{ Stmt4[i0, i1, i2] -> [(i2)] }]
                        Node type: leaf
                        
                        Node type: leaf tile size with 32

*/

#define DEBUG_TYPE "my-matmul-tile"

using namespace polly;
using namespace llvm;

namespace {

class MatMulTilingPass : public ScopPass {

public:
  static char ID;
  MatMulTilingPass() : ScopPass(ID) {}

  // 打印 isl node 类型
  void printNodeType(const isl::schedule_node &Node) {
    auto type = isl_schedule_node_get_type(Node.get());
    switch (type) {
    case isl_schedule_node_domain: {
      errs() << "Node type: domain\n";
      break;
    }
    case isl_schedule_node_band: {
      errs() << "Node type: band";
      auto Band = Node.as<isl::schedule_node_band>();
      auto PartialSchedule = Band.get_partial_schedule();
      auto dims = PartialSchedule.dim(isl::dim::out);
      if (dims.is_error()) {
        return;
      }
      unsigned size_dim = (unsigned)dims;
      errs() << "[";
      for (int d = 0; d < size_dim; ++d) {
        // 多维 schedule 里第 d 个维度的 affine 映射（即 tile 层的 II/JJ，点层的
        // i/j）
        auto upa = PartialSchedule.at(d);
        // 每个维度的具体 schedule 公式,比如：[i0, i1] -> [floor(i0/32)]
        const char *upa_cstr = isl_union_pw_aff_to_str(upa.get());
        if (d > 0)
          errs() << ",";
        errs() << upa_cstr;
        free((void *)upa_cstr);
      }
      errs() << "]\n";
      break;
    }
    case isl_schedule_node_sequence: {
      errs() << "Node type: sequence\n";
      break;
    }
    case isl_schedule_node_set: {
      errs() << "Node type: set\n";
      break;
    }
    case isl_schedule_node_filter: {
      auto filterSet =
          isl::manage(isl_schedule_node_filter_get_filter(Node.get()));
      const char *filterStr = isl_union_set_to_str(filterSet.get());
      errs() << "Node type: filter " << filterStr << "\n";
      free((void *)filterStr);
      break;
    }
    case isl_schedule_node_leaf: {
      errs() << "Node type: leaf\n";
      break;
    }
    case isl_schedule_node_mark: {
      auto id = isl_schedule_node_mark_get_id(Node.get());
      std::string markName = isl_id_get_name(id);
      errs() << "Node type: mark(\"" << markName << "\")\n";
      break;
    }
    default: {
      errs() << "Node type: unknown (" << type << ")\n";
      break;
    }
    }
  }

  void printScheduleTree(const isl::schedule_node &Node, int level = 0) {
    for (int i = 0; i < level; ++i)
      errs() << "  ";
    printNodeType(Node);
    auto nchildren = Node.n_children();
    if (nchildren.is_error())
      return;

    unsigned num = static_cast<unsigned>(nchildren);
    for (int i = 0; i < num; ++i) {
      printScheduleTree(Node.child(i), level + 1);
    }
  }

  bool runOnScop(Scop &S) override {
    auto &Context = S.getSharedIslCtx();
    auto Schedule = S.getScheduleTree();

    if (Schedule.is_null())
      return false;

    // 找到可以做分块的band
    auto Root = Schedule.get_root();

    // tile 前打印
    errs() << "=== Schedule Tree Before Tiling ===\n";
    printScheduleTree(Root);

    auto nchildren = Root.n_children();
    if (nchildren.is_error()) {
      LLVM_DEBUG(dbgs() << "n_children() error: isl error or node invalid\n");
      return false;
    }
    unsigned size_children = (unsigned)nchildren;
    if (size_children == 0)
      return false;

    isl::schedule_node Node = Root.child(0);

    printNodeType(Node);

    // 遍历调度树，找到最外层band
    Node = Node.first_child();
    if (isl_schedule_node_get_type(Node.get()) != isl_schedule_node_band)
      return false;

    auto BandNode = Node.as<isl::schedule_node_band>();
    auto bandnode_member = BandNode.n_member();
    if (bandnode_member.is_error()) {
      LLVM_DEBUG(
          dbgs() << "BandNode.n_member() error: isl error or node invalid\n");
      return false;
    }

    unsigned NumMembers = static_cast<unsigned>(bandnode_member);

    // 设置分块大小，例如全部用32
    std::vector<int> TileSizes(NumMembers, 32);

    // 应用分块
    Node = polly::tileNode(Node, "tile size", TileSizes, 64);
    // 替换schedule tree
    Schedule = Node.get_schedule();
    S.setScheduleTree(Schedule);

    // tile 后打印
    errs() << "=== Schedule Tree After Tiling ===\n";
    auto NewRoot = S.getScheduleTree().get_root();
    printScheduleTree(NewRoot);

    // 输出调试信息
    LLVM_DEBUG(dbgs() << "tile size with 32");
    return true;
  }
  void getAnalysisUsage(AnalysisUsage &AU) const override {
    ScopPass::getAnalysisUsage(AU);
  }
};

char MatMulTilingPass::ID = 0;

} // namespace

Pass *polly::createMatMulTilingPassPass() { return new MatMulTilingPass(); }

// 注册 Pass 到 opt 的命令行
INITIALIZE_PASS_BEGIN(MatMulTilingPass, "my-matmul-tile",
                      "Polly: my matmul tile Pass", false, false)
INITIALIZE_PASS_END(MatMulTilingPass, "my-matmul-tile",
                    "Polly: my matmul tile Pass", false, false)
