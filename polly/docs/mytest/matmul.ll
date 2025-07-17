; ModuleID = 'matmul.c'
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
  %i = alloca i32, align 4
  %j = alloca i32, align 4
  store i32 0, ptr %i, align 4
  br label %for.cond

for.cond:                                         ; preds = %for.inc17, %entry
  %0 = load i32, ptr %i, align 4
  %cmp = icmp slt i32 %0, 1536
  br i1 %cmp, label %for.body, label %for.end19

for.body:                                         ; preds = %for.cond
  store i32 0, ptr %j, align 4
  br label %for.cond1

for.cond1:                                        ; preds = %for.inc, %for.body
  %1 = load i32, ptr %j, align 4
  %cmp2 = icmp slt i32 %1, 1536
  br i1 %cmp2, label %for.body3, label %for.end

for.body3:                                        ; preds = %for.cond1
  %2 = load i32, ptr %i, align 4
  %3 = load i32, ptr %j, align 4
  %mul = mul nsw i32 %2, %3
  %rem = srem i32 %mul, 1024
  %add = add nsw i32 1, %rem
  %conv = sitofp i32 %add to double
  %div = fdiv double %conv, 2.000000e+00
  %conv4 = fptrunc double %div to float
  %4 = load i32, ptr %i, align 4
  %idxprom = sext i32 %4 to i64
  %arrayidx = getelementptr inbounds [1536 x [1536 x float]], ptr @A, i64 0, i64 %idxprom
  %5 = load i32, ptr %j, align 4
  %idxprom5 = sext i32 %5 to i64
  %arrayidx6 = getelementptr inbounds [1536 x float], ptr %arrayidx, i64 0, i64 %idxprom5
  store float %conv4, ptr %arrayidx6, align 4
  %6 = load i32, ptr %i, align 4
  %7 = load i32, ptr %j, align 4
  %mul7 = mul nsw i32 %6, %7
  %rem8 = srem i32 %mul7, 1024
  %add9 = add nsw i32 1, %rem8
  %conv10 = sitofp i32 %add9 to double
  %div11 = fdiv double %conv10, 2.000000e+00
  %conv12 = fptrunc double %div11 to float
  %8 = load i32, ptr %i, align 4
  %idxprom13 = sext i32 %8 to i64
  %arrayidx14 = getelementptr inbounds [1536 x [1536 x float]], ptr @B, i64 0, i64 %idxprom13
  %9 = load i32, ptr %j, align 4
  %idxprom15 = sext i32 %9 to i64
  %arrayidx16 = getelementptr inbounds [1536 x float], ptr %arrayidx14, i64 0, i64 %idxprom15
  store float %conv12, ptr %arrayidx16, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body3
  %10 = load i32, ptr %j, align 4
  %inc = add nsw i32 %10, 1
  store i32 %inc, ptr %j, align 4
  br label %for.cond1, !llvm.loop !6

for.end:                                          ; preds = %for.cond1
  br label %for.inc17

for.inc17:                                        ; preds = %for.end
  %11 = load i32, ptr %i, align 4
  %inc18 = add nsw i32 %11, 1
  store i32 %inc18, ptr %i, align 4
  br label %for.cond, !llvm.loop !8

for.end19:                                        ; preds = %for.cond
  ret void
}

; Function Attrs: noinline nounwind ssp uwtable
define void @print_array() #0 {
entry:
  %i = alloca i32, align 4
  %j = alloca i32, align 4
  store i32 0, ptr %i, align 4
  br label %for.cond

for.cond:                                         ; preds = %for.inc10, %entry
  %0 = load i32, ptr %i, align 4
  %cmp = icmp slt i32 %0, 1536
  br i1 %cmp, label %for.body, label %for.end12

for.body:                                         ; preds = %for.cond
  store i32 0, ptr %j, align 4
  br label %for.cond1

for.cond1:                                        ; preds = %for.inc, %for.body
  %1 = load i32, ptr %j, align 4
  %cmp2 = icmp slt i32 %1, 1536
  br i1 %cmp2, label %for.body3, label %for.end

for.body3:                                        ; preds = %for.cond1
  %2 = load ptr, ptr @__stdoutp, align 8
  %3 = load i32, ptr %i, align 4
  %idxprom = sext i32 %3 to i64
  %arrayidx = getelementptr inbounds [1536 x [1536 x float]], ptr @C, i64 0, i64 %idxprom
  %4 = load i32, ptr %j, align 4
  %idxprom4 = sext i32 %4 to i64
  %arrayidx5 = getelementptr inbounds [1536 x float], ptr %arrayidx, i64 0, i64 %idxprom4
  %5 = load float, ptr %arrayidx5, align 4
  %conv = fpext float %5 to double
  %call = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %2, ptr noundef @.str, double noundef %conv) #3
  %6 = load i32, ptr %j, align 4
  %rem = srem i32 %6, 80
  %cmp6 = icmp eq i32 %rem, 79
  br i1 %cmp6, label %if.then, label %if.end

if.then:                                          ; preds = %for.body3
  %7 = load ptr, ptr @__stdoutp, align 8
  %call8 = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %7, ptr noundef @.str.1) #3
  br label %if.end

if.end:                                           ; preds = %if.then, %for.body3
  br label %for.inc

for.inc:                                          ; preds = %if.end
  %8 = load i32, ptr %j, align 4
  %inc = add nsw i32 %8, 1
  store i32 %inc, ptr %j, align 4
  br label %for.cond1, !llvm.loop !9

for.end:                                          ; preds = %for.cond1
  %9 = load ptr, ptr @__stdoutp, align 8
  %call9 = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %9, ptr noundef @.str.1) #3
  br label %for.inc10

for.inc10:                                        ; preds = %for.end
  %10 = load i32, ptr %i, align 4
  %inc11 = add nsw i32 %10, 1
  store i32 %inc11, ptr %i, align 4
  br label %for.cond, !llvm.loop !10

for.end12:                                        ; preds = %for.cond
  ret void
}

; Function Attrs: nounwind
declare i32 @fprintf(ptr noundef, ptr noundef, ...) #1

; Function Attrs: noinline nounwind ssp uwtable
define i32 @main() #0 {
entry:
  %retval = alloca i32, align 4
  %i = alloca i32, align 4
  %j = alloca i32, align 4
  %k = alloca i32, align 4
  %t_start = alloca double, align 8
  %t_end = alloca double, align 8
  store i32 0, ptr %retval, align 4
  call void @init_array()
  store i32 0, ptr %i, align 4
  br label %for.cond

for.cond:                                         ; preds = %for.inc28, %entry
  %0 = load i32, ptr %i, align 4
  %cmp = icmp slt i32 %0, 1536
  br i1 %cmp, label %for.body, label %for.end30

for.body:                                         ; preds = %for.cond
  store i32 0, ptr %j, align 4
  br label %for.cond1

for.cond1:                                        ; preds = %for.inc25, %for.body
  %1 = load i32, ptr %j, align 4
  %cmp2 = icmp slt i32 %1, 1536
  br i1 %cmp2, label %for.body3, label %for.end27

for.body3:                                        ; preds = %for.cond1
  %2 = load i32, ptr %i, align 4
  %idxprom = sext i32 %2 to i64
  %arrayidx = getelementptr inbounds [1536 x [1536 x float]], ptr @C, i64 0, i64 %idxprom
  %3 = load i32, ptr %j, align 4
  %idxprom4 = sext i32 %3 to i64
  %arrayidx5 = getelementptr inbounds [1536 x float], ptr %arrayidx, i64 0, i64 %idxprom4
  store float 0.000000e+00, ptr %arrayidx5, align 4
  store i32 0, ptr %k, align 4
  br label %for.cond6

for.cond6:                                        ; preds = %for.inc, %for.body3
  %4 = load i32, ptr %k, align 4
  %cmp7 = icmp slt i32 %4, 1536
  br i1 %cmp7, label %for.body8, label %for.end

for.body8:                                        ; preds = %for.cond6
  %5 = load i32, ptr %i, align 4
  %idxprom9 = sext i32 %5 to i64
  %arrayidx10 = getelementptr inbounds [1536 x [1536 x float]], ptr @C, i64 0, i64 %idxprom9
  %6 = load i32, ptr %j, align 4
  %idxprom11 = sext i32 %6 to i64
  %arrayidx12 = getelementptr inbounds [1536 x float], ptr %arrayidx10, i64 0, i64 %idxprom11
  %7 = load float, ptr %arrayidx12, align 4
  %8 = load i32, ptr %i, align 4
  %idxprom13 = sext i32 %8 to i64
  %arrayidx14 = getelementptr inbounds [1536 x [1536 x float]], ptr @A, i64 0, i64 %idxprom13
  %9 = load i32, ptr %k, align 4
  %idxprom15 = sext i32 %9 to i64
  %arrayidx16 = getelementptr inbounds [1536 x float], ptr %arrayidx14, i64 0, i64 %idxprom15
  %10 = load float, ptr %arrayidx16, align 4
  %11 = load i32, ptr %k, align 4
  %idxprom17 = sext i32 %11 to i64
  %arrayidx18 = getelementptr inbounds [1536 x [1536 x float]], ptr @B, i64 0, i64 %idxprom17
  %12 = load i32, ptr %j, align 4
  %idxprom19 = sext i32 %12 to i64
  %arrayidx20 = getelementptr inbounds [1536 x float], ptr %arrayidx18, i64 0, i64 %idxprom19
  %13 = load float, ptr %arrayidx20, align 4
  %14 = call float @llvm.fmuladd.f32(float %10, float %13, float %7)
  %15 = load i32, ptr %i, align 4
  %idxprom21 = sext i32 %15 to i64
  %arrayidx22 = getelementptr inbounds [1536 x [1536 x float]], ptr @C, i64 0, i64 %idxprom21
  %16 = load i32, ptr %j, align 4
  %idxprom23 = sext i32 %16 to i64
  %arrayidx24 = getelementptr inbounds [1536 x float], ptr %arrayidx22, i64 0, i64 %idxprom23
  store float %14, ptr %arrayidx24, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body8
  %17 = load i32, ptr %k, align 4
  %inc = add nsw i32 %17, 1
  store i32 %inc, ptr %k, align 4
  br label %for.cond6, !llvm.loop !11

for.end:                                          ; preds = %for.cond6
  br label %for.inc25

for.inc25:                                        ; preds = %for.end
  %18 = load i32, ptr %j, align 4
  %inc26 = add nsw i32 %18, 1
  store i32 %inc26, ptr %j, align 4
  br label %for.cond1, !llvm.loop !12

for.end27:                                        ; preds = %for.cond1
  br label %for.inc28

for.inc28:                                        ; preds = %for.end27
  %19 = load i32, ptr %i, align 4
  %inc29 = add nsw i32 %19, 1
  store i32 %inc29, ptr %i, align 4
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
