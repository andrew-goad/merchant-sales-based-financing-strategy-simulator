# M1.4 Design and Generation Specification

## 1. Business purpose

M1.4 creates the daily merchant operating history that converts static merchant and application records into observable time-series evidence. It is the first stage where the simulator represents merchants as businesses operating through time rather than as one-time applications.

The primary business question is:

> What deterministic daily POS, transaction-quality, processor-continuity, and settlement behavior results from the accepted merchant population and frozen operating assumptions?

## 2. Grain and cardinality

The physical output grain is:

```text
population_id
+ merchant_id
+ processor_account_id
+ observation_date
```

The accepted baseline has:

```text
750 merchants
× 180 dates
= 135,000 rows
```

Rows before a merchant's processor-account activation date remain present as explicit zero-activity, not-connected observations. This preserves a rectangular calendar panel without falsely representing pre-activation transactions.

## 3. Source and lineage

M1.4 uses only accepted upstream entities and frozen controls:

- merchant master and primary industry assignment;
- processor account and partner channel;
- merchant relationship snapshot;
- accepted M1.3 application set, used as an upstream integrity prerequisite but not as a sales-generation input;
- frozen run parameter, profile, and source snapshots;
- approved `POS_DAILY` source contract;
- population observation window and deterministic seed version.

Each output row retains:

- accepted population identity;
- merchant and processor identity;
- source-contract identity;
- generating run identity;
- canonical row hash.

## 4. Merchant operating profile

`msbf_m1.m1_4_merchant_operating_profile` resolves one deterministic profile per merchant. It contains:

- industry sales center and dispersion;
- merchant-size and relationship scaling;
- cash-flow archetype;
- annual growth rate;
- daily volatility;
- zero-sales probability;
- seasonality amplitude and phase;
- weekday/weekend behavior;
- average-ticket center and merchant ticket scale;
- refund, chargeback, and reversal centers and multipliers;
- processor fee and settlement delay;
- optional bounded disruption, expansion, or demand-shock dates.

### 4.1 Cash-flow archetypes

The code assigns one of seven synthetic patterns:

| Archetype | Purpose |
|---|---|
| `STABLE` | Bounded ordinary growth with lower zero-sales pressure |
| `GROWING` | Positive trend and potential expansion step-up |
| `DECLINING` | Negative annual sales trend |
| `SEASONAL` | Larger governed seasonal amplitude |
| `VOLATILE` | Higher zero-sales and daily volatility behavior |
| `RECENT_DISRUPTION` | Short, material sales impairment near the as-of date |
| `THIN_HISTORY` | Processor account opened after the frozen history start |

Archetype assignment is deterministic and influenced by processor tenure, relationship history, prior interruption/default evidence, industry properties, and stable hash-based draws. It is not a calibrated behavioral model.

## 5. Daily-sales factor chain

For active, nonzero sales days, gross POS sales are generated from:

```text
Industry Daily Sales Center
× Merchant Scale
× Day-of-Week Factor
× Seasonal Factor
× Growth Trend Factor
× Lognormal Daily Volatility Factor
× Calendar Effect
× Processor Continuity Factor
× Bounded Operating-Event Factor
```

The result is bounded at zero and a synthetic upper limit, then rounded to currency precision.

### 5.1 Merchant scale

Merchant scale combines:

- annual-sales-band factor;
- relationship-stage factor;
- lognormal merchant dispersion;
- small deterministic jitter.

It is bounded to prevent implausibly tiny or dominant synthetic merchants.

### 5.2 Day-of-week behavior

Weekdays use a common Monday-through-Friday progression. Weekend behavior is industry-specific through frozen parameter values. This allows restaurants and retail to exhibit stronger weekends while professional services, construction, and energy services exhibit lower weekend volume.

### 5.3 Seasonality

Seasonality is a sinusoidal factor with an industry-specific amplitude and merchant-specific deterministic phase. It creates non-identical seasonal patterns within the same industry while preserving industry-level behavior.

### 5.4 Growth trend

The daily trend factor is derived from an archetype-level annual growth center plus bounded deterministic merchant variation. Growth is applied continuously over the observation window.

### 5.5 Volatility

The daily volatility factor is mean-adjusted lognormal variation derived from each industry's coefficient of variation. This preserves nonnegative sales while keeping expected scale near the merchant baseline.

## 6. Zero-sales and processor-continuity behavior

Zero-sales probability combines:

- industry zero-sales center;
- archetype multiplier;
- weekend adjustment;
- deterministic daily draw.

Processor status is independently generated from processor risk tier and a deterministic daily draw:

```text
NOT_YET_ACTIVE ↔ NOT_CONNECTED
ACTIVE         ↔ CONNECTED
DEGRADED       ↔ DELAYED
OUTAGE         ↔ DISCONNECTED
```

Processor outage forces a zero-sales row. Degradation applies a partial sales factor. Processor continuity and merchant cash-flow behavior remain separately diagnosable.

## 7. Calendar and bounded events

The baseline includes three governed calendar dates inside the accepted window:

- February 14, 2026;
- May 25, 2026;
- July 4, 2026.

Their effects differ by industry. They are demonstration sensitivities, not forecasts or universal holiday assumptions.

Bounded merchant events include:

- recent disruption;
- short demand shock;
- expansion step-up;
- processor degradation;
- processor outage.

Events are deterministic, bounded, and intentionally sparse. They create mixed operating histories without allowing edge cases to dominate the baseline.

## 8. Transaction and quality calculations

Transaction count is derived from gross sales and a merchant/day ticket estimate. Average ticket is then recalculated from the rounded gross-sales amount and final transaction count, ensuring physical reconciliation.

Refund, chargeback, and reversal rates use:

```text
Industry Center
× Merchant Multiplier
× Daily Multiplier
× Applicable Archetype Adjustment
```

Each rate is capped before calculating the currency amount.

Eligible sales are:

```text
max(
  Gross POS Sales
  − Refunds
  − Chargebacks
  − Reversals
  − Governed Exclusions,
  0
)
```

The baseline governed-exclusion amount is zero. Future policy/scenario stages may introduce governed exclusions without changing the physical schema.

## 9. Settlement methodology

Each processor account has a governed settlement delay. For an observation date:

```text
Settlement Source Date
=
Observation Date − Settlement Delay Days
```

Settlement amount equals eligible sales from that source date. The blueprint generates a limited pre-window buffer so the first physical observation dates can reproduce lagged settlement activity without storing pre-window fact rows.

Processor fee is:

```text
Settlement Amount × Processor Fee Rate
```

Net merchant proceeds are:

```text
Settlement Amount − Processor Fee Amount
```

## 10. Deterministic controls

M1.4 prohibits PostgreSQL session randomness. Every draw uses:

```text
msbf_ctl.deterministic_uniform(key, seed)
msbf_ctl.deterministic_normal(key, seed)
```

with unique M1.4 labels by behavioral component.

The expected snapshot is rebuilt directly from frozen inputs and code. The actual snapshot is independently reconstructed from persisted physical columns. Acceptance requires:

```text
Expected rows = 135,000
Actual rows   = 135,000
Mismatches    = 0
Expected set hash = Actual set hash = Stored set hash
```

Fixed-format scalar serialization is used for row hashing so numeric scale cannot create false mismatches.

## 11. Stage outputs

### Persistent business data

- `msbf_m1.merchant_pos_daily_base`

### Persistent governance evidence

- M1.4 generation specification;
- generation-specification hash;
- POS-history set hash;
- generation summary;
- 52 positive validation results;
- four negative-control results;
- acceptance summary;
- acceptance-gate result.

### Reusable functions

- `m1_4_pos_row_hash`
- `m1_4_assert_generation_ready`
- `m1_4_merchant_operating_profile`
- `m1_4_daily_pos_blueprint`
- `m1_4_expected_pos_snapshot`
- `m1_4_actual_pos_snapshot`

## 12. Explicit exclusions

M1.4 does not estimate:

- deposits, balances, NSFs, or liquidity;
- actual remittance performance;
- financing approval or price;
- default, delinquency, loss, or recovery;
- real economic forecasts;
- legal classification or disclosure requirements;
- production processor behavior;
- calibrated model outputs.

## 13. Acceptance standard

The stage is accepted only when:

- the preflight passes;
- generation persists exactly 135,000 rows;
- 52 positive checks pass;
- four negative controls pass;
- deterministic row and set hashes reconcile;
- all downstream/scenario tables remain empty;
- no blocking resolution error exists;
- the latest `M1_4_DAILY_POS_HISTORY` gate is `PASS`;
- the one-row master report returns `overall_m1_4_status = PASS`.
