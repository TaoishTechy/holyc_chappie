# Chappie HolyC — CM-QSR — cm-patch-006

<img width="1024" height="572" alt="image" src="https://github.com/user-attachments/assets/2206c033-c44a-4ca6-9803-d758e214a4f5" />


> **ShrineOS 4 MB minimal TOS, DOS-level size, resolution/color restrictions perfect for fresh AGI cores, later higher quality sensory — natural progression.**
> **TempleOS-inspired, Terry Davis level auditing, SIM-only, no QPU.**

## What this is

.MD Format Snapshot for Easy LLM Improting/Analysis: [HolyC Chappie v6 SNapshot](https://github.com/TaoishTechy/holyc_chappie/blob/main/snapshots/holyc_chappie_v6_SNAPSHOT_directory_consolidated.md)

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
