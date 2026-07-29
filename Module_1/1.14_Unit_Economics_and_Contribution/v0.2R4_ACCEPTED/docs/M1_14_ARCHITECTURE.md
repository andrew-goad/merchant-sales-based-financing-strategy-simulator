# M1.14 Architecture

## Governing purpose

M1.14 connects the accepted merchant-risk and comparative-loss foundations to a
transparent conditional-if-booked economic view. It makes revenue, non-loss
cost, loss burden, capital charge, hurdle, and contribution independently
visible before any final price or offer is created.

## Enterprise flow

```text
Accepted M1.3 request and channel terms
                    │
Accepted M1.10 capacity evidence
                    │
Accepted M1.13 exposure / comparative-loss evidence
                    ▼
        Materialized 1,500-row matched input
                    ▼
 Revenue foundation ── Non-loss cost foundation
                    │
 Comparative-loss burden ── Synthetic capital charge
                    ▼
 Contribution before loss
 Contribution after comparative loss
 Risk-adjusted contribution
                    ▼
 Annualized return ── Hurdle ── Economic surplus
                    ▼
 Evidence gate / tier / review routing
                    ▼
 1,500 wide snapshots + 21,000 component records
                    ▼
 Deterministic hashes, validation, acceptance evidence
```

## Physical architecture

### `application_unit_economics_snapshot`

One row for each governed application/scenario combination. It retains all
source-lineage hashes, input amounts, rate assumptions, component amounts,
contribution measures, returns, tiers, evidence status, and review routing.

### `unit_economics_component_value`

Fourteen long-form components provide direct reconciliation to the wide
snapshot and support downstream reporting without re-running economic formulas.

### `v_m1_14_unit_economics_lineage`

A governed consumption view exposes the scenario identity and principal
conditional-if-booked economics while preserving application and run lineage.

## Controls

- The M1.13 comparative-loss amount is consumed as accepted; it is not
  recalibrated in M1.14.
- A blocked loss-evidence record receives no fabricated after-loss contribution,
  return, surplus, or favorable economics.
- Stress contribution and annualized return cannot improve relative to the
  accepted baseline matched application.
- Partner acquisition cost uses the approved channel rate when available and a
  governed default otherwise, subject to a policy cap.
- All visible wide economics reconcile to fourteen persisted component records.
