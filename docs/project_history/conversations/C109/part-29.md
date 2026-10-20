# MSBF - Power BI Executive Portfolio Intelligence Part 2

Part 29 · [Conversation index](README.md) · [History home](../../README.md)

> Historical dialogue: commands and approvals below describe past events. They are not current execution or publication instructions. Attachment references do not establish recovered bytes.

[Previous part](part-28.md)
[Next part](part-30.md)

<a id="m-314d3edb-68c0-435b-b6a1-ec98afee31d9"></a>
## Andrew / user · C109-M00618

C109-M00618 · 2026-09-02T08:57:58.516000-04:00 · active path

Preceding visible parent: [C109-M00617](part-28.md#m-957ae1b4-e859-47c0-9e56-6c119864a053)

<!-- BEGIN_SOURCE_MESSAGE -->
PS C:\MSBF\PowerBI\R26_Parallel\MSBF_PBI_R26_PARALLEL_REFINEMENT_C1_20260902_DELIVERY> $R22Working =
>>     "C:\MSBF\R22\power_bi\desktop_working\MSBF_PBI_R1_SUCCESSOR_CANDIDATE_R22"
>>
>> Get-ChildItem `
>>     -LiteralPath $R22Working `
>>     -File `
>>     -Recurse `
>>     -ErrorAction Stop |
>> Select-String `
>>     -Pattern @(
>>         'MSBF_PBI_A1B_SYNTHETIC',
>>         'pDataRoot',
>>         'pBuildRoot',
>>         'R22\\power_bi\\carrier',
>>         'R1Successor'
>>     ) `
>>     -SimpleMatch |
>> Select-Object Path, LineNumber, Line |
>> Format-List

Path       : C:\MSBF\R22\power_bi\desktop_working\MSBF_PBI_R1_SUCCESSOR_CANDIDATE_R22\MSBF_PBI_R1_PARALLEL_REFINEMENT_C1_20260901.SemanticModel\model.bim
LineNumber : 15
Line       :         "value": "[\"pDataRoot\",\"pBuildRoot\",\"pCampaignOrRunId\",\"pDefaultScenario\",\"pDefaultAsOfDate\",\"pSourceRelease\",\"pModelDefinitionVersion\",\"pRecommendationDefinitionVersion\",\"pLoadOptionalDailyBase\",\
             "stg_POWER_BI_DATA_CATALOG\",\"fxReadCatalogedCsv\",\"fxKeyPart\",\"fxLatestOnOrBefore\",\"fxAssertSelectedRun\",\"stg_msbf_ctl_acceptance_gate_result\",\"stg_msbf_ctl_m1_17_g2_bundle_latest\",\"stg_msbf_ctl_m2_12_g3_bundle
             _latest\",\"stg_msbf_ctl_run_registry\",\"stg_msbf_m1_application_acquisition_contract_latest\",\"stg_msbf_m1_application_module1_latest\",\"stg_msbf_m1_merchant_application\",\"stg_msbf_m1_merchant_industry_assignment\",\"
             stg_msbf_m1_merchant_master\",\"stg_msbf_m1_merchant_relationship_snapshot\",\"stg_msbf_m2_advance_daily_remittance_monitoring\",\"stg_msbf_m2_application_booking_funding_activation_latest\",\"stg_msbf_m2_initial_portfolio_
             activation\",\"stg_msbf_ref_acquisition_source_family\",\"stg_msbf_ref_geography_region\",\"stg_msbf_ref_industry\",\"stg_msbf_ctl_m1_17_g2_bundle_registry\",\"stg_msbf_ctl_m2_12_g3_bundle_registry\",\"fxReadBuildCsv\",\"Mo
             delParameters\",\"DimScenario\",\"DimRunCampaign\",\"DimMerchant\",\"DimApplication\",\"DimAccountAdvance\",\"DimIndustry\",\"DimRegion\",\"DimAcquisitionSource\",\"DimDate\",\"DimAsOfDate\",\"FactGovernanceControl\",\"Fact
             SourceReconciliation\",\"FactValidationResult\",\"stg_msbf_m2_advance_intervention_strategy_latest\",\"stg_msbf_m2_advance_portfolio_monitoring_latest\",\"stg_msbf_m2_application_final_offer_decision_latest\",\"stg_msbf_m2_
             application_payment_reconciliation_certification_latest\",\"stg_msbf_m2_application_portfolio_performance_latest\",\"stg_msbf_m2_application_servicing_execution_latest\",\"stg_msbf_m2_final_decision_outcome_definition\",\"s
             tg_msbf_m2_payment_exception_case_snapshot\",\"stg_msbf_m2_portfolio_kpi_definition\",\"stg_msbf_m2_portfolio_kpi_snapshot\",\"stg_msbf_m2_portfolio_monitoring_status_definition\",\"stg_msbf_m2_portfolio_performance_tier_de
             finition\",\"stg_msbf_m2_servicing_queue_analytics_snapshot\",\"stg_msbf_m2_servicing_queue_definition\",\"DimDecisionOutcome\",\"DimMonitoringStatus\",\"DimPerformanceTier\",\"DimServicingQueue\",\"DimReportingScope\",\"Di
             mKPI\",\"FactApplicationScenario\",\"FactFinalDecision\",\"FactBookingActivation\",\"FactAccountDaily\",\"FactMonitoringEndpoint\",\"FactIntervention\",\"FactServicingExecution\",\"FactPaymentException\",\"FactAccountCertif
             ication\",\"FactPortfolioPerformanceEndpoint\",\"FactServicingQueueEndpoint\",\"FactPortfolioKPIEndpoint\",\"FactAccountReconciliation\",\"stg_msbf_m2_account_payment_reconciliation_snapshot\",\"R1DimApplicationScenario\",\
             "R1FactFeatureAvailability\",\"R1FactDecisionGate\",\"R1FactOfferCandidate\",\"R1FactFinalDecision\",\"R1FactNoFeasibleProof\",\"R1FactDailyMonitoring\",\"R1FactIntervention\",\"R1FactOperationalSetup\",\"R1FactServicingExe
             cution\",\"R1FactAccountCertification\",\"R1FactPortfolioPerformance\",\"R1DimStrategyProfile\",\"R1FactCandidateEvaluation\",\"R1FactApplicationStrategySimulation\",\"R1FactAccountStrategySimulation\",\"R1FactPortfolioStra
             tegyAnalysis\",\"R1FactG3v2Certification\",\"R1DimReportingScope\",\"R1AuthorityStatus\",\"R1Measures\",\"pSuccessorRoot\",\"pSuccessorSourceRelease\",\"stg_R1_SUCCESSOR_DATA_CATALOG\",\"fxReadSuccessorCsv\"]"

Path       : C:\MSBF\R22\power_bi\desktop_working\MSBF_PBI_R1_SUCCESSOR_CANDIDATE_R22\MSBF_PBI_R1_PARALLEL_REFINEMENT_C1_20260901.SemanticModel\model.bim
LineNumber : 58
Line       :         "name": "MSBF_R1SuccessorCandidate",

Path       : C:\MSBF\R22\power_bi\desktop_working\MSBF_PBI_R1_SUCCESSOR_CANDIDATE_R22\MSBF_PBI_R1_PARALLEL_REFINEMENT_C1_20260901.SemanticModel\model.bim
LineNumber : 62
Line       :         "name": "MSBF_R1SuccessorCertificationId",

Path       : C:\MSBF\R22\power_bi\desktop_working\MSBF_PBI_R1_SUCCESSOR_CANDIDATE_R22\MSBF_PBI_R1_PARALLEL_REFINEMENT_C1_20260901.SemanticModel\model.bim
LineNumber : 66
Line       :         "name": "MSBF_R1SuccessorPowerBIBundleSha256",

Path       : C:\MSBF\R22\power_bi\desktop_working\MSBF_PBI_R1_SUCCESSOR_CANDIDATE_R22\MSBF_PBI_R1_PARALLEL_REFINEMENT_C1_20260901.SemanticModel\model.bim
LineNumber : 4197
Line       :         "name": "pDataRoot",

Path       : C:\MSBF\R22\power_bi\desktop_working\MSBF_PBI_R1_SUCCESSOR_CANDIDATE_R22\MSBF_PBI_R1_PARALLEL_REFINEMENT_C1_20260901.SemanticModel\model.bim
LineNumber : 4216
Line       :         "expression": "\"\\\\localhost\\MSBF_PBI_A1B_SYNTHETIC\\pbi\" meta [IsParameterQuery=true, Type=\"Text\", IsParameterQueryRequired=true]",

Path       : C:\MSBF\R22\power_bi\desktop_working\MSBF_PBI_R1_SUCCESSOR_CANDIDATE_R22\MSBF_PBI_R1_PARALLEL_REFINEMENT_C1_20260901.SemanticModel\model.bim
LineNumber : 4221
Line       :         "name": "pBuildRoot",

Path       : C:\MSBF\R22\power_bi\desktop_working\MSBF_PBI_R1_SUCCESSOR_CANDIDATE_R22\MSBF_PBI_R1_PARALLEL_REFINEMENT_C1_20260901.SemanticModel\model.bim
LineNumber : 4240
Line       :         "expression": "\"\\\\localhost\\MSBF_PBI_A1B_SYNTHETIC\\build\" meta [IsParameterQuery=true, Type=\"Text\", IsParameterQueryRequired=true]",

Path       : C:\MSBF\R22\power_bi\desktop_working\MSBF_PBI_R1_SUCCESSOR_CANDIDATE_R22\MSBF_PBI_R1_PARALLEL_REFINEMENT_C1_20260901.SemanticModel\model.bim
LineNumber : 4427
Line       :           "    Root = Text.TrimEnd(pDataRoot, {\"/\", \"\\\"}),",

Path       : C:\MSBF\R22\power_bi\desktop_working\MSBF_PBI_R1_SUCCESSOR_CANDIDATE_R22\MSBF_PBI_R1_PARALLEL_REFINEMENT_C1_20260901.SemanticModel\model.bim
LineNumber : 4460
Line       :           "    Root = Text.TrimEnd(pDataRoot, {\"/\", \"\\\"}),",

Path       : C:\MSBF\R22\power_bi\desktop_working\MSBF_PBI_R1_SUCCESSOR_CANDIDATE_R22\MSBF_PBI_R1_PARALLEL_REFINEMENT_C1_20260901.SemanticModel\model.bim
LineNumber : 5605
Line       :           "    Root = Text.TrimEnd(pBuildRoot, {\"/\", \"\\\"}),",

Path       : C:\MSBF\R22\power_bi\desktop_working\MSBF_PBI_R1_SUCCESSOR_CANDIDATE_R22\MSBF_PBI_R1_PARALLEL_REFINEMENT_C1_20260901.SemanticModel\model.bim
LineNumber : 11461
Line       :                 "            {\"pDataRoot\", pDataRoot}, {\"pCampaignOrRunId\", Text.From(pCampaignOrRunId, \"en-US\")},",

Path       : C:\MSBF\R22\power_bi\desktop_working\MSBF_PBI_R1_SUCCESSOR_CANDIDATE_R22\MSBF_PBI_R1_SUCCESSOR_CANDIDATE_R20.SemanticModel\model.bim
LineNumber : 15
Line       :         "value": "[\"pDataRoot\",\"pBuildRoot\",\"pCampaignOrRunId\",\"pDefaultScenario\",\"pDefaultAsOfDate\",\"pSourceRelease\",\"pModelDefinitionVersion\",\"pRecommendationDefinitionVersion\",\"pLoadOptionalDailyBase\",\
             "stg_POWER_BI_DATA_CATALOG\",\"fxReadCatalogedCsv\",\"fxKeyPart\",\"fxLatestOnOrBefore\",\"fxAssertSelectedRun\",\"stg_msbf_ctl_acceptance_gate_result\",\"stg_msbf_ctl_m1_17_g2_bundle_latest\",\"stg_msbf_ctl_m2_12_g3_bundle
             _latest\",\"stg_msbf_ctl_run_registry\",\"stg_msbf_m1_application_acquisition_contract_latest\",\"stg_msbf_m1_application_module1_latest\",\"stg_msbf_m1_merchant_application\",\"stg_msbf_m1_merchant_industry_assignment\",\"
             stg_msbf_m1_merchant_master\",\"stg_msbf_m1_merchant_relationship_snapshot\",\"stg_msbf_m2_advance_daily_remittance_monitoring\",\"stg_msbf_m2_application_booking_funding_activation_latest\",\"stg_msbf_m2_initial_portfolio_
             activation\",\"stg_msbf_ref_acquisition_source_family\",\"stg_msbf_ref_geography_region\",\"stg_msbf_ref_industry\",\"stg_msbf_ctl_m1_17_g2_bundle_registry\",\"stg_msbf_ctl_m2_12_g3_bundle_registry\",\"fxReadBuildCsv\",\"Mo
             delParameters\",\"DimScenario\",\"DimRunCampaign\",\"DimMerchant\",\"DimApplication\",\"DimAccountAdvance\",\"DimIndustry\",\"DimRegion\",\"DimAcquisitionSource\",\"DimDate\",\"DimAsOfDate\",\"FactGovernanceControl\",\"Fact
             SourceReconciliation\",\"FactValidationResult\",\"stg_msbf_m2_advance_intervention_strategy_latest\",\"stg_msbf_m2_advance_portfolio_monitoring_latest\",\"stg_msbf_m2_application_final_offer_decision_latest\",\"stg_msbf_m2_
             application_payment_reconciliation_certification_latest\",\"stg_msbf_m2_application_portfolio_performance_latest\",\"stg_msbf_m2_application_servicing_execution_latest\",\"stg_msbf_m2_final_decision_outcome_definition\",\"s
             tg_msbf_m2_payment_exception_case_snapshot\",\"stg_msbf_m2_portfolio_kpi_definition\",\"stg_msbf_m2_portfolio_kpi_snapshot\",\"stg_msbf_m2_portfolio_monitoring_status_definition\",\"stg_msbf_m2_portfolio_performance_tier_de
             finition\",\"stg_msbf_m2_servicing_queue_analytics_snapshot\",\"stg_msbf_m2_servicing_queue_definition\",\"DimDecisionOutcome\",\"DimMonitoringStatus\",\"DimPerformanceTier\",\"DimServicingQueue\",\"DimReportingScope\",\"Di
             mKPI\",\"FactApplicationScenario\",\"FactFinalDecision\",\"FactBookingActivation\",\"FactAccountDaily\",\"FactMonitoringEndpoint\",\"FactIntervention\",\"FactServicingExecution\",\"FactPaymentException\",\"FactAccountCertif
             ication\",\"FactPortfolioPerformanceEndpoint\",\"FactServicingQueueEndpoint\",\"FactPortfolioKPIEndpoint\",\"FactAccountReconciliation\",\"stg_msbf_m2_account_payment_reconciliation_snapshot\",\"R1DimApplicationScenario\",\
             "R1FactFeatureAvailability\",\"R1FactDecisionGate\",\"R1FactOfferCandidate\",\"R1FactFinalDecision\",\"R1FactNoFeasibleProof\",\"R1FactDailyMonitoring\",\"R1FactIntervention\",\"R1FactOperationalSetup\",\"R1FactServicingExe
             cution\",\"R1FactAccountCertification\",\"R1FactPortfolioPerformance\",\"R1DimStrategyProfile\",\"R1FactCandidateEvaluation\",\"R1FactApplicationStrategySimulation\",\"R1FactAccountStrategySimulation\",\"R1FactPortfolioStra
             tegyAnalysis\",\"R1FactG3v2Certification\",\"R1DimReportingScope\",\"R1AuthorityStatus\",\"R1Measures\",\"pSuccessorRoot\",\"pSuccessorSourceRelease\",\"stg_R1_SUCCESSOR_DATA_CATALOG\",\"fxReadSuccessorCsv\"]"

Path       : C:\MSBF\R22\power_bi\desktop_working\MSBF_PBI_R1_SUCCESSOR_CANDIDATE_R22\MSBF_PBI_R1_SUCCESSOR_CANDIDATE_R20.SemanticModel\model.bim
LineNumber : 58
Line       :         "name": "MSBF_R1SuccessorCandidate",

Path       : C:\MSBF\R22\power_bi\desktop_working\MSBF_PBI_R1_SUCCESSOR_CANDIDATE_R22\MSBF_PBI_R1_SUCCESSOR_CANDIDATE_R20.SemanticModel\model.bim
LineNumber : 62
Line       :         "name": "MSBF_R1SuccessorCertificationId",

Path       : C:\MSBF\R22\power_bi\desktop_working\MSBF_PBI_R1_SUCCESSOR_CANDIDATE_R22\MSBF_PBI_R1_SUCCESSOR_CANDIDATE_R20.SemanticModel\model.bim
LineNumber : 66
Line       :         "name": "MSBF_R1SuccessorPowerBIBundleSha256",

Path       : C:\MSBF\R22\power_bi\desktop_working\MSBF_PBI_R1_SUCCESSOR_CANDIDATE_R22\MSBF_PBI_R1_SUCCESSOR_CANDIDATE_R20.SemanticModel\model.bim
LineNumber : 3307
Line       :         "name": "pDataRoot",

Path       : C:\MSBF\R22\power_bi\desktop_working\MSBF_PBI_R1_SUCCESSOR_CANDIDATE_R22\MSBF_PBI_R1_SUCCESSOR_CANDIDATE_R20.SemanticModel\model.bim
LineNumber : 3326
Line       :         "expression": "\"\\\\localhost\\MSBF_PBI_A1B_SYNTHETIC\\pbi\" meta [IsParameterQuery=true, Type=\"Text\", IsParameterQueryRequired=true]",

Path       : C:\MSBF\R22\power_bi\desktop_working\MSBF_PBI_R1_SUCCESSOR_CANDIDATE_R22\MSBF_PBI_R1_SUCCESSOR_CANDIDATE_R20.SemanticModel\model.bim
LineNumber : 3331
Line       :         "name": "pBuildRoot",

Path       : C:\MSBF\R22\power_bi\desktop_working\MSBF_PBI_R1_SUCCESSOR_CANDIDATE_R22\MSBF_PBI_R1_SUCCESSOR_CANDIDATE_R20.SemanticModel\model.bim
LineNumber : 3350
Line       :         "expression": "\"\\\\localhost\\MSBF_PBI_A1B_SYNTHETIC\\build\" meta [IsParameterQuery=true, Type=\"Text\", IsParameterQueryRequired=true]",

Path       : C:\MSBF\R22\power_bi\desktop_working\MSBF_PBI_R1_SUCCESSOR_CANDIDATE_R22\MSBF_PBI_R1_SUCCESSOR_CANDIDATE_R20.SemanticModel\model.bim
LineNumber : 3537
Line       :           "    Root = Text.TrimEnd(pDataRoot, {\"/\", \"\\\"}),",

Path       : C:\MSBF\R22\power_bi\desktop_working\MSBF_PBI_R1_SUCCESSOR_CANDIDATE_R22\MSBF_PBI_R1_SUCCESSOR_CANDIDATE_R20.SemanticModel\model.bim
LineNumber : 3570
Line       :           "    Root = Text.TrimEnd(pDataRoot, {\"/\", \"\\\"}),",

Path       : C:\MSBF\R22\power_bi\desktop_working\MSBF_PBI_R1_SUCCESSOR_CANDIDATE_R22\MSBF_PBI_R1_SUCCESSOR_CANDIDATE_R20.SemanticModel\model.bim
LineNumber : 4715
Line       :           "    Root = Text.TrimEnd(pBuildRoot, {\"/\", \"\\\"}),",

Path       : C:\MSBF\R22\power_bi\desktop_working\MSBF_PBI_R1_SUCCESSOR_CANDIDATE_R22\MSBF_PBI_R1_SUCCESSOR_CANDIDATE_R20.SemanticModel\model.bim
LineNumber : 10557
Line       :                 "            {\"pDataRoot\", pDataRoot}, {\"pCampaignOrRunId\", Text.From(pCampaignOrRunId, \"en-US\")},",
<!-- END_SOURCE_MESSAGE -->


<a id="m-172f9537-d942-4449-ab31-46c85ad07c31"></a>
## Assistant · C109-M00619

C109-M00619 · 2026-09-02T08:58:02.012131-04:00 · active path

Preceding visible parent: [C109-M00618](part-29.md#m-314d3edb-68c0-435b-b6a1-ec98afee31d9)

<!-- BEGIN_SOURCE_MESSAGE -->
This confirms the architecture exactly as expected.

Your live R22 refinement and its predecessor model both resolve the **core model** through:

```text
pDataRoot  = \\localhost\MSBF_PBI_A1B_SYNTHETIC\pbi
pBuildRoot = \\localhost\MSBF_PBI_A1B_SYNTHETIC\build
```

So the refresh failure is definitively caused by the missing A1b physical source/share. It is **not** evidence of an R26 carrier problem, and we should not change either model parameter. The accepted Focused R2 authority also confirms that this UNC source consisted of the same 222-file synthetic root and that those source roots remained unchanged. [export reference: filecite | turn103file5 | L420-L448]

We can now proceed with restoration.

### 1. Verify the accepted restoration carrier

Power BI should remain closed.

Run this in your current PowerShell window:

```powershell
$CarrierZip =
    "C:\MSBF\MSBF_PBI_A1B_FOCUSED_R2_INDEPENDENT_AUDIT_SUBMISSION_20260821.zip"

$ExpectedSha =
    "8dddea7de21f1ead227d9ed9bd6fdcbe439b0e48aa11f3cb16023e0b77744b02"

$CarrierItem = Get-Item -LiteralPath $CarrierZip

$ActualSha = (
    Get-FileHash `
        -LiteralPath $CarrierZip `
        -Algorithm SHA256
).Hash.ToLowerInvariant()

[pscustomobject]@{
    Exists        = Test-Path $CarrierZip
    Bytes         = $CarrierItem.Length
    ExpectedBytes = 34813542
    ByteMatch     = ($CarrierItem.Length -eq 34813542)
    SHA256        = $ActualSha
    ExpectedSHA   = $ExpectedSha
    HashMatch     = ($ActualSha -eq $ExpectedSha)
} | Format-List
```

We require:

```text
Exists    : True
Bytes     : 34813542
ByteMatch : True
HashMatch : True
```

The accepted audit carrier is independently recorded at exactly that size and SHA. [export reference: filecite | turn103file6 | L527-L568]

### 2. If that passes, restore the source

Open **PowerShell as Administrator** and use this streamlined controlled block:

```powershell
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$CarrierZip =
    "C:\MSBF\MSBF_PBI_A1B_FOCUSED_R2_INDEPENDENT_AUDIT_SUBMISSION_20260821.zip"

$ExpectedCarrierSha =
    "8dddea7de21f1ead227d9ed9bd6fdcbe439b0e48aa11f3cb16023e0b77744b02"

$RestoreParent =
    "C:\MSBF\MSBF_PBI_A1B_WORKING_R1_20260819"

$RestoreRoot =
    "$RestoreParent\synthetic_root"

$TempRoot =
    "C:\MSBF\_A1B_SOURCE_RESTORE_TEMP_20260902"

$ShareName =
    "MSBF_PBI_A1B_SYNTHETIC"


Write-Host "===== VERIFY SEALED CARRIER ====="

if (-not (Test-Path -LiteralPath $CarrierZip)) {
    throw "STOP: accepted Focused R2 ZIP is missing."
}

$CarrierHash = (
    Get-FileHash `
        -LiteralPath $CarrierZip `
        -Algorithm SHA256
).Hash.ToLowerInvariant()

if ($CarrierHash -ne $ExpectedCarrierSha) {
    throw "STOP: accepted Focused R2 ZIP SHA-256 mismatch."
}

if ((Get-Item -LiteralPath $CarrierZip).Length -ne 34813542) {
    throw "STOP: accepted Focused R2 ZIP byte-count mismatch."
}

Write-Host "Carrier identity: PASS"


Write-Host ""
Write-Host "===== PREPARE CLEAN EXTRACTION ====="

if (Test-Path -LiteralPath $RestoreRoot) {
    throw "STOP: target synthetic_root unexpectedly already exists."
}

if (Test-Path -LiteralPath $TempRoot) {
    Remove-Item $TempRoot -Recurse -Force
}

New-Item `
    -ItemType Directory `
    -Path $TempRoot |
    Out-Null

Expand-Archive `
    -LiteralPath $CarrierZip `
    -DestinationPath $TempRoot `
    -Force


Write-Host ""
Write-Host "===== LOCATE SYNTHETIC ROOT ====="

$SyntheticRoots = @(
    Get-ChildItem `
        -LiteralPath $TempRoot `
        -Directory `
        -Recurse `
        -Force |
    Where-Object {
        $_.Name -eq "synthetic_root" -and
        (Test-Path (Join-Path $_.FullName "pbi")) -and
        (Test-Path (Join-Path $_.FullName "build"))
    }
)

if ($SyntheticRoots.Count -ne 1) {
    throw "STOP: expected exactly one valid synthetic_root; found $($SyntheticRoots.Count)."
}

$ExtractedRoot = $SyntheticRoots[0].FullName

Write-Host "Found:"
Write-Host $ExtractedRoot


Write-Host ""
Write-Host "===== VERIFY 222-FILE POPULATION ====="

$ExtractedFiles = @(
    Get-ChildItem `
        -LiteralPath $ExtractedRoot `
        -File `
        -Recurse `
        -Force
)

Write-Host "Source files:" $ExtractedFiles.Count

if ($ExtractedFiles.Count -ne 222) {
    throw "STOP: expected exactly 222 source files."
}


Write-Host ""
Write-Host "===== VERIFY MANIFEST ====="

$ManifestFiles = @(
    Get-ChildItem `
        -LiteralPath $TempRoot `
        -File `
        -Recurse `
        -Force |
    Where-Object {
        $_.Name -eq "synthetic_root_MANIFEST_SHA256.csv"
    }
)

if ($ManifestFiles.Count -ne 1) {
    throw "STOP: expected exactly one synthetic-root manifest; found $($ManifestFiles.Count)."
}

$ManifestRows = @(
    Import-Csv -LiteralPath $ManifestFiles[0].FullName
)

if ($ManifestRows.Count -ne 222) {
    throw "STOP: expected exactly 222 manifest rows."
}

$Failures = @()

foreach ($Row in $ManifestRows) {

    $RelativePath = [string]$Row.relative_path
    $ExpectedBytes = [int64]$Row.bytes
    $ExpectedHash = ([string]$Row.sha256).ToLowerInvariant()

    $PhysicalPath =
        Join-Path $ExtractedRoot $RelativePath

    if (-not (Test-Path -LiteralPath $PhysicalPath)) {
        $Failures += "MISSING: $RelativePath"
        continue
    }

    $Item = Get-Item -LiteralPath $PhysicalPath

    if ($Item.Length -ne $ExpectedBytes) {
        $Failures += "BYTE: $RelativePath"
        continue
    }

    $ActualHash = (
        Get-FileHash `
            -LiteralPath $PhysicalPath `
            -Algorithm SHA256
    ).Hash.ToLowerInvariant()

    if ($ActualHash -ne $ExpectedHash) {
        $Failures += "HASH: $RelativePath"
    }
}

if ($Failures.Count -gt 0) {
    $Failures
    throw "STOP: synthetic-root manifest reconciliation failed."
}

Write-Host "Manifest reconciliation: PASS"


Write-Host ""
Write-Host "===== RESTORE PHYSICAL SOURCE ====="

New-Item `
    -ItemType Directory `
    -Path $RestoreParent `
    -Force |
    Out-Null

Copy-Item `
    -LiteralPath $ExtractedRoot `
    -Destination $RestoreParent `
    -Recurse

$RestoredCount = @(
    Get-ChildItem `
        -LiteralPath $RestoreRoot `
        -File `
        -Recurse `
        -Force
).Count

if ($RestoredCount -ne 222) {
    throw "STOP: restored source count is not 222."
}

Write-Host "Physical restore: PASS"


Write-Host ""
Write-Host "===== RESTORE LOCAL SMB SHARE ====="

$ExistingShare =
    Get-SmbShare `
        -Name $ShareName `
        -ErrorAction SilentlyContinue

if ($null -ne $ExistingShare) {

    if (
        $ExistingShare.Path.TrimEnd('\') -ne
        $RestoreRoot.TrimEnd('\')
    ) {
        throw "STOP: existing SMB share points to wrong physical path."
    }

}
else {

    $Identity =
        [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

    New-SmbShare `
        -Name $ShareName `
        -Path $RestoreRoot `
        -ReadAccess $Identity `
        -CachingMode None |
        Out-Null
}


Write-Host ""
Write-Host "===== FINAL VALIDATION ====="

$UNC = "\\localhost\$ShareName"

$Checks = [ordered]@{
    "Physical root"  = Test-Path $RestoreRoot
    "Physical pbi"   = Test-Path "$RestoreRoot\pbi"
    "Physical build" = Test-Path "$RestoreRoot\build"
    "UNC root"       = Test-Path $UNC
    "UNC pbi"        = Test-Path "$UNC\pbi"
    "UNC build"      = Test-Path "$UNC\build"
}

$Checks.GetEnumerator() |
    Format-Table -AutoSize

Write-Host ""
Write-Host "Restored files:" $RestoredCount

Write-Host ""
Get-SmbShare -Name $ShareName |
    Select-Object Name,Path |
    Format-List

Get-SmbShareAccess -Name $ShareName |
    Format-Table AccountName,AccessControlType,AccessRight -AutoSize

if ($Checks.Values -contains $false) {
    throw "STOP: final source/UNC validation failed."
}

Write-Host ""
Write-Host "A1B ACCEPTED SOURCE RESTORE: PASS"
```

### What this changes — and what it does not

This operation restores only the missing environmental dependency:

```text
C:\MSBF\MSBF_PBI_A1B_WORKING_R1_20260819\synthetic_root
                         ↓
\\localhost\MSBF_PBI_A1B_SYNTHETIC
```

It makes **zero changes** to:

```text
C:\MSBF\R22\power_bi
C:\MSBF\R26\power_bi\carrier
your R22 refinement project
your R26 refinement project
Power Query definitions
DAX
relationships
visuals
```

Your output has now physically demonstrated that the R22 refinement itself still contains the exact accepted UNC roots. That is good nonregression evidence.

Once you reach:

```text
A1B ACCEPTED SOURCE RESTORE: PASS
```

paste the final output here. Then we'll reopen the R26 project and retry **Refresh All**.
<!-- END_SOURCE_MESSAGE -->


<a id="m-e07148c0-c758-4af2-89d0-c992c8b8cf7f"></a>
## Andrew / user · C109-M00620

C109-M00620 · 2026-09-02T09:00:12.350000-04:00 · active path

Preceding visible parent: [C109-M00619](part-29.md#m-172f9537-d942-4449-ab31-46c85ad07c31)

<!-- BEGIN_SOURCE_MESSAGE -->
===== VERIFY SEALED CARRIER =====
Carrier identity: PASS

===== PREPARE CLEAN EXTRACTION =====

===== LOCATE SYNTHETIC ROOT =====
Found:
C:\MSBF\_A1B_SOURCE_RESTORE_TEMP_20260902\synthetic_root

===== VERIFY 222-FILE POPULATION =====
Source files: 222

===== VERIFY MANIFEST =====
Exception:
Line |
 128 |      throw "STOP: expected exactly one synthetic-root manifest; found  …
     |      ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     | STOP: expected exactly one synthetic-root manifest; found 0.
<!-- END_SOURCE_MESSAGE -->


<a id="m-0a53a918-1f43-4454-9a7f-6ead80e06a6f"></a>
## Assistant · C109-M00621

C109-M00621 · 2026-09-02T09:00:52.783266-04:00 · active path

Preceding visible parent: [C109-M00620](part-29.md#m-e07148c0-c758-4af2-89d0-c992c8b8cf7f)

<!-- BEGIN_SOURCE_MESSAGE -->
This is not a source failure. **The stop was caused by another incorrect filename assumption in my restoration script.** The Focused R2 package does not carry a file named `synthetic_root_MANIFEST_SHA256.csv` at package level.

The actual sealed submission was built with a **top-level `MANIFEST_SHA256.csv`**, covering the full package, plus `COPY_RECONCILIATION.csv`. The package-construction record explicitly shows that filename. [export reference: filecite | turn105file0 | L80-L99] Independent Audit then verified the resulting payload manifest at **436/436 PASS**, copy reconciliation at **434/434 PASS**, and clean extraction at **437/437 PASS**. [export reference: filecite | turn105file13 | L1095-L1111]

Your run has already independently established the two facts we most needed:

```text
Sealed Focused R2 carrier identity: PASS
Extracted synthetic_root files:     222
```

And the accepted authority confirms the underlying source population is exactly 222 files. [export reference: filecite | turn104file3 | L283-L300]

So **do not re-extract**. We can continue from the clean temporary extraction already sitting at:

```text
C:\MSBF\_A1B_SOURCE_RESTORE_TEMP_20260902
```

## Continue with this corrected verification block

Keep using the **Administrator PowerShell** session in which the extraction was performed.

Paste this whole block:

```powershell
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$TempRoot =
    "C:\MSBF\_A1B_SOURCE_RESTORE_TEMP_20260902"

$ExtractedRoot =
    "$TempRoot\synthetic_root"

$RestoreParent =
    "C:\MSBF\MSBF_PBI_A1B_WORKING_R1_20260819"

$RestoreRoot =
    "$RestoreParent\synthetic_root"

$ShareName =
    "MSBF_PBI_A1B_SYNTHETIC"


Write-Host "===== VERIFY PACKAGE MANIFEST ====="

$ManifestPath =
    Join-Path $TempRoot "MANIFEST_SHA256.csv"

if (-not (Test-Path -LiteralPath $ManifestPath)) {
    throw "STOP: package MANIFEST_SHA256.csv is missing."
}

$ManifestRows = @(
    Import-Csv -LiteralPath $ManifestPath
)

Write-Host "Package manifest rows:" $ManifestRows.Count

if ($ManifestRows.Count -ne 436) {
    throw "STOP: expected exactly 436 package-manifest rows."
}


Write-Host ""
Write-Host "===== ISOLATE SYNTHETIC_ROOT MANIFEST POPULATION ====="

$SyntheticManifestRows = @(
    $ManifestRows |
    Where-Object {
        ([string]$_.relative_path) -match '^synthetic_root[\\/]'
    }
)

Write-Host "Synthetic-root manifest rows:" $SyntheticManifestRows.Count

if ($SyntheticManifestRows.Count -ne 222) {
    throw "STOP: expected exactly 222 synthetic_root rows in package manifest."
}


Write-Host ""
Write-Host "===== VERIFY ALL 222 SYNTHETIC SOURCE FILES ====="

$ManifestFailures = @()

foreach ($Row in $SyntheticManifestRows) {

    $RelativePath =
        ([string]$Row.relative_path).Replace("/", "\")

    $PhysicalPath =
        Join-Path $TempRoot $RelativePath

    if (-not (Test-Path -LiteralPath $PhysicalPath)) {
        $ManifestFailures +=
            "MISSING: $RelativePath"
        continue
    }

    $Item =
        Get-Item -LiteralPath $PhysicalPath

    $ExpectedBytes =
        [int64]$Row.bytes

    if ($Item.Length -ne $ExpectedBytes) {
        $ManifestFailures +=
            "BYTE_MISMATCH: $RelativePath expected=$ExpectedBytes actual=$($Item.Length)"
        continue
    }

    $ExpectedHash =
        ([string]$Row.sha256).Trim().ToLowerInvariant()

    $ActualHash = (
        Get-FileHash `
            -LiteralPath $PhysicalPath `
            -Algorithm SHA256
    ).Hash.ToLowerInvariant()

    if ($ActualHash -ne $ExpectedHash) {
        $ManifestFailures +=
            "HASH_MISMATCH: $RelativePath"
    }
}

if ($ManifestFailures.Count -gt 0) {
    $ManifestFailures
    throw "STOP: synthetic_root package-manifest verification failed."
}

Write-Host "222 / 222 synthetic-root manifest verification: PASS"


Write-Host ""
Write-Host "===== VERIFY COPY RECONCILIATION ====="

$CopyPath =
    Join-Path $TempRoot "COPY_RECONCILIATION.csv"

if (-not (Test-Path -LiteralPath $CopyPath)) {
    throw "STOP: COPY_RECONCILIATION.csv is missing."
}

$CopyRows = @(
    Import-Csv -LiteralPath $CopyPath
)

Write-Host "Total copy reconciliation rows:" $CopyRows.Count

if ($CopyRows.Count -ne 434) {
    throw "STOP: expected exactly 434 copy-reconciliation rows."
}

$SyntheticCopyRows = @(
    $CopyRows |
    Where-Object {
        ([string]$_.component).Trim() -eq "synthetic_root"
    }
)

Write-Host "Synthetic-root copy rows:" $SyntheticCopyRows.Count

if ($SyntheticCopyRows.Count -ne 222) {
    throw "STOP: expected exactly 222 synthetic_root copy-reconciliation rows."
}

$SyntheticCopyFailures = @(
    $SyntheticCopyRows |
    Where-Object {
        $PassText =
            ([string]$_.pass).Trim().ToLowerInvariant()

        $ExistsText =
            ([string]$_.copied_exists).Trim().ToLowerInvariant()

        $PassText -ne "true" -or
        $ExistsText -ne "true" -or
        ([string]$_.source_sha256).Trim().ToLowerInvariant() -ne
            ([string]$_.copied_sha256).Trim().ToLowerInvariant()
    }
)

if ($SyntheticCopyFailures.Count -gt 0) {
    $SyntheticCopyFailures |
        Select-Object `
            component,
            relative_path,
            copied_exists,
            pass,
            source_sha256,
            copied_sha256 |
        Format-Table -AutoSize

    throw "STOP: synthetic_root copy reconciliation contains failures."
}

Write-Host "222 / 222 synthetic-root copy reconciliation: PASS"


Write-Host ""
Write-Host "===== SOURCE RESTORE PRECHECK ====="

$ExtractedCount = @(
    Get-ChildItem `
        -LiteralPath $ExtractedRoot `
        -File `
        -Recurse `
        -Force
).Count

Write-Host "Extracted source count:" $ExtractedCount

if ($ExtractedCount -ne 222) {
    throw "STOP: extracted synthetic_root count changed from 222."
}

if (Test-Path -LiteralPath $RestoreRoot) {
    throw "STOP: restoration target already exists. Do not overwrite it."
}

Write-Host "SOURCE RESTORE PRECHECK: PASS"
```

### Expected end

We want:

```text
Package manifest rows: 436
Synthetic-root manifest rows: 222

222 / 222 synthetic-root manifest verification: PASS

Total copy reconciliation rows: 434
Synthetic-root copy rows: 222
222 / 222 synthetic-root copy reconciliation: PASS

Extracted source count: 222
SOURCE RESTORE PRECHECK: PASS
```

That is actually **stronger verification** than the prior script attempted because it ties the 222 restored files directly to the sealed package-level manifest and the package's source-to-submission copy reconciliation.

---

## Then restore the physical source and share

Only after the previous block ends in `SOURCE RESTORE PRECHECK: PASS`, paste this:

```powershell
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$TempRoot =
    "C:\MSBF\_A1B_SOURCE_RESTORE_TEMP_20260902"

$ExtractedRoot =
    "$TempRoot\synthetic_root"

$RestoreParent =
    "C:\MSBF\MSBF_PBI_A1B_WORKING_R1_20260819"

$RestoreRoot =
    "$RestoreParent\synthetic_root"

$ShareName =
    "MSBF_PBI_A1B_SYNTHETIC"


Write-Host "===== RESTORE ACCEPTED PHYSICAL SOURCE ====="

if (Test-Path -LiteralPath $RestoreRoot) {
    throw "STOP: target synthetic_root already exists."
}

New-Item `
    -ItemType Directory `
    -Path $RestoreParent `
    -Force |
    Out-Null

Copy-Item `
    -LiteralPath $ExtractedRoot `
    -Destination $RestoreParent `
    -Recurse

$RestoredCount = @(
    Get-ChildItem `
        -LiteralPath $RestoreRoot `
        -File `
        -Recurse `
        -Force
).Count

Write-Host "Restored files:" $RestoredCount

if ($RestoredCount -ne 222) {
    throw "STOP: restored source does not contain exactly 222 files."
}


Write-Host ""
Write-Host "===== POST-COPY HASH RECONCILIATION ====="

$ManifestRows = @(
    Import-Csv `
        -LiteralPath "$TempRoot\MANIFEST_SHA256.csv"
)

$SyntheticManifestRows = @(
    $ManifestRows |
    Where-Object {
        ([string]$_.relative_path) -match '^synthetic_root[\\/]'
    }
)

$PostCopyFailures = @()

foreach ($Row in $SyntheticManifestRows) {

    $RelativeInsideRoot =
        ([string]$Row.relative_path) `
            -replace '^synthetic_root[\\/]+', ''

    $RelativeInsideRoot =
        $RelativeInsideRoot.Replace("/", "\")

    $RestoredPath =
        Join-Path $RestoreRoot $RelativeInsideRoot

    if (-not (Test-Path -LiteralPath $RestoredPath)) {
        $PostCopyFailures +=
            "MISSING: $RelativeInsideRoot"
        continue
    }

    $Item =
        Get-Item -LiteralPath $RestoredPath

    if ($Item.Length -ne [int64]$Row.bytes) {
        $PostCopyFailures +=
            "BYTE_MISMATCH: $RelativeInsideRoot"
        continue
    }

    $ActualHash = (
        Get-FileHash `
            -LiteralPath $RestoredPath `
            -Algorithm SHA256
    ).Hash.ToLowerInvariant()

    $ExpectedHash =
        ([string]$Row.sha256).Trim().ToLowerInvariant()

    if ($ActualHash -ne $ExpectedHash) {
        $PostCopyFailures +=
            "HASH_MISMATCH: $RelativeInsideRoot"
    }
}

if ($PostCopyFailures.Count -gt 0) {
    $PostCopyFailures
    throw "STOP: restored source differs from sealed manifest."
}

Write-Host "Restored source 222 / 222 hash reconciliation: PASS"


Write-Host ""
Write-Host "===== RESTORE LOCAL SMB SHARE ====="

$ExistingShare =
    Get-SmbShare `
        -Name $ShareName `
        -ErrorAction SilentlyContinue

if ($null -ne $ExistingShare) {

    if (
        $ExistingShare.Path.TrimEnd('\') -ne
        $RestoreRoot.TrimEnd('\')
    ) {
        throw "STOP: existing SMB share points to [$($ExistingShare.Path)] instead of [$RestoreRoot]."
    }

    Write-Host "Existing share already points to correct source."
}
else {

    $Identity =
        [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

    New-SmbShare `
        -Name $ShareName `
        -Path $RestoreRoot `
        -ReadAccess $Identity `
        -CachingMode None |
        Out-Null

    Write-Host "Created read-only share for:" $Identity
}


Write-Host ""
Write-Host "===== FINAL PHYSICAL / UNC VALIDATION ====="

$UNC =
    "\\localhost\$ShareName"

$Checks = [ordered]@{
    "Physical root"  = Test-Path $RestoreRoot
    "Physical pbi"   = Test-Path "$RestoreRoot\pbi"
    "Physical build" = Test-Path "$RestoreRoot\build"
    "UNC root"       = Test-Path $UNC
    "UNC pbi"        = Test-Path "$UNC\pbi"
    "UNC build"      = Test-Path "$UNC\build"
}

$Checks.GetEnumerator() |
    Format-Table -AutoSize

if ($Checks.Values -contains $false) {
    throw "STOP: final physical/UNC validation failed."
}

Write-Host ""
Write-Host "SMB identity:"
Get-SmbShare -Name $ShareName |
    Select-Object Name,Path |
    Format-List

Write-Host "SMB access:"
Get-SmbShareAccess -Name $ShareName |
    Format-Table `
        AccountName,
        AccessControlType,
        AccessRight `
        -AutoSize

Write-Host ""
Write-Host "A1B ACCEPTED SOURCE RESTORE: PASS"
```

The package construction evidence establishes that `COPY_RECONCILIATION.csv` was generated over the component folders, including `synthetic_root`, and the Focused R2 submission produced 434 controls with zero failures. [export reference: filecite | turn105file0 | L16-L98]

So this failure is now classified as:

```text
RESTORE ATTEMPT 1
STOP — verifier expected nonexistent synthetic-specific manifest filename

Source/carrier issue:
NO

Sealed carrier:
PASS

Extracted source population:
222 / 222

Correct verification authority:
MANIFEST_SHA256.csv + COPY_RECONCILIATION.csv
```

Run the **first corrected verification block** and give me its output before doing the copy/share block.
<!-- END_SOURCE_MESSAGE -->


<a id="m-0f9f337f-c1d0-4b99-ba15-0eb3198b4330"></a>
## Andrew / user · C109-M00622

C109-M00622 · 2026-09-02T09:10:23.932000-04:00 · active path

Preceding visible parent: [C109-M00621](part-29.md#m-0a53a918-1f43-4454-9a7f-6ead80e06a6f)

<!-- BEGIN_SOURCE_MESSAGE -->
I was downloading my chatgpt extract and it took up too much space and caused this error. what should i do now to get this back on track? i cleared 4gb so space should not be an issue when retrying: >>     Format-Table `
>>         AccountName,
>>         AccessControlType,
>>         AccessRight `
>>         -AutoSize
>>
>> Write-Host ""
>> Write-Host "A1B ACCEPTED SOURCE RESTORE: PASS"
===== RESTORE ACCEPTED PHYSICAL SOURCE =====
Copy-Item:
Line |
  32 |  Copy-Item `
     |  ~~~~~~~~~~~
     | There is not enough space on the disk. : 'C:\MSBF\MSBF_PBI_A1B_WORKING_R1_20260819\synthetic_root\pbi\data\core\msbf_m1\application_verification_fraud_snapshot.csv'.
<!-- END_SOURCE_MESSAGE -->


<a id="m-01279910-5b6d-450d-9667-9d39787d0c4c"></a>
## Assistant · C109-M00623

C109-M00623 · 2026-09-02T09:10:27.946330-04:00 · active path

Preceding visible parent: [C109-M00622](part-29.md#m-0f9f337f-c1d0-4b99-ba15-0eb3198b4330)

<!-- BEGIN_SOURCE_MESSAGE -->
This is recoverable and does **not** indicate a source or Power BI defect. The copy failed because the C: drive filled while writing the restored A1b source. Since you had already reached `RESTORE ACCEPTED PHYSICAL SOURCE`, the sealed carrier and the extracted 222-file source had already passed the earlier prechecks. The accepted source population is indeed 222 files. [export reference: filecite | turn104file3 | L283-L300]

The right recovery is: **stop the competing download, delete only the incomplete restore target, keep the verified temporary extraction, confirm enough free space, and retry the copy/hash/share steps.**

First, cancel or pause the ChatGPT export download for now. I would not let anything large continue writing to C: until Power BI refresh is finished.

Then keep Power BI closed and use your **Administrator PowerShell**.

## 1. Check how much space the restore actually needs

Run:

```powershell
$ExtractedRoot =
    "C:\MSBF\_A1B_SOURCE_RESTORE_TEMP_20260902\synthetic_root"

$RestoreRoot =
    "C:\MSBF\MSBF_PBI_A1B_WORKING_R1_20260819\synthetic_root"

$SourceBytes = (
    Get-ChildItem `
        -LiteralPath $ExtractedRoot `
        -File `
        -Recurse `
        -Force |
    Measure-Object Length -Sum
).Sum

$FreeBytes = (Get-PSDrive C).Free

[pscustomobject]@{
    SourceFiles = @(
        Get-ChildItem $ExtractedRoot -File -Recurse -Force
    ).Count

    SourceGB = [math]::Round($SourceBytes / 1GB, 3)
    FreeGB   = [math]::Round($FreeBytes / 1GB, 3)

    RecommendedFreeGB =
        [math]::Round(($SourceBytes + 2GB) / 1GB, 3)
} | Format-List
```

We want:

```text
SourceFiles : 222
```

and ideally:

```text
FreeGB > RecommendedFreeGB
```

I am deliberately adding about **2 GB of working headroom** because Power BI itself will need disk for refresh/cache serialization after the restore.

If your 4 GB free does not exceed that recommendation, free a little more before continuing.

---

# 2. Remove the incomplete copy only

The failed `Copy-Item` created a **partial**:

```text
C:\MSBF\MSBF_PBI_A1B_WORKING_R1_20260819\synthetic_root
```

That partial tree must not be resumed or trusted.

Run:

```powershell
$RestoreRoot =
    "C:\MSBF\MSBF_PBI_A1B_WORKING_R1_20260819\synthetic_root"

if (Test-Path -LiteralPath $RestoreRoot) {

    $PartialFiles = @(
        Get-ChildItem `
            -LiteralPath $RestoreRoot `
            -File `
            -Recurse `
            -Force `
            -ErrorAction SilentlyContinue
    ).Count

    Write-Host "Removing incomplete restore containing $PartialFiles files..."

    Remove-Item `
        -LiteralPath $RestoreRoot `
        -Recurse `
        -Force
}

Write-Host "Restore target absent:" (-not (Test-Path $RestoreRoot))
```

Expected:

```text
Restore target absent: True
```

**Do not delete:**

```text
C:\MSBF\_A1B_SOURCE_RESTORE_TEMP_20260902
```

That is our already verified extraction.

---

# 3. Retry the restore with disk-space protection

Now paste this complete block:

```powershell
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$TempRoot =
    "C:\MSBF\_A1B_SOURCE_RESTORE_TEMP_20260902"

$ExtractedRoot =
    "$TempRoot\synthetic_root"

$RestoreParent =
    "C:\MSBF\MSBF_PBI_A1B_WORKING_R1_20260819"

$RestoreRoot =
    "$RestoreParent\synthetic_root"

$ShareName =
    "MSBF_PBI_A1B_SYNTHETIC"


Write-Host "===== RESUME PREFLIGHT ====="

if (-not (Test-Path -LiteralPath $ExtractedRoot)) {
    throw "STOP: verified extracted synthetic_root is missing."
}

$SourceFiles = @(
    Get-ChildItem `
        -LiteralPath $ExtractedRoot `
        -File `
        -Recurse `
        -Force
)

if ($SourceFiles.Count -ne 222) {
    throw "STOP: extracted source no longer contains exactly 222 files."
}

$SourceBytes = (
    $SourceFiles |
    Measure-Object Length -Sum
).Sum

$FreeBytes = (Get-PSDrive C).Free

$RequiredFree =
    $SourceBytes + 2GB

Write-Host "Source files:" $SourceFiles.Count
Write-Host "Source GB:   " ([math]::Round($SourceBytes / 1GB, 3))
Write-Host "Free GB:     " ([math]::Round($FreeBytes / 1GB, 3))
Write-Host "Required GB: " ([math]::Round($RequiredFree / 1GB, 3))

if ($FreeBytes -lt $RequiredFree) {
    throw "STOP: insufficient C: free space for controlled restore plus Power BI working headroom."
}

if (Test-Path -LiteralPath $RestoreRoot) {
    throw "STOP: restore target still exists. Do not merge into a partial tree."
}

Write-Host "Resume preflight: PASS"


Write-Host ""
Write-Host "===== RESTORE ACCEPTED PHYSICAL SOURCE ====="

New-Item `
    -ItemType Directory `
    -Path $RestoreParent `
    -Force |
    Out-Null

Copy-Item `
    -LiteralPath $ExtractedRoot `
    -Destination $RestoreParent `
    -Recurse `
    -Force

$RestoredFiles = @(
    Get-ChildItem `
        -LiteralPath $RestoreRoot `
        -File `
        -Recurse `
        -Force
)

Write-Host "Restored files:" $RestoredFiles.Count

if ($RestoredFiles.Count -ne 222) {
    throw "STOP: restored source does not contain exactly 222 files."
}


Write-Host ""
Write-Host "===== POST-COPY MANIFEST RECONCILIATION ====="

$ManifestPath =
    "$TempRoot\MANIFEST_SHA256.csv"

if (-not (Test-Path -LiteralPath $ManifestPath)) {
    throw "STOP: sealed package MANIFEST_SHA256.csv is missing."
}

$ManifestRows = @(
    Import-Csv -LiteralPath $ManifestPath |
    Where-Object {
        ([string]$_.relative_path) -match '^synthetic_root[\\/]'
    }
)

if ($ManifestRows.Count -ne 222) {
    throw "STOP: expected 222 synthetic_root manifest rows."
}

$Failures = @()

foreach ($Row in $ManifestRows) {

    $RelativeInsideRoot =
        ([string]$Row.relative_path) `
            -replace '^synthetic_root[\\/]+', ''

    $RelativeInsideRoot =
        $RelativeInsideRoot.Replace("/", "\")

    $RestoredPath =
        Join-Path $RestoreRoot $RelativeInsideRoot

    if (-not (Test-Path -LiteralPath $RestoredPath)) {
        $Failures += "MISSING: $RelativeInsideRoot"
        continue
    }

    $FileItem =
        Get-Item -LiteralPath $RestoredPath

    if ($FileItem.Length -ne [int64]$Row.bytes) {
        $Failures += "BYTE_MISMATCH: $RelativeInsideRoot"
        continue
    }

    $ActualHash = (
        Get-FileHash `
            -LiteralPath $RestoredPath `
            -Algorithm SHA256
    ).Hash.ToLowerInvariant()

    $ExpectedHash =
        ([string]$Row.sha256).Trim().ToLowerInvariant()

    if ($ActualHash -ne $ExpectedHash) {
        $Failures += "HASH_MISMATCH: $RelativeInsideRoot"
    }
}

if ($Failures.Count -gt 0) {
    $Failures
    throw "STOP: restored source differs from sealed Focused R2 manifest."
}

Write-Host "Restored source 222 / 222 manifest reconciliation: PASS"


Write-Host ""
Write-Host "===== RESTORE LOCAL SMB SHARE ====="

$ExistingShare =
    Get-SmbShare `
        -Name $ShareName `
        -ErrorAction SilentlyContinue

if ($null -ne $ExistingShare) {

    if (
        $ExistingShare.Path.TrimEnd('\') -ne
        $RestoreRoot.TrimEnd('\')
    ) {
        throw "STOP: existing SMB share points to the wrong source path."
    }

    Write-Host "Existing share already points to correct source."
}
else {

    $Identity =
        [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

    New-SmbShare `
        -Name $ShareName `
        -Path $RestoreRoot `
        -ReadAccess $Identity `
        -CachingMode None |
        Out-Null

    Write-Host "Created read-only SMB share for:" $Identity
}


Write-Host ""
Write-Host "===== FINAL RESTORE VALIDATION ====="

$UNC =
    "\\localhost\$ShareName"

$Checks = [ordered]@{
    "Physical root"  = Test-Path $RestoreRoot
    "Physical pbi"   = Test-Path "$RestoreRoot\pbi"
    "Physical build" = Test-Path "$RestoreRoot\build"
    "UNC root"       = Test-Path $UNC
    "UNC pbi"        = Test-Path "$UNC\pbi"
    "UNC build"      = Test-Path "$UNC\build"
}

$Checks.GetEnumerator() |
    Format-Table -AutoSize

if ($Checks.Values -contains $false) {
    throw "STOP: final physical/UNC validation failed."
}

Write-Host ""
Get-SmbShare -Name $ShareName |
    Select-Object Name,Path |
    Format-List

Get-SmbShareAccess -Name $ShareName |
    Format-Table `
        AccountName,
        AccessControlType,
        AccessRight `
        -AutoSize

Write-Host ""
Write-Host "Remaining C: free GB:" `
    ([math]::Round((Get-PSDrive C).Free / 1GB, 3))

Write-Host ""
Write-Host "A1B ACCEPTED SOURCE RESTORE: PASS"
```

## Why we should restart the copy rather than resume it

The failed copy stopped partway through a CSV:

```text
application_verification_fraud_snapshot.csv
```

So we must treat the entire destination as **incomplete/untrusted**. Deleting the destination and copying the already verified source again gives us deterministic recovery. The subsequent 222/222 SHA-256 reconciliation proves that the restored copy exactly matches the sealed accepted package.

The Focused R2 audit independently verified the complete carrier and clean extraction, including all unchanged 222 synthetic-root files. [export reference: filecite | turn105file6 | L576-L622]

### After `A1B ACCEPTED SOURCE RESTORE: PASS`

Do **not** delete the temporary extraction yet.

We will:

1. reopen the R26 Power BI candidate;
2. retry **Refresh All**;
3. confirm the 24 network-path errors disappear;
4. complete the R26 Desktop checkpoint;
5. only after the refresh/save/reopen succeeds, clean up:
   ```text
   C:\MSBF\_A1B_SOURCE_RESTORE_TEMP_20260902
   ```

So the current event should be recorded as:

```text
A1B SOURCE RESTORE ATTEMPT 1
ENVIRONMENTAL STOP — C: DISK CAPACITY EXHAUSTED

Sealed source identity:
PASS

Extracted source:
222 / 222

Power BI/source contradiction:
NONE

Remediation:
free disk → discard partial target → exact recopy → 222/222 hash reconciliation
```

Your 4 GB cleanup may already be enough, but run the first space calculation before the copy so we know rather than assume.
<!-- END_SOURCE_MESSAGE -->


<a id="m-05fc8522-57b0-40b7-bafb-a4854c70b8d4"></a>
## Andrew / user · C109-M00624

C109-M00624 · 2026-09-02T09:14:14.710000-04:00 · active path

Preceding visible parent: [C109-M00623](part-29.md#m-01279910-5b6d-450d-9667-9d39787d0c4c)

<!-- BEGIN_SOURCE_MESSAGE -->
===== RESUME PREFLIGHT =====
Source files: 222
Source GB:    0.143
Free GB:      4.022
Required GB:  2.143
Resume preflight: PASS

===== RESTORE ACCEPTED PHYSICAL SOURCE =====
Restored files: 222

===== POST-COPY MANIFEST RECONCILIATION =====
Restored source 222 / 222 manifest reconciliation: PASS

===== RESTORE LOCAL SMB SHARE =====
New-SmbShare:
Line |
 189 |      New-SmbShare `
     |      ~~~~~~~~~~~~~~
     | Access is denied.
<!-- END_SOURCE_MESSAGE -->


<a id="m-25c91063-a154-4a43-9484-2cfa4e8d7ee1"></a>
## Assistant · C109-M00625

C109-M00625 · 2026-09-02T09:14:18.616920-04:00 · active path

Preceding visible parent: [C109-M00624](part-29.md#m-05fc8522-57b0-40b7-bafb-a4854c70b8d4)

<!-- BEGIN_SOURCE_MESSAGE -->
Good news: the **source restore itself is complete and verified**.

You now have:

```text
222 source files restored
222 / 222 manifest reconciliation PASS
```

So **do not recopy anything**. The only remaining failure is Windows permissions for creating the SMB share.

`New-SmbShare : Access is denied` means the PowerShell session was not elevated enough to create a Windows file share. That is an OS administration issue, not a source or Power BI issue.

Open a new **Windows PowerShell as Administrator** window and run only this share-restoration block:

```powershell
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RestoreRoot =
    "C:\MSBF\MSBF_PBI_A1B_WORKING_R1_20260819\synthetic_root"

$ShareName =
    "MSBF_PBI_A1B_SYNTHETIC"

Write-Host "===== ADMIN / SOURCE PRECHECK ====="

$IsAdmin = (
    New-Object Security.Principal.WindowsPrincipal(
        [Security.Principal.WindowsIdentity]::GetCurrent()
    )
).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)

Write-Host "Running elevated:" $IsAdmin
Write-Host "Restore root exists:" (Test-Path -LiteralPath $RestoreRoot)

if (-not $IsAdmin) {
    throw "STOP: PowerShell is not running as Administrator."
}

if (-not (Test-Path -LiteralPath $RestoreRoot)) {
    throw "STOP: restored synthetic_root is missing."
}

$FileCount = @(
    Get-ChildItem `
        -LiteralPath $RestoreRoot `
        -File `
        -Recurse `
        -Force
).Count

Write-Host "Restored files:" $FileCount

if ($FileCount -ne 222) {
    throw "STOP: restored source no longer contains exactly 222 files."
}


Write-Host ""
Write-Host "===== CREATE / VERIFY SMB SHARE ====="

$ExistingShare =
    Get-SmbShare `
        -Name $ShareName `
        -ErrorAction SilentlyContinue

if ($null -ne $ExistingShare) {

    if (
        $ExistingShare.Path.TrimEnd('\') -ne
        $RestoreRoot.TrimEnd('\')
    ) {
        throw "STOP: existing SMB share points to [$($ExistingShare.Path)] instead of [$RestoreRoot]."
    }

    Write-Host "Existing share already points to correct source."
}
else {

    $Identity =
        [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

    New-SmbShare `
        -Name $ShareName `
        -Path $RestoreRoot `
        -ReadAccess $Identity `
        -CachingMode None |
        Out-Null

    Write-Host "Created read-only share for:" $Identity
}


Write-Host ""
Write-Host "===== SHARE IDENTITY ====="

Get-SmbShare -Name $ShareName |
    Select-Object Name,Path |
    Format-List

Get-SmbShareAccess -Name $ShareName |
    Format-Table `
        AccountName,
        AccessControlType,
        AccessRight `
        -AutoSize


Write-Host ""
Write-Host "===== UNC ACCESS ====="

$UNC =
    "\\localhost\$ShareName"

$Checks = [ordered]@{
    "UNC root"  = Test-Path $UNC
    "UNC pbi"   = Test-Path "$UNC\pbi"
    "UNC build" = Test-Path "$UNC\build"
}

$Checks.GetEnumerator() |
    Format-Table -AutoSize

if ($Checks.Values -contains $false) {
    throw "STOP: one or more UNC checks failed."
}

Write-Host ""
Write-Host "A1B SMB SOURCE RESTORE: PASS"
```

You want the end to show:

```text
Running elevated: True
Restored files: 222

UNC root   True
UNC pbi    True
UNC build  True

A1B SMB SOURCE RESTORE: PASS
```

If `New-SmbShare` still says `Access is denied` even with `Running elevated: True`, then stop and paste the output. In that case we would inspect Windows SMB/server-service permissions rather than touching the source or Power BI.

Once this passes, reopen the R26 Power BI project and retry **Home → Refresh**. Do not change `pDataRoot`, `pBuildRoot`, or any query definitions.
<!-- END_SOURCE_MESSAGE -->


<a id="m-2f946ac1-7520-49b8-bd72-d94a4b13b93e"></a>
## Andrew / user · C109-M00626

C109-M00626 · 2026-09-02T09:15:39.374000-04:00 · active path

Preceding visible parent: [C109-M00625](part-29.md#m-25c91063-a154-4a43-9484-2cfa4e8d7ee1)

<!-- BEGIN_SOURCE_MESSAGE -->
===== ADMIN / SOURCE PRECHECK =====
Running elevated: True
Restore root exists: True
Restored files: 222

===== CREATE / VERIFY SMB SHARE =====
Created read-only share for: Owner\Andrew

===== SHARE IDENTITY =====

Name : MSBF_PBI_A1B_SYNTHETIC
Path : C:\MSBF\MSBF_PBI_A1B_WORKING_R1_20260819\synthetic_root


AccountName  AccessControlType AccessRight
-----------  ----------------- -----------
Owner\Andrew             Allow        Read


===== UNC ACCESS =====

Name      Value
----      -----
UNC root  True
UNC pbi   True
UNC build True


A1B SMB SOURCE RESTORE: PASS
<!-- END_SOURCE_MESSAGE -->


<a id="m-04bc5cd1-6141-4c60-b2c6-8e31ecf1eedc"></a>
## Assistant · C109-M00627

C109-M00627 · 2026-09-02T09:15:42.981937-04:00 · active path

Preceding visible parent: [C109-M00626](part-29.md#m-2f946ac1-7520-49b8-bd72-d94a4b13b93e)

<!-- BEGIN_SOURCE_MESSAGE -->
Excellent. That closes the environmental dependency cleanly.

```text
A1B CORE SOURCE RESTORE — PASS

Physical source:
C:\MSBF\MSBF_PBI_A1B_WORKING_R1_20260819\synthetic_root

Source files:
222

Sealed-manifest reconciliation:
222 / 222 PASS

SMB share:
\\localhost\MSBF_PBI_A1B_SYNTHETIC

Share target:
C:\MSBF\MSBF_PBI_A1B_WORKING_R1_20260819\synthetic_root

Access:
Owner\Andrew — Read

UNC root:
PASS

UNC pbi:
PASS

UNC build:
PASS
```

The earlier failures are therefore closed as **environmental restoration issues only**:

- original refresh failure: missing legacy A1b source/share;
- restore attempt 1: disk-full interruption;
- SMB creation attempt 1: non-elevated Windows permission;
- final restored source/share: **PASS**.

No Power Query, DAX, relationship, visual, R22 carrier, or R26 carrier change was required.

## Now return to the R26 Power BI candidate

Keep this folder for now:

```text
C:\MSBF\_A1B_SOURCE_RESTORE_TEMP_20260902
```

Do **not** delete it until the R26 refresh + save/reopen cycle passes.

Before opening Desktop, I would make one quick space check:

```powershell
[math]::Round((Get-PSDrive C).Free / 1GB, 3)
```

If you still have roughly 3+ GB free, proceed. Pause the ChatGPT export/download until we're finished with Power BI.

Then open the R26 project again. From your normal PowerShell window:

```powershell
$DeliveryRoot =
    "C:\MSBF\PowerBI\R26_Parallel\MSBF_PBI_R26_PARALLEL_REFINEMENT_C1_20260902_DELIVERY"

$R26Pbir = (
    Get-ChildItem `
        "$DeliveryRoot\project" `
        -Recurse `
        -Filter definition.pbir |
    Where-Object {
        $_.FullName -match "Report"
    } |
    Select-Object -First 1
).FullName

Write-Host $R26Pbir

Start-Process $R26Pbir
```

### In Power BI Desktop

Once the R26 report fully opens:

1. Go to **Home → Refresh**.
2. Let the entire refresh complete.
3. Do **not** edit any visual or query during the refresh.
4. The previous group of `The network name cannot be found` failures should now be gone.

If refresh fails, send me the exact query name(s) and error text. Do not make a local fix.

If refresh succeeds, **do not immediately start P02 QA**. Our next controlled action will be running:

```text
tests\R26_DESKTOP_CHECKPOINTS.dax
```

against the freshly refreshed physical R26 model.

That will verify the 15,600 / 47 monitoring population, R26 policy identity, day-14 checkpoint, M2.11 populations, G3-v2 identity, and the other physical model controls before we trust the rendered pages.
<!-- END_SOURCE_MESSAGE -->


<a id="m-de10a24b-d078-4b4e-bfec-01721256b649"></a>
## Andrew / user · C109-M00628

C109-M00628 · 2026-09-02T09:39:15.949000-04:00 · active path

Preceding visible parent: [C109-M00627](part-29.md#m-04bc5cd1-6141-4c60-b2c6-8e31ecf1eedc)

<!-- BEGIN_SOURCE_MESSAGE -->
The refresh was successful.
<!-- END_SOURCE_MESSAGE -->


<a id="m-b97fda7d-54d2-4d96-ac20-0add77e0f98c"></a>
## Assistant · C109-M00629

C109-M00629 · 2026-09-02T09:40:39.381149-04:00 · active path

Preceding visible parent: [C109-M00628](part-29.md#m-de10a24b-d078-4b4e-bfec-01721256b649)

<!-- BEGIN_SOURCE_MESSAGE -->
Good. Record this as:

```text
R26 POWER BI PHYSICAL REFRESH — PASS

Core A1b source restored and reachable
R26 successor carrier reachable
Full Desktop refresh completed successfully
Prior network-path failure resolved
No Power Query modification required
```

That gets us back onto the intended path.

Next, **keep Power BI open** and run the physical model checkpoint before touching any visuals.

1. In Power BI Desktop, click **DAX Query View** in the left navigation.
2. Click **New query**.
3. Open this local file:

```text
C:\MSBF\PowerBI\R26_Parallel\
MSBF_PBI_R26_PARALLEL_REFINEMENT_C1_20260902_DELIVERY\
tests\R26_DESKTOP_CHECKPOINTS.dax
```

4. Copy the entire contents into the new DAX query.
5. Click **Run**.

The first result set should return two rows for **8/8/2026**.

Expected:

| Scenario | Active paths | Operationally alerted | Adverse | Raw conditions | Operational families |
|---|---:|---:|---:|---:|---:|
| Baseline | 100 | 12 | 11 | 102 | 23 |
| Recession Energy | 25 | 2 | 2 | 18 | 4 |

The Baseline `100 / 12 / 11` checkpoint is one of the explicit R26 controls, and the full source reconciliation also supports the Recession values above.

The second result set should show:

```text
G3-v2 pass controls  = 70
G3-v2 fail controls  = 0

Certification ID
= G3V2_R26_C053DC064AB32A4D21864F94
```

The authority state should remain the R26 **candidate-only / audit-pending** state, not a publication-ready state.

Take a screenshot of each results grid, or paste the returned values here.

If both result sets match, our next step is **P02 physical validation**—Baseline/Recession rendering and tooltip evidence—not more source repair.
<!-- END_SOURCE_MESSAGE -->


<a id="m-c4b25713-b03c-4537-b938-7607abdf1ced"></a>
## Andrew / user · C109-M00630

C109-M00630 · 2026-09-02T09:51:30.636000-04:00 · active path

Preceding visible parent: [C109-M00629](part-29.md#m-b97fda7d-54d2-4d96-ac20-0add77e0f98c)

**Editorial record note:** 11 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: 587f5f70-5ef1-49ae-ad41-1b31d634dd99.png; 019ecea5-3d9d-44b4-8cd0-4c3bfbe398f4.png; ccfc09ba-cd68-408c-b817-ce0cdf6d553c.png; 8047e770-1a6b-49e0-9728-09b0d9aa7d0f.png; 748c0a3c-1939-4eb0-ad65-4a452fb6e35b.png; a92e0197-1ff0-4cf8-9425-3f0760058a38.png; 009f5455-5b75-44a0-9373-81760d8f003a.png; 4407594a-2b90-48f8-bdbc-aa6c582e8233.png; 5d47a127-b7e0-4c90-b9b0-d57b8c9c6370.png; 8bec000d-bb61-43b0-8557-b8217a03145e.png; 87618637-f0f4-42db-87b4-579006302110.png

<!-- BEGIN_SOURCE_MESSAGE -->
[No text body in export; see attachment/non-text note above.]
<!-- END_SOURCE_MESSAGE -->
