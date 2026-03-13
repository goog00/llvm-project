# MLIR 面试题（基于 Toy Tutorial）

> 共 10 题，分初级（4题）、中级（3题）、高级（3题）三个层次。

---

## 🟢 初级（Basic）

### 题目 1：什么是 MLIR 中的 Dialect？它和 LLVM IR 有什么本质区别？

**答案**：

Dialect（方言）是 MLIR 中对一组相关操作、类型和属性的逻辑分组，类似于一个可扩展的命名空间。

与 LLVM IR 的区别：

| 方面         | LLVM IR                                  | MLIR                                               |
| ------------ | ---------------------------------------- | -------------------------------------------------- |
| **可扩展性** | 固定的指令集，添加新指令需要修改核心代码 | 用户可以自定义 Dialect，无需修改框架               |
| **抽象层级** | 单一低层抽象（接近机器指令）             | 多层抽象共存（高层 Toy → 中层 Affine → 低层 LLVM） |
| **类型系统** | 固定类型（i32, float, ptr 等）           | 可扩展类型（如 Toy 的 StructType）                 |
| **优化时机** | 只能在低层做优化                         | 可在任意抽象层做优化                               |

在 Toy 教程中，`toy` 是一个自定义 Dialect，包含 `toy.constant`、`toy.add`、`toy.transpose` 等操作；而 `affine`、`arith`、`func`、`llvm` 是 MLIR 内置的 Dialect。

---

### 题目 2：Toy 教程中，ODS（Operation Definition Specification）是什么？它用 TableGen 定义操作有什么好处？

**答案**：

ODS 是 MLIR 中基于 TableGen 的操作定义框架，允许用声明式的方式定义操作的结构。

例如在 `Ops.td` 中定义 `TransposeOp`：

```tablegen
def TransposeOp : Toy_Op<"transpose", [Pure]> {
  let arguments = (ins F64Tensor:$input);
  let results = (outs F64Tensor);
  let hasVerifier = 1;
}
```

好处：

1. **自动生成代码**：自动生成 `build()`、`parse()`、`print()`、`verify()` 等方法的框架代码
2. **减少样板代码**：开发者只需关注核心逻辑
3. **一致性保障**：所有操作遵循统一的定义模式
4. **自动生成文档**：从 `summary` 和 `description` 字段生成文档
5. **Trait 声明**：直接在定义中标注操作特性（如 `Pure` 表示无副作用）

---

### 题目 3：MLIR 中 Operation、Region、Block 三者的关系是什么？

**答案**：

三者是嵌套的层级结构：

```
Operation（操作）
  └── Region（区域）
        └── Block（基本块）
              └── Operation（操作）
                    └── Region ...（可递归嵌套）
```

- **Operation**：MLIR 中的基本计算单元，如 `toy.add`、`func.func`、`affine.for`
- **Region**：包含一组 Block，用于表示操作的内部结构（如函数体、循环体）
- **Block**：包含一组顺序执行的 Operation，有参数（Block Arguments），以终止操作（Terminator）结束

以 Toy 教程为例：

```mlir
toy.func @main() {           // Operation (FuncOp)
  ^bb0:                       //   Region → Block
    %0 = toy.constant ...     //     Operation (ConstantOp)
    toy.print %0              //     Operation (PrintOp)
    toy.return                //     Operation (Terminator)
}
```

---

### 题目 4：Toy Ch3 中的 `Pure` trait 有什么作用？不加会怎样？

**答案**：

`Pure` trait 表示操作是**纯函数式**的——没有副作用且对相同输入总是产生相同输出。

作用：

1. **死代码消除（DCE）**：如果一个 `Pure` 操作的结果没有被使用，优化器可以安全删除它
2. **公共子表达式消除（CSE）**：两个相同的 `Pure` 操作可以合并为一个
3. **代码移动**：`Pure` 操作可以在程序中安全移动位置

不加 `Pure`：

```mlir
// 假设 toy.transpose 没有 Pure trait
%0 = toy.constant dense<...>
%1 = toy.transpose(%0)    // 即使结果未使用，也不会被删除
                            // 因为编译器不知道它是否有副作用
```

加了 `Pure`：

```mlir
%0 = toy.constant dense<...>
%1 = toy.transpose(%0)    // 结果未使用 → 被 DCE 安全删除
```

在 Toy 教程中，`toy.print` **不能**标记为 `Pure`，因为它有打印到控制台的副作用。

---

## 🟡 中级（Intermediate）

### 题目 5：Toy Ch4 中 Inlining 需要实现哪些接口？`materializeCallConversion()` 解决什么问题？

**答案**：

Ch4 中实现函数内联需要以下接口：

**1. DialectInlinerInterface（方言级接口）**

```cpp
struct ToyInlinerInterface : public DialectInlinerInterface {
  // 分析钩子：判断是否允许内联
  bool isLegalToInline(Operation *call, Operation *callable, ...) { return true; }
  bool isLegalToInline(Operation *, Region *, ...) { return true; }
  bool isLegalToInline(Region *, Region *, ...) { return true; }

  // 转换钩子：处理 return 终止符
  void handleTerminator(Operation *op, ValueRange valuesToRepl) { ... }

  // 类型适配钩子
  Operation *materializeCallConversion(...) { ... }
};
```

**2. CallOpInterface（操作级接口）**

`GenericCallOp` 需要实现 `getCallableForCallee()` 和 `getArgOperands()`，让内联器知道"调用的是谁"和"传递了哪些参数"。

**`materializeCallConversion()` 解决的问题**：

当调用方的参数类型与被调用函数的形参类型不匹配时，自动插入 `CastOp` 进行类型适配。

```mlir
// 调用方传入 tensor<2x3xf64>（具体形状）
// 被调用函数需要 tensor<*xf64>（未知形状）
// → materializeCallConversion 生成:
%cast = toy.cast %input : tensor<2x3xf64> to tensor<*xf64>
```

---

### 题目 6：Toy Ch5 中的部分下降（Partial Lowering）和 Ch6 中的完全下降（Full Lowering）有什么区别？为什么 `toy.print` 不在 Ch5 中下降？

**答案**：

**部分下降 vs 完全下降**：

| 方面         | Ch5 部分下降               | Ch6 完全下降            |
| ------------ | -------------------------- | ----------------------- |
| **API**      | `applyPartialConversion()` | `applyFullConversion()` |
| **目标**     | 允许部分操作保留为非法     | 所有操作必须转换为合法  |
| **转换范围** | Toy 计算操作 → Affine      | 所有剩余操作 → LLVM     |
| **残留操作** | `toy.print` 保留           | 无 Toy 操作残留         |

**为什么 `toy.print` 不在 Ch5 下降？**

1. **目标方言不匹配**：Ch5 的目标方言是 Affine + MemRef + Arith。这些方言中没有"打印"的概念
2. **需要运行时支持**：`print` 最终需要调用 C 标准库的 `printf`，这只有在 LLVM 方言层级才能表达
3. **分层设计**：Ch5 只负责将计算密集型操作下降为循环，I/O 操作留给后续阶段

Ch5 通过动态合法性检查保留 `toy.print`：

```cpp
target.addIllegalDialect<toy::ToyDialect>();  // Toy 方言整体非法
target.addDynamicallyLegalOp<toy::PrintOp>([](toy::PrintOp op) {
  // 但如果 print 的操作数已经从 Tensor 转换为 MemRef，则视为合法
  return llvm::none_of(op->getOperandTypes(),
                       [](Type type) { return llvm::isa<TensorType>(type); });
});
```

---

### 题目 7：Toy 教程中 Tensor → MemRef 的类型转换是如何完成的？为什么需要这个转换？

**答案**：

**为什么需要**：

- `Tensor` 是值语义（Value Semantics）：不可变，无副作用，适合高层优化
- `MemRef` 是引用语义（Reference Semantics）：对应真实的内存分配，有地址，可读写

要生成可执行的机器码，必须从"抽象值"转换为"具体内存"。

**转换方式**：

1. **类型映射**：

```cpp
static MemRefType convertTensorToMemRef(RankedTensorType type) {
  return MemRefType::get(type.getShape(), type.getElementType());
}
// tensor<2x3xf64> → memref<2x3xf64>
```

2. **内存管理**：每个张量结果对应一次 `memref.alloc` + `memref.dealloc`

```cpp
static Value insertAllocAndDealloc(MemRefType type, Location loc,
                                   PatternRewriter &rewriter) {
  auto alloc = memref::AllocOp::create(rewriter, loc, type);
  alloc->moveBefore(&parentBlock->front());     // alloc 放在块开头
  auto dealloc = memref::DeallocOp::create(rewriter, loc, alloc);
  dealloc->moveBefore(&parentBlock->back());    // dealloc 放在块结尾
  return alloc;
}
```

3. **数据访问方式变化**：

```mlir
// 转换前（Tensor，值语义）
%result = toy.add %a, %b : tensor<2x3xf64>

// 转换后（MemRef，引用语义）
%alloc = memref.alloc() : memref<2x3xf64>
affine.for %i = 0 to 2 {
  affine.for %j = 0 to 3 {
    %a_val = affine.load %a_memref[%i, %j]
    %b_val = affine.load %b_memref[%i, %j]
    %sum = arith.addf %a_val, %b_val
    affine.store %sum, %alloc[%i, %j]
  }
}
```

---

## 🔴 高级（Advanced）

### 题目 8：Toy Ch6 中的传递式下降（Transitive Lowering）是什么？请描述 Affine → LLVM 的完整传递路径。

**答案**：

传递式下降（A→B→C Lowering）是指一个操作不能直接转换为最终目标方言，而是经过多个中间方言逐步转换。

**Affine → LLVM 的完整路径**：

```
Affine Dialect          (affine.for, affine.load, affine.store)
    │
    │  populateAffineToStdConversionPatterns()
    ↓
SCF Dialect             (scf.for, scf.yield)
  + MemRef Dialect      (memref.load, memref.store)
    │
    │  populateSCFToControlFlowConversionPatterns()
    ↓
ControlFlow Dialect     (cf.br, cf.cond_br)
  + MemRef Dialect      (memref.load, memref.store)
  + Arith Dialect       (arith.addi, arith.cmpi)
    │
    │  populateControlFlowToLLVMConversionPatterns()
    │  populateMemRefToLLVMConversionPatterns()
    │  populateArithToLLVMConversionPatterns()
    │  populateFuncToLLVMConversionPatterns()
    ↓
LLVM Dialect            (llvm.br, llvm.load, llvm.store, llvm.add)
```

**具体示例**：`affine.for` 的转换链

```mlir
// Stage 1: Affine
affine.for %i = 0 to 10 {
  %v = affine.load %mem[%i] : memref<10xf64>
  affine.store %v, %out[%i] : memref<10xf64>
}

// Stage 2: SCF (Affine → SCF)
%lb = arith.constant 0 : index
%ub = arith.constant 10 : index
%step = arith.constant 1 : index
scf.for %i = %lb to %ub step %step {
  %v = memref.load %mem[%i] : memref<10xf64>
  memref.store %v, %out[%i] : memref<10xf64>
}

// Stage 3: ControlFlow (SCF → CF)
  cf.br ^header
^header:
  %i = ...
  %cond = arith.cmpi slt, %i, %ub : index
  cf.cond_br %cond, ^body, ^exit
^body:
  %v = memref.load %mem[%i] : memref<10xf64>
  memref.store %v, %out[%i] : memref<10xf64>
  %next = arith.addi %i, %step : index
  cf.br ^header
^exit:
  ...

// Stage 4: LLVM (CF + MemRef + Arith → LLVM)
  llvm.br ^header
^header:
  %i = llvm.phi ...
  %cond = llvm.icmp "slt" %i, %ub
  llvm.cond_br %cond, ^body, ^exit
^body:
  %ptr = llvm.getelementptr %mem[%i]
  %v = llvm.load %ptr : !llvm.ptr -> f64
  %optr = llvm.getelementptr %out[%i]
  llvm.store %v, %optr
  %next = llvm.add %i, %step
  llvm.br ^header
^exit:
  ...
```

**在 `ToyToLLVMLoweringPass::runOnOperation()` 中，所有阶段的 pattern 被一次性注册，由 `applyFullConversion()` 自动按依赖顺序应用。**

---

### 题目 9：如果要给 Toy 语言添加一个新的操作（如 `toy.matmul`），需要修改哪些文件？请描述完整流程。

**答案**：

以添加 `toy.matmul` 操作为例，需要修改以下文件（以 Ch6 为基准）：

**第一步：定义操作（ODS）**

修改 `include/toy/Ops.td`：

```tablegen
def MatMulOp : Toy_Op<"matmul", [Pure,
    DeclareOpInterfaceMethods<ShapeInferenceOpInterface>]> {
  let summary = "matrix multiplication";
  let arguments = (ins F64Tensor:$lhs, F64Tensor:$rhs);
  let results = (outs F64Tensor);
  let builders = [
    OpBuilder<(ins "Value":$lhs, "Value":$rhs)>
  ];
}
```

**第二步：实现操作方法**

修改 `mlir/Dialect.cpp`：

```cpp
void MatMulOp::build(OpBuilder &builder, OperationState &state,
                     Value lhs, Value rhs) {
  state.addTypes(UnrankedTensorType::get(builder.getF64Type()));
  state.addOperands({lhs, rhs});
}

void MatMulOp::inferShapes() {
  auto lhsType = cast<RankedTensorType>(getLhs().getType());
  auto rhsType = cast<RankedTensorType>(getRhs().getType());
  // [M, K] x [K, N] → [M, N]
  SmallVector<int64_t> shape = {lhsType.getShape()[0], rhsType.getShape()[1]};
  getResult().setType(RankedTensorType::get(shape, lhsType.getElementType()));
}
```

**第三步：修改前端 MLIRGen**

修改 `mlir/MLIRGen.cpp`，在 `mlirGen(BinaryExprAST)` 中添加对 `matmul` 运算符的处理。

**第四步：添加 Lowering Pattern**

修改 `mlir/LowerToAffineLoops.cpp`：

```cpp
struct MatMulOpLowering : public OpConversionPattern<toy::MatMulOp> {
  using OpConversionPattern<toy::MatMulOp>::OpConversionPattern;

  LogicalResult matchAndRewrite(toy::MatMulOp op, OpAdaptor adaptor,
                                ConversionPatternRewriter &rewriter) const final {
    auto loc = op->getLoc();
    auto resultType = cast<RankedTensorType>(*op->result_type_begin());
    auto memRefType = convertTensorToMemRef(resultType);
    auto alloc = insertAllocAndDealloc(memRefType, loc, rewriter);

    auto lhsType = cast<MemRefType>(adaptor.getLhs().getType());
    int64_t M = resultType.getShape()[0];
    int64_t N = resultType.getShape()[1];
    int64_t K = lhsType.getShape()[1];

    // 生成三层嵌套循环：for i, j, k
    // result[i][j] += lhs[i][k] * rhs[k][j]
    // ...
    rewriter.replaceOp(op, alloc);
    return success();
  }
};
```

**第五步：注册 Pattern**

在 `ToyToAffineLoweringPass::runOnOperation()` 中添加注册：

```cpp
patterns.add<..., MatMulOpLowering>(&getContext());
```

**第六步：可选优化**

修改 `mlir/ToyCombine.td` 或 `ToyCombine.cpp` 添加规范化规则（如 `matmul(A, I) → A`）。

**修改文件汇总**：

| 文件                          | 修改内容                        |
| ----------------------------- | ------------------------------- |
| `include/toy/Ops.td`          | ODS 定义                        |
| `mlir/Dialect.cpp`            | `build()`、`inferShapes()` 实现 |
| `mlir/MLIRGen.cpp`            | 前端支持                        |
| `mlir/LowerToAffineLoops.cpp` | Lowering pattern + 注册         |
| `mlir/ToyCombine.td/.cpp`     | （可选）优化规则                |

---

### 题目 10：MLIR 中 `ConversionTarget` 的合法性（Legality）机制是如何工作的？请结合 Toy Ch5 和 Ch6 说明 `addLegalDialect`、`addIllegalDialect` 和 `addDynamicallyLegalOp` 的区别和联合使用方式。

**答案**：

`ConversionTarget` 定义了方言转换的"终态"——哪些操作在转换后允许存在、哪些必须被消除。

**三种合法性标记**：

| 方法                            | 含义                                 | 使用场景     |
| ------------------------------- | ------------------------------------ | ------------ |
| `addLegalDialect<D>()`          | D 中所有操作都是合法的（允许存在）   | 标记目标方言 |
| `addIllegalDialect<D>()`        | D 中所有操作都是非法的（必须被转换） | 标记源方言   |
| `addDynamicallyLegalOp<Op>(fn)` | Op 的合法性由运行时函数 fn 决定      | 条件性保留   |

**Ch5 部分下降中的使用**：

```cpp
void ToyToAffineLoweringPass::runOnOperation() {
  ConversionTarget target(getContext());

  // ① 目标方言全部合法
  target.addLegalDialect<affine::AffineDialect, BuiltinDialect,
                         arith::ArithDialect, func::FuncDialect,
                         memref::MemRefDialect>();

  // ② 源方言（Toy）全部非法 → 所有 Toy 操作必须被转换
  target.addIllegalDialect<toy::ToyDialect>();

  // ③ 例外：toy.print 在操作数类型满足条件时是合法的
  target.addDynamicallyLegalOp<toy::PrintOp>([](toy::PrintOp op) {
    return llvm::none_of(op->getOperandTypes(),
                         [](Type type) { return llvm::isa<TensorType>(type); });
  });

  // 使用部分转换（允许合法操作残留）
  applyPartialConversion(getOperation(), target, std::move(patterns));
}
```

**合法性判定流程**：

```
对每个操作 Op：
├─ Op 属于 LegalDialect？ → ✅ 合法，跳过
├─ Op 属于 IllegalDialect？
│   ├─ Op 有 DynamicallyLegal 规则？
│   │   ├─ 规则返回 true？ → ✅ 合法，跳过
│   │   └─ 规则返回 false？ → ❌ 非法，必须转换
│   └─ 无动态规则？ → ❌ 非法，必须转换
└─ 未标记？ → 视转换模式而定
    ├─ FullConversion：未标记 = 非法
    └─ PartialConversion：未标记 = 合法
```

**Ch6 完全下降中的使用**：

```cpp
void ToyToLLVMLoweringPass::runOnOperation() {
  // LLVMConversionTarget 自动将 LLVM 方言标记为合法
  LLVMConversionTarget target(getContext());
  target.addLegalOp<ModuleOp>();  // ModuleOp 是特殊的顶层操作

  // 使用完全转换（不允许任何非法操作残留）
  applyFullConversion(module, target, std::move(patterns));
  // 如果转换后仍有非 LLVM 操作 → 报错
}
```

**Ch5 与 Ch6 的合法性策略对比**：

```
Ch5 (Partial):                    Ch6 (Full):
┌──────────────────────┐         ┌──────────────────────┐
│ Legal:               │         │ Legal:               │
│   Affine ✓           │         │   LLVM ✓             │
│   Arith ✓            │         │   ModuleOp ✓         │
│   Func ✓             │         │                      │
│   MemRef ✓           │         │ Illegal:             │
│                      │         │   其他所有方言 ✗     │
│ Illegal:             │         │                      │
│   Toy ✗              │         │ 转换方式:            │
│   (except print 条件) │         │   FullConversion     │
│                      │         │   (零容忍)           │
│ 转换方式:            │         └──────────────────────┘
│   PartialConversion  │
│   (允许残留)         │
└──────────────────────┘
```

**关键理解**：`addDynamicallyLegalOp` 的优先级高于 `addIllegalDialect`。即使整个 Toy 方言被标记为非法，`toy.print` 仍然可以通过动态检查被保留——但前提是它的操作数已经从 `TensorType` 转换为了 `MemRefType`。

---

# MLIR 面试题 · 第二部分：实际使用 & 原理

> 共 10 题，分为「实际使用」（5题）和「原理」（5题）两个主题。

---

## 🔧 实际使用篇（Practical Usage）

### 题目 11：DRR（Declarative Rewrite Rules）和 C++ RewritePattern 各自适用于什么场景？请举例说明。

**答案**：

| 方面         | DRR（TableGen 声明式）         | C++ RewritePattern（命令式）   |
| ------------ | ------------------------------ | ------------------------------ |
| **表达能力** | 适合简单的 1:1 或 1:N 模式匹配 | 可表达任意复杂的变换逻辑       |
| **代码量**   | 极少（几行 TableGen）          | 较多（需要完整的 C++ 类）      |
| **可维护性** | 高（声明式、自文档化）         | 较低（需要理解 Rewriter API）  |
| **动态条件** | 有限（只支持简单约束）         | 无限制（可以做任何运行时检查） |

**DRR 适合的场景**——结构化、模式固定的规则：

```tablegen
// Toy Ch3: reshape(reshape(x)) → reshape(x)
def ReshapeReshapeOptPattern : Pat<
  (ReshapeOp(ReshapeOp $arg)),
  (ReshapeOp $arg)>;
```

**C++ RewritePattern 适合的场景**——需要动态分析的复杂变换：

```cpp
// Toy Ch3: transpose(transpose(x)) → x
// 需要检查两个 transpose 的语义是否确实互逆
struct SimplifyRedundantTranspose : public OpRewritePattern<TransposeOp> {
  LogicalResult matchAndRewrite(TransposeOp op,
                                PatternRewriter &rewriter) const override {
    Value transposeInput = op.getOperand();
    auto inputOp = transposeInput.getDefiningOp<TransposeOp>();
    if (!inputOp)
      return failure();
    // 动态检查：确认是对同一个值的连续转置
    rewriter.replaceOp(op, {inputOp.getOperand()});
    return success();
  }
};
```

**选择原则**：能用 DRR 的优先用 DRR；涉及循环、条件分支、多步推导的用 C++。

---

### 题目 12：如何调试一个 MLIR Pass？请列举至少 3 种调试手段。

**答案**：

**方法 1：`-mlir-print-ir-before-all` / `-mlir-print-ir-after-all`**

在每个 Pass 前后打印 IR，观察 Pass 对 IR 的修改：

```bash
toyc-ch5 input.mlir -emit=mlir-affine -opt \
  -mlir-print-ir-before-all \
  -mlir-print-ir-after-all
```

**方法 2：`-debug` / `-debug-only=<tag>`**

配合代码中的 `LLVM_DEBUG` / `LDBG()` 宏输出调试信息：

```cpp
#define DEBUG_TYPE "shape-inference"

// 在 Pass 中：
LDBG() << "Inferring shape for: " << *op;
```

```bash
toyc-ch4 input.toy -emit=mlir -opt -debug-only=shape-inference
```

**方法 3：`-mlir-print-ir-after-change`**

只在 IR 实际发生变化时打印，减少输出噪音：

```bash
toyc-ch5 input.mlir -emit=mlir-affine -opt -mlir-print-ir-after-change
```

**方法 4：`-verify-each`**

在每个 Pass 后运行验证器，尽早发现生成了非法 IR 的 Pass：

```bash
toyc-ch6 input.mlir -emit=llvm -verify-each
```

**方法 5：Operation 的 `dump()` 方法**

在 C++ 代码中使用 GDB/LLDB 断点：

```cpp
// 在 Pass 代码中插入
op->dump();          // 打印单个操作
op->getParentOfType<ModuleOp>().dump();  // 打印整个模块
```

---

### 题目 13：Toy 教程中，`lowerOpToLoops()` 辅助函数的设计思路是什么？为什么要抽取这个公共函数？

**答案**：

`lowerOpToLoops()` 是 Ch5 `LowerToAffineLoops.cpp` 中提取的一个通用函数，负责将张量操作转换为嵌套的 Affine 循环。

**函数签名**：

```cpp
using LoopIterationFn = function_ref<Value(OpBuilder &, ValueRange loopIvs)>;

static void lowerOpToLoops(Operation *op, PatternRewriter &rewriter,
                           LoopIterationFn processIteration);
```

**设计思路——模板方法模式**：

```
lowerOpToLoops() 负责的"通用骨架"：
├─ 1. 将结果类型 Tensor → MemRef
├─ 2. 插入 memref.alloc / dealloc
├─ 3. 生成嵌套 affine.for 循环
├─ 4. 在循环体内调用 processIteration（由调用方定义）
├─ 5. 将 processIteration 返回值 store 到输出 memref
└─ 6. 用 alloc 替换原操作

调用方只需定义"循环体内做什么"：
```

**不同操作的 Lambda 区别**：

```cpp
// AddOp: 加载两个操作数，相加
lowerOpToLoops(op, rewriter, [&](OpBuilder &b, ValueRange ivs) {
  auto lhs = AffineLoadOp::create(b, loc, adaptor.getLhs(), ivs);
  auto rhs = AffineLoadOp::create(b, loc, adaptor.getRhs(), ivs);
  return arith::AddFOp::create(b, loc, lhs, rhs);
});

// TransposeOp: 用反转索引加载
lowerOpToLoops(op, rewriter, [&](OpBuilder &b, ValueRange ivs) {
  SmallVector<Value, 2> reverseIvs(llvm::reverse(ivs));
  return AffineLoadOp::create(b, loc, adaptor.getInput(), reverseIvs);
});

// MulOp: 加载两个操作数，相乘
lowerOpToLoops(op, rewriter, [&](OpBuilder &b, ValueRange ivs) {
  auto lhs = AffineLoadOp::create(b, loc, adaptor.getLhs(), ivs);
  auto rhs = AffineLoadOp::create(b, loc, adaptor.getRhs(), ivs);
  return arith::MulFOp::create(b, loc, lhs, rhs);
});
```

**好处**：

1. **消除代码重复**：alloc/dealloc/循环生成逻辑只写一次
2. **关注点分离**：Lowering 开发者只需思考"单个元素怎么计算"
3. **易于扩展**：新增操作只需写一个 Lambda

---

### 题目 14：在 MLIR 中，`OpAdaptor` 是什么？为什么 `matchAndRewrite` 中要用 `adaptor.getLhs()` 而不是 `op.getLhs()`？

**答案**：

**`OpAdaptor` 是经过类型转换后的操作数视图。**

在方言转换（Dialect Conversion）过程中，操作数的类型可能已经被 `TypeConverter` 转换了（如 Tensor → MemRef），但原始 `op` 中记录的仍是转换前的操作数。

```
原始操作 (op):
  toy.add %a, %b : tensor<2x3xf64>
     └─ op.getLhs() → %a : tensor<2x3xf64>  ← 旧类型！

适配器 (adaptor):
     └─ adaptor.getLhs() → %a' : memref<2x3xf64>  ← 新类型！
```

**具体对比**：

```cpp
LogicalResult matchAndRewrite(toy::AddOp op, OpAdaptor adaptor,
                              ConversionPatternRewriter &rewriter) const {
  // ❌ 错误：op.getLhs() 返回的是 tensor 类型的值
  //    在 Affine 层已经不存在了
  Value old_lhs = op.getLhs();  // tensor<2x3xf64>

  // ✅ 正确：adaptor.getLhs() 返回的是已转换为 memref 类型的值
  Value new_lhs = adaptor.getLhs();  // memref<2x3xf64>

  // 后续可以直接用 new_lhs 做 affine.load
  AffineLoadOp::create(builder, loc, new_lhs, loopIvs);
}
```

**使用规则**：

| 场景           | 用 `op`                     | 用 `adaptor`         |
| -------------- | --------------------------- | -------------------- |
| 获取操作的属性 | ✅ `op.getValue()`           | —                    |
| 获取操作的位置 | ✅ `op->getLoc()`            | —                    |
| 获取操作数的值 | ❌ 类型可能过期              | ✅ `adaptor.getLhs()` |
| 获取结果类型   | ✅ `op->result_type_begin()` | —                    |

---

### 题目 15：如何在 Toy 语言中实现常量折叠（Constant Folding）？请描述 Ch3 中 `ReshapeOp` 常量折叠的完整流程。

**答案**：

Ch3 中通过 DRR 规则实现了 `reshape(constant)` 的常量折叠。

**DRR 规则定义**（`ToyCombine.td`）：

```tablegen
def ReshapeConstant :
  NativeCodeCall<"$0.reshape(::llvm::cast<RankedTensorType>($1.getType()))">;

def FoldConstantReshapeOptPattern : Pat<
  (ReshapeOp:$res (ConstantOp $arg)),
  (ConstantOp (ReshapeConstant $arg, $res))>;
```

**完整流程**：

```
输入 IR:
  %0 = toy.constant dense<[[1, 2, 3], [4, 5, 6]]> : tensor<2x3xf64>
  %1 = toy.reshape(%0 : tensor<2x3xf64>) to tensor<3x2xf64>

匹配阶段:
  ├─ 模式匹配器发现 ReshapeOp 的输入是 ConstantOp
  ├─ 提取: $arg = dense<[[1,2,3],[4,5,6]]> : tensor<2x3xf64>
  └─ 提取: $res 的类型 = tensor<3x2xf64>

变换阶段:
  ├─ 调用 NativeCodeCall:
  │   $arg.reshape(cast<RankedTensorType>($res.getType()))
  │   = dense<[[1,2,3],[4,5,6]]>.reshape(tensor<3x2xf64>)
  │   = dense<[[1,2],[3,4],[5,6]]> : tensor<3x2xf64>
  └─ 生成新操作: ConstantOp(重塑后的属性)

输出 IR:
  %0 = toy.constant dense<[[1, 2], [3, 4], [5, 6]]> : tensor<3x2xf64>
  // ReshapeOp 被完全消除，常量在编译时重新排列
```

**优化效果**：运行时不再需要任何 reshape 计算，数据在编译期直接排列好。

---

## 📐 原理篇（Principles）

### 题目 16：MLIR 的多层抽象（Multi-Level Abstraction）相比传统编译器的固定 IR 层级有什么优势？请结合 Toy 的完整编译流水线说明。

**答案**：

**传统编译器的固定层级**：

```
源代码 → AST → 高层 IR → 低层 IR → 机器码
              (固定一层)  (固定一层)
```

问题：高层优化信息在下降到低层后丢失，无法恢复。

**MLIR 的多层抽象**：

```
源代码 → AST → Toy Dialect → Affine Dialect → SCF → LLVM Dialect → 机器码
              (领域语义)   (循环语义)    (控制流)  (机器语义)
```

**优势体现在 Toy 编译流水线中**：

| 抽象层             | 可做的优化                                  | 传统编译器能否做到               |
| ------------------ | ------------------------------------------- | -------------------------------- |
| **Toy Dialect**    | `transpose(transpose(x))→x`、`reshape` 折叠 | ❌ 低层 IR 中无"转置"概念         |
| **Toy Dialect**    | 函数内联 + 形状推断                         | ⚠️ 部分可以，但形状信息已丢失     |
| **Affine Dialect** | 循环融合、循环平铺、依赖分析                | ⚠️ 需要从低层 IR 逆向恢复循环结构 |
| **LLVM Dialect**   | 寄存器分配、指令选择                        | ✅ 这是传统编译器擅长的           |

**关键优势**：每一层保留了该层级特有的语义信息，优化器可以在最合适的抽象层做最有效的变换，而不是所有优化都在同一层竞争。

---

### 题目 17：MLIR 中的 `PatternRewriter` 与 `ConversionPatternRewriter` 有什么区别？分别用于什么场景？

**答案**：

两者都是 IR 重写工具，但适用的框架不同：

**`PatternRewriter`（普通重写）**：

- 用于 **Canonicalization**（规范化）等不涉及方言转换的场景
- 操作停留在同一个方言内
- 使用 `OpRewritePattern<Op>`
- 通过 `Canonicalizer` pass 驱动

```cpp
// Ch3: 在 Toy 方言内部做优化
struct SimplifyRedundantTranspose : public OpRewritePattern<TransposeOp> {
  LogicalResult matchAndRewrite(TransposeOp op,
                                PatternRewriter &rewriter) const override {
    // 输入和输出都是 Toy 方言操作
    rewriter.replaceOp(op, {inputOp.getOperand()});
    return success();
  }
};
```

**`ConversionPatternRewriter`（转换重写）**：

- 用于 **Dialect Conversion**（方言转换），操作从一个方言转换到另一个
- 配合 `ConversionTarget` 和 `TypeConverter` 使用
- 使用 `OpConversionPattern<Op>`
- 通过 `applyPartialConversion` / `applyFullConversion` 驱动

```cpp
// Ch5: 从 Toy 方言转换到 Affine 方言
struct AddOpLowering : public OpConversionPattern<toy::AddOp> {
  LogicalResult matchAndRewrite(toy::AddOp op, OpAdaptor adaptor,
                                ConversionPatternRewriter &rewriter) const {
    // 注意：有 OpAdaptor 参数（处理类型转换后的操作数）
    // 输入是 Toy 操作，输出是 Affine 操作
    ...
  }
};
```

**核心区别**：

| 方面           | PatternRewriter  | ConversionPatternRewriter      |
| -------------- | ---------------- | ------------------------------ |
| **类型转换**   | 不支持           | 支持（通过 TypeConverter）     |
| **OpAdaptor**  | 无               | 有（提供转换后的操作数）       |
| **合法性检查** | 无               | 有（ConversionTarget）         |
| **回滚机制**   | 无               | 有（转换失败时可回滚所有修改） |
| **典型用途**   | 规范化、窥孔优化 | 方言下降（Lowering）           |

---

### 题目 18：MLIR 中 `OperationPass<FuncOp>` 和 `OperationPass<ModuleOp>` 有什么区别？为什么 ShapeInferencePass 作用在 FuncOp 而 ToyToAffineLoweringPass 作用在 ModuleOp？

**答案**：

`OperationPass<T>` 的模板参数 `T` 指定了 Pass **作用的操作粒度**：

```cpp
// 作用在每个函数上，每个函数独立处理
struct ShapeInferencePass
    : public PassWrapper<ShapeInferencePass, OperationPass<toy::FuncOp>> { ... };

// 作用在整个模块上，一次处理所有内容
struct ToyToAffineLoweringPass
    : public PassWrapper<ToyToAffineLoweringPass, OperationPass<ModuleOp>> { ... };
```

**区别**：

| 方面         | `OperationPass<FuncOp>`                 | `OperationPass<ModuleOp>`  |
| ------------ | --------------------------------------- | -------------------------- |
| **粒度**     | 每个函数独立调用一次 `runOnOperation()` | 整个模块调用一次           |
| **并行性**   | 不同函数可并行处理                      | 无法并行                   |
| **可见范围** | 只能看到当前函数                        | 可以看到所有函数和全局符号 |
| **隔离性**   | 函数间互不影响                          | 可以跨函数修改             |

**为什么 ShapeInferencePass 用 FuncOp？**

- 形状推断是**过程内**（intraprocedural）分析：只需在单个函数内传播形状
- Ch4 中假设所有函数调用已被内联，只剩 `main`
- 用 FuncOp 粒度可以让 MLIR 框架并行处理多个函数

**为什么 ToyToAffineLoweringPass 用 ModuleOp？**

- 方言转换需要全局视角：`ConversionTarget` 对整个模块设置合法性规则
- `FuncOpLowering` 需要将 `toy.func` 替换为 `func.func`，这涉及模块级的符号表操作
- `applyPartialConversion` 需要在模块级别一致地应用所有模式

---

### 题目 19：MLIR 中 Hook 和 Interface 的设计哲学有何不同？为什么说 Interface 更具可扩展性？

**答案**：

**Hook（钩子）的设计哲学——"中心化"**：

MLIR 框架预定义了一组特定的功能点，操作通过重写这些固定方法来参与特定的变换。

```cpp
class MyOp : public Op<MyOp> {
  // 框架定义的固定钩子
  static void getCanonicalizationPatterns(RewritePatternSet &, MLIRContext *);
  OpFoldResult fold(FoldAdaptor);
  LogicalResult verify();
};
```

**Interface（接口）的设计哲学——"去中心化"**：

定义通用的方法契约，任何操作或方言都可以实现，且可以在外部附加。

```cpp
// 定义接口（独立于任何操作）
class ShapeInferenceOpInterface {
  void inferShapes();  // 方法契约
};

// 操作实现接口（自愿参与）
def AddOp : Toy_Op<"add", [
    DeclareOpInterfaceMethods<ShapeInferenceOpInterface>
]> { ... }
```

**可扩展性对比**：

| 场景           | Hook                                          | Interface                         |
| -------------- | --------------------------------------------- | --------------------------------- |
| **添加新变换** | 需要给 Op 基类添加新虚方法 → 所有操作都受影响 | 定义新接口 → 只有关心的操作实现它 |
| **第三方扩展** | 无法从外部给已有操作添加 Hook                 | 可以从外部为已有操作附加接口实现  |
| **跨方言复用** | Hook 绑定在特定方言的 Op 基类中               | Interface 跨方言通用              |

**Toy 教程中的体现**：

- **Hook**：`getCanonicalizationPatterns`（Ch3）——只能在操作定义时注册
- **Interface**：`ShapeInferenceOpInterface`（Ch4）——独立定义，多个操作自愿实现
- **Interface**：`CastOpInterface`（Ch4）——MLIR 内置接口，Toy 的 `CastOp` 实现它
- **Interface**：`DialectInlinerInterface`（Ch4）——方言级接口，控制内联行为

**关键洞察**：Interface 遵循"开闭原则"——对扩展开放，对修改关闭。新增变换不需要修改已有操作的代码。

---

### 题目 20：解释 MLIR 中值语义（Value Semantics）和引用语义（Reference Semantics）的区别，以及为什么 Tensor → MemRef 的转换是编译流程中不可避免的一步。

**答案**：

**值语义（Value Semantics）— Tensor**：

```mlir
%0 = toy.constant dense<[1, 2, 3]> : tensor<3xf64>
%1 = toy.add %0, %0 : tensor<3xf64>
// %0 在 add 之后仍然是 [1, 2, 3]，不可能被修改
// %1 是一个全新的值 [2, 4, 6]
```

- 每个值是不可变的（immutable）
- 没有别名问题（no aliasing）
- 操作产生新值而非修改已有值
- **便于推理和优化（CSE、DCE、代码移动）**

**引用语义（Reference Semantics）— MemRef**：

```mlir
%alloc = memref.alloc() : memref<3xf64>
memref.store %val, %alloc[0] : memref<3xf64>
// %alloc 的内容被修改了！
// 任何引用 %alloc 的操作都能看到变化
```

- 值是可变的（mutable）
- 存在别名问题
- 操作可以原地修改内存
- 对应真实的内存分配

**为什么转换不可避免？**

```
硬件现实:
├─ CPU 只能操作内存地址和寄存器
├─ 没有"不可变张量"的硬件概念
├─ 循环需要通过索引访问内存
└─ 函数调用通过指针传递数据

所以:
  tensor<2x3xf64>  (数学抽象)
        ↓ 必须转换
  memref<2x3xf64>  (内存实体)
        ↓ 进一步转换
  LLVM 指针 + GEP  (机器表示)
```

**转换时机的设计考量**：

```
          值语义层                    引用语义层
    ┌─────────────────┐         ┌─────────────────┐
    │ 优化容易:       │         │ 优化困难:       │
    │ - CSE ✓         │         │ - 需要别名分析  │
    │ - DCE ✓         │  转换   │ - 需要副作用分析│
    │ - 代码移动 ✓    │ ──→    │ - 需要依赖分析  │
    │ - 常量折叠 ✓    │         │                 │
    │                 │         │ 但能映射到硬件  │
    └─────────────────┘         └─────────────────┘
    
    尽量在值语义层做优化，最后再转换为引用语义
```

这就是为什么 Toy 教程在 Ch3/Ch4（值语义）做完所有高层优化后，才在 Ch5（引用语义）进行 Tensor → MemRef 转换。

---

# MLIR 面试题 · 第三部分：架构设计者视角

> 共 5 题，面向有编译器架构设计经验的高级候选人。

---

### 题目 21：为什么 MLIR 选择"一切皆操作"（Everything is an Operation）的统一抽象，而非像传统编译器那样区分指令、声明、类型定义等不同的 IR 节点？这种设计有哪些权衡？

**答案**：

**设计动机**：

传统编译器中，指令、函数、模块、类型声明是不同的 IR 节点类型，各有自己的遍历/变换 API：

```
传统编译器:
├─ Module (特殊容器)
│   ├─ Function (特殊容器)
│   │   ├─ BasicBlock (特殊容器)
│   │   │   ├─ Instruction (核心 IR 节点)
│   │   │   ├─ Instruction
│   │   │   └─ TerminatorInst (特殊子类)
│   │   └─ BasicBlock
│   └─ GlobalVariable (又一种特殊节点)
└─ ...
```

MLIR 将所有这些统一为 `Operation`：

```
MLIR:
├─ Operation (ModuleOp)
│   └─ Region → Block
│       ├─ Operation (FuncOp)
│       │   └─ Region → Block
│       │       ├─ Operation (affine.for)
│       │       │   └─ Region → Block
│       │       │       ├─ Operation (affine.load)
│       │       │       └─ Operation (affine.store)
│       │       └─ Operation (func.return)
│       └─ Operation (FuncOp)
└─ ...
```

**收益**：

| 收益                   | 说明                                                             |
| ---------------------- | ---------------------------------------------------------------- |
| **统一的变换基础设施** | 同一套 PatternRewriter 可以重写任何层级的操作                    |
| **统一的遍历机制**     | `op->walk()` 可递归遍历所有嵌套操作                              |
| **统一的验证框架**     | Traits 和 Interfaces 对所有操作通用                              |
| **方言可扩展**         | 新增"函数"、"模块"级概念不需要修改框架                           |
| **嵌套天然支持**       | `affine.for` 内嵌 `affine.for` 与 `func` 内嵌 `block` 是同一机制 |

**代价**：

| 代价             | 说明                                                                |
| ---------------- | ------------------------------------------------------------------- |
| **运行时开销**   | Operation 是堆分配对象，比固定结构的 IR 节点更重                    |
| **类型安全弱化** | 编译期无法区分"函数级操作"和"指令级操作"，需要运行时 `isa/dyn_cast` |
| **学习曲线**     | "函数也是操作"这一概念对传统编译器开发者不直观                      |

**权衡结论**：MLIR 用运行时的微小开销换取了架构上的巨大灵活性，使得同一套基础设施可以服务于从 TensorFlow 图到硬件指令的任意抽象层级。

---

### 题目 22：MLIR 的 Region 为什么设计为可以有不同的语义（SSACFG Region vs Graph Region）？这解决了什么架构级别的问题？

**答案**：

**两种 Region 语义**：

| 类型              | 语义                                                                    | 使用场景                             |
| ----------------- | ----------------------------------------------------------------------- | ------------------------------------ |
| **SSACFG Region** | Block 之间通过控制流连接（分支/跳转），Block 内部 SSA，值的支配关系明确 | `func.func`、`affine.for`、`scf.for` |
| **Graph Region**  | Block 内操作没有固定顺序，操作之间通过数据依赖隐式排序                  | TensorFlow 图、硬件描述、数据流图    |

**解决的架构问题**：

传统编译器假设 IR 是 SSACFG 形式——指令有固定顺序、Block 之间有控制流边。但许多领域的计算模型不是这样的：

```
TensorFlow 计算图:            硬件电路描述:
  MatMul ──→ Add              Input1 ──→ ALU ──→ Register
     ↑        ↑               Input2 ──↗
  Input1   Input2

  → 操作之间只有数据依赖      → 组件之间是并行连接
  → 没有"先执行A再执行B"       → 没有时序上的先后
```

如果强制用 SSACFG 表示，就必须人为引入虚假的顺序依赖，破坏了原始语义。

**设计影响**：

```cpp
// SSACFG Region: func.func 的函数体
func.func @example() {
  ^bb0:          // Block 0
    ...
    cf.br ^bb1   // 必须有显式的控制流终结符
  ^bb1:          // Block 1
    ...
}

// Graph Region: 某些方言的计算图
// Block 内操作可以任意重排，只要数据依赖满足
my_graph.region {
  %a = op1(...)
  %b = op2(...)    // op1 和 op2 没有顺序关系
  %c = op3(%a, %b) // op3 依赖 op1 和 op2
}
```

**架构洞察**：Region 语义的多态性使 MLIR 能够作为"IR 的 IR"——不同方言可以选择最适合自己领域的执行模型，而不是被迫适应一种固定的计算模型。

---

### 题目 23：从架构设计角度，MLIR 为什么选择渐进式下降（Progressive Lowering）而非一步到位的下降？这对 Pass 管线设计有什么影响？

**答案**：

**一步到位下降的问题**：

```
Toy IR ──────────────────────→ LLVM IR
         一个巨大的 Pass

问题:
├─ Pass 代码极其复杂（需要同时处理类型转换+循环生成+内存管理+控制流）
├─ 优化机会丢失（高层信息在一步中全部消失）
├─ 难以复用（每个高层方言都要写自己的→LLVM 转换）
└─ 难以测试和调试（中间状态不可观测）
```

**渐进式下降的优势**：

```
Toy IR → Affine+MemRef → SCF+MemRef → CF+MemRef → LLVM
  (1)       (2)            (3)          (4)        (5)

优势:
├─ 每步只做一件事（关注点分离）
├─ 每层可独立优化（Affine 层做循环优化，LLVM 层做寄存器分配）
├─ 中间层可复用（Affine→SCF 的转换被所有使用 Affine 的方言共享）
├─ 每步可独立测试（-emit=mlir-affine 查看中间结果）
└─ 新方言只需接入合适的中间层（不必直接到 LLVM）
```

**对 Pass 管线设计的影响**：

1. **管线是分层的**：优化 Pass 和下降 Pass 交替出现

```
Pipeline:
  Canonicalize (Toy 层优化)
  → Inline (Toy 层变换)
  → ShapeInference (Toy 层分析)
  → LowerToAffine (下降)
  → AffineLoopFusion (Affine 层优化)
  → AffineLoopTiling (Affine 层优化)
  → LowerToLLVM (下降)
  → LLVM 优化
```

2. **ConversionTarget 定义了层级边界**：每次下降明确"什么合法、什么非法"

3. **中间方言是"公共接口"**：不同的高层方言可以共享同一个下降路径

```
Toy ────→ Affine ────→ SCF ────→ LLVM
Linalg ──↗            ↗
TOSA ────→ Linalg ──↗
```

**架构原则**：渐进式下降体现了"每一层做好自己的事"的分层设计思想，使编译器成为一组可组合的模块，而非一个单体系统。

---

### 题目 24：MLIR 的 TypeConverter 在架构中扮演什么角色？如果没有 TypeConverter，方言转换会面临什么困难？

**答案**：

**TypeConverter 的角色**：

TypeConverter 是方言转换框架中负责**类型映射**的组件，定义了源方言的类型如何转换为目标方言的类型。

```
TypeConverter 的映射:
  tensor<2x3xf64>  →  memref<2x3xf64>    (Toy→Affine)
  memref<2x3xf64>  →  !llvm.struct<...>   (MemRef→LLVM)
  index             →  i64                  (Index→LLVM)
  f64               →  f64                  (保持不变)
```

**如果没有 TypeConverter 会怎样？**

问题 1：**签名转换困难**

```mlir
// 原始函数
func @foo(%arg0: tensor<2x3xf64>) -> tensor<2x3xf64> { ... }

// 没有 TypeConverter，开发者需要手动：
// 1. 创建新函数（新签名）
// 2. 建立旧参数到新参数的映射
// 3. 更新所有使用旧参数的操作
// 4. 处理嵌套区域中的类型引用
// 5. 更新所有调用者
```

问题 2：**Block 参数类型不一致**

```mlir
// 循环的 Block 参数也有类型
affine.for %i = 0 to 10 iter_args(%v = %init : tensor<3xf64>) {
  // %v 的类型需要从 tensor 转换为 memref
  // 所有使用 %v 的操作也需要更新
}
```

问题 3：**OpAdaptor 无法工作**

没有 TypeConverter，就没有 OpAdaptor，开发者在 `matchAndRewrite` 中拿到的操作数仍是旧类型，需要手动查找转换后的值。

**TypeConverter 的架构价值**：

```
没有 TypeConverter:                 有 TypeConverter:
┌──────────────────┐              ┌──────────────────┐
│ 每个 Pattern 都  │              │ TypeConverter     │
│ 手动处理类型转换 │              │ 统一处理类型映射  │
│ 手动更新 Block   │              │                  │
│ 参数             │              │ Framework 自动:  │
│ 手动建立新旧值   │              │ - 转换签名       │
│ 映射             │              │ - 更新 Block 参数│
│ 极易出错         │              │ - 提供 OpAdaptor │
└──────────────────┘              └──────────────────┘
```

**设计洞察**：TypeConverter 将"类型转换"从每个 Pattern 中抽离出来，成为方言转换框架的全局策略，实现了类型映射的集中管理和自动传播。

---

### 题目 25：MLIR 为什么需要同时支持 FullConversion 和 PartialConversion？从编译器架构角度分析这两种模式的设计意图。

**答案**：

**两种模式的本质区别**：

```cpp
// PartialConversion: 允许非法操作残留
applyPartialConversion(module, target, patterns);
// → 转换后 IR 中可以同时存在多个方言的操作

// FullConversion: 不允许任何非法操作残留
applyFullConversion(module, target, patterns);
// → 转换后 IR 中只剩合法方言的操作
```

**为什么需要 PartialConversion？**

设计意图：**支持渐进式、增量式的方言转换**

```
场景: Toy → Affine 的部分下降 (Ch5)

Toy 方言中有 7 种操作:
  ConstantOp ──→ 转换为 Affine
  AddOp      ──→ 转换为 Affine
  MulOp      ──→ 转换为 Affine
  TransposeOp──→ 转换为 Affine
  FuncOp     ──→ 转换为 func.func
  ReturnOp   ──→ 转换为 func.return
  PrintOp    ──→ 保留！(目标方言中无等价物)

如果只有 FullConversion:
  → PrintOp 无法转换 → 整个转换失败
  → 要么实现 print 的完整下降（但目标方言不支持 I/O）
  → 要么将 print 的下降混入当前 Pass（破坏关注点分离）
```

**为什么需要 FullConversion？**

设计意图：**确保编译流水线的最终一致性**

```
场景: 最终下降到 LLVM (Ch6)

在生成机器码前，IR 中不能有任何非 LLVM 操作:
  - 硬件不理解 affine.for
  - 硬件不理解 memref.load
  - 硬件不理解 toy.print

FullConversion 保证:
  → 转换后只剩 LLVM 方言操作
  → 如果有遗漏 → 编译失败（而非生成错误的机器码）
  → 相当于类型系统的"完整性检查"
```

**两种模式在管线中的协作**：

```
Toy IR
  │
  ├─ PartialConversion (Toy → Affine)
  │   保留: toy.print
  │   保证: 计算操作全部转换
  │
  ├─ (Affine 层优化)
  │
  └─ FullConversion (All → LLVM)
      保留: 无
      保证: IR 完全合法，可以生成机器码
```

**架构设计原则**：

| 原则         | PartialConversion      | FullConversion     |
| ------------ | ---------------------- | ------------------ |
| **何时使用** | 中间下降步骤           | 最终下降步骤       |
| **容错策略** | 宽容（允许未转换操作） | 严格（零容忍）     |
| **验证强度** | 弱（只验证已转换操作） | 强（验证所有操作） |
| **设计目的** | 支持增量转换           | 保证最终一致性     |

**本质**：PartialConversion 是"过程中的工具"，FullConversion 是"终点的守门人"。两者配合实现了渐进式下降的安全性保障。

---

# MLIR 面试题 · 第四部分：Affine Dialect & MemRef 专题

> 共 10 题，中高级难度，聚焦 Affine 方言与 MemRef 的核心概念与实际应用。

---

## 🟡 中级

### 题目 26：什么是 AffineMap？为什么 Affine 方言要求访存地址必须是仿射表达式？

**答案**：

**AffineMap 定义**：

AffineMap 是从一组维度（dimension）和符号（symbol）到一组结果的仿射映射，形式为：

$$f(d_0, d_1, ..., s_0, s_1, ...) = (a_0 \cdot d_0 + a_1 \cdot d_1 + ... + b_0 \cdot s_0 + ... + c)$$

其中 $d_i$ 是维度变量（循环归纳变量），$s_i$ 是符号变量（循环不变量），$a_i, b_i, c$ 是整数常量。

```mlir
// 示例
#map0 = affine_map<(d0, d1) -> (d0, d1)>        // 恒等映射
#map1 = affine_map<(d0, d1) -> (d1, d0)>        // 转置映射
#map2 = affine_map<(d0)[s0] -> (d0 + s0)>       // 带符号的偏移
#map3 = affine_map<(d0, d1) -> (d0 * 4 + d1)>   // 线性化
```

**为什么要求仿射？**

仿射约束使以下分析**可判定**（decidable）：

| 分析         | 仿射可做                     | 非仿射不可做               |
| ------------ | ---------------------------- | -------------------------- |
| **依赖分析** | 精确判定两个访存是否存在依赖 | 不可判定（等价于停机问题） |
| **循环融合** | 可以安全地融合两个循环       | 无法保证正确性             |
| **循环平铺** | 可以精确计算 tile 的边界     | 可能引入越界访问           |
| **并行化**   | 可以证明循环迭代间无依赖     | 保守假设全部有依赖         |
| **向量化**   | 可以确定连续访问模式         | 无法确定                   |

**反例——非仿射访问无法分析**：

```mlir
// 仿射（可分析）
%v = affine.load %A[%i + %j * 4] : memref<100xf64>

// 非仿射（不可分析）
%idx = call @compute_index(%i)   // 运行时才能确定
%v = memref.load %A[%idx]        // 编译期无法做依赖分析
```

---

### 题目 27：`affine.load` / `affine.store` 与 `memref.load` / `memref.store` 有什么区别？什么时候用哪个？

**答案**：

| 方面         | `affine.load/store`    | `memref.load/store` |
| ------------ | ---------------------- | ------------------- |
| **地址约束** | 必须是仿射表达式       | 任意 index 值       |
| **所属方言** | Affine 方言            | MemRef 方言         |
| **可分析性** | 支持依赖分析、循环优化 | 无法做精确依赖分析  |
| **使用场景** | 仿射循环体内           | 通用内存访问        |
| **IR 验证**  | 编译期验证地址是仿射的 | 不验证地址形式      |

**示例对比**：

```mlir
// affine.load: 地址是仿射表达式，编译期可分析
affine.for %i = 0 to 10 {
  affine.for %j = 0 to 20 {
    %v = affine.load %A[%i, %j] : memref<10x20xf64>
    //                 ^^^  ^^^
    //    仿射表达式: d0=i, d1=j → (d0, d1)
  }
}

// memref.load: 地址可以是任意计算结果
%idx = arith.remsi %i, %c10 : index   // 取模运算，非仿射
%v = memref.load %A[%idx] : memref<100xf64>
//                  ^^^^
//    非仿射表达式，无法做依赖分析
```

**选择原则**：

```
需要做循环优化（融合/平铺/并行化）？
├─ 是 → 用 affine.load/store（保留可分析性）
└─ 否 → 用 memref.load/store（更灵活）
```

**在 Toy 教程中**：Ch5 的 `LowerToAffineLoops.cpp` 使用 `affine.load/store`，因为生成的是规则的嵌套循环，可以利用 Affine 层的优化。

---

### 题目 28：MemRef 的 Layout Map 是什么？`memref<2x3xf64>` 和 `memref<2x3xf64, affine_map<(d0,d1)->(d1,d0)>>` 有什么区别？

**答案**：

**Layout Map**：定义了多维逻辑索引到一维物理内存地址的映射关系。

**默认布局（行优先 / Row-Major）**：

```
memref<2x3xf64>
等价于 memref<2x3xf64, affine_map<(d0, d1) -> (d0 * 3 + d1)>>

逻辑视图:          物理内存:
[0,0] [0,1] [0,2]  addr 0: [0,0]
[1,0] [1,1] [1,2]  addr 1: [0,1]
                    addr 2: [0,2]
                    addr 3: [1,0]
                    addr 4: [1,1]
                    addr 5: [1,2]
```

**自定义布局（列优先 / Column-Major）**：
映射公式的拆解
affine_map<(d0, d1) -> (d1 * 2 + d0)>
输入 $(d_0, d_1)$：逻辑维度的坐标（行号，列号）。
输出 $(d_1 \times 2 + d_0)$：物理内存中的偏移量（Offset）。
这个公式决定了数据在内存中是如何“铺”开的：
$d_1 \times 2$：这里的 2 就是第一维（行）的大小。这意味着每增加一列（$d_1$ 加 1），在内存地址上要跳过 2 个元素。
$+ d_0$：这意味着同一列中，相邻行（$d_0$ 加 1）在内存中是连续的（步长为 1）。

```
memref<2x3xf64, affine_map<(d0, d1) -> (d1 * 2 + d0)>>

逻辑视图:          物理内存:
[0,0] [0,1] [0,2]  addr 0: [0,0]
[1,0] [1,1] [1,2]  addr 1: [1,0]
                    addr 2: [0,1]
                    addr 3: [1,1]
                    addr 4: [0,2]
                    addr 5: [1,2]
```

**转置布局**：

```
memref<2x3xf64, affine_map<(d0, d1) -> (d1, d0)>>

逻辑索引 [i, j] 映射到物理索引 [j, i]
即：用 [i,j] 访问，实际读取的是底层存储的 [j,i] 位置
```

**实际用途**：

| 场景                     | Layout Map                             |
| ------------------------ | -------------------------------------- |
| C 风格数组               | 默认（行优先）                         |
| Fortran 风格数组         | 列优先                                 |
| 图像存储（NHWC vs NCHW） | 自定义维度排列                         |
| 硬件 Tiling              | `(d0, d1) -> (d0/4, d1/4, d0%4, d1%4)` |
| 转置视图（零拷贝）       | `(d0, d1) -> (d1, d0)`                 |

**关键点**：Layout Map 允许在**不移动数据**的情况下改变数组的逻辑视图。

---

### 题目 29：`memref.alloc` 和 `memref.alloca` 有什么区别？Toy 教程中为什么选择 `memref.alloc` + `memref.dealloc`？

**答案**：

| 方面            | `memref.alloc`               | `memref.alloca`             |
| --------------- | ---------------------------- | --------------------------- |
| **分配位置**    | 堆（Heap）                   | 栈（Stack）                 |
| **生命周期**    | 手动管理（需要 `dealloc`）   | 自动释放（函数返回时）      |
| **性能**        | 较慢（系统调用）             | 较快（移动栈指针）          |
| **大小限制**    | 几乎无限制                   | 受栈大小限制（通常 1-8 MB） |
| **下降到 LLVM** | → `malloc` / `aligned_alloc` | → `alloca` 指令             |

**Toy 教程选择 `alloc` + `dealloc` 的原因**：

1. **通用性**：`alloc` 适用于任意大小的张量，`alloca` 可能因张量过大导致栈溢出
2. **教学目的**：演示显式的内存管理（分配 + 释放的配对模式）
3. **简化设计**：Toy 函数没有控制流，所以 alloc 放在块头、dealloc 放在块尾的简单策略是安全的

```cpp
static Value insertAllocAndDealloc(MemRefType type, Location loc,
                                   PatternRewriter &rewriter) {
  auto alloc = memref::AllocOp::create(rewriter, loc, type);
  alloc->moveBefore(&parentBlock->front());     // 块头分配

  auto dealloc = memref::DeallocOp::create(rewriter, loc, alloc);
  dealloc->moveBefore(&parentBlock->back());    // 块尾释放
  return alloc;
}
```

**实际项目中的选择建议**：

```
小型临时缓冲区（已知大小 < 几KB）→ alloca（性能更好）
大型张量 / 动态大小               → alloc + dealloc
需要 Buffer 复用优化              → alloc + BufferDeallocation Pass
```

---

### 题目 30：`buildAffineLoopNest` 函数做了什么？它和手动创建 `affine.for` 操作有什么区别？

**答案**：

**`buildAffineLoopNest` 的功能**：

一次性创建多层嵌套的 `affine.for` 循环，并通过回调函数定义最内层循环体。

```cpp
// Toy Ch5 中的调用
SmallVector<int64_t, 4> lowerBounds(rank, 0);
SmallVector<int64_t, 4> steps(rank, 1);
affine::buildAffineLoopNest(
    rewriter, loc, lowerBounds, tensorType.getShape(), steps,
    [&](OpBuilder &nestedBuilder, Location loc, ValueRange ivs) {
      Value val = processIteration(nestedBuilder, ivs);
      affine::AffineStoreOp::create(nestedBuilder, loc, val, alloc, ivs);
    });
```

**等价的手动创建方式**（以 2 层循环为例）：

```cpp
// 手动创建: 繁琐且容易出错
auto outerLoop = affine::AffineForOp::create(rewriter, loc, 0, shape[0], 1);
rewriter.setInsertionPointToStart(outerLoop.getBody());

auto innerLoop = affine::AffineForOp::create(rewriter, loc, 0, shape[1], 1);
rewriter.setInsertionPointToStart(innerLoop.getBody());

Value iv0 = outerLoop.getInductionVar();
Value iv1 = innerLoop.getInductionVar();
// ... 循环体逻辑 ...

// 注意: 还需要处理 yield 终止符、插入点恢复等
rewriter.setInsertionPointAfter(outerLoop);
```

**对比**：

| 方面           | `buildAffineLoopNest`   | 手动创建               |
| -------------- | ----------------------- | ---------------------- |
| **代码量**     | 5-10 行                 | 20-40 行（随层数增加） |
| **维度通用**   | 自动适配任意层数        | 需要为每层手写或递归   |
| **插入点管理** | 自动管理                | 手动管理（极易出错）   |
| **终止符**     | 自动生成 `affine.yield` | 需要手动创建           |
| **灵活性**     | 较低（固定模式）        | 高（可自定义循环结构） |

**何时需要手动创建**：

- 非矩形循环（上界依赖外层变量）
- 循环携带依赖（iter_args）
- 非完美嵌套循环（层间有额外操作）

---

## 🔴 高级

### 题目 31：Affine 方言中的依赖分析（Dependence Analysis）是如何工作的？为什么循环融合（Loop Fusion）需要依赖分析？

**答案**：

**依赖分析的核心**：

给定两个内存访问 A 和 B，判断是否存在循环迭代 $(i_1, j_1)$ 和 $(i_2, j_2)$ 使得它们访问同一个内存位置。

**数学形式化**：

对于两个仿射访问：
- A: `affine.load %mem[f(i, j)]`，其中 $f(i,j) = a_1 i + a_2 j + c_1$
- B: `affine.store %v, %mem[g(i, j)]`，其中 $g(i,j) = b_1 i + b_2 j + c_2$

依赖存在的条件：

$$a_1 i_1 + a_2 j_1 + c_1 = b_1 i_2 + b_2 j_2 + c_2$$

在循环边界约束下求解此线性丢番图方程。由于都是仿射表达式，**此问题有多项式时间算法**。

**循环融合为什么需要依赖分析**：

```mlir
// 融合前: 两个独立循环
affine.for %i = 0 to N {                  // Loop 1
  %a = affine.load %A[%i]
  affine.store %a_plus_1, %B[%i]          // 写 B[i]
}
affine.for %j = 0 to N {                  // Loop 2
  %b = affine.load %B[%j]                 // 读 B[j]
  affine.store %b_times_2, %C[%j]
}

// 问题: 可以融合吗？
// Loop2 读 B[j] 依赖于 Loop1 写 B[i] (当 i==j 时)
// 这是一个 RAW (Read After Write) 依赖
// 依赖方向: Loop1 → Loop2 (正向)
// 结论: ✅ 可以安全融合（正向依赖在融合后仍被保持）

// 融合后:
affine.for %i = 0 to N {
  %a = affine.load %A[%i]
  affine.store %a_plus_1, %B[%i]          // 先写 B[i]
  %b = affine.load %B[%i]                 // 后读 B[i] ✓ 依赖满足
  affine.store %b_times_2, %C[%i]
}
```

**不能融合的反例**：

```mlir
affine.for %i = 0 to N {
  affine.store %v, %A[%i]       // 写 A[i]
}
affine.for %j = 0 to N {
  %v = affine.load %A[%j + 1]   // 读 A[j+1]
  affine.store %v2, %B[%j]
}

// 依赖: 读 A[j+1] 依赖写 A[i]，当 i = j+1
// 如果融合: 迭代 j 会读 A[j+1]，但 A[j+1] 要到迭代 j+1 才写入
// → 反向依赖，融合会破坏程序语义！
```

---

### 题目 32：什么是 Bufferization？`One-Shot Bufferize` 和 Toy 教程中手动的 Tensor→MemRef 转换有什么区别？

**答案**：

**Bufferization 定义**：

将值语义（Tensor）操作转换为引用语义（MemRef）操作的过程，核心挑战是决定哪些操作可以**原地修改**（in-place），哪些需要**额外分配**（out-of-place）。

**Toy 教程中的手动转换（Ch5）**：

```cpp
// 策略：每个操作的每个结果都分配新的 memref
static Value insertAllocAndDealloc(MemRefType type, ...) {
  auto alloc = memref::AllocOp::create(...);  // 每次都分配新内存
  auto dealloc = memref::DeallocOp::create(...);
  return alloc;
}
```

问题：

```mlir
// 手动转换后: 每个操作都有自己的 alloc
%alloc_0 = memref.alloc() : memref<3x2xf64>  // constant 的结果
%alloc_1 = memref.alloc() : memref<3x2xf64>  // transpose 的结果
%alloc_2 = memref.alloc() : memref<3x2xf64>  // mul 的结果
// → 3 次分配，即使 alloc_0 在 transpose 后不再使用
```

**One-Shot Bufferize（现代方法）**：

```
分析阶段:
├─ 对每个 tensor 操作，分析其输入 tensor 是否还有其他使用者
├─ 如果没有 → 可以原地修改（in-place），无需新分配
├─ 如果有   → 必须拷贝（out-of-place），需要新分配
└─ 使用别名分析确定安全性

优化结果:
%alloc_0 = memref.alloc() : memref<3x2xf64>  // constant
// transpose 可以原地写入 alloc_0（如果 constant 之后无人使用）
// mul 可以原地写入 transpose 的缓冲区
// → 可能只需 1 次分配！
```

**对比**：

| 方面            | Toy 手动转换       | One-Shot Bufferize   |
| --------------- | ------------------ | -------------------- |
| **分配策略**    | 每操作每结果都分配 | 尽量原地修改         |
| **内存效率**    | 低（大量冗余分配） | 高（最小化分配）     |
| **实现复杂度**  | 简单（直接替换）   | 复杂（需要别名分析） |
| **适用范围**    | 教学 / 简单场景    | 生产级编译器         |
| **Buffer 复用** | 无                 | 有（通过别名分析）   |
| **拷贝消除**    | 无                 | 有                   |

---

### 题目 33：MemRef 的动态维度和静态维度如何共存？`memref<?x3xf64>` 在内存中如何表示？

**答案**：

**静态 vs 动态维度**：

```mlir
memref<2x3xf64>     // 全静态: 编译期已知大小
memref<?x3xf64>     // 部分动态: 第 0 维运行时确定
memref<?x?xf64>     // 全动态: 所有维度运行时确定
```

**`?` 的含义**：该维度的大小在编译期未知，需要在运行时传递。

**内存表示（下降到 LLVM 后）**：

MemRef 被转换为一个**描述符结构体**：

```llvm
// memref<?x3xf64> 的 LLVM 表示:
!llvm.struct<(
  ptr,        // 1. allocated pointer (分配的原始指针，用于 free)
  ptr,        // 2. aligned pointer  (对齐后的数据指针，用于访问)
  i64,        // 3. offset           (起始偏移量)
  array<2 x i64>,  // 4. sizes      [?, 3]  → 第 0 维运行时填入
  array<2 x i64>   // 5. strides    [3, 1]  → 第 0 维 stride=3
)>
```

**动态维度的处理**：

```mlir
// 创建时必须传入动态维度的大小
%n = arith.constant 5 : index
%mem = memref.alloc(%n) : memref<?x3xf64>
// → 分配 5*3*8 = 120 字节
// → sizes = [5, 3]
// → strides = [3, 1]

// 访问时索引照常使用
%v = memref.load %mem[%i, %j] : memref<?x3xf64>
// 地址计算: base + i * stride[0] + j * stride[1]
//         = base + i * 3 + j * 1
```

**函数签名中的动态维度**：

```mlir
func.func @process(%arg: memref<?x3xf64>) {
  // 函数不知道第 0 维的大小
  // 但可以在运行时查询:
  %dim0 = memref.dim %arg, %c0 : memref<?x3xf64>
  // 从描述符的 sizes[0] 字段读取
}
```

**静态维度的优势**：

```
静态维度:                    动态维度:
├─ 编译期计算地址偏移        ├─ 运行时计算地址偏移
├─ 编译期计算分配大小        ├─ 运行时计算分配大小
├─ 编译期验证越界            ├─ 需要运行时检查越界
├─ 更多优化机会              ├─ 较少优化机会
└─ stride 可以编译期内联     └─ stride 必须从描述符加载
```

---

### 题目 34：什么是 MemRef 的 Subview？它在循环平铺（Loop Tiling）中扮演什么角色？

**答案**：

**`memref.subview` 定义**：

从已有的 MemRef 中创建一个子视图，**不拷贝数据**，而是通过调整 offset、sizes、strides 来引用原始内存的一个子区域。

```mlir
%sub = memref.subview %mem[%off0, %off1][%size0, %size1][1, 1]
    : memref<100x200xf64> to memref<?x?xf64, strided<[200, 1], offset: ?>>
//  ^^^^^^^^^^^^^^^^^^^^     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
//  原始 memref              子视图类型（带 stride 和 offset 信息）
```

**内存布局**：

```
原始 memref<100x200xf64>:
┌────────────────────────────────────────┐
│ [0,0] [0,1] [0,2] ... [0,199]         │
│ [1,0] [1,1] [1,2] ... [1,199]         │
│ ...                                    │
│ [99,0]          ...    [99,199]        │
└────────────────────────────────────────┘

subview [10, 20][4, 8][1, 1]:
                ┌────────────────┐
                │ [10,20]...[10,27]│  ← 从 [10,20] 开始
                │ [11,20]...[11,27]│  ← 4 行 8 列
                │ [12,20]...[12,27]│
                │ [13,20]...[13,27]│
                └────────────────┘

子视图描述符:
  aligned_ptr = 原始 ptr
  offset = 10 * 200 + 20 = 2020
  sizes = [4, 8]
  strides = [200, 1]  // 与原始相同（因为 step=[1,1]）
```

**在循环平铺中的角色**：

```mlir
// 平铺前: 遍历整个 100x200 矩阵
affine.for %i = 0 to 100 {
  affine.for %j = 0 to 200 {
    // 访问 %A[%i, %j]
  }
}

// 平铺后: 外层遍历 tile，内层遍历 tile 内元素
affine.for %i0 = 0 to 100 step 4 {
  affine.for %j0 = 0 to 200 step 8 {
    // 创建当前 tile 的子视图
    %tile = memref.subview %A[%i0, %j0][4, 8][1, 1]
        : memref<100x200xf64> to memref<4x8xf64, ...>

    // 在 tile 内操作（可能被向量化或映射到硬件加速器）
    affine.for %i1 = 0 to 4 {
      affine.for %j1 = 0 to 8 {
        // 访问 %tile[%i1, %j1]
        // 对应原始 %A[%i0+%i1, %j0+%j1]
      }
    }
  }
}
```

**Subview 的价值**：

| 优势           | 说明                                    |
| -------------- | --------------------------------------- |
| **零拷贝**     | 不移动任何数据，只创建新的描述符        |
| **局部性优化** | Tile 大小可以匹配 cache line            |
| **硬件映射**   | Tile 可以直接映射到硬件加速器的本地存储 |
| **组合性**     | Subview 的 subview 仍然合法             |

---

### 题目 35：Affine 方言的 `affine.if` 有什么用？它和 `scf.if` 有什么本质区别？为什么 Affine 方言需要自己的条件分支？

**答案**：

**`affine.if` 定义**：

```mlir
// affine.if: 条件必须是仿射约束（IntegerSet）
#set = affine_set<(d0, d1) : (d0 - d1 >= 0, d1 - 5 >= 0)>
affine.if #set(%i, %j) {
  // 当 i >= j 且 j >= 5 时执行
} else {
  // 否则执行
}
```

**`scf.if` 定义**：

```mlir
// scf.if: 条件是任意 i1 类型的值
%cond = arith.cmpi sge, %i, %j : index
scf.if %cond {
  // 当条件为真时执行
} else {
  // 否则执行
}
```

**本质区别**：

| 方面         | `affine.if`                    | `scf.if`           |
| ------------ | ------------------------------ | ------------------ |
| **条件类型** | `IntegerSet`（仿射不等式集合） | `i1`（任意布尔值） |
| **可分析性** | 编译期可以推理条件永真/永假    | 运行时求值         |
| **用途**     | 边界检查、条件执行             | 通用条件分支       |
| **优化能力** | 可以被简化/消除                | 不可静态简化       |

**为什么 Affine 需要自己的 if？**

用途 1：**循环剥离（Loop Peeling）后的边界检查**

```mlir
// 向量化时，最后几个迭代可能不足一个向量宽度
affine.for %i = 0 to 100 step 4 {
  affine.if affine_set<(d0) : (d0 + 3 - 99 <= 0)>(%i) {
    // 完整的 4 元素向量操作
    // 编译期可证明: 当 i <= 96 时永真
  } else {
    // 标量尾部处理
  }
}
```

用途 2：**三角循环的条件**

```mlir
// 只处理上三角矩阵
affine.for %i = 0 to N {
  affine.for %j = 0 to N {
    affine.if affine_set<(d0, d1) : (d1 - d0 >= 0)>(%i, %j) {
      // 只在 j >= i 时执行
      // 编译期可以将此转换为:
      // affine.for %j = %i to N  (更高效)
    }
  }
}
```

**优化潜力**：

```
affine.if 可以被编译期:
├─ 证明永真 → 删除条件，保留 then 分支
├─ 证明永假 → 删除条件，保留 else 分支
├─ 合并到循环边界 → 消除 if，调整循环范围
└─ 用于依赖分析的精化 → 更精确的依赖信息

scf.if 无法做以上任何事（条件是运行时值）
```

---

# MLIR 面试题 · 第五部分：SCF / Linalg / Vector / Transform 专题

> 共 10 题，分初级（3 题）、中级（4 题）、高级（3 题）。

---

## 🟢 初级

### 题目 36：SCF（Structured Control Flow）方言中的 `scf.for`、`scf.while`、`scf.if` 分别表示什么？它们和 Affine 方言中的循环/条件有什么关系？

**答案**：

**SCF 方言的三个核心操作**：

| 操作        | 语义                     | 类比                                   |
| ----------- | ------------------------ | -------------------------------------- |
| `scf.for`   | 已知上下界的计数循环     | C 的 `for (i = lb; i < ub; i += step)` |
| `scf.while` | 条件循环（先判断后执行） | C 的 `while (cond) { ... }`            |
| `scf.if`    | 条件分支                 | C 的 `if (cond) { ... } else { ... }`  |

```mlir
// scf.for: 携带迭代参数（可以累加）
%sum = scf.for %i = %lb to %ub step %step
    iter_args(%acc = %init) -> f64 {
  %new_acc = arith.addf %acc, %val : f64
  scf.yield %new_acc : f64
}

// scf.while: 先判断，后执行
%result = scf.while (%arg = %init) : (i64) -> i64 {
  %cond = arith.cmpi slt, %arg, %limit : i64
  scf.condition(%cond) %arg : i64       // 条件 + 传值
} do {
^bb0(%arg: i64):
  %next = arith.addi %arg, %c1 : i64
  scf.yield %next : i64                 // 回传
}

// scf.if: 可以返回值
%val = scf.if %cond -> f64 {
  scf.yield %a : f64
} else {
  scf.yield %b : f64
}
```

**与 Affine 方言的关系**：

```
抽象层级:
  Affine 方言 (高层)
    │  更多约束 → 更多优化机会
    │  循环边界必须是仿射表达式
    │  条件必须是仿射整数集合
    │
    │  populateAffineToStdConversionPatterns()
    ↓
  SCF 方言 (中层)
    │  更少约束 → 更通用
    │  循环边界可以是任意 index 值
    │  条件可以是任意 i1 值
    │
    │  populateSCFToControlFlowConversionPatterns()
    ↓
  CF 方言 (低层)
       无结构化控制流 → 只有 br / cond_br
```

**核心区别**：Affine 的循环/条件是**可分析的**（支持依赖分析、自动并行化），SCF 的是**通用的**（支持任意表达式但不可做多面体分析）。Affine 在下降过程中先转换为 SCF，再转换为 CF。

---

### 题目 37：Linalg 方言的核心设计思想是什么？`linalg.generic` 操作表达了什么？

**答案**：

**核心设计思想——将计算与迭代分离**：

Linalg 把一个张量计算分解为三个正交的组件：

| 组件             | 含义                 | 表示方式                                 |
| ---------------- | -------------------- | ---------------------------------------- |
| **迭代域**       | 循环遍历的空间       | `iterator_types`（parallel / reduction） |
| **数据访问模式** | 每个操作数如何被访问 | `indexing_maps`（AffineMap）             |
| **标量计算**     | 每个元素做什么运算   | `body`（Region 内的标量操作）            |

**`linalg.generic` 示例——矩阵乘法**：

```mlir
// C[i,j] += A[i,k] * B[k,j]
#map_a = affine_map<(i, j, k) -> (i, k)>   // A 的访问: A[i,k]
#map_b = affine_map<(i, j, k) -> (k, j)>   // B 的访问: B[k,j]
#map_c = affine_map<(i, j, k) -> (i, j)>   // C 的访问: C[i,j]

linalg.generic {
  indexing_maps = [#map_a, #map_b, #map_c],
  iterator_types = ["parallel", "parallel", "reduction"]
  //                 i: 并行     j: 并行      k: 归约
} ins(%A, %B : tensor<4x8xf64>, tensor<8x6xf64>)
  outs(%C : tensor<4x6xf64>) {
  ^bb0(%a: f64, %b: f64, %c: f64):
    %prod = arith.mulf %a, %b : f64      // 标量计算
    %sum = arith.addf %c, %prod : f64
    linalg.yield %sum : f64
} -> tensor<4x6xf64>
```

**这种分离的好处**：

```
                  linalg.generic
                 ┌──────────────┐
                 │ indexing_maps │──→ 决定 Tiling 策略
                 │ iterator_types│──→ 决定并行化方向
                 │ body (Region) │──→ 决定向量化/融合方式
                 └──────────────┘
                        │
         ┌──────────────┼──────────────┐
         ↓              ↓              ↓
   Tile to loops   Vectorize     Fuse with
   (→ scf.for)    (→ vector)    neighbor ops
```

编译器可以针对每个组件独立做变换决策，而不需要反向分析循环结构。

---

### 题目 38：Vector 方言的作用是什么？`vector.transfer_read` / `vector.transfer_write` 为什么比 `memref.load` / `memref.store` 更适合向量化？

**答案**：

**Vector 方言的作用**：

在 MLIR 中显式表达**SIMD / 向量级操作**，是从标量循环到硬件 SIMD 指令之间的中间抽象。

```
抽象层级:
  linalg.generic (高层: 张量计算语义)
      ↓ 向量化
  vector 方言 (中层: 显式向量操作)
      ↓ 下降
  llvm.intr.* (低层: 硬件 SIMD 指令, 如 AVX/NEON)
```

**`vector.transfer_read/write` vs `memref.load/store`**：

| 方面         | `memref.load/store` | `vector.transfer_read/write`     |
| ------------ | ------------------- | -------------------------------- |
| **粒度**     | 单个标量元素        | 一次读/写整个向量                |
| **越界处理** | 无（越界是 UB）     | 内置 padding（安全处理边界）     |
| **置换**     | 无                  | 支持 permutation_map（读时转置） |
| **掩码**     | 无                  | 支持 mask（条件读写）            |

**示例对比**：

```mlir
// 标量方式: 需要循环 + 逐元素加载
scf.for %i = 0 to 8 {
  %v = memref.load %A[%i] : memref<10xf64>
  // ... 处理 %v
}

// 向量方式: 一次读取 8 个元素
%vec = vector.transfer_read %A[%c0], %pad
    : memref<10xf64>, vector<8xf64>
// %vec = <A[0], A[1], A[2], ..., A[7]>
// 如果数组只有 10 个元素但要读 16 个:
// 超出部分自动填充 %pad 值（不会越界访问！）
```

**越界安全——关键优势**：

```mlir
// 数组大小 = 10，向量宽度 = 8
// 从索引 6 开始读 8 个元素: 需要 A[6]..A[13]
// 但 A 只有 A[0]..A[9]!

%vec = vector.transfer_read %A[%c6], %zero
    : memref<10xf64>, vector<8xf64>
// 结果: <A[6], A[7], A[8], A[9], 0.0, 0.0, 0.0, 0.0>
//                                ^^^^^^^^^^^^^^^^^^
//                           越界部分自动填充 zero
```

这使得向量化不需要单独处理尾部迭代（loop tail），大大简化了代码生成。

---

## 🟡 中级

### 题目 39：`scf.for` 的 `iter_args`（迭代参数）机制是如何工作的？为什么 SCF 方言要设计这个特性而不是直接读写变量？

**答案**：

**`iter_args` 机制**：

`scf.for` 可以携带在迭代间传递的值，每次迭代的输出作为下一次迭代的输入。

```mlir
// 计算 sum = 0 + 1 + 2 + ... + 9
%sum = scf.for %i = %c0 to %c10 step %c1
    iter_args(%acc = %c0_f64) -> (f64) {
  //         ^^^^   ^^^^^^^^
  //    迭代参数    初始值
  %i_f64 = arith.sitofp %i : index to f64
  %new_acc = arith.addf %acc, %i_f64 : f64
  scf.yield %new_acc : f64
  //        ^^^^^^^^
  //    传给下一次迭代的 %acc
} // %sum = 最后一次迭代的 yield 值
```

**执行流程**：

```
iter 0: %acc = 0.0  → %new_acc = 0.0 + 0.0 = 0.0  → yield 0.0
iter 1: %acc = 0.0  → %new_acc = 0.0 + 1.0 = 1.0  → yield 1.0
iter 2: %acc = 1.0  → %new_acc = 1.0 + 2.0 = 3.0  → yield 3.0
...
iter 9: %acc = 36.0 → %new_acc = 36.0 + 9.0 = 45.0 → yield 45.0
%sum = 45.0
```

**为什么不直接读写变量（如用 memref.store）？**

原因 1：**保持 SSA 形式**

```
MLIR 的核心设计: 每个值只被定义一次 (SSA)

❌ 非 SSA (命令式):          ✅ SSA (iter_args):
  %acc = 0.0                  %sum = scf.for ...
  for i in range(10):             iter_args(%acc = 0.0) {
    %acc = %acc + i             %new = addf %acc, ...
                                scf.yield %new
  // %acc 被多次赋值!          }
  // 违反 SSA                  // 每个 %acc 只定义一次
```

原因 2：**可优化性**

```
iter_args 的数据流是显式的:
├─ 编译器精确知道哪些值跨迭代传递
├─ 可以做归约识别 (reduction detection)
├─ 可以做循环不变量外提 (LICM)
└─ 可以做循环向量化 (将 iter_args 转为向量归约)

memref.store 的数据流是隐式的:
├─ 需要别名分析才能确定依赖
├─ 编译器很难证明 store/load 的关系
└─ 向量化/并行化困难
```

原因 3：**函数式语义与 Tensor 兼容**

```mlir
// iter_args 可以传递 tensor（值语义）
%result = scf.for %i = ... iter_args(%t = %init_tensor) -> tensor<4xf64> {
  %new_t = tensor.insert %val into %t[%i] : tensor<4xf64>
  scf.yield %new_t : tensor<4xf64>
}
// 完美保持值语义, bufferization 可以优化为原地操作
```

---

### 题目 40：Linalg 方言中 `iterator_types` 的 `"parallel"` 和 `"reduction"` 分别意味着什么？它们如何影响 Tiling 和并行化？

**答案**：

**定义**：

| 类型          | 含义                       | 数学语义           |
| ------------- | -------------------------- | ------------------ |
| `"parallel"`  | 各迭代独立，可任意并行执行 | 映射 (map)         |
| `"reduction"` | 迭代间有累积依赖，需要归约 | 折叠 (fold/reduce) |

**示例——矩阵乘法 C[i,j] += A[i,k] * B[k,j]**：

```mlir
linalg.generic {
  iterator_types = ["parallel", "parallel", "reduction"]
  //                 i           j           k
} ...
```

- `i` (parallel): 不同行可以独立计算
- `j` (parallel): 不同列可以独立计算
- `k` (reduction): 同一个 C[i,j] 的累加必须串行（或用归约树）

**对 Tiling 的影响**：

```
Parallel 维度的 Tiling:
  可以生成独立的子任务，直接并行

  原始: for i = 0 to M (parallel)
  Tiled: for i0 = 0 to M step tile_size  (外层: 分发到线程)
           for i1 = 0 to tile_size       (内层: 线程内执行)

Reduction 维度的 Tiling:
  需要局部归约 + 最终合并

  原始: for k = 0 to K (reduction): C[i,j] += A[i,k]*B[k,j]
  Tiled: for k0 = 0 to K step tile_size:
           local_sum = 0
           for k1 = 0 to tile_size:         // 局部归约
             local_sum += A[i, k0+k1] * B[k0+k1, j]
           C[i,j] += local_sum              // 合并到全局
```

**对并行化的影响**：

```
GPU 映射示例:
  iterator_types = ["parallel", "parallel", "reduction"]
                       ↓            ↓            ↓
                   blockIdx.y   blockIdx.x    串行循环
                   (网格 Y)     (网格 X)     (线程内)

  或者更细粒度:
                   blockIdx.y   threadIdx.x   归约树
                                             (shared memory)
```

**向量化的影响**：

```mlir
// parallel 维度: 直接向量化
for j = 0 to N step 8:  // parallel
  %vec_a = vector.broadcast %a : f64 to vector<8xf64>
  %vec_b = vector.transfer_read %B[k, j] : vector<8xf64>
  %vec_c = vector.fma %vec_a, %vec_b, %vec_c  // 8 路并行

// reduction 维度: 需要水平归约
// 8 路并行乘法后, 需要 vector.reduction "add" 汇总
```

---

### 题目 41：Vector 方言中的 `vector.multi_reduction` 和 `vector.contract` 分别用于什么场景？它们与硬件指令的关系是什么？

**答案**：

**`vector.multi_reduction`——通用多维归约**：

```mlir
// 沿指定维度做归约
// 输入: vector<4x8xf64>  →  沿 dim=1 归约  →  输出: vector<4xf64>
%result = vector.multi_reduction <add>, %input, %acc [1]
    : vector<4x8xf64> to vector<4xf64>

// 语义: result[i] = acc[i] + Σ(j=0..7) input[i][j]
```

使用场景：
- 行求和 / 列求和
- 池化操作 (Pooling)
- Softmax 中的 max / sum

**`vector.contract`——收缩/矩阵乘法**：

```mlir
// 等价于 C[i,j] += A[i,k] * B[k,j]
#map_a = affine_map<(i, j, k) -> (i, k)>
#map_b = affine_map<(i, j, k) -> (k, j)>
#map_c = affine_map<(i, j, k) -> (i, j)>

%result = vector.contract {
  indexing_maps = [#map_a, #map_b, #map_c],
  iterator_types = ["parallel", "parallel", "reduction"]
} %A, %B, %C : vector<4x8xf64>, vector<8x6xf64> into vector<4x6xf64>
```

使用场景：
- 矩阵乘法 (GEMM)
- 卷积的核心计算
- 注意力机制中的 QK^T

**与硬件指令的映射**：

| Vector 操作             | x86 (AVX-512)       | ARM (NEON/SVE) | GPU (Tensor Cores)       |
| ----------------------- | ------------------- | -------------- | ------------------------ |
| `multi_reduction <add>` | `vaddps` + 水平归约 | `faddp`        | warp shuffle reduce      |
| `contract` (小矩阵)     | `vfmadd231ps` 序列  | `fmla` 序列    | `wmma::mma_sync`         |
| `contract` (大矩阵)     | Tiled FMA           | Tiled FMA      | `mma.sync` (Tensor Core) |

**下降路径**：

```
vector.contract
    │
    ├─→ 小尺寸: 展开为 vector.fma + vector.reduction
    │     └─→ llvm.intr.fma (单条 FMA 指令)
    │
    └─→ 匹配硬件加速器: 直接映射
          ├─→ gpu.mma (NVIDIA Tensor Core)
          ├─→ amx.tile_dpbssd (Intel AMX)
          └─→ sme.outerproduct (ARM SME)
```

---

### 题目 42：Transform 方言的设计动机是什么？它与传统的 Pass 管线有什么本质不同？

**答案**：

**传统 Pass 管线的问题**：

```bash
# 传统方式: 编译选项控制优化
mlir-opt input.mlir \
  --linalg-tile="tile-sizes=4,4" \
  --linalg-vectorize \
  --loop-unroll="factor=2"

# 问题:
# 1. 优化策略是"全局的"——对所有操作生效，无法针对性优化
# 2. 组合爆炸——pass 之间的交互不可预测
# 3. 无法表达"先 tile op A，再 fuse op B 到 A 的循环中"
# 4. 调试困难——不知道哪个 pass 导致了性能退化
```

**Transform 方言的设计动机——"编译器即程序"**：

Transform 方言将**编译策略本身表达为 MLIR 操作**，使优化过程可编程、可调试、可组合。

```mlir
// Transform 脚本: 精确控制优化步骤
transform.sequence failures(propagate) {
^bb0(%module: !transform.any_op):
  // 1. 找到目标操作
  %matmul = transform.structured.match ops{["linalg.matmul"]}
      in %module : (!transform.any_op) -> !transform.any_op

  // 2. 对这个特定的 matmul 做 tiling
  %tiled, %loops:3 = transform.structured.tile_using_for %matmul
      tile_sizes [64, 64, 8]
      : (!transform.any_op) -> (!transform.any_op, !transform.any_op,
                                 !transform.any_op, !transform.any_op)

  // 3. 对 tiled 后的内层做向量化
  transform.structured.vectorize %tiled
      : (!transform.any_op) -> ()

  // 4. 展开向量操作到硬件 intrinsics
  %func = transform.structured.match ops{["func.func"]}
      in %module : (!transform.any_op) -> !transform.any_op
  transform.apply_patterns to %func {
    transform.apply_patterns.vector.lower_contraction
  } : !transform.any_op
}
```

**与传统 Pass 的本质区别**：

| 方面         | 传统 Pass 管线        | Transform 方言                    |
| ------------ | --------------------- | --------------------------------- |
| **目标粒度** | 全局（对所有操作）    | 精确到单个操作                    |
| **表达方式** | 命令行选项 / C++ 代码 | MLIR IR（可序列化、可分析）       |
| **组合方式** | 线性管线（A → B → C） | 任意组合（可嵌套、可条件执行）    |
| **可调试性** | 只能看 Pass 前后的 IR | Transform 脚本本身可以 dump/验证  |
| **可搜索性** | 手动尝试参数组合      | 可以用自动调优搜索 Transform 脚本 |
| **可复现性** | 依赖编译选项          | 脚本即文档，完全可复现            |

**核心理念**：

```
传统方式: 优化策略硬编码在 C++ Pass 中
           程序员写 Pass → 编译器执行 Pass

Transform: 优化策略用 IR 表达
           程序员写 Transform 脚本 → 编译器解释执行脚本
           (脚本本身也可以被优化/搜索!)
```

---

## 🔴 高级

### 题目 43：描述 `linalg.generic` → `scf.for` → `vector` 的完整 Tiling + Vectorization 流程。每一步发生了什么类型变换？

**答案**：

**完整变换链**：

```
linalg.generic (tensor 语义)
    ↓ ① Tile
linalg.generic (更小的 tile, 仍是 tensor)
  + scf.for (外层 tile 循环)
    ↓ ② Vectorize
vector 操作 (显式向量类型)
  + scf.for (外层 tile 循环)
    ↓ ③ Bufferize
vector 操作 + memref (引用语义)
  + scf.for
    ↓ ④ Lower vector ops
llvm 向量 intrinsics + scf.for
    ↓ ⑤ Lower scf to cf
llvm (完全低层)
```

**具体示例——矩阵加法 C = A + B**：

**原始 IR**：

```mlir
// linalg.generic: 高层张量计算
%C = linalg.generic {
  indexing_maps = [affine_map<(i,j)->(i,j)>,
                   affine_map<(i,j)->(i,j)>,
                   affine_map<(i,j)->(i,j)>],
  iterator_types = ["parallel", "parallel"]
} ins(%A, %B : tensor<128x256xf64>)
  outs(%C_init : tensor<128x256xf64>) {
  ^bb0(%a: f64, %b: f64, %c: f64):
    %sum = arith.addf %a, %b : f64
    linalg.yield %sum : f64
} -> tensor<128x256xf64>
```

**① Tile（tile_sizes = [32, 64]）**：

```mlir
// 外层: scf.for 遍历 tiles
// 内层: linalg.generic 处理单个 tile
scf.for %i = 0 to 128 step 32 {
  scf.for %j = 0 to 256 step 64 {
    %tile_a = tensor.extract_slice %A[%i,%j][32,64][1,1]
    %tile_b = tensor.extract_slice %B[%i,%j][32,64][1,1]
    %tile_c = tensor.extract_slice %C_init[%i,%j][32,64][1,1]

    %result_tile = linalg.generic { ... }
        ins(%tile_a, %tile_b : tensor<32x64xf64>)
        outs(%tile_c : tensor<32x64xf64>) { ... }

    tensor.insert_slice %result_tile into %C_init[%i,%j][32,64][1,1]
  }
}
```

**类型变化**：tensor<128x256> → tensor<32x64>（更小的 tile）

**② Vectorize**：

```mlir
scf.for %i = 0 to 128 step 32 {
  scf.for %j = 0 to 256 step 64 {
    // linalg.generic 被替换为向量操作
    %va = vector.transfer_read %A_slice[...] : vector<32x64xf64>
    %vb = vector.transfer_read %B_slice[...] : vector<32x64xf64>
    %vc = arith.addf %va, %vb : vector<32x64xf64>
    vector.transfer_write %vc, %C_slice[...]
  }
}
```

**类型变化**：tensor<32x64> → vector<32x64>（显式向量类型）

**③ + ④ + ⑤ Lower**：

```mlir
// vector<32x64xf64> 可能被进一步分解为多个硬件向量
// vector<32x64xf64> → 128 个 vector<16xf64> (假设 AVX-512)
// 最终生成:
//   %v = llvm.intr.x86.avx512.add.pd.512(%va, %vb)
```

**每步的类型变换总结**：

| 步骤            | 操作       | 输入类型            | 输出类型                    |
| --------------- | ---------- | ------------------- | --------------------------- |
| ① Tile          | 拆分迭代域 | `tensor<128x256>`   | `tensor<32x64>` + `scf.for` |
| ② Vectorize     | 标量→向量  | `tensor<32x64>`     | `vector<32x64>`             |
| ③ Bufferize     | 值→引用    | `tensor` → `memref` | `memref` + `vector`         |
| ④ Lower vector  | 拆分大向量 | `vector<32x64>`     | 多个 `vector<16>`           |
| ⑤ Lower to LLVM | 到硬件指令 | `vector<16>`        | `llvm.intr.*`               |

---

### 题目 44：在 Linalg 中，Fusion（融合）有哪些类型？Producer-Consumer Fusion 和 Tiling + Fusion 的区别是什么？

**答案**：

**Linalg Fusion 的类型**：

| 融合类型                     | 含义                                         | 效果         |
| ---------------------------- | -------------------------------------------- | ------------ |
| **Producer-Consumer Fusion** | 将生产者的计算内联到消费者中                 | 消除中间张量 |
| **Tiling + Fusion**          | 先 tile 消费者，再将生产者融合到 tile 循环中 | 提升局部性   |
| **Element-wise Fusion**      | 多个逐元素操作合并为一个                     | 减少循环开销 |

**Producer-Consumer Fusion**：

```mlir
// 融合前: 两个独立的 linalg 操作
%B = linalg.generic { /*relu*/ } ins(%A) outs(%B_init) { ... }
%C = linalg.generic { /*add*/  } ins(%B, %X) outs(%C_init) { ... }
// 中间张量 %B 完整地物化到内存中

// 融合后: 生产者内联到消费者
%C = linalg.generic {
  // 合并后的 body
} ins(%A, %X) outs(%C_init) {
  ^bb0(%a: f64, %x: f64, %c: f64):
    %relu = arith.maximumf %a, %zero : f64   // relu (原生产者)
    %sum = arith.addf %relu, %x : f64        // add  (原消费者)
    linalg.yield %sum : f64
}
// %B 完全消除, 无需额外内存!
```

**Tiling + Fusion**：

```mlir
// 场景: matmul 后接 relu
%B = linalg.matmul ins(%A, %W) outs(%B_init) : ...  // 大矩阵乘法
%C = linalg.generic {/*relu*/} ins(%B) outs(%C_init) // relu

// 直接 Producer-Consumer Fusion 不可行:
//   matmul 不是逐元素操作, 不能简单内联

// Tiling + Fusion 策略:
// 1. 先 tile relu (消费者)
scf.for %i = 0 to M step 32 {
  scf.for %j = 0 to N step 32 {
    %b_tile = tensor.extract_slice %B[%i,%j][32,32][1,1]
    %c_tile = linalg.generic {/*relu*/} ins(%b_tile) ...
  }
}

// 2. 将 matmul (生产者) 融合到 tile 循环内
scf.for %i = 0 to M step 32 {
  scf.for %j = 0 to N step 32 {
    // matmul 只计算需要的 32x32 tile
    %a_slice = tensor.extract_slice %A[%i,0][32,K][1,1]
    %w_slice = tensor.extract_slice %W[0,%j][K,32][1,1]
    %b_tile = linalg.matmul ins(%a_slice, %w_slice) ...

    // relu 立即消费 b_tile (还在 cache 中!)
    %c_tile = linalg.generic {/*relu*/} ins(%b_tile) ...
  }
}
```

**核心区别**：

| 方面           | Producer-Consumer                                   | Tiling + Fusion                    |
| -------------- | --------------------------------------------------- | ---------------------------------- |
| **适用条件**   | 两个操作的迭代域兼容（通常都是逐元素）              | 任意操作组合                       |
| **融合效果**   | 完全消除中间张量                                    | 中间张量缩小为 tile 大小           |
| **局部性提升** | 寄存器级（值不落地）                                | Cache 级（tile 在 L1/L2 中）       |
| **复杂度**     | 简单（合并 body）                                   | 复杂（需要计算生产者的 tile 依赖） |
| **典型场景**   | relu(add(x,y))、sigmoid(matmul(...)) 中的逐元素部分 | matmul + bias + relu 全链          |

---

### 题目 45：如何用 Transform 方言编写一个完整的 GEMM 优化策略？请描述关键步骤和设计考量。

**答案**：

**目标**：优化 `linalg.matmul`（C = A × B），生成高效的 Tiled + Vectorized 代码。

**Transform 脚本**：

```mlir
transform.sequence failures(propagate) {
^bb0(%module: !transform.any_op):

  // ===== Step 1: 定位目标操作 =====
  %matmul = transform.structured.match ops{["linalg.matmul"]}
      in %module : (!transform.any_op) -> !transform.any_op

  // ===== Step 2: 多级 Tiling =====
  // L2 Cache Tile: 128x128x64
  %tiled_l2, %loop_i, %loop_j, %loop_k =
      transform.structured.tile_using_for %matmul
      tile_sizes [128, 128, 64]
      : (!transform.any_op) -> (!transform.any_op, !transform.any_op,
                                 !transform.any_op, !transform.any_op)

  // L1 Cache Tile: 32x32x16
  %tiled_l1, %l1_i, %l1_j, %l1_k =
      transform.structured.tile_using_for %tiled_l2
      tile_sizes [32, 32, 16]
      : (!transform.any_op) -> (!transform.any_op, !transform.any_op,
                                 !transform.any_op, !transform.any_op)

  // Register Tile: 8x8x1 (匹配向量寄存器)
  %tiled_reg, %r_i, %r_j, %r_k =
      transform.structured.tile_using_for %tiled_l1
      tile_sizes [8, 8, 1]
      : (!transform.any_op) -> (!transform.any_op, !transform.any_op,
                                 !transform.any_op, !transform.any_op)

  // ===== Step 3: 向量化最内层 tile =====
  transform.structured.vectorize %tiled_reg
      : (!transform.any_op) -> ()

  // ===== Step 4: 应用向量优化 patterns =====
  %func = transform.structured.match ops{["func.func"]}
      in %module : (!transform.any_op) -> !transform.any_op

  transform.apply_patterns to %func {
    // 将 vector.contract 展开为 FMA
    transform.apply_patterns.vector.lower_contraction
        lowering_strategy = "outerproduct"
    // 将 vector.transfer 展开为非掩码操作
    transform.apply_patterns.vector.transfer_permutation_patterns
  } : !transform.any_op

  // ===== Step 5: Bufferize =====
  transform.bufferization.one_shot_bufferize %module
      : (!transform.any_op) -> ()

  // ===== Step 6: 后续低层优化 =====
  transform.apply_patterns to %func {
    transform.apply_patterns.vector.lower_shape_cast
    transform.apply_patterns.vector.lower_transpose
  } : !transform.any_op
}
```

**设计考量**：

| 决策               | 考量因素                        | 典型选择                                             |
| ------------------ | ------------------------------- | ---------------------------------------------------- |
| **L2 Tile 大小**   | L2 Cache 容量（通常 256KB-1MB） | 128×128 (f64) ≈ 128KB                                |
| **L1 Tile 大小**   | L1 Cache 容量（通常 32-64KB）   | 32×32 (f64) ≈ 8KB                                    |
| **Register Tile**  | 向量寄存器数量和宽度            | 8×8 (AVX-512 有 32 个 zmm 寄存器)                    |
| **Reduction tile** | 避免过长的依赖链                | K=16 (平衡 ILP 和 cache)                             |
| **向量化策略**     | 目标硬件的 FMA 形式             | outerproduct (适合 x86)，innerproduct (适合某些 GPU) |
| **Tiling 顺序**    | 数据重用模式                    | i→j→k (A 重用) 或 j→i→k (B 重用)                     |

**生成的循环结构**：

```
for i0 = 0 to M step 128:           // L2 tile (i)
  for j0 = 0 to N step 128:         // L2 tile (j)
    for k0 = 0 to K step 64:        // L2 tile (k)
      for i1 = 0 to 128 step 32:    // L1 tile (i)
        for j1 = 0 to 128 step 32:  // L1 tile (j)
          for k1 = 0 to 64 step 16: // L1 tile (k)
            // 寄存器级: 8x8x1
            // → 被向量化为 vector.contract
            // → 展开为 FMA 指令序列
```

**关键洞察**：Transform 脚本不是固定的——可以根据目标硬件参数化 tile 大小，用自动调优（Auto-tuning）搜索最优配置，然后将最优脚本保存为可复现的编译策略。

---

## 参考资料

- MLIR 官方文档：https://mlir.llvm.org/docs/Tutorials/Toy/
- Affine 方言文档：https://mlir.llvm.org/docs/Dialects/Affine/
- MemRef 方言文档：https://mlir.llvm.org/docs/Dialects/MemRef/
- Linalg 方言文档：https://mlir.llvm.org/docs/Dialects/Linalg/
- SCF 方言文档：https://mlir.llvm.org/docs/Dialects/SCF/
- Vector 方言文档：https://mlir.llvm.org/docs/Dialects/Vector/
- Transform 方言文档：https://mlir.llvm.org/docs/Dialects/Transform/
- 源代码路径：`mlir/examples/toy/Ch1` ~ `Ch7`
- 测试用例路径：`mlir/test/Examples/Toy/Ch1` ~ `Ch7`
