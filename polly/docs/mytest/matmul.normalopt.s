	.build_version macos, 15, 0	sdk_version 15, 4
	.section	__TEXT,__text,regular,pure_instructions
	.section	__TEXT,__literal16,16byte_literals
	.p2align	4, 0x0                          ## -- Begin function init_array
LCPI0_0:
	.quad	2                               ## 0x2
	.quad	3                               ## 0x3
LCPI0_1:
	.byte	0                               ## 0x0
	.byte	0                               ## 0x0
	.byte	0                               ## 0x0
	.byte	0                               ## 0x0
	.byte	0                               ## 0x0
	.byte	0                               ## 0x0
	.byte	0                               ## 0x0
	.byte	0                               ## 0x0
	.byte	1                               ## 0x1
	.byte	0                               ## 0x0
	.byte	0                               ## 0x0
	.byte	0                               ## 0x0
	.byte	0                               ## 0x0
	.byte	0                               ## 0x0
	.byte	0                               ## 0x0
	.byte	0                               ## 0x0
LCPI0_2:
	.long	1023                            ## 0x3ff
	.long	1023                            ## 0x3ff
	.long	1023                            ## 0x3ff
	.long	1023                            ## 0x3ff
LCPI0_3:
	.quad	0x3fe0000000000000              ## double 0.5
	.quad	0x3fe0000000000000              ## double 0.5
LCPI0_4:
	.quad	4                               ## 0x4
	.quad	4                               ## 0x4
	.section	__TEXT,__literal8,8byte_literals
	.p2align	1, 0x0
LCPI0_5:
	.short	1023                            ## 0x3ff
	.short	1023                            ## 0x3ff
	.short	1023                            ## 0x3ff
	.short	1023                            ## 0x3ff
	.section	__TEXT,__const
LCPI0_6:
	.space	2,4
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
	movaps	LCPI0_0(%rip), %xmm0            ## xmm0 = [2,3]
	movaps	LCPI0_1(%rip), %xmm1            ## xmm1 = [0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0]
	pmovsxwd	LCPI0_5(%rip), %xmm2            ## xmm2 = [1023,1023,1023,1023]
	pcmpeqd	%xmm3, %xmm3
	movapd	LCPI0_3(%rip), %xmm4            ## xmm4 = [5.0E-1,5.0E-1]
	leaq	_A(%rip), %rcx
	leaq	_B(%rip), %rdx
	pmovsxbq	LCPI0_6(%rip), %xmm5            ## xmm5 = [4,4]
	xorl	%esi, %esi
	.p2align	4
LBB0_1:                                 ## %vector.ph
                                        ## =>This Loop Header: Depth=1
                                        ##     Child Loop BB0_2 Depth 2
	movq	%rsi, %xmm6
	pshufd	$68, %xmm6, %xmm6               ## xmm6 = xmm6[0,1,0,1]
	shufps	$136, %xmm6, %xmm6              ## xmm6 = xmm6[0,2,0,2]
	xorl	%edi, %edi
	movaps	%xmm1, %xmm7
	movaps	%xmm0, %xmm8
	.p2align	4
LBB0_2:                                 ## %vector.body
                                        ##   Parent Loop BB0_1 Depth=1
                                        ## =>  This Inner Loop Header: Depth=2
	movaps	%xmm7, %xmm9
	shufps	$136, %xmm8, %xmm9              ## xmm9 = xmm9[0,2],xmm8[0,2]
	pmulld	%xmm6, %xmm9
	pand	%xmm2, %xmm9
	psubd	%xmm3, %xmm9
	cvtdq2pd	%xmm9, %xmm10
	pshufd	$238, %xmm9, %xmm9              ## xmm9 = xmm9[2,3,2,3]
	cvtdq2pd	%xmm9, %xmm9
	mulpd	%xmm4, %xmm9
	mulpd	%xmm4, %xmm10
	cvtpd2ps	%xmm10, %xmm10
	cvtpd2ps	%xmm9, %xmm9
	unpcklpd	%xmm9, %xmm10                   ## xmm10 = xmm10[0],xmm9[0]
	leaq	(%rax,%rdi), %r8
	movapd	%xmm10, (%rcx,%r8)
	movapd	%xmm10, (%rdx,%r8)
	paddq	%xmm5, %xmm7
	paddq	%xmm5, %xmm8
	addq	$16, %rdi
	cmpq	$6144, %rdi                     ## imm = 0x1800
	jne	LBB0_2
## %bb.3:                               ## %for.inc17
                                        ##   in Loop: Header=BB0_1 Depth=1
	incq	%rsi
	addq	$6144, %rax                     ## imm = 0x1800
	cmpq	$1536, %rsi                     ## imm = 0x600
	jne	LBB0_1
## %bb.4:                               ## %for.end19
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
	pushq	%rbx
	pushq	%rax
	.cfi_offset %rbx, -24
	callq	_init_array
	leaq	_A(%rip), %rax
	xorl	%ecx, %ecx
	leaq	_B(%rip), %rdx
	leaq	_C(%rip), %rsi
	.p2align	4
LBB2_1:                                 ## %for.cond1.preheader
                                        ## =>This Loop Header: Depth=1
                                        ##     Child Loop BB2_2 Depth 2
                                        ##       Child Loop BB2_3 Depth 3
	leaq	(%rcx,%rcx,2), %rdi
	shlq	$11, %rdi
	addq	%rsi, %rdi
	movq	%rdx, %r8
	xorl	%r9d, %r9d
	.p2align	4
LBB2_2:                                 ## %for.body3
                                        ##   Parent Loop BB2_1 Depth=1
                                        ## =>  This Loop Header: Depth=2
                                        ##       Child Loop BB2_3 Depth 3
	leaq	(%rdi,%r9,4), %r10
	xorps	%xmm0, %xmm0
	movl	$2, %r11d
	movq	%r8, %rbx
	.p2align	4
LBB2_3:                                 ## %for.body8
                                        ##   Parent Loop BB2_1 Depth=1
                                        ##     Parent Loop BB2_2 Depth=2
                                        ## =>    This Inner Loop Header: Depth=3
	movss	-8(%rax,%r11,4), %xmm1          ## xmm1 = mem[0],zero,zero,zero
	mulss	(%rbx), %xmm1
	movss	-4(%rax,%r11,4), %xmm2          ## xmm2 = mem[0],zero,zero,zero
	addss	%xmm0, %xmm1
	mulss	6144(%rbx), %xmm2
	addss	%xmm1, %xmm2
	movss	(%rax,%r11,4), %xmm0            ## xmm0 = mem[0],zero,zero,zero
	mulss	12288(%rbx), %xmm0
	addss	%xmm2, %xmm0
	addq	$3, %r11
	addq	$18432, %rbx                    ## imm = 0x4800
	cmpq	$1538, %r11                     ## imm = 0x602
	jne	LBB2_3
## %bb.4:                               ## %for.inc25
                                        ##   in Loop: Header=BB2_2 Depth=2
	movss	%xmm0, (%r10)
	incq	%r9
	addq	$4, %r8
	cmpq	$1536, %r9                      ## imm = 0x600
	jne	LBB2_2
## %bb.5:                               ## %for.inc28
                                        ##   in Loop: Header=BB2_1 Depth=1
	incq	%rcx
	addq	$6144, %rax                     ## imm = 0x1800
	cmpq	$1536, %rcx                     ## imm = 0x600
	jne	LBB2_1
## %bb.6:                               ## %for.end30
	xorl	%eax, %eax
	addq	$8, %rsp
	popq	%rbx
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
