//===-- M88kInstrInfo.td - M88k Instructions ---------------*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file describes the M88k instructions in TableGen format.
//
//===----------------------------------------------------------------------===//

// ---------------------------------------------------------------------------//
// Selection DAG Nodes.
// ---------------------------------------------------------------------------//

// Selection DAG types.

// These are target-independent nodes, but have target-specific formats.
def SDT_CallSeqStart : SDCallSeqStart<[SDTCisVT<0, i32>, SDTCisVT<1, i32>]>;
def SDT_CallSeqEnd   : SDCallSeqEnd<[SDTCisVT<0, i32>, SDTCisVT<1, i32>]>;
def SDT_Call         : SDTypeProfile<0, -1, [SDTCisPtrTy<0>]>;

// Selection DAG nodes.

def call             : SDNode<"M88kISD::CALL", SDT_Call,
                              [SDNPHasChain, SDNPOptInGlue, SDNPOutGlue,
                              SDNPVariadic]>;
def retglue          : SDNode<"M88kISD::RET_GLUE", SDTNone,
                              [SDNPHasChain, SDNPOptInGlue, SDNPVariadic]>;

// ---------------------------------------------------------------------------//
// Operands.
// ---------------------------------------------------------------------------//

class ImmediateAsmOperand<string name> : AsmOperandClass {
  let Name = name;
  let RenderMethod = "addImmOperands";
}

class ImmediateOp<ValueType vt, string asmop> : Operand<vt> {
  let PrintMethod = "print"#asmop#"Operand";
  let DecoderMethod = "decode"#asmop#"Operand";
  let ParserMatchClass = !cast<AsmOperandClass>(asmop);
  let OperandType = "OPERAND_IMMEDIATE";
}

// Condition code operands.
def CCode : AsmOperandClass {
  let Name = "CCode";
  let RenderMethod = "addConditionCodeOperands";
  let ParserMethod = "parseConditionCode";
}
def ccode : ImmediateOp<i8, "CCode"> {
  let OperandNamespace = "M88kOp";
  let OperandType = "OPERAND_CONDITION_CODE";
}

// Constructs an asm operand for a PC-relative address.  SIZE says how
// many bits there are.
class PCRelAsmOperand<string size> : ImmediateAsmOperand<"PCRel"#size> {
  let PredicateMethod = "isImm";
  let ParserMethod = "parsePCRel"#size;
}

// Constructs an operand for a PC-relative address with address type VT.
// ASMOP is the associated asm operand.
class PCRelOperand<ValueType vt, AsmOperandClass asmop> : Operand<vt> {
  let PrintMethod = "printPCRelOperand";
  let ParserMatchClass = asmop;
  let OperandType = "OPERAND_PCREL";
}

// PC-relative asm operands.
def PCRel16 : PCRelAsmOperand<"16">;

// PC-relative offsets of a basic block.  The offset is sign-extended
// and shifted left by 2 bits.
def brtarget16 : PCRelOperand<OtherVT, PCRel16> {
  let EncoderMethod = "getPC16Encoding";
  let DecoderMethod = "decodePC16BranchOperand";
}

// ---------------------------------------------------------------------------//
// Logic and bit field instructions.
// ---------------------------------------------------------------------------//

// Multiclass for logical instructions with triadic registers.
multiclass Logic<bits<5> Func, string OpcStr, SDNode OpNode> {
  let isCommutable = 1 in
    def rr : F_LR<Func, /*comp=*/0b0, OpcStr,
                  [(set i32:$rd, (OpNode GPROpnd:$rs1, GPROpnd:$rs2))]>;
  def rrc : F_LR<Func, /*comp=*/0b1, OpcStr,
                 [(set i32:$rd, (OpNode GPROpnd:$rs1, (not GPROpnd:$rs2)))]>;
}

defm AND : Logic<0b01000, "and", and>;
defm XOR : Logic<0b01010, "xor", xor>;
defm OR  : Logic<0b01011, "or", or>;

multiclass ArithTri<bits<6> Func, string OpcStr> { //, bit IsReMat = 0> {
  def rr : F_IRC<Func, /*carryin=*/0b0, /*carryout=*/0b0, OpcStr>;
//  let isReMaterializable = IsReMat in
//    def ri : F_II<Func, (ins GPROpnd:$rs1, uimm16:$imm16), OpcStr>;
}

defm DIVU : ArithTri<0b011010, "divu">;
defm DIVS : ArithTri<0b011110, "divs">;

let isBarrier = 1, isBranch = 1, isTerminator = 1, isIndirectBranch = 1 in {
  def JMP : F_JMP<0b11000, "jmp", [(brind GPROpnd:$rs2)]>;
}

let isReturn = 1, isTerminator = 1, isBarrier = 1,
    AsmString = "RET" in
  def RET : Pseudo<(outs), (ins), [(retglue)]>;

let isBranch = 1, isTerminator = 1 in {
  def BCND : F_BCOND<0b11101,
                     (outs), (ins ccode:$m5, GPROpnd:$rs1, brtarget16:$d16),
                     "bcnd">;
}

let isTrap = 1, isBarrier = 1, isTerminator = 1, isCodeGenOnly = 1 in {
  // Raises trap with vector 502 if bit 0 of %rs1 is not set. This is used to
  // generate the trap after a zero division. Marked as terminator to allow
  // instruction to be last of basic block.
  def TRAP503 : InstM88k<(outs), (ins GPROpnd:$rs1), "tb0", "0, $rs1, 503", []> {
    bits<5>  b5;
    bits<5>  rs1;
    bits<9>  vec9;

    let Inst{31-26} = 0b111100;
    let Inst{25-21} = 0b00000;
    let Inst{20-16} = rs1;
    let Inst{15-9}  = 0b1101000;
    let Inst{8-0}   = 0b111110111;
  }
}

