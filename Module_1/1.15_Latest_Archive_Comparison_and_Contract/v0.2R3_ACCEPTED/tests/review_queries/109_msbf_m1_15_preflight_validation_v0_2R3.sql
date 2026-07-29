/* ============================================================================
MSBF M1.15 Hard-Stop Preflight Validation
Program : 109_msbf_m1_15_preflight_validation_v0_2R3.sql
Version : v0.2R3
Purpose : Confirm the accepted M1.14 state, complete matched upstream evidence,
          approved contract policy, empty M1.15 targets, and zero blockers.
Mode    : Read-only; raises an exception on any failed prerequisite.
============================================================================ */

SET statement_timeout='10min';

DROP TABLE IF EXISTS _m1_15_preflight;
CREATE TEMP TABLE _m1_15_preflight ON COMMIT PRESERVE ROWS AS
WITH r AS (
    SELECT run_id,run_status,population_id,as_of_date
    FROM msbf_ctl.run_registry
    WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
), gates AS (
    SELECT count(DISTINCT gate_id) FILTER(WHERE result_status='PASS') AS passed_gates
    FROM msbf_ctl.acceptance_gate_result
    WHERE run_id=(SELECT run_id FROM r)
      AND gate_id IN (
        'M1_7_SOURCE_QUALITY_CONFIDENCE',
        'M1_8_VERIFICATION_FRAUD_CONTINUITY',
        'M1_9_ASOF_CASHFLOW_FEATURES',
        'M1_10_OBLIGATIONS_LIQUIDITY_CAPACITY',
        'M1_11_CASHFLOW_ARCHETYPE_RESILIENCE',
        'M1_12_INTEGRATED_RISK_PROXY',
        'M1_13_EXPOSURE_RECOVERY_LOSS_FOUNDATIONS',
        'M1_14_UNIT_ECONOMICS_CONTRIBUTION'
      )
      AND review_version=(
        SELECT max(g2.review_version)
        FROM msbf_ctl.acceptance_gate_result g2
        WHERE g2.run_id=msbf_ctl.acceptance_gate_result.run_id
          AND g2.gate_id=msbf_ctl.acceptance_gate_result.gate_id
      )
), counts AS (
    SELECT
      (SELECT count(*) FROM msbf_m1.application_cashflow_feature_snapshot
       WHERE module1_run_id=(SELECT run_id FROM r)) AS m1_9_rows,
      (SELECT count(*) FROM msbf_m1.application_liquidity_capacity_snapshot
       WHERE module1_run_id=(SELECT run_id FROM r)) AS m1_10_rows,
      (SELECT count(*) FROM msbf_m1.application_operating_resilience_snapshot
       WHERE module1_run_id=(SELECT run_id FROM r)) AS m1_11_rows,
      (SELECT count(*) FROM msbf_m1.application_integrated_risk_proxy_snapshot
       WHERE module1_run_id=(SELECT run_id FROM r)) AS m1_12_rows,
      (SELECT count(*) FROM msbf_m1.application_exposure_recovery_loss_snapshot
       WHERE module1_run_id=(SELECT run_id FROM r)) AS m1_13_rows,
      (SELECT count(*) FROM msbf_m1.application_unit_economics_snapshot
       WHERE module1_run_id=(SELECT run_id FROM r)) AS m1_14_rows,
      (SELECT count(*) FROM msbf_m1.application_verification_fraud_snapshot
       WHERE module1_run_id=(SELECT run_id FROM r)) AS m1_8_rows,
      (SELECT count(*) FROM msbf_m1.application_module1_latest
       WHERE module1_run_id=(SELECT run_id FROM r)) AS latest_rows,
      (SELECT count(*) FROM msbf_m1.application_module1_archive
       WHERE module1_run_id=(SELECT run_id FROM r)) AS archive_rows,
      (SELECT count(*) FROM msbf_m1.application_module1_scenario_comparison
       WHERE module1_run_id=(SELECT run_id FROM r)) AS comparison_rows,
      (SELECT count(*) FROM msbf_ctl.m1_15_consumption_contract_registry
       WHERE module1_run_id=(SELECT run_id FROM r)) AS contract_rows,
      (SELECT count(*) FROM msbf_ctl.run_evidence
       WHERE run_id=(SELECT run_id FROM r)
         AND evidence_code LIKE 'M1_15_%') AS m1_15_evidence_rows,
      (SELECT count(*) FROM msbf_ctl.acceptance_gate_result
       WHERE run_id=(SELECT run_id FROM r)
         AND gate_id='M1_15_CONSUMPTION_CONTRACT') AS m1_15_gate_rows,
      (SELECT count(*) FROM msbf_ctl.profile_resolution_error
       WHERE run_id=(SELECT run_id FROM r) AND severity='BLOCKING') AS blocking_errors
), scenarios AS (
    SELECT count(DISTINCT e.scenario_id) AS scenario_count,
           count(DISTINCT e.scenario_id) FILTER(WHERE sr.scenario_code='BASELINE') AS baseline_count,
           count(DISTINCT e.scenario_id) FILTER(WHERE sr.scenario_code='RECESSION_ENERGY') AS stress_count,
           count(DISTINCT sr.scenario_set_id) AS scenario_set_count
    FROM msbf_m1.application_unit_economics_snapshot e
    JOIN msbf_ctl.scenario_registry sr
      ON sr.scenario_id=e.scenario_id
    WHERE e.module1_run_id=(SELECT run_id FROM r)
), policy AS (
    SELECT count(*) AS policy_rows,
           max(profile_payload->>'methodology_version') AS methodology_version,
           max(profile_payload->>'schema_version') AS schema_version
    FROM msbf_ctl.policy_profile
    WHERE profile_code='M1_15_CONSUMPTION_CONTRACT'
      AND profile_version=1 AND status='APPROVED'
)
SELECT
    r.run_id,
    r.run_status,
    r.population_id,
    r.as_of_date,
    gates.passed_gates,
    counts.m1_9_rows,
    counts.m1_10_rows,
    counts.m1_11_rows,
    counts.m1_12_rows,
    counts.m1_13_rows,
    counts.m1_14_rows,
    counts.m1_8_rows,
    counts.latest_rows,
    counts.archive_rows,
    counts.comparison_rows,
    counts.contract_rows,
    counts.m1_15_evidence_rows,
    counts.m1_15_gate_rows,
    counts.blocking_errors,
    scenarios.scenario_count,
    scenarios.baseline_count,
    scenarios.stress_count,
    scenarios.scenario_set_count,
    policy.policy_rows,
    policy.methodology_version,
    policy.schema_version,
    CASE
      WHEN r.run_status='M1_14_ACCEPTED'
       AND gates.passed_gates=8
       AND counts.m1_8_rows=750
       AND counts.m1_9_rows=1500
       AND counts.m1_10_rows=1500
       AND counts.m1_11_rows=1500
       AND counts.m1_12_rows=1500
       AND counts.m1_13_rows=1500
       AND counts.m1_14_rows=1500
       AND counts.latest_rows=0
       AND counts.archive_rows=0
       AND counts.comparison_rows=0
       AND counts.contract_rows=0
       AND counts.m1_15_evidence_rows=0
       AND counts.m1_15_gate_rows=0
       AND counts.blocking_errors=0
       AND scenarios.scenario_count=2
       AND scenarios.baseline_count=1
       AND scenarios.stress_count=1
       AND scenarios.scenario_set_count=1
       AND policy.policy_rows=1
       AND policy.methodology_version='M1_15_METHOD_V1'
       AND policy.schema_version='M1_CONTRACT_SCHEMA_V1'
      THEN 'PASS' ELSE 'FAIL'
    END AS preflight_status
FROM r CROSS JOIN gates CROSS JOIN counts CROSS JOIN scenarios CROSS JOIN policy;

DO $preflight$
BEGIN
    IF (SELECT preflight_status FROM _m1_15_preflight)<>'PASS' THEN
        RAISE EXCEPTION 'M1.15 preflight failed: %',
            (SELECT row_to_json(p) FROM _m1_15_preflight p);
    END IF;
    PERFORM msbf_m1.m1_15_assert_generation_ready(
        (SELECT run_id FROM _m1_15_preflight)
    );
END;
$preflight$;

SELECT * FROM _m1_15_preflight;
