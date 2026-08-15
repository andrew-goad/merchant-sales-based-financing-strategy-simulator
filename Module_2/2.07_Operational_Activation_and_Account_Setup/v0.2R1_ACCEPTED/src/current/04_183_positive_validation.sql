/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.7 — Operational Activation & Account Setup

Program     : 183_msbf_m2_7_operational_activation_validation_v0_2.sql
Version     : v0.2

Purpose
-------
Execute 120 positive controls across lifecycle, accepted source identity,
definitions, exact source mapping, setup terms, stage boundaries,
latest/archive reproduction, stress non-improvement, hashes, canonical
identity, and acceptance readiness.

Required result
---------------
120 / 120 PASS and run_status = M2_7_VALIDATED.
============================================================================ */

BEGIN;

SET LOCAL work_mem='160MB';
SET LOCAL statement_timeout='45min';
SET LOCAL jit=off;

DROP TABLE IF EXISTS _m2_7_validation;

CREATE TEMP TABLE _m2_7_validation
(
    evidence_code text PRIMARY KEY,
    metric_name text NOT NULL,
    observed_value text,
    threshold_value text,
    status text NOT NULL,
    interpretation text NOT NULL
)
ON COMMIT PRESERVE ROWS;

DROP TABLE IF EXISTS _m2_7_vctx;

CREATE TEMP TABLE _m2_7_vctx
ON COMMIT DROP
AS
SELECT run_id,run_status
FROM msbf_ctl.run_registry
WHERE run_code='M1_V0_2_BASELINE_BUILD'
  AND run_version=1;

DO $ready$
BEGIN
    PERFORM msbf_ctl.m2_7_assert_validation_ready
    (
        (SELECT run_id FROM _m2_7_vctx)
    );
END;
$ready$;

CREATE OR REPLACE FUNCTION pg_temp.m2_7_add_check
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
    INSERT INTO _m2_7_validation
    (
        evidence_code,metric_name,observed_value,
        threshold_value,status,interpretation
    )
    VALUES
    (
        p_code,p_metric,p_observed,p_threshold,
        CASE WHEN p_pass THEN 'PASS' ELSE 'FAIL' END,
        p_interpretation
    );
END;
$function$;

DO $controls$
BEGIN
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_001_RUN_STATUS',
        'RUN_STATUS',
        ((SELECT run_status FROM _m2_7_vctx))::text,
        'M2_7_GENERATED|M2_7_VALIDATED',
        coalesce(((SELECT run_status IN ('M2_7_GENERATED','M2_7_VALIDATED') FROM _m2_7_vctx)),FALSE),
        'Validation begins from aligned generated or validated state.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_002_POLICY_STATUS',
        'POLICY_STATUS',
        ((SELECT policy_status FROM msbf_ctl.m2_7_policy_profile WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx)))::text,
        'APPROVED',
        coalesce(((SELECT policy_status='APPROVED' FROM msbf_ctl.m2_7_policy_profile WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx))),FALSE),
        'M2.7 policy is approved.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_003_METHOD_CONTRACT',
        'METHOD_CONTRACT',
        ((SELECT methodology_version||'|'||contract_code||'|'||contract_version||'|'||schema_version FROM msbf_ctl.m2_7_policy_profile WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx)))::text,
        'M2_7_METHOD_V1|M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION|1|M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_SCHEMA_V1',
        coalesce(((SELECT methodology_version='M2_7_METHOD_V1' AND contract_code='M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION' AND contract_version=1 AND schema_version='M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_SCHEMA_V1' FROM msbf_ctl.m2_7_policy_profile WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx))),FALSE),
        'M2.7 methodology and contract identity are exact.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_004_SOURCE_IDENTITY',
        'SOURCE_IDENTITY',
        ((SELECT source_contract_code||'|'||source_contract_version||'|'||source_schema_version||'|'||source_combined_set_hash FROM msbf_ctl.m2_7_policy_profile WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx)))::text,
        'M2_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_CONSUMPTION|1|M2_6_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_SCHEMA_V1|868125bff29270490cab4d2e55cb1388',
        coalesce(((SELECT source_contract_code='M2_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_CONSUMPTION' AND source_contract_version=1 AND source_schema_version='M2_6_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_SCHEMA_V1' AND source_combined_set_hash='868125bff29270490cab4d2e55cb1388' FROM msbf_ctl.m2_7_policy_profile WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx))),FALSE),
        'Accepted M2.6 source identity is frozen.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_005_SOURCE_GATE',
        'SOURCE_GATE',
        ((SELECT result_status FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM _m2_7_vctx) AND gate_id='M2_6_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY' AND review_version=1))::text,
        'PASS',
        coalesce(((SELECT result_status='PASS' FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM _m2_7_vctx) AND gate_id='M2_6_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY' AND review_version=1)),FALSE),
        'Accepted M2.6 gate is PASS.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_006_CONFIGURATION_HASH',
        'CONFIGURATION_HASH',
        ((SELECT configuration_hash FROM msbf_ctl.m2_7_policy_profile WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx)))::text,
        'physical configuration hash',
        coalesce(((SELECT configuration_hash=msbf_ctl.m2_7_hash_jsonb(configuration_payload) FROM msbf_ctl.m2_7_policy_profile WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx))),FALSE),
        'Configuration hash reconstructs from the approved payload.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_007_POLICY_ROW_HASH',
        'POLICY_ROW_HASH_MISMATCHES',
        ((SELECT count(*) FROM msbf_ctl.m2_7_policy_profile AS p WHERE p.module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND p.row_hash IS DISTINCT FROM msbf_ctl.m2_7_hash_jsonb(to_jsonb(p)-'row_hash'-'created_at'-'updated_at')))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_ctl.m2_7_policy_profile AS p WHERE p.module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND p.row_hash IS DISTINCT FROM msbf_ctl.m2_7_hash_jsonb(to_jsonb(p)-'row_hash'-'created_at'-'updated_at'))),FALSE),
        'Policy row hash reconstructs physically.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_008_POLICY_BOUNDARIES',
        'POLICY_BOUNDARIES',
        ((
        SELECT synthetic_data_only_flag AND
               simulated_operational_setup_only_flag AND
               preserve_m2_6_history_flag AND
               no_real_core_account_creation_flag AND
               no_real_payment_change_execution_flag AND
               no_bank_account_data_flag AND
               no_ach_or_network_transmission_flag AND
               no_external_notice_generation_flag AND
               no_merchant_contact_execution_flag AND
               no_write_off_posting_flag AND
               no_collection_or_legal_execution_flag
        FROM msbf_ctl.m2_7_policy_profile
        WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx)
    ))::text,
        'true',
        coalesce(((
        SELECT synthetic_data_only_flag AND
               simulated_operational_setup_only_flag AND
               preserve_m2_6_history_flag AND
               no_real_core_account_creation_flag AND
               no_real_payment_change_execution_flag AND
               no_bank_account_data_flag AND
               no_ach_or_network_transmission_flag AND
               no_external_notice_generation_flag AND
               no_merchant_contact_execution_flag AND
               no_write_off_posting_flag AND
               no_collection_or_legal_execution_flag
        FROM msbf_ctl.m2_7_policy_profile
        WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx)
    )),FALSE),
        'All M2.7 stage-boundary flags are enabled.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_009_GATE_CATALOG',
        'GATE_CATALOG_ROWS',
        ((SELECT count(*) FROM msbf_ref.acceptance_gate_catalog WHERE gate_id='M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP' AND active_flag))::text,
        '1',
        coalesce(((SELECT count(*)=1 FROM msbf_ref.acceptance_gate_catalog WHERE gate_id='M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP' AND active_flag)),FALSE),
        'M2.7 acceptance gate is registered.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_010_REGISTRY_STATUS',
        'REGISTRY_STATUS',
        ((SELECT contract_status FROM msbf_ctl.m2_7_operational_activation_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx)))::text,
        'GENERATED|VALIDATED',
        coalesce(((SELECT contract_status IN ('GENERATED','VALIDATED') FROM msbf_ctl.m2_7_operational_activation_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx))),FALSE),
        'M2.7 registry is aligned with validation state.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_011_REGISTRY_CONTRACT',
        'REGISTRY_CONTRACT',
        ((SELECT contract_code||'|'||contract_version||'|'||schema_version||'|'||methodology_version FROM msbf_ctl.m2_7_operational_activation_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx)))::text,
        'M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION|1|M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_SCHEMA_V1|M2_7_METHOD_V1',
        coalesce(((SELECT contract_code='M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION' AND contract_version=1 AND schema_version='M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_SCHEMA_V1' AND methodology_version='M2_7_METHOD_V1' FROM msbf_ctl.m2_7_operational_activation_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx))),FALSE),
        'Registry contract identity is exact.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_012_REGISTRY_COUNTS',
        'REGISTRY_COUNTS',
        ((SELECT source_rows||'|'||activation_rows||'|'||account_setup_rows||'|'||portfolio_summary_rows||'|'||latest_rows||'|'||archive_rows||'|'||comparison_rows||'|'||canonical_entities FROM msbf_ctl.m2_7_operational_activation_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx)))::text,
        '59|59|59|2|59|59|15|341',
        coalesce(((SELECT source_rows=59 AND activation_rows=59 AND account_setup_rows=59 AND portfolio_summary_rows=2 AND latest_rows=59 AND archive_rows=59 AND comparison_rows=15 AND canonical_entities=341 FROM msbf_ctl.m2_7_operational_activation_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx))),FALSE),
        'Registry cardinalities match the M2.7 contract.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_013_REGISTRY_DISTRIBUTION',
        'REGISTRY_DISTRIBUTION',
        ((SELECT no_setup_required_rows||'|'||temporary_adjustment_setup_rows||'|'||review_required_rows||'|'||setup_authorized_rows||'|'||setup_authorized_amount||'|'||review_required_amount FROM msbf_ctl.m2_7_operational_activation_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx)))::text,
        '57|1|1|1|518.04|461.69',
        coalesce(((SELECT no_setup_required_rows=57 AND temporary_adjustment_setup_rows=1 AND review_required_rows=1 AND setup_authorized_rows=1 AND setup_authorized_amount=518.04 AND review_required_amount=461.69 FROM msbf_ctl.m2_7_operational_activation_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx))),FALSE),
        'Registry preserves the exact 57/1/1 setup mapping.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_014_OUTCOME_COUNT',
        'OUTCOME_COUNT',
        ((SELECT count(*) FROM msbf_m2.operational_setup_outcome_definition WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx)))::text,
        '7',
        coalesce(((SELECT count(*)=7 FROM msbf_m2.operational_setup_outcome_definition WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx))),FALSE),
        'Outcome Count matches the governed dictionary.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_015_ACTION_COUNT',
        'ACTION_COUNT',
        ((SELECT count(*) FROM msbf_m2.operational_setup_action_definition WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx)))::text,
        '7',
        coalesce(((SELECT count(*)=7 FROM msbf_m2.operational_setup_action_definition WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx))),FALSE),
        'Action Count matches the governed dictionary.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_016_REASON_COUNT',
        'REASON_COUNT',
        ((SELECT count(*) FROM msbf_m2.operational_setup_reason_definition WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx)))::text,
        '28',
        coalesce(((SELECT count(*)=28 FROM msbf_m2.operational_setup_reason_definition WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx))),FALSE),
        'Reason Count matches the governed dictionary.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_017_DEFINITIONS_APPROVED',
        'NONAPPROVED_DEFINITIONS',
        ((
        SELECT
          (SELECT count(*) FROM msbf_m2.operational_setup_outcome_definition WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND definition_status<>'APPROVED')+
          (SELECT count(*) FROM msbf_m2.operational_setup_action_definition WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND definition_status<>'APPROVED')+
          (SELECT count(*) FROM msbf_m2.operational_setup_reason_definition WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND definition_status<>'APPROVED')
    ))::text,
        '0',
        coalesce(((
        SELECT
          (SELECT count(*) FROM msbf_m2.operational_setup_outcome_definition WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND definition_status<>'APPROVED')+
          (SELECT count(*) FROM msbf_m2.operational_setup_action_definition WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND definition_status<>'APPROVED')+
          (SELECT count(*) FROM msbf_m2.operational_setup_reason_definition WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND definition_status<>'APPROVED')=0
    )),FALSE),
        'All definitions are approved.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_018_DEFINITION_BOUNDARY',
        'DEFINITION_EXECUTION_ROWS',
        ((
        SELECT
          (SELECT count(*) FROM msbf_m2.operational_setup_outcome_definition WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND (real_core_account_created_flag OR real_payment_change_executed_flag OR external_notice_generated_flag OR production_adverse_action_flag))+
          (SELECT count(*) FROM msbf_m2.operational_setup_action_definition WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND (real_core_account_created_flag OR real_payment_change_executed_flag OR ach_or_network_transmission_flag OR merchant_contact_executed_flag OR write_off_posted_flag OR collection_or_legal_executed_flag OR external_notice_generated_flag OR production_adverse_action_flag))+
          (SELECT count(*) FROM msbf_m2.operational_setup_reason_definition WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND (executed_action_flag OR production_adverse_action_flag))
    ))::text,
        '0',
        coalesce(((
        SELECT
          (SELECT count(*) FROM msbf_m2.operational_setup_outcome_definition WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND (real_core_account_created_flag OR real_payment_change_executed_flag OR external_notice_generated_flag OR production_adverse_action_flag))+
          (SELECT count(*) FROM msbf_m2.operational_setup_action_definition WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND (real_core_account_created_flag OR real_payment_change_executed_flag OR ach_or_network_transmission_flag OR merchant_contact_executed_flag OR write_off_posted_flag OR collection_or_legal_executed_flag OR external_notice_generated_flag OR production_adverse_action_flag))+
          (SELECT count(*) FROM msbf_m2.operational_setup_reason_definition WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND (executed_action_flag OR production_adverse_action_flag))=0
    )),FALSE),
        'Definitions contain no real execution flags.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_019_OUTCOME_RANKS',
        'OUTCOME_RANK_DUPLICATES',
        ((SELECT count(*)-count(DISTINCT operational_setup_outcome_rank) FROM msbf_m2.operational_setup_outcome_definition WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx)))::text,
        '0',
        coalesce(((SELECT count(*)=count(DISTINCT operational_setup_outcome_rank) FROM msbf_m2.operational_setup_outcome_definition WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx))),FALSE),
        'Outcome ranks are unique.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_020_ACTION_RANKS',
        'ACTION_RANK_DUPLICATES',
        ((SELECT count(*)-count(DISTINCT operational_setup_action_rank) FROM msbf_m2.operational_setup_action_definition WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx)))::text,
        '0',
        coalesce(((SELECT count(*)=count(DISTINCT operational_setup_action_rank) FROM msbf_m2.operational_setup_action_definition WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx))),FALSE),
        'Action ranks are unique.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_021_OUTCOME_HASH',
        'OUTCOME_HASH_MISMATCHES',
        ((SELECT count(*) FROM msbf_m2.operational_setup_outcome_definition AS d WHERE d.module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND d.row_hash IS DISTINCT FROM msbf_ctl.m2_7_hash_jsonb(to_jsonb(d)-'row_hash'-'created_at')))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.operational_setup_outcome_definition AS d WHERE d.module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND d.row_hash IS DISTINCT FROM msbf_ctl.m2_7_hash_jsonb(to_jsonb(d)-'row_hash'-'created_at'))),FALSE),
        'Outcome Hash reconstructs physically.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_022_ACTION_HASH',
        'ACTION_HASH_MISMATCHES',
        ((SELECT count(*) FROM msbf_m2.operational_setup_action_definition AS d WHERE d.module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND d.row_hash IS DISTINCT FROM msbf_ctl.m2_7_hash_jsonb(to_jsonb(d)-'row_hash'-'created_at')))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.operational_setup_action_definition AS d WHERE d.module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND d.row_hash IS DISTINCT FROM msbf_ctl.m2_7_hash_jsonb(to_jsonb(d)-'row_hash'-'created_at'))),FALSE),
        'Action Hash reconstructs physically.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_023_REASON_HASH',
        'REASON_HASH_MISMATCHES',
        ((SELECT count(*) FROM msbf_m2.operational_setup_reason_definition AS d WHERE d.module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND d.row_hash IS DISTINCT FROM msbf_ctl.m2_7_hash_jsonb(to_jsonb(d)-'row_hash'-'created_at')))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.operational_setup_reason_definition AS d WHERE d.module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND d.row_hash IS DISTINCT FROM msbf_ctl.m2_7_hash_jsonb(to_jsonb(d)-'row_hash'-'created_at'))),FALSE),
        'Reason Hash reconstructs physically.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_024_REASON_OUTCOME_FK',
        'REASON_OUTCOME_MISMATCHES',
        ((SELECT count(*) FROM msbf_m2.operational_setup_reason_definition AS r LEFT JOIN msbf_m2.operational_setup_outcome_definition AS o ON o.module1_run_id=r.module1_run_id AND o.operational_setup_outcome_code=r.mapped_outcome_code WHERE r.module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND o.operational_setup_outcome_code IS NULL))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.operational_setup_reason_definition AS r LEFT JOIN msbf_m2.operational_setup_outcome_definition AS o ON o.module1_run_id=r.module1_run_id AND o.operational_setup_outcome_code=r.mapped_outcome_code WHERE r.module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND o.operational_setup_outcome_code IS NULL)),FALSE),
        'Every reason maps to a governed outcome.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_025_REASON_ACTION_FK',
        'REASON_ACTION_MISMATCHES',
        ((SELECT count(*) FROM msbf_m2.operational_setup_reason_definition AS r LEFT JOIN msbf_m2.operational_setup_action_definition AS a ON a.module1_run_id=r.module1_run_id AND a.operational_setup_action_code=r.mapped_action_code WHERE r.module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND a.operational_setup_action_code IS NULL))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.operational_setup_reason_definition AS r LEFT JOIN msbf_m2.operational_setup_action_definition AS a ON a.module1_run_id=r.module1_run_id AND a.operational_setup_action_code=r.mapped_action_code WHERE r.module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND a.operational_setup_action_code IS NULL)),FALSE),
        'Every reason maps to a governed action.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_026_OUTCOME_EXCLUSIVITY',
        'OUTCOME_EXCLUSIVITY_ERRORS',
        ((SELECT count(*) FROM msbf_m2.operational_setup_outcome_definition WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND (num_nonnulls(NULLIF(setup_authorized_flag,FALSE),NULLIF(setup_review_required_flag,FALSE),NULLIF(no_setup_required_flag,FALSE))<>1 OR blueprint_created_flag<>setup_authorized_flag)))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.operational_setup_outcome_definition WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND (num_nonnulls(NULLIF(setup_authorized_flag,FALSE),NULLIF(setup_review_required_flag,FALSE),NULLIF(no_setup_required_flag,FALSE))<>1 OR blueprint_created_flag<>setup_authorized_flag))),FALSE),
        'Outcome flags are mutually exclusive.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_027_OUTCOME_DOMAIN',
        'OUTCOME_DOMAIN_ROWS',
        ((SELECT count(*) FROM msbf_m2.operational_setup_outcome_definition WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND operational_setup_outcome_code IN ('NO_OPERATIONAL_SETUP_REQUIRED','STANDARD_SERVICING_SETUP_READY','TEMPORARY_PAYMENT_ADJUSTMENT_SETUP_READY','RESTRUCTURE_SETUP_READY','CONTROLLED_RECOVERY_SETUP_READY','CHARGE_OFF_SETUP_READY','OPERATIONAL_SETUP_REVIEW_REQUIRED')))::text,
        '7',
        coalesce(((SELECT count(*)=7 FROM msbf_m2.operational_setup_outcome_definition WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND operational_setup_outcome_code IN ('NO_OPERATIONAL_SETUP_REQUIRED','STANDARD_SERVICING_SETUP_READY','TEMPORARY_PAYMENT_ADJUSTMENT_SETUP_READY','RESTRUCTURE_SETUP_READY','CONTROLLED_RECOVERY_SETUP_READY','CHARGE_OFF_SETUP_READY','OPERATIONAL_SETUP_REVIEW_REQUIRED'))),FALSE),
        'Complete outcome domain is present.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_028_ACTION_DOMAIN',
        'ACTION_DOMAIN_ROWS',
        ((SELECT count(*) FROM msbf_m2.operational_setup_action_definition WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND operational_setup_action_code IN ('CLOSE_WITHOUT_SETUP','CREATE_STANDARD_SERVICING_BLUEPRINT','CREATE_TEMPORARY_ADJUSTMENT_BLUEPRINT','CREATE_RESTRUCTURE_BLUEPRINT','CREATE_RECOVERY_BLUEPRINT','CREATE_CHARGE_OFF_BLUEPRINT','ROUTE_OPERATIONAL_GOVERNANCE_REVIEW')))::text,
        '7',
        coalesce(((SELECT count(*)=7 FROM msbf_m2.operational_setup_action_definition WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND operational_setup_action_code IN ('CLOSE_WITHOUT_SETUP','CREATE_STANDARD_SERVICING_BLUEPRINT','CREATE_TEMPORARY_ADJUSTMENT_BLUEPRINT','CREATE_RESTRUCTURE_BLUEPRINT','CREATE_RECOVERY_BLUEPRINT','CREATE_CHARGE_OFF_BLUEPRINT','ROUTE_OPERATIONAL_GOVERNANCE_REVIEW'))),FALSE),
        'Complete action domain is present.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_029_POLICY_TERM_DOMAIN',
        'POLICY_TERM_DOMAIN',
        ((SELECT default_temporary_payment_factor||'|'||default_setup_duration_days||'|'||default_reassessment_interval_days||'|'||activation_effective_lag_days FROM msbf_ctl.m2_7_policy_profile WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx)))::text,
        '0.750000|14|7|1',
        coalesce(((SELECT default_temporary_payment_factor=0.75 AND default_setup_duration_days=14 AND default_reassessment_interval_days=7 AND activation_effective_lag_days=1 FROM msbf_ctl.m2_7_policy_profile WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx))),FALSE),
        'Governed setup-term defaults are exact.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_030_EXPECTED_COUNTS',
        'EXPECTED_COUNTS',
        ((SELECT expected_source_rows||'|'||expected_activation_rows||'|'||expected_account_setup_rows||'|'||expected_canonical_entities||'|'||expected_positive_controls||'|'||expected_negative_controls FROM msbf_ctl.m2_7_policy_profile WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx)))::text,
        '59|59|59|341|120|20',
        coalesce(((SELECT expected_source_rows=59 AND expected_activation_rows=59 AND expected_account_setup_rows=59 AND expected_canonical_entities=341 AND expected_positive_controls=120 AND expected_negative_controls=20 FROM msbf_ctl.m2_7_policy_profile WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx))),FALSE),
        'Policy expected counts are exact.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_031_SOURCE_ROWS',
        'SOURCE_ROWS',
        ((SELECT count(*) FROM msbf_m2.operational_activation_source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx)))::text,
        '59',
        coalesce(((SELECT count(*)=59 FROM msbf_m2.operational_activation_source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx))),FALSE),
        'Source snapshot contains 59 accepted M2.6 records.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_032_SOURCE_GRAIN',
        'SOURCE_GRAIN_DUPLICATES',
        ((SELECT count(*)-count(DISTINCT scenario_id::text||'|'||merchant_application_id) FROM msbf_m2.operational_activation_source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx)))::text,
        '0',
        coalesce(((SELECT count(*)=count(DISTINCT scenario_id::text||'|'||merchant_application_id) FROM msbf_m2.operational_activation_source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx))),FALSE),
        'Source grain is unique.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_033_SOURCE_CLOSED',
        'SOURCE_CLOSED_ROWS',
        ((SELECT count(*) FROM msbf_m2.operational_activation_source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND source_strategy_outcome_code='CLOSED_NO_FURTHER_ACTION' AND source_servicing_action_code='NO_ACTION_CLOSED'))::text,
        '57',
        coalesce(((SELECT count(*)=57 FROM msbf_m2.operational_activation_source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND source_strategy_outcome_code='CLOSED_NO_FURTHER_ACTION' AND source_servicing_action_code='NO_ACTION_CLOSED')),FALSE),
        'Accepted source contains 57 closed/no-action rows.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_034_SOURCE_TEMPORARY',
        'SOURCE_TEMPORARY_ROWS',
        ((SELECT count(*) FROM msbf_m2.operational_activation_source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND source_strategy_outcome_code='TEMPORARY_REMITTANCE_ADJUSTMENT_REVIEW' AND source_servicing_action_code='TEMPORARY_REMITTANCE_REVIEW'))::text,
        '1',
        coalesce(((SELECT count(*)=1 FROM msbf_m2.operational_activation_source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND source_strategy_outcome_code='TEMPORARY_REMITTANCE_ADJUSTMENT_REVIEW' AND source_servicing_action_code='TEMPORARY_REMITTANCE_REVIEW')),FALSE),
        'Accepted source contains one temporary-review row.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_035_SOURCE_OUTREACH',
        'SOURCE_OUTREACH_ROWS',
        ((SELECT count(*) FROM msbf_m2.operational_activation_source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND source_strategy_outcome_code='TARGETED_MERCHANT_OUTREACH_REVIEW' AND source_servicing_action_code='OUTREACH_REVIEW_QUEUE'))::text,
        '1',
        coalesce(((SELECT count(*)=1 FROM msbf_m2.operational_activation_source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND source_strategy_outcome_code='TARGETED_MERCHANT_OUTREACH_REVIEW' AND source_servicing_action_code='OUTREACH_REVIEW_QUEUE')),FALSE),
        'Accepted source contains one outreach-review row.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_036_SOURCE_TOTAL_EXPOSURE',
        'SOURCE_RECOMMENDED_EXPOSURE',
        ((SELECT round(sum(source_recommended_action_exposure_amount),2) FROM msbf_m2.operational_activation_source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx)))::text,
        '979.73',
        coalesce(((SELECT round(sum(source_recommended_action_exposure_amount),2)=979.73 FROM msbf_m2.operational_activation_source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx))),FALSE),
        'Accepted source recommended exposure totals $979.73.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_037_SOURCE_TEMP_EXPOSURE',
        'SOURCE_TEMP_EXPOSURE',
        ((SELECT round(sum(source_recommended_action_exposure_amount),2) FROM msbf_m2.operational_activation_source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND source_strategy_outcome_code='TEMPORARY_REMITTANCE_ADJUSTMENT_REVIEW'))::text,
        '518.04',
        coalesce(((SELECT round(sum(source_recommended_action_exposure_amount),2)=518.04 FROM msbf_m2.operational_activation_source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND source_strategy_outcome_code='TEMPORARY_REMITTANCE_ADJUSTMENT_REVIEW')),FALSE),
        'Temporary-review exposure is $518.04.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_038_SOURCE_REVIEW_EXPOSURE',
        'SOURCE_REVIEW_EXPOSURE',
        ((SELECT round(sum(source_recommended_action_exposure_amount),2) FROM msbf_m2.operational_activation_source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND source_strategy_outcome_code='TARGETED_MERCHANT_OUTREACH_REVIEW'))::text,
        '461.69',
        coalesce(((SELECT round(sum(source_recommended_action_exposure_amount),2)=461.69 FROM msbf_m2.operational_activation_source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND source_strategy_outcome_code='TARGETED_MERCHANT_OUTREACH_REVIEW')),FALSE),
        'Outreach-review exposure is $461.69.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_039_SOURCE_COMBINED_HASH',
        'SOURCE_COMBINED_HASH_MISMATCHES',
        ((SELECT count(*) FROM msbf_m2.operational_activation_source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND source_combined_set_hash<>'868125bff29270490cab4d2e55cb1388'))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.operational_activation_source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND source_combined_set_hash<>'868125bff29270490cab4d2e55cb1388')),FALSE),
        'Every source row retains the accepted M2.6 combined hash.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_040_SOURCE_ROW_HASH_PRESENT',
        'SOURCE_ROW_HASH_NULLS',
        ((SELECT count(*) FROM msbf_m2.operational_activation_source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND source_contract_row_hash IS NULL))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.operational_activation_source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND source_contract_row_hash IS NULL)),FALSE),
        'Every source row retains its accepted M2.6 contract hash.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_041_SOURCE_PHYSICAL_HASH',
        'SOURCE_PHYSICAL_HASH_MISMATCHES',
        ((SELECT count(*) FROM msbf_m2.operational_activation_source_snapshot AS s WHERE s.module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND s.row_hash IS DISTINCT FROM msbf_ctl.m2_7_hash_jsonb(to_jsonb(s)-'row_hash'-'created_at')))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.operational_activation_source_snapshot AS s WHERE s.module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND s.row_hash IS DISTINCT FROM msbf_ctl.m2_7_hash_jsonb(to_jsonb(s)-'row_hash'-'created_at'))),FALSE),
        'Source snapshot hashes reconstruct physically.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_042_SOURCE_IDENTIFIERS',
        'SOURCE_IDENTIFIER_ERRORS',
        ((SELECT count(*) FROM msbf_m2.operational_activation_source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND (scenario_code='' OR merchant_application_id='' OR merchant_id='' OR synthetic_account_id='' OR synthetic_advance_id='')))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.operational_activation_source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND (scenario_code='' OR merchant_application_id='' OR merchant_id='' OR synthetic_account_id='' OR synthetic_advance_id=''))),FALSE),
        'Source identifiers are complete.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_043_SOURCE_AMOUNT_DOMAIN',
        'SOURCE_NEGATIVE_AMOUNT_ROWS',
        ((SELECT count(*) FROM msbf_m2.operational_activation_source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND source_recommended_action_exposure_amount<0))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.operational_activation_source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND source_recommended_action_exposure_amount<0)),FALSE),
        'Source exposure is nonnegative.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_044_SOURCE_PAYLOAD_OBJECT',
        'SOURCE_PAYLOAD_ERRORS',
        ((SELECT count(*) FROM msbf_m2.operational_activation_source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND jsonb_typeof(source_payload)<>'object'))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.operational_activation_source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND jsonb_typeof(source_payload)<>'object')),FALSE),
        'Every source payload is a JSON object.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_045_SOURCE_SCENARIOS',
        'SOURCE_SCENARIO_COUNT',
        ((SELECT count(DISTINCT scenario_code) FROM msbf_m2.operational_activation_source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx)))::text,
        '2',
        coalesce(((SELECT count(DISTINCT scenario_code)=2 FROM msbf_m2.operational_activation_source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx))),FALSE),
        'Source retains two governed scenarios.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_046_ACTIVATION_ROWS',
        'ACTIVATION_ROWS',
        ((SELECT count(*) FROM msbf_m2.application_operational_activation_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx)))::text,
        '59',
        coalesce(((SELECT count(*)=59 FROM msbf_m2.application_operational_activation_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx))),FALSE),
        'Activation contains 59 rows.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_047_ACTIVATION_GRAIN',
        'ACTIVATION_GRAIN_DUPLICATES',
        ((SELECT count(*)-count(DISTINCT scenario_id::text||'|'||merchant_application_id) FROM msbf_m2.application_operational_activation_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx)))::text,
        '0',
        coalesce(((SELECT count(*)=count(DISTINCT scenario_id::text||'|'||merchant_application_id) FROM msbf_m2.application_operational_activation_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx))),FALSE),
        'Activation grain is unique.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_048_ACTIVATION_NO_SETUP',
        'ACTIVATION_NO_SETUP_ROWS',
        ((SELECT count(*) FROM msbf_m2.application_operational_activation_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND operational_setup_outcome_code='NO_OPERATIONAL_SETUP_REQUIRED' AND no_setup_required_flag))::text,
        '57',
        coalesce(((SELECT count(*)=57 FROM msbf_m2.application_operational_activation_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND operational_setup_outcome_code='NO_OPERATIONAL_SETUP_REQUIRED' AND no_setup_required_flag)),FALSE),
        'Fifty-seven closed records require no setup.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_049_ACTIVATION_TEMPORARY',
        'ACTIVATION_TEMPORARY_ROWS',
        ((SELECT count(*) FROM msbf_m2.application_operational_activation_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND operational_setup_outcome_code='TEMPORARY_PAYMENT_ADJUSTMENT_SETUP_READY' AND setup_authorized_flag))::text,
        '1',
        coalesce(((SELECT count(*)=1 FROM msbf_m2.application_operational_activation_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND operational_setup_outcome_code='TEMPORARY_PAYMENT_ADJUSTMENT_SETUP_READY' AND setup_authorized_flag)),FALSE),
        'One temporary-adjustment blueprint is authorized.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_050_ACTIVATION_REVIEW',
        'ACTIVATION_REVIEW_ROWS',
        ((SELECT count(*) FROM msbf_m2.application_operational_activation_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND operational_setup_outcome_code='OPERATIONAL_SETUP_REVIEW_REQUIRED' AND setup_review_required_flag))::text,
        '1',
        coalesce(((SELECT count(*)=1 FROM msbf_m2.application_operational_activation_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND operational_setup_outcome_code='OPERATIONAL_SETUP_REVIEW_REQUIRED' AND setup_review_required_flag)),FALSE),
        'One outreach recommendation remains in operational review.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_051_ACTIVATION_OTHER',
        'ACTIVATION_OTHER_ROWS',
        ((SELECT count(*) FROM msbf_m2.application_operational_activation_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND operational_setup_outcome_code NOT IN ('NO_OPERATIONAL_SETUP_REQUIRED','TEMPORARY_PAYMENT_ADJUSTMENT_SETUP_READY','OPERATIONAL_SETUP_REVIEW_REQUIRED')))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_operational_activation_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND operational_setup_outcome_code NOT IN ('NO_OPERATIONAL_SETUP_REQUIRED','TEMPORARY_PAYMENT_ADJUSTMENT_SETUP_READY','OPERATIONAL_SETUP_REVIEW_REQUIRED'))),FALSE),
        'No other setup outcome is generated in the accepted campaign.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_052_ACTIVATION_SETUP_AMOUNT',
        'ACTIVATION_SETUP_AMOUNT',
        ((SELECT round(sum(CASE WHEN setup_authorized_flag THEN source_recommended_action_exposure_amount ELSE 0 END),2) FROM msbf_m2.application_operational_activation_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx)))::text,
        '518.04',
        coalesce(((SELECT round(sum(CASE WHEN setup_authorized_flag THEN source_recommended_action_exposure_amount ELSE 0 END),2)=518.04 FROM msbf_m2.application_operational_activation_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx))),FALSE),
        'Setup-authorized exposure equals $518.04.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_053_ACTIVATION_REVIEW_AMOUNT',
        'ACTIVATION_REVIEW_AMOUNT',
        ((SELECT round(sum(CASE WHEN setup_review_required_flag THEN source_recommended_action_exposure_amount ELSE 0 END),2) FROM msbf_m2.application_operational_activation_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx)))::text,
        '461.69',
        coalesce(((SELECT round(sum(CASE WHEN setup_review_required_flag THEN source_recommended_action_exposure_amount ELSE 0 END),2)=461.69 FROM msbf_m2.application_operational_activation_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx))),FALSE),
        'Review-only exposure equals $461.69.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_054_SOURCE_ACTIVATION_LINEAGE',
        'SOURCE_ACTIVATION_LINEAGE_MISMATCHES',
        ((SELECT count(*) FROM msbf_m2.operational_activation_source_snapshot AS s FULL OUTER JOIN msbf_m2.application_operational_activation_snapshot AS a ON a.module1_run_id=s.module1_run_id AND a.scenario_id=s.scenario_id AND a.merchant_application_id=s.merchant_application_id WHERE coalesce(s.module1_run_id,a.module1_run_id)=(SELECT run_id FROM _m2_7_vctx) AND (s.row_hash IS DISTINCT FROM a.source_snapshot_row_hash OR s.source_contract_row_hash IS DISTINCT FROM a.source_contract_row_hash)))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.operational_activation_source_snapshot AS s FULL OUTER JOIN msbf_m2.application_operational_activation_snapshot AS a ON a.module1_run_id=s.module1_run_id AND a.scenario_id=s.scenario_id AND a.merchant_application_id=s.merchant_application_id WHERE coalesce(s.module1_run_id,a.module1_run_id)=(SELECT run_id FROM _m2_7_vctx) AND (s.row_hash IS DISTINCT FROM a.source_snapshot_row_hash OR s.source_contract_row_hash IS DISTINCT FROM a.source_contract_row_hash))),FALSE),
        'Every source maps to one activation with exact lineage.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_055_ACTIVATION_EXCLUSIVITY',
        'ACTIVATION_EXCLUSIVITY_ERRORS',
        ((SELECT count(*) FROM msbf_m2.application_operational_activation_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND (num_nonnulls(NULLIF(setup_authorized_flag,FALSE),NULLIF(setup_review_required_flag,FALSE),NULLIF(no_setup_required_flag,FALSE))<>1 OR blueprint_created_flag<>setup_authorized_flag)))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_operational_activation_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND (num_nonnulls(NULLIF(setup_authorized_flag,FALSE),NULLIF(setup_review_required_flag,FALSE),NULLIF(no_setup_required_flag,FALSE))<>1 OR blueprint_created_flag<>setup_authorized_flag))),FALSE),
        'Activation flags are mutually exclusive.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_056_ACTIVATION_OUTCOME_FK',
        'ACTIVATION_OUTCOME_FK_ERRORS',
        ((SELECT count(*) FROM msbf_m2.application_operational_activation_snapshot AS a LEFT JOIN msbf_m2.operational_setup_outcome_definition AS o ON o.module1_run_id=a.module1_run_id AND o.operational_setup_outcome_code=a.operational_setup_outcome_code WHERE a.module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND o.operational_setup_outcome_code IS NULL))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_operational_activation_snapshot AS a LEFT JOIN msbf_m2.operational_setup_outcome_definition AS o ON o.module1_run_id=a.module1_run_id AND o.operational_setup_outcome_code=a.operational_setup_outcome_code WHERE a.module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND o.operational_setup_outcome_code IS NULL)),FALSE),
        'Every activation outcome is governed.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_057_ACTIVATION_ACTION_FK',
        'ACTIVATION_ACTION_FK_ERRORS',
        ((SELECT count(*) FROM msbf_m2.application_operational_activation_snapshot AS a LEFT JOIN msbf_m2.operational_setup_action_definition AS d ON d.module1_run_id=a.module1_run_id AND d.operational_setup_action_code=a.operational_setup_action_code WHERE a.module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND d.operational_setup_action_code IS NULL))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_operational_activation_snapshot AS a LEFT JOIN msbf_m2.operational_setup_action_definition AS d ON d.module1_run_id=a.module1_run_id AND d.operational_setup_action_code=a.operational_setup_action_code WHERE a.module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND d.operational_setup_action_code IS NULL)),FALSE),
        'Every activation action is governed.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_058_ACTIVATION_REASON_FK',
        'ACTIVATION_REASON_FK_ERRORS',
        ((SELECT count(*) FROM msbf_m2.application_operational_activation_snapshot AS a LEFT JOIN msbf_m2.operational_setup_reason_definition AS r ON r.module1_run_id=a.module1_run_id AND r.operational_setup_reason_code=a.primary_setup_reason_code WHERE a.module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND r.operational_setup_reason_code IS NULL))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_operational_activation_snapshot AS a LEFT JOIN msbf_m2.operational_setup_reason_definition AS r ON r.module1_run_id=a.module1_run_id AND r.operational_setup_reason_code=a.primary_setup_reason_code WHERE a.module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND r.operational_setup_reason_code IS NULL)),FALSE),
        'Every primary setup reason is governed.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_059_ACTIVATION_REASON_ARRAY',
        'ACTIVATION_REASON_ARRAY_ERRORS',
        ((SELECT count(*) FROM msbf_m2.application_operational_activation_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND (jsonb_typeof(setup_reason_codes)<>'array' OR jsonb_array_length(setup_reason_codes)=0 OR NOT (setup_reason_codes @> to_jsonb(ARRAY[primary_setup_reason_code]::text[])))))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_operational_activation_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND (jsonb_typeof(setup_reason_codes)<>'array' OR jsonb_array_length(setup_reason_codes)=0 OR NOT (setup_reason_codes @> to_jsonb(ARRAY[primary_setup_reason_code]::text[]))))),FALSE),
        'Every activation has a nonempty reason array containing the primary reason.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_060_CASE_ID_UNIQUE',
        'CASE_ID_DUPLICATES',
        ((SELECT count(*)-count(DISTINCT synthetic_operational_case_id) FROM msbf_m2.application_operational_activation_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx)))::text,
        '0',
        coalesce(((SELECT count(*)=count(DISTINCT synthetic_operational_case_id) FROM msbf_m2.application_operational_activation_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx))),FALSE),
        'Synthetic operational case identifiers are unique.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_061_CASE_ID_SHAPE',
        'CASE_ID_SHAPE_ERRORS',
        ((SELECT count(*) FROM msbf_m2.application_operational_activation_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND synthetic_operational_case_id NOT LIKE 'MSBF_OPS_CASE_%'))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_operational_activation_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND synthetic_operational_case_id NOT LIKE 'MSBF_OPS_CASE_%')),FALSE),
        'Synthetic operational case identifiers have the governed shape.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_062_ACTIVATION_POLICY_HASH',
        'ACTIVATION_POLICY_HASH_ERRORS',
        ((SELECT count(*) FROM msbf_m2.application_operational_activation_snapshot AS a WHERE a.module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND a.policy_configuration_hash IS DISTINCT FROM (SELECT configuration_hash FROM msbf_ctl.m2_7_policy_profile WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx))))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_operational_activation_snapshot AS a WHERE a.module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND a.policy_configuration_hash IS DISTINCT FROM (SELECT configuration_hash FROM msbf_ctl.m2_7_policy_profile WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx)))),FALSE),
        'Policy hash propagates to every activation.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_063_ACTIVATION_PHYSICAL_HASH',
        'ACTIVATION_PHYSICAL_HASH_ERRORS',
        ((SELECT count(*) FROM msbf_m2.application_operational_activation_snapshot AS a WHERE a.module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND a.row_hash IS DISTINCT FROM msbf_ctl.m2_7_hash_jsonb(to_jsonb(a)-'row_hash'-'created_at')))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_operational_activation_snapshot AS a WHERE a.module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND a.row_hash IS DISTINCT FROM msbf_ctl.m2_7_hash_jsonb(to_jsonb(a)-'row_hash'-'created_at'))),FALSE),
        'Activation row hashes reconstruct physically.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_064_REAL_ACCOUNT_FALSE',
        'REAL_ACCOUNT_FALSE',
        ((SELECT count(*) FROM msbf_m2.application_operational_activation_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND real_core_account_created_flag))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_operational_activation_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND real_core_account_created_flag)),FALSE),
        'Real Account False on every activation row.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_065_PAYMENT_CHANGE_FALSE',
        'PAYMENT_CHANGE_FALSE',
        ((SELECT count(*) FROM msbf_m2.application_operational_activation_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND real_payment_change_executed_flag))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_operational_activation_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND real_payment_change_executed_flag)),FALSE),
        'Payment Change False on every activation row.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_066_BANK_DATA_FALSE',
        'BANK_DATA_FALSE',
        ((SELECT count(*) FROM msbf_m2.application_operational_activation_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND bank_account_data_present_flag))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_operational_activation_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND bank_account_data_present_flag)),FALSE),
        'Bank Data False on every activation row.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_067_ACH_FALSE',
        'ACH_FALSE',
        ((SELECT count(*) FROM msbf_m2.application_operational_activation_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND ach_or_network_transmission_flag))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_operational_activation_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND ach_or_network_transmission_flag)),FALSE),
        'Ach False on every activation row.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_068_NOTICE_FALSE',
        'NOTICE_FALSE',
        ((SELECT count(*) FROM msbf_m2.application_operational_activation_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND external_notice_generated_flag))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_operational_activation_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND external_notice_generated_flag)),FALSE),
        'Notice False on every activation row.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_069_CONTACT_FALSE',
        'CONTACT_FALSE',
        ((SELECT count(*) FROM msbf_m2.application_operational_activation_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND merchant_contact_executed_flag))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_operational_activation_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND merchant_contact_executed_flag)),FALSE),
        'Contact False on every activation row.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_070_WRITE_OFF_FALSE',
        'WRITE_OFF_FALSE',
        ((SELECT count(*) FROM msbf_m2.application_operational_activation_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND write_off_posted_flag))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_operational_activation_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND write_off_posted_flag)),FALSE),
        'Write Off False on every activation row.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_071_SETUP_ROWS',
        'SETUP_ROWS',
        ((SELECT count(*) FROM msbf_m2.operational_account_setup_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx)))::text,
        '59',
        coalesce(((SELECT count(*)=59 FROM msbf_m2.operational_account_setup_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx))),FALSE),
        'Account setup contains 59 rows.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_072_SETUP_GRAIN',
        'SETUP_GRAIN_DUPLICATES',
        ((SELECT count(*)-count(DISTINCT scenario_id::text||'|'||merchant_application_id) FROM msbf_m2.operational_account_setup_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx)))::text,
        '0',
        coalesce(((SELECT count(*)=count(DISTINCT scenario_id::text||'|'||merchant_application_id) FROM msbf_m2.operational_account_setup_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx))),FALSE),
        'Account setup grain is unique.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_073_ACTIVATION_SETUP_LINEAGE',
        'ACTIVATION_SETUP_LINEAGE_ERRORS',
        ((SELECT count(*) FROM msbf_m2.application_operational_activation_snapshot AS a FULL OUTER JOIN msbf_m2.operational_account_setup_snapshot AS s ON s.module1_run_id=a.module1_run_id AND s.scenario_id=a.scenario_id AND s.merchant_application_id=a.merchant_application_id WHERE coalesce(a.module1_run_id,s.module1_run_id)=(SELECT run_id FROM _m2_7_vctx) AND a.row_hash IS DISTINCT FROM s.source_activation_row_hash))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_operational_activation_snapshot AS a FULL OUTER JOIN msbf_m2.operational_account_setup_snapshot AS s ON s.module1_run_id=a.module1_run_id AND s.scenario_id=a.scenario_id AND s.merchant_application_id=a.merchant_application_id WHERE coalesce(a.module1_run_id,s.module1_run_id)=(SELECT run_id FROM _m2_7_vctx) AND a.row_hash IS DISTINCT FROM s.source_activation_row_hash)),FALSE),
        'Every activation maps to one setup row with exact lineage.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_074_SETUP_STATUS_DISTRIBUTION',
        'SETUP_STATUS_DISTRIBUTION',
        ((SELECT count(*) FILTER(WHERE account_setup_status_code='NOT_REQUIRED')||'|'||count(*) FILTER(WHERE account_setup_status_code='SIMULATED_BLUEPRINT_READY')||'|'||count(*) FILTER(WHERE account_setup_status_code='OPERATIONAL_REVIEW_REQUIRED') FROM msbf_m2.operational_account_setup_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx)))::text,
        '57|1|1',
        coalesce(((SELECT count(*) FILTER(WHERE account_setup_status_code='NOT_REQUIRED')=57 AND count(*) FILTER(WHERE account_setup_status_code='SIMULATED_BLUEPRINT_READY')=1 AND count(*) FILTER(WHERE account_setup_status_code='OPERATIONAL_REVIEW_REQUIRED')=1 FROM msbf_m2.operational_account_setup_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx))),FALSE),
        'Setup status distribution is exactly 57/1/1.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_075_SETUP_ID_UNIQUE',
        'SETUP_ID_DUPLICATES',
        ((SELECT count(*)-count(DISTINCT synthetic_account_setup_id) FROM msbf_m2.operational_account_setup_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx)))::text,
        '0',
        coalesce(((SELECT count(*)=count(DISTINCT synthetic_account_setup_id) FROM msbf_m2.operational_account_setup_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx))),FALSE),
        'Synthetic setup identifiers are unique.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_076_SETUP_ID_SHAPE',
        'SETUP_ID_SHAPE_ERRORS',
        ((SELECT count(*) FROM msbf_m2.operational_account_setup_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND synthetic_account_setup_id NOT LIKE 'MSBF_SETUP_%'))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.operational_account_setup_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND synthetic_account_setup_id NOT LIKE 'MSBF_SETUP_%')),FALSE),
        'Synthetic setup identifiers have the governed shape.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_077_READY_PLAN_PRESENT',
        'READY_PLAN_ERRORS',
        ((SELECT count(*) FROM msbf_m2.operational_account_setup_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND account_setup_status_code='SIMULATED_BLUEPRINT_READY' AND (synthetic_servicing_plan_id IS NULL OR operational_activation_date IS NULL OR next_reassessment_date IS NULL)))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.operational_account_setup_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND account_setup_status_code='SIMULATED_BLUEPRINT_READY' AND (synthetic_servicing_plan_id IS NULL OR operational_activation_date IS NULL OR next_reassessment_date IS NULL))),FALSE),
        'Ready blueprints have complete plans and dates.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_078_NONREADY_PLAN_NULL',
        'NONREADY_PLAN_ERRORS',
        ((SELECT count(*) FROM msbf_m2.operational_account_setup_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND account_setup_status_code<>'SIMULATED_BLUEPRINT_READY' AND (synthetic_servicing_plan_id IS NOT NULL OR operational_activation_date IS NOT NULL OR next_reassessment_date IS NOT NULL)))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.operational_account_setup_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND account_setup_status_code<>'SIMULATED_BLUEPRINT_READY' AND (synthetic_servicing_plan_id IS NOT NULL OR operational_activation_date IS NOT NULL OR next_reassessment_date IS NOT NULL))),FALSE),
        'No-setup and review rows carry no plan or dates.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_079_PLAN_ID_UNIQUE',
        'PLAN_ID_DUPLICATES',
        ((SELECT count(*) FILTER(WHERE synthetic_servicing_plan_id IS NOT NULL)-count(DISTINCT synthetic_servicing_plan_id) FROM msbf_m2.operational_account_setup_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx)))::text,
        '0',
        coalesce(((SELECT count(*) FILTER(WHERE synthetic_servicing_plan_id IS NOT NULL)=count(DISTINCT synthetic_servicing_plan_id) FROM msbf_m2.operational_account_setup_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx))),FALSE),
        'Synthetic servicing plan identifiers are unique.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_080_TEMPORARY_TERMS',
        'TEMPORARY_TERMS',
        ((SELECT applied_temporary_payment_factor||'|'||applied_setup_duration_days||'|'||applied_reassessment_interval_days FROM msbf_m2.operational_account_setup_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND operational_setup_outcome_code='TEMPORARY_PAYMENT_ADJUSTMENT_SETUP_READY'))::text,
        '0.750000|14|7',
        coalesce(((SELECT applied_temporary_payment_factor=0.75 AND applied_setup_duration_days=14 AND applied_reassessment_interval_days=7 FROM msbf_m2.operational_account_setup_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND operational_setup_outcome_code='TEMPORARY_PAYMENT_ADJUSTMENT_SETUP_READY')),FALSE),
        'Temporary blueprint uses the accepted 0.75/14/7 terms.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_081_NONTEMPORARY_TERMS_NULL',
        'NONTEMPORARY_TERM_ROWS',
        ((SELECT count(*) FROM msbf_m2.operational_account_setup_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND operational_setup_outcome_code<>'TEMPORARY_PAYMENT_ADJUSTMENT_SETUP_READY' AND (applied_temporary_payment_factor IS NOT NULL OR applied_setup_duration_days IS NOT NULL OR applied_reassessment_interval_days IS NOT NULL)))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.operational_account_setup_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND operational_setup_outcome_code<>'TEMPORARY_PAYMENT_ADJUSTMENT_SETUP_READY' AND (applied_temporary_payment_factor IS NOT NULL OR applied_setup_duration_days IS NOT NULL OR applied_reassessment_interval_days IS NOT NULL))),FALSE),
        'Non-temporary rows carry no temporary terms.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_082_DATE_ORDER',
        'DATE_ORDER_ERRORS',
        ((SELECT count(*) FROM msbf_m2.operational_account_setup_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND operational_activation_date IS NOT NULL AND next_reassessment_date<=operational_activation_date))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.operational_account_setup_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND operational_activation_date IS NOT NULL AND next_reassessment_date<=operational_activation_date)),FALSE),
        'Reassessment follows synthetic activation.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_083_SETUP_PAYLOAD_OBJECT',
        'SETUP_PAYLOAD_ERRORS',
        ((SELECT count(*) FROM msbf_m2.operational_account_setup_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND jsonb_typeof(setup_parameter_payload)<>'object'))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.operational_account_setup_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND jsonb_typeof(setup_parameter_payload)<>'object')),FALSE),
        'Setup parameter payloads are JSON objects.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_084_SETUP_PHYSICAL_HASH',
        'SETUP_PHYSICAL_HASH_ERRORS',
        ((SELECT count(*) FROM msbf_m2.operational_account_setup_snapshot AS s WHERE s.module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND s.row_hash IS DISTINCT FROM msbf_ctl.m2_7_hash_jsonb(to_jsonb(s)-'row_hash'-'created_at')))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.operational_account_setup_snapshot AS s WHERE s.module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND s.row_hash IS DISTINCT FROM msbf_ctl.m2_7_hash_jsonb(to_jsonb(s)-'row_hash'-'created_at'))),FALSE),
        'Setup row hashes reconstruct physically.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_085_SETUP_REAL_ACCOUNT_FALSE',
        'SETUP_REAL_ACCOUNT_FALSE',
        ((SELECT count(*) FROM msbf_m2.operational_account_setup_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND real_core_account_created_flag))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.operational_account_setup_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND real_core_account_created_flag)),FALSE),
        'Setup Real Account False on every setup row.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_086_SETUP_PAYMENT_FALSE',
        'SETUP_PAYMENT_FALSE',
        ((SELECT count(*) FROM msbf_m2.operational_account_setup_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND real_payment_change_executed_flag))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.operational_account_setup_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND real_payment_change_executed_flag)),FALSE),
        'Setup Payment False on every setup row.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_087_SETUP_BANK_FALSE',
        'SETUP_BANK_FALSE',
        ((SELECT count(*) FROM msbf_m2.operational_account_setup_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND bank_account_data_present_flag))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.operational_account_setup_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND bank_account_data_present_flag)),FALSE),
        'Setup Bank False on every setup row.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_088_SETUP_ACH_FALSE',
        'SETUP_ACH_FALSE',
        ((SELECT count(*) FROM msbf_m2.operational_account_setup_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND ach_or_network_transmission_flag))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.operational_account_setup_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND ach_or_network_transmission_flag)),FALSE),
        'Setup Ach False on every setup row.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_089_SETUP_NOTICE_FALSE',
        'SETUP_NOTICE_FALSE',
        ((SELECT count(*) FROM msbf_m2.operational_account_setup_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND external_notice_generated_flag))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.operational_account_setup_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND external_notice_generated_flag)),FALSE),
        'Setup Notice False on every setup row.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_090_SETUP_CONTACT_FALSE',
        'SETUP_CONTACT_FALSE',
        ((SELECT count(*) FROM msbf_m2.operational_account_setup_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND merchant_contact_executed_flag))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.operational_account_setup_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND merchant_contact_executed_flag)),FALSE),
        'Setup Contact False on every setup row.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_091_PORTFOLIO_ROWS',
        'PORTFOLIO_ROWS',
        ((SELECT count(*) FROM msbf_m2.operational_activation_portfolio_summary WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx)))::text,
        '2',
        coalesce(((SELECT count(*)=2 FROM msbf_m2.operational_activation_portfolio_summary WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx))),FALSE),
        'Two scenario summaries exist.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_092_PORTFOLIO_COUNT_IDENTITY',
        'PORTFOLIO_COUNT_ERRORS',
        ((SELECT count(*) FROM msbf_m2.operational_activation_portfolio_summary WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND setup_ready_rows+review_required_rows+no_setup_required_rows<>source_rows))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.operational_activation_portfolio_summary WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND setup_ready_rows+review_required_rows+no_setup_required_rows<>source_rows)),FALSE),
        'Scenario summary counts reconcile.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_093_PORTFOLIO_TOTALS',
        'PORTFOLIO_TOTALS',
        ((SELECT sum(source_rows)||'|'||sum(setup_ready_rows)||'|'||sum(review_required_rows)||'|'||sum(no_setup_required_rows)||'|'||sum(setup_authorized_amount)||'|'||sum(review_required_amount) FROM msbf_m2.operational_activation_portfolio_summary WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx)))::text,
        '59|1|1|57|518.04|461.69',
        coalesce(((SELECT sum(source_rows)=59 AND sum(setup_ready_rows)=1 AND sum(review_required_rows)=1 AND sum(no_setup_required_rows)=57 AND sum(setup_authorized_amount)=518.04 AND sum(review_required_amount)=461.69 FROM msbf_m2.operational_activation_portfolio_summary WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx))),FALSE),
        'Portfolio summaries reproduce exact campaign totals.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_094_PORTFOLIO_HASH',
        'PORTFOLIO_HASH_ERRORS',
        ((SELECT count(*) FROM msbf_m2.operational_activation_portfolio_summary AS p WHERE p.module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND p.row_hash IS DISTINCT FROM msbf_ctl.m2_7_hash_jsonb(to_jsonb(p)-'row_hash'-'created_at')))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.operational_activation_portfolio_summary AS p WHERE p.module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND p.row_hash IS DISTINCT FROM msbf_ctl.m2_7_hash_jsonb(to_jsonb(p)-'row_hash'-'created_at'))),FALSE),
        'Portfolio hashes reconstruct physically.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_095_LATEST_ROWS',
        'LATEST_ROWS',
        ((SELECT count(*) FROM msbf_m2.application_operational_activation_latest WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx)))::text,
        '59',
        coalesce(((SELECT count(*)=59 FROM msbf_m2.application_operational_activation_latest WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx))),FALSE),
        'Latest contract contains 59 rows.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_096_LATEST_GRAIN',
        'LATEST_GRAIN_DUPLICATES',
        ((SELECT count(*)-count(DISTINCT scenario_id::text||'|'||merchant_application_id) FROM msbf_m2.application_operational_activation_latest WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx)))::text,
        '0',
        coalesce(((SELECT count(*)=count(DISTINCT scenario_id::text||'|'||merchant_application_id) FROM msbf_m2.application_operational_activation_latest WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx))),FALSE),
        'Latest contract grain is unique.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_097_LATEST_IDENTITY',
        'LATEST_IDENTITY_ERRORS',
        ((SELECT count(*) FROM msbf_m2.application_operational_activation_latest WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND (contract_code<>'M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION' OR contract_version<>1 OR schema_version<>'M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_SCHEMA_V1' OR methodology_version<>'M2_7_METHOD_V1')))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_operational_activation_latest WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND (contract_code<>'M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION' OR contract_version<>1 OR schema_version<>'M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_SCHEMA_V1' OR methodology_version<>'M2_7_METHOD_V1'))),FALSE),
        'Latest contract identity is exact.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_098_LATEST_LINEAGE',
        'LATEST_LINEAGE_ERRORS',
        ((SELECT count(*) FROM msbf_m2.application_operational_activation_latest AS l JOIN msbf_m2.application_operational_activation_snapshot AS a ON a.module1_run_id=l.module1_run_id AND a.scenario_id=l.scenario_id AND a.merchant_application_id=l.merchant_application_id JOIN msbf_m2.operational_account_setup_snapshot AS s ON s.module1_run_id=l.module1_run_id AND s.scenario_id=l.scenario_id AND s.merchant_application_id=l.merchant_application_id WHERE l.module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND (l.activation_snapshot_row_hash IS DISTINCT FROM a.row_hash OR l.account_setup_snapshot_row_hash IS DISTINCT FROM s.row_hash)))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_operational_activation_latest AS l JOIN msbf_m2.application_operational_activation_snapshot AS a ON a.module1_run_id=l.module1_run_id AND a.scenario_id=l.scenario_id AND a.merchant_application_id=l.merchant_application_id JOIN msbf_m2.operational_account_setup_snapshot AS s ON s.module1_run_id=l.module1_run_id AND s.scenario_id=l.scenario_id AND s.merchant_application_id=l.merchant_application_id WHERE l.module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND (l.activation_snapshot_row_hash IS DISTINCT FROM a.row_hash OR l.account_setup_snapshot_row_hash IS DISTINCT FROM s.row_hash))),FALSE),
        'Latest contracts preserve activation and setup lineage.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_099_LATEST_HASH',
        'LATEST_HASH_ERRORS',
        ((SELECT count(*) FROM msbf_m2.application_operational_activation_latest AS l WHERE l.module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND l.contract_row_hash IS DISTINCT FROM msbf_ctl.m2_7_hash_jsonb(to_jsonb(l)-'contract_row_hash'-'created_at')))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_operational_activation_latest AS l WHERE l.module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND l.contract_row_hash IS DISTINCT FROM msbf_ctl.m2_7_hash_jsonb(to_jsonb(l)-'contract_row_hash'-'created_at'))),FALSE),
        'Latest hashes reconstruct physically.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_100_ARCHIVE_ROWS',
        'ARCHIVE_ROWS',
        ((SELECT count(*) FROM msbf_m2.application_operational_activation_archive WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx)))::text,
        '59',
        coalesce(((SELECT count(*)=59 FROM msbf_m2.application_operational_activation_archive WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx))),FALSE),
        'Archive contains 59 rows.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_101_LATEST_ARCHIVE',
        'LATEST_ARCHIVE_ERRORS',
        ((SELECT count(*) FROM msbf_m2.application_operational_activation_latest AS l FULL OUTER JOIN msbf_m2.application_operational_activation_archive AS a ON a.module1_run_id=l.module1_run_id AND a.contract_version=l.contract_version AND a.scenario_id=l.scenario_id AND a.merchant_application_id=l.merchant_application_id WHERE coalesce(l.module1_run_id,a.module1_run_id)=(SELECT run_id FROM _m2_7_vctx) AND (l.contract_row_hash IS DISTINCT FROM a.contract_row_hash OR a.contract_payload IS DISTINCT FROM (to_jsonb(l)-'created_at'))))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_operational_activation_latest AS l FULL OUTER JOIN msbf_m2.application_operational_activation_archive AS a ON a.module1_run_id=l.module1_run_id AND a.contract_version=l.contract_version AND a.scenario_id=l.scenario_id AND a.merchant_application_id=l.merchant_application_id WHERE coalesce(l.module1_run_id,a.module1_run_id)=(SELECT run_id FROM _m2_7_vctx) AND (l.contract_row_hash IS DISTINCT FROM a.contract_row_hash OR a.contract_payload IS DISTINCT FROM (to_jsonb(l)-'created_at')))),FALSE),
        'Latest and archive reproduce exactly.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_102_ARCHIVE_HASH',
        'ARCHIVE_HASH_ERRORS',
        ((SELECT count(*) FROM msbf_m2.application_operational_activation_archive AS a WHERE a.module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND a.archive_row_hash IS DISTINCT FROM msbf_ctl.m2_7_hash_jsonb(to_jsonb(a)-'archive_id'-'archive_row_hash'-'archived_at'-'created_at')))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_operational_activation_archive AS a WHERE a.module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND a.archive_row_hash IS DISTINCT FROM msbf_ctl.m2_7_hash_jsonb(to_jsonb(a)-'archive_id'-'archive_row_hash'-'archived_at'-'created_at'))),FALSE),
        'Archive hashes reconstruct physically.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_103_ARCHIVE_TRIGGER',
        'ARCHIVE_TRIGGER_ROWS',
        ((SELECT count(*) FROM pg_trigger WHERE tgrelid='msbf_m2.application_operational_activation_archive'::regclass AND tgname='trg_m2_7_activation_archive_immutable' AND NOT tgisinternal))::text,
        '1',
        coalesce(((SELECT count(*)=1 FROM pg_trigger WHERE tgrelid='msbf_m2.application_operational_activation_archive'::regclass AND tgname='trg_m2_7_activation_archive_immutable' AND NOT tgisinternal)),FALSE),
        'Archive immutability trigger is installed.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_104_COMPARISON_ROWS',
        'COMPARISON_ROWS',
        ((SELECT count(*) FROM msbf_m2.v_m2_7_matched_scenario_comparison WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx)))::text,
        '15',
        coalesce(((SELECT count(*)=15 FROM msbf_m2.v_m2_7_matched_scenario_comparison WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx))),FALSE),
        'Matched comparison contains 15 applications.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_105_STRESS_NONIMPROVEMENT',
        'STRESS_IMPROVEMENT_ROWS',
        ((SELECT count(*) FROM msbf_m2.v_m2_7_matched_scenario_comparison WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND (stress_setup_permission_improvement_flag OR stress_priority_improvement_flag)))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.v_m2_7_matched_scenario_comparison WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND (stress_setup_permission_improvement_flag OR stress_priority_improvement_flag))),FALSE),
        'Stress never becomes more permissive or lower priority.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_106_POLICY_SET_HASH',
        'POLICY_SET_HASH',
        ((SELECT policy_set_hash FROM msbf_ctl.m2_7_operational_activation_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx)))::text,
        '32 lowercase hexadecimal characters',
        coalesce(((SELECT length(policy_set_hash)=32 AND policy_set_hash ~ '^[0-9a-f]+$' FROM msbf_ctl.m2_7_operational_activation_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx))),FALSE),
        'policy_set_hash has a valid deterministic hash shape.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_107_OUTCOME_SET_HASH',
        'OUTCOME_SET_HASH',
        ((SELECT outcome_set_hash FROM msbf_ctl.m2_7_operational_activation_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx)))::text,
        '32 lowercase hexadecimal characters',
        coalesce(((SELECT length(outcome_set_hash)=32 AND outcome_set_hash ~ '^[0-9a-f]+$' FROM msbf_ctl.m2_7_operational_activation_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx))),FALSE),
        'outcome_set_hash has a valid deterministic hash shape.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_108_ACTION_SET_HASH',
        'ACTION_SET_HASH',
        ((SELECT action_set_hash FROM msbf_ctl.m2_7_operational_activation_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx)))::text,
        '32 lowercase hexadecimal characters',
        coalesce(((SELECT length(action_set_hash)=32 AND action_set_hash ~ '^[0-9a-f]+$' FROM msbf_ctl.m2_7_operational_activation_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx))),FALSE),
        'action_set_hash has a valid deterministic hash shape.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_109_REASON_SET_HASH',
        'REASON_SET_HASH',
        ((SELECT reason_set_hash FROM msbf_ctl.m2_7_operational_activation_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx)))::text,
        '32 lowercase hexadecimal characters',
        coalesce(((SELECT length(reason_set_hash)=32 AND reason_set_hash ~ '^[0-9a-f]+$' FROM msbf_ctl.m2_7_operational_activation_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx))),FALSE),
        'reason_set_hash has a valid deterministic hash shape.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_110_SOURCE_SET_HASH',
        'SOURCE_SET_HASH',
        ((SELECT source_set_hash FROM msbf_ctl.m2_7_operational_activation_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx)))::text,
        '32 lowercase hexadecimal characters',
        coalesce(((SELECT length(source_set_hash)=32 AND source_set_hash ~ '^[0-9a-f]+$' FROM msbf_ctl.m2_7_operational_activation_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx))),FALSE),
        'source_set_hash has a valid deterministic hash shape.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_111_ACTIVATION_SET_HASH',
        'ACTIVATION_SET_HASH',
        ((SELECT activation_set_hash FROM msbf_ctl.m2_7_operational_activation_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx)))::text,
        '32 lowercase hexadecimal characters',
        coalesce(((SELECT length(activation_set_hash)=32 AND activation_set_hash ~ '^[0-9a-f]+$' FROM msbf_ctl.m2_7_operational_activation_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx))),FALSE),
        'activation_set_hash has a valid deterministic hash shape.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_112_ACCOUNT_SETUP_SET_HASH',
        'ACCOUNT_SETUP_SET_HASH',
        ((SELECT account_setup_set_hash FROM msbf_ctl.m2_7_operational_activation_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx)))::text,
        '32 lowercase hexadecimal characters',
        coalesce(((SELECT length(account_setup_set_hash)=32 AND account_setup_set_hash ~ '^[0-9a-f]+$' FROM msbf_ctl.m2_7_operational_activation_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx))),FALSE),
        'account_setup_set_hash has a valid deterministic hash shape.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_113_PORTFOLIO_SUMMARY_SET_HASH',
        'PORTFOLIO_SUMMARY_SET_HASH',
        ((SELECT portfolio_summary_set_hash FROM msbf_ctl.m2_7_operational_activation_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx)))::text,
        '32 lowercase hexadecimal characters',
        coalesce(((SELECT length(portfolio_summary_set_hash)=32 AND portfolio_summary_set_hash ~ '^[0-9a-f]+$' FROM msbf_ctl.m2_7_operational_activation_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx))),FALSE),
        'portfolio_summary_set_hash has a valid deterministic hash shape.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_114_LATEST_SET_HASH',
        'LATEST_SET_HASH',
        ((SELECT latest_set_hash FROM msbf_ctl.m2_7_operational_activation_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx)))::text,
        '32 lowercase hexadecimal characters',
        coalesce(((SELECT length(latest_set_hash)=32 AND latest_set_hash ~ '^[0-9a-f]+$' FROM msbf_ctl.m2_7_operational_activation_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx))),FALSE),
        'latest_set_hash has a valid deterministic hash shape.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_115_ARCHIVE_SET_HASH',
        'ARCHIVE_SET_HASH',
        ((SELECT archive_set_hash FROM msbf_ctl.m2_7_operational_activation_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx)))::text,
        '32 lowercase hexadecimal characters',
        coalesce(((SELECT length(archive_set_hash)=32 AND archive_set_hash ~ '^[0-9a-f]+$' FROM msbf_ctl.m2_7_operational_activation_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx))),FALSE),
        'archive_set_hash has a valid deterministic hash shape.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_116_REGISTRY_HASH',
        'REGISTRY_HASH_ERRORS',
        ((SELECT count(*) FROM msbf_ctl.m2_7_operational_activation_contract_registry AS r WHERE r.module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND r.row_hash IS DISTINCT FROM msbf_ctl.m2_7_registry_row_hash(to_jsonb(r))))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_ctl.m2_7_operational_activation_contract_registry AS r WHERE r.module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND r.row_hash IS DISTINCT FROM msbf_ctl.m2_7_registry_row_hash(to_jsonb(r)))),FALSE),
        'Registry row hash reconstructs physically.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_117_CONTRACT_SET_HASH',
        'CONTRACT_SET_HASH_ERRORS',
        ((SELECT count(*) FROM msbf_ctl.m2_7_operational_activation_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND contract_set_hash IS DISTINCT FROM md5(row_hash)))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_ctl.m2_7_operational_activation_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx) AND contract_set_hash IS DISTINCT FROM md5(row_hash))),FALSE),
        'Contract set hash equals MD5 of registry row hash.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_118_CANONICAL_IDENTITY',
        'CANONICAL_IDENTITY',
        ((SELECT canonical_entities||'|'||combined_set_hash FROM msbf_m2.v_m2_7_canonical_hash WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx)))::text,
        '341|registry combined hash',
        coalesce(((SELECT c.canonical_entities=341 AND c.combined_set_hash IS NOT DISTINCT FROM r.combined_set_hash FROM msbf_m2.v_m2_7_canonical_hash AS c JOIN msbf_ctl.m2_7_operational_activation_contract_registry AS r ON r.module1_run_id=c.module1_run_id WHERE c.module1_run_id=(SELECT run_id FROM _m2_7_vctx))),FALSE),
        'Physical canonical count and combined hash reconcile.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_119_GENERATION_EVIDENCE',
        'GENERATION_EVIDENCE_ROWS',
        ((SELECT count(*) FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM _m2_7_vctx) AND evidence_code LIKE 'M2_7_%' AND evidence_code NOT LIKE 'M2_7_POS_%' AND evidence_code NOT LIKE 'M2_7_NEG_%' AND evidence_code<>'M2_7_ACCEPTANCE_SUMMARY'))::text,
        '24',
        coalesce(((SELECT count(*)=24 FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM _m2_7_vctx) AND evidence_code LIKE 'M2_7_%' AND evidence_code NOT LIKE 'M2_7_POS_%' AND evidence_code NOT LIKE 'M2_7_NEG_%' AND evidence_code<>'M2_7_ACCEPTANCE_SUMMARY')),FALSE),
        'Twenty-four generation-evidence rows are present.'
    );
    PERFORM pg_temp.m2_7_add_check
    (
        'M2_7_POS_120_ACCEPTANCE_NOT_WRITTEN',
        'ACCEPTANCE_ROWS',
        ((SELECT count(*) FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM _m2_7_vctx) AND gate_id='M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP'))::text,
        '0',
        coalesce(((SELECT count(*)=0 FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM _m2_7_vctx) AND gate_id='M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP')),FALSE),
        'Acceptance is not written before controls pass.'
    );
END;
$controls$;

DO $finalize$
DECLARE
    v_total bigint;
    v_pass bigint;
    v_fail bigint;
BEGIN
    SELECT
        count(*),
        count(*) FILTER(WHERE status='PASS'),
        count(*) FILTER(WHERE status='FAIL')
    INTO v_total,v_pass,v_fail
    FROM _m2_7_validation;

    IF v_total<>120 THEN
        RAISE EXCEPTION
            'M2.7 positive-control inventory failed: total %, expected 120.',
            v_total;
    END IF;

    INSERT INTO msbf_ctl.run_evidence
    (
        run_id,evidence_code,segment_key,metric_name,
        metric_value_numeric,metric_value_text,unit_code,status,
        interpretation
    )
    SELECT
        (SELECT run_id FROM _m2_7_vctx),
        evidence_code,'PORTFOLIO',metric_name,NULL::numeric(28,10),
        coalesce(observed_value,'<NULL>'),'VALIDATION',status,
        interpretation||' Threshold: '||coalesce(threshold_value,'<NULL>')
    FROM _m2_7_validation
    ON CONFLICT(run_id,evidence_code,segment_key)
    DO UPDATE SET
        metric_name=EXCLUDED.metric_name,
        metric_value_numeric=NULL,
        metric_value_text=EXCLUDED.metric_value_text,
        unit_code=EXCLUDED.unit_code,
        status=EXCLUDED.status,
        interpretation=EXCLUDED.interpretation,
        created_at=clock_timestamp();

    IF v_pass=120 AND v_fail=0 THEN
        UPDATE msbf_ctl.run_registry
        SET run_status='M2_7_VALIDATED'
        WHERE run_id=(SELECT run_id FROM _m2_7_vctx);

        UPDATE msbf_ctl.m2_7_operational_activation_contract_registry
        SET contract_status='VALIDATED',validated_at=clock_timestamp()
        WHERE module1_run_id=(SELECT run_id FROM _m2_7_vctx);
    ELSE
        RAISE EXCEPTION
            'M2.7 positive validation failed: pass %, fail %.',
            v_pass,v_fail;
    END IF;
END;
$finalize$;

COMMIT;

SELECT *
FROM _m2_7_validation
ORDER BY evidence_code;
