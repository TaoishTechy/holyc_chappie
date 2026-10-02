#ifndef CM_QSR_CARD_HC
#define CM_QSR_CARD_HC
// cm-patch-006 - header guard defect 3
#assert sizeof(I64)==8 // defect 4
#assert sizeof(U8)==1
#define CM_QSR_ARCH_X86_64 1 // defect 5
// CM_QSR_Card.HC - Family D 37-48 - capacity card and negative registry - cm-patch-005
// enhancements 1-16, 6,7,8,9,10,11,12

#define RAM_16GiB 17179869184.0 // 2^34
#define RAM_32GiB 34359738368.0 // 2^35
#define RAM_64GiB 68719476736.0 // 2^36
#define GiB 1073741824.0

I64 NMax_SV(F64 ram, I64 d);
I64 NMax_SVEx(F64 ram, I64 d, F64 *out_next);
F64 Pow_I64(F64 base, I64 exp);
Bool MemFits(I64 d, I64 n, F64 ram);
I64 ChiMax(F64 ram, I64 n, I64 d);
I64 ChiMaxWork(F64 ram, I64 n, I64 d);
I64 RhoCap(F64 ram, I64 d);
I64 LiouvCap(F64 ram, I64 d);
Bool IsImpossible(I64 d, I64 n);
F64 GiBOf(F64 bytes);
F64 SV_Mem(I64 d, I64 n);

// Registry buffer 4096, cap and drop oldest enhancement 10
#define REG_SIZE 4096
U8 registry[REG_SIZE];
I64 reg_len=0;

// 45. ClaimHash - FNV-1a64, enhancement 9 hash rejected sentence
I64 ClaimHash(U8 *s){
  U64 hash=14695981039346656037ULL;
  U64 prime=1099511628211ULL;
  if(!s) return hash;
  I64 i; for(i=0; s[i]!=0; i++){ hash ^= s[i]; hash *= prime; }
  return hash;
}

// 43. RegistryReject - append, cap buffer, drop oldest line
Bool RegistryReject(U8 *id, U8 *reason){
  if(!id || !reason) return FALSE;
  U8 line[256];
  StrPrint(line, "%s: %s [%x]\n", id, reason, ClaimHash(reason));
  I64 l=StrLen(line);
  if(l>=REG_SIZE) return FALSE;
  if(reg_len + l >= REG_SIZE-1){
    // drop oldest line: find first newline and shift
    I64 first=0; while(first<reg_len && registry[first]!='\n') first++;
    if(first<reg_len) first++; // include newline
    I64 remain=reg_len-first;
    MemCpy(registry, registry+first, remain);
    reg_len=remain;
  }
  if(reg_len + l >= REG_SIZE-1) return FALSE;
  MemCpy(registry+reg_len, line, l);
  reg_len+=l;
  registry[reg_len]=0;
  return TRUE;
}

// 44. RegistryDump
U0 RegistryDump(){
  if(reg_len==0){ "Registry empty - no QPU claims\n"; return; }
  "%s", registry;
}

// Card line helpers - enhancement 3,4: GiBOf only, both accepted and rejected

U0 CardLineSV(F64 ram, I64 d){
  if(d<2) return;
  I64 nmax=NMax_SV(ram,d);
  F64 mem_ok=Pow_I64(d,nmax)*16.0;
  F64 mem_next=Pow_I64(d,nmax+1)*16.0;
  // enhancement 3: GiBOf only, no 1e9
  // enhancement 4: both accepted and rejected
  "  SV d=%d n_max=%d M_ok=%.2f GiB M_next=%.2f GiB %s\n",
    d,nmax,GiBOf(mem_ok),GiBOf(mem_next), (mem_next>ram)?"overflow justifies cap":"";
}

U0 CardLineMPS(F64 ram, I64 n, I64 d){
  I64 chi=ChiMax(ram,n,d);
  I64 chi_w=ChiMaxWork(ram,n,d);
  // enhancement 5: split theory and workspace
  "  MPS n=%d d=%d chi_theory=%d chi_work=%d (work=theory/sqrt2 heuristic)\n",n,d,chi,chi_w;
}

U0 CardLineRho(F64 ram, I64 d){
  I64 cap=RhoCap(ram,d);
  F64 mem_ok=Pow_I64(d,2*cap)*16.0;
  F64 mem_next=Pow_I64(d,2*(cap+1))*16.0;
  "  Rho d=%d cap n=%d M_ok=%.2f GiB M_next=%.2f GiB density operator\n",d,cap,GiBOf(mem_ok),GiBOf(mem_next);
}

U0 CardLineLiouv(F64 ram, I64 d){
  I64 cap=LiouvCap(ram,d);
  F64 mem_ok=Pow_I64(d,4*cap)*16.0;
  F64 mem_next=Pow_I64(d,4*(cap+1))*16.0;
  // enhancement 7: n=8 only as 64 GiB Liouvillian edge
  "  Liouv d=%d cap n=%d M_ok=%.2f GiB M_next=%.2f GiB liouvillian (n=8 is 64 GiB edge)\n",d,cap,GiBOf(mem_ok),GiBOf(mem_next);
}

// 37. CapacityCard - 16,32,64 GiB, d=2,3,4 plus d=5,6 enhancement 11, header names 2^34,35,36 enhancement 12
U0 CapacityCard(){
  "=== CM-QSR CAPACITY CARD cm-patch-005 (SIM, exact=yes, GiB=2^30) ===\n";
  "RAM constants: 16 GiB=2^34, 32 GiB=2^35, 64 GiB=2^36 bytes\n";
  F64 rams[3]={RAM_16GiB,RAM_32GiB,RAM_64GiB};
  U8 *labels[3]={"16 GiB (2^34)","32 GiB (2^35)","64 GiB (2^36)"};
  I64 ri,d;
  for(ri=0;ri<3;ri++){
    "--- %s ---\n",labels[ri];
    for(d=2; d<=6; d++) CardLineSV(rams[ri],d); // 11 includes 5,6
    CardLineMPS(rams[ri],100,2);
    CardLineRho(rams[ri],2);
    CardLineRho(rams[ri],4);
    CardLineLiouv(rams[ri],2);
  }
  "  420e6 effective qudits = DELETED - violates M=16 d^N\n";
  // enhancement 6: delete any N<=8 density sentence - we only state density cap 15 and liouv cap 7
}

// 42. KillTest_420M - closed-form deletion, branch-free, enhancement 8
Bool KillTest_420M(){
  // closed form: IsImpossible(2,420000000) true without loop
  if(IsImpossible(2,420000000)){
    "NEGATIVE REGISTRY W37-W48: 420e6 effective qudits FAILS M=16 d^N - DELETED\n";
    "Proof: 16*2^64 = 256 EiB = %.2f GiB >64 GiB card. 420e6>>64, no loop, hash %x\n",
      GiBOf(16.0*Pow_I64(2,64)), ClaimHash("420e6 effective qudits");
    RegistryReject("W37","420e6 effective qudits - violates M=16 d^N");
    return TRUE;
  }
  return FALSE;
}

// 46. CardEquals
Bool CardEquals(F64 ram1, F64 ram2, I64 d){
  return NMax_SV(ram1,d)==NMax_SV(ram2,d);
}

// 47. BoundTag
#define BOUND_SV 0
#define BOUND_MPS 1
#define BOUND_RHO 2
#define BOUND_LIOUV 3
U8 *BoundTagName(I64 tag){
  if(tag==BOUND_SV) return "SV";
  if(tag==BOUND_MPS) return "MPS";
  if(tag==BOUND_RHO) return "RHO";
  if(tag==BOUND_LIOUV) return "LIOUV";
  return "UNKNOWN";
}

// 48. HonestUnit - refuse any print path that divides by 1e9
Bool HonestUnit(U8 *src){
  if(!src) return TRUE;
  I64 i, len=StrLen(src);
  for(i=0;i+2<len;i++){
    if(src[i]=='1' && src[i+1]=='e' && src[i+2]=='9') return FALSE;
  }
  return TRUE;
}

#endif // CM_QSR_CARD_HC
