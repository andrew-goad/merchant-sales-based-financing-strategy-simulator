# M1.8 Architecture

```text
Accepted M1.7 source-quality evidence
        +
Accepted merchant/application/owner/processor relationships
        +
Accepted M1.4 baseline POS continuity history
        +
Accepted M1.6 recession/energy POS continuity history
        ↓
Materialized 750-application input
        ↓
Five atomic checks + independent fraud screen
        ↓
4,500 persisted verification-result rows
        ↓
Independent fraud tier + baseline/stress continuity tiers
        ↓
750 application verification/fraud/continuity summaries
        ↓
Canonical hash reconciliation → validation → negative controls → acceptance
```

M1.8 deliberately keeps data confidence, verification, fraud, processor continuity and future credit risk as separate dimensions.
