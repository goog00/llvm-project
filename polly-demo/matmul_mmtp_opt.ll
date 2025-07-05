; ModuleID = 'matmul_mmtp.ll'
source_filename = "matmul.c"
target datalayout = "e-m:o-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx10.20.0"

%struct.__sFILE = type { i8*, i32, i32, i16, i16, %struct.__sbuf, i32, i8*, i32 (i8*)*, i32 (i8*, i8*, i32)*, i64 (i8*, i64, i32)*, i32 (i8*, i8*, i32)*, %struct.__sbuf, %struct.__sFILEX*, i32, [3 x i8], [1 x i8], %struct.__sbuf, i32, i64 }
%struct.__sFILEX = type opaque
%struct.__sbuf = type { i8*, i32 }

@A = common local_unnamed_addr global [1536 x [1536 x float]] zeroinitializer, align 16
@B = common local_unnamed_addr global [1536 x [1536 x float]] zeroinitializer, align 16
@__stdoutp = external local_unnamed_addr global %struct.__sFILE*, align 8
@.str = private unnamed_addr constant [5 x i8] c"%lf \00", align 1
@C = common local_unnamed_addr global [1536 x [1536 x float]] zeroinitializer, align 16

; Function Attrs: nofree norecurse nounwind ssp uwtable writeonly
define void @init_array() local_unnamed_addr #0 {
entry:
  br label %for.cond1.preheader

for.cond1.preheader:                              ; preds = %for.inc17, %entry
  %indvars.iv34 = phi i64 [ 0, %entry ], [ %indvars.iv.next35, %for.inc17 ]
  br label %for.body3

for.body3:                                        ; preds = %for.body3, %for.cond1.preheader
  %indvars.iv = phi i64 [ 0, %for.cond1.preheader ], [ %indvars.iv.next, %for.body3 ]
  %0 = mul nuw nsw i64 %indvars.iv, %indvars.iv34
  %1 = trunc i64 %0 to i32
  %rem = and i32 %1, 1023
  %add = add nuw nsw i32 %rem, 1
  %conv = sitofp i32 %add to double
  %div = fmul double %conv, 5.000000e-01
  %conv4 = fptrunc double %div to float
  %arrayidx6 = getelementptr inbounds [1536 x [1536 x float]], [1536 x [1536 x float]]* @A, i64 0, i64 %indvars.iv34, i64 %indvars.iv
  store float %conv4, float* %arrayidx6, align 4, !tbaa !4
  %arrayidx16 = getelementptr inbounds [1536 x [1536 x float]], [1536 x [1536 x float]]* @B, i64 0, i64 %indvars.iv34, i64 %indvars.iv
  store float %conv4, float* %arrayidx16, align 4, !tbaa !4
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  %exitcond = icmp eq i64 %indvars.iv.next, 1536
  br i1 %exitcond, label %for.inc17, label %for.body3

for.inc17:                                        ; preds = %for.body3
  %indvars.iv.next35 = add nuw nsw i64 %indvars.iv34, 1
  %exitcond36 = icmp eq i64 %indvars.iv.next35, 1536
  br i1 %exitcond36, label %for.end19, label %for.cond1.preheader

for.end19:                                        ; preds = %for.inc17
  ret void
}

; Function Attrs: nofree nounwind ssp uwtable
define void @print_array() local_unnamed_addr #1 {
entry:
  br label %for.cond1.preheader

for.cond1.preheader:                              ; preds = %for.end, %entry
  %indvars.iv26 = phi i64 [ 0, %entry ], [ %indvars.iv.next27, %for.end ]
  %0 = load %struct.__sFILE*, %struct.__sFILE** @__stdoutp, align 8, !tbaa !8
  br label %for.body3

for.body3:                                        ; preds = %for.inc, %for.cond1.preheader
  %indvars.iv = phi i64 [ 0, %for.cond1.preheader ], [ %indvars.iv.next, %for.inc ]
  %1 = phi %struct.__sFILE* [ %0, %for.cond1.preheader ], [ %4, %for.inc ]
  %j.024 = phi i32 [ 0, %for.cond1.preheader ], [ %inc, %for.inc ]
  %arrayidx5 = getelementptr inbounds [1536 x [1536 x float]], [1536 x [1536 x float]]* @C, i64 0, i64 %indvars.iv26, i64 %indvars.iv
  %2 = load float, float* %arrayidx5, align 4, !tbaa !4
  %conv = fpext float %2 to double
  %call = tail call i32 (%struct.__sFILE*, i8*, ...) @fprintf(%struct.__sFILE* %1, i8* getelementptr inbounds ([5 x i8], [5 x i8]* @.str, i64 0, i64 0), double %conv)
  %rem.lhs.trunc = trunc i32 %j.024 to i16
  %rem23 = urem i16 %rem.lhs.trunc, 80
  %cmp6 = icmp eq i16 %rem23, 79
  br i1 %cmp6, label %if.then, label %for.inc

if.then:                                          ; preds = %for.body3
  %3 = load %struct.__sFILE*, %struct.__sFILE** @__stdoutp, align 8, !tbaa !8
  %fputc22 = tail call i32 @fputc(i32 10, %struct.__sFILE* %3)
  br label %for.inc

for.inc:                                          ; preds = %if.then, %for.body3
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  %inc = add nuw nsw i32 %j.024, 1
  %4 = load %struct.__sFILE*, %struct.__sFILE** @__stdoutp, align 8, !tbaa !8
  %exitcond = icmp eq i64 %indvars.iv.next, 1536
  br i1 %exitcond, label %for.end, label %for.body3

for.end:                                          ; preds = %for.inc
  %fputc = tail call i32 @fputc(i32 10, %struct.__sFILE* %4)
  %indvars.iv.next27 = add nuw nsw i64 %indvars.iv26, 1
  %exitcond28 = icmp eq i64 %indvars.iv.next27, 1536
  br i1 %exitcond28, label %for.end12, label %for.cond1.preheader

for.end12:                                        ; preds = %for.end
  ret void
}

; Function Attrs: nofree nounwind
declare i32 @fprintf(%struct.__sFILE* nocapture, i8* nocapture readonly, ...) local_unnamed_addr #2

; Function Attrs: nofree nounwind ssp uwtable
define i32 @main() local_unnamed_addr #1 {
entry:
  tail call void @init_array()
  br label %for.cond1.preheader

for.cond1.preheader:                              ; preds = %for.inc28, %entry
  %indvar = phi i64 [ 0, %entry ], [ %indvar.next, %for.inc28 ]
  br label %for.body3

for.body3:                                        ; preds = %for.inc25, %for.cond1.preheader
  %indvars.iv51 = phi i64 [ 0, %for.cond1.preheader ], [ %indvars.iv.next52, %for.inc25 ]
  %arrayidx5 = getelementptr inbounds [1536 x [1536 x float]], [1536 x [1536 x float]]* @C, i64 0, i64 %indvar, i64 %indvars.iv51
  store float 0.000000e+00, float* %arrayidx5, align 4, !tbaa !4
  br label %for.body8

for.body8:                                        ; preds = %for.body8, %for.body3
  %indvars.iv = phi i64 [ 0, %for.body3 ], [ %indvars.iv.next, %for.body8 ]
  %0 = phi float [ 0.000000e+00, %for.body3 ], [ %add, %for.body8 ]
  %arrayidx16 = getelementptr inbounds [1536 x [1536 x float]], [1536 x [1536 x float]]* @A, i64 0, i64 %indvar, i64 %indvars.iv
  %1 = load float, float* %arrayidx16, align 4, !tbaa !4
  %arrayidx20 = getelementptr inbounds [1536 x [1536 x float]], [1536 x [1536 x float]]* @B, i64 0, i64 %indvars.iv, i64 %indvars.iv51
  %2 = load float, float* %arrayidx20, align 4, !tbaa !4
  %mul = fmul float %1, %2
  %add = fadd float %0, %mul
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  %exitcond = icmp eq i64 %indvars.iv.next, 1536
  br i1 %exitcond, label %for.inc25, label %for.body8

for.inc25:                                        ; preds = %for.body8
  store float %add, float* %arrayidx5, align 4, !tbaa !4
  %indvars.iv.next52 = add nuw nsw i64 %indvars.iv51, 1
  %exitcond53 = icmp eq i64 %indvars.iv.next52, 1536
  br i1 %exitcond53, label %for.inc28, label %for.body3

for.inc28:                                        ; preds = %for.inc25
  %indvar.next = add nuw nsw i64 %indvar, 1
  %exitcond55 = icmp eq i64 %indvar.next, 1536
  br i1 %exitcond55, label %for.end30, label %for.cond1.preheader

for.end30:                                        ; preds = %for.inc28
  tail call void @print_array()
  ret i32 0
}

; Function Attrs: nofree nounwind
declare i32 @fputc(i32, %struct.__sFILE* nocapture) local_unnamed_addr #3

attributes #0 = { nofree norecurse nounwind ssp uwtable writeonly "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-frame-pointer-elim"="true" "no-frame-pointer-elim-non-leaf" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #1 = { nofree nounwind ssp uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-frame-pointer-elim"="true" "no-frame-pointer-elim-non-leaf" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #2 = { nofree nounwind "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "less-precise-fpmad"="false" "no-frame-pointer-elim"="true" "no-frame-pointer-elim-non-leaf" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #3 = { nofree nounwind }

!llvm.module.flags = !{!0, !1, !2}
!llvm.ident = !{!3}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 15, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 7, !"PIC Level", i32 2}
!3 = !{!"clang version 9.0.1 (https://github.com/goog00/llvm-project.git d34d9abedad96104b14e440d3e68d5c8ace5f9a6)"}
!4 = !{!5, !5, i64 0}
!5 = !{!"float", !6, i64 0}
!6 = !{!"omnipotent char", !7, i64 0}
!7 = !{!"Simple C/C++ TBAA"}
!8 = !{!9, !9, i64 0}
!9 = !{!"any pointer", !6, i64 0}
