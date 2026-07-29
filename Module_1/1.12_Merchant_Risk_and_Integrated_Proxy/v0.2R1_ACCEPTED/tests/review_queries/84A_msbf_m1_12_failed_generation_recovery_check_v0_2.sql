/* ============================================================================
MSBF M1.12 — Failed-Generation Recovery-State Check
Version : v0.2
Purpose : Confirm that a cancelled or failed M1.12 generation transaction left
          the accepted M1.11 state intact and committed no M1.12 business rows,
          evidence, gate results, or downstream risk/loss outputs.
Mode    : Read-only. Run only after ROLLBACK following a failed program 86.
Required: recovery_state_status = PASS.
============================================================================ */

WITH r AS (
    SELECT run_id, run_status, population_id
    FROM msbf_ctl.run_registry
    WHERE run_code = 'M1_V0_2_BASELINE_BUILD'
      AND run_version = 1
),
counts AS (
    SELECT
        (SELECT count(*)
         FROM msbf_m1.application_integrated_risk_proxy_snapshot
         WHERE module1_run_id = (SELECT run_id FROM r)) AS snapshot_rows,
        (SELECT count(*)
         FROM msbf_m1.integrated_risk_component_value
         WHERE module1_run_id = (SELECT run_id FROM r)) AS component_rows,
        (SELECT count(*)
         FROM msbf_ctl.run_evidence
         WHERE run_id = (SELECT run_id FROM r)
           AND evidence_code LIKE 'M1_12_%') AS evidence_rows,
        (SELECT count(*)
         FROM msbf_ctl.acceptance_gate_result
         WHERE run_id = (SELECT run_id FROM r)
           AND gate_id = 'M1_12_INTEGRATED_RISK_PROXY') AS gate_rows,
        (SELECT count(*)
         FROM msbf_m1.merchant_risk_snapshot
         WHERE module1_run_id = (SELECT run_id FROM r)) AS legacy_risk_rows,
        (SELECT count(*)
         FROM msbf_m1.ead_path_snapshot
         WHERE module1_run_id = (SELECT run_id FROM r)) AS ead_rows,
        (SELECT count(*)
         FROM msbf_m1.module1_latest
         WHERE module1_run_id = (SELECT run_id FROM r)) AS latest_rows,
        (SELECT count(*)
         FROM msbf_m1.module1_archive
         WHERE module1_run_id = (SELECT run_id FROM r)) AS archive_rows,
        (SELECT count(*)
         FROM msbf_ctl.profile_resolution_error
         WHERE run_id = (SELECT run_id FROM r)
           AND severity = 'BLOCKING') AS blocking_errors
),
policy AS (
    SELECT
        status,
        profile_payload ->> 'methodology_version' AS methodology_version,
        profile_payload ->> 'composite_score_basis' AS composite_score_basis
    FROM msbf_ctl.policy_profile
    WHERE profile_code = 'M1_12_INTEGRATED_RISK_PROXY'
      AND profile_version = 1
),
hashes AS (
    SELECT
        (SELECT population_hash
         FROM msbf_m1.population_registry
         WHERE population_id = (SELECT population_id FROM r)) AS population_hash,
        (SELECT metric_value_text
         FROM msbf_ctl.run_evidence
         WHERE run_id = (SELECT run_id FROM r)
           AND evidence_code = 'M1_11_COMBINED_SET_HASH'
           AND segment_key = 'PORTFOLIO') AS resilience_hash
)
SELECT
    r.run_id,
    r.run_status,
    c.snapshot_rows,
    c.component_rows,
    c.evidence_rows,
    c.gate_rows,
    c.legacy_risk_rows,
    c.ead_rows,
    c.latest_rows,
    c.archive_rows,
    c.blocking_errors,
    p.status AS policy_status,
    p.methodology_version,
    p.composite_score_basis,
    h.population_hash,
    h.resilience_hash,
    to_regclass('msbf_m1.application_integrated_risk_proxy_snapshot') IS NOT NULL
        AS risk_snapshot_table_exists,
    to_regclass('msbf_m1.integrated_risk_component_value') IS NOT NULL
        AS risk_component_table_exists,
    CASE
        WHEN r.run_status = 'M1_11_ACCEPTED'
         AND c.snapshot_rows = 0
         AND c.component_rows = 0
         AND c.evidence_rows = 0
         AND c.gate_rows = 0
         AND c.legacy_risk_rows = 0
         AND c.ead_rows = 0
         AND c.latest_rows = 0
         AND c.archive_rows = 0
         AND c.blocking_errors = 0
         AND p.status = 'APPROVED'
         AND p.methodology_version = 'M1_12_METHOD_V1'
         AND p.composite_score_basis = 'SUM_PERSISTED_WEIGHTED_RISK_COMPONENTS'
         AND h.population_hash = '9b706c926260a3ef1ae8ac95eed5d0bf'
         AND h.resilience_hash = 'd219b2a0cb6d32f400b1ab71be6521fb'
         AND to_regclass('msbf_m1.application_integrated_risk_proxy_snapshot') IS NOT NULL
         AND to_regclass('msbf_m1.integrated_risk_component_value') IS NOT NULL
        THEN 'PASS'
        ELSE 'FAIL'
    END AS recovery_state_status
FROM r
CROSS JOIN counts c
CROSS JOIN policy p
CROSS JOIN hashes h;
