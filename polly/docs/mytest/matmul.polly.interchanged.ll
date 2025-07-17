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
  %call = tail call i32 (ptr, ptr, ...) @fprintf(ptr noundef %0, ptr noundef nonnull @.str, double noundef %conv) #6
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
  br label %polly.loop_header

polly.exiting:                                    ; preds = %polly.loop_exit3
  ret i32 0

polly.loop_header:                                ; preds = %entry, %polly.loop_exit3
  %polly.indvar = phi i64 [ 0, %entry ], [ %polly.indvar_next, %polly.loop_exit3 ]
  %0 = mul nuw nsw i64 %polly.indvar, 6144
  %scevgep = getelementptr i8, ptr @C, i64 %0
  %scevgep16 = getelementptr i8, ptr @A, i64 %0
  br label %polly.loop_header1

polly.loop_exit3:                                 ; preds = %polly.loop_exit10
  %polly.indvar_next = add nuw nsw i64 %polly.indvar, 1
  %exitcond4.not = icmp eq i64 %polly.indvar_next, 1536
  br i1 %exitcond4.not, label %polly.exiting, label %polly.loop_header

polly.loop_header1:                               ; preds = %polly.loop_header, %polly.loop_exit10
  %polly.indvar4 = phi i64 [ 0, %polly.loop_header ], [ %polly.indvar_next5, %polly.loop_exit10 ]
  %1 = shl nuw nsw i64 %polly.indvar4, 2
  %scevgep7 = getelementptr i8, ptr %scevgep, i64 %1
  %scevgep19 = getelementptr i8, ptr @B, i64 %1
  br label %polly.loop_header8

polly.loop_exit10:                                ; preds = %polly.loop_header8
  store float %p_.2, ptr %scevgep7, align 4, !alias.scope !17, !noalias !20
  %polly.indvar_next5 = add nuw nsw i64 %polly.indvar4, 1
  %exitcond3.not = icmp eq i64 %polly.indvar_next5, 1536
  br i1 %exitcond3.not, label %polly.loop_exit3, label %polly.loop_header1

polly.loop_header8:                               ; preds = %polly.loop_header8, %polly.loop_header1
  %p_1 = phi float [ 0.000000e+00, %polly.loop_header1 ], [ %p_.2, %polly.loop_header8 ]
  %polly.indvar11 = phi i64 [ 0, %polly.loop_header1 ], [ %polly.indvar_next12.2, %polly.loop_header8 ]
  %2 = shl nuw nsw i64 %polly.indvar11, 2
  %scevgep17 = getelementptr i8, ptr %scevgep16, i64 %2
  %_p_scalar_18 = load float, ptr %scevgep17, align 4, !alias.scope !23, !noalias !24
  %3 = mul nuw nsw i64 %polly.indvar11, 6144
  %scevgep20 = getelementptr i8, ptr %scevgep19, i64 %3
  %_p_scalar_21 = load float, ptr %scevgep20, align 4, !alias.scope !25, !noalias !26
  %p_ = tail call float @llvm.fmuladd.f32(float %_p_scalar_18, float %_p_scalar_21, float %p_1)
  %polly.indvar_next12 = add nuw nsw i64 %polly.indvar11, 1
  %4 = shl nuw nsw i64 %polly.indvar_next12, 2
  %scevgep17.1 = getelementptr i8, ptr %scevgep16, i64 %4
  %_p_scalar_18.1 = load float, ptr %scevgep17.1, align 4, !alias.scope !23, !noalias !24
  %5 = mul nuw nsw i64 %polly.indvar_next12, 6144
  %scevgep20.1 = getelementptr i8, ptr %scevgep19, i64 %5
  %_p_scalar_21.1 = load float, ptr %scevgep20.1, align 4, !alias.scope !25, !noalias !26
  %p_.1 = tail call float @llvm.fmuladd.f32(float %_p_scalar_18.1, float %_p_scalar_21.1, float %p_)
  %polly.indvar_next12.1 = add nuw nsw i64 %polly.indvar11, 2
  %6 = shl nuw nsw i64 %polly.indvar_next12.1, 2
  %scevgep17.2 = getelementptr i8, ptr %scevgep16, i64 %6
  %_p_scalar_18.2 = load float, ptr %scevgep17.2, align 4, !alias.scope !23, !noalias !24
  %7 = mul nuw nsw i64 %polly.indvar_next12.1, 6144
  %scevgep20.2 = getelementptr i8, ptr %scevgep19, i64 %7
  %_p_scalar_21.2 = load float, ptr %scevgep20.2, align 4, !alias.scope !25, !noalias !26
  %p_.2 = tail call float @llvm.fmuladd.f32(float %_p_scalar_18.2, float %_p_scalar_21.2, float %p_.1)
  %polly.indvar_next12.2 = add nuw nsw i64 %polly.indvar11, 3
  %exitcond.not.2 = icmp eq i64 %polly.indvar_next12.2, 1536
  br i1 %exitcond.not.2, label %polly.loop_exit10, label %polly.loop_header8
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare float @llvm.fmuladd.f32(float, float, float) #4

; Function Attrs: nofree nounwind
declare noundef i32 @fputc(i32 noundef, ptr nocapture noundef) local_unnamed_addr #5

attributes #0 = { nofree noinline norecurse nosync nounwind ssp memory(write, argmem: none, inaccessiblemem: none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "polly-optimized" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { nofree noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nofree nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nofree noinline norecurse nosync nounwind ssp memory(readwrite, argmem: write, inaccessiblemem: none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "polly-optimized" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #5 = { nofree nounwind }
attributes #6 = { nounwind }

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
