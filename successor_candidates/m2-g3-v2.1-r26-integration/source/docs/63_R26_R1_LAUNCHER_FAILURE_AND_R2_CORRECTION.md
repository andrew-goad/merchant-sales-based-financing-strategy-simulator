# R26 R1 launcher failure and R2 correction

## R1 physical result

R26 R1 did not begin runtime execution. Windows PowerShell rejected `RUN_R26.ps1` during parsing at the error-message interpolation:

```powershell
"Python command failed with exit code $LASTEXITCODE: ..."
```

PowerShell interpreted the colon immediately after `$LASTEXITCODE` as part of a scoped-variable reference. The script therefore failed before package validation, password entry, PostgreSQL connection, database clone creation, or M2.5 execution.

## R2 correction

R2 changes only the operator/validation packaging layer:

- replaces the ambiguous interpolation with format-string construction;
- resolves the Python executable into a scalar command variable before invocation;
- adds a static PowerShell variable-colon safety control to the package validator;
- changes the extraction directory to `C:\MSBF\R26_R2` to prevent contamination from the retired R1 folder; and
- preserves the exact approved R26 policy, Python runtime, transformed SQL, evidence carriers, immutable R6 source, and predecessor identities.

R1 is retired and must not be rerun. R2 is the sole operator package for the first database execution of R26.
