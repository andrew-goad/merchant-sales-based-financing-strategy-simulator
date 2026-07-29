/* ============================================================================
MSBF M1.9 As-of Cash-Flow Feature Engineering
Failed Canonical Numeric-Scale Recovery Check
Version : v0.2R3
Purpose : Confirm that the v0.2R2 generation-time canonical reconciliation
          failure committed no M1.9 business rows, evidence, or acceptance
          result and that the governed M1.6 scenario scope remains intact.

Run only after stopping the failed script 62 execution and issuing ROLLBACK.
This script is read-only.
============================================================================ */
WITH ctx AS (
    SELECT run_id,run_status,population_id,as_of_date
    FROM msbf_ctl.run_registry
    WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
), pos_used AS (
    SELECT scenario_id,count(*) AS pos_rows
    FROM msbf_m1.merchant_pos_daily_scenario
    WHERE generated_by_run_id=(SELECT run_id FROM ctx)
    GROUP BY scenario_id
), deposit_used AS (
    SELECT scenario_id,count(*) AS deposit_rows
    FROM msbf_m1.merchant_deposit_daily_scenario
    WHERE generated_by_run_id=(SELECT run_id FROM ctx)
    GROUP BY scenario_id
), accepted_scenarios AS (
    SELECT sr.scenario_id,sr.scenario_code,ss.scenario_set_code,
           ss.scenario_set_version,p.pos_rows,d.deposit_rows
    FROM pos_used p
    JOIN deposit_used d USING(scenario_id)
    JOIN msbf_ctl.scenario_registry sr ON sr.scenario_id=p.scenario_id
    JOIN msbf_ctl.scenario_set ss ON ss.scenario_set_id=sr.scenario_set_id
    WHERE p.pos_rows=135000
      AND d.deposit_rows=135000
      AND ss.scenario_set_code='M1_V0_2_BASELINE_AND_STRESS'
      AND ss.scenario_set_version=1
      AND ss.status='APPROVED'
      AND sr.status='APPROVED'
      AND sr.scenario_version=1
      AND sr.scenario_code IN ('BASELINE','RECESSION_ENERGY')
), scenario_summary AS (
    SELECT count(*) AS scenario_rows,
           count(*) FILTER(WHERE scenario_code='BASELINE') AS baseline_rows,
           count(*) FILTER(WHERE scenario_code='RECESSION_ENERGY') AS stress_rows
    FROM accepted_scenarios
), physical_type AS (
    SELECT format_type(a.atttypid,a.atttypmod) AS value_numeric_type
    FROM pg_attribute a
    WHERE a.attrelid='msbf_m1.cashflow_feature_value'::regclass
      AND a.attname='value_numeric'
      AND a.attnum>0
      AND NOT a.attisdropped
), state AS (
    SELECT
      (SELECT count(*) FROM msbf_m1.application_cashflow_feature_snapshot
        WHERE module1_run_id=(SELECT run_id FROM ctx)) AS snapshot_rows,
      (SELECT count(*) FROM msbf_m1.cashflow_feature_value
        WHERE module1_run_id=(SELECT run_id FROM ctx)) AS feature_value_rows,
      (SELECT count(*) FROM msbf_ctl.run_evidence
        WHERE run_id=(SELECT run_id FROM ctx) AND evidence_code LIKE 'M1_9_%') AS m1_9_evidence_rows,
      (SELECT count(*) FROM msbf_ctl.acceptance_gate_result
        WHERE run_id=(SELECT run_id FROM ctx) AND gate_id='M1_9_ASOF_CASHFLOW_FEATURES') AS m1_9_gate_rows,
      (SELECT count(*) FROM msbf_ctl.profile_resolution_error
        WHERE run_id=(SELECT run_id FROM ctx) AND severity='BLOCKING') AS blocking_errors,
      to_regclass('msbf_m1.application_cashflow_feature_snapshot') IS NOT NULL AS snapshot_table_exists,
      to_regclass('msbf_m1.cashflow_feature_value') IS NOT NULL AS feature_value_table_exists
)
SELECT
    c.run_id,c.run_status,c.population_id,c.as_of_date,
    ss.scenario_rows,ss.baseline_rows,ss.stress_rows,
    p.value_numeric_type,
    s.snapshot_table_exists,s.feature_value_table_exists,
    s.snapshot_rows,s.feature_value_rows,s.m1_9_evidence_rows,
    s.m1_9_gate_rows,s.blocking_errors,
    CASE WHEN
        c.run_status='M1_8_ACCEPTED'
        AND ss.scenario_rows=2
        AND ss.baseline_rows=1
        AND ss.stress_rows=1
        AND p.value_numeric_type='numeric(24,10)'
        AND s.snapshot_table_exists
        AND s.feature_value_table_exists
        AND s.snapshot_rows=0
        AND s.feature_value_rows=0
        AND s.m1_9_evidence_rows=0
        AND s.m1_9_gate_rows=0
        AND s.blocking_errors=0
      THEN 'PASS' ELSE 'FAIL' END AS recovery_state_status
FROM ctx c
CROSS JOIN scenario_summary ss
CROSS JOIN physical_type p
CROSS JOIN state s;
