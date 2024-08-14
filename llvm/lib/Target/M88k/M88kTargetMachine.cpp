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
#include "llvm/CodeGen/GlobalISel/IRTranslator.h"
#include "llvm/CodeGen/GlobalISel/InstructionSelect.h"
#include "llvm/CodeGen/GlobalISel/Legalizer.h"
#include "llvm/CodeGen/GlobalISel/RegBankSelect.h"
#include "llvm/CodeGen/Passes.h"
#include "llvm/CodeGen/TargetLoweringObjectFileImpl.h"
#include "llvm/CodeGen/TargetPassConfig.h"
#include "llvm/IR/LegacyPassManager.h"
#include "llvm/MC/TargetRegistry.h"

using namespace llvm;

static cl::opt<bool>
        NoZeroDivCheck("m88k-no-check-zero-division", 
                        cl::Hidden, cl::desc("M88k: Don't trap on integer division by zero."),
                        cl::init(false));

extern "C" LLVM_EXTERNAL_VISIBILITY void LLVMInitializeM88kTarget() {
    //Register the target
    RegisterTargetMachine<M88kTargetMachine> X(getTheM88kTarget());
    auto &PR = *PassRegistry::getPassRegistry();
    initializeM88kDAGToDAGISelPass(PR);
    initializeM88kDvInstrPass(PR);
}

M88kTargetMachine::~M88kTargetMachine() {}

bool M88kTargetMachine::noZeroDivCheck() const {return NoZeroDivCheck; }



namespace {

class M88kPassConfig : public TargetPassConfig {

public:
    M88kPassConfig(M88kTargetMachine &TM,
                   PassManagerBase &PM)
          : TargetPassConfig(TM, PM) {}
    bool addInstSelector() override;
    void addPreEmitPass() override;

    void addMachineSSAOptimization() override;


} ;
} //namespace 


void M88kPassConfig::addMachineSSAOptimization() {
  addPass(createM88kDivInstr(getTM<M88kTargetMachine>()));
  TargetPassConfig::addMachineSSAOptimization();
}
