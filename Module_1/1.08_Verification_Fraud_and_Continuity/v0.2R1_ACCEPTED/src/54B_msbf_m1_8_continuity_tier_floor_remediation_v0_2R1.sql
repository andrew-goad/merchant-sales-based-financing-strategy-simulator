/* ============================================================================
MSBF M1.8 v0.2R1 — Processor-Continuity Stress-Tier Remediation
Purpose : Correct the 18 application summaries where independently classified
          stress continuity tiers improved relative to baseline. The governed
          adverse-scenario method now floors the stress tier at the baseline
          tier while preserving all observed baseline and stress rate evidence.
Scope   : Updates the M1.8 policy profile, 750 summary row hashes, affected
          summary tiers/statuses, governed hashes/evidence, and run status.
          The 4,500 atomic verification rows are not changed.
============================================================================ */
BEGIN;
SET LOCAL work_mem='64MB';
SET LOCAL jit=off;
SET LOCAL lock_timeout='10s';
SET LOCAL statement_timeout='10min';

DO $guard$
DECLARE
  v_run_id bigint; v_status text; v_pos integer; v_pass integer; v_fail integer;
  v_failed_codes text; v_verification bigint; v_summary bigint; v_improvements bigint;
  v_gate_rows bigint; v_blocking bigint;
BEGIN
  SELECT run_id,run_status INTO STRICT v_run_id,v_status
  FROM msbf_ctl.run_registry
  WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
  FOR UPDATE;

  SELECT count(*),count(*) FILTER(WHERE status='PASS'),count(*) FILTER(WHERE status='FAIL'),
         string_agg(evidence_code,',' ORDER BY evidence_code) FILTER(WHERE status='FAIL')
    INTO v_pos,v_pass,v_fail,v_failed_codes
  FROM msbf_ctl.run_evidence
  WHERE run_id=v_run_id AND evidence_code LIKE 'M1_8_POS_%';

  SELECT count(*) INTO v_verification
  FROM msbf_m1.verification_result WHERE created_by_run_id=v_run_id;
  SELECT count(*) INTO v_summary
  FROM msbf_m1.application_verification_fraud_snapshot WHERE module1_run_id=v_run_id;
  SELECT count(*) INTO v_improvements
  FROM msbf_m1.application_verification_fraud_snapshot
  WHERE module1_run_id=v_run_id
    AND stress_processor_continuity_risk_tier<processor_continuity_risk_tier;
  SELECT count(*) INTO v_gate_rows
  FROM msbf_ctl.acceptance_gate_result
  WHERE run_id=v_run_id AND gate_id='M1_8_VERIFICATION_FRAUD_CONTINUITY';
  SELECT count(*) INTO v_blocking
  FROM msbf_ctl.profile_resolution_error WHERE run_id=v_run_id AND severity='BLOCKING';

  IF v_status<>'M1_8_FAILED'
     OR v_pos<>60 OR v_pass<>59 OR v_fail<>1
     OR v_failed_codes<>'M1_8_POS_48_STRESS_NONIMPROVEMENT'
     OR v_verification<>4500 OR v_summary<>750 OR v_improvements<>18
     OR v_gate_rows<>0 OR v_blocking<>0 THEN
    RAISE EXCEPTION 'M1.8 R1 remediation preconditions failed: status %, positive %/% (fail %; codes %), verification %, summary %, improvements %, gate %, blocking %.',
      v_status,v_pass,v_pos,v_fail,v_failed_codes,v_verification,v_summary,v_improvements,v_gate_rows,v_blocking;
  END IF;
END;
$guard$;

-- Preserve the original validation finding before revised validation replaces
-- the M1_8_POS_* evidence family.
INSERT INTO msbf_ctl.run_evidence(
  run_id,evidence_code,segment_key,metric_name,metric_value_numeric,
  unit_code,status,threshold_value_numeric,interpretation,created_at
)
SELECT run_id,'M1_8_R1_ORIGINAL_VALIDATION_FAILURE','PORTFOLIO',
       'Original stress-tier improvements identified',18,'APPLICATIONS','PASS',0,
       'The original positive validation correctly identified 18 stress continuity tiers below their baseline tiers. The generated rate evidence remained intact; the governed adverse-scenario tier method required a non-improvement floor.',clock_timestamp()
FROM msbf_ctl.run_registry
WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
ON CONFLICT(run_id,evidence_code,segment_key) DO UPDATE SET
  metric_value_numeric=EXCLUDED.metric_value_numeric,metric_value_text=NULL,
  unit_code=EXCLUDED.unit_code,status=EXCLUDED.status,
  threshold_value_numeric=EXCLUDED.threshold_value_numeric,
  interpretation=EXCLUDED.interpretation,created_at=clock_timestamp();

-- Governed methodology revision. Observed stress metrics remain unchanged;
-- only the adverse-scenario risk-tier interpretation is floored at baseline.
UPDATE msbf_ctl.policy_profile
SET profile_payload=jsonb_set(
      jsonb_set(profile_payload,'{methodology_version}',to_jsonb('M1_8_METHOD_V1_1'::text),true),
      '{stress_continuity_tier_floor_to_baseline}','true'::jsonb,true
    ),
    change_reason=concat_ws(' | ',nullif(change_reason,''),
      'v0.2R1: Stress processor-continuity tier cannot improve relative to baseline under an adverse scenario.')
WHERE profile_code='M1_8_VERIFICATION_FRAUD_CONTINUITY' AND profile_version=1;

-- Replace the configuration guard so future clean generation and all negative
-- controls require the revised policy payload.
CREATE OR REPLACE FUNCTION msbf_m1.m1_8_assert_configuration(p_run_id bigint)
RETURNS void
LANGUAGE plpgsql
AS $fn$
DECLARE
    v_as_of_date date;
    v_parameter_rows integer;
    v_parameter_names integer;
    v_missing_boolean integer;
    v_missing_numeric integer;
    v_check_rows integer;
    v_check_set text;
    v_policy_rows integer;
    v_policy_status text;
    v_policy jsonb;
    v_source_rows integer;
    v_source_apps integer;
    v_source_families integer;
    v_t2 numeric; v_t3 numeric; v_t4 numeric; v_t5 numeric;
BEGIN
    SELECT as_of_date INTO STRICT v_as_of_date
    FROM msbf_ctl.run_registry WHERE run_id=p_run_id;

    SELECT count(*),count(DISTINCT parameter_name),
           count(*) FILTER (
               WHERE parameter_name IN ('verification_hard_stop_check','verification_review_check')
                 AND (NOT (resolved_value?'value_boolean') OR resolved_value->>'value_boolean' IS NULL)
           ),
           count(*) FILTER (
               WHERE parameter_name NOT IN ('verification_hard_stop_check','verification_review_check')
                 AND (NOT (resolved_value?'value_numeric') OR resolved_value->>'value_numeric' IS NULL)
           )
    INTO v_parameter_rows,v_parameter_names,v_missing_boolean,v_missing_numeric
    FROM msbf_ctl.run_parameter_snapshot
    WHERE run_id=p_run_id
      AND (
          (scope_key='GLOBAL' AND parameter_name IN (
              'fraud_base_probability','bank_account_mismatch_fraud_points',
              'processor_mismatch_fraud_points','identity_conflict_fraud_points',
              'abnormal_refund_fraud_points','abnormal_chargeback_fraud_points',
              'fraud_tier_2_threshold','fraud_tier_3_threshold',
              'fraud_tier_4_threshold','fraud_tier_5_threshold'
          ))
          OR (scope_key LIKE 'VERIFICATION_CHECK:%'
              AND parameter_name IN ('verification_hard_stop_check','verification_review_check'))
      );

    IF v_parameter_rows<>22 OR v_parameter_names<>12 OR v_missing_boolean<>0 OR v_missing_numeric<>0 THEN
        RAISE EXCEPTION 'M1.8 requires 22 typed parameter rows across 12 names; rows %, names %, missing boolean %, missing numeric %.',
            v_parameter_rows,v_parameter_names,v_missing_boolean,v_missing_numeric;
    END IF;

    SELECT
        max((resolved_value->>'value_numeric')::numeric) FILTER (WHERE parameter_name='fraud_tier_2_threshold'),
        max((resolved_value->>'value_numeric')::numeric) FILTER (WHERE parameter_name='fraud_tier_3_threshold'),
        max((resolved_value->>'value_numeric')::numeric) FILTER (WHERE parameter_name='fraud_tier_4_threshold'),
        max((resolved_value->>'value_numeric')::numeric) FILTER (WHERE parameter_name='fraud_tier_5_threshold')
    INTO v_t2,v_t3,v_t4,v_t5
    FROM msbf_ctl.run_parameter_snapshot
    WHERE run_id=p_run_id AND scope_key='GLOBAL';

    IF NOT (v_t2<v_t3 AND v_t3<v_t4 AND v_t4<v_t5 AND v_t2>=0 AND v_t5<=100) THEN
        RAISE EXCEPTION 'M1.8 fraud thresholds must be strictly increasing within [0,100].';
    END IF;

    SELECT count(*),string_agg(check_code,',' ORDER BY check_code)
    INTO v_check_rows,v_check_set
    FROM msbf_ref.verification_check_code WHERE active_flag;

    IF v_check_rows<>6 OR v_check_set<>'BANK_ACCOUNT_MATCH,BENEFICIAL_OWNER,FRAUD_SCREEN,KYB_ENTITY,PROCESSOR_MATCH,SANCTIONS' THEN
        RAISE EXCEPTION 'M1.8 requires six active verification checks; rows %, set %.',v_check_rows,v_check_set;
    END IF;

    SELECT count(*),max(status),(jsonb_agg(profile_payload))->0
    INTO v_policy_rows,v_policy_status,v_policy
    FROM msbf_ctl.policy_profile
    WHERE profile_code='M1_8_VERIFICATION_FRAUD_CONTINUITY'
      AND profile_version=1
      AND effective_start_date<=v_as_of_date
      AND (effective_end_date IS NULL OR effective_end_date>v_as_of_date);

    IF v_policy_rows<>1 OR v_policy_status<>'APPROVED' OR NOT coalesce((v_policy->>'generation_enabled')::boolean,false) THEN
        RAISE EXCEPTION 'M1.8 requires one approved, effective, enabled methodology policy profile.';
    END IF;

    IF v_policy->>'methodology_version'<>'M1_8_METHOD_V1_1'
       OR NOT coalesce((v_policy->>'stress_continuity_tier_floor_to_baseline')::boolean,false)
       OR (SELECT count(*) FROM jsonb_object_keys(v_policy))<>31
       OR (v_policy->>'recent_window_days')::integer<1
       OR (v_policy->>'manual_review_fraud_tier')::integer NOT BETWEEN 1 AND 5
       OR (v_policy->>'hard_stop_fraud_tier')::integer NOT BETWEEN 1 AND 5
       OR (v_policy->>'manual_review_continuity_tier')::integer NOT BETWEEN 1 AND 5
       OR (v_policy->>'hard_stop_continuity_tier')::integer NOT BETWEEN 1 AND 5
       OR (v_policy->>'manual_review_fraud_tier')::integer>(v_policy->>'hard_stop_fraud_tier')::integer
       OR (v_policy->>'manual_review_continuity_tier')::integer>(v_policy->>'hard_stop_continuity_tier')::integer
       OR NOT (
           (v_policy->>'continuity_tier_2_degraded_rate')::numeric < (v_policy->>'continuity_tier_3_degraded_rate')::numeric
           AND (v_policy->>'continuity_tier_3_degraded_rate')::numeric < (v_policy->>'continuity_tier_4_degraded_rate')::numeric
           AND (v_policy->>'continuity_tier_2_outage_rate')::numeric < (v_policy->>'continuity_tier_3_outage_rate')::numeric
           AND (v_policy->>'continuity_tier_3_outage_rate')::numeric < (v_policy->>'continuity_tier_4_outage_rate')::numeric
           AND (v_policy->>'continuity_tier_2_connection_gap_rate')::numeric < (v_policy->>'continuity_tier_3_connection_gap_rate')::numeric
           AND (v_policy->>'continuity_tier_3_connection_gap_rate')::numeric < (v_policy->>'continuity_tier_4_connection_gap_rate')::numeric
       )
    THEN
        RAISE EXCEPTION 'M1.8 methodology policy payload is incomplete or non-monotonic.';
    END IF;

    SELECT count(*),count(DISTINCT merchant_application_id),count(DISTINCT source_code)
    INTO v_source_rows,v_source_apps,v_source_families
    FROM msbf_m1.source_snapshot
    WHERE module1_run_id=p_run_id;

    IF v_source_rows<>5250 OR v_source_apps<>750 OR v_source_families<>7 THEN
        RAISE EXCEPTION 'M1.8 requires accepted M1.7 source evidence: rows %, applications %, source families %.',
            v_source_rows,v_source_apps,v_source_families;
    END IF;
END;
$fn$;



CREATE TEMP TABLE _m1_8_r1_corrected ON COMMIT DROP AS
SELECT
  s.merchant_application_id,
  greatest(s.processor_continuity_risk_tier,s.stress_processor_continuity_risk_tier)::smallint AS corrected_stress_tier,
  CASE greatest(s.processor_continuity_risk_tier,s.stress_processor_continuity_risk_tier)
    WHEN 1 THEN 'STABLE' WHEN 2 THEN 'MONITORED' WHEN 3 THEN 'WATCH'
    WHEN 4 THEN 'DISRUPTED' ELSE 'UNAVAILABLE' END AS corrected_stress_status,
  (greatest(s.processor_continuity_risk_tier,s.stress_processor_continuity_risk_tier)
     >s.processor_continuity_risk_tier) AS corrected_worsening_flag,
  (s.stress_processor_continuity_risk_tier<s.processor_continuity_risk_tier) AS floor_applied_flag
FROM msbf_m1.application_verification_fraud_snapshot s
WHERE s.module1_run_id=(
  SELECT run_id FROM msbf_ctl.run_registry
  WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
);
CREATE UNIQUE INDEX ON _m1_8_r1_corrected(merchant_application_id);
ANALYZE _m1_8_r1_corrected;

UPDATE msbf_m1.application_verification_fraud_snapshot s
SET stress_processor_continuity_status=c.corrected_stress_status,
    stress_processor_continuity_risk_tier=c.corrected_stress_tier,
    continuity_stress_worsening_flag=c.corrected_worsening_flag,
    row_hash=msbf_m1.m1_8_summary_row_hash(
      s.module1_run_id,s.merchant_application_id,s.as_of_timestamp,
      s.verification_source_snapshot_id,s.pos_source_snapshot_id,s.deposit_source_snapshot_id,
      s.verification_pass_count,s.verification_review_count,s.verification_fail_count,
      s.verification_unavailable_count,s.critical_fail_count,s.fraud_score,s.fraud_risk_tier,
      s.processor_continuity_status,s.processor_continuity_risk_tier,
      c.corrected_stress_status,c.corrected_stress_tier,
      s.processor_active_day_rate,s.processor_degraded_day_rate,s.processor_outage_day_rate,
      s.recent_processor_outage_day_rate,s.data_connection_gap_day_rate,
      s.stress_processor_degraded_day_rate,s.stress_processor_outage_day_rate,
      s.stress_data_connection_gap_day_rate,c.corrected_worsening_flag,
      s.hard_stop_recommended_flag,s.manual_review_recommended_flag,
      s.verification_disposition,s.primary_reason_code,s.secondary_reason_codes,
      s.fraud_reason_flags,s.created_by_run_id
    )
FROM _m1_8_r1_corrected c
WHERE s.module1_run_id=(
  SELECT run_id FROM msbf_ctl.run_registry
  WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
)
AND s.merchant_application_id=c.merchant_application_id;
ANALYZE msbf_m1.application_verification_fraud_snapshot;

CREATE TEMP TABLE _m1_8_r1_actual ON COMMIT DROP AS
SELECT * FROM msbf_m1.m1_8_actual_entity_snapshot((
  SELECT run_id FROM msbf_ctl.run_registry
  WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
));
CREATE UNIQUE INDEX ON _m1_8_r1_actual(entity_key);
ANALYZE _m1_8_r1_actual;

DO $reconcile$
DECLARE
  v_run_id bigint; v_floor_rows bigint; v_remaining bigint;
  v_ver_mismatch bigint; v_sum_mismatch bigint; v_canonical bigint;
  v_ver_hash text; v_sum_hash text; v_combined_hash text; v_policy_hash text;
BEGIN
  SELECT run_id INTO STRICT v_run_id FROM msbf_ctl.run_registry
  WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1 FOR UPDATE;

  SELECT count(*) FILTER(WHERE floor_applied_flag) INTO v_floor_rows FROM _m1_8_r1_corrected;
  SELECT count(*) INTO v_remaining
  FROM msbf_m1.application_verification_fraud_snapshot
  WHERE module1_run_id=v_run_id
    AND stress_processor_continuity_risk_tier<processor_continuity_risk_tier;

  SELECT count(*) INTO v_ver_mismatch
  FROM msbf_m1.verification_result v
  JOIN msbf_m1.m1_8_actual_verification_snapshot(v_run_id) a
    ON a.entity_key=v.merchant_application_id||'|'||v.check_code
  WHERE v.created_by_run_id=v_run_id AND v.row_hash IS DISTINCT FROM a.row_hash;

  SELECT count(*) INTO v_sum_mismatch
  FROM msbf_m1.application_verification_fraud_snapshot s
  JOIN msbf_m1.m1_8_actual_summary_snapshot(v_run_id) a
    ON a.entity_key=s.merchant_application_id
  WHERE s.module1_run_id=v_run_id AND s.row_hash IS DISTINCT FROM a.row_hash;

  SELECT count(*),
         md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)
           FILTER(WHERE entity_key LIKE 'VERIFICATION|%')),
         md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)
           FILTER(WHERE entity_key LIKE 'SUMMARY|%')),
         md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key))
    INTO v_canonical,v_ver_hash,v_sum_hash,v_combined_hash
  FROM _m1_8_r1_actual;

  SELECT md5(profile_payload::text) INTO STRICT v_policy_hash
  FROM msbf_ctl.policy_profile
  WHERE profile_code='M1_8_VERIFICATION_FRAUD_CONTINUITY' AND profile_version=1;

  IF v_floor_rows<>18 OR v_remaining<>0 OR v_ver_mismatch<>0 OR v_sum_mismatch<>0 OR v_canonical<>5250 THEN
    RAISE EXCEPTION 'M1.8 R1 reconciliation failed: floor %, remaining %, verification mismatch %, summary mismatch %, canonical %.',
      v_floor_rows,v_remaining,v_ver_mismatch,v_sum_mismatch,v_canonical;
  END IF;

  INSERT INTO msbf_ctl.run_evidence(
    run_id,evidence_code,segment_key,metric_name,metric_value_text,unit_code,status,interpretation
  ) VALUES
    (v_run_id,'M1_8_POLICY_PROFILE_HASH','PORTFOLIO','M1.8 policy profile hash',v_policy_hash,'HASH','PASS','v0.2R1 governed methodology profile hash.'),
    (v_run_id,'M1_8_VERIFICATION_SET_HASH','PORTFOLIO','M1.8 verification set hash',v_ver_hash,'HASH','PASS','Canonical hash across the unchanged 4,500 atomic verification entities.'),
    (v_run_id,'M1_8_SUMMARY_SET_HASH','PORTFOLIO','M1.8 summary set hash',v_sum_hash,'HASH','PASS','Canonical hash across 750 application summaries after the governed stress-tier floor.'),
    (v_run_id,'M1_8_COMBINED_SET_HASH','PORTFOLIO','M1.8 combined set hash',v_combined_hash,'HASH','PASS','Canonical hash across all 5,250 M1.8 entities after v0.2R1 remediation.'),
    (v_run_id,'M1_8_GENERATION_SPEC','PORTFOLIO','M1.8 generation specification','M1_8_METHOD_V1_1|750 applications|6 checks|baseline+stress continuity|stress tier floor to baseline|independent fraud tier','TEXT','PASS','Governed synthetic M1.8 generation specification after v0.2R1 correction.'),
    (v_run_id,'M1_8_GENERATION_SUMMARY','PORTFOLIO','M1.8 generation summary',format('verification=4500; summary=750; canonical=5250; stress_floor_rows=%s; mismatches=0',v_floor_rows),'TEXT','PASS','M1.8 persisted generation and controlled v0.2R1 remediation reconcile exactly.'),
    (v_run_id,'M1_8_R1_CONTINUITY_TIER_FLOOR','PORTFOLIO','Stress continuity non-improvement floor applied',v_floor_rows::text,'APPLICATIONS','PASS','Eighteen independently classified stressed tiers were floored at their baseline tiers; observed continuity rates were not altered.')
  ON CONFLICT(run_id,evidence_code,segment_key) DO UPDATE SET
    metric_value_numeric=NULL,metric_value_text=EXCLUDED.metric_value_text,
    unit_code=EXCLUDED.unit_code,status=EXCLUDED.status,threshold_value_numeric=NULL,
    interpretation=EXCLUDED.interpretation,created_at=clock_timestamp();

  UPDATE msbf_ctl.run_registry
  SET run_status='M1_8_GENERATED',completed_at=NULL,
      notes=coalesce(notes,'')||format(E'
M1.8 v0.2R1 continuity-tier floor applied to %s summaries; all hashes rebuilt.',v_floor_rows)
  WHERE run_id=v_run_id;
END;
$reconcile$;

COMMIT;

WITH r AS (
 SELECT run_id,run_status FROM msbf_ctl.run_registry
 WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
), actual AS MATERIALIZED (
 SELECT * FROM msbf_m1.m1_8_actual_entity_snapshot((SELECT run_id FROM r))
), h AS (
 SELECT count(*) canonical_rows,
        md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)
          FILTER(WHERE entity_key LIKE 'VERIFICATION|%')) verification_hash,
        md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)
          FILTER(WHERE entity_key LIKE 'SUMMARY|%')) summary_hash,
        md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) combined_hash
 FROM actual
)
SELECT r.run_id,r.run_status,
       (SELECT count(*) FROM msbf_m1.verification_result WHERE created_by_run_id=r.run_id) verification_rows,
       (SELECT count(*) FROM msbf_m1.application_verification_fraud_snapshot WHERE module1_run_id=r.run_id) summary_rows,
       (SELECT count(*) FROM msbf_m1.application_verification_fraud_snapshot
         WHERE module1_run_id=r.run_id AND stress_processor_continuity_risk_tier<processor_continuity_risk_tier) remaining_improvements,
       18 AS corrected_summary_rows,h.canonical_rows,h.verification_hash,h.summary_hash,h.combined_hash,
       CASE WHEN r.run_status='M1_8_GENERATED'
                  AND h.canonical_rows=5250
                  AND (SELECT count(*) FROM msbf_m1.application_verification_fraud_snapshot
                       WHERE module1_run_id=r.run_id AND stress_processor_continuity_risk_tier<processor_continuity_risk_tier)=0
             THEN 'PASS' ELSE 'FAIL' END AS remediation_status
FROM r CROSS JOIN h;
