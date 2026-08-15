/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.10 — Portfolio Performance, KPI & Servicing Analytics

Program     : 207B_msbf_m2_10_definition_hash_diagnostic_v0_2R3.sql
Version     : v0.2R3

Purpose
-------
Run after stopping failed Program 207 and executing ROLLBACK. Identify the
four family-level physical dictionary-hash failures produced when Program 204
hashed seed records whose temporary aliases did not match the persisted table
column names.

Writes
------
None.

Required result
---------------
diagnostic_status = PASS, with physical mismatch counts 24 / 3 / 3 / 24 and
no partial validation, negative-control, or acceptance evidence.
============================================================================ */

SET statement_timeout='20min';
SET jit=off;

WITH run_context AS
(
    SELECT run_id,run_status
    FROM msbf_ctl.run_registry
    WHERE run_code='M1_V0_2_BASELINE_BUILD'
      AND run_version=1
),
registry AS
(
    SELECT contract_status,canonical_entities,combined_set_hash
    FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry
    WHERE module1_run_id=(SELECT run_id FROM run_context)
),
hash_state AS
(
    SELECT
        (
            SELECT count(*)
            FROM msbf_m2.portfolio_kpi_definition AS definition
            WHERE definition.module1_run_id=(SELECT run_id FROM run_context)
              AND definition.row_hash IS DISTINCT FROM
                  msbf_ctl.m2_10_hash_jsonb
                  (to_jsonb(definition)-'row_hash'-'created_at')
        )::bigint AS kpi_physical_hash_mismatches,
        (
            SELECT count(*)
            FROM msbf_m2.portfolio_performance_tier_definition AS definition
            WHERE definition.module1_run_id=(SELECT run_id FROM run_context)
              AND definition.row_hash IS DISTINCT FROM
                  msbf_ctl.m2_10_hash_jsonb
                  (to_jsonb(definition)-'row_hash'-'created_at')
        )::bigint AS tier_physical_hash_mismatches,
        (
            SELECT count(*)
            FROM msbf_m2.servicing_queue_definition AS definition
            WHERE definition.module1_run_id=(SELECT run_id FROM run_context)
              AND definition.row_hash IS DISTINCT FROM
                  msbf_ctl.m2_10_hash_jsonb
                  (to_jsonb(definition)-'row_hash'-'created_at')
        )::bigint AS queue_physical_hash_mismatches,
        (
            SELECT count(*)
            FROM msbf_m2.portfolio_analytics_reason_definition AS definition
            WHERE definition.module1_run_id=(SELECT run_id FROM run_context)
              AND definition.row_hash IS DISTINCT FROM
                  msbf_ctl.m2_10_hash_jsonb
                  (to_jsonb(definition)-'row_hash'-'created_at')
        )::bigint AS reason_physical_hash_mismatches
),
evidence_state AS
(
    SELECT
        count(*) FILTER(WHERE evidence_code LIKE 'M2_10_POS_%')::bigint
            AS positive_evidence_rows,
        count(*) FILTER(WHERE evidence_code LIKE 'M2_10_NEG_%')::bigint
            AS negative_evidence_rows,
        count(*) FILTER
        (
            WHERE evidence_code LIKE 'M2_10_%'
              AND evidence_code NOT LIKE 'M2_10_POS_%'
              AND evidence_code NOT LIKE 'M2_10_NEG_%'
              AND evidence_code<>'M2_10_ACCEPTANCE_SUMMARY'
        )::bigint AS generation_evidence_rows,
        count(*) FILTER
        (WHERE evidence_code='M2_10_ACCEPTANCE_SUMMARY')::bigint
            AS acceptance_evidence_rows
    FROM msbf_ctl.run_evidence
    WHERE run_id=(SELECT run_id FROM run_context)
),
gate_state AS
(
    SELECT count(*)::bigint AS acceptance_gate_rows
    FROM msbf_ctl.acceptance_gate_result
    WHERE run_id=(SELECT run_id FROM run_context)
      AND gate_id='M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS'
),
canonical AS
(
    SELECT canonical_entities,combined_set_hash
    FROM msbf_m2.v_m2_10_canonical_hash
    WHERE module1_run_id=(SELECT run_id FROM run_context)
)
SELECT
    run_context.run_status,
    registry.contract_status,
    registry.canonical_entities AS registry_canonical_entities,
    canonical.canonical_entities AS physical_canonical_entities,
    registry.combined_set_hash AS registry_combined_set_hash,
    canonical.combined_set_hash AS physical_combined_set_hash,
    hash_state.*,
    evidence_state.*,
    gate_state.acceptance_gate_rows,
    'M2_10_POS_025_KPI_HASH; M2_10_POS_026_TIER_HASH; '
    'M2_10_POS_027_QUEUE_HASH; M2_10_POS_028_REASON_HASH'
        AS identified_failed_controls,
    CASE
        WHEN run_context.run_status='M2_10_GENERATED'
         AND registry.contract_status='GENERATED'
         AND registry.canonical_entities=370
         AND canonical.canonical_entities=370
         AND registry.combined_set_hash IS NOT DISTINCT FROM
             canonical.combined_set_hash
         AND hash_state.kpi_physical_hash_mismatches=24
         AND hash_state.tier_physical_hash_mismatches=3
         AND hash_state.queue_physical_hash_mismatches=3
         AND hash_state.reason_physical_hash_mismatches=24
         AND evidence_state.positive_evidence_rows=0
         AND evidence_state.negative_evidence_rows=0
         AND evidence_state.generation_evidence_rows=24
         AND evidence_state.acceptance_evidence_rows=0
         AND gate_state.acceptance_gate_rows=0
        THEN 'PASS'
        ELSE 'FAIL'
    END AS diagnostic_status
FROM run_context
CROSS JOIN registry
CROSS JOIN hash_state
CROSS JOIN evidence_state
CROSS JOIN gate_state
CROSS JOIN canonical;
