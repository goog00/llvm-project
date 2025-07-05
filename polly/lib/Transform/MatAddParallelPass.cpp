#include "polly/DependenceInfo.h"
#include "polly/PolyhedralInfo.h"
#include "polly/ScopInfo.h"
#include "polly/Support/GICHelper.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Pass.h"
#include "llvm/Support/Debug.h"
#include "isl/schedule.h"
#include "isl/schedule_node.h"
#include "polly/LinkAllPasses.h"

using namespace llvm;
using namespace polly;

#define DEBUG_TYPE "matadd-parallel"

namespace {

class MatAddParallelPass : public FunctionPass {
public:
    static char ID;
    MatAddParallelPass() : FunctionPass(ID) {}

    bool runOnFunction(Function &F) override {
        auto *SI = getAnalysis<ScopInfoWrapperPass>().getSI();
        auto &DI= getAnalysis<DependenceInfoWrapperPass>();
        // LLVM IR 中的 LoopInfo 分析
        auto &LI = getAnalysis<LoopInfoWrapperPass>().getLoopInfo();
        // 并行性分析（PolyhedralInfo）
        auto &PI = getAnalysis<PolyhedralInfo>();

       

        //遍历函数中的SCOP
        for(auto &It : *SI){
            Scop *S = It.second.get();
            if (!S || S->isToBeSkipped()) {
                continue;
            }

            LLVM_DEBUG(dbgs() << "Processing SCop in region: " << It.first->getNameStr() << "\n");
            
            //获取依赖信息（语句级） : AL_Statement
            const Dependences &Deps = DI.getDependences(S, Dependences::AL_Statement);
            LLVM_DEBUG({
                dbgs() << "Dependences for Scop:\n";
                Deps.print(dbgs());
            });

            //检查循环并行性
            for(auto *TopLevelLoop : LI) {
                for (auto *L : depth_first(TopLevelLoop)) {
                    if (S->contains(L)){
                        bool IsParallel = PI.isParallel(L);
                        LLVM_DEBUG(dbgs() << "Loop " << L->getHeader()->getName() << " is " << (IsParallel ? "parallel" : "not parallel") << "\n");
                    }
                }
            }

            // 调度优化
            // 获取原始调度树
            isl::schedule Schedule = S->getScheduleTree();
            // LLVM_DEBUG(dbgs() << "Original Schedule: " << stringFromIslObj(Schedule.get()) << "\n");
            LLVM_DEBUG({
                dbgs() << "Original Schedule Summary:\n";
                isl::union_set Domain = S->getDomains();
                dbgs() << "  Domain: " << stringFromIslObj(Domain.get()) << "\n";
            });

            // 优化调度： 标记外层循环为并行
            isl_schedule_node *Node = isl_schedule_get_root(Schedule.get());
            Node = isl_schedule_node_child(Node,0);//
            bool IsPermutable = false;
            if(isl_schedule_node_get_type(Node) == isl_schedule_node_band) {
                //标记外层循环为可交换
                Node = isl_schedule_node_band_set_permutable(Node, 1);
                Node = isl_schedule_node_band_member_set_coincident(Node, 0, isl_bool_true);
                IsPermutable = true;
            }
            Schedule = isl::manage(isl_schedule_node_get_schedule(Node));
            isl_schedule_node_free(Node);
            //更新Scop的调度树
            S->setSchedule(Schedule.get_map());
            // LLVM_DEBUG(dbgs() << "Optimized Schedule: " << stringFromIslObj(Schedule.get()) << "\n");
            // 输出优化后的调度摘要
            LLVM_DEBUG({
                dbgs() << "Optimized Schedule Summary:\n";
                 isl::union_set Domain = S->getDomains();
                dbgs() << "  Domain: " << stringFromIslObj(Domain.get()) << "\n";
                dbgs() << "  Statements: " << S->getSize() << "\n";
                dbgs() << "  Permutable: " << (IsPermutable ? "Yes" : "No") << "\n";
                dbgs() << "  Coincident: " << (IsPermutable ? "Yes" : "No") << "\n";
            });

        }

        return false;// 不修改IR

    }


    void print(raw_ostream &OS, const Module *) const  override {
        auto *SI = getAnalysis<ScopInfoWrapperPass>().getSI();
        auto &DI = getAnalysis<DependenceInfoWrapperPass>();
        auto &PI = getAnalysis<PolyhedralInfo>();
     

        for (auto &It : *SI){
            Scop *S = It.second.get();
            if(!S || S->isToBeSkipped()){
                continue;
            }

            OS << "SCoP in region: " << It.first->getNameStr() << "\n";
            DI.getDependences(S, Dependences::AL_Statement).print(OS);
            PI.print(OS, nullptr);
            OS << "Schedule: " << stringFromIslObj(S->getSchedule().get()) << "\n\n";

        }
    }

    void getAnalysisUsage(AnalysisUsage &AU) const override {
        AU.addRequired<ScopInfoWrapperPass>();
        AU.addRequired<DependenceInfoWrapperPass>();
        AU.addRequired<LoopInfoWrapperPass>();
        AU.addRequired<PolyhedralInfo>();
        // 表明不修改任何 IR 或分析结果。
        AU.setPreservesAll();
    }

};



} // namespace

char MatAddParallelPass::ID;

// 注册 Pass



Pass *polly::createMatAddParallelPass() {
  MatAddParallelPass *pass = new MatAddParallelPass();
  return pass;
}

INITIALIZE_PASS_BEGIN(
    MatAddParallelPass, "matadd-parallel",
    "Polly - Parallelize matrix addition loops.", false,
    false)
INITIALIZE_PASS_END(
    MatAddParallelPass, "matadd-parallel",
    "Polly - Parallelize matrix addition loops.", false,
    false)
