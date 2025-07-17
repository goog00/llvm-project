; ModuleID = 'matmul.ll'
source_filename = "matmul.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx15.0.0"

@A = global [1536 x [1536 x float]] zeroinitializer, align 16
@B = global [1536 x [1536 x float]] zeroinitializer, align 16
@__stdoutp = external global ptr, align 8
@.str = private unnamed_addr constant [5 x i8] c"%lf \00", align 1
@C = global [1536 x [1536 x float]] zeroinitializer, align 16
@.str.1 = private unnamed_addr constant [2 x i8] c"\0A\00", align 1

; Function Attrs: noinline nounwind ssp uwtable
define void @init_array() #0 {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc17, %entry
  %i.0 = phi i32 [ 0, %entry ], [ %inc18, %for.inc17 ]
  %cmp = icmp samesign ult i32 %i.0, 1536
  br i1 %cmp, label %for.cond1, label %for.end19

for.cond1:                                        ; preds = %for.cond, %for.body3
  %j.0 = phi i32 [ %inc, %for.body3 ], [ 0, %for.cond ]
  %cmp2 = icmp samesign ult i32 %j.0, 1536
  br i1 %cmp2, label %for.body3, label %for.inc17

for.body3:                                        ; preds = %for.cond1
  %mul = mul nuw nsw i32 %j.0, %i.0
  %rem = and i32 %mul, 1023
  %add = add nuw nsw i32 %rem, 1
  %conv = uitofp nneg i32 %add to double
  %div = fmul double %conv, 5.000000e-01
  %conv4 = fptrunc double %div to float
  %idxprom = zext nneg i32 %i.0 to i64
  %idxprom5 = zext nneg i32 %j.0 to i64
  %arrayidx6 = getelementptr inbounds nuw [1536 x [1536 x float]], ptr @A, i64 0, i64 %idxprom, i64 %idxprom5
  store float %conv4, ptr %arrayidx6, align 4
  %arrayidx16 = getelementptr inbounds nuw [1536 x [1536 x float]], ptr @B, i64 0, i64 %idxprom, i64 %idxprom5
  store float %conv4, ptr %arrayidx16, align 4
  %inc = add nuw nsw i32 %j.0, 1
  br label %for.cond1, !llvm.loop !6

for.inc17:                                        ; preds = %for.cond1
  %inc18 = add nuw nsw i32 %i.0, 1
  br label %for.cond, !llvm.loop !8

for.end19:                                        ; preds = %for.cond
  ret void
}

; Function Attrs: noinline nounwind ssp uwtable
define void @print_array() #0 {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.end, %entry
  %i.0 = phi i32 [ 0, %entry ], [ %inc11, %for.end ]
  %cmp = icmp samesign ult i32 %i.0, 1536
  br i1 %cmp, label %for.cond1, label %for.end12

for.cond1:                                        ; preds = %for.cond, %for.inc
  %j.0 = phi i32 [ %inc, %for.inc ], [ 0, %for.cond ]
  %cmp2 = icmp samesign ult i32 %j.0, 1536
  br i1 %cmp2, label %for.body3, label %for.end

for.body3:                                        ; preds = %for.cond1
  %0 = load ptr, ptr @__stdoutp, align 8
  %idxprom = zext nneg i32 %i.0 to i64
  %idxprom4 = zext nneg i32 %j.0 to i64
  %arrayidx5 = getelementptr inbounds nuw [1536 x [1536 x float]], ptr @C, i64 0, i64 %idxprom, i64 %idxprom4
  %1 = load float, ptr %arrayidx5, align 4
  %conv = fpext float %1 to double
  %call = tail call i32 (ptr, ptr, ...) @fprintf(ptr noundef %0, ptr noundef nonnull @.str, double noundef %conv) #3
  %rem = urem i32 %j.0, 80
  %cmp6 = icmp eq i32 %rem, 79
  br i1 %cmp6, label %if.then, label %for.inc

if.then:                                          ; preds = %for.body3
  %2 = load ptr, ptr @__stdoutp, align 8
  %call8 = tail call i32 (ptr, ptr, ...) @fprintf(ptr noundef %2, ptr noundef nonnull @.str.1) #3
  br label %for.inc

for.inc:                                          ; preds = %for.body3, %if.then
  %inc = add nuw nsw i32 %j.0, 1
  br label %for.cond1, !llvm.loop !9

for.end:                                          ; preds = %for.cond1
  %3 = load ptr, ptr @__stdoutp, align 8
  %call9 = tail call i32 (ptr, ptr, ...) @fprintf(ptr noundef %3, ptr noundef nonnull @.str.1) #3
  %inc11 = add nuw nsw i32 %i.0, 1
  br label %for.cond, !llvm.loop !10

for.end12:                                        ; preds = %for.cond
  ret void
}

; Function Attrs: nounwind
declare i32 @fprintf(ptr noundef, ptr noundef, ...) #1

; Function Attrs: noinline nounwind ssp uwtable
define i32 @main() #0 {
entry:
  tail call void @init_array()
  br label %for.cond

for.cond:                                         ; preds = %for.inc28, %entry
  %i.0 = phi i32 [ 0, %entry ], [ %inc29, %for.inc28 ]
  %cmp = icmp samesign ult i32 %i.0, 1536
  br i1 %cmp, label %for.cond1, label %for.end30

for.cond1:                                        ; preds = %for.cond, %for.inc25
  %j.0 = phi i32 [ %inc26, %for.inc25 ], [ 0, %for.cond ]
  %cmp2 = icmp samesign ult i32 %j.0, 1536
  br i1 %cmp2, label %for.body3, label %for.inc28

for.body3:                                        ; preds = %for.cond1
  %idxprom = zext nneg i32 %i.0 to i64
  %idxprom4 = zext nneg i32 %j.0 to i64
  %arrayidx5 = getelementptr inbounds nuw [1536 x [1536 x float]], ptr @C, i64 0, i64 %idxprom, i64 %idxprom4
  store float 0.000000e+00, ptr %arrayidx5, align 4
  br label %for.cond6

for.cond6:                                        ; preds = %for.body8, %for.body3
  %k.0 = phi i32 [ 0, %for.body3 ], [ %inc, %for.body8 ]
  %cmp7 = icmp samesign ult i32 %k.0, 1536
  br i1 %cmp7, label %for.body8, label %for.inc25

for.body8:                                        ; preds = %for.cond6
  %0 = load float, ptr %arrayidx5, align 4
  %idxprom15 = zext nneg i32 %k.0 to i64
  %arrayidx16 = getelementptr inbounds nuw [1536 x [1536 x float]], ptr @A, i64 0, i64 %idxprom, i64 %idxprom15
  %1 = load float, ptr %arrayidx16, align 4
  %arrayidx20 = getelementptr inbounds nuw [1536 x [1536 x float]], ptr @B, i64 0, i64 %idxprom15, i64 %idxprom4
  %2 = load float, ptr %arrayidx20, align 4
  %3 = tail call float @llvm.fmuladd.f32(float %1, float %2, float %0)
  store float %3, ptr %arrayidx5, align 4
  %inc = add nuw nsw i32 %k.0, 1
  br label %for.cond6, !llvm.loop !11

for.inc25:                                        ; preds = %for.cond6
  %inc26 = add nuw nsw i32 %j.0, 1
  br label %for.cond1, !llvm.loop !12

for.inc28:                                        ; preds = %for.cond1
  %inc29 = add nuw nsw i32 %i.0, 1
  br label %for.cond, !llvm.loop !13

for.end30:                                        ; preds = %for.cond
  ret i32 0
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare float @llvm.fmuladd.f32(float, float, float) #2

attributes #0 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #3 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 15, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"clang version 20.1.0-rc3 (https://github.com/goog00/llvm-project.git a69568efe6c4972e71af295c6577b3412dd57c22)"}
!6 = distinct !{!6, !7}
!7 = !{!"llvm.loop.mustprogress"}
!8 = distinct !{!8, !7}
!9 = distinct !{!9, !7}
!10 = distinct !{!10, !7}
!11 = distinct !{!11, !7}
!12 = distinct !{!12, !7}
!13 = distinct !{!13, !7}
