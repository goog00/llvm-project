//===-- M88kInstrFormats.td - M88k Instruction Formats -----*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

class InstM88k<dag outs, dag ins, string asm, string operands,
               list<dag> pattern = []>
  : Instruction {
  bits<32> Inst;

  bits<32> SoftFail = 0; // Needed by disassembler.

  let Namespace = "M88k";
  let Size = 4;

  dag OutOperandList = outs;
  dag InOperandList = ins;
  // Construct the assembler string from template parameters asm and operands.
  // If the instruction has a delay slot, then append ".n" to the mnemonic.
  let AsmString = !if(!eq(operands, ""), asm,
                      !strconcat(asm, " ", operands));
  let Pattern = pattern;

  let DecoderNamespace = "M88k";
}

class Pseudo<dag outs, dag ins, list<dag> pattern>
  : InstM88k<outs, ins, "", "", pattern> {
  let isCodeGenOnly       = 1;
  let isPseudo            = 1;
  let hasNoSchedulingInfo = 1;
}

//===----------------------------------------------------------------------===//
// The formats follow the categories specified in the User Manual.
//===----------------------------------------------------------------------===//

// Category: Logical.
class F_L<dag outs, dag ins, string asm, string operands,
          list<dag> pattern = []>
   : InstM88k<outs, ins, asm, operands, pattern> {
  bits<5>  rd;
  bits<5>  rs1;
  let Inst{25-21} = rd;
  let Inst{20-16} = rs1;
}

// Format: Logical with triadic register.
class F_LR<bits<5> func, bits<1> comp, string asm, list<dag> pattern = []>
   : F_L<(outs GPROpnd:$rd), (ins GPROpnd:$rs1, GPROpnd:$rs2),
         !if(comp, !strconcat(asm, ".c"), asm), "$rd, $rs1, $rs2", pattern> {
  bits<5>  rs2;
  let Inst{31-26} = 0b111101;
  let Inst{15-11} = func;
  let Inst{10}    = comp;
  let Inst{9-5}   = 0b00000;
  let Inst{4-0}   = rs2;
}

// Category: Integer.

class F_I<dag outs, dag ins, string asm, string operands, list<dag> pattern = []>
   : InstM88k<outs, ins, asm, operands, pattern> {
  bits<5>  rd;
  bits<5>  rs1;
  let Inst{25-21} = rd;
  let Inst{20-16} = rs1;
}

// Format: Integer with 16bit immediate.
class F_II<bits<6> func, dag ins, string asm, list<dag> pattern = []>
   : F_I<(outs GPROpnd:$rd), ins, asm, "$rd, $rs1, $imm16", pattern> {
  bits<16> imm16;

  let Inst{31-26} = func;
  let Inst{15-0}  = imm16;
}

// Format: Integer with triadic register and carry.
class F_IRC<bits<6> func, bits<1> carryin, bits<1> carryout,
            string asm, list<dag> pattern = []>
   : F_I<(outs GPROpnd:$rd), (ins GPROpnd:$rs1, GPROpnd:$rs2),
         !strconcat(asm, !cond(!not(!or(carryin, carryout)) : "",
                               !and(carryin, !not(carryout)) : ".ci",
                               !and(!not(carryin), carryout) : ".co",
                               !and(carryin, carryout) : ".cio")),
         "$rd, $rs1, $rs2", pattern> {
  bits<5> rs2;

  let Inst{31-26} = 0b111101;
  let Inst{15-10} = func;
  let Inst{9}     = carryin;
  let Inst{8}     = carryout;
  let Inst{7-5}   = 0b000;
  let Inst{4-0}   = rs2;
}

// Category: Flow control.

// Format: JMP/JSR
class F_JMP<bits<5> func, string asm, list<dag> pattern = []>
   : InstM88k<(outs), (ins GPROpnd:$rs2), asm, "$rs2", pattern> {
  bits<5> rs2;

  let Inst{31-26} = 0b111101;
  let Inst{25-16} = 0b0000000000;
  let Inst{15-11} = func;
  let Inst{10}    = hasDelaySlot;
  let Inst{9-5}   = 0b00000;
  let Inst{4-0}   = rs2;
}

// Format: BB0/BB1/BCND
class F_BCOND<bits<5> func, dag outs, dag ins, string asm>
   : InstM88k<outs, ins, asm, "$m5, $rs1, $d16", []> {
  bits<5>  m5;
  bits<5>  rs1;
  bits<16> d16;

  let Inst{31-27} = func;
  let Inst{26}    = !if(hasDelaySlot, 1, 0);
  let Inst{25-21} = m5;
  let Inst{20-16} = rs1;
  let Inst{15-0}  = d16;
}

