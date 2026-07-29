/* ============================================================================
MSBF M1.15 Master Acceptance Report
Program : 114_MSBF_M1_15_Consumption_Contract_Master_Report_v0_2R3.sql
Version : v0.2R3
Purpose : Provide one executive acceptance row covering run state, contract
          lifecycle, cardinality, controls, hashes, and residual boundaries.
============================================================================ */

WITH r AS (
    SELECT run_id,run_status,population_id,as_of_date,completed_at
    FROM msbf_ctl.run_registry
    WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
), c AS (
    SELECT * FROM msbf_ctl.m1_15_consumption_contract_registry
    WHERE module1_run_id=(SELECT run_id FROM r)
), pos AS (
    SELECT count(*) AS checks,
           count(*) FILTER(WHERE status='PASS') AS passes,
           count(*) FILTER(WHERE status='FAIL') AS failures
    FROM msbf_ctl.run_evidence
    WHERE run_id=(SELECT run_id FROM r) AND evidence_code LIKE 'M1_15_POS_%'
), neg AS (
    SELECT count(*) AS controls,
           count(*) FILTER(WHERE status='PASS') AS passes,
           count(*) FILTER(WHERE status='FAIL') AS failures
    FROM msbf_ctl.run_evidence
    WHERE run_id=(SELECT run_id FROM r) AND evidence_code LIKE 'M1_15_NEG_%'
), gate AS (
    SELECT result_status,review_version,reviewed_at
    FROM msbf_ctl.acceptance_gate_result
    WHERE run_id=(SELECT run_id FROM r)
      AND gate_id='M1_15_CONSUMPTION_CONTRACT'
    ORDER BY review_version DESC LIMIT 1
), stats AS (
    SELECT
      (SELECT count(*) FROM msbf_m1.application_module1_latest
       WHERE module1_run_id=(SELECT run_id FROM r)) AS latest_rows,
      (SELECT count(*) FROM msbf_m1.application_module1_archive
       WHERE module1_run_id=(SELECT run_id FROM r)) AS archive_rows,
      (SELECT count(*) FROM msbf_m1.application_module1_scenario_comparison
       WHERE module1_run_id=(SELECT run_id FROM r)) AS comparison_rows,
      (SELECT count(DISTINCT merchant_application_id)
       FROM msbf_m1.application_module1_latest
       WHERE module1_run_id=(SELECT run_id FROM r)) AS applications,
      (SELECT count(DISTINCT scenario_id)
       FROM msbf_m1.application_module1_latest
       WHERE module1_run_id=(SELECT run_id FROM r)) AS scenarios,
      (SELECT count(*) FROM msbf_ctl.profile_resolution_error
       WHERE run_id=(SELECT run_id FROM r) AND severity='BLOCKING') AS blocking_errors,
      (SELECT count(*) FROM msbf_m1.application_module1_latest
       WHERE module1_run_id=(SELECT run_id FROM r)
         AND hard_stop_recommended_flag) AS hard_stop_rows,
      (SELECT count(*) FROM msbf_m1.application_module1_latest
       WHERE module1_run_id=(SELECT run_id FROM r)
         AND manual_review_recommended_flag) AS manual_review_rows
)
SELECT
    r.run_id,r.run_status,r.population_id,r.as_of_date,r.completed_at,
    c.contract_code,c.contract_version,c.schema_version,c.contract_status,
    stats.latest_rows,stats.archive_rows,stats.comparison_rows,
    stats.applications,stats.scenarios,
    pos.checks AS positive_checks,pos.passes AS positive_passes,
    pos.failures AS positive_failures,
    neg.controls AS negative_controls,neg.passes AS negative_passes,
    neg.failures AS negative_failures,
    stats.hard_stop_rows,stats.manual_review_rows,stats.blocking_errors,
    c.latest_set_hash,c.archive_set_hash,c.comparison_set_hash,
    c.contract_set_hash,c.combined_set_hash,
    gate.result_status AS gate_status,gate.review_version,gate.reviewed_at,
    CASE
      WHEN r.run_status='M1_15_ACCEPTED'
       AND c.contract_status='ACCEPTED'
       AND gate.result_status='PASS'
       AND pos.checks=84 AND pos.passes=84 AND pos.failures=0
       AND neg.controls=7 AND neg.passes=7 AND neg.failures=0
       AND stats.latest_rows=1500 AND stats.archive_rows=1500
       AND stats.comparison_rows=750 AND stats.blocking_errors=0
      THEN 'PASS' ELSE 'FAIL'
    END AS overall_m1_15_status
FROM r CROSS JOIN c CROSS JOIN pos CROSS JOIN neg CROSS JOIN gate CROSS JOIN stats;
