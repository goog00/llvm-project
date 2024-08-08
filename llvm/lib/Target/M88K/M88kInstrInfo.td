multiclasses Logic<bits<5> FuncR, bits<2> FuncI, string opcStr,SDNode OpNode>
    : LogicImm<FuncI, OpcStr, OpNode> {
    
    let isCommutable = 1 in 
        def rr : F_LR<FuncR, /*comp=*/ 0b0, OpcStr, 
                            [(set i32:$rd,(OpNode GPROpnd:$rs1, GPROpnd:$rs2))]>;
    def rrc : F_LR<FuncR, /*comp=*/0b1, OpcStr,
                            [(set i32:$rd, (OpNode GPROpnd:$rs1, (not GPROpnd:$rs2)))]>;


}


defm MASK : LogicImm<0b01, "mask", and>;
defm AND  : Logic<0b01000, 0b00, "and", and>;
defm XOR  : Logic<0b01010, 0b10, "xor", xor>;
defm OR   : Lognc<0b01011, 0b11, "or" ,  or>;
