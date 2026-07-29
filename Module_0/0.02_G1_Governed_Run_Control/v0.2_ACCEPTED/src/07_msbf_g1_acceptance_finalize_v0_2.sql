/* ============================================================================
MSBF G1 Acceptance Finalization
Version : v0.2
Purpose : Insert the immutable G1_CONTROL_PLANE acceptance result and authorize
          M1.2 deterministic merchant generation only after all positive checks
          and negative controls pass.
============================================================================ */

BEGIN;

DO $$
DECLARE
    v_run_id bigint;
    v_run_status text;
    v_positive_count integer;
    v_positive_pass integer;
    v_negative_count integer;
    v_negative_pass integer;
    v_failed_count integer;
    v_blocking_errors integer;
    v_review_version integer;
    v_parameter_rows integer;
    v_profile_rows integer;
    v_source_rows integer;
    v_analytical_rows bigint;
    v_parameter_hash text;
    v_profile_hash text;
    v_source_hash text;
    v_result text;
    v_observed text;
BEGIN
    SELECT run_id, run_status, parameter_snapshot_hash, profile_snapshot_hash, source_snapshot_hash
      INTO STRICT v_run_id, v_run_status, v_parameter_hash, v_profile_hash, v_source_hash
      FROM msbf_ctl.run_registry
     WHERE run_code='M1_V0_2_BASELINE_BUILD'
       AND run_version=1
     FOR UPDATE;

    IF v_run_status='G1_READY'
       AND EXISTS (
           SELECT 1
           FROM msbf_ctl.acceptance_gate_result
           WHERE run_id=v_run_id
             AND gate_id='G1_CONTROL_PLANE'
             AND result_status='PASS'
       ) THEN
        RAISE NOTICE 'Run % is already G1_READY with a PASS acceptance result; no duplicate acceptance inserted.', v_run_id;
        RETURN;
    END IF;

    IF v_run_status <> 'G1_VALIDATED' THEN
        RAISE EXCEPTION 'G1 finalization requires run_status=G1_VALIDATED; observed %', v_run_status;
    END IF;

    SELECT
        COUNT(*) FILTER (WHERE evidence_code LIKE 'G1_POS_%'),
        COUNT(*) FILTER (WHERE evidence_code LIKE 'G1_POS_%' AND status='PASS'),
        COUNT(*) FILTER (WHERE evidence_code LIKE 'G1_NEG_%'),
        COUNT(*) FILTER (WHERE evidence_code LIKE 'G1_NEG_%' AND status='PASS'),
        COUNT(*) FILTER (WHERE (evidence_code LIKE 'G1_POS_%' OR evidence_code LIKE 'G1_NEG_%') AND status='FAIL')
    INTO v_positive_count, v_positive_pass, v_negative_count, v_negative_pass, v_failed_count
    FROM msbf_ctl.run_evidence
    WHERE run_id=v_run_id;

    SELECT COUNT(*) INTO v_blocking_errors
    FROM msbf_ctl.profile_resolution_error
    WHERE run_id=v_run_id AND severity='BLOCKING';

    SELECT COUNT(*) INTO v_parameter_rows FROM msbf_ctl.run_parameter_snapshot WHERE run_id=v_run_id;
    SELECT COUNT(*) INTO v_profile_rows FROM msbf_ctl.run_profile_snapshot WHERE run_id=v_run_id;
    SELECT COUNT(*) INTO v_source_rows FROM msbf_ctl.run_source_snapshot WHERE run_id=v_run_id;

    SELECT
          (SELECT COUNT(*) FROM msbf_m1.merchant_master)
        + (SELECT COUNT(*) FROM msbf_m1.merchant_owner_guarantor)
        + (SELECT COUNT(*) FROM msbf_m1.merchant_industry_assignment)
        + (SELECT COUNT(*) FROM msbf_m1.partner_channel)
        + (SELECT COUNT(*) FROM msbf_m1.processor_account)
        + (SELECT COUNT(*) FROM msbf_m1.merchant_relationship_snapshot)
        + (SELECT COUNT(*) FROM msbf_m1.merchant_application)
        + (SELECT COUNT(*) FROM msbf_m1.source_snapshot)
        + (SELECT COUNT(*) FROM msbf_m1.application_obligation_snapshot)
        + (SELECT COUNT(*) FROM msbf_m1.collateral_availability_snapshot)
        + (SELECT COUNT(*) FROM msbf_m1.guarantee_availability_snapshot)
        + (SELECT COUNT(*) FROM msbf_m1.application_business_credit_snapshot)
        + (SELECT COUNT(*) FROM msbf_m1.application_owner_credit_snapshot)
        + (SELECT COUNT(*) FROM msbf_m1.merchant_pos_daily_base)
        + (SELECT COUNT(*) FROM msbf_m1.merchant_pos_daily_scenario)
        + (SELECT COUNT(*) FROM msbf_m1.merchant_deposit_daily_base)
        + (SELECT COUNT(*) FROM msbf_m1.merchant_deposit_daily_scenario)
        + (SELECT COUNT(*) FROM msbf_m1.verification_result)
        + (SELECT COUNT(*) FROM msbf_m1.merchant_feature_snapshot)
        + (SELECT COUNT(*) FROM msbf_m1.feature_value)
        + (SELECT COUNT(*) FROM msbf_m1.merchant_risk_snapshot)
        + (SELECT COUNT(*) FROM msbf_m1.risk_component_detail)
        + (SELECT COUNT(*) FROM msbf_m1.ead_path_snapshot)
        + (SELECT COUNT(*) FROM msbf_m1.module1_latest)
        + (SELECT COUNT(*) FROM msbf_m1.module1_archive)
    INTO v_analytical_rows;

    v_result := CASE
        WHEN v_positive_count=20
         AND v_positive_pass=20
         AND v_negative_count=3
         AND v_negative_pass=3
         AND v_failed_count=0
         AND v_blocking_errors=0
         AND v_parameter_rows=401
         AND v_profile_rows=18
         AND v_source_rows=7
         AND v_analytical_rows=0
         AND v_parameter_hash IS NOT NULL
         AND v_profile_hash IS NOT NULL
         AND v_source_hash IS NOT NULL
        THEN 'PASS'
        ELSE 'FAIL'
    END;

    v_observed := jsonb_build_object(
        'positive_checks', v_positive_count,
        'positive_passes', v_positive_pass,
        'negative_controls', v_negative_count,
        'negative_control_passes', v_negative_pass,
        'failed_evidence', v_failed_count,
        'blocking_resolution_errors', v_blocking_errors,
        'parameter_snapshot_rows', v_parameter_rows,
        'profile_snapshot_rows', v_profile_rows,
        'source_snapshot_rows', v_source_rows,
        'analytical_rows_before_authorization', v_analytical_rows,
        'parameter_snapshot_hash', v_parameter_hash,
        'profile_snapshot_hash', v_profile_hash,
        'source_snapshot_hash', v_source_hash
    )::text;

    SELECT COALESCE(MAX(review_version),0)+1
      INTO v_review_version
      FROM msbf_ctl.acceptance_gate_result
     WHERE run_id=v_run_id AND gate_id='G1_CONTROL_PLANE';

    INSERT INTO msbf_ctl.acceptance_gate_result (
        run_id, gate_id, review_version, result_status,
        observed_value, threshold_value, finding, residual_limitation,
        reviewer_role
    )
    VALUES (
        v_run_id,
        'G1_CONTROL_PLANE',
        v_review_version,
        v_result,
        v_observed,
        '20/20 positive checks PASS; 3/3 negative controls PASS; 0 blocking errors; 401/18/7 snapshots; 0 analytical rows.',
        CASE WHEN v_result='PASS'
             THEN 'Governed run and configuration readiness accepted.'
             ELSE 'G1 acceptance criteria were not fully satisfied.' END,
        'Synthetic demonstration configuration only. No production underwriting, legal, regulatory, pricing, PD, LGD, capital, accounting, or fair-lending conclusion is established.',
        'Project Owner / Validation'
    );

    INSERT INTO msbf_ctl.run_evidence (
        run_id, evidence_code, segment_key, metric_name,
        metric_value_text, unit_code, status, interpretation
    )
    VALUES (
        v_run_id,
        'G1_ACCEPTANCE_SUMMARY',
        'PORTFOLIO',
        'G1 governed run and configuration acceptance',
        v_observed,
        'JSON_TEXT',
        v_result,
        CASE WHEN v_result='PASS'
             THEN 'G1_CONTROL_PLANE accepted; M1.2 deterministic merchant generation is authorized.'
             ELSE 'G1_CONTROL_PLANE failed; analytical generation remains prohibited.' END
    )
    ON CONFLICT (run_id, evidence_code, segment_key)
    DO UPDATE SET
        metric_name=EXCLUDED.metric_name,
        metric_value_numeric=NULL,
        metric_value_text=EXCLUDED.metric_value_text,
        unit_code=EXCLUDED.unit_code,
        status=EXCLUDED.status,
        threshold_value_numeric=NULL,
        interpretation=EXCLUDED.interpretation,
        created_at=clock_timestamp();

    IF v_result='PASS' THEN
        UPDATE msbf_ctl.run_registry
           SET run_status='G1_READY',
               notes='G1_CONTROL_PLANE accepted. Authorized for M1.2 deterministic merchant generation; analytical execution has not yet started.'
         WHERE run_id=v_run_id;

        UPDATE msbf_m1.population_registry
           SET population_status='READY_FOR_GENERATION'
         WHERE created_by_run_id=v_run_id
           AND population_id='MSBF_POP_0001';
    ELSE
        UPDATE msbf_ctl.run_registry
           SET run_status='G1_FAILED',
               notes='G1_CONTROL_PLANE failed. Analytical generation is prohibited.'
         WHERE run_id=v_run_id;
    END IF;
END
$$;

COMMIT;

SELECT
    r.run_id,
    r.run_code,
    r.run_version,
    r.run_status,
    p.population_id,
    p.population_status,
    g.gate_id,
    g.review_version,
    g.result_status,
    g.reviewed_at,
    g.finding,
    g.residual_limitation,
    r.parameter_snapshot_hash,
    r.profile_snapshot_hash,
    r.source_snapshot_hash
FROM msbf_ctl.run_registry r
LEFT JOIN msbf_m1.population_registry p ON p.created_by_run_id=r.run_id
LEFT JOIN LATERAL (
    SELECT *
    FROM msbf_ctl.acceptance_gate_result x
    WHERE x.run_id=r.run_id AND x.gate_id='G1_CONTROL_PLANE'
    ORDER BY x.review_version DESC
    LIMIT 1
) g ON true
WHERE r.run_code='M1_V0_2_BASELINE_BUILD'
  AND r.run_version=1;
