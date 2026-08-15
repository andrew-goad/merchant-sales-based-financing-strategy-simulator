/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.7 — Operational Activation & Account Setup

Program     : 185_msbf_m2_7_acceptance_finalize_v0_2.sql
Version     : v0.2

Purpose
-------
Independently verify source identity, controls, physical counts, exact campaign
mapping, setup terms, execution boundaries, stress non-improvement,
latest/archive reproduction, canonical identity, and acceptance readiness.

Required result
---------------
acceptance_status = PASS
final_run_status = M2_7_ACCEPTED
final_contract_status = ACCEPTED
gate_status = PASS.
============================================================================ */

BEGIN;

SET LOCAL work_mem='160MB';
SET LOCAL statement_timeout='45min';
SET LOCAL jit=off;

DROP TABLE IF EXISTS _m2_7_acceptance;

CREATE TEMP TABLE _m2_7_acceptance
ON COMMIT PRESERVE ROWS
AS
WITH run_context AS
(
    SELECT run_id,run_status
    FROM msbf_ctl.run_registry
    WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
),
registry AS
(
    SELECT *
    FROM msbf_ctl.m2_7_operational_activation_contract_registry
    WHERE module1_run_id=(SELECT run_id FROM run_context)
),
source_registry AS
(
    SELECT
        contract_status,contract_code,contract_version,schema_version,
        combined_set_hash
    FROM msbf_ctl.m2_6_intervention_strategy_contract_registry
    WHERE module1_run_id=(SELECT run_id FROM run_context)
),
source_gate AS
(
    SELECT result_status AS gate_status
    FROM msbf_ctl.acceptance_gate_result
    WHERE run_id=(SELECT run_id FROM run_context)
      AND gate_id='M2_6_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY'
      AND review_version=1
),
controls AS
(
    SELECT
        count(*) FILTER(WHERE evidence_code LIKE 'M2_7_POS_%')::bigint
            AS positive_checks,
        count(*) FILTER
        (
            WHERE evidence_code LIKE 'M2_7_POS_%' AND status='PASS'
        )::bigint AS positive_passes,
        count(*) FILTER
        (
            WHERE evidence_code LIKE 'M2_7_POS_%' AND status<>'PASS'
        )::bigint AS positive_failures,
        count(*) FILTER(WHERE evidence_code LIKE 'M2_7_NEG_%')::bigint
            AS negative_checks,
        count(*) FILTER
        (
            WHERE evidence_code LIKE 'M2_7_NEG_%' AND status='PASS'
        )::bigint AS negative_passes,
        count(*) FILTER
        (
            WHERE evidence_code LIKE 'M2_7_NEG_%' AND status<>'PASS'
        )::bigint AS negative_failures,
        count(*) FILTER
        (
            WHERE evidence_code LIKE 'M2_7_%'
              AND evidence_code NOT LIKE 'M2_7_POS_%'
              AND evidence_code NOT LIKE 'M2_7_NEG_%'
              AND evidence_code<>'M2_7_ACCEPTANCE_SUMMARY'
        )::bigint AS generation_evidence_rows,
        count(*) FILTER
        (
            WHERE evidence_code LIKE 'M2_7_%' AND status='FAIL'
        )::bigint AS failed_evidence_rows
    FROM msbf_ctl.run_evidence
    WHERE run_id=(SELECT run_id FROM run_context)
),
physical AS
(
    SELECT
        (SELECT count(*) FROM msbf_ctl.m2_7_policy_profile WHERE module1_run_id=(SELECT run_id FROM run_context))::bigint AS policy_rows,
        (SELECT count(*) FROM msbf_m2.operational_setup_outcome_definition WHERE module1_run_id=(SELECT run_id FROM run_context))::bigint AS outcome_rows,
        (SELECT count(*) FROM msbf_m2.operational_setup_action_definition WHERE module1_run_id=(SELECT run_id FROM run_context))::bigint AS action_rows,
        (SELECT count(*) FROM msbf_m2.operational_setup_reason_definition WHERE module1_run_id=(SELECT run_id FROM run_context))::bigint AS reason_rows,
        (SELECT count(*) FROM msbf_m2.operational_activation_source_snapshot WHERE module1_run_id=(SELECT run_id FROM run_context))::bigint AS source_rows,
        (SELECT count(*) FROM msbf_m2.application_operational_activation_snapshot WHERE module1_run_id=(SELECT run_id FROM run_context))::bigint AS activation_rows,
        (SELECT count(*) FROM msbf_m2.operational_account_setup_snapshot WHERE module1_run_id=(SELECT run_id FROM run_context))::bigint AS setup_rows,
        (SELECT count(*) FROM msbf_m2.operational_activation_portfolio_summary WHERE module1_run_id=(SELECT run_id FROM run_context))::bigint AS portfolio_rows,
        (SELECT count(*) FROM msbf_m2.application_operational_activation_latest WHERE module1_run_id=(SELECT run_id FROM run_context))::bigint AS latest_rows,
        (SELECT count(*) FROM msbf_m2.application_operational_activation_archive WHERE module1_run_id=(SELECT run_id FROM run_context))::bigint AS archive_rows,
        (SELECT count(*) FROM msbf_m2.v_m2_7_matched_scenario_comparison WHERE module1_run_id=(SELECT run_id FROM run_context))::bigint AS comparison_rows,

        (SELECT count(*) FROM msbf_m2.application_operational_activation_snapshot WHERE module1_run_id=(SELECT run_id FROM run_context) AND (real_core_account_created_flag OR real_payment_change_executed_flag OR bank_account_data_present_flag OR ach_or_network_transmission_flag OR external_notice_generated_flag OR merchant_contact_executed_flag OR write_off_posted_flag OR collection_or_legal_executed_flag OR production_adverse_action_flag))::bigint AS activation_boundary_rows,

        (SELECT count(*) FROM msbf_m2.operational_account_setup_snapshot WHERE module1_run_id=(SELECT run_id FROM run_context) AND (real_core_account_created_flag OR real_payment_change_executed_flag OR bank_account_data_present_flag OR ach_or_network_transmission_flag OR external_notice_generated_flag OR merchant_contact_executed_flag OR write_off_posted_flag OR collection_or_legal_executed_flag OR production_adverse_action_flag))::bigint AS setup_boundary_rows,

        (SELECT count(*) FROM msbf_m2.v_m2_7_matched_scenario_comparison WHERE module1_run_id=(SELECT run_id FROM run_context) AND (stress_setup_permission_improvement_flag OR stress_priority_improvement_flag))::bigint AS stress_improvement_rows,

        (SELECT count(*) FROM msbf_m2.application_operational_activation_latest AS l FULL OUTER JOIN msbf_m2.application_operational_activation_archive AS a ON a.module1_run_id=l.module1_run_id AND a.contract_version=l.contract_version AND a.scenario_id=l.scenario_id AND a.merchant_application_id=l.merchant_application_id WHERE coalesce(l.module1_run_id,a.module1_run_id)=(SELECT run_id FROM run_context) AND (l.contract_row_hash IS DISTINCT FROM a.contract_row_hash OR a.contract_payload IS DISTINCT FROM (to_jsonb(l)-'created_at')))::bigint AS archive_mismatches,

        (SELECT count(*) FROM information_schema.columns WHERE table_schema='msbf_m2' AND table_name IN ('application_operational_activation_snapshot','operational_account_setup_snapshot','application_operational_activation_latest','application_operational_activation_archive') AND lower(column_name) IN ('real_core_account_number','bank_account_number','routing_number','settlement_account_number','ach_trace_number','payment_network_confirmation','external_notice_payload','production_adverse_action_notice'))::bigint AS prohibited_columns,

        (SELECT count(*) FROM information_schema.tables WHERE table_schema IN ('msbf_ctl','msbf_m2') AND lower(table_name) LIKE 'm2_8%')::bigint AS premature_m2_8_tables,

        (SELECT count(*) FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM run_context) AND gate_id='M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP')::bigint AS existing_gate_rows,

        (SELECT count(*) FROM msbf_ctl.profile_resolution_error WHERE run_id=(SELECT run_id FROM run_context) AND severity='BLOCKING')::bigint AS blocking_errors,

        (SELECT canonical_entities FROM msbf_m2.v_m2_7_canonical_hash WHERE module1_run_id=(SELECT run_id FROM run_context))::bigint AS physical_canonical_entities,
        (SELECT combined_set_hash FROM msbf_m2.v_m2_7_canonical_hash WHERE module1_run_id=(SELECT run_id FROM run_context)) AS physical_combined_set_hash
)
SELECT
    run_context.run_id,
    run_context.run_status AS prior_run_status,
    registry.contract_status AS prior_contract_status,

    source_registry.contract_status AS source_contract_status,
    source_registry.contract_code AS source_contract_code,
    source_registry.contract_version AS source_contract_version,
    source_registry.schema_version AS source_schema_version,
    source_registry.combined_set_hash AS source_combined_set_hash,
    source_gate.gate_status AS source_gate_status,

    controls.positive_checks,controls.positive_passes,
    controls.positive_failures,controls.negative_checks,
    controls.negative_passes,controls.negative_failures,
    controls.generation_evidence_rows,controls.failed_evidence_rows,

    physical.policy_rows,physical.outcome_rows,physical.action_rows,
    physical.reason_rows,physical.source_rows,physical.activation_rows,
    physical.setup_rows,physical.portfolio_rows,physical.latest_rows,
    physical.archive_rows,physical.comparison_rows,
    physical.activation_boundary_rows,physical.setup_boundary_rows,
    physical.stress_improvement_rows,physical.archive_mismatches,
    physical.prohibited_columns,physical.premature_m2_8_tables,
    physical.existing_gate_rows,physical.blocking_errors,
    physical.physical_canonical_entities,
    physical.physical_combined_set_hash,

    registry.no_setup_required_rows,
    registry.temporary_adjustment_setup_rows,
    registry.review_required_rows,
    registry.setup_authorized_rows,
    registry.setup_authorized_amount,
    registry.review_required_amount,
    registry.canonical_entities,
    registry.contract_set_hash,
    registry.combined_set_hash,

    CASE
        WHEN run_context.run_status='M2_7_VALIDATED'
         AND registry.contract_status='VALIDATED'

         AND source_registry.contract_status='ACCEPTED'
         AND source_registry.contract_code='M2_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_CONSUMPTION'
         AND source_registry.contract_version=1
         AND source_registry.schema_version='M2_6_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_SCHEMA_V1'
         AND source_registry.combined_set_hash='868125bff29270490cab4d2e55cb1388'
         AND source_gate.gate_status='PASS'

         AND controls.positive_checks=120
         AND controls.positive_passes=120
         AND controls.positive_failures=0
         AND controls.negative_checks=20
         AND controls.negative_passes=20
         AND controls.negative_failures=0
         AND controls.generation_evidence_rows=24
         AND controls.failed_evidence_rows=0

         AND physical.policy_rows=1
         AND physical.outcome_rows=7
         AND physical.action_rows=7
         AND physical.reason_rows=28
         AND physical.source_rows=59
         AND physical.activation_rows=59
         AND physical.setup_rows=59
         AND physical.portfolio_rows=2
         AND physical.latest_rows=59
         AND physical.archive_rows=59
         AND physical.comparison_rows=15

         AND physical.activation_boundary_rows=0
         AND physical.setup_boundary_rows=0
         AND physical.stress_improvement_rows=0
         AND physical.archive_mismatches=0
         AND physical.prohibited_columns=0
         AND physical.premature_m2_8_tables=0
         AND physical.existing_gate_rows=0
         AND physical.blocking_errors=0

         AND registry.no_setup_required_rows=57
         AND registry.temporary_adjustment_setup_rows=1
         AND registry.review_required_rows=1
         AND registry.setup_authorized_rows=1
         AND registry.setup_authorized_amount=518.04
         AND registry.review_required_amount=461.69

         AND registry.canonical_entities=341
         AND physical.physical_canonical_entities=341
         AND registry.combined_set_hash IS NOT DISTINCT FROM
             physical.physical_combined_set_hash
         AND registry.contract_set_hash IS NOT NULL
         AND registry.combined_set_hash IS NOT NULL
        THEN 'PASS'
        ELSE 'FAIL'
    END AS acceptance_status
FROM run_context
CROSS JOIN registry
CROSS JOIN source_registry
CROSS JOIN source_gate
CROSS JOIN controls
CROSS JOIN physical;

DO $guard$
DECLARE
    v record;
BEGIN
    SELECT * INTO v FROM _m2_7_acceptance;

    IF v.acceptance_status<>'PASS' THEN
        RAISE EXCEPTION
            'M2.7 acceptance preconditions failed: %.',
            row_to_json(v);
    END IF;

    PERFORM msbf_ctl.m2_7_assert_acceptance_ready(v.run_id);
END;
$guard$;

INSERT INTO msbf_ctl.run_evidence
(
    run_id,evidence_code,segment_key,metric_name,
    metric_value_numeric,metric_value_text,unit_code,status,interpretation
)
SELECT
    run_id,'M2_7_ACCEPTANCE_SUMMARY','PORTFOLIO',
    'M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_ACCEPTANCE',
    NULL::numeric(28,10),combined_set_hash,'ACCEPTANCE','PASS',
    'Formal M2.7 acceptance: synthetic operational activation and account setup accepted with exact M2.6 lineage, 120 positive controls, 20 negative controls, zero real execution, zero stress improvements, zero archive mismatches, and zero blocking violations.'
FROM _m2_7_acceptance;

UPDATE msbf_ctl.m2_7_operational_activation_contract_registry
SET contract_status='ACCEPTED',accepted_at=clock_timestamp()
WHERE module1_run_id=(SELECT run_id FROM _m2_7_acceptance);

UPDATE msbf_ctl.run_registry
SET
    run_status='M2_7_ACCEPTED',
    notes=coalesce(notes,'')||
        ' | M2.7 operational activation and account setup accepted.'
WHERE run_id=(SELECT run_id FROM _m2_7_acceptance);

INSERT INTO msbf_ctl.acceptance_gate_result
(
    run_id,gate_id,review_version,result_status,observed_value,
    threshold_value,finding,residual_limitation,reviewer_role
)
SELECT
    run_id,'M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP',1,'PASS',combined_set_hash,
    '120/120 positive; 20/20 negative; exact source and canonical identity; 57 no-setup, 1 temporary blueprint, 1 review; zero real-execution, stress, archive, or stage-boundary violations',
    'M2.7 synthetic operational activation and account setup accepted.',
    'Synthetic setup blueprints only; no real account creation, payment change, bank data, payment-network transmission, contact, write-off, collection/legal action, or external/adverse-action notice.',
    'Independent Validation / Project Owner'
FROM _m2_7_acceptance;

ALTER TABLE _m2_7_acceptance
    ADD COLUMN final_run_status text,
    ADD COLUMN final_contract_status text,
    ADD COLUMN gate_status text;

UPDATE _m2_7_acceptance AS acceptance
SET
    final_run_status=
    (
        SELECT run_status
        FROM msbf_ctl.run_registry
        WHERE run_id=acceptance.run_id
    ),
    final_contract_status=
    (
        SELECT contract_status
        FROM msbf_ctl.m2_7_operational_activation_contract_registry
        WHERE module1_run_id=acceptance.run_id
    ),
    gate_status=
    (
        SELECT result_status
        FROM msbf_ctl.acceptance_gate_result
        WHERE run_id=acceptance.run_id
          AND gate_id='M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP'
          AND review_version=1
    );

DO $final_guard$
DECLARE
    v record;
BEGIN
    SELECT final_run_status,final_contract_status,gate_status
    INTO v
    FROM _m2_7_acceptance;

    IF v.final_run_status<>'M2_7_ACCEPTED'
       OR v.final_contract_status<>'ACCEPTED'
       OR v.gate_status<>'PASS'
    THEN
        RAISE EXCEPTION
            'M2.7 final acceptance state failed: %.',
            row_to_json(v);
    END IF;
END;
$final_guard$;

COMMIT;

SELECT * FROM _m2_7_acceptance;
