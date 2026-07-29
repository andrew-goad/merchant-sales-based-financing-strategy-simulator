/* ============================================================================
MSBF M1.14 Unit Economics & Risk-Adjusted Contribution — Generation
Program : 102_msbf_m1_14_unit_economics_generation_v0_2R3.sql
Version : v0.2R3
Purpose : Generate scenario-aware conditional-if-booked revenue, non-loss
          costs, comparative-loss burden, synthetic risk-capital charge,
          risk-adjusted contribution, return, hurdle, and economic-review
          evidence from accepted M1.10 and M1.13 physical outputs.
Inputs  : Accepted M1.3 request terms, M1.10 capacity evidence, M1.13
          exposure/recovery/loss evidence, partner-channel economics, and the
          approved M1.14 policy profile.
Outputs : application_unit_economics_snapshot and
          unit_economics_component_value.
Boundary: Economics foundations only. No acceptance probability, final price,
          offer, approval, CECL, reserve, regulatory capital, or accounting
          income is created.
Performance: Accepted upstream blueprints are not rebuilt. The 1,500-row
             scenario/application input is materialized once, indexed, and
             transformed through bounded stages.
Recovery: After a pre-commit failure, ROLLBACK and run atomic program 100E.
          After a successful commit with lost output, run read-only program 102A v0.2R3.
============================================================================ */

BEGIN;
SET LOCAL work_mem = '64MB';
SET LOCAL jit = off;
SET LOCAL lock_timeout = '10s';
SET LOCAL statement_timeout = '15min';


/* ---------------------------------------------------------------------------
0. Atomic blocked-contract self-heal
   Program 100E is the normal preparation step. This duplicate fail-safe makes
   generation idempotently repair the recognized legacy contract when the
   database is otherwise still at the pristine M1.13 boundary. Unknown schema
   states fail closed.
--------------------------------------------------------------------------- */
LOCK TABLE msbf_m1.application_unit_economics_snapshot
    IN ACCESS EXCLUSIVE MODE;

DO $ensure_blocked_contract$
DECLARE
    v_run_id bigint;
    v_run_status text;
    v_def text;
    v_comment text;
    v_validated boolean;
    v_all_current boolean;
    v_baseline_absent boolean;
    v_baseline_present boolean;
    v_contract_state text;
    v_targets bigint;
    v_evidence bigint;
    v_gate bigint;
BEGIN
    SELECT run_id,run_status
    INTO STRICT v_run_id,v_run_status
    FROM msbf_ctl.run_registry
    WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1;

    SELECT
        (SELECT count(*) FROM msbf_m1.application_unit_economics_snapshot WHERE module1_run_id=v_run_id)
      + (SELECT count(*) FROM msbf_m1.unit_economics_component_value WHERE module1_run_id=v_run_id)
    INTO v_targets;

    SELECT count(*) INTO v_evidence
    FROM msbf_ctl.run_evidence
    WHERE run_id=v_run_id AND evidence_code LIKE 'M1_14_%';

    SELECT count(*) INTO v_gate
    FROM msbf_ctl.acceptance_gate_result
    WHERE run_id=v_run_id AND gate_id='M1_14_UNIT_ECONOMICS_CONTRIBUTION';

    SELECT pg_get_constraintdef(c.oid),c.convalidated,obj_description(c.oid,'pg_constraint')
    INTO STRICT v_def,v_validated,v_comment
    FROM pg_constraint c
    JOIN pg_class t ON t.oid=c.conrelid
    JOIN pg_namespace n ON n.oid=t.relnamespace
    WHERE n.nspname='msbf_m1'
      AND t.relname='application_unit_economics_snapshot'
      AND c.conname='ck_m1_14_blocked';

    v_all_current :=
       position('(comparative_expected_loss_amount is null)' in lower(v_def))>0
       AND position('(contribution_after_comparative_loss_amount is null)' in lower(v_def))>0
       AND position('(independent_risk_adjusted_contribution_amount is null)' in lower(v_def))>0
       AND position('(risk_adjusted_contribution_amount is null)' in lower(v_def))>0
       AND position('(contribution_after_loss_margin_rate is null)' in lower(v_def))>0
       AND position('(independent_risk_adjusted_contribution_margin_rate is null)' in lower(v_def))>0
       AND position('(risk_adjusted_contribution_margin_rate is null)' in lower(v_def))>0
       AND position('(independent_annualized_risk_adjusted_return_rate is null)' in lower(v_def))>0
       AND position('(annualized_risk_adjusted_return_rate is null)' in lower(v_def))>0
       AND position('(economic_surplus_amount is null)' in lower(v_def))>0;
    v_baseline_absent :=
       position('(baseline_risk_adjusted_contribution_amount is null)' in lower(v_def))=0
       AND position('(baseline_annualized_risk_adjusted_return_rate is null)' in lower(v_def))=0;
    v_baseline_present :=
       position('(baseline_risk_adjusted_contribution_amount is null)' in lower(v_def))>0
       AND position('(baseline_annualized_risk_adjusted_return_rate is null)' in lower(v_def))>0;

    v_contract_state := CASE
        WHEN v_validated AND v_all_current AND v_baseline_absent THEN 'APPROVED_V2'
        WHEN v_validated AND v_all_current AND v_baseline_present THEN 'LEGACY_V1'
        ELSE 'UNKNOWN'
    END;

    IF v_contract_state='LEGACY_V1' THEN
        IF v_run_status<>'M1_13_ACCEPTED' OR v_targets<>0 OR v_evidence<>0 OR v_gate<>0 THEN
            RAISE EXCEPTION
                'M1.14 legacy blocked contract cannot be repaired in the current state: run %, targets %, evidence %, gate %.',
                v_run_status,v_targets,v_evidence,v_gate;
        END IF;

        EXECUTE 'ALTER TABLE msbf_m1.application_unit_economics_snapshot DROP CONSTRAINT ck_m1_14_blocked';
        EXECUTE $ddl$
            ALTER TABLE msbf_m1.application_unit_economics_snapshot
            ADD CONSTRAINT ck_m1_14_blocked CHECK (
        unit_economics_evidence_status <> 'BLOCKED'
        OR (
            comparative_expected_loss_amount IS NULL
            AND contribution_after_comparative_loss_amount IS NULL
            AND independent_risk_adjusted_contribution_amount IS NULL
            AND risk_adjusted_contribution_amount IS NULL
            AND contribution_after_loss_margin_rate IS NULL
            AND independent_risk_adjusted_contribution_margin_rate IS NULL
            AND risk_adjusted_contribution_margin_rate IS NULL
            AND independent_annualized_risk_adjusted_return_rate IS NULL
            AND annualized_risk_adjusted_return_rate IS NULL
            AND economic_surplus_amount IS NULL
        )
    ) NOT VALID
        $ddl$;
        EXECUTE 'ALTER TABLE msbf_m1.application_unit_economics_snapshot VALIDATE CONSTRAINT ck_m1_14_blocked';
        RAISE NOTICE 'M1.14 generation self-healed the recognized legacy blocked-evidence constraint.';
    ELSIF v_contract_state<>'APPROVED_V2' THEN
        RAISE EXCEPTION 'M1.14 blocked-evidence constraint is unrecognized and cannot be repaired automatically: %.',v_def;
    END IF;

    EXECUTE format(
        'COMMENT ON CONSTRAINT ck_m1_14_blocked ON msbf_m1.application_unit_economics_snapshot IS %L',
        'MSBF_M1_14_BLOCKED_CONTRACT_V2 | Blocked current-scenario loss-dependent economics remain NULL. Matched-baseline contribution and return references may remain populated for comparison, lineage, and adverse-scenario non-improvement controls.'
    );
END;
$ensure_blocked_contract$;

/* ---------------------------------------------------------------------------
1. Durable hash helpers and fail-closed guards
--------------------------------------------------------------------------- */
CREATE OR REPLACE FUNCTION msbf_m1.m1_14_hash_jsonb(p_value jsonb)
RETURNS text
LANGUAGE sql
IMMUTABLE
STRICT
AS $$
    SELECT md5(p_value::text);
$$;

CREATE OR REPLACE FUNCTION msbf_m1.m1_14_actual_snapshot(p_run_id bigint)
RETURNS TABLE(entity_key text, row_hash text)
LANGUAGE sql
STABLE
AS $$
    SELECT
        'ECON|' || e.scenario_id || '|' || e.merchant_application_id,
        msbf_m1.m1_14_hash_jsonb(to_jsonb(e) - 'row_hash' - 'created_at')
    FROM msbf_m1.application_unit_economics_snapshot e
    WHERE e.module1_run_id = p_run_id;
$$;

CREATE OR REPLACE FUNCTION msbf_m1.m1_14_actual_component_snapshot(p_run_id bigint)
RETURNS TABLE(entity_key text, row_hash text)
LANGUAGE sql
STABLE
AS $$
    SELECT
        'COMP|' || c.scenario_id || '|' || c.merchant_application_id || '|' || c.component_code,
        msbf_m1.m1_14_hash_jsonb(to_jsonb(c) - 'calculation_hash' - 'created_at')
    FROM msbf_m1.unit_economics_component_value c
    WHERE c.module1_run_id = p_run_id;
$$;

CREATE OR REPLACE FUNCTION msbf_m1.m1_14_assert_configuration(p_run_id bigint)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    v_status text;
    v jsonb;
    v_scenarios integer;
    v_baseline integer;
    v_stress integer;
BEGIN
    SELECT status, profile_payload
    INTO STRICT v_status, v
    FROM msbf_ctl.policy_profile
    WHERE profile_code='M1_14_UNIT_ECONOMICS_CONTRIBUTION'
      AND profile_version=1;

    IF v_status <> 'APPROVED' THEN
        RAISE EXCEPTION 'M1.14 requires an APPROVED policy; observed %.', v_status;
    END IF;
    IF NOT coalesce((v->>'generation_enabled')::boolean,false) THEN
        RAISE EXCEPTION 'M1.14 generation is disabled.';
    END IF;
    IF v->>'methodology_version' <> 'M1_14_METHOD_V1'
       OR v->>'contribution_basis_code' <> 'CONDITIONAL_IF_BOOKED'
       OR v->>'comparative_loss_basis_code' <> 'M1_13_SCHEDULE_ADJUSTED_COMPARATIVE_LOSS'
       OR v->>'funding_cost_basis_code' <> 'PATH_WEIGHTED_EAD_X_ANNUAL_RATE_X_TERM'
       OR v->>'risk_capital_charge_basis_code' <> 'PATH_WEIGHTED_EAD_X_CAPITAL_X_COST_OF_CAPITAL_X_TERM'
       OR v->>'hurdle_basis_code' <> 'FUNDED_AMOUNT_X_ANNUAL_HURDLE_X_TERM' THEN
        RAISE EXCEPTION 'M1.14 governed methodology basis is invalid.';
    END IF;
    IF NOT coalesce((v->>'stress_contribution_cap_to_baseline')::boolean,false)
       OR NOT coalesce((v->>'stress_return_cap_to_baseline')::boolean,false)
       OR NOT coalesce((v->>'stress_economic_tier_floor_to_baseline')::boolean,false) THEN
        RAISE EXCEPTION 'M1.14 requires all adverse-scenario non-improvement controls.';
    END IF;
    IF (v->>'processor_payment_cost_rate')::numeric NOT BETWEEN 0 AND 1
       OR (v->>'default_partner_acquisition_cost_rate')::numeric NOT BETWEEN 0 AND 1
       OR (v->>'partner_acquisition_cost_rate_cap')::numeric NOT BETWEEN 0 AND 1
       OR (v->>'default_partner_acquisition_cost_rate')::numeric > (v->>'partner_acquisition_cost_rate_cap')::numeric
       OR (v->>'funding_cost_annual_rate')::numeric NOT BETWEEN 0 AND 1
       OR (v->>'servicing_variable_cost_rate')::numeric NOT BETWEEN 0 AND 1
       OR (v->>'operating_cost_variable_rate')::numeric NOT BETWEEN 0 AND 1
       OR (v->>'risk_capital_allocation_rate')::numeric NOT BETWEEN 0 AND 1
       OR (v->>'risk_capital_cost_annual_rate')::numeric NOT BETWEEN 0 AND 1
       OR (v->>'hurdle_annual_return_rate')::numeric NOT BETWEEN 0 AND 1
       OR (v->>'servicing_daily_cost_amount')::numeric < 0
       OR (v->>'operating_cost_fixed_amount')::numeric < 0 THEN
        RAISE EXCEPTION 'M1.14 governed economic parameters are outside approved bounds.';
    END IF;
    IF NOT (
        (v->>'economic_tier_1_return_threshold')::numeric
        > (v->>'economic_tier_2_return_threshold')::numeric
        AND (v->>'economic_tier_2_return_threshold')::numeric
        > (v->>'economic_tier_3_return_threshold')::numeric
        AND (v->>'economic_tier_3_return_threshold')::numeric >= 0
    ) THEN
        RAISE EXCEPTION 'M1.14 economic-tier thresholds are not strictly ordered.';
    END IF;
    IF (v->>'annualization_days')::integer <> 365 THEN
        RAISE EXCEPTION 'M1.14 annualization days must equal 365.';
    END IF;

    SELECT
        count(DISTINCT l.scenario_id),
        count(DISTINCT l.scenario_id) FILTER (WHERE sr.scenario_code='BASELINE'),
        count(DISTINCT l.scenario_id) FILTER (WHERE sr.scenario_code='RECESSION_ENERGY')
    INTO v_scenarios, v_baseline, v_stress
    FROM msbf_m1.application_exposure_recovery_loss_snapshot l
    JOIN msbf_ctl.scenario_registry sr ON sr.scenario_id=l.scenario_id
    JOIN msbf_ctl.scenario_set ss ON ss.scenario_set_id=sr.scenario_set_id
    WHERE l.module1_run_id=p_run_id
      AND ss.scenario_set_code='M1_V0_2_BASELINE_AND_STRESS'
      AND ss.scenario_set_version=1
      AND ss.status='APPROVED'
      AND sr.status='APPROVED'
      AND sr.scenario_version=1
      AND sr.scenario_code IN ('BASELINE','RECESSION_ENERGY');

    IF v_scenarios<>2 OR v_baseline<>1 OR v_stress<>1 THEN
        RAISE EXCEPTION 'M1.14 requires one accepted BASELINE and one RECESSION_ENERGY scenario; observed %, %, %.',
            v_scenarios, v_baseline, v_stress;
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION msbf_m1.m1_14_assert_generation_ready(p_run_id bigint)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    v_status text;
    v_loss bigint;
    v_capacity bigint;
    v_apps bigint;
    v_targets bigint;
    v_downstream bigint;
    v_blocking bigint;
    v_blocked_constraint_def text;
    v_blocked_constraint_validated boolean;
    v_blocked_constraint_comment text;
BEGIN
    PERFORM msbf_m1.m1_14_assert_configuration(p_run_id);

    SELECT run_status INTO STRICT v_status
    FROM msbf_ctl.run_registry
    WHERE run_id=p_run_id;
    IF v_status <> 'M1_13_ACCEPTED' THEN
        RAISE EXCEPTION 'M1.14 requires M1_13_ACCEPTED; observed %.', v_status;
    END IF;

    SELECT count(*), count(DISTINCT merchant_application_id)
    INTO v_loss, v_apps
    FROM msbf_m1.application_exposure_recovery_loss_snapshot
    WHERE module1_run_id=p_run_id;

    SELECT count(*) INTO v_capacity
    FROM msbf_m1.application_liquidity_capacity_snapshot
    WHERE module1_run_id=p_run_id;

    SELECT
        (SELECT count(*) FROM msbf_m1.application_unit_economics_snapshot WHERE module1_run_id=p_run_id)
      + (SELECT count(*) FROM msbf_m1.unit_economics_component_value WHERE module1_run_id=p_run_id)
    INTO v_targets;

    SELECT
        (SELECT count(*) FROM msbf_m1.module1_latest WHERE module1_run_id=p_run_id)
      + (SELECT count(*) FROM msbf_m1.module1_archive WHERE module1_run_id=p_run_id)
    INTO v_downstream;

    SELECT count(*) INTO v_blocking
    FROM msbf_ctl.profile_resolution_error
    WHERE run_id=p_run_id AND severity='BLOCKING';

    SELECT pg_get_constraintdef(c.oid),c.convalidated,obj_description(c.oid,'pg_constraint')
    INTO STRICT v_blocked_constraint_def,v_blocked_constraint_validated,v_blocked_constraint_comment
    FROM pg_constraint c
    JOIN pg_class t ON t.oid=c.conrelid
    JOIN pg_namespace n ON n.oid=t.relnamespace
    WHERE n.nspname='msbf_m1'
      AND t.relname='application_unit_economics_snapshot'
      AND c.conname='ck_m1_14_blocked';

    IF NOT v_blocked_constraint_validated
       OR coalesce(v_blocked_constraint_comment,'') NOT LIKE 'MSBF_M1_14_BLOCKED_CONTRACT_V2%'
       OR v_blocked_constraint_def ILIKE '%(baseline_risk_adjusted_contribution_amount IS NULL)%'
       OR v_blocked_constraint_def ILIKE '%(baseline_annualized_risk_adjusted_return_rate IS NULL)%'
       OR v_blocked_constraint_def NOT ILIKE '%(comparative_expected_loss_amount IS NULL)%'
       OR v_blocked_constraint_def NOT ILIKE '%(contribution_after_comparative_loss_amount IS NULL)%'
       OR v_blocked_constraint_def NOT ILIKE '%(independent_risk_adjusted_contribution_amount IS NULL)%'
       OR v_blocked_constraint_def NOT ILIKE '%(risk_adjusted_contribution_amount IS NULL)%'
       OR v_blocked_constraint_def NOT ILIKE '%(contribution_after_loss_margin_rate IS NULL)%'
       OR v_blocked_constraint_def NOT ILIKE '%(independent_risk_adjusted_contribution_margin_rate IS NULL)%'
       OR v_blocked_constraint_def NOT ILIKE '%(risk_adjusted_contribution_margin_rate IS NULL)%'
       OR v_blocked_constraint_def NOT ILIKE '%(independent_annualized_risk_adjusted_return_rate IS NULL)%'
       OR v_blocked_constraint_def NOT ILIKE '%(annualized_risk_adjusted_return_rate IS NULL)%'
       OR v_blocked_constraint_def NOT ILIKE '%(economic_surplus_amount IS NULL)%' THEN
        RAISE EXCEPTION
            'M1.14 blocked-evidence constraint is not the approved v0.2R3 contract: validated %, comment %, definition %.',
            v_blocked_constraint_validated,
            coalesce(v_blocked_constraint_comment,''),
            v_blocked_constraint_def;
    END IF;

    IF v_loss<>1500 OR v_capacity<>1500 OR v_apps<>750 THEN
        RAISE EXCEPTION 'M1.14 prerequisite population is invalid: loss %, capacity %, applications %.',
            v_loss, v_capacity, v_apps;
    END IF;
    IF v_targets<>0 THEN
        RAISE EXCEPTION 'M1.14 target population must be empty before generation; observed %.', v_targets;
    END IF;
    IF v_downstream<>0 THEN
        RAISE EXCEPTION 'M1.14 downstream output boundary is violated; observed % rows.', v_downstream;
    END IF;
    IF v_blocking<>0 THEN
        RAISE EXCEPTION 'M1.14 has % blocking configuration errors.', v_blocking;
    END IF;
END;
$$;

/* ---------------------------------------------------------------------------
2. Materialize accepted inputs and governed policy once
--------------------------------------------------------------------------- */
DO $notice$
BEGIN
    RAISE NOTICE 'M1.14 Phase 1/5 — materialize accepted loss, capacity, request and channel inputs';
END;
$notice$;

CREATE TEMP TABLE _m1_14_context ON COMMIT DROP AS
SELECT run_id, population_id, as_of_date
FROM msbf_ctl.run_registry
WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1;

DO $guard$
BEGIN
    PERFORM msbf_m1.m1_14_assert_generation_ready((SELECT run_id FROM _m1_14_context));
END;
$guard$;

CREATE TEMP TABLE _m1_14_policy ON COMMIT DROP AS
SELECT
    profile_payload,
    (profile_payload->>'processor_payment_cost_rate')::numeric AS processor_payment_cost_rate,
    (profile_payload->>'default_partner_acquisition_cost_rate')::numeric AS default_partner_acquisition_cost_rate,
    (profile_payload->>'partner_acquisition_cost_rate_cap')::numeric AS partner_acquisition_cost_rate_cap,
    (profile_payload->>'funding_cost_annual_rate')::numeric AS funding_cost_annual_rate,
    (profile_payload->>'servicing_daily_cost_amount')::numeric AS servicing_daily_cost_amount,
    (profile_payload->>'servicing_variable_cost_rate')::numeric AS servicing_variable_cost_rate,
    (profile_payload->>'operating_cost_fixed_amount')::numeric AS operating_cost_fixed_amount,
    (profile_payload->>'operating_cost_variable_rate')::numeric AS operating_cost_variable_rate,
    (profile_payload->>'risk_capital_allocation_rate')::numeric AS risk_capital_allocation_rate,
    (profile_payload->>'risk_capital_cost_annual_rate')::numeric AS risk_capital_cost_annual_rate,
    (profile_payload->>'hurdle_annual_return_rate')::numeric AS hurdle_annual_return_rate,
    (profile_payload->>'economic_tier_1_return_threshold')::numeric AS tier1_threshold,
    (profile_payload->>'economic_tier_2_return_threshold')::numeric AS tier2_threshold,
    (profile_payload->>'economic_tier_3_return_threshold')::numeric AS tier3_threshold,
    (profile_payload->>'annualization_days')::integer AS annualization_days
FROM msbf_ctl.policy_profile
WHERE profile_code='M1_14_UNIT_ECONOMICS_CONTRIBUTION'
  AND profile_version=1
  AND status='APPROVED';

CREATE TEMP TABLE _m1_14_inputs ON COMMIT DROP AS
SELECT
    l.module1_run_id,
    l.scenario_id,
    sr.scenario_code,
    l.merchant_application_id,
    l.population_id,
    l.merchant_id,
    l.as_of_date,
    l.industry_code,
    r.merchant_size_tier,
    r.relationship_stage,
    a.partner_channel_id,
    coalesce(pc.channel_type,'UNASSIGNED') AS channel_type,
    pc.acquisition_cost_rate,
    l.row_hash AS loss_snapshot_hash,
    c.row_hash AS capacity_snapshot_hash,
    a.request_hash AS application_request_hash,
    l.loss_evidence_status,
    l.integrated_risk_tier,
    l.path_weighted_ead_amount,
    l.schedule_adjusted_comparative_loss_rate,
    l.schedule_adjusted_comparative_expected_loss_amount,
    l.requested_funding_amount,
    l.requested_total_repayment_amount,
    l.requested_finance_charge_amount,
    l.requested_expected_payoff_days,
    l.hard_stop_recommended_flag AS upstream_hard_stop,
    l.manual_review_recommended_flag AS upstream_manual_review
FROM msbf_m1.application_exposure_recovery_loss_snapshot l
JOIN msbf_m1.application_liquidity_capacity_snapshot c
  ON c.module1_run_id=l.module1_run_id
 AND c.scenario_id=l.scenario_id
 AND c.merchant_application_id=l.merchant_application_id
JOIN msbf_m1.application_integrated_risk_proxy_snapshot r
  ON r.module1_run_id=l.module1_run_id
 AND r.scenario_id=l.scenario_id
 AND r.merchant_application_id=l.merchant_application_id
JOIN msbf_m1.merchant_application a
  ON a.merchant_application_id=l.merchant_application_id
LEFT JOIN msbf_m1.partner_channel pc
  ON pc.partner_channel_id=a.partner_channel_id
JOIN msbf_ctl.scenario_registry sr
  ON sr.scenario_id=l.scenario_id
JOIN msbf_ctl.scenario_set ss
  ON ss.scenario_set_id=sr.scenario_set_id
WHERE l.module1_run_id=(SELECT run_id FROM _m1_14_context)
  AND ss.scenario_set_code='M1_V0_2_BASELINE_AND_STRESS'
  AND ss.scenario_set_version=1
  AND ss.status='APPROVED'
  AND sr.status='APPROVED'
  AND sr.scenario_version=1
  AND sr.scenario_code IN ('BASELINE','RECESSION_ENERGY');
CREATE UNIQUE INDEX ON _m1_14_inputs(scenario_id,merchant_application_id);
ANALYZE _m1_14_inputs;

/* ---------------------------------------------------------------------------
3. Calculate bounded cost, contribution, return and hurdle evidence
--------------------------------------------------------------------------- */
DO $notice$
BEGIN
    RAISE NOTICE 'M1.14 Phase 2/5 — calculate conditional revenue, costs and independent economics';
END;
$notice$;

CREATE TEMP TABLE _m1_14_independent ON COMMIT DROP AS
WITH basis AS (
    SELECT
        i.*,
        p.*,
        CASE WHEN i.partner_channel_id IS NULL THEN 'DEFAULT_PARAMETER' ELSE 'SUPPORTED' END
            AS channel_cost_evidence_status,
        CASE
            WHEN i.loss_evidence_status='BLOCKED' THEN 'BLOCKED'
            WHEN i.loss_evidence_status='PARTIAL' OR i.partner_channel_id IS NULL THEN 'PARTIAL'
            ELSE 'COMPLETE'
        END AS unit_economics_evidence_status,
        least(
            coalesce(i.acquisition_cost_rate,p.default_partner_acquisition_cost_rate),
            p.partner_acquisition_cost_rate_cap
        )::numeric(12,8) AS governed_partner_acquisition_cost_rate,
        round(i.requested_total_repayment_amount / i.requested_funding_amount,8)::numeric(12,8)
            AS payback_multiple,
        i.requested_finance_charge_amount::numeric(18,2) AS gross_finance_revenue_amount,
        round(i.requested_finance_charge_amount / i.requested_funding_amount,8)::numeric(12,8)
            AS gross_finance_charge_rate,
        round(
            i.requested_finance_charge_amount / i.requested_funding_amount
            * p.annualization_days / i.requested_expected_payoff_days,
            8
        )::numeric(12,8) AS annualized_gross_yield_rate
    FROM _m1_14_inputs i
    CROSS JOIN _m1_14_policy p
), costs AS (
    SELECT
        b.*,
        round(b.requested_total_repayment_amount*b.processor_payment_cost_rate,2)::numeric(18,2)
            AS processor_payment_cost_amount,
        round(b.requested_funding_amount*b.governed_partner_acquisition_cost_rate,2)::numeric(18,2)
            AS partner_acquisition_cost_amount,
        round(
            b.path_weighted_ead_amount*b.funding_cost_annual_rate
            * b.requested_expected_payoff_days/b.annualization_days,
            2
        )::numeric(18,2) AS funding_cost_amount,
        round(
            b.servicing_daily_cost_amount*b.requested_expected_payoff_days
            + b.requested_total_repayment_amount*b.servicing_variable_cost_rate,
            2
        )::numeric(18,2) AS servicing_cost_amount,
        round(
            b.operating_cost_fixed_amount
            + b.requested_funding_amount*b.operating_cost_variable_rate,
            2
        )::numeric(18,2) AS operating_cost_amount,
        round(
            b.path_weighted_ead_amount*b.risk_capital_allocation_rate
            * b.risk_capital_cost_annual_rate
            * b.requested_expected_payoff_days/b.annualization_days,
            2
        )::numeric(18,2) AS risk_capital_charge_amount,
        round(
            b.requested_funding_amount*b.hurdle_annual_return_rate
            * b.requested_expected_payoff_days/b.annualization_days,
            2
        )::numeric(18,2) AS hurdle_required_contribution_amount
    FROM basis b
), contribution AS (
    SELECT
        c.*,
        round(
            c.processor_payment_cost_amount+c.partner_acquisition_cost_amount
            +c.funding_cost_amount+c.servicing_cost_amount+c.operating_cost_amount,
            2
        )::numeric(18,2) AS total_non_loss_cost_amount,
        round(
            c.gross_finance_revenue_amount
            -(c.processor_payment_cost_amount+c.partner_acquisition_cost_amount
              +c.funding_cost_amount+c.servicing_cost_amount+c.operating_cost_amount),
            2
        )::numeric(18,2) AS contribution_before_comparative_loss_amount
    FROM costs c
), independent AS (
    SELECT
        x.*,
        CASE WHEN x.unit_economics_evidence_status='BLOCKED'
             THEN NULL
             ELSE x.schedule_adjusted_comparative_expected_loss_amount::numeric(18,2)
        END AS comparative_expected_loss_amount,
        CASE WHEN x.unit_economics_evidence_status='BLOCKED'
             THEN NULL
             ELSE round(
                    x.contribution_before_comparative_loss_amount
                    - x.schedule_adjusted_comparative_expected_loss_amount,
                    2
                  )::numeric(18,2)
        END AS contribution_after_comparative_loss_amount
    FROM contribution x
), metrics AS (
    SELECT
        x.*,
        CASE WHEN x.unit_economics_evidence_status='BLOCKED' THEN NULL
             ELSE round(
                    x.contribution_after_comparative_loss_amount
                    - x.risk_capital_charge_amount,
                    2
                  )::numeric(18,2)
        END AS independent_risk_adjusted_contribution_amount,
        round(
            x.contribution_before_comparative_loss_amount/x.requested_funding_amount,
            8
        )::numeric(12,8) AS contribution_before_loss_margin_rate,
        CASE WHEN x.unit_economics_evidence_status='BLOCKED' THEN NULL
             ELSE round(
                    x.contribution_after_comparative_loss_amount/x.requested_funding_amount,
                    8
                  )::numeric(12,8)
        END AS contribution_after_loss_margin_rate
    FROM independent x
), returns AS (
    SELECT
        m.*,
        CASE WHEN m.unit_economics_evidence_status='BLOCKED' THEN NULL
             ELSE round(
                    m.independent_risk_adjusted_contribution_amount/m.requested_funding_amount,
                    8
                  )::numeric(12,8)
        END AS independent_risk_adjusted_contribution_margin_rate,
        CASE WHEN m.unit_economics_evidence_status='BLOCKED' THEN NULL
             ELSE round(
                    m.independent_risk_adjusted_contribution_amount/m.requested_funding_amount
                    * m.annualization_days/m.requested_expected_payoff_days,
                    8
                  )::numeric(12,8)
        END AS independent_annualized_risk_adjusted_return_rate,
        CASE WHEN m.unit_economics_evidence_status='BLOCKED' THEN NULL
             ELSE round(
                    m.independent_risk_adjusted_contribution_amount
                    - m.hurdle_required_contribution_amount,
                    2
                  )::numeric(18,2)
        END AS independent_economic_surplus_amount
    FROM metrics m
)
SELECT
    r.*,
    CASE
        WHEN r.unit_economics_evidence_status='BLOCKED' THEN 5
        WHEN r.independent_risk_adjusted_contribution_amount < 0 THEN 4
        WHEN r.independent_annualized_risk_adjusted_return_rate >= r.tier1_threshold
         AND r.independent_economic_surplus_amount >= 0 THEN 1
        WHEN r.independent_annualized_risk_adjusted_return_rate >= r.tier2_threshold
         AND r.independent_economic_surplus_amount >= 0 THEN 2
        WHEN r.independent_annualized_risk_adjusted_return_rate >= r.tier3_threshold
         AND r.independent_risk_adjusted_contribution_amount >= 0 THEN 3
        ELSE 4
    END::smallint AS independent_economic_tier
FROM returns r;
CREATE UNIQUE INDEX ON _m1_14_independent(scenario_id,merchant_application_id);
ANALYZE _m1_14_independent;

CREATE TEMP TABLE _m1_14_baseline ON COMMIT DROP AS
SELECT
    merchant_application_id,
    independent_risk_adjusted_contribution_amount AS baseline_risk_adjusted_contribution_amount,
    independent_annualized_risk_adjusted_return_rate AS baseline_annualized_risk_adjusted_return_rate,
    independent_economic_tier AS baseline_economic_tier
FROM _m1_14_independent
WHERE scenario_code='BASELINE';
CREATE UNIQUE INDEX ON _m1_14_baseline(merchant_application_id);

CREATE TEMP TABLE _m1_14_final ON COMMIT DROP AS
WITH floored AS (
    SELECT
        i.*,
        b.baseline_risk_adjusted_contribution_amount,
        b.baseline_annualized_risk_adjusted_return_rate,
        b.baseline_economic_tier,
        CASE
            WHEN i.unit_economics_evidence_status='BLOCKED' THEN NULL
            WHEN i.scenario_code='RECESSION_ENERGY'
             AND b.baseline_risk_adjusted_contribution_amount IS NULL THEN NULL
            WHEN i.scenario_code='RECESSION_ENERGY' THEN least(
                i.independent_risk_adjusted_contribution_amount,
                b.baseline_risk_adjusted_contribution_amount
            )
            ELSE i.independent_risk_adjusted_contribution_amount
        END::numeric(18,2) AS risk_adjusted_contribution_amount,
        CASE
            WHEN i.unit_economics_evidence_status='BLOCKED' THEN NULL
            WHEN i.scenario_code='RECESSION_ENERGY'
             AND b.baseline_annualized_risk_adjusted_return_rate IS NULL THEN NULL
            WHEN i.scenario_code='RECESSION_ENERGY' THEN least(
                i.independent_annualized_risk_adjusted_return_rate,
                b.baseline_annualized_risk_adjusted_return_rate
            )
            ELSE i.independent_annualized_risk_adjusted_return_rate
        END::numeric(12,8) AS annualized_risk_adjusted_return_rate
    FROM _m1_14_independent i
    JOIN _m1_14_baseline b USING(merchant_application_id)
), final_metrics AS (
    SELECT
        f.*,
        CASE WHEN f.unit_economics_evidence_status='BLOCKED' THEN NULL
             ELSE round(f.risk_adjusted_contribution_amount/f.requested_funding_amount,8)::numeric(12,8)
        END AS risk_adjusted_contribution_margin_rate,
        CASE WHEN f.unit_economics_evidence_status='BLOCKED' THEN NULL
             ELSE round(f.risk_adjusted_contribution_amount-f.hurdle_required_contribution_amount,2)::numeric(18,2)
        END AS economic_surplus_amount
    FROM floored f
), tiered AS (
    SELECT
        f.*,
        CASE
            WHEN f.unit_economics_evidence_status='BLOCKED' THEN 5
            WHEN f.risk_adjusted_contribution_amount < 0 THEN 4
            WHEN f.annualized_risk_adjusted_return_rate >= f.tier1_threshold
             AND f.economic_surplus_amount >= 0 THEN 1
            WHEN f.annualized_risk_adjusted_return_rate >= f.tier2_threshold
             AND f.economic_surplus_amount >= 0 THEN 2
            WHEN f.annualized_risk_adjusted_return_rate >= f.tier3_threshold
             AND f.risk_adjusted_contribution_amount >= 0 THEN 3
            ELSE 4
        END::smallint AS final_calculated_tier
    FROM final_metrics f
)
SELECT
    t.*,
    CASE WHEN t.scenario_code='RECESSION_ENERGY'
         THEN greatest(t.final_calculated_tier,t.baseline_economic_tier)
         ELSE t.final_calculated_tier
    END::smallint AS economic_tier,
    CASE
        WHEN t.scenario_code IS DISTINCT FROM 'RECESSION_ENERGY' THEN false
        WHEN greatest(t.final_calculated_tier,t.baseline_economic_tier)
             > t.baseline_economic_tier THEN true
        WHEN t.risk_adjusted_contribution_amount IS NULL
          OR t.baseline_risk_adjusted_contribution_amount IS NULL THEN false
        ELSE coalesce(
            t.risk_adjusted_contribution_amount
                < t.baseline_risk_adjusted_contribution_amount,
            false
        )
    END::boolean AS stress_economic_worsening_flag,
    CASE
        WHEN t.unit_economics_evidence_status='BLOCKED'
          OR t.risk_adjusted_contribution_amount IS NULL THEN false
        ELSE t.risk_adjusted_contribution_amount >= t.hurdle_required_contribution_amount
    END AS hurdle_pass_flag,
    CASE
        WHEN t.unit_economics_evidence_status='BLOCKED' THEN 'INSUFFICIENT_EVIDENCE'
        WHEN t.risk_adjusted_contribution_amount < 0 THEN 'NEGATIVE_CONTRIBUTION'
        WHEN t.risk_adjusted_contribution_amount >= t.hurdle_required_contribution_amount THEN 'ABOVE_HURDLE'
        ELSE 'BELOW_HURDLE'
    END AS economic_status,
    t.upstream_hard_stop AS hard_stop_recommended_flag,
    (
        t.upstream_manual_review
        OR t.unit_economics_evidence_status<>'COMPLETE'
        OR t.risk_adjusted_contribution_amount IS NULL
        OR t.risk_adjusted_contribution_amount < t.hurdle_required_contribution_amount
    ) AS manual_review_recommended_flag,
    CASE
        WHEN t.unit_economics_evidence_status='BLOCKED' THEN 'INSUFFICIENT_LOSS_EVIDENCE'
        WHEN t.partner_channel_id IS NULL THEN 'DEFAULT_CHANNEL_COST'
        WHEN t.risk_adjusted_contribution_amount < 0 THEN 'NEGATIVE_CONTRIBUTION_REVIEW'
        WHEN t.risk_adjusted_contribution_amount < t.hurdle_required_contribution_amount THEN 'ECONOMIC_HURDLE_REVIEW'
        WHEN t.upstream_manual_review THEN 'MANUAL_UNIT_ECONOMICS_REVIEW'
        WHEN t.loss_evidence_status='PARTIAL' THEN 'PARAMETER_ONLY_COSTS'
        ELSE 'NONE'
    END AS fallback_path_code,
    CASE
        WHEN t.unit_economics_evidence_status='BLOCKED' THEN 'INSUFFICIENT_LOSS_EVIDENCE'
        WHEN t.risk_adjusted_contribution_amount < 0 THEN 'NEGATIVE_RISK_ADJUSTED_CONTRIBUTION'
        WHEN t.risk_adjusted_contribution_amount < t.hurdle_required_contribution_amount THEN 'BELOW_ECONOMIC_HURDLE'
        WHEN t.partner_channel_id IS NULL THEN 'DEFAULT_CHANNEL_COST_ASSUMPTION'
        WHEN t.loss_evidence_status='PARTIAL' THEN 'PARTIAL_COMPARATIVE_LOSS_EVIDENCE'
        ELSE 'ABOVE_ECONOMIC_HURDLE'
    END AS primary_economic_reason_code,
    array_remove(ARRAY[
        CASE WHEN t.partner_channel_id IS NULL THEN 'DEFAULT_PARTNER_COST_RATE' END,
        CASE WHEN t.loss_evidence_status='PARTIAL' THEN 'PARTIAL_LOSS_EVIDENCE' END,
        CASE WHEN t.upstream_manual_review THEN 'UPSTREAM_MANUAL_REVIEW' END,
        CASE WHEN t.upstream_hard_stop THEN 'UPSTREAM_HARD_STOP' END,
        CASE WHEN t.scenario_code='RECESSION_ENERGY'
                  AND t.risk_adjusted_contribution_amount < t.baseline_risk_adjusted_contribution_amount
             THEN 'STRESS_CONTRIBUTION_WORSENING' END
    ],NULL)::text[] AS secondary_economic_reason_codes
FROM tiered t;
CREATE UNIQUE INDEX ON _m1_14_final(scenario_id,merchant_application_id);
ANALYZE _m1_14_final;

/* ---------------------------------------------------------------------------
4. Build target-typed expected snapshots and component evidence
--------------------------------------------------------------------------- */
DO $notice$
BEGIN
    RAISE NOTICE 'M1.14 Phase 3/5 — build target-typed expected snapshots and long-form components';
END;
$notice$;

CREATE TEMP TABLE _m1_14_snapshot_expected ON COMMIT DROP AS
SELECT * FROM msbf_m1.application_unit_economics_snapshot WITH NO DATA;

INSERT INTO _m1_14_snapshot_expected (
    module1_run_id,scenario_id,merchant_application_id,population_id,merchant_id,
    as_of_date,industry_code,merchant_size_tier,relationship_stage,partner_channel_id,
    channel_type,exposure_recovery_loss_snapshot_hash,liquidity_capacity_snapshot_hash,
    application_request_hash,loss_evidence_status,channel_cost_evidence_status,
    unit_economics_evidence_status,integrated_risk_tier,path_weighted_ead_amount,
    schedule_adjusted_comparative_loss_rate,requested_funding_amount,
    requested_total_repayment_amount,requested_finance_charge_amount,
    requested_expected_payoff_days,payback_multiple,gross_finance_revenue_amount,
    gross_finance_charge_rate,annualized_gross_yield_rate,processor_payment_cost_rate,
    processor_payment_cost_amount,partner_acquisition_cost_rate,
    partner_acquisition_cost_amount,funding_cost_annual_rate,funding_cost_amount,
    servicing_daily_cost_amount,servicing_variable_cost_rate,servicing_cost_amount,
    operating_cost_fixed_amount,operating_cost_variable_rate,operating_cost_amount,
    total_non_loss_cost_amount,contribution_before_comparative_loss_amount,
    comparative_expected_loss_amount,contribution_after_comparative_loss_amount,
    risk_capital_allocation_rate,risk_capital_cost_annual_rate,risk_capital_charge_amount,
    independent_risk_adjusted_contribution_amount,baseline_risk_adjusted_contribution_amount,
    risk_adjusted_contribution_amount,contribution_before_loss_margin_rate,
    contribution_after_loss_margin_rate,independent_risk_adjusted_contribution_margin_rate,
    risk_adjusted_contribution_margin_rate,independent_annualized_risk_adjusted_return_rate,
    baseline_annualized_risk_adjusted_return_rate,annualized_risk_adjusted_return_rate,
    hurdle_annual_return_rate,hurdle_required_contribution_amount,economic_surplus_amount,
    independent_economic_tier,baseline_economic_tier,economic_tier,
    stress_economic_worsening_flag,hurdle_pass_flag,economic_status,
    hard_stop_recommended_flag,manual_review_recommended_flag,fallback_path_code,
    primary_economic_reason_code,secondary_economic_reason_codes,row_hash,
    created_by_run_id
)
SELECT
    module1_run_id,scenario_id,merchant_application_id,population_id,merchant_id,
    as_of_date,industry_code,merchant_size_tier,relationship_stage,partner_channel_id,
    channel_type,loss_snapshot_hash,capacity_snapshot_hash,application_request_hash,
    loss_evidence_status,channel_cost_evidence_status,unit_economics_evidence_status,
    integrated_risk_tier,path_weighted_ead_amount,schedule_adjusted_comparative_loss_rate,
    requested_funding_amount,requested_total_repayment_amount,requested_finance_charge_amount,
    requested_expected_payoff_days,payback_multiple,gross_finance_revenue_amount,
    gross_finance_charge_rate,annualized_gross_yield_rate,processor_payment_cost_rate,
    processor_payment_cost_amount,governed_partner_acquisition_cost_rate,
    partner_acquisition_cost_amount,funding_cost_annual_rate,funding_cost_amount,
    servicing_daily_cost_amount,servicing_variable_cost_rate,servicing_cost_amount,
    operating_cost_fixed_amount,operating_cost_variable_rate,operating_cost_amount,
    total_non_loss_cost_amount,contribution_before_comparative_loss_amount,
    comparative_expected_loss_amount,contribution_after_comparative_loss_amount,
    risk_capital_allocation_rate,risk_capital_cost_annual_rate,risk_capital_charge_amount,
    independent_risk_adjusted_contribution_amount,baseline_risk_adjusted_contribution_amount,
    risk_adjusted_contribution_amount,contribution_before_loss_margin_rate,
    contribution_after_loss_margin_rate,independent_risk_adjusted_contribution_margin_rate,
    risk_adjusted_contribution_margin_rate,independent_annualized_risk_adjusted_return_rate,
    baseline_annualized_risk_adjusted_return_rate,annualized_risk_adjusted_return_rate,
    hurdle_annual_return_rate,hurdle_required_contribution_amount,economic_surplus_amount,
    independent_economic_tier,baseline_economic_tier,economic_tier,
    stress_economic_worsening_flag,hurdle_pass_flag,economic_status,
    hard_stop_recommended_flag,manual_review_recommended_flag,fallback_path_code,
    primary_economic_reason_code,secondary_economic_reason_codes,NULL,
    module1_run_id
FROM _m1_14_final;

UPDATE _m1_14_snapshot_expected
SET created_at=clock_timestamp()
WHERE created_at IS NULL;

UPDATE _m1_14_snapshot_expected e
SET row_hash=msbf_m1.m1_14_hash_jsonb(to_jsonb(e)-'row_hash'-'created_at')
WHERE e.row_hash IS NULL;
CREATE UNIQUE INDEX ON _m1_14_snapshot_expected(scenario_id,merchant_application_id);

/* Fail closed before persistence if a target NOT NULL Boolean is unresolved. */
DO $expected_boolean_guard$
DECLARE
    v_null_stress bigint;
    v_null_hurdle bigint;
    v_null_hard_stop bigint;
    v_null_manual_review bigint;
BEGIN
    SELECT
        count(*) FILTER (WHERE stress_economic_worsening_flag IS NULL),
        count(*) FILTER (WHERE hurdle_pass_flag IS NULL),
        count(*) FILTER (WHERE hard_stop_recommended_flag IS NULL),
        count(*) FILTER (WHERE manual_review_recommended_flag IS NULL)
    INTO
        v_null_stress,
        v_null_hurdle,
        v_null_hard_stop,
        v_null_manual_review
    FROM _m1_14_snapshot_expected;

    IF v_null_stress <> 0
       OR v_null_hurdle <> 0
       OR v_null_hard_stop <> 0
       OR v_null_manual_review <> 0 THEN
        RAISE EXCEPTION
            'M1.14 expected Boolean guard failed: stress %, hurdle %, hard-stop %, manual-review %.',
            v_null_stress,
            v_null_hurdle,
            v_null_hard_stop,
            v_null_manual_review;
    END IF;
END;
$expected_boolean_guard$;

/* Fail closed against the revised blocked-evidence physical contract.
   Baseline comparison references are intentionally allowed to remain populated. */
DO $expected_blocked_contract_guard$
DECLARE
    v_current_metric_violations bigint;
    v_blocked_baseline_reference_rows bigint;
BEGIN
    SELECT
        count(*) FILTER (
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
              )
        ),
        count(*) FILTER (
            WHERE unit_economics_evidence_status='BLOCKED'
              AND (
                  baseline_risk_adjusted_contribution_amount IS NOT NULL
                  OR baseline_annualized_risk_adjusted_return_rate IS NOT NULL
              )
        )
    INTO v_current_metric_violations,v_blocked_baseline_reference_rows
    FROM _m1_14_snapshot_expected;

    IF v_current_metric_violations<>0 THEN
        RAISE EXCEPTION
            'M1.14 blocked-evidence contract guard failed: % current-scenario metric violations; % blocked rows retain governed baseline references.',
            v_current_metric_violations,v_blocked_baseline_reference_rows;
    END IF;

    RAISE NOTICE
        'M1.14 blocked-evidence contract verified: 0 current-scenario metric violations; % blocked rows retain governed baseline comparison references.',
        v_blocked_baseline_reference_rows;
END;
$expected_blocked_contract_guard$;

CREATE TEMP TABLE _m1_14_component_expected ON COMMIT DROP AS
SELECT * FROM msbf_m1.unit_economics_component_value WITH NO DATA;

INSERT INTO _m1_14_component_expected (
    module1_run_id,scenario_id,merchant_application_id,component_code,
    component_version,component_amount,component_rate,component_sign,
    component_status,component_reason_code,source_lineage_hash,
    calculation_hash,created_by_run_id
)
SELECT
    e.module1_run_id,e.scenario_id,e.merchant_application_id,v.component_code,1,
    v.component_amount,v.component_rate,v.component_sign,
    CASE WHEN v.component_amount IS NULL THEN 'UNAVAILABLE' ELSE 'AVAILABLE' END,
    CASE WHEN v.component_amount IS NULL THEN 'INSUFFICIENT_EVIDENCE' ELSE 'CALCULATED' END,
    md5(e.exposure_recovery_loss_snapshot_hash||'|'||e.liquidity_capacity_snapshot_hash
        ||'|'||e.application_request_hash||'|'||coalesce(e.partner_channel_id,'DEFAULT')),
    NULL,
    e.module1_run_id
FROM _m1_14_snapshot_expected e
CROSS JOIN LATERAL (
    VALUES
        ('GROSS_FINANCE_REVENUE',e.gross_finance_revenue_amount,e.gross_finance_charge_rate,1::smallint),
        ('PROCESSOR_PAYMENT_COST',e.processor_payment_cost_amount,e.processor_payment_cost_rate,-1::smallint),
        ('PARTNER_ACQUISITION_COST',e.partner_acquisition_cost_amount,e.partner_acquisition_cost_rate,-1::smallint),
        ('FUNDING_COST',e.funding_cost_amount,e.funding_cost_annual_rate,-1::smallint),
        ('SERVICING_COST',e.servicing_cost_amount,e.servicing_variable_cost_rate,-1::smallint),
        ('OPERATING_COST',e.operating_cost_amount,e.operating_cost_variable_rate,-1::smallint),
        ('TOTAL_NON_LOSS_COST',e.total_non_loss_cost_amount,NULL::numeric,-1::smallint),
        ('CONTRIBUTION_BEFORE_COMPARATIVE_LOSS',e.contribution_before_comparative_loss_amount,e.contribution_before_loss_margin_rate,1::smallint),
        ('COMPARATIVE_EXPECTED_LOSS_BURDEN',e.comparative_expected_loss_amount,e.schedule_adjusted_comparative_loss_rate,-1::smallint),
        ('CONTRIBUTION_AFTER_COMPARATIVE_LOSS',e.contribution_after_comparative_loss_amount,e.contribution_after_loss_margin_rate,1::smallint),
        ('RISK_CAPITAL_CHARGE',e.risk_capital_charge_amount,e.risk_capital_cost_annual_rate,-1::smallint),
        ('RISK_ADJUSTED_CONTRIBUTION',e.risk_adjusted_contribution_amount,e.risk_adjusted_contribution_margin_rate,1::smallint),
        ('HURDLE_REQUIREMENT',e.hurdle_required_contribution_amount,e.hurdle_annual_return_rate,-1::smallint),
        ('ECONOMIC_SURPLUS',e.economic_surplus_amount,e.annualized_risk_adjusted_return_rate,1::smallint)
) AS v(component_code,component_amount,component_rate,component_sign);

UPDATE _m1_14_component_expected
SET created_at=clock_timestamp()
WHERE created_at IS NULL;

UPDATE _m1_14_component_expected c
SET calculation_hash=msbf_m1.m1_14_hash_jsonb(to_jsonb(c)-'calculation_hash'-'created_at')
WHERE c.calculation_hash IS NULL;
CREATE UNIQUE INDEX ON _m1_14_component_expected(
    scenario_id,merchant_application_id,component_code
);

/* ---------------------------------------------------------------------------
5. Persist, index, ANALYZE and reconcile once
--------------------------------------------------------------------------- */
DO $notice$
BEGIN
    RAISE NOTICE 'M1.14 Phase 4/5 — persist, index, analyze and reconcile canonical entities';
END;
$notice$;

INSERT INTO msbf_m1.application_unit_economics_snapshot (
    module1_run_id,scenario_id,merchant_application_id,population_id,merchant_id,
    as_of_date,industry_code,merchant_size_tier,relationship_stage,partner_channel_id,
    channel_type,exposure_recovery_loss_snapshot_hash,liquidity_capacity_snapshot_hash,
    application_request_hash,loss_evidence_status,channel_cost_evidence_status,
    unit_economics_evidence_status,integrated_risk_tier,path_weighted_ead_amount,
    schedule_adjusted_comparative_loss_rate,requested_funding_amount,
    requested_total_repayment_amount,requested_finance_charge_amount,
    requested_expected_payoff_days,payback_multiple,gross_finance_revenue_amount,
    gross_finance_charge_rate,annualized_gross_yield_rate,processor_payment_cost_rate,
    processor_payment_cost_amount,partner_acquisition_cost_rate,
    partner_acquisition_cost_amount,funding_cost_annual_rate,funding_cost_amount,
    servicing_daily_cost_amount,servicing_variable_cost_rate,servicing_cost_amount,
    operating_cost_fixed_amount,operating_cost_variable_rate,operating_cost_amount,
    total_non_loss_cost_amount,contribution_before_comparative_loss_amount,
    comparative_expected_loss_amount,contribution_after_comparative_loss_amount,
    risk_capital_allocation_rate,risk_capital_cost_annual_rate,risk_capital_charge_amount,
    independent_risk_adjusted_contribution_amount,baseline_risk_adjusted_contribution_amount,
    risk_adjusted_contribution_amount,contribution_before_loss_margin_rate,
    contribution_after_loss_margin_rate,independent_risk_adjusted_contribution_margin_rate,
    risk_adjusted_contribution_margin_rate,independent_annualized_risk_adjusted_return_rate,
    baseline_annualized_risk_adjusted_return_rate,annualized_risk_adjusted_return_rate,
    hurdle_annual_return_rate,hurdle_required_contribution_amount,economic_surplus_amount,
    independent_economic_tier,baseline_economic_tier,economic_tier,
    stress_economic_worsening_flag,hurdle_pass_flag,economic_status,
    hard_stop_recommended_flag,manual_review_recommended_flag,fallback_path_code,
    primary_economic_reason_code,secondary_economic_reason_codes,row_hash,
    created_by_run_id,created_at
)
SELECT
    module1_run_id,scenario_id,merchant_application_id,population_id,merchant_id,
    as_of_date,industry_code,merchant_size_tier,relationship_stage,partner_channel_id,
    channel_type,exposure_recovery_loss_snapshot_hash,liquidity_capacity_snapshot_hash,
    application_request_hash,loss_evidence_status,channel_cost_evidence_status,
    unit_economics_evidence_status,integrated_risk_tier,path_weighted_ead_amount,
    schedule_adjusted_comparative_loss_rate,requested_funding_amount,
    requested_total_repayment_amount,requested_finance_charge_amount,
    requested_expected_payoff_days,payback_multiple,gross_finance_revenue_amount,
    gross_finance_charge_rate,annualized_gross_yield_rate,processor_payment_cost_rate,
    processor_payment_cost_amount,partner_acquisition_cost_rate,
    partner_acquisition_cost_amount,funding_cost_annual_rate,funding_cost_amount,
    servicing_daily_cost_amount,servicing_variable_cost_rate,servicing_cost_amount,
    operating_cost_fixed_amount,operating_cost_variable_rate,operating_cost_amount,
    total_non_loss_cost_amount,contribution_before_comparative_loss_amount,
    comparative_expected_loss_amount,contribution_after_comparative_loss_amount,
    risk_capital_allocation_rate,risk_capital_cost_annual_rate,risk_capital_charge_amount,
    independent_risk_adjusted_contribution_amount,baseline_risk_adjusted_contribution_amount,
    risk_adjusted_contribution_amount,contribution_before_loss_margin_rate,
    contribution_after_loss_margin_rate,independent_risk_adjusted_contribution_margin_rate,
    risk_adjusted_contribution_margin_rate,independent_annualized_risk_adjusted_return_rate,
    baseline_annualized_risk_adjusted_return_rate,annualized_risk_adjusted_return_rate,
    hurdle_annual_return_rate,hurdle_required_contribution_amount,economic_surplus_amount,
    independent_economic_tier,baseline_economic_tier,economic_tier,
    stress_economic_worsening_flag,hurdle_pass_flag,economic_status,
    hard_stop_recommended_flag,manual_review_recommended_flag,fallback_path_code,
    primary_economic_reason_code,secondary_economic_reason_codes,row_hash,
    created_by_run_id,created_at
FROM _m1_14_snapshot_expected;

INSERT INTO msbf_m1.unit_economics_component_value (
    module1_run_id,scenario_id,merchant_application_id,component_code,
    component_version,component_amount,component_rate,component_sign,
    component_status,component_reason_code,source_lineage_hash,
    calculation_hash,created_by_run_id,created_at
)
SELECT
    module1_run_id,scenario_id,merchant_application_id,component_code,
    component_version,component_amount,component_rate,component_sign,
    component_status,component_reason_code,source_lineage_hash,
    calculation_hash,created_by_run_id,created_at
FROM _m1_14_component_expected;

ANALYZE msbf_m1.application_unit_economics_snapshot;
ANALYZE msbf_m1.unit_economics_component_value;

CREATE TEMP TABLE _m1_14_expected_canonical ON COMMIT DROP AS
SELECT 'ECON|'||scenario_id||'|'||merchant_application_id AS entity_key,row_hash
FROM _m1_14_snapshot_expected
UNION ALL
SELECT 'COMP|'||scenario_id||'|'||merchant_application_id||'|'||component_code,
       calculation_hash
FROM _m1_14_component_expected;
CREATE UNIQUE INDEX ON _m1_14_expected_canonical(entity_key);

CREATE TEMP TABLE _m1_14_actual_canonical ON COMMIT DROP AS
SELECT * FROM msbf_m1.m1_14_actual_snapshot((SELECT run_id FROM _m1_14_context))
UNION ALL
SELECT * FROM msbf_m1.m1_14_actual_component_snapshot((SELECT run_id FROM _m1_14_context));
CREATE UNIQUE INDEX ON _m1_14_actual_canonical(entity_key);

CREATE TEMP TABLE _m1_14_mismatch ON COMMIT DROP AS
SELECT coalesce(e.entity_key,a.entity_key) AS entity_key,
       e.row_hash AS expected_hash,a.row_hash AS actual_hash
FROM _m1_14_expected_canonical e
FULL JOIN _m1_14_actual_canonical a USING(entity_key)
WHERE e.row_hash IS DISTINCT FROM a.row_hash;

CREATE TEMP TABLE _m1_14_hashes ON COMMIT DROP AS
SELECT
    (SELECT count(*) FROM _m1_14_expected_canonical) AS expected_canonical_entities,
    (SELECT count(*) FROM _m1_14_actual_canonical) AS actual_canonical_entities,
    (SELECT count(*) FROM _m1_14_mismatch) AS row_level_mismatches,
    (SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key))
     FROM _m1_14_actual_canonical WHERE entity_key LIKE 'ECON|%') AS snapshot_set_hash,
    (SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key))
     FROM _m1_14_actual_canonical WHERE entity_key LIKE 'COMP|%') AS component_set_hash,
    (SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key))
     FROM _m1_14_actual_canonical) AS combined_set_hash;

DO $reconcile$
DECLARE v_expected bigint; v_actual bigint; v_mismatches bigint;
BEGIN
    SELECT expected_canonical_entities,actual_canonical_entities,row_level_mismatches
    INTO v_expected,v_actual,v_mismatches FROM _m1_14_hashes;
    IF v_expected<>22500 OR v_actual<>22500 OR v_mismatches<>0 THEN
        RAISE EXCEPTION 'M1.14 canonical reconciliation failed: expected %, actual %, mismatches %.',
            v_expected,v_actual,v_mismatches;
    END IF;
END;
$reconcile$;

/* ---------------------------------------------------------------------------
6. Persist governed generation evidence and advance run state
--------------------------------------------------------------------------- */
DO $notice$
BEGIN
    RAISE NOTICE 'M1.14 Phase 5/5 — persist governed evidence and commit generation checkpoint';
END;
$notice$;

INSERT INTO msbf_ctl.run_evidence (
    run_id,evidence_code,segment_key,metric_name,
    metric_value_text,unit_code,status,interpretation
)
SELECT run_id,'M1_14_GENERATION_SPEC','PORTFOLIO','M1.14 generation specification',
       'M1_14_METHOD_V1|CONDITIONAL_IF_BOOKED|M1_13_SCHEDULE_ADJUSTED_COMPARATIVE_LOSS|RISK_CAPITAL_CHARGE|ECONOMIC_HURDLE',
       'TEXT','PASS','Governed M1.14 unit-economics methodology and analytical boundary.'
FROM _m1_14_context
ON CONFLICT (run_id,evidence_code,segment_key) DO UPDATE SET
    metric_name=EXCLUDED.metric_name,metric_value_text=EXCLUDED.metric_value_text,
    metric_value_numeric=NULL,unit_code=EXCLUDED.unit_code,status=EXCLUDED.status,
    interpretation=EXCLUDED.interpretation,created_at=clock_timestamp();

INSERT INTO msbf_ctl.run_evidence (
    run_id,evidence_code,segment_key,metric_name,
    metric_value_text,unit_code,status,interpretation
)
SELECT c.run_id,x.evidence_code,'PORTFOLIO',x.metric_name,x.metric_value_text,
       'HASH','PASS',x.interpretation
FROM _m1_14_context c
CROSS JOIN LATERAL (
    VALUES
        ('M1_14_SNAPSHOT_SET_HASH','M1.14 unit-economics snapshot set hash',
         (SELECT snapshot_set_hash FROM _m1_14_hashes),
         'Deterministic hash over all persisted M1.14 wide snapshots.'),
        ('M1_14_COMPONENT_SET_HASH','M1.14 economics component set hash',
         (SELECT component_set_hash FROM _m1_14_hashes),
         'Deterministic hash over all persisted M1.14 long-form component rows.'),
        ('M1_14_COMBINED_SET_HASH','M1.14 combined set hash',
         (SELECT combined_set_hash FROM _m1_14_hashes),
         'Deterministic hash over the complete M1.14 canonical entity set.')
) x(evidence_code,metric_name,metric_value_text,interpretation)
ON CONFLICT (run_id,evidence_code,segment_key) DO UPDATE SET
    metric_name=EXCLUDED.metric_name,metric_value_text=EXCLUDED.metric_value_text,
    metric_value_numeric=NULL,unit_code=EXCLUDED.unit_code,status=EXCLUDED.status,
    interpretation=EXCLUDED.interpretation,created_at=clock_timestamp();

INSERT INTO msbf_ctl.run_evidence (
    run_id,evidence_code,segment_key,metric_name,
    metric_value_numeric,unit_code,status,interpretation
)
SELECT c.run_id,x.evidence_code,'PORTFOLIO',x.metric_name,x.metric_value_numeric,
       x.unit_code,'PASS',x.interpretation
FROM _m1_14_context c
CROSS JOIN LATERAL (
    VALUES
        ('M1_14_SNAPSHOT_ROW_COUNT','M1.14 snapshot rows',
         (SELECT count(*)::numeric FROM msbf_m1.application_unit_economics_snapshot WHERE module1_run_id=c.run_id),'ROWS',
         'Persisted scenario/application unit-economics snapshot count.'),
        ('M1_14_COMPONENT_ROW_COUNT','M1.14 component rows',
         (SELECT count(*)::numeric FROM msbf_m1.unit_economics_component_value WHERE module1_run_id=c.run_id),'ROWS',
         'Persisted long-form economics component count.'),
        ('M1_14_CANONICAL_ENTITY_COUNT','M1.14 canonical entities',
         (SELECT actual_canonical_entities::numeric FROM _m1_14_hashes),'ROWS',
         'Combined snapshot and component canonical entity count.'),
        ('M1_14_CANONICAL_MISMATCH_COUNT','M1.14 canonical mismatches',
         (SELECT row_level_mismatches::numeric FROM _m1_14_hashes),'ROWS',
         'Expected-versus-physical canonical row mismatches.'),
        ('M1_14_PORTFOLIO_GROSS_REVENUE','M1.14 portfolio gross finance revenue',
         (SELECT coalesce(sum(gross_finance_revenue_amount),0)::numeric FROM msbf_m1.application_unit_economics_snapshot WHERE module1_run_id=c.run_id),'CURRENCY',
         'Synthetic conditional-if-booked gross finance revenue total.'),
        ('M1_14_PORTFOLIO_RISK_ADJUSTED_CONTRIBUTION','M1.14 portfolio risk-adjusted contribution',
         (SELECT coalesce(sum(risk_adjusted_contribution_amount),0)::numeric FROM msbf_m1.application_unit_economics_snapshot WHERE module1_run_id=c.run_id),'CURRENCY',
         'Synthetic risk-adjusted contribution total over available evidence rows.')
) x(evidence_code,metric_name,metric_value_numeric,unit_code,interpretation)
ON CONFLICT (run_id,evidence_code,segment_key) DO UPDATE SET
    metric_name=EXCLUDED.metric_name,metric_value_numeric=EXCLUDED.metric_value_numeric,
    metric_value_text=NULL,unit_code=EXCLUDED.unit_code,status=EXCLUDED.status,
    interpretation=EXCLUDED.interpretation,created_at=clock_timestamp();

INSERT INTO msbf_ctl.run_evidence (
    run_id,evidence_code,segment_key,metric_name,
    metric_value_text,unit_code,status,interpretation
)
SELECT c.run_id,'M1_14_GENERATION_SUMMARY','PORTFOLIO','M1.14 generation summary',
       format('snapshots=%s|components=%s|canonical=%s|mismatches=%s|combined_hash=%s',
              (SELECT count(*) FROM msbf_m1.application_unit_economics_snapshot WHERE module1_run_id=c.run_id),
              (SELECT count(*) FROM msbf_m1.unit_economics_component_value WHERE module1_run_id=c.run_id),
              h.actual_canonical_entities,h.row_level_mismatches,h.combined_set_hash),
       'TEXT',CASE WHEN h.row_level_mismatches=0 THEN 'PASS' ELSE 'FAIL' END,
       'Committed M1.14 generation checkpoint.'
FROM _m1_14_context c CROSS JOIN _m1_14_hashes h
ON CONFLICT (run_id,evidence_code,segment_key) DO UPDATE SET
    metric_name=EXCLUDED.metric_name,metric_value_text=EXCLUDED.metric_value_text,
    metric_value_numeric=NULL,unit_code=EXCLUDED.unit_code,status=EXCLUDED.status,
    interpretation=EXCLUDED.interpretation,created_at=clock_timestamp();

UPDATE msbf_ctl.run_registry r
SET run_status='M1_14_GENERATED',
    notes=coalesce(r.notes,'')||E'\nM1.14 v0.2R3 generation completed under the atomic approved blocked-evidence contract with null-safe matched-stress interpretation and zero canonical mismatches.'
WHERE r.run_id=(SELECT run_id FROM _m1_14_context);

DROP TABLE IF EXISTS _m1_14_generation_result;
CREATE TEMP TABLE _m1_14_generation_result ON COMMIT PRESERVE ROWS AS
SELECT
    r.run_id,r.run_status,
    (SELECT count(*) FROM msbf_m1.application_unit_economics_snapshot WHERE module1_run_id=r.run_id) AS snapshot_rows,
    (SELECT count(*) FROM msbf_m1.unit_economics_component_value WHERE module1_run_id=r.run_id) AS component_rows,
    (SELECT count(DISTINCT merchant_application_id) FROM msbf_m1.application_unit_economics_snapshot WHERE module1_run_id=r.run_id) AS applications,
    (SELECT count(DISTINCT scenario_id) FROM msbf_m1.application_unit_economics_snapshot WHERE module1_run_id=r.run_id) AS scenarios,
    h.expected_canonical_entities,h.actual_canonical_entities,h.row_level_mismatches,
    h.snapshot_set_hash,h.component_set_hash,h.combined_set_hash,
    'APPROVED_V2'::text AS blocked_constraint_contract_state,
    CASE WHEN r.run_status='M1_14_GENERATED'
          AND (SELECT count(*) FROM msbf_m1.application_unit_economics_snapshot WHERE module1_run_id=r.run_id)=1500
          AND (SELECT count(*) FROM msbf_m1.unit_economics_component_value WHERE module1_run_id=r.run_id)=21000
          AND h.expected_canonical_entities=22500
          AND h.actual_canonical_entities=22500
          AND h.row_level_mismatches=0
         THEN 'PASS' ELSE 'FAIL' END AS generation_status
FROM msbf_ctl.run_registry r CROSS JOIN _m1_14_hashes h
WHERE r.run_id=(SELECT run_id FROM _m1_14_context);

COMMIT;

SELECT * FROM _m1_14_generation_result;
