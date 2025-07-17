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
  br label %vector.ph

vector.ph:                                        ; preds = %for.inc17, %entry
  %indvars.iv5 = phi i64 [ 0, %entry ], [ %indvars.iv.next6, %for.inc17 ]
  %broadcast.splatinsert = insertelement <4 x i64> poison, i64 %indvars.iv5, i64 0
  %broadcast.splat = shufflevector <4 x i64> %broadcast.splatinsert, <4 x i64> poison, <4 x i32> zeroinitializer
  br label %vector.body

vector.body:                                      ; preds = %vector.body, %vector.ph
  %index = phi i64 [ 0, %vector.ph ], [ %index.next, %vector.body ]
  %vec.ind = phi <4 x i64> [ <i64 0, i64 1, i64 2, i64 3>, %vector.ph ], [ %vec.ind.next, %vector.body ]
  %0 = mul nuw nsw <4 x i64> %vec.ind, %broadcast.splat
  %1 = trunc <4 x i64> %0 to <4 x i32>
  %2 = and <4 x i32> %1, splat (i32 1023)
  %3 = add nuw nsw <4 x i32> %2, splat (i32 1)
  %4 = uitofp nneg <4 x i32> %3 to <4 x double>
  %5 = fmul <4 x double> %4, splat (double 5.000000e-01)
  %6 = fptrunc <4 x double> %5 to <4 x float>
  %7 = getelementptr inbounds nuw [1536 x [1536 x float]], ptr @A, i64 0, i64 %indvars.iv5, i64 %index
  store <4 x float> %6, ptr %7, align 16
  %8 = getelementptr inbounds nuw [1536 x [1536 x float]], ptr @B, i64 0, i64 %indvars.iv5, i64 %index
  store <4 x float> %6, ptr %8, align 16
  %index.next = add nuw i64 %index, 4
  %vec.ind.next = add <4 x i64> %vec.ind, splat (i64 4)
  %9 = icmp eq i64 %index.next, 1536
  br i1 %9, label %for.inc17, label %vector.body, !llvm.loop !6

for.inc17:                                        ; preds = %vector.body
  %indvars.iv.next6 = add nuw nsw i64 %indvars.iv5, 1
  %exitcond8.not = icmp eq i64 %indvars.iv.next6, 1536
  br i1 %exitcond8.not, label %for.end19, label %vector.ph, !llvm.loop !10

for.end19:                                        ; preds = %for.inc17
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
  br i1 %exitcond.not, label %for.end, label %for.body3, !llvm.loop !11

for.end:                                          ; preds = %for.inc
  %3 = load ptr, ptr @__stdoutp, align 8
  %fputc = tail call i32 @fputc(i32 10, ptr %3)
  %indvars.iv.next7 = add nuw nsw i64 %indvars.iv6, 1
  %exitcond9.not = icmp eq i64 %indvars.iv.next7, 1536
  br i1 %exitcond9.not, label %for.end12, label %for.cond1.preheader, !llvm.loop !12

for.end12:                                        ; preds = %for.end
  ret void
}

; Function Attrs: nofree nounwind
declare noundef i32 @fprintf(ptr nocapture noundef, ptr nocapture noundef readonly, ...) local_unnamed_addr #2

; Function Attrs: nofree noinline norecurse nosync nounwind ssp memory(readwrite, argmem: write, inaccessiblemem: none) uwtable
define noundef i32 @main() local_unnamed_addr #3 {
entry:
  tail call void @init_array()
  br label %for.cond1.preheader

for.cond1.preheader:                              ; preds = %entry, %for.inc28
  %indvars.iv9 = phi i64 [ 0, %entry ], [ %indvars.iv.next10, %for.inc28 ]
  br label %for.body3

for.body3:                                        ; preds = %for.cond1.preheader, %for.inc25
  %indvars.iv5 = phi i64 [ 0, %for.cond1.preheader ], [ %indvars.iv.next6, %for.inc25 ]
  %arrayidx5 = getelementptr inbounds nuw [1536 x [1536 x float]], ptr @C, i64 0, i64 %indvars.iv9, i64 %indvars.iv5
  br label %for.body8

for.body8:                                        ; preds = %for.body8, %for.body3
  %indvars.iv = phi i64 [ 0, %for.body3 ], [ %indvars.iv.next.2, %for.body8 ]
  %0 = phi float [ 0.000000e+00, %for.body3 ], [ %9, %for.body8 ]
  %arrayidx16 = getelementptr inbounds nuw [1536 x [1536 x float]], ptr @A, i64 0, i64 %indvars.iv9, i64 %indvars.iv
  %1 = load float, ptr %arrayidx16, align 4
  %arrayidx20 = getelementptr inbounds nuw [1536 x [1536 x float]], ptr @B, i64 0, i64 %indvars.iv, i64 %indvars.iv5
  %2 = load float, ptr %arrayidx20, align 4
  %3 = tail call float @llvm.fmuladd.f32(float %1, float %2, float %0)
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  %arrayidx16.1 = getelementptr inbounds nuw [1536 x [1536 x float]], ptr @A, i64 0, i64 %indvars.iv9, i64 %indvars.iv.next
  %4 = load float, ptr %arrayidx16.1, align 4
  %arrayidx20.1 = getelementptr inbounds nuw [1536 x [1536 x float]], ptr @B, i64 0, i64 %indvars.iv.next, i64 %indvars.iv5
  %5 = load float, ptr %arrayidx20.1, align 4
  %6 = tail call float @llvm.fmuladd.f32(float %4, float %5, float %3)
  %indvars.iv.next.1 = add nuw nsw i64 %indvars.iv, 2
  %arrayidx16.2 = getelementptr inbounds nuw [1536 x [1536 x float]], ptr @A, i64 0, i64 %indvars.iv9, i64 %indvars.iv.next.1
  %7 = load float, ptr %arrayidx16.2, align 4
  %arrayidx20.2 = getelementptr inbounds nuw [1536 x [1536 x float]], ptr @B, i64 0, i64 %indvars.iv.next.1, i64 %indvars.iv5
  %8 = load float, ptr %arrayidx20.2, align 4
  %9 = tail call float @llvm.fmuladd.f32(float %7, float %8, float %6)
  %indvars.iv.next.2 = add nuw nsw i64 %indvars.iv, 3
  %exitcond.not.2 = icmp eq i64 %indvars.iv.next.2, 1536
  br i1 %exitcond.not.2, label %for.inc25, label %for.body8, !llvm.loop !13

for.inc25:                                        ; preds = %for.body8
  store float %9, ptr %arrayidx5, align 4
  %indvars.iv.next6 = add nuw nsw i64 %indvars.iv5, 1
  %exitcond8.not = icmp eq i64 %indvars.iv.next6, 1536
  br i1 %exitcond8.not, label %for.inc28, label %for.body3, !llvm.loop !14

for.inc28:                                        ; preds = %for.inc25
  %indvars.iv.next10 = add nuw nsw i64 %indvars.iv9, 1
  %exitcond12.not = icmp eq i64 %indvars.iv.next10, 1536
  br i1 %exitcond12.not, label %for.end30, label %for.cond1.preheader, !llvm.loop !15

for.end30:                                        ; preds = %for.inc28
  ret i32 0
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare float @llvm.fmuladd.f32(float, float, float) #4

; Function Attrs: nofree nounwind
declare noundef i32 @fputc(i32 noundef, ptr nocapture noundef) local_unnamed_addr #5

attributes #0 = { nofree noinline norecurse nosync nounwind ssp memory(write, argmem: none, inaccessiblemem: none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { nofree noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nofree nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nofree noinline norecurse nosync nounwind ssp memory(readwrite, argmem: write, inaccessiblemem: none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
!6 = distinct !{!6, !7, !8, !9}
!7 = !{!"llvm.loop.mustprogress"}
!8 = !{!"llvm.loop.isvectorized", i32 1}
!9 = !{!"llvm.loop.unroll.runtime.disable"}
!10 = distinct !{!10, !7}
!11 = distinct !{!11, !7}
!12 = distinct !{!12, !7}
!13 = distinct !{!13, !7}
!14 = distinct !{!14, !7}
!15 = distinct !{!15, !7}
