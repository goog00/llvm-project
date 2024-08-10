//===-- M88kISelLowering.cpp - M88k DAG lowering implementation -----===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file implements the M88kTargetLowering class.
//
//===----------------------------------------------------------------------===//


#include "M88kISelLowering.h"
#include "M88kSubtarget.h"
#include "MCTargetDesc/M88kMCTargetDesc.h"
#include "llvm/CodeGen/CallingConvLower.h"
#include "llvm/CodeGen/MachineRegisterInfo.h"
#include "llvm/CodeGen/TargetLoweringObjectFileImpl.h"
#include <cstdint>


using namespace llvm;

#define DEBUG_TYPE "m88k-lower"

M88kTargetLowering::M88kTargetLowering(const TargetMachine &TM,
                                       const M88kSubtarget &STI)
                 : TargetLowering(TM), Subtarget(STI) {
    addRegisterClass(MVT::i32, &M88k::GPRRegClass);
    // addRegisterClass(MVT::f32, &M88k::GPRRegClass);
    // addRegisterClass(MVT::f64, &M88k::GPR64RegClass);

    //compute derived properties from the register classes
    computeRegisterProperties(Subtarget.getRegisterInfo());

    //set up special registers
    setStackPointerRegisterToSaveRestore(M88k::R31);

    // how we extend i1 boolean values
    setBooleanContents(ZeroOrOneBooleanContent);


    setMinFunctionAlignment(Align(4));
    setPrefFunctionAlignment(Align(4));

    setOperationAction(ISD::AND, MVT::i32, Legal);
    setOperationAction(ISD::OR, MVT::i32, Legal);
    setOperationAction(ISD::XOR, MVT::i32, Legal);
    setOperationAction(ISD::CTPOP, MVT::i32, Expand);

}





//===----------------------------------------------------------------------===//
// Calling conventions
//===----------------------------------------------------------------------===//

#include "M88kGenCallingConv.inc"

SDValue M88kTargetLowering::LowerFormalArguments(
    SDValue Chain, CallingConv::ID CallConv,
    bool IsVarArg,
    const SmallVectorImpl<ISD::InputArg> &Ins,
    const SDLoc &DL, SelectionDAG &DAG,
    SmallVectorImpl<SDValue> &InVals) const {

   MachineFunction &MF = DAG.getMachineFunction();
   MachineRegisterInfo &MRI = MF.getRegInfo();

   SmallVector<CCValAssign, 16> ArgLocs;
    
   CCState CCInfo(CallConv, IsVarArg, MF, ArgLocs, *DAG.getContext());

   CCInfo.AnalyzeFormalArguments(Ins, CC_M88k);

   for (unsigned I = 0, E = ArgLocs.size(); I != E; ++I) {
      SDValue ArgValue;
      CCValAssign &VA = ArgLocs[I];
      EVT LocVT = VA.getLocVT();
      if(VA.isRegLoc()) {
        const TargetRegisterClass *RC;
        switch (LocVT.getSimpleVT().SimpleTy) {
        default:
            llvm_unreachable("Unexpected argument type");
        case MVT:i32:
          RC = &M88k::GPRRegClass;
          break;    
        }

        Register VReg = MRI.createVirtualRegister(RC);
        MRI.addLiveIn(VA.getLocReg(),VReg);
        ArgValue = DAG.getCopyFromReg(Chain, DL, VReg, LocVT);

        // If this is an 8/16-bit value, it is really passed promoted to 32 bits.
        // Insert an assert[sz]ext to capture this,then truncate to the right size.

        if(VA.getLocInfo() == CCValAssign::SExt) 
          ArgValue = DAG.getNode(ISD::AssertSext, DL, LocVT, ArgValue, 
                                DAG.getValueType(VA.getValVT()));
        else if (VA.getLocInfo() != CCValAssign::Full)
          ArgValue = DAG.getNode(ISD::TRUNCATE, DL, VA.getValVT(), ArgValue);


        InVals.push_back(ArgValue);                         


      } else {
        assert(VA.isMemLoc() && "Argment not register or meory");
        llvm_unreachable(  "M88k - LowerFormalArguments - "
         "Memory argument not implemented"
        );
      }

   
   }

    if (IsVarArg) {
        llvm_unreachable("M88k - LowerFormalArguments - "
                     "VarArgs not Implemented");
    }

    return Chain;

}

SDValue M88kTargetLowering::LowerReturn(
    SDValue Chain, CallingConv::ID CallConv,
    bool IsVarArg,
    const SmallVectorImpl<ISD::OutputArg> &Outs,
    const SmallVectorImpl<SDValue> &OutVals,
    const SDLoc &DL, SelectionDAG &DAG
) const {

    //Assign locations to each returned value.
    SmallVector<CCValAssign, 16> RetLocs;
    CCState RetCCInfo(CallConv,IsVarArg, DAG.getMachineFunction(),RetLocs,
                      *DAG.getContext());
    RetCCInfo.AnalyzeReturn(Outs,RetCC_M88k);

    SDValue Glue;
    SmallVector<SDValue, 4> RetOps(1, Chain);
    for(unsigned I = 0, E = RetLocs.size(); I != E; ++I) {
        CCValAssign &VA = RetLocs[I];

        //Make the return register live on exit
        assert(VA.isRegLoc() && "Can only return in registers !");

        //Chain and glue the copies together
        Register Reg = VA.getLocReg();
        Chain = DAG.getCopyToReg(Chain, DL, Reg, OutVals[I], Glue);

        Glue = Chain.getValue(1);
        RetOps.push_back(DAG.getRegister(Reg,VA.getLocVT()));

    } 
    // update chain and glue 
    RetOps[0] = Chain;
    if(Glue.getNode())
       RetOps.push_back(Glue);

    return DAG.getNode(M88kISD::RET_GLUE, DL, MVT::Other, RetOps);                    
}