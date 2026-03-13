# Toy 语言：从 AST 到 MLIR Dialect 的完整流程

## 概述

在 `mlir/examples/toy` 目录中，编译器通过以下阶段工作：

1. **Ch1：AST 定义** - 定义源语言的抽象语法树
2. **Ch2：Dialect 定义** - 定义 MLIR 中 Toy 语言的方言和操作
3. **MLIRGen：AST→MLIR 转换** - 将 AST 转换为 MLIR 中间表示

```
源代码 (toy 文件) 
  ↓
Lexer & Parser 
  ↓ 
AST (Ch1 定义)
  ↓
MLIRGen.cpp (AST 遍历)
  ↓
使用 OpBuilder 创建 MLIR 操作
  ↓
MLIR Module (Dialect IR)
```

---

## 第一步：Ch1 AST 定义

### 文件位置
- [mlir/examples/toy/Ch1/include/toy/AST.h](mlir/examples/toy/Ch1/include/toy/AST.h)

### AST 节点层次结构

```cpp
ExprAST (基类)
├── NumberExprAST          // 数字字面量：1.0
├── LiteralExprAST         // 数组字面量：[[1,2], [3,4]]
├── VariableExprAST        // 变量引用：a
├── VarDeclExprAST         // 变量声明：var a = ...
├── ReturnExprAST          // 返回语句：return x
├── BinaryExprAST          // 二元操作：a + b, a * b
├── CallExprAST            // 函数调用：transpose(x), foo(a)
└── PrintExprAST           // 打印语句：print(x)
```

### 关键数据结构

```cpp
// 变量类型包含形状信息
struct VarType {
  std::vector<int64_t> shape;
};

// 每个 AST 节点记录其源代码位置
class ExprAST {
private:
  Location location;  // 文件、行号、列号
  ExprASTKind kind;
};

// 模块是函数列表
class ModuleAST {
  std::vector<std::unique_ptr<FunctionAST>> functions;
};
```

---

## 第二步：Ch2 Dialect 定义

### 文件位置
- [mlir/examples/toy/Ch2/include/toy/Ops.td](mlir/examples/toy/Ch2/include/toy/Ops.td) - 操作定义（使用 TableGen）
- [mlir/examples/toy/Ch2/include/toy/Dialect.h](mlir/examples/toy/Ch2/include/toy/Dialect.h) - Dialect 声明
- [mlir/examples/toy/Ch2/mlir/Dialect.cpp](mlir/examples/toy/Ch2/mlir/Dialect.cpp) - Dialect 实现

### Dialect 注册（Ops.td）

Toy Dialect 定义了以下操作，使用 MLIR 的 TableGen 框架：

```tablegen
// Dialect 声明
def Toy_Dialect : Dialect {
  let name = "toy";
  let cppNamespace = "::mlir::toy";
}

// 操作基类
class Toy_Op<string mnemonic, list<Trait> traits = []> :
    Op<Toy_Dialect, mnemonic, traits>;
```

### 核心操作列表

#### 1. **ConstantOp** - 常数操作
```tablegen
def ConstantOp : Toy_Op<"constant", [Pure]> {
  let arguments = (ins F64ElementsAttr:$value);
  let results = (outs F64Tensor);
  
  // 生成的 C++ 代码可使用：
  // ConstantOp::create(builder, loc, value)
}
```

**MLIR 表示：**
```mlir
%0 = toy.constant dense<[[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]]>
                  : tensor<2x3xf64>
```

#### 2. **AddOp** - 元素级加法
```tablegen
def AddOp : Toy_Op<"add"> {
  let arguments = (ins F64Tensor:$lhs, F64Tensor:$rhs);
  let results = (outs F64Tensor);
}
```

**MLIR 表示：**
```mlir
%2 = toy.add %0, %1 : tensor<2x3xf64>
```

#### 3. **MulOp** - 元素级乘法
```tablegen
def MulOp : Toy_Op<"mul"> {
  let arguments = (ins F64Tensor:$lhs, F64Tensor:$rhs);
  let results = (outs F64Tensor);
}
```

#### 4. **TransposeOp** - 矩阵转置
```tablegen
def TransposeOp : Toy_Op<"transpose"> {
  let arguments = (ins F64Tensor:$operand);
  let results = (outs F64Tensor);
}
```

#### 5. **ReshapeOp** - 形状变换
```tablegen
def ReshapeOp : Toy_Op<"reshape"> {
  let arguments = (ins F64Tensor:$operand);
  let results = (outs F64Tensor);
}
```

#### 6. **FuncOp** - 函数操作
```tablegen
def FuncOp : Toy_Op<"func", [FunctionOpInterface, IsolatedFromAbove]> {
  let arguments = (ins
    SymbolNameAttr:$sym_name,
    TypeAttrOf<FunctionType>:$function_type
  );
  let regions = (region AnyRegion:$body);
}
```

**MLIR 表示：**
```mlir
toy.func @main() {
  %0 = toy.constant dense<5.5> : tensor<f64>
  toy.return %0 : tensor<f64>
}
```

#### 7. **ReturnOp** - 返回操作
```tablegen
def ReturnOp : Toy_Op<"return", [HasParent<"FuncOp">, NoSideEffect]> {
  let arguments = (ins Variadic<F64Tensor>:$operands);
}
```

#### 8. **PrintOp** - 打印操作
```tablegen
def PrintOp : Toy_Op<"print"> {
  let arguments = (ins F64Tensor:$input);
}
```

#### 9. **GenericCallOp** - 通用函数调用
```tablegen
def GenericCallOp : Toy_Op<"generic_call"> {
  let arguments = (ins
    FlatSymbolRefAttr:$callee,
    Variadic<F64Tensor>:$inputs
  );
  let results = (outs Variadic<F64Tensor>);
}
```

### 类型系统

Toy Dialect 中定义的类型：

```cpp
// F64Tensor - 64 位浮点数的张量（秩可变）
class F64Tensor<int rank = -1> : 
    TensorOf<[F64]>;

// F64ElementsAttr - 64 位浮点元素属性
def F64ElementsAttr : Attr<...>;
```

---

## 第三步：MLIRGen - AST 到 MLIR 的转换

### 文件位置
- [mlir/examples/toy/Ch2/include/toy/MLIRGen.h](mlir/examples/toy/Ch2/include/toy/MLIRGen.h) - 声明
- [mlir/examples/toy/Ch2/mlir/MLIRGen.cpp](mlir/examples/toy/Ch2/mlir/MLIRGen.cpp) - 实现

### MLIRGen 架构

#### 主要类：`MLIRGenImpl`

```cpp
class MLIRGenImpl {
private:
  mlir::OpBuilder builder;           // MLIR 操作构建器
  mlir::ModuleOp theModule;          // 顶级模块操作
  
  // 符号表：变量名 → MLIR Value
  llvm::ScopedHashTable<StringRef, mlir::Value> symbolTable;

public:
  mlir::ModuleOp mlirGen(ModuleAST &moduleAST);
};
```

### 转换流程详解

#### 1. **模块级转换**

```cpp
mlir::ModuleOp MLIRGenImpl::mlirGen(ModuleAST &moduleAST) {
  // 创建空的 MLIR 模块
  theModule = mlir::ModuleOp::create(builder.getUnknownLoc());
  
  // 逐个函数进行代码生成
  for (FunctionAST &f : moduleAST)
    mlirGen(f);
  
  // 验证模块
  if (failed(mlir::verify(theModule))) {
    theModule.emitError("module verification error");
    return nullptr;
  }
  
  return theModule;
}
```

**AST 节点** → **MLIR 操作**
- `ModuleAST` → `mlir::ModuleOp`

#### 2. **函数转换**

```cpp
mlir::toy::FuncOp MLIRGenImpl::mlirGen(FunctionAST &funcAST) {
  // 创建符号表作用域（函数级别）
  ScopedHashTableScope<StringRef, mlir::Value> varScope(symbolTable);
  
  // 创建 toy.func 操作
  mlir::toy::FuncOp function = mlirGen(*funcAST.getProto());
  
  // 获取函数的第一个块（入口块）
  mlir::Block &entryBlock = function.front();
  
  // 将函数参数添加到符号表
  for (const auto nameValue : llvm::zip(protoArgs, entryBlock.getArguments())) {
    declare(std::get<0>(nameValue)->getName(), 
            std::get<1>(nameValue));
  }
  
  // 设置插入点并生成函数体
  builder.setInsertionPointToStart(&entryBlock);
  mlirGen(*funcAST.getBody());
  
  // 确保有返回操作
  if (!hasReturnOp)
    ReturnOp::create(builder, loc, {});
  
  return function;
}
```

**AST 节点** → **MLIR 操作**
- `FunctionAST` → `toy.func`
- `PrototypeAST` → 函数签名

#### 3. **表达式转换**

使用访问者模式的分发机制：

```cpp
mlir::Value MLIRGenImpl::mlirGen(ExprAST &expr) {
  switch (expr.getKind()) {
    case Expr_BinOp:
      return mlirGen(cast<BinaryExprAST>(expr));
    case Expr_Var:
      return mlirGen(cast<VariableExprAST>(expr));
    case Expr_Literal:
      return mlirGen(cast<LiteralExprAST>(expr));
    case Expr_Call:
      return mlirGen(cast<CallExprAST>(expr));
    case Expr_Num:
      return mlirGen(cast<NumberExprAST>(expr));
    default:
      emitError(loc(expr.loc())) << "unhandled expr kind";
      return nullptr;
  }
}
```

#### 4. **具体操作转换**

##### a) 数字常数
```cpp
mlir::Value MLIRGenImpl::mlirGen(NumberExprAST &num) {
  // AST: NumberExprAST(1.0)
  // → MLIR: %0 = toy.constant dense<1.0> : tensor<f64>
  
  return ConstantOp::create(builder, loc(num.loc()), num.getValue());
}
```

##### b) 数组字面量
```cpp
mlir::Value MLIRGenImpl::mlirGen(LiteralExprAST &lit) {
  // AST: LiteralExprAST([[1,2], [3,4]])
  // → MLIR: %0 = toy.constant dense<[[1.0, 2.0], [3.0, 4.0]]>
  //              : tensor<2x2xf64>
  
  auto type = getType(lit.getDims());  // 获取张量类型
  
  std::vector<double> data;
  collectData(lit, data);              // 递归收集数据
  
  auto dataAttribute = mlir::DenseElementsAttr::get(dataType, data);
  return ConstantOp::create(builder, loc(lit.loc()), type, dataAttribute);
}
```

##### c) 二元操作
```cpp
mlir::Value MLIRGenImpl::mlirGen(BinaryExprAST &binop) {
  // AST: BinaryExprAST(lhs=1.0, op='+', rhs=2.0)
  // → MLIR: 
  //   %0 = toy.constant dense<1.0> : tensor<f64>
  //   %1 = toy.constant dense<2.0> : tensor<f64>
  //   %2 = toy.add %0, %1 : tensor<f64>
  
  mlir::Value lhs = mlirGen(*binop.getLHS());
  mlir::Value rhs = mlirGen(*binop.getRHS());
  
  switch (binop.getOp()) {
    case '+':
      return AddOp::create(builder, location, lhs, rhs);
    case '*':
      return MulOp::create(builder, location, lhs, rhs);
  }
}
```

##### d) 变量引用
```cpp
mlir::Value MLIRGenImpl::mlirGen(VariableExprAST &expr) {
  // AST: VariableExprAST("a")
  // → MLIR: 使用符号表中的值 %a
  
  if (auto variable = symbolTable.lookup(expr.getName()))
    return variable;
  
  emitError(loc(expr.loc()), "unknown variable '") 
    << expr.getName() << "'";
  return nullptr;
}
```

##### e) 函数调用
```cpp
mlir::Value MLIRGenImpl::mlirGen(CallExprAST &call) {
  // AST: CallExprAST("transpose", [x])
  // → MLIR: %0 = toy.transpose %x : ...
  
  StringRef callee = call.getCallee();
  
  SmallVector<mlir::Value, 4> operands;
  for (auto &expr : call.getArgs()) {
    operands.push_back(mlirGen(*expr));
  }
  
  if (callee == "transpose") {
    return TransposeOp::create(builder, location, operands[0]);
  }
  
  // 用户定义的函数
  return GenericCallOp::create(builder, location, callee, operands);
}
```

##### f) 变量声明
```cpp
mlir::Value MLIRGenImpl::mlirGen(VarDeclExprAST &vardecl) {
  // AST: VarDeclExprAST("a", shape=[2,3], init=LiteralExprAST([...]))
  // → MLIR:
  //   %0 = toy.constant dense<...> : tensor<2x3xf64>
  //   %1 = toy.reshape %0 : tensor<2x3xf64>
  
  mlir::Value value = mlirGen(*vardecl.getInitVal());
  
  // 如果声明指定了形状，添加 reshape 操作
  if (!vardecl.getType().shape.empty()) {
    value = ReshapeOp::create(builder, loc(vardecl.loc()),
                              getType(vardecl.getType()), value);
  }
  
  // 在符号表中注册变量
  declare(vardecl.getName(), value);
  return value;
}
```

##### g) 返回语句
```cpp
llvm::LogicalResult MLIRGenImpl::mlirGen(ReturnExprAST &ret) {
  // AST: ReturnExprAST(Some(BinaryExprAST(...)))
  // → MLIR: toy.return %0 : tensor<...>
  
  mlir::Value expr = nullptr;
  if (ret.getExpr().has_value()) {
    expr = mlirGen(**ret.getExpr());
  }
  
  ReturnOp::create(builder, location,
                   expr ? ArrayRef(expr) : ArrayRef<mlir::Value>());
  return mlir::success();
}
```

#### 5. **块和作用域处理**

```cpp
llvm::LogicalResult MLIRGenImpl::mlirGen(ExprASTList &blockAST) {
  // 为新块创建作用域
  ScopedHashTableScope<StringRef, mlir::Value> varScope(symbolTable);
  
  for (auto &expr : blockAST) {
    // 特殊处理某些语句类型
    if (auto *vardecl = dyn_cast<VarDeclExprAST>(expr.get())) {
      mlirGen(*vardecl);
      continue;
    }
    
    if (auto *ret = dyn_cast<ReturnExprAST>(expr.get()))
      return mlirGen(*ret);
    
    if (auto *print = dyn_cast<PrintExprAST>(expr.get())) {
      mlirGen(*print);
      continue;
    }
    
    // 一般表达式分发
    mlirGen(*expr);
  }
  
  return mlir::success();
}
```

### 类型转换

```cpp
mlir::Type MLIRGenImpl::getType(ArrayRef<int64_t> shape) {
  if (shape.empty())
    // 无秩张量
    return mlir::UnrankedTensorType::get(builder.getF64Type());
  else
    // 有秩张量，例如 tensor<2x3xf64>
    return mlir::RankedTensorType::get(shape, builder.getF64Type());
}
```

---

## 完整示例：Toy 代码→MLIR

### 源代码（toy 文件）

```toy
def multiply_transpose(a, b) {
  return transpose(a) * transpose(b);
}

def main() {
  var a<2, 3> = [[1, 2, 3], [4, 5, 6]];
  var b<2, 3> = [1, 2, 3, 4, 5, 6];
  print(multiply_transpose(a, b));
}
```

### 解析后的 AST 树结构

```
ModuleAST
├── FunctionAST("multiply_transpose")
│   ├── PrototypeAST("multiply_transpose", [a, b])
│   └── ExprASTList
│       └── ReturnExprAST
│           └── BinaryExprAST(*)
│               ├── CallExprAST("transpose")
│               │   └── VariableExprAST("a")
│               └── CallExprAST("transpose")
│                   └── VariableExprAST("b")
│
└── FunctionAST("main")
    ├── PrototypeAST("main", [])
    └── ExprASTList
        ├── VarDeclExprAST("a")
        │   └── LiteralExprAST([[1,2,3], [4,5,6]])
        ├── VarDeclExprAST("b")
        │   └── LiteralExprAST([1,2,3,4,5,6])
        └── PrintExprAST
            └── CallExprAST("multiply_transpose")
                ├── VariableExprAST("a")
                └── VariableExprAST("b")
```

### 生成的 MLIR（Dialect IR）

```mlir
module {
  toy.func @multiply_transpose(%arg0: tensor<?xf64>, %arg1: tensor<?xf64>) -> tensor<?xf64> {
    %0 = toy.transpose %arg0 : tensor<?xf64>
    %1 = toy.transpose %arg1 : tensor<?xf64>
    %2 = toy.mul %0, %1 : tensor<?xf64>
    toy.return %2 : tensor<?xf64>
  }
  
  toy.func @main() {
    %0 = toy.constant dense<[[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]]>
         : tensor<2x3xf64>
    %1 = toy.reshape %0 : tensor<2x3xf64>
    
    %2 = toy.constant dense<[1.0, 2.0, 3.0, 4.0, 5.0, 6.0]>
         : tensor<6xf64>
    %3 = toy.reshape %2 : tensor<2x3xf64>
    
    %4 = toy.generic_call @multiply_transpose(%1, %3) 
         : (tensor<2x3xf64>, tensor<2x3xf64>) -> tensor<?xf64>
    
    toy.print %4 : tensor<?xf64>
    toy.return
  }
}
```

---

## 关键概念总结

### 1. **AST 与 Dialect 的对应关系**

| AST 节点                 | MLIR 操作                | 说明             |
| ------------------------ | ------------------------ | ---------------- |
| `ModuleAST`              | `mlir::ModuleOp`         | 模块容器         |
| `FunctionAST`            | `toy.func`               | 函数定义         |
| `PrototypeAST`           | 函数签名                 | 函数原型         |
| `NumberExprAST`          | `toy.constant`           | 标量常数         |
| `LiteralExprAST`         | `toy.constant`           | 数组常数         |
| `VariableExprAST`        | SSA 值引用               | 变量使用         |
| `BinaryExprAST(+)`       | `toy.add`                | 加法操作         |
| `BinaryExprAST(*)`       | `toy.mul`                | 乘法操作         |
| `CallExprAST(transpose)` | `toy.transpose`          | 转置内建函数     |
| `CallExprAST(other)`     | `toy.generic_call`       | 用户函数调用     |
| `VarDeclExprAST`         | `toy.reshape` + SSA 绑定 | 变量声明与初始化 |
| `ReturnExprAST`          | `toy.return`             | 返回语句         |
| `PrintExprAST`           | `toy.print`              | 打印操作         |

### 2. **符号表的作用**

```cpp
llvm::ScopedHashTable<StringRef, mlir::Value> symbolTable;
```

- **创建作用域**：进入函数或块时调用 `ScopedHashTableScope`
- **注册变量**：`symbolTable.insert(varName, mirValue)`
- **查询变量**：`symbolTable.lookup(varName)` 返回相应的 MLIR Value
- **销毁作用域**：退出函数或块时自动销毁

### 3. **OpBuilder 的角色**

```cpp
mlir::OpBuilder builder;
```

- 管理**插入点**：操作在何处添加到 IR 中
- **创建操作**：`builder.create<OpType>(loc, args...)`
- **类型创建**：`builder.getF64Type()`, `builder.getFunctionType(...)`
- **位置追踪**：每个操作都关联源代码位置

### 4. **类型推导与创建**

```cpp
// 从 AST 维度创建 MLIR 类型
VarType astType = {shape: [2, 3]};
mlir::Type mlirType = getType(astType);
// → mlir::RankedTensorType<2x3xf64>

// 属性收集
std::vector<double> data;
collectData(literalAST, data);  // 递归扁平化
auto attr = mlir::DenseElementsAttr::get(tensorType, data);
```

### 5. **错误处理与验证**

```cpp
// 语义检查
if (!symbolTable.lookup(varName))
  emitError(loc, "unknown variable");

// 模块验证
if (failed(mlir::verify(theModule)))
  return nullptr;
```

---

## 编译流程总结

```
Toy 源文件
    ↓
Lexer (词法分析)
    ↓
Parser (语法分析) → AST
    ↓
MLIRGen (遍历 AST)
    ├─→ 读取 AST 节点
    ├─→ 查询 Dialect 操作定义
    ├─→ 使用 OpBuilder 创建操作
    ├─→ 管理符号表（变量映射）
    └─→ 验证生成的 MLIR
    ↓
MLIR Module (Dialect IR)
    ↓
后续 Pass（优化、降低等）
    ↓
最终代码生成
```

---

## 文件导航

### Ch1 - AST 定义
- [AST.h](mlir/examples/toy/Ch1/include/toy/AST.h) - 节点定义
- [Lexer.h](mlir/examples/toy/Ch1/include/toy/Lexer.h) - 词法分析
- [Parser.h](mlir/examples/toy/Ch1/include/toy/Parser.h) - 语法分析

### Ch2 - Dialect + MLIRGen
- **Dialect 定义**
  - [Ops.td](mlir/examples/toy/Ch2/include/toy/Ops.td) - 操作定义（TableGen）
  - [Dialect.h](mlir/examples/toy/Ch2/include/toy/Dialect.h) - Dialect 声明
  - [Dialect.cpp](mlir/examples/toy/Ch2/mlir/Dialect.cpp) - Dialect 实现

- **MLIR 生成**
  - [MLIRGen.h](mlir/examples/toy/Ch2/include/toy/MLIRGen.h) - 接口
  - [MLIRGen.cpp](mlir/examples/toy/Ch2/mlir/MLIRGen.cpp) - **核心转换实现**

- **编译器入口**
  - [toyc.cpp](mlir/examples/toy/Ch2/toyc.cpp) - 驱动程序

---

## 关键代码位置

### MLIRGen.cpp 中的关键方法

| 方法                          | 行号 | 功能       |
| ----------------------------- | ---- | ---------- |
| `mlirGen(ModuleAST)`          | ~70  | 模块入口   |
| `mlirGen(FunctionAST)`        | ~130 | 函数处理   |
| `mlirGen(BinaryExprAST)`      | ~180 | 二元操作   |
| `mlirGen(LiteralExprAST)`     | ~250 | 数组常数   |
| `mlirGen(CallExprAST)`        | ~310 | 函数调用   |
| `mlirGen(ExprAST)` - dispatch | ~360 | 表达式分发 |
| `getType()`                   | ~430 | 类型构造   |

---

## 深入学习资源

1. **MLIR 官方文档**：https://mlir.llvm.org/
2. **Toy 教程**：`docs/Tutorials/Toy/Ch-*.md`
3. **TableGen 指南**：`mlir/include/mlir/IR/OpBase.td`
4. **LLVM IR 设计**：传统编译器设计理论
