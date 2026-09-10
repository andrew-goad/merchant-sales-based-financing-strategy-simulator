# R26 retained-final resume and future top-to-bottom runtime architecture

## Current decision

R26 R2 completed the expensive compiler/final M2.5-M2.10 business path and proved its business exports exact. It failed only when volatile execution metadata (`validated_at`, `evaluated_at`, and COMPILER/FINAL role labels) was incorrectly included in the M2.11 deterministic source identity. The R2 final database `msbf_r1_r26_g3v2_20260902_024119` was retained and R6 was unchanged.

The owner briefly started the full-rerun R3, then intentionally interrupted it with Ctrl+C before substantial execution after the retained-final resume opportunity was recognized. The locally extracted R26_R3 folder was deleted. That interrupted attempt is not accepted evidence and is not used as a resume source. Any partial R3 database that may exist is observational only and must not be used or silently dropped by this package.

The governed resume source is exclusively the exact retained R2 final named above. This resume verifies that database against the exact R2 result evidence before cloning it. It never mutates the retained R2 final.

## Resume boundary

1. Verify immutable R6 remains physically unchanged.
2. Verify the retained R2 final database exists.
3. Verify its stable Wave A database identity equals the R2 final evidence.
4. Verify all R26 physical policy controls equal the R2 final evidence.
5. Verify the R26 G3 schema is absent, proving the R2 failure occurred before final G3 materialization.
6. Re-export every M2.5-M2.10 Wave A export read-only and require byte-for-byte equality to the R2 result ZIP.
7. Clone the retained R2 final to a fresh resume database.
8. Reconfirm Wave A identity on the clone.
9. Apply only the corrected Wave A semantic canonicalization boundary.
10. Materialize M2.11 and M2.12/G3-v2 on the clone.
11. Require the independently reconstructed compiler/final canonical source root and simulation identity.
12. Require G3-v2 70/70 PASS.
13. Reverify R6 and the retained R2 final are unchanged.

No M2.5-M2.10 SQL generation or validation is rerun through this resume.

## Permanent lesson for future top-to-bottom runtimes

Future MSBF successor runtimes must distinguish **business-semantic re-performance** from **execution/evidence identity construction**. A late evidence-identity defect must not automatically trigger hours of previously proven computation.

### Mandatory architecture requirements

- Compute and freeze a `BUSINESS_SEMANTIC_IDENTITY` after each expensive stage group, excluding timestamps, database names, execution roles, host/session metadata, and other observational fields.
- Keep a separate `EXECUTION_EVIDENCE_IDENTITY` that may include timestamps and role labels but is never used as a deterministic business source root.
- Before dropping a successful compiler, persist its canonical semantic identity and all source-root inputs needed to reproduce downstream deterministic identities offline.
- Before launching an expensive final downstream stage, run a **canonical compiler/final preflight** against all already-produced upstream artifacts. If canonical upstream identities differ, stop before downstream re-execution.
- Materialize durable checkpoint receipts at at least: Wave A complete, M2.11 simulation complete, and G3-v2 certification complete.
- Every top-to-bottom runtime must include a governed `RESUME_ELIGIBILITY` decision record. Resume is allowed only when the failed stage is downstream of a physically verified checkpoint and all upstream business-semantic identities are exact.
- Resume must always clone the retained failed-run database; never repair it in place.
- Resume must verify immutable source nonmutation and retained-predecessor nonmutation before and after execution.
- Full rerun remains mandatory when any upstream business output, policy, transformed source, schema, population, row-hash root, or business-semantic identity is uncertain or divergent.
- Package validation must test PowerShell parsing, deterministic-identity canonicalization, checkpoint/resume contracts, and clean extraction before operator delivery.

### Decision tree

`UPSTREAM BUSINESS DIVERGENCE / UNKNOWN` → fresh top-to-bottom compiler/final run.

`LATE DOWNSTREAM EVIDENCE-IDENTITY DEFECT + upstream exact + retained final available` → governed clone-and-resume.

`FAILED DATABASE RETAINED BUT upstream identity cannot be proven exact` → do not resume; fresh run.

This architecture is a permanent non-regression requirement for the next consolidated MSBF top-to-bottom runtime.
