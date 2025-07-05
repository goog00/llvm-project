
1.ScopInfo

ScopInfo.h ScopInfo.cpp 
这个类包含了llvm ir 中的多面体模型相关的静态控制信息，是多面体编译操作的对象，如迭代空间，数据空间，迭代语句，调度等信息的。多面体编译过程中的分析和优化操作也是在此类基础上进行的，非常的重要。


好的，以下是对 `ScopInfo.h` 文件的详细解释，内容将以中文呈现，力求清晰、简洁且全面，帮助理解 Polly 项目中该头文件的作用和结构。

---

### 概述

`ScopInfo.h` 是 **Polly** 项目的一个核心头文件，Polly 是 LLVM 编译器基础设施中的一个高级优化框架，专注于 **静态控制流部分（Static Control Part，简称 SCoP）** 的分析和优化。SCoP 是指程序中具有静态控制流特性的代码区域（例如嵌套循环），其控制流和内存访问可以用多面体模型（polyhedral model）来表示和优化。这种模型被广泛应用于高性能计算、并行化、向量化等优化场景。

该头文件定义了 Polly 用于表示和操作 SCoP 的核心数据结构和功能，包括：

1. **Scop** 类：表示一个完整的 SCoP，包含其控制流、内存访问和多面体模型的描述。
2. **ScopStmt** 类：表示 SCoP 中的一个语句，通常对应一个基本块（Basic Block）或区域（Region）。
3. **ScopArrayInfo** 类：描述 SCoP 中涉及的数组或标量内存对象。
4. **MemoryAccess** 类：表示对内存的访问（读或写）。
5. **ScopInfo** 类：管理函数中所有 SCoP 的集合。
6. 其他辅助结构和工具，用于支持多面体优化。

以下将逐一分析这些主要组件。

---

### 1. 宏定义

文件包含一些宏和全局变量的声明，例如：

- **`UseInstructionNames`**：控制是否使用指令名称（可能用于调试或输出）。
- **`MaxDisjunctsInDomain`**：限制域构造中允许的最大基本集（basic sets）数量，以控制编译时间和复杂性。

```cpp
extern bool UseInstructionNames;
extern int const MaxDisjunctsInDomain;
```

---

### 2. 核心数据结构

#### 2.1 Scop 类

`Scop` 类是表示 SCoP 的核心数据结构，封装了一个静态控制流区域的所有信息。以下是其关键成员和功能：

- **成员变量**：
  - `IslCtx`：一个 `std::shared_ptr<isl_ctx>`，指向 **ISL (Integer Set Library)** 的上下文，用于管理多面体模型中的数学对象（如集合和映射）。
  - `SE` 和 `DT`：分别指向 LLVM 的 `ScalarEvolution` 和 `DominatorTree`，用于分析循环和控制流依赖。
  - `R`：表示 SCoP 对应的 LLVM `Region`，定义了 SCoP 的边界。
  - `AccessFunctions`：存储 SCoP 中所有的内存访问（`MemoryAccess` 对象）。
  - `Stmts`：存储 SCoP 中的所有语句（`ScopStmt` 对象）。
  - `Parameters`：SCoP 中涉及的参数（例如循环边界中的符号常量）。
  - `Context` 和 `AssumedContext`：分别表示 SCoP 的参数约束和假设上下文，用于描述 SCoP 的有效性。
  - `Schedule`：SCoP 的调度，表示语句实例的执行顺序，通常以多维调度树（schedule tree）的形式存储。
  - `MinMaxAliasGroups`：用于运行时别名检查（alias checks）的分组信息。

- **关键方法**：
  - `getContext()`：获取 SCoP 的参数约束。
  - `getSchedule()` 和 `getScheduleTree()`：获取 SCoP 的调度信息。
  - `addScopStmt()`：添加新的语句到 SCoP 中。
  - `getOrCreateScopArrayInfo()`：创建或获取数组信息对象。
  - `simplifySCoP()`：简化 SCoP 表示，移除无用语句或优化表示形式。
  - `isProfitable()`：判断 SCoP 是否值得优化。
  - `getPwAff()`：将 LLVM 的 `SCEV`（Scalar Evolution 表达式）转换为 ISL 的多面体表达式（`isl::pw_aff`）。

- **功能**：
  `Scop` 类负责将 LLVM IR 中的代码区域转化为多面体模型，分析其控制流、内存访问和调度信息，并为后续优化（如循环变换、并行化）提供基础。它通过与 ISL 库的交互，使用多面体数学来精确描述循环的迭代域和数据依赖。

#### 2.2 ScopStmt 类

`ScopStmt` 表示 SCoP 中的一个语句，通常对应一个基本块（`BasicBlock`）或一个区域（`Region`）。它描述了语句的迭代域、调度和内存访问。

- **成员变量**：
  - `Parent`：指向所属的 `Scop` 对象。
  - `Domain`：表示语句的迭代域（`isl::set`），描述语句执行的迭代向量集合。
  - `MemAccs`：存储该语句涉及的所有内存访问（`MemoryAccess` 对象）。
  - `BB` 或 `R`：指向对应的基本块或区域，表示该语句的代码实体。
  - `NestLoops`：存储包含该语句的循环嵌套结构。
  - `Instructions`：语句中包含的 LLVM 指令。

- **关键方法**：
  - `getDomain()`：获取语句的迭代域。
  - `getSchedule()`：获取语句的调度。
  - `removeAccessData()`：移除特定内存访问的相关数据。

- **功能**：
  `ScopStmt` 是 SCoP 中最小的执行单元，用于表示一个基本块或区域的执行行为。它通过迭代域（iteration domain）描述语句在循环中的执行实例，并通过内存访问记录数据依赖。

#### 2.3 ScopArrayInfo 类

`ScopArrayInfo` 用于描述 SCoP 中的数组或标量内存对象，区分了不同的内存类型（`MemoryKind`）。

- **内存类型（MemoryKind）**：
  - `Array`：表示多维数组或单元素数组（如全局变量或栈分配）。
  - `Value`：表示 LLVM 中的标量值（`llvm::Value`），通过虚拟内存对象建模。
  - `PHI`：表示 SCoP 内的 PHI 节点，建模其数据流。
  - `ExitPHI`：表示 SCoP 退出块中的 PHI 节点。

- **成员变量**：
  - `BasePtr`：数组或标量的基地址。
  - `ElementType`：数组元素的类型。
  - `DimensionSizes`：数组各维的大小（以 `SCEV` 形式）。
  - `DimensionSizesPw`：数组各维大小的 ISL 表示（`isl::pw_aff`）。
  - `Kind`：内存对象的类型（`Array`、`Value`、`PHI` 或 `ExitPHI`）。
  - `FAD`：Fortran 数组描述符（用于支持 Fortran 数组）。

- **关键方法**：
  - `updateElementType()`：更新数组元素类型，确保兼容所有访问。
  - `updateSizes()`：更新数组维度大小。
  - `getBasePtr()`：获取基地址。
  - `getDimensionSize()`：获取指定维度的大小。
  - `isCompatibleWith()`：检查两个数组是否兼容（维度、元素大小等）。

- **功能**：
  `ScopArrayInfo` 提供了 SCoP 中内存对象的统一表示，无论是数组还是标量值，都通过多面体模型建模其访问模式。它支持动态数组（通过 delinearization）以及 Fortran 数组的特殊处理。

#### 2.4 MemoryAccess 类

`MemoryAccess` 表示 SCoP 中的一次内存访问（读或写），描述了访问的地址、类型和关联的语句。

- **访问类型（AccessType）**：
  - `READ`：读访问。
  - `MUST_WRITE`：确定性写访问（覆盖旧值）。
  - `MAY_WRITE`：可能写访问（条件写）。

- **约减类型（ReductionType）**：
  支持约减操作（如加法、乘法、位运算），用于优化约减循环。

- **成员变量**：
  - `Id`：访问的唯一标识符（`isl::id`）。
  - `Kind`：内存对象类型（`MemoryKind`）。
  - `AccType`：访问类型（读/写）。
  - `BaseAddr`：访问的基地址。
  - `AccessRelation`：访问关系（`isl::map`），描述语句实例到内存地址的映射。
  - `Subscripts`：访问的下标表达式（以 `SCEV` 表示）。
  - `InvalidDomain`：访问无效的迭代域。

- **关键方法**：
  - `getAccessRelation()`：获取访问关系。
  - `getAddressFunction()`：获取唯一的内存地址映射。
  - `isReductionLike()`：检查是否为约减型访问。
  - `getPwAff()`：将下标表达式转换为 ISL 表示。

- **功能**：
  `MemoryAccess` 描述了 SCoP 中所有的内存操作，包括数组访问、标量值读写和 PHI 节点相关访问。它通过 `AccessRelation` 将语句实例映射到内存地址，支持多面体优化中的依赖分析。

#### 2.5 ScopInfo 类

`ScopInfo` 是一个管理类，负责存储和管理一个函数中所有 SCoP 的信息。

- **成员变量**：
  - `RegionToScopMap`：将 LLVM `Region` 映射到对应的 `Scop` 对象。
  - 依赖的 LLVM 分析工具：`ScalarEvolution`、`LoopInfo`、`AliasAnalysis` 等。

- **关键方法**：
  - `getScop()`：获取指定区域的 SCoP 对象。
  - `recompute()`：重新计算函数中的 SCoP 信息。
  - `invalidate()`：处理分析失效的情况。

- **功能**：
  `ScopInfo` 作为函数级别的 SCoP 管理器，负责初始化、存储和提供对 SCoP 的访问。它是 Polly 分析流程的入口点。

---

### 3. 多面体模型的核心概念

Polly 使用 **多面体模型** 来表示和优化 SCoP，其核心概念包括：

- **迭代域（Iteration Domain）**：
  表示语句的执行实例集合。例如，对于循环：
  ```c
  for (i = 0; i < 100 + b; ++i)
      for (j = 0; j < i; ++j)
          S(i, j);
  ```
  迭代域为 `{ S[i,j] : 0 <= i <= 100 + b, 0 <= j <= i }`，描述了语句 `S` 的所有可能执行实例。

- **访问关系（Access Relation）**：
  描述语句实例到内存地址的映射。例如，`A[i + 3j]` 的访问关系为 `{ S[i,j] -> A[i + 3j] }`。

- **调度（Schedule）**：
  定义语句实例的执行顺序，通常以多维向量表示。例如，调度 `{ S[i,j] -> [i, j] }` 表示按 `i` 和 `j` 的顺序执行。

- **上下文（Context）**：
  表示参数的约束条件，例如 `b >= 0`。上下文分为 `AssumedContext`（假设成立的条件）和 `InvalidContext`（必须不成立的条件）。

- **ISL 库**：
  Polly 使用 ISL 库来处理多面体数学运算（如集合、映射、仿射函数）。`isl::set`、`isl::map` 和 `isl::pw_aff` 是核心数据类型。

---

### 4. 关键功能和优化

Polly 通过 `ScopInfo.h` 提供以下功能和优化：

1. **SCoP 检测**：
   - 通过 `ScopDetection` 识别程序中的 SCoP，分析控制流和内存访问是否满足静态控制流的条件。
   - 例如，循环必须具有可分析的边界（通过 `SCEV`），内存访问必须是仿射的（affine）。

2. **多面体表示**：
   - 将 LLVM IR 转换为多面体模型，包括迭代域、访问关系和调度。
   - 支持复杂情况，如非仿射子区域（non-affine subregions）和 Fortran 数组。

3. **内存访问建模**：
   - 通过 `MemoryAccess` 和 `ScopArrayInfo` 精确描述数组和标量访问，支持约减操作和 PHI 节点。
   - 特殊处理标量值，通过虚拟内存对象（`.s2a` 和 `.phiops`）建模数据流。

4. **优化支持**：
   - 提供调度变换（`setSchedule`）、依赖分析和别名检查（`MinMaxAliasGroups`）。
   - 支持运行时检查（runtime checks）以验证假设（`AssumedContext`）。

5. **代码生成**：
   - 将优化后的多面体模型转换回 LLVM IR，生成高效代码（如向量化、并行化代码）。

---

### 5. 使用场景和意义

`ScopInfo.h` 是 Polly 的核心组件，用于以下场景：

- **循环优化**：通过多面体模型进行循环融合、分块、交换等变换。
- **并行化**：识别并生成并行循环，适用于多核 CPU 或 GPU。
- **向量化**：生成适合 SIMD 指令的代码。
- **高性能计算**：优化科学计算程序中的密集循环。

---

### 6. 代码结构分析

以下是文件的主要结构：

- **头文件包含和命名空间**：
  ```cpp
  #include "polly/ScopDetection.h"
  #include "polly/Support/SCEVAffinator.h"
  #include "llvm/ADT/ArrayRef.h"
  #include "llvm/Analysis/RegionPass.h"
  #include "isl/isl-noexceptions.h"
  ```
  依赖 Polly 的其他模块（如 `ScopDetection`）、LLVM 分析工具和 ISL 库。

- **枚举和类型**：
  - `AssumptionKind`：定义优化时的假设类型（如别名、边界、复杂度等）。
  - `MemoryKind`：区分数组、标量、PHI 节点等内存对象。
  - `AccessType` 和 `ReductionType`：描述内存访问和约减操作的类型。

- **类和接口**：
  - `Scop`：核心类，管理 SCoP 的所有信息。
  - `ScopStmt`：表示单个语句。
  - `ScopArrayInfo`：表示内存对象。
  - `MemoryAccess`：表示内存访问。
  - `ScopInfo` 和 `ScopInfoRegionPass`：提供函数级和区域级的 SCoP 分析。

- **工具函数**：
  - 提供打印（`print`）、调试（`dump`）和上下文操作（如 `addAssumption`）等功能。

---

### 7. 关键实现细节

- **ISL 集成**：
  Polly 依赖 ISL 库来处理多面体数学。`ScopInfo.h` 中大量使用了 `isl::set`、`isl::map` 和 `isl::pw_aff` 来表示迭代域、访问关系和仿射表达式。

- **标量建模**：
  标量值（`llvm::Value`）通过虚拟内存对象建模为零维数组，解决了多面体模型无法直接处理 SSA 值的限制。例如：
  ```cpp
  // Value 类型的内存访问
  Value -> { S[i,j] -> Value.s2a[] }
  ```

- **Fortran 支持**：
  通过 `FAD`（Fortran Array Descriptor）支持动态尺寸的 Fortran 数组，增强了 Polly 对科学计算程序的适用性。

- **优化假设**：
  使用 `AssumedContext` 和 `InvalidContext` 记录优化时的假设和限制，生成运行时检查以确保正确性。

---

### 8. 示例代码分析

假设有以下 C 代码：
```c
void example(int A[], int n) {
    for (int i = 0; i < n; ++i)
        for (int j = 0; j < n; ++j)
            A[i + j] += 1;
}
```

Polly 会将其解析为一个 SCoP：

- **迭代域**：
  ```cpp
  { S[i,j] : 0 <= i < n, 0 <= j < n }
  ```

- **访问关系**：
  ```cpp
  { S[i,j] -> A[i + j] }
  ```

- **调度**：
  ```cpp
  { S[i,j] -> [i, j] }
  ```

- **ScopArrayInfo**：
  - `BasePtr`：`A`
  - `ElementType`：`int`
  - `DimensionSizes`：`[n]`（一维数组）

- **MemoryAccess**：
  - 读访问：`A[i + j]`（`READ`）
  - 写访问：`A[i + j]`（`MUST_WRITE`）

Polly 随后可对该 SCoP 进行优化，例如循环交换或向量化。

---

### 9. 总结

`ScopInfo.h` 是 Polly 框架的核心，定义了用于表示和操作 SCoP 的数据结构和接口。它通过多面体模型将 LLVM IR 转化为数学表示，支持复杂的循环优化和并行化。主要特点包括：

- **模块化设计**：`Scop`、`ScopStmt`、`ScopArrayInfo` 和 `MemoryAccess` 分工明确，分别处理 SCoP、语句、内存对象和访问。
- **多面体支持**：通过 ISL 库实现精确的数学建模。
- **灵活性**：支持数组、标量、PHI 节点和 Fortran 数组的统一建模。
- **优化能力**：为循环变换、并行化和向量化提供基础。

该文件是理解 Polly 工作原理的关键，适合研究人员和开发者深入学习多面体优化和 LLVM 的高级优化技术。

如果需要更具体的某个部分的解释或示例，请告诉我！