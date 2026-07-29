/* ============================================================================
MSBF M1.16 Acquisition Source, Marketing Attribution & Merchant Acquisition Cost
Program : 116_msbf_m1_16_acquisition_foundations_schema_policy_extension_v0_2R3.sql
Version : v0.2R3
Purpose : Register the M1.16 gate, dedicated parameter set and approved policy;
          create source/campaign/funnel/cost/attribution/contract tables,
          dictionaries, immutable archive controls, hash/readiness functions,
          and explicitly projected downstream views.
Inputs  : Accepted G0 through M1.15 database state.
Outputs : Schema and governed configuration only. No M1.16 business records.
Boundary: Acquisition evidence and economics foundation only. No credit
          eligibility, pricing, offer, approval, decline, funded CAC, LTV,
          marketing optimization, or Module 2 decisioning.
Safety  : Idempotent DDL and metadata upserts in one transaction. Accepted
          M1.14 and M1.15 tables are read-only dependencies and are not altered.
============================================================================ */

BEGIN;
SET LOCAL lock_timeout='10s';
SET LOCAL statement_timeout='10min';

/* ---------------------------------------------------------------------------
1. Acceptance gate, dedicated parameter set, and approved policy
--------------------------------------------------------------------------- */
INSERT INTO msbf_ref.acceptance_gate_catalog(gate_id,gate_name,module_code,severity,description)
VALUES(
    'M1_16_ACQUISITION_MARKETING_COST_FOUNDATIONS',
    'M1.16 Acquisition Source, Marketing Attribution and Merchant Acquisition Cost Foundations',
    'M1','BLOCKING',
    'Governed source, campaign, funnel, touchpoint, attribution, cost-allocation, M1.14 overlap, companion-contract, and archive acceptance.'
)
ON CONFLICT(gate_id) DO UPDATE SET
    gate_name=EXCLUDED.gate_name,module_code=EXCLUDED.module_code,
    severity=EXCLUDED.severity,active_flag=true,description=EXCLUDED.description;


INSERT INTO msbf_ref.feature_family(
    feature_family_code,feature_family_name,owner_role,active_flag,description
)
VALUES(
    'ACQUISITION_ECONOMICS','Acquisition Economics',
    'Enterprise Acquisition Analytics / Finance / Data Governance',true,
    'Governed synthetic acquisition-source, attribution, cost, and M1.14-overlap evidence.'
)
ON CONFLICT(feature_family_code) DO UPDATE SET
    feature_family_name=EXCLUDED.feature_family_name,
    owner_role=EXCLUDED.owner_role,active_flag=true,description=EXCLUDED.description;

INSERT INTO msbf_ctl.parameter_definition(
    parameter_name,parameter_category,parameter_subcategory,module_code,stage_code,
    data_type,unit_code,scope_dimensions,description,business_rationale,
    calculation_usage,default_value_text,minimum_value_numeric,maximum_value_numeric,
    allowed_values,required_flag,scenario_override_allowed_flag,change_class,
    owner_role,validation_rule,sensitivity_class,production_boundary,status,
    definition_version
)
VALUES
('m1_16_methodology_version','M1_16_ACQUISITION','FOUNDATIONS','M1','M1_16','TEXT',NULL,ARRAY['GLOBAL']::text[],'Governed M1.16 parameter m1_16_methodology_version.','Supports deterministic acquisition source, attribution, cost, contract, and validation behavior.','M1.16 schema/generation/validation','M1_16_METHOD_V1',NULL,NULL,NULL,true,false,'MATERIAL','Enterprise Acquisition Analytics',NULL,'MEDIUM','Synthetic demonstration only.','ACTIVE',1),
('m1_16_contract_code','M1_16_ACQUISITION','FOUNDATIONS','M1','M1_16','TEXT',NULL,ARRAY['GLOBAL']::text[],'Governed M1.16 parameter m1_16_contract_code.','Supports deterministic acquisition source, attribution, cost, contract, and validation behavior.','M1.16 schema/generation/validation','M1_ACQUISITION_CONSUMPTION',NULL,NULL,NULL,true,false,'MATERIAL','Enterprise Acquisition Analytics',NULL,'MEDIUM','Synthetic demonstration only.','ACTIVE',1),
('m1_16_contract_version','M1_16_ACQUISITION','FOUNDATIONS','M1','M1_16','INTEGER',NULL,ARRAY['GLOBAL']::text[],'Governed M1.16 parameter m1_16_contract_version.','Supports deterministic acquisition source, attribution, cost, contract, and validation behavior.','M1.16 schema/generation/validation','1',NULL,NULL,NULL,true,false,'MATERIAL','Enterprise Acquisition Analytics',NULL,'MEDIUM','Synthetic demonstration only.','ACTIVE',1),
('m1_16_schema_version','M1_16_ACQUISITION','FOUNDATIONS','M1','M1_16','TEXT',NULL,ARRAY['GLOBAL']::text[],'Governed M1.16 parameter m1_16_schema_version.','Supports deterministic acquisition source, attribution, cost, contract, and validation behavior.','M1.16 schema/generation/validation','M1_ACQUISITION_SCHEMA_V1',NULL,NULL,NULL,true,false,'MATERIAL','Enterprise Acquisition Analytics',NULL,'MEDIUM','Synthetic demonstration only.','ACTIVE',1),
('m1_16_attribution_method','M1_16_ACQUISITION','FOUNDATIONS','M1','M1_16','TEXT',NULL,ARRAY['GLOBAL']::text[],'Governed M1.16 parameter m1_16_attribution_method.','Supports deterministic acquisition source, attribution, cost, contract, and validation behavior.','M1.16 schema/generation/validation','GOVERNED_PRIMARY_TOUCH_V1',NULL,NULL,NULL,true,false,'MATERIAL','Enterprise Acquisition Analytics',NULL,'MEDIUM','Synthetic demonstration only.','ACTIVE',1),
('m1_16_source_profile_expected_rows','M1_16_ACQUISITION','FOUNDATIONS','M1','M1_16','INTEGER','ROWS',ARRAY['GLOBAL']::text[],'Governed M1.16 parameter m1_16_source_profile_expected_rows.','Supports deterministic acquisition source, attribution, cost, contract, and validation behavior.','M1.16 schema/generation/validation','18',NULL,NULL,NULL,true,false,'MATERIAL','Enterprise Acquisition Analytics',NULL,'MEDIUM','Synthetic demonstration only.','ACTIVE',1),
('m1_16_campaign_expected_rows','M1_16_ACQUISITION','FOUNDATIONS','M1','M1_16','INTEGER','ROWS',ARRAY['GLOBAL']::text[],'Governed M1.16 parameter m1_16_campaign_expected_rows.','Supports deterministic acquisition source, attribution, cost, contract, and validation behavior.','M1.16 schema/generation/validation','20',NULL,NULL,NULL,true,false,'MATERIAL','Enterprise Acquisition Analytics',NULL,'MEDIUM','Synthetic demonstration only.','ACTIVE',1),
('m1_16_funnel_stage_expected_rows','M1_16_ACQUISITION','FOUNDATIONS','M1','M1_16','INTEGER','ROWS',ARRAY['GLOBAL']::text[],'Governed M1.16 parameter m1_16_funnel_stage_expected_rows.','Supports deterministic acquisition source, attribution, cost, contract, and validation behavior.','M1.16 schema/generation/validation','120',NULL,NULL,NULL,true,false,'MATERIAL','Enterprise Acquisition Analytics',NULL,'MEDIUM','Synthetic demonstration only.','ACTIVE',1),
('m1_16_cost_ledger_expected_rows','M1_16_ACQUISITION','FOUNDATIONS','M1','M1_16','INTEGER','ROWS',ARRAY['GLOBAL']::text[],'Governed M1.16 parameter m1_16_cost_ledger_expected_rows.','Supports deterministic acquisition source, attribution, cost, contract, and validation behavior.','M1.16 schema/generation/validation','40',NULL,NULL,NULL,true,false,'MATERIAL','Enterprise Acquisition Analytics',NULL,'MEDIUM','Synthetic demonstration only.','ACTIVE',1),
('m1_16_touchpoint_expected_rows','M1_16_ACQUISITION','FOUNDATIONS','M1','M1_16','INTEGER','ROWS',ARRAY['GLOBAL']::text[],'Governed M1.16 parameter m1_16_touchpoint_expected_rows.','Supports deterministic acquisition source, attribution, cost, contract, and validation behavior.','M1.16 schema/generation/validation','1075',NULL,NULL,NULL,true,false,'MATERIAL','Enterprise Acquisition Analytics',NULL,'MEDIUM','Synthetic demonstration only.','ACTIVE',1),
('m1_16_attribution_expected_rows','M1_16_ACQUISITION','FOUNDATIONS','M1','M1_16','INTEGER','ROWS',ARRAY['GLOBAL']::text[],'Governed M1.16 parameter m1_16_attribution_expected_rows.','Supports deterministic acquisition source, attribution, cost, contract, and validation behavior.','M1.16 schema/generation/validation','750',NULL,NULL,NULL,true,false,'MATERIAL','Enterprise Acquisition Analytics',NULL,'MEDIUM','Synthetic demonstration only.','ACTIVE',1),
('m1_16_cost_snapshot_expected_rows','M1_16_ACQUISITION','FOUNDATIONS','M1','M1_16','INTEGER','ROWS',ARRAY['GLOBAL']::text[],'Governed M1.16 parameter m1_16_cost_snapshot_expected_rows.','Supports deterministic acquisition source, attribution, cost, contract, and validation behavior.','M1.16 schema/generation/validation','750',NULL,NULL,NULL,true,false,'MATERIAL','Enterprise Acquisition Analytics',NULL,'MEDIUM','Synthetic demonstration only.','ACTIVE',1),
('m1_16_component_expected_rows','M1_16_ACQUISITION','FOUNDATIONS','M1','M1_16','INTEGER','ROWS',ARRAY['GLOBAL']::text[],'Governed M1.16 parameter m1_16_component_expected_rows.','Supports deterministic acquisition source, attribution, cost, contract, and validation behavior.','M1.16 schema/generation/validation','9000',NULL,NULL,NULL,true,false,'MATERIAL','Enterprise Acquisition Analytics',NULL,'MEDIUM','Synthetic demonstration only.','ACTIVE',1),
('m1_16_latest_expected_rows','M1_16_ACQUISITION','FOUNDATIONS','M1','M1_16','INTEGER','ROWS',ARRAY['GLOBAL']::text[],'Governed M1.16 parameter m1_16_latest_expected_rows.','Supports deterministic acquisition source, attribution, cost, contract, and validation behavior.','M1.16 schema/generation/validation','750',NULL,NULL,NULL,true,false,'MATERIAL','Enterprise Acquisition Analytics',NULL,'MEDIUM','Synthetic demonstration only.','ACTIVE',1),
('m1_16_archive_expected_rows','M1_16_ACQUISITION','FOUNDATIONS','M1','M1_16','INTEGER','ROWS',ARRAY['GLOBAL']::text[],'Governed M1.16 parameter m1_16_archive_expected_rows.','Supports deterministic acquisition source, attribution, cost, contract, and validation behavior.','M1.16 schema/generation/validation','750',NULL,NULL,NULL,true,false,'MATERIAL','Enterprise Acquisition Analytics',NULL,'MEDIUM','Synthetic demonstration only.','ACTIVE',1),
('m1_16_integrated_view_expected_rows','M1_16_ACQUISITION','FOUNDATIONS','M1','M1_16','INTEGER','ROWS',ARRAY['GLOBAL']::text[],'Governed M1.16 parameter m1_16_integrated_view_expected_rows.','Supports deterministic acquisition source, attribution, cost, contract, and validation behavior.','M1.16 schema/generation/validation','1500',NULL,NULL,NULL,true,false,'MATERIAL','Enterprise Acquisition Analytics',NULL,'MEDIUM','Synthetic demonstration only.','ACTIVE',1),
('m1_16_contract_registry_expected_rows','M1_16_ACQUISITION','FOUNDATIONS','M1','M1_16','INTEGER','ROWS',ARRAY['GLOBAL']::text[],'Governed M1.16 parameter m1_16_contract_registry_expected_rows.','Supports deterministic acquisition source, attribution, cost, contract, and validation behavior.','M1.16 schema/generation/validation','1',NULL,NULL,NULL,true,false,'MATERIAL','Enterprise Acquisition Analytics',NULL,'MEDIUM','Synthetic demonstration only.','ACTIVE',1),
('m1_16_canonical_expected_rows','M1_16_ACQUISITION','FOUNDATIONS','M1','M1_16','INTEGER','ROWS',ARRAY['GLOBAL']::text[],'Governed M1.16 parameter m1_16_canonical_expected_rows.','Supports deterministic acquisition source, attribution, cost, contract, and validation behavior.','M1.16 schema/generation/validation','13274',NULL,NULL,NULL,true,false,'MATERIAL','Enterprise Acquisition Analytics',NULL,'MEDIUM','Synthetic demonstration only.','ACTIVE',1),
('m1_16_max_touchpoints','M1_16_ACQUISITION','FOUNDATIONS','M1','M1_16','INTEGER',NULL,ARRAY['GLOBAL']::text[],'Governed M1.16 parameter m1_16_max_touchpoints.','Supports deterministic acquisition source, attribution, cost, contract, and validation behavior.','M1.16 schema/generation/validation','3',NULL,NULL,NULL,true,false,'MATERIAL','Enterprise Acquisition Analytics',NULL,'MEDIUM','Synthetic demonstration only.','ACTIVE',1),
('m1_16_touchpoint_modulus_assisted','M1_16_ACQUISITION','FOUNDATIONS','M1','M1_16','INTEGER',NULL,ARRAY['GLOBAL']::text[],'Governed M1.16 parameter m1_16_touchpoint_modulus_assisted.','Supports deterministic acquisition source, attribution, cost, contract, and validation behavior.','M1.16 schema/generation/validation','3',NULL,NULL,NULL,true,false,'MATERIAL','Enterprise Acquisition Analytics',NULL,'MEDIUM','Synthetic demonstration only.','ACTIVE',1),
('m1_16_touchpoint_modulus_third','M1_16_ACQUISITION','FOUNDATIONS','M1','M1_16','INTEGER',NULL,ARRAY['GLOBAL']::text[],'Governed M1.16 parameter m1_16_touchpoint_modulus_third.','Supports deterministic acquisition source, attribution, cost, contract, and validation behavior.','M1.16 schema/generation/validation','10',NULL,NULL,NULL,true,false,'MATERIAL','Enterprise Acquisition Analytics',NULL,'MEDIUM','Synthetic demonstration only.','ACTIVE',1),
('m1_16_attribution_block_modulus','M1_16_ACQUISITION','FOUNDATIONS','M1','M1_16','INTEGER',NULL,ARRAY['GLOBAL']::text[],'Governed M1.16 parameter m1_16_attribution_block_modulus.','Supports deterministic acquisition source, attribution, cost, contract, and validation behavior.','M1.16 schema/generation/validation','47',NULL,NULL,NULL,true,false,'MATERIAL','Enterprise Acquisition Analytics',NULL,'MEDIUM','Synthetic demonstration only.','ACTIVE',1),
('m1_16_cost_block_modulus','M1_16_ACQUISITION','FOUNDATIONS','M1','M1_16','INTEGER',NULL,ARRAY['GLOBAL']::text[],'Governed M1.16 parameter m1_16_cost_block_modulus.','Supports deterministic acquisition source, attribution, cost, contract, and validation behavior.','M1.16 schema/generation/validation','61',NULL,NULL,NULL,true,false,'MATERIAL','Enterprise Acquisition Analytics',NULL,'MEDIUM','Synthetic demonstration only.','ACTIVE',1),
('m1_16_primary_attribution_weight','M1_16_ACQUISITION','FOUNDATIONS','M1','M1_16','NUMERIC','RATE',ARRAY['GLOBAL']::text[],'Governed M1.16 parameter m1_16_primary_attribution_weight.','Supports deterministic acquisition source, attribution, cost, contract, and validation behavior.','M1.16 schema/generation/validation','1.0',NULL,NULL,NULL,true,false,'MATERIAL','Enterprise Acquisition Analytics',NULL,'MEDIUM','Synthetic demonstration only.','ACTIVE',1),
('m1_16_assisted_attribution_weight','M1_16_ACQUISITION','FOUNDATIONS','M1','M1_16','NUMERIC','RATE',ARRAY['GLOBAL']::text[],'Governed M1.16 parameter m1_16_assisted_attribution_weight.','Supports deterministic acquisition source, attribution, cost, contract, and validation behavior.','M1.16 schema/generation/validation','0.0',NULL,NULL,NULL,true,false,'MATERIAL','Enterprise Acquisition Analytics',NULL,'MEDIUM','Synthetic demonstration only.','ACTIVE',1),
('m1_16_allocation_tolerance_currency','M1_16_ACQUISITION','FOUNDATIONS','M1','M1_16','NUMERIC','RATE',ARRAY['GLOBAL']::text[],'Governed M1.16 parameter m1_16_allocation_tolerance_currency.','Supports deterministic acquisition source, attribution, cost, contract, and validation behavior.','M1.16 schema/generation/validation','0.0',NULL,NULL,NULL,true,false,'MATERIAL','Enterprise Acquisition Analytics',NULL,'MEDIUM','Synthetic demonstration only.','ACTIVE',1),
('m1_16_scenario_invariance_required','M1_16_ACQUISITION','FOUNDATIONS','M1','M1_16','BOOLEAN',NULL,ARRAY['GLOBAL']::text[],'Governed M1.16 parameter m1_16_scenario_invariance_required.','Supports deterministic acquisition source, attribution, cost, contract, and validation behavior.','M1.16 schema/generation/validation','true',NULL,NULL,NULL,true,false,'MATERIAL','Enterprise Acquisition Analytics',NULL,'MEDIUM','Synthetic demonstration only.','ACTIVE',1),
('m1_16_supported_zero_requires_evidence','M1_16_ACQUISITION','FOUNDATIONS','M1','M1_16','BOOLEAN',NULL,ARRAY['GLOBAL']::text[],'Governed M1.16 parameter m1_16_supported_zero_requires_evidence.','Supports deterministic acquisition source, attribution, cost, contract, and validation behavior.','M1.16 schema/generation/validation','true',NULL,NULL,NULL,true,false,'MATERIAL','Enterprise Acquisition Analytics',NULL,'MEDIUM','Synthetic demonstration only.','ACTIVE',1),
('m1_16_unknown_overlap_is_blocked','M1_16_ACQUISITION','FOUNDATIONS','M1','M1_16','BOOLEAN',NULL,ARRAY['GLOBAL']::text[],'Governed M1.16 parameter m1_16_unknown_overlap_is_blocked.','Supports deterministic acquisition source, attribution, cost, contract, and validation behavior.','M1.16 schema/generation/validation','true',NULL,NULL,NULL,true,false,'MATERIAL','Enterprise Acquisition Analytics',NULL,'MEDIUM','Synthetic demonstration only.','ACTIVE',1),
('m1_16_synthetic_data_only','M1_16_ACQUISITION','FOUNDATIONS','M1','M1_16','BOOLEAN',NULL,ARRAY['GLOBAL']::text[],'Governed M1.16 parameter m1_16_synthetic_data_only.','Supports deterministic acquisition source, attribution, cost, contract, and validation behavior.','M1.16 schema/generation/validation','true',NULL,NULL,NULL,true,false,'MATERIAL','Enterprise Acquisition Analytics',NULL,'MEDIUM','Synthetic demonstration only.','ACTIVE',1),
('m1_16_no_pii','M1_16_ACQUISITION','FOUNDATIONS','M1','M1_16','BOOLEAN',NULL,ARRAY['GLOBAL']::text[],'Governed M1.16 parameter m1_16_no_pii.','Supports deterministic acquisition source, attribution, cost, contract, and validation behavior.','M1.16 schema/generation/validation','true',NULL,NULL,NULL,true,false,'MATERIAL','Enterprise Acquisition Analytics',NULL,'MEDIUM','Synthetic demonstration only.','ACTIVE',1),
('m1_16_prohibited_module2_outputs','M1_16_ACQUISITION','FOUNDATIONS','M1','M1_16','BOOLEAN',NULL,ARRAY['GLOBAL']::text[],'Governed M1.16 parameter m1_16_prohibited_module2_outputs.','Supports deterministic acquisition source, attribution, cost, contract, and validation behavior.','M1.16 schema/generation/validation','true',NULL,NULL,NULL,true,false,'MATERIAL','Enterprise Acquisition Analytics',NULL,'MEDIUM','Synthetic demonstration only.','ACTIVE',1)
ON CONFLICT(parameter_name) DO UPDATE SET
    parameter_category=EXCLUDED.parameter_category,
    parameter_subcategory=EXCLUDED.parameter_subcategory,
    module_code=EXCLUDED.module_code,stage_code=EXCLUDED.stage_code,
    data_type=EXCLUDED.data_type,unit_code=EXCLUDED.unit_code,
    scope_dimensions=EXCLUDED.scope_dimensions,description=EXCLUDED.description,
    business_rationale=EXCLUDED.business_rationale,
    calculation_usage=EXCLUDED.calculation_usage,
    default_value_text=EXCLUDED.default_value_text,
    required_flag=EXCLUDED.required_flag,
    scenario_override_allowed_flag=EXCLUDED.scenario_override_allowed_flag,
    change_class=EXCLUDED.change_class,owner_role=EXCLUDED.owner_role,
    sensitivity_class=EXCLUDED.sensitivity_class,
    production_boundary=EXCLUDED.production_boundary,status='ACTIVE',
    definition_version=EXCLUDED.definition_version;

INSERT INTO msbf_ctl.parameter_set(
    parameter_set_code,parameter_set_version,business_name,purpose,
    effective_start_date,status,owner_role,approver_role,approval_timestamp
)
SELECT
    'M1_16_ACQUISITION_FOUNDATIONS',1,
    'M1.16 Acquisition Source, Attribution and Cost Foundations',
    'Dedicated additive M1.16 deterministic acquisition configuration; does not mutate accepted G1 snapshots.',
    r.as_of_date,'APPROVED','Enterprise Acquisition Analytics',
    'Independent Validation',clock_timestamp()
FROM msbf_ctl.run_registry r
WHERE r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1
ON CONFLICT(parameter_set_code,parameter_set_version) DO UPDATE SET
    business_name=EXCLUDED.business_name,purpose=EXCLUDED.purpose,
    effective_start_date=EXCLUDED.effective_start_date,status='APPROVED',
    owner_role=EXCLUDED.owner_role,approver_role=EXCLUDED.approver_role,
    approval_timestamp=EXCLUDED.approval_timestamp;


INSERT INTO msbf_ctl.parameter_value(parameter_set_id,parameter_name,scope_key,scope_payload,value_text,unit_code,effective_start_date,change_reason)
SELECT ps.parameter_set_id,'m1_16_methodology_version','GLOBAL','{}'::jsonb,'M1_16_METHOD_V1','VALUE',r.as_of_date,'Initial governed M1.16 acquisition-foundations configuration.'
FROM msbf_ctl.parameter_set ps
JOIN msbf_ctl.run_registry r ON r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1
WHERE ps.parameter_set_code='M1_16_ACQUISITION_FOUNDATIONS' AND ps.parameter_set_version=1
ON CONFLICT(parameter_set_id,parameter_name,scope_key,effective_start_date) DO UPDATE SET
    scope_payload=EXCLUDED.scope_payload,


    value_text=EXCLUDED.value_text,
    unit_code=EXCLUDED.unit_code,
    change_reason=EXCLUDED.change_reason;

INSERT INTO msbf_ctl.parameter_value(parameter_set_id,parameter_name,scope_key,scope_payload,value_text,unit_code,effective_start_date,change_reason)
SELECT ps.parameter_set_id,'m1_16_contract_code','GLOBAL','{}'::jsonb,'M1_ACQUISITION_CONSUMPTION','VALUE',r.as_of_date,'Initial governed M1.16 acquisition-foundations configuration.'
FROM msbf_ctl.parameter_set ps
JOIN msbf_ctl.run_registry r ON r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1
WHERE ps.parameter_set_code='M1_16_ACQUISITION_FOUNDATIONS' AND ps.parameter_set_version=1
ON CONFLICT(parameter_set_id,parameter_name,scope_key,effective_start_date) DO UPDATE SET
    scope_payload=EXCLUDED.scope_payload,


    value_text=EXCLUDED.value_text,
    unit_code=EXCLUDED.unit_code,
    change_reason=EXCLUDED.change_reason;

INSERT INTO msbf_ctl.parameter_value(parameter_set_id,parameter_name,scope_key,scope_payload,value_numeric,unit_code,effective_start_date,change_reason)
SELECT ps.parameter_set_id,'m1_16_contract_version','GLOBAL','{}'::jsonb,1,'VALUE',r.as_of_date,'Initial governed M1.16 acquisition-foundations configuration.'
FROM msbf_ctl.parameter_set ps
JOIN msbf_ctl.run_registry r ON r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1
WHERE ps.parameter_set_code='M1_16_ACQUISITION_FOUNDATIONS' AND ps.parameter_set_version=1
ON CONFLICT(parameter_set_id,parameter_name,scope_key,effective_start_date) DO UPDATE SET
    scope_payload=EXCLUDED.scope_payload,
    value_numeric=EXCLUDED.value_numeric,


    unit_code=EXCLUDED.unit_code,
    change_reason=EXCLUDED.change_reason;

INSERT INTO msbf_ctl.parameter_value(parameter_set_id,parameter_name,scope_key,scope_payload,value_text,unit_code,effective_start_date,change_reason)
SELECT ps.parameter_set_id,'m1_16_schema_version','GLOBAL','{}'::jsonb,'M1_ACQUISITION_SCHEMA_V1','VALUE',r.as_of_date,'Initial governed M1.16 acquisition-foundations configuration.'
FROM msbf_ctl.parameter_set ps
JOIN msbf_ctl.run_registry r ON r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1
WHERE ps.parameter_set_code='M1_16_ACQUISITION_FOUNDATIONS' AND ps.parameter_set_version=1
ON CONFLICT(parameter_set_id,parameter_name,scope_key,effective_start_date) DO UPDATE SET
    scope_payload=EXCLUDED.scope_payload,


    value_text=EXCLUDED.value_text,
    unit_code=EXCLUDED.unit_code,
    change_reason=EXCLUDED.change_reason;

INSERT INTO msbf_ctl.parameter_value(parameter_set_id,parameter_name,scope_key,scope_payload,value_text,unit_code,effective_start_date,change_reason)
SELECT ps.parameter_set_id,'m1_16_attribution_method','GLOBAL','{}'::jsonb,'GOVERNED_PRIMARY_TOUCH_V1','VALUE',r.as_of_date,'Initial governed M1.16 acquisition-foundations configuration.'
FROM msbf_ctl.parameter_set ps
JOIN msbf_ctl.run_registry r ON r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1
WHERE ps.parameter_set_code='M1_16_ACQUISITION_FOUNDATIONS' AND ps.parameter_set_version=1
ON CONFLICT(parameter_set_id,parameter_name,scope_key,effective_start_date) DO UPDATE SET
    scope_payload=EXCLUDED.scope_payload,


    value_text=EXCLUDED.value_text,
    unit_code=EXCLUDED.unit_code,
    change_reason=EXCLUDED.change_reason;

INSERT INTO msbf_ctl.parameter_value(parameter_set_id,parameter_name,scope_key,scope_payload,value_numeric,unit_code,effective_start_date,change_reason)
SELECT ps.parameter_set_id,'m1_16_source_profile_expected_rows','GLOBAL','{}'::jsonb,18,'ROWS',r.as_of_date,'Initial governed M1.16 acquisition-foundations configuration.'
FROM msbf_ctl.parameter_set ps
JOIN msbf_ctl.run_registry r ON r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1
WHERE ps.parameter_set_code='M1_16_ACQUISITION_FOUNDATIONS' AND ps.parameter_set_version=1
ON CONFLICT(parameter_set_id,parameter_name,scope_key,effective_start_date) DO UPDATE SET
    scope_payload=EXCLUDED.scope_payload,
    value_numeric=EXCLUDED.value_numeric,


    unit_code=EXCLUDED.unit_code,
    change_reason=EXCLUDED.change_reason;

INSERT INTO msbf_ctl.parameter_value(parameter_set_id,parameter_name,scope_key,scope_payload,value_numeric,unit_code,effective_start_date,change_reason)
SELECT ps.parameter_set_id,'m1_16_campaign_expected_rows','GLOBAL','{}'::jsonb,20,'ROWS',r.as_of_date,'Initial governed M1.16 acquisition-foundations configuration.'
FROM msbf_ctl.parameter_set ps
JOIN msbf_ctl.run_registry r ON r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1
WHERE ps.parameter_set_code='M1_16_ACQUISITION_FOUNDATIONS' AND ps.parameter_set_version=1
ON CONFLICT(parameter_set_id,parameter_name,scope_key,effective_start_date) DO UPDATE SET
    scope_payload=EXCLUDED.scope_payload,
    value_numeric=EXCLUDED.value_numeric,


    unit_code=EXCLUDED.unit_code,
    change_reason=EXCLUDED.change_reason;

INSERT INTO msbf_ctl.parameter_value(parameter_set_id,parameter_name,scope_key,scope_payload,value_numeric,unit_code,effective_start_date,change_reason)
SELECT ps.parameter_set_id,'m1_16_funnel_stage_expected_rows','GLOBAL','{}'::jsonb,120,'ROWS',r.as_of_date,'Initial governed M1.16 acquisition-foundations configuration.'
FROM msbf_ctl.parameter_set ps
JOIN msbf_ctl.run_registry r ON r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1
WHERE ps.parameter_set_code='M1_16_ACQUISITION_FOUNDATIONS' AND ps.parameter_set_version=1
ON CONFLICT(parameter_set_id,parameter_name,scope_key,effective_start_date) DO UPDATE SET
    scope_payload=EXCLUDED.scope_payload,
    value_numeric=EXCLUDED.value_numeric,


    unit_code=EXCLUDED.unit_code,
    change_reason=EXCLUDED.change_reason;

INSERT INTO msbf_ctl.parameter_value(parameter_set_id,parameter_name,scope_key,scope_payload,value_numeric,unit_code,effective_start_date,change_reason)
SELECT ps.parameter_set_id,'m1_16_cost_ledger_expected_rows','GLOBAL','{}'::jsonb,40,'ROWS',r.as_of_date,'Initial governed M1.16 acquisition-foundations configuration.'
FROM msbf_ctl.parameter_set ps
JOIN msbf_ctl.run_registry r ON r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1
WHERE ps.parameter_set_code='M1_16_ACQUISITION_FOUNDATIONS' AND ps.parameter_set_version=1
ON CONFLICT(parameter_set_id,parameter_name,scope_key,effective_start_date) DO UPDATE SET
    scope_payload=EXCLUDED.scope_payload,
    value_numeric=EXCLUDED.value_numeric,


    unit_code=EXCLUDED.unit_code,
    change_reason=EXCLUDED.change_reason;

INSERT INTO msbf_ctl.parameter_value(parameter_set_id,parameter_name,scope_key,scope_payload,value_numeric,unit_code,effective_start_date,change_reason)
SELECT ps.parameter_set_id,'m1_16_touchpoint_expected_rows','GLOBAL','{}'::jsonb,1075,'ROWS',r.as_of_date,'Initial governed M1.16 acquisition-foundations configuration.'
FROM msbf_ctl.parameter_set ps
JOIN msbf_ctl.run_registry r ON r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1
WHERE ps.parameter_set_code='M1_16_ACQUISITION_FOUNDATIONS' AND ps.parameter_set_version=1
ON CONFLICT(parameter_set_id,parameter_name,scope_key,effective_start_date) DO UPDATE SET
    scope_payload=EXCLUDED.scope_payload,
    value_numeric=EXCLUDED.value_numeric,


    unit_code=EXCLUDED.unit_code,
    change_reason=EXCLUDED.change_reason;

INSERT INTO msbf_ctl.parameter_value(parameter_set_id,parameter_name,scope_key,scope_payload,value_numeric,unit_code,effective_start_date,change_reason)
SELECT ps.parameter_set_id,'m1_16_attribution_expected_rows','GLOBAL','{}'::jsonb,750,'ROWS',r.as_of_date,'Initial governed M1.16 acquisition-foundations configuration.'
FROM msbf_ctl.parameter_set ps
JOIN msbf_ctl.run_registry r ON r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1
WHERE ps.parameter_set_code='M1_16_ACQUISITION_FOUNDATIONS' AND ps.parameter_set_version=1
ON CONFLICT(parameter_set_id,parameter_name,scope_key,effective_start_date) DO UPDATE SET
    scope_payload=EXCLUDED.scope_payload,
    value_numeric=EXCLUDED.value_numeric,


    unit_code=EXCLUDED.unit_code,
    change_reason=EXCLUDED.change_reason;

INSERT INTO msbf_ctl.parameter_value(parameter_set_id,parameter_name,scope_key,scope_payload,value_numeric,unit_code,effective_start_date,change_reason)
SELECT ps.parameter_set_id,'m1_16_cost_snapshot_expected_rows','GLOBAL','{}'::jsonb,750,'ROWS',r.as_of_date,'Initial governed M1.16 acquisition-foundations configuration.'
FROM msbf_ctl.parameter_set ps
JOIN msbf_ctl.run_registry r ON r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1
WHERE ps.parameter_set_code='M1_16_ACQUISITION_FOUNDATIONS' AND ps.parameter_set_version=1
ON CONFLICT(parameter_set_id,parameter_name,scope_key,effective_start_date) DO UPDATE SET
    scope_payload=EXCLUDED.scope_payload,
    value_numeric=EXCLUDED.value_numeric,


    unit_code=EXCLUDED.unit_code,
    change_reason=EXCLUDED.change_reason;

INSERT INTO msbf_ctl.parameter_value(parameter_set_id,parameter_name,scope_key,scope_payload,value_numeric,unit_code,effective_start_date,change_reason)
SELECT ps.parameter_set_id,'m1_16_component_expected_rows','GLOBAL','{}'::jsonb,9000,'ROWS',r.as_of_date,'Initial governed M1.16 acquisition-foundations configuration.'
FROM msbf_ctl.parameter_set ps
JOIN msbf_ctl.run_registry r ON r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1
WHERE ps.parameter_set_code='M1_16_ACQUISITION_FOUNDATIONS' AND ps.parameter_set_version=1
ON CONFLICT(parameter_set_id,parameter_name,scope_key,effective_start_date) DO UPDATE SET
    scope_payload=EXCLUDED.scope_payload,
    value_numeric=EXCLUDED.value_numeric,


    unit_code=EXCLUDED.unit_code,
    change_reason=EXCLUDED.change_reason;

INSERT INTO msbf_ctl.parameter_value(parameter_set_id,parameter_name,scope_key,scope_payload,value_numeric,unit_code,effective_start_date,change_reason)
SELECT ps.parameter_set_id,'m1_16_latest_expected_rows','GLOBAL','{}'::jsonb,750,'ROWS',r.as_of_date,'Initial governed M1.16 acquisition-foundations configuration.'
FROM msbf_ctl.parameter_set ps
JOIN msbf_ctl.run_registry r ON r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1
WHERE ps.parameter_set_code='M1_16_ACQUISITION_FOUNDATIONS' AND ps.parameter_set_version=1
ON CONFLICT(parameter_set_id,parameter_name,scope_key,effective_start_date) DO UPDATE SET
    scope_payload=EXCLUDED.scope_payload,
    value_numeric=EXCLUDED.value_numeric,


    unit_code=EXCLUDED.unit_code,
    change_reason=EXCLUDED.change_reason;

INSERT INTO msbf_ctl.parameter_value(parameter_set_id,parameter_name,scope_key,scope_payload,value_numeric,unit_code,effective_start_date,change_reason)
SELECT ps.parameter_set_id,'m1_16_archive_expected_rows','GLOBAL','{}'::jsonb,750,'ROWS',r.as_of_date,'Initial governed M1.16 acquisition-foundations configuration.'
FROM msbf_ctl.parameter_set ps
JOIN msbf_ctl.run_registry r ON r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1
WHERE ps.parameter_set_code='M1_16_ACQUISITION_FOUNDATIONS' AND ps.parameter_set_version=1
ON CONFLICT(parameter_set_id,parameter_name,scope_key,effective_start_date) DO UPDATE SET
    scope_payload=EXCLUDED.scope_payload,
    value_numeric=EXCLUDED.value_numeric,


    unit_code=EXCLUDED.unit_code,
    change_reason=EXCLUDED.change_reason;

INSERT INTO msbf_ctl.parameter_value(parameter_set_id,parameter_name,scope_key,scope_payload,value_numeric,unit_code,effective_start_date,change_reason)
SELECT ps.parameter_set_id,'m1_16_integrated_view_expected_rows','GLOBAL','{}'::jsonb,1500,'ROWS',r.as_of_date,'Initial governed M1.16 acquisition-foundations configuration.'
FROM msbf_ctl.parameter_set ps
JOIN msbf_ctl.run_registry r ON r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1
WHERE ps.parameter_set_code='M1_16_ACQUISITION_FOUNDATIONS' AND ps.parameter_set_version=1
ON CONFLICT(parameter_set_id,parameter_name,scope_key,effective_start_date) DO UPDATE SET
    scope_payload=EXCLUDED.scope_payload,
    value_numeric=EXCLUDED.value_numeric,


    unit_code=EXCLUDED.unit_code,
    change_reason=EXCLUDED.change_reason;

INSERT INTO msbf_ctl.parameter_value(parameter_set_id,parameter_name,scope_key,scope_payload,value_numeric,unit_code,effective_start_date,change_reason)
SELECT ps.parameter_set_id,'m1_16_contract_registry_expected_rows','GLOBAL','{}'::jsonb,1,'ROWS',r.as_of_date,'Initial governed M1.16 acquisition-foundations configuration.'
FROM msbf_ctl.parameter_set ps
JOIN msbf_ctl.run_registry r ON r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1
WHERE ps.parameter_set_code='M1_16_ACQUISITION_FOUNDATIONS' AND ps.parameter_set_version=1
ON CONFLICT(parameter_set_id,parameter_name,scope_key,effective_start_date) DO UPDATE SET
    scope_payload=EXCLUDED.scope_payload,
    value_numeric=EXCLUDED.value_numeric,


    unit_code=EXCLUDED.unit_code,
    change_reason=EXCLUDED.change_reason;

INSERT INTO msbf_ctl.parameter_value(parameter_set_id,parameter_name,scope_key,scope_payload,value_numeric,unit_code,effective_start_date,change_reason)
SELECT ps.parameter_set_id,'m1_16_canonical_expected_rows','GLOBAL','{}'::jsonb,13274,'ROWS',r.as_of_date,'Initial governed M1.16 acquisition-foundations configuration.'
FROM msbf_ctl.parameter_set ps
JOIN msbf_ctl.run_registry r ON r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1
WHERE ps.parameter_set_code='M1_16_ACQUISITION_FOUNDATIONS' AND ps.parameter_set_version=1
ON CONFLICT(parameter_set_id,parameter_name,scope_key,effective_start_date) DO UPDATE SET
    scope_payload=EXCLUDED.scope_payload,
    value_numeric=EXCLUDED.value_numeric,


    unit_code=EXCLUDED.unit_code,
    change_reason=EXCLUDED.change_reason;

INSERT INTO msbf_ctl.parameter_value(parameter_set_id,parameter_name,scope_key,scope_payload,value_numeric,unit_code,effective_start_date,change_reason)
SELECT ps.parameter_set_id,'m1_16_max_touchpoints','GLOBAL','{}'::jsonb,3,'VALUE',r.as_of_date,'Initial governed M1.16 acquisition-foundations configuration.'
FROM msbf_ctl.parameter_set ps
JOIN msbf_ctl.run_registry r ON r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1
WHERE ps.parameter_set_code='M1_16_ACQUISITION_FOUNDATIONS' AND ps.parameter_set_version=1
ON CONFLICT(parameter_set_id,parameter_name,scope_key,effective_start_date) DO UPDATE SET
    scope_payload=EXCLUDED.scope_payload,
    value_numeric=EXCLUDED.value_numeric,


    unit_code=EXCLUDED.unit_code,
    change_reason=EXCLUDED.change_reason;

INSERT INTO msbf_ctl.parameter_value(parameter_set_id,parameter_name,scope_key,scope_payload,value_numeric,unit_code,effective_start_date,change_reason)
SELECT ps.parameter_set_id,'m1_16_touchpoint_modulus_assisted','GLOBAL','{}'::jsonb,3,'VALUE',r.as_of_date,'Initial governed M1.16 acquisition-foundations configuration.'
FROM msbf_ctl.parameter_set ps
JOIN msbf_ctl.run_registry r ON r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1
WHERE ps.parameter_set_code='M1_16_ACQUISITION_FOUNDATIONS' AND ps.parameter_set_version=1
ON CONFLICT(parameter_set_id,parameter_name,scope_key,effective_start_date) DO UPDATE SET
    scope_payload=EXCLUDED.scope_payload,
    value_numeric=EXCLUDED.value_numeric,


    unit_code=EXCLUDED.unit_code,
    change_reason=EXCLUDED.change_reason;

INSERT INTO msbf_ctl.parameter_value(parameter_set_id,parameter_name,scope_key,scope_payload,value_numeric,unit_code,effective_start_date,change_reason)
SELECT ps.parameter_set_id,'m1_16_touchpoint_modulus_third','GLOBAL','{}'::jsonb,10,'VALUE',r.as_of_date,'Initial governed M1.16 acquisition-foundations configuration.'
FROM msbf_ctl.parameter_set ps
JOIN msbf_ctl.run_registry r ON r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1
WHERE ps.parameter_set_code='M1_16_ACQUISITION_FOUNDATIONS' AND ps.parameter_set_version=1
ON CONFLICT(parameter_set_id,parameter_name,scope_key,effective_start_date) DO UPDATE SET
    scope_payload=EXCLUDED.scope_payload,
    value_numeric=EXCLUDED.value_numeric,


    unit_code=EXCLUDED.unit_code,
    change_reason=EXCLUDED.change_reason;

INSERT INTO msbf_ctl.parameter_value(parameter_set_id,parameter_name,scope_key,scope_payload,value_numeric,unit_code,effective_start_date,change_reason)
SELECT ps.parameter_set_id,'m1_16_attribution_block_modulus','GLOBAL','{}'::jsonb,47,'VALUE',r.as_of_date,'Initial governed M1.16 acquisition-foundations configuration.'
FROM msbf_ctl.parameter_set ps
JOIN msbf_ctl.run_registry r ON r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1
WHERE ps.parameter_set_code='M1_16_ACQUISITION_FOUNDATIONS' AND ps.parameter_set_version=1
ON CONFLICT(parameter_set_id,parameter_name,scope_key,effective_start_date) DO UPDATE SET
    scope_payload=EXCLUDED.scope_payload,
    value_numeric=EXCLUDED.value_numeric,


    unit_code=EXCLUDED.unit_code,
    change_reason=EXCLUDED.change_reason;

INSERT INTO msbf_ctl.parameter_value(parameter_set_id,parameter_name,scope_key,scope_payload,value_numeric,unit_code,effective_start_date,change_reason)
SELECT ps.parameter_set_id,'m1_16_cost_block_modulus','GLOBAL','{}'::jsonb,61,'VALUE',r.as_of_date,'Initial governed M1.16 acquisition-foundations configuration.'
FROM msbf_ctl.parameter_set ps
JOIN msbf_ctl.run_registry r ON r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1
WHERE ps.parameter_set_code='M1_16_ACQUISITION_FOUNDATIONS' AND ps.parameter_set_version=1
ON CONFLICT(parameter_set_id,parameter_name,scope_key,effective_start_date) DO UPDATE SET
    scope_payload=EXCLUDED.scope_payload,
    value_numeric=EXCLUDED.value_numeric,


    unit_code=EXCLUDED.unit_code,
    change_reason=EXCLUDED.change_reason;

INSERT INTO msbf_ctl.parameter_value(parameter_set_id,parameter_name,scope_key,scope_payload,value_numeric,unit_code,effective_start_date,change_reason)
SELECT ps.parameter_set_id,'m1_16_primary_attribution_weight','GLOBAL','{}'::jsonb,1.0,'RATE',r.as_of_date,'Initial governed M1.16 acquisition-foundations configuration.'
FROM msbf_ctl.parameter_set ps
JOIN msbf_ctl.run_registry r ON r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1
WHERE ps.parameter_set_code='M1_16_ACQUISITION_FOUNDATIONS' AND ps.parameter_set_version=1
ON CONFLICT(parameter_set_id,parameter_name,scope_key,effective_start_date) DO UPDATE SET
    scope_payload=EXCLUDED.scope_payload,
    value_numeric=EXCLUDED.value_numeric,


    unit_code=EXCLUDED.unit_code,
    change_reason=EXCLUDED.change_reason;

INSERT INTO msbf_ctl.parameter_value(parameter_set_id,parameter_name,scope_key,scope_payload,value_numeric,unit_code,effective_start_date,change_reason)
SELECT ps.parameter_set_id,'m1_16_assisted_attribution_weight','GLOBAL','{}'::jsonb,0.0,'RATE',r.as_of_date,'Initial governed M1.16 acquisition-foundations configuration.'
FROM msbf_ctl.parameter_set ps
JOIN msbf_ctl.run_registry r ON r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1
WHERE ps.parameter_set_code='M1_16_ACQUISITION_FOUNDATIONS' AND ps.parameter_set_version=1
ON CONFLICT(parameter_set_id,parameter_name,scope_key,effective_start_date) DO UPDATE SET
    scope_payload=EXCLUDED.scope_payload,
    value_numeric=EXCLUDED.value_numeric,


    unit_code=EXCLUDED.unit_code,
    change_reason=EXCLUDED.change_reason;

INSERT INTO msbf_ctl.parameter_value(parameter_set_id,parameter_name,scope_key,scope_payload,value_numeric,unit_code,effective_start_date,change_reason)
SELECT ps.parameter_set_id,'m1_16_allocation_tolerance_currency','GLOBAL','{}'::jsonb,0.0,'RATE',r.as_of_date,'Initial governed M1.16 acquisition-foundations configuration.'
FROM msbf_ctl.parameter_set ps
JOIN msbf_ctl.run_registry r ON r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1
WHERE ps.parameter_set_code='M1_16_ACQUISITION_FOUNDATIONS' AND ps.parameter_set_version=1
ON CONFLICT(parameter_set_id,parameter_name,scope_key,effective_start_date) DO UPDATE SET
    scope_payload=EXCLUDED.scope_payload,
    value_numeric=EXCLUDED.value_numeric,


    unit_code=EXCLUDED.unit_code,
    change_reason=EXCLUDED.change_reason;

INSERT INTO msbf_ctl.parameter_value(parameter_set_id,parameter_name,scope_key,scope_payload,value_boolean,unit_code,effective_start_date,change_reason)
SELECT ps.parameter_set_id,'m1_16_scenario_invariance_required','GLOBAL','{}'::jsonb,true,'VALUE',r.as_of_date,'Initial governed M1.16 acquisition-foundations configuration.'
FROM msbf_ctl.parameter_set ps
JOIN msbf_ctl.run_registry r ON r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1
WHERE ps.parameter_set_code='M1_16_ACQUISITION_FOUNDATIONS' AND ps.parameter_set_version=1
ON CONFLICT(parameter_set_id,parameter_name,scope_key,effective_start_date) DO UPDATE SET
    scope_payload=EXCLUDED.scope_payload,

    value_boolean=EXCLUDED.value_boolean,

    unit_code=EXCLUDED.unit_code,
    change_reason=EXCLUDED.change_reason;

INSERT INTO msbf_ctl.parameter_value(parameter_set_id,parameter_name,scope_key,scope_payload,value_boolean,unit_code,effective_start_date,change_reason)
SELECT ps.parameter_set_id,'m1_16_supported_zero_requires_evidence','GLOBAL','{}'::jsonb,true,'VALUE',r.as_of_date,'Initial governed M1.16 acquisition-foundations configuration.'
FROM msbf_ctl.parameter_set ps
JOIN msbf_ctl.run_registry r ON r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1
WHERE ps.parameter_set_code='M1_16_ACQUISITION_FOUNDATIONS' AND ps.parameter_set_version=1
ON CONFLICT(parameter_set_id,parameter_name,scope_key,effective_start_date) DO UPDATE SET
    scope_payload=EXCLUDED.scope_payload,

    value_boolean=EXCLUDED.value_boolean,

    unit_code=EXCLUDED.unit_code,
    change_reason=EXCLUDED.change_reason;

INSERT INTO msbf_ctl.parameter_value(parameter_set_id,parameter_name,scope_key,scope_payload,value_boolean,unit_code,effective_start_date,change_reason)
SELECT ps.parameter_set_id,'m1_16_unknown_overlap_is_blocked','GLOBAL','{}'::jsonb,true,'VALUE',r.as_of_date,'Initial governed M1.16 acquisition-foundations configuration.'
FROM msbf_ctl.parameter_set ps
JOIN msbf_ctl.run_registry r ON r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1
WHERE ps.parameter_set_code='M1_16_ACQUISITION_FOUNDATIONS' AND ps.parameter_set_version=1
ON CONFLICT(parameter_set_id,parameter_name,scope_key,effective_start_date) DO UPDATE SET
    scope_payload=EXCLUDED.scope_payload,

    value_boolean=EXCLUDED.value_boolean,

    unit_code=EXCLUDED.unit_code,
    change_reason=EXCLUDED.change_reason;

INSERT INTO msbf_ctl.parameter_value(parameter_set_id,parameter_name,scope_key,scope_payload,value_boolean,unit_code,effective_start_date,change_reason)
SELECT ps.parameter_set_id,'m1_16_synthetic_data_only','GLOBAL','{}'::jsonb,true,'VALUE',r.as_of_date,'Initial governed M1.16 acquisition-foundations configuration.'
FROM msbf_ctl.parameter_set ps
JOIN msbf_ctl.run_registry r ON r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1
WHERE ps.parameter_set_code='M1_16_ACQUISITION_FOUNDATIONS' AND ps.parameter_set_version=1
ON CONFLICT(parameter_set_id,parameter_name,scope_key,effective_start_date) DO UPDATE SET
    scope_payload=EXCLUDED.scope_payload,

    value_boolean=EXCLUDED.value_boolean,

    unit_code=EXCLUDED.unit_code,
    change_reason=EXCLUDED.change_reason;

INSERT INTO msbf_ctl.parameter_value(parameter_set_id,parameter_name,scope_key,scope_payload,value_boolean,unit_code,effective_start_date,change_reason)
SELECT ps.parameter_set_id,'m1_16_no_pii','GLOBAL','{}'::jsonb,true,'VALUE',r.as_of_date,'Initial governed M1.16 acquisition-foundations configuration.'
FROM msbf_ctl.parameter_set ps
JOIN msbf_ctl.run_registry r ON r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1
WHERE ps.parameter_set_code='M1_16_ACQUISITION_FOUNDATIONS' AND ps.parameter_set_version=1
ON CONFLICT(parameter_set_id,parameter_name,scope_key,effective_start_date) DO UPDATE SET
    scope_payload=EXCLUDED.scope_payload,

    value_boolean=EXCLUDED.value_boolean,

    unit_code=EXCLUDED.unit_code,
    change_reason=EXCLUDED.change_reason;

INSERT INTO msbf_ctl.parameter_value(parameter_set_id,parameter_name,scope_key,scope_payload,value_boolean,unit_code,effective_start_date,change_reason)
SELECT ps.parameter_set_id,'m1_16_prohibited_module2_outputs','GLOBAL','{}'::jsonb,true,'VALUE',r.as_of_date,'Initial governed M1.16 acquisition-foundations configuration.'
FROM msbf_ctl.parameter_set ps
JOIN msbf_ctl.run_registry r ON r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1
WHERE ps.parameter_set_code='M1_16_ACQUISITION_FOUNDATIONS' AND ps.parameter_set_version=1
ON CONFLICT(parameter_set_id,parameter_name,scope_key,effective_start_date) DO UPDATE SET
    scope_payload=EXCLUDED.scope_payload,

    value_boolean=EXCLUDED.value_boolean,

    unit_code=EXCLUDED.unit_code,
    change_reason=EXCLUDED.change_reason;


UPDATE msbf_ctl.parameter_set ps
SET parameter_set_hash=(
    SELECT md5(string_agg(
        pv.parameter_name||'|'||pv.scope_key||'|'||
        coalesce(pv.value_numeric::text,pv.value_text,pv.value_boolean::text,pv.value_date::text,pv.value_json::text),
        '||' ORDER BY pv.parameter_name,pv.scope_key
    ))
    FROM msbf_ctl.parameter_value pv
    WHERE pv.parameter_set_id=ps.parameter_set_id
)
WHERE ps.parameter_set_code='M1_16_ACQUISITION_FOUNDATIONS' AND ps.parameter_set_version=1;

INSERT INTO msbf_ctl.policy_profile(
    profile_code,profile_version,business_name,effective_start_date,status,
    owner_role,approver_role,approval_timestamp,last_review_date,next_review_date,
    change_reason,policy_domain,parameter_set_id,profile_payload
)
SELECT
    'M1_16_ACQUISITION_FOUNDATIONS',1,
    'M1.16 Acquisition Source, Marketing Attribution and Merchant Acquisition Cost Foundations',
    r.as_of_date,'APPROVED','Enterprise Acquisition Analytics / Finance / Data Governance',
    'Independent Validation',clock_timestamp(),r.as_of_date,r.as_of_date+365,
    'New governed enhancement inserted before final G2 assurance.',
    'ACQUISITION_MARKETING_COST_FOUNDATIONS',ps.parameter_set_id,
    jsonb_build_object(
        'methodology_version','M1_16_METHOD_V1',
        'contract_code','M1_ACQUISITION_CONSUMPTION',
        'contract_version',1,
        'schema_version','M1_ACQUISITION_SCHEMA_V1',
        'attribution_method','GOVERNED_PRIMARY_TOUCH_V1',
        'source_profile_expected_rows',18,
        'campaign_expected_rows',20,
        'funnel_stage_expected_rows',120,
        'cost_ledger_expected_rows',40,
        'touchpoint_expected_rows',1075,
        'attribution_expected_rows',750,
        'cost_snapshot_expected_rows',750,
        'component_expected_rows',9000,
        'latest_expected_rows',750,
        'archive_expected_rows',750,
        'integrated_view_expected_rows',1500,
        'canonical_expected_rows',13274,
        'scenario_invariance_required',true,
        'synthetic_data_only',true,
        'no_pii',true,
        'm1_14_immutable',true,
        'm1_15_immutable',true,
        'production_boundary','Synthetic acquisition evidence and economics foundation; not credit decisioning, realized CAC, causal attribution, or accounting.'
    )
FROM msbf_ctl.run_registry r
JOIN msbf_ctl.parameter_set ps
  ON ps.parameter_set_code='M1_16_ACQUISITION_FOUNDATIONS' AND ps.parameter_set_version=1
WHERE r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1
ON CONFLICT(profile_code,profile_version) DO UPDATE SET
    business_name=EXCLUDED.business_name,effective_start_date=EXCLUDED.effective_start_date,
    status='APPROVED',owner_role=EXCLUDED.owner_role,approver_role=EXCLUDED.approver_role,
    approval_timestamp=EXCLUDED.approval_timestamp,last_review_date=EXCLUDED.last_review_date,
    next_review_date=EXCLUDED.next_review_date,change_reason=EXCLUDED.change_reason,
    policy_domain=EXCLUDED.policy_domain,parameter_set_id=EXCLUDED.parameter_set_id,
    profile_payload=EXCLUDED.profile_payload;

/* ---------------------------------------------------------------------------
2. Governed acquisition dictionaries
--------------------------------------------------------------------------- */
CREATE TABLE IF NOT EXISTS msbf_ref.acquisition_source_family(
    source_family_code text PRIMARY KEY,
    source_family_name text NOT NULL,
    description text NOT NULL,
    active_flag boolean NOT NULL DEFAULT true
);
INSERT INTO msbf_ref.acquisition_source_family(source_family_code,source_family_name,description)
VALUES
('PAID','Paid','Paid media, mail, or other directly purchased acquisition.'),
('OWNED','Owned','Bank-controlled website, email, or owned audience.'),
('ORGANIC','Organic','Unpaid discoverability or direct organic arrival.'),
('RELATIONSHIP','Relationship','Relationship-manager, branch, treasury, or existing-customer outreach.'),
('PROCESSOR_EMBEDDED','Processor Embedded','Processor dashboard, email, or account-manager pathway.'),
('STRATEGIC_PARTNER','Strategic Partner','Approved software, association, or merchant-services referral.'),
('BROKER_OR_LEAD','Broker or Lead','Broker, ISO, purchased-lead, or broker-direct pathway.')
ON CONFLICT(source_family_code) DO UPDATE SET
 source_family_name=EXCLUDED.source_family_name,description=EXCLUDED.description,active_flag=true;

CREATE TABLE IF NOT EXISTS msbf_ref.acquisition_funnel_stage(
    stage_code text PRIMARY KEY,
    stage_name text NOT NULL,
    stage_order smallint NOT NULL UNIQUE,
    description text NOT NULL,
    active_flag boolean NOT NULL DEFAULT true
);
INSERT INTO msbf_ref.acquisition_funnel_stage(stage_code,stage_name,stage_order,description)
VALUES
('TARGETED_OR_ELIGIBLE','Targeted or Eligible',1,'Normalized cross-channel acquisition funnel stage 1.'),
('DELIVERED_OR_PRESENTED','Delivered or Presented',2,'Normalized cross-channel acquisition funnel stage 2.'),
('ENGAGED_OR_RESPONDED','Engaged or Responded',3,'Normalized cross-channel acquisition funnel stage 3.'),
('QUALIFIED_LEAD','Qualified Lead',4,'Normalized cross-channel acquisition funnel stage 4.'),
('APPLICATION_STARTED','Application Started',5,'Normalized cross-channel acquisition funnel stage 5.'),
('APPLICATION_SUBMITTED','Application Submitted',6,'Normalized cross-channel acquisition funnel stage 6.')
ON CONFLICT(stage_code) DO UPDATE SET
 stage_name=EXCLUDED.stage_name,stage_order=EXCLUDED.stage_order,
 description=EXCLUDED.description,active_flag=true;

CREATE TABLE IF NOT EXISTS msbf_ref.acquisition_cost_basis(
    cost_basis_code text PRIMARY KEY,
    cost_basis_name text NOT NULL,
    conditional_basis_flag boolean NOT NULL,
    description text NOT NULL,
    active_flag boolean NOT NULL DEFAULT true
);
INSERT INTO msbf_ref.acquisition_cost_basis(cost_basis_code,cost_basis_name,conditional_basis_flag,description)
VALUES
('FIXED_CAMPAIGN','Fixed Campaign',false,'Governed acquisition cost basis: Fixed Campaign.'),
('PER_IMPRESSION_OR_DELIVERY','Per Impression or Delivery',false,'Governed acquisition cost basis: Per Impression or Delivery.'),
('PER_CLICK_OR_RESPONSE','Per Click or Response',false,'Governed acquisition cost basis: Per Click or Response.'),
('PER_QUALIFIED_LEAD','Per Qualified Lead',false,'Governed acquisition cost basis: Per Qualified Lead.'),
('PER_APPLICATION_START','Per Application Start',false,'Governed acquisition cost basis: Per Application Start.'),
('PER_SUBMITTED_APPLICATION','Per Submitted Application',false,'Governed acquisition cost basis: Per Submitted Application.'),
('PER_APPROVED_APPLICATION','Per Approved Application',true,'Governed acquisition cost basis: Per Approved Application.'),
('PER_ACCEPTED_OFFER','Per Accepted Offer',true,'Governed acquisition cost basis: Per Accepted Offer.'),
('PER_FUNDED_ACCOUNT','Per Funded Account',true,'Governed acquisition cost basis: Per Funded Account.'),
('PERCENT_FUNDED_AMOUNT','Percent of Funded Amount',true,'Governed acquisition cost basis: Percent of Funded Amount.'),
('INTERNAL_LABOR_HOUR','Internal Labor Hour',false,'Governed acquisition cost basis: Internal Labor Hour.'),
('ALLOCATED_OVERHEAD','Allocated Overhead',false,'Governed acquisition cost basis: Allocated Overhead.'),
('SUPPORTED_ZERO','Supported Zero',false,'Governed acquisition cost basis: Supported Zero.'),
('NOT_APPLICABLE','Not Applicable',false,'Governed acquisition cost basis: Not Applicable.'),
('GOVERNED_PARAMETER','Governed Parameter',false,'Governed acquisition cost basis: Governed Parameter.')
ON CONFLICT(cost_basis_code) DO UPDATE SET
 cost_basis_name=EXCLUDED.cost_basis_name,
 conditional_basis_flag=EXCLUDED.conditional_basis_flag,
 description=EXCLUDED.description,active_flag=true;

CREATE TABLE IF NOT EXISTS msbf_ref.acquisition_cost_timing(
    cost_timing_code text PRIMARY KEY,
    cost_timing_name text NOT NULL,
    incurred_flag boolean NOT NULL,
    conditional_flag boolean NOT NULL,
    description text NOT NULL,
    active_flag boolean NOT NULL DEFAULT true,
    CONSTRAINT ck_acq_timing_flags CHECK(num_nonnulls(incurred_flag,conditional_flag)=2 AND incurred_flag<>conditional_flag)
);
INSERT INTO msbf_ref.acquisition_cost_timing(cost_timing_code,cost_timing_name,incurred_flag,conditional_flag,description)
VALUES
('INCURRED_PRE_APPLICATION','Incurred Pre-Application',true,false,'Governed acquisition cost timing: Incurred Pre-Application.'),
('INCURRED_AT_APPLICATION','Incurred At Application',true,false,'Governed acquisition cost timing: Incurred At Application.'),
('CONDITIONAL_ON_APPROVAL','Conditional on Approval',false,true,'Governed acquisition cost timing: Conditional on Approval.'),
('CONDITIONAL_ON_ACCEPTANCE','Conditional on Acceptance',false,true,'Governed acquisition cost timing: Conditional on Acceptance.'),
('CONDITIONAL_ON_FUNDING','Conditional on Funding',false,true,'Governed acquisition cost timing: Conditional on Funding.')
ON CONFLICT(cost_timing_code) DO UPDATE SET
 cost_timing_name=EXCLUDED.cost_timing_name,incurred_flag=EXCLUDED.incurred_flag,
 conditional_flag=EXCLUDED.conditional_flag,description=EXCLUDED.description,active_flag=true;

CREATE TABLE IF NOT EXISTS msbf_ref.acquisition_cost_component(
    cost_component_code text PRIMARY KEY,
    cost_component_name text NOT NULL,
    component_role_code text NOT NULL,
    additive_flag boolean NOT NULL,
    included_in_detailed_total_flag boolean NOT NULL,
    included_in_enhanced_total_flag boolean NOT NULL,
    sign_multiplier smallint NOT NULL,
    display_order smallint NOT NULL UNIQUE,
    description text NOT NULL,
    active_flag boolean NOT NULL DEFAULT true,
    CONSTRAINT ck_acq_component_role CHECK(component_role_code IN(
      'ATOMIC_COST','REFERENCE_VALUE','OVERLAP_ADJUSTMENT','DERIVED_SUBTOTAL','DERIVED_TOTAL')),
    CONSTRAINT ck_acq_component_sign CHECK(sign_multiplier IN(-1,1))
);
INSERT INTO msbf_ref.acquisition_cost_component(
    cost_component_code,cost_component_name,component_role_code,additive_flag,
    included_in_detailed_total_flag,included_in_enhanced_total_flag,
    sign_multiplier,display_order,description
)
VALUES
('PAID_MEDIA_COST','Paid Media Cost','ATOMIC_COST',true,true,false,1,10,'Governed M1.16 acquisition-cost component: Paid Media Cost.'),
('DIRECT_MAIL_EVENT_OUTBOUND_COST','Direct Mail / Event / Outbound Cost','ATOMIC_COST',true,true,false,1,20,'Governed M1.16 acquisition-cost component: Direct Mail / Event / Outbound Cost.'),
('PURCHASED_LEAD_COST','Purchased Lead Cost','ATOMIC_COST',true,true,false,1,30,'Governed M1.16 acquisition-cost component: Purchased Lead Cost.'),
('INTERNAL_SALES_RM_COST','Internal Sales / RM Cost','ATOMIC_COST',true,true,false,1,40,'Governed M1.16 acquisition-cost component: Internal Sales / RM Cost.'),
('AGENCY_CREATIVE_TECH_COST','Agency / Creative / Technology Cost','ATOMIC_COST',true,true,false,1,50,'Governed M1.16 acquisition-cost component: Agency / Creative / Technology Cost.'),
('CAMPAIGN_OVERHEAD_COST','Campaign Overhead Cost','ATOMIC_COST',true,true,false,1,60,'Governed M1.16 acquisition-cost component: Campaign Overhead Cost.'),
('ACQUISITION_INCENTIVE_COST','Acquisition Incentive Cost','ATOMIC_COST',true,true,false,1,70,'Governed M1.16 acquisition-cost component: Acquisition Incentive Cost.'),
('DETAILED_CONDITIONAL_PARTNER_BROKER_COST','Detailed Conditional Partner / Broker Cost','ATOMIC_COST',true,true,false,1,80,'Governed M1.16 acquisition-cost component: Detailed Conditional Partner / Broker Cost.'),
('LEGACY_M1_14_ACQUISITION_COST','Accepted M1.14 Legacy Acquisition Cost','REFERENCE_VALUE',false,false,true,1,90,'Governed M1.16 acquisition-cost component: Accepted M1.14 Legacy Acquisition Cost.'),
('IDENTIFIED_LEGACY_OVERLAP','Identified Legacy Overlap','OVERLAP_ADJUSTMENT',false,false,false,-1,100,'Governed M1.16 acquisition-cost component: Identified Legacy Overlap.'),
('INCREMENTAL_ACQUISITION_COST_BEYOND_M1_14','Incremental Acquisition Cost Beyond M1.14','DERIVED_SUBTOTAL',false,false,true,1,110,'Governed M1.16 acquisition-cost component: Incremental Acquisition Cost Beyond M1.14.'),
('ENHANCED_TOTAL_ACQUISITION_COST_IF_BOOKED','Enhanced Total Acquisition Cost If Booked','DERIVED_TOTAL',false,false,false,1,120,'Governed M1.16 acquisition-cost component: Enhanced Total Acquisition Cost If Booked.')
ON CONFLICT(cost_component_code) DO UPDATE SET
 cost_component_name=EXCLUDED.cost_component_name,
 component_role_code=EXCLUDED.component_role_code,additive_flag=EXCLUDED.additive_flag,
 included_in_detailed_total_flag=EXCLUDED.included_in_detailed_total_flag,
 included_in_enhanced_total_flag=EXCLUDED.included_in_enhanced_total_flag,
 sign_multiplier=EXCLUDED.sign_multiplier,display_order=EXCLUDED.display_order,
 description=EXCLUDED.description,active_flag=true;


INSERT INTO msbf_m1.feature_definition(
    feature_code,feature_version,feature_name,feature_family_code,data_type,unit_code,
    observation_window_days,formula_description,expected_direction,valid_min_numeric,
    valid_max_numeric,owner_role,active_flag,production_boundary
)
SELECT
    c.cost_component_code,1,c.cost_component_name,'ACQUISITION_ECONOMICS','NUMERIC','CURRENCY',
    NULL,c.description,'DESCRIPTIVE',0,NULL,
    'Enterprise Acquisition Analytics / Finance / Data Governance',true,
    'Synthetic acquisition economics and overlap evidence; not production attribution, accounting, pricing, or credit decisioning.'
FROM msbf_ref.acquisition_cost_component c
WHERE c.active_flag
ON CONFLICT(feature_code,feature_version) DO UPDATE SET
    feature_name=EXCLUDED.feature_name,feature_family_code=EXCLUDED.feature_family_code,
    data_type=EXCLUDED.data_type,unit_code=EXCLUDED.unit_code,
    formula_description=EXCLUDED.formula_description,
    expected_direction=EXCLUDED.expected_direction,
    valid_min_numeric=EXCLUDED.valid_min_numeric,
    valid_max_numeric=EXCLUDED.valid_max_numeric,
    owner_role=EXCLUDED.owner_role,active_flag=true,
    production_boundary=EXCLUDED.production_boundary;

CREATE TABLE IF NOT EXISTS msbf_ref.acquisition_attribution_method(
    attribution_method_code text NOT NULL,
    method_version integer NOT NULL,
    method_name text NOT NULL,
    primary_weight numeric(9,6) NOT NULL,
    assisted_weight numeric(9,6) NOT NULL,
    max_touchpoints smallint NOT NULL,
    fallback_hierarchy jsonb NOT NULL,
    status text NOT NULL,
    description text NOT NULL,
    CONSTRAINT pk_acq_attribution_method PRIMARY KEY(attribution_method_code,method_version),
    CONSTRAINT ck_acq_attribution_weights CHECK(primary_weight BETWEEN 0 AND 1 AND assisted_weight BETWEEN 0 AND 1),
    CONSTRAINT ck_acq_attribution_touchpoints CHECK(max_touchpoints BETWEEN 1 AND 10)
);
INSERT INTO msbf_ref.acquisition_attribution_method(
    attribution_method_code,method_version,method_name,primary_weight,assisted_weight,
    max_touchpoints,fallback_hierarchy,status,description
)
VALUES(
    'GOVERNED_PRIMARY_TOUCH_V1',1,'Governed Primary Touch',1.000000,0.000000,3,
    '["SUPPORTED_PRIMARY","LAST_NON_DIRECT","FIRST_ONLY_TOUCH","ACCEPTED_PARENT_CHANNEL_FALLBACK","BLOCKED"]'::jsonb,
    'APPROVED','Deterministic descriptive and financial-allocation method; not causal multi-touch attribution.'
)
ON CONFLICT(attribution_method_code,method_version) DO UPDATE SET
 method_name=EXCLUDED.method_name,primary_weight=EXCLUDED.primary_weight,
 assisted_weight=EXCLUDED.assisted_weight,max_touchpoints=EXCLUDED.max_touchpoints,
 fallback_hierarchy=EXCLUDED.fallback_hierarchy,status='APPROVED',description=EXCLUDED.description;

CREATE TABLE IF NOT EXISTS msbf_ref.acquisition_legacy_overlap_policy(
    partner_channel_id text NOT NULL,
    cost_component_code text NOT NULL,
    legacy_scope_code text NOT NULL,
    overlap_class text NOT NULL,
    overlap_rate numeric(9,6) NOT NULL,
    status text NOT NULL,
    description text NOT NULL,
    CONSTRAINT pk_acq_overlap_policy PRIMARY KEY(partner_channel_id,cost_component_code),
    CONSTRAINT ck_acq_overlap_rate CHECK(overlap_rate BETWEEN 0 AND 1),
    CONSTRAINT ck_acq_overlap_class CHECK(overlap_class IN(
      'NOT_INCLUDED_IN_M1_14','POTENTIALLY_INCLUDED_IN_M1_14','FULLY_INCLUDED_IN_M1_14','BLOCKED_SCOPE')),
    CONSTRAINT fk_acq_overlap_channel FOREIGN KEY(partner_channel_id)
      REFERENCES msbf_m1.partner_channel(partner_channel_id) ON DELETE RESTRICT,
    CONSTRAINT fk_acq_overlap_component FOREIGN KEY(cost_component_code)
      REFERENCES msbf_ref.acquisition_cost_component(cost_component_code) ON DELETE RESTRICT
);

WITH channels AS(
  SELECT * FROM (VALUES
    ('CH_PROCESSOR_DIRECT','PROCESSOR_CHANNEL_COST_PROXY'),
    ('CH_BANK_RELATIONSHIP','RELATIONSHIP_ACQUISITION_PROXY'),
    ('CH_DIGITAL_DIRECT','DIGITAL_ACQUISITION_PROXY'),
    ('CH_STRATEGIC_PARTNER','STRATEGIC_PARTNER_COST_PROXY'),
    ('CH_BROKER_NETWORK','BROKER_ACQUISITION_PROXY')
  ) v(partner_channel_id,legacy_scope_code)
), atomic AS(
  SELECT cost_component_code
  FROM msbf_ref.acquisition_cost_component
  WHERE component_role_code='ATOMIC_COST'
), mapping AS(
 SELECT c.partner_channel_id,a.cost_component_code,c.legacy_scope_code,
   CASE
     WHEN a.cost_component_code='DETAILED_CONDITIONAL_PARTNER_BROKER_COST' THEN 'FULLY_INCLUDED_IN_M1_14'
     WHEN c.partner_channel_id='CH_PROCESSOR_DIRECT' AND a.cost_component_code IN('CAMPAIGN_OVERHEAD_COST','AGENCY_CREATIVE_TECH_COST','INTERNAL_SALES_RM_COST') THEN 'POTENTIALLY_INCLUDED_IN_M1_14'
     WHEN c.partner_channel_id='CH_BANK_RELATIONSHIP' AND a.cost_component_code IN('INTERNAL_SALES_RM_COST','CAMPAIGN_OVERHEAD_COST') THEN 'POTENTIALLY_INCLUDED_IN_M1_14'
     WHEN c.partner_channel_id='CH_DIGITAL_DIRECT' AND a.cost_component_code IN('PAID_MEDIA_COST','AGENCY_CREATIVE_TECH_COST','CAMPAIGN_OVERHEAD_COST') THEN 'POTENTIALLY_INCLUDED_IN_M1_14'
     WHEN c.partner_channel_id='CH_STRATEGIC_PARTNER' AND a.cost_component_code='CAMPAIGN_OVERHEAD_COST' THEN 'POTENTIALLY_INCLUDED_IN_M1_14'
     WHEN c.partner_channel_id='CH_BROKER_NETWORK' AND a.cost_component_code IN('PURCHASED_LEAD_COST','CAMPAIGN_OVERHEAD_COST') THEN 'POTENTIALLY_INCLUDED_IN_M1_14'
     ELSE 'NOT_INCLUDED_IN_M1_14' END AS overlap_class,
   CASE
     WHEN a.cost_component_code='DETAILED_CONDITIONAL_PARTNER_BROKER_COST' THEN 1.000000
     WHEN c.partner_channel_id='CH_PROCESSOR_DIRECT' AND a.cost_component_code='CAMPAIGN_OVERHEAD_COST' THEN 0.500000
     WHEN c.partner_channel_id='CH_PROCESSOR_DIRECT' AND a.cost_component_code IN('AGENCY_CREATIVE_TECH_COST','INTERNAL_SALES_RM_COST') THEN 0.250000
     WHEN c.partner_channel_id='CH_BANK_RELATIONSHIP' AND a.cost_component_code='INTERNAL_SALES_RM_COST' THEN 0.800000
     WHEN c.partner_channel_id='CH_BANK_RELATIONSHIP' AND a.cost_component_code='CAMPAIGN_OVERHEAD_COST' THEN 0.250000
     WHEN c.partner_channel_id='CH_DIGITAL_DIRECT' AND a.cost_component_code='PAID_MEDIA_COST' THEN 0.600000
     WHEN c.partner_channel_id='CH_DIGITAL_DIRECT' AND a.cost_component_code='AGENCY_CREATIVE_TECH_COST' THEN 0.500000
     WHEN c.partner_channel_id='CH_DIGITAL_DIRECT' AND a.cost_component_code='CAMPAIGN_OVERHEAD_COST' THEN 0.400000
     WHEN c.partner_channel_id='CH_STRATEGIC_PARTNER' AND a.cost_component_code='CAMPAIGN_OVERHEAD_COST' THEN 0.500000
     WHEN c.partner_channel_id='CH_BROKER_NETWORK' AND a.cost_component_code='PURCHASED_LEAD_COST' THEN 0.500000
     WHEN c.partner_channel_id='CH_BROKER_NETWORK' AND a.cost_component_code='CAMPAIGN_OVERHEAD_COST' THEN 0.400000
     ELSE 0.000000 END::numeric(9,6) AS overlap_rate
 FROM channels c CROSS JOIN atomic a
)
INSERT INTO msbf_ref.acquisition_legacy_overlap_policy(
 partner_channel_id,cost_component_code,legacy_scope_code,overlap_class,overlap_rate,status,description
)
SELECT partner_channel_id,cost_component_code,legacy_scope_code,overlap_class,overlap_rate,'APPROVED',
       'M1.16 component-level mapping to the accepted M1.14 broad acquisition-cost proxy.'
FROM mapping
ON CONFLICT(partner_channel_id,cost_component_code) DO UPDATE SET
 legacy_scope_code=EXCLUDED.legacy_scope_code,overlap_class=EXCLUDED.overlap_class,
 overlap_rate=EXCLUDED.overlap_rate,status='APPROVED',description=EXCLUDED.description;

/* ---------------------------------------------------------------------------
3. Governed source, campaign, funnel, ledger, touchpoint, attribution, and cost tables
--------------------------------------------------------------------------- */
CREATE TABLE IF NOT EXISTS msbf_m1.acquisition_source_profile(
    module1_run_id bigint NOT NULL,
    acquisition_source_code text NOT NULL,
    acquisition_source_name text NOT NULL,
    normalized_source_family text NOT NULL,
    source_subtype text NOT NULL,
    source_classification text NOT NULL,
    accepted_partner_channel_id text NOT NULL,
    accepted_channel_type text NOT NULL,
    source_owner_classification text NOT NULL,
    vendor_partner_code text NOT NULL,
    third_party_flag boolean NOT NULL,
    approved_source_flag boolean NOT NULL,
    governance_status text NOT NULL,
    permitted_attribution_roles text[] NOT NULL,
    permitted_cost_basis_codes text[] NOT NULL,
    permitted_cost_timing_codes text[] NOT NULL,
    default_attribution_priority smallint NOT NULL,
    effective_start_date date NOT NULL,
    effective_end_date date,
    source_evidence_status text NOT NULL,
    configuration_payload jsonb NOT NULL,
    row_hash text NOT NULL,
    created_by_run_id bigint NOT NULL,
    created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT pk_acq_source_profile PRIMARY KEY(module1_run_id,acquisition_source_code),
    CONSTRAINT ck_acq_source_dates CHECK(effective_end_date IS NULL OR effective_end_date>effective_start_date),
    CONSTRAINT ck_acq_source_class CHECK(source_classification IN('PAID','OWNED','ORGANIC','RELATIONSHIP','PROCESSOR_EMBEDDED','STRATEGIC_PARTNER','BROKER_OR_LEAD')),
    CONSTRAINT ck_acq_source_family_alignment CHECK(normalized_source_family=source_classification),
    CONSTRAINT ck_acq_source_evidence CHECK(source_evidence_status IN('COMPLETE','PARTIAL','BLOCKED')),
    CONSTRAINT ck_acq_source_run CHECK(created_by_run_id=module1_run_id),
    CONSTRAINT fk_acq_source_run FOREIGN KEY(module1_run_id) REFERENCES msbf_ctl.run_registry(run_id) ON DELETE CASCADE,
    CONSTRAINT fk_acq_source_family FOREIGN KEY(source_classification) REFERENCES msbf_ref.acquisition_source_family(source_family_code) ON DELETE RESTRICT,
    CONSTRAINT fk_acq_source_channel FOREIGN KEY(accepted_partner_channel_id) REFERENCES msbf_m1.partner_channel(partner_channel_id) ON DELETE RESTRICT
);

/* Ensure the source-family alignment contract also exists when Program 116
   is rerun after a prior schema-only execution. */
DO $source_family_alignment$
BEGIN
  IF NOT EXISTS(
      SELECT 1
      FROM pg_constraint
      WHERE conrelid='msbf_m1.acquisition_source_profile'::regclass
        AND conname='ck_acq_source_family_alignment'
  ) THEN
    ALTER TABLE msbf_m1.acquisition_source_profile
      ADD CONSTRAINT ck_acq_source_family_alignment
      CHECK(normalized_source_family=source_classification) NOT VALID;
  END IF;
  ALTER TABLE msbf_m1.acquisition_source_profile
    VALIDATE CONSTRAINT ck_acq_source_family_alignment;
END;
$source_family_alignment$;

CREATE TABLE IF NOT EXISTS msbf_m1.acquisition_marketing_campaign(
    module1_run_id bigint NOT NULL,
    acquisition_campaign_id text NOT NULL,
    acquisition_source_code text NOT NULL,
    accepted_partner_channel_id text NOT NULL,
    campaign_family_code text NOT NULL,
    campaign_type text NOT NULL,
    campaign_name_synthetic text NOT NULL,
    effective_start_date date NOT NULL,
    effective_end_date date NOT NULL,
    campaign_status text NOT NULL,
    approval_status text NOT NULL,
    audience_segment_code text NOT NULL,
    budget_amount numeric(18,2) NOT NULL,
    spend_amount numeric(18,2) NOT NULL,
    owner_classification text NOT NULL,
    vendor_partner_code text NOT NULL,
    always_on_flag boolean NOT NULL,
    campaign_evidence_status text NOT NULL,
    row_hash text NOT NULL,
    created_by_run_id bigint NOT NULL,
    created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT pk_acq_campaign PRIMARY KEY(module1_run_id,acquisition_campaign_id),
    CONSTRAINT ck_acq_campaign_dates CHECK(effective_end_date>=effective_start_date),
    CONSTRAINT ck_acq_campaign_amounts CHECK(budget_amount>=0 AND spend_amount>=0 AND budget_amount>=spend_amount),
    CONSTRAINT ck_acq_campaign_status CHECK(campaign_status IN('ACTIVE','INACTIVE','RETIRED') AND approval_status IN('APPROVED','DRAFT','REJECTED')),
    CONSTRAINT ck_acq_campaign_evidence CHECK(campaign_evidence_status IN('COMPLETE','PARTIAL','BLOCKED')),
    CONSTRAINT ck_acq_campaign_run CHECK(created_by_run_id=module1_run_id),
    CONSTRAINT fk_acq_campaign_source FOREIGN KEY(module1_run_id,acquisition_source_code) REFERENCES msbf_m1.acquisition_source_profile(module1_run_id,acquisition_source_code) ON DELETE CASCADE,
    CONSTRAINT fk_acq_campaign_channel FOREIGN KEY(accepted_partner_channel_id) REFERENCES msbf_m1.partner_channel(partner_channel_id) ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS msbf_m1.acquisition_campaign_funnel_stage(
    module1_run_id bigint NOT NULL,
    acquisition_campaign_id text NOT NULL,
    stage_code text NOT NULL,
    stage_order smallint NOT NULL,
    period_start_date date NOT NULL,
    period_end_date date NOT NULL,
    stage_count bigint NOT NULL,
    applicability_status text NOT NULL,
    conversion_rate_from_prior numeric(12,8),
    evidence_basis_code text NOT NULL,
    evidence_status text NOT NULL,
    row_hash text NOT NULL,
    created_by_run_id bigint NOT NULL,
    created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT pk_acq_funnel PRIMARY KEY(module1_run_id,acquisition_campaign_id,stage_code),
    CONSTRAINT ck_acq_funnel_count CHECK(stage_count>=0),
    CONSTRAINT ck_acq_funnel_applicability CHECK(applicability_status IN('APPLICABLE','NOT_APPLICABLE')),
    CONSTRAINT ck_acq_funnel_conversion CHECK(conversion_rate_from_prior IS NULL OR conversion_rate_from_prior BETWEEN 0 AND 1),
    CONSTRAINT ck_acq_funnel_evidence CHECK(evidence_status IN('COMPLETE','PARTIAL','BLOCKED')),
    CONSTRAINT ck_acq_funnel_run CHECK(created_by_run_id=module1_run_id),
    CONSTRAINT fk_acq_funnel_campaign FOREIGN KEY(module1_run_id,acquisition_campaign_id) REFERENCES msbf_m1.acquisition_marketing_campaign(module1_run_id,acquisition_campaign_id) ON DELETE CASCADE,
    CONSTRAINT fk_acq_funnel_stage FOREIGN KEY(stage_code) REFERENCES msbf_ref.acquisition_funnel_stage(stage_code) ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS msbf_m1.acquisition_cost_ledger(
    module1_run_id bigint NOT NULL,
    acquisition_cost_line_id text NOT NULL,
    acquisition_campaign_id text NOT NULL,
    acquisition_source_code text NOT NULL,
    cost_component_code text NOT NULL,
    cost_basis_code text NOT NULL,
    cost_timing_code text NOT NULL,
    quantity numeric(24,6) NOT NULL,
    unit_cost_amount numeric(18,6),
    unit_rate numeric(12,8),
    gross_cost_amount numeric(18,2) NOT NULL,
    currency_code text NOT NULL,
    incurred_effective_date date NOT NULL,
    allocable_flag boolean NOT NULL,
    conditional_flag boolean NOT NULL,
    allocation_method_code text NOT NULL,
    accepted_m1_14_overlap_class text NOT NULL,
    evidence_basis_code text NOT NULL,
    evidence_status text NOT NULL,
    row_hash text NOT NULL,
    created_by_run_id bigint NOT NULL,
    created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT pk_acq_cost_ledger PRIMARY KEY(module1_run_id,acquisition_cost_line_id),
    CONSTRAINT ck_acq_ledger_amounts CHECK(quantity>=0 AND gross_cost_amount>=0 AND (unit_cost_amount IS NULL OR unit_cost_amount>=0) AND (unit_rate IS NULL OR unit_rate BETWEEN 0 AND 1)),
    CONSTRAINT ck_acq_ledger_value CHECK(num_nonnulls(unit_cost_amount,unit_rate)=1),
    CONSTRAINT ck_acq_ledger_evidence CHECK(evidence_status IN('COMPLETE','PARTIAL','BLOCKED')),
    CONSTRAINT ck_acq_ledger_run CHECK(created_by_run_id=module1_run_id),
    CONSTRAINT fk_acq_ledger_campaign FOREIGN KEY(module1_run_id,acquisition_campaign_id) REFERENCES msbf_m1.acquisition_marketing_campaign(module1_run_id,acquisition_campaign_id) ON DELETE CASCADE,
    CONSTRAINT fk_acq_ledger_source FOREIGN KEY(module1_run_id,acquisition_source_code) REFERENCES msbf_m1.acquisition_source_profile(module1_run_id,acquisition_source_code) ON DELETE CASCADE,
    CONSTRAINT fk_acq_ledger_component FOREIGN KEY(cost_component_code) REFERENCES msbf_ref.acquisition_cost_component(cost_component_code) ON DELETE RESTRICT,
    CONSTRAINT fk_acq_ledger_basis FOREIGN KEY(cost_basis_code) REFERENCES msbf_ref.acquisition_cost_basis(cost_basis_code) ON DELETE RESTRICT,
    CONSTRAINT fk_acq_ledger_timing FOREIGN KEY(cost_timing_code) REFERENCES msbf_ref.acquisition_cost_timing(cost_timing_code) ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS msbf_m1.application_acquisition_touchpoint(
    module1_run_id bigint NOT NULL,
    merchant_application_id text NOT NULL,
    touchpoint_sequence smallint NOT NULL,
    merchant_id text NOT NULL,
    acquisition_source_code text NOT NULL,
    acquisition_campaign_id text NOT NULL,
    touchpoint_type text NOT NULL,
    touchpoint_timestamp timestamptz NOT NULL,
    first_touch_flag boolean NOT NULL,
    last_touch_flag boolean NOT NULL,
    primary_attribution_flag boolean NOT NULL,
    assisted_touch_flag boolean NOT NULL,
    attribution_weight numeric(9,6) NOT NULL,
    support_status text NOT NULL,
    evidence_status text NOT NULL,
    accepted_partner_channel_id text NOT NULL,
    row_hash text NOT NULL,
    created_by_run_id bigint NOT NULL,
    created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT pk_acq_touchpoint PRIMARY KEY(module1_run_id,merchant_application_id,touchpoint_sequence),
    CONSTRAINT ck_acq_touchpoint_sequence CHECK(touchpoint_sequence BETWEEN 1 AND 3),
    CONSTRAINT ck_acq_touchpoint_weight CHECK(attribution_weight BETWEEN 0 AND 1),
    CONSTRAINT ck_acq_touchpoint_flags CHECK(primary_attribution_flag<>assisted_touch_flag),
    CONSTRAINT ck_acq_touchpoint_evidence CHECK(evidence_status IN('COMPLETE','PARTIAL','BLOCKED')),
    CONSTRAINT ck_acq_touchpoint_run CHECK(created_by_run_id=module1_run_id),
    CONSTRAINT fk_acq_touchpoint_application FOREIGN KEY(merchant_application_id) REFERENCES msbf_m1.merchant_application(merchant_application_id) ON DELETE CASCADE,
    CONSTRAINT fk_acq_touchpoint_merchant FOREIGN KEY(merchant_id) REFERENCES msbf_m1.merchant_master(merchant_id) ON DELETE RESTRICT,
    CONSTRAINT fk_acq_touchpoint_source FOREIGN KEY(module1_run_id,acquisition_source_code) REFERENCES msbf_m1.acquisition_source_profile(module1_run_id,acquisition_source_code) ON DELETE RESTRICT,
    CONSTRAINT fk_acq_touchpoint_campaign FOREIGN KEY(module1_run_id,acquisition_campaign_id) REFERENCES msbf_m1.acquisition_marketing_campaign(module1_run_id,acquisition_campaign_id) ON DELETE RESTRICT,
    CONSTRAINT fk_acq_touchpoint_channel FOREIGN KEY(accepted_partner_channel_id) REFERENCES msbf_m1.partner_channel(partner_channel_id) ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS msbf_m1.application_acquisition_attribution_snapshot(
    module1_run_id bigint NOT NULL,
    merchant_application_id text NOT NULL,
    population_id text NOT NULL,
    merchant_id text NOT NULL,
    application_date date NOT NULL,
    as_of_date date NOT NULL,
    accepted_partner_channel_id text NOT NULL,
    accepted_channel_type text NOT NULL,
    accepted_application_channel text NOT NULL,
    first_touch_source_code text NOT NULL,
    first_touch_campaign_id text NOT NULL,
    last_touch_source_code text NOT NULL,
    last_touch_campaign_id text NOT NULL,
    primary_source_code text NOT NULL,
    primary_campaign_id text NOT NULL,
    touchpoint_count smallint NOT NULL,
    assisted_touch_count smallint NOT NULL,
    attribution_method_code text NOT NULL,
    attribution_method_version integer NOT NULL,
    attribution_confidence_score numeric(9,6) NOT NULL,
    attribution_confidence_tier text NOT NULL,
    parent_channel_reconciliation_status text NOT NULL,
    fallback_path_code text NOT NULL,
    primary_attribution_reason_code text NOT NULL,
    secondary_attribution_reason_codes text[] NOT NULL DEFAULT '{}'::text[],
    attribution_evidence_status text NOT NULL,
    application_request_hash text NOT NULL,
    m1_15_baseline_contract_row_hash text NOT NULL,
    m1_15_stress_contract_row_hash text NOT NULL,
    row_hash text NOT NULL,
    created_by_run_id bigint NOT NULL,
    created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT pk_acq_attribution PRIMARY KEY(module1_run_id,merchant_application_id),
    CONSTRAINT ck_acq_attribution_touch_count CHECK(touchpoint_count BETWEEN 1 AND 3 AND assisted_touch_count BETWEEN 0 AND touchpoint_count-1),
    CONSTRAINT ck_acq_attribution_confidence CHECK(attribution_confidence_score BETWEEN 0 AND 1),
    CONSTRAINT ck_acq_attribution_tier CHECK(attribution_confidence_tier IN('HIGH','MEDIUM','LOW','INSUFFICIENT')),
    CONSTRAINT ck_acq_attribution_parent_status CHECK(parent_channel_reconciliation_status IN('MATCH','GOVERNED_EXCEPTION','BLOCKED_CONFLICT')),
    CONSTRAINT ck_acq_attribution_evidence CHECK(attribution_evidence_status IN('COMPLETE','PARTIAL','BLOCKED')),
    CONSTRAINT ck_acq_attribution_run CHECK(created_by_run_id=module1_run_id),
    CONSTRAINT fk_acq_attribution_application FOREIGN KEY(merchant_application_id) REFERENCES msbf_m1.merchant_application(merchant_application_id) ON DELETE CASCADE,
    CONSTRAINT fk_acq_attribution_merchant FOREIGN KEY(merchant_id) REFERENCES msbf_m1.merchant_master(merchant_id) ON DELETE RESTRICT,
    CONSTRAINT fk_acq_attribution_population FOREIGN KEY(population_id) REFERENCES msbf_m1.population_registry(population_id) ON DELETE RESTRICT,
    CONSTRAINT fk_acq_attribution_method FOREIGN KEY(attribution_method_code,attribution_method_version) REFERENCES msbf_ref.acquisition_attribution_method(attribution_method_code,method_version) ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS msbf_m1.application_acquisition_cost_component_value(
    module1_run_id bigint NOT NULL,
    merchant_application_id text NOT NULL,
    cost_component_code text NOT NULL,
    component_version integer NOT NULL,
    component_role_code text NOT NULL,
    cost_timing_code text NOT NULL,
    cost_basis_code text NOT NULL,
    component_amount numeric(18,2),
    evidence_status text NOT NULL,
    included_in_m1_14_flag boolean NOT NULL,
    legacy_overlap_class text NOT NULL,
    sign_multiplier smallint NOT NULL,
    calculation_hash text NOT NULL,
    source_lineage_payload jsonb NOT NULL,
    row_hash text NOT NULL,
    created_by_run_id bigint NOT NULL,
    created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT pk_acq_cost_component PRIMARY KEY(module1_run_id,merchant_application_id,cost_component_code,component_version),
    CONSTRAINT ck_acq_cost_component_amount CHECK(component_amount IS NULL OR component_amount>=0),
    CONSTRAINT ck_acq_cost_component_evidence CHECK(evidence_status IN('COMPLETE','PARTIAL','BLOCKED','NOT_APPLICABLE')),
    CONSTRAINT ck_acq_cost_component_sign CHECK(sign_multiplier IN(-1,1)),
    CONSTRAINT ck_acq_cost_component_run CHECK(created_by_run_id=module1_run_id),
    CONSTRAINT fk_acq_cost_component_application FOREIGN KEY(merchant_application_id) REFERENCES msbf_m1.merchant_application(merchant_application_id) ON DELETE CASCADE,
    CONSTRAINT fk_acq_cost_component_definition FOREIGN KEY(cost_component_code) REFERENCES msbf_ref.acquisition_cost_component(cost_component_code) ON DELETE RESTRICT,
    CONSTRAINT fk_acq_cost_component_timing FOREIGN KEY(cost_timing_code) REFERENCES msbf_ref.acquisition_cost_timing(cost_timing_code) ON DELETE RESTRICT,
    CONSTRAINT fk_acq_cost_component_basis FOREIGN KEY(cost_basis_code) REFERENCES msbf_ref.acquisition_cost_basis(cost_basis_code) ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS msbf_m1.application_acquisition_cost_snapshot(
    module1_run_id bigint NOT NULL,
    merchant_application_id text NOT NULL,
    population_id text NOT NULL,
    merchant_id text NOT NULL,
    as_of_date date NOT NULL,
    accepted_partner_channel_id text NOT NULL,
    accepted_channel_type text NOT NULL,
    accepted_application_channel text NOT NULL,
    primary_source_code text NOT NULL,
    primary_campaign_id text NOT NULL,
    paid_media_cost_amount numeric(18,2) NOT NULL,
    direct_mail_event_outbound_cost_amount numeric(18,2) NOT NULL,
    purchased_lead_cost_amount numeric(18,2) NOT NULL,
    internal_sales_rm_cost_amount numeric(18,2) NOT NULL,
    agency_creative_tech_cost_amount numeric(18,2) NOT NULL,
    campaign_overhead_cost_amount numeric(18,2) NOT NULL,
    acquisition_incentive_cost_amount numeric(18,2) NOT NULL,
    detailed_conditional_partner_broker_cost_amount numeric(18,2) NOT NULL,
    direct_attributable_incurred_cost_amount numeric(18,2) NOT NULL,
    internally_allocated_acquisition_cost_amount numeric(18,2) NOT NULL,
    total_incurred_pre_application_cost_amount numeric(18,2) NOT NULL,
    detailed_total_acquisition_cost_if_booked numeric(18,2) NOT NULL,
    accepted_m1_14_acquisition_cost_rate numeric(12,8) NOT NULL,
    accepted_m1_14_acquisition_cost_amount numeric(18,2) NOT NULL,
    legacy_m1_14_cost_scope_code text NOT NULL,
    mapped_detailed_cost_potentially_represented numeric(18,2) NOT NULL,
    identified_legacy_overlap_amount numeric(18,2),
    unmapped_legacy_proxy_amount numeric(18,2),
    incremental_acquisition_cost_beyond_m1_14 numeric(18,2),
    enhanced_total_acquisition_cost_if_booked numeric(18,2),
    attribution_evidence_status text NOT NULL,
    cost_evidence_status text NOT NULL,
    overlap_evidence_status text NOT NULL,
    acquisition_contract_evidence_status text NOT NULL,
    supported_zero_component_count smallint NOT NULL,
    fallback_path_code text NOT NULL,
    primary_cost_reason_code text NOT NULL,
    secondary_cost_reason_codes text[] NOT NULL DEFAULT '{}'::text[],
    attribution_snapshot_hash text NOT NULL,
    m1_14_baseline_row_hash text NOT NULL,
    m1_14_stress_row_hash text NOT NULL,
    m1_14_combined_set_hash text NOT NULL,
    m1_15_baseline_contract_row_hash text NOT NULL,
    m1_15_stress_contract_row_hash text NOT NULL,
    m1_15_combined_set_hash text NOT NULL,
    m1_16_policy_configuration_hash text NOT NULL,
    row_hash text NOT NULL,
    created_by_run_id bigint NOT NULL,
    created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT pk_acq_cost_snapshot PRIMARY KEY(module1_run_id,merchant_application_id),
    CONSTRAINT ck_acq_cost_nonnegative CHECK(
      paid_media_cost_amount>=0 AND direct_mail_event_outbound_cost_amount>=0 AND purchased_lead_cost_amount>=0
      AND internal_sales_rm_cost_amount>=0 AND agency_creative_tech_cost_amount>=0 AND campaign_overhead_cost_amount>=0
      AND acquisition_incentive_cost_amount>=0 AND detailed_conditional_partner_broker_cost_amount>=0
      AND direct_attributable_incurred_cost_amount>=0 AND internally_allocated_acquisition_cost_amount>=0
      AND total_incurred_pre_application_cost_amount>=0 AND detailed_total_acquisition_cost_if_booked>=0
      AND accepted_m1_14_acquisition_cost_amount>=0 AND mapped_detailed_cost_potentially_represented>=0
      AND (identified_legacy_overlap_amount IS NULL OR identified_legacy_overlap_amount>=0)
      AND (unmapped_legacy_proxy_amount IS NULL OR unmapped_legacy_proxy_amount>=0)
      AND (incremental_acquisition_cost_beyond_m1_14 IS NULL OR incremental_acquisition_cost_beyond_m1_14>=0)
      AND (enhanced_total_acquisition_cost_if_booked IS NULL OR enhanced_total_acquisition_cost_if_booked>=0)),
    CONSTRAINT ck_acq_cost_rate CHECK(accepted_m1_14_acquisition_cost_rate BETWEEN 0 AND 1),
    CONSTRAINT ck_acq_cost_evidence CHECK(
      attribution_evidence_status IN('COMPLETE','PARTIAL','BLOCKED')
      AND cost_evidence_status IN('COMPLETE','PARTIAL','BLOCKED')
      AND overlap_evidence_status IN('COMPLETE','PARTIAL','BLOCKED')
      AND acquisition_contract_evidence_status IN('COMPLETE','PARTIAL','BLOCKED')),
    CONSTRAINT ck_acq_cost_blocked CHECK(
      acquisition_contract_evidence_status<>'BLOCKED'
      OR (identified_legacy_overlap_amount IS NULL AND unmapped_legacy_proxy_amount IS NULL
          AND incremental_acquisition_cost_beyond_m1_14 IS NULL
          AND enhanced_total_acquisition_cost_if_booked IS NULL)),
    CONSTRAINT ck_acq_cost_run CHECK(created_by_run_id=module1_run_id),
    CONSTRAINT fk_acq_cost_snapshot_application FOREIGN KEY(merchant_application_id) REFERENCES msbf_m1.merchant_application(merchant_application_id) ON DELETE CASCADE,
    CONSTRAINT fk_acq_cost_snapshot_population FOREIGN KEY(population_id) REFERENCES msbf_m1.population_registry(population_id) ON DELETE RESTRICT,
    CONSTRAINT fk_acq_cost_snapshot_merchant FOREIGN KEY(merchant_id) REFERENCES msbf_m1.merchant_master(merchant_id) ON DELETE RESTRICT,
    CONSTRAINT fk_acq_cost_snapshot_channel FOREIGN KEY(accepted_partner_channel_id) REFERENCES msbf_m1.partner_channel(partner_channel_id) ON DELETE RESTRICT
);

/* ---------------------------------------------------------------------------
4. Companion contract registry, latest contract, and immutable archive
--------------------------------------------------------------------------- */
CREATE TABLE IF NOT EXISTS msbf_ctl.m1_16_acquisition_contract_registry(
    contract_code text NOT NULL,
    contract_version integer NOT NULL,
    module1_run_id bigint NOT NULL,
    schema_version text NOT NULL,
    scenario_set_id bigint NOT NULL,
    methodology_version text NOT NULL,
    source_m1_15_contract_code text NOT NULL,
    source_m1_15_contract_version integer NOT NULL,
    source_m1_15_schema_version text NOT NULL,
    source_m1_15_combined_hash text NOT NULL,
    source_m1_14_combined_hash text NOT NULL,
    policy_configuration_hash text NOT NULL,
    contract_status text NOT NULL,
    source_profile_row_count integer NOT NULL,
    campaign_row_count integer NOT NULL,
    funnel_row_count integer NOT NULL,
    cost_ledger_row_count integer NOT NULL,
    touchpoint_row_count integer NOT NULL,
    attribution_row_count integer NOT NULL,
    cost_snapshot_row_count integer NOT NULL,
    component_row_count integer NOT NULL,
    latest_row_count integer NOT NULL,
    archive_row_count integer NOT NULL,
    integrated_view_row_count integer NOT NULL,
    source_profile_set_hash text NOT NULL,
    campaign_set_hash text NOT NULL,
    funnel_set_hash text NOT NULL,
    cost_ledger_set_hash text NOT NULL,
    touchpoint_set_hash text NOT NULL,
    attribution_set_hash text NOT NULL,
    cost_snapshot_set_hash text NOT NULL,
    component_set_hash text NOT NULL,
    latest_set_hash text NOT NULL,
    archive_set_hash text NOT NULL,
    contract_set_hash text NOT NULL,
    combined_set_hash text NOT NULL,
    contract_row_hash text NOT NULL,
    generated_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    validated_at timestamptz,
    accepted_at timestamptz,
    created_by_run_id bigint NOT NULL,
    CONSTRAINT pk_m1_16_contract_registry PRIMARY KEY(contract_code,contract_version,module1_run_id),
    CONSTRAINT ck_m1_16_contract_status CHECK(contract_status IN('GENERATED','VALIDATED','ACCEPTED','RETIRED')),
    CONSTRAINT ck_m1_16_contract_counts CHECK(
      source_profile_row_count>=0 AND campaign_row_count>=0 AND funnel_row_count>=0
      AND cost_ledger_row_count>=0 AND touchpoint_row_count>=0 AND attribution_row_count>=0
      AND cost_snapshot_row_count>=0 AND component_row_count>=0 AND latest_row_count>=0
      AND archive_row_count>=0 AND integrated_view_row_count>=0),
    CONSTRAINT ck_m1_16_contract_run CHECK(created_by_run_id=module1_run_id),
    CONSTRAINT fk_m1_16_contract_run FOREIGN KEY(module1_run_id) REFERENCES msbf_ctl.run_registry(run_id) ON DELETE CASCADE,
    CONSTRAINT fk_m1_16_contract_scenario_set FOREIGN KEY(scenario_set_id) REFERENCES msbf_ctl.scenario_set(scenario_set_id) ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS msbf_m1.application_acquisition_contract_latest(
    module1_run_id bigint NOT NULL,
    merchant_application_id text NOT NULL,
    population_id text NOT NULL,
    merchant_id text NOT NULL,
    as_of_date date NOT NULL,
    accepted_partner_channel_id text NOT NULL,
    accepted_channel_type text NOT NULL,
    accepted_application_channel text NOT NULL,
    primary_source_code text NOT NULL,
    primary_campaign_id text NOT NULL,
    attribution_method_code text NOT NULL,
    attribution_method_version integer NOT NULL,
    attribution_confidence_score numeric(9,6) NOT NULL,
    attribution_confidence_tier text NOT NULL,
    touchpoint_count smallint NOT NULL,
    assisted_touch_count smallint NOT NULL,
    attribution_evidence_status text NOT NULL,
    direct_attributable_incurred_cost_amount numeric(18,2) NOT NULL,
    internally_allocated_acquisition_cost_amount numeric(18,2) NOT NULL,
    total_incurred_pre_application_cost_amount numeric(18,2) NOT NULL,
    detailed_conditional_partner_broker_cost_amount numeric(18,2) NOT NULL,
    detailed_total_acquisition_cost_if_booked numeric(18,2) NOT NULL,
    accepted_m1_14_acquisition_cost_rate numeric(12,8) NOT NULL,
    accepted_m1_14_acquisition_cost_amount numeric(18,2) NOT NULL,
    legacy_m1_14_cost_scope_code text NOT NULL,
    identified_legacy_overlap_amount numeric(18,2),
    unmapped_legacy_proxy_amount numeric(18,2),
    incremental_acquisition_cost_beyond_m1_14 numeric(18,2),
    enhanced_total_acquisition_cost_if_booked numeric(18,2),
    cost_evidence_status text NOT NULL,
    overlap_evidence_status text NOT NULL,
    acquisition_contract_evidence_status text NOT NULL,
    fallback_path_code text NOT NULL,
    primary_reason_code text NOT NULL,
    secondary_reason_codes text[] NOT NULL DEFAULT '{}'::text[],
    attribution_snapshot_hash text NOT NULL,
    cost_snapshot_hash text NOT NULL,
    m1_14_baseline_row_hash text NOT NULL,
    m1_14_stress_row_hash text NOT NULL,
    m1_15_baseline_contract_row_hash text NOT NULL,
    m1_15_stress_contract_row_hash text NOT NULL,
    source_payload jsonb NOT NULL,
    lineage_payload jsonb NOT NULL,
    contract_code text NOT NULL,
    contract_version integer NOT NULL,
    schema_version text NOT NULL,
    contract_row_hash text NOT NULL,
    created_by_run_id bigint NOT NULL,
    created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT pk_m1_16_latest PRIMARY KEY(module1_run_id,merchant_application_id),
    CONSTRAINT ck_m1_16_latest_evidence CHECK(acquisition_contract_evidence_status IN('COMPLETE','PARTIAL','BLOCKED')),
    CONSTRAINT ck_m1_16_latest_confidence CHECK(attribution_confidence_score BETWEEN 0 AND 1),
    CONSTRAINT ck_m1_16_latest_run CHECK(created_by_run_id=module1_run_id),
    CONSTRAINT fk_m1_16_latest_run FOREIGN KEY(module1_run_id) REFERENCES msbf_ctl.run_registry(run_id) ON DELETE CASCADE,
    CONSTRAINT fk_m1_16_latest_application FOREIGN KEY(merchant_application_id) REFERENCES msbf_m1.merchant_application(merchant_application_id) ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS msbf_m1.application_acquisition_contract_archive(
    archive_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    module1_run_id bigint NOT NULL,
    merchant_application_id text NOT NULL,
    contract_code text NOT NULL,
    contract_version integer NOT NULL,
    schema_version text NOT NULL,
    contract_row_hash text NOT NULL,
    contract_payload jsonb NOT NULL,
    archived_by_run_id bigint NOT NULL,
    archived_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT uq_m1_16_archive UNIQUE(module1_run_id,contract_code,contract_version,merchant_application_id),
    CONSTRAINT ck_m1_16_archive_run CHECK(archived_by_run_id=module1_run_id),
    CONSTRAINT fk_m1_16_archive_run FOREIGN KEY(module1_run_id) REFERENCES msbf_ctl.run_registry(run_id) ON DELETE CASCADE,
    CONSTRAINT fk_m1_16_archive_application FOREIGN KEY(merchant_application_id) REFERENCES msbf_m1.merchant_application(merchant_application_id) ON DELETE RESTRICT
);

CREATE OR REPLACE FUNCTION msbf_m1.m1_16_reject_archive_mutation()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  RAISE EXCEPTION 'M1.16 acquisition archive is immutable: % is not permitted on %.%.',
    TG_OP,TG_TABLE_SCHEMA,TG_TABLE_NAME;
END;
$$;
DROP TRIGGER IF EXISTS trg_m1_16_archive_immutable ON msbf_m1.application_acquisition_contract_archive;
CREATE TRIGGER trg_m1_16_archive_immutable
BEFORE UPDATE OR DELETE ON msbf_m1.application_acquisition_contract_archive
FOR EACH ROW EXECUTE FUNCTION msbf_m1.m1_16_reject_archive_mutation();

/* ---------------------------------------------------------------------------
5. Indexes
--------------------------------------------------------------------------- */
CREATE INDEX IF NOT EXISTS ix_acq_source_channel ON msbf_m1.acquisition_source_profile(module1_run_id,accepted_partner_channel_id,acquisition_source_code);
CREATE INDEX IF NOT EXISTS ix_acq_campaign_source ON msbf_m1.acquisition_marketing_campaign(module1_run_id,acquisition_source_code,acquisition_campaign_id);
CREATE INDEX IF NOT EXISTS ix_acq_funnel_stage ON msbf_m1.acquisition_campaign_funnel_stage(module1_run_id,stage_order,acquisition_campaign_id);
CREATE INDEX IF NOT EXISTS ix_acq_ledger_campaign ON msbf_m1.acquisition_cost_ledger(module1_run_id,acquisition_campaign_id,cost_timing_code);
CREATE INDEX IF NOT EXISTS ix_acq_touch_campaign ON msbf_m1.application_acquisition_touchpoint(module1_run_id,acquisition_campaign_id,merchant_application_id);
CREATE INDEX IF NOT EXISTS ix_acq_attribution_campaign ON msbf_m1.application_acquisition_attribution_snapshot(module1_run_id,primary_campaign_id,merchant_application_id);
CREATE INDEX IF NOT EXISTS ix_acq_cost_channel ON msbf_m1.application_acquisition_cost_snapshot(module1_run_id,accepted_partner_channel_id,acquisition_contract_evidence_status);
CREATE INDEX IF NOT EXISTS ix_acq_component_code ON msbf_m1.application_acquisition_cost_component_value(module1_run_id,cost_component_code,merchant_application_id);
CREATE INDEX IF NOT EXISTS ix_m1_16_latest_channel ON msbf_m1.application_acquisition_contract_latest(module1_run_id,accepted_partner_channel_id,merchant_application_id);
CREATE INDEX IF NOT EXISTS ix_m1_16_archive_contract ON msbf_m1.application_acquisition_contract_archive(module1_run_id,contract_version,merchant_application_id);

/* ---------------------------------------------------------------------------
6. Hashing and fail-closed readiness helpers
--------------------------------------------------------------------------- */
CREATE OR REPLACE FUNCTION msbf_m1.m1_16_hash_jsonb(p_payload jsonb)
RETURNS text LANGUAGE sql IMMUTABLE STRICT AS $$ SELECT md5(p_payload::text); $$;

CREATE OR REPLACE FUNCTION msbf_m1.m1_16_assert_upstream_hashes(p_run_id bigint)
RETURNS void LANGUAGE plpgsql AS $$
DECLARE
  v_m114 text; v_m115 text; v_latest text; v_archive text; v_compare text; v_contract text;
BEGIN
  SELECT metric_value_text INTO STRICT v_m114 FROM msbf_ctl.run_evidence
   WHERE run_id=p_run_id AND evidence_code='M1_14_COMBINED_SET_HASH' AND segment_key='PORTFOLIO';
  SELECT combined_set_hash,latest_set_hash,archive_set_hash,comparison_set_hash,contract_set_hash
    INTO STRICT v_m115,v_latest,v_archive,v_compare,v_contract
  FROM msbf_ctl.m1_15_consumption_contract_registry
  WHERE module1_run_id=p_run_id AND contract_code='M1_APPLICATION_CONSUMPTION' AND contract_version=1 AND contract_status='ACCEPTED';
  IF v_m114<>'3a47f59b56fa158c18c111caa1c64909'
     OR v_m115<>'fcd2704e17ec0d2e73191ea36061d74b'
     OR v_latest<>'95b54308f082b0fc57be2dd370e94435'
     OR v_archive<>'1da2f7145cab091a274303064df9c680'
     OR v_compare<>'0f03497fbcff3b21138258aa5e3a0667'
     OR v_contract<>'52b682a64efa3836e9383e3c8f5d6ca6' THEN
    RAISE EXCEPTION 'M1.16 upstream hash contract failed: M1.14 %, M1.15 %, latest %, archive %, comparison %, contract %.',
      v_m114,v_m115,v_latest,v_archive,v_compare,v_contract;
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION msbf_m1.m1_16_assert_configuration(p_run_id bigint)
RETURNS void LANGUAGE plpgsql AS $$
DECLARE
  v_policy jsonb; v_param_hash text; v_apps bigint; v_latest bigint; v_compare bigint;
  v_m114 bigint; v_invariance bigint; v_scenarios bigint; v_baseline bigint; v_stress bigint;
BEGIN
  SELECT pp.profile_payload,ps.parameter_set_hash
    INTO STRICT v_policy,v_param_hash
  FROM msbf_ctl.policy_profile pp
  JOIN msbf_ctl.parameter_set ps ON ps.parameter_set_id=pp.parameter_set_id
  WHERE pp.profile_code='M1_16_ACQUISITION_FOUNDATIONS' AND pp.profile_version=1 AND pp.status='APPROVED'
    AND ps.parameter_set_code='M1_16_ACQUISITION_FOUNDATIONS' AND ps.parameter_set_version=1 AND ps.status='APPROVED';

  SELECT count(*) INTO v_apps FROM msbf_m1.merchant_application WHERE created_by_run_id=p_run_id;
  SELECT count(*) INTO v_latest FROM msbf_m1.application_module1_latest WHERE module1_run_id=p_run_id;
  SELECT count(*) INTO v_compare FROM msbf_m1.application_module1_scenario_comparison WHERE module1_run_id=p_run_id;
  SELECT count(*) INTO v_m114 FROM msbf_m1.application_unit_economics_snapshot WHERE module1_run_id=p_run_id;
  SELECT count(DISTINCT l.scenario_id),
         count(DISTINCT l.scenario_id) FILTER(WHERE l.scenario_code='BASELINE'),
         count(DISTINCT l.scenario_id) FILTER(WHERE l.scenario_code='RECESSION_ENERGY')
    INTO v_scenarios,v_baseline,v_stress
  FROM msbf_m1.application_module1_latest l WHERE l.module1_run_id=p_run_id;
  SELECT count(*) INTO v_invariance
  FROM msbf_m1.application_unit_economics_snapshot b
  JOIN msbf_ctl.scenario_registry br ON br.scenario_id=b.scenario_id AND br.scenario_code='BASELINE'
  JOIN msbf_m1.application_unit_economics_snapshot s
    ON s.module1_run_id=b.module1_run_id AND s.merchant_application_id=b.merchant_application_id
  JOIN msbf_ctl.scenario_registry sr ON sr.scenario_id=s.scenario_id AND sr.scenario_code='RECESSION_ENERGY'
  WHERE b.module1_run_id=p_run_id
    AND (b.partner_acquisition_cost_rate IS DISTINCT FROM s.partner_acquisition_cost_rate
      OR b.partner_acquisition_cost_amount IS DISTINCT FROM s.partner_acquisition_cost_amount);

  IF v_policy->>'methodology_version'<>'M1_16_METHOD_V1'
     OR v_policy->>'contract_code'<>'M1_ACQUISITION_CONSUMPTION'
     OR v_policy->>'schema_version'<>'M1_ACQUISITION_SCHEMA_V1'
     OR v_param_hash IS NULL
     OR v_apps<>750 OR v_latest<>1500
     OR v_compare<>750 OR v_m114<>1500
     OR v_scenarios<>2 OR v_baseline<>1 OR v_stress<>1 OR v_invariance<>0 THEN
    RAISE EXCEPTION 'M1.16 configuration failed: parameter hash %, apps %, latest %, comparison %, M1.14 %, scenarios %, baseline %, stress %, acquisition divergence %.',
      v_param_hash,v_apps,v_latest,v_compare,v_m114,v_scenarios,v_baseline,v_stress,v_invariance;
  END IF;
  PERFORM msbf_m1.m1_16_assert_upstream_hashes(p_run_id);
END;
$$;

CREATE OR REPLACE FUNCTION msbf_m1.m1_16_assert_prerequisite_status(p_run_id bigint)
RETURNS void LANGUAGE plpgsql AS $$
DECLARE v_status text;
BEGIN
  PERFORM msbf_m1.m1_16_assert_configuration(p_run_id);
  SELECT run_status INTO STRICT v_status FROM msbf_ctl.run_registry WHERE run_id=p_run_id;
  IF v_status<>'M1_15_ACCEPTED' THEN
    RAISE EXCEPTION 'M1.16 requires M1_15_ACCEPTED; observed %.',v_status;
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION msbf_m1.m1_16_assert_generation_ready(p_run_id bigint)
RETURNS void LANGUAGE plpgsql AS $$
DECLARE
  v_business bigint; v_evidence bigint; v_gate bigint; v_blocking bigint;
BEGIN
  PERFORM msbf_m1.m1_16_assert_prerequisite_status(p_run_id);
  SELECT
    (SELECT count(*) FROM msbf_m1.acquisition_source_profile WHERE module1_run_id=p_run_id)
   +(SELECT count(*) FROM msbf_m1.acquisition_marketing_campaign WHERE module1_run_id=p_run_id)
   +(SELECT count(*) FROM msbf_m1.acquisition_campaign_funnel_stage WHERE module1_run_id=p_run_id)
   +(SELECT count(*) FROM msbf_m1.acquisition_cost_ledger WHERE module1_run_id=p_run_id)
   +(SELECT count(*) FROM msbf_m1.application_acquisition_touchpoint WHERE module1_run_id=p_run_id)
   +(SELECT count(*) FROM msbf_m1.application_acquisition_attribution_snapshot WHERE module1_run_id=p_run_id)
   +(SELECT count(*) FROM msbf_m1.application_acquisition_cost_component_value WHERE module1_run_id=p_run_id)
   +(SELECT count(*) FROM msbf_m1.application_acquisition_cost_snapshot WHERE module1_run_id=p_run_id)
   +(SELECT count(*) FROM msbf_m1.application_acquisition_contract_latest WHERE module1_run_id=p_run_id)
   +(SELECT count(*) FROM msbf_m1.application_acquisition_contract_archive WHERE module1_run_id=p_run_id)
   +(SELECT count(*) FROM msbf_ctl.m1_16_acquisition_contract_registry WHERE module1_run_id=p_run_id)
    INTO v_business;
  SELECT count(*) INTO v_evidence FROM msbf_ctl.run_evidence WHERE run_id=p_run_id AND evidence_code LIKE 'M1_16_%';
  SELECT count(*) INTO v_gate FROM msbf_ctl.acceptance_gate_result WHERE run_id=p_run_id AND gate_id='M1_16_ACQUISITION_MARKETING_COST_FOUNDATIONS';
  SELECT count(*) INTO v_blocking FROM msbf_ctl.profile_resolution_error WHERE run_id=p_run_id AND severity='BLOCKING';
  IF v_business<>0 OR v_evidence<>0 OR v_gate<>0 OR v_blocking<>0 THEN
    RAISE EXCEPTION 'M1.16 pristine-target readiness failed: business %, evidence %, gate %, blocking %.',v_business,v_evidence,v_gate,v_blocking;
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION msbf_m1.m1_16_assert_no_prohibited_output(p_output_code text)
RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  IF p_output_code IN('APPROVAL','DECLINE','COUNTEROFFER','PRICING','FUNDED_CAC','REALIZED_LTV','MARKETING_OPTIMIZATION') THEN
    RAISE EXCEPTION 'M1.16 prohibited output requested: %.',p_output_code;
  END IF;
END;
$$;


CREATE OR REPLACE FUNCTION msbf_m1.m1_16_assert_persisted_integrity(p_run_id bigint)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    v_run_status text;
    v_contract_status text;
    v_expected_contract_status text;
    v_count bigint;
    v_hash text;
BEGIN
    SELECT run_status INTO STRICT v_run_status
    FROM msbf_ctl.run_registry WHERE run_id=p_run_id;

    SELECT contract_status INTO STRICT v_contract_status
    FROM msbf_ctl.m1_16_acquisition_contract_registry
    WHERE module1_run_id=p_run_id
      AND contract_code='M1_ACQUISITION_CONSUMPTION'
      AND contract_version=1;

    v_expected_contract_status := CASE v_run_status
      WHEN 'M1_16_GENERATED' THEN 'GENERATED'
      WHEN 'M1_16_VALIDATED' THEN 'VALIDATED'
      WHEN 'M1_16_ACCEPTED' THEN 'ACCEPTED'
      ELSE NULL END;
    IF v_expected_contract_status IS NULL OR v_contract_status<>v_expected_contract_status THEN
      RAISE EXCEPTION 'M1.16 run/contract lifecycle mismatch: run %, contract %.',v_run_status,v_contract_status;
    END IF;

    SELECT
      (SELECT count(*) FROM msbf_m1.acquisition_source_profile WHERE module1_run_id=p_run_id)
     +(SELECT count(*) FROM msbf_m1.acquisition_marketing_campaign WHERE module1_run_id=p_run_id)
     +(SELECT count(*) FROM msbf_m1.acquisition_campaign_funnel_stage WHERE module1_run_id=p_run_id)
     +(SELECT count(*) FROM msbf_m1.acquisition_cost_ledger WHERE module1_run_id=p_run_id)
     +(SELECT count(*) FROM msbf_m1.application_acquisition_touchpoint WHERE module1_run_id=p_run_id)
     +(SELECT count(*) FROM msbf_m1.application_acquisition_attribution_snapshot WHERE module1_run_id=p_run_id)
     +(SELECT count(*) FROM msbf_m1.application_acquisition_cost_snapshot WHERE module1_run_id=p_run_id)
     +(SELECT count(*) FROM msbf_m1.application_acquisition_cost_component_value WHERE module1_run_id=p_run_id)
     +(SELECT count(*) FROM msbf_m1.application_acquisition_contract_latest WHERE module1_run_id=p_run_id)
     +(SELECT count(*) FROM msbf_m1.application_acquisition_contract_archive WHERE module1_run_id=p_run_id)
     +(SELECT count(*) FROM msbf_ctl.m1_16_acquisition_contract_registry WHERE module1_run_id=p_run_id)
    INTO v_count;
    IF v_count<>13274 THEN
      RAISE EXCEPTION 'M1.16 canonical entity count failed: observed %, expected 13274.',v_count;
    END IF;

    SELECT count(*) INTO v_count
    FROM msbf_m1.acquisition_source_profile s
    WHERE s.module1_run_id=p_run_id
      AND (NOT s.approved_source_flag OR s.governance_status<>'APPROVED'
       OR s.source_classification<>s.normalized_source_family
       OR NOT (s.accepted_partner_channel_id=ANY(ARRAY[
          'CH_PROCESSOR_DIRECT','CH_BANK_RELATIONSHIP','CH_DIGITAL_DIRECT',
          'CH_STRATEGIC_PARTNER','CH_BROKER_NETWORK'])));
    IF v_count<>0 THEN RAISE EXCEPTION 'M1.16 source-governance violations: %.',v_count; END IF;

    SELECT count(*) INTO v_count
    FROM msbf_m1.acquisition_marketing_campaign c
    JOIN msbf_m1.acquisition_source_profile s
      ON s.module1_run_id=c.module1_run_id AND s.acquisition_source_code=c.acquisition_source_code
    WHERE c.module1_run_id=p_run_id
      AND (c.approval_status<>'APPROVED' OR c.campaign_status<>'ACTIVE'
       OR c.accepted_partner_channel_id<>s.accepted_partner_channel_id
       OR c.effective_end_date<c.effective_start_date);
    IF v_count<>0 THEN RAISE EXCEPTION 'M1.16 campaign-governance violations: %.',v_count; END IF;

    WITH ordered AS(
      SELECT f.module1_run_id,f.acquisition_campaign_id,f.stage_code,f.stage_order,
             f.stage_count,lag(f.stage_count) OVER(PARTITION BY f.acquisition_campaign_id ORDER BY f.stage_order) AS prior_count
      FROM msbf_m1.acquisition_campaign_funnel_stage f WHERE f.module1_run_id=p_run_id
    )
    SELECT count(*) INTO v_count FROM ordered
    WHERE stage_count<0 OR (prior_count IS NOT NULL AND stage_count>prior_count);
    IF v_count<>0 THEN RAISE EXCEPTION 'M1.16 funnel monotonicity violations: %.',v_count; END IF;

    SELECT count(*) INTO v_count
    FROM msbf_m1.acquisition_cost_ledger l
    JOIN msbf_m1.acquisition_source_profile s
      ON s.module1_run_id=l.module1_run_id AND s.acquisition_source_code=l.acquisition_source_code
    WHERE l.module1_run_id=p_run_id
      AND (l.gross_cost_amount<0 OR l.quantity<0
       OR NOT (l.cost_basis_code=ANY(s.permitted_cost_basis_codes))
       OR NOT (l.cost_timing_code=ANY(s.permitted_cost_timing_codes)));
    IF v_count<>0 THEN RAISE EXCEPTION 'M1.16 ledger/basis/timing violations: %.',v_count; END IF;

    SELECT count(*) INTO v_count
    FROM msbf_m1.application_acquisition_touchpoint t
    JOIN msbf_m1.merchant_application a ON a.merchant_application_id=t.merchant_application_id
    WHERE t.module1_run_id=p_run_id
      AND (t.touchpoint_sequence NOT BETWEEN 1 AND 3
       OR t.touchpoint_timestamp>a.application_date::timestamp+interval '23 hours 59 minutes 59 seconds');
    IF v_count<>0 THEN RAISE EXCEPTION 'M1.16 touchpoint boundary violations: %.',v_count; END IF;

    SELECT count(*) INTO v_count
    FROM (
      SELECT merchant_application_id,
             count(*) AS touch_count,
             count(*) FILTER(WHERE first_touch_flag) AS first_count,
             count(*) FILTER(WHERE last_touch_flag) AS last_count,
             count(*) FILTER(WHERE primary_attribution_flag) AS primary_count,
             sum(attribution_weight) AS total_weight
      FROM msbf_m1.application_acquisition_touchpoint
      WHERE module1_run_id=p_run_id GROUP BY merchant_application_id
    ) x
    WHERE touch_count NOT BETWEEN 1 AND 3 OR first_count<>1 OR last_count<>1
       OR primary_count<>1 OR total_weight<>1.000000;
    IF v_count<>0 THEN RAISE EXCEPTION 'M1.16 touchpoint attribution violations: %.',v_count; END IF;

    SELECT count(*) INTO v_count
    FROM msbf_m1.application_acquisition_attribution_snapshot a
    JOIN msbf_m1.application_acquisition_touchpoint t
      ON t.module1_run_id=a.module1_run_id
     AND t.merchant_application_id=a.merchant_application_id
     AND t.primary_attribution_flag
    WHERE a.module1_run_id=p_run_id
      AND (a.primary_source_code<>t.acquisition_source_code
       OR a.primary_campaign_id<>t.acquisition_campaign_id
       OR a.touchpoint_count<>(SELECT count(*) FROM msbf_m1.application_acquisition_touchpoint z
                              WHERE z.module1_run_id=a.module1_run_id
                                AND z.merchant_application_id=a.merchant_application_id));
    IF v_count<>0 THEN RAISE EXCEPTION 'M1.16 attribution-snapshot violations: %.',v_count; END IF;

    SELECT count(*) INTO v_count
    FROM msbf_m1.application_acquisition_cost_snapshot c
    WHERE c.module1_run_id=p_run_id
      AND (
        c.direct_attributable_incurred_cost_amount IS DISTINCT FROM
          (c.paid_media_cost_amount+c.direct_mail_event_outbound_cost_amount+
           c.purchased_lead_cost_amount+c.acquisition_incentive_cost_amount)
        OR c.internally_allocated_acquisition_cost_amount IS DISTINCT FROM
          (c.internal_sales_rm_cost_amount+c.agency_creative_tech_cost_amount+c.campaign_overhead_cost_amount)
        OR c.total_incurred_pre_application_cost_amount IS DISTINCT FROM
          (c.direct_attributable_incurred_cost_amount+c.internally_allocated_acquisition_cost_amount)
        OR c.detailed_total_acquisition_cost_if_booked IS DISTINCT FROM
          (c.total_incurred_pre_application_cost_amount+c.detailed_conditional_partner_broker_cost_amount)
        OR (c.acquisition_contract_evidence_status<>'BLOCKED' AND (
          c.unmapped_legacy_proxy_amount IS DISTINCT FROM c.accepted_m1_14_acquisition_cost_amount-c.identified_legacy_overlap_amount
          OR c.incremental_acquisition_cost_beyond_m1_14 IS DISTINCT FROM c.detailed_total_acquisition_cost_if_booked-c.identified_legacy_overlap_amount
          OR c.enhanced_total_acquisition_cost_if_booked IS DISTINCT FROM c.accepted_m1_14_acquisition_cost_amount+c.incremental_acquisition_cost_beyond_m1_14))
        OR (c.acquisition_contract_evidence_status='BLOCKED' AND num_nonnulls(
          c.identified_legacy_overlap_amount,c.unmapped_legacy_proxy_amount,
          c.incremental_acquisition_cost_beyond_m1_14,c.enhanced_total_acquisition_cost_if_booked)<>0)
      );
    IF v_count<>0 THEN RAISE EXCEPTION 'M1.16 acquisition-cost identity violations: %.',v_count; END IF;

    SELECT count(*) INTO v_count
    FROM msbf_m1.application_acquisition_cost_component_value v
    WHERE v.module1_run_id=p_run_id
      AND v.row_hash IS DISTINCT FROM msbf_m1.m1_16_hash_jsonb(to_jsonb(v)-'row_hash'-'created_at');
    IF v_count<>0 THEN RAISE EXCEPTION 'M1.16 component row-hash violations: %.',v_count; END IF;

    SELECT count(*) INTO v_count
    FROM msbf_m1.application_acquisition_contract_latest l
    WHERE l.module1_run_id=p_run_id
      AND l.contract_row_hash IS DISTINCT FROM msbf_m1.m1_16_hash_jsonb(to_jsonb(l)-'contract_row_hash'-'created_at');
    IF v_count<>0 THEN RAISE EXCEPTION 'M1.16 latest row-hash violations: %.',v_count; END IF;

    SELECT count(*) INTO v_count
    FROM msbf_m1.application_acquisition_contract_archive a
    JOIN msbf_m1.application_acquisition_contract_latest l
      ON l.module1_run_id=a.module1_run_id AND l.merchant_application_id=a.merchant_application_id
     AND l.contract_code=a.contract_code AND l.contract_version=a.contract_version
    WHERE a.module1_run_id=p_run_id
      AND (a.contract_row_hash<>l.contract_row_hash OR a.contract_payload IS DISTINCT FROM to_jsonb(l)-'created_at');
    IF v_count<>0 THEN RAISE EXCEPTION 'M1.16 latest/archive reproduction violations: %.',v_count; END IF;

    SELECT count(*) INTO v_count
    FROM (
      SELECT merchant_application_id,count(*) AS scenario_rows,
             count(DISTINCT coalesce(primary_source_code,'<NULL>')) AS sources,
             count(DISTINCT coalesce(enhanced_total_acquisition_cost_if_booked::text,'<NULL>')) AS costs
      FROM msbf_m1.v_m1_16_module1_integrated_consumption
      WHERE module1_run_id=p_run_id GROUP BY merchant_application_id
    ) x
    WHERE scenario_rows<>2 OR sources<>1 OR costs<>1;
    IF v_count<>0 THEN RAISE EXCEPTION 'M1.16 integrated-view scenario-invariance violations: %.',v_count; END IF;

    SELECT md5(string_agg('LATEST|'||merchant_application_id||'|'||contract_row_hash,'||' ORDER BY merchant_application_id))
      INTO v_hash
    FROM msbf_m1.application_acquisition_contract_latest WHERE module1_run_id=p_run_id;
    IF v_hash<>(SELECT latest_set_hash FROM msbf_ctl.m1_16_acquisition_contract_registry
               WHERE module1_run_id=p_run_id AND contract_code='M1_ACQUISITION_CONSUMPTION' AND contract_version=1) THEN
      RAISE EXCEPTION 'M1.16 latest set hash failed.';
    END IF;

    PERFORM msbf_m1.m1_16_assert_upstream_hashes(p_run_id);
END;
$$;

/* ---------------------------------------------------------------------------
7. Explicitly projected consumption views
--------------------------------------------------------------------------- */
CREATE OR REPLACE VIEW msbf_m1.v_m1_16_acquisition_latest AS
SELECT
  l.module1_run_id,l.merchant_application_id,l.population_id,l.merchant_id,l.as_of_date,
  l.accepted_partner_channel_id,l.accepted_channel_type,l.accepted_application_channel,
  l.primary_source_code,l.primary_campaign_id,l.attribution_method_code,
  l.attribution_method_version,l.attribution_confidence_score,l.attribution_confidence_tier,
  l.touchpoint_count,l.assisted_touch_count,l.attribution_evidence_status,
  l.direct_attributable_incurred_cost_amount,l.internally_allocated_acquisition_cost_amount,
  l.total_incurred_pre_application_cost_amount,l.detailed_conditional_partner_broker_cost_amount,
  l.detailed_total_acquisition_cost_if_booked,l.accepted_m1_14_acquisition_cost_rate,
  l.accepted_m1_14_acquisition_cost_amount,l.legacy_m1_14_cost_scope_code,
  l.identified_legacy_overlap_amount,l.unmapped_legacy_proxy_amount,
  l.incremental_acquisition_cost_beyond_m1_14,l.enhanced_total_acquisition_cost_if_booked,
  l.cost_evidence_status,l.overlap_evidence_status,l.acquisition_contract_evidence_status,
  l.fallback_path_code,l.primary_reason_code,l.secondary_reason_codes,
  l.attribution_snapshot_hash,l.cost_snapshot_hash,l.m1_14_baseline_row_hash,
  l.m1_14_stress_row_hash,l.m1_15_baseline_contract_row_hash,l.m1_15_stress_contract_row_hash,
  l.contract_code,l.contract_version,l.schema_version,l.contract_row_hash
FROM msbf_m1.application_acquisition_contract_latest l;

CREATE OR REPLACE VIEW msbf_m1.v_m1_16_acquisition_lineage AS
SELECT
  c.contract_code,c.contract_version,c.schema_version,c.methodology_version,
  c.module1_run_id,r.run_code,r.run_version,r.run_status,r.population_id,r.as_of_date,
  ss.scenario_set_code,ss.scenario_set_version,c.source_m1_15_contract_code,
  c.source_m1_15_contract_version,c.source_m1_15_schema_version,c.source_m1_15_combined_hash,
  c.source_m1_14_combined_hash,c.policy_configuration_hash,c.contract_status,
  c.source_profile_row_count,c.campaign_row_count,c.funnel_row_count,c.cost_ledger_row_count,
  c.touchpoint_row_count,c.attribution_row_count,c.cost_snapshot_row_count,c.component_row_count,
  c.latest_row_count,c.archive_row_count,c.integrated_view_row_count,
  c.source_profile_set_hash,c.campaign_set_hash,
  c.funnel_set_hash,c.cost_ledger_set_hash,c.touchpoint_set_hash,c.attribution_set_hash,
  c.cost_snapshot_set_hash,c.component_set_hash,c.latest_set_hash,c.archive_set_hash,
  c.contract_set_hash,c.combined_set_hash,c.contract_row_hash,c.generated_at,c.validated_at,c.accepted_at
FROM msbf_ctl.m1_16_acquisition_contract_registry c
JOIN msbf_ctl.run_registry r ON r.run_id=c.module1_run_id
JOIN msbf_ctl.scenario_set ss ON ss.scenario_set_id=c.scenario_set_id;

CREATE OR REPLACE VIEW msbf_m1.v_m1_16_campaign_funnel AS
SELECT
  c.module1_run_id,c.acquisition_campaign_id,c.acquisition_source_code,c.accepted_partner_channel_id,
  c.campaign_family_code,c.campaign_type,c.campaign_name_synthetic,c.campaign_status,c.approval_status,
  c.effective_start_date,c.effective_end_date,c.budget_amount,c.spend_amount,c.campaign_evidence_status,
  f.stage_code,f.stage_order,f.stage_count,f.conversion_rate_from_prior,f.evidence_status AS funnel_evidence_status
FROM msbf_m1.acquisition_marketing_campaign c
JOIN msbf_m1.acquisition_campaign_funnel_stage f
  ON f.module1_run_id=c.module1_run_id AND f.acquisition_campaign_id=c.acquisition_campaign_id;

CREATE OR REPLACE VIEW msbf_m1.v_m1_16_power_bi_acquisition AS
SELECT
  l.module1_run_id,l.merchant_application_id,l.population_id,l.merchant_id,l.as_of_date,
  l.accepted_partner_channel_id,l.accepted_channel_type,l.accepted_application_channel,
  l.primary_source_code,l.primary_campaign_id,l.attribution_confidence_tier,
  l.touchpoint_count,l.assisted_touch_count,l.attribution_evidence_status,
  l.direct_attributable_incurred_cost_amount,l.internally_allocated_acquisition_cost_amount,
  l.total_incurred_pre_application_cost_amount,l.detailed_conditional_partner_broker_cost_amount,
  l.detailed_total_acquisition_cost_if_booked,l.accepted_m1_14_acquisition_cost_amount,
  l.identified_legacy_overlap_amount,l.unmapped_legacy_proxy_amount,
  l.incremental_acquisition_cost_beyond_m1_14,l.enhanced_total_acquisition_cost_if_booked,
  l.cost_evidence_status,l.overlap_evidence_status,l.acquisition_contract_evidence_status,
  l.fallback_path_code,l.primary_reason_code,l.contract_code,l.contract_version,l.schema_version,l.contract_row_hash
FROM msbf_m1.application_acquisition_contract_latest l;

CREATE OR REPLACE VIEW msbf_m1.v_m1_16_module1_integrated_consumption AS
SELECT
  m.module1_run_id,m.scenario_id,m.scenario_code,m.merchant_application_id,m.population_id,m.merchant_id,
  m.as_of_date,m.industry_code,m.merchant_size_tier,m.relationship_stage,
  m.partner_channel_id,m.channel_type,m.source_confidence_score,m.data_confidence_tier,
  m.verification_disposition,m.fraud_risk_tier,m.processor_continuity_status,
  m.avg_daily_eligible_sales_30d,m.average_available_balance_30d,m.capacity_tier,
  m.affordability_status,m.archetype_code,m.operating_resilience_score,m.resilience_tier,
  m.integrated_risk_score,m.synthetic_merchant_risk_proxy,m.integrated_risk_tier,
  m.path_weighted_ead_amount,m.lgd_input_rate,m.schedule_adjusted_comparative_expected_loss_amount,
  m.risk_adjusted_contribution_amount,m.annualized_risk_adjusted_return_rate,m.economic_tier,
  m.economic_status,m.hard_stop_recommended_flag,m.manual_review_recommended_flag,
  m.contract_evidence_status AS m1_15_contract_evidence_status,m.contract_row_hash AS m1_15_contract_row_hash,
  a.primary_source_code,a.primary_campaign_id,a.attribution_confidence_score,a.attribution_confidence_tier,
  a.touchpoint_count,a.assisted_touch_count,a.attribution_evidence_status,
  a.direct_attributable_incurred_cost_amount,a.internally_allocated_acquisition_cost_amount,
  a.total_incurred_pre_application_cost_amount,a.detailed_conditional_partner_broker_cost_amount,
  a.detailed_total_acquisition_cost_if_booked,a.accepted_m1_14_acquisition_cost_amount,
  a.identified_legacy_overlap_amount,a.unmapped_legacy_proxy_amount,
  a.incremental_acquisition_cost_beyond_m1_14,a.enhanced_total_acquisition_cost_if_booked,
  a.cost_evidence_status,a.overlap_evidence_status,a.acquisition_contract_evidence_status,
  a.contract_row_hash AS m1_16_contract_row_hash
FROM msbf_m1.application_module1_latest m
JOIN msbf_m1.application_acquisition_contract_latest a
  ON a.module1_run_id=m.module1_run_id AND a.merchant_application_id=m.merchant_application_id;

COMMIT;

SELECT
  'M1_16_SCHEMA_POLICY_CONTRACT_EXTENSION' AS checkpoint,
  to_regclass('msbf_m1.acquisition_source_profile') IS NOT NULL AS source_profile_exists,
  to_regclass('msbf_m1.acquisition_marketing_campaign') IS NOT NULL AS campaign_exists,
  to_regclass('msbf_m1.application_acquisition_contract_latest') IS NOT NULL AS latest_exists,
  to_regclass('msbf_m1.application_acquisition_contract_archive') IS NOT NULL AS archive_exists,
  to_regclass('msbf_ctl.m1_16_acquisition_contract_registry') IS NOT NULL AS registry_exists,
  (SELECT status FROM msbf_ctl.policy_profile WHERE profile_code='M1_16_ACQUISITION_FOUNDATIONS' AND profile_version=1) AS policy_status,
  (SELECT parameter_set_hash FROM msbf_ctl.parameter_set WHERE parameter_set_code='M1_16_ACQUISITION_FOUNDATIONS' AND parameter_set_version=1) AS policy_configuration_hash,
  '18'::integer AS expected_source_profiles,
  '20'::integer AS expected_campaigns,
  '13274'::integer AS expected_canonical_entities,
  'PASS'::text AS schema_policy_extension_status;
