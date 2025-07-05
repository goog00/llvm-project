; ModuleID = 'matadd.ll'
source_filename = "matadd.c"
target datalayout = "e-m:o-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx10.20.0"

; Function Attrs: nofree norecurse nounwind ssp uwtable
define void @matadd(float* nocapture readonly %A, float* nocapture readonly %B, float* nocapture %C) local_unnamed_addr #0 {
entry:
  %polly.access.A = getelementptr float, float* %A, i64 10000
  %0 = icmp ule float* %polly.access.A, %C
  %polly.access.C34 = getelementptr float, float* %C, i64 10000
  %1 = icmp ule float* %polly.access.C34, %A
  %2 = or i1 %0, %1
  %polly.access.B = getelementptr float, float* %B, i64 10000
  %3 = icmp ule float* %polly.access.B, %C
  %4 = icmp ule float* %polly.access.C34, %B
  %5 = or i1 %3, %4
  %6 = and i1 %2, %5
  br i1 %6, label %polly.loop_header, label %for.cond1.preheader

for.cond1.preheader:                              ; preds = %for.cond.cleanup3, %entry
  %indvars.iv30 = phi i64 [ %indvars.iv.next31, %for.cond.cleanup3 ], [ 0, %entry ]
  %7 = mul nuw nsw i64 %indvars.iv30, 100
  %scevgep = getelementptr float, float* %C, i64 %7
  %8 = add nuw i64 %7, 100
  %scevgep92 = getelementptr float, float* %C, i64 %8
  %9 = mul nuw nsw i64 %indvars.iv30, 100
  %scevgep100 = getelementptr float, float* %B, i64 %8
  %scevgep98 = getelementptr float, float* %B, i64 %7
  %scevgep96 = getelementptr float, float* %A, i64 %8
  %scevgep94 = getelementptr float, float* %A, i64 %7
  %bound0 = icmp ult float* %scevgep, %scevgep96
  %bound1 = icmp ult float* %scevgep94, %scevgep92
  %found.conflict = and i1 %bound0, %bound1
  %bound0102 = icmp ult float* %scevgep, %scevgep100
  %bound1103 = icmp ult float* %scevgep98, %scevgep92
  %found.conflict104 = and i1 %bound0102, %bound1103
  %conflict.rdx = or i1 %found.conflict, %found.conflict104
  br i1 %conflict.rdx, label %for.body4, label %vector.body

vector.body:                                      ; preds = %for.cond1.preheader
  %10 = getelementptr inbounds float, float* %A, i64 %9
  %11 = bitcast float* %10 to <4 x float>*
  %wide.load = load <4 x float>, <4 x float>* %11, align 4, !tbaa !4, !alias.scope !8
  %12 = getelementptr inbounds float, float* %B, i64 %9
  %13 = bitcast float* %12 to <4 x float>*
  %wide.load105 = load <4 x float>, <4 x float>* %13, align 4, !tbaa !4, !alias.scope !11
  %14 = fadd <4 x float> %wide.load, %wide.load105
  %15 = getelementptr inbounds float, float* %C, i64 %9
  %16 = bitcast float* %15 to <4 x float>*
  store <4 x float> %14, <4 x float>* %16, align 4, !tbaa !4, !alias.scope !13, !noalias !15
  %17 = add nuw nsw i64 %9, 4
  %18 = getelementptr inbounds float, float* %A, i64 %17
  %19 = bitcast float* %18 to <4 x float>*
  %wide.load.1 = load <4 x float>, <4 x float>* %19, align 4, !tbaa !4, !alias.scope !8
  %20 = getelementptr inbounds float, float* %B, i64 %17
  %21 = bitcast float* %20 to <4 x float>*
  %wide.load105.1 = load <4 x float>, <4 x float>* %21, align 4, !tbaa !4, !alias.scope !11
  %22 = fadd <4 x float> %wide.load.1, %wide.load105.1
  %23 = getelementptr inbounds float, float* %C, i64 %17
  %24 = bitcast float* %23 to <4 x float>*
  store <4 x float> %22, <4 x float>* %24, align 4, !tbaa !4, !alias.scope !13, !noalias !15
  %25 = add nuw nsw i64 %9, 8
  %26 = getelementptr inbounds float, float* %A, i64 %25
  %27 = bitcast float* %26 to <4 x float>*
  %wide.load.2 = load <4 x float>, <4 x float>* %27, align 4, !tbaa !4, !alias.scope !8
  %28 = getelementptr inbounds float, float* %B, i64 %25
  %29 = bitcast float* %28 to <4 x float>*
  %wide.load105.2 = load <4 x float>, <4 x float>* %29, align 4, !tbaa !4, !alias.scope !11
  %30 = fadd <4 x float> %wide.load.2, %wide.load105.2
  %31 = getelementptr inbounds float, float* %C, i64 %25
  %32 = bitcast float* %31 to <4 x float>*
  store <4 x float> %30, <4 x float>* %32, align 4, !tbaa !4, !alias.scope !13, !noalias !15
  %33 = add nuw nsw i64 %9, 12
  %34 = getelementptr inbounds float, float* %A, i64 %33
  %35 = bitcast float* %34 to <4 x float>*
  %wide.load.3 = load <4 x float>, <4 x float>* %35, align 4, !tbaa !4, !alias.scope !8
  %36 = getelementptr inbounds float, float* %B, i64 %33
  %37 = bitcast float* %36 to <4 x float>*
  %wide.load105.3 = load <4 x float>, <4 x float>* %37, align 4, !tbaa !4, !alias.scope !11
  %38 = fadd <4 x float> %wide.load.3, %wide.load105.3
  %39 = getelementptr inbounds float, float* %C, i64 %33
  %40 = bitcast float* %39 to <4 x float>*
  store <4 x float> %38, <4 x float>* %40, align 4, !tbaa !4, !alias.scope !13, !noalias !15
  %41 = add nuw nsw i64 %9, 16
  %42 = getelementptr inbounds float, float* %A, i64 %41
  %43 = bitcast float* %42 to <4 x float>*
  %wide.load.4 = load <4 x float>, <4 x float>* %43, align 4, !tbaa !4, !alias.scope !8
  %44 = getelementptr inbounds float, float* %B, i64 %41
  %45 = bitcast float* %44 to <4 x float>*
  %wide.load105.4 = load <4 x float>, <4 x float>* %45, align 4, !tbaa !4, !alias.scope !11
  %46 = fadd <4 x float> %wide.load.4, %wide.load105.4
  %47 = getelementptr inbounds float, float* %C, i64 %41
  %48 = bitcast float* %47 to <4 x float>*
  store <4 x float> %46, <4 x float>* %48, align 4, !tbaa !4, !alias.scope !13, !noalias !15
  %49 = add nuw nsw i64 %9, 20
  %50 = getelementptr inbounds float, float* %A, i64 %49
  %51 = bitcast float* %50 to <4 x float>*
  %wide.load.5 = load <4 x float>, <4 x float>* %51, align 4, !tbaa !4, !alias.scope !8
  %52 = getelementptr inbounds float, float* %B, i64 %49
  %53 = bitcast float* %52 to <4 x float>*
  %wide.load105.5 = load <4 x float>, <4 x float>* %53, align 4, !tbaa !4, !alias.scope !11
  %54 = fadd <4 x float> %wide.load.5, %wide.load105.5
  %55 = getelementptr inbounds float, float* %C, i64 %49
  %56 = bitcast float* %55 to <4 x float>*
  store <4 x float> %54, <4 x float>* %56, align 4, !tbaa !4, !alias.scope !13, !noalias !15
  %57 = add nuw nsw i64 %9, 24
  %58 = getelementptr inbounds float, float* %A, i64 %57
  %59 = bitcast float* %58 to <4 x float>*
  %wide.load.6 = load <4 x float>, <4 x float>* %59, align 4, !tbaa !4, !alias.scope !8
  %60 = getelementptr inbounds float, float* %B, i64 %57
  %61 = bitcast float* %60 to <4 x float>*
  %wide.load105.6 = load <4 x float>, <4 x float>* %61, align 4, !tbaa !4, !alias.scope !11
  %62 = fadd <4 x float> %wide.load.6, %wide.load105.6
  %63 = getelementptr inbounds float, float* %C, i64 %57
  %64 = bitcast float* %63 to <4 x float>*
  store <4 x float> %62, <4 x float>* %64, align 4, !tbaa !4, !alias.scope !13, !noalias !15
  %65 = add nuw nsw i64 %9, 28
  %66 = getelementptr inbounds float, float* %A, i64 %65
  %67 = bitcast float* %66 to <4 x float>*
  %wide.load.7 = load <4 x float>, <4 x float>* %67, align 4, !tbaa !4, !alias.scope !8
  %68 = getelementptr inbounds float, float* %B, i64 %65
  %69 = bitcast float* %68 to <4 x float>*
  %wide.load105.7 = load <4 x float>, <4 x float>* %69, align 4, !tbaa !4, !alias.scope !11
  %70 = fadd <4 x float> %wide.load.7, %wide.load105.7
  %71 = getelementptr inbounds float, float* %C, i64 %65
  %72 = bitcast float* %71 to <4 x float>*
  store <4 x float> %70, <4 x float>* %72, align 4, !tbaa !4, !alias.scope !13, !noalias !15
  %73 = add nuw nsw i64 %9, 32
  %74 = getelementptr inbounds float, float* %A, i64 %73
  %75 = bitcast float* %74 to <4 x float>*
  %wide.load.8 = load <4 x float>, <4 x float>* %75, align 4, !tbaa !4, !alias.scope !8
  %76 = getelementptr inbounds float, float* %B, i64 %73
  %77 = bitcast float* %76 to <4 x float>*
  %wide.load105.8 = load <4 x float>, <4 x float>* %77, align 4, !tbaa !4, !alias.scope !11
  %78 = fadd <4 x float> %wide.load.8, %wide.load105.8
  %79 = getelementptr inbounds float, float* %C, i64 %73
  %80 = bitcast float* %79 to <4 x float>*
  store <4 x float> %78, <4 x float>* %80, align 4, !tbaa !4, !alias.scope !13, !noalias !15
  %81 = add nuw nsw i64 %9, 36
  %82 = getelementptr inbounds float, float* %A, i64 %81
  %83 = bitcast float* %82 to <4 x float>*
  %wide.load.9 = load <4 x float>, <4 x float>* %83, align 4, !tbaa !4, !alias.scope !8
  %84 = getelementptr inbounds float, float* %B, i64 %81
  %85 = bitcast float* %84 to <4 x float>*
  %wide.load105.9 = load <4 x float>, <4 x float>* %85, align 4, !tbaa !4, !alias.scope !11
  %86 = fadd <4 x float> %wide.load.9, %wide.load105.9
  %87 = getelementptr inbounds float, float* %C, i64 %81
  %88 = bitcast float* %87 to <4 x float>*
  store <4 x float> %86, <4 x float>* %88, align 4, !tbaa !4, !alias.scope !13, !noalias !15
  %89 = add nuw nsw i64 %9, 40
  %90 = getelementptr inbounds float, float* %A, i64 %89
  %91 = bitcast float* %90 to <4 x float>*
  %wide.load.10 = load <4 x float>, <4 x float>* %91, align 4, !tbaa !4, !alias.scope !8
  %92 = getelementptr inbounds float, float* %B, i64 %89
  %93 = bitcast float* %92 to <4 x float>*
  %wide.load105.10 = load <4 x float>, <4 x float>* %93, align 4, !tbaa !4, !alias.scope !11
  %94 = fadd <4 x float> %wide.load.10, %wide.load105.10
  %95 = getelementptr inbounds float, float* %C, i64 %89
  %96 = bitcast float* %95 to <4 x float>*
  store <4 x float> %94, <4 x float>* %96, align 4, !tbaa !4, !alias.scope !13, !noalias !15
  %97 = add nuw nsw i64 %9, 44
  %98 = getelementptr inbounds float, float* %A, i64 %97
  %99 = bitcast float* %98 to <4 x float>*
  %wide.load.11 = load <4 x float>, <4 x float>* %99, align 4, !tbaa !4, !alias.scope !8
  %100 = getelementptr inbounds float, float* %B, i64 %97
  %101 = bitcast float* %100 to <4 x float>*
  %wide.load105.11 = load <4 x float>, <4 x float>* %101, align 4, !tbaa !4, !alias.scope !11
  %102 = fadd <4 x float> %wide.load.11, %wide.load105.11
  %103 = getelementptr inbounds float, float* %C, i64 %97
  %104 = bitcast float* %103 to <4 x float>*
  store <4 x float> %102, <4 x float>* %104, align 4, !tbaa !4, !alias.scope !13, !noalias !15
  %105 = add nuw nsw i64 %9, 48
  %106 = getelementptr inbounds float, float* %A, i64 %105
  %107 = bitcast float* %106 to <4 x float>*
  %wide.load.12 = load <4 x float>, <4 x float>* %107, align 4, !tbaa !4, !alias.scope !8
  %108 = getelementptr inbounds float, float* %B, i64 %105
  %109 = bitcast float* %108 to <4 x float>*
  %wide.load105.12 = load <4 x float>, <4 x float>* %109, align 4, !tbaa !4, !alias.scope !11
  %110 = fadd <4 x float> %wide.load.12, %wide.load105.12
  %111 = getelementptr inbounds float, float* %C, i64 %105
  %112 = bitcast float* %111 to <4 x float>*
  store <4 x float> %110, <4 x float>* %112, align 4, !tbaa !4, !alias.scope !13, !noalias !15
  %113 = add nuw nsw i64 %9, 52
  %114 = getelementptr inbounds float, float* %A, i64 %113
  %115 = bitcast float* %114 to <4 x float>*
  %wide.load.13 = load <4 x float>, <4 x float>* %115, align 4, !tbaa !4, !alias.scope !8
  %116 = getelementptr inbounds float, float* %B, i64 %113
  %117 = bitcast float* %116 to <4 x float>*
  %wide.load105.13 = load <4 x float>, <4 x float>* %117, align 4, !tbaa !4, !alias.scope !11
  %118 = fadd <4 x float> %wide.load.13, %wide.load105.13
  %119 = getelementptr inbounds float, float* %C, i64 %113
  %120 = bitcast float* %119 to <4 x float>*
  store <4 x float> %118, <4 x float>* %120, align 4, !tbaa !4, !alias.scope !13, !noalias !15
  %121 = add nuw nsw i64 %9, 56
  %122 = getelementptr inbounds float, float* %A, i64 %121
  %123 = bitcast float* %122 to <4 x float>*
  %wide.load.14 = load <4 x float>, <4 x float>* %123, align 4, !tbaa !4, !alias.scope !8
  %124 = getelementptr inbounds float, float* %B, i64 %121
  %125 = bitcast float* %124 to <4 x float>*
  %wide.load105.14 = load <4 x float>, <4 x float>* %125, align 4, !tbaa !4, !alias.scope !11
  %126 = fadd <4 x float> %wide.load.14, %wide.load105.14
  %127 = getelementptr inbounds float, float* %C, i64 %121
  %128 = bitcast float* %127 to <4 x float>*
  store <4 x float> %126, <4 x float>* %128, align 4, !tbaa !4, !alias.scope !13, !noalias !15
  %129 = add nuw nsw i64 %9, 60
  %130 = getelementptr inbounds float, float* %A, i64 %129
  %131 = bitcast float* %130 to <4 x float>*
  %wide.load.15 = load <4 x float>, <4 x float>* %131, align 4, !tbaa !4, !alias.scope !8
  %132 = getelementptr inbounds float, float* %B, i64 %129
  %133 = bitcast float* %132 to <4 x float>*
  %wide.load105.15 = load <4 x float>, <4 x float>* %133, align 4, !tbaa !4, !alias.scope !11
  %134 = fadd <4 x float> %wide.load.15, %wide.load105.15
  %135 = getelementptr inbounds float, float* %C, i64 %129
  %136 = bitcast float* %135 to <4 x float>*
  store <4 x float> %134, <4 x float>* %136, align 4, !tbaa !4, !alias.scope !13, !noalias !15
  %137 = add nuw nsw i64 %9, 64
  %138 = getelementptr inbounds float, float* %A, i64 %137
  %139 = bitcast float* %138 to <4 x float>*
  %wide.load.16 = load <4 x float>, <4 x float>* %139, align 4, !tbaa !4, !alias.scope !8
  %140 = getelementptr inbounds float, float* %B, i64 %137
  %141 = bitcast float* %140 to <4 x float>*
  %wide.load105.16 = load <4 x float>, <4 x float>* %141, align 4, !tbaa !4, !alias.scope !11
  %142 = fadd <4 x float> %wide.load.16, %wide.load105.16
  %143 = getelementptr inbounds float, float* %C, i64 %137
  %144 = bitcast float* %143 to <4 x float>*
  store <4 x float> %142, <4 x float>* %144, align 4, !tbaa !4, !alias.scope !13, !noalias !15
  %145 = add nuw nsw i64 %9, 68
  %146 = getelementptr inbounds float, float* %A, i64 %145
  %147 = bitcast float* %146 to <4 x float>*
  %wide.load.17 = load <4 x float>, <4 x float>* %147, align 4, !tbaa !4, !alias.scope !8
  %148 = getelementptr inbounds float, float* %B, i64 %145
  %149 = bitcast float* %148 to <4 x float>*
  %wide.load105.17 = load <4 x float>, <4 x float>* %149, align 4, !tbaa !4, !alias.scope !11
  %150 = fadd <4 x float> %wide.load.17, %wide.load105.17
  %151 = getelementptr inbounds float, float* %C, i64 %145
  %152 = bitcast float* %151 to <4 x float>*
  store <4 x float> %150, <4 x float>* %152, align 4, !tbaa !4, !alias.scope !13, !noalias !15
  %153 = add nuw nsw i64 %9, 72
  %154 = getelementptr inbounds float, float* %A, i64 %153
  %155 = bitcast float* %154 to <4 x float>*
  %wide.load.18 = load <4 x float>, <4 x float>* %155, align 4, !tbaa !4, !alias.scope !8
  %156 = getelementptr inbounds float, float* %B, i64 %153
  %157 = bitcast float* %156 to <4 x float>*
  %wide.load105.18 = load <4 x float>, <4 x float>* %157, align 4, !tbaa !4, !alias.scope !11
  %158 = fadd <4 x float> %wide.load.18, %wide.load105.18
  %159 = getelementptr inbounds float, float* %C, i64 %153
  %160 = bitcast float* %159 to <4 x float>*
  store <4 x float> %158, <4 x float>* %160, align 4, !tbaa !4, !alias.scope !13, !noalias !15
  %161 = add nuw nsw i64 %9, 76
  %162 = getelementptr inbounds float, float* %A, i64 %161
  %163 = bitcast float* %162 to <4 x float>*
  %wide.load.19 = load <4 x float>, <4 x float>* %163, align 4, !tbaa !4, !alias.scope !8
  %164 = getelementptr inbounds float, float* %B, i64 %161
  %165 = bitcast float* %164 to <4 x float>*
  %wide.load105.19 = load <4 x float>, <4 x float>* %165, align 4, !tbaa !4, !alias.scope !11
  %166 = fadd <4 x float> %wide.load.19, %wide.load105.19
  %167 = getelementptr inbounds float, float* %C, i64 %161
  %168 = bitcast float* %167 to <4 x float>*
  store <4 x float> %166, <4 x float>* %168, align 4, !tbaa !4, !alias.scope !13, !noalias !15
  %169 = add nuw nsw i64 %9, 80
  %170 = getelementptr inbounds float, float* %A, i64 %169
  %171 = bitcast float* %170 to <4 x float>*
  %wide.load.20 = load <4 x float>, <4 x float>* %171, align 4, !tbaa !4, !alias.scope !8
  %172 = getelementptr inbounds float, float* %B, i64 %169
  %173 = bitcast float* %172 to <4 x float>*
  %wide.load105.20 = load <4 x float>, <4 x float>* %173, align 4, !tbaa !4, !alias.scope !11
  %174 = fadd <4 x float> %wide.load.20, %wide.load105.20
  %175 = getelementptr inbounds float, float* %C, i64 %169
  %176 = bitcast float* %175 to <4 x float>*
  store <4 x float> %174, <4 x float>* %176, align 4, !tbaa !4, !alias.scope !13, !noalias !15
  %177 = add nuw nsw i64 %9, 84
  %178 = getelementptr inbounds float, float* %A, i64 %177
  %179 = bitcast float* %178 to <4 x float>*
  %wide.load.21 = load <4 x float>, <4 x float>* %179, align 4, !tbaa !4, !alias.scope !8
  %180 = getelementptr inbounds float, float* %B, i64 %177
  %181 = bitcast float* %180 to <4 x float>*
  %wide.load105.21 = load <4 x float>, <4 x float>* %181, align 4, !tbaa !4, !alias.scope !11
  %182 = fadd <4 x float> %wide.load.21, %wide.load105.21
  %183 = getelementptr inbounds float, float* %C, i64 %177
  %184 = bitcast float* %183 to <4 x float>*
  store <4 x float> %182, <4 x float>* %184, align 4, !tbaa !4, !alias.scope !13, !noalias !15
  %185 = add nuw nsw i64 %9, 88
  %186 = getelementptr inbounds float, float* %A, i64 %185
  %187 = bitcast float* %186 to <4 x float>*
  %wide.load.22 = load <4 x float>, <4 x float>* %187, align 4, !tbaa !4, !alias.scope !8
  %188 = getelementptr inbounds float, float* %B, i64 %185
  %189 = bitcast float* %188 to <4 x float>*
  %wide.load105.22 = load <4 x float>, <4 x float>* %189, align 4, !tbaa !4, !alias.scope !11
  %190 = fadd <4 x float> %wide.load.22, %wide.load105.22
  %191 = getelementptr inbounds float, float* %C, i64 %185
  %192 = bitcast float* %191 to <4 x float>*
  store <4 x float> %190, <4 x float>* %192, align 4, !tbaa !4, !alias.scope !13, !noalias !15
  %193 = add nuw nsw i64 %9, 92
  %194 = getelementptr inbounds float, float* %A, i64 %193
  %195 = bitcast float* %194 to <4 x float>*
  %wide.load.23 = load <4 x float>, <4 x float>* %195, align 4, !tbaa !4, !alias.scope !8
  %196 = getelementptr inbounds float, float* %B, i64 %193
  %197 = bitcast float* %196 to <4 x float>*
  %wide.load105.23 = load <4 x float>, <4 x float>* %197, align 4, !tbaa !4, !alias.scope !11
  %198 = fadd <4 x float> %wide.load.23, %wide.load105.23
  %199 = getelementptr inbounds float, float* %C, i64 %193
  %200 = bitcast float* %199 to <4 x float>*
  store <4 x float> %198, <4 x float>* %200, align 4, !tbaa !4, !alias.scope !13, !noalias !15
  %201 = add nuw nsw i64 %9, 96
  %202 = getelementptr inbounds float, float* %A, i64 %201
  %203 = bitcast float* %202 to <4 x float>*
  %wide.load.24 = load <4 x float>, <4 x float>* %203, align 4, !tbaa !4, !alias.scope !8
  %204 = getelementptr inbounds float, float* %B, i64 %201
  %205 = bitcast float* %204 to <4 x float>*
  %wide.load105.24 = load <4 x float>, <4 x float>* %205, align 4, !tbaa !4, !alias.scope !11
  %206 = fadd <4 x float> %wide.load.24, %wide.load105.24
  %207 = getelementptr inbounds float, float* %C, i64 %201
  %208 = bitcast float* %207 to <4 x float>*
  store <4 x float> %206, <4 x float>* %208, align 4, !tbaa !4, !alias.scope !13, !noalias !15
  br label %for.cond.cleanup3

for.cond.cleanup:                                 ; preds = %polly.loop_exit41, %for.cond.cleanup3
  ret void

for.cond.cleanup3:                                ; preds = %for.body4, %vector.body
  %indvars.iv.next31 = add nuw nsw i64 %indvars.iv30, 1
  %exitcond33 = icmp eq i64 %indvars.iv.next31, 100
  br i1 %exitcond33, label %for.cond.cleanup, label %for.cond1.preheader

for.body4:                                        ; preds = %for.body4, %for.cond1.preheader
  %indvars.iv = phi i64 [ %indvars.iv.next.1, %for.body4 ], [ 0, %for.cond1.preheader ]
  %209 = add nuw nsw i64 %indvars.iv, %9
  %arrayidx = getelementptr inbounds float, float* %A, i64 %209
  %210 = load float, float* %arrayidx, align 4, !tbaa !4
  %arrayidx8 = getelementptr inbounds float, float* %B, i64 %209
  %211 = load float, float* %arrayidx8, align 4, !tbaa !4
  %add9 = fadd float %210, %211
  %arrayidx13 = getelementptr inbounds float, float* %C, i64 %209
  store float %add9, float* %arrayidx13, align 4, !tbaa !4
  %indvars.iv.next = or i64 %indvars.iv, 1
  %212 = add nuw nsw i64 %indvars.iv.next, %9
  %arrayidx.1 = getelementptr inbounds float, float* %A, i64 %212
  %213 = load float, float* %arrayidx.1, align 4, !tbaa !4
  %arrayidx8.1 = getelementptr inbounds float, float* %B, i64 %212
  %214 = load float, float* %arrayidx8.1, align 4, !tbaa !4
  %add9.1 = fadd float %213, %214
  %arrayidx13.1 = getelementptr inbounds float, float* %C, i64 %212
  store float %add9.1, float* %arrayidx13.1, align 4, !tbaa !4
  %indvars.iv.next.1 = add nuw nsw i64 %indvars.iv, 2
  %exitcond.1 = icmp eq i64 %indvars.iv.next.1, 100
  br i1 %exitcond.1, label %for.cond.cleanup3, label %for.body4, !llvm.loop !16

polly.loop_header:                                ; preds = %polly.loop_exit41, %entry
  %polly.indvar = phi i64 [ %polly.indvar_next, %polly.loop_exit41 ], [ 0, %entry ]
  %215 = mul nsw i64 %polly.indvar, -32
  %216 = icmp slt i64 %215, -68
  %smin = select i1 %216, i64 %215, i64 -68
  %217 = add nsw i64 %smin, 100
  %218 = mul nsw i64 %polly.indvar, -32
  %219 = icmp slt i64 %218, -68
  %220 = select i1 %219, i64 %218, i64 -68
  %221 = add nsw i64 %220, 99
  %polly.loop_guard = icmp sgt i64 %221, -1
  %222 = shl i64 %polly.indvar, 5
  br i1 %polly.loop_guard, label %polly.loop_header45.us.us, label %polly.loop_exit41

polly.loop_header45.us.us:                        ; preds = %polly.loop_header45.us.us, %polly.loop_header
  %polly.indvar48.us.us = phi i64 [ %polly.indvar_next49.us.us, %polly.loop_header45.us.us ], [ 0, %polly.loop_header ]
  %223 = add nuw nsw i64 %polly.indvar48.us.us, %222
  %224 = mul i64 %223, 100
  %225 = getelementptr float, float* %A, i64 %224
  %226 = bitcast float* %225 to <4 x float>*
  %wide.load156 = load <4 x float>, <4 x float>* %226, align 4, !alias.scope !18, !noalias !20
  %227 = getelementptr float, float* %B, i64 %224
  %228 = bitcast float* %227 to <4 x float>*
  %wide.load157 = load <4 x float>, <4 x float>* %228, align 4, !alias.scope !21, !noalias !23
  %229 = fadd <4 x float> %wide.load156, %wide.load157
  %230 = getelementptr float, float* %C, i64 %224
  %231 = bitcast float* %230 to <4 x float>*
  store <4 x float> %229, <4 x float>* %231, align 4, !alias.scope !22, !noalias !24
  %232 = add i64 %224, 4
  %233 = getelementptr float, float* %A, i64 %232
  %234 = bitcast float* %233 to <4 x float>*
  %wide.load156.1 = load <4 x float>, <4 x float>* %234, align 4, !alias.scope !18, !noalias !20
  %235 = getelementptr float, float* %B, i64 %232
  %236 = bitcast float* %235 to <4 x float>*
  %wide.load157.1 = load <4 x float>, <4 x float>* %236, align 4, !alias.scope !21, !noalias !23
  %237 = fadd <4 x float> %wide.load156.1, %wide.load157.1
  %238 = getelementptr float, float* %C, i64 %232
  %239 = bitcast float* %238 to <4 x float>*
  store <4 x float> %237, <4 x float>* %239, align 4, !alias.scope !22, !noalias !24
  %240 = add i64 %224, 8
  %241 = getelementptr float, float* %A, i64 %240
  %242 = bitcast float* %241 to <4 x float>*
  %wide.load156.2 = load <4 x float>, <4 x float>* %242, align 4, !alias.scope !18, !noalias !20
  %243 = getelementptr float, float* %B, i64 %240
  %244 = bitcast float* %243 to <4 x float>*
  %wide.load157.2 = load <4 x float>, <4 x float>* %244, align 4, !alias.scope !21, !noalias !23
  %245 = fadd <4 x float> %wide.load156.2, %wide.load157.2
  %246 = getelementptr float, float* %C, i64 %240
  %247 = bitcast float* %246 to <4 x float>*
  store <4 x float> %245, <4 x float>* %247, align 4, !alias.scope !22, !noalias !24
  %248 = add i64 %224, 12
  %249 = getelementptr float, float* %A, i64 %248
  %250 = bitcast float* %249 to <4 x float>*
  %wide.load156.3 = load <4 x float>, <4 x float>* %250, align 4, !alias.scope !18, !noalias !20
  %251 = getelementptr float, float* %B, i64 %248
  %252 = bitcast float* %251 to <4 x float>*
  %wide.load157.3 = load <4 x float>, <4 x float>* %252, align 4, !alias.scope !21, !noalias !23
  %253 = fadd <4 x float> %wide.load156.3, %wide.load157.3
  %254 = getelementptr float, float* %C, i64 %248
  %255 = bitcast float* %254 to <4 x float>*
  store <4 x float> %253, <4 x float>* %255, align 4, !alias.scope !22, !noalias !24
  %256 = add i64 %224, 16
  %257 = getelementptr float, float* %A, i64 %256
  %258 = bitcast float* %257 to <4 x float>*
  %wide.load156.4 = load <4 x float>, <4 x float>* %258, align 4, !alias.scope !18, !noalias !20
  %259 = getelementptr float, float* %B, i64 %256
  %260 = bitcast float* %259 to <4 x float>*
  %wide.load157.4 = load <4 x float>, <4 x float>* %260, align 4, !alias.scope !21, !noalias !23
  %261 = fadd <4 x float> %wide.load156.4, %wide.load157.4
  %262 = getelementptr float, float* %C, i64 %256
  %263 = bitcast float* %262 to <4 x float>*
  store <4 x float> %261, <4 x float>* %263, align 4, !alias.scope !22, !noalias !24
  %264 = add i64 %224, 20
  %265 = getelementptr float, float* %A, i64 %264
  %266 = bitcast float* %265 to <4 x float>*
  %wide.load156.5 = load <4 x float>, <4 x float>* %266, align 4, !alias.scope !18, !noalias !20
  %267 = getelementptr float, float* %B, i64 %264
  %268 = bitcast float* %267 to <4 x float>*
  %wide.load157.5 = load <4 x float>, <4 x float>* %268, align 4, !alias.scope !21, !noalias !23
  %269 = fadd <4 x float> %wide.load156.5, %wide.load157.5
  %270 = getelementptr float, float* %C, i64 %264
  %271 = bitcast float* %270 to <4 x float>*
  store <4 x float> %269, <4 x float>* %271, align 4, !alias.scope !22, !noalias !24
  %272 = add i64 %224, 24
  %273 = getelementptr float, float* %A, i64 %272
  %274 = bitcast float* %273 to <4 x float>*
  %wide.load156.6 = load <4 x float>, <4 x float>* %274, align 4, !alias.scope !18, !noalias !20
  %275 = getelementptr float, float* %B, i64 %272
  %276 = bitcast float* %275 to <4 x float>*
  %wide.load157.6 = load <4 x float>, <4 x float>* %276, align 4, !alias.scope !21, !noalias !23
  %277 = fadd <4 x float> %wide.load156.6, %wide.load157.6
  %278 = getelementptr float, float* %C, i64 %272
  %279 = bitcast float* %278 to <4 x float>*
  store <4 x float> %277, <4 x float>* %279, align 4, !alias.scope !22, !noalias !24
  %280 = add i64 %224, 28
  %281 = getelementptr float, float* %A, i64 %280
  %282 = bitcast float* %281 to <4 x float>*
  %wide.load156.7 = load <4 x float>, <4 x float>* %282, align 4, !alias.scope !18, !noalias !20
  %283 = getelementptr float, float* %B, i64 %280
  %284 = bitcast float* %283 to <4 x float>*
  %wide.load157.7 = load <4 x float>, <4 x float>* %284, align 4, !alias.scope !21, !noalias !23
  %285 = fadd <4 x float> %wide.load156.7, %wide.load157.7
  %286 = getelementptr float, float* %C, i64 %280
  %287 = bitcast float* %286 to <4 x float>*
  store <4 x float> %285, <4 x float>* %287, align 4, !alias.scope !22, !noalias !24
  %polly.indvar_next49.us.us = add nuw nsw i64 %polly.indvar48.us.us, 1
  %polly.loop_cond50.us.us = icmp slt i64 %polly.indvar48.us.us, %221
  br i1 %polly.loop_cond50.us.us, label %polly.loop_header45.us.us, label %polly.loop_header45.us.us.1

polly.loop_exit41:                                ; preds = %polly.loop_header45.us.us.3, %polly.loop_header
  %polly.indvar_next = add nuw nsw i64 %polly.indvar, 1
  %exitcond87 = icmp eq i64 %polly.indvar_next, 4
  br i1 %exitcond87, label %for.cond.cleanup, label %polly.loop_header

polly.loop_header45.us.us.1:                      ; preds = %polly.loop_header45.us.us.1, %polly.loop_header45.us.us
  %polly.indvar48.us.us.1 = phi i64 [ %polly.indvar_next49.us.us.1, %polly.loop_header45.us.us.1 ], [ 0, %polly.loop_header45.us.us ]
  %288 = add nuw nsw i64 %polly.indvar48.us.us.1, %222
  %289 = mul i64 %288, 100
  %290 = add i64 %289, 32
  %291 = getelementptr float, float* %A, i64 %290
  %292 = bitcast float* %291 to <4 x float>*
  %wide.load143 = load <4 x float>, <4 x float>* %292, align 4, !alias.scope !18, !noalias !20
  %293 = getelementptr float, float* %B, i64 %290
  %294 = bitcast float* %293 to <4 x float>*
  %wide.load144 = load <4 x float>, <4 x float>* %294, align 4, !alias.scope !21, !noalias !23
  %295 = fadd <4 x float> %wide.load143, %wide.load144
  %296 = getelementptr float, float* %C, i64 %290
  %297 = bitcast float* %296 to <4 x float>*
  store <4 x float> %295, <4 x float>* %297, align 4, !alias.scope !22, !noalias !24
  %298 = add i64 %289, 36
  %299 = getelementptr float, float* %A, i64 %298
  %300 = bitcast float* %299 to <4 x float>*
  %wide.load143.1 = load <4 x float>, <4 x float>* %300, align 4, !alias.scope !18, !noalias !20
  %301 = getelementptr float, float* %B, i64 %298
  %302 = bitcast float* %301 to <4 x float>*
  %wide.load144.1 = load <4 x float>, <4 x float>* %302, align 4, !alias.scope !21, !noalias !23
  %303 = fadd <4 x float> %wide.load143.1, %wide.load144.1
  %304 = getelementptr float, float* %C, i64 %298
  %305 = bitcast float* %304 to <4 x float>*
  store <4 x float> %303, <4 x float>* %305, align 4, !alias.scope !22, !noalias !24
  %306 = add i64 %289, 40
  %307 = getelementptr float, float* %A, i64 %306
  %308 = bitcast float* %307 to <4 x float>*
  %wide.load143.2 = load <4 x float>, <4 x float>* %308, align 4, !alias.scope !18, !noalias !20
  %309 = getelementptr float, float* %B, i64 %306
  %310 = bitcast float* %309 to <4 x float>*
  %wide.load144.2 = load <4 x float>, <4 x float>* %310, align 4, !alias.scope !21, !noalias !23
  %311 = fadd <4 x float> %wide.load143.2, %wide.load144.2
  %312 = getelementptr float, float* %C, i64 %306
  %313 = bitcast float* %312 to <4 x float>*
  store <4 x float> %311, <4 x float>* %313, align 4, !alias.scope !22, !noalias !24
  %314 = add i64 %289, 44
  %315 = getelementptr float, float* %A, i64 %314
  %316 = bitcast float* %315 to <4 x float>*
  %wide.load143.3 = load <4 x float>, <4 x float>* %316, align 4, !alias.scope !18, !noalias !20
  %317 = getelementptr float, float* %B, i64 %314
  %318 = bitcast float* %317 to <4 x float>*
  %wide.load144.3 = load <4 x float>, <4 x float>* %318, align 4, !alias.scope !21, !noalias !23
  %319 = fadd <4 x float> %wide.load143.3, %wide.load144.3
  %320 = getelementptr float, float* %C, i64 %314
  %321 = bitcast float* %320 to <4 x float>*
  store <4 x float> %319, <4 x float>* %321, align 4, !alias.scope !22, !noalias !24
  %322 = add i64 %289, 48
  %323 = getelementptr float, float* %A, i64 %322
  %324 = bitcast float* %323 to <4 x float>*
  %wide.load143.4 = load <4 x float>, <4 x float>* %324, align 4, !alias.scope !18, !noalias !20
  %325 = getelementptr float, float* %B, i64 %322
  %326 = bitcast float* %325 to <4 x float>*
  %wide.load144.4 = load <4 x float>, <4 x float>* %326, align 4, !alias.scope !21, !noalias !23
  %327 = fadd <4 x float> %wide.load143.4, %wide.load144.4
  %328 = getelementptr float, float* %C, i64 %322
  %329 = bitcast float* %328 to <4 x float>*
  store <4 x float> %327, <4 x float>* %329, align 4, !alias.scope !22, !noalias !24
  %330 = add i64 %289, 52
  %331 = getelementptr float, float* %A, i64 %330
  %332 = bitcast float* %331 to <4 x float>*
  %wide.load143.5 = load <4 x float>, <4 x float>* %332, align 4, !alias.scope !18, !noalias !20
  %333 = getelementptr float, float* %B, i64 %330
  %334 = bitcast float* %333 to <4 x float>*
  %wide.load144.5 = load <4 x float>, <4 x float>* %334, align 4, !alias.scope !21, !noalias !23
  %335 = fadd <4 x float> %wide.load143.5, %wide.load144.5
  %336 = getelementptr float, float* %C, i64 %330
  %337 = bitcast float* %336 to <4 x float>*
  store <4 x float> %335, <4 x float>* %337, align 4, !alias.scope !22, !noalias !24
  %338 = add i64 %289, 56
  %339 = getelementptr float, float* %A, i64 %338
  %340 = bitcast float* %339 to <4 x float>*
  %wide.load143.6 = load <4 x float>, <4 x float>* %340, align 4, !alias.scope !18, !noalias !20
  %341 = getelementptr float, float* %B, i64 %338
  %342 = bitcast float* %341 to <4 x float>*
  %wide.load144.6 = load <4 x float>, <4 x float>* %342, align 4, !alias.scope !21, !noalias !23
  %343 = fadd <4 x float> %wide.load143.6, %wide.load144.6
  %344 = getelementptr float, float* %C, i64 %338
  %345 = bitcast float* %344 to <4 x float>*
  store <4 x float> %343, <4 x float>* %345, align 4, !alias.scope !22, !noalias !24
  %346 = add i64 %289, 60
  %347 = getelementptr float, float* %A, i64 %346
  %348 = bitcast float* %347 to <4 x float>*
  %wide.load143.7 = load <4 x float>, <4 x float>* %348, align 4, !alias.scope !18, !noalias !20
  %349 = getelementptr float, float* %B, i64 %346
  %350 = bitcast float* %349 to <4 x float>*
  %wide.load144.7 = load <4 x float>, <4 x float>* %350, align 4, !alias.scope !21, !noalias !23
  %351 = fadd <4 x float> %wide.load143.7, %wide.load144.7
  %352 = getelementptr float, float* %C, i64 %346
  %353 = bitcast float* %352 to <4 x float>*
  store <4 x float> %351, <4 x float>* %353, align 4, !alias.scope !22, !noalias !24
  %polly.indvar_next49.us.us.1 = add nuw nsw i64 %polly.indvar48.us.us.1, 1
  %polly.loop_cond50.us.us.1 = icmp slt i64 %polly.indvar48.us.us.1, %221
  br i1 %polly.loop_cond50.us.us.1, label %polly.loop_header45.us.us.1, label %polly.loop_header45.us.us.2

polly.loop_header45.us.us.2:                      ; preds = %polly.loop_header45.us.us.2, %polly.loop_header45.us.us.1
  %polly.indvar48.us.us.2 = phi i64 [ %polly.indvar_next49.us.us.2, %polly.loop_header45.us.us.2 ], [ 0, %polly.loop_header45.us.us.1 ]
  %354 = add nuw nsw i64 %polly.indvar48.us.us.2, %222
  %355 = mul i64 %354, 100
  %356 = add i64 %355, 64
  %357 = getelementptr float, float* %A, i64 %356
  %358 = bitcast float* %357 to <4 x float>*
  %wide.load130 = load <4 x float>, <4 x float>* %358, align 4, !alias.scope !18, !noalias !20
  %359 = getelementptr float, float* %B, i64 %356
  %360 = bitcast float* %359 to <4 x float>*
  %wide.load131 = load <4 x float>, <4 x float>* %360, align 4, !alias.scope !21, !noalias !23
  %361 = fadd <4 x float> %wide.load130, %wide.load131
  %362 = getelementptr float, float* %C, i64 %356
  %363 = bitcast float* %362 to <4 x float>*
  store <4 x float> %361, <4 x float>* %363, align 4, !alias.scope !22, !noalias !24
  %364 = add i64 %355, 68
  %365 = getelementptr float, float* %A, i64 %364
  %366 = bitcast float* %365 to <4 x float>*
  %wide.load130.1 = load <4 x float>, <4 x float>* %366, align 4, !alias.scope !18, !noalias !20
  %367 = getelementptr float, float* %B, i64 %364
  %368 = bitcast float* %367 to <4 x float>*
  %wide.load131.1 = load <4 x float>, <4 x float>* %368, align 4, !alias.scope !21, !noalias !23
  %369 = fadd <4 x float> %wide.load130.1, %wide.load131.1
  %370 = getelementptr float, float* %C, i64 %364
  %371 = bitcast float* %370 to <4 x float>*
  store <4 x float> %369, <4 x float>* %371, align 4, !alias.scope !22, !noalias !24
  %372 = add i64 %355, 72
  %373 = getelementptr float, float* %A, i64 %372
  %374 = bitcast float* %373 to <4 x float>*
  %wide.load130.2 = load <4 x float>, <4 x float>* %374, align 4, !alias.scope !18, !noalias !20
  %375 = getelementptr float, float* %B, i64 %372
  %376 = bitcast float* %375 to <4 x float>*
  %wide.load131.2 = load <4 x float>, <4 x float>* %376, align 4, !alias.scope !21, !noalias !23
  %377 = fadd <4 x float> %wide.load130.2, %wide.load131.2
  %378 = getelementptr float, float* %C, i64 %372
  %379 = bitcast float* %378 to <4 x float>*
  store <4 x float> %377, <4 x float>* %379, align 4, !alias.scope !22, !noalias !24
  %380 = add i64 %355, 76
  %381 = getelementptr float, float* %A, i64 %380
  %382 = bitcast float* %381 to <4 x float>*
  %wide.load130.3 = load <4 x float>, <4 x float>* %382, align 4, !alias.scope !18, !noalias !20
  %383 = getelementptr float, float* %B, i64 %380
  %384 = bitcast float* %383 to <4 x float>*
  %wide.load131.3 = load <4 x float>, <4 x float>* %384, align 4, !alias.scope !21, !noalias !23
  %385 = fadd <4 x float> %wide.load130.3, %wide.load131.3
  %386 = getelementptr float, float* %C, i64 %380
  %387 = bitcast float* %386 to <4 x float>*
  store <4 x float> %385, <4 x float>* %387, align 4, !alias.scope !22, !noalias !24
  %388 = add i64 %355, 80
  %389 = getelementptr float, float* %A, i64 %388
  %390 = bitcast float* %389 to <4 x float>*
  %wide.load130.4 = load <4 x float>, <4 x float>* %390, align 4, !alias.scope !18, !noalias !20
  %391 = getelementptr float, float* %B, i64 %388
  %392 = bitcast float* %391 to <4 x float>*
  %wide.load131.4 = load <4 x float>, <4 x float>* %392, align 4, !alias.scope !21, !noalias !23
  %393 = fadd <4 x float> %wide.load130.4, %wide.load131.4
  %394 = getelementptr float, float* %C, i64 %388
  %395 = bitcast float* %394 to <4 x float>*
  store <4 x float> %393, <4 x float>* %395, align 4, !alias.scope !22, !noalias !24
  %396 = add i64 %355, 84
  %397 = getelementptr float, float* %A, i64 %396
  %398 = bitcast float* %397 to <4 x float>*
  %wide.load130.5 = load <4 x float>, <4 x float>* %398, align 4, !alias.scope !18, !noalias !20
  %399 = getelementptr float, float* %B, i64 %396
  %400 = bitcast float* %399 to <4 x float>*
  %wide.load131.5 = load <4 x float>, <4 x float>* %400, align 4, !alias.scope !21, !noalias !23
  %401 = fadd <4 x float> %wide.load130.5, %wide.load131.5
  %402 = getelementptr float, float* %C, i64 %396
  %403 = bitcast float* %402 to <4 x float>*
  store <4 x float> %401, <4 x float>* %403, align 4, !alias.scope !22, !noalias !24
  %404 = add i64 %355, 88
  %405 = getelementptr float, float* %A, i64 %404
  %406 = bitcast float* %405 to <4 x float>*
  %wide.load130.6 = load <4 x float>, <4 x float>* %406, align 4, !alias.scope !18, !noalias !20
  %407 = getelementptr float, float* %B, i64 %404
  %408 = bitcast float* %407 to <4 x float>*
  %wide.load131.6 = load <4 x float>, <4 x float>* %408, align 4, !alias.scope !21, !noalias !23
  %409 = fadd <4 x float> %wide.load130.6, %wide.load131.6
  %410 = getelementptr float, float* %C, i64 %404
  %411 = bitcast float* %410 to <4 x float>*
  store <4 x float> %409, <4 x float>* %411, align 4, !alias.scope !22, !noalias !24
  %412 = add i64 %355, 92
  %413 = getelementptr float, float* %A, i64 %412
  %414 = bitcast float* %413 to <4 x float>*
  %wide.load130.7 = load <4 x float>, <4 x float>* %414, align 4, !alias.scope !18, !noalias !20
  %415 = getelementptr float, float* %B, i64 %412
  %416 = bitcast float* %415 to <4 x float>*
  %wide.load131.7 = load <4 x float>, <4 x float>* %416, align 4, !alias.scope !21, !noalias !23
  %417 = fadd <4 x float> %wide.load130.7, %wide.load131.7
  %418 = getelementptr float, float* %C, i64 %412
  %419 = bitcast float* %418 to <4 x float>*
  store <4 x float> %417, <4 x float>* %419, align 4, !alias.scope !22, !noalias !24
  %polly.indvar_next49.us.us.2 = add nuw nsw i64 %polly.indvar48.us.us.2, 1
  %polly.loop_cond50.us.us.2 = icmp slt i64 %polly.indvar48.us.us.2, %221
  br i1 %polly.loop_cond50.us.us.2, label %polly.loop_header45.us.us.2, label %polly.loop_header45.us.us.3

polly.loop_header45.us.us.3:                      ; preds = %polly.loop_header45.us.us.3, %polly.loop_header45.us.us.2
  %polly.indvar48.us.us.3 = phi i64 [ %polly.indvar_next49.us.us.3.1, %polly.loop_header45.us.us.3 ], [ 0, %polly.loop_header45.us.us.2 ]
  %niter = phi i64 [ %niter.nsub.1, %polly.loop_header45.us.us.3 ], [ %217, %polly.loop_header45.us.us.2 ]
  %420 = add nuw nsw i64 %polly.indvar48.us.us.3, %222
  %421 = mul i64 %420, 100
  %422 = add i64 %421, 96
  %423 = getelementptr float, float* %A, i64 %422
  %424 = bitcast float* %423 to <4 x float>*
  %wide.load117 = load <4 x float>, <4 x float>* %424, align 4, !alias.scope !18, !noalias !20
  %425 = getelementptr float, float* %B, i64 %422
  %426 = bitcast float* %425 to <4 x float>*
  %wide.load118 = load <4 x float>, <4 x float>* %426, align 4, !alias.scope !21, !noalias !23
  %427 = fadd <4 x float> %wide.load117, %wide.load118
  %428 = getelementptr float, float* %C, i64 %422
  %429 = bitcast float* %428 to <4 x float>*
  store <4 x float> %427, <4 x float>* %429, align 4, !alias.scope !22, !noalias !24
  %polly.indvar_next49.us.us.3 = or i64 %polly.indvar48.us.us.3, 1
  %430 = add nuw nsw i64 %polly.indvar_next49.us.us.3, %222
  %431 = mul i64 %430, 100
  %432 = add i64 %431, 96
  %433 = getelementptr float, float* %A, i64 %432
  %434 = bitcast float* %433 to <4 x float>*
  %wide.load117.1 = load <4 x float>, <4 x float>* %434, align 4, !alias.scope !18, !noalias !20
  %435 = getelementptr float, float* %B, i64 %432
  %436 = bitcast float* %435 to <4 x float>*
  %wide.load118.1 = load <4 x float>, <4 x float>* %436, align 4, !alias.scope !21, !noalias !23
  %437 = fadd <4 x float> %wide.load117.1, %wide.load118.1
  %438 = getelementptr float, float* %C, i64 %432
  %439 = bitcast float* %438 to <4 x float>*
  store <4 x float> %437, <4 x float>* %439, align 4, !alias.scope !22, !noalias !24
  %polly.indvar_next49.us.us.3.1 = add nuw nsw i64 %polly.indvar48.us.us.3, 2
  %niter.nsub.1 = add i64 %niter, -2
  %niter.ncmp.1 = icmp eq i64 %niter.nsub.1, 0
  br i1 %niter.ncmp.1, label %polly.loop_exit41, label %polly.loop_header45.us.us.3
}

attributes #0 = { nofree norecurse nounwind ssp uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-frame-pointer-elim"="true" "no-frame-pointer-elim-non-leaf" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "polly-optimized" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }

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
!8 = !{!9}
!9 = distinct !{!9, !10}
!10 = distinct !{!10, !"LVerDomain"}
!11 = !{!12}
!12 = distinct !{!12, !10}
!13 = !{!14}
!14 = distinct !{!14, !10}
!15 = !{!9, !12}
!16 = distinct !{!16, !17}
!17 = !{!"llvm.loop.isvectorized", i32 1}
!18 = distinct !{!18, !19, !"polly.alias.scope.MemRef0"}
!19 = distinct !{!19, !"polly.alias.scope.domain"}
!20 = !{!21, !22}
!21 = distinct !{!21, !19, !"polly.alias.scope.MemRef1"}
!22 = distinct !{!22, !19, !"polly.alias.scope.MemRef2"}
!23 = !{!18, !22}
!24 = !{!18, !21}
