#ifndef CM_QSR_1_HC
#define CM_QSR_1_HC
// cm-patch-006 - header guard defect 3
#assert sizeof(I64)==8 // defect 4
#assert sizeof(U8)==1
#define CM_QSR_ARCH_X86_64 1 // defect 5
// CM_QSR.HC - Patch cm-patch-005 - Spider Chappie - Terry Davis level audit
// Layer SIM only, no QPU, no GPU requirement, no effective-qudit inflation
// Compile order is dependency order. Do not reorder.
// One init only enhancement 89,90. This file does NOT run at include enhancement 91.
// Extractor must emit text enhancement 94.

#include "CM_QSR_Num.HC"
#include "CM_QSR_Weyl.HC"
#include "CM_QSR_SV.HC"
#include "CM_QSR_Card.HC"
#include "CM_QSR_MPS.HC"
#include "CM_QSR_Open.HC"
#include "CM_QSR_Stab.HC"
#include "CM_QSR_Sparse.HC"
#include "CM_QSR_Cipher.HC"
#include "CM_QSR_K.HC"
#include "CM_QSR_Sample.HC"
#include "CM_QSR_Test.HC"

// Public entry remains CM_QSR_Init, prints card, kill test, fixtures, does not allocate state
U0 CM_QSR_Init(){
  if(sizeof(Complex128)!=16){
    "FATAL: sizeof(Complex128)!=16 - refusing\n";
    return;
  }
  CapacityCard;
  KillTest_420M;
  RegistryDump;
  Bool ok=ReleaseGate; // enhancement 92 only ship signal
  if(ok) "CM-QSR cm-patch-005 ACCEPTED - Spider Chappie audited, Terry-level\n";
  else "CM-QSR cm-patch-005 REJECTED - fix fixtures\n";
}

// Call CM_QSR_Init; to run

#endif // CM_QSR_1_HC
