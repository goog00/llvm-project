// PassDemo.cpp
#include "polly/ScopPass.h"
#include "llvm/Support/raw_ostream.h"
#include "polly/LinkAllPasses.h"

using namespace polly;
using namespace llvm;

namespace {

class PassDemoPass : public ScopPass {
public:
  static char ID;
  PassDemoPass() : ScopPass(ID) {}

  bool runOnScop(Scop &S) override {
    errs() << "[PassDemoPass] runOnScop called!\n";
    // ...你的优化代码...
    return false; // or true if you modified SCoP
  }

  void getAnalysisUsage(AnalysisUsage &AU) const override {
    ScopPass::getAnalysisUsage(AU);
  }
};

char PassDemoPass::ID = 0;

} // namespace

Pass *polly::createPassDemoPassPass() { return new PassDemoPass(); }

// 注册 Pass 到 opt 的命令行
INITIALIZE_PASS_BEGIN(PassDemoPass, "polly-pass-demo",
                      "Polly: Example pass demo Pass", false, false)
INITIALIZE_PASS_END(PassDemoPass, "polly-pass-demo",
                    "Polly: Example pass demo Pass", false, false)

