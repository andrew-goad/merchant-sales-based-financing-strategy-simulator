# Module 4 Charter
## Portfolio Strategy, Economic Stress, Industry Dependency, Strategy Robustness, and Capacity Allocation Engine

# 1. Business question

> How do portfolio risk, loss, profitability, concentration, merchant health, line actions, and strategy rankings change under controlled economic, industry, funding, and competitive scenarios—and where should the institution deploy or withdraw incremental capacity?

# 2. Purpose

Module 4 is the enterprise portfolio-management layer. It consumes accepted origination and lifecycle evidence, applies direct and network-propagated stress, evaluates risk appetite and strategy robustness, and produces segment-level actions and multi-year planning evidence.

# 3. Primary grains

```text
merchant/advance stress result:
stress_run_id × merchant_id or advance_id

portfolio limit result:
stress_run_id × limit_id × segment_key

strategy robustness point:
strategy_id × scenario_id × portfolio_snapshot_id

capacity allocation:
allocation_run_id × segment_key
```

# 4. Inputs

- accepted M1/M2/M3 archive contracts;
- economic and market scenarios;
- industry dependency network;
- funding-cost and competitor assumptions;
- risk-appetite and concentration limits;
- strategy and portfolio-mix profiles;
- capital/risk-charge demonstration assumptions;
- one-/three-/five-year capability and growth constraints.

# 5. Processing stages

| Stage | Purpose |
|---|---|
| M4.0 | Portfolio snapshot, scenario, strategy, and limit identity |
| M4.1 | Source and profile gatekeeper |
| M4.2 | Direct macro/industry/funding/competitor shock assignment |
| M4.3 | Second-order industry dependency propagation with lag/damping/cap |
| M4.4 | Merchant sales, volatility, liquidity, collateral, and acceptance effects |
| M4.5 | Stressed risk, EAD, LGD, Expected Loss, contribution, and health |
| M4.6 | Segment and concentration aggregation |
| M4.7 | Risk-appetite warning/breach/action determination |
| M4.8 | Strategy frontier and robustness calculation |
| M4.9 | Incremental capacity allocation and withdrawal recommendation |
| M4.10 | One-/three-/five-year portfolio and capability evidence |
| M4.11 | Latest/archive, comparison, evidence, and acceptance |

# 6. Scenario taxonomy

- broad recession;
- consumer-spending decline;
- energy-price decline;
- energy-price spike and input-cost shock;
- inflation and margin compression;
- funding-cost increase;
- competitor-price compression;
- processor or partner disruption;
- regional downturn;
- supply-chain disruption;
- combined severe-but-plausible scenario.

# 7. Industry dependency model

Each directed relationship contains:

```text
source_industry_id
dependent_industry_id
transmission_channel
dependency_weight
transmission_lag_days
damping_factor
maximum_propagated_shock
scenario_applicability
source_reference_or_assumption
```

Propagation is transparent and bounded. The model is a synthetic sensitivity framework, not an input-output economic forecast.

# 8. Stress transmission

```text
Direct Shock
→ Merchant Revenue / Cost / Volatility / Liquidity
→ Remittance Capacity and Payoff Slippage
→ Credit Risk / Health / Line Action
→ EAD and Collateral Value
→ LGD and Expected Loss
→ Acceptance and Contribution
→ Concentration and Risk Appetite
→ Management Action
```

# 9. Strategy robustness

A strategy is evaluated across scenarios using:

- base expected booked contribution;
- stressed contribution and loss;
- worst-case and percentile outcomes;
- approval/access and booked volume;
- concentration and limit breaches;
- line/workout burden;
- relationship/wallet value;
- scenario dispersion;
- resilience score.

A base-case winner is not automatically the preferred robust strategy.

# 10. Capacity allocation

Incremental capacity ranking considers:

```text
Stress-Adjusted Expected Contribution
− Concentration Penalty
− Risk-Appetite Penalty
− Uncertainty / Data-Confidence Penalty
+ Relationship and Strategic Value
```

Recommendations include increase, maintain, restrict, pause, remediate, or exit by segment.

# 11. Owned logical tables

- `economic_scenario`;
- `scenario_factor_shock`;
- `industry_dependency`;
- `scenario_industry_shock`;
- `stress_merchant_result`;
- `stress_advance_result`;
- `portfolio_segment_snapshot`;
- `portfolio_limit_status`;
- `strategy_frontier_result`;
- `strategy_robustness_result`;
- `capacity_allocation_result`;
- `multi_year_strategy_evidence`;
- `module4_latest`;
- `module4_archive`.

# 12. Output contracts

- `M4_STRESS_MERCHANT_RESULT_V1`;
- `M4_PORTFOLIO_LIMIT_STATUS_V1`;
- `M4_STRATEGY_ROBUSTNESS_V1`;
- `M4_CAPACITY_ALLOCATION_V1`.

# 13. Exclusions

Module 4 does not:

- forecast actual GDP, commodity prices, or defaults;
- create production capital or reserve estimates;
- automatically implement policy or line changes;
- use industry dependency weights as empirical truth;
- override legal/compliance or credit hard controls.

# 14. P0 validation

- matched merchant/account population across scenarios;
- direct and indirect effects separately visible;
- propagation weights, lags, damping, and caps reconcile;
- no circular shock amplification beyond configured limits;
- stressed merchant metrics reconcile to portfolio totals;
- risk-appetite warnings and breaches use correct denominators;
- strategy rankings reproduce from archived evidence;
- capacity recommendations remain within budget and concentration headroom;
- stress results are sensitivities, not forecasts;
- one-/three-/five-year scale gates link to measurable evidence.

# 15. Acceptance gate

Module 4 is accepted when it can explain which initial shock affected which merchants through which channels, quantify portfolio consequences, compare strategy resilience, and recommend governed segment actions.
