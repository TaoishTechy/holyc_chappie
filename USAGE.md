# USAGE — cm-patch-006

## Requirements

- TempleOS / ShrineOS HolyC or host C harness (optional, not substitute per 95)
- 64-bit, `sizeof(Complex128)==16`, `sizeof(I64)==8`
- RAM arg passed, not hard-coded

## Include once, init explicit

`CM_QSR.HC` must not run at include (15). One init function (89).

```c
#include "src/CM_QSR_Guards.HC"
#include "src/CM_QSR_Arena.HC"
#include "src/CM_QSR_Num.HC"
#include "src/CM_QSR_Weyl.HC"
#include "src/CM_QSR_SV.HC"
#include "src/CM_QSR_Card.HC"
#include "src/CM_QSR_K.HC"
#include "src/CM_QSR_MPS.HC"
#include "src/CM_QSR_Open.HC"
#include "src/CM_QSR_Stab.HC"
#include "src/CM_QSR_Sparse.HC"
#include "src/CM_QSR_Cipher.HC"
#include "src/CM_QSR_Sample.HC"
#include "src/CM_QSR_Test.HC"
#include "src/CM_QSR.HC"

CM_QSR_Init; // prints capacity card, registry, checks sizeof(Complex128)==16
```

Or master include (order dependency fixed with guards per 13):

```c
#include "src/CM_QSR.HC"
CM_QSR_Init;
```

## Capacity card (61-72 fixed)

```
=== CM-QSR CAPACITY CARD cm-patch-006 (SIM, exact=yes, GiB=2^30) ===
RAM constants: 16 GiB=2^34, 32 GiB=2^35, 64 GiB=2^36 bytes
--- 32 GiB (2^35) ---
  SV d=2 n_max=31 M_ok=34359738368 bytes 32.00 GiB M_next=68719476736 bytes 64.00 GiB overflow justifies cap
  SV d=3 n_max=19 M_ok=23245229334 bytes 21.64 GiB M_next=69735688002 bytes 64.94 GiB overflow justifies cap
  SV d=4 n_max=15 M_ok=17179869184 bytes 16.00 GiB M_next=68719476736 bytes 64.00 GiB overflow justifies cap
  SV d=5 n_max=13 M_ok=19531250000 bytes 18.18 GiB M_next=...
  SV d=6 n_max=12 M_ok=...
  MPS n=100 d=2 chi_theory=3276 (1.99 GiB) chi_work=2316 (1.99 GiB peak with workspace)
  Rho d=2 cap n=15 M_ok=16.00 GiB M_next=256.00 GiB density
  Liouv d=2 cap n=7 M_ok=16.00 GiB M_next=256.00 GiB (n=8 is 64 GiB edge)
  420e6 effective qudits = DELETED
```

Per 3-4: `GiBOf` only, prints accepted+rejected. Per 5: split theory/work chi. Per 8-9: 420e6 branch-free, hash `FNV-1a64`.

## Release gate (92-93 fixed)

`ReleaseGate` is only ship signal (92). Skipped backend fixtures reported SKIPPED not PASSED (93, 141).

```c
Bool ok = ReleaseGate;
// === RELEASE GATE cm-patch-006 ===
// Test_ShiftDirection 1 — |0⟩→|1⟩ first fixture (137)
// Test_Xd_I 1
// Test_Zd_I 1
// Test_XZ 1 — XZ=ωZX at d=3
// Test_F4 1 — F^4=I d=2,3,4
// Test_AllocNorm 1
// Test_OverlapPhase 1 — +i and -i both
// Test_CardNumbers 1 — 31,19,15
// Test_KillClosed 1 — branch-free no long loop
// Test_MpsAgrees SKIPPED (ValidSpec false for MPS until fixtures pass) — not PASSED
// Test_SealStable 1
// Test_OOM 1 — graceful NULL
// Test_XZ_d5 1 — d>4 commutator
// Pass 13/13 (1 SKIPPED reported)
```

Until that drop, MPS, stabilizer, sparse stay enum-only (E-45, G-62).

## Family B Weyl usage

```c
QuditSpec spec; spec.n=2; spec.d=3; spec.backend=0; spec.chi=0; spec.seed=1; spec.provenance="test";
Complex128 *psi = AllocState(&spec, RAM_32GiB); // ram arg, |0⟩ zeros rest (33-34)
ApplyShift(psi,2,3,0); // |0⟩→|1⟩ forward (17-18)
Bool ok = (psi[1].re>0.9); // fixture

ApplyClock(psi,2,3,1); // Z
// X^d=I, Z^d=I fixtures present (19)
// XZ=ωZX fixture present at d=2,3,4 (20)
// phase table built once per d, not Cos/Sin per amplitude (21)
// out-of-range site refused before stride power (22)
// X^k as k mod d rotations (23)
// displacement integer cocycle (24)
// Fourier site F†F=I (25)
// O(1) extra one register not shadow state (26-27)
// null-check psi first (28)
// no wrap negative site (29)
```

## Family C statevector usage

```c
QuditSpec spec; spec.n=2; spec.d=2; spec.backend=0; spec.chi=0; spec.seed=0; spec.provenance="test";
if(!ValidSpec(&spec)) return; // rejects n>=64 (42), rejects unknown backends (43), requires provenance (44)
Complex128 *psi = AllocState(&spec, RAM_32GiB); // NULL on failure (35)
F64 n2 = Norm2(psi,4); // Kahan compensated
Complex128 ov = Overlap(a,b,dim); // correct sign conj(a)*b (36)
F64 fid = Fidelity(a,b,dim); // derived from overlap (37), orthogonal 0, global phase 1
if(!Renorm(psi,dim)) {} // zero refuse (39)
FreeState(psi); psi=NULL; // null the caller (40)
```

## MPS only as refused backend until fixtures pass (45-56)

```c
if(!ValidSpec(&spec)) {} // false for MPS per 45
MpsChain *c = MpsAlloc(n,d,chi,RAM_32GiB); // per-site chiL,d,chiR (46), tensor formula bytes (47), unwind partial allocate (53)
MpsApplyOneSite(c,site,op); // bond-1 product state first (48)
Complex128 *sv = MpsToSV(c,RAM_32GiB); // cross-check SV n<=6 d=2 (49), only if MemFits (54)
F64 discarded; MpsSvdTruncate(c,ChiMax(ram,n,d),1e-12,&discarded); // 2×2 SVD before two-site (50), report discarded weight (51), cap bond at ChiMax (52)
```

## Open, stabilizer, sparse (57-76)

```c
Complex128 *L = NoSuperoperatorAlloc(d,n,ram); // refused (57)
Bool ok = KrausTP(ops,k,d); // one-site completeness only (58)
F64 p; ApplyKrausSample(psi,dim,branch,&p); // trajectory prob (59)
PartialTraceSite(psi,n,d,site,rho_out); // product fixture (60)
F64 pur = Purity(rho,d); // =1 pure (61)
if(StabRefuseQudit(d)) {} // refuses d!=2 with registry line (62)
if(!StabAllowed(d)) {} // do not enable until HZH=X passes (63)
StabPhaseTrack(t,gen,p); // phase 2 bits (64)
StabMeasure(t,q,seed); // Z on |0⟩ returns 0 (65)
StabMem(n); // bytes not effective qudits (66)
SparseGet(m,idx); // missing key 0 (67)
SparseApplyShift(m,site); // preserves occupancy (68)
SparsePrune(m,eps); // reports weight (69)
if(SparseRefuseDense(m)) {} // >d^n/4 (70)
SparseToSV(m,ram); // cross-check 3-occupied vs SV (71), no silent dense promotion (72)
```

## Seals, sampling (77-88)

```c
I64 h = Fnv1a64("cm-qsr"); // FNV-1a64 first (77)
I64 s = Xorshift64Star(&state); // KAT seed 1 (78)
if(!AffineDigit(x,a,b,d,&out)) {} // refuses non-coprime (79)
I64 seal = ProvenanceSeal(n,d,backend,chi,seed,tag); // covers n,d,backend,chi,seed,tag (80)
I64 idx = BornSample(psi,dim,&state); // 0 on |0⟩ (81)
ShotLoop(psi,n,d,shots,&spec,hist); // same seed same shot string (82)
HistogramAdd(hist,idx); // sums to shots (83)
SeedDump(&spec); // no amplitude printed (84)
Gcd(12,18); ModInv(a,d); // fixtures before cipher inverse (85)
```

## ShrineOS and SpiderChappie (89-91)

```c
#include "examples/ShrineOS_Boot.HC"
ShrineOS_Boot; // VFS mount block size check

#include "examples/SpiderChappie.HC"
Chappie_Boot; // dynamic allocation, Yield() not busy-wait, lock-free ring buffer future
loop {
  Chappie_Tick;
  Yield(); // cooperative
  if(chappie_tick%100==0) checkpoint to .RED/.ISO
}
```

## CI (94-95)

Extractor must emit text — automatic fail if binary-marked. Host C harness later if desired, not substitute for HolyC fixture.

```bash
python3 tools/extract_audit.py # TEXT OK
python3 tools/lint_hc.py src/*.HC # no QPU, no 1e9, no effective qudit
bash ci/run_qemu.sh # QEMU headless ShrineOS, ReleaseGate
gcc tests/host_test.c -o host_test -lm && ./host_test # optional
```

## Honesty (96)

No QPU symbol, no effective-qudit counter, no decimal-GB print anywhere in fourteen files. Checked by `HonestUnit()`.
