/* ============================================================================
MSBF M1.16 — Generation Checkpoint Reconstruction
Program : 118A_msbf_m1_16_generation_reconciliation_reconstructed_v0_2R3.sql
Version : v0.2R3
Purpose : Reconstruct Program 118 counts and hashes after a successful commit
          when the original DBeaver result tab was lost.
Use     : Contingency only. Do not use in the normal execution sequence.
Safety  : Read-only.
============================================================================ */

WITH ctx AS(
  SELECT r.run_id,r.run_code,r.run_version,r.run_status,r.population_id,r.as_of_date,
         c.contract_status,c.scenario_set_id,c.methodology_version,c.contract_code,
         c.contract_version,c.schema_version,c.source_m1_15_combined_hash,
         c.source_m1_14_combined_hash,c.policy_configuration_hash,
         c.source_profile_row_count,c.campaign_row_count,c.funnel_row_count,
         c.cost_ledger_row_count,c.touchpoint_row_count,c.attribution_row_count,
         c.cost_snapshot_row_count,c.component_row_count,c.latest_row_count,
         c.archive_row_count,c.integrated_view_row_count,c.source_profile_set_hash,
         c.campaign_set_hash,c.funnel_set_hash,c.cost_ledger_set_hash,c.touchpoint_set_hash,
         c.attribution_set_hash,c.cost_snapshot_set_hash,c.component_set_hash,
         c.latest_set_hash,c.archive_set_hash,c.contract_set_hash,c.combined_set_hash,
         c.contract_row_hash
  FROM msbf_ctl.run_registry r
  JOIN msbf_ctl.m1_16_acquisition_contract_registry c ON c.module1_run_id=r.run_id
  WHERE r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1
    AND c.contract_code='M1_ACQUISITION_CONSUMPTION' AND c.contract_version=1
), hashes AS(
 SELECT
  (SELECT md5(string_agg('SOURCE|'||acquisition_source_code||'|'||row_hash,'||' ORDER BY acquisition_source_code)) FROM msbf_m1.acquisition_source_profile WHERE module1_run_id=(SELECT run_id FROM ctx)) AS source_hash,
  (SELECT md5(string_agg('CAMPAIGN|'||acquisition_campaign_id||'|'||row_hash,'||' ORDER BY acquisition_campaign_id)) FROM msbf_m1.acquisition_marketing_campaign WHERE module1_run_id=(SELECT run_id FROM ctx)) AS campaign_hash,
  (SELECT md5(string_agg('FUNNEL|'||acquisition_campaign_id||'|'||stage_code||'|'||row_hash,'||' ORDER BY acquisition_campaign_id,stage_order)) FROM msbf_m1.acquisition_campaign_funnel_stage WHERE module1_run_id=(SELECT run_id FROM ctx)) AS funnel_hash,
  (SELECT md5(string_agg('LEDGER|'||acquisition_cost_line_id||'|'||row_hash,'||' ORDER BY acquisition_cost_line_id)) FROM msbf_m1.acquisition_cost_ledger WHERE module1_run_id=(SELECT run_id FROM ctx)) AS ledger_hash,
  (SELECT md5(string_agg('TOUCH|'||merchant_application_id||'|'||touchpoint_sequence||'|'||row_hash,'||' ORDER BY merchant_application_id,touchpoint_sequence)) FROM msbf_m1.application_acquisition_touchpoint WHERE module1_run_id=(SELECT run_id FROM ctx)) AS touch_hash,
  (SELECT md5(string_agg('ATTRIBUTION|'||merchant_application_id||'|'||row_hash,'||' ORDER BY merchant_application_id)) FROM msbf_m1.application_acquisition_attribution_snapshot WHERE module1_run_id=(SELECT run_id FROM ctx)) AS attribution_hash,
  (SELECT md5(string_agg('COST|'||merchant_application_id||'|'||row_hash,'||' ORDER BY merchant_application_id)) FROM msbf_m1.application_acquisition_cost_snapshot WHERE module1_run_id=(SELECT run_id FROM ctx)) AS cost_hash,
  (SELECT md5(string_agg('COMPONENT|'||merchant_application_id||'|'||cost_component_code||'|'||row_hash,'||' ORDER BY merchant_application_id,cost_component_code)) FROM msbf_m1.application_acquisition_cost_component_value WHERE module1_run_id=(SELECT run_id FROM ctx)) AS component_hash,
  (SELECT md5(string_agg('LATEST|'||merchant_application_id||'|'||contract_row_hash,'||' ORDER BY merchant_application_id)) FROM msbf_m1.application_acquisition_contract_latest WHERE module1_run_id=(SELECT run_id FROM ctx)) AS latest_hash,
  (SELECT md5(string_agg('ARCHIVE|'||contract_version||'|'||merchant_application_id||'|'||contract_row_hash,'||' ORDER BY contract_version,merchant_application_id)) FROM msbf_m1.application_acquisition_contract_archive WHERE module1_run_id=(SELECT run_id FROM ctx)) AS archive_hash
), contract_calc AS(
 SELECT h.source_hash,h.campaign_hash,h.funnel_hash,h.ledger_hash,h.touch_hash,
        h.attribution_hash,h.cost_hash,h.component_hash,h.latest_hash,h.archive_hash,
 md5('M1_ACQUISITION_CONSUMPTION|1|'||(SELECT run_id FROM ctx)||'|M1_ACQUISITION_SCHEMA_V1|'||
     (SELECT source_m1_15_combined_hash FROM ctx)||'|'||(SELECT source_m1_14_combined_hash FROM ctx)||'|'||
     (SELECT policy_configuration_hash FROM ctx)||'|'||h.source_hash||'|'||h.campaign_hash||'|'||
     h.funnel_hash||'|'||h.ledger_hash||'|'||h.touch_hash||'|'||h.attribution_hash||'|'||
     h.cost_hash||'|'||h.component_hash||'|'||h.latest_hash||'|'||h.archive_hash) AS contract_hash
 FROM hashes h
), all_entities AS(
 SELECT 'SOURCE|'||acquisition_source_code AS entity_key,row_hash FROM msbf_m1.acquisition_source_profile WHERE module1_run_id=(SELECT run_id FROM ctx)
 UNION ALL SELECT 'CAMPAIGN|'||acquisition_campaign_id,row_hash FROM msbf_m1.acquisition_marketing_campaign WHERE module1_run_id=(SELECT run_id FROM ctx)
 UNION ALL SELECT 'FUNNEL|'||acquisition_campaign_id||'|'||stage_code,row_hash FROM msbf_m1.acquisition_campaign_funnel_stage WHERE module1_run_id=(SELECT run_id FROM ctx)
 UNION ALL SELECT 'LEDGER|'||acquisition_cost_line_id,row_hash FROM msbf_m1.acquisition_cost_ledger WHERE module1_run_id=(SELECT run_id FROM ctx)
 UNION ALL SELECT 'TOUCH|'||merchant_application_id||'|'||touchpoint_sequence::text,row_hash FROM msbf_m1.application_acquisition_touchpoint WHERE module1_run_id=(SELECT run_id FROM ctx)
 UNION ALL SELECT 'ATTRIBUTION|'||merchant_application_id,row_hash FROM msbf_m1.application_acquisition_attribution_snapshot WHERE module1_run_id=(SELECT run_id FROM ctx)
 UNION ALL SELECT 'COST|'||merchant_application_id,row_hash FROM msbf_m1.application_acquisition_cost_snapshot WHERE module1_run_id=(SELECT run_id FROM ctx)
 UNION ALL SELECT 'COMPONENT|'||merchant_application_id||'|'||cost_component_code,row_hash FROM msbf_m1.application_acquisition_cost_component_value WHERE module1_run_id=(SELECT run_id FROM ctx)
 UNION ALL SELECT 'LATEST|'||merchant_application_id,contract_row_hash FROM msbf_m1.application_acquisition_contract_latest WHERE module1_run_id=(SELECT run_id FROM ctx)
 UNION ALL SELECT 'ARCHIVE|'||contract_version::text||'|'||merchant_application_id,contract_row_hash FROM msbf_m1.application_acquisition_contract_archive WHERE module1_run_id=(SELECT run_id FROM ctx)
 UNION ALL SELECT 'CONTRACT|'||contract_code||'|'||contract_version::text||'|'||module1_run_id::text,contract_row_hash FROM msbf_ctl.m1_16_acquisition_contract_registry WHERE module1_run_id=(SELECT run_id FROM ctx)
), combined AS(
 SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) AS combined_hash,count(*) AS entity_count FROM all_entities
)

SELECT
 ctx.run_id,ctx.run_code,ctx.run_version,ctx.run_status,ctx.contract_status,
 (SELECT count(*) FROM msbf_m1.acquisition_source_profile WHERE module1_run_id=ctx.run_id) AS source_profile_rows,
 (SELECT count(*) FROM msbf_m1.acquisition_marketing_campaign WHERE module1_run_id=ctx.run_id) AS campaign_rows,
 (SELECT count(*) FROM msbf_m1.acquisition_campaign_funnel_stage WHERE module1_run_id=ctx.run_id) AS funnel_rows,
 (SELECT count(*) FROM msbf_m1.acquisition_cost_ledger WHERE module1_run_id=ctx.run_id) AS cost_ledger_rows,
 (SELECT count(*) FROM msbf_m1.application_acquisition_touchpoint WHERE module1_run_id=ctx.run_id) AS touchpoint_rows,
 (SELECT count(*) FROM msbf_m1.application_acquisition_attribution_snapshot WHERE module1_run_id=ctx.run_id) AS attribution_rows,
 (SELECT count(*) FROM msbf_m1.application_acquisition_cost_snapshot WHERE module1_run_id=ctx.run_id) AS cost_snapshot_rows,
 (SELECT count(*) FROM msbf_m1.application_acquisition_cost_component_value WHERE module1_run_id=ctx.run_id) AS component_rows,
 (SELECT count(*) FROM msbf_m1.application_acquisition_contract_latest WHERE module1_run_id=ctx.run_id) AS latest_rows,
 (SELECT count(*) FROM msbf_m1.application_acquisition_contract_archive WHERE module1_run_id=ctx.run_id) AS archive_rows,
 (SELECT count(*) FROM msbf_m1.v_m1_16_module1_integrated_consumption WHERE module1_run_id=ctx.run_id) AS integrated_view_rows,
 combined.entity_count AS canonical_entities,
 contract_calc.source_hash,contract_calc.campaign_hash,contract_calc.funnel_hash,
 contract_calc.ledger_hash,contract_calc.touch_hash,contract_calc.attribution_hash,
 contract_calc.cost_hash,contract_calc.component_hash,contract_calc.latest_hash,
 contract_calc.archive_hash,contract_calc.contract_hash,combined.combined_hash,
 CASE WHEN ctx.run_status IN('M1_16_GENERATED','M1_16_VALIDATED','M1_16_ACCEPTED')
       AND ctx.source_profile_row_count=18
       AND ctx.campaign_row_count=20
       AND ctx.funnel_row_count=120
       AND ctx.cost_ledger_row_count=40
       AND ctx.touchpoint_row_count=1075
       AND ctx.attribution_row_count=750
       AND ctx.cost_snapshot_row_count=750
       AND ctx.component_row_count=9000
       AND ctx.latest_row_count=750
       AND ctx.archive_row_count=750
       AND ctx.integrated_view_row_count=1500
       AND combined.entity_count=13274
       AND ctx.source_profile_set_hash=contract_calc.source_hash
       AND ctx.campaign_set_hash=contract_calc.campaign_hash
       AND ctx.funnel_set_hash=contract_calc.funnel_hash
       AND ctx.cost_ledger_set_hash=contract_calc.ledger_hash
       AND ctx.touchpoint_set_hash=contract_calc.touch_hash
       AND ctx.attribution_set_hash=contract_calc.attribution_hash
       AND ctx.cost_snapshot_set_hash=contract_calc.cost_hash
       AND ctx.component_set_hash=contract_calc.component_hash
       AND ctx.latest_set_hash=contract_calc.latest_hash
       AND ctx.archive_set_hash=contract_calc.archive_hash
       AND ctx.contract_set_hash=contract_calc.contract_hash
       AND ctx.combined_set_hash=combined.combined_hash
      THEN 'PASS' ELSE 'FAIL' END AS generation_reconciliation_status
FROM ctx CROSS JOIN contract_calc CROSS JOIN combined;
