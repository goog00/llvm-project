; ModuleID = '<stdin>'
source_filename = "matmul.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx15.0.0"

@A = local_unnamed_addr global [1536 x [1536 x float]] zeroinitializer, align 16
@B = local_unnamed_addr global [1536 x [1536 x float]] zeroinitializer, align 16
@__stdoutp = external local_unnamed_addr global ptr, align 8
@.str = private unnamed_addr constant [5 x i8] c"%lf \00", align 1
@C = local_unnamed_addr global [1536 x [1536 x float]] zeroinitializer, align 16

; Function Attrs: noinline nounwind ssp uwtable
define void @init_array() local_unnamed_addr #0 {
entry:
  %polly.par.userContext = alloca {}, align 8
  %polly.par.LBPtr.i = alloca i64, align 8
  %polly.par.UBPtr.i = alloca i64, align 8
  call void @GOMP_parallel_loop_runtime_start(ptr nonnull @init_array_polly_subfn, ptr nonnull %polly.par.userContext, i32 0, i64 0, i64 1536, i64 1) #8
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %polly.par.LBPtr.i)
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %polly.par.UBPtr.i)
  %0 = call i8 @GOMP_loop_runtime_next(ptr nonnull %polly.par.LBPtr.i, ptr nonnull %polly.par.UBPtr.i) #8
  %.not1.i = icmp eq i8 %0, 0
  br i1 %.not1.i, label %init_array_polly_subfn.exit, label %polly.par.loadIVBounds.i

polly.par.checkNext.loopexit.i:                   ; preds = %polly.loop_exit3.i
  %1 = call i8 @GOMP_loop_runtime_next(ptr nonnull %polly.par.LBPtr.i, ptr nonnull %polly.par.UBPtr.i) #8
  %.not.i = icmp eq i8 %1, 0
  br i1 %.not.i, label %init_array_polly_subfn.exit, label %polly.par.loadIVBounds.i

polly.par.loadIVBounds.i:                         ; preds = %entry, %polly.par.checkNext.loopexit.i
  %polly.par.LB.i = load i64, ptr %polly.par.LBPtr.i, align 8
  %polly.par.UB.i = load i64, ptr %polly.par.UBPtr.i, align 8
  %polly.par.UBAdjusted.i = add i64 %polly.par.UB.i, -1
  br label %polly.loop_header.i

polly.loop_header.i:                              ; preds = %polly.loop_exit3.i, %polly.par.loadIVBounds.i
  %polly.indvar.i = phi i64 [ %polly.par.LB.i, %polly.par.loadIVBounds.i ], [ %polly.indvar_next.i, %polly.loop_exit3.i ]
  %2 = mul i64 %polly.indvar.i, 6144
  %scevgep.i = getelementptr i8, ptr @A, i64 %2
  %scevgep8.i = getelementptr i8, ptr @B, i64 %2
  %3 = trunc i64 %polly.indvar.i to i32
  %broadcast.splatinsert = insertelement <4 x i32> poison, i32 %3, i64 0
  %broadcast.splat = shufflevector <4 x i32> %broadcast.splatinsert, <4 x i32> poison, <4 x i32> zeroinitializer
  br label %vector.body

vector.body:                                      ; preds = %vector.body, %polly.loop_header.i
  %index = phi i64 [ 0, %polly.loop_header.i ], [ %index.next, %vector.body ]
  %vec.ind = phi <4 x i32> [ <i32 0, i32 1, i32 2, i32 3>, %polly.loop_header.i ], [ %vec.ind.next, %vector.body ]
  %4 = mul <4 x i32> %vec.ind, %broadcast.splat
  %5 = and <4 x i32> %4, splat (i32 1023)
  %6 = add nuw nsw <4 x i32> %5, splat (i32 1)
  %7 = uitofp nneg <4 x i32> %6 to <4 x double>
  %8 = fmul <4 x double> %7, splat (double 5.000000e-01)
  %9 = fptrunc <4 x double> %8 to <4 x float>
  %10 = shl nuw nsw i64 %index, 2
  %11 = getelementptr i8, ptr %scevgep.i, i64 %10
  store <4 x float> %9, ptr %11, align 16, !alias.scope !6, !noalias !9, !llvm.access.group !11
  %12 = getelementptr i8, ptr %scevgep8.i, i64 %10
  store <4 x float> %9, ptr %12, align 16, !alias.scope !9, !noalias !6, !llvm.access.group !11
  %index.next = add nuw i64 %index, 4
  %vec.ind.next = add <4 x i32> %vec.ind, splat (i32 4)
  %13 = icmp eq i64 %index.next, 1536
  br i1 %13, label %polly.loop_exit3.i, label %vector.body, !llvm.loop !12

polly.loop_exit3.i:                               ; preds = %vector.body
  %polly.indvar_next.i = add nsw i64 %polly.indvar.i, 1
  %polly.loop_cond.not.not.i = icmp slt i64 %polly.indvar.i, %polly.par.UBAdjusted.i
  br i1 %polly.loop_cond.not.not.i, label %polly.loop_header.i, label %polly.par.checkNext.loopexit.i

init_array_polly_subfn.exit:                      ; preds = %polly.par.checkNext.loopexit.i, %entry
  call void @GOMP_loop_end_nowait() #8
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %polly.par.LBPtr.i)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %polly.par.UBPtr.i)
  call void @GOMP_parallel_end() #8
  ret void
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
  %call = tail call i32 (ptr, ptr, ...) @fprintf(ptr noundef %0, ptr noundef nonnull @.str, double noundef %conv) #8
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
  br i1 %exitcond.not, label %for.end, label %for.body3, !llvm.loop !16

for.end:                                          ; preds = %for.inc
  %3 = load ptr, ptr @__stdoutp, align 8
  %fputc = tail call i32 @fputc(i32 10, ptr %3)
  %indvars.iv.next7 = add nuw nsw i64 %indvars.iv6, 1
  %exitcond9.not = icmp eq i64 %indvars.iv.next7, 1536
  br i1 %exitcond9.not, label %for.end12, label %for.cond1.preheader, !llvm.loop !18

for.end12:                                        ; preds = %for.end
  ret void
}

; Function Attrs: nofree nounwind
declare noundef i32 @fprintf(ptr nocapture noundef, ptr nocapture noundef readonly, ...) local_unnamed_addr #2

; Function Attrs: noinline nounwind ssp uwtable
define noundef i32 @main() local_unnamed_addr #0 {
entry:
  %polly.par.userContext2 = alloca {}, align 8
  %polly.par.LBPtr.i = alloca i64, align 8
  %polly.par.UBPtr.i = alloca i64, align 8
  tail call void @init_array()
  call void @GOMP_parallel_loop_runtime_start(ptr nonnull @main_polly_subfn, ptr nonnull %polly.par.userContext2, i32 0, i64 0, i64 1536, i64 1) #8
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %polly.par.LBPtr.i)
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %polly.par.UBPtr.i)
  %0 = call i8 @GOMP_loop_runtime_next(ptr nonnull %polly.par.LBPtr.i, ptr nonnull %polly.par.UBPtr.i) #8
  %.not1.i = icmp eq i8 %0, 0
  br i1 %.not1.i, label %main_polly_subfn.exit, label %polly.par.loadIVBounds.i

polly.par.loadIVBounds.i:                         ; preds = %entry, %polly.par.loadIVBounds.i
  %polly.par.LB.i = load i64, ptr %polly.par.LBPtr.i, align 8
  %polly.par.UB.i = load i64, ptr %polly.par.UBPtr.i, align 8
  %polly.par.UBAdjusted.i = add i64 %polly.par.UB.i, -1
  %1 = mul i64 %polly.par.LB.i, 6144
  %scevgep.i = getelementptr i8, ptr @C, i64 %1
  %smax.i = call i64 @llvm.smax.i64(i64 %polly.par.LB.i, i64 %polly.par.UBAdjusted.i)
  %reass.sub = sub i64 %smax.i, %polly.par.LB.i
  %2 = mul i64 %reass.sub, 6144
  %3 = add i64 %2, 6144
  call void @llvm.memset.p0.i64(ptr align 16 %scevgep.i, i8 0, i64 %3, i1 false), !alias.scope !19, !noalias !22
  %4 = call i8 @GOMP_loop_runtime_next(ptr nonnull %polly.par.LBPtr.i, ptr nonnull %polly.par.UBPtr.i) #8
  %.not.i = icmp eq i8 %4, 0
  br i1 %.not.i, label %main_polly_subfn.exit, label %polly.par.loadIVBounds.i

main_polly_subfn.exit:                            ; preds = %polly.par.loadIVBounds.i, %entry
  call void @GOMP_loop_end_nowait() #8
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %polly.par.LBPtr.i)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %polly.par.UBPtr.i)
  call void @GOMP_parallel_end() #8
  call void @GOMP_parallel_loop_runtime_start(ptr nonnull @main_polly_subfn_1, ptr nonnull %polly.par.userContext2, i32 0, i64 0, i64 1536, i64 64) #8
  call void @main_polly_subfn_1(ptr nonnull poison) #8
  call void @GOMP_parallel_end() #8
  ret i32 0
}

define internal void @init_array_polly_subfn(ptr nocapture readnone %polly.par.userContext) #3 {
polly.par.setup:
  %polly.par.LBPtr = alloca i64, align 8
  %polly.par.UBPtr = alloca i64, align 8
  %0 = call i8 @GOMP_loop_runtime_next(ptr nonnull %polly.par.LBPtr, ptr nonnull %polly.par.UBPtr)
  %.not1 = icmp eq i8 %0, 0
  br i1 %.not1, label %polly.par.exit, label %polly.par.loadIVBounds

polly.par.exit:                                   ; preds = %polly.par.checkNext.loopexit, %polly.par.setup
  call void @GOMP_loop_end_nowait()
  ret void

polly.par.checkNext.loopexit:                     ; preds = %polly.loop_exit3
  %1 = call i8 @GOMP_loop_runtime_next(ptr nonnull %polly.par.LBPtr, ptr nonnull %polly.par.UBPtr)
  %.not = icmp eq i8 %1, 0
  br i1 %.not, label %polly.par.exit, label %polly.par.loadIVBounds

polly.par.loadIVBounds:                           ; preds = %polly.par.setup, %polly.par.checkNext.loopexit
  %polly.par.LB = load i64, ptr %polly.par.LBPtr, align 8
  %polly.par.UB = load i64, ptr %polly.par.UBPtr, align 8
  %polly.par.UBAdjusted = add i64 %polly.par.UB, -1
  br label %polly.loop_header

polly.loop_header:                                ; preds = %polly.par.loadIVBounds, %polly.loop_exit3
  %polly.indvar = phi i64 [ %polly.par.LB, %polly.par.loadIVBounds ], [ %polly.indvar_next, %polly.loop_exit3 ]
  %2 = mul i64 %polly.indvar, 6144
  %scevgep = getelementptr i8, ptr @A, i64 %2
  %scevgep8 = getelementptr i8, ptr @B, i64 %2
  %3 = trunc i64 %polly.indvar to i32
  %broadcast.splatinsert = insertelement <4 x i32> poison, i32 %3, i64 0
  %broadcast.splat = shufflevector <4 x i32> %broadcast.splatinsert, <4 x i32> poison, <4 x i32> zeroinitializer
  br label %vector.body

vector.body:                                      ; preds = %vector.body, %polly.loop_header
  %index = phi i64 [ 0, %polly.loop_header ], [ %index.next, %vector.body ]
  %vec.ind = phi <4 x i32> [ <i32 0, i32 1, i32 2, i32 3>, %polly.loop_header ], [ %vec.ind.next, %vector.body ]
  %4 = mul <4 x i32> %vec.ind, %broadcast.splat
  %5 = and <4 x i32> %4, splat (i32 1023)
  %6 = add nuw nsw <4 x i32> %5, splat (i32 1)
  %7 = uitofp nneg <4 x i32> %6 to <4 x double>
  %8 = fmul <4 x double> %7, splat (double 5.000000e-01)
  %9 = fptrunc <4 x double> %8 to <4 x float>
  %10 = shl nuw nsw i64 %index, 2
  %11 = getelementptr i8, ptr %scevgep, i64 %10
  store <4 x float> %9, ptr %11, align 16, !alias.scope !25, !noalias !28, !llvm.access.group !11
  %12 = getelementptr i8, ptr %scevgep8, i64 %10
  store <4 x float> %9, ptr %12, align 16, !alias.scope !28, !noalias !25, !llvm.access.group !11
  %index.next = add nuw i64 %index, 4
  %vec.ind.next = add <4 x i32> %vec.ind, splat (i32 4)
  %13 = icmp eq i64 %index.next, 1536
  br i1 %13, label %polly.loop_exit3, label %vector.body, !llvm.loop !30

polly.loop_exit3:                                 ; preds = %vector.body
  %polly.indvar_next = add nsw i64 %polly.indvar, 1
  %polly.loop_cond.not.not = icmp slt i64 %polly.indvar, %polly.par.UBAdjusted
  br i1 %polly.loop_cond.not.not, label %polly.loop_header, label %polly.par.checkNext.loopexit
}

declare i8 @GOMP_loop_runtime_next(ptr, ptr) local_unnamed_addr

declare void @GOMP_loop_end_nowait() local_unnamed_addr

declare void @GOMP_parallel_loop_runtime_start(ptr, ptr, i32, i64, i64, i64) local_unnamed_addr

declare void @GOMP_parallel_end() local_unnamed_addr

define internal void @main_polly_subfn(ptr nocapture readnone %polly.par.userContext) #3 {
polly.par.setup:
  %polly.par.LBPtr = alloca i64, align 8
  %polly.par.UBPtr = alloca i64, align 8
  %0 = call i8 @GOMP_loop_runtime_next(ptr nonnull %polly.par.LBPtr, ptr nonnull %polly.par.UBPtr)
  %.not1 = icmp eq i8 %0, 0
  br i1 %.not1, label %polly.par.exit, label %polly.par.loadIVBounds

polly.par.exit:                                   ; preds = %polly.par.loadIVBounds, %polly.par.setup
  call void @GOMP_loop_end_nowait()
  ret void

polly.par.loadIVBounds:                           ; preds = %polly.par.setup, %polly.par.loadIVBounds
  %polly.par.LB = load i64, ptr %polly.par.LBPtr, align 8
  %polly.par.UB = load i64, ptr %polly.par.UBPtr, align 8
  %polly.par.UBAdjusted = add i64 %polly.par.UB, -1
  %1 = mul i64 %polly.par.LB, 6144
  %scevgep = getelementptr i8, ptr @C, i64 %1
  %smax = call i64 @llvm.smax.i64(i64 %polly.par.LB, i64 %polly.par.UBAdjusted)
  %2 = add i64 %smax, 1
  %3 = sub i64 %2, %polly.par.LB
  %4 = mul nuw i64 %3, 6144
  call void @llvm.memset.p0.i64(ptr align 16 %scevgep, i8 0, i64 %4, i1 false), !alias.scope !31, !noalias !34
  %5 = call i8 @GOMP_loop_runtime_next(ptr nonnull %polly.par.LBPtr, ptr nonnull %polly.par.UBPtr)
  %.not = icmp eq i8 %5, 0
  br i1 %.not, label %polly.par.exit, label %polly.par.loadIVBounds
}

define internal void @main_polly_subfn_1(ptr nocapture readnone %polly.par.userContext) #3 {
polly.par.setup:
  %polly.par.LBPtr = alloca i64, align 8
  %polly.par.UBPtr = alloca i64, align 8
  %0 = call i8 @GOMP_loop_runtime_next(ptr nonnull %polly.par.LBPtr, ptr nonnull %polly.par.UBPtr)
  %.not1 = icmp eq i8 %0, 0
  br i1 %.not1, label %polly.par.exit, label %polly.par.loadIVBounds

polly.par.exit:                                   ; preds = %polly.par.checkNext.loopexit, %polly.par.setup
  call void @GOMP_loop_end_nowait()
  ret void

polly.par.checkNext.loopexit:                     ; preds = %polly.loop_exit3
  %1 = call i8 @GOMP_loop_runtime_next(ptr nonnull %polly.par.LBPtr, ptr nonnull %polly.par.UBPtr)
  %.not = icmp eq i8 %1, 0
  br i1 %.not, label %polly.par.exit, label %polly.par.loadIVBounds

polly.par.loadIVBounds:                           ; preds = %polly.par.setup, %polly.par.checkNext.loopexit
  %polly.par.LB = load i64, ptr %polly.par.LBPtr, align 8
  %polly.par.UB = load i64, ptr %polly.par.UBPtr, align 8
  %polly.par.UBAdjusted = add i64 %polly.par.UB, -1
  br label %polly.loop_header

polly.loop_header:                                ; preds = %polly.par.loadIVBounds, %polly.loop_exit3
  %polly.indvar = phi i64 [ %polly.par.LB, %polly.par.loadIVBounds ], [ %polly.indvar_next, %polly.loop_exit3 ]
  %2 = add nsw i64 %polly.indvar, 63
  br label %polly.loop_header1

polly.loop_exit3:                                 ; preds = %polly.loop_exit9
  %polly.indvar_next = add nsw i64 %polly.indvar, 64
  %polly.loop_cond.not = icmp sgt i64 %polly.indvar_next, %polly.par.UBAdjusted
  br i1 %polly.loop_cond.not, label %polly.par.checkNext.loopexit, label %polly.loop_header

polly.loop_header1:                               ; preds = %polly.loop_header, %polly.loop_exit9
  %polly.indvar4 = phi i64 [ 0, %polly.loop_header ], [ %polly.indvar_next5, %polly.loop_exit9 ]
  %3 = shl i64 %polly.indvar4, 2
  %4 = shl i64 %polly.indvar4, 2
  %5 = or disjoint i64 %4, 64
  %6 = shl i64 %polly.indvar4, 2
  %7 = or disjoint i64 %6, 128
  %8 = shl i64 %polly.indvar4, 2
  %9 = or disjoint i64 %8, 192
  br label %polly.loop_header7

polly.loop_exit9:                                 ; preds = %polly.loop_exit15
  %polly.indvar_next5 = add nuw nsw i64 %polly.indvar4, 64
  %polly.loop_cond6 = icmp samesign ult i64 %polly.indvar4, 1472
  br i1 %polly.loop_cond6, label %polly.loop_header1, label %polly.loop_exit3

polly.loop_header7:                               ; preds = %polly.loop_header1, %polly.loop_exit15
  %indvars.iv4 = phi i64 [ 64, %polly.loop_header1 ], [ %indvars.iv.next5, %polly.loop_exit15 ]
  %polly.indvar10 = phi i64 [ 0, %polly.loop_header1 ], [ %polly.indvar_next11, %polly.loop_exit15 ]
  br label %polly.loop_header13

polly.loop_exit15:                                ; preds = %polly.loop_exit21
  %polly.indvar_next11 = add nuw nsw i64 %polly.indvar10, 64
  %polly.loop_cond12 = icmp samesign ult i64 %polly.indvar10, 1472
  %indvars.iv.next5 = add nuw nsw i64 %indvars.iv4, 64
  br i1 %polly.loop_cond12, label %polly.loop_header7, label %polly.loop_exit9

polly.loop_header13:                              ; preds = %polly.loop_header7, %polly.loop_exit21
  %polly.indvar16 = phi i64 [ %polly.indvar_next17, %polly.loop_exit21 ], [ %polly.indvar, %polly.loop_header7 ]
  %10 = mul i64 %polly.indvar16, 6144
  %scevgep = getelementptr i8, ptr @C, i64 %10
  %scevgep38 = getelementptr i8, ptr @A, i64 %10
  %11 = getelementptr i8, ptr %scevgep, i64 %3
  %12 = getelementptr i8, ptr %scevgep, i64 %5
  %13 = getelementptr i8, ptr %scevgep, i64 %7
  %14 = getelementptr i8, ptr %scevgep, i64 %9
  %.promoted = load <16 x float>, ptr %11, align 16, !alias.scope !31, !noalias !34
  %.promoted15 = load <16 x float>, ptr %12, align 16, !alias.scope !31, !noalias !34
  %.promoted17 = load <16 x float>, ptr %13, align 16, !alias.scope !31, !noalias !34
  %.promoted19 = load <16 x float>, ptr %14, align 16, !alias.scope !31, !noalias !34
  br label %polly.loop_header19

polly.loop_exit21:                                ; preds = %polly.loop_header19
  store <16 x float> %interleaved.vec, ptr %11, align 16, !alias.scope !31, !noalias !34
  store <16 x float> %interleaved.vec.1, ptr %12, align 16, !alias.scope !31, !noalias !34
  store <16 x float> %interleaved.vec.2, ptr %13, align 16, !alias.scope !31, !noalias !34
  store <16 x float> %interleaved.vec.3, ptr %14, align 16, !alias.scope !31, !noalias !34
  %polly.indvar_next17 = add nsw i64 %polly.indvar16, 1
  %polly.loop_cond18.not.not = icmp slt i64 %polly.indvar16, %2
  br i1 %polly.loop_cond18.not.not, label %polly.loop_header13, label %polly.loop_exit15

polly.loop_header19:                              ; preds = %polly.loop_header13, %polly.loop_header19
  %interleaved.vec.320 = phi <16 x float> [ %.promoted19, %polly.loop_header13 ], [ %interleaved.vec.3, %polly.loop_header19 ]
  %interleaved.vec.218 = phi <16 x float> [ %.promoted17, %polly.loop_header13 ], [ %interleaved.vec.2, %polly.loop_header19 ]
  %interleaved.vec.116 = phi <16 x float> [ %.promoted15, %polly.loop_header13 ], [ %interleaved.vec.1, %polly.loop_header19 ]
  %interleaved.vec14 = phi <16 x float> [ %.promoted, %polly.loop_header13 ], [ %interleaved.vec, %polly.loop_header19 ]
  %polly.indvar22 = phi i64 [ %polly.indvar10, %polly.loop_header13 ], [ %polly.indvar_next23, %polly.loop_header19 ]
  %15 = shl nuw nsw i64 %polly.indvar22, 2
  %scevgep39 = getelementptr i8, ptr %scevgep38, i64 %15
  %_p_scalar_40 = load float, ptr %scevgep39, align 4, !alias.scope !37, !noalias !38, !llvm.access.group !39
  %broadcast.splatinsert = insertelement <4 x float> poison, float %_p_scalar_40, i64 0
  %16 = mul nuw nsw i64 %polly.indvar22, 6144
  %scevgep41 = getelementptr i8, ptr @B, i64 %16
  %17 = getelementptr i8, ptr %scevgep41, i64 %3
  %wide.vec9 = load <16 x float>, ptr %17, align 16, !alias.scope !40, !noalias !41
  %18 = shufflevector <4 x float> %broadcast.splatinsert, <4 x float> poison, <16 x i32> zeroinitializer
  %interleaved.vec = call <16 x float> @llvm.fmuladd.v16f32(<16 x float> %18, <16 x float> %wide.vec9, <16 x float> %interleaved.vec14)
  %19 = getelementptr i8, ptr %scevgep41, i64 %5
  %wide.vec9.1 = load <16 x float>, ptr %19, align 16, !alias.scope !40, !noalias !41
  %20 = shufflevector <4 x float> %broadcast.splatinsert, <4 x float> poison, <16 x i32> zeroinitializer
  %interleaved.vec.1 = call <16 x float> @llvm.fmuladd.v16f32(<16 x float> %20, <16 x float> %wide.vec9.1, <16 x float> %interleaved.vec.116)
  %21 = getelementptr i8, ptr %scevgep41, i64 %7
  %wide.vec9.2 = load <16 x float>, ptr %21, align 16, !alias.scope !40, !noalias !41
  %22 = shufflevector <4 x float> %broadcast.splatinsert, <4 x float> poison, <16 x i32> zeroinitializer
  %interleaved.vec.2 = call <16 x float> @llvm.fmuladd.v16f32(<16 x float> %22, <16 x float> %wide.vec9.2, <16 x float> %interleaved.vec.218)
  %23 = getelementptr i8, ptr %scevgep41, i64 %9
  %wide.vec9.3 = load <16 x float>, ptr %23, align 16, !alias.scope !40, !noalias !41
  %24 = shufflevector <4 x float> %broadcast.splatinsert, <4 x float> poison, <16 x i32> zeroinitializer
  %interleaved.vec.3 = call <16 x float> @llvm.fmuladd.v16f32(<16 x float> %24, <16 x float> %wide.vec9.3, <16 x float> %interleaved.vec.320)
  %polly.indvar_next23 = add nuw nsw i64 %polly.indvar22, 1
  %exitcond.not = icmp eq i64 %polly.indvar_next23, %indvars.iv4
  br i1 %exitcond.not, label %polly.loop_exit21, label %polly.loop_header19
}

; Function Attrs: nofree nounwind
declare noundef i32 @fputc(i32 noundef, ptr nocapture noundef) local_unnamed_addr #4

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #5

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #5

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #6

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i64 @llvm.smax.i64(i64, i64) #7

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare <16 x float> @llvm.fmuladd.v16f32(<16 x float>, <16 x float>, <16 x float>) #7

attributes #0 = { noinline nounwind ssp uwtable "frame-pointer"="all" "no-trapping-math"="true" "polly-optimized" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { nofree noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nofree nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { "polly.skip.fn" }
attributes #4 = { nofree nounwind }
attributes #5 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #6 = { nocallback nofree nounwind willreturn memory(argmem: write) }
attributes #7 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #8 = { nounwind }

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
!11 = distinct !{}
!12 = distinct !{!12, !13, !14, !15}
!13 = !{!"llvm.loop.parallel_accesses", !11}
!14 = !{!"llvm.loop.isvectorized", i32 1}
!15 = !{!"llvm.loop.unroll.runtime.disable"}
!16 = distinct !{!16, !17}
!17 = !{!"llvm.loop.mustprogress"}
!18 = distinct !{!18, !17}
!19 = !{!20}
!20 = distinct !{!20, !21, !"polly.alias.scope.MemRef_C"}
!21 = distinct !{!21, !"polly.alias.scope.domain"}
!22 = !{!23, !24}
!23 = distinct !{!23, !21, !"polly.alias.scope.MemRef_A"}
!24 = distinct !{!24, !21, !"polly.alias.scope.MemRef_B"}
!25 = !{!26}
!26 = distinct !{!26, !27, !"polly.alias.scope.MemRef_A"}
!27 = distinct !{!27, !"polly.alias.scope.domain"}
!28 = !{!29}
!29 = distinct !{!29, !27, !"polly.alias.scope.MemRef_B"}
!30 = distinct !{!30, !13, !14, !15}
!31 = !{!32}
!32 = distinct !{!32, !33, !"polly.alias.scope.MemRef_C"}
!33 = distinct !{!33, !"polly.alias.scope.domain"}
!34 = !{!35, !36}
!35 = distinct !{!35, !33, !"polly.alias.scope.MemRef_A"}
!36 = distinct !{!36, !33, !"polly.alias.scope.MemRef_B"}
!37 = !{!35}
!38 = !{!32, !36}
!39 = distinct !{}
!40 = !{!36}
!41 = !{!32, !35}
