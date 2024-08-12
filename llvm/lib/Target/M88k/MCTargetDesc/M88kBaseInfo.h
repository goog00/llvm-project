//===-- M88kBaseInfo.h - Top level definitions for M88k ------ --*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file contains small standalone helper functions and enum definitions for
// the M88k target useful for the compiler back-end and the MC libraries.
// As such, it deliberately does not include references to LLVM core
// code gen types, passes, etc..
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_M88K_MCTARGETDESC_M88KBASEINFO_H
#define LLVM_LIB_TARGET_M88K_MCTARGETDESC_M88KBASEINFO_H

#include "llvm/MC/MCInstrDesc.h"

namespace llvm {
namespace M88kOp {
enum OperandType : unsigned {
  OPERAND_FIRST_M88K = MCOI::OPERAND_FIRST_TARGET,
  OPERAND_UIMM5 = OPERAND_FIRST_M88K,
  OPERAND_UIMM16,
  OPERAND_SIMM16,
  OPERAND_CONDITION_CODE,
  OPERAND_BFWIDTH,
  OPERAND_BFOFFSET,
  OPERAND_PIXELROTATE,
  OPERAND_REGISTER_SCALED,
};
} // namespace M88kOp

} // namespace llvm

#endif
