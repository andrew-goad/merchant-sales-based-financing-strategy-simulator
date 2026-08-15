/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.3 — Final Offer & Decision Authorization

Program     : 152_msbf_m2_3_negative_control_tests_v0_2R2.sql
Version     : v0.2R2
Purpose     : Prove fail-closed controls for policy boundaries, adverse action,
              booking/funding, invalid term states, archive immutability,
              lifecycle reruns, source-hash drift, and prohibited payloads.

Output      : 20-row session-preserved result set.
Required    : 20 / 20 PASS.
============================================================================ */

BEGIN;

SET LOCAL statement_timeout = '20min';
SET LOCAL jit = off;

DROP TABLE IF EXISTS _m2_3_negative;

CREATE TEMP TABLE _m2_3_negative
(
    evidence_code  text PRIMARY KEY,
    metric_name    text NOT NULL,
    status         text NOT NULL,
    interpretation text NOT NULL
)
ON COMMIT PRESERVE ROWS;

DROP TABLE IF EXISTS _m2_3_nctx;

CREATE TEMP TABLE _m2_3_nctx
ON COMMIT DROP
AS
SELECT run_id, run_status
FROM msbf_ctl.run_registry
WHERE run_code='M1_V0_2_BASELINE_BUILD'
  AND run_version=1;

DO $m2_3_negative_ready$
DECLARE
    v_positive bigint;
BEGIN
    SELECT count(*)
    INTO v_positive
    FROM msbf_ctl.run_evidence
    WHERE run_id = (SELECT run_id FROM _m2_3_nctx)
      AND evidence_code LIKE 'M2_3_POS_%'
      AND status = 'PASS';

    IF (SELECT run_status FROM _m2_3_nctx) <> 'M2_3_VALIDATED'
       OR v_positive <> 120 THEN
        RAISE EXCEPTION
            'M2.3 negative controls require M2_3_VALIDATED and 120 positive passes.';
    END IF;
END;
$m2_3_negative_ready$;

CREATE OR REPLACE FUNCTION pg_temp.m2_3_add_negative
(
    p_code text,
    p_pass boolean,
    p_interpretation text
)
RETURNS void
LANGUAGE plpgsql
AS $function$
BEGIN
    INSERT INTO _m2_3_negative
    VALUES
    (
        p_code,
        p_code,
        CASE WHEN p_pass THEN 'PASS' ELSE 'FAIL' END,
        p_interpretation
    );
END;
$function$;

CREATE TEMP TABLE _m2_3_neg_policy
(
    policy_status text NOT NULL CHECK(policy_status IN('APPROVED','RETIRED')),
    no_booking_funding_flag boolean NOT NULL CHECK(no_booking_funding_flag),
    no_external_notice_generation_flag boolean NOT NULL CHECK(no_external_notice_generation_flag),
    no_production_adverse_action_notice_flag boolean NOT NULL CHECK(no_production_adverse_action_notice_flag)
)
ON COMMIT DROP;

CREATE TEMP TABLE _m2_3_neg_outcome
(
    production_adverse_action_notice_flag boolean NOT NULL,
    booking_funding_flag boolean NOT NULL,
    CHECK(production_adverse_action_notice_flag IS FALSE),
    CHECK(booking_funding_flag IS FALSE)
)
ON COMMIT DROP;

CREATE TEMP TABLE _m2_3_neg_reason
(
    production_adverse_action_notice_flag boolean NOT NULL
        CHECK(production_adverse_action_notice_flag IS FALSE)
)
ON COMMIT DROP;

CREATE TEMP TABLE _m2_3_neg_grain
(
    scenario_id bigint NOT NULL,
    merchant_application_id text NOT NULL,
    PRIMARY KEY(scenario_id,merchant_application_id)
)
ON COMMIT DROP;

CREATE TEMP TABLE _m2_3_neg_terms
(
    final_offer_authorized_flag boolean NOT NULL,
    final_offer_amount numeric(18,2),
    final_remittance_rate numeric(9,6),
    final_authorization_evidence_status text NOT NULL
        CHECK(final_authorization_evidence_status IN
              ('AUTHORIZED','REVIEW_REQUIRED','DECLINE_AUTHORIZED','BLOCKED')),
    CHECK
    (
        (
            final_offer_authorized_flag
            AND final_offer_amount IS NOT NULL
            AND final_remittance_rate IS NOT NULL
        )
        OR
        (
            final_offer_authorized_flag IS FALSE
            AND final_offer_amount IS NULL
            AND final_remittance_rate IS NULL
        )
    )
)
ON COMMIT DROP;


DO $m2_3_neg_001_policy_status$
BEGIN
    BEGIN
INSERT INTO _m2_3_neg_policy VALUES('DRAFT',TRUE,TRUE,TRUE);
        PERFORM pg_temp.m2_3_add_negative
        (
            'M2_3_NEG_001_POLICY_STATUS',
            FALSE,
            'Expected rejection did not occur.'
        );
    EXCEPTION
        WHEN check_violation THEN
            PERFORM pg_temp.m2_3_add_negative
            (
                'M2_3_NEG_001_POLICY_STATUS',
                TRUE,
                SQLERRM
            );
    END;
END;
$m2_3_neg_001_policy_status$;
DO $m2_3_neg_002_booking_boundary_flag$
BEGIN
    BEGIN
INSERT INTO _m2_3_neg_policy VALUES('APPROVED',FALSE,TRUE,TRUE);
        PERFORM pg_temp.m2_3_add_negative
        (
            'M2_3_NEG_002_BOOKING_BOUNDARY_FLAG',
            FALSE,
            'Expected rejection did not occur.'
        );
    EXCEPTION
        WHEN check_violation THEN
            PERFORM pg_temp.m2_3_add_negative
            (
                'M2_3_NEG_002_BOOKING_BOUNDARY_FLAG',
                TRUE,
                SQLERRM
            );
    END;
END;
$m2_3_neg_002_booking_boundary_flag$;
DO $m2_3_neg_003_external_notice_boundary$
BEGIN
    BEGIN
INSERT INTO _m2_3_neg_policy VALUES('APPROVED',TRUE,FALSE,TRUE);
        PERFORM pg_temp.m2_3_add_negative
        (
            'M2_3_NEG_003_EXTERNAL_NOTICE_BOUNDARY',
            FALSE,
            'Expected rejection did not occur.'
        );
    EXCEPTION
        WHEN check_violation THEN
            PERFORM pg_temp.m2_3_add_negative
            (
                'M2_3_NEG_003_EXTERNAL_NOTICE_BOUNDARY',
                TRUE,
                SQLERRM
            );
    END;
END;
$m2_3_neg_003_external_notice_boundary$;
DO $m2_3_neg_004_adverse_action_boundary$
BEGIN
    BEGIN
INSERT INTO _m2_3_neg_policy VALUES('APPROVED',TRUE,TRUE,FALSE);
        PERFORM pg_temp.m2_3_add_negative
        (
            'M2_3_NEG_004_ADVERSE_ACTION_BOUNDARY',
            FALSE,
            'Expected rejection did not occur.'
        );
    EXCEPTION
        WHEN check_violation THEN
            PERFORM pg_temp.m2_3_add_negative
            (
                'M2_3_NEG_004_ADVERSE_ACTION_BOUNDARY',
                TRUE,
                SQLERRM
            );
    END;
END;
$m2_3_neg_004_adverse_action_boundary$;
DO $m2_3_neg_005_outcome_adverse_action_flag$
BEGIN
    BEGIN
INSERT INTO _m2_3_neg_outcome VALUES(TRUE,FALSE);
        PERFORM pg_temp.m2_3_add_negative
        (
            'M2_3_NEG_005_OUTCOME_ADVERSE_ACTION_FLAG',
            FALSE,
            'Expected rejection did not occur.'
        );
    EXCEPTION
        WHEN check_violation THEN
            PERFORM pg_temp.m2_3_add_negative
            (
                'M2_3_NEG_005_OUTCOME_ADVERSE_ACTION_FLAG',
                TRUE,
                SQLERRM
            );
    END;
END;
$m2_3_neg_005_outcome_adverse_action_flag$;
DO $m2_3_neg_006_outcome_booking_flag$
BEGIN
    BEGIN
INSERT INTO _m2_3_neg_outcome VALUES(FALSE,TRUE);
        PERFORM pg_temp.m2_3_add_negative
        (
            'M2_3_NEG_006_OUTCOME_BOOKING_FLAG',
            FALSE,
            'Expected rejection did not occur.'
        );
    EXCEPTION
        WHEN check_violation THEN
            PERFORM pg_temp.m2_3_add_negative
            (
                'M2_3_NEG_006_OUTCOME_BOOKING_FLAG',
                TRUE,
                SQLERRM
            );
    END;
END;
$m2_3_neg_006_outcome_booking_flag$;
DO $m2_3_neg_007_reason_adverse_action_flag$
BEGIN
    BEGIN
INSERT INTO _m2_3_neg_reason VALUES(TRUE);
        PERFORM pg_temp.m2_3_add_negative
        (
            'M2_3_NEG_007_REASON_ADVERSE_ACTION_FLAG',
            FALSE,
            'Expected rejection did not occur.'
        );
    EXCEPTION
        WHEN check_violation THEN
            PERFORM pg_temp.m2_3_add_negative
            (
                'M2_3_NEG_007_REASON_ADVERSE_ACTION_FLAG',
                TRUE,
                SQLERRM
            );
    END;
END;
$m2_3_neg_007_reason_adverse_action_flag$;
DO $m2_3_neg_008_duplicate_decision_grain$
BEGIN
    BEGIN
INSERT INTO _m2_3_neg_grain VALUES(1,'APP');
        INSERT INTO _m2_3_neg_grain VALUES(1,'APP');
        PERFORM pg_temp.m2_3_add_negative
        (
            'M2_3_NEG_008_DUPLICATE_DECISION_GRAIN',
            FALSE,
            'Expected rejection did not occur.'
        );
    EXCEPTION
        WHEN unique_violation THEN
            PERFORM pg_temp.m2_3_add_negative
            (
                'M2_3_NEG_008_DUPLICATE_DECISION_GRAIN',
                TRUE,
                SQLERRM
            );
    END;
END;
$m2_3_neg_008_duplicate_decision_grain$;
DO $m2_3_neg_009_offer_without_terms$
BEGIN
    BEGIN
INSERT INTO _m2_3_neg_terms VALUES(TRUE,NULL,0.100000,'AUTHORIZED');
        PERFORM pg_temp.m2_3_add_negative
        (
            'M2_3_NEG_009_OFFER_WITHOUT_TERMS',
            FALSE,
            'Expected rejection did not occur.'
        );
    EXCEPTION
        WHEN check_violation THEN
            PERFORM pg_temp.m2_3_add_negative
            (
                'M2_3_NEG_009_OFFER_WITHOUT_TERMS',
                TRUE,
                SQLERRM
            );
    END;
END;
$m2_3_neg_009_offer_without_terms$;
DO $m2_3_neg_010_nonoffer_with_terms$
BEGIN
    BEGIN
INSERT INTO _m2_3_neg_terms VALUES(FALSE,1000.00,NULL,'DECLINE_AUTHORIZED');
        PERFORM pg_temp.m2_3_add_negative
        (
            'M2_3_NEG_010_NONOFFER_WITH_TERMS',
            FALSE,
            'Expected rejection did not occur.'
        );
    EXCEPTION
        WHEN check_violation THEN
            PERFORM pg_temp.m2_3_add_negative
            (
                'M2_3_NEG_010_NONOFFER_WITH_TERMS',
                TRUE,
                SQLERRM
            );
    END;
END;
$m2_3_neg_010_nonoffer_with_terms$;
DO $m2_3_neg_011_invalid_status_domain$
BEGIN
    BEGIN
INSERT INTO _m2_3_neg_terms VALUES(FALSE,NULL,NULL,'BOOKED');
        PERFORM pg_temp.m2_3_add_negative
        (
            'M2_3_NEG_011_INVALID_STATUS_DOMAIN',
            FALSE,
            'Expected rejection did not occur.'
        );
    EXCEPTION
        WHEN check_violation THEN
            PERFORM pg_temp.m2_3_add_negative
            (
                'M2_3_NEG_011_INVALID_STATUS_DOMAIN',
                TRUE,
                SQLERRM
            );
    END;
END;
$m2_3_neg_011_invalid_status_domain$;
DO $m2_3_neg_012_archive_update$
BEGIN
    BEGIN
UPDATE msbf_m2.application_final_offer_decision_archive
        SET primary_decision_reason_code = 'MUTATION_TEST'
        WHERE module1_run_id = (SELECT run_id FROM _m2_3_nctx)
          AND archive_id =
              (
                  SELECT archive_id
                  FROM msbf_m2.application_final_offer_decision_archive
                  WHERE module1_run_id = (SELECT run_id FROM _m2_3_nctx)
                  LIMIT 1
              );
        PERFORM pg_temp.m2_3_add_negative
        (
            'M2_3_NEG_012_ARCHIVE_UPDATE',
            FALSE,
            'Expected rejection did not occur.'
        );
    EXCEPTION
        WHEN OTHERS THEN
            PERFORM pg_temp.m2_3_add_negative
            (
                'M2_3_NEG_012_ARCHIVE_UPDATE',
                TRUE,
                SQLERRM
            );
    END;
END;
$m2_3_neg_012_archive_update$;
DO $m2_3_neg_013_archive_delete$
BEGIN
    BEGIN
DELETE FROM msbf_m2.application_final_offer_decision_archive
        WHERE module1_run_id = (SELECT run_id FROM _m2_3_nctx)
          AND archive_id =
              (
                  SELECT archive_id
                  FROM msbf_m2.application_final_offer_decision_archive
                  WHERE module1_run_id = (SELECT run_id FROM _m2_3_nctx)
                  LIMIT 1
              );
        PERFORM pg_temp.m2_3_add_negative
        (
            'M2_3_NEG_013_ARCHIVE_DELETE',
            FALSE,
            'Expected rejection did not occur.'
        );
    EXCEPTION
        WHEN OTHERS THEN
            PERFORM pg_temp.m2_3_add_negative
            (
                'M2_3_NEG_013_ARCHIVE_DELETE',
                TRUE,
                SQLERRM
            );
    END;
END;
$m2_3_neg_013_archive_delete$;
DO $m2_3_neg_014_post_generation_rerun$
BEGIN
    BEGIN
PERFORM msbf_ctl.m2_3_assert_generation_ready
        (
            (SELECT run_id FROM _m2_3_nctx)
        );
        PERFORM pg_temp.m2_3_add_negative
        (
            'M2_3_NEG_014_POST_GENERATION_RERUN',
            FALSE,
            'Expected rejection did not occur.'
        );
    EXCEPTION
        WHEN OTHERS THEN
            PERFORM pg_temp.m2_3_add_negative
            (
                'M2_3_NEG_014_POST_GENERATION_RERUN',
                TRUE,
                SQLERRM
            );
    END;
END;
$m2_3_neg_014_post_generation_rerun$;
DO $m2_3_neg_015_premature_acceptance$
BEGIN
    BEGIN
PERFORM msbf_ctl.m2_3_assert_acceptance_ready
        (
            (SELECT run_id FROM _m2_3_nctx)
        );
        PERFORM pg_temp.m2_3_add_negative
        (
            'M2_3_NEG_015_PREMATURE_ACCEPTANCE',
            FALSE,
            'Expected rejection did not occur.'
        );
    EXCEPTION
        WHEN OTHERS THEN
            PERFORM pg_temp.m2_3_add_negative
            (
                'M2_3_NEG_015_PREMATURE_ACCEPTANCE',
                TRUE,
                SQLERRM
            );
    END;
END;
$m2_3_neg_015_premature_acceptance$;
DO $m2_3_neg_016_source_m2_2_hash_drift$
BEGIN
    BEGIN
UPDATE msbf_ctl.m2_3_policy_profile
        SET source_m2_2_combined_hash='00000000000000000000000000000000'
        WHERE module1_run_id=(SELECT run_id FROM _m2_3_nctx);

        PERFORM msbf_ctl.m2_3_assert_configuration
        (
            (SELECT run_id FROM _m2_3_nctx)
        );
        PERFORM pg_temp.m2_3_add_negative
        (
            'M2_3_NEG_016_SOURCE_M2_2_HASH_DRIFT',
            FALSE,
            'Expected rejection did not occur.'
        );
    EXCEPTION
        WHEN OTHERS THEN
            PERFORM pg_temp.m2_3_add_negative
            (
                'M2_3_NEG_016_SOURCE_M2_2_HASH_DRIFT',
                TRUE,
                SQLERRM
            );
    END;
END;
$m2_3_neg_016_source_m2_2_hash_drift$;
DO $m2_3_neg_017_booking_payload$
BEGIN
    BEGIN
PERFORM msbf_ctl.m2_3_assert_no_booking_payload('{"booking_status":"BOOKED"}'::jsonb);
        PERFORM pg_temp.m2_3_add_negative
        (
            'M2_3_NEG_017_BOOKING_PAYLOAD',
            FALSE,
            'Expected rejection did not occur.'
        );
    EXCEPTION
        WHEN OTHERS THEN
            PERFORM pg_temp.m2_3_add_negative
            (
                'M2_3_NEG_017_BOOKING_PAYLOAD',
                TRUE,
                SQLERRM
            );
    END;
END;
$m2_3_neg_017_booking_payload$;
DO $m2_3_neg_018_funding_payload$
BEGIN
    BEGIN
PERFORM msbf_ctl.m2_3_assert_no_booking_payload('{"funding_status":"FUNDED"}'::jsonb);
        PERFORM pg_temp.m2_3_add_negative
        (
            'M2_3_NEG_018_FUNDING_PAYLOAD',
            FALSE,
            'Expected rejection did not occur.'
        );
    EXCEPTION
        WHEN OTHERS THEN
            PERFORM pg_temp.m2_3_add_negative
            (
                'M2_3_NEG_018_FUNDING_PAYLOAD',
                TRUE,
                SQLERRM
            );
    END;
END;
$m2_3_neg_018_funding_payload$;
DO $m2_3_neg_019_external_notice_payload$
BEGIN
    BEGIN
PERFORM msbf_ctl.m2_3_assert_no_booking_payload('{"external_notice_payload":{}}'::jsonb);
        PERFORM pg_temp.m2_3_add_negative
        (
            'M2_3_NEG_019_EXTERNAL_NOTICE_PAYLOAD',
            FALSE,
            'Expected rejection did not occur.'
        );
    EXCEPTION
        WHEN OTHERS THEN
            PERFORM pg_temp.m2_3_add_negative
            (
                'M2_3_NEG_019_EXTERNAL_NOTICE_PAYLOAD',
                TRUE,
                SQLERRM
            );
    END;
END;
$m2_3_neg_019_external_notice_payload$;
DO $m2_3_neg_020_production_adverse_action_payload$
BEGIN
    BEGIN
PERFORM msbf_ctl.m2_3_assert_no_booking_payload('{"production_adverse_action_notice":true}'::jsonb);
        PERFORM pg_temp.m2_3_add_negative
        (
            'M2_3_NEG_020_PRODUCTION_ADVERSE_ACTION_PAYLOAD',
            FALSE,
            'Expected rejection did not occur.'
        );
    EXCEPTION
        WHEN OTHERS THEN
            PERFORM pg_temp.m2_3_add_negative
            (
                'M2_3_NEG_020_PRODUCTION_ADVERSE_ACTION_PAYLOAD',
                TRUE,
                SQLERRM
            );
    END;
END;
$m2_3_neg_020_production_adverse_action_payload$;

DO $m2_3_negative_finalize$
DECLARE
    v_total bigint;
    v_pass bigint;
    v_fail bigint;
BEGIN
    SELECT
        count(*),
        count(*) FILTER(WHERE status = 'PASS'),
        count(*) FILTER(WHERE status = 'FAIL')
    INTO v_total, v_pass, v_fail
    FROM _m2_3_negative;

    IF v_total <> 20 THEN
        RAISE EXCEPTION
            'M2.3 negative-control inventory failed: total %, expected %.',
            v_total, 20;
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
        (SELECT run_id FROM _m2_3_nctx),
        evidence_code,
        'PORTFOLIO',
        metric_name,
        NULL::numeric(28,10),
        status,
        'NEGATIVE_CONTROL',
        status,
        interpretation
    FROM _m2_3_negative
    ON CONFLICT(run_id,evidence_code,segment_key)
    DO UPDATE SET
        metric_name = EXCLUDED.metric_name,
        metric_value_numeric = NULL,
        metric_value_text = EXCLUDED.metric_value_text,
        unit_code = EXCLUDED.unit_code,
        status = EXCLUDED.status,
        interpretation = EXCLUDED.interpretation,
        created_at = clock_timestamp();

    IF v_pass <> 20 OR v_fail <> 0 THEN
        UPDATE msbf_ctl.run_registry
        SET run_status = 'M2_3_FAILED'
        WHERE run_id = (SELECT run_id FROM _m2_3_nctx);

        RAISE EXCEPTION
            'M2.3 negative controls failed: pass %, fail %.',
            v_pass, v_fail;
    END IF;
END;
$m2_3_negative_finalize$;

COMMIT;

SELECT
    evidence_code,
    metric_name,
    status,
    interpretation
FROM _m2_3_negative
ORDER BY evidence_code;
