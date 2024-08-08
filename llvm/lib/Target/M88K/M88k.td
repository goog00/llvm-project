//===----------------------------------------------------------------------===//
// Target-independent interfaces which we are implementing
//===----------------------------------------------------------------------===//

include "llvm/Target/Target.td"


//===----------------------------------------------------------------------===//
// M88k subtarget features.
//===----------------------------------------------------------------------===//


//===----------------------------------------------------------------------===//
// Register File, Calling Conv, Instruction Descriptions
//===----------------------------------------------------------------------===//

include "M88kRegisterInfo.td"
include "M88kInstrFormats.td"
include "M88kInstrInfo.td"

//===----------------------------------------------------------------------===//
// Declare the target which we are implementing
//===----------------------------------------------------------------------===//

def M88kInstrInfo : InstrInfo;
def M88kAsmParser : AsmParser;
def M88kAsmParserVariant : AsmParserVariant {
    let RegisterPrefix = "%";
    let TokenizingCharacters = "[]<>*!";
}

def M88k : Target {
    let InstructionSet = M88kInstrInfo;
    let AssemblyParsers = [M88kAsmParser];
    let AssemblyParserVariants = [M88kAsmParserVariant];
}