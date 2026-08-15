/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.5 — Daily Remittance, Exposure & Portfolio Monitoring

Program     : 167_msbf_m2_5_daily_remittance_exposure_validation_v0_2.sql
Version     : v0.2R2

Revision v0.2R2
----------------
Corrects M2_5_POS_082_LATEST_ARCHIVE_REPRODUCTION so the immutable archive
payload is compared with the target-typed latest contract payload, excluding
the system-managed persistent `created_at` timestamp. No generated row, hash,
count, policy, outcome, source contract, or business methodology changes.

Purpose
-------
Perform 120 read-only positive controls across lifecycle, policy boundaries,
accepted M2.4 and M1.6 lineage, replay completeness, daily remittance and
exposure arithmetic, status/alert identities, stress status flooring,
latest/archive reproduction, portfolio aggregation, hashes, evidence and
acceptance readiness.

Output
------
A session-preserved 120-row validation table.

Required result
---------------
120 / 120 PASS and run_status = M2_5_VALIDATED.
============================================================================ */

BEGIN;

SET LOCAL work_mem = '160MB';
SET LOCAL statement_timeout = '45min';
SET LOCAL jit = off;

DROP TABLE IF EXISTS _m2_5_validation;

CREATE TEMP TABLE _m2_5_validation
(
    evidence_code      text PRIMARY KEY,
    metric_name        text NOT NULL,
    observed_value     text,
    threshold_value    text,
    status             text NOT NULL,
    interpretation     text NOT NULL
)
ON COMMIT PRESERVE ROWS;

DROP TABLE IF EXISTS _m2_5_vctx;

CREATE TEMP TABLE _m2_5_vctx
ON COMMIT DROP
AS
SELECT run_id, run_status
FROM msbf_ctl.run_registry
WHERE run_code = 'M1_V0_2_BASELINE_BUILD'
  AND run_version = 1;

DO $m2_5_validation_ready$
BEGIN
    PERFORM msbf_ctl.m2_5_assert_validation_ready
    (
        (SELECT run_id FROM _m2_5_vctx)
    );
END;
$m2_5_validation_ready$;

CREATE OR REPLACE FUNCTION pg_temp.m2_5_add_check
(
    p_code text,
    p_metric text,
    p_observed text,
    p_threshold text,
    p_pass boolean,
    p_interpretation text
)
RETURNS void
LANGUAGE plpgsql
AS $function$
BEGIN
    INSERT INTO _m2_5_validation
    (
        evidence_code,
        metric_name,
        observed_value,
        threshold_value,
        status,
        interpretation
    )
    VALUES
    (
        p_code,
        p_metric,
        p_observed,
        p_threshold,
        CASE WHEN p_pass THEN 'PASS' ELSE 'FAIL' END,
        p_interpretation
    );
END;
$function$;

DO $m2_5_positive_controls$
BEGIN
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_001_RUN_STATUS',
        'RUN_STATUS',
        ((SELECT run_status FROM _m2_5_vctx))::text,
        'M2_5_GENERATED',
        coalesce(((SELECT run_status='M2_5_GENERATED' FROM _m2_5_vctx)), FALSE),
        'Validation begins from generated state.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_002_POLICY_APPROVED_BOUNDARIES',
        'POLICY_APPROVED_BOUNDARIES',
        ((SELECT policy_status||'|'||synthetic_data_only_flag||'|'||no_real_debit_instruction_flag||'|'||no_external_notice_generation_flag||'|'||no_production_adverse_action_notice_flag||'|'||no_write_off_or_restructure_action_flag||'|'||monitoring_only_no_servicing_action_flag FROM msbf_ctl.m2_5_policy_profile WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx)))::text,
        'APPROVED|true|true|true|true|true|true',
        coalesce(((SELECT policy_status='APPROVED' AND synthetic_data_only_flag AND no_real_debit_instruction_flag AND no_external_notice_generation_flag AND no_production_adverse_action_notice_flag AND no_write_off_or_restructure_action_flag AND monitoring_only_no_servicing_action_flag FROM msbf_ctl.m2_5_policy_profile WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx))), FALSE),
        'Policy and monitoring-only boundaries are approved.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_003_METHOD_CONTRACT_IDENTITY',
        'METHOD_CONTRACT_IDENTITY',
        ((SELECT methodology_version||'|'||contract_code||'|'||contract_version||'|'||schema_version FROM msbf_ctl.m2_5_policy_profile WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx)))::text,
        'M2_5_METHOD_V1|M2_DAILY_REMITTANCE_EXPOSURE_MONITORING_CONSUMPTION|1|M2_5_DAILY_REMITTANCE_EXPOSURE_SCHEMA_V1',
        coalesce(((SELECT methodology_version='M2_5_METHOD_V1' AND contract_code='M2_DAILY_REMITTANCE_EXPOSURE_MONITORING_CONSUMPTION' AND contract_version=1 AND schema_version='M2_5_DAILY_REMITTANCE_EXPOSURE_SCHEMA_V1' FROM msbf_ctl.m2_5_policy_profile WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx))), FALSE),
        'Method and contract identity are exact.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_004_SOURCE_M2_4_HASH',
        'SOURCE_M2_4_HASH',
        ((SELECT source_m2_4_combined_hash FROM msbf_ctl.m2_5_policy_profile WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx)))::text,
        '117450a3eea7bb3d3c74d18cc3c8e96a',
        coalesce(((SELECT source_m2_4_combined_hash='117450a3eea7bb3d3c74d18cc3c8e96a' FROM msbf_ctl.m2_5_policy_profile WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx))), FALSE),
        'Accepted M2.4 combined hash is preserved.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_005_SOURCE_M2_4_REGISTRY',
        'SOURCE_M2_4_REGISTRY',
        ((SELECT contract_status||'|'||portfolio_rows||'|'||combined_set_hash FROM msbf_ctl.m2_4_portfolio_activation_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx)))::text,
        'ACCEPTED|59|accepted hash',
        coalesce(((SELECT contract_status='ACCEPTED' AND contract_code='M2_PORTFOLIO_ACTIVATION_CONSUMPTION' AND contract_version=1 AND schema_version='M2_4_PORTFOLIO_ACTIVATION_SCHEMA_V1' AND portfolio_rows=59 AND combined_set_hash='117450a3eea7bb3d3c74d18cc3c8e96a' FROM msbf_ctl.m2_4_portfolio_activation_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx))), FALSE),
        'Accepted M2.4 portfolio activation registry is exact.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_006_SOURCE_M2_4_GATE',
        'SOURCE_M2_4_GATE',
        ((SELECT result_status FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM _m2_5_vctx) AND gate_id='M2_4_BOOKING_FUNDING_PORTFOLIO_ACTIVATION' AND review_version=1))::text,
        'PASS',
        coalesce(((SELECT result_status='PASS' FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM _m2_5_vctx) AND gate_id='M2_4_BOOKING_FUNDING_PORTFOLIO_ACTIVATION' AND review_version=1)), FALSE),
        'M2.4 acceptance gate is PASS.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_007_SOURCE_M1_6_GATE',
        'SOURCE_M1_6_GATE',
        ((SELECT result_status FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM _m2_5_vctx) AND gate_id='M1_6_MATCHED_SCENARIO_OVERLAYS' ORDER BY review_version DESC LIMIT 1))::text,
        'PASS',
        coalesce(((SELECT result_status='PASS' FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM _m2_5_vctx) AND gate_id='M1_6_MATCHED_SCENARIO_OVERLAYS' ORDER BY review_version DESC LIMIT 1)), FALSE),
        'M1.6 matched scenario history gate is PASS.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_008_SOURCE_M1_6_HASH',
        'SOURCE_M1_6_HASH',
        ((SELECT source_m1_6_combined_hash FROM msbf_ctl.m2_5_policy_profile WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx)))::text,
        'accepted M1.6 hash',
        coalesce(((SELECT policy.source_m1_6_combined_hash IS NOT DISTINCT FROM evidence.metric_value_text FROM msbf_ctl.m2_5_policy_profile AS policy JOIN msbf_ctl.run_evidence AS evidence ON evidence.run_id=policy.module1_run_id AND evidence.evidence_code='M1_6_COMBINED_SET_HASH' AND evidence.segment_key='PORTFOLIO' AND evidence.status='PASS' WHERE policy.module1_run_id=(SELECT run_id FROM _m2_5_vctx))), FALSE),
        'Policy M1.6 hash matches accepted evidence.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_009_CONFIGURATION_HASH',
        'CONFIGURATION_HASH',
        ((SELECT configuration_hash FROM msbf_ctl.m2_5_policy_profile WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx)))::text,
        'physical payload hash',
        coalesce(((SELECT configuration_hash=msbf_ctl.m2_5_hash_jsonb(configuration_payload) FROM msbf_ctl.m2_5_policy_profile WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx))), FALSE),
        'Configuration hash reconstructs from policy payload.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_010_POLICY_ROW_HASH',
        'POLICY_ROW_HASH_MISMATCHES',
        ((SELECT count(*) FROM msbf_ctl.m2_5_policy_profile AS p WHERE p.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND p.row_hash IS DISTINCT FROM msbf_ctl.m2_5_hash_jsonb(to_jsonb(p)-'row_hash'-'created_at'-'updated_at')))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_ctl.m2_5_policy_profile AS p WHERE p.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND p.row_hash IS DISTINCT FROM msbf_ctl.m2_5_hash_jsonb(to_jsonb(p)-'row_hash'-'created_at'-'updated_at'))), FALSE),
        'Policy row hash reconstructs physically.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_011_ACCEPTANCE_GATE_CATALOG',
        'ACCEPTANCE_GATE_CATALOG',
        ((SELECT count(*) FROM msbf_ref.acceptance_gate_catalog WHERE gate_id='M2_5_DAILY_REMITTANCE_EXPOSURE_PORTFOLIO_MONITORING' AND active_flag))::text,
        '1',
        coalesce(((SELECT count(*)=1 FROM msbf_ref.acceptance_gate_catalog WHERE gate_id='M2_5_DAILY_REMITTANCE_EXPOSURE_PORTFOLIO_MONITORING' AND active_flag)), FALSE),
        'M2.5 gate is registered.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_012_STATUS_DEFINITION_COUNT',
        'STATUS_DEFINITION_COUNT',
        ((SELECT count(*) FROM msbf_m2.portfolio_monitoring_status_definition WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx)))::text,
        '6',
        coalesce(((SELECT count(*)=6 FROM msbf_m2.portfolio_monitoring_status_definition WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx))), FALSE),
        'Status Definition Count matches governance.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_013_ALERT_DEFINITION_COUNT',
        'ALERT_DEFINITION_COUNT',
        ((SELECT count(*) FROM msbf_m2.portfolio_monitoring_alert_definition WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx)))::text,
        '7',
        coalesce(((SELECT count(*)=7 FROM msbf_m2.portfolio_monitoring_alert_definition WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx))), FALSE),
        'Alert Definition Count matches governance.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_014_REASON_DEFINITION_COUNT',
        'REASON_DEFINITION_COUNT',
        ((SELECT count(*) FROM msbf_m2.portfolio_monitoring_reason_definition WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx)))::text,
        '24',
        coalesce(((SELECT count(*)=24 FROM msbf_m2.portfolio_monitoring_reason_definition WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx))), FALSE),
        'Reason Definition Count matches governance.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_015_STATUS_PHYSICAL_HASH',
        'STATUS_HASH_MISMATCHES',
        ((SELECT count(*) FROM msbf_m2.portfolio_monitoring_status_definition AS s WHERE s.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND s.row_hash IS DISTINCT FROM msbf_ctl.m2_5_hash_jsonb(to_jsonb(s)-'row_hash'-'created_at')))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.portfolio_monitoring_status_definition AS s WHERE s.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND s.row_hash IS DISTINCT FROM msbf_ctl.m2_5_hash_jsonb(to_jsonb(s)-'row_hash'-'created_at'))), FALSE),
        'Status-definition hashes reconstruct.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_016_ALERT_PHYSICAL_HASH',
        'ALERT_HASH_MISMATCHES',
        ((SELECT count(*) FROM msbf_m2.portfolio_monitoring_alert_definition AS a WHERE a.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND a.row_hash IS DISTINCT FROM msbf_ctl.m2_5_hash_jsonb(to_jsonb(a)-'row_hash'-'created_at')))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.portfolio_monitoring_alert_definition AS a WHERE a.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND a.row_hash IS DISTINCT FROM msbf_ctl.m2_5_hash_jsonb(to_jsonb(a)-'row_hash'-'created_at'))), FALSE),
        'Alert-definition hashes reconstruct.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_017_REASON_PHYSICAL_HASH',
        'REASON_HASH_MISMATCHES',
        ((SELECT count(*) FROM msbf_m2.portfolio_monitoring_reason_definition AS r WHERE r.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND r.row_hash IS DISTINCT FROM msbf_ctl.m2_5_hash_jsonb(to_jsonb(r)-'row_hash'-'created_at')))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.portfolio_monitoring_reason_definition AS r WHERE r.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND r.row_hash IS DISTINCT FROM msbf_ctl.m2_5_hash_jsonb(to_jsonb(r)-'row_hash'-'created_at'))), FALSE),
        'Reason-definition hashes reconstruct.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_018_REASON_BOUNDARY_FLAGS',
        'REASON_BOUNDARY_FLAG_ROWS',
        ((SELECT count(*) FROM msbf_m2.portfolio_monitoring_reason_definition WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND (production_adverse_action_notice_flag OR servicing_action_authorized_flag)))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.portfolio_monitoring_reason_definition WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND (production_adverse_action_notice_flag OR servicing_action_authorized_flag))), FALSE),
        'Reasons authorize neither servicing action nor production notice.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_019_REGISTRY_ROW_COUNT',
        'REGISTRY_ROW_COUNT',
        ((SELECT count(*) FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx)))::text,
        '1',
        coalesce(((SELECT count(*)=1 FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx))), FALSE),
        'Exactly one registry row exists.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_020_REGISTRY_STATUS',
        'REGISTRY_STATUS',
        ((SELECT contract_status FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx)))::text,
        'GENERATED',
        coalesce(((SELECT contract_status='GENERATED' FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx))), FALSE),
        'Registry is generated before validation.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_021_REGISTRY_COUNTS',
        'REGISTRY_COUNTS',
        ((SELECT source_rows||'|'||daily_rows||'|'||latest_rows||'|'||archive_rows||'|'||portfolio_daily_rows||'|'||comparison_rows||'|'||canonical_entities FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx)))::text,
        '59|7080|59|59|240|15|7536',
        coalesce(((SELECT source_rows=59 AND daily_rows=7080 AND latest_rows=59 AND archive_rows=59 AND portfolio_daily_rows=240 AND comparison_rows=15 AND canonical_entities=7536 FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx))), FALSE),
        'Registry counts match the M2.5 contract.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_022_SOURCE_ROWS',
        'SOURCE_ROWS',
        ((SELECT count(*) FROM msbf_m2.advance_monitoring_source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx)))::text,
        '59',
        coalesce(((SELECT count(*)=59 FROM msbf_m2.advance_monitoring_source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx))), FALSE),
        'Source Rows count matches expected.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_029_DAILY_ROWS',
        'DAILY_ROWS',
        ((SELECT count(*) FROM msbf_m2.advance_daily_remittance_monitoring WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx)))::text,
        '7080',
        coalesce(((SELECT count(*)=7080 FROM msbf_m2.advance_daily_remittance_monitoring WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx))), FALSE),
        'Daily Rows count matches expected.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_070_LATEST_ROWS',
        'LATEST_ROWS',
        ((SELECT count(*) FROM msbf_m2.advance_portfolio_monitoring_latest WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx)))::text,
        '59',
        coalesce(((SELECT count(*)=59 FROM msbf_m2.advance_portfolio_monitoring_latest WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx))), FALSE),
        'Latest Rows count matches expected.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_079_ARCHIVE_ROWS',
        'ARCHIVE_ROWS',
        ((SELECT count(*) FROM msbf_m2.advance_portfolio_monitoring_archive WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx)))::text,
        '59',
        coalesce(((SELECT count(*)=59 FROM msbf_m2.advance_portfolio_monitoring_archive WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx))), FALSE),
        'Archive Rows count matches expected.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_083_PORTFOLIO_DAILY_ROWS',
        'PORTFOLIO_DAILY_ROWS',
        ((SELECT count(*) FROM msbf_m2.portfolio_daily_monitoring_summary WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx)))::text,
        '240',
        coalesce(((SELECT count(*)=240 FROM msbf_m2.portfolio_daily_monitoring_summary WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx))), FALSE),
        'Portfolio Daily Rows count matches expected.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_023_BASELINE_SOURCE_ROWS',
        'BASELINE_SOURCE_ROWS',
        ((SELECT count(*) FROM msbf_m2.advance_monitoring_source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND scenario_code='BASELINE'))::text,
        '44',
        coalesce(((SELECT count(*)=44 FROM msbf_m2.advance_monitoring_source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND scenario_code='BASELINE')), FALSE),
        'Baseline source count is 44.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_024_STRESS_SOURCE_ROWS',
        'STRESS_SOURCE_ROWS',
        ((SELECT count(*) FROM msbf_m2.advance_monitoring_source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND scenario_code='RECESSION_ENERGY'))::text,
        '15',
        coalesce(((SELECT count(*)=15 FROM msbf_m2.advance_monitoring_source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND scenario_code='RECESSION_ENERGY')), FALSE),
        'Stress source count is 15.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_025_SOURCE_GRAIN',
        'SOURCE_DUPLICATE_GRAIN_ROWS',
        ((SELECT count(*)-count(DISTINCT scenario_id::text||'|'||merchant_application_id) FROM msbf_m2.advance_monitoring_source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx)))::text,
        '0',
        coalesce(((SELECT count(*)=count(DISTINCT scenario_id::text||'|'||merchant_application_id) FROM msbf_m2.advance_monitoring_source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx))), FALSE),
        'Source grain is unique.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_026_SOURCE_PHYSICAL_HASH',
        'SOURCE_HASH_MISMATCHES',
        ((SELECT count(*) FROM msbf_m2.advance_monitoring_source_snapshot AS s WHERE s.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND s.row_hash IS DISTINCT FROM msbf_ctl.m2_5_hash_jsonb(to_jsonb(s)-'row_hash'-'created_at')))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.advance_monitoring_source_snapshot AS s WHERE s.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND s.row_hash IS DISTINCT FROM msbf_ctl.m2_5_hash_jsonb(to_jsonb(s)-'row_hash'-'created_at'))), FALSE),
        'Source hashes reconstruct.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_027_SOURCE_M2_4_LINEAGE',
        'SOURCE_M2_4_LINEAGE_MISMATCHES',
        ((SELECT count(*) FROM msbf_m2.advance_monitoring_source_snapshot AS s JOIN msbf_m2.application_booking_funding_activation_latest AS a ON a.module1_run_id=s.module1_run_id AND a.scenario_id=s.scenario_id AND a.merchant_application_id=s.merchant_application_id WHERE s.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND s.source_m2_4_contract_row_hash IS DISTINCT FROM a.contract_row_hash))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.advance_monitoring_source_snapshot AS s JOIN msbf_m2.application_booking_funding_activation_latest AS a ON a.module1_run_id=s.module1_run_id AND a.scenario_id=s.scenario_id AND a.merchant_application_id=s.merchant_application_id WHERE s.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND s.source_m2_4_contract_row_hash IS DISTINCT FROM a.contract_row_hash)), FALSE),
        'Source preserves M2.4 latest row identity.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_028_SOURCE_AMOUNT_IDENTITY',
        'SOURCE_AMOUNT_IDENTITY_ERRORS',
        ((SELECT count(*) FROM msbf_m2.advance_monitoring_source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND (funded_amount<=0 OR total_repayment_amount<funded_amount OR initial_exposure_amount IS DISTINCT FROM funded_amount OR remittance_rate NOT BETWEEN 0.05 AND 0.20 OR collection_horizon_days NOT BETWEEN 1 AND 120)))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.advance_monitoring_source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND (funded_amount<=0 OR total_repayment_amount<funded_amount OR initial_exposure_amount IS DISTINCT FROM funded_amount OR remittance_rate NOT BETWEEN 0.05 AND 0.20 OR collection_horizon_days NOT BETWEEN 1 AND 120))), FALSE),
        'Source economics are internally coherent.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_030_BASELINE_DAILY_ROWS',
        'BASELINE_DAILY_ROWS',
        ((SELECT count(*) FROM msbf_m2.advance_daily_remittance_monitoring WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND scenario_code='BASELINE'))::text,
        '5280',
        coalesce(((SELECT count(*)=5280 FROM msbf_m2.advance_daily_remittance_monitoring WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND scenario_code='BASELINE')), FALSE),
        'Baseline daily rows equal 44 x 120.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_031_STRESS_DAILY_ROWS',
        'STRESS_DAILY_ROWS',
        ((SELECT count(*) FROM msbf_m2.advance_daily_remittance_monitoring WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND scenario_code='RECESSION_ENERGY'))::text,
        '1800',
        coalesce(((SELECT count(*)=1800 FROM msbf_m2.advance_daily_remittance_monitoring WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND scenario_code='RECESSION_ENERGY')), FALSE),
        'Stress daily rows equal 15 x 120.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_032_DAILY_GRAIN',
        'DAILY_DUPLICATE_GRAIN_ROWS',
        ((SELECT count(*)-count(DISTINCT scenario_id::text||'|'||merchant_application_id||'|'||monitoring_day_index::text) FROM msbf_m2.advance_daily_remittance_monitoring WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx)))::text,
        '0',
        coalesce(((SELECT count(*)=count(DISTINCT scenario_id::text||'|'||merchant_application_id||'|'||monitoring_day_index::text) FROM msbf_m2.advance_daily_remittance_monitoring WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx))), FALSE),
        'Daily grain is unique.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_033_PER_SOURCE_120_DAYS',
        'PER_SOURCE_DAY_COUNT_ERRORS',
        ((SELECT count(*) FROM (SELECT scenario_id,merchant_application_id,count(*) AS days FROM msbf_m2.advance_daily_remittance_monitoring WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx) GROUP BY scenario_id,merchant_application_id HAVING count(*)<>120) AS errors))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM (SELECT scenario_id,merchant_application_id,count(*) AS days FROM msbf_m2.advance_daily_remittance_monitoring WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx) GROUP BY scenario_id,merchant_application_id HAVING count(*)<>120) AS errors)), FALSE),
        'Every activated advance has 120 monitoring days.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_034_DAY_INDEX_RANGE',
        'DAY_INDEX_RANGE',
        ((SELECT min(monitoring_day_index)||'|'||max(monitoring_day_index) FROM msbf_m2.advance_daily_remittance_monitoring WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx)))::text,
        '1|120',
        coalesce(((SELECT min(monitoring_day_index)=1 AND max(monitoring_day_index)=120 FROM msbf_m2.advance_daily_remittance_monitoring WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx))), FALSE),
        'Daily index spans 1 through 120.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_035_MONITORING_DATE_SEQUENCE',
        'MONITORING_DATE_SEQUENCE_ERRORS',
        ((SELECT count(*) FROM msbf_m2.advance_daily_remittance_monitoring AS d JOIN msbf_m2.advance_monitoring_source_snapshot AS s ON s.module1_run_id=d.module1_run_id AND s.scenario_id=d.scenario_id AND s.merchant_application_id=d.merchant_application_id WHERE d.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND d.monitoring_date IS DISTINCT FROM s.first_expected_remittance_date+(d.monitoring_day_index-1)))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.advance_daily_remittance_monitoring AS d JOIN msbf_m2.advance_monitoring_source_snapshot AS s ON s.module1_run_id=d.module1_run_id AND s.scenario_id=d.scenario_id AND s.merchant_application_id=d.merchant_application_id WHERE d.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND d.monitoring_date IS DISTINCT FROM s.first_expected_remittance_date+(d.monitoring_day_index-1))), FALSE),
        'Monitoring dates map sequentially from first expected remittance.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_036_REPLAY_HASHES_PRESENT',
        'REPLAY_HASH_NULLS',
        ((SELECT count(*) FROM msbf_m2.advance_daily_remittance_monitoring WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND (source_pos_set_hash IS NULL OR source_deposit_row_hash IS NULL)))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.advance_daily_remittance_monitoring WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND (source_pos_set_hash IS NULL OR source_deposit_row_hash IS NULL))), FALSE),
        'POS and deposit replay hashes are present.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_037_REPLAY_SOURCE_DATES',
        'REPLAY_SOURCE_DATE_ERRORS',
        ((SELECT count(*) FROM msbf_m2.advance_daily_remittance_monitoring AS d JOIN msbf_m2.advance_monitoring_source_snapshot AS s ON s.module1_run_id=d.module1_run_id AND s.scenario_id=d.scenario_id AND s.merchant_application_id=d.merchant_application_id WHERE d.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND d.source_observation_date>s.as_of_date))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.advance_daily_remittance_monitoring AS d JOIN msbf_m2.advance_monitoring_source_snapshot AS s ON s.module1_run_id=d.module1_run_id AND s.scenario_id=d.scenario_id AND s.merchant_application_id=d.merchant_application_id WHERE d.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND d.source_observation_date>s.as_of_date)), FALSE),
        'Replay uses accepted historical dates no later than as-of date.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_038_ACTUAL_NOT_ABOVE_RAW',
        'ACTUAL_NOT_ABOVE_RAW_VIOLATIONS',
        ((SELECT count(*) FROM msbf_m2.advance_daily_remittance_monitoring AS d JOIN msbf_m2.advance_monitoring_source_snapshot AS s ON s.module1_run_id=d.module1_run_id AND s.scenario_id=d.scenario_id AND s.merchant_application_id=d.merchant_application_id WHERE d.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND (actual_remittance_amount>raw_remittance_amount+0.01)))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.advance_daily_remittance_monitoring AS d JOIN msbf_m2.advance_monitoring_source_snapshot AS s ON s.module1_run_id=d.module1_run_id AND s.scenario_id=d.scenario_id AND s.merchant_application_id=d.merchant_application_id WHERE d.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND (actual_remittance_amount>raw_remittance_amount+0.01))), FALSE),
        'Actual Not Above Raw has zero violations.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_039_ACTUAL_NOT_ABOVE_BALANCE',
        'ACTUAL_NOT_ABOVE_BALANCE_VIOLATIONS',
        ((SELECT count(*) FROM msbf_m2.advance_daily_remittance_monitoring AS d JOIN msbf_m2.advance_monitoring_source_snapshot AS s ON s.module1_run_id=d.module1_run_id AND s.scenario_id=d.scenario_id AND s.merchant_application_id=d.merchant_application_id WHERE d.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND (actual_remittance_amount>receivable_balance_before+0.01)))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.advance_daily_remittance_monitoring AS d JOIN msbf_m2.advance_monitoring_source_snapshot AS s ON s.module1_run_id=d.module1_run_id AND s.scenario_id=d.scenario_id AND s.merchant_application_id=d.merchant_application_id WHERE d.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND (actual_remittance_amount>receivable_balance_before+0.01))), FALSE),
        'Actual Not Above Balance has zero violations.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_040_BALANCE_RECONCILIATION',
        'BALANCE_RECONCILIATION_VIOLATIONS',
        ((SELECT count(*) FROM msbf_m2.advance_daily_remittance_monitoring AS d JOIN msbf_m2.advance_monitoring_source_snapshot AS s ON s.module1_run_id=d.module1_run_id AND s.scenario_id=d.scenario_id AND s.merchant_application_id=d.merchant_application_id WHERE d.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND (abs(receivable_balance_after-greatest(receivable_balance_before-actual_remittance_amount,0))>0.01)))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.advance_daily_remittance_monitoring AS d JOIN msbf_m2.advance_monitoring_source_snapshot AS s ON s.module1_run_id=d.module1_run_id AND s.scenario_id=d.scenario_id AND s.merchant_application_id=d.merchant_application_id WHERE d.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND (abs(receivable_balance_after-greatest(receivable_balance_before-actual_remittance_amount,0))>0.01))), FALSE),
        'Balance Reconciliation has zero violations.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_042_CUMULATIVE_CAP',
        'CUMULATIVE_CAP_VIOLATIONS',
        ((SELECT count(*) FROM msbf_m2.advance_daily_remittance_monitoring AS d JOIN msbf_m2.advance_monitoring_source_snapshot AS s ON s.module1_run_id=d.module1_run_id AND s.scenario_id=d.scenario_id AND s.merchant_application_id=d.merchant_application_id WHERE d.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND (cumulative_remittance_amount>total_repayment_amount+0.01)))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.advance_daily_remittance_monitoring AS d JOIN msbf_m2.advance_monitoring_source_snapshot AS s ON s.module1_run_id=d.module1_run_id AND s.scenario_id=d.scenario_id AND s.merchant_application_id=d.merchant_application_id WHERE d.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND (cumulative_remittance_amount>total_repayment_amount+0.01))), FALSE),
        'Cumulative Cap has zero violations.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_043_EXPECTED_CUMULATIVE_CAP',
        'EXPECTED_CUMULATIVE_CAP_VIOLATIONS',
        ((SELECT count(*) FROM msbf_m2.advance_daily_remittance_monitoring AS d JOIN msbf_m2.advance_monitoring_source_snapshot AS s ON s.module1_run_id=d.module1_run_id AND s.scenario_id=d.scenario_id AND s.merchant_application_id=d.merchant_application_id WHERE d.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND (cumulative_expected_remittance_amount>total_repayment_amount+0.01)))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.advance_daily_remittance_monitoring AS d JOIN msbf_m2.advance_monitoring_source_snapshot AS s ON s.module1_run_id=d.module1_run_id AND s.scenario_id=d.scenario_id AND s.merchant_application_id=d.merchant_application_id WHERE d.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND (cumulative_expected_remittance_amount>total_repayment_amount+0.01))), FALSE),
        'Expected Cumulative Cap has zero violations.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_044_SHORTFALL_RECONCILIATION',
        'SHORTFALL_RECONCILIATION_VIOLATIONS',
        ((SELECT count(*) FROM msbf_m2.advance_daily_remittance_monitoring AS d JOIN msbf_m2.advance_monitoring_source_snapshot AS s ON s.module1_run_id=d.module1_run_id AND s.scenario_id=d.scenario_id AND s.merchant_application_id=d.merchant_application_id WHERE d.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND (abs(cumulative_shortfall_amount-greatest(cumulative_expected_remittance_amount-cumulative_remittance_amount,0))>0.01)))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.advance_daily_remittance_monitoring AS d JOIN msbf_m2.advance_monitoring_source_snapshot AS s ON s.module1_run_id=d.module1_run_id AND s.scenario_id=d.scenario_id AND s.merchant_application_id=d.merchant_application_id WHERE d.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND (abs(cumulative_shortfall_amount-greatest(cumulative_expected_remittance_amount-cumulative_remittance_amount,0))>0.01))), FALSE),
        'Shortfall Reconciliation has zero violations.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_045_EXPOSURE_RECONCILIATION',
        'EXPOSURE_RECONCILIATION_VIOLATIONS',
        ((SELECT count(*) FROM msbf_m2.advance_daily_remittance_monitoring AS d JOIN msbf_m2.advance_monitoring_source_snapshot AS s ON s.module1_run_id=d.module1_run_id AND s.scenario_id=d.scenario_id AND s.merchant_application_id=d.merchant_application_id WHERE d.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND (abs(principal_exposure_proxy+unearned_finance_charge_proxy-receivable_balance_after)>0.02)))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.advance_daily_remittance_monitoring AS d JOIN msbf_m2.advance_monitoring_source_snapshot AS s ON s.module1_run_id=d.module1_run_id AND s.scenario_id=d.scenario_id AND s.merchant_application_id=d.merchant_application_id WHERE d.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND (abs(principal_exposure_proxy+unearned_finance_charge_proxy-receivable_balance_after)>0.02))), FALSE),
        'Exposure Reconciliation has zero violations.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_046_COVERAGE_RATIO_DOMAIN',
        'COVERAGE_RATIO_DOMAIN_VIOLATIONS',
        ((SELECT count(*) FROM msbf_m2.advance_daily_remittance_monitoring AS d JOIN msbf_m2.advance_monitoring_source_snapshot AS s ON s.module1_run_id=d.module1_run_id AND s.scenario_id=d.scenario_id AND s.merchant_application_id=d.merchant_application_id WHERE d.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND (remittance_coverage_ratio<0)))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.advance_daily_remittance_monitoring AS d JOIN msbf_m2.advance_monitoring_source_snapshot AS s ON s.module1_run_id=d.module1_run_id AND s.scenario_id=d.scenario_id AND s.merchant_application_id=d.merchant_application_id WHERE d.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND (remittance_coverage_ratio<0))), FALSE),
        'Coverage Ratio Domain has zero violations.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_047_PACE_RATIO_DOMAIN',
        'PACE_RATIO_DOMAIN_VIOLATIONS',
        ((SELECT count(*) FROM msbf_m2.advance_daily_remittance_monitoring AS d JOIN msbf_m2.advance_monitoring_source_snapshot AS s ON s.module1_run_id=d.module1_run_id AND s.scenario_id=d.scenario_id AND s.merchant_application_id=d.merchant_application_id WHERE d.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND (cumulative_pace_ratio<0)))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.advance_daily_remittance_monitoring AS d JOIN msbf_m2.advance_monitoring_source_snapshot AS s ON s.module1_run_id=d.module1_run_id AND s.scenario_id=d.scenario_id AND s.merchant_application_id=d.merchant_application_id WHERE d.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND (cumulative_pace_ratio<0))), FALSE),
        'Pace Ratio Domain has zero violations.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_048_ZERO_STREAK_DOMAIN',
        'ZERO_STREAK_DOMAIN_VIOLATIONS',
        ((SELECT count(*) FROM msbf_m2.advance_daily_remittance_monitoring AS d JOIN msbf_m2.advance_monitoring_source_snapshot AS s ON s.module1_run_id=d.module1_run_id AND s.scenario_id=d.scenario_id AND s.merchant_application_id=d.merchant_application_id WHERE d.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND (zero_sales_streak_days<0)))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.advance_daily_remittance_monitoring AS d JOIN msbf_m2.advance_monitoring_source_snapshot AS s ON s.module1_run_id=d.module1_run_id AND s.scenario_id=d.scenario_id AND s.merchant_application_id=d.merchant_application_id WHERE d.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND (zero_sales_streak_days<0))), FALSE),
        'Zero Streak Domain has zero violations.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_049_DAYS_SINCE_REMITTANCE_DOMAIN',
        'DAYS_SINCE_REMITTANCE_DOMAIN_VIOLATIONS',
        ((SELECT count(*) FROM msbf_m2.advance_daily_remittance_monitoring AS d JOIN msbf_m2.advance_monitoring_source_snapshot AS s ON s.module1_run_id=d.module1_run_id AND s.scenario_id=d.scenario_id AND s.merchant_application_id=d.merchant_application_id WHERE d.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND (days_since_last_positive_remittance<0)))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.advance_daily_remittance_monitoring AS d JOIN msbf_m2.advance_monitoring_source_snapshot AS s ON s.module1_run_id=d.module1_run_id AND s.scenario_id=d.scenario_id AND s.merchant_application_id=d.merchant_application_id WHERE d.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND (days_since_last_positive_remittance<0))), FALSE),
        'Days Since Remittance Domain has zero violations.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_050_TRAILING_7_CAP',
        'TRAILING_7_CAP_VIOLATIONS',
        ((SELECT count(*) FROM msbf_m2.advance_daily_remittance_monitoring AS d JOIN msbf_m2.advance_monitoring_source_snapshot AS s ON s.module1_run_id=d.module1_run_id AND s.scenario_id=d.scenario_id AND s.merchant_application_id=d.merchant_application_id WHERE d.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND (trailing_7_day_remittance_amount>cumulative_remittance_amount+0.01)))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.advance_daily_remittance_monitoring AS d JOIN msbf_m2.advance_monitoring_source_snapshot AS s ON s.module1_run_id=d.module1_run_id AND s.scenario_id=d.scenario_id AND s.merchant_application_id=d.merchant_application_id WHERE d.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND (trailing_7_day_remittance_amount>cumulative_remittance_amount+0.01))), FALSE),
        'Trailing 7 Cap has zero violations.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_051_TRAILING_30_CAP',
        'TRAILING_30_CAP_VIOLATIONS',
        ((SELECT count(*) FROM msbf_m2.advance_daily_remittance_monitoring AS d JOIN msbf_m2.advance_monitoring_source_snapshot AS s ON s.module1_run_id=d.module1_run_id AND s.scenario_id=d.scenario_id AND s.merchant_application_id=d.merchant_application_id WHERE d.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND (trailing_30_day_remittance_amount>cumulative_remittance_amount+0.01)))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.advance_daily_remittance_monitoring AS d JOIN msbf_m2.advance_monitoring_source_snapshot AS s ON s.module1_run_id=d.module1_run_id AND s.scenario_id=d.scenario_id AND s.merchant_application_id=d.merchant_application_id WHERE d.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND (trailing_30_day_remittance_amount>cumulative_remittance_amount+0.01))), FALSE),
        'Trailing 30 Cap has zero violations.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_052_PAID_OFF_IDENTITY',
        'PAID_OFF_IDENTITY_VIOLATIONS',
        ((SELECT count(*) FROM msbf_m2.advance_daily_remittance_monitoring AS d JOIN msbf_m2.advance_monitoring_source_snapshot AS s ON s.module1_run_id=d.module1_run_id AND s.scenario_id=d.scenario_id AND s.merchant_application_id=d.merchant_application_id WHERE d.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND (paid_off_flag IS DISTINCT FROM (receivable_balance_after=0))))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.advance_daily_remittance_monitoring AS d JOIN msbf_m2.advance_monitoring_source_snapshot AS s ON s.module1_run_id=d.module1_run_id AND s.scenario_id=d.scenario_id AND s.merchant_application_id=d.merchant_application_id WHERE d.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND (paid_off_flag IS DISTINCT FROM (receivable_balance_after=0)))), FALSE),
        'Paid Off Identity has zero violations.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_053_STATUS_RANK_DOMAIN',
        'STATUS_RANK_DOMAIN_VIOLATIONS',
        ((SELECT count(*) FROM msbf_m2.advance_daily_remittance_monitoring AS d JOIN msbf_m2.advance_monitoring_source_snapshot AS s ON s.module1_run_id=d.module1_run_id AND s.scenario_id=d.scenario_id AND s.merchant_application_id=d.merchant_application_id WHERE d.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND (monitoring_status_rank NOT BETWEEN 0 AND 5 OR raw_monitoring_status_rank NOT BETWEEN 0 AND 5)))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.advance_daily_remittance_monitoring AS d JOIN msbf_m2.advance_monitoring_source_snapshot AS s ON s.module1_run_id=d.module1_run_id AND s.scenario_id=d.scenario_id AND s.merchant_application_id=d.merchant_application_id WHERE d.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND (monitoring_status_rank NOT BETWEEN 0 AND 5 OR raw_monitoring_status_rank NOT BETWEEN 0 AND 5))), FALSE),
        'Status Rank Domain has zero violations.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_041_CUMULATIVE_MONOTONIC',
        'CUMULATIVE_MONOTONIC_VIOLATIONS',
        ((SELECT count(*) FROM (SELECT cumulative_remittance_amount,lag(cumulative_remittance_amount) OVER(PARTITION BY scenario_id,merchant_application_id ORDER BY monitoring_day_index) AS prior FROM msbf_m2.advance_daily_remittance_monitoring WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx)) AS x WHERE prior IS NOT NULL AND cumulative_remittance_amount<prior))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM (SELECT cumulative_remittance_amount,lag(cumulative_remittance_amount) OVER(PARTITION BY scenario_id,merchant_application_id ORDER BY monitoring_day_index) AS prior FROM msbf_m2.advance_daily_remittance_monitoring WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx)) AS x WHERE prior IS NOT NULL AND cumulative_remittance_amount<prior)), FALSE),
        'Cumulative remittance is nondecreasing.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_054_STATUS_CODE_RANK_MAPPING',
        'STATUS_CODE_RANK_MISMATCHES',
        ((SELECT count(*) FROM msbf_m2.advance_daily_remittance_monitoring AS d JOIN msbf_m2.portfolio_monitoring_status_definition AS s ON s.module1_run_id=d.module1_run_id AND s.monitoring_status_code=d.monitoring_status_code WHERE d.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND s.monitoring_status_rank<>d.monitoring_status_rank))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.advance_daily_remittance_monitoring AS d JOIN msbf_m2.portfolio_monitoring_status_definition AS s ON s.module1_run_id=d.module1_run_id AND s.monitoring_status_code=d.monitoring_status_code WHERE d.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND s.monitoring_status_rank<>d.monitoring_status_rank)), FALSE),
        'Final status code and rank match dictionary.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_055_RAW_STATUS_CODE_RANK_MAPPING',
        'RAW_STATUS_CODE_RANK_MISMATCHES',
        ((SELECT count(*) FROM msbf_m2.advance_daily_remittance_monitoring AS d JOIN msbf_m2.portfolio_monitoring_status_definition AS s ON s.module1_run_id=d.module1_run_id AND s.monitoring_status_code=d.raw_monitoring_status_code WHERE d.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND s.monitoring_status_rank<>d.raw_monitoring_status_rank))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.advance_daily_remittance_monitoring AS d JOIN msbf_m2.portfolio_monitoring_status_definition AS s ON s.module1_run_id=d.module1_run_id AND s.monitoring_status_code=d.raw_monitoring_status_code WHERE d.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND s.monitoring_status_rank<>d.raw_monitoring_status_rank)), FALSE),
        'Raw status code and rank match dictionary.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_056_STRESS_RANK_FLOOR',
        'STRESS_RANK_FLOOR_VIOLATIONS',
        ((SELECT count(*) FROM msbf_m2.advance_daily_remittance_monitoring WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND scenario_code='RECESSION_ENERGY' AND NOT paid_off_flag AND monitoring_status_rank<raw_monitoring_status_rank))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.advance_daily_remittance_monitoring WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND scenario_code='RECESSION_ENERGY' AND NOT paid_off_flag AND monitoring_status_rank<raw_monitoring_status_rank)), FALSE),
        'Stress final status is never more favorable than raw status for open exposure.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_057_STRESS_FLOOR_FLAG_IDENTITY',
        'STRESS_FLOOR_FLAG_ERRORS',
        ((SELECT count(*) FROM msbf_m2.advance_daily_remittance_monitoring AS stress JOIN msbf_m2.advance_daily_remittance_monitoring AS baseline ON baseline.module1_run_id=stress.module1_run_id AND baseline.merchant_application_id=stress.merchant_application_id AND baseline.monitoring_day_index=stress.monitoring_day_index AND baseline.scenario_code='BASELINE' WHERE stress.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND stress.scenario_code='RECESSION_ENERGY' AND stress.stress_status_floor_applied_flag IS DISTINCT FROM (NOT stress.paid_off_flag AND NOT baseline.paid_off_flag AND stress.raw_monitoring_status_rank<baseline.raw_monitoring_status_rank)))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.advance_daily_remittance_monitoring AS stress JOIN msbf_m2.advance_daily_remittance_monitoring AS baseline ON baseline.module1_run_id=stress.module1_run_id AND baseline.merchant_application_id=stress.merchant_application_id AND baseline.monitoring_day_index=stress.monitoring_day_index AND baseline.scenario_code='BASELINE' WHERE stress.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND stress.scenario_code='RECESSION_ENERGY' AND stress.stress_status_floor_applied_flag IS DISTINCT FROM (NOT stress.paid_off_flag AND NOT baseline.paid_off_flag AND stress.raw_monitoring_status_rank<baseline.raw_monitoring_status_rank))), FALSE),
        'Stress-floor flag reflects actual open-exposure adjustments.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_058_RAW_STATUS_RECOMPUTATION',
        'RAW_STATUS_RECOMPUTATION_ERRORS',
        ((SELECT count(*) FROM msbf_m2.advance_daily_remittance_monitoring AS d JOIN msbf_m2.advance_monitoring_source_snapshot AS s ON s.module1_run_id=d.module1_run_id AND s.scenario_id=d.scenario_id AND s.merchant_application_id=d.merchant_application_id WHERE d.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND d.raw_monitoring_status_rank IS DISTINCT FROM CASE WHEN d.receivable_balance_after=0 THEN 0 WHEN d.monitoring_day_index>=14 AND d.days_since_last_positive_remittance>=14 THEN 5 WHEN d.monitoring_day_index>=14 AND (d.cumulative_pace_ratio<0.5 OR d.zero_sales_streak_days>=10 OR (d.monitoring_day_index>s.collection_horizon_days AND d.receivable_balance_after>0)) THEN 4 WHEN d.monitoring_day_index>=14 AND (d.cumulative_pace_ratio<0.75 OR d.days_since_last_positive_remittance>=7) THEN 3 WHEN d.monitoring_day_index>=7 AND (d.cumulative_pace_ratio<0.9 OR d.remittance_coverage_ratio<0.75 OR d.source_available_balance<0 OR d.source_nsf_count>0 OR d.source_negative_balance_flag) THEN 2 ELSE 1 END))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.advance_daily_remittance_monitoring AS d JOIN msbf_m2.advance_monitoring_source_snapshot AS s ON s.module1_run_id=d.module1_run_id AND s.scenario_id=d.scenario_id AND s.merchant_application_id=d.merchant_application_id WHERE d.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND d.raw_monitoring_status_rank IS DISTINCT FROM CASE WHEN d.receivable_balance_after=0 THEN 0 WHEN d.monitoring_day_index>=14 AND d.days_since_last_positive_remittance>=14 THEN 5 WHEN d.monitoring_day_index>=14 AND (d.cumulative_pace_ratio<0.5 OR d.zero_sales_streak_days>=10 OR (d.monitoring_day_index>s.collection_horizon_days AND d.receivable_balance_after>0)) THEN 4 WHEN d.monitoring_day_index>=14 AND (d.cumulative_pace_ratio<0.75 OR d.days_since_last_positive_remittance>=7) THEN 3 WHEN d.monitoring_day_index>=7 AND (d.cumulative_pace_ratio<0.9 OR d.remittance_coverage_ratio<0.75 OR d.source_available_balance<0 OR d.source_nsf_count>0 OR d.source_negative_balance_flag) THEN 2 ELSE 1 END)), FALSE),
        'Raw monitoring status reconstructs from governed thresholds.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_059_PRIMARY_REASON_PRESENT',
        'PRIMARY_REASON_NULLS',
        ((SELECT count(*) FROM msbf_m2.advance_daily_remittance_monitoring WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND primary_monitoring_reason_code IS NULL))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.advance_daily_remittance_monitoring WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND primary_monitoring_reason_code IS NULL)), FALSE),
        'Every daily row has a primary reason.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_060_REASON_ARRAY_PRESENT',
        'REASON_ARRAY_ERRORS',
        ((SELECT count(*) FROM msbf_m2.advance_daily_remittance_monitoring WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND (monitoring_reason_codes IS NULL OR jsonb_typeof(monitoring_reason_codes)<>'array' OR jsonb_array_length(monitoring_reason_codes)=0)))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.advance_daily_remittance_monitoring WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND (monitoring_reason_codes IS NULL OR jsonb_typeof(monitoring_reason_codes)<>'array' OR jsonb_array_length(monitoring_reason_codes)=0))), FALSE),
        'Reason payload is a nonempty JSON array.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_061_ALERT_PAYLOAD_OBJECT',
        'ALERT_PAYLOAD_ERRORS',
        ((SELECT count(*) FROM msbf_m2.advance_daily_remittance_monitoring WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND jsonb_typeof(alert_payload)<>'object'))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.advance_daily_remittance_monitoring WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND jsonb_typeof(alert_payload)<>'object')), FALSE),
        'Alert payload is a JSON object.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_062_DAILY_SHORTFALL_ALERT',
        'DAILY_SHORTFALL_ALERT_ERRORS',
        ((SELECT count(*) FROM msbf_m2.advance_daily_remittance_monitoring WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND (daily_shortfall_alert_flag IS DISTINCT FROM (daily_shortfall_amount>0))))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.advance_daily_remittance_monitoring WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND (daily_shortfall_alert_flag IS DISTINCT FROM (daily_shortfall_amount>0)))), FALSE),
        'Daily Shortfall Alert matches metrics.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_063_PACE_WATCH_ALERT',
        'PACE_WATCH_ALERT_ERRORS',
        ((SELECT count(*) FROM msbf_m2.advance_daily_remittance_monitoring WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND (cumulative_pace_watch_alert_flag IS DISTINCT FROM (monitoring_day_index>=7 AND cumulative_pace_ratio<0.9))))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.advance_daily_remittance_monitoring WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND (cumulative_pace_watch_alert_flag IS DISTINCT FROM (monitoring_day_index>=7 AND cumulative_pace_ratio<0.9)))), FALSE),
        'Pace Watch Alert matches metrics.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_064_PACE_HIGH_ALERT',
        'PACE_HIGH_ALERT_ERRORS',
        ((SELECT count(*) FROM msbf_m2.advance_daily_remittance_monitoring WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND (cumulative_pace_high_alert_flag IS DISTINCT FROM (monitoring_day_index>=14 AND cumulative_pace_ratio<0.75))))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.advance_daily_remittance_monitoring WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND (cumulative_pace_high_alert_flag IS DISTINCT FROM (monitoring_day_index>=14 AND cumulative_pace_ratio<0.75)))), FALSE),
        'Pace High Alert matches metrics.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_065_ZERO_STREAK_ALERT',
        'ZERO_STREAK_ALERT_ERRORS',
        ((SELECT count(*) FROM msbf_m2.advance_daily_remittance_monitoring WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND (zero_sales_streak_alert_flag IS DISTINCT FROM (zero_sales_streak_days>=10))))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.advance_daily_remittance_monitoring WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND (zero_sales_streak_alert_flag IS DISTINCT FROM (zero_sales_streak_days>=10)))), FALSE),
        'Zero Streak Alert matches metrics.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_066_LIQUIDITY_ALERT',
        'LIQUIDITY_ALERT_ERRORS',
        ((SELECT count(*) FROM msbf_m2.advance_daily_remittance_monitoring WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND (liquidity_stress_alert_flag IS DISTINCT FROM (source_available_balance<0 OR source_nsf_count>0 OR source_negative_balance_flag))))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.advance_daily_remittance_monitoring WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND (liquidity_stress_alert_flag IS DISTINCT FROM (source_available_balance<0 OR source_nsf_count>0 OR source_negative_balance_flag)))), FALSE),
        'Liquidity Alert matches metrics.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_067_HORIZON_OVERRUN_ALERT',
        'HORIZON_OVERRUN_ALERT_ERRORS',
        ((SELECT count(*) FROM msbf_m2.advance_daily_remittance_monitoring AS d JOIN msbf_m2.advance_monitoring_source_snapshot AS s ON s.module1_run_id=d.module1_run_id AND s.scenario_id=d.scenario_id AND s.merchant_application_id=d.merchant_application_id WHERE d.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND d.horizon_overrun_alert_flag IS DISTINCT FROM (d.monitoring_day_index>s.collection_horizon_days AND d.receivable_balance_after>0)))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.advance_daily_remittance_monitoring AS d JOIN msbf_m2.advance_monitoring_source_snapshot AS s ON s.module1_run_id=d.module1_run_id AND s.scenario_id=d.scenario_id AND s.merchant_application_id=d.merchant_application_id WHERE d.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND d.horizon_overrun_alert_flag IS DISTINCT FROM (d.monitoring_day_index>s.collection_horizon_days AND d.receivable_balance_after>0))), FALSE),
        'Horizon-overrun alert follows contract horizon.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_068_SOURCE_LINEAGE_HASHES',
        'SOURCE_LINEAGE_HASH_NULLS',
        ((SELECT count(*) FROM msbf_m2.advance_daily_remittance_monitoring WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND (source_m2_4_contract_row_hash IS NULL OR source_advance_row_hash IS NULL OR source_portfolio_row_hash IS NULL OR source_pos_set_hash IS NULL OR source_deposit_row_hash IS NULL)))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.advance_daily_remittance_monitoring WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND (source_m2_4_contract_row_hash IS NULL OR source_advance_row_hash IS NULL OR source_portfolio_row_hash IS NULL OR source_pos_set_hash IS NULL OR source_deposit_row_hash IS NULL))), FALSE),
        'Daily lineage hashes are complete.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_069_DAILY_PHYSICAL_HASH',
        'DAILY_HASH_MISMATCHES',
        ((SELECT count(*) FROM msbf_m2.advance_daily_remittance_monitoring AS d WHERE d.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND d.row_hash IS DISTINCT FROM msbf_ctl.m2_5_hash_jsonb(to_jsonb(d)-'row_hash'-'created_at')))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.advance_daily_remittance_monitoring AS d WHERE d.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND d.row_hash IS DISTINCT FROM msbf_ctl.m2_5_hash_jsonb(to_jsonb(d)-'row_hash'-'created_at'))), FALSE),
        'Daily physical hashes reconstruct.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_071_LATEST_GRAIN',
        'LATEST_DUPLICATE_GRAIN_ROWS',
        ((SELECT count(*)-count(DISTINCT scenario_id::text||'|'||merchant_application_id) FROM msbf_m2.advance_portfolio_monitoring_latest WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx)))::text,
        '0',
        coalesce(((SELECT count(*)=count(DISTINCT scenario_id::text||'|'||merchant_application_id) FROM msbf_m2.advance_portfolio_monitoring_latest WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx))), FALSE),
        'Latest grain is unique.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_072_LATEST_DAY_120',
        'LATEST_DAY_ERRORS',
        ((SELECT count(*) FROM msbf_m2.advance_portfolio_monitoring_latest WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND (monitoring_horizon_days<>120 OR latest_monitoring_day_index<>120)))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.advance_portfolio_monitoring_latest WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND (monitoring_horizon_days<>120 OR latest_monitoring_day_index<>120))), FALSE),
        'Latest contract represents day 120.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_073_LATEST_SOURCE_DAILY_HASH',
        'LATEST_SOURCE_DAILY_HASH_MISMATCHES',
        ((SELECT count(*) FROM msbf_m2.advance_portfolio_monitoring_latest AS l JOIN msbf_m2.advance_daily_remittance_monitoring AS d ON d.module1_run_id=l.module1_run_id AND d.scenario_id=l.scenario_id AND d.merchant_application_id=l.merchant_application_id AND d.monitoring_day_index=120 WHERE l.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND l.source_daily_row_hash IS DISTINCT FROM d.row_hash))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.advance_portfolio_monitoring_latest AS l JOIN msbf_m2.advance_daily_remittance_monitoring AS d ON d.module1_run_id=l.module1_run_id AND d.scenario_id=l.scenario_id AND d.merchant_application_id=l.merchant_application_id AND d.monitoring_day_index=120 WHERE l.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND l.source_daily_row_hash IS DISTINCT FROM d.row_hash)), FALSE),
        'Latest contract points to day-120 daily row.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_074_LATEST_PHYSICAL_HASH',
        'LATEST_HASH_MISMATCHES',
        ((SELECT count(*) FROM msbf_m2.advance_portfolio_monitoring_latest AS l WHERE l.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND l.contract_row_hash IS DISTINCT FROM msbf_ctl.m2_5_hash_jsonb(to_jsonb(l)-'contract_row_hash'-'created_at')))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.advance_portfolio_monitoring_latest AS l WHERE l.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND l.contract_row_hash IS DISTINCT FROM msbf_ctl.m2_5_hash_jsonb(to_jsonb(l)-'contract_row_hash'-'created_at'))), FALSE),
        'Latest contract hashes reconstruct.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_075_LATEST_STATUS_REPRODUCTION',
        'LATEST_STATUS_MISMATCHES',
        ((SELECT count(*) FROM msbf_m2.advance_portfolio_monitoring_latest AS l JOIN msbf_m2.advance_daily_remittance_monitoring AS d ON d.module1_run_id=l.module1_run_id AND d.scenario_id=l.scenario_id AND d.merchant_application_id=l.merchant_application_id AND d.monitoring_day_index=120 WHERE l.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND (l.latest_monitoring_status_code IS DISTINCT FROM d.monitoring_status_code OR l.latest_monitoring_status_rank IS DISTINCT FROM d.monitoring_status_rank OR l.paid_off_flag IS DISTINCT FROM d.paid_off_flag)))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.advance_portfolio_monitoring_latest AS l JOIN msbf_m2.advance_daily_remittance_monitoring AS d ON d.module1_run_id=l.module1_run_id AND d.scenario_id=l.scenario_id AND d.merchant_application_id=l.merchant_application_id AND d.monitoring_day_index=120 WHERE l.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND (l.latest_monitoring_status_code IS DISTINCT FROM d.monitoring_status_code OR l.latest_monitoring_status_rank IS DISTINCT FROM d.monitoring_status_rank OR l.paid_off_flag IS DISTINCT FROM d.paid_off_flag))), FALSE),
        'Latest status reproduces day-120 daily status.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_076_LATEST_AMOUNT_REPRODUCTION',
        'LATEST_AMOUNT_MISMATCHES',
        ((SELECT count(*) FROM msbf_m2.advance_portfolio_monitoring_latest AS l JOIN msbf_m2.advance_daily_remittance_monitoring AS d ON d.module1_run_id=l.module1_run_id AND d.scenario_id=l.scenario_id AND d.merchant_application_id=l.merchant_application_id AND d.monitoring_day_index=120 WHERE l.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND (l.cumulative_remittance_amount IS DISTINCT FROM d.cumulative_remittance_amount OR l.remaining_receivable_amount IS DISTINCT FROM d.receivable_balance_after OR l.cumulative_shortfall_amount IS DISTINCT FROM d.cumulative_shortfall_amount)))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.advance_portfolio_monitoring_latest AS l JOIN msbf_m2.advance_daily_remittance_monitoring AS d ON d.module1_run_id=l.module1_run_id AND d.scenario_id=l.scenario_id AND d.merchant_application_id=l.merchant_application_id AND d.monitoring_day_index=120 WHERE l.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND (l.cumulative_remittance_amount IS DISTINCT FROM d.cumulative_remittance_amount OR l.remaining_receivable_amount IS DISTINCT FROM d.receivable_balance_after OR l.cumulative_shortfall_amount IS DISTINCT FROM d.cumulative_shortfall_amount))), FALSE),
        'Latest economics reproduce day-120 metrics.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_077_PAYOFF_DAY_IDENTITY',
        'PAYOFF_DAY_ERRORS',
        ((SELECT count(*) FROM msbf_m2.advance_portfolio_monitoring_latest AS l WHERE l.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND l.payoff_day_index IS DISTINCT FROM (SELECT min(d.monitoring_day_index) FROM msbf_m2.advance_daily_remittance_monitoring AS d WHERE d.module1_run_id=l.module1_run_id AND d.scenario_id=l.scenario_id AND d.merchant_application_id=l.merchant_application_id AND d.paid_off_flag)))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.advance_portfolio_monitoring_latest AS l WHERE l.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND l.payoff_day_index IS DISTINCT FROM (SELECT min(d.monitoring_day_index) FROM msbf_m2.advance_daily_remittance_monitoring AS d WHERE d.module1_run_id=l.module1_run_id AND d.scenario_id=l.scenario_id AND d.merchant_application_id=l.merchant_application_id AND d.paid_off_flag))), FALSE),
        'Payoff day is the first paid-off daily row.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_078_LATEST_ALERT_COUNT',
        'LATEST_ALERT_COUNT_ERRORS',
        ((SELECT count(*) FROM msbf_m2.advance_portfolio_monitoring_latest AS l JOIN msbf_m2.advance_daily_remittance_monitoring AS d ON d.module1_run_id=l.module1_run_id AND d.scenario_id=l.scenario_id AND d.merchant_application_id=l.merchant_application_id AND d.monitoring_day_index=120 WHERE l.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND l.active_alert_count IS DISTINCT FROM (d.daily_shortfall_alert_flag::integer+d.cumulative_pace_watch_alert_flag::integer+d.cumulative_pace_high_alert_flag::integer+d.zero_sales_streak_alert_flag::integer+d.liquidity_stress_alert_flag::integer+d.horizon_overrun_alert_flag::integer+d.stress_status_floor_applied_flag::integer)))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.advance_portfolio_monitoring_latest AS l JOIN msbf_m2.advance_daily_remittance_monitoring AS d ON d.module1_run_id=l.module1_run_id AND d.scenario_id=l.scenario_id AND d.merchant_application_id=l.merchant_application_id AND d.monitoring_day_index=120 WHERE l.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND l.active_alert_count IS DISTINCT FROM (d.daily_shortfall_alert_flag::integer+d.cumulative_pace_watch_alert_flag::integer+d.cumulative_pace_high_alert_flag::integer+d.zero_sales_streak_alert_flag::integer+d.liquidity_stress_alert_flag::integer+d.horizon_overrun_alert_flag::integer+d.stress_status_floor_applied_flag::integer))), FALSE),
        'Latest alert count reproduces day-120 alert flags.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_080_ARCHIVE_GRAIN',
        'ARCHIVE_DUPLICATE_GRAIN_ROWS',
        ((SELECT count(*)-count(DISTINCT contract_version::text||'|'||scenario_id::text||'|'||merchant_application_id) FROM msbf_m2.advance_portfolio_monitoring_archive WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx)))::text,
        '0',
        coalesce(((SELECT count(*)=count(DISTINCT contract_version::text||'|'||scenario_id::text||'|'||merchant_application_id) FROM msbf_m2.advance_portfolio_monitoring_archive WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx))), FALSE),
        'Archive grain is unique.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_081_ARCHIVE_PHYSICAL_HASH',
        'ARCHIVE_HASH_MISMATCHES',
        ((SELECT count(*) FROM msbf_m2.advance_portfolio_monitoring_archive AS a WHERE a.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND a.archive_row_hash IS DISTINCT FROM msbf_ctl.m2_5_hash_jsonb(to_jsonb(a)-'archive_id'-'archive_row_hash'-'archived_at'-'created_at')))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.advance_portfolio_monitoring_archive AS a WHERE a.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND a.archive_row_hash IS DISTINCT FROM msbf_ctl.m2_5_hash_jsonb(to_jsonb(a)-'archive_id'-'archive_row_hash'-'archived_at'-'created_at'))), FALSE),
        'Archive hashes reconstruct.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_082_LATEST_ARCHIVE_REPRODUCTION',
        'LATEST_ARCHIVE_MISMATCHES',
        ((SELECT count(*) FROM msbf_m2.advance_portfolio_monitoring_latest AS l FULL OUTER JOIN msbf_m2.advance_portfolio_monitoring_archive AS a ON a.module1_run_id=l.module1_run_id AND a.contract_version=l.contract_version AND a.scenario_id=l.scenario_id AND a.merchant_application_id=l.merchant_application_id WHERE coalesce(l.module1_run_id,a.module1_run_id)=(SELECT run_id FROM _m2_5_vctx) AND (l.contract_row_hash IS DISTINCT FROM a.contract_row_hash OR a.contract_payload IS DISTINCT FROM (to_jsonb(l)-'created_at'))))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.advance_portfolio_monitoring_latest AS l FULL OUTER JOIN msbf_m2.advance_portfolio_monitoring_archive AS a ON a.module1_run_id=l.module1_run_id AND a.contract_version=l.contract_version AND a.scenario_id=l.scenario_id AND a.merchant_application_id=l.merchant_application_id WHERE coalesce(l.module1_run_id,a.module1_run_id)=(SELECT run_id FROM _m2_5_vctx) AND (l.contract_row_hash IS DISTINCT FROM a.contract_row_hash OR a.contract_payload IS DISTINCT FROM (to_jsonb(l)-'created_at')))), FALSE),
        'Latest and archive reproduce exactly.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_084_PORTFOLIO_SCENARIO_ROWS',
        'PORTFOLIO_SCENARIO_ROWS',
        ((SELECT count(*) FILTER(WHERE scenario_code='BASELINE')||'|'||count(*) FILTER(WHERE scenario_code='RECESSION_ENERGY') FROM msbf_m2.portfolio_daily_monitoring_summary WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx)))::text,
        '120|120',
        coalesce(((SELECT count(*) FILTER(WHERE scenario_code='BASELINE')=120 AND count(*) FILTER(WHERE scenario_code='RECESSION_ENERGY')=120 FROM msbf_m2.portfolio_daily_monitoring_summary WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx))), FALSE),
        'Portfolio summary has 120 rows per scenario.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_085_PORTFOLIO_PHYSICAL_HASH',
        'PORTFOLIO_HASH_MISMATCHES',
        ((SELECT count(*) FROM msbf_m2.portfolio_daily_monitoring_summary AS p WHERE p.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND p.row_hash IS DISTINCT FROM msbf_ctl.m2_5_hash_jsonb(to_jsonb(p)-'row_hash'-'created_at')))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.portfolio_daily_monitoring_summary AS p WHERE p.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND p.row_hash IS DISTINCT FROM msbf_ctl.m2_5_hash_jsonb(to_jsonb(p)-'row_hash'-'created_at'))), FALSE),
        'Portfolio summary hashes reconstruct.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_086_PORTFOLIO_COUNT_RECONCILIATION',
        'PORTFOLIO_COUNT_ERRORS',
        ((SELECT count(*) FROM msbf_m2.portfolio_daily_monitoring_summary AS p WHERE p.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND p.opening_advance_count IS DISTINCT FROM (SELECT count(*) FROM msbf_m2.advance_daily_remittance_monitoring AS d WHERE d.module1_run_id=p.module1_run_id AND d.scenario_id=p.scenario_id AND d.monitoring_day_index=p.monitoring_day_index)))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.portfolio_daily_monitoring_summary AS p WHERE p.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND p.opening_advance_count IS DISTINCT FROM (SELECT count(*) FROM msbf_m2.advance_daily_remittance_monitoring AS d WHERE d.module1_run_id=p.module1_run_id AND d.scenario_id=p.scenario_id AND d.monitoring_day_index=p.monitoring_day_index))), FALSE),
        'Portfolio opening counts reconcile to daily ledger.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_087_PORTFOLIO_REMITTANCE_RECONCILIATION',
        'PORTFOLIO_REMITTANCE_ERRORS',
        ((SELECT count(*) FROM msbf_m2.portfolio_daily_monitoring_summary AS p WHERE p.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND p.daily_remittance_amount IS DISTINCT FROM (SELECT round(sum(d.actual_remittance_amount),2) FROM msbf_m2.advance_daily_remittance_monitoring AS d WHERE d.module1_run_id=p.module1_run_id AND d.scenario_id=p.scenario_id AND d.monitoring_day_index=p.monitoring_day_index)))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.portfolio_daily_monitoring_summary AS p WHERE p.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND p.daily_remittance_amount IS DISTINCT FROM (SELECT round(sum(d.actual_remittance_amount),2) FROM msbf_m2.advance_daily_remittance_monitoring AS d WHERE d.module1_run_id=p.module1_run_id AND d.scenario_id=p.scenario_id AND d.monitoring_day_index=p.monitoring_day_index))), FALSE),
        'Portfolio remittance reconciles to daily ledger.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_088_PORTFOLIO_EXPOSURE_RECONCILIATION',
        'PORTFOLIO_EXPOSURE_ERRORS',
        ((SELECT count(*) FROM msbf_m2.portfolio_daily_monitoring_summary AS p WHERE p.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND p.total_receivable_exposure_amount IS DISTINCT FROM (SELECT round(sum(d.receivable_balance_after),2) FROM msbf_m2.advance_daily_remittance_monitoring AS d WHERE d.module1_run_id=p.module1_run_id AND d.scenario_id=p.scenario_id AND d.monitoring_day_index=p.monitoring_day_index)))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.portfolio_daily_monitoring_summary AS p WHERE p.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND p.total_receivable_exposure_amount IS DISTINCT FROM (SELECT round(sum(d.receivable_balance_after),2) FROM msbf_m2.advance_daily_remittance_monitoring AS d WHERE d.module1_run_id=p.module1_run_id AND d.scenario_id=p.scenario_id AND d.monitoring_day_index=p.monitoring_day_index))), FALSE),
        'Portfolio exposure reconciles to daily ledger.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_089_PORTFOLIO_PACE_RECONCILIATION',
        'PORTFOLIO_PACE_ERRORS',
        ((SELECT count(*) FROM msbf_m2.portfolio_daily_monitoring_summary AS p WHERE p.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND p.portfolio_pace_ratio IS DISTINCT FROM CASE WHEN p.cumulative_expected_remittance_amount>0 THEN round(p.cumulative_remittance_amount/p.cumulative_expected_remittance_amount,8) ELSE 1.00000000 END))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.portfolio_daily_monitoring_summary AS p WHERE p.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND p.portfolio_pace_ratio IS DISTINCT FROM CASE WHEN p.cumulative_expected_remittance_amount>0 THEN round(p.cumulative_remittance_amount/p.cumulative_expected_remittance_amount,8) ELSE 1.00000000 END)), FALSE),
        'Portfolio pace ratio is internally coherent.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_090_COMPARISON_ROWS',
        'COMPARISON_ROWS',
        ((SELECT count(*) FROM msbf_m2.v_m2_5_matched_monitoring_comparison WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx)))::text,
        '15',
        coalesce(((SELECT count(*)=15 FROM msbf_m2.v_m2_5_matched_monitoring_comparison WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx))), FALSE),
        'Fifteen applications are active in both scenarios.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_091_STRESS_STATUS_NONIMPROVEMENT',
        'STRESS_STATUS_IMPROVEMENTS',
        ((SELECT count(*) FROM msbf_m2.v_m2_5_matched_monitoring_comparison WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND stress_status_improvement_flag))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.v_m2_5_matched_monitoring_comparison WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND stress_status_improvement_flag)), FALSE),
        'Stress latest status does not improve for open exposure.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_092_MATCHED_APPLICATIONS',
        'MATCHED_APPLICATIONS',
        ((SELECT count(DISTINCT merchant_application_id) FROM msbf_m2.v_m2_5_matched_monitoring_comparison WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx)))::text,
        '15',
        coalesce(((SELECT count(DISTINCT merchant_application_id)=15 FROM msbf_m2.v_m2_5_matched_monitoring_comparison WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx))), FALSE),
        'Matched comparison contains 15 unique both-active applications.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_093_BOTH_ACTIVE_SOURCE',
        'BOTH_ACTIVE_SOURCE_ERRORS',
        ((SELECT count(*) FROM msbf_m2.v_m2_5_matched_monitoring_comparison AS c WHERE c.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND (c.baseline_synthetic_advance_id IS NULL OR c.stress_synthetic_advance_id IS NULL)))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.v_m2_5_matched_monitoring_comparison AS c WHERE c.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND (c.baseline_synthetic_advance_id IS NULL OR c.stress_synthetic_advance_id IS NULL))), FALSE),
        'Both matched scenarios have active advances.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_094_CANONICAL_ENTITY_COUNT',
        'CANONICAL_ENTITY_COUNT',
        ((SELECT canonical_entities FROM msbf_m2.v_m2_5_canonical_hash WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx)))::text,
        '7536',
        coalesce(((SELECT canonical_entities=7536 FROM msbf_m2.v_m2_5_canonical_hash WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx))), FALSE),
        'Canonical universe contains 7,536 entities.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_095_COMBINED_SET_HASH',
        'COMBINED_SET_HASH',
        ((SELECT combined_set_hash FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx)))::text,
        'physical canonical hash',
        coalesce(((SELECT r.combined_set_hash IS NOT DISTINCT FROM c.combined_set_hash FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry AS r JOIN msbf_m2.v_m2_5_canonical_hash AS c ON c.module1_run_id=r.module1_run_id WHERE r.module1_run_id=(SELECT run_id FROM _m2_5_vctx))), FALSE),
        'Combined hash matches physical canonical view.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_096_POLICY_SET_HASH',
        'POLICY_SET_HASH',
        ((SELECT policy_set_hash FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx)))::text,
        'physical reconstruction',
        coalesce(((SELECT reg.policy_set_hash IS NOT DISTINCT FROM (SELECT md5(string_agg(p.row_hash,'|' ORDER BY p.module1_run_id)) FROM msbf_ctl.m2_5_policy_profile AS p WHERE p.module1_run_id=(SELECT run_id FROM _m2_5_vctx)) FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry AS reg WHERE reg.module1_run_id=(SELECT run_id FROM _m2_5_vctx))), FALSE),
        'Policy Set Hash reconciles.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_097_STATUS_SET_HASH',
        'STATUS_SET_HASH',
        ((SELECT status_set_hash FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx)))::text,
        'physical reconstruction',
        coalesce(((SELECT reg.status_set_hash IS NOT DISTINCT FROM (SELECT md5(string_agg(s.row_hash,'|' ORDER BY s.monitoring_status_rank)) FROM msbf_m2.portfolio_monitoring_status_definition AS s WHERE s.module1_run_id=(SELECT run_id FROM _m2_5_vctx)) FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry AS reg WHERE reg.module1_run_id=(SELECT run_id FROM _m2_5_vctx))), FALSE),
        'Status Set Hash reconciles.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_098_ALERT_SET_HASH',
        'ALERT_SET_HASH',
        ((SELECT alert_set_hash FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx)))::text,
        'physical reconstruction',
        coalesce(((SELECT reg.alert_set_hash IS NOT DISTINCT FROM (SELECT md5(string_agg(a.row_hash,'|' ORDER BY a.alert_rank)) FROM msbf_m2.portfolio_monitoring_alert_definition AS a WHERE a.module1_run_id=(SELECT run_id FROM _m2_5_vctx)) FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry AS reg WHERE reg.module1_run_id=(SELECT run_id FROM _m2_5_vctx))), FALSE),
        'Alert Set Hash reconciles.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_099_REASON_SET_HASH',
        'REASON_SET_HASH',
        ((SELECT reason_set_hash FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx)))::text,
        'physical reconstruction',
        coalesce(((SELECT reg.reason_set_hash IS NOT DISTINCT FROM (SELECT md5(string_agg(r.row_hash,'|' ORDER BY r.monitoring_reason_code)) FROM msbf_m2.portfolio_monitoring_reason_definition AS r WHERE r.module1_run_id=(SELECT run_id FROM _m2_5_vctx)) FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry AS reg WHERE reg.module1_run_id=(SELECT run_id FROM _m2_5_vctx))), FALSE),
        'Reason Set Hash reconciles.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_100_SOURCE_SET_HASH',
        'SOURCE_SET_HASH',
        ((SELECT source_set_hash FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx)))::text,
        'physical reconstruction',
        coalesce(((SELECT reg.source_set_hash IS NOT DISTINCT FROM (SELECT md5(string_agg(s.scenario_id::text||'|'||s.merchant_application_id||'|'||s.row_hash,'|' ORDER BY s.scenario_id,s.merchant_application_id)) FROM msbf_m2.advance_monitoring_source_snapshot AS s WHERE s.module1_run_id=(SELECT run_id FROM _m2_5_vctx)) FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry AS reg WHERE reg.module1_run_id=(SELECT run_id FROM _m2_5_vctx))), FALSE),
        'Source Set Hash reconciles.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_101_DAILY_SET_HASH',
        'DAILY_SET_HASH',
        ((SELECT daily_set_hash FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx)))::text,
        'physical reconstruction',
        coalesce(((SELECT reg.daily_set_hash IS NOT DISTINCT FROM (SELECT md5(string_agg(d.scenario_id::text||'|'||d.merchant_application_id||'|'||d.monitoring_day_index::text||'|'||d.row_hash,'|' ORDER BY d.scenario_id,d.merchant_application_id,d.monitoring_day_index)) FROM msbf_m2.advance_daily_remittance_monitoring AS d WHERE d.module1_run_id=(SELECT run_id FROM _m2_5_vctx)) FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry AS reg WHERE reg.module1_run_id=(SELECT run_id FROM _m2_5_vctx))), FALSE),
        'Daily Set Hash reconciles.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_102_LATEST_SET_HASH',
        'LATEST_SET_HASH',
        ((SELECT latest_set_hash FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx)))::text,
        'physical reconstruction',
        coalesce(((SELECT reg.latest_set_hash IS NOT DISTINCT FROM (SELECT md5(string_agg(l.scenario_id::text||'|'||l.merchant_application_id||'|'||l.contract_row_hash,'|' ORDER BY l.scenario_id,l.merchant_application_id)) FROM msbf_m2.advance_portfolio_monitoring_latest AS l WHERE l.module1_run_id=(SELECT run_id FROM _m2_5_vctx)) FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry AS reg WHERE reg.module1_run_id=(SELECT run_id FROM _m2_5_vctx))), FALSE),
        'Latest Set Hash reconciles.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_103_ARCHIVE_SET_HASH',
        'ARCHIVE_SET_HASH',
        ((SELECT archive_set_hash FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx)))::text,
        'physical reconstruction',
        coalesce(((SELECT reg.archive_set_hash IS NOT DISTINCT FROM (SELECT md5(string_agg(a.scenario_id::text||'|'||a.merchant_application_id||'|'||a.archive_row_hash,'|' ORDER BY a.scenario_id,a.merchant_application_id)) FROM msbf_m2.advance_portfolio_monitoring_archive AS a WHERE a.module1_run_id=(SELECT run_id FROM _m2_5_vctx)) FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry AS reg WHERE reg.module1_run_id=(SELECT run_id FROM _m2_5_vctx))), FALSE),
        'Archive Set Hash reconciles.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_104_PORTFOLIO_SET_HASH',
        'PORTFOLIO_SET_HASH',
        ((SELECT portfolio_daily_set_hash FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx)))::text,
        'physical reconstruction',
        coalesce(((SELECT reg.portfolio_daily_set_hash IS NOT DISTINCT FROM (SELECT md5(string_agg(p.scenario_id::text||'|'||p.monitoring_day_index::text||'|'||p.row_hash,'|' ORDER BY p.scenario_id,p.monitoring_day_index)) FROM msbf_m2.portfolio_daily_monitoring_summary AS p WHERE p.module1_run_id=(SELECT run_id FROM _m2_5_vctx)) FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry AS reg WHERE reg.module1_run_id=(SELECT run_id FROM _m2_5_vctx))), FALSE),
        'Portfolio Set Hash reconciles.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_105_CONTRACT_SET_HASH',
        'CONTRACT_SET_HASH',
        ((SELECT contract_set_hash FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx)))::text,
        'md5(registry row hash)',
        coalesce(((SELECT contract_set_hash=md5(row_hash) FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx))), FALSE),
        'Contract set hash equals registry identity.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_106_REGISTRY_ROW_HASH',
        'REGISTRY_ROW_HASH_MISMATCHES',
        ((SELECT count(*) FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry AS r WHERE r.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND r.row_hash IS DISTINCT FROM msbf_ctl.m2_5_registry_row_hash(to_jsonb(r))))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry AS r WHERE r.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND r.row_hash IS DISTINCT FROM msbf_ctl.m2_5_registry_row_hash(to_jsonb(r)))), FALSE),
        'Registry row hash reconstructs.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_107_GENERATION_EVIDENCE_COUNT',
        'GENERATION_EVIDENCE_COUNT',
        ((SELECT count(*) FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM _m2_5_vctx) AND evidence_code LIKE 'M2_5_%' AND evidence_code NOT LIKE 'M2_5_POS_%' AND evidence_code NOT LIKE 'M2_5_NEG_%' AND evidence_code<>'M2_5_ACCEPTANCE_SUMMARY'))::text,
        '24',
        coalesce(((SELECT count(*)=24 FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM _m2_5_vctx) AND evidence_code LIKE 'M2_5_%' AND evidence_code NOT LIKE 'M2_5_POS_%' AND evidence_code NOT LIKE 'M2_5_NEG_%' AND evidence_code<>'M2_5_ACCEPTANCE_SUMMARY')), FALSE),
        'Twenty-four generation evidence rows exist.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_108_FAILED_EVIDENCE',
        'FAILED_EVIDENCE_ROWS',
        ((SELECT count(*) FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM _m2_5_vctx) AND evidence_code LIKE 'M2_5_%' AND status='FAIL'))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM _m2_5_vctx) AND evidence_code LIKE 'M2_5_%' AND status='FAIL')), FALSE),
        'No M2.5 evidence is failed.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_109_SOURCE_M1_6_POS_ROWS',
        'SOURCE_M1_6_POS_ROWS',
        ((SELECT count(*) FROM msbf_m1.merchant_pos_daily_scenario WHERE generated_by_run_id=(SELECT run_id FROM _m2_5_vctx)))::text,
        '270000',
        coalesce(((SELECT count(*)=270000 FROM msbf_m1.merchant_pos_daily_scenario WHERE generated_by_run_id=(SELECT run_id FROM _m2_5_vctx))), FALSE),
        'Accepted M1.6 POS source row count is intact.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_110_SOURCE_M1_6_DEPOSIT_ROWS',
        'SOURCE_M1_6_DEPOSIT_ROWS',
        ((SELECT count(*) FROM msbf_m1.merchant_deposit_daily_scenario WHERE generated_by_run_id=(SELECT run_id FROM _m2_5_vctx)))::text,
        '270000',
        coalesce(((SELECT count(*)=270000 FROM msbf_m1.merchant_deposit_daily_scenario WHERE generated_by_run_id=(SELECT run_id FROM _m2_5_vctx))), FALSE),
        'Accepted M1.6 deposit source row count is intact.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_111_NO_SERVICING_ACTION_COLUMNS',
        'PROHIBITED_COLUMN_ROWS',
        ((SELECT count(*) FROM information_schema.columns WHERE table_schema='msbf_m2' AND table_name IN ('advance_daily_remittance_monitoring','advance_portfolio_monitoring_latest','advance_portfolio_monitoring_archive','portfolio_daily_monitoring_summary') AND lower(column_name) IN ('debit_instruction','ach_trace_number','payment_network_confirmation','bank_account_number','routing_number','account_number','collection_action','servicing_action','write_off','charge_off','restructure_offer','workout_offer','external_notice_payload','production_adverse_action_notice')))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM information_schema.columns WHERE table_schema='msbf_m2' AND table_name IN ('advance_daily_remittance_monitoring','advance_portfolio_monitoring_latest','advance_portfolio_monitoring_archive','portfolio_daily_monitoring_summary') AND lower(column_name) IN ('debit_instruction','ach_trace_number','payment_network_confirmation','bank_account_number','routing_number','account_number','collection_action','servicing_action','write_off','charge_off','restructure_offer','workout_offer','external_notice_payload','production_adverse_action_notice'))), FALSE),
        'No servicing-action or real-payment columns exist.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_112_NO_M2_6_TABLES',
        'M2_6_TABLE_ROWS',
        ((SELECT count(*) FROM information_schema.tables WHERE table_schema IN ('msbf_ctl','msbf_m2') AND lower(table_name) LIKE 'm2_6%'))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM information_schema.tables WHERE table_schema IN ('msbf_ctl','msbf_m2') AND lower(table_name) LIKE 'm2_6%')), FALSE),
        'M2.6 objects are not created prematurely.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_113_NO_REAL_DEBIT_EVIDENCE',
        'REAL_DEBIT_EVIDENCE_ROWS',
        ((SELECT count(*) FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM _m2_5_vctx) AND lower(metric_name) LIKE '%debit_instruction%'))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM _m2_5_vctx) AND lower(metric_name) LIKE '%debit_instruction%')), FALSE),
        'No real debit instruction evidence exists.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_114_NO_PRODUCTION_NOTICE_REASONS',
        'PRODUCTION_NOTICE_REASON_ROWS',
        ((SELECT count(*) FROM msbf_m2.portfolio_monitoring_reason_definition WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND production_adverse_action_notice_flag))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.portfolio_monitoring_reason_definition WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND production_adverse_action_notice_flag)), FALSE),
        'No reason is a production adverse-action notice.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_115_NO_SERVICING_ACTION_REASONS',
        'SERVICING_ACTION_REASON_ROWS',
        ((SELECT count(*) FROM msbf_m2.portfolio_monitoring_reason_definition WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND servicing_action_authorized_flag))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.portfolio_monitoring_reason_definition WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND servicing_action_authorized_flag)), FALSE),
        'No reason authorizes servicing action.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_116_ACCEPTANCE_NOT_YET_WRITTEN',
        'ACCEPTANCE_ROWS',
        ((SELECT count(*) FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM _m2_5_vctx) AND gate_id='M2_5_DAILY_REMITTANCE_EXPOSURE_PORTFOLIO_MONITORING'))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM _m2_5_vctx) AND gate_id='M2_5_DAILY_REMITTANCE_EXPOSURE_PORTFOLIO_MONITORING')), FALSE),
        'Acceptance is not written before controls complete.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_117_PAID_OPEN_SUM',
        'PAID_OPEN_SUM',
        ((SELECT paid_off_rows+open_monitoring_rows FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx)))::text,
        '59',
        coalesce(((SELECT paid_off_rows+open_monitoring_rows=59 FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_5_vctx))), FALSE),
        'Paid-off and open monitoring rows sum to 59.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_118_TOTAL_REMITTANCE_REGISTRY',
        'TOTAL_REMITTANCE_REGISTRY_ERRORS',
        ((SELECT count(*) FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry AS r WHERE r.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND r.total_remittance_amount IS DISTINCT FROM (SELECT round(sum(l.cumulative_remittance_amount),2) FROM msbf_m2.advance_portfolio_monitoring_latest AS l WHERE l.module1_run_id=r.module1_run_id)))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry AS r WHERE r.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND r.total_remittance_amount IS DISTINCT FROM (SELECT round(sum(l.cumulative_remittance_amount),2) FROM msbf_m2.advance_portfolio_monitoring_latest AS l WHERE l.module1_run_id=r.module1_run_id))), FALSE),
        'Registry total remittance reconciles to latest rows.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_119_ENDING_EXPOSURE_REGISTRY',
        'ENDING_EXPOSURE_REGISTRY_ERRORS',
        ((SELECT count(*) FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry AS r WHERE r.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND r.ending_receivable_exposure_amount IS DISTINCT FROM (SELECT round(sum(l.remaining_receivable_amount),2) FROM msbf_m2.advance_portfolio_monitoring_latest AS l WHERE l.module1_run_id=r.module1_run_id)))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry AS r WHERE r.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND r.ending_receivable_exposure_amount IS DISTINCT FROM (SELECT round(sum(l.remaining_receivable_amount),2) FROM msbf_m2.advance_portfolio_monitoring_latest AS l WHERE l.module1_run_id=r.module1_run_id))), FALSE),
        'Registry ending exposure reconciles to latest rows.'
    );
    PERFORM pg_temp.m2_5_add_check
    (
        'M2_5_POS_120_STRESS_FLOOR_REGISTRY',
        'STRESS_FLOOR_REGISTRY_ERRORS',
        ((SELECT count(*) FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry AS r WHERE r.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND r.stress_status_floor_rows IS DISTINCT FROM (SELECT count(*) FROM msbf_m2.advance_daily_remittance_monitoring AS d WHERE d.module1_run_id=r.module1_run_id AND d.stress_status_floor_applied_flag)))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry AS r WHERE r.module1_run_id=(SELECT run_id FROM _m2_5_vctx) AND r.stress_status_floor_rows IS DISTINCT FROM (SELECT count(*) FROM msbf_m2.advance_daily_remittance_monitoring AS d WHERE d.module1_run_id=r.module1_run_id AND d.stress_status_floor_applied_flag))), FALSE),
        'Registry stress-floor count reconciles to daily rows.'
    );
END;
$m2_5_positive_controls$;

DO $m2_5_validation_finalize$
DECLARE
    v_total bigint;
    v_pass bigint;
    v_fail bigint;
BEGIN
    SELECT
        count(*),
        count(*) FILTER(WHERE status = 'PASS'),
        count(*) FILTER(WHERE status = 'FAIL')
    INTO v_total, v_pass, v_fail
    FROM _m2_5_validation;

    IF v_total <> 120 THEN
        RAISE EXCEPTION
            'M2.5 positive-control inventory failed: total %, expected 120.',
            v_total;
    END IF;

    INSERT INTO msbf_ctl.run_evidence
    (
        run_id,
        evidence_code,
        segment_key,
        metric_name,
        metric_value_numeric,
        metric_value_text,
        unit_code,
        status,
        interpretation
    )
    SELECT
        (SELECT run_id FROM _m2_5_vctx),
        validation.evidence_code,
        'PORTFOLIO',
        validation.metric_name,
        NULL::numeric(24,10),
        coalesce(validation.observed_value, '<NULL>'),
        'VALIDATION',
        validation.status,
        validation.interpretation ||
        ' Threshold: ' || coalesce(validation.threshold_value, '<NULL>')
    FROM _m2_5_validation AS validation
    ON CONFLICT(run_id, evidence_code, segment_key)
    DO UPDATE SET
        metric_name = EXCLUDED.metric_name,
        metric_value_numeric = NULL,
        metric_value_text = EXCLUDED.metric_value_text,
        unit_code = EXCLUDED.unit_code,
        status = EXCLUDED.status,
        interpretation = EXCLUDED.interpretation,
        created_at = clock_timestamp();

    IF v_pass = 120 AND v_fail = 0 THEN
        UPDATE msbf_ctl.run_registry
        SET run_status = 'M2_5_VALIDATED'
        WHERE run_id = (SELECT run_id FROM _m2_5_vctx);

        UPDATE msbf_ctl.m2_5_portfolio_monitoring_contract_registry
        SET
            contract_status = 'VALIDATED',
            validated_at = clock_timestamp()
        WHERE module1_run_id = (SELECT run_id FROM _m2_5_vctx);
    ELSE
        RAISE EXCEPTION
            'M2.5 positive validation failed: pass %, fail %.',
            v_pass,
            v_fail;
    END IF;
END;
$m2_5_validation_finalize$;

COMMIT;

SELECT
    validation.evidence_code,
    validation.metric_name,
    validation.observed_value,
    validation.threshold_value,
    validation.status,
    validation.interpretation
FROM _m2_5_validation AS validation
ORDER BY validation.evidence_code;
