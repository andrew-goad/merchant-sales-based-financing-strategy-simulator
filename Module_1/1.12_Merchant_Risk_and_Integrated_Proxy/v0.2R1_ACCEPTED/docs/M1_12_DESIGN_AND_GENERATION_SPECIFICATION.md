# M1.12 Design and Generation Specification

## Business purpose

M1.12 converts accepted operating, capacity, source-confidence, fraud, verification, continuity, industry, and relationship evidence into a transparent synthetic merchant-risk proxy. It is designed to support governed comparison and downstream development, not to impersonate a calibrated default model.

## Unit of analysis

- Wide snapshot: run × scenario × application
- Long component: run × scenario × application × component
- Expected rows: 1,500 wide, 10,500 long

## Component methodology

The seven risk-oriented component scores are bounded from 0 to 100. Each is multiplied by its governed weight, rounded to six decimals, and persisted. The independent integrated score is the sum of the seven persisted weighted points when all evidence is usable.

Hard verification stops and fraud tier five impose governed score floors. The accepted stress scenario then applies a non-improvement floor relative to the matched baseline score and tier.

## Synthetic proxy

```text
Synthetic Merchant Risk Proxy = Integrated Risk Score / 100
```

The proxy is a normalized synthetic indicator only. It is not a calibrated probability of default.

## Evidence gating

- COMPLETE: all required evidence is usable
- PARTIAL: evidence is usable with a controlled limitation
- BLOCKED: one or more required components cannot support a numeric integrated score

Blocked rows retain tier 5 and `INSUFFICIENT_EVIDENCE`, while score and proxy remain null.

## Performance architecture

- No upstream blueprint regeneration
- One materialization of accepted input rows
- One 10,500-row component expansion
- One 1,500-row composite and stress pass
- One persistence and `ANALYZE` phase
- One expected/actual canonical reconciliation
- Persisted-only validation and reporting


## Physical schema extension

M1.12 adds two designed parent tables and 65 designed columns. Projected totals after migration are **78 designed parent/non-child tables** and **1,358 designed table columns**. The original G0 acceptance remains historically unchanged at 70 physical parent tables and 1,041 designed columns.
