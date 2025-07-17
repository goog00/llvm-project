; ModuleID = '<stdin>'
source_filename = "matmul.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx15.0.0"

@A = local_unnamed_addr global [1536 x [1536 x float]] zeroinitializer, align 16
@B = local_unnamed_addr global [1536 x [1536 x float]] zeroinitializer, align 16
@__stdoutp = external local_unnamed_addr global ptr, align 8
@.str = private unnamed_addr constant [5 x i8] c"%lf \00", align 1
@C = local_unnamed_addr global [1536 x [1536 x float]] zeroinitializer, align 16

; Function Attrs: nofree noinline norecurse nosync nounwind ssp memory(write, argmem: none, inaccessiblemem: none) uwtable
define void @init_array() local_unnamed_addr #0 {
entry:
  br label %polly.loop_header

polly.exiting:                                    ; preds = %polly.loop_exit3
  ret void

polly.loop_header:                                ; preds = %entry, %polly.loop_exit3
  %polly.indvar = phi i64 [ 0, %entry ], [ %polly.indvar_next, %polly.loop_exit3 ]
  %0 = mul nuw nsw i64 %polly.indvar, 6144
  %scevgep = getelementptr i8, ptr @A, i64 %0
  %scevgep8 = getelementptr i8, ptr @B, i64 %0
  %1 = trunc i64 %polly.indvar to i32
  %broadcast.splatinsert = insertelement <4 x i32> poison, i32 %1, i64 0
  %broadcast.splat = shufflevector <4 x i32> %broadcast.splatinsert, <4 x i32> poison, <4 x i32> zeroinitializer
  br label %vector.body

vector.body:                                      ; preds = %vector.body, %polly.loop_header
  %index = phi i64 [ 0, %polly.loop_header ], [ %index.next, %vector.body ]
  %vec.ind = phi <4 x i32> [ <i32 0, i32 1, i32 2, i32 3>, %polly.loop_header ], [ %vec.ind.next, %vector.body ]
  %2 = mul <4 x i32> %vec.ind, %broadcast.splat
  %3 = and <4 x i32> %2, splat (i32 1023)
  %4 = add nuw nsw <4 x i32> %3, splat (i32 1)
  %5 = uitofp nneg <4 x i32> %4 to <4 x double>
  %6 = fmul <4 x double> %5, splat (double 5.000000e-01)
  %7 = fptrunc <4 x double> %6 to <4 x float>
  %8 = shl nuw nsw i64 %index, 2
  %9 = getelementptr i8, ptr %scevgep, i64 %8
  store <4 x float> %7, ptr %9, align 16, !alias.scope !6, !noalias !9
  %10 = getelementptr i8, ptr %scevgep8, i64 %8
  store <4 x float> %7, ptr %10, align 16, !alias.scope !9, !noalias !6
  %index.next = add nuw i64 %index, 4
  %vec.ind.next = add <4 x i32> %vec.ind, splat (i32 4)
  %11 = icmp eq i64 %index.next, 1536
  br i1 %11, label %polly.loop_exit3, label %vector.body, !llvm.loop !11

polly.loop_exit3:                                 ; preds = %vector.body
  %polly.indvar_next = add nuw nsw i64 %polly.indvar, 1
  %exitcond1.not = icmp eq i64 %polly.indvar_next, 1536
  br i1 %exitcond1.not, label %polly.exiting, label %polly.loop_header
}

; Function Attrs: nofree noinline nounwind ssp uwtable
define void @print_array() local_unnamed_addr #1 {
entry:
  br label %for.cond1.preheader

for.cond1.preheader:                              ; preds = %entry, %for.end
  %indvars.iv6 = phi i64 [ 0, %entry ], [ %indvars.iv.next7, %for.end ]
  br label %for.body3

for.body3:                                        ; preds = %for.cond1.preheader, %for.inc
  %indvars.iv = phi i64 [ 0, %for.cond1.preheader ], [ %indvars.iv.next, %for.inc ]
  %0 = load ptr, ptr @__stdoutp, align 8
  %arrayidx5 = getelementptr inbounds nuw [1536 x [1536 x float]], ptr @C, i64 0, i64 %indvars.iv6, i64 %indvars.iv
  %1 = load float, ptr %arrayidx5, align 4
  %conv = fpext float %1 to double
  %call = tail call i32 (ptr, ptr, ...) @fprintf(ptr noundef %0, ptr noundef nonnull @.str, double noundef %conv) #7
  %rem.lhs.trunc = trunc i64 %indvars.iv to i16
  %rem2 = urem i16 %rem.lhs.trunc, 80
  %cmp6 = icmp eq i16 %rem2, 79
  br i1 %cmp6, label %if.then, label %for.inc

if.then:                                          ; preds = %for.body3
  %2 = load ptr, ptr @__stdoutp, align 8
  %fputc1 = tail call i32 @fputc(i32 10, ptr %2)
  br label %for.inc

for.inc:                                          ; preds = %if.then, %for.body3
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  %exitcond.not = icmp eq i64 %indvars.iv.next, 1536
  br i1 %exitcond.not, label %for.end, label %for.body3, !llvm.loop !14

for.end:                                          ; preds = %for.inc
  %3 = load ptr, ptr @__stdoutp, align 8
  %fputc = tail call i32 @fputc(i32 10, ptr %3)
  %indvars.iv.next7 = add nuw nsw i64 %indvars.iv6, 1
  %exitcond9.not = icmp eq i64 %indvars.iv.next7, 1536
  br i1 %exitcond9.not, label %for.end12, label %for.cond1.preheader, !llvm.loop !16

for.end12:                                        ; preds = %for.end
  ret void
}

; Function Attrs: nofree nounwind
declare noundef i32 @fprintf(ptr nocapture noundef, ptr nocapture noundef readonly, ...) local_unnamed_addr #2

; Function Attrs: nofree noinline norecurse nosync nounwind ssp memory(readwrite, argmem: write, inaccessiblemem: none) uwtable
define noundef i32 @main() local_unnamed_addr #3 {
entry:
  tail call void @init_array()
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(9437184) @C, i8 0, i64 9437184, i1 false), !alias.scope !17, !noalias !20
  br label %polly.loop_header8

polly.exiting:                                    ; preds = %polly.loop_exit16
  ret i32 0

polly.loop_header8:                               ; preds = %entry, %polly.loop_exit16
  %indvars.iv5 = phi i64 [ 64, %entry ], [ %indvars.iv.next6, %polly.loop_exit16 ]
  %polly.indvar11 = phi i64 [ 0, %entry ], [ %polly.indvar_next12, %polly.loop_exit16 ]
  br label %polly.loop_header14

polly.loop_exit16:                                ; preds = %polly.loop_exit22
  %polly.indvar_next12 = add nuw nsw i64 %polly.indvar11, 64
  %polly.loop_cond13 = icmp samesign ult i64 %polly.indvar11, 1472
  %indvars.iv.next6 = add nuw nsw i64 %indvars.iv5, 64
  br i1 %polly.loop_cond13, label %polly.loop_header8, label %polly.exiting

polly.loop_header14:                              ; preds = %polly.loop_header8, %polly.loop_exit22
  %polly.indvar17 = phi i64 [ 0, %polly.loop_header8 ], [ %polly.indvar_next18, %polly.loop_exit22 ]
  %0 = shl nuw nsw i64 %polly.indvar17, 2
  %offset.idx.1 = shl i64 %polly.indvar17, 2
  %1 = or disjoint i64 %offset.idx.1, 32
  %offset.idx.2 = shl i64 %polly.indvar17, 2
  %2 = or disjoint i64 %offset.idx.2, 64
  %offset.idx.3 = shl i64 %polly.indvar17, 2
  %3 = or disjoint i64 %offset.idx.3, 96
  %offset.idx.4 = shl i64 %polly.indvar17, 2
  %4 = or disjoint i64 %offset.idx.4, 128
  %offset.idx.5 = shl i64 %polly.indvar17, 2
  %5 = or disjoint i64 %offset.idx.5, 160
  %offset.idx.6 = shl i64 %polly.indvar17, 2
  %6 = or disjoint i64 %offset.idx.6, 192
  %offset.idx.7 = shl i64 %polly.indvar17, 2
  %7 = or disjoint i64 %offset.idx.7, 224
  br label %polly.loop_header20

polly.loop_exit22:                                ; preds = %polly.loop_exit28
  %polly.indvar_next18 = add nuw nsw i64 %polly.indvar17, 64
  %polly.loop_cond19 = icmp samesign ult i64 %polly.indvar17, 1472
  br i1 %polly.loop_cond19, label %polly.loop_header14, label %polly.loop_exit16

polly.loop_header20:                              ; preds = %polly.loop_header14, %polly.loop_exit28
  %indvars.iv2 = phi i64 [ 64, %polly.loop_header14 ], [ %indvars.iv.next3, %polly.loop_exit28 ]
  %polly.indvar23 = phi i64 [ 0, %polly.loop_header14 ], [ %polly.indvar_next24, %polly.loop_exit28 ]
  br label %polly.loop_header26

polly.loop_exit28:                                ; preds = %polly.loop_exit34
  %polly.indvar_next24 = add nuw nsw i64 %polly.indvar23, 64
  %polly.loop_cond25 = icmp samesign ult i64 %polly.indvar23, 1472
  %indvars.iv.next3 = add nuw nsw i64 %indvars.iv2, 64
  br i1 %polly.loop_cond25, label %polly.loop_header20, label %polly.loop_exit22

polly.loop_header26:                              ; preds = %polly.loop_header20, %polly.loop_exit34
  %polly.indvar29 = phi i64 [ %polly.indvar11, %polly.loop_header20 ], [ %polly.indvar_next30, %polly.loop_exit34 ]
  %8 = mul nuw nsw i64 %polly.indvar29, 6144
  %scevgep44 = getelementptr i8, ptr @C, i64 %8
  %scevgep46 = getelementptr i8, ptr @A, i64 %8
  %9 = getelementptr i8, ptr %scevgep44, i64 %0
  %10 = getelementptr i8, ptr %9, i64 16
  %11 = getelementptr i8, ptr %scevgep44, i64 %1
  %12 = getelementptr i8, ptr %11, i64 16
  %13 = getelementptr i8, ptr %scevgep44, i64 %2
  %14 = getelementptr i8, ptr %13, i64 16
  %15 = getelementptr i8, ptr %scevgep44, i64 %3
  %16 = getelementptr i8, ptr %15, i64 16
  %17 = getelementptr i8, ptr %scevgep44, i64 %4
  %18 = getelementptr i8, ptr %17, i64 16
  %19 = getelementptr i8, ptr %scevgep44, i64 %5
  %20 = getelementptr i8, ptr %19, i64 16
  %21 = getelementptr i8, ptr %scevgep44, i64 %6
  %22 = getelementptr i8, ptr %21, i64 16
  %23 = getelementptr i8, ptr %scevgep44, i64 %7
  %24 = getelementptr i8, ptr %23, i64 16
  %.promoted = load <4 x float>, ptr %9, align 16, !alias.scope !17, !noalias !20
  %.promoted12 = load <4 x float>, ptr %10, align 16, !alias.scope !17, !noalias !20
  %.promoted15 = load <4 x float>, ptr %11, align 16, !alias.scope !17, !noalias !20
  %.promoted17 = load <4 x float>, ptr %12, align 16, !alias.scope !17, !noalias !20
  %.promoted19 = load <4 x float>, ptr %13, align 16, !alias.scope !17, !noalias !20
  %.promoted21 = load <4 x float>, ptr %14, align 16, !alias.scope !17, !noalias !20
  %.promoted23 = load <4 x float>, ptr %15, align 16, !alias.scope !17, !noalias !20
  %.promoted25 = load <4 x float>, ptr %16, align 16, !alias.scope !17, !noalias !20
  %.promoted27 = load <4 x float>, ptr %17, align 16, !alias.scope !17, !noalias !20
  %.promoted29 = load <4 x float>, ptr %18, align 16, !alias.scope !17, !noalias !20
  %.promoted31 = load <4 x float>, ptr %19, align 16, !alias.scope !17, !noalias !20
  %.promoted33 = load <4 x float>, ptr %20, align 16, !alias.scope !17, !noalias !20
  %.promoted35 = load <4 x float>, ptr %21, align 16, !alias.scope !17, !noalias !20
  %.promoted37 = load <4 x float>, ptr %22, align 16, !alias.scope !17, !noalias !20
  %.promoted39 = load <4 x float>, ptr %23, align 16, !alias.scope !17, !noalias !20
  %.promoted41 = load <4 x float>, ptr %24, align 16, !alias.scope !17, !noalias !20
  br label %polly.loop_header32

polly.loop_exit34:                                ; preds = %polly.loop_header32
  store <4 x float> %43, ptr %9, align 16, !alias.scope !17, !noalias !20
  store <4 x float> %44, ptr %10, align 16, !alias.scope !17, !noalias !20
  store <4 x float> %47, ptr %11, align 16, !alias.scope !17, !noalias !20
  store <4 x float> %48, ptr %12, align 16, !alias.scope !17, !noalias !20
  store <4 x float> %51, ptr %13, align 16, !alias.scope !17, !noalias !20
  store <4 x float> %52, ptr %14, align 16, !alias.scope !17, !noalias !20
  store <4 x float> %55, ptr %15, align 16, !alias.scope !17, !noalias !20
  store <4 x float> %56, ptr %16, align 16, !alias.scope !17, !noalias !20
  store <4 x float> %59, ptr %17, align 16, !alias.scope !17, !noalias !20
  store <4 x float> %60, ptr %18, align 16, !alias.scope !17, !noalias !20
  store <4 x float> %63, ptr %19, align 16, !alias.scope !17, !noalias !20
  store <4 x float> %64, ptr %20, align 16, !alias.scope !17, !noalias !20
  store <4 x float> %67, ptr %21, align 16, !alias.scope !17, !noalias !20
  store <4 x float> %68, ptr %22, align 16, !alias.scope !17, !noalias !20
  store <4 x float> %71, ptr %23, align 16, !alias.scope !17, !noalias !20
  store <4 x float> %72, ptr %24, align 16, !alias.scope !17, !noalias !20
  %polly.indvar_next30 = add nuw nsw i64 %polly.indvar29, 1
  %exitcond7.not = icmp eq i64 %polly.indvar_next30, %indvars.iv5
  br i1 %exitcond7.not, label %polly.loop_exit28, label %polly.loop_header26

polly.loop_header32:                              ; preds = %polly.loop_header26, %polly.loop_header32
  %25 = phi <4 x float> [ %.promoted41, %polly.loop_header26 ], [ %72, %polly.loop_header32 ]
  %26 = phi <4 x float> [ %.promoted39, %polly.loop_header26 ], [ %71, %polly.loop_header32 ]
  %27 = phi <4 x float> [ %.promoted37, %polly.loop_header26 ], [ %68, %polly.loop_header32 ]
  %28 = phi <4 x float> [ %.promoted35, %polly.loop_header26 ], [ %67, %polly.loop_header32 ]
  %29 = phi <4 x float> [ %.promoted33, %polly.loop_header26 ], [ %64, %polly.loop_header32 ]
  %30 = phi <4 x float> [ %.promoted31, %polly.loop_header26 ], [ %63, %polly.loop_header32 ]
  %31 = phi <4 x float> [ %.promoted29, %polly.loop_header26 ], [ %60, %polly.loop_header32 ]
  %32 = phi <4 x float> [ %.promoted27, %polly.loop_header26 ], [ %59, %polly.loop_header32 ]
  %33 = phi <4 x float> [ %.promoted25, %polly.loop_header26 ], [ %56, %polly.loop_header32 ]
  %34 = phi <4 x float> [ %.promoted23, %polly.loop_header26 ], [ %55, %polly.loop_header32 ]
  %35 = phi <4 x float> [ %.promoted21, %polly.loop_header26 ], [ %52, %polly.loop_header32 ]
  %36 = phi <4 x float> [ %.promoted19, %polly.loop_header26 ], [ %51, %polly.loop_header32 ]
  %37 = phi <4 x float> [ %.promoted17, %polly.loop_header26 ], [ %48, %polly.loop_header32 ]
  %38 = phi <4 x float> [ %.promoted15, %polly.loop_header26 ], [ %47, %polly.loop_header32 ]
  %wide.load813 = phi <4 x float> [ %.promoted12, %polly.loop_header26 ], [ %44, %polly.loop_header32 ]
  %wide.load11 = phi <4 x float> [ %.promoted, %polly.loop_header26 ], [ %43, %polly.loop_header32 ]
  %polly.indvar35 = phi i64 [ %polly.indvar23, %polly.loop_header26 ], [ %polly.indvar_next36, %polly.loop_header32 ]
  %39 = shl nuw nsw i64 %polly.indvar35, 2
  %scevgep47 = getelementptr i8, ptr %scevgep46, i64 %39
  %_p_scalar_48 = load float, ptr %scevgep47, align 4, !alias.scope !23, !noalias !24
  %broadcast.splatinsert = insertelement <4 x float> poison, float %_p_scalar_48, i64 0
  %broadcast.splat = shufflevector <4 x float> %broadcast.splatinsert, <4 x float> poison, <4 x i32> zeroinitializer
  %40 = mul nuw nsw i64 %polly.indvar35, 6144
  %scevgep49 = getelementptr i8, ptr @B, i64 %40
  %41 = getelementptr i8, ptr %scevgep49, i64 %0
  %42 = getelementptr i8, ptr %41, i64 16
  %wide.load9 = load <4 x float>, ptr %41, align 16, !alias.scope !25, !noalias !26
  %wide.load10 = load <4 x float>, ptr %42, align 16, !alias.scope !25, !noalias !26
  %43 = tail call <4 x float> @llvm.fmuladd.v4f32(<4 x float> %broadcast.splat, <4 x float> %wide.load9, <4 x float> %wide.load11)
  %44 = tail call <4 x float> @llvm.fmuladd.v4f32(<4 x float> %broadcast.splat, <4 x float> %wide.load10, <4 x float> %wide.load813)
  %45 = getelementptr i8, ptr %scevgep49, i64 %1
  %46 = getelementptr i8, ptr %45, i64 16
  %wide.load9.1 = load <4 x float>, ptr %45, align 16, !alias.scope !25, !noalias !26
  %wide.load10.1 = load <4 x float>, ptr %46, align 16, !alias.scope !25, !noalias !26
  %47 = tail call <4 x float> @llvm.fmuladd.v4f32(<4 x float> %broadcast.splat, <4 x float> %wide.load9.1, <4 x float> %38)
  %48 = tail call <4 x float> @llvm.fmuladd.v4f32(<4 x float> %broadcast.splat, <4 x float> %wide.load10.1, <4 x float> %37)
  %49 = getelementptr i8, ptr %scevgep49, i64 %2
  %50 = getelementptr i8, ptr %49, i64 16
  %wide.load9.2 = load <4 x float>, ptr %49, align 16, !alias.scope !25, !noalias !26
  %wide.load10.2 = load <4 x float>, ptr %50, align 16, !alias.scope !25, !noalias !26
  %51 = tail call <4 x float> @llvm.fmuladd.v4f32(<4 x float> %broadcast.splat, <4 x float> %wide.load9.2, <4 x float> %36)
  %52 = tail call <4 x float> @llvm.fmuladd.v4f32(<4 x float> %broadcast.splat, <4 x float> %wide.load10.2, <4 x float> %35)
  %53 = getelementptr i8, ptr %scevgep49, i64 %3
  %54 = getelementptr i8, ptr %53, i64 16
  %wide.load9.3 = load <4 x float>, ptr %53, align 16, !alias.scope !25, !noalias !26
  %wide.load10.3 = load <4 x float>, ptr %54, align 16, !alias.scope !25, !noalias !26
  %55 = tail call <4 x float> @llvm.fmuladd.v4f32(<4 x float> %broadcast.splat, <4 x float> %wide.load9.3, <4 x float> %34)
  %56 = tail call <4 x float> @llvm.fmuladd.v4f32(<4 x float> %broadcast.splat, <4 x float> %wide.load10.3, <4 x float> %33)
  %57 = getelementptr i8, ptr %scevgep49, i64 %4
  %58 = getelementptr i8, ptr %57, i64 16
  %wide.load9.4 = load <4 x float>, ptr %57, align 16, !alias.scope !25, !noalias !26
  %wide.load10.4 = load <4 x float>, ptr %58, align 16, !alias.scope !25, !noalias !26
  %59 = tail call <4 x float> @llvm.fmuladd.v4f32(<4 x float> %broadcast.splat, <4 x float> %wide.load9.4, <4 x float> %32)
  %60 = tail call <4 x float> @llvm.fmuladd.v4f32(<4 x float> %broadcast.splat, <4 x float> %wide.load10.4, <4 x float> %31)
  %61 = getelementptr i8, ptr %scevgep49, i64 %5
  %62 = getelementptr i8, ptr %61, i64 16
  %wide.load9.5 = load <4 x float>, ptr %61, align 16, !alias.scope !25, !noalias !26
  %wide.load10.5 = load <4 x float>, ptr %62, align 16, !alias.scope !25, !noalias !26
  %63 = tail call <4 x float> @llvm.fmuladd.v4f32(<4 x float> %broadcast.splat, <4 x float> %wide.load9.5, <4 x float> %30)
  %64 = tail call <4 x float> @llvm.fmuladd.v4f32(<4 x float> %broadcast.splat, <4 x float> %wide.load10.5, <4 x float> %29)
  %65 = getelementptr i8, ptr %scevgep49, i64 %6
  %66 = getelementptr i8, ptr %65, i64 16
  %wide.load9.6 = load <4 x float>, ptr %65, align 16, !alias.scope !25, !noalias !26
  %wide.load10.6 = load <4 x float>, ptr %66, align 16, !alias.scope !25, !noalias !26
  %67 = tail call <4 x float> @llvm.fmuladd.v4f32(<4 x float> %broadcast.splat, <4 x float> %wide.load9.6, <4 x float> %28)
  %68 = tail call <4 x float> @llvm.fmuladd.v4f32(<4 x float> %broadcast.splat, <4 x float> %wide.load10.6, <4 x float> %27)
  %69 = getelementptr i8, ptr %scevgep49, i64 %7
  %70 = getelementptr i8, ptr %69, i64 16
  %wide.load9.7 = load <4 x float>, ptr %69, align 16, !alias.scope !25, !noalias !26
  %wide.load10.7 = load <4 x float>, ptr %70, align 16, !alias.scope !25, !noalias !26
  %71 = tail call <4 x float> @llvm.fmuladd.v4f32(<4 x float> %broadcast.splat, <4 x float> %wide.load9.7, <4 x float> %26)
  %72 = tail call <4 x float> @llvm.fmuladd.v4f32(<4 x float> %broadcast.splat, <4 x float> %wide.load10.7, <4 x float> %25)
  %polly.indvar_next36 = add nuw nsw i64 %polly.indvar35, 1
  %exitcond4.not = icmp eq i64 %polly.indvar_next36, %indvars.iv2
  br i1 %exitcond4.not, label %polly.loop_exit34, label %polly.loop_header32
}

; Function Attrs: nofree nounwind
declare noundef i32 @fputc(i32 noundef, ptr nocapture noundef) local_unnamed_addr #4

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #5

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare <4 x float> @llvm.fmuladd.v4f32(<4 x float>, <4 x float>, <4 x float>) #6

attributes #0 = { nofree noinline norecurse nosync nounwind ssp memory(write, argmem: none, inaccessiblemem: none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "polly-optimized" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { nofree noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nofree nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nofree noinline norecurse nosync nounwind ssp memory(readwrite, argmem: write, inaccessiblemem: none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "polly-optimized" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nofree nounwind }
attributes #5 = { nocallback nofree nounwind willreturn memory(argmem: write) }
attributes #6 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #7 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 15, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"clang version 20.1.0-rc3 (https://github.com/goog00/llvm-project.git a69568efe6c4972e71af295c6577b3412dd57c22)"}
!6 = !{!7}
!7 = distinct !{!7, !8, !"polly.alias.scope.MemRef_A"}
!8 = distinct !{!8, !"polly.alias.scope.domain"}
!9 = !{!10}
!10 = distinct !{!10, !8, !"polly.alias.scope.MemRef_B"}
!11 = distinct !{!11, !12, !13}
!12 = !{!"llvm.loop.isvectorized", i32 1}
!13 = !{!"llvm.loop.unroll.runtime.disable"}
!14 = distinct !{!14, !15}
!15 = !{!"llvm.loop.mustprogress"}
!16 = distinct !{!16, !15}
!17 = !{!18}
!18 = distinct !{!18, !19, !"polly.alias.scope.MemRef_C"}
!19 = distinct !{!19, !"polly.alias.scope.domain"}
!20 = !{!21, !22}
!21 = distinct !{!21, !19, !"polly.alias.scope.MemRef_A"}
!22 = distinct !{!22, !19, !"polly.alias.scope.MemRef_B"}
!23 = !{!21}
!24 = !{!18, !22}
!25 = !{!22}
!26 = !{!18, !21}
