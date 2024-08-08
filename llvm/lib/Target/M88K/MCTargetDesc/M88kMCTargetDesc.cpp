
#include "M88kMCTargetDesc.h"


using namespace llvm;

#define GET_INSTRINFO_MC_DESC
#include "M88kGenInstrInfo.inc"

#define GET_SUBTARGETINFO_MC_DESC
#include "M88kGenSubtargetInfo.inc"

#define GET_REGINFO_MC_DESC
#include "M88kGenRegisterInfo.inc"

static MCAsmInfo *createM88kMCAsmInfo(const MCRegisterInfo &MRI,
                                      const Triple &TT,
                                      const MCTargetOptions &Options) {
  MCAsmInfo *MAI = new M88kMCAsmInfo(TT);
  return MAI;
}


static MCInstPrinter *createM88kMCInstPrinter(const Triple &T,
                                              unsigned SyntaxVariant,
                                              const MCAsmInfo &MAI,
                                              const MCInstrInfo &MII,
                                              const MCRegisterInfo &MRI) {
  return new M88kInstPrinter(MAI, MII, MRI);
}



static MCInstrInfo *createM88kMCInstrInfo() {
    MCInstrInfo *X = new MCInstrInfo();
    InitM88kMCInstrInfo(X);
    return X;
}


static MCRegisterInfo *createM88kMCRegisterInfo(const Triple &TT) {
    MCRegisterInfo *X = new MCRegisterInfo();
    InitM88kMCRegisterInfo(X, M88k::R1);
    return X;
}

static MCSubtargetInfo *createM88kMCSubtargetInfo(const Triple &TT, StringRef CPU, StringRef FS) {
    return createM88kMCSubtargetInfoImpl(TT, CPU, /*TuneCPU*/ CPU,FS);
}



extern "C" LLVM_EXTERNAL_VISIBILITY void LLVMInitializedM88kTargetMC() {

    // Register the MCInstrInfo
    TargetRegistry::RegisterMCInstrInfo(getTheM88kTarget(),createM88kMCInstrInfo);

    //Register the MCRegisterInfo.
    TargetRegistry::RegisterMCRegInfo(getTheM88kTarget(), createM88kMCRegisterInfo);

    //Register the MCSubtargetInfo
    TargetRegistry::RegisterMCAsmBackend(getTheM88kTarget(), createM88kMCSubtargetInfo);

    TargetRegistry::RegisterMCAsmInfo(getTheM88kTarget(), createM88kMCAsmInfo);

    TargetRegistry::RegisterMCCodeEmitter(getTheM88kTarget(), createM88kMCCodeEmitter);

    TargetRegistry::RegisterMCInstPrinter(getTheM88kTarget(), createM88kMCInstPrinter);
}