/* ============================================================================
MSBF M1.14 Unit Economics & Risk-Adjusted Contribution — Acceptance Finalizer
Program : 105_msbf_m1_14_acceptance_finalize_v0_2R4.sql
Version : v0.2R4
Purpose : Reconcile positive and negative controls, physical row counts,
          contribution identities, adverse-scenario floors, canonical hashes,
          policy settings, and stage boundaries before formal acceptance.
Mode    : Writes the formal gate, acceptance summary, and final run status.
Output  : One filterable acceptance row preserved after COMMIT.
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


DROP TABLE IF EXISTS _m1_14_acceptance;
CREATE TEMP TABLE _m1_14_acceptance ON COMMIT PRESERVE ROWS AS
WITH r AS (
    SELECT run_id,run_status,population_id,as_of_date
    FROM msbf_ctl.run_registry
    WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
), pos AS (
    SELECT count(*) AS checks,
           count(*) FILTER (WHERE status='PASS') AS passes,
           count(*) FILTER (WHERE status='FAIL') AS failures
    FROM msbf_ctl.run_evidence
    WHERE run_id=(SELECT run_id FROM r) AND evidence_code LIKE 'M1_14_POS_%'
), neg AS (
    SELECT count(*) AS controls,
           count(*) FILTER (WHERE status='PASS') AS passes,
           count(*) FILTER (WHERE status='FAIL') AS failures
    FROM msbf_ctl.run_evidence
    WHERE run_id=(SELECT run_id FROM r) AND evidence_code LIKE 'M1_14_NEG_%'
), policy AS (
    SELECT profile_payload
    FROM msbf_ctl.policy_profile
    WHERE profile_code='M1_14_UNIT_ECONOMICS_CONTRIBUTION'
      AND profile_version=1 AND status='APPROVED'
), rows AS (
    SELECT
        (SELECT count(*) FROM msbf_m1.application_unit_economics_snapshot
         WHERE module1_run_id=(SELECT run_id FROM r)) AS snapshots,
        (SELECT count(*) FROM msbf_m1.unit_economics_component_value
         WHERE module1_run_id=(SELECT run_id FROM r)) AS components,
        (SELECT count(DISTINCT merchant_application_id)
         FROM msbf_m1.application_unit_economics_snapshot
         WHERE module1_run_id=(SELECT run_id FROM r)) AS applications,
        (SELECT count(DISTINCT scenario_id)
         FROM msbf_m1.application_unit_economics_snapshot
         WHERE module1_run_id=(SELECT run_id FROM r)) AS scenarios,
        (SELECT count(*) FROM msbf_m1.application_unit_economics_snapshot e
         WHERE e.module1_run_id=(SELECT run_id FROM r)
           AND e.row_hash<>msbf_m1.m1_14_hash_jsonb(to_jsonb(e)-'row_hash'-'created_at')) AS snapshot_hash_mismatches,
        (SELECT count(*) FROM msbf_m1.unit_economics_component_value c
         WHERE c.module1_run_id=(SELECT run_id FROM r)
           AND c.calculation_hash<>msbf_m1.m1_14_hash_jsonb(to_jsonb(c)-'calculation_hash'-'created_at')) AS component_hash_mismatches,
        (SELECT count(*) FROM msbf_m1.application_unit_economics_snapshot
         WHERE module1_run_id=(SELECT run_id FROM r)
           AND contribution_before_comparative_loss_amount IS DISTINCT FROM
               round(gross_finance_revenue_amount-total_non_loss_cost_amount,2)::numeric(18,2)) AS preloss_identity_violations,
        (SELECT count(*) FROM msbf_m1.application_unit_economics_snapshot
         WHERE module1_run_id=(SELECT run_id FROM r)
           AND unit_economics_evidence_status='BLOCKED'
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
           )) AS blocked_contract_violations,
        (SELECT count(*)
         FROM msbf_m1.application_unit_economics_snapshot e
         JOIN msbf_ctl.scenario_registry sr USING(scenario_id)
         WHERE e.module1_run_id=(SELECT run_id FROM r)
           AND sr.scenario_code='RECESSION_ENERGY'
           AND e.unit_economics_evidence_status<>'BLOCKED'
           AND e.risk_adjusted_contribution_amount IS DISTINCT FROM
               CASE
                   WHEN e.baseline_risk_adjusted_contribution_amount IS NULL THEN NULL
                   ELSE least(
                       e.independent_risk_adjusted_contribution_amount,
                       e.baseline_risk_adjusted_contribution_amount
                   )::numeric(18,2)
               END) AS stress_contribution_floor_violations,
        (SELECT count(*) FROM msbf_m1.application_unit_economics_snapshot e
         JOIN msbf_ctl.scenario_registry sr USING(scenario_id)
         WHERE e.module1_run_id=(SELECT run_id FROM r)
           AND sr.scenario_code='RECESSION_ENERGY'
           AND e.risk_adjusted_contribution_amount>e.baseline_risk_adjusted_contribution_amount) AS stress_contribution_improvements,
        (SELECT count(*) FROM msbf_m1.application_unit_economics_snapshot e
         JOIN msbf_ctl.scenario_registry sr USING(scenario_id)
         WHERE e.module1_run_id=(SELECT run_id FROM r)
           AND sr.scenario_code='RECESSION_ENERGY'
           AND e.annualized_risk_adjusted_return_rate>e.baseline_annualized_risk_adjusted_return_rate) AS stress_return_improvements,
        (SELECT count(*) FROM msbf_m1.application_unit_economics_snapshot e
         JOIN msbf_ctl.scenario_registry sr USING(scenario_id)
         WHERE e.module1_run_id=(SELECT run_id FROM r)
           AND sr.scenario_code='RECESSION_ENERGY'
           AND e.economic_tier<e.baseline_economic_tier) AS stress_tier_improvements,
        (SELECT count(*) FROM msbf_m1.module1_latest
         WHERE module1_run_id=(SELECT run_id FROM r))
      + (SELECT count(*) FROM msbf_m1.module1_archive
         WHERE module1_run_id=(SELECT run_id FROM r)) AS downstream_rows,
        (SELECT count(*) FROM msbf_ctl.profile_resolution_error
         WHERE run_id=(SELECT run_id FROM r) AND severity='BLOCKING') AS blocking_errors
), actual AS (
    SELECT * FROM msbf_m1.m1_14_actual_snapshot((SELECT run_id FROM r))
    UNION ALL
    SELECT * FROM msbf_m1.m1_14_actual_component_snapshot((SELECT run_id FROM r))
), hashes AS (
    SELECT count(*) AS canonical_entities,
           (SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) FROM actual WHERE entity_key LIKE 'ECON|%') AS snapshot_hash,
           (SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) FROM actual WHERE entity_key LIKE 'COMP|%') AS component_hash,
           md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) AS combined_hash
    FROM actual
), stored AS (
    SELECT
        max(metric_value_text) FILTER (WHERE evidence_code='M1_14_SNAPSHOT_SET_HASH') AS stored_snapshot_hash,
        max(metric_value_text) FILTER (WHERE evidence_code='M1_14_COMPONENT_SET_HASH') AS stored_component_hash,
        max(metric_value_text) FILTER (WHERE evidence_code='M1_14_COMBINED_SET_HASH') AS stored_combined_hash,
        (max(metric_value_numeric) FILTER (WHERE evidence_code='M1_14_CANONICAL_MISMATCH_COUNT'))::bigint AS stored_mismatches
    FROM msbf_ctl.run_evidence
    WHERE run_id=(SELECT run_id FROM r)
)
SELECT
    r.run_id,r.run_status,
    pos.checks AS positive_checks,pos.passes AS positive_passes,pos.failures AS positive_failures,
    neg.controls AS negative_controls,neg.passes AS negative_passes,neg.failures AS negative_failures,
    rows.*,hashes.*,stored.*,
    policy.profile_payload->>'methodology_version' AS methodology_version,
    policy.profile_payload->>'contribution_basis_code' AS contribution_basis_code,
    policy.profile_payload->>'comparative_loss_basis_code' AS comparative_loss_basis_code,
    policy.profile_payload->>'funding_cost_basis_code' AS funding_cost_basis_code,
    policy.profile_payload->>'risk_capital_charge_basis_code' AS capital_charge_basis_code,
    policy.profile_payload->>'hurdle_basis_code' AS hurdle_basis_code,
    CASE
        WHEN r.run_status='M1_14_VALIDATED'
         AND pos.checks=82 AND pos.passes=82 AND pos.failures=0
         AND neg.controls=7 AND neg.passes=7 AND neg.failures=0
         AND rows.snapshots=1500 AND rows.components=21000
         AND rows.applications=750 AND rows.scenarios=2
         AND rows.snapshot_hash_mismatches=0 AND rows.component_hash_mismatches=0
         AND rows.preloss_identity_violations=0
         AND rows.blocked_contract_violations=0
         AND rows.stress_contribution_floor_violations=0
         AND rows.stress_contribution_improvements=0
         AND rows.stress_return_improvements=0
         AND rows.stress_tier_improvements=0
         AND rows.downstream_rows=0 AND rows.blocking_errors=0
         AND hashes.canonical_entities=22500
         AND stored.stored_mismatches=0
         AND hashes.snapshot_hash=stored.stored_snapshot_hash
         AND hashes.component_hash=stored.stored_component_hash
         AND hashes.combined_hash=stored.stored_combined_hash
         AND policy.profile_payload->>'methodology_version'='M1_14_METHOD_V1'
         AND policy.profile_payload->>'contribution_basis_code'='CONDITIONAL_IF_BOOKED'
         AND policy.profile_payload->>'comparative_loss_basis_code'='M1_13_SCHEDULE_ADJUSTED_COMPARATIVE_LOSS'
         AND (policy.profile_payload->>'stress_contribution_cap_to_baseline')::boolean
         AND (policy.profile_payload->>'stress_return_cap_to_baseline')::boolean
         AND (policy.profile_payload->>'stress_economic_tier_floor_to_baseline')::boolean
        THEN 'PASS' ELSE 'FAIL'
    END AS acceptance_status
FROM r CROSS JOIN pos CROSS JOIN neg CROSS JOIN rows CROSS JOIN hashes CROSS JOIN stored CROSS JOIN policy;

INSERT INTO msbf_ctl.acceptance_gate_result(
    run_id,gate_id,review_version,result_status,observed_value,threshold_value,
    finding,residual_limitation,reviewer_role,reviewed_at
)
SELECT
    a.run_id,'M1_14_UNIT_ECONOMICS_CONTRIBUTION',
    coalesce((SELECT max(review_version)+1 FROM msbf_ctl.acceptance_gate_result
              WHERE run_id=a.run_id AND gate_id='M1_14_UNIT_ECONOMICS_CONTRIBUTION'),1),
    a.acceptance_status,
    format('positive=%s/%s|negative=%s/%s|snapshots=%s|components=%s|canonical=%s|mismatches=%s|contribution_improvements=%s|return_improvements=%s|tier_improvements=%s',
           a.positive_passes,a.positive_checks,a.negative_passes,a.negative_controls,
           a.snapshots,a.components,a.canonical_entities,a.stored_mismatches,
           a.stress_contribution_improvements,a.stress_return_improvements,a.stress_tier_improvements),
    '82/82 positive; 7/7 negative; 1,500 snapshots; 21,000 components; zero mismatches; zero adverse-scenario improvements',
    CASE WHEN a.acceptance_status='PASS'
         THEN 'M1.14 unit economics and risk-adjusted contribution foundations accepted.'
         ELSE 'M1.14 acceptance requirements were not fully satisfied.' END,
    'Synthetic conditional-if-booked economics only; not recognized income, transfer pricing, regulatory capital, pricing, offer, or decisioning.',
    'Independent Validation',clock_timestamp()
FROM _m1_14_acceptance a;

INSERT INTO msbf_ctl.run_evidence(
    run_id,evidence_code,segment_key,metric_name,metric_value_text,
    unit_code,status,interpretation
)
SELECT run_id,'M1_14_ACCEPTANCE_SUMMARY','PORTFOLIO','M1.14 acceptance summary',
       format('positive=%s/%s|negative=%s/%s|snapshots=%s|components=%s|hash=%s',
              positive_passes,positive_checks,negative_passes,negative_controls,
              snapshots,components,combined_hash),
       'TEXT',acceptance_status,'Formal M1.14 acceptance summary.'
FROM _m1_14_acceptance
ON CONFLICT(run_id,evidence_code,segment_key) DO UPDATE SET
    metric_name=EXCLUDED.metric_name,metric_value_text=EXCLUDED.metric_value_text,
    metric_value_numeric=NULL,unit_code=EXCLUDED.unit_code,status=EXCLUDED.status,
    interpretation=EXCLUDED.interpretation,created_at=clock_timestamp();

UPDATE msbf_ctl.run_registry r
SET run_status=CASE WHEN a.acceptance_status='PASS' THEN 'M1_14_ACCEPTED' ELSE 'M1_14_FAILED' END,
    completed_at=CASE WHEN a.acceptance_status='PASS' THEN clock_timestamp() ELSE r.completed_at END,
    notes=coalesce(r.notes,'')||E'\nM1.14 v0.2R4 acceptance: '||a.acceptance_status||'.'
FROM _m1_14_acceptance a
WHERE r.run_id=a.run_id;

COMMIT;

SELECT a.*,r.run_status AS final_run_status,g.review_version,g.result_status AS gate_status
FROM _m1_14_acceptance a
JOIN msbf_ctl.run_registry r USING(run_id)
JOIN LATERAL (
    SELECT * FROM msbf_ctl.acceptance_gate_result x
    WHERE x.run_id=a.run_id AND x.gate_id='M1_14_UNIT_ECONOMICS_CONTRIBUTION'
    ORDER BY review_version DESC LIMIT 1
) g ON true;
