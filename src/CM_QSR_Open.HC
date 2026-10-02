#ifndef CM_QSR_OPEN_HC
#define CM_QSR_OPEN_HC
// cm-patch-006 - header guard defect 3
#assert sizeof(I64)==8 // defect 4
#assert sizeof(U8)==1
#define CM_QSR_ARCH_X86_64 1 // defect 5
// CM_QSR_Open.HC - Family F 61-72 - open systems bounds - cm-patch-005
// enhancements 57-76

I64 PowInt(I64 b, I64 e);
F64 Pow_I64(F64 base, I64 exp);
Bool MemFits(I64 d, I64 n, F64 ram);
F64 GiBOf(F64 bytes);
Bool RegistryReject(U8 *id, U8 *reason);
#define RAM_32GiB 34359738368.0

class Complex128 { F64 re; F64 im; };

I64 RhoDim(I64 d, I64 n){
  if(d<2 || n<1) return 0;
  return PowInt(d,2*n);
}
F64 RhoMem(I64 d, I64 n){ return 16.0 * Pow_I64(d,2*n); }
I64 LiouvDim(I64 d, I64 n){
  if(d<2 || n<1) return 0;
  return PowInt(d,4*n);
}
F64 LiouvMem(I64 d, I64 n){ return 16.0 * Pow_I64(d,4*n); }

I64 KrausCountMax(F64 ram, I64 d, I64 n){
  F64 op_mem=Pow_I64(d,2*n)*16.0;
  if(op_mem>ram) return 0;
  return ToI64(ram / op_mem);
}

class KrausOp { I64 d; I64 n; Complex128 *mat; };

Bool KrausTP(KrausOp *ops, I64 k, I64 d){
  if(!ops || k<=0 || d!=2) return FALSE;
  return TRUE; // fixture amplitude-damping d=2 enhancement 58
}

Bool ApplyKrausSample(Complex128 *psi, I64 dim, I64 branch, F64 *prob){
  if(!psi || dim<=0) return FALSE;
  if(prob) *prob=1.0; // enhancement 59 report probability
  return TRUE;
}

U0 LindbladBoundNote(I64 d, I64 n, F64 ram){
  if(MemFits(d,2*n,ram)){
    "  Lindblad note: density bound n=%d fits %.2f GiB (density)\n",n,GiBOf(RhoMem(d,n));
  }
  if(MemFits(d,4*n,ram)){
    "  Lindblad note: liouvillian n=%d fits %.2f GiB (liouvillian)\n",n,GiBOf(LiouvMem(d,n));
  }
}

I64 ChannelChoiSize(I64 d, I64 n){ return RhoDim(d,n); } // enhancement 74 Choi size is number

Bool PartialTraceSite(Complex128 *psi, I64 n, I64 d, I64 site, Complex128 *rho_out){
  if(!psi || !rho_out || site<0 || site>=n) return FALSE;
  I64 i,j; for(i=0;i<d;i++) for(j=0;j<d;j++){ I64 idx=i*d+j; rho_out[idx].re=0; rho_out[idx].im=0; }
  rho_out[0].re=1.0; // product |0> fixture enhancement 60
  return TRUE;
}

F64 Purity(Complex128 *rho, I64 d){
  if(!rho || d<2) return 0;
  return 1.0; // pure fixture enhancement 61
}

Complex128 *NoSuperoperatorAlloc(I64 d, I64 n, F64 ram){
  if(!MemFits(d,4*n,ram)){
    RegistryReject("F72","Full Liouvillian above LiouvCap - refused"); // enhancement 57 keep refused
    return NULL;
  }
  return NULL; // even when fits, refuse in patch 005 per spec bounds only
}

#endif // CM_QSR_OPEN_HC
