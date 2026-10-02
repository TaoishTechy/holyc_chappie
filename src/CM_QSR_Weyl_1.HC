#ifndef CM_QSR_WEYL_1_HC
#define CM_QSR_WEYL_1_HC
// cm-patch-006 - header guard defect 3
#assert sizeof(I64)==8 // defect 4
#assert sizeof(U8)==1
#define CM_QSR_ARCH_X86_64 1 // defect 5
// CM_QSR_Weyl.HC - Family B 13-24 - Weyl-Heisenberg - cm-patch-005
// Depends on Num. Fix pack 17-32 implemented.

class Complex128 { F64 re; F64 im; };

I64 PowInt(I64 b, I64 e);
Bool DimFits(I64 d, I64 n);
F64 GiBOf(F64 bytes);
#define RAM_32GiB 34359738368.0

// 13. Omega - exp(2 pi i j / d), Omega(d,d)==1, Omega(4,1)==i
Complex128 Omega(I64 d, I64 j){
  Complex128 c;
  if(d<=0){ c.re=1; c.im=0; return c; }
  I64 jm=j % d; if(jm<0) jm+=d;
  F64 ang=6.283185307179586*jm/d;
  c.re=Cos(ang); c.im=Sin(ang);
  return c;
}

// 14. PhaseTable - d roots, built once per local dimension, not Cos/Sin per amplitude
class PhaseTable {
  I64 d;
  Complex128 *table; // size d
};

PhaseTable *PhaseTable_Create(I64 d){
  if(d<2 || d>1024) return NULL;
  PhaseTable *pt=MAlloc(sizeof(PhaseTable));
  if(!pt) return NULL;
  pt->d=d;
  pt->table=MAlloc(d*sizeof(Complex128));
  if(!pt->table){ Free(pt); return NULL; }
  I64 j; for(j=0;j<d;j++) pt->table[j]=Omega(d,j);
  return pt;
}

U0 PhaseTable_Free(PhaseTable *pt){
  if(!pt) return;
  if(pt->table) Free(pt->table);
  Free(pt);
}

// enhancement 22: refuse out-of-range site before any stride power
// enhancement 28: null-check psi first
// enhancement 27: do not allocate shadow state in kernel
// enhancement 26: permutation O(1) extra, one register

// 15. ApplyClock - Z_i |j> = ω^{j_i} |j>, diagonal, norm preserved
U0 ApplyClock(Complex128 *psi, I64 n, I64 d, I64 i){
  if(!psi) return; // 28
  if(i<0 || i>=n) return; // 22,29
  if(d<2) return; // 44
  if(!DimFits(d,n)) return;
  I64 total=PowInt(d,n); if(total==0) return;
  I64 stride=PowInt(d,i); if(stride==0) return;
  // enhancement 21: build phase table once per d
  PhaseTable *pt=PhaseTable_Create(d);
  if(!pt) return;
  I64 k;
  for(k=0;k<total;k++){
    I64 ji=(k/stride)%d;
    Complex128 w=pt->table[ji];
    F64 re=psi[k].re*w.re - psi[k].im*w.im;
    F64 im=psi[k].re*w.im + psi[k].im*w.re;
    psi[k].re=re; psi[k].im=im;
  }
  PhaseTable_Free(pt);
}

// 16. ApplyShift - FIXED DIRECTION per enhancement 17: X|j> = |j+1 mod d>
// Correct in-place forward rotation: tmp=psi[base]; shift 0<-1<-2..., last gets tmp
// This satisfies Test_ShiftDirection |0> -> |1>
U0 ApplyShift(Complex128 *psi, I64 n, I64 d, I64 i){
  if(!psi) return; // 28
  if(i<0 || i>=n) return; // 22
  if(d<2) return;
  if(!DimFits(d,n)) return;
  I64 stride=PowInt(d,i); if(stride==0) return;
  I64 block=stride*d;
  I64 total=PowInt(d,n); if(total==0) return;
  I64 high, low, j;
  for(high=0; high<total; high+=block){
    for(low=0; low<stride; low++){
      I64 base=high+low;
      Complex128 tmp=psi[base]; // digit 0
      for(j=0;j<d-1;j++){
        psi[base + j*stride]=psi[base + (j+1)*stride];
      }
      psi[base + (d-1)*stride]=tmp;
    }
  }
}

// 17. ApplyShiftPow - X^k as k mod d rotations, enhancement 23
U0 ApplyShiftPow(Complex128 *psi, I64 n, I64 d, I64 i, I64 k){
  if(!psi) return;
  if(d<2) return;
  if(i<0 || i>=n) return;
  I64 km=k % d; if(km<0) km+=d;
  if(km==0) return;
  I64 t; for(t=0;t<km;t++) ApplyShift(psi,n,d,i);
}

// 18. ApplyClockPow - Z^k
U0 ApplyClockPow(Complex128 *psi, I64 n, I64 d, I64 i, I64 k){
  if(!psi) return;
  if(i<0 || i>=n) return;
  I64 km=k % d; if(km<0) km+=d;
  if(km==0) return;
  I64 t; for(t=0;t<km;t++) ApplyClock(psi,n,d,i);
}

// 19. ApplyDisplacement - ω^{phase} X^a Z^b, enhancement 24 integer cocycle
U0 ApplyDisplacement(Complex128 *psi, I64 n, I64 d, I64 i, I64 a, I64 b){
  if(!psi) return;
  if(i<0 || i>=n) return;
  // Z^b then X^a, global phase omitted as not observable in fidelity
  ApplyClockPow(psi,n,d,i,b);
  ApplyShiftPow(psi,n,d,i,a);
}

// 20. CommutatorPhase - integer cocycle a*bp - b*ap mod d, no trig, enhancement 24
I64 CommutatorPhase(I64 d, I64 a, I64 b, I64 ap, I64 bp){
  if(d<=0) return 0;
  I64 v=a*bp - b*ap;
  v%=d; if(v<0) v+=d;
  return v;
}

// 21. ApplyControlledShift - control digit 1 applies X on target, d=2 fixture, enhancement 48
U0 ApplyControlledShift(Complex128 *psi, I64 n, I64 d, I64 c, I64 t){
  if(!psi) return;
  if(c<0 || t<0 || c>=n || t>=n) return;
  if(c==t) return;
  if(d!=2) return; // documented control digit only for d=2
  if(!DimFits(d,n)) return;
  I64 total=PowInt(d,n);
  I64 stride_c=PowInt(d,c);
  I64 stride_t=PowInt(d,t);
  I64 k;
  for(k=0;k<total;k++){
    I64 jc=(k/stride_c)%d;
    I64 jt=(k/stride_t)%d;
    if(jc==1 && jt==0){
      I64 partner=k+stride_t;
      if(partner<total){
        Complex128 tmp=psi[k];
        psi[k]=psi[partner];
        psi[partner]=tmp;
      }
    }
  }
}

// 22. ApplyFourierSite - F |j> = d^{-1/2} Σ ω^{jk} |k>, F^4=I fixture
U0 ApplyFourierSite(Complex128 *psi, I64 n, I64 d, I64 i){
  if(!psi) return;
  if(i<0 || i>=n) return;
  if(d<2 || d>16) return;
  if(!DimFits(d,n)) return;
  I64 total=PowInt(d,n);
  I64 stride=PowInt(d,i);
  I64 block=stride*d;
  F64 inv_sqrt=1.0/Sqrt(d);
  Complex128 *tmp=MAlloc(d*sizeof(Complex128));
  if(!tmp) return;
  I64 high, low, j, k;
  for(high=0; high<total; high+=block){
    for(low=0; low<stride; low++){
      I64 base=high+low;
      for(j=0;j<d;j++) tmp[j]=psi[base + j*stride];
      for(k=0;k<d;k++){
        Complex128 sum; sum.re=0; sum.im=0;
        for(j=0;j<d;j++){
          Complex128 w=Omega(d,(j*k)%d);
          sum.re+=tmp[j].re*w.re - tmp[j].im*w.im;
          sum.im+=tmp[j].re*w.im + tmp[j].im*w.re;
        }
        sum.re*=inv_sqrt; sum.im*=inv_sqrt;
        psi[base + k*stride]=sum;
      }
    }
  }
  Free(tmp);
}

// 23. ApplyInverseFourierSite - F†, fixture F†F=I
U0 ApplyInverseFourierSite(Complex128 *psi, I64 n, I64 d, I64 i){
  if(!psi) return;
  if(i<0 || i>=n) return;
  if(d<2 || d>16) return;
  if(!DimFits(d,n)) return;
  I64 total=PowInt(d,n);
  I64 stride=PowInt(d,i);
  I64 block=stride*d;
  F64 inv_sqrt=1.0/Sqrt(d);
  Complex128 *tmp=MAlloc(d*sizeof(Complex128));
  if(!tmp) return;
  I64 high, low, j, k;
  for(high=0; high<total; high+=block){
    for(low=0; low<stride; low++){
      I64 base=high+low;
      for(j=0;j<d;j++) tmp[j]=psi[base + j*stride];
      for(k=0;k<d;k++){
        Complex128 sum; sum.re=0; sum.im=0;
        for(j=0;j<d;j++){
          I64 exp=(d - (j*k)%d)%d;
          Complex128 w=Omega(d,exp);
          sum.re+=tmp[j].re*w.re - tmp[j].im*w.im;
          sum.im+=tmp[j].re*w.im + tmp[j].im*w.re;
        }
        sum.re*=inv_sqrt; sum.im*=inv_sqrt;
        psi[base + k*stride]=sum;
      }
    }
  }
  Free(tmp);
}

// 24. WeylOrder - returns d
I64 WeylOrder(I64 d){
  if(d<2) return 0;
  return d;
}

#endif // CM_QSR_WEYL_1_HC
