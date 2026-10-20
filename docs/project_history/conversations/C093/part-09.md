# MSBF - Campaign Scale 750 - 2,500 - 25,000

Part 09 · [Conversation index](README.md) · [History home](../../README.md)

> Historical dialogue: commands and approvals below describe past events. They are not current execution or publication instructions. Attachment references do not establish recovered bytes.

[Previous part](part-08.md)
[Next part](part-10.md)

<a id="m-5de37677-0405-4447-8f64-70249fbf9606"></a>
## Assistant · C093-M00135

C093-M00135 · 2026-08-21T09:16:48.820221-04:00 · active path

Preceding visible parent: [C093-M00134](part-08.md#m-95b34d97-17b3-4749-8fa7-7be1efdd0cf8)

<!-- BEGIN_SOURCE_MESSAGE -->
## CR-WP5 R5 Correction R2 complete — native rerun pending

The bounded Correction R2 source package is complete. I made only the two requested root corrections plus the identity propagation mechanically required by the changed final bytes.

The trust-handoff module now has one central lexical JSON parser using `ConvertFrom-Json -DateKind String`. `Assert-MSBFDetachedRsaSignature` returns its signed payload through that parser, and the downstream trust module no longer has direct `Get-Content ... | ConvertFrom-Json` paths that could silently coerce ISO timestamps. The helper also fails closed if the PowerShell host does not expose the required `DateKind` capability rather than falling back to date coercion.

The native harness now additionally records `R5_NATIVE_TRUST_RECEIPT_ROUNDTRIP_RESULTS.csv`, proving for production-path cases:

```text
pre-write receipt core SHA-256
=
persisted receipt_core_sha256
=
post-read recomputed receipt core SHA-256

issued_at_utc       -> System.String + UTF-8 byte-identical
not_before_utc      -> System.String + UTF-8 byte-identical
expires_at_utc      -> System.String + UTF-8 byte-identical
```

The only other test-behavior correction is `R5-NAT-041`: its expectation now matches the existing governed rejection exactly:

```text
Exactly one canonical current adapter-binding row is required.
```

The canonical-binding guard itself was not weakened or changed. `R5-NAT-012` through `R5-NAT-040`, the 44-row test plan, checkpoint/report contracts, splitter, empty-result behavior, sealing sequence, quarantine logic, and fake-engine fixtures remain unchanged.

Because the trust-module identity changed, its embedded identity pins in the production orchestrator and driver necessarily changed as well. That mechanically required rebinding all 230 definitions, all 230 canonical binding rows, and the checkpoint/report catalogs; those are identity propagation changes, not additional behavioral remediation.

### Final Correction R2 identities

```text
Source carrier
MSBF_CR_WP5_R5_CORRECTION_R2_STATIC_REMEDIATION_20260821.zip

SHA-256
8b92cd282d9aedb2006936e7d11229d75baf49c8705ef119b416cbf02702f986

Bytes
119,649,265

ZIP entries
1,196

Manifest rows
1,192

Manifest SHA-256
16383f20ef39ba6f00a9adf060e77a678422c2722db205719e0647198dd0e9e4

Payload-tree SHA-256
565db599a911621a5270653963299187568528fa8f55a9f6db8b165d0b0b7246

Complete carrier-tree SHA-256
3c8e0ce46d1aecf145d9586a381b286f14cbd521ed002dc1c065195eb51a4600

Trust-handoff module SHA-256
a3d15e278928aa7c60c899380c60ec166dc13834f82c9917047f7eb5edeee8fd

Production driver SHA-256
980c24cbb50f71875e65f9943f8238965b11224e75c89f9b5c83f3d8ddb75e49

Production orchestrator SHA-256
5bdce4610796c56d3a32fc274bab39ec0ac25b3b693f781b63e3c497cc5bf5a5

Canonical binding catalog SHA-256
acd8de30e5f941b0027d38923cce734f4c1341b49cd726ea54a1c14b139f7788

Checkpoint catalog SHA-256
c538f4935a6a928467983fb6c5607c6df0e5c7721ca69e2ddbb4bfc55a3f22de

Report catalog SHA-256
f28082758d9a6f9d35be7e8c02c36812ca55ec1bf0a8f4add78f29aac0c0deaf

Native harness SHA-256
596c5448f31806c08d0580146f7b6fca207fe410d16781c4fc8597708aa0bbb5

Protected-manifest SHA-256
b438cca673bb7ec94106807d3f20315081bdeb6365ea1173c59d5e734ebf5496

Protected-tree SHA-256
4c6b6acd25fd99559018e8ddf270c689d0ea2407c087c0309f6a97b44a5f6b20
```

Static validation is **70/70 PASS**, the standalone validator is **PASS**, and the native test plan remains **44 controls / 8 AST files**. No PostgreSQL, real `psql`, database action, checkpoint/report database execution, recovery, or replay occurred. That remains inside the audit-authorized R5 static-only boundary. [export reference: filecite | turn23file0 | L299-L330]

| Deliverable | File |
|---|---|
| **Correction R2 source carrier** | Download ZIP (historical reference: `sandbox:[session]/MSBF_CR_WP5_R5_CORRECTION_R2_STATIC_REMEDIATION_20260821.zip`; referenced bytes not established here) |
| Source SHA-256 sidecar | Download (historical reference: `sandbox:[session]/MSBF_CR_WP5_R5_CORRECTION_R2_STATIC_REMEDIATION_20260821.zip.sha256`; referenced bytes not established here) |
| External validation | Read (historical reference: `sandbox:[session]/MSBF_CR_WP5_R5_CORRECTION_R2_STATIC_REMEDIATION_20260821_VALIDATION_REPORT.md`; referenced bytes not established here) |
| Machine validation | Download (historical reference: `sandbox:[session]/MSBF_CR_WP5_R5_CORRECTION_R2_STATIC_REMEDIATION_20260821_VALIDATION_REPORT.json`; referenced bytes not established here) |
| Standalone validation | Download (historical reference: `sandbox:[session]/MSBF_CR_WP5_R5_CORRECTION_R2_STATIC_REMEDIATION_20260821_STANDALONE_VALIDATION.json`; referenced bytes not established here) |
| Correction R2 report | Read (historical reference: `sandbox:[session]/_crwp5_r5_correction_r2_build/20_R5_CORRECTION_R2/CR_WP5_R5_CORRECTION_R2_REPORT.md`; referenced bytes not established here) |
| R2 non-regression controls | Download (historical reference: `sandbox:[session]/_crwp5_r5_correction_r2_build/20_R5_CORRECTION_R2/CORRECTION_R2_NONREGRESSION_CONTROLS.csv`; referenced bytes not established here) |
| Exact R1→R2 diff | Download (historical reference: `sandbox:[session]/_crwp5_r5_correction_r2_build/20_R5_CORRECTION_R2/CORRECTION_R1_TO_R2_SOURCE_DIFF.csv`; referenced bytes not established here) |
| Updated external-authority request | Download ZIP (historical reference: `sandbox:[session]/MSBF_CR_WP5_R5_CORRECTION_R2_EXTERNAL_AUTHORITY_DECISION_REQUEST_20260821.zip`; referenced bytes not established here) |
| Authority-request sidecar | Download (historical reference: `sandbox:[session]/MSBF_CR_WP5_R5_CORRECTION_R2_EXTERNAL_AUTHORITY_DECISION_REQUEST_20260821.zip.sha256`; referenced bytes not established here) |
| Authority-request validation | Read (historical reference: `sandbox:[session]/MSBF_CR_WP5_R5_CORRECTION_R2_EXTERNAL_AUTHORITY_DECISION_REQUEST_20260821_VALIDATION_REPORT.md`; referenced bytes not established here) |
| **Fresh Correction R2 native runner** | Download (historical reference: `sandbox:[session]/Run-CRWP5R5CorrectionR2NativeEvidence.ps1`; referenced bytes not established here) |
| Runner sidecar | Download (historical reference: `sandbox:[session]/Run-CRWP5R5CorrectionR2NativeEvidence.ps1.sha256`; referenced bytes not established here) |
| Native-run instructions | Read (historical reference: `sandbox:[session]/CR_WP5_R5_CORRECTION_R2_NATIVE_RUN_INSTRUCTIONS.md`; referenced bytes not established here) |

The external authority request remains explicitly pending and non-self-approved. Its new SHA-256 is:

```text
b953dcdcf5c07a5477cef2f32b9c7cba0d8782e740684834017dc438221b48d6
```

The fresh runner is bound to the exact R2 carrier above:

```text
Run-CRWP5R5CorrectionR2NativeEvidence.ps1

SHA-256
f7f57a869f2f85199f97d172a13a58493ace00d041d0f6ee4014e7a41d168ff8
```

PowerShell is not available in this artifact runtime, so I could not perform the actual 44-control rerun here. Use your PowerShell 7.6.5/Core host from a clean folder containing the R2 carrier and runner:

```powershell
$PSVersionTable.PSVersion
$PSVersionTable.PSEdition

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

& .\Run-CRWP5R5CorrectionR2NativeEvidence.ps1 `
    -BasePath (Get-Location).Path
```

The fresh evidence names are:

```text
CR_WP5_R5_CORRECTION_R2_NATIVE_EVIDENCE.zip
CR_WP5_R5_CORRECTION_R2_NATIVE_EVIDENCE.zip.sha256
```

The target result is still **8/8 AST and 44/44 native PASS**, now with the additional receipt round-trip evidence physically demonstrating the cryptographic lexical invariant.
<!-- END_SOURCE_MESSAGE -->


<a id="m-5735ba57-0ff5-4d74-90dc-b53d2cf56ffc"></a>
## Andrew / user · C093-M00136

C093-M00136 · 2026-08-21T09:34:01.209000-04:00 · active path

Preceding visible parent: [C093-M00135](part-09.md#m-5de37677-0405-4447-8f64-70249fbf9606)

**Editorial record note:** Attachment references: CR_WP5_R5_CORRECTION_R2_NATIVE_EVIDENCE.zip; CR_WP5_R5_CORRECTION_R2_NATIVE_EVIDENCE.zip.sha256

<!-- BEGIN_SOURCE_MESSAGE -->
PS D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000> $PSVersionTable.PSVersion
>> $PSVersionTable.PSEdition
>>
>> Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
>>
>> & .\Run-CRWP5R5CorrectionR2NativeEvidence.ps1 `
>>     -BasePath (Get-Location).Path

Major  Minor  Patch  PreReleaseLabel BuildLabel
-----  -----  -----  --------------- ----------
7      6      5
Core
{
  "schema_version": "MSBF_CR_WP5_R5_NATIVE_OFFLINE_TEST_SUMMARY_V1",
  "carrier_sha256": "8b92cd282d9aedb2006936e7d11229d75baf49c8705ef119b416cbf02702f986",
  "package_manifest_sha256": "16383f20ef39ba6f00a9adf060e77a678422c2722db205719e0647198dd0e9e4",
  "package_payload_tree_sha256": "565db599a911621a5270653963299187568528fa8f55a9f6db8b165d0b0b7246",
  "complete_extracted_tree_sha256": "3c8e0ce46d1aecf145d9586a381b286f14cbd521ed002dc1c065195eb51a4600",
  "protected_tree_manifest_sha256": "b438cca673bb7ec94106807d3f20315081bdeb6365ea1173c59d5e734ebf5496",
  "protected_tree_sha256": "4c6b6acd25fd99559018e8ddf270c689d0ea2407c087c0309f6a97b44a5f6b20",
  "ast_files": 8,
  "ast_pass": 8,
  "tests": 44,
  "pass": 44,
  "fail": 0,
  "overall_status": "PASS",
  "production_chain_tested": true,
  "exact_checkpoint_tested": true,
  "multi_result_report_tested": true,
  "empty_result_header_tested": true,
  "authenticated_trust_handoff_tested": true,
  "signed_receipt_path_binding_tested": true,
  "protected_runtime_authority_pin_source_tested": true,
  "signed_orchestrator_boundary_tested": true,
  "single_use_trust_tested": true,
  "final_state_seal_tested": true,
  "fake_psql_process_invoked": true,
  "real_psql_process_invoked": false,
  "postgresql_connection_attempted": false,
  "database_action_performed": false,
  "checkpoint_report_executed_against_database": false,
  "recovery_invoked": false,
  "campaign_replay_invoked": false,
  "tested_at_utc": "2026-08-21T13:29:20.1018233+00:00"
}
{
  "schema_version": "MSBF_CR_WP5_R5_CORRECTION_R2_NATIVE_OPERATOR_RESULT_V1",
  "status": "PASS",
  "powershell_version": "7.6.5",
  "source_carrier_sha256": "8b92cd282d9aedb2006936e7d11229d75baf49c8705ef119b416cbf02702f986",
  "evidence_zip": "D:\\MSBF_ARCHIVE\\MSBF - Campaign Scale 750 - 2,500 - 25,000\\CR_WP5_R5_CORRECTION_R2_NATIVE_EVIDENCE.zip",
  "evidence_zip_sha256": "17cfac10e536be75698c3ba560cb82605f55d6b45065130ee1ab4f9ecec49a45",
  "ast_pass": 8,
  "ast_files": 8,
  "tests_pass": 44,
  "tests": 44,
  "production_chain_tested": true,
  "exact_checkpoint_tested": true,
  "multi_result_report_tested": true,
  "empty_result_header_tested": true,
  "authenticated_trust_handoff_tested": true,
  "signed_receipt_path_binding_tested": true,
  "protected_runtime_authority_pin_source_tested": true,
  "signed_orchestrator_boundary_tested": true,
  "single_use_trust_tested": true,
  "final_state_seal_tested": true,
  "fake_psql_process_invoked": true,
  "real_psql_process_invoked": false,
  "postgresql_connection_attempted": false,
  "completed_at_utc": "2026-08-21T13:29:22.7265603+00:00"
}
<!-- END_SOURCE_MESSAGE -->


<a id="m-0a17ea5f-5334-46cd-a1ac-66be7526db41"></a>
## Assistant · C093-M00137

C093-M00137 · 2026-08-21T09:34:05.553703-04:00 · active path

Preceding visible parent: [C093-M00136](part-09.md#m-5735ba57-0ff5-4d74-90dc-b53d2cf56ffc)

<!-- BEGIN_SOURCE_MESSAGE -->
The Correction R2 native result is clean: **8/8 AST and 44/44 native controls PASS**, with the exact checkpoint path, seven-result report/empty-header behavior, authenticated trust handoff, signed-receipt path binding, protected authority pin, signed orchestrator boundary, single-use trust, and final-state-complete sealing all exercised. I’m ingesting the uploaded native carrier now, independently reconciling it to the exact R2 source/tree identities, and preparing the final `ER-CAM-004` through `ER-CAM-008` audit-resubmission wrapper while keeping the external signer/trust decision explicitly pending and non-self-approved.
<!-- END_SOURCE_MESSAGE -->


<a id="m-6f671370-cf87-400a-939f-da55db4413b6"></a>
## Assistant · C093-M00138

C093-M00138 · 2026-08-21T09:38:47.643980-04:00 · active path

Preceding visible parent: [C093-M00137](part-09.md#m-0a17ea5f-5334-46cd-a1ac-66be7526db41)

<!-- BEGIN_SOURCE_MESSAGE -->
## CR-WP5 R5 Correction R2 — Final Audit Resubmission Complete

The uploaded native evidence has been ingested and independently reconciled to the exact Correction R2 source bytes. The result is clean:

```text
PowerShell                         7.6.5 / Core
AST                                8 / 8 PASS
Native controls                   44 / 44 PASS
Overall                            PASS

Exact checkpoint path              PASS
Multi-result report path           PASS
Empty-result header behavior       PASS
Trust-receipt lexical round-trip   PASS
Authenticated trust handoff        PASS
Signed receipt path binding        PASS
Protected runtime authority pin    PASS
Signed orchestrator boundary       PASS
Single-use trust                   PASS
Final-state-complete seal          PASS
Post-seal mutation rejection       PASS
Failure quarantine                 PASS

Fake psql invoked                  true
Real psql invoked                  false
PostgreSQL attempted               false
Database action                    false
Checkpoint/report against DB       false
Recovery                           false
Campaign replay                    false
```

That directly addresses the three R5 correction populations required by the R6 audit: authenticated/non-bypassable trust, production checkpoint/report output handling, and final-state-complete immutable success evidence. [export reference: filecite | turn23file0 | L281-L295] The execution boundary also remains exactly as required: PostgreSQL, accepted checkpoint/report execution, recovery, and Campaign execution remain unauthorized. [export reference: filecite | turn23file0 | L299-L323]

### Exact controlling identities

| Artifact | SHA-256 |
|---|---|
| R5 Correction R2 source | `8b92cd282d9aedb2006936e7d11229d75baf49c8705ef119b416cbf02702f986` |
| Native evidence | `17cfac10e536be75698c3ba560cb82605f55d6b45065130ee1ab4f9ecec49a45` |
| Bootstrap candidate | `722284d50730b4ca94d1b16734d09c4d1b83d5856131c25efebfdb440bc8e655` |
| External authority request | `b953dcdcf5c07a5477cef2f32b9c7cba0d8782e740684834017dc438221b48d6` |

The native sidecar physically matches the uploaded native carrier. The native evidence also binds exactly to:

```text
Manifest SHA-256
16383f20ef39ba6f00a9adf060e77a678422c2722db205719e0647198dd0e9e4

Payload-tree SHA-256
565db599a911621a5270653963299187568528fa8f55a9f6db8b165d0b0b7246

Complete extracted-tree SHA-256
3c8e0ce46d1aecf145d9586a381b286f14cbd521ed002dc1c065195eb51a4600

Protected-manifest SHA-256
b438cca673bb7ec94106807d3f20315081bdeb6365ea1173c59d5e734ebf5496

Protected-tree SHA-256
4c6b6acd25fd99559018e8ddf270c689d0ea2407c087c0309f6a97b44a5f6b20
```

### Final audit wrapper

```text
Artifact
MSBF_CR_WP5_R5_CORRECTION_R2_FINAL_AUDIT_RESUBMISSION_20260821.zip

Bytes
164,514,462

SHA-256
4217ece8c9ffaac2ae36341e0f6f2c48b502fb2171bdc6e8e567a77bca111a1e

ZIP entries
40

Wrapper manifest rows
36

Wrapper manifest SHA-256
c0fa5bb52b4044796eff63b7e79583866ee6f167e36f2a4861ecca14d341884e

Wrapper payload-tree SHA-256
70407d60a600caf79c025973d3c23e1f8f0471b3841600939a3dc5df168654ce

Cross-carrier controls
48 / 48 PASS
```

The wrapper resubmits under **`ER-CAM-004` through `ER-CAM-008`**. It requests independent redetermination of `CAM-F-006`, `CAM-F-011`, and `CAM-F-012`, while preserving the prior closures of `CAM-F-007`, `CAM-F-009`, and `CAM-F-010`. It does **not** self-close findings or claim CR-WP5 acceptance.

The external signer/trust decision also remains correctly external:

```text
decision_status             PENDING_INDEPENDENT_DECISION
bootstrap_approved          false
trust_anchor_approved       false
signer_key_approved         false
source_owner_self_approval  false
private_key_included        false
```

### Deliverables

| Deliverable | File |
|---|---|
| **Final ER-CAM-004→008 audit resubmission** | Download ZIP (historical reference: `sandbox:[session]/MSBF_CR_WP5_R5_CORRECTION_R2_FINAL_AUDIT_RESUBMISSION_20260821.zip`; referenced bytes not established here) |
| Final wrapper SHA-256 sidecar | Download (historical reference: `sandbox:[session]/MSBF_CR_WP5_R5_CORRECTION_R2_FINAL_AUDIT_RESUBMISSION_20260821.zip.sha256`; referenced bytes not established here) |
| Final wrapper validation | Read (historical reference: `sandbox:[session]/MSBF_CR_WP5_R5_CORRECTION_R2_FINAL_AUDIT_RESUBMISSION_20260821_VALIDATION_REPORT.md`; referenced bytes not established here) |
| Machine wrapper validation | Download (historical reference: `sandbox:[session]/MSBF_CR_WP5_R5_CORRECTION_R2_FINAL_AUDIT_RESUBMISSION_20260821_VALIDATION_REPORT.json`; referenced bytes not established here) |
| Main ER-CAM-004→008 resubmission | Read (historical reference: `sandbox:[session]/MSBF_CR_WP5_R5_CORRECTION_R2_FINAL_AUDIT_RESUBMISSION_20260821/04_ER_CAM_004_005_006_007_008/ER_CAM_004_005_006_007_008_R5_R2_FINAL_RESUBMISSION.md`; referenced bytes not established here) |
| Finding response matrix | Download (historical reference: `sandbox:[session]/MSBF_CR_WP5_R5_CORRECTION_R2_FINAL_AUDIT_RESUBMISSION_20260821/04_ER_CAM_004_005_006_007_008/CAMPAIGN_R5_R2_FINDING_RESPONSE_MATRIX.csv`; referenced bytes not established here) |
| ER-CAM response matrix | Download (historical reference: `sandbox:[session]/MSBF_CR_WP5_R5_CORRECTION_R2_FINAL_AUDIT_RESUBMISSION_20260821/04_ER_CAM_004_005_006_007_008/ER_CAM_004_005_006_007_008_R5_R2_SOURCE_OWNER_RESPONSE_MATRIX.csv`; referenced bytes not established here) |
| 48-control cross-carrier reconciliation | Download (historical reference: `sandbox:[session]/MSBF_CR_WP5_R5_CORRECTION_R2_FINAL_AUDIT_RESUBMISSION_20260821/05_VALIDATION/FINAL_CROSS_CARRIER_RECONCILIATION.csv`; referenced bytes not established here) |
| Native evidence ingest validation | Read (historical reference: `sandbox:[session]/MSBF_CR_WP5_R5_CORRECTION_R2_FINAL_AUDIT_RESUBMISSION_20260821/05_VALIDATION/NATIVE_EVIDENCE_INGEST_VALIDATION.md`; referenced bytes not established here) |
| External authority decision request narrative | Read (historical reference: `sandbox:[session]/MSBF_CR_WP5_R5_CORRECTION_R2_FINAL_AUDIT_RESUBMISSION_20260821/03_EXTERNAL_AUTHORITY/EXTERNAL_AUTHORITY_DECISION_REQUIRED.md`; referenced bytes not established here) |
| No-execution attestation | Read (historical reference: `sandbox:[session]/MSBF_CR_WP5_R5_CORRECTION_R2_FINAL_AUDIT_RESUBMISSION_20260821/06_GOVERNANCE/NO_EXECUTION_ATTESTATION.md`; referenced bytes not established here) |
| R5 correction chronology | Read (historical reference: `sandbox:[session]/MSBF_CR_WP5_R5_CORRECTION_R2_FINAL_AUDIT_RESUBMISSION_20260821/06_GOVERNANCE/R5_CORRECTION_CHRONOLOGY.md`; referenced bytes not established here) |
| Final internal wrapper validation | Read (historical reference: `sandbox:[session]/MSBF_CR_WP5_R5_CORRECTION_R2_FINAL_AUDIT_RESUBMISSION_20260821/07_FINAL_VALIDATION/FINAL_WRAPPER_VALIDATION.md`; referenced bytes not established here) |
| Exact uploaded native evidence | Download (historical reference: `sandbox:[session]/CR_WP5_R5_CORRECTION_R2_NATIVE_EVIDENCE.zip`; referenced bytes not established here) |
| Native evidence sidecar | Download (historical reference: `sandbox:[session]/CR_WP5_R5_CORRECTION_R2_NATIVE_EVIDENCE.zip.sha256`; referenced bytes not established here) |
| Exact R2 source carrier | Download (historical reference: `sandbox:[session]/MSBF_CR_WP5_R5_CORRECTION_R2_STATIC_REMEDIATION_20260821.zip`; referenced bytes not established here) |
| R2 external authority request | Download (historical reference: `sandbox:[session]/MSBF_CR_WP5_R5_CORRECTION_R2_EXTERNAL_AUTHORITY_DECISION_REQUEST_20260821.zip`; referenced bytes not established here) |

The next action is now **Independent Audit redetermination only** under `ER-CAM-004` through `ER-CAM-008`, including the separate external signer/trust decision. The audit expressly identifies R5 static remediation as the permitted advancement and continues to prohibit any PostgreSQL, checkpoint/report database execution, recovery, or campaign replay until a governing decision changes that state. [export reference: filecite | turn23file0 | L328-L330]
<!-- END_SOURCE_MESSAGE -->


<a id="m-58f8dbe9-b3f1-47c8-98d3-6f71a15cb20a"></a>
## Andrew / user · C093-M00139

C093-M00139 · 2026-08-21T13:27:52.784000-04:00 · active path

Preceding visible parent: [C093-M00138](part-09.md#m-6f671370-cf87-400a-939f-da55db4413b6)

**Editorial record note:** Attachment references: MSBF_IA_CAMPAIGN_CR_WP5_R5_CORRECTION_R2_AUDIT_R7_20260821_ZIP_VALIDATION_REPORT(1).json; MSBF_IA_CAMPAIGN_CR_WP5_R5_CORRECTION_R2_AUDIT_R7_20260821_ZIP_VALIDATION_REPORT(1).md; AUDIT_ChatGPT_Response(20260821-172733).txt; MSBF_IA_CAMPAIGN_CR_WP5_R5_CORRECTION_R2_AUDIT_R7_20260821(1).zip

<!-- BEGIN_SOURCE_MESSAGE -->
**Prepare an external-authority activation and failure-terminal closure addendum only.** Supply one externally controlled, signed, time-bounded, and revocable decision binding the exact bootstrap carrier and source, authority-root and signer public keys and fingerprints, custody, algorithm, validity period, revocation mechanism, and protected pin. Rebuild the source/native carrier only if the approved protected pin changes. Make the sealed failure population include—or cryptographically chain—the final adapter, driver, and orchestrator `FAIL` states, and reperform the exact no-database failure path. **Do not connect to PostgreSQL, execute a checkpoint or report against a database, invoke recovery, or run the 750, 2,500, or 25,000 Campaign stage.**  
<!-- END_SOURCE_MESSAGE -->


<a id="m-a04e4b99-c726-42e2-baf3-931679d74997"></a>
## Assistant · C093-M00140

C093-M00140 · 2026-08-21T14:15:56.184375-04:00 · active path

Preceding visible parent: [C093-M00139](part-09.md#m-58f8dbe9-b3f1-47c8-98d3-6f71a15cb20a)

<!-- BEGIN_SOURCE_MESSAGE -->
# External-Authority Activation and Failure-Terminal Addendum — Issuance Package Ready

The governing R7 audit accepted **CR-WP5 R5 Correction R2 construction as `PASS_WITH_OBSERVATIONS`**, but retained Campaign runtime readiness on `HOLD`. The remaining governance items are narrowly separated: external bootstrap/signer/trust approval is still unissued, and `CAM-F-013` requires terminal failure-state closure before runtime. [export reference: filecite | turn26file2 | L3-L27]

I did **not** fabricate an “external” signature inside the Campaign source-owner workspace. That would be source-owner self-approval—the exact condition R7 prohibited. The audit expressly states that no independently controlled root key, signer key, fingerprints, custody owner, validity interval, revocation mechanism, signed decision, or approved protected pin had been supplied, and that Independent Audit would not invent those authorities. [export reference: filecite | turn26file2 | L261-L286]

Instead, I prepared the complete, bounded package required for an independently controlled authority to issue that decision, together with an exact failure-terminal source delta ready to apply after the signed decision returns.

## Package result

```text
Artifact
MSBF_CR_WP5_R5_EXTERNAL_AUTHORITY_ACTIVATION_FAILURE_TERMINAL_ADDENDUM_REQUEST_20260821.zip

Bytes
92,546

SHA-256
1e4b69bab409cdf4dfad57230e8268c9c2caca216f29925ea81ff6c9765372db

ZIP entries
47

Manifest rows
43

Manifest SHA-256
0e4432ca1399e304eb55a38c684f7585592348ae9f590bba25d1ca0128d865ee

Preparation controls
16 / 16 PASS

Issuer/verifier cryptographic self-test
PASS

External decision supplied
NO — must be issued externally

Source rebuild performed
NO — approved pin not yet available

Native re-performance performed
NO — final approved-pin bytes do not yet exist

Private key included
NO

Source-owner self-approval
NO

PostgreSQL/database/Campaign activity
0
```

The R7 audit package itself passed ZIP, manifest, path-safety, JSON, and CSV validation before being used as the governing basis. [export reference: filecite | turn26file1 | L1-L20]

## What the package contains

### Externally controlled activation issuance

The package includes working issuance and verification tooling for an independent authority to return:

- the exact authority-root public key and file-byte SHA-256 fingerprint;
- the exact authorization-signer public key and fingerprint;
- root and signer key IDs;
- custody owner and custody system;
- key-exportability attestation;
- rotation and revocation references;
- signed, time-bounded activation decision;
- independently signed revocation-status record;
- independently signed custody attestation;
- exact approved protected-pin bytes;
- exact pin SHA-256 bound into the signed decision;
- RSA PKCS#1 SHA-256 signatures over exact UTF-8/no-BOM payload bytes; and
- a complete public-only manifest and sidecar.

The issuer was tested with temporary self-test keys, and the independently implemented verifier successfully reproduced the signatures, public-key fingerprints, bootstrap identities, protected-pin hash, validity window, active revocation status, manifest, and private-key-exclusion controls. Those test keys were deleted and are not in the package.

### Exact failure-terminal source delta

R7 found that the parent attempt contained final adapter, driver, and orchestrator `FAIL` states, but the quarantine bundle was sealed earlier—while its copied adapter state remained `STARTED` and before driver/orchestrator terminal records existed. [export reference: filecite | turn26file2 | L224-L257]

The prepared delta uses the audit-permitted **self-contained sealed-population option**:

```text
ADAPTER_FAILURE.json
→ final adapter_attempt_state.json = FAIL
→ final driver_end_state.json = FAIL
→ driver throws
→ final orchestrator_end_state.json = FAIL
→ quarantine copy
→ QUARANTINE_MANIFEST.csv
→ QUARANTINE_SEAL.json
→ QUARANTINE_REVALIDATION.json
```

The proposed seal binds:

```text
ADAPTER_FAILURE.json SHA-256
final adapter state SHA-256
final driver state SHA-256
final orchestrator state SHA-256
quarantine manifest SHA-256
quarantine tree SHA-256
execution attempt ID
automatic_recovery_allowed = false
```

The strengthened `R5-NAT-040` control requires all three copied terminal states to be `FAIL`, carry the same attempt ID, appear exactly once in the quarantine manifest, match the parent final-state hashes recorded by the seal, and pass post-seal physical revalidation.

The package contains exact unified diffs and complete proposed replacements for:

```text
Invoke-MSBFSingleSessionReadOnlyAdapter.ps1
Invoke-MSBFTrustedAdapterAttempt.ps1
Invoke-CRWP5R5NativeOfflineTests.ps1
```

Each delta is pinned to the exact R5 Correction R2 preimage SHA-256 so it cannot silently apply to another source revision.

## Why no source/native rebuild was issued yet

The current protected pin still contains unresolved `<IA_TO_APPROVE>` placeholders. Any legitimate external approval will therefore change the protected-pin bytes and SHA-256. R7 requires rebuilding the protected pin and affected source/native identities **only after** the external decision exists. [export reference: filecite | turn26file2 | L274-L286]

The package therefore preserves the correct order:

```text
Independent authority issues signed activation
→ source workstream verifies signatures, validity, revocation and custody
→ approved pin is embedded
→ failure-terminal delta is applied
→ affected identities are regenerated
→ one final source carrier is built
→ exact success and injected-failure no-database paths are rerun
→ ER-CAM-006 / ER-CAM-009 addendum is submitted
```

This follows the audit’s exact permitted next action. [export reference: filecite | turn26file2 | L354-L357]

## Deliverables

### Primary package

- Download the external-authority and failure-terminal addendum request (historical reference: `sandbox:[session]/MSBF_CR_WP5_R5_EXTERNAL_AUTHORITY_ACTIVATION_FAILURE_TERMINAL_ADDENDUM_REQUEST_20260821.zip`; referenced bytes not established here)
- Download the SHA-256 sidecar (historical reference: `sandbox:[session]/MSBF_CR_WP5_R5_EXTERNAL_AUTHORITY_ACTIVATION_FAILURE_TERMINAL_ADDENDUM_REQUEST_20260821.zip.sha256`; referenced bytes not established here)
- Read the validation report (historical reference: `sandbox:[session]/MSBF_CR_WP5_R5_EXTERNAL_AUTHORITY_ACTIVATION_FAILURE_TERMINAL_ADDENDUM_REQUEST_20260821_VALIDATION_REPORT.md`; referenced bytes not established here)
- Download the machine-readable validation (historical reference: `sandbox:[session]/MSBF_CR_WP5_R5_EXTERNAL_AUTHORITY_ACTIVATION_FAILURE_TERMINAL_ADDENDUM_REQUEST_20260821_VALIDATION_REPORT.json`; referenced bytes not established here)
- Read the package start guide (historical reference: `sandbox:[session]/MSBF_CR_WP5_R5_EXTERNAL_AUTHORITY_ACTIVATION_FAILURE_TERMINAL_ADDENDUM_REQUEST_20260821/00_READ_FIRST/README_FIRST.md`; referenced bytes not established here)

### Independent-authority handoff

- Copy/paste prompt for the independent authority (historical reference: `sandbox:[session]/MSBF_CR_WP5_R5_EXTERNAL_AUTHORITY_ACTIVATION_FAILURE_TERMINAL_ADDENDUM_REQUEST_20260821/05_HANDOFF/COPY_PASTE_PROMPT_FOR_INDEPENDENT_AUTHORITY.md`; referenced bytes not established here)
- Read the issuance instructions (historical reference: `sandbox:[session]/MSBF_CR_WP5_R5_EXTERNAL_AUTHORITY_ACTIVATION_FAILURE_TERMINAL_ADDENDUM_REQUEST_20260821/03_EXTERNAL_AUTHORITY_ISSUANCE/EXTERNAL_AUTHORITY_ISSUANCE_INSTRUCTIONS.md`; referenced bytes not established here)
- Download the authority issuance script (historical reference: `sandbox:[session]/MSBF_CR_WP5_R5_EXTERNAL_AUTHORITY_ACTIVATION_FAILURE_TERMINAL_ADDENDUM_REQUEST_20260821/03_EXTERNAL_AUTHORITY_ISSUANCE/issue_external_authority_activation.py`; referenced bytes not established here)
- Download the activation verifier (historical reference: `sandbox:[session]/MSBF_CR_WP5_R5_EXTERNAL_AUTHORITY_ACTIVATION_FAILURE_TERMINAL_ADDENDUM_REQUEST_20260821/03_EXTERNAL_AUTHORITY_ISSUANCE/verify_external_authority_activation.py`; referenced bytes not established here)
- Download the external-authority return requirements (historical reference: `sandbox:[session]/MSBF_CR_WP5_R5_EXTERNAL_AUTHORITY_ACTIVATION_FAILURE_TERMINAL_ADDENDUM_REQUEST_20260821/05_HANDOFF/EXTERNAL_AUTHORITY_RETURN_REQUIREMENTS.json`; referenced bytes not established here)
- Read the issuer/verifier self-test result (historical reference: `sandbox:[session]/MSBF_CR_WP5_R5_EXTERNAL_AUTHORITY_ACTIVATION_FAILURE_TERMINAL_ADDENDUM_REQUEST_20260821/07_VALIDATION/ISSUANCE_AND_VERIFIER_SELFTEST.json`; referenced bytes not established here)

### Decision and pin schemas

- External authority decision template (historical reference: `sandbox:[session]/MSBF_CR_WP5_R5_EXTERNAL_AUTHORITY_ACTIVATION_FAILURE_TERMINAL_ADDENDUM_REQUEST_20260821/03_EXTERNAL_AUTHORITY_ISSUANCE/EXTERNAL_AUTHORITY_DECISION_TEMPLATE.json`; referenced bytes not established here)
- Protected external-authority pin template (historical reference: `sandbox:[session]/MSBF_CR_WP5_R5_EXTERNAL_AUTHORITY_ACTIVATION_FAILURE_TERMINAL_ADDENDUM_REQUEST_20260821/03_EXTERNAL_AUTHORITY_ISSUANCE/PROTECTED_EXTERNAL_AUTHORITY_PIN_TEMPLATE.json`; referenced bytes not established here)
- Revocation-status template (historical reference: `sandbox:[session]/MSBF_CR_WP5_R5_EXTERNAL_AUTHORITY_ACTIVATION_FAILURE_TERMINAL_ADDENDUM_REQUEST_20260821/03_EXTERNAL_AUTHORITY_ISSUANCE/REVOCATION_STATUS_TEMPLATE.json`; referenced bytes not established here)
- Key-custody attestation template (historical reference: `sandbox:[session]/MSBF_CR_WP5_R5_EXTERNAL_AUTHORITY_ACTIVATION_FAILURE_TERMINAL_ADDENDUM_REQUEST_20260821/03_EXTERNAL_AUTHORITY_ISSUANCE/KEY_CUSTODY_ATTESTATION_TEMPLATE.json`; referenced bytes not established here)
- Exact activation-input identities (historical reference: `sandbox:[session]/MSBF_CR_WP5_R5_EXTERNAL_AUTHORITY_ACTIVATION_FAILURE_TERMINAL_ADDENDUM_REQUEST_20260821/02_EXACT_INPUT_IDENTITIES/EXACT_ACTIVATION_INPUTS.json`; referenced bytes not established here)

### Failure-terminal closure

- Read the failure-terminal closure contract (historical reference: `sandbox:[session]/MSBF_CR_WP5_R5_EXTERNAL_AUTHORITY_ACTIVATION_FAILURE_TERMINAL_ADDENDUM_REQUEST_20260821/04_FAILURE_TERMINAL_CLOSURE/FAILURE_TERMINAL_CLOSURE_CONTRACT.md`; referenced bytes not established here)
- Read the source-rebuild rule (historical reference: `sandbox:[session]/MSBF_CR_WP5_R5_EXTERNAL_AUTHORITY_ACTIVATION_FAILURE_TERMINAL_ADDENDUM_REQUEST_20260821/04_FAILURE_TERMINAL_CLOSURE/SOURCE_REBUILD_RULE.md`; referenced bytes not established here)
- Download the exact source-delta identity register (historical reference: `sandbox:[session]/MSBF_CR_WP5_R5_EXTERNAL_AUTHORITY_ACTIVATION_FAILURE_TERMINAL_ADDENDUM_REQUEST_20260821/04_FAILURE_TERMINAL_CLOSURE/FAILURE_TERMINAL_SOURCE_DELTA_IDENTITIES.json`; referenced bytes not established here)
- Driver failure-ordering patch (historical reference: `sandbox:[session]/MSBF_CR_WP5_R5_EXTERNAL_AUTHORITY_ACTIVATION_FAILURE_TERMINAL_ADDENDUM_REQUEST_20260821/04_FAILURE_TERMINAL_CLOSURE/PATCHES/Invoke-MSBFSingleSessionReadOnlyAdapter.ps1.failure_terminal_closure.patch`; referenced bytes not established here)
- Orchestrator terminal-sealing patch (historical reference: `sandbox:[session]/MSBF_CR_WP5_R5_EXTERNAL_AUTHORITY_ACTIVATION_FAILURE_TERMINAL_ADDENDUM_REQUEST_20260821/04_FAILURE_TERMINAL_CLOSURE/PATCHES/Invoke-MSBFTrustedAdapterAttempt.ps1.failure_terminal_closure.patch`; referenced bytes not established here)
- Strengthened native failure-test patch (historical reference: `sandbox:[session]/MSBF_CR_WP5_R5_EXTERNAL_AUTHORITY_ACTIVATION_FAILURE_TERMINAL_ADDENDUM_REQUEST_20260821/04_FAILURE_TERMINAL_CLOSURE/PATCHES/Invoke-CRWP5R5NativeOfflineTests.ps1.failure_terminal_closure.patch`; referenced bytes not established here)

### Governance

- Read the no-execution attestation (historical reference: `sandbox:[session]/MSBF_CR_WP5_R5_EXTERNAL_AUTHORITY_ACTIVATION_FAILURE_TERMINAL_ADDENDUM_REQUEST_20260821/06_GOVERNANCE/NO_EXECUTION_ATTESTATION.md`; referenced bytes not established here)
- Download the 16-control preparation validation (historical reference: `sandbox:[session]/MSBF_CR_WP5_R5_EXTERNAL_AUTHORITY_ACTIVATION_FAILURE_TERMINAL_ADDENDUM_REQUEST_20260821/07_VALIDATION/STATIC_CONTROL_RESULTS.csv`; referenced bytes not established here)
- Read the final internal validation (historical reference: `sandbox:[session]/MSBF_CR_WP5_R5_EXTERNAL_AUTHORITY_ACTIVATION_FAILURE_TERMINAL_ADDENDUM_REQUEST_20260821/07_VALIDATION/FINAL_PACKAGE_VALIDATION.md`; referenced bytes not established here)

## Required external return

Send the primary ZIP to the Independent Audit workspace or another expressly designated independent key custodian using the included copy/paste prompt. The required return is exactly:

```text
MSBF_R5_EXTERNAL_AUTHORITY_ACTIVATION_RETURN.zip
MSBF_R5_EXTERNAL_AUTHORITY_ACTIVATION_RETURN.zip.sha256
```

After those two files return, the approved protected pin can be embedded, the three-file failure-terminal delta applied, all affected source/tree identities regenerated, and the exact no-database success and injected-failure paths rerun. PostgreSQL and every Campaign stage remain prohibited throughout this addendum cycle. [export reference: filecite | turn26file2 | L315-L343]
<!-- END_SOURCE_MESSAGE -->


<a id="m-ea2bb2d5-885b-4928-9ab9-023f3e218d0d"></a>
## Andrew / user · C093-M00141

C093-M00141 · 2026-08-21T16:39:34.823000-04:00 · active path

Preceding visible parent: [C093-M00140](part-09.md#m-a04e4b99-c726-42e2-baf3-931679d74997)

**Editorial record note:** Attachment references: MSBF_R5_EXTERNAL_AUTHORITY_ACTIVATION_RETURN(1).zip; MSBF_R5_EXTERNAL_AUTHORITY_ACTIVATION_RETURN.zip(1).sha256

<!-- BEGIN_SOURCE_MESSAGE -->
# External-authority activation issued

**Decision:** `PASS_WITH_OBSERVATIONS — ACTIVATION ISSUED`

The exact bootstrap carrier and source are approved **only** for the bounded `NO_DATABASE_FAKE_PSQL_TEST_ONLY` addendum cycle. This decision does not authorize PostgreSQL, real `psql`, database creation or mutation, accepted checkpoint/report execution, recovery, or any 750/2,500/25,000 Campaign stage.

The governing audit standard continues to require independent verification and prohibits converting static source quality into runtime or public acceptance. 

## Issued authority

```text
Decision ID
IA-D-R7-CAM-001-AUTH-20260821-001

Approved bootstrap carrier
MSBF_CR_WP5_R5_PREIMPORT_BOOTSTRAP_CANDIDATE_20260821_R1.zip

Approved bootstrap carrier SHA-256
722284d50730b4ca94d1b16734d09c4d1b83d5856131c25efebfdb440bc8e655

Approved bootstrap source SHA-256
f85244b5454ae261492635ffb2d0c0caa04f223d03b6552a244c8d764ef1c20f

Permitted client mode
NO_DATABASE_FAKE_PSQL_TEST_ONLY

Issued
2026-08-21T18:54:00Z

Not before
2026-08-21T18:54:00Z

Expires
2026-09-20T18:54:00Z

Revocation status
ACTIVE / NOT_REVOKED

Revocation reference
IA-MSBF-R5-REVOCATION-20260821-001
```

## Cryptographic identities

```text
Authority-root key ID
IA-MSBF-R5-ROOT-20260821-001

Authority-root public-key SHA-256
09bdeb9c7768e1269b9ea433928bed79b06f046d65d6d6dc0be2150ab675006a

Authorization-signer key ID
IA-MSBF-R5-SIGNER-20260821-001

Authorization-signer public-key SHA-256
32e0085e81969c1793a2fa4110b81ac57ceea691b160edba8e65560621ef9011

Approved protected-pin SHA-256
945618dcd5bb24ffce59f91333d1e5e353ed720904f97348608d2bc08821cd95

Signature algorithm
RSA_PKCS1_SHA256

Canonicalization
UTF8_NO_BOM_EXACT_PAYLOAD_BYTES
```

The root and signer are distinct 3072-bit RSA key pairs. Their private keys are held outside the return package in the restricted Independent Audit workspace for this issuance cycle. Custody is software-based and **not HSM-backed**; that limitation is expressly recorded in the signed custody attestation. No private key is included in the user-facing package.

## Independent validation

The return package passed **82 independently re-performed controls**, including:

```text
ZIP SHA-256 and sidecar                  PASS
ZIP CRC and exact file population       PASS
Unsafe, duplicate and case-fold paths   0
Symlinks and encrypted members          0
Manifest and SHA256SUMS reconciliation  PASS
Root and signer key-pair verification   PASS
Three detached root signatures          PASS
Decision, pin and revocation binding    PASS
Bootstrap carrier/source binding        PASS
Validity-window controls                PASS
Signer custody proof                    PASS
Private-key exclusion                   PASS
Source-owner self-approval              FALSE
```

```text
Activation return ZIP SHA-256
f2853de82b5164fc657ee052dcdd97ee29f6d3522752a7d372532cc5e153d11d
```

## Updated governance state

| Item                               | Disposition                                           |
| ---------------------------------- | ----------------------------------------------------- |
| R5 static/no-database construction | `PASS_WITH_OBSERVATIONS — UNCHANGED`                  |
| External bootstrap identity        | `PASS_WITH_OBSERVATIONS`                              |
| External fake-engine activation    | `PASS_WITH_OBSERVATIONS — ISSUED`                     |
| `ER-CAM-006`                       | `OPEN_PENDING_FINAL_SOURCE_AND_AUTHORIZATION_BINDING` |
| `CAM-F-013`                        | `OPEN / MODERATE`                                     |
| Campaign runtime readiness         | `HOLD`                                                |
| PostgreSQL or real `psql`          | `NOT AUTHORIZED`                                      |
| Checkpoint/report against database | `NOT AUTHORIZED`                                      |
| Recovery or Campaign replay        | `NOT AUTHORIZED`                                      |
| Public Campaign milestone claim    | `NOT AUTHORIZED`                                      |

The activation package does **not** itself close `CAM-F-013`. The three-file failure-terminal delta must still be applied, built into one final source carrier, and re-performed through the exact no-database injected-failure path.

## Required next sequence

```text
Use the exact activation return unchanged
→ verify its signatures, validity and active revocation status
→ embed the exact protected pin
→ apply the exact three-file failure-terminal delta
→ regenerate all affected source/tree/carrier identities
→ prepare the final canonical authorization payload
→ return that payload to Independent Audit for detached signer authorization
→ run the exact no-database success and injected-failure paths
→ resubmit final ER-CAM-006 / ER-CAM-009 evidence
```

The additional detached-signing handoff is mandatory because the approved authorization-signer private key remains under Independent Audit custody and is not supplied to the source owner. The source owner must not replace that key or self-sign the final authorization.

## Required return files

Download `MSBF_R5_EXTERNAL_AUTHORITY_ACTIVATION_RETURN.zip` (historical reference: `sandbox:[session]/MSBF_R5_EXTERNAL_AUTHORITY_ACTIVATION_RETURN.zip`; referenced bytes not established here)

Download the SHA-256 sidecar (historical reference: `sandbox:[session]/MSBF_R5_EXTERNAL_AUTHORITY_ACTIVATION_RETURN.zip.sha256`; referenced bytes not established here)

<!-- END_SOURCE_MESSAGE -->


<a id="m-b222f6fe-fe56-4a38-b0f4-f451c6629797"></a>
## Assistant · C093-M00142

C093-M00142 · 2026-08-21T17:48:33.641085-04:00 · active path

Preceding visible parent: [C093-M00141](part-09.md#m-ea2bb2d5-885b-4928-9ab9-023f3e218d0d)

<!-- BEGIN_SOURCE_MESSAGE -->
# External Activation Applied; Detached-Signing Handoff Ready

The independently issued activation return has been verified and applied to the R5 source. Because the approved protected-pin identity changed, the source carrier was rebuilt as required. The exact three-file failure-terminal delta was also applied, and all affected source, catalog, manifest, protected-tree, and carrier identities were regenerated.

The R7 audit had already accepted R5 static/no-database construction with observations while retaining runtime readiness on `HOLD`; it identified `CAM-F-013` as the remaining failure-terminal issue required before runtime. [export reference: filecite | turn26file2 | L13-L27] The defect was specifically that the sealed quarantine copy preceded the final adapter, driver, and orchestrator `FAIL` states. [export reference: filecite | turn26file2 | L224-L257]

## External activation verification

The uploaded activation return independently reconciled as follows:

```text
Activation return SHA-256
f2853de82b5164fc657ee052dcdd97ee29f6d3522752a7d372532cc5e153d11d

Decision ID
IA-D-R7-CAM-001-AUTH-20260821-001

Decision status
APPROVED

Permitted client mode
NO_DATABASE_FAKE_PSQL_TEST_ONLY

Authority-root key
IA-MSBF-R5-ROOT-20260821-001
09bdeb9c7768e1269b9ea433928bed79b06f046d65d6d6dc0be2150ab675006a

Authorization signer
IA-MSBF-R5-SIGNER-20260821-001
32e0085e81969c1793a2fa4110b81ac57ceea691b160edba8e65560621ef9011

Approved protected pin
945618dcd5bb24ffce59f91333d1e5e353ed720904f97348608d2bc08821cd95

Root signatures verified
3 / 3 PASS

Revocation status
ACTIVE / NOT_REVOKED

Private key included
false

Source-owner self-approval
false
```

The three verified root signatures cover the exact activation decision, key-custody attestation, and revocation-status payloads. The root and authorization-signer public keys are distinct RSA-3072 identities.

## Failure-terminal closure applied

The exact R7 three-file delta is now incorporated into the rebuilt source. The failure sequence is:

```text
ADAPTER_FAILURE.json
→ final adapter_attempt_state.json = FAIL
→ final driver_end_state.json = FAIL
→ driver throws
→ final orchestrator_end_state.json = FAIL
→ construct quarantine population
→ QUARANTINE_MANIFEST.csv
→ QUARANTINE_SEAL.json
→ QUARANTINE_REVALIDATION.json
```

The revised failure seal is designed to bind:

```text
ADAPTER_FAILURE.json SHA-256
final adapter FAIL-state SHA-256
final driver FAIL-state SHA-256
final orchestrator FAIL-state SHA-256
quarantine-manifest SHA-256
quarantine-tree SHA-256
execution-attempt identity
automatic_recovery_allowed = false
```

`R5-NAT-040` now requires the exact governed result:

```text
FAILURE_TERMINAL_SEALED
```

The success path, checkpoint contract, report splitter, expected-empty header behavior, fake-engine fixtures, and other existing R5 native expectations were not redesigned.

## Rebuilt source identity

```text
Artifact
MSBF_CR_WP5_R5_ACTIVATED_FAILURE_TERMINAL_ADDENDUM_SOURCE_20260821_R1.zip

Bytes
119,687,038

SHA-256
cdd80b674ac6697977d466d2fe63ca2a857ed9b2bf7bde66d98d86deb94acfee

ZIP entries
1,214

Manifest rows
1,210

Manifest SHA-256
7e09dd603436d0248aad1db02bc1c0b53fbcb351a452c49e5d7c3814850636e5

Payload-tree SHA-256
b01a273ac453e0499b8fd3455653a3b929ef6a79c86da108559d4607bbb9cce2

Complete carrier-tree SHA-256
6c5a88d9af97521a2329bda4cb86e31609242bcf60e9731a8077ad8ca00e1dc8

Protected-manifest SHA-256
75d6a52aebb439374eec8a55f5e5bb507328ff5b8690487619d0895c75dc5d48

Protected-tree SHA-256
51d7d438fb05fcbc897167c1fcd5366cc0e0b595e542414202ed7b7a8ecc06b9

Static controls
82 / 82 PASS

Standalone validator
PASS
```

The exact approved protected pin is embedded. The external-activation return and its public decision, keys, custody, revocation, and signature records are retained as package provenance. All 230 current adapter definitions and canonical binding rows were regenerated against the changed driver, orchestrator, trust module, pin, and catalog identities.

## Mandatory detached-signing handoff

The source owner cannot complete the next cryptographic step because the approved authorization-signer private key remains under Independent Audit custody. I therefore prepared the exact signing request rather than substituting or self-signing with another key.

The package contains two immutable canonical authorization cases:

```text
SUCCESS_CHECKPOINT
INJECTED_FAILURE
```

Each case includes:

- the exact canonical authorization payload;
- target and environment evidence;
- a trust-receipt template;
- exact final source, manifest, payload-tree, complete-tree, and protected-tree identities;
- the approved activation, pin, root, and signer identities;
- the exact no-database fake-engine mode;
- all prohibited actions set to `false`; and
- exact Windows paths for the signed return and attempt roots.

### Signing-request identity

```text
Artifact
MSBF_CR_WP5_R5_ACTIVATED_ADDENDUM_AUTHORIZATION_SIGNING_REQUEST_20260821.zip

Bytes
119,455,028

SHA-256
c4968065cc7a4e95b37c68472b7f786f9fa3b3e08f433cce1fc84a99087206f8

ZIP entries
22

Manifest rows
18

Manifest SHA-256
181e2cc8e830f7559cad30a10ad934f7473bd88f11dafbf750d0d8cb60cb67bb

SHA256SUMS SHA-256
09cd29a036b8570bc32e165f84d6cf797afd936e69549dc6db03799141d8b19f

Payload-tree SHA-256
34eb9148b2bcbe3d1bcd9d7e7002c569d0f24be20bddb6684c44cfd794c7cbe4

Authorization signer
IA-MSBF-R5-SIGNER-20260821-001

Authorization window
2026-08-21T21:15:00Z
through
2026-08-28T18:54:00Z
```

The included signing utility verifies the activation return, root-signed decision, revocation status, protected pin, approved signer identity, final source identity, authorization scope, validity period, and prohibited-action boundary before it uses the independently controlled signer private key. The issuance and return-verification utilities compile successfully and passed a temporary-key end-to-end self-test; no temporary or external private key is included.

## Current governance state

| Item | Current status |
|---|---|
| External activation verification | **PASS** |
| Approved pin embedded | **PASS** |
| Three-file failure-terminal delta | **APPLIED** |
| Source identity regeneration | **COMPLETE** |
| Source static controls | **82 / 82 PASS** |
| Final canonical authorizations | **COMPLETE** |
| Independent detached signatures | **PENDING** |
| Native success/failure re-performance | **NOT YET PERFORMED** |
| `CAM-F-013` | **PENDING FINAL NATIVE REPERFORMANCE AND IA REDETERMINATION** |
| `ER-CAM-006` / `ER-CAM-009` addendum | **NOT YET SUBMITTED** |
| PostgreSQL / real `psql` | **NOT AUTHORIZED** |
| Campaign stage | **NOT AUTHORIZED** |

This is the correct stop point. The R7 audit expressly allowed only external-authority activation, failure-terminal closure, final identity rebuilding when the pin changed, and exact no-database re-performance; PostgreSQL and every Campaign stage remain prohibited. [export reference: filecite | turn26file2 | L315-L343] [export reference: filecite | turn26file2 | L354-L357]

## Deliverables

### Send these to Independent Audit now

- Download the detached-signing request ZIP (historical reference: `sandbox:[session]/MSBF_CR_WP5_R5_ACTIVATED_ADDENDUM_AUTHORIZATION_SIGNING_REQUEST_20260821.zip`; referenced bytes not established here)
- Download its SHA-256 sidecar (historical reference: `sandbox:[session]/MSBF_CR_WP5_R5_ACTIVATED_ADDENDUM_AUTHORIZATION_SIGNING_REQUEST_20260821.zip.sha256`; referenced bytes not established here)
- Open the copy/paste prompt for Independent Audit (historical reference: `sandbox:[session]/MSBF_CR_WP5_R5_ACTIVATED_ADDENDUM_COPY_PASTE_PROMPT_FOR_INDEPENDENT_AUDIT.md`; referenced bytes not established here)
- Read the signing-request README (historical reference: `sandbox:[session]/MSBF_CR_WP5_R5_ACTIVATED_ADDENDUM_SIGNING_REQUEST_README.md`; referenced bytes not established here)
- Read the signing-request validation report (historical reference: `sandbox:[session]/MSBF_CR_WP5_R5_ACTIVATED_ADDENDUM_AUTHORIZATION_SIGNING_REQUEST_20260821_VALIDATION_REPORT.md`; referenced bytes not established here)
- Download the machine-readable signing validation (historical reference: `sandbox:[session]/MSBF_CR_WP5_R5_ACTIVATED_ADDENDUM_AUTHORIZATION_SIGNING_REQUEST_20260821_VALIDATION_REPORT.json`; referenced bytes not established here)

### Rebuilt source carrier

- Download the activated failure-terminal source ZIP (historical reference: `sandbox:[session]/MSBF_CR_WP5_R5_ACTIVATED_FAILURE_TERMINAL_ADDENDUM_SOURCE_20260821_R1.zip`; referenced bytes not established here)
- Download the source SHA-256 sidecar (historical reference: `sandbox:[session]/MSBF_CR_WP5_R5_ACTIVATED_FAILURE_TERMINAL_ADDENDUM_SOURCE_20260821_R1.zip.sha256`; referenced bytes not established here)
- Read the source validation report (historical reference: `sandbox:[session]/MSBF_CR_WP5_R5_ACTIVATED_FAILURE_TERMINAL_ADDENDUM_SOURCE_20260821_R1_VALIDATION_REPORT.md`; referenced bytes not established here)
- Download the machine-readable source validation (historical reference: `sandbox:[session]/MSBF_CR_WP5_R5_ACTIVATED_FAILURE_TERMINAL_ADDENDUM_SOURCE_20260821_R1_VALIDATION_REPORT.json`; referenced bytes not established here)
- Download the standalone validation (historical reference: `sandbox:[session]/MSBF_CR_WP5_R5_ACTIVATED_FAILURE_TERMINAL_ADDENDUM_SOURCE_20260821_R1_STANDALONE_VALIDATION.json`; referenced bytes not established here)

### Construction and verification records

- Read the complete construction report (historical reference: `sandbox:[session]/MSBF_CR_WP5_R5_ACTIVATED_FAILURE_TERMINAL_ADDENDUM_CONSTRUCTION_REPORT.md`; referenced bytes not established here)
- Download the machine construction report (historical reference: `sandbox:[session]/MSBF_CR_WP5_R5_ACTIVATED_FAILURE_TERMINAL_ADDENDUM_CONSTRUCTION_REPORT.json`; referenced bytes not established here)
- Download the 33-control preparation register (historical reference: `sandbox:[session]/MSBF_CR_WP5_R5_ACTIVATED_FAILURE_TERMINAL_ADDENDUM_PREPARATION_CONTROLS.csv`; referenced bytes not established here)
- Download the exact R2→activated-addendum source diff (historical reference: `sandbox:[session]/MSBF_CR_WP5_R5_ACTIVATED_FAILURE_TERMINAL_ADDENDUM_R2_TO_R1_SOURCE_DIFF.csv`; referenced bytes not established here)
- Download the activation verification record (historical reference: `sandbox:[session]/MSBF_CR_WP5_R5_EXTERNAL_AUTHORITY_ACTIVATION_VERIFICATION.json`; referenced bytes not established here)
- Download the signing issuer/verifier self-test (historical reference: `sandbox:[session]/MSBF_CR_WP5_R5_ACTIVATED_ADDENDUM_SIGNING_REQUEST_SELFTEST.json`; referenced bytes not established here)
- Read the exact next-step instructions (historical reference: `sandbox:[session]/CR_WP5_R5_ACTIVATED_ADDENDUM_NEXT_STEP.md`; referenced bytes not established here)

## Required Independent Audit return

Independent Audit must return these files unchanged:

```text
MSBF_CR_WP5_R5_ACTIVATED_ADDENDUM_AUTHORIZATION_SIGNING_RETURN_20260821.zip

MSBF_CR_WP5_R5_ACTIVATED_ADDENDUM_AUTHORIZATION_SIGNING_RETURN_20260821.zip.sha256
```

The signed return must be issued and used before:

```text
2026-08-28T18:54:00Z
```

If that window is missed, the canonical authorization request must be regenerated; its payloads must not be edited. After the signed return is uploaded, the next bounded action is to verify it, generate the exact-byte runner, execute only the no-database `SUCCESS_CHECKPOINT` and `INJECTED_FAILURE` cases, and prepare the final `ER-CAM-006 / ER-CAM-009` addendum.
<!-- END_SOURCE_MESSAGE -->


<a id="m-6d274925-114a-4761-9f47-447ae8eb5918"></a>
## Andrew / user · C093-M00143

C093-M00143 · 2026-08-21T23:40:44.294000-04:00 · active path

Preceding visible parent: [C093-M00142](part-09.md#m-b222f6fe-fe56-4a38-b0f4-f451c6629797)

**Editorial record note:** Attachment references: 06_EXACT_NEXT_ACTION(1).md; INDEPENDENT_AUDIT_STATUS_DASHBOARD(20260821-224324)(1).md; MISMATCHED_KEY_NEGATIVE_TEST(1).txt; MSBF_IA_CAMPAIGN_R5_DETACHED_SIGNING_CUSTODY_HOLD_R9_20260821(1).zip; MSBF_IA_CAMPAIGN_R5_DETACHED_SIGNING_CUSTODY_HOLD_R9_20260821.zip(1).sha256; MSBF_IA_CAMPAIGN_R5_DETACHED_SIGNING_CUSTODY_HOLD_R9_20260821_ZIP_VALIDATION_REPORT(1).md; SIGNER_CUSTODY_SEARCH_RESULTS(1).json; SIGNING_REQUEST_AUDIT_CONTROL_RESULTS(1).csv; 01_IA_WP3G_CAMPAIGN_R5_DETACHED_SIGNING_CUSTODY_AUDIT_REPORT(1).md; 02_IA_WP3G_MACHINE_SUMMARY(1).json; 03_CAMPAIGN_EXTERNAL_AUTHORITY_CUSTODY_RECOVERY_OR_ROTATION_PROMPT(1).md; 04_AUTHORITY_DECISION_AND_SUPERSESSION_REGISTER(1).csv

<!-- BEGIN_SOURCE_MESSAGE -->
# IA-WP3G — Detached-signing custody audit completed

**Decision ID:** `IA-D-R9-CAM-001-CUSTODY`

## Governing disposition

| DecisionIndependent disposition                              |                                           |
| ------------------------------------------------------------ | ----------------------------------------- |
| Activated-addendum signing request                           | `PASS_WITH_OBSERVATIONS`                  |
| Exact two-case authorization population                      | `PASS`                                    |
| Rebuilt source carrier                                       | `PASS` — physical identity and manifests  |
| Activation-return public records                             | `PASS` — signatures and public identities |
| **Approved signer private-key custody**                      | **`FAIL / BLOCKING`**                     |
| **Detached-signature issuance**                              | **`HOLD`**                                |
| Requested signing-return ZIP                                 | **`NOT ISSUED`**                          |
| Prior activation decision                                    | **`SUPERSEDED / WITHDRAWN FOR NEW USE`**  |
| CR-WP5 R5 construction                                       | `PASS_WITH_OBSERVATIONS — UNCHANGED`      |
| `CAM-F-013`                                                  | `OPEN / MODERATE — UNCHANGED`             |
| Campaign runtime readiness                                   | `HOLD`                                    |
| PostgreSQL, database execution, recovery, or Campaign replay | `NOT AUTHORIZED`                          |

This is **not a cybersecurity-policy refusal**. The packages were fully inspected and the canonical authorizations were validated. The blocking issue is a real cryptographic custody failure: the private key corresponding to the approved authorization-signer public key is not available at the signing boundary.

## What passed

The signing request independently reconciles to:

```text
Signing request SHA-256
c4968065cc7a4e95b37c68472b7f786f9fa3b3e08f433cce1fc84a99087206f8

ZIP entries
22

Manifest
18 / 18 PASS

SHA256SUMS
18 / 18 PASS

Rebuilt source SHA-256
cdd80b674ac6697977d466d2fe63ca2a857ed9b2bf7bde66d98d86deb94acfee

Activation return SHA-256
f2853de82b5164fc657ee052dcdd97ee29f6d3522752a7d372532cc5e153d11d
```

The request contains exactly the two expected cases:

```text
SUCCESS_CHECKPOINT
0691e3cdd2d82041afa56575edf2322a8fffb271c12becbd9b53c1272e4988e7

INJECTED_FAILURE
2269c7235fa72420427d717ddda6bb1272f2b2c666e255bdb4bb0ed1873d76a6
```

Both cases bind the exact rebuilt source, activation return, protected pin, signer identity, no-database mode, and prohibited-action population. The request package reports itself as ready for an independent signer while expressly containing **no private key**.

The activation return’s three root signatures independently verify:

```text
Activation decision signature      PASS
Revocation-status signature        PASS
Key-custody attestation signature  PASS
Protected-pin identity             PASS
```

The request’s authorized window is:

```text
2026-08-21T21:15:00Z
through
2026-08-28T18:54:00Z
```

It remains limited to the two no-database cases and does not authorize PostgreSQL or Campaign execution.

## Blocking custody finding — `IA-F-003`

The approved signer is:

```text
Signer key ID
IA-MSBF-R5-SIGNER-20260821-001

Approved signer public-key file SHA-256
32e0085e81969c1793a2fa4110b81ac57ceea691b160edba8e65560621ef9011
```

The external-authority protocol requires a **retained authorization-signer private key under independently controlled custody**. It also correctly prohibits including that private key in the public activation-return package.

At this signing event:

- no private key matching the approved signer was present in the accessible Independent Audit workspace;
- no matching private key was found across 75 accessible archive carriers;
- the private keys that were found belonged to unrelated static-test identities;
- their derived public keys did not match the approved signer;
- a newly generated substitute key was correctly rejected by the supplied issuance utility; and
- no signing-return ZIP or sidecar was created.

A different key cannot be substituted while retaining the approved signer ID and public-key identity. That would create a false cryptographic assertion, and the supplied verifier would reject it.

## Correction of the prior custody record

I need to correct the earlier activation response.

The prior statement that the authority-root and authorization-signer private keys were retained in a restricted Independent Audit workspace was **not durable across the session boundary**. I withdraw that custody-continuity claim.

The public activation records and their signatures remain valid as historical evidence. They do not establish that the corresponding private keys remain available for a new signing event. Because the old root private key is also unavailable, a new cryptographically signed revocation under that root cannot be issued from this workspace.

Accordingly:

```text
IA-D-R7-CAM-001-AUTH-20260821-001

Historical public record:
RETAINED FOR PROVENANCE

Authority for a new attempt:
WITHDRAWN / NOT USABLE
```

## Independent control result

```text
Independent controls     83
PASS                     80
FAIL                      3
```

The three failed controls are three expressions of the same custody failure:

1. the signed custody attestation is no longer operationally supportable;
2. the approved signer private key is unavailable; and
3. no accessible candidate key matches the approved signer public identity.

## Required remediation

There are two valid paths.

### Path A — genuine key recovery

Restore the original authority-root and authorization-signer private keys from a bona fide independently controlled backup. Before signing:

- derive each public key from the recovered private key;
- prove exact equality with the approved public-key identities;
- revalidate custody and access controls;
- confirm the activation and revocation state remain valid; and
- sign the unchanged request before **August 28, 2026 at 18:54 UTC**.

### Path B — authority rotation

When no genuine backup exists:

- create new root and signer keys in durable independent custody;
- issue a new activation decision, custody attestation, revocation record, and protected pin;
- administratively retire the former activation;
- rebuild the source against the new protected pin;
- regenerate both canonical authorization payloads; and
- submit a new detached-signing request.

Future private-key custody must survive conversation and container boundaries—for example, a named offline custodian, HSM, KMS, or controlled encrypted key store—not an ephemeral chat workspace.

## Exact permitted next action

> **Do not execute either no-database case and do not use the old activation for a new attempt.** First restore the exact original root and signer private keys from a genuine independent backup and prove their public-key matches. If no such backup exists, rotate the external authority through durable independent custody, issue a new activation and protected pin, rebuild the affected source identities, and submit a new canonical signing request. Preserve the current request and activation records as failed-custody provenance. PostgreSQL, real `psql`, checkpoint/report database execution, recovery, and every Campaign stage remain prohibited.

# Independent Audit return package

```text
Package
MSBF_IA_CAMPAIGN_R5_DETACHED_SIGNING_CUSTODY_HOLD_R9_20260821.zip

Bytes
532,846

SHA-256
084d66d07ee16dd8fe79590814808d296b82446748580fb499c6b2d6f4c06e1e

ZIP entries
24

Payload manifest rows
21

ZIP validation
PASS
```

## Primary deliverables

Download the complete custody-hold audit package (historical reference: `sandbox:[session]/MSBF_IA_CAMPAIGN_R5_DETACHED_SIGNING_CUSTODY_HOLD_R9_20260821.zip`; referenced bytes not established here)

Download the SHA-256 sidecar (historical reference: `sandbox:[session]/MSBF_IA_CAMPAIGN_R5_DETACHED_SIGNING_CUSTODY_HOLD_R9_20260821.zip.sha256`; referenced bytes not established here)

Open the ZIP-validation report (historical reference: `sandbox:[session]/MSBF_IA_CAMPAIGN_R5_DETACHED_SIGNING_CUSTODY_HOLD_R9_20260821_ZIP_VALIDATION_REPORT.md`; referenced bytes not established here)

Open the formal detached-signing custody audit report (historical reference: `sandbox:[session]/MSBF_IA_CAMPAIGN_R5_DETACHED_SIGNING_CUSTODY_HOLD_R9_20260821/01_IA_WP3G_CAMPAIGN_R5_DETACHED_SIGNING_CUSTODY_AUDIT_REPORT.md`; referenced bytes not established here)

Open the machine-readable audit summary (historical reference: `sandbox:[session]/MSBF_IA_CAMPAIGN_R5_DETACHED_SIGNING_CUSTODY_HOLD_R9_20260821/02_IA_WP3G_MACHINE_SUMMARY.json`; referenced bytes not established here)

Open the custody recovery or authority-rotation prompt (historical reference: `sandbox:[session]/MSBF_IA_CAMPAIGN_R5_DETACHED_SIGNING_CUSTODY_HOLD_R9_20260821/03_CAMPAIGN_EXTERNAL_AUTHORITY_CUSTODY_RECOVERY_OR_ROTATION_PROMPT.md`; referenced bytes not established here)

Open the exact next-action record (historical reference: `sandbox:[session]/MSBF_IA_CAMPAIGN_R5_DETACHED_SIGNING_CUSTODY_HOLD_R9_20260821/06_EXACT_NEXT_ACTION.md`; referenced bytes not established here)

## Independent evidence

Open the complete 83-control results (historical reference: `sandbox:[session]/MSBF_IA_CAMPAIGN_R5_DETACHED_SIGNING_CUSTODY_HOLD_R9_20260821/evidence/SIGNING_REQUEST_AUDIT_CONTROL_RESULTS.csv`; referenced bytes not established here)

Open the custody-search results (historical reference: `sandbox:[session]/MSBF_IA_CAMPAIGN_R5_DETACHED_SIGNING_CUSTODY_HOLD_R9_20260821/evidence/SIGNER_CUSTODY_SEARCH_RESULTS.json`; referenced bytes not established here)

Open the mismatched-key negative test (historical reference: `sandbox:[session]/MSBF_IA_CAMPAIGN_R5_DETACHED_SIGNING_CUSTODY_HOLD_R9_20260821/evidence/MISMATCHED_KEY_NEGATIVE_TEST.txt`; referenced bytes not established here)

Open the authority decision and supersession register (historical reference: `sandbox:[session]/MSBF_IA_CAMPAIGN_R5_DETACHED_SIGNING_CUSTODY_HOLD_R9_20260821/04_AUTHORITY_DECISION_AND_SUPERSESSION_REGISTER.csv`; referenced bytes not established here)

Open the updated integrated dashboard (historical reference: `sandbox:[session]/MSBF_IA_CAMPAIGN_R5_DETACHED_SIGNING_CUSTODY_HOLD_R9_20260821/INDEPENDENT_AUDIT_STATUS_DASHBOARD.md`; referenced bytes not established here)
<!-- END_SOURCE_MESSAGE -->
