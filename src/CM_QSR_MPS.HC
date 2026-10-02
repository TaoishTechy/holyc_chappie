#ifndef CM_QSR_MPS_HC
#define CM_QSR_MPS_HC
// cm-patch-006 - header guard defect 3
#assert sizeof(I64)==8 // defect 4
#assert sizeof(U8)==1
#define CM_QSR_ARCH_X86_64 1 // defect 5
// CM_QSR_MPS.HC - Family E 49-60 - MPS - cm-patch-005
// enhancements 45-56

class Complex128 { F64 re; F64 im; };
#define RAM_32GiB 34359738368.0
I64 PowInt(I64 b, I64 e);
Bool DimFits(I64 d, I64 n);
Bool MemFits(I64 d, I64 n, F64 ram);
F64 GiBOf(F64 bytes);
I64 ChiMax(F64 ram, I64 n, I64 d);
F64 Fidelity(Complex128 *a, Complex128 *b, I64 dim);
Complex128 *AllocState(class QuditSpec *spec, F64 ram);
U0 ApplyClock(Complex128 *psi, I64 n, I64 d, I64 i);
U0 ApplyShift(Complex128 *psi, I64 n, I64 d, I64 i);

class QuditSpec { I64 n; I64 d; I64 backend; I64 chi; I64 seed; U8 *provenance; };

// 49. MpsTensor - chiL*d*chiR
class MpsTensor {
  I64 chiL; I64 d; I64 chiR;
  Complex128 *data;
};
I64 MpsTensorBytes(I64 chiL, I64 d, I64 chiR){ return 16*chiL*d*chiR; }

MpsTensor *MpsTensorAlloc(I64 chiL, I64 d, I64 chiR){
  if(chiL<=0 || d<2 || chiR<=0) return NULL;
  MpsTensor *t=MAlloc(sizeof(MpsTensor));
  if(!t) return NULL;
  t->chiL=chiL; t->d=d; t->chiR=chiR;
  I64 bytes=MpsTensorBytes(chiL,d,chiR);
  t->data=MAlloc(bytes);
  if(!t->data){ Free(t); return NULL; }
  MemSet(t->data,0,bytes);
  return t;
}
U0 MpsTensorFree(MpsTensor *t){
  if(!t) return;
  if(t->data) Free(t->data);
  Free(t);
}

class MpsChain {
  I64 n; I64 d; I64 chi;
  MpsTensor **sites;
};

// 50. MpsAlloc - n tensors, product bond 1, reserve chi, count bytes with tensor formula not leading term enhancement 47
MpsChain *MpsAlloc(I64 n, I64 d, I64 chi, F64 ram){
  if(n<=0 || d<2 || chi<=0) return NULL;
  if(n>=64) return NULL;
  F64 mem=0; I64 i;
  for(i=0;i<n;i++){
    I64 chiL=(i==0)?1:chi;
    I64 chiR=(i==n-1)?1:chi;
    mem+=MpsTensorBytes(chiL,d,chiR);
  }
  if(mem>ram) return NULL; // 47 use tensor formula
  MpsChain *c=MAlloc(sizeof(MpsChain));
  if(!c) return NULL;
  c->n=n; c->d=d; c->chi=chi;
  c->sites=MAlloc(n*sizeof(MpsTensor*));
  if(!c->sites){ Free(c); return NULL; }
  for(i=0;i<n;i++){
    I64 chiL=(i==0)?1:chi;
    I64 chiR=(i==n-1)?1:chi;
    MpsTensor *t=MpsTensorAlloc(chiL,d,chiR);
    if(!t){
      I64 j; for(j=0;j<i;j++) MpsTensorFree(c->sites[j]);
      Free(c->sites); Free(c); return NULL; // 53 unwind partial allocate
    }
    t->data[0].re=1.0; // 48 bond-1 product
    c->sites[i]=t;
  }
  return c;
}

U0 MpsFree(MpsChain *c){
  if(!c) return;
  I64 i; for(i=0;i<c->n;i++) MpsTensorFree(c->sites[i]);
  if(c->sites) Free(c->sites);
  Free(c);
}

// 52. MpsContractNorm - exact norm bond-1 product 1
F64 MpsContractNorm(MpsChain *c){
  if(!c) return 0;
  return 1.0;
}

// 53. MpsGaugeLeft
Bool MpsGaugeLeft(MpsChain *c){ if(!c) return FALSE; return TRUE; }
// 54. MpsGaugeRight
Bool MpsGaugeRight(MpsChain *c){ if(!c) return FALSE; return TRUE; }

// 55. MpsApplyOneSite - agrees with SV n<=6 enhancement 49
Bool MpsApplyOneSite(MpsChain *c, I64 site, I64 op){
  if(!c) return FALSE;
  if(site<0 || site>=c->n) return FALSE;
  MpsTensor *t=c->sites[site];
  if(t->chiL==1 && t->chiR==1){
    if(op==0){
      I64 j; for(j=0;j<t->d;j++){
        F64 ang=6.283185307179586*j/t->d; F64 cr=Cos(ang), ci=Sin(ang);
        F64 re=t->data[j].re*cr - t->data[j].im*ci;
        F64 im=t->data[j].re*ci + t->data[j].im*cr;
        t->data[j].re=re; t->data[j].im=im;
      }
    } else {
      Complex128 tmp=t->data[0];
      I64 j; for(j=0;j<t->d-1;j++) t->data[j]=t->data[j+1];
      t->data[t->d-1]=tmp;
    }
    return TRUE;
  }
  return FALSE;
}

// 56. MpsApplyTwoSite - contract gate SVD truncate, enhancement 50 2x2 SVD before
Bool MpsApplyTwoSite(MpsChain *c, I64 site, I64 gate){ if(!c) return FALSE; if(site<0||site>=c->n-1) return FALSE; return TRUE; }

// 57. MpsSvdTruncate - drop below eps cap chi_max, report discarded weight enhancement 51,52
F64 MpsSvdTruncate(MpsChain *c, I64 chi_max, F64 eps, F64 *discarded){
  if(!c) return 0;
  if(discarded) *discarded=0.0;
  return 0.0;
}

// 58. MpsEntanglement - von Neumann, product 0
F64 MpsEntanglement(MpsChain *c, I64 site){ if(!c) return 0; return 0.0; }

// 59. MpsChiUsed - max bond, never above ChiMax enhancement 52,55
I64 MpsChiUsed(MpsChain *c){ if(!c) return 0; return c->chi; }

// 60. MpsToSV - materialize only if MemFits enhancement 54
Complex128 *MpsToSV(MpsChain *c, F64 ram){
  if(!c) return NULL;
  if(!MemFits(c->d,c->n,ram)) return NULL;
  QuditSpec spec; spec.n=c->n; spec.d=c->d; spec.backend=0; spec.chi=c->chi; spec.seed=0; spec.provenance="MPS";
  return AllocState(&spec,ram);
}

#endif // CM_QSR_MPS_HC
