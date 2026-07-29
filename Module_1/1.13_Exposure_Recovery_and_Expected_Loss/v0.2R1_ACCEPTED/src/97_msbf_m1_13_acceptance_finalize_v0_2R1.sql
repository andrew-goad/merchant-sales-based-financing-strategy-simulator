/* ============================================================================
M1.13 v0.2R1 BOOLEAN-PARAMETER AGGREGATION HOTFIX
Source  : 97_msbf_m1_13_acceptance_finalize_v0_2.sql
Role    : Acceptance finalizer; executable logic unchanged from v0.2.
Revision: File name is version-aligned to v0.2R1. Except where explicitly
          documented in HOTFIX_NOTES_v0_2R1.md, executable logic is unchanged.
============================================================================ */

/* ============================================================================
MSBF M1.13 Exposure, Recovery & Expected Loss Foundations — Acceptance Finalizer
Version : v0.2
Purpose : Reconcile the final positive/negative controls, daily exposure-path
          population, recovery/LGD identities, comparative loss identities,
          matched stress floors, deterministic hashes, policy settings, and
          downstream stage boundaries before formal acceptance.
Mode    : Writes the formal gate result, acceptance summary, and final run
          status. No business evidence is recalculated or modified.
Output  : One filterable acceptance row preserved after COMMIT.
============================================================================ */

BEGIN;
SET LOCAL work_mem = '128MB';
SET LOCAL jit = off;
SET LOCAL statement_timeout = '20min';

DROP TABLE IF EXISTS _m1_13_acceptance;
CREATE TEMP TABLE _m1_13_acceptance
ON COMMIT PRESERVE ROWS AS
WITH r AS (
    SELECT run_id, run_status, population_id, as_of_date
    FROM msbf_ctl.run_registry
    WHERE run_code = 'M1_V0_2_BASELINE_BUILD'
      AND run_version = 1
), pos AS (
    SELECT
        count(*) AS checks,
        count(*) FILTER (WHERE status='PASS') AS passes,
        count(*) FILTER (WHERE status='FAIL') AS failures
    FROM msbf_ctl.run_evidence
    WHERE run_id = (SELECT run_id FROM r)
      AND evidence_code LIKE 'M1_13_POS_%'
), neg AS (
    SELECT
        count(*) AS controls,
        count(*) FILTER (WHERE status='PASS') AS passes,
        count(*) FILTER (WHERE status='FAIL') AS failures
    FROM msbf_ctl.run_evidence
    WHERE run_id = (SELECT run_id FROM r)
      AND evidence_code LIKE 'M1_13_NEG_%'
), policy AS (
    SELECT profile_payload
    FROM msbf_ctl.policy_profile
    WHERE profile_code = 'M1_13_EXPOSURE_RECOVERY_LOSS_FOUNDATIONS'
      AND profile_version = 1
      AND status = 'APPROVED'
), rows AS (
    SELECT
        (SELECT count(*)
         FROM msbf_m1.application_ead_path_value
         WHERE module1_run_id=(SELECT run_id FROM r)) AS path_rows,
        (SELECT count(*)
         FROM msbf_m1.application_exposure_recovery_loss_snapshot
         WHERE module1_run_id=(SELECT run_id FROM r)) AS snapshots,
        (SELECT count(DISTINCT merchant_application_id)
         FROM msbf_m1.application_exposure_recovery_loss_snapshot
         WHERE module1_run_id=(SELECT run_id FROM r)) AS applications,
        (SELECT count(DISTINCT scenario_id)
         FROM msbf_m1.application_exposure_recovery_loss_snapshot
         WHERE module1_run_id=(SELECT run_id FROM r)) AS scenarios,
        (SELECT sum(requested_expected_payoff_days+1)::bigint*2
         FROM msbf_m1.merchant_application
         WHERE created_by_run_id=(SELECT run_id FROM r)) AS expected_path_rows,
        (SELECT count(*)
         FROM msbf_m1.application_ead_path_value p
         WHERE p.module1_run_id=(SELECT run_id FROM r)
           AND p.path_hash <> msbf_m1.m1_13_hash_jsonb(
               to_jsonb(p) - 'path_hash' - 'created_at'
           )) AS path_hash_mismatches,
        (SELECT count(*)
         FROM msbf_m1.application_exposure_recovery_loss_snapshot l
         WHERE l.module1_run_id=(SELECT run_id FROM r)
           AND l.row_hash <> msbf_m1.m1_13_hash_jsonb(
               to_jsonb(l) - 'row_hash' - 'created_at'
           )) AS snapshot_hash_mismatches,
        (SELECT count(*)
         FROM msbf_m1.application_ead_path_value
         WHERE module1_run_id=(SELECT run_id FROM r)
           AND (beginning_exposure_amount < 0
             OR ending_exposure_amount < 0
             OR weighted_ead_amount < 0)) AS negative_path_values,
        (SELECT count(*)
         FROM msbf_m1.application_exposure_recovery_loss_snapshot
         WHERE module1_run_id=(SELECT run_id FROM r)
           AND expected_ead_rate IS DISTINCT FROM round(
               path_weighted_ead_amount / initial_receivable_exposure_amount,
               8
           )::numeric(12,8)) AS ead_rate_identity_violations,
        (SELECT count(*)
         FROM msbf_m1.application_exposure_recovery_loss_snapshot
         WHERE module1_run_id=(SELECT run_id FROM r)
           AND recovery_rate_assumption IS DISTINCT FROM
               (1.0-lgd_input_rate)::numeric(12,8)) AS recovery_identity_violations,
        (SELECT count(*)
         FROM msbf_m1.application_exposure_recovery_loss_snapshot
         WHERE module1_run_id=(SELECT run_id FROM r)
           AND synthetic_merchant_risk_proxy IS NOT NULL
           AND simple_comparative_expected_loss_amount IS DISTINCT FROM
               round(initial_receivable_exposure_amount
                   * synthetic_merchant_risk_proxy
                   * lgd_input_rate,2)::numeric(18,2)) AS simple_loss_identity_violations,
        (SELECT count(*)
         FROM msbf_m1.application_exposure_recovery_loss_snapshot
         WHERE module1_run_id=(SELECT run_id FROM r)
           AND synthetic_merchant_risk_proxy IS NOT NULL
           AND schedule_adjusted_comparative_expected_loss_amount IS DISTINCT FROM
               round(path_weighted_ead_amount
                   * synthetic_merchant_risk_proxy
                   * lgd_input_rate,2)::numeric(18,2)) AS schedule_loss_identity_violations,
        (SELECT count(*)
         FROM msbf_m1.application_exposure_recovery_loss_snapshot l
         JOIN msbf_ctl.scenario_registry sr USING(scenario_id)
         JOIN (
             SELECT merchant_application_id,
                    path_weighted_ead_amount AS baseline_value
             FROM msbf_m1.application_exposure_recovery_loss_snapshot b
             JOIN msbf_ctl.scenario_registry srb USING(scenario_id)
             WHERE b.module1_run_id=(SELECT run_id FROM r)
               AND srb.scenario_code='BASELINE'
         ) b USING(merchant_application_id)
         WHERE l.module1_run_id=(SELECT run_id FROM r)
           AND sr.scenario_code='RECESSION_ENERGY'
           AND l.path_weighted_ead_amount < b.baseline_value) AS stress_ead_improvements,
        (SELECT count(*)
         FROM msbf_m1.application_exposure_recovery_loss_snapshot l
         JOIN msbf_ctl.scenario_registry sr USING(scenario_id)
         JOIN (
             SELECT merchant_application_id, lgd_input_rate AS baseline_value
             FROM msbf_m1.application_exposure_recovery_loss_snapshot b
             JOIN msbf_ctl.scenario_registry srb USING(scenario_id)
             WHERE b.module1_run_id=(SELECT run_id FROM r)
               AND srb.scenario_code='BASELINE'
         ) b USING(merchant_application_id)
         WHERE l.module1_run_id=(SELECT run_id FROM r)
           AND sr.scenario_code='RECESSION_ENERGY'
           AND l.lgd_input_rate < b.baseline_value) AS stress_lgd_improvements,
        (SELECT count(*)
         FROM msbf_m1.application_exposure_recovery_loss_snapshot l
         JOIN msbf_ctl.scenario_registry sr USING(scenario_id)
         JOIN (
             SELECT merchant_application_id,
                    schedule_adjusted_comparative_expected_loss_amount AS baseline_value
             FROM msbf_m1.application_exposure_recovery_loss_snapshot b
             JOIN msbf_ctl.scenario_registry srb USING(scenario_id)
             WHERE b.module1_run_id=(SELECT run_id FROM r)
               AND srb.scenario_code='BASELINE'
         ) b USING(merchant_application_id)
         WHERE l.module1_run_id=(SELECT run_id FROM r)
           AND sr.scenario_code='RECESSION_ENERGY'
           AND l.schedule_adjusted_comparative_expected_loss_amount < b.baseline_value) AS stress_loss_improvements,
        (SELECT count(*)
         FROM msbf_m1.merchant_risk_snapshot
         WHERE module1_run_id=(SELECT run_id FROM r))
      + (SELECT count(*)
         FROM msbf_m1.risk_component_detail
         WHERE module1_run_id=(SELECT run_id FROM r))
      + (SELECT count(*)
         FROM msbf_m1.ead_path_snapshot
         WHERE module1_run_id=(SELECT run_id FROM r))
      + (SELECT count(*)
         FROM msbf_m1.module1_latest
         WHERE module1_run_id=(SELECT run_id FROM r))
      + (SELECT count(*)
         FROM msbf_m1.module1_archive
         WHERE module1_run_id=(SELECT run_id FROM r)) AS downstream_rows,
        (SELECT count(*)
         FROM msbf_ctl.profile_resolution_error
         WHERE run_id=(SELECT run_id FROM r)
           AND severity='BLOCKING') AS blocking_errors
), actual AS (
    SELECT * FROM msbf_m1.m1_13_actual_path_snapshot((SELECT run_id FROM r))
    UNION ALL
    SELECT * FROM msbf_m1.m1_13_actual_loss_snapshot((SELECT run_id FROM r))
), hashes AS (
    SELECT
        count(*) AS canonical_entities,
        (SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key))
         FROM actual WHERE entity_key LIKE 'PATH|%') AS path_hash,
        (SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key))
         FROM actual WHERE entity_key LIKE 'LOSS|%') AS snapshot_hash,
        md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) AS combined_hash
    FROM actual
), stored AS (
    SELECT
        max(metric_value_text) FILTER (WHERE evidence_code='M1_13_PATH_SET_HASH') AS stored_path_hash,
        max(metric_value_text) FILTER (WHERE evidence_code='M1_13_SNAPSHOT_SET_HASH') AS stored_snapshot_hash,
        max(metric_value_text) FILTER (WHERE evidence_code='M1_13_COMBINED_SET_HASH') AS stored_combined_hash,
        (max(metric_value_numeric) FILTER (WHERE evidence_code='M1_13_CANONICAL_MISMATCH_COUNT'))::bigint AS stored_mismatches
    FROM msbf_ctl.run_evidence
    WHERE run_id=(SELECT run_id FROM r)
)
SELECT
    r.run_id,
    r.run_status,
    pos.checks AS positive_checks,
    pos.passes AS positive_passes,
    pos.failures AS positive_failures,
    neg.controls AS negative_controls,
    neg.passes AS negative_passes,
    neg.failures AS negative_failures,
    rows.*,
    hashes.*,
    stored.*,
    policy.profile_payload->>'methodology_version' AS methodology_version,
    policy.profile_payload->>'exposure_basis_code' AS exposure_basis_code,
    policy.profile_payload->>'ead_method_code' AS ead_method_code,
    policy.profile_payload->>'default_timing_basis_code' AS default_timing_basis_code,
    policy.profile_payload->>'risk_proxy_basis_code' AS risk_proxy_basis_code,
    (policy.profile_payload->>'stress_ead_floor_to_baseline')::boolean AS ead_floor_enabled,
    (policy.profile_payload->>'stress_lgd_floor_to_baseline')::boolean AS lgd_floor_enabled,
    (policy.profile_payload->>'stress_loss_floor_to_baseline')::boolean AS loss_floor_enabled,
    CASE
        WHEN r.run_status='M1_13_VALIDATED'
         AND pos.checks=82 AND pos.passes=82 AND pos.failures=0
         AND neg.controls=7 AND neg.passes=7 AND neg.failures=0
         AND rows.snapshots=1500
         AND rows.applications=750
         AND rows.scenarios=2
         AND rows.path_rows=rows.expected_path_rows
         AND rows.path_hash_mismatches=0
         AND rows.snapshot_hash_mismatches=0
         AND rows.negative_path_values=0
         AND rows.ead_rate_identity_violations=0
         AND rows.recovery_identity_violations=0
         AND rows.simple_loss_identity_violations=0
         AND rows.schedule_loss_identity_violations=0
         AND rows.stress_ead_improvements=0
         AND rows.stress_lgd_improvements=0
         AND rows.stress_loss_improvements=0
         AND rows.downstream_rows=0
         AND rows.blocking_errors=0
         AND hashes.canonical_entities=rows.path_rows+rows.snapshots
         AND stored.stored_mismatches=0
         AND hashes.path_hash=stored.stored_path_hash
         AND hashes.snapshot_hash=stored.stored_snapshot_hash
         AND hashes.combined_hash=stored.stored_combined_hash
         AND policy.profile_payload->>'methodology_version'='M1_13_METHOD_V1'
         AND policy.profile_payload->>'exposure_basis_code'='CONTRACTUAL_RECEIVABLE'
         AND policy.profile_payload->>'ead_method_code'='WEIGHTED_DAILY_BALANCE'
         AND policy.profile_payload->>'default_timing_basis_code'='EARLY_MIDDLE_LATE'
         AND policy.profile_payload->>'risk_proxy_basis_code'='SYNTHETIC_MERCHANT_RISK_PROXY'
         AND (policy.profile_payload->>'stress_ead_floor_to_baseline')::boolean
         AND (policy.profile_payload->>'stress_lgd_floor_to_baseline')::boolean
         AND (policy.profile_payload->>'stress_loss_floor_to_baseline')::boolean
        THEN 'PASS'
        ELSE 'FAIL'
    END AS acceptance_status
FROM r
CROSS JOIN pos
CROSS JOIN neg
CROSS JOIN rows
CROSS JOIN hashes
CROSS JOIN stored
CROSS JOIN policy;

INSERT INTO msbf_ctl.acceptance_gate_result (
    run_id, gate_id, review_version, result_status,
    observed_value, threshold_value, finding, residual_limitation,
    reviewer_role, reviewed_at
)
SELECT
    a.run_id,
    'M1_13_EXPOSURE_RECOVERY_LOSS_FOUNDATIONS',
    coalesce((
        SELECT max(review_version)+1
        FROM msbf_ctl.acceptance_gate_result
        WHERE run_id=a.run_id
          AND gate_id='M1_13_EXPOSURE_RECOVERY_LOSS_FOUNDATIONS'
    ),1),
    a.acceptance_status,
    format(
        'positive=%s/%s|negative=%s/%s|paths=%s|snapshots=%s|canonical=%s|mismatches=%s|ead_improvements=%s|lgd_improvements=%s|loss_improvements=%s',
        a.positive_passes,a.positive_checks,
        a.negative_passes,a.negative_controls,
        a.path_rows,a.snapshots,a.canonical_entities,a.stored_mismatches,
        a.stress_ead_improvements,a.stress_lgd_improvements,a.stress_loss_improvements
    ),
    '82/82 positive; 7/7 negative; complete path population; 1,500 snapshots; zero mismatches; zero adverse-scenario improvements',
    CASE
        WHEN a.acceptance_status='PASS'
            THEN 'M1.13 scenario-aware exposure, recovery/LGD, and comparative expected-loss foundations accepted.'
        ELSE 'M1.13 acceptance requirements were not fully satisfied.'
    END,
    'Synthetic comparative foundations only; not calibrated PD/EAD/LGD, CECL, reserve, capital, pricing, adverse action, or production underwriting.',
    'Independent Validation',
    clock_timestamp()
FROM _m1_13_acceptance a;

INSERT INTO msbf_ctl.run_evidence (
    run_id,evidence_code,segment_key,metric_name,
    metric_value_text,unit_code,status,interpretation
)
SELECT
    run_id,
    'M1_13_ACCEPTANCE_SUMMARY',
    'PORTFOLIO',
    'M1.13 acceptance summary',
    format(
        'positive=%s/%s|negative=%s/%s|paths=%s|snapshots=%s|hash=%s',
        positive_passes,positive_checks,
        negative_passes,negative_controls,
        path_rows,snapshots,combined_hash
    ),
    'TEXT',
    acceptance_status,
    'Formal M1.13 acceptance summary.'
FROM _m1_13_acceptance
ON CONFLICT (run_id,evidence_code,segment_key) DO UPDATE SET
    metric_name=EXCLUDED.metric_name,
    metric_value_text=EXCLUDED.metric_value_text,
    metric_value_numeric=NULL,
    unit_code=EXCLUDED.unit_code,
    status=EXCLUDED.status,
    interpretation=EXCLUDED.interpretation,
    created_at=clock_timestamp();

UPDATE msbf_ctl.run_registry r
SET run_status=CASE
        WHEN a.acceptance_status='PASS' THEN 'M1_13_ACCEPTED'
        ELSE 'M1_13_FAILED'
    END,
    completed_at=CASE
        WHEN a.acceptance_status='PASS' THEN clock_timestamp()
        ELSE r.completed_at
    END,
    notes=coalesce(r.notes,'') || E'\nM1.13 v0.2 acceptance: ' || a.acceptance_status || '.'
FROM _m1_13_acceptance a
WHERE r.run_id=a.run_id;

COMMIT;

SELECT
    a.*,
    r.run_status AS final_run_status,
    g.review_version,
    g.result_status AS gate_status
FROM _m1_13_acceptance a
JOIN msbf_ctl.run_registry r USING(run_id)
JOIN LATERAL (
    SELECT *
    FROM msbf_ctl.acceptance_gate_result x
    WHERE x.run_id=a.run_id
      AND x.gate_id='M1_13_EXPOSURE_RECOVERY_LOSS_FOUNDATIONS'
    ORDER BY review_version DESC
    LIMIT 1
) g ON true;
