# Tiling 实际例子详解

## 示例 1：基础矩阵乘法分块

### 原始代码（未分块）
```mlir
linalg.matmul ins(%A: memref<?x?xf32>, %B: memref<?x?xf32>)
             outs(%C: memref<?x?xf32>)
```

**矩阵尺寸**: 
- A: 128×256 (M×K)
- B: 256×128 (K×N)
- C: 128×128 (M×N)

---

### 分块配置
```cpp
LinalgTilingOptions opts;
opts.setTileSizes({32, 32, 64});  // [tile_m, tile_n, tile_k]
```

---

### 分块后的效果（概念图）

#### 原始矩阵视图：
```
A[128×256]:              B[256×128]:           C[128×128]:
┌─────────────┐         ┌─────────────┐       ┌───────────┐
│             │         │             │       │           │
│  128 rows   │  ×      │ 128 cols    │   =   │ C result  │
│             │         │             │       │           │
└─────────────┘         └─────────────┘       └───────────┘
  256 cols               256 rows              128 rows
```

#### 分块迭代次数：
```
M dimension (128 rows):  128 ÷ 32 = 4 个分块
N dimension (128 cols):  128 ÷ 32 = 4 个分块  
K dimension (256 depth): 256 ÷ 64 = 4 个分块

总计: 4 × 4 × 4 = 64 个分块计算
```

#### 嵌套循环结构：
```cpp
scf.for %m = 0 to 128 step 32 {         // 0, 32, 64, 96
  scf.for %n = 0 to 128 step 32 {       // 0, 32, 64, 96
    scf.for %k = 0 to 256 step 64 {     // 0, 64, 128, 192
      // 计算: C[m:m+32, n:n+32] += A[m:m+32, k:k+64] × B[k:k+64, n:n+32]
      
      // 提取子数组（分块）
      %A_tile = memref.subview %A[%m, %k][32, 64][1, 1]
      %B_tile = memref.subview %B[%k, %n][64, 32][1, 1]
      %C_tile = memref.subview %C[%m, %n][32, 32][1, 1]
      
      // 对分块进行矩阵乘法
      linalg.matmul ins(%A_tile, %B_tile) outs(%C_tile)
    }
  }
}
```

---

## 示例 2：带边界条件的分块

### 非对齐分块（Misaligned Tiling）

**矩阵尺寸**:
- A: 100×100 (不能整除 32)
- 分块大小: 32

```
第一个分块:  0   32    64    96   100
           ├─────┼─────┼─────┼──┤
           |block|block|block|B | B = 边界分块 (4×100)
           │ 32  │ 32  │ 32  │4 │

分块迭代:
  100 ÷ 32 = 3 个完整分块 + 1 个边界分块
  = 4 次迭代
```

#### 计算每次迭代的实际大小（来自 Tiling.cpp）

```cpp
// 伪代码展示 calculateTileOffsetsAndSizes 的逻辑

for iteration i in 0..3:
  // 分块起始位置
  tile_offset[i] = i * 32
  
  // 实际分块大小（边界需要缩小）
  remaining = 100 - tile_offset[i]
  tile_size[i] = min(32, remaining)

// 结果：
// i=0: offset=0,   size=32   (完整分块)
// i=1: offset=32,  size=32   (完整分块)
// i=2: offset=64,  size=32   (完整分块)
// i=3: offset=96,  size=4    (边界分块)
```

---

## 示例 3：多维分块的 Range 表达

### 3D 操作（batch matmul）

```mlir
linalg.batch_matmul ins(%A: tensor<?x?x?xf32>, %B: tensor<?x?x?xf32>)
                   outs(%C: tensor<?x?x?xf32>)
```

**维度**: [batch=8, M=256, N=256, K=256]
**分块大小**: [1, 64, 64, 64]

#### makeTiledLoopRanges 的输出

```cpp
Range ranges[4] = {
  // Batch 维度（不分块，tile_size=1）
  Range {offset: 0, size: 8,   step: 1},
  
  // M 维度
  Range {offset: 0, size: 256, step: 64},
  
  // N 维度  
  Range {offset: 0, size: 256, step: 64},
  
  // K 维度
  Range {offset: 0, size: 256, step: 64}
};
```

#### 生成的循环嵌套

```mlir
scf.for %b = 0 to 8 step 1 {
  scf.for %m = 0 to 256 step 64 {
    scf.for %n = 0 to 256 step 64 {
      scf.for %k = 0 to 256 step 64 {
        // 计算 C[b, m:m+64, n:n+64] += A[b, m:m+64, k:k+64] × B[b, k:k+64, n:n+64]
      }
    }
  }
}
```

---

## 示例 4：循环交换（Interchange）

### 原始循环顺序

```cpp
opts.setTileSizes({32, 32, 64});      // [m, n, k] 顺序
// 默认循环: m, n, k
```

```mlir
scf.for %m = 0 to M step 32 {
  scf.for %n = 0 to N step 32 {
    scf.for %k = 0 to K step 64 {
      // 缓存利用率较差（k 循环在最内层，导致频繁访问 B）
    }
  }
}
```

### 交换循环顺序优化缓存

```cpp
opts.setTileSizes({32, 32, 64});
opts.setInterchange({2, 0, 1});       // 交换为 [k, m, n]
```

```mlir
scf.for %k = 0 to K step 64 {         // k 放到最外层
  scf.for %m = 0 to M step 32 {       // m 在中间
    scf.for %n = 0 to N step 32 {     // n 在最内层
      // 缓存利用率更好
      // 原因：A 的 k 维在最外层循环中固定，
      //      B 的 k 维也在最外层中固定，
      //      只有 n 维在最内层变化
    }
  }
}
```

---

## 示例 5：循环剥离（Peeling）处理边界

### 问题场景

矩阵大小 M=100，分块大小 32，无法整除：

```
需要分离处理：
1. 完整分块 (0..64): 两次迭代，每次 32 行
2. 边界分块 (64..100): 一次迭代，4 行
```

### 剥离配置

```cpp
opts.setTileSizes({32, 32, 64});
opts.setPeeledLoops({0});              // 对 m 维进行剥离
```

### 生成的结构

```mlir
// 完整分块循环（快速路径）
scf.for %m = 0 to 96 step 32 {         // 0, 32, 64
  scf.for %n = 0 to N step 32 {
    scf.for %k = 0 to K step 64 {
      // 矩阵乘法，每个分块大小固定为 32×32
    }
  }
}

// 剥离的边界分块（特殊处理）
scf.for %m = 96 to 100 step 4 {        // 96
  scf.for %n = 0 to N step 32 {
    scf.for %k = 0 to K step 64 {
      // 矩阵乘法，分块大小为 4×32（特殊处理）
    }
  }
}
```

---

## 关键取值规律总结

### 分块大小选择（实践规则）

```
L1 缓存: ~32 KB
L2 缓存: ~256 KB
L3 缓存: ~8 MB

matmul 分块大小建议:
  对于 float32 (4 字节):
  - 64×64×64 对应 4×256×256 = 256 KB (L2)
  - 32×32×32 对应 4×32×32×3 ≈ 12 KB (L1)
```

### 边界分块大小计算

```cpp
remaining = dimension_size - (iterations * tile_size)
final_tile_size = min(tile_size, remaining)

例: dim=100, tile_size=32
  iter 0: size = min(32, 100-0)   = 32
  iter 1: size = min(32, 100-32)  = 32
  iter 2: size = min(32, 100-64)  = 32
  iter 3: size = min(32, 100-96)  = 4  ← 边界分块
```

---

## 测试命令

```bash
# 运行分块测试
mlir-opt mlir/test/Dialect/Linalg/tile-offset.mlir \
         -transform-interpreter -split-input-file

# 查看分块的 MLIR 输出
mlir-opt your_file.mlir \
         -transform-interpreter \
         -mlir-print-op-generic  # 查看详细 IR
```

