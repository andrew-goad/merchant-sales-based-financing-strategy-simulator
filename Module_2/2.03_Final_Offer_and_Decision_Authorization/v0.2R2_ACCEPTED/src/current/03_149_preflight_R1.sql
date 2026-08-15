/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.3 — Final Offer & Decision Authorization

Program     : 149_msbf_m2_3_preflight_validation_v0_2R1.sql
Version     : v0.2R1
Purpose     : Fail closed unless accepted M2.2 source contracts, policy
              profile, outcome/reason dictionaries, empty M2.3 targets, and
              stage-boundary controls are ready for deterministic generation.

Writes      : None. Result table is session-scoped and filterable.
Required    : preflight_status = PASS.
============================================================================ */

SET statement_timeout = '20min';
SET jit = off;

DROP TABLE IF EXISTS _m2_3_preflight;

CREATE TEMP TABLE _m2_3_preflight
ON COMMIT PRESERVE ROWS
AS
WITH run_context AS
(
    SELECT
        run_id,
        run_status
    FROM msbf_ctl.run_registry
    WHERE run_code = 'M1_V0_2_BASELINE_BUILD'
      AND run_version = 1
),
policy AS
(
    SELECT *
    FROM msbf_ctl.m2_3_policy_profile
    WHERE module1_run_id = (SELECT run_id FROM run_context)
      AND policy_code = 'M2_3_FINAL_OFFER_DECISION_POLICY_V1'
),
source_registry AS
(
    SELECT
        count(*)::bigint AS registry_rows,
        max(contract_status) AS contract_status,
        max(pricing_contract_code) AS pricing_contract_code,
        max(pricing_contract_version) AS pricing_contract_version,
        max(pricing_schema_version) AS pricing_schema_version,
        max(combined_set_hash) AS combined_set_hash,
        max(pricing_latest_rows) AS pricing_latest_rows,
        max(pricing_archive_rows) AS pricing_archive_rows,
        max(comparison_rows) AS comparison_rows,
        max(canonical_entities) AS canonical_entities
    FROM msbf_ctl.m2_2_pricing_structure_contract_registry
    WHERE module1_run_id = (SELECT run_id FROM run_context)
),
source_gate AS
(
    SELECT
        count(*)::bigint AS gate_rows,
        max(result_status) AS gate_status
    FROM msbf_ctl.acceptance_gate_result
    WHERE run_id = (SELECT run_id FROM run_context)
      AND gate_id = 'M2_2_PRICING_STRUCTURE_COUNTEROFFER'
),
source_latest AS
(
    SELECT
        count(*)::bigint AS source_rows,
        count(DISTINCT merchant_application_id)::bigint AS applications,
        count(DISTINCT scenario_id)::bigint AS scenarios,
        count(*) FILTER(WHERE scenario_code = 'BASELINE')::bigint AS baseline_rows,
        count(*) FILTER(WHERE scenario_code = 'RECESSION_ENERGY')::bigint AS stress_rows,
        count(*) FILTER(WHERE pricing_disposition_code = 'STRUCTURE_READY')::bigint AS structure_ready_rows,
        count(*) FILTER(WHERE pricing_disposition_code = 'COUNTEROFFER_FOUNDATION_REVIEW')::bigint AS counteroffer_review_rows,
        count(*) FILTER(WHERE pricing_disposition_code = 'NO_STRUCTURE_INSUFFICIENT_EVIDENCE')::bigint AS insufficient_evidence_rows,
        count(*) FILTER(WHERE pricing_disposition_code = 'NO_STRUCTURE_POLICY_DECLINE')::bigint AS policy_decline_rows,
        count(*) FILTER
        (
            WHERE module1_run_id IS NULL
               OR scenario_id IS NULL
               OR scenario_code IS NULL
               OR merchant_application_id IS NULL
               OR contract_row_hash IS NULL
               OR source_request_contract_row_hash IS NULL
        )::bigint AS required_key_nulls
    FROM msbf_m2.application_pricing_structure_latest
    WHERE module1_run_id = (SELECT run_id FROM run_context)
),
gate_catalog AS
(
    SELECT
        count(*)::bigint AS gate_catalog_rows
    FROM msbf_ref.acceptance_gate_catalog
    WHERE gate_id = 'M2_3_FINAL_OFFER_DECISION_AUTHORIZATION'
      AND active_flag
),
definitions AS
(
    SELECT
        (SELECT count(*)
         FROM msbf_m2.final_decision_outcome_definition
         WHERE module1_run_id = (SELECT run_id FROM run_context)
           AND outcome_status = 'APPROVED')::bigint AS outcome_rows,
        (SELECT count(*)
         FROM msbf_m2.final_decision_reason_definition
         WHERE module1_run_id = (SELECT run_id FROM run_context)
           AND reason_status = 'APPROVED')::bigint AS reason_rows,
        (SELECT count(*)
         FROM msbf_m2.final_decision_outcome_definition
         WHERE module1_run_id = (SELECT run_id FROM run_context)
           AND (production_adverse_action_notice_flag OR booking_funding_flag))::bigint
           AS prohibited_outcome_flags,
        (SELECT count(*)
         FROM msbf_m2.final_decision_reason_definition
         WHERE module1_run_id = (SELECT run_id FROM run_context)
           AND production_adverse_action_notice_flag)::bigint
           AS prohibited_reason_flags
),
targets AS
(
    SELECT
        (SELECT count(*) FROM msbf_m2.application_final_decision_source_snapshot
         WHERE module1_run_id = (SELECT run_id FROM run_context))::bigint AS source_snapshot_rows,
        (SELECT count(*) FROM msbf_m2.application_final_offer_decision_snapshot
         WHERE module1_run_id = (SELECT run_id FROM run_context))::bigint AS decision_snapshot_rows,
        (SELECT count(*) FROM msbf_m2.application_final_offer_decision_latest
         WHERE module1_run_id = (SELECT run_id FROM run_context))::bigint AS latest_rows,
        (SELECT count(*) FROM msbf_m2.application_final_offer_decision_archive
         WHERE module1_run_id = (SELECT run_id FROM run_context))::bigint AS archive_rows,
        (SELECT count(*) FROM msbf_ctl.m2_3_final_decision_contract_registry
         WHERE module1_run_id = (SELECT run_id FROM run_context))::bigint AS registry_rows,
        (SELECT count(*) FROM msbf_ctl.run_evidence
         WHERE run_id = (SELECT run_id FROM run_context)
           AND evidence_code LIKE 'M2_3_%')::bigint AS evidence_rows,
        (SELECT count(*) FROM msbf_ctl.acceptance_gate_result
         WHERE run_id = (SELECT run_id FROM run_context)
           AND gate_id = 'M2_3_FINAL_OFFER_DECISION_AUTHORIZATION')::bigint AS acceptance_rows,
        (SELECT count(*) FROM information_schema.tables
         WHERE table_schema IN ('msbf_m2','msbf_ctl')
           AND lower(table_name) LIKE 'm2_4%')::bigint AS m2_4_tables,
        (SELECT count(*) FROM information_schema.columns
         WHERE table_schema = 'msbf_m2'
           AND table_name IN
           (
               'application_final_offer_decision_snapshot',
               'application_final_offer_decision_latest',
               'application_final_offer_decision_archive'
           )
           AND lower(column_name) IN
           (
               'booking_status',
               'funding_status',
               'funded_amount',
               'loan_number',
               'account_number',
               'production_adverse_action_notice',
               'external_notice_payload'
           ))::bigint AS prohibited_columns
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
    policy.no_booking_funding_flag,
    policy.no_external_notice_generation_flag,
    policy.no_production_adverse_action_notice_flag,

    source_registry.registry_rows AS source_registry_rows,
    source_registry.contract_status AS source_contract_status,
    source_registry.pricing_contract_code AS source_contract_code,
    source_registry.pricing_contract_version AS source_contract_version,
    source_registry.pricing_schema_version AS source_schema_version,
    source_registry.combined_set_hash AS source_combined_hash,
    source_gate.gate_rows AS source_gate_rows,
    source_gate.gate_status AS source_gate_status,

    source_latest.source_rows,
    source_latest.applications,
    source_latest.scenarios,
    source_latest.baseline_rows,
    source_latest.stress_rows,
    source_latest.structure_ready_rows,
    source_latest.counteroffer_review_rows,
    source_latest.insufficient_evidence_rows,
    source_latest.policy_decline_rows,
    source_latest.required_key_nulls,

    gate_catalog.gate_catalog_rows,
    definitions.outcome_rows,
    definitions.reason_rows,
    definitions.prohibited_outcome_flags,
    definitions.prohibited_reason_flags,

    targets.source_snapshot_rows AS target_source_snapshot_rows,
    targets.decision_snapshot_rows AS target_decision_snapshot_rows,
    targets.latest_rows AS target_latest_rows,
    targets.archive_rows AS target_archive_rows,
    targets.registry_rows AS target_registry_rows,
    targets.evidence_rows AS target_evidence_rows,
    targets.acceptance_rows AS target_acceptance_rows,
    targets.m2_4_tables,
    targets.prohibited_columns,

    CASE
        WHEN run_context.run_status = 'M2_2_ACCEPTED'
         AND policy.policy_status = 'APPROVED'
         AND policy.methodology_version = 'M2_3_METHOD_V1'
         AND policy.contract_code = 'M2_FINAL_OFFER_DECISION_CONSUMPTION'
         AND policy.contract_version = 1
         AND policy.schema_version = 'M2_3_FINAL_DECISION_SCHEMA_V1'
         AND policy.no_booking_funding_flag
         AND policy.no_external_notice_generation_flag
         AND policy.no_production_adverse_action_notice_flag
         AND source_registry.registry_rows = 1
         AND source_registry.contract_status = 'ACCEPTED'
         AND source_registry.pricing_contract_code = 'M2_PRICING_STRUCTURE_CONSUMPTION'
         AND source_registry.pricing_contract_version = 1
         AND source_registry.pricing_schema_version = 'M2_2_PRICING_STRUCTURE_SCHEMA_V1'
         AND source_registry.combined_set_hash = 'bbe83b187b31ea561789797322031fc6'
         AND source_gate.gate_rows = 1
         AND source_gate.gate_status = 'PASS'
         AND source_latest.source_rows = 1500
         AND source_latest.applications = 750
         AND source_latest.scenarios = 2
         AND source_latest.baseline_rows = 750
         AND source_latest.stress_rows = 750
         AND source_latest.structure_ready_rows = 59
         AND source_latest.counteroffer_review_rows = 190
         AND source_latest.insufficient_evidence_rows = 178
         AND source_latest.policy_decline_rows = 1073
         AND source_latest.required_key_nulls = 0
         AND gate_catalog.gate_catalog_rows = 1
         AND definitions.outcome_rows = 5
         AND definitions.reason_rows = 22
         AND definitions.prohibited_outcome_flags = 0
         AND definitions.prohibited_reason_flags = 0
         AND targets.source_snapshot_rows = 0
         AND targets.decision_snapshot_rows = 0
         AND targets.latest_rows = 0
         AND targets.archive_rows = 0
         AND targets.registry_rows = 0
         AND targets.evidence_rows = 0
         AND targets.acceptance_rows = 0
         AND targets.m2_4_tables = 0
         AND targets.prohibited_columns = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END AS preflight_status

FROM run_context
CROSS JOIN policy
CROSS JOIN source_registry
CROSS JOIN source_gate
CROSS JOIN source_latest
CROSS JOIN gate_catalog
CROSS JOIN definitions
CROSS JOIN targets;

DO $m2_3_preflight_guard$
DECLARE
    v record;
BEGIN
    SELECT *
    INTO v
    FROM _m2_3_preflight;

    IF v.preflight_status <> 'PASS' THEN
        RAISE EXCEPTION
            'M2.3 preflight failed: %',
            row_to_json(v);
    END IF;

    PERFORM msbf_ctl.m2_3_assert_generation_ready(v.run_id);
END;
$m2_3_preflight_guard$;

SELECT *
FROM _m2_3_preflight;
