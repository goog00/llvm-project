//===-- M88kTargetMachine.cpp - Define TargetMachine for M88k ---*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
//
//===----------------------------------------------------------------------===//



#include "M88kTargetMachine.h"
#include "M88k.h"
#include "TargetInfo/M88kTargetInfo.h"
#include "llvm/CodeGen/Passes.h"
#include "llvm/CodeGen/TargetLoweringObjectFileImpl.h"
#include "llvm/CodeGen/TargetPassConfig.h"
#include "llvm/IR/LegacyPassManager.h"
#include "llvm/MC/TargetRegistry.h"



using namespace llvm;

extern "C" LLVM_EXTERNAL_VISIBILITY void LLVMInitializeM88kTarget() {
    //register the target
    RegisterTargetMachine<M88kTargetMachine> X(getTheM88kTarget());
    auto &PR = *PassRegistry::getPassRegistry();
    initializeM88kDAGToDAGISelPass(PR);
}

namespace {
    //todo: check
std::string computeDataLayout(const Triple &TT, StringRef CPU, StringRef FS) {
    std::string Ret;

    //Big endian
    Ret += "E";

    //data mangling
    Ret += DataLayout::getManglingComponent(TT);

    //Pointer are 32 bit
    Ret += "-p:32:8:32";

    //Make sure that global data has at least 16 bits of alignment by default,
    // so that we can refer to it using larl, we don't have any 
    // special requirements for stack variables though
    Ret += "-i1:8:16:-i8:8:16";

    //64-bit intergers are naturally aligned
    Ret += "-i64:64";

    //128-bit floats are aligned only to 64 bits 
    Ret += "-f128:64";

    // we prefer 16 bits of aligned for all globals; see above.
    Ret += "-n32";

    return Ret;


}   


Reloc::Model getEffectiveRelocModel(std::optional<Reloc::Model> RM) {
    if(!RM || *RM == Reloc::DynamicNoPIC) 
       return Reloc::Static;

    return *RM;   
}

M88kTargetMachine::M88kTargetMachine(const Target &T,
                                     const Triple &TT,
                                     StringRef CPU,
                                     StringRef FS,
                                     const TargetOptions &Options,
                                     std::optional<Reloc::Model> RM,
                                     std::optional<CodeModel::Model> CM,
                                     CodeGenOpt::Level OL, bool JIT)
        : LLVMTargetMachine(T, computeDataLayout(TT, CPU, FS), TT, CPU, FS, Options,
                            getEffectiveRelocModel(RM),
                            getEffectiveCodeModel(CM, CodeModel::Medium), OL),
           TLOF(std::make_unique<TargetLoweringObjectFileELF>()) {
    
    initAsmInfo();
}                 


M88kTargetMachine::~M88kTargetMachine() {}

const M88kSubtarget * M88kTargetMachine::getSubtargetImpl(const Function &F) const {
    Attribute CPUAttr = F.getFnAttribute("target-cpu");
    Attribute FSAttr = F.getFnAttribute("target-features");

    std::string CPU = !CPUAttr.hasAttribute(Attribute::None)
                      ? CPUAttr.getValueAsString().str() : TargetCPU;

    std::string FS = !FSAttr.hasAttribute(Attribute::None) 
                     ? FSAttr.getValueAsString().str()
                     : TargetFS;

    auto &I = SubtargetMap[CPU + FS];    
    if(!I) {
        //this needs to be done before we create a new subtarget since any 
        //creation will depend on the TM and the code generation flags on the function
        // that reside in  TargetOptions
        resetTargetOptions(F);
        I = std::make_unique<M88kSubtarget>(TargetTriple, CPU, FS, *this);
    }    

    return I.get();                    
}


namespace {

class M88kPassConfig : public TargetPassConfig {

public:
  M88kPassConfig(M88kTargetMachine &TM, PassManagerBase &PM) : TargetPassConfig(TM, PM) {}
  
  M88kTargetMachine &getM88kTargetMachine() const {
    return getTM<M88kTargetMachine>();
  }   

  bool addInstSelector() override;
  void addPreEmitPass() override;

} ; 

} // namespace 

TargetPassConfig *M88kTargetMachine::createPassConfig(PassManagerBase &PM) {
    return new M88kPassConfig(*this, PM);
}

bool M88kPassConfig::addInstSelector() {
    addPass(createM88kISelDag(getM88kTargetMachine(),getOptLevel()));
    return false;
}

void M88kPassConfig::addPreEmitPass() {
    //TODO Add pass for div-by-zero check
}





} // end of namespace 