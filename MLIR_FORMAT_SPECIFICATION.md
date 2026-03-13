# MLIR 操作格式设置指南 - Toy Dialect 中的 AddOp 例子

## 问题
toy.add 操作的 MLIR 表示格式：`%2 = toy.add %0, %1 : tensor<2x3xf64>` 是在哪里设置的？

## 答案总览

MLIR 操作的打印格式由两部分决定：

1. **Ops.td 中的格式声明** - 定义如何解析和打印操作
2. **Dialect.cpp 中的实现** - 提供具体的 parser 和 printer 方法

---

## 详细流程

### 第一层：Ops.td 中的格式声明

**文件位置**：[mlir/examples/toy/Ch2/include/toy/Ops.td](mlir/examples/toy/Ch2/include/toy/Ops.td)

#### AddOp 的定义

```tablegen
def AddOp : Toy_Op<"add"> {
  let summary = "element-wise addition operation";
  let description = [{
    The "add" operation performs element-wise addition between two tensors.
    The shapes of the tensor operands are expected to match.
  }];

  let arguments = (ins F64Tensor:$lhs, F64Tensor:$rhs);
  let results = (outs F64Tensor);

  // ⚠️ 关键：指示编译器这个操作有自定义格式
  let hasCustomAssemblyFormat = 1;

  // Allow building an AddOp with from the two input operands.
  let builders = [
    OpBuilder<(ins "Value":$lhs, "Value":$rhs)>
  ];
}
```

关键字段解析：
- `arguments = (ins F64Tensor:$lhs, F64Tensor:$rhs)` - 定义操作有两个 F64Tensor 类型的操作数
- `results = (outs F64Tensor)` - 定义操作产生一个 F64Tensor 结果
- **`let hasCustomAssemblyFormat = 1`** - 标志该操作需要自定义的 parser 和 printer

### 第二层：Dialect.cpp 中的实现

**文件位置**：[mlir/examples/toy/Ch2/mlir/Dialect.cpp](mlir/examples/toy/Ch2/mlir/Dialect.cpp)

#### 关键函数

从 `printBinaryOp` 开始，这是一个通用的二元操作打印函数：

```cpp
/// A generalized printer for binary operations. It prints in two different
/// forms depending on if all of the types match.
static void printBinaryOp(mlir::OpAsmPrinter &printer, mlir::Operation *op) {
  // 第一步：打印操作数列表
  printer << " " << op->getOperands();
  
  // 第二步：打印可选属性字典
  printer.printOptionalAttrDict(op->getAttrs());
  
  // 第三步：打印冒号和类型
  printer << " : ";

  // 第四步：判断如何打印类型
  Type resultType = *op->result_type_begin();
  if (llvm::all_of(op->getOperandTypes(),
                   [=](Type type) { return type == resultType; })) {
    // 如果所有操作数和结果的类型相同，直接打印该类型
    printer << resultType;
    return;
  }

  // 否则打印函数类型（输入类型 → 结果类型）
  printer.printFunctionalType(op->getOperandTypes(), op->getResultTypes());
}
```

#### AddOp 的 Parser 和 Printer

```cpp
//===----------------------------------------------------------------------===//
// AddOp
//===----------------------------------------------------------------------===//

void AddOp::build(mlir::OpBuilder &builder, mlir::OperationState &state,
                  mlir::Value lhs, mlir::Value rhs) {
  // 创建无秩张量作为结果类型
  state.addTypes(UnrankedTensorType::get(builder.getF64Type()));
  state.addOperands({lhs, rhs});
}

// Parser：将 MLIR 文本转换为内部表示
mlir::ParseResult AddOp::parse(mlir::OpAsmParser &parser,
                               mlir::OperationState &result) {
  // 使用通用二元操作解析器
  return parseBinaryOp(parser, result);
}

// Printer：将内部表示转换为 MLIR 文本
void AddOp::print(mlir::OpAsmPrinter &p) { printBinaryOp(p, *this); }
```

---

## 打印流程详解

### 完整的输出过程

当 AddOp 被打印时，例如 `%2 = toy.add %0, %1 : tensor<2x3xf64>`：

```
AddOp 操作对象
    ↓
调用 AddOp::print()
    ↓
调用 printBinaryOp() 函数
    ↓
步骤1：printer << " " << op->getOperands()
       输出：" %0 %1"
    ↓
步骤2：printer.printOptionalAttrDict(op->getAttrs())
       输出：（如果有属性则打印，通常为空）
    ↓
步骤3：printer << " : "
       输出：" : "
    ↓
步骤4a：检查所有操作数和结果类型是否相同
        ↓ 如果相同
        printer << resultType
        输出：" tensor<2x3xf64>"
        ↓ 如果不同
        printer.printFunctionalType(...)
        输出：" (tensor<Ax...>, tensor<Bx...>) -> tensor<Cx...>"
```

### 完整输出结果

```mlir
toy.add %0 %1 : tensor<2x3xf64>
```

但由于 MLIR 的上层格式，实际显示时会加入结果值和赋值：
```mlir
%2 = toy.add %0, %1 : tensor<2x3xf64>
```

---

## 与其他操作的格式对比

### 对比表格

| 操作              | Ops.td 格式声明               | Printer 实现      | 输出格式                             |
| ----------------- | ----------------------------- | ----------------- | ------------------------------------ |
| **AddOp**         | `hasCustomAssemblyFormat = 1` | `printBinaryOp()` | `toy.add %0, %1 : type`              |
| **MulOp**         | `hasCustomAssemblyFormat = 1` | `printBinaryOp()` | `toy.mul %0, %1 : type`              |
| **ConstantOp**    | `hasCustomAssemblyFormat = 1` | 自定义 `print()`  | `toy.constant dense<...>`            |
| **PrintOp**       | `assemblyFormat = ...`        | 自动生成          | `toy.print %input : type`            |
| **ReshapeOp**     | `assemblyFormat = ...`        | 自动生成          | `toy.reshape (%in : type) to type`   |
| **GenericCallOp** | `assemblyFormat = ...`        | 自动生成          | `toy.generic_call @func(...) : type` |

---

## 两种格式声明方式

### 方式 1：`hasCustomAssemblyFormat = 1`（手动控制）

**在 Ops.td 中**：
```tablegen
def AddOp : Toy_Op<"add"> {
  ...
  let hasCustomAssemblyFormat = 1;
};
```

**在 Dialect.cpp 中**：
必须手动实现 `parse()` 和 `print()` 方法：
```cpp
mlir::ParseResult AddOp::parse(mlir::OpAsmParser &parser,
                               mlir::OperationState &result) {
  // 自定义解析逻辑
  return parseBinaryOp(parser, result);
}

void AddOp::print(mlir::OpAsmPrinter &p) {
  // 自定义打印逻辑
  printBinaryOp(p, *this);
}
```

#### 优点
- 完全控制格式
- 可以实现复杂的自定义格式

#### 缺点
- 需要手动编写 parser 和 printer
- 代码量较多

---

### 方式 2：`assemblyFormat`（声明式）

**在 Ops.td 中**：
```tablegen
def PrintOp : Toy_Op<"print"> {
  let arguments = (ins F64Tensor:$input);
  
  // 使用 assemblyFormat 自动生成 parser 和 printer
  let assemblyFormat = "$input attr-dict `:` type($input)";
}
```

输出格式：`toy.print %0 : tensor<2x3xf64>`

**又例如**：
```tablegen
def ReshapeOp : Toy_Op<"reshape"> {
  let arguments = (ins F64Tensor:$input);
  let results = (outs StaticShapeTensorOf<[F64]>);
  
  let assemblyFormat = [{
    `(` $input `:` type($input) `)` attr-dict `to` type(results)
  }];
}
```

输出格式：`toy.reshape (%0 : tensor<10xf64>) to tensor<5x2xf64>`

#### 优点
- 代码简洁
- MLIR 自动生成 parser 和 printer
- 易于维护

#### 缺点
- 格式灵活性受限
- 复杂场景需要使用 `hasCustomAssemblyFormat`

---

## PrintOp 的具体例子

### Ops.td 声明

```tablegen
def PrintOp : Toy_Op<"print"> {
  let summary = "print operation";
  let description = [{
    The "print" builtin operation prints a given input tensor, and produces
    no results.
  }];

  // PrintOp 只有一个输入
  let arguments = (ins F64Tensor:$input);

  // 使用 assemblyFormat 声明式格式
  // $input - 打印操作数
  // attr-dict - 打印属性字典
  // type($input) - 打印操作数的类型
  let assemblyFormat = "$input attr-dict `:` type($input)";
}
```

### 自动生成的效果

- **输入**：`toy.print %0 : tensor<2x3xf64>`
- **解析**：MLIR 自动生成的 parser 将其解析为 PrintOp
- **打印**：MLIR 自动生成的 printer 将其转换回相同的文本格式

---

## GenericCallOp 的例子

### Ops.td 声明

```tablegen
def GenericCallOp : Toy_Op<"generic_call"> {
  let arguments = (ins FlatSymbolRefAttr:$callee, Variadic<F64Tensor>:$inputs);
  let results = (outs F64Tensor);

  // 声明式格式
  // $callee - 符号引用（函数名）
  // $inputs - 可变参数列表
  // functional-type($inputs, results) - 输入和结果的函数类型
  let assemblyFormat = [{
    $callee `(` $inputs `)` attr-dict `:` functional-type($inputs, results)
  }];

  let builders = [
    OpBuilder<(ins "StringRef":$callee, "ArrayRef<Value>":$arguments)>
  ];
}
```

### 输出格式

```mlir
%4 = toy.generic_call @multiply_transpose(%1, %3) : (tensor<2x3xf64>, tensor<2x3xf64>) -> tensor<?xf64>
```

格式分解：
- `@multiply_transpose` - `$callee` 符号
- `(%1, %3)` - `$inputs` 参数列表
- `(tensor<2x3xf64>, tensor<2x3xf64>) -> tensor<?xf64>` - 函数类型

---

## ConstantOp 的自定义打印

### Ops.td 声明

```tablegen
def ConstantOp : Toy_Op<"constant", [Pure]> {
  let arguments = (ins F64ElementsAttr:$value);
  let results = (outs F64Tensor);
  
  let hasCustomAssemblyFormat = 1;
  
  let builders = [...];
  let hasVerifier = 1;
}
```

### Dialect.cpp 实现

```cpp
mlir::ParseResult ConstantOp::parse(mlir::OpAsmParser &parser,
                                    mlir::OperationState &result) {
  mlir::DenseElementsAttr value;
  if (parser.parseOptionalAttrDict(result.attributes) ||
      parser.parseAttribute(value, "value", result.attributes))
    return failure();

  result.addTypes(value.getType());
  return success();
}

void ConstantOp::print(mlir::OpAsmPrinter &printer) {
  printer << " ";
  printer.printOptionalAttrDict((*this)->getAttrs(), 
                                 /*elidedAttrs=*/{"value"});
  printer << getValue();
}
```

### 输出格式

```mlir
%0 = toy.constant dense<[[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]]> : tensor<2x3xf64>
```

---

## 打印工具函数参考

### 常用打印方法（OpAsmPrinter 类）

```cpp
// 打印操作数列表
printer << " " << op->getOperands()

// 打印可选属性字典（默认所有属性）
printer.printOptionalAttrDict(op->getAttrs())

// 打印属性字典但排除某些属性
printer.printOptionalAttrDict(op->getAttrs(), 
                               /*elidedAttrs=*/{"value", "name"})

// 打印属性
printer << op->getAttr("name")

// 打印类型
printer << resultType

// 打印函数类型（输入 → 输出）
printer.printFunctionalType(op->getOperandTypes(), 
                            op->getResultTypes())

// 获取结果类型
op->result_type_begin()
op->result_type_end()

// 获取操作数类型
op->getOperandTypes()
```

### 常用解析方法（OpAsmParser 类）

```cpp
// 解析操作数列表
parser.parseOperandList(operands, requiredCount)

// 解析可选属性字典
parser.parseOptionalAttrDict(result.attributes)

// 解析属性
parser.parseAttribute(attr, attrName, result.attributes)

// 解析类型
parser.parseColonType(type)

// 解析操作数列表到具体类型
parser.resolveOperands(operands, types, loc, result.operands)

// 获取当前位置
parser.getCurrentLocation()
```

---

## 总结流程图

```
用户编写 Toy 源代码
    ↓
MLIRGen 生成 MLIR 操作对象
    ↓
输出 MLIR 代码时调用操作的 print() 方法
    ↓
┌─────────────────────────────────────┐
│ 检查操作定义 (Ops.td)                 │
├─────────────────────────────────────┤
│ hasCustomAssemblyFormat = 1?          │
├─────────────────────────────────────┤
│   YES → 调用自定义 print() 方法       │
│   NO  → 使用 assemblyFormat 自动生成  │
└─────────────────────────────────────┘
    ↓
将操作转换为文本格式
    ↓
输出到文件或控制台

例如：%2 = toy.add %0, %1 : tensor<2x3xf64>
```

---

## 核心要点

1. **格式定义位置**：
   - `Ops.td` 中的 `hasCustomAssemblyFormat` 或 `assemblyFormat` 字段

2. **具体实现位置**：
   - `Dialect.cpp` 中的 `OpName::parse()` 和 `OpName::print()` 方法
   - 或由 MLIR 框架自动生成（使用 assemblyFormat）

3. **两种选择**：
   - **手动**：`hasCustomAssemblyFormat = 1` + 自定义 parser/printer
   - **自动**：`assemblyFormat = "..."` 声明式定义

4. **二元操作的通用模式**：
   - 使用 `printBinaryOp()` 和 `parseBinaryOp()` 函数
   - 所有二元操作（Add、Mul 等）共享同一个打印/解析逻辑

5. **输出格式结构**：
   ```
   toy.<mnemonic> <operands> [attributes] : <types>
   ```
   - 操作名由 `Toy_Op<"mnemonic">` 定义
   - 操作数由 `let arguments = ...` 定义
   - 类型由结果类型推导或显式指定
