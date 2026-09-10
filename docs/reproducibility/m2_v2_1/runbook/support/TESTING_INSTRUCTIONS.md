# Reproduce the toolkit tests

The new tools use Python standard library only. Keep reports outside the frozen package. Source-owned runtime/input archives remain separate dependencies.

```powershell
$env:PYTHONDONTWRITEBYTECODE = "1"
$env:MSBF_GOLDEN_RESULT = "C:\MSBF\in\msbf_r1_r26_resume_20260902_070655_M2_11_M2_12_G3V2_RESULTS.zip"
$env:MSBF_PBIX = "C:\MSBF\pbi_r3\release\MSBF_Merchant_Credit_Intelligence_M2_v2.1.0-rc2.pbix"
python -B "C:\MSBF\runbook\tests\test_runbook_checks.py"
if ($LASTEXITCODE -ne 0) { throw "Toolkit tests failed" }
```

All 43 tests were executed with real accepted evidence in this delivery. Running without those environment variables skips the real-input cases; a skipped test is not a passed test. The test suite only mutates temporary fixture copies and never contacts a database.

`tools/offline_replay.py` additionally runs the exact frozen source-owned simulation/canonicalization code under external-call guards. Its full result is retained separately from the unit-test log. Power BI identity inspection reads its ZIP members; it never opens Desktop.

The read-only SQL preflight was source-reviewed but not executed against a PostgreSQL server here. Windows command blocks and the original launcher are not represented as locally Windows-tested by this build. Complete WINDOWS_QUALIFICATION_CHECKLIST.md for those claims.

Six additional environment-probe tests use mocked binary identities to test wrong/missing tool versions and output preservation. Run `python -B tests/test_environment_probe.py` from the runbook root. These tests do not establish Windows qualification. The actual local environment probe correctly returned HOLD on this Linux host with no PostgreSQL/PowerShell runtime installed.
