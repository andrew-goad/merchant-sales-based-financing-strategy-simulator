# M1.13 Accepted Release Notes — v0.2R1

M1.13 is **PASSED AND ACCEPTED**.

Accepted scope includes:

- 93,720 scenario-aware daily contractual-receivable exposure-path rows;
- 1,500 exposure/recovery/loss snapshots;
- path-weighted comparative EAD;
- industry and scenario LGD foundations;
- explicit recovery evidence states;
- simple and schedule-adjusted comparative expected loss;
- 82 positive controls and seven negative controls;
- exact deterministic reconciliation across 95,220 canonical entities.

The v0.2R1 correction replaces two unsupported `max(boolean)` expressions in generation
with governed `bool_or(boolean)` aggregation. The original v0.2 failure occurred before
persistent generation and did not alter accepted predecessor data.

Next authorized module: M1.14 — Unit Economics & Risk-Adjusted Contribution Foundations.
