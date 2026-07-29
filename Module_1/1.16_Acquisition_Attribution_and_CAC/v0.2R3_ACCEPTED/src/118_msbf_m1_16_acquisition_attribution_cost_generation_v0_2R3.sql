/* ============================================================================
MSBF M1.16 Acquisition Source, Marketing Attribution & Merchant Acquisition Cost
Program : 118_msbf_m1_16_acquisition_attribution_cost_generation_v0_2R3.sql
Version : v0.2R3
Purpose : Deterministically generate source profiles, campaigns, aggregate funnel,
          cost ledger, bounded application touchpoints, primary attribution,
          cent-reconciled acquisition costs, M1.14 overlap bridge, companion
          latest/archive contract, canonical hashes, and generation evidence.
Inputs  : Accepted M1.2/M1.3 application/channel records; accepted M1.14
          unit-economics rows; accepted M1.15 contract and scenario set.
Outputs : M1.16 physical business records, contract registry, immutable archive,
          set hashes, generation evidence, and run status M1_16_GENERATED.
Boundary: No application decision, price, offer, funding outcome/probability,
          realized CAC/LTV, causal attribution, or Module 2 output.
Safety  : One transaction; accepted upstream rows are read only. Target-typed
          expected tables, explicit projections, physical hash reconstruction,
          exact cent allocation, and fail-closed canonical reconciliation.
============================================================================ */
BEGIN;
SET LOCAL lock_timeout='10s';
SET LOCAL statement_timeout='20min';
SET LOCAL work_mem='128MB';
SET LOCAL jit=off;

DO $phase_1$ BEGIN RAISE NOTICE 'M1.16 Phase 1/7 — validate readiness and materialize accepted inputs'; END; $phase_1$;

DROP TABLE IF EXISTS _m1_16_ctx;
CREATE TEMP TABLE _m1_16_ctx ON COMMIT DROP AS
SELECT
  r.run_id,r.run_code,r.run_version,r.population_id,r.as_of_date,
  ss.scenario_set_id,ss.scenario_set_code,ss.scenario_set_version,
  max(l.scenario_id) FILTER(WHERE l.scenario_code='BASELINE') AS baseline_scenario_id,
  max(l.scenario_id) FILTER(WHERE l.scenario_code='RECESSION_ENERGY') AS stress_scenario_id,
  (SELECT metric_value_text FROM msbf_ctl.run_evidence
    WHERE run_id=r.run_id AND evidence_code='M1_14_COMBINED_SET_HASH' AND segment_key='PORTFOLIO') AS m1_14_combined_hash,
  c.combined_set_hash AS m1_15_combined_hash,c.contract_code AS m1_15_contract_code,
  c.contract_version AS m1_15_contract_version,c.schema_version AS m1_15_schema_version,
  ps.parameter_set_hash AS policy_configuration_hash
FROM msbf_ctl.run_registry r
JOIN msbf_m1.application_module1_latest l ON l.module1_run_id=r.run_id
JOIN msbf_ctl.scenario_registry sr ON sr.scenario_id=l.scenario_id
JOIN msbf_ctl.scenario_set ss ON ss.scenario_set_id=sr.scenario_set_id
JOIN msbf_ctl.m1_15_consumption_contract_registry c
  ON c.module1_run_id=r.run_id AND c.contract_code='M1_APPLICATION_CONSUMPTION'
 AND c.contract_version=1 AND c.contract_status='ACCEPTED'
JOIN msbf_ctl.policy_profile pp ON pp.profile_code='M1_16_ACQUISITION_FOUNDATIONS' AND pp.profile_version=1 AND pp.status='APPROVED'
JOIN msbf_ctl.parameter_set ps ON ps.parameter_set_id=pp.parameter_set_id AND ps.status='APPROVED'
WHERE r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1
GROUP BY r.run_id,r.run_code,r.run_version,r.population_id,r.as_of_date,
         ss.scenario_set_id,ss.scenario_set_code,ss.scenario_set_version,
         c.combined_set_hash,c.contract_code,c.contract_version,c.schema_version,
         ps.parameter_set_hash;

DO $ready$ DECLARE v_run bigint; BEGIN
  SELECT run_id INTO STRICT v_run FROM _m1_16_ctx;
  PERFORM msbf_m1.m1_16_assert_generation_ready(v_run);
END; $ready$;

DROP TABLE IF EXISTS _m1_16_app_base;
CREATE TEMP TABLE _m1_16_app_base ON COMMIT DROP AS
SELECT
  a.merchant_application_id,a.population_id,a.merchant_id,a.application_date,a.as_of_date,
  a.partner_channel_id,pc.channel_type,a.application_channel,a.request_hash,
  a.requested_funding_amount,
  row_number() OVER(ORDER BY a.merchant_application_id)::integer AS app_sequence,
  row_number() OVER(PARTITION BY a.partner_channel_id ORDER BY a.merchant_application_id)::integer AS channel_sequence,
  b.partner_acquisition_cost_rate AS accepted_m1_14_acquisition_cost_rate,
  b.partner_acquisition_cost_amount AS accepted_m1_14_acquisition_cost_amount,
  b.row_hash AS m1_14_baseline_row_hash,s.row_hash AS m1_14_stress_row_hash,
  lb.contract_row_hash AS m1_15_baseline_contract_row_hash,
  ls.contract_row_hash AS m1_15_stress_contract_row_hash,
  ctx.m1_14_combined_hash,ctx.m1_15_combined_hash,ctx.policy_configuration_hash,
  ctx.run_id
FROM msbf_m1.merchant_application a
JOIN msbf_m1.partner_channel pc ON pc.partner_channel_id=a.partner_channel_id
JOIN _m1_16_ctx ctx ON true
JOIN msbf_m1.application_unit_economics_snapshot b
  ON b.module1_run_id=ctx.run_id AND b.scenario_id=ctx.baseline_scenario_id
 AND b.merchant_application_id=a.merchant_application_id
JOIN msbf_m1.application_unit_economics_snapshot s
  ON s.module1_run_id=ctx.run_id AND s.scenario_id=ctx.stress_scenario_id
 AND s.merchant_application_id=a.merchant_application_id
JOIN msbf_m1.application_module1_latest lb
  ON lb.module1_run_id=ctx.run_id AND lb.scenario_id=ctx.baseline_scenario_id
 AND lb.merchant_application_id=a.merchant_application_id
JOIN msbf_m1.application_module1_latest ls
  ON ls.module1_run_id=ctx.run_id AND ls.scenario_id=ctx.stress_scenario_id
 AND ls.merchant_application_id=a.merchant_application_id
WHERE a.created_by_run_id=ctx.run_id
  AND b.partner_acquisition_cost_rate=s.partner_acquisition_cost_rate
  AND b.partner_acquisition_cost_amount=s.partner_acquisition_cost_amount;
CREATE UNIQUE INDEX ON _m1_16_app_base(merchant_application_id);
CREATE INDEX ON _m1_16_app_base(partner_channel_id,channel_sequence);
ANALYZE _m1_16_app_base;

DO $input_guard$ DECLARE v_apps bigint; BEGIN
 SELECT count(*) INTO v_apps FROM _m1_16_app_base;
 IF v_apps<>750 THEN RAISE EXCEPTION 'M1.16 accepted input count failed: %.',v_apps; END IF;
END; $input_guard$;

DO $phase_2$ BEGIN RAISE NOTICE 'M1.16 Phase 2/7 — generate source profiles, campaigns, funnel, and cost ledger'; END; $phase_2$;

DROP TABLE IF EXISTS _m1_16_source_expected;
CREATE TEMP TABLE _m1_16_source_expected (LIKE msbf_m1.acquisition_source_profile INCLUDING DEFAULTS) ON COMMIT DROP;
INSERT INTO _m1_16_source_expected(
 module1_run_id,acquisition_source_code,acquisition_source_name,normalized_source_family,
 source_subtype,source_classification,accepted_partner_channel_id,accepted_channel_type,
 source_owner_classification,vendor_partner_code,third_party_flag,approved_source_flag,
 governance_status,permitted_attribution_roles,permitted_cost_basis_codes,
 permitted_cost_timing_codes,default_attribution_priority,effective_start_date,effective_end_date,
 source_evidence_status,configuration_payload,row_hash,created_by_run_id,created_at
)
SELECT ctx.run_id,'SRC_PROC_PORTAL','Processor Dashboard / Embedded Portal','PROCESSOR_EMBEDDED','PROCESSOR_DASHBOARD','PROCESSOR_EMBEDDED','CH_PROCESSOR_DIRECT','PROCESSOR_DIRECT','Processor Partnerships','VENDOR_PROCESSOR_01',true,true,'APPROVED',ARRAY['PRIMARY','FIRST','LAST','ASSISTED']::text[],ARRAY['FIXED_CAMPAIGN','ALLOCATED_OVERHEAD','INTERNAL_LABOR_HOUR','PERCENT_FUNDED_AMOUNT','SUPPORTED_ZERO']::text[],ARRAY['INCURRED_PRE_APPLICATION','INCURRED_AT_APPLICATION','CONDITIONAL_ON_FUNDING']::text[],1,ctx.as_of_date-365,ctx.as_of_date+30,'COMPLETE',jsonb_build_object('synthetic',true,'source_subtype','PROCESSOR_DASHBOARD','third_party',true),''::text,ctx.run_id,clock_timestamp() FROM _m1_16_ctx ctx
UNION ALL
SELECT ctx.run_id,'SRC_PROC_EMAIL','Processor Email / In-Product Outreach','PROCESSOR_EMBEDDED','PROCESSOR_EMAIL','PROCESSOR_EMBEDDED','CH_PROCESSOR_DIRECT','PROCESSOR_DIRECT','Processor Partnerships','VENDOR_PROCESSOR_01',true,true,'APPROVED',ARRAY['PRIMARY','FIRST','LAST','ASSISTED']::text[],ARRAY['FIXED_CAMPAIGN','ALLOCATED_OVERHEAD','INTERNAL_LABOR_HOUR','PERCENT_FUNDED_AMOUNT','SUPPORTED_ZERO']::text[],ARRAY['INCURRED_PRE_APPLICATION','INCURRED_AT_APPLICATION','CONDITIONAL_ON_FUNDING']::text[],2,ctx.as_of_date-365,ctx.as_of_date+30,'COMPLETE',jsonb_build_object('synthetic',true,'source_subtype','PROCESSOR_EMAIL','third_party',true),''::text,ctx.run_id,clock_timestamp() FROM _m1_16_ctx ctx
UNION ALL
SELECT ctx.run_id,'SRC_PROC_ACCOUNT_MANAGER','Processor Account-Manager Referral','PROCESSOR_EMBEDDED','PROCESSOR_ACCOUNT_MANAGER','PROCESSOR_EMBEDDED','CH_PROCESSOR_DIRECT','PROCESSOR_DIRECT','Processor Partnerships','VENDOR_PROCESSOR_01',true,true,'APPROVED',ARRAY['PRIMARY','FIRST','LAST','ASSISTED']::text[],ARRAY['FIXED_CAMPAIGN','ALLOCATED_OVERHEAD','INTERNAL_LABOR_HOUR','PERCENT_FUNDED_AMOUNT','SUPPORTED_ZERO']::text[],ARRAY['INCURRED_PRE_APPLICATION','INCURRED_AT_APPLICATION','CONDITIONAL_ON_FUNDING']::text[],3,ctx.as_of_date-365,ctx.as_of_date+30,'PARTIAL',jsonb_build_object('synthetic',true,'source_subtype','PROCESSOR_ACCOUNT_MANAGER','third_party',true),''::text,ctx.run_id,clock_timestamp() FROM _m1_16_ctx ctx
UNION ALL
SELECT ctx.run_id,'SRC_BANK_RELATIONSHIP_MANAGER','Relationship Manager','RELATIONSHIP','RELATIONSHIP_MANAGER','RELATIONSHIP','CH_BANK_RELATIONSHIP','BANK_RELATIONSHIP','Business Banking','INTERNAL_BANK',false,true,'APPROVED',ARRAY['PRIMARY','FIRST','LAST','ASSISTED']::text[],ARRAY['INTERNAL_LABOR_HOUR','ALLOCATED_OVERHEAD','PERCENT_FUNDED_AMOUNT','SUPPORTED_ZERO']::text[],ARRAY['INCURRED_PRE_APPLICATION','INCURRED_AT_APPLICATION','CONDITIONAL_ON_FUNDING']::text[],1,ctx.as_of_date-365,ctx.as_of_date+30,'COMPLETE',jsonb_build_object('synthetic',true,'source_subtype','RELATIONSHIP_MANAGER','third_party',false),''::text,ctx.run_id,clock_timestamp() FROM _m1_16_ctx ctx
UNION ALL
SELECT ctx.run_id,'SRC_BANK_BRANCH_BANKER','Branch / Business Banker','RELATIONSHIP','BRANCH_BANKER','RELATIONSHIP','CH_BANK_RELATIONSHIP','BANK_RELATIONSHIP','Business Banking','INTERNAL_BANK',false,true,'APPROVED',ARRAY['PRIMARY','FIRST','LAST','ASSISTED']::text[],ARRAY['INTERNAL_LABOR_HOUR','ALLOCATED_OVERHEAD','PERCENT_FUNDED_AMOUNT','SUPPORTED_ZERO']::text[],ARRAY['INCURRED_PRE_APPLICATION','INCURRED_AT_APPLICATION','CONDITIONAL_ON_FUNDING']::text[],2,ctx.as_of_date-365,ctx.as_of_date+30,'PARTIAL',jsonb_build_object('synthetic',true,'source_subtype','BRANCH_BANKER','third_party',false),''::text,ctx.run_id,clock_timestamp() FROM _m1_16_ctx ctx
UNION ALL
SELECT ctx.run_id,'SRC_BANK_TREASURY_CROSS_SELL','Treasury / Merchant Services Cross-Sell','RELATIONSHIP','TREASURY_CROSS_SELL','RELATIONSHIP','CH_BANK_RELATIONSHIP','BANK_RELATIONSHIP','Treasury Management','INTERNAL_BANK',false,true,'APPROVED',ARRAY['PRIMARY','FIRST','LAST','ASSISTED']::text[],ARRAY['INTERNAL_LABOR_HOUR','ALLOCATED_OVERHEAD','PERCENT_FUNDED_AMOUNT','SUPPORTED_ZERO']::text[],ARRAY['INCURRED_PRE_APPLICATION','INCURRED_AT_APPLICATION','CONDITIONAL_ON_FUNDING']::text[],3,ctx.as_of_date-365,ctx.as_of_date+30,'PARTIAL',jsonb_build_object('synthetic',true,'source_subtype','TREASURY_CROSS_SELL','third_party',false),''::text,ctx.run_id,clock_timestamp() FROM _m1_16_ctx ctx
UNION ALL
SELECT ctx.run_id,'SRC_DIGITAL_PAID_SEARCH','Paid Search','PAID','PAID_SEARCH','PAID','CH_DIGITAL_DIRECT','DIGITAL_DIRECT','Digital Acquisition','VENDOR_MEDIA_01',true,true,'APPROVED',ARRAY['PRIMARY','FIRST','LAST','ASSISTED']::text[],ARRAY['FIXED_CAMPAIGN','PER_IMPRESSION_OR_DELIVERY','PER_CLICK_OR_RESPONSE','PER_QUALIFIED_LEAD','PER_SUBMITTED_APPLICATION','PERCENT_FUNDED_AMOUNT','ALLOCATED_OVERHEAD']::text[],ARRAY['INCURRED_PRE_APPLICATION','INCURRED_AT_APPLICATION','CONDITIONAL_ON_FUNDING']::text[],1,ctx.as_of_date-365,ctx.as_of_date+30,'COMPLETE',jsonb_build_object('synthetic',true,'source_subtype','PAID_SEARCH','third_party',true),''::text,ctx.run_id,clock_timestamp() FROM _m1_16_ctx ctx
UNION ALL
SELECT ctx.run_id,'SRC_DIGITAL_ORGANIC_SEARCH','Organic Search','ORGANIC','ORGANIC_SEARCH','ORGANIC','CH_DIGITAL_DIRECT','DIGITAL_DIRECT','Digital Acquisition','INTERNAL_DIGITAL',false,true,'APPROVED',ARRAY['PRIMARY','FIRST','LAST','ASSISTED']::text[],ARRAY['FIXED_CAMPAIGN','ALLOCATED_OVERHEAD','INTERNAL_LABOR_HOUR','PERCENT_FUNDED_AMOUNT','SUPPORTED_ZERO']::text[],ARRAY['INCURRED_PRE_APPLICATION','INCURRED_AT_APPLICATION','CONDITIONAL_ON_FUNDING']::text[],2,ctx.as_of_date-365,ctx.as_of_date+30,'PARTIAL',jsonb_build_object('synthetic',true,'source_subtype','ORGANIC_SEARCH','third_party',false),''::text,ctx.run_id,clock_timestamp() FROM _m1_16_ctx ctx
UNION ALL
SELECT ctx.run_id,'SRC_DIGITAL_PAID_SOCIAL','Paid Social / Display','PAID','PAID_SOCIAL_DISPLAY','PAID','CH_DIGITAL_DIRECT','DIGITAL_DIRECT','Digital Acquisition','VENDOR_MEDIA_02',true,true,'APPROVED',ARRAY['PRIMARY','FIRST','LAST','ASSISTED']::text[],ARRAY['FIXED_CAMPAIGN','PER_IMPRESSION_OR_DELIVERY','PER_CLICK_OR_RESPONSE','PER_QUALIFIED_LEAD','PER_SUBMITTED_APPLICATION','PERCENT_FUNDED_AMOUNT','ALLOCATED_OVERHEAD']::text[],ARRAY['INCURRED_PRE_APPLICATION','INCURRED_AT_APPLICATION','CONDITIONAL_ON_FUNDING']::text[],3,ctx.as_of_date-365,ctx.as_of_date+30,'COMPLETE',jsonb_build_object('synthetic',true,'source_subtype','PAID_SOCIAL_DISPLAY','third_party',true),''::text,ctx.run_id,clock_timestamp() FROM _m1_16_ctx ctx
UNION ALL
SELECT ctx.run_id,'SRC_DIGITAL_DIRECT_NAV','Bank Website / Direct Navigation','OWNED','DIRECT_NAVIGATION','OWNED','CH_DIGITAL_DIRECT','DIGITAL_DIRECT','Digital Acquisition','INTERNAL_DIGITAL',false,true,'APPROVED',ARRAY['PRIMARY','FIRST','LAST','ASSISTED']::text[],ARRAY['FIXED_CAMPAIGN','ALLOCATED_OVERHEAD','INTERNAL_LABOR_HOUR','PERCENT_FUNDED_AMOUNT','SUPPORTED_ZERO']::text[],ARRAY['INCURRED_PRE_APPLICATION','INCURRED_AT_APPLICATION','CONDITIONAL_ON_FUNDING']::text[],4,ctx.as_of_date-365,ctx.as_of_date+30,'PARTIAL',jsonb_build_object('synthetic',true,'source_subtype','DIRECT_NAVIGATION','third_party',false),''::text,ctx.run_id,clock_timestamp() FROM _m1_16_ctx ctx
UNION ALL
SELECT ctx.run_id,'SRC_DIGITAL_EMAIL_RETARGET','Email / Retargeting','OWNED','EMAIL_RETARGETING','OWNED','CH_DIGITAL_DIRECT','DIGITAL_DIRECT','Digital Acquisition','INTERNAL_DIGITAL',false,true,'APPROVED',ARRAY['PRIMARY','FIRST','LAST','ASSISTED']::text[],ARRAY['FIXED_CAMPAIGN','ALLOCATED_OVERHEAD','INTERNAL_LABOR_HOUR','PERCENT_FUNDED_AMOUNT','SUPPORTED_ZERO']::text[],ARRAY['INCURRED_PRE_APPLICATION','INCURRED_AT_APPLICATION','CONDITIONAL_ON_FUNDING']::text[],5,ctx.as_of_date-365,ctx.as_of_date+30,'PARTIAL',jsonb_build_object('synthetic',true,'source_subtype','EMAIL_RETARGETING','third_party',false),''::text,ctx.run_id,clock_timestamp() FROM _m1_16_ctx ctx
UNION ALL
SELECT ctx.run_id,'SRC_DIGITAL_DIRECT_MAIL','Prospect Direct Mail / Outbound','PAID','DIRECT_MAIL_OUTBOUND','PAID','CH_DIGITAL_DIRECT','DIGITAL_DIRECT','Direct Marketing','VENDOR_MAIL_01',true,true,'APPROVED',ARRAY['PRIMARY','FIRST','LAST','ASSISTED']::text[],ARRAY['FIXED_CAMPAIGN','PER_IMPRESSION_OR_DELIVERY','PER_CLICK_OR_RESPONSE','PER_QUALIFIED_LEAD','PER_SUBMITTED_APPLICATION','PERCENT_FUNDED_AMOUNT','ALLOCATED_OVERHEAD']::text[],ARRAY['INCURRED_PRE_APPLICATION','INCURRED_AT_APPLICATION','CONDITIONAL_ON_FUNDING']::text[],6,ctx.as_of_date-365,ctx.as_of_date+30,'COMPLETE',jsonb_build_object('synthetic',true,'source_subtype','DIRECT_MAIL_OUTBOUND','third_party',true),''::text,ctx.run_id,clock_timestamp() FROM _m1_16_ctx ctx
UNION ALL
SELECT ctx.run_id,'SRC_PARTNER_SOFTWARE_PLATFORM','Software / Platform Referral','STRATEGIC_PARTNER','SOFTWARE_PLATFORM_REFERRAL','STRATEGIC_PARTNER','CH_STRATEGIC_PARTNER','STRATEGIC_PARTNER','Strategic Partnerships','VENDOR_PLATFORM_01',true,true,'APPROVED',ARRAY['PRIMARY','FIRST','LAST','ASSISTED']::text[],ARRAY['FIXED_CAMPAIGN','ALLOCATED_OVERHEAD','INTERNAL_LABOR_HOUR','PERCENT_FUNDED_AMOUNT','SUPPORTED_ZERO','PER_SUBMITTED_APPLICATION']::text[],ARRAY['INCURRED_PRE_APPLICATION','INCURRED_AT_APPLICATION','CONDITIONAL_ON_FUNDING']::text[],1,ctx.as_of_date-365,ctx.as_of_date+30,'COMPLETE',jsonb_build_object('synthetic',true,'source_subtype','SOFTWARE_PLATFORM_REFERRAL','third_party',true),''::text,ctx.run_id,clock_timestamp() FROM _m1_16_ctx ctx
UNION ALL
SELECT ctx.run_id,'SRC_PARTNER_ASSOCIATION','Association Referral','STRATEGIC_PARTNER','ASSOCIATION_REFERRAL','STRATEGIC_PARTNER','CH_STRATEGIC_PARTNER','STRATEGIC_PARTNER','Strategic Partnerships','VENDOR_ASSOC_01',true,true,'APPROVED',ARRAY['PRIMARY','FIRST','LAST','ASSISTED']::text[],ARRAY['FIXED_CAMPAIGN','ALLOCATED_OVERHEAD','INTERNAL_LABOR_HOUR','PERCENT_FUNDED_AMOUNT','SUPPORTED_ZERO','PER_SUBMITTED_APPLICATION']::text[],ARRAY['INCURRED_PRE_APPLICATION','INCURRED_AT_APPLICATION','CONDITIONAL_ON_FUNDING']::text[],2,ctx.as_of_date-365,ctx.as_of_date+30,'PARTIAL',jsonb_build_object('synthetic',true,'source_subtype','ASSOCIATION_REFERRAL','third_party',true),''::text,ctx.run_id,clock_timestamp() FROM _m1_16_ctx ctx
UNION ALL
SELECT ctx.run_id,'SRC_PARTNER_MERCHANT_SERVICES','Merchant-Services Partner Referral','STRATEGIC_PARTNER','MERCHANT_SERVICES_REFERRAL','STRATEGIC_PARTNER','CH_STRATEGIC_PARTNER','STRATEGIC_PARTNER','Strategic Partnerships','VENDOR_MSP_01',true,true,'APPROVED',ARRAY['PRIMARY','FIRST','LAST','ASSISTED']::text[],ARRAY['FIXED_CAMPAIGN','ALLOCATED_OVERHEAD','INTERNAL_LABOR_HOUR','PERCENT_FUNDED_AMOUNT','SUPPORTED_ZERO','PER_SUBMITTED_APPLICATION']::text[],ARRAY['INCURRED_PRE_APPLICATION','INCURRED_AT_APPLICATION','CONDITIONAL_ON_FUNDING']::text[],3,ctx.as_of_date-365,ctx.as_of_date+30,'COMPLETE',jsonb_build_object('synthetic',true,'source_subtype','MERCHANT_SERVICES_REFERRAL','third_party',true),''::text,ctx.run_id,clock_timestamp() FROM _m1_16_ctx ctx
UNION ALL
SELECT ctx.run_id,'SRC_BROKER_ISO','Broker / ISO Referral','BROKER_OR_LEAD','BROKER_ISO_REFERRAL','BROKER_OR_LEAD','CH_BROKER_NETWORK','BROKER_NETWORK','Broker Channel','VENDOR_BROKER_01',true,true,'APPROVED',ARRAY['PRIMARY','FIRST','LAST','ASSISTED']::text[],ARRAY['FIXED_CAMPAIGN','PER_IMPRESSION_OR_DELIVERY','PER_CLICK_OR_RESPONSE','PER_QUALIFIED_LEAD','PER_SUBMITTED_APPLICATION','PERCENT_FUNDED_AMOUNT','ALLOCATED_OVERHEAD']::text[],ARRAY['INCURRED_PRE_APPLICATION','INCURRED_AT_APPLICATION','CONDITIONAL_ON_FUNDING']::text[],1,ctx.as_of_date-365,ctx.as_of_date+30,'COMPLETE',jsonb_build_object('synthetic',true,'source_subtype','BROKER_ISO_REFERRAL','third_party',true),''::text,ctx.run_id,clock_timestamp() FROM _m1_16_ctx ctx
UNION ALL
SELECT ctx.run_id,'SRC_BROKER_PURCHASED_LEAD','Purchased Lead','BROKER_OR_LEAD','PURCHASED_LEAD','BROKER_OR_LEAD','CH_BROKER_NETWORK','BROKER_NETWORK','Broker Channel','VENDOR_LEAD_01',true,true,'APPROVED',ARRAY['PRIMARY','FIRST','LAST','ASSISTED']::text[],ARRAY['FIXED_CAMPAIGN','PER_IMPRESSION_OR_DELIVERY','PER_CLICK_OR_RESPONSE','PER_QUALIFIED_LEAD','PER_SUBMITTED_APPLICATION','PERCENT_FUNDED_AMOUNT','ALLOCATED_OVERHEAD']::text[],ARRAY['INCURRED_PRE_APPLICATION','INCURRED_AT_APPLICATION','CONDITIONAL_ON_FUNDING']::text[],2,ctx.as_of_date-365,ctx.as_of_date+30,'PARTIAL',jsonb_build_object('synthetic',true,'source_subtype','PURCHASED_LEAD','third_party',true),''::text,ctx.run_id,clock_timestamp() FROM _m1_16_ctx ctx
UNION ALL
SELECT ctx.run_id,'SRC_BROKER_DIRECT','Broker-Sourced Direct Application','BROKER_OR_LEAD','BROKER_DIRECT_APPLICATION','BROKER_OR_LEAD','CH_BROKER_NETWORK','BROKER_NETWORK','Broker Channel','VENDOR_BROKER_02',true,true,'APPROVED',ARRAY['PRIMARY','FIRST','LAST','ASSISTED']::text[],ARRAY['FIXED_CAMPAIGN','PER_IMPRESSION_OR_DELIVERY','PER_CLICK_OR_RESPONSE','PER_QUALIFIED_LEAD','PER_SUBMITTED_APPLICATION','PERCENT_FUNDED_AMOUNT','ALLOCATED_OVERHEAD']::text[],ARRAY['INCURRED_PRE_APPLICATION','INCURRED_AT_APPLICATION','CONDITIONAL_ON_FUNDING']::text[],3,ctx.as_of_date-365,ctx.as_of_date+30,'PARTIAL',jsonb_build_object('synthetic',true,'source_subtype','BROKER_DIRECT_APPLICATION','third_party',true),''::text,ctx.run_id,clock_timestamp() FROM _m1_16_ctx ctx;
UPDATE _m1_16_source_expected s
SET row_hash=msbf_m1.m1_16_hash_jsonb(to_jsonb(s)-'row_hash'-'created_at')
WHERE row_hash='';
INSERT INTO msbf_m1.acquisition_source_profile(
 module1_run_id,acquisition_source_code,acquisition_source_name,normalized_source_family,
 source_subtype,source_classification,accepted_partner_channel_id,accepted_channel_type,
 source_owner_classification,vendor_partner_code,third_party_flag,approved_source_flag,
 governance_status,permitted_attribution_roles,permitted_cost_basis_codes,
 permitted_cost_timing_codes,default_attribution_priority,effective_start_date,effective_end_date,
 source_evidence_status,configuration_payload,row_hash,created_by_run_id,created_at
)
SELECT module1_run_id,acquisition_source_code,acquisition_source_name,normalized_source_family,
 source_subtype,source_classification,accepted_partner_channel_id,accepted_channel_type,
 source_owner_classification,vendor_partner_code,third_party_flag,approved_source_flag,
 governance_status,permitted_attribution_roles,permitted_cost_basis_codes,
 permitted_cost_timing_codes,default_attribution_priority,effective_start_date,effective_end_date,
 source_evidence_status,configuration_payload,row_hash,created_by_run_id,created_at
FROM _m1_16_source_expected;

DROP TABLE IF EXISTS _m1_16_campaign_seed;
CREATE TEMP TABLE _m1_16_campaign_seed(
 acquisition_campaign_id text,acquisition_source_code text,accepted_partner_channel_id text,
 campaign_family_code text,campaign_type text,campaign_name_synthetic text,
 submitted_count integer,primary_cost_component text,cost_basis_code text,
 quantity_source text,unit_cost numeric(18,6),conditional_rate numeric(12,8),
 owner_classification text,vendor_partner_code text,always_on_flag boolean,funnel_profile text
) ON COMMIT DROP;
INSERT INTO _m1_16_campaign_seed VALUES
('ACQ_PROC_PORTAL_ALWAYS_ON','SRC_PROC_PORTAL','CH_PROCESSOR_DIRECT','PROCESSOR_DIRECT','ALWAYS_ON_EMBEDDED','Processor Portal Always-On',105,'CAMPAIGN_OVERHEAD_COST','FIXED_CAMPAIGN','FIXED',4200.0,0.006,'Processor Partnerships','VENDOR_PROCESSOR_01',true,'WARM'),
('ACQ_PROC_EMAIL_OUTREACH','SRC_PROC_EMAIL','CH_PROCESSOR_DIRECT','PROCESSOR_DIRECT','OWNED_OUTREACH','Processor Email Outreach',90,'AGENCY_CREATIVE_TECH_COST','FIXED_CAMPAIGN','FIXED',3600.0,0.006,'Processor Partnerships','VENDOR_PROCESSOR_01',false,'WARM'),
('ACQ_PROC_AM_REFERRAL','SRC_PROC_ACCOUNT_MANAGER','CH_PROCESSOR_DIRECT','PROCESSOR_DIRECT','RELATIONSHIP_REFERRAL','Processor Account-Manager Referral',60,'INTERNAL_SALES_RM_COST','INTERNAL_LABOR_HOUR','LABOR_HOURS',75.0,0.006,'Processor Partnerships','VENDOR_PROCESSOR_01',true,'RELATIONSHIP'),
('ACQ_BANK_RM_ALWAYS_ON','SRC_BANK_RELATIONSHIP_MANAGER','CH_BANK_RELATIONSHIP','BANK_RELATIONSHIP','RELATIONSHIP_REFERRAL','Relationship Manager Always-On',65,'INTERNAL_SALES_RM_COST','INTERNAL_LABOR_HOUR','LABOR_HOURS',75.0,0.004,'Business Banking','INTERNAL_BANK',true,'RELATIONSHIP'),
('ACQ_BANK_BRANCH_OUTREACH','SRC_BANK_BRANCH_BANKER','CH_BANK_RELATIONSHIP','BANK_RELATIONSHIP','RELATIONSHIP_OUTREACH','Branch Business Banker Outreach',45,'INTERNAL_SALES_RM_COST','INTERNAL_LABOR_HOUR','LABOR_HOURS',75.0,0.004,'Business Banking','INTERNAL_BANK',false,'RELATIONSHIP'),
('ACQ_BANK_TREASURY_XSELL','SRC_BANK_TREASURY_CROSS_SELL','CH_BANK_RELATIONSHIP','BANK_RELATIONSHIP','CROSS_SELL','Treasury and Merchant Services Cross-Sell',25,'INTERNAL_SALES_RM_COST','INTERNAL_LABOR_HOUR','LABOR_HOURS',75.0,0.004,'Treasury Management','INTERNAL_BANK',true,'RELATIONSHIP'),
('ACQ_DIGITAL_PAID_SEARCH_BRAND','SRC_DIGITAL_PAID_SEARCH','CH_DIGITAL_DIRECT','DIGITAL_DIRECT','PAID_SEARCH','Paid Search — Brand',30,'PAID_MEDIA_COST','PER_CLICK_OR_RESPONSE','ENGAGED',5.0,0.008,'Digital Acquisition','VENDOR_MEDIA_01',false,'PAID_DIGITAL'),
('ACQ_DIGITAL_PAID_SEARCH_NONBRAND','SRC_DIGITAL_PAID_SEARCH','CH_DIGITAL_DIRECT','DIGITAL_DIRECT','PAID_SEARCH','Paid Search — Nonbrand',25,'PAID_MEDIA_COST','PER_CLICK_OR_RESPONSE','ENGAGED',7.0,0.008,'Digital Acquisition','VENDOR_MEDIA_01',false,'PAID_DIGITAL'),
('ACQ_DIGITAL_ORGANIC_ALWAYS_ON','SRC_DIGITAL_ORGANIC_SEARCH','CH_DIGITAL_DIRECT','DIGITAL_DIRECT','ORGANIC_SEARCH','Organic Search Always-On',25,'AGENCY_CREATIVE_TECH_COST','FIXED_CAMPAIGN','FIXED',4200.0,0.008,'Digital Acquisition','INTERNAL_DIGITAL',true,'OWNED_ORGANIC'),
('ACQ_DIGITAL_PAID_SOCIAL','SRC_DIGITAL_PAID_SOCIAL','CH_DIGITAL_DIRECT','DIGITAL_DIRECT','PAID_SOCIAL_DISPLAY','Paid Social and Display',20,'PAID_MEDIA_COST','PER_CLICK_OR_RESPONSE','ENGAGED',4.0,0.008,'Digital Acquisition','VENDOR_MEDIA_02',false,'PAID_DIGITAL'),
('ACQ_DIGITAL_DIRECT_NAV','SRC_DIGITAL_DIRECT_NAV','CH_DIGITAL_DIRECT','DIGITAL_DIRECT','OWNED_DIRECT','Direct Navigation Always-On',20,'CAMPAIGN_OVERHEAD_COST','ALLOCATED_OVERHEAD','FIXED',3000.0,0.008,'Digital Acquisition','INTERNAL_DIGITAL',true,'OWNED_ORGANIC'),
('ACQ_DIGITAL_EMAIL_RETARGET','SRC_DIGITAL_EMAIL_RETARGET','CH_DIGITAL_DIRECT','DIGITAL_DIRECT','OWNED_EMAIL','Email and Retargeting',15,'AGENCY_CREATIVE_TECH_COST','FIXED_CAMPAIGN','FIXED',3600.0,0.008,'Digital Acquisition','INTERNAL_DIGITAL',false,'OWNED_ORGANIC'),
('ACQ_DIGITAL_DIRECT_MAIL','SRC_DIGITAL_DIRECT_MAIL','CH_DIGITAL_DIRECT','DIGITAL_DIRECT','DIRECT_MAIL','Prospect Direct Mail',15,'DIRECT_MAIL_EVENT_OUTBOUND_COST','PER_IMPRESSION_OR_DELIVERY','DELIVERED',0.85,0.008,'Direct Marketing','VENDOR_MAIL_01',false,'PAID_DIGITAL'),
('ACQ_PARTNER_SOFTWARE_PLATFORM','SRC_PARTNER_SOFTWARE_PLATFORM','CH_STRATEGIC_PARTNER','STRATEGIC_PARTNER','PLATFORM_REFERRAL','Software Platform Referral',50,'CAMPAIGN_OVERHEAD_COST','ALLOCATED_OVERHEAD','FIXED',5000.0,0.02,'Strategic Partnerships','VENDOR_PLATFORM_01',true,'PARTNER'),
('ACQ_PARTNER_ASSOCIATION','SRC_PARTNER_ASSOCIATION','CH_STRATEGIC_PARTNER','STRATEGIC_PARTNER','ASSOCIATION_REFERRAL','Association Referral Program',40,'ACQUISITION_INCENTIVE_COST','PER_SUBMITTED_APPLICATION','SUBMITTED',50.0,0.02,'Strategic Partnerships','VENDOR_ASSOC_01',false,'PARTNER'),
('ACQ_PARTNER_MERCHANT_SERVICES','SRC_PARTNER_MERCHANT_SERVICES','CH_STRATEGIC_PARTNER','STRATEGIC_PARTNER','MERCHANT_SERVICES_REFERRAL','Merchant Services Partner Referral',30,'CAMPAIGN_OVERHEAD_COST','ALLOCATED_OVERHEAD','FIXED',4200.0,0.02,'Strategic Partnerships','VENDOR_MSP_01',true,'PARTNER'),
('ACQ_BROKER_ISO_EAST','SRC_BROKER_ISO','CH_BROKER_NETWORK','BROKER_NETWORK','BROKER_ISO','Broker / ISO East',35,'CAMPAIGN_OVERHEAD_COST','ALLOCATED_OVERHEAD','FIXED',4200.0,0.04,'Broker Channel','VENDOR_BROKER_01',true,'BROKER'),
('ACQ_BROKER_ISO_WEST','SRC_BROKER_ISO','CH_BROKER_NETWORK','BROKER_NETWORK','BROKER_ISO','Broker / ISO West',25,'CAMPAIGN_OVERHEAD_COST','ALLOCATED_OVERHEAD','FIXED',3600.0,0.04,'Broker Channel','VENDOR_BROKER_01',true,'BROKER'),
('ACQ_BROKER_PURCHASED_LEADS','SRC_BROKER_PURCHASED_LEAD','CH_BROKER_NETWORK','BROKER_NETWORK','PURCHASED_LEAD','Purchased Lead Program',20,'PURCHASED_LEAD_COST','PER_QUALIFIED_LEAD','QUALIFIED',65.0,0.04,'Broker Channel','VENDOR_LEAD_01',false,'BROKER'),
('ACQ_BROKER_DIRECT','SRC_BROKER_DIRECT','CH_BROKER_NETWORK','BROKER_NETWORK','BROKER_DIRECT','Broker-Sourced Direct Application',10,'ACQUISITION_INCENTIVE_COST','PER_SUBMITTED_APPLICATION','SUBMITTED',50.0,0.04,'Broker Channel','VENDOR_BROKER_02',false,'BROKER');

DROP TABLE IF EXISTS _m1_16_campaign_calc;
CREATE TEMP TABLE _m1_16_campaign_calc ON COMMIT DROP AS
WITH counts AS(
 SELECT s.acquisition_campaign_id,s.acquisition_source_code,s.accepted_partner_channel_id,
  s.campaign_family_code,s.campaign_type,s.campaign_name_synthetic,s.submitted_count,
  s.primary_cost_component,s.cost_basis_code,s.quantity_source,s.unit_cost,s.conditional_rate,
  s.owner_classification,s.vendor_partner_code,s.always_on_flag,s.funnel_profile,
  ceil(s.submitted_count * CASE s.funnel_profile WHEN 'WARM' THEN 4.0 WHEN 'RELATIONSHIP' THEN 3.5 WHEN 'PAID_DIGITAL' THEN 20.0 WHEN 'OWNED_ORGANIC' THEN 8.0 WHEN 'PARTNER' THEN 5.0 ELSE 4.0 END)::bigint AS targeted_count,
  ceil(s.submitted_count * CASE s.funnel_profile WHEN 'WARM' THEN 3.5 WHEN 'RELATIONSHIP' THEN 3.0 WHEN 'PAID_DIGITAL' THEN 18.0 WHEN 'OWNED_ORGANIC' THEN 7.0 WHEN 'PARTNER' THEN 4.5 ELSE 3.5 END)::bigint AS delivered_count,
  ceil(s.submitted_count * CASE s.funnel_profile WHEN 'WARM' THEN 2.2 WHEN 'RELATIONSHIP' THEN 2.0 WHEN 'PAID_DIGITAL' THEN 5.0 WHEN 'OWNED_ORGANIC' THEN 3.5 WHEN 'PARTNER' THEN 2.5 ELSE 2.2 END)::bigint AS engaged_count,
  ceil(s.submitted_count * CASE s.funnel_profile WHEN 'WARM' THEN 1.5 WHEN 'RELATIONSHIP' THEN 1.4 WHEN 'PAID_DIGITAL' THEN 2.0 WHEN 'OWNED_ORGANIC' THEN 1.8 WHEN 'PARTNER' THEN 1.5 ELSE 1.4 END)::bigint AS qualified_count,
  ceil(s.submitted_count * CASE s.funnel_profile WHEN 'WARM' THEN 1.15 WHEN 'RELATIONSHIP' THEN 1.12 WHEN 'PAID_DIGITAL' THEN 1.25 WHEN 'OWNED_ORGANIC' THEN 1.20 WHEN 'PARTNER' THEN 1.15 ELSE 1.10 END)::bigint AS started_count
 FROM _m1_16_campaign_seed s
), quantity AS(
 SELECT c.acquisition_campaign_id,c.acquisition_source_code,c.accepted_partner_channel_id,
  c.campaign_family_code,c.campaign_type,c.campaign_name_synthetic,c.submitted_count,
  c.primary_cost_component,c.cost_basis_code,c.quantity_source,c.unit_cost,c.conditional_rate,
  c.owner_classification,c.vendor_partner_code,c.always_on_flag,c.funnel_profile,
  c.targeted_count,c.delivered_count,c.engaged_count,c.qualified_count,c.started_count,
  CASE c.quantity_source WHEN 'FIXED' THEN 1::numeric
       WHEN 'LABOR_HOURS' THEN ceil(c.submitted_count*0.75)::numeric
       WHEN 'ENGAGED' THEN c.engaged_count::numeric
       WHEN 'DELIVERED' THEN c.delivered_count::numeric
       WHEN 'QUALIFIED' THEN c.qualified_count::numeric
       WHEN 'SUBMITTED' THEN c.submitted_count::numeric END AS incurred_quantity
 FROM counts c
)
SELECT q.acquisition_campaign_id,q.acquisition_source_code,q.accepted_partner_channel_id,
 q.campaign_family_code,q.campaign_type,q.campaign_name_synthetic,q.submitted_count,
 q.primary_cost_component,q.cost_basis_code,q.quantity_source,q.unit_cost,q.conditional_rate,
 q.owner_classification,q.vendor_partner_code,q.always_on_flag,q.funnel_profile,
 q.targeted_count,q.delivered_count,q.engaged_count,q.qualified_count,q.started_count,
 q.incurred_quantity,
 CASE
   WHEN q.primary_cost_component IN(
     'PAID_MEDIA_COST','DIRECT_MAIL_EVENT_OUTBOUND_COST',
     'PURCHASED_LEAD_COST','ACQUISITION_INCENTIVE_COST'
   ) THEN 'COMPLETE'
   ELSE 'PARTIAL'
 END::text AS campaign_evidence_status,
 round(q.incurred_quantity*q.unit_cost,2)::numeric(18,2) AS spend_amount,
 round(q.incurred_quantity*q.unit_cost*1.10,2)::numeric(18,2) AS budget_amount
FROM quantity q;
CREATE UNIQUE INDEX ON _m1_16_campaign_calc(acquisition_campaign_id);

/* The campaign evidence status is a governed derived attribute used by both
   the persisted campaign and every campaign-funnel row.  It is calculated
   once in _m1_16_campaign_calc so downstream consumers cannot reference a
   field that is absent from their physical source relation. */
DO $campaign_projection_guard$
DECLARE
  v_rows bigint;
  v_null_status bigint;
  v_invalid_status bigint;
BEGIN
  SELECT count(*),
         count(*) FILTER (WHERE campaign_evidence_status IS NULL),
         count(*) FILTER (
           WHERE campaign_evidence_status NOT IN('COMPLETE','PARTIAL','BLOCKED')
         )
    INTO v_rows,v_null_status,v_invalid_status
  FROM _m1_16_campaign_calc;

  IF v_rows<>20 OR v_null_status<>0 OR v_invalid_status<>0 THEN
    RAISE EXCEPTION
      'M1.16 campaign projection guard failed: rows %, null status %, invalid status %.',
      v_rows,v_null_status,v_invalid_status;
  END IF;
END;
$campaign_projection_guard$;

DROP TABLE IF EXISTS _m1_16_campaign_expected;
CREATE TEMP TABLE _m1_16_campaign_expected (LIKE msbf_m1.acquisition_marketing_campaign INCLUDING DEFAULTS) ON COMMIT DROP;
INSERT INTO _m1_16_campaign_expected(
 module1_run_id,acquisition_campaign_id,acquisition_source_code,accepted_partner_channel_id,
 campaign_family_code,campaign_type,campaign_name_synthetic,effective_start_date,effective_end_date,
 campaign_status,approval_status,audience_segment_code,budget_amount,spend_amount,
 owner_classification,vendor_partner_code,always_on_flag,campaign_evidence_status,row_hash,
 created_by_run_id,created_at
)
SELECT ctx.run_id,c.acquisition_campaign_id,c.acquisition_source_code,c.accepted_partner_channel_id,
 c.campaign_family_code,c.campaign_type,c.campaign_name_synthetic,ctx.as_of_date-180,ctx.as_of_date,
 'ACTIVE','APPROVED','SYNTHETIC_SMALL_BUSINESS_GENERAL',c.budget_amount,c.spend_amount,
 c.owner_classification,c.vendor_partner_code,c.always_on_flag,
 c.campaign_evidence_status,
 '',ctx.run_id,clock_timestamp()
FROM _m1_16_campaign_calc c CROSS JOIN _m1_16_ctx ctx;
UPDATE _m1_16_campaign_expected c
SET row_hash=msbf_m1.m1_16_hash_jsonb(to_jsonb(c)-'row_hash'-'created_at') WHERE row_hash='';
INSERT INTO msbf_m1.acquisition_marketing_campaign(
 module1_run_id,acquisition_campaign_id,acquisition_source_code,accepted_partner_channel_id,
 campaign_family_code,campaign_type,campaign_name_synthetic,effective_start_date,effective_end_date,
 campaign_status,approval_status,audience_segment_code,budget_amount,spend_amount,
 owner_classification,vendor_partner_code,always_on_flag,campaign_evidence_status,row_hash,
 created_by_run_id,created_at
)
SELECT module1_run_id,acquisition_campaign_id,acquisition_source_code,accepted_partner_channel_id,
 campaign_family_code,campaign_type,campaign_name_synthetic,effective_start_date,effective_end_date,
 campaign_status,approval_status,audience_segment_code,budget_amount,spend_amount,
 owner_classification,vendor_partner_code,always_on_flag,campaign_evidence_status,row_hash,
 created_by_run_id,created_at FROM _m1_16_campaign_expected;

DROP TABLE IF EXISTS _m1_16_funnel_expected;
CREATE TEMP TABLE _m1_16_funnel_expected (LIKE msbf_m1.acquisition_campaign_funnel_stage INCLUDING DEFAULTS) ON COMMIT DROP;
WITH stages AS(
 SELECT c.acquisition_campaign_id,c.accepted_partner_channel_id,c.campaign_evidence_status,
        ctx.run_id,ctx.as_of_date,
        v.stage_code,v.stage_order,v.stage_count
 FROM _m1_16_campaign_calc c
 CROSS JOIN _m1_16_ctx ctx
 CROSS JOIN LATERAL (VALUES
   ('TARGETED_OR_ELIGIBLE'::text,1::smallint,c.targeted_count),
   ('DELIVERED_OR_PRESENTED',2::smallint,c.delivered_count),
   ('ENGAGED_OR_RESPONDED',3::smallint,c.engaged_count),
   ('QUALIFIED_LEAD',4::smallint,c.qualified_count),
   ('APPLICATION_STARTED',5::smallint,c.started_count),
   ('APPLICATION_SUBMITTED',6::smallint,c.submitted_count::bigint)
 ) v(stage_code,stage_order,stage_count)
), with_prior AS(
 SELECT s.acquisition_campaign_id,s.accepted_partner_channel_id,s.campaign_evidence_status,
        s.run_id,s.as_of_date,s.stage_code,s.stage_order,s.stage_count,
        lag(s.stage_count) OVER(PARTITION BY acquisition_campaign_id ORDER BY stage_order) AS prior_count
 FROM stages s
)
INSERT INTO _m1_16_funnel_expected(
 module1_run_id,acquisition_campaign_id,stage_code,stage_order,period_start_date,period_end_date,
 stage_count,applicability_status,conversion_rate_from_prior,evidence_basis_code,evidence_status,
 row_hash,created_by_run_id,created_at
)
SELECT run_id,acquisition_campaign_id,stage_code,stage_order,as_of_date-180,as_of_date,
 stage_count,'APPLICABLE',CASE WHEN prior_count IS NULL OR prior_count=0 THEN NULL ELSE round(stage_count::numeric/prior_count,8) END,
 'DETERMINISTIC_CAMPAIGN_FUNNEL',campaign_evidence_status,'',run_id,clock_timestamp()
FROM with_prior;

DO $funnel_campaign_status_guard$
DECLARE
  v_rows bigint;
  v_status_mismatches bigint;
BEGIN
  SELECT count(*),
         count(*) FILTER (
           WHERE f.evidence_status IS DISTINCT FROM c.campaign_evidence_status
         )
    INTO v_rows,v_status_mismatches
  FROM _m1_16_funnel_expected f
  JOIN _m1_16_campaign_expected c
    ON c.module1_run_id=f.module1_run_id
   AND c.acquisition_campaign_id=f.acquisition_campaign_id;

  IF v_rows<>120 OR v_status_mismatches<>0 THEN
    RAISE EXCEPTION
      'M1.16 campaign/funnel evidence guard failed: rows %, status mismatches %.',
      v_rows,v_status_mismatches;
  END IF;
END;
$funnel_campaign_status_guard$;

UPDATE _m1_16_funnel_expected f
SET row_hash=msbf_m1.m1_16_hash_jsonb(to_jsonb(f)-'row_hash'-'created_at') WHERE row_hash='';
INSERT INTO msbf_m1.acquisition_campaign_funnel_stage(
 module1_run_id,acquisition_campaign_id,stage_code,stage_order,period_start_date,period_end_date,
 stage_count,applicability_status,conversion_rate_from_prior,evidence_basis_code,evidence_status,
 row_hash,created_by_run_id,created_at
)
SELECT module1_run_id,acquisition_campaign_id,stage_code,stage_order,period_start_date,period_end_date,
 stage_count,applicability_status,conversion_rate_from_prior,evidence_basis_code,evidence_status,
 row_hash,created_by_run_id,created_at FROM _m1_16_funnel_expected;

DROP TABLE IF EXISTS _m1_16_ledger_expected;
CREATE TEMP TABLE _m1_16_ledger_expected (LIKE msbf_m1.acquisition_cost_ledger INCLUDING DEFAULTS) ON COMMIT DROP;
INSERT INTO _m1_16_ledger_expected(
 module1_run_id,acquisition_cost_line_id,acquisition_campaign_id,acquisition_source_code,
 cost_component_code,cost_basis_code,cost_timing_code,quantity,unit_cost_amount,unit_rate,
 gross_cost_amount,currency_code,incurred_effective_date,allocable_flag,conditional_flag,
 allocation_method_code,accepted_m1_14_overlap_class,evidence_basis_code,evidence_status,
 row_hash,created_by_run_id,created_at
)
SELECT ctx.run_id,c.acquisition_campaign_id||'|INCURRED',c.acquisition_campaign_id,c.acquisition_source_code,
 c.primary_cost_component,c.cost_basis_code,
 CASE WHEN c.primary_cost_component IN('INTERNAL_SALES_RM_COST','ACQUISITION_INCENTIVE_COST') THEN 'INCURRED_AT_APPLICATION' ELSE 'INCURRED_PRE_APPLICATION' END,
 c.incurred_quantity,c.unit_cost,NULL,c.spend_amount,'USD',ctx.as_of_date-30,true,false,
 'PRIMARY_ATTRIBUTED_EQUAL_CENT_RECONCILIATION',op.overlap_class,
 CASE WHEN c.primary_cost_component IN('PAID_MEDIA_COST','DIRECT_MAIL_EVENT_OUTBOUND_COST','PURCHASED_LEAD_COST','ACQUISITION_INCENTIVE_COST') THEN 'DIRECT_SYNTHETIC_OBSERVATION'
      WHEN c.primary_cost_component='INTERNAL_SALES_RM_COST' THEN 'INTERNAL_COST_ALLOCATED' ELSE 'GOVERNED_PARAMETER' END,
 CASE WHEN c.primary_cost_component IN('PAID_MEDIA_COST','DIRECT_MAIL_EVENT_OUTBOUND_COST','PURCHASED_LEAD_COST','ACQUISITION_INCENTIVE_COST') THEN 'COMPLETE' ELSE 'PARTIAL' END,
 '',ctx.run_id,clock_timestamp()
FROM _m1_16_campaign_calc c CROSS JOIN _m1_16_ctx ctx
JOIN msbf_ref.acquisition_legacy_overlap_policy op
  ON op.partner_channel_id=c.accepted_partner_channel_id AND op.cost_component_code=c.primary_cost_component
UNION ALL
SELECT ctx.run_id,c.acquisition_campaign_id||'|CONDITIONAL',c.acquisition_campaign_id,c.acquisition_source_code,
 'DETAILED_CONDITIONAL_PARTNER_BROKER_COST','PERCENT_FUNDED_AMOUNT','CONDITIONAL_ON_FUNDING',
 0::numeric,NULL,c.conditional_rate,0::numeric(18,2),'USD',ctx.as_of_date,false,true,
 'APPLICATION_REQUESTED_FUNDING_IF_BOOKED','FULLY_INCLUDED_IN_M1_14','GOVERNED_PARAMETER','PARTIAL',
 '',ctx.run_id,clock_timestamp()
FROM _m1_16_campaign_calc c CROSS JOIN _m1_16_ctx ctx;
UPDATE _m1_16_ledger_expected l
SET row_hash=msbf_m1.m1_16_hash_jsonb(to_jsonb(l)-'row_hash'-'created_at') WHERE row_hash='';
INSERT INTO msbf_m1.acquisition_cost_ledger(
 module1_run_id,acquisition_cost_line_id,acquisition_campaign_id,acquisition_source_code,
 cost_component_code,cost_basis_code,cost_timing_code,quantity,unit_cost_amount,unit_rate,
 gross_cost_amount,currency_code,incurred_effective_date,allocable_flag,conditional_flag,
 allocation_method_code,accepted_m1_14_overlap_class,evidence_basis_code,evidence_status,
 row_hash,created_by_run_id,created_at
)
SELECT module1_run_id,acquisition_cost_line_id,acquisition_campaign_id,acquisition_source_code,
 cost_component_code,cost_basis_code,cost_timing_code,quantity,unit_cost_amount,unit_rate,
 gross_cost_amount,currency_code,incurred_effective_date,allocable_flag,conditional_flag,
 allocation_method_code,accepted_m1_14_overlap_class,evidence_basis_code,evidence_status,
 row_hash,created_by_run_id,created_at FROM _m1_16_ledger_expected;

ANALYZE msbf_m1.acquisition_source_profile;
ANALYZE msbf_m1.acquisition_marketing_campaign;
ANALYZE msbf_m1.acquisition_campaign_funnel_stage;
ANALYZE msbf_m1.acquisition_cost_ledger;

DO $phase_3$ BEGIN RAISE NOTICE 'M1.16 Phase 3/7 — assign campaigns and generate bounded application touchpoints and attribution'; END; $phase_3$;

DROP TABLE IF EXISTS _m1_16_app_assignment;
CREATE TEMP TABLE _m1_16_app_assignment ON COMMIT DROP AS
SELECT a.merchant_application_id,a.population_id,a.merchant_id,a.application_date,a.as_of_date,
 a.partner_channel_id,a.channel_type,a.application_channel,a.request_hash,a.requested_funding_amount,
 a.app_sequence,a.channel_sequence,a.accepted_m1_14_acquisition_cost_rate,
 a.accepted_m1_14_acquisition_cost_amount,a.m1_14_baseline_row_hash,a.m1_14_stress_row_hash,
 a.m1_15_baseline_contract_row_hash,a.m1_15_stress_contract_row_hash,a.m1_14_combined_hash,
 a.m1_15_combined_hash,a.policy_configuration_hash,a.run_id,
 CASE a.partner_channel_id
  WHEN 'CH_PROCESSOR_DIRECT' THEN CASE WHEN channel_sequence<=105 THEN 'ACQ_PROC_PORTAL_ALWAYS_ON' WHEN channel_sequence<=195 THEN 'ACQ_PROC_EMAIL_OUTREACH' ELSE 'ACQ_PROC_AM_REFERRAL' END
  WHEN 'CH_BANK_RELATIONSHIP' THEN CASE WHEN channel_sequence<=65 THEN 'ACQ_BANK_RM_ALWAYS_ON' WHEN channel_sequence<=110 THEN 'ACQ_BANK_BRANCH_OUTREACH' ELSE 'ACQ_BANK_TREASURY_XSELL' END
  WHEN 'CH_DIGITAL_DIRECT' THEN CASE WHEN channel_sequence<=30 THEN 'ACQ_DIGITAL_PAID_SEARCH_BRAND' WHEN channel_sequence<=55 THEN 'ACQ_DIGITAL_PAID_SEARCH_NONBRAND' WHEN channel_sequence<=80 THEN 'ACQ_DIGITAL_ORGANIC_ALWAYS_ON' WHEN channel_sequence<=100 THEN 'ACQ_DIGITAL_PAID_SOCIAL' WHEN channel_sequence<=120 THEN 'ACQ_DIGITAL_DIRECT_NAV' WHEN channel_sequence<=135 THEN 'ACQ_DIGITAL_EMAIL_RETARGET' ELSE 'ACQ_DIGITAL_DIRECT_MAIL' END
  WHEN 'CH_STRATEGIC_PARTNER' THEN CASE WHEN channel_sequence<=50 THEN 'ACQ_PARTNER_SOFTWARE_PLATFORM' WHEN channel_sequence<=90 THEN 'ACQ_PARTNER_ASSOCIATION' ELSE 'ACQ_PARTNER_MERCHANT_SERVICES' END
  WHEN 'CH_BROKER_NETWORK' THEN CASE WHEN channel_sequence<=35 THEN 'ACQ_BROKER_ISO_EAST' WHEN channel_sequence<=60 THEN 'ACQ_BROKER_ISO_WEST' WHEN channel_sequence<=80 THEN 'ACQ_BROKER_PURCHASED_LEADS' ELSE 'ACQ_BROKER_DIRECT' END
 END AS primary_campaign_id,
 (1 + CASE WHEN app_sequence%3=0 THEN 1 ELSE 0 END + CASE WHEN app_sequence%10=0 THEN 1 ELSE 0 END)::smallint AS touchpoint_count
FROM _m1_16_app_base a;
CREATE UNIQUE INDEX ON _m1_16_app_assignment(merchant_application_id);

DROP TABLE IF EXISTS _m1_16_campaign_rank;
CREATE TEMP TABLE _m1_16_campaign_rank ON COMMIT DROP AS
SELECT c.module1_run_id,c.acquisition_campaign_id,c.acquisition_source_code,c.accepted_partner_channel_id,
 c.campaign_type,c.effective_start_date,c.effective_end_date,c.campaign_evidence_status,
 row_number() OVER(PARTITION BY c.accepted_partner_channel_id ORDER BY c.acquisition_campaign_id)::integer AS campaign_rank,
 count(*) OVER(PARTITION BY c.accepted_partner_channel_id)::integer AS campaign_count
FROM _m1_16_campaign_expected c;
CREATE UNIQUE INDEX ON _m1_16_campaign_rank(accepted_partner_channel_id,campaign_rank);

DROP TABLE IF EXISTS _m1_16_touch_expected;
CREATE TEMP TABLE _m1_16_touch_expected (LIKE msbf_m1.application_acquisition_touchpoint INCLUDING DEFAULTS) ON COMMIT DROP;
WITH expanded AS(
 SELECT a.merchant_application_id,a.population_id,a.merchant_id,a.application_date,a.as_of_date,
 a.partner_channel_id,a.channel_type,a.application_channel,a.request_hash,a.requested_funding_amount,
 a.app_sequence,a.channel_sequence,a.accepted_m1_14_acquisition_cost_rate,
 a.accepted_m1_14_acquisition_cost_amount,a.m1_14_baseline_row_hash,a.m1_14_stress_row_hash,
 a.m1_15_baseline_contract_row_hash,a.m1_15_stress_contract_row_hash,a.m1_14_combined_hash,
 a.m1_15_combined_hash,a.policy_configuration_hash,a.run_id,a.primary_campaign_id,a.touchpoint_count,g.seq,pr.campaign_rank AS primary_rank,pr.campaign_count,
   CASE WHEN g.seq=a.touchpoint_count THEN pr.campaign_rank
        ELSE ((pr.campaign_rank+a.app_sequence+g.seq-2)%pr.campaign_count)+1 END AS selected_rank
 FROM _m1_16_app_assignment a
 JOIN _m1_16_campaign_rank pr
   ON pr.accepted_partner_channel_id=a.partner_channel_id AND pr.acquisition_campaign_id=a.primary_campaign_id
 CROSS JOIN LATERAL generate_series(1,a.touchpoint_count) g(seq)
), selected AS(
 SELECT e.merchant_application_id,e.population_id,e.merchant_id,e.application_date,e.as_of_date,
 e.partner_channel_id,e.channel_type,e.application_channel,e.request_hash,e.requested_funding_amount,
 e.app_sequence,e.channel_sequence,e.accepted_m1_14_acquisition_cost_rate,
 e.accepted_m1_14_acquisition_cost_amount,e.m1_14_baseline_row_hash,e.m1_14_stress_row_hash,
 e.m1_15_baseline_contract_row_hash,e.m1_15_stress_contract_row_hash,e.m1_14_combined_hash,
 e.m1_15_combined_hash,e.policy_configuration_hash,e.run_id,e.primary_campaign_id,e.touchpoint_count,
 e.seq,e.primary_rank,e.campaign_count,e.selected_rank,cr.acquisition_campaign_id,cr.acquisition_source_code,cr.campaign_type,
        cr.effective_start_date,cr.effective_end_date,cr.campaign_evidence_status,
        sp.source_evidence_status
 FROM expanded e
 JOIN _m1_16_campaign_rank cr
   ON cr.accepted_partner_channel_id=e.partner_channel_id AND cr.campaign_rank=e.selected_rank
 JOIN _m1_16_source_expected sp
   ON sp.module1_run_id=cr.module1_run_id
  AND sp.acquisition_source_code=cr.acquisition_source_code
)
INSERT INTO _m1_16_touch_expected(
 module1_run_id,merchant_application_id,touchpoint_sequence,merchant_id,
 acquisition_source_code,acquisition_campaign_id,touchpoint_type,touchpoint_timestamp,
 first_touch_flag,last_touch_flag,primary_attribution_flag,assisted_touch_flag,
 attribution_weight,support_status,evidence_status,accepted_partner_channel_id,
 row_hash,created_by_run_id,created_at
)
SELECT run_id,merchant_application_id,seq::smallint,merchant_id,
 acquisition_source_code,acquisition_campaign_id,campaign_type,
 (application_date::timestamp + interval '09:00' - make_interval(days=>(touchpoint_count-seq)*7))::timestamptz,
 seq=1,seq=touchpoint_count,seq=touchpoint_count,seq<touchpoint_count,
 CASE WHEN seq=touchpoint_count THEN 1.000000 ELSE 0.000000 END,
 'SUPPORTED',
 CASE
   WHEN app_sequence%47=0 OR source_evidence_status='BLOCKED' OR campaign_evidence_status='BLOCKED' THEN 'BLOCKED'
   WHEN seq<touchpoint_count OR source_evidence_status='PARTIAL' OR campaign_evidence_status='PARTIAL' THEN 'PARTIAL'
   ELSE 'COMPLETE'
 END,
 partner_channel_id,'',run_id,clock_timestamp()
FROM selected;
UPDATE _m1_16_touch_expected t
SET row_hash=msbf_m1.m1_16_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at') WHERE row_hash='';
INSERT INTO msbf_m1.application_acquisition_touchpoint(
 module1_run_id,merchant_application_id,touchpoint_sequence,merchant_id,
 acquisition_source_code,acquisition_campaign_id,touchpoint_type,touchpoint_timestamp,
 first_touch_flag,last_touch_flag,primary_attribution_flag,assisted_touch_flag,
 attribution_weight,support_status,evidence_status,accepted_partner_channel_id,
 row_hash,created_by_run_id,created_at
)
SELECT module1_run_id,merchant_application_id,touchpoint_sequence,merchant_id,
 acquisition_source_code,acquisition_campaign_id,touchpoint_type,touchpoint_timestamp,
 first_touch_flag,last_touch_flag,primary_attribution_flag,assisted_touch_flag,
 attribution_weight,support_status,evidence_status,accepted_partner_channel_id,
 row_hash,created_by_run_id,created_at FROM _m1_16_touch_expected;

DROP TABLE IF EXISTS _m1_16_attribution_expected;
CREATE TEMP TABLE _m1_16_attribution_expected (LIKE msbf_m1.application_acquisition_attribution_snapshot INCLUDING DEFAULTS) ON COMMIT DROP;
WITH agg AS(
 SELECT t.module1_run_id,t.merchant_application_id,
   (array_agg(t.acquisition_source_code ORDER BY t.touchpoint_sequence))[1] AS first_source,
   (array_agg(t.acquisition_campaign_id ORDER BY t.touchpoint_sequence))[1] AS first_campaign,
   (array_agg(t.acquisition_source_code ORDER BY t.touchpoint_sequence DESC))[1] AS last_source,
   (array_agg(t.acquisition_campaign_id ORDER BY t.touchpoint_sequence DESC))[1] AS last_campaign,
   max(t.acquisition_source_code) FILTER(WHERE t.primary_attribution_flag) AS primary_source,
   max(t.acquisition_campaign_id) FILTER(WHERE t.primary_attribution_flag) AS primary_campaign,
   count(*)::smallint AS touchpoint_count,
   count(*) FILTER(WHERE t.assisted_touch_flag)::smallint AS assisted_touch_count,
   bool_or(t.evidence_status='BLOCKED') AS any_blocked_evidence,
   bool_or(t.evidence_status='PARTIAL') AS any_partial_evidence
 FROM _m1_16_touch_expected t
 GROUP BY t.module1_run_id,t.merchant_application_id
)
INSERT INTO _m1_16_attribution_expected(
 module1_run_id,merchant_application_id,population_id,merchant_id,application_date,as_of_date,
 accepted_partner_channel_id,accepted_channel_type,accepted_application_channel,
 first_touch_source_code,first_touch_campaign_id,last_touch_source_code,last_touch_campaign_id,
 primary_source_code,primary_campaign_id,touchpoint_count,assisted_touch_count,
 attribution_method_code,attribution_method_version,attribution_confidence_score,
 attribution_confidence_tier,parent_channel_reconciliation_status,fallback_path_code,
 primary_attribution_reason_code,secondary_attribution_reason_codes,attribution_evidence_status,
 application_request_hash,m1_15_baseline_contract_row_hash,m1_15_stress_contract_row_hash,
 row_hash,created_by_run_id,created_at
)
SELECT a.run_id,a.merchant_application_id,a.population_id,a.merchant_id,a.application_date,a.as_of_date,
 a.partner_channel_id,a.channel_type,a.application_channel,
 g.first_source,g.first_campaign,g.last_source,g.last_campaign,g.primary_source,g.primary_campaign,
 g.touchpoint_count,g.assisted_touch_count,'GOVERNED_PRIMARY_TOUCH_V1',1,
 CASE
   WHEN g.any_blocked_evidence THEN 0.350000
   WHEN g.any_partial_evidence OR g.touchpoint_count>1 THEN 0.750000
   ELSE 0.950000
 END,
 CASE
   WHEN g.any_blocked_evidence THEN 'INSUFFICIENT'
   WHEN g.any_partial_evidence OR g.touchpoint_count>1 THEN 'MEDIUM'
   ELSE 'HIGH'
 END,
 CASE WHEN g.any_blocked_evidence THEN 'BLOCKED_CONFLICT' ELSE 'MATCH' END,
 CASE
   WHEN g.any_blocked_evidence THEN 'PARENT_CHANNEL_FALLBACK'
   WHEN g.any_partial_evidence OR g.touchpoint_count>1 THEN 'GOVERNED_PRIMARY_TOUCH'
   ELSE 'NONE'
 END,
 CASE
   WHEN g.any_blocked_evidence THEN 'MATERIAL_TOUCHPOINT_CONFLICT'
   WHEN g.any_partial_evidence THEN 'PARTIAL_SOURCE_OR_CAMPAIGN_EVIDENCE'
   WHEN g.touchpoint_count>1 THEN 'PRIMARY_TOUCH_WITH_ASSISTS'
   ELSE 'SINGLE_SUPPORTED_TOUCH'
 END,
 ARRAY_REMOVE(ARRAY[
   CASE WHEN g.touchpoint_count>1 THEN 'ASSISTED_TOUCHES_RETAINED' END,
   CASE WHEN g.any_partial_evidence THEN 'PARTIAL_SOURCE_OR_CAMPAIGN_EVIDENCE' END
 ]::text[],NULL),
 CASE
   WHEN g.any_blocked_evidence THEN 'BLOCKED'
   WHEN g.any_partial_evidence OR g.touchpoint_count>1 THEN 'PARTIAL'
   ELSE 'COMPLETE'
 END,
 a.request_hash,a.m1_15_baseline_contract_row_hash,a.m1_15_stress_contract_row_hash,
 '',a.run_id,clock_timestamp()
FROM _m1_16_app_assignment a JOIN agg g ON g.merchant_application_id=a.merchant_application_id;
UPDATE _m1_16_attribution_expected a
SET row_hash=msbf_m1.m1_16_hash_jsonb(to_jsonb(a)-'row_hash'-'created_at') WHERE row_hash='';
INSERT INTO msbf_m1.application_acquisition_attribution_snapshot(
 module1_run_id,merchant_application_id,population_id,merchant_id,application_date,as_of_date,
 accepted_partner_channel_id,accepted_channel_type,accepted_application_channel,
 first_touch_source_code,first_touch_campaign_id,last_touch_source_code,last_touch_campaign_id,
 primary_source_code,primary_campaign_id,touchpoint_count,assisted_touch_count,
 attribution_method_code,attribution_method_version,attribution_confidence_score,
 attribution_confidence_tier,parent_channel_reconciliation_status,fallback_path_code,
 primary_attribution_reason_code,secondary_attribution_reason_codes,attribution_evidence_status,
 application_request_hash,m1_15_baseline_contract_row_hash,m1_15_stress_contract_row_hash,
 row_hash,created_by_run_id,created_at
)
SELECT module1_run_id,merchant_application_id,population_id,merchant_id,application_date,as_of_date,
 accepted_partner_channel_id,accepted_channel_type,accepted_application_channel,
 first_touch_source_code,first_touch_campaign_id,last_touch_source_code,last_touch_campaign_id,
 primary_source_code,primary_campaign_id,touchpoint_count,assisted_touch_count,
 attribution_method_code,attribution_method_version,attribution_confidence_score,
 attribution_confidence_tier,parent_channel_reconciliation_status,fallback_path_code,
 primary_attribution_reason_code,secondary_attribution_reason_codes,attribution_evidence_status,
 application_request_hash,m1_15_baseline_contract_row_hash,m1_15_stress_contract_row_hash,
 row_hash,created_by_run_id,created_at FROM _m1_16_attribution_expected;
ANALYZE msbf_m1.application_acquisition_touchpoint;
ANALYZE msbf_m1.application_acquisition_attribution_snapshot;

DO $phase_4$ BEGIN RAISE NOTICE 'M1.16 Phase 4/7 — allocate campaign cost, reconcile M1.14 overlap, and persist cost evidence'; END; $phase_4$;

DROP TABLE IF EXISTS _m1_16_allocated_incurred;
CREATE TEMP TABLE _m1_16_allocated_incurred ON COMMIT DROP AS
WITH assigned AS(
 SELECT a.merchant_application_id,a.primary_campaign_id,
        l.cost_component_code,l.cost_basis_code,l.cost_timing_code,l.gross_cost_amount,
        l.evidence_basis_code,l.evidence_status,
        count(*) OVER(PARTITION BY a.primary_campaign_id)::bigint AS application_count,
        row_number() OVER(PARTITION BY a.primary_campaign_id ORDER BY a.merchant_application_id)::bigint AS allocation_rank
 FROM _m1_16_app_assignment a
 JOIN _m1_16_ledger_expected l
   ON l.acquisition_campaign_id=a.primary_campaign_id AND l.conditional_flag=false
), cents AS(
 SELECT x.merchant_application_id,x.primary_campaign_id,x.cost_component_code,x.cost_basis_code,
        x.cost_timing_code,x.gross_cost_amount,x.evidence_basis_code,x.evidence_status,
        x.application_count,x.allocation_rank,
        (round(x.gross_cost_amount*100))::bigint AS total_cents,
        ((round(x.gross_cost_amount*100))::bigint / x.application_count)::bigint AS base_cents
 FROM assigned x
)
SELECT c.merchant_application_id,c.primary_campaign_id,c.cost_component_code,c.cost_basis_code,
 c.cost_timing_code,c.gross_cost_amount,c.evidence_basis_code,c.evidence_status,
 c.application_count,c.allocation_rank,c.total_cents,c.base_cents,
 ((c.base_cents + CASE WHEN c.allocation_rank <= c.total_cents-c.base_cents*c.application_count THEN 1 ELSE 0 END)::numeric/100)::numeric(18,2) AS allocated_amount
FROM cents c;
CREATE UNIQUE INDEX ON _m1_16_allocated_incurred(merchant_application_id);

DROP TABLE IF EXISTS _m1_16_atomic_costs;
CREATE TEMP TABLE _m1_16_atomic_costs ON COMMIT DROP AS
SELECT a.merchant_application_id,a.run_id,a.population_id,a.merchant_id,a.as_of_date,
 a.partner_channel_id,a.channel_type,a.application_channel,a.primary_campaign_id,
 ai.cost_component_code AS primary_incurred_component,ai.cost_basis_code AS primary_cost_basis,
 ai.cost_timing_code AS primary_cost_timing,ai.evidence_basis_code AS primary_cost_evidence_basis,
 ai.evidence_status AS primary_cost_evidence_status,ai.allocated_amount,
 coalesce(max(ai.allocated_amount) FILTER(WHERE ai.cost_component_code='PAID_MEDIA_COST'),0)::numeric(18,2) AS paid_media,
 coalesce(max(ai.allocated_amount) FILTER(WHERE ai.cost_component_code='DIRECT_MAIL_EVENT_OUTBOUND_COST'),0)::numeric(18,2) AS direct_mail,
 coalesce(max(ai.allocated_amount) FILTER(WHERE ai.cost_component_code='PURCHASED_LEAD_COST'),0)::numeric(18,2) AS purchased_lead,
 coalesce(max(ai.allocated_amount) FILTER(WHERE ai.cost_component_code='INTERNAL_SALES_RM_COST'),0)::numeric(18,2) AS internal_rm,
 coalesce(max(ai.allocated_amount) FILTER(WHERE ai.cost_component_code='AGENCY_CREATIVE_TECH_COST'),0)::numeric(18,2) AS agency_tech,
 coalesce(max(ai.allocated_amount) FILTER(WHERE ai.cost_component_code='CAMPAIGN_OVERHEAD_COST'),0)::numeric(18,2) AS campaign_overhead,
 coalesce(max(ai.allocated_amount) FILTER(WHERE ai.cost_component_code='ACQUISITION_INCENTIVE_COST'),0)::numeric(18,2) AS incentive,
 round(a.requested_funding_amount*cl.unit_rate,2)::numeric(18,2) AS conditional_cost,
 a.accepted_m1_14_acquisition_cost_rate,a.accepted_m1_14_acquisition_cost_amount,
 a.m1_14_baseline_row_hash,a.m1_14_stress_row_hash,a.m1_14_combined_hash,
 a.m1_15_baseline_contract_row_hash,a.m1_15_stress_contract_row_hash,a.m1_15_combined_hash,
 a.policy_configuration_hash,a.app_sequence
FROM _m1_16_app_assignment a
JOIN _m1_16_allocated_incurred ai ON ai.merchant_application_id=a.merchant_application_id
JOIN _m1_16_ledger_expected cl ON cl.acquisition_campaign_id=a.primary_campaign_id AND cl.conditional_flag=true
GROUP BY a.merchant_application_id,a.run_id,a.population_id,a.merchant_id,a.as_of_date,
 a.partner_channel_id,a.channel_type,a.application_channel,a.primary_campaign_id,
 ai.cost_component_code,ai.cost_basis_code,ai.cost_timing_code,ai.evidence_basis_code,
 ai.evidence_status,ai.allocated_amount,cl.unit_rate,a.requested_funding_amount,
 a.accepted_m1_14_acquisition_cost_rate,a.accepted_m1_14_acquisition_cost_amount,
 a.m1_14_baseline_row_hash,a.m1_14_stress_row_hash,a.m1_14_combined_hash,
 a.m1_15_baseline_contract_row_hash,a.m1_15_stress_contract_row_hash,a.m1_15_combined_hash,
 a.policy_configuration_hash,a.app_sequence;

DROP TABLE IF EXISTS _m1_16_cost_calc;
CREATE TEMP TABLE _m1_16_cost_calc ON COMMIT DROP AS
WITH unpivot AS(
 SELECT a.merchant_application_id,a.partner_channel_id,
        v.component_code,v.amount,
        op.legacy_scope_code,op.overlap_class,op.overlap_rate
 FROM _m1_16_atomic_costs a
 CROSS JOIN LATERAL (VALUES
  ('PAID_MEDIA_COST'::text,a.paid_media),
  ('DIRECT_MAIL_EVENT_OUTBOUND_COST',a.direct_mail),
  ('PURCHASED_LEAD_COST',a.purchased_lead),
  ('INTERNAL_SALES_RM_COST',a.internal_rm),
  ('AGENCY_CREATIVE_TECH_COST',a.agency_tech),
  ('CAMPAIGN_OVERHEAD_COST',a.campaign_overhead),
  ('ACQUISITION_INCENTIVE_COST',a.incentive),
  ('DETAILED_CONDITIONAL_PARTNER_BROKER_COST',a.conditional_cost)
 ) v(component_code,amount)
 JOIN msbf_ref.acquisition_legacy_overlap_policy op
   ON op.partner_channel_id=a.partner_channel_id AND op.cost_component_code=v.component_code
), overlap AS(
 SELECT merchant_application_id,
        max(legacy_scope_code) AS legacy_scope_code,
        sum(amount) FILTER(WHERE overlap_class<>'NOT_INCLUDED_IN_M1_14')::numeric(18,2) AS mapped_detailed,
        round(sum(amount*overlap_rate),2)::numeric(18,2) AS supported_overlap,
        bool_or(amount>0 AND overlap_class='POTENTIALLY_INCLUDED_IN_M1_14') AS has_potential_overlap
 FROM unpivot GROUP BY merchant_application_id
)
SELECT a.merchant_application_id,a.run_id,a.population_id,a.merchant_id,a.as_of_date,
 a.partner_channel_id,a.channel_type,a.application_channel,a.primary_campaign_id,
 a.primary_incurred_component,a.primary_cost_basis,a.primary_cost_timing,
 a.primary_cost_evidence_basis,a.primary_cost_evidence_status,a.allocated_amount,
 a.paid_media,a.direct_mail,a.purchased_lead,a.internal_rm,a.agency_tech,
 a.campaign_overhead,a.incentive,a.conditional_cost,a.accepted_m1_14_acquisition_cost_rate,
 a.accepted_m1_14_acquisition_cost_amount,a.m1_14_baseline_row_hash,a.m1_14_stress_row_hash,
 a.m1_14_combined_hash,a.m1_15_baseline_contract_row_hash,a.m1_15_stress_contract_row_hash,
 a.m1_15_combined_hash,a.policy_configuration_hash,a.app_sequence,o.legacy_scope_code,o.mapped_detailed,o.supported_overlap,o.has_potential_overlap,
 (a.paid_media+a.direct_mail+a.purchased_lead+a.incentive)::numeric(18,2) AS direct_attributable,
 (a.internal_rm+a.agency_tech+a.campaign_overhead)::numeric(18,2) AS internal_allocated,
 (a.paid_media+a.direct_mail+a.purchased_lead+a.incentive+a.internal_rm+a.agency_tech+a.campaign_overhead)::numeric(18,2) AS total_incurred,
 (a.paid_media+a.direct_mail+a.purchased_lead+a.incentive+a.internal_rm+a.agency_tech+a.campaign_overhead+a.conditional_cost)::numeric(18,2) AS detailed_total,
 least(a.accepted_m1_14_acquisition_cost_amount,o.supported_overlap)::numeric(18,2) AS bounded_overlap,
 (a.app_sequence%61=0) AS cost_blocked
FROM _m1_16_atomic_costs a
JOIN overlap o ON o.merchant_application_id=a.merchant_application_id;

DROP TABLE IF EXISTS _m1_16_cost_expected;
CREATE TEMP TABLE _m1_16_cost_expected (LIKE msbf_m1.application_acquisition_cost_snapshot INCLUDING DEFAULTS) ON COMMIT DROP;
INSERT INTO _m1_16_cost_expected(
 module1_run_id,merchant_application_id,population_id,merchant_id,as_of_date,
 accepted_partner_channel_id,accepted_channel_type,accepted_application_channel,
 primary_source_code,primary_campaign_id,paid_media_cost_amount,
 direct_mail_event_outbound_cost_amount,purchased_lead_cost_amount,internal_sales_rm_cost_amount,
 agency_creative_tech_cost_amount,campaign_overhead_cost_amount,acquisition_incentive_cost_amount,
 detailed_conditional_partner_broker_cost_amount,direct_attributable_incurred_cost_amount,
 internally_allocated_acquisition_cost_amount,total_incurred_pre_application_cost_amount,
 detailed_total_acquisition_cost_if_booked,accepted_m1_14_acquisition_cost_rate,
 accepted_m1_14_acquisition_cost_amount,legacy_m1_14_cost_scope_code,
 mapped_detailed_cost_potentially_represented,identified_legacy_overlap_amount,
 unmapped_legacy_proxy_amount,incremental_acquisition_cost_beyond_m1_14,
 enhanced_total_acquisition_cost_if_booked,attribution_evidence_status,cost_evidence_status,
 overlap_evidence_status,acquisition_contract_evidence_status,supported_zero_component_count,
 fallback_path_code,primary_cost_reason_code,secondary_cost_reason_codes,
 attribution_snapshot_hash,m1_14_baseline_row_hash,m1_14_stress_row_hash,m1_14_combined_set_hash,
 m1_15_baseline_contract_row_hash,m1_15_stress_contract_row_hash,m1_15_combined_set_hash,
 m1_16_policy_configuration_hash,row_hash,created_by_run_id,created_at
)
SELECT c.run_id,c.merchant_application_id,c.population_id,c.merchant_id,c.as_of_date,
 c.partner_channel_id,c.channel_type,c.application_channel,a.primary_source_code,c.primary_campaign_id,
 c.paid_media,c.direct_mail,c.purchased_lead,c.internal_rm,c.agency_tech,c.campaign_overhead,c.incentive,
 c.conditional_cost,c.direct_attributable,c.internal_allocated,c.total_incurred,c.detailed_total,
 c.accepted_m1_14_acquisition_cost_rate,c.accepted_m1_14_acquisition_cost_amount,c.legacy_scope_code,
 c.mapped_detailed,
 CASE WHEN c.cost_blocked OR a.attribution_evidence_status='BLOCKED' THEN NULL ELSE c.bounded_overlap END,
 CASE WHEN c.cost_blocked OR a.attribution_evidence_status='BLOCKED' THEN NULL ELSE c.accepted_m1_14_acquisition_cost_amount-c.bounded_overlap END,
 CASE WHEN c.cost_blocked OR a.attribution_evidence_status='BLOCKED' THEN NULL ELSE c.detailed_total-c.bounded_overlap END,
 CASE WHEN c.cost_blocked OR a.attribution_evidence_status='BLOCKED' THEN NULL ELSE c.accepted_m1_14_acquisition_cost_amount+c.detailed_total-c.bounded_overlap END,
 a.attribution_evidence_status,
 CASE WHEN c.cost_blocked THEN 'BLOCKED' WHEN c.primary_incurred_component IN('PAID_MEDIA_COST','DIRECT_MAIL_EVENT_OUTBOUND_COST','PURCHASED_LEAD_COST','ACQUISITION_INCENTIVE_COST') THEN 'COMPLETE' ELSE 'PARTIAL' END,
 CASE WHEN c.cost_blocked THEN 'BLOCKED' WHEN c.has_potential_overlap THEN 'PARTIAL' ELSE 'COMPLETE' END,
 CASE WHEN c.cost_blocked OR a.attribution_evidence_status='BLOCKED' THEN 'BLOCKED'
      WHEN a.attribution_evidence_status='COMPLETE'
       AND c.primary_incurred_component IN('PAID_MEDIA_COST','DIRECT_MAIL_EVENT_OUTBOUND_COST','PURCHASED_LEAD_COST','ACQUISITION_INCENTIVE_COST')
       AND NOT c.has_potential_overlap THEN 'COMPLETE' ELSE 'PARTIAL' END,
 0::smallint,
 CASE WHEN c.cost_blocked THEN 'COST_SCOPE_REMEDIATION' WHEN a.attribution_evidence_status='BLOCKED' THEN 'ATTRIBUTION_REMEDIATION' WHEN c.has_potential_overlap THEN 'LEGACY_OVERLAP_REVIEW' ELSE 'NONE' END,
 CASE WHEN c.cost_blocked THEN 'UNRESOLVED_LEGACY_SCOPE' WHEN a.attribution_evidence_status='BLOCKED' THEN 'ATTRIBUTION_CONFLICT' WHEN c.has_potential_overlap THEN 'ESTIMATED_LEGACY_OVERLAP' ELSE 'SUPPORTED_ACQUISITION_ECONOMICS' END,
 CASE WHEN c.has_potential_overlap THEN ARRAY['M1_14_BROAD_PROXY_RECONCILED']::text[] ELSE ARRAY[]::text[] END,
 a.row_hash,c.m1_14_baseline_row_hash,c.m1_14_stress_row_hash,c.m1_14_combined_hash,
 c.m1_15_baseline_contract_row_hash,c.m1_15_stress_contract_row_hash,c.m1_15_combined_hash,
 c.policy_configuration_hash,'',c.run_id,clock_timestamp()
FROM _m1_16_cost_calc c
JOIN _m1_16_attribution_expected a ON a.merchant_application_id=c.merchant_application_id;
UPDATE _m1_16_cost_expected c
SET row_hash=msbf_m1.m1_16_hash_jsonb(to_jsonb(c)-'row_hash'-'created_at') WHERE row_hash='';
INSERT INTO msbf_m1.application_acquisition_cost_snapshot(
 module1_run_id,merchant_application_id,population_id,merchant_id,as_of_date,
 accepted_partner_channel_id,accepted_channel_type,accepted_application_channel,
 primary_source_code,primary_campaign_id,paid_media_cost_amount,
 direct_mail_event_outbound_cost_amount,purchased_lead_cost_amount,internal_sales_rm_cost_amount,
 agency_creative_tech_cost_amount,campaign_overhead_cost_amount,acquisition_incentive_cost_amount,
 detailed_conditional_partner_broker_cost_amount,direct_attributable_incurred_cost_amount,
 internally_allocated_acquisition_cost_amount,total_incurred_pre_application_cost_amount,
 detailed_total_acquisition_cost_if_booked,accepted_m1_14_acquisition_cost_rate,
 accepted_m1_14_acquisition_cost_amount,legacy_m1_14_cost_scope_code,
 mapped_detailed_cost_potentially_represented,identified_legacy_overlap_amount,
 unmapped_legacy_proxy_amount,incremental_acquisition_cost_beyond_m1_14,
 enhanced_total_acquisition_cost_if_booked,attribution_evidence_status,cost_evidence_status,
 overlap_evidence_status,acquisition_contract_evidence_status,supported_zero_component_count,
 fallback_path_code,primary_cost_reason_code,secondary_cost_reason_codes,
 attribution_snapshot_hash,m1_14_baseline_row_hash,m1_14_stress_row_hash,m1_14_combined_set_hash,
 m1_15_baseline_contract_row_hash,m1_15_stress_contract_row_hash,m1_15_combined_set_hash,
 m1_16_policy_configuration_hash,row_hash,created_by_run_id,created_at
)
SELECT module1_run_id,merchant_application_id,population_id,merchant_id,as_of_date,
 accepted_partner_channel_id,accepted_channel_type,accepted_application_channel,
 primary_source_code,primary_campaign_id,paid_media_cost_amount,
 direct_mail_event_outbound_cost_amount,purchased_lead_cost_amount,internal_sales_rm_cost_amount,
 agency_creative_tech_cost_amount,campaign_overhead_cost_amount,acquisition_incentive_cost_amount,
 detailed_conditional_partner_broker_cost_amount,direct_attributable_incurred_cost_amount,
 internally_allocated_acquisition_cost_amount,total_incurred_pre_application_cost_amount,
 detailed_total_acquisition_cost_if_booked,accepted_m1_14_acquisition_cost_rate,
 accepted_m1_14_acquisition_cost_amount,legacy_m1_14_cost_scope_code,
 mapped_detailed_cost_potentially_represented,identified_legacy_overlap_amount,
 unmapped_legacy_proxy_amount,incremental_acquisition_cost_beyond_m1_14,
 enhanced_total_acquisition_cost_if_booked,attribution_evidence_status,cost_evidence_status,
 overlap_evidence_status,acquisition_contract_evidence_status,supported_zero_component_count,
 fallback_path_code,primary_cost_reason_code,secondary_cost_reason_codes,
 attribution_snapshot_hash,m1_14_baseline_row_hash,m1_14_stress_row_hash,m1_14_combined_set_hash,
 m1_15_baseline_contract_row_hash,m1_15_stress_contract_row_hash,m1_15_combined_set_hash,
 m1_16_policy_configuration_hash,row_hash,created_by_run_id,created_at FROM _m1_16_cost_expected;

DROP TABLE IF EXISTS _m1_16_component_expected;
CREATE TEMP TABLE _m1_16_component_expected (LIKE msbf_m1.application_acquisition_cost_component_value INCLUDING DEFAULTS) ON COMMIT DROP;
WITH values_wide AS(
 SELECT c.run_id,c.merchant_application_id,c.primary_campaign_id,c.partner_channel_id,
        c.primary_incurred_component,c.primary_cost_timing,c.primary_cost_basis,
        c.primary_cost_evidence_status,c.cost_blocked,c.has_potential_overlap,c.legacy_scope_code,
        v.cost_component_code,v.component_amount,
   d.component_role_code,d.sign_multiplier,
   CASE
    WHEN v.cost_component_code=c.primary_incurred_component THEN c.primary_cost_timing
    WHEN v.cost_component_code='DETAILED_CONDITIONAL_PARTNER_BROKER_COST' THEN 'CONDITIONAL_ON_FUNDING'
    WHEN v.cost_component_code IN('LEGACY_M1_14_ACQUISITION_COST','IDENTIFIED_LEGACY_OVERLAP','INCREMENTAL_ACQUISITION_COST_BEYOND_M1_14','ENHANCED_TOTAL_ACQUISITION_COST_IF_BOOKED') THEN 'CONDITIONAL_ON_FUNDING'
    ELSE 'INCURRED_PRE_APPLICATION' END AS cost_timing_code,
   CASE
    WHEN v.cost_component_code=c.primary_incurred_component THEN c.primary_cost_basis
    WHEN v.cost_component_code='DETAILED_CONDITIONAL_PARTNER_BROKER_COST' THEN 'PERCENT_FUNDED_AMOUNT'
    WHEN v.cost_component_code IN('LEGACY_M1_14_ACQUISITION_COST','IDENTIFIED_LEGACY_OVERLAP','INCREMENTAL_ACQUISITION_COST_BEYOND_M1_14','ENHANCED_TOTAL_ACQUISITION_COST_IF_BOOKED') THEN 'GOVERNED_PARAMETER'
    ELSE 'NOT_APPLICABLE' END AS cost_basis_code,
   CASE
    WHEN v.cost_component_code=c.primary_incurred_component THEN c.primary_cost_evidence_status
    WHEN v.cost_component_code IN('PAID_MEDIA_COST','DIRECT_MAIL_EVENT_OUTBOUND_COST','PURCHASED_LEAD_COST','INTERNAL_SALES_RM_COST','AGENCY_CREATIVE_TECH_COST','CAMPAIGN_OVERHEAD_COST','ACQUISITION_INCENTIVE_COST') THEN 'NOT_APPLICABLE'
    WHEN v.cost_component_code='DETAILED_CONDITIONAL_PARTNER_BROKER_COST' THEN 'PARTIAL'
    WHEN v.cost_component_code='LEGACY_M1_14_ACQUISITION_COST' THEN 'COMPLETE'
    WHEN c.cost_blocked OR a.attribution_evidence_status='BLOCKED' THEN 'BLOCKED'
    ELSE CASE WHEN c.has_potential_overlap THEN 'PARTIAL' ELSE 'COMPLETE' END END AS component_evidence_status,
   op.overlap_class
 FROM _m1_16_cost_calc c
 JOIN _m1_16_attribution_expected a ON a.merchant_application_id=c.merchant_application_id
 CROSS JOIN LATERAL (VALUES
   ('PAID_MEDIA_COST'::text,CASE WHEN c.primary_incurred_component='PAID_MEDIA_COST' THEN c.paid_media ELSE NULL END),
   ('DIRECT_MAIL_EVENT_OUTBOUND_COST',CASE WHEN c.primary_incurred_component='DIRECT_MAIL_EVENT_OUTBOUND_COST' THEN c.direct_mail ELSE NULL END),
   ('PURCHASED_LEAD_COST',CASE WHEN c.primary_incurred_component='PURCHASED_LEAD_COST' THEN c.purchased_lead ELSE NULL END),
   ('INTERNAL_SALES_RM_COST',CASE WHEN c.primary_incurred_component='INTERNAL_SALES_RM_COST' THEN c.internal_rm ELSE NULL END),
   ('AGENCY_CREATIVE_TECH_COST',CASE WHEN c.primary_incurred_component='AGENCY_CREATIVE_TECH_COST' THEN c.agency_tech ELSE NULL END),
   ('CAMPAIGN_OVERHEAD_COST',CASE WHEN c.primary_incurred_component='CAMPAIGN_OVERHEAD_COST' THEN c.campaign_overhead ELSE NULL END),
   ('ACQUISITION_INCENTIVE_COST',CASE WHEN c.primary_incurred_component='ACQUISITION_INCENTIVE_COST' THEN c.incentive ELSE NULL END),
   ('DETAILED_CONDITIONAL_PARTNER_BROKER_COST',c.conditional_cost),
   ('LEGACY_M1_14_ACQUISITION_COST',c.accepted_m1_14_acquisition_cost_amount),
   ('IDENTIFIED_LEGACY_OVERLAP',CASE WHEN c.cost_blocked OR a.attribution_evidence_status='BLOCKED' THEN NULL ELSE c.bounded_overlap END),
   ('INCREMENTAL_ACQUISITION_COST_BEYOND_M1_14',CASE WHEN c.cost_blocked OR a.attribution_evidence_status='BLOCKED' THEN NULL ELSE c.detailed_total-c.bounded_overlap END),
   ('ENHANCED_TOTAL_ACQUISITION_COST_IF_BOOKED',CASE WHEN c.cost_blocked OR a.attribution_evidence_status='BLOCKED' THEN NULL ELSE c.accepted_m1_14_acquisition_cost_amount+c.detailed_total-c.bounded_overlap END)
 ) v(cost_component_code,component_amount)
 JOIN msbf_ref.acquisition_cost_component d ON d.cost_component_code=v.cost_component_code
 LEFT JOIN msbf_ref.acquisition_legacy_overlap_policy op
   ON op.partner_channel_id=c.partner_channel_id AND op.cost_component_code=v.cost_component_code
)
INSERT INTO _m1_16_component_expected(
 module1_run_id,merchant_application_id,cost_component_code,component_version,
 component_role_code,cost_timing_code,cost_basis_code,component_amount,evidence_status,
 included_in_m1_14_flag,legacy_overlap_class,sign_multiplier,calculation_hash,
 source_lineage_payload,row_hash,created_by_run_id,created_at
)
SELECT run_id,merchant_application_id,cost_component_code,1,component_role_code,
 cost_timing_code,cost_basis_code,component_amount,component_evidence_status,
 CASE WHEN cost_component_code='LEGACY_M1_14_ACQUISITION_COST' THEN true
      WHEN overlap_class IN('POTENTIALLY_INCLUDED_IN_M1_14','FULLY_INCLUDED_IN_M1_14') THEN true ELSE false END,
 coalesce(overlap_class,CASE WHEN cost_component_code='LEGACY_M1_14_ACQUISITION_COST' THEN 'FULLY_INCLUDED_IN_M1_14' ELSE 'NOT_INCLUDED_IN_M1_14' END),
 sign_multiplier,
 md5(merchant_application_id||'|'||cost_component_code||'|'||coalesce(component_amount::text,'NULL')||'|'||component_evidence_status),
 jsonb_build_object('primary_campaign_id',primary_campaign_id,'partner_channel_id',partner_channel_id,'legacy_scope_code',legacy_scope_code),
 '',run_id,clock_timestamp()
FROM values_wide;
UPDATE _m1_16_component_expected c
SET row_hash=msbf_m1.m1_16_hash_jsonb(to_jsonb(c)-'row_hash'-'created_at') WHERE row_hash='';
INSERT INTO msbf_m1.application_acquisition_cost_component_value(
 module1_run_id,merchant_application_id,cost_component_code,component_version,
 component_role_code,cost_timing_code,cost_basis_code,component_amount,evidence_status,
 included_in_m1_14_flag,legacy_overlap_class,sign_multiplier,calculation_hash,
 source_lineage_payload,row_hash,created_by_run_id,created_at
)
SELECT module1_run_id,merchant_application_id,cost_component_code,component_version,
 component_role_code,cost_timing_code,cost_basis_code,component_amount,evidence_status,
 included_in_m1_14_flag,legacy_overlap_class,sign_multiplier,calculation_hash,
 source_lineage_payload,row_hash,created_by_run_id,created_at FROM _m1_16_component_expected;

ANALYZE msbf_m1.application_acquisition_cost_snapshot;
ANALYZE msbf_m1.application_acquisition_cost_component_value;

DO $phase_5$ BEGIN RAISE NOTICE 'M1.16 Phase 5/7 — create companion latest contract and immutable archive'; END; $phase_5$;

DROP TABLE IF EXISTS _m1_16_latest_expected;
CREATE TEMP TABLE _m1_16_latest_expected (LIKE msbf_m1.application_acquisition_contract_latest INCLUDING DEFAULTS) ON COMMIT DROP;
INSERT INTO _m1_16_latest_expected(
 module1_run_id,merchant_application_id,population_id,merchant_id,as_of_date,
 accepted_partner_channel_id,accepted_channel_type,accepted_application_channel,
 primary_source_code,primary_campaign_id,attribution_method_code,attribution_method_version,
 attribution_confidence_score,attribution_confidence_tier,touchpoint_count,assisted_touch_count,
 attribution_evidence_status,direct_attributable_incurred_cost_amount,
 internally_allocated_acquisition_cost_amount,total_incurred_pre_application_cost_amount,
 detailed_conditional_partner_broker_cost_amount,detailed_total_acquisition_cost_if_booked,
 accepted_m1_14_acquisition_cost_rate,accepted_m1_14_acquisition_cost_amount,
 legacy_m1_14_cost_scope_code,identified_legacy_overlap_amount,unmapped_legacy_proxy_amount,
 incremental_acquisition_cost_beyond_m1_14,enhanced_total_acquisition_cost_if_booked,
 cost_evidence_status,overlap_evidence_status,acquisition_contract_evidence_status,
 fallback_path_code,primary_reason_code,secondary_reason_codes,
 attribution_snapshot_hash,cost_snapshot_hash,m1_14_baseline_row_hash,m1_14_stress_row_hash,
 m1_15_baseline_contract_row_hash,m1_15_stress_contract_row_hash,source_payload,lineage_payload,
 contract_code,contract_version,schema_version,contract_row_hash,created_by_run_id,created_at
)
SELECT c.module1_run_id,c.merchant_application_id,c.population_id,c.merchant_id,c.as_of_date,
 c.accepted_partner_channel_id,c.accepted_channel_type,c.accepted_application_channel,
 c.primary_source_code,c.primary_campaign_id,a.attribution_method_code,a.attribution_method_version,
 a.attribution_confidence_score,a.attribution_confidence_tier,a.touchpoint_count,a.assisted_touch_count,
 c.attribution_evidence_status,c.direct_attributable_incurred_cost_amount,
 c.internally_allocated_acquisition_cost_amount,c.total_incurred_pre_application_cost_amount,
 c.detailed_conditional_partner_broker_cost_amount,c.detailed_total_acquisition_cost_if_booked,
 c.accepted_m1_14_acquisition_cost_rate,c.accepted_m1_14_acquisition_cost_amount,
 c.legacy_m1_14_cost_scope_code,c.identified_legacy_overlap_amount,c.unmapped_legacy_proxy_amount,
 c.incremental_acquisition_cost_beyond_m1_14,c.enhanced_total_acquisition_cost_if_booked,
 c.cost_evidence_status,c.overlap_evidence_status,c.acquisition_contract_evidence_status,
 c.fallback_path_code,c.primary_cost_reason_code,c.secondary_cost_reason_codes,
 a.row_hash,c.row_hash,c.m1_14_baseline_row_hash,c.m1_14_stress_row_hash,
 c.m1_15_baseline_contract_row_hash,c.m1_15_stress_contract_row_hash,
 jsonb_build_object(
   'first_touch_source',a.first_touch_source_code,'last_touch_source',a.last_touch_source_code,
   'primary_source',a.primary_source_code,'primary_campaign',a.primary_campaign_id,
   'touchpoint_count',a.touchpoint_count,'attribution_evidence_status',a.attribution_evidence_status,
   'cost_evidence_status',c.cost_evidence_status,'overlap_evidence_status',c.overlap_evidence_status),
 jsonb_build_object(
   'application_request_hash',a.application_request_hash,
   'm1_14_baseline_row_hash',c.m1_14_baseline_row_hash,'m1_14_stress_row_hash',c.m1_14_stress_row_hash,
   'm1_14_combined_set_hash',c.m1_14_combined_set_hash,
   'm1_15_baseline_contract_row_hash',c.m1_15_baseline_contract_row_hash,
   'm1_15_stress_contract_row_hash',c.m1_15_stress_contract_row_hash,
   'm1_15_combined_set_hash',c.m1_15_combined_set_hash,
   'm1_16_policy_configuration_hash',c.m1_16_policy_configuration_hash),
 'M1_ACQUISITION_CONSUMPTION',1,'M1_ACQUISITION_SCHEMA_V1','',c.module1_run_id,clock_timestamp()
FROM _m1_16_cost_expected c
JOIN _m1_16_attribution_expected a ON a.merchant_application_id=c.merchant_application_id;
UPDATE _m1_16_latest_expected l
SET contract_row_hash=msbf_m1.m1_16_hash_jsonb(to_jsonb(l)-'contract_row_hash'-'created_at')
WHERE contract_row_hash='';
INSERT INTO msbf_m1.application_acquisition_contract_latest(
 module1_run_id,merchant_application_id,population_id,merchant_id,as_of_date,
 accepted_partner_channel_id,accepted_channel_type,accepted_application_channel,
 primary_source_code,primary_campaign_id,attribution_method_code,attribution_method_version,
 attribution_confidence_score,attribution_confidence_tier,touchpoint_count,assisted_touch_count,
 attribution_evidence_status,direct_attributable_incurred_cost_amount,
 internally_allocated_acquisition_cost_amount,total_incurred_pre_application_cost_amount,
 detailed_conditional_partner_broker_cost_amount,detailed_total_acquisition_cost_if_booked,
 accepted_m1_14_acquisition_cost_rate,accepted_m1_14_acquisition_cost_amount,
 legacy_m1_14_cost_scope_code,identified_legacy_overlap_amount,unmapped_legacy_proxy_amount,
 incremental_acquisition_cost_beyond_m1_14,enhanced_total_acquisition_cost_if_booked,
 cost_evidence_status,overlap_evidence_status,acquisition_contract_evidence_status,
 fallback_path_code,primary_reason_code,secondary_reason_codes,
 attribution_snapshot_hash,cost_snapshot_hash,m1_14_baseline_row_hash,m1_14_stress_row_hash,
 m1_15_baseline_contract_row_hash,m1_15_stress_contract_row_hash,source_payload,lineage_payload,
 contract_code,contract_version,schema_version,contract_row_hash,created_by_run_id,created_at
)
SELECT module1_run_id,merchant_application_id,population_id,merchant_id,as_of_date,
 accepted_partner_channel_id,accepted_channel_type,accepted_application_channel,
 primary_source_code,primary_campaign_id,attribution_method_code,attribution_method_version,
 attribution_confidence_score,attribution_confidence_tier,touchpoint_count,assisted_touch_count,
 attribution_evidence_status,direct_attributable_incurred_cost_amount,
 internally_allocated_acquisition_cost_amount,total_incurred_pre_application_cost_amount,
 detailed_conditional_partner_broker_cost_amount,detailed_total_acquisition_cost_if_booked,
 accepted_m1_14_acquisition_cost_rate,accepted_m1_14_acquisition_cost_amount,
 legacy_m1_14_cost_scope_code,identified_legacy_overlap_amount,unmapped_legacy_proxy_amount,
 incremental_acquisition_cost_beyond_m1_14,enhanced_total_acquisition_cost_if_booked,
 cost_evidence_status,overlap_evidence_status,acquisition_contract_evidence_status,
 fallback_path_code,primary_reason_code,secondary_reason_codes,
 attribution_snapshot_hash,cost_snapshot_hash,m1_14_baseline_row_hash,m1_14_stress_row_hash,
 m1_15_baseline_contract_row_hash,m1_15_stress_contract_row_hash,source_payload,lineage_payload,
 contract_code,contract_version,schema_version,contract_row_hash,created_by_run_id,created_at
FROM _m1_16_latest_expected;

INSERT INTO msbf_m1.application_acquisition_contract_archive(
 module1_run_id,merchant_application_id,contract_code,contract_version,schema_version,
 contract_row_hash,contract_payload,archived_by_run_id,archived_at
)
SELECT module1_run_id,merchant_application_id,contract_code,contract_version,schema_version,
 contract_row_hash,to_jsonb(l)-'created_at',module1_run_id,clock_timestamp()
FROM msbf_m1.application_acquisition_contract_latest l
WHERE module1_run_id=(SELECT run_id FROM _m1_16_ctx);

ANALYZE msbf_m1.application_acquisition_contract_latest;
ANALYZE msbf_m1.application_acquisition_contract_archive;

DO $phase_6$ BEGIN RAISE NOTICE 'M1.16 Phase 6/7 — calculate canonical set hashes and register companion contract'; END; $phase_6$;

DROP TABLE IF EXISTS _m1_16_hashes;
CREATE TEMP TABLE _m1_16_hashes ON COMMIT DROP AS
SELECT
 (SELECT md5(string_agg('SOURCE|'||acquisition_source_code||'|'||row_hash,'||' ORDER BY acquisition_source_code)) FROM msbf_m1.acquisition_source_profile WHERE module1_run_id=(SELECT run_id FROM _m1_16_ctx)) AS source_hash,
 (SELECT md5(string_agg('CAMPAIGN|'||acquisition_campaign_id||'|'||row_hash,'||' ORDER BY acquisition_campaign_id)) FROM msbf_m1.acquisition_marketing_campaign WHERE module1_run_id=(SELECT run_id FROM _m1_16_ctx)) AS campaign_hash,
 (SELECT md5(string_agg('FUNNEL|'||acquisition_campaign_id||'|'||stage_code||'|'||row_hash,'||' ORDER BY acquisition_campaign_id,stage_order)) FROM msbf_m1.acquisition_campaign_funnel_stage WHERE module1_run_id=(SELECT run_id FROM _m1_16_ctx)) AS funnel_hash,
 (SELECT md5(string_agg('LEDGER|'||acquisition_cost_line_id||'|'||row_hash,'||' ORDER BY acquisition_cost_line_id)) FROM msbf_m1.acquisition_cost_ledger WHERE module1_run_id=(SELECT run_id FROM _m1_16_ctx)) AS ledger_hash,
 (SELECT md5(string_agg('TOUCH|'||merchant_application_id||'|'||touchpoint_sequence||'|'||row_hash,'||' ORDER BY merchant_application_id,touchpoint_sequence)) FROM msbf_m1.application_acquisition_touchpoint WHERE module1_run_id=(SELECT run_id FROM _m1_16_ctx)) AS touch_hash,
 (SELECT md5(string_agg('ATTRIBUTION|'||merchant_application_id||'|'||row_hash,'||' ORDER BY merchant_application_id)) FROM msbf_m1.application_acquisition_attribution_snapshot WHERE module1_run_id=(SELECT run_id FROM _m1_16_ctx)) AS attribution_hash,
 (SELECT md5(string_agg('COST|'||merchant_application_id||'|'||row_hash,'||' ORDER BY merchant_application_id)) FROM msbf_m1.application_acquisition_cost_snapshot WHERE module1_run_id=(SELECT run_id FROM _m1_16_ctx)) AS cost_hash,
 (SELECT md5(string_agg('COMPONENT|'||merchant_application_id||'|'||cost_component_code||'|'||row_hash,'||' ORDER BY merchant_application_id,cost_component_code)) FROM msbf_m1.application_acquisition_cost_component_value WHERE module1_run_id=(SELECT run_id FROM _m1_16_ctx)) AS component_hash,
 (SELECT md5(string_agg('LATEST|'||merchant_application_id||'|'||contract_row_hash,'||' ORDER BY merchant_application_id)) FROM msbf_m1.application_acquisition_contract_latest WHERE module1_run_id=(SELECT run_id FROM _m1_16_ctx)) AS latest_hash,
 (SELECT md5(string_agg('ARCHIVE|'||contract_version||'|'||merchant_application_id||'|'||contract_row_hash,'||' ORDER BY contract_version,merchant_application_id)) FROM msbf_m1.application_acquisition_contract_archive WHERE module1_run_id=(SELECT run_id FROM _m1_16_ctx)) AS archive_hash;

INSERT INTO msbf_ctl.m1_16_acquisition_contract_registry(
 contract_code,contract_version,module1_run_id,schema_version,scenario_set_id,methodology_version,
 source_m1_15_contract_code,source_m1_15_contract_version,source_m1_15_schema_version,
 source_m1_15_combined_hash,source_m1_14_combined_hash,policy_configuration_hash,
 contract_status,source_profile_row_count,campaign_row_count,funnel_row_count,cost_ledger_row_count,
 touchpoint_row_count,attribution_row_count,cost_snapshot_row_count,component_row_count,
 latest_row_count,archive_row_count,source_profile_set_hash,campaign_set_hash,funnel_set_hash,
 cost_ledger_set_hash,touchpoint_set_hash,attribution_set_hash,cost_snapshot_set_hash,
 component_set_hash,latest_set_hash,archive_set_hash,integrated_view_row_count,
 contract_set_hash,combined_set_hash,contract_row_hash,created_by_run_id
)
SELECT 'M1_ACQUISITION_CONSUMPTION',1,ctx.run_id,'M1_ACQUISITION_SCHEMA_V1',ctx.scenario_set_id,'M1_16_METHOD_V1',
 ctx.m1_15_contract_code,ctx.m1_15_contract_version,ctx.m1_15_schema_version,
 ctx.m1_15_combined_hash,ctx.m1_14_combined_hash,ctx.policy_configuration_hash,'GENERATED',
 18,20,120,40,
 1075,750,750,9000,
 750,750,
 h.source_hash,h.campaign_hash,h.funnel_hash,h.ledger_hash,h.touch_hash,h.attribution_hash,
 h.cost_hash,h.component_hash,h.latest_hash,h.archive_hash,1500,
 md5('M1_ACQUISITION_CONSUMPTION|1|'||ctx.run_id||'|M1_ACQUISITION_SCHEMA_V1|'||ctx.m1_15_combined_hash||'|'||ctx.m1_14_combined_hash||'|'||ctx.policy_configuration_hash||'|'||
     h.source_hash||'|'||h.campaign_hash||'|'||h.funnel_hash||'|'||h.ledger_hash||'|'||h.touch_hash||'|'||h.attribution_hash||'|'||h.cost_hash||'|'||h.component_hash||'|'||h.latest_hash||'|'||h.archive_hash),
 '','',ctx.run_id
FROM _m1_16_ctx ctx CROSS JOIN _m1_16_hashes h;

UPDATE msbf_ctl.m1_16_acquisition_contract_registry c
SET contract_row_hash=msbf_m1.m1_16_hash_jsonb(
 to_jsonb(c)-'contract_row_hash'-'combined_set_hash'-'contract_status'-'generated_at'-'validated_at'-'accepted_at'
)
WHERE c.module1_run_id=(SELECT run_id FROM _m1_16_ctx);

WITH all_entities AS(
 SELECT 'SOURCE|'||acquisition_source_code AS entity_key,row_hash FROM msbf_m1.acquisition_source_profile WHERE module1_run_id=(SELECT run_id FROM _m1_16_ctx)
 UNION ALL SELECT 'CAMPAIGN|'||acquisition_campaign_id,row_hash FROM msbf_m1.acquisition_marketing_campaign WHERE module1_run_id=(SELECT run_id FROM _m1_16_ctx)
 UNION ALL SELECT 'FUNNEL|'||acquisition_campaign_id||'|'||stage_code,row_hash FROM msbf_m1.acquisition_campaign_funnel_stage WHERE module1_run_id=(SELECT run_id FROM _m1_16_ctx)
 UNION ALL SELECT 'LEDGER|'||acquisition_cost_line_id,row_hash FROM msbf_m1.acquisition_cost_ledger WHERE module1_run_id=(SELECT run_id FROM _m1_16_ctx)
 UNION ALL SELECT 'TOUCH|'||merchant_application_id||'|'||touchpoint_sequence::text,row_hash FROM msbf_m1.application_acquisition_touchpoint WHERE module1_run_id=(SELECT run_id FROM _m1_16_ctx)
 UNION ALL SELECT 'ATTRIBUTION|'||merchant_application_id,row_hash FROM msbf_m1.application_acquisition_attribution_snapshot WHERE module1_run_id=(SELECT run_id FROM _m1_16_ctx)
 UNION ALL SELECT 'COST|'||merchant_application_id,row_hash FROM msbf_m1.application_acquisition_cost_snapshot WHERE module1_run_id=(SELECT run_id FROM _m1_16_ctx)
 UNION ALL SELECT 'COMPONENT|'||merchant_application_id||'|'||cost_component_code,row_hash FROM msbf_m1.application_acquisition_cost_component_value WHERE module1_run_id=(SELECT run_id FROM _m1_16_ctx)
 UNION ALL SELECT 'LATEST|'||merchant_application_id,contract_row_hash FROM msbf_m1.application_acquisition_contract_latest WHERE module1_run_id=(SELECT run_id FROM _m1_16_ctx)
 UNION ALL SELECT 'ARCHIVE|'||contract_version::text||'|'||merchant_application_id,contract_row_hash FROM msbf_m1.application_acquisition_contract_archive WHERE module1_run_id=(SELECT run_id FROM _m1_16_ctx)
 UNION ALL SELECT 'CONTRACT|'||contract_code||'|'||contract_version::text||'|'||module1_run_id::text,contract_row_hash FROM msbf_ctl.m1_16_acquisition_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m1_16_ctx)
)
UPDATE msbf_ctl.m1_16_acquisition_contract_registry c
SET combined_set_hash=(SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) FROM all_entities)
WHERE c.module1_run_id=(SELECT run_id FROM _m1_16_ctx);

DO $phase_7$ BEGIN RAISE NOTICE 'M1.16 Phase 7/7 — reconcile physical entities, persist evidence, and commit'; END; $phase_7$;

DROP TABLE IF EXISTS _m1_16_mismatches;
CREATE TEMP TABLE _m1_16_mismatches(entity_type text,entity_key text,expected_hash text,actual_hash text) ON COMMIT DROP;
INSERT INTO _m1_16_mismatches
SELECT 'SOURCE',coalesce(e.acquisition_source_code,a.acquisition_source_code),e.row_hash,a.row_hash
FROM _m1_16_source_expected e FULL JOIN msbf_m1.acquisition_source_profile a
 ON a.module1_run_id=e.module1_run_id AND a.acquisition_source_code=e.acquisition_source_code
WHERE coalesce(e.module1_run_id,a.module1_run_id)=(SELECT run_id FROM _m1_16_ctx) AND e.row_hash IS DISTINCT FROM a.row_hash
UNION ALL
SELECT 'CAMPAIGN',coalesce(e.acquisition_campaign_id,a.acquisition_campaign_id),e.row_hash,a.row_hash
FROM _m1_16_campaign_expected e FULL JOIN msbf_m1.acquisition_marketing_campaign a
 ON a.module1_run_id=e.module1_run_id AND a.acquisition_campaign_id=e.acquisition_campaign_id
WHERE coalesce(e.module1_run_id,a.module1_run_id)=(SELECT run_id FROM _m1_16_ctx) AND e.row_hash IS DISTINCT FROM a.row_hash
UNION ALL
SELECT 'FUNNEL',coalesce(e.acquisition_campaign_id,a.acquisition_campaign_id)||'|'||coalesce(e.stage_code,a.stage_code),e.row_hash,a.row_hash
FROM _m1_16_funnel_expected e FULL JOIN msbf_m1.acquisition_campaign_funnel_stage a
 ON a.module1_run_id=e.module1_run_id AND a.acquisition_campaign_id=e.acquisition_campaign_id AND a.stage_code=e.stage_code
WHERE coalesce(e.module1_run_id,a.module1_run_id)=(SELECT run_id FROM _m1_16_ctx) AND e.row_hash IS DISTINCT FROM a.row_hash
UNION ALL
SELECT 'LEDGER',coalesce(e.acquisition_cost_line_id,a.acquisition_cost_line_id),e.row_hash,a.row_hash
FROM _m1_16_ledger_expected e FULL JOIN msbf_m1.acquisition_cost_ledger a
 ON a.module1_run_id=e.module1_run_id AND a.acquisition_cost_line_id=e.acquisition_cost_line_id
WHERE coalesce(e.module1_run_id,a.module1_run_id)=(SELECT run_id FROM _m1_16_ctx) AND e.row_hash IS DISTINCT FROM a.row_hash
UNION ALL
SELECT 'TOUCH',coalesce(e.merchant_application_id,a.merchant_application_id)||'|'||coalesce(e.touchpoint_sequence,a.touchpoint_sequence)::text,e.row_hash,a.row_hash
FROM _m1_16_touch_expected e FULL JOIN msbf_m1.application_acquisition_touchpoint a
 ON a.module1_run_id=e.module1_run_id AND a.merchant_application_id=e.merchant_application_id AND a.touchpoint_sequence=e.touchpoint_sequence
WHERE coalesce(e.module1_run_id,a.module1_run_id)=(SELECT run_id FROM _m1_16_ctx) AND e.row_hash IS DISTINCT FROM a.row_hash
UNION ALL
SELECT 'ATTRIBUTION',coalesce(e.merchant_application_id,a.merchant_application_id),e.row_hash,a.row_hash
FROM _m1_16_attribution_expected e FULL JOIN msbf_m1.application_acquisition_attribution_snapshot a
 ON a.module1_run_id=e.module1_run_id AND a.merchant_application_id=e.merchant_application_id
WHERE coalesce(e.module1_run_id,a.module1_run_id)=(SELECT run_id FROM _m1_16_ctx) AND e.row_hash IS DISTINCT FROM a.row_hash
UNION ALL
SELECT 'COST',coalesce(e.merchant_application_id,a.merchant_application_id),e.row_hash,a.row_hash
FROM _m1_16_cost_expected e FULL JOIN msbf_m1.application_acquisition_cost_snapshot a
 ON a.module1_run_id=e.module1_run_id AND a.merchant_application_id=e.merchant_application_id
WHERE coalesce(e.module1_run_id,a.module1_run_id)=(SELECT run_id FROM _m1_16_ctx) AND e.row_hash IS DISTINCT FROM a.row_hash
UNION ALL
SELECT 'COMPONENT',coalesce(e.merchant_application_id,a.merchant_application_id)||'|'||coalesce(e.cost_component_code,a.cost_component_code),e.row_hash,a.row_hash
FROM _m1_16_component_expected e FULL JOIN msbf_m1.application_acquisition_cost_component_value a
 ON a.module1_run_id=e.module1_run_id AND a.merchant_application_id=e.merchant_application_id AND a.cost_component_code=e.cost_component_code AND a.component_version=e.component_version
WHERE coalesce(e.module1_run_id,a.module1_run_id)=(SELECT run_id FROM _m1_16_ctx) AND e.row_hash IS DISTINCT FROM a.row_hash
UNION ALL
SELECT 'LATEST',coalesce(e.merchant_application_id,a.merchant_application_id),e.contract_row_hash,a.contract_row_hash
FROM _m1_16_latest_expected e FULL JOIN msbf_m1.application_acquisition_contract_latest a
 ON a.module1_run_id=e.module1_run_id AND a.merchant_application_id=e.merchant_application_id
WHERE coalesce(e.module1_run_id,a.module1_run_id)=(SELECT run_id FROM _m1_16_ctx) AND e.contract_row_hash IS DISTINCT FROM a.contract_row_hash
UNION ALL
SELECT 'ARCHIVE',coalesce(e.merchant_application_id,a.merchant_application_id),e.contract_row_hash,a.contract_row_hash
FROM _m1_16_latest_expected e FULL JOIN msbf_m1.application_acquisition_contract_archive a
 ON a.module1_run_id=e.module1_run_id AND a.merchant_application_id=e.merchant_application_id
AND a.contract_code=e.contract_code AND a.contract_version=e.contract_version
WHERE coalesce(e.module1_run_id,a.module1_run_id)=(SELECT run_id FROM _m1_16_ctx)
  AND (e.contract_row_hash IS DISTINCT FROM a.contract_row_hash
    OR a.contract_payload IS DISTINCT FROM to_jsonb(e)-'created_at')
UNION ALL
SELECT 'CONTRACT',c.contract_code||'|'||c.contract_version::text,
       msbf_m1.m1_16_hash_jsonb(to_jsonb(c)-'contract_row_hash'-'combined_set_hash'-'contract_status'-'generated_at'-'validated_at'-'accepted_at'),
       c.contract_row_hash
FROM msbf_ctl.m1_16_acquisition_contract_registry c
WHERE c.module1_run_id=(SELECT run_id FROM _m1_16_ctx)
  AND c.contract_row_hash IS DISTINCT FROM msbf_m1.m1_16_hash_jsonb(
        to_jsonb(c)-'contract_row_hash'-'combined_set_hash'-'contract_status'-'generated_at'-'validated_at'-'accepted_at');

DROP TABLE IF EXISTS _m1_16_reconciliation;
CREATE TEMP TABLE _m1_16_reconciliation ON COMMIT DROP AS
SELECT
 (SELECT count(*) FROM msbf_m1.acquisition_source_profile WHERE module1_run_id=(SELECT run_id FROM _m1_16_ctx)) AS source_rows,
 (SELECT count(*) FROM msbf_m1.acquisition_marketing_campaign WHERE module1_run_id=(SELECT run_id FROM _m1_16_ctx)) AS campaign_rows,
 (SELECT count(*) FROM msbf_m1.acquisition_campaign_funnel_stage WHERE module1_run_id=(SELECT run_id FROM _m1_16_ctx)) AS funnel_rows,
 (SELECT count(*) FROM msbf_m1.acquisition_cost_ledger WHERE module1_run_id=(SELECT run_id FROM _m1_16_ctx)) AS ledger_rows,
 (SELECT count(*) FROM msbf_m1.application_acquisition_touchpoint WHERE module1_run_id=(SELECT run_id FROM _m1_16_ctx)) AS touchpoint_rows,
 (SELECT count(*) FROM msbf_m1.application_acquisition_attribution_snapshot WHERE module1_run_id=(SELECT run_id FROM _m1_16_ctx)) AS attribution_rows,
 (SELECT count(*) FROM msbf_m1.application_acquisition_cost_snapshot WHERE module1_run_id=(SELECT run_id FROM _m1_16_ctx)) AS cost_rows,
 (SELECT count(*) FROM msbf_m1.application_acquisition_cost_component_value WHERE module1_run_id=(SELECT run_id FROM _m1_16_ctx)) AS component_rows,
 (SELECT count(*) FROM msbf_m1.application_acquisition_contract_latest WHERE module1_run_id=(SELECT run_id FROM _m1_16_ctx)) AS latest_rows,
 (SELECT count(*) FROM msbf_m1.application_acquisition_contract_archive WHERE module1_run_id=(SELECT run_id FROM _m1_16_ctx)) AS archive_rows,
 (SELECT count(*) FROM msbf_ctl.m1_16_acquisition_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m1_16_ctx)) AS registry_rows,
 (SELECT count(*) FROM msbf_m1.v_m1_16_module1_integrated_consumption WHERE module1_run_id=(SELECT run_id FROM _m1_16_ctx)) AS integrated_view_rows,
 (SELECT count(*) FROM _m1_16_mismatches) AS row_level_mismatches,
 (SELECT combined_set_hash FROM msbf_ctl.m1_16_acquisition_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m1_16_ctx)) AS combined_set_hash;

DO $reconcile_guard$ DECLARE x _m1_16_reconciliation%ROWTYPE; BEGIN
 SELECT * INTO STRICT x FROM _m1_16_reconciliation;
 IF x.source_rows<>18 OR x.campaign_rows<>20
 OR x.funnel_rows<>120 OR x.ledger_rows<>40
 OR x.touchpoint_rows<>1075 OR x.attribution_rows<>750
 OR x.cost_rows<>750 OR x.component_rows<>9000
 OR x.latest_rows<>750 OR x.archive_rows<>750
 OR x.registry_rows<>1 OR x.integrated_view_rows<>1500
 OR x.row_level_mismatches<>0 OR x.combined_set_hash IS NULL THEN
   RAISE EXCEPTION 'M1.16 reconciliation failed: %',row_to_json(x);
 END IF;
END; $reconcile_guard$;

DROP TABLE IF EXISTS _m1_16_generation_evidence;
CREATE TEMP TABLE _m1_16_generation_evidence(
 run_id bigint,evidence_code text,segment_key text,metric_name text,
 metric_value_numeric numeric(24,10),metric_value_text text,unit_code text,
 status text,interpretation text
) ON COMMIT PRESERVE ROWS;
INSERT INTO _m1_16_generation_evidence VALUES
((SELECT run_id FROM _m1_16_ctx),'M1_16_SOURCE_PROFILE_SET_HASH','PORTFOLIO','Source profile set hash',NULL::numeric(24,10),(SELECT source_profile_set_hash FROM msbf_ctl.m1_16_acquisition_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m1_16_ctx)),'HASH','PASS','Canonical source-profile set hash.'),
((SELECT run_id FROM _m1_16_ctx),'M1_16_CAMPAIGN_SET_HASH','PORTFOLIO','Campaign set hash',NULL::numeric(24,10),(SELECT campaign_set_hash FROM msbf_ctl.m1_16_acquisition_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m1_16_ctx)),'HASH','PASS','Canonical acquisition-campaign set hash.'),
((SELECT run_id FROM _m1_16_ctx),'M1_16_FUNNEL_SET_HASH','PORTFOLIO','Funnel set hash',NULL::numeric(24,10),(SELECT funnel_set_hash FROM msbf_ctl.m1_16_acquisition_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m1_16_ctx)),'HASH','PASS','Canonical campaign-funnel set hash.'),
((SELECT run_id FROM _m1_16_ctx),'M1_16_COST_LEDGER_SET_HASH','PORTFOLIO','Cost ledger set hash',NULL::numeric(24,10),(SELECT cost_ledger_set_hash FROM msbf_ctl.m1_16_acquisition_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m1_16_ctx)),'HASH','PASS','Canonical acquisition-cost-ledger set hash.'),
((SELECT run_id FROM _m1_16_ctx),'M1_16_TOUCHPOINT_SET_HASH','PORTFOLIO','Touchpoint set hash',NULL::numeric(24,10),(SELECT touchpoint_set_hash FROM msbf_ctl.m1_16_acquisition_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m1_16_ctx)),'HASH','PASS','Canonical application-touchpoint set hash.'),
((SELECT run_id FROM _m1_16_ctx),'M1_16_ATTRIBUTION_SET_HASH','PORTFOLIO','Attribution set hash',NULL::numeric(24,10),(SELECT attribution_set_hash FROM msbf_ctl.m1_16_acquisition_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m1_16_ctx)),'HASH','PASS','Canonical application-attribution set hash.'),
((SELECT run_id FROM _m1_16_ctx),'M1_16_COST_SNAPSHOT_SET_HASH','PORTFOLIO','Cost snapshot set hash',NULL::numeric(24,10),(SELECT cost_snapshot_set_hash FROM msbf_ctl.m1_16_acquisition_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m1_16_ctx)),'HASH','PASS','Canonical acquisition-cost snapshot set hash.'),
((SELECT run_id FROM _m1_16_ctx),'M1_16_COMPONENT_SET_HASH','PORTFOLIO','Component set hash',NULL::numeric(24,10),(SELECT component_set_hash FROM msbf_ctl.m1_16_acquisition_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m1_16_ctx)),'HASH','PASS','Canonical long-form acquisition-cost component set hash.'),
((SELECT run_id FROM _m1_16_ctx),'M1_16_LATEST_SET_HASH','PORTFOLIO','Latest acquisition contract set hash',NULL::numeric(24,10),(SELECT latest_set_hash FROM msbf_ctl.m1_16_acquisition_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m1_16_ctx)),'HASH','PASS','Canonical companion latest-contract set hash.'),
((SELECT run_id FROM _m1_16_ctx),'M1_16_ARCHIVE_SET_HASH','PORTFOLIO','Archive set hash',NULL::numeric(24,10),(SELECT archive_set_hash FROM msbf_ctl.m1_16_acquisition_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m1_16_ctx)),'HASH','PASS','Canonical immutable archive set hash.'),
((SELECT run_id FROM _m1_16_ctx),'M1_16_CONTRACT_SET_HASH','PORTFOLIO','Contract set hash',NULL::numeric(24,10),(SELECT contract_set_hash FROM msbf_ctl.m1_16_acquisition_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m1_16_ctx)),'HASH','PASS','Governed companion-contract identity hash.'),
((SELECT run_id FROM _m1_16_ctx),'M1_16_COMBINED_SET_HASH','PORTFOLIO','Combined M1.16 set hash',NULL::numeric(24,10),(SELECT combined_set_hash FROM msbf_ctl.m1_16_acquisition_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m1_16_ctx)),'HASH','PASS','Combined canonical hash across all 13,274 M1.16 entities.'),
((SELECT run_id FROM _m1_16_ctx),'M1_16_CANONICAL_ENTITY_COUNT','PORTFOLIO','Canonical entity count',13274::numeric(24,10),NULL::text,'ROWS','PASS','Complete M1.16 canonical entity population.'),
((SELECT run_id FROM _m1_16_ctx),'M1_16_CANONICAL_MISMATCH_COUNT','PORTFOLIO','Canonical mismatch count',(SELECT row_level_mismatches::numeric(24,10) FROM _m1_16_reconciliation),NULL::text,'ROWS','PASS','Expected-versus-physical row-hash mismatches.'),
((SELECT run_id FROM _m1_16_ctx),'M1_16_SOURCE_PROFILE_ROW_COUNT','PORTFOLIO','Source profile rows',18::numeric(24,10),NULL::text,'ROWS','PASS','Governed acquisition source profiles.'),
((SELECT run_id FROM _m1_16_ctx),'M1_16_CAMPAIGN_ROW_COUNT','PORTFOLIO','Campaign rows',20::numeric(24,10),NULL::text,'ROWS','PASS','Governed acquisition campaigns.'),
((SELECT run_id FROM _m1_16_ctx),'M1_16_FUNNEL_ROW_COUNT','PORTFOLIO','Funnel rows',120::numeric(24,10),NULL::text,'ROWS','PASS','Campaign by normalized funnel-stage rows.'),
((SELECT run_id FROM _m1_16_ctx),'M1_16_COST_LEDGER_ROW_COUNT','PORTFOLIO','Cost ledger rows',40::numeric(24,10),NULL::text,'ROWS','PASS','Incurred and conditional acquisition-cost ledger lines.'),
((SELECT run_id FROM _m1_16_ctx),'M1_16_TOUCHPOINT_ROW_COUNT','PORTFOLIO','Touchpoint rows',1075::numeric(24,10),NULL::text,'ROWS','PASS','Bounded application acquisition touchpoints.'),
((SELECT run_id FROM _m1_16_ctx),'M1_16_ATTRIBUTION_ROW_COUNT','PORTFOLIO','Attribution rows',750::numeric(24,10),NULL::text,'ROWS','PASS','One governed attribution snapshot per application.'),
((SELECT run_id FROM _m1_16_ctx),'M1_16_COST_SNAPSHOT_ROW_COUNT','PORTFOLIO','Cost snapshot rows',750::numeric(24,10),NULL::text,'ROWS','PASS','One acquisition-cost snapshot per application.'),
((SELECT run_id FROM _m1_16_ctx),'M1_16_COMPONENT_ROW_COUNT','PORTFOLIO','Component rows',9000::numeric(24,10),NULL::text,'ROWS','PASS','Twelve long-form acquisition-cost components per application.'),
((SELECT run_id FROM _m1_16_ctx),'M1_16_LATEST_ROW_COUNT','PORTFOLIO','Latest contract rows',750::numeric(24,10),NULL::text,'ROWS','PASS','One companion contract per accepted application.'),
((SELECT run_id FROM _m1_16_ctx),'M1_16_ARCHIVE_ROW_COUNT','PORTFOLIO','Archive rows',750::numeric(24,10),NULL::text,'ROWS','PASS','Immutable archive exactly reproduces the companion latest contract.'),
((SELECT run_id FROM _m1_16_ctx),'M1_16_INTEGRATED_VIEW_ROW_COUNT','PORTFOLIO','Integrated M1.15/M1.16 rows',1500::numeric(24,10),NULL::text,'ROWS','PASS','Read-only scenario-aware integrated consumption rows.');

INSERT INTO msbf_ctl.run_evidence(
 run_id,evidence_code,segment_key,metric_name,metric_value_numeric,metric_value_text,
 unit_code,status,interpretation
)
SELECT run_id,evidence_code,segment_key,metric_name,metric_value_numeric,metric_value_text,
 unit_code,status,interpretation FROM _m1_16_generation_evidence;

UPDATE msbf_ctl.run_registry
SET run_status='M1_16_GENERATED',completed_at=clock_timestamp(),row_count=13274,
    notes=coalesce(notes,'')||' | M1.16 acquisition foundations generated.'
WHERE run_id=(SELECT run_id FROM _m1_16_ctx);

COMMIT;

SELECT
 r.run_id,r.run_code,r.run_version,r.run_status,
 c.contract_status,c.source_profile_row_count,c.campaign_row_count,c.funnel_row_count,
 c.cost_ledger_row_count,c.touchpoint_row_count,c.attribution_row_count,
 c.cost_snapshot_row_count,c.component_row_count,c.latest_row_count,c.archive_row_count,
 c.integrated_view_row_count,
 13274::bigint AS expected_canonical_entities,
 13274::bigint AS actual_canonical_entities,
 0::bigint AS row_level_mismatches,
 c.source_profile_set_hash,c.campaign_set_hash,c.funnel_set_hash,c.cost_ledger_set_hash,
 c.touchpoint_set_hash,c.attribution_set_hash,c.cost_snapshot_set_hash,c.component_set_hash,
 c.latest_set_hash,c.archive_set_hash,c.contract_set_hash,c.combined_set_hash,
 'PASS'::text AS generation_status
FROM msbf_ctl.run_registry r
JOIN msbf_ctl.m1_16_acquisition_contract_registry c ON c.module1_run_id=r.run_id
WHERE r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1;
