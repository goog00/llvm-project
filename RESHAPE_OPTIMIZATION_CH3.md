# Ch3 中 Reshape 操作和优化的完整实现分析

## 概述

在 Toy 编译器的 Ch3 中，引入了**优化 Pass**。具体表现为：

1. **Reshape 操作的定义** - 在 Ops.td 中定义（与 Ch2 相同）
2. **优化规则的定义** - 在 ToyCombine.td 中使用 **DRR (Declarative Rewrite Rules)**
3. **优化规则的实现** - 在 ToyCombine.cpp 中注册规范化模式
4. **优化的应用** - 在 toyc.cpp 中调用 Canonicalizer Pass

---

## 第一部分：Reshape 操作定义

### 文件位置
[mlir/examples/toy/Ch3/include/toy/Ops.td](mlir/examples/toy/Ch3/include/toy/Ops.td) 第 247-269 行

### Reshape 的 TableGen 定义

```tablegen
def ReshapeOp : Toy_Op<"reshape", [Pure]> {
  let summary = "tensor reshape operation";
  let description = [{
    Reshape operation is transforming its input tensor into a new tensor with
    the same number of elements but different shapes. For example:

    ```mlir
       %0 = toy.reshape (%arg1 : tensor<10xf64>) to tensor<5x2xf64>
    ```
  }];

  // 单个输入操作数
  let arguments = (ins F64Tensor:$input);

  // 结果必须是静态形状的张量
  let results = (outs StaticShapeTensorOf<[F64]>);

  // 使用声明式格式：`(` 输入 `:` 输入类型 `)` 属性字典 `to` 结果类型
  let assemblyFormat = [{
    `(` $input `:` type($input) `)` attr-dict `to` type(results)
  }];

  // ⚠️ 关键：启用规范化模式
  let hasCanonicalizer = 1;
}
```

### 关键特性

| 特性                         | 说明                                           |
| ---------------------------- | ---------------------------------------------- |
| `[Pure]`                     | Reshape 是纯操作（无副作用），可以被删除或重排 |
| `hasCanonicalizer = 1`       | 这个操作支持规范化模式                         |
| `StaticShapeTensorOf<[F64]>` | 结果必须具有静态形状                           |

### MLIR 表示示例

```mlir
%1 = toy.reshape (%0 : tensor<10xf64>) to tensor<5x2xf64>
%2 = toy.reshape (%1 : tensor<5x2xf64>) to tensor<10xf64>
```

---

## 第二部分：优化规则定义

### 文件位置
[mlir/examples/toy/Ch3/mlir/ToyCombine.td](mlir/examples/toy/Ch3/mlir/ToyCombine.td)

### 优化规则的三种形式

#### 1️⃣ **基础模式匹配和重写**

**规则一：消除冗余的嵌套 Reshape**

```tablegen
// Reshape(Reshape(x)) = Reshape(x)
def ReshapeReshapeOptPattern : Pat<
  (ReshapeOp(ReshapeOp $arg)),  // 源模式：嵌套的两个 ReshapeOp
  (ReshapeOp $arg)               // 目标模式：直接应用外层 ReshapeOp 到内层输入
>;
```

**工作原理**：
```
匹配模式：
%0 = toy.reshape (%x : tensorA) to tensorB
%1 = toy.reshape (%0 : tensorB) to tensorC

替换为：
%1 = toy.reshape (%x : tensorA) to tensorC

结果：
消除了中间的 reshape 操作，直接从输入 x 变换到最终形状
```

**数据流图**：
```
原始：
x --[Reshape A→B]→ %0 --[Reshape B→C]→ %1

优化后：
x --[Reshape A→C]→ %1
```

#### 2️⃣ **使用本地 C++ 代码的模式匹配**

**规则二：常数传播和 Reshape 折叠**

```tablegen
// 定义 Native Code Call 函数
def ReshapeConstant :
  NativeCodeCall<"$0.reshape(::llvm::cast<ShapedType>($1.getType()))">;

// Reshape(Constant(x)) = x'
def FoldConstantReshapeOptPattern : Pat<
  (ReshapeOp:$res (ConstantOp $arg)),  // 源：应用于 Constant 的 Reshape
  (ConstantOp (ReshapeConstant $arg, $res))  // 目标：返回新的 Constant
>;
```

**工作原理**：

当一个 Reshape 操作应用于常数时，我们可以在编译时计算新的常数，而不是在运行时执行 reshape。

```
匹配模式：
%0 = toy.constant dense<[1.0, 2.0, 3.0, 4.0, 5.0, 6.0]> : tensor<6xf64>
%1 = toy.reshape (%0 : tensor<6xf64>) to tensor<2x3xf64>

替换为：
%1 = toy.constant dense<[[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]]> : tensor<2x3xf64>

结果：
在编译时计算常数折叠，消除运行时 reshape 操作
```

**代码分解**：
- `$0.reshape(...)` - 调用 Constant 属性的 `reshape` 方法
- `::llvm::cast<ShapedType>($1.getType())` - 获取 Reshape 操作结果的类型

#### 3️⃣ **带约束的模式匹配**

**规则三：删除冗余 Reshape（当形状相同时）**

```tablegen
// 定义约束：检查两个类型是否相同
def TypesAreIdentical : Constraint<
  CPred<"$0.getType() == $1.getType()">
>;

// Reshape(x) = x，其中输入和输出形状相同
def RedundantReshapeOptPattern : Pat<
  (ReshapeOp:$res $arg),     // 源：任何 Reshape 操作
  (replaceWithValue $arg),   // 目标：直接使用输入值
  [(TypesAreIdentical $res, $arg)]  // 约束：结果类型等于输入类型
>;
```

**工作原理**：

```
匹配模式：
%0 = toy.reshape (%x : tensor<2x3xf64>) to tensor<2x3xf64>

约束检查：
$res 的类型 (tensor<2x3xf64>) == $arg 的类型 (tensor<2x3xf64>) ✓

替换为：
直接使用 %x，删除 reshape 操作

结果：
%0 = %x
```

---

## 第三部分：优化规则的实现

### 文件位置
[mlir/examples/toy/Ch3/mlir/ToyCombine.cpp](mlir/examples/toy/Ch3/mlir/ToyCombine.cpp)

### 完整代码结构

```cpp
#include "mlir/IR/MLIRContext.h"
#include "mlir/IR/PatternMatch.h"
#include "mlir/IR/Value.h"
#include "toy/Dialect.h"
using namespace mlir;
using namespace toy;

namespace {
// 从 ToyCombine.td 自动生成的规则
#include "ToyCombine.inc"
} // namespace

//===----------------------------------------------------------------------===//
// 针对 TransposeOp 的 C++ 规范化模式
//===----------------------------------------------------------------------===//

struct SimplifyRedundantTranspose : public mlir::OpRewritePattern<TransposeOp> {
  SimplifyRedundantTranspose(mlir::MLIRContext *context)
      : OpRewritePattern<TransposeOp>(context, /*benefit=*/1) {}

  llvm::LogicalResult
  matchAndRewrite(TransposeOp op,
                  mlir::PatternRewriter &rewriter) const override {
    // 检查输入是否由另一个 Transpose 定义
    mlir::Value transposeInput = op.getOperand();
    TransposeOp transposeInputOp = transposeInput.getDefiningOp<TransposeOp>();

    if (!transposeInputOp)
      return failure();  // 不匹配

    // 匹配成功：替换当前 Transpose 为其输入的输入
    rewriter.replaceOp(op, {transposeInputOp.getOperand()});
    return success();
  }
};

//===----------------------------------------------------------------------===//
// 注册规范化模式
//===----------------------------------------------------------------------===//

// 为 TransposeOp 注册规范化模式
void TransposeOp::getCanonicalizationPatterns(RewritePatternSet &results,
                                              MLIRContext *context) {
  results.add<SimplifyRedundantTranspose>(context);
}

// 为 ReshapeOp 注册规范化模式
void ReshapeOp::getCanonicalizationPatterns(RewritePatternSet &results,
                                            MLIRContext *context) {
  // 添加从 ToyCombine.td 生成的三个规则
  results.add<ReshapeReshapeOptPattern,      // 规则1：嵌套 Reshape
              RedundantReshapeOptPattern,    // 规则2：冗余 Reshape
              FoldConstantReshapeOptPattern>(context);  // 规则3：常数折叠
}
```

### 关键概念

#### OpRewritePattern 基类

```cpp
class SimplifyRedundantTranspose : public mlir::OpRewritePattern<TransposeOp>
```

- 模板参数 `TransposeOp` - 指定要匹配的操作类型
- `matchAndRewrite()` - 主要方法，执行匹配和重写

#### PatternRewriter 工具

```cpp
mlir::PatternRewriter &rewriter
```

提供的关键方法：
- `rewriter.replaceOp(oldOp, newValues)` - 用新值替换旧操作
- `rewriter.create<OpType>(loc, args...)` - 创建新操作
- `rewriter.eraseOp(op)` - 删除操作

#### getCanonicalizationPatterns() 方法

这是一个虚拟方法，每个操作可以注册其规范化模式：

```cpp
void ReshapeOp::getCanonicalizationPatterns(RewritePatternSet &results,
                                            MLIRContext *context) {
  results.add<Pattern1, Pattern2, Pattern3>(context);
}
```

---

## 第四部分：优化应用流程

### 文件位置
[mlir/examples/toy/Ch3/toyc.cpp](mlir/examples/toy/Ch3/toyc.cpp) 第 105-128 行

### 优化 Pass 应用

```cpp
static int dumpMLIR() {
  mlir::MLIRContext context;
  context.getOrLoadDialect<mlir::toy::ToyDialect>();

  mlir::OwningOpRef<mlir::ModuleOp> module;
  llvm::SourceMgr sourceMgr;
  mlir::SourceMgrDiagnosticHandler sourceMgrHandler(sourceMgr, &context);
  
  if (int error = loadMLIR(sourceMgr, context, module))
    return error;

  // 如果启用了 -opt 标志
  if (enableOpt) {
    // 创建 Pass Manager，针对模块
    mlir::PassManager pm(module.get()->getName());
    
    // 应用命令行选项
    if (mlir::failed(mlir::applyPassManagerCLOptions(pm)))
      return 4;

    // 为每个 toy.func 操作添加 Canonicalizer Pass
    pm.addNestedPass<mlir::toy::FuncOp>(mlir::createCanonicalizerPass());
    
    // 执行 Pass
    if (mlir::failed(pm.run(*module)))
      return 4;
  }

  module->dump();
  return 0;
}
```

### 关键部分解析

#### 1. 创建 PassManager

```cpp
mlir::PassManager pm(module.get()->getName());
```

- 管理一系列 Pass 的执行
- 按照特定顺序应用优化

#### 2. 添加嵌套 Pass

```cpp
pm.addNestedPass<mlir::toy::FuncOp>(mlir::createCanonicalizerPass());
```

- `addNestedPass<OpType>` - 为每个 OpType 操作添加 Pass
- 这里为每个 `toy.func` 函数添加 Canonicalizer
- Canonicalizer Pass 自动搜索所有操作的 `getCanonicalizationPatterns()` 并应用

#### 3. 执行 Pass

```cpp
if (mlir::failed(pm.run(*module)))
  return 4;
```

运行所有注册的 Pass，应用所有规范化规则。

### 使用示例

```bash
# 不优化
./toyc-ch3 file.toy -emit=mlir

# 启用优化
./toyc-ch3 file.toy -emit=mlir -opt
```

---

## 完整优化工作流

### 编译命令示例

```bash
./build/bin/toyc-ch3 mlir/test/Examples/Toy/Ch3/trivial_reshape.toy -emit=mlir -opt
```

### 流程图

```
源 Toy 文件 (trivial_reshape.toy)
    ↓
MLIRGen (生成未优化的 MLIR)
    ↓
未优化的 MLIR 模块
    ├─ %0 = toy.reshape (...)
    ├─ %1 = toy.reshape (%0, ...)  ← 可以优化
    └─ ...
    ↓
PassManager
    ├─ 加载 Canonicalizer Pass
    ├─ 对每个 toy.func 运行
    └─ 搜集所有 getCanonicalizationPatterns()
    ↓
应用规范化规则
    ├─ ReshapeReshapeOptPattern 匹配 reshape(reshape(...))
    ├─ RedundantReshapeOptPattern 匹配形状相同的 reshape
    ├─ FoldConstantReshapeOptPattern 匹配 reshape(constant)
    └─ SimplifyRedundantTranspose 匹配 transpose(transpose(...))
    ↓
优化后的 MLIR 模块
    ├─ %0 = toy.reshape (...)
    └─ ... (冗余操作已删除)
    ↓
输出到控制台/文件
```

---

## 具体例子：trivial_reshape.toy

### 源文件内容

假设 trivial_reshape.toy 包含：

```toy
def main() {
  var a<10> = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
  var b = reshape(a, [5, 2]);
  var c = reshape(b, [10]);
  print(c);
}
```

### 未优化的 MLIR（Ch3 without -opt）

```mlir
toy.func @main() {
  %0 = toy.constant dense<[1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0]> : tensor<10xf64>
  %1 = toy.reshape (%0 : tensor<10xf64>) to tensor<5x2xf64>  ← reshape 1
  %2 = toy.reshape (%1 : tensor<5x2xf64>) to tensor<10xf64>  ← reshape 2（冗余）
  toy.print %2 : tensor<10xf64>
  toy.return
}
```

### 优化后的 MLIR（Ch3 with -opt）

```mlir
toy.func @main() {
  %0 = toy.constant dense<[1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0]> : tensor<10xf64>
  toy.print %0 : tensor<10xf64>  ← 两个 reshape 都被消除！
  toy.return
}
```

**为什么可以这样优化？**

1. `%1 = reshape(%0 : tensor<10> to tensor<5x2>)` - 10 个元素重塑为 5×2
2. `%2 = reshape(%1 : tensor<5x2> to tensor<10>)` - 10 个元素（5×2=10）再重塑为 1D
3. 结果：没有改变任何数据，只是改变了形状，最后又改回去了！

**优化规则应用**：
- 首先 `ReshapeReshapeOptPattern` 匹配：`reshape(reshape(x))` → `reshape(x)` 的输入
  - 结果：`%2 = reshape(%0 : tensor<10> to tensor<10>)`
- 然后 `RedundantReshapeOptPattern` 匹配：形状相同的 reshape
  - 结果：删除 `%2`，直接使用 `%0`

---

## DRR (Declarative Rewrite Rules) 详解

### DRR 的三个核心概念

#### 1. Pattern 类

```tablegen
class Pattern<
  dag sourcePattern,              // 要匹配的模式
  list<dag> resultPatterns,       // 替换的模式
  list<dag> additionalConstraints = [],  // 额外约束
  list<dag> supplementalPatterns = [],   // 补充模式
  dag benefitsAdded = (addBenefit 0)     // 优化收益
>;
```

#### 2. Pat 宏

最常用的模式定义方式：

```tablegen
def MyPattern : Pat<
  sourcePattern,      // 要匹配的 DAG
  resultPattern       // 替换的 DAG
>;
```

#### 3. NativeCodeCall

当模式匹配不够灵活时，可以调用 C++ 代码：

```tablegen
def MyCodeCall :
  NativeCodeCall<"myFunction($0, $1, ...)">;

// 在模式中使用
def MyPattern : Pat<
  (MyOp $arg),
  (OtherOp (MyCodeCall $arg))
>;
```

### 自动代码生成

TableGen 工具自动从 `.td` 文件生成 `.cpp.inc` 文件：

```bash
tablegen -gen-rewriters ToyCombine.td -o ToyCombine.inc
```

生成的文件包含：
- `ReshapeReshapeOptPattern` 类定义
- `RedundantReshapeOptPattern` 类定义
- `FoldConstantReshapeOptPattern` 类定义

---

## 总结表格

| 方面             | 说明                                      | 位置                                                                     |
| ---------------- | ----------------------------------------- | ------------------------------------------------------------------------ |
| **Reshape 定义** | Pure 操作，支持规范化                     | [Ch3/Ops.td#L247](mlir/examples/toy/Ch3/include/toy/Ops.td#L247)         |
| **优化规则1**    | 嵌套 Reshape 消除                         | [Ch3/ToyCombine.td#L33](mlir/examples/toy/Ch3/mlir/ToyCombine.td#L33)    |
| **优化规则2**    | 常数 Reshape 折叠                         | [Ch3/ToyCombine.td#L39-44](mlir/examples/toy/Ch3/mlir/ToyCombine.td#L39) |
| **优化规则3**    | 冗余 Reshape 删除                         | [Ch3/ToyCombine.td#L49-52](mlir/examples/toy/Ch3/mlir/ToyCombine.td#L49) |
| **规则注册**     | 在 Ops 中注册 getCanonicalizationPatterns | [Ch3/Dialect.cpp#L65-67](mlir/examples/toy/Ch3/mlir/Dialect.cpp#L65)     |
| **优化应用**     | Canonicalizer Pass                        | [Ch3/toyc.cpp#L122](mlir/examples/toy/Ch3/toyc.cpp#L122)                 |

---

## 关键学习要点

### 1. Reshape 不只是数据结构
- 在编译时进行形状变换
- 保持元素总数不变
- 编译器可以识别和优化冗余的形状变换

### 2. DRR 的三层机制
- **声明式规则**（.td）→ 简洁的模式定义
- **代码生成**（tablegen）→ 自动生成 C++ 代码
- **运行时应用**（Pass）→ 执行优化

### 3. 规范化 vs 优化
- **规范化**（Canonicalization）- 将 IR 转换为标准形式
- **内置在操作定义中** - `hasCanonicalizer = 1`
- **自动发现和应用** - Canonicalizer Pass 会自动搜集所有模式

### 4. PassManager 的作用
- 管理多个 Pass 的执行
- 支持嵌套 Pass（针对特定操作）
- 提供命令行集成

### 5. 实际意义
```
代码优化 = 消除冗余 + 折叠常量 + 形状传播
           ↓           ↓          ↓
      嵌套删除    编译时计算    类型传播
```
