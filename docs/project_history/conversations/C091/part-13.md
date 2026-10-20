# MSBF - Power BI Executive Portfolio Intelligence

Part 13 · [Conversation index](README.md) · [History home](../../README.md)

> Historical dialogue: commands and approvals below describe past events. They are not current execution or publication instructions. Attachment references do not establish recovered bytes.

[Previous part](part-12.md)
[Next part](part-14.md)

<a id="m-244f5b48-e2da-41df-9337-6f4ade047e92"></a>
## Assistant · C091-M00170

C091-M00170 · 2026-08-20T12:19:45.062747-04:00 · active path

Preceding visible parent: [C091-M00169](part-12.md#m-71715634-7dc0-40a9-80fb-594dd3bd086a)

<!-- BEGIN_SOURCE_MESSAGE -->
E06 completed successfully, with one qualification we should preserve rather than overstate.

I inspected the actual CSV. It contains **31 rows for the 31 active relationships**, and every row reports `Pass = TRUE`:

```text
Active relationships tested       31
Pass = TRUE                        31
Pass = FALSE                        0
```

For **25 relationships**, the selected test key produced a nonblank direct row count and the propagated relationship count matched exactly. Examples include:

```text
REL-001   98 = 98
REL-006   44 = 44
REL-021  750 = 750
REL-038  120 = 120
REL-055  190 = 190
REL-056 1059 = 1059
REL-070   24 = 24
REL-080   58 = 58
```

There are, however, **6 relationships where both comparison counts are BLANK** for the automatically selected test key:

```text
REL-005   DimAccountAdvance → DimApplication
REL-045   FactPaymentException → DimAccountAdvance
REL-057   FactMonitoringEndpoint → DimMonitoringStatus
REL-072   FactAccountDaily → DimDate
REL-075   FactPaymentException → DimDate
REL-078   FactBookingActivation → DimDate
```

DAX evaluates `BLANK() = BLANK()` as true, so those six `TRUE` values are **not strong affirmative propagation evidence**. They are not failures, but we should not claim “31/31 physically demonstrated propagation” from this file alone.

So the precise E06 disposition is:

```text
E06 test population                         31/31
Nonblank propagation comparisons            25/31 PASS
False comparisons                            0
Blank/blank inconclusive comparisons         6
Relationship configuration                  31 active OneDirection
E06 overall                    PASS_WITH_FOLLOWUP
```

That is exactly why inspecting the exported data rather than relying only on the green `TRUE` column matters.

### Next: E06B targeted retest of those six

We should resolve them now before moving to orphans. The issue is the generic generator selected the **minimum dimension key**, which happens not to occur on the many side for those six relationships. The retest should instead select a key that physically exists on **both sides**.

Run this DAX query:

```dax
EVALUATE
UNION(

    /* REL-005 */
    VAR K005 =
        MINX(
            FILTER(
                VALUES('DimAccountAdvance'[ApplicationKey]),
                NOT ISBLANK('DimAccountAdvance'[ApplicationKey])
            ),
            'DimAccountAdvance'[ApplicationKey]
        )
    VAR D005 =
        CALCULATE(
            COUNTROWS('DimAccountAdvance'),
            'DimAccountAdvance'[ApplicationKey] = K005
        )
    VAR P005 =
        CALCULATE(
            COUNTROWS('DimAccountAdvance'),
            TREATAS({K005}, 'DimApplication'[ApplicationKey])
        )
    RETURN
        ROW(
            "Relationship","REL-005",
            "TestKey",K005,
            "DirectExpectedRows",D005,
            "RelationshipFilteredRows",P005,
            "Pass",D005 = P005 && NOT ISBLANK(D005)
        ),

    /* REL-045 */
    VAR K045 =
        MINX(
            FILTER(
                VALUES('FactPaymentException'[AccountKey]),
                NOT ISBLANK('FactPaymentException'[AccountKey])
            ),
            'FactPaymentException'[AccountKey]
        )
    VAR D045 =
        CALCULATE(
            COUNTROWS('FactPaymentException'),
            'FactPaymentException'[AccountKey] = K045
        )
    VAR P045 =
        CALCULATE(
            COUNTROWS('FactPaymentException'),
            TREATAS({K045}, 'DimAccountAdvance'[AccountKey])
        )
    RETURN
        ROW(
            "Relationship","REL-045",
            "TestKey",K045,
            "DirectExpectedRows",D045,
            "RelationshipFilteredRows",P045,
            "Pass",D045 = P045 && NOT ISBLANK(D045)
        ),

    /* REL-057 */
    VAR K057 =
        MINX(
            FILTER(
                VALUES('FactMonitoringEndpoint'[latest_monitoring_status_code]),
                NOT ISBLANK('FactMonitoringEndpoint'[latest_monitoring_status_code])
            ),
            'FactMonitoringEndpoint'[latest_monitoring_status_code]
        )
    VAR D057 =
        CALCULATE(
            COUNTROWS('FactMonitoringEndpoint'),
            'FactMonitoringEndpoint'[latest_monitoring_status_code] = K057
        )
    VAR P057 =
        CALCULATE(
            COUNTROWS('FactMonitoringEndpoint'),
            TREATAS({K057}, 'DimMonitoringStatus'[monitoring_status_code])
        )
    RETURN
        ROW(
            "Relationship","REL-057",
            "TestKey",K057,
            "DirectExpectedRows",D057,
            "RelationshipFilteredRows",P057,
            "Pass",D057 = P057 && NOT ISBLANK(D057)
        ),

    /* REL-072 */
    VAR K072 =
        MINX(
            FILTER(
                VALUES('FactAccountDaily'[monitoring_date]),
                NOT ISBLANK('FactAccountDaily'[monitoring_date])
            ),
            'FactAccountDaily'[monitoring_date]
        )
    VAR D072 =
        CALCULATE(
            COUNTROWS('FactAccountDaily'),
            'FactAccountDaily'[monitoring_date] = K072
        )
    VAR P072 =
        CALCULATE(
            COUNTROWS('FactAccountDaily'),
            TREATAS({K072}, 'DimDate'[Date])
        )
    RETURN
        ROW(
            "Relationship","REL-072",
            "TestKey",K072,
            "DirectExpectedRows",D072,
            "RelationshipFilteredRows",P072,
            "Pass",D072 = P072 && NOT ISBLANK(D072)
        ),

    /* REL-075 */
    VAR K075 =
        MINX(
            FILTER(
                VALUES('FactPaymentException'[originating_event_date]),
                NOT ISBLANK('FactPaymentException'[originating_event_date])
            ),
            'FactPaymentException'[originating_event_date]
        )
    VAR D075 =
        CALCULATE(
            COUNTROWS('FactPaymentException'),
            'FactPaymentException'[originating_event_date] = K075
        )
    VAR P075 =
        CALCULATE(
            COUNTROWS('FactPaymentException'),
            TREATAS({K075}, 'DimDate'[Date])
        )
    RETURN
        ROW(
            "Relationship","REL-075",
            "TestKey",K075,
            "DirectExpectedRows",D075,
            "RelationshipFilteredRows",P075,
            "Pass",D075 = P075 && NOT ISBLANK(D075)
        ),

    /* REL-078 */
    VAR K078 =
        MINX(
            FILTER(
                VALUES('FactBookingActivation'[portfolio_activation_date]),
                NOT ISBLANK('FactBookingActivation'[portfolio_activation_date])
            ),
            'FactBookingActivation'[portfolio_activation_date]
        )
    VAR D078 =
        CALCULATE(
            COUNTROWS('FactBookingActivation'),
            'FactBookingActivation'[portfolio_activation_date] = K078
        )
    VAR P078 =
        CALCULATE(
            COUNTROWS('FactBookingActivation'),
            TREATAS({K078}, 'DimDate'[Date])
        )
    RETURN
        ROW(
            "Relationship","REL-078",
            "TestKey",K078,
            "DirectExpectedRows",D078,
            "RelationshipFilteredRows",P078,
            "Pass",D078 = P078 && NOT ISBLANK(D078)
        )
)
ORDER BY [Relationship]
```

Save the result as:

```text
E06B_RELATIONSHIP_FILTER_BEHAVIOR_TARGETED.csv
```

and the screenshot as:

```text
E06B_RELATIONSHIP_FILTER_BEHAVIOR_TARGETED.png
```

For all six we now require:

```text
DirectExpectedRows        > 0
RelationshipFilteredRows  = DirectExpectedRows
Pass                       TRUE
```

If that happens, we can combine E06 + E06B and state rigorously:

> **31/31 active relationships demonstrated live-engine one-direction filter propagation using a physically populated test key.**

Then we'll run the 31 active-relationship orphan controls.
<!-- END_SOURCE_MESSAGE -->


<a id="m-652fae56-e08d-4070-8aa1-6f797e7b9691"></a>
## Andrew / user · C091-M00171

C091-M00171 · 2026-08-20T12:24:32.961000-04:00 · active path

Preceding visible parent: [C091-M00170](part-13.md#m-244f5b48-e2da-41df-9337-6f4ade047e92)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: E06B_RELATIONSHIP_FILTER_BEHAVIOR_TARGETED.png; E06B_RELATIONSHIP_FILTER_BEHAVIOR_TARGETED.csv

<!-- BEGIN_SOURCE_MESSAGE -->
E06B_RELATIONSHIP_FILTER_BEHAVIOR_TARGETED attached.
<!-- END_SOURCE_MESSAGE -->


<a id="m-e8d251d5-feba-45f3-9c3a-7e73962199d7"></a>
## Assistant · C091-M00172

C091-M00172 · 2026-08-20T12:24:41.968087-04:00 · active path

Preceding visible parent: [C091-M00171](part-13.md#m-652fae56-e08d-4070-8aa1-6f797e7b9691)

<!-- BEGIN_SOURCE_MESSAGE -->
E06B resolves the six inconclusive E06 cases cleanly. I inspected the CSV itself: every targeted relationship now uses a populated key, every direct count is positive, every propagated count matches exactly, and all six return `Pass=True`.

```text
REL-005    2 = 2     PASS
REL-045    1 = 1     PASS
REL-057   57 = 57    PASS
REL-072   59 = 59    PASS
REL-075    1 = 1     PASS
REL-078   59 = 59    PASS
```

Combined with E06, we can now state precisely:

```text
Active relationships                         31
One-direction relationships                  31
Relationships with populated-key test        31/31
Direct vs propagated counts equal            31/31
Filter-propagation failures                   0
Sole inactive relationship              REL-076
Bidirectional relationships                   0

E06 + E06B FILTER BEHAVIOR                  PASS
```

So `AUD-REL-005` now has materially stronger live-engine filter-behavior evidence. We still need the matching orphan test before considering that control's A1b evidence complete.

## E07 — all 32 relationship orphan controls

For orphan integrity, I recommend testing **all 32 physical relationships**, including inactive `REL-076`. Inactivity affects filter propagation; it does not remove the referential-integrity requirement.

We can generate the DAX deterministically from the already exported live relationship inventory rather than manually transcribing 32 keys. Use the earlier:

```text
E03_LIVE_ENGINE_RELATIONSHIPS.csv
```

Run this PowerShell block:

```powershell
$work = "C:\MSBF\MSBF_PBI_A1B_WORKING_R1_20260819"
$return = Join-Path $work "evidence\local_engine_return"

$input = Join-Path $return "E03_LIVE_ENGINE_RELATIONSHIPS.csv"
$output = Join-Path $return "E07_RELATIONSHIP_ORPHANS_QUERY.dax"

$rels = @(Import-Csv -LiteralPath $input)

if ($rels.Count -ne 32) {
    throw "STOP: expected 32 physical relationships; found $($rels.Count)."
}

function QTable([string]$name) {
    "'" + $name.Replace("'","''") + "'"
}

function QColumn([string]$table,[string]$column) {
    "$(QTable $table)[$column]"
}

$parts = @()

foreach ($r in $rels) {

    $fromColumn = QColumn $r.FromTable $r.FromColumn
    $toColumn   = QColumn $r.ToTable   $r.ToColumn

    $parts += @"
ROW(
    "Relationship", "$($r.Relationship)",
    "FromTable", "$($r.FromTable)",
    "FromColumn", "$($r.FromColumn)",
    "ToTable", "$($r.ToTable)",
    "ToColumn", "$($r.ToColumn)",
    "IsActive", "$($r.IsActive)",
    "NonBlankFromKeys",
        COUNTROWS(
            FILTER(
                VALUES($fromColumn),
                NOT ISBLANK($fromColumn)
            )
        ),
    "OrphanKeyCount",
        COUNTROWS(
            FILTER(
                VALUES($fromColumn),
                NOT ISBLANK($fromColumn)
                    &&
                NOT CONTAINS(
                    ALL($toColumn),
                    $toColumn,
                    $fromColumn
                )
            )
        )
)
"@
}

$query = @"
EVALUATE
VAR __Orphans =
    UNION(
$($parts -join ",`r`n")
    )
RETURN
    ADDCOLUMNS(
        __Orphans,
        "Pass", [OrphanKeyCount] = 0
    )
ORDER BY [Relationship]
"@

[IO.File]::WriteAllText(
    $output,
    $query,
    [Text.UTF8Encoding]::new($false)
)

Write-Host "Generated:"
Write-Host $output
Write-Host ""
Write-Host "Relationships encoded:" $rels.Count
```

Then open `E07_RELATIONSHIP_ORPHANS_QUERY.dax` in DAX Studio and execute it.

### Required E07 result

We want exactly:

```text
Rows returned                  32
Relationships tested           32
OrphanKeyCount = 0             32
Pass = TRUE                    32
Failures                        0
REL-076 included              YES
```

`NonBlankFromKeys` is included as an important diagnostic. If any relationship unexpectedly has zero nonblank many-side keys, we will distinguish that from a successful populated referential-integrity test rather than allowing `0 orphans` to hide an empty test population.

Save:

```text
E07_RELATIONSHIP_ORPHANS.csv
E07_RELATIONSHIP_ORPHANS.png
E07_RELATIONSHIP_ORPHANS_QUERY.dax
```

If all 32 return zero orphans with populated test populations where expected, we can close the relationship-integrity portion and move to **scenario isolation**, followed by the critical **AUD-ASOF-003B 2026-11-21 / 2026-11-22 / 2026-11-23 endpoint test**.
<!-- END_SOURCE_MESSAGE -->


<a id="m-a071674c-a65c-4e98-9d80-ac09d9e1f5ec"></a>
## Andrew / user · C091-M00173

C091-M00173 · 2026-08-20T12:30:04.850000-04:00 · active path

Preceding visible parent: [C091-M00172](part-13.md#m-e8d251d5-feba-45f3-9c3a-7e73962199d7)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: E07_RELATIONSHIP_ORPHANS.png; E07_RELATIONSHIP_ORPHANS.csv; E07_RELATIONSHIP_ORPHANS_QUERY.dax

<!-- BEGIN_SOURCE_MESSAGE -->
E07_RELATIONSHIP_ORPHANS attached.
<!-- END_SOURCE_MESSAGE -->


<a id="m-677b0409-e8f3-4a54-9502-344480dbb53e"></a>
## Assistant · C091-M00174

C091-M00174 · 2026-08-20T12:31:00.595702-04:00 · active path

Preceding visible parent: [C091-M00173](part-13.md#m-a071674c-a65c-4e98-9d80-ac09d9e1f5ec)

<!-- BEGIN_SOURCE_MESSAGE -->
E07 is substantively successful, with one small evidence-normalization issue that is worth fixing before we move on.

I inspected the CSV directly. All **32 physical relationships** were tested, including inactive `REL-076`. Every relationship has a **nonzero populated from-side key population**, and no relationship produced any orphan rows.

The exported `OrphanKeyCount` cells are all `BLANK()` rather than literal `0`, however. DAX treats that empty `COUNTROWS(FILTER(...))` result as blank in this construction, and your `Pass` expression therefore evaluates `BLANK() = 0` as `TRUE`. That is semantically fine, but for Audit I would prefer literal zeros so there is no ambiguity.

The current evidence establishes:

```text
Relationships tested                  32
Active                                31
Inactive                               1
REL-076 included                     YES

NonBlankFromKeys > 0                 32/32
Observed orphan rows                    0
Pass = TRUE                          32/32

Exported OrphanKeyCount values        BLANK
Literal-zero normalization          NEEDED
```

So E07 is best classified right now as **PASS_WITH_EVIDENCE_NORMALIZATION**.

### E07B — normalize the orphan counts to literal zero

We do not need to regenerate the whole 32-relationship query. Use the existing `E07_RELATIONSHIP_ORPHANS_QUERY.dax` and make one evidence-only change in its final result projection.

At the very end, your existing query currently has logic equivalent to:

```dax
RETURN
    ADDCOLUMNS(
        __Orphans,
        "Pass", [OrphanKeyCount] = 0
    )
ORDER BY [Relationship]
```

Replace only that final `RETURN` block with:

```dax
RETURN
    SELECTCOLUMNS(
        __Orphans,
        "Relationship", [Relationship],
        "FromTable", [FromTable],
        "FromColumn", [FromColumn],
        "ToTable", [ToTable],
        "ToColumn", [ToColumn],
        "IsActive", [IsActive],
        "NonBlankFromKeys", [NonBlankFromKeys],
        "OrphanKeyCount", COALESCE([OrphanKeyCount], 0),
        "Pass", COALESCE([OrphanKeyCount], 0) = 0
    )
ORDER BY [Relationship]
```

Do not alter any of the 32 relationship-specific tests above it.

Run that revised query and save the result as:

```text
E07B_RELATIONSHIP_ORPHANS_NORMALIZED.csv
E07B_RELATIONSHIP_ORPHANS_NORMALIZED.png
```

The exact required result is:

```text
Rows returned                  32
NonBlankFromKeys > 0           32/32
OrphanKeyCount = 0             32/32
Pass = TRUE                    32/32
REL-076 included                 YES
```

If that occurs, we can state cleanly:

> **All 32 physical relationships, including the sole inactive role-playing relationship REL-076, were tested against populated from-side key populations and returned zero orphan keys.**

After that normalization, the relationship evidence package will be exceptionally strong:

```text
E03  relationship metadata                PASS
E06  active filter propagation           PASS
E06B targeted populated-key follow-up    PASS
E07/E07B referential integrity           PASS
```

Then we can move directly to **scenario isolation**, followed by the critical `AUD-ASOF-003B` three-date evidence test.
<!-- END_SOURCE_MESSAGE -->


<a id="m-309609ae-dc41-48a6-8142-7908a478718d"></a>
## Andrew / user · C091-M00175

C091-M00175 · 2026-08-20T12:51:29.605000-04:00 · active path

Preceding visible parent: [C091-M00174](part-13.md#m-677b0409-e8f3-4a54-9502-344480dbb53e)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: E07B_RELATIONSHIP_ORPHANS_NORMALIZED.csv; E07B_RELATIONSHIP_ORPHANS_NORMALIZED.png

<!-- BEGIN_SOURCE_MESSAGE -->
E07B_RELATIONSHIP_ORPHANS_NORMALIZED attached.
<!-- END_SOURCE_MESSAGE -->


<a id="m-51b0c815-12d2-47e2-a11c-f98c0232bc05"></a>
## Assistant · C091-M00176

C091-M00176 · 2026-08-20T12:51:37.464285-04:00 · active path

Preceding visible parent: [C091-M00175](part-13.md#m-309609ae-dc41-48a6-8142-7908a478718d)

<!-- BEGIN_SOURCE_MESSAGE -->
E07B is now a **clean PASS**. I inspected the CSV directly:

```text
Physical relationships tested       32
Populated from-side populations      32/32
Minimum NonBlankFromKeys              1
OrphanKeyCount = 0                   32/32
Pass = TRUE                          32/32
Failures                              0

REL-076 included                     YES
REL-076 active                        NO
REL-076 nonblank keys                  1
REL-076 orphan keys                    0
```

This closes the evidence-normalization issue from E07. Combined evidence now supports:

```text
E03  Relationship metadata                    PASS
E06  Initial active filter behavior           PASS_WITH_FOLLOWUP
E06B Six populated-key follow-ups             PASS
      → Combined filter propagation           31/31 PASS
E07  Initial orphan integrity                 PASS_WITH_NORMALIZATION
E07B Literal-zero orphan integrity            32/32 PASS
```

We can move on without further relationship testing.

## E08 — Scenario isolation

We need to prove the scenario-qualified model continues to preserve the expected BASELINE versus RECESSION_ENERGY populations after A1b activation and processing.

Run this in a new DAX Studio tab:

```dax
EVALUATE
SUMMARIZECOLUMNS(
    'DimScenario'[scenario_code],

    "ApplicationScenarioRows",
        COUNTROWS('FactApplicationScenario'),

    "DistinctApplications",
        DISTINCTCOUNT('FactApplicationScenario'[merchant_application_id]),

    "DistinctMerchants",
        DISTINCTCOUNT('FactApplicationScenario'[merchant_id]),

    "BookingActivationRows",
        COUNTROWS('FactBookingActivation'),

    "FinalDecisionRows",
        COUNTROWS('FactFinalDecision'),

    "AccountCount",
        COUNTROWS('DimAccountAdvance'),

    "MonitoringEndpointRows",
        COUNTROWS('FactMonitoringEndpoint'),

    "PortfolioPerformanceEndpointRows",
        COUNTROWS('FactPortfolioPerformanceEndpoint'),

    "ServicingExecutionRows",
        COUNTROWS('FactServicingExecution')
)
ORDER BY
    'DimScenario'[scenario_code]
```

Save:

```text
E08_SCENARIO_ISOLATION.csv
E08_SCENARIO_ISOLATION.png
```

### What I expect to establish

The key population boundary remains:

```text
BASELINE
44 accepted account paths / applications

RECESSION_ENERGY
15 matched stress-overlay paths / applications

Total
59 paths
```

The 750/1,500 application-level A1b facts operate at a different grain, so we should **not** expect every column in E08 to show 44/15. The purpose of this query is to expose the scenario-specific counts at each fact's actual grain and ensure the scenario relationship does not collapse, cross-contaminate, or duplicate populations.

Do not treat different counts across facts as a failure by themselves.

## Then E09 — `AUD-ASOF-003B`

Once E08 is clean, the critical remaining control is the one A1a could not physically execute: endpoint-only fact behavior around the evidence endpoint.

We'll test exactly:

```text
2026-11-21   pre-endpoint
2026-11-22   evidence endpoint
2026-11-23   post-evidence
```

against the A1b endpoint-governed facts and the centralized as-of measures. That test needs to distinguish:

```text
pre-endpoint       no historical back-casting
endpoint           evidence becomes available
post-endpoint      outside evidence boundary / HOLD behavior
```

Run **E08 first** and send me the CSV/result. Then I'll construct E09 from the actual live scenario-isolation result and the physical endpoint-fact schemas rather than guessing at their behavior.
<!-- END_SOURCE_MESSAGE -->


<a id="m-6dbe5fe3-c75a-4c17-a72d-77981dcd87a0"></a>
## Andrew / user · C091-M00177

C091-M00177 · 2026-08-20T13:02:18.702000-04:00 · active path

Preceding visible parent: [C091-M00176](part-13.md#m-51b0c815-12d2-47e2-a11c-f98c0232bc05)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: E08_SCENARIO_ISOLATION.png; E08_SCENARIO_ISOLATION.csv

<!-- BEGIN_SOURCE_MESSAGE -->
E08_SCENARIO_ISOLATION attached.
<!-- END_SOURCE_MESSAGE -->


<a id="m-ce59b2ea-045c-45c5-a550-499f90132792"></a>
## Assistant · C091-M00178

C091-M00178 · 2026-08-20T13:02:36.382891-04:00 · active path

Preceding visible parent: [C091-M00177](part-13.md#m-6dbe5fe3-c75a-4c17-a72d-77981dcd87a0)

<!-- BEGIN_SOURCE_MESSAGE -->
E08 is a clean **scenario-isolation PASS**. I inspected the CSV directly.

```text
                           BASELINE   RECESSION_ENERGY
ApplicationScenarioRows        750                750
DistinctApplications           750                750
DistinctMerchants              750                750
BookingActivationRows          750                750
FinalDecisionRows              750                750

AccountCount                    44                 15
MonitoringEndpointRows          44                 15
PortfolioPerformanceEndpoint    44                 15
ServicingExecutionRows          44                 15
```

This is particularly useful because it demonstrates both grains simultaneously: the A1b application/scenario facts preserve **750 rows independently in each scenario**, while the account/endpoint facts preserve the governed **44 BASELINE + 15 RECESSION_ENERGY = 59 account paths**. There is no visible scenario collapse or cross-scenario multiplication.

```text
E08 scenario populations                  2/2 PASS
Application scenario isolation            750 / 750 PASS
Distinct application isolation            750 / 750 PASS
Distinct merchant isolation               750 / 750 PASS
Booking/final-decision isolation           750 / 750 PASS
Account-path isolation                      44 / 15 PASS
Monitoring endpoint isolation               44 / 15 PASS
Portfolio endpoint isolation                44 / 15 PASS
Servicing execution isolation               44 / 15 PASS
Total account paths                              59 PASS
```

We can now move to the major remaining local-engine control: **AUD-ASOF-003B**.

## E09 — first establish the endpoint-fact physical dates

Before testing measures at 11/21, 11/22 and 11/23, I want one short diagnostic from the live model. This prevents us from assuming which date column governs each endpoint fact.

Run:

```dax
EVALUATE
UNION(
    ROW(
        "Object", "FactAccountCertification",
        "Rows", COUNTROWS('FactAccountCertification'),
        "MinDate", MIN('FactAccountCertification'[certification_date]),
        "MaxDate", MAX('FactAccountCertification'[certification_date])
    ),
    ROW(
        "Object", "FactMonitoringEndpoint",
        "Rows", COUNTROWS('FactMonitoringEndpoint'),
        "MinDate", MIN('FactMonitoringEndpoint'[latest_monitoring_date]),
        "MaxDate", MAX('FactMonitoringEndpoint'[latest_monitoring_date])
    ),
    ROW(
        "Object", "FactPortfolioPerformanceEndpoint",
        "Rows", COUNTROWS('FactPortfolioPerformanceEndpoint'),
        "MinDate", MIN('FactPortfolioPerformanceEndpoint'[portfolio_snapshot_date]),
        "MaxDate", MAX('FactPortfolioPerformanceEndpoint'[portfolio_snapshot_date])
    ),
    ROW(
        "Object", "FactServicingExecution",
        "Rows", COUNTROWS('FactServicingExecution'),
        "MinDate", MIN('FactServicingExecution'[created_at]),
        "MaxDate", MAX('FactServicingExecution'[created_at])
    ),
    ROW(
        "Object", "FactServicingQueueEndpoint",
        "Rows", COUNTROWS('FactServicingQueueEndpoint'),
        "MinDate", MIN('FactServicingQueueEndpoint'[created_at]),
        "MaxDate", MAX('FactServicingQueueEndpoint'[created_at])
    )
)
ORDER BY [Object]
```

If DAX Studio reports that one of those date-column names does not exist, **do not substitute a guessed column**. Send me the exact error and I will derive the correct column from the live metadata.

Save a successful result as:

```text
E09_ENDPOINT_FACT_DATE_DIAGNOSTIC.csv
E09_ENDPOINT_FACT_DATE_DIAGNOSTIC.png
```

### Why this intermediate step matters

We already know the controller spine physically contains:

```text
2026-07-23   source-run as-of
2026-11-22   evidence endpoint
```

But `AUD-ASOF-003B` is stronger than proving that `DimDate` contains those dates. We need to prove the **business facts and centralized measures do not expose endpoint evidence before 11/22, do expose it at 11/22, and correctly handle 11/23 as outside the evidence boundary**.

The final E09 test will therefore evaluate the same controlled measures under three explicit `DimAsOfDate[AsOfDate]` contexts:

```text
2026-11-21   PRE_ENDPOINT
2026-11-22   ENDPOINT
2026-11-23   POST_ENDPOINT
```

and will include at minimum:

```text
Selected As Of Date
As Of Evidence Status
Endpoint Evidence Available
Portfolio Evidence Max Date

Active Account Count As Of
Current Exposure As Of
Paid Off Accounts As Of
Cumulative Actual Remittance As Of
Cumulative Expected Remittance As Of
Remaining Receivable As Of
Open Servicing Queue
Unresolved Payment Exceptions As Of
```

That will give Audit direct live-engine evidence of the no-back-casting and post-evidence boundary behavior rather than an inference from source dates.

Run the **E09 endpoint-fact date diagnostic** first and send me the result.
<!-- END_SOURCE_MESSAGE -->


<a id="m-316ca2bb-c45b-4d9a-8964-e0acfd77d399"></a>
## Andrew / user · C091-M00179

C091-M00179 · 2026-08-20T13:04:46.894000-04:00 · active path

Preceding visible parent: [C091-M00178](part-13.md#m-ce59b2ea-045c-45c5-a550-499f90132792)

<!-- BEGIN_SOURCE_MESSAGE -->
error in that query: Query (18, 24) Column 'portfolio_snapshot_date' in table 'FactPortfolioPerformanceEndpoint' cannot be found or may not be used in this expression.
<!-- END_SOURCE_MESSAGE -->


<a id="m-9969b205-f94c-4b51-8fbc-71cc9e813a4d"></a>
## Assistant · C091-M00180

C091-M00180 · 2026-08-20T13:04:47.694498-04:00 · active path

Preceding visible parent: [C091-M00179](part-13.md#m-316ca2bb-c45b-4d9a-8964-e0acfd77d399)

<!-- BEGIN_SOURCE_MESSAGE -->
Good stop. **Do not substitute another date column yet.** This is exactly why we put the diagnostic ahead of `AUD-ASOF-003B`.

The failure is confined to the diagnostic query:

```text
FactPortfolioPerformanceEndpoint[portfolio_snapshot_date]
→ column does not exist
```

No model change is indicated.

### 1. Preserve the failed diagnostic

Save the screenshot/error, then record:

```powershell
$work = "C:\MSBF\MSBF_PBI_A1B_WORKING_R1_20260819"
$return = Join-Path $work "evidence\local_engine_return"

[pscustomobject]@{
    event = "E09_ENDPOINT_FACT_DATE_DIAGNOSTIC_SCHEMA_OBSERVATION"
    captured_local = (Get-Date).ToString("o")
    captured_utc = (Get-Date).ToUniversalTime().ToString("o")

    query = "E09_ENDPOINT_FACT_DATE_DIAGNOSTIC"
    result = "STOPPED_ON_SCHEMA_MISMATCH"

    object = "FactPortfolioPerformanceEndpoint"
    attempted_column = "portfolio_snapshot_date"

    error =
        "Column 'portfolio_snapshot_date' in table 'FactPortfolioPerformanceEndpoint' cannot be found or may not be used in this expression."

    model_modified = $false
    measure_modified = $false
    relationship_modified = $false

    disposition =
        "DERIVE_ENDPOINT_DATE_COLUMNS_FROM_LIVE_ENGINE_METADATA_BEFORE_RETRY"
} |
    ConvertTo-Json -Depth 6 |
    Set-Content `
        -LiteralPath "$return\E09_ENDPOINT_DATE_DIAGNOSTIC_SCHEMA_OBSERVATION.json" `
        -Encoding utf8
```

### 2. Ask the live engine for the actual columns

Run this in DAX Studio:

```dax
EVALUATE
SELECTCOLUMNS(
    FILTER(
        INFO.VIEW.COLUMNS(),
        [Table] IN {
            "FactAccountCertification",
            "FactMonitoringEndpoint",
            "FactPortfolioKPIEndpoint",
            "FactPortfolioPerformanceEndpoint",
            "FactServicingExecution",
            "FactServicingQueueEndpoint"
        }
    ),
    "Table", [Table],
    "Column", [Name],
    "DataType", [DataType],
    "SourceColumn", [SourceColumn],
    "IsHidden", [IsHidden]
)
ORDER BY
    [Table],
    [Column]
```

This deliberately includes **six endpoint-governed facts**, including `FactPortfolioKPIEndpoint`; my previous diagnostic omitted that table, so we should correct the evidence population now rather than carry that omission forward.

Save:

```text
E09_ENDPOINT_FACT_COLUMN_METADATA.csv
E09_ENDPOINT_FACT_COLUMN_METADATA.png
```

### 3. Do not run the three-date test yet

Once you send me that CSV/result, I will construct the corrected diagnostic using the **actual live-engine date fields** for all six endpoint-governed facts.

Then we can build `AUD-ASOF-003B` against the authoritative physical schemas for:

```text
2026-11-21  PRE_ENDPOINT
2026-11-22  ENDPOINT
2026-11-23  POST_ENDPOINT
```

This was a useful failure: it prevented us from creating evidence around an assumed field name. The A1b model itself remains untouched.
<!-- END_SOURCE_MESSAGE -->


<a id="m-05012183-eafe-433b-bf6e-595dc244cac1"></a>
## Andrew / user · C091-M00181

C091-M00181 · 2026-08-20T13:08:37.540000-04:00 · active path

Preceding visible parent: [C091-M00180](part-13.md#m-9969b205-f94c-4b51-8fbc-71cc9e813a4d)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: E09_ENDPOINT_FACT_COLUMN_METADATA.png; E09_ENDPOINT_FACT_COLUMN_METADATA.csv

<!-- BEGIN_SOURCE_MESSAGE -->
E09_ENDPOINT_FACT_COLUMN_METADATA attached.
<!-- END_SOURCE_MESSAGE -->


<a id="m-dba41fea-59e4-4f35-9822-5afa7f7ea994"></a>
## Assistant · C091-M00182

C091-M00182 · 2026-08-20T13:08:46.024887-04:00 · active path

Preceding visible parent: [C091-M00181](part-13.md#m-05012183-eafe-433b-bf6e-595dc244cac1)

<!-- BEGIN_SOURCE_MESSAGE -->
Good. The live metadata resolves the schema ambiguity. I inspected all **238 column-metadata rows across the six endpoint-governed facts**.

The important finding is that these six objects **do not share one common business-date column**:

```text
FactAccountCertification
  certification_date          Date
  created_at                  DateTime

FactMonitoringEndpoint
  latest_monitoring_date      Date
  created_at                  DateTime

FactPortfolioKPIEndpoint
  created_at                  DateTime

FactPortfolioPerformanceEndpoint
  created_at                  DateTime

FactServicingExecution
  created_at                  DateTime

FactServicingQueueEndpoint
  created_at                  DateTime
```

So my attempted `portfolio_snapshot_date` was incorrect. More importantly, we should **not reinterpret `created_at` as an as-of/effective date merely because it is the only timestamp on four endpoint tables**. That would invent semantics the physical schema does not establish.

The better `AUD-ASOF-003B` test is therefore measure/controller based: exercise the centralized as-of logic at the three required dates and observe whether endpoint evidence is exposed or withheld. That is exactly the business behavior we need to validate.

## E09A — three-date centralized as-of behavior

Run this exact query:

```dax
EVALUATE
UNION(

    /* ---------------------------------------------------------
       PRE-ENDPOINT: 2026-11-21
       --------------------------------------------------------- */
    CALCULATETABLE(
        ROW(
            "TestDate", DATE(2026,11,21),
            "BoundaryClass", "PRE_ENDPOINT",

            "SelectedAsOfDate", [Selected As Of Date],
            "AsOfEvidenceStatus", [As Of Evidence Status],
            "EndpointEvidenceAvailable", [Endpoint Evidence Available],
            "PortfolioEvidenceMaxDate", [Portfolio Evidence Max Date],

            "ActiveAccountCountAsOf", [Active Account Count As Of],
            "CurrentExposureAsOf", [Current Exposure As Of],
            "PaidOffAccountsAsOf", [Paid Off Accounts As Of],

            "CumulativeActualRemittanceAsOf",
                [Cumulative Actual Remittance As Of],

            "CumulativeExpectedRemittanceAsOf",
                [Cumulative Expected Remittance As Of],

            "RemainingReceivableAsOf",
                [Remaining Receivable As Of],

            "OpenServicingQueue",
                [Open Servicing Queue],

            "UnresolvedPaymentExceptionsAsOf",
                [Unresolved Payment Exceptions As Of]
        ),
        TREATAS(
            { DATE(2026,11,21) },
            'DimAsOfDate'[AsOfDate]
        )
    ),

    /* ---------------------------------------------------------
       EVIDENCE ENDPOINT: 2026-11-22
       --------------------------------------------------------- */
    CALCULATETABLE(
        ROW(
            "TestDate", DATE(2026,11,22),
            "BoundaryClass", "EVIDENCE_ENDPOINT",

            "SelectedAsOfDate", [Selected As Of Date],
            "AsOfEvidenceStatus", [As Of Evidence Status],
            "EndpointEvidenceAvailable", [Endpoint Evidence Available],
            "PortfolioEvidenceMaxDate", [Portfolio Evidence Max Date],

            "ActiveAccountCountAsOf", [Active Account Count As Of],
            "CurrentExposureAsOf", [Current Exposure As Of],
            "PaidOffAccountsAsOf", [Paid Off Accounts As Of],

            "CumulativeActualRemittanceAsOf",
                [Cumulative Actual Remittance As Of],

            "CumulativeExpectedRemittanceAsOf",
                [Cumulative Expected Remittance As Of],

            "RemainingReceivableAsOf",
                [Remaining Receivable As Of],

            "OpenServicingQueue",
                [Open Servicing Queue],

            "UnresolvedPaymentExceptionsAsOf",
                [Unresolved Payment Exceptions As Of]
        ),
        TREATAS(
            { DATE(2026,11,22) },
            'DimAsOfDate'[AsOfDate]
        )
    ),

    /* ---------------------------------------------------------
       POST-EVIDENCE: 2026-11-23
       --------------------------------------------------------- */
    CALCULATETABLE(
        ROW(
            "TestDate", DATE(2026,11,23),
            "BoundaryClass", "POST_EVIDENCE",

            "SelectedAsOfDate", [Selected As Of Date],
            "AsOfEvidenceStatus", [As Of Evidence Status],
            "EndpointEvidenceAvailable", [Endpoint Evidence Available],
            "PortfolioEvidenceMaxDate", [Portfolio Evidence Max Date],

            "ActiveAccountCountAsOf", [Active Account Count As Of],
            "CurrentExposureAsOf", [Current Exposure As Of],
            "PaidOffAccountsAsOf", [Paid Off Accounts As Of],

            "CumulativeActualRemittanceAsOf",
                [Cumulative Actual Remittance As Of],

            "CumulativeExpectedRemittanceAsOf",
                [Cumulative Expected Remittance As Of],

            "RemainingReceivableAsOf",
                [Remaining Receivable As Of],

            "OpenServicingQueue",
                [Open Servicing Queue],

            "UnresolvedPaymentExceptionsAsOf",
                [Unresolved Payment Exceptions As Of]
        ),
        TREATAS(
            { DATE(2026,11,23) },
            'DimAsOfDate'[AsOfDate]
        )
    )
)
ORDER BY [TestDate]
```

Save:

```text
E09A_AUD_ASOF_003B_THREE_DATE_MEASURE_BEHAVIOR.csv
E09A_AUD_ASOF_003B_THREE_DATE_MEASURE_BEHAVIOR.png
```

### Do not assume the expected values yet

This is important. We know the intended control principle:

```text
11/21   PRE_ENDPOINT
11/22   EVIDENCE_ENDPOINT
11/23   POST_EVIDENCE
```

But we should let the **actual governed DAX definitions tell us their encoded behavior** before declaring exactly which measures must blank on each date.

For example, `As Of Evidence Status` may distinguish these dates with explicit status text rather than simply returning `BLANK()`. Likewise, some daily monitoring measures could legitimately exist on 11/21 even though endpoint-only facts must not be back-cast.

So for E09A, **do not interpret anything manually and do not change any measure**. Just preserve the three rows.

## Then we will perform E09B

Once I see E09A, I will reconcile the output against the actual 60 measure definitions we already captured and construct a narrower endpoint-only test covering the six governed endpoint objects:

```text
FactAccountCertification
FactMonitoringEndpoint
FactPortfolioKPIEndpoint
FactPortfolioPerformanceEndpoint
FactServicingExecution
FactServicingQueueEndpoint
```

That will let us distinguish rigorously between:

- ordinary historical/as-of monitoring evidence;
- endpoint-only evidence;
- the 11/22 evidence boundary;
- post-evidence HOLD behavior.

Run **E09A only** next and send me the three-row CSV/result.
<!-- END_SOURCE_MESSAGE -->


<a id="m-a4563561-4efe-4b56-a5e3-456ad572082f"></a>
## Andrew / user · C091-M00183

C091-M00183 · 2026-08-20T13:14:44.367000-04:00 · active path

Preceding visible parent: [C091-M00182](part-13.md#m-dba41fea-59e4-4f35-9822-5afa7f7ea994)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: E09A_AUD_ASOF_003B_THREE_DATE_MEASURE_BEHAVIOR.png; E09A_AUD_ASOF_003B_THREE_DATE_MEASURE_BEHAVIOR.csv

<!-- BEGIN_SOURCE_MESSAGE -->
E09A evidence attached.
<!-- END_SOURCE_MESSAGE -->


<a id="m-6ec56314-f214-4c4b-9639-b8c7bae617d6"></a>
## Assistant · C091-M00184

C091-M00184 · 2026-08-20T13:14:52.204021-04:00 · active path

Preceding visible parent: [C091-M00183](part-13.md#m-a4563561-4efe-4b56-a5e3-456ad572082f)

<!-- BEGIN_SOURCE_MESSAGE -->
E09A gives us a very important result. I inspected the three-row CSV directly.

The centralized as-of controller behaves correctly at the **post-evidence boundary**, but it also exposes a specific issue/question we need to resolve before calling `AUD-ASOF-003B` complete:

| Control | 11/21 PRE | 11/22 ENDPOINT | 11/23 POST |
|---|---:|---:|---:|
| Selected As Of Date | 11/21 | 11/22 | **BLANK** |
| As Of Evidence Status | VALID | VALID | **HOLD_OUTSIDE_EVIDENCE** |
| Endpoint Evidence Available | **0** | **0** | 0 |
| Portfolio Evidence Max Date | 11/22 | 11/22 | 11/22 |
| Active Accounts | 2 | 2 | 0 |
| Current Exposure | 1,287.02 | 979.73 | **BLANK** |
| Paid Off Accounts | 57 | 57 | 0 |
| Cumulative Actual | 800,551.70 | 800,858.99 | **BLANK** |
| Cumulative Expected | 801,838.72 | 801,838.72 | **BLANK** |
| Remaining Receivable | 1,287.02 | 979.73 | **BLANK** |
| Open Servicing Queue | 10 | 10 | **BLANK** |

### What has already passed

The **11/23 outside-evidence behavior is excellent**:

```text
Requested date                  2026-11-23
Selected As Of Date             BLANK
As Of Evidence Status           HOLD_OUTSIDE_EVIDENCE
Portfolio Evidence Max Date     2026-11-22

Exposure/remittance measures    BLANK
Open servicing queue            BLANK
```

That is direct live-engine evidence that the model does **not silently carry 11/22 evidence forward into 11/23**.

Likewise, 11/21 and 11/22 are distinguished correctly as valid dates, and the ordinary as-of measures evolve between them rather than simply repeating endpoint values:

```text
Current Exposure
11/21   1,287.02
11/22     979.73

Cumulative Actual
11/21   800,551.70
11/22   800,858.99
```

So ordinary historical/as-of behavior is functioning.

## One result requires investigation

`Endpoint Evidence Available` is:

```text
11/21 = 0
11/22 = 0
11/23 = 0
```

That is potentially significant.

If this measure is supposed to become `1` exactly on **2026-11-22**, then `AUD-ASOF-003B` has exposed a real defect. If instead the measure has a narrower semantic definition—for example, requiring a particular endpoint-fact/filter context—then the zero at 11/22 may be correct.

We should **not infer which interpretation applies**.

### E09A disposition

For now:

```text
Pre-endpoint ordinary as-of behavior        PASS
Evidence-endpoint ordinary as-of behavior   PASS
Post-evidence HOLD behavior                 PASS
No post-endpoint carry-forward              PASS

Endpoint Evidence Available:
  11/21                                      0
  11/22                                      0
  11/23                                      0
                                             INVESTIGATE

AUD-ASOF-003B                               NOT YET CLOSED
```

## E09B — inspect the actual endpoint-control definitions

Before executing anything else, run this metadata query:

```dax
EVALUATE
SELECTCOLUMNS(
    FILTER(
        INFO.VIEW.MEASURES(),
        [Name] IN {
            "Endpoint Evidence Available",
            "As Of Evidence Status",
            "Selected As Of Date",
            "Portfolio Evidence Max Date"
        }
    ),
    "Measure", [Name],
    "Expression", [Expression],
    "FormatString", [FormatString],
    "IsHidden", [IsHidden]
)
ORDER BY [Measure]
```

Save it as:

```text
E09B_ASOF_CONTROL_MEASURE_DEFINITIONS.csv
E09B_ASOF_CONTROL_MEASURE_DEFINITIONS.png
```

This is read-only metadata evidence. **Do not edit any measure.**

Once you send me that CSV, I can determine exactly what `Endpoint Evidence Available = 0` means according to the model's own authored logic. Then we'll construct the final endpoint-only physical test around that definition and the six endpoint-governed facts.

We are very close, but this is precisely the sort of result that should be resolved rather than waved through.
<!-- END_SOURCE_MESSAGE -->


<a id="m-4a59c559-4343-4237-87f6-eecaef98606e"></a>
## Andrew / user · C091-M00185

C091-M00185 · 2026-08-20T13:20:11.982000-04:00 · active path

Preceding visible parent: [C091-M00184](part-13.md#m-6ec56314-f214-4c4b-9639-b8c7bae617d6)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: E09B_ASOF_CONTROL_MEASURE_DEFINITIONS.csv; E09B_ASOF_CONTROL_MEASURE_DEFINITIONS.png

<!-- BEGIN_SOURCE_MESSAGE -->
E09B_ASOF_CONTROL_MEASURE_DEFINITIONS attached.
<!-- END_SOURCE_MESSAGE -->


<a id="m-77f66613-5d45-46be-a27d-574f39557529"></a>
## Assistant · C091-M00186

C091-M00186 · 2026-08-20T13:20:19.835623-04:00 · active path

Preceding visible parent: [C091-M00185](part-13.md#m-4a59c559-4343-4237-87f6-eecaef98606e)

<!-- BEGIN_SOURCE_MESSAGE -->
E09B explains the `Endpoint Evidence Available = 0` result precisely. I inspected the exported measure definitions.

The measure requires **five conditions simultaneously**:

```dax
[As Of Evidence Status] = "VALID"
&& [Selected As Of Date] = [Portfolio Evidence Max Date]
&& [G2 Contract Pass] = 1
&& [G3 Contract Pass] = 1
&& [Source Reconciliation Pass] = 1
```

At `2026-11-22`, E09A already established the first four conditions:

```text
As Of Evidence Status          VALID
Selected As Of Date            2026-11-22
Portfolio Evidence Max Date    2026-11-22
G2 Contract Pass               previously observed = 1
G3 Contract Pass               previously observed = 1
```

Therefore the remaining gating condition is **`[Source Reconciliation Pass]`**. In E05's unfiltered execution, that measure returned `0`. So `Endpoint Evidence Available = 0` is not an as-of/date-controller defect; it is the intended downstream consequence of the source-reconciliation gate currently evaluating false.

That distinction is important.

### Current `AUD-ASOF-003B` interpretation

The date-boundary behavior itself is behaving coherently:

```text
2026-11-21  VALID
2026-11-22  VALID
2026-11-23  HOLD_OUTSIDE_EVIDENCE
```

And `Portfolio Evidence Max Date` is explicitly derived from:

```dax
MAX('FactAccountDaily'[monitoring_date])
```

with date filters removed. That physically establishes `2026-11-22` as the evidence ceiling.

The endpoint availability flag is therefore **fail-closed** rather than incorrectly exposing endpoint evidence:

```text
Endpoint date reached                    YES
Date boundary valid                      YES
G2/G3 gates                              PASS
Source reconciliation gate               NOT PASS
Endpoint Evidence Available              0
```

We now need to determine *why* `Source Reconciliation Pass = 0` before deciding whether that is an expected governed HOLD or an A1b defect.

## E09C — inspect and execute the reconciliation gate

First retrieve the exact measure definition:

```dax
EVALUATE
SELECTCOLUMNS(
    FILTER(
        INFO.VIEW.MEASURES(),
        [Name] IN {
            "Source Reconciliation Pass",
            "Reconciliation Difference",
            "Primary Key Fail Count",
            "Orphan Fail Count",
            "Measure Recompute Fail Count",
            "G2 Contract Pass",
            "G3 Contract Pass"
        }
    ),
    "Measure", [Name],
    "Expression", [Expression],
    "IsHidden", [IsHidden]
)
ORDER BY [Measure]
```

Save:

```text
E09C_RECONCILIATION_GATE_MEASURE_DEFINITIONS.csv
E09C_RECONCILIATION_GATE_MEASURE_DEFINITIONS.png
```

Then, in a second query, execute those controls specifically at the endpoint:

```dax
EVALUATE
CALCULATETABLE(
    ROW(
        "TestDate", DATE(2026,11,22),
        "AsOfEvidenceStatus", [As Of Evidence Status],
        "SelectedAsOfDate", [Selected As Of Date],
        "PortfolioEvidenceMaxDate", [Portfolio Evidence Max Date],

        "G2ContractPass", [G2 Contract Pass],
        "G3ContractPass", [G3 Contract Pass],

        "SourceReconciliationPass", [Source Reconciliation Pass],
        "ReconciliationDifference", [Reconciliation Difference],
        "PrimaryKeyFailCount", [Primary Key Fail Count],
        "OrphanFailCount", [Orphan Fail Count],
        "MeasureRecomputeFailCount", [Measure Recompute Fail Count],

        "EndpointEvidenceAvailable", [Endpoint Evidence Available]
    ),
    TREATAS(
        { DATE(2026,11,22) },
        'DimAsOfDate'[AsOfDate]
    )
)
```

Save:

```text
E09C_ENDPOINT_RECONCILIATION_GATE_EXECUTION.csv
E09C_ENDPOINT_RECONCILIATION_GATE_EXECUTION.png
```

Do **not** change any measure if `SourceReconciliationPass` remains `0`.

### Why this is the right next test

We should not weaken `Endpoint Evidence Available` just to make it return `1`. Its current construction is actually a desirable fail-closed control: endpoint evidence cannot become claimable unless date validity, G2, G3, **and source reconciliation** all pass.

The remaining question is whether:

1. `Source Reconciliation Pass = 0` is an **expected HOLD because its required validation context is absent**, or
2. the live A1b model contains an actual source-reconciliation failure.

E09C will tell us which.

At this point I would classify the evidence as:

```text
AUD-ASOF-003B

Pre-endpoint date handling             PASS
Endpoint date recognition              PASS
Post-endpoint HOLD                     PASS
No post-evidence carry-forward         PASS
Evidence ceiling = 2026-11-22          PASS

Endpoint Evidence Available               0
Reason                                 SOURCE_RECONCILIATION_GATE_FALSE
Correct fail-closed behavior           PASS

Underlying reconciliation gate         INVESTIGATE
Overall AUD-ASOF-003B                   PENDING E09C
```

Run both E09C queries and send me the two CSVs/results.
<!-- END_SOURCE_MESSAGE -->


<a id="m-5a536923-8527-4bb1-800f-5893199531c7"></a>
## Andrew / user · C091-M00187

C091-M00187 · 2026-08-20T13:27:47.651000-04:00 · active path

Preceding visible parent: [C091-M00186](part-13.md#m-77f66613-5d45-46be-a27d-574f39557529)

**Editorial record note:** 2 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: E09C_ENDPOINT_RECONCILIATION_GATE_EXECUTION.csv; E09C_RECONCILIATION_GATE_MEASURE_DEFINITIONS.png; E09C_RECONCILIATION_GATE_MEASURE_DEFINITIONS.csv; E09C_ENDPOINT_RECONCILIATION_GATE_EXECUTION.png

<!-- BEGIN_SOURCE_MESSAGE -->
E09C evidence attached.
<!-- END_SOURCE_MESSAGE -->


<a id="m-64a17d56-d6b4-496c-92ef-dae4675fed70"></a>
## Assistant · C091-M00188

C091-M00188 · 2026-08-20T13:28:03.938004-04:00 · active path

Preceding visible parent: [C091-M00187](part-13.md#m-5a536923-8527-4bb1-800f-5893199531c7)

<!-- BEGIN_SOURCE_MESSAGE -->
E09C narrows the issue materially. I inspected both CSVs directly.

At the exact endpoint `2026-11-22`, the live engine returns:

```text
As Of Evidence Status          VALID
Selected As Of Date            2026-11-22
Portfolio Evidence Max Date    2026-11-22
G2 Contract Pass               1
G3 Contract Pass               1

Source Reconciliation Pass     0
Endpoint Evidence Available    0

Reconciliation Difference      BLANK
Primary Key Fail Count         BLANK
Orphan Fail Count              BLANK
Measure Recompute Fail Count   BLANK
```

The measure definition establishes exactly why. `Source Reconciliation Pass` is not based on those three specialized fail-count measures. It independently requires **every row** in both `FactSourceReconciliation` and `FactValidationResult` to have a PASS status:

```text
SourceControls > 0
ValidationControls > 0
SourceFailures = 0
ValidationFailures = 0
```

where:

```text
SourceFailures =
    FactSourceReconciliation[object_audit_status] <> "PASS"

ValidationFailures =
    FactValidationResult[status] <> "PASS"
```

So E09C has established that **at least one row in one of those two populations is not PASS**. We should not yet call that an A1b model defect, because it may be a deliberately retained HOLD/pending row in the governed evidence population.

The blank `Primary Key Fail Count`, `Orphan Fail Count`, and `Measure Recompute Fail Count` are actually useful: they give us no evidence that those specific categories are causing the gate to fail. We now need to identify the exact non-PASS population.

## E09D — identify the gate blocker exactly

Run this first. It gives us a compact status distribution for both controlling tables:

```dax
EVALUATE
UNION(
    SELECTCOLUMNS(
        SUMMARIZECOLUMNS(
            'FactSourceReconciliation'[object_audit_status],
            "RowCount", COUNTROWS('FactSourceReconciliation')
        ),
        "Population", "FactSourceReconciliation",
        "Status", COALESCE('FactSourceReconciliation'[object_audit_status], "<BLANK>"),
        "RowCount", [RowCount]
    ),

    SELECTCOLUMNS(
        SUMMARIZECOLUMNS(
            'FactValidationResult'[status],
            "RowCount", COUNTROWS('FactValidationResult')
        ),
        "Population", "FactValidationResult",
        "Status", COALESCE('FactValidationResult'[status], "<BLANK>"),
        "RowCount", [RowCount]
    )
)
ORDER BY
    [Population],
    [Status]
```

Save as:

```text
E09D_RECONCILIATION_GATE_STATUS_DISTRIBUTION.csv
E09D_RECONCILIATION_GATE_STATUS_DISTRIBUTION.png
```

Then run this second query to identify the actual source-reconciliation blockers:

```dax
EVALUATE
FILTER(
    SELECTCOLUMNS(
        'FactSourceReconciliation',
        "schema", 'FactSourceReconciliation'[schema],
        "object", 'FactSourceReconciliation'[object],
        "object_audit_status", 'FactSourceReconciliation'[object_audit_status],
        "loaded_rows", 'FactSourceReconciliation'[loaded_rows],
        "actual_rows", 'FactSourceReconciliation'[actual_rows]
    ),
    COALESCE([object_audit_status], "") <> "PASS"
)
ORDER BY
    [schema],
    [object]
```

Save as:

```text
E09D_SOURCE_RECONCILIATION_NONPASS.csv
E09D_SOURCE_RECONCILIATION_NONPASS.png
```

Finally run the validation-side blocker query:

```dax
EVALUATE
FILTER(
    SELECTCOLUMNS(
        'FactValidationResult',
        "control_id", 'FactValidationResult'[control_id],
        "validation_category", 'FactValidationResult'[validation_category],
        "source_schema", 'FactValidationResult'[source_schema],
        "source_object", 'FactValidationResult'[source_object],
        "status", 'FactValidationResult'[status],
        "residual_limitation", 'FactValidationResult'[residual_limitation]
    ),
    COALESCE([status], "") <> "PASS"
)
ORDER BY
    [validation_category],
    [control_id]
```

Save as:

```text
E09D_VALIDATION_NONPASS.csv
E09D_VALIDATION_NONPASS.png
```

Do **not** alter any rows, measures, queries, or reconciliation logic regardless of what those queries return.

### Current disposition

At this point the evidence supports a fairly strong conclusion already:

```text
AUD-ASOF-003B

11/21 valid historical as-of behavior        PASS
11/22 endpoint recognized                    PASS
11/23 outside-evidence HOLD                  PASS
No post-endpoint carry-forward               PASS
Evidence ceiling = 2026-11-22                PASS
G2 contract gate                             PASS
G3 contract gate                             PASS

Endpoint evidence publication gate           CLOSED / FAIL-CLOSED
Endpoint Evidence Available                  0
Immediate cause                              Source Reconciliation Pass = 0

Underlying non-PASS population               IDENTIFICATION PENDING
AUD-ASOF-003B final disposition              PENDING E09D
```

This is not a reason to weaken the gate. If the non-PASS rows turn out to be intentional governance HOLDs, then the model is doing exactly what it should: **recognizing the endpoint while refusing to declare endpoint evidence available until every required reconciliation/validation control is PASS**. If they are unexpected failures, we preserve them for Audit instead.

Run the three E09D queries and send me the results.
<!-- END_SOURCE_MESSAGE -->


<a id="m-c5622b89-5d8b-4cb9-b479-58e431837889"></a>
## Andrew / user · C091-M00189

C091-M00189 · 2026-08-20T13:36:27.628000-04:00 · active path

Preceding visible parent: [C091-M00188](part-13.md#m-64a17d56-d6b4-496c-92ef-dae4675fed70)

**Editorial record note:** 3 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: E09D_SOURCE_RECONCILIATION_NONPASS.png; E09D_SOURCE_RECONCILIATION_NONPASS.csv; E09D_RECONCILIATION_GATE_STATUS_DISTRIBUTION.png; E09D_RECONCILIATION_GATE_STATUS_DISTRIBUTION.csv; E09D_VALIDATION_NONPASS.png; E09D_VALIDATION_NONPASS.csv

<!-- BEGIN_SOURCE_MESSAGE -->
E09D evidence attached.
<!-- END_SOURCE_MESSAGE -->


<a id="m-780bbb4e-23c8-45c5-85da-e768271c9bd1"></a>
## Assistant · C091-M00190

C091-M00190 · 2026-08-20T13:36:38.702474-04:00 · active path

Preceding visible parent: [C091-M00189](part-13.md#m-c5622b89-5d8b-4cb9-b479-58e431837889)

<!-- BEGIN_SOURCE_MESSAGE -->
E09D identifies the blocker conclusively, and it is **not a substantive source-reconciliation failure**. It is an exact-status predicate mismatch between the A1b DAX gate and the inherited A1a reconciliation evidence.

The physical results are:

```text
FactSourceReconciliation
  rows:    214
  status:  PASS_A1A_R3_STATIC
  rows with literal "PASS": 0

FactValidationResult
  rows:    533
  status:  PASS
  non-PASS rows: 0
```

The second E09D export confirms why all 214 source-reconciliation rows were returned by the `<> "PASS"` query: every one carries `object_audit_status = PASS_A1A_R3_STATIC`. The validation-side non-PASS export is empty.

### What this means

`[Source Reconciliation Pass]` currently implements an **exact literal `PASS` test**. But its entire 214-row source population uses the more specific inherited status `PASS_A1A_R3_STATIC`.

Therefore:

```text
Physical source reconciliation population       214
PASS_A1A_R3_STATIC                              214/214
Other source statuses                             0

Physical validation population                   533
PASS                                             533/533
Other validation statuses                         0

Substantive failed reconciliation rows             0
Substantive failed validation rows                 0

DAX Source Reconciliation Pass                     0
Cause                       STATUS-VOCABULARY MISMATCH
```

This also explains the entire chain:

```text
PASS_A1A_R3_STATIC <> "PASS"
        ↓
Source Reconciliation Pass = 0
        ↓
Endpoint Evidence Available = 0
```

So I would **not** classify `AUD-ASOF-003B` as failing because the underlying evidence is bad. But neither should we self-correct the measure now: the authorized A1b catalog gave us an exact 60-measure semantic construction, and changing one of those measure definitions would be a semantic hotfix requiring explicit bounded authority.

## Preserve this as a discovered A1b runtime finding

Before doing anything else, record it:

```powershell
$work = "C:\MSBF\MSBF_PBI_A1B_WORKING_R1_20260819"
$return = Join-Path $work "evidence\local_engine_return"

[pscustomobject]@{
    event = "A1B_SOURCE_RECONCILIATION_STATUS_VOCABULARY_FINDING"
    captured_local = (Get-Date).ToString("o")
    captured_utc = (Get-Date).ToUniversalTime().ToString("o")

    discovered_during = "AUD-ASOF-003B"

    fact_source_reconciliation_rows = 214
    fact_source_reconciliation_status = "PASS_A1A_R3_STATIC"
    fact_source_reconciliation_status_count = 214
    literal_pass_source_rows = 0

    fact_validation_result_rows = 533
    fact_validation_result_status = "PASS"
    fact_validation_result_status_count = 533
    validation_nonpass_rows = 0

    substantive_source_failure_observed = $false
    substantive_validation_failure_observed = $false

    dax_source_reconciliation_pass = 0
    dax_endpoint_evidence_available = 0

    root_cause =
        "SOURCE_RECONCILIATION_PASS_MEASURE_REQUIRES_LITERAL_PASS_WHILE_ALL_214_SOURCE_ROWS_USE_PASS_A1A_R3_STATIC"

    classification =
        "A1B_RUNTIME_STATUS_VOCABULARY_MISMATCH"

    model_modified = $false
    measure_modified = $false

    remediation_authorized = $false

    disposition =
        "PRESERVE_FAIL_CLOSED_STATE_AND_REFER_BOUNDED_SEMANTIC_REMEDIATION_TO_INDEPENDENT_AUDIT"
} |
    ConvertTo-Json -Depth 8 |
    Set-Content `
        -LiteralPath "$return\E09D_SOURCE_RECONCILIATION_STATUS_VOCABULARY_FINDING.json" `
        -Encoding utf8
```

## We should **not patch it yet**

This is materially different from HF01. HF01 corrected malformed M path syntax necessary to execute the already-authorized logic. Here, changing `[Source Reconciliation Pass]` from something equivalent to:

```dax
[object_audit_status] <> "PASS"
```

to accepting `PASS_A1A_R3_STATIC` would change the semantic acceptance predicate of a governed measure.

It may be the correct remediation—and the evidence strongly suggests that it is—but Independent Audit should decide whether:

1. `PASS_A1A_R3_STATIC` is an authorized success state for this A1b gate;
2. the source carrier should instead have normalized that status to `PASS`; or
3. some other contract was intended.

We should not silently choose among those.

### `AUD-ASOF-003B` can now be stated precisely

The as-of control itself has produced useful positive evidence:

```text
2026-11-21
  Status                         VALID
  Endpoint availability         0
  Historical as-of values       present

2026-11-22
  Status                         VALID
  Selected date                 2026-11-22
  Evidence ceiling              2026-11-22
  G2                            PASS
  G3                            PASS
  Endpoint availability         0
  blocker                       status-vocabulary mismatch

2026-11-23
  Status                         HOLD_OUTSIDE_EVIDENCE
  Selected date                 BLANK
  Exposure/remittance outputs   BLANK
  Endpoint availability         0
```

Thus the model **does pass the temporal boundary behavior**: historical calculation before the endpoint, recognition of the endpoint itself, and fail-closed behavior beyond it. What cannot yet pass is the endpoint-availability grant because of the newly discovered reconciliation-status mismatch.

I would therefore carry:

```text
AUD-ASOF-003B
  temporal boundary behavior          PASS
  pre-endpoint behavior               PASS
  endpoint recognition                PASS
  post-endpoint HOLD                  PASS
  no post-endpoint carry-forward      PASS
  endpoint grant                      BLOCKED
  blocker                             A1B status-vocabulary mismatch
  remediation                         NOT SELF-AUTHORIZED
  final IA disposition                PENDING
```

At this point I recommend **stopping further business-semantic testing and preserving this exact live state**. We have found a real bounded A1b semantic defect/contract mismatch, and continuing downstream could produce evidence whose interpretation depends on a gate we already know is false.

The appropriate next step is to package the evidence for Independent Audit with a narrowly framed request: **ratify the PBI-F-004 equivalent-evidence exception and determine disposition/remediation authority for the `PASS_A1A_R3_STATIC` versus literal `PASS` mismatch discovered under `AUD-ASOF-003B`.** No A1b measure should be edited before that decision.
<!-- END_SOURCE_MESSAGE -->


<a id="m-38551fc8-2287-4990-b589-6c1915578f51"></a>
## Andrew / user · C091-M00191

C091-M00191 · 2026-08-20T13:44:45.746000-04:00 · active path

Preceding visible parent: [C091-M00190](part-13.md#m-780bbb4e-23c8-45c5-85da-e768271c9bd1)

<!-- BEGIN_SOURCE_MESSAGE -->
Proceed to package the evidence for Independent Audit (including instructions for how to zip the live evidence we've been storing) with a narrowly framed request: **ratify the PBI-F-004 equivalent-evidence exception and determine disposition/remediation authority for the** **`PASS_A1A_R3_STATIC`** **versus literal** **`PASS`** **mismatch discovered under** **`AUD-ASOF-003B`****.** No A1b measure should be edited before that decision.  When creating the audit prompt, know that I will be providing file MSBF - Power BI Executive Portfolio Intelligence - ChatGPT\_Interactions\_49\_Thru\_## where ## is currently 87, but will likely be 87+ after a few more interactions before we finalize this for audit.
<!-- END_SOURCE_MESSAGE -->
