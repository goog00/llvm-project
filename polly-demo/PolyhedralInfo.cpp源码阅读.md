以下是对 `PolyhedralInfo.cpp` 文件的详细解释，内容以中文呈现，力求清晰、简洁且全面，帮助理解 LLVM 项目中 Polly 优化框架的 `PolyhedralInfo` 模块。该文件提供了一个接口，用于访问 Polly 的多面体分析功能，供 LLVM 变换 Pass 使用，重点在于检查循环的并行性和可向量化性。以下分析将涵盖文件的功能、实现细节和关键方法。

---

### 1. 文件概述

`PolyhedralInfo.cpp` 实现了 `PolyhedralInfo` 类，作为 Polly 框架的一个分析 Pass（`AnalysisPass`），提供对多面体分析结果的访问接口。它依赖于 Polly 的 `ScopInfo` 和 `DependenceInfo` 模块，允许 LLVM 变换 Pass 查询特定循环（`Loop`）的并行性（`isParallel`）和可向量化性（`isVectorizable`）。该文件是 Polly 与其他 LLVM Pass 交互的桥梁，特别适用于需要利用多面体模型信息的优化场景。

文件的主要功能包括：

1. **并行性检查**：通过分析数据依赖和调度，判断循环是否可并行执行。
2. **调度提取**：为指定循环提取部分调度（partial schedule），表示其执行顺序。
3. **SCoP 查找**：定位包含指定循环的 SCoP（静态控制流部分）。
4. **调试支持**：提供调试信息，输出循环的并行性分析结果。

**注意**：文件标明“Work in progress”，表明其功能可能仍在开发中，未来可能会有扩展或修改。

---

### 2. 文件头部和全局配置

#### 2.1 头文件和依赖

文件包含了以下关键头文件：

```cpp
#include "polly/PolyhedralInfo.h"
#include "polly/DependenceInfo.h"
#include "polly/ScopInfo.h"
#include "polly/Support/GICHelper.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Support/Debug.h"
#include "isl/union_map.h"
```

- **Polly 模块**：
  - `PolyhedralInfo.h`：定义 `PolyhedralInfo` 类的接口。
  - `DependenceInfo.h`：提供数据依赖分析。
  - `ScopInfo.h`：定义 SCoP 数据结构（如 `Scop`、`ScopStmt`）。
  - `GICHelper.h`：提供 ISL 对象的字符串转换工具（`stringFromIslObj`）。
- **LLVM 模块**：
  - `LoopInfo.h`：提供循环信息（`Loop` 和 `LoopInfo`）。
  - `Debug.h`：支持调试输出。
- **ISL 库**：
  - `isl/union_map.h`：支持多面体调度和依赖操作。

#### 2.2 命令行选项

文件定义了两个命令行选项，用于控制分析行为：

```cpp
static cl::opt<bool> CheckParallel("polly-check-parallel",
                                   cl::desc("Check for parallel loops"),
                                   cl::Hidden, cl::init(false), cl::ZeroOrMore,
                                   cl::cat(PollyCategory));

static cl::opt<bool> CheckVectorizable("polly-check-vectorizable",
                                       cl::desc("Check for vectorizable loops"),
                                       cl::Hidden, cl::init(false),
                                       cl::ZeroOrMore, cl::cat(PollyCategory));
```

- `CheckParallel`：是否检查循环的并行性（默认 `false`）。
- `CheckVectorizable`：是否检查循环的可向量化性（默认 `false`）。
- 两者均为隐藏选项（`cl::Hidden`），仅用于调试或开发。

---

### 3. `PolyhedralInfo` 类结构

`PolyhedralInfo` 继承自 LLVM 的 `FunctionPass`，提供多面体分析接口。以下是其核心方法和功能的详细分析。

#### 3.1 类定义和成员

```cpp
class PolyhedralInfo : public FunctionPass {
public:
  static char ID;
  explicit PolyhedralInfo() : FunctionPass(ID) {}
  bool runOnFunction(Function &F) override;
  void print(raw_ostream &OS, const Module *) const override;
  void getAnalysisUsage(AnalysisUsage &AU) const override;

  bool isParallel(Loop *L) const;
  bool checkParallel(Loop *L, isl_pw_aff **MinDepDistPtr = nullptr) const;
  const Scop *getScopContainingLoop(Loop *L) const;
  __isl_give isl_union_map *getScheduleForLoop(const Scop *S, Loop *L) const;

private:
  ScopInfo *SI;
  DependenceInfoWrapperPass *DI;
};
```

- **成员变量**：
  - `SI`：指向 `ScopInfo` 对象，存储 SCoP 信息。
  - `DI`：指向 `DependenceInfoWrapperPass` 对象，提供依赖分析。

- **主要方法**：
  - `runOnFunction`：初始化 Pass，获取依赖的分析结果。
  - `print`：打印循环的并行性信息。
  - `isParallel` 和 `checkParallel`：检查循环是否可并行。
  - `getScopContainingLoop`：查找包含指定循环的 SCoP。
  - `getScheduleForLoop`：提取循环的部分调度。

#### 3.2 核心方法

##### 3.2.1 `getAnalysisUsage`

```cpp
void PolyhedralInfo::getAnalysisUsage(AnalysisUsage &AU) const {
  AU.addRequiredTransitive<DependenceInfoWrapperPass>();
  AU.addRequired<LoopInfoWrapperPass>();
  AU.addRequiredTransitive<ScopInfoWrapperPass>();
  AU.setPreservesAll();
}
```

- **功能**：
  - 声明依赖的分析 Pass：
    - `DependenceInfoWrapperPass`：提供数据依赖信息。
    - `LoopInfoWrapperPass`：提供循环结构信息。
    - `ScopInfoWrapperPass`：提供 SCoP 信息。
  - 设置 `setPreservesAll`，表示该 Pass 不修改 IR。

##### 3.2.2 `runOnFunction`

```cpp
bool PolyhedralInfo::runOnFunction(Function &F) {
  DI = &getAnalysis<DependenceInfoWrapperPass>();
  SI = getAnalysis<ScopInfoWrapperPass>().getSI();
  return false;
}
```

- **功能**：
  - 初始化 `DI` 和 `SI`，分别获取 `DependenceInfoWrapperPass` 和 `ScopInfoWrapperPass` 的结果。
  - 返回 `false`，表示不修改函数的 IR。

##### 3.2.3 `print`

```cpp
void PolyhedralInfo::print(raw_ostream &OS, const Module *) const {
  auto &LI = getAnalysis<LoopInfoWrapperPass>().getLoopInfo();
  for (auto *TopLevelLoop : LI) {
    for (auto *L : depth_first(TopLevelLoop)) {
      OS.indent(2) << L->getHeader()->getName() << ":\t";
      if (CheckParallel && isParallel(L))
        OS << "Loop is parallel.\n";
      else if (CheckParallel)
        OS << "Loop is not parallel.\n";
    }
  }
}
```

- **功能**：
  - 遍历函数的所有顶层循环（`TopLevelLoop`）及其嵌套循环（通过 `depth_first`）。
  - 如果启用 `CheckParallel`，调用 `isParallel` 检查每个循环的并行性，并打印结果。
  - 输出格式为：`[循环头基本块名称]: Loop is parallel.` 或 `Loop is not parallel.`。

##### 3.2.4 `checkParallel` 和 `isParallel`

```cpp
bool PolyhedralInfo::checkParallel(Loop *L, isl_pw_aff **MinDepDistPtr) const {
  bool IsParallel;
  const Scop *S = getScopContainingLoop(L);
  if (!S)
    return false;
  const Dependences &D =
      DI->getDependences(const_cast<Scop *>(S), Dependences::AL_Access);
  if (!D.hasValidDependences())
    return false;
  LLVM_DEBUG(dbgs() << "Loop :\t" << L->getHeader()->getName() << ":\n");

  isl_union_map *Deps =
      D.getDependences(Dependences::TYPE_RAW | Dependences::TYPE_WAW |
                       Dependences::TYPE_WAR | Dependences::TYPE_RED)
          .release();

  LLVM_DEBUG(dbgs() << "Dependences :\t" << stringFromIslObj(Deps) << "\n");

  isl_union_map *Schedule = getScheduleForLoop(S, L);
  LLVM_DEBUG(dbgs() << "Schedule: \t" << stringFromIslObj(Schedule) << "\n");

  IsParallel = D.isParallel(Schedule, Deps, MinDepDistPtr);
  isl_union_map_free(Schedule);
  return IsParallel;
}

bool PolyhedralInfo::isParallel(Loop *L) const { return checkParallel(L); }
```

- **功能**：
  - `isParallel` 是对外接口，调用 `checkParallel` 检查循环是否可并行。
  - `checkParallel` 的步骤：
    1. 调用 `getScopContainingLoop` 查找包含循环 `L` 的 SCoP。
    2. 如果没有 SCoP 或依赖无效，返回 `false`。
    3. 获取所有依赖（`RAW`、`WAW`、`WAR` 和约减依赖 `RED`）。
    4. 调用 `getScheduleForLoop` 获取循环的部分调度。
    5. 使用 `Dependences::isParallel` 检查调度是否允许并行执行（无跨迭代依赖）。
    6. 如果提供 `MinDepDistPtr`，返回最小依赖距离（`isl_pw_aff`）。
  - 调试模式下，输出循环名称、依赖和调度信息。

##### 3.2.5 `getScopContainingLoop`

```cpp
const Scop *PolyhedralInfo::getScopContainingLoop(Loop *L) const {
  assert((SI) && "ScopInfoWrapperPass is required by PolyhedralInfo pass!\n");
  for (auto &It : *SI) {
    Region *R = It.first;
    if (R->contains(L))
      return It.second.get();
  }
  return nullptr;
}
```

- **功能**：
  - 遍历 `ScopInfo` 中的所有 SCoP，检查每个 SCoP 的区域（`Region`）是否包含循环 `L`。
  - 如果找到包含 `L` 的 SCoP，返回其指针；否则返回 `nullptr`。
  - 使用 `assert` 确保 `SI` 已初始化。

##### 3.2.6 `getScheduleForLoop`

```cpp
__isl_give isl_union_map *PolyhedralInfo::getScheduleForLoop(const Scop *S,
                                                             Loop *L) const {
  isl_union_map *Schedule = isl_union_map_empty(S->getParamSpace().release());
  int CurrDim = S->getRelativeLoopDepth(L);
  LLVM_DEBUG(dbgs() << "Relative loop depth:\t" << CurrDim << "\n");
  assert(CurrDim >= 0 && "Loop in region should have at least depth one");

  for (auto &SS : *S) {
    if (L->contains(SS.getSurroundingLoop())) {
      unsigned int MaxDim = SS.getNumIterators();
      LLVM_DEBUG(dbgs() << "Maximum depth of Stmt:\t" << MaxDim << "\n");
      isl_map *ScheduleMap = SS.getSchedule().release();
      assert(
          ScheduleMap &&
          "Schedules that contain extension nodes require special handling.");

      ScheduleMap = isl_map_project_out(ScheduleMap, isl_dim_out, CurrDim + 1,
                                        MaxDim - CurrDim - 1);
      ScheduleMap = isl_map_set_tuple_id(ScheduleMap, isl_dim_in,
                                         SS.getDomainId().release());
      Schedule =
          isl_union_map_union(Schedule, isl_union_map_from_map(ScheduleMap));
    }
  }
  Schedule = isl_union_map_coalesce(Schedule);
  return Schedule;
}
```

- **功能**：
  - 为指定循环 `L` 在 SCoP `S` 中提取部分调度（`isl_union_map`）。
  - 步骤：
    1. 创建空的调度映射（`isl_union_map_empty`），基于 SCoP 的参数空间。
    2. 获取循环 `L` 的相对深度（`CurrDim`），通过 `S->getRelativeLoopDepth(L)`。
    3. 遍历 SCoP 中的所有语句（`ScopStmt`），检查其周围循环（`getSurroundingLoop`）是否被 `L` 包含。
    4. 对于符合条件的语句：
       - 获取其调度映射（`SS.getSchedule`）。
       - 使用 `isl_map_project_out` 投影掉内层维度（从 `CurrDim + 1` 到 `MaxDim - 1`），保留外层调度。
       - 设置输入元组 ID 为语句的域 ID（`SS.getDomainId`）。
       - 将调度映射加入到联合映射（`isl_union_map_union`）。
    5. 调用 `isl_union_map_coalesce` 合并调度映射，优化表示。
  - **示例**：
    对于代码：
    ```c
    for (int i = 0; i < n; i++)
        for (int j = 0; j < n; j++)
            A[j] = 1;  // Stmt
    ```
    - 原始调度：`{ Stmt[i0, i1] -> [i0, i1] }`。
    - 外层循环（`i`）调度：`{ Stmt[i0, i1] -> [i0] }`。
    - 内层循环（`j`）调度：`{ Stmt[i0, i1] -> [i0, i1] }`。

---

### 4. 实现细节和优化

- **多面体模型**：
  - 使用 ISL 库操作调度（`isl_union_map`）和依赖（`isl_union_map`），表示循环的执行顺序和数据依赖。
  - 调度映射表示语句的迭代域到执行顺序的映射，投影操作（`isl_map_project_out`）用于提取特定循环级别的调度。

- **并行性分析**：
  - `Dependences::isParallel` 检查调度是否允许并行执行，基于依赖是否跨越迭代（`RAW`、`WAW`、`WAR` 和约减依赖）。
  - 可选的 `MinDepDistPtr` 返回最小依赖距离，用于进一步分析。

- **调试支持**：
  - 使用 `LLVM_DEBUG` 宏输出循环名称、依赖和调度信息。
  - 使用 `stringFromIslObj` 将 ISL 对象转换为字符串，便于调试。

- **局限性**：
  - 不支持包含扩展节点（extension nodes）的调度（需特殊处理）。
  - 可向量化性检查（`CheckVectorizable`）在代码中未实现，可能为未来扩展预留。

---

### 5. 示例分析

考虑以下 C 代码：

```c
void example(int A[], int n) {
    for (int i = 0; i < n; i++)
        for (int j = 0; j < n; j++)
            A[j] = A[j] + 1;
}
```

`PolyhedralInfo` 的处理流程如下：

1. **初始化**：
   - `runOnFunction` 获取 `DependenceInfo` 和 `ScopInfo`。

2. **SCoP 查找**：
   - 对于外层循环 `i`，调用 `getScopContainingLoop` 找到包含它的 SCoP。

3. **调度提取**：
   - 调用 `getScheduleForLoop`：
     - 语句 `Stmt` 的原始调度：`{ Stmt[i,j] -> [i,j] }`。
     - 外层循环 `i` 的调度：`{ Stmt[i,j] -> [i] }`。
     - 内层循环 `j` 的调度：`{ Stmt[i,j] -> [i,j] }`。

4. **并行性检查**：
   - 获取依赖：`{ Stmt[i,j] -> Stmt[i,j+1] }`（`RAW` 和 `WAW`，因 `A[j]` 的读写）。
   - 检查外层循环 `i`：
     - 调度 `{ Stmt[i,j] -> [i] }` 无跨迭代依赖（`j` 维度被投影掉），因此 `isParallel` 返回 `true`。
   - 检查内层循环 `j`：
     - 调度 `{ Stmt[i,j] -> [i,j] }` 存在跨迭代依赖（`j` 到 `j+1`），因此 `isParallel` 返回 `false`。

5. **打印**：
   - 如果启用 `CheckParallel`，输出：
     ```
     loop_i: Loop is parallel.
     loop_j: Loop is not parallel.
     ```

---

### 6. 总结

`PolyhedralInfo.cpp` 是 Polly 框架中提供多面体分析接口的核心模块，允许 LLVM Pass 查询循环的并行性并提取调度信息。其设计特点包括：

- **接口化**：提供简洁的 `isParallel` 方法，易于集成到其他 Pass。
- **多面体支持**：利用 ISL 库精确分析调度和依赖。
- **灵活性**：支持调试和命令行配置，便于开发和测试。
- **扩展性**：预留了可向量化性检查等功能，未来可扩展。

 