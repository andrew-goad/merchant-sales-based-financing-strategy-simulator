# M2.10 Program 207 Positive-Validation Correction — v0.2R3

## Root cause

`M2_10_POS_049_PERFORMANCE_RATES` contained one extra closing parenthesis in
its Boolean `coalesce(...)` argument. The malformed function call caused the
SQL-script parser to treat the large dollar-quoted positive-control block as
unterminated.

## Corrections

1. Removed the single extra closing parenthesis from POS_049.
2. Split the 120 controls into seven bounded, logically ordered DO blocks.
3. Preserved all 120 control codes, observations, thresholds, and business
   interpretations.
4. Updated Program 207A to v0.2R2 for post-rollback recovery verification.
5. Re-audited Programs 208–211 for balanced dollar tags, quotes, comments, and
   parentheses. No downstream changes were required.

## Execution resume

```text
Stop → ROLLBACK; → 207A v0.2R2 → 207 v0.2R2 → 208
```

Programs 204–206 remain authoritative and must not be rerun.
