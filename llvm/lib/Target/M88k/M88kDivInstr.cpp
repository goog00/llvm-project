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

class M88kBuilder {
  MachineBasicBlock *MBB;          // 指向当前正在操作的基本块（MachineBasicBlock）。
  MachineBasicBlock::iterator I;   // 当前指令插入位置的迭代器，初始为基本块的末尾。
  const DebugLoc &DL;              // 调试位置信息，用于指令生成时的调试信息记录。

  const TargetInstrInfo &TII;      // 目标指令信息（Target Instruction Info），提供生成目标指令的接口。
  const TargetRegisterInfo &TRI;   // 目标寄存器信息（Target Register Info），提供寄存器相关信息和操作的接口。
  const RegisterBankInfo &RBI;     // 寄存器库信息（Register Bank Info），提供寄存器库相关的管理和查询功能。

public:
  // 构造函数：初始化 M88kBuilder 类的成员变量
  // - Pass: 传入的 M88kDivInstr 对象，包含了 TII、TRI 和 RBI 的引用。
  // - MBB: 当前操作的基本块。
  // - DL: 调试位置信息。
  M88kBuilder(M88kDivInstr &Pass, MachineBasicBlock *MBB, const DebugLoc &DL)
        : MBB(MBB), I(MBB->end()), DL(DL), TII(*Pass.TII), TRI(*Pass.TRI),
          RBI(*Pass.RBI) {}

  // setMBB：设置新的基本块并重置指令插入点为新基本块的末尾
  void setMBB(MachineBasicBlock *NewMBB) {
    MBB = NewMBB;
    I = MBB->end();
  } 

  // constrainInst：限制机器指令的寄存器操作数，使其符合目标架构的约束
  void constrainInst(MachineInstr *MI) {
    // 使用 constrainSelectedInstRegOperands 函数对指令的寄存器操作数进行约束检查
    if(!constrainSelectedInstRegOperands(*MI, TII, TRI, RBI))
      llvm_unreachable("Could not constrain register operands"); // 如果约束失败，则抛出错误
  }

  // bcnd：生成一个条件分支指令，并将其插入到当前基本块中
  MachineInstr *bcnd(CC0 Cc, Register Reg, MachineBasicBlock *TargetMBB) {
    // 构建 BCND 指令，带有条件代码（Cc）、寄存器（Reg）和目标基本块（TargetMBB）
    MachineInstr *MI = BuildMI(*MBB, I, DL, TII.get(M88k::BCND))
                        .addImm(static_cast<int64_t>(Cc)) // 添加条件码作为立即数操作数
                        .addReg(Reg)                      // 添加寄存器操作数
                        .addMBB(TargetMBB);               // 添加目标基本块操作数
    constrainInst(MI);                                    // 对指令的寄存器操作数施加约束
    return MI;                                            // 返回生成的指令
  }
   
  // trap503：生成一个 TRAP503 指令，用于触发 503 向量的陷阱
  MachineInstr *trap503(Register Reg) {
    // 构建 TRAP503 指令，带有一个寄存器操作数
    MachineInstr *MI = BuildMI(*MBB, I, DL, TII.get(M88k::TRAP503))
                        .addReg(Reg);                     // 添加寄存器操作数
    constrainInst(MI);                                    // 对指令的寄存器操作数施加约束
    return MI;                                            // 返回生成的指令
  }

};


} // end anonymous namespace 


void M88kDivInstr::addZeroDivCheck(MachineBasicBlock &MBB,
                                   MachineInstr *DivInst) {
    assert(DivInst->getOpcode() == M88k::DIVSrr || DivInst->getOpcode() == M88k::DIVUrr && "unexpected opcode");
    MachineBasicBlock *TailBB = MBB.splitAt(*DivInst);
    M88kBuilder B(*this, &MBB, DivInst->getDebugLoc());
    B.bcnd(CC0::NE0, DivInst->getOperand(2).getReg(),TailBB);
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

  for(MachineBasicBlock &MBB : reverse(MF))
     Changed |= runOnMachineBasicBlock(MBB);

  return Changed;   

}

bool M88kDivInstr::runOnMachineBasicBlock(MachineBasicBlock &MBB) {

  bool Changed = false;

  for (MachineBasicBlock::reverse_instr_iterator I = MBB.instr_rbegin(); 
                I != MBB.instr_rend(); ++I) {

      unsigned Opc = I->getOpcode();

      if((Opc == M88k::DIVUrr || Opc == M88k::DIVSrr) && AddZeroDivCheck) {
        
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
