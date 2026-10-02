#ifndef CM_QSR_SV_1_HC
#define CM_QSR_SV_1_HC
// cm-patch-006 - header guard defect 3
#assert sizeof(I64)==8 // defect 4
#assert sizeof(U8)==1
#define CM_QSR_ARCH_X86_64 1 // defect 5
// CM_QSR_SV.HC - Family C 25-36 - statevector runtime - cm-patch-005
// enhancements 33-44

class Complex128 { F64 re; F64 im; };
class QuditSpec {
  I64 n; I64 d; I64 backend; I64 chi; I64 seed; U8 *provenance;
};

#define B_CPU_SV 0
#define B_CPU_MPS 1
#define B_SPARSE 2
#define B_STABILIZER 3
#define B_MMAP 4
#define RAM_32GiB 34359738368.0

I64 PowInt(I64 b, I64 e);
Bool DimFits(I64 d, I64 n);
Bool MemFits(I64 d, I64 n, F64 ram);
F64 GiBOf(F64 bytes);

// 25. ValidSpec - d>=2, 1<=n<64, backend must be implemented, enhancement 42,43,44
Bool ValidSpec(QuditSpec *s){
  if(!s) return FALSE;
  if(s->d < 2) return FALSE;
  if(s->n < 1) return FALSE;
  if(s->n >= 64) return FALSE; // 42
  if(s->backend != B_CPU_SV) return FALSE; // 43 refuses unimplemented backends
  if(!s->provenance) return FALSE; // 44 require provenance before seal
  return TRUE;
}

// 26. AllocState - |0...0>, zero fill, refuse over card, enhancement 33,34,35
Complex128 *AllocState(QuditSpec *spec, F64 ram_limit){
  if(!spec) return NULL;
  if(!ValidSpec(spec)) return NULL;
  if(!DimFits(spec->d, spec->n)) return NULL;
  if(!MemFits(spec->d, spec->n, ram_limit)) return NULL; // 33 pass card limit
  I64 dim=PowInt(spec->d, spec->n); if(dim==0) return NULL;
  I64 bytes=dim*sizeof(Complex128);
  Complex128 *p=MAlloc(bytes);
  if(!p) return NULL; // 35 return NULL on allocator failure
  MemSet(p,0,bytes); // 34 zero block
  p[0].re=1.0; // then set index 0 to 1
  return p;
}

// 27. FreeState - null-safe, caller nulls pointer enhancement 40
U0 FreeState(Complex128 *p){
  if(p) Free(p);
}

// 28. SiteStride - d^i via PowInt after DimFits
I64 SiteStride(I64 d, I64 i){
  if(i<0) return 0;
  if(!DimFits(d,i)) return 0;
  return PowInt(d,i);
}

// 29. DigitAt - (idx/stride)%d
I64 DigitAt(I64 idx, I64 stride, I64 d){
  if(stride<=0 || d<2) return 0;
  return (idx/stride)%d;
}

// 30. ComposeIndex - rebuild index from digits, inverse of digit extraction
I64 ComposeIndex(I64 *digits, I64 n, I64 d){
  if(!digits) return 0;
  I64 idx=0; I64 stride=1; I64 i;
  for(i=0;i<n;i++){
    idx+=digits[i]*stride;
    if(!DimFits(d,i+1)) return 0;
    stride*=d;
  }
  return idx;
}

// 31. ApplyPhaseGlobal - multiply every amplitude by one Complex128, fidelity 1 fixture 54
U0 ApplyPhaseGlobal(Complex128 *psi, I64 dim, Complex128 phase){
  if(!psi) return;
  I64 k;
  for(k=0;k<dim;k++){
    F64 re=psi[k].re*phase.re - psi[k].im*phase.im;
    F64 im=psi[k].re*phase.im + psi[k].im*phase.re;
    psi[k].re=re; psi[k].im=im;
  }
}

// 32. Norm2 - sum |a|^2
F64 Norm2(Complex128 *psi, I64 dim){
  if(!psi || dim<=0) return 0;
  F64 s=0; I64 k;
  for(k=0;k<dim;k++) s+=psi[k].re*psi[k].re + psi[k].im*psi[k].im;
  return s;
}

// 33. Overlap - returns Complex128, correct sign: conj(a)*b = a.re*b.re + a.im*b.im + i*(a.re*b.im - a.im*b.re)
// enhancement 36
Complex128 Overlap(Complex128 *a, Complex128 *b, I64 dim){
  Complex128 res; res.re=0; res.im=0;
  if(!a || !b || dim<=0) return res;
  F64 re=0, im=0; I64 k;
  for(k=0;k<dim;k++){
    re+=a[k].re*b[k].re + a[k].im*b[k].im;
    im+=a[k].re*b[k].im - a[k].im*b[k].re; // correct sign enhancement 52
  }
  res.re=re; res.im=im;
  return res;
}

// 34. Fidelity - |overlap|^2/(na nb), enhancement 37, 53,54
F64 Fidelity(Complex128 *a, Complex128 *b, I64 dim){
  if(!a || !b || dim<=0) return 0;
  F64 na=Norm2(a,dim); F64 nb=Norm2(b,dim);
  if(na==0 || nb==0) return 0; // enhancement 55 zero returns 0 no 1e-30 floor enhancement 38
  Complex128 ov=Overlap(a,b,dim);
  F64 mag2=ov.re*ov.re + ov.im*ov.im;
  return mag2/(na*nb);
}

// 35. Renorm - divide by sqrt(Norm2), refuse if norm 0 enhancement 39
Bool Renorm(Complex128 *psi, I64 dim){
  if(!psi) return FALSE;
  F64 n2=Norm2(psi,dim);
  if(n2==0) return FALSE;
  F64 inv=1.0/Sqrt(n2);
  I64 k; for(k=0;k<dim;k++){ psi[k].re*=inv; psi[k].im*=inv; }
  return TRUE;
}

// 36. SnapshotCopy - explicit full copy for fixtures only, enhancement 41
Complex128 *SnapshotCopy(Complex128 *src, I64 dim){
  if(!src || dim<=0) return NULL;
  I64 bytes=dim*sizeof(Complex128);
  Complex128 *dst=MAlloc(bytes);
  if(!dst) return NULL;
  MemCpy(dst,src,bytes);
  return dst;
}

#endif // CM_QSR_SV_1_HC
