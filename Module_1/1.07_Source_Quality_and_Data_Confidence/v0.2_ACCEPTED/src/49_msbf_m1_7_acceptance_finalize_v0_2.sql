/* ============================================================================
MSBF M1.7 Source Quality & Data Confidence — Acceptance Finalizer
Version : v0.2
Purpose : Finalize the source-quality gate only after positive, negative,
          deterministic, cardinality, stage-boundary, and configuration checks.
============================================================================ */
BEGIN;
SET LOCAL work_mem='64MB';
SET LOCAL jit=off;
SET LOCAL lock_timeout='10s';
SET LOCAL statement_timeout='10min';

CREATE TEMP TABLE _m1_7_accept_actual ON COMMIT DROP AS
SELECT *
FROM msbf_m1.m1_7_actual_source_snapshot(
    (
        SELECT run_id
        FROM msbf_ctl.run_registry
        WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
    )
);
CREATE UNIQUE INDEX ON _m1_7_accept_actual(entity_key);
ANALYZE _m1_7_accept_actual;

DO $accept$
DECLARE
    v_run_id bigint;
    v_status text;
    v_positive integer;
    v_positive_pass integer;
    v_negative integer;
    v_negative_pass integer;
    v_failed_evidence integer;
    v_rows bigint;
    v_apps integer;
    v_sources integer;
    v_physical_hash text;
    v_stored_hash text;
    v_mismatch bigint;
    v_downstream bigint;
    v_errors bigint;
    v_review integer;
    v_result text;
    v_finding text;
BEGIN
    SELECT run_id, run_status
      INTO STRICT v_run_id, v_status
      FROM msbf_ctl.run_registry
     WHERE run_code='M1_V0_2_BASELINE_BUILD'
       AND run_version=1
     FOR UPDATE;

    IF v_status='M1_7_ACCEPTED' THEN
        RAISE EXCEPTION 'M1.7 is already accepted.';
    END IF;

    IF v_status NOT IN ('M1_7_VALIDATED','M1_7_FAILED') THEN
        RAISE EXCEPTION
            'M1.7 acceptance requires completed validation; observed %.',
            v_status;
    END IF;

    SELECT count(*),
           count(*) FILTER (WHERE status='PASS')
      INTO v_positive, v_positive_pass
      FROM msbf_ctl.run_evidence
     WHERE run_id=v_run_id
       AND evidence_code~'^M1_7_POS_[0-9]{2}_';

    SELECT count(*),
           count(*) FILTER (WHERE status='PASS')
      INTO v_negative, v_negative_pass
      FROM msbf_ctl.run_evidence
     WHERE run_id=v_run_id
       AND evidence_code LIKE 'M1_7_NEG_%';

    SELECT count(*)
      INTO v_failed_evidence
      FROM msbf_ctl.run_evidence
     WHERE run_id=v_run_id
       AND (
           evidence_code~'^M1_7_POS_[0-9]{2}_'
           OR evidence_code LIKE 'M1_7_NEG_%'
       )
       AND status='FAIL';

    SELECT count(*),
           count(DISTINCT merchant_application_id),
           count(DISTINCT source_code)
      INTO v_rows, v_apps, v_sources
      FROM msbf_m1.source_snapshot
     WHERE module1_run_id=v_run_id;

    SELECT md5(
               string_agg(
                   entity_key || '|' || row_hash,
                   '||' ORDER BY entity_key
               )
           )
      INTO v_physical_hash
      FROM _m1_7_accept_actual;

    SELECT metric_value_text
      INTO v_stored_hash
      FROM msbf_ctl.run_evidence
     WHERE run_id=v_run_id
       AND evidence_code='M1_7_SOURCE_SET_HASH';

    SELECT count(*)
      INTO v_mismatch
      FROM msbf_m1.source_snapshot s
      JOIN _m1_7_accept_actual a
        ON a.entity_key=s.merchant_application_id || '|' || s.source_code
     WHERE s.module1_run_id=v_run_id
       AND s.source_hash IS DISTINCT FROM a.row_hash;

    SELECT
        (SELECT count(*) FROM msbf_m1.application_obligation_snapshot WHERE created_by_run_id=v_run_id)
      + (SELECT count(*) FROM msbf_m1.collateral_availability_snapshot WHERE created_by_run_id=v_run_id)
      + (SELECT count(*) FROM msbf_m1.guarantee_availability_snapshot WHERE created_by_run_id=v_run_id)
      + (SELECT count(*) FROM msbf_m1.application_business_credit_snapshot WHERE created_by_run_id=v_run_id)
      + (SELECT count(*) FROM msbf_m1.application_owner_credit_snapshot WHERE created_by_run_id=v_run_id)
      + (SELECT count(*) FROM msbf_m1.verification_result WHERE created_by_run_id=v_run_id)
      + (SELECT count(*) FROM msbf_m1.merchant_feature_snapshot WHERE module1_run_id=v_run_id)
      + (SELECT count(*) FROM msbf_m1.merchant_risk_snapshot WHERE module1_run_id=v_run_id)
      + (SELECT count(*) FROM msbf_m1.ead_path_snapshot WHERE module1_run_id=v_run_id)
      + (SELECT count(*) FROM msbf_m1.module1_latest WHERE module1_run_id=v_run_id)
      + (SELECT count(*) FROM msbf_m1.module1_archive WHERE module1_run_id=v_run_id)
      INTO v_downstream;

    SELECT count(*)
      INTO v_errors
      FROM msbf_ctl.profile_resolution_error
     WHERE run_id=v_run_id
       AND severity='BLOCKING';

    v_result:=CASE
        WHEN v_status='M1_7_VALIDATED'
         AND v_positive=55
         AND v_positive_pass=55
         AND v_negative=5
         AND v_negative_pass=5
         AND v_failed_evidence=0
         AND v_rows=5250
         AND v_apps=750
         AND v_sources=7
         AND v_physical_hash IS NOT NULL
         AND v_physical_hash=v_stored_hash
         AND v_mismatch=0
         AND v_downstream=0
         AND v_errors=0
        THEN 'PASS'
        ELSE 'FAIL'
    END;

    v_finding:=format(
        'Positive %s/%s; negative %s/%s; failed evidence %s; rows %s; applications %s; sources %s; mismatches %s; downstream %s; blocking errors %s.',
        v_positive_pass,v_positive,v_negative_pass,v_negative,v_failed_evidence,
        v_rows,v_apps,v_sources,v_mismatch,v_downstream,v_errors
    );

    SELECT coalesce(max(review_version),0)+1
      INTO v_review
      FROM msbf_ctl.acceptance_gate_result
     WHERE run_id=v_run_id
       AND gate_id='M1_7_SOURCE_QUALITY_CONFIDENCE';

    INSERT INTO msbf_ctl.acceptance_gate_result(
        run_id,
        gate_id,
        review_version,
        result_status,
        observed_value,
        threshold_value,
        finding,
        residual_limitation,
        reviewer_role
    )
    VALUES(
        v_run_id,
        'M1_7_SOURCE_QUALITY_CONFIDENCE',
        v_review,
        v_result,
        jsonb_build_object(
            'positive_checks',v_positive,
            'positive_passes',v_positive_pass,
            'negative_controls',v_negative,
            'negative_passes',v_negative_pass,
            'failed_evidence',v_failed_evidence,
            'source_rows',v_rows,
            'applications',v_apps,
            'sources',v_sources,
            'set_hash',v_physical_hash,
            'mismatches',v_mismatch,
            'downstream',v_downstream,
            'blocking_errors',v_errors
        )::text,
        '55 positive PASS; 5 negative PASS; 5,250 source rows; 750 applications; 7 sources; 0 mismatches; 0 downstream rows; 0 blocking errors.',
        v_finding,
        'Synthetic source availability, quality, freshness, reconciliation and confidence; not production data-quality certification.',
        'Independent Validation'
    );

    INSERT INTO msbf_ctl.run_evidence(
        run_id,evidence_code,segment_key,metric_name,
        metric_value_text,unit_code,status,interpretation
    )
    VALUES(
        v_run_id,
        'M1_7_ACCEPTANCE_SUMMARY',
        'PORTFOLIO',
        'M1.7 acceptance summary',
        v_finding,
        'TEXT',
        v_result,
        'Formal M1.7 stage acceptance.'
    )
    ON CONFLICT(run_id,evidence_code,segment_key)
    DO UPDATE SET
        metric_value_numeric=NULL,
        metric_value_text=EXCLUDED.metric_value_text,
        unit_code=EXCLUDED.unit_code,
        status=EXCLUDED.status,
        threshold_value_numeric=NULL,
        interpretation=EXCLUDED.interpretation,
        created_at=clock_timestamp();

    UPDATE msbf_ctl.run_registry
       SET run_status=CASE WHEN v_result='PASS' THEN 'M1_7_ACCEPTED' ELSE 'M1_7_FAILED' END,
           completed_at=CASE WHEN v_result='PASS' THEN clock_timestamp() ELSE NULL END,
           notes=coalesce(notes,'')
               || E'\nM1.7 acceptance review '
               || v_review || ': ' || v_result || '.'
     WHERE run_id=v_run_id;
END;
$accept$;

COMMIT;

SELECT
    r.run_id,
    r.run_status,
    a.gate_id,
    a.review_version,
    a.result_status,
    a.observed_value,
    a.threshold_value,
    a.finding,
    a.residual_limitation,
    a.reviewed_at
FROM msbf_ctl.run_registry r
JOIN LATERAL (
    SELECT *
    FROM msbf_ctl.acceptance_gate_result x
    WHERE x.run_id=r.run_id
      AND x.gate_id='M1_7_SOURCE_QUALITY_CONFIDENCE'
    ORDER BY review_version DESC
    LIMIT 1
) a ON true
WHERE r.run_code='M1_V0_2_BASELINE_BUILD'
  AND r.run_version=1;
