/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.5 — Daily Remittance, Exposure & Portfolio Monitoring

Program     : 168A_msbf_m2_5_failed_negative_control_format_recovery_v0_2R4.sql
Version     : v0.2R4

Purpose
-------
Read-only recovery and state proof after Program 168 v0.2 raised SQLSTATE
22023 in the diagnostic `format()` expression for:

    M2_5_NEG_020_SERVICING_NOTICE_PAYLOAD_VOCABULARY

Execute `ROLLBACK;` before this program. The failed Program 168 outer
transaction should leave the committed Program 167 validated state unchanged,
with 120 positive PASS rows, zero negative evidence rows, zero acceptance rows,
and the complete generated M2.5 population intact.

This program also independently proves that the five Negative Control 020
payload keys are rejected by the committed boundary function.

Writes
------
Temporary diagnostics only. No persistent state changes.

Required result
---------------
Exactly one row with recovery_status = PASS.
============================================================================ */

BEGIN;

SET LOCAL statement_timeout = '20min';
SET LOCAL jit = off;
SET LOCAL client_min_messages = warning;

DROP TABLE IF EXISTS _m2_5_r4_negative_control_recovery;

CREATE TEMP TABLE _m2_5_r4_negative_control_recovery
(
    run_id                                  bigint,
    run_status                              text,
    contract_status                         text,

    generation_evidence_rows                bigint,
    positive_evidence_rows                  bigint,
    positive_passes                         bigint,
    positive_failures                       bigint,
    negative_evidence_rows                  bigint,
    failed_evidence_rows                    bigint,
    acceptance_rows                         bigint,
    blocking_errors                         bigint,

    source_rows                             bigint,
    daily_rows                              bigint,
    latest_rows                             bigint,
    archive_rows                            bigint,
    portfolio_daily_rows                    bigint,
    comparison_rows                         bigint,
    canonical_entities                      bigint,

    registry_combined_set_hash              text,
    physical_combined_set_hash              text,

    collection_action_rejected              boolean,
    write_off_rejected                      boolean,
    restructure_offer_rejected              boolean,
    external_notice_payload_rejected        boolean,
    production_adverse_notice_rejected      boolean,

    recovery_status                         text
)
ON COMMIT PRESERVE ROWS;

INSERT INTO _m2_5_r4_negative_control_recovery
(
    run_id,
    run_status,
    contract_status,
    generation_evidence_rows,
    positive_evidence_rows,
    positive_passes,
    positive_failures,
    negative_evidence_rows,
    failed_evidence_rows,
    acceptance_rows,
    blocking_errors,
    source_rows,
    daily_rows,
    latest_rows,
    archive_rows,
    portfolio_daily_rows,
    comparison_rows,
    canonical_entities,
    registry_combined_set_hash,
    physical_combined_set_hash,
    collection_action_rejected,
    write_off_rejected,
    restructure_offer_rejected,
    external_notice_payload_rejected,
    production_adverse_notice_rejected,
    recovery_status
)
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
        combined_set_hash
    FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry
    WHERE module1_run_id = (SELECT run_id FROM run_context)
),
evidence AS
(
    SELECT
        count(*) FILTER
        (
            WHERE evidence_code LIKE 'M2_5_%'
              AND evidence_code NOT LIKE 'M2_5_POS_%'
              AND evidence_code NOT LIKE 'M2_5_NEG_%'
              AND evidence_code <> 'M2_5_ACCEPTANCE_SUMMARY'
        )::bigint AS generation_evidence_rows,

        count(*) FILTER
        (
            WHERE evidence_code LIKE 'M2_5_POS_%'
        )::bigint AS positive_evidence_rows,

        count(*) FILTER
        (
            WHERE evidence_code LIKE 'M2_5_POS_%'
              AND status = 'PASS'
        )::bigint AS positive_passes,

        count(*) FILTER
        (
            WHERE evidence_code LIKE 'M2_5_POS_%'
              AND status <> 'PASS'
        )::bigint AS positive_failures,

        count(*) FILTER
        (
            WHERE evidence_code LIKE 'M2_5_NEG_%'
        )::bigint AS negative_evidence_rows,

        count(*) FILTER
        (
            WHERE evidence_code LIKE 'M2_5_%'
              AND status = 'FAIL'
        )::bigint AS failed_evidence_rows

    FROM msbf_ctl.run_evidence
    WHERE run_id = (SELECT run_id FROM run_context)
),
physical AS
(
    SELECT
        (
            SELECT count(*)
            FROM msbf_m2.advance_monitoring_source_snapshot
            WHERE module1_run_id = (SELECT run_id FROM run_context)
        )::bigint AS source_rows,

        (
            SELECT count(*)
            FROM msbf_m2.advance_daily_remittance_monitoring
            WHERE module1_run_id = (SELECT run_id FROM run_context)
        )::bigint AS daily_rows,

        (
            SELECT count(*)
            FROM msbf_m2.advance_portfolio_monitoring_latest
            WHERE module1_run_id = (SELECT run_id FROM run_context)
        )::bigint AS latest_rows,

        (
            SELECT count(*)
            FROM msbf_m2.advance_portfolio_monitoring_archive
            WHERE module1_run_id = (SELECT run_id FROM run_context)
        )::bigint AS archive_rows,

        (
            SELECT count(*)
            FROM msbf_m2.portfolio_daily_monitoring_summary
            WHERE module1_run_id = (SELECT run_id FROM run_context)
        )::bigint AS portfolio_daily_rows,

        (
            SELECT count(*)
            FROM msbf_m2.v_m2_5_matched_monitoring_comparison
            WHERE module1_run_id = (SELECT run_id FROM run_context)
        )::bigint AS comparison_rows,

        (
            SELECT canonical_entities
            FROM msbf_m2.v_m2_5_canonical_hash
            WHERE module1_run_id = (SELECT run_id FROM run_context)
        )::bigint AS canonical_entities,

        (
            SELECT combined_set_hash
            FROM msbf_m2.v_m2_5_canonical_hash
            WHERE module1_run_id = (SELECT run_id FROM run_context)
        ) AS physical_combined_set_hash,

        (
            SELECT count(*)
            FROM msbf_ctl.acceptance_gate_result
            WHERE run_id = (SELECT run_id FROM run_context)
              AND gate_id = 'M2_5_DAILY_REMITTANCE_EXPOSURE_PORTFOLIO_MONITORING'
        )::bigint AS acceptance_rows,

        (
            SELECT count(*)
            FROM msbf_ctl.profile_resolution_error
            WHERE run_id = (SELECT run_id FROM run_context)
              AND severity = 'BLOCKING'
        )::bigint AS blocking_errors
)
SELECT
    run_context.run_id,
    run_context.run_status,
    registry.contract_status,
    evidence.generation_evidence_rows,
    evidence.positive_evidence_rows,
    evidence.positive_passes,
    evidence.positive_failures,
    evidence.negative_evidence_rows,
    evidence.failed_evidence_rows,
    physical.acceptance_rows,
    physical.blocking_errors,
    physical.source_rows,
    physical.daily_rows,
    physical.latest_rows,
    physical.archive_rows,
    physical.portfolio_daily_rows,
    physical.comparison_rows,
    physical.canonical_entities,
    registry.combined_set_hash,
    physical.physical_combined_set_hash,
    FALSE,
    FALSE,
    FALSE,
    FALSE,
    FALSE,
    NULL::text
FROM run_context
CROSS JOIN registry
CROSS JOIN evidence
CROSS JOIN physical;

DO $m2_5_r4_payload_proof$
DECLARE
    v_collection_rejected boolean := FALSE;
    v_writeoff_rejected boolean := FALSE;
    v_restructure_rejected boolean := FALSE;
    v_notice_rejected boolean := FALSE;
    v_adverse_rejected boolean := FALSE;
BEGIN
    BEGIN
        PERFORM msbf_ctl.m2_5_assert_no_servicing_action_payload
        (
            '{"collection_action":"CONTACT"}'::jsonb
        );
    EXCEPTION WHEN OTHERS THEN
        v_collection_rejected :=
            SQLERRM LIKE
            'M2.5 boundary rejected prohibited servicing payload key collection_action%';
    END;

    BEGIN
        PERFORM msbf_ctl.m2_5_assert_no_servicing_action_payload
        (
            '{"write_off":true}'::jsonb
        );
    EXCEPTION WHEN OTHERS THEN
        v_writeoff_rejected :=
            SQLERRM LIKE
            'M2.5 boundary rejected prohibited servicing payload key write_off%';
    END;

    BEGIN
        PERFORM msbf_ctl.m2_5_assert_no_servicing_action_payload
        (
            '{"restructure_offer":{"term_days":30}}'::jsonb
        );
    EXCEPTION WHEN OTHERS THEN
        v_restructure_rejected :=
            SQLERRM LIKE
            'M2.5 boundary rejected prohibited servicing payload key restructure_offer%';
    END;

    BEGIN
        PERFORM msbf_ctl.m2_5_assert_no_servicing_action_payload
        (
            '{"external_notice_payload":{}}'::jsonb
        );
    EXCEPTION WHEN OTHERS THEN
        v_notice_rejected :=
            SQLERRM LIKE
            'M2.5 boundary rejected prohibited servicing payload key external_notice_payload%';
    END;

    BEGIN
        PERFORM msbf_ctl.m2_5_assert_no_servicing_action_payload
        (
            '{"production_adverse_action_notice":true}'::jsonb
        );
    EXCEPTION WHEN OTHERS THEN
        v_adverse_rejected :=
            SQLERRM LIKE
            'M2.5 boundary rejected prohibited servicing payload key production_adverse_action_notice%';
    END;

    UPDATE _m2_5_r4_negative_control_recovery AS recovery
    SET
        collection_action_rejected = v_collection_rejected,
        write_off_rejected = v_writeoff_rejected,
        restructure_offer_rejected = v_restructure_rejected,
        external_notice_payload_rejected = v_notice_rejected,
        production_adverse_notice_rejected = v_adverse_rejected
    WHERE recovery.run_id IS NOT NULL;
END;
$m2_5_r4_payload_proof$;

UPDATE _m2_5_r4_negative_control_recovery AS recovery
SET recovery_status =
    CASE
        WHEN recovery.run_status = 'M2_5_VALIDATED'
         AND recovery.contract_status = 'VALIDATED'
         AND recovery.generation_evidence_rows = 24
         AND recovery.positive_evidence_rows = 120
         AND recovery.positive_passes = 120
         AND recovery.positive_failures = 0
         AND recovery.negative_evidence_rows = 0
         AND recovery.failed_evidence_rows = 0
         AND recovery.acceptance_rows = 0
         AND recovery.blocking_errors = 0
         AND recovery.source_rows = 59
         AND recovery.daily_rows = 7080
         AND recovery.latest_rows = 59
         AND recovery.archive_rows = 59
         AND recovery.portfolio_daily_rows = 240
         AND recovery.comparison_rows = 15
         AND recovery.canonical_entities = 7536
         AND recovery.registry_combined_set_hash IS NOT DISTINCT FROM
             recovery.physical_combined_set_hash
         AND recovery.collection_action_rejected
         AND recovery.write_off_rejected
         AND recovery.restructure_offer_rejected
         AND recovery.external_notice_payload_rejected
         AND recovery.production_adverse_notice_rejected
        THEN 'PASS'
        ELSE 'FAIL'
    END
WHERE recovery.run_id IS NOT NULL;

COMMIT;

SELECT
    recovery.run_id,
    recovery.run_status,
    recovery.contract_status,
    recovery.generation_evidence_rows,
    recovery.positive_evidence_rows,
    recovery.positive_passes,
    recovery.positive_failures,
    recovery.negative_evidence_rows,
    recovery.failed_evidence_rows,
    recovery.acceptance_rows,
    recovery.blocking_errors,
    recovery.source_rows,
    recovery.daily_rows,
    recovery.latest_rows,
    recovery.archive_rows,
    recovery.portfolio_daily_rows,
    recovery.comparison_rows,
    recovery.canonical_entities,
    recovery.registry_combined_set_hash,
    recovery.physical_combined_set_hash,
    recovery.collection_action_rejected,
    recovery.write_off_rejected,
    recovery.restructure_offer_rejected,
    recovery.external_notice_payload_rejected,
    recovery.production_adverse_notice_rejected,
    recovery.recovery_status
FROM _m2_5_r4_negative_control_recovery AS recovery;
