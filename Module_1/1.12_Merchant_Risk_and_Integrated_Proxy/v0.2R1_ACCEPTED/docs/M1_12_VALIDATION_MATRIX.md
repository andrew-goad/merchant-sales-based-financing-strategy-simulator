# M1.12 Validation Matrix

Positive controls: **80**

| Code | Control | Threshold |
|---|---|---|
| `M1_12_POS_01_RUN_STATUS` | Run status is M1_12_GENERATED | M1_12_GENERATED |
| `M1_12_POS_02_G1_CONTROL_PLANE` | Accepted predecessor gate G1_CONTROL_PLANE | PASS |
| `M1_12_POS_03_M1_2_POPULATION` | Accepted predecessor gate M1_2_POPULATION | PASS |
| `M1_12_POS_04_M1_3_APPLICATION_REQUEST` | Accepted predecessor gate M1_3_APPLICATION_REQUEST | PASS |
| `M1_12_POS_05_M1_4_DAILY_POS_HISTORY` | Accepted predecessor gate M1_4_DAILY_POS_HISTORY | PASS |
| `M1_12_POS_06_M1_5_DAILY_DEPOSIT_LIQUIDITY` | Accepted predecessor gate M1_5_DAILY_DEPOSIT_LIQUIDITY | PASS |
| `M1_12_POS_07_M1_6_MATCHED_SCENARIO_OVERLAYS` | Accepted predecessor gate M1_6_MATCHED_SCENARIO_OVERLAYS | PASS |
| `M1_12_POS_08_M1_7_SOURCE_QUALITY_CONFIDENCE` | Accepted predecessor gate M1_7_SOURCE_QUALITY_CONFIDENCE | PASS |
| `M1_12_POS_09_M1_8_VERIFICATION_FRAUD_CONTINUITY` | Accepted predecessor gate M1_8_VERIFICATION_FRAUD_CONTINUITY | PASS |
| `M1_12_POS_10_M1_9_ASOF_CASHFLOW_FEATURES` | Accepted predecessor gate M1_9_ASOF_CASHFLOW_FEATURES | PASS |
| `M1_12_POS_11_M1_10_OBLIGATIONS_LIQUIDITY_CAPACITY` | Accepted predecessor gate M1_10_OBLIGATIONS_LIQUIDITY_CAPACITY | PASS |
| `M1_12_POS_12_M1_11_CASHFLOW_ARCHETYPE_RESILIENCE` | Accepted predecessor gate M1_11_CASHFLOW_ARCHETYPE_RESILIENCE | PASS |
| `M1_12_POS_13_PARAMETER_HASH` | Accepted parameter hash | bd09e598c82db96e47459d77fd11e7c8 |
| `M1_12_POS_14_PROFILE_HASH` | Accepted profile hash | 462cbd2ed92f68e5bdecf6b17537a973 |
| `M1_12_POS_15_SOURCE_HASH` | Accepted source hash | 93c3d1368fb2450ab4a08e2b721f92d3 |
| `M1_12_POS_16_POPULATION_HASH` | Accepted population hash | 9b706c926260a3ef1ae8ac95eed5d0bf |
| `M1_12_POS_17_APPLICATION_HASH` | Accepted application hash | 01485256b9b5748fb412743d35ced602 |
| `M1_12_POS_18_POS_HISTORY_HASH` | Accepted pos history hash | d1971e8d319483c187ec0c0483a31e33 |
| `M1_12_POS_19_DEPOSIT_HISTORY_HASH` | Accepted deposit history hash | bbe96dd24fbbba3af4a587dd475a88d0 |
| `M1_12_POS_20_SCENARIO_SET_HASH` | Accepted scenario set hash | 3f85921bf6fc30ddc6cee146085e58c5 |
| `M1_12_POS_21_SOURCE_QUALITY_HASH` | Accepted source quality hash | de56a458d9ec0b344886850592c4e6c8 |
| `M1_12_POS_22_VERIFICATION_HASH` | Accepted verification hash | 604a5640a25da92a850840dbe13e3d56 |
| `M1_12_POS_23_CASHFLOW_HASH` | Accepted cashflow hash | 7c25acac533179f42789a6daa79d0cc3 |
| `M1_12_POS_24_CAPACITY_HASH` | Accepted capacity hash | a91e82a315305a98953d013043a17d9a |
| `M1_12_POS_25_RESILIENCE_HASH` | Accepted resilience hash | d219b2a0cb6d32f400b1ab71be6521fb |
| `M1_12_POS_26_POLICY_APPROVED` | M1.12 policy profile is approved | APPROVED |
| `M1_12_POS_27_METHODOLOGY_VERSION` | M1.12 methodology version | M1_12_METHOD_V1 |
| `M1_12_POS_28_COMPOSITE_BASIS` | Composite uses persisted weighted risk points | SUM_PERSISTED_WEIGHTED_RISK_COMPONENTS |
| `M1_12_POS_29_COMPONENT_WEIGHT_SUM` | Component weights sum to one | 1.000000 |
| `M1_12_POS_30_TIER_THRESHOLD_ORDER` | Risk-tier thresholds are strictly increasing | strictly increasing |
| `M1_12_POS_31_STRESS_FLOORS_ENABLED` | Matched stress non-improvement floors are enabled | score=true|tier=true |
| `M1_12_POS_32_SCENARIO_SCOPE` | Exactly one approved baseline and one approved stress scenario | 2|1|1 |
| `M1_12_POS_33_SNAPSHOT_COUNT` | Integrated risk snapshot row count | 1500 |
| `M1_12_POS_34_COMPONENT_COUNT` | Integrated risk component row count | 10500 |
| `M1_12_POS_35_APPLICATION_COUNT` | Application coverage | 750 |
| `M1_12_POS_36_SCENARIO_COUNT` | Scenario coverage | 2 |
| `M1_12_POS_37_UNIQUE_SNAPSHOT_GRAIN` | Unique scenario/application snapshot grain | rows=unique |
| `M1_12_POS_38_UNIQUE_COMPONENT_GRAIN` | Unique scenario/application/component grain | rows=unique |
| `M1_12_POS_39_SEVEN_COMPONENTS_PER_SNAPSHOT` | Exactly seven components per snapshot | 0 violations |
| `M1_12_POS_40_COMPONENT_CODE_COVERAGE` | All governed component codes are present | 7 |
| `M1_12_POS_41_COMPONENT_WEIGHT_IDENTITY` | Component weights sum to one per snapshot | 0 violations |
| `M1_12_POS_42_COMPONENT_SCORE_BOUNDS` | Component scores and weighted points are bounded | 0 violations |
| `M1_12_POS_43_WEIGHTED_COMPONENT_IDENTITY` | Weighted points equal rounded score times weight | 0 violations |
| `M1_12_POS_44_COMPONENT_AVAILABILITY_IDENTITY` | Component availability fields are internally consistent | 0 violations |
| `M1_12_POS_45_COMPONENT_ZONE_MAPPING` | Component-zone mapping follows governed thresholds | 0 violations |
| `M1_12_POS_46_DIRECTIONAL_STATUS_MAPPING` | Directional-status mapping follows governed cutoffs | 0 violations |
| `M1_12_POS_47_COMPONENT_LINEAGE_PRESENT` | Every component retains source lineage | 0 violations |
| `M1_12_POS_48_COMPONENT_ROW_HASH` | Component calculation hashes reconstruct from physical fields | 0 violations |
| `M1_12_POS_49_WIDE_LONG_COMPONENT_RECONCILIATION` | Wide component scores equal long-form evidence | 0 violations |
| `M1_12_POS_50_EVIDENCE_STATUS_IDENTITY` | Integrated evidence status reflects upstream and component availability | 0 violations |
| `M1_12_POS_51_COMPOSITE_IDENTITY` | Non-blocked integrated score equals persisted weighted component sum after governed floors | 0 violations |
| `M1_12_POS_52_BLOCKED_PROXY_SUPPRESSION` | Blocked evidence suppresses score and proxy | 0 violations |
| `M1_12_POS_53_PROXY_IDENTITY` | Synthetic risk proxy equals integrated score divided by 100 | 0 violations |
| `M1_12_POS_54_INDEPENDENT_TIER_MAPPING` | Independent risk tier follows independent score | 0 violations |
| `M1_12_POS_55_BASELINE_IDENTITY` | Baseline score and tier reproduce matched baseline rows | 0 violations |
| `M1_12_POS_56_FINAL_TIER_MAPPING` | Final integrated risk tier follows final score | 0 violations |
| `M1_12_POS_57_STATUS_MAPPING` | Risk status follows evidence status and final tier | 0 violations |
| `M1_12_POS_58_STRESS_SCORE_NONIMPROVEMENT` | Stress integrated score does not improve relative to baseline | 0 improvements |
| `M1_12_POS_59_STRESS_TIER_NONIMPROVEMENT` | Stress risk tier does not improve relative to baseline | 0 improvements |
| `M1_12_POS_60_STRESS_WORSENING_FLAG` | Stress worsening flag reflects score or tier deterioration | 0 violations |
| `M1_12_POS_61_HARD_STOP_SCORE_FLOOR` | Verification hard stops receive the governed score floor when evidence is usable | 0 violations |
| `M1_12_POS_62_FRAUD_TIER_FLOOR` | Fraud tier five receives the governed score floor when evidence is usable | 0 violations |
| `M1_12_POS_63_RISK_FLOOR_FLAG` | Risk-floor flag reflects hard-stop or severe-fraud adjustment | 0 violations |
| `M1_12_POS_64_MANUAL_REVIEW_IDENTITY` | Manual-review recommendation follows governed routing conditions | 0 violations |
| `M1_12_POS_65_FALLBACK_MAPPING` | Fallback path follows governed precedence | 0 violations |
| `M1_12_POS_66_PRIMARY_REASON_DOMAIN` | Primary risk reason belongs to the governed domain | 0 violations |
| `M1_12_POS_67_SECONDARY_REASON_ARRAY` | Secondary reason arrays contain no null elements | 0 violations |
| `M1_12_POS_68_SCORE_BOUNDS` | Snapshot component and integrated scores are bounded | 0 violations |
| `M1_12_POS_69_TIER_BOUNDS` | All risk tiers remain between one and five | 0 violations |
| `M1_12_POS_70_MATCHED_SCENARIO_COVERAGE` | Every application has one baseline and one stress snapshot | 0 violations |
| `M1_12_POS_71_UPSTREAM_ROW_HASH_LINEAGE` | Snapshot lineage hashes reproduce accepted upstream rows | 0 violations |
| `M1_12_POS_72_SNAPSHOT_ROW_HASH` | Integrated snapshot row hashes reconstruct from physical fields | 0 violations |
| `M1_12_POS_73_SNAPSHOT_SET_HASH` | Snapshot set hash reconciles | actual=stored |
| `M1_12_POS_74_COMPONENT_SET_HASH` | Component set hash reconciles | actual=stored |
| `M1_12_POS_75_COMBINED_SET_HASH` | Combined canonical set hash reconciles | actual=stored |
| `M1_12_POS_76_GENERATION_EVIDENCE` | Generation evidence inventory is complete | 9 |
| `M1_12_POS_77_CANONICAL_COUNTS` | Canonical counts and stored mismatch evidence reconcile | 12000|12000|0 |
| `M1_12_POS_78_ASOF_LINEAGE` | As-of dates do not exceed the governed run date | 0 future rows |
| `M1_12_POS_79_STAGE_BOUNDARY` | No downstream calibrated risk, exposure, loss, latest, or archive rows exist | 0 |
| `M1_12_POS_80_BLOCKING_ERRORS` | No blocking configuration errors exist | 0 |

Negative controls: **7**

- Generation disabled
- Invalid component-weight sum
- Invalid tier order
- Unapproved policy
- Unapproved accepted stress scenario
- Prerequisite run-status drift
- Post-generation rerun