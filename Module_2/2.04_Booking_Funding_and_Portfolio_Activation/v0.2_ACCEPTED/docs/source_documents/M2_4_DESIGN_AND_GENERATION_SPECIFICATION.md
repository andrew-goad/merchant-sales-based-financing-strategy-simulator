# M2.4 Design and Generation Specification

## Mapping

| Accepted M2.3 outcome | M2.4 activation outcome | Operational objects |
|---|---|---|
| `FINAL_OFFER_AUTHORIZED` | `BOOKED_FUNDED_PORTFOLIO_ACTIVATED` | Account, advance, portfolio |
| `COUNTEROFFER_REVIEW_REQUIRED` | `ACTIVATION_REVIEW_REQUIRED` | None |
| `DECLINE_INSUFFICIENT_EVIDENCE_AUTHORIZED` | `NOT_ACTIVATED_INSUFFICIENT_EVIDENCE` | None |
| `DECLINE_POLICY_AUTHORIZED` | `NOT_ACTIVATED_POLICY_DECLINE` | None |

## Deterministic identifiers

Synthetic identifiers are MD5-derived from governed run, scenario, application and entity-type keys:

```text
MSBF_ACCT_<20 uppercase hex characters>
MSBF_ADV_<20 uppercase hex characters>
```

## Dates

```text
Booking date                  as_of_date + 1 day
Funding date                  as_of_date + 2 days
Portfolio activation date     as_of_date + 2 days
Monitoring start date         as_of_date + 2 days
First expected remittance     as_of_date + 3 days
```

## Canonical reconciliation

```text
1 policy
+ 5 outcomes
+ 24 reasons
+ 4 notice controls
+ 1,500 source rows
+ 1,500 activation snapshots
+ 1,500 latest rows
+ 1,500 archive rows
+ 59 accounts
+ 59 advances
+ 59 portfolio positions
+ 1 registry
= 6,212 canonical entities
```
