# Quick Start — MSBF independent execution

**The rule:** choose a route, verify the exact input, execute once, compare the checkpoint, preserve the evidence. Never retry an unknown state.

## Start here

1. **Choose scope.** Route A = offline code reproduction; Route B = approved retained-checkpoint database replay; Route C = view accepted Power BI. Route D, the final empty-database build, is not yet qualified.
2. **Prepare.** Put the runbook at `C:\MSBF\runbook`, inputs at `C:\MSBF\in`, and evidence in a new dated folder. Check the runbook ZIP/sidecar and internal manifest (procedure page 3).
3. **Verify inputs.** Use `runbook_checks.py verify` and the pinned component ID. Stop on any mismatch or existing extraction destination.
4. **Execute.** Route A: `offline_replay.py` over the exact `R26_R3_RESUME` source; no database required (page 4). Route B: original `RUN_R26_RESUME.ps1`, once, only after pages 5–6 entry checks. Route C: validate and open a copy, no refresh/save (page 9).
5. **Reconcile.** `runbook_checks.py reconcile` checks the result against the accepted R26 reference. Runtime success alone is insufficient.
6. **Retain.** Save run record, logs, result ZIP, sidecar, checker reports and exceptions. Seal the evidence outside its folder (page 13).
7. **Review.** A separate reviewer records the tested scope, result, limitations and disposition. Final release binding and Windows qualification must close before claiming end-to-end clean-start readiness.

## Smallest software set

Route A: Python only. Route B: Python + PowerShell 7 + PostgreSQL 17 server/clients + exact approved checkpoint databases. Route C: Python for identity checks + Power BI Desktop for viewing. DBeaver is optional.

## What is required but not in this small ZIP

- Source runtime: `MSBF_R26_R3_RETAINED_FINAL_RESUME_RUNTIME_20260902.zip`.
- Accepted output: `msbf_r1_r26_resume_20260902_070655_M2_11_M2_12_G3V2_RESULTS.zip`.
- Power BI route: `MSBF_MCI_POWER_BI_GITHUB_PUBLICATION_SUPPORT_R3_20260904.zip`.

Exact sizes/hashes are in `registers/COMPONENT_LOCK.json`; commands are in [the complete procedure](REPRODUCIBILITY_AND_EXECUTION.md). Those inputs retain their own public/private classifications.

## Stop / protect

Stop on first error. Do not Retry/Skip, reset statuses, delete schemas, rerun an interrupted package or execute recovery without a specific disposition. Never use the accepted final as a write target. Keep credentials out of logs. Preserve the original Power BI bytes and the existing P01–P04-only scope.
