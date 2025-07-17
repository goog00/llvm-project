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
	xorl	%eax, %eax
	pmovsxbd	LCPI0_4(%rip), %xmm0            ## xmm0 = [0,1,2,3]
	pmovsxwd	LCPI0_5(%rip), %xmm1            ## xmm1 = [1023,1023,1023,1023]
	pcmpeqd	%xmm2, %xmm2
	movapd	LCPI0_2(%rip), %xmm3            ## xmm3 = [5.0E-1,5.0E-1]
	leaq	_A(%rip), %rcx
	leaq	_B(%rip), %rdx
	pmovsxbd	LCPI0_6(%rip), %xmm4            ## xmm4 = [4,4,4,4]
	xorl	%esi, %esi
	.p2align	4
LBB0_1:                                 ## %polly.loop_header
                                        ## =>This Loop Header: Depth=1
                                        ##     Child Loop BB0_2 Depth 2
	movd	%esi, %xmm5
	pshufd	$0, %xmm5, %xmm5                ## xmm5 = xmm5[0,0,0,0]
	xorl	%edi, %edi
	movdqa	%xmm0, %xmm6
	.p2align	4
LBB0_2:                                 ## %vector.body
                                        ##   Parent Loop BB0_1 Depth=1
                                        ## =>  This Inner Loop Header: Depth=2
	movdqa	%xmm6, %xmm7
	pmulld	%xmm5, %xmm7
	pand	%xmm1, %xmm7
	psubd	%xmm2, %xmm7
	cvtdq2pd	%xmm7, %xmm8
	pshufd	$238, %xmm7, %xmm7              ## xmm7 = xmm7[2,3,2,3]
	cvtdq2pd	%xmm7, %xmm7
	mulpd	%xmm3, %xmm7
	mulpd	%xmm3, %xmm8
	cvtpd2ps	%xmm8, %xmm8
	cvtpd2ps	%xmm7, %xmm7
	unpcklpd	%xmm7, %xmm8                    ## xmm8 = xmm8[0],xmm7[0]
	leaq	(%rax,%rdi), %r8
	movapd	%xmm8, (%rcx,%r8)
	movapd	%xmm8, (%rdx,%r8)
	paddd	%xmm4, %xmm6
	addq	$16, %rdi
	cmpq	$6144, %rdi                     ## imm = 0x1800
	jne	LBB0_2
## %bb.3:                               ## %polly.loop_exit3
                                        ##   in Loop: Header=BB0_1 Depth=1
	incq	%rsi
	addq	$6144, %rax                     ## imm = 0x1800
	cmpq	$1536, %rsi                     ## imm = 0x600
	jne	LBB0_1
## %bb.4:                               ## %polly.exiting
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
	pushq	%r13
	pushq	%r12
	pushq	%rbx
	subq	$88, %rsp
	.cfi_offset %rbx, -56
	.cfi_offset %r12, -48
	.cfi_offset %r13, -40
	.cfi_offset %r14, -32
	.cfi_offset %r15, -24
	callq	_init_array
	leaq	_C(%rip), %rbx
	movl	$9437184, %esi                  ## imm = 0x900000
	movq	%rbx, %rdi
	callq	___bzero
	movl	$64, %eax
	leaq	_A(%rip), %rcx
	movq	%rcx, -56(%rbp)                 ## 8-byte Spill
	movq	$0, -48(%rbp)                   ## 8-byte Folded Spill
	.p2align	4
LBB2_1:                                 ## %polly.loop_header8
                                        ## =>This Loop Header: Depth=1
                                        ##     Child Loop BB2_2 Depth 2
                                        ##       Child Loop BB2_3 Depth 3
                                        ##         Child Loop BB2_4 Depth 4
                                        ##           Child Loop BB2_5 Depth 5
	leaq	_B+192(%rip), %r8
	xorl	%ecx, %ecx
	.p2align	4
LBB2_2:                                 ## %polly.loop_header14
                                        ##   Parent Loop BB2_1 Depth=1
                                        ## =>  This Loop Header: Depth=2
                                        ##       Child Loop BB2_3 Depth 3
                                        ##         Child Loop BB2_4 Depth 4
                                        ##           Child Loop BB2_5 Depth 5
	leaq	(,%rcx,4), %r9
	leaq	64(,%rcx,4), %r10
	leaq	128(,%rcx,4), %r11
	movq	%rcx, -120(%rbp)                ## 8-byte Spill
	leaq	192(,%rcx,4), %r14
	movq	-56(%rbp), %rcx                 ## 8-byte Reload
	movq	%r8, -128(%rbp)                 ## 8-byte Spill
	xorl	%r13d, %r13d
	.p2align	4
LBB2_3:                                 ## %polly.loop_header20
                                        ##   Parent Loop BB2_1 Depth=1
                                        ##     Parent Loop BB2_2 Depth=2
                                        ## =>    This Loop Header: Depth=3
                                        ##         Child Loop BB2_4 Depth 4
                                        ##           Child Loop BB2_5 Depth 5
	movq	%rcx, %r15
	movq	-48(%rbp), %rsi                 ## 8-byte Reload
	.p2align	4
LBB2_4:                                 ## %polly.loop_header26
                                        ##   Parent Loop BB2_1 Depth=1
                                        ##     Parent Loop BB2_2 Depth=2
                                        ##       Parent Loop BB2_3 Depth=3
                                        ## =>      This Loop Header: Depth=4
                                        ##           Child Loop BB2_5 Depth 5
	movq	%rsi, %rdx
	shlq	$11, %rdx
	leaq	(%rdx,%rdx,2), %rdi
	leaq	(%rbx,%rdi), %rdx
	movaps	(%r9,%rdx), %xmm11
	movaps	16(%r9,%rdx), %xmm15
	movaps	32(%r9,%rdx), %xmm12
	movaps	48(%r9,%rdx), %xmm13
	movaps	(%r10,%rdx), %xmm8
	movaps	16(%r10,%rdx), %xmm9
	movaps	32(%r10,%rdx), %xmm10
	movaps	48(%r10,%rdx), %xmm0
	movaps	%xmm0, -80(%rbp)                ## 16-byte Spill
	movaps	(%r11,%rdx), %xmm0
	movaps	%xmm0, -96(%rbp)                ## 16-byte Spill
	movaps	16(%r11,%rdx), %xmm4
	movaps	32(%r11,%rdx), %xmm5
	movaps	48(%r11,%rdx), %xmm14
	movaps	(%r14,%rdx), %xmm2
	movaps	16(%r14,%rdx), %xmm3
	movaps	32(%r14,%rdx), %xmm6
	movaps	48(%r14,%rdx), %xmm7
	movq	%r8, %r12
	movl	$0, %edx
	.p2align	4
LBB2_5:                                 ## %polly.loop_header32
                                        ##   Parent Loop BB2_1 Depth=1
                                        ##     Parent Loop BB2_2 Depth=2
                                        ##       Parent Loop BB2_3 Depth=3
                                        ##         Parent Loop BB2_4 Depth=4
                                        ## =>        This Inner Loop Header: Depth=5
	movaps	%xmm2, -112(%rbp)               ## 16-byte Spill
	movss	(%r15,%rdx,4), %xmm0            ## xmm0 = mem[0],zero,zero,zero
	shufps	$0, %xmm0, %xmm0                ## xmm0 = xmm0[0,0,0,0]
	movaps	-144(%r12), %xmm1
	mulps	%xmm0, %xmm1
	addps	%xmm1, %xmm13
	movaps	-160(%r12), %xmm1
	mulps	%xmm0, %xmm1
	addps	%xmm1, %xmm12
	movaps	-176(%r12), %xmm1
	mulps	%xmm0, %xmm1
	addps	%xmm1, %xmm15
	movaps	-192(%r12), %xmm1
	mulps	%xmm0, %xmm1
	addps	%xmm1, %xmm11
	movaps	-80(%r12), %xmm1
	mulps	%xmm0, %xmm1
	movaps	-80(%rbp), %xmm2                ## 16-byte Reload
	addps	%xmm1, %xmm2
	movaps	%xmm2, -80(%rbp)                ## 16-byte Spill
	movaps	-96(%r12), %xmm1
	mulps	%xmm0, %xmm1
	addps	%xmm1, %xmm10
	movaps	-112(%r12), %xmm1
	mulps	%xmm0, %xmm1
	addps	%xmm1, %xmm9
	movaps	-128(%r12), %xmm1
	mulps	%xmm0, %xmm1
	addps	%xmm1, %xmm8
	movaps	-16(%r12), %xmm1
	mulps	%xmm0, %xmm1
	addps	%xmm1, %xmm14
	movaps	-32(%r12), %xmm1
	mulps	%xmm0, %xmm1
	addps	%xmm1, %xmm5
	movaps	-48(%r12), %xmm1
	mulps	%xmm0, %xmm1
	addps	%xmm1, %xmm4
	movaps	-64(%r12), %xmm1
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
	movaps	-96(%rbp), %xmm4                ## 16-byte Reload
	addps	%xmm1, %xmm4
	movaps	%xmm4, -96(%rbp)                ## 16-byte Spill
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
	movaps	48(%r12), %xmm1
	mulps	%xmm0, %xmm1
	addps	%xmm1, %xmm7
	movaps	32(%r12), %xmm1
	mulps	%xmm0, %xmm1
	addps	%xmm1, %xmm6
	movaps	16(%r12), %xmm1
	mulps	%xmm0, %xmm1
	addps	%xmm1, %xmm3
	mulps	(%r12), %xmm0
	movaps	-112(%rbp), %xmm2               ## 16-byte Reload
	addps	%xmm0, %xmm2
	movaps	%xmm2, -112(%rbp)               ## 16-byte Spill
	movaps	-112(%rbp), %xmm2               ## 16-byte Reload
	incq	%rdx
	addq	$6144, %r12                     ## imm = 0x1800
	cmpq	$64, %rdx
	jne	LBB2_5
## %bb.6:                               ## %polly.loop_exit34
                                        ##   in Loop: Header=BB2_4 Depth=4
	leaq	(%rdi,%r9), %rdx
	movaps	%xmm15, 16(%rbx,%rdx)
	movaps	%xmm11, (%rbx,%rdx)
	movaps	%xmm12, 32(%rbx,%rdx)
	movaps	%xmm13, 48(%rbx,%rdx)
	leaq	(%rdi,%r10), %rdx
	movaps	-80(%rbp), %xmm0                ## 16-byte Reload
	movaps	%xmm0, 48(%rbx,%rdx)
	movaps	%xmm8, (%rbx,%rdx)
	movaps	%xmm9, 16(%rbx,%rdx)
	movaps	%xmm10, 32(%rbx,%rdx)
	leaq	(%rdi,%r11), %rdx
	movaps	%xmm14, 48(%rbx,%rdx)
	movaps	-96(%rbp), %xmm0                ## 16-byte Reload
	movaps	%xmm0, (%rbx,%rdx)
	movaps	%xmm4, 16(%rbx,%rdx)
	movaps	%xmm5, 32(%rbx,%rdx)
	addq	%r14, %rdi
	movaps	%xmm6, 32(%rbx,%rdi)
	movaps	%xmm7, 48(%rbx,%rdi)
	movaps	%xmm2, (%rbx,%rdi)
	movaps	%xmm3, 16(%rbx,%rdi)
	incq	%rsi
	addq	$6144, %r15                     ## imm = 0x1800
	cmpq	%rax, %rsi
	jne	LBB2_4
## %bb.7:                               ## %polly.loop_exit28
                                        ##   in Loop: Header=BB2_3 Depth=3
	leaq	64(%r13), %rdx
	addq	$393216, %r8                    ## imm = 0x60000
	addq	$256, %rcx                      ## imm = 0x100
	cmpq	$1472, %r13                     ## imm = 0x5C0
	movq	%rdx, %r13
	jb	LBB2_3
## %bb.8:                               ## %polly.loop_exit22
                                        ##   in Loop: Header=BB2_2 Depth=2
	movq	-120(%rbp), %rdx                ## 8-byte Reload
	leaq	64(%rdx), %rcx
	movq	-128(%rbp), %r8                 ## 8-byte Reload
	addq	$256, %r8                       ## imm = 0x100
	cmpq	$1472, %rdx                     ## imm = 0x5C0
	jb	LBB2_2
## %bb.9:                               ## %polly.loop_exit16
                                        ##   in Loop: Header=BB2_1 Depth=1
	movq	-48(%rbp), %rdx                 ## 8-byte Reload
	leaq	64(%rdx), %rcx
	addq	$64, %rax
	addq	$393216, -56(%rbp)              ## 8-byte Folded Spill
                                        ## imm = 0x60000
	cmpq	$1472, %rdx                     ## imm = 0x5C0
	movq	%rcx, -48(%rbp)                 ## 8-byte Spill
	jb	LBB2_1
## %bb.10:                              ## %polly.exiting
	xorl	%eax, %eax
	addq	$88, %rsp
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
