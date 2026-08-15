# M2.10 Design and Generation Specification

The accepted M2.9 latest contract is materialized once. Certified account
states map deterministically to:

```text
57 CLOSED_STABLE       → NO_SERVICING_REQUIRED       → 0 burden
1  ACTIVE_RECONCILED   → ACTIVE_REASSESSMENT         → 2 burden
1  CONTROLLED_REVIEW   → GOVERNANCE_REVIEW_HOLD      → 5 burden
```

Portfolio KPIs are calculated from the account-performance fact at three
scopes: all accounts, baseline, and recession-energy stress. Rate KPIs use
explicit numerator/denominator fields and `NOT_APPLICABLE` when denominators
are zero. The expected portfolio totals are $785.48 certified exposure,
$194.25 processed payments, a 1.000000 collection rate, 0.142857 return rate,
1.000000 retry cure, and 7.000000 burden units.
