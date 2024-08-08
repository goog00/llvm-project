
#ifndef LLVM_LIB_TARGET_M88K_MCTARGETDESC_M88KMCTARGETDESC_H
#define LLVM_LIB_TARGET_M88K_MCTARGETDESC_M88KMCTARGETDESC_H

#include "llvm/Support/DataTypes.h"

#include <memory>

namespace llvm {

class MCAsmBackend;
class MCCodeEmitter;
class MCContext;
class MCInstrInfo;
class MCObjectTargetWriter;
class MCRegisterInfo;
class MCSubtargetInfo;
class MCTargetOptions;
class StringRef;
class Target;
class Triple;
class raw_pwrite_stream;
class raw_ostream;

MCCodeEmitter *createM88kMCCodeEmitter(const MCInstrInfo &MCII,
                                       MCContext &Ctx);

MCAsmBackend *createM88kMCAsmBackend(const Target &T,
                                     const MCSubtargetInfo &STI,
                                     const MCRegisterInfo &MRI,
                                     const MCTargetOptions &Options);

std::unique_ptr<MCObjectTargetWriter> createM88kObjectWriter(uint8_t OSABI);

}

#define GET_REGINFO_ENUM
#include "M88kGenRegisterInfo.inc"

#define GET_INSTRINFO_ENUM
#include "M88kGenInstrInfo.inc"

#define GET_SUBTARGETINFO_ENUM
#include "M88kGenSubtargetInfo.inc"

#endif