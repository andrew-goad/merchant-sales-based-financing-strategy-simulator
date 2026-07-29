# M1.11 Design and Generation Specification

## Business purpose

M1.11 translates accepted scenario-aware operating evidence into explainable cash-flow archetypes and operating-resilience measures. It supports portfolio segmentation and later risk-component design while preserving the separation between observed operating resilience and calibrated merchant credit risk.

## Archetype precedence

1. `INSUFFICIENT_EVIDENCE`
2. `THIN_HISTORY`
3. `DISRUPTED`
4. `DECLINING`
5. `VOLATILE`
6. `SEASONAL`
7. `GROWING`
8. `STABLE`

The precedence prevents a merchant with blocking evidence or a major disruption from being mislabeled as stable merely because another metric appears favorable.

## Component weights

- Revenue: 30%
- Liquidity: 25%
- Burden/capacity: 25%
- Processor continuity: 10%
- Data confidence: 10%

## Stress interpretation

The recession scenario may leave the final resilience tier/archetype risk rank unchanged or worsen it. It may not improve either interpreted measure relative to the matched baseline. Observed underlying metrics are not overwritten.

## Performance design

Accepted physical M1.9 and M1.10 rows are materialized once, indexed, and analyzed. Generation creates only 1,500 snapshot rows and 7,500 component rows. Validation, acceptance, and reporting operate on persisted M1.11 rows and independently recomputed physical hashes.

## Physical extension

The module adds two parent tables and 76 designed columns. Projected totals after migration are 76 parent/non-child tables and 1,293 designed table columns. This is a controlled post-G0 extension; the original G0 acceptance remains unchanged.
