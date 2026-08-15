# M2.6 v0.2R1 Master-Report Boundary-Source Correction

## Root cause

Program 178 v0.2 calculated strategy-distribution metrics from the accepted
latest contract and also attempted to calculate six execution-boundary flags
from that same table.

The latest contract intentionally contains recommendation and review fields,
but it does not persist:

- `merchant_contact_executed_flag`
- `payment_change_executed_flag`
- `write_off_or_charge_off_executed_flag`
- `legal_or_collection_action_executed_flag`
- `external_notice_generated_flag`
- `production_adverse_action_notice_flag`

Those fields are governed on
`msbf_m2.advance_intervention_strategy_snapshot`, where Programs 175 and 177
already validated them and Program 179 already reports boundary exceptions.

## Correction

Program 178 v0.2R1 keeps strategy distribution and exposure on the latest
contract and moves only the executed-boundary calculation to the strategy
snapshot.

## Current execution

Programs 172–177 remain authoritative. Program 178 is read-only, so no
persistent rollback or regeneration is required.

Run:

```text
178A (optional proof)
→ 178 v0.2R1
→ 179 v0.2
```

Required:

```text
178A recovery_status = PASS
178 overall_m2_6_status = PASS
179 Result Sets 23 and 24 = zero rows
```
