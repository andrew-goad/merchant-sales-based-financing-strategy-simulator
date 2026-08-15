/* ============================================================================
M2.3 Program 148A — Failed-Generation Recovery Check
Version     : v0.2R2
Purpose     : Read-only recovery check after a failed/cancelled Program 150
              generation attempt. Run after ROLLBACK.
Required    : recovery_status = PASS.
============================================================================ */

WITH run_context AS
(
    SELECT run_id, run_status
    FROM msbf_ctl.run_registry
    WHERE run_code='M1_V0_2_BASELINE_BUILD'
      AND run_version=1
),
policy AS
(
    SELECT policy_status, configuration_hash
    FROM msbf_ctl.m2_3_policy_profile
    WHERE module1_run_id=(SELECT run_id FROM run_context)
),
targets AS
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
        (SELECT count(*) FROM msbf_ctl.m2_3_final_decision_contract_registry
         WHERE module1_run_id=(SELECT run_id FROM run_context)) AS registry_rows,
        (SELECT count(*) FROM msbf_ctl.run_evidence
         WHERE run_id=(SELECT run_id FROM run_context)
           AND evidence_code LIKE 'M2_3_%') AS evidence_rows,
        (SELECT count(*) FROM msbf_ctl.acceptance_gate_result
         WHERE run_id=(SELECT run_id FROM run_context)
           AND gate_id='M2_3_FINAL_OFFER_DECISION_AUTHORIZATION') AS acceptance_rows
)
SELECT
    run_context.run_status,
    policy.policy_status,
    policy.configuration_hash,
    targets.source_rows,
    targets.snapshot_rows,
    targets.latest_rows,
    targets.archive_rows,
    targets.registry_rows,
    targets.evidence_rows,
    targets.acceptance_rows,
    CASE
        WHEN run_context.run_status='M2_2_ACCEPTED'
         AND policy.policy_status='APPROVED'
         AND length(policy.configuration_hash)=32
         AND policy.configuration_hash ~ '^[0-9a-f]+$'
         AND targets.source_rows=0
         AND targets.snapshot_rows=0
         AND targets.latest_rows=0
         AND targets.archive_rows=0
         AND targets.registry_rows=0
         AND targets.evidence_rows=0
         AND targets.acceptance_rows=0
        THEN 'PASS'
        ELSE 'FAIL'
    END AS recovery_status
FROM run_context
CROSS JOIN policy
CROSS JOIN targets;
