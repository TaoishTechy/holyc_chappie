#ifndef CM_QSR_SAMPLE_1_HC
#define CM_QSR_SAMPLE_1_HC
// cm-patch-006 - header guard defect 3
#assert sizeof(I64)==8 // defect 4
#assert sizeof(U8)==1
#define CM_QSR_ARCH_X86_64 1 // defect 5
// CM_QSR_Sample.HC - Family J 109-120 - sampling - cm-patch-005
// enhancements 81-84

class Complex128 { F64 re; F64 im; };
I64 SplitMix64(I64 *state);
I64 Xorshift64Star(I64 *state);
I64 ProvenanceSeal(I64 n, I64 d, I64 backend, I64 chi, I64 seed, U8 *tag);
I64 PowInt(I64 b, I64 e);
F64 Norm2(Complex128 *psi, I64 dim);

class QuditSpec { I64 n; I64 d; I64 backend; I64 chi; I64 seed; U8 *provenance; };

I64 SeedFromSpec(QuditSpec *spec){
  if(!spec) return 0;
  I64 s=spec->seed;
  if(s==0) return 0; // legal and documented
  return SplitMix64(&s);
}

F64 Uniform01(I64 *state){
  if(!state) return 0;
  I64 x=Xorshift64Star(state);
  I64 mant=(x>>11) & 0x1FFFFFFFFFFFFF;
  return mant * 1.1102230246251565e-16;
}

I64 BornSample(Complex128 *psi, I64 dim, I64 *state){
  if(!psi || dim<=0 || !state) return 0;
  F64 r=Uniform01(state);
  F64 cum=0, norm=Norm2(psi,dim); if(norm==0) return 0;
  I64 i; for(i=0;i<dim;i++){ F64 p=(psi[i].re*psi[i].re + psi[i].im*psi[i].im)/norm; cum+=p; if(r<cum) return i; }
  return dim-1;
}

I64 BornSampleSite(Complex128 *psi, I64 n, I64 d, I64 site, I64 *state){
  if(!psi) return 0;
  I64 dim=PowInt(d,n); if(dim==0) return 0;
  F64 *marg=MAlloc(d*sizeof(F64)); if(!marg) return 0;
  I64 i; for(i=0;i<d;i++) marg[i]=0;
  I64 total=dim; I64 stride=PowInt(d,site);
  for(i=0;i<total;i++){ I64 ji=(i/stride)%d; marg[ji]+=psi[i].re*psi[i].re + psi[i].im*psi[i].im; }
  F64 norm=Norm2(psi,dim); if(norm>0){ for(i=0;i<d;i++) marg[i]/=norm; }
  F64 r=Uniform01(state); F64 cum=0; I64 res=0;
  for(i=0;i<d;i++){ cum+=marg[i]; if(r<cum){ res=i; break; } }
  Free(marg); return res;
}

class Histogram { I64 bins; I64 *counts; };
Histogram *HistogramAlloc(I64 bins){
  Histogram *h=MAlloc(sizeof(Histogram)); if(!h) return NULL;
  h->bins=bins; h->counts=MAlloc(bins*sizeof(I64)); if(!h->counts){ Free(h); return NULL; }
  MemSet(h->counts,0,bins*sizeof(I64)); return h;
}
U0 HistogramFree(Histogram *h){ if(h){ if(h->counts) Free(h->counts); Free(h); } }
U0 HistogramAdd(Histogram *h, I64 idx){ if(!h || idx<0 || idx>=h->bins) return; h->counts[idx]++; }

Bool ShotLoop(Complex128 *psi, I64 n, I64 d, I64 shots, QuditSpec *spec, Histogram *hist){
  if(!psi||!spec||!hist) return FALSE;
  I64 state=SeedFromSpec(spec); if(state==0) state=1;
  I64 s; for(s=0;s<shots;s++){ I64 idx=BornSample(psi, PowInt(d,n), &state); HistogramAdd(hist, idx); }
  return TRUE; // enhancement 82 same seed same shot string, enhancement 83 counts sum to shots
}

I64 DiscreteSample(F64 *p, I64 d, I64 *state){
  if(!p || d<=0 || !state) return 0;
  F64 r=Uniform01(state); F64 cum=0; I64 i; for(i=0;i<d;i++){ cum+=p[i]; if(r<cum) return i; } return d-1;
}

class AliasTable { I64 d; F64 *prob; I64 *alias; };
AliasTable *AliasBuild(F64 *p, I64 d){
  if(!p || d<=0) return NULL;
  AliasTable *a=MAlloc(sizeof(AliasTable)); if(!a) return NULL;
  a->d=d; a->prob=MAlloc(d*sizeof(F64)); a->alias=MAlloc(d*sizeof(I64));
  if(!a->prob||!a->alias){ if(a->prob) Free(a->prob); if(a->alias) Free(a->alias); Free(a); return NULL; }
  I64 i; for(i=0;i<d;i++){ a->prob[i]=1.0; a->alias[i]=i; }
  return a;
}
U0 AliasFree(AliasTable *a){ if(a){ if(a->prob) Free(a->prob); if(a->alias) Free(a->alias); Free(a); } }
I64 AliasDraw(AliasTable *a, I64 *state){
  if(!a || !state) return 0;
  F64 r=Uniform01(state)*a->d; I64 i=ToI64(r); if(i<0) i=0; if(i>=a->d) i=a->d-1;
  F64 y=r - i; if(y < a->prob[i]) return i; else return a->alias[i];
}
I64 BitSample(I64 *state){ if(!state) return 0; I64 x=Xorshift64Star(state); return x & 1; }

U0 SeedDump(QuditSpec *spec){
  if(!spec) return;
  I64 seal=ProvenanceSeal(spec->n,spec->d,spec->backend,spec->chi,spec->seed,spec->provenance);
  "Seed=%d Seal=%x\n",spec->seed,seal; // enhancement 84 do not print amplitudes
}

Bool RefuseUnseeded(QuditSpec *spec, Bool flag){
  if(!spec) return TRUE;
  if(flag && spec->seed==0) return TRUE;
  return FALSE;
}

#endif // CM_QSR_SAMPLE_1_HC
