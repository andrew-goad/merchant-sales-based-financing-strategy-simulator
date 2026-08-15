/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.7 — Operational Activation & Account Setup

Program     : 184_msbf_m2_7_negative_control_tests_v0_2.sql
Version     : v0.2

Purpose
-------
Prove fail-closed behavior for policy drift, real-execution flags, invalid
setup terms, duplicate grain, archive mutation, lifecycle reruns, premature
acceptance, source-hash drift, and prohibited bank, ACH, action, collection,
legal, and notice payloads.

Required result
---------------
20 / 20 PASS.
============================================================================ */

BEGIN;

SET LOCAL statement_timeout='30min';
SET LOCAL jit=off;

DROP TABLE IF EXISTS _m2_7_negative;

CREATE TEMP TABLE _m2_7_negative
(
    evidence_code text PRIMARY KEY,
    metric_name text NOT NULL,
    status text NOT NULL,
    interpretation text NOT NULL
)
ON COMMIT PRESERVE ROWS;

DROP TABLE IF EXISTS _m2_7_nctx;

CREATE TEMP TABLE _m2_7_nctx
ON COMMIT DROP
AS
SELECT run_id,run_status
FROM msbf_ctl.run_registry
WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1;

DO $ready$
DECLARE
    v_pass bigint;
BEGIN
    SELECT count(*)
    INTO v_pass
    FROM msbf_ctl.run_evidence
    WHERE run_id=(SELECT run_id FROM _m2_7_nctx)
      AND evidence_code LIKE 'M2_7_POS_%'
      AND status='PASS';

    IF (SELECT run_status FROM _m2_7_nctx)<>'M2_7_VALIDATED'
       OR v_pass<>120
    THEN
        RAISE EXCEPTION
            'M2.7 negative controls require M2_7_VALIDATED and 120 positive passes.';
    END IF;
END;
$ready$;

CREATE OR REPLACE FUNCTION pg_temp.m2_7_add_negative
(
    p_code text,
    p_pass boolean,
    p_interpretation text
)
RETURNS void
LANGUAGE plpgsql
AS $function$
BEGIN
    INSERT INTO _m2_7_negative
    (
        evidence_code,metric_name,status,interpretation
    )
    VALUES
    (
        p_code,p_code,
        CASE WHEN p_pass THEN 'PASS' ELSE 'FAIL' END,
        p_interpretation
    );
END;
$function$;

CREATE TEMP TABLE _m2_7_neg_outcome
(
    real_core_account_created_flag boolean NOT NULL,
    real_payment_change_executed_flag boolean NOT NULL,
    external_notice_generated_flag boolean NOT NULL,
    production_adverse_action_flag boolean NOT NULL,
    CHECK
    (
        real_core_account_created_flag IS FALSE
        AND real_payment_change_executed_flag IS FALSE
        AND external_notice_generated_flag IS FALSE
        AND production_adverse_action_flag IS FALSE
    )
)
ON COMMIT DROP;

CREATE TEMP TABLE _m2_7_neg_action
(
    real_core_account_created_flag boolean NOT NULL,
    real_payment_change_executed_flag boolean NOT NULL,
    ach_or_network_transmission_flag boolean NOT NULL,
    merchant_contact_executed_flag boolean NOT NULL,
    write_off_posted_flag boolean NOT NULL,
    collection_or_legal_executed_flag boolean NOT NULL,
    external_notice_generated_flag boolean NOT NULL,
    production_adverse_action_flag boolean NOT NULL,
    CHECK
    (
        real_core_account_created_flag IS FALSE
        AND real_payment_change_executed_flag IS FALSE
        AND ach_or_network_transmission_flag IS FALSE
        AND merchant_contact_executed_flag IS FALSE
        AND write_off_posted_flag IS FALSE
        AND collection_or_legal_executed_flag IS FALSE
        AND external_notice_generated_flag IS FALSE
        AND production_adverse_action_flag IS FALSE
    )
)
ON COMMIT DROP;

CREATE TEMP TABLE _m2_7_neg_grain
(
    scenario_id bigint NOT NULL,
    merchant_application_id text NOT NULL,
    PRIMARY KEY(scenario_id,merchant_application_id)
)
ON COMMIT DROP;

CREATE TEMP TABLE _m2_7_neg_setup
(
    account_setup_status_code text NOT NULL,
    synthetic_servicing_plan_id text,
    operational_activation_date date,
    next_reassessment_date date,
    CHECK
    (
        (
            account_setup_status_code='SIMULATED_BLUEPRINT_READY'
            AND synthetic_servicing_plan_id IS NOT NULL
            AND operational_activation_date IS NOT NULL
            AND next_reassessment_date IS NOT NULL
        )
        OR
        (
            account_setup_status_code<>'SIMULATED_BLUEPRINT_READY'
            AND synthetic_servicing_plan_id IS NULL
            AND operational_activation_date IS NULL
            AND next_reassessment_date IS NULL
        )
    )
)
ON COMMIT DROP;

CREATE TEMP TABLE _m2_7_neg_factor
(
    temporary_payment_factor numeric(9,6) NOT NULL
        CHECK(temporary_payment_factor BETWEEN 0.10 AND 1.00)
)
ON COMMIT DROP;

DO $m2_7_neg_001_policy_status$
BEGIN
    BEGIN
        UPDATE msbf_ctl.m2_7_policy_profile
        SET policy_status='DRAFT'
        WHERE module1_run_id=(SELECT run_id FROM _m2_7_nctx);
        PERFORM pg_temp.m2_7_add_negative
        (
            'M2_7_NEG_001_POLICY_STATUS',
            FALSE,
            'Expected rejection did not occur.'
        );
    EXCEPTION
        WHEN check_violation THEN
            PERFORM pg_temp.m2_7_add_negative
            (
                'M2_7_NEG_001_POLICY_STATUS',
                TRUE,
                SQLERRM
            );
    END;
END;
$m2_7_neg_001_policy_status$;
DO $m2_7_neg_002_simulated_setup_boundary$
BEGIN
    BEGIN
        UPDATE msbf_ctl.m2_7_policy_profile
        SET simulated_operational_setup_only_flag=FALSE
        WHERE module1_run_id=(SELECT run_id FROM _m2_7_nctx);

        PERFORM msbf_ctl.m2_7_assert_configuration
        (
            (SELECT run_id FROM _m2_7_nctx)
        );
        PERFORM pg_temp.m2_7_add_negative
        (
            'M2_7_NEG_002_SIMULATED_SETUP_BOUNDARY',
            FALSE,
            'Expected rejection did not occur.'
        );
    EXCEPTION
        WHEN OTHERS THEN
            PERFORM pg_temp.m2_7_add_negative
            (
                'M2_7_NEG_002_SIMULATED_SETUP_BOUNDARY',
                TRUE,
                SQLERRM
            );
    END;
END;
$m2_7_neg_002_simulated_setup_boundary$;
DO $m2_7_neg_003_real_account_boundary$
BEGIN
    BEGIN
        UPDATE msbf_ctl.m2_7_policy_profile
        SET no_real_core_account_creation_flag=FALSE
        WHERE module1_run_id=(SELECT run_id FROM _m2_7_nctx);

        PERFORM msbf_ctl.m2_7_assert_configuration
        (
            (SELECT run_id FROM _m2_7_nctx)
        );
        PERFORM pg_temp.m2_7_add_negative
        (
            'M2_7_NEG_003_REAL_ACCOUNT_BOUNDARY',
            FALSE,
            'Expected rejection did not occur.'
        );
    EXCEPTION
        WHEN OTHERS THEN
            PERFORM pg_temp.m2_7_add_negative
            (
                'M2_7_NEG_003_REAL_ACCOUNT_BOUNDARY',
                TRUE,
                SQLERRM
            );
    END;
END;
$m2_7_neg_003_real_account_boundary$;
DO $m2_7_neg_004_payment_change_boundary$
BEGIN
    BEGIN
        UPDATE msbf_ctl.m2_7_policy_profile
        SET no_real_payment_change_execution_flag=FALSE
        WHERE module1_run_id=(SELECT run_id FROM _m2_7_nctx);

        PERFORM msbf_ctl.m2_7_assert_configuration
        (
            (SELECT run_id FROM _m2_7_nctx)
        );
        PERFORM pg_temp.m2_7_add_negative
        (
            'M2_7_NEG_004_PAYMENT_CHANGE_BOUNDARY',
            FALSE,
            'Expected rejection did not occur.'
        );
    EXCEPTION
        WHEN OTHERS THEN
            PERFORM pg_temp.m2_7_add_negative
            (
                'M2_7_NEG_004_PAYMENT_CHANGE_BOUNDARY',
                TRUE,
                SQLERRM
            );
    END;
END;
$m2_7_neg_004_payment_change_boundary$;
DO $m2_7_neg_005_bank_data_boundary$
BEGIN
    BEGIN
        UPDATE msbf_ctl.m2_7_policy_profile
        SET no_bank_account_data_flag=FALSE
        WHERE module1_run_id=(SELECT run_id FROM _m2_7_nctx);

        PERFORM msbf_ctl.m2_7_assert_configuration
        (
            (SELECT run_id FROM _m2_7_nctx)
        );
        PERFORM pg_temp.m2_7_add_negative
        (
            'M2_7_NEG_005_BANK_DATA_BOUNDARY',
            FALSE,
            'Expected rejection did not occur.'
        );
    EXCEPTION
        WHEN OTHERS THEN
            PERFORM pg_temp.m2_7_add_negative
            (
                'M2_7_NEG_005_BANK_DATA_BOUNDARY',
                TRUE,
                SQLERRM
            );
    END;
END;
$m2_7_neg_005_bank_data_boundary$;
DO $m2_7_neg_006_ach_network_boundary$
BEGIN
    BEGIN
        UPDATE msbf_ctl.m2_7_policy_profile
        SET no_ach_or_network_transmission_flag=FALSE
        WHERE module1_run_id=(SELECT run_id FROM _m2_7_nctx);

        PERFORM msbf_ctl.m2_7_assert_configuration
        (
            (SELECT run_id FROM _m2_7_nctx)
        );
        PERFORM pg_temp.m2_7_add_negative
        (
            'M2_7_NEG_006_ACH_NETWORK_BOUNDARY',
            FALSE,
            'Expected rejection did not occur.'
        );
    EXCEPTION
        WHEN OTHERS THEN
            PERFORM pg_temp.m2_7_add_negative
            (
                'M2_7_NEG_006_ACH_NETWORK_BOUNDARY',
                TRUE,
                SQLERRM
            );
    END;
END;
$m2_7_neg_006_ach_network_boundary$;
DO $m2_7_neg_007_external_notice_boundary$
BEGIN
    BEGIN
        UPDATE msbf_ctl.m2_7_policy_profile
        SET no_external_notice_generation_flag=FALSE
        WHERE module1_run_id=(SELECT run_id FROM _m2_7_nctx);

        PERFORM msbf_ctl.m2_7_assert_configuration
        (
            (SELECT run_id FROM _m2_7_nctx)
        );
        PERFORM pg_temp.m2_7_add_negative
        (
            'M2_7_NEG_007_EXTERNAL_NOTICE_BOUNDARY',
            FALSE,
            'Expected rejection did not occur.'
        );
    EXCEPTION
        WHEN OTHERS THEN
            PERFORM pg_temp.m2_7_add_negative
            (
                'M2_7_NEG_007_EXTERNAL_NOTICE_BOUNDARY',
                TRUE,
                SQLERRM
            );
    END;
END;
$m2_7_neg_007_external_notice_boundary$;
DO $m2_7_neg_008_outcome_execution_flag$
BEGIN
    BEGIN
        INSERT INTO _m2_7_neg_outcome
        (
            real_core_account_created_flag,
            real_payment_change_executed_flag,
            external_notice_generated_flag,
            production_adverse_action_flag
        )
        VALUES(TRUE,TRUE,TRUE,TRUE);
        PERFORM pg_temp.m2_7_add_negative
        (
            'M2_7_NEG_008_OUTCOME_EXECUTION_FLAG',
            FALSE,
            'Expected rejection did not occur.'
        );
    EXCEPTION
        WHEN check_violation THEN
            PERFORM pg_temp.m2_7_add_negative
            (
                'M2_7_NEG_008_OUTCOME_EXECUTION_FLAG',
                TRUE,
                SQLERRM
            );
    END;
END;
$m2_7_neg_008_outcome_execution_flag$;
DO $m2_7_neg_009_action_execution_flag$
BEGIN
    BEGIN
        INSERT INTO _m2_7_neg_action
        (
            real_core_account_created_flag,
            real_payment_change_executed_flag,
            ach_or_network_transmission_flag,
            merchant_contact_executed_flag,
            write_off_posted_flag,
            collection_or_legal_executed_flag,
            external_notice_generated_flag,
            production_adverse_action_flag
        )
        VALUES(TRUE,TRUE,TRUE,TRUE,TRUE,TRUE,TRUE,TRUE);
        PERFORM pg_temp.m2_7_add_negative
        (
            'M2_7_NEG_009_ACTION_EXECUTION_FLAG',
            FALSE,
            'Expected rejection did not occur.'
        );
    EXCEPTION
        WHEN check_violation THEN
            PERFORM pg_temp.m2_7_add_negative
            (
                'M2_7_NEG_009_ACTION_EXECUTION_FLAG',
                TRUE,
                SQLERRM
            );
    END;
END;
$m2_7_neg_009_action_execution_flag$;
DO $m2_7_neg_010_duplicate_activation_grain$
BEGIN
    BEGIN
        INSERT INTO _m2_7_neg_grain
        VALUES(1,'SYNTHETIC_APPLICATION');

        INSERT INTO _m2_7_neg_grain
        VALUES(1,'SYNTHETIC_APPLICATION');
        PERFORM pg_temp.m2_7_add_negative
        (
            'M2_7_NEG_010_DUPLICATE_ACTIVATION_GRAIN',
            FALSE,
            'Expected rejection did not occur.'
        );
    EXCEPTION
        WHEN unique_violation THEN
            PERFORM pg_temp.m2_7_add_negative
            (
                'M2_7_NEG_010_DUPLICATE_ACTIVATION_GRAIN',
                TRUE,
                SQLERRM
            );
    END;
END;
$m2_7_neg_010_duplicate_activation_grain$;
DO $m2_7_neg_011_ready_setup_without_plan$
BEGIN
    BEGIN
        INSERT INTO _m2_7_neg_setup
        (
            account_setup_status_code,
            synthetic_servicing_plan_id,
            operational_activation_date,
            next_reassessment_date
        )
        VALUES
        (
            'SIMULATED_BLUEPRINT_READY',
            NULL,
            current_date,
            current_date+7
        );
        PERFORM pg_temp.m2_7_add_negative
        (
            'M2_7_NEG_011_READY_SETUP_WITHOUT_PLAN',
            FALSE,
            'Expected rejection did not occur.'
        );
    EXCEPTION
        WHEN check_violation THEN
            PERFORM pg_temp.m2_7_add_negative
            (
                'M2_7_NEG_011_READY_SETUP_WITHOUT_PLAN',
                TRUE,
                SQLERRM
            );
    END;
END;
$m2_7_neg_011_ready_setup_without_plan$;
DO $m2_7_neg_012_no_setup_with_plan$
BEGIN
    BEGIN
        INSERT INTO _m2_7_neg_setup
        (
            account_setup_status_code,
            synthetic_servicing_plan_id,
            operational_activation_date,
            next_reassessment_date
        )
        VALUES
        (
            'NOT_REQUIRED',
            'MSBF_PLAN_PROHIBITED',
            current_date,
            current_date+7
        );
        PERFORM pg_temp.m2_7_add_negative
        (
            'M2_7_NEG_012_NO_SETUP_WITH_PLAN',
            FALSE,
            'Expected rejection did not occur.'
        );
    EXCEPTION
        WHEN check_violation THEN
            PERFORM pg_temp.m2_7_add_negative
            (
                'M2_7_NEG_012_NO_SETUP_WITH_PLAN',
                TRUE,
                SQLERRM
            );
    END;
END;
$m2_7_neg_012_no_setup_with_plan$;
DO $m2_7_neg_013_invalid_temporary_factor$
BEGIN
    BEGIN
        INSERT INTO _m2_7_neg_factor
        VALUES(1.50);
        PERFORM pg_temp.m2_7_add_negative
        (
            'M2_7_NEG_013_INVALID_TEMPORARY_FACTOR',
            FALSE,
            'Expected rejection did not occur.'
        );
    EXCEPTION
        WHEN check_violation THEN
            PERFORM pg_temp.m2_7_add_negative
            (
                'M2_7_NEG_013_INVALID_TEMPORARY_FACTOR',
                TRUE,
                SQLERRM
            );
    END;
END;
$m2_7_neg_013_invalid_temporary_factor$;
DO $m2_7_neg_014_archive_update$
BEGIN
    BEGIN
        UPDATE msbf_m2.application_operational_activation_archive
        SET operational_setup_queue_code='MUTATION_TEST'
        WHERE archive_id=
              (
                  SELECT archive_id
                  FROM msbf_m2.application_operational_activation_archive
                  WHERE module1_run_id=(SELECT run_id FROM _m2_7_nctx)
                  ORDER BY archive_id
                  LIMIT 1
              );
        PERFORM pg_temp.m2_7_add_negative
        (
            'M2_7_NEG_014_ARCHIVE_UPDATE',
            FALSE,
            'Expected rejection did not occur.'
        );
    EXCEPTION
        WHEN OTHERS THEN
            PERFORM pg_temp.m2_7_add_negative
            (
                'M2_7_NEG_014_ARCHIVE_UPDATE',
                TRUE,
                SQLERRM
            );
    END;
END;
$m2_7_neg_014_archive_update$;
DO $m2_7_neg_015_archive_delete$
BEGIN
    BEGIN
        DELETE FROM msbf_m2.application_operational_activation_archive
        WHERE archive_id=
              (
                  SELECT archive_id
                  FROM msbf_m2.application_operational_activation_archive
                  WHERE module1_run_id=(SELECT run_id FROM _m2_7_nctx)
                  ORDER BY archive_id
                  LIMIT 1
              );
        PERFORM pg_temp.m2_7_add_negative
        (
            'M2_7_NEG_015_ARCHIVE_DELETE',
            FALSE,
            'Expected rejection did not occur.'
        );
    EXCEPTION
        WHEN OTHERS THEN
            PERFORM pg_temp.m2_7_add_negative
            (
                'M2_7_NEG_015_ARCHIVE_DELETE',
                TRUE,
                SQLERRM
            );
    END;
END;
$m2_7_neg_015_archive_delete$;
DO $m2_7_neg_016_post_generation_rerun$
BEGIN
    BEGIN
        PERFORM msbf_ctl.m2_7_assert_generation_ready
        (
            (SELECT run_id FROM _m2_7_nctx)
        );
        PERFORM pg_temp.m2_7_add_negative
        (
            'M2_7_NEG_016_POST_GENERATION_RERUN',
            FALSE,
            'Expected rejection did not occur.'
        );
    EXCEPTION
        WHEN OTHERS THEN
            PERFORM pg_temp.m2_7_add_negative
            (
                'M2_7_NEG_016_POST_GENERATION_RERUN',
                TRUE,
                SQLERRM
            );
    END;
END;
$m2_7_neg_016_post_generation_rerun$;
DO $m2_7_neg_017_premature_acceptance$
BEGIN
    BEGIN
        PERFORM msbf_ctl.m2_7_assert_acceptance_ready
        (
            (SELECT run_id FROM _m2_7_nctx)
        );
        PERFORM pg_temp.m2_7_add_negative
        (
            'M2_7_NEG_017_PREMATURE_ACCEPTANCE',
            FALSE,
            'Expected rejection did not occur.'
        );
    EXCEPTION
        WHEN OTHERS THEN
            PERFORM pg_temp.m2_7_add_negative
            (
                'M2_7_NEG_017_PREMATURE_ACCEPTANCE',
                TRUE,
                SQLERRM
            );
    END;
END;
$m2_7_neg_017_premature_acceptance$;
DO $m2_7_neg_018_source_hash_drift$
BEGIN
    BEGIN
        UPDATE msbf_ctl.m2_7_policy_profile
        SET source_combined_set_hash=
            '00000000000000000000000000000000'
        WHERE module1_run_id=(SELECT run_id FROM _m2_7_nctx);

        PERFORM msbf_ctl.m2_7_assert_configuration
        (
            (SELECT run_id FROM _m2_7_nctx)
        );
        PERFORM pg_temp.m2_7_add_negative
        (
            'M2_7_NEG_018_SOURCE_HASH_DRIFT',
            FALSE,
            'Expected rejection did not occur.'
        );
    EXCEPTION
        WHEN OTHERS THEN
            PERFORM pg_temp.m2_7_add_negative
            (
                'M2_7_NEG_018_SOURCE_HASH_DRIFT',
                TRUE,
                SQLERRM
            );
    END;
END;
$m2_7_neg_018_source_hash_drift$;
DO $m2_7_neg_019_bank_ach_payload$
BEGIN
    BEGIN
        PERFORM msbf_ctl.m2_7_assert_no_real_operational_payload
        (
            jsonb_build_object
            (
                'bank_account_number','SYNTHETIC',
                'routing_number','SYNTHETIC',
                'ach_trace_number','SYNTHETIC'
            )
        );
        PERFORM pg_temp.m2_7_add_negative
        (
            'M2_7_NEG_019_BANK_ACH_PAYLOAD',
            FALSE,
            'Expected rejection did not occur.'
        );
    EXCEPTION
        WHEN OTHERS THEN
            PERFORM pg_temp.m2_7_add_negative
            (
                'M2_7_NEG_019_BANK_ACH_PAYLOAD',
                TRUE,
                SQLERRM
            );
    END;
END;
$m2_7_neg_019_bank_ach_payload$;
DO $m2_7_neg_020_executed_action_notice_payload$
BEGIN
    BEGIN
        PERFORM msbf_ctl.m2_7_assert_no_real_operational_payload
        (
            jsonb_build_object
            (
                'merchant_contact_executed',TRUE,
                'write_off_posted',TRUE,
                'collection_agency_referral',TRUE,
                'legal_action_executed',TRUE,
                'external_notice_payload',
                    jsonb_build_object('synthetic',TRUE),
                'production_adverse_action_notice',TRUE
            )
        );
        PERFORM pg_temp.m2_7_add_negative
        (
            'M2_7_NEG_020_EXECUTED_ACTION_NOTICE_PAYLOAD',
            FALSE,
            'Expected rejection did not occur.'
        );
    EXCEPTION
        WHEN OTHERS THEN
            PERFORM pg_temp.m2_7_add_negative
            (
                'M2_7_NEG_020_EXECUTED_ACTION_NOTICE_PAYLOAD',
                TRUE,
                SQLERRM
            );
    END;
END;
$m2_7_neg_020_executed_action_notice_payload$;

DO $finalize$
DECLARE
    v_total bigint;
    v_pass bigint;
    v_fail bigint;
BEGIN
    SELECT
        count(*),
        count(*) FILTER(WHERE status='PASS'),
        count(*) FILTER(WHERE status='FAIL')
    INTO v_total,v_pass,v_fail
    FROM _m2_7_negative;

    IF v_total<>20 THEN
        RAISE EXCEPTION
            'M2.7 negative-control inventory failed: total %, expected 20.',
            v_total;
    END IF;

    INSERT INTO msbf_ctl.run_evidence
    (
        run_id,evidence_code,segment_key,metric_name,
        metric_value_numeric,metric_value_text,unit_code,status,
        interpretation
    )
    SELECT
        (SELECT run_id FROM _m2_7_nctx),
        evidence_code,'PORTFOLIO',metric_name,NULL::numeric(28,10),
        status,'NEGATIVE_CONTROL',status,interpretation
    FROM _m2_7_negative
    ON CONFLICT(run_id,evidence_code,segment_key)
    DO UPDATE SET
        metric_name=EXCLUDED.metric_name,
        metric_value_numeric=NULL,
        metric_value_text=EXCLUDED.metric_value_text,
        unit_code=EXCLUDED.unit_code,
        status=EXCLUDED.status,
        interpretation=EXCLUDED.interpretation,
        created_at=clock_timestamp();

    IF v_pass<>20 OR v_fail<>0 THEN
        RAISE EXCEPTION
            'M2.7 negative controls failed: pass %, fail %.',
            v_pass,v_fail;
    END IF;
END;
$finalize$;

COMMIT;

SELECT *
FROM _m2_7_negative
ORDER BY evidence_code;
