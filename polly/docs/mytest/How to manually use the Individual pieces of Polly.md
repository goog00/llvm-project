
由于[Polly官方文档](https://polly.llvm.org/docs/HowToManuallyUseTheIndividualPiecesOfPolly.html)较为陈旧，其中一些命令行参数在较新版本中已被弃用或修改，导致我们在尝试 Polly 时容易遇到参数无效或命令执行失败的问题，影响了学习和实践的体验。
我基于release/20.x 源码，重新整理修正了过时参数，确保各个步骤在当前版本中均可正确执行，方便大家更顺利地上手并深入了解 Polly 的优化过程。如果大家想直接使用官方文档，可以切换到release/9.x，也存在一些差异，但基本上都支持。

## 1.环境准备：
1.build llvm 
```
git checkout release/20.x

mkdir build && cd build

cmake -G Ninja \
  -DLLVM_ENABLE_PROJECTS="clang;polly" \
  -DCMAKE_BUILD_TYPE=Debug \
  -DLLVM_ENABLE_ASSERTIONS=ON \
  -DLLVM_TARGETS_TO_BUILD="X86" \
  ../llvm
  
ninja -j10

设置临时环境变量
export PATH="/Users/xx/compiler/mlir/llvm-project/build/bin:$PATH"

```

Note:
尝试过在构建的时候关闭新的Pass Manager 看是否可以支持哪些比较古老的pass参数,发现已经不支持这样做了。

```
cmake ../llvm \
  -G Ninja \
  -DLLVM_ENABLE_PROJECTS="clang;polly" \
  -DLLVM_TARGETS_TO_BUILD="X86" \
  -DLLVM_ENABLE_NEW_PASS_MANAGER=OFF \
  -DPOLLY_ENABLE_GPGPU_CODEGEN=OFF \
  -DCMAKE_BUILD_TYPE=Release \
  -DLLVM_ENABLE_ASSERTIONS=ON

Enabling the legacy pass manager on the cmake level is no longer supported.

```

2.prepare matmul.c
自定义一个目录，比如，polly/docs/mytest,

```
cp experiments/matmul/matmul.c .
```


### 2.Execute the individual Polly passes manually
执行Polly 优化流程中各个Pass，观察分析每个Pass的效果。



1. create llvm ir from c

```
clang -S -emit-llvm matmul.c -Xclang -disable-O0-optnone -o matmul.ll
```

2. prepare llvm-ir for polly
   
```
opt -S -polly-canonicalize matmul.ll -o matmul.preopt.ll
```

3. Show the SCoPs detected by Polly

```
opt -basic-aa -polly-print-ast    matmul.preopt.ll  -polly-process-unprofitable -polly-use-llvm-names


Printing analysis 'Polly - Generate an AST from the SCoP (isl)' for region: 'for.cond => for.end19' in function 'init_array':
Printing analysis 'Polly - Generate an AST of the SCoP (isl)'for.cond => for.end19' in function 'init_array':
:: isl ast :: init_array :: %for.cond---%for.end19

if (1)

    // Loop with Metadata
    for (int c0 = 0; c0 <= 1535; c0 += 1) {
    // Loop with Metadata
    for (int c1 = 0; c1 <= 1535; c1 += 1)
        Stmt_for_body3(c0, c1);
    }

else
    {  /* original code */ }

Printing analysis 'Polly - Generate an AST from the SCoP (isl)' for region: 'for.cond => for.end30' in function 'main':
Printing analysis 'Polly - Generate an AST of the SCoP (isl)'for.cond => for.end30' in function 'main':
:: isl ast :: main :: %for.cond---%for.end30

if (1)

    // Loop with Metadata
    for (int c0 = 0; c0 <= 1535; c0 += 1) {
    // Loop with Metadata
    for (int c1 = 0; c1 <= 1535; c1 += 1) {
        Stmt_for_body3(c0, c1);
        // Loop with Metadata
        for (int c2 = 0; c2 <= 1535; c2 += 1)
        Stmt_for_body8(c0, c1, c2);
    }
    }

else
    {  /* original code */ }

```

4. Highlight the detected SCoPs in the CFGs of the program (requires graphviz/dotty) 
   没找到对应新版本的参数，但不影响接下来的流程，暂时先跳过。

```

旧： 
opt -polly-use-llvm-names -basic-aa -view-scops -disable-output matmul.preopt.ll
opt -polly-use-llvm-names -basic-aa -view-scops-only -disable-output matmul.preopt.ll


opt -basic-aa -dot-scops -disable-output   matmul.preopt.ll -polly-use-llvm-names

opt -polly-use-llvm-names -basic-aa  -view-scops-only -disable-output matmul.preopt.ll

```


5. View the polyhedral representation of the SCoPs

```

    opt  -basic-aa -polly-print-function-scops matmul.preopt.ll -polly-process-unprofitable -polly-use-llvm-names

    Printing analysis 'Polly - Create polyhedral description of all Scops of a function' for function 'init_array':
        Function: init_array
        Region: %for.cond---%for.end19
        Max Loop Depth:  2
        Invariant Accesses: {
        }
        Context:
        {  :  }
        Assumed Context:
        {  :  }
        Invalid Context:
        {  : false }
        Defined Behavior Context:
        {  :  }
        Arrays {
            float MemRef_A[*][1536]; // Element size 4
            float MemRef_B[*][1536]; // Element size 4
        }
        Arrays (Bounds as pw_affs) {
            float MemRef_A[*][ { [] -> [(1536)] } ]; // Element size 4
            float MemRef_B[*][ { [] -> [(1536)] } ]; // Element size 4
        }
        Alias Groups (0):
            n/a
        Statements {
            Stmt_for_body3
                Domain :=
                    { Stmt_for_body3[i0, i1] : 0 <= i0 <= 1535 and 0 <= i1 <= 1535 };
                Schedule :=
                    { Stmt_for_body3[i0, i1] -> [i0, i1] };
                MustWriteAccess :=  [Reduction Type: NONE] [Scalar: 0]
                    { Stmt_for_body3[i0, i1] -> MemRef_A[i0, i1] };
                MustWriteAccess :=  [Reduction Type: NONE] [Scalar: 0]
                    { Stmt_for_body3[i0, i1] -> MemRef_B[i0, i1] };
        }
    Printing analysis 'Polly - Create polyhedral description of all Scops of a function' for function 'print_array':
    Printing analysis 'Polly - Create polyhedral description of all Scops of a function' for function 'main':
        Function: main
        Region: %for.cond---%for.end30
        Max Loop Depth:  3
        Invariant Accesses: {
        }
        Context:
        {  :  }
        Assumed Context:
        {  :  }
        Invalid Context:
        {  : false }
        Defined Behavior Context:
        {  :  }
        Arrays {
            float MemRef_C[*][1536]; // Element size 4
            float MemRef_A[*][1536]; // Element size 4
            float MemRef_B[*][1536]; // Element size 4
        }
        Arrays (Bounds as pw_affs) {
            float MemRef_C[*][ { [] -> [(1536)] } ]; // Element size 4
            float MemRef_A[*][ { [] -> [(1536)] } ]; // Element size 4
            float MemRef_B[*][ { [] -> [(1536)] } ]; // Element size 4
        }
        Alias Groups (0):
            n/a
        Statements {
            Stmt_for_body3
                Domain :=
                    { Stmt_for_body3[i0, i1] : 0 <= i0 <= 1535 and 0 <= i1 <= 1535 };
                Schedule :=
                    { Stmt_for_body3[i0, i1] -> [i0, i1, 0, 0] };
                MustWriteAccess :=  [Reduction Type: NONE] [Scalar: 0]
                    { Stmt_for_body3[i0, i1] -> MemRef_C[i0, i1] };
            Stmt_for_body8
                Domain :=
                    { Stmt_for_body8[i0, i1, i2] : 0 <= i0 <= 1535 and 0 <= i1 <= 1535 and 0 <= i2 <= 1535 };
                Schedule :=
                    { Stmt_for_body8[i0, i1, i2] -> [i0, i1, 1, i2] };
                ReadAccess :=       [Reduction Type: NONE] [Scalar: 0]
                    { Stmt_for_body8[i0, i1, i2] -> MemRef_C[i0, i1] };
                ReadAccess :=       [Reduction Type: NONE] [Scalar: 0]
                    { Stmt_for_body8[i0, i1, i2] -> MemRef_A[i0, i2] };
                ReadAccess :=       [Reduction Type: NONE] [Scalar: 0]
                    { Stmt_for_body8[i0, i1, i2] -> MemRef_B[i2, i1] };
                MustWriteAccess :=  [Reduction Type: NONE] [Scalar: 0]
                    { Stmt_for_body8[i0, i1, i2] -> MemRef_C[i0, i1] };
        }
```

6. Show the dependences for the SCoPs

```
旧： opt -basic-aa -polly-use-llvm-names -polly-dependences  matmul.preopt.ll -polly-process-unprofitable

opt -basic-aa -polly-use-llvm-names -polly-print-dependences  matmul.preopt.ll -polly-process-unprofitable

Printing analysis 'Polly - Calculate dependences' for region: 'for.cond => for.end19' in function 'init_array':
    RAW dependences:
            {  }
    WAR dependences:
            {  }
    WAW dependences:
            {  }
    Reduction dependences:
            {  }
    Transitive closure of reduction dependences:
            {  }
Printing analysis 'Polly - Calculate dependences' for region: 'for.cond => for.end30' in function 'main':
    RAW dependences:
            { Stmt_for_body8[i0, i1, i2] -> Stmt_for_body8[i0, i1, 1 + i2] : 0 <= i0 <= 1535 and 0 <= i1 <= 1535 and 0 <= i2 <= 1534; Stmt_for_body3[i0, i1] -> Stmt_for_body8[i0, i1, 0] : 0 <= i0 <= 1535 and 0 <= i1 <= 1535 }
    WAR dependences:
            { Stmt_for_body8[i0, i1, i2] -> Stmt_for_body8[i0, i1, 1 + i2] : 0 <= i0 <= 1535 and 0 <= i1 <= 1535 and 0 <= i2 <= 1534 }
    WAW dependences:
            { Stmt_for_body8[i0, i1, i2] -> Stmt_for_body8[i0, i1, 1 + i2] : 0 <= i0 <= 1535 and 0 <= i1 <= 1535 and 0 <= i2 <= 1534; Stmt_for_body3[i0, i1] -> Stmt_for_body8[i0, i1, 0] : 0 <= i0 <= 1535 and 0 <= i1 <= 1535 }
    Reduction dependences:
            {  }
    Transitive closure of reduction dependences:
            {  }

```                


7. Export jscop files

```
opt -basic-aa -polly-use-llvm-names -polly-export-jscop matmul.preopt.ll -polly-process-unprofitable
note:
init_array___%for.cond---%for.end19.jscop命名生成与具体的平台有关
Writing JScop '%for.cond---%for.end19' in function 'init_array' to './init_array___%for.cond---%for.end19.jscop'.

Writing JScop '%for.cond---%for.end30' in function 'main' to './main___%for.cond---%for.end30.jscop'.

```

8. Import the changed jscop files and print the updated SCoP structure (optional)

**No Polly**

```
    旧： opt -basic-aa -polly-use-llvm-names matmul.preopt.ll -polly-import-jscop -polly-ast -analyze -polly-process-unprofitable

    opt -basic-aa -polly-use-llvm-names matmul.preopt.ll -polly-import-jscop -polly-print-ast  -polly-process-unprofitable


    Reading JScop '%for.cond---%for.end19' in function 'init_array' from './init_array___%for.cond---%for.end19.jscop'.
    Printing analysis 'Polly - Generate an AST from the SCoP (isl)' for region: 'for.cond => for.end19' in function 'init_array':
    Printing analysis 'Polly - Generate an AST of the SCoP (isl)'for.cond => for.end19' in function 'init_array':
    :: isl ast :: init_array :: %for.cond---%for.end19

    if (1)

        for (int c0 = 0; c0 <= 1535; c0 += 1)
        for (int c1 = 0; c1 <= 1535; c1 += 1)
            Stmt_for_body3(c0, c1);

    else
        {  /* original code */ }

    Reading JScop '%for.cond---%for.end30' in function 'main' from './main___%for.cond---%for.end30.jscop'.
    Printing analysis 'Polly - Generate an AST from the SCoP (isl)' for region: 'for.cond => for.end30' in function 'main':
    Printing analysis 'Polly - Generate an AST of the SCoP (isl)'for.cond => for.end30' in function 'main':
    :: isl ast :: main :: %for.cond---%for.end30

    if (1)

        for (int c0 = 0; c0 <= 1535; c0 += 1)
        for (int c1 = 0; c1 <= 1535; c1 += 1) {
            Stmt_for_body3(c0, c1);
            for (int c3 = 0; c3 <= 1535; c3 += 1)
            Stmt_for_body8(c0, c1, c3);
        }

    else
        {  /* original code */ }
```


**Loop Interchange (and Fission to allow the interchange)**



```
旧： opt -basic-aa -polly-use-llvm-names matmul.preopt.ll -polly-import-jscop -polly-import-jscop-postfix=interchanged -polly-ast -analyze -polly-process-unprofitable


opt -basic-aa -polly-use-llvm-names matmul.preopt.ll -polly-import-jscop -polly-import-jscop-postfix=interchanged -polly-print-ast  -polly-process-unprofitable

note:
init_array___%for.cond---%for.end19.jscop.interchanged是在init_array___%for.cond---%for.end19.jscop基础上添加了.interchanged后缀，其他同理。


Reading JScop '%for.cond---%for.end19' in function 'init_array' from './init_array___%for.cond---%for.end19.jscop.interchanged'.
Printing analysis 'Polly - Generate an AST from the SCoP (isl)' for region: 'for.cond => for.end19' in function 'init_array':
Printing analysis 'Polly - Generate an AST of the SCoP (isl)'for.cond => for.end19' in function 'init_array':
:: isl ast :: init_array :: %for.cond---%for.end19

if (1)

    for (int c0 = 0; c0 <= 1535; c0 += 1)
    for (int c1 = 0; c1 <= 1535; c1 += 1)
        Stmt_for_body3(c0, c1);

else
    {  /* original code */ }

Reading JScop '%for.cond---%for.end30' in function 'main' from './main___%for.cond---%for.end30.jscop.interchanged'.
Printing analysis 'Polly - Generate an AST from the SCoP (isl)' for region: 'for.cond => for.end30' in function 'main':
Printing analysis 'Polly - Generate an AST of the SCoP (isl)'for.cond => for.end30' in function 'main':
:: isl ast :: main :: %for.cond---%for.end30

if (1)

    for (int c0 = 0; c0 <= 1535; c0 += 1)
    for (int c1 = 0; c1 <= 1535; c1 += 1) {
        Stmt_for_body3(c0, c1);
        for (int c3 = 0; c3 <= 1535; c3 += 1)
        Stmt_for_body8(c0, c1, c3);
    }

else
    {  /* original code */ }
```


**Interchange + Tiling**



```
旧： opt -basic-aa -polly-use-llvm-names matmul.preopt.ll -polly-import-jscop -polly-import-jscop-postfix=interchanged+tiled -polly-ast -analyze -polly-process-unprofitable


opt -basic-aa -polly-use-llvm-names matmul.preopt.ll -polly-import-jscop -polly-import-jscop-postfix=interchanged+tiled -polly-print-ast -polly-process-unprofitable

Reading JScop '%for.cond---%for.end19' in function 'init_array' from './init_array___%for.cond---%for.end19.jscop.interchanged+tiled'.
Printing analysis 'Polly - Generate an AST from the SCoP (isl)' for region: 'for.cond => for.end19' in function 'init_array':
Printing analysis 'Polly - Generate an AST of the SCoP (isl)'for.cond => for.end19' in function 'init_array':
:: isl ast :: init_array :: %for.cond---%for.end19

if (1)

    for (int c0 = 0; c0 <= 1535; c0 += 1)
    for (int c1 = 0; c1 <= 1535; c1 += 1)
        Stmt_for_body3(c0, c1);

else
    {  /* original code */ }

Reading JScop '%for.cond---%for.end30' in function 'main' from './main___%for.cond---%for.end30.jscop.interchanged+tiled'.
Printing analysis 'Polly - Generate an AST from the SCoP (isl)' for region: 'for.cond => for.end30' in function 'main':
Printing analysis 'Polly - Generate an AST of the SCoP (isl)'for.cond => for.end30' in function 'main':
:: isl ast :: main :: %for.cond---%for.end30

if (1)

    {
    for (int c1 = 0; c1 <= 1535; c1 += 1)
        for (int c2 = 0; c2 <= 1535; c2 += 1)
        Stmt_for_body3(c1, c2);
    for (int c1 = 0; c1 <= 1535; c1 += 64)
        for (int c2 = 0; c2 <= 1535; c2 += 64)
        for (int c3 = 0; c3 <= 1535; c3 += 64)
            for (int c4 = c1; c4 <= c1 + 63; c4 += 1)
            for (int c5 = c3; c5 <= c3 + 63; c5 += 1)
                for (int c6 = c2; c6 <= c2 + 63; c6 += 1)
                Stmt_for_body8(c4, c6, c5);
    }

else
    {  /* original code */ }

```

**Interchange + Tiling + Strip-mining to prepare vectorization**



```
旧： opt -basic-aa -polly-use-llvm-names matmul.preopt.ll -polly-import-jscop -polly-import-jscop-postfix=interchanged+tiled -polly-ast -analyze -polly-process-unprofitable

opt -basic-aa -polly-use-llvm-names matmul.preopt.ll -polly-import-jscop -polly-import-jscop-postfix=interchanged+tiled+vector -polly-print-ast -polly-process-unprofitable

Reading JScop '%for.cond---%for.end19' in function 'init_array' from './init_array___%for.cond---%for.end19.jscop.interchanged+tiled+vector'.
Printing analysis 'Polly - Generate an AST from the SCoP (isl)' for region: 'for.cond => for.end19' in function 'init_array':
Printing analysis 'Polly - Generate an AST of the SCoP (isl)'for.cond => for.end19' in function 'init_array':
:: isl ast :: init_array :: %for.cond---%for.end19

if (1)

    for (int c0 = 0; c0 <= 1535; c0 += 1)
      for (int c1 = 0; c1 <= 1535; c1 += 1)
        Stmt_for_body3(c0, c1);

else
    {  /* original code */ }

Reading JScop '%for.cond---%for.end30' in function 'main' from './main___%for.cond---%for.end30.jscop.interchanged+tiled+vector'.
Printing analysis 'Polly - Generate an AST from the SCoP (isl)' for region: 'for.cond => for.end30' in function 'main':
Printing analysis 'Polly - Generate an AST of the SCoP (isl)'for.cond => for.end30' in function 'main':
:: isl ast :: main :: %for.cond---%for.end30

if (1)

    {
      for (int c1 = 0; c1 <= 1535; c1 += 1)
        for (int c2 = 0; c2 <= 1535; c2 += 1)
          Stmt_for_body3(c1, c2);
      for (int c1 = 0; c1 <= 1535; c1 += 64)
        for (int c2 = 0; c2 <= 1535; c2 += 64)
          for (int c3 = 0; c3 <= 1535; c3 += 64)
            for (int c4 = c1; c4 <= c1 + 63; c4 += 1)
              for (int c5 = c3; c5 <= c3 + 63; c5 += 1)
                for (int c6 = c2; c6 <= c2 + 63; c6 += 4)
                  for (int c7 = c6; c7 <= c6 + 3; c7 += 1)
                    Stmt_for_body8(c4, c7, c5);
    }

else
    {  /* original code */ }
    
```


9. Codegenerate the SCoPs
    
```
opt -S matmul.preopt.ll | opt -S -O3 -o matmul.normalopt.ll
```

```
opt -S matmul.preopt.ll -basic-aa -polly-use-llvm-names -polly-import-jscop -polly-import-jscop-postfix=interchanged -polly-codegen -polly-process-unprofitable | opt -S -O3 -o matmul.polly.interchanged.ll

Reading JScop '%for.cond---%for.end19' in function 'init_array' from './init_array___%for.cond---%for.end19.jscop.interchanged'.
Reading JScop '%for.cond---%for.end30' in function 'main' from './main___%for.cond---%for.end30.jscop.interchanged'.
```



```
opt -S matmul.preopt.ll -basic-aa -polly-use-llvm-names -polly-import-jscop -polly-import-jscop-postfix=interchanged+tiled -polly-codegen -polly-process-unprofitable | opt -S -O3 -o matmul.polly.interchanged+tiled.ll


Reading JScop '%for.cond---%for.end19' in function 'init_array' from './init_array___%for.cond---%for.end19.jscop.interchanged+tiled'.
Reading JScop '%for.cond---%for.end30' in function 'main' from './main___%for.cond---%for.end30.jscop.interchanged+tiled'.
```



```
#deprecated: -polly-vectorizer=polly
opt -S matmul.preopt.ll -basic-aa -polly-use-llvm-names -polly-import-jscop -polly-import-jscop-postfix=interchanged+tiled+vector -polly-codegen -polly-vectorizer=polly -polly-process-unprofitable | opt -S -O3 -o matmul.polly.interchanged+tiled+vector.ll

RegisterPasses.cpp#
static cl::opt<VectorizerChoice, true> Vectorizer(
    "polly-vectorizer", cl::desc("Select the vectorization strategy"),
    cl::values(
        clEnumValN(VECTORIZER_NONE, "none", "No Vectorization"),
        clEnumValN(
            VECTORIZER_STRIPMINE, "stripmine",
            "Strip-mine outer loops for the loop-vectorizer to trigger")),
    cl::location(PollyVectorizerChoice), cl::init(VECTORIZER_NONE),
    cl::cat(PollyCategory));


opt -S matmul.preopt.ll -basic-aa -polly-use-llvm-names -polly-import-jscop -polly-import-jscop-postfix=interchanged+tiled+vector -polly-codegen -polly-vectorizer=stripmine -polly-process-unprofitable | opt -S -O3 -o matmul.polly.interchanged+tiled+vector.ll

Reading JScop '%for.cond---%for.end19' in function 'init_array' from './init_array___%for.cond---%for.end19.jscop.interchanged+tiled+vector'.
Reading JScop '%for.cond---%for.end30' in function 'main' from './main___%for.cond---%for.end30.jscop.interchanged+tiled+vector'.
```

```
和前面的命令重复，应该是想做openmp 优化，但好像没有
原文是：matmul.polly.interchanged+tiled+vector.ll， 我改成：matmul.polly.interchanged+tiled+vector+openmp.ll，下文用到的这个.ll;不确定这样改是否对。

opt -S matmul.preopt.ll -basic-aa -polly-use-llvm-names -polly-import-jscop -polly-import-jscop-postfix=interchanged+tiled+vector -polly-codegen -polly-vectorizer=stripmine -polly-parallel -polly-process-unprofitable | opt -S -O3 -o matmul.polly.interchanged+tiled+vector+openmp.ll


Reading JScop '%for.cond---%for.end19' in function 'init_array' from './init_array___%for.cond---%for.end19.jscop.interchanged+tiled+vector'.
Reading JScop '%for.cond---%for.end30' in function 'main' from './main___%for.cond---%for.end30.jscop.interchanged+tiled+vector'.
```


10. Create the executables
       
```
1.生成汇编 
# -o matmul.normalopt.s	输出目标为汇编文件（.s）
# -relocation-model=pic 生成 位置无关代码（PIC, Position Independent Code），适合用于动态库或可重定位的程序模块

llc matmul.normalopt.ll -o matmul.normalopt.s -relocation-model=pic

2.汇编编译为机器码并链接成可执行文件
clang matmul.normalopt.s -o matmul.normalopt.exe
```



```
llc matmul.polly.interchanged.ll -o matmul.polly.interchanged.s -relocation-model=pic
clang matmul.polly.interchanged.s -o matmul.polly.interchanged.exe
```


```
llc matmul.polly.interchanged+tiled.ll -o matmul.polly.interchanged+tiled.s -relocation-model=pic
clang matmul.polly.interchanged+tiled.s -o matmul.polly.interchanged+tiled.exe

```
```
llc matmul.polly.interchanged+tiled+vector.ll -o matmul.polly.interchanged+tiled+vector.s -relocation-model=pic
clang matmul.polly.interchanged+tiled+vector.s -o matmul.polly.interchanged+tiled+vector.exe

```
```
llc matmul.polly.interchanged+tiled+vector+openmp.ll -o matmul.polly.interchanged+tiled+vector+openmp.s -relocation-model=pic
clang matmul.polly.interchanged+tiled+vector+openmp.s -lgomp -o matmul.polly.interchanged+tiled+vector+openmp.exe
```

11. Compare the runtime of the executables

```
time ./matmul.normalopt.exe
./matmul.normalopt.exe  9.82s user 0.18s system 95% cpu 10.458 total


time ./matmul.polly.interchanged.exe
./matmul.polly.interchanged.exe  9.17s user 0.15s system 98% cpu 9.490 total


time ./matmul.polly.interchanged+tiled.exe
./matmul.polly.interchanged+tiled.exe  0.49s user 0.02s system 97% cpu 0.528 total

time ./matmul.polly.interchanged+tiled+vector.exe
./matmul.polly.interchanged+tiled+vector.exe  0.47s user 0.01s system 98% cpu 0.494 total


time ./matmul.polly.interchanged+tiled+vector+openmp.exe (有问题)
zsh: no such file or directory: ./matmul.polly.interchanged+tiled+vector+openmp.exe
./matmul.polly.interchanged+tiled+vector+openmp.exe  0.00s user 0.00s system 76% cpu 0.001 total

```


### Reference
https://polly.llvm.org/docs/HowToManuallyUseTheIndividualPiecesOfPolly.html
