# M1.12 Parameter Dictionary

All M1.12 methodology parameters are governed in policy profile `M1_12_INTEGRATED_RISK_PROXY`, version 1.

| Parameter | Value | Purpose |
|---|---:|---|
| `component_weight_operating_resilience` | 0.25 | Operating-resilience contribution |
| `component_weight_capacity_burden` | 0.20 | Capacity and burden contribution |
| `component_weight_liquidity` | 0.15 | Liquidity contribution |
| `component_weight_source_confidence` | 0.10 | Source-confidence contribution |
| `component_weight_verification_fraud` | 0.15 | Verification and fraud contribution |
| `component_weight_processor_continuity` | 0.05 | Processor-continuity contribution |
| `component_weight_industry_relationship` | 0.10 | Industry and relationship context |
| `risk_tier_1_max` | 20 | Tier 1 upper boundary |
| `risk_tier_2_max` | 40 | Tier 2 upper boundary |
| `risk_tier_3_max` | 60 | Tier 3 upper boundary |
| `risk_tier_4_max` | 80 | Tier 4 upper boundary |
| `hard_stop_score_floor` | 90 | Minimum usable-evidence score for verification hard stops |
| `fraud_tier_5_score_floor` | 80 | Minimum usable-evidence score for fraud tier five |
| `manual_review_tier_min` | 4 | Minimum tier triggering risk review |
| `source_confidence_partial_threshold` | 0.90 | Threshold below which evidence is partial |

The seven component weights must sum to 1.0. Tier thresholds must be strictly increasing.
