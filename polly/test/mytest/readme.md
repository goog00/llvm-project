


export PATH="/Users/sunteng/compiler/mlir/llvm-project/build/bin:$PATH"



1. create llvm ir from c

```
clang -S -emit-llvm matmul.c -Xclang -disable-O0-optnone -o matmul.ll
```

2. prepare llvm-ir for polly
   
```
opt -S -polly-canonicalize matmul.ll -o matmul.preopt.ll
```

3. 
../../../build/bin/opt -polly-scops -polly-matmul-tiling  matmul.preopt.ll

```
[MatmulTilingPass] runOnScop called!
```


../../../build/bin/opt -polly-scops -my-matmul-tile  matmul.preopt.ll