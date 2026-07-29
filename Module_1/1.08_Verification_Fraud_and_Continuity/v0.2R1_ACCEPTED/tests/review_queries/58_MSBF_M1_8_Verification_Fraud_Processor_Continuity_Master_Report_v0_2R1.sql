/* MSBF M1.8 — One-Row Master Acceptance Report v0.2R1 */
WITH r AS (
 SELECT run_id,run_status,population_id,as_of_date,parameter_snapshot_hash,profile_snapshot_hash,source_snapshot_hash
 FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
), gate AS (
 SELECT * FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM r)
 AND gate_id='M1_8_VERIFICATION_FRAUD_CONTINUITY' ORDER BY review_version DESC LIMIT 1
), ev AS (
 SELECT count(*) FILTER(WHERE evidence_code LIKE 'M1_8_POS_%') positive_checks,
        count(*) FILTER(WHERE evidence_code LIKE 'M1_8_POS_%' AND status='PASS') positive_passes,
        count(*) FILTER(WHERE evidence_code LIKE 'M1_8_NEG_%') negative_controls,
        count(*) FILTER(WHERE evidence_code LIKE 'M1_8_NEG_%' AND status='PASS') negative_passes,
        count(*) FILTER(WHERE evidence_code LIKE 'M1_8_%' AND status='FAIL') failed_evidence,
        max(metric_value_text) FILTER(WHERE evidence_code='M1_8_VERIFICATION_SET_HASH') verification_hash,
        max(metric_value_text) FILTER(WHERE evidence_code='M1_8_SUMMARY_SET_HASH') summary_hash,
        max(metric_value_text) FILTER(WHERE evidence_code='M1_8_COMBINED_SET_HASH') combined_hash
 FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM r)
), policy AS (
 SELECT profile_payload->>'methodology_version' methodology_version,
        coalesce((profile_payload->>'stress_continuity_tier_floor_to_baseline')::boolean,false) stress_floor_enabled
 FROM msbf_ctl.policy_profile
 WHERE profile_code='M1_8_VERIFICATION_FRAUD_CONTINUITY' AND profile_version=1
), actual AS MATERIALIZED (
 SELECT * FROM msbf_m1.m1_8_actual_entity_snapshot((SELECT run_id FROM r))
), hashes AS (
 SELECT count(*) canonical_rows,
        md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key) FILTER (WHERE entity_key LIKE 'VERIFICATION|%')) verification_hash,
        md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key) FILTER (WHERE entity_key LIKE 'SUMMARY|%')) summary_hash,
        md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) combined_hash
 FROM actual
), rows AS (
 SELECT
  (SELECT count(*) FROM msbf_m1.verification_result WHERE created_by_run_id=(SELECT run_id FROM r)) verification_rows,
  (SELECT count(*) FROM msbf_m1.application_verification_fraud_snapshot WHERE module1_run_id=(SELECT run_id FROM r)) summary_rows,
  (SELECT count(DISTINCT merchant_application_id) FROM msbf_m1.verification_result WHERE created_by_run_id=(SELECT run_id FROM r)) applications,
  (SELECT count(DISTINCT check_code) FROM msbf_m1.verification_result WHERE created_by_run_id=(SELECT run_id FROM r)) check_codes,
  (SELECT count(*) FROM msbf_m1.application_verification_fraud_snapshot WHERE module1_run_id=(SELECT run_id FROM r) AND verification_disposition='CLEAR') clear_apps,
  (SELECT count(*) FROM msbf_m1.application_verification_fraud_snapshot WHERE module1_run_id=(SELECT run_id FROM r) AND verification_disposition='REVIEW') review_apps,
  (SELECT count(*) FROM msbf_m1.application_verification_fraud_snapshot WHERE module1_run_id=(SELECT run_id FROM r) AND verification_disposition='STOP') stop_apps,
  (SELECT count(*) FROM msbf_m1.application_verification_fraud_snapshot WHERE module1_run_id=(SELECT run_id FROM r) AND verification_disposition='INSUFFICIENT_EVIDENCE') insufficient_apps,
  (SELECT round(avg(fraud_score),6) FROM msbf_m1.application_verification_fraud_snapshot WHERE module1_run_id=(SELECT run_id FROM r)) avg_fraud_score,
  (SELECT count(*) FROM msbf_m1.application_verification_fraud_snapshot
    WHERE module1_run_id=(SELECT run_id FROM r)
      AND stress_processor_continuity_risk_tier<processor_continuity_risk_tier) stress_tier_improvements,
  (SELECT count(*) FROM msbf_ctl.profile_resolution_error WHERE run_id=(SELECT run_id FROM r) AND severity='BLOCKING') blocking_errors
)
SELECT r.run_id,r.run_status,r.population_id,r.as_of_date,
       gate.review_version AS m1_8_review_version,gate.result_status AS m1_8_gate_status,
       ev.positive_checks,ev.positive_passes,ev.negative_controls,ev.negative_passes,ev.failed_evidence,
       policy.methodology_version,policy.stress_floor_enabled,rows.*,hashes.canonical_rows,ev.verification_hash AS stored_verification_hash,hashes.verification_hash AS actual_verification_hash,
       ev.summary_hash AS stored_summary_hash,hashes.summary_hash AS actual_summary_hash,
       ev.combined_hash AS stored_combined_hash,hashes.combined_hash AS actual_combined_hash,
       CASE WHEN r.run_status='M1_8_ACCEPTED' AND gate.result_status='PASS'
                  AND ev.positive_checks=60 AND ev.positive_passes=60
                  AND ev.negative_controls=6 AND ev.negative_passes=6 AND ev.failed_evidence=0
                  AND rows.verification_rows=4500 AND rows.summary_rows=750 AND rows.applications=750 AND rows.check_codes=6
                  AND hashes.canonical_rows=5250
                  AND ev.verification_hash=hashes.verification_hash
                  AND ev.summary_hash=hashes.summary_hash
                  AND ev.combined_hash=hashes.combined_hash
                  AND rows.blocking_errors=0 AND rows.stress_tier_improvements=0
                  AND policy.stress_floor_enabled AND policy.methodology_version='M1_8_METHOD_V1_1'
             THEN 'PASS' ELSE 'FAIL' END AS overall_m1_8_status
FROM r CROSS JOIN gate CROSS JOIN ev CROSS JOIN policy CROSS JOIN hashes CROSS JOIN rows;
