# MSBF - Power BI Executive Portfolio Intelligence

Part 11 · [Conversation index](README.md) · [History home](../../README.md)

> Historical dialogue: commands and approvals below describe past events. They are not current execution or publication instructions. Attachment references do not establish recovered bytes.

[Previous part](part-10.md)
[Next part](part-12.md)

<a id="m-ab7746fb-ad08-4192-b39c-12523861a096"></a>
## Assistant · C091-M00132

C091-M00132 · 2026-08-19T20:56:56.792000-04:00 · active path

Preceding visible parent: [C091-M00131](part-10.md#m-27f590b8-ae3f-413e-b531-8f96bcc7bdfb)

<!-- BEGIN_SOURCE_MESSAGE -->
The UNC patch itself completed successfully. The failure occurred **afterward**, when PowerShell tried to launch the static verifier. Nothing in that verifier attempt changed the project.

The cause is straightforward: the earlier `Process = Bypass` setting applied only to the PowerShell process in which you set it. This is now a different PowerShell session/process, so execution policy reverted to the machine default. The A1b runbook still requires the static boundary verification before Desktop is reopened or any refresh occurs. [export reference: filecite | turn17file0 | L26-L39]

### 1. Re-enable the process-scoped policy only

Run:

```powershell
Set-ExecutionPolicy `
    -Scope Process `
    -ExecutionPolicy Bypass `
    -Force
```

Then confirm:

```powershell
Get-ExecutionPolicy -List
```

Expected relevant state:

```text
Process          Bypass
CurrentUser      Undefined
LocalMachine     RemoteSigned
```

Do not change `CurrentUser` or `LocalMachine`.

### 2. Unblock the scripts in the **working copy**

The initializer copied the tools into the A1b working root, so unblock those copies as well:

```powershell
$work = "C:\MSBF\MSBF_PBI_A1B_WORKING_R1_20260819"

Get-ChildItem `
    -LiteralPath "$work\tools" `
    -File `
    -Filter "*.ps1" |
    Unblock-File
```

### 3. Preserve this verifier-launch observation

This is worth recording because the UNC patch itself had already committed successfully:

```powershell
$return = Join-Path $work "evidence\local_engine_return"

@'
A1B POST-UNC-PATCH VERIFIER EXECUTION-POLICY OBSERVATION

Date: 2026-08-19

Operation:
Verify-A1bPreRefreshBoundary.ps1 after the dedicated UNC parameter patch.

Observed condition:
PowerShell blocked the verifier because script execution was disabled in the
current PowerShell process.

The prior Process-scope Bypass setting belonged to an earlier PowerShell
session and did not persist into this process.

The verifier did not start.
No project or evidence file was modified by the blocked verifier invocation.
The completed UNC parameter patch remains the current project state.

No Power BI Desktop refresh occurred.
No Power Query Refresh All occurred.
No Close & Apply occurred.
No model processing occurred.

Remediation:
Set ExecutionPolicy=Bypass for the current process only, unblock the working-copy
tool scripts, and rerun the static A1b pre-refresh boundary verifier.
'@ |
    Set-Content `
        -LiteralPath "$return\E00_POST_UNC_PATCH_VERIFIER_EXECUTION_POLICY_OBSERVATION.txt" `
        -Encoding utf8
```

### 4. Rerun the static boundary verifier

Now run:

```powershell
& "$work\tools\Verify-A1bPreRefreshBoundary.ps1" `
    -PackageRoot $work *>&1 |
    Tee-Object `
        -FilePath "$return\E00_A1B_PRE_REFRESH_BOUNDARY_AFTER_UNC_PATCH.txt"
```

We need it to remain exactly:

```text
tables                    32
relationships             32
power_query_objects       79
measures                  60

a1b_tables                18
a1b_relationships         26
a1b_power_query_objects   32
a1b_measures              60

technical_shell_pages      1
visuals                    0

inactive_relationships:
REL-076 only

bidirectional_relationships:
none

scenario_code_relationships:
none
```

and the roots must now resolve to:

```text
pDataRoot:
\\localhost\MSBF_PBI_A1B_SYNTHETIC\pbi

pBuildRoot:
\\localhost\MSBF_PBI_A1B_SYNTHETIC\build
```

### Current state

The important chronology is:

```text
Failed first raw patch                 NONMUTATING — proven by hash
Correct UNC patch                      PASS
Embedded/external parameter parity     PASS
Before/after hashes                     CAPTURED
UNC share                              PASS / READ-ONLY
Static boundary re-verification        NOT YET EXECUTED
Desktop reopen                         NOT AUTHORIZED YET
Refresh Preview                         PROHIBITED
```

So **do not reopen Power BI yet**. Send me the full output from the rerun of `Verify-A1bPreRefreshBoundary.ps1`; if it passes, we proceed directly to reopening Desktop and getting the UNC privacy source registered.
<!-- END_SOURCE_MESSAGE -->


<a id="m-ffc72e92-b5ef-4bcd-b7a2-87d5b995ba54"></a>
## Andrew / user · C091-M00133

C091-M00133 · 2026-08-19T21:03:06.219000-04:00 · active path

Preceding visible parent: [C091-M00132](part-11.md#m-ab7746fb-ad08-4192-b39c-12523861a096)

<!-- BEGIN_SOURCE_MESSAGE -->
note i am still using the powershell 5.1 administrator vs the powershell 7 we had been using: PS C:\WINDOWS\system32> Get-ExecutionPolicy -List

        Scope ExecutionPolicy
        ----- ---------------
MachinePolicy       Undefined
   UserPolicy       Undefined
      Process          Bypass
  CurrentUser       Undefined
 LocalMachine       Undefined


PS C:\WINDOWS\system32> $work = "C:\MSBF\MSBF_PBI_A1B_WORKING_R1_20260819"
>>
>> Get-ChildItem `
>>     -LiteralPath "$work\tools" `
>>     -File `
>>     -Filter "*.ps1" |
>>     Unblock-File
PS C:\WINDOWS\system32> $return = Join-Path $work "evidence\local_engine_return"
>>
>> @'
>> A1B POST-UNC-PATCH VERIFIER EXECUTION-POLICY OBSERVATION
>>
>> Date: 2026-08-19
>>
>> Operation:
>> Verify-A1bPreRefreshBoundary.ps1 after the dedicated UNC parameter patch.
>>
>> Observed condition:
>> PowerShell blocked the verifier because script execution was disabled in the
>> current PowerShell process.
>>
>> The prior Process-scope Bypass setting belonged to an earlier PowerShell
>> session and did not persist into this process.
>>
>> The verifier did not start.
>> No project or evidence file was modified by the blocked verifier invocation.
>> The completed UNC parameter patch remains the current project state.
>>
>> No Power BI Desktop refresh occurred.
>> No Power Query Refresh All occurred.
>> No Close & Apply occurred.
>> No model processing occurred.
>>
>> Remediation:
>> Set ExecutionPolicy=Bypass for the current process only, unblock the working-copy
>> tool scripts, and rerun the static A1b pre-refresh boundary verifier.
>> '@ |
>>     Set-Content `
>>         -LiteralPath "$return\E00_POST_UNC_PATCH_VERIFIER_EXECUTION_POLICY_OBSERVATION.txt" `
>>         -Encoding utf8
PS C:\WINDOWS\system32> & "$work\tools\Verify-A1bPreRefreshBoundary.ps1" `
>>     -PackageRoot $work *>&1 |
>>     Tee-Object `
>>         -FilePath "$return\E00_A1B_PRE_REFRESH_BOUNDARY_AFTER_UNC_PATCH.txt"
{
    "tables":  32,
    "relationships":  32,
    "named_expressions":  47,
    "partitions":  32,
    "power_query_objects":  79,
    "measures":  60,
    "a1b_tables":  18,
    "a1b_relationships":  26,
    "a1b_power_query_objects":  32,
    "a1b_measures":  60,
    "exact_a1b_tables":  true,
    "exact_a1b_relationships":  true,
    "exact_a1b_queries":  true,
    "exact_a1b_measures":  true,
    "technical_shell_pages":  1,
    "page_display_names":  [
                               "A1A_TECHNICAL_SHELL_NO_VISUALS"
                           ],
    "visuals":  0,
    "bookmarks":  0,
    "inactive_relationships":  [
                                   "REL-076"
                               ],
    "bidirectional_relationships":  [

                                    ],
    "scenario_code_relationships":  [

                                    ],
    "pDataRoot":  "\"\\\\localhost\\MSBF_PBI_A1B_SYNTHETIC\\pbi\" meta [IsParameterQuery=true, Type=\"Text\", IsParameterQueryRequired=true]",
    "pBuildRoot":  "\"\\\\localhost\\MSBF_PBI_A1B_SYNTHETIC\\build\" meta [IsParameterQuery=true, Type=\"Text\", IsParameterQueryRequired=true]"
}
A1b pre-refresh boundary HOLD: pDataRoot, pBuildRoot
At C:\MSBF\MSBF_PBI_A1B_WORKING_R1_20260819\tools\Verify-A1bPreRefreshBoundary.ps1:62 char:26
+ ... ount -gt 0){throw "A1b pre-refresh boundary HOLD: $($fail -join ', ') ...
+                 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : OperationStopped: (A1b pre-refresh...oot, pBuildRoot:String) [], RuntimeException
    + FullyQualifiedErrorId : A1b pre-refresh boundary HOLD: pDataRoot, pBuildRoot
<!-- END_SOURCE_MESSAGE -->


<a id="m-47502d6a-af68-4f18-a1e8-e78796fb2391"></a>
## Assistant · C091-M00134

C091-M00134 · 2026-08-19T21:03:28.664606-04:00 · active path

Preceding visible parent: [C091-M00133](part-11.md#m-ffc72e92-b5ef-4bcd-b7a2-87d5b995ba54)

<!-- BEGIN_SOURCE_MESSAGE -->
This is a **verifier-definition mismatch, not an A1b model boundary failure**.

Your output proves the semantic boundary itself is still exactly correct:

```text
32 tables
32 relationships
79 Power Query objects
60 measures

18 A1b tables
26 A1b relationships
32 A1b Power Query objects
60 A1b measures

1 technical shell
0 visuals
REL-076 only inactive
0 bidirectional relationships
0 scenario_code relationships
```

And the verifier is reading the new dedicated roots correctly:

```text
pDataRoot  = \\localhost\MSBF_PBI_A1B_SYNTHETIC\pbi
pBuildRoot = \\localhost\MSBF_PBI_A1B_SYNTHETIC\build
```

It is holding only because `Verify-A1bPreRefreshBoundary.ps1` was authored when the package expected `S:\pbi` / `S:\build`. Independent Audit, however, authorizes changing **only** `pDataRoot` and `pBuildRoot` to dedicated governed synthetic roots; it does not require those roots to remain `S:`. [export reference: filecite | turn19file3 | L244-L255] The governing construction prompt likewise says the two parameters must be dedicated MSBF synthetic roots and specifically prohibits `C:\` as the privacy boundary. [export reference: filecite | turn19file7 | L569-L588]

So: **do not revert the UNC patch. Do not reopen Desktop yet.** We should correct the verifier only, preserve its predecessor, then rerun it.

Also, PowerShell 5.1 Administrator is fine for this immediate verifier repair. Your current process already has `ExecutionPolicy = Bypass`; no further policy change is needed.

### 1. Inspect exactly how the verifier tests the roots

Run this first, read-only:

```powershell
$work = "C:\MSBF\MSBF_PBI_A1B_WORKING_R1_20260819"

$verifier = Join-Path $work `
    "tools\Verify-A1bPreRefreshBoundary.ps1"

Select-String `
    -LiteralPath $verifier `
    -Pattern 'pDataRoot|pBuildRoot|S:\\pbi|S:\\build' `
    -Context 3,3 |
    Format-List
```

Then also:

```powershell
$lines = Get-Content -LiteralPath $verifier

for ($i = 0; $i -lt $lines.Count; $i++) {
    if (
        $lines[$i] -match 'pDataRoot' -or
        $lines[$i] -match 'pBuildRoot' -or
        $lines[$i] -match 'S:\\pbi' -or
        $lines[$i] -match 'S:\\build'
    ) {
        "{0,4}: {1}" -f ($i + 1), $lines[$i]
    }
}
```

Paste that output to me before editing.

### Why I want this one inspection step

We already know the verifier itself reaches the right model values. The only question is whether its final predicates are written as something like:

```powershell
$pDataRoot -ne '"S:\pbi" meta [...]'
$pBuildRoot -ne '"S:\build" meta [...]'
```

or use regex/substring logic.

I do **not** want to blindly replace `S:\` text in an audit-control script without seeing the exact two predicates. The proper repair should change only the verifier's allowed-root expectation, not weaken any other control.

### 2. Preserve the current HOLD as a verifier-observation

You can record this now:

```powershell
$return = Join-Path $work "evidence\local_engine_return"

@'
A1B POST-UNC-PATCH STATIC VERIFIER ROOT-EXPECTATION OBSERVATION

Date: 2026-08-19

Operation:
Verify-A1bPreRefreshBoundary.ps1 after authorized pDataRoot/pBuildRoot change
from S:\ paths to the dedicated local SMB synthetic root.

Physical verifier results before the final predicate:
- tables = 32
- relationships = 32
- power_query_objects = 79
- measures = 60
- A1b tables = 18
- A1b relationships = 26
- A1b Power Query objects = 32
- A1b measures = 60
- exact A1b object identities = true
- technical shell pages = 1
- visuals = 0
- bookmarks = 0
- sole inactive relationship = REL-076
- bidirectional relationships = 0
- scenario_code relationships = 0

The verifier also read:
pDataRoot =
\\localhost\MSBF_PBI_A1B_SYNTHETIC\pbi

pBuildRoot =
\\localhost\MSBF_PBI_A1B_SYNTHETIC\build

Final verifier disposition:
HOLD on pDataRoot and pBuildRoot only.

Interpretation:
The project satisfies the semantic/object boundary, but the verifier appears
to retain its predecessor S:\ root expectation. Independent Audit permits
pDataRoot and pBuildRoot to change to dedicated governed synthetic roots.

No Desktop reopen occurred after the UNC patch.
No Refresh Preview occurred.
No Close & Apply occurred.
No Desktop refresh or semantic processing occurred.

Next action:
Inspect and, if confirmed, correct only the verifier root-acceptance predicates
to the exact authorized UNC roots; preserve the original verifier and rerun.
'@ |
    Set-Content `
        -LiteralPath "$return\E00_UNC_ROOT_VERIFIER_EXPECTATION_OBSERVATION.txt" `
        -Encoding utf8
```

### Current status

```text
Accepted A1a baseline                     PASS
A1b semantic/object boundary              PASS
UNC SMB root creation                     PASS
Read-only share access                    PASS
UNC pDataRoot/pBuildRoot patch            PASS
Embedded/external parity                  PASS
Failed first patch nonmutation            PASS
Static verifier object controls           PASS
Static verifier root predicate            HOLD — likely stale S:\ expectation
Desktop reopen                            WAIT
Refresh Preview                           PROHIBITED
```

This is the correct place to stop. Send me the `Select-String` / numbered-line output from the verifier; then I can give you the **exact two-line verifier correction** rather than guessing.
<!-- END_SOURCE_MESSAGE -->


<a id="m-e12734e1-69d1-4a19-a50e-08a196ba6459"></a>
## Andrew / user · C091-M00135

C091-M00135 · 2026-08-19T21:09:07.285000-04:00 · active path

Preceding visible parent: [C091-M00134](part-11.md#m-47502d6a-af68-4f18-a1e8-e78796fb2391)

<!-- BEGIN_SOURCE_MESSAGE -->
PS C:\WINDOWS\system32> $work = "C:\MSBF\MSBF_PBI_A1B_WORKING_R1_20260819"
>>
>> $verifier = Join-Path $work `
>>     "tools\Verify-A1bPreRefreshBoundary.ps1"
>>
>> Select-String `
>>     -LiteralPath $verifier `
>>     -Pattern 'pDataRoot|pBuildRoot|S:\\pbi|S:\\build' `
>>     -Context 3,3 |
>>     Format-List


IgnoreCase : True
LineNumber : 33
Line       : $pDataExpr=string (historical reference: `@($expr|Where-Object name -eq 'pDataRoot'`; referenced bytes not established here)[0].expression)
Filename   : Verify-A1bPreRefreshBoundary.ps1
Path       : C:\MSBF\MSBF_PBI_A1B_WORKING_R1_20260819\tools\Verify-A1bPreRefreshBoundary.ps1
Pattern    : pDataRoot|pBuildRoot|S:\\pbi|S:\\build
Context    : Microsoft.PowerShell.Commands.MatchInfoContext
Matches    : {0}

IgnoreCase : True
LineNumber : 34
Line       : $pBuildExpr=string (historical reference: `@($expr|Where-Object name -eq 'pBuildRoot'`; referenced bytes not established here)[0].expression)
Filename   : Verify-A1bPreRefreshBoundary.ps1
Path       : C:\MSBF\MSBF_PBI_A1B_WORKING_R1_20260819\tools\Verify-A1bPreRefreshBoundary.ps1
Pattern    : pDataRoot|pBuildRoot|S:\\pbi|S:\\build
Context    : Microsoft.PowerShell.Commands.MatchInfoContext
Matches    : {0}

IgnoreCase : True
LineNumber : 43
Line       :  pDataRoot=$pDataExpr;pBuildRoot=$pBuildExpr
Filename   : Verify-A1bPreRefreshBoundary.ps1
Path       : C:\MSBF\MSBF_PBI_A1B_WORKING_R1_20260819\tools\Verify-A1bPreRefreshBoundary.ps1
Pattern    : pDataRoot|pBuildRoot|S:\\pbi|S:\\build
Context    : Microsoft.PowerShell.Commands.MatchInfoContext
Matches    : {0}

IgnoreCase : True
LineNumber : 60
Line       : if($pDataExpr -ne '"S:\pbi" meta [IsParameterQuery=true, Type="Text", IsParameterQueryRequired=true]'){$fail+='pDataRoot'}
Filename   : Verify-A1bPreRefreshBoundary.ps1
Path       : C:\MSBF\MSBF_PBI_A1B_WORKING_R1_20260819\tools\Verify-A1bPreRefreshBoundary.ps1
Pattern    : pDataRoot|pBuildRoot|S:\\pbi|S:\\build
Context    : Microsoft.PowerShell.Commands.MatchInfoContext
Matches    : {0}

IgnoreCase : True
LineNumber : 61
Line       : if($pBuildExpr -ne '"S:\build" meta [IsParameterQuery=true, Type="Text", IsParameterQueryRequired=true]'){$fail+='pBuildRoot'}
Filename   : Verify-A1bPreRefreshBoundary.ps1
Path       : C:\MSBF\MSBF_PBI_A1B_WORKING_R1_20260819\tools\Verify-A1bPreRefreshBoundary.ps1
Pattern    : pDataRoot|pBuildRoot|S:\\pbi|S:\\build
Context    : Microsoft.PowerShell.Commands.MatchInfoContext
Matches    : {0}



PS C:\WINDOWS\system32> $lines = Get-Content -LiteralPath $verifier
>>
>> for ($i = 0; $i -lt $lines.Count; $i++) {
>>     if (
>>         $lines[$i] -match 'pDataRoot' -or
>>         $lines[$i] -match 'pBuildRoot' -or
>>         $lines[$i] -match 'S:\\pbi' -or
>>         $lines[$i] -match 'S:\\build'
>>     ) {
>>         "{0,4}: {1}" -f ($i + 1), $lines[$i]
>>     }
>> }
  33: $pDataExpr=string (historical reference: `@($expr|Where-Object name -eq 'pDataRoot'`; referenced bytes not established here)[0].expression)
  34: $pBuildExpr=string (historical reference: `@($expr|Where-Object name -eq 'pBuildRoot'`; referenced bytes not established here)[0].expression)
  43:  pDataRoot=$pDataExpr;pBuildRoot=$pBuildExpr
  60: if($pDataExpr -ne '"S:\pbi" meta [IsParameterQuery=true, Type="Text", IsParameterQueryRequired=true]'){$fail+='pDataRoot'}
  61: if($pBuildExpr -ne '"S:\build" meta [IsParameterQuery=true, Type="Text", IsParameterQueryRequired=true]'){$fail+='pBuildRoot'}
PS C:\WINDOWS\system32> $return = Join-Path $work "evidence\local_engine_return"
>>
>> @'
>> A1B POST-UNC-PATCH STATIC VERIFIER ROOT-EXPECTATION OBSERVATION
>>
>> Date: 2026-08-19
>>
>> Operation:
>> Verify-A1bPreRefreshBoundary.ps1 after authorized pDataRoot/pBuildRoot change
>> from S:\ paths to the dedicated local SMB synthetic root.
>>
>> Physical verifier results before the final predicate:
>> - tables = 32
>> - relationships = 32
>> - power_query_objects = 79
>> - measures = 60
>> - A1b tables = 18
>> - A1b relationships = 26
>> - A1b Power Query objects = 32
>> - A1b measures = 60
>> - exact A1b object identities = true
>> - technical shell pages = 1
>> - visuals = 0
>> - bookmarks = 0
>> - sole inactive relationship = REL-076
>> - bidirectional relationships = 0
>> - scenario_code relationships = 0
>>
>> The verifier also read:
>> pDataRoot =
>> \\localhost\MSBF_PBI_A1B_SYNTHETIC\pbi
>>
>> pBuildRoot =
>> \\localhost\MSBF_PBI_A1B_SYNTHETIC\build
>>
>> Final verifier disposition:
>> HOLD on pDataRoot and pBuildRoot only.
>>
>> Interpretation:
>> The project satisfies the semantic/object boundary, but the verifier appears
>> to retain its predecessor S:\ root expectation. Independent Audit permits
>> pDataRoot and pBuildRoot to change to dedicated governed synthetic roots.
>>
>> No Desktop reopen occurred after the UNC patch.
>> No Refresh Preview occurred.
>> No Close & Apply occurred.
>> No Desktop refresh or semantic processing occurred.
>>
>> Next action:
>> Inspect and, if confirmed, correct only the verifier root-acceptance predicates
>> to the exact authorized UNC roots; preserve the original verifier and rerun.
>> '@ |
>>     Set-Content `
>>         -LiteralPath "$return\E00_UNC_ROOT_VERIFIER_EXPECTATION_OBSERVATION.txt" `
>>         -Encoding utf8
<!-- END_SOURCE_MESSAGE -->


<a id="m-c72f6373-3a9f-43cb-b1ba-0a81ad0503fb"></a>
## Assistant · C091-M00136

C091-M00136 · 2026-08-19T21:09:10.621740-04:00 · active path

Preceding visible parent: [C091-M00135](part-11.md#m-e12734e1-69d1-4a19-a50e-08a196ba6459)

<!-- BEGIN_SOURCE_MESSAGE -->
Confirmed. The verifier is hard-coded to accept only the predecessor `S:\pbi` and `S:\build` values:

```text
Line 60 → S:\pbi
Line 61 → S:\build
```

That is now stale relative to the independently permitted source change. Audit explicitly allows `pDataRoot` and `pBuildRoot` to change **only to dedicated governed synthetic roots**, while keeping every other A1a source definition unchanged. [export reference: filecite | turn19file3 | L244-L255]

So the correct remediation is **verifier-only**: preserve the current verifier, replace exactly those two expected literals with the exact UNC roots, prove only two lines changed, and rerun. Do not change the project again.

## 1. Preserve the pre-correction verifier

Run:

```powershell
$work = "C:\MSBF\MSBF_PBI_A1B_WORKING_R1_20260819"
$return = Join-Path $work "evidence\local_engine_return"

$verifier = Join-Path $work `
    "tools\Verify-A1bPreRefreshBoundary.ps1"

$backup = "$verifier.PRE_UNC_ROOT_EXPECTATION_FIX_20260819"

Copy-Item `
    -LiteralPath $verifier `
    -Destination $backup `
    -Force

Write-Host "Verifier preserved:"
Write-Host $backup
```

Capture its SHA-256:

```powershell
$beforeVerifierHash = (
    Get-FileHash `
        -LiteralPath $verifier `
        -Algorithm SHA256
).Hash.ToLowerInvariant()

Write-Host "Verifier before SHA-256:"
Write-Host $beforeVerifierHash
```

## 2. Apply exactly the two authorized verifier changes

Run this exact block:

```powershell
$text = Get-Content `
    -LiteralPath $verifier `
    -Raw

$oldData = @'
if($pDataExpr -ne '"S:\pbi" meta [IsParameterQuery=true, Type="Text", IsParameterQueryRequired=true]'){$fail+='pDataRoot'}
'@.Trim()

$newData = @'
if($pDataExpr -ne '"\\localhost\MSBF_PBI_A1B_SYNTHETIC\pbi" meta [IsParameterQuery=true, Type="Text", IsParameterQueryRequired=true]'){$fail+='pDataRoot'}
'@.Trim()

$oldBuild = @'
if($pBuildExpr -ne '"S:\build" meta [IsParameterQuery=true, Type="Text", IsParameterQueryRequired=true]'){$fail+='pBuildRoot'}
'@.Trim()

$newBuild = @'
if($pBuildExpr -ne '"\\localhost\MSBF_PBI_A1B_SYNTHETIC\build" meta [IsParameterQuery=true, Type="Text", IsParameterQueryRequired=true]'){$fail+='pBuildRoot'}
'@.Trim()

$dataMatches = (
    [regex]::Matches(
        $text,
        [regex]::Escape($oldData)
    )
).Count

$buildMatches = (
    [regex]::Matches(
        $text,
        [regex]::Escape($oldBuild)
    )
).Count

Write-Host "Old pDataRoot predicate matches: " $dataMatches
Write-Host "Old pBuildRoot predicate matches:" $buildMatches

if ($dataMatches -ne 1 -or $buildMatches -ne 1) {
    throw "STOP: expected exactly one old root predicate for each parameter."
}

$text = $text.Replace($oldData,$newData)
$text = $text.Replace($oldBuild,$newBuild)

Set-Content `
    -LiteralPath $verifier `
    -Value $text `
    -Encoding utf8
```

Expected:

```text
Old pDataRoot predicate matches:  1
Old pBuildRoot predicate matches: 1
```

## 3. Prove only those two verifier lines changed

Run:

```powershell
$beforeLines = Get-Content -LiteralPath $backup
$afterLines  = Get-Content -LiteralPath $verifier

if ($beforeLines.Count -ne $afterLines.Count) {
    throw "STOP: verifier line count changed unexpectedly."
}

$diff = for ($i = 0; $i -lt $beforeLines.Count; $i++) {

    if ($beforeLines[$i] -cne $afterLines[$i]) {

        [pscustomobject]@{
            line_number = $i + 1
            before = $beforeLines[$i]
            after  = $afterLines[$i]
        }
    }
}

$diff | Format-Table -AutoSize -Wrap

if (@($diff).Count -ne 2) {
    throw "STOP: expected exactly two verifier-line changes."
}

if (
    @($diff | Select-Object -ExpandProperty line_number) -join "," -ne "60,61"
) {
    throw "STOP: changed verifier lines are not exactly 60 and 61."
}

$diff |
    Export-Csv `
        -LiteralPath "$return\E00_UNC_ROOT_VERIFIER_EXPECTATION_DIFF.csv" `
        -NoTypeInformation `
        -Encoding utf8

Write-Host "VERIFIER TWO-LINE CHANGE CONTROL PASS."
```

Required:

```text
line 60: S:\pbi   → \\localhost\MSBF_PBI_A1B_SYNTHETIC\pbi
line 61: S:\build → \\localhost\MSBF_PBI_A1B_SYNTHETIC\build

VERIFIER TWO-LINE CHANGE CONTROL PASS.
```

## 4. Record before/after verifier hashes

```powershell
$afterVerifierHash = (
    Get-FileHash `
        -LiteralPath $verifier `
        -Algorithm SHA256
).Hash.ToLowerInvariant()

[pscustomobject]@{
    event = "A1B_PRE_REFRESH_VERIFIER_UNC_ROOT_EXPECTATION_FIX"
    captured_local = (Get-Date).ToString("o")
    captured_utc = (Get-Date).ToUniversalTime().ToString("o")

    verifier_before_sha256 = $beforeVerifierHash
    verifier_after_sha256  = $afterVerifierHash

    changed_lines = @(60,61)

    pDataRoot_expected_before = "S:\pbi"
    pDataRoot_expected_after =
        "\\localhost\MSBF_PBI_A1B_SYNTHETIC\pbi"

    pBuildRoot_expected_before = "S:\build"
    pBuildRoot_expected_after =
        "\\localhost\MSBF_PBI_A1B_SYNTHETIC\build"

    project_modified_by_verifier_fix = $false
    semantic_logic_modified = $false

    refresh_executed = $false
    close_apply_executed = $false

    status = "VERIFIER_ONLY_CORRECTION"
} |
    ConvertTo-Json -Depth 6 |
    Set-Content `
        -LiteralPath "$return\E00_UNC_ROOT_VERIFIER_EXPECTATION_FIX.json" `
        -Encoding utf8
```

## 5. Verify the predicates now contain the exact UNC values

```powershell
Select-String `
    -LiteralPath $verifier `
    -Pattern 'pDataExpr -ne|pBuildExpr -ne' |
    Select-Object LineNumber,Line |
    Format-Table -AutoSize -Wrap
```

You should see exactly:

```text
60 ... "\\localhost\MSBF_PBI_A1B_SYNTHETIC\pbi" ...
61 ... "\\localhost\MSBF_PBI_A1B_SYNTHETIC\build" ...
```

## 6. Rerun the static pre-refresh verifier

Now rerun:

```powershell
& "$work\tools\Verify-A1bPreRefreshBoundary.ps1" `
    -PackageRoot $work *>&1 |
    Tee-Object `
        -FilePath "$return\E00_A1B_PRE_REFRESH_BOUNDARY_AFTER_UNC_PATCH_R2.txt"
```

The expected final result is a full PASS with:

```text
tables                    32
relationships             32
power_query_objects       79
measures                  60

a1b_tables                18
a1b_relationships         26
a1b_power_query_objects   32
a1b_measures              60

technical_shell_pages      1
visuals                    0
bookmarks                  0

inactive_relationships:
REL-076

bidirectional_relationships:
none

scenario_code_relationships:
none

pDataRoot:
\\localhost\MSBF_PBI_A1B_SYNTHETIC\pbi

pBuildRoot:
\\localhost\MSBF_PBI_A1B_SYNTHETIC\build
```

The governing audit explicitly permits only those two root changes and requires a stop for any other A1a source drift, object-count divergence, relationship defect, broad `C:\` privacy scope, or refresh failure. [export reference: filecite | turn19file7 | L581-L598]

### One note on PowerShell 5.1

Staying in **Windows PowerShell 5.1 Administrator** for this SMB/verifier portion is appropriate. The original package instructions used PowerShell 7 for general execution, but nothing in this verifier repair depends on PS7. Your current `Process = Bypass` is also scoped only to this session, which is the desired boundary.

Do **not reopen Desktop until this verifier returns PASS**. Send me the complete R2 verifier output next.
<!-- END_SOURCE_MESSAGE -->


<a id="m-7267c668-1c4a-4aea-9713-c99741e46590"></a>
## Andrew / user · C091-M00137

C091-M00137 · 2026-08-19T21:13:29.684000-04:00 · active path

Preceding visible parent: [C091-M00136](part-11.md#m-c72f6373-3a9f-43cb-b1ba-0a81ad0503fb)

<!-- BEGIN_SOURCE_MESSAGE -->
PS C:\WINDOWS\system32> $work = "C:\MSBF\MSBF_PBI_A1B_WORKING_R1_20260819"
>> $return = Join-Path $work "evidence\local_engine_return"
>>
>> $verifier = Join-Path $work `
>>     "tools\Verify-A1bPreRefreshBoundary.ps1"
>>
>> $backup = "$verifier.PRE_UNC_ROOT_EXPECTATION_FIX_20260819"
>>
>> Copy-Item `
>>     -LiteralPath $verifier `
>>     -Destination $backup `
>>     -Force
>>
>> Write-Host "Verifier preserved:"
>> Write-Host $backup
Verifier preserved:
C:\MSBF\MSBF_PBI_A1B_WORKING_R1_20260819\tools\Verify-A1bPreRefreshBoundary.ps1.PRE_UNC_ROOT_EXPECTATION_FIX_20260819
PS C:\WINDOWS\system32> $beforeVerifierHash = (
>>     Get-FileHash `
>>         -LiteralPath $verifier `
>>         -Algorithm SHA256
>> ).Hash.ToLowerInvariant()
>>
>> Write-Host "Verifier before SHA-256:"
>> Write-Host $beforeVerifierHash
Verifier before SHA-256:
4df2fd3264805b47e94095666f58e70a9f120f80e9ae45949acf37ac10a0a2fd
PS C:\WINDOWS\system32> $text = Get-Content `
>>     -LiteralPath $verifier `
>>     -Raw
>>
>> $oldData = @'
>> if($pDataExpr -ne '"S:\pbi" meta [IsParameterQuery=true, Type="Text", IsParameterQueryRequired=true]'){$fail+='pDataRoot'}
>> '@.Trim()
>>
>> $newData = @'
>> if($pDataExpr -ne '"\\localhost\MSBF_PBI_A1B_SYNTHETIC\pbi" meta [IsParameterQuery=true, Type="Text", IsParameterQueryRequired=true]'){$fail+='pDataRoot'}
>> '@.Trim()
>>
>> $oldBuild = @'
>> if($pBuildExpr -ne '"S:\build" meta [IsParameterQuery=true, Type="Text", IsParameterQueryRequired=true]'){$fail+='pBuildRoot'}
>> '@.Trim()
>>
>> $newBuild = @'
>> if($pBuildExpr -ne '"\\localhost\MSBF_PBI_A1B_SYNTHETIC\build" meta [IsParameterQuery=true, Type="Text", IsParameterQueryRequired=true]'){$fail+='pBuildRoot'}
>> '@.Trim()
>>
>> $dataMatches = (
>>     [regex]::Matches(
>>         $text,
>>         [regex]::Escape($oldData)
>>     )
>> ).Count
>>
>> $buildMatches = (
>>     [regex]::Matches(
>>         $text,
>>         [regex]::Escape($oldBuild)
>>     )
>> ).Count
>>
>> Write-Host "Old pDataRoot predicate matches: " $dataMatches
>> Write-Host "Old pBuildRoot predicate matches:" $buildMatches
>>
>> if ($dataMatches -ne 1 -or $buildMatches -ne 1) {
>>     throw "STOP: expected exactly one old root predicate for each parameter."
>> }
>>
>> $text = $text.Replace($oldData,$newData)
>> $text = $text.Replace($oldBuild,$newBuild)
>>
>> Set-Content `
>>     -LiteralPath $verifier `
>>     -Value $text `
>>     -Encoding utf8
Old pDataRoot predicate matches:  1
Old pBuildRoot predicate matches: 1
PS C:\WINDOWS\system32> $beforeLines = Get-Content -LiteralPath $backup
>> $afterLines  = Get-Content -LiteralPath $verifier
>>
>> if ($beforeLines.Count -ne $afterLines.Count) {
>>     throw "STOP: verifier line count changed unexpectedly."
>> }
>>
>> $diff = for ($i = 0; $i -lt $beforeLines.Count; $i++) {
>>
>>     if ($beforeLines[$i] -cne $afterLines[$i]) {
>>
>>         [pscustomobject]@{
>>             line_number = $i + 1
>>             before = $beforeLines[$i]
>>             after  = $afterLines[$i]
>>         }
>>     }
>> }
>>
>> $diff | Format-Table -AutoSize -Wrap
>>
>> if (@($diff).Count -ne 2) {
>>     throw "STOP: expected exactly two verifier-line changes."
>> }
>>
>> if (
>>     @($diff | Select-Object -ExpandProperty line_number) -join "," -ne "60,61"
>> ) {
>>     throw "STOP: changed verifier lines are not exactly 60 and 61."
>> }
>>
>> $diff |
>>     Export-Csv `
>>         -LiteralPath "$return\E00_UNC_ROOT_VERIFIER_EXPECTATION_DIFF.csv" `
>>         -NoTypeInformation `
>>         -Encoding utf8
>>
>> Write-Host "VERIFIER TWO-LINE CHANGE CONTROL PASS."
STOP: verifier line count changed unexpectedly.
At line:5 char:5
+     throw "STOP: verifier line count changed unexpectedly."
+     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : OperationStopped: (STOP: verifier ...d unexpectedly.:String) [], RuntimeException
    + FullyQualifiedErrorId : STOP: verifier line count changed unexpectedly.
<!-- END_SOURCE_MESSAGE -->


<a id="m-0610cfcf-03ed-4e19-9243-7211dba46ef1"></a>
## Assistant · C091-M00138

C091-M00138 · 2026-08-19T21:13:33.518713-04:00 · active path

Preceding visible parent: [C091-M00137](part-11.md#m-7267c668-1c4a-4aea-9713-c99741e46590)

<!-- BEGIN_SOURCE_MESSAGE -->
The stop is explainable and remains confined to the **verifier helper**, not the A1b project.

In Windows PowerShell 5.1, `Set-Content -Encoding utf8` can alter file serialization—most likely by adding a terminal newline and/or changing UTF-8 encoding characteristics. Your semantic project was not touched by this verifier edit. The correct response is to restore the verifier byte-for-byte from the preserved backup and redo the same two-line change using `.NET File.WriteAllText`, which will not add an extra line.

Do **not** reopen Desktop yet.

### 1. Diagnose the line-count difference, then restore the exact backup

Run:

```powershell
$work = "C:\MSBF\MSBF_PBI_A1B_WORKING_R1_20260819"
$return = Join-Path $work "evidence\local_engine_return"

$verifier = Join-Path $work `
    "tools\Verify-A1bPreRefreshBoundary.ps1"

$backup = "$verifier.PRE_UNC_ROOT_EXPECTATION_FIX_20260819"

$beforeLines = Get-Content -LiteralPath $backup
$afterLines  = Get-Content -LiteralPath $verifier

[pscustomobject]@{
    backup_lines  = $beforeLines.Count
    current_lines = $afterLines.Count
    difference    = $afterLines.Count - $beforeLines.Count
} | Format-List
```

Then restore the verifier exactly:

```powershell
Copy-Item `
    -LiteralPath $backup `
    -Destination $verifier `
    -Force

$restoredHash = (
    Get-FileHash `
        -LiteralPath $verifier `
        -Algorithm SHA256
).Hash.ToLowerInvariant()

$backupHash = (
    Get-FileHash `
        -LiteralPath $backup `
        -Algorithm SHA256
).Hash.ToLowerInvariant()

[pscustomobject]@{
    backup_sha256   = $backupHash
    restored_sha256 = $restoredHash
    exact_restore   = ($backupHash -ceq $restoredHash)
} | Format-List

if ($backupHash -cne $restoredHash) {
    throw "STOP: verifier did not restore byte-for-byte."
}

Write-Host "VERIFIER BYTE-FOR-BYTE RESTORE PASS."
```

Expected controlling hash:

```text
4df2fd3264805b47e94095666f58e70a9f120f80e9ae45949acf37ac10a0a2fd
```

### 2. Preserve this second verifier-tooling observation

```powershell
@'
A1B UNC ROOT VERIFIER SERIALIZATION OBSERVATION

Date: 2026-08-19

Operation:
Verifier-only correction of the pDataRoot/pBuildRoot expected values.

Observed condition:
The first verifier-only edit used Windows PowerShell 5.1 Set-Content
-Encoding utf8. The subsequent line-count control detected that the resulting
file line count differed from the preserved verifier.

The control stopped before the corrected verifier was executed.

No PBIP, model.bim, Power Query definition, semantic table, relationship,
measure, page, visual, or source data was changed by this condition.
No refresh or model processing occurred.

Remediation:
Restore Verify-A1bPreRefreshBoundary.ps1 byte-for-byte from its preserved
pre-correction backup and apply the same exact two predicate changes using
System.IO.File.WriteAllText so the original newline structure is preserved.
'@ |
    Set-Content `
        -LiteralPath "$return\E00_UNC_ROOT_VERIFIER_SERIALIZATION_OBSERVATION.txt" `
        -Encoding utf8
```

That evidence text itself may use normal PowerShell serialization; the concern applies to the **controlled executable verifier**, where we want exact line preservation.

### 3. Reapply the two changes without `Set-Content`

Now patch the restored verifier using raw text:

```powershell
$text = [IO.File]::ReadAllText($verifier)

$oldData = @'
if($pDataExpr -ne '"S:\pbi" meta [IsParameterQuery=true, Type="Text", IsParameterQueryRequired=true]'){$fail+='pDataRoot'}
'@.Trim()

$newData = @'
if($pDataExpr -ne '"\\localhost\MSBF_PBI_A1B_SYNTHETIC\pbi" meta [IsParameterQuery=true, Type="Text", IsParameterQueryRequired=true]'){$fail+='pDataRoot'}
'@.Trim()

$oldBuild = @'
if($pBuildExpr -ne '"S:\build" meta [IsParameterQuery=true, Type="Text", IsParameterQueryRequired=true]'){$fail+='pBuildRoot'}
'@.Trim()

$newBuild = @'
if($pBuildExpr -ne '"\\localhost\MSBF_PBI_A1B_SYNTHETIC\build" meta [IsParameterQuery=true, Type="Text", IsParameterQueryRequired=true]'){$fail+='pBuildRoot'}
'@.Trim()

$dataMatches = (
    [regex]::Matches(
        $text,
        [regex]::Escape($oldData)
    )
).Count

$buildMatches = (
    [regex]::Matches(
        $text,
        [regex]::Escape($oldBuild)
    )
).Count

Write-Host "Old pDataRoot predicate matches: " $dataMatches
Write-Host "Old pBuildRoot predicate matches:" $buildMatches

if ($dataMatches -ne 1 -or $buildMatches -ne 1) {
    throw "STOP: expected exactly one old predicate for each root."
}

$patched = $text.Replace($oldData,$newData)
$patched = $patched.Replace($oldBuild,$newBuild)

[IO.File]::WriteAllText(
    $verifier,
    $patched,
    [Text.UTF8Encoding]::new($false)
)

Write-Host "Verifier patched using File.WriteAllText."
```

### 4. Reperform the exact two-line control

```powershell
$beforeLines = Get-Content -LiteralPath $backup
$afterLines  = Get-Content -LiteralPath $verifier

[pscustomobject]@{
    before_lines = $beforeLines.Count
    after_lines  = $afterLines.Count
} | Format-List

if ($beforeLines.Count -ne $afterLines.Count) {
    throw "STOP: verifier line count still differs after controlled patch."
}

$diff = @(
    for ($i = 0; $i -lt $beforeLines.Count; $i++) {

        if ($beforeLines[$i] -cne $afterLines[$i]) {

            [pscustomobject]@{
                line_number = $i + 1
                before = $beforeLines[$i]
                after  = $afterLines[$i]
            }
        }
    }
)

$diff | Format-Table -AutoSize -Wrap

if ($diff.Count -ne 2) {
    throw "STOP: expected exactly two verifier-line changes; found $($diff.Count)."
}

$changedLineNumbers = (
    $diff |
    Select-Object -ExpandProperty line_number
) -join ","

if ($changedLineNumbers -ne "60,61") {
    throw "STOP: changed verifier lines are $changedLineNumbers; expected 60,61."
}

$diff |
    Export-Csv `
        -LiteralPath "$return\E00_UNC_ROOT_VERIFIER_EXPECTATION_DIFF.csv" `
        -NoTypeInformation `
        -Encoding utf8

Write-Host "VERIFIER TWO-LINE CHANGE CONTROL PASS."
```

Expected:

```text
before_lines = after_lines

60  S:\pbi   → \\localhost\MSBF_PBI_A1B_SYNTHETIC\pbi
61  S:\build → \\localhost\MSBF_PBI_A1B_SYNTHETIC\build

VERIFIER TWO-LINE CHANGE CONTROL PASS.
```

### 5. Record the corrected verifier identity

```powershell
$afterVerifierHash = (
    Get-FileHash `
        -LiteralPath $verifier `
        -Algorithm SHA256
).Hash.ToLowerInvariant()

[pscustomobject]@{
    event = "A1B_PRE_REFRESH_VERIFIER_UNC_ROOT_EXPECTATION_FIX"
    captured_local = (Get-Date).ToString("o")
    captured_utc = (Get-Date).ToUniversalTime().ToString("o")

    verifier_before_sha256 = $backupHash
    verifier_after_sha256  = $afterVerifierHash

    changed_lines = @(60,61)

    pDataRoot_expected_before = "S:\pbi"
    pDataRoot_expected_after =
        "\\localhost\MSBF_PBI_A1B_SYNTHETIC\pbi"

    pBuildRoot_expected_before = "S:\build"
    pBuildRoot_expected_after =
        "\\localhost\MSBF_PBI_A1B_SYNTHETIC\build"

    edit_method = "SYSTEM_IO_FILE_WRITEALLTEXT_UTF8_NO_BOM"
    project_modified_by_verifier_fix = $false
    semantic_logic_modified = $false
    refresh_executed = $false
    close_apply_executed = $false

    status = "VERIFIER_ONLY_TWO_LINE_CORRECTION"
} |
    ConvertTo-Json -Depth 6 |
    Set-Content `
        -LiteralPath "$return\E00_UNC_ROOT_VERIFIER_EXPECTATION_FIX.json" `
        -Encoding utf8

Write-Host "Verifier after SHA-256:"
Write-Host $afterVerifierHash
```

### 6. Finally rerun the verifier

```powershell
& "$work\tools\Verify-A1bPreRefreshBoundary.ps1" `
    -PackageRoot $work *>&1 |
    Tee-Object `
        -FilePath "$return\E00_A1B_PRE_REFRESH_BOUNDARY_AFTER_UNC_PATCH_R2.txt"
```

We still require the exact **32/32/79/60**, one shell, zero visuals, `REL-076` only inactive state, with the two UNC roots. Audit permits those two root changes but requires an immediate stop for other A1a source drift or object-count/relationship deviations. [export reference: filecite | turn19file3 | L244-L255]

Your current state is still safely bounded: the two root parameters are the only permitted A1a source changes, and **no refresh/model processing may occur until this pre-refresh control and the privacy evidence gate pass**. [export reference: filecite | turn19file7 | L569-L598]

Send me the final output from Step 6.
<!-- END_SOURCE_MESSAGE -->


<a id="m-fcecb8cb-7e47-4000-bce3-725130012880"></a>
## Andrew / user · C091-M00139

C091-M00139 · 2026-08-19T21:23:51.358000-04:00 · active path

Preceding visible parent: [C091-M00138](part-11.md#m-0610cfcf-03ed-4e19-9243-7211dba46ef1)

<!-- BEGIN_SOURCE_MESSAGE -->
PS C:\WINDOWS\system32> $work = "C:\MSBF\MSBF_PBI_A1B_WORKING_R1_20260819"
>> $return = Join-Path $work "evidence\local_engine_return"
>>
>> $verifier = Join-Path $work `
>>     "tools\Verify-A1bPreRefreshBoundary.ps1"
>>
>> $backup = "$verifier.PRE_UNC_ROOT_EXPECTATION_FIX_20260819"
>>
>> $beforeLines = Get-Content -LiteralPath $backup
>> $afterLines  = Get-Content -LiteralPath $verifier
>>
>> [pscustomobject]@{
>>     backup_lines  = $beforeLines.Count
>>     current_lines = $afterLines.Count
>>     difference    = $afterLines.Count - $beforeLines.Count
>> } | Format-List


backup_lines  : 67
current_lines : 68
difference    : 1



PS C:\WINDOWS\system32> Copy-Item `
>>     -LiteralPath $backup `
>>     -Destination $verifier `
>>     -Force
>>
>> $restoredHash = (
>>     Get-FileHash `
>>         -LiteralPath $verifier `
>>         -Algorithm SHA256
>> ).Hash.ToLowerInvariant()
>>
>> $backupHash = (
>>     Get-FileHash `
>>         -LiteralPath $backup `
>>         -Algorithm SHA256
>> ).Hash.ToLowerInvariant()
>>
>> [pscustomobject]@{
>>     backup_sha256   = $backupHash
>>     restored_sha256 = $restoredHash
>>     exact_restore   = ($backupHash -ceq $restoredHash)
>> } | Format-List
>>
>> if ($backupHash -cne $restoredHash) {
>>     throw "STOP: verifier did not restore byte-for-byte."
>> }
>>
>> Write-Host "VERIFIER BYTE-FOR-BYTE RESTORE PASS."


backup_sha256   : 4df2fd3264805b47e94095666f58e70a9f120f80e9ae45949acf37ac10a0a2fd
restored_sha256 : 4df2fd3264805b47e94095666f58e70a9f120f80e9ae45949acf37ac10a0a2fd
exact_restore   : True



VERIFIER BYTE-FOR-BYTE RESTORE PASS.
PS C:\WINDOWS\system32> @'
>> A1B UNC ROOT VERIFIER SERIALIZATION OBSERVATION
>>
>> Date: 2026-08-19
>>
>> Operation:
>> Verifier-only correction of the pDataRoot/pBuildRoot expected values.
>>
>> Observed condition:
>> The first verifier-only edit used Windows PowerShell 5.1 Set-Content
>> -Encoding utf8. The subsequent line-count control detected that the resulting
>> file line count differed from the preserved verifier.
>>
>> The control stopped before the corrected verifier was executed.
>>
>> No PBIP, model.bim, Power Query definition, semantic table, relationship,
>> measure, page, visual, or source data was changed by this condition.
>> No refresh or model processing occurred.
>>
>> Remediation:
>> Restore Verify-A1bPreRefreshBoundary.ps1 byte-for-byte from its preserved
>> pre-correction backup and apply the same exact two predicate changes using
>> System.IO.File.WriteAllText so the original newline structure is preserved.
>> '@ |
>>     Set-Content `
>>         -LiteralPath "$return\E00_UNC_ROOT_VERIFIER_SERIALIZATION_OBSERVATION.txt" `
>>         -Encoding utf8
PS C:\WINDOWS\system32> $text = [IO.File]::ReadAllText($verifier)
>>
>> $oldData = @'
>> if($pDataExpr -ne '"S:\pbi" meta [IsParameterQuery=true, Type="Text", IsParameterQueryRequired=true]'){$fail+='pDataRoot'}
>> '@.Trim()
>>
>> $newData = @'
>> if($pDataExpr -ne '"\\localhost\MSBF_PBI_A1B_SYNTHETIC\pbi" meta [IsParameterQuery=true, Type="Text", IsParameterQueryRequired=true]'){$fail+='pDataRoot'}
>> '@.Trim()
>>
>> $oldBuild = @'
>> if($pBuildExpr -ne '"S:\build" meta [IsParameterQuery=true, Type="Text", IsParameterQueryRequired=true]'){$fail+='pBuildRoot'}
>> '@.Trim()
>>
>> $newBuild = @'
>> if($pBuildExpr -ne '"\\localhost\MSBF_PBI_A1B_SYNTHETIC\build" meta [IsParameterQuery=true, Type="Text", IsParameterQueryRequired=true]'){$fail+='pBuildRoot'}
>> '@.Trim()
>>
>> $dataMatches = (
>>     [regex]::Matches(
>>         $text,
>>         [regex]::Escape($oldData)
>>     )
>> ).Count
>>
>> $buildMatches = (
>>     [regex]::Matches(
>>         $text,
>>         [regex]::Escape($oldBuild)
>>     )
>> ).Count
>>
>> Write-Host "Old pDataRoot predicate matches: " $dataMatches
>> Write-Host "Old pBuildRoot predicate matches:" $buildMatches
>>
>> if ($dataMatches -ne 1 -or $buildMatches -ne 1) {
>>     throw "STOP: expected exactly one old predicate for each root."
>> }
>>
>> $patched = $text.Replace($oldData,$newData)
>> $patched = $patched.Replace($oldBuild,$newBuild)
>>
>> [IO.File]::WriteAllText(
>>     $verifier,
>>     $patched,
>>     [Text.UTF8Encoding]::new($false)
>> )
>>
>> Write-Host "Verifier patched using File.WriteAllText."
Old pDataRoot predicate matches:  1
Old pBuildRoot predicate matches: 1
Verifier patched using File.WriteAllText.
PS C:\WINDOWS\system32> $beforeLines = Get-Content -LiteralPath $backup
>> $afterLines  = Get-Content -LiteralPath $verifier
>>
>> [pscustomobject]@{
>>     before_lines = $beforeLines.Count
>>     after_lines  = $afterLines.Count
>> } | Format-List
>>
>> if ($beforeLines.Count -ne $afterLines.Count) {
>>     throw "STOP: verifier line count still differs after controlled patch."
>> }
>>
>> $diff = @(
>>     for ($i = 0; $i -lt $beforeLines.Count; $i++) {
>>
>>         if ($beforeLines[$i] -cne $afterLines[$i]) {
>>
>>             [pscustomobject]@{
>>                 line_number = $i + 1
>>                 before = $beforeLines[$i]
>>                 after  = $afterLines[$i]
>>             }
>>         }
>>     }
>> )
>>
>> $diff | Format-Table -AutoSize -Wrap
>>
>> if ($diff.Count -ne 2) {
>>     throw "STOP: expected exactly two verifier-line changes; found $($diff.Count)."
>> }
>>
>> $changedLineNumbers = (
>>     $diff |
>>     Select-Object -ExpandProperty line_number
>> ) -join ","
>>
>> if ($changedLineNumbers -ne "60,61") {
>>     throw "STOP: changed verifier lines are $changedLineNumbers; expected 60,61."
>> }
>>
>> $diff |
>>     Export-Csv `
>>         -LiteralPath "$return\E00_UNC_ROOT_VERIFIER_EXPECTATION_DIFF.csv" `
>>         -NoTypeInformation `
>>         -Encoding utf8
>>
>> Write-Host "VERIFIER TWO-LINE CHANGE CONTROL PASS."


before_lines : 67
after_lines  : 67




line_number before                                                                                                                         after
----------- ------                                                                                                                         -----
         60 if($pDataExpr -ne '"S:\pbi" meta [IsParameterQuery=true, Type="Text", IsParameterQueryRequired=true]'){$fail+='pDataRoot'}     if($pDataExpr -ne
                                                                                                                                           '"\\localhost\MSBF_PBI_A1B_SYNTHETIC\pbi" meta
                                                                                                                                           [IsParameterQuery=true, Type="Text", IsParameterQu
                                                                                                                                           eryRequired=true]'){$fail+='pDataRoot'}
         61 if($pBuildExpr -ne '"S:\build" meta [IsParameterQuery=true, Type="Text", IsParameterQueryRequired=true]'){$fail+='pBuildRoot'} if($pBuildExpr -ne
                                                                                                                                           '"\\localhost\MSBF_PBI_A1B_SYNTHETIC\build" meta
                                                                                                                                           [IsParameterQuery=true, Type="Text", IsParameterQu
                                                                                                                                           eryRequired=true]'){$fail+='pBuildRoot'}


VERIFIER TWO-LINE CHANGE CONTROL PASS.
PS C:\WINDOWS\system32> $afterVerifierHash = (
>>     Get-FileHash `
>>         -LiteralPath $verifier `
>>         -Algorithm SHA256
>> ).Hash.ToLowerInvariant()
>>
>> [pscustomobject]@{
>>     event = "A1B_PRE_REFRESH_VERIFIER_UNC_ROOT_EXPECTATION_FIX"
>>     captured_local = (Get-Date).ToString("o")
>>     captured_utc = (Get-Date).ToUniversalTime().ToString("o")
>>
>>     verifier_before_sha256 = $backupHash
>>     verifier_after_sha256  = $afterVerifierHash
>>
>>     changed_lines = @(60,61)
>>
>>     pDataRoot_expected_before = "S:\pbi"
>>     pDataRoot_expected_after =
>>         "\\localhost\MSBF_PBI_A1B_SYNTHETIC\pbi"
>>
>>     pBuildRoot_expected_before = "S:\build"
>>     pBuildRoot_expected_after =
>>         "\\localhost\MSBF_PBI_A1B_SYNTHETIC\build"
>>
>>     edit_method = "SYSTEM_IO_FILE_WRITEALLTEXT_UTF8_NO_BOM"
>>     project_modified_by_verifier_fix = $false
>>     semantic_logic_modified = $false
>>     refresh_executed = $false
>>     close_apply_executed = $false
>>
>>     status = "VERIFIER_ONLY_TWO_LINE_CORRECTION"
>> } |
>>     ConvertTo-Json -Depth 6 |
>>     Set-Content `
>>         -LiteralPath "$return\E00_UNC_ROOT_VERIFIER_EXPECTATION_FIX.json" `
>>         -Encoding utf8
>>
>> Write-Host "Verifier after SHA-256:"
>> Write-Host $afterVerifierHash
Verifier after SHA-256:
6219071188c43d303642a6bff48134b4faaa6f96b0566c534f355476adcc3af6
PS C:\WINDOWS\system32> & "$work\tools\Verify-A1bPreRefreshBoundary.ps1" `
>>     -PackageRoot $work *>&1 |
>>     Tee-Object `
>>         -FilePath "$return\E00_A1B_PRE_REFRESH_BOUNDARY_AFTER_UNC_PATCH_R2.txt"
{
    "tables":  32,
    "relationships":  32,
    "named_expressions":  47,
    "partitions":  32,
    "power_query_objects":  79,
    "measures":  60,
    "a1b_tables":  18,
    "a1b_relationships":  26,
    "a1b_power_query_objects":  32,
    "a1b_measures":  60,
    "exact_a1b_tables":  true,
    "exact_a1b_relationships":  true,
    "exact_a1b_queries":  true,
    "exact_a1b_measures":  true,
    "technical_shell_pages":  1,
    "page_display_names":  [
                               "A1A_TECHNICAL_SHELL_NO_VISUALS"
                           ],
    "visuals":  0,
    "bookmarks":  0,
    "inactive_relationships":  [
                                   "REL-076"
                               ],
    "bidirectional_relationships":  [

                                    ],
    "scenario_code_relationships":  [

                                    ],
    "pDataRoot":  "\"\\\\localhost\\MSBF_PBI_A1B_SYNTHETIC\\pbi\" meta [IsParameterQuery=true, Type=\"Text\", IsParameterQueryRequired=true]",
    "pBuildRoot":  "\"\\\\localhost\\MSBF_PBI_A1B_SYNTHETIC\\build\" meta [IsParameterQuery=true, Type=\"Text\", IsParameterQueryRequired=true]"
}
A1b pre-refresh semantic boundary PASS.
REL-076 is the sole authorized inactive role-playing date relationship; any other inactive relationship is a stop.
REFRESH REMAINS PROHIBITED until privacy/global-enforcement, Desktop identity, and A1a baseline evidence are captured.
<!-- END_SOURCE_MESSAGE -->


<a id="m-ad8b99ce-986f-4a92-b788-0a0c8b4e0eb6"></a>
## Assistant · C091-M00140

C091-M00140 · 2026-08-19T21:24:06.949430-04:00 · active path

Preceding visible parent: [C091-M00139](part-11.md#m-fcecb8cb-7e47-4000-bce3-725130012880)

<!-- BEGIN_SOURCE_MESSAGE -->
Good. The verifier now passes the exact semantic boundary with the dedicated UNC roots, so the **static pre-refresh boundary is satisfied**.

The current state is:

```text
A1a accepted baseline                     PASS
A1b 32/32/79/60 boundary                  PASS
Exact A1b additions                       PASS
Technical shell                           1
Substantive pages                         0
Visuals                                   0
Inactive relationships                    REL-076 only
Bidirectional relationships               0
scenario_code relationships               0
pDataRoot                                 \\localhost\MSBF_PBI_A1B_SYNTHETIC\pbi
pBuildRoot                                \\localhost\MSBF_PBI_A1B_SYNTHETIC\build
```

That is consistent with Audit’s authorization: only `pDataRoot` and `pBuildRoot` may move to dedicated governed synthetic roots; other A1a source drift remains prohibited. [export reference: filecite | turn19file3 | L244-L255]

We can now proceed to the **privacy-registration and evidence gate**, but still **not to Refresh All yet**.

### 1. Reopen the exact working PBIP

Open:

```text
C:\MSBF\MSBF_PBI_A1B_WORKING_R1_20260819
\project
\MSBF_PBI_A1A_Local_Construction_R1.pbip
```

If Desktop shows a `Refresh now` banner, ignore it.

Confirm the only physical page remains:

```text
A1A_TECHNICAL_SHELL_NO_VISUALS
```

with zero visuals.

### 2. Reconfirm the 79-query inventory

Open:

**Home → Transform data**

Do not Refresh All.

Confirm:

```text
Queries [79]
```

Then click:

```text
stg_POWER_BI_DATA_CATALOG
```

At this point Power Query should attempt the new UNC path:

```text
\\localhost\MSBF_PBI_A1B_SYNTHETIC\pbi
```

If a privacy prompt appears, choose **Continue**.

### 3. Set the UNC source privacy level

For this isolated synthetic root, set:

```text
Public
```

Audit expressly permits Public for an isolated, fully inventoried MSBF synthetic root containing no unrelated personal or production data; broad `C:\ Public` and global privacy-ignore remain prohibited. [export reference: filecite | turn19file5 | L467-L498]

If Desktop exposes one parent source:

```text
\\localhost\MSBF_PBI_A1B_SYNTHETIC
```

use that.

If it exposes two separate scopes:

```text
\\localhost\MSBF_PBI_A1B_SYNTHETIC\pbi
\\localhost\MSBF_PBI_A1B_SYNTHETIC\build
```

set both to `Public`.

Do not modify the old `C:\` permission.

### 4. Capture the required Data Source Settings evidence

Without running Refresh All, go to:

**File → Options and settings → Data source settings**

Capture the view showing the actual UNC source and its privacy classification.

Save it as:

```text
C:\MSBF\MSBF_PBI_A1B_WORKING_R1_20260819
\evidence\local_engine_return
\E00_PRIVACY_DATA_SOURCE_SETTINGS.png
```

The key requirement is that the controlling source begins with:

```text
\\localhost\MSBF_PBI_A1B_SYNTHETIC
```

—not `C:\`.

Audit specifically requires the exact source-root privacy level to be captured before first refresh. [export reference: filecite | turn19file7 | L569-L579]

### 5. Re-capture Desktop process identity for this reopened process

Since this will be a new Power BI process, rerun the native CIM identity capture and overwrite:

```text
E00_POWER_BI_DESKTOP_PROCESS_IDENTITY.json
```

Use the same block that succeeded previously. We still want:

```text
file_version      2.156.951.0
resolved_version  2.156.951.0
identity_status   PASS
```

The About screenshot you already captured remains useful, but the active process record should correspond to the actual Desktop process that will perform A1b refresh.

### 6. Create the privacy attestation only after seeing the exact UI scope

If Data Source Settings shows the parent UNC root, run:

```powershell
$work = "C:\MSBF\MSBF_PBI_A1B_WORKING_R1_20260819"
$return = Join-Path $work "evidence\local_engine_return"

[pscustomobject]@{
    captured_utc = (Get-Date).ToUniversalTime().ToString("o")

    source_scope =
        "\\localhost\MSBF_PBI_A1B_SYNTHETIC"

    privacy_level = "Public"

    physical_backing_root =
        "C:\MSBF\MSBF_PBI_A1B_WORKING_R1_20260819\synthetic_root"

    pDataRoot =
        "\\localhost\MSBF_PBI_A1B_SYNTHETIC\pbi"

    pBuildRoot =
        "\\localhost\MSBF_PBI_A1B_SYNTHETIC\build"

    isolated_synthetic_root_only = $true
    contains_unrelated_personal_or_production_data = $false

    global_privacy_enforcement_enabled = $true
    ignore_privacy_levels = $false
    fast_combine_enabled = $false

    screenshot_data_source_settings =
        "E00_PRIVACY_DATA_SOURCE_SETTINGS.png"

    screenshot_global_privacy =
        "E00_PRIVACY_GLOBAL_ENFORCEMENT.png"

    status = "PASS"
} |
    ConvertTo-Json -Depth 6 |
    Set-Content `
        -LiteralPath "$return\E00_PRIVACY_ATTESTATION.json" `
        -Encoding utf8
```

If Desktop shows the two subroots instead, **do not run this exact attestation**; send me the screenshot and we'll make the JSON match the physical UI.

### 7. Confirm the required pre-refresh evidence files exist

Before running the formal gate, run:

```powershell
$work = "C:\MSBF\MSBF_PBI_A1B_WORKING_R1_20260819"
$return = Join-Path $work "evidence\local_engine_return"

$required = @(
    "E00_PRIVACY_GLOBAL_ENFORCEMENT.png",
    "E00_PRIVACY_DATA_SOURCE_SETTINGS.png",
    "E00_PRIVACY_ATTESTATION.json",
    "E00_POWER_BI_DESKTOP_ABOUT.png",
    "E00_POWER_BI_DESKTOP_PROCESS_IDENTITY.json",
    "E00_SYNTHETIC_ROOT_MAPPING.json",
    "E00_A1A_BASELINE_PREFLIGHT.json",
    "E00_A1B_PRE_REFRESH_BOUNDARY.json"
)

$required |
    ForEach-Object {
        [pscustomobject]@{
            file = $_
            exists = Test-Path -LiteralPath (Join-Path $return $_)
        }
    } |
    Format-Table -AutoSize
```

Every row must be `True`.

If the initializer placed some of those baseline files somewhere else, do not fabricate replacements; tell me which ones show `False`.

### 8. Run the formal pre-refresh evidence gate

Only after all required files exist:

```powershell
$work = "C:\MSBF\MSBF_PBI_A1B_WORKING_R1_20260819"
$return = Join-Path $work "evidence\local_engine_return"

& "$work\tools\Verify-A1bPreRefreshEvidenceGate.ps1" `
    -PackageRoot $work *>&1 |
    Tee-Object `
        -FilePath "$return\E00_A1B_PRE_REFRESH_EVIDENCE_GATE.txt"
```

We require a clean PASS. Audit’s construction authority is explicit that the **first refresh/model-processing attempt remains gated** until the dedicated-root/privacy evidence, Desktop-version evidence, and accepted A1a baseline preflight are complete. [export reference: filecite | turn19file0 | L84-L99]

### 9. Only after gate PASS

Then, and only then:

**Power Query Editor → Refresh Preview → Refresh All**

Stop immediately on any query error. Do not Close & Apply until all 79 queries evaluate successfully. The governing A1b prompt requires successful Power Query evaluation, model processing, DMV evidence, relationship controls, measure compilation, and `AUD-ASOF-003B` evidence while preserving the zero-page/zero-visual boundary. [export reference: filecite | turn19file2 | L177-L229]

For now, reopen Desktop and get the **UNC Data Source Settings screenshot**. Send me that screenshot before running the formal evidence gate.
<!-- END_SOURCE_MESSAGE -->


<a id="m-11307773-639e-4bf5-8dee-b24d2fb1e570"></a>
## Andrew / user · C091-M00141

C091-M00141 · 2026-08-20T05:24:05.277000-04:00 · active path

Preceding visible parent: [C091-M00140](part-11.md#m-ad8b99ce-986f-4a92-b788-0a0c8b4e0eb6)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: E00_DATA_SOURCE_SETTINGS_03.png

<!-- BEGIN_SOURCE_MESSAGE -->
The path is still showing C:
<!-- END_SOURCE_MESSAGE -->


<a id="m-2e66df1e-ea83-41e1-b5f2-c58e282f24f4"></a>
## Assistant · C091-M00142

C091-M00142 · 2026-08-20T05:24:17.611312-04:00 · active path

Preceding visible parent: [C091-M00141](part-11.md#m-11307773-639e-4bf5-8dee-b24d2fb1e570)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes—the screenshot still shows the **old global `C:\` permission**, not a new UNC permission. More importantly, the background Power Query preview proves the query itself is now using the UNC parameter: `pBuildRoot` visibly shows `\\localhost\MSBF_PBI_A1B_SYNTHETIC\build`, and `stg_POWER_BI_DATA_CATALOG` is successfully evaluating 214 rows. So the UNC path change worked; the unresolved issue is that Power BI’s **Global permissions** list is not surfacing a separate UNC entry.

Microsoft’s current documentation says the Data Source Settings path is derived from the connector’s required source parameters, and privacy is attached to the recognized data-source path. It also notes that hand-authored queries may not always appear normally in the current-file list. [export reference: cite | turn838917search2 | turn838917search0]

At this point, I would **not try another source-path redesign**. The stronger interpretation is: the project is executing against the dedicated UNC root, while Desktop’s credential/privacy store is continuing to expose the pre-existing `C:\` global file-source permission. We should preserve that as a UI limitation and use a direct privacy prompt/evidence path rather than keep changing the semantic source.

Do this next:

1. Close the **Data source settings** dialog only.
2. Stay in Power Query Editor.
3. Select `stg_POWER_BI_DATA_CATALOG`.
4. Click **Refresh Preview** for that single query only — **not Refresh All**.
5. If Power BI presents the privacy-level prompt, capture it before making a selection. Then set the source to **Public** only if the prompt identifies the isolated UNC source or the two UNC subroots.
6. If there is **no privacy prompt** and the single-query preview succeeds, stop there and tell me exactly that. Do not proceed to Refresh All yet.

Why this is the right diagnostic: Power Query applies privacy at evaluation time, and the July 2026 Desktop release you are running includes updated Data Privacy Firewall behavior that still enforces compatible privacy levels rather than disabling them. [export reference: cite | turn838917search1 | turn838917search0]

Preserve this screenshot as:

```text
E00_DATA_SOURCE_SETTINGS_03.png
```

and record the current state as:

```text
UNC semantic path               PASS
stg_POWER_BI_DATA_CATALOG       PASS — 214 rows
Global privacy enforcement      PASS
Global permissions UI           still exposes C:\ only
UNC privacy registration UI     NOT VISIBLE
Refresh All                     PROHIBITED
Close & Apply                   PROHIBITED
```

The key next evidence is whether a **single-query Refresh Preview** causes Desktop to present a UNC-specific privacy prompt. If it does, we can close the privacy-control gap without another model change.
<!-- END_SOURCE_MESSAGE -->


<a id="m-473b4b93-5b4f-4eb0-bc8e-2cf7b69ec576"></a>
## Andrew / user · C091-M00143

C091-M00143 · 2026-08-20T05:45:49.765000-04:00 · active path

Preceding visible parent: [C091-M00142](part-11.md#m-2e66df1e-ea83-41e1-b5f2-c58e282f24f4)

<!-- BEGIN_SOURCE_MESSAGE -->
The single-query refresh preview worked. No privacy prompt appeared.
<!-- END_SOURCE_MESSAGE -->
