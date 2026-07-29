/* ============================================================================
MSBF M1.14 Unit Economics & Risk-Adjusted Contribution — Fail-Closed Preflight
Program : 101_msbf_m1_14_preflight_validation_v0_2R3.sql
Version : v0.2R3
Purpose : Prove the accepted M1.13 boundary, approved M1.14 policy, matched
          scenario population, corrected blocked-evidence schema contract,
          empty targets, accepted hashes, and downstream boundaries are ready.
Mode    : Read-only with a session-preserved result table. A failed preflight
          raises an exception after constructing the diagnostic result, so the
          execution cannot be mistaken for readiness.
Required: preflight_status = PASS.
============================================================================ */

BEGIN;

DROP TABLE IF EXISTS _m1_14_preflight_result;
CREATE TEMP TABLE _m1_14_preflight_result
ON COMMIT PRESERVE ROWS
AS
WITH run_context AS (
    SELECT
        run_id, run_status, population_id, as_of_date,
        parameter_snapshot_hash, profile_snapshot_hash, source_snapshot_hash
    FROM msbf_ctl.run_registry
    WHERE run_code = 'M1_V0_2_BASELINE_BUILD'
      AND run_version = 1
),
passed_gates AS (
    SELECT count(*) AS passed_gate_count
    FROM (
        SELECT DISTINCT ON (gate_id) gate_id, result_status
        FROM msbf_ctl.acceptance_gate_result
        WHERE run_id = (SELECT run_id FROM run_context)
          AND gate_id IN (
              'G1_CONTROL_PLANE',
              'M1_2_POPULATION',
              'M1_3_APPLICATION_REQUEST',
              'M1_4_DAILY_POS_HISTORY',
              'M1_5_DAILY_DEPOSIT_LIQUIDITY',
              'M1_6_MATCHED_SCENARIO_OVERLAYS',
              'M1_7_SOURCE_QUALITY_CONFIDENCE',
              'M1_8_VERIFICATION_FRAUD_CONTINUITY',
              'M1_9_ASOF_CASHFLOW_FEATURES',
              'M1_10_OBLIGATIONS_LIQUIDITY_CAPACITY',
              'M1_11_CASHFLOW_ARCHETYPE_RESILIENCE',
              'M1_12_INTEGRATED_RISK_PROXY',
              'M1_13_EXPOSURE_RECOVERY_LOSS_FOUNDATIONS'
          )
        ORDER BY gate_id, review_version DESC
    ) latest
    WHERE result_status = 'PASS'
),
policy AS (
    SELECT
        status,
        profile_payload,
        profile_payload ->> 'methodology_version' AS methodology_version,
        profile_payload ->> 'contribution_basis_code' AS contribution_basis_code,
        profile_payload ->> 'comparative_loss_basis_code' AS comparative_loss_basis_code,
        profile_payload ->> 'funding_cost_basis_code' AS funding_cost_basis_code,
        profile_payload ->> 'risk_capital_charge_basis_code' AS capital_charge_basis_code,
        profile_payload ->> 'hurdle_basis_code' AS hurdle_basis_code,
        (profile_payload ->> 'generation_enabled')::boolean AS generation_enabled,
        (profile_payload ->> 'stress_contribution_cap_to_baseline')::boolean AS contribution_floor,
        (profile_payload ->> 'stress_return_cap_to_baseline')::boolean AS return_floor,
        (profile_payload ->> 'stress_economic_tier_floor_to_baseline')::boolean AS tier_floor,
        (profile_payload ->> 'processor_payment_cost_rate')::numeric AS processor_cost_rate,
        (profile_payload ->> 'default_partner_acquisition_cost_rate')::numeric AS default_partner_cost_rate,
        (profile_payload ->> 'partner_acquisition_cost_rate_cap')::numeric AS partner_cost_cap,
        (profile_payload ->> 'funding_cost_annual_rate')::numeric AS funding_cost_rate,
        (profile_payload ->> 'servicing_daily_cost_amount')::numeric AS servicing_daily_cost,
        (profile_payload ->> 'servicing_variable_cost_rate')::numeric AS servicing_variable_rate,
        (profile_payload ->> 'operating_cost_fixed_amount')::numeric AS operating_fixed_cost,
        (profile_payload ->> 'operating_cost_variable_rate')::numeric AS operating_variable_rate,
        (profile_payload ->> 'risk_capital_allocation_rate')::numeric AS capital_allocation_rate,
        (profile_payload ->> 'risk_capital_cost_annual_rate')::numeric AS capital_cost_rate,
        (profile_payload ->> 'hurdle_annual_return_rate')::numeric AS hurdle_rate,
        (profile_payload ->> 'economic_tier_1_return_threshold')::numeric AS tier1_threshold,
        (profile_payload ->> 'economic_tier_2_return_threshold')::numeric AS tier2_threshold,
        (profile_payload ->> 'economic_tier_3_return_threshold')::numeric AS tier3_threshold,
        (profile_payload ->> 'annualization_days')::integer AS annualization_days
    FROM msbf_ctl.policy_profile
    WHERE profile_code = 'M1_14_UNIT_ECONOMICS_CONTRIBUTION'
      AND profile_version = 1
),
scenario_scope AS (
    SELECT
        count(DISTINCT l.scenario_id) AS scenario_count,
        count(DISTINCT l.scenario_id) FILTER (WHERE sr.scenario_code='BASELINE') AS baseline_count,
        count(DISTINCT l.scenario_id) FILTER (WHERE sr.scenario_code='RECESSION_ENERGY') AS stress_count,
        count(*) AS loss_rows,
        count(DISTINCT l.merchant_application_id) AS applications
    FROM msbf_m1.application_exposure_recovery_loss_snapshot l
    JOIN msbf_ctl.scenario_registry sr ON sr.scenario_id=l.scenario_id
    JOIN msbf_ctl.scenario_set ss ON ss.scenario_set_id=sr.scenario_set_id
    WHERE l.module1_run_id=(SELECT run_id FROM run_context)
      AND ss.scenario_set_code='M1_V0_2_BASELINE_AND_STRESS'
      AND ss.scenario_set_version=1
      AND ss.status='APPROVED'
      AND sr.status='APPROVED'
      AND sr.scenario_version=1
      AND sr.scenario_code IN ('BASELINE','RECESSION_ENERGY')
),
input_counts AS (
    SELECT
        (SELECT count(*) FROM msbf_m1.merchant_application
         WHERE created_by_run_id=(SELECT run_id FROM run_context)) AS application_rows,
        (SELECT count(*) FROM msbf_m1.application_exposure_recovery_loss_snapshot
         WHERE module1_run_id=(SELECT run_id FROM run_context)) AS loss_rows,
        (SELECT count(*) FROM msbf_m1.application_liquidity_capacity_snapshot
         WHERE module1_run_id=(SELECT run_id FROM run_context)) AS capacity_rows,
        (SELECT count(*) FROM msbf_m1.partner_channel
         WHERE created_by_run_id=(SELECT run_id FROM run_context)) AS partner_channels,
        (SELECT count(*) FROM msbf_m1.merchant_relationship_snapshot
         WHERE created_by_run_id=(SELECT run_id FROM run_context)) AS relationship_rows
),
target_counts AS (
    SELECT
        (SELECT count(*) FROM msbf_m1.application_unit_economics_snapshot
         WHERE module1_run_id=(SELECT run_id FROM run_context)) AS snapshot_rows,
        (SELECT count(*) FROM msbf_m1.unit_economics_component_value
         WHERE module1_run_id=(SELECT run_id FROM run_context)) AS component_rows,
        (SELECT count(*) FROM msbf_ctl.run_evidence
         WHERE run_id=(SELECT run_id FROM run_context)
           AND evidence_code LIKE 'M1_14_%') AS evidence_rows,
        (SELECT count(*) FROM msbf_ctl.acceptance_gate_result
         WHERE run_id=(SELECT run_id FROM run_context)
           AND gate_id='M1_14_UNIT_ECONOMICS_CONTRIBUTION') AS gate_rows
),
stage_boundary AS (
    SELECT
        (SELECT count(*) FROM msbf_m1.module1_latest
         WHERE module1_run_id=(SELECT run_id FROM run_context)) AS latest_rows,
        (SELECT count(*) FROM msbf_m1.module1_archive
         WHERE module1_run_id=(SELECT run_id FROM run_context)) AS archive_rows,
        (SELECT count(*) FROM msbf_ctl.profile_resolution_error
         WHERE run_id=(SELECT run_id FROM run_context)
           AND severity='BLOCKING') AS blocking_errors
),
accepted_hashes AS (
    SELECT
        (SELECT population_hash FROM msbf_m1.population_registry
         WHERE population_id=(SELECT population_id FROM run_context)) AS population_hash,
        (SELECT metric_value_text FROM msbf_ctl.run_evidence
         WHERE run_id=(SELECT run_id FROM run_context)
           AND evidence_code='M1_3_APPLICATION_SET_HASH'
           AND segment_key='PORTFOLIO') AS application_hash,
        (SELECT metric_value_text FROM msbf_ctl.run_evidence
         WHERE run_id=(SELECT run_id FROM run_context)
           AND evidence_code='M1_6_COMBINED_SET_HASH'
           AND segment_key='PORTFOLIO') AS scenario_hash,
        (SELECT metric_value_text FROM msbf_ctl.run_evidence
         WHERE run_id=(SELECT run_id FROM run_context)
           AND evidence_code='M1_10_COMBINED_SET_HASH'
           AND segment_key='PORTFOLIO') AS capacity_hash,
        (SELECT metric_value_text FROM msbf_ctl.run_evidence
         WHERE run_id=(SELECT run_id FROM run_context)
           AND evidence_code='M1_13_COMBINED_SET_HASH'
           AND segment_key='PORTFOLIO') AS loss_hash
),
schema_state AS (
    SELECT
        to_regclass('msbf_m1.application_unit_economics_snapshot') IS NOT NULL AS snapshot_table_exists,
        to_regclass('msbf_m1.unit_economics_component_value') IS NOT NULL AS component_table_exists,
        to_regclass('msbf_m1.v_m1_14_unit_economics_lineage') IS NOT NULL AS lineage_view_exists,
        (SELECT count(*) FROM msbf_m1.feature_definition
         WHERE feature_family_code='UNIT_ECONOMICS_CONTRIBUTION'
           AND feature_version=1 AND active_flag) AS active_feature_definitions
),
constraint_state AS (
    SELECT
        pg_get_constraintdef(c.oid) AS blocked_constraint_definition,
        c.convalidated AS blocked_constraint_validated,
        obj_description(c.oid,'pg_constraint') AS blocked_constraint_comment,
        pg_get_constraintdef(c.oid)
            NOT ILIKE '%(baseline_risk_adjusted_contribution_amount IS NULL)%'
        AND pg_get_constraintdef(c.oid)
            NOT ILIKE '%(baseline_annualized_risk_adjusted_return_rate IS NULL)%'
            AS blocked_constraint_allows_baseline_reference,
        pg_get_constraintdef(c.oid) ILIKE '%(comparative_expected_loss_amount IS NULL)%'
        AND pg_get_constraintdef(c.oid) ILIKE '%(contribution_after_comparative_loss_amount IS NULL)%'
        AND pg_get_constraintdef(c.oid) ILIKE '%(independent_risk_adjusted_contribution_amount IS NULL)%'
        AND pg_get_constraintdef(c.oid) ILIKE '%(risk_adjusted_contribution_amount IS NULL)%'
        AND pg_get_constraintdef(c.oid) ILIKE '%(contribution_after_loss_margin_rate IS NULL)%'
        AND pg_get_constraintdef(c.oid) ILIKE '%(independent_risk_adjusted_contribution_margin_rate IS NULL)%'
        AND pg_get_constraintdef(c.oid) ILIKE '%(risk_adjusted_contribution_margin_rate IS NULL)%'
        AND pg_get_constraintdef(c.oid) ILIKE '%(independent_annualized_risk_adjusted_return_rate IS NULL)%'
        AND pg_get_constraintdef(c.oid) ILIKE '%(annualized_risk_adjusted_return_rate IS NULL)%'
        AND pg_get_constraintdef(c.oid) ILIKE '%(economic_surplus_amount IS NULL)%'
            AS blocked_constraint_gates_current_metrics,
        CASE
            WHEN c.convalidated
             AND pg_get_constraintdef(c.oid)
                    NOT ILIKE '%(baseline_risk_adjusted_contribution_amount IS NULL)%'
             AND pg_get_constraintdef(c.oid)
                    NOT ILIKE '%(baseline_annualized_risk_adjusted_return_rate IS NULL)%'
             AND pg_get_constraintdef(c.oid) ILIKE '%(comparative_expected_loss_amount IS NULL)%'
             AND pg_get_constraintdef(c.oid) ILIKE '%(contribution_after_comparative_loss_amount IS NULL)%'
             AND pg_get_constraintdef(c.oid) ILIKE '%(independent_risk_adjusted_contribution_amount IS NULL)%'
             AND pg_get_constraintdef(c.oid) ILIKE '%(risk_adjusted_contribution_amount IS NULL)%'
             AND pg_get_constraintdef(c.oid) ILIKE '%(contribution_after_loss_margin_rate IS NULL)%'
             AND pg_get_constraintdef(c.oid) ILIKE '%(independent_risk_adjusted_contribution_margin_rate IS NULL)%'
             AND pg_get_constraintdef(c.oid) ILIKE '%(risk_adjusted_contribution_margin_rate IS NULL)%'
             AND pg_get_constraintdef(c.oid) ILIKE '%(independent_annualized_risk_adjusted_return_rate IS NULL)%'
             AND pg_get_constraintdef(c.oid) ILIKE '%(annualized_risk_adjusted_return_rate IS NULL)%'
             AND pg_get_constraintdef(c.oid) ILIKE '%(economic_surplus_amount IS NULL)%'
            THEN 'APPROVED_V2'
            ELSE 'NOT_APPROVED_V2'
        END AS blocked_constraint_contract_state
    FROM pg_constraint c
    JOIN pg_class t ON t.oid=c.conrelid
    JOIN pg_namespace n ON n.oid=t.relnamespace
    WHERE n.nspname='msbf_m1'
      AND t.relname='application_unit_economics_snapshot'
      AND c.conname='ck_m1_14_blocked'
)
SELECT
    r.run_id,
    r.run_status,
    g.passed_gate_count,
    p.status AS policy_status,
    p.methodology_version,
    p.contribution_basis_code,
    p.comparative_loss_basis_code,
    p.funding_cost_basis_code,
    p.capital_charge_basis_code,
    p.hurdle_basis_code,
    p.generation_enabled,
    p.contribution_floor,
    p.return_floor,
    p.tier_floor,
    p.processor_cost_rate,
    p.default_partner_cost_rate,
    p.partner_cost_cap,
    p.funding_cost_rate,
    p.servicing_daily_cost,
    p.servicing_variable_rate,
    p.operating_fixed_cost,
    p.operating_variable_rate,
    p.capital_allocation_rate,
    p.capital_cost_rate,
    p.hurdle_rate,
    p.tier1_threshold,
    p.tier2_threshold,
    p.tier3_threshold,
    p.annualization_days,
    s.scenario_count,
    s.baseline_count,
    s.stress_count,
    i.application_rows,
    i.loss_rows,
    i.capacity_rows,
    i.partner_channels,
    i.relationship_rows,
    t.snapshot_rows,
    t.component_rows,
    t.evidence_rows,
    t.gate_rows,
    b.latest_rows,
    b.archive_rows,
    b.blocking_errors,
    h.population_hash,
    h.application_hash,
    h.scenario_hash,
    h.capacity_hash,
    h.loss_hash,
    sc.snapshot_table_exists,
    sc.component_table_exists,
    sc.lineage_view_exists,
    sc.active_feature_definitions,
    cs.blocked_constraint_definition,
    cs.blocked_constraint_validated,
    cs.blocked_constraint_allows_baseline_reference,
    cs.blocked_constraint_gates_current_metrics,
    cs.blocked_constraint_comment,
    cs.blocked_constraint_contract_state,
    CASE
        WHEN r.run_status='M1_13_ACCEPTED'
         AND g.passed_gate_count=13
         AND p.status='APPROVED'
         AND p.generation_enabled
         AND p.methodology_version='M1_14_METHOD_V1'
         AND p.contribution_basis_code='CONDITIONAL_IF_BOOKED'
         AND p.comparative_loss_basis_code='M1_13_SCHEDULE_ADJUSTED_COMPARATIVE_LOSS'
         AND p.funding_cost_basis_code='PATH_WEIGHTED_EAD_X_ANNUAL_RATE_X_TERM'
         AND p.capital_charge_basis_code='PATH_WEIGHTED_EAD_X_CAPITAL_X_COST_OF_CAPITAL_X_TERM'
         AND p.hurdle_basis_code='FUNDED_AMOUNT_X_ANNUAL_HURDLE_X_TERM'
         AND p.contribution_floor AND p.return_floor AND p.tier_floor
         AND p.processor_cost_rate BETWEEN 0 AND 1
         AND p.default_partner_cost_rate BETWEEN 0 AND p.partner_cost_cap
         AND p.partner_cost_cap BETWEEN 0 AND 1
         AND p.funding_cost_rate BETWEEN 0 AND 1
         AND p.servicing_daily_cost >= 0
         AND p.servicing_variable_rate BETWEEN 0 AND 1
         AND p.operating_fixed_cost >= 0
         AND p.operating_variable_rate BETWEEN 0 AND 1
         AND p.capital_allocation_rate BETWEEN 0 AND 1
         AND p.capital_cost_rate BETWEEN 0 AND 1
         AND p.hurdle_rate BETWEEN 0 AND 1
         AND p.tier1_threshold > p.tier2_threshold
         AND p.tier2_threshold > p.tier3_threshold
         AND p.tier3_threshold >= 0
         AND p.annualization_days=365
         AND s.scenario_count=2 AND s.baseline_count=1 AND s.stress_count=1
         AND i.application_rows=750 AND i.loss_rows=1500 AND i.capacity_rows=1500
         AND i.partner_channels=5 AND i.relationship_rows=750
         AND t.snapshot_rows=0 AND t.component_rows=0
         AND t.evidence_rows=0 AND t.gate_rows=0
         AND b.latest_rows=0 AND b.archive_rows=0 AND b.blocking_errors=0
         AND h.population_hash IS NOT NULL
         AND h.application_hash IS NOT NULL
         AND h.scenario_hash IS NOT NULL
         AND h.capacity_hash IS NOT NULL
         AND h.loss_hash IS NOT NULL
         AND sc.snapshot_table_exists AND sc.component_table_exists
         AND sc.lineage_view_exists AND sc.active_feature_definitions=14
         AND cs.blocked_constraint_validated
         AND cs.blocked_constraint_allows_baseline_reference
         AND cs.blocked_constraint_gates_current_metrics
         AND cs.blocked_constraint_contract_state='APPROVED_V2'
         AND coalesce(cs.blocked_constraint_comment,'') LIKE 'MSBF_M1_14_BLOCKED_CONTRACT_V2%'
        THEN 'PASS'
        ELSE 'FAIL'
    END AS preflight_status
FROM run_context r
CROSS JOIN passed_gates g
CROSS JOIN policy p
CROSS JOIN scenario_scope s
CROSS JOIN input_counts i
CROSS JOIN target_counts t
CROSS JOIN stage_boundary b
CROSS JOIN accepted_hashes h
CROSS JOIN schema_state sc
CROSS JOIN constraint_state cs;

DO $assert_preflight$
DECLARE
    r record;
BEGIN
    SELECT * INTO STRICT r
    FROM _m1_14_preflight_result;

    IF r.preflight_status<>'PASS' THEN
        RAISE EXCEPTION
            'M1.14 v0.2R3 preflight failed: run %, gates %, contract %, validated %, allows-baseline %, gates-current %, marker %, snapshots %, components %, evidence %, gate %, downstream latest %, downstream archive %, blocking %.',
            r.run_status, r.passed_gate_count, r.blocked_constraint_contract_state,
            r.blocked_constraint_validated,
            r.blocked_constraint_allows_baseline_reference,
            r.blocked_constraint_gates_current_metrics,
            coalesce(r.blocked_constraint_comment,''),
            r.snapshot_rows, r.component_rows, r.evidence_rows, r.gate_rows,
            r.latest_rows, r.archive_rows, r.blocking_errors;
    END IF;
END;
$assert_preflight$;

COMMIT;

SELECT *
FROM _m1_14_preflight_result;
