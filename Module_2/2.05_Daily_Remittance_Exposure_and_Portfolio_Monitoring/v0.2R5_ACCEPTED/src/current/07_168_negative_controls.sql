/* ============================================================================
Revision v0.2R4 correction
-------------------------
- Replaces the malformed diagnostic `format()` expression in Negative Control
  020 with `concat()`.
- PostgreSQL `format()` requires `%s`, `%I`, `%L`, or `%%`; the v0.2 string used
  bare percent signs and raised SQLSTATE 22023 before the negative-control
  transaction could commit.
- No negative-control predicate, payload vocabulary, policy value, generated
  row, hash, lifecycle rule, or business methodology changes.
============================================================================ */

/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.5 — Daily Remittance, Exposure & Portfolio Monitoring

Program     : 168_msbf_m2_5_negative_control_tests_v0_2R4.sql
Version     : v0.2R4

Purpose
-------
Prove fail-closed behavior for policy-boundary drift, prohibited servicing and
notice reasons, duplicate daily grain, invalid remittance/exposure states,
archive immutability, post-generation reruns, premature acceptance, accepted
M2.4 source-hash drift, and prohibited real-debit/collections/write-off/
restructure/external-notice payloads.

Execution model
---------------
Each mutation is isolated inside a PL/pgSQL exception subtransaction. Expected
rejections roll back locally. The outer transaction commits only when all 20
controls return PASS.

Required result
---------------
20 / 20 PASS.
============================================================================ */

BEGIN;

SET LOCAL statement_timeout = '30min';
SET LOCAL jit = off;

DROP TABLE IF EXISTS _m2_5_negative;

CREATE TEMP TABLE _m2_5_negative
(
    evidence_code  text PRIMARY KEY,
    metric_name    text NOT NULL,
    status         text NOT NULL,
    interpretation text NOT NULL
)
ON COMMIT PRESERVE ROWS;

DROP TABLE IF EXISTS _m2_5_nctx;

CREATE TEMP TABLE _m2_5_nctx
ON COMMIT DROP
AS
SELECT
    run.run_id,
    run.run_status
FROM msbf_ctl.run_registry AS run
WHERE run.run_code = 'M1_V0_2_BASELINE_BUILD'
  AND run.run_version = 1;

DO $m2_5_negative_ready$
DECLARE
    v_contract_status text;
    v_positive_passes bigint;
    v_negative_rows bigint;
BEGIN
    SELECT registry.contract_status
    INTO v_contract_status
    FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry AS registry
    WHERE registry.module1_run_id =
          (SELECT run_id FROM _m2_5_nctx);

    SELECT count(*)
    INTO v_positive_passes
    FROM msbf_ctl.run_evidence
    WHERE run_id = (SELECT run_id FROM _m2_5_nctx)
      AND evidence_code LIKE 'M2_5_POS_%'
      AND status = 'PASS';

    SELECT count(*)
    INTO v_negative_rows
    FROM msbf_ctl.run_evidence
    WHERE run_id = (SELECT run_id FROM _m2_5_nctx)
      AND evidence_code LIKE 'M2_5_NEG_%';

    IF (SELECT run_status FROM _m2_5_nctx) <> 'M2_5_VALIDATED'
       OR v_contract_status <> 'VALIDATED'
       OR v_positive_passes <> 120
       OR v_negative_rows <> 0 THEN
        RAISE EXCEPTION
            'M2.5 negative controls require validated state, 120 positive passes, and zero prior negative evidence.';
    END IF;
END;
$m2_5_negative_ready$;

CREATE OR REPLACE FUNCTION pg_temp.m2_5_add_negative
(
    p_code text,
    p_pass boolean,
    p_interpretation text
)
RETURNS void
LANGUAGE plpgsql
AS $function$
BEGIN
    INSERT INTO _m2_5_negative
    (
        evidence_code,
        metric_name,
        status,
        interpretation
    )
    VALUES
    (
        p_code,
        p_code,
        CASE WHEN p_pass THEN 'PASS' ELSE 'FAIL' END,
        p_interpretation
    );
END;
$function$;

/* --------------------------------------------------------------------------
Isolated temporary structures used only by negative controls.
-------------------------------------------------------------------------- */

CREATE TEMP TABLE _m2_5_neg_reason
(
    production_adverse_action_notice_flag boolean NOT NULL,
    servicing_action_authorized_flag boolean NOT NULL,
    CHECK
    (
        production_adverse_action_notice_flag IS FALSE
        AND servicing_action_authorized_flag IS FALSE
    )
)
ON COMMIT DROP;

CREATE TEMP TABLE _m2_5_neg_grain
(
    scenario_id bigint NOT NULL,
    merchant_application_id text NOT NULL,
    monitoring_day_index integer NOT NULL,
    PRIMARY KEY
    (
        scenario_id,
        merchant_application_id,
        monitoring_day_index
    )
)
ON COMMIT DROP;

CREATE TEMP TABLE _m2_5_neg_daily
(
    raw_remittance_amount numeric(18,2) NOT NULL,
    actual_remittance_amount numeric(18,2) NOT NULL,
    receivable_balance_before numeric(18,2) NOT NULL,
    receivable_balance_after numeric(18,2) NOT NULL,
    principal_exposure_proxy numeric(18,2) NOT NULL,
    unearned_finance_charge_proxy numeric(18,2) NOT NULL,
    monitoring_status_rank integer NOT NULL,

    CHECK
    (
        raw_remittance_amount >= 0
        AND actual_remittance_amount >= 0
        AND receivable_balance_before >= 0
        AND receivable_balance_after >= 0
        AND principal_exposure_proxy >= 0
        AND unearned_finance_charge_proxy >= 0
        AND monitoring_status_rank BETWEEN 0 AND 5
    ),

    CHECK
    (
        actual_remittance_amount <= raw_remittance_amount + 0.01
        AND actual_remittance_amount <= receivable_balance_before + 0.01
        AND abs
        (
            receivable_balance_after -
            greatest
            (
                receivable_balance_before - actual_remittance_amount,
                0
            )
        ) <= 0.01
        AND abs
        (
            principal_exposure_proxy +
            unearned_finance_charge_proxy -
            receivable_balance_after
        ) <= 0.02
    )
)
ON COMMIT DROP;

/* --------------------------------------------------------------------------
Twenty governed negative controls.
-------------------------------------------------------------------------- */

DO $m2_5_neg_001_policy_status$
BEGIN
    BEGIN
        UPDATE msbf_ctl.m2_5_policy_profile
        SET policy_status = 'DRAFT'
        WHERE module1_run_id =
              (SELECT run_id FROM _m2_5_nctx);
        PERFORM pg_temp.m2_5_add_negative
        (
            'M2_5_NEG_001_POLICY_STATUS',
            FALSE,
            'Expected rejection did not occur.'
        );
    EXCEPTION
        WHEN check_violation THEN
            PERFORM pg_temp.m2_5_add_negative
            (
                'M2_5_NEG_001_POLICY_STATUS',
                TRUE,
                SQLERRM
            );
    END;
END;
$m2_5_neg_001_policy_status$;
DO $m2_5_neg_002_real_debit_boundary$
BEGIN
    BEGIN
        UPDATE msbf_ctl.m2_5_policy_profile
        SET no_real_debit_instruction_flag = FALSE
        WHERE module1_run_id =
              (SELECT run_id FROM _m2_5_nctx);

        PERFORM msbf_ctl.m2_5_assert_configuration
        (
            (SELECT run_id FROM _m2_5_nctx)
        );
        PERFORM pg_temp.m2_5_add_negative
        (
            'M2_5_NEG_002_REAL_DEBIT_BOUNDARY',
            FALSE,
            'Expected rejection did not occur.'
        );
    EXCEPTION
        WHEN OTHERS THEN
            PERFORM pg_temp.m2_5_add_negative
            (
                'M2_5_NEG_002_REAL_DEBIT_BOUNDARY',
                TRUE,
                SQLERRM
            );
    END;
END;
$m2_5_neg_002_real_debit_boundary$;
DO $m2_5_neg_003_external_notice_boundary$
BEGIN
    BEGIN
        UPDATE msbf_ctl.m2_5_policy_profile
        SET no_external_notice_generation_flag = FALSE
        WHERE module1_run_id =
              (SELECT run_id FROM _m2_5_nctx);

        PERFORM msbf_ctl.m2_5_assert_configuration
        (
            (SELECT run_id FROM _m2_5_nctx)
        );
        PERFORM pg_temp.m2_5_add_negative
        (
            'M2_5_NEG_003_EXTERNAL_NOTICE_BOUNDARY',
            FALSE,
            'Expected rejection did not occur.'
        );
    EXCEPTION
        WHEN OTHERS THEN
            PERFORM pg_temp.m2_5_add_negative
            (
                'M2_5_NEG_003_EXTERNAL_NOTICE_BOUNDARY',
                TRUE,
                SQLERRM
            );
    END;
END;
$m2_5_neg_003_external_notice_boundary$;
DO $m2_5_neg_004_adverse_notice_boundary$
BEGIN
    BEGIN
        UPDATE msbf_ctl.m2_5_policy_profile
        SET no_production_adverse_action_notice_flag = FALSE
        WHERE module1_run_id =
              (SELECT run_id FROM _m2_5_nctx);

        PERFORM msbf_ctl.m2_5_assert_configuration
        (
            (SELECT run_id FROM _m2_5_nctx)
        );
        PERFORM pg_temp.m2_5_add_negative
        (
            'M2_5_NEG_004_ADVERSE_NOTICE_BOUNDARY',
            FALSE,
            'Expected rejection did not occur.'
        );
    EXCEPTION
        WHEN OTHERS THEN
            PERFORM pg_temp.m2_5_add_negative
            (
                'M2_5_NEG_004_ADVERSE_NOTICE_BOUNDARY',
                TRUE,
                SQLERRM
            );
    END;
END;
$m2_5_neg_004_adverse_notice_boundary$;
DO $m2_5_neg_005_write_off_restructure_boundary$
BEGIN
    BEGIN
        UPDATE msbf_ctl.m2_5_policy_profile
        SET no_write_off_or_restructure_action_flag = FALSE
        WHERE module1_run_id =
              (SELECT run_id FROM _m2_5_nctx);

        PERFORM msbf_ctl.m2_5_assert_configuration
        (
            (SELECT run_id FROM _m2_5_nctx)
        );
        PERFORM pg_temp.m2_5_add_negative
        (
            'M2_5_NEG_005_WRITE_OFF_RESTRUCTURE_BOUNDARY',
            FALSE,
            'Expected rejection did not occur.'
        );
    EXCEPTION
        WHEN OTHERS THEN
            PERFORM pg_temp.m2_5_add_negative
            (
                'M2_5_NEG_005_WRITE_OFF_RESTRUCTURE_BOUNDARY',
                TRUE,
                SQLERRM
            );
    END;
END;
$m2_5_neg_005_write_off_restructure_boundary$;
DO $m2_5_neg_006_monitoring_only_boundary$
BEGIN
    BEGIN
        UPDATE msbf_ctl.m2_5_policy_profile
        SET monitoring_only_no_servicing_action_flag = FALSE
        WHERE module1_run_id =
              (SELECT run_id FROM _m2_5_nctx);

        PERFORM msbf_ctl.m2_5_assert_configuration
        (
            (SELECT run_id FROM _m2_5_nctx)
        );
        PERFORM pg_temp.m2_5_add_negative
        (
            'M2_5_NEG_006_MONITORING_ONLY_BOUNDARY',
            FALSE,
            'Expected rejection did not occur.'
        );
    EXCEPTION
        WHEN OTHERS THEN
            PERFORM pg_temp.m2_5_add_negative
            (
                'M2_5_NEG_006_MONITORING_ONLY_BOUNDARY',
                TRUE,
                SQLERRM
            );
    END;
END;
$m2_5_neg_006_monitoring_only_boundary$;
DO $m2_5_neg_007_reason_adverse_notice_flag$
BEGIN
    BEGIN
        INSERT INTO _m2_5_neg_reason
        (
            production_adverse_action_notice_flag,
            servicing_action_authorized_flag
        )
        VALUES
        (
            TRUE,
            FALSE
        );
        PERFORM pg_temp.m2_5_add_negative
        (
            'M2_5_NEG_007_REASON_ADVERSE_NOTICE_FLAG',
            FALSE,
            'Expected rejection did not occur.'
        );
    EXCEPTION
        WHEN check_violation THEN
            PERFORM pg_temp.m2_5_add_negative
            (
                'M2_5_NEG_007_REASON_ADVERSE_NOTICE_FLAG',
                TRUE,
                SQLERRM
            );
    END;
END;
$m2_5_neg_007_reason_adverse_notice_flag$;
DO $m2_5_neg_008_reason_servicing_action_flag$
BEGIN
    BEGIN
        INSERT INTO _m2_5_neg_reason
        (
            production_adverse_action_notice_flag,
            servicing_action_authorized_flag
        )
        VALUES
        (
            FALSE,
            TRUE
        );
        PERFORM pg_temp.m2_5_add_negative
        (
            'M2_5_NEG_008_REASON_SERVICING_ACTION_FLAG',
            FALSE,
            'Expected rejection did not occur.'
        );
    EXCEPTION
        WHEN check_violation THEN
            PERFORM pg_temp.m2_5_add_negative
            (
                'M2_5_NEG_008_REASON_SERVICING_ACTION_FLAG',
                TRUE,
                SQLERRM
            );
    END;
END;
$m2_5_neg_008_reason_servicing_action_flag$;
DO $m2_5_neg_009_duplicate_daily_grain$
BEGIN
    BEGIN
        INSERT INTO _m2_5_neg_grain
        (
            scenario_id,
            merchant_application_id,
            monitoring_day_index
        )
        VALUES
        (
            1,
            'SYNTHETIC_APPLICATION',
            1
        );

        INSERT INTO _m2_5_neg_grain
        (
            scenario_id,
            merchant_application_id,
            monitoring_day_index
        )
        VALUES
        (
            1,
            'SYNTHETIC_APPLICATION',
            1
        );
        PERFORM pg_temp.m2_5_add_negative
        (
            'M2_5_NEG_009_DUPLICATE_DAILY_GRAIN',
            FALSE,
            'Expected rejection did not occur.'
        );
    EXCEPTION
        WHEN unique_violation THEN
            PERFORM pg_temp.m2_5_add_negative
            (
                'M2_5_NEG_009_DUPLICATE_DAILY_GRAIN',
                TRUE,
                SQLERRM
            );
    END;
END;
$m2_5_neg_009_duplicate_daily_grain$;
DO $m2_5_neg_010_negative_remittance$
BEGIN
    BEGIN
        INSERT INTO _m2_5_neg_daily
        (
            raw_remittance_amount,
            actual_remittance_amount,
            receivable_balance_before,
            receivable_balance_after,
            principal_exposure_proxy,
            unearned_finance_charge_proxy,
            monitoring_status_rank
        )
        VALUES
        (
            100.00,
            -1.00,
            1000.00,
            1001.00,
            900.00,
            101.00,
            1
        );
        PERFORM pg_temp.m2_5_add_negative
        (
            'M2_5_NEG_010_NEGATIVE_REMITTANCE',
            FALSE,
            'Expected rejection did not occur.'
        );
    EXCEPTION
        WHEN check_violation THEN
            PERFORM pg_temp.m2_5_add_negative
            (
                'M2_5_NEG_010_NEGATIVE_REMITTANCE',
                TRUE,
                SQLERRM
            );
    END;
END;
$m2_5_neg_010_negative_remittance$;
DO $m2_5_neg_011_remittance_exceeds_raw$
BEGIN
    BEGIN
        INSERT INTO _m2_5_neg_daily
        (
            raw_remittance_amount,
            actual_remittance_amount,
            receivable_balance_before,
            receivable_balance_after,
            principal_exposure_proxy,
            unearned_finance_charge_proxy,
            monitoring_status_rank
        )
        VALUES
        (
            100.00,
            101.00,
            1000.00,
            899.00,
            800.00,
            99.00,
            1
        );
        PERFORM pg_temp.m2_5_add_negative
        (
            'M2_5_NEG_011_REMITTANCE_EXCEEDS_RAW',
            FALSE,
            'Expected rejection did not occur.'
        );
    EXCEPTION
        WHEN check_violation THEN
            PERFORM pg_temp.m2_5_add_negative
            (
                'M2_5_NEG_011_REMITTANCE_EXCEEDS_RAW',
                TRUE,
                SQLERRM
            );
    END;
END;
$m2_5_neg_011_remittance_exceeds_raw$;
DO $m2_5_neg_012_balance_reconciliation$
BEGIN
    BEGIN
        INSERT INTO _m2_5_neg_daily
        (
            raw_remittance_amount,
            actual_remittance_amount,
            receivable_balance_before,
            receivable_balance_after,
            principal_exposure_proxy,
            unearned_finance_charge_proxy,
            monitoring_status_rank
        )
        VALUES
        (
            100.00,
            100.00,
            1000.00,
            850.00,
            750.00,
            100.00,
            1
        );
        PERFORM pg_temp.m2_5_add_negative
        (
            'M2_5_NEG_012_BALANCE_RECONCILIATION',
            FALSE,
            'Expected rejection did not occur.'
        );
    EXCEPTION
        WHEN check_violation THEN
            PERFORM pg_temp.m2_5_add_negative
            (
                'M2_5_NEG_012_BALANCE_RECONCILIATION',
                TRUE,
                SQLERRM
            );
    END;
END;
$m2_5_neg_012_balance_reconciliation$;
DO $m2_5_neg_013_invalid_status_rank$
BEGIN
    BEGIN
        INSERT INTO _m2_5_neg_daily
        (
            raw_remittance_amount,
            actual_remittance_amount,
            receivable_balance_before,
            receivable_balance_after,
            principal_exposure_proxy,
            unearned_finance_charge_proxy,
            monitoring_status_rank
        )
        VALUES
        (
            100.00,
            100.00,
            1000.00,
            900.00,
            800.00,
            100.00,
            9
        );
        PERFORM pg_temp.m2_5_add_negative
        (
            'M2_5_NEG_013_INVALID_STATUS_RANK',
            FALSE,
            'Expected rejection did not occur.'
        );
    EXCEPTION
        WHEN check_violation THEN
            PERFORM pg_temp.m2_5_add_negative
            (
                'M2_5_NEG_013_INVALID_STATUS_RANK',
                TRUE,
                SQLERRM
            );
    END;
END;
$m2_5_neg_013_invalid_status_rank$;
DO $m2_5_neg_014_archive_update$
BEGIN
    BEGIN
        UPDATE msbf_m2.advance_portfolio_monitoring_archive
        SET primary_monitoring_reason_code =
            'M2_5_MUTATION_TEST'
        WHERE archive_id =
              (
                  SELECT archive_id
                  FROM msbf_m2.advance_portfolio_monitoring_archive
                  WHERE module1_run_id =
                        (SELECT run_id FROM _m2_5_nctx)
                  ORDER BY archive_id
                  LIMIT 1
              );
        PERFORM pg_temp.m2_5_add_negative
        (
            'M2_5_NEG_014_ARCHIVE_UPDATE',
            FALSE,
            'Expected rejection did not occur.'
        );
    EXCEPTION
        WHEN OTHERS THEN
            PERFORM pg_temp.m2_5_add_negative
            (
                'M2_5_NEG_014_ARCHIVE_UPDATE',
                TRUE,
                SQLERRM
            );
    END;
END;
$m2_5_neg_014_archive_update$;
DO $m2_5_neg_015_archive_delete$
BEGIN
    BEGIN
        DELETE FROM msbf_m2.advance_portfolio_monitoring_archive
        WHERE archive_id =
              (
                  SELECT archive_id
                  FROM msbf_m2.advance_portfolio_monitoring_archive
                  WHERE module1_run_id =
                        (SELECT run_id FROM _m2_5_nctx)
                  ORDER BY archive_id
                  LIMIT 1
              );
        PERFORM pg_temp.m2_5_add_negative
        (
            'M2_5_NEG_015_ARCHIVE_DELETE',
            FALSE,
            'Expected rejection did not occur.'
        );
    EXCEPTION
        WHEN OTHERS THEN
            PERFORM pg_temp.m2_5_add_negative
            (
                'M2_5_NEG_015_ARCHIVE_DELETE',
                TRUE,
                SQLERRM
            );
    END;
END;
$m2_5_neg_015_archive_delete$;
DO $m2_5_neg_016_post_generation_rerun$
BEGIN
    BEGIN
        PERFORM msbf_ctl.m2_5_assert_generation_ready
        (
            (SELECT run_id FROM _m2_5_nctx)
        );
        PERFORM pg_temp.m2_5_add_negative
        (
            'M2_5_NEG_016_POST_GENERATION_RERUN',
            FALSE,
            'Expected rejection did not occur.'
        );
    EXCEPTION
        WHEN OTHERS THEN
            PERFORM pg_temp.m2_5_add_negative
            (
                'M2_5_NEG_016_POST_GENERATION_RERUN',
                TRUE,
                SQLERRM
            );
    END;
END;
$m2_5_neg_016_post_generation_rerun$;
DO $m2_5_neg_017_premature_acceptance$
BEGIN
    BEGIN
        PERFORM msbf_ctl.m2_5_assert_acceptance_ready
        (
            (SELECT run_id FROM _m2_5_nctx)
        );
        PERFORM pg_temp.m2_5_add_negative
        (
            'M2_5_NEG_017_PREMATURE_ACCEPTANCE',
            FALSE,
            'Expected rejection did not occur.'
        );
    EXCEPTION
        WHEN OTHERS THEN
            PERFORM pg_temp.m2_5_add_negative
            (
                'M2_5_NEG_017_PREMATURE_ACCEPTANCE',
                TRUE,
                SQLERRM
            );
    END;
END;
$m2_5_neg_017_premature_acceptance$;
DO $m2_5_neg_018_source_m2_4_hash_drift$
BEGIN
    BEGIN
        UPDATE msbf_ctl.m2_5_policy_profile
        SET source_m2_4_combined_hash =
            '00000000000000000000000000000000'
        WHERE module1_run_id =
              (SELECT run_id FROM _m2_5_nctx);

        PERFORM msbf_ctl.m2_5_assert_configuration
        (
            (SELECT run_id FROM _m2_5_nctx)
        );
        PERFORM pg_temp.m2_5_add_negative
        (
            'M2_5_NEG_018_SOURCE_M2_4_HASH_DRIFT',
            FALSE,
            'Expected rejection did not occur.'
        );
    EXCEPTION
        WHEN OTHERS THEN
            PERFORM pg_temp.m2_5_add_negative
            (
                'M2_5_NEG_018_SOURCE_M2_4_HASH_DRIFT',
                TRUE,
                SQLERRM
            );
    END;
END;
$m2_5_neg_018_source_m2_4_hash_drift$;
DO $m2_5_neg_019_real_debit_payload$
BEGIN
    BEGIN
        PERFORM msbf_ctl.m2_5_assert_no_servicing_action_payload
        (
            '{"debit_instruction":{"amount":100.00}}'::jsonb
        );
        PERFORM pg_temp.m2_5_add_negative
        (
            'M2_5_NEG_019_REAL_DEBIT_PAYLOAD',
            FALSE,
            'Expected rejection did not occur.'
        );
    EXCEPTION
        WHEN OTHERS THEN
            PERFORM pg_temp.m2_5_add_negative
            (
                'M2_5_NEG_019_REAL_DEBIT_PAYLOAD',
                TRUE,
                SQLERRM
            );
    END;
END;
$m2_5_neg_019_real_debit_payload$;
DO $m2_5_neg_020_servicing_notice_payload_vocabulary$
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

    PERFORM pg_temp.m2_5_add_negative
    (
        'M2_5_NEG_020_SERVICING_NOTICE_PAYLOAD_VOCABULARY',
        v_collection_rejected
        AND v_writeoff_rejected
        AND v_restructure_rejected
        AND v_notice_rejected
        AND v_adverse_rejected,
        concat
        (
            'collection ', v_collection_rejected,
            ', write-off ', v_writeoff_rejected,
            ', restructure ', v_restructure_rejected,
            ', notice ', v_notice_rejected,
            ', adverse-action ', v_adverse_rejected
        )
    );
END;
$m2_5_neg_020_servicing_notice_payload_vocabulary$;

DO $m2_5_negative_finalize$
DECLARE
    v_total bigint;
    v_pass bigint;
    v_fail bigint;
BEGIN
    SELECT
        count(*),
        count(*) FILTER(WHERE status = 'PASS'),
        count(*) FILTER(WHERE status = 'FAIL')
    INTO
        v_total,
        v_pass,
        v_fail
    FROM _m2_5_negative;

    IF v_total <> 20 THEN
        RAISE EXCEPTION
            'M2.5 negative-control inventory failed: total %, expected %.',
            v_total,
            20;
    END IF;

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
        (SELECT run_id FROM _m2_5_nctx),
        negative.evidence_code,
        'PORTFOLIO',
        negative.metric_name,
        NULL::numeric(24,10),
        negative.status,
        'NEGATIVE_CONTROL',
        negative.status,
        negative.interpretation
    FROM _m2_5_negative AS negative
    ON CONFLICT(run_id, evidence_code, segment_key)
    DO UPDATE SET
        metric_name = EXCLUDED.metric_name,
        metric_value_numeric = NULL,
        metric_value_text = EXCLUDED.metric_value_text,
        unit_code = EXCLUDED.unit_code,
        status = EXCLUDED.status,
        interpretation = EXCLUDED.interpretation,
        created_at = clock_timestamp();

    IF v_pass <> 20
       OR v_fail <> 0 THEN
        RAISE EXCEPTION
            'M2.5 negative controls failed: pass %, fail %.',
            v_pass,
            v_fail;
    END IF;
END;
$m2_5_negative_finalize$;

COMMIT;

SELECT
    negative.evidence_code,
    negative.metric_name,
    negative.status,
    negative.interpretation
FROM _m2_5_negative AS negative
ORDER BY negative.evidence_code;
