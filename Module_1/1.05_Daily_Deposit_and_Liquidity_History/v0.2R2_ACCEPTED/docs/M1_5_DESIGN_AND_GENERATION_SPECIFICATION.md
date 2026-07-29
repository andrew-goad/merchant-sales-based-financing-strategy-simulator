# M1.5 Design and Generation Specification

## 1. Business purpose

M1.5 creates a deterministic synthetic operating-account history that translates accepted merchant POS settlements into observable liquidity behavior. It supplies the daily balance, NSF, negative-balance, and existing-financing-pressure evidence needed by later source-quality, underwriting-feature, stress, and portfolio-management stages.

The output is a synthetic analytical construct. It is not bank-statement data, transaction categorization, servicing performance, or calibrated merchant liquidity behavior.

## 2. Accepted inputs

M1.5 consumes only accepted upstream artifacts:

- G1 frozen parameter, profile, and source snapshots;
- M1.2 merchant and relationship population;
- M1.3 applications and requested structures;
- M1.4 180-day POS and processor-settlement history;
- one approved, contract-ready `DEPOSIT_DAILY` source contract.

All accepted upstream hashes must recompute exactly before generation.

## 3. Output grain and cardinality

```text
population_id + merchant_id + observation_date
```

```text
750 merchants × 180 dates = 135,000 rows
```

## 4. Merchant liquidity profile

Each merchant receives a deterministic profile containing:

- industry capture center and balance-buffer center;
- merchant capture and withdrawal rates;
- target balance buffer and initial opening balance;
- provisional liquidity-risk tier;
- governed NSF and negative-balance propensities;
- source-observability flag;
- bounded lower closing-balance floor;
- optional bounded existing-financing-remittance window.

The provisional liquidity tier is a synthetic segmentation aid. It is not a calibrated probability-of-default or production credit tier.

## 5. Deposit generation

### Captured POS deposit

```text
Base POS Deposit
=
Accepted Net Merchant Proceeds
× Daily Capture Rate
```

Daily capture is governed by industry center, merchant-level deterministic variation, relationship adjustment, and daily deterministic variation. It is bounded between 25% and 100%.

### Non-POS support deposit

A cumulative deterministic support amount is added only when the raw closing path would fall below the governed lower closing-balance floor. It represents synthetic owner or non-POS liquidity support and is separately visible in the blueprint.

```text
Total Deposit
=
Base POS Deposit
+ Non-POS Support Deposit
```

## 6. Withdrawal generation

Operating withdrawals reflect:

- merchant withdrawal-to-deposit profile;
- day-of-week and month-cycle factors;
- deterministic daily variation;
- processor and operating disruption factors;
- bounded liquidity-stress draws;
- active existing-financing remittance.

```text
Total Withdrawal
=
Base Operating Withdrawal
+ Bounded Stress Withdrawal
+ Existing Financing Remittance
```

## 7. Existing-financing pressure

A deterministic subset of merchants with prior advances receives a 30-, 60-, or 90-day active financing window. Daily remittance is bounded to 2.5%–6.0% of average daily net merchant proceeds and is applied only while the processor is active and the observation date is inside the assigned window.

This is synthetic obligation pressure for liquidity analysis. Detailed obligation evidence remains a later controlled stage.

## 8. Balance roll-forward

```text
Closing Balance
=
Opening Balance
+ Deposit Amount
− Withdrawal Amount
```

```text
Available Balance
=
Closing Balance
− Temporary Hold Amount
```

```text
Minimum Balance
=
minimum(Opening Balance, Closing Balance, Available Balance)
```

The next day opening balance equals the current day closing balance.

## 9. Temporary holds and NSF events

Temporary holds are derived from accepted refunds, chargebacks, and reversals. NSF propensity is governed by provisional liquidity tier and increased when available balance is negative or below 25% of target buffer. Daily NSF count is bounded to zero, one, or two.

## 10. Source observability

`deposit_source_available_flag` represents whether deposit history would be observable from the simulated source. M1.5 always stores the full latent synthetic truth panel. M1.7 will separately convert source availability, freshness, reconciliation, and conflict into data-confidence evidence.

## 11. Deterministic controls

Every pseudo-random draw uses:

```text
msbf_ctl.deterministic_uniform(key, seed)
msbf_ctl.deterministic_normal(key, seed)
```

The expected snapshot is rebuilt directly from accepted inputs and code. The actual snapshot is independently reconstructed from persisted physical columns. Acceptance requires 135,000 expected rows, 135,000 actual rows, zero mismatches, and identical expected/actual/stored set hashes.

## 12. Stage boundary

M1.5 does not create:

- scenario-adjusted POS or deposit history;
- source-quality snapshots;
- application obligations, collateral, guarantees, credit, or verification evidence;
- underwriting features;
- risk components or risk snapshots;
- EAD, LGD, Expected Loss;
- latest or archive contract outputs.

## 13. Production boundary

All data and rules are synthetic demonstration assumptions. Production use would require approved source data, legal/compliance review, independent validation, monitoring, access controls, implementation controls, and formal governance approval.
