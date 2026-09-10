# MSBF R26 R3 retained-final resume

This package resumes only M2.11-M2.12/G3-v2 from the exact retained R26 R2 final database. It does **not** rerun M2.5-M2.10.

Required local databases:

- `msbf_r1_m2_4_r6_20260830_030634` — immutable R6.
- `msbf_r1_r26_g3v2_20260902_024119` — exact retained R2 final, read-only predecessor.

Run once:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
cd C:\MSBF\R26_R3_RESUME
.\RUN_R26_RESUME.ps1
```

Do not rerun R17, R19, R26 R2, or the interrupted full R3. Do not manually modify or delete the retained R2 final before this resume completes.
