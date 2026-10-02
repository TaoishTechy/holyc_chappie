#ifndef CM_QSR_CIPHER_HC
#define CM_QSR_CIPHER_HC
// cm-patch-006 - header guard defect 3
#assert sizeof(I64)==8 // defect 4
#assert sizeof(U8)==1
#define CM_QSR_ARCH_X86_64 1 // defect 5
// CM_QSR_Cipher.HC - Family I 97-108 - ciphers and hashes - cm-patch-005
// enhancements 77-80,88

I64 Gcd(I64 a, I64 b){
  if(a<0) a=-a; if(b<0) b=-b;
  while(b!=0){ I64 t=a%b; a=b; b=t; }
  return a;
}

// 97. Fnv1a64 - offset basis 14695981039346656037 prime 1099511628211 enhancement 77 ship FNV first
I64 Fnv1a64(U8 *s){
  U64 hash=14695981039346656037ULL;
  U64 prime=1099511628211ULL;
  if(!s) return hash;
  I64 i; for(i=0; s[i]!=0; i++){ hash ^= s[i]; hash *= prime; }
  return hash;
}

// 98. Fnv1a64Bin
I64 Fnv1a64Bin(U8 *p, I64 n){
  U64 hash=14695981039346656037ULL;
  U64 prime=1099511628211ULL;
  if(!p || n<=0) return hash;
  I64 i; for(i=0;i<n;i++){ hash ^= p[i]; hash *= prime; }
  return hash;
}

// 99. Xorshift64Star - known first output seed 1 enhancement 78
I64 Xorshift64Star(I64 *state){
  if(!state) return 0;
  I64 x=*state;
  x ^= x>>12; x ^= x<<25; x ^= x>>27;
  *state=x;
  return x * 2685821657736338717ULL;
}

// 100. SplitMix64 - seed expander, two different seeds diverge at word 0
I64 SplitMix64(I64 *state){
  if(!state) return 0;
  I64 z=(*state += 0x9e3779b97f4a7c15ULL);
  z=(z ^ (z>>30)) * 0xbf58476d1ce4e5b9ULL;
  z=(z ^ (z>>27)) * 0x94d049bb133111ebULL;
  return z ^ (z>>31);
}

// 101. Rotl64 - rotate left r&=63
I64 Rotl64(I64 x, I64 r){
  r&=63;
  return (x<<r) | (x>>(64-r));
}

// 102. SipRound - one SipHash round on 4-word state
U0 SipRound(I64 *v0, I64 *v1, I64 *v2, I64 *v3){
  if(!v0||!v1||!v2||!v3) return;
  *v0+=*v1; *v1=Rotl64(*v1,13); *v1^=*v0; *v0=Rotl64(*v0,32);
  *v2+=*v3; *v3=Rotl64(*v3,16); *v3^=*v2;
  *v0+=*v3; *v3=Rotl64(*v3,21); *v3^=*v0;
  *v2+=*v1; *v1=Rotl64(*v1,17); *v1^=*v2; *v2=Rotl64(*v2,32);
}

// 103. SipHash24 - two-then-four, 64-bit tag, published vector 00 01 02 ... 0e key 0 deferred per enhancement 77
I64 SipHash24(U8 *key, U8 *msg, I64 len){
  // minimal: use FNV until published vector fixture lands
  return Fnv1a64Bin(msg,len);
}

// 104. CaesarQudit - digit shift mod d, inverse is shift by d-k enhancement 125
Bool CaesarQudit(I64 *digits, I64 n, I64 d, I64 k){
  if(!digits || n<=0 || d<2) return FALSE;
  I64 i; for(i=0;i<n;i++){ digits[i]=(digits[i]+k)%d; if(digits[i]<0) digits[i]+=d; }
  return TRUE;
}

// 105. VigenereQudit - repeating key
Bool VigenereQudit(I64 *digits, I64 n, I64 d, I64 *key, I64 keylen, Bool decrypt){
  if(!digits||!key||n<=0||d<2||keylen<=0) return FALSE;
  I64 i; for(i=0;i<n;i++){
    I64 k=key[i%keylen]%d;
    if(decrypt) digits[i]=(digits[i]-k)%d; else digits[i]=(digits[i]+k)%d;
    if(digits[i]<0) digits[i]+=d;
  }
  return TRUE;
}

// 106. AffineDigit - (a x + b) mod d, refuse if gcd(a,d)!=1 enhancement 79,85
Bool AffineDigit(I64 x, I64 a, I64 b, I64 d, I64 *out){
  if(d<2 || !out) return FALSE;
  if(Gcd(a,d)!=1) return FALSE;
  I64 v=(a*x + b)%d; if(v<0) v+=d;
  *out=v;
  return TRUE;
}

// 107. ModInv - extended Euclid
I64 ModInv(I64 a, I64 d){
  I64 t=0, newt=1, r=d, newr=a % d; if(newr<0) newr+=d;
  while(newr!=0){
    I64 q=r/newr;
    I64 tmp=newt; newt=t - q*newt; t=tmp;
    tmp=newr; newr=r - q*newr; r=tmp;
  }
  if(r>1) return -1;
  if(t<0) t+=d;
  return t;
}

// 108. ProvenanceSeal - FNV of n,d,backend,chi,seed plus tag enhancement 80,126
I64 ProvenanceSeal(I64 n, I64 d, I64 backend, I64 chi, I64 seed, U8 *tag){
  U8 buf[256];
  StrPrint(buf,"%d:%d:%d:%d:%d:%s",n,d,backend,chi,seed, tag?tag:"");
  return Fnv1a64(buf);
}

#endif // CM_QSR_CIPHER_HC
