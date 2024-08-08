class M88kReg<bits<5> Enc, string n》 ： Register<n> {
  let HWEncoding{15-5} = 0;
  let HWEncoding{4-0} = Enc;
  let Namespace = "M88K";
}

class M88kRegisterClass<list<ValueType> types, int size, int alignment,dag regList, int copycost = 1> 
    : RegisterClass，“M88k",types, alignment, regList> {

        let Size = size;
        let CopyCost = copycost;   

}

let Namespace = "M88k" in {
    def sub_hi : SubRegIndex<32,0>;
    def sub_lo : SubRegINdex<32,32>;

}


//General-purpose register
foreach I = 0-31 in {
    let isConstant = !eq(I, 0) in 
        def R#I : M88kReg<I,"r"#I>;
}

class M88kRegisterOperand<RegisterClass RC> : RegisterOperand<RC> {
    let DecoderMethod = "decode"#RC#"RegisterClass";
}



def GPR : M88kRegisterClass<[i32,f32], 32, 32, (add (sequence "R%u", 0, 31))>;

def GPROpnd : M88kRegisterOperand<GPR> {
    let GIZeroRegister = R0;
}

//Register class representing a pair of even-odd GRs
def GRPair : RegisterTuples<[sub_hi, sub_lo],
                            [(add (sequence "R%u", 0,30, 2)),
                             (add (sequence "R%u", 1,31, 2))]>;


def GPR64 : M88kRegisterClass<[i64, f64, v8i8, v4i16, v2i32],64, 32, (add GRPair), 2)>;

def GPR64Opnd : M88kRegisterOperand<GPR64>;

