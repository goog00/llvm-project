1. create ir 
../build/bin/clang -S -emit-llvm matmul.c -Xclang -disable-O0-optnone -o matmul.ll

2. prepare the llvm-ir for polly
../build/bin/opt  -S -polly-canonicalize matmul.ll -o matmul.preopt.ll

3. Show the SCoPs detected by Polly (optional) 可选步骤 有问题暂时跳过
../build/bin/opt -basic-aa -polly-ast --aa matmul.preopt.ll -polly-process-unprofitable -polly-use-llvm-names -f

4. Highlight the detected SCoPs in the CFGs of the program (requires graphviz/dotty)
../build/bin/opt -polly-use-llvm-names -basic-aa -view-scops -disable-output matmul.preopt.ll