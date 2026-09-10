# MSBF R22 Power BI Desktop Evidence — Independent Adjudication

## Decision

**R22's substantive Power BI remediation passed.** The uploaded evidence package is intact, the refreshed model retained the expected 54 tables / 52 relationships / 164 measures / 52 expressions, P05 and P06 render without error panels, all zero-safe cards now display numeric values, and the P06 incremental-servicing comparison correctly shows Early Intervention = 4 with the other profiles = 0.

The final evidence gate is nevertheless **HOLD_FOR_BOUNDED_STATE_CORRECTION** because the submitted save/reopen attestation says the project was returned to `BALANCED_FRONTIER`, while the reopened screenshot and the captured working PBIP both show the saved P06 strategy profile as `EARLY_INTERVENTION`.

This is an owner-evidence state variance—not a source, model, DAX, relationship, carrier, strategy, or business-output defect.

## Evidence integrity

```text
Evidence ZIP SHA-256          32ef3d1670983c5e256e684d6eced6458786b71fc98fa8fe9681213d284efc5b
Sidecar match                 PASS
ZIP CRC                       PASS
Archive file members          154
Owner manifest rows           153
Manifest missing              0
Manifest hash mismatches      0
Manifest unexpected files     0
Duplicate paths               0
Traversal/absolute paths      0
Encrypted members             0
```

The manifest governs every file except the manifest itself.

## Structural and source review

```text
Immutable R22 source PBIP changed       FALSE
Tables                                  54
Relationships                           52
Measures                               164
Expressions                             52
Relationship definitions                EXACT
Column definitions                      EXACT
DAX measure expressions                 EXACT
M partition expressions                 EXACT
P01-P04 page definitions                EXACT
Evidence of manual model/source edits   NONE
Desktop-changed working files           49
```

The 49 working-file differences consist of normal Desktop metadata/serialization, generated linguistic metadata/layout, visual query activation metadata, and saved report interaction state. No owner-authored M, DAX, relationship, visual-field binding, page-definition, or carrier edit was found.

## Attestation review

| Attestation | Independent result |
|---|---|
| Full refresh | Supported PASS |
| P01-P04 functional | Supported PASS |
| P05 error-free; no-feasible proof coverage = 100.0% | Supported PASS |
| P06 error-free | Supported PASS |
| Balanced Frontier = 0 / 0 / 1 / 0 | Supported PASS |
| Early Intervention = 4 / 4 / 0 / 0 | Supported PASS |
| Incremental servicing chart: Early Intervention 4; others 0 | Supported PASS |
| Multiple profiles remain visible | Supported PASS |
| Save/close/reopen functionality | Supported PASS |
| Returned to Balanced Frontier before save/reopen | **Not supported / FAIL** |
| No manual source/model edits | Supported NO |

## Exact saved-state variance

```text
Source R22 P06 strategy default          BALANCED_FRONTIER
Captured working PBIP saved state        EARLY_INTERVENTION

P06 strategy-slicer source SHA-256
08f96afb0d8cb16e91b4d601a9b101716c9a9b79c7caf34b48722660d9677656

P06 strategy-slicer working SHA-256
f585d816472193c92086dbb9c86b6a729e68efc9f12d69a90701f192a58b2c78
```

The time sequence is also consistent:

```text
Balanced screenshot                 17:57:00
Early Intervention screenshot       17:58:28
Saved strategy-slicer file          17:58:52
Reopen screenshot                   18:04:14
```

## Bounded correction

No new R22 package, preparation run, query refresh, model change, or logic correction is needed.

Open the existing R22 working PBIP, set P06 back to `BALANCED_FRONTIER`, save, close, reopen, capture a replacement `05_reopen_validation_r22.png` showing the Balanced state, and rerun only the existing evidence collector. Preserve the current `180652` package as superseded diagnostic evidence.

## Authority

Accepted Module 1/G2 and Module 2/G3 remain controlling. R17 and R19 remain successful engineering candidates. R22's model/visual remediation is physically proven, but Independent Audit submission remains on hold until the corrected R22 evidence package removes the attestation contradiction.
