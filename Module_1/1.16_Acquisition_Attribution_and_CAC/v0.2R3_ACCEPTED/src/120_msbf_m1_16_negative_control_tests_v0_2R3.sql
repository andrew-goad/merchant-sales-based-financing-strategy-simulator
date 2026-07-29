/* ============================================================================
MSBF M1.16 Negative Controls
Program : 120_msbf_m1_16_negative_control_tests_v0_2R1.sql
Version : v0.2R3
Purpose : Prove fail-closed rejection of invalid source, campaign, funnel,
          touchpoint, attribution, cost, overlap, archive, upstream-contract,
          scenario-invariance, lifecycle, cardinality, run-status, rerun, and prohibited-output states.
Output  : One filterable 20-row result set.
Safety  : Every mutation occurs in an exception subtransaction and is rolled
          back automatically. Accepted and generated records remain unchanged.
============================================================================ */
BEGIN;
SET LOCAL work_mem='64MB';
SET LOCAL jit=off;
SET LOCAL statement_timeout='20min';

DROP TABLE IF EXISTS _m1_16_negative_run;
CREATE TEMP TABLE _m1_16_negative_run ON COMMIT PRESERVE ROWS AS
SELECT run_id,run_status
FROM msbf_ctl.run_registry
WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1;

DO $run_guard$
BEGIN
 IF NOT EXISTS(SELECT 1 FROM _m1_16_negative_run WHERE run_status='M1_16_VALIDATED') THEN
   RAISE EXCEPTION 'M1.16 negative controls require M1_16_VALIDATED.';
 END IF;
END;
$run_guard$;

DROP TABLE IF EXISTS _m1_16_negative;
CREATE TEMP TABLE _m1_16_negative(
 evidence_code text PRIMARY KEY,test_name text NOT NULL,expected_result text NOT NULL,
 observed_result text NOT NULL,status text NOT NULL,interpretation text NOT NULL
) ON COMMIT PRESERVE ROWS;

CREATE OR REPLACE FUNCTION pg_temp.m1_16_record_negative(
 p_code text,p_name text,p_expected text,p_rejected boolean,p_interpretation text
) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
 INSERT INTO _m1_16_negative VALUES(
  p_code,p_name,p_expected,
  CASE WHEN p_rejected THEN 'REJECTED_AS_EXPECTED' ELSE 'NOT_REJECTED' END,
  CASE WHEN p_rejected THEN 'PASS' ELSE 'FAIL' END,
  p_interpretation
 );
END; $$;

CREATE OR REPLACE FUNCTION pg_temp.m1_16_assert_current_integrity(p_run_id bigint)
RETURNS void LANGUAGE plpgsql AS $$
DECLARE v_bad bigint;v_m115_latest_hash text;v_registry_hash text;
BEGIN
 SELECT count(*) INTO v_bad FROM msbf_m1.acquisition_source_profile s
 LEFT JOIN msbf_m1.partner_channel p ON p.partner_channel_id=s.accepted_partner_channel_id
 WHERE s.module1_run_id=p_run_id
   AND (NOT s.approved_source_flag OR s.governance_status<>'APPROVED'
        OR s.normalized_source_family<>s.source_classification
        OR p.partner_channel_id IS NULL OR p.channel_type<>s.accepted_channel_type);
 IF v_bad<>0 THEN RAISE EXCEPTION 'source integrity'; END IF;

 SELECT count(*) INTO v_bad FROM msbf_m1.acquisition_marketing_campaign
 WHERE module1_run_id=p_run_id AND (campaign_status<>'ACTIVE' OR approval_status<>'APPROVED');
 IF v_bad<>0 THEN RAISE EXCEPTION 'campaign integrity'; END IF;

 SELECT count(*) INTO v_bad
 FROM msbf_m1.acquisition_campaign_funnel_stage f
 JOIN (
   SELECT module1_run_id,acquisition_campaign_id,stage_order,stage_count,
          lag(stage_count) OVER(PARTITION BY module1_run_id,acquisition_campaign_id ORDER BY stage_order) prior_count
   FROM msbf_m1.acquisition_campaign_funnel_stage WHERE module1_run_id=p_run_id
 ) x ON x.module1_run_id=f.module1_run_id AND x.acquisition_campaign_id=f.acquisition_campaign_id AND x.stage_order=f.stage_order
 WHERE f.module1_run_id=p_run_id AND x.prior_count IS NOT NULL AND f.stage_count>x.prior_count;
 IF v_bad<>0 THEN RAISE EXCEPTION 'funnel integrity'; END IF;

 SELECT count(*) INTO v_bad FROM msbf_m1.application_acquisition_touchpoint t
 JOIN msbf_m1.merchant_application a ON a.merchant_application_id=t.merchant_application_id
 WHERE t.module1_run_id=p_run_id AND t.touchpoint_timestamp>a.application_date::timestamptz+interval '23 hours 59 minutes 59 seconds';
 IF v_bad<>0 THEN RAISE EXCEPTION 'touchpoint timing'; END IF;

 SELECT count(*) INTO v_bad FROM (
   SELECT merchant_application_id,count(*) n,count(*) FILTER(WHERE primary_attribution_flag) primary_n,
          sum(attribution_weight) weight_sum
   FROM msbf_m1.application_acquisition_touchpoint WHERE module1_run_id=p_run_id
   GROUP BY merchant_application_id
 ) q WHERE n>3 OR primary_n<>1 OR weight_sum<>1.000000;
 IF v_bad<>0 THEN RAISE EXCEPTION 'touchpoint attribution'; END IF;

 SELECT count(*) INTO v_bad
 FROM msbf_m1.acquisition_cost_ledger l
 JOIN msbf_m1.acquisition_source_profile s
   ON s.module1_run_id=l.module1_run_id AND s.acquisition_source_code=l.acquisition_source_code
 WHERE l.module1_run_id=p_run_id
   AND (l.quantity<0 OR l.gross_cost_amount<0
        OR NOT (l.cost_basis_code=ANY(s.permitted_cost_basis_codes))
        OR NOT (l.cost_timing_code=ANY(s.permitted_cost_timing_codes)));
 IF v_bad<>0 THEN RAISE EXCEPTION 'ledger integrity'; END IF;

 SELECT count(*) INTO v_bad FROM (
   SELECT l.acquisition_campaign_id,l.gross_cost_amount,
          sum(cv.component_amount) FILTER(WHERE d.component_role_code='ATOMIC_COST') AS allocated_amount
   FROM msbf_m1.acquisition_cost_ledger l
   JOIN msbf_m1.application_acquisition_attribution_snapshot a
     ON a.module1_run_id=l.module1_run_id AND a.primary_campaign_id=l.acquisition_campaign_id
   JOIN msbf_m1.application_acquisition_cost_component_value cv
     ON cv.module1_run_id=a.module1_run_id AND cv.merchant_application_id=a.merchant_application_id
    AND cv.cost_component_code=l.cost_component_code
   JOIN msbf_ref.acquisition_cost_component d ON d.cost_component_code=cv.cost_component_code
   WHERE l.module1_run_id=p_run_id AND NOT l.conditional_flag
   GROUP BY l.acquisition_campaign_id,l.gross_cost_amount
 ) q WHERE allocated_amount IS DISTINCT FROM gross_cost_amount;
 IF v_bad<>0 THEN RAISE EXCEPTION 'allocation integrity'; END IF;

 SELECT count(*) INTO v_bad FROM msbf_m1.application_acquisition_cost_snapshot c
 WHERE c.module1_run_id=p_run_id
   AND ((c.identified_legacy_overlap_amount IS NOT NULL
         AND (c.identified_legacy_overlap_amount>c.accepted_m1_14_acquisition_cost_amount
              OR c.identified_legacy_overlap_amount>c.mapped_detailed_cost_potentially_represented))
     OR (c.acquisition_contract_evidence_status='BLOCKED'
         AND (c.identified_legacy_overlap_amount IS NOT NULL
              OR c.incremental_acquisition_cost_beyond_m1_14 IS NOT NULL
              OR c.enhanced_total_acquisition_cost_if_booked IS NOT NULL)));
 IF v_bad<>0 THEN RAISE EXCEPTION 'overlap/evidence integrity'; END IF;

 SELECT count(*) INTO v_bad
 FROM msbf_m1.application_acquisition_cost_component_value cv
 JOIN msbf_ref.acquisition_legacy_overlap_policy p
   ON p.partner_channel_id=(SELECT accepted_partner_channel_id FROM msbf_m1.application_acquisition_cost_snapshot c WHERE c.module1_run_id=cv.module1_run_id AND c.merchant_application_id=cv.merchant_application_id)
  AND p.cost_component_code=cv.cost_component_code
 WHERE cv.module1_run_id=p_run_id
   AND ((p.overlap_class IN('FULLY_INCLUDED_IN_M1_14','POTENTIALLY_INCLUDED_IN_M1_14')) <> cv.included_in_m1_14_flag)
   AND cv.component_role_code='ATOMIC_COST';
 IF v_bad<>0 THEN RAISE EXCEPTION 'double-count mapping'; END IF;

 SELECT count(*) INTO v_bad FROM msbf_m1.v_m1_16_module1_integrated_consumption v
 WHERE v.module1_run_id=p_run_id AND v.partner_channel_id<>v.accepted_partner_channel_id;
 IF v_bad<>0 THEN RAISE EXCEPTION 'scenario/source divergence'; END IF;

 SELECT md5(string_agg('LATEST|'||scenario_id||'|'||merchant_application_id||'|'||contract_row_hash,'||' ORDER BY scenario_id,merchant_application_id))
 INTO v_m115_latest_hash
 FROM msbf_m1.application_module1_latest WHERE module1_run_id=p_run_id;
 SELECT latest_set_hash INTO STRICT v_registry_hash
 FROM msbf_ctl.m1_15_consumption_contract_registry
 WHERE module1_run_id=p_run_id AND contract_status='ACCEPTED';
 IF v_m115_latest_hash<>v_registry_hash THEN RAISE EXCEPTION 'accepted M1.15 mutation'; END IF;

 IF (SELECT run_status FROM msbf_ctl.run_registry WHERE run_id=p_run_id)<>'M1_16_VALIDATED' THEN
   RAISE EXCEPTION 'run status drift';
 END IF;
END; $$;

DO $negative_tests$
DECLARE
 v_run bigint=(SELECT run_id FROM _m1_16_negative_run);
 v_rejected boolean;v_second boolean;
BEGIN
 -- 01 Unapproved acquisition source
 v_rejected:=false;
 BEGIN
  UPDATE msbf_m1.acquisition_source_profile SET governance_status='DRAFT'
  WHERE module1_run_id=v_run AND acquisition_source_code=(SELECT min(acquisition_source_code) FROM msbf_m1.acquisition_source_profile WHERE module1_run_id=v_run);
  PERFORM pg_temp.m1_16_assert_current_integrity(v_run);
 EXCEPTION WHEN OTHERS THEN v_rejected:=true; END;
 PERFORM pg_temp.m1_16_record_negative('M1_16_NEG_01_UNAPPROVED_SOURCE','Unapproved source','REJECTED',v_rejected,'Unapproved source profiles fail the governed integrity contract.');

 -- 02 Invalid source-to-parent-channel mapping
 v_rejected:=false;
 BEGIN
  UPDATE msbf_m1.acquisition_source_profile SET accepted_partner_channel_id='CH_BANK_RELATIONSHIP'
  WHERE module1_run_id=v_run AND acquisition_source_code='SRC_PROC_PORTAL';
  PERFORM pg_temp.m1_16_assert_current_integrity(v_run);
 EXCEPTION WHEN OTHERS THEN v_rejected:=true; END;
 PERFORM pg_temp.m1_16_record_negative('M1_16_NEG_02_INVALID_PARENT_MAPPING','Invalid source parent mapping','REJECTED',v_rejected,'Source-to-accepted-parent lineage cannot be contradicted.');

 -- 03 Touchpoint after application
 v_rejected:=false;
 BEGIN
  UPDATE msbf_m1.application_acquisition_touchpoint t
  SET touchpoint_timestamp=(SELECT application_date::timestamptz+interval '2 days' FROM msbf_m1.merchant_application a WHERE a.merchant_application_id=t.merchant_application_id)
  WHERE t.module1_run_id=v_run AND t.merchant_application_id=(SELECT min(merchant_application_id) FROM msbf_m1.application_acquisition_touchpoint WHERE module1_run_id=v_run) AND t.touchpoint_sequence=1;
  PERFORM pg_temp.m1_16_assert_current_integrity(v_run);
 EXCEPTION WHEN OTHERS THEN v_rejected:=true; END;
 PERFORM pg_temp.m1_16_record_negative('M1_16_NEG_03_FUTURE_TOUCHPOINT','Post-application touchpoint','REJECTED',v_rejected,'Acquisition touchpoints cannot occur after the application boundary.');

 -- 04 Inactive campaign
 v_rejected:=false;
 BEGIN
  UPDATE msbf_m1.acquisition_marketing_campaign SET campaign_status='INACTIVE'
  WHERE module1_run_id=v_run AND acquisition_campaign_id=(SELECT min(acquisition_campaign_id) FROM msbf_m1.acquisition_marketing_campaign WHERE module1_run_id=v_run);
  PERFORM pg_temp.m1_16_assert_current_integrity(v_run);
 EXCEPTION WHEN OTHERS THEN v_rejected:=true; END;
 PERFORM pg_temp.m1_16_record_negative('M1_16_NEG_04_INACTIVE_CAMPAIGN','Inactive primary campaign','REJECTED',v_rejected,'Generated attribution cannot rely on an inactive campaign.');

 -- 05 Inverted funnel
 v_rejected:=false;
 BEGIN
  UPDATE msbf_m1.acquisition_campaign_funnel_stage f SET stage_count=stage_count+100000
  WHERE f.module1_run_id=v_run AND f.stage_code='APPLICATION_SUBMITTED'
    AND f.acquisition_campaign_id=(SELECT min(acquisition_campaign_id) FROM msbf_m1.acquisition_campaign_funnel_stage WHERE module1_run_id=v_run);
  PERFORM pg_temp.m1_16_assert_current_integrity(v_run);
 EXCEPTION WHEN OTHERS THEN v_rejected:=true; END;
 PERFORM pg_temp.m1_16_record_negative('M1_16_NEG_05_INVERTED_FUNNEL','Inverted funnel','REJECTED',v_rejected,'A downstream funnel stage cannot exceed an upstream count.');

 -- 06 Negative raw cost
 v_rejected:=false;
 BEGIN
  UPDATE msbf_m1.acquisition_cost_ledger SET gross_cost_amount=-1
  WHERE module1_run_id=v_run AND acquisition_cost_line_id=(SELECT min(acquisition_cost_line_id) FROM msbf_m1.acquisition_cost_ledger WHERE module1_run_id=v_run);
 EXCEPTION WHEN OTHERS THEN v_rejected:=true; END;
 PERFORM pg_temp.m1_16_record_negative('M1_16_NEG_06_NEGATIVE_RAW_COST','Negative raw cost','CHECK_REJECTED',v_rejected,'Raw acquisition expense cannot be negative.');

 -- 07 Unsupported cost basis/timing
 v_rejected:=false;
 BEGIN
  UPDATE msbf_m1.acquisition_cost_ledger SET cost_basis_code='PER_FUNDED_ACCOUNT'
  WHERE module1_run_id=v_run AND conditional_flag=false
    AND acquisition_cost_line_id=(SELECT min(acquisition_cost_line_id) FROM msbf_m1.acquisition_cost_ledger WHERE module1_run_id=v_run AND conditional_flag=false);
  PERFORM pg_temp.m1_16_assert_current_integrity(v_run);
 EXCEPTION WHEN OTHERS THEN v_rejected:=true; END;
 PERFORM pg_temp.m1_16_record_negative('M1_16_NEG_07_UNSUPPORTED_BASIS_TIMING','Unsupported source cost basis','REJECTED',v_rejected,'Source-specific cost basis and timing permissions fail closed.');

 -- 08 Allocation mismatch
 v_rejected:=false;
 BEGIN
  UPDATE msbf_m1.application_acquisition_cost_component_value SET component_amount=component_amount+1
  WHERE module1_run_id=v_run AND cost_component_code IN('PAID_MEDIA_COST','DIRECT_MAIL_EVENT_OUTBOUND_COST','PURCHASED_LEAD_COST','INTERNAL_SALES_RM_COST','AGENCY_CREATIVE_TECH_COST','CAMPAIGN_OVERHEAD_COST','ACQUISITION_INCENTIVE_COST')
    AND merchant_application_id=(SELECT min(merchant_application_id) FROM msbf_m1.application_acquisition_cost_component_value WHERE module1_run_id=v_run AND component_amount>0);
  PERFORM pg_temp.m1_16_assert_current_integrity(v_run);
 EXCEPTION WHEN OTHERS THEN v_rejected:=true; END;
 PERFORM pg_temp.m1_16_record_negative('M1_16_NEG_08_ALLOCATION_MISMATCH','Campaign allocation mismatch','REJECTED',v_rejected,'Application allocations must reconcile exactly to campaign spend.');

 -- 09 Duplicate primary attribution / invalid weight
 v_rejected:=false;
 BEGIN
  UPDATE msbf_m1.application_acquisition_touchpoint SET primary_attribution_flag=true,assisted_touch_flag=false,attribution_weight=1.000000
  WHERE module1_run_id=v_run AND assisted_touch_flag
    AND merchant_application_id=(SELECT min(merchant_application_id) FROM msbf_m1.application_acquisition_touchpoint WHERE module1_run_id=v_run AND assisted_touch_flag);
  PERFORM pg_temp.m1_16_assert_current_integrity(v_run);
 EXCEPTION WHEN OTHERS THEN v_rejected:=true; END;
 PERFORM pg_temp.m1_16_record_negative('M1_16_NEG_09_DUPLICATE_PRIMARY','Duplicate primary attribution','REJECTED',v_rejected,'Each application must have one primary attribution and total weight one.');

 -- 10 Touchpoint count beyond maximum
 v_rejected:=false;
 BEGIN
  INSERT INTO msbf_m1.application_acquisition_touchpoint(
   module1_run_id,merchant_application_id,touchpoint_sequence,merchant_id,acquisition_source_code,
   acquisition_campaign_id,touchpoint_type,touchpoint_timestamp,first_touch_flag,last_touch_flag,
   primary_attribution_flag,assisted_touch_flag,attribution_weight,support_status,evidence_status,
   accepted_partner_channel_id,row_hash,created_by_run_id
  )
  SELECT module1_run_id,merchant_application_id,4,merchant_id,acquisition_source_code,
         acquisition_campaign_id,'ASSISTED',touchpoint_timestamp,false,false,false,true,0.000000,
         support_status,evidence_status,accepted_partner_channel_id,md5(row_hash||'|NEG4'),created_by_run_id
  FROM msbf_m1.application_acquisition_touchpoint
  WHERE module1_run_id=v_run AND merchant_application_id=(
    SELECT merchant_application_id FROM msbf_m1.application_acquisition_touchpoint WHERE module1_run_id=v_run
    GROUP BY merchant_application_id HAVING count(*)=3 ORDER BY merchant_application_id LIMIT 1)
  ORDER BY touchpoint_sequence LIMIT 1;
  PERFORM pg_temp.m1_16_assert_current_integrity(v_run);
 EXCEPTION WHEN OTHERS THEN v_rejected:=true; END;
 PERFORM pg_temp.m1_16_record_negative('M1_16_NEG_10_EXCESS_TOUCHPOINTS','Touchpoint maximum exceeded','REJECTED',v_rejected,'The bounded touchpoint maximum is fail-closed.');

 -- 11 Legacy overlap exceeds bounds
 v_rejected:=false;
 BEGIN
  UPDATE msbf_m1.application_acquisition_cost_snapshot SET identified_legacy_overlap_amount=accepted_m1_14_acquisition_cost_amount+1
  WHERE module1_run_id=v_run AND acquisition_contract_evidence_status<>'BLOCKED'
    AND merchant_application_id=(SELECT min(merchant_application_id) FROM msbf_m1.application_acquisition_cost_snapshot WHERE module1_run_id=v_run AND acquisition_contract_evidence_status<>'BLOCKED');
  PERFORM pg_temp.m1_16_assert_current_integrity(v_run);
 EXCEPTION WHEN OTHERS THEN v_rejected:=true; END;
 PERFORM pg_temp.m1_16_record_negative('M1_16_NEG_11_OVERLAP_EXCEEDS_BOUND','Legacy overlap above bound','REJECTED',v_rejected,'Overlap cannot exceed accepted legacy or mapped detailed cost.');

 -- 12 Double-count mapping contradiction
 v_rejected:=false;
 BEGIN
  UPDATE msbf_m1.application_acquisition_cost_component_value cv SET included_in_m1_14_flag=false
  WHERE cv.module1_run_id=v_run AND cv.cost_component_code='DETAILED_CONDITIONAL_PARTNER_BROKER_COST'
    AND cv.merchant_application_id=(SELECT min(merchant_application_id) FROM msbf_m1.application_acquisition_cost_component_value WHERE module1_run_id=v_run);
  PERFORM pg_temp.m1_16_assert_current_integrity(v_run);
 EXCEPTION WHEN OTHERS THEN v_rejected:=true; END;
 PERFORM pg_temp.m1_16_record_negative('M1_16_NEG_12_DOUBLE_COUNT_MAPPING','Contradictory M1.14 inclusion mapping','REJECTED',v_rejected,'Component-level overlap mapping must remain explicit and consistent.');

 -- 13 Scenario-specific acquisition divergence via accepted M1.15 channel mutation
 v_rejected:=false;
 BEGIN
  UPDATE msbf_m1.application_module1_latest SET partner_channel_id='CH_BANK_RELATIONSHIP'
  WHERE module1_run_id=v_run AND scenario_code='RECESSION_ENERGY'
    AND merchant_application_id=(SELECT min(merchant_application_id) FROM msbf_m1.application_module1_latest WHERE module1_run_id=v_run AND scenario_code='RECESSION_ENERGY' AND partner_channel_id<>'CH_BANK_RELATIONSHIP');
  PERFORM pg_temp.m1_16_assert_current_integrity(v_run);
 EXCEPTION WHEN OTHERS THEN v_rejected:=true; END;
 PERFORM pg_temp.m1_16_record_negative('M1_16_NEG_13_SCENARIO_DIVERGENCE','Scenario-specific acquisition divergence','REJECTED',v_rejected,'Historical acquisition identity cannot vary by current matched scenario.');

 -- 14 M1.16 archive UPDATE and DELETE
 v_rejected:=false;v_second:=false;
 BEGIN
  UPDATE msbf_m1.application_acquisition_contract_archive SET schema_version='INVALID'
  WHERE archive_id=(SELECT min(archive_id) FROM msbf_m1.application_acquisition_contract_archive WHERE module1_run_id=v_run);
 EXCEPTION WHEN OTHERS THEN v_rejected:=true; END;
 BEGIN
  DELETE FROM msbf_m1.application_acquisition_contract_archive
  WHERE archive_id=(SELECT min(archive_id) FROM msbf_m1.application_acquisition_contract_archive WHERE module1_run_id=v_run);
 EXCEPTION WHEN OTHERS THEN v_second:=true; END;
 PERFORM pg_temp.m1_16_record_negative('M1_16_NEG_14_ARCHIVE_IMMUTABILITY','M1.16 archive update/delete','BOTH_REJECTED',v_rejected AND v_second,'Immutable M1.16 archive rejects UPDATE and DELETE.');

 -- 15 Accepted M1.15 archive mutation
 v_rejected:=false;
 BEGIN
  UPDATE msbf_m1.application_module1_archive SET schema_version='INVALID'
  WHERE archive_id=(SELECT min(archive_id) FROM msbf_m1.application_module1_archive WHERE module1_run_id=v_run);
 EXCEPTION WHEN OTHERS THEN v_rejected:=true; END;
 PERFORM pg_temp.m1_16_record_negative('M1_16_NEG_15_M1_15_MUTATION','Accepted M1.15 archive mutation','REJECTED',v_rejected,'M1.16 cannot mutate the accepted M1.15 archive.');

 -- 16 Prerequisite run-status drift
 v_rejected:=false;
 BEGIN
  UPDATE msbf_ctl.run_registry SET run_status='M1_14_ACCEPTED' WHERE run_id=v_run;
  PERFORM pg_temp.m1_16_assert_current_integrity(v_run);
 EXCEPTION WHEN OTHERS THEN v_rejected:=true; END;
 PERFORM pg_temp.m1_16_record_negative('M1_16_NEG_16_RUN_STATUS_DRIFT','Run status drift','REJECTED',v_rejected,'Validated M1.16 execution rejects prerequisite-status drift.');

 -- 17 Attempted post-generation rerun
 v_rejected:=false;
 BEGIN
  PERFORM msbf_m1.m1_16_assert_generation_ready(v_run);
 EXCEPTION WHEN OTHERS THEN v_rejected:=true; END;
 PERFORM pg_temp.m1_16_record_negative('M1_16_NEG_17_POST_GENERATION_RERUN','Post-generation rerun','REJECTED',v_rejected,'Pristine-target readiness rejects regeneration after commit.');

 -- 18 Unknown-as-zero and prohibited Module 2 output
 v_rejected:=false;v_second:=false;
 BEGIN
  UPDATE msbf_m1.application_acquisition_cost_snapshot
  SET identified_legacy_overlap_amount=0,unmapped_legacy_proxy_amount=0,
      incremental_acquisition_cost_beyond_m1_14=0,enhanced_total_acquisition_cost_if_booked=0
  WHERE module1_run_id=v_run AND acquisition_contract_evidence_status='BLOCKED'
    AND merchant_application_id=(SELECT min(merchant_application_id) FROM msbf_m1.application_acquisition_cost_snapshot WHERE module1_run_id=v_run AND acquisition_contract_evidence_status='BLOCKED');
 EXCEPTION WHEN OTHERS THEN v_rejected:=true; END;
 BEGIN
  PERFORM msbf_m1.m1_16_assert_no_prohibited_output('PRICING');
 EXCEPTION WHEN OTHERS THEN v_second:=true; END;
 PERFORM pg_temp.m1_16_record_negative('M1_16_NEG_18_UNKNOWN_ZERO_PROHIBITED_OUTPUT','Unknown cost as zero / Module 2 output','BOTH_REJECTED',v_rejected AND v_second,'Blocked costs remain unknown and M1.16 cannot publish pricing or decisioning output.');


 -- 19 Contract lifecycle mismatch
 v_rejected:=false;
 BEGIN
  UPDATE msbf_ctl.m1_16_acquisition_contract_registry
  SET contract_status='ACCEPTED'
  WHERE module1_run_id=v_run
    AND contract_code='M1_ACQUISITION_CONSUMPTION'
    AND contract_version=1;
  PERFORM msbf_m1.m1_16_assert_persisted_integrity(v_run);
 EXCEPTION WHEN OTHERS THEN v_rejected:=true; END;
 PERFORM pg_temp.m1_16_record_negative(
  'M1_16_NEG_19_CONTRACT_LIFECYCLE_MISMATCH',
  'Run and contract lifecycle mismatch',
  'REJECTED',v_rejected,
  'The validated run and companion-contract registry must remain lifecycle-aligned.'
 );

 -- 20 Component cardinality drift
 v_rejected:=false;
 BEGIN
  DELETE FROM msbf_m1.application_acquisition_cost_component_value
  WHERE module1_run_id=v_run
    AND merchant_application_id=(
      SELECT min(merchant_application_id)
      FROM msbf_m1.application_acquisition_cost_component_value
      WHERE module1_run_id=v_run
    )
    AND cost_component_code=(
      SELECT min(cost_component_code)
      FROM msbf_m1.application_acquisition_cost_component_value
      WHERE module1_run_id=v_run
    );
  PERFORM msbf_m1.m1_16_assert_persisted_integrity(v_run);
 EXCEPTION WHEN OTHERS THEN v_rejected:=true; END;
 PERFORM pg_temp.m1_16_record_negative(
  'M1_16_NEG_20_COMPONENT_CARDINALITY_DRIFT',
  'Acquisition-cost component cardinality drift',
  'REJECTED',v_rejected,
  'Exactly twelve governed cost components per application and 13,274 canonical entities are required.'
 );
END;
$negative_tests$;

DO $negative_guard$
DECLARE v_total integer;v_fail integer;
BEGIN
 SELECT count(*),count(*) FILTER(WHERE status='FAIL') INTO v_total,v_fail FROM _m1_16_negative;
 IF v_total<>20 OR v_fail<>0 THEN
  RAISE EXCEPTION 'M1.16 negative controls failed: total %, failures %.',v_total,v_fail;
 END IF;
END;
$negative_guard$;

DELETE FROM msbf_ctl.run_evidence
WHERE run_id=(SELECT run_id FROM _m1_16_negative_run) AND evidence_code LIKE 'M1_16_NEG_%';
INSERT INTO msbf_ctl.run_evidence(
 run_id,evidence_code,segment_key,metric_name,metric_value_text,unit_code,status,interpretation
)
SELECT (SELECT run_id FROM _m1_16_negative_run),evidence_code,'PORTFOLIO',test_name,
 observed_result,'TEXT',status,interpretation FROM _m1_16_negative;

COMMIT;

SELECT evidence_code,test_name,expected_result,observed_result,status,interpretation
FROM _m1_16_negative ORDER BY evidence_code;
