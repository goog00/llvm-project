# 深度总结：IR 设计中的 Tiling 角度

## 你的关键洞察

你提出了一个**深层的设计哲学问题**：

```
MLIR:  "用户说要什么，编译器决定怎么做" → 声明式
Triton: "用户既说要什么，又说怎么做"   → 命令式

这决定了整个 IR 的结构！
```

---

## 三个层级的总结

### 层级1：表面理解

**问题**：MLIR Tiling 和 Triton Tiling 有什么区别？

**答案**：
- MLIR：编译器自动生成循环嵌套
- Triton：用户直接写 Block 级操作

---

### 层级2：设计理解（你现在的水平）

**问题**：为什么会有这两种方式？

**答案**：
- MLIR 是**声明式** → 多层操作 + 复杂 Pass
- Triton 是**命令式** → 单层清晰 + 简单编译器

**这对 IR 设计的影响**：
- 决定了操作集的设计
- 决定了元数据系统
- 决定了 Pass 的复杂度

---

### 层级3：系统理解（你下一步要达到）

**问题**：我要设计一个支持 Tiling 的 IR，需要什么？

**答案**：
```
第一步：选择哲学
  ├─ 声明式还是命令式？
  └─ 这决定了一切

第二步：设计最小操作集
  ├─ TOP 5 必需操作
  ├─ 它们怎么交互
  └─ 如何支持 Tiling

第三步：实现对应的基础设施
  ├─ 高层操作 vs 低层操作
  ├─ 元数据系统
  └─ Pass 框架
```

---

## MLIR Tiling 需要的最小操作集

### 按重要性排序

```
TOP 5 必需操作：
┌─────────────────────────────────────┐
│ 1. ✅ 类型系统（Types）             │
│    ├─ memref（带 strided）          │
│    └─ tensor                        │
│    为什么：描述数据形状和内存布局   │
│                                     │
│ 2. ✅ 子视图/索引（Indexing）       │
│    ├─ memref.subview                │
│    └─ tensor.extract_slice          │
│    为什么：Tiling 的核心             │
│           → 提取分块                │
│                                     │
│ 3. ✅ 循环（Loops）                 │
│    ├─ scf.for                       │
│    └─ scf.if                        │
│    为什么：Tiling 生成嵌套循环       │
│           → 边界处理                │
│                                     │
│ 4. ✅ 内存操作（Memory）            │
│    ├─ memref.load                   │
│    ├─ memref.store                  │
│    └─ memref.alloc                  │
│    为什么：访问数据                 │
│                                     │
│ 5. ✅ 计算操作（Compute）           │
│    ├─ arith.* (基本算术)            │
│    ├─ 结构化操作 (linalg/generic)  │
│    └─ func.call (函数调用)          │
│    为什么：表达实际计算             │
│                                     │
│ 额外：元数据（Metadata）            │
│    ├─ indexing_maps                 │
│    └─ iterator_types                │
│    为什么：Tiling Pass 需要理解语义 │
└─────────────────────────────────────┘
```

### 这 5 个为什么足够？

```
完整的 Tiling 流程可以用这 5 个表达：

linalg.matmul
  │ (包含 indexing_maps + iterator_types)
  │ Tiling Pass 分析这些元数据
  ↓

scf.for %m = 0 to M step 32 {    // 操作 3: 循环
  scf.for %n = 0 to N step 32 {  // 操作 3: 循环
    scf.for %k = 0 to K step 64 {// 操作 3: 循环
      // 操作 2: 子视图（提取分块）
      %A_tile = memref.subview %A[%m, %k][32, 64][1, 1]
      %B_tile = memref.subview %B[%k, %n][64, 32][1, 1]
      %C_tile = memref.subview %C[%m, %n][32, 32][1, 1]
      
      // 操作 5: 函数调用 + 操作 4: 内存 + 操作 5: 计算
      %i = arith.constant 0 : index
      %j = arith.constant 0 : index
      scf.for %ii = %i to 32 {    // 操作 3: 循环
        scf.for %jj = %j to 32 {
          %a = memref.load %A_tile[%ii, %jj]   // 操作 4: 加载
          %b = memref.load %B_tile[%ii, %jj]
          %prod = arith.mulf %a, %b            // 操作 5: 计算
          %c = memref.load %C_tile[%ii, %jj]
          %sum = arith.addf %c, %prod          // 操作 5: 计算
          memref.store %sum, %C_tile[%ii, %jj] // 操作 4: 存储
        }
      }
    }
  }
}
```

每一行代码都在使用这 5 个基本操作类别！

---

## 如果你要从零设计 IR

### 阶段 1：实现最小操作集（能 Tiling）

**时间**：1-2 周

```cpp
// 伪代码展示设计步骤

// 第 1 天：类型系统
class MemRefType : Type {
  int rank;
  vector<Dimension> shape;
  Type elementType;
  MemoryLayout layout; // 支持 strided
};

// 第 2-3 天：基本操作
Operation* ScfForOp {
  Value lowerBound, upperBound, step;
  Region body;
};

Operation* MemrefSubviewOp {
  Value memref;
  vector<Value> offsets, sizes, strides;
};

// 第 4-5 天：计算操作
Operation* ArithMulFOp {
  Value lhs, rhs;
};

Operation* FuncCallOp {
  FunctionType type;
  vector<Value> args;
};

// 第 6-7 天：元数据系统
class StructuredOpInterface {
  vector<AffineMap> indexing_maps;
  vector<IteratorType> iterator_types;
};
```

**产出**：能运行一个简单的 Tiling Pass

---

### 阶段 2：实现 Tiling Pass

**时间**：2-3 周

```cpp
class TilingPass : Pass {
  // 核心逻辑（简化版）
  
  void runOnOperation(linalg::LinalgOp op) {
    // 第 1 步：理解操作的语义
    vector<AffineMap> maps = op.getIndexingMaps();
    vector<IteratorType> iters = op.getIteratorTypes();
    
    // 第 2 步：决定分块大小
    vector<int64_t> tileSizes = decideTileSizes(op);
    
    // 第 3 步：生成循环嵌套
    vector<scf::ForOp> loops = createNestedLoops(tileSizes);
    
    // 第 4 步：在循环中提取分块
    for (auto loop : loops) {
      createSubviews(op, loop);
    }
    
    // 第 5 步：应用操作到分块
    applyOpToTiles(op);
  }
};
```

**产出**：完整的 Tiling 变换

---

### 阶段 3：添加优化 Pass

**时间**：1-2 周

```cpp
// 融合 Pass（可选）
class LinalgFusionPass : Pass {
  // 将多个 Tiling 后的循环融合
};

// 向量化 Pass（可选）
class VectorizationPass : Pass {
  // 将标量循环转换为向量操作
};
```

---

## 为什么 MLIR 的 Tiling.cpp 有 883 行？

```
现代 MLIR（完整产品）包含：

┌─ 基本 Tiling 逻辑: ~200 行
│  ├─ makeTiledLoopRanges()
│  ├─ linalgOpToLoopsImpl()
│  └─ emitScalarImplementation()
│
├─ 高级特性: ~300 行
│  ├─ 并行化分布
│  ├─ 循环剥离（Peeling）
│  ├─ 循环交换（Interchange）
│  └─ 边界优化
│
├─ 边界情况处理: ~150 行
│  ├─ 非对齐分块
│  ├─ 动态维度
│  └─ 复杂的索引映射
│
├─ Pass 框架: ~100 行
│  ├─ Pass 定义
│  ├─ 选项处理
│  └─ 整合
│
└─ 工具和助手: ~133 行
   ├─ 验证和检查
   ├─ 错误处理
   └─ 日志和调试

总计：883 行
```

**如果只做基本 Tiling**：200-250 行就足够了！

---

## 对你的启发：设计的权衡

### 权衡1：声明式 vs 命令式

```
你需要选择一个：

声明式（MLIR 风格）
  优点：✅ 用户简单 ✅ 自动跨平台 ✅ 优化空间大
  缺点：❌ 编译器复杂 ❌ 启发式不完美
  IR 设计：多层操作 + 丰富元数据
  
命令式（Triton 风格）
  优点：✅ 编译器简单 ✅ 用户可控 ✅ 调试容易
  缺点：❌ 用户需要专业知识 ❌ 难跨平台
  IR 设计：单层清晰 + 最小操作集
```

### 权衡2：操作数量 vs 灵活性

```
操作少 → 表达力受限，但易于实现
操作多 → 表达力强，但复杂度高

平衡点：
  保留最小必需的 5 大类操作
  + 可选的优化友好操作
```

### 权衡3：编译器复杂度 vs 用户代码简洁

```
编译器复杂
  ↗      ↘
声明式   命令式
  ↘      ↗
用户代码复杂
```

---

## 最终建议

### 如果你要设计新 IR

**第一步**：明确你的哲学

```
问：谁应该承担优化的复杂性？

答案A：编译器（声明式）
  → 采用 MLIR 的设计思路
  → 用户负担：最小
  → 编译器负担：最大
  → 适合：框架、库、通用编译器

答案B：用户（命令式）
  → 采用 Triton 的设计思路
  → 用户负担：中等
  → 编译器负担：最小
  → 适合：内核、性能敏感代码
```

**第二步**：设计对应的操作集

```
如果选择声明式（MLIR）：
  必需：TOP 5 操作
  可选：Affine、Vector、GPU
  元数据：indexing_maps、iterator_types、其他
  Pass：Tiling → Fusion → Vectorization
  
如果选择命令式（Triton）：
  必需：清晰的执行模型 + 最小操作
  元数据：BLOCK_M/N/K、program_id
  编译器：代码生成 + 预定义优化
```

**第三步**：实现示例变换

```
选好后，立即实现一个 Tiling 相关的 Pass：
  • 如果是声明式：实现 Tiling Pass (Linalg → SCF)
  • 如果是命令式：实现 Block 层的指令发射
  
通过这个过程，你会发现设计的缺陷！
```

---

## 总结表

| 方面     | 最小 IR    | 完整产品（MLIR） | 为什么               |
| -------- | ---------- | ---------------- | -------------------- |
| 操作集   | 5 大类     | 15+ 方言         | 支持不同层级的优化   |
| 元数据   | 基本注解   | 完整属性系统     | 支持复杂的 Pass 决策 |
| Pass     | Tiling 1个 | 100+ Pass        | 多个优化的组合       |
| 代码行数 | 200-300 行 | 10000+ 行        | 产品需要完整的工具链 |

---

## 你的下一步

1. ✅ 理解 MLIR vs Triton 的本质区别（已完成）
2. ✅ 理解 Tiling 需要的最小操作集（已完成）
3. 📝 **下一步**：实现一个最小 IR + Tiling Pass
   ```
   建议练习：用 C++ 实现一个只支持 MatMul Tiling 的 IR
   预计时间：1-2 周
   产出：300-400 行代码的完整系统
   ```
4. 📝 然后扩展：添加其他 Pass（融合、向量化）
5. 📝 最后反思：哪些设计选择你会改变？

这个过程会给你**深层的编译器设计直觉**。

