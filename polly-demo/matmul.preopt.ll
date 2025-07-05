; ModuleID = 'matmul.ll'
source_filename = "matmul.c"
target datalayout = "e-m:o-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx10.20.0"

%struct.__sFILE = type { i8*, i32, i32, i16, i16, %struct.__sbuf, i32, i8*, i32 (i8*)*, i32 (i8*, i8*, i32)*, i64 (i8*, i64, i32)*, i32 (i8*, i8*, i32)*, %struct.__sbuf, %struct.__sFILEX*, i32, [3 x i8], [1 x i8], %struct.__sbuf, i32, i64 }
%struct.__sFILEX = type opaque
%struct.__sbuf = type { i8*, i32 }

@A = common global [1536 x [1536 x float]] zeroinitializer, align 16
@B = common global [1536 x [1536 x float]] zeroinitializer, align 16
@__stdoutp = external global %struct.__sFILE*, align 8
@.str = private unnamed_addr constant [5 x i8] c"%lf \00", align 1
@C = common global [1536 x [1536 x float]] zeroinitializer, align 16
@.str.1 = private unnamed_addr constant [2 x i8] c"\0A\00", align 1

; Function Attrs: noinline nounwind ssp uwtable
define void @init_array() #0 {
entry:
  br label %entry.split

entry.split:                                      ; preds = %entry
  br label %for.cond1.preheader

for.cond1.preheader:                              ; preds = %entry.split, %for.inc17
  %indvars.iv4 = phi i64 [ 0, %entry.split ], [ %indvars.iv.next5, %for.inc17 ]
  br label %for.body3

for.body3:                                        ; preds = %for.cond1.preheader, %for.body3
  %indvars.iv = phi i64 [ 0, %for.cond1.preheader ], [ %indvars.iv.next, %for.body3 ]
  %0 = mul nuw nsw i64 %indvars.iv, %indvars.iv4
  %1 = trunc i64 %0 to i32
  %rem = and i32 %1, 1023
  %add = add nuw nsw i32 %rem, 1
  %conv = sitofp i32 %add to double
  %div = fmul double %conv, 5.000000e-01
  %conv4 = fptrunc double %div to float
  %arrayidx6 = getelementptr inbounds [1536 x [1536 x float]], [1536 x [1536 x float]]* @A, i64 0, i64 %indvars.iv4, i64 %indvars.iv
  store float %conv4, float* %arrayidx6, align 4
  %arrayidx16 = getelementptr inbounds [1536 x [1536 x float]], [1536 x [1536 x float]]* @B, i64 0, i64 %indvars.iv4, i64 %indvars.iv
  store float %conv4, float* %arrayidx16, align 4
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  %exitcond = icmp ne i64 %indvars.iv.next, 1536
  br i1 %exitcond, label %for.body3, label %for.inc17

for.inc17:                                        ; preds = %for.body3
  %indvars.iv.next5 = add nuw nsw i64 %indvars.iv4, 1
  %exitcond6 = icmp ne i64 %indvars.iv.next5, 1536
  br i1 %exitcond6, label %for.cond1.preheader, label %for.end19

for.end19:                                        ; preds = %for.inc17
  ret void
}

; Function Attrs: noinline nounwind ssp uwtable
define void @print_array() #0 {
entry:
  br label %entry.split

entry.split:                                      ; preds = %entry
  br label %for.cond1.preheader

for.cond1.preheader:                              ; preds = %entry.split, %for.end
  %indvars.iv6 = phi i64 [ 0, %entry.split ], [ %indvars.iv.next7, %for.end ]
  %0 = load %struct.__sFILE*, %struct.__sFILE** @__stdoutp, align 8
  br label %for.body3

for.body3:                                        ; preds = %for.cond1.preheader, %for.inc
  %indvars.iv = phi i64 [ 0, %for.cond1.preheader ], [ %indvars.iv.next, %for.inc ]
  %1 = phi %struct.__sFILE* [ %0, %for.cond1.preheader ], [ %5, %for.inc ]
  %arrayidx5 = getelementptr inbounds [1536 x [1536 x float]], [1536 x [1536 x float]]* @C, i64 0, i64 %indvars.iv6, i64 %indvars.iv
  %2 = load float, float* %arrayidx5, align 4
  %conv = fpext float %2 to double
  %call = tail call i32 (%struct.__sFILE*, i8*, ...) @fprintf(%struct.__sFILE* %1, i8* getelementptr inbounds ([5 x i8], [5 x i8]* @.str, i64 0, i64 0), double %conv) #3
  %3 = trunc i64 %indvars.iv to i32
  %rem = urem i32 %3, 80
  %cmp6 = icmp eq i32 %rem, 79
  br i1 %cmp6, label %if.then, label %for.inc

if.then:                                          ; preds = %for.body3
  %4 = load %struct.__sFILE*, %struct.__sFILE** @__stdoutp, align 8
  %fputc3 = tail call i32 @fputc(i32 10, %struct.__sFILE* %4)
  br label %for.inc

for.inc:                                          ; preds = %for.body3, %if.then
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  %5 = load %struct.__sFILE*, %struct.__sFILE** @__stdoutp, align 8
  %exitcond = icmp ne i64 %indvars.iv.next, 1536
  br i1 %exitcond, label %for.body3, label %for.end

for.end:                                          ; preds = %for.inc
  %.lcssa = phi %struct.__sFILE* [ %5, %for.inc ]
  %fputc = tail call i32 @fputc(i32 10, %struct.__sFILE* %.lcssa)
  %indvars.iv.next7 = add nuw nsw i64 %indvars.iv6, 1
  %exitcond8 = icmp ne i64 %indvars.iv.next7, 1536
  br i1 %exitcond8, label %for.cond1.preheader, label %for.end12

for.end12:                                        ; preds = %for.end
  ret void
}

declare i32 @fprintf(%struct.__sFILE*, i8*, ...) #1

; Function Attrs: noinline nounwind ssp uwtable
define i32 @main() #0 {
entry:
  br label %entry.split

entry.split:                                      ; preds = %entry
  tail call void @init_array()
  br label %for.cond1.preheader

for.cond1.preheader:                              ; preds = %entry.split, %for.inc28
  %indvars.iv7 = phi i64 [ 0, %entry.split ], [ %indvars.iv.next8, %for.inc28 ]
  br label %for.body3

for.body3:                                        ; preds = %for.cond1.preheader, %for.inc25
  %indvars.iv4 = phi i64 [ 0, %for.cond1.preheader ], [ %indvars.iv.next5, %for.inc25 ]
  %arrayidx5 = getelementptr inbounds [1536 x [1536 x float]], [1536 x [1536 x float]]* @C, i64 0, i64 %indvars.iv7, i64 %indvars.iv4
  store float 0.000000e+00, float* %arrayidx5, align 4
  br label %for.body8

for.body8:                                        ; preds = %for.body3, %for.body8
  %indvars.iv = phi i64 [ 0, %for.body3 ], [ %indvars.iv.next, %for.body8 ]
  %0 = load float, float* %arrayidx5, align 4
  %arrayidx16 = getelementptr inbounds [1536 x [1536 x float]], [1536 x [1536 x float]]* @A, i64 0, i64 %indvars.iv7, i64 %indvars.iv
  %1 = load float, float* %arrayidx16, align 4
  %arrayidx20 = getelementptr inbounds [1536 x [1536 x float]], [1536 x [1536 x float]]* @B, i64 0, i64 %indvars.iv, i64 %indvars.iv4
  %2 = load float, float* %arrayidx20, align 4
  %mul = fmul float %1, %2
  %add = fadd float %0, %mul
  store float %add, float* %arrayidx5, align 4
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  %exitcond = icmp ne i64 %indvars.iv.next, 1536
  br i1 %exitcond, label %for.body8, label %for.inc25

for.inc25:                                        ; preds = %for.body8
  %indvars.iv.next5 = add nuw nsw i64 %indvars.iv4, 1
  %exitcond6 = icmp ne i64 %indvars.iv.next5, 1536
  br i1 %exitcond6, label %for.body3, label %for.inc28

for.inc28:                                        ; preds = %for.inc25
  %indvars.iv.next8 = add nuw nsw i64 %indvars.iv7, 1
  %exitcond9 = icmp ne i64 %indvars.iv.next8, 1536
  br i1 %exitcond9, label %for.cond1.preheader, label %for.end30

for.end30:                                        ; preds = %for.inc28
  ret i32 0
}

; Function Attrs: nofree nounwind
declare i64 @fwrite(i8* nocapture, i64, i64, %struct.__sFILE* nocapture) #2

; Function Attrs: nofree nounwind
declare i32 @fputc(i32, %struct.__sFILE* nocapture) #2

attributes #0 = { noinline nounwind ssp uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-frame-pointer-elim"="true" "no-frame-pointer-elim-non-leaf" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #1 = { "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "less-precise-fpmad"="false" "no-frame-pointer-elim"="true" "no-frame-pointer-elim-non-leaf" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #2 = { nofree nounwind }
attributes #3 = { nounwind }

!llvm.module.flags = !{!0, !1, !2}
!llvm.ident = !{!3}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 15, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 7, !"PIC Level", i32 2}
!3 = !{!"clang version 9.0.1 (https://github.com/goog00/llvm-project.git c1a0a213378a458fbea1a5c77b315c7dce08fd05)"}
