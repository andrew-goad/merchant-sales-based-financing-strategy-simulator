# M2.3 Architecture

```text
Accepted M2.2 pricing structure latest rows
        1,500 scenario/application rows
                    |
                    v
Target-typed M2.3 source snapshot
                    |
                    v
Decision/outcome authorization mapping
  STRUCTURE_READY -> FINAL_OFFER_AUTHORIZED
  COUNTEROFFER_FOUNDATION_REVIEW -> COUNTEROFFER_REVIEW_REQUIRED
  NO_STRUCTURE_INSUFFICIENT_EVIDENCE -> DECLINE_INSUFFICIENT_EVIDENCE_AUTHORIZED
  NO_STRUCTURE_POLICY_DECLINE -> DECLINE_POLICY_AUTHORIZED
                    |
                    v
Latest decision contract + immutable archive
                    |
                    v
M2.4 booking/funding remains prohibited until later authorization
```
