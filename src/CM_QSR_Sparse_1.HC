#ifndef CM_QSR_SPARSE_1_HC
#define CM_QSR_SPARSE_1_HC
// cm-patch-006 - header guard defect 3
#assert sizeof(I64)==8 // defect 4
#assert sizeof(U8)==1
#define CM_QSR_ARCH_X86_64 1 // defect 5
// CM_QSR_Sparse.HC - Family H 85-96 - sparse map - cm-patch-005
// enhancements 67-72,76

class Complex128 { F64 re; F64 im; };
I64 PowInt(I64 b, I64 e);
Bool DimFits(I64 d, I64 n);
Bool MemFits(I64 d, I64 n, F64 ram);
F64 GiBOf(F64 bytes);

class SparseNode { I64 idx; Complex128 amp; SparseNode *next; };
class SparseMap { I64 n; I64 d; I64 count; SparseNode *head; };

SparseMap *SparseAlloc(I64 n, I64 d){
  if(n<=0 || d<2) return NULL;
  SparseMap *m=MAlloc(sizeof(SparseMap));
  if(!m) return NULL;
  m->n=n; m->d=d; m->count=0; m->head=NULL;
  return m;
}
U0 SparseFree(SparseMap *m){
  if(!m) return;
  SparseNode *cur=m->head; while(cur){ SparseNode *nxt=cur->next; Free(cur); cur=nxt; }
  Free(m);
}
Bool SparseSet(SparseMap *m, I64 idx, Complex128 amp){
  if(!m) return FALSE;
  SparseNode *cur=m->head;
  while(cur){ if(cur->idx==idx){ cur->amp=amp; return TRUE; } cur=cur->next; }
  SparseNode *node=MAlloc(sizeof(SparseNode));
  if(!node) return FALSE;
  node->idx=idx; node->amp=amp; node->next=m->head; m->head=node; m->count++;
  return TRUE;
}
Complex128 SparseGet(SparseMap *m, I64 idx){
  Complex128 zero; zero.re=0; zero.im=0;
  if(!m) return zero;
  SparseNode *cur=m->head;
  while(cur){ if(cur->idx==idx) return cur->amp; cur=cur->next; }
  return zero; // enhancement 67 missing is 0
}
I64 SiteStride(I64 d, I64 i){ if(i<0) return 0; return PowInt(d,i); }
Complex128 Omega(I64 d, I64 j);
Bool SparseApplyClock(SparseMap *m, I64 site){
  if(!m || site<0 || site>=m->n) return FALSE;
  I64 stride=SiteStride(m->d, site); if(stride==0) return FALSE;
  SparseNode *cur=m->head;
  while(cur){
    I64 ji=(cur->idx/stride)%m->d;
    Complex128 w=Omega(m->d, ji);
    F64 re=cur->amp.re*w.re - cur->amp.im*w.im;
    F64 im=cur->amp.re*w.im + cur->amp.im*w.re;
    cur->amp.re=re; cur->amp.im=im;
    cur=cur->next;
  }
  return TRUE; // enhancement 71 cross-check 3-occupied vs SV
}
Bool SparseApplyShift(SparseMap *m, I64 site){
  if(!m || site<0 || site>=m->n) return FALSE;
  I64 stride=SiteStride(m->d, site); if(stride==0) return FALSE;
  SparseNode *cur=m->head;
  while(cur){
    I64 ji=(cur->idx/stride)%m->d;
    I64 base=cur->idx - ji*stride;
    I64 jnext=(ji+1)%m->d;
    cur->idx=base + jnext*stride;
    cur=cur->next;
  }
  return TRUE; // enhancement 68 shift preserves occupancy
}
F64 SparsePrune(SparseMap *m, F64 eps){
  if(!m) return 0;
  F64 dropped=0;
  SparseNode *prev=NULL, *cur=m->head;
  while(cur){
    F64 norm=cur->amp.re*cur->amp.re + cur->amp.im*cur->amp.im;
    if(norm < eps*eps){
      dropped+=norm; // enhancement 69 report weight
      SparseNode *del=cur;
      if(prev) prev->next=cur->next; else m->head=cur->next;
      cur=cur->next; Free(del); m->count--;
    } else { prev=cur; cur=cur->next; }
  }
  return dropped;
}
Complex128 *SparseToSV(SparseMap *m, F64 ram){
  if(!m) return NULL;
  if(!DimFits(m->d,m->n)) return NULL;
  if(!MemFits(m->d,m->n,ram)) return NULL;
  I64 dim=PowInt(m->d,m->n);
  Complex128 *psi=MAlloc(dim*sizeof(Complex128));
  if(!psi) return NULL;
  MemSet(psi,0,dim*sizeof(Complex128));
  SparseNode *cur=m->head;
  while(cur){ if(cur->idx>=0 && cur->idx<dim) psi[cur->idx]=cur->amp; cur=cur->next; }
  return psi;
}
SparseMap *SparseAdd(SparseMap *a, SparseMap *b){
  if(!a || !b) return NULL;
  if(a->n!=b->n || a->d!=b->d) return NULL;
  SparseMap *c=SparseAlloc(a->n,a->d); if(!c) return NULL;
  SparseNode *cur=a->head; while(cur){ SparseSet(c,cur->idx,cur->amp); cur=cur->next; }
  cur=b->head; while(cur){
    Complex128 existing=SparseGet(c,cur->idx);
    Complex128 sum; sum.re=existing.re+cur->amp.re; sum.im=existing.im+cur->amp.im;
    SparseSet(c,cur->idx,sum); cur=cur->next;
  }
  return c;
}
F64 SparseNorm(SparseMap *m){
  if(!m) return 0;
  F64 s=0; SparseNode *cur=m->head; while(cur){ s+=cur->amp.re*cur->amp.re + cur->amp.im*cur->amp.im; cur=cur->next; }
  return s;
}
I64 SparseOccupancy(SparseMap *m){ if(!m) return 0; return m->count; }
Bool SparseRefuseDense(SparseMap *m){
  if(!m) return TRUE;
  I64 dim=PowInt(m->d,m->n); if(dim==0) return TRUE;
  if(m->count > dim/4) return TRUE; // enhancement 70
  return FALSE;
}

#endif // CM_QSR_SPARSE_1_HC
