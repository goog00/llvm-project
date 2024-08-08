
// #include "MCTargetDesc/M88kMCExpr.h"
#include "MCTargetDesc/M88kMCTargetDesc.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/MC/MCCodeEmitter.h"
#include "llvm/MC/MCContext.h"
#include "llvm/MC/MCExpr.h"
#include "llvm/MC/MCFixup.h"
#include "llvm/MC/MCInst.h"
#include "llvm/MC/MCInstrInfo.h"
#include "llvm/MC/MCRegisterInfo.h"
#include "llvm/MC/MCSubtargetInfo.h"
#include "llvm/Support/Casting.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/raw_ostream.h"
#include <cassert>
#include <cstdint>


using namespace llvm;

#define DEBUG_TYPE "mccodeemitter"

STATISTIC(MCNumEmitted,"Number of MC instructions emitted");



namespace {

class M88kMCCodeEmitter : public MCCodeEmitter { 
    const MCInstrInfo &MCII;
    MCContext &Ctx;

public:
    M88kMCCodeEmitter(const MCInstrInfo &MCII, MCContext &Ctx) : MCII(MCII),Ctx(Ctx) {}

    ~M88kMCCodeEmitter() override = default;

    void encodeInstruction(const MCInst &MI, raw_ostream &OS, 
                            SmallVectorImpl<MCFixup> &Fixups,
                           const MCSubtargetInfo &STI) const override;

    uint64_t getBinaryCodeForInstr(const MCInst &MI,
                                    SmallVectorImpl<MCFixup> &Fixups, 
                                    const MCSubtargetInfo &STI) const;

    unsigned getMachineOpValue(const MCInst &MI, const MCOperand &MO,
                                SmallVectorImpl<MCFixup> &Fixups,
                                const MCSubtargetInfo &STI) const;

    
};

} // end anonymous namespace



void M88kMCCodeEmitter::encodeInstruction(const MCInst &MI,raw_ostream &OS, 
                                          SmallVectorImpl<MCFixup> &Fixups,
                                          const MCSubtargetInfo &STI) const {

    uint64_t Bits = getBinaryCodeForInstr(MI, Fixups, STI);
    ++MCNumEmitted;
    support::endian::write<uint32_t>(OS, Bits,support::big);
                                          
                                          
}


unsigned
M88kMCCodeEmitter::getMachineOpValue(const MCInst &MI, const MCOperand &MO,
                                     SmallVectorImpl<MCFixup> &Fixups,const MCSubtargetInfo &STI) const {
        if (MO.isReg())
           return Ctx.getRegisterInfo()->getEncodingValue(MO.getReg());
        if (MO.isImm())
            return static_cast<uint64_t>(MO.getImm());

        return 0;       

}



#include "M88kGenMCCodeEmitter.inc"
MCCodeEmitter *llvm::createM88kMCcodeEmitter(const MCInstrInfo &MCII,MCContext &Ctx) {
    return new M88kMCCodeEmitter(MCII,Ctx);
}