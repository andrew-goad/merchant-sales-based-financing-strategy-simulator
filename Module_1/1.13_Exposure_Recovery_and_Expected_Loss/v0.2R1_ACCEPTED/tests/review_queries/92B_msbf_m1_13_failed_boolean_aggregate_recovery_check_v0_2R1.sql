/* ============================================================================
MSBF M1.13 — Failed Boolean-Aggregate Generation Recovery Check
Version : v0.2R1
Purpose : Confirm that the failed v0.2 program-94 transaction committed no
          M1.13 business rows, evidence, gate results, or run-state changes;
          confirm the committed schema/policy extension and governed Boolean
          parameter rows remain valid before corrected generation.
Use     : Execute only after clicking Stop and issuing ROLLBACK in the failed
          DBeaver session.
Mode    : Read-only and fail-closed.
Required: recovery_state_status = PASS.
============================================================================ */

WITH run_context AS (
    SELECT run_id, run_status
    FROM msbf_ctl.run_registry
    WHERE run_code = 'M1_V0_2_BASELINE_BUILD'
      AND run_version = 1
),
boolean_parameters AS (
    SELECT
        count(*) FILTER (
            WHERE parameter_name = 'simple_el_publish_flag'
              AND scope_key = 'GLOBAL'
        ) AS simple_flag_rows,
        count(*) FILTER (
            WHERE parameter_name = 'schedule_adjusted_el_publish_flag'
              AND scope_key = 'GLOBAL'
        ) AS schedule_flag_rows,
        bool_or((resolved_value ->> 'value_boolean')::boolean) FILTER (
            WHERE parameter_name = 'simple_el_publish_flag'
              AND scope_key = 'GLOBAL'
        ) AS simple_el_publish_flag,
        bool_or((resolved_value ->> 'value_boolean')::boolean) FILTER (
            WHERE parameter_name = 'schedule_adjusted_el_publish_flag'
              AND scope_key = 'GLOBAL'
        ) AS schedule_adjusted_el_publish_flag
    FROM msbf_ctl.run_parameter_snapshot
    WHERE run_id = (SELECT run_id FROM run_context)
),
state AS (
    SELECT
        r.run_id,
        r.run_status,
        (SELECT count(*)
         FROM msbf_m1.application_ead_path_value
         WHERE module1_run_id = r.run_id) AS path_rows,
        (SELECT count(*)
         FROM msbf_m1.application_exposure_recovery_loss_snapshot
         WHERE module1_run_id = r.run_id) AS snapshot_rows,
        (SELECT count(*)
         FROM msbf_ctl.run_evidence
         WHERE run_id = r.run_id
           AND evidence_code LIKE 'M1_13_%') AS evidence_rows,
        (SELECT count(*)
         FROM msbf_ctl.acceptance_gate_result
         WHERE run_id = r.run_id
           AND gate_id = 'M1_13_EXPOSURE_RECOVERY_LOSS_FOUNDATIONS') AS gate_rows,
        (SELECT count(*)
         FROM msbf_ctl.profile_resolution_error
         WHERE run_id = r.run_id
           AND severity = 'BLOCKING') AS blocking_errors,
        to_regclass('msbf_m1.application_ead_path_value') IS NOT NULL
            AS path_table_exists,
        to_regclass('msbf_m1.application_exposure_recovery_loss_snapshot') IS NOT NULL
            AS snapshot_table_exists,
        (
            SELECT count(*) = 1
            FROM msbf_ctl.policy_profile
            WHERE profile_code = 'M1_13_EXPOSURE_RECOVERY_LOSS_FOUNDATIONS'
              AND profile_version = 1
              AND status = 'APPROVED'
        ) AS approved_policy_exists
    FROM run_context r
)
SELECT
    s.*,
    bp.simple_flag_rows,
    bp.schedule_flag_rows,
    bp.simple_el_publish_flag,
    bp.schedule_adjusted_el_publish_flag,
    CASE
        WHEN s.run_status = 'M1_12_ACCEPTED'
         AND s.path_rows = 0
         AND s.snapshot_rows = 0
         AND s.evidence_rows = 0
         AND s.gate_rows = 0
         AND s.blocking_errors = 0
         AND s.path_table_exists
         AND s.snapshot_table_exists
         AND s.approved_policy_exists
         AND bp.simple_flag_rows = 1
         AND bp.schedule_flag_rows = 1
         AND bp.simple_el_publish_flag IS NOT NULL
         AND bp.schedule_adjusted_el_publish_flag IS NOT NULL
        THEN 'PASS'
        ELSE 'FAIL'
    END AS recovery_state_status
FROM state s
CROSS JOIN boolean_parameters bp;
