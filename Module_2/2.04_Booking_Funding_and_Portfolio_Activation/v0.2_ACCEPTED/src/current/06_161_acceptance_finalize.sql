/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.4 — Booking, Funding & Portfolio Activation

Program     : 161_msbf_m2_4_acceptance_finalize_v0_2.sql
Version     : v0.2
Purpose     : Independently verify positive/negative evidence, physical counts,
              source-to-activation mapping, account/advance/portfolio linkage,
              latest/archive reproduction, stress non-improvement and exact
              synthetic operational boundaries before issuing the M2.4 gate.

Required    : acceptance_status = PASS and final_run_status = M2_4_ACCEPTED.
============================================================================ */

BEGIN;

SET LOCAL work_mem='128MB';
SET LOCAL statement_timeout='35min';
SET LOCAL jit=off;

/* --------------------------------------------------------------------------
Phase 1 — Reconstruct independent acceptance evidence
-------------------------------------------------------------------------- */
DROP TABLE IF EXISTS _m2_4_acceptance;

CREATE TEMP TABLE _m2_4_acceptance
ON COMMIT PRESERVE ROWS
AS
WITH run_context AS
(
    SELECT run_id,run_status
    FROM msbf_ctl.run_registry
    WHERE run_code='M1_V0_2_BASELINE_BUILD'
      AND run_version=1
),
registry AS
(
    SELECT
        contract_status,
        canonical_entities,
        activated_rows,
        review_required_rows,
        not_activated_insufficient_rows,
        not_activated_policy_rows,
        contract_set_hash,
        combined_set_hash
    FROM msbf_ctl.m2_4_portfolio_activation_contract_registry
    WHERE module1_run_id=(SELECT run_id FROM run_context)
),
controls AS
(
    SELECT
        count(*) FILTER(WHERE evidence_code LIKE 'M2_4_POS_%') AS positive_checks,
        count(*) FILTER(WHERE evidence_code LIKE 'M2_4_POS_%' AND status='PASS') AS positive_passes,
        count(*) FILTER(WHERE evidence_code LIKE 'M2_4_POS_%' AND status<>'PASS') AS positive_failures,
        count(*) FILTER(WHERE evidence_code LIKE 'M2_4_NEG_%') AS negative_checks,
        count(*) FILTER(WHERE evidence_code LIKE 'M2_4_NEG_%' AND status='PASS') AS negative_passes,
        count(*) FILTER(WHERE evidence_code LIKE 'M2_4_NEG_%' AND status<>'PASS') AS negative_failures
    FROM msbf_ctl.run_evidence
    WHERE run_id=(SELECT run_id FROM run_context)
),
physical AS
(
    SELECT
        (SELECT count(*) FROM msbf_ctl.m2_4_policy_profile WHERE module1_run_id=(SELECT run_id FROM run_context)) AS policy_rows,
        (SELECT count(*) FROM msbf_m2.booking_funding_activation_outcome_definition WHERE module1_run_id=(SELECT run_id FROM run_context)) AS outcome_rows,
        (SELECT count(*) FROM msbf_m2.booking_funding_reason_definition WHERE module1_run_id=(SELECT run_id FROM run_context)) AS reason_rows,
        (SELECT count(*) FROM msbf_m2.external_notice_control_definition WHERE module1_run_id=(SELECT run_id FROM run_context)) AS notice_rows,
        (SELECT count(*) FROM msbf_m2.application_booking_funding_source_snapshot WHERE module1_run_id=(SELECT run_id FROM run_context)) AS source_rows,
        (SELECT count(*) FROM msbf_m2.application_booking_funding_activation_snapshot WHERE module1_run_id=(SELECT run_id FROM run_context)) AS snapshot_rows,
        (SELECT count(*) FROM msbf_m2.application_booking_funding_activation_latest WHERE module1_run_id=(SELECT run_id FROM run_context)) AS latest_rows,
        (SELECT count(*) FROM msbf_m2.application_booking_funding_activation_archive WHERE module1_run_id=(SELECT run_id FROM run_context)) AS archive_rows,
        (SELECT count(*) FROM msbf_m2.synthetic_account_activation WHERE module1_run_id=(SELECT run_id FROM run_context)) AS account_rows,
        (SELECT count(*) FROM msbf_m2.synthetic_advance_funding WHERE module1_run_id=(SELECT run_id FROM run_context)) AS advance_rows,
        (SELECT count(*) FROM msbf_m2.initial_portfolio_activation WHERE module1_run_id=(SELECT run_id FROM run_context)) AS portfolio_rows,
        (SELECT count(*) FROM msbf_m2.v_m2_4_matched_scenario_comparison WHERE module1_run_id=(SELECT run_id FROM run_context)) AS comparison_rows,
        (SELECT count(*) FROM msbf_m2.application_booking_funding_activation_latest WHERE module1_run_id=(SELECT run_id FROM run_context) AND activation_outcome_code='BOOKED_FUNDED_PORTFOLIO_ACTIVATED') AS activated_rows,
        (SELECT count(*) FROM msbf_m2.application_booking_funding_activation_latest WHERE module1_run_id=(SELECT run_id FROM run_context) AND activation_outcome_code='ACTIVATION_REVIEW_REQUIRED') AS review_rows,
        (SELECT count(*) FROM msbf_m2.application_booking_funding_activation_latest WHERE module1_run_id=(SELECT run_id FROM run_context) AND activation_outcome_code='NOT_ACTIVATED_INSUFFICIENT_EVIDENCE') AS insufficient_rows,
        (SELECT count(*) FROM msbf_m2.application_booking_funding_activation_latest WHERE module1_run_id=(SELECT run_id FROM run_context) AND activation_outcome_code='NOT_ACTIVATED_POLICY_DECLINE') AS policy_rows_not_activated,
        (SELECT count(*) FROM msbf_m2.v_m2_4_matched_scenario_comparison WHERE module1_run_id=(SELECT run_id FROM run_context) AND (stress_activation_improvement_flag OR stress_funded_amount_improvement_flag)) AS stress_improvement_rows,
        (SELECT count(*) FROM msbf_m2.application_booking_funding_activation_latest WHERE module1_run_id=(SELECT run_id FROM run_context) AND NOT portfolio_activated_flag AND (funded_amount IS NOT NULL OR synthetic_account_id IS NOT NULL OR synthetic_advance_id IS NOT NULL)) AS nonactivated_value_rows,
        (SELECT count(*) FROM msbf_m2.application_booking_funding_activation_latest WHERE module1_run_id=(SELECT run_id FROM run_context) AND (real_funds_movement_flag OR external_notice_generation_authorized_flag OR external_notice_transmitted_flag OR production_adverse_action_notice_flag)) AS boundary_flag_rows,
        (SELECT count(*) FROM msbf_m2.application_booking_funding_activation_latest AS latest JOIN msbf_m2.application_booking_funding_activation_archive AS archive ON archive.module1_run_id=latest.module1_run_id AND archive.contract_version=latest.contract_version AND archive.scenario_id=latest.scenario_id AND archive.merchant_application_id=latest.merchant_application_id WHERE latest.module1_run_id=(SELECT run_id FROM run_context) AND (archive.contract_row_hash IS DISTINCT FROM latest.contract_row_hash OR archive.contract_payload IS DISTINCT FROM (to_jsonb(latest)-'created_at'))) AS archive_mismatches,
        (SELECT count(*) FROM msbf_m2.application_booking_funding_activation_latest AS latest LEFT JOIN msbf_m2.synthetic_account_activation AS account ON account.module1_run_id=latest.module1_run_id AND account.scenario_id=latest.scenario_id AND account.merchant_application_id=latest.merchant_application_id LEFT JOIN msbf_m2.synthetic_advance_funding AS advance ON advance.module1_run_id=latest.module1_run_id AND advance.scenario_id=latest.scenario_id AND advance.merchant_application_id=latest.merchant_application_id LEFT JOIN msbf_m2.initial_portfolio_activation AS portfolio ON portfolio.module1_run_id=latest.module1_run_id AND portfolio.scenario_id=latest.scenario_id AND portfolio.merchant_application_id=latest.merchant_application_id WHERE latest.module1_run_id=(SELECT run_id FROM run_context) AND ((latest.portfolio_activated_flag AND (account.row_hash IS NULL OR advance.row_hash IS NULL OR portfolio.row_hash IS NULL)) OR (NOT latest.portfolio_activated_flag AND (account.row_hash IS NOT NULL OR advance.row_hash IS NOT NULL OR portfolio.row_hash IS NOT NULL)))) AS activation_link_mismatches,
        (SELECT count(*) FROM msbf_m2.application_booking_funding_activation_latest AS activation WHERE activation.module1_run_id=(SELECT run_id FROM run_context) AND EXISTS (SELECT 1 FROM jsonb_array_elements_text(activation.activation_reason_codes) AS reason_value WHERE NOT EXISTS (SELECT 1 FROM msbf_m2.booking_funding_reason_definition AS reason WHERE reason.module1_run_id=activation.module1_run_id AND reason.activation_reason_code=reason_value.value AND reason.mapped_activation_outcome_code=activation.activation_outcome_code))) AS reason_mapping_mismatches,
        (SELECT count(*) FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM run_context) AND gate_id='M2_4_BOOKING_FUNDING_PORTFOLIO_ACTIVATION') AS existing_gate_rows
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
    physical.notice_rows,
    physical.source_rows,
    physical.snapshot_rows,
    physical.latest_rows,
    physical.archive_rows,
    physical.account_rows,
    physical.advance_rows,
    physical.portfolio_rows,
    physical.comparison_rows,
    physical.activated_rows,
    physical.review_rows,
    physical.insufficient_rows,
    physical.policy_rows_not_activated,
    physical.stress_improvement_rows,
    physical.nonactivated_value_rows,
    physical.boundary_flag_rows,
    physical.archive_mismatches,
    physical.activation_link_mismatches,
    physical.reason_mapping_mismatches,
    physical.existing_gate_rows,
    registry.canonical_entities,
    registry.contract_set_hash,
    registry.combined_set_hash,
    CASE
        WHEN run_context.run_status='M2_4_VALIDATED'
         AND registry.contract_status='VALIDATED'
         AND controls.positive_checks=120
         AND controls.positive_passes=120
         AND controls.positive_failures=0
         AND controls.negative_checks=20
         AND controls.negative_passes=20
         AND controls.negative_failures=0
         AND physical.policy_rows=1
         AND physical.outcome_rows=5
         AND physical.reason_rows=24
         AND physical.notice_rows=4
         AND physical.source_rows=1500
         AND physical.snapshot_rows=1500
         AND physical.latest_rows=1500
         AND physical.archive_rows=1500
         AND physical.account_rows=59
         AND physical.advance_rows=59
         AND physical.portfolio_rows=59
         AND physical.comparison_rows=750
         AND physical.activated_rows=59
         AND physical.review_rows=190
         AND physical.insufficient_rows=178
         AND physical.policy_rows_not_activated=1073
         AND physical.stress_improvement_rows=0
         AND physical.nonactivated_value_rows=0
         AND physical.boundary_flag_rows=0
         AND physical.archive_mismatches=0
         AND physical.activation_link_mismatches=0
         AND physical.reason_mapping_mismatches=0
         AND physical.existing_gate_rows=0
         AND registry.canonical_entities=6212
         AND registry.contract_set_hash IS NOT NULL
         AND registry.combined_set_hash IS NOT NULL
        THEN 'PASS'
        ELSE 'FAIL'
    END AS acceptance_status
FROM run_context
CROSS JOIN registry
CROSS JOIN controls
CROSS JOIN physical;

/* --------------------------------------------------------------------------
Phase 2 — Fail-closed acceptance precondition and lifecycle assertion
-------------------------------------------------------------------------- */
DO $m2_4_acceptance_guard$
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
        source_rows,
        latest_rows,
        account_rows,
        advance_rows,
        portfolio_rows,
        stress_improvement_rows,
        nonactivated_value_rows,
        boundary_flag_rows,
        archive_mismatches,
        activation_link_mismatches,
        reason_mapping_mismatches,
        canonical_entities,
        combined_set_hash,
        acceptance_status
    INTO v
    FROM _m2_4_acceptance;

    IF v.acceptance_status <> 'PASS' THEN
        RAISE EXCEPTION
            'M2.4 acceptance preconditions failed: %',
            row_to_json(v);
    END IF;

    PERFORM msbf_ctl.m2_4_assert_acceptance_ready(v.run_id);
END;
$m2_4_acceptance_guard$;

/* --------------------------------------------------------------------------
Phase 3 — Persist one-valued acceptance evidence and issue the gate
-------------------------------------------------------------------------- */
DROP TABLE IF EXISTS _m2_4_acceptance_evidence;

CREATE TEMP TABLE _m2_4_acceptance_evidence
(
    run_id               bigint NOT NULL,
    evidence_code        text NOT NULL,
    segment_key          text NOT NULL,
    metric_name          text NOT NULL,
    metric_value_numeric numeric(24,10),
    metric_value_text    text,
    unit_code            text NOT NULL,
    status               text NOT NULL,
    interpretation       text NOT NULL,
    CHECK(num_nonnulls(metric_value_numeric,metric_value_text)=1)
)
ON COMMIT DROP;

INSERT INTO _m2_4_acceptance_evidence
SELECT
    run_id,
    'M2_4_ACCEPTANCE_SUMMARY',
    'PORTFOLIO',
    'M2_4_BOOKING_FUNDING_PORTFOLIO_ACTIVATION_ACCEPTANCE',
    NULL::numeric(24,10),
    combined_set_hash,
    'ACCEPTANCE',
    'PASS',
    'Formal M2.4 acceptance: synthetic booking, funding and portfolio activation contract accepted with 120 positive controls, 20 negative controls, zero stress improvements, zero archive/link mismatches, and no real-world movement or notice violations.'
FROM _m2_4_acceptance;

UPDATE msbf_ctl.m2_4_portfolio_activation_contract_registry
SET
    contract_status='ACCEPTED',
    accepted_at=clock_timestamp()
WHERE module1_run_id=(SELECT run_id FROM _m2_4_acceptance);

UPDATE msbf_ctl.run_registry
SET
    run_status='M2_4_ACCEPTED',
    notes=coalesce(notes,'') ||
        ' | M2.4 synthetic booking, funding and portfolio activation accepted.'
WHERE run_id=(SELECT run_id FROM _m2_4_acceptance);

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
    'M2_4_BOOKING_FUNDING_PORTFOLIO_ACTIVATION',
    1,
    'PASS',
    combined_set_hash,
    '120/120 positive; 20/20 negative; zero deterministic, stress, archive, activation-link, real-funds, notice, or adverse-action violations',
    'M2.4 synthetic booking, funding and portfolio activation accepted.',
    'All account, advance, funding and portfolio records are synthetic; no real funds movement, external transmission, or production adverse-action notice occurs.',
    'Independent Validation / Project Owner'
FROM _m2_4_acceptance;

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
FROM _m2_4_acceptance_evidence AS evidence;

/* --------------------------------------------------------------------------
Phase 4 — Independently verify committed lifecycle and gate status
-------------------------------------------------------------------------- */
ALTER TABLE _m2_4_acceptance
    ADD COLUMN final_run_status text,
    ADD COLUMN final_contract_status text,
    ADD COLUMN gate_status text;

UPDATE _m2_4_acceptance AS acceptance
SET
    final_run_status=(SELECT run_status FROM msbf_ctl.run_registry WHERE run_id=acceptance.run_id),
    final_contract_status=(SELECT contract_status FROM msbf_ctl.m2_4_portfolio_activation_contract_registry WHERE module1_run_id=acceptance.run_id),
    gate_status=(SELECT result_status FROM msbf_ctl.acceptance_gate_result WHERE run_id=acceptance.run_id AND gate_id='M2_4_BOOKING_FUNDING_PORTFOLIO_ACTIVATION' AND review_version=1);

DO $m2_4_acceptance_final_guard$
DECLARE
    v record;
BEGIN
    SELECT
        final_run_status,
        final_contract_status,
        gate_status
    INTO v
    FROM _m2_4_acceptance;

    IF v.final_run_status <> 'M2_4_ACCEPTED'
       OR v.final_contract_status <> 'ACCEPTED'
       OR v.gate_status <> 'PASS' THEN
        RAISE EXCEPTION
            'M2.4 final acceptance state failed: %',
            row_to_json(v);
    END IF;
END;
$m2_4_acceptance_final_guard$;

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
    notice_rows,
    source_rows,
    snapshot_rows,
    latest_rows,
    archive_rows,
    account_rows,
    advance_rows,
    portfolio_rows,
    comparison_rows,
    activated_rows,
    review_rows,
    insufficient_rows,
    policy_rows_not_activated,
    stress_improvement_rows,
    nonactivated_value_rows,
    boundary_flag_rows,
    archive_mismatches,
    activation_link_mismatches,
    reason_mapping_mismatches,
    existing_gate_rows,
    canonical_entities,
    contract_set_hash,
    combined_set_hash,
    acceptance_status,
    final_run_status,
    final_contract_status,
    gate_status
FROM _m2_4_acceptance;
