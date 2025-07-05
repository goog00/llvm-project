以下是对 `ScopBuilder.cpp` 文件的详细解释，内容以中文呈现，力求清晰、简洁且全面，帮助理解 Polly 项目中 `ScopBuilder` 类在构建 SCoP（静态控制流部分）描述时的作用和实现逻辑。该文件是 LLVM 编译器基础设施中 Polly 优化框架的一部分，负责将检测到的 SCoP 区域从 LLVM IR 转换为多面体模型的表示，为后续优化（如循环变换、并行化、向量化）提供基础。

---

### 1. 文件概述

`ScopBuilder.cpp` 是 Polly 框架中用于构建 SCoP 表示的核心实现文件。它基于 `ScopDetection` 检测到的 SCoP 区域，从 LLVM IR 中提取信息，构造多面体模型的描述，包括迭代域、访问关系、调度等。`ScopBuilder` 类通过分析 LLVM IR 的控制流、内存访问和循环结构，生成 `Scop`、`ScopStmt`、`ScopArrayInfo` 和 `MemoryAccess` 等对象，最终形成一个完整的 SCoP 表示。

文件的主要功能包括：

1. **SCoP 构建**：从 LLVM 区域（`Region`）生成 SCoP 数据结构。
2. **语句划分**：将基本块或区域划分为 `ScopStmt`，支持不同粒度的划分策略。
3. **内存访问建模**：分析指令中的内存访问，生成 `MemoryAccess` 对象，支持数组、标量、PHI 节点和内存内在函数。
4. **调度生成**：为 SCoP 构建执行顺序（调度树），支持嵌套循环。
5. **优化支持**：处理不变量加载（invariant loads）、别名分析、约减操作等，为后续优化提供基础。
6. **验证和简化**：验证 SCoP 的可行性，简化上下文和访问关系。

---

### 2. 文件头部和全局配置

#### 2.1 头文件和依赖

文件包含了 Polly 和 LLVM 的多个模块：

```cpp
#include "polly/ScopBuilder.h"
#include "polly/ScopDetection.h"
#include "polly/ScopInfo.h"
#include "polly/Support/GICHelper.h"
#include "polly/Support/ISLTools.h"
#include "polly/Support/SCEVValidator.h"
#include "llvm/Analysis/AliasAnalysis.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/ScalarEvolution.h"
```

- **Polly 模块**：`ScopDetection` 用于检测 SCoP，`ScopInfo` 定义核心数据结构，`GICHelper` 和 `ISLTools` 提供 ISL（Integer Set Library）相关的辅助功能，`SCEVValidator` 验证标量演化表达式（SCEV）的仿射性。
- **LLVM 模块**：包括 `AliasAnalysis`（别名分析）、`LoopInfo`（循环信息）、`ScalarEvolution`（标量演化分析）、`DominatorTree`（支配树）等，用于分析 LLVM IR 的控制流和数据依赖。
- **ISL 库**：通过 `isl-noexceptions.h` 提供多面体运算支持。

#### 2.2 统计和配置选项

文件定义了一些统计变量和命令行选项，用于控制 Polly 的行为：

- **统计变量**：
  ```cpp
  STATISTIC(ScopFound, "Number of valid Scops");
  STATISTIC(RichScopFound, "Number of Scops containing a loop");
  STATISTIC(InfeasibleScops, "Number of SCoPs with statically infeasible context.");
  ```
  用于跟踪有效 SCoP、包含循环的 SCoP 和不可行 SCoP 的数量。

- **命令行选项**：
  - `ModelReadOnlyScalars`：是否建模只读标量值（默认开启）。
  - `MaxDimensionsInAccessRange`：限制访问范围的最大维度（默认 9），防止编译时间过长。
  - `PollyAllowDereferenceOfAllFunctionParams`：允许将所有函数指针参数视为可解引用，用于不变量加载提升。
  - `RunTimeChecksMaxArraysPerGroup` 和 `RunTimeChecksMaxParameters`：限制运行时别名检查的数组和参数数量。
  - `UnprofitableScalarAccs`：将包含标量访问的语句视为不可优化。
  - `UserContextStr`：允许用户指定额外的上下文约束。
  - `DetectFortranArrays`：检测 Fortran 数组，支持 Fortran 代码生成。
  - `DetectReductions` 和 `DisableMultiplicativeReductions`：控制约减操作的检测和禁用乘法约减。
  - `StmtGranularity`：控制语句划分的粒度，支持三种策略：
    - `BasicBlocks`：每个基本块一个语句。
    - `ScalarIndependence`：基于标量独立性划分。
    - `Stores`：在存储指令处分割语句。

这些选项提供了灵活的配置，适应不同的优化需求和性能权衡。

---

### 3. ScopBuilder 类结构

`ScopBuilder` 类是文件的主体，负责从 LLVM 区域构造 SCoP。其构造函数和主要方法如下：

#### 3.1 构造函数

```cpp
ScopBuilder::ScopBuilder(Region *R, AssumptionCache &AC, AliasAnalysis &AA,
                         const DataLayout &DL, DominatorTree &DT, LoopInfo &LI,
                         ScopDetection &SD, ScalarEvolution &SE,
                         OptimizationRemarkEmitter &ORE)
    : AA(AA), DL(DL), DT(DT), LI(LI), SD(SD), SE(SE), ORE(ORE) {
```

- **参数**：
  - `R`：要分析的 LLVM 区域（`Region`）。
  - `AC`：假设缓存，用于跟踪优化假设。
  - `AA`：别名分析，用于确定指针是否可能指向相同内存。
  - `DL`：数据布局，提供类型大小和对齐信息。
  - `DT`：支配树，分析控制流依赖。
  - `LI`：循环信息，获取循环结构。
  - `SD`：SCoP 检测器，提供检测到的 SCoP 信息。
  - `SE`：标量演化分析，用于解析循环边界和内存访问。
  - `ORE`：优化备注发射器，记录分析和优化信息。

- **功能**：
  初始化 `Scop` 对象，调用 `buildScop` 方法构建 SCoP，并记录统计信息。如果 SCoP 不可行（上下文不满足条件），则销毁 `Scop` 对象。

#### 3.2 核心方法

`buildScop` 是构建 SCoP 的入口方法，协调以下步骤：

1. **初始化 Scop 对象**：
   ```cpp
   scop.reset(new Scop(R, SE, LI, DT, *SD.getDetectionContext(&R), ORE));
   ```
   创建 `Scop` 对象，初始化区域、标量演化和循环信息。

2. **构建语句**：
   调用 `buildStmts` 将区域划分为 `ScopStmt`。

3. **处理不变量加载**：
   为不变量加载（`RequiredInvariantLoads`）创建内存访问。

4. **构建访问函数**：
   调用 `buildAccessFunctions` 为每个语句生成内存访问（`MemoryAccess`）。

5. **处理退出块 PHI 节点**：
   为区域退出块的 PHI 节点建模标量访问。

6. **生成全局读访问**：
   为全局只读访问添加 `MemoryAccess`。

7. **构建不变量等价类**：
   调用 `buildInvariantEquivalenceClasses` 处理不变量加载的等价类。

8. **构建域和访问关系**：
   调用 `buildDomains`、`buildAccessRelations` 和 `collectSurroundingLoops` 设置语句的迭代域和访问关系。

9. **检测约减操作**：
   如果启用 `DetectReductions`，调用 `checkForReductions` 检测约减模式。

10. **构建调度**：
    调用 `buildSchedule` 生成 SCoP 的调度树。

11. **完成访问关系**：
    调用 `finalizeAccesses` 调整访问关系的元素大小和维度。

12. **添加用户上下文和假设**：
    调用 `addUserContext` 和 `addRecordedAssumptions` 加入用户定义的上下文和假设。

13. **别名检查**：
    调用 `buildAliasChecks` 生成运行时别名检查。

14. **提升不变量加载**：
    调用 `hoistInvariantLoads` 和 `canonicalizeDynamicBasePtrs` 优化不变量加载。

15. **验证和简化**：
    调用 `verifyInvariantLoads`、`simplifySCoP` 和 `verifyUses` 验证 SCoP 的正确性并简化表示。

---

### 4. 核心功能详解

以下是对 `ScopBuilder` 类中关键方法的详细分析，突出其实现逻辑和作用。

#### 4.1 构建语句 (`buildStmts`)

`buildStmts` 方法将区域划分为 `ScopStmt`，支持不同粒度的划分策略：

- **非仿射子区域**：
  ```cpp
  if (scop->isNonAffineSubRegion(&SR)) {
      std::vector<Instruction *> Instructions;
      Loop *SurroundingLoop = getFirstNonBoxedLoopFor(SR.getEntry(), LI, scop->getBoxedLoops());
      for (Instruction &Inst : *SR.getEntry())
          if (shouldModelInst(&Inst, SurroundingLoop))
              Instructions.push_back(&Inst);
      long RIdx = scop->getNextStmtIdx();
      std::string Name = makeStmtName(&SR, RIdx);
      scop->addScopStmt(&SR, Name, SurroundingLoop, Instructions);
  }
  ```
  非仿射子区域（如条件分支或复杂控制流）被建模为单个 `ScopStmt`，包含入口块的指令。

- **基本块**：
  根据 `StmtGranularity` 选项，采用不同策略：
  - **`BasicBlocks`**：调用 `buildSequentialBlockStmts(BB)`，每个基本块生成一个 `ScopStmt`。
  - **`Stores`**：调用 `buildSequentialBlockStmts(BB, true)`，在存储指令处分割语句。
  - **`ScalarIndependence`**：调用 `buildEqivClassBlockStmts`，基于标量依赖划分语句，使用等价类（`EquivalenceClasses`）合并相关指令。

- **语句命名**：
  使用 `makeStmtName` 生成 ISL 兼容的语句名称，格式为 `Stmt_<BB/Region>_<Index>_<Suffix>`，支持调试和唯一性。

#### 4.2 构建内存访问 (`buildAccessFunctions` 和相关方法)

内存访问是 SCoP 的核心组件，`buildAccessFunctions` 为每个语句生成 `MemoryAccess` 对象，处理以下类型的访问：

- **PHI 节点** (`buildPHIAccesses`)：
  - 将 PHI 节点建模为读写操作，读操作（`MemoryAccess::READ`）表示 PHI 节点的读取，写操作（`MemoryAccess::MUST_WRITE` 或 `MemoryKind::ExitPHI`）表示来自前驱块的写入。
  - 对于退出块的 PHI 节点，只建模前驱块的写入。
  - 使用 `ensurePHIWrite` 和 `addPHIReadAccess` 确保正确的数据流。

- **内存指令** (`buildMemoryAccess`)：
  支持以下类型的内存访问：
  - **固定多维访问** (`buildAccessMultiDimFixed`)：处理 `GetElementPtrInst`（GEP）指令，提取下标和维度大小，生成仿射访问。
  - **参数化多维访问** (`buildAccessMultiDimParam`)：处理动态数组（通过去线性化），使用预计算的去线性化信息。
  - **内存内在函数** (`buildAccessMemIntrinsic`)：处理 `memcpy` 等内在函数，建模为读写访问。
  - **函数调用** (`buildAccessCallInst`)：处理可能访问内存的函数调用，区分只读和读写行为。
  - **单维访问** (`buildAccessSingleDim`)：处理标量或简单数组访问，检查是否为仿射表达式。

- **标量依赖** (`buildScalarDependences`)：
  确保指令的操作数被正确读取（`ensureValueRead`），为标量值生成 `MemoryAccess::READ`。

- **逃逸依赖** (`buildEscapingDependences`)：
  为在 SCoP 外部使用的值生成写访问（`ensureValueWrite`）。

#### 4.3 构建调度 (`buildSchedule`)

`buildSchedule` 方法生成 SCoP 的调度树，表示语句的执行顺序：

- **遍历方式**：
  使用逆后序遍历（`ReversePostOrderTraversal`）处理区域节点（`RegionNode`），确保依赖顺序正确。

- **循环处理**：
  - 使用 `LoopStack` 跟踪当前循环嵌套，包含循环（`Loop`）、调度（`Schedule`）和处理的基本块数量（`NumBlocksProcessed`）。
  - 当遇到循环头时，将循环加入 `LoopStack`，优先处理循环内的节点。
  - 使用 `combineInSequence` 组合语句的调度，形成顺序执行的调度树。

- **调度生成**：
  - 为每个语句生成基于其迭代域的调度（`isl::schedule::from_domain`）。
  - 使用 `mapToDimension` 将迭代域映射到指定维度，构建多维调度。
  - 在循环结束时，插入部分调度（`insert_partial_schedule`），并将子调度合并到父循环。

#### 4.4 不变量加载处理 (`hoistInvariantLoads` 和 `buildInvariantEquivalenceClasses`)

- **不变量加载提升**：
  - 方法 `hoistInvariantLoads` 将不随循环变化的加载（invariant loads）从语句中移除，添加到 SCoP 的全局不变量等价类（`InvariantEquivClassTy`）。
  - 检查加载是否可以无条件提升（`canAlwaysBeHoisted`），考虑指针可解引用性、语句上下文和别名信息。
  - 使用 `getNonHoistableCtx` 检查加载是否可能被写入，若安全则提升。

- **等价类构建**：
  - 方法 `buildInvariantEquivalenceClasses` 根据加载的指针和类型（`SCEV` 和 `Type`）分组，形成等价类。
  - 确保相同地址的加载共享一个 `ScopArrayInfo` 对象。

#### 4.5 约减操作检测 (`checkForReductions`)

- 方法 `checkForReductions` 检测约减模式（如累加、位运算），生成 `MemoryAccess::ReductionType`：
  - 收集候选的加载-存储对（`collectCandidateReductionLoads`），要求存储的输入来自二元运算（`BinaryOperator`），且运算符是可交换和结合的（如 `Add`、`Or`）。
  - 检查加载和存储的访问关系是否重叠（`isl::map::is_equal`），确保无其他访问干扰。
  - 支持的约减类型包括 `ADD`、`BOR`、`BXOR`、`BAND` 和 `MUL`（可通过 `DisableMultiplicativeReductions` 禁用）。

#### 4.6 别名检查 (`buildAliasChecks` 和相关方法)

- **别名分组** (`buildAliasGroups`)：
  - 使用 `AliasSetTracker` 识别可能别名的指针，形成 `AliasGroupTy`。
  - 将访问分为只读（`ReadOnlyAccesses`）和读写（`ReadWriteAccesses`），分别计算最小/最大访问范围（`calculateMinMaxAccess`）。
  - 使用 `buildMinMaxAccess` 计算访问的上下界（`lexmin` 和 `lexmax`），生成运行时检查。

- **域分割** (`splitAliasGroupsByDomain`)：
  - 根据访问的迭代域（`getAccessDomain`）分割别名组，减少检查的复杂性。

- **限制**：
  - 通过 `RunTimeChecksMaxArraysPerGroup` 和 `RunTimeChecksMaxParameters` 限制检查规模。
  - 如果无法生成有效检查，调用 `invalidate(ALIASING)` 标记 SCoP 不可行。

#### 4.7 Fortran 数组支持 (`isFortranArrayDescriptor` 和 `findFADAllocationVisible/Invisible`)

- 方法 `isFortranArrayDescriptor` 检查值是否为 Fortran 数组描述符，验证其类型结构（如 `struct.array*`）。
- 方法 `findFADAllocationVisible` 和 `findFADAllocationInvisible` 识别 Fortran 数组的分配模式，处理 `malloc` 调用和 GEP 指令。

#### 4.8 验证和简化

- **验证使用** (`verifyUses`)：
  - 检查物理使用（基于基本块）和虚拟使用（基于 `MemoryAccess`）的一致性，确保标量访问正确。
  - 在调试模式下运行（`#ifndef NDEBUG`）。

- **简化 SCoP** (`simplifySCoP`)：
  - 移除空语句（`removeStmtNotInDomainMap`）。
  - 简化上下文（`simplifyContexts`）和访问关系（`foldAccessRelations`）。

- **上下文和假设**：
  - `addUserContext` 加入用户指定的上下文约束（`UserContextStr`）。
  - `addRecordedAssumptions` 添加记录的假设（如别名、不变量加载）。

---

### 5. 实现细节和优化

- **多面体模型**：
  使用 ISL 库操作多面体对象（如 `isl::set`、`isl::map`、`isl::pw_multi_aff`），表示迭代域、访问关系和调度。

- **标量建模**：
  标量值（`Value`）通过 `MemoryKind::Value` 和 `MemoryKind::PHI` 建模为虚拟内存对象，解决多面体模型对 SSA 形式的限制。

- **不变量加载提升**：
  通过 `hoistInvariantLoads` 将不变量加载移到 SCoP 全局，减少冗余加载。

- **约减优化**：
  检测并标记约减操作，支持后续并行化或向量化。

- **别名分析**：
  使用 `AliasAnalysis` 和运行时检查（`buildAliasChecks`）确保内存访问的正确性，必要时生成运行时条件。

- **性能优化**：
  - 使用 `MaxDimensionsInAccessRange` 和 `RunTimeChecksMaxAccessDisjuncts` 限制复杂访问的处理。
  - 通过 `simplify` 和 `coalesce` 简化 ISL 对象，减少计算开销。

---

### 6. 示例分析

考虑以下 C 代码：

```c
void example(int A[], int n) {
    for (int i = 0; i < n; ++i)
        for (int j = 0; j < n; ++j)
            A[i + j] += 1;
}
```

`ScopBuilder` 的处理流程如下：

1. **SCoP 检测**：
   `ScopDetection` 识别循环为 SCoP，包含两个嵌套循环。

2. **语句划分** (`buildStmts`)：
   - 内层循环体 `A[i + j] += 1` 形成一个 `ScopStmt`，命名为 `Stmt_example_0`。
   - 迭代域为 `{ Stmt_example_0[i,j] : 0 <= i < n, 0 <= j < n }`。

3. **内存访问** (`buildAccessFunctions`)：
   - 加载 `A[i + j]`：生成 `MemoryAccess::READ`，访问关系为 `{ Stmt_example_0[i,j] -> A[i + j] }`。
   - 存储 `A[i + j]`：生成 `MemoryAccess::MUST_WRITE`，访问关系同上。
   - 检测约减操作（`+=`），标记为 `MemoryAccess::RT_ADD`。

4. **调度生成** (`buildSchedule`)：
   - 调度为 `{ Stmt_example_0[i,j] -> [i, j] }`，表示按 `i` 和 `j` 顺序执行。

5. **别名检查** (`buildAliasChecks`)：
   - 确认 `A` 是唯一数组，无别名冲突。

6. **最终 SCoP**：
   - `Scop` 包含一个语句、两个内存访问和一个调度树。
   - 上下文为 `{ [n] : n >= 0 }`。

后续优化可进行循环交换、向量化或并行化。

---

### 7. 总结

`ScopBuilder.cpp` 是 Polly 框架中从 LLVM IR 构建 SCoP 表示的核心实现，涵盖了语句划分、内存访问建模、调度生成、不变量加载提升、约减检测和别名分析等功能。其设计特点包括：

- **模块化**：通过多个方法分解复杂任务，便于维护和扩展。
- **多面体支持**：深度整合 ISL 库，精确建模循环和内存访问。
- **灵活性**：支持多种语句粒度、Fortran 数组和用户定义上下文。
- **优化导向**：为并行化、向量化等优化奠定基础。

