# MLIR Tiling vs Triton Tiling 对比

## 快速总结

| 维度         | MLIR Tiling            | Triton Tiling        |
| ------------ | ---------------------- | -------------------- |
| **抽象级别** | 编译器IR变换           | GPU编程语言/框架     |
| **目标**     | CPU/GPU通用分块        | GPU专用优化          |
| **编程模型** | 循环嵌套（scf/affine） | Block级操作（SIMD）  |
| **内存管理** | 手动/自动化            | 全自动（shared mem） |
| **分块粒度** | 多维数据分块           | GPU线程块映射        |
| **适用场景** | 通用张量操作           | 高性能GPU核心        |

---

## 1️⃣ 本质区别

### MLIR Tiling（编译器IR层面）

**定义**: 在编译阶段将大操作分解为多个小操作

```
高层 linalg 操作
    ↓
    │ Tiling Pass
    ↓
嵌套循环结构（scf.for/affine.for）
    ↓
后续优化和下降
```

**特点**:
- 作用在**中间表示（IR）**层面
- 生成**循环嵌套**（Loop structure）
- 是**编译优化**的一个步骤
- **与硬件无关**（可生成CPU或GPU代码）

**MLIR 分块代码示例**（生成的IR）：
```mlir
scf.for %m = 0 to M step 32 {          // tile_m = 32
  scf.for %n = 0 to N step 32 {        // tile_n = 32
    scf.for %k = 0 to K step 64 {      // tile_k = 64
      %A_tile = memref.subview %A[%m, %k][32, 64][1, 1]
      %B_tile = memref.subview %B[%k, %n][64, 32][1, 1]
      %C_tile = memref.subview %C[%m, %n][32, 32][1, 1]
      linalg.matmul ins(%A_tile, %B_tile) outs(%C_tile)
    }
  }
}
```

---

### Triton Tiling（GPU编程抽象）

**定义**: 在GPU编程模型中，用Block（多维数据块）作为执行和编程的基本单位

```
Triton Python 代码
    ↓
    │ AST解析
    ↓
Triton-IR（Block级操作）
    ↓
自动优化和并行化
    ↓
LLVM-IR → PTX → GPU 执行
```

**特点**:
- 是**编程语言**本身的特性
- 提供**Block级别原语**（tl.load, tl.store, tl.dot等）
- **自动处理**内存合并、共享内存、线程级同步
- **GPU专用**（目前仅支持NVIDIA）

**Triton 分块代码示例**（用户代码）：
```python
@triton.jit
def matmul_kernel(A, B, C, M, N, K, stride_am, stride_ak, stride_bk, stride_bn, stride_cm, stride_cn, **META):
    # 提取元参数（分块大小）
    BLOCK_M = META['BLOCK_M']   # 如 64
    BLOCK_N = META['BLOCK_N']   # 如 64
    BLOCK_K = META['BLOCK_K']   # 如 32
    
    # 获取线程块ID
    pid_m = tl.program_id(0)
    pid_n = tl.program_id(1)
    
    # 计算该线程块处理的行列范围
    rm = pid_m * BLOCK_M + tl.arange(0, BLOCK_M)      # Block中所有行索引
    rn = pid_n * BLOCK_N + tl.arange(0, BLOCK_N)      # Block中所有列索引
    rk = tl.arange(0, BLOCK_K)                        # 深度索引
    
    # 计算内存地址（向量化）
    A = A + (rm[:, None] * stride_am + rk[None, :] * stride_ak)
    B = B + (rk[:, None] * stride_bk + rn[None, :] * stride_bn)
    
    # 累加器初始化
    acc = tl.zeros((BLOCK_M, BLOCK_N), dtype=tl.float32)
    
    # K维循环（在GPU内部展开）
    for k in range(K, 0, -BLOCK_K):
        a = tl.load(A)                      # 自动合并内存，放到共享内存
        b = tl.load(B)
        acc += tl.dot(a, b)                 # Block级矩阵乘法
        A += BLOCK_K * stride_ak            # 指针跳跃
        B += BLOCK_K * stride_bk
    
    # 存储结果
    C = C + (rm[:, None] * stride_cm + rn[None, :] * stride_cn)
    tl.store(C, acc)
```

---

## 2️⃣ 分块粒度与目标

### MLIR Tiling：多维数据分块

**目标**: 优化**数据访问和缓存局部性**

```
矩阵 C (M×N)
┌─────────────────┐
│ Tile Tile Tile  │
│ (32×32) × 3     │
│ Tile Tile Tile  │
│ Tile Tile Tile  │
└─────────────────┘

分块方式：C 分成 (M/32) × (N/32) 个大小为 32×32 的块
```

**应用场景**:
- L1/L2 缓存优化（CPU）
- DRAM → Local Memory 优化（GPU）
- Tiling后可继续应用其他优化（循环融合、向量化）

---

### Triton Tiling：GPU执行单元映射

**目标**: 将**计算任务映射到GPU的执行单元**

```
GPU 执行模型：
┌─────────────────────────────────────┐
│ GPU（多个流多处理器 SM）            │
├─────────────────────────────────────┤
│ SM 0      SM 1      SM 2    ...     │
├─────┬─────┼─────┬─────┼──────┤     │
│Block│Block│Block│Block│Block │ ...  │
│ 0,0 │ 0,1 │ 1,0 │ 1,1 │      │     │
└─────┴─────┴─────┴─────┴──────┘     │
       ↓
    每个Block内部：
    (BLOCK_M × BLOCK_N) 个线程
    执行矩阵乘法
```

**应用场景**:
- 线程块映射和调度
- 共享内存管理
- Tensor Core 调用（对于高性能）

---

## 3️⃣ 编程模型对比

### MLIR Tiling：声明式变换

```cpp
// 配置分块大小
LinalgTilingOptions opts;
opts.setTileSizes({32, 32, 64});

// 应用 Pass
mlir-opt input.mlir -linalg-tiling -tile-sizes=32,32,64

// 输出：自动生成嵌套循环
```

**优点**:
- ✅ 简单声明式
- ✅ 自动生成高效循环结构
- ✅ 编译器可以进行后续优化
- ✅ 与硬件无关

**缺点**:
- ❌ 难以微调硬件特定优化
- ❌ 对GPU的线程块、共享内存等GPU特性控制有限

---

### Triton Tiling：编程语言级别

```python
# 用户直接指定分块大小（元参数）
@triton.jit
def matmul(A, B, C, ..., **META):
    BLOCK_M = META['BLOCK_M']
    BLOCK_N = META['BLOCK_N']
    BLOCK_K = META['BLOCK_K']
    
    # 用户写 Block 级操作
    # 编译器自动处理：
    # - 内存合并
    # - 共享内存分配
    # - 线程同步
```

**优点**:
- ✅ 明确的GPU执行模型（program_id, blocks）
- ✅ 自动处理复杂的GPU优化（内存合并、共享内存）
- ✅ 用户可自由编写计算逻辑
- ✅ 代码量少（25行实现高效matmul）

**缺点**:
- ❌ 需要理解GPU编程模型
- ❌ 仅限NVIDIA GPU
- ❌ 手动调参（BLOCK_M, BLOCK_N, BLOCK_K）

---

## 4️⃣ 内存管理方式

### MLIR Tiling：手动/自动混合

```mlir
// 生成的 scf.for 循环中：
scf.for %m = ... {
  scf.for %n = ... {
    // 需要手动通过 subview 提取分块
    %A_tile = memref.subview %A[%m, %k][32, 64][1, 1]
    %B_tile = memref.subview %B[%k, %n][64, 32][1, 1]
    
    // 内存优化需要额外的 pass（如 bufferization）
    // 共享内存分配也需要额外处理
  }
}
```

**特点**:
- 需要额外的 bufferization 和 GPU-specific lowering pass
- 由后续 pass 决定是否使用GPU共享内存

---

### Triton Tiling：完全自动

```python
@triton.jit
def matmul(..., **META):
    # tl.load 自动：
    # 1. 检查内存访问模式
    # 2. 优化内存合并
    # 3. 自动分配共享内存
    # 4. 插入必要的同步
    a = tl.load(A)  # 智能处理！
    b = tl.load(B)
    
    # Triton编译器后端自动执行上述优化
```

**特点**:
- Triton编译器的核心价值
- 程序员专注于逻辑，不需要手动优化

---

## 5️⃣ 实现复杂度对比

### 同样的矩阵乘法

#### MLIR 方式（不含优化pass）
```
代码行数：～100+ 行（生成的循环嵌套）
+ 需要额外的 bufferization
+ 需要 GPU lowering pass
+ 需要内存优化和调度
```

#### Triton 方式
```python
@triton.jit
def matmul(A, B, C, M, N, K, stride_am, stride_ak,
           stride_bk, stride_bn, stride_cm, stride_cn, **META):
    BLOCK_M, BLOCK_N, BLOCK_K = META['BLOCK_M'], META['BLOCK_N'], META['BLOCK_K']
    pid_m = tl.program_id(0)
    pid_n = tl.program_id(1)
    rm = pid_m * BLOCK_M + tl.arange(0, BLOCK_M)
    rn = pid_n * BLOCK_N + tl.arange(0, BLOCK_N)
    rk = tl.arange(0, BLOCK_K)
    A = A + (rm[:, None] * stride_am + rk[None, :] * stride_ak)
    B = B + (rk[:, None] * stride_bk + rn[None, :] * stride_bn)
    acc = tl.zeros((BLOCK_M, BLOCK_N), dtype=tl.float32)
    for k in range(K, 0, -BLOCK_K):
        a = tl.load(A)
        b = tl.load(B)
        acc += tl.dot(a, b)
        A += BLOCK_K * stride_ak
        B += BLOCK_K * stride_bk
    C = C + (rm[:, None] * stride_cm + rn[None, :] * stride_cn)
    tl.store(C, acc)
    
# 总计：～25 行！
```

---

## 6️⃣ 性能特性对比

### MLIR Tiling 的性能优化方式

```
linalg.matmul
    ↓
分块（Tiling）→ 生成循环嵌套
    ↓
循环融合（Fusion）→ 减少内存访问
    ↓  
向量化（Vectorization）→ 使用SIMD
    ↓
循环交换（Interchange）→ 优化缓存
    ↓
最终高效代码
```

**优化层级**: 编译器自动化，但需要配置多个pass

---

### Triton 的性能优化方式

```
Triton 代码（Block语义）
    ↓
Triton-IR（分析数据流）
    ↓
自动共享内存分配 → 自动内存合并
    ↓
自动线程分配 → 自动同步
    ↓
LLVM-IR → PTX
    ↓
高性能GPU代码
```

**优化层级**: 编译器一站式处理，用户很少干预

---

## 7️⃣ 适用场景总结

### 选择 MLIR Tiling

✅ 需要**跨平台编译**（CPU和GPU）
✅ 已有复杂的**张量算法框架**
✅ 需要**多层次优化控制**
✅ **数据流分析**重要
✅ 集成到现有编译基础设施

**示例**: IREE、XLA、JAX后端

---

### 选择 Triton

✅ **仅针对NVIDIA GPU**
✅ 需要**极致性能**（Tensor Core等）
✅ 不想手写繁琐的GPU代码
✅ **快速原型**很重要
✅ **可读性**和**简洁性**优先

**示例**: PyTorch custom kernels、xFormers、vLLM

---

## 8️⃣ 技术栈对比

### MLIR Tiling 技术栈

```
应用层：PyTorch → TensorFlow → etc
    ↓
高层IR：Linalg 方言
    ↓
分块变换：Tiling Pass
    ↓
循环IR：SCF/Affine 方言
    ↓
优化：多个Pass（融合、向量化等）
    ↓
目标IR：LLVM IR
    ↓
代码生成：LLVM Backend
    ↓
执行：CPU/GPU
```

---

### Triton 技术栈

```
应用层：PyTorch custom kernel
    ↓
用户代码：Triton Python
    ↓
AST解析：生成 Triton-IR
    ↓
分析优化：Block级别分析
    ↓
自动优化：内存管理、线程分配
    ↓
目标IR：LLVM IR
    ↓
代码生成：NVVM Backend
    ↓
执行：NVIDIA GPU
```

---

## 9️⃣ 实际代码示例：同一算法的两种实现

### 问题：计算 C += A × B (128×128×256)，tile_size=[64,64,32]

#### MLIR 方式
```cpp
// C++ 代码配置和调用
LinalgTilingOptions opts;
opts.setTileSizes({64, 64, 32});

// 应用到 linalg.matmul
auto result = tileLinalgOp(rewriter, matmulOp, opts);

// 生成的 MLIR（简化）：
scf.for %m = 0 to 128 step 64 {      // 2 次迭代
  scf.for %n = 0 to 128 step 64 {    // 2 次迭代
    scf.for %k = 0 to 256 step 32 {  // 8 次迭代
      %A_tile = memref.subview %A[%m, %k][64, 32]
      %B_tile = memref.subview %B[%k, %n][32, 64]
      %C_tile = memref.subview %C[%m, %n][64, 64]
      linalg.matmul ins(%A_tile, %B_tile) outs(%C_tile)
    }
  }
}
// 总计分块：2×2×8 = 32 个分块计算
```

#### Triton 方式
```python
import triton
import triton.language as tl

@triton.jit
def matmul_block(A, B, C, M, N, K, 
                stride_am, stride_ak, stride_bk, stride_bn, stride_cm, stride_cn,
                BLOCK_M: tl.constexpr, BLOCK_N: tl.constexpr, BLOCK_K: tl.constexpr):
    """
    Block size: BLOCK_M=64, BLOCK_N=64, BLOCK_K=32
    Grid: (M//64, N//64) = (2, 2)
    每个Block处理一个 64×64 输出块
    """
    pid_m = tl.program_id(0)
    pid_n = tl.program_id(1)
    
    # 该Block处理的行列范围
    rm = pid_m * BLOCK_M + tl.arange(0, BLOCK_M)  # [0-64) 或 [64-128)
    rn = pid_n * BLOCK_N + tl.arange(0, BLOCK_N)  # [0-64) 或 [64-128)
    rk = tl.arange(0, BLOCK_K)
    
    # 指针计算
    A = A + (rm[:, None] * stride_am + rk[None, :] * stride_ak)
    B = B + (rk[:, None] * stride_bk + rn[None, :] * stride_bn)
    C = C + (rm[:, None] * stride_cm + rn[None, :] * stride_cn)
    
    # K维循环（在GPU线程块内）
    acc = tl.zeros((BLOCK_M, BLOCK_N), dtype=tl.float32)
    for k in range(K, 0, -BLOCK_K):  # 8 次迭代
        a = tl.load(A)               # 64×32 块，自动合并
        b = tl.load(B)               # 32×64 块，自动合并
        acc += tl.dot(a, b)          # Block级矩阵乘法
        A += BLOCK_K * stride_ak
        B += BLOCK_K * stride_bk
    
    # 边界检查和存储
    mask = (rm[:, None] < M) & (rn[None, :] < N)
    tl.store(C, acc, mask=mask)

# 启动内核
grid = (128 // 64, 128 // 64)  # (2, 2) blocks
matmul_block[grid](A, B, C, 128, 128, 256, ...)
```

---

## 🔟 关键差异速查表

| 特性         | MLIR           | Triton          |
| ------------ | -------------- | --------------- |
| **抽象**     | 编译IR变换     | GPU编程语言     |
| **编程**     | 声明式配置     | 命令式编程      |
| **分块粒度** | 数据块（多维） | GPU线程块       |
| **内存管理** | 手动+编译器    | 完全自动        |
| **平台支持** | CPU/GPU通用    | NVIDIA GPU专用  |
| **性能**     | 需要多pass组合 | 一站式优化      |
| **易用性**   | 需要懂编译器   | 需要懂GPU模型   |
| **代码量**   | 生成的IR较多   | 用户代码简洁    |
| **调试**     | 可查看中间IR   | 需要GPU调试工具 |
| **学习曲线** | 陡峭           | 中等            |

---

## 总结

### 本质区别

**MLIR Tiling** = **编译优化技术**
- 在编译阶段**分解计算**
- 生成**更好的循环结构**
- 为后续优化铺路

**Triton Tiling** = **编程抽象**
- 在**编程模型**中内置分块概念
- **自动化**硬件优化的复杂细节
- 用户用Block思维编程

### 何时使用

- **MLIR**: 构建通用编译器/框架 (IREE, XLA, JAX)
- **Triton**: 快速写高性能GPU内核 (PyTorch custom ops, vLLM)

两者并非竞争关系，而是**不同层级的抽象**：
- MLIR 是**低级编译器基础**
- Triton 是**高级GPU编程语言**

