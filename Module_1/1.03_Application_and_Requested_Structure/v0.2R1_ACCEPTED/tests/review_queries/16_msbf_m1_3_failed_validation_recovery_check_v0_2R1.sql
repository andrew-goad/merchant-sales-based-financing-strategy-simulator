/* ============================================================================
MSBF M1.3 Failed-Validation Recovery Precheck
Version : v0.2R1
Purpose : Confirm that the accepted 750-row application set is intact and that
          the only blocking positive-validation failure is the original
          relationship-stage aggregate-ratio test before applying the v0.2R1
          validation-specification correction.

This script is read-only. It does not regenerate or alter applications.
============================================================================ */

WITH ctx AS (
    SELECT r.run_id,r.run_code,r.run_version,r.run_status,r.population_id,
           r.parameter_snapshot_hash,r.profile_snapshot_hash,r.source_snapshot_hash,
           p.population_status,p.population_hash
    FROM msbf_ctl.run_registry r
    JOIN msbf_m1.population_registry p ON p.population_id=r.population_id
    WHERE r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1
), hashes AS (
    SELECT
      (SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key))
         FROM msbf_m1.m1_3_expected_application_snapshot((SELECT run_id FROM ctx))) AS expected_hash,
      (SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key))
         FROM msbf_m1.m1_3_actual_application_snapshot((SELECT run_id FROM ctx))) AS actual_hash,
      (SELECT metric_value_text
         FROM msbf_ctl.run_evidence
        WHERE run_id=(SELECT run_id FROM ctx)
          AND evidence_code='M1_3_APPLICATION_SET_HASH'
          AND segment_key='PORTFOLIO') AS stored_hash
), mismatches AS (
    SELECT COUNT(*) AS mismatch_count
    FROM msbf_m1.m1_3_expected_application_snapshot((SELECT run_id FROM ctx)) e
    FULL JOIN msbf_m1.m1_3_actual_application_snapshot((SELECT run_id FROM ctx)) a USING(entity_key)
    WHERE e.row_hash IS DISTINCT FROM a.row_hash
), evidence AS (
    SELECT
      COUNT(*) FILTER (WHERE evidence_code LIKE 'M1_3_POS_%') AS positive_checks,
      COUNT(*) FILTER (WHERE evidence_code LIKE 'M1_3_POS_%' AND status='PASS') AS positive_passes,
      COUNT(*) FILTER (WHERE evidence_code LIKE 'M1_3_POS_%' AND status='FAIL') AS positive_failures,
      string_agg(evidence_code,',' ORDER BY evidence_code)
        FILTER (WHERE evidence_code LIKE 'M1_3_POS_%' AND status='FAIL') AS failed_positive_codes,
      COUNT(*) FILTER (WHERE evidence_code LIKE 'M1_3_NEG_%') AS negative_controls,
      COUNT(*) FILTER (WHERE evidence_code LIKE 'M1_3_NEG_%' AND status='PASS') AS negative_passes
    FROM msbf_ctl.run_evidence
    WHERE run_id=(SELECT run_id FROM ctx)
), downstream AS (
    SELECT
      (SELECT COUNT(*) FROM msbf_m1.source_snapshot WHERE module1_run_id=(SELECT run_id FROM ctx))
     +(SELECT COUNT(*) FROM msbf_m1.application_obligation_snapshot WHERE created_by_run_id=(SELECT run_id FROM ctx))
     +(SELECT COUNT(*) FROM msbf_m1.collateral_availability_snapshot WHERE created_by_run_id=(SELECT run_id FROM ctx))
     +(SELECT COUNT(*) FROM msbf_m1.guarantee_availability_snapshot WHERE created_by_run_id=(SELECT run_id FROM ctx))
     +(SELECT COUNT(*) FROM msbf_m1.application_business_credit_snapshot WHERE created_by_run_id=(SELECT run_id FROM ctx))
     +(SELECT COUNT(*) FROM msbf_m1.application_owner_credit_snapshot WHERE created_by_run_id=(SELECT run_id FROM ctx))
     +(SELECT COUNT(*) FROM msbf_m1.verification_result WHERE created_by_run_id=(SELECT run_id FROM ctx))
     +(SELECT COUNT(*) FROM msbf_m1.merchant_pos_daily_base WHERE generated_by_run_id=(SELECT run_id FROM ctx))
     +(SELECT COUNT(*) FROM msbf_m1.merchant_pos_daily_scenario WHERE generated_by_run_id=(SELECT run_id FROM ctx))
     +(SELECT COUNT(*) FROM msbf_m1.merchant_deposit_daily_base WHERE generated_by_run_id=(SELECT run_id FROM ctx))
     +(SELECT COUNT(*) FROM msbf_m1.merchant_deposit_daily_scenario WHERE generated_by_run_id=(SELECT run_id FROM ctx))
     +(SELECT COUNT(*) FROM msbf_m1.merchant_feature_snapshot WHERE module1_run_id=(SELECT run_id FROM ctx))
     +(SELECT COUNT(*) FROM msbf_m1.feature_value WHERE module1_run_id=(SELECT run_id FROM ctx))
     +(SELECT COUNT(*) FROM msbf_m1.merchant_risk_snapshot WHERE module1_run_id=(SELECT run_id FROM ctx))
     +(SELECT COUNT(*) FROM msbf_m1.risk_component_detail WHERE module1_run_id=(SELECT run_id FROM ctx))
     +(SELECT COUNT(*) FROM msbf_m1.ead_path_snapshot WHERE module1_run_id=(SELECT run_id FROM ctx))
     +(SELECT COUNT(*) FROM msbf_m1.module1_latest WHERE module1_run_id=(SELECT run_id FROM ctx))
     +(SELECT COUNT(*) FROM msbf_m1.module1_archive WHERE module1_run_id=(SELECT run_id FROM ctx)) AS downstream_rows
), checks AS (
    SELECT ctx.*,
           (SELECT COUNT(*) FROM msbf_m1.merchant_application WHERE created_by_run_id=ctx.run_id) AS applications,
           hashes.expected_hash,hashes.actual_hash,hashes.stored_hash,
           mismatches.mismatch_count,
           evidence.positive_checks,evidence.positive_passes,evidence.positive_failures,
           evidence.failed_positive_codes,evidence.negative_controls,evidence.negative_passes,
           downstream.downstream_rows,
           (SELECT COUNT(*) FROM msbf_ctl.profile_resolution_error WHERE run_id=ctx.run_id AND severity='BLOCKING') AS blocking_errors,
           (SELECT result_status FROM msbf_ctl.acceptance_gate_result
             WHERE run_id=ctx.run_id AND gate_id='G1_CONTROL_PLANE'
             ORDER BY review_version DESC LIMIT 1) AS g1_status,
           (SELECT result_status FROM msbf_ctl.acceptance_gate_result
             WHERE run_id=ctx.run_id AND gate_id='M1_2_POPULATION'
             ORDER BY review_version DESC LIMIT 1) AS m12_status,
           (SELECT result_status FROM msbf_ctl.acceptance_gate_result
             WHERE run_id=ctx.run_id AND gate_id='M1_3_APPLICATION_REQUEST'
             ORDER BY review_version DESC LIMIT 1) AS latest_m13_status
    FROM ctx CROSS JOIN hashes CROSS JOIN mismatches CROSS JOIN evidence CROSS JOIN downstream
)
SELECT *,
       CASE WHEN run_status='M1_3_FAILED'
                  AND population_status='M1_2_ACCEPTED'
                  AND applications=750
                  AND mismatch_count=0
                  AND expected_hash=actual_hash AND expected_hash=stored_hash
                  AND positive_checks=42 AND positive_passes=41 AND positive_failures=1
                  AND failed_positive_codes='M1_3_POS_36_RELATIONSHIP_DIFFERENTIATION'
                  AND negative_controls=3 AND negative_passes=3
                  AND downstream_rows=0 AND blocking_errors=0
                  AND g1_status='PASS' AND m12_status='PASS' AND latest_m13_status='FAIL'
             THEN 'PASS' ELSE 'FAIL' END AS recovery_state_status
FROM checks;

DO $$
DECLARE v_status text;
BEGIN
  WITH ctx AS (
      SELECT r.run_id,r.run_status,r.population_id,p.population_status
      FROM msbf_ctl.run_registry r
      JOIN msbf_m1.population_registry p ON p.population_id=r.population_id
      WHERE r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1
  ), h AS (
      SELECT
       (SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) FROM msbf_m1.m1_3_expected_application_snapshot((SELECT run_id FROM ctx))) expected_hash,
       (SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) FROM msbf_m1.m1_3_actual_application_snapshot((SELECT run_id FROM ctx))) actual_hash,
       (SELECT metric_value_text FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM ctx) AND evidence_code='M1_3_APPLICATION_SET_HASH' AND segment_key='PORTFOLIO') stored_hash
  ), x AS (
      SELECT CASE WHEN (SELECT run_status FROM ctx)='M1_3_FAILED'
                        AND (SELECT population_status FROM ctx)='M1_2_ACCEPTED'
                        AND (SELECT COUNT(*) FROM msbf_m1.merchant_application WHERE created_by_run_id=(SELECT run_id FROM ctx))=750
                        AND (SELECT expected_hash FROM h)=(SELECT actual_hash FROM h)
                        AND (SELECT expected_hash FROM h)=(SELECT stored_hash FROM h)
                        AND (SELECT COUNT(*) FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM ctx) AND evidence_code LIKE 'M1_3_POS_%' AND status='FAIL')=1
                        AND (SELECT COUNT(*) FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM ctx) AND evidence_code='M1_3_POS_36_RELATIONSHIP_DIFFERENTIATION' AND status='FAIL')=1
                   THEN 'PASS' ELSE 'FAIL' END status
  ) SELECT status INTO v_status FROM x;
  IF v_status<>'PASS' THEN
    RAISE EXCEPTION 'M1.3 v0.2R1 recovery precheck failed. Do not alter or regenerate application rows.';
  END IF;
END $$;
