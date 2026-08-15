/* ============================================================================
M2.3 Program 150A — Generation Result Reconstruction
Version     : v0.2R2
Purpose     : Read-only reconstruction if Program 150 committed but the
              DBeaver result tab was lost or suppressed.
============================================================================ */

WITH run_context AS
(
    SELECT run_id, run_status
    FROM msbf_ctl.run_registry
    WHERE run_code='M1_V0_2_BASELINE_BUILD'
      AND run_version=1
),
registry AS
(
    SELECT *
    FROM msbf_ctl.m2_3_final_decision_contract_registry
    WHERE module1_run_id=(SELECT run_id FROM run_context)
),
physical AS
(
    SELECT
        (SELECT count(*) FROM msbf_m2.application_final_decision_source_snapshot
         WHERE module1_run_id=(SELECT run_id FROM run_context)) AS source_rows,
        (SELECT count(*) FROM msbf_m2.application_final_offer_decision_snapshot
         WHERE module1_run_id=(SELECT run_id FROM run_context)) AS snapshot_rows,
        (SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest
         WHERE module1_run_id=(SELECT run_id FROM run_context)) AS latest_rows,
        (SELECT count(*) FROM msbf_m2.application_final_offer_decision_archive
         WHERE module1_run_id=(SELECT run_id FROM run_context)) AS archive_rows,
        (SELECT count(*) FROM msbf_m2.v_m2_3_matched_scenario_comparison
         WHERE module1_run_id=(SELECT run_id FROM run_context)) AS comparison_rows,
        (SELECT count(*) FROM msbf_ctl.run_evidence
         WHERE run_id=(SELECT run_id FROM run_context)
           AND evidence_code LIKE 'M2_3_%') AS m2_3_evidence_rows
)
SELECT
    run_context.run_status,
    registry.contract_status,
    physical.source_rows,
    physical.snapshot_rows,
    physical.latest_rows,
    physical.archive_rows,
    physical.comparison_rows,
    registry.canonical_entities,
    physical.m2_3_evidence_rows,
    registry.policy_set_hash,
    registry.outcome_set_hash,
    registry.reason_set_hash,
    registry.source_set_hash,
    registry.decision_snapshot_set_hash,
    registry.decision_latest_set_hash,
    registry.decision_archive_set_hash,
    registry.contract_set_hash,
    registry.combined_set_hash,
    CASE
        WHEN run_context.run_status IN('M2_3_GENERATED','M2_3_VALIDATED','M2_3_ACCEPTED')
         AND registry.contract_status IN('GENERATED','VALIDATED','ACCEPTED')
         AND physical.source_rows=1500
         AND physical.snapshot_rows=1500
         AND physical.latest_rows=1500
         AND physical.archive_rows=1500
         AND physical.comparison_rows=750
         AND registry.canonical_entities=6029
         AND physical.m2_3_evidence_rows >= 20
         AND registry.combined_set_hash IS NOT NULL
        THEN 'PASS'
        ELSE 'FAIL'
    END AS generation_reconstruction_status
FROM run_context
CROSS JOIN registry
CROSS JOIN physical;
