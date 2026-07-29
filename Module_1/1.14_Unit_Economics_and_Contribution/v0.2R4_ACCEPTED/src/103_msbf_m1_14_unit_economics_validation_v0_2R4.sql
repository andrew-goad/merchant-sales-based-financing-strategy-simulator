/* ============================================================================
MSBF M1.14 Unit Economics & Risk-Adjusted Contribution — Positive Validation
Program : 103_msbf_m1_14_unit_economics_validation_v0_2R4.sql
Version : v0.2R4
Purpose : Execute the complete blocking validation framework over persisted
          M1.14 snapshots, components, policy, identities, stress controls,
          hashes, evidence, and stage boundaries.
Output  : One filterable 82-row result set preserved after COMMIT in the same
          DBeaver session.
Boundary: Read and validate persisted M1.14 evidence; do not regenerate logic.
============================================================================ */

BEGIN;
SET LOCAL work_mem='64MB';
SET LOCAL jit=off;
SET LOCAL statement_timeout='15min';


/* Fail closed if the physical blocked-evidence contract is not the approved V2 contract. */
DO $assert_blocked_contract$
DECLARE
    v_def text;
    v_validated boolean;
    v_comment text;
BEGIN
    SELECT pg_get_constraintdef(c.oid),c.convalidated,obj_description(c.oid,'pg_constraint')
    INTO STRICT v_def,v_validated,v_comment
    FROM pg_constraint c
    JOIN pg_class t ON t.oid=c.conrelid
    JOIN pg_namespace n ON n.oid=t.relnamespace
    WHERE n.nspname='msbf_m1'
      AND t.relname='application_unit_economics_snapshot'
      AND c.conname='ck_m1_14_blocked';

    IF NOT v_validated
       OR coalesce(v_comment,'') NOT LIKE 'MSBF_M1_14_BLOCKED_CONTRACT_V2%'
       OR position('(baseline_risk_adjusted_contribution_amount is null)' in lower(v_def))>0
       OR position('(baseline_annualized_risk_adjusted_return_rate is null)' in lower(v_def))>0
       OR position('(comparative_expected_loss_amount is null)' in lower(v_def))=0
       OR position('(contribution_after_comparative_loss_amount is null)' in lower(v_def))=0
       OR position('(independent_risk_adjusted_contribution_amount is null)' in lower(v_def))=0
       OR position('(risk_adjusted_contribution_amount is null)' in lower(v_def))=0
       OR position('(contribution_after_loss_margin_rate is null)' in lower(v_def))=0
       OR position('(independent_risk_adjusted_contribution_margin_rate is null)' in lower(v_def))=0
       OR position('(risk_adjusted_contribution_margin_rate is null)' in lower(v_def))=0
       OR position('(independent_annualized_risk_adjusted_return_rate is null)' in lower(v_def))=0
       OR position('(annualized_risk_adjusted_return_rate is null)' in lower(v_def))=0
       OR position('(economic_surplus_amount is null)' in lower(v_def))=0 THEN
        RAISE EXCEPTION
            'M1.14 approved blocked-evidence contract is not installed: validated %, comment %, definition %.',
            v_validated,coalesce(v_comment,''),v_def;
    END IF;
END;
$assert_blocked_contract$;


DROP TABLE IF EXISTS _m1_14_validation;
CREATE TEMP TABLE _m1_14_validation (
    evidence_code text PRIMARY KEY,
    metric_name text NOT NULL,
    observed_value text,
    threshold_value text,
    status text NOT NULL,
    interpretation text
) ON COMMIT PRESERVE ROWS;

CREATE OR REPLACE FUNCTION pg_temp.m1_14_add_check(
    p_code text,p_name text,p_observed text,p_threshold text,
    p_pass boolean,p_interpretation text
) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO _m1_14_validation VALUES(
        p_code,p_name,p_observed,p_threshold,
        CASE WHEN coalesce(p_pass,false) THEN 'PASS' ELSE 'FAIL' END,
        p_interpretation
    );
END;
$$;

CREATE TEMP TABLE _m1_14_vrun ON COMMIT DROP AS
SELECT run_id,run_status,population_id,as_of_date,
       parameter_snapshot_hash,profile_snapshot_hash,source_snapshot_hash
FROM msbf_ctl.run_registry
WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1;

CREATE TEMP TABLE _m1_14_vgates ON COMMIT DROP AS
SELECT DISTINCT ON (gate_id) gate_id,result_status
FROM msbf_ctl.acceptance_gate_result
WHERE run_id=(SELECT run_id FROM _m1_14_vrun)
  AND gate_id IN (
      'G1_CONTROL_PLANE','M1_2_POPULATION','M1_3_APPLICATION_REQUEST',
      'M1_4_DAILY_POS_HISTORY','M1_5_DAILY_DEPOSIT_LIQUIDITY',
      'M1_6_MATCHED_SCENARIO_OVERLAYS','M1_7_SOURCE_QUALITY_CONFIDENCE',
      'M1_8_VERIFICATION_FRAUD_CONTINUITY','M1_9_ASOF_CASHFLOW_FEATURES',
      'M1_10_OBLIGATIONS_LIQUIDITY_CAPACITY','M1_11_CASHFLOW_ARCHETYPE_RESILIENCE',
      'M1_12_INTEGRATED_RISK_PROXY','M1_13_EXPOSURE_RECOVERY_LOSS_FOUNDATIONS'
  )
ORDER BY gate_id,review_version DESC;

CREATE TEMP TABLE _m1_14_vpolicy ON COMMIT DROP AS
SELECT status,profile_payload
FROM msbf_ctl.policy_profile
WHERE profile_code='M1_14_UNIT_ECONOMICS_CONTRIBUTION' AND profile_version=1;

CREATE TEMP TABLE _m1_14_vs ON COMMIT DROP AS
SELECT e.*,sr.scenario_code
FROM msbf_m1.application_unit_economics_snapshot e
JOIN msbf_ctl.scenario_registry sr USING(scenario_id)
WHERE e.module1_run_id=(SELECT run_id FROM _m1_14_vrun);
CREATE UNIQUE INDEX ON _m1_14_vs(scenario_id,merchant_application_id);
ANALYZE _m1_14_vs;

CREATE TEMP TABLE _m1_14_vc ON COMMIT DROP AS
SELECT * FROM msbf_m1.unit_economics_component_value
WHERE module1_run_id=(SELECT run_id FROM _m1_14_vrun);
CREATE UNIQUE INDEX ON _m1_14_vc(scenario_id,merchant_application_id,component_code);
ANALYZE _m1_14_vc;

CREATE TEMP TABLE _m1_14_vbaseline ON COMMIT DROP AS
SELECT merchant_application_id,
       risk_adjusted_contribution_amount AS baseline_risk_adjusted_contribution_amount,
       annualized_risk_adjusted_return_rate AS baseline_annualized_risk_adjusted_return_rate,
       economic_tier AS baseline_economic_tier
FROM _m1_14_vs WHERE scenario_code='BASELINE';
CREATE UNIQUE INDEX ON _m1_14_vbaseline(merchant_application_id);

CREATE TEMP TABLE _m1_14_vevidence ON COMMIT DROP AS
SELECT evidence_code,metric_value_text,metric_value_numeric,status
FROM msbf_ctl.run_evidence
WHERE run_id=(SELECT run_id FROM _m1_14_vrun);
CREATE INDEX ON _m1_14_vevidence(evidence_code);

CREATE TEMP TABLE _m1_14_vactual ON COMMIT DROP AS
SELECT * FROM msbf_m1.m1_14_actual_snapshot((SELECT run_id FROM _m1_14_vrun))
UNION ALL
SELECT * FROM msbf_m1.m1_14_actual_component_snapshot((SELECT run_id FROM _m1_14_vrun));
CREATE UNIQUE INDEX ON _m1_14_vactual(entity_key);

CREATE TEMP TABLE _m1_14_vhash ON COMMIT DROP AS
SELECT
    count(*) AS canonical_entities,
    (SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) FROM _m1_14_vactual WHERE entity_key LIKE 'ECON|%') AS snapshot_hash,
    (SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) FROM _m1_14_vactual WHERE entity_key LIKE 'COMP|%') AS component_hash,
    md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) AS combined_hash
FROM _m1_14_vactual;

DO $checks$
BEGIN
    PERFORM pg_temp.m1_14_add_check('M1_14_POS_01_RUN_STATUS', 'Prerequisite generated run status', ((SELECT run_status FROM _m1_14_vrun))::text, ('M1_14_GENERATED')::text, ((SELECT run_status='M1_14_GENERATED' FROM _m1_14_vrun)), 'Validation starts only from the committed M1.14 generation state.');
    PERFORM pg_temp.m1_14_add_check('M1_14_POS_02_PREREQUISITE_GATES', 'Accepted predecessor gate count', ((SELECT count(*)::text FROM _m1_14_vgates WHERE result_status='PASS'))::text, ('13')::text, ((SELECT count(*)=13 FROM _m1_14_vgates WHERE result_status='PASS')), 'All G1 through M1.13 prerequisite gates remain accepted.');
    PERFORM pg_temp.m1_14_add_check('M1_14_POS_03_PARAMETER_HASH', 'Parameter snapshot hash preservation', ((SELECT parameter_snapshot_hash FROM _m1_14_vrun))::text, ('bd09e598c82db96e47459d77fd11e7c8')::text, ((SELECT parameter_snapshot_hash='bd09e598c82db96e47459d77fd11e7c8' FROM _m1_14_vrun)), 'Accepted G1 parameter snapshot remains unchanged.');
    PERFORM pg_temp.m1_14_add_check('M1_14_POS_04_PROFILE_HASH', 'Profile snapshot hash preservation', ((SELECT profile_snapshot_hash FROM _m1_14_vrun))::text, ('462cbd2ed92f68e5bdecf6b17537a973')::text, ((SELECT profile_snapshot_hash='462cbd2ed92f68e5bdecf6b17537a973' FROM _m1_14_vrun)), 'Accepted G1 profile snapshot remains unchanged.');
    PERFORM pg_temp.m1_14_add_check('M1_14_POS_05_SOURCE_HASH', 'Source snapshot hash preservation', ((SELECT source_snapshot_hash FROM _m1_14_vrun))::text, ('93c3d1368fb2450ab4a08e2b721f92d3')::text, ((SELECT source_snapshot_hash='93c3d1368fb2450ab4a08e2b721f92d3' FROM _m1_14_vrun)), 'Accepted G1 source snapshot remains unchanged.');
    PERFORM pg_temp.m1_14_add_check('M1_14_POS_06_POPULATION_HASH', 'Population hash preservation', ((SELECT population_hash FROM msbf_m1.population_registry WHERE population_id=(SELECT population_id FROM _m1_14_vrun)))::text, ('9b706c926260a3ef1ae8ac95eed5d0bf')::text, ((SELECT population_hash='9b706c926260a3ef1ae8ac95eed5d0bf' FROM msbf_m1.population_registry WHERE population_id=(SELECT population_id FROM _m1_14_vrun))), 'Accepted deterministic population remains unchanged.');
    PERFORM pg_temp.m1_14_add_check('M1_14_POS_07_APPLICATION_HASH', 'Application set hash preservation', ((SELECT metric_value_text FROM _m1_14_vevidence WHERE evidence_code='M1_3_APPLICATION_SET_HASH'))::text, ('01485256b9b5748fb412743d35ced602')::text, ((SELECT metric_value_text='01485256b9b5748fb412743d35ced602' FROM _m1_14_vevidence WHERE evidence_code='M1_3_APPLICATION_SET_HASH')), 'Accepted M1.3 application population remains unchanged.');
    PERFORM pg_temp.m1_14_add_check('M1_14_POS_08_SCENARIO_HASH', 'Scenario set hash preservation', ((SELECT metric_value_text FROM _m1_14_vevidence WHERE evidence_code='M1_6_COMBINED_SET_HASH'))::text, ('3f85921bf6fc30ddc6cee146085e58c5')::text, ((SELECT metric_value_text='3f85921bf6fc30ddc6cee146085e58c5' FROM _m1_14_vevidence WHERE evidence_code='M1_6_COMBINED_SET_HASH')), 'Accepted matched scenario population remains unchanged.');
    PERFORM pg_temp.m1_14_add_check('M1_14_POS_09_CAPACITY_HASH', 'Capacity set hash preservation', ((SELECT metric_value_text FROM _m1_14_vevidence WHERE evidence_code='M1_10_COMBINED_SET_HASH'))::text, ('a91e82a315305a98953d013043a17d9a')::text, ((SELECT metric_value_text='a91e82a315305a98953d013043a17d9a' FROM _m1_14_vevidence WHERE evidence_code='M1_10_COMBINED_SET_HASH')), 'Accepted M1.10 capacity evidence remains unchanged.');
    PERFORM pg_temp.m1_14_add_check('M1_14_POS_10_LOSS_HASH', 'Exposure/recovery/loss set hash preservation', ((SELECT metric_value_text FROM _m1_14_vevidence WHERE evidence_code='M1_13_COMBINED_SET_HASH'))::text, ('11dca65763f4062ad9002244ee6452f9')::text, ((SELECT metric_value_text='11dca65763f4062ad9002244ee6452f9' FROM _m1_14_vevidence WHERE evidence_code='M1_13_COMBINED_SET_HASH')), 'Accepted M1.13 exposure/recovery/loss evidence remains unchanged.');
    PERFORM pg_temp.m1_14_add_check('M1_14_POS_11_POLICY_APPROVED', 'M1.14 policy approval', ((SELECT status FROM _m1_14_vpolicy))::text, ('APPROVED')::text, ((SELECT status='APPROVED' FROM _m1_14_vpolicy)), 'The M1.14 methodology profile is approved.');
    PERFORM pg_temp.m1_14_add_check('M1_14_POS_12_METHOD_VERSION', 'Governed methodology version', ((SELECT profile_payload->>'methodology_version' FROM _m1_14_vpolicy))::text, ('M1_14_METHOD_V1')::text, ((SELECT profile_payload->>'methodology_version'='M1_14_METHOD_V1' FROM _m1_14_vpolicy)), 'The accepted generation uses the governed M1.14 methodology version.');
    PERFORM pg_temp.m1_14_add_check('M1_14_POS_13_METHOD_BASES', 'Governed economics bases', ((SELECT concat_ws('|',profile_payload->>'contribution_basis_code',profile_payload->>'comparative_loss_basis_code',profile_payload->>'funding_cost_basis_code',profile_payload->>'risk_capital_charge_basis_code',profile_payload->>'hurdle_basis_code') FROM _m1_14_vpolicy))::text, ('CONDITIONAL_IF_BOOKED|M1_13_SCHEDULE_ADJUSTED_COMPARATIVE_LOSS|PATH_WEIGHTED_EAD_X_ANNUAL_RATE_X_TERM|PATH_WEIGHTED_EAD_X_CAPITAL_X_COST_OF_CAPITAL_X_TERM|FUNDED_AMOUNT_X_ANNUAL_HURDLE_X_TERM')::text, ((SELECT profile_payload->>'contribution_basis_code'='CONDITIONAL_IF_BOOKED' AND profile_payload->>'comparative_loss_basis_code'='M1_13_SCHEDULE_ADJUSTED_COMPARATIVE_LOSS' AND profile_payload->>'funding_cost_basis_code'='PATH_WEIGHTED_EAD_X_ANNUAL_RATE_X_TERM' AND profile_payload->>'risk_capital_charge_basis_code'='PATH_WEIGHTED_EAD_X_CAPITAL_X_COST_OF_CAPITAL_X_TERM' AND profile_payload->>'hurdle_basis_code'='FUNDED_AMOUNT_X_ANNUAL_HURDLE_X_TERM' FROM _m1_14_vpolicy)), 'Contribution, loss, funding, capital, and hurdle bases match the approved specification.');
    PERFORM pg_temp.m1_14_add_check('M1_14_POS_14_STRESS_CONTROLS', 'Adverse-scenario economic floors', ((SELECT concat_ws('|',profile_payload->>'stress_contribution_cap_to_baseline',profile_payload->>'stress_return_cap_to_baseline',profile_payload->>'stress_economic_tier_floor_to_baseline') FROM _m1_14_vpolicy))::text, ('true|true|true')::text, ((SELECT (profile_payload->>'stress_contribution_cap_to_baseline')::boolean AND (profile_payload->>'stress_return_cap_to_baseline')::boolean AND (profile_payload->>'stress_economic_tier_floor_to_baseline')::boolean FROM _m1_14_vpolicy)), 'All governed stress non-improvement controls are enabled.');
    PERFORM pg_temp.m1_14_add_check('M1_14_POS_15_PARAMETER_BOUNDS', 'Governed economic parameter bounds', ((SELECT 'validated'))::text, ('all bounded')::text, ((SELECT (profile_payload->>'processor_payment_cost_rate')::numeric BETWEEN 0 AND 1 AND (profile_payload->>'default_partner_acquisition_cost_rate')::numeric BETWEEN 0 AND (profile_payload->>'partner_acquisition_cost_rate_cap')::numeric AND (profile_payload->>'partner_acquisition_cost_rate_cap')::numeric BETWEEN 0 AND 1 AND (profile_payload->>'funding_cost_annual_rate')::numeric BETWEEN 0 AND 1 AND (profile_payload->>'servicing_daily_cost_amount')::numeric>=0 AND (profile_payload->>'servicing_variable_cost_rate')::numeric BETWEEN 0 AND 1 AND (profile_payload->>'operating_cost_fixed_amount')::numeric>=0 AND (profile_payload->>'operating_cost_variable_rate')::numeric BETWEEN 0 AND 1 AND (profile_payload->>'risk_capital_allocation_rate')::numeric BETWEEN 0 AND 1 AND (profile_payload->>'risk_capital_cost_annual_rate')::numeric BETWEEN 0 AND 1 AND (profile_payload->>'hurdle_annual_return_rate')::numeric BETWEEN 0 AND 1 FROM _m1_14_vpolicy)), 'All governed rate and amount assumptions are within approved bounds.');
    PERFORM pg_temp.m1_14_add_check('M1_14_POS_16_TIER_ORDER', 'Economic tier threshold order', ((SELECT concat_ws('>',profile_payload->>'economic_tier_1_return_threshold',profile_payload->>'economic_tier_2_return_threshold',profile_payload->>'economic_tier_3_return_threshold') FROM _m1_14_vpolicy))::text, ('strictly descending')::text, ((SELECT (profile_payload->>'economic_tier_1_return_threshold')::numeric>(profile_payload->>'economic_tier_2_return_threshold')::numeric AND (profile_payload->>'economic_tier_2_return_threshold')::numeric>(profile_payload->>'economic_tier_3_return_threshold')::numeric AND (profile_payload->>'economic_tier_3_return_threshold')::numeric>=0 FROM _m1_14_vpolicy)), 'Economic tier thresholds are strictly ordered.');
    PERFORM pg_temp.m1_14_add_check('M1_14_POS_17_SNAPSHOT_ROWS', 'Unit-economics snapshot count', ((SELECT count(*)::text FROM _m1_14_vs))::text, ('1500')::text, ((SELECT count(*)=1500 FROM _m1_14_vs)), 'Exactly 750 applications are represented under two scenarios.');
    PERFORM pg_temp.m1_14_add_check('M1_14_POS_18_COMPONENT_ROWS', 'Economics component row count', ((SELECT count(*)::text FROM _m1_14_vc))::text, ('21000')::text, ((SELECT count(*)=21000 FROM _m1_14_vc)), 'Fourteen component rows exist per scenario/application snapshot.');
    PERFORM pg_temp.m1_14_add_check('M1_14_POS_19_APPLICATION_COUNT', 'Distinct application count', ((SELECT count(DISTINCT merchant_application_id)::text FROM _m1_14_vs))::text, ('750')::text, ((SELECT count(DISTINCT merchant_application_id)=750 FROM _m1_14_vs)), 'All accepted applications are represented.');
    PERFORM pg_temp.m1_14_add_check('M1_14_POS_20_SCENARIO_COUNT', 'Distinct accepted scenario count', ((SELECT count(DISTINCT scenario_id)::text FROM _m1_14_vs))::text, ('2')::text, ((SELECT count(DISTINCT scenario_id)=2 FROM _m1_14_vs)), 'Baseline and recession scenarios are represented.');
    PERFORM pg_temp.m1_14_add_check('M1_14_POS_21_UNIQUE_SNAPSHOT_GRAIN', 'Unique snapshot grain', ((SELECT count(*)::text||'/'||count(DISTINCT (scenario_id,merchant_application_id))::text FROM _m1_14_vs))::text, ('1500/1500')::text, ((SELECT count(*)=count(DISTINCT (scenario_id,merchant_application_id)) FROM _m1_14_vs)), 'Snapshot scenario/application grain is unique.');
    PERFORM pg_temp.m1_14_add_check('M1_14_POS_22_UNIQUE_COMPONENT_GRAIN', 'Unique component grain', ((SELECT count(*)::text||'/'||count(DISTINCT (scenario_id,merchant_application_id,component_code))::text FROM _m1_14_vc))::text, ('21000/21000')::text, ((SELECT count(*)=count(DISTINCT (scenario_id,merchant_application_id,component_code)) FROM _m1_14_vc)), 'Component scenario/application/code grain is unique.');
    PERFORM pg_temp.m1_14_add_check('M1_14_POS_23_COMPONENTS_PER_SNAPSHOT', 'Fourteen components per snapshot', ((SELECT min(n)::text||'/'||max(n)::text FROM (SELECT count(*) n FROM _m1_14_vc GROUP BY scenario_id,merchant_application_id) q))::text, ('14/14')::text, ((SELECT min(n)=14 AND max(n)=14 FROM (SELECT count(*) n FROM _m1_14_vc GROUP BY scenario_id,merchant_application_id) q)), 'Every snapshot carries the complete governed component inventory.');
    PERFORM pg_temp.m1_14_add_check('M1_14_POS_24_BASELINE_ROWS', 'Baseline snapshot count', ((SELECT count(*)::text FROM _m1_14_vs WHERE scenario_code='BASELINE'))::text, ('750')::text, ((SELECT count(*)=750 FROM _m1_14_vs WHERE scenario_code='BASELINE')), 'Baseline contains all 750 applications.');
    PERFORM pg_temp.m1_14_add_check('M1_14_POS_25_STRESS_ROWS', 'Stress snapshot count', ((SELECT count(*)::text FROM _m1_14_vs WHERE scenario_code='RECESSION_ENERGY'))::text, ('750')::text, ((SELECT count(*)=750 FROM _m1_14_vs WHERE scenario_code='RECESSION_ENERGY')), 'Stress contains all 750 applications.');
    /* POS26 must hash the physical table record only. _m1_14_vs also contains
       scenario_code for analytical validation; that nonphysical reporting field
       is intentionally excluded from canonical snapshot hashing. */
    PERFORM pg_temp.m1_14_add_check(
        'M1_14_POS_26_SNAPSHOT_ROW_HASH',
        'Snapshot physical row-hash reconstruction',
        ((SELECT count(*)::text
          FROM msbf_m1.application_unit_economics_snapshot e
          WHERE e.module1_run_id=(SELECT run_id FROM _m1_14_vrun)
            AND e.row_hash IS DISTINCT FROM
                msbf_m1.m1_14_hash_jsonb(
                    to_jsonb(e)-'row_hash'-'created_at'
                ))),
        '0',
        ((SELECT count(*)=0
          FROM msbf_m1.application_unit_economics_snapshot e
          WHERE e.module1_run_id=(SELECT run_id FROM _m1_14_vrun)
            AND e.row_hash IS DISTINCT FROM
                msbf_m1.m1_14_hash_jsonb(
                    to_jsonb(e)-'row_hash'-'created_at'
                ))),
        'Every snapshot hash reconstructs from persisted physical table fields; reporting-only scenario enrichment is excluded.'
    );
    PERFORM pg_temp.m1_14_add_check('M1_14_POS_27_COMPONENT_ROW_HASH', 'Component physical hash reconstruction', ((SELECT count(*)::text FROM _m1_14_vc c WHERE c.calculation_hash<>msbf_m1.m1_14_hash_jsonb(to_jsonb(c)-'calculation_hash'-'created_at')))::text, ('0')::text, ((SELECT count(*)=0 FROM _m1_14_vc c WHERE c.calculation_hash<>msbf_m1.m1_14_hash_jsonb(to_jsonb(c)-'calculation_hash'-'created_at'))), 'Every component hash reconstructs from persisted physical fields.');
    PERFORM pg_temp.m1_14_add_check('M1_14_POS_28_REQUEST_AMOUNT_IDENTITY', 'Requested financing amount identity', ((SELECT count(*)::text FROM _m1_14_vs WHERE requested_finance_charge_amount<>requested_total_repayment_amount-requested_funding_amount))::text, ('0')::text, ((SELECT count(*)=0 FROM _m1_14_vs WHERE requested_finance_charge_amount<>requested_total_repayment_amount-requested_funding_amount)), 'Finance charge equals total repayment less requested funding.');
    PERFORM pg_temp.m1_14_add_check('M1_14_POS_29_PAYBACK_MULTIPLE_IDENTITY', 'Payback multiple identity', ((SELECT count(*)::text FROM _m1_14_vs WHERE payback_multiple IS DISTINCT FROM round(requested_total_repayment_amount/requested_funding_amount,8)::numeric(12,8)))::text, ('0')::text, ((SELECT count(*)=0 FROM _m1_14_vs WHERE payback_multiple IS DISTINCT FROM round(requested_total_repayment_amount/requested_funding_amount,8)::numeric(12,8))), 'Payback multiple reconciles to requested terms.');
    PERFORM pg_temp.m1_14_add_check('M1_14_POS_30_FINANCE_CHARGE_RATE_IDENTITY', 'Gross finance-charge rate identity', ((SELECT count(*)::text FROM _m1_14_vs WHERE gross_finance_charge_rate IS DISTINCT FROM round(requested_finance_charge_amount/requested_funding_amount,8)::numeric(12,8)))::text, ('0')::text, ((SELECT count(*)=0 FROM _m1_14_vs WHERE gross_finance_charge_rate IS DISTINCT FROM round(requested_finance_charge_amount/requested_funding_amount,8)::numeric(12,8))), 'Gross finance-charge rate reconciles to requested terms.');
    PERFORM pg_temp.m1_14_add_check('M1_14_POS_31_ANNUALIZED_GROSS_YIELD_IDENTITY', 'Annualized gross-yield identity', ((SELECT count(*)::text FROM _m1_14_vs WHERE annualized_gross_yield_rate IS DISTINCT FROM round(requested_finance_charge_amount/requested_funding_amount*365/requested_expected_payoff_days,8)::numeric(12,8)))::text, ('0')::text, ((SELECT count(*)=0 FROM _m1_14_vs WHERE annualized_gross_yield_rate IS DISTINCT FROM round(requested_finance_charge_amount/requested_funding_amount*365/requested_expected_payoff_days,8)::numeric(12,8))), 'Annualized gross yield uses the governed 365-day comparison basis.');
    PERFORM pg_temp.m1_14_add_check('M1_14_POS_32_PROCESSOR_COST_IDENTITY', 'Processor payment-cost identity', ((SELECT count(*)::text FROM _m1_14_vs WHERE processor_payment_cost_amount IS DISTINCT FROM round(requested_total_repayment_amount*processor_payment_cost_rate,2)::numeric(18,2)))::text, ('0')::text, ((SELECT count(*)=0 FROM _m1_14_vs WHERE processor_payment_cost_amount IS DISTINCT FROM round(requested_total_repayment_amount*processor_payment_cost_rate,2)::numeric(18,2))), 'Processor payment cost reconciles to the governed rate and repayment base.');
    PERFORM pg_temp.m1_14_add_check('M1_14_POS_33_PARTNER_COST_IDENTITY', 'Partner acquisition-cost identity', ((SELECT count(*)::text FROM _m1_14_vs WHERE partner_acquisition_cost_amount IS DISTINCT FROM round(requested_funding_amount*partner_acquisition_cost_rate,2)::numeric(18,2)))::text, ('0')::text, ((SELECT count(*)=0 FROM _m1_14_vs WHERE partner_acquisition_cost_amount IS DISTINCT FROM round(requested_funding_amount*partner_acquisition_cost_rate,2)::numeric(18,2))), 'Partner acquisition cost reconciles to funded amount and governed channel rate.');
    PERFORM pg_temp.m1_14_add_check('M1_14_POS_34_PARTNER_RATE_BOUNDS', 'Partner acquisition-rate support and cap', ((SELECT count(*)::text FROM _m1_14_vs WHERE partner_acquisition_cost_rate<0 OR partner_acquisition_cost_rate>(SELECT (profile_payload->>'partner_acquisition_cost_rate_cap')::numeric FROM _m1_14_vpolicy)))::text, ('0')::text, ((SELECT count(*)=0 FROM _m1_14_vs WHERE partner_acquisition_cost_rate<0 OR partner_acquisition_cost_rate>(SELECT (profile_payload->>'partner_acquisition_cost_rate_cap')::numeric FROM _m1_14_vpolicy))), 'Supported or default channel rates remain within the governed cap.');
    PERFORM pg_temp.m1_14_add_check('M1_14_POS_35_FUNDING_COST_IDENTITY', 'Funding-cost identity', ((SELECT count(*)::text FROM _m1_14_vs WHERE funding_cost_amount IS DISTINCT FROM round(path_weighted_ead_amount*funding_cost_annual_rate*requested_expected_payoff_days/365,2)::numeric(18,2)))::text, ('0')::text, ((SELECT count(*)=0 FROM _m1_14_vs WHERE funding_cost_amount IS DISTINCT FROM round(path_weighted_ead_amount*funding_cost_annual_rate*requested_expected_payoff_days/365,2)::numeric(18,2))), 'Funding cost uses path-weighted EAD, annual rate, and payoff fraction.');
    PERFORM pg_temp.m1_14_add_check('M1_14_POS_36_SERVICING_COST_IDENTITY', 'Servicing-cost identity', ((SELECT count(*)::text FROM _m1_14_vs WHERE servicing_cost_amount IS DISTINCT FROM round(servicing_daily_cost_amount*requested_expected_payoff_days+requested_total_repayment_amount*servicing_variable_cost_rate,2)::numeric(18,2)))::text, ('0')::text, ((SELECT count(*)=0 FROM _m1_14_vs WHERE servicing_cost_amount IS DISTINCT FROM round(servicing_daily_cost_amount*requested_expected_payoff_days+requested_total_repayment_amount*servicing_variable_cost_rate,2)::numeric(18,2))), 'Servicing cost reconciles to daily and variable cost foundations.');
    PERFORM pg_temp.m1_14_add_check('M1_14_POS_37_OPERATING_COST_IDENTITY', 'Operating-cost identity', ((SELECT count(*)::text FROM _m1_14_vs WHERE operating_cost_amount IS DISTINCT FROM round(operating_cost_fixed_amount+requested_funding_amount*operating_cost_variable_rate,2)::numeric(18,2)))::text, ('0')::text, ((SELECT count(*)=0 FROM _m1_14_vs WHERE operating_cost_amount IS DISTINCT FROM round(operating_cost_fixed_amount+requested_funding_amount*operating_cost_variable_rate,2)::numeric(18,2))), 'Operating cost reconciles to fixed and variable foundations.');
    PERFORM pg_temp.m1_14_add_check('M1_14_POS_38_TOTAL_NON_LOSS_COST_IDENTITY', 'Total non-loss-cost identity', ((SELECT count(*)::text FROM _m1_14_vs WHERE total_non_loss_cost_amount IS DISTINCT FROM round(processor_payment_cost_amount+partner_acquisition_cost_amount+funding_cost_amount+servicing_cost_amount+operating_cost_amount,2)::numeric(18,2)))::text, ('0')::text, ((SELECT count(*)=0 FROM _m1_14_vs WHERE total_non_loss_cost_amount IS DISTINCT FROM round(processor_payment_cost_amount+partner_acquisition_cost_amount+funding_cost_amount+servicing_cost_amount+operating_cost_amount,2)::numeric(18,2))), 'Total non-loss cost is the sum of five governed cost foundations.');
    PERFORM pg_temp.m1_14_add_check('M1_14_POS_39_PRE_LOSS_CONTRIBUTION_IDENTITY', 'Contribution-before-loss identity', ((SELECT count(*)::text FROM _m1_14_vs WHERE contribution_before_comparative_loss_amount IS DISTINCT FROM round(gross_finance_revenue_amount-total_non_loss_cost_amount,2)::numeric(18,2)))::text, ('0')::text, ((SELECT count(*)=0 FROM _m1_14_vs WHERE contribution_before_comparative_loss_amount IS DISTINCT FROM round(gross_finance_revenue_amount-total_non_loss_cost_amount,2)::numeric(18,2))), 'Contribution before comparative loss reconciles exactly.');
    PERFORM pg_temp.m1_14_add_check('M1_14_POS_40_COMPARATIVE_LOSS_REPRODUCTION', 'Accepted M1.13 comparative-loss reproduction', ((SELECT count(*)::text FROM _m1_14_vs e JOIN msbf_m1.application_exposure_recovery_loss_snapshot l USING(module1_run_id,scenario_id,merchant_application_id) WHERE e.comparative_expected_loss_amount IS DISTINCT FROM CASE WHEN e.unit_economics_evidence_status='BLOCKED' THEN NULL ELSE l.schedule_adjusted_comparative_expected_loss_amount END))::text, ('0')::text, ((SELECT count(*)=0 FROM _m1_14_vs e JOIN msbf_m1.application_exposure_recovery_loss_snapshot l USING(module1_run_id,scenario_id,merchant_application_id) WHERE e.comparative_expected_loss_amount IS DISTINCT FROM CASE WHEN e.unit_economics_evidence_status='BLOCKED' THEN NULL ELSE l.schedule_adjusted_comparative_expected_loss_amount END)), 'Comparative loss burden reproduces accepted M1.13 evidence with blocked gating.');
    PERFORM pg_temp.m1_14_add_check('M1_14_POS_41_AFTER_LOSS_CONTRIBUTION_IDENTITY', 'Contribution-after-loss identity', ((SELECT count(*)::text FROM _m1_14_vs WHERE unit_economics_evidence_status<>'BLOCKED' AND contribution_after_comparative_loss_amount IS DISTINCT FROM round(contribution_before_comparative_loss_amount-comparative_expected_loss_amount,2)::numeric(18,2)))::text, ('0')::text, ((SELECT count(*)=0 FROM _m1_14_vs WHERE unit_economics_evidence_status<>'BLOCKED' AND contribution_after_comparative_loss_amount IS DISTINCT FROM round(contribution_before_comparative_loss_amount-comparative_expected_loss_amount,2)::numeric(18,2))), 'Contribution after comparative loss reconciles exactly.');
    PERFORM pg_temp.m1_14_add_check('M1_14_POS_42_CAPITAL_CHARGE_IDENTITY', 'Synthetic risk-capital-charge identity', ((SELECT count(*)::text FROM _m1_14_vs WHERE risk_capital_charge_amount IS DISTINCT FROM round(path_weighted_ead_amount*risk_capital_allocation_rate*risk_capital_cost_annual_rate*requested_expected_payoff_days/365,2)::numeric(18,2)))::text, ('0')::text, ((SELECT count(*)=0 FROM _m1_14_vs WHERE risk_capital_charge_amount IS DISTINCT FROM round(path_weighted_ead_amount*risk_capital_allocation_rate*risk_capital_cost_annual_rate*requested_expected_payoff_days/365,2)::numeric(18,2))), 'Synthetic capital charge reconciles to path-weighted EAD and governed rates.');
    PERFORM pg_temp.m1_14_add_check('M1_14_POS_43_INDEPENDENT_RISK_ADJUSTED_CONTRIBUTION', 'Independent risk-adjusted contribution identity', ((SELECT count(*)::text FROM _m1_14_vs WHERE unit_economics_evidence_status<>'BLOCKED' AND independent_risk_adjusted_contribution_amount IS DISTINCT FROM round(contribution_after_comparative_loss_amount-risk_capital_charge_amount,2)::numeric(18,2)))::text, ('0')::text, ((SELECT count(*)=0 FROM _m1_14_vs WHERE unit_economics_evidence_status<>'BLOCKED' AND independent_risk_adjusted_contribution_amount IS DISTINCT FROM round(contribution_after_comparative_loss_amount-risk_capital_charge_amount,2)::numeric(18,2))), 'Independent risk-adjusted contribution reconciles exactly.');
    PERFORM pg_temp.m1_14_add_check('M1_14_POS_44_BASELINE_CONTRIBUTION_MAPPING', 'Baseline contribution mapping', ((SELECT count(*)::text FROM _m1_14_vs e JOIN _m1_14_vbaseline b USING(merchant_application_id) WHERE e.baseline_risk_adjusted_contribution_amount IS DISTINCT FROM b.baseline_risk_adjusted_contribution_amount))::text, ('0')::text, ((SELECT count(*)=0 FROM _m1_14_vs e JOIN _m1_14_vbaseline b USING(merchant_application_id) WHERE e.baseline_risk_adjusted_contribution_amount IS DISTINCT FROM b.baseline_risk_adjusted_contribution_amount)), 'Each matched row retains the accepted baseline contribution comparison.');
    PERFORM pg_temp.m1_14_add_check('M1_14_POS_45_BASELINE_FINAL_IDENTITY', 'Baseline final contribution identity', ((SELECT count(*)::text FROM _m1_14_vs WHERE scenario_code='BASELINE' AND risk_adjusted_contribution_amount IS DISTINCT FROM independent_risk_adjusted_contribution_amount))::text, ('0')::text, ((SELECT count(*)=0 FROM _m1_14_vs WHERE scenario_code='BASELINE' AND risk_adjusted_contribution_amount IS DISTINCT FROM independent_risk_adjusted_contribution_amount)), 'Baseline final contribution equals independently calculated contribution.');
    PERFORM pg_temp.m1_14_add_check('M1_14_POS_46_STRESS_CONTRIBUTION_NONIMPROVEMENT', 'Stress contribution non-improvement', ((SELECT count(*)::text FROM _m1_14_vs WHERE scenario_code='RECESSION_ENERGY' AND risk_adjusted_contribution_amount>baseline_risk_adjusted_contribution_amount))::text, ('0')::text, ((SELECT count(*)=0 FROM _m1_14_vs WHERE scenario_code='RECESSION_ENERGY' AND risk_adjusted_contribution_amount>baseline_risk_adjusted_contribution_amount)), 'Adverse scenario final contribution cannot improve relative to baseline.');
    PERFORM pg_temp.m1_14_add_check('M1_14_POS_47_PRE_LOSS_MARGIN_IDENTITY', 'Contribution-before-loss margin identity', ((SELECT count(*)::text FROM _m1_14_vs WHERE contribution_before_loss_margin_rate IS DISTINCT FROM round(contribution_before_comparative_loss_amount/requested_funding_amount,8)::numeric(12,8)))::text, ('0')::text, ((SELECT count(*)=0 FROM _m1_14_vs WHERE contribution_before_loss_margin_rate IS DISTINCT FROM round(contribution_before_comparative_loss_amount/requested_funding_amount,8)::numeric(12,8))), 'Pre-loss contribution margin reconciles to funded amount.');
    PERFORM pg_temp.m1_14_add_check('M1_14_POS_48_AFTER_LOSS_MARGIN_IDENTITY', 'Contribution-after-loss margin identity', ((SELECT count(*)::text FROM _m1_14_vs WHERE unit_economics_evidence_status<>'BLOCKED' AND contribution_after_loss_margin_rate IS DISTINCT FROM round(contribution_after_comparative_loss_amount/requested_funding_amount,8)::numeric(12,8)))::text, ('0')::text, ((SELECT count(*)=0 FROM _m1_14_vs WHERE unit_economics_evidence_status<>'BLOCKED' AND contribution_after_loss_margin_rate IS DISTINCT FROM round(contribution_after_comparative_loss_amount/requested_funding_amount,8)::numeric(12,8))), 'After-loss contribution margin reconciles to funded amount.');
    PERFORM pg_temp.m1_14_add_check('M1_14_POS_49_INDEPENDENT_MARGIN_IDENTITY', 'Independent risk-adjusted margin identity', ((SELECT count(*)::text FROM _m1_14_vs WHERE unit_economics_evidence_status<>'BLOCKED' AND independent_risk_adjusted_contribution_margin_rate IS DISTINCT FROM round(independent_risk_adjusted_contribution_amount/requested_funding_amount,8)::numeric(12,8)))::text, ('0')::text, ((SELECT count(*)=0 FROM _m1_14_vs WHERE unit_economics_evidence_status<>'BLOCKED' AND independent_risk_adjusted_contribution_margin_rate IS DISTINCT FROM round(independent_risk_adjusted_contribution_amount/requested_funding_amount,8)::numeric(12,8))), 'Independent risk-adjusted margin reconciles exactly.');
    PERFORM pg_temp.m1_14_add_check('M1_14_POS_50_FINAL_MARGIN_IDENTITY', 'Final risk-adjusted margin identity', ((SELECT count(*)::text FROM _m1_14_vs WHERE unit_economics_evidence_status<>'BLOCKED' AND risk_adjusted_contribution_margin_rate IS DISTINCT FROM round(risk_adjusted_contribution_amount/requested_funding_amount,8)::numeric(12,8)))::text, ('0')::text, ((SELECT count(*)=0 FROM _m1_14_vs WHERE unit_economics_evidence_status<>'BLOCKED' AND risk_adjusted_contribution_margin_rate IS DISTINCT FROM round(risk_adjusted_contribution_amount/requested_funding_amount,8)::numeric(12,8))), 'Final risk-adjusted contribution margin reconciles exactly.');
    PERFORM pg_temp.m1_14_add_check('M1_14_POS_51_INDEPENDENT_ANNUALIZED_RETURN', 'Independent annualized-return identity', ((SELECT count(*)::text FROM _m1_14_vs WHERE unit_economics_evidence_status<>'BLOCKED' AND independent_annualized_risk_adjusted_return_rate IS DISTINCT FROM round(independent_risk_adjusted_contribution_amount/requested_funding_amount*365/requested_expected_payoff_days,8)::numeric(12,8)))::text, ('0')::text, ((SELECT count(*)=0 FROM _m1_14_vs WHERE unit_economics_evidence_status<>'BLOCKED' AND independent_annualized_risk_adjusted_return_rate IS DISTINCT FROM round(independent_risk_adjusted_contribution_amount/requested_funding_amount*365/requested_expected_payoff_days,8)::numeric(12,8))), 'Independent annualized risk-adjusted return uses the governed term basis.');
    PERFORM pg_temp.m1_14_add_check('M1_14_POS_52_BASELINE_RETURN_MAPPING', 'Baseline annualized-return mapping', ((SELECT count(*)::text FROM _m1_14_vs e JOIN _m1_14_vbaseline b USING(merchant_application_id) WHERE e.baseline_annualized_risk_adjusted_return_rate IS DISTINCT FROM b.baseline_annualized_risk_adjusted_return_rate))::text, ('0')::text, ((SELECT count(*)=0 FROM _m1_14_vs e JOIN _m1_14_vbaseline b USING(merchant_application_id) WHERE e.baseline_annualized_risk_adjusted_return_rate IS DISTINCT FROM b.baseline_annualized_risk_adjusted_return_rate)), 'Each matched row retains the accepted baseline return comparison.');
    PERFORM pg_temp.m1_14_add_check('M1_14_POS_53_FINAL_ANNUALIZED_RETURN', 'Final annualized-return identity', ((SELECT count(*)::text FROM _m1_14_vs WHERE unit_economics_evidence_status<>'BLOCKED' AND annualized_risk_adjusted_return_rate IS DISTINCT FROM round(risk_adjusted_contribution_amount/requested_funding_amount*365/requested_expected_payoff_days,8)::numeric(12,8)))::text, ('0')::text, ((SELECT count(*)=0 FROM _m1_14_vs WHERE unit_economics_evidence_status<>'BLOCKED' AND annualized_risk_adjusted_return_rate IS DISTINCT FROM round(risk_adjusted_contribution_amount/requested_funding_amount*365/requested_expected_payoff_days,8)::numeric(12,8))), 'Final annualized risk-adjusted return reconciles exactly.');
    PERFORM pg_temp.m1_14_add_check('M1_14_POS_54_STRESS_RETURN_NONIMPROVEMENT', 'Stress annualized-return non-improvement', ((SELECT count(*)::text FROM _m1_14_vs WHERE scenario_code='RECESSION_ENERGY' AND annualized_risk_adjusted_return_rate>baseline_annualized_risk_adjusted_return_rate))::text, ('0')::text, ((SELECT count(*)=0 FROM _m1_14_vs WHERE scenario_code='RECESSION_ENERGY' AND annualized_risk_adjusted_return_rate>baseline_annualized_risk_adjusted_return_rate)), 'Adverse scenario final annualized return cannot improve.');
    PERFORM pg_temp.m1_14_add_check('M1_14_POS_55_HURDLE_REQUIREMENT_IDENTITY', 'Hurdle-required contribution identity', ((SELECT count(*)::text FROM _m1_14_vs WHERE hurdle_required_contribution_amount IS DISTINCT FROM round(requested_funding_amount*hurdle_annual_return_rate*requested_expected_payoff_days/365,2)::numeric(18,2)))::text, ('0')::text, ((SELECT count(*)=0 FROM _m1_14_vs WHERE hurdle_required_contribution_amount IS DISTINCT FROM round(requested_funding_amount*hurdle_annual_return_rate*requested_expected_payoff_days/365,2)::numeric(18,2))), 'Hurdle requirement reconciles to funded amount, annual hurdle, and term.');
    PERFORM pg_temp.m1_14_add_check('M1_14_POS_56_ECONOMIC_SURPLUS_IDENTITY', 'Economic-surplus identity', ((SELECT count(*)::text FROM _m1_14_vs WHERE unit_economics_evidence_status<>'BLOCKED' AND economic_surplus_amount IS DISTINCT FROM round(risk_adjusted_contribution_amount-hurdle_required_contribution_amount,2)::numeric(18,2)))::text, ('0')::text, ((SELECT count(*)=0 FROM _m1_14_vs WHERE unit_economics_evidence_status<>'BLOCKED' AND economic_surplus_amount IS DISTINCT FROM round(risk_adjusted_contribution_amount-hurdle_required_contribution_amount,2)::numeric(18,2))), 'Economic surplus reconciles to final contribution less hurdle requirement.');
    PERFORM pg_temp.m1_14_add_check(
        'M1_14_POS_57_BLOCKED_EVIDENCE_GATING',
        'Blocked current-scenario economics null behavior',
        ((SELECT count(*)::text
          FROM _m1_14_vs
          WHERE unit_economics_evidence_status='BLOCKED'
            AND (
                comparative_expected_loss_amount IS NOT NULL
                OR contribution_after_comparative_loss_amount IS NOT NULL
                OR independent_risk_adjusted_contribution_amount IS NOT NULL
                OR risk_adjusted_contribution_amount IS NOT NULL
                OR contribution_after_loss_margin_rate IS NOT NULL
                OR independent_risk_adjusted_contribution_margin_rate IS NOT NULL
                OR risk_adjusted_contribution_margin_rate IS NOT NULL
                OR independent_annualized_risk_adjusted_return_rate IS NOT NULL
                OR annualized_risk_adjusted_return_rate IS NOT NULL
                OR economic_surplus_amount IS NOT NULL
            )))::text,
        '0',
        ((SELECT count(*)=0
          FROM _m1_14_vs
          WHERE unit_economics_evidence_status='BLOCKED'
            AND (
                comparative_expected_loss_amount IS NOT NULL
                OR contribution_after_comparative_loss_amount IS NOT NULL
                OR independent_risk_adjusted_contribution_amount IS NOT NULL
                OR risk_adjusted_contribution_amount IS NOT NULL
                OR contribution_after_loss_margin_rate IS NOT NULL
                OR independent_risk_adjusted_contribution_margin_rate IS NOT NULL
                OR risk_adjusted_contribution_margin_rate IS NOT NULL
                OR independent_annualized_risk_adjusted_return_rate IS NOT NULL
                OR annualized_risk_adjusted_return_rate IS NOT NULL
                OR economic_surplus_amount IS NOT NULL
            ))),
        'Blocked current-scenario loss-dependent economics remain NULL; matched baseline contribution and return references may remain populated and are validated separately.'
    );
    PERFORM pg_temp.m1_14_add_check('M1_14_POS_58_EVIDENCE_STATUS_MAPPING', 'Unit-economics evidence-status mapping', ((SELECT count(*)::text FROM _m1_14_vs WHERE unit_economics_evidence_status IS DISTINCT FROM CASE WHEN loss_evidence_status='BLOCKED' THEN 'BLOCKED' WHEN loss_evidence_status='PARTIAL' OR channel_cost_evidence_status='DEFAULT_PARAMETER' THEN 'PARTIAL' ELSE 'COMPLETE' END))::text, ('0')::text, ((SELECT count(*)=0 FROM _m1_14_vs WHERE unit_economics_evidence_status IS DISTINCT FROM CASE WHEN loss_evidence_status='BLOCKED' THEN 'BLOCKED' WHEN loss_evidence_status='PARTIAL' OR channel_cost_evidence_status='DEFAULT_PARAMETER' THEN 'PARTIAL' ELSE 'COMPLETE' END)), 'Economics evidence status follows accepted loss and channel-cost evidence.');
    PERFORM pg_temp.m1_14_add_check('M1_14_POS_59_INDEPENDENT_TIER_DOMAIN', 'Independent economic-tier domain', ((SELECT count(*)::text FROM _m1_14_vs WHERE independent_economic_tier NOT BETWEEN 1 AND 5))::text, ('0')::text, ((SELECT count(*)=0 FROM _m1_14_vs WHERE independent_economic_tier NOT BETWEEN 1 AND 5)), 'Independent economic tier remains within the governed domain.');
    PERFORM pg_temp.m1_14_add_check('M1_14_POS_60_BASELINE_TIER_MAPPING', 'Baseline economic-tier mapping', ((SELECT count(*)::text FROM _m1_14_vs e JOIN _m1_14_vbaseline b USING(merchant_application_id) WHERE e.baseline_economic_tier<>b.baseline_economic_tier))::text, ('0')::text, ((SELECT count(*)=0 FROM _m1_14_vs e JOIN _m1_14_vbaseline b USING(merchant_application_id) WHERE e.baseline_economic_tier<>b.baseline_economic_tier)), 'Every matched row preserves its baseline economic tier.');
    PERFORM pg_temp.m1_14_add_check('M1_14_POS_61_STRESS_TIER_NONIMPROVEMENT', 'Stress economic-tier non-improvement', ((SELECT count(*)::text FROM _m1_14_vs WHERE scenario_code='RECESSION_ENERGY' AND economic_tier<baseline_economic_tier))::text, ('0')::text, ((SELECT count(*)=0 FROM _m1_14_vs WHERE scenario_code='RECESSION_ENERGY' AND economic_tier<baseline_economic_tier)), 'Adverse scenario final economic tier cannot improve.');
    PERFORM pg_temp.m1_14_add_check('M1_14_POS_62_HURDLE_PASS_MAPPING', 'Hurdle-pass mapping', ((SELECT count(*)::text FROM _m1_14_vs WHERE hurdle_pass_flag IS DISTINCT FROM CASE
            WHEN unit_economics_evidence_status='BLOCKED'
              OR risk_adjusted_contribution_amount IS NULL THEN false
            ELSE risk_adjusted_contribution_amount>=hurdle_required_contribution_amount
        END))::text, ('0')::text, ((SELECT count(*)=0 FROM _m1_14_vs WHERE hurdle_pass_flag IS DISTINCT FROM CASE
            WHEN unit_economics_evidence_status='BLOCKED'
              OR risk_adjusted_contribution_amount IS NULL THEN false
            ELSE risk_adjusted_contribution_amount>=hurdle_required_contribution_amount
        END)), 'Hurdle-pass flag reconciles to final contribution and evidence status.');
    PERFORM pg_temp.m1_14_add_check('M1_14_POS_63_ECONOMIC_STATUS_MAPPING', 'Economic-status mapping', ((SELECT count(*)::text FROM _m1_14_vs WHERE economic_status IS DISTINCT FROM CASE WHEN unit_economics_evidence_status='BLOCKED' THEN 'INSUFFICIENT_EVIDENCE' WHEN risk_adjusted_contribution_amount<0 THEN 'NEGATIVE_CONTRIBUTION' WHEN risk_adjusted_contribution_amount>=hurdle_required_contribution_amount THEN 'ABOVE_HURDLE' ELSE 'BELOW_HURDLE' END))::text, ('0')::text, ((SELECT count(*)=0 FROM _m1_14_vs WHERE economic_status IS DISTINCT FROM CASE WHEN unit_economics_evidence_status='BLOCKED' THEN 'INSUFFICIENT_EVIDENCE' WHEN risk_adjusted_contribution_amount<0 THEN 'NEGATIVE_CONTRIBUTION' WHEN risk_adjusted_contribution_amount>=hurdle_required_contribution_amount THEN 'ABOVE_HURDLE' ELSE 'BELOW_HURDLE' END)), 'Economic status follows final contribution, hurdle, and evidence state.');
    PERFORM pg_temp.m1_14_add_check('M1_14_POS_64_MANUAL_REVIEW_MAPPING', 'Manual-review recommendation mapping', ((SELECT count(*)::text FROM _m1_14_vs e JOIN msbf_m1.application_exposure_recovery_loss_snapshot l USING(module1_run_id,scenario_id,merchant_application_id) WHERE e.manual_review_recommended_flag IS DISTINCT FROM (l.manual_review_recommended_flag OR e.unit_economics_evidence_status<>'COMPLETE' OR e.risk_adjusted_contribution_amount IS NULL OR e.risk_adjusted_contribution_amount<e.hurdle_required_contribution_amount)))::text, ('0')::text, ((SELECT count(*)=0 FROM _m1_14_vs e JOIN msbf_m1.application_exposure_recovery_loss_snapshot l USING(module1_run_id,scenario_id,merchant_application_id) WHERE e.manual_review_recommended_flag IS DISTINCT FROM (l.manual_review_recommended_flag OR e.unit_economics_evidence_status<>'COMPLETE' OR e.risk_adjusted_contribution_amount IS NULL OR e.risk_adjusted_contribution_amount<e.hurdle_required_contribution_amount))), 'Manual-review routing preserves upstream review and economics conditions.');
    PERFORM pg_temp.m1_14_add_check('M1_14_POS_65_FALLBACK_DOMAIN', 'Fallback-path domain', ((SELECT count(*)::text FROM _m1_14_vs WHERE fallback_path_code NOT IN ('NONE','DEFAULT_CHANNEL_COST','PARAMETER_ONLY_COSTS','INSUFFICIENT_LOSS_EVIDENCE','ECONOMIC_HURDLE_REVIEW','NEGATIVE_CONTRIBUTION_REVIEW','MANUAL_UNIT_ECONOMICS_REVIEW')))::text, ('0')::text, ((SELECT count(*)=0 FROM _m1_14_vs WHERE fallback_path_code NOT IN ('NONE','DEFAULT_CHANNEL_COST','PARAMETER_ONLY_COSTS','INSUFFICIENT_LOSS_EVIDENCE','ECONOMIC_HURDLE_REVIEW','NEGATIVE_CONTRIBUTION_REVIEW','MANUAL_UNIT_ECONOMICS_REVIEW'))), 'Fallback routing remains within the governed domain.');
    PERFORM pg_temp.m1_14_add_check('M1_14_POS_66_PRIMARY_REASON_DOMAIN', 'Primary economic-reason domain', ((SELECT count(*)::text FROM _m1_14_vs WHERE primary_economic_reason_code NOT IN ('INSUFFICIENT_LOSS_EVIDENCE','NEGATIVE_RISK_ADJUSTED_CONTRIBUTION','BELOW_ECONOMIC_HURDLE','DEFAULT_CHANNEL_COST_ASSUMPTION','PARTIAL_COMPARATIVE_LOSS_EVIDENCE','ABOVE_ECONOMIC_HURDLE')))::text, ('0')::text, ((SELECT count(*)=0 FROM _m1_14_vs WHERE primary_economic_reason_code NOT IN ('INSUFFICIENT_LOSS_EVIDENCE','NEGATIVE_RISK_ADJUSTED_CONTRIBUTION','BELOW_ECONOMIC_HURDLE','DEFAULT_CHANNEL_COST_ASSUMPTION','PARTIAL_COMPARATIVE_LOSS_EVIDENCE','ABOVE_ECONOMIC_HURDLE'))), 'Primary economic reasons remain within the governed domain.');
    PERFORM pg_temp.m1_14_add_check('M1_14_POS_67_HARD_STOP_REPRODUCTION', 'Upstream hard-stop reproduction', ((SELECT count(*)::text FROM _m1_14_vs e JOIN msbf_m1.application_exposure_recovery_loss_snapshot l USING(module1_run_id,scenario_id,merchant_application_id) WHERE e.hard_stop_recommended_flag IS DISTINCT FROM l.hard_stop_recommended_flag))::text, ('0')::text, ((SELECT count(*)=0 FROM _m1_14_vs e JOIN msbf_m1.application_exposure_recovery_loss_snapshot l USING(module1_run_id,scenario_id,merchant_application_id) WHERE e.hard_stop_recommended_flag IS DISTINCT FROM l.hard_stop_recommended_flag)), 'M1.14 preserves accepted upstream hard-stop evidence.');
    PERFORM pg_temp.m1_14_add_check('M1_14_POS_68_COMPONENT_CODE_INVENTORY', 'Governed component-code inventory', ((SELECT count(DISTINCT component_code)::text FROM _m1_14_vc))::text, ('14')::text, ((SELECT count(DISTINCT component_code)=14 FROM _m1_14_vc)), 'All fourteen governed economics components are present.');
    PERFORM pg_temp.m1_14_add_check('M1_14_POS_69_COMPONENT_STATUS_MAPPING', 'Component availability mapping', ((SELECT count(*)::text FROM _m1_14_vc WHERE component_status IS DISTINCT FROM CASE WHEN component_amount IS NULL THEN 'UNAVAILABLE' ELSE 'AVAILABLE' END))::text, ('0')::text, ((SELECT count(*)=0 FROM _m1_14_vc WHERE component_status IS DISTINCT FROM CASE WHEN component_amount IS NULL THEN 'UNAVAILABLE' ELSE 'AVAILABLE' END)), 'Long-form component availability follows persisted component amount.');
    PERFORM pg_temp.m1_14_add_check('M1_14_POS_70_COMPONENT_SIGN_MAPPING', 'Component sign mapping', ((SELECT count(*)::text FROM _m1_14_vc WHERE (component_code IN ('GROSS_FINANCE_REVENUE','CONTRIBUTION_BEFORE_COMPARATIVE_LOSS','CONTRIBUTION_AFTER_COMPARATIVE_LOSS','RISK_ADJUSTED_CONTRIBUTION','ECONOMIC_SURPLUS') AND component_sign<>1) OR (component_code NOT IN ('GROSS_FINANCE_REVENUE','CONTRIBUTION_BEFORE_COMPARATIVE_LOSS','CONTRIBUTION_AFTER_COMPARATIVE_LOSS','RISK_ADJUSTED_CONTRIBUTION','ECONOMIC_SURPLUS') AND component_sign<>-1)))::text, ('0')::text, ((SELECT count(*)=0 FROM _m1_14_vc WHERE (component_code IN ('GROSS_FINANCE_REVENUE','CONTRIBUTION_BEFORE_COMPARATIVE_LOSS','CONTRIBUTION_AFTER_COMPARATIVE_LOSS','RISK_ADJUSTED_CONTRIBUTION','ECONOMIC_SURPLUS') AND component_sign<>1) OR (component_code NOT IN ('GROSS_FINANCE_REVENUE','CONTRIBUTION_BEFORE_COMPARATIVE_LOSS','CONTRIBUTION_AFTER_COMPARATIVE_LOSS','RISK_ADJUSTED_CONTRIBUTION','ECONOMIC_SURPLUS') AND component_sign<>-1))), 'Revenue/contribution components are positive and cost/loss/hurdle components are negative.');
    PERFORM pg_temp.m1_14_add_check('M1_14_POS_71_WIDE_LONG_COMPONENT_IDENTITY', 'Wide-versus-long component identity', ((SELECT count(*)::text FROM _m1_14_vs e JOIN _m1_14_vc c USING(module1_run_id,scenario_id,merchant_application_id) WHERE c.component_amount IS DISTINCT FROM CASE c.component_code WHEN 'GROSS_FINANCE_REVENUE' THEN e.gross_finance_revenue_amount WHEN 'PROCESSOR_PAYMENT_COST' THEN e.processor_payment_cost_amount WHEN 'PARTNER_ACQUISITION_COST' THEN e.partner_acquisition_cost_amount WHEN 'FUNDING_COST' THEN e.funding_cost_amount WHEN 'SERVICING_COST' THEN e.servicing_cost_amount WHEN 'OPERATING_COST' THEN e.operating_cost_amount WHEN 'TOTAL_NON_LOSS_COST' THEN e.total_non_loss_cost_amount WHEN 'CONTRIBUTION_BEFORE_COMPARATIVE_LOSS' THEN e.contribution_before_comparative_loss_amount WHEN 'COMPARATIVE_EXPECTED_LOSS_BURDEN' THEN e.comparative_expected_loss_amount WHEN 'CONTRIBUTION_AFTER_COMPARATIVE_LOSS' THEN e.contribution_after_comparative_loss_amount WHEN 'RISK_CAPITAL_CHARGE' THEN e.risk_capital_charge_amount WHEN 'RISK_ADJUSTED_CONTRIBUTION' THEN e.risk_adjusted_contribution_amount WHEN 'HURDLE_REQUIREMENT' THEN e.hurdle_required_contribution_amount WHEN 'ECONOMIC_SURPLUS' THEN e.economic_surplus_amount END))::text, ('0')::text, ((SELECT count(*)=0 FROM _m1_14_vs e JOIN _m1_14_vc c USING(module1_run_id,scenario_id,merchant_application_id) WHERE c.component_amount IS DISTINCT FROM CASE c.component_code WHEN 'GROSS_FINANCE_REVENUE' THEN e.gross_finance_revenue_amount WHEN 'PROCESSOR_PAYMENT_COST' THEN e.processor_payment_cost_amount WHEN 'PARTNER_ACQUISITION_COST' THEN e.partner_acquisition_cost_amount WHEN 'FUNDING_COST' THEN e.funding_cost_amount WHEN 'SERVICING_COST' THEN e.servicing_cost_amount WHEN 'OPERATING_COST' THEN e.operating_cost_amount WHEN 'TOTAL_NON_LOSS_COST' THEN e.total_non_loss_cost_amount WHEN 'CONTRIBUTION_BEFORE_COMPARATIVE_LOSS' THEN e.contribution_before_comparative_loss_amount WHEN 'COMPARATIVE_EXPECTED_LOSS_BURDEN' THEN e.comparative_expected_loss_amount WHEN 'CONTRIBUTION_AFTER_COMPARATIVE_LOSS' THEN e.contribution_after_comparative_loss_amount WHEN 'RISK_CAPITAL_CHARGE' THEN e.risk_capital_charge_amount WHEN 'RISK_ADJUSTED_CONTRIBUTION' THEN e.risk_adjusted_contribution_amount WHEN 'HURDLE_REQUIREMENT' THEN e.hurdle_required_contribution_amount WHEN 'ECONOMIC_SURPLUS' THEN e.economic_surplus_amount END)), 'Every long-form economics amount reconciles to the wide snapshot.');
    PERFORM pg_temp.m1_14_add_check('M1_14_POS_72_COMPONENT_SOURCE_LINEAGE', 'Component source-lineage hashes', ((SELECT count(*)::text FROM _m1_14_vc WHERE source_lineage_hash IS NULL OR length(source_lineage_hash)<>32))::text, ('0')::text, ((SELECT count(*)=0 FROM _m1_14_vc WHERE source_lineage_hash IS NULL OR length(source_lineage_hash)<>32)), 'Every component preserves deterministic source lineage.');
    PERFORM pg_temp.m1_14_add_check('M1_14_POS_73_SNAPSHOT_SET_HASH', 'Snapshot set-hash reconciliation', ((SELECT snapshot_hash FROM _m1_14_vhash))::text, ((SELECT metric_value_text FROM _m1_14_vevidence WHERE evidence_code='M1_14_SNAPSHOT_SET_HASH'))::text, ((SELECT snapshot_hash=(SELECT metric_value_text FROM _m1_14_vevidence WHERE evidence_code='M1_14_SNAPSHOT_SET_HASH') FROM _m1_14_vhash)), 'Persisted snapshot set hash reconciles independently.');
    PERFORM pg_temp.m1_14_add_check('M1_14_POS_74_COMPONENT_SET_HASH', 'Component set-hash reconciliation', ((SELECT component_hash FROM _m1_14_vhash))::text, ((SELECT metric_value_text FROM _m1_14_vevidence WHERE evidence_code='M1_14_COMPONENT_SET_HASH'))::text, ((SELECT component_hash=(SELECT metric_value_text FROM _m1_14_vevidence WHERE evidence_code='M1_14_COMPONENT_SET_HASH') FROM _m1_14_vhash)), 'Persisted component set hash reconciles independently.');
    PERFORM pg_temp.m1_14_add_check('M1_14_POS_75_COMBINED_SET_HASH', 'Combined set-hash reconciliation', ((SELECT combined_hash FROM _m1_14_vhash))::text, ((SELECT metric_value_text FROM _m1_14_vevidence WHERE evidence_code='M1_14_COMBINED_SET_HASH'))::text, ((SELECT combined_hash=(SELECT metric_value_text FROM _m1_14_vevidence WHERE evidence_code='M1_14_COMBINED_SET_HASH') FROM _m1_14_vhash)), 'Complete M1.14 canonical set hash reconciles independently.');
    PERFORM pg_temp.m1_14_add_check('M1_14_POS_76_CANONICAL_ENTITY_COUNT', 'Canonical entity count', ((SELECT canonical_entities::text FROM _m1_14_vhash))::text, ('22500')::text, ((SELECT canonical_entities=22500 FROM _m1_14_vhash)), 'Canonical universe contains 1,500 snapshots plus 21,000 components.');
    PERFORM pg_temp.m1_14_add_check('M1_14_POS_77_GENERATION_MISMATCH_EVIDENCE', 'Generation mismatch evidence', ((SELECT metric_value_numeric::bigint::text FROM _m1_14_vevidence WHERE evidence_code='M1_14_CANONICAL_MISMATCH_COUNT'))::text, ('0')::text, ((SELECT metric_value_numeric=0 FROM _m1_14_vevidence WHERE evidence_code='M1_14_CANONICAL_MISMATCH_COUNT')), 'Generation persisted zero expected-versus-actual mismatches.');
    PERFORM pg_temp.m1_14_add_check('M1_14_POS_78_GENERATION_EVIDENCE_COMPLETENESS', 'Generation evidence completeness', ((SELECT count(*)::text FROM _m1_14_vevidence WHERE evidence_code IN ('M1_14_GENERATION_SPEC','M1_14_SNAPSHOT_SET_HASH','M1_14_COMPONENT_SET_HASH','M1_14_COMBINED_SET_HASH','M1_14_SNAPSHOT_ROW_COUNT','M1_14_COMPONENT_ROW_COUNT','M1_14_CANONICAL_ENTITY_COUNT','M1_14_CANONICAL_MISMATCH_COUNT','M1_14_GENERATION_SUMMARY')))::text, ('9')::text, ((SELECT count(*)=9 FROM _m1_14_vevidence WHERE evidence_code IN ('M1_14_GENERATION_SPEC','M1_14_SNAPSHOT_SET_HASH','M1_14_COMPONENT_SET_HASH','M1_14_COMBINED_SET_HASH','M1_14_SNAPSHOT_ROW_COUNT','M1_14_COMPONENT_ROW_COUNT','M1_14_CANONICAL_ENTITY_COUNT','M1_14_CANONICAL_MISMATCH_COUNT','M1_14_GENERATION_SUMMARY'))), 'Required governed generation evidence is complete.');
    PERFORM pg_temp.m1_14_add_check('M1_14_POS_79_NO_FUTURE_DATA', 'No-future-data control', ((SELECT count(*)::text FROM _m1_14_vs WHERE as_of_date>(SELECT as_of_date FROM _m1_14_vrun)))::text, ('0')::text, ((SELECT count(*)=0 FROM _m1_14_vs WHERE as_of_date>(SELECT as_of_date FROM _m1_14_vrun))), 'No feature row uses evidence after the governed run as-of date.');
    PERFORM pg_temp.m1_14_add_check('M1_14_POS_80_DOWNSTREAM_BOUNDARY', 'Downstream latest/archive boundary', ((SELECT ((SELECT count(*) FROM msbf_m1.module1_latest WHERE module1_run_id=(SELECT run_id FROM _m1_14_vrun))+(SELECT count(*) FROM msbf_m1.module1_archive WHERE module1_run_id=(SELECT run_id FROM _m1_14_vrun)))::text))::text, ('0')::text, ((SELECT (SELECT count(*) FROM msbf_m1.module1_latest WHERE module1_run_id=(SELECT run_id FROM _m1_14_vrun))+(SELECT count(*) FROM msbf_m1.module1_archive WHERE module1_run_id=(SELECT run_id FROM _m1_14_vrun))=0)), 'M1.14 does not create final latest or archive contracts.');
    PERFORM pg_temp.m1_14_add_check('M1_14_POS_81_BLOCKING_ERRORS', 'Blocking configuration errors', ((SELECT count(*)::text FROM msbf_ctl.profile_resolution_error WHERE run_id=(SELECT run_id FROM _m1_14_vrun) AND severity='BLOCKING'))::text, ('0')::text, ((SELECT count(*)=0 FROM msbf_ctl.profile_resolution_error WHERE run_id=(SELECT run_id FROM _m1_14_vrun) AND severity='BLOCKING')), 'No blocking configuration errors remain.');
    PERFORM pg_temp.m1_14_add_check('M1_14_POS_82_STRESS_WORSENING_FLAG', 'Stress-worsening flag consistency', ((SELECT count(*)::text FROM _m1_14_vs WHERE stress_economic_worsening_flag IS DISTINCT FROM CASE
            WHEN scenario_code IS DISTINCT FROM 'RECESSION_ENERGY' THEN false
            WHEN economic_tier>baseline_economic_tier THEN true
            WHEN risk_adjusted_contribution_amount IS NULL
              OR baseline_risk_adjusted_contribution_amount IS NULL THEN false
            ELSE coalesce(
                risk_adjusted_contribution_amount
                    < baseline_risk_adjusted_contribution_amount,
                false
            )
        END))::text, ('0')::text, ((SELECT count(*)=0 FROM _m1_14_vs WHERE stress_economic_worsening_flag IS DISTINCT FROM CASE
            WHEN scenario_code IS DISTINCT FROM 'RECESSION_ENERGY' THEN false
            WHEN economic_tier>baseline_economic_tier THEN true
            WHEN risk_adjusted_contribution_amount IS NULL
              OR baseline_risk_adjusted_contribution_amount IS NULL THEN false
            ELSE coalesce(
                risk_adjusted_contribution_amount
                    < baseline_risk_adjusted_contribution_amount,
                false
            )
        END)), 'Stress-worsening indicator reconciles to final matched economics.');
END;
$checks$;

INSERT INTO msbf_ctl.run_evidence(
    run_id,evidence_code,segment_key,metric_name,metric_value_text,
    unit_code,status,interpretation
)
SELECT (SELECT run_id FROM _m1_14_vrun),evidence_code,'PORTFOLIO',metric_name,
       observed_value,'TEXT',status,
       interpretation||' | threshold='||coalesce(threshold_value,'')
FROM _m1_14_validation
ON CONFLICT(run_id,evidence_code,segment_key) DO UPDATE SET
    metric_name=EXCLUDED.metric_name,metric_value_text=EXCLUDED.metric_value_text,
    metric_value_numeric=NULL,unit_code=EXCLUDED.unit_code,status=EXCLUDED.status,
    interpretation=EXCLUDED.interpretation,created_at=clock_timestamp();

UPDATE msbf_ctl.run_registry
SET run_status=CASE
        WHEN (SELECT count(*) FROM _m1_14_validation)=82
         AND (SELECT count(*) FROM _m1_14_validation WHERE status='PASS')=82
        THEN 'M1_14_VALIDATED' ELSE 'M1_14_FAILED' END,
    notes=coalesce(notes,'')||E'\nM1.14 v0.2R4 positive validation completed using physical-row snapshot hash reconstruction under the approved blocked-evidence contract.'
WHERE run_id=(SELECT run_id FROM _m1_14_vrun);

COMMIT;

SELECT evidence_code,metric_name,observed_value,threshold_value,status,interpretation
FROM _m1_14_validation
ORDER BY evidence_code;
