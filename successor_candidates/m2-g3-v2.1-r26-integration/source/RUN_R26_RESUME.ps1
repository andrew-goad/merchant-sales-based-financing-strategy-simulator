$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $Root

Write-Host "MSBF R26 R3 retained-final M2.11-M2.12/G3-v2 resume"
Write-Host "Retained R2 final: msbf_r1_r26_g3v2_20260902_024119 (read-only predecessor; do not modify)"
Write-Host "Immutable R6: msbf_r1_m2_4_r6_20260830_030634"
Write-Host "This path does NOT rerun M2.5-M2.10."

if (Test-Path ".\results\*.zip") {
    throw "A resume result ZIP already exists. Do not rerun this frozen resume package. Return the existing result evidence."
}

$Python = (Get-Command python.exe -ErrorAction SilentlyContinue)
if (-not $Python) { $Python = (Get-Command python -ErrorAction SilentlyContinue) }
if (-not $Python) { throw "Python executable not found in PATH." }
$PythonExe = $Python.Source

Write-Host "Validating frozen resume package..."
& $PythonExe ".\src\validate_resume_package.py"
if ($LASTEXITCODE -ne 0) { throw ("Resume package validation failed with exit code {0}." -f $LASTEXITCODE) }

$SecurePassword = Read-Host "PostgreSQL password for local user postgres (not stored)" -AsSecureString
$BSTR = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePassword)
try {
    $PlainPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    $env:PGPASSWORD = $PlainPassword
    $PyArgs = @(
        ".\src\resume_r26.py",
        "--source-db", "msbf_r1_m2_4_r6_20260830_030634",
        "--retained-final-db", "msbf_r1_r26_g3v2_20260902_024119",
        "--pg-bin", "C:\Program Files\PostgreSQL\17\bin",
        "--host", "localhost", "--port", "5432", "--user", "postgres"
    )
    & $PythonExe @PyArgs
    $Code = $LASTEXITCODE
} finally {
    $env:PGPASSWORD = $null
    if ($BSTR -ne [IntPtr]::Zero) { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR) }
    $PlainPassword = $null
}

if ($Code -ne 0) {
    throw "R26 retained-final resume stopped fail-closed. Do not rerun it and do not manually repair either retained database. Upload the generated result ZIP and sidecar from .\results."
}
Write-Host "PASS. Upload the generated *_M2_11_M2_12_G3V2_RESULTS.zip and sidecar from .\results."
