/* ============================================================================
MSBF M1.16 Acceptance Finalizer
Program : 121_msbf_m1_16_acceptance_finalize_v0_2R1.sql
Version : v0.2R3
Purpose : Reconcile positive and negative controls, physical cardinalities,
          acquisition cost identities, latest/archive reproduction, integrated
          consumption, hashes, stage boundaries, and companion lifecycle.
Output  : One filterable acceptance result preserved after COMMIT.
============================================================================ */
BEGIN;
SET LOCAL work_mem='96MB';
SET LOCAL jit=off;
SET LOCAL statement_timeout='20min';

DROP TABLE IF EXISTS _m1_16_acceptance;
CREATE TEMP TABLE _m1_16_acceptance ON COMMIT PRESERVE ROWS AS
WITH r AS (
 SELECT run_id,run_status FROM msbf_ctl.run_registry
 WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
), pos AS (
 SELECT count(*) checks,count(*) FILTER(WHERE status='PASS') passes,count(*) FILTER(WHERE status='FAIL') failures
 FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM r) AND evidence_code LIKE 'M1_16_POS_%'
), neg AS (
 SELECT count(*) controls,count(*) FILTER(WHERE status='PASS') passes,count(*) FILTER(WHERE status='FAIL') failures
 FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM r) AND evidence_code LIKE 'M1_16_NEG_%'
), c AS (
 SELECT * FROM msbf_ctl.m1_16_acquisition_contract_registry WHERE module1_run_id=(SELECT run_id FROM r)
), rows AS (
 SELECT
  (SELECT count(*) FROM msbf_m1.acquisition_source_profile WHERE module1_run_id=(SELECT run_id FROM r)) source_rows,
  (SELECT count(*) FROM msbf_m1.acquisition_marketing_campaign WHERE module1_run_id=(SELECT run_id FROM r)) campaign_rows,
  (SELECT count(*) FROM msbf_m1.acquisition_campaign_funnel_stage WHERE module1_run_id=(SELECT run_id FROM r)) funnel_rows,
  (SELECT count(*) FROM msbf_m1.acquisition_cost_ledger WHERE module1_run_id=(SELECT run_id FROM r)) ledger_rows,
  (SELECT count(*) FROM msbf_m1.application_acquisition_touchpoint WHERE module1_run_id=(SELECT run_id FROM r)) touch_rows,
  (SELECT count(*) FROM msbf_m1.application_acquisition_attribution_snapshot WHERE module1_run_id=(SELECT run_id FROM r)) attribution_rows,
  (SELECT count(*) FROM msbf_m1.application_acquisition_cost_snapshot WHERE module1_run_id=(SELECT run_id FROM r)) cost_rows,
  (SELECT count(*) FROM msbf_m1.application_acquisition_cost_component_value WHERE module1_run_id=(SELECT run_id FROM r)) component_rows,
  (SELECT count(*) FROM msbf_m1.application_acquisition_contract_latest WHERE module1_run_id=(SELECT run_id FROM r)) latest_rows,
  (SELECT count(*) FROM msbf_m1.application_acquisition_contract_archive WHERE module1_run_id=(SELECT run_id FROM r)) archive_rows,
  (SELECT count(*) FROM msbf_m1.v_m1_16_module1_integrated_consumption WHERE module1_run_id=(SELECT run_id FROM r)) integrated_rows,
  (SELECT count(*) FROM pg_trigger WHERE tgname='trg_m1_16_archive_immutable' AND tgenabled<>'D') archive_trigger_count,
  (SELECT count(*) FROM msbf_ctl.profile_resolution_error WHERE run_id=(SELECT run_id FROM r) AND severity='BLOCKING') blocking_errors
), mismatch AS (
 SELECT
  (SELECT count(*) FROM msbf_m1.acquisition_source_profile x WHERE x.module1_run_id=(SELECT run_id FROM r) AND x.row_hash IS DISTINCT FROM msbf_m1.m1_16_hash_jsonb(to_jsonb(x)-'row_hash'-'created_at'))
 +(SELECT count(*) FROM msbf_m1.acquisition_marketing_campaign x WHERE x.module1_run_id=(SELECT run_id FROM r) AND x.row_hash IS DISTINCT FROM msbf_m1.m1_16_hash_jsonb(to_jsonb(x)-'row_hash'-'created_at'))
 +(SELECT count(*) FROM msbf_m1.acquisition_campaign_funnel_stage x WHERE x.module1_run_id=(SELECT run_id FROM r) AND x.row_hash IS DISTINCT FROM msbf_m1.m1_16_hash_jsonb(to_jsonb(x)-'row_hash'-'created_at'))
 +(SELECT count(*) FROM msbf_m1.acquisition_cost_ledger x WHERE x.module1_run_id=(SELECT run_id FROM r) AND x.row_hash IS DISTINCT FROM msbf_m1.m1_16_hash_jsonb(to_jsonb(x)-'row_hash'-'created_at'))
 +(SELECT count(*) FROM msbf_m1.application_acquisition_touchpoint x WHERE x.module1_run_id=(SELECT run_id FROM r) AND x.row_hash IS DISTINCT FROM msbf_m1.m1_16_hash_jsonb(to_jsonb(x)-'row_hash'-'created_at'))
 +(SELECT count(*) FROM msbf_m1.application_acquisition_attribution_snapshot x WHERE x.module1_run_id=(SELECT run_id FROM r) AND x.row_hash IS DISTINCT FROM msbf_m1.m1_16_hash_jsonb(to_jsonb(x)-'row_hash'-'created_at'))
 +(SELECT count(*) FROM msbf_m1.application_acquisition_cost_snapshot x WHERE x.module1_run_id=(SELECT run_id FROM r) AND x.row_hash IS DISTINCT FROM msbf_m1.m1_16_hash_jsonb(to_jsonb(x)-'row_hash'-'created_at'))
 +(SELECT count(*) FROM msbf_m1.application_acquisition_cost_component_value x WHERE x.module1_run_id=(SELECT run_id FROM r) AND x.row_hash IS DISTINCT FROM msbf_m1.m1_16_hash_jsonb(to_jsonb(x)-'row_hash'-'created_at'))
 +(SELECT count(*) FROM msbf_m1.application_acquisition_contract_latest x WHERE x.module1_run_id=(SELECT run_id FROM r) AND x.contract_row_hash IS DISTINCT FROM msbf_m1.m1_16_hash_jsonb(to_jsonb(x)-'contract_row_hash'-'created_at')) physical_hash_mismatches,
  (SELECT count(*) FROM msbf_m1.application_acquisition_contract_archive a
   JOIN msbf_m1.application_acquisition_contract_latest l ON l.module1_run_id=a.module1_run_id AND l.merchant_application_id=a.merchant_application_id
   WHERE a.module1_run_id=(SELECT run_id FROM r) AND (a.contract_row_hash<>l.contract_row_hash OR a.contract_payload IS DISTINCT FROM to_jsonb(l)-'created_at')) archive_mismatches,
  (SELECT count(*) FROM msbf_m1.application_acquisition_cost_snapshot WHERE module1_run_id=(SELECT run_id FROM r) AND acquisition_contract_evidence_status='BLOCKED' AND enhanced_total_acquisition_cost_if_booked IS NOT NULL) blocked_total_violations,
  (SELECT count(*) FROM (
    SELECT merchant_application_id FROM msbf_m1.v_m1_16_module1_integrated_consumption WHERE module1_run_id=(SELECT run_id FROM r)
    GROUP BY merchant_application_id HAVING count(*)<>2
   ) q) integrated_pair_violations
), entities AS (

SELECT ('SOURCE|'||acquisition_source_code)::text AS entity_key,row_hash::text AS row_hash
FROM msbf_m1.acquisition_source_profile WHERE module1_run_id=(SELECT run_id FROM r)
UNION ALL SELECT ('CAMPAIGN|'||acquisition_campaign_id)::text,row_hash::text
FROM msbf_m1.acquisition_marketing_campaign WHERE module1_run_id=(SELECT run_id FROM r)
UNION ALL SELECT ('FUNNEL|'||acquisition_campaign_id||'|'||stage_code)::text,row_hash::text
FROM msbf_m1.acquisition_campaign_funnel_stage WHERE module1_run_id=(SELECT run_id FROM r)
UNION ALL SELECT ('LEDGER|'||acquisition_cost_line_id)::text,row_hash::text
FROM msbf_m1.acquisition_cost_ledger WHERE module1_run_id=(SELECT run_id FROM r)
UNION ALL SELECT ('TOUCH|'||merchant_application_id||'|'||touchpoint_sequence::text)::text,row_hash::text
FROM msbf_m1.application_acquisition_touchpoint WHERE module1_run_id=(SELECT run_id FROM r)
UNION ALL SELECT ('ATTRIBUTION|'||merchant_application_id)::text,row_hash::text
FROM msbf_m1.application_acquisition_attribution_snapshot WHERE module1_run_id=(SELECT run_id FROM r)
UNION ALL SELECT ('COST|'||merchant_application_id)::text,row_hash::text
FROM msbf_m1.application_acquisition_cost_snapshot WHERE module1_run_id=(SELECT run_id FROM r)
UNION ALL SELECT ('COMPONENT|'||merchant_application_id||'|'||cost_component_code)::text,row_hash::text
FROM msbf_m1.application_acquisition_cost_component_value WHERE module1_run_id=(SELECT run_id FROM r)
UNION ALL SELECT ('LATEST|'||merchant_application_id)::text,contract_row_hash::text
FROM msbf_m1.application_acquisition_contract_latest WHERE module1_run_id=(SELECT run_id FROM r)
UNION ALL SELECT ('ARCHIVE|'||contract_version::text||'|'||merchant_application_id)::text,contract_row_hash::text
FROM msbf_m1.application_acquisition_contract_archive WHERE module1_run_id=(SELECT run_id FROM r)
UNION ALL SELECT ('CONTRACT|'||contract_code||'|'||contract_version::text||'|'||module1_run_id::text)::text,contract_row_hash::text
FROM msbf_ctl.m1_16_acquisition_contract_registry WHERE module1_run_id=(SELECT run_id FROM r)

), physical AS (
 SELECT count(*) canonical_entities,md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) combined_hash FROM entities
), stored AS (
 SELECT max(metric_value_text) FILTER(WHERE evidence_code='M1_16_COMBINED_SET_HASH') combined_hash,
        (max(metric_value_numeric) FILTER(WHERE evidence_code='M1_16_CANONICAL_MISMATCH_COUNT'))::bigint mismatches
 FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM r)
)
SELECT r.run_id,r.run_status,pos.checks positive_checks,pos.passes positive_passes,pos.failures positive_failures,
 neg.controls negative_controls,neg.passes negative_passes,neg.failures negative_failures,
 rows.source_rows,rows.campaign_rows,rows.funnel_rows,rows.ledger_rows,rows.touch_rows,
 rows.attribution_rows,rows.cost_rows,rows.component_rows,rows.latest_rows,rows.archive_rows,
 rows.integrated_rows,rows.archive_trigger_count,rows.blocking_errors,
 mismatch.physical_hash_mismatches,mismatch.archive_mismatches,
 mismatch.blocked_total_violations,mismatch.integrated_pair_violations,
 physical.canonical_entities,physical.combined_hash AS recomputed_combined_hash,
 stored.combined_hash AS stored_combined_hash,stored.mismatches AS stored_mismatches,
 c.contract_code,c.contract_version,c.schema_version,c.methodology_version,c.contract_status,
 c.source_m1_14_combined_hash,c.source_m1_15_combined_hash,c.combined_set_hash AS registry_combined_hash,
 CASE WHEN r.run_status='M1_16_VALIDATED'
       AND pos.checks=112 AND pos.passes=112 AND pos.failures=0
       AND neg.controls=20 AND neg.passes=20 AND neg.failures=0
       AND rows.source_rows=18 AND rows.campaign_rows=20
       AND rows.funnel_rows=120 AND rows.ledger_rows=40
       AND rows.touch_rows=1075 AND rows.attribution_rows=750
       AND rows.cost_rows=750 AND rows.component_rows=9000
       AND rows.latest_rows=750 AND rows.archive_rows=750
       AND rows.integrated_rows=1500 AND rows.archive_trigger_count=1 AND rows.blocking_errors=0
       AND mismatch.physical_hash_mismatches=0 AND mismatch.archive_mismatches=0
       AND mismatch.blocked_total_violations=0 AND mismatch.integrated_pair_violations=0
       AND physical.canonical_entities=13274 AND stored.mismatches=0
       AND physical.combined_hash=stored.combined_hash AND physical.combined_hash=c.combined_set_hash
       AND c.contract_code='M1_ACQUISITION_CONSUMPTION' AND c.contract_version=1
       AND c.schema_version='M1_ACQUISITION_SCHEMA_V1' AND c.methodology_version='M1_16_METHOD_V1'
       AND c.contract_status='VALIDATED'
      THEN 'PASS' ELSE 'FAIL' END acceptance_status
FROM r CROSS JOIN pos CROSS JOIN neg CROSS JOIN c CROSS JOIN rows CROSS JOIN mismatch CROSS JOIN physical CROSS JOIN stored;

INSERT INTO msbf_ctl.acceptance_gate_result(
 run_id,gate_id,review_version,result_status,observed_value,threshold_value,
 finding,residual_limitation,reviewer_role,reviewed_at
)
SELECT run_id,'M1_16_ACQUISITION_MARKETING_COST_FOUNDATIONS',coalesce((SELECT max(review_version)+1 FROM msbf_ctl.acceptance_gate_result WHERE run_id=a.run_id AND gate_id='M1_16_ACQUISITION_MARKETING_COST_FOUNDATIONS'),1),
 acceptance_status,
 format('positive=%s/%s|negative=%s/%s|source=%s|campaign=%s|funnel=%s|ledger=%s|touch=%s|attribution=%s|cost=%s|component=%s|latest=%s|archive=%s|canonical=%s|mismatches=%s',
 positive_passes,positive_checks,negative_passes,negative_controls,source_rows,campaign_rows,funnel_rows,ledger_rows,touch_rows,attribution_rows,cost_rows,component_rows,latest_rows,archive_rows,canonical_entities,stored_mismatches),
 '112/112 positive; 20/20 negative; 18 source; 20 campaigns; 120 funnel; 40 ledger; 1,075 touch; 750 attribution/cost/latest/archive; 9,000 components; 13,274 canonical; zero mismatches',
 CASE WHEN acceptance_status='PASS' THEN 'M1.16 acquisition source, attribution, cost, companion contract, archive, and integrated consumption accepted.' ELSE 'M1.16 acceptance requirements were not fully satisfied.' END,
 'Synthetic acquisition evidence only; no production attribution, funded CAC, causal lift, pricing, approval, offer, or legal conclusion.',
 'Independent Validation',clock_timestamp()
FROM _m1_16_acceptance a;

INSERT INTO msbf_ctl.run_evidence(
 run_id,evidence_code,segment_key,metric_name,metric_value_text,unit_code,status,interpretation
)
SELECT run_id,'M1_16_ACCEPTANCE_SUMMARY','PORTFOLIO','M1.16 acceptance summary',
 format('positive=%s/%s|negative=%s/%s|latest=%s|archive=%s|canonical=%s|hash=%s',positive_passes,positive_checks,negative_passes,negative_controls,latest_rows,archive_rows,canonical_entities,registry_combined_hash),
 'TEXT',acceptance_status,'Formal M1.16 acquisition-contract acceptance summary.'
FROM _m1_16_acceptance
ON CONFLICT(run_id,evidence_code,segment_key) DO UPDATE SET
 metric_value_text=EXCLUDED.metric_value_text,status=EXCLUDED.status,
 interpretation=EXCLUDED.interpretation,created_at=clock_timestamp();

UPDATE msbf_ctl.m1_16_acquisition_contract_registry c
SET contract_status=CASE WHEN a.acceptance_status='PASS' THEN 'ACCEPTED' ELSE 'VALIDATED' END,
    accepted_at=CASE WHEN a.acceptance_status='PASS' THEN clock_timestamp() ELSE c.accepted_at END,
    validated_at=coalesce(c.validated_at,clock_timestamp())
FROM _m1_16_acceptance a WHERE c.module1_run_id=a.run_id;

UPDATE msbf_ctl.run_registry r
SET run_status=CASE WHEN a.acceptance_status='PASS' THEN 'M1_16_ACCEPTED' ELSE 'M1_16_FAILED' END,
    completed_at=CASE WHEN a.acceptance_status='PASS' THEN clock_timestamp() ELSE NULL END,
    notes=concat_ws(E'
',r.notes,CASE WHEN a.acceptance_status='PASS' THEN 'M1.16 acquisition foundations accepted.' ELSE 'M1.16 acceptance failed.' END)
FROM _m1_16_acceptance a WHERE r.run_id=a.run_id;

COMMIT;
SELECT * FROM _m1_16_acceptance;
