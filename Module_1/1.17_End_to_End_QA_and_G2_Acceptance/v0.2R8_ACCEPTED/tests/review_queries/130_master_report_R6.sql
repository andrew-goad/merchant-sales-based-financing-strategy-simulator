
/* ============================================================================
 M1.17 Program 130 — G2 Contract Master Report
 Version v0.2R6

 Read-only executive one-row report for the accepted Module 1 G2 bundle.
============================================================================ */

WITH r AS (
    SELECT run_id,run_code,run_version,run_status,population_id,as_of_date
    FROM msbf_ctl.run_registry
    WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
), reg AS (
    SELECT *
    FROM msbf_ctl.m1_17_g2_bundle_registry
    WHERE module1_run_id=(SELECT run_id FROM r)
), controls AS (
    SELECT
        count(*) FILTER(WHERE evidence_code LIKE 'M1_17_POS_%') AS positive_checks,
        count(*) FILTER(WHERE evidence_code LIKE 'M1_17_POS_%' AND status='PASS') AS positive_passes,
        count(*) FILTER(WHERE evidence_code LIKE 'M1_17_NEG_%') AS negative_checks,
        count(*) FILTER(WHERE evidence_code LIKE 'M1_17_NEG_%' AND status='PASS') AS negative_passes
    FROM msbf_ctl.run_evidence
    WHERE run_id=(SELECT run_id FROM r)
), gate AS (
    SELECT coalesce(
        to_jsonb(g)->>'result_status',
        to_jsonb(g)->>'gate_status',
        to_jsonb(g)->>'status'
    ) AS gate_status
    FROM msbf_ctl.acceptance_gate_result g
    WHERE g.run_id=(SELECT run_id FROM r)
      AND g.gate_id='G2_M1_CONTRACT'
    ORDER BY
        CASE
            WHEN (to_jsonb(g)->>'review_version') ~ '^[0-9]+$'
            THEN (to_jsonb(g)->>'review_version')::integer
            ELSE 0
        END DESC
    LIMIT 1
), counts AS (
    SELECT
        (SELECT count(*) FROM msbf_ctl.m1_17_hash_chain_snapshot
          WHERE module1_run_id=(SELECT run_id FROM r)) AS hash_chain_rows,
        (SELECT count(*) FROM msbf_ctl.m1_17_end_to_end_evidence_snapshot
          WHERE module1_run_id=(SELECT run_id FROM r)) AS evidence_snapshot_rows,
        (SELECT count(*) FROM msbf_m1.v_m1_17_g2_integrated_consumption
          WHERE module1_run_id=(SELECT run_id FROM r)) AS integrated_rows,
        (SELECT count(DISTINCT merchant_application_id)
         FROM msbf_m1.v_m1_17_g2_integrated_consumption
         WHERE module1_run_id=(SELECT run_id FROM r)) AS applications,
        (SELECT count(DISTINCT scenario_id)
         FROM msbf_m1.v_m1_17_g2_integrated_consumption
         WHERE module1_run_id=(SELECT run_id FROM r)) AS scenarios,
        (SELECT count(*) FROM msbf_ctl.profile_resolution_error
         WHERE run_id=(SELECT run_id FROM r)
           AND severity='BLOCKING') AS blocking_errors,
        msbf_ctl.m1_17_schema_row_count('msbf_m2') AS module2_rows
)
SELECT
    r.run_code,
    r.run_version,
    r.run_status,
    r.population_id,
    r.as_of_date,
    reg.methodology_version,
    reg.bundle_code,
    reg.bundle_version,
    reg.schema_version,
    reg.bundle_status,
    reg.source_m1_15_contract_code,
    reg.source_m1_15_contract_version,
    reg.source_m1_15_schema_version,
    reg.source_m1_15_combined_hash,
    reg.source_m1_16_contract_code,
    reg.source_m1_16_contract_version,
    reg.source_m1_16_schema_version,
    reg.source_m1_16_combined_hash,
    reg.accepted_scenario_set_hash,
    reg.policy_configuration_hash,
    reg.predecessor_gate_count,
    counts.applications,
    counts.scenarios,
    counts.integrated_rows,
    counts.hash_chain_rows,
    counts.evidence_snapshot_rows,
    reg.canonical_entities,
    controls.positive_passes,
    controls.positive_checks,
    controls.negative_passes,
    controls.negative_checks,
    counts.blocking_errors,
    counts.module2_rows,
    reg.hash_chain_set_hash,
    reg.evidence_set_hash,
    reg.bundle_latest_set_hash,
    reg.bundle_archive_set_hash,
    reg.contract_set_hash,
    reg.combined_g2_hash,
    gate.gate_status,
    CASE
        WHEN r.run_status='M1_17_ACCEPTED'
         AND reg.bundle_status='ACCEPTED'
         AND gate.gate_status='PASS'
         AND controls.positive_passes=128
         AND controls.positive_checks=128
         AND controls.negative_passes=20
         AND controls.negative_checks=20
         AND counts.applications=750
         AND counts.scenarios=2
         AND counts.integrated_rows=1500
         AND counts.hash_chain_rows=18
         AND counts.evidence_snapshot_rows=48
         AND reg.canonical_entities=69
         AND counts.blocking_errors=0
         AND counts.module2_rows=0
        THEN 'PASS'
        ELSE 'FAIL'
    END AS overall_m1_17_status
FROM r
CROSS JOIN reg
CROSS JOIN controls
CROSS JOIN gate
CROSS JOIN counts;
