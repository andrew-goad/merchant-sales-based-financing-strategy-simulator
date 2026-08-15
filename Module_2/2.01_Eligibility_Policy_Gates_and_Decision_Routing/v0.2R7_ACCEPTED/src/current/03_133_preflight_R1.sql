/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
M2.1 — Eligibility, Policy Gates & Decision Routing Foundations

Program : 133_msbf_m2_1_preflight_validation_v0_2R1.sql
Version : v0.2R1
Title   : Hard-Stop Preflight Validation

Purpose
Verify the accepted G2 boundary, approved M2.1 policy and reference definitions, exact input cardinality, pristine application-level targets, absence of blocking errors and strict M2.2 stage boundary.

Inputs
M1.17 accepted bundle, G2 acceptance gate, M2.1 policy/reference objects and accepted integrated G2 view.

Outputs
One filterable preflight checkpoint with preflight_status=PASS or a fail-closed exception.

Stage boundary
Preflight does not create routing outcomes or change run status.

Execution standard
Run the complete file with DBeaver Execute SQL Script. Stop at the first
PostgreSQL error. Never use Retry, Skip or Skip All. Execute ROLLBACK after a
failed transactional program.
============================================================================ */

BEGIN;
SET LOCAL statement_timeout='15min';
SET LOCAL jit=off;

DROP TABLE IF EXISTS _m2_1_preflight;
CREATE TEMP TABLE _m2_1_preflight ON COMMIT PRESERVE ROWS AS
WITH r AS (
    SELECT run_id,run_status,population_id,as_of_date
    FROM msbf_ctl.run_registry
    WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
), g2 AS (
    SELECT bundle_code,bundle_version,schema_version,bundle_status,combined_g2_hash,
           integrated_consumption_rows,canonical_entities
    FROM msbf_ctl.m1_17_g2_bundle_registry
    WHERE module1_run_id=(SELECT run_id FROM r)
), gate AS (
    SELECT result_status
    FROM msbf_ctl.acceptance_gate_result
    WHERE run_id=(SELECT run_id FROM r) AND gate_id='G2_M1_CONTRACT'
    ORDER BY review_version DESC LIMIT 1
), p AS (
    SELECT * FROM msbf_ctl.m2_1_policy_profile WHERE policy_code='M2_1_ELIGIBILITY_POLICY_V1'
), counts AS (
    SELECT
      (SELECT count(*) FROM msbf_m1.v_m1_17_g2_integrated_consumption WHERE module1_run_id=(SELECT run_id FROM r)) AS input_rows,
      (SELECT count(DISTINCT merchant_application_id) FROM msbf_m1.v_m1_17_g2_integrated_consumption WHERE module1_run_id=(SELECT run_id FROM r)) AS applications,
      (SELECT count(DISTINCT scenario_id) FROM msbf_m1.v_m1_17_g2_integrated_consumption WHERE module1_run_id=(SELECT run_id FROM r)) AS scenarios,
      (SELECT count(*) FROM msbf_m1.v_m1_17_g2_integrated_consumption WHERE module1_run_id=(SELECT run_id FROM r) AND scenario_code='BASELINE') AS baseline_rows,
      (SELECT count(*) FROM msbf_m1.v_m1_17_g2_integrated_consumption WHERE module1_run_id=(SELECT run_id FROM r) AND scenario_code='RECESSION_ENERGY') AS stress_rows,
      (SELECT count(*) FROM msbf_m2.strategy_campaign WHERE module1_run_id=(SELECT run_id FROM r) AND strategy_campaign_code='M2_1_CONTROLLED_ENTRY_BASELINE') AS campaign_rows,
      (SELECT count(*) FROM msbf_m2.policy_gate_definition WHERE module1_run_id=(SELECT run_id FROM r) AND strategy_campaign_code='M2_1_CONTROLLED_ENTRY_BASELINE') AS gate_definition_rows,
      (SELECT count(*) FROM msbf_m2.reason_code_definition WHERE module1_run_id=(SELECT run_id FROM r) AND strategy_campaign_code='M2_1_CONTROLLED_ENTRY_BASELINE') AS reason_rows,
      (SELECT count(*) FROM msbf_m2.routing_outcome_definition WHERE module1_run_id=(SELECT run_id FROM r) AND strategy_campaign_code='M2_1_CONTROLLED_ENTRY_BASELINE') AS outcome_rows,
      (SELECT count(*) FROM msbf_m2.application_policy_gate_result WHERE module1_run_id=(SELECT run_id FROM r)) AS target_gate_rows,
      (SELECT count(*) FROM msbf_m2.application_eligibility_routing_snapshot WHERE module1_run_id=(SELECT run_id FROM r)) AS target_snapshot_rows,
      (SELECT count(*) FROM msbf_m2.application_eligibility_routing_latest WHERE module1_run_id=(SELECT run_id FROM r)) AS target_latest_rows,
      (SELECT count(*) FROM msbf_m2.application_eligibility_routing_archive WHERE module1_run_id=(SELECT run_id FROM r)) AS target_archive_rows,
      (SELECT count(*) FROM msbf_ctl.m2_1_strategy_contract_registry WHERE module1_run_id=(SELECT run_id FROM r)) AS target_registry_rows,
      (SELECT count(*) FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM r) AND evidence_code LIKE 'M2_1_%') AS evidence_rows,
      (SELECT count(*) FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM r) AND gate_id='M2_1_ELIGIBILITY_POLICY_ROUTING') AS acceptance_rows,
      (SELECT count(*) FROM msbf_ctl.profile_resolution_error WHERE run_id=(SELECT run_id FROM r) AND severity='BLOCKING') AS blocking_errors,
      (SELECT count(*) FROM information_schema.tables WHERE table_schema='msbf_m2' AND table_name LIKE 'm2_2%') AS m2_2_tables,
      (SELECT count(*)
       FROM information_schema.columns
       WHERE table_schema='msbf_m2'
         AND table_name IN (
             'application_policy_gate_result',
             'application_eligibility_routing_snapshot',
             'application_eligibility_routing_latest',
             'application_eligibility_routing_archive'
         )
         AND lower(column_name) IN (
             'apr','factor_rate','approved_amount','offer_amount',
             'remittance_rate','offer_term','approved_term','final_price',
             'funded_flag','funded_outcome','funding_status','booking_status',
             'adverse_action_code','adverse_action_notice'
         )) AS prohibited_columns,
      (SELECT count(*)
       FROM information_schema.columns
       WHERE table_schema='msbf_m2'
         AND table_name='reason_code_definition'
         AND lower(column_name)='production_adverse_action_flag')
          AS adverse_action_governance_columns,
      (SELECT count(*)
       FROM msbf_m2.reason_code_definition
       WHERE module1_run_id=(SELECT run_id FROM r)
         AND production_adverse_action_flag)
          AS production_adverse_action_rows
)
SELECT
    r.run_id,r.run_status,r.population_id,r.as_of_date,
    p.policy_status,p.configuration_hash AS policy_configuration_hash,
    g2.bundle_code AS source_g2_bundle_code,g2.bundle_version AS source_g2_bundle_version,
    g2.schema_version AS source_g2_schema_version,g2.bundle_status AS source_g2_bundle_status,
    g2.combined_g2_hash AS source_g2_combined_hash,g2.integrated_consumption_rows AS source_g2_registered_rows,
    gate.result_status AS g2_gate_status,c.*,
    CASE WHEN
      r.run_status='M1_17_ACCEPTED'
      AND p.policy_status='APPROVED'
      AND p.configuration_hash=msbf_ctl.m2_1_hash_jsonb(p.configuration_payload)
      AND g2.bundle_code='M1_G2_CONSUMPTION_BUNDLE' AND g2.bundle_version=1
      AND g2.schema_version='M1_G2_BUNDLE_SCHEMA_V1' AND g2.bundle_status='ACCEPTED'
      AND g2.combined_g2_hash='7d9e466da28cad2551aa99c4c40c912b' AND gate.result_status='PASS'
      AND c.input_rows=1500 AND c.applications=750 AND c.scenarios=2
      AND c.baseline_rows=750 AND c.stress_rows=750
      AND c.campaign_rows=1 AND c.gate_definition_rows=12 AND c.reason_rows=23 AND c.outcome_rows=4
      AND c.target_gate_rows=0 AND c.target_snapshot_rows=0 AND c.target_latest_rows=0
      AND c.target_archive_rows=0 AND c.target_registry_rows=0
      AND c.evidence_rows=0 AND c.acceptance_rows=0 AND c.blocking_errors=0
      AND c.m2_2_tables=0
      AND c.prohibited_columns=0
      AND c.adverse_action_governance_columns=1
      AND c.production_adverse_action_rows=0
    THEN 'PASS' ELSE 'FAIL' END AS preflight_status
FROM r CROSS JOIN g2 CROSS JOIN gate CROSS JOIN p CROSS JOIN counts c;

DO $m2_1_preflight_guard$
DECLARE v record;
BEGIN
    SELECT * INTO v FROM _m2_1_preflight;
    IF v.preflight_status<>'PASS' THEN
        RAISE EXCEPTION 'M2.1 preflight failed: %',row_to_json(v);
    END IF;
    PERFORM msbf_ctl.m2_1_assert_generation_ready(v.run_id);
END;
$m2_1_preflight_guard$;

COMMIT;
SELECT * FROM _m2_1_preflight;
