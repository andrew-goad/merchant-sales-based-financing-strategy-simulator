/* ============================================================================
MSBF M1.7 Source Quality & Data Confidence — Negative Controls
Version : v0.2
Purpose : Prove that the same M1.7 configuration and generation guardrails
          reject missing parameters, unready contracts, invalid thresholds,
          run-status drift, and post-generation reruns.
============================================================================ */
BEGIN;
SET LOCAL lock_timeout='10s';
SET LOCAL statement_timeout='10min';

DO $controls$
DECLARE
    v_run_id bigint;
    v_run_status text;
    v_pass integer:=0;
    v_message text;
BEGIN
    SELECT run_id, run_status
      INTO STRICT v_run_id, v_run_status
      FROM msbf_ctl.run_registry
     WHERE run_code='M1_V0_2_BASELINE_BUILD'
       AND run_version=1
     FOR UPDATE;

    IF v_run_status<>'M1_7_VALIDATED' THEN
        RAISE EXCEPTION
            'M1.7 negative controls require M1_7_VALIDATED; observed %.',
            v_run_status;
    END IF;

    DELETE FROM msbf_ctl.run_evidence
     WHERE run_id=v_run_id
       AND evidence_code LIKE 'M1_7_NEG_%';

    -- 01 — Missing typed parameter value.
    BEGIN
        UPDATE msbf_ctl.run_parameter_snapshot
           SET resolved_value='{}'::jsonb
         WHERE run_id=v_run_id
           AND parameter_name='source_completeness_pass_rate'
           AND scope_key='GLOBAL';

        PERFORM msbf_m1.m1_7_assert_configuration(v_run_id);
        RAISE EXCEPTION 'M1_7_NEG_CONTROL_DID_NOT_REJECT';
    EXCEPTION
        WHEN OTHERS THEN
            v_message:=SQLERRM;
            IF v_message LIKE 'M1.7 configuration requires 18 typed parameter rows%' THEN
                v_pass:=v_pass+1;
            ELSE
                RAISE;
            END IF;
    END;

    INSERT INTO msbf_ctl.run_evidence(
        run_id,evidence_code,segment_key,metric_name,
        metric_value_text,unit_code,status,interpretation
    )
    VALUES(
        v_run_id,
        'M1_7_NEG_01_MISSING_PARAMETER',
        'PORTFOLIO',
        'Missing required parameter rejected',
        'PASS',
        'TEXT',
        'PASS',
        'The production configuration guard rejected a temporarily missing typed parameter value.'
    );

    -- 02 — Source snapshot/contract not ready.
    BEGIN
        UPDATE msbf_ctl.run_source_snapshot
           SET quality_status='NOT_READY'
         WHERE run_id=v_run_id
           AND source_code='POS_DAILY';

        PERFORM msbf_m1.m1_7_assert_configuration(v_run_id);
        RAISE EXCEPTION 'M1_7_NEG_CONTROL_DID_NOT_REJECT';
    EXCEPTION
        WHEN OTHERS THEN
            v_message:=SQLERRM;
            IF v_message LIKE 'M1.7 requires seven approved, effective, contract-ready source families%' THEN
                v_pass:=v_pass+1;
            ELSE
                RAISE;
            END IF;
    END;

    INSERT INTO msbf_ctl.run_evidence(
        run_id,evidence_code,segment_key,metric_name,
        metric_value_text,unit_code,status,interpretation
    )
    VALUES(
        v_run_id,
        'M1_7_NEG_02_SOURCE_NOT_READY',
        'PORTFOLIO',
        'Unready source contract rejected',
        'PASS',
        'TEXT',
        'PASS',
        'The production configuration guard rejected a temporary unready POS source.'
    );

    -- 03 — Non-monotonic thresholds.
    BEGIN
        UPDATE msbf_ctl.run_parameter_snapshot
           SET resolved_value=jsonb_set(
               resolved_value,
               '{value_numeric}',
               to_jsonb(1.10::numeric),
               true
           )
         WHERE run_id=v_run_id
           AND parameter_name='source_completeness_warning_rate'
           AND scope_key='GLOBAL';

        PERFORM msbf_m1.m1_7_assert_configuration(v_run_id);
        RAISE EXCEPTION 'M1_7_NEG_CONTROL_DID_NOT_REJECT';
    EXCEPTION
        WHEN OTHERS THEN
            v_message:=SQLERRM;
            IF v_message='M1.7 global threshold configuration is invalid or non-monotonic.' THEN
                v_pass:=v_pass+1;
            ELSE
                RAISE;
            END IF;
    END;

    INSERT INTO msbf_ctl.run_evidence(
        run_id,evidence_code,segment_key,metric_name,
        metric_value_text,unit_code,status,interpretation
    )
    VALUES(
        v_run_id,
        'M1_7_NEG_03_THRESHOLD_ORDER',
        'PORTFOLIO',
        'Invalid threshold ordering rejected',
        'PASS',
        'TEXT',
        'PASS',
        'The production configuration guard rejected temporarily non-monotonic completeness thresholds.'
    );

    -- 04 — Run-status drift.
    BEGIN
        UPDATE msbf_ctl.run_registry
           SET run_status='M1_6_FAILED'
         WHERE run_id=v_run_id;

        PERFORM msbf_m1.m1_7_assert_generation_ready(v_run_id);
        RAISE EXCEPTION 'M1_7_NEG_CONTROL_DID_NOT_REJECT';
    EXCEPTION
        WHEN OTHERS THEN
            v_message:=SQLERRM;
            IF v_message LIKE 'M1.7 generation requires M1_6_ACCEPTED; observed M1_6_FAILED.%' THEN
                v_pass:=v_pass+1;
            ELSE
                RAISE;
            END IF;
    END;

    INSERT INTO msbf_ctl.run_evidence(
        run_id,evidence_code,segment_key,metric_name,
        metric_value_text,unit_code,status,interpretation
    )
    VALUES(
        v_run_id,
        'M1_7_NEG_04_STATUS_DRIFT',
        'PORTFOLIO',
        'Run-status drift rejected',
        'PASS',
        'TEXT',
        'PASS',
        'The production generation guard rejected a temporary prerequisite-status drift.'
    );

    -- 05 — Existing source snapshots prevent regeneration.
    BEGIN
        UPDATE msbf_ctl.run_registry
           SET run_status='M1_6_ACCEPTED'
         WHERE run_id=v_run_id;

        PERFORM msbf_m1.m1_7_assert_generation_ready(v_run_id);
        RAISE EXCEPTION 'M1_7_NEG_CONTROL_DID_NOT_REJECT';
    EXCEPTION
        WHEN OTHERS THEN
            v_message:=SQLERRM;
            IF v_message LIKE 'M1.7 source snapshots already exist:%' THEN
                v_pass:=v_pass+1;
            ELSE
                RAISE;
            END IF;
    END;

    INSERT INTO msbf_ctl.run_evidence(
        run_id,evidence_code,segment_key,metric_name,
        metric_value_text,unit_code,status,interpretation
    )
    VALUES(
        v_run_id,
        'M1_7_NEG_05_REGENERATION',
        'PORTFOLIO',
        'Post-generation rerun rejected',
        'PASS',
        'TEXT',
        'PASS',
        'The production generation guard rejected an attempted rerun over persisted source snapshots.'
    );

    IF v_pass<>5 THEN
        RAISE EXCEPTION
            'M1.7 negative controls did not all reject as designed: %/5.',
            v_pass;
    END IF;

    IF (SELECT run_status FROM msbf_ctl.run_registry WHERE run_id=v_run_id)
       IS DISTINCT FROM 'M1_7_VALIDATED'
    THEN
        RAISE EXCEPTION 'M1.7 negative controls did not restore the accepted pre-control run status.';
    END IF;

    IF (SELECT count(*) FROM msbf_m1.source_snapshot WHERE module1_run_id=v_run_id)<>5250 THEN
        RAISE EXCEPTION 'M1.7 negative controls changed the persisted source-snapshot count.';
    END IF;
END;
$controls$;

COMMIT;

SELECT
    evidence_code,
    metric_name,
    status,
    interpretation
FROM msbf_ctl.run_evidence
WHERE run_id=(
    SELECT run_id
    FROM msbf_ctl.run_registry
    WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
)
  AND evidence_code LIKE 'M1_7_NEG_%'
ORDER BY evidence_code;
