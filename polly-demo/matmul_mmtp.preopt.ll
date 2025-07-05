; ModuleID = 'matmul_mmtp.ll'
source_filename = "matmul_MatMulTilingPass.c"
target datalayout = "e-m:o-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx10.20.0"

; Function Attrs: noinline nounwind ssp uwtable
define void @matmul(float* %A, float* %B, float* %C, i32 %N) #0 {
entry:
  br label %entry.split

entry.split:                                      ; preds = %entry
  %cmp6 = icmp sgt i32 %N, 0
  br i1 %cmp6, label %for.cond1.preheader.lr.ph, label %for.end22

for.cond1.preheader.lr.ph:                        ; preds = %entry.split
  %0 = sext i32 %N to i64
  %1 = sext i32 %N to i64
  %wide.trip.count20 = zext i32 %N to i64
  br label %for.cond1.preheader

for.cond1.preheader:                              ; preds = %for.cond1.preheader.lr.ph, %for.inc20
  %indvars.iv17 = phi i64 [ 0, %for.cond1.preheader.lr.ph ], [ %indvars.iv.next18, %for.inc20 ]
  %cmp23 = icmp sgt i32 %N, 0
  br i1 %cmp23, label %for.cond4.preheader.lr.ph, label %for.inc20

for.cond4.preheader.lr.ph:                        ; preds = %for.cond1.preheader
  %wide.trip.count15 = zext i32 %N to i64
  br label %for.cond4.preheader

for.cond4.preheader:                              ; preds = %for.cond4.preheader.lr.ph, %for.inc17
  %indvars.iv12 = phi i64 [ 0, %for.cond4.preheader.lr.ph ], [ %indvars.iv.next13, %for.inc17 ]
  %cmp51 = icmp sgt i32 %N, 0
  br i1 %cmp51, label %for.body6.lr.ph, label %for.inc17

for.body6.lr.ph:                                  ; preds = %for.cond4.preheader
  %wide.trip.count = zext i32 %N to i64
  br label %for.body6

for.body6:                                        ; preds = %for.body6.lr.ph, %for.body6
  %indvars.iv = phi i64 [ 0, %for.body6.lr.ph ], [ %indvars.iv.next, %for.body6 ]
  %2 = mul nsw i64 %indvars.iv17, %1
  %3 = add nsw i64 %indvars.iv, %2
  %arrayidx = getelementptr inbounds float, float* %A, i64 %3
  %4 = load float, float* %arrayidx, align 4
  %5 = mul nsw i64 %indvars.iv, %0
  %6 = add nsw i64 %5, %indvars.iv12
  %arrayidx10 = getelementptr inbounds float, float* %B, i64 %6
  %7 = load float, float* %arrayidx10, align 4
  %mul11 = fmul float %4, %7
  %8 = add nsw i64 %indvars.iv12, %2
  %arrayidx15 = getelementptr inbounds float, float* %C, i64 %8
  %9 = load float, float* %arrayidx15, align 4
  %add16 = fadd float %9, %mul11
  store float %add16, float* %arrayidx15, align 4
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  %exitcond = icmp ne i64 %indvars.iv.next, %wide.trip.count
  br i1 %exitcond, label %for.body6, label %for.cond4.for.inc17_crit_edge

for.cond4.for.inc17_crit_edge:                    ; preds = %for.body6
  br label %for.inc17

for.inc17:                                        ; preds = %for.cond4.for.inc17_crit_edge, %for.cond4.preheader
  %indvars.iv.next13 = add nuw nsw i64 %indvars.iv12, 1
  %exitcond16 = icmp ne i64 %indvars.iv.next13, %wide.trip.count15
  br i1 %exitcond16, label %for.cond4.preheader, label %for.cond1.for.inc20_crit_edge

for.cond1.for.inc20_crit_edge:                    ; preds = %for.inc17
  br label %for.inc20

for.inc20:                                        ; preds = %for.cond1.for.inc20_crit_edge, %for.cond1.preheader
  %indvars.iv.next18 = add nuw nsw i64 %indvars.iv17, 1
  %exitcond21 = icmp ne i64 %indvars.iv.next18, %wide.trip.count20
  br i1 %exitcond21, label %for.cond1.preheader, label %for.cond.for.end22_crit_edge

for.cond.for.end22_crit_edge:                     ; preds = %for.inc20
  br label %for.end22

for.end22:                                        ; preds = %for.cond.for.end22_crit_edge, %entry.split
  ret void
}

attributes #0 = { noinline nounwind ssp uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-frame-pointer-elim"="true" "no-frame-pointer-elim-non-leaf" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }

!llvm.module.flags = !{!0, !1, !2}
!llvm.ident = !{!3}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 15, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 7, !"PIC Level", i32 2}
!3 = !{!"clang version 9.0.1 (https://github.com/goog00/llvm-project.git d34d9abedad96104b14e440d3e68d5c8ace5f9a6)"}
