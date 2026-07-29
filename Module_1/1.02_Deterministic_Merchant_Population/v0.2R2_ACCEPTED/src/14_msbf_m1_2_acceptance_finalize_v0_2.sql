/* ============================================================================
MSBF M1.2 Acceptance Finalization
Version : v0.2R2
Purpose : Accept the deterministic merchant population only after all 36
          positive checks and 3 negative controls pass.
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
  v_failed integer;
  v_mismatch bigint;
  v_expected_hash text;
  v_actual_hash text;
  v_stored_hash text;
  v_downstream bigint;
  v_review_version integer;
  v_result text;
  v_observed text;
BEGIN
  SELECT run_id,run_status INTO STRICT v_run_id,v_run_status
  FROM msbf_ctl.run_registry
  WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1 FOR UPDATE;

  IF v_run_status='M1_2_ACCEPTED' AND EXISTS (
    SELECT 1 FROM msbf_ctl.acceptance_gate_result WHERE run_id=v_run_id AND gate_id='M1_2_POPULATION' AND result_status='PASS'
  ) THEN
    RAISE NOTICE 'M1.2 is already accepted; no duplicate acceptance inserted.';
    RETURN;
  END IF;
  IF v_run_status<>'M1_2_VALIDATED' THEN
    RAISE EXCEPTION 'M1.2 finalization requires run_status=M1_2_VALIDATED; observed %',v_run_status;
  END IF;

  SELECT COUNT(*) FILTER (WHERE evidence_code LIKE 'M1_2_POS_%'),
         COUNT(*) FILTER (WHERE evidence_code LIKE 'M1_2_POS_%' AND status='PASS'),
         COUNT(*) FILTER (WHERE evidence_code LIKE 'M1_2_NEG_%'),
         COUNT(*) FILTER (WHERE evidence_code LIKE 'M1_2_NEG_%' AND status='PASS'),
         COUNT(*) FILTER (WHERE (evidence_code LIKE 'M1_2_POS_%' OR evidence_code LIKE 'M1_2_NEG_%') AND status='FAIL')
    INTO v_positive_count,v_positive_pass,v_negative_count,v_negative_pass,v_failed
  FROM msbf_ctl.run_evidence WHERE run_id=v_run_id;

  SELECT COUNT(*) INTO v_mismatch
  FROM msbf_m1.m1_2_expected_entity_snapshot(v_run_id) e
  FULL JOIN msbf_m1.m1_2_actual_entity_snapshot(v_run_id) a USING(entity_type,entity_key)
  WHERE e.row_hash IS DISTINCT FROM a.row_hash;

  SELECT md5(string_agg(entity_type||'|'||entity_key||'|'||row_hash,'||' ORDER BY entity_type,entity_key))
    INTO v_expected_hash FROM msbf_m1.m1_2_expected_entity_snapshot(v_run_id);
  SELECT md5(string_agg(entity_type||'|'||entity_key||'|'||row_hash,'||' ORDER BY entity_type,entity_key))
    INTO v_actual_hash FROM msbf_m1.m1_2_actual_entity_snapshot(v_run_id);
  SELECT population_hash INTO v_stored_hash FROM msbf_m1.population_registry
   WHERE population_id=(SELECT population_id FROM msbf_ctl.run_registry WHERE run_id=v_run_id);

  SELECT
      (SELECT COUNT(*) FROM msbf_m1.merchant_application WHERE created_by_run_id=v_run_id)
    + (SELECT COUNT(*) FROM msbf_m1.merchant_pos_daily_base WHERE generated_by_run_id=v_run_id)
    + (SELECT COUNT(*) FROM msbf_m1.merchant_pos_daily_scenario WHERE generated_by_run_id=v_run_id)
    + (SELECT COUNT(*) FROM msbf_m1.merchant_deposit_daily_base WHERE generated_by_run_id=v_run_id)
    + (SELECT COUNT(*) FROM msbf_m1.merchant_deposit_daily_scenario WHERE generated_by_run_id=v_run_id)
    + (SELECT COUNT(*) FROM msbf_m1.merchant_feature_snapshot WHERE module1_run_id=v_run_id)
    + (SELECT COUNT(*) FROM msbf_m1.merchant_risk_snapshot WHERE module1_run_id=v_run_id)
    + (SELECT COUNT(*) FROM msbf_m1.ead_path_snapshot WHERE module1_run_id=v_run_id)
    + (SELECT COUNT(*) FROM msbf_m1.module1_latest WHERE module1_run_id=v_run_id)
    + (SELECT COUNT(*) FROM msbf_m1.module1_archive WHERE module1_run_id=v_run_id)
  INTO v_downstream;

  v_result:=CASE WHEN v_positive_count=36 AND v_positive_pass=36
                       AND v_negative_count=3 AND v_negative_pass=3
                       AND v_failed=0 AND v_mismatch=0
                       AND v_expected_hash=v_actual_hash AND v_actual_hash=v_stored_hash
                       AND v_downstream=0
                  THEN 'PASS' ELSE 'FAIL' END;

  v_observed:=jsonb_build_object(
    'positive_checks',v_positive_count,'positive_passes',v_positive_pass,
    'negative_controls',v_negative_count,'negative_passes',v_negative_pass,
    'failed_evidence',v_failed,'row_level_mismatches',v_mismatch,
    'expected_population_hash',v_expected_hash,'actual_population_hash',v_actual_hash,
    'stored_population_hash',v_stored_hash,'downstream_rows',v_downstream,
    'g1_parameter_hash',(SELECT parameter_snapshot_hash FROM msbf_ctl.run_registry WHERE run_id=v_run_id),
    'g1_profile_hash',(SELECT profile_snapshot_hash FROM msbf_ctl.run_registry WHERE run_id=v_run_id),
    'g1_source_hash',(SELECT source_snapshot_hash FROM msbf_ctl.run_registry WHERE run_id=v_run_id)
  )::text;

  SELECT COALESCE(MAX(review_version),0)+1 INTO v_review_version
  FROM msbf_ctl.acceptance_gate_result WHERE run_id=v_run_id AND gate_id='M1_2_POPULATION';

  INSERT INTO msbf_ctl.acceptance_gate_result(
    run_id,gate_id,review_version,result_status,observed_value,threshold_value,
    finding,residual_limitation,reviewer_role
  ) VALUES(
    v_run_id,'M1_2_POPULATION',v_review_version,v_result,v_observed,
    '36/36 positive checks PASS; 3/3 negative controls PASS; 0 row mismatches; population hashes equal; 0 downstream rows.',
    CASE WHEN v_result='PASS' THEN 'M1.2 deterministic merchant population accepted.' ELSE 'M1.2 acceptance criteria were not fully satisfied.' END,
    'Synthetic demonstration population only. No production underwriting, legal, regulatory, pricing, PD, LGD, capital, accounting, fair-lending, or security certification is established.',
    'Project Owner / Validation'
  );

  INSERT INTO msbf_ctl.run_evidence(run_id,evidence_code,segment_key,metric_name,metric_value_text,unit_code,status,interpretation)
  VALUES(v_run_id,'M1_2_ACCEPTANCE_SUMMARY','PORTFOLIO','M1.2 population acceptance',v_observed,'JSON_TEXT',v_result,
         CASE WHEN v_result='PASS' THEN 'M1.2 accepted; M1.3 application generation is authorized.' ELSE 'M1.2 failed; subsequent generation remains prohibited.' END)
  ON CONFLICT (run_id,evidence_code,segment_key) DO UPDATE SET metric_name=EXCLUDED.metric_name,metric_value_numeric=NULL,metric_value_text=EXCLUDED.metric_value_text,unit_code=EXCLUDED.unit_code,status=EXCLUDED.status,threshold_value_numeric=NULL,interpretation=EXCLUDED.interpretation,created_at=clock_timestamp();

  IF v_result='PASS' THEN
    UPDATE msbf_ctl.run_registry SET run_status='M1_2_ACCEPTED',notes='M1.2 deterministic merchant population accepted. Authorized for M1.3 application generation.' WHERE run_id=v_run_id;
    UPDATE msbf_m1.population_registry SET population_status='M1_2_ACCEPTED' WHERE population_id=(SELECT population_id FROM msbf_ctl.run_registry WHERE run_id=v_run_id);
  ELSE
    UPDATE msbf_ctl.run_registry SET run_status='M1_2_FAILED',notes='M1.2 acceptance failed; subsequent analytical generation prohibited.' WHERE run_id=v_run_id;
  END IF;
END
$$;

COMMIT;

SELECT r.run_id,r.run_code,r.run_version,r.run_status,p.population_id,p.population_status,p.population_hash,
       g.gate_id,g.review_version,g.result_status,g.reviewed_at,g.finding,g.residual_limitation,
       r.parameter_snapshot_hash,r.profile_snapshot_hash,r.source_snapshot_hash
FROM msbf_ctl.run_registry r
JOIN msbf_m1.population_registry p ON p.population_id=r.population_id
LEFT JOIN LATERAL (
 SELECT * FROM msbf_ctl.acceptance_gate_result x WHERE x.run_id=r.run_id AND x.gate_id='M1_2_POPULATION' ORDER BY review_version DESC LIMIT 1
) g ON true
WHERE r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1;
