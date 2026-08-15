/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.7 — Operational Activation & Account Setup
============================================================================ */

/* ============================================================================
Program     : 186_MSBF_M2_7_Master_Report_v0_2.sql
Version     : v0.2

Purpose
-------
Produce one executive/governance summary row after formal M2.7 acceptance.
The report independently reconciles lifecycle, accepted M2.6 source identity,
physical cardinalities, exact 57/1/1 setup distribution, setup and review
exposure, temporary terms, evidence, real-execution boundaries, canonical
identity, stress non-improvement, and latest/archive reproduction.

Writes
------
None.

Required result
---------------
overall_m2_7_status = PASS.
============================================================================ */

SET statement_timeout='30min';
SET jit=off;

WITH run_context AS
(
    SELECT run_id,run_code,run_version,run_status
    FROM msbf_ctl.run_registry
    WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
),
policy AS
(
    SELECT *
    FROM msbf_ctl.m2_7_policy_profile
    WHERE module1_run_id=(SELECT run_id FROM run_context)
),
registry AS
(
    SELECT *
    FROM msbf_ctl.m2_7_operational_activation_contract_registry
    WHERE module1_run_id=(SELECT run_id FROM run_context)
),
gate AS
(
    SELECT result_status AS gate_status
    FROM msbf_ctl.acceptance_gate_result
    WHERE run_id=(SELECT run_id FROM run_context)
      AND gate_id='M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP'
      AND review_version=1
),
evidence AS
(
    SELECT
        count(*) FILTER
        (
            WHERE evidence_code LIKE 'M2_7_POS_%' AND status='PASS'
        )::bigint AS positive_passes,
        count(*) FILTER
        (
            WHERE evidence_code LIKE 'M2_7_POS_%'
        )::bigint AS positive_checks,
        count(*) FILTER
        (
            WHERE evidence_code LIKE 'M2_7_NEG_%' AND status='PASS'
        )::bigint AS negative_passes,
        count(*) FILTER
        (
            WHERE evidence_code LIKE 'M2_7_NEG_%'
        )::bigint AS negative_checks,
        count(*) FILTER
        (
            WHERE evidence_code LIKE 'M2_7_%'
              AND evidence_code NOT LIKE 'M2_7_POS_%'
              AND evidence_code NOT LIKE 'M2_7_NEG_%'
              AND evidence_code<>'M2_7_ACCEPTANCE_SUMMARY'
        )::bigint AS generation_evidence_rows,
        count(*) FILTER
        (
            WHERE evidence_code='M2_7_ACCEPTANCE_SUMMARY'
              AND status='PASS'
        )::bigint AS acceptance_evidence_rows,
        count(*) FILTER
        (
            WHERE evidence_code LIKE 'M2_7_%' AND status='FAIL'
        )::bigint AS failed_evidence_rows
    FROM msbf_ctl.run_evidence
    WHERE run_id=(SELECT run_id FROM run_context)
),
distribution AS
(
    SELECT
        count(*)::bigint AS latest_rows,
        count(*) FILTER(WHERE no_setup_required_flag)::bigint
            AS no_setup_required_rows,
        count(*) FILTER
        (
            WHERE operational_setup_outcome_code=
                  'STANDARD_SERVICING_SETUP_READY'
        )::bigint AS standard_setup_rows,
        count(*) FILTER
        (
            WHERE operational_setup_outcome_code=
                  'TEMPORARY_PAYMENT_ADJUSTMENT_SETUP_READY'
        )::bigint AS temporary_adjustment_setup_rows,
        count(*) FILTER
        (
            WHERE operational_setup_outcome_code='RESTRUCTURE_SETUP_READY'
        )::bigint AS restructure_setup_rows,
        count(*) FILTER
        (
            WHERE operational_setup_outcome_code=
                  'CONTROLLED_RECOVERY_SETUP_READY'
        )::bigint AS recovery_setup_rows,
        count(*) FILTER
        (
            WHERE operational_setup_outcome_code='CHARGE_OFF_SETUP_READY'
        )::bigint AS charge_off_setup_rows,
        count(*) FILTER(WHERE setup_review_required_flag)::bigint
            AS review_required_rows,
        count(*) FILTER(WHERE setup_authorized_flag)::bigint
            AS setup_authorized_rows,
        round
        (
            sum
            (
                CASE WHEN setup_authorized_flag
                     THEN source_recommended_action_exposure_amount ELSE 0 END
            ),
            2
        ) AS setup_authorized_amount,
        round
        (
            sum
            (
                CASE WHEN setup_review_required_flag
                     THEN source_recommended_action_exposure_amount ELSE 0 END
            ),
            2
        ) AS review_required_amount
    FROM msbf_m2.application_operational_activation_latest
    WHERE module1_run_id=(SELECT run_id FROM run_context)
),
temporary AS
(
    SELECT
        count(*)::bigint AS temporary_rows,
        min(applied_temporary_payment_factor) AS minimum_factor,
        max(applied_temporary_payment_factor) AS maximum_factor,
        min(applied_setup_duration_days) AS minimum_duration_days,
        max(applied_setup_duration_days) AS maximum_duration_days,
        min(applied_reassessment_interval_days) AS minimum_reassessment_days,
        max(applied_reassessment_interval_days) AS maximum_reassessment_days
    FROM msbf_m2.application_operational_activation_latest
    WHERE module1_run_id=(SELECT run_id FROM run_context)
      AND operational_setup_outcome_code=
          'TEMPORARY_PAYMENT_ADJUSTMENT_SETUP_READY'
),
boundary AS
(
    SELECT
        (
            SELECT count(*)
            FROM msbf_m2.application_operational_activation_snapshot
            WHERE module1_run_id=(SELECT run_id FROM run_context)
              AND
              (
                  real_core_account_created_flag
                  OR real_payment_change_executed_flag
                  OR bank_account_data_present_flag
                  OR ach_or_network_transmission_flag
                  OR external_notice_generated_flag
                  OR merchant_contact_executed_flag
                  OR write_off_posted_flag
                  OR collection_or_legal_executed_flag
                  OR production_adverse_action_flag
              )
        )
        +
        (
            SELECT count(*)
            FROM msbf_m2.operational_account_setup_snapshot
            WHERE module1_run_id=(SELECT run_id FROM run_context)
              AND
              (
                  real_core_account_created_flag
                  OR real_payment_change_executed_flag
                  OR bank_account_data_present_flag
                  OR ach_or_network_transmission_flag
                  OR external_notice_generated_flag
                  OR merchant_contact_executed_flag
                  OR write_off_posted_flag
                  OR collection_or_legal_executed_flag
                  OR production_adverse_action_flag
              )
        )::bigint AS executed_boundary_rows
),
diagnostics AS
(
    SELECT
        (
            SELECT canonical_entities
            FROM msbf_m2.v_m2_7_canonical_hash
            WHERE module1_run_id=(SELECT run_id FROM run_context)
        )::bigint AS physical_canonical_entities,
        (
            SELECT combined_set_hash
            FROM msbf_m2.v_m2_7_canonical_hash
            WHERE module1_run_id=(SELECT run_id FROM run_context)
        ) AS physical_combined_set_hash,
        (
            SELECT count(*)
            FROM msbf_m2.v_m2_7_matched_scenario_comparison
            WHERE module1_run_id=(SELECT run_id FROM run_context)
              AND
              (
                  stress_setup_permission_improvement_flag
                  OR stress_priority_improvement_flag
              )
        )::bigint AS stress_improvement_rows,
        (
            SELECT count(*)
            FROM msbf_m2.application_operational_activation_latest AS l
            FULL OUTER JOIN
                 msbf_m2.application_operational_activation_archive AS a
              ON a.module1_run_id=l.module1_run_id
             AND a.contract_version=l.contract_version
             AND a.scenario_id=l.scenario_id
             AND a.merchant_application_id=l.merchant_application_id
            WHERE coalesce(l.module1_run_id,a.module1_run_id)=
                  (SELECT run_id FROM run_context)
              AND
              (
                  l.contract_row_hash IS DISTINCT FROM a.contract_row_hash
                  OR a.contract_payload IS DISTINCT FROM
                     (to_jsonb(l)-'created_at')
              )
        )::bigint AS archive_mismatches,
        (
            SELECT count(*)
            FROM information_schema.columns
            WHERE table_schema='msbf_m2'
              AND table_name IN
              (
                  'application_operational_activation_snapshot',
                  'operational_account_setup_snapshot',
                  'application_operational_activation_latest',
                  'application_operational_activation_archive'
              )
              AND lower(column_name) IN
              (
                  'real_core_account_number',
                  'bank_account_number',
                  'routing_number',
                  'settlement_account_number',
                  'ach_trace_number',
                  'payment_network_confirmation',
                  'external_notice_payload',
                  'production_adverse_action_notice'
              )
        )::bigint AS prohibited_columns,
        (
            SELECT count(*)
            FROM information_schema.tables
            WHERE table_schema IN ('msbf_ctl','msbf_m2')
              AND lower(table_name) LIKE 'm2_8%'
        )::bigint AS premature_m2_8_tables
)
SELECT
    run_context.run_code,run_context.run_version,run_context.run_status,

    policy.policy_code,policy.policy_version,policy.policy_status,
    policy.methodology_version,policy.contract_code,
    policy.contract_version,policy.schema_version,
    policy.source_contract_code,policy.source_contract_version,
    policy.source_schema_version,policy.source_acceptance_gate_id,
    policy.source_combined_set_hash,policy.configuration_hash,

    registry.contract_status,gate.gate_status,

    registry.policy_rows,registry.outcome_rows,registry.action_rows,
    registry.reason_rows,registry.source_rows,registry.activation_rows,
    registry.account_setup_rows,registry.portfolio_summary_rows,
    registry.latest_rows,registry.archive_rows,registry.comparison_rows,
    registry.registry_rows,registry.canonical_entities,

    distribution.no_setup_required_rows,distribution.standard_setup_rows,
    distribution.temporary_adjustment_setup_rows,
    distribution.restructure_setup_rows,distribution.recovery_setup_rows,
    distribution.charge_off_setup_rows,distribution.review_required_rows,
    distribution.setup_authorized_rows,distribution.setup_authorized_amount,
    distribution.review_required_amount,

    temporary.temporary_rows,temporary.minimum_factor,
    temporary.maximum_factor,temporary.minimum_duration_days,
    temporary.maximum_duration_days,temporary.minimum_reassessment_days,
    temporary.maximum_reassessment_days,

    evidence.positive_passes,evidence.positive_checks,
    evidence.negative_passes,evidence.negative_checks,
    evidence.generation_evidence_rows,evidence.acceptance_evidence_rows,
    evidence.failed_evidence_rows,

    boundary.executed_boundary_rows,
    diagnostics.physical_canonical_entities,
    diagnostics.stress_improvement_rows,diagnostics.archive_mismatches,
    diagnostics.prohibited_columns,diagnostics.premature_m2_8_tables,

    registry.policy_set_hash,registry.outcome_set_hash,
    registry.action_set_hash,registry.reason_set_hash,
    registry.source_set_hash,registry.activation_set_hash,
    registry.account_setup_set_hash,registry.portfolio_summary_set_hash,
    registry.latest_set_hash,registry.archive_set_hash,
    registry.contract_set_hash,registry.combined_set_hash,

    CASE
        WHEN run_context.run_status='M2_7_ACCEPTED'
         AND policy.policy_status='APPROVED'
         AND policy.synthetic_data_only_flag
         AND policy.simulated_operational_setup_only_flag
         AND policy.preserve_m2_6_history_flag
         AND policy.no_real_core_account_creation_flag
         AND policy.no_real_payment_change_execution_flag
         AND policy.no_bank_account_data_flag
         AND policy.no_ach_or_network_transmission_flag
         AND policy.no_external_notice_generation_flag
         AND policy.no_merchant_contact_execution_flag
         AND policy.no_write_off_posting_flag
         AND policy.no_collection_or_legal_execution_flag

         AND registry.contract_status='ACCEPTED'
         AND gate.gate_status='PASS'

         AND registry.policy_rows=1
         AND registry.outcome_rows=7
         AND registry.action_rows=7
         AND registry.reason_rows=28
         AND registry.source_rows=59
         AND registry.activation_rows=59
         AND registry.account_setup_rows=59
         AND registry.portfolio_summary_rows=2
         AND registry.latest_rows=59
         AND registry.archive_rows=59
         AND registry.comparison_rows=15
         AND registry.registry_rows=1
         AND registry.canonical_entities=341

         AND distribution.no_setup_required_rows=57
         AND distribution.temporary_adjustment_setup_rows=1
         AND distribution.review_required_rows=1
         AND distribution.setup_authorized_rows=1
         AND distribution.setup_authorized_amount=518.04
         AND distribution.review_required_amount=461.69

         AND temporary.temporary_rows=1
         AND temporary.minimum_factor=0.75
         AND temporary.maximum_factor=0.75
         AND temporary.minimum_duration_days=14
         AND temporary.maximum_duration_days=14
         AND temporary.minimum_reassessment_days=7
         AND temporary.maximum_reassessment_days=7

         AND evidence.positive_passes=120
         AND evidence.positive_checks=120
         AND evidence.negative_passes=20
         AND evidence.negative_checks=20
         AND evidence.generation_evidence_rows=24
         AND evidence.acceptance_evidence_rows=1
         AND evidence.failed_evidence_rows=0

         AND boundary.executed_boundary_rows=0
         AND diagnostics.physical_canonical_entities=341
         AND registry.combined_set_hash IS NOT DISTINCT FROM
             diagnostics.physical_combined_set_hash
         AND diagnostics.stress_improvement_rows=0
         AND diagnostics.archive_mismatches=0
         AND diagnostics.prohibited_columns=0
         AND diagnostics.premature_m2_8_tables=0
        THEN 'PASS'
        ELSE 'FAIL'
    END AS overall_m2_7_status
FROM run_context
CROSS JOIN policy
CROSS JOIN registry
CROSS JOIN gate
CROSS JOIN evidence
CROSS JOIN distribution
CROSS JOIN temporary
CROSS JOIN boundary
CROSS JOIN diagnostics;
