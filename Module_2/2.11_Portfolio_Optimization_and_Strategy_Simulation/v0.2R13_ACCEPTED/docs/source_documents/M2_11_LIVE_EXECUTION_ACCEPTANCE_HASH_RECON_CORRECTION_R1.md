# M2.11 live-execution acceptance hash-reconstruction correction R1

## Runtime trigger

Program 217 stopped fail-closed with 43 of 45 prerequisites passing. The two failed requirements were:

```text
M2_11_ACC_029_ORDERED_SET_HASH_RECON   5 set-hash mismatches
M2_11_ACC_031_COMBINED_SET_HASH_RECON  combined-set mismatch
```

Programs 215 and 216 had already completed 120/120 and 20/20 PASS respectively. The Program 217 requirement guard is before all acceptance writes, so the failed transaction did not reach the acceptance-gate, acceptance-evidence, or lifecycle-write section.

## Root cause

The superseded Program 217 aggregated stored hashes from `msbf_m2.v_m2_11_canonical_entity_hash_source` ordered by a text `business_key`. For five families, that view's key-component order differs from the governed Program 214/215 set-hash order:

| Family | Superseded view order | Governed order |
|---|---|---|
| Strategy summary | run, strategy, scope | run, scope, strategy |
| Frontier | run, strategy, scope | run, scope, strategy |
| Comparison | run, challenger, scope | run, scope, challenger |
| Latest | run, strategy, scope | run, scope, strategy |
| Archive | run, version, strategy, scope | run, version, scope, strategy |

That explains the exact live mismatch count of five. Program 215's target-typed physical reconstruction passed all nineteen families, so the persisted canonical state and registry hashes were internally sound.

## Correction

Program 217 now reconstructs all nineteen family hashes directly from target-typed physical fields using the exact Program 214/215 ordering, governed run filters, and contract-version filters. It no longer uses the canonical hash-source view as the set-hash reconstruction authority.

```text
Program 217 prior SHA-256  dbd40464e8a157514abd2344becc58529f7f8e1bc7d703f9a03bcac5e7913f4f
Program 217 R11 SHA-256   1b56dc1aadcf66c6c695b71346ff60472790a5f297a8efdae4d9332b0ebfcf35
Acceptance matrix SHA-256 2681dd66f9a5ea2d42e1cdedecc120e8d5087623db832b97bfb21697ca57314a
```

No generated business row, source snapshot, strategy result, score, frontier result, latest value, archive value, registry hash, combined hash, or lifecycle rule changed.

## Resume boundary

```text
Programs 212–216      LIVE PASS / DO NOT RERUN
Corrected Program 217 R11  AUTHORIZED RESUME POINT
Programs 218–219      CONDITIONAL AFTER PROGRAM 217 PASS
Recovery programs     NOT AUTHORIZED
M2.11                  VALIDATED / NOT ACCEPTED
```
