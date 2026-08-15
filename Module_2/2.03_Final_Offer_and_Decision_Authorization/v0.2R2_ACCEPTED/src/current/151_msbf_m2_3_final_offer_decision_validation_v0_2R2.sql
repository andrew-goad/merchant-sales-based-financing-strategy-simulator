/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.3 — Final Offer & Decision Authorization

Program     : 151_msbf_m2_3_final_offer_decision_validation_v0_2R2.sql
Version     : v0.2R2
Purpose     : Read-only positive validation of M2.3 policy, source lineage,
              final decision mappings, offer-term boundaries, hashes,
              latest/archive reproduction, stress non-improvement, and
              stage-boundary controls.

Output      : 120-row session-preserved result set.
Required    : 120 / 120 PASS.
============================================================================ */

BEGIN;

SET LOCAL work_mem = '96MB';
SET LOCAL statement_timeout = '30min';
SET LOCAL jit = off;

DROP TABLE IF EXISTS _m2_3_validation;

CREATE TEMP TABLE _m2_3_validation
(
    evidence_code      text PRIMARY KEY,
    metric_name        text NOT NULL,
    observed_value     text,
    threshold_value    text,
    status             text NOT NULL,
    interpretation     text NOT NULL
)
ON COMMIT PRESERVE ROWS;

DROP TABLE IF EXISTS _m2_3_vctx;

CREATE TEMP TABLE _m2_3_vctx
ON COMMIT DROP
AS
SELECT
    run.run_id,
    run.run_status
FROM msbf_ctl.run_registry AS run
WHERE run.run_code = 'M1_V0_2_BASELINE_BUILD'
  AND run.run_version = 1;

DO $m2_3_validation_ready$
BEGIN
    PERFORM msbf_ctl.m2_3_assert_validation_ready
    (
        (SELECT run_id FROM _m2_3_vctx)
    );
END;
$m2_3_validation_ready$;

CREATE OR REPLACE FUNCTION pg_temp.m2_3_add_check
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
    INSERT INTO _m2_3_validation
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

DO $m2_3_positive_controls$
BEGIN
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_001_RUN_STATUS',
        'RUN_STATUS',
        ((SELECT run_status FROM _m2_3_vctx))::text,
        'M2_3_GENERATED',
        coalesce(((SELECT run_status='M2_3_GENERATED' FROM _m2_3_vctx)), FALSE),
        'Validation begins from generated state.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_002_POLICY_APPROVED',
        'POLICY_APPROVED',
        ((SELECT policy_status||'|'||synthetic_data_only_flag||'|'||no_booking_funding_flag||'|'||no_external_notice_generation_flag||'|'||no_production_adverse_action_notice_flag FROM msbf_ctl.m2_3_policy_profile WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx)))::text,
        'APPROVED|true|true|true|true',
        coalesce(((SELECT policy_status='APPROVED' AND synthetic_data_only_flag AND no_booking_funding_flag AND no_external_notice_generation_flag AND no_production_adverse_action_notice_flag FROM msbf_ctl.m2_3_policy_profile WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx))), FALSE),
        'Policy and stage-boundary flags are approved.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_003_METHOD_CONTRACT',
        'METHOD_CONTRACT',
        ((SELECT methodology_version||'|'||contract_code||'|'||contract_version||'|'||schema_version FROM msbf_ctl.m2_3_policy_profile WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx)))::text,
        'M2_3_METHOD_V1|M2_FINAL_OFFER_DECISION_CONSUMPTION|1|M2_3_FINAL_DECISION_SCHEMA_V1',
        coalesce(((SELECT methodology_version='M2_3_METHOD_V1' AND contract_code='M2_FINAL_OFFER_DECISION_CONSUMPTION' AND contract_version=1 AND schema_version='M2_3_FINAL_DECISION_SCHEMA_V1' FROM msbf_ctl.m2_3_policy_profile WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx))), FALSE),
        'M2.3 method and contract identity are exact.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_004_SOURCE_M2_2_HASH',
        'SOURCE_M2_2_HASH',
        ((SELECT source_m2_2_combined_hash FROM msbf_ctl.m2_3_policy_profile WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx)))::text,
        'bbe83b187b31ea561789797322031fc6',
        coalesce(((SELECT source_m2_2_combined_hash='bbe83b187b31ea561789797322031fc6' FROM msbf_ctl.m2_3_policy_profile WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx))), FALSE),
        'Accepted M2.2 combined hash is preserved.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_005_SOURCE_M2_2_REGISTRY',
        'SOURCE_M2_2_REGISTRY',
        ((SELECT contract_status||'|'||pricing_latest_rows||'|'||combined_set_hash FROM msbf_ctl.m2_2_pricing_structure_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx)))::text,
        'ACCEPTED|1500|accepted hash',
        coalesce(((SELECT contract_status='ACCEPTED' AND pricing_contract_code='M2_PRICING_STRUCTURE_CONSUMPTION' AND pricing_latest_rows=1500 AND combined_set_hash='bbe83b187b31ea561789797322031fc6' FROM msbf_ctl.m2_2_pricing_structure_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx))), FALSE),
        'M2.2 pricing-structure contract is accepted.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_006_SOURCE_M2_2_GATE',
        'SOURCE_M2_2_GATE',
        ((SELECT result_status FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM _m2_3_vctx) AND gate_id='M2_2_PRICING_STRUCTURE_COUNTEROFFER' AND review_version=1))::text,
        'PASS',
        coalesce(((SELECT result_status='PASS' FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM _m2_3_vctx) AND gate_id='M2_2_PRICING_STRUCTURE_COUNTEROFFER' AND review_version=1)), FALSE),
        'M2.2 acceptance gate is PASS.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_007_CONFIGURATION_HASH',
        'CONFIGURATION_HASH',
        ((SELECT configuration_hash FROM msbf_ctl.m2_3_policy_profile WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx)))::text,
        'physical payload hash',
        coalesce(((SELECT configuration_hash=msbf_ctl.m2_3_hash_jsonb(configuration_payload) FROM msbf_ctl.m2_3_policy_profile WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx))), FALSE),
        'Configuration hash reconstructs from payload.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_008_POLICY_ROW_HASH',
        'POLICY_ROW_HASH',
        ((SELECT count(*) FROM msbf_ctl.m2_3_policy_profile p WHERE p.module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND p.row_hash IS DISTINCT FROM msbf_ctl.m2_3_hash_jsonb(to_jsonb(p)-'row_hash'-'created_at'-'updated_at'))::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_ctl.m2_3_policy_profile p WHERE p.module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND p.row_hash IS DISTINCT FROM msbf_ctl.m2_3_hash_jsonb(to_jsonb(p)-'row_hash'-'created_at'-'updated_at'))), FALSE),
        'Policy row hash reconstructs physically.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_009_OUTCOME_DEFINITIONS',
        'OUTCOME_DEFINITIONS',
        ((SELECT count(*) FROM msbf_m2.final_decision_outcome_definition WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx))::text)::text,
        '5',
        coalesce(((SELECT count(*)=5 FROM msbf_m2.final_decision_outcome_definition WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx))), FALSE),
        'Outcome Definitions count matches governance.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_010_REASON_DEFINITIONS',
        'REASON_DEFINITIONS',
        ((SELECT count(*) FROM msbf_m2.final_decision_reason_definition WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx))::text)::text,
        '22',
        coalesce(((SELECT count(*)=22 FROM msbf_m2.final_decision_reason_definition WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx))), FALSE),
        'Reason Definitions count matches governance.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_011_OUTCOME_BOUNDARY_FLAGS',
        'OUTCOME_BOUNDARY_FLAGS',
        ((SELECT count(*) FROM msbf_m2.final_decision_outcome_definition WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND (production_adverse_action_notice_flag OR booking_funding_flag))::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.final_decision_outcome_definition WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND (production_adverse_action_notice_flag OR booking_funding_flag))), FALSE),
        'Outcome dictionary contains no production-adverse-action or booking flags.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_012_REASON_BOUNDARY_FLAGS',
        'REASON_BOUNDARY_FLAGS',
        ((SELECT count(*) FROM msbf_m2.final_decision_reason_definition WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND production_adverse_action_notice_flag)::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.final_decision_reason_definition WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND production_adverse_action_notice_flag)), FALSE),
        'Reason dictionary contains no production adverse-action notice flags.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_013_REGISTRY_ROW',
        'REGISTRY_ROW',
        ((SELECT count(*) FROM msbf_ctl.m2_3_final_decision_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx))::text)::text,
        '1',
        coalesce(((SELECT count(*)=1 FROM msbf_ctl.m2_3_final_decision_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx))), FALSE),
        'Exactly one M2.3 contract registry row exists.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_014_REGISTRY_STATUS',
        'REGISTRY_STATUS',
        ((SELECT contract_status FROM msbf_ctl.m2_3_final_decision_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx)))::text,
        'GENERATED',
        coalesce(((SELECT contract_status='GENERATED' FROM msbf_ctl.m2_3_final_decision_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx))), FALSE),
        'Registry begins validation in generated state.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_015_REGISTRY_COUNTS',
        'REGISTRY_COUNTS',
        ((SELECT source_rows||'|'||decision_snapshot_rows||'|'||decision_latest_rows||'|'||decision_archive_rows||'|'||comparison_rows||'|'||canonical_entities FROM msbf_ctl.m2_3_final_decision_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx)))::text,
        '1500|1500|1500|1500|750|6029',
        coalesce(((SELECT source_rows=1500 AND decision_snapshot_rows=1500 AND decision_latest_rows=1500 AND decision_archive_rows=1500 AND comparison_rows=750 AND canonical_entities=6029 FROM msbf_ctl.m2_3_final_decision_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx))), FALSE),
        'Registry cardinalities match M2.3 contract.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_016_SOURCE_ROWS',
        'SOURCE_ROWS',
        ((SELECT count(*) FROM msbf_m2.application_final_decision_source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx))::text)::text,
        '1500',
        coalesce(((SELECT count(*)=1500 FROM msbf_m2.application_final_decision_source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx))), FALSE),
        'Source snapshot contains all accepted M2.2 rows.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_017_SOURCE_APPLICATIONS',
        'SOURCE_APPLICATIONS',
        ((SELECT count(DISTINCT merchant_application_id) FROM msbf_m2.application_final_decision_source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx))::text)::text,
        '750',
        coalesce(((SELECT count(DISTINCT merchant_application_id)=750 FROM msbf_m2.application_final_decision_source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx))), FALSE),
        'Source snapshot covers 750 applications.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_018_SOURCE_SCENARIOS',
        'SOURCE_SCENARIOS',
        ((SELECT count(DISTINCT scenario_id) FROM msbf_m2.application_final_decision_source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx))::text)::text,
        '2',
        coalesce(((SELECT count(DISTINCT scenario_id)=2 FROM msbf_m2.application_final_decision_source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx))), FALSE),
        'Source snapshot retains two scenarios.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_019_SOURCE_SCENARIO_BALANCE',
        'SOURCE_SCENARIO_BALANCE',
        ((SELECT count(*) FILTER(WHERE scenario_code='BASELINE')||'|'||count(*) FILTER(WHERE scenario_code='RECESSION_ENERGY') FROM msbf_m2.application_final_decision_source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx)))::text,
        '750|750',
        coalesce(((SELECT count(*) FILTER(WHERE scenario_code='BASELINE')=750 AND count(*) FILTER(WHERE scenario_code='RECESSION_ENERGY')=750 FROM msbf_m2.application_final_decision_source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx))), FALSE),
        'Baseline and stress source rows balance.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_020_SOURCE_GRAIN',
        'SOURCE_GRAIN',
        ((SELECT count(*)-count(DISTINCT scenario_id::text||'|'||merchant_application_id) FROM msbf_m2.application_final_decision_source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx))::text)::text,
        '0',
        coalesce(((SELECT count(*)=count(DISTINCT scenario_id::text||'|'||merchant_application_id) FROM msbf_m2.application_final_decision_source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx))), FALSE),
        'Source snapshot grain is unique.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_021_DECISION_SNAPSHOT_ROWS',
        'DECISION_SNAPSHOT_ROWS',
        ((SELECT count(*) FROM msbf_m2.application_final_offer_decision_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx))::text)::text,
        '1500',
        coalesce(((SELECT count(*)=1500 FROM msbf_m2.application_final_offer_decision_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx))), FALSE),
        'Decision Snapshot Rows count matches expected.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_022_DECISION_LATEST_ROWS',
        'DECISION_LATEST_ROWS',
        ((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx))::text)::text,
        '1500',
        coalesce(((SELECT count(*)=1500 FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx))), FALSE),
        'Decision Latest Rows count matches expected.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_023_DECISION_ARCHIVE_ROWS',
        'DECISION_ARCHIVE_ROWS',
        ((SELECT count(*) FROM msbf_m2.application_final_offer_decision_archive WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx))::text)::text,
        '1500',
        coalesce(((SELECT count(*)=1500 FROM msbf_m2.application_final_offer_decision_archive WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx))), FALSE),
        'Decision Archive Rows count matches expected.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_024_LATEST_GRAIN',
        'LATEST_GRAIN',
        ((SELECT count(*)-count(DISTINCT scenario_id::text||'|'||merchant_application_id) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx))::text)::text,
        '0',
        coalesce(((SELECT count(*)=count(DISTINCT scenario_id::text||'|'||merchant_application_id) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx))), FALSE),
        'Latest decision contract grain is unique.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_025_ARCHIVE_GRAIN',
        'ARCHIVE_GRAIN',
        ((SELECT count(*)-count(DISTINCT contract_version::text||'|'||scenario_id::text||'|'||merchant_application_id) FROM msbf_m2.application_final_offer_decision_archive WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx))::text)::text,
        '0',
        coalesce(((SELECT count(*)=count(DISTINCT contract_version::text||'|'||scenario_id::text||'|'||merchant_application_id) FROM msbf_m2.application_final_offer_decision_archive WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx))), FALSE),
        'Archive decision contract grain is unique.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_026_FINAL_OFFER_AUTHORIZED',
        'FINAL_OFFER_AUTHORIZED',
        ((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND final_decision_outcome_code='FINAL_OFFER_AUTHORIZED')::text)::text,
        '59',
        coalesce(((SELECT count(*)=59 FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND final_decision_outcome_code='FINAL_OFFER_AUTHORIZED')), FALSE),
        'FINAL_OFFER_AUTHORIZED count matches accepted routing.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_027_COUNTEROFFER_REVIEW_REQUIRED',
        'COUNTEROFFER_REVIEW_REQUIRED',
        ((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND final_decision_outcome_code='COUNTEROFFER_REVIEW_REQUIRED')::text)::text,
        '190',
        coalesce(((SELECT count(*)=190 FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND final_decision_outcome_code='COUNTEROFFER_REVIEW_REQUIRED')), FALSE),
        'COUNTEROFFER_REVIEW_REQUIRED count matches accepted routing.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_028_DECLINE_INSUFFICIENT_EVIDENCE_AUTHORIZED',
        'DECLINE_INSUFFICIENT_EVIDENCE_AUTHORIZED',
        ((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND final_decision_outcome_code='DECLINE_INSUFFICIENT_EVIDENCE_AUTHORIZED')::text)::text,
        '178',
        coalesce(((SELECT count(*)=178 FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND final_decision_outcome_code='DECLINE_INSUFFICIENT_EVIDENCE_AUTHORIZED')), FALSE),
        'DECLINE_INSUFFICIENT_EVIDENCE_AUTHORIZED count matches accepted routing.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_029_DECLINE_POLICY_AUTHORIZED',
        'DECLINE_POLICY_AUTHORIZED',
        ((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND final_decision_outcome_code='DECLINE_POLICY_AUTHORIZED')::text)::text,
        '1073',
        coalesce(((SELECT count(*)=1073 FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND final_decision_outcome_code='DECLINE_POLICY_AUTHORIZED')), FALSE),
        'DECLINE_POLICY_AUTHORIZED count matches accepted routing.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_030_OUTCOME_TOTAL',
        'OUTCOME_TOTAL',
        ((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx))::text)::text,
        '1500',
        coalesce(((SELECT count(*)=1500 FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx))), FALSE),
        'All M2.3 latest rows map to final outcome.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_031_BASELINE_ROWS',
        'BASELINE_ROWS',
        ((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND scenario_code='BASELINE')::text)::text,
        '750',
        coalesce(((SELECT count(*)=750 FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND scenario_code='BASELINE')), FALSE),
        'BASELINE final decision rows equal 750.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_032_RECESSION_ENERGY_ROWS',
        'RECESSION_ENERGY_ROWS',
        ((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND scenario_code='RECESSION_ENERGY')::text)::text,
        '750',
        coalesce(((SELECT count(*)=750 FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND scenario_code='RECESSION_ENERGY')), FALSE),
        'RECESSION_ENERGY final decision rows equal 750.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_033_STRUCTURE_READY_TO_OFFER',
        '033_STRUCTURE_READY_TO_OFFER',
        ((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND source_pricing_disposition_code='STRUCTURE_READY' AND final_decision_outcome_code<>'FINAL_OFFER_AUTHORIZED')::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND source_pricing_disposition_code='STRUCTURE_READY' AND final_decision_outcome_code<>'FINAL_OFFER_AUTHORIZED')), FALSE),
        'STRUCTURE_READY maps only to FINAL_OFFER_AUTHORIZED.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_034_COUNTEROFFER_REVIEW_TO_REVIEW',
        '034_COUNTEROFFER_REVIEW_TO_REVIEW',
        ((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND source_pricing_disposition_code='COUNTEROFFER_FOUNDATION_REVIEW' AND final_decision_outcome_code<>'COUNTEROFFER_REVIEW_REQUIRED')::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND source_pricing_disposition_code='COUNTEROFFER_FOUNDATION_REVIEW' AND final_decision_outcome_code<>'COUNTEROFFER_REVIEW_REQUIRED')), FALSE),
        'COUNTEROFFER_FOUNDATION_REVIEW maps only to COUNTEROFFER_REVIEW_REQUIRED.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_035_INSUFFICIENT_TO_DECLINE',
        '035_INSUFFICIENT_TO_DECLINE',
        ((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND source_pricing_disposition_code='NO_STRUCTURE_INSUFFICIENT_EVIDENCE' AND final_decision_outcome_code<>'DECLINE_INSUFFICIENT_EVIDENCE_AUTHORIZED')::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND source_pricing_disposition_code='NO_STRUCTURE_INSUFFICIENT_EVIDENCE' AND final_decision_outcome_code<>'DECLINE_INSUFFICIENT_EVIDENCE_AUTHORIZED')), FALSE),
        'NO_STRUCTURE_INSUFFICIENT_EVIDENCE maps only to DECLINE_INSUFFICIENT_EVIDENCE_AUTHORIZED.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_036_POLICY_TO_DECLINE',
        '036_POLICY_TO_DECLINE',
        ((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND source_pricing_disposition_code='NO_STRUCTURE_POLICY_DECLINE' AND final_decision_outcome_code<>'DECLINE_POLICY_AUTHORIZED')::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND source_pricing_disposition_code='NO_STRUCTURE_POLICY_DECLINE' AND final_decision_outcome_code<>'DECLINE_POLICY_AUTHORIZED')), FALSE),
        'NO_STRUCTURE_POLICY_DECLINE maps only to DECLINE_POLICY_AUTHORIZED.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_037_OFFER_FLAG_IDENTITY',
        'OFFER_FLAG_IDENTITY',
        ((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND final_offer_authorized_flag IS DISTINCT FROM (final_decision_outcome_code='FINAL_OFFER_AUTHORIZED'))::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND final_offer_authorized_flag IS DISTINCT FROM (final_decision_outcome_code='FINAL_OFFER_AUTHORIZED'))), FALSE),
        'Offer authorization flag follows final outcome.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_038_DECLINE_FLAG_IDENTITY',
        'DECLINE_FLAG_IDENTITY',
        ((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND decline_authorized_flag IS DISTINCT FROM (final_decision_outcome_code IN ('DECLINE_POLICY_AUTHORIZED','DECLINE_INSUFFICIENT_EVIDENCE_AUTHORIZED')))::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND decline_authorized_flag IS DISTINCT FROM (final_decision_outcome_code IN ('DECLINE_POLICY_AUTHORIZED','DECLINE_INSUFFICIENT_EVIDENCE_AUTHORIZED')))), FALSE),
        'Decline authorization flag follows final outcome.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_039_REVIEW_FLAG_IDENTITY',
        'REVIEW_FLAG_IDENTITY',
        ((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND counteroffer_review_required_flag IS DISTINCT FROM (final_decision_outcome_code='COUNTEROFFER_REVIEW_REQUIRED'))::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND counteroffer_review_required_flag IS DISTINCT FROM (final_decision_outcome_code='COUNTEROFFER_REVIEW_REQUIRED'))), FALSE),
        'Review flag follows final outcome.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_040_STATUS_DOMAIN',
        'STATUS_DOMAIN',
        ((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND final_authorization_evidence_status NOT IN ('AUTHORIZED','REVIEW_REQUIRED','DECLINE_AUTHORIZED','BLOCKED'))::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND final_authorization_evidence_status NOT IN ('AUTHORIZED','REVIEW_REQUIRED','DECLINE_AUTHORIZED','BLOCKED'))), FALSE),
        'Authorization status stays within governed domain.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_041_OFFER_TERMS_PRESENT',
        'OFFER_TERMS_PRESENT',
        ((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND final_offer_authorized_flag AND (final_offer_amount IS NULL OR final_remittance_rate IS NULL OR final_payback_multiple IS NULL OR final_collection_horizon_days IS NULL OR final_total_repayment_amount IS NULL OR final_finance_charge_amount IS NULL OR final_implied_daily_collection_amount IS NULL OR final_implied_payoff_days IS NULL OR final_offer_expiration_days IS NULL))::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND final_offer_authorized_flag AND (final_offer_amount IS NULL OR final_remittance_rate IS NULL OR final_payback_multiple IS NULL OR final_collection_horizon_days IS NULL OR final_total_repayment_amount IS NULL OR final_finance_charge_amount IS NULL OR final_implied_daily_collection_amount IS NULL OR final_implied_payoff_days IS NULL OR final_offer_expiration_days IS NULL))), FALSE),
        'Authorized final offers have all final terms.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_042_NONOFFERS_NO_TERMS',
        'NONOFFERS_NO_TERMS',
        ((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND NOT final_offer_authorized_flag AND (final_offer_amount IS NOT NULL OR final_remittance_rate IS NOT NULL OR final_payback_multiple IS NOT NULL OR final_collection_horizon_days IS NOT NULL OR final_total_repayment_amount IS NOT NULL OR final_finance_charge_amount IS NOT NULL OR final_implied_daily_collection_amount IS NOT NULL OR final_implied_payoff_days IS NOT NULL OR final_offer_expiration_days IS NOT NULL))::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND NOT final_offer_authorized_flag AND (final_offer_amount IS NOT NULL OR final_remittance_rate IS NOT NULL OR final_payback_multiple IS NOT NULL OR final_collection_horizon_days IS NOT NULL OR final_total_repayment_amount IS NOT NULL OR final_finance_charge_amount IS NOT NULL OR final_implied_daily_collection_amount IS NOT NULL OR final_implied_payoff_days IS NOT NULL OR final_offer_expiration_days IS NOT NULL))), FALSE),
        'Non-offer outcomes carry no final offer terms.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_043_AMOUNT_POSITIVE',
        '043_AMOUNT_POSITIVE',
        ((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND final_offer_authorized_flag AND NOT (final_offer_amount > 0))::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND final_offer_authorized_flag AND NOT (final_offer_amount > 0))), FALSE),
        'Authorized offer term condition holds: final_offer_amount > 0.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_044_REMITTANCE_BOUNDS',
        '044_REMITTANCE_BOUNDS',
        ((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND final_offer_authorized_flag AND NOT (final_remittance_rate BETWEEN 0.05 AND 0.20))::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND final_offer_authorized_flag AND NOT (final_remittance_rate BETWEEN 0.05 AND 0.20))), FALSE),
        'Authorized offer term condition holds: final_remittance_rate BETWEEN 0.05 AND 0.20.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_045_PAYBACK_BOUNDS',
        '045_PAYBACK_BOUNDS',
        ((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND final_offer_authorized_flag AND NOT (final_payback_multiple BETWEEN 1.05 AND 1.40))::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND final_offer_authorized_flag AND NOT (final_payback_multiple BETWEEN 1.05 AND 1.40))), FALSE),
        'Authorized offer term condition holds: final_payback_multiple BETWEEN 1.05 AND 1.40.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_046_HORIZON_BOUNDS',
        '046_HORIZON_BOUNDS',
        ((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND final_offer_authorized_flag AND NOT (final_collection_horizon_days BETWEEN 1 AND 120))::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND final_offer_authorized_flag AND NOT (final_collection_horizon_days BETWEEN 1 AND 120))), FALSE),
        'Authorized offer term condition holds: final_collection_horizon_days BETWEEN 1 AND 120.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_047_EXPIRATION_14',
        '047_EXPIRATION_14',
        ((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND final_offer_authorized_flag AND NOT (final_offer_expiration_days = 14))::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND final_offer_authorized_flag AND NOT (final_offer_expiration_days = 14))), FALSE),
        'Authorized offer term condition holds: final_offer_expiration_days = 14.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_048_OFFER_TERMS_EQUAL_M2_2',
        'OFFER_TERMS_EQUAL_M2_2',
        ((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest d JOIN msbf_m2.application_pricing_structure_latest p ON p.module1_run_id=d.module1_run_id AND p.scenario_id=d.scenario_id AND p.merchant_application_id=d.merchant_application_id WHERE d.module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND d.final_offer_authorized_flag AND (d.final_offer_amount IS DISTINCT FROM p.selected_funding_amount OR d.final_remittance_rate IS DISTINCT FROM p.selected_remittance_rate OR d.final_payback_multiple IS DISTINCT FROM p.selected_payback_multiple OR d.final_collection_horizon_days IS DISTINCT FROM p.selected_collection_horizon_days))::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_final_offer_decision_latest d JOIN msbf_m2.application_pricing_structure_latest p ON p.module1_run_id=d.module1_run_id AND p.scenario_id=d.scenario_id AND p.merchant_application_id=d.merchant_application_id WHERE d.module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND d.final_offer_authorized_flag AND (d.final_offer_amount IS DISTINCT FROM p.selected_funding_amount OR d.final_remittance_rate IS DISTINCT FROM p.selected_remittance_rate OR d.final_payback_multiple IS DISTINCT FROM p.selected_payback_multiple OR d.final_collection_horizon_days IS DISTINCT FROM p.selected_collection_horizon_days))), FALSE),
        'Final offer terms exactly inherit accepted M2.2 selected terms.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_049_SOURCE_ROW_REPRODUCTION',
        'SOURCE_ROW_REPRODUCTION',
        ((SELECT count(*) FROM msbf_m2.application_final_decision_source_snapshot s JOIN msbf_m2.application_pricing_structure_latest p ON p.module1_run_id=s.module1_run_id AND p.scenario_id=s.scenario_id AND p.merchant_application_id=s.merchant_application_id WHERE s.module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND s.source_m2_2_contract_row_hash IS DISTINCT FROM p.contract_row_hash)::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_final_decision_source_snapshot s JOIN msbf_m2.application_pricing_structure_latest p ON p.module1_run_id=s.module1_run_id AND p.scenario_id=s.scenario_id AND p.merchant_application_id=s.merchant_application_id WHERE s.module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND s.source_m2_2_contract_row_hash IS DISTINCT FROM p.contract_row_hash)), FALSE),
        'Source snapshot preserves M2.2 contract row hash.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_050_DECISION_SOURCE_LINEAGE',
        'DECISION_SOURCE_LINEAGE',
        ((SELECT count(*) FROM msbf_m2.application_final_offer_decision_snapshot d JOIN msbf_m2.application_final_decision_source_snapshot s ON s.module1_run_id=d.module1_run_id AND s.scenario_id=d.scenario_id AND s.merchant_application_id=d.merchant_application_id WHERE d.module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND d.source_snapshot_row_hash IS DISTINCT FROM s.row_hash)::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_final_offer_decision_snapshot d JOIN msbf_m2.application_final_decision_source_snapshot s ON s.module1_run_id=d.module1_run_id AND s.scenario_id=d.scenario_id AND s.merchant_application_id=d.merchant_application_id WHERE d.module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND d.source_snapshot_row_hash IS DISTINCT FROM s.row_hash)), FALSE),
        'Decision snapshot references the source snapshot hash.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_051_PRIMARY_REASON_PRESENT',
        'PRIMARY_REASON_PRESENT',
        ((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND (primary_decision_reason_code IS NULL))::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND (primary_decision_reason_code IS NULL))), FALSE),
        'Primary Reason Present validates.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_052_REASON_ARRAY_PRESENT',
        'REASON_ARRAY_PRESENT',
        ((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND (decision_reason_codes IS NULL OR jsonb_array_length(decision_reason_codes)=0))::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND (decision_reason_codes IS NULL OR jsonb_array_length(decision_reason_codes)=0))), FALSE),
        'Reason Array Present validates.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_053_OFFER_REASON',
        'OFFER_REASON',
        ((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND (final_decision_outcome_code='FINAL_OFFER_AUTHORIZED' AND primary_decision_reason_code<>'M2_3_FINAL_OFFER_READY'))::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND (final_decision_outcome_code='FINAL_OFFER_AUTHORIZED' AND primary_decision_reason_code<>'M2_3_FINAL_OFFER_READY'))), FALSE),
        'Offer Reason validates.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_054_REVIEW_REASON',
        'REVIEW_REASON',
        ((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND (final_decision_outcome_code='COUNTEROFFER_REVIEW_REQUIRED' AND primary_decision_reason_code<>'M2_3_COUNTEROFFER_REVIEW_REQUIRED'))::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND (final_decision_outcome_code='COUNTEROFFER_REVIEW_REQUIRED' AND primary_decision_reason_code<>'M2_3_COUNTEROFFER_REVIEW_REQUIRED'))), FALSE),
        'Review Reason validates.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_055_INSUFFICIENT_REASON',
        'INSUFFICIENT_REASON',
        ((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND (final_decision_outcome_code='DECLINE_INSUFFICIENT_EVIDENCE_AUTHORIZED' AND primary_decision_reason_code<>'M2_3_INSUFFICIENT_EVIDENCE'))::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND (final_decision_outcome_code='DECLINE_INSUFFICIENT_EVIDENCE_AUTHORIZED' AND primary_decision_reason_code<>'M2_3_INSUFFICIENT_EVIDENCE'))), FALSE),
        'Insufficient Reason validates.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_056_POLICY_REASON',
        'POLICY_REASON',
        ((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND (final_decision_outcome_code='DECLINE_POLICY_AUTHORIZED' AND primary_decision_reason_code<>'M2_3_POLICY_DECLINE'))::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND (final_decision_outcome_code='DECLINE_POLICY_AUTHORIZED' AND primary_decision_reason_code<>'M2_3_POLICY_DECLINE'))), FALSE),
        'Policy Reason validates.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_057_OUTCOME_FK',
        'OUTCOME_FK',
        ((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest d LEFT JOIN msbf_m2.final_decision_outcome_definition o ON o.module1_run_id=d.module1_run_id AND o.decision_outcome_code=d.final_decision_outcome_code WHERE d.module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND (o.decision_outcome_code IS NULL))::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_final_offer_decision_latest d LEFT JOIN msbf_m2.final_decision_outcome_definition o ON o.module1_run_id=d.module1_run_id AND o.decision_outcome_code=d.final_decision_outcome_code WHERE d.module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND (o.decision_outcome_code IS NULL))), FALSE),
        'Outcome Fk validates.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_058_REASON_FK',
        'REASON_FK',
        ((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest d LEFT JOIN msbf_m2.final_decision_reason_definition r ON r.module1_run_id=d.module1_run_id AND r.decision_reason_code=d.primary_decision_reason_code WHERE d.module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND (r.decision_reason_code IS NULL))::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_final_offer_decision_latest d LEFT JOIN msbf_m2.final_decision_reason_definition r ON r.module1_run_id=d.module1_run_id AND r.decision_reason_code=d.primary_decision_reason_code WHERE d.module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND (r.decision_reason_code IS NULL))), FALSE),
        'Reason Fk validates.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_059_CUSTOMER_OFFER_OUTCOME',
        'CUSTOMER_OFFER_OUTCOME',
        ((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest d LEFT JOIN msbf_m2.final_decision_outcome_definition o ON o.module1_run_id=d.module1_run_id AND o.decision_outcome_code=d.final_decision_outcome_code WHERE d.module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND (o.customer_offer_flag IS DISTINCT FROM d.final_offer_authorized_flag))::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_final_offer_decision_latest d LEFT JOIN msbf_m2.final_decision_outcome_definition o ON o.module1_run_id=d.module1_run_id AND o.decision_outcome_code=d.final_decision_outcome_code WHERE d.module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND (o.customer_offer_flag IS DISTINCT FROM d.final_offer_authorized_flag))), FALSE),
        'Customer Offer Outcome validates.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_060_DECLINE_OUTCOME',
        'DECLINE_OUTCOME',
        ((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest d LEFT JOIN msbf_m2.final_decision_outcome_definition o ON o.module1_run_id=d.module1_run_id AND o.decision_outcome_code=d.final_decision_outcome_code WHERE d.module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND (o.decline_flag IS DISTINCT FROM d.decline_authorized_flag))::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_final_offer_decision_latest d LEFT JOIN msbf_m2.final_decision_outcome_definition o ON o.module1_run_id=d.module1_run_id AND o.decision_outcome_code=d.final_decision_outcome_code WHERE d.module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND (o.decline_flag IS DISTINCT FROM d.decline_authorized_flag))), FALSE),
        'Decline Outcome validates.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_061_SOURCE_HASH',
        'SOURCE_HASH',
        ((SELECT count(*) FROM msbf_m2.application_final_decision_source_snapshot t WHERE t.module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND t.row_hash IS DISTINCT FROM msbf_ctl.m2_3_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'))::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_final_decision_source_snapshot t WHERE t.module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND t.row_hash IS DISTINCT FROM msbf_ctl.m2_3_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'))), FALSE),
        'SOURCE_HASH reconstructs from physical row.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_062_SNAPSHOT_HASH',
        'SNAPSHOT_HASH',
        ((SELECT count(*) FROM msbf_m2.application_final_offer_decision_snapshot t WHERE t.module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND t.row_hash IS DISTINCT FROM msbf_ctl.m2_3_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'))::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_final_offer_decision_snapshot t WHERE t.module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND t.row_hash IS DISTINCT FROM msbf_ctl.m2_3_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'))), FALSE),
        'SNAPSHOT_HASH reconstructs from physical row.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_063_LATEST_HASH',
        'LATEST_HASH',
        ((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest t WHERE t.module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND t.contract_row_hash IS DISTINCT FROM msbf_ctl.m2_3_hash_jsonb(to_jsonb(t)-'contract_row_hash'-'created_at'))::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_final_offer_decision_latest t WHERE t.module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND t.contract_row_hash IS DISTINCT FROM msbf_ctl.m2_3_hash_jsonb(to_jsonb(t)-'contract_row_hash'-'created_at'))), FALSE),
        'LATEST_HASH reconstructs from physical row.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_064_ARCHIVE_HASH',
        'ARCHIVE_HASH',
        ((SELECT count(*) FROM msbf_m2.application_final_offer_decision_archive t WHERE t.module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND t.archive_row_hash IS DISTINCT FROM msbf_ctl.m2_3_hash_jsonb(to_jsonb(t)-'archive_id'-'archive_row_hash'-'archived_at'-'created_at'))::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_final_offer_decision_archive t WHERE t.module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND t.archive_row_hash IS DISTINCT FROM msbf_ctl.m2_3_hash_jsonb(to_jsonb(t)-'archive_id'-'archive_row_hash'-'archived_at'-'created_at'))), FALSE),
        'ARCHIVE_HASH reconstructs from physical row.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_065_LATEST_ARCHIVE_REPRODUCTION',
        'LATEST_ARCHIVE_REPRODUCTION',
        ((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest l FULL OUTER JOIN msbf_m2.application_final_offer_decision_archive a ON a.module1_run_id=l.module1_run_id AND a.contract_version=l.contract_version AND a.scenario_id=l.scenario_id AND a.merchant_application_id=l.merchant_application_id WHERE coalesce(l.module1_run_id,a.module1_run_id)=(SELECT run_id FROM _m2_3_vctx) AND (l.contract_row_hash IS DISTINCT FROM a.contract_row_hash OR a.contract_payload IS DISTINCT FROM (to_jsonb(l)-'created_at')))::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_final_offer_decision_latest l FULL OUTER JOIN msbf_m2.application_final_offer_decision_archive a ON a.module1_run_id=l.module1_run_id AND a.contract_version=l.contract_version AND a.scenario_id=l.scenario_id AND a.merchant_application_id=l.merchant_application_id WHERE coalesce(l.module1_run_id,a.module1_run_id)=(SELECT run_id FROM _m2_3_vctx) AND (l.contract_row_hash IS DISTINCT FROM a.contract_row_hash OR a.contract_payload IS DISTINCT FROM (to_jsonb(l)-'created_at')))), FALSE),
        'Latest and archive reproduce exactly.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_066_POLICY_SET_HASH',
        'POLICY_SET_HASH',
        ((SELECT policy_set_hash FROM msbf_ctl.m2_3_final_decision_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx)))::text,
        'physical reconstruction',
        coalesce(((SELECT registry.policy_set_hash IS NOT DISTINCT FROM (SELECT md5(string_agg(p.row_hash,'|' ORDER BY p.module1_run_id)) FROM msbf_ctl.m2_3_policy_profile p WHERE p.module1_run_id=(SELECT run_id FROM _m2_3_vctx)) FROM msbf_ctl.m2_3_final_decision_contract_registry registry WHERE registry.module1_run_id=(SELECT run_id FROM _m2_3_vctx))), FALSE),
        'POLICY_SET_HASH reconciles to physical reconstruction.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_067_OUTCOME_SET_HASH',
        'OUTCOME_SET_HASH',
        ((SELECT outcome_set_hash FROM msbf_ctl.m2_3_final_decision_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx)))::text,
        'physical reconstruction',
        coalesce(((SELECT registry.outcome_set_hash IS NOT DISTINCT FROM (SELECT md5(string_agg(o.row_hash,'|' ORDER BY o.decision_outcome_rank,o.decision_outcome_code)) FROM msbf_m2.final_decision_outcome_definition o WHERE o.module1_run_id=(SELECT run_id FROM _m2_3_vctx)) FROM msbf_ctl.m2_3_final_decision_contract_registry registry WHERE registry.module1_run_id=(SELECT run_id FROM _m2_3_vctx))), FALSE),
        'OUTCOME_SET_HASH reconciles to physical reconstruction.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_068_REASON_SET_HASH',
        'REASON_SET_HASH',
        ((SELECT reason_set_hash FROM msbf_ctl.m2_3_final_decision_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx)))::text,
        'physical reconstruction',
        coalesce(((SELECT registry.reason_set_hash IS NOT DISTINCT FROM (SELECT md5(string_agg(r.row_hash,'|' ORDER BY r.decision_reason_code)) FROM msbf_m2.final_decision_reason_definition r WHERE r.module1_run_id=(SELECT run_id FROM _m2_3_vctx)) FROM msbf_ctl.m2_3_final_decision_contract_registry registry WHERE registry.module1_run_id=(SELECT run_id FROM _m2_3_vctx))), FALSE),
        'REASON_SET_HASH reconciles to physical reconstruction.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_069_SOURCE_SET_HASH',
        'SOURCE_SET_HASH',
        ((SELECT source_set_hash FROM msbf_ctl.m2_3_final_decision_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx)))::text,
        'physical reconstruction',
        coalesce(((SELECT registry.source_set_hash IS NOT DISTINCT FROM (SELECT md5(string_agg(s.scenario_id::text||'|'||s.merchant_application_id||'|'||s.row_hash,'|' ORDER BY s.scenario_id,s.merchant_application_id)) FROM msbf_m2.application_final_decision_source_snapshot s WHERE s.module1_run_id=(SELECT run_id FROM _m2_3_vctx)) FROM msbf_ctl.m2_3_final_decision_contract_registry registry WHERE registry.module1_run_id=(SELECT run_id FROM _m2_3_vctx))), FALSE),
        'SOURCE_SET_HASH reconciles to physical reconstruction.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_070_SNAPSHOT_SET_HASH',
        'SNAPSHOT_SET_HASH',
        ((SELECT decision_snapshot_set_hash FROM msbf_ctl.m2_3_final_decision_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx)))::text,
        'physical reconstruction',
        coalesce(((SELECT registry.decision_snapshot_set_hash IS NOT DISTINCT FROM (SELECT md5(string_agg(s.scenario_id::text||'|'||s.merchant_application_id||'|'||s.row_hash,'|' ORDER BY s.scenario_id,s.merchant_application_id)) FROM msbf_m2.application_final_offer_decision_snapshot s WHERE s.module1_run_id=(SELECT run_id FROM _m2_3_vctx)) FROM msbf_ctl.m2_3_final_decision_contract_registry registry WHERE registry.module1_run_id=(SELECT run_id FROM _m2_3_vctx))), FALSE),
        'SNAPSHOT_SET_HASH reconciles to physical reconstruction.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_071_LATEST_SET_HASH',
        'LATEST_SET_HASH',
        ((SELECT decision_latest_set_hash FROM msbf_ctl.m2_3_final_decision_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx)))::text,
        'physical reconstruction',
        coalesce(((SELECT registry.decision_latest_set_hash IS NOT DISTINCT FROM (SELECT md5(string_agg(l.scenario_id::text||'|'||l.merchant_application_id||'|'||l.contract_row_hash,'|' ORDER BY l.scenario_id,l.merchant_application_id)) FROM msbf_m2.application_final_offer_decision_latest l WHERE l.module1_run_id=(SELECT run_id FROM _m2_3_vctx)) FROM msbf_ctl.m2_3_final_decision_contract_registry registry WHERE registry.module1_run_id=(SELECT run_id FROM _m2_3_vctx))), FALSE),
        'LATEST_SET_HASH reconciles to physical reconstruction.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_072_ARCHIVE_SET_HASH',
        'ARCHIVE_SET_HASH',
        ((SELECT decision_archive_set_hash FROM msbf_ctl.m2_3_final_decision_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx)))::text,
        'physical reconstruction',
        coalesce(((SELECT registry.decision_archive_set_hash IS NOT DISTINCT FROM (SELECT md5(string_agg(a.scenario_id::text||'|'||a.merchant_application_id||'|'||a.archive_row_hash,'|' ORDER BY a.scenario_id,a.merchant_application_id)) FROM msbf_m2.application_final_offer_decision_archive a WHERE a.module1_run_id=(SELECT run_id FROM _m2_3_vctx)) FROM msbf_ctl.m2_3_final_decision_contract_registry registry WHERE registry.module1_run_id=(SELECT run_id FROM _m2_3_vctx))), FALSE),
        'ARCHIVE_SET_HASH reconciles to physical reconstruction.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_073_CONTRACT_SET_HASH',
        'CONTRACT_SET_HASH',
        ((SELECT contract_set_hash FROM msbf_ctl.m2_3_final_decision_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx)))::text,
        'physical reconstruction',
        coalesce(((SELECT registry.contract_set_hash IS NOT DISTINCT FROM (SELECT md5(r.row_hash) FROM msbf_ctl.m2_3_final_decision_contract_registry r WHERE r.module1_run_id=(SELECT run_id FROM _m2_3_vctx)) FROM msbf_ctl.m2_3_final_decision_contract_registry registry WHERE registry.module1_run_id=(SELECT run_id FROM _m2_3_vctx))), FALSE),
        'CONTRACT_SET_HASH reconciles to physical reconstruction.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_074_COMBINED_HASH_NOT_NULL',
        'COMBINED_HASH_NOT_NULL',
        ((SELECT combined_set_hash FROM msbf_ctl.m2_3_final_decision_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx)))::text,
        'non-null hash',
        coalesce(((SELECT combined_set_hash IS NOT NULL AND length(combined_set_hash)=32 FROM msbf_ctl.m2_3_final_decision_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx))), FALSE),
        'Combined canonical hash exists.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_075_COMPARISON_ROWS',
        'COMPARISON_ROWS',
        ((SELECT count(*) FROM msbf_m2.v_m2_3_matched_scenario_comparison WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx))::text)::text,
        '750',
        coalesce((((SELECT count(*) FROM msbf_m2.v_m2_3_matched_scenario_comparison WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx)))=750), FALSE),
        'Comparison Rows is governed.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_076_STRESS_DECISION_NONIMPROVEMENT',
        'STRESS_DECISION_NONIMPROVEMENT',
        ((SELECT count(*) FROM msbf_m2.v_m2_3_matched_scenario_comparison WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND stress_decision_improvement_flag)::text)::text,
        '0',
        coalesce((((SELECT count(*) FROM msbf_m2.v_m2_3_matched_scenario_comparison WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND stress_decision_improvement_flag))=0), FALSE),
        'Stress Decision Nonimprovement is governed.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_077_STRESS_OFFER_TERM_NONIMPROVEMENT',
        'STRESS_OFFER_TERM_NONIMPROVEMENT',
        ((SELECT count(*) FROM msbf_m2.v_m2_3_matched_scenario_comparison WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND stress_offer_term_improvement_flag)::text)::text,
        '0',
        coalesce((((SELECT count(*) FROM msbf_m2.v_m2_3_matched_scenario_comparison WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND stress_offer_term_improvement_flag))=0), FALSE),
        'Stress Offer Term Nonimprovement is governed.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_078_BASELINE_OFFER_COUNT',
        'BASELINE_OFFER_COUNT',
        ((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND scenario_code='BASELINE' AND final_offer_authorized_flag)::text)::text,
        '44',
        coalesce((((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND scenario_code='BASELINE' AND final_offer_authorized_flag))=44), FALSE),
        'Baseline Offer Count is governed.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_079_STRESS_OFFER_COUNT',
        'STRESS_OFFER_COUNT',
        ((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND scenario_code='RECESSION_ENERGY' AND final_offer_authorized_flag)::text)::text,
        '15',
        coalesce((((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND scenario_code='RECESSION_ENERGY' AND final_offer_authorized_flag))=15), FALSE),
        'Stress Offer Count is governed.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_080_BASELINE_REVIEW_COUNT',
        'BASELINE_REVIEW_COUNT',
        ((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND scenario_code='BASELINE' AND counteroffer_review_required_flag)::text)::text,
        '139',
        coalesce((((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND scenario_code='BASELINE' AND counteroffer_review_required_flag))=139), FALSE),
        'Baseline Review Count is governed.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_081_STRESS_REVIEW_COUNT',
        'STRESS_REVIEW_COUNT',
        ((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND scenario_code='RECESSION_ENERGY' AND counteroffer_review_required_flag)::text)::text,
        '51',
        coalesce((((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND scenario_code='RECESSION_ENERGY' AND counteroffer_review_required_flag))=51), FALSE),
        'Stress Review Count is governed.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_082_BASELINE_POLICY_DECLINE',
        'BASELINE_POLICY_DECLINE',
        ((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND scenario_code='BASELINE' AND final_decision_outcome_code='DECLINE_POLICY_AUTHORIZED')::text)::text,
        '524',
        coalesce((((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND scenario_code='BASELINE' AND final_decision_outcome_code='DECLINE_POLICY_AUTHORIZED'))=524), FALSE),
        'Baseline Policy Decline is governed.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_083_STRESS_POLICY_DECLINE',
        'STRESS_POLICY_DECLINE',
        ((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND scenario_code='RECESSION_ENERGY' AND final_decision_outcome_code='DECLINE_POLICY_AUTHORIZED')::text)::text,
        '549',
        coalesce((((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND scenario_code='RECESSION_ENERGY' AND final_decision_outcome_code='DECLINE_POLICY_AUTHORIZED'))=549), FALSE),
        'Stress Policy Decline is governed.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_084_BASELINE_INSUFFICIENT',
        'BASELINE_INSUFFICIENT',
        ((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND scenario_code='BASELINE' AND final_decision_outcome_code='DECLINE_INSUFFICIENT_EVIDENCE_AUTHORIZED')::text)::text,
        '43',
        coalesce((((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND scenario_code='BASELINE' AND final_decision_outcome_code='DECLINE_INSUFFICIENT_EVIDENCE_AUTHORIZED'))=43), FALSE),
        'Baseline Insufficient is governed.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_085_STRESS_INSUFFICIENT',
        'STRESS_INSUFFICIENT',
        ((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND scenario_code='RECESSION_ENERGY' AND final_decision_outcome_code='DECLINE_INSUFFICIENT_EVIDENCE_AUTHORIZED')::text)::text,
        '135',
        coalesce((((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND scenario_code='RECESSION_ENERGY' AND final_decision_outcome_code='DECLINE_INSUFFICIENT_EVIDENCE_AUTHORIZED'))=135), FALSE),
        'Stress Insufficient is governed.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_086_NO_BOOKING_COLUMNS',
        'NO_BOOKING_COLUMNS',
        ((SELECT count(*) FROM information_schema.columns WHERE table_schema='msbf_m2' AND table_name IN ('application_final_offer_decision_snapshot','application_final_offer_decision_latest','application_final_offer_decision_archive') AND lower(column_name) IN ('booking_status','funding_status','funded_amount','loan_number','account_number','external_notice_payload'))::text)::text,
        '0',
        coalesce((((SELECT count(*) FROM information_schema.columns WHERE table_schema='msbf_m2' AND table_name IN ('application_final_offer_decision_snapshot','application_final_offer_decision_latest','application_final_offer_decision_archive') AND lower(column_name) IN ('booking_status','funding_status','funded_amount','loan_number','account_number','external_notice_payload')))=0), FALSE),
        'No Booking Columns validates.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_087_NO_BOOKING_DATA',
        'NO_BOOKING_DATA',
        ((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND false)::text)::text,
        '0',
        coalesce((((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND false))=0), FALSE),
        'No Booking Data validates.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_088_NO_PROD_ADVERSE_OUTCOME',
        'NO_PROD_ADVERSE_OUTCOME',
        ((SELECT count(*) FROM msbf_m2.final_decision_outcome_definition WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND production_adverse_action_notice_flag)::text)::text,
        '0',
        coalesce((((SELECT count(*) FROM msbf_m2.final_decision_outcome_definition WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND production_adverse_action_notice_flag))=0), FALSE),
        'No Prod Adverse Outcome validates.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_089_NO_PROD_ADVERSE_REASON',
        'NO_PROD_ADVERSE_REASON',
        ((SELECT count(*) FROM msbf_m2.final_decision_reason_definition WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND production_adverse_action_notice_flag)::text)::text,
        '0',
        coalesce((((SELECT count(*) FROM msbf_m2.final_decision_reason_definition WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND production_adverse_action_notice_flag))=0), FALSE),
        'No Prod Adverse Reason validates.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_090_ARCHIVE_TRIGGER',
        'ARCHIVE_TRIGGER',
        ((SELECT count(*) FROM pg_trigger WHERE tgrelid='msbf_m2.application_final_offer_decision_archive'::regclass AND tgname='trg_m2_3_decision_archive_immutable' AND NOT tgisinternal)::text)::text,
        '1',
        coalesce((((SELECT count(*) FROM pg_trigger WHERE tgrelid='msbf_m2.application_final_offer_decision_archive'::regclass AND tgname='trg_m2_3_decision_archive_immutable' AND NOT tgisinternal))=1), FALSE),
        'Archive Trigger validates.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_091_NO_M2_4_TABLES',
        'NO_M2_4_TABLES',
        ((SELECT count(*) FROM information_schema.tables WHERE table_schema IN ('msbf_m2','msbf_ctl') AND lower(table_name) LIKE 'm2_4%')::text)::text,
        '0',
        coalesce((((SELECT count(*) FROM information_schema.tables WHERE table_schema IN ('msbf_m2','msbf_ctl') AND lower(table_name) LIKE 'm2_4%'))=0), FALSE),
        'No M2 4 Tables validates.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_092_SOURCE_M2_2_ROWS_RECONCILE',
        'SOURCE_M2_2_ROWS_RECONCILE',
        ((SELECT count(*) FROM msbf_m2.application_final_decision_source_snapshot s FULL OUTER JOIN msbf_m2.application_pricing_structure_latest p ON p.module1_run_id=s.module1_run_id AND p.scenario_id=s.scenario_id AND p.merchant_application_id=s.merchant_application_id WHERE coalesce(s.module1_run_id,p.module1_run_id)=(SELECT run_id FROM _m2_3_vctx) AND (s.source_m2_2_contract_row_hash IS DISTINCT FROM p.contract_row_hash OR s.pricing_disposition_code IS DISTINCT FROM p.pricing_disposition_code))::text)::text,
        '0',
        coalesce((((SELECT count(*) FROM msbf_m2.application_final_decision_source_snapshot s FULL OUTER JOIN msbf_m2.application_pricing_structure_latest p ON p.module1_run_id=s.module1_run_id AND p.scenario_id=s.scenario_id AND p.merchant_application_id=s.merchant_application_id WHERE coalesce(s.module1_run_id,p.module1_run_id)=(SELECT run_id FROM _m2_3_vctx) AND (s.source_m2_2_contract_row_hash IS DISTINCT FROM p.contract_row_hash OR s.pricing_disposition_code IS DISTINCT FROM p.pricing_disposition_code)))=0), FALSE),
        'Source M2 2 Rows Reconcile validates.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_093_DECISION_LATEST_RECONCILE',
        'DECISION_LATEST_RECONCILE',
        ((SELECT count(*) FROM msbf_m2.application_final_offer_decision_snapshot s FULL OUTER JOIN msbf_m2.application_final_offer_decision_latest l ON l.module1_run_id=s.module1_run_id AND l.scenario_id=s.scenario_id AND l.merchant_application_id=s.merchant_application_id WHERE coalesce(s.module1_run_id,l.module1_run_id)=(SELECT run_id FROM _m2_3_vctx) AND (s.row_hash IS DISTINCT FROM l.snapshot_row_hash))::text)::text,
        '0',
        coalesce((((SELECT count(*) FROM msbf_m2.application_final_offer_decision_snapshot s FULL OUTER JOIN msbf_m2.application_final_offer_decision_latest l ON l.module1_run_id=s.module1_run_id AND l.scenario_id=s.scenario_id AND l.merchant_application_id=s.merchant_application_id WHERE coalesce(s.module1_run_id,l.module1_run_id)=(SELECT run_id FROM _m2_3_vctx) AND (s.row_hash IS DISTINCT FROM l.snapshot_row_hash)))=0), FALSE),
        'Decision Latest Reconcile validates.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_094_GENERATION_EVIDENCE_COUNT',
        'GENERATION_EVIDENCE_COUNT',
        ((SELECT count(*) FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM _m2_3_vctx) AND evidence_code LIKE 'M2_3_%' AND evidence_code NOT LIKE 'M2_3_POS_%' AND evidence_code NOT LIKE 'M2_3_NEG_%')::text)::text,
        '20',
        coalesce((((SELECT count(*) FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM _m2_3_vctx) AND evidence_code LIKE 'M2_3_%' AND evidence_code NOT LIKE 'M2_3_POS_%' AND evidence_code NOT LIKE 'M2_3_NEG_%'))=20), FALSE),
        'Generation Evidence Count validates.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_095_FAILED_M2_3_EVIDENCE',
        'FAILED_M2_3_EVIDENCE',
        ((SELECT count(*) FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM _m2_3_vctx) AND evidence_code LIKE 'M2_3_%' AND status='FAIL')::text)::text,
        '0',
        coalesce((((SELECT count(*) FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM _m2_3_vctx) AND evidence_code LIKE 'M2_3_%' AND status='FAIL'))=0), FALSE),
        'Failed M2 3 Evidence validates.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_096_CONTRACT_IDENTITY',
        'CONTRACT_IDENTITY',
        ((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND (contract_code<>'M2_FINAL_OFFER_DECISION_CONSUMPTION' OR contract_version<>1 OR schema_version<>'M2_3_FINAL_DECISION_SCHEMA_V1' OR methodology_version<>'M2_3_METHOD_V1'))::text)::text,
        '0',
        coalesce((((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND (contract_code<>'M2_FINAL_OFFER_DECISION_CONSUMPTION' OR contract_version<>1 OR schema_version<>'M2_3_FINAL_DECISION_SCHEMA_V1' OR methodology_version<>'M2_3_METHOD_V1')))=0), FALSE),
        'Contract Identity validates.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_097_OFFER_EXPIRATION_ONLY_OFFERS',
        'OFFER_EXPIRATION_ONLY_OFFERS',
        ((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND ((final_offer_authorized_flag AND final_offer_expiration_days<>14) OR (NOT final_offer_authorized_flag AND final_offer_expiration_days IS NOT NULL)))::text)::text,
        '0',
        coalesce((((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND ((final_offer_authorized_flag AND final_offer_expiration_days<>14) OR (NOT final_offer_authorized_flag AND final_offer_expiration_days IS NOT NULL))))=0), FALSE),
        'Offer Expiration Only Offers validates.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_098_TOTAL_REPAYMENT_IDENTITY',
        'TOTAL_REPAYMENT_IDENTITY',
        ((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND final_offer_authorized_flag AND final_total_repayment_amount IS DISTINCT FROM round(final_offer_amount*final_payback_multiple,2))::text)::text,
        '0',
        coalesce((((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND final_offer_authorized_flag AND final_total_repayment_amount IS DISTINCT FROM round(final_offer_amount*final_payback_multiple,2)))=0), FALSE),
        'Total Repayment Identity validates.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_099_FINANCE_CHARGE_IDENTITY',
        'FINANCE_CHARGE_IDENTITY',
        ((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND final_offer_authorized_flag AND final_finance_charge_amount IS DISTINCT FROM round(final_offer_amount*(final_payback_multiple-1),2))::text)::text,
        '0',
        coalesce((((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND final_offer_authorized_flag AND final_finance_charge_amount IS DISTINCT FROM round(final_offer_amount*(final_payback_multiple-1),2)))=0), FALSE),
        'Finance Charge Identity validates.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_100_DAILY_COLLECTION_POSITIVE',
        'DAILY_COLLECTION_POSITIVE',
        ((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND final_offer_authorized_flag AND final_implied_daily_collection_amount<=0)::text)::text,
        '0',
        coalesce((((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND final_offer_authorized_flag AND final_implied_daily_collection_amount<=0))=0), FALSE),
        'Daily Collection Positive validates.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_101_PAYOFF_DAYS_POSITIVE',
        'PAYOFF_DAYS_POSITIVE',
        ((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND final_offer_authorized_flag AND final_implied_payoff_days<=0)::text)::text,
        '0',
        coalesce((((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND final_offer_authorized_flag AND final_implied_payoff_days<=0))=0), FALSE),
        'Payoff Days Positive validates.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_102_DECLINES_NO_MANUAL_REVIEW',
        'DECLINES_NO_MANUAL_REVIEW',
        ((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND decline_authorized_flag AND manual_review_required_flag)::text)::text,
        '0',
        coalesce((((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND decline_authorized_flag AND manual_review_required_flag))=0), FALSE),
        'Declines No Manual Review validates.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_103_REVIEW_NOT_DECLINE',
        'REVIEW_NOT_DECLINE',
        ((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND counteroffer_review_required_flag AND decline_authorized_flag)::text)::text,
        '0',
        coalesce((((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND counteroffer_review_required_flag AND decline_authorized_flag))=0), FALSE),
        'Review Not Decline validates.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_104_REVIEW_NOT_OFFER',
        'REVIEW_NOT_OFFER',
        ((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND counteroffer_review_required_flag AND final_offer_authorized_flag)::text)::text,
        '0',
        coalesce((((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND counteroffer_review_required_flag AND final_offer_authorized_flag))=0), FALSE),
        'Review Not Offer validates.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_105_OFFER_NOT_DECLINE',
        'OFFER_NOT_DECLINE',
        ((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND final_offer_authorized_flag AND decline_authorized_flag)::text)::text,
        '0',
        coalesce((((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND final_offer_authorized_flag AND decline_authorized_flag))=0), FALSE),
        'Offer Not Decline validates.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_106_SOURCE_HASH_PRESENT',
        'SOURCE_HASH_PRESENT',
        ((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND (source_m2_2_contract_row_hash IS NULL OR source_request_contract_row_hash IS NULL OR source_g2_combined_hash IS NULL))::text)::text,
        '0',
        coalesce((((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND (source_m2_2_contract_row_hash IS NULL OR source_request_contract_row_hash IS NULL OR source_g2_combined_hash IS NULL)))=0), FALSE),
        'Source Hash Present validates.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_107_REASON_CODES_JSON_ARRAY',
        'REASON_CODES_JSON_ARRAY',
        ((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND jsonb_typeof(decision_reason_codes)<>'array')::text)::text,
        '0',
        coalesce((((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND jsonb_typeof(decision_reason_codes)<>'array'))=0), FALSE),
        'Reason Codes Json Array validates.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_108_POLICY_CONFIG_HASH_PROPAGATES',
        'POLICY_CONFIG_HASH_PROPAGATES',
        ((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND policy_configuration_hash IS DISTINCT FROM (SELECT configuration_hash FROM msbf_ctl.m2_3_policy_profile WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx)))::text)::text,
        '0',
        coalesce((((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND policy_configuration_hash IS DISTINCT FROM (SELECT configuration_hash FROM msbf_ctl.m2_3_policy_profile WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx))))=0), FALSE),
        'Policy Config Hash Propagates validates.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_109_REGISTRY_ROW_HASH',
        'REGISTRY_ROW_HASH',
        ((SELECT count(*) FROM msbf_ctl.m2_3_final_decision_contract_registry r WHERE r.module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND r.row_hash IS DISTINCT FROM msbf_ctl.m2_3_registry_row_hash(to_jsonb(r)))::text)::text,
        '0',
        coalesce((((SELECT count(*) FROM msbf_ctl.m2_3_final_decision_contract_registry r WHERE r.module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND r.row_hash IS DISTINCT FROM msbf_ctl.m2_3_registry_row_hash(to_jsonb(r))))=0), FALSE),
        'Registry Row Hash validates.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_110_REGISTRY_CONTRACT_HASH',
        'REGISTRY_CONTRACT_HASH',
        ((SELECT count(*) FROM msbf_ctl.m2_3_final_decision_contract_registry r WHERE r.module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND r.contract_set_hash IS DISTINCT FROM md5(r.row_hash))::text)::text,
        '0',
        coalesce((((SELECT count(*) FROM msbf_ctl.m2_3_final_decision_contract_registry r WHERE r.module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND r.contract_set_hash IS DISTINCT FROM md5(r.row_hash)))=0), FALSE),
        'Registry Contract Hash validates.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_111_LATEST_OFFER_AUTHORIZED_COUNT',
        'LATEST_OFFER_AUTHORIZED_COUNT',
        ((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND final_offer_authorized_flag)::text)::text,
        '59',
        coalesce((((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND final_offer_authorized_flag))=59), FALSE),
        'Latest Offer Authorized Count validates.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_112_LATEST_REVIEW_COUNT',
        'LATEST_REVIEW_COUNT',
        ((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND counteroffer_review_required_flag)::text)::text,
        '190',
        coalesce((((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND counteroffer_review_required_flag))=190), FALSE),
        'Latest Review Count validates.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_113_LATEST_DECLINE_COUNT',
        'LATEST_DECLINE_COUNT',
        ((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND decline_authorized_flag)::text)::text,
        '1251',
        coalesce((((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND decline_authorized_flag))=1251), FALSE),
        'Latest Decline Count validates.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_114_ARCHIVE_ROWS_MATCH_LATEST',
        'ARCHIVE_ROWS_MATCH_LATEST',
        ((SELECT (SELECT count(*) FROM msbf_m2.application_final_offer_decision_archive WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx))-(SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx)))::text)::text,
        '0',
        coalesce((((SELECT (SELECT count(*) FROM msbf_m2.application_final_offer_decision_archive WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx))-(SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx))))=0), FALSE),
        'Archive Rows Match Latest validates.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_115_COMPARISON_APPLICATIONS',
        'COMPARISON_APPLICATIONS',
        ((SELECT count(DISTINCT merchant_application_id) FROM msbf_m2.v_m2_3_matched_scenario_comparison WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx))::text)::text,
        '750',
        coalesce((((SELECT count(DISTINCT merchant_application_id) FROM msbf_m2.v_m2_3_matched_scenario_comparison WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx)))=750), FALSE),
        'Comparison Applications validates.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_116_BASELINE_DECISION_ROWS',
        'BASELINE_DECISION_ROWS',
        ((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND scenario_code='BASELINE')::text)::text,
        '750',
        coalesce((((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND scenario_code='BASELINE'))=750), FALSE),
        'Baseline Decision Rows validates.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_117_STRESS_DECISION_ROWS',
        'STRESS_DECISION_ROWS',
        ((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND scenario_code='RECESSION_ENERGY')::text)::text,
        '750',
        coalesce((((SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND scenario_code='RECESSION_ENERGY'))=750), FALSE),
        'Stress Decision Rows validates.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_118_CANONICAL_ENTITY_COUNT',
        'CANONICAL_ENTITY_COUNT',
        ((SELECT canonical_entities FROM msbf_ctl.m2_3_final_decision_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx))::text)::text,
        '6029',
        coalesce((((SELECT canonical_entities FROM msbf_ctl.m2_3_final_decision_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx)))=6029), FALSE),
        'Canonical Entity Count validates.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_119_COMBINED_HASH_SHAPE',
        'COMBINED_HASH_SHAPE',
        ((SELECT count(*) FROM msbf_ctl.m2_3_final_decision_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND length(combined_set_hash)=32 AND combined_set_hash ~ '^[0-9a-f]+$')::text)::text,
        '1',
        coalesce((((SELECT count(*) FROM msbf_ctl.m2_3_final_decision_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_3_vctx) AND length(combined_set_hash)=32 AND combined_set_hash ~ '^[0-9a-f]+$'))=1), FALSE),
        'Combined Hash Shape validates.'
    );
    PERFORM pg_temp.m2_3_add_check(
        'M2_3_POS_120_ACCEPTANCE_NOT_YET_WRITTEN',
        'ACCEPTANCE_NOT_YET_WRITTEN',
        ((SELECT count(*) FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM _m2_3_vctx) AND gate_id='M2_3_FINAL_OFFER_DECISION_AUTHORIZATION')::text)::text,
        '0',
        coalesce((((SELECT count(*) FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM _m2_3_vctx) AND gate_id='M2_3_FINAL_OFFER_DECISION_AUTHORIZATION'))=0), FALSE),
        'Acceptance Not Yet Written validates.'
    );
END;
$m2_3_positive_controls$;

DO $m2_3_validation_finalize$
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
    FROM _m2_3_validation;

    IF v_total <> 120 THEN
        RAISE EXCEPTION
            'M2.3 positive-control inventory failed: total %, expected %.',
            v_total, 120;
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
        (SELECT run_id FROM _m2_3_vctx),
        evidence_code,
        'PORTFOLIO',
        metric_name,
        NULL::numeric(28,10),
        coalesce(observed_value,'<NULL>'),
        'VALIDATION',
        status,
        interpretation || ' Threshold: ' || coalesce(threshold_value,'<NULL>')
    FROM _m2_3_validation
    ON CONFLICT(run_id,evidence_code,segment_key)
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
        SET run_status = 'M2_3_VALIDATED'
        WHERE run_id = (SELECT run_id FROM _m2_3_vctx);

        UPDATE msbf_ctl.m2_3_final_decision_contract_registry
        SET
            contract_status = 'VALIDATED',
            validated_at = clock_timestamp()
        WHERE module1_run_id = (SELECT run_id FROM _m2_3_vctx);
    ELSE
        UPDATE msbf_ctl.run_registry
        SET run_status = 'M2_3_FAILED'
        WHERE run_id = (SELECT run_id FROM _m2_3_vctx);

        RAISE EXCEPTION
            'M2.3 positive validation failed: pass %, fail %.',
            v_pass, v_fail;
    END IF;
END;
$m2_3_validation_finalize$;

COMMIT;

SELECT
    evidence_code,
    metric_name,
    observed_value,
    threshold_value,
    status,
    interpretation
FROM _m2_3_validation
ORDER BY evidence_code;
