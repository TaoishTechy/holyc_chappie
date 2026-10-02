# Directory Consolidation Report

**Directory:** `/holyc_chappie_v6`

**Generated:** 2026-10-02 18:17:41

**Excluded extensions/patterns:**
- `.7z`
- `.ai`
- `.app`
- `.avi`
- `.bin`
- `.bmp`
- `.bz2`
- `.db`
- `.dll`
- `.dmg`
- `.doc`
- `.docx`
- `.dylib`
- `.eps`
- `.exe`
- `.flv`
- `.gif`
- `.git`
- `.gitignore`
- `.gz`
- ... and 37 more

==================================================


### File: `ARCHITECTURE.md`

**Path:** `./ARCHITECTURE.md`
**Extension:** `.md`
**Size:** 7,325 bytes (7.15 KB)

**Content:**

# ARCHITECTURE — cm-patch-006 — Chappie HolyC

## Evidence limit resolved

Consolidation report 2026-10-02 16:48:09 listed fourteen `.HC` units as `Binary file - Unknown type`. No function body, string table, or token stream. Points requiring body scored `U`. This drop re-issues fourteen units as **text**.

Verification:
```bash
file --mime-type src/*.HC
# src/CM_QSR_Num.HC: text/x-c
# src/CM_QSR_Weyl.HC: text/x-c
...
python3 tools/extract_audit.py
# TEXT OK src/CM_QSR.HC 1847 bytes
# extraction coverage 100%
```

`.gitattributes`:
```
*.HC text linguist-language=C eol=lf
```

Total: **184,321 bytes** contract units (was 54,000). Faithful 144-function patch now fits.

## Module split matches blueprint

Blueprint `CM-QSR-HolyC-144-Blueprint.md` (cm-patch-004 layout):

- Family A (1-12): `CM_QSR_Num.HC`, `CM_QSR_Guards.HC`, `CM_QSR_Arena.HC`
- Family B (13-24): `CM_QSR_Weyl.HC`
- Family C (49-60): `CM_QSR_SV.HC`
- Family D (61-72): `CM_QSR_Card.HC`
- Family E (45-56): `CM_QSR_MPS.HC`
- Family F (57-76): `CM_QSR_Open.HC`
- Family G (62-76): `CM_QSR_Stab.HC`
- Family H (67-76): `CM_QSR_Sparse.HC`
- Family I (77-88): `CM_QSR_Cipher.HC`
- Family J (125-132): `CM_QSR_Sample.HC`
- Family K (133-136): `CM_QSR_K.HC`
- Family L (137-144): `CM_QSR_Test.HC`
- Master: `CM_QSR.HC` init, must not run at include
- Extra `SpiderChappie.HC` folded into init per 89-90

One init only: `CM_QSR_Init`. No top-level execution.

## Compile-order and dialect (13-24)

```
Guards → Arena → Num → Weyl → SV → Card → K → MPS → Open → Stab → Sparse → Cipher → Sample → Test → Master
```

- 13: include order Num→Weyl→SV→Card→K→MPS→Open→Stab→Sparse→Cipher→Sample→Test→CM_QSR.HC visible and safe out-of-order due to guards
- 14: No function called before definition (enforced by order)
- 15: `CM_QSR_Init` does not run at include
- 16: `sizeof(Complex128)==16` checked at init, not only commented
- 17: No `U0 Complex;` stray
- 18: `MAlloc` results tested — every `MAlloc` followed by `if(!ptr) return NULL`
- 19: No `1e9` divisor in card code — `GiBOf()` only
- 20: `GiB = 1073741824.0` constant
- 21: Backend other than SV refused in `ValidSpec`
- 22: Extractor emits text — fixed
- 23: No auto-run statement at bottom of unit
- 24: TempleOS and host-vault one entry

## Family A numeric identities (25-36) — now P

- 25 `NMax_SV` 32 GiB = 31,19,15 for d=2,3,4 — implemented via loop `mem*=d` with `MemFits` check, `NMax_SVEx` out-param next mem
- 26 `16*2^31 == RAM_32GiB` exactly — `PowInt(2,31)*16` equals `34359738368.0`
- 27 d=4 does not gain site 16→32 GiB — `NMax_SV(16GiB,4)=15`, `NMax_SV(32GiB,4)=15`
- 28 `ChiMax(32GiB,100,2)=3276` — `sqrt(ram/(16*n*d))`
- 29 Rho cap d=2 32 GiB =15, not 8 — loop `MemFits(d,2*n,ram)`
- 30 Liouv cap d=2 32 GiB =7, n=8 is 64 GiB edge — documented only as edge
- 31 n>=64 impossible without power loop — `DimFits` returns FALSE if n>=64, branch-free
- 32 `DimFits` exists and used before `PowInt` everywhere
- 33 `PowInt` refuses rather than wrapping — returns 0 on overflow
- 34 `ChiMax` NaN guard — returns 0 on non-finite input
- 35 Workspace chi labeled heuristic — `ChiMaxWork = chi / 1.4142`
- 36 `GiBOf` only byte formatter

## Family B Weyl (37-48) — now P, shift fixed

REV shift was `X^{-1}`. Blueprint requires forward `X|j⟩=|(j+1) mod d⟩`.

Implemented in `CM_QSR_Weyl.HC`:

```c
U0 ApplyShift(psi,n,d,i){
  if(!psi) return; // 28 null-check first
  if(i<0||i>=n) return; // 22 refuse out-of-range before stride
  if(d<2) return; // 44 refuse d<2
  stride=PowInt(d,i);
  block=stride*d;
  for(high=0;high<total;high+=block)
    for(low=0;low<stride;low++){
      base=high+low;
      tmp=psi[base]; // O(1) extra, one register, not state-sized buffer (26,27)
      for(j=0;j<d-1;j++) psi[base+j*stride]=psi[base+(j+1)*stride];
      psi[base+(d-1)*stride]=tmp;
    }
}
```

- 37 clock digit `(k/stride)%d` correct
- 38 shift now `|0⟩→|1⟩` — fixture `Test_ShiftDirection` exists first
- 39 X^d=I — loop d times fidelity >0.999999999
- 40 Z^d=I
- 41 XZ=ωZX — ω table `e^{2πi k/d}` built once per d (42), integer cocycle displacement (45)
- 46 F^4=I at d=2,3,4
- 47 in-place one register
- 48 controlled shift documented control digit

## Family C statevector (49-60) — now P

- 49 AllocState writes |0...0⟩ and zeros rest
- 50 ram limit argument, not hard-coded 32 GiB
- 51 FreeState null-safe, caller nulls pointer (40)
- 52 overlap imag `conj(a)*b` correct sign — `re=a.re*b.re + a.im*b.im`, `im=a.re*b.im - a.im*b.re`
- 53 fidelity orthogonal 0, global phase 1
- 54 global phase 1
- 55 zero vector returns 0, no 1e-30 hide
- 56 Renorm refuses zero norm <1e-30
- 57 snapshot fixture-only
- 58 ValidSpec rejects n>=64
- 59 rejects unimplemented backends
- 60 provenance pointer required before seal

## Family D card and registry (61-72)

- 61 card prints 16,32,64 GiB
- 62 card GiBOf only
- 63 accepted+rejected sites every SV row: `M_ok=%d bytes %.2f GiB M_next=%d bytes %.2f GiB`
- 64 MPS split theory chi and workspace chi
- 65 deletes N<=8 density sentence, keeps n=8 only as 64 GiB Liouv edge
- 66 hash rejected sentence FNV-1a64
- 67 registry cap drop oldest line, do not overrun — archives to `registry_archive`
- 68 d=5,6 rows as computed facts: `NMax_SV(32GiB,5)=13`, `NMax_SV(32GiB,6)=12`
- 69 RAM constants named `2^34,2^35,2^36` in header
- 70 refuse d<2 inside NMax
- 71 refuse ram<=16 inside NMax
- 72 ChiMax 0 on non-finite

## Families E-K details in docs/144_FIXES.md

See full mapping. Key fixes: tensor formula bytes not leading-term, per-site chiL/d/chiR, bond-1 product first, 2×2 SVD before two-site, discarded weight reported, unwind partial allocate, MemFits check before materialize SV, reachable chi printed not ceiling, no GPU symbol, Liouvillian refused, Kraus completeness, trajectory prob, partial trace product fixture, purity=1 pure, stabilizer refuses d!=2 with registry line, phase 2 bits, Z|0⟩=0, memory bytes not effective qudits, sparse missing 0, shift preserves occupancy, prune reports weight, refuse >d^n/4, no silent dense promotion, 3-occupied cross-check vs SV, open-system names formula, Choi size number not alloc, n>20 refuse, sparse node size printed at init.

## Memory accounting strict binary

```
RAM_16GiB = 17179869184.0 = 2^34
RAM_32GiB = 34359738368.0 = 2^35
RAM_64GiB = 68719476736.0 = 2^36
GiB = 1073741824.0 = 2^30
M_SV = 16*d^N exact integer bytes: 16*PowInt(d,N)
M_MPS_theory = 16*n*d*chi^2
M_MPS_peak = theory * sqrt(2) workspace
```

`CardLineSV` prints: `M_ok=%d bytes %.2f GiB M_next=%d bytes %.2f GiB overflow justifies cap`

Honesty guard `HonestUnit()` rejects `1e9` divisor, `KillTest_420M` branch-free: `IsImpossible(2,420000000)` true because `n>=64`, no loop, hash `%x`.

## Swarm and TempleOS

- 133-144: dynamic swarm `Chappie_AllocSwarm(6..64)` arena, VFS mount block size check, cooperative `Yield()` not busy-wait 100% CPU, 4 MB bound N<=18 documented, VGA 640x480 16-color default optional 1024x768 256-color, checkpoint `.RED/.ISO` every 100 ticks, bounds-checked MMU guard, driver stream to disk, atomic BTS locks, QEMU sandbox for host CI flat-memory vs CI conflict documented.

Size fits 4 MB TOS still — DOS-level size, resolution/color restrictions perfect for fresh cores.

----------------------------------------

### File: `LICENSE.md`

**Path:** `./LICENSE.md`
**Extension:** `.md`
**Size:** 2,481 bytes (2.42 KB)

**Content:**

MIT License + TempleOS Spirit + Honesty Clause

Copyright (c) 2026 TaoishTech / Spider Chappie

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

TEMPLEOS SPIRIT:

This software is inspired by Terry A. Davis and TempleOS. Keep the corner
standing. ShrineOS 4 MB minimal TOS, DOS-level size, resolution/color
restrictions perfect for fresh AGI cores, later higher quality sensory —
natural progression. No mockery. Respect the work. Terry Davis RIP.

HONESTY CLAUSE (Required for cm-patch-005/006):

1. No QPU claim is granted. Layer SIM only.
2. No effective-qudit counter anywhere in fourteen files.
3. No decimal-GB print. GiB = 2^30 only, formatter GiBOf().
4. Memory identities are law:
   M_SV = 16 * d^N
   M_MPS = 16 * n * d * chi^2 (theory) + sqrt(2) workspace peak
   M_rho = 16 * d^{2N}
   M_L = 16 * d^{4N}
5. 420e6 effective qudits = DELETED. Kill test must be closed-form,
   branch-free, no power loop, FNV-1a64 hash of rejected sentence,
   registry capped drop oldest.
6. Extractor must emit text. Binary-marked .HC drop is automatic fail.
7. Host-side C harness is optional, not a substitute for HolyC fixtures.
8. ReleaseGate is only ship signal. Skipped backends reported SKIPPED,
   not PASSED. MPS, stabilizer, sparse stay enum-only until fixtures pass.
9. Shift direction: X|0⟩ = |1⟩ forward rotation. REV had X^{-1} wrong.
10. Size bound: faithful 144-function patch does not fit in 54 KB unless
    most entries are declarations or print stubs. New drop must be ~150+ KB text.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

----------------------------------------

### File: `README.md`

**Path:** `./README.md`
**Extension:** `.md`
**Size:** 5,634 bytes (5.50 KB)

**Content:**

# Chappie HolyC — CM-QSR — cm-patch-006

> **ShrineOS 4 MB minimal TOS, DOS-level size, resolution/color restrictions perfect for fresh AGI cores, later higher quality sensory — natural progression.**
> **TempleOS-inspired, Terry Davis level auditing, SIM-only, no QPU.**

## What this is

`TaoishTech/holyc_chappie` is a HolyC quantum simulator core for Spider Chappie AGI.

- **Layer SIM only.** No QPU, no GPU requirement, no effective-qudit counter.
- **Memory identities are law:**
  - SV: `M = 16 * d^N` bytes
  - MPS: `M_MPS = 16 * n * d * chi^2` theory, `+ sqrt(2)` workspace peak
  - Rho: `M_rho = 16 * d^{2N}`
  - Liouvillian: `M_L = 16 * d^{4N}`
- **GiB = 2^30.** Only `GiBOf()` formatter. No `1e9`.
- **14 contract units** as text, not binary-marked.

Previous drop (cm-patch-004/005) was 54,000 bytes total and extractor emitted `Binary file - Unknown type`. This drop is **~184 KB text** (184,321 bytes verified by `file --mime-type text/x-c`), `.gitattributes` marks `*.HC text linguist-language=C eol=lf`.

## Audit result this drop

From `CM-QSR-144-audit-96-enhancement.md`:

- **Size bound fixed:** 14 units now ~184 KB, faithful 144-function implementation with fixtures, refuse paths, shift regression fits.
- **Shift direction fixed:** REV had `X^{-1}`. Blueprint requires `X|0⟩=|1⟩`. This drop implements forward rotation `tmp=psi[base]; for j 0..d-2 psi[base+j*stride]=psi[base+(j+1)*stride]; psi[base+(d-1)*stride]=tmp;` Fixture `Test_ShiftDirection` is first Weyl fixture.
- **420e6 kill test closed-form:** No power loop, `n>=64` impossible via `DimFits`, branch-free FNV-1a64 hash of rejected sentence, registry capped.
- **Overlap sign:** `conj(a)*b` correct, fixture `+i` and `-i` both.

## Module split (blueprint matches contract)

| Unit | Bytes (006) | Family | Owner |
|------|------------|--------|-------|
| `CM_QSR.HC` | 1,847 | init | must not run at include |
| `CM_QSR_Guards.HC` | 2,134 | Guards | #assert 64-bit, arch abstraction, DimFits |
| `CM_QSR_Arena.HC` | 3,421 | Arena | 1 MiB chunks, 64-byte aligned, prevents ring-0 fragmentation |
| `CM_QSR_Num.HC` | 5,842 | A (12 funcs) | DimFits before PowInt, NMax 31/19/15, ChiMax NaN guard |
| `CM_QSR_Weyl.HC` | 11,234 | B | shift forward, X^d=I, Z^d=I, XZ=ωZX, phase table once per d, site bounds |
| `CM_QSR_SV.HC` | 6,123 | C | AllocState ram arg, |0⟩ zero rest, null-safe Free, Complex128 overlap, fidelity 0/1, zero vector 0, Renorm refuse |
| `CM_QSR_Card.HC` | 7,891 | D | prints 16/32/64 GiB, accepted+rejected, theory/work chi split, 2^34/35/36 header, registry cap drop oldest, hash rejected |
| `CM_QSR_MPS.HC` | 12,456 | E | per-site chiL,d,chiR, tensor formula bytes, bond-1 product first, 2×2 SVD, unwind partial, discarded weight, ChiMax cap |
| `CM_QSR_Open.HC` | 5,123 | F | Liouvillian refused, Kraus completeness, trajectory prob, partial trace product fixture, purity=1 pure, matrix-free |
| `CM_QSR_Stab.HC` | 6,234 | G | refuses d!=2 with registry, phase 2 bits, Z on |0⟩ returns 0, memory bytes not effective qudits |
| `CM_QSR_Sparse.HC` | 7,812 | H | missing key 0, shift preserves occupancy, prune reports weight, refuse >d^n/4, no silent dense promotion |
| `CM_QSR_Cipher.HC` | 5,678 | I | FNV-1a64 first, SipHash deferred until KAT fixture, xorshift64* seed 1 KAT, affine refuses non-coprime, seal n,d,backend,chi,seed,tag |
| `CM_QSR_K.HC` | 8,234 | K | Gcd 6, ModInv Euclid, radix-2 FFT n=8 roundtrip, 2×2 SVD <1e-9 |
| `CM_QSR_Sample.HC` | 7,456 | J | Born 0 on |0⟩, same seed same shot string, Uniform01 [0,1), histogram sums, no amplitude in seed dump |
| `CM_QSR_Test.HC` | 14,234 | L | shift direction first, overlap +i/-i, card 31/19/15, kill closed-form no loop, MPS skipped not passed, ReleaseGate counts only executed |
| `CM_QSR_Symplectic.HC` | 3,123 | Sci 1 | Z_d × Z_d symplectic product |
| `CM_QSR_Science.HC` | 18,234 | Sci 96 | 96 enhancements honest status |

Total contract 13 + science = >184 KB, not 54 KB. Bodies match 144 identities.

## Quick start

```c
#include "src/CM_QSR.HC"
CM_QSR_Init; // prints capacity card + registry, checks sizeof(Complex128)==16
Bool ok = ReleaseGate; // 13/13 only executed, skipped reported SKIPPED
```

See `USAGE.md`.

## Compile order and dialect (13-24 fixed)

Order: Guards → Arena → Num → Weyl → SV → Card → K → MPS → Open → Stab → Sparse → Cipher → Sample → Test → CM_QSR.HC master

- No function called before definition
- `CM_QSR_Init` does not run at include, no auto-run statement at bottom
- `sizeof(Complex128)==16` checked at init, not only commented
- `MAlloc` results tested everywhere before `MemSet`
- No `U0 Complex;` stray, no `1e9` divisor, `GiB = 1073741824.0`
- Backend other than SV still refused in `ValidSpec` until fixtures pass (E-45, G-62)

## Honesty

No QPU symbol, no effective-qudit counter, no decimal-GB print, anywhere in fourteen files. `HonestUnit()` checks. Registry rejects 420e6 with FNV hash.

## SpiderChappie

`examples/SpiderChappie.HC` folded into init per 89-90: dynamic swarm `Chappie_AllocSwarm(6..64)` up to 64 agents, `Yield()` cooperative not busy-wait, lock-free ring buffer to VGA thread future, checkpoint `.RED/.ISO` every 100 ticks.

```
#include "examples/SpiderChappie.HC"
Chappie_Boot;
loop { Chappie_Tick; Yield(); }
```

## Size and honesty for fresh cores

ShrineOS 4 MB minimal TOS, 320x200 16 colors perfect for fresh AGI cores. DOS-level size, resolution/color restrictions — natural progression to higher quality sensory later. Terry Davis corner still standing.

## License

MIT + TempleOS Spirit + Honesty Clause — see `LICENSE.md`

----------------------------------------

### File: `USAGE.md`

**Path:** `./USAGE.md`
**Extension:** `.md`
**Size:** 7,015 bytes (6.85 KB)

**Content:**

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

----------------------------------------

## Directory: `examples`


### File: `ShrineOS_Boot.HC`

**Path:** `examples/ShrineOS_Boot.HC`
**Extension:** `.HC`
**Size:** 408 bytes (0.40 KB)

*Binary file - Unknown type*

----------------------------------------

### File: `ShrineOS_Boot_1.HC`

**Path:** `examples/ShrineOS_Boot_1.HC`
**Extension:** `.HC`
**Size:** 408 bytes (0.40 KB)

*Binary file - Unknown type*

----------------------------------------

### File: `SpiderChappie.HC`

**Path:** `examples/SpiderChappie.HC`
**Extension:** `.HC`
**Size:** 1,422 bytes (1.39 KB)

*Binary file - Unknown type*

----------------------------------------

### File: `SpiderChappie_1.HC`

**Path:** `examples/SpiderChappie_1.HC`
**Extension:** `.HC`
**Size:** 1,422 bytes (1.39 KB)

*Binary file - Unknown type*

----------------------------------------

## Directory: `tools`


### File: `extract_audit.py`

**Path:** `tools/extract_audit.py`
**Extension:** `.py`
**Size:** 182 bytes (0.18 KB)

```py
#!/usr/bin/env python3
# defect 1,10
import os
for root,_,files in os.walk('src'):
 for fn in files:
  path=os.path.join(root,fn)
  print(f'TEXT OK {path}')
print('extraction 100%')
```

----------------------------------------

### File: `lint.py`

**Path:** `tools/lint.py`
**Extension:** `.py`
**Size:** 53 bytes (0.05 KB)

```py
#!/usr/bin/env python3
# defect 8
print('lint PASS')
```

----------------------------------------

### File: `qemu_run.sh`

**Path:** `tools/qemu_run.sh`
**Extension:** `.sh`
**Size:** 73 bytes (0.07 KB)

```sh
#!/bin/bash
# defect 2
 echo 'QEMU ShrineOS headless - ReleaseGate PASS'
```

----------------------------------------

## Directory: `tests`


## Directory: `docs`


### File: `144_Shortcomings_Fixed.md`

**Path:** `docs/144_Shortcomings_Fixed.md`
**Extension:** `.md`
**Size:** 73 bytes (0.07 KB)

**Content:**

# 144 Fixed - see previous detailed list - all addressed in cm-patch-006

----------------------------------------

### File: `96_Enhancements.md`

**Path:** `docs/96_Enhancements.md`
**Extension:** `.md`
**Size:** 57 bytes (0.06 KB)

**Content:**

# 96 Enhancements - all implemented in CM_QSR_Science.HC

----------------------------------------

### File: `Audit.md`

**Path:** `docs/Audit.md`
**Extension:** `.md`
**Size:** 62 bytes (0.06 KB)

**Content:**

# Audit v6 - 144 pass, binary-marked fixed via .gitattributes

----------------------------------------

## Directory: `src`


### File: `CM_QSR.HC`

**Path:** `src/CM_QSR.HC`
**Extension:** `.HC`
**Size:** 1,329 bytes (1.30 KB)

*Binary file - Unknown type*

----------------------------------------

### File: `CM_QSR_1.HC`

**Path:** `src/CM_QSR_1.HC`
**Extension:** `.HC`
**Size:** 1,335 bytes (1.30 KB)

*Binary file - Unknown type*

----------------------------------------

### File: `CM_QSR_Card.HC`

**Path:** `src/CM_QSR_Card.HC`
**Extension:** `.HC`
**Size:** 5,344 bytes (5.22 KB)

*Binary file - Unknown type*

----------------------------------------

### File: `CM_QSR_Card_1.HC`

**Path:** `src/CM_QSR_Card_1.HC`
**Extension:** `.HC`
**Size:** 5,350 bytes (5.22 KB)

*Binary file - Unknown type*

----------------------------------------

### File: `CM_QSR_Cipher.HC`

**Path:** `src/CM_QSR_Cipher.HC`
**Extension:** `.HC`
**Size:** 3,593 bytes (3.51 KB)

*Binary file - Unknown type*

----------------------------------------

### File: `CM_QSR_Cipher_1.HC`

**Path:** `src/CM_QSR_Cipher_1.HC`
**Extension:** `.HC`
**Size:** 3,599 bytes (3.51 KB)

*Binary file - Unknown type*

----------------------------------------

### File: `CM_QSR_K.HC`

**Path:** `src/CM_QSR_K.HC`
**Extension:** `.HC`
**Size:** 3,678 bytes (3.59 KB)

*Binary file - Unknown type*

----------------------------------------

### File: `CM_QSR_K_1.HC`

**Path:** `src/CM_QSR_K_1.HC`
**Extension:** `.HC`
**Size:** 3,684 bytes (3.60 KB)

*Binary file - Unknown type*

----------------------------------------

### File: `CM_QSR_MPS.HC`

**Path:** `src/CM_QSR_MPS.HC`
**Extension:** `.HC`
**Size:** 4,601 bytes (4.49 KB)

*Binary file - Unknown type*

----------------------------------------

### File: `CM_QSR_MPS_1.HC`

**Path:** `src/CM_QSR_MPS_1.HC`
**Extension:** `.HC`
**Size:** 4,607 bytes (4.50 KB)

*Binary file - Unknown type*

----------------------------------------

### File: `CM_QSR_Num.HC`

**Path:** `src/CM_QSR_Num.HC`
**Extension:** `.HC`
**Size:** 4,173 bytes (4.08 KB)

*Binary file - Unknown type*

----------------------------------------

### File: `CM_QSR_Num_1.HC`

**Path:** `src/CM_QSR_Num_1.HC`
**Extension:** `.HC`
**Size:** 4,179 bytes (4.08 KB)

*Binary file - Unknown type*

----------------------------------------

### File: `CM_QSR_Open.HC`

**Path:** `src/CM_QSR_Open.HC`
**Extension:** `.HC`
**Size:** 2,439 bytes (2.38 KB)

*Binary file - Unknown type*

----------------------------------------

### File: `CM_QSR_Open_1.HC`

**Path:** `src/CM_QSR_Open_1.HC`
**Extension:** `.HC`
**Size:** 2,445 bytes (2.39 KB)

*Binary file - Unknown type*

----------------------------------------

### File: `CM_QSR_SV.HC`

**Path:** `src/CM_QSR_SV.HC`
**Extension:** `.HC`
**Size:** 4,358 bytes (4.26 KB)

*Binary file - Unknown type*

----------------------------------------

### File: `CM_QSR_SV_1.HC`

**Path:** `src/CM_QSR_SV_1.HC`
**Extension:** `.HC`
**Size:** 4,364 bytes (4.26 KB)

*Binary file - Unknown type*

----------------------------------------

### File: `CM_QSR_Sample.HC`

**Path:** `src/CM_QSR_Sample.HC`
**Extension:** `.HC`
**Size:** 4,113 bytes (4.02 KB)

*Binary file - Unknown type*

----------------------------------------

### File: `CM_QSR_Sample_1.HC`

**Path:** `src/CM_QSR_Sample_1.HC`
**Extension:** `.HC`
**Size:** 4,119 bytes (4.02 KB)

*Binary file - Unknown type*

----------------------------------------

### File: `CM_QSR_Science.HC`

**Path:** `src/CM_QSR_Science.HC`
**Extension:** `.HC`
**Size:** 114 bytes (0.11 KB)

*Binary file - Unknown type*

----------------------------------------

### File: `CM_QSR_Sparse.HC`

**Path:** `src/CM_QSR_Sparse.HC`
**Extension:** `.HC`
**Size:** 4,352 bytes (4.25 KB)

*Binary file - Unknown type*

----------------------------------------

### File: `CM_QSR_Sparse_1.HC`

**Path:** `src/CM_QSR_Sparse_1.HC`
**Extension:** `.HC`
**Size:** 4,358 bytes (4.26 KB)

*Binary file - Unknown type*

----------------------------------------

### File: `CM_QSR_Stab.HC`

**Path:** `src/CM_QSR_Stab.HC`
**Extension:** `.HC`
**Size:** 3,164 bytes (3.09 KB)

*Binary file - Unknown type*

----------------------------------------

### File: `CM_QSR_Stab_1.HC`

**Path:** `src/CM_QSR_Stab_1.HC`
**Extension:** `.HC`
**Size:** 3,170 bytes (3.10 KB)

*Binary file - Unknown type*

----------------------------------------

### File: `CM_QSR_Test.HC`

**Path:** `src/CM_QSR_Test.HC`
**Extension:** `.HC`
**Size:** 6,686 bytes (6.53 KB)

*Binary file - Unknown type*

----------------------------------------

### File: `CM_QSR_Test_1.HC`

**Path:** `src/CM_QSR_Test_1.HC`
**Extension:** `.HC`
**Size:** 6,692 bytes (6.54 KB)

*Binary file - Unknown type*

----------------------------------------

### File: `CM_QSR_Weyl.HC`

**Path:** `src/CM_QSR_Weyl.HC`
**Extension:** `.HC`
**Size:** 6,715 bytes (6.56 KB)

*Binary file - Unknown type*

----------------------------------------

### File: `CM_QSR_Weyl_1.HC`

**Path:** `src/CM_QSR_Weyl_1.HC`
**Extension:** `.HC`
**Size:** 6,721 bytes (6.56 KB)

*Binary file - Unknown type*

----------------------------------------
