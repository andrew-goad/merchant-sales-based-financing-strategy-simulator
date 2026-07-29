/* ============================================================================
MSBF M1.16 — Failed-Generation Recovery Check
Program : 116A_msbf_m1_16_failed_generation_recovery_check_v0_2R3.sql
Version : v0.2R3
Purpose : Prove the pristine accepted M1.15 boundary after a cancelled or failed
          pre-commit Program 118 transaction.
Use     : Run only after ROLLBACK following a failed/cancelled Program 118.
Safety  : Read-only except for a session-preserved temporary result row.
============================================================================ */
BEGIN;
DROP TABLE IF EXISTS _m1_16_recovery;
CREATE TEMP TABLE _m1_16_recovery ON COMMIT PRESERVE ROWS AS
WITH r AS(
  SELECT run_id,run_code,run_version,run_status,parameter_snapshot_hash,
         profile_snapshot_hash,source_snapshot_hash
  FROM msbf_ctl.run_registry
  WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
), counts AS(
  SELECT
    (SELECT count(*) FROM msbf_m1.acquisition_source_profile WHERE module1_run_id=r.run_id) AS source_rows,
    (SELECT count(*) FROM msbf_m1.acquisition_marketing_campaign WHERE module1_run_id=r.run_id) AS campaign_rows,
    (SELECT count(*) FROM msbf_m1.acquisition_campaign_funnel_stage WHERE module1_run_id=r.run_id) AS funnel_rows,
    (SELECT count(*) FROM msbf_m1.acquisition_cost_ledger WHERE module1_run_id=r.run_id) AS ledger_rows,
    (SELECT count(*) FROM msbf_m1.application_acquisition_touchpoint WHERE module1_run_id=r.run_id) AS touchpoint_rows,
    (SELECT count(*) FROM msbf_m1.application_acquisition_attribution_snapshot WHERE module1_run_id=r.run_id) AS attribution_rows,
    (SELECT count(*) FROM msbf_m1.application_acquisition_cost_snapshot WHERE module1_run_id=r.run_id) AS cost_rows,
    (SELECT count(*) FROM msbf_m1.application_acquisition_cost_component_value WHERE module1_run_id=r.run_id) AS component_rows,
    (SELECT count(*) FROM msbf_m1.application_acquisition_contract_latest WHERE module1_run_id=r.run_id) AS latest_rows,
    (SELECT count(*) FROM msbf_m1.application_acquisition_contract_archive WHERE module1_run_id=r.run_id) AS archive_rows,
    (SELECT count(*) FROM msbf_ctl.m1_16_acquisition_contract_registry WHERE module1_run_id=r.run_id) AS registry_rows,
    (SELECT count(*) FROM msbf_ctl.run_evidence WHERE run_id=r.run_id AND evidence_code LIKE 'M1_16_%') AS evidence_rows,
    (SELECT count(*) FROM msbf_ctl.acceptance_gate_result WHERE run_id=r.run_id AND gate_id='M1_16_ACQUISITION_MARKETING_COST_FOUNDATIONS') AS gate_rows,
    (SELECT count(*) FROM msbf_ctl.profile_resolution_error WHERE run_id=r.run_id AND severity='BLOCKING') AS blocking_errors
  FROM r
)
SELECT r.run_id,r.run_code,r.run_version,r.run_status,r.parameter_snapshot_hash,
       r.profile_snapshot_hash,r.source_snapshot_hash,
       c.source_rows,c.campaign_rows,c.funnel_rows,c.ledger_rows,c.touchpoint_rows,
       c.attribution_rows,c.cost_rows,c.component_rows,c.latest_rows,c.archive_rows,
       c.registry_rows,c.evidence_rows,c.gate_rows,c.blocking_errors,
  to_regclass('msbf_m1.acquisition_source_profile') IS NOT NULL AS source_table_exists,
  to_regclass('msbf_m1.application_acquisition_contract_latest') IS NOT NULL AS latest_table_exists,
  to_regclass('msbf_m1.application_acquisition_contract_archive') IS NOT NULL AS archive_table_exists,
  (SELECT status FROM msbf_ctl.policy_profile WHERE profile_code='M1_16_ACQUISITION_FOUNDATIONS' AND profile_version=1) AS policy_status,
  (SELECT parameter_set_hash FROM msbf_ctl.parameter_set WHERE parameter_set_code='M1_16_ACQUISITION_FOUNDATIONS' AND parameter_set_version=1) AS policy_configuration_hash,
  CASE WHEN r.run_status='M1_15_ACCEPTED'
         AND r.parameter_snapshot_hash='bd09e598c82db96e47459d77fd11e7c8'
         AND r.profile_snapshot_hash='462cbd2ed92f68e5bdecf6b17537a973'
         AND r.source_snapshot_hash='93c3d1368fb2450ab4a08e2b721f92d3'
         AND c.source_rows+c.campaign_rows+c.funnel_rows+c.ledger_rows+c.touchpoint_rows+
             c.attribution_rows+c.cost_rows+c.component_rows+c.latest_rows+c.archive_rows+
             c.registry_rows+c.evidence_rows+c.gate_rows+c.blocking_errors=0
         AND to_regclass('msbf_m1.acquisition_source_profile') IS NOT NULL
         AND to_regclass('msbf_m1.application_acquisition_contract_latest') IS NOT NULL
         AND to_regclass('msbf_m1.application_acquisition_contract_archive') IS NOT NULL
       THEN 'PASS' ELSE 'FAIL' END AS recovery_state_status
FROM r CROSS JOIN counts c;
DO $guard$ DECLARE x _m1_16_recovery%ROWTYPE; BEGIN
 SELECT * INTO STRICT x FROM _m1_16_recovery;
 IF x.recovery_state_status<>'PASS' THEN
   RAISE EXCEPTION 'M1.16 recovery-state check failed: %',row_to_json(x);
 END IF;
END; $guard$;
COMMIT;
SELECT * FROM _m1_16_recovery;
