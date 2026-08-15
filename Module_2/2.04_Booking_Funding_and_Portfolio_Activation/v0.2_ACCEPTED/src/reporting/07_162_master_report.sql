/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.4 — Booking, Funding & Portfolio Activation

Program     : 162_MSBF_M2_4_Master_Report_v0_2.sql
Version     : v0.2
Purpose     : Produce one executive/governance row after M2.4 acceptance.
              The report reconciles lifecycle, source contract, physical
              cardinality, activation outcomes, operational sub-ledgers,
              controls, archive integrity, stress non-improvement and all
              synthetic-only stage boundaries.

Writes      : None.
Required    : overall_m2_4_status = PASS.
============================================================================ */

SET statement_timeout = '30min';
SET jit = off;

/* --------------------------------------------------------------------------
Report reconstruction — lifecycle, policy, registry, controls and diagnostics
-------------------------------------------------------------------------- */
WITH run_context AS
(
    SELECT
        run_id,
        run_code,
        run_version,
        run_status
    FROM msbf_ctl.run_registry
    WHERE run_code = 'M1_V0_2_BASELINE_BUILD'
      AND run_version = 1
),
policy AS
(
    SELECT
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
        synthetic_booking_enabled_flag,
        synthetic_funding_enabled_flag,
        portfolio_activation_enabled_flag,
        synthetic_offer_acceptance_assumed_flag,
        real_funds_movement_prohibited_flag,
        external_notice_transmission_prohibited_flag,
        production_adverse_action_notice_prohibited_flag,
        review_routes_not_bookable_flag,
        decline_routes_not_bookable_flag,
        stress_nonimprovement_required_flag,
        configuration_hash
    FROM msbf_ctl.m2_4_policy_profile
    WHERE module1_run_id = (SELECT run_id FROM run_context)
),
registry AS
(
    SELECT
        contract_status,
        policy_rows,
        outcome_rows,
        reason_rows,
        notice_control_rows,
        source_rows,
        activation_snapshot_rows,
        activation_latest_rows,
        activation_archive_rows,
        account_rows,
        advance_rows,
        portfolio_rows,
        comparison_rows,
        registry_rows,
        canonical_entities,
        activated_rows,
        review_required_rows,
        not_activated_insufficient_rows,
        not_activated_policy_rows,
        policy_set_hash,
        outcome_set_hash,
        reason_set_hash,
        notice_control_set_hash,
        source_set_hash,
        activation_snapshot_set_hash,
        activation_latest_set_hash,
        activation_archive_set_hash,
        account_set_hash,
        advance_set_hash,
        portfolio_set_hash,
        contract_set_hash,
        combined_set_hash,
        generated_at,
        validated_at,
        accepted_at
    FROM msbf_ctl.m2_4_portfolio_activation_contract_registry
    WHERE module1_run_id = (SELECT run_id FROM run_context)
),
acceptance AS
(
    SELECT
        result_status AS gate_status,
        observed_value,
        threshold_value,
        reviewer_role
    FROM msbf_ctl.acceptance_gate_result
    WHERE run_id = (SELECT run_id FROM run_context)
      AND gate_id = 'M2_4_BOOKING_FUNDING_PORTFOLIO_ACTIVATION'
      AND review_version = 1
),
controls AS
(
    SELECT
        count(*) FILTER
        (
            WHERE evidence_code LIKE 'M2_4_POS_%'
        )::bigint AS positive_checks,
        count(*) FILTER
        (
            WHERE evidence_code LIKE 'M2_4_POS_%'
              AND status = 'PASS'
        )::bigint AS positive_passes,
        count(*) FILTER
        (
            WHERE evidence_code LIKE 'M2_4_NEG_%'
        )::bigint AS negative_checks,
        count(*) FILTER
        (
            WHERE evidence_code LIKE 'M2_4_NEG_%'
              AND status = 'PASS'
        )::bigint AS negative_passes,
        count(*) FILTER
        (
            WHERE evidence_code LIKE 'M2_4_%'
              AND status = 'FAIL'
        )::bigint AS failed_evidence
    FROM msbf_ctl.run_evidence
    WHERE run_id = (SELECT run_id FROM run_context)
),
physical AS
(
    SELECT
        count(*) FILTER
        (
            WHERE activation_outcome_code =
                  'BOOKED_FUNDED_PORTFOLIO_ACTIVATED'
        )::bigint AS activated_rows,
        count(*) FILTER
        (
            WHERE activation_outcome_code =
                  'ACTIVATION_REVIEW_REQUIRED'
        )::bigint AS review_required_rows,
        count(*) FILTER
        (
            WHERE activation_outcome_code =
                  'NOT_ACTIVATED_INSUFFICIENT_EVIDENCE'
        )::bigint AS insufficient_rows,
        count(*) FILTER
        (
            WHERE activation_outcome_code =
                  'NOT_ACTIVATED_POLICY_DECLINE'
        )::bigint AS policy_decline_rows,
        count(*) FILTER
        (
            WHERE scenario_code = 'BASELINE'
        )::bigint AS baseline_rows,
        count(*) FILTER
        (
            WHERE scenario_code = 'RECESSION_ENERGY'
        )::bigint AS stress_rows,
        round(sum(funded_amount) FILTER
        (
            WHERE portfolio_activated_flag
        ),2) AS total_synthetic_funded_amount,
        round(avg(funded_amount) FILTER
        (
            WHERE portfolio_activated_flag
        ),2) AS average_synthetic_funded_amount
    FROM msbf_m2.application_booking_funding_activation_latest
    WHERE module1_run_id = (SELECT run_id FROM run_context)
),
subledgers AS
(
    SELECT
        (SELECT count(*)
         FROM msbf_m2.synthetic_account_activation
         WHERE module1_run_id = (SELECT run_id FROM run_context))::bigint
            AS account_rows,
        (SELECT count(*)
         FROM msbf_m2.synthetic_advance_funding
         WHERE module1_run_id = (SELECT run_id FROM run_context))::bigint
            AS advance_rows,
        (SELECT count(*)
         FROM msbf_m2.initial_portfolio_activation
         WHERE module1_run_id = (SELECT run_id FROM run_context))::bigint
            AS portfolio_rows
),
diagnostics AS
(
    SELECT
        (SELECT count(*)
         FROM msbf_m2.v_m2_4_matched_scenario_comparison
         WHERE module1_run_id = (SELECT run_id FROM run_context)
           AND
           (
               stress_activation_improvement_flag
               OR stress_funded_amount_improvement_flag
           ))::bigint AS stress_improvements,

        (SELECT count(*)
         FROM msbf_m2.application_booking_funding_activation_latest
         WHERE module1_run_id = (SELECT run_id FROM run_context)
           AND NOT portfolio_activated_flag
           AND
           (
               synthetic_account_id IS NOT NULL
               OR synthetic_advance_id IS NOT NULL
               OR funded_amount IS NOT NULL
               OR booking_date IS NOT NULL
               OR funding_date IS NOT NULL
               OR portfolio_activation_date IS NOT NULL
           ))::bigint AS nonactivated_operational_payload_rows,

        (SELECT count(*)
         FROM msbf_m2.application_booking_funding_activation_latest
         WHERE module1_run_id = (SELECT run_id FROM run_context)
           AND
           (
               real_funds_movement_flag
               OR external_notice_generation_authorized_flag
               OR external_notice_transmitted_flag
               OR production_adverse_action_notice_flag
           ))::bigint AS prohibited_operational_flag_rows,

        (SELECT count(*)
         FROM msbf_m2.application_booking_funding_activation_latest AS latest
         JOIN msbf_m2.application_booking_funding_activation_archive AS archive
           ON archive.module1_run_id = latest.module1_run_id
          AND archive.contract_version = latest.contract_version
          AND archive.scenario_id = latest.scenario_id
          AND archive.merchant_application_id =
              latest.merchant_application_id
         WHERE latest.module1_run_id = (SELECT run_id FROM run_context)
           AND
           (
               archive.contract_row_hash IS DISTINCT FROM
                   latest.contract_row_hash
               OR archive.contract_payload IS DISTINCT FROM
                   (to_jsonb(latest) - 'created_at')
           ))::bigint AS archive_mismatches,

        (SELECT count(*)
         FROM msbf_m2.application_booking_funding_activation_latest AS activation
         WHERE activation.module1_run_id = (SELECT run_id FROM run_context)
           AND EXISTS
           (
               SELECT 1
               FROM jsonb_array_elements_text
                    (activation.activation_reason_codes) AS reason_value
               WHERE NOT EXISTS
               (
                   SELECT 1
                   FROM msbf_m2.booking_funding_reason_definition AS reason
                   WHERE reason.module1_run_id = activation.module1_run_id
                     AND reason.activation_reason_code = reason_value.value
                     AND reason.mapped_activation_outcome_code =
                         activation.activation_outcome_code
               )
           ))::bigint AS reason_mapping_mismatches,

        (SELECT count(*)
         FROM msbf_m2.application_booking_funding_activation_latest AS latest
         LEFT JOIN msbf_m2.synthetic_account_activation AS account
           ON account.module1_run_id = latest.module1_run_id
          AND account.scenario_id = latest.scenario_id
          AND account.merchant_application_id =
              latest.merchant_application_id
         LEFT JOIN msbf_m2.synthetic_advance_funding AS advance
           ON advance.module1_run_id = latest.module1_run_id
          AND advance.scenario_id = latest.scenario_id
          AND advance.merchant_application_id =
              latest.merchant_application_id
         LEFT JOIN msbf_m2.initial_portfolio_activation AS portfolio
           ON portfolio.module1_run_id = latest.module1_run_id
          AND portfolio.scenario_id = latest.scenario_id
          AND portfolio.merchant_application_id =
              latest.merchant_application_id
         WHERE latest.module1_run_id = (SELECT run_id FROM run_context)
           AND latest.portfolio_activated_flag
           AND
           (
               account.synthetic_account_id IS DISTINCT FROM
                   latest.synthetic_account_id
               OR advance.synthetic_advance_id IS DISTINCT FROM
                   latest.synthetic_advance_id
               OR portfolio.synthetic_advance_id IS DISTINCT FROM
                   latest.synthetic_advance_id
           ))::bigint AS subledger_link_mismatches
)
SELECT
    run_context.run_code,
    run_context.run_version,
    run_context.run_status,
    policy.policy_code,
    policy.policy_version,
    policy.policy_status,
    policy.methodology_version,
    policy.contract_code,
    policy.contract_version,
    policy.schema_version,
    policy.source_m2_3_contract_code,
    policy.source_m2_3_contract_version,
    policy.source_m2_3_schema_version,
    policy.source_m2_3_combined_hash,
    registry.contract_status,
    acceptance.gate_status,
    acceptance.reviewer_role,
    registry.policy_rows,
    registry.outcome_rows,
    registry.reason_rows,
    registry.notice_control_rows,
    registry.source_rows,
    registry.activation_snapshot_rows,
    registry.activation_latest_rows,
    registry.activation_archive_rows,
    registry.account_rows,
    registry.advance_rows,
    registry.portfolio_rows,
    registry.comparison_rows,
    registry.canonical_entities,
    physical.activated_rows,
    physical.review_required_rows,
    physical.insufficient_rows AS not_activated_insufficient_rows,
    physical.policy_decline_rows AS not_activated_policy_rows,
    physical.baseline_rows,
    physical.stress_rows,
    physical.total_synthetic_funded_amount,
    physical.average_synthetic_funded_amount,
    subledgers.account_rows AS physical_account_rows,
    subledgers.advance_rows AS physical_advance_rows,
    subledgers.portfolio_rows AS physical_portfolio_rows,
    controls.positive_passes,
    controls.positive_checks,
    controls.negative_passes,
    controls.negative_checks,
    controls.failed_evidence,
    diagnostics.stress_improvements,
    diagnostics.nonactivated_operational_payload_rows,
    diagnostics.prohibited_operational_flag_rows,
    diagnostics.archive_mismatches,
    diagnostics.reason_mapping_mismatches,
    diagnostics.subledger_link_mismatches,
    registry.policy_set_hash,
    registry.outcome_set_hash,
    registry.reason_set_hash,
    registry.notice_control_set_hash,
    registry.source_set_hash,
    registry.activation_snapshot_set_hash,
    registry.activation_latest_set_hash,
    registry.activation_archive_set_hash,
    registry.account_set_hash,
    registry.advance_set_hash,
    registry.portfolio_set_hash,
    registry.contract_set_hash,
    registry.combined_set_hash,
    registry.generated_at,
    registry.validated_at,
    registry.accepted_at,
    CASE
        WHEN run_context.run_status = 'M2_4_ACCEPTED'
         AND policy.policy_status = 'APPROVED'
         AND registry.contract_status = 'ACCEPTED'
         AND acceptance.gate_status = 'PASS'
         AND registry.policy_rows = 1
         AND registry.outcome_rows = 5
         AND registry.reason_rows = 24
         AND registry.notice_control_rows = 4
         AND registry.source_rows = 1500
         AND registry.activation_snapshot_rows = 1500
         AND registry.activation_latest_rows = 1500
         AND registry.activation_archive_rows = 1500
         AND registry.account_rows = 59
         AND registry.advance_rows = 59
         AND registry.portfolio_rows = 59
         AND registry.comparison_rows = 750
         AND registry.canonical_entities = 6212
         AND physical.activated_rows = 59
         AND physical.review_required_rows = 190
         AND physical.insufficient_rows = 178
         AND physical.policy_decline_rows = 1073
         AND physical.baseline_rows = 750
         AND physical.stress_rows = 750
         AND subledgers.account_rows = 59
         AND subledgers.advance_rows = 59
         AND subledgers.portfolio_rows = 59
         AND controls.positive_checks = 120
         AND controls.positive_passes = 120
         AND controls.negative_checks = 20
         AND controls.negative_passes = 20
         AND controls.failed_evidence = 0
         AND diagnostics.stress_improvements = 0
         AND diagnostics.nonactivated_operational_payload_rows = 0
         AND diagnostics.prohibited_operational_flag_rows = 0
         AND diagnostics.archive_mismatches = 0
         AND diagnostics.reason_mapping_mismatches = 0
         AND diagnostics.subledger_link_mismatches = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END AS overall_m2_4_status
FROM run_context
CROSS JOIN policy
CROSS JOIN registry
CROSS JOIN acceptance
CROSS JOIN controls
CROSS JOIN physical
CROSS JOIN subledgers
CROSS JOIN diagnostics;
