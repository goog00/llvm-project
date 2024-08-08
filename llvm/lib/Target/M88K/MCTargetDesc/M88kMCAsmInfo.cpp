
#include "M88kMCAsmInfo.h"

using namespace llvm;

M88kMCAsmInfo::M88kMCAsmInfo(const Triple &TT) {
    IsLittleEndian = false;
    UseDotAlignForAlignment = true;
    MinInstAlignment = 4;

    CommentString = "|";
    Data64bitsDirective = "\t.space\t";
    UsesELFSectionDirectiveForBSS = true;
    SupportsDebugInformation = false;
    ExceptionsType = ExceptionHandling::SjLj;

}