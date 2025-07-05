以下是对 `DependenceInfo.cpp` 文件的详细解释，内容以中文呈现，力求清晰、简洁且全面，帮助理解 LLVM 项目中 Polly 优化框架的依赖分析模块。该文件实现了 `DependenceInfo` 和相关类，负责为 SCoP（静态控制流部分）计算数据依赖关系，包括读后写（RAW）、写后读（WAR）、写后写（WAW）以及约减依赖（RED），并利用 ISL（Integer Set Library）库进行精确的多面体依赖分析。以下分析涵盖文件的功能、实现细节、核心方法以及与 `PolyhedralInfo.cpp` 和 `ScheduleOptimizer.cpp` 的关系。

---

### 1. 文件概述

`DependenceInfo.cpp` 是 Polly 框架中用于计算 SCoP 数据依赖的核心模块，提供了 `DependenceInfo` 和 `DependenceInfoWrapperPass` 两个 Pass，用于分析 SCoP 中语句间的依赖关系。其主要功能包括：

1. **依赖计算**：基于 ISL 的流分析（flow analysis），计算精确的 RAW、WAR、WAW 和约减依赖（RED），支持语句级、引用级和访问级分析。
2. **约减依赖处理**：识别并处理约减操作（如 `sum += A[i]`），包括约减依赖的传递闭包（transitive closure）。
3. **并行性检查**：验证调度是否允许并行执行，检查是否存在跨迭代依赖。
4. **调试支持**：提供依赖信息的打印和调试功能。
5. **多层次分析**：支持不同粒度的依赖分析（语句级、引用级、访问级）。

该模块通过多面体模型表示依赖关系，确保精确性（无冗余依赖），并支持私有化依赖（privatization dependences）以优化约减操作的并行性。依赖信息为调度优化（如 `ScheduleOptimizer.cpp`）和并行性分析（如 `PolyhedralInfo.cpp`）提供基础。

---

### 2. 文件头部和全局配置

#### 2.1 头文件和依赖

文件包含以下关键头文件：

```cpp
#include "polly/DependenceInfo.h"
#include "polly/ScopInfo.h"
#include "polly/Support/GICHelper.h"
#include "polly/Support/ISLTools.h"
#include "llvm/Support/Debug.h"
#include "isl/aff.h"
#include "isl/ctx.h"
#include "isl/flow.h"
#include "isl/map.h"
#include "isl/schedule.h"
#include "isl/set.h"
#include "isl/union_map.h"
#include "isl/union_set.h"
```

- **Polly 模块**：
  - `DependenceInfo.h`：定义 `DependenceInfo` 和相关类。
  - `ScopInfo.h`：提供 SCoP 数据结构（如 `Scop`、`ScopStmt`、`MemoryAccess`）。
  - `GICHelper.h`：支持 ISL 对象的字符串转换（`stringFromIslObj`）。
  - `ISLTools.h`：提供 ISL 操作的辅助工具。
- **LLVM 模块**：
  - `Debug.h`：支持调试输出。
- **ISL 库**：
  - 提供多面体操作支持（如 `isl_union_map`、`isl_schedule`、`isl_flow`）。

#### 2.2 命令行选项

文件定义了以下命令行选项，用于控制依赖分析行为：

```cpp
static cl::opt<int> OptComputeOut(
    "polly-dependences-computeout",
    cl::desc("Bound the dependence analysis by a maximal amount of computational steps (0 means no bound)"),
    cl::Hidden, cl::init(500000), cl::ZeroOrMore, cl::cat(PollyCategory));

static cl::opt<bool> LegalityCheckDisabled(
    "disable-polly-legality", cl::desc("Disable polly legality check"),
    cl::Hidden, cl::init(false), cl::ZeroOrMore, cl::cat(PollyCategory));

static cl::opt<bool> UseReductions(
    "polly-dependences-use-reductions",
    cl::desc("Exploit reductions in dependence analysis"),
    cl::Hidden, cl::init(true), cl::ZeroOrMore, cl::cat(PollyCategory));

static cl::opt<enum AnalysisType> OptAnalysisType(
    "polly-dependences-analysis-type",
    cl::desc("The kind of dependence analysis to use"),
    cl::values(clEnumValN(VALUE_BASED_ANALYSIS, "value-based", "Exact dependences without transitive dependences"),
               clEnumValN(MEMORY_BASED_ANALYSIS, "memory-based", "Overapproximation of dependences")),
    cl::Hidden, cl::init(VALUE_BASED_ANALYSIS), cl::ZeroOrMore, cl::cat(PollyCategory));

static cl::opt<Dependences::AnalysisLevel> OptAnalysisLevel(
    "polly-dependences-analysis-level",
    cl::desc("The level of dependence analysis"),
    cl::values(clEnumValN(Dependences::AL_Statement, "statement-wise", "Statement-level analysis"),
               clEnumValN(Dependences::AL_Reference, "reference-wise", "Memory reference level analysis that distinguish accessed references in the same statement"),
               clEnumValN(Dependences::AL_Access, "access-wise", "Memory reference level analysis that distinguish access instructions in the same statement")),
    cl::Hidden, cl::init(Dependences::AL_Statement), cl::ZeroOrMore, cl::cat(PollyCategory));
```

- `OptComputeOut`：限制依赖分析的最大计算步数（默认 500,000，0 表示无限制）。
- `LegalityCheckDisabled`：禁用调度合法性检查（默认 `false`）。
- `UseReductions`：是否利用约减依赖（默认 `true`）。
- `OptAnalysisType`：依赖分析类型：
  - `VALUE_BASED_ANALYSIS`：精确依赖分析，无传递依赖（默认）。
  - `MEMORY_BASED_ANALYSIS`：内存访问的过近似依赖分析。
- `OptAnalysisLevel`：依赖分析粒度：
  - `AL_Statement`：语句级（默认）。
  - `AL_Reference`：引用级，区分同一语句中的不同数组引用。
  - `AL_Access`：访问级，区分同一语句中的不同访问指令。

---

### 3. 核心类和方法

`DependenceInfo.cpp` 实现了 `DependenceInfo`、`DependenceInfoWrapperPass` 和 `Dependences` 类，核心功能由 `Dependences::calculateDependences` 方法完成。以下详细分析各部分。

#### 3.1 `Dependences` 类

`Dependences` 是核心类，负责存储和计算 SCoP 的依赖关系。

##### 3.1.1 成员变量

- `RAW`、`WAR`、`WAW`、`RED`、`TC_RED`：存储读后写、写后读、写后写、约减依赖及其传递闭包的 `isl_union_map`。
- `ReductionDependences`：映射 `MemoryAccess` 到约减依赖的 `isl_map`。
- `Level`：分析粒度（`AL_Statement`、`AL_Reference` 或 `AL_Access`）。
- `IslCtx`：ISL 上下文。

##### 3.1.2 核心方法

###### `collectInfo`

```cpp
static void collectInfo(Scop &S, isl_union_map *&Read, isl_union_map *&MustWrite,
                        isl_union_map *&MayWrite, isl_union_map *&ReductionTagMap,
                        isl_union_set *&TaggedStmtDomain, Dependences::AnalysisLevel Level);
```

- **功能**：
  - 收集 SCoP 的读写访问和约减信息：
    - `Read`：所有读访问的联合映射。
    - `MustWrite`：所有确定写（must-write）访问的联合映射。
    - `MayWrite`：所有可能写（may-write）访问的联合映射。
    - `ReductionTagMap`：约减访问的标记映射。
    - `TaggedStmtDomain`：标记后的语句域（用于细粒度分析）。
  - 步骤：
    1. 初始化空的 `isl_union_map` 和 `isl_union_set`。
    2. 收集约减数组（`ReductionArrays`），基于 `MA->isReductionLike()`。
    3. 遍历 SCoP 的语句（`ScopStmt`）和内存访问（`MemoryAccess`）：
       - 获取访问关系（`MA->getAccessRelation`）并与语句域（`Stmt.getDomain`）相交。
       - 对于约减访问，构建标记映射（`ReductionTagMap`）并调整访问域。
       - 对于非约减访问，根据 `Level`（引用级或访问级）标记访问关系。
       - 根据访问类型（读、确定写、可能写）分配到 `Read`、`MustWrite` 或 `MayWrite`。
    4. 如果需要细粒度分析（`Level > AL_Statement`），标记语句调度（`Stmt.getSchedule`）。
    5. 合并所有映射（`isl_union_map_coalesce`）。

###### `buildFlow`

```cpp
static __isl_give isl_union_flow *buildFlow(__isl_keep isl_union_map *Snk,
                                            __isl_keep isl_union_map *Src,
                                            __isl_keep isl_union_map *MaySrc,
                                            __isl_keep isl_schedule *Schedule);
```

- **功能**：
  - 使用 ISL 流分析（`isl_union_access_info_compute_flow`）构建依赖流：
    - `Snk`：接收端（sink，如写访问）。
    - `Src`：确定源（must-source，如确定写）。
    - `MaySrc`：可能源（may-source，如读访问）。
    - `Schedule`：SCoP 的调度树。
  - 返回 `isl_union_flow` 对象，包含依赖信息。

###### `buildWAR`

```cpp
static isl_union_map *buildWAR(isl_union_map *Write, isl_union_map *MustWrite,
                               isl_union_map *Read, isl_schedule *Schedule);
```

- **功能**：
  - 计算精确的 WAR 依赖，确保只生成读到最近写（`Read -> MustWrite`）的依赖，避免冗余依赖（如 `Read -> MayWrite` 覆盖 `Read -> MustWrite`）。
  - 步骤：
    1. 使用 `buildFlow` 构建流分析，获取过估计的 WAR 依赖（`WAROverestimated`）。
    2. 构造 `WARMemAccesses`，将依赖映射到内存访问空间。
    3. 应用 `WARMemAccesses` 到 `WAROverestimated` 的域，生成标记后的 WAR 依赖。
    4. 与包装后的读访问（`ReadWrapped`）相交，仅保留读到写的依赖。
    5. 投影掉内存访问标记，得到标准形式的 WAR 依赖（`{ Read -> Write }`）。

###### `addPrivatizationDependences`

```cpp
void Dependences::addPrivatizationDependences();
```

- **功能**：
  - 为约减访问添加私有化依赖，扩展原始依赖以包含所有后续约减迭代。
  - 步骤：
    1. 计算约减依赖的传递闭包（`TC_RED`），使用 `isl_union_map_transitive_closure`。
    2. 移除负向依赖（backward dependences），确保无依赖循环。
    3. 扩展 RAW、WAW 和 WAR 依赖，应用传递闭包到源和接收端。
  - **示例**：
    ```c
    *sum = 0;                    // S0
    for (int i = 0; i < 1024; i++)
        *sum += i;               // S1
    *sum = *sum * 3;            // S2
    ```
    - 原始依赖：
      - RAW: `{ S0[] -> S1[0]; S1[1023] -> S2[] }`
      - WAW: `{ S0[] -> S1[0]; S1[1023] -> S2[] }`
      - RED: `{ S1[i] -> S1[i+1] : 0 <= i <= 1022 }`
    - 私有化后：
      - RAW: `{ S0[] -> S1[i] : 0 <= i <= 1023; S1[i] -> S2[] : 0 <= i <= 1023 }`
      - WAW: 同上
      - RED: 不变

###### `calculateDependences`

```cpp
void Dependences::calculateDependences(Scop &S);
```

- **功能**：
  - 计算 SCoP 的所有依赖（RAW、WAR、WAW、RED 和 TC_RED）。
  - 步骤：
    1. 调用 `collectInfo` 收集读写访问和约减信息。
    2. 获取 SCoP 的调度树（`S.getScheduleTree`）。
    3. 如果存在约减访问，标记调度树以支持细粒度依赖（`Level > AL_Statement`）。
    4. 使用 `buildFlow` 和 `buildWAR` 计算依赖：
       - 对于 `VALUE_BASED_ANALYSIS`：
         - RAW: 读到确定写或可能写的依赖。
         - WAW: 写到确定写或可能写的依赖。
         - WAR: 精确的读到写依赖（通过 `buildWAR`）。
       - 对于 `MEMORY_BASED_ANALYSIS`：
         - RAW: 读到任何写的依赖（过近似）。
         - WAR: 写到任何读的依赖。
         - WAW: 写到任何写的依赖。
    5. 处理约减依赖：
       - 提取约减依赖（`RED`），与 RAW 和 WAW 相交，确保地址相同。
       - 移除约减依赖对 RAW、WAW 和 WAR 的影响。
       - 添加私有化依赖（`addPrivatizationDependences`）。
       - 为每个约减访问分配依赖（`setReductionDependences`）。
    6. 调整依赖格式（`isl_union_map_zip` 和 `isl_union_set_unwrap`），合并语句级依赖（`STMT_RAW` 等）。
    7. 合并和优化依赖（`isl_union_map_coalesce`）。

###### `isParallel`

```cpp
bool Dependences::isParallel(isl_union_map *Schedule, isl_union_map *Deps,
                             isl_pw_aff **MinDistancePtr) const;
```

- **功能**：
  - 检查调度是否允许并行执行，验证是否存在跨迭代依赖。
  - 步骤：
    1. 将依赖映射到时间空间（`apply_domain` 和 `apply_range`）。
    2. 如果依赖为空，返回 `true`（并行）。
    3. 提取调度维度（`Dimension`），强制外层维度相等（`isl_map_equate`）。
    4. 计算依赖距离（`Deltas`），检查当前维度是否为零（`Distance`）。
    5. 如果 `IsParallel` 为 `true`（无非零距离），返回 `true`。
    6. 如果提供 `MinDistancePtr`，计算最小依赖距离（`isl_set_dim_min`）。
  - 用于 `PolyhedralInfo::checkParallel`。

###### `isValidSchedule`

```cpp
bool Dependences::isValidSchedule(Scop &S, const StatementToIslMapTy &NewSchedule) const;
```

- **功能**：
  - 验证新调度的合法性，确保不引入依赖循环。
  - 步骤：
    1. 如果禁用合法性检查（`LegalityCheckDisabled`），返回 `true`。
    2. 获取所有依赖（RAW、WAR、WAW）。
    3. 构建新调度（`Schedule`），从 `NewSchedule` 或语句的原始调度。
    4. 将依赖映射到新调度空间（`apply_domain` 和 `apply_range`）。
    5. 检查依赖距离（`Deltas`）是否包含非正向依赖（`lex_le_set`）。
    6. 如果无非正向依赖，返回 `true`（合法）。

###### `getDependences`

```cpp
isl::union_map Dependences::getDependences(int Kinds) const;
```

- **功能**：
  - 返回指定类型的依赖（`TYPE_RAW`、`TYPE_WAR`、`TYPE_WAW`、`TYPE_RED`、`TYPE_TC_RED`）的联合。
  - 合并后优化（`coalesce` 和 `detect_equalities`）。

###### `print` 和 `dump`

```cpp
void Dependences::print(raw_ostream &OS) const;
void Dependences::dump() const;
```

- **功能**：
  - 打印 RAW、WAR、WAW、RED 和 TC_RED 依赖到指定输出流（`dump` 使用 `dbgs()`）。

#### 3.2 `DependenceInfo` 类

`DependenceInfo` 继承自 `ScopPass`，为每个 SCoP 提供依赖分析。

##### 3.2.1 核心方法

###### `runOnScop`

```cpp
bool DependenceInfo::runOnScop(Scop &ScopVar);
```

- 初始化 SCoP 指针（`S`），返回 `false`（不修改 IR）。

###### `getDependences` 和 `recomputeDependences`

```cpp
const Dependences &DependenceInfo::getDependences(Dependences::AnalysisLevel Level);
const Dependences &DependenceInfo::recomputeDependences(Dependences::AnalysisLevel Level);
```

- 返回指定分析级别的依赖（`D[Level]`），若不存在则重新计算。

###### `printScop`

```cpp
void DependenceInfo::printScop(raw_ostream &OS, Scop &S) const;
```

- 打印 SCoP 的依赖信息，使用当前分析级别（`OptAnalysisLevel`）。

###### `getAnalysisUsage`

```cpp
void DependenceInfo::getAnalysisUsage(AnalysisUsage &AU) const;
```

- 声明依赖 `ScopInfoRegionPass`，设置 `setPreservesAll`。

#### 3.3 `DependenceInfoWrapperPass` 类

`DependenceInfoWrapperPass` 继承自 `FunctionPass`，为函数中的所有 SCoP 计算依赖。

##### 3.3.1 核心方法

###### `runOnFunction`

```cpp
bool DependenceInfoWrapperPass::runOnFunction(Function &F);
```

- 遍历函数的 SCoP（通过 `ScopInfoWrapperPass`），为每个 SCoP 计算访问级依赖（`AL_Access`）。

###### `getDependences` 和 `recomputeDependences`

```cpp
const Dependences &DependenceInfoWrapperPass::getDependences(Scop *S, Dependences::AnalysisLevel Level);
const Dependences &DependenceInfoWrapperPass::recomputeDependences(Scop *S, Dependences::AnalysisLevel Level);
```

- 返回指定 SCoP 和级别的依赖，若不存在则重新计算。

###### `print`

```cpp
void DependenceInfoWrapperPass::print(raw_ostream &OS, const Module *M) const;
```

- 打印所有 SCoP 的依赖信息。

###### `getAnalysisUsage`

```cpp
void DependenceInfoWrapperPass::getAnalysisUsage(AnalysisUsage &AU) const;
```

- 声明依赖 `ScopInfoWrapperPass`，设置 `setPreservesAll`。

---

### 4. 实现细节和优化

- **多面体模型**：
  - 使用 ISL 的 `isl_union_map` 和 `isl_union_set` 表示依赖和访问关系。
  - 依赖映射格式为 `{ Stmt[i] -> Stmt[j] }` 或 `{ [Stmt[i] -> Array[f(i)]] -> [Stmt[j] -> Array[f(j)]] }`（细粒度）。
  - 约减依赖通过传递闭包（`TC_RED`）建模，支持私有化优化。

- **精确依赖分析**：
  - `VALUE_BASED_ANALYSIS` 确保只返回最近的写依赖（如 `Read -> MustWrite`），避免冗余。
  - `MEMORY_BASED_ANALYSIS` 提供过近似依赖，适用于快速分析。

- **约减处理**：
  - 识别约减访问（`isReductionLike`），确保语句内只有一个读和一个写。
  - 使用 `StrictWAW` 检测无中间读的写到写依赖。
  - 私有化依赖扩展约减访问的影响范围，优化并行性。

- **细粒度分析**：
  - 引用级（`AL_Reference`）标记数组 ID，访问级（`AL_Access`）标记访问指令 ID。
  - 约减访问使用标记调度树（`pullback_union_pw_multi_aff`）支持细粒度依赖。

- **性能优化**：
  - 使用 `IslMaxOperationsGuard` 限制计算步数（`OptComputeOut`）。
  - 合并映射（`coalesce`）和检测等价性（`detect_equalities`）以优化表示。

---

### 5. 示例分析

考虑以下 C 代码：

```c
void example(int *sum, int A[], int N) {
    *sum = 0;                    // S0
    for (int i = 0; i < N; i++)  // S1
        *sum += A[i];
    *sum = *sum * 3;            // S2
}
```

`DependenceInfo` 的处理流程如下：

1. **SCoP 构建**（由 `ScopInfo` 完成）：
   - 迭代域：`{ S0[]; S1[i] : 0 <= i < N; S2[] }`
   - 访问关系：
     - S0: `Write: { S0[] -> sum[] }`
     - S1: `Read: { S1[i] -> A[i] }`, `Read: { S1[i] -> sum[] }`, `Write: { S1[i] -> sum[] }`
     - S2: `Read: { S2[] -> sum[] }`, `Write: { S2[] -> sum[] }`
   - 调度：`{ S0[] -> [0]; S1[i] -> [1,i]; S2[] -> [2] }`

2. **收集信息**（`collectInfo`）：
   - `Read`: `{ S1[i] -> A[i]; S1[i] -> sum[]; S2[] -> sum[] }`
   - `MustWrite`: `{ S0[] -> sum[]; S1[i] -> sum[]; S2[] -> sum[] }`
   - `MayWrite`: `{}`
   - `ReductionTagMap`: `{ [S1[i] -> sum[]] -> sum[] }`
   - `TaggedStmtDomain`: `{ S0[]; S1[i]; S2[] }`

3. **约减检测**：
   - S1 的 `sum` 访问标记为约减（`isReductionLike`）。
   - `StrictWAW`: `{ S1[i] -> S1[i+1] : 0 <= i < N-1 }`

4. **依赖计算**（`calculateDependences`）：
   - RAW:
     - `{ S0[] -> S1[0]; S1[i] -> S2[] : 0 <= i < N }`
   - WAW:
     - `{ S0[] -> S1[0]; S1[i] -> S2[] : 0 <= i < N }`
   - WAR: `{}`
   - RED: `{ S1[i] -> S1[i+1] : 0 <= i < N-1 }`
   - TC_RED: `{ S1[i] -> S1[j] : 0 <= i < j < N }`
   - 私有化后：
     - RAW: `{ S0[] -> S1[i] : 0 <= i < N; S1[i] -> S2[] : 0 <= i < N }`
     - WAW: 同上

5. **并行性检查**（`isParallel`）：
   - 对于循环 `i`：
     - 调度：`{ S1[i] -> [i] }`
     - 依赖映射后：`{ S1[i] -> S1[j] : i < j }`
     - 距离非零（`j - i >= 1`），返回 `false`（不可并行）。

---

### 6. 与其他文件的关联

- **与 `PolyhedralInfo.cpp`**：
  - `DependenceInfo` 提供依赖数据，供 `PolyhedralInfo::checkParallel` 使用。
  - `PolyhedralInfo` 调用 `Dependences::isParallel` 验证循环并行性。
  - 两者共享 `ScopInfo` 和 ISL 上下文，依赖 `DependenceInfoWrapperPass`。

- **与 `ScheduleOptimizer.cpp`**：
  - `DependenceInfo` 的依赖信息用于 `IslScheduleOptimizer::runOnScop` 的调度优化。
  - `Dependences::isValidSchedule` 验证新调度的合法性。
  - 约减依赖和私有化依赖支持矩阵乘法优化和平行化。

---

### 7. 总结

`DependenceInfo.cpp` 是 Polly 框架中依赖分析的核心模块，基于 ISL 提供精确的 RAW、WAR、WAW 和约减依赖分析。其设计特点包括：

- **精确性**：通过 `VALUE_BASED_ANALYSIS` 和 WAR 过滤确保无冗余依赖。
- **约减支持**：处理约减依赖和私有化依赖，优化并行性。
- **多粒度分析**：支持语句级、引用级和访问级分析，灵活适应不同优化需求。
- **调试友好**：提供详细的依赖打印和调试支持。

