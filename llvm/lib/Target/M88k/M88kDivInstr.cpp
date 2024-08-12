//===-- M88kDelaySlotFiller.cpp - Delay Slot Filler for M88k --------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// Special pass to handle division instructions on MC88100:
//
// - If TM.noZeroDivCheck() returns false then additional code is inserted to
//   check for zero division after signed and unsigned divisions.
//
// These changes are necessary due to some hardware limitations. The MC88100
// CPU does not reliable detect division by zero, so an additional check is
// required. The signed division instruction traps into the OS if any of the
// operands are negative. The OS handles this situation transparently but
// trapping into kernel mode is expensive. Therefore the instruction is replaced
// with an inline version using the unsigned division instruction.
//
// Both issues are fixed on the MC88110 CPU, and no code is changed if code for
// it is generated.
//
//===----------------------------------------------------------------------===//

#include "M88k.h"
#include "M88kInstrInfo.h"
#include "M88kTargetMachine.h"
#include "MCTargetDesc/M88kMCTargetDesc.h"
#include "llvm/ADT/Statistic.h"
#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/CodeGen/MachineFunctionPass.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/MachineRegisterInfo.h"
#include "llvm/IR/Instructions.h"
#include "llvm/Support/Debug.h"

#define DEBUG_TYPE "m88k-div-instr"

using namespace llvm;

STATISTIC(InsertedChecks, "Number of inserted checks for division by zero");

namespace {

enum class CC0 : unsigned {
  EQ0 = 0x2,
  NE0 = 0xd,
  GT0 = 0x1,
  LT0 = 0xc,
  GE0 = 0x3,
  LE0 = 0xe
};

class M88kDivInstr : public MachineFunctionPass {
  friend class M88kBuilder;

  const M88kTargetMachine *TM;
  const TargetInstrInfo *TII;
  const TargetRegisterInfo *TRI;
  const RegisterBankInfo *RBI;
  MachineRegisterInfo *MRI;

  bool AddZeroDivCheck;

public:
  static char ID;

  M88kDivInstr(const M88kTargetMachine *TM = nullptr);

  MachineFunctionProperties getRequiredProperties() const override;

  bool runOnMachineFunction(MachineFunction &MF) override;

  bool runOnMachineBasicBlock(MachineBasicBlock &MBB);

private:
  void addZeroDivCheck(MachineBasicBlock &MBB, MachineInstr *DivInst);
};

// Specialiced builder for m88k instructions.
class M88kBuilder {
  MachineBasicBlock *MBB;
  MachineBasicBlock::iterator I;
  const DebugLoc &DL;

  const TargetInstrInfo &TII;
  const TargetRegisterInfo &TRI;
  const RegisterBankInfo &RBI;

public:
  M88kBuilder(M88kDivInstr &Pass, MachineBasicBlock *MBB, const DebugLoc &DL)
      : MBB(MBB), I(MBB->end()), DL(DL), TII(*Pass.TII), TRI(*Pass.TRI),
        RBI(*Pass.RBI) {}

  void setMBB(MachineBasicBlock *NewMBB) {
    MBB = NewMBB;
    I = MBB->end();
  }

  void constrainInst(MachineInstr *MI) {
    if (!constrainSelectedInstRegOperands(*MI, TII, TRI, RBI))
      llvm_unreachable("Could not constrain register operands");
  }

  MachineInstr *bcnd(CC0 Cc, Register Reg, MachineBasicBlock *TargetMBB) {
    MachineInstr *MI = BuildMI(*MBB, I, DL, TII.get(M88k::BCND))
                           .addImm(static_cast<int64_t>(Cc))
                           .addReg(Reg)
                           .addMBB(TargetMBB);
    constrainInst(MI);
    return MI;
  }

  MachineInstr *trap503(Register Reg) {
    MachineInstr *MI = BuildMI(*MBB, I, DL, TII.get(M88k::TRAP503)).addReg(Reg);
    constrainInst(MI);
    return MI;
  }
};

} // end anonymous namespace

// Inserts a check for division by zero after the div instruction.
// MI must point to a DIVSrr or DIVUrr instruction.
void M88kDivInstr::addZeroDivCheck(MachineBasicBlock &MBB,
                                   MachineInstr *DivInst) {
  assert(DivInst->getOpcode() == M88k::DIVSrr ||
         DivInst->getOpcode() == M88k::DIVUrr && "Unexpected opcode");
  MachineBasicBlock *TailBB = MBB.splitAt(*DivInst);
  M88kBuilder B(*this, &MBB, DivInst->getDebugLoc());
  B.bcnd(CC0::NE0, DivInst->getOperand(2).getReg(), TailBB);
  B.trap503(DivInst->getOperand(2).getReg());
  ++InsertedChecks;
}

M88kDivInstr::M88kDivInstr(const M88kTargetMachine *TM)
    : MachineFunctionPass(ID), TM(TM) {
  initializeM88kDivInstrPass(*PassRegistry::getPassRegistry());
}

MachineFunctionProperties M88kDivInstr::getRequiredProperties() const {
  return MachineFunctionProperties().set(
      MachineFunctionProperties::Property::IsSSA);
}

bool M88kDivInstr::runOnMachineFunction(MachineFunction &MF) {
  const M88kSubtarget &Subtarget = MF.getSubtarget<M88kSubtarget>();

  TII = Subtarget.getInstrInfo();
  TRI = Subtarget.getRegisterInfo();
  RBI = Subtarget.getRegBankInfo();
  MRI = &MF.getRegInfo();

  AddZeroDivCheck = !TM->noZeroDivCheck();

  bool Changed = false;
  // Iterating in reverse order avoids newly inserted MBBs.
  for (MachineBasicBlock &MBB : reverse(MF))
    Changed |= runOnMachineBasicBlock(MBB);

  return Changed;
}

bool M88kDivInstr::runOnMachineBasicBlock(MachineBasicBlock &MBB) {
  bool Changed = false;

  for (MachineBasicBlock::reverse_instr_iterator I = MBB.instr_rbegin();
       I != MBB.instr_rend(); ++I) {
    unsigned Opc = I->getOpcode();
    if ((Opc == M88k::DIVUrr || Opc == M88k::DIVSrr) && AddZeroDivCheck) {
      // Add the check only for the 2-register form of the instruction.
      // The immediate of the register-immediate version should never be zero!
      addZeroDivCheck(MBB, &*I);
      Changed = true;
    }
  }
  return Changed;
}

char M88kDivInstr::ID = 0;
INITIALIZE_PASS(M88kDivInstr, DEBUG_TYPE, "Handle div instructions", false,
                false)

namespace llvm {
FunctionPass *createM88kDivInstr(const M88kTargetMachine &TM) {
  return new M88kDivInstr(&TM);
}
} // end namespace llvm
