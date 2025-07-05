

void matadd(float *A, float *B, float *C) {
    for (int i = 0; i < 100; i++)
        for (int j = 0; j < 100; j++)
            C[i * 100 + j] = A[i * 100 + j] + B[i * 100 + j];
}