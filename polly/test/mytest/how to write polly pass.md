
### 1.定义Pass ： 
在目录Transform下定义PassDemo.cpp
```
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


```
note: 一定要引入它：#include "polly/LinkAllPasses.h"

### 2.注册Pass

#### polly/lib/CMakeLists.txt:
```
add_llvm_pass_plugin(Polly
.....
Transform/PassDemo.cpp
```

####  polly/LinkAllPasses.h :

```
llvm::Pass *createPassDemoPassPass();
polly::createPassDemoPassPass(); 
void initializePassDemoPassPass(llvm::PassRegistry &);

对应PassDemo.cpp 中：
Pass *polly::createPassDemoPassPass() { return new PassDemoPass(); }

// 注册 Pass 到 opt 的命令行
INITIALIZE_PASS_BEGIN(PassDemoPass, "polly-pass-demo",
                      "Polly: Example pass demo Pass", false, false)
INITIALIZE_PASS_END(PassDemoPass, "polly-pass-demo",
                    "Polly: Example pass demo Pass", false, false)

```

#### RegisterPasses.cpp :
```
  initializePassDemoPassPass(Registry);
```


### 3.ninja
查看自定义的Pass是否注册成功

```

../../../build/bin/opt --help | grep matmul
      --polly-pass-demo                                               - Polly: Example pass demo Pass
```

### 4.执行Pass


1. create llvm ir from c

```
clang -S -emit-llvm matmul.c -Xclang -disable-O0-optnone -o matmul.ll
```

2. prepare llvm-ir for polly
   
```
opt -S -polly-canonicalize matmul.ll -o matmul.preopt.ll
```

3. -polly-pass-demo 
../../../build/bin/opt -polly-scops -polly-pass-demo  matmul.preopt.ll

```
[PassDemoPass] runOnScop called!
```



以上自定义简单的Polly Pass 流程笔记，显示已注册成功，可以在基础上进行进一步的优化开发了。

note: llvm version 是 20.