# Data Lineage and As-of Framework
## Merchant Sales-Based Financing Strategy Simulator v0.1R1

# 1. Purpose

The framework prevents future-data leakage, preserves reproducibility, separates economic scenarios from source history, and makes every decision and action traceable to evidence available at the time.

# 2. Six time axes

| Time axis | Definition | Primary use |
|---|---|---|
| Observation date | Date of POS, deposit, remittance, covenant, or collateral evidence | Source facts |
| Application as-of date | Latest data permitted for origination features | Module 1/2 |
| Decision date | Date profile, strategy, and compliance package are selected | Module 2 |
| Booking/performance date | Funding and daily account lifecycle | Module 3 |
| Scenario reference/horizon date | Stress assumption timing | Module 1/4 |
| Regulatory effective/selection date | Date approved requirement is applicable and selected | Module 2/control plane |

# 3. Origination leakage rule

For every feature used in Module 1 or Module 2:

```text
source_observation_timestamp ≤ application_as_of_timestamp
```

Exceptions are prohibited. Later corrections may create a new restated run but cannot silently rewrite the original decision evidence.

# 4. Performance leakage rule

For a Module 3 recommendation on `review_date`:

```text
performance_date, covenant_test_date, collateral_valuation_date,
and source_observation_date ≤ review_date
```

# 5. Stress snapshot rule

Module 4 begins from an immutable accepted portfolio snapshot. Scenario outputs do not alter baseline facts. Each result preserves baseline, direct shock, indirect shock, and stressed value separately.

# 6. Regulatory selection rule

A requirement can be selected only when:

```text
status = APPROVED
and effective_start_date ≤ decision_date
and (effective_end_date is null or decision_date < effective_end_date)
and next_review_date ≥ decision_date
```

Any failure produces review/block.

# 7. Source-to-feature lineage

Every derived feature stores or can resolve:

```text
feature_definition_id
calculation_version
source_snapshot_ids
observation_window_start/end
as_of_date
parameter_snapshot_id
scenario_overlay_id
quality_status
lineage_hash
```

# 8. Baseline versus scenario history

1. Generate one deterministic baseline merchant/day history.
2. Store it immutably by population ID.
3. Apply scenario transformations to matched merchant/date rows.
4. Preserve baseline and scenario values separately.
5. Do not regenerate intrinsic merchant identity for matched scenarios.

# 9. Window standards

Initial configurable windows:

- 7/14/30 days for very recent performance;
- 30/60/90 days for short-term origination and trend;
- 180 days for intermediate seasonality/volatility;
- 365 days where available for annual seasonality and long-run comparison.

Every feature name or dictionary entry must expose its window and denominator.

# 10. Corrections and restatements

- source correction creates a new source snapshot version;
- feature restatement creates a new Module 1 run;
- decision restatement creates a new Module 2 run and does not replace the archived original;
- performance correction creates a new correction version or restated account-day record with lineage;
- regulatory source change creates a superseding profile version and impact review.

# 11. Data-quality states

```text
AVAILABLE_CONFIRMED
AVAILABLE_WITH_WARNING
PARTIAL_FALLBACK
CONFLICT_REVIEW
SOURCE_OUTAGE
UNAVAILABLE
```

Data-quality status is distinct from merchant credit health.

# 12. Restricted data and access

The architecture supports separate restricted domains for demographic/reporting data and future production payment/security data. The public simulator includes neither real demographic applicant data nor real cardholder data.

# 13. Required validation tests

- maximum source observation date by feature ≤ as-of date;
- identical population/profile/source versions reproduce identical snapshot hash;
- baseline/scenario merchant/date key coverage matches;
- regulatory profile effective-date and staleness tests pass;
- correction versions preserve original history;
- every decision/health/stress row resolves to full lineage;
- no restricted reporting field appears in the decision contract unless explicitly approved for a lawful purpose.

## M1.16 LINEAGE ADDENDUM

Acquisition touchpoints may not occur after the application boundary. Application-level acquisition evidence projects unchanged into both accepted M1.15 scenario rows. M1.14 baseline/stress source hashes and M1.15 contract hashes remain explicit lineage.
