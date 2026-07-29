/* ============================================================================
MSBF M1.15 Latest, Archive, Comparison & Contract Generation
Program : 110_msbf_m1_15_latest_archive_comparison_generation_v0_2R3.sql
Version : v0.2R3
Purpose : Materialize the scenario-aware latest contract, immutable archive,
          matched comparison, contract registry, canonical hashes, and evidence.
Inputs  : Accepted persisted M1.7-M1.14 outputs.
Outputs : 1,500 latest rows, 1,500 archive rows, 750 comparison rows, one
          contract-registry row, and exact canonical reconciliation.
Safety  : One transaction; fails before commit on count, lineage, or hash drift.
============================================================================ */

BEGIN;
SET LOCAL work_mem='128MB';
SET LOCAL jit=off;
SET LOCAL lock_timeout='10s';
SET LOCAL statement_timeout='20min';

DROP TABLE IF EXISTS _m1_15_ctx;
CREATE TEMP TABLE _m1_15_ctx ON COMMIT DROP AS
SELECT r.run_id,r.population_id,r.as_of_date,
       min(sr.scenario_set_id) AS scenario_set_id
FROM msbf_ctl.run_registry r
JOIN msbf_m1.application_unit_economics_snapshot e
  ON e.module1_run_id=r.run_id
JOIN msbf_ctl.scenario_registry sr
  ON sr.scenario_id=e.scenario_id
WHERE r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1
GROUP BY r.run_id,r.population_id,r.as_of_date;

DO $ready$
BEGIN
    PERFORM msbf_m1.m1_15_assert_generation_ready(
        (SELECT run_id FROM _m1_15_ctx)
    );
END;
$ready$;

DO $notice_1$ BEGIN RAISE NOTICE 'M1.15 Phase 1/5 — materialize accepted Module 1 contract inputs'; END; $notice_1$;

DROP TABLE IF EXISTS _m1_15_latest_expected;
CREATE TEMP TABLE _m1_15_latest_expected ON COMMIT DROP AS
SELECT
    e.module1_run_id::bigint AS module1_run_id,
    e.scenario_id::bigint AS scenario_id,
    e.merchant_application_id::text AS merchant_application_id,
    e.population_id::text AS population_id,
    e.merchant_id::text AS merchant_id,
    e.as_of_date::date AS as_of_date,
    sr.scenario_code::text AS scenario_code,
    e.industry_code::text AS industry_code,
    e.merchant_size_tier::text AS merchant_size_tier,
    e.relationship_stage::text AS relationship_stage,
    e.partner_channel_id::text AS partner_channel_id,
    e.channel_type::text AS channel_type,

    f.source_confidence_score::numeric(9,6) AS source_confidence_score,
    f.data_confidence_tier::text AS data_confidence_tier,
    v.verification_disposition::text AS verification_disposition,
    v.fraud_risk_tier::smallint AS fraud_risk_tier,
    v.processor_continuity_status::text AS processor_continuity_status,
    f.feature_completeness_status::text AS feature_completeness_status,
    f.avg_daily_eligible_sales_30d::numeric(18,2) AS avg_daily_eligible_sales_30d,
    f.annualized_eligible_sales::numeric(18,2) AS annualized_eligible_sales,
    f.average_available_balance_30d::numeric(18,2) AS average_available_balance_30d,
    f.negative_balance_day_rate_30d::numeric(12,8) AS negative_balance_day_rate_30d,
    f.nsf_count_30d::integer AS nsf_count_30d,

    c.capacity_tier::smallint AS capacity_tier,
    c.capacity_evidence_status::text AS capacity_evidence_status,
    c.affordability_status::text AS affordability_status,
    c.sales_linked_payment_coverage_ratio::numeric(12,6) AS sales_linked_payment_coverage_ratio,
    c.residual_daily_operating_cash_flow::numeric(18,2) AS residual_daily_operating_cash_flow,
    c.post_financing_liquidity_buffer_amount::numeric(18,2) AS post_financing_liquidity_buffer_amount,

    o.archetype_code::text AS archetype_code,
    o.operating_resilience_score::numeric(12,6) AS operating_resilience_score,
    o.resilience_tier::smallint AS resilience_tier,
    o.resilience_status::text AS resilience_status,
    o.operating_resilience_evidence_status::text AS operating_resilience_evidence_status,

    r.integrated_risk_score::numeric(12,6) AS integrated_risk_score,
    r.synthetic_merchant_risk_proxy::numeric(12,8) AS synthetic_merchant_risk_proxy,
    r.integrated_risk_tier::smallint AS integrated_risk_tier,
    r.integrated_risk_status::text AS integrated_risk_status,
    r.integrated_risk_evidence_status::text AS integrated_risk_evidence_status,

    l.path_weighted_ead_amount::numeric(18,2) AS path_weighted_ead_amount,
    l.expected_ead_rate::numeric(12,8) AS expected_ead_rate,
    l.recovery_rate_assumption::numeric(12,8) AS recovery_rate_assumption,
    l.lgd_input_rate::numeric(12,8) AS lgd_input_rate,
    l.schedule_adjusted_comparative_expected_loss_amount::numeric(18,2)
        AS schedule_adjusted_comparative_expected_loss_amount,
    l.schedule_adjusted_comparative_loss_rate::numeric(12,8)
        AS schedule_adjusted_comparative_loss_rate,
    l.loss_evidence_status::text AS loss_evidence_status,

    e.gross_finance_revenue_amount::numeric(18,2) AS gross_finance_revenue_amount,
    e.total_non_loss_cost_amount::numeric(18,2) AS total_non_loss_cost_amount,
    e.risk_adjusted_contribution_amount::numeric(18,2) AS risk_adjusted_contribution_amount,
    e.annualized_risk_adjusted_return_rate::numeric(12,8) AS annualized_risk_adjusted_return_rate,
    e.economic_surplus_amount::numeric(18,2) AS economic_surplus_amount,
    e.economic_tier::smallint AS economic_tier,
    e.economic_status::text AS economic_status,
    e.unit_economics_evidence_status::text AS unit_economics_evidence_status,

    (v.hard_stop_recommended_flag OR r.hard_stop_recommended_flag
     OR l.hard_stop_recommended_flag OR e.hard_stop_recommended_flag)::boolean
        AS hard_stop_recommended_flag,
    (v.manual_review_recommended_flag OR c.manual_review_recommended_flag
     OR o.manual_review_recommended_flag OR r.manual_review_recommended_flag
     OR l.manual_review_recommended_flag OR e.manual_review_recommended_flag)::boolean
        AS manual_review_recommended_flag,
    CASE
      WHEN e.unit_economics_evidence_status='BLOCKED'
        OR l.loss_evidence_status='BLOCKED'
        OR r.integrated_risk_evidence_status='BLOCKED'
        OR o.operating_resilience_evidence_status='BLOCKED'
        OR c.capacity_evidence_status='BLOCKED'
        OR f.feature_completeness_status='BLOCKED'
        OR v.verification_disposition IN ('STOP','INSUFFICIENT_EVIDENCE')
      THEN 'BLOCKED'
      WHEN e.unit_economics_evidence_status='PARTIAL'
        OR l.loss_evidence_status='PARTIAL'
        OR r.integrated_risk_evidence_status='PARTIAL'
        OR o.operating_resilience_evidence_status='PARTIAL'
        OR c.capacity_evidence_status<>'COMPLETE'
        OR f.feature_completeness_status='PARTIAL'
        OR v.verification_disposition='REVIEW'
      THEN 'PARTIAL'
      ELSE 'COMPLETE'
    END::text AS contract_evidence_status,
    CASE
      WHEN v.hard_stop_recommended_flag OR r.hard_stop_recommended_flag
        OR l.hard_stop_recommended_flag OR e.hard_stop_recommended_flag
      THEN 'HARD_STOP'
      WHEN e.fallback_path_code<>'NONE' THEN e.fallback_path_code
      WHEN l.fallback_path_code<>'NONE' THEN l.fallback_path_code
      WHEN r.fallback_path_code<>'NONE' THEN r.fallback_path_code
      WHEN o.fallback_path_code<>'NONE' THEN o.fallback_path_code
      WHEN c.fallback_path_code<>'NONE' THEN c.fallback_path_code
      ELSE 'NONE'
    END::text AS fallback_path_code,
    CASE
      WHEN v.hard_stop_recommended_flag THEN v.primary_reason_code
      WHEN r.hard_stop_recommended_flag THEN r.primary_risk_reason_code
      WHEN l.hard_stop_recommended_flag THEN l.primary_loss_reason_code
      WHEN e.hard_stop_recommended_flag THEN e.primary_economic_reason_code
      WHEN e.manual_review_recommended_flag THEN e.primary_economic_reason_code
      WHEN l.manual_review_recommended_flag THEN l.primary_loss_reason_code
      WHEN r.manual_review_recommended_flag THEN r.primary_risk_reason_code
      WHEN o.manual_review_recommended_flag THEN o.primary_resilience_reason_code
      WHEN c.manual_review_recommended_flag THEN c.primary_capacity_reason_code
      ELSE 'CONTRACT_CLEAR'
    END::text AS primary_contract_reason_code,
    ARRAY[
      v.primary_reason_code,
      c.primary_capacity_reason_code,
      o.primary_resilience_reason_code,
      r.primary_risk_reason_code,
      l.primary_loss_reason_code,
      e.primary_economic_reason_code
    ]::text[] AS secondary_contract_reason_codes,

    v.row_hash::text AS m1_8_row_hash,
    f.feature_snapshot_hash::text AS m1_9_row_hash,
    c.row_hash::text AS m1_10_row_hash,
    o.row_hash::text AS m1_11_row_hash,
    r.row_hash::text AS m1_12_row_hash,
    l.row_hash::text AS m1_13_row_hash,
    e.row_hash::text AS m1_14_row_hash,
    jsonb_build_object(
      'source_confidence_score',f.source_confidence_score,
      'verification_disposition',v.verification_disposition,
      'capacity_evidence_status',c.capacity_evidence_status,
      'resilience_evidence_status',o.operating_resilience_evidence_status,
      'risk_evidence_status',r.integrated_risk_evidence_status,
      'loss_evidence_status',l.loss_evidence_status,
      'unit_economics_evidence_status',e.unit_economics_evidence_status
    )::jsonb AS source_payload,
    jsonb_build_object(
      'm1_8',v.row_hash,'m1_9',f.feature_snapshot_hash,'m1_10',c.row_hash,
      'm1_11',o.row_hash,'m1_12',r.row_hash,'m1_13',l.row_hash,'m1_14',e.row_hash,
      'scenario_id',e.scenario_id,'scenario_code',sr.scenario_code,
      'module1_run_id',e.module1_run_id
    )::jsonb AS lineage_payload,

    'M1_APPLICATION_CONSUMPTION'::text AS contract_code,
    1::integer AS contract_version,
    'M1_CONTRACT_SCHEMA_V1'::text AS schema_version,
    ''::text AS contract_row_hash,
    e.module1_run_id::bigint AS created_by_run_id,
    clock_timestamp()::timestamptz AS created_at
FROM msbf_m1.application_unit_economics_snapshot e
JOIN msbf_ctl.scenario_registry sr
  ON sr.scenario_id=e.scenario_id
JOIN msbf_m1.application_exposure_recovery_loss_snapshot l
  ON l.module1_run_id=e.module1_run_id
 AND l.scenario_id=e.scenario_id
 AND l.merchant_application_id=e.merchant_application_id
JOIN msbf_m1.application_integrated_risk_proxy_snapshot r
  ON r.module1_run_id=e.module1_run_id
 AND r.scenario_id=e.scenario_id
 AND r.merchant_application_id=e.merchant_application_id
JOIN msbf_m1.application_operating_resilience_snapshot o
  ON o.module1_run_id=e.module1_run_id
 AND o.scenario_id=e.scenario_id
 AND o.merchant_application_id=e.merchant_application_id
JOIN msbf_m1.application_liquidity_capacity_snapshot c
  ON c.module1_run_id=e.module1_run_id
 AND c.scenario_id=e.scenario_id
 AND c.merchant_application_id=e.merchant_application_id
JOIN msbf_m1.application_cashflow_feature_snapshot f
  ON f.module1_run_id=e.module1_run_id
 AND f.scenario_id=e.scenario_id
 AND f.merchant_application_id=e.merchant_application_id
JOIN msbf_m1.application_verification_fraud_snapshot v
  ON v.module1_run_id=e.module1_run_id
 AND v.merchant_application_id=e.merchant_application_id
WHERE e.module1_run_id=(SELECT run_id FROM _m1_15_ctx);

UPDATE _m1_15_latest_expected t
SET contract_row_hash=msbf_m1.m1_15_hash_jsonb(
    to_jsonb(t)-'contract_row_hash'-'created_at'
)
WHERE contract_row_hash='';

CREATE UNIQUE INDEX ON _m1_15_latest_expected(
    module1_run_id,scenario_id,merchant_application_id
);

DO $latest_count$
BEGIN
    IF (SELECT count(*) FROM _m1_15_latest_expected)<>1500 THEN
        RAISE EXCEPTION 'M1.15 latest expected 1,500 rows; observed %.',
            (SELECT count(*) FROM _m1_15_latest_expected);
    END IF;
END;
$latest_count$;

DO $notice_2$ BEGIN RAISE NOTICE 'M1.15 Phase 2/5 — persist latest and immutable archive'; END; $notice_2$;

INSERT INTO msbf_m1.application_module1_latest(
    module1_run_id, scenario_id, merchant_application_id, population_id,
    merchant_id, as_of_date, scenario_code, industry_code,
    merchant_size_tier, relationship_stage, partner_channel_id, channel_type,
    source_confidence_score, data_confidence_tier, verification_disposition, fraud_risk_tier,
    processor_continuity_status, feature_completeness_status, avg_daily_eligible_sales_30d, annualized_eligible_sales,
    average_available_balance_30d, negative_balance_day_rate_30d, nsf_count_30d, capacity_tier,
    capacity_evidence_status, affordability_status, sales_linked_payment_coverage_ratio, residual_daily_operating_cash_flow,
    post_financing_liquidity_buffer_amount, archetype_code, operating_resilience_score, resilience_tier,
    resilience_status, operating_resilience_evidence_status, integrated_risk_score, synthetic_merchant_risk_proxy,
    integrated_risk_tier, integrated_risk_status, integrated_risk_evidence_status, path_weighted_ead_amount,
    expected_ead_rate, recovery_rate_assumption, lgd_input_rate, schedule_adjusted_comparative_expected_loss_amount,
    schedule_adjusted_comparative_loss_rate, loss_evidence_status, gross_finance_revenue_amount, total_non_loss_cost_amount,
    risk_adjusted_contribution_amount, annualized_risk_adjusted_return_rate, economic_surplus_amount, economic_tier,
    economic_status, unit_economics_evidence_status, hard_stop_recommended_flag, manual_review_recommended_flag,
    contract_evidence_status, fallback_path_code, primary_contract_reason_code, secondary_contract_reason_codes,
    m1_8_row_hash, m1_9_row_hash, m1_10_row_hash, m1_11_row_hash,
    m1_12_row_hash, m1_13_row_hash, m1_14_row_hash, source_payload,
    lineage_payload, contract_code, contract_version, schema_version,
    contract_row_hash, created_by_run_id, created_at
)
SELECT
    module1_run_id, scenario_id, merchant_application_id, population_id,
    merchant_id, as_of_date, scenario_code, industry_code,
    merchant_size_tier, relationship_stage, partner_channel_id, channel_type,
    source_confidence_score, data_confidence_tier, verification_disposition, fraud_risk_tier,
    processor_continuity_status, feature_completeness_status, avg_daily_eligible_sales_30d, annualized_eligible_sales,
    average_available_balance_30d, negative_balance_day_rate_30d, nsf_count_30d, capacity_tier,
    capacity_evidence_status, affordability_status, sales_linked_payment_coverage_ratio, residual_daily_operating_cash_flow,
    post_financing_liquidity_buffer_amount, archetype_code, operating_resilience_score, resilience_tier,
    resilience_status, operating_resilience_evidence_status, integrated_risk_score, synthetic_merchant_risk_proxy,
    integrated_risk_tier, integrated_risk_status, integrated_risk_evidence_status, path_weighted_ead_amount,
    expected_ead_rate, recovery_rate_assumption, lgd_input_rate, schedule_adjusted_comparative_expected_loss_amount,
    schedule_adjusted_comparative_loss_rate, loss_evidence_status, gross_finance_revenue_amount, total_non_loss_cost_amount,
    risk_adjusted_contribution_amount, annualized_risk_adjusted_return_rate, economic_surplus_amount, economic_tier,
    economic_status, unit_economics_evidence_status, hard_stop_recommended_flag, manual_review_recommended_flag,
    contract_evidence_status, fallback_path_code, primary_contract_reason_code, secondary_contract_reason_codes,
    m1_8_row_hash, m1_9_row_hash, m1_10_row_hash, m1_11_row_hash,
    m1_12_row_hash, m1_13_row_hash, m1_14_row_hash, source_payload,
    lineage_payload, contract_code, contract_version, schema_version,
    contract_row_hash, created_by_run_id, created_at
FROM _m1_15_latest_expected;

INSERT INTO msbf_m1.application_module1_archive(
    module1_run_id,scenario_id,merchant_application_id,
    contract_code,contract_version,schema_version,contract_row_hash,
    contract_payload,archived_by_run_id
)
SELECT
    module1_run_id,scenario_id,merchant_application_id,
    contract_code,contract_version,schema_version,contract_row_hash,
    to_jsonb(t)-'created_at',
    module1_run_id
FROM _m1_15_latest_expected t;

ANALYZE msbf_m1.application_module1_latest;
ANALYZE msbf_m1.application_module1_archive;

DO $notice_3$ BEGIN RAISE NOTICE 'M1.15 Phase 3/5 — construct matched scenario comparison'; END; $notice_3$;

DROP TABLE IF EXISTS _m1_15_comparison_expected;
CREATE TEMP TABLE _m1_15_comparison_expected ON COMMIT DROP AS
SELECT
    b.module1_run_id::bigint,
    b.merchant_application_id::text,
    b.population_id::text,
    b.merchant_id::text,
    b.as_of_date::date,
    b.scenario_id::bigint AS baseline_scenario_id,
    s.scenario_id::bigint AS stress_scenario_id,

    b.source_confidence_score::numeric(9,6) AS baseline_source_confidence_score,
    s.source_confidence_score::numeric(9,6) AS stress_source_confidence_score,
    (s.source_confidence_score-b.source_confidence_score)::numeric(12,8) AS source_confidence_delta,

    b.avg_daily_eligible_sales_30d::numeric(18,2) AS baseline_avg_daily_eligible_sales_30d,
    s.avg_daily_eligible_sales_30d::numeric(18,2) AS stress_avg_daily_eligible_sales_30d,
    CASE WHEN b.avg_daily_eligible_sales_30d IS NULL OR s.avg_daily_eligible_sales_30d IS NULL
         THEN NULL ELSE (s.avg_daily_eligible_sales_30d-b.avg_daily_eligible_sales_30d)::numeric(18,2) END
         AS sales_delta_amount,

    b.average_available_balance_30d::numeric(18,2) AS baseline_average_available_balance_30d,
    s.average_available_balance_30d::numeric(18,2) AS stress_average_available_balance_30d,
    CASE WHEN b.average_available_balance_30d IS NULL OR s.average_available_balance_30d IS NULL
         THEN NULL ELSE (s.average_available_balance_30d-b.average_available_balance_30d)::numeric(18,2) END
         AS available_balance_delta_amount,

    b.capacity_tier::smallint AS baseline_capacity_tier,
    s.capacity_tier::smallint AS stress_capacity_tier,
    (s.capacity_tier-b.capacity_tier)::smallint AS capacity_tier_delta,

    b.operating_resilience_score::numeric(12,6) AS baseline_operating_resilience_score,
    s.operating_resilience_score::numeric(12,6) AS stress_operating_resilience_score,
    CASE WHEN b.operating_resilience_score IS NULL OR s.operating_resilience_score IS NULL
         THEN NULL ELSE (s.operating_resilience_score-b.operating_resilience_score)::numeric(12,6) END
         AS resilience_score_delta,
    b.resilience_tier::smallint AS baseline_resilience_tier,
    s.resilience_tier::smallint AS stress_resilience_tier,
    (s.resilience_tier-b.resilience_tier)::smallint AS resilience_tier_delta,

    b.integrated_risk_score::numeric(12,6) AS baseline_integrated_risk_score,
    s.integrated_risk_score::numeric(12,6) AS stress_integrated_risk_score,
    CASE WHEN b.integrated_risk_score IS NULL OR s.integrated_risk_score IS NULL
         THEN NULL ELSE (s.integrated_risk_score-b.integrated_risk_score)::numeric(12,6) END
         AS integrated_risk_score_delta,
    b.integrated_risk_tier::smallint AS baseline_integrated_risk_tier,
    s.integrated_risk_tier::smallint AS stress_integrated_risk_tier,
    (s.integrated_risk_tier-b.integrated_risk_tier)::smallint AS integrated_risk_tier_delta,

    b.path_weighted_ead_amount::numeric(18,2) AS baseline_path_weighted_ead_amount,
    s.path_weighted_ead_amount::numeric(18,2) AS stress_path_weighted_ead_amount,
    (s.path_weighted_ead_amount-b.path_weighted_ead_amount)::numeric(18,2)
         AS path_weighted_ead_delta_amount,

    b.lgd_input_rate::numeric(12,8) AS baseline_lgd_input_rate,
    s.lgd_input_rate::numeric(12,8) AS stress_lgd_input_rate,
    (s.lgd_input_rate-b.lgd_input_rate)::numeric(12,8) AS lgd_delta_rate,

    b.schedule_adjusted_comparative_expected_loss_amount::numeric(18,2)
         AS baseline_comparative_loss_amount,
    s.schedule_adjusted_comparative_expected_loss_amount::numeric(18,2)
         AS stress_comparative_loss_amount,
    CASE WHEN b.schedule_adjusted_comparative_expected_loss_amount IS NULL
           OR s.schedule_adjusted_comparative_expected_loss_amount IS NULL
         THEN NULL
         ELSE (s.schedule_adjusted_comparative_expected_loss_amount
              -b.schedule_adjusted_comparative_expected_loss_amount)::numeric(18,2)
    END AS comparative_loss_delta_amount,

    b.risk_adjusted_contribution_amount::numeric(18,2)
         AS baseline_risk_adjusted_contribution_amount,
    s.risk_adjusted_contribution_amount::numeric(18,2)
         AS stress_risk_adjusted_contribution_amount,
    CASE WHEN b.risk_adjusted_contribution_amount IS NULL
           OR s.risk_adjusted_contribution_amount IS NULL
         THEN NULL
         ELSE (s.risk_adjusted_contribution_amount
              -b.risk_adjusted_contribution_amount)::numeric(18,2)
    END AS risk_adjusted_contribution_delta_amount,

    b.annualized_risk_adjusted_return_rate::numeric(12,8) AS baseline_annualized_return_rate,
    s.annualized_risk_adjusted_return_rate::numeric(12,8) AS stress_annualized_return_rate,
    CASE WHEN b.annualized_risk_adjusted_return_rate IS NULL
           OR s.annualized_risk_adjusted_return_rate IS NULL
         THEN NULL
         ELSE (s.annualized_risk_adjusted_return_rate
              -b.annualized_risk_adjusted_return_rate)::numeric(12,8)
    END AS annualized_return_delta_rate,

    b.economic_tier::smallint AS baseline_economic_tier,
    s.economic_tier::smallint AS stress_economic_tier,
    (s.economic_tier-b.economic_tier)::smallint AS economic_tier_delta,

    (s.capacity_tier>b.capacity_tier)::boolean AS capacity_worsening_flag,
    (s.resilience_tier>b.resilience_tier
      OR (s.operating_resilience_score IS NOT NULL
          AND b.operating_resilience_score IS NOT NULL
          AND s.operating_resilience_score<b.operating_resilience_score))::boolean
        AS resilience_worsening_flag,
    (s.integrated_risk_tier>b.integrated_risk_tier
      OR (s.integrated_risk_score IS NOT NULL
          AND b.integrated_risk_score IS NOT NULL
          AND s.integrated_risk_score>b.integrated_risk_score))::boolean
        AS integrated_risk_worsening_flag,
    (s.schedule_adjusted_comparative_expected_loss_amount IS NOT NULL
      AND b.schedule_adjusted_comparative_expected_loss_amount IS NOT NULL
      AND s.schedule_adjusted_comparative_expected_loss_amount
          >b.schedule_adjusted_comparative_expected_loss_amount)::boolean
        AS comparative_loss_worsening_flag,
    (
      (s.risk_adjusted_contribution_amount IS NOT NULL
       AND b.risk_adjusted_contribution_amount IS NOT NULL
       AND s.risk_adjusted_contribution_amount<b.risk_adjusted_contribution_amount)
      OR
      (s.annualized_risk_adjusted_return_rate IS NOT NULL
       AND b.annualized_risk_adjusted_return_rate IS NOT NULL
       AND s.annualized_risk_adjusted_return_rate<b.annualized_risk_adjusted_return_rate)
      OR s.economic_tier>b.economic_tier
    )::boolean AS economic_worsening_flag,
    (s.manual_review_recommended_flag AND NOT b.manual_review_recommended_flag)::boolean
        AS manual_review_escalation_flag,
    (s.hard_stop_recommended_flag AND NOT b.hard_stop_recommended_flag)::boolean
        AS hard_stop_escalation_flag,

    CASE
      WHEN b.contract_evidence_status='BLOCKED' OR s.contract_evidence_status='BLOCKED'
      THEN 'BLOCKED'
      WHEN b.contract_evidence_status='PARTIAL' OR s.contract_evidence_status='PARTIAL'
      THEN 'PARTIAL'
      ELSE 'COMPLETE'
    END::text AS comparison_evidence_status,
    b.contract_row_hash::text AS baseline_contract_row_hash,
    s.contract_row_hash::text AS stress_contract_row_hash,
    b.contract_code::text AS contract_code,
    b.contract_version::integer AS contract_version,
    ''::text AS comparison_row_hash,
    b.module1_run_id::bigint AS created_by_run_id,
    clock_timestamp()::timestamptz AS created_at
FROM _m1_15_latest_expected b
JOIN _m1_15_latest_expected s
  ON s.module1_run_id=b.module1_run_id
 AND s.merchant_application_id=b.merchant_application_id
WHERE b.scenario_code='BASELINE'
  AND s.scenario_code='RECESSION_ENERGY';

UPDATE _m1_15_comparison_expected c
SET comparison_row_hash=msbf_m1.m1_15_hash_jsonb(
    to_jsonb(c)-'comparison_row_hash'-'created_at'
)
WHERE comparison_row_hash='';

DO $comparison_count$
BEGIN
    IF (SELECT count(*) FROM _m1_15_comparison_expected)<>750 THEN
        RAISE EXCEPTION 'M1.15 comparison expected 750 rows; observed %.',
            (SELECT count(*) FROM _m1_15_comparison_expected);
    END IF;
END;
$comparison_count$;

INSERT INTO msbf_m1.application_module1_scenario_comparison(
    module1_run_id, merchant_application_id, population_id, merchant_id,
    as_of_date, baseline_scenario_id, stress_scenario_id, baseline_source_confidence_score,
    stress_source_confidence_score, source_confidence_delta, baseline_avg_daily_eligible_sales_30d, stress_avg_daily_eligible_sales_30d,
    sales_delta_amount, baseline_average_available_balance_30d, stress_average_available_balance_30d, available_balance_delta_amount,
    baseline_capacity_tier, stress_capacity_tier, capacity_tier_delta, baseline_operating_resilience_score,
    stress_operating_resilience_score, resilience_score_delta, baseline_resilience_tier, stress_resilience_tier,
    resilience_tier_delta, baseline_integrated_risk_score, stress_integrated_risk_score, integrated_risk_score_delta,
    baseline_integrated_risk_tier, stress_integrated_risk_tier, integrated_risk_tier_delta, baseline_path_weighted_ead_amount,
    stress_path_weighted_ead_amount, path_weighted_ead_delta_amount, baseline_lgd_input_rate, stress_lgd_input_rate,
    lgd_delta_rate, baseline_comparative_loss_amount, stress_comparative_loss_amount, comparative_loss_delta_amount,
    baseline_risk_adjusted_contribution_amount, stress_risk_adjusted_contribution_amount, risk_adjusted_contribution_delta_amount, baseline_annualized_return_rate,
    stress_annualized_return_rate, annualized_return_delta_rate, baseline_economic_tier, stress_economic_tier,
    economic_tier_delta, capacity_worsening_flag, resilience_worsening_flag, integrated_risk_worsening_flag,
    comparative_loss_worsening_flag, economic_worsening_flag, manual_review_escalation_flag, hard_stop_escalation_flag,
    comparison_evidence_status, baseline_contract_row_hash, stress_contract_row_hash, contract_code,
    contract_version, comparison_row_hash, created_by_run_id, created_at
)
SELECT
    module1_run_id, merchant_application_id, population_id, merchant_id,
    as_of_date, baseline_scenario_id, stress_scenario_id, baseline_source_confidence_score,
    stress_source_confidence_score, source_confidence_delta, baseline_avg_daily_eligible_sales_30d, stress_avg_daily_eligible_sales_30d,
    sales_delta_amount, baseline_average_available_balance_30d, stress_average_available_balance_30d, available_balance_delta_amount,
    baseline_capacity_tier, stress_capacity_tier, capacity_tier_delta, baseline_operating_resilience_score,
    stress_operating_resilience_score, resilience_score_delta, baseline_resilience_tier, stress_resilience_tier,
    resilience_tier_delta, baseline_integrated_risk_score, stress_integrated_risk_score, integrated_risk_score_delta,
    baseline_integrated_risk_tier, stress_integrated_risk_tier, integrated_risk_tier_delta, baseline_path_weighted_ead_amount,
    stress_path_weighted_ead_amount, path_weighted_ead_delta_amount, baseline_lgd_input_rate, stress_lgd_input_rate,
    lgd_delta_rate, baseline_comparative_loss_amount, stress_comparative_loss_amount, comparative_loss_delta_amount,
    baseline_risk_adjusted_contribution_amount, stress_risk_adjusted_contribution_amount, risk_adjusted_contribution_delta_amount, baseline_annualized_return_rate,
    stress_annualized_return_rate, annualized_return_delta_rate, baseline_economic_tier, stress_economic_tier,
    economic_tier_delta, capacity_worsening_flag, resilience_worsening_flag, integrated_risk_worsening_flag,
    comparative_loss_worsening_flag, economic_worsening_flag, manual_review_escalation_flag, hard_stop_escalation_flag,
    comparison_evidence_status, baseline_contract_row_hash, stress_contract_row_hash, contract_code,
    contract_version, comparison_row_hash, created_by_run_id, created_at
FROM _m1_15_comparison_expected;

ANALYZE msbf_m1.application_module1_scenario_comparison;

DO $notice_4$ BEGIN RAISE NOTICE 'M1.15 Phase 4/5 — calculate set hashes and register contract'; END; $notice_4$;

DROP TABLE IF EXISTS _m1_15_hashes;
CREATE TEMP TABLE _m1_15_hashes ON COMMIT DROP AS
WITH latest AS (
  SELECT md5(string_agg(
      'LATEST|'||scenario_id||'|'||merchant_application_id||'|'||contract_row_hash,
      '||' ORDER BY scenario_id,merchant_application_id
  )) AS h
  FROM msbf_m1.application_module1_latest
  WHERE module1_run_id=(SELECT run_id FROM _m1_15_ctx)
), archive AS (
  SELECT md5(string_agg(
      'ARCHIVE|'||contract_version||'|'||scenario_id||'|'||merchant_application_id||'|'||contract_row_hash,
      '||' ORDER BY contract_version,scenario_id,merchant_application_id
  )) AS h
  FROM msbf_m1.application_module1_archive
  WHERE module1_run_id=(SELECT run_id FROM _m1_15_ctx)
), compare AS (
  SELECT md5(string_agg(
      'COMPARE|'||merchant_application_id||'|'||comparison_row_hash,
      '||' ORDER BY merchant_application_id
  )) AS h
  FROM msbf_m1.application_module1_scenario_comparison
  WHERE module1_run_id=(SELECT run_id FROM _m1_15_ctx)
)
SELECT latest.h AS latest_hash,archive.h AS archive_hash,compare.h AS comparison_hash
FROM latest CROSS JOIN archive CROSS JOIN compare;

INSERT INTO msbf_ctl.m1_15_consumption_contract_registry(
    contract_code,contract_version,module1_run_id,schema_version,scenario_set_id,
    contract_status,latest_row_count,archive_row_count,comparison_row_count,
    latest_set_hash,archive_set_hash,comparison_set_hash,contract_set_hash,
    combined_set_hash,contract_row_hash,created_by_run_id
)
SELECT
    'M1_APPLICATION_CONSUMPTION',1,ctx.run_id,'M1_CONTRACT_SCHEMA_V1',ctx.scenario_set_id,
    'GENERATED',1500,1500,750,
    h.latest_hash,h.archive_hash,h.comparison_hash,
    md5('M1_APPLICATION_CONSUMPTION|1|'||ctx.run_id||'|M1_CONTRACT_SCHEMA_V1|'||
        h.latest_hash||'|'||h.archive_hash||'|'||h.comparison_hash),
    '',
    '',
    ctx.run_id
FROM _m1_15_ctx ctx CROSS JOIN _m1_15_hashes h;

UPDATE msbf_ctl.m1_15_consumption_contract_registry c
SET contract_row_hash=msbf_m1.m1_15_hash_jsonb(
    to_jsonb(c)
      -'contract_row_hash'
      -'combined_set_hash'
      -'contract_status'
      -'generated_at'
      -'validated_at'
)
WHERE c.module1_run_id=(SELECT run_id FROM _m1_15_ctx);

WITH all_entities AS (
  SELECT ('LATEST|'||scenario_id::text||'|'||merchant_application_id)::text AS entity_key,
         contract_row_hash::text AS row_hash
  FROM msbf_m1.application_module1_latest
  WHERE module1_run_id=(SELECT run_id FROM _m1_15_ctx)
  UNION ALL
  SELECT ('ARCHIVE|'||contract_version::text||'|'||scenario_id::text||'|'||merchant_application_id)::text,
         contract_row_hash::text
  FROM msbf_m1.application_module1_archive
  WHERE module1_run_id=(SELECT run_id FROM _m1_15_ctx)
  UNION ALL
  SELECT ('COMPARE|'||merchant_application_id)::text,comparison_row_hash::text
  FROM msbf_m1.application_module1_scenario_comparison
  WHERE module1_run_id=(SELECT run_id FROM _m1_15_ctx)
  UNION ALL
  SELECT ('CONTRACT|'||contract_code||'|'||contract_version::text||'|'||module1_run_id::text)::text,
         contract_row_hash::text
  FROM msbf_ctl.m1_15_consumption_contract_registry
  WHERE module1_run_id=(SELECT run_id FROM _m1_15_ctx)
)
UPDATE msbf_ctl.m1_15_consumption_contract_registry c
SET combined_set_hash=(
    SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key))
    FROM all_entities
)
WHERE c.module1_run_id=(SELECT run_id FROM _m1_15_ctx);

DO $notice_5$ BEGIN RAISE NOTICE 'M1.15 Phase 5/5 — reconcile canonical entities and persist evidence'; END; $notice_5$;

DROP TABLE IF EXISTS _m1_15_reconciliation;
CREATE TEMP TABLE _m1_15_reconciliation ON COMMIT DROP AS
WITH expected_latest AS (
  SELECT ('LATEST|'||scenario_id::text||'|'||merchant_application_id)::text AS entity_key,
         contract_row_hash::text AS row_hash
  FROM _m1_15_latest_expected
), actual_latest AS (
  SELECT ('LATEST|'||scenario_id::text||'|'||merchant_application_id)::text AS entity_key,
         contract_row_hash::text AS row_hash
  FROM msbf_m1.application_module1_latest
  WHERE module1_run_id=(SELECT run_id FROM _m1_15_ctx)
), expected_compare AS (
  SELECT 'COMPARE|'||merchant_application_id AS entity_key,
         comparison_row_hash AS row_hash
  FROM _m1_15_comparison_expected
), actual_compare AS (
  SELECT 'COMPARE|'||merchant_application_id AS entity_key,
         comparison_row_hash AS row_hash
  FROM msbf_m1.application_module1_scenario_comparison
  WHERE module1_run_id=(SELECT run_id FROM _m1_15_ctx)
), latest_mismatch AS (
  SELECT count(*) AS n FROM expected_latest e FULL JOIN actual_latest a
    ON a.entity_key=e.entity_key
  WHERE e.row_hash IS DISTINCT FROM a.row_hash
), compare_mismatch AS (
  SELECT count(*) AS n FROM expected_compare e FULL JOIN actual_compare a
    ON a.entity_key=e.entity_key
  WHERE e.row_hash IS DISTINCT FROM a.row_hash
), archive_mismatch AS (
  SELECT count(*) AS n
  FROM msbf_m1.application_module1_archive a
  JOIN msbf_m1.application_module1_latest l
    ON l.module1_run_id=a.module1_run_id
   AND l.scenario_id=a.scenario_id
   AND l.merchant_application_id=a.merchant_application_id
  WHERE a.module1_run_id=(SELECT run_id FROM _m1_15_ctx)
    AND (
      a.contract_row_hash IS DISTINCT FROM l.contract_row_hash
      OR a.contract_payload IS DISTINCT FROM to_jsonb(l)-'created_at'
    )
), contract_mismatch AS (
  SELECT count(*) AS n
  FROM msbf_ctl.m1_15_consumption_contract_registry c
  WHERE c.module1_run_id=(SELECT run_id FROM _m1_15_ctx)
    AND c.contract_row_hash IS DISTINCT FROM msbf_m1.m1_15_hash_jsonb(
      to_jsonb(c)
        -'contract_row_hash'
        -'combined_set_hash'
        -'contract_status'
        -'generated_at'
        -'validated_at'
    )
)
SELECT
  1500::bigint AS expected_latest_rows,
  (SELECT count(*) FROM msbf_m1.application_module1_latest
   WHERE module1_run_id=(SELECT run_id FROM _m1_15_ctx))::bigint AS actual_latest_rows,
  1500::bigint AS expected_archive_rows,
  (SELECT count(*) FROM msbf_m1.application_module1_archive
   WHERE module1_run_id=(SELECT run_id FROM _m1_15_ctx))::bigint AS actual_archive_rows,
  750::bigint AS expected_comparison_rows,
  (SELECT count(*) FROM msbf_m1.application_module1_scenario_comparison
   WHERE module1_run_id=(SELECT run_id FROM _m1_15_ctx))::bigint AS actual_comparison_rows,
  (SELECT n FROM latest_mismatch)
 + (SELECT n FROM compare_mismatch)
 + (SELECT n FROM archive_mismatch)
 + (SELECT n FROM contract_mismatch) AS row_level_mismatches;

DO $reconcile$
DECLARE v record;
BEGIN
    SELECT * INTO v FROM _m1_15_reconciliation;
    IF v.actual_latest_rows<>v.expected_latest_rows
       OR v.actual_archive_rows<>v.expected_archive_rows
       OR v.actual_comparison_rows<>v.expected_comparison_rows
       OR v.row_level_mismatches<>0 THEN
        RAISE EXCEPTION 'M1.15 canonical reconciliation failed: %',row_to_json(v);
    END IF;
END;
$reconcile$;

DELETE FROM msbf_ctl.run_evidence
WHERE run_id=(SELECT run_id FROM _m1_15_ctx)
  AND evidence_code LIKE 'M1_15_%';

/* ---------------------------------------------------------------------------
Persist generation evidence through a target-typed staging table.

PostgreSQL resolves UNION columns from left to right. In the superseded R1
source, five leading NULL values caused metric_value_numeric to resolve as
text before the later bigint mismatch count was encountered. The explicit
staging schema below eliminates unknown-literal type inference entirely.
--------------------------------------------------------------------------- */
DROP TABLE IF EXISTS _m1_15_generation_evidence;
CREATE TEMP TABLE _m1_15_generation_evidence(
    run_id bigint NOT NULL,
    evidence_code text NOT NULL,
    segment_key text NOT NULL,
    metric_name text NOT NULL,
    metric_value_numeric numeric(24,10),
    metric_value_text text,
    unit_code text NOT NULL,
    status text NOT NULL,
    interpretation text NOT NULL,
    CONSTRAINT ck_m1_15_generation_evidence_value
        CHECK (num_nonnulls(metric_value_numeric,metric_value_text)=1)
) ON COMMIT DROP;

INSERT INTO _m1_15_generation_evidence
SELECT run_id,'M1_15_LATEST_SET_HASH','PORTFOLIO','M1.15 latest set hash',
       NULL::numeric(24,10),
       (SELECT latest_set_hash::text
        FROM msbf_ctl.m1_15_consumption_contract_registry
        WHERE module1_run_id=run_id),
       'HASH','PASS','Canonical hash of 1,500 scenario-aware latest contract rows.'
FROM _m1_15_ctx;

INSERT INTO _m1_15_generation_evidence
SELECT run_id,'M1_15_ARCHIVE_SET_HASH','PORTFOLIO','M1.15 archive set hash',
       NULL::numeric(24,10),
       (SELECT archive_set_hash::text
        FROM msbf_ctl.m1_15_consumption_contract_registry
        WHERE module1_run_id=run_id),
       'HASH','PASS','Canonical hash of 1,500 immutable archive rows.'
FROM _m1_15_ctx;

INSERT INTO _m1_15_generation_evidence
SELECT run_id,'M1_15_COMPARISON_SET_HASH','PORTFOLIO','M1.15 comparison set hash',
       NULL::numeric(24,10),
       (SELECT comparison_set_hash::text
        FROM msbf_ctl.m1_15_consumption_contract_registry
        WHERE module1_run_id=run_id),
       'HASH','PASS','Canonical hash of 750 matched scenario-comparison rows.'
FROM _m1_15_ctx;

INSERT INTO _m1_15_generation_evidence
SELECT run_id,'M1_15_CONTRACT_SET_HASH','PORTFOLIO','M1.15 contract set hash',
       NULL::numeric(24,10),
       (SELECT contract_set_hash::text
        FROM msbf_ctl.m1_15_consumption_contract_registry
        WHERE module1_run_id=run_id),
       'HASH','PASS','Governed contract identity hash.'
FROM _m1_15_ctx;

INSERT INTO _m1_15_generation_evidence
SELECT run_id,'M1_15_COMBINED_SET_HASH','PORTFOLIO','M1.15 combined set hash',
       NULL::numeric(24,10),
       (SELECT combined_set_hash::text
        FROM msbf_ctl.m1_15_consumption_contract_registry
        WHERE module1_run_id=run_id),
       'HASH','PASS','Combined canonical hash across 3,751 contract entities.'
FROM _m1_15_ctx;

INSERT INTO _m1_15_generation_evidence
SELECT run_id,'M1_15_CANONICAL_MISMATCH_COUNT','PORTFOLIO',
       'M1.15 canonical mismatch count',
       (SELECT row_level_mismatches::numeric(24,10)
        FROM _m1_15_reconciliation),
       NULL::text,'COUNT','PASS',
       'Expected and physical contract entities reconcile exactly.'
FROM _m1_15_ctx;

INSERT INTO _m1_15_generation_evidence
SELECT run_id,'M1_15_GENERATION_SUMMARY','PORTFOLIO','M1.15 generation summary',
       NULL::numeric(24,10),
       format('latest=1500|archive=1500|comparison=750|contract=1|canonical=3751|mismatches=0')::text,
       'TEXT','PASS','M1.15 governed contract generation completed.'
FROM _m1_15_ctx;

DO $generation_evidence_guard$
BEGIN
    IF (SELECT count(*) FROM _m1_15_generation_evidence)<>7
       OR EXISTS (
           SELECT 1
           FROM _m1_15_generation_evidence
           WHERE num_nonnulls(metric_value_numeric,metric_value_text)<>1
       ) THEN
        RAISE EXCEPTION 'M1.15 generation-evidence staging failed its typed-value contract.';
    END IF;
END;
$generation_evidence_guard$;

INSERT INTO msbf_ctl.run_evidence(
    run_id,evidence_code,segment_key,metric_name,metric_value_numeric,
    metric_value_text,unit_code,status,interpretation
)
SELECT
    run_id,evidence_code,segment_key,metric_name,metric_value_numeric,
    metric_value_text,unit_code,status,interpretation
FROM _m1_15_generation_evidence;

UPDATE msbf_ctl.run_registry
SET run_status='M1_15_GENERATED',
    row_count=3751,
    notes=concat_ws(E'\n',notes,'M1.15 latest/archive/comparison contract generated.'),
    completed_at=NULL
WHERE run_id=(SELECT run_id FROM _m1_15_ctx);

DROP TABLE IF EXISTS _m1_15_generation_result;
CREATE TEMP TABLE _m1_15_generation_result ON COMMIT PRESERVE ROWS AS
SELECT
    r.run_id,r.run_status,
    c.contract_code,c.contract_version,c.schema_version,c.contract_status,
    c.latest_row_count AS latest_rows,
    c.archive_row_count AS archive_rows,
    c.comparison_row_count AS comparison_rows,
    750::integer AS applications,
    2::integer AS scenarios,
    3751::integer AS canonical_entities,
    rec.row_level_mismatches,
    c.latest_set_hash,c.archive_set_hash,c.comparison_set_hash,
    c.contract_set_hash,c.combined_set_hash,
    CASE
      WHEN r.run_status='M1_15_GENERATED'
       AND c.latest_row_count=1500
       AND c.archive_row_count=1500
       AND c.comparison_row_count=750
       AND rec.row_level_mismatches=0
      THEN 'PASS' ELSE 'FAIL'
    END AS generation_status
FROM msbf_ctl.run_registry r
JOIN msbf_ctl.m1_15_consumption_contract_registry c
  ON c.module1_run_id=r.run_id
CROSS JOIN _m1_15_reconciliation rec
WHERE r.run_id=(SELECT run_id FROM _m1_15_ctx);

COMMIT;

SELECT * FROM _m1_15_generation_result;
