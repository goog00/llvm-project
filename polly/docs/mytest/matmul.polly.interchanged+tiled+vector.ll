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
  store <4 x float> %7, ptr %9, align 16, !alias.scope !6, !noalias !9, !llvm.access.group !11
  %10 = getelementptr i8, ptr %scevgep8, i64 %8
  store <4 x float> %7, ptr %10, align 16, !alias.scope !9, !noalias !6, !llvm.access.group !11
  %index.next = add nuw i64 %index, 4
  %vec.ind.next = add <4 x i32> %vec.ind, splat (i32 4)
  %11 = icmp eq i64 %index.next, 1536
  br i1 %11, label %polly.loop_exit3, label %vector.body, !llvm.loop !14

polly.loop_exit3:                                 ; preds = %vector.body
  %polly.indvar_next = add nuw nsw i64 %polly.indvar, 1
  %exitcond1.not = icmp eq i64 %polly.indvar_next, 1536
  br i1 %exitcond1.not, label %polly.exiting, label %polly.loop_header, !llvm.loop !18
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
  br i1 %exitcond.not, label %for.end, label %for.body3, !llvm.loop !20

for.end:                                          ; preds = %for.inc
  %3 = load ptr, ptr @__stdoutp, align 8
  %fputc = tail call i32 @fputc(i32 10, ptr %3)
  %indvars.iv.next7 = add nuw nsw i64 %indvars.iv6, 1
  %exitcond9.not = icmp eq i64 %indvars.iv.next7, 1536
  br i1 %exitcond9.not, label %for.end12, label %for.cond1.preheader, !llvm.loop !22

for.end12:                                        ; preds = %for.end
  ret void
}

; Function Attrs: nofree nounwind
declare noundef i32 @fprintf(ptr nocapture noundef, ptr nocapture noundef readonly, ...) local_unnamed_addr #2

; Function Attrs: nofree noinline norecurse nosync nounwind ssp memory(readwrite, argmem: write, inaccessiblemem: none) uwtable
define noundef i32 @main() local_unnamed_addr #3 {
entry:
  tail call void @init_array()
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(9437184) @C, i8 0, i64 9437184, i1 false), !alias.scope !23, !noalias !26
  br label %polly.loop_header8

polly.exiting:                                    ; preds = %polly.loop_exit16
  ret i32 0

polly.loop_header8:                               ; preds = %entry, %polly.loop_exit16
  %indvars.iv6 = phi i64 [ 64, %entry ], [ %indvars.iv.next7, %polly.loop_exit16 ]
  %polly.indvar11 = phi i64 [ 0, %entry ], [ %polly.indvar_next12, %polly.loop_exit16 ]
  br label %polly.loop_header14

polly.loop_exit16:                                ; preds = %polly.loop_exit22
  %polly.indvar_next12 = add nuw nsw i64 %polly.indvar11, 64
  %polly.loop_cond13 = icmp samesign ult i64 %polly.indvar11, 1472
  %indvars.iv.next7 = add nuw nsw i64 %indvars.iv6, 64
  br i1 %polly.loop_cond13, label %polly.loop_header8, label %polly.exiting, !llvm.loop !29

polly.loop_header14:                              ; preds = %polly.loop_header8, %polly.loop_exit22
  %polly.indvar17 = phi i64 [ 0, %polly.loop_header8 ], [ %polly.indvar_next18, %polly.loop_exit22 ]
  %0 = shl i64 %polly.indvar17, 2
  %1 = shl i64 %polly.indvar17, 2
  %2 = or disjoint i64 %1, 64
  %3 = shl i64 %polly.indvar17, 2
  %4 = or disjoint i64 %3, 128
  %5 = shl i64 %polly.indvar17, 2
  %6 = or disjoint i64 %5, 192
  br label %polly.loop_header20

polly.loop_exit22:                                ; preds = %polly.loop_exit28
  %polly.indvar_next18 = add nuw nsw i64 %polly.indvar17, 64
  %polly.loop_cond19 = icmp samesign ult i64 %polly.indvar17, 1472
  br i1 %polly.loop_cond19, label %polly.loop_header14, label %polly.loop_exit16

polly.loop_header20:                              ; preds = %polly.loop_header14, %polly.loop_exit28
  %indvars.iv4 = phi i64 [ 64, %polly.loop_header14 ], [ %indvars.iv.next5, %polly.loop_exit28 ]
  %polly.indvar23 = phi i64 [ 0, %polly.loop_header14 ], [ %polly.indvar_next24, %polly.loop_exit28 ]
  br label %polly.loop_header26

polly.loop_exit28:                                ; preds = %polly.loop_exit34
  %polly.indvar_next24 = add nuw nsw i64 %polly.indvar23, 64
  %polly.loop_cond25 = icmp samesign ult i64 %polly.indvar23, 1472
  %indvars.iv.next5 = add nuw nsw i64 %indvars.iv4, 64
  br i1 %polly.loop_cond25, label %polly.loop_header20, label %polly.loop_exit22

polly.loop_header26:                              ; preds = %polly.loop_header20, %polly.loop_exit34
  %polly.indvar29 = phi i64 [ %polly.indvar11, %polly.loop_header20 ], [ %polly.indvar_next30, %polly.loop_exit34 ]
  %7 = mul nuw nsw i64 %polly.indvar29, 6144
  %scevgep50 = getelementptr i8, ptr @C, i64 %7
  %scevgep52 = getelementptr i8, ptr @A, i64 %7
  %8 = getelementptr i8, ptr %scevgep50, i64 %0
  %9 = getelementptr i8, ptr %scevgep50, i64 %2
  %10 = getelementptr i8, ptr %scevgep50, i64 %4
  %11 = getelementptr i8, ptr %scevgep50, i64 %6
  %.promoted = load <16 x float>, ptr %8, align 16, !alias.scope !23, !noalias !26
  %.promoted18 = load <16 x float>, ptr %9, align 16, !alias.scope !23, !noalias !26
  %.promoted20 = load <16 x float>, ptr %10, align 16, !alias.scope !23, !noalias !26
  %.promoted22 = load <16 x float>, ptr %11, align 16, !alias.scope !23, !noalias !26
  br label %polly.loop_header32

polly.loop_exit34:                                ; preds = %polly.loop_header32
  store <16 x float> %interleaved.vec, ptr %8, align 16, !alias.scope !23, !noalias !26
  store <16 x float> %interleaved.vec.1, ptr %9, align 16, !alias.scope !23, !noalias !26
  store <16 x float> %interleaved.vec.2, ptr %10, align 16, !alias.scope !23, !noalias !26
  store <16 x float> %interleaved.vec.3, ptr %11, align 16, !alias.scope !23, !noalias !26
  %polly.indvar_next30 = add nuw nsw i64 %polly.indvar29, 1
  %exitcond8.not = icmp eq i64 %polly.indvar_next30, %indvars.iv6
  br i1 %exitcond8.not, label %polly.loop_exit28, label %polly.loop_header26

polly.loop_header32:                              ; preds = %polly.loop_header26, %polly.loop_header32
  %interleaved.vec.323 = phi <16 x float> [ %.promoted22, %polly.loop_header26 ], [ %interleaved.vec.3, %polly.loop_header32 ]
  %interleaved.vec.221 = phi <16 x float> [ %.promoted20, %polly.loop_header26 ], [ %interleaved.vec.2, %polly.loop_header32 ]
  %interleaved.vec.119 = phi <16 x float> [ %.promoted18, %polly.loop_header26 ], [ %interleaved.vec.1, %polly.loop_header32 ]
  %interleaved.vec17 = phi <16 x float> [ %.promoted, %polly.loop_header26 ], [ %interleaved.vec, %polly.loop_header32 ]
  %polly.indvar35 = phi i64 [ %polly.indvar23, %polly.loop_header26 ], [ %polly.indvar_next36, %polly.loop_header32 ]
  %12 = shl nuw nsw i64 %polly.indvar35, 2
  %scevgep53 = getelementptr i8, ptr %scevgep52, i64 %12
  %_p_scalar_54 = load float, ptr %scevgep53, align 4, !alias.scope !32, !noalias !33, !llvm.access.group !34
  %broadcast.splatinsert = insertelement <4 x float> poison, float %_p_scalar_54, i64 0
  %13 = mul nuw nsw i64 %polly.indvar35, 6144
  %scevgep55 = getelementptr i8, ptr @B, i64 %13
  %14 = getelementptr i8, ptr %scevgep55, i64 %0
  %wide.vec12 = load <16 x float>, ptr %14, align 16, !alias.scope !36, !noalias !37
  %15 = shufflevector <4 x float> %broadcast.splatinsert, <4 x float> poison, <16 x i32> zeroinitializer
  %interleaved.vec = tail call <16 x float> @llvm.fmuladd.v16f32(<16 x float> %15, <16 x float> %wide.vec12, <16 x float> %interleaved.vec17)
  %16 = getelementptr i8, ptr %scevgep55, i64 %2
  %wide.vec12.1 = load <16 x float>, ptr %16, align 16, !alias.scope !36, !noalias !37
  %17 = shufflevector <4 x float> %broadcast.splatinsert, <4 x float> poison, <16 x i32> zeroinitializer
  %interleaved.vec.1 = tail call <16 x float> @llvm.fmuladd.v16f32(<16 x float> %17, <16 x float> %wide.vec12.1, <16 x float> %interleaved.vec.119)
  %18 = getelementptr i8, ptr %scevgep55, i64 %4
  %wide.vec12.2 = load <16 x float>, ptr %18, align 16, !alias.scope !36, !noalias !37
  %19 = shufflevector <4 x float> %broadcast.splatinsert, <4 x float> poison, <16 x i32> zeroinitializer
  %interleaved.vec.2 = tail call <16 x float> @llvm.fmuladd.v16f32(<16 x float> %19, <16 x float> %wide.vec12.2, <16 x float> %interleaved.vec.221)
  %20 = getelementptr i8, ptr %scevgep55, i64 %6
  %wide.vec12.3 = load <16 x float>, ptr %20, align 16, !alias.scope !36, !noalias !37
  %21 = shufflevector <4 x float> %broadcast.splatinsert, <4 x float> poison, <16 x i32> zeroinitializer
  %interleaved.vec.3 = tail call <16 x float> @llvm.fmuladd.v16f32(<16 x float> %21, <16 x float> %wide.vec12.3, <16 x float> %interleaved.vec.323)
  %polly.indvar_next36 = add nuw nsw i64 %polly.indvar35, 1
  %exitcond.not = icmp eq i64 %polly.indvar_next36, %indvars.iv4
  br i1 %exitcond.not, label %polly.loop_exit34, label %polly.loop_header32
}

; Function Attrs: nofree nounwind
declare noundef i32 @fputc(i32 noundef, ptr nocapture noundef) local_unnamed_addr #4

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #5

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare <16 x float> @llvm.fmuladd.v16f32(<16 x float>, <16 x float>, <16 x float>) #6

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
!11 = !{!12, !13}
!12 = distinct !{}
!13 = distinct !{}
!14 = distinct !{!14, !15, !16, !17}
!15 = !{!"llvm.loop.parallel_accesses", !13}
!16 = !{!"llvm.loop.isvectorized", i32 1}
!17 = !{!"llvm.loop.unroll.runtime.disable"}
!18 = distinct !{!18, !19}
!19 = !{!"llvm.loop.parallel_accesses", !12}
!20 = distinct !{!20, !21}
!21 = !{!"llvm.loop.mustprogress"}
!22 = distinct !{!22, !21}
!23 = !{!24}
!24 = distinct !{!24, !25, !"polly.alias.scope.MemRef_C"}
!25 = distinct !{!25, !"polly.alias.scope.domain"}
!26 = !{!27, !28}
!27 = distinct !{!27, !25, !"polly.alias.scope.MemRef_A"}
!28 = distinct !{!28, !25, !"polly.alias.scope.MemRef_B"}
!29 = distinct !{!29, !30}
!30 = !{!"llvm.loop.parallel_accesses", !31}
!31 = distinct !{}
!32 = !{!27}
!33 = !{!24, !28}
!34 = !{!31, !35}
!35 = distinct !{}
!36 = !{!28}
!37 = !{!24, !27}
