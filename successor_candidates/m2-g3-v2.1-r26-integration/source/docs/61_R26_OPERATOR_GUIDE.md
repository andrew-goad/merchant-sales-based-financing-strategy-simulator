# R26 R3 Operator Guide

## R1 launcher failure boundary

R26 R1 failed before execution because of a PowerShell parser defect. R26 R2 corrected that launcher and then physically completed compiler M2.5–M2.12 and final M2.5–M2.10 before stopping fail-closed at the final M2.11 simulation-identity gate. R2 evidence proves the Wave A business exports were deterministic; the mismatch was caused by raw execution timestamps and compiler/final role metadata being included in the M2.11 source identity. R3 canonicalizes only that evidence-identity boundary. The approved R26 monitoring policy and M2.5–M2.12 business methods are unchanged.

## Purpose

Run the owner-approved M2.5 monitoring-calibration correction through the complete M2.5–M2.12/G3-v2 successor chain using a fresh compiler clone and a separate fresh final clone from immutable R6.

## Prerequisites

- Windows PowerShell.
- Python 3.x available as `python` or `py -3`.
- PostgreSQL 17 client tools under `C:\Program Files\PostgreSQL\17\bin` unless overridden.
- Local PostgreSQL database `msbf_r1_m2_4_r6_20260830_030634` present and unchanged.
- User `postgres` can authenticate locally.

## Exact command

```powershell
Set-ExecutionPolicy -Scope Process Bypass
cd C:\MSBF\R26_R3
.\RUN_R26.ps1
```

The launcher validates the frozen package before requesting the PostgreSQL password. The password is placed only in the current process environment and removed in `finally`; it is not written to disk.

## Expected execution architecture

1. Validate immutable R6 source control and normalized schema fingerprint.
2. Create fresh compiler `msbf_r1_r26_compile_<timestamp>`.
3. Execute M2.5 V2 correction and M2.6–M2.10 successor path.
4. Enforce R26 physical policy/calibration controls.
5. Build new M2.11 eight-profile simulation and M2.12/G3-v2 certification with new source/report identities.
6. Only after full compiler PASS, drop compiler.
7. Create fresh final `msbf_r1_r26_g3v2_<timestamp>` from R6.
8. Re-perform M2.5–M2.12 exactly.
9. Require compiler/final exact normalized identity.
10. Reverify R6 nonmutation.
11. Retain the final database only after PASS.

## Fail-closed behavior

On any failure:

- stop immediately;
- do not modify R6;
- retain any created compiler/final database for diagnosis;
- write a result ZIP and SHA-256 sidecar;
- do not rerun R17, R19, or R26;
- return the generated R26 result ZIP and sidecar.

## PASS evidence

A PASS result must report, at minimum:

- `status = PASS`;
- `last_stage = COMPLETE`;
- `source_modified = false`;
- compiler dropped;
- final database retained;
- 15,600 M2.5 daily rows;
- 15,600 R26 operational-family rows;
- exact R26 checkpoint controls;
- 130 M2.6 paths and endpoint distribution 126 / 3 / 1;
- 52,152 candidate-profile evaluations;
- 12,000 application-profile simulations;
- 1,040 account-profile simulations;
- 70/70 G3-v2 certification controls;
- new R26 certification and report identities;
- compiler/final exact identity PASS.
