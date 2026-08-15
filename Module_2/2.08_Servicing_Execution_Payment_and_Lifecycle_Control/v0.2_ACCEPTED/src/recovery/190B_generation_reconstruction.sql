/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.8 — Servicing Execution Simulation, Payment Processing
             & Account Lifecycle Control

Program     : 190B_msbf_m2_8_generation_reconciliation_reconstructed_v0_2.sql
Version     : v0.2

Purpose
-------
Reconstruct the committed Program 190 checkpoint without writes when a
DBeaver result tab is lost or suppressed.

Stage boundary
--------------
All servicing, payment, processor-reference, return, retry, and lifecycle
outputs are deterministic synthetic evidence. No real funds move; no bank or
routing data is used; no ACH/network transmission, external processor call,
merchant contact, write-off/collection/legal execution, external notice, or
production adverse action occurs.

Required result
---------------
generation_reconstruction_status = PASS.
============================================================================ */

WITH r AS(SELECT run_id,run_status FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1),g AS(SELECT * FROM msbf_ctl.m2_8_servicing_execution_contract_registry WHERE module1_run_id=(SELECT run_id FROM r)),p AS(SELECT
 (SELECT count(*) FROM msbf_m2.servicing_execution_source_snapshot WHERE module1_run_id=(SELECT run_id FROM r)) source_rows,
 (SELECT count(*) FROM msbf_m2.application_servicing_execution_snapshot WHERE module1_run_id=(SELECT run_id FROM r)) execution_rows,
 (SELECT count(*) FROM msbf_m2.synthetic_payment_processing_event WHERE module1_run_id=(SELECT run_id FROM r)) payment_event_rows,
 (SELECT count(*) FROM msbf_m2.account_lifecycle_transition_snapshot WHERE module1_run_id=(SELECT run_id FROM r)) lifecycle_transition_rows,
 (SELECT count(*) FROM msbf_m2.servicing_execution_portfolio_summary WHERE module1_run_id=(SELECT run_id FROM r)) portfolio_rows,
 (SELECT count(*) FROM msbf_m2.application_servicing_execution_latest WHERE module1_run_id=(SELECT run_id FROM r)) latest_rows,
 (SELECT count(*) FROM msbf_m2.application_servicing_execution_archive WHERE module1_run_id=(SELECT run_id FROM r)) archive_rows,
 (SELECT count(*) FROM msbf_m2.v_m2_8_matched_scenario_comparison WHERE module1_run_id=(SELECT run_id FROM r)) comparison_rows,
 (SELECT canonical_entities FROM msbf_m2.v_m2_8_canonical_hash WHERE module1_run_id=(SELECT run_id FROM r)) canonical_entities,
 (SELECT combined_set_hash FROM msbf_m2.v_m2_8_canonical_hash WHERE module1_run_id=(SELECT run_id FROM r)) physical_combined_set_hash,
 (SELECT count(*) FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM r) AND evidence_code LIKE 'M2_8_%' AND evidence_code NOT LIKE 'M2_8_POS_%' AND evidence_code NOT LIKE 'M2_8_NEG_%' AND evidence_code<>'M2_8_ACCEPTANCE_SUMMARY') generation_evidence_rows,
 (SELECT count(*) FROM msbf_m2.v_m2_8_matched_scenario_comparison WHERE module1_run_id=(SELECT run_id FROM r) AND (stress_processing_permission_improvement_flag OR stress_priority_improvement_flag OR stress_exposure_improvement_flag)) stress_improvement_rows)
SELECT r.run_status,g.contract_status,p.*,g.no_processing_required_rows,g.temporary_processing_rows,g.review_hold_rows,g.settled_event_rows,g.returned_event_rows,g.retry_event_rows,g.initial_transition_rows,g.payment_transition_rows,g.checkpoint_transition_rows,g.processing_authorized_amount,g.review_hold_amount,g.scheduled_payment_amount,g.processed_payment_amount,g.returned_payment_amount,g.retry_payment_amount,g.ending_simulated_exposure_amount,g.policy_set_hash,g.outcome_set_hash,g.action_set_hash,g.lifecycle_state_set_hash,g.reason_set_hash,g.source_set_hash,g.execution_set_hash,g.payment_event_set_hash,g.lifecycle_transition_set_hash,g.portfolio_summary_set_hash,g.latest_set_hash,g.archive_set_hash,g.contract_set_hash,g.combined_set_hash,
 CASE WHEN r.run_status IN ('M2_8_GENERATED','M2_8_VALIDATED','M2_8_ACCEPTED') AND g.contract_status IN ('GENERATED','VALIDATED','ACCEPTED') AND p.source_rows=59 AND p.execution_rows=59 AND p.payment_event_rows=7 AND p.lifecycle_transition_rows=67 AND p.portfolio_rows=2 AND p.latest_rows=59 AND p.archive_rows=59 AND p.comparison_rows=15 AND p.canonical_entities=367 AND p.generation_evidence_rows=24 AND p.stress_improvement_rows=0 AND g.no_processing_required_rows=57 AND g.temporary_processing_rows=1 AND g.review_hold_rows=1 AND g.settled_event_rows=5 AND g.returned_event_rows=1 AND g.retry_event_rows=1 AND g.initial_transition_rows=59 AND g.payment_transition_rows=7 AND g.checkpoint_transition_rows=1 AND g.processing_authorized_amount=518.04 AND g.review_hold_amount=461.69 AND g.scheduled_payment_amount=194.25 AND g.processed_payment_amount=194.25 AND g.returned_payment_amount=27.75 AND g.retry_payment_amount=27.75 AND g.ending_simulated_exposure_amount=785.48 AND g.combined_set_hash IS NOT DISTINCT FROM p.physical_combined_set_hash THEN 'PASS' ELSE 'FAIL' END generation_reconstruction_status
FROM r CROSS JOIN g CROSS JOIN p;
