/* ============================================================================
MSBF M1.8 — Detailed Evidence Report v0.2
Produces 17 result sets. Result sets 15 and 17 must be empty after acceptance.
============================================================================ */
BEGIN; SET LOCAL work_mem='64MB'; SET LOCAL jit=off; SET LOCAL statement_timeout='15min';
CREATE TEMP TABLE _m1_8_dr_ctx ON COMMIT DROP AS
SELECT r.run_id,r.run_status,r.population_id,r.as_of_date,
       pp.profile_payload->>'methodology_version' AS methodology_version,
       coalesce((pp.profile_payload->>'stress_continuity_tier_floor_to_baseline')::boolean,false) AS stress_floor_enabled
FROM msbf_ctl.run_registry r
JOIN msbf_ctl.policy_profile pp
  ON pp.profile_code='M1_8_VERIFICATION_FRAUD_CONTINUITY' AND pp.profile_version=1
WHERE r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1;
CREATE TEMP TABLE _m1_8_dr_checks ON COMMIT DROP AS
SELECT v.*,s.source_code,s.availability_status,s.quality_status,s.data_confidence_score
FROM msbf_m1.verification_result v
LEFT JOIN msbf_m1.source_snapshot s ON s.source_snapshot_id=v.source_snapshot_id AND s.module1_run_id=v.created_by_run_id
WHERE v.created_by_run_id=(SELECT run_id FROM _m1_8_dr_ctx);
CREATE INDEX ON _m1_8_dr_checks(merchant_application_id,check_code);
CREATE TEMP TABLE _m1_8_dr_summary ON COMMIT DROP AS
SELECT * FROM msbf_m1.application_verification_fraud_snapshot WHERE module1_run_id=(SELECT run_id FROM _m1_8_dr_ctx);
CREATE UNIQUE INDEX ON _m1_8_dr_summary(merchant_application_id);
CREATE TEMP TABLE _m1_8_dr_actual ON COMMIT DROP AS
SELECT * FROM msbf_m1.m1_8_actual_entity_snapshot((SELECT run_id FROM _m1_8_dr_ctx));
CREATE UNIQUE INDEX ON _m1_8_dr_actual(entity_key);
ANALYZE _m1_8_dr_checks;ANALYZE _m1_8_dr_summary;ANALYZE _m1_8_dr_actual;

-- 01 Run and Acceptance State
SELECT r.*,g.review_version,g.result_status AS gate_status,g.finding,g.residual_limitation,g.reviewed_at
FROM _m1_8_dr_ctx r LEFT JOIN LATERAL(SELECT * FROM msbf_ctl.acceptance_gate_result x WHERE x.run_id=r.run_id AND x.gate_id='M1_8_VERIFICATION_FRAUD_CONTINUITY' ORDER BY review_version DESC LIMIT 1) g ON true;
-- 02 Entity and Stage-Boundary Row Counts
SELECT
 (SELECT count(*) FROM _m1_8_dr_checks) verification_rows,
 (SELECT count(*) FROM _m1_8_dr_summary) summary_rows,
 (SELECT count(DISTINCT merchant_application_id) FROM _m1_8_dr_checks) applications,
 (SELECT count(DISTINCT check_code) FROM _m1_8_dr_checks) check_codes,
 (SELECT count(*) FROM _m1_8_dr_actual) canonical_entities,
 (SELECT count(*) FROM msbf_m1.application_obligation_snapshot WHERE created_by_run_id=(SELECT run_id FROM _m1_8_dr_ctx)) obligation_rows,
 (SELECT count(*) FROM msbf_m1.collateral_availability_snapshot WHERE created_by_run_id=(SELECT run_id FROM _m1_8_dr_ctx)) collateral_rows,
 (SELECT count(*) FROM msbf_m1.application_business_credit_snapshot WHERE created_by_run_id=(SELECT run_id FROM _m1_8_dr_ctx)) business_credit_rows,
 (SELECT count(*) FROM msbf_m1.merchant_feature_snapshot WHERE module1_run_id=(SELECT run_id FROM _m1_8_dr_ctx)) feature_rows,
 (SELECT count(*) FROM msbf_m1.merchant_risk_snapshot WHERE module1_run_id=(SELECT run_id FROM _m1_8_dr_ctx)) risk_rows;
-- 03 Verification Check Result Summary
SELECT check_code,result_status,count(*) applications,round(avg(coalesce(risk_tier,0)),4) avg_risk_tier,
       count(*) FILTER(WHERE hard_stop_recommended_flag) hard_stops,
       count(*) FILTER(WHERE manual_review_recommended_flag) manual_reviews
FROM _m1_8_dr_checks GROUP BY check_code,result_status ORDER BY check_code,result_status;
-- 04 Source Availability and Quality Diagnostics
SELECT source_code,availability_status,quality_status,count(*) check_rows,round(avg(data_confidence_score),6) avg_confidence
FROM _m1_8_dr_checks GROUP BY source_code,availability_status,quality_status ORDER BY source_code,availability_status,quality_status;
-- 05 Hard-Stop and Manual-Review Diagnostics
SELECT check_code,count(*) total_rows,
       count(*) FILTER(WHERE hard_stop_recommended_flag) hard_stop_rows,
       count(*) FILTER(WHERE manual_review_recommended_flag) review_rows,
       count(*) FILTER(WHERE result_status='UNAVAILABLE') unavailable_rows,
       count(*) FILTER(WHERE result_status='FAIL') failed_rows
FROM _m1_8_dr_checks GROUP BY check_code ORDER BY check_code;
-- 06 Fraud Score and Tier Diagnostics
SELECT fraud_risk_tier,count(*) applications,round(min(fraud_score),6) min_score,round(avg(fraud_score),6) avg_score,
       round(max(fraud_score),6) max_score,count(*) FILTER(WHERE verification_disposition='STOP') stop_apps,
       count(*) FILTER(WHERE verification_disposition='REVIEW') review_apps
FROM _m1_8_dr_summary GROUP BY fraud_risk_tier ORDER BY fraud_risk_tier;
-- 07 Fraud Reason-Flag Diagnostics
SELECT flag_name,count(*) FILTER(WHERE flag_value) flagged_applications
FROM _m1_8_dr_summary s
CROSS JOIN LATERAL jsonb_each_text(s.fraud_reason_flags) f(flag_name,flag_text)
CROSS JOIN LATERAL (SELECT flag_text::boolean flag_value) x
GROUP BY flag_name ORDER BY flag_name;
-- 08 Baseline Processor-Continuity Diagnostics
SELECT processor_continuity_status,processor_continuity_risk_tier,count(*) applications,
       round(avg(processor_active_day_rate),6) avg_active_rate,round(avg(processor_degraded_day_rate),6) avg_degraded_rate,
       round(avg(processor_outage_day_rate),6) avg_outage_rate,round(avg(recent_processor_outage_day_rate),6) avg_recent_outage_rate,
       round(avg(data_connection_gap_day_rate),6) avg_gap_rate
FROM _m1_8_dr_summary GROUP BY processor_continuity_status,processor_continuity_risk_tier
ORDER BY processor_continuity_risk_tier;
-- 09 Stress Processor-Continuity Diagnostics
SELECT stress_processor_continuity_status,stress_processor_continuity_risk_tier,count(*) applications,
       round(avg(stress_processor_degraded_day_rate),6) avg_degraded_rate,
       round(avg(stress_processor_outage_day_rate),6) avg_outage_rate,
       round(avg(stress_data_connection_gap_day_rate),6) avg_gap_rate
FROM _m1_8_dr_summary GROUP BY stress_processor_continuity_status,stress_processor_continuity_risk_tier
ORDER BY stress_processor_continuity_risk_tier;
-- 10 Continuity Stress Migration
SELECT processor_continuity_risk_tier baseline_tier,stress_processor_continuity_risk_tier stress_tier,
       stress_processor_continuity_risk_tier-processor_continuity_risk_tier AS tier_delta,
       count(*) applications,count(*) FILTER(WHERE continuity_stress_worsening_flag) worsening_apps
FROM _m1_8_dr_summary
GROUP BY processor_continuity_risk_tier,stress_processor_continuity_risk_tier
ORDER BY baseline_tier,stress_tier;
-- 11 Disposition and Reason Diagnostics
SELECT verification_disposition,primary_reason_code,count(*) applications,
       round(avg(fraud_score),6) avg_fraud_score,round(avg(processor_outage_day_rate),6) avg_outage_rate,
       count(*) FILTER(WHERE hard_stop_recommended_flag) hard_stops,count(*) FILTER(WHERE manual_review_recommended_flag) manual_reviews
FROM _m1_8_dr_summary GROUP BY verification_disposition,primary_reason_code
ORDER BY verification_disposition,applications DESC,primary_reason_code;
-- 12 Partner/Channel Diagnostics
SELECT coalesce(pc.channel_type,'UNASSIGNED') channel_type,count(*) applications,
       round(avg(s.fraud_score),6) avg_fraud_score,round(avg(s.processor_continuity_risk_tier),4) avg_continuity_tier,
       count(*) FILTER(WHERE s.verification_disposition='CLEAR') clear_apps,
       count(*) FILTER(WHERE s.verification_disposition='REVIEW') review_apps,
       count(*) FILTER(WHERE s.verification_disposition IN ('STOP','INSUFFICIENT_EVIDENCE')) stop_or_insufficient_apps
FROM _m1_8_dr_summary s JOIN msbf_m1.merchant_application a USING(merchant_application_id)
LEFT JOIN msbf_m1.partner_channel pc ON pc.partner_channel_id=a.partner_channel_id
GROUP BY coalesce(pc.channel_type,'UNASSIGNED') ORDER BY channel_type;
-- 13 Industry Diagnostics
SELECT i.industry_code,count(*) applications,round(avg(s.fraud_score),6) avg_fraud_score,
       round(avg(s.processor_continuity_risk_tier),4) avg_baseline_continuity_tier,
       round(avg(s.stress_processor_continuity_risk_tier),4) avg_stress_continuity_tier,
       count(*) FILTER(WHERE s.continuity_stress_worsening_flag) worsening_apps,
       count(*) FILTER(WHERE s.verification_disposition='CLEAR') clear_apps,
       count(*) FILTER(WHERE s.verification_disposition<>'CLEAR') nonclear_apps
FROM _m1_8_dr_summary s JOIN msbf_m1.merchant_application a USING(merchant_application_id)
JOIN msbf_m1.merchant_industry_assignment i ON i.merchant_id=a.merchant_id AND i.assignment_type='PRIMARY'
GROUP BY i.industry_code ORDER BY i.industry_code;
-- 14 Sample Application Profiles
SELECT s.merchant_application_id,a.merchant_id,i.industry_code,s.verification_disposition,s.primary_reason_code,
       s.fraud_score,s.fraud_risk_tier,s.processor_continuity_status,s.processor_continuity_risk_tier,
       s.stress_processor_continuity_status,s.stress_processor_continuity_risk_tier,s.continuity_stress_worsening_flag,
       s.verification_pass_count,s.verification_review_count,s.verification_fail_count,s.verification_unavailable_count,
       s.secondary_reason_codes,s.fraud_reason_flags
FROM _m1_8_dr_summary s JOIN msbf_m1.merchant_application a USING(merchant_application_id)
JOIN msbf_m1.merchant_industry_assignment i ON i.merchant_id=a.merchant_id AND i.assignment_type='PRIMARY'
ORDER BY CASE s.verification_disposition WHEN 'STOP' THEN 1 WHEN 'INSUFFICIENT_EVIDENCE' THEN 2 WHEN 'REVIEW' THEN 3 ELSE 4 END,
         s.fraud_score DESC,s.merchant_application_id LIMIT 40;
-- 15 Row-Level Deterministic Mismatches (must be empty)
SELECT e.entity_key,e.row_hash stored_row_hash,a.row_hash recomputed_row_hash
FROM (
 SELECT 'VERIFICATION|'||merchant_application_id||'|'||check_code entity_key,row_hash FROM _m1_8_dr_checks
 UNION ALL SELECT 'SUMMARY|'||merchant_application_id,row_hash FROM _m1_8_dr_summary
) e FULL JOIN _m1_8_dr_actual a USING(entity_key)
WHERE e.row_hash IS DISTINCT FROM a.row_hash ORDER BY entity_key;
-- 16 M1.8 Evidence
SELECT evidence_code,segment_key,metric_name,metric_value_numeric,metric_value_text,unit_code,status,threshold_value_numeric,interpretation,created_at
FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM _m1_8_dr_ctx) AND evidence_code LIKE 'M1_8_%'
ORDER BY evidence_code,segment_key;
-- 17 Blocking Resolution Errors (must be empty)
SELECT profile_domain,scope_key,error_code,severity,error_message,created_at
FROM msbf_ctl.profile_resolution_error WHERE run_id=(SELECT run_id FROM _m1_8_dr_ctx) AND severity='BLOCKING'
ORDER BY created_at,error_code;
COMMIT;
