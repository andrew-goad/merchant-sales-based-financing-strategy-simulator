# M1.12 Architecture

```text
Accepted M1.8 verification / fraud / continuity
                    +
Accepted M1.10 capacity and obligation evidence
                    +
Accepted M1.11 archetype and operating-resilience evidence
                    ↓
       Materialized 1,500-row matched input
                    ↓
 Seven transparent risk-oriented components
                    ↓
 Persisted weighted component evidence (10,500 rows)
                    ↓
 Governed hard-stop / fraud floors
                    ↓
 Matched stress score and tier floors
                    ↓
 Integrated score, normalized synthetic proxy,
 tier, status, reasons, and controlled routing
                    ↓
 1,500 snapshots + 10,500 components
                    ↓
 Exact 12,000-entity canonical reconciliation
```

## Design principles

1. **Transparency:** every composite point is traceable to a persisted component.
2. **Evidence gating:** blocked evidence produces no numeric proxy.
3. **Risk separation:** the proxy remains distinct from calibrated PD, EAD, LGD, and Expected Loss.
4. **Matched stress discipline:** adverse stress may not improve the interpreted score or tier.
5. **No cold handoffs:** source hashes, reasons, review flags, and fallback paths are retained with every snapshot.
