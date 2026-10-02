#ifndef CM_QSR_NUM_HC
#define CM_QSR_NUM_HC
// cm-patch-006 - header guard defect 3
#assert sizeof(I64)==8 // defect 4
#assert sizeof(U8)==1
#define CM_QSR_ARCH_X86_64 1 // defect 5
// CM_QSR_Num.HC - Family A 1-12 - exact arithmetic - cm-patch-005
// Compile first. No calls before definition. Layer SIM only.
// RAM constants: 16 GiB = 2^34, 32 GiB = 2^35, 64 GiB = 2^36 bytes

#define RAM_16GiB 17179869184.0  // 2^34
#define RAM_32GiB 34359738368.0  // 2^35
#define RAM_64GiB 68719476736.0  // 2^36
#define GiB 1073741824.0
#define I64_MAX 9223372036854775807
#define PI 3.141592653589793

// 1. Pow_I64 - binary exponentiation, F64 base, exact through 2^53 for integer bases
F64 Pow_I64(F64 base, I64 exp){
  F64 r=1.0;
  while(exp>0){
    if(exp&1) r*=base;
    base*=base;
    exp>>=1;
  }
  return r;
}

// 3. DimFits - d^n fits in signed 63 bits, used before PowInt
Bool DimFits(I64 d, I64 n){
  if(d<2 || n<1) return FALSE;
  if(n>=63) return FALSE;
  I64 r=1;
  I64 i;
  for(i=0;i<n;i++){
    if(r > I64_MAX / d) return FALSE;
    r*=d;
  }
  return TRUE;
}

// 2. PowInt - integer power, refuses rather than wrapping, calls DimFits at top
I64 PowInt(I64 b, I64 e){
  if(e<0) return 0;
  if(b<2) return 0;
  if(!DimFits(b,e)) return 0; // enhancement 1: call DimFits at top
  I64 r=1;
  while(e>0){
    if(e&1){
      if(r > I64_MAX / b) return 0;
      r*=b;
    }
    e>>=1;
    if(e){
      if(b > I64_MAX / b) return 0;
      b*=b;
    }
  }
  return r;
}

// 4. MemFits - 16*d^n <= ram without forming d^n past ram ceiling
Bool MemFits(I64 d, I64 n, F64 ram){
  if(d<2 || n<1 || n>=64) return FALSE;
  if(ram<=16.0) return FALSE; // enhancement 14: refuse ram<=16
  F64 mem=16.0;
  I64 i;
  for(i=0;i<n;i++){
    mem*=d;
    if(mem>ram) return FALSE;
    if(mem>1e30) return FALSE;
  }
  return mem<=ram;
}

// 5. NMax_SV - largest n with 16*d^n <= ram, refuses d<2 and ram<=16
// enhancement 13,14: refuse d<2, ram<=16
I64 NMax_SV(F64 ram, I64 d){
  if(d<2) return 0;
  if(ram<=16.0) return 0;
  I64 n=0;
  F64 mem=16.0;
  while(mem * d <= ram){
    mem*=d;
    n++;
    if(n>=64) break;
  }
  return n;
}

// 2b. NMax_SVEx - enhancement 2: return accepted n and rejected next memory by out-params
I64 NMax_SVEx(F64 ram, I64 d, F64 *out_next_mem){
  I64 n=NMax_SV(ram,d);
  if(out_next_mem) *out_next_mem=16.0*Pow_I64(d,n+1);
  return n;
}

// 6. NextSiteMem - 16*d^{n+1}, caller must have MemFits(d,n)
F64 NextSiteMem(I64 d, I64 n){
  return 16.0 * Pow_I64(d, n+1);
}

// 7. ChiMax - floor(sqrt(ram/(16 n d))), floor documented as ToI64 of nonnegative sqrt
// enhancement 16: ToI64 of nonnegative sqrt
I64 ChiMax(F64 ram, I64 n, I64 d){
  if(n<=0 || d<2) return 0;
  if(ram!=ram) return 0; // NaN guard enhancement 15
  F64 denom=16.0*n*d;
  if(denom!=denom) return 0;
  F64 v=ram/denom;
  if(v!=v) return 0; // non-finite
  if(v<=0) return 0;
  F64 s=Sqrt(v); // s >=0
  if(s!=s) return 0; // NaN guard
  return ToI64(s); // floor via ToI64
}

// 8. ChiMaxWork - same with 2x scratch, divide by sqrt2 before floor, heuristic labeled
I64 ChiMaxWork(F64 ram, I64 n, I64 d){
  // heuristic: workspace ~ doubles peak, effective chi ~= chi/sqrt(2)
  // enhancement 5: split theory and workspace
  F64 chi=ChiMax(ram,n,d);
  return ToI64(chi / 1.4142135623730951);
}

// 9. RhoCap - largest n with 16*d^{2n} <= ram
I64 RhoCap(F64 ram, I64 d){
  if(d<2) return 0;
  I64 n=0;
  while(MemFits(d, 2*(n+1), ram)) n++;
  return n;
}

// 10. LiouvCap - largest n with 16*d^{4n} <= ram
I64 LiouvCap(F64 ram, I64 d){
  if(d<2) return 0;
  I64 n=0;
  while(MemFits(d, 4*(n+1), ram)) n++;
  return n;
}

// 11. IsImpossible - closed form, n>=64 or mem above 1 PiB, branch-free, no loop over claim
// enhancement 8: keep 420e6 test branch-free
Bool IsImpossible(I64 d, I64 n){
  // n>=64 => 16*2^64 = 256 EiB, impossible
  if(n>=64) return TRUE;
  if(d<2) return TRUE;
  // quick closed form: d=2 n>=46 => >1 PiB, d>=3 n>=30 => >1 PiB
  if(d==2 && n>=46) return TRUE;
  if(d>=3 && n>=30) return TRUE;
  return FALSE;
}

// 12. GiBOf - bytes / 1073741824.0, only byte formatter, enhancement 3
F64 GiBOf(F64 bytes){
  return bytes / 1073741824.0;
}

#endif // CM_QSR_NUM_HC
