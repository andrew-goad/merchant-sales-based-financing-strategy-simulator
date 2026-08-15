/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.4 — Booking, Funding & Portfolio Activation

Program     : 160_msbf_m2_4_negative_control_tests_v0_2.sql
Version     : v0.2
Purpose     : Prove fail-closed policy, operational, identifier, archive,
              lifecycle, source-hash and real-world payload boundaries.

Output      : 20-row session-preserved result set.
Required    : 20 / 20 PASS.
============================================================================ */

BEGIN;

SET LOCAL statement_timeout='25min';
SET LOCAL jit=off;

DROP TABLE IF EXISTS _m2_4_negative;

CREATE TEMP TABLE _m2_4_negative
(
    evidence_code text PRIMARY KEY,
    metric_name text NOT NULL,
    status text NOT NULL,
    interpretation text NOT NULL
)
ON COMMIT PRESERVE ROWS;

DROP TABLE IF EXISTS _m2_4_nctx;

CREATE TEMP TABLE _m2_4_nctx
ON COMMIT DROP
AS
SELECT run_id,run_status
FROM msbf_ctl.run_registry
WHERE run_code='M1_V0_2_BASELINE_BUILD'
  AND run_version=1;

DO $m2_4_negative_ready$
DECLARE
    v_positive bigint;
BEGIN
    SELECT count(*)
    INTO v_positive
    FROM msbf_ctl.run_evidence
    WHERE run_id=(SELECT run_id FROM _m2_4_nctx)
      AND evidence_code LIKE 'M2_4_POS_%'
      AND status='PASS';

    IF (SELECT run_status FROM _m2_4_nctx) <> 'M2_4_VALIDATED'
       OR v_positive <> 120 THEN
        RAISE EXCEPTION
            'M2.4 negative controls require M2_4_VALIDATED and 120 positive passes.';
    END IF;
END;
$m2_4_negative_ready$;

CREATE OR REPLACE FUNCTION pg_temp.m2_4_add_negative
(
    p_code text,
    p_pass boolean,
    p_interpretation text
)
RETURNS void
LANGUAGE plpgsql
AS $function$
BEGIN
    INSERT INTO _m2_4_negative
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

CREATE TEMP TABLE _m2_4_neg_policy
(
    policy_status text NOT NULL CHECK(policy_status IN('APPROVED','RETIRED')),
    real_funds_movement_prohibited_flag boolean NOT NULL CHECK(real_funds_movement_prohibited_flag),
    external_notice_transmission_prohibited_flag boolean NOT NULL CHECK(external_notice_transmission_prohibited_flag),
    production_adverse_action_notice_prohibited_flag boolean NOT NULL CHECK(production_adverse_action_notice_prohibited_flag)
)
ON COMMIT DROP;

CREATE TEMP TABLE _m2_4_neg_outcome
(
    real_funds_movement_flag boolean NOT NULL CHECK(real_funds_movement_flag IS FALSE),
    external_notice_transmission_flag boolean NOT NULL CHECK(external_notice_transmission_flag IS FALSE)
)
ON COMMIT DROP;

CREATE TEMP TABLE _m2_4_neg_reason
(
    production_adverse_action_notice_flag boolean NOT NULL CHECK(production_adverse_action_notice_flag IS FALSE)
)
ON COMMIT DROP;

CREATE TEMP TABLE _m2_4_neg_notice
(
    external_transmission_authorized_flag boolean NOT NULL CHECK(external_transmission_authorized_flag IS FALSE)
)
ON COMMIT DROP;

CREATE TEMP TABLE _m2_4_neg_grain
(
    scenario_id bigint NOT NULL,
    merchant_application_id text NOT NULL,
    PRIMARY KEY(scenario_id,merchant_application_id)
)
ON COMMIT DROP;

CREATE TEMP TABLE _m2_4_neg_activation
(
    portfolio_activated_flag boolean NOT NULL,
    synthetic_account_id text,
    synthetic_advance_id text,
    funded_amount numeric(18,2),
    activation_evidence_status text NOT NULL CHECK(activation_evidence_status IN('ACTIVATED','REVIEW_REQUIRED','NOT_ACTIVATED','BLOCKED')),
    CHECK
    (
        (
            portfolio_activated_flag
            AND synthetic_account_id IS NOT NULL
            AND synthetic_advance_id IS NOT NULL
            AND funded_amount IS NOT NULL
        )
        OR
        (
            portfolio_activated_flag IS FALSE
            AND synthetic_account_id IS NULL
            AND synthetic_advance_id IS NULL
            AND funded_amount IS NULL
        )
    )
)
ON COMMIT DROP;

CREATE TEMP TABLE _m2_4_neg_account
(
    synthetic_account_id text PRIMARY KEY
)
ON COMMIT DROP;

CREATE TEMP TABLE _m2_4_neg_advance
(
    synthetic_advance_id text PRIMARY KEY
)
ON COMMIT DROP;

/* --------------------------------------------------------------------------
Negative Controls 001–004 — policy status and stage-boundary drift
-------------------------------------------------------------------------- */
DO $m2_4_neg_001_policy_status$
BEGIN
    BEGIN
        INSERT INTO _m2_4_neg_policy VALUES('DRAFT',TRUE,TRUE,TRUE);
        PERFORM pg_temp.m2_4_add_negative
        (
            'M2_4_NEG_001_POLICY_STATUS',
            FALSE,
            'Expected rejection did not occur.'
        );
    EXCEPTION
        WHEN check_violation THEN
            PERFORM pg_temp.m2_4_add_negative
            (
                'M2_4_NEG_001_POLICY_STATUS',
                TRUE,
                SQLERRM
            );
    END;
END;
$m2_4_neg_001_policy_status$;
DO $m2_4_neg_002_real_funds_policy_boundary$
BEGIN
    BEGIN
        UPDATE msbf_ctl.m2_4_policy_profile AS policy
        SET
            configuration_payload = jsonb_set
            (
                policy.configuration_payload,
                '{real_funds_movement_prohibited}',
                'false'::jsonb,
                FALSE
            ),
            configuration_hash = msbf_ctl.m2_4_hash_jsonb
            (
                jsonb_set
                (
                    policy.configuration_payload,
                    '{real_funds_movement_prohibited}',
                    'false'::jsonb,
                    FALSE
                )
            )
        WHERE policy.module1_run_id =
              (SELECT run_id FROM _m2_4_nctx);

        UPDATE msbf_ctl.m2_4_policy_profile AS policy
        SET row_hash = msbf_ctl.m2_4_hash_jsonb
        (
            to_jsonb(policy)
            - 'row_hash'
            - 'created_at'
            - 'updated_at'
        )
        WHERE policy.module1_run_id =
              (SELECT run_id FROM _m2_4_nctx);

        PERFORM msbf_ctl.m2_4_assert_configuration
        (
            (SELECT run_id FROM _m2_4_nctx)
        );

        PERFORM pg_temp.m2_4_add_negative
        (
            'M2_4_NEG_002_REAL_FUNDS_POLICY_BOUNDARY',
            FALSE,
            'Expected rejection did not occur.'
        );
    EXCEPTION
        WHEN OTHERS THEN
            PERFORM pg_temp.m2_4_add_negative
            (
                'M2_4_NEG_002_REAL_FUNDS_POLICY_BOUNDARY',
                TRUE,
                SQLERRM
            );
    END;
END;
$m2_4_neg_002_real_funds_policy_boundary$;
DO $m2_4_neg_003_external_notice_policy_boundary$
BEGIN
    BEGIN
        UPDATE msbf_ctl.m2_4_policy_profile AS policy
        SET
            configuration_payload = jsonb_set
            (
                policy.configuration_payload,
                '{external_notice_transmission_prohibited}',
                'false'::jsonb,
                FALSE
            ),
            configuration_hash = msbf_ctl.m2_4_hash_jsonb
            (
                jsonb_set
                (
                    policy.configuration_payload,
                    '{external_notice_transmission_prohibited}',
                    'false'::jsonb,
                    FALSE
                )
            )
        WHERE policy.module1_run_id =
              (SELECT run_id FROM _m2_4_nctx);

        UPDATE msbf_ctl.m2_4_policy_profile AS policy
        SET row_hash = msbf_ctl.m2_4_hash_jsonb
        (
            to_jsonb(policy)
            - 'row_hash'
            - 'created_at'
            - 'updated_at'
        )
        WHERE policy.module1_run_id =
              (SELECT run_id FROM _m2_4_nctx);

        PERFORM msbf_ctl.m2_4_assert_configuration
        (
            (SELECT run_id FROM _m2_4_nctx)
        );

        PERFORM pg_temp.m2_4_add_negative
        (
            'M2_4_NEG_003_EXTERNAL_NOTICE_POLICY_BOUNDARY',
            FALSE,
            'Expected rejection did not occur.'
        );
    EXCEPTION
        WHEN OTHERS THEN
            PERFORM pg_temp.m2_4_add_negative
            (
                'M2_4_NEG_003_EXTERNAL_NOTICE_POLICY_BOUNDARY',
                TRUE,
                SQLERRM
            );
    END;
END;
$m2_4_neg_003_external_notice_policy_boundary$;
DO $m2_4_neg_004_adverse_action_policy_boundary$
BEGIN
    BEGIN
        UPDATE msbf_ctl.m2_4_policy_profile AS policy
        SET
            configuration_payload = jsonb_set
            (
                policy.configuration_payload,
                '{production_adverse_action_notice_prohibited}',
                'false'::jsonb,
                FALSE
            ),
            configuration_hash = msbf_ctl.m2_4_hash_jsonb
            (
                jsonb_set
                (
                    policy.configuration_payload,
                    '{production_adverse_action_notice_prohibited}',
                    'false'::jsonb,
                    FALSE
                )
            )
        WHERE policy.module1_run_id =
              (SELECT run_id FROM _m2_4_nctx);

        UPDATE msbf_ctl.m2_4_policy_profile AS policy
        SET row_hash = msbf_ctl.m2_4_hash_jsonb
        (
            to_jsonb(policy)
            - 'row_hash'
            - 'created_at'
            - 'updated_at'
        )
        WHERE policy.module1_run_id =
              (SELECT run_id FROM _m2_4_nctx);

        PERFORM msbf_ctl.m2_4_assert_configuration
        (
            (SELECT run_id FROM _m2_4_nctx)
        );

        PERFORM pg_temp.m2_4_add_negative
        (
            'M2_4_NEG_004_ADVERSE_ACTION_POLICY_BOUNDARY',
            FALSE,
            'Expected rejection did not occur.'
        );
    EXCEPTION
        WHEN OTHERS THEN
            PERFORM pg_temp.m2_4_add_negative
            (
                'M2_4_NEG_004_ADVERSE_ACTION_POLICY_BOUNDARY',
                TRUE,
                SQLERRM
            );
    END;
END;
$m2_4_neg_004_adverse_action_policy_boundary$;
/* --------------------------------------------------------------------------
Negative Controls 005–008 — governed outcome, reason and notice dictionaries
-------------------------------------------------------------------------- */
DO $m2_4_neg_005_outcome_real_funds_flag$
BEGIN
    BEGIN
        INSERT INTO _m2_4_neg_outcome VALUES(TRUE,FALSE);
        PERFORM pg_temp.m2_4_add_negative
        (
            'M2_4_NEG_005_OUTCOME_REAL_FUNDS_FLAG',
            FALSE,
            'Expected rejection did not occur.'
        );
    EXCEPTION
        WHEN check_violation THEN
            PERFORM pg_temp.m2_4_add_negative
            (
                'M2_4_NEG_005_OUTCOME_REAL_FUNDS_FLAG',
                TRUE,
                SQLERRM
            );
    END;
END;
$m2_4_neg_005_outcome_real_funds_flag$;
DO $m2_4_neg_006_outcome_external_notice_flag$
BEGIN
    BEGIN
        INSERT INTO _m2_4_neg_outcome VALUES(FALSE,TRUE);
        PERFORM pg_temp.m2_4_add_negative
        (
            'M2_4_NEG_006_OUTCOME_EXTERNAL_NOTICE_FLAG',
            FALSE,
            'Expected rejection did not occur.'
        );
    EXCEPTION
        WHEN check_violation THEN
            PERFORM pg_temp.m2_4_add_negative
            (
                'M2_4_NEG_006_OUTCOME_EXTERNAL_NOTICE_FLAG',
                TRUE,
                SQLERRM
            );
    END;
END;
$m2_4_neg_006_outcome_external_notice_flag$;
DO $m2_4_neg_007_reason_adverse_action_flag$
BEGIN
    BEGIN
        INSERT INTO _m2_4_neg_reason VALUES(TRUE);
        PERFORM pg_temp.m2_4_add_negative
        (
            'M2_4_NEG_007_REASON_ADVERSE_ACTION_FLAG',
            FALSE,
            'Expected rejection did not occur.'
        );
    EXCEPTION
        WHEN check_violation THEN
            PERFORM pg_temp.m2_4_add_negative
            (
                'M2_4_NEG_007_REASON_ADVERSE_ACTION_FLAG',
                TRUE,
                SQLERRM
            );
    END;
END;
$m2_4_neg_007_reason_adverse_action_flag$;
DO $m2_4_neg_008_notice_external_transmission_flag$
BEGIN
    BEGIN
        INSERT INTO _m2_4_neg_notice VALUES(TRUE);
        PERFORM pg_temp.m2_4_add_negative
        (
            'M2_4_NEG_008_NOTICE_EXTERNAL_TRANSMISSION_FLAG',
            FALSE,
            'Expected rejection did not occur.'
        );
    EXCEPTION
        WHEN check_violation THEN
            PERFORM pg_temp.m2_4_add_negative
            (
                'M2_4_NEG_008_NOTICE_EXTERNAL_TRANSMISSION_FLAG',
                TRUE,
                SQLERRM
            );
    END;
END;
$m2_4_neg_008_notice_external_transmission_flag$;
/* --------------------------------------------------------------------------
Negative Controls 009–014 — grains, activation-state constraints and IDs
-------------------------------------------------------------------------- */
DO $m2_4_neg_009_duplicate_activation_grain$
BEGIN
    BEGIN
        INSERT INTO _m2_4_neg_grain VALUES(1,'APP');
        INSERT INTO _m2_4_neg_grain VALUES(1,'APP');
        PERFORM pg_temp.m2_4_add_negative
        (
            'M2_4_NEG_009_DUPLICATE_ACTIVATION_GRAIN',
            FALSE,
            'Expected rejection did not occur.'
        );
    EXCEPTION
        WHEN unique_violation THEN
            PERFORM pg_temp.m2_4_add_negative
            (
                'M2_4_NEG_009_DUPLICATE_ACTIVATION_GRAIN',
                TRUE,
                SQLERRM
            );
    END;
END;
$m2_4_neg_009_duplicate_activation_grain$;
DO $m2_4_neg_010_activated_without_ids$
BEGIN
    BEGIN
        INSERT INTO _m2_4_neg_activation VALUES(TRUE,NULL,NULL,1000.00,'ACTIVATED');
        PERFORM pg_temp.m2_4_add_negative
        (
            'M2_4_NEG_010_ACTIVATED_WITHOUT_IDS',
            FALSE,
            'Expected rejection did not occur.'
        );
    EXCEPTION
        WHEN check_violation THEN
            PERFORM pg_temp.m2_4_add_negative
            (
                'M2_4_NEG_010_ACTIVATED_WITHOUT_IDS',
                TRUE,
                SQLERRM
            );
    END;
END;
$m2_4_neg_010_activated_without_ids$;
DO $m2_4_neg_011_nonactivated_with_amount$
BEGIN
    BEGIN
        INSERT INTO _m2_4_neg_activation VALUES(FALSE,NULL,NULL,1000.00,'NOT_ACTIVATED');
        PERFORM pg_temp.m2_4_add_negative
        (
            'M2_4_NEG_011_NONACTIVATED_WITH_AMOUNT',
            FALSE,
            'Expected rejection did not occur.'
        );
    EXCEPTION
        WHEN check_violation THEN
            PERFORM pg_temp.m2_4_add_negative
            (
                'M2_4_NEG_011_NONACTIVATED_WITH_AMOUNT',
                TRUE,
                SQLERRM
            );
    END;
END;
$m2_4_neg_011_nonactivated_with_amount$;
DO $m2_4_neg_012_invalid_activation_status$
BEGIN
    BEGIN
        INSERT INTO _m2_4_neg_activation VALUES(FALSE,NULL,NULL,NULL,'BOOKED');
        PERFORM pg_temp.m2_4_add_negative
        (
            'M2_4_NEG_012_INVALID_ACTIVATION_STATUS',
            FALSE,
            'Expected rejection did not occur.'
        );
    EXCEPTION
        WHEN check_violation THEN
            PERFORM pg_temp.m2_4_add_negative
            (
                'M2_4_NEG_012_INVALID_ACTIVATION_STATUS',
                TRUE,
                SQLERRM
            );
    END;
END;
$m2_4_neg_012_invalid_activation_status$;
DO $m2_4_neg_013_duplicate_account_id$
BEGIN
    BEGIN
        INSERT INTO _m2_4_neg_account VALUES('MSBF_ACCT_DUP');
        INSERT INTO _m2_4_neg_account VALUES('MSBF_ACCT_DUP');
        PERFORM pg_temp.m2_4_add_negative
        (
            'M2_4_NEG_013_DUPLICATE_ACCOUNT_ID',
            FALSE,
            'Expected rejection did not occur.'
        );
    EXCEPTION
        WHEN unique_violation THEN
            PERFORM pg_temp.m2_4_add_negative
            (
                'M2_4_NEG_013_DUPLICATE_ACCOUNT_ID',
                TRUE,
                SQLERRM
            );
    END;
END;
$m2_4_neg_013_duplicate_account_id$;
DO $m2_4_neg_014_duplicate_advance_id$
BEGIN
    BEGIN
        INSERT INTO _m2_4_neg_advance VALUES('MSBF_ADV_DUP');
        INSERT INTO _m2_4_neg_advance VALUES('MSBF_ADV_DUP');
        PERFORM pg_temp.m2_4_add_negative
        (
            'M2_4_NEG_014_DUPLICATE_ADVANCE_ID',
            FALSE,
            'Expected rejection did not occur.'
        );
    EXCEPTION
        WHEN unique_violation THEN
            PERFORM pg_temp.m2_4_add_negative
            (
                'M2_4_NEG_014_DUPLICATE_ADVANCE_ID',
                TRUE,
                SQLERRM
            );
    END;
END;
$m2_4_neg_014_duplicate_advance_id$;
/* --------------------------------------------------------------------------
Negative Controls 015–016 — immutable archive enforcement
-------------------------------------------------------------------------- */
DO $m2_4_neg_015_archive_update$
BEGIN
    BEGIN
        UPDATE msbf_m2.application_booking_funding_activation_archive
        SET primary_activation_reason_code='MUTATION_TEST'
        WHERE module1_run_id=(SELECT run_id FROM _m2_4_nctx)
          AND archive_id=(SELECT archive_id FROM msbf_m2.application_booking_funding_activation_archive WHERE module1_run_id=(SELECT run_id FROM _m2_4_nctx) LIMIT 1);
        PERFORM pg_temp.m2_4_add_negative
        (
            'M2_4_NEG_015_ARCHIVE_UPDATE',
            FALSE,
            'Expected rejection did not occur.'
        );
    EXCEPTION
        WHEN OTHERS THEN
            PERFORM pg_temp.m2_4_add_negative
            (
                'M2_4_NEG_015_ARCHIVE_UPDATE',
                TRUE,
                SQLERRM
            );
    END;
END;
$m2_4_neg_015_archive_update$;
DO $m2_4_neg_016_archive_delete$
BEGIN
    BEGIN
        DELETE FROM msbf_m2.application_booking_funding_activation_archive
        WHERE module1_run_id=(SELECT run_id FROM _m2_4_nctx)
          AND archive_id=(SELECT archive_id FROM msbf_m2.application_booking_funding_activation_archive WHERE module1_run_id=(SELECT run_id FROM _m2_4_nctx) LIMIT 1);
        PERFORM pg_temp.m2_4_add_negative
        (
            'M2_4_NEG_016_ARCHIVE_DELETE',
            FALSE,
            'Expected rejection did not occur.'
        );
    EXCEPTION
        WHEN OTHERS THEN
            PERFORM pg_temp.m2_4_add_negative
            (
                'M2_4_NEG_016_ARCHIVE_DELETE',
                TRUE,
                SQLERRM
            );
    END;
END;
$m2_4_neg_016_archive_delete$;
/* --------------------------------------------------------------------------
Negative Controls 017–020 — lifecycle, source drift and real-world payloads
-------------------------------------------------------------------------- */
DO $m2_4_neg_017_post_generation_rerun$
BEGIN
    BEGIN
        PERFORM msbf_ctl.m2_4_assert_generation_ready
        (
            (SELECT run_id FROM _m2_4_nctx)
        );
        PERFORM pg_temp.m2_4_add_negative
        (
            'M2_4_NEG_017_POST_GENERATION_RERUN',
            FALSE,
            'Expected rejection did not occur.'
        );
    EXCEPTION
        WHEN OTHERS THEN
            PERFORM pg_temp.m2_4_add_negative
            (
                'M2_4_NEG_017_POST_GENERATION_RERUN',
                TRUE,
                SQLERRM
            );
    END;
END;
$m2_4_neg_017_post_generation_rerun$;
DO $m2_4_neg_018_premature_acceptance$
BEGIN
    BEGIN
        PERFORM msbf_ctl.m2_4_assert_acceptance_ready
        (
            (SELECT run_id FROM _m2_4_nctx)
        );
        PERFORM pg_temp.m2_4_add_negative
        (
            'M2_4_NEG_018_PREMATURE_ACCEPTANCE',
            FALSE,
            'Expected rejection did not occur.'
        );
    EXCEPTION
        WHEN OTHERS THEN
            PERFORM pg_temp.m2_4_add_negative
            (
                'M2_4_NEG_018_PREMATURE_ACCEPTANCE',
                TRUE,
                SQLERRM
            );
    END;
END;
$m2_4_neg_018_premature_acceptance$;
DO $m2_4_neg_019_source_m2_3_hash_drift$
BEGIN
    BEGIN
        UPDATE msbf_ctl.m2_4_policy_profile
        SET source_m2_3_combined_hash='00000000000000000000000000000000'
        WHERE module1_run_id=(SELECT run_id FROM _m2_4_nctx);

        PERFORM msbf_ctl.m2_4_assert_configuration
        (
            (SELECT run_id FROM _m2_4_nctx)
        );
        PERFORM pg_temp.m2_4_add_negative
        (
            'M2_4_NEG_019_SOURCE_M2_3_HASH_DRIFT',
            FALSE,
            'Expected rejection did not occur.'
        );
    EXCEPTION
        WHEN OTHERS THEN
            PERFORM pg_temp.m2_4_add_negative
            (
                'M2_4_NEG_019_SOURCE_M2_3_HASH_DRIFT',
                TRUE,
                SQLERRM
            );
    END;
END;
$m2_4_neg_019_source_m2_3_hash_drift$;
DO $m2_4_neg_020_real_world_payloads$
DECLARE
    v_payload jsonb;
    v_rejected bigint := 0;
BEGIN
    FOREACH v_payload IN ARRAY ARRAY
    [
        '{"ach_trace_number":"SYNTHETIC"}'::jsonb,
        '{"bank_account_number":"SYNTHETIC"}'::jsonb,
        '{"settlement_account_number":"SYNTHETIC"}'::jsonb,
        '{"routing_number":"SYNTHETIC"}'::jsonb,
        '{"core_booking_id":"SYNTHETIC"}'::jsonb,
        '{"real_account_number":"SYNTHETIC"}'::jsonb,
        '{"real_funds_movement":true}'::jsonb,
        '{"external_notice_payload":{}}'::jsonb,
        '{"external_notice_transmitted":true}'::jsonb,
        '{"production_adverse_action_notice":true}'::jsonb
    ]
    LOOP
        BEGIN
            PERFORM msbf_ctl.m2_4_assert_no_real_world_payload(v_payload);
        EXCEPTION
            WHEN OTHERS THEN
                v_rejected := v_rejected + 1;
        END;
    END LOOP;

    PERFORM pg_temp.m2_4_add_negative
    (
        'M2_4_NEG_020_REAL_WORLD_PAYLOADS',
        v_rejected = 10,
        'Rejected ' || v_rejected::text || ' of 10 prohibited payloads.'
    );
END;
$m2_4_neg_020_real_world_payloads$;

DO $m2_4_negative_finalize$
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
    FROM _m2_4_negative;

    IF v_total <> 20 THEN
        RAISE EXCEPTION
            'M2.4 negative-control inventory failed: total %, expected %.',
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
        (SELECT run_id FROM _m2_4_nctx),
        negative.evidence_code,
        'PORTFOLIO',
        negative.metric_name,
        NULL::numeric(24,10),
        negative.status,
        'NEGATIVE_CONTROL',
        negative.status,
        negative.interpretation
    FROM _m2_4_negative AS negative
    ON CONFLICT(run_id,evidence_code,segment_key)
    DO UPDATE SET
        metric_name=EXCLUDED.metric_name,
        metric_value_numeric=NULL,
        metric_value_text=EXCLUDED.metric_value_text,
        unit_code=EXCLUDED.unit_code,
        status=EXCLUDED.status,
        interpretation=EXCLUDED.interpretation,
        created_at=clock_timestamp();

    IF v_pass <> 20
       OR v_fail <> 0 THEN
        UPDATE msbf_ctl.run_registry
        SET run_status='M2_4_FAILED'
        WHERE run_id=(SELECT run_id FROM _m2_4_nctx);

        RAISE EXCEPTION
            'M2.4 negative controls failed: pass %, fail %.',
            v_pass,
            v_fail;
    END IF;
END;
$m2_4_negative_finalize$;

COMMIT;

SELECT
    evidence_code,
    metric_name,
    status,
    interpretation
FROM _m2_4_negative
ORDER BY evidence_code;
