/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
M2.1 — Eligibility, Policy Gates & Decision-Routing Foundations

Program
132F_msbf_m2_1_failed_negative_control_boundary_assertion_recovery_v0_2R5.sql

Purpose
Repair the configuration assertion that caused Program 136 v0.2R4 to return
18 of 20 negative controls rather than 20 of 20.

Exact failed negative controls
- M2_1_NEG_004_FINAL_OFFER_BOUNDARY
- M2_1_NEG_005_ACQUISITION_CREDIT_BOUNDARY

Root cause
The physical policy columns were changed by the negative controls, but
`msbf_ctl.m2_1_assert_configuration()` validated only the configuration payload
hash and did not compare these physical boundary columns to the approved
payload:

- no_final_offer_terms_flag
- acquisition_source_review_only_flag

The payload and its hash remained unchanged, so the old assertion accepted the
drift. This program strengthens the configuration and acceptance assertions,
proves the two mutations are now rejected, preserves the defect as audit
history, and leaves the validated generated population unchanged.

Writes
- Replaces two assertion functions.
- Inserts one superseded audit-history evidence row.
- Does not change policy values, gate results, routing snapshots, contracts,
  archives, source data, positive evidence, run status or contract status.

Normal next
135 v0.2R5 → 136 v0.2R5 → 137 v0.2R5 → 138 v0.2R5 → 139 v0.2R5
============================================================================ */

BEGIN;

SET LOCAL work_mem = '64MB';
SET LOCAL lock_timeout = '10s';
SET LOCAL statement_timeout = '20min';
SET LOCAL jit = off;

DROP TABLE IF EXISTS _m2_1_r5_boundary_recovery;

CREATE TEMP TABLE _m2_1_r5_boundary_recovery
ON COMMIT PRESERVE ROWS
AS
WITH governed_run AS
(
    SELECT
        run_id,
        run_status
    FROM msbf_ctl.run_registry
    WHERE run_code = 'M1_V0_2_BASELINE_BUILD'
      AND run_version = 1
),
contract_registry AS
(
    SELECT
        contract_status,
        gate_result_rows,
        routing_snapshot_rows,
        latest_rows,
        archive_rows,
        comparison_rows,
        canonical_entities,
        combined_set_hash
    FROM msbf_ctl.m2_1_strategy_contract_registry
    WHERE module1_run_id = (SELECT run_id FROM governed_run)
),
policy AS
(
    SELECT
        policy_code,
        policy_status,
        synthetic_data_only_flag,
        no_final_offer_terms_flag,
        no_production_adverse_action_flag,
        acquisition_source_review_only_flag,
        configuration_payload,
        configuration_hash,

        (configuration_payload->>'synthetic_data_only')::boolean
            AS payload_synthetic_data_only,
        (configuration_payload->>'no_final_offer_terms')::boolean
            AS payload_no_final_offer_terms,
        (configuration_payload->>'no_production_adverse_action')::boolean
            AS payload_no_production_adverse_action,
        (configuration_payload->>'acquisition_source_review_only')::boolean
            AS payload_acquisition_source_review_only
    FROM msbf_ctl.m2_1_policy_profile
    WHERE policy_code = 'M2_1_ELIGIBILITY_POLICY_V1'
),
evidence AS
(
    SELECT
        count(*) FILTER (
            WHERE evidence_code LIKE 'M2_1_POS_%'
        )::bigint AS positive_checks,

        count(*) FILTER (
            WHERE evidence_code LIKE 'M2_1_POS_%'
              AND status = 'PASS'
        )::bigint AS positive_passes,

        count(*) FILTER (
            WHERE evidence_code LIKE 'M2_1_POS_%'
              AND status <> 'PASS'
        )::bigint AS positive_failures,

        count(*) FILTER (
            WHERE evidence_code LIKE 'M2_1_NEG_%'
        )::bigint AS negative_evidence_rows
    FROM msbf_ctl.run_evidence
    WHERE run_id = (SELECT run_id FROM governed_run)
),
physical AS
(
    SELECT
        (
            SELECT count(*)
            FROM msbf_m2.application_policy_gate_result
            WHERE module1_run_id = (SELECT run_id FROM governed_run)
        )::bigint AS gate_result_rows,

        (
            SELECT count(*)
            FROM msbf_m2.application_eligibility_routing_snapshot
            WHERE module1_run_id = (SELECT run_id FROM governed_run)
        )::bigint AS routing_snapshot_rows,

        (
            SELECT count(*)
            FROM msbf_m2.application_eligibility_routing_latest
            WHERE module1_run_id = (SELECT run_id FROM governed_run)
        )::bigint AS latest_rows,

        (
            SELECT count(*)
            FROM msbf_m2.application_eligibility_routing_archive
            WHERE module1_run_id = (SELECT run_id FROM governed_run)
        )::bigint AS archive_rows,

        (
            SELECT count(*)
            FROM msbf_m2.v_m2_1_matched_scenario_comparison
            WHERE module1_run_id = (SELECT run_id FROM governed_run)
        )::bigint AS comparison_rows,

        (
            SELECT count(*)
            FROM msbf_ctl.acceptance_gate_result
            WHERE run_id = (SELECT run_id FROM governed_run)
              AND gate_id = 'M2_1_ELIGIBILITY_POLICY_ROUTING'
        )::bigint AS acceptance_rows,

        (
            SELECT count(*)
            FROM msbf_ctl.profile_resolution_error
            WHERE run_id = (SELECT run_id FROM governed_run)
              AND severity = 'BLOCKING'
        )::bigint AS blocking_errors
),
function_state AS
(
    SELECT
        pg_get_functiondef(
            'msbf_ctl.m2_1_assert_configuration(bigint)'::regprocedure
        ) AS prior_configuration_function,

        pg_get_functiondef(
            'msbf_ctl.m2_1_assert_acceptance_ready(bigint)'::regprocedure
        ) AS prior_acceptance_function
)
SELECT
    governed_run.run_id,
    governed_run.run_status AS prior_run_status,
    contract_registry.contract_status AS prior_contract_status,

    policy.*,
    evidence.*,
    physical.*,

    contract_registry.canonical_entities,
    contract_registry.combined_set_hash,

    position(
        'no_final_offer_terms_flag'
        in function_state.prior_configuration_function
    ) > 0 AS prior_final_offer_check_present,

    position(
        'acquisition_source_review_only_flag'
        in function_state.prior_configuration_function
    ) > 0 AS prior_acquisition_boundary_check_present,

    position(
        'm2_1_assert_configuration'
        in function_state.prior_acceptance_function
    ) > 0 AS prior_acceptance_calls_configuration
FROM governed_run
CROSS JOIN contract_registry
CROSS JOIN policy
CROSS JOIN evidence
CROSS JOIN physical
CROSS JOIN function_state;

DO $m2_1_r5_precondition_guard$
DECLARE
    v record;
BEGIN
    SELECT *
    INTO v
    FROM _m2_1_r5_boundary_recovery;

    IF v.prior_run_status <> 'M2_1_VALIDATED'
       OR v.prior_contract_status <> 'VALIDATED'
       OR v.policy_status <> 'APPROVED'
       OR v.synthetic_data_only_flag IS DISTINCT FROM TRUE
       OR v.no_final_offer_terms_flag IS DISTINCT FROM TRUE
       OR v.no_production_adverse_action_flag IS DISTINCT FROM TRUE
       OR v.acquisition_source_review_only_flag IS DISTINCT FROM TRUE
       OR v.payload_synthetic_data_only IS DISTINCT FROM TRUE
       OR v.payload_no_final_offer_terms IS DISTINCT FROM TRUE
       OR v.payload_no_production_adverse_action IS DISTINCT FROM TRUE
       OR v.payload_acquisition_source_review_only IS DISTINCT FROM TRUE
       OR v.configuration_hash IS DISTINCT FROM
            msbf_ctl.m2_1_hash_jsonb(v.configuration_payload)
       OR v.positive_checks <> 112
       OR v.positive_passes <> 112
       OR v.positive_failures <> 0
       OR v.negative_evidence_rows <> 0
       OR v.gate_result_rows <> 18000
       OR v.routing_snapshot_rows <> 1500
       OR v.latest_rows <> 1500
       OR v.archive_rows <> 1500
       OR v.comparison_rows <> 750
       OR v.acceptance_rows <> 0
       OR v.blocking_errors <> 0
       OR v.canonical_entities <> 22541
       OR v.combined_set_hash IS NULL THEN
        RAISE EXCEPTION
            'M2.1 v0.2R5 boundary-assertion recovery preconditions failed: %',
            row_to_json(v);
    END IF;
END;
$m2_1_r5_precondition_guard$;

CREATE OR REPLACE FUNCTION msbf_ctl.m2_1_assert_configuration(
    p_run_id bigint
)
RETURNS void
LANGUAGE plpgsql
AS $function$
DECLARE
    v msbf_ctl.m2_1_policy_profile%ROWTYPE;
BEGIN
    SELECT *
    INTO v
    FROM msbf_ctl.m2_1_policy_profile
    WHERE policy_code = 'M2_1_ELIGIBILITY_POLICY_V1';

    IF NOT FOUND
       OR v.policy_status <> 'APPROVED'
       OR v.methodology_version <> 'M2_1_METHOD_V1'
       OR v.contract_code <> 'M2_ELIGIBILITY_ROUTING_CONSUMPTION'
       OR v.contract_version <> 1
       OR v.schema_version <> 'M2_1_ROUTING_SCHEMA_V1'
       OR v.required_source_g2_hash <>
            '7d9e466da28cad2551aa99c4c40c912b'
       OR v.expected_gate_count <> 12
       OR v.expected_reason_count <> 23
       OR v.expected_outcome_count <> 4
       OR v.expected_input_rows <> 1500
       OR v.expected_gate_result_rows <> 18000
       OR v.expected_snapshot_rows <> 1500
       OR v.expected_latest_rows <> 1500
       OR v.expected_archive_rows <> 1500
       OR v.expected_comparison_rows <> 750
       OR v.expected_canonical_entities <> 22541
       OR v.expected_positive_controls <> 112
       OR v.expected_negative_controls <> 20
       OR v.expected_detail_result_sets <> 24

       /* Physical stage-boundary flags must remain approved. */
       OR v.synthetic_data_only_flag IS DISTINCT FROM TRUE
       OR v.no_final_offer_terms_flag IS DISTINCT FROM TRUE
       OR v.no_production_adverse_action_flag IS DISTINCT FROM TRUE
       OR v.acquisition_source_review_only_flag IS DISTINCT FROM TRUE

       /* Physical flags must agree with the governed payload. */
       OR (v.configuration_payload->>'synthetic_data_only')::boolean
            IS DISTINCT FROM v.synthetic_data_only_flag
       OR (v.configuration_payload->>'no_final_offer_terms')::boolean
            IS DISTINCT FROM v.no_final_offer_terms_flag
       OR (v.configuration_payload->>'no_production_adverse_action')::boolean
            IS DISTINCT FROM v.no_production_adverse_action_flag
       OR (v.configuration_payload->>'acquisition_source_review_only')::boolean
            IS DISTINCT FROM v.acquisition_source_review_only_flag

       OR v.configuration_hash IS DISTINCT FROM
            msbf_ctl.m2_1_hash_jsonb(v.configuration_payload) THEN
        RAISE EXCEPTION
            'M2.1 policy configuration is absent, unapproved, malformed, '
            'boundary-inconsistent, or hash-inconsistent.';
    END IF;
END;
$function$;

CREATE OR REPLACE FUNCTION msbf_ctl.m2_1_assert_acceptance_ready(
    p_run_id bigint
)
RETURNS void
LANGUAGE plpgsql
AS $function$
DECLARE
    v_status text;
    v_pos bigint;
    v_neg bigint;
BEGIN
    PERFORM msbf_ctl.m2_1_assert_configuration(p_run_id);
    PERFORM msbf_ctl.m2_1_assert_prerequisite_status(p_run_id);

    SELECT run_status
    INTO v_status
    FROM msbf_ctl.run_registry
    WHERE run_id = p_run_id;

    IF v_status <> 'M2_1_VALIDATED' THEN
        RAISE EXCEPTION
            'M2.1 acceptance requires M2_1_VALIDATED; observed %.',
            v_status;
    END IF;

    SELECT count(*) FILTER (WHERE status = 'PASS')
    INTO v_pos
    FROM msbf_ctl.run_evidence
    WHERE run_id = p_run_id
      AND evidence_code LIKE 'M2_1_POS_%';

    SELECT count(*) FILTER (WHERE status = 'PASS')
    INTO v_neg
    FROM msbf_ctl.run_evidence
    WHERE run_id = p_run_id
      AND evidence_code LIKE 'M2_1_NEG_%';

    IF v_pos <> 112 OR v_neg <> 20 THEN
        RAISE EXCEPTION
            'M2.1 acceptance requires 112 positive and 20 negative PASS '
            'records; observed % and %.',
            v_pos,
            v_neg;
    END IF;
END;
$function$;

/* Prove the two formerly ineffective negative mutations now fail closed. */
ALTER TABLE _m2_1_r5_boundary_recovery
    ADD COLUMN final_offer_boundary_rejected boolean,
    ADD COLUMN final_offer_sqlstate text,
    ADD COLUMN final_offer_message text,
    ADD COLUMN acquisition_boundary_rejected boolean,
    ADD COLUMN acquisition_sqlstate text,
    ADD COLUMN acquisition_message text;

DO $m2_1_r5_mutation_proof$
DECLARE
    v_rejected boolean;
    v_state text;
    v_message text;
BEGIN
    v_rejected := FALSE;
    v_state := NULL;
    v_message := NULL;

    BEGIN
        UPDATE msbf_ctl.m2_1_policy_profile
        SET no_final_offer_terms_flag = FALSE
        WHERE policy_code = 'M2_1_ELIGIBILITY_POLICY_V1';

        PERFORM msbf_ctl.m2_1_assert_configuration(
            (SELECT run_id FROM _m2_1_r5_boundary_recovery)
        );

        RAISE EXCEPTION USING
            ERRCODE = 'P0002',
            MESSAGE = 'M2_1_NEGATIVE_CONTROL_NOT_REJECTED';
    EXCEPTION
        WHEN OTHERS THEN
            v_state := SQLSTATE;
            v_message := SQLERRM;
            v_rejected := (
                SQLSTATE <> 'P0002'
                OR SQLERRM <> 'M2_1_NEGATIVE_CONTROL_NOT_REJECTED'
            );
    END;

    UPDATE _m2_1_r5_boundary_recovery
    SET
        final_offer_boundary_rejected = v_rejected,
        final_offer_sqlstate = v_state,
        final_offer_message = v_message
    WHERE run_id IS NOT NULL;

    v_rejected := FALSE;
    v_state := NULL;
    v_message := NULL;

    BEGIN
        UPDATE msbf_ctl.m2_1_policy_profile
        SET acquisition_source_review_only_flag = FALSE
        WHERE policy_code = 'M2_1_ELIGIBILITY_POLICY_V1';

        PERFORM msbf_ctl.m2_1_assert_configuration(
            (SELECT run_id FROM _m2_1_r5_boundary_recovery)
        );

        RAISE EXCEPTION USING
            ERRCODE = 'P0002',
            MESSAGE = 'M2_1_NEGATIVE_CONTROL_NOT_REJECTED';
    EXCEPTION
        WHEN OTHERS THEN
            v_state := SQLSTATE;
            v_message := SQLERRM;
            v_rejected := (
                SQLSTATE <> 'P0002'
                OR SQLERRM <> 'M2_1_NEGATIVE_CONTROL_NOT_REJECTED'
            );
    END;

    UPDATE _m2_1_r5_boundary_recovery
    SET
        acquisition_boundary_rejected = v_rejected,
        acquisition_sqlstate = v_state,
        acquisition_message = v_message
    WHERE run_id IS NOT NULL;
END;
$m2_1_r5_mutation_proof$;

/* Preserve the failed 18-of-20 execution as audit history. */
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
    run_id,
    'M2_1_HIST_NEG_004_005_V0_2R4',
    'PORTFOLIO',
    'SUPERSEDED_BOUNDARY_ASSERTION_NEGATIVE_CONTROL_FINDING',
    NULL::numeric(24,10),
    'M2_1_NEG_004_FINAL_OFFER_BOUNDARY|'
        || 'M2_1_NEG_005_ACQUISITION_CREDIT_BOUNDARY',
    'AUDIT_HISTORY',
    'SUPERSEDED',
    'Program 136 v0.2R4 produced 18 of 20 PASS because the prior '
    || 'configuration assertion did not compare the physical final-offer '
    || 'and acquisition-review-only flags to the approved policy payload. '
    || 'v0.2R5 strengthens the assertion and independently proves both '
    || 'mutations are rejected.'
FROM _m2_1_r5_boundary_recovery
ON CONFLICT (run_id, evidence_code, segment_key)
DO UPDATE
SET
    metric_name = EXCLUDED.metric_name,
    metric_value_numeric = NULL,
    metric_value_text = EXCLUDED.metric_value_text,
    unit_code = EXCLUDED.unit_code,
    status = EXCLUDED.status,
    interpretation = EXCLUDED.interpretation,
    created_at = clock_timestamp();

ALTER TABLE _m2_1_r5_boundary_recovery
    ADD COLUMN final_configuration_function_complete boolean,
    ADD COLUMN final_acceptance_calls_configuration boolean,
    ADD COLUMN final_policy_flags_valid boolean,
    ADD COLUMN final_run_status text,
    ADD COLUMN final_contract_status text,
    ADD COLUMN final_positive_passes bigint,
    ADD COLUMN final_negative_evidence_rows bigint,
    ADD COLUMN preserved_history_rows bigint,
    ADD COLUMN recovery_status text;

UPDATE _m2_1_r5_boundary_recovery AS recovery
SET
    final_configuration_function_complete =
    (
        SELECT
            position(
                'no_final_offer_terms_flag is distinct from true'
                in lower(
                    pg_get_functiondef(
                        'msbf_ctl.m2_1_assert_configuration(bigint)'::regprocedure
                    )
                )
            ) > 0
            AND
            position(
                'acquisition_source_review_only_flag is distinct from true'
                in lower(
                    pg_get_functiondef(
                        'msbf_ctl.m2_1_assert_configuration(bigint)'::regprocedure
                    )
                )
            ) > 0
            AND
            position(
                'no_production_adverse_action_flag is distinct from true'
                in lower(
                    pg_get_functiondef(
                        'msbf_ctl.m2_1_assert_configuration(bigint)'::regprocedure
                    )
                )
            ) > 0
            AND
            position(
                'synthetic_data_only_flag is distinct from true'
                in lower(
                    pg_get_functiondef(
                        'msbf_ctl.m2_1_assert_configuration(bigint)'::regprocedure
                    )
                )
            ) > 0
    ),

    final_acceptance_calls_configuration =
    (
        SELECT position(
            'm2_1_assert_configuration'
            in lower(
                pg_get_functiondef(
                    'msbf_ctl.m2_1_assert_acceptance_ready(bigint)'::regprocedure
                )
            )
        ) > 0
    ),

    final_policy_flags_valid =
    (
        SELECT
            p.synthetic_data_only_flag
            AND p.no_final_offer_terms_flag
            AND p.no_production_adverse_action_flag
            AND p.acquisition_source_review_only_flag
            AND (p.configuration_payload->>'synthetic_data_only')::boolean
                IS NOT DISTINCT FROM p.synthetic_data_only_flag
            AND (p.configuration_payload->>'no_final_offer_terms')::boolean
                IS NOT DISTINCT FROM p.no_final_offer_terms_flag
            AND (p.configuration_payload->>'no_production_adverse_action')::boolean
                IS NOT DISTINCT FROM p.no_production_adverse_action_flag
            AND (p.configuration_payload->>'acquisition_source_review_only')::boolean
                IS NOT DISTINCT FROM p.acquisition_source_review_only_flag
            AND p.configuration_hash =
                msbf_ctl.m2_1_hash_jsonb(p.configuration_payload)
        FROM msbf_ctl.m2_1_policy_profile AS p
        WHERE p.policy_code = 'M2_1_ELIGIBILITY_POLICY_V1'
    ),

    final_run_status =
    (
        SELECT run_status
        FROM msbf_ctl.run_registry
        WHERE run_id = recovery.run_id
    ),

    final_contract_status =
    (
        SELECT contract_status
        FROM msbf_ctl.m2_1_strategy_contract_registry
        WHERE module1_run_id = recovery.run_id
    ),

    final_positive_passes =
    (
        SELECT count(*)
        FROM msbf_ctl.run_evidence
        WHERE run_id = recovery.run_id
          AND evidence_code LIKE 'M2_1_POS_%'
          AND status = 'PASS'
    ),

    final_negative_evidence_rows =
    (
        SELECT count(*)
        FROM msbf_ctl.run_evidence
        WHERE run_id = recovery.run_id
          AND evidence_code LIKE 'M2_1_NEG_%'
    ),

    preserved_history_rows =
    (
        SELECT count(*)
        FROM msbf_ctl.run_evidence
        WHERE run_id = recovery.run_id
          AND evidence_code = 'M2_1_HIST_NEG_004_005_V0_2R4'
    ),

    recovery_status = 'PASS'
WHERE recovery.run_id IS NOT NULL;

DO $m2_1_r5_final_guard$
DECLARE
    v record;
BEGIN
    SELECT *
    INTO v
    FROM _m2_1_r5_boundary_recovery;

    IF v.final_offer_boundary_rejected IS DISTINCT FROM TRUE
       OR v.acquisition_boundary_rejected IS DISTINCT FROM TRUE
       OR v.final_configuration_function_complete IS DISTINCT FROM TRUE
       OR v.final_acceptance_calls_configuration IS DISTINCT FROM TRUE
       OR v.final_policy_flags_valid IS DISTINCT FROM TRUE
       OR v.final_run_status <> 'M2_1_VALIDATED'
       OR v.final_contract_status <> 'VALIDATED'
       OR v.final_positive_passes <> 112
       OR v.final_negative_evidence_rows <> 0
       OR v.preserved_history_rows <> 1 THEN
        RAISE EXCEPTION
            'M2.1 v0.2R5 final boundary-assertion recovery state failed: %',
            row_to_json(v);
    END IF;
END;
$m2_1_r5_final_guard$;

COMMIT;

SELECT
    prior_run_status,
    prior_contract_status,
    positive_checks,
    positive_passes,
    positive_failures,
    negative_evidence_rows,

    prior_final_offer_check_present,
    prior_acquisition_boundary_check_present,
    prior_acceptance_calls_configuration,

    final_offer_boundary_rejected,
    final_offer_sqlstate,
    final_offer_message,

    acquisition_boundary_rejected,
    acquisition_sqlstate,
    acquisition_message,

    final_configuration_function_complete,
    final_acceptance_calls_configuration,
    final_policy_flags_valid,
    final_run_status,
    final_contract_status,
    final_positive_passes,
    final_negative_evidence_rows,
    preserved_history_rows,
    recovery_status
FROM _m2_1_r5_boundary_recovery;
