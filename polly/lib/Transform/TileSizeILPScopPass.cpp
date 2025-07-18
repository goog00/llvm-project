
#include "polly/DependenceInfo.h"
#include "polly/PolyhedralInfo.h"
#include "polly/ScopInfo.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Pass.h"
#include "llvm/Support/Debug.h"
#include "polly/Support/ISLOStream.h"
#include "isl/isl-noexceptions.h"
#include "polly/LinkAllPasses.h"
#include <vector>
#include <string>

// 定义调试类型，用于控制调试输出的范围
#define DEBUG_TYPE "tile-size-ilp"

using namespace llvm;
using namespace polly;

namespace {

// 定义一个 FunctionPass，用于在 Polly 中为 SCoP（静态控制部分）选择 tile 大小
class TileSizeILPScopPass : public FunctionPass {
public:
    static char ID; // Pass 的唯一标识符
    TileSizeILPScopPass() : FunctionPass(ID) {}

    // 主函数：在每个函数上运行 Pass，分析 SCoP 并为循环选择 tile 大小
    bool runOnFunction(Function &F) override {
        // 输出调试信息，表明 Pass 被调用
        errs() << "TileSizeILPScopPass invoked!\n";

        // 获取 Polly 的 SCoP 信息
        auto *SI = getAnalysis<ScopInfoWrapperPass>().getSI();
        // 遍历函数中所有检测到的 SCoP
        for (auto &It : *SI) {
            Scop *S = It.second.get();
            // 输出当前 SCoP 的区域名称
            errs() << "  SCoP region: " << It.first->getNameStr();
            // 检查 SCoP 是否有效
            if (!S) {
                errs() << "    SCoP pointer null!\n";
                continue;
            }
            // 调试模式下打印 SCoP 的详细信息（包括指令）
            LLVM_DEBUG(S->print(dbgs(), true));

            // 输出 SCoP 的语句数量和最大循环深度
            errs() << ", size = " << S->getSize() << ", max loop depth = " << S->getMaxLoopDepth() << "\n";
            // 如果 SCoP 没有语句，跳过处理
            if (S->getSize() == 0) {
                errs() << "    SCoP empty (no statements).\n";
                continue;
            }
            // 获取 SCoP 的最大循环深度
            unsigned Depth = S->getMaxLoopDepth();
            // 确保循环深度至少为 2（矩阵乘法通常需要 2 或 3 层循环）
            if (Depth < 2) {
                errs() << "    SCoP too shallow, max loop depth = " << Depth << ".\n";
                continue;
            }

            // 获取 ISL 上下文，用于构建约束和目标函数
            isl_ctx *ctx = S->getIslCtx().get();
            // 创建一个具有 Depth 维度的集合空间（每个维度表示一个 tile 大小）
            isl_space *space = isl_space_set_alloc(ctx, 0, Depth);
            // 创建一个初始的约束集，表示整个整数空间
            isl_basic_set *bset = isl_basic_set_universe(isl_space_copy(space));
            // 创建局部空间，用于定义约束
            isl_local_space *ls = isl_local_space_from_space(isl_space_copy(space));
            // 存储 tile 变量名称（如 tile_0, tile_1）
            std::vector<std::string> tileVarNames;

            // 为每个循环维度设置 tile 大小约束：4 ≤ tile_i ≤ 512
            for (unsigned i = 0; i < Depth; ++i) {
                // 创建变量名 tile_i
                std::string name = "tile_" + std::to_string(i);
                tileVarNames.push_back(name);
                // 为维度分配一个唯一标识符
                isl_id *id = isl_id_alloc(ctx, name.c_str(), nullptr);
                isl_space_set_dim_id(space, isl_dim_set, i, id);
                // 注意：这里未释放 id，可能导致内存泄漏，后续需修复

                // 添加约束：tile_i >= 4
                isl_constraint *c1 = isl_inequality_alloc(isl_local_space_copy(ls));
                isl_constraint_set_coefficient_si(c1, isl_dim_set, i, 1);
                isl_constraint_set_constant_si(c1, -4); // 表示 tile_i - 4 >= 0
                bset = isl_basic_set_add_constraint(bset, c1);

                // 添加约束：tile_i <= 512
                isl_constraint *c2 = isl_inequality_alloc(isl_local_space_copy(ls));
                isl_constraint_set_coefficient_si(c2, isl_dim_set, i, -1);
                isl_constraint_set_constant_si(c2, 512); // 表示 -tile_i + 512 >= 0
                bset = isl_basic_set_add_constraint(bset, c2);
            }

            // 添加内存约束：假设 L1 缓存为 128KB，限制 tile 大小以适应缓存
            if (Depth >= 2) {
                // 约束：8 * tile_0 ≤ 131072（假设 double 类型占 8 字节）
                isl_constraint *cmem0 = isl_inequality_alloc(isl_local_space_copy(ls));
                isl_constraint_set_coefficient_si(cmem0, isl_dim_set, 0, 8);
                isl_constraint_set_constant_si(cmem0, -131072); // 8*tile_0 - 131072 <= 0
                bset = isl_basic_set_add_constraint(bset, cmem0);

                // 约束：8 * tile_1 ≤ 131072
                isl_constraint *cmem1 = isl_inequality_alloc(isl_local_space_copy(ls));
                isl_constraint_set_coefficient_si(cmem1, isl_dim_set, 1, 8);
                isl_constraint_set_constant_si(cmem1, -131072); // 8*tile_1 - 131072 <= 0
                bset = isl_basic_set_add_constraint(bset, cmem1);

                // 注释掉的约束：8 * tile_0 * tile_1 ≤ 131072
                // 此约束可能导致约束集无解，暂时禁用以调试
                /*
                isl_constraint *cmem2 = isl_inequality_alloc(isl_local_space_copy(ls));
                isl_constraint_set_coefficient_si(cmem2, isl_dim_set, 0, 8);
                isl_constraint_set_coefficient_si(cmem2, isl_dim_set, 1, 8);
                isl_constraint_set_constant_si(cmem2, -131072);
                bset = isl_basic_set_add_constraint(bset, cmem2);
                */
            }

            // 定义目标函数：最大化 tile_0 + tile_1 + ... + tile_{Depth-1}
            isl_aff *obj = isl_aff_zero_on_domain(isl_local_space_copy(ls));
            for (unsigned i = 0; i < Depth; ++i) {
                isl_aff_set_coefficient_si(obj, isl_dim_in, i, 1); // 设置每个维度的系数为 1
            }

            // 调试：打印最终的约束集
            errs() << "[TileSizeILPScopPass] Constraint set: " << stringFromIslObj(bset) << "\n";

            // 求解 ILP：寻找最大化目标函数的可行解
            isl_set *bset_set = isl_basic_set_to_set(isl_basic_set_copy(bset));
            if (isl_set_is_empty(bset_set)) {
                // 如果约束集为空，说明约束矛盾（如 { [i0, i1] : 1 = 0 }）
                errs() << "[TileSizeILPScopPass] Constraint set is empty (no feasible solutions)!\n";
                isl_set_free(bset_set);
            } else {
                // 使用 lexmax 求解最大值集合
                isl_set *max_set = isl_set_lexmax(bset_set);
                if (isl_set_is_empty(max_set)) {
                    errs() << "[TileSizeILPScopPass] Lexmax set is empty!\n";
                    isl_set_free(max_set);
                } else {
                    // 从最大值集合中采样一个点
                    isl_point *pt = isl_set_sample_point(max_set);
                    if (pt && !isl_point_is_void(pt)) {
                        // 获取点的空间并检查维度
                        isl_space *pt_space = isl_point_get_space(pt);
                        if (isl_space_dim(pt_space, isl_dim_set) == Depth) {
                            errs() << "[TileSizeILPScopPass] Optimal tile assignment:\n";
                            // 提取每个维度的 tile 大小
                            for (unsigned i = 0; i < Depth; ++i) {
                                isl_val *v = isl_point_get_coordinate_val(pt, isl_dim_set, i);
                                errs() << "  " << tileVarNames[i] << " = " << isl_val_to_str(v) << "\n";
                                isl_val_free(v);
                            }
                        } else {
                            // 如果维度不匹配，输出错误信息
                            errs() << "[TileSizeILPScopPass] Point dimension mismatch: expected " << Depth
                                   << ", got " << isl_space_dim(pt_space, isl_dim_set) << "\n";
                        }
                        isl_space_free(pt_space);
                        isl_point_free(pt);
                    } else {
                        // 如果点无效或约束过于严格，输出错误
                        errs() << "[TileSizeILPScopPass] No feasible tile sizes (invalid point or constraints too tight)\n";
                        if (pt) isl_point_free(pt);
                    }
                    isl_set_free(max_set);
                }
                isl_set_free(bset_set);
            }

            // 释放 ISL 资源，防止内存泄漏
            isl_aff_free(obj);
            isl_basic_set_free(bset);
            isl_local_space_free(ls);
            isl_space_free(space);
        }
        // 返回 false，表示 Pass 未修改函数
        return false;
    }

    // 打印 Pass 的输出信息，主要用于调试
    void print(raw_ostream &OS, const Module *) const override {
        auto *SI = getAnalysis<ScopInfoWrapperPass>().getSI();
        for (auto &It : *SI) {
            Scop *S = It.second.get();
            if (!S || S->getSize() == 0) continue;
            OS << "SCoP in region: " << It.first->getNameStr() << "\n";
            OS << "Schedule: " << stringFromIslObj(S->getSchedule().get()) << "\n\n";
        }
    }

    // 定义 Pass 依赖，声明需要 ScopInfoWrapperPass
    void getAnalysisUsage(AnalysisUsage &AU) const override {
        AU.addRequired<ScopInfoWrapperPass>();
        AU.setPreservesAll();
    }
};

} // namespace

// 初始化 Pass ID
char TileSizeILPScopPass::ID;

// 创建 Pass 的工厂函数
Pass *polly::createTileSizeILPScopPass() {
    return new TileSizeILPScopPass();
}

// 注册 Pass
INITIALIZE_PASS_BEGIN(
    TileSizeILPScopPass, "tile-size-ilp",
    "Polly - Tile Size ILP selection for SCoP (ICS21, LLVM18+)", false, false)
INITIALIZE_PASS_END(
    TileSizeILPScopPass, "tile-size-ilp",
    "Polly - Tile Size ILP selection for SCoP (ICS21, LLVM18+)", false, false)

static RegisterPass<TileSizeILPScopPass>
    X("tile-size-ilp", "Polly - Tile Size ILP selection for SCoP (ICS21, LLVM18+)", false, false);