# M1.3 Design and Generation Specification

## 1. Business question

> What deterministic application and requested sales-linked financing structure should be attached to each accepted synthetic merchant before transaction history, underwriting evidence, risk translation, or decisions are generated?

## 2. Stage boundary

M1.3 owns application identity and request mechanics. It does not own cash-flow underwriting or a final offer.

### Included

- Application and as-of dates.
- Processor and partner linkage.
- Requested funding amount.
- Requested remittance rate.
- Requested expected payoff horizon.
- Requested total repayment and finance charge.
- Requested use of proceeds.
- Application channel and submitted status.
- Request-row hash.
- Diagnostic annual-sales proxy, sales-linked reference amount, repayment-path ratio, and request-sizing constraint.

### Excluded

- POS and deposit history.
- Source quality or verification evidence.
- Existing obligations.
- Collateral and covenant requirements.
- Credit/fraud/data-confidence risk.
- Approval, counteroffer, or decline.
- Final price, disclosure, or legal classification.
- EAD, LGD, Expected Loss, contribution, or portfolio allocation.

## 3. Deterministic identity

```text
merchant_application_id = merchant_id || '_A01'
application_date         = run as_of_date
as_of_date                = run as_of_date
application_status        = SUBMITTED
```

Exactly one application is created for each of the 750 accepted merchants.

## 4. Exact governed assignments

### Expected payoff horizons

| Horizon | Frozen weight | Exact target |
|---:|---:|---:|
| 30 days | 25% | 188 |
| 60 days | 45% | 337 |
| 90 days | 30% | 225 |

### Use of proceeds

| Use | Frozen weight | Exact target |
|---|---:|---:|
| Working capital | 45% | 338 |
| Inventory | 20% | 150 |
| Equipment repair | 12% | 90 |
| Seasonal need | 10% | 75 |
| Expansion | 8% | 60 |
| Emergency expense | 5% | 37 |

Largest-remainder quota allocation fixes exact counts. Deterministic merchant ranking assigns the categories without session randomness.

## 5. Request-generation annual-sales proxy

The proxy is generated solely to create internally related request amounts. It is not observed cash-flow evidence and must not be consumed as an underwriting feature.

| Accepted annual-sales band | Proxy range |
|---|---:|
| `UNDER_250K` | $150,000–$250,000 |
| `250K_TO_1M` | $300,000–$1,000,000 |
| `1M_TO_5M` | $1,200,000–$5,000,000 |
| `5M_TO_20M` | $5,500,000–$20,000,000 |

Within-band values use a deterministic log-style transform.

## 6. Requested economics

### Reference tier

A transparent synthetic reference tier uses owner score, prior relationship evidence, and processor tier. It is a request-generation market reference only. It is not an underwriting grade or final price tier.

### Remittance rate

```text
requested remittance rate
= governed horizon center
+ merchant-size adjustment
+ relationship adjustment
+ channel adjustment
+ deterministic dispersion
bounded by global minimum and maximum
```

### Payback multiple

```text
requested payback multiple
= governed reference-tier center
+ horizon adjustment
+ relationship adjustment
+ channel adjustment
+ prior-default adjustment
+ deterministic dispersion
bounded by global minimum and maximum
```

### Request-path utilization factor

The factor creates both conservative and aggressive requests:

```text
< 1.0  requested economics are below the deterministic reference sales path
≈ 1.0  requested economics are near that path
> 1.0  requested economics exceed that path and require downstream review
```

The factor is bounded between 0.65 and 1.35 and responds to relationship stage, owner profile, use of proceeds, and deterministic request appetite.

## 7. Requested amount

Four candidate limits are calculated:

```text
Merchant request appetite
Sales-linked request reference
Funding-to-annualized-sales cap
Global funding maximum
```

The lowest candidate applies, subject to the governed product minimum and $100 request increment.

```text
requested funding amount
= max(product minimum,
      floor(min(candidate limits) / 100) × 100)
```

If the product minimum overrides a lower structural candidate, the blueprint identifies `MINIMUM_PRODUCT_AMOUNT_FLOOR`. This is not hidden or treated as automatically affordable.

## 8. Core identities

```text
requested total repayment
= round(requested funding × requested payback multiple, 2)

requested finance charge
= requested total repayment − requested funding

expected daily remittance proxy
= requested total repayment ÷ requested expected payoff days

implied payoff days
= requested total repayment
  ÷ (annual-sales proxy / 365 × requested remittance rate)

repayment-path ratio
= requested total repayment
  ÷ (annual-sales proxy / 365 × requested remittance rate × requested horizon)
```

The expected daily remittance is an arithmetic request-path measure. The implied payoff and repayment-path ratio diagnose whether the request appears below, near, or above the reference sales path. M1.3 does not adjudicate affordability.

## 9. Canonical deterministic proof

Expected hashes are regenerated directly from frozen G1/M1.2 inputs and M1.3 rules. Actual hashes are independently recomputed from all 17 persisted physical application columns. Acceptance requires 750 expected rows, 750 actual rows, zero mismatches, and identical expected/actual/stored aggregate hashes.

## 10. Production boundary

The stage is an explainable synthetic request generator. Production implementation would require institution data, product/legal approval, empirical calibration, pricing governance, compliance review, validation, security controls, monitoring, and formal change management.
