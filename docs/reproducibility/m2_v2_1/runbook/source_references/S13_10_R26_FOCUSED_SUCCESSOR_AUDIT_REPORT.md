# IA-WP1R26 — Focused R26 Monitoring-Calibration Successor Audit

**Decision ID:** `IA-D-R15-M12-001`  
**Governing model:** `IA-GOV-20260822-001`  
**Overall:** `PASS_WITH_OBSERVATIONS`

## Recalibration determination

```text
Immediate gate
Accept or reject R26 as the next technical M2.5-M2.12/G3-v2 baseline and
authorize only the version-separated repository/Power BI integration step.

Material risks tested
Policy implementation drift
R2 identity failure masking business-output divergence
Unsafe retained-final resume or predecessor mutation
M2.11 strategy-method drift
Simulation/certification identity inconsistency

Another R26 runtime cycle required
NO

Empirical/physical evidence preferable to further static assurance
YES

Audit burden proportionality
SATISFIED
```

## Decision

R26 is **accepted as the next technical Module 2 M2.5-M2.12 / G3-v2 successor baseline**. The current public predecessor remains controlling public authority until a later version-separated integration and publication action is independently accepted.

| Matter | Disposition |
|---|---|
| Owner-approved M2.5 monitoring calibration | `PASS` |
| Physical R2 M2.5-M2.10 business outputs | `PASS` |
| R2 runtime as a whole | `FAIL — HISTORICAL PROVENANCE` |
| Retained-final clone-and-resume method | `PASS_WITH_OBSERVATIONS` |
| M2.11 eight-profile simulation | `PASS` |
| M2.12 / G3-v2 certification | `PASS` |
| R26 technical successor baseline | `PASS` |
| Version-separated repository / Power BI integration | `AUTHORIZED` |
| Public supersession / publication | `NOT AUTHORIZED` |

## Physical identities accepted

```text
R26 final result ZIP        113450c7167c8a5e1b40497c4e39506d276aa0e057bbeb3f316561af5d4096c3
Resume DB                   msbf_r1_r26_resume_g3v2_20260902_070655
Policy                      6c6a6f8103bb7276c5d1063d900d96070903e82b5f7143431bc150556e092027
Source root                 618ac7ad9278ad0c3876601eb75336bb166132d412f9eae221a145cda770d41f
Simulation bundle           569ea013b573b9c1e49592cbca0f078861b8d11f55462c3c49d718462c5b12ee
Control root                3d9e6f264bd220e7a80a7e433945d37a41ade548581d273218b0e3df8b6f2498
Power BI source bundle      b858965c48cd3aa0ca8ef9277305c2b2377db11cec03c1f48690c772764f98af
Report root                 c053dc064ab32a4d21864f943d7efb1d70adffc31701bddfbf26daf2db1b802d
Certification               G3V2_R26_C053DC064AB32A4D21864F94
```

## Policy implementation

The physical R26 source implements exactly the owner-approved policy: daily monitoring begins with first expected remittance; expected pace is selected total repayment divided by selected horizon; pace WATCH becomes eligible on day 21 and adverse pace status on day 30; three consecutive eligible-day pace breaches are required, yielding first pace-only WATCH/adverse activation on days 23/32; early no-remittance, zero-sales, liquidity and horizon triggers are retained; raw signal flags remain available while operational alert families are separately governed.

The packaged static policy test independently reran at **16/16 PASS**. Eighteen monitoring checkpoints were independently recomputed from the physical 15,600-row daily R26 extract with zero mismatch.

## R2 failure adjudication

The physical R2 receipt is correctly retained as `FAIL` at `FINAL_M2_11_M2_12`. It must not be relabeled PASS.

However, compiler/final M2.5, R26 daily overlay, and M2.6-M2.10 business exports are byte-for-byte exact. The raw stage registry differs only in execution timestamps, nested volatile timestamps and the COMPILER/FINAL authority label; the validation export differs only in `evaluated_at`. Independent execution of the packaged canonicalization re-performance returns PASS and derives one common semantic source root.

This is a localized evidence-identity defect, not a failed Wave A business computation.

## Retained-final resume

Before cloning, the resume verified the retained R2 final database identity, exact policy controls, absence of the R26 G3 schema, and nine Wave A exports byte-for-byte against the R2 result package. The clone reproduces the same nine exports, and the retained R2 final remains identical after the resume. R6 source control/schema also remains exact.

This is the correct solution-oriented recovery layer: the already-proven M2.5-M2.10 work was not rerun. Only M2.11/M2.12/G3-v2 was rebuilt on a fresh clone using the corrected semantic identity.

## M2.11 and G3-v2

```text
Strategy profiles             8
Candidate evaluations    52,152
Application simulations  12,000
Account simulations       1,040
G3-v2 controls             70/70 PASS
```

The accepted eight-profile strategy method is preserved. The R26 build changes the Wave A input/policy identity, not the strategy-selection method. Comparing the successful R2 compiler simulation to the resumed result shows business fields remain exact; the changed physical fields are the corrected `source_root_sha256` and dependent row hashes/identity controls.

The control root, six-object Power BI source bundle, report root and certification ID were independently recomputed from the physical resumed outputs and match exactly.

## Observations

1. The R2 run remains failed provenance; accept only its exact Wave A outputs as the resume source.
2. Corrected semantic identity necessarily changes M2.11 row hashes; this is expected and not a business-method change.
3. The R26 Power BI bundle is an accepted **source identity**, not an already refreshed/accepted public Power BI artifact.
4. Public supersession and GitHub/Power BI publication remain separate.

No blocking finding remains and no additional R26 runtime cycle is justified.

## Exact next action

> **Freeze R26 as the accepted technical successor baseline. Regenerate one version-separated Power BI and repository candidate from the exact accepted R26 physical facts and identities, preserving the current public predecessor authority and existing accepted report logic where not affected. Submit only that integration delta for bounded review before public supersession or publication. Do not rerun R26 unless a physical regression or source divergence is discovered.**
