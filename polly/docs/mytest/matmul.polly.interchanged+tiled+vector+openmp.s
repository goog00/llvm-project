	.build_version macos, 15, 0	sdk_version 15, 4
	.section	__TEXT,__text,regular,pure_instructions
	.section	__TEXT,__literal16,16byte_literals
	.p2align	4, 0x0                          ## -- Begin function init_array
LCPI0_0:
	.long	0                               ## 0x0
	.long	1                               ## 0x1
	.long	2                               ## 0x2
	.long	3                               ## 0x3
LCPI0_1:
	.long	1023                            ## 0x3ff
	.long	1023                            ## 0x3ff
	.long	1023                            ## 0x3ff
	.long	1023                            ## 0x3ff
LCPI0_2:
	.quad	0x3fe0000000000000              ## double 0.5
	.quad	0x3fe0000000000000              ## double 0.5
LCPI0_3:
	.long	4                               ## 0x4
	.long	4                               ## 0x4
	.long	4                               ## 0x4
	.long	4                               ## 0x4
	.section	__TEXT,__literal4,4byte_literals
LCPI0_4:
	.byte	0                               ## 0x0
	.byte	1                               ## 0x1
	.byte	2                               ## 0x2
	.byte	3                               ## 0x3
LCPI0_6:
	.space	4,4
	.section	__TEXT,__literal8,8byte_literals
	.p2align	1, 0x0
LCPI0_5:
	.short	1023                            ## 0x3ff
	.short	1023                            ## 0x3ff
	.short	1023                            ## 0x3ff
	.short	1023                            ## 0x3ff
	.section	__TEXT,__text,regular,pure_instructions
	.globl	_init_array
	.p2align	4
_init_array:                            ## @init_array
	.cfi_startproc
## %bb.0:                               ## %entry
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset %rbp, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register %rbp
	pushq	%r15
	pushq	%r14
	pushq	%r12
	pushq	%rbx
	subq	$32, %rsp
	.cfi_offset %rbx, -48
	.cfi_offset %r12, -40
	.cfi_offset %r14, -32
	.cfi_offset %r15, -24
	leaq	_init_array_polly_subfn(%rip), %rdi
	leaq	-40(%rbp), %rsi
	movl	$1536, %r8d                     ## imm = 0x600
	movl	$1, %r9d
	xorl	%edx, %edx
	xorl	%ecx, %ecx
	callq	_GOMP_parallel_loop_runtime_start
	leaq	-56(%rbp), %rdi
	leaq	-48(%rbp), %rsi
	callq	_GOMP_loop_runtime_next
	testb	%al, %al
	je	LBB0_7
## %bb.1:
	pmovsxbd	LCPI0_4(%rip), %xmm4            ## xmm4 = [0,1,2,3]
	pmovsxwd	LCPI0_5(%rip), %xmm5            ## xmm5 = [1023,1023,1023,1023]
	pcmpeqd	%xmm6, %xmm6
	movapd	LCPI0_2(%rip), %xmm7            ## xmm7 = [5.0E-1,5.0E-1]
	leaq	_A(%rip), %r15
	leaq	_B(%rip), %r12
	pmovsxbd	LCPI0_6(%rip), %xmm8            ## xmm8 = [4,4,4,4]
	leaq	-56(%rbp), %rbx
	leaq	-48(%rbp), %r14
	.p2align	4
LBB0_3:                                 ## %polly.par.loadIVBounds.i
                                        ## =>This Loop Header: Depth=1
                                        ##     Child Loop BB0_4 Depth 2
                                        ##       Child Loop BB0_5 Depth 3
	movq	-56(%rbp), %rcx
	movq	-48(%rbp), %rax
	decq	%rax
	movq	%rcx, %rdx
	shlq	$11, %rdx
	leaq	(%rdx,%rdx,2), %rdx
	.p2align	4
LBB0_4:                                 ## %polly.loop_header.i
                                        ##   Parent Loop BB0_3 Depth=1
                                        ## =>  This Loop Header: Depth=2
                                        ##       Child Loop BB0_5 Depth 3
	movd	%ecx, %xmm0
	pshufd	$0, %xmm0, %xmm0                ## xmm0 = xmm0[0,0,0,0]
	xorl	%esi, %esi
	movdqa	%xmm4, %xmm1
	.p2align	4
LBB0_5:                                 ## %vector.body
                                        ##   Parent Loop BB0_3 Depth=1
                                        ##     Parent Loop BB0_4 Depth=2
                                        ## =>    This Inner Loop Header: Depth=3
	movdqa	%xmm1, %xmm2
	pmulld	%xmm0, %xmm2
	pand	%xmm5, %xmm2
	psubd	%xmm6, %xmm2
	cvtdq2pd	%xmm2, %xmm3
	pshufd	$238, %xmm2, %xmm2              ## xmm2 = xmm2[2,3,2,3]
	cvtdq2pd	%xmm2, %xmm2
	mulpd	%xmm7, %xmm2
	mulpd	%xmm7, %xmm3
	cvtpd2ps	%xmm3, %xmm3
	cvtpd2ps	%xmm2, %xmm2
	unpcklpd	%xmm2, %xmm3                    ## xmm3 = xmm3[0],xmm2[0]
	leaq	(%rdx,%rsi), %rdi
	movapd	%xmm3, (%r15,%rdi)
	movapd	%xmm3, (%r12,%rdi)
	paddd	%xmm8, %xmm1
	addq	$16, %rsi
	cmpq	$6144, %rsi                     ## imm = 0x1800
	jne	LBB0_5
## %bb.6:                               ## %polly.loop_exit3.i
                                        ##   in Loop: Header=BB0_4 Depth=2
	leaq	1(%rcx), %rsi
	addq	$6144, %rdx                     ## imm = 0x1800
	cmpq	%rax, %rcx
	movq	%rsi, %rcx
	jl	LBB0_4
## %bb.2:                               ## %polly.par.checkNext.loopexit.i
                                        ##   in Loop: Header=BB0_3 Depth=1
	movq	%rbx, %rdi
	movq	%r14, %rsi
	callq	_GOMP_loop_runtime_next
	pmovsxbd	LCPI0_6(%rip), %xmm8            ## xmm8 = [4,4,4,4]
	movapd	LCPI0_2(%rip), %xmm7            ## xmm7 = [5.0E-1,5.0E-1]
	pcmpeqd	%xmm6, %xmm6
	pmovsxwd	LCPI0_5(%rip), %xmm5            ## xmm5 = [1023,1023,1023,1023]
	pmovsxbd	LCPI0_4(%rip), %xmm4            ## xmm4 = [0,1,2,3]
	testb	%al, %al
	jne	LBB0_3
LBB0_7:                                 ## %init_array_polly_subfn.exit
	callq	_GOMP_loop_end_nowait
	callq	_GOMP_parallel_end
	addq	$32, %rsp
	popq	%rbx
	popq	%r12
	popq	%r14
	popq	%r15
	popq	%rbp
	retq
	.cfi_endproc
                                        ## -- End function
	.globl	_print_array                    ## -- Begin function print_array
	.p2align	4
_print_array:                           ## @print_array
	.cfi_startproc
## %bb.0:                               ## %entry
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset %rbp, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register %rbp
	pushq	%r15
	pushq	%r14
	pushq	%r13
	pushq	%r12
	pushq	%rbx
	pushq	%rax
	.cfi_offset %rbx, -56
	.cfi_offset %r12, -48
	.cfi_offset %r13, -40
	.cfi_offset %r14, -32
	.cfi_offset %r15, -24
	leaq	_C(%rip), %r12
	xorl	%eax, %eax
	movq	___stdoutp@GOTPCREL(%rip), %r13
	leaq	L_.str(%rip), %rbx
	jmp	LBB1_1
	.p2align	4
LBB1_5:                                 ## %for.end
                                        ##   in Loop: Header=BB1_1 Depth=1
	movq	(%r13), %rsi
	movl	$10, %edi
	callq	_fputc
	movq	-48(%rbp), %rax                 ## 8-byte Reload
	incq	%rax
	addq	$6144, %r12                     ## imm = 0x1800
	cmpq	$1536, %rax                     ## imm = 0x600
	je	LBB1_6
LBB1_1:                                 ## %for.cond1.preheader
                                        ## =>This Loop Header: Depth=1
                                        ##     Child Loop BB1_2 Depth 2
	movq	%rax, -48(%rbp)                 ## 8-byte Spill
	xorl	%r14d, %r14d
	jmp	LBB1_2
	.p2align	4
LBB1_4:                                 ## %for.inc
                                        ##   in Loop: Header=BB1_2 Depth=2
	incq	%r14
	cmpq	$1536, %r14                     ## imm = 0x600
	je	LBB1_5
LBB1_2:                                 ## %for.body3
                                        ##   Parent Loop BB1_1 Depth=1
                                        ## =>  This Inner Loop Header: Depth=2
	movq	%r14, %rax
	movabsq	$-3689348814741910323, %rcx     ## imm = 0xCCCCCCCCCCCCCCCD
	mulq	%rcx
	movq	%rdx, %r15
	movq	(%r13), %rdi
	movss	(%r12,%r14,4), %xmm0            ## xmm0 = mem[0],zero,zero,zero
	cvtss2sd	%xmm0, %xmm0
	movq	%rbx, %rsi
	movb	$1, %al
	callq	_fprintf
	shrl	$2, %r15d
	andl	$-16, %r15d
	leal	(%r15,%r15,4), %eax
	addl	$79, %eax
	cmpw	%r14w, %ax
	jne	LBB1_4
## %bb.3:                               ## %if.then
                                        ##   in Loop: Header=BB1_2 Depth=2
	movq	(%r13), %rsi
	movl	$10, %edi
	callq	_fputc
	jmp	LBB1_4
LBB1_6:                                 ## %for.end12
	addq	$8, %rsp
	popq	%rbx
	popq	%r12
	popq	%r13
	popq	%r14
	popq	%r15
	popq	%rbp
	retq
	.cfi_endproc
                                        ## -- End function
	.globl	_main                           ## -- Begin function main
	.p2align	4
_main:                                  ## @main
	.cfi_startproc
## %bb.0:                               ## %entry
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset %rbp, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register %rbp
	pushq	%r15
	pushq	%r14
	pushq	%rbx
	subq	$24, %rsp
	.cfi_offset %rbx, -40
	.cfi_offset %r14, -32
	.cfi_offset %r15, -24
	callq	_init_array
	leaq	_main_polly_subfn(%rip), %rdi
	leaq	-32(%rbp), %rsi
	movl	$1536, %r8d                     ## imm = 0x600
	movl	$1, %r9d
	xorl	%edx, %edx
	xorl	%ecx, %ecx
	callq	_GOMP_parallel_loop_runtime_start
	leaq	-48(%rbp), %rdi
	leaq	-40(%rbp), %rsi
	callq	_GOMP_loop_runtime_next
	testb	%al, %al
	je	LBB2_3
## %bb.1:                               ## %polly.par.loadIVBounds.i.preheader
	leaq	_C(%rip), %r15
	leaq	-48(%rbp), %rbx
	leaq	-40(%rbp), %r14
	.p2align	4
LBB2_2:                                 ## %polly.par.loadIVBounds.i
                                        ## =>This Inner Loop Header: Depth=1
	movq	-48(%rbp), %rax
	movq	-40(%rbp), %rcx
	decq	%rcx
	leaq	(%rax,%rax,2), %rdi
	shlq	$11, %rdi
	addq	%r15, %rdi
	cmpq	%rcx, %rax
	cmovgq	%rax, %rcx
	subq	%rax, %rcx
	leaq	(%rcx,%rcx,2), %rsi
	shlq	$11, %rsi
	addq	$6144, %rsi                     ## imm = 0x1800
	callq	___bzero
	movq	%rbx, %rdi
	movq	%r14, %rsi
	callq	_GOMP_loop_runtime_next
	testb	%al, %al
	jne	LBB2_2
LBB2_3:                                 ## %main_polly_subfn.exit
	callq	_GOMP_loop_end_nowait
	callq	_GOMP_parallel_end
	leaq	_main_polly_subfn_1(%rip), %rdi
	leaq	-32(%rbp), %rsi
	movl	$1536, %r8d                     ## imm = 0x600
	movl	$64, %r9d
	xorl	%edx, %edx
	xorl	%ecx, %ecx
	callq	_GOMP_parallel_loop_runtime_start
	callq	_main_polly_subfn_1
	callq	_GOMP_parallel_end
	xorl	%eax, %eax
	addq	$24, %rsp
	popq	%rbx
	popq	%r14
	popq	%r15
	popq	%rbp
	retq
	.cfi_endproc
                                        ## -- End function
	.section	__TEXT,__literal16,16byte_literals
	.p2align	4, 0x0                          ## -- Begin function init_array_polly_subfn
LCPI3_0:
	.long	0                               ## 0x0
	.long	1                               ## 0x1
	.long	2                               ## 0x2
	.long	3                               ## 0x3
LCPI3_1:
	.long	1023                            ## 0x3ff
	.long	1023                            ## 0x3ff
	.long	1023                            ## 0x3ff
	.long	1023                            ## 0x3ff
LCPI3_2:
	.quad	0x3fe0000000000000              ## double 0.5
	.quad	0x3fe0000000000000              ## double 0.5
LCPI3_3:
	.long	4                               ## 0x4
	.long	4                               ## 0x4
	.long	4                               ## 0x4
	.long	4                               ## 0x4
	.section	__TEXT,__text,regular,pure_instructions
	.p2align	4
_init_array_polly_subfn:                ## @init_array_polly_subfn
	.cfi_startproc
## %bb.0:                               ## %polly.par.setup
	pushq	%r15
	.cfi_def_cfa_offset 16
	pushq	%r14
	.cfi_def_cfa_offset 24
	pushq	%r12
	.cfi_def_cfa_offset 32
	pushq	%rbx
	.cfi_def_cfa_offset 40
	subq	$24, %rsp
	.cfi_def_cfa_offset 64
	.cfi_offset %rbx, -40
	.cfi_offset %r12, -32
	.cfi_offset %r14, -24
	.cfi_offset %r15, -16
	leaq	16(%rsp), %rdi
	leaq	8(%rsp), %rsi
	callq	_GOMP_loop_runtime_next
	testb	%al, %al
	je	LBB3_2
## %bb.1:
	leaq	_B(%rip), %r15
	leaq	_A(%rip), %r12
	movdqa	LCPI3_0(%rip), %xmm5            ## xmm5 = [0,1,2,3]
	movdqa	LCPI3_1(%rip), %xmm6            ## xmm6 = [1023,1023,1023,1023]
	pcmpeqd	%xmm7, %xmm7
	movapd	LCPI3_2(%rip), %xmm8            ## xmm8 = [5.0E-1,5.0E-1]
	movdqa	LCPI3_3(%rip), %xmm9            ## xmm9 = [4,4,4,4]
	leaq	16(%rsp), %rbx
	leaq	8(%rsp), %r14
	.p2align	4
LBB3_4:                                 ## %polly.par.loadIVBounds
                                        ## =>This Loop Header: Depth=1
                                        ##     Child Loop BB3_5 Depth 2
                                        ##       Child Loop BB3_6 Depth 3
	movq	16(%rsp), %rcx
	movq	8(%rsp), %rax
	decq	%rax
	movq	%rcx, %rdx
	shlq	$11, %rdx
	leaq	(%rdx,%rdx,2), %rdx
	leaq	(%r15,%rdx), %rsi
	addq	%r12, %rdx
	.p2align	4
LBB3_5:                                 ## %polly.loop_header
                                        ##   Parent Loop BB3_4 Depth=1
                                        ## =>  This Loop Header: Depth=2
                                        ##       Child Loop BB3_6 Depth 3
	movd	%ecx, %xmm0
	pshufd	$0, %xmm0, %xmm0                ## xmm0 = xmm0[0,0,0,0]
	movq	$-6144, %rdi                    ## imm = 0xE800
	pshufd	$245, %xmm0, %xmm1              ## xmm1 = xmm0[1,1,3,3]
	movdqa	%xmm5, %xmm2
	.p2align	4
LBB3_6:                                 ## %vector.body
                                        ##   Parent Loop BB3_4 Depth=1
                                        ##     Parent Loop BB3_5 Depth=2
                                        ## =>    This Inner Loop Header: Depth=3
	movdqa	%xmm2, %xmm3
	pmuludq	%xmm0, %xmm3
	pshufd	$232, %xmm3, %xmm3              ## xmm3 = xmm3[0,2,2,3]
	pshufd	$245, %xmm2, %xmm4              ## xmm4 = xmm2[1,1,3,3]
	pmuludq	%xmm1, %xmm4
	pshufd	$232, %xmm4, %xmm4              ## xmm4 = xmm4[0,2,2,3]
	punpckldq	%xmm4, %xmm3            ## xmm3 = xmm3[0],xmm4[0],xmm3[1],xmm4[1]
	pand	%xmm6, %xmm3
	psubd	%xmm7, %xmm3
	cvtdq2pd	%xmm3, %xmm4
	pshufd	$238, %xmm3, %xmm3              ## xmm3 = xmm3[2,3,2,3]
	cvtdq2pd	%xmm3, %xmm3
	mulpd	%xmm8, %xmm3
	mulpd	%xmm8, %xmm4
	cvtpd2ps	%xmm4, %xmm4
	cvtpd2ps	%xmm3, %xmm3
	unpcklpd	%xmm3, %xmm4                    ## xmm4 = xmm4[0],xmm3[0]
	movapd	%xmm4, 6144(%rdx,%rdi)
	movapd	%xmm4, 6144(%rsi,%rdi)
	paddd	%xmm9, %xmm2
	addq	$16, %rdi
	jne	LBB3_6
## %bb.7:                               ## %polly.loop_exit3
                                        ##   in Loop: Header=BB3_5 Depth=2
	addq	$6144, %rsi                     ## imm = 0x1800
	addq	$6144, %rdx                     ## imm = 0x1800
	cmpq	%rax, %rcx
	leaq	1(%rcx), %rcx
	jl	LBB3_5
## %bb.3:                               ## %polly.par.checkNext.loopexit
                                        ##   in Loop: Header=BB3_4 Depth=1
	movq	%rbx, %rdi
	movq	%r14, %rsi
	callq	_GOMP_loop_runtime_next
	movdqa	LCPI3_3(%rip), %xmm9            ## xmm9 = [4,4,4,4]
	movapd	LCPI3_2(%rip), %xmm8            ## xmm8 = [5.0E-1,5.0E-1]
	pcmpeqd	%xmm7, %xmm7
	movdqa	LCPI3_1(%rip), %xmm6            ## xmm6 = [1023,1023,1023,1023]
	movdqa	LCPI3_0(%rip), %xmm5            ## xmm5 = [0,1,2,3]
	testb	%al, %al
	jne	LBB3_4
LBB3_2:                                 ## %polly.par.exit
	callq	_GOMP_loop_end_nowait
	addq	$24, %rsp
	popq	%rbx
	popq	%r12
	popq	%r14
	popq	%r15
	retq
	.cfi_endproc
                                        ## -- End function
	.p2align	4                               ## -- Begin function main_polly_subfn
_main_polly_subfn:                      ## @main_polly_subfn
	.cfi_startproc
## %bb.0:                               ## %polly.par.setup
	pushq	%r15
	.cfi_def_cfa_offset 16
	pushq	%r14
	.cfi_def_cfa_offset 24
	pushq	%rbx
	.cfi_def_cfa_offset 32
	subq	$16, %rsp
	.cfi_def_cfa_offset 48
	.cfi_offset %rbx, -32
	.cfi_offset %r14, -24
	.cfi_offset %r15, -16
	leaq	8(%rsp), %rdi
	movq	%rsp, %rsi
	callq	_GOMP_loop_runtime_next
	testb	%al, %al
	je	LBB4_3
## %bb.1:
	leaq	_C(%rip), %r15
	leaq	8(%rsp), %rbx
	movq	%rsp, %r14
	.p2align	4
LBB4_2:                                 ## %polly.par.loadIVBounds
                                        ## =>This Inner Loop Header: Depth=1
	movq	8(%rsp), %rax
	movq	(%rsp), %rcx
	decq	%rcx
	leaq	(%rax,%rax,2), %rdi
	shlq	$11, %rdi
	addq	%r15, %rdi
	cmpq	%rcx, %rax
	cmovgq	%rax, %rcx
	subq	%rax, %rcx
	leaq	(%rcx,%rcx,2), %rsi
	shlq	$11, %rsi
	addq	$6144, %rsi                     ## imm = 0x1800
	callq	___bzero
	movq	%rbx, %rdi
	movq	%r14, %rsi
	callq	_GOMP_loop_runtime_next
	testb	%al, %al
	jne	LBB4_2
LBB4_3:                                 ## %polly.par.exit
	callq	_GOMP_loop_end_nowait
	addq	$16, %rsp
	popq	%rbx
	popq	%r14
	popq	%r15
	retq
	.cfi_endproc
                                        ## -- End function
	.p2align	4                               ## -- Begin function main_polly_subfn_1
_main_polly_subfn_1:                    ## @main_polly_subfn_1
	.cfi_startproc
## %bb.0:                               ## %polly.par.setup
	pushq	%rbp
	.cfi_def_cfa_offset 16
	pushq	%r15
	.cfi_def_cfa_offset 24
	pushq	%r14
	.cfi_def_cfa_offset 32
	pushq	%r13
	.cfi_def_cfa_offset 40
	pushq	%r12
	.cfi_def_cfa_offset 48
	pushq	%rbx
	.cfi_def_cfa_offset 56
	subq	$104, %rsp
	.cfi_def_cfa_offset 160
	.cfi_offset %rbx, -56
	.cfi_offset %r12, -48
	.cfi_offset %r13, -40
	.cfi_offset %r14, -32
	.cfi_offset %r15, -24
	.cfi_offset %rbp, -16
	leaq	24(%rsp), %rdi
	leaq	16(%rsp), %rsi
	callq	_GOMP_loop_runtime_next
	testb	%al, %al
	je	LBB5_2
## %bb.1:
	leaq	_C(%rip), %r13
	.p2align	4
LBB5_4:                                 ## %polly.par.loadIVBounds
                                        ## =>This Loop Header: Depth=1
                                        ##     Child Loop BB5_5 Depth 2
                                        ##       Child Loop BB5_6 Depth 3
                                        ##         Child Loop BB5_7 Depth 4
                                        ##           Child Loop BB5_8 Depth 5
                                        ##             Child Loop BB5_9 Depth 6
	movq	24(%rsp), %rcx
	movq	16(%rsp), %rax
	decq	%rax
	movq	%rax, 80(%rsp)                  ## 8-byte Spill
	leaq	(%rcx,%rcx,2), %rdx
	shlq	$11, %rdx
	leaq	_A(%rip), %rax
	addq	%rax, %rdx
	movq	%rdx, 8(%rsp)                   ## 8-byte Spill
	.p2align	4
LBB5_5:                                 ## %polly.loop_header
                                        ##   Parent Loop BB5_4 Depth=1
                                        ## =>  This Loop Header: Depth=2
                                        ##       Child Loop BB5_6 Depth 3
                                        ##         Child Loop BB5_7 Depth 4
                                        ##           Child Loop BB5_8 Depth 5
                                        ##             Child Loop BB5_9 Depth 6
	leaq	63(%rcx), %rsi
	leaq	_B+192(%rip), %r8
	xorl	%eax, %eax
	.p2align	4
LBB5_6:                                 ## %polly.loop_header1
                                        ##   Parent Loop BB5_4 Depth=1
                                        ##     Parent Loop BB5_5 Depth=2
                                        ## =>    This Loop Header: Depth=3
                                        ##         Child Loop BB5_7 Depth 4
                                        ##           Child Loop BB5_8 Depth 5
                                        ##             Child Loop BB5_9 Depth 6
	leaq	(,%rax,4), %r9
	leaq	64(,%rax,4), %r10
	leaq	128(,%rax,4), %r11
	movq	%rax, 88(%rsp)                  ## 8-byte Spill
	leaq	192(,%rax,4), %rbp
	movq	8(%rsp), %r15                   ## 8-byte Reload
	movq	%r8, 96(%rsp)                   ## 8-byte Spill
	xorl	%r14d, %r14d
	.p2align	4
LBB5_7:                                 ## %polly.loop_header7
                                        ##   Parent Loop BB5_4 Depth=1
                                        ##     Parent Loop BB5_5 Depth=2
                                        ##       Parent Loop BB5_6 Depth=3
                                        ## =>      This Loop Header: Depth=4
                                        ##           Child Loop BB5_8 Depth 5
                                        ##             Child Loop BB5_9 Depth 6
	movq	%r15, %rdx
	movq	%rcx, %rax
	.p2align	4
LBB5_8:                                 ## %polly.loop_header13
                                        ##   Parent Loop BB5_4 Depth=1
                                        ##     Parent Loop BB5_5 Depth=2
                                        ##       Parent Loop BB5_6 Depth=3
                                        ##         Parent Loop BB5_7 Depth=4
                                        ## =>        This Loop Header: Depth=5
                                        ##             Child Loop BB5_9 Depth 6
	movq	%rax, %rdi
	shlq	$11, %rdi
	leaq	(%rdi,%rdi,2), %rbx
	leaq	(%r13,%rbx), %rdi
	movaps	(%r9,%rdi), %xmm11
	movaps	16(%r9,%rdi), %xmm15
	movaps	32(%r9,%rdi), %xmm12
	movaps	48(%r9,%rdi), %xmm13
	movaps	(%r10,%rdi), %xmm8
	movaps	16(%r10,%rdi), %xmm9
	movaps	32(%r10,%rdi), %xmm10
	movaps	48(%r10,%rdi), %xmm0
	movaps	%xmm0, 32(%rsp)                 ## 16-byte Spill
	movaps	(%r11,%rdi), %xmm0
	movaps	%xmm0, 48(%rsp)                 ## 16-byte Spill
	movaps	16(%r11,%rdi), %xmm4
	movaps	32(%r11,%rdi), %xmm5
	movaps	48(%r11,%rdi), %xmm14
	movaps	(%rbp,%rdi), %xmm2
	movaps	16(%rbp,%rdi), %xmm3
	movaps	32(%rbp,%rdi), %xmm6
	movaps	48(%rbp,%rdi), %xmm7
	movq	$-256, %r12
	movq	%r8, %rdi
	.p2align	4
LBB5_9:                                 ## %polly.loop_header19
                                        ##   Parent Loop BB5_4 Depth=1
                                        ##     Parent Loop BB5_5 Depth=2
                                        ##       Parent Loop BB5_6 Depth=3
                                        ##         Parent Loop BB5_7 Depth=4
                                        ##           Parent Loop BB5_8 Depth=5
                                        ## =>          This Inner Loop Header: Depth=6
	movaps	%xmm2, 64(%rsp)                 ## 16-byte Spill
	movss	256(%rdx,%r12), %xmm0           ## xmm0 = mem[0],zero,zero,zero
	shufps	$0, %xmm0, %xmm0                ## xmm0 = xmm0[0,0,0,0]
	movaps	-144(%rdi), %xmm1
	mulps	%xmm0, %xmm1
	addps	%xmm1, %xmm13
	movaps	-160(%rdi), %xmm1
	mulps	%xmm0, %xmm1
	addps	%xmm1, %xmm12
	movaps	-176(%rdi), %xmm1
	mulps	%xmm0, %xmm1
	addps	%xmm1, %xmm15
	movaps	-192(%rdi), %xmm1
	mulps	%xmm0, %xmm1
	addps	%xmm1, %xmm11
	movaps	-80(%rdi), %xmm1
	mulps	%xmm0, %xmm1
	movaps	32(%rsp), %xmm2                 ## 16-byte Reload
	addps	%xmm1, %xmm2
	movaps	%xmm2, 32(%rsp)                 ## 16-byte Spill
	movaps	-96(%rdi), %xmm1
	mulps	%xmm0, %xmm1
	addps	%xmm1, %xmm10
	movaps	-112(%rdi), %xmm1
	mulps	%xmm0, %xmm1
	addps	%xmm1, %xmm9
	movaps	-128(%rdi), %xmm1
	mulps	%xmm0, %xmm1
	addps	%xmm1, %xmm8
	movaps	-16(%rdi), %xmm1
	mulps	%xmm0, %xmm1
	addps	%xmm1, %xmm14
	movaps	-32(%rdi), %xmm1
	mulps	%xmm0, %xmm1
	addps	%xmm1, %xmm5
	movaps	-48(%rdi), %xmm1
	mulps	%xmm0, %xmm1
	addps	%xmm1, %xmm4
	movaps	-64(%rdi), %xmm1
	mulps	%xmm0, %xmm1
	movaps	%xmm15, %xmm2
	movaps	%xmm14, %xmm15
	movaps	%xmm13, %xmm14
	movaps	%xmm12, %xmm13
	movaps	%xmm11, %xmm12
	movaps	%xmm10, %xmm11
	movaps	%xmm9, %xmm10
	movaps	%xmm8, %xmm9
	movaps	%xmm7, %xmm8
	movaps	%xmm6, %xmm7
	movaps	%xmm5, %xmm6
	movaps	%xmm4, %xmm5
	movaps	48(%rsp), %xmm4                 ## 16-byte Reload
	addps	%xmm1, %xmm4
	movaps	%xmm4, 48(%rsp)                 ## 16-byte Spill
	movaps	%xmm5, %xmm4
	movaps	%xmm6, %xmm5
	movaps	%xmm7, %xmm6
	movaps	%xmm8, %xmm7
	movaps	%xmm9, %xmm8
	movaps	%xmm10, %xmm9
	movaps	%xmm11, %xmm10
	movaps	%xmm12, %xmm11
	movaps	%xmm13, %xmm12
	movaps	%xmm14, %xmm13
	movaps	%xmm15, %xmm14
	movaps	%xmm2, %xmm15
	movaps	48(%rdi), %xmm1
	mulps	%xmm0, %xmm1
	addps	%xmm1, %xmm7
	movaps	32(%rdi), %xmm1
	mulps	%xmm0, %xmm1
	addps	%xmm1, %xmm6
	movaps	16(%rdi), %xmm1
	mulps	%xmm0, %xmm1
	addps	%xmm1, %xmm3
	mulps	(%rdi), %xmm0
	movaps	64(%rsp), %xmm2                 ## 16-byte Reload
	addps	%xmm0, %xmm2
	movaps	%xmm2, 64(%rsp)                 ## 16-byte Spill
	movaps	64(%rsp), %xmm2                 ## 16-byte Reload
	addq	$6144, %rdi                     ## imm = 0x1800
	addq	$4, %r12
	jne	LBB5_9
## %bb.10:                              ## %polly.loop_exit21
                                        ##   in Loop: Header=BB5_8 Depth=5
	leaq	(%rbx,%r9), %rdi
	movaps	%xmm15, 16(%r13,%rdi)
	movaps	%xmm11, (%r13,%rdi)
	movaps	%xmm12, 32(%r13,%rdi)
	movaps	%xmm13, 48(%r13,%rdi)
	leaq	(%rbx,%r10), %rdi
	movaps	32(%rsp), %xmm0                 ## 16-byte Reload
	movaps	%xmm0, 48(%r13,%rdi)
	movaps	%xmm8, (%r13,%rdi)
	movaps	%xmm9, 16(%r13,%rdi)
	movaps	%xmm10, 32(%r13,%rdi)
	leaq	(%rbx,%r11), %rdi
	movaps	%xmm14, 48(%r13,%rdi)
	movaps	48(%rsp), %xmm0                 ## 16-byte Reload
	movaps	%xmm0, (%r13,%rdi)
	movaps	%xmm4, 16(%r13,%rdi)
	movaps	%xmm5, 32(%r13,%rdi)
	addq	%rbp, %rbx
	movaps	%xmm6, 32(%r13,%rbx)
	movaps	%xmm7, 48(%r13,%rbx)
	movaps	%xmm2, (%r13,%rbx)
	movaps	%xmm3, 16(%r13,%rbx)
	addq	$6144, %rdx                     ## imm = 0x1800
	cmpq	%rsi, %rax
	leaq	1(%rax), %rax
	jl	LBB5_8
## %bb.11:                              ## %polly.loop_exit15
                                        ##   in Loop: Header=BB5_7 Depth=4
	addq	$393216, %r8                    ## imm = 0x60000
	addq	$256, %r15                      ## imm = 0x100
	cmpq	$1472, %r14                     ## imm = 0x5C0
	leaq	64(%r14), %r14
	jb	LBB5_7
## %bb.12:                              ## %polly.loop_exit9
                                        ##   in Loop: Header=BB5_6 Depth=3
	movq	96(%rsp), %r8                   ## 8-byte Reload
	addq	$256, %r8                       ## imm = 0x100
	movq	88(%rsp), %rax                  ## 8-byte Reload
	cmpq	$1472, %rax                     ## imm = 0x5C0
	leaq	64(%rax), %rax
	jb	LBB5_6
## %bb.13:                              ## %polly.loop_exit3
                                        ##   in Loop: Header=BB5_5 Depth=2
	addq	$64, %rcx
	addq	$393216, 8(%rsp)                ## 8-byte Folded Spill
                                        ## imm = 0x60000
	cmpq	80(%rsp), %rcx                  ## 8-byte Folded Reload
	jle	LBB5_5
## %bb.3:                               ## %polly.par.checkNext.loopexit
                                        ##   in Loop: Header=BB5_4 Depth=1
	leaq	24(%rsp), %rdi
	leaq	16(%rsp), %rsi
	callq	_GOMP_loop_runtime_next
	testb	%al, %al
	jne	LBB5_4
LBB5_2:                                 ## %polly.par.exit
	callq	_GOMP_loop_end_nowait
	addq	$104, %rsp
	popq	%rbx
	popq	%r12
	popq	%r13
	popq	%r14
	popq	%r15
	popq	%rbp
	retq
	.cfi_endproc
                                        ## -- End function
	.globl	_A                              ## @A
.zerofill __DATA,__common,_A,9437184,4
	.globl	_B                              ## @B
.zerofill __DATA,__common,_B,9437184,4
	.section	__TEXT,__cstring,cstring_literals
L_.str:                                 ## @.str
	.asciz	"%lf "

	.globl	_C                              ## @C
.zerofill __DATA,__common,_C,9437184,4
.subsections_via_symbols
