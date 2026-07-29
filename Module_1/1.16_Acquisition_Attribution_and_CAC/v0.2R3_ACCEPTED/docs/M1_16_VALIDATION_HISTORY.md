# M1.16 Validation and Correction History

## v0.2 — Initial source

- Schema and policy extension: PASS.
- Preflight: PASS.
- Program 118 stopped before commit because `_m1_16_campaign_calc` omitted `campaign_evidence_status`, which the downstream funnel CTE required.

## v0.2R1 — Committed acquisition generation

- Recovery: PASS; no M1.16 business, evidence, or gate rows had committed.
- Preflight: PASS.
- Generation: 18 source profiles, 20 campaigns, 120 funnel rows, 40 ledger rows, 1,075 touchpoints, 750 attribution snapshots, 750 cost snapshots, 9,000 components, 750 latest rows, 750 archive rows, 1,500 integrated rows, and 13,274 canonical entities with zero mismatches.
- Positive validation: 111 of 112 PASS.
- POS087 incorrectly treated 15 governed `BLOCKED_CONFLICT` records as physical parent-channel mismatches.

## v0.2R2 — Parent-channel and evidence-status separation

- Recovery proved physical parent mismatches = 0, status-mapping mismatches = 0, and governed blocked conflicts = 15.
- POS087 was corrected and passed.
- Positive validation again returned 111 of 112 because POS050 broadly counted the retained POS087 audit-history record as generation evidence.

## v0.2R3 — Exact generation-evidence inventory and acceptance

- Recovery proved the exact 25 governed generation records were present and preserved two audit-history records.
- POS050 was changed to the explicit 25-code inventory.
- Final positive validation: 112 of 112 PASS.
- Negative controls: 20 of 20 PASS.
- Acceptance gate and contract lifecycle: PASS / ACCEPTED.
- Master report: PASS.
- All 24 detailed reports completed; deterministic-mismatch and blocking/stage-boundary outputs are empty.

## Final accepted state

```text
Run status        M1_16_ACCEPTED
Contract status   ACCEPTED
Package           v0.2R3
Generation        v0.2R1
Methodology       M1_16_METHOD_V1
Schema            M1_ACQUISITION_SCHEMA_V1
Combined hash     86df51a0ca68d84096d00ff0f1b19f33
```
