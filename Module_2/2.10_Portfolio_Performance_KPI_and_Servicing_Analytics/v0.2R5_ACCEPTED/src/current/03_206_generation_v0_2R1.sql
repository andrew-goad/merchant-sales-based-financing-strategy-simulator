/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.10 — Portfolio Performance, KPI & Servicing Analytics

Program     : 206_msbf_m2_10_portfolio_performance_kpi_generation_v0_2R1.sql
Version     : v0.2R1

Purpose
-------
Materialize the accepted M2.9 latest contract exactly once; derive 59
account-performance facts; produce portfolio and scenario summaries, 72 KPI
facts, three servicing-queue summaries, latest and immutable archive
contracts; compute deterministic set and canonical hashes; persist 24
generation-evidence records; and transition the run to M2_10_GENERATED.

Performance design
------------------
The accepted M2.9 source is scanned once. Exact accepted M2.9 outcome,
certification-state, flag, amount, exception, and variance predicates are
materialized in a fail-closed classification layer before any performance
tier is assigned. Reusable intermediates are indexed and ANALYZED. Scope and queue
summaries aggregate the account fact without self-joins. Persisted generation
is separated from validation, negative controls, acceptance, and reporting.

Required result
---------------
generation_status=PASS; 59 account facts; three scopes; 72 KPI facts; three
queues; exact 57/1/1 tier and queue posture; $785.48 certified exposure;
7.000000 burden units; 370 canonical entities; zero deterministic or stress
improvement mismatches.
============================================================================ */

BEGIN;
SET LOCAL work_mem='224MB';
SET LOCAL lock_timeout='10s';
SET LOCAL statement_timeout='70min';
SET LOCAL jit=off;

/* ============================================================================
Section 1 — Context and generation readiness
============================================================================ */

DROP TABLE IF EXISTS _m2_10_result;
CREATE TEMP TABLE _m2_10_result
(
 run_id bigint,run_status text,policy_rows bigint,kpi_definition_rows bigint,
 performance_tier_rows bigint,servicing_queue_rows bigint,reason_rows bigint,
 source_rows bigint,account_performance_rows bigint,scope_summary_rows bigint,
 kpi_snapshot_rows bigint,queue_summary_rows bigint,latest_rows bigint,
 archive_rows bigint,comparison_rows bigint,registry_rows bigint,
 portfolio_account_rows bigint,baseline_account_rows bigint,stress_account_rows bigint,
 closed_stable_rows bigint,active_reconciled_rows bigint,controlled_review_rows bigint,
 no_servicing_queue_rows bigint,active_reassessment_queue_rows bigint,
 governance_review_queue_rows bigint,certified_account_rows bigint,
 certification_rate numeric(18,6),certified_exposure_amount numeric(24,2),
 active_exposure_amount numeric(24,2),review_hold_exposure_amount numeric(24,2),
 scheduled_payment_amount numeric(24,2),processed_payment_amount numeric(24,2),
 gross_collection_rate numeric(18,6),returned_payment_amount numeric(24,2),
 return_rate numeric(18,6),retry_payment_amount numeric(24,2),
 retry_cure_rate numeric(18,6),reconciliation_variance_amount numeric(24,2),
 exposure_variance_amount numeric(24,2),exception_case_count bigint,
 resolved_exception_count bigint,exception_resolution_rate numeric(18,6),
 unresolved_exception_count bigint,servicing_burden_units numeric(24,6),
 average_burden_per_account numeric(18,6),expected_canonical_entities bigint,
 actual_canonical_entities bigint,row_level_mismatches bigint,
 stress_tier_improvements bigint,stress_burden_improvements bigint,
 stress_exposure_improvements bigint,policy_set_hash text,
 kpi_definition_set_hash text,performance_tier_set_hash text,
 servicing_queue_set_hash text,reason_set_hash text,source_set_hash text,
 account_performance_set_hash text,scope_summary_set_hash text,
 kpi_snapshot_set_hash text,queue_summary_set_hash text,latest_set_hash text,
 archive_set_hash text,contract_set_hash text,combined_set_hash text,
 generation_status text
) ON COMMIT PRESERVE ROWS;

DROP TABLE IF EXISTS _m2_10_ctx;
CREATE TEMP TABLE _m2_10_ctx ON COMMIT DROP AS
SELECT run.run_id,run.as_of_date,policy.configuration_hash,
 policy.closed_burden_units,policy.active_burden_units,
 policy.review_burden_units,policy.rate_decimal_scale,
 policy.source_combined_set_hash
FROM msbf_ctl.run_registry AS run
JOIN msbf_ctl.m2_10_policy_profile AS policy
  ON policy.module1_run_id=run.run_id
WHERE run.run_code='M1_V0_2_BASELINE_BUILD' AND run.run_version=1;

DO $m2_10_generation_ready$
BEGIN
 PERFORM msbf_ctl.m2_10_assert_generation_ready((SELECT run_id FROM _m2_10_ctx));
END;
$m2_10_generation_ready$;

/* ============================================================================
Section 2 — Materialize accepted M2.9 latest source once
============================================================================ */

DROP TABLE IF EXISTS _m2_10_source_input;
CREATE TEMP TABLE _m2_10_source_input ON COMMIT DROP AS
SELECT source.module1_run_id,source.scenario_id,source.scenario_code,
 source.merchant_application_id,source.merchant_id,source.synthetic_account_id,
 source.synthetic_advance_id,source.source_final_lifecycle_state_code,
 source.source_exposure_amount,source.payment_event_count,
 source.settled_event_count,source.returned_event_count,source.retry_event_count,
 source.scheduled_payment_amount,source.processed_payment_amount,
 source.returned_payment_amount,source.retry_payment_amount,
 source.reconciliation_variance_amount,source.exposure_variance_amount,
 source.exception_case_count,source.resolved_exception_count,
 source.unresolved_exception_count,source.reconciliation_outcome_code,
 source.resolution_action_code,source.certified_state_code,
 source.state_certified_flag,source.active_state_flag,source.closed_state_flag,
 source.review_hold_state_flag,source.exception_resolved_flag,
 source.certified_exposure_amount,source.certification_date,
 source.primary_reconciliation_reason_code,source.reconciliation_reason_codes,
 source.contract_row_hash AS source_contract_row_hash,
 ctx.source_combined_set_hash,to_jsonb(source) AS source_payload
FROM msbf_m2.application_payment_reconciliation_certification_latest AS source
CROSS JOIN _m2_10_ctx AS ctx
WHERE source.module1_run_id=ctx.run_id;
CREATE UNIQUE INDEX ON _m2_10_source_input
(module1_run_id,scenario_id,merchant_application_id);
CREATE INDEX ON _m2_10_source_input
(module1_run_id,scenario_code,certified_state_code);
ANALYZE _m2_10_source_input;

/* ============================================================================
Section 3 — Target-typed source snapshot and account-performance fact
============================================================================ */

DROP TABLE IF EXISTS _m2_10_source_expected;
CREATE TEMP TABLE _m2_10_source_expected ON COMMIT DROP AS
SELECT source.*,NULL::text AS row_hash
FROM _m2_10_source_input AS source WHERE FALSE;

INSERT INTO _m2_10_source_expected
SELECT source.*,NULL::text FROM _m2_10_source_input AS source;
UPDATE _m2_10_source_expected AS source
SET row_hash=msbf_ctl.m2_10_hash_jsonb(to_jsonb(source)-'row_hash')
WHERE source.row_hash IS NULL;
CREATE UNIQUE INDEX ON _m2_10_source_expected
(module1_run_id,scenario_id,merchant_application_id);
ANALYZE _m2_10_source_expected;

INSERT INTO msbf_m2.portfolio_performance_source_snapshot
(
 module1_run_id,scenario_id,scenario_code,merchant_application_id,merchant_id,
 synthetic_account_id,synthetic_advance_id,source_final_lifecycle_state_code,
 source_exposure_amount,payment_event_count,settled_event_count,
 returned_event_count,retry_event_count,scheduled_payment_amount,
 processed_payment_amount,returned_payment_amount,retry_payment_amount,
 reconciliation_variance_amount,exposure_variance_amount,exception_case_count,
 resolved_exception_count,unresolved_exception_count,reconciliation_outcome_code,
 resolution_action_code,certified_state_code,state_certified_flag,
 active_state_flag,closed_state_flag,review_hold_state_flag,
 exception_resolved_flag,certified_exposure_amount,certification_date,
 primary_reconciliation_reason_code,reconciliation_reason_codes,
 source_contract_row_hash,source_combined_set_hash,source_payload,row_hash
)
SELECT module1_run_id,scenario_id,scenario_code,merchant_application_id,merchant_id,
 synthetic_account_id,synthetic_advance_id,source_final_lifecycle_state_code,
 source_exposure_amount,payment_event_count,settled_event_count,
 returned_event_count,retry_event_count,scheduled_payment_amount,
 processed_payment_amount,returned_payment_amount,retry_payment_amount,
 reconciliation_variance_amount,exposure_variance_amount,exception_case_count,
 resolved_exception_count,unresolved_exception_count,reconciliation_outcome_code,
 resolution_action_code,certified_state_code,state_certified_flag,
 active_state_flag,closed_state_flag,review_hold_state_flag,
 exception_resolved_flag,certified_exposure_amount,certification_date,
 primary_reconciliation_reason_code,reconciliation_reason_codes,
 source_contract_row_hash,source_combined_set_hash,source_payload,row_hash
FROM _m2_10_source_expected;

DROP TABLE IF EXISTS _m2_10_source_classified;
CREATE TEMP TABLE _m2_10_source_classified ON COMMIT DROP AS
SELECT
    source.*,
    CASE
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
        AND source.exposure_variance_amount=0 THEN 'CLOSED_STABLE'
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
        AND source.exposure_variance_amount=0 THEN 'ACTIVE_RECONCILED'
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
        AND source.exposure_variance_amount=0 THEN 'CONTROLLED_REVIEW'
        ELSE 'SOURCE_MAPPING_ERROR'
    END AS source_mapping_code,
    CASE
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
    END AS performance_tier_code,
    CASE
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
    END AS servicing_queue_code,
    CASE
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
    END AS primary_portfolio_reason_code
FROM _m2_10_source_expected AS source;

CREATE UNIQUE INDEX ON _m2_10_source_classified
(module1_run_id,scenario_id,merchant_application_id);
CREATE INDEX ON _m2_10_source_classified
(module1_run_id,source_mapping_code);
ANALYZE _m2_10_source_classified;

DO $m2_10_source_mapping_guard$
DECLARE
    v record;
BEGIN
    SELECT
        count(*) AS source_rows,
        count(*) FILTER(WHERE source_mapping_code='CLOSED_STABLE') AS closed_rows,
        count(*) FILTER(WHERE source_mapping_code='ACTIVE_RECONCILED') AS active_rows,
        count(*) FILTER(WHERE source_mapping_code='CONTROLLED_REVIEW') AS review_rows,
        count(*) FILTER(WHERE source_mapping_code='SOURCE_MAPPING_ERROR') AS mapping_errors
    INTO v
    FROM _m2_10_source_classified;

    IF v.source_rows<>59
       OR v.closed_rows<>57
       OR v.active_rows<>1
       OR v.review_rows<>1
       OR v.mapping_errors<>0
    THEN
        RAISE EXCEPTION
            'M2.10 accepted M2.9 source classification failed: %.',
            row_to_json(v);
    END IF;
END;
$m2_10_source_mapping_guard$;

DROP TABLE IF EXISTS _m2_10_performance_expected;
CREATE TEMP TABLE _m2_10_performance_expected ON COMMIT DROP AS
SELECT mapped.module1_run_id,mapped.scenario_id,mapped.scenario_code,
 mapped.merchant_application_id,mapped.merchant_id,mapped.synthetic_account_id,
 mapped.synthetic_advance_id,mapped.source_final_lifecycle_state_code,
 mapped.certified_state_code,mapped.state_certified_flag,
 mapped.performance_tier_code,mapped.servicing_queue_code,
 (mapped.payment_event_count>0) AS payment_activity_flag,
 (mapped.exception_case_count>0) AS exception_incident_flag,
 (mapped.exception_case_count>0 AND mapped.unresolved_exception_count=0
  AND mapped.resolved_exception_count=mapped.exception_case_count) AS exception_resolved_flag,
 mapped.payment_event_count,mapped.settled_event_count,mapped.returned_event_count,
 mapped.retry_event_count,mapped.exception_case_count,mapped.resolved_exception_count,
 mapped.unresolved_exception_count,mapped.source_exposure_amount,
 mapped.certified_exposure_amount,mapped.scheduled_payment_amount,
 mapped.processed_payment_amount,mapped.returned_payment_amount,
 mapped.retry_payment_amount,mapped.reconciliation_variance_amount,
 mapped.exposure_variance_amount,
 CASE WHEN mapped.scheduled_payment_amount>0 THEN
  round(mapped.processed_payment_amount/mapped.scheduled_payment_amount,6) END AS gross_collection_rate,
 CASE WHEN mapped.scheduled_payment_amount>0 THEN
  round(mapped.returned_payment_amount/mapped.scheduled_payment_amount,6) END AS return_rate,
 CASE WHEN mapped.returned_payment_amount>0 THEN
  round(mapped.retry_payment_amount/mapped.returned_payment_amount,6) END AS retry_cure_rate,
 CASE WHEN mapped.source_exposure_amount>0 THEN
  round(mapped.certified_exposure_amount/mapped.source_exposure_amount,6) END AS exposure_retention_rate,
 tier.burden_units AS servicing_burden_units,mapped.primary_portfolio_reason_code,
 to_jsonb(array_remove(ARRAY[
  'M2_10_REASON_SOURCE_CERTIFIED',mapped.primary_portfolio_reason_code,
  CASE WHEN mapped.payment_event_count>0 THEN 'M2_10_REASON_PAYMENT_ACTIVITY_PRESENT'
       ELSE 'M2_10_REASON_NO_PAYMENT_ACTIVITY' END,
  CASE WHEN mapped.scheduled_payment_amount>0
        AND mapped.processed_payment_amount=mapped.scheduled_payment_amount
       THEN 'M2_10_REASON_COLLECTION_COMPLETE' END,
  CASE WHEN mapped.returned_payment_amount>0 THEN 'M2_10_REASON_RETURN_PRESENT' END,
  CASE WHEN mapped.returned_payment_amount>0
        AND mapped.retry_payment_amount=mapped.returned_payment_amount
       THEN 'M2_10_REASON_RETRY_CURED' END,
  CASE WHEN mapped.exception_case_count=0 THEN 'M2_10_REASON_NO_EXCEPTION'
       ELSE 'M2_10_REASON_EXCEPTION_RESOLVED' END,
  CASE WHEN mapped.unresolved_exception_count=0 THEN 'M2_10_REASON_NO_UNRESOLVED_EXCEPTION' END,
  CASE WHEN mapped.reconciliation_variance_amount=0 THEN 'M2_10_REASON_ZERO_RECON_VARIANCE' END,
  CASE WHEN mapped.exposure_variance_amount=0 THEN 'M2_10_REASON_ZERO_EXPOSURE_VARIANCE' END,
  CASE WHEN mapped.active_state_flag THEN 'M2_10_REASON_ACTIVE_EXPOSURE'
       WHEN mapped.review_hold_state_flag THEN 'M2_10_REASON_REVIEW_HOLD_EXPOSURE' END,
  CASE mapped.servicing_queue_code
       WHEN 'NO_SERVICING_REQUIRED' THEN 'M2_10_REASON_NO_SERVICING_QUEUE'
       WHEN 'ACTIVE_REASSESSMENT' THEN 'M2_10_REASON_ACTIVE_REASSESSMENT_QUEUE'
       ELSE 'M2_10_REASON_GOVERNANCE_REVIEW_QUEUE' END,
  'M2_10_REASON_SOURCE_HASH_PRESENT','M2_10_REASON_HISTORY_PRESERVED',
  'M2_10_REASON_SYNTHETIC_ONLY']::text[],NULL)) AS portfolio_reason_codes,
 FALSE::boolean AS production_decision_executed_flag,
 FALSE::boolean AS external_system_updated_flag,
 FALSE::boolean AS merchant_contact_executed_flag,
 mapped.source_contract_row_hash,mapped.row_hash AS source_snapshot_row_hash,
 ctx.configuration_hash AS policy_configuration_hash,NULL::text AS row_hash
FROM _m2_10_source_classified AS mapped
JOIN msbf_m2.portfolio_performance_tier_definition AS tier
 ON tier.module1_run_id=mapped.module1_run_id
AND tier.performance_tier_code=mapped.performance_tier_code
CROSS JOIN _m2_10_ctx AS ctx;

UPDATE _m2_10_performance_expected AS performance
SET row_hash=msbf_ctl.m2_10_hash_jsonb(to_jsonb(performance)-'row_hash')
WHERE performance.row_hash IS NULL;
CREATE UNIQUE INDEX ON _m2_10_performance_expected
(module1_run_id,scenario_id,merchant_application_id);
CREATE INDEX ON _m2_10_performance_expected
(module1_run_id,scenario_code,performance_tier_code);
CREATE INDEX ON _m2_10_performance_expected
(module1_run_id,servicing_queue_code);
ANALYZE _m2_10_performance_expected;

DO $m2_10_performance_guard$
DECLARE v record;
BEGIN
 SELECT count(*) AS account_rows,
  count(*) FILTER(WHERE scenario_code='BASELINE') AS baseline_rows,
  count(*) FILTER(WHERE scenario_code='RECESSION_ENERGY') AS stress_rows,
  count(*) FILTER(WHERE performance_tier_code='CLOSED_STABLE') AS closed_rows,
  count(*) FILTER(WHERE performance_tier_code='ACTIVE_RECONCILED') AS active_rows,
  count(*) FILTER(WHERE performance_tier_code='CONTROLLED_REVIEW') AS review_rows,
  count(*) FILTER(WHERE servicing_queue_code='NO_SERVICING_REQUIRED') AS no_queue_rows,
  count(*) FILTER(WHERE servicing_queue_code='ACTIVE_REASSESSMENT') AS active_queue_rows,
  count(*) FILTER(WHERE servicing_queue_code='GOVERNANCE_REVIEW_HOLD') AS review_queue_rows,
  count(*) FILTER(WHERE state_certified_flag) AS certified_rows,
  round(sum(certified_exposure_amount),2) AS certified_exposure,
  round(sum(CASE WHEN performance_tier_code='ACTIVE_RECONCILED' THEN certified_exposure_amount ELSE 0 END),2) AS active_exposure,
  round(sum(CASE WHEN performance_tier_code='CONTROLLED_REVIEW' THEN certified_exposure_amount ELSE 0 END),2) AS review_exposure,
  round(sum(scheduled_payment_amount),2) AS scheduled_amount,
  round(sum(processed_payment_amount),2) AS processed_amount,
  round(sum(returned_payment_amount),2) AS returned_amount,
  round(sum(retry_payment_amount),2) AS retry_amount,
  round(sum(abs(reconciliation_variance_amount)),2) AS recon_variance,
  round(sum(abs(exposure_variance_amount)),2) AS exposure_variance,
  sum(exception_case_count) AS exception_cases,
  sum(resolved_exception_count) AS resolved_exceptions,
  sum(unresolved_exception_count) AS unresolved_exceptions,
  round(sum(servicing_burden_units),6) AS burden_units,
  count(*) FILTER(WHERE production_decision_executed_flag
    OR external_system_updated_flag OR merchant_contact_executed_flag) AS boundary_rows
 INTO v FROM _m2_10_performance_expected;
 IF v.account_rows<>59 OR v.baseline_rows<>44 OR v.stress_rows<>15
  OR v.closed_rows<>57 OR v.active_rows<>1 OR v.review_rows<>1
  OR v.no_queue_rows<>57 OR v.active_queue_rows<>1 OR v.review_queue_rows<>1
  OR v.certified_rows<>59 OR v.certified_exposure<>785.48
  OR v.active_exposure<>323.79 OR v.review_exposure<>461.69
  OR v.scheduled_amount<>194.25 OR v.processed_amount<>194.25
  OR v.returned_amount<>27.75 OR v.retry_amount<>27.75
  OR v.recon_variance<>0 OR v.exposure_variance<>0
  OR v.exception_cases<>1 OR v.resolved_exceptions<>1 OR v.unresolved_exceptions<>0
  OR v.burden_units<>7.000000 OR v.boundary_rows<>0
 THEN RAISE EXCEPTION 'M2.10 account performance generation failed: %.',row_to_json(v);
 END IF;
END;
$m2_10_performance_guard$;

INSERT INTO msbf_m2.application_portfolio_performance_snapshot
(
 module1_run_id,scenario_id,scenario_code,merchant_application_id,merchant_id,
 synthetic_account_id,synthetic_advance_id,source_final_lifecycle_state_code,
 certified_state_code,state_certified_flag,performance_tier_code,servicing_queue_code,
 payment_activity_flag,exception_incident_flag,exception_resolved_flag,
 payment_event_count,settled_event_count,returned_event_count,retry_event_count,
 exception_case_count,resolved_exception_count,unresolved_exception_count,
 source_exposure_amount,certified_exposure_amount,scheduled_payment_amount,
 processed_payment_amount,returned_payment_amount,retry_payment_amount,
 reconciliation_variance_amount,exposure_variance_amount,gross_collection_rate,
 return_rate,retry_cure_rate,exposure_retention_rate,servicing_burden_units,
 primary_portfolio_reason_code,portfolio_reason_codes,
 production_decision_executed_flag,external_system_updated_flag,
 merchant_contact_executed_flag,source_contract_row_hash,source_snapshot_row_hash,
 policy_configuration_hash,row_hash
)
SELECT module1_run_id,scenario_id,scenario_code,merchant_application_id,merchant_id,
 synthetic_account_id,synthetic_advance_id,source_final_lifecycle_state_code,
 certified_state_code,state_certified_flag,performance_tier_code,servicing_queue_code,
 payment_activity_flag,exception_incident_flag,exception_resolved_flag,
 payment_event_count,settled_event_count,returned_event_count,retry_event_count,
 exception_case_count,resolved_exception_count,unresolved_exception_count,
 source_exposure_amount,certified_exposure_amount,scheduled_payment_amount,
 processed_payment_amount,returned_payment_amount,retry_payment_amount,
 reconciliation_variance_amount,exposure_variance_amount,gross_collection_rate,
 return_rate,retry_cure_rate,exposure_retention_rate,servicing_burden_units,
 primary_portfolio_reason_code,portfolio_reason_codes,
 production_decision_executed_flag,external_system_updated_flag,
 merchant_contact_executed_flag,source_contract_row_hash,source_snapshot_row_hash,
 policy_configuration_hash,row_hash
FROM _m2_10_performance_expected;

/* ============================================================================
Section 4 — Portfolio and scenario scope summaries
============================================================================ */

DROP TABLE IF EXISTS _m2_10_scope_expected;
CREATE TEMP TABLE _m2_10_scope_expected ON COMMIT DROP AS
WITH base AS
(
 SELECT performance.module1_run_id,'PORTFOLIO_ALL'::text AS scope_code,
  'PORTFOLIO'::text AS scope_type,NULL::text AS scenario_code,
  performance.state_certified_flag,performance.performance_tier_code,
  performance.certified_exposure_amount,performance.scheduled_payment_amount,
  performance.processed_payment_amount,performance.returned_payment_amount,
  performance.retry_payment_amount,performance.reconciliation_variance_amount,
  performance.exposure_variance_amount,performance.exception_case_count,
  performance.resolved_exception_count,performance.unresolved_exception_count,
  performance.servicing_burden_units
 FROM _m2_10_performance_expected AS performance
 UNION ALL
 SELECT performance.module1_run_id,performance.scenario_code,'SCENARIO',
  performance.scenario_code,performance.state_certified_flag,
  performance.performance_tier_code,performance.certified_exposure_amount,
  performance.scheduled_payment_amount,performance.processed_payment_amount,
  performance.returned_payment_amount,performance.retry_payment_amount,
  performance.reconciliation_variance_amount,performance.exposure_variance_amount,
  performance.exception_case_count,performance.resolved_exception_count,
  performance.unresolved_exception_count,performance.servicing_burden_units
 FROM _m2_10_performance_expected AS performance
), aggregated AS
(
 SELECT module1_run_id,scope_code,scope_type,scenario_code,
  count(*)::bigint AS account_count,
  count(*) FILTER(WHERE state_certified_flag)::bigint AS certified_account_count,
  count(*) FILTER(WHERE performance_tier_code='ACTIVE_RECONCILED')::bigint AS active_account_count,
  count(*) FILTER(WHERE performance_tier_code='CLOSED_STABLE')::bigint AS closed_account_count,
  count(*) FILTER(WHERE performance_tier_code='CONTROLLED_REVIEW')::bigint AS review_hold_account_count,
  round(sum(certified_exposure_amount),2) AS certified_exposure_amount,
  round(sum(CASE WHEN performance_tier_code='ACTIVE_RECONCILED' THEN certified_exposure_amount ELSE 0 END),2) AS active_exposure_amount,
  round(sum(CASE WHEN performance_tier_code='CONTROLLED_REVIEW' THEN certified_exposure_amount ELSE 0 END),2) AS review_hold_exposure_amount,
  round(sum(scheduled_payment_amount),2) AS scheduled_payment_amount,
  round(sum(processed_payment_amount),2) AS processed_payment_amount,
  round(sum(returned_payment_amount),2) AS returned_payment_amount,
  round(sum(retry_payment_amount),2) AS retry_payment_amount,
  round(sum(abs(reconciliation_variance_amount)),2) AS reconciliation_variance_amount,
  round(sum(abs(exposure_variance_amount)),2) AS exposure_variance_amount,
  sum(exception_case_count)::bigint AS exception_case_count,
  sum(resolved_exception_count)::bigint AS resolved_exception_count,
  sum(unresolved_exception_count)::bigint AS unresolved_exception_count,
  round(sum(servicing_burden_units),6) AS servicing_burden_units
 FROM base GROUP BY module1_run_id,scope_code,scope_type,scenario_code
)
SELECT aggregated.*,
 round(certified_account_count::numeric/account_count,6)::numeric(18,6) AS certification_rate,
 CASE WHEN scheduled_payment_amount>0 THEN round(processed_payment_amount/scheduled_payment_amount,6) END::numeric(18,6) AS gross_collection_rate,
 CASE WHEN scheduled_payment_amount>0 THEN round(returned_payment_amount/scheduled_payment_amount,6) END::numeric(18,6) AS return_rate,
 CASE WHEN returned_payment_amount>0 THEN round(retry_payment_amount/returned_payment_amount,6) END::numeric(18,6) AS retry_cure_rate,
 CASE WHEN exception_case_count>0 THEN round(resolved_exception_count::numeric/exception_case_count,6) END::numeric(18,6) AS exception_resolution_rate,
 round(servicing_burden_units/account_count,6)::numeric(18,6) AS average_burden_per_account,
 NULL::text AS row_hash
FROM aggregated;

UPDATE _m2_10_scope_expected AS scope
SET row_hash=msbf_ctl.m2_10_hash_jsonb(to_jsonb(scope)-'row_hash')
WHERE scope.row_hash IS NULL;
CREATE UNIQUE INDEX ON _m2_10_scope_expected(module1_run_id,scope_code);
ANALYZE _m2_10_scope_expected;

DO $m2_10_scope_guard$
DECLARE v record;
BEGIN
 SELECT count(*) AS scope_rows,
  max(account_count) FILTER(WHERE scope_code='PORTFOLIO_ALL') AS portfolio_accounts,
  max(account_count) FILTER(WHERE scope_code='BASELINE') AS baseline_accounts,
  max(account_count) FILTER(WHERE scope_code='RECESSION_ENERGY') AS stress_accounts,
  max(certified_account_count) FILTER(WHERE scope_code='PORTFOLIO_ALL') AS certified_accounts,
  max(certification_rate) FILTER(WHERE scope_code='PORTFOLIO_ALL') AS certification_rate,
  max(certified_exposure_amount) FILTER(WHERE scope_code='PORTFOLIO_ALL') AS certified_exposure,
  max(gross_collection_rate) FILTER(WHERE scope_code='PORTFOLIO_ALL') AS collection_rate,
  max(return_rate) FILTER(WHERE scope_code='PORTFOLIO_ALL') AS return_rate,
  max(retry_cure_rate) FILTER(WHERE scope_code='PORTFOLIO_ALL') AS retry_cure_rate,
  max(exception_resolution_rate) FILTER(WHERE scope_code='PORTFOLIO_ALL') AS exception_resolution_rate,
  max(servicing_burden_units) FILTER(WHERE scope_code='PORTFOLIO_ALL') AS burden_units,
  max(average_burden_per_account) FILTER(WHERE scope_code='PORTFOLIO_ALL') AS average_burden
 INTO v FROM _m2_10_scope_expected;
 IF v.scope_rows<>3 OR v.portfolio_accounts<>59 OR v.baseline_accounts<>44
  OR v.stress_accounts<>15 OR v.certified_accounts<>59
  OR v.certification_rate<>1.000000 OR v.certified_exposure<>785.48
  OR v.collection_rate<>1.000000 OR v.return_rate<>0.142857
  OR v.retry_cure_rate<>1.000000 OR v.exception_resolution_rate<>1.000000
  OR v.burden_units<>7.000000 OR v.average_burden<>0.118644
 THEN RAISE EXCEPTION 'M2.10 scope summary failed: %.',row_to_json(v);
 END IF;
END;
$m2_10_scope_guard$;

INSERT INTO msbf_m2.portfolio_performance_scope_summary
(
 module1_run_id,scope_code,scope_type,scenario_code,account_count,
 certified_account_count,active_account_count,closed_account_count,
 review_hold_account_count,certified_exposure_amount,active_exposure_amount,
 review_hold_exposure_amount,scheduled_payment_amount,processed_payment_amount,
 returned_payment_amount,retry_payment_amount,reconciliation_variance_amount,
 exposure_variance_amount,exception_case_count,resolved_exception_count,
 unresolved_exception_count,servicing_burden_units,certification_rate,
 gross_collection_rate,return_rate,retry_cure_rate,exception_resolution_rate,
 average_burden_per_account,row_hash
)
SELECT module1_run_id,scope_code,scope_type,scenario_code,account_count,
 certified_account_count,active_account_count,closed_account_count,
 review_hold_account_count,certified_exposure_amount,active_exposure_amount,
 review_hold_exposure_amount,scheduled_payment_amount,processed_payment_amount,
 returned_payment_amount,retry_payment_amount,reconciliation_variance_amount,
 exposure_variance_amount,exception_case_count,resolved_exception_count,
 unresolved_exception_count,servicing_burden_units,certification_rate,
 gross_collection_rate,return_rate,retry_cure_rate,exception_resolution_rate,
 average_burden_per_account,row_hash
FROM _m2_10_scope_expected;

/* ============================================================================
Section 5 — Governed KPI facts
============================================================================ */

DROP TABLE IF EXISTS _m2_10_kpi_expected;
CREATE TEMP TABLE _m2_10_kpi_expected ON COMMIT DROP AS
SELECT scope.module1_run_id,scope.scope_code,scope.scope_type,scope.scenario_code,
 definition.kpi_code,definition.kpi_rank,definition.unit_code,
 value.applicable_flag,value.kpi_value_numeric,value.kpi_value_text,
 value.numerator_value,value.denominator_value,
 CASE WHEN value.applicable_flag THEN 'M2_10_REASON_KPI_APPLICABLE'
      ELSE 'M2_10_REASON_KPI_NOT_APPLICABLE' END AS primary_portfolio_reason_code,
 scope.row_hash AS source_scope_row_hash,NULL::text AS row_hash
FROM _m2_10_scope_expected AS scope
CROSS JOIN LATERAL
(
 VALUES
 ('ACCOUNT_COUNT'::text,scope.account_count::numeric(28,10),NULL::text,TRUE,scope.account_count::numeric(28,10),NULL::numeric(28,10)),
 ('CERTIFIED_ACCOUNT_COUNT',scope.certified_account_count::numeric(28,10),NULL,TRUE,scope.certified_account_count::numeric(28,10),NULL),
 ('CERTIFICATION_RATE',scope.certification_rate::numeric(28,10),NULL,TRUE,scope.certified_account_count::numeric(28,10),scope.account_count::numeric(28,10)),
 ('ACTIVE_ACCOUNT_COUNT',scope.active_account_count::numeric(28,10),NULL,TRUE,scope.active_account_count::numeric(28,10),NULL),
 ('CLOSED_ACCOUNT_COUNT',scope.closed_account_count::numeric(28,10),NULL,TRUE,scope.closed_account_count::numeric(28,10),NULL),
 ('REVIEW_HOLD_ACCOUNT_COUNT',scope.review_hold_account_count::numeric(28,10),NULL,TRUE,scope.review_hold_account_count::numeric(28,10),NULL),
 ('CERTIFIED_EXPOSURE_AMOUNT',scope.certified_exposure_amount::numeric(28,10),NULL,TRUE,scope.certified_exposure_amount::numeric(28,10),NULL),
 ('ACTIVE_EXPOSURE_AMOUNT',scope.active_exposure_amount::numeric(28,10),NULL,TRUE,scope.active_exposure_amount::numeric(28,10),NULL),
 ('REVIEW_HOLD_EXPOSURE_AMOUNT',scope.review_hold_exposure_amount::numeric(28,10),NULL,TRUE,scope.review_hold_exposure_amount::numeric(28,10),NULL),
 ('SCHEDULED_PAYMENT_AMOUNT',scope.scheduled_payment_amount::numeric(28,10),NULL,TRUE,scope.scheduled_payment_amount::numeric(28,10),NULL),
 ('PROCESSED_PAYMENT_AMOUNT',scope.processed_payment_amount::numeric(28,10),NULL,TRUE,scope.processed_payment_amount::numeric(28,10),NULL),
 ('GROSS_COLLECTION_RATE',CASE WHEN scope.scheduled_payment_amount>0 THEN scope.gross_collection_rate::numeric(28,10) END,CASE WHEN scope.scheduled_payment_amount=0 THEN 'NOT_APPLICABLE' END,scope.scheduled_payment_amount>0,scope.processed_payment_amount::numeric(28,10),scope.scheduled_payment_amount::numeric(28,10)),
 ('RETURNED_PAYMENT_AMOUNT',scope.returned_payment_amount::numeric(28,10),NULL,TRUE,scope.returned_payment_amount::numeric(28,10),NULL),
 ('RETURN_RATE',CASE WHEN scope.scheduled_payment_amount>0 THEN scope.return_rate::numeric(28,10) END,CASE WHEN scope.scheduled_payment_amount=0 THEN 'NOT_APPLICABLE' END,scope.scheduled_payment_amount>0,scope.returned_payment_amount::numeric(28,10),scope.scheduled_payment_amount::numeric(28,10)),
 ('RETRY_PAYMENT_AMOUNT',scope.retry_payment_amount::numeric(28,10),NULL,TRUE,scope.retry_payment_amount::numeric(28,10),NULL),
 ('RETRY_CURE_RATE',CASE WHEN scope.returned_payment_amount>0 THEN scope.retry_cure_rate::numeric(28,10) END,CASE WHEN scope.returned_payment_amount=0 THEN 'NOT_APPLICABLE' END,scope.returned_payment_amount>0,scope.retry_payment_amount::numeric(28,10),scope.returned_payment_amount::numeric(28,10)),
 ('RECONCILIATION_VARIANCE_AMOUNT',scope.reconciliation_variance_amount::numeric(28,10),NULL,TRUE,scope.reconciliation_variance_amount::numeric(28,10),NULL),
 ('EXPOSURE_VARIANCE_AMOUNT',scope.exposure_variance_amount::numeric(28,10),NULL,TRUE,scope.exposure_variance_amount::numeric(28,10),NULL),
 ('EXCEPTION_CASE_COUNT',scope.exception_case_count::numeric(28,10),NULL,TRUE,scope.exception_case_count::numeric(28,10),NULL),
 ('RESOLVED_EXCEPTION_COUNT',scope.resolved_exception_count::numeric(28,10),NULL,TRUE,scope.resolved_exception_count::numeric(28,10),NULL),
 ('EXCEPTION_RESOLUTION_RATE',CASE WHEN scope.exception_case_count>0 THEN scope.exception_resolution_rate::numeric(28,10) END,CASE WHEN scope.exception_case_count=0 THEN 'NOT_APPLICABLE' END,scope.exception_case_count>0,scope.resolved_exception_count::numeric(28,10),scope.exception_case_count::numeric(28,10)),
 ('UNRESOLVED_EXCEPTION_COUNT',scope.unresolved_exception_count::numeric(28,10),NULL,TRUE,scope.unresolved_exception_count::numeric(28,10),NULL),
 ('SERVICING_BURDEN_UNITS',scope.servicing_burden_units::numeric(28,10),NULL,TRUE,scope.servicing_burden_units::numeric(28,10),NULL),
 ('AVERAGE_BURDEN_PER_ACCOUNT',scope.average_burden_per_account::numeric(28,10),NULL,TRUE,scope.servicing_burden_units::numeric(28,10),scope.account_count::numeric(28,10))
) AS value(kpi_code,kpi_value_numeric,kpi_value_text,applicable_flag,numerator_value,denominator_value)
JOIN msbf_m2.portfolio_kpi_definition AS definition
 ON definition.module1_run_id=scope.module1_run_id
AND definition.kpi_code=value.kpi_code;

UPDATE _m2_10_kpi_expected AS kpi
SET row_hash=msbf_ctl.m2_10_hash_jsonb(to_jsonb(kpi)-'row_hash')
WHERE kpi.row_hash IS NULL;
CREATE UNIQUE INDEX ON _m2_10_kpi_expected(module1_run_id,scope_code,kpi_code);
CREATE INDEX ON _m2_10_kpi_expected(module1_run_id,kpi_rank,scope_code);
ANALYZE _m2_10_kpi_expected;

DO $m2_10_kpi_guard$
DECLARE v record;
BEGIN
 SELECT count(*) AS kpi_rows,count(DISTINCT scope_code) AS scopes,
  count(DISTINCT kpi_code) AS kpis,
  count(*) FILTER(WHERE applicable_flag) AS applicable_rows,
  count(*) FILTER(WHERE NOT applicable_flag) AS not_applicable_rows,
  count(*) FILTER(WHERE scope_code='PORTFOLIO_ALL' AND kpi_code='GROSS_COLLECTION_RATE' AND kpi_value_numeric=1) AS portfolio_collection_rows,
  count(*) FILTER(WHERE scope_code='PORTFOLIO_ALL' AND kpi_code='SERVICING_BURDEN_UNITS' AND kpi_value_numeric=7) AS portfolio_burden_rows
 INTO v FROM _m2_10_kpi_expected;
 IF v.kpi_rows<>72 OR v.scopes<>3 OR v.kpis<>24 OR v.applicable_rows<>68
  OR v.not_applicable_rows<>4 OR v.portfolio_collection_rows<>1 OR v.portfolio_burden_rows<>1
 THEN RAISE EXCEPTION 'M2.10 KPI snapshot failed: %.',row_to_json(v);
 END IF;
END;
$m2_10_kpi_guard$;

INSERT INTO msbf_m2.portfolio_kpi_snapshot
(module1_run_id,scope_code,scope_type,scenario_code,kpi_code,kpi_rank,unit_code,
 applicable_flag,kpi_value_numeric,kpi_value_text,numerator_value,denominator_value,
 primary_portfolio_reason_code,source_scope_row_hash,row_hash)
SELECT module1_run_id,scope_code,scope_type,scenario_code,kpi_code,kpi_rank,unit_code,
 applicable_flag,kpi_value_numeric,kpi_value_text,numerator_value,denominator_value,
 primary_portfolio_reason_code,source_scope_row_hash,row_hash
FROM _m2_10_kpi_expected;

/* ============================================================================
Section 6 — Servicing queue analytics
============================================================================ */

DROP TABLE IF EXISTS _m2_10_queue_expected;
CREATE TEMP TABLE _m2_10_queue_expected ON COMMIT DROP AS
SELECT performance.module1_run_id,performance.servicing_queue_code,
 count(*)::bigint AS account_count,count(DISTINCT performance.scenario_code)::bigint AS scenario_count,
 round(sum(performance.certified_exposure_amount),2) AS certified_exposure_amount,
 sum(performance.payment_event_count)::bigint AS payment_event_count,
 sum(performance.exception_case_count)::bigint AS exception_case_count,
 sum(performance.resolved_exception_count)::bigint AS resolved_exception_count,
 sum(performance.unresolved_exception_count)::bigint AS unresolved_exception_count,
 round(sum(performance.servicing_burden_units),6) AS servicing_burden_units,
 max(tier.performance_tier_rank) AS maximum_tier_rank,NULL::text AS row_hash
FROM _m2_10_performance_expected AS performance
JOIN msbf_m2.portfolio_performance_tier_definition AS tier
 ON tier.module1_run_id=performance.module1_run_id
AND tier.performance_tier_code=performance.performance_tier_code
GROUP BY performance.module1_run_id,performance.servicing_queue_code;

UPDATE _m2_10_queue_expected AS queue
SET row_hash=msbf_ctl.m2_10_hash_jsonb(to_jsonb(queue)-'row_hash')
WHERE queue.row_hash IS NULL;
CREATE UNIQUE INDEX ON _m2_10_queue_expected(module1_run_id,servicing_queue_code);
ANALYZE _m2_10_queue_expected;

DO $m2_10_queue_guard$
DECLARE v record;
BEGIN
 SELECT count(*) AS queue_rows,sum(account_count) AS account_rows,
  round(sum(certified_exposure_amount),2) AS certified_exposure,
  sum(payment_event_count) AS payment_events,sum(exception_case_count) AS exception_cases,
  sum(resolved_exception_count) AS resolved_exceptions,
  sum(unresolved_exception_count) AS unresolved_exceptions,
  round(sum(servicing_burden_units),6) AS burden_units
 INTO v FROM _m2_10_queue_expected;
 IF v.queue_rows<>3 OR v.account_rows<>59 OR v.certified_exposure<>785.48
  OR v.payment_events<>7 OR v.exception_cases<>1 OR v.resolved_exceptions<>1
  OR v.unresolved_exceptions<>0 OR v.burden_units<>7.000000
 THEN RAISE EXCEPTION 'M2.10 queue analytics failed: %.',row_to_json(v);
 END IF;
END;
$m2_10_queue_guard$;

INSERT INTO msbf_m2.servicing_queue_analytics_snapshot
(module1_run_id,servicing_queue_code,account_count,scenario_count,
 certified_exposure_amount,payment_event_count,exception_case_count,
 resolved_exception_count,unresolved_exception_count,servicing_burden_units,
 maximum_tier_rank,row_hash)
SELECT module1_run_id,servicing_queue_code,account_count,scenario_count,
 certified_exposure_amount,payment_event_count,exception_case_count,
 resolved_exception_count,unresolved_exception_count,servicing_burden_units,
 maximum_tier_rank,row_hash FROM _m2_10_queue_expected;

/* ============================================================================
Section 7 — Latest and immutable archive contracts
============================================================================ */

DROP TABLE IF EXISTS _m2_10_latest_expected;
CREATE TEMP TABLE _m2_10_latest_expected ON COMMIT DROP AS
SELECT performance.module1_run_id,'M2_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_CONSUMPTION'::text AS contract_code,
 1::integer AS contract_version,'M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_SCHEMA_V1'::text AS schema_version,
 'M2_10_METHOD_V1'::text AS methodology_version,performance.scenario_id,
 performance.scenario_code,performance.merchant_application_id,performance.merchant_id,
 performance.synthetic_account_id,performance.synthetic_advance_id,
 performance.source_final_lifecycle_state_code,performance.certified_state_code,
 performance.state_certified_flag,performance.performance_tier_code,
 performance.servicing_queue_code,performance.payment_activity_flag,
 performance.exception_incident_flag,performance.exception_resolved_flag,
 performance.payment_event_count,performance.settled_event_count,
 performance.returned_event_count,performance.retry_event_count,
 performance.exception_case_count,performance.resolved_exception_count,
 performance.unresolved_exception_count,performance.source_exposure_amount,
 performance.certified_exposure_amount,performance.scheduled_payment_amount,
 performance.processed_payment_amount,performance.returned_payment_amount,
 performance.retry_payment_amount,performance.reconciliation_variance_amount,
 performance.exposure_variance_amount,performance.gross_collection_rate,
 performance.return_rate,performance.retry_cure_rate,
 performance.exposure_retention_rate,performance.servicing_burden_units,
 performance.primary_portfolio_reason_code,performance.portfolio_reason_codes,
 performance.source_contract_row_hash,performance.source_snapshot_row_hash,
 performance.row_hash AS performance_snapshot_row_hash,
 performance.policy_configuration_hash,NULL::text AS contract_row_hash
FROM _m2_10_performance_expected AS performance;

UPDATE _m2_10_latest_expected AS latest
SET contract_row_hash=msbf_ctl.m2_10_hash_jsonb(to_jsonb(latest)-'contract_row_hash')
WHERE latest.contract_row_hash IS NULL;
CREATE UNIQUE INDEX ON _m2_10_latest_expected(module1_run_id,scenario_id,merchant_application_id);
ANALYZE _m2_10_latest_expected;

DO $m2_10_latest_hash_guard$
DECLARE v_null bigint; v_invalid bigint;
BEGIN
 SELECT count(*) FILTER(WHERE contract_row_hash IS NULL),
  count(*) FILTER(WHERE contract_row_hash IS NOT NULL
    AND (length(contract_row_hash)<>32 OR contract_row_hash!~'^[0-9a-f]+$'))
 INTO v_null,v_invalid FROM _m2_10_latest_expected;
 IF v_null<>0 OR v_invalid<>0 THEN
  RAISE EXCEPTION 'M2.10 latest staging hash failed: null %, invalid %.',v_null,v_invalid;
 END IF;
END;
$m2_10_latest_hash_guard$;

INSERT INTO msbf_m2.application_portfolio_performance_latest
(
 module1_run_id,contract_code,contract_version,schema_version,
 methodology_version,scenario_id,scenario_code,merchant_application_id,
 merchant_id,synthetic_account_id,synthetic_advance_id,
 source_final_lifecycle_state_code,certified_state_code,state_certified_flag,
 performance_tier_code,servicing_queue_code,payment_activity_flag,
 exception_incident_flag,exception_resolved_flag,payment_event_count,
 settled_event_count,returned_event_count,retry_event_count,
 exception_case_count,resolved_exception_count,unresolved_exception_count,
 source_exposure_amount,certified_exposure_amount,scheduled_payment_amount,
 processed_payment_amount,returned_payment_amount,retry_payment_amount,
 reconciliation_variance_amount,exposure_variance_amount,
 gross_collection_rate,return_rate,retry_cure_rate,exposure_retention_rate,
 servicing_burden_units,primary_portfolio_reason_code,portfolio_reason_codes,
 source_contract_row_hash,source_snapshot_row_hash,
 performance_snapshot_row_hash,policy_configuration_hash,contract_row_hash,
 created_at
)
SELECT module1_run_id,contract_code,contract_version,schema_version,
 methodology_version,scenario_id,scenario_code,merchant_application_id,
 merchant_id,synthetic_account_id,synthetic_advance_id,
 source_final_lifecycle_state_code,certified_state_code,state_certified_flag,
 performance_tier_code,servicing_queue_code,payment_activity_flag,
 exception_incident_flag,exception_resolved_flag,payment_event_count,
 settled_event_count,returned_event_count,retry_event_count,
 exception_case_count,resolved_exception_count,unresolved_exception_count,
 source_exposure_amount,certified_exposure_amount,scheduled_payment_amount,
 processed_payment_amount,returned_payment_amount,retry_payment_amount,
 reconciliation_variance_amount,exposure_variance_amount,
 gross_collection_rate,return_rate,retry_cure_rate,exposure_retention_rate,
 servicing_burden_units,primary_portfolio_reason_code,portfolio_reason_codes,
 source_contract_row_hash,source_snapshot_row_hash,
 performance_snapshot_row_hash,policy_configuration_hash,contract_row_hash,
 clock_timestamp()
FROM _m2_10_latest_expected AS latest;

DROP TABLE IF EXISTS _m2_10_archive_expected;
CREATE TEMP TABLE _m2_10_archive_expected ON COMMIT DROP AS
SELECT latest.*,to_jsonb(latest) AS contract_payload,NULL::text AS archive_row_hash
FROM _m2_10_latest_expected AS latest;
UPDATE _m2_10_archive_expected AS archive
SET archive_row_hash=msbf_ctl.m2_10_hash_jsonb(to_jsonb(archive)-'archive_row_hash')
WHERE archive.archive_row_hash IS NULL;

INSERT INTO msbf_m2.application_portfolio_performance_archive
(
 module1_run_id,contract_code,contract_version,schema_version,methodology_version,
 scenario_id,scenario_code,merchant_application_id,merchant_id,synthetic_account_id,
 synthetic_advance_id,source_final_lifecycle_state_code,certified_state_code,
 state_certified_flag,performance_tier_code,servicing_queue_code,
 payment_activity_flag,exception_incident_flag,exception_resolved_flag,
 payment_event_count,settled_event_count,returned_event_count,retry_event_count,
 exception_case_count,resolved_exception_count,unresolved_exception_count,
 source_exposure_amount,certified_exposure_amount,scheduled_payment_amount,
 processed_payment_amount,returned_payment_amount,retry_payment_amount,
 reconciliation_variance_amount,exposure_variance_amount,gross_collection_rate,
 return_rate,retry_cure_rate,exposure_retention_rate,servicing_burden_units,
 primary_portfolio_reason_code,portfolio_reason_codes,source_contract_row_hash,
 source_snapshot_row_hash,performance_snapshot_row_hash,policy_configuration_hash,
 contract_row_hash,contract_payload,archive_row_hash
)
SELECT module1_run_id,contract_code,contract_version,schema_version,methodology_version,
 scenario_id,scenario_code,merchant_application_id,merchant_id,synthetic_account_id,
 synthetic_advance_id,source_final_lifecycle_state_code,certified_state_code,
 state_certified_flag,performance_tier_code,servicing_queue_code,
 payment_activity_flag,exception_incident_flag,exception_resolved_flag,
 payment_event_count,settled_event_count,returned_event_count,retry_event_count,
 exception_case_count,resolved_exception_count,unresolved_exception_count,
 source_exposure_amount,certified_exposure_amount,scheduled_payment_amount,
 processed_payment_amount,returned_payment_amount,retry_payment_amount,
 reconciliation_variance_amount,exposure_variance_amount,gross_collection_rate,
 return_rate,retry_cure_rate,exposure_retention_rate,servicing_burden_units,
 primary_portfolio_reason_code,portfolio_reason_codes,source_contract_row_hash,
 source_snapshot_row_hash,performance_snapshot_row_hash,policy_configuration_hash,
 contract_row_hash,contract_payload,archive_row_hash
FROM _m2_10_archive_expected;

ANALYZE msbf_m2.portfolio_performance_source_snapshot;
ANALYZE msbf_m2.application_portfolio_performance_snapshot;
ANALYZE msbf_m2.portfolio_performance_scope_summary;
ANALYZE msbf_m2.portfolio_kpi_snapshot;
ANALYZE msbf_m2.servicing_queue_analytics_snapshot;
ANALYZE msbf_m2.application_portfolio_performance_latest;
ANALYZE msbf_m2.application_portfolio_performance_archive;

/* ============================================================================
Section 8 — Set hashes and contract registry
============================================================================ */

DROP TABLE IF EXISTS _m2_10_hashes;
CREATE TEMP TABLE _m2_10_hashes ON COMMIT DROP AS
SELECT
 (SELECT md5(string_agg(row_hash,'|' ORDER BY module1_run_id)) FROM msbf_ctl.m2_10_policy_profile WHERE module1_run_id=(SELECT run_id FROM _m2_10_ctx)) AS policy_set_hash,
 (SELECT md5(string_agg(row_hash,'|' ORDER BY kpi_rank,kpi_code)) FROM msbf_m2.portfolio_kpi_definition WHERE module1_run_id=(SELECT run_id FROM _m2_10_ctx)) AS kpi_definition_set_hash,
 (SELECT md5(string_agg(row_hash,'|' ORDER BY performance_tier_rank,performance_tier_code)) FROM msbf_m2.portfolio_performance_tier_definition WHERE module1_run_id=(SELECT run_id FROM _m2_10_ctx)) AS performance_tier_set_hash,
 (SELECT md5(string_agg(row_hash,'|' ORDER BY servicing_queue_rank,servicing_queue_code)) FROM msbf_m2.servicing_queue_definition WHERE module1_run_id=(SELECT run_id FROM _m2_10_ctx)) AS servicing_queue_set_hash,
 (SELECT md5(string_agg(row_hash,'|' ORDER BY portfolio_analytics_reason_code)) FROM msbf_m2.portfolio_analytics_reason_definition WHERE module1_run_id=(SELECT run_id FROM _m2_10_ctx)) AS reason_set_hash,
 (SELECT md5(string_agg(scenario_id::text||'|'||merchant_application_id||'|'||row_hash,'|' ORDER BY scenario_id,merchant_application_id)) FROM _m2_10_source_expected) AS source_set_hash,
 (SELECT md5(string_agg(scenario_id::text||'|'||merchant_application_id||'|'||row_hash,'|' ORDER BY scenario_id,merchant_application_id)) FROM _m2_10_performance_expected) AS account_performance_set_hash,
 (SELECT md5(string_agg(scope_code||'|'||row_hash,'|' ORDER BY scope_code)) FROM _m2_10_scope_expected) AS scope_summary_set_hash,
 (SELECT md5(string_agg(scope_code||'|'||kpi_code||'|'||row_hash,'|' ORDER BY scope_code,kpi_rank,kpi_code)) FROM _m2_10_kpi_expected) AS kpi_snapshot_set_hash,
 (SELECT md5(string_agg(servicing_queue_code||'|'||row_hash,'|' ORDER BY servicing_queue_code)) FROM _m2_10_queue_expected) AS queue_summary_set_hash,
 (SELECT md5(string_agg(scenario_id::text||'|'||merchant_application_id||'|'||contract_row_hash,'|' ORDER BY scenario_id,merchant_application_id)) FROM _m2_10_latest_expected) AS latest_set_hash,
 (SELECT md5(string_agg(scenario_id::text||'|'||merchant_application_id||'|'||archive_row_hash,'|' ORDER BY scenario_id,merchant_application_id)) FROM _m2_10_archive_expected) AS archive_set_hash;

DROP TABLE IF EXISTS _m2_10_registry_expected;
CREATE TEMP TABLE _m2_10_registry_expected ON COMMIT DROP AS
SELECT ctx.run_id AS module1_run_id,'M2_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_CONSUMPTION'::text AS contract_code,
 1::integer AS contract_version,'M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_SCHEMA_V1'::text AS schema_version,
 'M2_10_METHOD_V1'::text AS methodology_version,
 'M2_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_CONSUMPTION'::text AS source_contract_code,1::integer AS source_contract_version,
 'M2_9_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_SCHEMA_V1'::text AS source_schema_version,
 'M2_9_PAYMENT_RECONCILIATION_EXCEPTION_RESOLUTION_ACCOUNT_STATE_CERTIFICATION'::text AS source_acceptance_gate_id,
 '6af76d0059b47623619ebc09330b15fe'::text AS source_combined_set_hash,ctx.configuration_hash AS policy_configuration_hash,
 1::bigint AS policy_rows,24::bigint AS kpi_definition_rows,3::bigint AS performance_tier_rows,
 3::bigint AS servicing_queue_rows,24::bigint AS reason_rows,59::bigint AS source_rows,
 59::bigint AS account_performance_rows,3::bigint AS scope_summary_rows,
 72::bigint AS kpi_snapshot_rows,3::bigint AS queue_summary_rows,59::bigint AS latest_rows,
 59::bigint AS archive_rows,
 (SELECT count(*) FROM msbf_m2.v_m2_10_matched_scenario_comparison WHERE module1_run_id=ctx.run_id)::bigint AS comparison_rows,
 1::bigint AS registry_rows,370::bigint AS canonical_entities,
 scope.account_count AS portfolio_account_rows,
 (SELECT count(*) FROM _m2_10_performance_expected WHERE scenario_code='BASELINE')::bigint AS baseline_account_rows,
 (SELECT count(*) FROM _m2_10_performance_expected WHERE scenario_code='RECESSION_ENERGY')::bigint AS stress_account_rows,
 scope.closed_account_count AS closed_stable_rows,scope.active_account_count AS active_reconciled_rows,
 scope.review_hold_account_count AS controlled_review_rows,
 (SELECT count(*) FROM _m2_10_performance_expected WHERE servicing_queue_code='NO_SERVICING_REQUIRED')::bigint AS no_servicing_queue_rows,
 (SELECT count(*) FROM _m2_10_performance_expected WHERE servicing_queue_code='ACTIVE_REASSESSMENT')::bigint AS active_reassessment_queue_rows,
 (SELECT count(*) FROM _m2_10_performance_expected WHERE servicing_queue_code='GOVERNANCE_REVIEW_HOLD')::bigint AS governance_review_queue_rows,
 scope.certified_account_count AS certified_account_rows,scope.certification_rate,
 scope.certified_exposure_amount,scope.active_exposure_amount,scope.review_hold_exposure_amount,
 scope.scheduled_payment_amount,scope.processed_payment_amount,scope.gross_collection_rate,
 scope.returned_payment_amount,scope.return_rate,scope.retry_payment_amount,scope.retry_cure_rate,
 scope.reconciliation_variance_amount,scope.exposure_variance_amount,
 scope.exception_case_count,scope.resolved_exception_count,scope.exception_resolution_rate,
 scope.unresolved_exception_count,scope.servicing_burden_units,scope.average_burden_per_account,
 hashes.policy_set_hash,hashes.kpi_definition_set_hash,hashes.performance_tier_set_hash,
 hashes.servicing_queue_set_hash,hashes.reason_set_hash,hashes.source_set_hash,
 hashes.account_performance_set_hash,hashes.scope_summary_set_hash,hashes.kpi_snapshot_set_hash,
 hashes.queue_summary_set_hash,hashes.latest_set_hash,hashes.archive_set_hash,
 NULL::text AS contract_set_hash,NULL::text AS combined_set_hash,
 'GENERATED'::text AS contract_status,clock_timestamp() AS generated_at,
 NULL::timestamptz AS validated_at,NULL::timestamptz AS accepted_at,NULL::text AS row_hash
FROM _m2_10_ctx AS ctx
CROSS JOIN _m2_10_hashes AS hashes
CROSS JOIN _m2_10_scope_expected AS scope
WHERE scope.module1_run_id=ctx.run_id AND scope.scope_code='PORTFOLIO_ALL';

UPDATE _m2_10_registry_expected AS registry
SET row_hash=msbf_ctl.m2_10_registry_row_hash(to_jsonb(registry))
WHERE registry.row_hash IS NULL;
UPDATE _m2_10_registry_expected AS registry
SET contract_set_hash=md5(registry.row_hash)
WHERE registry.contract_set_hash IS NULL;

/* ============================================================================
Section 9 — Canonical universe and physical reconciliation
============================================================================ */

DROP TABLE IF EXISTS _m2_10_canonical_expected;
CREATE TEMP TABLE _m2_10_canonical_expected
(entity_type text NOT NULL,entity_key text NOT NULL,row_hash text NOT NULL,
 PRIMARY KEY(entity_type,entity_key)) ON COMMIT DROP;

INSERT INTO _m2_10_canonical_expected
SELECT 'POLICY',policy_code||'|v'||policy_version::text,row_hash FROM msbf_ctl.m2_10_policy_profile WHERE module1_run_id=(SELECT run_id FROM _m2_10_ctx)
UNION ALL SELECT 'KPI_DEFINITION',kpi_code,row_hash FROM msbf_m2.portfolio_kpi_definition WHERE module1_run_id=(SELECT run_id FROM _m2_10_ctx)
UNION ALL SELECT 'PERFORMANCE_TIER_DEFINITION',performance_tier_code,row_hash FROM msbf_m2.portfolio_performance_tier_definition WHERE module1_run_id=(SELECT run_id FROM _m2_10_ctx)
UNION ALL SELECT 'SERVICING_QUEUE_DEFINITION',servicing_queue_code,row_hash FROM msbf_m2.servicing_queue_definition WHERE module1_run_id=(SELECT run_id FROM _m2_10_ctx)
UNION ALL SELECT 'REASON_DEFINITION',portfolio_analytics_reason_code,row_hash FROM msbf_m2.portfolio_analytics_reason_definition WHERE module1_run_id=(SELECT run_id FROM _m2_10_ctx)
UNION ALL SELECT 'SOURCE',scenario_id::text||'|'||merchant_application_id,row_hash FROM _m2_10_source_expected
UNION ALL SELECT 'ACCOUNT_PERFORMANCE',scenario_id::text||'|'||merchant_application_id,row_hash FROM _m2_10_performance_expected
UNION ALL SELECT 'SCOPE_SUMMARY',scope_code,row_hash FROM _m2_10_scope_expected
UNION ALL SELECT 'KPI_SNAPSHOT',scope_code||'|'||kpi_code,row_hash FROM _m2_10_kpi_expected
UNION ALL SELECT 'QUEUE_SUMMARY',servicing_queue_code,row_hash FROM _m2_10_queue_expected
UNION ALL SELECT 'LATEST',scenario_id::text||'|'||merchant_application_id,contract_row_hash FROM _m2_10_latest_expected
UNION ALL SELECT 'ARCHIVE',scenario_id::text||'|'||merchant_application_id,archive_row_hash FROM _m2_10_archive_expected
UNION ALL SELECT 'REGISTRY',contract_code||'|v'||contract_version::text,row_hash FROM _m2_10_registry_expected;

UPDATE _m2_10_registry_expected AS registry
SET combined_set_hash=(SELECT md5(string_agg(entity_type||'|'||entity_key||'|'||row_hash,'|' ORDER BY entity_type,entity_key)) FROM _m2_10_canonical_expected)
WHERE registry.combined_set_hash IS NULL;

INSERT INTO msbf_ctl.m2_10_portfolio_analytics_contract_registry
(
 module1_run_id,contract_code,contract_version,schema_version,methodology_version,
 source_contract_code,source_contract_version,source_schema_version,
 source_acceptance_gate_id,source_combined_set_hash,policy_configuration_hash,
 policy_rows,kpi_definition_rows,performance_tier_rows,servicing_queue_rows,
 reason_rows,source_rows,account_performance_rows,scope_summary_rows,
 kpi_snapshot_rows,queue_summary_rows,latest_rows,archive_rows,comparison_rows,
 registry_rows,canonical_entities,portfolio_account_rows,baseline_account_rows,
 stress_account_rows,closed_stable_rows,active_reconciled_rows,controlled_review_rows,
 no_servicing_queue_rows,active_reassessment_queue_rows,governance_review_queue_rows,
 certified_account_rows,certification_rate,certified_exposure_amount,
 active_exposure_amount,review_hold_exposure_amount,scheduled_payment_amount,
 processed_payment_amount,gross_collection_rate,returned_payment_amount,return_rate,
 retry_payment_amount,retry_cure_rate,reconciliation_variance_amount,
 exposure_variance_amount,exception_case_count,resolved_exception_count,
 exception_resolution_rate,unresolved_exception_count,servicing_burden_units,
 average_burden_per_account,policy_set_hash,kpi_definition_set_hash,
 performance_tier_set_hash,servicing_queue_set_hash,reason_set_hash,source_set_hash,
 account_performance_set_hash,scope_summary_set_hash,kpi_snapshot_set_hash,
 queue_summary_set_hash,latest_set_hash,archive_set_hash,contract_set_hash,
 combined_set_hash,contract_status,generated_at,validated_at,accepted_at,row_hash
)
SELECT module1_run_id,contract_code,contract_version,schema_version,methodology_version,
 source_contract_code,source_contract_version,source_schema_version,
 source_acceptance_gate_id,source_combined_set_hash,policy_configuration_hash,
 policy_rows,kpi_definition_rows,performance_tier_rows,servicing_queue_rows,
 reason_rows,source_rows,account_performance_rows,scope_summary_rows,
 kpi_snapshot_rows,queue_summary_rows,latest_rows,archive_rows,comparison_rows,
 registry_rows,canonical_entities,portfolio_account_rows,baseline_account_rows,
 stress_account_rows,closed_stable_rows,active_reconciled_rows,controlled_review_rows,
 no_servicing_queue_rows,active_reassessment_queue_rows,governance_review_queue_rows,
 certified_account_rows,certification_rate,certified_exposure_amount,
 active_exposure_amount,review_hold_exposure_amount,scheduled_payment_amount,
 processed_payment_amount,gross_collection_rate,returned_payment_amount,return_rate,
 retry_payment_amount,retry_cure_rate,reconciliation_variance_amount,
 exposure_variance_amount,exception_case_count,resolved_exception_count,
 exception_resolution_rate,unresolved_exception_count,servicing_burden_units,
 average_burden_per_account,policy_set_hash,kpi_definition_set_hash,
 performance_tier_set_hash,servicing_queue_set_hash,reason_set_hash,source_set_hash,
 account_performance_set_hash,scope_summary_set_hash,kpi_snapshot_set_hash,
 queue_summary_set_hash,latest_set_hash,archive_set_hash,contract_set_hash,
 combined_set_hash,contract_status,generated_at,validated_at,accepted_at,row_hash
FROM _m2_10_registry_expected;

DROP TABLE IF EXISTS _m2_10_mismatch;
CREATE TEMP TABLE _m2_10_mismatch ON COMMIT DROP AS
SELECT coalesce(expected.entity_type,actual.entity_type) AS entity_type,
 coalesce(expected.entity_key,actual.entity_key) AS entity_key,
 expected.row_hash AS expected_hash,actual.row_hash AS actual_hash
FROM _m2_10_canonical_expected AS expected
FULL OUTER JOIN
(SELECT entity_type,entity_key,row_hash FROM msbf_m2.v_m2_10_canonical_entity
 WHERE module1_run_id=(SELECT run_id FROM _m2_10_ctx)) AS actual
 ON actual.entity_type=expected.entity_type AND actual.entity_key=expected.entity_key
WHERE expected.row_hash IS DISTINCT FROM actual.row_hash;

DROP TABLE IF EXISTS _m2_10_diagnostics;
CREATE TEMP TABLE _m2_10_diagnostics ON COMMIT PRESERVE ROWS AS
SELECT (SELECT count(*) FROM _m2_10_canonical_expected)::bigint AS expected_canonical_entities,
 (SELECT count(*) FROM msbf_m2.v_m2_10_canonical_entity WHERE module1_run_id=(SELECT run_id FROM _m2_10_ctx))::bigint AS actual_canonical_entities,
 (SELECT count(*) FROM _m2_10_mismatch)::bigint AS row_level_mismatches,
 (SELECT count(*) FROM msbf_m2.v_m2_10_matched_scenario_comparison WHERE module1_run_id=(SELECT run_id FROM _m2_10_ctx))::bigint AS comparison_rows,
 (SELECT count(*) FROM msbf_m2.v_m2_10_matched_scenario_comparison WHERE module1_run_id=(SELECT run_id FROM _m2_10_ctx) AND stress_tier_improvement_flag)::bigint AS stress_tier_improvements,
 (SELECT count(*) FROM msbf_m2.v_m2_10_matched_scenario_comparison WHERE module1_run_id=(SELECT run_id FROM _m2_10_ctx) AND stress_burden_improvement_flag)::bigint AS stress_burden_improvements,
 (SELECT count(*) FROM msbf_m2.v_m2_10_matched_scenario_comparison WHERE module1_run_id=(SELECT run_id FROM _m2_10_ctx) AND stress_exposure_improvement_flag)::bigint AS stress_exposure_improvements;

DO $m2_10_reconciliation_guard$
DECLARE v record;
BEGIN
 SELECT * INTO v FROM _m2_10_diagnostics;
 IF v.expected_canonical_entities<>370 OR v.actual_canonical_entities<>370
  OR v.row_level_mismatches<>0 OR v.comparison_rows<>15
  OR v.stress_tier_improvements<>0 OR v.stress_burden_improvements<>0
  OR v.stress_exposure_improvements<>0
 THEN RAISE EXCEPTION 'M2.10 deterministic reconciliation failed: %.',row_to_json(v);
 END IF;
END;
$m2_10_reconciliation_guard$;

/* ============================================================================
Section 10 — Governed generation evidence and lifecycle transition
============================================================================ */

DROP TABLE IF EXISTS _m2_10_generation_evidence;
CREATE TEMP TABLE _m2_10_generation_evidence
(run_id bigint NOT NULL,evidence_code text NOT NULL,segment_key text NOT NULL,
 metric_name text NOT NULL,metric_value_numeric numeric(28,10),metric_value_text text,
 unit_code text NOT NULL,status text NOT NULL,interpretation text NOT NULL,
 CHECK(num_nonnulls(metric_value_numeric,metric_value_text)=1)) ON COMMIT DROP;

INSERT INTO _m2_10_generation_evidence
SELECT registry.module1_run_id,evidence.evidence_code,'PORTFOLIO',evidence.metric_name,
 evidence.numeric_value,evidence.text_value,evidence.unit_code,'PASS',evidence.interpretation
FROM _m2_10_registry_expected AS registry
CROSS JOIN LATERAL
(VALUES
 ('M2_10_POLICY_SET_HASH','POLICY_SET_HASH',NULL::numeric(28,10),registry.policy_set_hash,'HASH','M2.10 policy set hash.'),
 ('M2_10_KPI_DEFINITION_SET_HASH','KPI_DEFINITION_SET_HASH',NULL,registry.kpi_definition_set_hash,'HASH','KPI definition set hash.'),
 ('M2_10_PERFORMANCE_TIER_SET_HASH','PERFORMANCE_TIER_SET_HASH',NULL,registry.performance_tier_set_hash,'HASH','Performance tier set hash.'),
 ('M2_10_SERVICING_QUEUE_SET_HASH','SERVICING_QUEUE_SET_HASH',NULL,registry.servicing_queue_set_hash,'HASH','Servicing queue set hash.'),
 ('M2_10_REASON_SET_HASH','REASON_SET_HASH',NULL,registry.reason_set_hash,'HASH','Analytics reason set hash.'),
 ('M2_10_SOURCE_SET_HASH','SOURCE_SET_HASH',NULL,registry.source_set_hash,'HASH','Accepted M2.9 source set hash.'),
 ('M2_10_ACCOUNT_PERFORMANCE_SET_HASH','ACCOUNT_PERFORMANCE_SET_HASH',NULL,registry.account_performance_set_hash,'HASH','Account performance set hash.'),
 ('M2_10_SCOPE_SUMMARY_SET_HASH','SCOPE_SUMMARY_SET_HASH',NULL,registry.scope_summary_set_hash,'HASH','Scope summary set hash.'),
 ('M2_10_KPI_SNAPSHOT_SET_HASH','KPI_SNAPSHOT_SET_HASH',NULL,registry.kpi_snapshot_set_hash,'HASH','KPI snapshot set hash.'),
 ('M2_10_QUEUE_SUMMARY_SET_HASH','QUEUE_SUMMARY_SET_HASH',NULL,registry.queue_summary_set_hash,'HASH','Queue summary set hash.'),
 ('M2_10_LATEST_SET_HASH','LATEST_SET_HASH',NULL,registry.latest_set_hash,'HASH','Latest set hash.'),
 ('M2_10_ARCHIVE_SET_HASH','ARCHIVE_SET_HASH',NULL,registry.archive_set_hash,'HASH','Archive set hash.'),
 ('M2_10_CONTRACT_SET_HASH','CONTRACT_SET_HASH',NULL,registry.contract_set_hash,'HASH','Contract set hash.'),
 ('M2_10_COMBINED_SET_HASH','COMBINED_SET_HASH',NULL,registry.combined_set_hash,'HASH','Complete canonical hash.'),
 ('M2_10_SOURCE_ROWS','SOURCE_ROWS',registry.source_rows::numeric,NULL,'ROWS','Accepted source rows.'),
 ('M2_10_ACCOUNT_PERFORMANCE_ROWS','ACCOUNT_PERFORMANCE_ROWS',registry.account_performance_rows::numeric,NULL,'ROWS','Account performance rows.'),
 ('M2_10_SCOPE_SUMMARY_ROWS','SCOPE_SUMMARY_ROWS',registry.scope_summary_rows::numeric,NULL,'ROWS','Scope summary rows.'),
 ('M2_10_KPI_SNAPSHOT_ROWS','KPI_SNAPSHOT_ROWS',registry.kpi_snapshot_rows::numeric,NULL,'ROWS','KPI rows.'),
 ('M2_10_QUEUE_SUMMARY_ROWS','QUEUE_SUMMARY_ROWS',registry.queue_summary_rows::numeric,NULL,'ROWS','Queue rows.'),
 ('M2_10_CANONICAL_ENTITIES','CANONICAL_ENTITIES',registry.canonical_entities::numeric,NULL,'ROWS','Canonical entities.'),
 ('M2_10_CERTIFIED_EXPOSURE','CERTIFIED_EXPOSURE',registry.certified_exposure_amount::numeric,NULL,'USD','Certified exposure.'),
 ('M2_10_PROCESSED_PAYMENT','PROCESSED_PAYMENT',registry.processed_payment_amount::numeric,NULL,'USD','Processed payment.'),
 ('M2_10_SERVICING_BURDEN','SERVICING_BURDEN',registry.servicing_burden_units::numeric,NULL,'UNITS','Servicing burden.'),
 ('M2_10_EXCEPTION_RESOLUTION_RATE','EXCEPTION_RESOLUTION_RATE',registry.exception_resolution_rate::numeric,NULL,'RATE','Exception resolution rate.')
) AS evidence(evidence_code,metric_name,numeric_value,text_value,unit_code,interpretation);

INSERT INTO msbf_ctl.run_evidence
(run_id,evidence_code,segment_key,metric_name,metric_value_numeric,
 metric_value_text,unit_code,status,interpretation)
SELECT
 evidence.run_id,evidence.evidence_code,evidence.segment_key,
 evidence.metric_name,evidence.metric_value_numeric,
 evidence.metric_value_text,evidence.unit_code,evidence.status,
 evidence.interpretation
FROM _m2_10_generation_evidence AS evidence;

UPDATE msbf_ctl.run_registry SET run_status='M2_10_GENERATED',
 notes=coalesce(notes,'')||' | M2.10 portfolio performance, KPI, and servicing analytics generated.'
WHERE run_id=(SELECT run_id FROM _m2_10_ctx);

INSERT INTO _m2_10_result
SELECT registry.module1_run_id,'M2_10_GENERATED',registry.policy_rows,
 registry.kpi_definition_rows,registry.performance_tier_rows,
 registry.servicing_queue_rows,registry.reason_rows,registry.source_rows,
 registry.account_performance_rows,registry.scope_summary_rows,
 registry.kpi_snapshot_rows,registry.queue_summary_rows,registry.latest_rows,
 registry.archive_rows,registry.comparison_rows,registry.registry_rows,
 registry.portfolio_account_rows,registry.baseline_account_rows,
 registry.stress_account_rows,registry.closed_stable_rows,
 registry.active_reconciled_rows,registry.controlled_review_rows,
 registry.no_servicing_queue_rows,registry.active_reassessment_queue_rows,
 registry.governance_review_queue_rows,registry.certified_account_rows,
 registry.certification_rate,registry.certified_exposure_amount,
 registry.active_exposure_amount,registry.review_hold_exposure_amount,
 registry.scheduled_payment_amount,registry.processed_payment_amount,
 registry.gross_collection_rate,registry.returned_payment_amount,
 registry.return_rate,registry.retry_payment_amount,registry.retry_cure_rate,
 registry.reconciliation_variance_amount,registry.exposure_variance_amount,
 registry.exception_case_count,registry.resolved_exception_count,
 registry.exception_resolution_rate,registry.unresolved_exception_count,
 registry.servicing_burden_units,registry.average_burden_per_account,
 370,diagnostics.actual_canonical_entities,diagnostics.row_level_mismatches,
 diagnostics.stress_tier_improvements,diagnostics.stress_burden_improvements,
 diagnostics.stress_exposure_improvements,registry.policy_set_hash,
 registry.kpi_definition_set_hash,registry.performance_tier_set_hash,
 registry.servicing_queue_set_hash,registry.reason_set_hash,
 registry.source_set_hash,registry.account_performance_set_hash,
 registry.scope_summary_set_hash,registry.kpi_snapshot_set_hash,
 registry.queue_summary_set_hash,registry.latest_set_hash,registry.archive_set_hash,
 registry.contract_set_hash,registry.combined_set_hash,'PASS'
FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry AS registry
CROSS JOIN _m2_10_diagnostics AS diagnostics
WHERE registry.module1_run_id=(SELECT run_id FROM _m2_10_ctx);

COMMIT;
SELECT * FROM _m2_10_result;
