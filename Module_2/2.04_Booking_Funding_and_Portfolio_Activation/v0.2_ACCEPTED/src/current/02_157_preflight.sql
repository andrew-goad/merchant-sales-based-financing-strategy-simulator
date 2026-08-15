/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.4 — Booking, Funding & Portfolio Activation

Program     : 157_msbf_m2_4_preflight_validation_v0_2.sql
Version     : v0.2
Purpose     : Fail closed unless accepted M2.3 source contracts, the M2.4
              policy, activation/reason/notice dictionaries, acceptance-gate
              registration, empty target tables, and exact operational stage
              boundaries are ready for deterministic generation.

Writes      : None. Result table is session-scoped and filterable.
Required    : preflight_status = PASS.
============================================================================ */

SET statement_timeout = '25min';
SET jit = off;

/* --------------------------------------------------------------------------
Phase 1 — Reconstruct accepted source, policy, dictionaries and empty targets
-------------------------------------------------------------------------- */
DROP TABLE IF EXISTS _m2_4_preflight;

CREATE TEMP TABLE _m2_4_preflight
ON COMMIT PRESERVE ROWS
AS
WITH run_context AS
(
    SELECT run_id, run_status
    FROM msbf_ctl.run_registry
    WHERE run_code = 'M1_V0_2_BASELINE_BUILD'
      AND run_version = 1
),
policy AS
(
    SELECT
        module1_run_id,
        policy_code,
        policy_version,
        policy_status,
        methodology_version,
        contract_code,
        contract_version,
        schema_version,
        source_m2_3_contract_code,
        source_m2_3_contract_version,
        source_m2_3_schema_version,
        source_m2_3_combined_hash,
        source_m2_3_acceptance_gate_id,
        synthetic_booking_enabled_flag,
        synthetic_funding_enabled_flag,
        portfolio_activation_enabled_flag,
        synthetic_offer_acceptance_assumed_flag,
        real_funds_movement_prohibited_flag,
        external_notice_transmission_prohibited_flag,
        production_adverse_action_notice_prohibited_flag,
        review_routes_not_bookable_flag,
        decline_routes_not_bookable_flag,
        duplicate_activation_prohibited_flag,
        source_decision_immutable_flag,
        stress_nonimprovement_required_flag,
        expected_canonical_entities,
        configuration_hash
    FROM msbf_ctl.m2_4_policy_profile
    WHERE module1_run_id = (SELECT run_id FROM run_context)
      AND policy_code = 'M2_4_BOOKING_FUNDING_ACTIVATION_POLICY_V1'
),
source_registry AS
(
    SELECT
        count(*)::bigint AS registry_rows,
        max(contract_status) AS contract_status,
        max(contract_code) AS contract_code,
        max(contract_version) AS contract_version,
        max(schema_version) AS schema_version,
        max(combined_set_hash) AS combined_set_hash,
        max(decision_latest_rows) AS latest_rows,
        max(decision_archive_rows) AS archive_rows,
        max(comparison_rows) AS comparison_rows,
        max(canonical_entities) AS canonical_entities
    FROM msbf_ctl.m2_3_final_decision_contract_registry
    WHERE module1_run_id = (SELECT run_id FROM run_context)
),
source_gate AS
(
    SELECT
        count(*)::bigint AS gate_rows,
        max(result_status) AS gate_status
    FROM msbf_ctl.acceptance_gate_result
    WHERE run_id = (SELECT run_id FROM run_context)
      AND gate_id = 'M2_3_FINAL_OFFER_DECISION_AUTHORIZATION'
      AND review_version = 1
),
source_latest AS
(
    SELECT
        count(*)::bigint AS source_rows,
        count(DISTINCT merchant_application_id)::bigint AS applications,
        count(DISTINCT scenario_id)::bigint AS scenarios,
        count(*) FILTER (WHERE scenario_code = 'BASELINE')::bigint AS baseline_rows,
        count(*) FILTER (WHERE scenario_code = 'RECESSION_ENERGY')::bigint AS stress_rows,
        count(*) FILTER (WHERE final_decision_outcome_code = 'FINAL_OFFER_AUTHORIZED')::bigint AS final_offer_rows,
        count(*) FILTER (WHERE final_decision_outcome_code = 'COUNTEROFFER_REVIEW_REQUIRED')::bigint AS review_rows,
        count(*) FILTER (WHERE final_decision_outcome_code = 'DECLINE_INSUFFICIENT_EVIDENCE_AUTHORIZED')::bigint AS insufficient_rows,
        count(*) FILTER (WHERE final_decision_outcome_code = 'DECLINE_POLICY_AUTHORIZED')::bigint AS policy_decline_rows,
        count(*) FILTER
        (
            WHERE module1_run_id IS NULL
               OR scenario_id IS NULL
               OR scenario_code IS NULL
               OR merchant_application_id IS NULL
               OR contract_row_hash IS NULL
               OR source_m2_2_contract_row_hash IS NULL
               OR source_g2_combined_hash IS NULL
        )::bigint AS required_key_nulls,
        count(*) FILTER
        (
            WHERE final_offer_authorized_flag
              AND
              (
                  final_offer_amount IS NULL
                  OR final_remittance_rate IS NULL
                  OR final_payback_multiple IS NULL
                  OR final_collection_horizon_days IS NULL
              )
        )::bigint AS incomplete_offer_rows,
        count(*) FILTER
        (
            WHERE NOT final_offer_authorized_flag
              AND
              (
                  final_offer_amount IS NOT NULL
                  OR final_remittance_rate IS NOT NULL
                  OR final_payback_multiple IS NOT NULL
                  OR final_collection_horizon_days IS NOT NULL
              )
        )::bigint AS prohibited_nonoffer_terms
    FROM msbf_m2.application_final_offer_decision_latest
    WHERE module1_run_id = (SELECT run_id FROM run_context)
),
definitions AS
(
    SELECT
        (SELECT count(*) FROM msbf_m2.booking_funding_activation_outcome_definition
         WHERE module1_run_id = (SELECT run_id FROM run_context)
           AND outcome_status = 'APPROVED')::bigint AS outcome_rows,
        (SELECT count(*) FROM msbf_m2.booking_funding_reason_definition
         WHERE module1_run_id = (SELECT run_id FROM run_context)
           AND reason_status = 'APPROVED')::bigint AS reason_rows,
        (SELECT count(*) FROM msbf_m2.external_notice_control_definition
         WHERE module1_run_id = (SELECT run_id FROM run_context)
           AND control_status = 'APPROVED')::bigint AS notice_rows,
        (SELECT count(*) FROM msbf_m2.booking_funding_activation_outcome_definition
         WHERE module1_run_id = (SELECT run_id FROM run_context)
           AND
           (
               external_notice_transmission_flag
               OR production_adverse_action_notice_flag
               OR real_funds_movement_flag
           ))::bigint AS prohibited_outcome_flags,
        (SELECT count(*) FROM msbf_m2.booking_funding_reason_definition
         WHERE module1_run_id = (SELECT run_id FROM run_context)
           AND production_adverse_action_notice_flag)::bigint AS prohibited_reason_flags,
        (SELECT count(*) FROM msbf_m2.external_notice_control_definition
         WHERE module1_run_id = (SELECT run_id FROM run_context)
           AND
           (
               external_transmission_authorized_flag
               OR production_adverse_action_notice_flag
           ))::bigint AS prohibited_notice_flags
),
gate_catalog AS
(
    SELECT count(*)::bigint AS gate_catalog_rows
    FROM msbf_ref.acceptance_gate_catalog
    WHERE gate_id = 'M2_4_BOOKING_FUNDING_PORTFOLIO_ACTIVATION'
      AND active_flag
),
targets AS
(
    SELECT
        (SELECT count(*) FROM msbf_m2.application_booking_funding_source_snapshot
         WHERE module1_run_id = (SELECT run_id FROM run_context))::bigint AS source_snapshot_rows,
        (SELECT count(*) FROM msbf_m2.application_booking_funding_activation_snapshot
         WHERE module1_run_id = (SELECT run_id FROM run_context))::bigint AS activation_snapshot_rows,
        (SELECT count(*) FROM msbf_m2.application_booking_funding_activation_latest
         WHERE module1_run_id = (SELECT run_id FROM run_context))::bigint AS latest_rows,
        (SELECT count(*) FROM msbf_m2.application_booking_funding_activation_archive
         WHERE module1_run_id = (SELECT run_id FROM run_context))::bigint AS archive_rows,
        (SELECT count(*) FROM msbf_m2.synthetic_account_activation
         WHERE module1_run_id = (SELECT run_id FROM run_context))::bigint AS account_rows,
        (SELECT count(*) FROM msbf_m2.synthetic_advance_funding
         WHERE module1_run_id = (SELECT run_id FROM run_context))::bigint AS advance_rows,
        (SELECT count(*) FROM msbf_m2.initial_portfolio_activation
         WHERE module1_run_id = (SELECT run_id FROM run_context))::bigint AS portfolio_rows,
        (SELECT count(*) FROM msbf_ctl.m2_4_portfolio_activation_contract_registry
         WHERE module1_run_id = (SELECT run_id FROM run_context))::bigint AS registry_rows,
        (SELECT count(*) FROM msbf_ctl.run_evidence
         WHERE run_id = (SELECT run_id FROM run_context)
           AND evidence_code LIKE 'M2_4_%')::bigint AS evidence_rows,
        (SELECT count(*) FROM msbf_ctl.acceptance_gate_result
         WHERE run_id = (SELECT run_id FROM run_context)
           AND gate_id = 'M2_4_BOOKING_FUNDING_PORTFOLIO_ACTIVATION')::bigint AS acceptance_rows,
        (SELECT count(*) FROM information_schema.tables
         WHERE table_schema IN ('msbf_m2','msbf_ctl')
           AND lower(table_name) LIKE 'm2_5%')::bigint AS m2_5_tables,
        (SELECT count(*) FROM information_schema.columns
         WHERE table_schema = 'msbf_m2'
           AND table_name IN
           (
               'application_booking_funding_activation_snapshot',
               'application_booking_funding_activation_latest',
               'application_booking_funding_activation_archive',
               'synthetic_account_activation',
               'synthetic_advance_funding',
               'initial_portfolio_activation'
           )
           AND lower(column_name) IN
           (
               'ach_trace_number',
               'bank_account_number',
               'settlement_account_number',
               'routing_number',
               'real_account_number',
               'core_booking_id',
               'external_notice_payload',
               'production_adverse_action_notice'
           ))::bigint AS prohibited_real_world_columns
)
SELECT
    run_context.run_id,
    run_context.run_status,
    policy.policy_status,
    policy.methodology_version,
    policy.contract_code,
    policy.contract_version,
    policy.schema_version,
    policy.configuration_hash,
    policy.synthetic_booking_enabled_flag,
    policy.synthetic_funding_enabled_flag,
    policy.portfolio_activation_enabled_flag,
    policy.synthetic_offer_acceptance_assumed_flag,
    policy.real_funds_movement_prohibited_flag,
    policy.external_notice_transmission_prohibited_flag,
    policy.production_adverse_action_notice_prohibited_flag,
    source_registry.registry_rows AS source_registry_rows,
    source_registry.contract_status AS source_contract_status,
    source_registry.contract_code AS source_contract_code,
    source_registry.contract_version AS source_contract_version,
    source_registry.schema_version AS source_schema_version,
    source_registry.combined_set_hash AS source_combined_hash,
    source_gate.gate_rows AS source_gate_rows,
    source_gate.gate_status AS source_gate_status,
    source_latest.source_rows,
    source_latest.applications,
    source_latest.scenarios,
    source_latest.baseline_rows,
    source_latest.stress_rows,
    source_latest.final_offer_rows,
    source_latest.review_rows,
    source_latest.insufficient_rows,
    source_latest.policy_decline_rows,
    source_latest.required_key_nulls,
    source_latest.incomplete_offer_rows,
    source_latest.prohibited_nonoffer_terms,
    definitions.outcome_rows,
    definitions.reason_rows,
    definitions.notice_rows,
    definitions.prohibited_outcome_flags,
    definitions.prohibited_reason_flags,
    definitions.prohibited_notice_flags,
    gate_catalog.gate_catalog_rows,
    targets.source_snapshot_rows AS target_source_snapshot_rows,
    targets.activation_snapshot_rows AS target_activation_snapshot_rows,
    targets.latest_rows AS target_latest_rows,
    targets.archive_rows AS target_archive_rows,
    targets.account_rows AS target_account_rows,
    targets.advance_rows AS target_advance_rows,
    targets.portfolio_rows AS target_portfolio_rows,
    targets.registry_rows AS target_registry_rows,
    targets.evidence_rows AS target_evidence_rows,
    targets.acceptance_rows AS target_acceptance_rows,
    targets.m2_5_tables,
    targets.prohibited_real_world_columns,
    CASE
        WHEN run_context.run_status = 'M2_3_ACCEPTED'
         AND policy.policy_status = 'APPROVED'
         AND policy.methodology_version = 'M2_4_METHOD_V1'
         AND policy.contract_code = 'M2_PORTFOLIO_ACTIVATION_CONSUMPTION'
         AND policy.contract_version = 1
         AND policy.schema_version = 'M2_4_PORTFOLIO_ACTIVATION_SCHEMA_V1'
         AND policy.synthetic_booking_enabled_flag
         AND policy.synthetic_funding_enabled_flag
         AND policy.portfolio_activation_enabled_flag
         AND policy.synthetic_offer_acceptance_assumed_flag
         AND policy.real_funds_movement_prohibited_flag
         AND policy.external_notice_transmission_prohibited_flag
         AND policy.production_adverse_action_notice_prohibited_flag
         AND source_registry.registry_rows = 1
         AND source_registry.contract_status = 'ACCEPTED'
         AND source_registry.contract_code = 'M2_FINAL_OFFER_DECISION_CONSUMPTION'
         AND source_registry.contract_version = 1
         AND source_registry.schema_version = 'M2_3_FINAL_DECISION_SCHEMA_V1'
         AND source_registry.combined_set_hash = 'bf09349b06ede7e5a2ec830c2f9ffe90'
         AND source_gate.gate_rows = 1
         AND source_gate.gate_status = 'PASS'
         AND source_latest.source_rows = 1500
         AND source_latest.applications = 750
         AND source_latest.scenarios = 2
         AND source_latest.baseline_rows = 750
         AND source_latest.stress_rows = 750
         AND source_latest.final_offer_rows = 59
         AND source_latest.review_rows = 190
         AND source_latest.insufficient_rows = 178
         AND source_latest.policy_decline_rows = 1073
         AND source_latest.required_key_nulls = 0
         AND source_latest.incomplete_offer_rows = 0
         AND source_latest.prohibited_nonoffer_terms = 0
         AND definitions.outcome_rows = 5
         AND definitions.reason_rows = 24
         AND definitions.notice_rows = 4
         AND definitions.prohibited_outcome_flags = 0
         AND definitions.prohibited_reason_flags = 0
         AND definitions.prohibited_notice_flags = 0
         AND gate_catalog.gate_catalog_rows = 1
         AND targets.source_snapshot_rows = 0
         AND targets.activation_snapshot_rows = 0
         AND targets.latest_rows = 0
         AND targets.archive_rows = 0
         AND targets.account_rows = 0
         AND targets.advance_rows = 0
         AND targets.portfolio_rows = 0
         AND targets.registry_rows = 0
         AND targets.evidence_rows = 0
         AND targets.acceptance_rows = 0
         AND targets.m2_5_tables = 0
         AND targets.prohibited_real_world_columns = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END AS preflight_status
FROM run_context
CROSS JOIN policy
CROSS JOIN source_registry
CROSS JOIN source_gate
CROSS JOIN source_latest
CROSS JOIN definitions
CROSS JOIN gate_catalog
CROSS JOIN targets;

/* --------------------------------------------------------------------------
Phase 2 — Fail closed and invoke the persistent generation-readiness assertion
-------------------------------------------------------------------------- */
DO $m2_4_preflight_guard$
DECLARE
    v record;
BEGIN
    SELECT
        run_id,
        run_status,
        policy_status,
        source_contract_status,
        source_gate_status,
        source_rows,
        final_offer_rows,
        review_rows,
        insufficient_rows,
        policy_decline_rows,
        outcome_rows,
        reason_rows,
        notice_rows,
        gate_catalog_rows,
        target_source_snapshot_rows,
        target_activation_snapshot_rows,
        target_latest_rows,
        target_archive_rows,
        target_account_rows,
        target_advance_rows,
        target_portfolio_rows,
        target_registry_rows,
        target_evidence_rows,
        target_acceptance_rows,
        m2_5_tables,
        prohibited_real_world_columns,
        preflight_status
    INTO v
    FROM _m2_4_preflight;

    IF v.preflight_status <> 'PASS' THEN
        RAISE EXCEPTION
            'M2.4 preflight failed: %',
            row_to_json(v);
    END IF;

    PERFORM msbf_ctl.m2_4_assert_generation_ready(v.run_id);
END;
$m2_4_preflight_guard$;

SELECT
    run_id,
    run_status,
    policy_status,
    methodology_version,
    contract_code,
    contract_version,
    schema_version,
    configuration_hash,
    source_registry_rows,
    source_contract_status,
    source_contract_code,
    source_contract_version,
    source_schema_version,
    source_combined_hash,
    source_gate_rows,
    source_gate_status,
    source_rows,
    applications,
    scenarios,
    baseline_rows,
    stress_rows,
    final_offer_rows,
    review_rows,
    insufficient_rows,
    policy_decline_rows,
    required_key_nulls,
    incomplete_offer_rows,
    prohibited_nonoffer_terms,
    outcome_rows,
    reason_rows,
    notice_rows,
    prohibited_outcome_flags,
    prohibited_reason_flags,
    prohibited_notice_flags,
    gate_catalog_rows,
    target_source_snapshot_rows,
    target_activation_snapshot_rows,
    target_latest_rows,
    target_archive_rows,
    target_account_rows,
    target_advance_rows,
    target_portfolio_rows,
    target_registry_rows,
    target_evidence_rows,
    target_acceptance_rows,
    m2_5_tables,
    prohibited_real_world_columns,
    preflight_status
FROM _m2_4_preflight;
