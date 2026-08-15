# M2.11 R11 acceptance hash-reconstruction static audit

```text
Correction controls                   44 / 44 PASS
Failures                               0
Program 217 requirements               45
Canonical families reconstructed       19
Live positive controls                120 / 120 PASS
Live negative controls                 20 / 20 PASS
```

## Root-cause control

The superseded Program 217 used the canonical hash-source view's text `business_key` ordering. Five families used a different component order than Program 214/215, exactly matching the five live set-hash mismatches. R11 reconstructs all nineteen hashes directly from target-typed physical fields and exact governed order.

## Scope

Only Program 217, Acceptance Requirement Matrix rows 029/031, and affected governance/package records changed. Programs 212–216 and 218–219 and all recoveries remain byte-identical.

No PostgreSQL execution was performed during correction construction.
