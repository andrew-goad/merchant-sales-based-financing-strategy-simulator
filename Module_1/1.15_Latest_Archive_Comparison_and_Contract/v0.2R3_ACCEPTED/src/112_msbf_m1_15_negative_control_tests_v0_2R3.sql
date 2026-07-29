/* ============================================================================
MSBF M1.15 Negative Controls
Program : 112_msbf_m1_15_negative_control_tests_v0_2R3.sql
Version : v0.2R3
Purpose : Prove fail-closed handling of invalid policy, schema version, scenario
          approval, prerequisite status, archive mutation, and rerun attempts.
Output  : One filterable seven-row result set preserved after COMMIT.
============================================================================ */

BEGIN;
SET LOCAL statement_timeout='10min';

DROP TABLE IF EXISTS _m1_15_negative;
CREATE TEMP TABLE _m1_15_negative(
    evidence_code text PRIMARY KEY,
    control_name text NOT NULL,
    status text NOT NULL,
    observed_value text NOT NULL,
    interpretation text NOT NULL
) ON COMMIT PRESERVE ROWS;

CREATE OR REPLACE FUNCTION pg_temp.m1_15_add_negative(
    p_code text,p_name text,p_pass boolean,p_observed text,p_interpretation text
)
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO _m1_15_negative
    VALUES(
        p_code,p_name,CASE WHEN p_pass THEN 'PASS' ELSE 'FAIL' END,
        p_observed,p_interpretation
    );
END;
$$;

DO $controls$
DECLARE
    v_run_id bigint := (
        SELECT run_id FROM msbf_ctl.run_registry
        WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
    );
    v_scenario_id bigint := (
        SELECT min(l.scenario_id)
        FROM msbf_m1.application_module1_latest l
        WHERE l.module1_run_id=(
            SELECT run_id FROM msbf_ctl.run_registry
            WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
        )
    );
BEGIN
    IF (SELECT run_status FROM msbf_ctl.run_registry WHERE run_id=v_run_id)<>'M1_15_VALIDATED' THEN
        RAISE EXCEPTION 'M1.15 negative controls require M1_15_VALIDATED.';
    END IF;

    /* 1. Disabled policy must fail readiness. */
    BEGIN
        UPDATE msbf_ctl.run_registry SET run_status='M1_14_ACCEPTED' WHERE run_id=v_run_id;
        UPDATE msbf_ctl.policy_profile
        SET status='DRAFT'
        WHERE profile_code='M1_15_CONSUMPTION_CONTRACT' AND profile_version=1;
        PERFORM msbf_m1.m1_15_assert_configuration(v_run_id);
        PERFORM pg_temp.m1_15_add_negative(
            'M1_15_NEG_01_DISABLED_POLICY','Disabled policy rejection',false,
            'readiness unexpectedly passed','A non-approved M1.15 policy must fail closed.'
        );
    EXCEPTION WHEN OTHERS THEN
        PERFORM pg_temp.m1_15_add_negative(
            'M1_15_NEG_01_DISABLED_POLICY','Disabled policy rejection',true,
            SQLERRM,'A non-approved M1.15 policy was rejected.'
        );
    END;

    /* 2. Invalid contract schema must fail readiness. */
    BEGIN
        UPDATE msbf_ctl.run_registry SET run_status='M1_14_ACCEPTED' WHERE run_id=v_run_id;
        UPDATE msbf_ctl.policy_profile
        SET profile_payload=jsonb_set(profile_payload,'{schema_version}','"INVALID_SCHEMA"'::jsonb)
        WHERE profile_code='M1_15_CONSUMPTION_CONTRACT' AND profile_version=1;
        PERFORM msbf_m1.m1_15_assert_configuration(v_run_id);
        PERFORM pg_temp.m1_15_add_negative(
            'M1_15_NEG_02_INVALID_SCHEMA','Invalid schema-version rejection',false,
            'readiness unexpectedly passed','An invalid contract schema must fail closed.'
        );
    EXCEPTION WHEN OTHERS THEN
        PERFORM pg_temp.m1_15_add_negative(
            'M1_15_NEG_02_INVALID_SCHEMA','Invalid schema-version rejection',true,
            SQLERRM,'An invalid contract schema was rejected.'
        );
    END;

    /* 3. Unapproved accepted scenario must fail readiness. */
    BEGIN
        UPDATE msbf_ctl.run_registry SET run_status='M1_14_ACCEPTED' WHERE run_id=v_run_id;
        UPDATE msbf_ctl.scenario_registry SET status='DRAFT' WHERE scenario_id=v_scenario_id;
        PERFORM msbf_m1.m1_15_assert_configuration(v_run_id);
        PERFORM pg_temp.m1_15_add_negative(
            'M1_15_NEG_03_UNAPPROVED_SCENARIO','Unapproved scenario rejection',false,
            'readiness unexpectedly passed','The accepted scenario population must remain approved.'
        );
    EXCEPTION WHEN OTHERS THEN
        PERFORM pg_temp.m1_15_add_negative(
            'M1_15_NEG_03_UNAPPROVED_SCENARIO','Unapproved scenario rejection',true,
            SQLERRM,'An unapproved scenario was rejected.'
        );
    END;

    /* 4. Prerequisite run-status drift must fail readiness. */
    BEGIN
        UPDATE msbf_ctl.run_registry SET run_status='M1_13_ACCEPTED' WHERE run_id=v_run_id;
        PERFORM msbf_m1.m1_15_assert_prerequisite_status(v_run_id);
        PERFORM pg_temp.m1_15_add_negative(
            'M1_15_NEG_04_PREREQUISITE_DRIFT','Prerequisite status-drift rejection',false,
            'readiness unexpectedly passed','M1.15 requires the accepted M1.14 boundary.'
        );
    EXCEPTION WHEN OTHERS THEN
        PERFORM pg_temp.m1_15_add_negative(
            'M1_15_NEG_04_PREREQUISITE_DRIFT','Prerequisite status-drift rejection',true,
            SQLERRM,'Prerequisite status drift was rejected.'
        );
    END;

    /* 5. Archive UPDATE must be rejected by the immutable trigger. */
    BEGIN
        UPDATE msbf_m1.application_module1_archive
        SET contract_row_hash=contract_row_hash
        WHERE archive_id=(
            SELECT min(archive_id)
            FROM msbf_m1.application_module1_archive
            WHERE module1_run_id=v_run_id
        );
        PERFORM pg_temp.m1_15_add_negative(
            'M1_15_NEG_05_ARCHIVE_UPDATE','Archive update rejection',false,
            'archive update unexpectedly succeeded','Accepted archive rows must be immutable.'
        );
    EXCEPTION WHEN OTHERS THEN
        PERFORM pg_temp.m1_15_add_negative(
            'M1_15_NEG_05_ARCHIVE_UPDATE','Archive update rejection',true,
            SQLERRM,'Archive UPDATE was rejected.'
        );
    END;

    /* 6. Archive DELETE must be rejected by the immutable trigger. */
    BEGIN
        DELETE FROM msbf_m1.application_module1_archive
        WHERE archive_id=(
            SELECT min(archive_id)
            FROM msbf_m1.application_module1_archive
            WHERE module1_run_id=v_run_id
        );
        PERFORM pg_temp.m1_15_add_negative(
            'M1_15_NEG_06_ARCHIVE_DELETE','Archive delete rejection',false,
            'archive delete unexpectedly succeeded','Accepted archive rows must be immutable.'
        );
    EXCEPTION WHEN OTHERS THEN
        PERFORM pg_temp.m1_15_add_negative(
            'M1_15_NEG_06_ARCHIVE_DELETE','Archive delete rejection',true,
            SQLERRM,'Archive DELETE was rejected.'
        );
    END;

    /* 7. A committed M1.15 population must reject generation rerun. */
    BEGIN
        PERFORM msbf_m1.m1_15_assert_generation_ready(v_run_id);
        PERFORM pg_temp.m1_15_add_negative(
            'M1_15_NEG_07_POST_GENERATION_RERUN','Post-generation rerun rejection',false,
            'readiness unexpectedly passed','Generation is single-commit for the governed run.'
        );
    EXCEPTION WHEN OTHERS THEN
        PERFORM pg_temp.m1_15_add_negative(
            'M1_15_NEG_07_POST_GENERATION_RERUN','Post-generation rerun rejection',true,
            SQLERRM,'Post-generation rerun was rejected.'
        );
    END;
END;
$controls$;

DO $inventory$
BEGIN
    IF (SELECT count(*) FROM _m1_15_negative)<>7 THEN
        RAISE EXCEPTION 'M1.15 expected seven negative controls; observed %.',
            (SELECT count(*) FROM _m1_15_negative);
    END IF;
END;
$inventory$;

DELETE FROM msbf_ctl.run_evidence
WHERE run_id=(
    SELECT run_id FROM msbf_ctl.run_registry
    WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
)
AND evidence_code LIKE 'M1_15_NEG_%';

INSERT INTO msbf_ctl.run_evidence(
    run_id,evidence_code,segment_key,metric_name,metric_value_text,
    unit_code,status,interpretation
)
SELECT
    (SELECT run_id FROM msbf_ctl.run_registry
     WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1),
    evidence_code,'PORTFOLIO',control_name,observed_value,
    'TEXT',status,interpretation
FROM _m1_15_negative;

DO $final$
BEGIN
    IF (SELECT count(*) FILTER(WHERE status='FAIL') FROM _m1_15_negative)>0 THEN
        RAISE EXCEPTION 'M1.15 negative controls did not all pass.';
    END IF;
END;
$final$;

COMMIT;

SELECT * FROM _m1_15_negative ORDER BY evidence_code;
