# MSBF Campaign Readiness Rebase v0.2 — Accepted M2.12 Baseline

## Determination

**READ_ONLY_REBASE_COMPLETE_WITH_BLOCKERS**

```text
Accepted source boundary                 M2_12_ACCEPTED
Accepted full-project SHA-256            2d2524dae3802eb757197b75d7aeab94b64239cc2cb4585ff2599a728283a17a
Executable governed stages               30

Normal campaign positions                230
Physical normal sources                  229
Missing physical source positions          1  (M1.17 Program 127)
Normal source SHA-256 mismatches            0
M1.17 blocked campaign positions            8

Recovery/contingency catalog rows         128
Normal/recovery overlaps                    0
Automatic recovery rows                     0

Checkpoint inventory rows                174
Active checkpoint specifications         166
Existing compiled definitions            154
New checkpoints to compile                12

Report definitions                         56
Detailed result sets                      554
Total governed report result sets         582
New report definitions to compile           4
New result-retention rows to compile       50

SQL generated or changed                    0
PostgreSQL connections opened               0
Business SQL executions                     0
```

## Executive conclusion

The accepted M2.12 repository is structurally suitable for continued campaign
engineering and extends the prior plan cleanly from 214 to 230 normal positions. The
source and recovery inventories reconcile physically. The existing v0.1–v0.3 harness
architecture is substantially reusable.

The project is **not yet ready for the 750 golden replay or a 25,000-application run**.
The principal blocker remains the M1.17 clean-build source closure. Campaign identity,
counts, dates and expected results also require a governed configuration/overlay layer,
and the native read-only adapter requires real Windows/PostgreSQL certification.

## Exact next governed action

Begin `CR-WP1 — M1.17 Governed Clean-Build Source Closure` and `CR-WP2 — Campaign
Configuration & Expected-Results Freeze` as separate bounded work packages. They may
be designed in parallel, but no campaign SQL execution is authorized.
