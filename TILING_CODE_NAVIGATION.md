# Tiling.cpp 代码导航地图

## 文件快速索引

```
mlir/lib/Dialect/Linalg/Transforms/Tiling.cpp (883 行)

第1-45行:       头文件、命名空间、宏定义
第47-73行:      ⭐ makeTiledLoopRanges() - 生成分块循环范围
第75-88行:      ⭐ transformIndexOps() - 索引变换  
第89-103行:     emitIsPositiveIndexAssertion() - 验证分块大小
第104-250行:    linalgOpToLoopsImpl() - 核心分块实现
第251-330行:    emitScalarImplementation() - 标量计算
第333-341行:    canOmitTileOffsetInBoundsCheck() - 优化检查
第342-360行:    ⭐ calculateTileOffsetsAndSizes() - 计算偏移和大小
第361-370行:    buildMax() / buildMin() - AffineMap 构建
第371-450行:    tileToForallOpImpl() - 分块到 forall 循环
第451-550行:    并行分布相关函数
第550-700行:    其他助手函数
第700-883行:    Pass 定义和寄存
```

---

## 1️⃣ 入口函数 - makeTiledLoopRanges()

**位置**: 第 47-73 行
**调用链**: `tiling transformation` → `makeTiledLoopRanges()` → `scf.for` 生成

```cpp
std::tuple<SmallVector<Range, 4>, LoopIndexToRangeIndexMap>
mlir::linalg::makeTiledLoopRanges(RewriterBase &b, Location loc, AffineMap map,
                                  ArrayRef<OpFoldResult> allShapeSizes,
                                  ArrayRef<OpFoldResult> allTileSizes)
```

### 流程图
```
输入：
  ├─ allShapeSizes: [M=128, N=128, K=256]
  ├─ allTileSizes: [32, 32, 64]
  └─ map: 维度映射

处理步骤：
  1. 应用 map 到 shapeSizes
  2. 移除 tile_size=0 的维度（跳过不分块的维度）
  3. 为每个维度创建 Range
  
输出：
  ├─ ranges: [Range{0, 128, 32}, Range{0, 128, 32}, Range{0, 256, 64}]
  └─ loopIndexToRangeIndex: 维度映射表
```

### 关键代码片段

```cpp
// 第 51-59 行：处理 tile_size=0（不分块维度）
SmallVector<OpFoldResult> shapeSizes =
    makeComposedFoldedMultiResultAffineApply(b, loc, map, allShapeSizes);
SmallVector<OpFoldResult> tileSizes(allTileSizes);

// 移除零 tile size
LoopIndexToRangeIndexMap loopIndexToRangeIndex;
for (int idx = 0, e = tileSizes.size(), zerosCount = 0; idx < e; ++idx) {
  if (getConstantIntValue(tileSizes[idx - zerosCount]) == 0) {
    shapeSizes.erase(shapeSizes.begin() + idx - zerosCount);
    tileSizes.erase(tileSizes.begin() + idx - zerosCount);
    ++zerosCount;
  }
  // 记录映射: 原始索引 → 实际循环索引
  loopIndexToRangeIndex[idx] = idx - zerosCount;
}

// 第 67-69 行：创建 Range（循环范围）
SmallVector<Range, 4> res;
for (unsigned idx = 0; idx < tileSizes.size(); ++idx)
  res.push_back(Range{b.getIndexAttr(0), shapeSizes[idx], tileSizes[idx]});
```

---

## 2️⃣ 核心计算 - calculateTileOffsetsAndSizes()

**位置**: 第 362-450 行
**调用**：来自 `tileToForallOpImpl()` 或其他分块策略
**作用**：在 forall 循环体中计算每个分块的实际偏移和大小

```cpp
static void calculateTileOffsetsAndSizes(
    RewriterBase &b,                              // IR 构建器
    Location loc,
    scf::ForallOp forallOp,                      // 分块循环操作
    ArrayRef<OpFoldResult> numThreads,           // 线程数（GPU 场景）
    SmallVector<Range> loopRanges,               // 循环范围
    bool omitTileOffsetBoundsCheck,              // 优化标志
    std::optional<ArrayRef<OpFoldResult>> nominalTileSizes,  // 期望分块大小
    SmallVector<OpFoldResult> &tiledOffsets,     // 输出：分块偏移
    SmallVector<OpFoldResult> &tiledSizes)       // 输出：分块大小
```

### 核心算法

```cpp
// 第 368-376 行：遍历每个循环维度
SmallVector<Value> threadIds = forallOp.getInductionVars();
int64_t nLoops = loopRanges.size();
tiledOffsets.reserve(nLoops);
tiledSizes.reserve(nLoops);

for (unsigned loopIdx = 0, threadIdIdx = 0; loopIdx < nLoops; ++loopIdx) {
  bool overflow = loopIdx >= numThreads.size();
  bool isZero = !overflow && isZeroInteger(numThreads[loopIdx]);
  
  // 计算偏移：threadId * nominalSize
  // 计算大小：min(nominalSize, remaining)
}
```

### 关键概念：min 和 max 计算

```cpp
// 处理边界情况，需要使用 affine.min
OpFoldResult tileSizeMin = buildMin(b, loc, {
  nominalTileSize,                    // 期望大小（如 32）
  remaining = dimension_size - offset // 剩余大小
});
```

---

## 3️⃣ 循环生成 - linalgOpToLoopsImpl()

**位置**: 第 104-250 行
**调用链**: Pass → `tileLinalgOp()` → `linalgOpToLoopsImpl()`
**作用**: 为每个维度生成嵌套的 scf.for 或 affine.for 循环

```cpp
template <typename LoopType>
static FailureOr<LinalgLoops>
linalgOpToLoopsImpl(RewriterBase &rewriter, LinalgOp linalgOp) {
  // LoopType = scf::ForOp 或 affine::AffineForOp
}
```

### 简化流程

```cpp
// 第 120-150 行：构建循环结构
LinalgLoops loops;
for (unsigned i = 0; i < ranges.size(); ++i) {
  // 创建一个新的 scf.for 循环
  auto loop = rewriter.create<scf::ForOp>(
      loc, lowerBounds[i], upperBounds[i], steps[i], ...);
  
  // 进入循环体
  rewriter.setInsertionPointToStart(loop.getBody(0));
  
  loops.push_back(loop);
}

// 第 160+ 行：在最内层循环体生成标量计算
if (i == ranges.size() - 1) {
  // 最内层：生成 load、计算、store
  emitScalarImplementation(rewriter, linalgOp, ...);
}
```

---

## 4️⃣ 标量计算生成 - emitScalarImplementation()

**位置**: 第 251-330 行
**调用**: 从 `linalgOpToLoopsImpl()` 的最内层循环
**作用**: 为分块生成实际的标量计算代码

```cpp
template <typename LoadOpTy, typename StoreOpTy>
static void emitScalarImplementation(OpBuilder &b, Location loc,
                                     ArrayRef<Value> allIvs,
                                     LinalgOp linalgOp)
```

### 生成步骤

```
1. Load 输入 (第 260-270 行)
   ├─ 对每个输入，计算索引
   └─ 生成 memref.load 操作

2. 执行计算 (第 280-300 行)
   ├─ 如果是通用 linalg.generic，执行其 region
   └─ 如果是具体操作（matmul），直接计算
   
3. Store 输出 (第 310-320 行)
   ├─ 对每个输出，计算索引
   └─ 生成 memref.store 操作
```

---

## 5️⃣ 索引处理 - transformIndexOps()

**位置**: 第 75-88 行
**调用**: 从分块后处理循环中
**作用**: 将 linalg.index 操作转换为循环归纳变量

```cpp
void mlir::linalg::transformIndexOps(
    RewriterBase &b, 
    LinalgOp op, 
    SmallVectorImpl<Value> &ivs,  // 循环的归纳变量
    const LoopIndexToRangeIndexMap &loopIndexToRangeIndex)
```

### 工作原理

```
输入：
  ├─ ivs: [%m, %n, %k]  (循环归纳变量)
  └─ loopIndexToRangeIndex: {0→0, 2→1}  (维度0和2使用)

输出：
  所有 linalg.index op 被替换为对应的 iv
  
例：
  %idx_m = linalg.index 0  →  %m
  %idx_k = linalg.index 2  →  %k
```

---

## 6️⃣ Pass 定义

**位置**: 第 750-883 行

### LinalgTilingPass

```cpp
struct LinalgTilingPass
    : public impl::LinalgTilingPassBase<LinalgTilingPass> {
  
  // 选项：tile-sizes（从命令行读取）
  SmallVector<int64_t> tileSizesList;
  
  void runOnOperation() override {
    // 获取 module
    auto module = getOperation();
    
    // 对每个 function 应用分块
    module.walk([&](func::FuncOp func) {
      func.walk([&](LinalgOp op) {
        // 为该 op 应用分块
        tileLinalgOp(rewriter, op, options);
      });
    });
  }
};
```

---

## 数据流总结

```
用户输入:
  ├─ linalg 操作（如 matmul）
  ├─ 分块大小配置（LinalgTilingOptions）
  └─ 可选的索引映射、循环类型

         ↓

makeTiledLoopRanges:
  ├─ 输入: shapeSizes, tileSizes, indexingMap
  ├─ 处理: 应用 map，移除零分块
  └─ 输出: Range 集合，维度映射表

         ↓

linalgOpToLoopsImpl:
  ├─ 为每个 Range 创建 scf.for
  ├─ 嵌套循环结构
  └─ 进入最内层循环体

         ↓

calculateTileOffsetsAndSizes (可选):
  ├─ 计算线程/块的分块偏移
  ├─ 使用 affine.min 处理边界
  └─ 生成 subview 操作

         ↓

emitScalarImplementation:
  ├─ 生成 load（使用计算出的索引）
  ├─ 执行区域计算或直接操作
  └─ 生成 store

         ↓

输出:
  分块后的 MLIR 代码
  ├─ scf.for 嵌套
  ├─ memref.subview 提取分块
  └─ 标量 load/compute/store
```

---

## 快速检查点

### 如何追踪分块操作？

1. **找到 tiling pass 的入口**:
   ```bash
   grep -n "struct LinalgTilingPass" Tiling.cpp
   # → 第 760 行
   ```

2. **找到核心分块函数**:
   ```bash
   grep -n "linalgOpToLoopsImpl" Tiling.cpp
   # → 第 104 行
   ```

3. **查看如何处理边界**:
   ```bash
   grep -n "calculateTileOffsetsAndSizes" Tiling.cpp
   # → 第 362 行
   ```

4. **查看标量生成**:
   ```bash
   grep -n "emitScalarImplementation" Tiling.cpp
   # → 第 251 行

---

## 常见问题排查

| 问题           | 检查位置                                    |
| -------------- | ------------------------------------------- |
| 分块大小不对   | makeTiledLoopRanges 第 51-69 行             |
| 边界处理有问题 | calculateTileOffsetsAndSizes 第 380-420 行  |
| 索引计算错误   | emitScalarImplementation 第 270-290 行      |
| 循环顺序不对   | interchangeVector 处理 (搜索 "interchange") |
| 性能下降       | 检查 canOmitTileOffsetBoundsCheck 第 333 行 |

