/* ============================================================================
MSBF M1.10 v0.2R2 — Failed Validation Syntax Recovery Check
Purpose : Confirm program 70 committed successfully, program 71 committed no
          validation evidence, and the persisted M1.10 generation remains fully
          reconciled before rerunning validation.
Execution: Read-only. Run after STOP + ROLLBACK of the failed R1 validation.
============================================================================ */
WITH r AS (
    SELECT run_id, run_status, population_id, as_of_date
    FROM msbf_ctl.run_registry
    WHERE run_code='M1_V0_2_BASELINE_BUILD'
      AND run_version=1
), actual AS (
    SELECT * FROM msbf_m1.m1_10_actual_obligation((SELECT run_id FROM r))
    UNION ALL
    SELECT * FROM msbf_m1.m1_10_actual_capacity((SELECT run_id FROM r))
), hashes AS (
    SELECT
        md5(
            string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)
            FILTER (WHERE entity_key LIKE 'OBLIGATION|%')
        ) AS obligation_hash,
        md5(
            string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)
            FILTER (WHERE entity_key LIKE 'CAPACITY|%')
        ) AS capacity_hash,
        md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) AS combined_hash,
        count(*) AS canonical_entities
    FROM actual
), stored AS (
    SELECT
        max(metric_value_text) FILTER (WHERE evidence_code='M1_10_OBLIGATION_SET_HASH') AS stored_obligation_hash,
        max(metric_value_text) FILTER (WHERE evidence_code='M1_10_CAPACITY_SET_HASH') AS stored_capacity_hash,
        max(metric_value_text) FILTER (WHERE evidence_code='M1_10_COMBINED_SET_HASH') AS stored_combined_hash,
        (max(metric_value_numeric) FILTER (WHERE evidence_code='M1_10_CANONICAL_ENTITY_COUNT'))::bigint AS stored_canonical_entities,
        (max(metric_value_numeric) FILTER (WHERE evidence_code='M1_10_CANONICAL_MISMATCH_COUNT'))::bigint AS stored_mismatches,
        count(*) FILTER (
            WHERE evidence_code IN (
                'M1_10_GENERATION_SPEC',
                'M1_10_OBLIGATION_ENTITY_COUNT',
                'M1_10_CAPACITY_ENTITY_COUNT',
                'M1_10_CANONICAL_ENTITY_COUNT',
                'M1_10_CANONICAL_MISMATCH_COUNT',
                'M1_10_OBLIGATION_SET_HASH',
                'M1_10_CAPACITY_SET_HASH',
                'M1_10_COMBINED_SET_HASH',
                'M1_10_GENERATION_SUMMARY'
            )
        ) AS generation_evidence_rows,
        count(*) FILTER (WHERE evidence_code LIKE 'M1_10_POS_%') AS positive_evidence_rows,
        count(*) FILTER (WHERE evidence_code LIKE 'M1_10_NEG_%') AS negative_evidence_rows
    FROM msbf_ctl.run_evidence
    WHERE run_id=(SELECT run_id FROM r)
), counts AS (
    SELECT
        (SELECT count(*) FROM msbf_m1.application_obligation_snapshot
          WHERE created_by_run_id=(SELECT run_id FROM r)) AS obligation_rows,
        (SELECT count(*) FROM msbf_m1.application_liquidity_capacity_snapshot
          WHERE module1_run_id=(SELECT run_id FROM r)) AS capacity_rows,
        (SELECT count(DISTINCT merchant_application_id)
           FROM msbf_m1.application_liquidity_capacity_snapshot
          WHERE module1_run_id=(SELECT run_id FROM r)) AS applications,
        (SELECT count(DISTINCT scenario_id)
           FROM msbf_m1.application_liquidity_capacity_snapshot
          WHERE module1_run_id=(SELECT run_id FROM r)) AS scenarios,
        (SELECT count(*) FROM msbf_ctl.acceptance_gate_result
          WHERE run_id=(SELECT run_id FROM r)
            AND gate_id='M1_10_OBLIGATIONS_LIQUIDITY_CAPACITY') AS gate_rows,
        (SELECT count(*) FROM msbf_ctl.profile_resolution_error
          WHERE run_id=(SELECT run_id FROM r)
            AND severity='BLOCKING') AS blocking_errors
)
SELECT
    clock_timestamp() AS execution_timestamp,
    current_database() AS database_name,
    current_user AS database_user,
    r.run_id,
    r.run_status,
    r.population_id,
    r.as_of_date,
    c.obligation_rows,
    c.capacity_rows,
    c.applications,
    c.scenarios,
    h.canonical_entities,
    s.stored_canonical_entities,
    s.stored_mismatches,
    s.generation_evidence_rows,
    s.positive_evidence_rows,
    s.negative_evidence_rows,
    c.gate_rows,
    c.blocking_errors,
    s.stored_obligation_hash,
    h.obligation_hash AS recomputed_obligation_hash,
    s.stored_capacity_hash,
    h.capacity_hash AS recomputed_capacity_hash,
    s.stored_combined_hash,
    h.combined_hash AS recomputed_combined_hash,
    CASE
      WHEN r.run_status='M1_10_GENERATED'
       AND c.obligation_rows > 0
       AND c.capacity_rows=1500
       AND c.applications=750
       AND c.scenarios=2
       AND h.canonical_entities=s.stored_canonical_entities
       AND s.stored_mismatches=0
       AND s.generation_evidence_rows=9
       AND s.positive_evidence_rows=0
       AND s.negative_evidence_rows=0
       AND c.gate_rows=0
       AND c.blocking_errors=0
       AND h.obligation_hash=s.stored_obligation_hash
       AND h.capacity_hash=s.stored_capacity_hash
       AND h.combined_hash=s.stored_combined_hash
      THEN 'PASS' ELSE 'FAIL'
    END AS recovery_state_status
FROM r
CROSS JOIN hashes h
CROSS JOIN stored s
CROSS JOIN counts c;
