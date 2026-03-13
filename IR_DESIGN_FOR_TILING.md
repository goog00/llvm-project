# IR 设计：从 Tiling 的角度看最小化操作集

## 你的洞察（完全正确！）

```
MLIR (声明式)                    Triton (命令式)
┌─────────────────────┐        ┌──────────────────────┐
│ 高层抽象操作        │        │ Block级编程API       │
│ "我要 matmul"       │        │ "在这个位置做这个"   │
│ ↓ 编译器决定        │        │ ↓ 用户决定           │
│ 如何tiling         │        │ 如何分块和优化       │
└─────────────────────┘        └──────────────────────┘

MLIR: 用户指定**WHAT**，编译器做**HOW**
Triton: 用户既指定WHAT又指定**HOW**
```

---

## 从 Tiling 看 IR 设计

### 问题1：Tiling 对 IR 有什么要求？

让我们用一个具体例子：

```mlir
// 原始操作
%C = linalg.matmul ins(%A, %B) outs(%C)

// Tiling 后需要的 IR 特性
scf.for %m = 0 to M step 32 {      // ← 循环结构
  scf.for %n = 0 to N step 32 {    // ← 循环结构
    scf.for %k = 0 to K step 64 {  // ← 循环结构
      %A_tile = memref.subview %A[%m, %k][32, 64]  // ← 子视图/索引操作
      %B_tile = memref.subview %B[%k, %n][64, 32]
      %C_tile = memref.subview %C[%m, %n][32, 32]
      %result = linalg.matmul ins(%A_tile, %B_tile) outs(%C_tile)  // ← 原操作重用
    }
  }
}
```

从这个例子看，IR 需要支持：

| 特性            | 为什么                 | 例子                                     |
| --------------- | ---------------------- | ---------------------------------------- |
| **循环结构**    | Tiling 生成嵌套循环    | `scf.for`, `affine.for`                  |
| **子视图/索引** | 提取分块数据           | `memref.subview`, `tensor.extract_slice` |
| **操作重用**    | 对分块重复应用相同计算 | `linalg.matmul` 应用于tile               |
| **控制流**      | 边界条件处理           | `scf.if`, `affine.if`                    |
| **类型系统**    | 描述数据形状和步长     | `memref<?x?xf32, strided>`               |

---

## 最小 IR 操作集定义

### 1️⃣ 核心数据结构层

```
这一层定义 IR 能处理什么数据
```

#### 必需操作：

```mlir
// 类型系统
memref<MxNxf32>                    // 静态形状
memref<?x?xf32>                    // 动态形状  
memref<?x?xf32, strided<...>>      // 带步长的内存视图

tensor<MxNxf32>                    // 张量（不可变）
```

**为什么需要**：
- Tiling 需要描述原始数据（A, B, C）的形状
- 需要支持动态维度（运行时才知道）
- 需要支持非连续内存（strided，用于subview）

---

### 2️⃣ 操作（Operations）层

#### A. 内存/索引操作 ⭐⭐⭐

```mlir
// 必需：提取数据片段（Tiling 的核心）
%tile = memref.subview %A[%m, %k][32, 64][1, 1]
        : memref<?x?xf32> to memref<32x64xf32, strided<[?, 1]>>

%slice = tensor.extract_slice %A[%m:%m+32, %k:%k+64]
         : tensor<?x?xf32> to tensor<32x64xf32>

// 必需：加载/存储
%val = memref.load %A[%i, %j] : memref<?x?xf32>
memref.store %val, %B[%i, %j] : memref<?x?xf32>

// 必需：分配内存（临时缓冲区）
%buf = memref.alloc(32, 64) : memref<32x64xf32>
memref.dealloc %buf : memref<32x64xf32>
```

**Tiling 中的作用**：
```
scf.for %m ... {
  scf.for %n ... {
    // 这里必须能提取分块
    %A_tile = memref.subview %A[%m, ...][32, 32][1, 1]  ← 核心！
    // 然后应用操作
    call @compute(%A_tile)
  }
}
```

---

#### B. 基本计算操作

```mlir
// 必需：算术运算（标量计算）
%c = arith.addf %a, %b : f32
%p = arith.mulf %a, %b : f32

// 必需：结构化操作（高层操作）
%C = linalg.matmul ins(%A, %B) outs(%C)
%C = linalg.generic {...} ins(%A) outs(%C)
```

**Tiling 中的作用**：
```
// 方式1：对分块应用相同的高层操作
scf.for ... {
  %result = linalg.matmul ins(%A_tile, %B_tile) outs(%C_tile)
                          ↑
                    对 tile 重用相同操作
}

// 方式2：展开为标量循环
scf.for %i ... {
  scf.for %j ... {
    %a = memref.load %A[%i, %j]   ← 标量加载
    %b = memref.load %B[%i, %j]
    %c = arith.addf %a, %b        ← 标量计算
    memref.store %c, %C[%i, %j]   ← 标量存储
  }
}
```

---

#### C. 循环控制 ⭐⭐⭐

```mlir
// 必需：循环（Tiling 生成的核心）
scf.for %i = %lb to %ub step %step {
  // 循环体
}

// 可选但常用：并行循环
scf.forall (%i, %j) in (%lb:%ub, %lb:%ub) {
  // 并行体
}

// 必需：条件分支（边界处理）
scf.if %cond {
  // true 分支
} else {
  // false 分支
}
```

**Tiling 中的作用**：
```
// 完整的 tiling 结构
scf.for %m = 0 to M step 32 {
  scf.for %n = 0 to N step 32 {
    scf.for %k = 0 to K step 64 {
      %A_tile = memref.subview %A[%m, %k][...]
      %B_tile = memref.subview %B[%k, %n][...]
      %C_tile = memref.subview %C[%m, %n][...]
      
      // 边界检查
      %cond = arith.cmpi lt, %m, %M : index
      scf.if %cond {
        linalg.matmul ins(%A_tile, %B_tile) outs(%C_tile)
      }
    }
  }
}
```

---

#### D. 函数/操作容器

```mlir
// 必需：函数定义
func.func @matmul(%A: memref<?x?xf32>, 
                  %B: memref<?x?xf32>,
                  %C: memref<?x?xf32>) {
  // Tiling 代码在这里
  return
}

// 必需：函数调用
func.call @matmul(%A, %B, %C) : (memref<?x?xf32>, ...) -> ()
```

---

### 3️⃣ 元数据/属性层

```mlir
// Indexing maps（描述操作如何访问数据）
linalg.generic {
  indexing_maps = [
    affine_map<(d0, d1, d2) -> (d0, d2)>,  // A: (m, k)
    affine_map<(d0, d1, d2) -> (d2, d1)>,  // B: (k, n)
    affine_map<(d0, d1, d2) -> (d0, d1)>   // C: (m, n)
  ]
}

// Iterator types（指定循环的性质）
iterator_types = ["parallel", "parallel", "reduction"]
```

**Tiling 中的作用**：
```
Tiling Pass 需要这些信息来：
1. 理解哪个维度是 M, N, K
2. 决定如何分块
3. 推导 tile 后的索引映射
```

---

## 最小 IR 操作集总结

### 绝对必需（TOP 5）

```
1. ✅ 类型系统（Memref, Tensor）
   └─ 为什么：描述数据的形状和内存布局
   
2. ✅ 子视图/切片操作（subview, extract_slice）
   └─ 为什么：Tiling 的核心——提取分块
   
3. ✅ 循环操作（scf.for, affine.for）
   └─ 为什么：Tiling 生成嵌套循环
   
4. ✅ 加载/存储（load, store）
   └─ 为什么：访问内存中的数据
   
5. ✅ 算术/结构化操作（arith.*, linalg.*)
   └─ 为什么：表达计算
```

### 强烈推荐

```
6. 🟢 条件分支（scf.if）
   └─ 为什么：处理边界和条件
   
7. 🟢 函数（func.func, func.call）
   └─ 为什么：模块化代码
   
8. 🟢 并行循环（scf.forall）
   └─ 为什么：GPU/多线程映射
```

### 可选但有用

```
9. 🔵 Affine 循环（affine.for）
   └─ 为什么：优化友好的循环
   
10. 🔵 内存分配（memref.alloc）
    └─ 为什么：临时缓冲区
```

---

## 从 Tiling 的完整流程看

### 输入 → 处理 → 输出

```
输入层（需要的操作）：
  linalg.matmul
    ↑
  需要：结构化操作 + 类型系统

   ↓ Tiling Pass

处理层（Tiling 中需要）：
  1. 理解输入操作的语义
  2. 决定分块大小
  3. 生成循环嵌套（需要：循环操作）
  4. 提取分块（需要：子视图操作）
  5. 应用操作到分块（需要：函数调用）

   ↓

输出层（生成的操作）：
  scf.for
    ├─ 需要：循环结构 ✓
    ├─ 需要：索引计算 (arith.*) 
    ├─ 需要：子视图 ✓
    └─ 需要：内嵌操作调用 ✓
```

---

## 设计 IR 的具体建议

### 层级1：最小化 IR（能做 Tiling）

```
必需组件：
┌─────────────────────────────────────┐
│ 1. 类型系统                         │
│    - Memref (带步长)                │
│    - Tensor                         │
│                                     │
│ 2. 内存操作                         │
│    - subview / extract_slice        │
│    - load / store                   │
│    - alloc / dealloc                │
│                                     │
│ 3. 循环                             │
│    - for (必需)                     │
│    - if (边界)                      │
│                                     │
│ 4. 操作                             │
│    - arith.* (算术)                 │
│    - 结构化操作 (或通用 generic)    │
│    - func.call                      │
│                                     │
│ 5. 元数据                           │
│    - indexing_maps                  │
│    - iterator_types                 │
│                                     │
└─────────────────────────────────────┘
```

### 层级2：优化友好 IR（支持高级优化）

添加到最小化 IR：

```
┌─────────────────────────────────────┐
│ + Affine 循环 (affine.for)          │
│ + Affine 表达式 (affine_map)        │
│ + 并行循环 (scf.forall)             │
│ + GPU 操作 (gpu.*)                  │
│ + 向量操作 (vector.*)               │
│                                     │
└─────────────────────────────────────┘
```

---

## 实践例子：用最小 IR 表达 Tiling

### 只用最小集合表达 Tiling

```mlir
// 注：这是用最小操作集写的
module {
  func.func @matmul_tiled(%A: memref<?x?xf32>,
                          %B: memref<?x?xf32>,
                          %C: memref<?x?xf32>,
                          %M: index, %N: index, %K: index) {
    %c0 = arith.constant 0 : index
    %c32 = arith.constant 32 : index
    
    // 三层循环（最小必需操作）
    scf.for %m = %c0 to %M step %c32 {
      scf.for %n = %c0 to %N step %c32 {
        scf.for %k = %c0 to %K step %c32 {
          
          // 提取分块（必需：subview）
          %A_tile = memref.subview %A[%m, %k][32, 32][1, 1]
                    : memref<?x?xf32> to memref<32x32xf32, strided<[?, 1]>>
          %B_tile = memref.subview %B[%k, %n][32, 32][1, 1]
                    : memref<?x?xf32> to memref<32x32xf32, strided<[?, 1]>>
          %C_tile = memref.subview %C[%m, %n][32, 32][1, 1]
                    : memref<?x?xf32> to memref<32x32xf32, strided<[?, 1]>>
          
          // 对分块应用操作（必需：操作）
          func.call @matmul_tile(%A_tile, %B_tile, %C_tile)
                    : (memref<32x32xf32, strided<[?, 1]>>,
                       memref<32x32xf32, strided<[?, 1]>>,
                       memref<32x32xf32, strided<[?, 1]>>) -> ()
        }
      }
    }
    return
  }
  
  func.func @matmul_tile(%A: memref<32x32xf32, strided<[?, 1]>>,
                         %B: memref<32x32xf32, strided<[?, 1]>>,
                         %C: memref<32x32xf32, strided<[?, 1]>>) {
    %c0 = arith.constant 0 : index
    %c32 = arith.constant 32 : index
    
    // 标量循环
    scf.for %i = %c0 to %c32 step %c1 {
      scf.for %j = %c0 to %c32 step %c1 {
        scf.for %p = %c0 to %c32 step %c1 {
          // 标量操作（必需：load, arith.*, store）
          %a = memref.load %A[%i, %p] : memref<32x32xf32, ...>
          %b = memref.load %B[%p, %j] : memref<32x32xf32, ...>
          %prod = arith.mulf %a, %b : f32
          %c = memref.load %C[%i, %j] : memref<32x32xf32, ...>
          %sum = arith.addf %c, %prod : f32
          memref.store %sum, %C[%i, %j] : memref<32x32xf32, ...>
        }
      }
    }
    return
  }
}
```

**分析**：这个例子用**最小操作集**表达了完整的 Tiling：
- ✅ 循环：`scf.for`（3层）
- ✅ 子视图：`memref.subview`（提取分块）
- ✅ 操作：`func.call`, `memref.load`, `arith.*`, `memref.store`
- ✅ 类型：`memref<32x32xf32, strided<...>>`

---

## IR 设计的核心原则

### 原则1：分离关注点

```
高层操作        → linalg.matmul（用户说"要什么"）
   ↓
Tiling 变换     → 生成循环嵌套（编译器决定"怎么做"）
   ↓
中层操作        → scf.for, memref.subview（机器执行的模型）
   ↓
低层操作        → affine.for, memref.load（优化友好）
   ↓
目标代码        → LLVM IR → 汇编（执行）
```

**对 IR 的含义**：
- 保留**多个抽象层级**的操作（不同的Pass在不同层级工作）
- 高层操作用于**声明语义**（什么是 matmul）
- 低层操作用于**执行语义**（如何实现）

---

### 原则2：可组合性

```
IR 操作应该能自由组合：
  scf.for { 
    scf.for {
      scf.if {
        memref.subview {
          func.call { ... }
        }
      }
    }
  }
```

**对 IR 的含义**：
- 操作要有清晰的输入/输出
- 支持任意嵌套
- 避免"只能在某个上下文中使用"的操作

---

### 原则3：不丢失信息

```
高层操作包含丰富的语义信息（什么是 matmul）
Tiling 前不应该丢失这些信息
等到需要时再展开

例如：
  linalg.matmul {                  ← 保留语义
    indexing_maps = [...]          ← 保留索引信息
    iterator_types = [...]         ← 保留循环类型
  }
  
在 Tiling Pass 中可以利用这些信息做更好的决策
```

**对 IR 的含义**：
- 设计**属性系统**来保留元数据
- 不要过早地展开（desugar）高层操作

---

## 总结：最小 IR 设计清单

### 必需的 5 大类操作

```
1. ✅ 类型系统（Types）
   ├─ memref（带步长支持）
   └─ tensor
   
2. ✅ 内存操作（Memory）
   ├─ subview / extract_slice
   ├─ load / store
   └─ alloc / dealloc
   
3. ✅ 循环（Loops）
   ├─ scf.for
   └─ scf.if
   
4. ✅ 计算（Compute）
   ├─ arith.*（基本算术）
   ├─ 结构化操作（linalg/generic）
   └─ 函数调用
   
5. ✅ 元数据（Metadata）
   ├─ indexing_maps
   └─ iterator_types
```

### 为什么这些是最小集合

```
Tiling 的完整流程：

用户指定：     linalg.matmul + tile_size=[32,32,64]
               ↑ 需要：类型系统、结构化操作、元数据

编译器生成：   scf.for x scf.for x scf.for
               ↑ 需要：循环操作

在循环中：     memref.subview, func.call
               ↑ 需要：内存操作、函数调用

标量计算：     arith.mulf, memref.load, memref.store
               ↑ 需要：算术、内存访问
```

每个类别都不能缺少，任何缺少都会打破 Tiling 流程。

---

## 实际建议

### 如果你要设计一个支持 Tiling 的 IR

**第一阶段**：实现上述 TOP 5

```
Priority 1（Week 1）:
  - 类型系统（Memref）
  - scf.for / scf.if
  - 子视图操作
  - 基本算术（arith.*）

Priority 2（Week 2）:
  - 函数定义和调用
  - 元数据属性系统
  - 结构化操作框架
```

**第二阶段**：添加优化层级

```
Priority 3（Week 3+）:
  - Affine 方言（优化友好）
  - GPU 操作（GPU target）
  - 向量操作（向量化）
```

### 不要做的事

```
❌ 不要为每个操作创建特定上下文的语法
   → 保持通用性和可组合性

❌ 不要过早地 desugar（展开高层操作）
   → 让 Pass 保留尽可能多的信息

❌ 不要忘记元数据系统
   → Tiling 需要理解操作的语义

❌ 不要混淆"什么"和"怎么做"
   → 高层操作说"什么"，低层操作说"怎么做"
```

