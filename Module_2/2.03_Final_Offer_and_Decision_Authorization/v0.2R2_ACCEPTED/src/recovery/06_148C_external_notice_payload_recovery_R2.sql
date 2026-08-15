/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.3 — Final Offer & Decision Authorization

Program     : 148C_msbf_m2_3_failed_external_notice_payload_boundary_recovery_v0_2R2.sql
Version     : v0.2R2
Purpose     : Repair the sole failed negative-control boundary identified after
              Programs 148–151 completed successfully:

                  M2_3_NEG_019_EXTERNAL_NOTICE_PAYLOAD

              The v0.2R1 function rejected `external_notice`, but not the exact
              governed/tested key `external_notice_payload`. The recovery also
              aligns `account_number`, which already appears in the physical
              prohibited-column controls.

Writes      : CREATE OR REPLACE FUNCTION only for
              msbf_ctl.m2_3_assert_no_booking_payload(jsonb).

Preserves   : All generated rows, all hashes, all 120 positive-control evidence,
              run/contract lifecycle, M2.2 predecessor state, and acceptance
              state.

Run after   : Click Stop, then execute ROLLBACK after the failed Program 152.
Required    : recovery_status = PASS.
============================================================================ */

BEGIN;

SET LOCAL lock_timeout = '10s';
SET LOCAL statement_timeout = '20min';
SET LOCAL jit = off;

DROP TABLE IF EXISTS _m2_3_r2_boundary_recovery;

CREATE TEMP TABLE _m2_3_r2_boundary_recovery
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
registry AS
(
    SELECT
        contract_status,
        canonical_entities,
        combined_set_hash
    FROM msbf_ctl.m2_3_final_decision_contract_registry
    WHERE module1_run_id = (SELECT run_id FROM run_context)
),
controls AS
(
    SELECT
        count(*) FILTER
        (
            WHERE evidence_code LIKE 'M2_3_POS_%'
        )::bigint AS positive_checks,

        count(*) FILTER
        (
            WHERE evidence_code LIKE 'M2_3_POS_%'
              AND status = 'PASS'
        )::bigint AS positive_passes,

        count(*) FILTER
        (
            WHERE evidence_code LIKE 'M2_3_POS_%'
              AND status <> 'PASS'
        )::bigint AS positive_failures,

        count(*) FILTER
        (
            WHERE evidence_code LIKE 'M2_3_NEG_%'
        )::bigint AS negative_evidence_rows

    FROM msbf_ctl.run_evidence
    WHERE run_id = (SELECT run_id FROM run_context)
),
physical AS
(
    SELECT
        (
            SELECT count(*)
            FROM msbf_m2.application_final_decision_source_snapshot
            WHERE module1_run_id = (SELECT run_id FROM run_context)
        )::bigint AS source_rows,

        (
            SELECT count(*)
            FROM msbf_m2.application_final_offer_decision_snapshot
            WHERE module1_run_id = (SELECT run_id FROM run_context)
        )::bigint AS snapshot_rows,

        (
            SELECT count(*)
            FROM msbf_m2.application_final_offer_decision_latest
            WHERE module1_run_id = (SELECT run_id FROM run_context)
        )::bigint AS latest_rows,

        (
            SELECT count(*)
            FROM msbf_m2.application_final_offer_decision_archive
            WHERE module1_run_id = (SELECT run_id FROM run_context)
        )::bigint AS archive_rows,

        (
            SELECT count(*)
            FROM msbf_m2.v_m2_3_matched_scenario_comparison
            WHERE module1_run_id = (SELECT run_id FROM run_context)
        )::bigint AS comparison_rows,

        (
            SELECT count(*)
            FROM msbf_ctl.acceptance_gate_result
            WHERE run_id = (SELECT run_id FROM run_context)
              AND gate_id = 'M2_3_FINAL_OFFER_DECISION_AUTHORIZATION'
        )::bigint AS acceptance_rows
),
function_state AS
(
    SELECT pg_get_functiondef
    (
        'msbf_ctl.m2_3_assert_no_booking_payload(jsonb)'::regprocedure
    ) AS function_definition
)
SELECT
    run_context.run_id,
    run_context.run_status AS prior_run_status,
    registry.contract_status AS prior_contract_status,
    registry.canonical_entities,
    registry.combined_set_hash,

    controls.positive_checks,
    controls.positive_passes,
    controls.positive_failures,
    controls.negative_evidence_rows,

    physical.source_rows,
    physical.snapshot_rows,
    physical.latest_rows,
    physical.archive_rows,
    physical.comparison_rows,
    physical.acceptance_rows,

    position
    (
        '''external_notice'''
        IN function_state.function_definition
    ) > 0 AS prior_external_notice_guard,

    position
    (
        '''external_notice_payload'''
        IN function_state.function_definition
    ) > 0 AS prior_external_notice_payload_guard,

    position
    (
        '''account_number'''
        IN function_state.function_definition
    ) > 0 AS prior_account_number_guard

FROM run_context
CROSS JOIN registry
CROSS JOIN controls
CROSS JOIN physical
CROSS JOIN function_state;

DO $m2_3_r2_precondition_guard$
DECLARE
    v record;
BEGIN
    SELECT
        run_id,
        prior_run_status,
        prior_contract_status,
        canonical_entities,
        combined_set_hash,
        positive_checks,
        positive_passes,
        positive_failures,
        negative_evidence_rows,
        source_rows,
        snapshot_rows,
        latest_rows,
        archive_rows,
        comparison_rows,
        acceptance_rows,
        prior_external_notice_guard,
        prior_external_notice_payload_guard,
        prior_account_number_guard
    INTO v
    FROM _m2_3_r2_boundary_recovery;

    IF v.prior_run_status <> 'M2_3_VALIDATED'
       OR v.prior_contract_status <> 'VALIDATED'
       OR v.canonical_entities <> 6029
       OR v.combined_set_hash IS NULL
       OR v.positive_checks <> 120
       OR v.positive_passes <> 120
       OR v.positive_failures <> 0
       OR v.negative_evidence_rows <> 0
       OR v.source_rows <> 1500
       OR v.snapshot_rows <> 1500
       OR v.latest_rows <> 1500
       OR v.archive_rows <> 1500
       OR v.comparison_rows <> 750
       OR v.acceptance_rows <> 0
       OR v.prior_external_notice_guard IS DISTINCT FROM TRUE
       OR v.prior_external_notice_payload_guard IS DISTINCT FROM FALSE
       OR v.prior_account_number_guard IS DISTINCT FROM FALSE THEN
        RAISE EXCEPTION
            'M2.3 v0.2R2 boundary-recovery preconditions failed: %',
            row_to_json(v);
    END IF;
END;
$m2_3_r2_precondition_guard$;

/* --------------------------------------------------------------------------
Repair the exact prohibited-payload vocabulary. The function remains a
pure fail-closed assertion and does not update any persistent business row.
-------------------------------------------------------------------------- */
CREATE OR REPLACE FUNCTION msbf_ctl.m2_3_assert_no_booking_payload
(
    p_payload jsonb
)
RETURNS void
LANGUAGE plpgsql
AS $function$
DECLARE
    v_key text;
BEGIN
    SELECT key
    INTO v_key
    FROM jsonb_object_keys(coalesce(p_payload, '{}'::jsonb)) AS key
    WHERE lower(key) IN
    (
        'booking',
        'booking_status',
        'funding',
        'funding_status',
        'funded_amount',
        'production_adverse_action_notice',
        'external_notice',
        'external_notice_payload',
        'account_opened',
        'account_number',
        'loan_number'
    )
    LIMIT 1;

    IF v_key IS NOT NULL THEN
        RAISE EXCEPTION
            'M2.3 boundary rejected prohibited payload key %.',
            v_key;
    END IF;
END;
$function$;

ALTER TABLE _m2_3_r2_boundary_recovery
    ADD COLUMN final_external_notice_guard boolean,
    ADD COLUMN final_external_notice_payload_guard boolean,
    ADD COLUMN final_account_number_guard boolean,
    ADD COLUMN booking_status_rejected boolean,
    ADD COLUMN funding_status_rejected boolean,
    ADD COLUMN external_notice_payload_rejected boolean,
    ADD COLUMN account_number_rejected boolean,
    ADD COLUMN production_adverse_action_rejected boolean,
    ADD COLUMN harmless_payload_allowed boolean,
    ADD COLUMN final_run_status text,
    ADD COLUMN final_contract_status text,
    ADD COLUMN final_positive_passes bigint,
    ADD COLUMN final_negative_evidence_rows bigint,
    ADD COLUMN final_acceptance_rows bigint,
    ADD COLUMN recovery_status text;

DO $m2_3_r2_function_proof$
DECLARE
    v_booking_rejected boolean := FALSE;
    v_funding_rejected boolean := FALSE;
    v_external_rejected boolean := FALSE;
    v_account_rejected boolean := FALSE;
    v_adverse_rejected boolean := FALSE;
    v_harmless_allowed boolean := FALSE;
BEGIN
    BEGIN
        PERFORM msbf_ctl.m2_3_assert_no_booking_payload
        (
            '{"booking_status":"BOOKED"}'::jsonb
        );
    EXCEPTION
        WHEN OTHERS THEN
            v_booking_rejected :=
                SQLERRM LIKE
                'M2.3 boundary rejected prohibited payload key booking_status%';
    END;

    BEGIN
        PERFORM msbf_ctl.m2_3_assert_no_booking_payload
        (
            '{"funding_status":"FUNDED"}'::jsonb
        );
    EXCEPTION
        WHEN OTHERS THEN
            v_funding_rejected :=
                SQLERRM LIKE
                'M2.3 boundary rejected prohibited payload key funding_status%';
    END;

    BEGIN
        PERFORM msbf_ctl.m2_3_assert_no_booking_payload
        (
            '{"external_notice_payload":{}}'::jsonb
        );
    EXCEPTION
        WHEN OTHERS THEN
            v_external_rejected :=
                SQLERRM LIKE
                'M2.3 boundary rejected prohibited payload key external_notice_payload%';
    END;

    BEGIN
        PERFORM msbf_ctl.m2_3_assert_no_booking_payload
        (
            '{"account_number":"SYNTHETIC"}'::jsonb
        );
    EXCEPTION
        WHEN OTHERS THEN
            v_account_rejected :=
                SQLERRM LIKE
                'M2.3 boundary rejected prohibited payload key account_number%';
    END;

    BEGIN
        PERFORM msbf_ctl.m2_3_assert_no_booking_payload
        (
            '{"production_adverse_action_notice":true}'::jsonb
        );
    EXCEPTION
        WHEN OTHERS THEN
            v_adverse_rejected :=
                SQLERRM LIKE
                'M2.3 boundary rejected prohibited payload key production_adverse_action_notice%';
    END;

    BEGIN
        PERFORM msbf_ctl.m2_3_assert_no_booking_payload
        (
            '{"synthetic_decision_note":"permitted"}'::jsonb
        );
        v_harmless_allowed := TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            v_harmless_allowed := FALSE;
    END;

    UPDATE _m2_3_r2_boundary_recovery
    SET
        booking_status_rejected = v_booking_rejected,
        funding_status_rejected = v_funding_rejected,
        external_notice_payload_rejected = v_external_rejected,
        account_number_rejected = v_account_rejected,
        production_adverse_action_rejected = v_adverse_rejected,
        harmless_payload_allowed = v_harmless_allowed;
END;
$m2_3_r2_function_proof$;

UPDATE _m2_3_r2_boundary_recovery AS recovery
SET
    final_external_notice_guard =
    (
        SELECT position
        (
            '''external_notice'''
            IN pg_get_functiondef
            (
                'msbf_ctl.m2_3_assert_no_booking_payload(jsonb)'::regprocedure
            )
        ) > 0
    ),

    final_external_notice_payload_guard =
    (
        SELECT position
        (
            '''external_notice_payload'''
            IN pg_get_functiondef
            (
                'msbf_ctl.m2_3_assert_no_booking_payload(jsonb)'::regprocedure
            )
        ) > 0
    ),

    final_account_number_guard =
    (
        SELECT position
        (
            '''account_number'''
            IN pg_get_functiondef
            (
                'msbf_ctl.m2_3_assert_no_booking_payload(jsonb)'::regprocedure
            )
        ) > 0
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
        FROM msbf_ctl.m2_3_final_decision_contract_registry
        WHERE module1_run_id = recovery.run_id
    ),

    final_positive_passes =
    (
        SELECT count(*)
        FROM msbf_ctl.run_evidence
        WHERE run_id = recovery.run_id
          AND evidence_code LIKE 'M2_3_POS_%'
          AND status = 'PASS'
    ),

    final_negative_evidence_rows =
    (
        SELECT count(*)
        FROM msbf_ctl.run_evidence
        WHERE run_id = recovery.run_id
          AND evidence_code LIKE 'M2_3_NEG_%'
    ),

    final_acceptance_rows =
    (
        SELECT count(*)
        FROM msbf_ctl.acceptance_gate_result
        WHERE run_id = recovery.run_id
          AND gate_id = 'M2_3_FINAL_OFFER_DECISION_AUTHORIZATION'
    );

UPDATE _m2_3_r2_boundary_recovery
SET recovery_status = 'PASS'
WHERE final_external_notice_guard
  AND final_external_notice_payload_guard
  AND final_account_number_guard
  AND booking_status_rejected
  AND funding_status_rejected
  AND external_notice_payload_rejected
  AND account_number_rejected
  AND production_adverse_action_rejected
  AND harmless_payload_allowed
  AND final_run_status = 'M2_3_VALIDATED'
  AND final_contract_status = 'VALIDATED'
  AND final_positive_passes = 120
  AND final_negative_evidence_rows = 0
  AND final_acceptance_rows = 0;

DO $m2_3_r2_final_guard$
DECLARE
    v record;
BEGIN
    SELECT
        final_external_notice_guard,
        final_external_notice_payload_guard,
        final_account_number_guard,
        booking_status_rejected,
        funding_status_rejected,
        external_notice_payload_rejected,
        account_number_rejected,
        production_adverse_action_rejected,
        harmless_payload_allowed,
        final_run_status,
        final_contract_status,
        final_positive_passes,
        final_negative_evidence_rows,
        final_acceptance_rows,
        recovery_status
    INTO v
    FROM _m2_3_r2_boundary_recovery;

    IF v.recovery_status IS DISTINCT FROM 'PASS' THEN
        RAISE EXCEPTION
            'M2.3 v0.2R2 boundary-recovery final state failed: %',
            row_to_json(v);
    END IF;
END;
$m2_3_r2_final_guard$;

COMMIT;

SELECT
    prior_run_status,
    prior_contract_status,
    canonical_entities,
    positive_checks,
    positive_passes,
    positive_failures,
    negative_evidence_rows,
    source_rows,
    snapshot_rows,
    latest_rows,
    archive_rows,
    comparison_rows,
    acceptance_rows,
    prior_external_notice_guard,
    prior_external_notice_payload_guard,
    prior_account_number_guard,
    final_external_notice_guard,
    final_external_notice_payload_guard,
    final_account_number_guard,
    booking_status_rejected,
    funding_status_rejected,
    external_notice_payload_rejected,
    account_number_rejected,
    production_adverse_action_rejected,
    harmless_payload_allowed,
    final_run_status,
    final_contract_status,
    final_positive_passes,
    final_negative_evidence_rows,
    final_acceptance_rows,
    recovery_status
FROM _m2_3_r2_boundary_recovery;
