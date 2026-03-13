# MLIR vs Triton 快速参考卡

## 一句话总结

| 方案              | 核心概念                                  |
| ----------------- | ----------------------------------------- |
| **MLIR Tiling**   | 编译阶段把大操作拆成小操作，优化循环结构  |
| **Triton Tiling** | 用GPU线程块作为编程单位，自动处理硬件优化 |

---

## 代码对比（最重要！）

### MLIR 方式

**输入**:
```mlir
linalg.matmul ins(%A, %B) outs(%C)
```

**配置**:
```cpp
opts.setTileSizes({32, 32, 64});
```

**输出** (自动生成):
```mlir
scf.for %m = 0 to M step 32 {
  scf.for %n = 0 to N step 32 {
    scf.for %k = 0 to K step 64 {
      %A_tile = memref.subview %A[%m, %k][32, 64]
      %B_tile = memref.subview %B[%k, %n][64, 32]
      %C_tile = memref.subview %C[%m, %n][32, 32]
      linalg.matmul ins(%A_tile, %B_tile) outs(%C_tile)
    }
  }
}
```

---

### Triton 方式

**输入** (用户手写):
```python
@triton.jit
def matmul(A, B, C, M, N, K, ..., **META):
    BLOCK_M, BLOCK_N, BLOCK_K = META['BLOCK_M'], META['BLOCK_N'], META['BLOCK_K']
    
    pid_m = tl.program_id(0)    # 线程块ID
    pid_n = tl.program_id(1)
    
    # 该Block处理的位置
    rm = pid_m * BLOCK_M + tl.arange(0, BLOCK_M)
    rn = pid_n * BLOCK_N + tl.arange(0, BLOCK_N)
    
    # 计算分块
    acc = tl.zeros((BLOCK_M, BLOCK_N), dtype=tl.float32)
    for k in range(0, K, BLOCK_K):
        a = tl.load(A)
        b = tl.load(B)
        acc += tl.dot(a, b)  # Block级矩阵乘
    
    tl.store(C, acc)
```

**特点**: 用户直接指定GPU执行模式

---

## 执行模型对比

### MLIR

```
编译时刻：
  linalg.matmul ─────→ [Tiling Pass] ─────→ scf.for 循环
  
运行时刻：
  scf.for → 物理循环执行 → 内存访问 → 计算 → 存储
```

### Triton

```
编译时刻：
  Triton代码 ─────→ AST解析 ─────→ Triton-IR ─────→ 优化 ─────→ LLVM-IR → PTX
  
运行时刻：
  Grid启动 → 多个Block并行 → 内存合并✓ → 共享内存✓ → 计算 → 存储
  （✓ = 编译器自动处理）
```

---

## 分块大小如何指定

### MLIR

```cpp
// 方式1：固定大小
opts.setTileSizes({32, 32, 64});

// 方式2：动态计算
opts.setTileSizeComputationFunction([](OpBuilder &b, Operation *op) {
  return SmallVector<Value>{...};
});
```

### Triton

```python
# 元参数方式
@triton.jit
def kernel(..., BLOCK_M: tl.constexpr, BLOCK_N: tl.constexpr, BLOCK_K: tl.constexpr):
    ...

# 启动时指定
kernel[grid, (BLOCK_M, BLOCK_N)](A, B, C, ...)
```

---

## 性能优化的方式

### MLIR：多Pass组合

```bash
# 分块
-linalg-tiling -tile-sizes=32,32,64
# 融合
-linalg-fuse-elementwise-ops
# 向量化
-vector-default-lowering
# 循环优化
-affine-pipeline-data-transfer
```

### Triton：一体化

```python
@triton.jit
def kernel(...):
    # 编写一次
    # 编译器自动：
    # ✓ 内存合并优化
    # ✓ 共享内存分配
    # ✓ 线程调度
    # ✓ Warp优化
    pass
```

---

## 需要了解什么

### MLIR 需要懂

- [ ] 什么是 Tiling（分块）
- [ ] Loop IR（scf/affine）
- [ ] MemRef 和 Tensor
- [ ] Transformation 框架
- [ ] 多个 Pass 的组合

### Triton 需要懂

- [ ] GPU 线程模型（Grid/Block）
- [ ] program_id（线程块ID）
- [ ] Block（多维数据块）
- [ ] Memory coalescing（内存合并）
- [ ] Shared memory（共享内存）

---

## 典型使用场景

### MLIR 用于

```
深度学习框架的编译器后端：
  PyTorch/TensorFlow
    ↓
  高层操作（convolution, matmul等）
    ↓
  MLIR Tiling + 其他优化
    ↓
  高效的 CPU/GPU 代码
```

**工具链**: IREE, XLA, JAX, TVM

---

### Triton 用于

```
自定义 GPU 内核优化：
  想要写高效 matmul
    ↓
  用 Triton（不用CUDA）
    ↓
  ~25行代码
    ↓
  性能接近 cuBLAS
```

**工具链**: PyTorch, vLLM, xFormers

---

## 决策树

```
Q: 我需要编译器优化吗？
├─ 是 → Q2: 需要跨平台吗？
│   ├─ 是 → MLIR ✓
│   └─ 否 → Q3: 是否NVIDIA GPU？
│       ├─ 是 → Triton ✓（更简洁）
│       └─ 否 → MLIR ✓
│
└─ 否 → Q2: 我只想写一个GPU内核吗？
    ├─ 是 → Triton ✓
    └─ 否 → MLIR ✓
```

---

## 关键数据对比

| 指标                 | MLIR               | Triton           |
| -------------------- | ------------------ | ---------------- |
| **学习时间**         | 1-2 周             | 3-5 天           |
| **Hello World 长度** | 50+ 行配置         | 10 行代码        |
| **性能开发周期**     | 需要多次调整 Pass  | 1-2 次调参       |
| **可读性**           | 高（MLIR IR）      | 高（Python）     |
| **可维护性**         | 中等               | 高（用户代码少） |
| **调试难度**         | 中等（查看中间IR） | 困难（GPU调试）  |
| **扩展性**           | 高（编译器框架）   | 低（语言设定）   |

---

## 内存优化的自动化程度

### MLIR

```
手动：
  ✗ 选择 tile size
  ✗ 指定循环顺序
  ✗ 决定是否分块
  
自动：
  ✓ 生成循环嵌套
  ✓ 应用于所有维度
  ✓ 后续 pass 优化
```

### Triton

```
手动：
  ✗ 内存访问模式（tl.load）
  ✗ Block大小（META参数）
  ✗ 计算逻辑（Python）
  
自动：
  ✓ 内存合并（tl.load分析）
  ✓ 共享内存分配
  ✓ 线程同步
  ✓ Warp调度
```

---

## 何时选择哪个

### 用 MLIR Tiling 如果：

- 需要**一个编译器**处理多个操作
- 目标**多平台**（CPU/GPU）
- 有现有的编译基础设施
- 需要**精细的编译控制**
- 算法框架复杂

**例子**: XLA, IREE, 商业编译器

---

### 用 Triton 如果：

- 只需要写**一个 GPU 内核**
- 目标**NVIDIA GPU**
- 想要**快速原型**和**简洁代码**
- 不想学习 CUDA
- 性能很重要

**例子**: PyTorch 自定义算子, vLLM 内核, xFormers

---

## 实战建议

### 学习 MLIR Tiling：

1. 先学基础（Range, Loop结构）
2. 跑一个简单例子（e.g., matmul）
3. 尝试调整 tile sizes
4. 观察生成的循环结构
5. 深入学习其他 Pass（fusion, vectorization）

### 学习 Triton：

1. 理解 Grid/Block 概念
2. 写一个 element-wise op
3. 写一个 reduction（sum）
4. 写一个 matmul
5. 优化（调 BLOCK_M/N/K）

---

## 资源链接

### MLIR

- [官方教程](https://mlir.llvm.org/docs/Tutorials/)
- Tiling 代码：`mlir/lib/Dialect/Linalg/Transforms/Tiling.cpp`
- 测试：`mlir/test/Dialect/Linalg/tile-*.mlir`

### Triton

- [官方文档](https://triton-lang.org/)
- [GitHub](https://github.com/openai/triton)
- 示例：Triton tutorials (matmul, softmax等)

