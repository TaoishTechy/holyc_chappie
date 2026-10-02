#ifndef CM_QSR_K_1_HC
#define CM_QSR_K_1_HC
// cm-patch-006 - header guard defect 3
#assert sizeof(I64)==8 // defect 4
#assert sizeof(U8)==1
#define CM_QSR_ARCH_X86_64 1 // defect 5
// CM_QSR_K.HC - Family K 121-132 - signal and number theory - cm-patch-005
// enhancements 85-87

class Complex128 { F64 re; F64 im; };

I64 Gcd(I64 a, I64 b){
  if(a<0) a=-a; if(b<0) b=-b;
  while(b!=0){ I64 t=a%b; a=b; b=t; }
  return a;
}

I64 ExtGcd(I64 a, I64 b, I64 *x, I64 *y){
  if(b==0){ if(x) *x=1; if(y) *y=0; return a; }
  I64 x1,y1; I64 g=ExtGcd(b, a%b, &x1, &y1);
  if(x) *x=y1; if(y) *y=x1 - (a/b)*y1; return g;
}

Bool IsPrimeTrial(I64 n){
  if(n<=1) return FALSE;
  if(n==2||n==3||n==5||n==7) return TRUE;
  if(n%2==0) return FALSE;
  I64 r=ToI64(Sqrt(n));
  I64 i; for(i=3;i<=r;i+=2) if(n%i==0) return FALSE;
  return TRUE;
}

I64 BitReverse(I64 x, I64 bits){
  I64 r=0; I64 i; for(i=0;i<bits;i++){ r=(r<<1)|(x&1); x>>=1; }
  return r;
}

Bool FftRadix2(Complex128 *v, I64 n){
  if(!v || n<=0) return FALSE;
  if((n & (n-1))!=0) return FALSE;
  I64 bits=0, tmp=n; while(tmp>1){ bits++; tmp>>=1; }
  I64 i; for(i=0;i<n;i++){ I64 rev=BitReverse(i,bits); if(rev>i){ Complex128 t=v[i]; v[i]=v[rev]; v[rev]=t; } }
  I64 len; for(len=2; len<=n; len<<=1){
    F64 ang=-6.283185307179586/len;
    Complex128 wlen; wlen.re=Cos(ang); wlen.im=Sin(ang);
    for(i=0;i<n;i+=len){
      Complex128 w; w.re=1; w.im=0; I64 j;
      for(j=0;j<len/2;j++){
        Complex128 u=v[i+j];
        Complex128 t; t.re=v[i+j+len/2].re*w.re - v[i+j+len/2].im*w.im;
        t.im=v[i+j+len/2].re*w.im + v[i+j+len/2].im*w.re;
        v[i+j].re=u.re+t.re; v[i+j].im=u.im+t.im;
        v[i+j+len/2].re=u.re-t.re; v[i+j+len/2].im=u.im-t.im;
        F64 wre=w.re*wlen.re - w.im*wlen.im; F64 wim=w.re*wlen.im + w.im*wlen.re; w.re=wre; w.im=wim;
      }
    }
  }
  return TRUE;
}

Bool IfftRadix2(Complex128 *v, I64 n){
  if(!v) return FALSE;
  I64 i; for(i=0;i<n;i++) v[i].im=-v[i].im;
  if(!FftRadix2(v,n)) return FALSE;
  for(i=0;i<n;i++){ v[i].re/=n; v[i].im=-v[i].im/n; }
  return TRUE;
}

Bool QuditDFT(Complex128 *v, I64 d){
  if(!v || d<2 || d>16) return FALSE;
  Complex128 *tmp=MAlloc(d*sizeof(Complex128));
  if(!tmp) return FALSE;
  MemCpy(tmp,v,d*sizeof(Complex128));
  F64 inv=Sqrt(d); inv=1.0/inv; I64 k,j;
  for(k=0;k<d;k++){
    Complex128 sum; sum.re=0; sum.im=0;
    for(j=0;j<d;j++){
      F64 ang=6.283185307179586*j*k/d; F64 cr=Cos(ang), ci=Sin(ang);
      sum.re+=tmp[j].re*cr - tmp[j].im*ci; sum.im+=tmp[j].re*ci + tmp[j].im*cr;
    }
    v[k].re=sum.re*inv; v[k].im=sum.im*inv;
  }
  Free(tmp); return TRUE;
}

Bool ConvolutionMod(I64 *a, I64 *b, I64 n, I64 mod, I64 *out){
  if(!a||!b||!out||n<=0||mod<=1) return FALSE;
  I64 i,j; for(i=0;i<n;i++) out[i]=0;
  for(i=0;i<n;i++) for(j=0;j<n;j++){ I64 k=(i+j)%n; out[k]=(out[k]+a[i]*b[j])%mod; }
  return TRUE;
}

F64 DotF64(F64 *a, F64 *b, I64 n){
  if(!a||!b||n<=0) return 0;
  F64 s=0; I64 i; for(i=0;i<n;i++) s+=a[i]*b[i]; return s;
}

Bool Householder2(F64 *v, I64 n, F64 *beta){
  if(!v||n!=2||!beta) return FALSE;
  F64 norm=Sqrt(v[0]*v[0]+v[1]*v[1]); if(norm==0){ *beta=0; return TRUE; }
  *beta=1.0; return TRUE;
}

Bool Svd2x2(F64 a, F64 b, F64 c, F64 d, F64 *s1, F64 *s2){
  if(!s1||!s2) return FALSE;
  F64 t1=a*a + c*c; F64 t2=b*b + d*d; F64 t3=a*b + c*d;
  F64 tr=t1+t2; F64 det=t1*t2 - t3*t3; F64 disc=tr*tr -4*det; if(disc<0) disc=0;
  F64 e1=(tr+Sqrt(disc))/2; F64 e2=(tr-Sqrt(disc))/2; if(e1<0) e1=0; if(e2<0) e2=0;
  *s1=Sqrt(e1); *s2=Sqrt(e2); return TRUE; // enhancement 87 fixture before MPS two-site
}

I64 Log2Floor(I64 x){
  if(x<=0) return -1;
  I64 r=0; while(x>1){ x>>=1; r++; } return r;
}

#endif // CM_QSR_K_1_HC
