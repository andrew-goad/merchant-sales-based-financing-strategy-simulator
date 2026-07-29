/* ============================================================================
M1.13 v0.2R1 BOOLEAN-PARAMETER AGGREGATION HOTFIX
Source  : 96_msbf_m1_13_negative_control_tests_v0_2.sql
Role    : Negative controls; executable logic unchanged from v0.2.
Revision: File name is version-aligned to v0.2R1. Except where explicitly
          documented in HOTFIX_NOTES_v0_2R1.md, executable logic is unchanged.
============================================================================ */

/* ============================================================================
MSBF M1.13 Exposure, Recovery & Expected Loss Foundations — Negative Controls
Version : v0.2
Purpose : Prove that material policy, frozen-parameter, scenario-scope,
          prerequisite-state, and rerun defects fail closed without changing
          committed M1.13 business evidence.
Mode    : Seven controlled mutations execute inside PL/pgSQL exception
          subtransactions and roll back automatically.
Output  : One filterable seven-row result set preserved after COMMIT.
============================================================================ */

BEGIN;
SET LOCAL lock_timeout = '10s';
SET LOCAL statement_timeout = '10min';

DROP TABLE IF EXISTS _m1_13_negative;
CREATE TEMP TABLE _m1_13_negative (
    evidence_code text PRIMARY KEY,
    test_name text NOT NULL,
    expected_failure text NOT NULL,
    observed_failure text,
    status text NOT NULL,
    interpretation text NOT NULL
) ON COMMIT PRESERVE ROWS;

CREATE OR REPLACE FUNCTION pg_temp.m1_13_record_negative(
    p_code text,
    p_name text,
    p_expected text,
    p_observed text,
    p_pass boolean,
    p_interpretation text
)
RETURNS void
LANGUAGE plpgsql
AS $fn$
BEGIN
    INSERT INTO _m1_13_negative VALUES (
        p_code,
        p_name,
        p_expected,
        p_observed,
        CASE WHEN coalesce(p_pass,false) THEN 'PASS' ELSE 'FAIL' END,
        p_interpretation
    );
END;
$fn$;

DO $tests$
DECLARE
    v_run_id bigint;
    v_message text;
    v_pass boolean;
BEGIN
    SELECT run_id
    INTO STRICT v_run_id
    FROM msbf_ctl.run_registry
    WHERE run_code = 'M1_V0_2_BASELINE_BUILD'
      AND run_version = 1;

    /* 1 — Generation-disabled policy */
    v_message := NULL;
    v_pass := false;
    BEGIN
        UPDATE msbf_ctl.policy_profile
        SET profile_payload = jsonb_set(profile_payload,'{generation_enabled}','false'::jsonb)
        WHERE profile_code = 'M1_13_EXPOSURE_RECOVERY_LOSS_FOUNDATIONS'
          AND profile_version = 1;
        PERFORM msbf_m1.m1_13_assert_configuration(v_run_id);
    EXCEPTION WHEN OTHERS THEN
        v_message := SQLERRM;
        v_pass := position('generation is disabled' in lower(SQLERRM)) > 0;
    END;
    PERFORM pg_temp.m1_13_record_negative(
        'M1_13_NEG_01_GENERATION_DISABLED',
        'Generation-disabled policy',
        'generation is disabled',
        v_message,
        v_pass,
        'M1.13 must fail closed when governed generation is disabled.'
    );

    /* 2 — Unapproved policy profile */
    v_message := NULL;
    v_pass := false;
    BEGIN
        UPDATE msbf_ctl.policy_profile
        SET status = 'DRAFT'
        WHERE profile_code = 'M1_13_EXPOSURE_RECOVERY_LOSS_FOUNDATIONS'
          AND profile_version = 1;
        PERFORM msbf_m1.m1_13_assert_configuration(v_run_id);
    EXCEPTION WHEN OTHERS THEN
        v_message := SQLERRM;
        v_pass := position('requires an approved policy profile' in lower(SQLERRM)) > 0;
    END;
    PERFORM pg_temp.m1_13_record_negative(
        'M1_13_NEG_02_POLICY_APPROVAL',
        'Unapproved M1.13 policy',
        'requires an APPROVED policy profile',
        v_message,
        v_pass,
        'Only an approved exposure/recovery/loss methodology may be executed.'
    );

    /* 3 — Invalid governed methodology basis */
    v_message := NULL;
    v_pass := false;
    BEGIN
        UPDATE msbf_ctl.policy_profile
        SET profile_payload = jsonb_set(
            profile_payload,
            '{ead_method_code}',
            to_jsonb('INVALID_METHOD'::text)
        )
        WHERE profile_code = 'M1_13_EXPOSURE_RECOVERY_LOSS_FOUNDATIONS'
          AND profile_version = 1;
        PERFORM msbf_m1.m1_13_assert_configuration(v_run_id);
    EXCEPTION WHEN OTHERS THEN
        v_message := SQLERRM;
        v_pass := position('methodology basis is not the approved governed basis' in lower(SQLERRM)) > 0;
    END;
    PERFORM pg_temp.m1_13_record_negative(
        'M1_13_NEG_03_METHOD_BASIS',
        'Invalid governed methodology basis',
        'methodology basis is not the approved governed basis',
        v_message,
        v_pass,
        'The exposure, EAD, timing, and risk-proxy bases must remain governed.'
    );

    /* 4 — Invalid default-timing weight sum */
    v_message := NULL;
    v_pass := false;
    BEGIN
        UPDATE msbf_ctl.run_parameter_snapshot
        SET resolved_value = jsonb_set(
            resolved_value,
            '{value_numeric}',
            to_jsonb(0.90::numeric)
        )
        WHERE run_id = v_run_id
          AND parameter_name = 'default_timing_weight'
          AND scope_key = 'PATH_DAY_BUCKET:EARLY';
        PERFORM msbf_m1.m1_13_assert_configuration(v_run_id);
    EXCEPTION WHEN OTHERS THEN
        v_message := SQLERRM;
        v_pass := position('weights must contain three rows and sum to 1.0' in lower(SQLERRM)) > 0;
    END;
    PERFORM pg_temp.m1_13_record_negative(
        'M1_13_NEG_04_TIMING_WEIGHT_SUM',
        'Invalid default-timing weight sum',
        'weights must contain three rows and sum to 1.0',
        v_message,
        v_pass,
        'The early/middle/late default-timing distribution must remain normalized.'
    );

    /* 5 — Unapproved accepted stress scenario */
    v_message := NULL;
    v_pass := false;
    BEGIN
        UPDATE msbf_ctl.scenario_registry
        SET status = 'DRAFT'
        WHERE scenario_id IN (
            SELECT sr.scenario_id
            FROM msbf_ctl.scenario_registry sr
            JOIN msbf_ctl.scenario_set ss
              ON ss.scenario_set_id = sr.scenario_set_id
            WHERE ss.scenario_set_code = 'M1_V0_2_BASELINE_AND_STRESS'
              AND ss.scenario_set_version = 1
              AND sr.scenario_code = 'RECESSION_ENERGY'
              AND sr.scenario_version = 1
        );
        PERFORM msbf_m1.m1_13_assert_configuration(v_run_id);
    EXCEPTION WHEN OTHERS THEN
        v_message := SQLERRM;
        v_pass := position('requires exactly one accepted baseline and one recession_energy scenario' in lower(SQLERRM)) > 0;
    END;
    PERFORM pg_temp.m1_13_record_negative(
        'M1_13_NEG_05_UNAPPROVED_STRESS_SCENARIO',
        'Unapproved accepted stress scenario',
        'requires exactly one accepted BASELINE and one RECESSION_ENERGY scenario',
        v_message,
        v_pass,
        'The module must remain scoped to the approved matched M1.6 scenario set.'
    );

    /* 6 — Prerequisite run-status drift */
    v_message := NULL;
    v_pass := false;
    BEGIN
        UPDATE msbf_ctl.run_registry
        SET run_status = 'M1_11_ACCEPTED'
        WHERE run_id = v_run_id;
        PERFORM msbf_m1.m1_13_assert_generation_ready(v_run_id);
    EXCEPTION WHEN OTHERS THEN
        v_message := SQLERRM;
        v_pass := position('requires m1_12_accepted' in lower(SQLERRM)) > 0;
    END;
    PERFORM pg_temp.m1_13_record_negative(
        'M1_13_NEG_06_PREREQUISITE_STATUS',
        'Prerequisite run-status drift',
        'requires M1_12_ACCEPTED',
        v_message,
        v_pass,
        'M1.13 generation may begin only from the accepted M1.12 milestone.'
    );

    /* 7 — Attempted post-generation rerun */
    v_message := NULL;
    v_pass := false;
    BEGIN
        UPDATE msbf_ctl.run_registry
        SET run_status = 'M1_12_ACCEPTED'
        WHERE run_id = v_run_id;
        PERFORM msbf_m1.m1_13_assert_generation_ready(v_run_id);
    EXCEPTION WHEN OTHERS THEN
        v_message := SQLERRM;
        v_pass := position('target rows already exist' in lower(SQLERRM)) > 0;
    END;
    PERFORM pg_temp.m1_13_record_negative(
        'M1_13_NEG_07_RERUN_PROTECTION',
        'Attempted post-generation rerun',
        'target rows already exist',
        v_message,
        v_pass,
        'Committed M1.13 evidence must not be regenerated in place.'
    );
END;
$tests$;

INSERT INTO msbf_ctl.run_evidence (
    run_id, evidence_code, segment_key, metric_name,
    metric_value_text, unit_code, status, interpretation
)
SELECT
    (SELECT run_id
     FROM msbf_ctl.run_registry
     WHERE run_code = 'M1_V0_2_BASELINE_BUILD'
       AND run_version = 1),
    evidence_code,
    'PORTFOLIO',
    test_name,
    coalesce(observed_failure,'NO ERROR'),
    'TEXT',
    status,
    'expected=' || expected_failure || '|' || interpretation
FROM _m1_13_negative
ON CONFLICT (run_id,evidence_code,segment_key) DO UPDATE SET
    metric_name = EXCLUDED.metric_name,
    metric_value_text = EXCLUDED.metric_value_text,
    metric_value_numeric = NULL,
    unit_code = EXCLUDED.unit_code,
    status = EXCLUDED.status,
    interpretation = EXCLUDED.interpretation,
    created_at = clock_timestamp();

DO $assert$
DECLARE
    v_total integer;
    v_pass integer;
BEGIN
    SELECT count(*), count(*) FILTER (WHERE status='PASS')
    INTO v_total, v_pass
    FROM _m1_13_negative;

    IF v_total <> 7 OR v_pass <> 7 THEN
        RAISE EXCEPTION 'M1.13 negative controls failed: %/% PASS.', v_pass, v_total;
    END IF;
END;
$assert$;

COMMIT;

SELECT
    evidence_code,
    test_name,
    expected_failure,
    observed_failure,
    status,
    interpretation
FROM _m1_13_negative
ORDER BY evidence_code;
