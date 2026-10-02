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
