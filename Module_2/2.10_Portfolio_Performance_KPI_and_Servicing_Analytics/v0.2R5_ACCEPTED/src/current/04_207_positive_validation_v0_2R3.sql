/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.10 — Portfolio Performance, KPI & Servicing Analytics

Program     : 207_msbf_m2_10_portfolio_performance_kpi_validation_v0_2R3.sql
Version     : v0.2R3

Purpose
-------
Execute 120 substantive positive controls in bounded, parser-safe control blocks across lifecycle, accepted M2.9
identity, dictionaries, source and account fact, portfolio and scenario scope,
KPI applicability and values, servicing queues, latest/archive reproduction,
stress non-improvement, deterministic hashes, canonical identity, stage
boundaries, and acceptance readiness.

Required result
---------------
120 / 120 PASS and run_status=M2_10_VALIDATED.
============================================================================ */

BEGIN;
SET LOCAL work_mem='160MB';
SET LOCAL statement_timeout='55min';
SET LOCAL jit=off;
DROP TABLE IF EXISTS _m2_10_validation;
CREATE TEMP TABLE _m2_10_validation
(evidence_code text PRIMARY KEY,metric_name text NOT NULL,observed_value text,
 threshold_value text,status text NOT NULL,interpretation text NOT NULL)
ON COMMIT PRESERVE ROWS;
DROP TABLE IF EXISTS _m2_10_vctx;
CREATE TEMP TABLE _m2_10_vctx ON COMMIT DROP AS
SELECT run_id,run_status FROM msbf_ctl.run_registry
WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1;
DO $m2_10_validation_ready$
BEGIN
 PERFORM msbf_ctl.m2_10_assert_validation_ready((SELECT run_id FROM _m2_10_vctx));
END;
$m2_10_validation_ready$;

CREATE OR REPLACE FUNCTION pg_temp.m2_10_add_check
(p_code text,p_metric text,p_observed text,p_threshold text,p_pass boolean,p_interpretation text)
RETURNS void LANGUAGE plpgsql AS $function$
BEGIN
 INSERT INTO _m2_10_validation VALUES
 (p_code,p_metric,p_observed,p_threshold,CASE WHEN p_pass THEN 'PASS' ELSE 'FAIL' END,p_interpretation);
END;
$function$;

/* Fail early if the four Program 204 physical dictionary hashes were not normalized. */
DO $m2_10_definition_hash_ready$
DECLARE
    v record;
BEGIN
    SELECT
        (
            SELECT count(*)
            FROM msbf_m2.portfolio_kpi_definition AS definition
            WHERE definition.module1_run_id=(SELECT run_id FROM _m2_10_vctx)
              AND definition.row_hash IS DISTINCT FROM
                  msbf_ctl.m2_10_hash_jsonb
                  (to_jsonb(definition)-'row_hash'-'created_at')
        ) AS kpi_mismatches,
        (
            SELECT count(*)
            FROM msbf_m2.portfolio_performance_tier_definition AS definition
            WHERE definition.module1_run_id=(SELECT run_id FROM _m2_10_vctx)
              AND definition.row_hash IS DISTINCT FROM
                  msbf_ctl.m2_10_hash_jsonb
                  (to_jsonb(definition)-'row_hash'-'created_at')
        ) AS tier_mismatches,
        (
            SELECT count(*)
            FROM msbf_m2.servicing_queue_definition AS definition
            WHERE definition.module1_run_id=(SELECT run_id FROM _m2_10_vctx)
              AND definition.row_hash IS DISTINCT FROM
                  msbf_ctl.m2_10_hash_jsonb
                  (to_jsonb(definition)-'row_hash'-'created_at')
        ) AS queue_mismatches,
        (
            SELECT count(*)
            FROM msbf_m2.portfolio_analytics_reason_definition AS definition
            WHERE definition.module1_run_id=(SELECT run_id FROM _m2_10_vctx)
              AND definition.row_hash IS DISTINCT FROM
                  msbf_ctl.m2_10_hash_jsonb
                  (to_jsonb(definition)-'row_hash'-'created_at')
        ) AS reason_mismatches
    INTO v;

    IF v.kpi_mismatches<>0
       OR v.tier_mismatches<>0
       OR v.queue_mismatches<>0
       OR v.reason_mismatches<>0
    THEN
        RAISE EXCEPTION
            'M2.10 physical dictionary hashes require Program 207C repair: KPI %, tier %, queue %, reason %.',
            v.kpi_mismatches,v.tier_mismatches,
            v.queue_mismatches,v.reason_mismatches;
    END IF;
END;
$m2_10_definition_hash_ready$;

/* ============================================================================
Section 1 — One hundred twenty governed positive controls
============================================================================ */
/* Controls 001–030 — bounded parser-safe execution block. */
DO $m2_10_positive_001_030$
BEGIN
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_001_RUN_STATUS',
            'RUN_STATUS',
            ((SELECT run_status FROM _m2_10_vctx))::text,
            'M2_10_GENERATED|M2_10_VALIDATED',
            coalesce(((SELECT run_status IN ('M2_10_GENERATED','M2_10_VALIDATED') FROM _m2_10_vctx)),FALSE),
            'Validation begins from generated or validated lifecycle.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_002_CONTRACT_STATUS',
            'CONTRACT_STATUS',
            ((SELECT contract_status FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx)))::text,
            'GENERATED|VALIDATED',
            coalesce(((SELECT contract_status IN ('GENERATED','VALIDATED') FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx))),FALSE),
            'Registry lifecycle aligns with validation.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_003_POLICY_STATUS',
            'POLICY_STATUS',
            ((SELECT policy_status FROM msbf_ctl.m2_10_policy_profile WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx)))::text,
            'APPROVED',
            coalesce(((SELECT policy_status='APPROVED' FROM msbf_ctl.m2_10_policy_profile WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx))),FALSE),
            'M2.10 policy is approved.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_004_METHOD_CONTRACT',
            'METHOD_CONTRACT',
            ((SELECT methodology_version||'|'||contract_code||'|'||contract_version||'|'||schema_version FROM msbf_ctl.m2_10_policy_profile WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx)))::text,
            'M2_10_METHOD_V1|M2_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_CONSUMPTION|1|M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_SCHEMA_V1',
            coalesce(((SELECT methodology_version='M2_10_METHOD_V1' AND contract_code='M2_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_CONSUMPTION' AND contract_version=1 AND schema_version='M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_SCHEMA_V1' FROM msbf_ctl.m2_10_policy_profile WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx))),FALSE),
            'Methodology and contract identity are exact.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_005_SOURCE_IDENTITY',
            'SOURCE_IDENTITY',
            ((SELECT source_contract_code||'|'||source_contract_version||'|'||source_schema_version||'|'||source_combined_set_hash FROM msbf_ctl.m2_10_policy_profile WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx)))::text,
            'M2_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_CONSUMPTION|1|M2_9_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_SCHEMA_V1|6af76d0059b47623619ebc09330b15fe',
            coalesce(((SELECT source_contract_code='M2_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_CONSUMPTION' AND source_contract_version=1 AND source_schema_version='M2_9_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_SCHEMA_V1' AND source_combined_set_hash='6af76d0059b47623619ebc09330b15fe' FROM msbf_ctl.m2_10_policy_profile WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx))),FALSE),
            'Accepted M2.9 source identity is frozen.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_006_SOURCE_REGISTRY',
            'SOURCE_REGISTRY',
            ((SELECT contract_status||'|'||contract_code||'|'||contract_version||'|'||schema_version||'|'||combined_set_hash FROM msbf_ctl.m2_9_reconciliation_certification_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx)))::text,
            'ACCEPTED|M2_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_CONSUMPTION|1|M2_9_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_SCHEMA_V1|6af76d0059b47623619ebc09330b15fe',
            coalesce(((SELECT contract_status='ACCEPTED' AND contract_code='M2_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_CONSUMPTION' AND contract_version=1 AND schema_version='M2_9_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_SCHEMA_V1' AND combined_set_hash='6af76d0059b47623619ebc09330b15fe' FROM msbf_ctl.m2_9_reconciliation_certification_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx))),FALSE),
            'Physical accepted M2.9 registry is exact.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_007_SOURCE_GATE',
            'SOURCE_GATE',
            ((SELECT result_status FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM _m2_10_vctx) AND gate_id='M2_9_PAYMENT_RECONCILIATION_EXCEPTION_RESOLUTION_ACCOUNT_STATE_CERTIFICATION' AND review_version=1))::text,
            'PASS',
            coalesce(((SELECT result_status='PASS' FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM _m2_10_vctx) AND gate_id='M2_9_PAYMENT_RECONCILIATION_EXCEPTION_RESOLUTION_ACCOUNT_STATE_CERTIFICATION' AND review_version=1)),FALSE),
            'Accepted M2.9 gate is PASS.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_008_CONFIGURATION_HASH',
            'CONFIGURATION_HASH',
            ((SELECT configuration_hash FROM msbf_ctl.m2_10_policy_profile WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx)))::text,
            'physical configuration hash',
            coalesce(((SELECT configuration_hash=msbf_ctl.m2_10_hash_jsonb(configuration_payload) FROM msbf_ctl.m2_10_policy_profile WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx))),FALSE),
            'Configuration hash reconstructs.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_009_POLICY_ROW_HASH',
            'POLICY_ROW_HASH_MISMATCHES',
            ((SELECT count(*) FROM msbf_ctl.m2_10_policy_profile AS p WHERE p.module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND p.row_hash IS DISTINCT FROM msbf_ctl.m2_10_hash_jsonb(to_jsonb(p)-'row_hash'-'created_at'-'updated_at')))::text,
            '0',
            coalesce(((SELECT count(*)=0 FROM msbf_ctl.m2_10_policy_profile AS p WHERE p.module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND p.row_hash IS DISTINCT FROM msbf_ctl.m2_10_hash_jsonb(to_jsonb(p)-'row_hash'-'created_at'-'updated_at'))),FALSE),
            'Policy row hash reconstructs physically.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_010_POLICY_BOUNDARY',
            'POLICY_BOUNDARY',
            ((SELECT synthetic_data_only_flag AND analytics_only_flag AND preserve_m2_9_history_flag AND no_production_decisioning_flag AND no_real_funds_movement_flag AND no_external_system_update_flag AND no_merchant_contact_flag AND no_write_off_collection_legal_flag FROM msbf_ctl.m2_10_policy_profile WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx)))::text,
            'true',
            coalesce(((SELECT synthetic_data_only_flag AND analytics_only_flag AND preserve_m2_9_history_flag AND no_production_decisioning_flag AND no_real_funds_movement_flag AND no_external_system_update_flag AND no_merchant_contact_flag AND no_write_off_collection_legal_flag FROM msbf_ctl.m2_10_policy_profile WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx))),FALSE),
            'All non-production boundaries are enabled.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_011_POLICY_PARAMETERS',
            'POLICY_PARAMETERS',
            ((SELECT closed_burden_units||'|'||active_burden_units||'|'||review_burden_units||'|'||rate_decimal_scale FROM msbf_ctl.m2_10_policy_profile WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx)))::text,
            '0.000000|2.000000|5.000000|6',
            coalesce(((SELECT closed_burden_units=0 AND active_burden_units=2 AND review_burden_units=5 AND rate_decimal_scale=6 FROM msbf_ctl.m2_10_policy_profile WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx))),FALSE),
            'Burden and precision parameters are exact.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_012_GATE_CATALOG',
            'GATE_CATALOG_ROWS',
            ((SELECT count(*) FROM msbf_ref.acceptance_gate_catalog WHERE gate_id='M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS' AND active_flag))::text,
            '1',
            coalesce(((SELECT count(*)=1 FROM msbf_ref.acceptance_gate_catalog WHERE gate_id='M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS' AND active_flag)),FALSE),
            'M2.10 gate is registered.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_013_REGISTRY_ROWS',
            'REGISTRY_ROWS',
            ((SELECT count(*) FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx)))::text,
            '1',
            coalesce(((SELECT count(*)=1 FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx))),FALSE),
            'Exactly one registry row exists.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_014_REGISTRY_COUNTS',
            'REGISTRY_COUNTS',
            ((SELECT source_rows||'|'||account_performance_rows||'|'||scope_summary_rows||'|'||kpi_snapshot_rows||'|'||queue_summary_rows||'|'||latest_rows||'|'||archive_rows||'|'||comparison_rows||'|'||canonical_entities FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx)))::text,
            '59|59|3|72|3|59|59|15|370',
            coalesce(((SELECT source_rows=59 AND account_performance_rows=59 AND scope_summary_rows=3 AND kpi_snapshot_rows=72 AND queue_summary_rows=3 AND latest_rows=59 AND archive_rows=59 AND comparison_rows=15 AND canonical_entities=370 FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx))),FALSE),
            'Registry cardinalities match the contract.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_015_REGISTRY_TOTALS',
            'REGISTRY_TOTALS',
            ((SELECT portfolio_account_rows||'|'||closed_stable_rows||'|'||active_reconciled_rows||'|'||controlled_review_rows||'|'||certified_exposure_amount||'|'||processed_payment_amount||'|'||servicing_burden_units FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx)))::text,
            '59|57|1|1|785.48|194.25|7.000000',
            coalesce(((SELECT portfolio_account_rows=59 AND closed_stable_rows=57 AND active_reconciled_rows=1 AND controlled_review_rows=1 AND certified_exposure_amount=785.48 AND processed_payment_amount=194.25 AND servicing_burden_units=7 FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx))),FALSE),
            'Registry business totals are exact.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_016_KPI_COUNT',
            'KPI_COUNT',
            ((SELECT count(*) FROM msbf_m2.portfolio_kpi_definition WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx)))::text,
            '24',
            coalesce(((SELECT count(*)=24 FROM msbf_m2.portfolio_kpi_definition WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx))),FALSE),
            'Kpi Count matches the governed dictionary.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_017_TIER_COUNT',
            'TIER_COUNT',
            ((SELECT count(*) FROM msbf_m2.portfolio_performance_tier_definition WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx)))::text,
            '3',
            coalesce(((SELECT count(*)=3 FROM msbf_m2.portfolio_performance_tier_definition WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx))),FALSE),
            'Tier Count matches the governed dictionary.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_018_QUEUE_COUNT',
            'QUEUE_COUNT',
            ((SELECT count(*) FROM msbf_m2.servicing_queue_definition WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx)))::text,
            '3',
            coalesce(((SELECT count(*)=3 FROM msbf_m2.servicing_queue_definition WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx))),FALSE),
            'Queue Count matches the governed dictionary.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_019_REASON_COUNT',
            'REASON_COUNT',
            ((SELECT count(*) FROM msbf_m2.portfolio_analytics_reason_definition WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx)))::text,
            '24',
            coalesce(((SELECT count(*)=24 FROM msbf_m2.portfolio_analytics_reason_definition WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx))),FALSE),
            'Reason Count matches the governed dictionary.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_020_DEFINITIONS_APPROVED',
            'NONAPPROVED_DEFINITIONS',
            (((SELECT count(*) FROM msbf_m2.portfolio_kpi_definition WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND definition_status<>'APPROVED')+(SELECT count(*) FROM msbf_m2.portfolio_performance_tier_definition WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND definition_status<>'APPROVED')+(SELECT count(*) FROM msbf_m2.servicing_queue_definition WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND definition_status<>'APPROVED')+(SELECT count(*) FROM msbf_m2.portfolio_analytics_reason_definition WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND definition_status<>'APPROVED')))::text,
            '0',
            coalesce((((SELECT count(*) FROM msbf_m2.portfolio_kpi_definition WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND definition_status<>'APPROVED')+(SELECT count(*) FROM msbf_m2.portfolio_performance_tier_definition WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND definition_status<>'APPROVED')+(SELECT count(*) FROM msbf_m2.servicing_queue_definition WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND definition_status<>'APPROVED')+(SELECT count(*) FROM msbf_m2.portfolio_analytics_reason_definition WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND definition_status<>'APPROVED')=0)),FALSE),
            'All definitions are approved.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_021_REASON_BOUNDARY',
            'PRODUCTION_REASON_ROWS',
            ((SELECT count(*) FROM msbf_m2.portfolio_analytics_reason_definition WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND production_action_flag))::text,
            '0',
            coalesce(((SELECT count(*)=0 FROM msbf_m2.portfolio_analytics_reason_definition WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND production_action_flag)),FALSE),
            'No reason authorizes production action.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_022_TIER_RANKS',
            'TIER_RANK_DUPLICATES',
            ((SELECT count(*)-count(DISTINCT performance_tier_rank) FROM msbf_m2.portfolio_performance_tier_definition WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx)))::text,
            '0',
            coalesce(((SELECT count(*)=count(DISTINCT performance_tier_rank) FROM msbf_m2.portfolio_performance_tier_definition WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx))),FALSE),
            'Tier ranks are unique.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_023_QUEUE_RANKS',
            'QUEUE_RANK_DUPLICATES',
            ((SELECT count(*)-count(DISTINCT servicing_queue_rank) FROM msbf_m2.servicing_queue_definition WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx)))::text,
            '0',
            coalesce(((SELECT count(*)=count(DISTINCT servicing_queue_rank) FROM msbf_m2.servicing_queue_definition WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx))),FALSE),
            'Queue ranks are unique.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_024_KPI_RANKS',
            'KPI_RANK_DUPLICATES',
            ((SELECT count(*)-count(DISTINCT kpi_rank) FROM msbf_m2.portfolio_kpi_definition WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx)))::text,
            '0',
            coalesce(((SELECT count(*)=count(DISTINCT kpi_rank) FROM msbf_m2.portfolio_kpi_definition WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx))),FALSE),
            'KPI ranks are unique.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_025_KPI_HASH',
            'KPI_HASH_MISMATCHES',
            ((SELECT count(*) FROM msbf_m2.portfolio_kpi_definition AS d WHERE d.module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND d.row_hash IS DISTINCT FROM msbf_ctl.m2_10_hash_jsonb(to_jsonb(d)-'row_hash'-'created_at')))::text,
            '0',
            coalesce(((SELECT count(*)=0 FROM msbf_m2.portfolio_kpi_definition AS d WHERE d.module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND d.row_hash IS DISTINCT FROM msbf_ctl.m2_10_hash_jsonb(to_jsonb(d)-'row_hash'-'created_at'))),FALSE),
            'Kpi Hash reconstructs physically.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_026_TIER_HASH',
            'TIER_HASH_MISMATCHES',
            ((SELECT count(*) FROM msbf_m2.portfolio_performance_tier_definition AS d WHERE d.module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND d.row_hash IS DISTINCT FROM msbf_ctl.m2_10_hash_jsonb(to_jsonb(d)-'row_hash'-'created_at')))::text,
            '0',
            coalesce(((SELECT count(*)=0 FROM msbf_m2.portfolio_performance_tier_definition AS d WHERE d.module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND d.row_hash IS DISTINCT FROM msbf_ctl.m2_10_hash_jsonb(to_jsonb(d)-'row_hash'-'created_at'))),FALSE),
            'Tier Hash reconstructs physically.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_027_QUEUE_HASH',
            'QUEUE_HASH_MISMATCHES',
            ((SELECT count(*) FROM msbf_m2.servicing_queue_definition AS d WHERE d.module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND d.row_hash IS DISTINCT FROM msbf_ctl.m2_10_hash_jsonb(to_jsonb(d)-'row_hash'-'created_at')))::text,
            '0',
            coalesce(((SELECT count(*)=0 FROM msbf_m2.servicing_queue_definition AS d WHERE d.module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND d.row_hash IS DISTINCT FROM msbf_ctl.m2_10_hash_jsonb(to_jsonb(d)-'row_hash'-'created_at'))),FALSE),
            'Queue Hash reconstructs physically.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_028_REASON_HASH',
            'REASON_HASH_MISMATCHES',
            ((SELECT count(*) FROM msbf_m2.portfolio_analytics_reason_definition AS d WHERE d.module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND d.row_hash IS DISTINCT FROM msbf_ctl.m2_10_hash_jsonb(to_jsonb(d)-'row_hash'-'created_at')))::text,
            '0',
            coalesce(((SELECT count(*)=0 FROM msbf_m2.portfolio_analytics_reason_definition AS d WHERE d.module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND d.row_hash IS DISTINCT FROM msbf_ctl.m2_10_hash_jsonb(to_jsonb(d)-'row_hash'-'created_at'))),FALSE),
            'Reason Hash reconstructs physically.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_029_TIER_BURDENS',
            'TIER_BURDENS',
            ((SELECT string_agg(performance_tier_code||'='||burden_units,',' ORDER BY performance_tier_rank) FROM msbf_m2.portfolio_performance_tier_definition WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx)))::text,
            'CLOSED_STABLE=0.000000,ACTIVE_RECONCILED=2.000000,CONTROLLED_REVIEW=5.000000',
            coalesce(((SELECT count(*)=3 AND sum(burden_units)=7 FROM msbf_m2.portfolio_performance_tier_definition WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx))),FALSE),
            'Tier burdens are exact.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_030_EXPECTED_COUNTS',
            'EXPECTED_COUNTS',
            ((SELECT expected_source_rows||'|'||expected_account_performance_rows||'|'||expected_scope_summary_rows||'|'||expected_kpi_snapshot_rows||'|'||expected_queue_summary_rows||'|'||expected_canonical_entities||'|'||expected_positive_controls||'|'||expected_negative_controls FROM msbf_ctl.m2_10_policy_profile WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx)))::text,
            '59|59|3|72|3|370|120|20',
            coalesce(((SELECT expected_source_rows=59 AND expected_account_performance_rows=59 AND expected_scope_summary_rows=3 AND expected_kpi_snapshot_rows=72 AND expected_queue_summary_rows=3 AND expected_canonical_entities=370 AND expected_positive_controls=120 AND expected_negative_controls=20 FROM msbf_ctl.m2_10_policy_profile WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx))),FALSE),
            'Policy expected counts are exact.'
        );
END;
$m2_10_positive_001_030$;

/* Controls 031–042 — bounded parser-safe execution block. */
DO $m2_10_positive_031_042$
BEGIN
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_031_SOURCE_COUNT',
            'SOURCE_ROWS',
            ((SELECT count(*) FROM msbf_m2.portfolio_performance_source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx)))::text,
            '59',
            coalesce(((SELECT count(*)=59 FROM msbf_m2.portfolio_performance_source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx))),FALSE),
            'Source snapshot contains 59 records.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_032_SOURCE_GRAIN',
            'SOURCE_GRAIN_DUPLICATES',
            ((SELECT count(*)-count(DISTINCT scenario_id::text||'|'||merchant_application_id) FROM msbf_m2.portfolio_performance_source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx)))::text,
            '0',
            coalesce(((SELECT count(*)=count(DISTINCT scenario_id::text||'|'||merchant_application_id) FROM msbf_m2.portfolio_performance_source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx))),FALSE),
            'Source grain is unique.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_033_SOURCE_SCENARIOS',
            'SOURCE_SCENARIOS',
            ((SELECT count(*) FILTER(WHERE scenario_code='BASELINE')||'|'||count(*) FILTER(WHERE scenario_code='RECESSION_ENERGY') FROM msbf_m2.portfolio_performance_source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx)))::text,
            '44|15',
            coalesce(((SELECT count(*) FILTER(WHERE scenario_code='BASELINE')=44 AND count(*) FILTER(WHERE scenario_code='RECESSION_ENERGY')=15 FROM msbf_m2.portfolio_performance_source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx))),FALSE),
            'Source scenarios retain 44 baseline and 15 stress rows.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_034_SOURCE_STATE_POSTURE',
            'SOURCE_STATE_POSTURE',
            ((SELECT
                count(*) FILTER(WHERE source.reconciliation_outcome_code='NO_PAYMENT_ACTIVITY_RECONCILED'
            AND source.certified_state_code='CERTIFIED_CLOSED_NO_PROCESSING'
            AND source.state_certified_flag IS TRUE
            AND source.closed_state_flag IS TRUE
            AND source.active_state_flag IS FALSE
            AND source.review_hold_state_flag IS FALSE
            AND source.exception_resolved_flag IS FALSE
            AND source.exception_case_count=0
            AND source.resolved_exception_count=0
            AND source.unresolved_exception_count=0
            AND source.certified_exposure_amount=0
            AND source.scheduled_payment_amount=0
            AND source.processed_payment_amount=0
            AND source.returned_payment_amount=0
            AND source.retry_payment_amount=0
            AND source.reconciliation_variance_amount=0
            AND source.exposure_variance_amount=0)||'|'||
                count(*) FILTER(WHERE source.reconciliation_outcome_code='PAYMENT_ACTIVITY_RECONCILED_AFTER_RETRY'
            AND source.certified_state_code='CERTIFIED_REASSESSMENT_DUE_AFTER_RETRY'
            AND source.state_certified_flag IS TRUE
            AND source.active_state_flag IS TRUE
            AND source.closed_state_flag IS FALSE
            AND source.review_hold_state_flag IS FALSE
            AND source.exception_resolved_flag IS TRUE
            AND source.exception_case_count=1
            AND source.resolved_exception_count=1
            AND source.unresolved_exception_count=0
            AND source.payment_event_count=7
            AND source.settled_event_count=5
            AND source.returned_event_count=1
            AND source.retry_event_count=1
            AND source.certified_exposure_amount=323.79
            AND source.scheduled_payment_amount=194.25
            AND source.processed_payment_amount=194.25
            AND source.returned_payment_amount=27.75
            AND source.retry_payment_amount=27.75
            AND source.reconciliation_variance_amount=0
            AND source.exposure_variance_amount=0)||'|'||
                count(*) FILTER(WHERE source.reconciliation_outcome_code='RECONCILIATION_REVIEW_HOLD'
            AND source.certified_state_code='CERTIFIED_REVIEW_HOLD'
            AND source.state_certified_flag IS TRUE
            AND source.review_hold_state_flag IS TRUE
            AND source.active_state_flag IS FALSE
            AND source.closed_state_flag IS FALSE
            AND source.exception_resolved_flag IS FALSE
            AND source.exception_case_count=0
            AND source.resolved_exception_count=0
            AND source.unresolved_exception_count=0
            AND source.certified_exposure_amount=461.69
            AND source.scheduled_payment_amount=0
            AND source.processed_payment_amount=0
            AND source.returned_payment_amount=0
            AND source.retry_payment_amount=0
            AND source.reconciliation_variance_amount=0
            AND source.exposure_variance_amount=0)||'|'||
                count(*) FILTER
                (
                    WHERE NOT
                    (
                        (source.reconciliation_outcome_code='NO_PAYMENT_ACTIVITY_RECONCILED'
            AND source.certified_state_code='CERTIFIED_CLOSED_NO_PROCESSING'
            AND source.state_certified_flag IS TRUE
            AND source.closed_state_flag IS TRUE
            AND source.active_state_flag IS FALSE
            AND source.review_hold_state_flag IS FALSE
            AND source.exception_resolved_flag IS FALSE
            AND source.exception_case_count=0
            AND source.resolved_exception_count=0
            AND source.unresolved_exception_count=0
            AND source.certified_exposure_amount=0
            AND source.scheduled_payment_amount=0
            AND source.processed_payment_amount=0
            AND source.returned_payment_amount=0
            AND source.retry_payment_amount=0
            AND source.reconciliation_variance_amount=0
            AND source.exposure_variance_amount=0) OR (source.reconciliation_outcome_code='PAYMENT_ACTIVITY_RECONCILED_AFTER_RETRY'
            AND source.certified_state_code='CERTIFIED_REASSESSMENT_DUE_AFTER_RETRY'
            AND source.state_certified_flag IS TRUE
            AND source.active_state_flag IS TRUE
            AND source.closed_state_flag IS FALSE
            AND source.review_hold_state_flag IS FALSE
            AND source.exception_resolved_flag IS TRUE
            AND source.exception_case_count=1
            AND source.resolved_exception_count=1
            AND source.unresolved_exception_count=0
            AND source.payment_event_count=7
            AND source.settled_event_count=5
            AND source.returned_event_count=1
            AND source.retry_event_count=1
            AND source.certified_exposure_amount=323.79
            AND source.scheduled_payment_amount=194.25
            AND source.processed_payment_amount=194.25
            AND source.returned_payment_amount=27.75
            AND source.retry_payment_amount=27.75
            AND source.reconciliation_variance_amount=0
            AND source.exposure_variance_amount=0) OR (source.reconciliation_outcome_code='RECONCILIATION_REVIEW_HOLD'
            AND source.certified_state_code='CERTIFIED_REVIEW_HOLD'
            AND source.state_certified_flag IS TRUE
            AND source.review_hold_state_flag IS TRUE
            AND source.active_state_flag IS FALSE
            AND source.closed_state_flag IS FALSE
            AND source.exception_resolved_flag IS FALSE
            AND source.exception_case_count=0
            AND source.resolved_exception_count=0
            AND source.unresolved_exception_count=0
            AND source.certified_exposure_amount=461.69
            AND source.scheduled_payment_amount=0
            AND source.processed_payment_amount=0
            AND source.returned_payment_amount=0
            AND source.retry_payment_amount=0
            AND source.reconciliation_variance_amount=0
            AND source.exposure_variance_amount=0)
                    )
                )
              FROM msbf_m2.portfolio_performance_source_snapshot AS source
              WHERE source.module1_run_id=(SELECT run_id FROM _m2_10_vctx)))::text,
            '57|1|1|0',
            coalesce(((SELECT
                count(*) FILTER(WHERE source.reconciliation_outcome_code='NO_PAYMENT_ACTIVITY_RECONCILED'
            AND source.certified_state_code='CERTIFIED_CLOSED_NO_PROCESSING'
            AND source.state_certified_flag IS TRUE
            AND source.closed_state_flag IS TRUE
            AND source.active_state_flag IS FALSE
            AND source.review_hold_state_flag IS FALSE
            AND source.exception_resolved_flag IS FALSE
            AND source.exception_case_count=0
            AND source.resolved_exception_count=0
            AND source.unresolved_exception_count=0
            AND source.certified_exposure_amount=0
            AND source.scheduled_payment_amount=0
            AND source.processed_payment_amount=0
            AND source.returned_payment_amount=0
            AND source.retry_payment_amount=0
            AND source.reconciliation_variance_amount=0
            AND source.exposure_variance_amount=0)=57
                AND count(*) FILTER(WHERE source.reconciliation_outcome_code='PAYMENT_ACTIVITY_RECONCILED_AFTER_RETRY'
            AND source.certified_state_code='CERTIFIED_REASSESSMENT_DUE_AFTER_RETRY'
            AND source.state_certified_flag IS TRUE
            AND source.active_state_flag IS TRUE
            AND source.closed_state_flag IS FALSE
            AND source.review_hold_state_flag IS FALSE
            AND source.exception_resolved_flag IS TRUE
            AND source.exception_case_count=1
            AND source.resolved_exception_count=1
            AND source.unresolved_exception_count=0
            AND source.payment_event_count=7
            AND source.settled_event_count=5
            AND source.returned_event_count=1
            AND source.retry_event_count=1
            AND source.certified_exposure_amount=323.79
            AND source.scheduled_payment_amount=194.25
            AND source.processed_payment_amount=194.25
            AND source.returned_payment_amount=27.75
            AND source.retry_payment_amount=27.75
            AND source.reconciliation_variance_amount=0
            AND source.exposure_variance_amount=0)=1
                AND count(*) FILTER(WHERE source.reconciliation_outcome_code='RECONCILIATION_REVIEW_HOLD'
            AND source.certified_state_code='CERTIFIED_REVIEW_HOLD'
            AND source.state_certified_flag IS TRUE
            AND source.review_hold_state_flag IS TRUE
            AND source.active_state_flag IS FALSE
            AND source.closed_state_flag IS FALSE
            AND source.exception_resolved_flag IS FALSE
            AND source.exception_case_count=0
            AND source.resolved_exception_count=0
            AND source.unresolved_exception_count=0
            AND source.certified_exposure_amount=461.69
            AND source.scheduled_payment_amount=0
            AND source.processed_payment_amount=0
            AND source.returned_payment_amount=0
            AND source.retry_payment_amount=0
            AND source.reconciliation_variance_amount=0
            AND source.exposure_variance_amount=0)=1
                AND count(*) FILTER
                (
                    WHERE NOT
                    (
                        (source.reconciliation_outcome_code='NO_PAYMENT_ACTIVITY_RECONCILED'
            AND source.certified_state_code='CERTIFIED_CLOSED_NO_PROCESSING'
            AND source.state_certified_flag IS TRUE
            AND source.closed_state_flag IS TRUE
            AND source.active_state_flag IS FALSE
            AND source.review_hold_state_flag IS FALSE
            AND source.exception_resolved_flag IS FALSE
            AND source.exception_case_count=0
            AND source.resolved_exception_count=0
            AND source.unresolved_exception_count=0
            AND source.certified_exposure_amount=0
            AND source.scheduled_payment_amount=0
            AND source.processed_payment_amount=0
            AND source.returned_payment_amount=0
            AND source.retry_payment_amount=0
            AND source.reconciliation_variance_amount=0
            AND source.exposure_variance_amount=0) OR (source.reconciliation_outcome_code='PAYMENT_ACTIVITY_RECONCILED_AFTER_RETRY'
            AND source.certified_state_code='CERTIFIED_REASSESSMENT_DUE_AFTER_RETRY'
            AND source.state_certified_flag IS TRUE
            AND source.active_state_flag IS TRUE
            AND source.closed_state_flag IS FALSE
            AND source.review_hold_state_flag IS FALSE
            AND source.exception_resolved_flag IS TRUE
            AND source.exception_case_count=1
            AND source.resolved_exception_count=1
            AND source.unresolved_exception_count=0
            AND source.payment_event_count=7
            AND source.settled_event_count=5
            AND source.returned_event_count=1
            AND source.retry_event_count=1
            AND source.certified_exposure_amount=323.79
            AND source.scheduled_payment_amount=194.25
            AND source.processed_payment_amount=194.25
            AND source.returned_payment_amount=27.75
            AND source.retry_payment_amount=27.75
            AND source.reconciliation_variance_amount=0
            AND source.exposure_variance_amount=0) OR (source.reconciliation_outcome_code='RECONCILIATION_REVIEW_HOLD'
            AND source.certified_state_code='CERTIFIED_REVIEW_HOLD'
            AND source.state_certified_flag IS TRUE
            AND source.review_hold_state_flag IS TRUE
            AND source.active_state_flag IS FALSE
            AND source.closed_state_flag IS FALSE
            AND source.exception_resolved_flag IS FALSE
            AND source.exception_case_count=0
            AND source.resolved_exception_count=0
            AND source.unresolved_exception_count=0
            AND source.certified_exposure_amount=461.69
            AND source.scheduled_payment_amount=0
            AND source.processed_payment_amount=0
            AND source.returned_payment_amount=0
            AND source.retry_payment_amount=0
            AND source.reconciliation_variance_amount=0
            AND source.exposure_variance_amount=0)
                    )
                )=0
              FROM msbf_m2.portfolio_performance_source_snapshot AS source
              WHERE source.module1_run_id=(SELECT run_id FROM _m2_10_vctx))),FALSE),
            'Source posture uses the exact accepted M2.9 outcome, certification-state, flag, exception, amount, and variance predicates.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_035_SOURCE_CERTIFIED',
            'SOURCE_CERTIFIED_ROWS',
            ((SELECT count(*) FROM msbf_m2.portfolio_performance_source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND state_certified_flag))::text,
            '59',
            coalesce(((SELECT count(*)=59 FROM msbf_m2.portfolio_performance_source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND state_certified_flag)),FALSE),
            'Every source account is certified.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_036_SOURCE_EXPOSURE',
            'SOURCE_CERTIFIED_EXPOSURE',
            ((SELECT round(sum(certified_exposure_amount),2) FROM msbf_m2.portfolio_performance_source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx)))::text,
            '785.48',
            coalesce(((SELECT round(sum(certified_exposure_amount),2)=785.48 FROM msbf_m2.portfolio_performance_source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx))),FALSE),
            'Source certified exposure is exact.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_037_SOURCE_PAYMENTS',
            'SOURCE_PAYMENT_TOTALS',
            ((SELECT round(sum(scheduled_payment_amount),2)||'|'||round(sum(processed_payment_amount),2)||'|'||round(sum(returned_payment_amount),2)||'|'||round(sum(retry_payment_amount),2) FROM msbf_m2.portfolio_performance_source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx)))::text,
            '194.25|194.25|27.75|27.75',
            coalesce(((SELECT round(sum(scheduled_payment_amount),2)=194.25 AND round(sum(processed_payment_amount),2)=194.25 AND round(sum(returned_payment_amount),2)=27.75 AND round(sum(retry_payment_amount),2)=27.75 FROM msbf_m2.portfolio_performance_source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx))),FALSE),
            'Source payment totals are exact.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_038_SOURCE_VARIANCES',
            'SOURCE_VARIANCES',
            ((SELECT round(sum(abs(reconciliation_variance_amount)),2)||'|'||round(sum(abs(exposure_variance_amount)),2) FROM msbf_m2.portfolio_performance_source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx)))::text,
            '0.00|0.00',
            coalesce(((SELECT round(sum(abs(reconciliation_variance_amount)),2)=0 AND round(sum(abs(exposure_variance_amount)),2)=0 FROM msbf_m2.portfolio_performance_source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx))),FALSE),
            'Source variances are zero.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_039_SOURCE_EXCEPTIONS',
            'SOURCE_EXCEPTIONS',
            ((SELECT sum(exception_case_count)||'|'||sum(resolved_exception_count)||'|'||sum(unresolved_exception_count) FROM msbf_m2.portfolio_performance_source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx)))::text,
            '1|1|0',
            coalesce(((SELECT sum(exception_case_count)=1 AND sum(resolved_exception_count)=1 AND sum(unresolved_exception_count)=0 FROM msbf_m2.portfolio_performance_source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx))),FALSE),
            'Source exception posture is exact.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_040_SOURCE_HASH_IDENTITY',
            'SOURCE_HASH_ERRORS',
            ((SELECT count(*) FROM msbf_m2.portfolio_performance_source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND source_combined_set_hash<>'6af76d0059b47623619ebc09330b15fe'))::text,
            '0',
            coalesce(((SELECT count(*)=0 FROM msbf_m2.portfolio_performance_source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND source_combined_set_hash<>'6af76d0059b47623619ebc09330b15fe')),FALSE),
            'Every source row retains the accepted combined hash.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_041_SOURCE_LINEAGE',
            'SOURCE_LINEAGE_ERRORS',
            ((SELECT count(*) FROM msbf_m2.portfolio_performance_source_snapshot AS s LEFT JOIN msbf_m2.application_payment_reconciliation_certification_latest AS l ON l.module1_run_id=s.module1_run_id AND l.scenario_id=s.scenario_id AND l.merchant_application_id=s.merchant_application_id WHERE s.module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND (l.contract_row_hash IS NULL OR s.source_contract_row_hash IS DISTINCT FROM l.contract_row_hash)))::text,
            '0',
            coalesce(((SELECT count(*)=0 FROM msbf_m2.portfolio_performance_source_snapshot AS s LEFT JOIN msbf_m2.application_payment_reconciliation_certification_latest AS l ON l.module1_run_id=s.module1_run_id AND l.scenario_id=s.scenario_id AND l.merchant_application_id=s.merchant_application_id WHERE s.module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND (l.contract_row_hash IS NULL OR s.source_contract_row_hash IS DISTINCT FROM l.contract_row_hash))),FALSE),
            'Source lineage preserves accepted M2.9 row hashes.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_042_SOURCE_PHYSICAL_HASH',
            'SOURCE_PHYSICAL_HASH_ERRORS',
            ((SELECT count(*) FROM msbf_m2.portfolio_performance_source_snapshot AS s WHERE s.module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND s.row_hash IS DISTINCT FROM msbf_ctl.m2_10_hash_jsonb(to_jsonb(s)-'row_hash'-'created_at')))::text,
            '0',
            coalesce(((SELECT count(*)=0 FROM msbf_m2.portfolio_performance_source_snapshot AS s WHERE s.module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND s.row_hash IS DISTINCT FROM msbf_ctl.m2_10_hash_jsonb(to_jsonb(s)-'row_hash'-'created_at'))),FALSE),
            'Source hashes reconstruct physically.'
        );
END;
$m2_10_positive_031_042$;

/* Controls 043–060 — bounded parser-safe execution block. */
DO $m2_10_positive_043_060$
BEGIN
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_043_PERFORMANCE_COUNT',
            'PERFORMANCE_ROWS',
            ((SELECT count(*) FROM msbf_m2.application_portfolio_performance_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx)))::text,
            '59',
            coalesce(((SELECT count(*)=59 FROM msbf_m2.application_portfolio_performance_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx))),FALSE),
            'Account-performance fact contains 59 rows.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_044_PERFORMANCE_GRAIN',
            'PERFORMANCE_GRAIN_DUPLICATES',
            ((SELECT count(*)-count(DISTINCT scenario_id::text||'|'||merchant_application_id) FROM msbf_m2.application_portfolio_performance_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx)))::text,
            '0',
            coalesce(((SELECT count(*)=count(DISTINCT scenario_id::text||'|'||merchant_application_id) FROM msbf_m2.application_portfolio_performance_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx))),FALSE),
            'Account-performance grain is unique.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_045_PERFORMANCE_LINEAGE',
            'PERFORMANCE_LINEAGE_ERRORS',
            ((SELECT count(*) FROM msbf_m2.application_portfolio_performance_snapshot AS p LEFT JOIN msbf_m2.portfolio_performance_source_snapshot AS s ON s.module1_run_id=p.module1_run_id AND s.scenario_id=p.scenario_id AND s.merchant_application_id=p.merchant_application_id WHERE p.module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND (s.row_hash IS NULL OR p.source_snapshot_row_hash IS DISTINCT FROM s.row_hash OR p.source_contract_row_hash IS DISTINCT FROM s.source_contract_row_hash)))::text,
            '0',
            coalesce(((SELECT count(*)=0 FROM msbf_m2.application_portfolio_performance_snapshot AS p LEFT JOIN msbf_m2.portfolio_performance_source_snapshot AS s ON s.module1_run_id=p.module1_run_id AND s.scenario_id=p.scenario_id AND s.merchant_application_id=p.merchant_application_id WHERE p.module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND (s.row_hash IS NULL OR p.source_snapshot_row_hash IS DISTINCT FROM s.row_hash OR p.source_contract_row_hash IS DISTINCT FROM s.source_contract_row_hash))),FALSE),
            'Performance facts preserve source lineage.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_046_PERFORMANCE_TIERS',
            'SOURCE_TO_PERFORMANCE_MAPPING_ERRORS',
            ((SELECT count(*)
     FROM msbf_m2.portfolio_performance_source_snapshot AS source
     FULL OUTER JOIN msbf_m2.application_portfolio_performance_snapshot AS performance
       ON performance.module1_run_id=source.module1_run_id
      AND performance.scenario_id=source.scenario_id
      AND performance.merchant_application_id=source.merchant_application_id
     WHERE coalesce(source.module1_run_id,performance.module1_run_id)=
           (SELECT run_id FROM _m2_10_vctx)
       AND
       (
           source.row_hash IS NULL
           OR performance.row_hash IS NULL
           OR (CASE
            WHEN source.reconciliation_outcome_code='NO_PAYMENT_ACTIVITY_RECONCILED'
            AND source.certified_state_code='CERTIFIED_CLOSED_NO_PROCESSING'
            AND source.state_certified_flag IS TRUE
            AND source.closed_state_flag IS TRUE
            AND source.active_state_flag IS FALSE
            AND source.review_hold_state_flag IS FALSE
            AND source.exception_resolved_flag IS FALSE
            AND source.exception_case_count=0
            AND source.resolved_exception_count=0
            AND source.unresolved_exception_count=0
            AND source.certified_exposure_amount=0
            AND source.scheduled_payment_amount=0
            AND source.processed_payment_amount=0
            AND source.returned_payment_amount=0
            AND source.retry_payment_amount=0
            AND source.reconciliation_variance_amount=0
            AND source.exposure_variance_amount=0
            THEN 'CLOSED_STABLE'
            WHEN source.reconciliation_outcome_code='PAYMENT_ACTIVITY_RECONCILED_AFTER_RETRY'
            AND source.certified_state_code='CERTIFIED_REASSESSMENT_DUE_AFTER_RETRY'
            AND source.state_certified_flag IS TRUE
            AND source.active_state_flag IS TRUE
            AND source.closed_state_flag IS FALSE
            AND source.review_hold_state_flag IS FALSE
            AND source.exception_resolved_flag IS TRUE
            AND source.exception_case_count=1
            AND source.resolved_exception_count=1
            AND source.unresolved_exception_count=0
            AND source.payment_event_count=7
            AND source.settled_event_count=5
            AND source.returned_event_count=1
            AND source.retry_event_count=1
            AND source.certified_exposure_amount=323.79
            AND source.scheduled_payment_amount=194.25
            AND source.processed_payment_amount=194.25
            AND source.returned_payment_amount=27.75
            AND source.retry_payment_amount=27.75
            AND source.reconciliation_variance_amount=0
            AND source.exposure_variance_amount=0
            THEN 'ACTIVE_RECONCILED'
            WHEN source.reconciliation_outcome_code='RECONCILIATION_REVIEW_HOLD'
            AND source.certified_state_code='CERTIFIED_REVIEW_HOLD'
            AND source.state_certified_flag IS TRUE
            AND source.review_hold_state_flag IS TRUE
            AND source.active_state_flag IS FALSE
            AND source.closed_state_flag IS FALSE
            AND source.exception_resolved_flag IS FALSE
            AND source.exception_case_count=0
            AND source.resolved_exception_count=0
            AND source.unresolved_exception_count=0
            AND source.certified_exposure_amount=461.69
            AND source.scheduled_payment_amount=0
            AND source.processed_payment_amount=0
            AND source.returned_payment_amount=0
            AND source.retry_payment_amount=0
            AND source.reconciliation_variance_amount=0
            AND source.exposure_variance_amount=0
            THEN 'CONTROLLED_REVIEW'
            ELSE 'SOURCE_MAPPING_ERROR'
        END) IS DISTINCT FROM performance.performance_tier_code
           OR (CASE
            WHEN source.reconciliation_outcome_code='NO_PAYMENT_ACTIVITY_RECONCILED'
            AND source.certified_state_code='CERTIFIED_CLOSED_NO_PROCESSING'
            AND source.state_certified_flag IS TRUE
            AND source.closed_state_flag IS TRUE
            AND source.active_state_flag IS FALSE
            AND source.review_hold_state_flag IS FALSE
            AND source.exception_resolved_flag IS FALSE
            AND source.exception_case_count=0
            AND source.resolved_exception_count=0
            AND source.unresolved_exception_count=0
            AND source.certified_exposure_amount=0
            AND source.scheduled_payment_amount=0
            AND source.processed_payment_amount=0
            AND source.returned_payment_amount=0
            AND source.retry_payment_amount=0
            AND source.reconciliation_variance_amount=0
            AND source.exposure_variance_amount=0
            THEN 'NO_SERVICING_REQUIRED'
            WHEN source.reconciliation_outcome_code='PAYMENT_ACTIVITY_RECONCILED_AFTER_RETRY'
            AND source.certified_state_code='CERTIFIED_REASSESSMENT_DUE_AFTER_RETRY'
            AND source.state_certified_flag IS TRUE
            AND source.active_state_flag IS TRUE
            AND source.closed_state_flag IS FALSE
            AND source.review_hold_state_flag IS FALSE
            AND source.exception_resolved_flag IS TRUE
            AND source.exception_case_count=1
            AND source.resolved_exception_count=1
            AND source.unresolved_exception_count=0
            AND source.payment_event_count=7
            AND source.settled_event_count=5
            AND source.returned_event_count=1
            AND source.retry_event_count=1
            AND source.certified_exposure_amount=323.79
            AND source.scheduled_payment_amount=194.25
            AND source.processed_payment_amount=194.25
            AND source.returned_payment_amount=27.75
            AND source.retry_payment_amount=27.75
            AND source.reconciliation_variance_amount=0
            AND source.exposure_variance_amount=0
            THEN 'ACTIVE_REASSESSMENT'
            WHEN source.reconciliation_outcome_code='RECONCILIATION_REVIEW_HOLD'
            AND source.certified_state_code='CERTIFIED_REVIEW_HOLD'
            AND source.state_certified_flag IS TRUE
            AND source.review_hold_state_flag IS TRUE
            AND source.active_state_flag IS FALSE
            AND source.closed_state_flag IS FALSE
            AND source.exception_resolved_flag IS FALSE
            AND source.exception_case_count=0
            AND source.resolved_exception_count=0
            AND source.unresolved_exception_count=0
            AND source.certified_exposure_amount=461.69
            AND source.scheduled_payment_amount=0
            AND source.processed_payment_amount=0
            AND source.returned_payment_amount=0
            AND source.retry_payment_amount=0
            AND source.reconciliation_variance_amount=0
            AND source.exposure_variance_amount=0
            THEN 'GOVERNANCE_REVIEW_HOLD'
            ELSE 'SOURCE_MAPPING_ERROR'
        END) IS DISTINCT FROM performance.servicing_queue_code
           OR (CASE
            WHEN source.reconciliation_outcome_code='NO_PAYMENT_ACTIVITY_RECONCILED'
            AND source.certified_state_code='CERTIFIED_CLOSED_NO_PROCESSING'
            AND source.state_certified_flag IS TRUE
            AND source.closed_state_flag IS TRUE
            AND source.active_state_flag IS FALSE
            AND source.review_hold_state_flag IS FALSE
            AND source.exception_resolved_flag IS FALSE
            AND source.exception_case_count=0
            AND source.resolved_exception_count=0
            AND source.unresolved_exception_count=0
            AND source.certified_exposure_amount=0
            AND source.scheduled_payment_amount=0
            AND source.processed_payment_amount=0
            AND source.returned_payment_amount=0
            AND source.retry_payment_amount=0
            AND source.reconciliation_variance_amount=0
            AND source.exposure_variance_amount=0
            THEN 'M2_10_REASON_CLOSED_STABLE'
            WHEN source.reconciliation_outcome_code='PAYMENT_ACTIVITY_RECONCILED_AFTER_RETRY'
            AND source.certified_state_code='CERTIFIED_REASSESSMENT_DUE_AFTER_RETRY'
            AND source.state_certified_flag IS TRUE
            AND source.active_state_flag IS TRUE
            AND source.closed_state_flag IS FALSE
            AND source.review_hold_state_flag IS FALSE
            AND source.exception_resolved_flag IS TRUE
            AND source.exception_case_count=1
            AND source.resolved_exception_count=1
            AND source.unresolved_exception_count=0
            AND source.payment_event_count=7
            AND source.settled_event_count=5
            AND source.returned_event_count=1
            AND source.retry_event_count=1
            AND source.certified_exposure_amount=323.79
            AND source.scheduled_payment_amount=194.25
            AND source.processed_payment_amount=194.25
            AND source.returned_payment_amount=27.75
            AND source.retry_payment_amount=27.75
            AND source.reconciliation_variance_amount=0
            AND source.exposure_variance_amount=0
            THEN 'M2_10_REASON_ACTIVE_RECONCILED'
            WHEN source.reconciliation_outcome_code='RECONCILIATION_REVIEW_HOLD'
            AND source.certified_state_code='CERTIFIED_REVIEW_HOLD'
            AND source.state_certified_flag IS TRUE
            AND source.review_hold_state_flag IS TRUE
            AND source.active_state_flag IS FALSE
            AND source.closed_state_flag IS FALSE
            AND source.exception_resolved_flag IS FALSE
            AND source.exception_case_count=0
            AND source.resolved_exception_count=0
            AND source.unresolved_exception_count=0
            AND source.certified_exposure_amount=461.69
            AND source.scheduled_payment_amount=0
            AND source.processed_payment_amount=0
            AND source.returned_payment_amount=0
            AND source.retry_payment_amount=0
            AND source.reconciliation_variance_amount=0
            AND source.exposure_variance_amount=0
            THEN 'M2_10_REASON_CONTROLLED_REVIEW'
            ELSE 'M2_10_REASON_SOURCE_MAPPING_ERROR'
        END) IS DISTINCT FROM performance.primary_portfolio_reason_code
       )))::text,
            '0',
            coalesce(((SELECT count(*)
     FROM msbf_m2.portfolio_performance_source_snapshot AS source
     FULL OUTER JOIN msbf_m2.application_portfolio_performance_snapshot AS performance
       ON performance.module1_run_id=source.module1_run_id
      AND performance.scenario_id=source.scenario_id
      AND performance.merchant_application_id=source.merchant_application_id
     WHERE coalesce(source.module1_run_id,performance.module1_run_id)=
           (SELECT run_id FROM _m2_10_vctx)
       AND
       (
           source.row_hash IS NULL
           OR performance.row_hash IS NULL
           OR (CASE
            WHEN source.reconciliation_outcome_code='NO_PAYMENT_ACTIVITY_RECONCILED'
            AND source.certified_state_code='CERTIFIED_CLOSED_NO_PROCESSING'
            AND source.state_certified_flag IS TRUE
            AND source.closed_state_flag IS TRUE
            AND source.active_state_flag IS FALSE
            AND source.review_hold_state_flag IS FALSE
            AND source.exception_resolved_flag IS FALSE
            AND source.exception_case_count=0
            AND source.resolved_exception_count=0
            AND source.unresolved_exception_count=0
            AND source.certified_exposure_amount=0
            AND source.scheduled_payment_amount=0
            AND source.processed_payment_amount=0
            AND source.returned_payment_amount=0
            AND source.retry_payment_amount=0
            AND source.reconciliation_variance_amount=0
            AND source.exposure_variance_amount=0
            THEN 'CLOSED_STABLE'
            WHEN source.reconciliation_outcome_code='PAYMENT_ACTIVITY_RECONCILED_AFTER_RETRY'
            AND source.certified_state_code='CERTIFIED_REASSESSMENT_DUE_AFTER_RETRY'
            AND source.state_certified_flag IS TRUE
            AND source.active_state_flag IS TRUE
            AND source.closed_state_flag IS FALSE
            AND source.review_hold_state_flag IS FALSE
            AND source.exception_resolved_flag IS TRUE
            AND source.exception_case_count=1
            AND source.resolved_exception_count=1
            AND source.unresolved_exception_count=0
            AND source.payment_event_count=7
            AND source.settled_event_count=5
            AND source.returned_event_count=1
            AND source.retry_event_count=1
            AND source.certified_exposure_amount=323.79
            AND source.scheduled_payment_amount=194.25
            AND source.processed_payment_amount=194.25
            AND source.returned_payment_amount=27.75
            AND source.retry_payment_amount=27.75
            AND source.reconciliation_variance_amount=0
            AND source.exposure_variance_amount=0
            THEN 'ACTIVE_RECONCILED'
            WHEN source.reconciliation_outcome_code='RECONCILIATION_REVIEW_HOLD'
            AND source.certified_state_code='CERTIFIED_REVIEW_HOLD'
            AND source.state_certified_flag IS TRUE
            AND source.review_hold_state_flag IS TRUE
            AND source.active_state_flag IS FALSE
            AND source.closed_state_flag IS FALSE
            AND source.exception_resolved_flag IS FALSE
            AND source.exception_case_count=0
            AND source.resolved_exception_count=0
            AND source.unresolved_exception_count=0
            AND source.certified_exposure_amount=461.69
            AND source.scheduled_payment_amount=0
            AND source.processed_payment_amount=0
            AND source.returned_payment_amount=0
            AND source.retry_payment_amount=0
            AND source.reconciliation_variance_amount=0
            AND source.exposure_variance_amount=0
            THEN 'CONTROLLED_REVIEW'
            ELSE 'SOURCE_MAPPING_ERROR'
        END) IS DISTINCT FROM performance.performance_tier_code
           OR (CASE
            WHEN source.reconciliation_outcome_code='NO_PAYMENT_ACTIVITY_RECONCILED'
            AND source.certified_state_code='CERTIFIED_CLOSED_NO_PROCESSING'
            AND source.state_certified_flag IS TRUE
            AND source.closed_state_flag IS TRUE
            AND source.active_state_flag IS FALSE
            AND source.review_hold_state_flag IS FALSE
            AND source.exception_resolved_flag IS FALSE
            AND source.exception_case_count=0
            AND source.resolved_exception_count=0
            AND source.unresolved_exception_count=0
            AND source.certified_exposure_amount=0
            AND source.scheduled_payment_amount=0
            AND source.processed_payment_amount=0
            AND source.returned_payment_amount=0
            AND source.retry_payment_amount=0
            AND source.reconciliation_variance_amount=0
            AND source.exposure_variance_amount=0
            THEN 'NO_SERVICING_REQUIRED'
            WHEN source.reconciliation_outcome_code='PAYMENT_ACTIVITY_RECONCILED_AFTER_RETRY'
            AND source.certified_state_code='CERTIFIED_REASSESSMENT_DUE_AFTER_RETRY'
            AND source.state_certified_flag IS TRUE
            AND source.active_state_flag IS TRUE
            AND source.closed_state_flag IS FALSE
            AND source.review_hold_state_flag IS FALSE
            AND source.exception_resolved_flag IS TRUE
            AND source.exception_case_count=1
            AND source.resolved_exception_count=1
            AND source.unresolved_exception_count=0
            AND source.payment_event_count=7
            AND source.settled_event_count=5
            AND source.returned_event_count=1
            AND source.retry_event_count=1
            AND source.certified_exposure_amount=323.79
            AND source.scheduled_payment_amount=194.25
            AND source.processed_payment_amount=194.25
            AND source.returned_payment_amount=27.75
            AND source.retry_payment_amount=27.75
            AND source.reconciliation_variance_amount=0
            AND source.exposure_variance_amount=0
            THEN 'ACTIVE_REASSESSMENT'
            WHEN source.reconciliation_outcome_code='RECONCILIATION_REVIEW_HOLD'
            AND source.certified_state_code='CERTIFIED_REVIEW_HOLD'
            AND source.state_certified_flag IS TRUE
            AND source.review_hold_state_flag IS TRUE
            AND source.active_state_flag IS FALSE
            AND source.closed_state_flag IS FALSE
            AND source.exception_resolved_flag IS FALSE
            AND source.exception_case_count=0
            AND source.resolved_exception_count=0
            AND source.unresolved_exception_count=0
            AND source.certified_exposure_amount=461.69
            AND source.scheduled_payment_amount=0
            AND source.processed_payment_amount=0
            AND source.returned_payment_amount=0
            AND source.retry_payment_amount=0
            AND source.reconciliation_variance_amount=0
            AND source.exposure_variance_amount=0
            THEN 'GOVERNANCE_REVIEW_HOLD'
            ELSE 'SOURCE_MAPPING_ERROR'
        END) IS DISTINCT FROM performance.servicing_queue_code
           OR (CASE
            WHEN source.reconciliation_outcome_code='NO_PAYMENT_ACTIVITY_RECONCILED'
            AND source.certified_state_code='CERTIFIED_CLOSED_NO_PROCESSING'
            AND source.state_certified_flag IS TRUE
            AND source.closed_state_flag IS TRUE
            AND source.active_state_flag IS FALSE
            AND source.review_hold_state_flag IS FALSE
            AND source.exception_resolved_flag IS FALSE
            AND source.exception_case_count=0
            AND source.resolved_exception_count=0
            AND source.unresolved_exception_count=0
            AND source.certified_exposure_amount=0
            AND source.scheduled_payment_amount=0
            AND source.processed_payment_amount=0
            AND source.returned_payment_amount=0
            AND source.retry_payment_amount=0
            AND source.reconciliation_variance_amount=0
            AND source.exposure_variance_amount=0
            THEN 'M2_10_REASON_CLOSED_STABLE'
            WHEN source.reconciliation_outcome_code='PAYMENT_ACTIVITY_RECONCILED_AFTER_RETRY'
            AND source.certified_state_code='CERTIFIED_REASSESSMENT_DUE_AFTER_RETRY'
            AND source.state_certified_flag IS TRUE
            AND source.active_state_flag IS TRUE
            AND source.closed_state_flag IS FALSE
            AND source.review_hold_state_flag IS FALSE
            AND source.exception_resolved_flag IS TRUE
            AND source.exception_case_count=1
            AND source.resolved_exception_count=1
            AND source.unresolved_exception_count=0
            AND source.payment_event_count=7
            AND source.settled_event_count=5
            AND source.returned_event_count=1
            AND source.retry_event_count=1
            AND source.certified_exposure_amount=323.79
            AND source.scheduled_payment_amount=194.25
            AND source.processed_payment_amount=194.25
            AND source.returned_payment_amount=27.75
            AND source.retry_payment_amount=27.75
            AND source.reconciliation_variance_amount=0
            AND source.exposure_variance_amount=0
            THEN 'M2_10_REASON_ACTIVE_RECONCILED'
            WHEN source.reconciliation_outcome_code='RECONCILIATION_REVIEW_HOLD'
            AND source.certified_state_code='CERTIFIED_REVIEW_HOLD'
            AND source.state_certified_flag IS TRUE
            AND source.review_hold_state_flag IS TRUE
            AND source.active_state_flag IS FALSE
            AND source.closed_state_flag IS FALSE
            AND source.exception_resolved_flag IS FALSE
            AND source.exception_case_count=0
            AND source.resolved_exception_count=0
            AND source.unresolved_exception_count=0
            AND source.certified_exposure_amount=461.69
            AND source.scheduled_payment_amount=0
            AND source.processed_payment_amount=0
            AND source.returned_payment_amount=0
            AND source.retry_payment_amount=0
            AND source.reconciliation_variance_amount=0
            AND source.exposure_variance_amount=0
            THEN 'M2_10_REASON_CONTROLLED_REVIEW'
            ELSE 'M2_10_REASON_SOURCE_MAPPING_ERROR'
        END) IS DISTINCT FROM performance.primary_portfolio_reason_code
       ))=0),FALSE),
            'Every accepted M2.9 source row maps exactly to the governed M2.10 tier, queue, and primary reason.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_047_PERFORMANCE_QUEUES',
            'PERFORMANCE_QUEUES',
            ((SELECT count(*) FILTER(WHERE servicing_queue_code='NO_SERVICING_REQUIRED')||'|'||count(*) FILTER(WHERE servicing_queue_code='ACTIVE_REASSESSMENT')||'|'||count(*) FILTER(WHERE servicing_queue_code='GOVERNANCE_REVIEW_HOLD') FROM msbf_m2.application_portfolio_performance_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx)))::text,
            '57|1|1',
            coalesce(((SELECT count(*) FILTER(WHERE servicing_queue_code='NO_SERVICING_REQUIRED')=57 AND count(*) FILTER(WHERE servicing_queue_code='ACTIVE_REASSESSMENT')=1 AND count(*) FILTER(WHERE servicing_queue_code='GOVERNANCE_REVIEW_HOLD')=1 FROM msbf_m2.application_portfolio_performance_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx))),FALSE),
            'Servicing queues reproduce 57/1/1.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_048_PERFORMANCE_BURDEN',
            'PERFORMANCE_BURDEN',
            ((SELECT round(sum(servicing_burden_units),6) FROM msbf_m2.application_portfolio_performance_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx)))::text,
            '7.000000',
            coalesce(((SELECT round(sum(servicing_burden_units),6)=7 FROM msbf_m2.application_portfolio_performance_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx))),FALSE),
            'Total servicing burden is 7 units.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_049_PERFORMANCE_RATES',
            'PERFORMANCE_RATE_ERRORS',
            ((SELECT count(*) FROM msbf_m2.application_portfolio_performance_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND ((scheduled_payment_amount>0 AND gross_collection_rate IS DISTINCT FROM round(processed_payment_amount/scheduled_payment_amount,6)) OR (scheduled_payment_amount>0 AND return_rate IS DISTINCT FROM round(returned_payment_amount/scheduled_payment_amount,6)) OR (returned_payment_amount>0 AND retry_cure_rate IS DISTINCT FROM round(retry_payment_amount/returned_payment_amount,6)))))::text,
            '0',
            coalesce(((SELECT count(*)=0 FROM msbf_m2.application_portfolio_performance_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND ((scheduled_payment_amount>0 AND gross_collection_rate IS DISTINCT FROM round(processed_payment_amount/scheduled_payment_amount,6)) OR (scheduled_payment_amount>0 AND return_rate IS DISTINCT FROM round(returned_payment_amount/scheduled_payment_amount,6)) OR (returned_payment_amount>0 AND retry_cure_rate IS DISTINCT FROM round(retry_payment_amount/returned_payment_amount,6))))),FALSE),
            'Account rates reconstruct from amounts.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_050_PERFORMANCE_REASON_ARRAY',
            'PERFORMANCE_REASON_ERRORS',
            ((SELECT count(*) FROM msbf_m2.application_portfolio_performance_snapshot AS p WHERE p.module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND (jsonb_typeof(p.portfolio_reason_codes)<>'array' OR jsonb_array_length(p.portfolio_reason_codes)=0 OR NOT EXISTS(SELECT 1 FROM jsonb_array_elements_text(p.portfolio_reason_codes) AS r(code) WHERE r.code=p.primary_portfolio_reason_code))))::text,
            '0',
            coalesce(((SELECT count(*)=0 FROM msbf_m2.application_portfolio_performance_snapshot AS p WHERE p.module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND (jsonb_typeof(p.portfolio_reason_codes)<>'array' OR jsonb_array_length(p.portfolio_reason_codes)=0 OR NOT EXISTS(SELECT 1 FROM jsonb_array_elements_text(p.portfolio_reason_codes) AS r(code) WHERE r.code=p.primary_portfolio_reason_code)))),FALSE),
            'Every performance row contains its primary reason.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_051_PERFORMANCE_PHYSICAL_HASH',
            'PERFORMANCE_HASH_ERRORS',
            ((SELECT count(*) FROM msbf_m2.application_portfolio_performance_snapshot AS p WHERE p.module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND p.row_hash IS DISTINCT FROM msbf_ctl.m2_10_hash_jsonb(to_jsonb(p)-'row_hash'-'created_at')))::text,
            '0',
            coalesce(((SELECT count(*)=0 FROM msbf_m2.application_portfolio_performance_snapshot AS p WHERE p.module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND p.row_hash IS DISTINCT FROM msbf_ctl.m2_10_hash_jsonb(to_jsonb(p)-'row_hash'-'created_at'))),FALSE),
            'Performance hashes reconstruct physically.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_052_PERFORMANCE_CERTIFIED',
            'PERFORMANCE_CERTIFIED_ROWS',
            ((SELECT count(*) FROM msbf_m2.application_portfolio_performance_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND state_certified_flag))::text,
            '59',
            coalesce(((SELECT count(*)=59 FROM msbf_m2.application_portfolio_performance_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND state_certified_flag)),FALSE),
            'Every account-performance row is certified.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_053_PERFORMANCE_PAYMENT_ACTIVITY',
            'PAYMENT_ACTIVITY_ROWS',
            ((SELECT count(*) FROM msbf_m2.application_portfolio_performance_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND payment_activity_flag))::text,
            '1',
            coalesce(((SELECT count(*)=1 FROM msbf_m2.application_portfolio_performance_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND payment_activity_flag)),FALSE),
            'Exactly one account has payment activity.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_054_PERFORMANCE_EXCEPTION_INCIDENT',
            'EXCEPTION_INCIDENT_ROWS',
            ((SELECT count(*) FROM msbf_m2.application_portfolio_performance_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND exception_incident_flag))::text,
            '1',
            coalesce(((SELECT count(*)=1 FROM msbf_m2.application_portfolio_performance_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND exception_incident_flag)),FALSE),
            'Exactly one account has a payment exception incident.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_055_PERFORMANCE_EXCEPTION_RESOLVED',
            'EXCEPTION_RESOLVED_ROWS',
            ((SELECT count(*) FROM msbf_m2.application_portfolio_performance_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND exception_resolved_flag))::text,
            '1',
            coalesce(((SELECT count(*)=1 FROM msbf_m2.application_portfolio_performance_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND exception_resolved_flag)),FALSE),
            'The sole payment exception is resolved.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_056_PERFORMANCE_BOUNDARY_DECISION',
            'PRODUCTION_DECISION_ROWS',
            ((SELECT count(*) FROM msbf_m2.application_portfolio_performance_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND production_decision_executed_flag))::text,
            '0',
            coalesce(((SELECT count(*)=0 FROM msbf_m2.application_portfolio_performance_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND production_decision_executed_flag)),FALSE),
            'No production decision is executed.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_057_PERFORMANCE_BOUNDARY_SYSTEM',
            'EXTERNAL_SYSTEM_ROWS',
            ((SELECT count(*) FROM msbf_m2.application_portfolio_performance_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND external_system_updated_flag))::text,
            '0',
            coalesce(((SELECT count(*)=0 FROM msbf_m2.application_portfolio_performance_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND external_system_updated_flag)),FALSE),
            'No external system is updated.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_058_PERFORMANCE_BOUNDARY_CONTACT',
            'MERCHANT_CONTACT_ROWS',
            ((SELECT count(*) FROM msbf_m2.application_portfolio_performance_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND merchant_contact_executed_flag))::text,
            '0',
            coalesce(((SELECT count(*)=0 FROM msbf_m2.application_portfolio_performance_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND merchant_contact_executed_flag)),FALSE),
            'No merchant contact is executed.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_059_ACTIVE_ACCOUNT_AMOUNTS',
            'ACTIVE_ACCOUNT_AMOUNTS',
            ((SELECT count(*)||'|'||coalesce(max(performance.certified_exposure_amount),0)||'|'||
                     coalesce(max(performance.scheduled_payment_amount),0)||'|'||
                     coalesce(max(performance.processed_payment_amount),0)||'|'||
                     coalesce(max(performance.returned_payment_amount),0)||'|'||
                     coalesce(max(performance.retry_payment_amount),0)
              FROM msbf_m2.application_portfolio_performance_snapshot AS performance
              JOIN msbf_m2.portfolio_performance_source_snapshot AS source
                ON source.module1_run_id=performance.module1_run_id
               AND source.scenario_id=performance.scenario_id
               AND source.merchant_application_id=performance.merchant_application_id
              WHERE performance.module1_run_id=(SELECT run_id FROM _m2_10_vctx)
                AND source.reconciliation_outcome_code='PAYMENT_ACTIVITY_RECONCILED_AFTER_RETRY'
            AND source.certified_state_code='CERTIFIED_REASSESSMENT_DUE_AFTER_RETRY'
            AND source.state_certified_flag IS TRUE
            AND source.active_state_flag IS TRUE
            AND source.closed_state_flag IS FALSE
            AND source.review_hold_state_flag IS FALSE
            AND source.exception_resolved_flag IS TRUE
            AND source.exception_case_count=1
            AND source.resolved_exception_count=1
            AND source.unresolved_exception_count=0
            AND source.payment_event_count=7
            AND source.settled_event_count=5
            AND source.returned_event_count=1
            AND source.retry_event_count=1
            AND source.certified_exposure_amount=323.79
            AND source.scheduled_payment_amount=194.25
            AND source.processed_payment_amount=194.25
            AND source.returned_payment_amount=27.75
            AND source.retry_payment_amount=27.75
            AND source.reconciliation_variance_amount=0
            AND source.exposure_variance_amount=0
                AND performance.performance_tier_code='ACTIVE_RECONCILED'
                AND performance.servicing_queue_code='ACTIVE_REASSESSMENT'
                AND performance.primary_portfolio_reason_code='M2_10_REASON_ACTIVE_RECONCILED'))::text,
            '1|323.79|194.25|194.25|27.75|27.75',
            coalesce(((SELECT count(*)=1
                AND max(performance.certified_exposure_amount)=323.79
                AND max(performance.scheduled_payment_amount)=194.25
                AND max(performance.processed_payment_amount)=194.25
                AND max(performance.returned_payment_amount)=27.75
                AND max(performance.retry_payment_amount)=27.75
              FROM msbf_m2.application_portfolio_performance_snapshot AS performance
              JOIN msbf_m2.portfolio_performance_source_snapshot AS source
                ON source.module1_run_id=performance.module1_run_id
               AND source.scenario_id=performance.scenario_id
               AND source.merchant_application_id=performance.merchant_application_id
              WHERE performance.module1_run_id=(SELECT run_id FROM _m2_10_vctx)
                AND source.reconciliation_outcome_code='PAYMENT_ACTIVITY_RECONCILED_AFTER_RETRY'
            AND source.certified_state_code='CERTIFIED_REASSESSMENT_DUE_AFTER_RETRY'
            AND source.state_certified_flag IS TRUE
            AND source.active_state_flag IS TRUE
            AND source.closed_state_flag IS FALSE
            AND source.review_hold_state_flag IS FALSE
            AND source.exception_resolved_flag IS TRUE
            AND source.exception_case_count=1
            AND source.resolved_exception_count=1
            AND source.unresolved_exception_count=0
            AND source.payment_event_count=7
            AND source.settled_event_count=5
            AND source.returned_event_count=1
            AND source.retry_event_count=1
            AND source.certified_exposure_amount=323.79
            AND source.scheduled_payment_amount=194.25
            AND source.processed_payment_amount=194.25
            AND source.returned_payment_amount=27.75
            AND source.retry_payment_amount=27.75
            AND source.reconciliation_variance_amount=0
            AND source.exposure_variance_amount=0
                AND performance.performance_tier_code='ACTIVE_RECONCILED'
                AND performance.servicing_queue_code='ACTIVE_REASSESSMENT'
                AND performance.primary_portfolio_reason_code='M2_10_REASON_ACTIVE_RECONCILED')),FALSE),
            'The exact accepted M2.9 retry-reconciled account maps to the active tier with exact amounts.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_060_REVIEW_ACCOUNT_AMOUNT',
            'REVIEW_ACCOUNT_AMOUNT',
            ((SELECT count(*)||'|'||coalesce(max(performance.certified_exposure_amount),0)
              FROM msbf_m2.application_portfolio_performance_snapshot AS performance
              JOIN msbf_m2.portfolio_performance_source_snapshot AS source
                ON source.module1_run_id=performance.module1_run_id
               AND source.scenario_id=performance.scenario_id
               AND source.merchant_application_id=performance.merchant_application_id
              WHERE performance.module1_run_id=(SELECT run_id FROM _m2_10_vctx)
                AND source.reconciliation_outcome_code='RECONCILIATION_REVIEW_HOLD'
            AND source.certified_state_code='CERTIFIED_REVIEW_HOLD'
            AND source.state_certified_flag IS TRUE
            AND source.review_hold_state_flag IS TRUE
            AND source.active_state_flag IS FALSE
            AND source.closed_state_flag IS FALSE
            AND source.exception_resolved_flag IS FALSE
            AND source.exception_case_count=0
            AND source.resolved_exception_count=0
            AND source.unresolved_exception_count=0
            AND source.certified_exposure_amount=461.69
            AND source.scheduled_payment_amount=0
            AND source.processed_payment_amount=0
            AND source.returned_payment_amount=0
            AND source.retry_payment_amount=0
            AND source.reconciliation_variance_amount=0
            AND source.exposure_variance_amount=0
                AND performance.performance_tier_code='CONTROLLED_REVIEW'
                AND performance.servicing_queue_code='GOVERNANCE_REVIEW_HOLD'
                AND performance.primary_portfolio_reason_code='M2_10_REASON_CONTROLLED_REVIEW'))::text,
            '1|461.69',
            coalesce(((SELECT count(*)=1
                AND max(performance.certified_exposure_amount)=461.69
              FROM msbf_m2.application_portfolio_performance_snapshot AS performance
              JOIN msbf_m2.portfolio_performance_source_snapshot AS source
                ON source.module1_run_id=performance.module1_run_id
               AND source.scenario_id=performance.scenario_id
               AND source.merchant_application_id=performance.merchant_application_id
              WHERE performance.module1_run_id=(SELECT run_id FROM _m2_10_vctx)
                AND source.reconciliation_outcome_code='RECONCILIATION_REVIEW_HOLD'
            AND source.certified_state_code='CERTIFIED_REVIEW_HOLD'
            AND source.state_certified_flag IS TRUE
            AND source.review_hold_state_flag IS TRUE
            AND source.active_state_flag IS FALSE
            AND source.closed_state_flag IS FALSE
            AND source.exception_resolved_flag IS FALSE
            AND source.exception_case_count=0
            AND source.resolved_exception_count=0
            AND source.unresolved_exception_count=0
            AND source.certified_exposure_amount=461.69
            AND source.scheduled_payment_amount=0
            AND source.processed_payment_amount=0
            AND source.returned_payment_amount=0
            AND source.retry_payment_amount=0
            AND source.reconciliation_variance_amount=0
            AND source.exposure_variance_amount=0
                AND performance.performance_tier_code='CONTROLLED_REVIEW'
                AND performance.servicing_queue_code='GOVERNANCE_REVIEW_HOLD'
                AND performance.primary_portfolio_reason_code='M2_10_REASON_CONTROLLED_REVIEW')),FALSE),
            'The exact accepted M2.9 review-hold account maps to controlled review at $461.69.'
        );
END;
$m2_10_positive_043_060$;

/* Controls 061–075 — bounded parser-safe execution block. */
DO $m2_10_positive_061_075$
BEGIN
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_061_SCOPE_COUNT',
            'SCOPE_ROWS',
            ((SELECT count(*) FROM msbf_m2.portfolio_performance_scope_summary WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx)))::text,
            '3',
            coalesce(((SELECT count(*)=3 FROM msbf_m2.portfolio_performance_scope_summary WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx))),FALSE),
            'Three governed scopes exist.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_062_SCOPE_CODES',
            'SCOPE_CODES',
            ((SELECT string_agg(scope_code,',' ORDER BY scope_code) FROM msbf_m2.portfolio_performance_scope_summary WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx)))::text,
            'BASELINE,PORTFOLIO_ALL,RECESSION_ENERGY',
            coalesce(((SELECT count(*)=3 FROM msbf_m2.portfolio_performance_scope_summary WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND scope_code IN ('PORTFOLIO_ALL','BASELINE','RECESSION_ENERGY'))),FALSE),
            'Portfolio and two scenario scopes exist.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_063_SCOPE_ACCOUNTS',
            'SCOPE_ACCOUNTS',
            ((SELECT max(account_count) FILTER(WHERE scope_code='PORTFOLIO_ALL')||'|'||max(account_count) FILTER(WHERE scope_code='BASELINE')||'|'||max(account_count) FILTER(WHERE scope_code='RECESSION_ENERGY') FROM msbf_m2.portfolio_performance_scope_summary WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx)))::text,
            '59|44|15',
            coalesce(((SELECT max(account_count) FILTER(WHERE scope_code='PORTFOLIO_ALL')=59 AND max(account_count) FILTER(WHERE scope_code='BASELINE')=44 AND max(account_count) FILTER(WHERE scope_code='RECESSION_ENERGY')=15 FROM msbf_m2.portfolio_performance_scope_summary WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx))),FALSE),
            'Scope account counts are exact.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_064_PORTFOLIO_CERTIFICATION',
            'PORTFOLIO_CERTIFICATION',
            ((SELECT certified_account_count||'|'||certification_rate FROM msbf_m2.portfolio_performance_scope_summary WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND scope_code='PORTFOLIO_ALL'))::text,
            '59|1.000000',
            coalesce(((SELECT certified_account_count=59 AND certification_rate=1 FROM msbf_m2.portfolio_performance_scope_summary WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND scope_code='PORTFOLIO_ALL')),FALSE),
            'Portfolio certification is complete.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_065_PORTFOLIO_EXPOSURE',
            'PORTFOLIO_EXPOSURE',
            ((SELECT certified_exposure_amount||'|'||active_exposure_amount||'|'||review_hold_exposure_amount FROM msbf_m2.portfolio_performance_scope_summary WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND scope_code='PORTFOLIO_ALL'))::text,
            '785.48|323.79|461.69',
            coalesce(((SELECT certified_exposure_amount=785.48 AND active_exposure_amount=323.79 AND review_hold_exposure_amount=461.69 FROM msbf_m2.portfolio_performance_scope_summary WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND scope_code='PORTFOLIO_ALL')),FALSE),
            'Portfolio exposure components are exact.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_066_PORTFOLIO_PAYMENT_RATES',
            'PORTFOLIO_PAYMENT_RATES',
            ((SELECT gross_collection_rate||'|'||return_rate||'|'||retry_cure_rate FROM msbf_m2.portfolio_performance_scope_summary WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND scope_code='PORTFOLIO_ALL'))::text,
            '1.000000|0.142857|1.000000',
            coalesce(((SELECT gross_collection_rate=1 AND return_rate=0.142857 AND retry_cure_rate=1 FROM msbf_m2.portfolio_performance_scope_summary WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND scope_code='PORTFOLIO_ALL')),FALSE),
            'Portfolio payment rates are exact.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_067_PORTFOLIO_EXCEPTION_RATE',
            'PORTFOLIO_EXCEPTION_RATE',
            ((SELECT exception_case_count||'|'||resolved_exception_count||'|'||unresolved_exception_count||'|'||exception_resolution_rate FROM msbf_m2.portfolio_performance_scope_summary WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND scope_code='PORTFOLIO_ALL'))::text,
            '1|1|0|1.000000',
            coalesce(((SELECT exception_case_count=1 AND resolved_exception_count=1 AND unresolved_exception_count=0 AND exception_resolution_rate=1 FROM msbf_m2.portfolio_performance_scope_summary WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND scope_code='PORTFOLIO_ALL')),FALSE),
            'Exception resolution is complete.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_068_PORTFOLIO_BURDEN',
            'PORTFOLIO_BURDEN',
            ((SELECT servicing_burden_units||'|'||average_burden_per_account FROM msbf_m2.portfolio_performance_scope_summary WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND scope_code='PORTFOLIO_ALL'))::text,
            '7.000000|0.118644',
            coalesce(((SELECT servicing_burden_units=7 AND average_burden_per_account=0.118644 FROM msbf_m2.portfolio_performance_scope_summary WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND scope_code='PORTFOLIO_ALL')),FALSE),
            'Portfolio servicing burden is exact.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_069_STRESS_ZERO_ACTIVITY',
            'STRESS_ZERO_ACTIVITY',
            ((SELECT scheduled_payment_amount||'|'||processed_payment_amount||'|'||certified_exposure_amount||'|'||servicing_burden_units FROM msbf_m2.portfolio_performance_scope_summary WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND scope_code='RECESSION_ENERGY'))::text,
            '0.00|0.00|0.00|0.000000',
            coalesce(((SELECT scheduled_payment_amount=0 AND processed_payment_amount=0 AND certified_exposure_amount=0 AND servicing_burden_units=0 FROM msbf_m2.portfolio_performance_scope_summary WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND scope_code='RECESSION_ENERGY')),FALSE),
            'Stress matched cohort is closed with zero activity.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_070_SCOPE_PHYSICAL_HASH',
            'SCOPE_HASH_ERRORS',
            ((SELECT count(*) FROM msbf_m2.portfolio_performance_scope_summary AS s WHERE s.module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND s.row_hash IS DISTINCT FROM msbf_ctl.m2_10_hash_jsonb(to_jsonb(s)-'row_hash'-'created_at')))::text,
            '0',
            coalesce(((SELECT count(*)=0 FROM msbf_m2.portfolio_performance_scope_summary AS s WHERE s.module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND s.row_hash IS DISTINCT FROM msbf_ctl.m2_10_hash_jsonb(to_jsonb(s)-'row_hash'-'created_at'))),FALSE),
            'Scope hashes reconstruct physically.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_071_KPI_COUNT',
            'KPI_ROWS',
            ((SELECT count(*) FROM msbf_m2.portfolio_kpi_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx)))::text,
            '72',
            coalesce(((SELECT count(*)=72 FROM msbf_m2.portfolio_kpi_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx))),FALSE),
            'KPI matrix contains 72 facts.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_072_KPI_GRAIN',
            'KPI_GRAIN_DUPLICATES',
            ((SELECT count(*)-count(DISTINCT scope_code||'|'||kpi_code) FROM msbf_m2.portfolio_kpi_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx)))::text,
            '0',
            coalesce(((SELECT count(*)=count(DISTINCT scope_code||'|'||kpi_code) FROM msbf_m2.portfolio_kpi_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx))),FALSE),
            'KPI grain is unique.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_073_KPI_SCOPE_COUNT',
            'KPI_SCOPE_COUNT',
            ((SELECT count(DISTINCT scope_code) FROM msbf_m2.portfolio_kpi_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx)))::text,
            '3',
            coalesce(((SELECT count(DISTINCT scope_code)=3 FROM msbf_m2.portfolio_kpi_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx))),FALSE),
            'KPI facts cover three scopes.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_074_KPI_CODE_COUNT',
            'KPI_CODE_COUNT',
            ((SELECT count(DISTINCT kpi_code) FROM msbf_m2.portfolio_kpi_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx)))::text,
            '24',
            coalesce(((SELECT count(DISTINCT kpi_code)=24 FROM msbf_m2.portfolio_kpi_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx))),FALSE),
            'KPI facts cover all 24 KPIs.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_075_KPI_APPLICABILITY',
            'KPI_APPLICABILITY',
            ((SELECT count(*) FILTER(WHERE applicable_flag)||'|'||count(*) FILTER(WHERE NOT applicable_flag) FROM msbf_m2.portfolio_kpi_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx)))::text,
            '68|4',
            coalesce(((SELECT count(*) FILTER(WHERE applicable_flag)=68 AND count(*) FILTER(WHERE NOT applicable_flag)=4 FROM msbf_m2.portfolio_kpi_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx))),FALSE),
            'KPI applicability is exact.'
        );
END;
$m2_10_positive_061_075$;

/* Controls 076–090 — bounded parser-safe execution block. */
DO $m2_10_positive_076_090$
BEGIN
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_076_KPI_NOT_APPLICABLE_TEXT',
            'KPI_NA_TEXT_ERRORS',
            ((SELECT count(*) FROM msbf_m2.portfolio_kpi_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND NOT applicable_flag AND kpi_value_text<>'NOT_APPLICABLE'))::text,
            '0',
            coalesce(((SELECT count(*)=0 FROM msbf_m2.portfolio_kpi_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND NOT applicable_flag AND kpi_value_text<>'NOT_APPLICABLE')),FALSE),
            'Nonapplicable KPIs are labeled explicitly.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_077_KPI_SOURCE_LINEAGE',
            'KPI_SOURCE_LINEAGE_ERRORS',
            ((SELECT count(*) FROM msbf_m2.portfolio_kpi_snapshot AS k LEFT JOIN msbf_m2.portfolio_performance_scope_summary AS s ON s.module1_run_id=k.module1_run_id AND s.scope_code=k.scope_code WHERE k.module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND (s.row_hash IS NULL OR k.source_scope_row_hash IS DISTINCT FROM s.row_hash)))::text,
            '0',
            coalesce(((SELECT count(*)=0 FROM msbf_m2.portfolio_kpi_snapshot AS k LEFT JOIN msbf_m2.portfolio_performance_scope_summary AS s ON s.module1_run_id=k.module1_run_id AND s.scope_code=k.scope_code WHERE k.module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND (s.row_hash IS NULL OR k.source_scope_row_hash IS DISTINCT FROM s.row_hash))),FALSE),
            'Every KPI retains scope lineage.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_078_KPI_PHYSICAL_HASH',
            'KPI_HASH_ERRORS',
            ((SELECT count(*) FROM msbf_m2.portfolio_kpi_snapshot AS k WHERE k.module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND k.row_hash IS DISTINCT FROM msbf_ctl.m2_10_hash_jsonb(to_jsonb(k)-'row_hash'-'created_at')))::text,
            '0',
            coalesce(((SELECT count(*)=0 FROM msbf_m2.portfolio_kpi_snapshot AS k WHERE k.module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND k.row_hash IS DISTINCT FROM msbf_ctl.m2_10_hash_jsonb(to_jsonb(k)-'row_hash'-'created_at'))),FALSE),
            'KPI hashes reconstruct physically.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_079_KPI_ACCOUNT_COUNT',
            'KPI_ACCOUNT_COUNT',
            ((SELECT kpi_value_numeric FROM msbf_m2.portfolio_kpi_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND scope_code='PORTFOLIO_ALL' AND kpi_code='ACCOUNT_COUNT'))::text,
            '59',
            coalesce(((SELECT kpi_value_numeric=59::numeric FROM msbf_m2.portfolio_kpi_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND scope_code='PORTFOLIO_ALL' AND kpi_code='ACCOUNT_COUNT')),FALSE),
            'Portfolio KPI ACCOUNT_COUNT is exact.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_080_KPI_CERTIFICATION_RATE',
            'KPI_CERTIFICATION_RATE',
            ((SELECT kpi_value_numeric FROM msbf_m2.portfolio_kpi_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND scope_code='PORTFOLIO_ALL' AND kpi_code='CERTIFICATION_RATE'))::text,
            '1.0000000000',
            coalesce(((SELECT kpi_value_numeric=1.0000000000::numeric FROM msbf_m2.portfolio_kpi_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND scope_code='PORTFOLIO_ALL' AND kpi_code='CERTIFICATION_RATE')),FALSE),
            'Portfolio KPI CERTIFICATION_RATE is exact.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_081_KPI_CERTIFIED_EXPOSURE',
            'KPI_CERTIFIED_EXPOSURE',
            ((SELECT kpi_value_numeric FROM msbf_m2.portfolio_kpi_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND scope_code='PORTFOLIO_ALL' AND kpi_code='CERTIFIED_EXPOSURE_AMOUNT'))::text,
            '785.4800000000',
            coalesce(((SELECT kpi_value_numeric=785.4800000000::numeric FROM msbf_m2.portfolio_kpi_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND scope_code='PORTFOLIO_ALL' AND kpi_code='CERTIFIED_EXPOSURE_AMOUNT')),FALSE),
            'Portfolio KPI CERTIFIED_EXPOSURE_AMOUNT is exact.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_082_KPI_COLLECTION_RATE',
            'KPI_COLLECTION_RATE',
            ((SELECT kpi_value_numeric FROM msbf_m2.portfolio_kpi_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND scope_code='PORTFOLIO_ALL' AND kpi_code='GROSS_COLLECTION_RATE'))::text,
            '1.0000000000',
            coalesce(((SELECT kpi_value_numeric=1.0000000000::numeric FROM msbf_m2.portfolio_kpi_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND scope_code='PORTFOLIO_ALL' AND kpi_code='GROSS_COLLECTION_RATE')),FALSE),
            'Portfolio KPI GROSS_COLLECTION_RATE is exact.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_083_KPI_RETURN_RATE',
            'KPI_RETURN_RATE',
            ((SELECT kpi_value_numeric FROM msbf_m2.portfolio_kpi_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND scope_code='PORTFOLIO_ALL' AND kpi_code='RETURN_RATE'))::text,
            '0.1428570000',
            coalesce(((SELECT kpi_value_numeric=0.1428570000::numeric FROM msbf_m2.portfolio_kpi_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND scope_code='PORTFOLIO_ALL' AND kpi_code='RETURN_RATE')),FALSE),
            'Portfolio KPI RETURN_RATE is exact.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_084_KPI_RETRY_CURE',
            'KPI_RETRY_CURE',
            ((SELECT kpi_value_numeric FROM msbf_m2.portfolio_kpi_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND scope_code='PORTFOLIO_ALL' AND kpi_code='RETRY_CURE_RATE'))::text,
            '1.0000000000',
            coalesce(((SELECT kpi_value_numeric=1.0000000000::numeric FROM msbf_m2.portfolio_kpi_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND scope_code='PORTFOLIO_ALL' AND kpi_code='RETRY_CURE_RATE')),FALSE),
            'Portfolio KPI RETRY_CURE_RATE is exact.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_085_KPI_BURDEN',
            'KPI_BURDEN',
            ((SELECT kpi_value_numeric FROM msbf_m2.portfolio_kpi_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND scope_code='PORTFOLIO_ALL' AND kpi_code='SERVICING_BURDEN_UNITS'))::text,
            '7.0000000000',
            coalesce(((SELECT kpi_value_numeric=7.0000000000::numeric FROM msbf_m2.portfolio_kpi_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND scope_code='PORTFOLIO_ALL' AND kpi_code='SERVICING_BURDEN_UNITS')),FALSE),
            'Portfolio KPI SERVICING_BURDEN_UNITS is exact.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_086_QUEUE_SUMMARY_COUNT',
            'QUEUE_SUMMARY_ROWS',
            ((SELECT count(*) FROM msbf_m2.servicing_queue_analytics_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx)))::text,
            '3',
            coalesce(((SELECT count(*)=3 FROM msbf_m2.servicing_queue_analytics_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx))),FALSE),
            'Three queue summaries exist.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_087_QUEUE_ACCOUNT_TOTAL',
            'QUEUE_ACCOUNT_TOTAL',
            ((SELECT sum(account_count) FROM msbf_m2.servicing_queue_analytics_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx)))::text,
            '59',
            coalesce(((SELECT sum(account_count)=59 FROM msbf_m2.servicing_queue_analytics_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx))),FALSE),
            'Queue accounts reconcile to 59.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_088_QUEUE_EXPOSURE_TOTAL',
            'QUEUE_EXPOSURE_TOTAL',
            ((SELECT round(sum(certified_exposure_amount),2) FROM msbf_m2.servicing_queue_analytics_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx)))::text,
            '785.48',
            coalesce(((SELECT round(sum(certified_exposure_amount),2)=785.48 FROM msbf_m2.servicing_queue_analytics_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx))),FALSE),
            'Queue exposure reconciles.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_089_QUEUE_BURDEN_TOTAL',
            'QUEUE_BURDEN_TOTAL',
            ((SELECT round(sum(servicing_burden_units),6) FROM msbf_m2.servicing_queue_analytics_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx)))::text,
            '7.000000',
            coalesce(((SELECT round(sum(servicing_burden_units),6)=7 FROM msbf_m2.servicing_queue_analytics_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx))),FALSE),
            'Queue burden reconciles.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_090_QUEUE_PHYSICAL_HASH',
            'QUEUE_HASH_ERRORS',
            ((SELECT count(*) FROM msbf_m2.servicing_queue_analytics_snapshot AS q WHERE q.module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND q.row_hash IS DISTINCT FROM msbf_ctl.m2_10_hash_jsonb(to_jsonb(q)-'row_hash'-'created_at')))::text,
            '0',
            coalesce(((SELECT count(*)=0 FROM msbf_m2.servicing_queue_analytics_snapshot AS q WHERE q.module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND q.row_hash IS DISTINCT FROM msbf_ctl.m2_10_hash_jsonb(to_jsonb(q)-'row_hash'-'created_at'))),FALSE),
            'Queue hashes reconstruct physically.'
        );
END;
$m2_10_positive_076_090$;

/* Controls 091–100 — bounded parser-safe execution block. */
DO $m2_10_positive_091_100$
BEGIN
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_091_LATEST_COUNT',
            'LATEST_ROWS',
            ((SELECT count(*) FROM msbf_m2.application_portfolio_performance_latest WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx)))::text,
            '59',
            coalesce(((SELECT count(*)=59 FROM msbf_m2.application_portfolio_performance_latest WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx))),FALSE),
            'Latest contract contains 59 rows.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_092_LATEST_GRAIN',
            'LATEST_GRAIN_DUPLICATES',
            ((SELECT count(*)-count(DISTINCT scenario_id::text||'|'||merchant_application_id) FROM msbf_m2.application_portfolio_performance_latest WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx)))::text,
            '0',
            coalesce(((SELECT count(*)=count(DISTINCT scenario_id::text||'|'||merchant_application_id) FROM msbf_m2.application_portfolio_performance_latest WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx))),FALSE),
            'Latest grain is unique.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_093_LATEST_IDENTITY',
            'LATEST_IDENTITY_ERRORS',
            ((SELECT count(*) FROM msbf_m2.application_portfolio_performance_latest WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND (contract_code<>'M2_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_CONSUMPTION' OR contract_version<>1 OR schema_version<>'M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_SCHEMA_V1' OR methodology_version<>'M2_10_METHOD_V1')))::text,
            '0',
            coalesce(((SELECT count(*)=0 FROM msbf_m2.application_portfolio_performance_latest WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND (contract_code<>'M2_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_CONSUMPTION' OR contract_version<>1 OR schema_version<>'M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_SCHEMA_V1' OR methodology_version<>'M2_10_METHOD_V1'))),FALSE),
            'Latest contract identity is exact.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_094_LATEST_LINEAGE',
            'LATEST_LINEAGE_ERRORS',
            ((SELECT count(*) FROM msbf_m2.application_portfolio_performance_latest AS l JOIN msbf_m2.application_portfolio_performance_snapshot AS p ON p.module1_run_id=l.module1_run_id AND p.scenario_id=l.scenario_id AND p.merchant_application_id=l.merchant_application_id WHERE l.module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND (l.performance_snapshot_row_hash IS DISTINCT FROM p.row_hash OR l.source_snapshot_row_hash IS DISTINCT FROM p.source_snapshot_row_hash OR l.source_contract_row_hash IS DISTINCT FROM p.source_contract_row_hash)))::text,
            '0',
            coalesce(((SELECT count(*)=0 FROM msbf_m2.application_portfolio_performance_latest AS l JOIN msbf_m2.application_portfolio_performance_snapshot AS p ON p.module1_run_id=l.module1_run_id AND p.scenario_id=l.scenario_id AND p.merchant_application_id=l.merchant_application_id WHERE l.module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND (l.performance_snapshot_row_hash IS DISTINCT FROM p.row_hash OR l.source_snapshot_row_hash IS DISTINCT FROM p.source_snapshot_row_hash OR l.source_contract_row_hash IS DISTINCT FROM p.source_contract_row_hash))),FALSE),
            'Latest preserves source and performance lineage.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_095_LATEST_PHYSICAL_HASH',
            'LATEST_HASH_ERRORS',
            ((SELECT count(*) FROM msbf_m2.application_portfolio_performance_latest AS l WHERE l.module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND l.contract_row_hash IS DISTINCT FROM msbf_ctl.m2_10_hash_jsonb(to_jsonb(l)-'contract_row_hash'-'created_at')))::text,
            '0',
            coalesce(((SELECT count(*)=0 FROM msbf_m2.application_portfolio_performance_latest AS l WHERE l.module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND l.contract_row_hash IS DISTINCT FROM msbf_ctl.m2_10_hash_jsonb(to_jsonb(l)-'contract_row_hash'-'created_at'))),FALSE),
            'Latest hashes reconstruct physically.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_096_ARCHIVE_COUNT',
            'ARCHIVE_ROWS',
            ((SELECT count(*) FROM msbf_m2.application_portfolio_performance_archive WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx)))::text,
            '59',
            coalesce(((SELECT count(*)=59 FROM msbf_m2.application_portfolio_performance_archive WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx))),FALSE),
            'Archive contains 59 rows.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_097_LATEST_ARCHIVE_REPRODUCTION',
            'LATEST_ARCHIVE_ERRORS',
            ((SELECT count(*) FROM msbf_m2.application_portfolio_performance_latest AS latest FULL OUTER JOIN msbf_m2.application_portfolio_performance_archive AS archive ON archive.module1_run_id=latest.module1_run_id AND archive.contract_version=latest.contract_version AND archive.scenario_id=latest.scenario_id AND archive.merchant_application_id=latest.merchant_application_id WHERE coalesce(latest.module1_run_id,archive.module1_run_id)=(SELECT run_id FROM _m2_10_vctx) AND (latest.contract_row_hash IS DISTINCT FROM archive.contract_row_hash OR archive.contract_payload IS DISTINCT FROM (to_jsonb(latest)-'created_at'))))::text,
            '0',
            coalesce(((SELECT count(*)=0 FROM msbf_m2.application_portfolio_performance_latest AS latest FULL OUTER JOIN msbf_m2.application_portfolio_performance_archive AS archive ON archive.module1_run_id=latest.module1_run_id AND archive.contract_version=latest.contract_version AND archive.scenario_id=latest.scenario_id AND archive.merchant_application_id=latest.merchant_application_id WHERE coalesce(latest.module1_run_id,archive.module1_run_id)=(SELECT run_id FROM _m2_10_vctx) AND (latest.contract_row_hash IS DISTINCT FROM archive.contract_row_hash OR archive.contract_payload IS DISTINCT FROM (to_jsonb(latest)-'created_at')))),FALSE),
            'Latest and archive reproduce exactly.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_098_ARCHIVE_PHYSICAL_HASH',
            'ARCHIVE_HASH_ERRORS',
            ((SELECT count(*) FROM msbf_m2.application_portfolio_performance_archive AS a WHERE a.module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND a.archive_row_hash IS DISTINCT FROM msbf_ctl.m2_10_hash_jsonb(to_jsonb(a)-'archive_id'-'archive_row_hash'-'archived_at'-'created_at')))::text,
            '0',
            coalesce(((SELECT count(*)=0 FROM msbf_m2.application_portfolio_performance_archive AS a WHERE a.module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND a.archive_row_hash IS DISTINCT FROM msbf_ctl.m2_10_hash_jsonb(to_jsonb(a)-'archive_id'-'archive_row_hash'-'archived_at'-'created_at'))),FALSE),
            'Archive hashes reconstruct physically.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_099_COMPARISON_COUNT',
            'COMPARISON_ROWS',
            ((SELECT count(*) FROM msbf_m2.v_m2_10_matched_scenario_comparison WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx)))::text,
            '15',
            coalesce(((SELECT count(*)=15 FROM msbf_m2.v_m2_10_matched_scenario_comparison WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx))),FALSE),
            'Matched comparison contains 15 applications.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_100_STRESS_NONIMPROVEMENT',
            'STRESS_IMPROVEMENT_ROWS',
            ((SELECT count(*) FROM msbf_m2.v_m2_10_matched_scenario_comparison WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND (stress_tier_improvement_flag OR stress_burden_improvement_flag OR stress_exposure_improvement_flag)))::text,
            '0',
            coalesce(((SELECT count(*)=0 FROM msbf_m2.v_m2_10_matched_scenario_comparison WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND (stress_tier_improvement_flag OR stress_burden_improvement_flag OR stress_exposure_improvement_flag))),FALSE),
            'Stress never appears better on tier, burden, or exposure.'
        );
END;
$m2_10_positive_091_100$;

/* Controls 101–120 — bounded parser-safe execution block. */
DO $m2_10_positive_101_120$
BEGIN
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_101_POLICY_SET_HASH',
            'POLICY_SET_HASH',
            ((SELECT policy_set_hash FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx)))::text,
            '32 lowercase hexadecimal characters',
            coalesce(((SELECT length(policy_set_hash)=32 AND policy_set_hash~'^[0-9a-f]+$' FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx))),FALSE),
            'Policy Set Hash has valid deterministic shape.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_102_KPI_DEFINITION_SET_HASH',
            'KPI_DEFINITION_SET_HASH',
            ((SELECT kpi_definition_set_hash FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx)))::text,
            '32 lowercase hexadecimal characters',
            coalesce(((SELECT length(kpi_definition_set_hash)=32 AND kpi_definition_set_hash~'^[0-9a-f]+$' FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx))),FALSE),
            'Kpi Definition Set Hash has valid deterministic shape.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_103_PERFORMANCE_TIER_SET_HASH',
            'PERFORMANCE_TIER_SET_HASH',
            ((SELECT performance_tier_set_hash FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx)))::text,
            '32 lowercase hexadecimal characters',
            coalesce(((SELECT length(performance_tier_set_hash)=32 AND performance_tier_set_hash~'^[0-9a-f]+$' FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx))),FALSE),
            'Performance Tier Set Hash has valid deterministic shape.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_104_SERVICING_QUEUE_SET_HASH',
            'SERVICING_QUEUE_SET_HASH',
            ((SELECT servicing_queue_set_hash FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx)))::text,
            '32 lowercase hexadecimal characters',
            coalesce(((SELECT length(servicing_queue_set_hash)=32 AND servicing_queue_set_hash~'^[0-9a-f]+$' FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx))),FALSE),
            'Servicing Queue Set Hash has valid deterministic shape.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_105_REASON_SET_HASH',
            'REASON_SET_HASH',
            ((SELECT reason_set_hash FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx)))::text,
            '32 lowercase hexadecimal characters',
            coalesce(((SELECT length(reason_set_hash)=32 AND reason_set_hash~'^[0-9a-f]+$' FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx))),FALSE),
            'Reason Set Hash has valid deterministic shape.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_106_SOURCE_SET_HASH',
            'SOURCE_SET_HASH',
            ((SELECT source_set_hash FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx)))::text,
            '32 lowercase hexadecimal characters',
            coalesce(((SELECT length(source_set_hash)=32 AND source_set_hash~'^[0-9a-f]+$' FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx))),FALSE),
            'Source Set Hash has valid deterministic shape.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_107_ACCOUNT_PERFORMANCE_SET_HASH',
            'ACCOUNT_PERFORMANCE_SET_HASH',
            ((SELECT account_performance_set_hash FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx)))::text,
            '32 lowercase hexadecimal characters',
            coalesce(((SELECT length(account_performance_set_hash)=32 AND account_performance_set_hash~'^[0-9a-f]+$' FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx))),FALSE),
            'Account Performance Set Hash has valid deterministic shape.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_108_SCOPE_SUMMARY_SET_HASH',
            'SCOPE_SUMMARY_SET_HASH',
            ((SELECT scope_summary_set_hash FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx)))::text,
            '32 lowercase hexadecimal characters',
            coalesce(((SELECT length(scope_summary_set_hash)=32 AND scope_summary_set_hash~'^[0-9a-f]+$' FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx))),FALSE),
            'Scope Summary Set Hash has valid deterministic shape.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_109_KPI_SNAPSHOT_SET_HASH',
            'KPI_SNAPSHOT_SET_HASH',
            ((SELECT kpi_snapshot_set_hash FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx)))::text,
            '32 lowercase hexadecimal characters',
            coalesce(((SELECT length(kpi_snapshot_set_hash)=32 AND kpi_snapshot_set_hash~'^[0-9a-f]+$' FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx))),FALSE),
            'Kpi Snapshot Set Hash has valid deterministic shape.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_110_QUEUE_SUMMARY_SET_HASH',
            'QUEUE_SUMMARY_SET_HASH',
            ((SELECT queue_summary_set_hash FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx)))::text,
            '32 lowercase hexadecimal characters',
            coalesce(((SELECT length(queue_summary_set_hash)=32 AND queue_summary_set_hash~'^[0-9a-f]+$' FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx))),FALSE),
            'Queue Summary Set Hash has valid deterministic shape.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_111_LATEST_SET_HASH',
            'LATEST_SET_HASH',
            ((SELECT latest_set_hash FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx)))::text,
            '32 lowercase hexadecimal characters',
            coalesce(((SELECT length(latest_set_hash)=32 AND latest_set_hash~'^[0-9a-f]+$' FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx))),FALSE),
            'Latest Set Hash has valid deterministic shape.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_112_ARCHIVE_SET_HASH',
            'ARCHIVE_SET_HASH',
            ((SELECT archive_set_hash FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx)))::text,
            '32 lowercase hexadecimal characters',
            coalesce(((SELECT length(archive_set_hash)=32 AND archive_set_hash~'^[0-9a-f]+$' FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx))),FALSE),
            'Archive Set Hash has valid deterministic shape.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_113_CONTRACT_SET_HASH',
            'CONTRACT_SET_HASH',
            ((SELECT contract_set_hash FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx)))::text,
            '32 lowercase hexadecimal characters',
            coalesce(((SELECT length(contract_set_hash)=32 AND contract_set_hash~'^[0-9a-f]+$' FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx))),FALSE),
            'Contract Set Hash has valid deterministic shape.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_114_COMBINED_SET_HASH',
            'COMBINED_SET_HASH',
            ((SELECT combined_set_hash FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx)))::text,
            '32 lowercase hexadecimal characters',
            coalesce(((SELECT length(combined_set_hash)=32 AND combined_set_hash~'^[0-9a-f]+$' FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx))),FALSE),
            'Combined Set Hash has valid deterministic shape.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_115_REGISTRY_HASH',
            'REGISTRY_HASH_ERRORS',
            ((SELECT count(*) FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry AS r WHERE r.module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND r.row_hash IS DISTINCT FROM msbf_ctl.m2_10_registry_row_hash(to_jsonb(r))))::text,
            '0',
            coalesce(((SELECT count(*)=0 FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry AS r WHERE r.module1_run_id=(SELECT run_id FROM _m2_10_vctx) AND r.row_hash IS DISTINCT FROM msbf_ctl.m2_10_registry_row_hash(to_jsonb(r)))),FALSE),
            'Registry row hash reconstructs physically.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_116_CANONICAL_IDENTITY',
            'CANONICAL_IDENTITY',
            ((SELECT canonical_entities||'|'||combined_set_hash FROM msbf_m2.v_m2_10_canonical_hash WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx)))::text,
            '370|registry combined hash',
            coalesce(((SELECT c.canonical_entities=370 AND c.combined_set_hash IS NOT DISTINCT FROM r.combined_set_hash FROM msbf_m2.v_m2_10_canonical_hash AS c JOIN msbf_ctl.m2_10_portfolio_analytics_contract_registry AS r ON r.module1_run_id=c.module1_run_id WHERE c.module1_run_id=(SELECT run_id FROM _m2_10_vctx))),FALSE),
            'Physical canonical identity reconciles.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_117_GENERATION_EVIDENCE',
            'GENERATION_EVIDENCE_ROWS',
            ((SELECT count(*) FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM _m2_10_vctx) AND evidence_code LIKE 'M2_10_%' AND evidence_code NOT LIKE 'M2_10_POS_%' AND evidence_code NOT LIKE 'M2_10_NEG_%' AND evidence_code<>'M2_10_ACCEPTANCE_SUMMARY'))::text,
            '24',
            coalesce(((SELECT count(*)=24 FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM _m2_10_vctx) AND evidence_code LIKE 'M2_10_%' AND evidence_code NOT LIKE 'M2_10_POS_%' AND evidence_code NOT LIKE 'M2_10_NEG_%' AND evidence_code<>'M2_10_ACCEPTANCE_SUMMARY')),FALSE),
            'Twenty-four generation-evidence rows exist.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_118_NO_FAILED_EVIDENCE',
            'FAILED_EVIDENCE_ROWS',
            ((SELECT count(*) FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM _m2_10_vctx) AND evidence_code LIKE 'M2_10_%' AND status='FAIL'))::text,
            '0',
            coalesce(((SELECT count(*)=0 FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM _m2_10_vctx) AND evidence_code LIKE 'M2_10_%' AND status='FAIL')),FALSE),
            'No M2.10 evidence is failed.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_119_NO_PREMATURE_M2_11',
            'PREMATURE_M2_11_TABLES',
            ((SELECT count(*) FROM information_schema.tables WHERE table_schema IN ('msbf_ctl','msbf_m2') AND lower(table_name) LIKE 'm2_11%'))::text,
            '0',
            coalesce(((SELECT count(*)=0 FROM information_schema.tables WHERE table_schema IN ('msbf_ctl','msbf_m2') AND lower(table_name) LIKE 'm2_11%')),FALSE),
            'No premature M2.11 objects exist.'
        );
    PERFORM pg_temp.m2_10_add_check
        (
            'M2_10_POS_120_ACCEPTANCE_NOT_WRITTEN',
            'ACCEPTANCE_ROWS',
            ((SELECT count(*) FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM _m2_10_vctx) AND gate_id='M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS'))::text,
            '0',
            coalesce(((SELECT count(*)=0 FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM _m2_10_vctx) AND gate_id='M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS')),FALSE),
            'Acceptance is not written before controls pass.'
        );
END;
$m2_10_positive_101_120$;

/* ============================================================================
Section 2 — Persist evidence and transition validated lifecycle
============================================================================ */
DO $m2_10_validation_finalize$
DECLARE
    v_total bigint;
    v_pass bigint;
    v_fail bigint;
    v_failed_detail text;
BEGIN
    SELECT
        count(*),
        count(*) FILTER(WHERE status='PASS'),
        count(*) FILTER(WHERE status='FAIL'),
        string_agg
        (
            evidence_code||'[observed='||coalesce(observed_value,'<NULL>')||
            '; threshold='||coalesce(threshold_value,'<NULL>')||']',
            '; ' ORDER BY evidence_code
        ) FILTER(WHERE status='FAIL')
    INTO v_total,v_pass,v_fail,v_failed_detail
    FROM _m2_10_validation;

    IF v_total<>120
    THEN
        RAISE EXCEPTION
            'M2.10 positive-control inventory failed: total %, expected 120.',
            v_total;
    END IF;

    INSERT INTO msbf_ctl.run_evidence
    (
        run_id,evidence_code,segment_key,metric_name,
        metric_value_numeric,metric_value_text,unit_code,status,
        interpretation
    )
    SELECT
        (SELECT run_id FROM _m2_10_vctx),
        evidence_code,'PORTFOLIO',metric_name,
        NULL::numeric(28,10),coalesce(observed_value,'<NULL>'),
        'VALIDATION',status,
        interpretation||' Threshold: '||
        coalesce(threshold_value,'<NULL>')
    FROM _m2_10_validation
    ON CONFLICT(run_id,evidence_code,segment_key)
    DO UPDATE SET
        metric_name=EXCLUDED.metric_name,
        metric_value_numeric=NULL,
        metric_value_text=EXCLUDED.metric_value_text,
        unit_code=EXCLUDED.unit_code,
        status=EXCLUDED.status,
        interpretation=EXCLUDED.interpretation,
        created_at=clock_timestamp();

    IF v_pass=120 AND v_fail=0
    THEN
        UPDATE msbf_ctl.run_registry
        SET run_status='M2_10_VALIDATED'
        WHERE run_id=(SELECT run_id FROM _m2_10_vctx);

        UPDATE msbf_ctl.m2_10_portfolio_analytics_contract_registry
        SET contract_status='VALIDATED',validated_at=clock_timestamp()
        WHERE module1_run_id=(SELECT run_id FROM _m2_10_vctx);
    ELSE
        RAISE EXCEPTION
            'M2.10 positive validation failed: pass %, fail %. Failed controls: %.',
            v_pass,v_fail,coalesce(v_failed_detail,'<NONE>');
    END IF;
END;
$m2_10_validation_finalize$;
COMMIT;
SELECT evidence_code,metric_name,observed_value,threshold_value,status,interpretation
FROM _m2_10_validation ORDER BY evidence_code;
