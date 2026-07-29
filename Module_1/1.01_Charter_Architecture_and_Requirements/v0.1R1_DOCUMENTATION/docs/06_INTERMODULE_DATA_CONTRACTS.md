# Intermodule Data Contracts
## Merchant Sales-Based Financing Strategy Simulator v0.1R1

# 1. Contract principles

Every contract is:

- versioned;
- immutable after acceptance;
- grain- and key-specific;
- as-of controlled;
- schema validated;
- source and run lineage complete;
- rejected on missing mandatory fields or incompatible versions;
- archived separately from latest views.

A consumer must not query a producer's internal stage tables.

# 2. Contract summary

| Contract | Producer | Consumer | Grain | Primary key |
|---|---|---|---|---|
| `CTRL_PROFILE_SNAPSHOT_V1` | Control plane | M1–M4 | Run × profile/value | `run_id + profile_type + profile_id + version` |
| `M1_APPLICATION_RISK_SNAPSHOT_V1` | M1 | M2, M4 | Scenario × application | `module1_run_id + merchant_application_id` |
| `M2_FINAL_DECISION_V1` | M2 | M3, M4, reporting | Strategy × application | `module2_run_id + merchant_application_id` |
| `M2_OFFER_COMPLIANCE_PACKAGE_V1` | M2 | Operations/reporting/audit | Final offer × package version | `final_offer_id + package_version` |
| `M2_BOOKED_ADVANCE_V1` | M2 | M3, M4 | Booked advance | `advance_id` |
| `M3_ACCOUNT_DAY_PERFORMANCE_V1` | M3 | M4, reporting | Advance × date | `advance_id + performance_date` |
| `M3_MERCHANT_HEALTH_ACTION_V1` | M3 | M4, reporting | Facility × review date | `facility_id + review_date` |
| `M3_LOSS_MITIGATION_RECOMMENDATION_V1` | M3 | M4, reporting | Advance × review × treatment | `advance_id + review_date + treatment_id` |
| `M4_STRESS_MERCHANT_RESULT_V1` | M4 | Reporting/governance | Stress run × merchant/advance | `stress_run_id + entity_type + entity_id` |
| `M4_PORTFOLIO_LIMIT_STATUS_V1` | M4 | Governance/reporting | Run × limit × segment | `stress_run_id + limit_id + segment_key` |
| `M4_STRATEGY_ROBUSTNESS_V1` | M4 | Governance/reporting | Strategy × scenario × portfolio snapshot | composite business key |
| `M4_CAPACITY_ALLOCATION_V1` | M4 | Portfolio strategy | Allocation run × segment | `allocation_run_id + segment_key` |

# 3. `CTRL_PROFILE_SNAPSHOT_V1`

Mandatory families:

- run identity and code version;
- profile type/id/version/status;
- effective start/end and selection date;
- owner/approver;
- parameter name/value/unit/source;
- superseded profile reference;
- snapshot hash.

Invariants:

- one resolved value for each mandatory parameter path;
- all selected profiles approved and effective;
- no stale regulatory profile;
- hash stable for identical configuration.

# 4. `M1_APPLICATION_RISK_SNAPSHOT_V1`

Mandatory identity:

```text
module1_run_id
population_id
module1_scenario_id
merchant_id
merchant_application_id
application_date
as_of_date
history_start_date
history_end_date
source_snapshot_id
contract_version
```

Mandatory analytical families:

- merchant/industry/channel/relationship;
- source availability/freshness/confidence;
- verification/fraud/operational continuity;
- revenue, trend, volatility, seasonality, refunds, chargebacks;
- deposits, liquidity, obligations, stacking;
- cash-flow archetype;
- request mechanics;
- capacity and burden;
- risk components and final proxy;
- EAD/LGD inputs/Expected Loss;
- boundary and diagnostic flags.

Reject conditions:

- duplicate application key;
- history after as-of date;
- missing request or core risk field;
- source/parameter/profile lineage absent;
- scenario population mismatch.

# 5. `M2_FINAL_DECISION_V1`

Mandatory identity:

- M1 lineage;
- module2 run/strategy/experiment identity;
- candidate selected ID;
- final offer ID;
- decision timestamp and as-of date.

Mandatory outcome:

- credit outcome;
- compliance disposition;
- allocation status;
- final amount/remittance/horizon/price/total repayment;
- acceptance and competitor assumptions;
- collateral/guarantee package;
- covenant package;
- offer-specific risk/EAD/LGD/EL;
- expected contribution;
- primary and secondary reason codes;
- manual-review and exception flags.

Invariants:

- exactly one final row per application/run;
- selected candidate exists and reconciles;
- positive booked result passes all hard controls;
- compliance block never maps to bookable offer.

# 6. `M2_OFFER_COMPLIANCE_PACKAGE_V1`

Mandatory fields:

- final offer and context identity;
- product/operating/jurisdiction/regulatory profile versions;
- applicability snapshot;
- required and satisfied disclosures/calculations;
- license/registration/broker checks;
- reporting and data-segregation flags;
- record-retention profile;
- required manual approvals and evidence;
- unresolved item count;
- disposition;
- package hash.

Reject conditions:

- calculation values do not reconcile to final offer;
- required document/profile version missing;
- expired permission;
- unresolved item with `CLEAR` status;
- stale requirement profile.

# 7. `M2_BOOKED_ADVANCE_V1`

Mandatory fields:

- facility and advance IDs;
- merchant/final offer IDs;
- booking/funding dates;
- funded amount and total repayment amount;
- remittance percentage;
- expected payoff horizon/date;
- contractual maturity where applicable;
- minimum-progress terms;
- opening balance/EAD path reference;
- collateral, guarantee, covenant links;
- processor/settlement route;
- accepted compliance package;
- facility limit and availability after booking.

# 8. `M3_ACCOUNT_DAY_PERFORMANCE_V1`

Mandatory fields:

- advance/facility/merchant/date identity;
- beginning/ending balance;
- eligible sales;
- expected and actual remittance;
- cumulative expected/actual remittance;
- fulfillment ratio;
- repayment progress index;
- payoff slippage;
- interruption days/severity;
- processor/data continuity;
- minimum-progress status;
- covenant/collateral status summary;
- performance state;
- source and policy version.

Invariants:

- balance roll-forward reconciles;
- date sequence has no duplicate;
- cumulative values are monotonic where expected;
- no performance date before booking;
- no future date relative to monitoring as-of.

# 9. `M3_MERCHANT_HEALTH_ACTION_V1`

Mandatory fields:

- facility/merchant/review identity;
- health components and final state;
- risk/relationship/opportunity flags;
- current limit/utilization/availability;
- recommended action and amount;
- action rationale/reason codes;
- policy/limit/compliance checks;
- escalation and owner;
- action status: recommended/approved/executed/rejected.

# 10. M4 contracts

Every M4 row preserves:

- portfolio snapshot and source-contract versions;
- scenario and dependency-network version;
- baseline values;
- direct shock;
- indirect shock by channel;
- stressed values;
- risk/loss/contribution deltas;
- limit status;
- recommended action;
- interpretation boundary.

# 11. Version compatibility

Consumers declare minimum and maximum supported contract versions. Incompatible versions fail before processing. Additive nullable fields may be backward compatible; grain, key, meaning, or unit changes require a new major contract version.

# 12. Error and quarantine handling

Rejected rows are written to a contract-error table with:

- contract name/version;
- producer run;
- business key;
- error code;
- failing field/value;
- detected timestamp;
- severity;
- resolution status.

No quarantined row can enter a positive decision, booking, or accepted evidence set.

# 13. Feedback loops

M3 and M4 outputs can inform proposed future policy/strategy versions, but they cannot modify M1 or M2 profiles directly. The loop is:

```text
Evidence → Recommendation → Governance Review → New Approved Version → New Run
```

## M1_ACQUISITION_CONSUMPTION v1

Application-level companion contract under `M1_ACQUISITION_SCHEMA_V1`. Module 2 consumes the future G2 bundle/view joining this contract to `M1_APPLICATION_CONSUMPTION v1`; it should not reach into stage tables directly.
