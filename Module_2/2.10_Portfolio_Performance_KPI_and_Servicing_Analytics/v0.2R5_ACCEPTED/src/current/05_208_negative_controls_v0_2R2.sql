/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.10 — Portfolio Performance, KPI & Servicing Analytics

Program     : 208_msbf_m2_10_negative_control_tests_v0_2R2.sql
Version     : v0.2R2

Purpose
-------
Prove fail-closed behavior for policy and source drift, production-decision and
execution boundaries, invalid burden and scope values, duplicate or invalid
KPI facts, archive mutation, lifecycle reruns, premature acceptance, and
prohibited analytics payloads. The KPI-applicability control uses an explicit NULL-safe contract and verifies the repaired physical constraint before testing.

Required result
---------------
20 / 20 PASS.
============================================================================ */

BEGIN;
SET LOCAL statement_timeout='35min';
SET LOCAL jit=off;
DROP TABLE IF EXISTS _m2_10_negative;
CREATE TEMP TABLE _m2_10_negative
(evidence_code text PRIMARY KEY,metric_name text NOT NULL,status text NOT NULL,
 interpretation text NOT NULL) ON COMMIT PRESERVE ROWS;
DROP TABLE IF EXISTS _m2_10_nctx;
CREATE TEMP TABLE _m2_10_nctx ON COMMIT DROP AS
SELECT run_id,run_status FROM msbf_ctl.run_registry
WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1;

DO $m2_10_negative_ready$
DECLARE
 v_positive bigint;
 v_mapping_errors bigint;
 v_strict_applicability_constraint boolean;
 v_applicability_errors bigint;
BEGIN
 SELECT count(*) INTO v_positive FROM msbf_ctl.run_evidence
 WHERE run_id=(SELECT run_id FROM _m2_10_nctx)
   AND evidence_code LIKE 'M2_10_POS_%' AND status='PASS';

 SELECT count(*) INTO v_mapping_errors
 FROM msbf_m2.portfolio_performance_source_snapshot AS source
 FULL OUTER JOIN msbf_m2.application_portfolio_performance_snapshot AS performance
   ON performance.module1_run_id=source.module1_run_id
  AND performance.scenario_id=source.scenario_id
  AND performance.merchant_application_id=source.merchant_application_id
 WHERE coalesce(source.module1_run_id,performance.module1_run_id)=
       (SELECT run_id FROM _m2_10_nctx)
   AND
   (
       source.row_hash IS NULL
       OR performance.row_hash IS NULL
       OR (CASE
        WHEN source.reconciliation_outcome_code='NO_PAYMENT_ACTIVITY_RECONCILED'
        AND source.certified_state_code='CERTIFIED_CLOSED_NO_PROCESSING'
        AND source.state_certified_flag IS TRUE
        AND source.closed_state_flag IS TRUE
        AND source.active_state_flag IS FALSE
        AND source.review_hold_state_flag IS FALSE
        AND source.exception_resolved_flag IS FALSE
        AND source.exception_case_count=0
        AND source.resolved_exception_count=0
        AND source.unresolved_exception_count=0
        AND source.certified_exposure_amount=0
        AND source.scheduled_payment_amount=0
        AND source.processed_payment_amount=0
        AND source.returned_payment_amount=0
        AND source.retry_payment_amount=0
        AND source.reconciliation_variance_amount=0
        AND source.exposure_variance_amount=0
        THEN 'CLOSED_STABLE'
        WHEN source.reconciliation_outcome_code='PAYMENT_ACTIVITY_RECONCILED_AFTER_RETRY'
        AND source.certified_state_code='CERTIFIED_REASSESSMENT_DUE_AFTER_RETRY'
        AND source.state_certified_flag IS TRUE
        AND source.active_state_flag IS TRUE
        AND source.closed_state_flag IS FALSE
        AND source.review_hold_state_flag IS FALSE
        AND source.exception_resolved_flag IS TRUE
        AND source.exception_case_count=1
        AND source.resolved_exception_count=1
        AND source.unresolved_exception_count=0
        AND source.payment_event_count=7
        AND source.settled_event_count=5
        AND source.returned_event_count=1
        AND source.retry_event_count=1
        AND source.certified_exposure_amount=323.79
        AND source.scheduled_payment_amount=194.25
        AND source.processed_payment_amount=194.25
        AND source.returned_payment_amount=27.75
        AND source.retry_payment_amount=27.75
        AND source.reconciliation_variance_amount=0
        AND source.exposure_variance_amount=0
        THEN 'ACTIVE_RECONCILED'
        WHEN source.reconciliation_outcome_code='RECONCILIATION_REVIEW_HOLD'
        AND source.certified_state_code='CERTIFIED_REVIEW_HOLD'
        AND source.state_certified_flag IS TRUE
        AND source.review_hold_state_flag IS TRUE
        AND source.active_state_flag IS FALSE
        AND source.closed_state_flag IS FALSE
        AND source.exception_resolved_flag IS FALSE
        AND source.exception_case_count=0
        AND source.resolved_exception_count=0
        AND source.unresolved_exception_count=0
        AND source.certified_exposure_amount=461.69
        AND source.scheduled_payment_amount=0
        AND source.processed_payment_amount=0
        AND source.returned_payment_amount=0
        AND source.retry_payment_amount=0
        AND source.reconciliation_variance_amount=0
        AND source.exposure_variance_amount=0
        THEN 'CONTROLLED_REVIEW'
        ELSE 'SOURCE_MAPPING_ERROR'
    END) IS DISTINCT FROM performance.performance_tier_code
       OR (CASE
        WHEN source.reconciliation_outcome_code='NO_PAYMENT_ACTIVITY_RECONCILED'
        AND source.certified_state_code='CERTIFIED_CLOSED_NO_PROCESSING'
        AND source.state_certified_flag IS TRUE
        AND source.closed_state_flag IS TRUE
        AND source.active_state_flag IS FALSE
        AND source.review_hold_state_flag IS FALSE
        AND source.exception_resolved_flag IS FALSE
        AND source.exception_case_count=0
        AND source.resolved_exception_count=0
        AND source.unresolved_exception_count=0
        AND source.certified_exposure_amount=0
        AND source.scheduled_payment_amount=0
        AND source.processed_payment_amount=0
        AND source.returned_payment_amount=0
        AND source.retry_payment_amount=0
        AND source.reconciliation_variance_amount=0
        AND source.exposure_variance_amount=0
        THEN 'NO_SERVICING_REQUIRED'
        WHEN source.reconciliation_outcome_code='PAYMENT_ACTIVITY_RECONCILED_AFTER_RETRY'
        AND source.certified_state_code='CERTIFIED_REASSESSMENT_DUE_AFTER_RETRY'
        AND source.state_certified_flag IS TRUE
        AND source.active_state_flag IS TRUE
        AND source.closed_state_flag IS FALSE
        AND source.review_hold_state_flag IS FALSE
        AND source.exception_resolved_flag IS TRUE
        AND source.exception_case_count=1
        AND source.resolved_exception_count=1
        AND source.unresolved_exception_count=0
        AND source.payment_event_count=7
        AND source.settled_event_count=5
        AND source.returned_event_count=1
        AND source.retry_event_count=1
        AND source.certified_exposure_amount=323.79
        AND source.scheduled_payment_amount=194.25
        AND source.processed_payment_amount=194.25
        AND source.returned_payment_amount=27.75
        AND source.retry_payment_amount=27.75
        AND source.reconciliation_variance_amount=0
        AND source.exposure_variance_amount=0
        THEN 'ACTIVE_REASSESSMENT'
        WHEN source.reconciliation_outcome_code='RECONCILIATION_REVIEW_HOLD'
        AND source.certified_state_code='CERTIFIED_REVIEW_HOLD'
        AND source.state_certified_flag IS TRUE
        AND source.review_hold_state_flag IS TRUE
        AND source.active_state_flag IS FALSE
        AND source.closed_state_flag IS FALSE
        AND source.exception_resolved_flag IS FALSE
        AND source.exception_case_count=0
        AND source.resolved_exception_count=0
        AND source.unresolved_exception_count=0
        AND source.certified_exposure_amount=461.69
        AND source.scheduled_payment_amount=0
        AND source.processed_payment_amount=0
        AND source.returned_payment_amount=0
        AND source.retry_payment_amount=0
        AND source.reconciliation_variance_amount=0
        AND source.exposure_variance_amount=0
        THEN 'GOVERNANCE_REVIEW_HOLD'
        ELSE 'SOURCE_MAPPING_ERROR'
    END) IS DISTINCT FROM performance.servicing_queue_code
       OR (CASE
        WHEN source.reconciliation_outcome_code='NO_PAYMENT_ACTIVITY_RECONCILED'
        AND source.certified_state_code='CERTIFIED_CLOSED_NO_PROCESSING'
        AND source.state_certified_flag IS TRUE
        AND source.closed_state_flag IS TRUE
        AND source.active_state_flag IS FALSE
        AND source.review_hold_state_flag IS FALSE
        AND source.exception_resolved_flag IS FALSE
        AND source.exception_case_count=0
        AND source.resolved_exception_count=0
        AND source.unresolved_exception_count=0
        AND source.certified_exposure_amount=0
        AND source.scheduled_payment_amount=0
        AND source.processed_payment_amount=0
        AND source.returned_payment_amount=0
        AND source.retry_payment_amount=0
        AND source.reconciliation_variance_amount=0
        AND source.exposure_variance_amount=0
        THEN 'M2_10_REASON_CLOSED_STABLE'
        WHEN source.reconciliation_outcome_code='PAYMENT_ACTIVITY_RECONCILED_AFTER_RETRY'
        AND source.certified_state_code='CERTIFIED_REASSESSMENT_DUE_AFTER_RETRY'
        AND source.state_certified_flag IS TRUE
        AND source.active_state_flag IS TRUE
        AND source.closed_state_flag IS FALSE
        AND source.review_hold_state_flag IS FALSE
        AND source.exception_resolved_flag IS TRUE
        AND source.exception_case_count=1
        AND source.resolved_exception_count=1
        AND source.unresolved_exception_count=0
        AND source.payment_event_count=7
        AND source.settled_event_count=5
        AND source.returned_event_count=1
        AND source.retry_event_count=1
        AND source.certified_exposure_amount=323.79
        AND source.scheduled_payment_amount=194.25
        AND source.processed_payment_amount=194.25
        AND source.returned_payment_amount=27.75
        AND source.retry_payment_amount=27.75
        AND source.reconciliation_variance_amount=0
        AND source.exposure_variance_amount=0
        THEN 'M2_10_REASON_ACTIVE_RECONCILED'
        WHEN source.reconciliation_outcome_code='RECONCILIATION_REVIEW_HOLD'
        AND source.certified_state_code='CERTIFIED_REVIEW_HOLD'
        AND source.state_certified_flag IS TRUE
        AND source.review_hold_state_flag IS TRUE
        AND source.active_state_flag IS FALSE
        AND source.closed_state_flag IS FALSE
        AND source.exception_resolved_flag IS FALSE
        AND source.exception_case_count=0
        AND source.resolved_exception_count=0
        AND source.unresolved_exception_count=0
        AND source.certified_exposure_amount=461.69
        AND source.scheduled_payment_amount=0
        AND source.processed_payment_amount=0
        AND source.returned_payment_amount=0
        AND source.retry_payment_amount=0
        AND source.reconciliation_variance_amount=0
        AND source.exposure_variance_amount=0
        THEN 'M2_10_REASON_CONTROLLED_REVIEW'
        ELSE 'M2_10_REASON_SOURCE_MAPPING_ERROR'
    END) IS DISTINCT FROM performance.primary_portfolio_reason_code
   );

 SELECT
  count(*)=1
  AND bool_and(constraint_record.convalidated)
  AND bool_or
      (
       position('kpi_value_numeric IS NULL'
                IN pg_get_constraintdef(constraint_record.oid))>0
       AND position('kpi_value_text IS NULL'
                    IN pg_get_constraintdef(constraint_record.oid))>0
       AND position('kpi_value_text IS NOT NULL'
                    IN pg_get_constraintdef(constraint_record.oid))>0
      )
 INTO v_strict_applicability_constraint
 FROM pg_constraint AS constraint_record
 WHERE constraint_record.conrelid=
       'msbf_m2.portfolio_kpi_snapshot'::regclass
   AND constraint_record.conname='ck_m2_10_kpi_applicability';

 SELECT count(*)
 INTO v_applicability_errors
 FROM msbf_m2.portfolio_kpi_snapshot
 WHERE module1_run_id=(SELECT run_id FROM _m2_10_nctx)
   AND NOT
   (
      (
       applicable_flag IS TRUE
       AND kpi_value_numeric IS NOT NULL
       AND kpi_value_text IS NULL
      )
      OR
      (
       applicable_flag IS FALSE
       AND kpi_value_numeric IS NULL
       AND kpi_value_text IS NOT NULL
       AND kpi_value_text='NOT_APPLICABLE'
      )
   );

 IF (SELECT run_status FROM _m2_10_nctx)<>'M2_10_VALIDATED'
    OR v_positive<>120
    OR v_mapping_errors<>0
    OR NOT coalesce(v_strict_applicability_constraint,FALSE)
    OR v_applicability_errors<>0
 THEN
  RAISE EXCEPTION
   'M2.10 negative controls require M2_10_VALIDATED, 120 positive passes, zero source-mapping errors, a validated strict KPI-applicability constraint, and zero applicability errors; positive %, mapping errors %, strict constraint %, applicability errors %.',
   v_positive,v_mapping_errors,
   v_strict_applicability_constraint,v_applicability_errors;
 END IF;
END;
$m2_10_negative_ready$;

CREATE OR REPLACE FUNCTION pg_temp.m2_10_add_negative
(p_code text,p_pass boolean,p_interpretation text)
RETURNS void LANGUAGE plpgsql AS $function$
BEGIN INSERT INTO _m2_10_negative VALUES
(p_code,p_code,CASE WHEN p_pass THEN 'PASS' ELSE 'FAIL' END,p_interpretation); END;
$function$;

CREATE TEMP TABLE _m2_10_neg_reason
(production_action_flag boolean NOT NULL CHECK(production_action_flag IS FALSE)) ON COMMIT DROP;
CREATE TEMP TABLE _m2_10_neg_burden
(burden_units numeric(12,6) NOT NULL CHECK(burden_units>=0)) ON COMMIT DROP;
CREATE TEMP TABLE _m2_10_neg_queue_burden
(burden_units numeric(12,6) NOT NULL CHECK(burden_units>=0)) ON COMMIT DROP;
CREATE TEMP TABLE _m2_10_neg_kpi_grain
(scope_code text NOT NULL,kpi_code text NOT NULL,PRIMARY KEY(scope_code,kpi_code)) ON COMMIT DROP;
CREATE TEMP TABLE _m2_10_neg_kpi_value
(kpi_value_numeric numeric,kpi_value_text text,CHECK(num_nonnulls(kpi_value_numeric,kpi_value_text)=1)) ON COMMIT DROP;
CREATE TEMP TABLE _m2_10_neg_kpi_applicability
(
 applicable_flag boolean NOT NULL,
 kpi_value_numeric numeric,
 kpi_value_text text,
 CHECK
 (
  (
   applicable_flag IS TRUE
   AND kpi_value_numeric IS NOT NULL
   AND kpi_value_text IS NULL
  )
  OR
  (
   applicable_flag IS FALSE
   AND kpi_value_numeric IS NULL
   AND kpi_value_text IS NOT NULL
   AND kpi_value_text='NOT_APPLICABLE'
  )
 )
) ON COMMIT DROP;
CREATE TEMP TABLE _m2_10_neg_scope
(account_count bigint,active_count bigint,closed_count bigint,review_count bigint,
 CHECK(active_count+closed_count+review_count=account_count)) ON COMMIT DROP;

/* ============================================================================
Section 1 — Twenty governed negative controls
============================================================================ */
DO $m2_10_neg_001_policy_status$
BEGIN
 BEGIN
  UPDATE msbf_ctl.m2_10_policy_profile
  SET policy_status='DRAFT'
  WHERE module1_run_id=(SELECT run_id FROM _m2_10_nctx);
  PERFORM pg_temp.m2_10_add_negative('M2_10_NEG_001_POLICY_STATUS',FALSE,'Expected rejection did not occur.');
 EXCEPTION WHEN check_violation THEN
  PERFORM pg_temp.m2_10_add_negative('M2_10_NEG_001_POLICY_STATUS',TRUE,SQLERRM);
 END;
END;
$m2_10_neg_001_policy_status$;
DO $m2_10_neg_002_analytics_boundary$
BEGIN
 BEGIN
  UPDATE msbf_ctl.m2_10_policy_profile
  SET analytics_only_flag=FALSE
  WHERE module1_run_id=(SELECT run_id FROM _m2_10_nctx);
  PERFORM msbf_ctl.m2_10_assert_configuration((SELECT run_id FROM _m2_10_nctx));
  PERFORM pg_temp.m2_10_add_negative('M2_10_NEG_002_ANALYTICS_BOUNDARY',FALSE,'Expected rejection did not occur.');
 EXCEPTION WHEN OTHERS THEN
  PERFORM pg_temp.m2_10_add_negative('M2_10_NEG_002_ANALYTICS_BOUNDARY',TRUE,SQLERRM);
 END;
END;
$m2_10_neg_002_analytics_boundary$;
DO $m2_10_neg_003_decision_boundary$
BEGIN
 BEGIN
  UPDATE msbf_ctl.m2_10_policy_profile
  SET no_production_decisioning_flag=FALSE
  WHERE module1_run_id=(SELECT run_id FROM _m2_10_nctx);
  PERFORM msbf_ctl.m2_10_assert_configuration((SELECT run_id FROM _m2_10_nctx));
  PERFORM pg_temp.m2_10_add_negative('M2_10_NEG_003_DECISION_BOUNDARY',FALSE,'Expected rejection did not occur.');
 EXCEPTION WHEN OTHERS THEN
  PERFORM pg_temp.m2_10_add_negative('M2_10_NEG_003_DECISION_BOUNDARY',TRUE,SQLERRM);
 END;
END;
$m2_10_neg_003_decision_boundary$;
DO $m2_10_neg_004_funds_boundary$
BEGIN
 BEGIN
  UPDATE msbf_ctl.m2_10_policy_profile
  SET no_real_funds_movement_flag=FALSE
  WHERE module1_run_id=(SELECT run_id FROM _m2_10_nctx);
  PERFORM msbf_ctl.m2_10_assert_configuration((SELECT run_id FROM _m2_10_nctx));
  PERFORM pg_temp.m2_10_add_negative('M2_10_NEG_004_FUNDS_BOUNDARY',FALSE,'Expected rejection did not occur.');
 EXCEPTION WHEN OTHERS THEN
  PERFORM pg_temp.m2_10_add_negative('M2_10_NEG_004_FUNDS_BOUNDARY',TRUE,SQLERRM);
 END;
END;
$m2_10_neg_004_funds_boundary$;
DO $m2_10_neg_005_system_boundary$
BEGIN
 BEGIN
  UPDATE msbf_ctl.m2_10_policy_profile
  SET no_external_system_update_flag=FALSE
  WHERE module1_run_id=(SELECT run_id FROM _m2_10_nctx);
  PERFORM msbf_ctl.m2_10_assert_configuration((SELECT run_id FROM _m2_10_nctx));
  PERFORM pg_temp.m2_10_add_negative('M2_10_NEG_005_SYSTEM_BOUNDARY',FALSE,'Expected rejection did not occur.');
 EXCEPTION WHEN OTHERS THEN
  PERFORM pg_temp.m2_10_add_negative('M2_10_NEG_005_SYSTEM_BOUNDARY',TRUE,SQLERRM);
 END;
END;
$m2_10_neg_005_system_boundary$;
DO $m2_10_neg_006_contact_boundary$
BEGIN
 BEGIN
  UPDATE msbf_ctl.m2_10_policy_profile
  SET no_merchant_contact_flag=FALSE
  WHERE module1_run_id=(SELECT run_id FROM _m2_10_nctx);
  PERFORM msbf_ctl.m2_10_assert_configuration((SELECT run_id FROM _m2_10_nctx));
  PERFORM pg_temp.m2_10_add_negative('M2_10_NEG_006_CONTACT_BOUNDARY',FALSE,'Expected rejection did not occur.');
 EXCEPTION WHEN OTHERS THEN
  PERFORM pg_temp.m2_10_add_negative('M2_10_NEG_006_CONTACT_BOUNDARY',TRUE,SQLERRM);
 END;
END;
$m2_10_neg_006_contact_boundary$;
DO $m2_10_neg_007_reason_production_action$
BEGIN
 BEGIN
  INSERT INTO _m2_10_neg_reason VALUES(TRUE);
  PERFORM pg_temp.m2_10_add_negative('M2_10_NEG_007_REASON_PRODUCTION_ACTION',FALSE,'Expected rejection did not occur.');
 EXCEPTION WHEN check_violation THEN
  PERFORM pg_temp.m2_10_add_negative('M2_10_NEG_007_REASON_PRODUCTION_ACTION',TRUE,SQLERRM);
 END;
END;
$m2_10_neg_007_reason_production_action$;
DO $m2_10_neg_008_negative_tier_burden$
BEGIN
 BEGIN
  INSERT INTO _m2_10_neg_burden VALUES(-1.000000);
  PERFORM pg_temp.m2_10_add_negative('M2_10_NEG_008_NEGATIVE_TIER_BURDEN',FALSE,'Expected rejection did not occur.');
 EXCEPTION WHEN check_violation THEN
  PERFORM pg_temp.m2_10_add_negative('M2_10_NEG_008_NEGATIVE_TIER_BURDEN',TRUE,SQLERRM);
 END;
END;
$m2_10_neg_008_negative_tier_burden$;
DO $m2_10_neg_009_negative_queue_burden$
BEGIN
 BEGIN
  INSERT INTO _m2_10_neg_queue_burden VALUES(-1.000000);
  PERFORM pg_temp.m2_10_add_negative('M2_10_NEG_009_NEGATIVE_QUEUE_BURDEN',FALSE,'Expected rejection did not occur.');
 EXCEPTION WHEN check_violation THEN
  PERFORM pg_temp.m2_10_add_negative('M2_10_NEG_009_NEGATIVE_QUEUE_BURDEN',TRUE,SQLERRM);
 END;
END;
$m2_10_neg_009_negative_queue_burden$;
DO $m2_10_neg_010_duplicate_kpi_grain$
BEGIN
 BEGIN
  INSERT INTO _m2_10_neg_kpi_grain VALUES('PORTFOLIO_ALL','ACCOUNT_COUNT');
  INSERT INTO _m2_10_neg_kpi_grain VALUES('PORTFOLIO_ALL','ACCOUNT_COUNT');
  PERFORM pg_temp.m2_10_add_negative('M2_10_NEG_010_DUPLICATE_KPI_GRAIN',FALSE,'Expected rejection did not occur.');
 EXCEPTION WHEN unique_violation THEN
  PERFORM pg_temp.m2_10_add_negative('M2_10_NEG_010_DUPLICATE_KPI_GRAIN',TRUE,SQLERRM);
 END;
END;
$m2_10_neg_010_duplicate_kpi_grain$;
DO $m2_10_neg_011_null_kpi_value$
BEGIN
 BEGIN
  INSERT INTO _m2_10_neg_kpi_value VALUES(NULL,NULL);
  PERFORM pg_temp.m2_10_add_negative('M2_10_NEG_011_NULL_KPI_VALUE',FALSE,'Expected rejection did not occur.');
 EXCEPTION WHEN check_violation THEN
  PERFORM pg_temp.m2_10_add_negative('M2_10_NEG_011_NULL_KPI_VALUE',TRUE,SQLERRM);
 END;
END;
$m2_10_neg_011_null_kpi_value$;
DO $m2_10_neg_012_invalid_kpi_applicability$
BEGIN
 BEGIN
  INSERT INTO _m2_10_neg_kpi_applicability VALUES(FALSE,1.000000,NULL);
  PERFORM pg_temp.m2_10_add_negative('M2_10_NEG_012_INVALID_KPI_APPLICABILITY',FALSE,'Expected rejection did not occur.');
 EXCEPTION WHEN check_violation THEN
  PERFORM pg_temp.m2_10_add_negative('M2_10_NEG_012_INVALID_KPI_APPLICABILITY',TRUE,SQLERRM);
 END;
END;
$m2_10_neg_012_invalid_kpi_applicability$;
DO $m2_10_neg_013_invalid_scope_counts$
BEGIN
 BEGIN
  INSERT INTO _m2_10_neg_scope VALUES(10,5,5,5);
  PERFORM pg_temp.m2_10_add_negative('M2_10_NEG_013_INVALID_SCOPE_COUNTS',FALSE,'Expected rejection did not occur.');
 EXCEPTION WHEN check_violation THEN
  PERFORM pg_temp.m2_10_add_negative('M2_10_NEG_013_INVALID_SCOPE_COUNTS',TRUE,SQLERRM);
 END;
END;
$m2_10_neg_013_invalid_scope_counts$;
DO $m2_10_neg_014_archive_update$
BEGIN
 BEGIN
  UPDATE msbf_m2.application_portfolio_performance_archive
  SET performance_tier_code='MUTATION_TEST'
  WHERE archive_id=(SELECT archive_id FROM msbf_m2.application_portfolio_performance_archive
    WHERE module1_run_id=(SELECT run_id FROM _m2_10_nctx) ORDER BY archive_id LIMIT 1);
  PERFORM pg_temp.m2_10_add_negative('M2_10_NEG_014_ARCHIVE_UPDATE',FALSE,'Expected rejection did not occur.');
 EXCEPTION WHEN OTHERS THEN
  PERFORM pg_temp.m2_10_add_negative('M2_10_NEG_014_ARCHIVE_UPDATE',TRUE,SQLERRM);
 END;
END;
$m2_10_neg_014_archive_update$;
DO $m2_10_neg_015_archive_delete$
BEGIN
 BEGIN
  DELETE FROM msbf_m2.application_portfolio_performance_archive
  WHERE archive_id=(SELECT archive_id FROM msbf_m2.application_portfolio_performance_archive
    WHERE module1_run_id=(SELECT run_id FROM _m2_10_nctx) ORDER BY archive_id LIMIT 1);
  PERFORM pg_temp.m2_10_add_negative('M2_10_NEG_015_ARCHIVE_DELETE',FALSE,'Expected rejection did not occur.');
 EXCEPTION WHEN OTHERS THEN
  PERFORM pg_temp.m2_10_add_negative('M2_10_NEG_015_ARCHIVE_DELETE',TRUE,SQLERRM);
 END;
END;
$m2_10_neg_015_archive_delete$;
DO $m2_10_neg_016_post_generation_rerun$
BEGIN
 BEGIN
  PERFORM msbf_ctl.m2_10_assert_generation_ready((SELECT run_id FROM _m2_10_nctx));
  PERFORM pg_temp.m2_10_add_negative('M2_10_NEG_016_POST_GENERATION_RERUN',FALSE,'Expected rejection did not occur.');
 EXCEPTION WHEN OTHERS THEN
  PERFORM pg_temp.m2_10_add_negative('M2_10_NEG_016_POST_GENERATION_RERUN',TRUE,SQLERRM);
 END;
END;
$m2_10_neg_016_post_generation_rerun$;
DO $m2_10_neg_017_premature_acceptance$
BEGIN
 BEGIN
  PERFORM msbf_ctl.m2_10_assert_acceptance_ready((SELECT run_id FROM _m2_10_nctx));
  PERFORM pg_temp.m2_10_add_negative('M2_10_NEG_017_PREMATURE_ACCEPTANCE',FALSE,'Expected rejection did not occur.');
 EXCEPTION WHEN OTHERS THEN
  PERFORM pg_temp.m2_10_add_negative('M2_10_NEG_017_PREMATURE_ACCEPTANCE',TRUE,SQLERRM);
 END;
END;
$m2_10_neg_017_premature_acceptance$;
DO $m2_10_neg_018_source_hash_drift$
BEGIN
 BEGIN
  UPDATE msbf_ctl.m2_10_policy_profile
  SET source_combined_set_hash='00000000000000000000000000000000'
  WHERE module1_run_id=(SELECT run_id FROM _m2_10_nctx);
  PERFORM msbf_ctl.m2_10_assert_configuration((SELECT run_id FROM _m2_10_nctx));
  PERFORM pg_temp.m2_10_add_negative('M2_10_NEG_018_SOURCE_HASH_DRIFT',FALSE,'Expected rejection did not occur.');
 EXCEPTION WHEN OTHERS THEN
  PERFORM pg_temp.m2_10_add_negative('M2_10_NEG_018_SOURCE_HASH_DRIFT',TRUE,SQLERRM);
 END;
END;
$m2_10_neg_018_source_hash_drift$;
DO $m2_10_neg_019_production_decision_payload$
BEGIN
 BEGIN
  PERFORM msbf_ctl.m2_10_assert_no_production_analytics_payload
  (jsonb_build_object('production_decision','APPROVE','production_strategy_change',TRUE));
  PERFORM pg_temp.m2_10_add_negative('M2_10_NEG_019_PRODUCTION_DECISION_PAYLOAD',FALSE,'Expected rejection did not occur.');
 EXCEPTION WHEN OTHERS THEN
  PERFORM pg_temp.m2_10_add_negative('M2_10_NEG_019_PRODUCTION_DECISION_PAYLOAD',TRUE,SQLERRM);
 END;
END;
$m2_10_neg_019_production_decision_payload$;
DO $m2_10_neg_020_execution_payload$
BEGIN
 BEGIN
  PERFORM msbf_ctl.m2_10_assert_no_production_analytics_payload
  (jsonb_build_object('real_funds_moved',TRUE,'external_system_updated',TRUE,
   'merchant_contact_executed',TRUE,'write_off_posted',TRUE,
   'collection_agency_referral',TRUE,'legal_action_executed',TRUE,
   'external_notice_payload',jsonb_build_object('synthetic',TRUE),
   'production_adverse_action_notice',TRUE));
  PERFORM pg_temp.m2_10_add_negative('M2_10_NEG_020_EXECUTION_PAYLOAD',FALSE,'Expected rejection did not occur.');
 EXCEPTION WHEN OTHERS THEN
  PERFORM pg_temp.m2_10_add_negative('M2_10_NEG_020_EXECUTION_PAYLOAD',TRUE,SQLERRM);
 END;
END;
$m2_10_neg_020_execution_payload$;

/* ============================================================================
Section 2 — Persist evidence only after all controls pass
============================================================================ */
DO $m2_10_negative_finalize$
DECLARE v_total bigint; v_pass bigint; v_fail bigint; v_failed_controls text;
BEGIN
 SELECT count(*),count(*) FILTER(WHERE status='PASS'),count(*) FILTER(WHERE status='FAIL')
 INTO v_total,v_pass,v_fail FROM _m2_10_negative;
 IF v_total<>20 THEN RAISE EXCEPTION 'M2.10 negative-control inventory failed: total %, expected 20.',v_total; END IF;
 INSERT INTO msbf_ctl.run_evidence
 (run_id,evidence_code,segment_key,metric_name,metric_value_numeric,
  metric_value_text,unit_code,status,interpretation)
 SELECT (SELECT run_id FROM _m2_10_nctx),evidence_code,'PORTFOLIO',metric_name,
  NULL::numeric(28,10),status,'NEGATIVE_CONTROL',status,interpretation
 FROM _m2_10_negative
 ON CONFLICT(run_id,evidence_code,segment_key) DO UPDATE SET
  metric_name=EXCLUDED.metric_name,metric_value_numeric=NULL,
  metric_value_text=EXCLUDED.metric_value_text,unit_code=EXCLUDED.unit_code,
  status=EXCLUDED.status,interpretation=EXCLUDED.interpretation,
  created_at=clock_timestamp();
 IF v_pass<>20 OR v_fail<>0 THEN
  SELECT string_agg
         (
          evidence_code||' [observed='||status||'; '||interpretation||']',
          '; ' ORDER BY evidence_code
         )
  INTO v_failed_controls
  FROM _m2_10_negative
  WHERE status='FAIL';

  RAISE EXCEPTION
   'M2.10 negative controls failed: pass %, fail %; failed controls: %.',
   v_pass,v_fail,coalesce(v_failed_controls,'<none>');
 END IF;
END;
$m2_10_negative_finalize$;
COMMIT;
SELECT evidence_code,metric_name,status,interpretation
FROM _m2_10_negative ORDER BY evidence_code;
