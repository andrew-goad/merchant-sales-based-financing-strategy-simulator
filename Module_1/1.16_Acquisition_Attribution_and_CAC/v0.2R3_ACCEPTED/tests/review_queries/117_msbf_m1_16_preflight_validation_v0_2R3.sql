/* ============================================================================
MSBF M1.16 Acquisition Source, Marketing Attribution & Merchant Acquisition Cost
Program : 117_msbf_m1_16_preflight_validation_v0_2R3.sql
Version : v0.2R3
Purpose : Prove the accepted M1.15 boundary, upstream hashes, scenario-invariant
          M1.14 acquisition cost, approved M1.16 policy, complete dictionaries,
          pristine M1.16 targets, and strict Module 2 stage boundary.
Safety  : Read-only except for a session-preserved temporary result table.
          Any failed prerequisite raises an exception and stops execution.
============================================================================ */
BEGIN;
SET LOCAL lock_timeout='10s';
SET LOCAL statement_timeout='10min';

DO $preflight_guard$
DECLARE v_run_id bigint;
BEGIN
  SELECT run_id INTO STRICT v_run_id FROM msbf_ctl.run_registry
  WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1;
  PERFORM msbf_m1.m1_16_assert_generation_ready(v_run_id);
END;
$preflight_guard$;

DROP TABLE IF EXISTS _m1_16_preflight;
CREATE TEMP TABLE _m1_16_preflight ON COMMIT PRESERVE ROWS AS
WITH r AS(
  SELECT * FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
), p AS(
  SELECT pp.status AS policy_status,ps.status AS parameter_set_status,ps.parameter_set_hash,
         pp.profile_payload
  FROM msbf_ctl.policy_profile pp
  JOIN msbf_ctl.parameter_set ps ON ps.parameter_set_id=pp.parameter_set_id
  WHERE pp.profile_code='M1_16_ACQUISITION_FOUNDATIONS' AND pp.profile_version=1
), s AS(
  SELECT count(DISTINCT l.scenario_id) AS scenario_count,
         count(DISTINCT l.scenario_id) FILTER(WHERE l.scenario_code='BASELINE') AS baseline_count,
         count(DISTINCT l.scenario_id) FILTER(WHERE l.scenario_code='RECESSION_ENERGY') AS stress_count,
         count(DISTINCT sr.scenario_set_id) AS scenario_set_count
  FROM msbf_m1.application_module1_latest l
  JOIN msbf_ctl.scenario_registry sr ON sr.scenario_id=l.scenario_id
  WHERE l.module1_run_id=(SELECT run_id FROM r)
), inv AS(
  SELECT count(*) AS divergence_count
  FROM msbf_m1.application_unit_economics_snapshot b
  JOIN msbf_ctl.scenario_registry br ON br.scenario_id=b.scenario_id AND br.scenario_code='BASELINE'
  JOIN msbf_m1.application_unit_economics_snapshot x
    ON x.module1_run_id=b.module1_run_id AND x.merchant_application_id=b.merchant_application_id
  JOIN msbf_ctl.scenario_registry xr ON xr.scenario_id=x.scenario_id AND xr.scenario_code='RECESSION_ENERGY'
  WHERE b.module1_run_id=(SELECT run_id FROM r)
    AND (b.partner_acquisition_cost_rate IS DISTINCT FROM x.partner_acquisition_cost_rate
      OR b.partner_acquisition_cost_amount IS DISTINCT FROM x.partner_acquisition_cost_amount)
), targets AS(
  SELECT
    (SELECT count(*) FROM msbf_m1.acquisition_source_profile WHERE module1_run_id=(SELECT run_id FROM r)) AS source_rows,
    (SELECT count(*) FROM msbf_m1.acquisition_marketing_campaign WHERE module1_run_id=(SELECT run_id FROM r)) AS campaign_rows,
    (SELECT count(*) FROM msbf_m1.acquisition_campaign_funnel_stage WHERE module1_run_id=(SELECT run_id FROM r)) AS funnel_rows,
    (SELECT count(*) FROM msbf_m1.acquisition_cost_ledger WHERE module1_run_id=(SELECT run_id FROM r)) AS ledger_rows,
    (SELECT count(*) FROM msbf_m1.application_acquisition_touchpoint WHERE module1_run_id=(SELECT run_id FROM r)) AS touchpoint_rows,
    (SELECT count(*) FROM msbf_m1.application_acquisition_attribution_snapshot WHERE module1_run_id=(SELECT run_id FROM r)) AS attribution_rows,
    (SELECT count(*) FROM msbf_m1.application_acquisition_cost_snapshot WHERE module1_run_id=(SELECT run_id FROM r)) AS cost_rows,
    (SELECT count(*) FROM msbf_m1.application_acquisition_cost_component_value WHERE module1_run_id=(SELECT run_id FROM r)) AS component_rows,
    (SELECT count(*) FROM msbf_m1.application_acquisition_contract_latest WHERE module1_run_id=(SELECT run_id FROM r)) AS latest_rows,
    (SELECT count(*) FROM msbf_m1.application_acquisition_contract_archive WHERE module1_run_id=(SELECT run_id FROM r)) AS archive_rows,
    (SELECT count(*) FROM msbf_ctl.m1_16_acquisition_contract_registry WHERE module1_run_id=(SELECT run_id FROM r)) AS registry_rows,
    (SELECT count(*) FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM r) AND evidence_code LIKE 'M1_16_%') AS evidence_rows,
    (SELECT count(*) FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM r) AND gate_id='M1_16_ACQUISITION_MARKETING_COST_FOUNDATIONS') AS gate_rows
), boundaries AS(
  SELECT
    (SELECT count(*) FROM msbf_m1.module1_latest WHERE module1_run_id=(SELECT run_id FROM r)) AS legacy_latest_rows,
    (SELECT count(*) FROM msbf_m1.module1_archive WHERE module1_run_id=(SELECT run_id FROM r)) AS legacy_archive_rows,
    (SELECT count(*) FROM msbf_ctl.profile_resolution_error WHERE run_id=(SELECT run_id FROM r) AND severity='BLOCKING') AS blocking_errors
)
SELECT
  r.run_id,r.run_code,r.run_version,r.run_status,r.population_id,r.as_of_date,
  r.parameter_snapshot_hash,r.profile_snapshot_hash,r.source_snapshot_hash,
  (SELECT metric_value_text FROM msbf_ctl.run_evidence WHERE run_id=r.run_id AND evidence_code='M1_14_COMBINED_SET_HASH' AND segment_key='PORTFOLIO') AS m1_14_combined_hash,
  (SELECT combined_set_hash FROM msbf_ctl.m1_15_consumption_contract_registry WHERE module1_run_id=r.run_id AND contract_code='M1_APPLICATION_CONSUMPTION' AND contract_version=1) AS m1_15_combined_hash,
  (SELECT contract_status FROM msbf_ctl.m1_15_consumption_contract_registry WHERE module1_run_id=r.run_id AND contract_code='M1_APPLICATION_CONSUMPTION' AND contract_version=1) AS m1_15_contract_status,
  (SELECT count(*) FROM msbf_m1.merchant_application WHERE created_by_run_id=r.run_id) AS applications,
  (SELECT count(*) FROM msbf_m1.application_unit_economics_snapshot WHERE module1_run_id=r.run_id) AS m1_14_rows,
  (SELECT count(*) FROM msbf_m1.application_module1_latest WHERE module1_run_id=r.run_id) AS m1_15_latest_rows,
  (SELECT count(*) FROM msbf_m1.application_module1_scenario_comparison WHERE module1_run_id=r.run_id) AS m1_15_comparison_rows,
  s.scenario_count,s.baseline_count,s.stress_count,s.scenario_set_count,
  inv.divergence_count AS m1_14_acquisition_scenario_divergence,
  p.policy_status,p.parameter_set_status,p.parameter_set_hash,
  (SELECT count(*) FROM msbf_ref.acquisition_source_family WHERE active_flag) AS source_family_dictionary_rows,
  (SELECT count(*) FROM msbf_ref.acquisition_funnel_stage WHERE active_flag) AS funnel_dictionary_rows,
  (SELECT count(*) FROM msbf_ref.acquisition_cost_basis WHERE active_flag) AS cost_basis_dictionary_rows,
  (SELECT count(*) FROM msbf_ref.acquisition_cost_timing WHERE active_flag) AS cost_timing_dictionary_rows,
  (SELECT count(*) FROM msbf_ref.acquisition_cost_component WHERE active_flag) AS component_dictionary_rows,
  (SELECT count(*) FROM msbf_ref.acquisition_legacy_overlap_policy WHERE status='APPROVED') AS overlap_policy_rows,
  t.source_rows,t.campaign_rows,t.funnel_rows,t.ledger_rows,t.touchpoint_rows,
  t.attribution_rows,t.cost_rows,t.component_rows,t.latest_rows,t.archive_rows,t.registry_rows,
  t.evidence_rows,t.gate_rows,b.legacy_latest_rows,b.legacy_archive_rows,b.blocking_errors,
  'PASS'::text AS preflight_status
FROM r CROSS JOIN p CROSS JOIN s CROSS JOIN inv CROSS JOIN targets t CROSS JOIN boundaries b;

DO $preflight_result_guard$
DECLARE x _m1_16_preflight%ROWTYPE;
BEGIN
  SELECT * INTO STRICT x FROM _m1_16_preflight;
  IF x.run_status<>'M1_15_ACCEPTED'
     OR x.parameter_snapshot_hash<>'bd09e598c82db96e47459d77fd11e7c8'
     OR x.profile_snapshot_hash<>'462cbd2ed92f68e5bdecf6b17537a973'
     OR x.source_snapshot_hash<>'93c3d1368fb2450ab4a08e2b721f92d3'
     OR x.m1_14_combined_hash<>'3a47f59b56fa158c18c111caa1c64909'
     OR x.m1_15_combined_hash<>'fcd2704e17ec0d2e73191ea36061d74b'
     OR x.m1_15_contract_status<>'ACCEPTED'
     OR x.applications<>750 OR x.m1_14_rows<>1500
     OR x.m1_15_latest_rows<>1500 OR x.m1_15_comparison_rows<>750
     OR x.scenario_count<>2 OR x.baseline_count<>1 OR x.stress_count<>1 OR x.scenario_set_count<>1
     OR x.m1_14_acquisition_scenario_divergence<>0
     OR x.policy_status<>'APPROVED' OR x.parameter_set_status<>'APPROVED'
     OR x.parameter_set_hash IS NULL
     OR x.source_family_dictionary_rows<>7 OR x.funnel_dictionary_rows<>6
     OR x.cost_basis_dictionary_rows<>15 OR x.cost_timing_dictionary_rows<>5
     OR x.component_dictionary_rows<>12 OR x.overlap_policy_rows<>40
     OR x.source_rows<>0 OR x.campaign_rows<>0 OR x.funnel_rows<>0 OR x.ledger_rows<>0
     OR x.touchpoint_rows<>0 OR x.attribution_rows<>0 OR x.cost_rows<>0 OR x.component_rows<>0
     OR x.latest_rows<>0 OR x.archive_rows<>0 OR x.registry_rows<>0 OR x.evidence_rows<>0 OR x.gate_rows<>0
     OR x.legacy_latest_rows<>0 OR x.legacy_archive_rows<>0 OR x.blocking_errors<>0 THEN
       RAISE EXCEPTION 'M1.16 preflight failed: %',row_to_json(x);
  END IF;
END;
$preflight_result_guard$;

COMMIT;
SELECT * FROM _m1_16_preflight;
