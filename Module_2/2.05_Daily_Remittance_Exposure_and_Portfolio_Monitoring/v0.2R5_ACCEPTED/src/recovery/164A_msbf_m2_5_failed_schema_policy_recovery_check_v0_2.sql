/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.5 — Daily Remittance, Exposure & Portfolio Monitoring

Program     : 164A_msbf_m2_5_failed_schema_policy_recovery_check_v0_2.sql
Version     : v0.2

Purpose
-------
Read-only recovery check after a failed Program 164 schema/policy transaction.
Execute `ROLLBACK;` first. PostgreSQL DDL is transactional, so all M2.5
objects should be absent while the accepted M2.4 and M1.6 source boundaries
remain intact.

Required result
---------------
recovery_status = PASS.
============================================================================ */

WITH run_context AS
(
    SELECT
        run_id,
        run_status
    FROM msbf_ctl.run_registry
    WHERE run_code = 'M1_V0_2_BASELINE_BUILD'
      AND run_version = 1
),
source_m2_4 AS
(
    SELECT
        count(*)::bigint AS registry_rows,
        max(contract_status) AS contract_status,
        max(contract_code) AS contract_code,
        max(contract_version) AS contract_version,
        max(schema_version) AS schema_version,
        max(combined_set_hash) AS combined_set_hash
    FROM msbf_ctl.m2_4_portfolio_activation_contract_registry
    WHERE module1_run_id = (SELECT run_id FROM run_context)
),
source_m1_6 AS
(
    SELECT
        count(*)::bigint AS evidence_rows,
        max(metric_value_text) AS combined_set_hash
    FROM msbf_ctl.run_evidence
    WHERE run_id = (SELECT run_id FROM run_context)
      AND evidence_code = 'M1_6_COMBINED_SET_HASH'
      AND segment_key = 'PORTFOLIO'
      AND status = 'PASS'
),
gates AS
(
    SELECT
        count(*) FILTER
        (
            WHERE gate_id = 'M2_4_BOOKING_FUNDING_PORTFOLIO_ACTIVATION'
              AND result_status = 'PASS'
        )::bigint AS m2_4_gate_rows,
        count(*) FILTER
        (
            WHERE gate_id = 'M1_6_MATCHED_SCENARIO_OVERLAYS'
              AND result_status = 'PASS'
        )::bigint AS m1_6_gate_rows
    FROM msbf_ctl.acceptance_gate_result
    WHERE run_id = (SELECT run_id FROM run_context)
),
objects AS
(
    SELECT
        (to_regclass('msbf_ctl.m2_5_policy_profile') IS NOT NULL)::integer
            AS policy_table_exists,
        (to_regclass('msbf_m2.portfolio_monitoring_status_definition') IS NOT NULL)::integer
            AS status_table_exists,
        (to_regclass('msbf_m2.portfolio_monitoring_alert_definition') IS NOT NULL)::integer
            AS alert_table_exists,
        (to_regclass('msbf_m2.portfolio_monitoring_reason_definition') IS NOT NULL)::integer
            AS reason_table_exists,
        (to_regclass('msbf_m2.advance_monitoring_source_snapshot') IS NOT NULL)::integer
            AS source_table_exists,
        (to_regclass('msbf_m2.advance_daily_remittance_monitoring') IS NOT NULL)::integer
            AS daily_table_exists,
        (to_regclass('msbf_m2.advance_portfolio_monitoring_latest') IS NOT NULL)::integer
            AS latest_table_exists,
        (to_regclass('msbf_m2.advance_portfolio_monitoring_archive') IS NOT NULL)::integer
            AS archive_table_exists,
        (to_regclass('msbf_m2.portfolio_daily_monitoring_summary') IS NOT NULL)::integer
            AS portfolio_table_exists,
        (to_regclass('msbf_ctl.m2_5_portfolio_monitoring_contract_registry') IS NOT NULL)::integer
            AS registry_table_exists,
        (to_regclass('msbf_m2.v_m2_5_portfolio_monitoring_latest') IS NOT NULL)::integer
            AS latest_view_exists,
        (to_regclass('msbf_m2.v_m2_5_matched_monitoring_comparison') IS NOT NULL)::integer
            AS comparison_view_exists
),
rows_if_objects_exist AS
(
    SELECT
        CASE
            WHEN to_regclass('msbf_ctl.m2_5_policy_profile') IS NULL
            THEN 0::bigint
            ELSE
                (
                    SELECT count(*)
                    FROM msbf_ctl.m2_5_policy_profile
                    WHERE module1_run_id = (SELECT run_id FROM run_context)
                )
        END AS policy_rows,

        CASE
            WHEN to_regclass('msbf_ctl.m2_5_portfolio_monitoring_contract_registry') IS NULL
            THEN 0::bigint
            ELSE
                (
                    SELECT count(*)
                    FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry
                    WHERE module1_run_id = (SELECT run_id FROM run_context)
                )
        END AS registry_rows,

        (
            SELECT count(*)
            FROM msbf_ctl.run_evidence
            WHERE run_id = (SELECT run_id FROM run_context)
              AND evidence_code LIKE 'M2_5_%'
        )::bigint AS evidence_rows,

        (
            SELECT count(*)
            FROM msbf_ctl.acceptance_gate_result
            WHERE run_id = (SELECT run_id FROM run_context)
              AND gate_id = 'M2_5_DAILY_REMITTANCE_EXPOSURE_PORTFOLIO_MONITORING'
        )::bigint AS acceptance_rows,

        (
            SELECT count(*)
            FROM msbf_ref.acceptance_gate_catalog
            WHERE gate_id = 'M2_5_DAILY_REMITTANCE_EXPOSURE_PORTFOLIO_MONITORING'
        )::bigint AS gate_catalog_rows
)
SELECT
    run_context.run_status,
    source_m2_4.registry_rows AS source_m2_4_registry_rows,
    source_m2_4.contract_status AS source_m2_4_contract_status,
    source_m2_4.contract_code AS source_m2_4_contract_code,
    source_m2_4.contract_version AS source_m2_4_contract_version,
    source_m2_4.schema_version AS source_m2_4_schema_version,
    source_m2_4.combined_set_hash AS source_m2_4_combined_hash,
    source_m1_6.evidence_rows AS source_m1_6_evidence_rows,
    source_m1_6.combined_set_hash AS source_m1_6_combined_hash,
    gates.m2_4_gate_rows,
    gates.m1_6_gate_rows,
    objects.policy_table_exists,
    objects.status_table_exists,
    objects.alert_table_exists,
    objects.reason_table_exists,
    objects.source_table_exists,
    objects.daily_table_exists,
    objects.latest_table_exists,
    objects.archive_table_exists,
    objects.portfolio_table_exists,
    objects.registry_table_exists,
    objects.latest_view_exists,
    objects.comparison_view_exists,
    rows_if_objects_exist.policy_rows,
    rows_if_objects_exist.registry_rows,
    rows_if_objects_exist.evidence_rows,
    rows_if_objects_exist.acceptance_rows,
    rows_if_objects_exist.gate_catalog_rows,

    CASE
        WHEN run_context.run_status = 'M2_4_ACCEPTED'
         AND source_m2_4.registry_rows = 1
         AND source_m2_4.contract_status = 'ACCEPTED'
         AND source_m2_4.contract_code = 'M2_PORTFOLIO_ACTIVATION_CONSUMPTION'
         AND source_m2_4.contract_version = 1
         AND source_m2_4.schema_version = 'M2_4_PORTFOLIO_ACTIVATION_SCHEMA_V1'
         AND source_m2_4.combined_set_hash = '117450a3eea7bb3d3c74d18cc3c8e96a'
         AND source_m1_6.evidence_rows = 1
         AND length(source_m1_6.combined_set_hash) = 32
         AND source_m1_6.combined_set_hash ~ '^[0-9a-f]+$'
         AND gates.m2_4_gate_rows = 1
         AND gates.m1_6_gate_rows = 1
         AND objects.policy_table_exists = 0
         AND objects.status_table_exists = 0
         AND objects.alert_table_exists = 0
         AND objects.reason_table_exists = 0
         AND objects.source_table_exists = 0
         AND objects.daily_table_exists = 0
         AND objects.latest_table_exists = 0
         AND objects.archive_table_exists = 0
         AND objects.portfolio_table_exists = 0
         AND objects.registry_table_exists = 0
         AND objects.latest_view_exists = 0
         AND objects.comparison_view_exists = 0
         AND rows_if_objects_exist.policy_rows = 0
         AND rows_if_objects_exist.registry_rows = 0
         AND rows_if_objects_exist.evidence_rows = 0
         AND rows_if_objects_exist.acceptance_rows = 0
         AND rows_if_objects_exist.gate_catalog_rows = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END AS recovery_status

FROM run_context
CROSS JOIN source_m2_4
CROSS JOIN source_m1_6
CROSS JOIN gates
CROSS JOIN objects
CROSS JOIN rows_if_objects_exist;
