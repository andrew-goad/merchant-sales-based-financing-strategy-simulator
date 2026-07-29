# M1.8 Design and Generation Specification

## Purpose

Create transparent, deterministic synthetic verification, fraud, and processor-continuity evidence for every accepted application without fabricating credit quality or treating missing evidence as a substantive failure.

## Grains

- `verification_result`: application × check × version × as-of timestamp — 4,500 rows.
- `application_verification_fraud_snapshot`: run × application — 750 rows.

## Checks

| Check | Governed source | Default route |
|---|---|---|
| KYB entity | Verification | Hard stop on fail/unavailable |
| Beneficial owner | Verification | Hard stop on fail/unavailable |
| Sanctions | Verification | Hard stop on fail/unavailable |
| Bank account match | Deposit daily | Hard stop on fail/unavailable |
| Processor match | POS daily | Hard stop on fail/unavailable |
| Fraud screen | Verification plus observed signals | Review on elevated tier/source quality; summary handles Tier 5 stop |

## Fraud methodology

Fraud score equals the governed base probability converted to points plus bounded, transparent point contributions for bank mismatch, processor mismatch, identity conflict, abnormal refunds and abnormal chargebacks. Fraud risk is independent of credit risk.

## Continuity methodology

Baseline continuity uses accepted M1.4 processor and connection states only after the governed processor-account opening date. Stress continuity uses the same eligible operating window in the accepted M1.6 `RECESSION_ENERGY` scenario. Continuity tiers use the effective-dated M1.8 policy profile.

## Performance design

- accepted physical histories are aggregated once;
- 750-row inputs are materialized and indexed;
- no M1.4–M1.7 blueprint regeneration;
- expected canonical rows are materialized once during generation;
- validation and reporting recompute hashes from persisted physical rows only;
- `ANALYZE` occurs after persistence;
- JIT is disabled and work memory is bounded.

## Boundaries

M1.8 is synthetic strategy evidence, not actual KYB, AML, sanctions, identity, fraud, processor-security or regulatory certification. It does not create a credit decision or adverse action.


## Accepted v0.2R1 processor-continuity methodology

The accepted method is `M1_8_METHOD_V1_1`. Baseline and stressed processor rates are calculated independently from accepted physical histories. Because the scenario is adverse, the final interpreted stressed continuity tier is floored to the accepted baseline tier:

```text
Final Stress Tier = greatest(Baseline Tier, Independently Classified Stress Tier)
```

This control prevents adverse-scenario interpretation from producing a lower risk tier while preserving all observed rates and atomic verification evidence.
