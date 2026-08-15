/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.3 — Final Offer & Decision Authorization

Program     : 153_msbf_m2_3_acceptance_finalize_v0_2R2.sql
Version     : v0.2R2
Purpose     : Independently verify positive and negative evidence, physical
              counts, final-offer/declarative boundaries, deterministic hashes,
              latest/archive reproduction, and stage boundaries before issuing
              the M2.3 acceptance gate.

Required    : acceptance_status = PASS and final_run_status = M2_3_ACCEPTED.
============================================================================ */

BEGIN;

SET LOCAL work_mem = '96MB';
SET LOCAL statement_timeout = '30min';
SET LOCAL jit = off;

DROP TABLE IF EXISTS _m2_3_acceptance;

CREATE TEMP TABLE _m2_3_acceptance
ON COMMIT PRESERVE ROWS
AS
WITH run_context AS
(
    SELECT run_id, run_status
    FROM msbf_ctl.run_registry
    WHERE run_code='M1_V0_2_BASELINE_BUILD'
      AND run_version=1
),
registry AS
(
    SELECT
        contract_status,
        canonical_entities,
        final_offer_authorized_rows,
        manual_review_required_rows,
        decline_insufficient_evidence_rows,
        decline_policy_rows,
        contract_set_hash,
        combined_set_hash
    FROM msbf_ctl.m2_3_final_decision_contract_registry
    WHERE module1_run_id=(SELECT run_id FROM run_context)
),
controls AS
(
    SELECT
        count(*) FILTER(WHERE evidence_code LIKE 'M2_3_POS_%') AS positive_checks,
        count(*) FILTER(WHERE evidence_code LIKE 'M2_3_POS_%' AND status='PASS') AS positive_passes,
        count(*) FILTER(WHERE evidence_code LIKE 'M2_3_POS_%' AND status<>'PASS') AS positive_failures,
        count(*) FILTER(WHERE evidence_code LIKE 'M2_3_NEG_%') AS negative_checks,
        count(*) FILTER(WHERE evidence_code LIKE 'M2_3_NEG_%' AND status='PASS') AS negative_passes,
        count(*) FILTER(WHERE evidence_code LIKE 'M2_3_NEG_%' AND status<>'PASS') AS negative_failures
    FROM msbf_ctl.run_evidence
    WHERE run_id=(SELECT run_id FROM run_context)
),
physical AS
(
    SELECT
        (SELECT count(*) FROM msbf_ctl.m2_3_policy_profile WHERE module1_run_id=(SELECT run_id FROM run_context)) AS policy_rows,
        (SELECT count(*) FROM msbf_m2.final_decision_outcome_definition WHERE module1_run_id=(SELECT run_id FROM run_context)) AS outcome_rows,
        (SELECT count(*) FROM msbf_m2.final_decision_reason_definition WHERE module1_run_id=(SELECT run_id FROM run_context)) AS reason_rows,
        (SELECT count(*) FROM msbf_m2.application_final_decision_source_snapshot WHERE module1_run_id=(SELECT run_id FROM run_context)) AS source_rows,
        (SELECT count(*) FROM msbf_m2.application_final_offer_decision_snapshot WHERE module1_run_id=(SELECT run_id FROM run_context)) AS snapshot_rows,
        (SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM run_context)) AS latest_rows,
        (SELECT count(*) FROM msbf_m2.application_final_offer_decision_archive WHERE module1_run_id=(SELECT run_id FROM run_context)) AS archive_rows,
        (SELECT count(*) FROM msbf_m2.v_m2_3_matched_scenario_comparison WHERE module1_run_id=(SELECT run_id FROM run_context)) AS comparison_rows,
        (SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM run_context) AND final_offer_authorized_flag) AS final_offer_rows,
        (SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM run_context) AND counteroffer_review_required_flag) AS manual_review_rows,
        (SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM run_context) AND final_decision_outcome_code='DECLINE_INSUFFICIENT_EVIDENCE_AUTHORIZED') AS insufficient_rows,
        (SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM run_context) AND final_decision_outcome_code='DECLINE_POLICY_AUTHORIZED') AS policy_decline_rows,
        (SELECT count(*) FROM msbf_m2.v_m2_3_matched_scenario_comparison WHERE module1_run_id=(SELECT run_id FROM run_context) AND (stress_decision_improvement_flag OR stress_offer_term_improvement_flag)) AS stress_improvement_rows,
        (SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=(SELECT run_id FROM run_context) AND NOT final_offer_authorized_flag AND final_offer_amount IS NOT NULL) AS nonoffer_term_rows,
        (SELECT count(*) FROM msbf_m2.final_decision_outcome_definition WHERE module1_run_id=(SELECT run_id FROM run_context) AND (production_adverse_action_notice_flag OR booking_funding_flag)) AS prohibited_outcome_flags,
        (SELECT count(*) FROM msbf_m2.final_decision_reason_definition WHERE module1_run_id=(SELECT run_id FROM run_context) AND production_adverse_action_notice_flag) AS prohibited_reason_flags,
        (SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest AS latest JOIN msbf_m2.application_final_offer_decision_archive AS archive ON archive.module1_run_id=latest.module1_run_id AND archive.contract_version=latest.contract_version AND archive.scenario_id=latest.scenario_id AND archive.merchant_application_id=latest.merchant_application_id WHERE latest.module1_run_id=(SELECT run_id FROM run_context) AND (archive.contract_row_hash IS DISTINCT FROM latest.contract_row_hash OR archive.contract_payload IS DISTINCT FROM (to_jsonb(latest)-'created_at'))) AS archive_mismatches,
        (SELECT count(*) FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM run_context) AND gate_id='M2_3_FINAL_OFFER_DECISION_AUTHORIZATION') AS existing_gate_rows
)
SELECT
    run_context.run_id,
    run_context.run_status AS prior_run_status,
    registry.contract_status AS prior_contract_status,
    controls.positive_checks,
    controls.positive_passes,
    controls.positive_failures,
    controls.negative_checks,
    controls.negative_passes,
    controls.negative_failures,
    physical.policy_rows,
    physical.outcome_rows,
    physical.reason_rows,
    physical.source_rows,
    physical.snapshot_rows,
    physical.latest_rows,
    physical.archive_rows,
    physical.comparison_rows,
    physical.final_offer_rows,
    physical.manual_review_rows,
    physical.insufficient_rows,
    physical.policy_decline_rows,
    physical.stress_improvement_rows,
    physical.nonoffer_term_rows,
    physical.prohibited_outcome_flags,
    physical.prohibited_reason_flags,
    physical.archive_mismatches,
    physical.existing_gate_rows,
    registry.canonical_entities,
    registry.contract_set_hash,
    registry.combined_set_hash,
    CASE
        WHEN run_context.run_status = 'M2_3_VALIDATED'
         AND registry.contract_status = 'VALIDATED'
         AND controls.positive_checks = 120
         AND controls.positive_passes = 120
         AND controls.positive_failures = 0
         AND controls.negative_checks = 20
         AND controls.negative_passes = 20
         AND controls.negative_failures = 0
         AND physical.policy_rows = 1
         AND physical.outcome_rows = 5
         AND physical.reason_rows = 22
         AND physical.source_rows = 1500
         AND physical.snapshot_rows = 1500
         AND physical.latest_rows = 1500
         AND physical.archive_rows = 1500
         AND physical.comparison_rows = 750
         AND physical.final_offer_rows = 59
         AND physical.manual_review_rows = 190
         AND physical.insufficient_rows = 178
         AND physical.policy_decline_rows = 1073
         AND physical.stress_improvement_rows = 0
         AND physical.nonoffer_term_rows = 0
         AND physical.prohibited_outcome_flags = 0
         AND physical.prohibited_reason_flags = 0
         AND physical.archive_mismatches = 0
         AND physical.existing_gate_rows = 0
         AND registry.canonical_entities = 6029
         AND registry.contract_set_hash IS NOT NULL
         AND registry.combined_set_hash IS NOT NULL
        THEN 'PASS'
        ELSE 'FAIL'
    END AS acceptance_status
FROM run_context
CROSS JOIN registry
CROSS JOIN controls
CROSS JOIN physical;

DO $m2_3_acceptance_guard$
DECLARE
    v record;
BEGIN
    SELECT
        run_id,
        prior_run_status,
        prior_contract_status,
        positive_checks,
        positive_passes,
        positive_failures,
        negative_checks,
        negative_passes,
        negative_failures,
        policy_rows,
        outcome_rows,
        reason_rows,
        source_rows,
        snapshot_rows,
        latest_rows,
        archive_rows,
        comparison_rows,
        final_offer_rows,
        manual_review_rows,
        insufficient_rows,
        policy_decline_rows,
        stress_improvement_rows,
        nonoffer_term_rows,
        prohibited_outcome_flags,
        prohibited_reason_flags,
        archive_mismatches,
        existing_gate_rows,
        canonical_entities,
        contract_set_hash,
        combined_set_hash,
        acceptance_status
    INTO v
    FROM _m2_3_acceptance;

    IF v.acceptance_status <> 'PASS' THEN
        RAISE EXCEPTION
            'M2.3 acceptance preconditions failed: %',
            row_to_json(v);
    END IF;

    PERFORM msbf_ctl.m2_3_assert_acceptance_ready(v.run_id);
END;
$m2_3_acceptance_guard$;

DROP TABLE IF EXISTS _m2_3_acceptance_evidence;

CREATE TEMP TABLE _m2_3_acceptance_evidence
(
    run_id                  bigint NOT NULL,
    evidence_code           text NOT NULL,
    segment_key             text NOT NULL,
    metric_name             text NOT NULL,
    metric_value_numeric    numeric(28,10),
    metric_value_text       text,
    unit_code               text NOT NULL,
    status                  text NOT NULL,
    interpretation          text NOT NULL,
    CHECK(num_nonnulls(metric_value_numeric,metric_value_text)=1)
)
ON COMMIT DROP;

INSERT INTO _m2_3_acceptance_evidence
SELECT
    run_id,
    'M2_3_ACCEPTANCE_SUMMARY',
    'PORTFOLIO',
    'M2_3_FINAL_OFFER_DECISION_ACCEPTANCE',
    NULL::numeric(28,10),
    combined_set_hash,
    'ACCEPTANCE',
    'PASS',
    'Formal M2.3 acceptance: final offer and decision authorization contract '
    || 'accepted with 120 positive controls, 20 negative controls, zero '
    || 'stress improvements, zero archive mismatches, and no booking/funding '
    || 'or production adverse-action notice.'
FROM _m2_3_acceptance;

UPDATE msbf_ctl.m2_3_final_decision_contract_registry
SET
    contract_status = 'ACCEPTED',
    accepted_at = clock_timestamp()
WHERE module1_run_id = (SELECT run_id FROM _m2_3_acceptance);

UPDATE msbf_ctl.run_registry
SET
    run_status = 'M2_3_ACCEPTED',
    notes = coalesce(notes,'') ||
        ' | M2.3 final offer and decision authorization accepted.'
WHERE run_id = (SELECT run_id FROM _m2_3_acceptance);

INSERT INTO msbf_ctl.acceptance_gate_result
(
    run_id,
    gate_id,
    review_version,
    result_status,
    observed_value,
    threshold_value,
    finding,
    residual_limitation,
    reviewer_role
)
SELECT
    run_id,
    'M2_3_FINAL_OFFER_DECISION_AUTHORIZATION',
    1,
    'PASS',
    combined_set_hash,
    '120/120 positive; 20/20 negative; zero deterministic, stress, archive, or boundary violations',
    'M2.3 final offer and decision authorization accepted.',
    'No booking, funding, external notice generation, or production adverse-action notice is created by M2.3.',
    'Independent Validation / Project Owner'
FROM _m2_3_acceptance;

INSERT INTO msbf_ctl.run_evidence
(
    run_id,
    evidence_code,
    segment_key,
    metric_name,
    metric_value_numeric,
    metric_value_text,
    unit_code,
    status,
    interpretation
)
SELECT
    evidence.run_id,
    evidence.evidence_code,
    evidence.segment_key,
    evidence.metric_name,
    evidence.metric_value_numeric,
    evidence.metric_value_text,
    evidence.unit_code,
    evidence.status,
    evidence.interpretation
FROM _m2_3_acceptance_evidence AS evidence;

ALTER TABLE _m2_3_acceptance
    ADD COLUMN final_run_status text,
    ADD COLUMN final_contract_status text,
    ADD COLUMN gate_status text;

UPDATE _m2_3_acceptance AS acceptance
SET
    final_run_status =
    (
        SELECT run_status
        FROM msbf_ctl.run_registry
        WHERE run_id = acceptance.run_id
    ),
    final_contract_status =
    (
        SELECT contract_status
        FROM msbf_ctl.m2_3_final_decision_contract_registry
        WHERE module1_run_id = acceptance.run_id
    ),
    gate_status =
    (
        SELECT result_status
        FROM msbf_ctl.acceptance_gate_result
        WHERE run_id = acceptance.run_id
          AND gate_id = 'M2_3_FINAL_OFFER_DECISION_AUTHORIZATION'
          AND review_version = 1
    );

DO $m2_3_acceptance_final_guard$
DECLARE
    v record;
BEGIN
    SELECT
        run_id,
        prior_run_status,
        prior_contract_status,
        positive_checks,
        positive_passes,
        positive_failures,
        negative_checks,
        negative_passes,
        negative_failures,
        policy_rows,
        outcome_rows,
        reason_rows,
        source_rows,
        snapshot_rows,
        latest_rows,
        archive_rows,
        comparison_rows,
        final_offer_rows,
        manual_review_rows,
        insufficient_rows,
        policy_decline_rows,
        stress_improvement_rows,
        nonoffer_term_rows,
        prohibited_outcome_flags,
        prohibited_reason_flags,
        archive_mismatches,
        existing_gate_rows,
        canonical_entities,
        contract_set_hash,
        combined_set_hash,
        acceptance_status,
        final_run_status,
        final_contract_status,
        gate_status
    INTO v
    FROM _m2_3_acceptance;

    IF v.final_run_status <> 'M2_3_ACCEPTED'
       OR v.final_contract_status <> 'ACCEPTED'
       OR v.gate_status <> 'PASS' THEN
        RAISE EXCEPTION
            'M2.3 final acceptance state failed: %',
            row_to_json(v);
    END IF;
END;
$m2_3_acceptance_final_guard$;

COMMIT;

SELECT
    run_id,
    prior_run_status,
    prior_contract_status,
    positive_checks,
    positive_passes,
    positive_failures,
    negative_checks,
    negative_passes,
    negative_failures,
    policy_rows,
    outcome_rows,
    reason_rows,
    source_rows,
    snapshot_rows,
    latest_rows,
    archive_rows,
    comparison_rows,
    final_offer_rows,
    manual_review_rows,
    insufficient_rows,
    policy_decline_rows,
    stress_improvement_rows,
    nonoffer_term_rows,
    prohibited_outcome_flags,
    prohibited_reason_flags,
    archive_mismatches,
    existing_gate_rows,
    canonical_entities,
    contract_set_hash,
    combined_set_hash,
    acceptance_status,
    final_run_status,
    final_contract_status,
    gate_status
FROM _m2_3_acceptance;
