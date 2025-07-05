以下是对 `ScheduleOptimizer.cpp` 文件的详细解释，内容以中文呈现，力求清晰、简洁且全面，帮助理解 LLVM 项目中 Polly 优化框架的调度优化模块。该文件是 Polly 框架的核心组成部分，负责基于数据依赖和迭代域生成优化的调度树（Schedule Tree），以最大化并行性、平铺性和数据局部性，同时最小化数据依赖距离。优化过程基于多面体模型，结合 ISL（Integer Set Library）库的调度优化器和一系列后调度变换（如平铺、预向量化、矩阵乘法模式优化等）。

---

### 1. 文件概述

`ScheduleOptimizer.cpp` 实现了 `IslScheduleOptimizer` 类，作为 Polly 的一个 `ScopPass`，其主要功能是从 SCoP（静态控制流部分）的迭代域和依赖关系中生成一个新的调度树，优化程序的执行顺序以提高性能。优化过程分为两个主要阶段：

1. **ISL 调度优化**：
   使用 ISL 库的调度优化器（基于 Pluto 算法的变种）生成初始调度树，目标是最大化并行性、平铺性和数据局部性，参考文献为 Bondhugula 等人的《A Practical Automatic Polyhedral Parallelizer and Locality Optimizer》（PLDI 2008）。

2. **后调度变换**：
   在初始调度树上应用一系列变换，包括：
   - **平铺（Tiling）**：将循环分为平铺循环（tile loops）和点循环（point loops），优化缓存局部性。
   - **预向量化（Prevectorization）**：通过条带挖掘（strip-mining）调整循环结构，支持向量化。
   - **矩阵乘法模式优化**：识别矩阵乘法模式，应用 BLIS（Basic Linear Algebra Subprograms）优化的微内核和宏内核变换。
   - **数据布局优化**：调整数组访问模式以实现顺序访问和缓存对齐。

文件还提供了统计信息收集、命令行选项配置以及对目标体系结构的适配（如缓存参数、向量寄存器宽度等）。

---

### 2. 文件头部和全局配置

#### 2.1 头文件和依赖

文件包含了以下关键头文件：

```cpp
#include "polly/ScheduleOptimizer.h"
#include "polly/CodeGen/CodeGeneration.h"
#include "polly/DependenceInfo.h"
#include "polly/ScopInfo.h"
#include "polly/ScheduleTreeTransform.h"
#include "polly/Simplify.h"
#include "llvm/Analysis/TargetTransformInfo.h"
#include "isl/schedule.h"
#include "isl/schedule_node.h"
```

- **Polly 模块**：
  - `DependenceInfo`：提供 SCoP 的数据依赖信息。
  - `ScopInfo`：定义 SCoP 数据结构（如 `Scop`、`ScopStmt`）。
  - `ScheduleTreeTransform`：提供调度树变换工具。
  - `Simplify`：用于简化 ISL 对象。
- **LLVM 模块**：
  - `TargetTransformInfo`：提供目标体系结构信息（如缓存大小、向量寄存器宽度）。
- **ISL 库**：
  - 提供多面体运算支持（如 `isl::schedule`、`isl::schedule_node`）。

#### 2.2 命令行选项

文件定义了大量命令行选项，用于控制调度优化的行为：

- **依赖优化选项**：
  - `OptimizeDeps`：选择优化的依赖类型（`all` 或 `raw`，默认 `all`）。
  - `SimplifyDeps`：是否简化依赖关系（`yes` 或 `no`，默认 `yes`）。

- **调度约束**：
  - `MaxConstantTerm`：最大常数项（默认 20）。
  - `MaxCoefficient`：最大系数（默认 20）。
  - `FusionStrategy`：融合策略（`min` 或 `max`，默认 `min`）。
  - `MaximizeBandDepth`：是否最大化带节点深度（默认 `yes`）。
  - `OuterCoincidence`：是否在外层带节点满足一致性约束（默认 `no`）。

- **平铺选项**：
  - `FirstLevelTiling`：是否启用一级平铺（默认 `true`）。
  - `SecondLevelTiling`：是否启用二级平铺（默认 `false`）。
  - `RegisterTiling`：是否启用寄存器平铺（默认 `false`）。
  - `FirstLevelTileSizes` 和 `SecondLevelTileSizes`：指定平铺尺寸。
  - `FirstLevelDefaultTileSize`（默认 32）、`SecondLevelDefaultTileSize`（默认 16）、`RegisterDefaultTileSize`（默认 2）。

- **预向量化选项**：
  - `PrevectorWidth`：预向量化的条带挖掘宽度（默认 4）。
  - `PollyVectorizerChoice`：向量化策略（未在代码中定义具体值，需通过外部配置）。

- **目标体系结构选项**：
  - `LatencyVectorFma`：向量融合乘加指令的延迟（默认 8 周期）。
  - `ThroughputVectorFma`：向量融合乘加指令的吞吐量（默认 1 次/周期）。
  - `FirstCacheLevelSize`、`SecondCacheLevelSize`：一级和二级缓存大小（默认 32KB 和 256KB）。
  - `FirstCacheLevelAssociativity`、`SecondCacheLevelAssociativity`：缓存关联度（默认 8）。
  - `VectorRegisterBitwidth`：向量寄存器宽度（默认从 `TargetTransformInfo` 获取）。

- **矩阵乘法优化**：
  - `PMBasedOpts`：是否启用基于模式匹配的优化（默认 `true`）。
  - `PollyPatternMatchingNcQuotient`：宏内核参数 `Nc` 和微内核参数 `Nr` 的商（默认 256）。

- **调试和输出**：
  - `OptimizedScops`：是否打印优化后的 SCoP（默认 `false`）。

#### 2.3 统计变量

文件定义了多个统计变量，用于跟踪优化过程：

```cpp
STATISTIC(ScopsProcessed, "Number of scops processed");
STATISTIC(ScopsRescheduled, "Number of scops rescheduled");
STATISTIC(ScopsOptimized, "Number of scops optimized");
STATISTIC(NumAffineLoopsOptimized, "Number of affine loops optimized");
STATISTIC(NumBoxedLoopsOptimized, "Number of boxed loops optimized");
THREE_STATISTICS(NumBands, "Number of bands");
THREE_STATISTICS(NumBandMembers, "Number of band members");
THREE_STATISTICS(NumCoincident, "Number of coincident band members");
THREE_STATISTICS(NumPermutable, "Number of permutable bands");
THREE_STATISTICS(NumFilters, "Number of filter nodes");
THREE_STATISTICS(NumExtension, "Number of extension nodes");
STATISTIC(FirstLevelTileOpts, "Number of first level tiling applied");
STATISTIC(SecondLevelTileOpts, "Number of second level tiling applied");
STATISTIC(RegisterTileOpts, "Number of register tiling applied");
STATISTIC(PrevectOpts, "Number of strip-mining for prevectorization applied");
STATISTIC(MatMulOpts, "Number of matrix multiplication patterns detected and optimized");
```

这些统计变量记录了调度树中不同节点的数量（如带节点、过滤节点、扩展节点）以及应用的具体优化次数（平铺、预向量化、矩阵乘法优化等）。

---

### 3. 核心类和方法

`ScheduleOptimizer.cpp` 的核心是 `IslScheduleOptimizer` 类（继承自 `ScopPass`）和 `ScheduleTreeOptimizer` 命名空间中的静态方法。以下详细分析其结构和功能。

#### 3.1 `IslScheduleOptimizer` 类

`IslScheduleOptimizer` 是 Polly 的一个优化 Pass，负责优化 SCoP 的调度树。

##### 3.1.1 构造函数和析构函数

```cpp
explicit IslScheduleOptimizer() : ScopPass(ID) {}
~IslScheduleOptimizer() override { isl_schedule_free(LastSchedule); }
```

- 构造函数初始化基类 `ScopPass`，析构函数释放上一次计算的调度（`LastSchedule`）。

##### 3.1.2 `runOnScop`

`runOnScop` 是优化 Pass 的入口方法，执行调度优化并更新 SCoP：

```cpp
bool runOnScop(Scop &S) override;
```

- **输入检查**：
  - 跳过已标记为优化的 SCoP（`S.isToBeSkipped()`）或空 SCoP（`S.getSize() == 0`）。
  - 验证依赖信息（`DependenceInfo`）的有效性，确保与 SCoP 的 ISL 上下文一致。

- **依赖和域准备**：
  - 获取依赖（`Dependences`）和域（`Domain`）。
  - 根据 `OptimizeDeps` 选择优化哪些依赖（`RAW`、`WAR`、`WAW`），默认优化所有依赖。
  - 如果启用 `SimplifyDeps`，通过 `gist_domain` 和 `gist_range` 简化依赖关系，移除域约束以减少调度时间。

- **ISL 调度优化**：
  - 配置 ISL 选项（如 `schedule_outer_coincidence`、`schedule_serialize_sccs`、`schedule_maximize_band_depth` 等）。
  - 使用 `isl::schedule_constraints` 设置域、有效性依赖（`validity`）、接近性依赖（`proximity`）和一致性依赖（`coincidence`）。
  - 调用 `SC.compute_schedule()` 计算初始调度树。

- **后调度变换**：
  - 调用 `ScheduleTreeOptimizer::optimizeSchedule` 应用平铺、预向量化或矩阵乘法优化。
  - 使用 `hoistExtensionNodes` 提升扩展节点（extension nodes），确保调度树结构正确。

- **调度有效性检查**：
  - 调用 `ScheduleTreeOptimizer::isProfitableSchedule` 检查新调度是否优于旧调度（基于调度映射是否发生变化）。
  - 如果调度有效，更新 SCoP 的调度树（`S.setScheduleTree`），标记为已优化（`S.markAsOptimized`）。

- **统计和输出**：
  - 更新统计变量（如 `ScopsProcessed`、`ScopsRescheduled`、`ScopsOptimized`）。
  - 如果启用 `OptimizedScops`，打印优化后的 SCoP。

##### 3.1.3 `printScop`

```cpp
void printScop(raw_ostream &OS, Scop &S) const override;
```

打印上一次计算的调度树（`LastSchedule`），使用 ISL 的打印功能。

##### 3.1.4 `getAnalysisUsage`

```cpp
void getAnalysisUsage(AnalysisUsage &AU) const override;
```

声明依赖的分析模块（`DependenceInfo` 和 `TargetTransformInfoWrapperPass`），并保留 `DependenceInfo`。

#### 3.2 `ScheduleTreeOptimizer` 命名空间

`ScheduleTreeOptimizer` 包含一系列静态方法，用于优化调度树节点和应用特定变换。

##### 3.2.1 `optimizeSchedule`

```cpp
isl::schedule optimizeSchedule(isl::schedule Schedule, const OptimizerAdditionalInfoTy *OAI);
```

- 入口方法，调用 `optimizeScheduleNode` 对调度树根节点进行递归优化。

##### 3.2.2 `optimizeScheduleNode`

```cpp
isl::schedule_node optimizeScheduleNode(isl::schedule_node Node, const OptimizerAdditionalInfoTy *OAI);
```

- 使用 `isl_schedule_node_map_descendant_bottom_up` 递归遍历调度树，自底向上应用 `optimizeBand` 方法优化带节点（band nodes）。

##### 3.2.3 `optimizeBand`

```cpp
__isl_give isl_schedule_node *optimizeBand(__isl_take isl_schedule_node *Node, void *User);
```

- **检查可平铺性**：
  - 调用 `isTileableBandNode` 检查带节点是否可平铺（需为 permutable、具有多个维度且子节点为简单结构）。

- **矩阵乘法模式优化**：
  - 如果启用 `PMBasedOpts` 且检测到矩阵乘法模式（`isMatrMultPattern`），调用 `optimizeMatMulPattern` 应用 BLIS 优化。
  - 增加 `MatMulOpts` 统计计数。

- **标准优化**：
  - 如果未检测到矩阵乘法模式，调用 `standardBandOpts` 应用一级平铺、二级平铺、寄存器平铺和预向量化。

##### 3.2.4 `isTileableBandNode`

```cpp
bool isTileableBandNode(isl::schedule_node Node);
```

- 检查带节点是否可平铺，要求：
  - 节点类型为 `isl_schedule_node_band`。
  - 只有一个子节点。
  - 带节点是可交换的（permutable）。
  - 具有多个维度（`Dims > 1`）。
  - 子节点为叶子节点或简单序列节点（`isSimpleInnermostBand`）。

##### 3.2.5 `standardBandOpts`

```cpp
__isl_give isl_schedule_node *standardBandOpts(isl::schedule_node Node, void *User);
```

- 应用标准优化：
  - **一级平铺**：调用 `tileNode` 使用 `FirstLevelTileSizes` 或 `FirstLevelDefaultTileSize`。
  - **二级平铺**：调用 `tileNode` 使用 `SecondLevelTileSizes` 或 `SecondLevelDefaultTileSize`。
  - **寄存器平铺**：调用 `applyRegisterTiling` 使用 `RegisterTileSizes` 或 `RegisterDefaultTileSize`，并设置 `unroll` 选项。
  - **预向量化**：调用 `prevectSchedBand` 在一致性维度（coincident dimension）上应用条带挖掘，宽度为 `PrevectorWidth`。

##### 3.2.6 `tileNode`

```cpp
isl::schedule_node tileNode(isl::schedule_node Node, const char *Identifier, ArrayRef<int> TileSizes, int DefaultTileSize);
```

- 应用平铺变换：
  - 创建平铺尺寸（`Sizes`），优先使用 `TileSizes`，否则使用 `DefaultTileSize`。
  - 插入标记节点（如 `1st level tiling - Tiles` 和 `1st level tiling - Points`）。
  - 调用 `isl_schedule_node_band_tile` 执行平铺。

##### 3.2.7 `prevectSchedBand`

```cpp
isl::schedule_node prevectSchedBand(isl::schedule_node Node, unsigned DimToVectorize, int VectorWidth);
```

- 应用预向量化变换：
  - 分割带节点（`isl_schedule_node_band_split`）以隔离要向量化的维度。
  - 应用平铺（宽度为 `VectorWidth`）。
  - 调用 `isolateFullPartialTiles` 隔离完整和部分平铺。
  - 设置 `unroll` 选项为禁用（防止向量化循环被展开）。
  - 插入 `SIMD` 标记节点，增加 `PrevectOpts` 计数。

##### 3.2.8 矩阵乘法模式优化相关方法

以下方法专门用于检测和优化矩阵乘法模式，基于 BLIS 框架。

- **isMatrMultPattern**：
  ```cpp
  bool isMatrMultPattern(isl::schedule_node Node, const Dependences *D, MatMulInfoTy &MMI);
  ```
  - 检查带节点是否表示矩阵乘法模式，要求：
    - 带节点有至少三个维度，子节点为叶子节点，调度深度为 0。
    - 包含单一语句（`isl_union_map_n_map == 1`）。
    - 调用 `containsMatrMult` 验证矩阵乘法模式：
      - 写访问为 `S(..., i, ..., j, ...) -> C[i, j]`。
      - 仅有一个循环传递依赖（`S(..., k, ...) -> S(..., k+1, ...)`）。
      - 包含三个读访问：`A[i, k]`、`B[k, j]` 和 `C[i, j]`。
      - 其他访问在循环交换后步幅为 0。

- **containsMatrMult**：
  ```cpp
  bool containsMatrMult(isl::map PartialSchedule, const Dependences *D, MatMulInfoTy &MMI);
  ```
  - 验证语句的内存访问和依赖是否符合矩阵乘法模式：
    - 检查最后一个数组写访问是否为 `C[i, j]`（`isMatMulOperandAcc`）。
    - 验证循环传递依赖（`containsOnlyMatMulDep`）。
    - 检查读访问是否为 `A[i, k]`、`B[k, j]` 和 `C[i, j]`（`isMatMulNonScalarReadAccess`）。
    - 确保其他访问在循环交换后步幅为 0（`containsOnlyMatrMultAcc`）。

- **optimizeMatMulPattern**：
  ```cpp
  isl::schedule_node optimizeMatMulPattern(isl::schedule_node Node, const TargetTransformInfo *TTI, MatMulInfoTy &MMI);
  ```
  - 应用矩阵乘法优化：
    - 标记 `C` 数组为“无迭代间别名”（`markInterIterationAliasFree`）。
    - 恢复原始维度顺序（`getBandNodeWithOriginDimOrder`）。
    - 交换维度以将 `i`, `j`, `k` 移到带节点末尾。
    - 获取微内核（`MicroKernelParams`）和宏内核（`MacroKernelParams`）参数。
    - 应用宏内核（`createMacroKernel`）和平铺（`Mc`, `Nc`, `Kc`）。
    - 应用微内核（`createMicroKernel`）和寄存器平铺（`Mr`, `Nr`）。
    - 禁用循环向量化（`markLoopVectorizerDisabled`）。
    - 隔离并展开内层循环（`isolateAndUnrollMatMulInnerLoops`）。
    - 优化数据布局（`optimizeDataLayoutMatrMulPattern`），为 `A` 和 `B` 创建新数组（`Packed_A`、`Packed_B`）并调整访问关系。

- **getMicroKernelParams** 和 **getMacroKernelParams**：
  - 计算 BLIS 微内核（`Mr`, `Nr`）和宏内核（`Mc`, `Nc`, `Kc`）参数，基于目标体系结构（`TTI`）、缓存参数和矩阵元素大小。
  - 微内核参数考虑向量寄存器宽度（`VectorRegisterBitwidth`）和 FMA 指令延迟（`LatencyVectorFma`）与吞吐量（`ThroughputVectorFma`）。
  - 宏内核参数考虑缓存大小（`FirstCacheLevelSize`, `SecondCacheLevelSize`）和关联度（`FirstCacheLevelAssociativity`, `SecondCacheLevelAssociativity`）。

- **optimizeDataLayoutMatrMulPattern**：
  - 应用数据布局变换，为 `A` 和 `B` 创建新数组（`Packed_A`, `Packed_B`），调整访问关系以实现顺序访问和缓存对齐。
  - 添加复制语句（`addScopStmt`）将数据从原始数组复制到新数组。

##### 3.2.9 辅助方法

- **getIsolateOptions** 和 **getDimOptions**：
  - 生成隔离选项（`isolate`）和维度选项（如 `unroll`, `atomic`），用于控制调度树的 AST 生成。

- **addExtentConstraints** 和 **getPartialTilePrefixes**：
  - 为向量化的循环添加范围约束，确保平铺边界正确。

- **permuteDimensions** 和 **permuteBandNodeDimensions**：
  - 交换调度映射或带节点的维度，用于调整循环顺序。

- **markInterIterationAliasFree** 和 **markLoopVectorizerDisabled**：
  - 插入标记节点，分别表示无迭代间别名和禁用循环向量化。

- **getBandNodeWithOriginDimOrder**：
  - 恢复带节点的原始维度顺序，用于矩阵乘法优化。

---

### 4. 实现细节和优化

- **多面体模型**：
  - 使用 ISL 库操作调度树（`isl::schedule`）、带节点（`isl::schedule_node_band`）、映射（`isl::map`）和集合（`isl::set`）。
  - 调度树由带节点、过滤节点、扩展节点等组成，表示循环嵌套和执行顺序。

- **矩阵乘法优化**：
  - 基于 BLIS 框架，通过微内核和宏内核优化矩阵乘法，适配目标体系结构的缓存和寄存器。
  - 数据布局变换（packing）确保顺序访问，减少缓存未命中。

- **平铺和向量化**：
  - 平铺分为一级（缓存）、二级（额外缓存层）和寄存器级，支持多层次内存层次结构。
  - 预向量化通过条带挖掘调整循环，适配 SLP 向量化器。

- **依赖处理**：
  - 使用 `DependenceInfo` 提供 RAW、WAR 和 WAW 依赖。
  - 简化依赖（`gist_domain` 和 `gist_range`）以减少调度开销。

- **目标体系结构适配**：
  - 通过 `TargetTransformInfo` 获取缓存大小、关联度和向量寄存器宽度。
  - 默认值基于 Intel Core i7-3820 SandyBridge 体系结构。

---

### 5. 示例分析

考虑以下矩阵乘法代码：

```c
void matmul(double A[], double B[], double C[], int N, int M, int P) {
    for (int i = 0; i < N; i++)
        for (int j = 0; j < M; j++)
            for (int k = 0; k < P; k++)
                C[i * M + j] += A[i * P + k] * B[k * M + j];
}
```

`IslScheduleOptimizer` 的处理流程如下：

1. **SCoP 检测和构建**：
   - `ScopBuilder` 识别循环为 SCoP，生成迭代域 `{ Stmt_matmul[i,j,k] : 0 <= i < N, 0 <= j < M, 0 <= k < P }`。
   - 内存访问：`C[i,j]`（写）、`A[i,k]`（读）、`B[k,j]`（读）、`C[i,j]`（读）。

2. **依赖分析**：
   - `DependenceInfo` 检测到循环传递依赖 `{ Stmt_matmul[i,j,k] -> Stmt_matmul[i,j,k+1] }`。

3. **ISL 调度优化**：
   - 生成初始调度树，调度为 `{ Stmt_matmul[i,j,k] -> [i,j,k] }`。
   - 简化依赖（如果启用 `SimplifyDeps`）。

4. **矩阵乘法模式检测**：
   - `isMatrMultPattern` 确认语句符合矩阵乘法模式，设置 `MMI.i=0`, `MMI.j=1`, `MMI.k=2`。

5. **优化调度树**：
   - 应用宏内核平铺（如 `Mc=64`, `Nc=256`, `Kc=128`）。
   - 应用微内核平铺（如 `Mr=4`, `Nr=8`）。
   - 调整调度为 `{ Stmt_matmul[i,j,k] -> [floor(i/64), floor(j/256), floor(k/128), floor((i mod 64)/4), floor((j mod 256)/8), k mod 128, j mod 8, i mod 4] }`。
   - 创建新数组 `Packed_A` 和 `Packed_B`，调整访问关系为顺序访问。
   - 插入复制语句将数据复制到新数组。

6. **结果**：
   - 生成优化的调度树，标记外层循环为并行（`coincident`）。
   - 禁用循环向量化，展开内层循环以支持 SLP 向量化。

---

### 6. 总结

`ScheduleOptimizer.cpp` 是 Polly 框架中调度优化的核心实现，通过 ISL 调度优化器和后调度变换（如平铺、预向量化、矩阵乘法优化）生成高性能的调度树。其设计特点包括：

- **模块化**：分为 ISL 调度和后调度变换，易于扩展。
- **多面体支持**：深度整合 ISL 库，精确建模循环和依赖。
- **目标适配**：通过 `TargetTransformInfo` 支持不同体系结构。
- **灵活性**：通过命令行选项支持多种优化策略和配置。

该文件适合研究人员和开发者深入理解多面体优化、矩阵乘法优化和目标体系结构适配技术。如果需要更具体的方法分析或代码示例，请告诉我！