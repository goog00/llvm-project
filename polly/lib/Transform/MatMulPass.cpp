// MatMulTilingPass.cpp
#include "polly/LinkAllPasses.h"
#include "polly/ScheduleTreeTransform.h"
#include "polly/ScopPass.h"
#include "llvm/Pass.h"
#include "isl/isl-noexceptions.h"
#include "isl/schedule_type.h"

#define DEBUG_TYPE "polly-matmul-tiling"

using namespace polly;
using namespace llvm;

namespace {

class MatMulTilingPass : public ScopPass {

public:
  static char ID;
  MatMulTilingPass() : ScopPass(ID) {}

  bool runOnScop(Scop &S) override {
    auto &Context = S.getSharedIslCtx();
    auto Schedule = S.getScheduleTree();

    if (Schedule.is_null())
      return false;

    // 找到可以做分块的band
    auto Root = Schedule.get_root();

    isl::schedule_node Node = Root.child(0);

    // 遍历调度树，找到最外层band
    Node = Node.first_child();
    // 用 isl C API 判断类型
    if (isl_schedule_node_get_type(Node.get()) != isl_schedule_node_band)
      return false;

    auto BandNode = Node.as<isl::schedule_node_band>();
    unsigned NumMembers = static_cast<unsigned>(BandNode.n_member());
    // 设置分块大小，例如全部用32
    std::vector<int> TileSizes(NumMembers, 32);

    // 应用分块
    Node = polly::tileNode(Node, "tile size", TileSizes, 64);

    // 替换schedule tree
    Schedule = Node.get_schedule();
    S.setScheduleTree(Schedule);

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

Pass *polly::createMatMulTilingPassPass() {
  return new MatMulTilingPass();
}


// 注册 Pass 到 opt 的命令行
INITIALIZE_PASS_BEGIN(MatMulTilingPass, "my-matmul-tile",
                      "Polly: my matmul tile Pass", false, false)
INITIALIZE_PASS_END(MatMulTilingPass, "my-matmul-tile",
                    "Polly: my matmul tile Pass", false, false)

