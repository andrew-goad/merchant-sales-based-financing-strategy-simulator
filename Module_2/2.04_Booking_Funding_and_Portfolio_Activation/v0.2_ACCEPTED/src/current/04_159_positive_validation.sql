/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.4 — Booking, Funding & Portfolio Activation

Program     : 159_msbf_m2_4_booking_funding_activation_validation_v0_2.sql
Version     : v0.2
Purpose     : Read-only positive validation of M2.4 governance, source lineage,
              operational mapping, synthetic IDs and dates, account/advance/
              portfolio linkage, physical hashes, latest/archive reproduction,
              matched stress non-improvement and real-world stage boundaries.

Output      : 120-row session-preserved result set.
Required    : 120 / 120 PASS.
============================================================================ */

BEGIN;

SET LOCAL work_mem = '128MB';
SET LOCAL statement_timeout = '35min';
SET LOCAL jit = off;

DROP TABLE IF EXISTS _m2_4_validation;

CREATE TEMP TABLE _m2_4_validation
(
    evidence_code   text PRIMARY KEY,
    metric_name     text NOT NULL,
    observed_value  text,
    threshold_value text,
    status          text NOT NULL,
    interpretation  text NOT NULL
)
ON COMMIT PRESERVE ROWS;

DROP TABLE IF EXISTS _m2_4_vctx;

CREATE TEMP TABLE _m2_4_vctx
ON COMMIT DROP
AS
SELECT run_id,run_status
FROM msbf_ctl.run_registry
WHERE run_code='M1_V0_2_BASELINE_BUILD'
  AND run_version=1;

DO $m2_4_validation_ready$
BEGIN
    PERFORM msbf_ctl.m2_4_assert_validation_ready
    (
        (SELECT run_id FROM _m2_4_vctx)
    );
END;
$m2_4_validation_ready$;

CREATE OR REPLACE FUNCTION pg_temp.m2_4_add_check
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
    INSERT INTO _m2_4_validation
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

DO $m2_4_positive_controls$
BEGIN
    /* ----------------------------------------------------------------------
    Controls 001–020 — lifecycle, policy, accepted M2.3 source and dictionaries
    ---------------------------------------------------------------------- */
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_001_RUN_STATUS',
        'RUN_STATUS',
        ((SELECT run_status FROM _m2_4_vctx))::text,
        'M2_4_GENERATED or M2_4_VALIDATED',
        coalesce(((SELECT run_status IN ('M2_4_GENERATED','M2_4_VALIDATED') FROM _m2_4_vctx)),FALSE),
        'Validation begins from generated state or a governed validation rerun state.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_002_POLICY_APPROVED',
        'POLICY_APPROVED',
        ((SELECT policy_status||'|'||synthetic_booking_enabled_flag||'|'||synthetic_funding_enabled_flag||'|'||portfolio_activation_enabled_flag||'|'||synthetic_offer_acceptance_assumed_flag||'|'||real_funds_movement_prohibited_flag||'|'||external_notice_transmission_prohibited_flag||'|'||production_adverse_action_notice_prohibited_flag||'|'||review_routes_not_bookable_flag||'|'||decline_routes_not_bookable_flag||'|'||duplicate_activation_prohibited_flag||'|'||source_decision_immutable_flag||'|'||stress_nonimprovement_required_flag||'|'||booking_lag_days||'|'||funding_lag_days||'|'||first_remittance_lag_days||'|'||monitoring_start_lag_days FROM msbf_ctl.m2_4_policy_profile WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx)))::text,
        'APPROVED|true|true|true|true|true|true|true|true|true|true|true|true|1|2|3|2',
        coalesce(((SELECT policy_status='APPROVED' AND synthetic_booking_enabled_flag AND synthetic_funding_enabled_flag AND portfolio_activation_enabled_flag AND synthetic_offer_acceptance_assumed_flag AND real_funds_movement_prohibited_flag AND external_notice_transmission_prohibited_flag AND production_adverse_action_notice_prohibited_flag AND review_routes_not_bookable_flag AND decline_routes_not_bookable_flag AND duplicate_activation_prohibited_flag AND source_decision_immutable_flag AND stress_nonimprovement_required_flag AND booking_lag_days=1 AND funding_lag_days=2 AND first_remittance_lag_days=3 AND monitoring_start_lag_days=2 FROM msbf_ctl.m2_4_policy_profile WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx))),FALSE),
        'Policy and operational boundary flags are approved.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_003_METHOD_CONTRACT',
        'METHOD_CONTRACT',
        ((SELECT methodology_version||'|'||contract_code||'|'||contract_version||'|'||schema_version FROM msbf_ctl.m2_4_policy_profile WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx)))::text,
        'M2_4_METHOD_V1|M2_PORTFOLIO_ACTIVATION_CONSUMPTION|1|M2_4_PORTFOLIO_ACTIVATION_SCHEMA_V1',
        coalesce(((SELECT methodology_version='M2_4_METHOD_V1' AND contract_code='M2_PORTFOLIO_ACTIVATION_CONSUMPTION' AND contract_version=1 AND schema_version='M2_4_PORTFOLIO_ACTIVATION_SCHEMA_V1' FROM msbf_ctl.m2_4_policy_profile WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx))),FALSE),
        'M2.4 method and contract identity are exact.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_004_SOURCE_M2_3_HASH',
        'SOURCE_M2_3_HASH',
        ((SELECT source_m2_3_combined_hash FROM msbf_ctl.m2_4_policy_profile WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx)))::text,
        'bf09349b06ede7e5a2ec830c2f9ffe90',
        coalesce(((SELECT source_m2_3_combined_hash='bf09349b06ede7e5a2ec830c2f9ffe90' FROM msbf_ctl.m2_4_policy_profile WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx))),FALSE),
        'Accepted M2.3 combined hash is preserved.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_005_SOURCE_M2_3_REGISTRY',
        'SOURCE_M2_3_REGISTRY',
        ((SELECT contract_status||'|'||decision_latest_rows||'|'||combined_set_hash FROM msbf_ctl.m2_3_final_decision_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx)))::text,
        'ACCEPTED|1500|accepted hash',
        coalesce(((SELECT contract_status='ACCEPTED' AND contract_code='M2_FINAL_OFFER_DECISION_CONSUMPTION' AND contract_version=1 AND schema_version='M2_3_FINAL_DECISION_SCHEMA_V1' AND decision_latest_rows=1500 AND combined_set_hash='bf09349b06ede7e5a2ec830c2f9ffe90' FROM msbf_ctl.m2_3_final_decision_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx))),FALSE),
        'M2.3 final-decision contract is accepted.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_006_SOURCE_M2_3_GATE',
        'SOURCE_M2_3_GATE',
        ((SELECT result_status FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM _m2_4_vctx) AND gate_id='M2_3_FINAL_OFFER_DECISION_AUTHORIZATION' AND review_version=1))::text,
        'PASS',
        coalesce(((SELECT result_status='PASS' FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM _m2_4_vctx) AND gate_id='M2_3_FINAL_OFFER_DECISION_AUTHORIZATION' AND review_version=1)),FALSE),
        'M2.3 acceptance gate is PASS.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_007_CONFIGURATION_HASH',
        'CONFIGURATION_HASH',
        ((SELECT configuration_hash FROM msbf_ctl.m2_4_policy_profile WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx)))::text,
        'physical payload hash',
        coalesce(((SELECT configuration_hash=msbf_ctl.m2_4_hash_jsonb(configuration_payload) FROM msbf_ctl.m2_4_policy_profile WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx))),FALSE),
        'Configuration hash reconstructs from payload.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_008_POLICY_ROW_HASH',
        'POLICY_ROW_HASH',
        ((SELECT count(*) FROM msbf_ctl.m2_4_policy_profile AS policy WHERE policy.module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND policy.row_hash IS DISTINCT FROM msbf_ctl.m2_4_hash_jsonb(to_jsonb(policy)-'row_hash'-'created_at'-'updated_at'))::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_ctl.m2_4_policy_profile AS policy WHERE policy.module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND policy.row_hash IS DISTINCT FROM msbf_ctl.m2_4_hash_jsonb(to_jsonb(policy)-'row_hash'-'created_at'-'updated_at'))),FALSE),
        'Policy physical row hash reconciles.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_009_OUTCOME_DEFINITIONS',
        'OUTCOME_DEFINITIONS',
        ((SELECT count(*) FROM msbf_m2.booking_funding_activation_outcome_definition WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx))::text)::text,
        '5',
        coalesce(((SELECT count(*)=5 FROM msbf_m2.booking_funding_activation_outcome_definition WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx))),FALSE),
        'Outcome Definitions count is governed.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_010_REASON_DEFINITIONS',
        'REASON_DEFINITIONS',
        ((SELECT count(*) FROM msbf_m2.booking_funding_reason_definition WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx))::text)::text,
        '24',
        coalesce(((SELECT count(*)=24 FROM msbf_m2.booking_funding_reason_definition WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx))),FALSE),
        'Reason Definitions count is governed.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_011_NOTICE_DEFINITIONS',
        'NOTICE_DEFINITIONS',
        ((SELECT count(*) FROM msbf_m2.external_notice_control_definition WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx))::text)::text,
        '4',
        coalesce(((SELECT count(*)=4 FROM msbf_m2.external_notice_control_definition WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx))),FALSE),
        'Notice Definitions count is governed.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_012_OUTCOME_BOUNDARIES',
        'OUTCOME_BOUNDARIES',
        ((SELECT count(*) FROM msbf_m2.booking_funding_activation_outcome_definition WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND (external_notice_transmission_flag OR production_adverse_action_notice_flag OR real_funds_movement_flag))::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.booking_funding_activation_outcome_definition WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND (external_notice_transmission_flag OR production_adverse_action_notice_flag OR real_funds_movement_flag))),FALSE),
        'Outcome dictionary has no real-world movement or notice flags.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_013_REASON_BOUNDARIES',
        'REASON_BOUNDARIES',
        ((SELECT count(*) FROM msbf_m2.booking_funding_reason_definition WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND production_adverse_action_notice_flag)::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.booking_funding_reason_definition WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND production_adverse_action_notice_flag)),FALSE),
        'Reason dictionary has no production adverse-action flags.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_014_NOTICE_BOUNDARIES',
        'NOTICE_BOUNDARIES',
        ((SELECT count(*) FROM msbf_m2.external_notice_control_definition WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND (external_transmission_authorized_flag OR production_adverse_action_notice_flag))::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.external_notice_control_definition WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND (external_transmission_authorized_flag OR production_adverse_action_notice_flag))),FALSE),
        'Notice controls are internal only.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_015_REGISTRY_ROW',
        'REGISTRY_ROW',
        ((SELECT count(*) FROM msbf_ctl.m2_4_portfolio_activation_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx))::text)::text,
        '1',
        coalesce(((SELECT count(*)=1 FROM msbf_ctl.m2_4_portfolio_activation_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx))),FALSE),
        'Exactly one contract registry row exists.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_016_REGISTRY_STATUS',
        'REGISTRY_STATUS',
        ((SELECT contract_status FROM msbf_ctl.m2_4_portfolio_activation_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx)))::text,
        'GENERATED',
        coalesce(((SELECT contract_status='GENERATED' FROM msbf_ctl.m2_4_portfolio_activation_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx))),FALSE),
        'Registry begins validation in generated state.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_017_REGISTRY_COUNTS',
        'REGISTRY_COUNTS',
        ((SELECT source_rows||'|'||activation_snapshot_rows||'|'||activation_latest_rows||'|'||activation_archive_rows||'|'||account_rows||'|'||advance_rows||'|'||portfolio_rows||'|'||comparison_rows||'|'||canonical_entities FROM msbf_ctl.m2_4_portfolio_activation_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx)))::text,
        '1500|1500|1500|1500|59|59|59|750|6212',
        coalesce(((SELECT source_rows=1500 AND activation_snapshot_rows=1500 AND activation_latest_rows=1500 AND activation_archive_rows=1500 AND account_rows=59 AND advance_rows=59 AND portfolio_rows=59 AND comparison_rows=750 AND canonical_entities=6212 FROM msbf_ctl.m2_4_portfolio_activation_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx))),FALSE),
        'Registry cardinalities match M2.4 contract.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_018_SOURCE_ROWS',
        'SOURCE_ROWS',
        ((SELECT count(*) FROM msbf_m2.application_booking_funding_source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx))::text)::text,
        '1500',
        coalesce(((SELECT count(*)=1500 FROM msbf_m2.application_booking_funding_source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx))),FALSE),
        'Source snapshot contains all accepted M2.3 rows.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_019_SOURCE_APPLICATIONS',
        'SOURCE_APPLICATIONS',
        ((SELECT count(DISTINCT merchant_application_id) FROM msbf_m2.application_booking_funding_source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx))::text)::text,
        '750',
        coalesce(((SELECT count(DISTINCT merchant_application_id)=750 FROM msbf_m2.application_booking_funding_source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx))),FALSE),
        'Source snapshot covers 750 applications.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_020_SOURCE_SCENARIOS',
        'SOURCE_SCENARIOS',
        ((SELECT count(DISTINCT scenario_id) FROM msbf_m2.application_booking_funding_source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx))::text)::text,
        '2',
        coalesce(((SELECT count(DISTINCT scenario_id)=2 FROM msbf_m2.application_booking_funding_source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx))),FALSE),
        'Source snapshot retains two scenarios.'
    );
    /* ----------------------------------------------------------------------
    Controls 021–037 — source, snapshot, latest/archive and cardinality grains
    ---------------------------------------------------------------------- */
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_021_SOURCE_SCENARIO_BALANCE',
        'SOURCE_SCENARIO_BALANCE',
        ((SELECT count(*) FILTER(WHERE scenario_code='BASELINE')||'|'||count(*) FILTER(WHERE scenario_code='RECESSION_ENERGY') FROM msbf_m2.application_booking_funding_source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx)))::text,
        '750|750',
        coalesce(((SELECT count(*) FILTER(WHERE scenario_code='BASELINE')=750 AND count(*) FILTER(WHERE scenario_code='RECESSION_ENERGY')=750 FROM msbf_m2.application_booking_funding_source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx))),FALSE),
        'Baseline and stress source rows balance.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_022_SOURCE_GRAIN',
        'SOURCE_GRAIN',
        ((SELECT count(*)-count(DISTINCT scenario_id::text||'|'||merchant_application_id) FROM msbf_m2.application_booking_funding_source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx))::text)::text,
        '0',
        coalesce(((SELECT count(*)=count(DISTINCT scenario_id::text||'|'||merchant_application_id) FROM msbf_m2.application_booking_funding_source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx))),FALSE),
        'Source snapshot grain is unique.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_023_ACTIVATION_SNAPSHOT_ROWS',
        'ACTIVATION_SNAPSHOT_ROWS',
        ((SELECT count(*) FROM msbf_m2.application_booking_funding_activation_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx))::text)::text,
        '1500',
        coalesce(((SELECT count(*)=1500 FROM msbf_m2.application_booking_funding_activation_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx))),FALSE),
        'Activation Snapshot Rows match expected.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_024_ACTIVATION_LATEST_ROWS',
        'ACTIVATION_LATEST_ROWS',
        ((SELECT count(*) FROM msbf_m2.application_booking_funding_activation_latest WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx))::text)::text,
        '1500',
        coalesce(((SELECT count(*)=1500 FROM msbf_m2.application_booking_funding_activation_latest WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx))),FALSE),
        'Activation Latest Rows match expected.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_025_ACTIVATION_ARCHIVE_ROWS',
        'ACTIVATION_ARCHIVE_ROWS',
        ((SELECT count(*) FROM msbf_m2.application_booking_funding_activation_archive WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx))::text)::text,
        '1500',
        coalesce(((SELECT count(*)=1500 FROM msbf_m2.application_booking_funding_activation_archive WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx))),FALSE),
        'Activation Archive Rows match expected.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_026_ACCOUNT_ROWS',
        'ACCOUNT_ROWS',
        ((SELECT count(*) FROM msbf_m2.synthetic_account_activation WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx))::text)::text,
        '59',
        coalesce(((SELECT count(*)=59 FROM msbf_m2.synthetic_account_activation WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx))),FALSE),
        'Account Rows match expected.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_027_ADVANCE_ROWS',
        'ADVANCE_ROWS',
        ((SELECT count(*) FROM msbf_m2.synthetic_advance_funding WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx))::text)::text,
        '59',
        coalesce(((SELECT count(*)=59 FROM msbf_m2.synthetic_advance_funding WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx))),FALSE),
        'Advance Rows match expected.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_028_PORTFOLIO_ROWS',
        'PORTFOLIO_ROWS',
        ((SELECT count(*) FROM msbf_m2.initial_portfolio_activation WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx))::text)::text,
        '59',
        coalesce(((SELECT count(*)=59 FROM msbf_m2.initial_portfolio_activation WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx))),FALSE),
        'Portfolio Rows match expected.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_029_COMPARISON_ROWS',
        'COMPARISON_ROWS',
        ((SELECT count(*) FROM msbf_m2.v_m2_4_matched_scenario_comparison WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx))::text)::text,
        '750',
        coalesce(((SELECT count(*)=750 FROM msbf_m2.v_m2_4_matched_scenario_comparison WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx))),FALSE),
        'Matched comparison contains 750 applications.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_030_CANONICAL_ENTITIES',
        'CANONICAL_ENTITIES',
        ((SELECT canonical_entities FROM msbf_ctl.m2_4_portfolio_activation_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx)))::text,
        '6212',
        coalesce(((SELECT canonical_entities=6212 FROM msbf_ctl.m2_4_portfolio_activation_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx))),FALSE),
        'Canonical entity count is 6,212.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_031_BOOKED_FUNDED_PORTFOLIO_ACTIVATED',
        'BOOKED_FUNDED_PORTFOLIO_ACTIVATED',
        ((SELECT count(*) FROM msbf_m2.application_booking_funding_activation_latest WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND activation_outcome_code='BOOKED_FUNDED_PORTFOLIO_ACTIVATED')::text)::text,
        '59',
        coalesce(((SELECT count(*)=59 FROM msbf_m2.application_booking_funding_activation_latest WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND activation_outcome_code='BOOKED_FUNDED_PORTFOLIO_ACTIVATED')),FALSE),
        'BOOKED_FUNDED_PORTFOLIO_ACTIVATED count matches accepted M2.3 routing.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_032_ACTIVATION_REVIEW_REQUIRED',
        'ACTIVATION_REVIEW_REQUIRED',
        ((SELECT count(*) FROM msbf_m2.application_booking_funding_activation_latest WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND activation_outcome_code='ACTIVATION_REVIEW_REQUIRED')::text)::text,
        '190',
        coalesce(((SELECT count(*)=190 FROM msbf_m2.application_booking_funding_activation_latest WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND activation_outcome_code='ACTIVATION_REVIEW_REQUIRED')),FALSE),
        'ACTIVATION_REVIEW_REQUIRED count matches accepted M2.3 routing.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_033_NOT_ACTIVATED_INSUFFICIENT_EVIDENCE',
        'NOT_ACTIVATED_INSUFFICIENT_EVIDENCE',
        ((SELECT count(*) FROM msbf_m2.application_booking_funding_activation_latest WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND activation_outcome_code='NOT_ACTIVATED_INSUFFICIENT_EVIDENCE')::text)::text,
        '178',
        coalesce(((SELECT count(*)=178 FROM msbf_m2.application_booking_funding_activation_latest WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND activation_outcome_code='NOT_ACTIVATED_INSUFFICIENT_EVIDENCE')),FALSE),
        'NOT_ACTIVATED_INSUFFICIENT_EVIDENCE count matches accepted M2.3 routing.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_034_NOT_ACTIVATED_POLICY_DECLINE',
        'NOT_ACTIVATED_POLICY_DECLINE',
        ((SELECT count(*) FROM msbf_m2.application_booking_funding_activation_latest WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND activation_outcome_code='NOT_ACTIVATED_POLICY_DECLINE')::text)::text,
        '1073',
        coalesce(((SELECT count(*)=1073 FROM msbf_m2.application_booking_funding_activation_latest WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND activation_outcome_code='NOT_ACTIVATED_POLICY_DECLINE')),FALSE),
        'NOT_ACTIVATED_POLICY_DECLINE count matches accepted M2.3 routing.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_035_OUTCOME_TOTAL',
        'OUTCOME_TOTAL',
        ((SELECT count(*) FROM msbf_m2.application_booking_funding_activation_latest WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx))::text)::text,
        '1500',
        coalesce(((SELECT count(*)=1500 FROM msbf_m2.application_booking_funding_activation_latest WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx))),FALSE),
        'All rows map to an activation outcome.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_036_BASELINE_ROWS',
        'BASELINE_ROWS',
        ((SELECT count(*) FROM msbf_m2.application_booking_funding_activation_latest WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND scenario_code='BASELINE')::text)::text,
        '750',
        coalesce(((SELECT count(*)=750 FROM msbf_m2.application_booking_funding_activation_latest WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND scenario_code='BASELINE')),FALSE),
        'BASELINE activation rows equal 750.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_037_RECESSION_ENERGY_ROWS',
        'RECESSION_ENERGY_ROWS',
        ((SELECT count(*) FROM msbf_m2.application_booking_funding_activation_latest WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND scenario_code='RECESSION_ENERGY')::text)::text,
        '750',
        coalesce(((SELECT count(*)=750 FROM msbf_m2.application_booking_funding_activation_latest WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND scenario_code='RECESSION_ENERGY')),FALSE),
        'RECESSION_ENERGY activation rows equal 750.'
    );
    /* ----------------------------------------------------------------------
    Controls 038–046 — final-decision-to-activation mapping and status identity
    ---------------------------------------------------------------------- */
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_038_SOURCE_TO_ACTIVATION',
        'SOURCE_TO_ACTIVATION_38',
        ((SELECT count(*) FROM msbf_m2.application_booking_funding_activation_latest WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND source_final_decision_outcome_code='FINAL_OFFER_AUTHORIZED' AND activation_outcome_code<>'BOOKED_FUNDED_PORTFOLIO_ACTIVATED')::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_booking_funding_activation_latest WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND source_final_decision_outcome_code='FINAL_OFFER_AUTHORIZED' AND activation_outcome_code<>'BOOKED_FUNDED_PORTFOLIO_ACTIVATED')),FALSE),
        'FINAL_OFFER_AUTHORIZED maps only to BOOKED_FUNDED_PORTFOLIO_ACTIVATED.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_039_SOURCE_TO_ACTIVATION',
        'SOURCE_TO_ACTIVATION_39',
        ((SELECT count(*) FROM msbf_m2.application_booking_funding_activation_latest WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND source_final_decision_outcome_code='COUNTEROFFER_REVIEW_REQUIRED' AND activation_outcome_code<>'ACTIVATION_REVIEW_REQUIRED')::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_booking_funding_activation_latest WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND source_final_decision_outcome_code='COUNTEROFFER_REVIEW_REQUIRED' AND activation_outcome_code<>'ACTIVATION_REVIEW_REQUIRED')),FALSE),
        'COUNTEROFFER_REVIEW_REQUIRED maps only to ACTIVATION_REVIEW_REQUIRED.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_040_SOURCE_TO_ACTIVATION',
        'SOURCE_TO_ACTIVATION_40',
        ((SELECT count(*) FROM msbf_m2.application_booking_funding_activation_latest WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND source_final_decision_outcome_code='DECLINE_INSUFFICIENT_EVIDENCE_AUTHORIZED' AND activation_outcome_code<>'NOT_ACTIVATED_INSUFFICIENT_EVIDENCE')::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_booking_funding_activation_latest WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND source_final_decision_outcome_code='DECLINE_INSUFFICIENT_EVIDENCE_AUTHORIZED' AND activation_outcome_code<>'NOT_ACTIVATED_INSUFFICIENT_EVIDENCE')),FALSE),
        'DECLINE_INSUFFICIENT_EVIDENCE_AUTHORIZED maps only to NOT_ACTIVATED_INSUFFICIENT_EVIDENCE.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_041_SOURCE_TO_ACTIVATION',
        'SOURCE_TO_ACTIVATION_41',
        ((SELECT count(*) FROM msbf_m2.application_booking_funding_activation_latest WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND source_final_decision_outcome_code='DECLINE_POLICY_AUTHORIZED' AND activation_outcome_code<>'NOT_ACTIVATED_POLICY_DECLINE')::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_booking_funding_activation_latest WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND source_final_decision_outcome_code='DECLINE_POLICY_AUTHORIZED' AND activation_outcome_code<>'NOT_ACTIVATED_POLICY_DECLINE')),FALSE),
        'DECLINE_POLICY_AUTHORIZED maps only to NOT_ACTIVATED_POLICY_DECLINE.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_042_BOOKING_FLAG_IDENTITY',
        'BOOKING_FLAG_IDENTITY',
        ((SELECT count(*) FROM msbf_m2.application_booking_funding_activation_latest WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND booking_authorized_flag IS DISTINCT FROM (activation_outcome_code='BOOKED_FUNDED_PORTFOLIO_ACTIVATED'))::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_booking_funding_activation_latest WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND booking_authorized_flag IS DISTINCT FROM (activation_outcome_code='BOOKED_FUNDED_PORTFOLIO_ACTIVATED'))),FALSE),
        'Booking flag follows activation outcome.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_043_FUNDING_FLAG_IDENTITY',
        'FUNDING_FLAG_IDENTITY',
        ((SELECT count(*) FROM msbf_m2.application_booking_funding_activation_latest WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND funding_completed_flag IS DISTINCT FROM (activation_outcome_code='BOOKED_FUNDED_PORTFOLIO_ACTIVATED'))::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_booking_funding_activation_latest WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND funding_completed_flag IS DISTINCT FROM (activation_outcome_code='BOOKED_FUNDED_PORTFOLIO_ACTIVATED'))),FALSE),
        'Funding flag follows activation outcome.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_044_PORTFOLIO_FLAG_IDENTITY',
        'PORTFOLIO_FLAG_IDENTITY',
        ((SELECT count(*) FROM msbf_m2.application_booking_funding_activation_latest WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND portfolio_activated_flag IS DISTINCT FROM (activation_outcome_code='BOOKED_FUNDED_PORTFOLIO_ACTIVATED'))::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_booking_funding_activation_latest WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND portfolio_activated_flag IS DISTINCT FROM (activation_outcome_code='BOOKED_FUNDED_PORTFOLIO_ACTIVATED'))),FALSE),
        'Portfolio flag follows activation outcome.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_045_REVIEW_FLAG_IDENTITY',
        'REVIEW_FLAG_IDENTITY',
        ((SELECT count(*) FROM msbf_m2.application_booking_funding_activation_latest WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND operational_review_required_flag IS DISTINCT FROM (activation_outcome_code='ACTIVATION_REVIEW_REQUIRED'))::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_booking_funding_activation_latest WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND operational_review_required_flag IS DISTINCT FROM (activation_outcome_code='ACTIVATION_REVIEW_REQUIRED'))),FALSE),
        'Review flag follows activation outcome.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_046_STATUS_DOMAIN',
        'STATUS_DOMAIN',
        ((SELECT count(*) FROM msbf_m2.application_booking_funding_activation_latest WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND activation_evidence_status NOT IN ('ACTIVATED','REVIEW_REQUIRED','NOT_ACTIVATED','BLOCKED'))::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_booking_funding_activation_latest WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND activation_evidence_status NOT IN ('ACTIVATED','REVIEW_REQUIRED','NOT_ACTIVATED','BLOCKED'))),FALSE),
        'Activation status stays within governed domain.'
    );
    /* ----------------------------------------------------------------------
    Controls 047–060 — synthetic IDs, operational terms, dates and sub-ledgers
    ---------------------------------------------------------------------- */
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_047_ACTIVATED_VALUES_PRESENT',
        'ACTIVATED_VALUES_PRESENT',
        ((SELECT count(*) FROM msbf_m2.application_booking_funding_activation_latest WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND portfolio_activated_flag AND (synthetic_account_id IS NULL OR synthetic_advance_id IS NULL OR booked_amount IS NULL OR funded_amount IS NULL OR activation_remittance_rate IS NULL OR activation_payback_multiple IS NULL OR activation_collection_horizon_days IS NULL OR booking_date IS NULL OR funding_date IS NULL OR portfolio_activation_date IS NULL OR first_expected_remittance_date IS NULL OR monitoring_start_date IS NULL))::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_booking_funding_activation_latest WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND portfolio_activated_flag AND (synthetic_account_id IS NULL OR synthetic_advance_id IS NULL OR booked_amount IS NULL OR funded_amount IS NULL OR activation_remittance_rate IS NULL OR activation_payback_multiple IS NULL OR activation_collection_horizon_days IS NULL OR booking_date IS NULL OR funding_date IS NULL OR portfolio_activation_date IS NULL OR first_expected_remittance_date IS NULL OR monitoring_start_date IS NULL))),FALSE),
        'Activated rows have all IDs, terms and dates.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_048_NONACTIVATED_VALUES_ABSENT',
        'NONACTIVATED_VALUES_ABSENT',
        ((SELECT count(*) FROM msbf_m2.application_booking_funding_activation_latest WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND NOT portfolio_activated_flag AND (synthetic_account_id IS NOT NULL OR synthetic_advance_id IS NOT NULL OR booked_amount IS NOT NULL OR funded_amount IS NOT NULL OR activation_remittance_rate IS NOT NULL OR activation_payback_multiple IS NOT NULL OR activation_collection_horizon_days IS NOT NULL OR booking_date IS NOT NULL OR funding_date IS NOT NULL OR portfolio_activation_date IS NOT NULL OR first_expected_remittance_date IS NOT NULL OR monitoring_start_date IS NOT NULL))::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_booking_funding_activation_latest WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND NOT portfolio_activated_flag AND (synthetic_account_id IS NOT NULL OR synthetic_advance_id IS NOT NULL OR booked_amount IS NOT NULL OR funded_amount IS NOT NULL OR activation_remittance_rate IS NOT NULL OR activation_payback_multiple IS NOT NULL OR activation_collection_horizon_days IS NOT NULL OR booking_date IS NOT NULL OR funding_date IS NOT NULL OR portfolio_activation_date IS NOT NULL OR first_expected_remittance_date IS NOT NULL OR monitoring_start_date IS NOT NULL))),FALSE),
        'Nonactivated rows have no synthetic booking/funding values.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_049_ACTIVATED_TERMS_PRESENT',
        'ACTIVATED_TERMS_PRESENT',
        ((SELECT count(*) FROM msbf_m2.application_booking_funding_activation_latest WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND portfolio_activated_flag AND (activation_total_repayment_amount IS NULL OR activation_finance_charge_amount IS NULL OR activation_implied_daily_collection_amount IS NULL OR activation_implied_payoff_days IS NULL))::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_booking_funding_activation_latest WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND portfolio_activated_flag AND (activation_total_repayment_amount IS NULL OR activation_finance_charge_amount IS NULL OR activation_implied_daily_collection_amount IS NULL OR activation_implied_payoff_days IS NULL))),FALSE),
        'Activated rows have all economic terms.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_050_NONACTIVATED_TERMS_ABSENT',
        'NONACTIVATED_TERMS_ABSENT',
        ((SELECT count(*) FROM msbf_m2.application_booking_funding_activation_latest WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND NOT portfolio_activated_flag AND (activation_total_repayment_amount IS NOT NULL OR activation_finance_charge_amount IS NOT NULL OR activation_implied_daily_collection_amount IS NOT NULL OR activation_implied_payoff_days IS NOT NULL))::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_booking_funding_activation_latest WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND NOT portfolio_activated_flag AND (activation_total_repayment_amount IS NOT NULL OR activation_finance_charge_amount IS NOT NULL OR activation_implied_daily_collection_amount IS NOT NULL OR activation_implied_payoff_days IS NOT NULL))),FALSE),
        'Nonactivated rows carry no activation economics.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_051_BOOKED_EQUALS_FUNDED',
        'BOOKED_EQUALS_FUNDED',
        ((SELECT count(*) FROM msbf_m2.application_booking_funding_activation_latest WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND portfolio_activated_flag AND booked_amount IS DISTINCT FROM funded_amount)::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_booking_funding_activation_latest WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND portfolio_activated_flag AND booked_amount IS DISTINCT FROM funded_amount)),FALSE),
        'Booked and funded synthetic amounts are identical.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_052_FUNDED_EQUALS_FINAL_OFFER',
        'FUNDED_EQUALS_FINAL_OFFER',
        ((SELECT count(*) FROM msbf_m2.application_booking_funding_activation_latest AS activation JOIN msbf_m2.application_final_offer_decision_latest AS decision ON decision.module1_run_id=activation.module1_run_id AND decision.scenario_id=activation.scenario_id AND decision.merchant_application_id=activation.merchant_application_id WHERE activation.module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND activation.portfolio_activated_flag AND activation.funded_amount IS DISTINCT FROM decision.final_offer_amount)::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_booking_funding_activation_latest AS activation JOIN msbf_m2.application_final_offer_decision_latest AS decision ON decision.module1_run_id=activation.module1_run_id AND decision.scenario_id=activation.scenario_id AND decision.merchant_application_id=activation.merchant_application_id WHERE activation.module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND activation.portfolio_activated_flag AND activation.funded_amount IS DISTINCT FROM decision.final_offer_amount)),FALSE),
        'Funded Equals Final Offer preserves M2.3 terms.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_053_REMITTANCE_EQUALS_FINAL_OFFER',
        'REMITTANCE_EQUALS_FINAL_OFFER',
        ((SELECT count(*) FROM msbf_m2.application_booking_funding_activation_latest AS activation JOIN msbf_m2.application_final_offer_decision_latest AS decision ON decision.module1_run_id=activation.module1_run_id AND decision.scenario_id=activation.scenario_id AND decision.merchant_application_id=activation.merchant_application_id WHERE activation.module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND activation.portfolio_activated_flag AND activation.activation_remittance_rate IS DISTINCT FROM decision.final_remittance_rate)::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_booking_funding_activation_latest AS activation JOIN msbf_m2.application_final_offer_decision_latest AS decision ON decision.module1_run_id=activation.module1_run_id AND decision.scenario_id=activation.scenario_id AND decision.merchant_application_id=activation.merchant_application_id WHERE activation.module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND activation.portfolio_activated_flag AND activation.activation_remittance_rate IS DISTINCT FROM decision.final_remittance_rate)),FALSE),
        'Remittance Equals Final Offer preserves M2.3 terms.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_054_PAYBACK_EQUALS_FINAL_OFFER',
        'PAYBACK_EQUALS_FINAL_OFFER',
        ((SELECT count(*) FROM msbf_m2.application_booking_funding_activation_latest AS activation JOIN msbf_m2.application_final_offer_decision_latest AS decision ON decision.module1_run_id=activation.module1_run_id AND decision.scenario_id=activation.scenario_id AND decision.merchant_application_id=activation.merchant_application_id WHERE activation.module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND activation.portfolio_activated_flag AND activation.activation_payback_multiple IS DISTINCT FROM decision.final_payback_multiple)::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_booking_funding_activation_latest AS activation JOIN msbf_m2.application_final_offer_decision_latest AS decision ON decision.module1_run_id=activation.module1_run_id AND decision.scenario_id=activation.scenario_id AND decision.merchant_application_id=activation.merchant_application_id WHERE activation.module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND activation.portfolio_activated_flag AND activation.activation_payback_multiple IS DISTINCT FROM decision.final_payback_multiple)),FALSE),
        'Payback Equals Final Offer preserves M2.3 terms.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_055_HORIZON_EQUALS_FINAL_OFFER',
        'HORIZON_EQUALS_FINAL_OFFER',
        ((SELECT count(*) FROM msbf_m2.application_booking_funding_activation_latest AS activation JOIN msbf_m2.application_final_offer_decision_latest AS decision ON decision.module1_run_id=activation.module1_run_id AND decision.scenario_id=activation.scenario_id AND decision.merchant_application_id=activation.merchant_application_id WHERE activation.module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND activation.portfolio_activated_flag AND activation.activation_collection_horizon_days IS DISTINCT FROM decision.final_collection_horizon_days)::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_booking_funding_activation_latest AS activation JOIN msbf_m2.application_final_offer_decision_latest AS decision ON decision.module1_run_id=activation.module1_run_id AND decision.scenario_id=activation.scenario_id AND decision.merchant_application_id=activation.merchant_application_id WHERE activation.module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND activation.portfolio_activated_flag AND activation.activation_collection_horizon_days IS DISTINCT FROM decision.final_collection_horizon_days)),FALSE),
        'Horizon Equals Final Offer preserves M2.3 terms.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_056_TOTAL_REPAYMENT_EQUALS_FINAL_OFFER',
        'TOTAL_REPAYMENT_EQUALS_FINAL_OFFER',
        ((SELECT count(*) FROM msbf_m2.application_booking_funding_activation_latest AS activation JOIN msbf_m2.application_final_offer_decision_latest AS decision ON decision.module1_run_id=activation.module1_run_id AND decision.scenario_id=activation.scenario_id AND decision.merchant_application_id=activation.merchant_application_id WHERE activation.module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND activation.portfolio_activated_flag AND activation.activation_total_repayment_amount IS DISTINCT FROM decision.final_total_repayment_amount)::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_booking_funding_activation_latest AS activation JOIN msbf_m2.application_final_offer_decision_latest AS decision ON decision.module1_run_id=activation.module1_run_id AND decision.scenario_id=activation.scenario_id AND decision.merchant_application_id=activation.merchant_application_id WHERE activation.module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND activation.portfolio_activated_flag AND activation.activation_total_repayment_amount IS DISTINCT FROM decision.final_total_repayment_amount)),FALSE),
        'Total Repayment Equals Final Offer preserves M2.3 terms.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_057_FINANCE_CHARGE_EQUALS_FINAL_OFFER',
        'FINANCE_CHARGE_EQUALS_FINAL_OFFER',
        ((SELECT count(*) FROM msbf_m2.application_booking_funding_activation_latest AS activation JOIN msbf_m2.application_final_offer_decision_latest AS decision ON decision.module1_run_id=activation.module1_run_id AND decision.scenario_id=activation.scenario_id AND decision.merchant_application_id=activation.merchant_application_id WHERE activation.module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND activation.portfolio_activated_flag AND activation.activation_finance_charge_amount IS DISTINCT FROM decision.final_finance_charge_amount)::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_booking_funding_activation_latest AS activation JOIN msbf_m2.application_final_offer_decision_latest AS decision ON decision.module1_run_id=activation.module1_run_id AND decision.scenario_id=activation.scenario_id AND decision.merchant_application_id=activation.merchant_application_id WHERE activation.module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND activation.portfolio_activated_flag AND activation.activation_finance_charge_amount IS DISTINCT FROM decision.final_finance_charge_amount)),FALSE),
        'Finance Charge Equals Final Offer preserves M2.3 terms.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_058_DATE_ORDER',
        'DATE_ORDER',
        ((SELECT count(*) FROM msbf_m2.application_booking_funding_activation_latest WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND portfolio_activated_flag AND NOT (booking_date<=funding_date AND funding_date<=portfolio_activation_date AND funding_date<=monitoring_start_date AND funding_date<first_expected_remittance_date))::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_booking_funding_activation_latest WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND portfolio_activated_flag AND NOT (booking_date<=funding_date AND funding_date<=portfolio_activation_date AND funding_date<=monitoring_start_date AND funding_date<first_expected_remittance_date))),FALSE),
        'Booking, funding, activation, monitoring and remittance dates are ordered.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_059_SYNTHETIC_ACCEPTANCE_IDENTITY',
        'SYNTHETIC_ACCEPTANCE_IDENTITY',
        ((SELECT count(*) FROM msbf_m2.application_booking_funding_activation_latest WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND synthetic_offer_acceptance_assumed_flag IS DISTINCT FROM portfolio_activated_flag)::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_booking_funding_activation_latest WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND synthetic_offer_acceptance_assumed_flag IS DISTINCT FROM portfolio_activated_flag)),FALSE),
        'Synthetic acceptance is explicit only for activated offers.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_060_OPERATIONAL_BOUNDARY_FLAGS',
        'OPERATIONAL_BOUNDARY_FLAGS',
        ((SELECT count(*) FROM msbf_m2.application_booking_funding_activation_latest WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND (real_funds_movement_flag OR external_notice_generation_authorized_flag OR external_notice_transmitted_flag OR production_adverse_action_notice_flag))::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_booking_funding_activation_latest WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND (real_funds_movement_flag OR external_notice_generation_authorized_flag OR external_notice_transmitted_flag OR production_adverse_action_notice_flag))),FALSE),
        'No real-world movement or notice flags are set.'
    );
    /* ----------------------------------------------------------------------
    Controls 061–069 — notice, reason, outcome and sub-ledger linkage integrity
    ---------------------------------------------------------------------- */
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_061_NOTICE_MAPPING',
        'NOTICE_MAPPING',
        ((SELECT count(*) FROM msbf_m2.application_booking_funding_activation_latest WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND notice_control_code IS DISTINCT FROM CASE activation_outcome_code WHEN 'BOOKED_FUNDED_PORTFOLIO_ACTIVATED' THEN 'FUNDING_CONFIRMATION_INTERNAL_ONLY' WHEN 'ACTIVATION_REVIEW_REQUIRED' THEN 'ACTIVATION_REVIEW_INTERNAL_ONLY' WHEN 'NOT_ACTIVATED_INSUFFICIENT_EVIDENCE' THEN 'DECLINE_NOTICE_SUPPRESSED_SYNTHETIC' WHEN 'NOT_ACTIVATED_POLICY_DECLINE' THEN 'DECLINE_NOTICE_SUPPRESSED_SYNTHETIC' ELSE 'NO_NOTICE_SOURCE_BOUNDARY' END)::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_booking_funding_activation_latest WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND notice_control_code IS DISTINCT FROM CASE activation_outcome_code WHEN 'BOOKED_FUNDED_PORTFOLIO_ACTIVATED' THEN 'FUNDING_CONFIRMATION_INTERNAL_ONLY' WHEN 'ACTIVATION_REVIEW_REQUIRED' THEN 'ACTIVATION_REVIEW_INTERNAL_ONLY' WHEN 'NOT_ACTIVATED_INSUFFICIENT_EVIDENCE' THEN 'DECLINE_NOTICE_SUPPRESSED_SYNTHETIC' WHEN 'NOT_ACTIVATED_POLICY_DECLINE' THEN 'DECLINE_NOTICE_SUPPRESSED_SYNTHETIC' ELSE 'NO_NOTICE_SOURCE_BOUNDARY' END)),FALSE),
        'Notice-control mapping follows activation outcome.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_062_PRIMARY_REASON_PRESENT',
        'PRIMARY_REASON_PRESENT',
        ((SELECT count(*) FROM msbf_m2.application_booking_funding_activation_latest WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND primary_activation_reason_code IS NULL)::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_booking_funding_activation_latest WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND primary_activation_reason_code IS NULL)),FALSE),
        'Every activation row has a primary reason.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_063_REASON_ARRAY_PRESENT',
        'REASON_ARRAY_PRESENT',
        ((SELECT count(*) FROM msbf_m2.application_booking_funding_activation_latest WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND (activation_reason_codes IS NULL OR jsonb_typeof(activation_reason_codes)<>'array' OR jsonb_array_length(activation_reason_codes)=0))::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_booking_funding_activation_latest WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND (activation_reason_codes IS NULL OR jsonb_typeof(activation_reason_codes)<>'array' OR jsonb_array_length(activation_reason_codes)=0))),FALSE),
        'Every activation row has a nonempty reason array.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_064_OUTCOME_FK',
        'OUTCOME_FK',
        ((SELECT count(*) FROM msbf_m2.application_booking_funding_activation_latest AS activation LEFT JOIN msbf_m2.booking_funding_activation_outcome_definition AS outcome ON outcome.module1_run_id=activation.module1_run_id AND outcome.activation_outcome_code=activation.activation_outcome_code WHERE activation.module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND outcome.activation_outcome_code IS NULL)::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_booking_funding_activation_latest AS activation LEFT JOIN msbf_m2.booking_funding_activation_outcome_definition AS outcome ON outcome.module1_run_id=activation.module1_run_id AND outcome.activation_outcome_code=activation.activation_outcome_code WHERE activation.module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND outcome.activation_outcome_code IS NULL)),FALSE),
        'All activation outcomes resolve to the dictionary.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_065_REASON_FK',
        'REASON_FK_AND_OUTCOME_MAPPING',
        ((
            SELECT count(*)
            FROM msbf_m2.application_booking_funding_activation_latest AS activation
            LEFT JOIN msbf_m2.booking_funding_reason_definition AS primary_reason
              ON primary_reason.module1_run_id = activation.module1_run_id
             AND primary_reason.activation_reason_code =
                 activation.primary_activation_reason_code
            WHERE activation.module1_run_id =
                  (SELECT run_id FROM _m2_4_vctx)
              AND
              (
                  primary_reason.activation_reason_code IS NULL
                  OR primary_reason.mapped_activation_outcome_code IS DISTINCT FROM
                     activation.activation_outcome_code
                  OR EXISTS
                     (
                         SELECT 1
                         FROM jsonb_array_elements_text
                              (activation.activation_reason_codes) AS reason_value
                         WHERE NOT EXISTS
                         (
                             SELECT 1
                             FROM msbf_m2.booking_funding_reason_definition AS reason
                             WHERE reason.module1_run_id = activation.module1_run_id
                               AND reason.activation_reason_code = reason_value.value
                               AND reason.mapped_activation_outcome_code =
                                   activation.activation_outcome_code
                         )
                     )
              )
        )::text)::text,
        '0',
        coalesce
        (
            ((
                SELECT count(*) = 0
                FROM msbf_m2.application_booking_funding_activation_latest AS activation
                LEFT JOIN msbf_m2.booking_funding_reason_definition AS primary_reason
                  ON primary_reason.module1_run_id = activation.module1_run_id
                 AND primary_reason.activation_reason_code =
                     activation.primary_activation_reason_code
                WHERE activation.module1_run_id =
                      (SELECT run_id FROM _m2_4_vctx)
                  AND
                  (
                      primary_reason.activation_reason_code IS NULL
                      OR primary_reason.mapped_activation_outcome_code IS DISTINCT FROM
                         activation.activation_outcome_code
                      OR EXISTS
                         (
                             SELECT 1
                             FROM jsonb_array_elements_text
                                  (activation.activation_reason_codes) AS reason_value
                             WHERE NOT EXISTS
                             (
                                 SELECT 1
                                 FROM msbf_m2.booking_funding_reason_definition AS reason
                                 WHERE reason.module1_run_id = activation.module1_run_id
                                   AND reason.activation_reason_code = reason_value.value
                                   AND reason.mapped_activation_outcome_code =
                                       activation.activation_outcome_code
                             )
                         )
                  )
            )),
            FALSE
        ),
        'All primary and supporting reason codes resolve to the dictionary and map to the row activation outcome.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_066_NOTICE_FK',
        'NOTICE_FK',
        ((SELECT count(*) FROM msbf_m2.application_booking_funding_activation_latest AS activation LEFT JOIN msbf_m2.external_notice_control_definition AS notice ON notice.module1_run_id=activation.module1_run_id AND notice.notice_control_code=activation.notice_control_code WHERE activation.module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND notice.notice_control_code IS NULL)::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_booking_funding_activation_latest AS activation LEFT JOIN msbf_m2.external_notice_control_definition AS notice ON notice.module1_run_id=activation.module1_run_id AND notice.notice_control_code=activation.notice_control_code WHERE activation.module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND notice.notice_control_code IS NULL)),FALSE),
        'All notice controls resolve to the dictionary.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_067_ACCOUNT_LINK',
        'ACCOUNT_LINK',
        ((SELECT count(*) FROM msbf_m2.application_booking_funding_activation_latest AS activation LEFT JOIN msbf_m2.synthetic_account_activation AS account ON account.module1_run_id=activation.module1_run_id AND account.scenario_id=activation.scenario_id AND account.merchant_application_id=activation.merchant_application_id WHERE activation.module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND ((activation.portfolio_activated_flag AND (account.row_hash IS NULL OR account.synthetic_account_id IS DISTINCT FROM activation.synthetic_account_id)) OR (NOT activation.portfolio_activated_flag AND account.row_hash IS NOT NULL)))::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_booking_funding_activation_latest AS activation LEFT JOIN msbf_m2.synthetic_account_activation AS account ON account.module1_run_id=activation.module1_run_id AND account.scenario_id=activation.scenario_id AND account.merchant_application_id=activation.merchant_application_id WHERE activation.module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND ((activation.portfolio_activated_flag AND (account.row_hash IS NULL OR account.synthetic_account_id IS DISTINCT FROM activation.synthetic_account_id)) OR (NOT activation.portfolio_activated_flag AND account.row_hash IS NOT NULL)))),FALSE),
        'Account Link is complete and exclusive to activated rows.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_068_ADVANCE_LINK',
        'ADVANCE_LINK',
        ((SELECT count(*) FROM msbf_m2.application_booking_funding_activation_latest AS activation LEFT JOIN msbf_m2.synthetic_advance_funding AS advance ON advance.module1_run_id=activation.module1_run_id AND advance.scenario_id=activation.scenario_id AND advance.merchant_application_id=activation.merchant_application_id WHERE activation.module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND ((activation.portfolio_activated_flag AND (advance.row_hash IS NULL OR advance.synthetic_advance_id IS DISTINCT FROM activation.synthetic_advance_id)) OR (NOT activation.portfolio_activated_flag AND advance.row_hash IS NOT NULL)))::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_booking_funding_activation_latest AS activation LEFT JOIN msbf_m2.synthetic_advance_funding AS advance ON advance.module1_run_id=activation.module1_run_id AND advance.scenario_id=activation.scenario_id AND advance.merchant_application_id=activation.merchant_application_id WHERE activation.module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND ((activation.portfolio_activated_flag AND (advance.row_hash IS NULL OR advance.synthetic_advance_id IS DISTINCT FROM activation.synthetic_advance_id)) OR (NOT activation.portfolio_activated_flag AND advance.row_hash IS NOT NULL)))),FALSE),
        'Advance Link is complete and exclusive to activated rows.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_069_PORTFOLIO_LINK',
        'PORTFOLIO_LINK',
        ((SELECT count(*) FROM msbf_m2.application_booking_funding_activation_latest AS activation LEFT JOIN msbf_m2.initial_portfolio_activation AS portfolio ON portfolio.module1_run_id=activation.module1_run_id AND portfolio.scenario_id=activation.scenario_id AND portfolio.merchant_application_id=activation.merchant_application_id WHERE activation.module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND ((activation.portfolio_activated_flag AND (portfolio.row_hash IS NULL OR portfolio.synthetic_advance_id IS DISTINCT FROM activation.synthetic_advance_id)) OR (NOT activation.portfolio_activated_flag AND portfolio.row_hash IS NOT NULL)))::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_booking_funding_activation_latest AS activation LEFT JOIN msbf_m2.initial_portfolio_activation AS portfolio ON portfolio.module1_run_id=activation.module1_run_id AND portfolio.scenario_id=activation.scenario_id AND portfolio.merchant_application_id=activation.merchant_application_id WHERE activation.module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND ((activation.portfolio_activated_flag AND (portfolio.row_hash IS NULL OR portfolio.synthetic_advance_id IS DISTINCT FROM activation.synthetic_advance_id)) OR (NOT activation.portfolio_activated_flag AND portfolio.row_hash IS NOT NULL)))),FALSE),
        'Portfolio Link is complete and exclusive to activated rows.'
    );
    /* ----------------------------------------------------------------------
    Controls 070–095 — physical row hashes, lineage, set hashes and contract identity
    ---------------------------------------------------------------------- */
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_070_ACCOUNT_HASH',
        'ACCOUNT_HASH',
        ((SELECT count(*) FROM msbf_m2.synthetic_account_activation AS row_value WHERE row_value.module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND row_value.row_hash IS DISTINCT FROM msbf_ctl.m2_4_hash_jsonb(to_jsonb(row_value)-'row_hash'-'created_at'))::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.synthetic_account_activation AS row_value WHERE row_value.module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND row_value.row_hash IS DISTINCT FROM msbf_ctl.m2_4_hash_jsonb(to_jsonb(row_value)-'row_hash'-'created_at'))),FALSE),
        'Account Hash reconstructs physically.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_071_ADVANCE_HASH',
        'ADVANCE_HASH',
        ((SELECT count(*) FROM msbf_m2.synthetic_advance_funding AS row_value WHERE row_value.module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND row_value.row_hash IS DISTINCT FROM msbf_ctl.m2_4_hash_jsonb(to_jsonb(row_value)-'row_hash'-'created_at'))::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.synthetic_advance_funding AS row_value WHERE row_value.module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND row_value.row_hash IS DISTINCT FROM msbf_ctl.m2_4_hash_jsonb(to_jsonb(row_value)-'row_hash'-'created_at'))),FALSE),
        'Advance Hash reconstructs physically.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_072_PORTFOLIO_HASH',
        'PORTFOLIO_HASH',
        ((SELECT count(*) FROM msbf_m2.initial_portfolio_activation AS row_value WHERE row_value.module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND row_value.row_hash IS DISTINCT FROM msbf_ctl.m2_4_hash_jsonb(to_jsonb(row_value)-'row_hash'-'created_at'))::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.initial_portfolio_activation AS row_value WHERE row_value.module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND row_value.row_hash IS DISTINCT FROM msbf_ctl.m2_4_hash_jsonb(to_jsonb(row_value)-'row_hash'-'created_at'))),FALSE),
        'Portfolio Hash reconstructs physically.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_073_SOURCE_HASH',
        'SOURCE_HASH',
        ((SELECT count(*) FROM msbf_m2.application_booking_funding_source_snapshot AS row_value WHERE row_value.module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND row_value.row_hash IS DISTINCT FROM msbf_ctl.m2_4_hash_jsonb(to_jsonb(row_value)-'row_hash'-'created_at'))::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_booking_funding_source_snapshot AS row_value WHERE row_value.module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND row_value.row_hash IS DISTINCT FROM msbf_ctl.m2_4_hash_jsonb(to_jsonb(row_value)-'row_hash'-'created_at'))),FALSE),
        'Source Hash reconstructs physically.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_074_ACTIVATION_SNAPSHOT_HASH',
        'ACTIVATION_SNAPSHOT_HASH',
        ((SELECT count(*) FROM msbf_m2.application_booking_funding_activation_snapshot AS row_value WHERE row_value.module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND row_value.row_hash IS DISTINCT FROM msbf_ctl.m2_4_hash_jsonb(to_jsonb(row_value)-'row_hash'-'created_at'))::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_booking_funding_activation_snapshot AS row_value WHERE row_value.module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND row_value.row_hash IS DISTINCT FROM msbf_ctl.m2_4_hash_jsonb(to_jsonb(row_value)-'row_hash'-'created_at'))),FALSE),
        'Activation Snapshot Hash reconstructs physically.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_075_LATEST_HASH',
        'LATEST_HASH',
        ((SELECT count(*) FROM msbf_m2.application_booking_funding_activation_latest AS row_value WHERE row_value.module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND row_value.contract_row_hash IS DISTINCT FROM msbf_ctl.m2_4_hash_jsonb(to_jsonb(row_value)-'contract_row_hash'-'created_at'))::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_booking_funding_activation_latest AS row_value WHERE row_value.module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND row_value.contract_row_hash IS DISTINCT FROM msbf_ctl.m2_4_hash_jsonb(to_jsonb(row_value)-'contract_row_hash'-'created_at'))),FALSE),
        'Latest Hash reconstructs physically.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_076_ARCHIVE_HASH',
        'ARCHIVE_HASH',
        ((SELECT count(*) FROM msbf_m2.application_booking_funding_activation_archive AS row_value WHERE row_value.module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND row_value.archive_row_hash IS DISTINCT FROM msbf_ctl.m2_4_hash_jsonb(to_jsonb(row_value)-'archive_id'-'archive_row_hash'-'archived_at'-'created_at'))::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_booking_funding_activation_archive AS row_value WHERE row_value.module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND row_value.archive_row_hash IS DISTINCT FROM msbf_ctl.m2_4_hash_jsonb(to_jsonb(row_value)-'archive_id'-'archive_row_hash'-'archived_at'-'created_at'))),FALSE),
        'Archive Hash reconstructs physically.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_077_LATEST_ARCHIVE_REPRODUCTION',
        'LATEST_ARCHIVE_REPRODUCTION',
        ((SELECT count(*) FROM msbf_m2.application_booking_funding_activation_latest AS latest FULL OUTER JOIN msbf_m2.application_booking_funding_activation_archive AS archive ON archive.module1_run_id=latest.module1_run_id AND archive.contract_version=latest.contract_version AND archive.scenario_id=latest.scenario_id AND archive.merchant_application_id=latest.merchant_application_id WHERE coalesce(latest.module1_run_id,archive.module1_run_id)=(SELECT run_id FROM _m2_4_vctx) AND (latest.contract_row_hash IS DISTINCT FROM archive.contract_row_hash OR archive.contract_payload IS DISTINCT FROM (to_jsonb(latest)-'created_at')))::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_booking_funding_activation_latest AS latest FULL OUTER JOIN msbf_m2.application_booking_funding_activation_archive AS archive ON archive.module1_run_id=latest.module1_run_id AND archive.contract_version=latest.contract_version AND archive.scenario_id=latest.scenario_id AND archive.merchant_application_id=latest.merchant_application_id WHERE coalesce(latest.module1_run_id,archive.module1_run_id)=(SELECT run_id FROM _m2_4_vctx) AND (latest.contract_row_hash IS DISTINCT FROM archive.contract_row_hash OR archive.contract_payload IS DISTINCT FROM (to_jsonb(latest)-'created_at')))),FALSE),
        'Latest and archive reproduce exactly.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_078_SOURCE_M2_3_LINEAGE',
        'SOURCE_M2_3_LINEAGE',
        ((SELECT count(*) FROM msbf_m2.application_booking_funding_source_snapshot AS source JOIN msbf_m2.application_final_offer_decision_latest AS decision ON decision.module1_run_id=source.module1_run_id AND decision.scenario_id=source.scenario_id AND decision.merchant_application_id=source.merchant_application_id WHERE source.module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND source.source_m2_3_contract_row_hash IS DISTINCT FROM decision.contract_row_hash)::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_booking_funding_source_snapshot AS source JOIN msbf_m2.application_final_offer_decision_latest AS decision ON decision.module1_run_id=source.module1_run_id AND decision.scenario_id=source.scenario_id AND decision.merchant_application_id=source.merchant_application_id WHERE source.module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND source.source_m2_3_contract_row_hash IS DISTINCT FROM decision.contract_row_hash)),FALSE),
        'Source snapshot preserves M2.3 contract hash.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_079_ACTIVATION_SOURCE_LINEAGE',
        'ACTIVATION_SOURCE_LINEAGE',
        ((SELECT count(*) FROM msbf_m2.application_booking_funding_activation_snapshot AS activation JOIN msbf_m2.application_booking_funding_source_snapshot AS source ON source.module1_run_id=activation.module1_run_id AND source.scenario_id=activation.scenario_id AND source.merchant_application_id=activation.merchant_application_id WHERE activation.module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND activation.source_snapshot_row_hash IS DISTINCT FROM source.row_hash)::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_booking_funding_activation_snapshot AS activation JOIN msbf_m2.application_booking_funding_source_snapshot AS source ON source.module1_run_id=activation.module1_run_id AND source.scenario_id=activation.scenario_id AND source.merchant_application_id=activation.merchant_application_id WHERE activation.module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND activation.source_snapshot_row_hash IS DISTINCT FROM source.row_hash)),FALSE),
        'Activation snapshot preserves source row hash.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_080_ACCOUNT_SOURCE_LINEAGE',
        'ACCOUNT_SOURCE_LINEAGE',
        ((SELECT count(*) FROM msbf_m2.synthetic_account_activation AS account JOIN msbf_m2.application_booking_funding_activation_snapshot AS activation ON activation.module1_run_id=account.module1_run_id AND activation.scenario_id=account.scenario_id AND activation.merchant_application_id=account.merchant_application_id WHERE account.module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND account.source_activation_row_hash IS DISTINCT FROM activation.row_hash)::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.synthetic_account_activation AS account JOIN msbf_m2.application_booking_funding_activation_snapshot AS activation ON activation.module1_run_id=account.module1_run_id AND activation.scenario_id=account.scenario_id AND activation.merchant_application_id=account.merchant_application_id WHERE account.module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND account.source_activation_row_hash IS DISTINCT FROM activation.row_hash)),FALSE),
        'Account activation preserves activation row hash.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_081_ADVANCE_SOURCE_LINEAGE',
        'ADVANCE_SOURCE_LINEAGE',
        ((SELECT count(*) FROM msbf_m2.synthetic_advance_funding AS advance JOIN msbf_m2.application_booking_funding_activation_snapshot AS activation ON activation.module1_run_id=advance.module1_run_id AND activation.scenario_id=advance.scenario_id AND activation.merchant_application_id=advance.merchant_application_id WHERE advance.module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND advance.source_activation_row_hash IS DISTINCT FROM activation.row_hash)::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.synthetic_advance_funding AS advance JOIN msbf_m2.application_booking_funding_activation_snapshot AS activation ON activation.module1_run_id=advance.module1_run_id AND activation.scenario_id=advance.scenario_id AND activation.merchant_application_id=advance.merchant_application_id WHERE advance.module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND advance.source_activation_row_hash IS DISTINCT FROM activation.row_hash)),FALSE),
        'Advance funding preserves activation row hash.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_082_PORTFOLIO_SOURCE_LINEAGE',
        'PORTFOLIO_SOURCE_LINEAGE',
        ((SELECT count(*) FROM msbf_m2.initial_portfolio_activation AS portfolio JOIN msbf_m2.synthetic_advance_funding AS advance ON advance.module1_run_id=portfolio.module1_run_id AND advance.scenario_id=portfolio.scenario_id AND advance.merchant_application_id=portfolio.merchant_application_id WHERE portfolio.module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND portfolio.source_advance_row_hash IS DISTINCT FROM advance.row_hash)::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.initial_portfolio_activation AS portfolio JOIN msbf_m2.synthetic_advance_funding AS advance ON advance.module1_run_id=portfolio.module1_run_id AND advance.scenario_id=portfolio.scenario_id AND advance.merchant_application_id=portfolio.merchant_application_id WHERE portfolio.module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND portfolio.source_advance_row_hash IS DISTINCT FROM advance.row_hash)),FALSE),
        'Portfolio activation preserves advance row hash.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_083_POLICY_SET_HASH',
        'POLICY_SET_HASH',
        ((SELECT policy_set_hash FROM msbf_ctl.m2_4_portfolio_activation_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx)))::text,
        'physical reconstruction',
        coalesce(((SELECT registry.policy_set_hash IS NOT DISTINCT FROM (SELECT md5(string_agg(row_hash,'|' ORDER BY module1_run_id)) FROM msbf_ctl.m2_4_policy_profile WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx)) FROM msbf_ctl.m2_4_portfolio_activation_contract_registry AS registry WHERE registry.module1_run_id=(SELECT run_id FROM _m2_4_vctx))),FALSE),
        'Policy Set Hash reconciles physically.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_084_OUTCOME_SET_HASH',
        'OUTCOME_SET_HASH',
        ((SELECT outcome_set_hash FROM msbf_ctl.m2_4_portfolio_activation_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx)))::text,
        'physical reconstruction',
        coalesce(((SELECT registry.outcome_set_hash IS NOT DISTINCT FROM (SELECT md5(string_agg(row_hash,'|' ORDER BY activation_outcome_rank,activation_outcome_code)) FROM msbf_m2.booking_funding_activation_outcome_definition WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx)) FROM msbf_ctl.m2_4_portfolio_activation_contract_registry AS registry WHERE registry.module1_run_id=(SELECT run_id FROM _m2_4_vctx))),FALSE),
        'Outcome Set Hash reconciles physically.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_085_REASON_SET_HASH',
        'REASON_SET_HASH',
        ((SELECT reason_set_hash FROM msbf_ctl.m2_4_portfolio_activation_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx)))::text,
        'physical reconstruction',
        coalesce(((SELECT registry.reason_set_hash IS NOT DISTINCT FROM (SELECT md5(string_agg(row_hash,'|' ORDER BY activation_reason_code)) FROM msbf_m2.booking_funding_reason_definition WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx)) FROM msbf_ctl.m2_4_portfolio_activation_contract_registry AS registry WHERE registry.module1_run_id=(SELECT run_id FROM _m2_4_vctx))),FALSE),
        'Reason Set Hash reconciles physically.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_086_NOTICE_SET_HASH',
        'NOTICE_SET_HASH',
        ((SELECT notice_control_set_hash FROM msbf_ctl.m2_4_portfolio_activation_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx)))::text,
        'physical reconstruction',
        coalesce(((SELECT registry.notice_control_set_hash IS NOT DISTINCT FROM (SELECT md5(string_agg(row_hash,'|' ORDER BY notice_control_code)) FROM msbf_m2.external_notice_control_definition WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx)) FROM msbf_ctl.m2_4_portfolio_activation_contract_registry AS registry WHERE registry.module1_run_id=(SELECT run_id FROM _m2_4_vctx))),FALSE),
        'Notice Set Hash reconciles physically.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_087_SOURCE_SET_HASH',
        'SOURCE_SET_HASH',
        ((SELECT source_set_hash FROM msbf_ctl.m2_4_portfolio_activation_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx)))::text,
        'physical reconstruction',
        coalesce(((SELECT registry.source_set_hash IS NOT DISTINCT FROM (SELECT md5(string_agg(scenario_id::text||'|'||merchant_application_id||'|'||row_hash,'|' ORDER BY scenario_id,merchant_application_id)) FROM msbf_m2.application_booking_funding_source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx)) FROM msbf_ctl.m2_4_portfolio_activation_contract_registry AS registry WHERE registry.module1_run_id=(SELECT run_id FROM _m2_4_vctx))),FALSE),
        'Source Set Hash reconciles physically.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_088_ACTIVATION_SNAPSHOT_SET_HASH',
        'ACTIVATION_SNAPSHOT_SET_HASH',
        ((SELECT activation_snapshot_set_hash FROM msbf_ctl.m2_4_portfolio_activation_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx)))::text,
        'physical reconstruction',
        coalesce(((SELECT registry.activation_snapshot_set_hash IS NOT DISTINCT FROM (SELECT md5(string_agg(scenario_id::text||'|'||merchant_application_id||'|'||row_hash,'|' ORDER BY scenario_id,merchant_application_id)) FROM msbf_m2.application_booking_funding_activation_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx)) FROM msbf_ctl.m2_4_portfolio_activation_contract_registry AS registry WHERE registry.module1_run_id=(SELECT run_id FROM _m2_4_vctx))),FALSE),
        'Activation Snapshot Set Hash reconciles physically.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_089_LATEST_SET_HASH',
        'LATEST_SET_HASH',
        ((SELECT activation_latest_set_hash FROM msbf_ctl.m2_4_portfolio_activation_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx)))::text,
        'physical reconstruction',
        coalesce(((SELECT registry.activation_latest_set_hash IS NOT DISTINCT FROM (SELECT md5(string_agg(scenario_id::text||'|'||merchant_application_id||'|'||contract_row_hash,'|' ORDER BY scenario_id,merchant_application_id)) FROM msbf_m2.application_booking_funding_activation_latest WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx)) FROM msbf_ctl.m2_4_portfolio_activation_contract_registry AS registry WHERE registry.module1_run_id=(SELECT run_id FROM _m2_4_vctx))),FALSE),
        'Latest Set Hash reconciles physically.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_090_ARCHIVE_SET_HASH',
        'ARCHIVE_SET_HASH',
        ((SELECT activation_archive_set_hash FROM msbf_ctl.m2_4_portfolio_activation_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx)))::text,
        'physical reconstruction',
        coalesce(((SELECT registry.activation_archive_set_hash IS NOT DISTINCT FROM (SELECT md5(string_agg(scenario_id::text||'|'||merchant_application_id||'|'||archive_row_hash,'|' ORDER BY scenario_id,merchant_application_id)) FROM msbf_m2.application_booking_funding_activation_archive WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx)) FROM msbf_ctl.m2_4_portfolio_activation_contract_registry AS registry WHERE registry.module1_run_id=(SELECT run_id FROM _m2_4_vctx))),FALSE),
        'Archive Set Hash reconciles physically.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_091_ACCOUNT_SET_HASH',
        'ACCOUNT_SET_HASH',
        ((SELECT account_set_hash FROM msbf_ctl.m2_4_portfolio_activation_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx)))::text,
        'physical reconstruction',
        coalesce(((SELECT registry.account_set_hash IS NOT DISTINCT FROM (SELECT md5(string_agg(scenario_id::text||'|'||merchant_application_id||'|'||row_hash,'|' ORDER BY scenario_id,merchant_application_id)) FROM msbf_m2.synthetic_account_activation WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx)) FROM msbf_ctl.m2_4_portfolio_activation_contract_registry AS registry WHERE registry.module1_run_id=(SELECT run_id FROM _m2_4_vctx))),FALSE),
        'Account Set Hash reconciles physically.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_092_ADVANCE_SET_HASH',
        'ADVANCE_SET_HASH',
        ((SELECT advance_set_hash FROM msbf_ctl.m2_4_portfolio_activation_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx)))::text,
        'physical reconstruction',
        coalesce(((SELECT registry.advance_set_hash IS NOT DISTINCT FROM (SELECT md5(string_agg(scenario_id::text||'|'||merchant_application_id||'|'||row_hash,'|' ORDER BY scenario_id,merchant_application_id)) FROM msbf_m2.synthetic_advance_funding WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx)) FROM msbf_ctl.m2_4_portfolio_activation_contract_registry AS registry WHERE registry.module1_run_id=(SELECT run_id FROM _m2_4_vctx))),FALSE),
        'Advance Set Hash reconciles physically.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_093_PORTFOLIO_SET_HASH',
        'PORTFOLIO_SET_HASH',
        ((SELECT portfolio_set_hash FROM msbf_ctl.m2_4_portfolio_activation_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx)))::text,
        'physical reconstruction',
        coalesce(((SELECT registry.portfolio_set_hash IS NOT DISTINCT FROM (SELECT md5(string_agg(scenario_id::text||'|'||merchant_application_id||'|'||row_hash,'|' ORDER BY scenario_id,merchant_application_id)) FROM msbf_m2.initial_portfolio_activation WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx)) FROM msbf_ctl.m2_4_portfolio_activation_contract_registry AS registry WHERE registry.module1_run_id=(SELECT run_id FROM _m2_4_vctx))),FALSE),
        'Portfolio Set Hash reconciles physically.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_094_CONTRACT_SET_HASH',
        'CONTRACT_SET_HASH',
        ((SELECT contract_set_hash FROM msbf_ctl.m2_4_portfolio_activation_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx)))::text,
        'physical reconstruction',
        coalesce(((SELECT registry.contract_set_hash IS NOT DISTINCT FROM (SELECT md5(row_hash) FROM msbf_ctl.m2_4_portfolio_activation_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx)) FROM msbf_ctl.m2_4_portfolio_activation_contract_registry AS registry WHERE registry.module1_run_id=(SELECT run_id FROM _m2_4_vctx))),FALSE),
        'Contract Set Hash reconciles physically.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_095_COMBINED_HASH_SHAPE',
        'COMBINED_HASH_SHAPE',
        ((SELECT combined_set_hash FROM msbf_ctl.m2_4_portfolio_activation_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx)))::text,
        '32-character lowercase hex',
        coalesce(((SELECT length(combined_set_hash)=32 AND combined_set_hash ~ '^[0-9a-f]+$' FROM msbf_ctl.m2_4_portfolio_activation_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx))),FALSE),
        'Combined canonical hash has valid shape.'
    );
    /* ----------------------------------------------------------------------
    Controls 096–106 — matched baseline/stress non-improvement certification
    ---------------------------------------------------------------------- */
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_096_COMPARISON_APPLICATIONS',
        'COMPARISON_APPLICATIONS',
        ((SELECT count(*) FROM msbf_m2.v_m2_4_matched_scenario_comparison WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx))::text)::text,
        '750',
        coalesce(((SELECT count(*)=750 FROM msbf_m2.v_m2_4_matched_scenario_comparison WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx))),FALSE),
        'Matched comparison contains 750 rows.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_097_STRESS_ACTIVATION_NONIMPROVEMENT',
        'STRESS_ACTIVATION_NONIMPROVEMENT',
        ((SELECT count(*) FROM msbf_m2.v_m2_4_matched_scenario_comparison WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND stress_activation_improvement_flag)::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.v_m2_4_matched_scenario_comparison WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND stress_activation_improvement_flag)),FALSE),
        'Stress activation outcome is never more favorable than baseline.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_098_STRESS_AMOUNT_NONIMPROVEMENT',
        'STRESS_AMOUNT_NONIMPROVEMENT',
        ((SELECT count(*) FROM msbf_m2.v_m2_4_matched_scenario_comparison WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND stress_funded_amount_improvement_flag)::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.v_m2_4_matched_scenario_comparison WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND stress_funded_amount_improvement_flag)),FALSE),
        'Stress funded amount is never more favorable than baseline.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_099_BASELINE_BOOKED_FUNDED_PORTFOLIO_ACTIVATED',
        'BASELINE_BOOKED_FUNDED_PORTFOLIO_ACTIVATED',
        ((SELECT count(*) FROM msbf_m2.application_booking_funding_activation_latest WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND scenario_code='BASELINE' AND activation_outcome_code='BOOKED_FUNDED_PORTFOLIO_ACTIVATED')::text)::text,
        '44',
        coalesce(((SELECT count(*)=44 FROM msbf_m2.application_booking_funding_activation_latest WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND scenario_code='BASELINE' AND activation_outcome_code='BOOKED_FUNDED_PORTFOLIO_ACTIVATED')),FALSE),
        'BASELINE BOOKED_FUNDED_PORTFOLIO_ACTIVATED count is governed.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_100_RECESSION_ENERGY_BOOKED_FUNDED_PORTFOLIO_ACTIVATED',
        'RECESSION_ENERGY_BOOKED_FUNDED_PORTFOLIO_ACTIVATED',
        ((SELECT count(*) FROM msbf_m2.application_booking_funding_activation_latest WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND scenario_code='RECESSION_ENERGY' AND activation_outcome_code='BOOKED_FUNDED_PORTFOLIO_ACTIVATED')::text)::text,
        '15',
        coalesce(((SELECT count(*)=15 FROM msbf_m2.application_booking_funding_activation_latest WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND scenario_code='RECESSION_ENERGY' AND activation_outcome_code='BOOKED_FUNDED_PORTFOLIO_ACTIVATED')),FALSE),
        'RECESSION_ENERGY BOOKED_FUNDED_PORTFOLIO_ACTIVATED count is governed.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_101_BASELINE_ACTIVATION_REVIEW_REQUIRED',
        'BASELINE_ACTIVATION_REVIEW_REQUIRED',
        ((SELECT count(*) FROM msbf_m2.application_booking_funding_activation_latest WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND scenario_code='BASELINE' AND activation_outcome_code='ACTIVATION_REVIEW_REQUIRED')::text)::text,
        '139',
        coalesce(((SELECT count(*)=139 FROM msbf_m2.application_booking_funding_activation_latest WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND scenario_code='BASELINE' AND activation_outcome_code='ACTIVATION_REVIEW_REQUIRED')),FALSE),
        'BASELINE ACTIVATION_REVIEW_REQUIRED count is governed.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_102_RECESSION_ENERGY_ACTIVATION_REVIEW_REQUIRED',
        'RECESSION_ENERGY_ACTIVATION_REVIEW_REQUIRED',
        ((SELECT count(*) FROM msbf_m2.application_booking_funding_activation_latest WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND scenario_code='RECESSION_ENERGY' AND activation_outcome_code='ACTIVATION_REVIEW_REQUIRED')::text)::text,
        '51',
        coalesce(((SELECT count(*)=51 FROM msbf_m2.application_booking_funding_activation_latest WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND scenario_code='RECESSION_ENERGY' AND activation_outcome_code='ACTIVATION_REVIEW_REQUIRED')),FALSE),
        'RECESSION_ENERGY ACTIVATION_REVIEW_REQUIRED count is governed.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_103_BASELINE_NOT_ACTIVATED_POLICY_DECLINE',
        'BASELINE_NOT_ACTIVATED_POLICY_DECLINE',
        ((SELECT count(*) FROM msbf_m2.application_booking_funding_activation_latest WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND scenario_code='BASELINE' AND activation_outcome_code='NOT_ACTIVATED_POLICY_DECLINE')::text)::text,
        '524',
        coalesce(((SELECT count(*)=524 FROM msbf_m2.application_booking_funding_activation_latest WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND scenario_code='BASELINE' AND activation_outcome_code='NOT_ACTIVATED_POLICY_DECLINE')),FALSE),
        'BASELINE NOT_ACTIVATED_POLICY_DECLINE count is governed.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_104_RECESSION_ENERGY_NOT_ACTIVATED_POLICY_DECLINE',
        'RECESSION_ENERGY_NOT_ACTIVATED_POLICY_DECLINE',
        ((SELECT count(*) FROM msbf_m2.application_booking_funding_activation_latest WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND scenario_code='RECESSION_ENERGY' AND activation_outcome_code='NOT_ACTIVATED_POLICY_DECLINE')::text)::text,
        '549',
        coalesce(((SELECT count(*)=549 FROM msbf_m2.application_booking_funding_activation_latest WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND scenario_code='RECESSION_ENERGY' AND activation_outcome_code='NOT_ACTIVATED_POLICY_DECLINE')),FALSE),
        'RECESSION_ENERGY NOT_ACTIVATED_POLICY_DECLINE count is governed.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_105_BASELINE_NOT_ACTIVATED_INSUFFICIENT_EVIDENCE',
        'BASELINE_NOT_ACTIVATED_INSUFFICIENT_EVIDENCE',
        ((SELECT count(*) FROM msbf_m2.application_booking_funding_activation_latest WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND scenario_code='BASELINE' AND activation_outcome_code='NOT_ACTIVATED_INSUFFICIENT_EVIDENCE')::text)::text,
        '43',
        coalesce(((SELECT count(*)=43 FROM msbf_m2.application_booking_funding_activation_latest WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND scenario_code='BASELINE' AND activation_outcome_code='NOT_ACTIVATED_INSUFFICIENT_EVIDENCE')),FALSE),
        'BASELINE NOT_ACTIVATED_INSUFFICIENT_EVIDENCE count is governed.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_106_RECESSION_ENERGY_NOT_ACTIVATED_INSUFFICIENT_EVIDENCE',
        'RECESSION_ENERGY_NOT_ACTIVATED_INSUFFICIENT_EVIDENCE',
        ((SELECT count(*) FROM msbf_m2.application_booking_funding_activation_latest WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND scenario_code='RECESSION_ENERGY' AND activation_outcome_code='NOT_ACTIVATED_INSUFFICIENT_EVIDENCE')::text)::text,
        '135',
        coalesce(((SELECT count(*)=135 FROM msbf_m2.application_booking_funding_activation_latest WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND scenario_code='RECESSION_ENERGY' AND activation_outcome_code='NOT_ACTIVATED_INSUFFICIENT_EVIDENCE')),FALSE),
        'RECESSION_ENERGY NOT_ACTIVATED_INSUFFICIENT_EVIDENCE count is governed.'
    );
    /* ----------------------------------------------------------------------
    Controls 107–120 — future-stage, real-world, evidence and acceptance boundaries
    ---------------------------------------------------------------------- */
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_107_NO_M2_5_TABLES',
        'NO_M2_5_TABLES',
        ((SELECT count(*) FROM information_schema.tables WHERE table_schema IN ('msbf_m2','msbf_ctl') AND lower(table_name) LIKE 'm2_5%')::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM information_schema.tables WHERE table_schema IN ('msbf_m2','msbf_ctl') AND lower(table_name) LIKE 'm2_5%')),FALSE),
        'No M2.5 objects are created by M2.4.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_108_NO_REAL_WORLD_COLUMNS',
        'NO_REAL_WORLD_COLUMNS',
        ((SELECT count(*) FROM information_schema.columns WHERE table_schema='msbf_m2' AND table_name IN ('application_booking_funding_activation_snapshot','application_booking_funding_activation_latest','application_booking_funding_activation_archive','synthetic_account_activation','synthetic_advance_funding','initial_portfolio_activation') AND lower(column_name) IN ('ach_trace_number','bank_account_number','settlement_account_number','routing_number','real_account_number','core_booking_id','external_notice_payload','production_adverse_action_notice'))::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM information_schema.columns WHERE table_schema='msbf_m2' AND table_name IN ('application_booking_funding_activation_snapshot','application_booking_funding_activation_latest','application_booking_funding_activation_archive','synthetic_account_activation','synthetic_advance_funding','initial_portfolio_activation') AND lower(column_name) IN ('ach_trace_number','bank_account_number','settlement_account_number','routing_number','real_account_number','core_booking_id','external_notice_payload','production_adverse_action_notice'))),FALSE),
        'No prohibited real-world operational columns exist.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_109_GENERATION_EVIDENCE_COUNT',
        'GENERATION_EVIDENCE_COUNT',
        ((SELECT count(*) FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM _m2_4_vctx) AND evidence_code LIKE 'M2_4_%' AND evidence_code NOT LIKE 'M2_4_POS_%' AND evidence_code NOT LIKE 'M2_4_NEG_%')::text)::text,
        '24',
        coalesce(((SELECT count(*)=24 FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM _m2_4_vctx) AND evidence_code LIKE 'M2_4_%' AND evidence_code NOT LIKE 'M2_4_POS_%' AND evidence_code NOT LIKE 'M2_4_NEG_%')),FALSE),
        'Generation evidence inventory is 24 rows.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_110_FAILED_M2_4_EVIDENCE',
        'FAILED_M2_4_EVIDENCE',
        ((SELECT count(*) FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM _m2_4_vctx) AND evidence_code LIKE 'M2_4_%' AND status='FAIL')::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM _m2_4_vctx) AND evidence_code LIKE 'M2_4_%' AND status='FAIL')),FALSE),
        'No current M2.4 evidence is failed.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_111_CONTRACT_IDENTITY',
        'CONTRACT_IDENTITY',
        ((SELECT count(*) FROM msbf_m2.application_booking_funding_activation_latest WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND (contract_code<>'M2_PORTFOLIO_ACTIVATION_CONSUMPTION' OR contract_version<>1 OR schema_version<>'M2_4_PORTFOLIO_ACTIVATION_SCHEMA_V1' OR methodology_version<>'M2_4_METHOD_V1'))::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_booking_funding_activation_latest WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND (contract_code<>'M2_PORTFOLIO_ACTIVATION_CONSUMPTION' OR contract_version<>1 OR schema_version<>'M2_4_PORTFOLIO_ACTIVATION_SCHEMA_V1' OR methodology_version<>'M2_4_METHOD_V1'))),FALSE),
        'Latest contract identity is exact.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_112_DATES_ONLY_ACTIVATED',
        'DATES_ONLY_ACTIVATED',
        ((SELECT count(*) FROM msbf_m2.application_booking_funding_activation_latest WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND ((portfolio_activated_flag AND (booking_date IS NULL OR funding_date IS NULL OR portfolio_activation_date IS NULL)) OR (NOT portfolio_activated_flag AND (booking_date IS NOT NULL OR funding_date IS NOT NULL OR portfolio_activation_date IS NOT NULL))))::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_booking_funding_activation_latest WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND ((portfolio_activated_flag AND (booking_date IS NULL OR funding_date IS NULL OR portfolio_activation_date IS NULL)) OR (NOT portfolio_activated_flag AND (booking_date IS NOT NULL OR funding_date IS NOT NULL OR portfolio_activation_date IS NOT NULL))))),FALSE),
        'Operational dates exist only for activated rows.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_113_ACCOUNT_PREFIX',
        'ACCOUNT_PREFIX',
        ((SELECT count(*) FROM msbf_m2.synthetic_account_activation WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND synthetic_account_id NOT LIKE 'MSBF_ACCT_%')::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.synthetic_account_activation WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND synthetic_account_id NOT LIKE 'MSBF_ACCT_%')),FALSE),
        'Synthetic account identifiers use the governed prefix.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_114_ADVANCE_PREFIX',
        'ADVANCE_PREFIX',
        ((SELECT count(*) FROM msbf_m2.synthetic_advance_funding WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND synthetic_advance_id NOT LIKE 'MSBF_ADV_%')::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.synthetic_advance_funding WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND synthetic_advance_id NOT LIKE 'MSBF_ADV_%')),FALSE),
        'Synthetic advance identifiers use the governed prefix.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_115_ACCOUNT_STATUS',
        'ACCOUNT_STATUS',
        ((SELECT count(*) FROM msbf_m2.synthetic_account_activation WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND account_status<>'ACTIVE')::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.synthetic_account_activation WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND account_status<>'ACTIVE')),FALSE),
        'All synthetic accounts activate as ACTIVE.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_116_FUNDING_STATUS',
        'FUNDING_STATUS',
        ((SELECT count(*) FROM msbf_m2.synthetic_advance_funding WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND (funding_status<>'SYNTHETIC_FUNDED' OR real_funds_movement_flag))::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.synthetic_advance_funding WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND (funding_status<>'SYNTHETIC_FUNDED' OR real_funds_movement_flag))),FALSE),
        'Funding status is synthetic and no real funds move.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_117_PORTFOLIO_STATUS',
        'PORTFOLIO_STATUS',
        ((SELECT count(*) FROM msbf_m2.initial_portfolio_activation WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND portfolio_status<>'ACTIVE')::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.initial_portfolio_activation WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND portfolio_status<>'ACTIVE')),FALSE),
        'All initial portfolio positions are ACTIVE.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_118_PORTFOLIO_AMOUNT_IDENTITY',
        'PORTFOLIO_AMOUNT_IDENTITY',
        ((SELECT count(*) FROM msbf_m2.initial_portfolio_activation WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND (current_outstanding_balance_proxy IS DISTINCT FROM original_funded_amount OR initial_exposure_amount IS DISTINCT FROM original_funded_amount OR initial_expected_collection_amount<original_funded_amount))::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.initial_portfolio_activation WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND (current_outstanding_balance_proxy IS DISTINCT FROM original_funded_amount OR initial_exposure_amount IS DISTINCT FROM original_funded_amount OR initial_expected_collection_amount<original_funded_amount))),FALSE),
        'Initial portfolio amount identities reconcile.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_119_ACCEPTANCE_NOT_YET_WRITTEN',
        'ACCEPTANCE_NOT_YET_WRITTEN',
        ((SELECT count(*) FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM _m2_4_vctx) AND gate_id='M2_4_BOOKING_FUNDING_PORTFOLIO_ACTIVATION')::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM _m2_4_vctx) AND gate_id='M2_4_BOOKING_FUNDING_PORTFOLIO_ACTIVATION')),FALSE),
        'Acceptance gate is not written before validation completes.'
    );
    PERFORM pg_temp.m2_4_add_check
    (
        'M2_4_POS_120_REGISTRY_HASH_IDENTITY',
        'REGISTRY_HASH_IDENTITY',
        ((SELECT count(*) FROM msbf_ctl.m2_4_portfolio_activation_contract_registry AS registry WHERE registry.module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND (registry.row_hash IS DISTINCT FROM msbf_ctl.m2_4_registry_row_hash(to_jsonb(registry)) OR registry.contract_set_hash IS DISTINCT FROM md5(registry.row_hash)))::text)::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_ctl.m2_4_portfolio_activation_contract_registry AS registry WHERE registry.module1_run_id=(SELECT run_id FROM _m2_4_vctx) AND (registry.row_hash IS DISTINCT FROM msbf_ctl.m2_4_registry_row_hash(to_jsonb(registry)) OR registry.contract_set_hash IS DISTINCT FROM md5(registry.row_hash)))),FALSE),
        'Registry physical row and contract hashes reconcile.'
    );
END;
$m2_4_positive_controls$;

DO $m2_4_validation_finalize$
DECLARE
    v_total bigint;
    v_pass bigint;
    v_fail bigint;
BEGIN
    SELECT
        count(*),
        count(*) FILTER (WHERE status='PASS'),
        count(*) FILTER (WHERE status='FAIL')
    INTO v_total,v_pass,v_fail
    FROM _m2_4_validation;

    IF v_total <> 120 THEN
        RAISE EXCEPTION
            'M2.4 positive-control inventory failed: total %, expected %.',
            v_total,
            120;
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
        (SELECT run_id FROM _m2_4_vctx),
        validation.evidence_code,
        'PORTFOLIO',
        validation.metric_name,
        NULL::numeric(24,10),
        coalesce(validation.observed_value,'<NULL>'),
        'VALIDATION',
        validation.status,
        validation.interpretation ||
            ' Threshold: ' || coalesce(validation.threshold_value,'<NULL>')
    FROM _m2_4_validation AS validation
    ON CONFLICT(run_id,evidence_code,segment_key)
    DO UPDATE SET
        metric_name = EXCLUDED.metric_name,
        metric_value_numeric = NULL,
        metric_value_text = EXCLUDED.metric_value_text,
        unit_code = EXCLUDED.unit_code,
        status = EXCLUDED.status,
        interpretation = EXCLUDED.interpretation,
        created_at = clock_timestamp();

    IF v_pass = 120
       AND v_fail = 0 THEN
        UPDATE msbf_ctl.run_registry
        SET run_status='M2_4_VALIDATED'
        WHERE run_id=(SELECT run_id FROM _m2_4_vctx);

        UPDATE msbf_ctl.m2_4_portfolio_activation_contract_registry
        SET
            contract_status='VALIDATED',
            validated_at=clock_timestamp()
        WHERE module1_run_id=(SELECT run_id FROM _m2_4_vctx);
    ELSE
        UPDATE msbf_ctl.run_registry
        SET run_status='M2_4_FAILED'
        WHERE run_id=(SELECT run_id FROM _m2_4_vctx);

        RAISE EXCEPTION
            'M2.4 positive validation failed: pass %, fail %.',
            v_pass,
            v_fail;
    END IF;
END;
$m2_4_validation_finalize$;

COMMIT;

SELECT
    evidence_code,
    metric_name,
    observed_value,
    threshold_value,
    status,
    interpretation
FROM _m2_4_validation
ORDER BY evidence_code;
