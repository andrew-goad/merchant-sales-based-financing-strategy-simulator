# MSBF - Power BI Executive Portfolio Intelligence Part 2

Part 35 · [Conversation index](README.md) · [History home](../../README.md)

> Historical dialogue: commands and approvals below describe past events. They are not current execution or publication instructions. Attachment references do not establish recovered bytes.

[Previous part](part-34.md)
[Next part](part-36.md)

<a id="m-7d727534-495f-4271-9fee-f618f4824e6e"></a>
## Assistant · C109-M00763

C109-M00763 · 2026-09-02T19:19:03.839072-04:00 · active path

Preceding visible parent: [C109-M00762](part-34.md#m-b3123996-5855-4301-9422-adadde1f55a7)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. Below is the **explicit implementation sequence** I would follow from where you are now. The goal is to stop improvising inside P03 and first repair the carrier/model with one proper successor lifecycle table.

The governing point is that the current successor carrier already exposes R1 decision, monitoring, intervention, operational setup, servicing, certification, etc., but the funded lifecycle dates were omitted from the curated projection. The R1/R26 handoff explicitly says to preserve the source-owned chain rather than reconstruct it in DAX. [export reference: filecite | turn140file0 | L82-L103]

## Step 1 — Create the physical `R1FactFundedLifecycle.csv`

Do this outside Power BI first.

1. Open **File Explorer**.
2. Go to:
   `C:\MSBF\R26\power_bi\carrier`
3. Confirm you see:
   - `curated`
   - `raw`
   - `SUCCESSOR_DATA_CATALOG.csv`
   - package manifest/receipt files.
4. Do **not** edit `R1FactDailyMonitoring.csv`.
5. We need to create a new file:
   `C:\MSBF\R26\power_bi\carrier\curated\R1FactFundedLifecycle.csv`

The preferred source is the exact R1 M2.4 lifecycle population. Since you have the retained R1/R26 physical source chain locally, the easiest controlled route is to generate the 130-row CSV from the accepted successor source—not from report DAX.

Use PostgreSQL/psql only if that R1 successor database is still available. If it is not, we can derive the carrier file from the exact retained R17 M2.5 source payload, because that source physically carries the M2.4 lifecycle dates forward. The M2.5 source contains `funding_date`, `portfolio_activation_date`, `monitoring_start_date`, and related funded terms. [export reference: filecite | turn141file0 | L11-L35]

Before I give you a source-generation script, tell me which of these is currently available locally:

- the accepted R1/R26 database containing the successor M2.4 objects; or
- the raw R17 M2.5 CSV under the carrier.

You almost certainly have the second one. Check:

`C:\MSBF\R26\power_bi\carrier\raw\r17\m2_5_power_bi.csv`

If that file exists, we can create the lifecycle file from it without touching the database.

## Step 2 — Build the lifecycle CSV from the raw R17 source

Assuming that file exists, use PowerShell.

Open a normal PowerShell window and run:

```powershell
$Source = "C:\MSBF\R26\power_bi\carrier\raw\r17\m2_5_power_bi.csv"
$Target = "C:\MSBF\R26\power_bi\carrier\curated\R1FactFundedLifecycle.csv"

$Rows = Import-Csv -LiteralPath $Source

$Lifecycle =
    $Rows |
    Group-Object module1_run_id,scenario_id,merchant_application_id |
    ForEach-Object {

        $g = $_.Group
        $r = $g | Select-Object -First 1

        [pscustomobject]@{
            module1_run_id                 = $r.module1_run_id
            scenario_id                    = $r.scenario_id
            scenario_code                  = $r.scenario_code
            merchant_application_id        = $r.merchant_application_id
            population_id                  = $r.population_id
            merchant_id                    = $r.merchant_id

            synthetic_account_id           = $r.synthetic_account_id
            synthetic_advance_id           = $r.synthetic_advance_id

            booking_date                   = $r.booking_date
            funding_date                   = $r.funding_date
            portfolio_activation_date      = $r.portfolio_activation_date
            monitoring_start_date           = $r.monitoring_start_date
            first_expected_remittance_date = $r.first_expected_remittance_date

            funded_amount                  = $r.funded_amount
            collection_horizon_days        = $r.collection_horizon_days
        }
    }

$Lifecycle |
    Export-Csv -LiteralPath $Target -NoTypeInformation -Encoding UTF8

Write-Host "Rows:" $Lifecycle.Count
Write-Host "Target:" $Target
```

Important: if `booking_date` does **not** exist in the R17 raw M2.5 file, PowerShell will leave it blank. That is acceptable temporarily; do not infer it. Funding date is the critical P03 field.

The source files show that M2.4 distinguishes booking, funding, activation, monitoring, and first-remittance dates, so those dates should remain independent source fields. [export reference: filecite | turn141file3 | L337-L344]

## Step 3 — Validate the new file before Power BI

Run:

```powershell
$Lifecycle = Import-Csv "C:\MSBF\R26\power_bi\carrier\curated\R1FactFundedLifecycle.csv"

"Rows = $($Lifecycle.Count)"
"Distinct application-scenario keys = $(
    ($Lifecycle |
        ForEach-Object { "$($_.module1_run_id)|$($_.scenario_id)|$($_.merchant_application_id)" } |
        Sort-Object -Unique).Count
)"
```

Expected:

```text
Rows = 130
Distinct application-scenario keys = 130
```

Then check 738:

```powershell
$Lifecycle |
    Where-Object {
        $_.merchant_application_id -eq "MSBF_POP_0001_M000738_A01"
    } |
    Format-List *
```

Expected Baseline facts include:

```text
scenario_code                  : BASELINE
funding_date                   : 2026-07-25
portfolio_activation_date      : 2026-07-25
monitoring_start_date          : 2026-07-25
first_expected_remittance_date : 2026-07-26
funded_amount                  : 25000
collection_horizon_days        : 60
```

There should be **no Recession Energy row for 738**, because that scenario is not funded.

If those values do not appear, stop there and send me the output. Do not continue into Power BI.

## Step 4 — Add the Power Query table

Once the CSV validates:

1. Open the current PBIP:
   `MSBF_PBI_R26_PARALLEL_REFINEMENT_C1_20260902`
2. Go to **Home → Transform data**.
3. In Power Query Editor, go to **Home → New Source → Text/CSV**.
4. Browse to:
   `C:\MSBF\R26\power_bi\carrier\curated\R1FactFundedLifecycle.csv`
5. Select the file.
6. Click **Transform Data**, not Load.
7. Rename the query exactly:
   `R1FactFundedLifecycle`

Now set data types explicitly:

- `module1_run_id` → Whole Number
- `scenario_id` → Whole Number
- `scenario_code` → Text
- `merchant_application_id` → Text
- `population_id` → Text
- `merchant_id` → Text
- `synthetic_account_id` → Text
- `synthetic_advance_id` → Text
- `booking_date` → Date
- `funding_date` → Date
- `portfolio_activation_date` → Date
- `monitoring_start_date` → Date
- `first_expected_remittance_date` → Date
- `funded_amount` → Decimal Number
- `collection_horizon_days` → Whole Number

Do not create calculated lifecycle dates in Power Query.

## Step 5 — Add the semantic keys in Power Query

Because your R1 successor model uses `ApplicationScenarioKey` consistently, add it here too.

In Power Query:

1. Go to **Add Column → Custom Column**.
2. Name:
   `ApplicationScenarioKey`
3. Formula:

```powerquery
Text.From([module1_run_id])
    & "|"
    & Text.From([scenario_id])
    & "|"
    & [merchant_application_id]
```

4. Click OK.
5. Set its type to **Text**.

If you also want consistent R1 lineage keys, add:

```powerquery
ApplicationKey =
Text.From([module1_run_id])
    & "|"
    & [merchant_application_id]
```

and:

```powerquery
RunScenarioKey =
Text.From([module1_run_id])
    & "|"
    & Text.From([scenario_id])
```

I would add all three so this table behaves like the rest of the successor carrier.

## Step 6 — Add lineage columns

Since this is a controlled integration delta, add:

- `R1SourceBoundary`
- `R1AuthorityState`

Use **Add Column → Custom Column**.

For `R1SourceBoundary`:

```powerquery
"R1_M2_4_FUNDED_LIFECYCLE_VIA_R17"
```

For `R1AuthorityState`:

```powerquery
"CANDIDATE_ONLY_PENDING_R26_INTEGRATION_REVIEW"
```

For `R1SourceArtifactSha256`, I would not fabricate a hash manually. Either:
- use the exact raw R17 source SHA already in the carrier catalog, or
- leave it out until we update the carrier manifest formally.

The existing successor catalog identifies the raw R17 monitoring source and its SHA, so this can be lineage-bound later rather than guessed. [export reference: filecite | turn143file3 | L109-L110]

## Step 7 — Load the table

1. In Power Query Editor, click **Home → Close & Apply**.
2. Wait for the table to load.
3. Go to **Data view**.
4. Select `R1FactFundedLifecycle`.
5. Verify row count = **130**.

## Step 8 — Create the relationship

Go to **Model view**.

Create:

`R1DimApplicationScenario[ApplicationScenarioKey]`

to:

`R1FactFundedLifecycle[ApplicationScenarioKey]`

Set:

- Cardinality: **One to many (1:*)**
- Cross filter direction: **Single**
- Make this relationship active: **checked**

Click OK.

Do not relate the lifecycle table directly to `DimMerchant`, `DimApplication`, or scenario by merchant-only keys.

## Step 9 — Validate the relationship before changing P03

Create this temporary DAX measure:

```DAX
R26 P03 DEBUG Lifecycle Rows =
COUNTROWS ( 'R1FactFundedLifecycle' )
```

Put it in a temporary card on P03.

Test:

**Merchant 000738 / Baseline**

Expected:

```text
1
```

Then switch to:

**Merchant 000738 / Recession Energy**

Expected:

```text
0
```

If you get 1 / 0, the exact scenario-key relationship is working.

## Step 10 — Replace `Funded Lifecycle Available`

Use this full replacement:

```DAX
R26 P03 Funded Lifecycle Available =
VAR _Rows =
    COUNTROWS (
        'R1FactFundedLifecycle'
    )
RETURN
    IF (
        _Rows = 1,
        1,
        0
    )
```

Because the relationship now does the filtering, we no longer need unnecessary `TREATAS` machinery here.

If you prefer a defensive exact-key version, use:

```DAX
R26 P03 Funded Lifecycle Available =
VAR _Key =
    SELECTEDVALUE (
        'R1DimApplicationScenario'[ApplicationScenarioKey]
    )
VAR _Rows =
    CALCULATE (
        COUNTROWS (
            'R1FactFundedLifecycle'
        ),
        TREATAS (
            { _Key },
            'R1FactFundedLifecycle'[ApplicationScenarioKey]
        )
    )
RETURN
    IF (
        NOT ISBLANK ( _Key )
            && _Rows = 1,
        1,
        0
    )
```

I prefer the defensive version for P03.

## Step 11 — Replace Funding Date measure

Use:

```DAX
R26 P03 Funding Date =
VAR _Key =
    SELECTEDVALUE (
        'R1DimApplicationScenario'[ApplicationScenarioKey]
    )
RETURN
    IF (
        [R26 P03 Funded Lifecycle Available] = 1
            && NOT ISBLANK ( _Key ),
        CALCULATE (
            SELECTEDVALUE (
                'R1FactFundedLifecycle'[funding_date]
            ),
            TREATAS (
                { _Key },
                'R1FactFundedLifecycle'[ApplicationScenarioKey]
            )
        )
    )
```

Format:

1. Select the measure in the Data pane.
2. **Measure tools → Format → Date**
3. Use your preferred short date format, probably:
   `M/d/yyyy`

## Step 12 — Put Funding Date back into Proposed structure

Select the Proposed structure table.

Final order:

1. Amount
2. Remittance
3. Payback multiple
4. Horizon days
5. Repayment
6. Funding date

Use only the **measure** `R26 P03 Funding Date`.

Do not put the raw lifecycle `funding_date` column into the visual.

## Step 13 — Fix the decision tile colors

Your Decision Class / Label should remain based on `R1FactFinalDecision`.

Use:

```DAX
R26 P03 Decision Tile Background =
SWITCH (
    [R26 P03 Decision Class],
    "AUTHORIZED", "#2E7D32",
    "REVIEW",     "#C58A00",
    "DECLINED",   "#C62828",
    "#D9D9D9"
)
```

For both the upper and lower decision cards:

1. Select the card.
2. **Format visual → General → Effects → Background**
3. Click **fx**.
4. Format style → **Field value**
5. Base it on → `R26 P03 Decision Tile Background`
6. Click OK.

Keep:
- Uniform padding = **0**
- text wrap = On
- value alignment = Center.

## Step 14 — Fix Recommendation narrative

Replace the current Recommendation measure with:

```DAX
R26 P03 Decision Narrative =
VAR _Key =
    SELECTEDVALUE (
        'R1DimApplicationScenario'[ApplicationScenarioKey]
    )
RETURN
    IF (
        NOT ISBLANK ( _Key ),
        CALCULATE (
            SELECTEDVALUE (
                'R1FactFinalDecision'[decision_why_text]
            ),
            TREATAS (
                { _Key },
                'R1FactFinalDecision'[ApplicationScenarioKey]
            )
        )
    )
```

Then:

1. Select the Recommendation text visual.
2. Remove the current narrative measure.
3. Add `R26 P03 Decision Narrative`.
4. Keep the heading **Recommendation**.

For 738 / Baseline, it should no longer say manual authorization is required.

## Step 15 — Retest 738 as the primary regression case

For **738 / Baseline**, verify all of these at once:

- green tile
- `AUTHORIZED`
- `Approved as requested`
- proposed amount `$25,000.00`
- remittance `13.40%`
- payback multiple `1.21`
- horizon `60`
- repayment `$30,209.08`
- funding date `7/25/2026`
- funded lifecycle available
- Account performance populated
- Monitoring journey populated
- Recommendation reflects R1 authorization, not predecessor review.

Then switch only Scenario to **Recession Energy**:

- red tile
- declined/evidence decline
- no proposed funded lifecycle
- Funding date blank
- Account performance blank
- Monitoring journey blank
- no Baseline date leaking across.

That single merchant/scenario pair is now a very strong regression test for correct successor-vs-predecessor authority handling.

The one thing I need from you before you execute Step 2 is simply confirmation that this file exists:

`C:\MSBF\R26\power_bi\carrier\raw\r17\m2_5_power_bi.csv`

If it does, use the sequence above. If it does not, I will give you the exact alternative extraction route from the retained R1 M2.4 source instead.
<!-- END_SOURCE_MESSAGE -->


<a id="m-dbba06fe-a410-43ec-b706-d6755316cbcc"></a>
## Andrew / user · C109-M00764

C109-M00764 · 2026-09-02T19:43:38.358000-04:00 · active path

Preceding visible parent: [C109-M00763](part-35.md#m-7d727534-495f-4271-9fee-f618f4824e6e)

**Editorial record note:** Attachment references: MSBF_R26_POWER_BI_FUNDED_LIFECYCLE_EXPORT_RESULT.zip; MSBF_R26_POWER_BI_FUNDED_LIFECYCLE_EXPORT_RESULT.zip.sha256

<!-- BEGIN_SOURCE_MESSAGE -->
# R26 FUNDED-LIFECYCLE INTEGRATION — PHYSICAL EXPORT RETURN

The bounded R1 M2.4 funded-lifecycle export has now been physically executed from the retained read-only source:

```
```

```
msbf_r1_m2_4_r6_20260830_030634
```

Attached is the generated result package:

```
```

```
MSBF_R26_POWER_BI_FUNDED_LIFECYCLE_EXPORT_RESULT.zip
```

together with its SHA-256 sidecar.

## Governing authority

R26 has now completed focused Independent Audit:

```
```

```
Decision ID: IA-D-R15-M12-001
Overall: PASS_WITH_OBSERVATIONS
R26 technical successor baseline: PASS
Version-separated repository / Power BI integration: AUTHORIZED NEXT STEP
Public supersession/publication: NOT AUTHORIZED
```

Therefore, no longer describe R26 itself as pending focused audit. The current Power BI project remains a **version-separated integration candidate pending its own bounded integration-delta review**.

## First action

Before changing the PBIP:

1.  verify the attached result ZIP against its sidecar; 
2.  ingest the complete result package and its receipt/validation evidence; 
3.  independently confirm that `R1FactFundedLifecycle.csv` is the physically generated R1 M2.4 lifecycle projection rather than a DAX- or lag-derived table; 
4.  verify expected population and uniqueness before model integration. 

Expected:

```
```

```
R1FactFundedLifecycle rows          130
BASELINE                           103
RECESSION_ENERGY                    27
Unique ApplicationScenarioKey      130
Grain                              one funded ApplicationScenarioKey
```

## Required regression case — application 738

Confirm:

```
```

```
ApplicationScenarioKey
1|5|MSBF_POP_0001_M000738_A01

Scenario
BASELINE

booking_date                    2026-07-24
funding_date                    2026-07-25
portfolio_activation_date       2026-07-25
monitoring_start_date           2026-07-25
first_expected_remittance_date  2026-07-26
funded_amount                   25000.00
collection_horizon_days         60
```

and confirm that:

```
```

```
1|6|MSBF_POP_0001_M000738_A01
RECESSION_ENERGY
```

has **no funded-lifecycle row**.

No Baseline lifecycle value may leak to the Recession Energy path.

## Integration instruction

Add:

```
```

```
R1FactFundedLifecycle
```

as a **new additive semantic object** in the current:

```
```

```
MSBF_PBI_R26_PARALLEL_REFINEMENT_C1_20260902
```

or its current direct successor working copy.

Do **not** modify:

```
```

```
R1FactDailyMonitoring
```

which remains the accepted R26 monitoring projection at:

```
```

```
15,600 rows
47 columns
```

Do not add `funding_date` as a 48th monitoring column.

## Relationship

Establish:

```
```

```
R1DimApplicationScenario[ApplicationScenarioKey]
                 1
                 |
                 v
                 *
R1FactFundedLifecycle[ApplicationScenarioKey]
```

with:

```
```

```
Cardinality             One-to-many
Cross-filter direction  Single
Active                  Yes
```

Do not relate the lifecycle object by merchant ID or application ID alone.

## Source boundary

Treat `R1FactFundedLifecycle` as the Power BI exposure of the physical R1 M2.4 funded-lifecycle authority.

Do not calculate:

```
```

```
funding_date = as_of_date + 2
```

in DAX or Power Query.

Do not infer lifecycle dates from monitoring dates.

The physical export is the lifecycle-date authority.

## P03 correction

Once the table is physically loaded and reconciled:

-  use `R1FactFundedLifecycle` for `R26 P03 Funded Lifecycle Available`; 
-  use its physical `funding_date` for `R26 P03 Funding Date`; 
-  restore **Funding date** to the Proposed Structure table; 
-  preserve final-decision authority from `R1FactFinalDecision[governed_final_outcome_code]`; 
-  preserve the R1 final-decision narrative from `decision_why_text`; 
-  do not allow predecessor decision or M1 review language to control the R26 P03 decision presentation. 

For 738 / Baseline, final P03 should reconcile to:

```
```

```
Decision              AUTHORIZED
Label                 Approved as requested
Amount                $25,000.00
Remittance            13.40%
Payback multiple      1.21
Horizon               60 days
Repayment             $30,209.08
Funding date          7/25/2026
Lifecycle             Present
```

For 738 / Recession Energy:

```
```

```
Decision              DECLINED
Funding date          BLANK
Lifecycle             Absent
Account performance   BLANK
Monitoring journey    BLANK
```

## Carrier/inventory treatment

Record this as a bounded **R26 Power BI integration delta**, not an R26 source correction:

```
```

```
New semantic object
R1FactFundedLifecycle

Rows
130

Grain
ApplicationScenarioKey

Source
Physical R1 M2.4 funded lifecycle

R1FactDailyMonitoring
UNCHANGED — 15,600 / 47

R26 monitoring policy
UNCHANGED

R26 technical certification
UNCHANGED — 70/70
```

Update the successor data catalog, Power Query/model inventory, relationship inventory, lineage documentation, model counts, integration-delta register, and validation evidence accordingly.

## Continue after lifecycle integration

Do not stop merely after loading the CSV.

After the lifecycle object passes:

1.  complete the P03 corrections; 
2.  run the 738 Baseline/Recession Energy regression; 
3.  test additional funded and nonfunded scenario paths; 
4.  confirm P01/P02/P04/P05/P06 nonregression except for already authorized R26 integration/refinement changes; 
5.  continue the remaining Power BI refinement work; 
6.  preserve this lifecycle addition for the final save/close/reopen and bounded integration-audit evidence package. 

Do **not** publish Power BI, activate public supersession, or alter accepted predecessor artifacts through this action.
<!-- END_SOURCE_MESSAGE -->


<a id="m-40c9d28c-ca7d-41e7-b480-e8c4229f5376"></a>
## Assistant · C109-M00765

C109-M00765 · 2026-09-02T19:45:30.607973-04:00 · active path

Preceding visible parent: [C109-M00764](part-35.md#m-dbba06fe-a410-43ec-b706-d6755316cbcc)

<!-- BEGIN_SOURCE_MESSAGE -->
The funded-lifecycle export package passes the requested pre-integration checks. I would proceed with integration.

I verified the ZIP SHA-256 against the sidecar:

`74e5051319a815ae648d0c73987d2f642c46854b07e41a6d555a590a2bf8a7ee` — **PASS**

The ZIP itself is structurally clean, all four internal SHA-256 sidecars validate, and the receipt reports the retained read-only source as:

`msbf_r1_m2_4_r6_20260830_030634`  
`msbf_m2.application_booking_funding_activation_latest`

The physical raw export and curated table both contain **130 rows**. The raw 15 lifecycle fields are byte-for-data identical to those same 15 fields in the curated 23-column table; the additional eight curated fields are deterministic semantic keys/lineage fields, not lifecycle calculations. The supplied Power Query M only reads and types the CSV—it does not calculate funding dates. I also independently verified **103 Baseline / 27 Recession Energy / 130 unique ApplicationScenarioKey / zero duplicate keys**, no nulls in the physical lifecycle fields, and valid date ordering across all 130 rows.

For merchant 738 specifically, I verified:

```text
1|5|MSBF_POP_0001_M000738_A01
BASELINE

booking_date                    2026-07-24
funding_date                    2026-07-25
portfolio_activation_date       2026-07-25
monitoring_start_date           2026-07-25
first_expected_remittance_date  2026-07-26
funded_amount                   25000.00
collection_horizon_days         60
```

and there is **no** row for:

`1|6|MSBF_POP_0001_M000738_A01`

So the Baseline/Recession scenario boundary is physically clean.

Also, I will use the updated authority language going forward:

> **R26 technical successor baseline = accepted. Current Power BI work = version-separated integration candidate pending bounded integration-delta review. Publication/public supersession = not authorized.**

## Recommended physical integration sequence

I would make one adjustment to the earlier workflow: **do not directly mutate the accepted R26 carrier root if we can avoid it.** Create an additive integration carrier copy first. That gives us a clean R26 → integration-candidate diff.

### 1. Save and close Power BI first

In Power BI Desktop:

1. Press **Ctrl+S**.
2. Close the PBIP.
3. Do not reopen it yet.

### 2. Create a separate integration carrier

Open PowerShell and run:

```powershell
$SourceCarrier = "C:\MSBF\R26\power_bi\carrier"
$IntegrationCarrier = "C:\MSBF\R26\power_bi\carrier_integration_c1"

if (Test-Path $IntegrationCarrier) {
    throw "Integration carrier already exists: $IntegrationCarrier"
}

Copy-Item `
    -LiteralPath $SourceCarrier `
    -Destination $IntegrationCarrier `
    -Recurse

Write-Host "Created integration carrier:"
Write-Host $IntegrationCarrier
```

This preserves the accepted R26 carrier untouched.

### 3. Extract the verified lifecycle package

Assuming you placed the downloaded result ZIP somewhere accessible, extract it to a temporary folder. For example:

```powershell
$Zip = "C:\MSBF\MSBF_R26_POWER_BI_FUNDED_LIFECYCLE_EXPORT_RESULT.zip"
$Temp = "C:\MSBF\_R26_FUNDED_LIFECYCLE_EXPORT"

if (Test-Path $Temp) {
    Remove-Item $Temp -Recurse -Force
}

Expand-Archive `
    -LiteralPath $Zip `
    -DestinationPath $Temp

Get-ChildItem $Temp -Recurse
```

You should see the same 12 package members I verified.

### 4. Copy the curated lifecycle object into the integration carrier

Run:

```powershell
Copy-Item `
    -LiteralPath "$Temp\curated\R1FactFundedLifecycle.csv" `
    -Destination "$IntegrationCarrier\curated\R1FactFundedLifecycle.csv"
```

Then copy the raw R6 source evidence:

```powershell
New-Item `
    -ItemType Directory `
    -Force `
    -Path "$IntegrationCarrier\raw\r6" |
    Out-Null

Copy-Item `
    -LiteralPath "$Temp\raw\r6\m2_4_funded_lifecycle.csv" `
    -Destination "$IntegrationCarrier\raw\r6\m2_4_funded_lifecycle.csv"
```

Do **not** touch:

`R1FactDailyMonitoring.csv`

### 5. Verify the physical copied table

Run:

```powershell
$Lifecycle =
    Import-Csv "$IntegrationCarrier\curated\R1FactFundedLifecycle.csv"

"Rows: $($Lifecycle.Count)"

"Baseline: $(
    @($Lifecycle | Where-Object scenario_code -eq 'BASELINE').Count
)"

"Recession Energy: $(
    @($Lifecycle | Where-Object scenario_code -eq 'RECESSION_ENERGY').Count
)"

"Unique keys: $(
    @($Lifecycle.ApplicationScenarioKey | Sort-Object -Unique).Count
)"
```

Expected:

```text
Rows: 130
Baseline: 103
Recession Energy: 27
Unique keys: 130
```

Then:

```powershell
$Lifecycle |
    Where-Object ApplicationScenarioKey -eq `
        "1|5|MSBF_POP_0001_M000738_A01" |
    Format-List
```

Confirm `funding_date = 2026-07-25`.

And:

```powershell
$Lifecycle |
    Where-Object ApplicationScenarioKey -eq `
        "1|6|MSBF_POP_0001_M000738_A01"
```

Expected: **no output**.

## 6. Point the working PBIP to the integration carrier

Your current project uses `pSuccessorRoot`.

Open the PBIP again.

Then:

1. **Home → Transform data → Transform data**
2. In Power Query Editor, select parameter **`pSuccessorRoot`**.
3. Change only its working-copy value from:

   `C:\MSBF\R26\power_bi\carrier`

   to:

   `C:\MSBF\R26\power_bi\carrier_integration_c1`

4. Do not change the accepted carrier files themselves.

This makes the current PBIP explicitly a **version-separated integration candidate**.

## 7. Add `R1FactFundedLifecycle` in Power Query

Still in Power Query Editor:

1. **Home → New Source → Blank Query**
2. In the Queries pane, rename it exactly:

   `R1FactFundedLifecycle`

3. Select the query.
4. **Home → Advanced Editor**
5. Delete everything currently in the editor.
6. Paste this exact M from the verified export package:

```powerquery
let
    Source = Csv.Document(
        File.Contents(pSuccessorRoot & "\\curated\\R1FactFundedLifecycle.csv"),
        [Delimiter=",", Encoding=65001, QuoteStyle=QuoteStyle.Csv]
    ),
    PromotedHeaders = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
    Typed = Table.TransformColumnTypes(
        PromotedHeaders,
        {
            {"module1_run_id", Int64.Type},
            {"scenario_id", Int64.Type},
            {"scenario_code", type text},
            {"merchant_application_id", type text},
            {"merchant_id", type text},
            {"population_id", type text},
            {"synthetic_account_id", type text},
            {"synthetic_advance_id", type text},
            {"booking_date", type date},
            {"funding_date", type date},
            {"portfolio_activation_date", type date},
            {"monitoring_start_date", type date},
            {"first_expected_remittance_date", type date},
            {"funded_amount", type number},
            {"collection_horizon_days", Int64.Type},
            {"ApplicationKey", type text},
            {"RunScenarioKey", type text},
            {"ApplicationScenarioKey", type text},
            {"AccountKey", type text},
            {"AdvanceKey", type text},
            {"R1SourceBoundary", type text},
            {"R1SourceArtifactSha256", type text},
            {"R1AuthorityState", type text}
        }
    )
in
    Typed
```

7. Click **Done**.
8. Confirm the preview shows **23 columns**.
9. Confirm the date columns display as dates.
10. **Home → Close & Apply**.

Do not add calculated keys or calculated dates—the physical export already contains them.

## 8. Verify the new semantic table

After the model loads:

1. Go to **Data view**.
2. Select `R1FactFundedLifecycle`.
3. Confirm the status bar/table count reports **130 rows**.
4. Scroll through the fields and confirm:
   - `funding_date`
   - `ApplicationScenarioKey`
   - `R1SourceBoundary`
   - `R1AuthorityState`

are present.

## 9. Create the relationship

Go to **Model view**.

Drag:

`R1DimApplicationScenario[ApplicationScenarioKey]`

onto:

`R1FactFundedLifecycle[ApplicationScenarioKey]`

In the relationship dialog set:

- **Cardinality:** One to many (`1:*`)
- **Cross-filter direction:** Single
- **Make this relationship active:** checked

Click **OK**.

Do not create merchant-ID or application-ID relationships.

## 10. Add/replace the two lifecycle measures

Open **DAX Query View → New query**.

Paste:

```DAX
DEFINE

    MEASURE 'R1Measures'[R26 P03 Funded Lifecycle Available] =
        VAR _Key =
            SELECTEDVALUE (
                'R1DimApplicationScenario'[ApplicationScenarioKey]
            )
        VAR _Rows =
            CALCULATE (
                COUNTROWS (
                    'R1FactFundedLifecycle'
                ),
                TREATAS (
                    { _Key },
                    'R1FactFundedLifecycle'[ApplicationScenarioKey]
                )
            )
        RETURN
            IF (
                NOT ISBLANK ( _Key )
                    && _Rows = 1,
                1,
                0
            )


    MEASURE 'R1Measures'[R26 P03 Funding Date] =
        VAR _Key =
            SELECTEDVALUE (
                'R1DimApplicationScenario'[ApplicationScenarioKey]
            )
        RETURN
            IF (
                [R26 P03 Funded Lifecycle Available] = 1
                    && NOT ISBLANK ( _Key ),
                CALCULATE (
                    SELECTEDVALUE (
                        'R1FactFundedLifecycle'[funding_date]
                    ),
                    TREATAS (
                        { _Key },
                        'R1FactFundedLifecycle'[ApplicationScenarioKey]
                    )
                )
            )

EVALUATE
ROW (
    "Lifecycle rows",
        [R26 P03 Funded Lifecycle Available],
    "Funding date",
        [R26 P03 Funding Date]
)
```

Then:

1. Click **Update model with changes**.
2. Let Power BI replace the existing measures if prompted.
3. Run the query.

With 738 / Baseline selected, expected:

```text
Lifecycle rows   1
Funding date     7/25/2026
```

Switch the P03 Scenario slicer to Recession Energy and rerun if necessary:

```text
Lifecycle rows   0
Funding date     blank
```

## 11. Format Funding Date

In the Data pane:

1. Select `R26 P03 Funding Date`.
2. Go to **Measure tools**.
3. **Format → Date**
4. Choose a short date representation matching the page, preferably:

   `M/d/yyyy`

## 12. Restore Funding date to Proposed structure

On P03:

1. Select the **Proposed structure** table.
2. In **Build visual**, remove any raw:
   - `operational_activation_date`
   - old predecessor funding date
   - obsolete funding-date measure
3. Add:

   `R1Measures[R26 P03 Funding Date]`

4. Move it to the final column.

Final order:

**Amount | Remittance | Payback multiple | Horizon days | Repayment | Funding date**

For 738 / Baseline, this should now show exactly one row with `7/25/2026`.

## 13. Correct Decision Narrative now

The current 738 narrative shown earlier was still predecessor/review language.

Replace `R26 P03 Decision Narrative` with:

```DAX
R26 P03 Decision Narrative =
VAR _Key =
    SELECTEDVALUE (
        'R1DimApplicationScenario'[ApplicationScenarioKey]
    )
RETURN
    IF (
        NOT ISBLANK ( _Key ),
        CALCULATE (
            SELECTEDVALUE (
                'R1FactFinalDecision'[decision_why_text]
            ),
            TREATAS (
                { _Key },
                'R1FactFinalDecision'[ApplicationScenarioKey]
            )
        )
    )
```

Then make sure the visible **Recommendation** block uses this measure.

738 / Baseline should no longer state that manual authorization remains required.

## 14. Correct the decision-card background

Use this exact measure:

```DAX
R26 P03 Decision Tile Background =
SWITCH (
    [R26 P03 Decision Class],
    "AUTHORIZED", "#2E7D32",
    "REVIEW",     "#C58A00",
    "DECLINED",   "#C62828",
    "#D9D9D9"
)
```

For **both** decision cards:

1. Select the card.
2. **Format visual → General → Effects → Background**
3. Click **fx**.
4. **Format style → Field value**
5. Base on:
   `R26 P03 Decision Tile Background`
6. Click **OK**.

738 / Baseline must now be green.

## 15. Run the full 738 regression

### 738 / Baseline

Confirm simultaneously:

```text
Decision             AUTHORIZED
Label                Approved as requested
Tile                 Green
Amount               $25,000.00
Remittance           13.40%
Payback multiple     1.21
Horizon              60
Repayment            $30,209.08
Funding date         7/25/2026
Lifecycle available  1
```

And:

- Recommendation reflects the R1 authorized outcome.
- Account performance exists.
- Monitoring journey exists.

### 738 / Recession Energy

Confirm:

```text
Decision             DECLINED
Funding date         blank
Lifecycle available  0
```

And:

- Proposed funded lifecycle does not appear.
- Account performance is blank.
- Monitoring journey is blank.
- No `7/25/2026` leakage.

## 16. Do not forget the integration-control artifacts

After the physical model works, we still need to update the **integration candidate**, not the accepted R26 source package:

- successor data catalog: append the supplied `R1FactFundedLifecycle` catalog row;
- model table count: **54 → 55**
- relationship count: **54 → 55**
- Power Query expression count: **52 → 53**
- document the new 130-row table;
- record `R1FactDailyMonitoring` unchanged at **15,600 × 47**;
- record R26 G3-v2 unchanged at **70/70**;
- preserve the export receipt and hashes in integration evidence;
- record the carrier-root change and new semantic object in the integration-delta register.

I would do those metadata/package-control updates **after** we prove the physical Power BI relationship and 738 regression, so we don't formalize an integration object that has not yet rendered correctly.

Once you reach the point where **738 / Baseline shows one proposed-structure row with `7/25/2026`**, send me that P03 screenshot. From there we can finish the remaining P03 semantic/visual regression without another source-discovery loop.
<!-- END_SOURCE_MESSAGE -->


<a id="m-191e5f99-7ce6-4fa3-8633-6a3d059cb1d1"></a>
## Andrew / user · C109-M00766

C109-M00766 · 2026-09-02T20:14:46.135000-04:00 · active path

Preceding visible parent: [C109-M00765](part-35.md#m-40c9d28c-ca7d-41e7-b480-e8c4229f5376)

<!-- BEGIN_SOURCE_MESSAGE -->
explain this - which direction is the one to many?   9. Create the relationship
Go to **Model view**.

Drag:

`R1DimApplicationScenario[ApplicationScenarioKey]`

onto:

`R1FactFundedLifecycle[ApplicationScenarioKey]`

In the relationship dialog set:

- **Cardinality:** One to many (`1:*`) 
- **Cross-filter direction:** Single 
- **Make this relationship active:** checked 

Click **OK**.

Do not create merchant-ID or application-ID relationships.
<!-- END_SOURCE_MESSAGE -->


<a id="m-0e240f7d-9f86-4a68-8b68-eaa445f0f568"></a>
## Assistant · C109-M00767

C109-M00767 · 2026-09-02T20:14:49.676654-04:00 · active path

Preceding visible parent: [C109-M00766](part-35.md#m-191e5f99-7ce6-4fa3-8633-6a3d059cb1d1)

<!-- BEGIN_SOURCE_MESSAGE -->
The **one side is `R1DimApplicationScenario`** and the **many side is `R1FactFundedLifecycle`**.

So the relationship is:

```text
R1DimApplicationScenario[ApplicationScenarioKey]   1
                                                    |
                                                    |
                                                    v
R1FactFundedLifecycle[ApplicationScenarioKey]      *
```

Why:

- `R1DimApplicationScenario` has exactly one row for each `ApplicationScenarioKey`.
- `R1FactFundedLifecycle` is a fact table. Even though this specific export currently also has one row per funded `ApplicationScenarioKey`, structurally it belongs on the **many/fact side** of the model.
- This preserves the standard dimensional pattern: **dimension filters fact**.

In the Power BI relationship dialog, if it shows:

**From table:** `R1DimApplicationScenario`  
**To table:** `R1FactFundedLifecycle`

then choose:

**Cardinality:** `One to many (1:*)`

with the **1 next to `R1DimApplicationScenario`** and the **\* next to `R1FactFundedLifecycle`**.

For cross-filter direction, choose **Single**, with filtering flowing:

```text
R1DimApplicationScenario
        ↓
R1FactFundedLifecycle
```

That way your Merchant + Scenario slicers resolve the selected `ApplicationScenarioKey` in the dimension and then filter the funded-lifecycle row. The lifecycle table does not filter back upstream into the dimension.

One nuance: because the lifecycle export is currently unique at 130/130 keys, Power BI may offer or infer **one-to-one**. I still want the model relationship treated as **dimension 1 → fact \*** unless Power BI prevents it because both sides are physically unique. If Power BI shows one-to-one as the only sensible option, send me that dialog screenshot before clicking OK.
<!-- END_SOURCE_MESSAGE -->


<a id="m-658423be-2d4c-425d-abaf-12ca739eecc5"></a>
## Andrew / user · C109-M00768

C109-M00768 · 2026-09-02T20:17:41.961000-04:00 · active path

Preceding visible parent: [C109-M00767](part-35.md#m-0e240f7d-9f86-4a68-8b68-eaa445f0f568)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: 3c282d68-c9be-493b-843b-704fd5c169dc.png

<!-- BEGIN_SOURCE_MESSAGE -->
[No text body in export; see attachment/non-text note above.]
<!-- END_SOURCE_MESSAGE -->


<a id="m-1a8b7fae-4a37-4e0d-8f84-b6f0fffa18a6"></a>
## Assistant · C109-M00769

C109-M00769 · 2026-09-02T20:17:47.318002-04:00 · active path

Preceding visible parent: [C109-M00768](part-35.md#m-658423be-2d4c-425d-abaf-12ca739eecc5)

<!-- BEGIN_SOURCE_MESSAGE -->
The screenshot is very useful. **Do not save this relationship yet.** Power BI has already created or detected another relationship involving the new lifecycle table, which is creating an ambiguous filter path.

The error tells us exactly what the competing paths are:

```text
Path 1
R1FactFundedLifecycle → DimMerchant

Path 2
R1FactFundedLifecycle
→ R1DimApplicationScenario
→ DimApplication
→ DimMerchant
```

We want **Path 2 only**. The new lifecycle table should hang off `R1DimApplicationScenario` at `ApplicationScenarioKey` grain. It should **not** also connect directly to `DimMerchant`.

### Do this now

1. In the relationship dialog you have open, click **Cancel**.
2. Go to **Model view**.
3. Find `R1FactFundedLifecycle`.
4. Look for **every relationship line currently connected to it**.

Because Power BI often auto-detects relationships when a new table is loaded, I expect you will see at least one automatically created line from `R1FactFundedLifecycle` to a core table.

### Delete the unwanted direct relationship

Find the relationship between:

`R1FactFundedLifecycle`

and

`DimMerchant`

Click the relationship line, then either:

- press **Delete**, or
- right-click → **Delete**

Confirm deletion.

We do **not** want this:

```text
DimMerchant
    ↑
R1FactFundedLifecycle
```

The lifecycle table contains `merchant_id` only as a **descriptive/lineage field**. It is not supposed to create a separate semantic filter route.

### Also inspect for other auto-detected relationships

Before creating the intended relationship, check whether Power BI also created direct relationships from `R1FactFundedLifecycle` to any of these:

- `DimApplication`
- `DimScenario`
- `DimMerchant`
- any other core dimension

If so, **delete those too**.

For this new table, I want exactly **one model relationship** at this stage:

```text
R1DimApplicationScenario[ApplicationScenarioKey]   1
                       |
                       v
R1FactFundedLifecycle[ApplicationScenarioKey]      *
```

Nothing else.

The fields such as:

- `ApplicationKey`
- `RunScenarioKey`
- `merchant_id`
- `AccountKey`
- `AdvanceKey`

remain in `R1FactFundedLifecycle` for lineage and traceability, but they should **not each become separate active relationships**. `ApplicationScenarioKey` is the governed grain key for this object.

### Then create the intended relationship again

After removing the auto-detected relationships:

1. Drag `R1DimApplicationScenario[ApplicationScenarioKey]`
2. onto `R1FactFundedLifecycle[ApplicationScenarioKey]`.

Set:

- **From table:** `R1DimApplicationScenario`
- **From column:** `ApplicationScenarioKey`
- **To table:** `R1FactFundedLifecycle`
- **To column:** `ApplicationScenarioKey`
- **Cardinality:** `One to many (1:*)`
- **Cross-filter direction:** `Single`
- **Make this relationship active:** checked

Then **Save** should become available.

### Why this matters

The existing successor model already has the proper upstream path:

```text
DimMerchant
   ↓
DimApplication
   ↓
R1DimApplicationScenario
   ↓
R1FactFundedLifecycle
```

More precisely, the existing core/successor integration uses `DimApplication[ApplicationKey] 1 → * R1DimApplicationScenario[ApplicationKey]`. The handoff established that as part of the successor model. [export reference: filecite | turn140file11 | L943-L976]

Adding another direct:

```text
DimMerchant → R1FactFundedLifecycle
```

gives Power BI two ways to reach the same data, hence the ambiguity warning.

So **cancel this dialog, delete every auto-detected lifecycle relationship, then create only the ApplicationScenarioKey relationship.**

If you want, send me a screenshot of `R1FactFundedLifecycle` in Model view after you cancel—I can tell you exactly which line(s) to delete before you touch anything.
<!-- END_SOURCE_MESSAGE -->


<a id="m-546ef257-bfc1-4967-b484-9e15c86422eb"></a>
## Andrew / user · C109-M00770

C109-M00770 · 2026-09-02T20:25:59.850000-04:00 · active path

Preceding visible parent: [C109-M00769](part-35.md#m-1a8b7fae-4a37-4e0d-8f84-b6f0fffa18a6)

**Editorial record note:** 13 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: 60b170ea-30ea-4d82-a9c5-65ca0f73fecb.png; 684c61bb-535e-4a5b-bcfc-cd69c20285ef.png; 6b77a01c-fd84-48f3-9119-cf03548277a9.png; 1fd4c917-34bf-480e-8ede-c1ddb6131c0f.png; 8147ac7f-cf06-4d6a-bb54-2e3bbf30148a.png; 7dd75412-a2ad-487e-9f23-28ffd097e8dc.png; 09ea21c7-8d3e-40e2-bb6d-4c5b1e37f76a.png; 107d2c17-1606-452a-9731-9cb59b4809ea.png; 3e0d5e04-281a-40b5-8587-83ff0dcf4f07.png; e0c5d86e-5693-4c9e-8e2c-3bbf991ed826.png; 42377b9f-6520-47a5-a4c0-75d6265b22f1.png; 663653c3-1842-4892-99eb-399ab30725ba.png; 12da5df5-9e69-4709-aac7-5c10dd8ce571.png

<!-- BEGIN_SOURCE_MESSAGE -->
[No text body in export; see attachment/non-text note above.]
<!-- END_SOURCE_MESSAGE -->


<a id="m-161e67af-7209-4114-afa0-65cfe34fe8c1"></a>
## Assistant · C109-M00771

C109-M00771 · 2026-09-02T20:26:10.290377-04:00 · active path

Preceding visible parent: [C109-M00770](part-35.md#m-546ef257-bfc1-4967-b484-9e15c86422eb)

<!-- BEGIN_SOURCE_MESSAGE -->
These screenshots clarify exactly what happened: **Power BI auto-detected a large set of relationships for the new table. None of those auto-detected relationships should remain.** The lifecycle table should have **one and only one model relationship**: the governed `ApplicationScenarioKey` relationship to `R1DimApplicationScenario`.

Most importantly, one of the auto-created relationships is **active**:

`R1FactFundedLifecycle[population_id] → DimRunCampaign[population_id]`

That active relationship is what makes the intended `R1DimApplicationScenario → R1FactFundedLifecycle` relationship ambiguous. The other auto-detected relationships are currently inactive, but they should still be removed because they are not part of the lifecycle-table contract and create unnecessary alternate semantic paths.

The successor model deliberately uses deterministic keys and controlled relationships; the handoff says not to rediscover or reconstruct alternate paths merely because columns happen to match. [export reference: filecite | turn140file0 | L31-L55]

### Delete every existing relationship connected to `R1FactFundedLifecycle`

From your screenshots, I count **13 auto-detected relationships**. Delete all of these:

| # | Other table | Lifecycle key | Status now | Action |
|---|---|---|---|---|
| 1 | `R1FactPortfolioPerformance` | `synthetic_account_id` | Inactive | **Delete** |
| 2 | `R1FactIntervention` | `synthetic_account_id` | Inactive | **Delete** |
| 3 | `FactAccountDaily` | `synthetic_advance_id` | Inactive | **Delete** |
| 4 | `FactApplicationScenario` | `ApplicationScenarioKey` | Inactive | **Delete** |
| 5 | `FactPaymentException` | `scenario_id` | Inactive | **Delete** |
| 6 | `FactFinalDecision` | `ApplicationScenarioKey` | Inactive | **Delete** |
| 7 | `DimRunCampaign` | `population_id` | **ACTIVE** | **Delete** |
| 8 | `R1FactServicingExecution` | `synthetic_account_id` | Inactive | **Delete** |
| 9 | `R1FactDailyMonitoring` | `synthetic_advance_id` | Inactive | **Delete** |
| 10 | `R1FactAccountStrategySimulation` | `AccountKey` | Inactive | **Delete** |
| 11 | `R1FactOperationalSetup` | `synthetic_account_id` | Inactive | **Delete** |
| 12 | `R1FactAccountCertification` | `synthetic_account_id` | Inactive | **Delete** |
| 13 | `R1DimApplicationScenario` | `ApplicationScenarioKey` | Inactive auto-created 1:1 | **Delete and recreate correctly** |

That last one deserves emphasis: you already have an automatically created relationship to the **right table and column**, but it is currently:

- inactive;
- `1:1`;
- bidirectional.

That is **not** the relationship contract we want.

### How to delete them

For each dotted/solid line touching `R1FactFundedLifecycle`:

1. Click the relationship line.
2. Confirm the Properties pane shows `R1FactFundedLifecycle` as one of the tables.
3. Press the **Delete** key on your keyboard.
4. Power BI will ask you to confirm deletion.
5. Click **Delete**.
6. Repeat until `R1FactFundedLifecycle` has **no relationship lines at all**.

Because there are a lot of lines close together, use the Properties pane exactly as you did in these screenshots to make sure you have selected the intended relationship before deleting it.

Do **not** delete any relationships between other existing tables. Only lines where one endpoint is `R1FactFundedLifecycle`.

### Then create exactly one relationship

Once the lifecycle table is completely isolated, drag:

`R1DimApplicationScenario[ApplicationScenarioKey]`

onto:

`R1FactFundedLifecycle[ApplicationScenarioKey]`

In the dialog, make sure the top and bottom are exactly:

```text
From table
R1DimApplicationScenario
Column
ApplicationScenarioKey

To table
R1FactFundedLifecycle
Column
ApplicationScenarioKey
```

Then set:

**Cardinality:** `One to many (1:*)`

This means:

```text
R1DimApplicationScenario                              R1FactFundedLifecycle
ApplicationScenarioKey                                ApplicationScenarioKey
          1                         →                          *
```

So the **1 belongs to `R1DimApplicationScenario`** and the **\* belongs to `R1FactFundedLifecycle`**.

Even though the current lifecycle export happens to contain exactly 130 unique keys, we are deliberately modeling it as a fact hanging off the application-scenario dimension. The semantic contract is dimension → fact, not peer-to-peer `1:1`.

Set:

**Cross-filter direction:** `Single`

The direction should be:

```text
R1DimApplicationScenario
          ↓
R1FactFundedLifecycle
```

Set:

**Make this relationship active:** `Yes`

Then click **Save**.

### Why we do not want the other relationships

The fields in `R1FactFundedLifecycle` such as:

`population_id`  
`synthetic_account_id`  
`synthetic_advance_id`  
`ApplicationKey`  
`AccountKey`  
`AdvanceKey`

are valuable **lineage and reconciliation attributes**. They are not invitations to build another model relationship for each identifier.

The governed grain of this new object is:

`ApplicationScenarioKey`

and the physical export has exactly 130 unique keys. Everything else should be reached through the established model path:

```text
DimMerchant / DimApplication / DimScenario
                ↓
       R1DimApplicationScenario
                ↓
       R1FactFundedLifecycle
```

That is why merchant 738 works correctly:

```text
738 + Baseline
→ ApplicationScenarioKey 1|5|...
→ lifecycle row exists

738 + Recession Energy
→ ApplicationScenarioKey 1|6|...
→ lifecycle row does not exist
```

No merchant-level or population-level relationship can accidentally leak the Baseline lifecycle into Recession Energy.

### One setting I want you to check before clicking Save

After deleting the 13 auto-detected relationships and recreating the intended one, the dialog should look like this:

```text
R1DimApplicationScenario              R1FactFundedLifecycle
ApplicationScenarioKey                ApplicationScenarioKey

Cardinality:
One to many (1:*)

Cross-filter direction:
Single

Active:
Yes
```

There should be **no red ambiguity warning** at the bottom.

If that is what you see, save it. If Power BI gives you a new warning despite all other lifecycle relationships being deleted, send me that dialog before proceeding.
<!-- END_SOURCE_MESSAGE -->


<a id="m-d89a066c-166c-4fac-8d33-4e804c32adcc"></a>
## Andrew / user · C109-M00772

C109-M00772 · 2026-09-02T20:32:17.281000-04:00 · active path

Preceding visible parent: [C109-M00771](part-35.md#m-161e67af-7209-4114-afa0-65cfe34fe8c1)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: 12c24c25-e319-4900-9a2c-57e24a7afa6e.png

<!-- BEGIN_SOURCE_MESSAGE -->
[No text body in export; see attachment/non-text note above.]
<!-- END_SOURCE_MESSAGE -->


<a id="m-02a638f4-70e0-44e9-b413-358af6f67524"></a>
## Assistant · C109-M00773

C109-M00773 · 2026-09-02T20:32:21.471723-04:00 · active path

Preceding visible parent: [C109-M00772](part-35.md#m-d89a066c-166c-4fac-8d33-4e804c32adcc)

<!-- BEGIN_SOURCE_MESSAGE -->
The error is actually good news: **the relationship design is fine; the wrong columns are selected in the dialog.**

In your screenshot, Power BI is currently relating:

```text
R1DimApplicationScenario[ApplicationKey]
        1
        ↓
R1FactFundedLifecycle[ApplicationKey]
        *
```

—not `ApplicationScenarioKey`.

You can see the green selection box is on **ApplicationKey** in both preview grids. That field is **not unique** in `R1DimApplicationScenario`, because each application occurs once for Baseline and once for Recession Energy. Hence Power BI reports a duplicate such as:

```text
1|MSBF_POP_0001_M000001_A01
```

That is exactly expected for `ApplicationKey`.

### Fix it in this same dialog

Do **not** cancel. Just change the selected columns.

1. In the **top grid** for `R1DimApplicationScenario`, look immediately to the right of the currently highlighted `ApplicationKey` column.
2. Click the next column:
   **`ApplicationScenarioKey`**
3. Make sure the green outline moves from `ApplicationKey` to `ApplicationScenarioKey`.

Then in the **bottom grid** for `R1FactFundedLifecycle`:

4. Again, look immediately to the right of `ApplicationKey`.
5. Click:
   **`ApplicationScenarioKey`**
6. Make sure the green outline is on `ApplicationScenarioKey`.

The dialog should then represent:

```text
FROM
R1DimApplicationScenario[ApplicationScenarioKey]

TO
R1FactFundedLifecycle[ApplicationScenarioKey]
```

### Leave these settings as they are

Keep:

- **Cardinality:** `One to many (1:*)`
- **Cross-filter direction:** `Single`
- **Make this relationship active:** checked

Once both selected columns are actually `ApplicationScenarioKey`, the duplicate-key error should disappear and **Save** should become available.

### Why `ApplicationKey` failed but `ApplicationScenarioKey` works

For merchant/application 738:

`ApplicationKey` is the same under both scenarios:

```text
1|MSBF_POP_0001_M000738_A01
```

so it occurs twice in the 1,500-row R1 dimension.

But `ApplicationScenarioKey` includes the scenario:

```text
Baseline:
1|5|MSBF_POP_0001_M000738_A01

Recession Energy:
1|6|MSBF_POP_0001_M000738_A01
```

Those are different and unique.

That is precisely why the lifecycle export and handoff require **ApplicationScenarioKey grain**—it prevents Baseline funding facts from leaking into Recession Energy.

So: **you do not have a data defect here. You simply clicked the adjacent `ApplicationKey` column instead of `ApplicationScenarioKey`.** Select `ApplicationScenarioKey` in both grids and save.
<!-- END_SOURCE_MESSAGE -->


<a id="m-305a73de-ac86-4389-994f-8b44aa9f30fc"></a>
## Andrew / user · C109-M00774

C109-M00774 · 2026-09-02T20:45:04.116000-04:00 · active path

Preceding visible parent: [C109-M00773](part-35.md#m-02a638f4-70e0-44e9-b413-358af6f67524)

**Editorial record note:** 2 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: 116b9d75-5d38-498d-9320-eb8ed3457393.png; 76f53115-4196-4264-9da5-93b6c657a8f3.png

<!-- BEGIN_SOURCE_MESSAGE -->
I'm not a big fan of the decision narrative. It is not a substantial write-up. Other than that, it seems we have made significant progress.
<!-- END_SOURCE_MESSAGE -->


<a id="m-769b9114-b761-444e-b287-fcd13486577b"></a>
## Assistant · C109-M00775

C109-M00775 · 2026-09-02T20:45:07.652733-04:00 · active path

Preceding visible parent: [C109-M00774](part-35.md#m-305a73de-ac86-4389-994f-8b44aa9f30fc)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes — the page has made a major jump. The **authority problem is now largely solved**: 738 cleanly differentiates Baseline vs. Recession Energy, Funding date is correct on the funded path, and the final decision tile/narratives no longer leak predecessor review state.

I agree with your criticism of the current **Recommendation** block. It is now factually correct, but too thin relative to the rest of the page. The operating-evidence and risk/economics blocks are substantive; the recommendation should close the story with comparable explanatory weight.

I would not simply make `decision_why_text` longer in DAX. Instead, use a **composite R1-successor narrative measure** that remains source-owned but assembles the final decision narrative with selected-structure and search context already present in the successor facts.

For example, for 738 / Baseline, the recommendation should read more like:

> The requested structure was authorized without a counteroffer. The selected terms preserve the requested $25,000 amount, 13.40% remittance rate, 1.21 payback multiple, and 60-day horizon. The structure passed the governed decision boundary and entered the funded lifecycle on July 25, 2026.

That is much more satisfying because it answers three executive questions:

**What did we decide?**  
**What structure did we authorize?**  
**Did it actually proceed into the funded lifecycle?**

For a counteroffer review, it should instead say something like:

> A supportable alternative structure was identified after governed candidate search, but the outcome remains subject to review and was not authorized for funding. The proposed terms reduce exposure and/or alter repayment economics relative to the original request; no funded lifecycle exists for this scenario.

And for a decline:

> The application was declined because governed evidence/structure requirements were not satisfied. No authorized structure or funded lifecycle was established for this scenario.

I would therefore replace the visible `Recommendation` measure with a richer **presentation measure**, but keep `R1FactFinalDecision[decision_why_text]` as the anchor rather than override it.

A good full replacement pattern is:

```DAX
R26 P03 Recommendation Narrative =
VAR _BaseNarrative =
    [R26 P03 Decision Narrative]

VAR _DecisionClass =
    [R26 P03 Decision Class]

VAR _DecisionLabel =
    [R26 P03 Decision Label]

VAR _Amount =
    [R26 P03 Selected Structure Amount]

VAR _Remittance =
    [R26 P03 Selected Remittance Rate]

VAR _PBM =
    [R26 P03 Selected Payback Multiple]

VAR _Horizon =
    [R26 P03 Selected Horizon Days]

VAR _FundingDate =
    [R26 P03 Funding Date]

RETURN
    SWITCH (
        TRUE (),

        _DecisionClass = "AUTHORIZED",
            _BaseNarrative
                & " The authorized structure is "
                & FORMAT ( _Amount, "$#,0.00" )
                & " at a "
                & FORMAT ( _Remittance, "0.00%" )
                & " remittance rate, "
                & FORMAT ( _PBM, "0.00" )
                & " payback multiple, and "
                & FORMAT ( _Horizon, "0" )
                & "-day horizon."
                & IF (
                    NOT ISBLANK ( _FundingDate ),
                    " The funded lifecycle began on "
                        & FORMAT ( _FundingDate, "mmmm d, yyyy" )
                        & ".",
                    ""
                ),

        _DecisionClass = "REVIEW",
            _BaseNarrative
                & IF (
                    NOT ISBLANK ( _Amount ),
                    " A proposed structure of "
                        & FORMAT ( _Amount, "$#,0.00" )
                        & " at a "
                        & FORMAT ( _Remittance, "0.00%" )
                        & " remittance rate, "
                        & FORMAT ( _PBM, "0.00" )
                        & " payback multiple, and "
                        & FORMAT ( _Horizon, "0" )
                        & "-day horizon remains subject to governed review.",
                    ""
                )
                & " No funded lifecycle has been established.",

        _DecisionClass = "DECLINED",
            _BaseNarrative
                & " No authorized structure or funded lifecycle was established for this scenario.",

        _BaseNarrative
    )
```

Then bind the **Recommendation** visual to:

`R26 P03 Recommendation Narrative`

instead of the shorter `R26 P03 Decision Narrative`.

I like this because it does **not invent a new decision**. It presents the existing successor decision, the exact successor proposed terms, and the physical funded-lifecycle result together in one executive-readable close.

One small visual point: you now have enough vertical room in that lower-left section that I would let Recommendation use **3–4 lines**, not force it into the same compact height as before. The page balance still works, and the recommendation is important enough to deserve the extra space.

So yes: **keep the current P03 structure, but materially strengthen Recommendation.** That is the next change I would make before freezing the page.
<!-- END_SOURCE_MESSAGE -->


<a id="m-66fda1d2-8ce0-4c07-ba8d-ab6c6e464dd1"></a>
## Andrew / user · C109-M00776

C109-M00776 · 2026-09-02T20:54:35.278000-04:00 · active path

Preceding visible parent: [C109-M00775](part-35.md#m-769b9114-b761-444e-b287-fcd13486577b)

<!-- BEGIN_SOURCE_MESSAGE -->
what does it even mean to a user reading when it says, "The independent scenario authorized..." It sounds too technical still.
<!-- END_SOURCE_MESSAGE -->


<a id="m-33342071-e602-4d9c-89f5-cd842667dde9"></a>
## Assistant · C109-M00777

C109-M00777 · 2026-09-02T20:54:39.364946-04:00 · active path

Preceding visible parent: [C109-M00776](part-35.md#m-66fda1d2-8ce0-4c07-ba8d-ab6c6e464dd1)

<!-- BEGIN_SOURCE_MESSAGE -->
I agree. **“The independent scenario authorized…” is model/process language, not business-user language.** A user reading P03 should not have to understand what an “independent scenario” is to know what happened.

For the page, the Recommendation should speak in plain decision terms:

- what happened,
- why,
- what structure resulted,
- and whether it funded.

For 738 / Baseline, I would use wording more like:

> **The requested structure was approved as submitted.** The $25,000 request, 13.40% remittance rate, 1.21 payback multiple, and 60-day term satisfied the governed decision requirements. The account entered the funded lifecycle on July 25, 2026.

That is much clearer.

For other classes, I would use the same business-facing pattern:

- **Counteroffer authorized:** “A revised structure was approved after the requested terms did not fully satisfy the governed decision requirements. The approved structure reduced or adjusted the original request while remaining within the required risk and economic boundaries.”
- **Counteroffer review:** “A revised structure was identified, but it requires additional review before it can be authorized. No funded lifecycle has been established.”
- **Underwriting review:** “The application requires additional underwriting review before a final authorization can be made. No funded lifecycle has been established.”
- **Evidence decline:** “The application was declined because required underwriting evidence was not sufficient to support a complete decision. No funded lifecycle was established.”
- **No feasible structure:** “The requested structure did not meet the governed requirements, and no supportable alternative structure was identified. No funded lifecycle was established.”
- **Policy hard stop:** “The application was declined because a governed policy requirement was not satisfied. No funded lifecycle was established.”

So I would treat `decision_why_text` as a **source explanation**, not necessarily final display copy. The Power BI measure can translate that source-owned state into polished business wording without changing the underlying decision.

For 738 specifically, I would absolutely replace “The independent scenario authorized…” with **“The requested structure was approved as submitted.”** That is the right executive language.
<!-- END_SOURCE_MESSAGE -->


<a id="m-037987f9-b7e4-406e-9421-03851d95b2b1"></a>
## Andrew / user · C109-M00778

C109-M00778 · 2026-09-02T20:56:09.565000-04:00 · active path

Preceding visible parent: [C109-M00777](part-35.md#m-33342071-e602-4d9c-89f5-cd842667dde9)

<!-- BEGIN_SOURCE_MESSAGE -->
I agree with that. These merchant operating evidence / risk & economic assessment / recommendation need to be written with the user in mind and it needs to be highly marketable and clear and professional. let's work on these write-ups logic.
<!-- END_SOURCE_MESSAGE -->
