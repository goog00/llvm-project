# Tiling.cpp 阅读指南

## 文件概览
- **位置**: `mlir/lib/Dialect/Linalg/Transforms/Tiling.cpp` (883 行)
- **功能**: 实现 linalg 操作的分块（Tiling）变换

---

## 核心概念

### 什么是 Tiling（分块）？
将大的操作分成多个小的分块进行计算，有利于：
1. **缓存优化** - 让数据更好地适应 L1/L2 缓存
2. **并行化** - 分块可以并行执行
3. **向量化** - 每个分块可以使用 SIMD 指令

### 例子：
```
原始 matmul (M x N x K):
  A[M, K] × B[K, N] → C[M, N]

分块后（tile_size = 64）：
  for m in 0..M step 64:
    for n in 0..N step 64:
      for k in 0..K step 64:
        C[m:m+64, n:n+64] += A[m:m+64, k:k+64] × B[k:k+64, n:n+64]
```

---

## 文件结构

### 1️⃣ **分块配置结构** (第190-260行)
📄 文件: `mlir/include/mlir/Dialect/Linalg/Transforms/Transforms.h`

```cpp
struct LinalgTilingOptions {
  // 分块大小计算函数
  TileSizeComputationFunction tileSizeComputationFunction;
  
  // 设置固定分块大小（如 [32, 32, 64]）
  setTileSizes(ArrayRef<int64_t> ts);
  
  // 循环交换顺序
  SmallVector<unsigned, 4> interchangeVector;
  
  // 循环类型：scf.for vs affine.for
  LinalgTilingLoopType loopType;
  
  // 并行化分布选项
  std::optional<LinalgLoopDistributionOptions> distribution;
  
  // 循环剥离（处理边界情况）
  SmallVector<int64_t> peeledLoops;
};
```

---

### 2️⃣ **关键函数 - 分块大小计算** (第345-390行)

#### `calculateTileOffsetsAndSizes()` - 核心算法 ⭐⭐⭐
**作用**: 为每个分块计算偏移量和大小

```cpp
static void calculateTileOffsetsAndSizes(
    RewriterBase &b,                      // IR 构建器
    Location loc,
    scf::ForallOp forallOp,              // 分块循环
    ArrayRef<OpFoldResult> numThreads,   // 线程数（用于分布式）
    SmallVector<Range> loopRanges,       // 原始循环范围
    bool omitTileOffsetBoundsCheck,
    std::optional<ArrayRef<OpFoldResult>> nominalTileSizes,  // 名义分块大小
    SmallVector<OpFoldResult> &tiledOffsets,  // 输出：每个分块的起始位置
    SmallVector<OpFoldResult> &tiledSizes);   // 输出：每个分块的实际大小
```

**关键概念**：
- `nominalTileSizes`: 期望的分块大小（如 64）
- `tiledOffsets`: 实际分块在全局数组中的起始位置
- `tiledSizes`: 实际分块的大小（边界分块可能更小）

---

### 3️⃣ **Range 和循环结构** (第47-73行)

#### `makeTiledLoopRanges()` - 生成分块循环范围

```cpp
std::tuple<SmallVector<Range, 4>, LoopIndexToRangeIndexMap>
makeTiledLoopRanges(
    RewriterBase &b,
    Location loc,
    AffineMap map,                    // 索引映射
    ArrayRef<OpFoldResult> allShapeSizes,  // 维度大小 [M, N, K]
    ArrayRef<OpFoldResult> allTileSizes);  // 分块大小 [32, 32, 64]
```

**返回值**:
```
Range {
  offset: 0,           // 分块起始位置
  size: shapeSize,     // 当前维度的大小
  step: tileSize       // 分块大小
}
```

**示例**：
```
输入：
  shapeSize = [128, 128, 128]  (M, N, K)
  tileSize = [32, 32, 64]

输出范围（3个循环）：
  Loop 0 (m): 0 to 128 step 32  → 4 次迭代
  Loop 1 (n): 0 to 128 step 32  → 4 次迭代  
  Loop 2 (k): 0 to 128 step 64  → 2 次迭代
```

---

### 4️⃣ **辅助工具函数** (第333-363行)

| 函数                               | 作用                   |
| ---------------------------------- | ---------------------- |
| `canOmitTileOffsetInBoundsCheck()` | 检查是否需要边界检查   |
| `buildMax()`                       | 生成 `affine.max` 操作 |
| `buildMin()`                       | 生成 `affine.min` 操作 |
| `emitIsPositiveIndexAssertion()`   | 验证分块大小为正       |

---

### 5️⃣ **Pass 实现** (第356-373行)

```cpp
struct LinalgTilingPass
    : public impl::LinalgTilingPassBase<LinalgTilingPass> {
  
  // 使用的分块大小配置
  SmallVector<int64_t> tileSizesList;
  
  void runOnOperation() {
    // 对每个 linalg 操作应用分块
  }
};
```

---

## 阅读顺序建议

### 快速上手（30分钟）
1. ✅ 了解 `LinalgTilingOptions` (Transforms.h:190-260)
2. ✅ 理解 `makeTiledLoopRanges()` (Tiling.cpp:47-73)
3. ✅ 看测试用例理解效果

### 深入理解（2小时）
1. ✅ `calculateTileOffsetsAndSizes()` - 核心算法
2. ✅ `emitScalarImplementation<>()` - 标量计算
3. ✅ `transformIndexOps()` - 索引变换
4. ✅ 循环生成和剥离逻辑

### 完全掌握（1天）
- 研究边界条件处理
- 学习并行化分布
- 学习循环交换和剥离

---

## 关键数据结构

### Range（循环范围）
```cpp
struct Range {
  OpFoldResult offset;  // 起始值
  OpFoldResult size;    // 范围大小
  OpFoldResult step;    // 步长（分块大小）
};
```

### TileSizeComputationFunction
```cpp
using TileSizeComputationFunction =
    std::function<SmallVector<Value, 4>(OpBuilder &, Operation *)>;
```
- **参数**: OpBuilder 用于创建新 IR，Operation 是当前操作
- **返回**: 动态计算的分块大小值列表

---

## 测试文件

查看这些测试文件理解实际用法：
- `mlir/test/Dialect/Linalg/tile-*.mlir` - 不同场景的分块测试
- `mlir/test/Examples/Toy/Ch5/` - Toy 教程中的分块示例

---

## 常见操作

### 设置固定分块大小
```cpp
LinalgTilingOptions opts;
opts.setTileSizes({32, 32, 64});  // 固定大小
```

### 动态计算分块大小
```cpp
opts.setTileSizeComputationFunction([](OpBuilder &b, Operation *op) {
  return SmallVector<Value>{
    createConstantIndex(b, 32),
    createConstantIndex(b, 32),
    createConstantIndex(b, 64)
  };
});
```

### 循环交换
```cpp
opts.setInterchange({2, 0, 1});  // k, m, n 顺序
```

### 并行分布（GPU）
```cpp
LinalgLoopDistributionOptions distOptions;
distOptions.procInfo = procInfoFn;
opts.setDistributionOptions(distOptions);
```

---

## 常见问题

**Q: 分块大小为什么很重要？**
A: 分块大小直接影响缓存效率。太小性能差，太大会溢出缓存。通常选择 L2 缓存大小的平方根。

**Q: 什么时候需要 `peeledLoops`？**
A: 当 M, N, K 不能被分块大小整除时，需要处理剩余元素（边界分块）。

**Q: `interchangeVector` 的作用？**
A: 改变循环嵌套顺序以优化缓存局部性（如改进 TLB 命中率）。

