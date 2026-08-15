# M2.12 Live-Execution Validation and Hotfix History

This chronology is derived from the controlled execution conversation and the physical source/evidence artifacts included in this package. It is an audit-navigation aid, not a substitute for original console transcripts.

Every reported execution anomaly was handled fail-closed: the operator stopped and issued `ROLLBACK`, except the post-commit Program 220 export anomaly and the separately authorized Recovery 222A sequence correction.

| Seq. | Date | Program | Attempt | Code/result | Outcome and correction | Classification |
|---:|---|---|---|---|---|---|
| 1 | 2026-08-10 | 220 | Original/R1 | `42803` | Correlated catalog subquery referenced ungrouped outer c.oid in aggregate postflight. HF1 rewrote seven view-dependency checks. | **SUPERSEDED** |
| 2 | 2026-08-10 | 220 | HF1 | `P0001` | P220_PF_0064 timestamp type comparison used alias timestamptz instead of catalog display timestamp with time zone. HF2 corrected 14 timestamp postflights. | **SUPERSEDED** |
| 3 | 2026-08-10 | 220 | HF2 | `42883` | name[] compared with text[] in attname array aggregates. HF3 cast 68 attname expressions inside aggregates. | **SUPERSEDED** |
| 4 | 2026-08-10 | 220 | HF3 | `P0001` | Constraint structural postflight expected NOT connoinherit for PK/UNIQUE/FK. HF4 corrected all 23 affected constraints and completed full review. | **SUPERSEDED** |
| 5 | 2026-08-10 | 220 | HF4 | `PASS` | Program 220 installed 21 top-level objects and reached READY_FOR_PROGRAM_221. Result exported from fetched rows; later temp-table requery 42P01 treated as export anomaly only. | **EXECUTED_SUCCESS** |
| 6 | 2026-08-11 | 221 | Original | `P0001` | G3 gate helper was unscoped and returned 34 rows instead of one. HF5 scoped gate and corrected registry mappings. | **SUPERSEDED** |
| 7 | 2026-08-11 | 221 | HF5 | `P0001` | Source graph mismatch, including M1.3 accepted gate JSON hash extraction defect. HF6 extracted application_set_hash and hardened all 19 edges. | **SUPERSEDED** |
| 8 | 2026-08-11 | 221 | HF6 | `PASS` | 48/48 assertions, 19 edges, 13 components, 12 nodes, 72 evidence rows, 20 capabilities. Program 222 held pending correction. | **EXECUTED_SUCCESS** |
| 9 | 2026-08-11 | 222 | HF7 | `P0001` | Stage-boundary certification failed nodes 1 and 4 due wrong physical evidence sources. HF8 rebuilt M1.17 and M2.3 special controls. | **SUPERSEDED** |
| 10 | 2026-08-11 | 222 | HF8 | `42702` | Ambiguous module1_run_id in multi-source hash-stage query. HF9 qualified aliases, fixed grouping/literals and hash preimages. | **SUPERSEDED** |
| 11 | 2026-08-11 | 222 | HF9 precheck | `P0001` | Archive sequence showed 1\|true after rolled-back HF8 attempt; sequence advancement was nontransactional. Directed Recovery 222A selected from exact state. | **RECOVERY_REQUIRED** |
| 12 | 2026-08-11 | 222A | R1 | `PASS` | Precheck matched recovery decision, archive/registry sequences restored to pristine pre-222 state, postcheck passed. Only approved sequence setval operations executed. | **EXECUTED_SUCCESS** |
| 13 | 2026-08-11 | 222 | HF9 | `PASS` | Generated 9 families, 134 entities, 24 generation rows; lifecycle M2_12_GENERATED/GENERATED. READY_FOR_PROGRAM_223. | **EXECUTED_SUCCESS** |
| 14 | 2026-08-11 | 223 | HF10 | `42601` | psql \set meta-command rejected by DBeaver/PostgreSQL server. HF11 removed client meta-command. | **SUPERSEDED** |
| 15 | 2026-08-11 | 223 | HF11 | `P0001` | 128 controls evaluated but two failed: G3 archive payload parity and M2.11 PARTIAL posture. HF12 corrected controls 009 and 114 and added complete diagnostic. | **SUPERSEDED** |
| 16 | 2026-08-11 | 223 | HF12 | `PASS` | 128/128 positive controls persisted; lifecycle M2_12_VALIDATED/VALIDATED. Zero negative or acceptance rows. | **EXECUTED_SUCCESS** |
| 17 | 2026-08-11 | 224 | HF13 diagnostic | `42702` | Control 003 used ambiguous contract_status in joined fixture. HF14 qualified joined fixture columns and hardened same-class controls. | **SUPERSEDED** |
| 18 | 2026-08-11 | 224 | HF14 | `PASS` | 20/20 isolated negative controls persisted; lifecycle remained VALIDATED. All before/after fingerprints exact. | **EXECUTED_SUCCESS** |
| 19 | 2026-08-11 | 225 | HF15 verifier | `P0001` | Sixteen negative evidence rows falsely failed because empty constraint field encoding P0001\|\|message was expected as two segments. HF16 corrected encoding verifier. | **SUPERSEDED** |
| 20 | 2026-08-11 | 225 | HF15 diagnostic | `42702` | Ambiguous contract_version in joined requirement grain checks. HF17 qualified Requirements 017-021 in diagnostic and main. | **SUPERSEDED** |
| 21 | 2026-08-11 | 225 | HF17 diagnostic | `42703` | Requirement 033 referenced nonexistent m1_17_contract_row_hash view column. HF19 used physical m2_1_source_g2_combined_hash lineage. | **SUPERSEDED** |
| 22 | 2026-08-11 | 225 | HF19 diagnostic | `42601` | Requirement 044 had an unbalanced parenthesis and failed near semicolon. HF20 corrected parser defect in diagnostic and main. | **SUPERSEDED** |
| 23 | 2026-08-11 | 225 | HF20 diagnostic | `CLIENT_FREEZE` | DBeaver froze rendering 47 intermediate function-result tabs. Compact HF20C suppressed intermediate tabs. | **SUPERSEDED** |
| 24 | 2026-08-11 | 225 | HF20C | `42703` | Final projection referenced authoritative_source instead of physical authority_trace. HF20C2 corrected final projections. | **SUPERSEDED** |
| 25 | 2026-08-11 | 225 | HF20C2 | `DIAGNOSTIC_FAIL` | Requirements 027 and 045 failed: text evidence stored in metric_value_text and latest-row hash preimage retained row_hash. HF23 corrected both requirements in compact diagnostic and main. | **SUPERSEDED** |
| 26 | 2026-08-11 | 225 | HF23 | `PASS` | 47/47 pre-write diagnostic and 48/48 final requirements; lifecycle M2_12_ACCEPTED/ACCEPTED. One G3 gate row and one acceptance evidence row; no production/Module 3 authority. | **EXECUTED_SUCCESS** |
| 27 | 2026-08-11 | 226 | HF24 | `PASS` | Read-only 92-field master report emitted with exact accepted lifecycle, counts, hashes, zero findings. No persistent mutation. | **EXECUTED_SUCCESS** |
| 28 | 2026-08-12 | 227 | HF25 | `P0001` | Result Set 10 content gate treated valid COMPLETE/PARTIAL/BLOCKED domain as non-PASS and produced rs10_fail=3. HF26 corrected RS10 content gate and proactively hardened RS17. | **SUPERSEDED** |
| 29 | 2026-08-12 | 227 | HF26 narrow diagnostic | `25006` | Diagnostic declared SQL-level READ ONLY then attempted temporary CTAS. HF27 allowed temporary writes while remaining persistent-state read-only. | **SUPERSEDED** |
| 30 | 2026-08-12 | 227 | HF27 diagnostic + HF26 main | `PASS` | Application summary diagnostic passed and Program 227 produced 24 governed result sets. Post-chain evidence capture completed; independent audit required. | **EXECUTED_SUCCESS** |

| 31 | 2026-08-12 | AUDIT_HANDOFF | Submission R1 review | `EVIDENCE_GAP` | Program 227 Result Set 11 was physically limited to 200 rows although governed cardinality was 1,500. A corrected export was supplied. | **RESOLVED_POST_SUBMISSION** |
| 32 | 2026-08-12 | AUDIT_HANDOFF | Submission R2 | `PASS` | R2 promotes the complete 1,500-row export, preserves the old bytes and original raw ZIP, and reconciles all 24 Program 227 cardinalities. Runtime transcript/process evidence remains open. | **AUDIT_SUBMISSION_CURRENT** |
