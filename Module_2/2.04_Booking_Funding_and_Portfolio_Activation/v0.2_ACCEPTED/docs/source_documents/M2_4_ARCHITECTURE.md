# M2.4 Architecture

```text
Accepted M2.3 final-decision contract
        1,500 scenario/application rows
                    |
                    v
Target-typed M2.4 source snapshot
                    |
                    v
Activation mapping
  FINAL_OFFER_AUTHORIZED -> BOOKED_FUNDED_PORTFOLIO_ACTIVATED
  COUNTEROFFER_REVIEW_REQUIRED -> ACTIVATION_REVIEW_REQUIRED
  DECLINE_INSUFFICIENT -> NOT_ACTIVATED_INSUFFICIENT_EVIDENCE
  DECLINE_POLICY -> NOT_ACTIVATED_POLICY_DECLINE
                    |
                    v
59 synthetic accounts + 59 synthetic advances + 59 initial portfolio positions
                    |
                    v
Latest activation contract + immutable archive
                    |
                    v
M2.5 daily remittance, exposure and portfolio monitoring
```

The accepted M2.3 source is materialized once. Every hash-bearing staging table is explicitly target-typed before hashing. Generation, validation, negative testing, acceptance and reporting remain separate programs.
