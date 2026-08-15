/* ============================================================================
M2.2 Program 145 v0.2R2 — Acceptance Finalizer
Explicit namespaces, single-valued acceptance evidence, reviewer role, and
independent physical guards before lifecycle transition.
============================================================================ */
BEGIN; SET LOCAL work_mem='96MB'; SET LOCAL statement_timeout='45min'; SET LOCAL jit=off;
DROP TABLE IF EXISTS _m2_2_acceptance;
CREATE TEMP TABLE _m2_2_acceptance ON COMMIT PRESERVE ROWS AS
WITH r AS(SELECT run_id,run_status FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1),
registry AS(SELECT contract_status,canonical_entities,request_contract_set_hash,pricing_contract_set_hash,combined_set_hash FROM msbf_ctl.m2_2_pricing_structure_contract_registry WHERE module1_run_id=(SELECT run_id FROM r)),
controls AS(SELECT count(*) FILTER(WHERE evidence_code LIKE 'M2_2_POS_%') AS positive_checks,count(*) FILTER(WHERE evidence_code LIKE 'M2_2_POS_%' AND status='PASS') AS positive_passes,count(*) FILTER(WHERE evidence_code LIKE 'M2_2_POS_%' AND status<>'PASS') AS positive_failures,count(*) FILTER(WHERE evidence_code LIKE 'M2_2_NEG_%') AS negative_checks,count(*) FILTER(WHERE evidence_code LIKE 'M2_2_NEG_%' AND status='PASS') AS negative_passes,count(*) FILTER(WHERE evidence_code LIKE 'M2_2_NEG_%' AND status<>'PASS') AS negative_failures FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM r)),
physical AS(SELECT
 (SELECT count(*) FROM msbf_m2.application_request_structure_snapshot WHERE module1_run_id=(SELECT run_id FROM r)) AS request_snapshot_rows,
 (SELECT count(*) FROM msbf_m2.application_request_structure_latest WHERE module1_run_id=(SELECT run_id FROM r)) AS request_latest_rows,
 (SELECT count(*) FROM msbf_m2.application_request_structure_archive WHERE module1_run_id=(SELECT run_id FROM r)) AS request_archive_rows,
 (SELECT count(*) FROM msbf_m2.application_pricing_structure_candidate WHERE module1_run_id=(SELECT run_id FROM r)) AS candidate_rows,
 (SELECT count(*) FROM msbf_m2.application_pricing_structure_snapshot WHERE module1_run_id=(SELECT run_id FROM r)) AS pricing_snapshot_rows,
 (SELECT count(*) FROM msbf_m2.application_pricing_structure_latest WHERE module1_run_id=(SELECT run_id FROM r)) AS pricing_latest_rows,
 (SELECT count(*) FROM msbf_m2.application_pricing_structure_archive WHERE module1_run_id=(SELECT run_id FROM r)) AS pricing_archive_rows,
 (SELECT count(*) FROM msbf_m2.v_m2_2_matched_scenario_comparison WHERE module1_run_id=(SELECT run_id FROM r)) AS comparison_rows,
 (SELECT count(*) FROM msbf_m2.v_m2_2_matched_scenario_comparison WHERE module1_run_id=(SELECT run_id FROM r) AND stress_structure_improvement_flag) AS stress_improvements,
 (SELECT count(*) FROM msbf_m2.application_pricing_structure_snapshot s LEFT JOIN msbf_m2.application_pricing_structure_candidate c ON c.module1_run_id=s.module1_run_id AND c.scenario_id=s.scenario_id AND c.merchant_application_id=s.merchant_application_id AND c.row_hash=s.selected_candidate_row_hash WHERE s.module1_run_id=(SELECT run_id FROM r) AND s.structure_available_flag AND (
    c.row_hash IS NULL
    OR NOT c.selected_foundation_flag
    OR s.selected_candidate_template_code IS DISTINCT FROM
       c.candidate_template_code
    OR s.selected_funding_amount IS DISTINCT FROM
       c.candidate_funding_amount
    OR s.selected_remittance_rate IS DISTINCT FROM
       c.candidate_remittance_rate
    OR s.selected_payback_multiple IS DISTINCT FROM
       c.candidate_payback_multiple
    OR s.selected_collection_horizon_days IS DISTINCT FROM
       c.candidate_collection_horizon_days
    OR s.selected_total_repayment_amount IS DISTINCT FROM
       c.candidate_total_repayment_amount
    OR s.selected_finance_charge_amount IS DISTINCT FROM
       c.candidate_finance_charge_amount
    OR s.selected_implied_daily_collection_amount IS DISTINCT FROM
       c.implied_daily_collection_amount
    OR s.selected_implied_payoff_days IS DISTINCT FROM
       c.implied_payoff_days
    OR s.selected_amount_to_request_ratio IS DISTINCT FROM
       c.amount_to_request_ratio
)) AS selected_candidate_mismatches,
 (SELECT count(*) FROM msbf_m2.application_pricing_structure_latest l FULL OUTER JOIN msbf_m2.application_pricing_structure_archive a ON a.module1_run_id=l.module1_run_id AND a.scenario_id=l.scenario_id AND a.merchant_application_id=l.merchant_application_id WHERE coalesce(l.module1_run_id,a.module1_run_id)=(SELECT run_id FROM r) AND (l.contract_row_hash IS DISTINCT FROM a.contract_row_hash OR a.contract_payload IS DISTINCT FROM (to_jsonb(l)-'created_at'))) AS archive_mismatches,
 (SELECT count(*) FROM msbf_ctl.profile_resolution_error WHERE run_id=(SELECT run_id FROM r) AND severity='BLOCKING') AS blocking_errors,
 (SELECT count(*) FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM r) AND gate_id='M2_2_PRICING_STRUCTURE_COUNTEROFFER') AS existing_gate_rows,
 (SELECT count(*) FROM information_schema.columns WHERE table_schema='msbf_m2' AND table_name LIKE 'application_%structure%' AND lower(column_name) IN('approval_flag','decline_flag','final_decision_code','adverse_action_code','booking_status','funding_status')) AS prohibited_columns)
SELECT r.run_id,r.run_status AS prior_run_status,registry.contract_status AS prior_contract_status,controls.positive_checks,controls.positive_passes,controls.positive_failures,controls.negative_checks,controls.negative_passes,controls.negative_failures,physical.request_snapshot_rows,physical.request_latest_rows,physical.request_archive_rows,physical.candidate_rows,physical.pricing_snapshot_rows,physical.pricing_latest_rows,physical.pricing_archive_rows,physical.comparison_rows,physical.stress_improvements,physical.selected_candidate_mismatches,physical.archive_mismatches,physical.blocking_errors,physical.existing_gate_rows,physical.prohibited_columns,registry.canonical_entities,registry.request_contract_set_hash,registry.pricing_contract_set_hash,registry.combined_set_hash,
 CASE WHEN r.run_status='M2_2_VALIDATED' AND registry.contract_status='VALIDATED' AND controls.positive_checks=120 AND controls.positive_passes=120 AND controls.positive_failures=0 AND controls.negative_checks=20 AND controls.negative_passes=20 AND controls.negative_failures=0 AND physical.request_snapshot_rows=750 AND physical.request_latest_rows=750 AND physical.request_archive_rows=750 AND physical.candidate_rows=557 AND physical.pricing_snapshot_rows=1500 AND physical.pricing_latest_rows=1500 AND physical.pricing_archive_rows=1500 AND physical.comparison_rows=750 AND registry.canonical_entities=7336 AND physical.stress_improvements=0 AND physical.selected_candidate_mismatches=0 AND physical.archive_mismatches=0 AND physical.blocking_errors=0 AND physical.existing_gate_rows=0 AND physical.prohibited_columns=0 AND registry.request_contract_set_hash IS NOT NULL AND registry.pricing_contract_set_hash IS NOT NULL AND registry.combined_set_hash IS NOT NULL THEN 'PASS' ELSE 'FAIL' END AS acceptance_status
FROM r CROSS JOIN registry CROSS JOIN controls CROSS JOIN physical;
DO $$ DECLARE v record; BEGIN SELECT * INTO v FROM _m2_2_acceptance; PERFORM msbf_ctl.m2_2_assert_acceptance_ready(v.run_id); IF v.acceptance_status<>'PASS' THEN RAISE EXCEPTION 'M2.2 acceptance preconditions failed: %',row_to_json(v); END IF; END $$;
DROP TABLE IF EXISTS _m2_2_acceptance_evidence;
CREATE TEMP TABLE _m2_2_acceptance_evidence(run_id bigint,evidence_code text,segment_key text,metric_name text,metric_value_numeric numeric(24,10),metric_value_text text,unit_code text,status text,interpretation text,CHECK(num_nonnulls(metric_value_numeric,metric_value_text)=1)) ON COMMIT DROP;
INSERT INTO _m2_2_acceptance_evidence SELECT run_id,'M2_2_ACCEPTANCE_SUMMARY','PORTFOLIO','M2_2_PRICING_STRUCTURE_ACCEPTANCE',NULL::numeric(24,10),combined_set_hash,'ACCEPTANCE','PASS','Formal M2.2 acceptance: 7,336 canonical entities, 120 positive controls, 20 negative controls, bounded structure contracts, and no final credit decision.' FROM _m2_2_acceptance;
UPDATE msbf_ctl.m2_2_pricing_structure_contract_registry SET contract_status='ACCEPTED',accepted_at=clock_timestamp() WHERE module1_run_id=(SELECT run_id FROM _m2_2_acceptance);
UPDATE msbf_ctl.run_registry SET run_status='M2_2_ACCEPTED',notes=coalesce(notes,'')||' | M2.2 pricing, structure and counteroffer foundations accepted.' WHERE run_id=(SELECT run_id FROM _m2_2_acceptance);
INSERT INTO msbf_ctl.acceptance_gate_result(run_id,gate_id,review_version,result_status,observed_value,threshold_value,finding,residual_limitation,reviewer_role)
SELECT run_id,'M2_2_PRICING_STRUCTURE_COUNTEROFFER',1,'PASS',combined_set_hash,'120/120 positive; 20/20 negative; zero deterministic or boundary violations','M2.2 pricing and structure foundations accepted.','Final customer offer and credit decision remain outside M2.2.','Independent Validation / Project Owner' FROM _m2_2_acceptance;
INSERT INTO msbf_ctl.run_evidence(run_id,evidence_code,segment_key,metric_name,metric_value_numeric,metric_value_text,unit_code,status,interpretation)
SELECT run_id,evidence_code,segment_key,metric_name,metric_value_numeric,metric_value_text,unit_code,status,interpretation FROM _m2_2_acceptance_evidence;
ALTER TABLE _m2_2_acceptance ADD COLUMN final_run_status text,ADD COLUMN final_contract_status text,ADD COLUMN gate_status text;
UPDATE _m2_2_acceptance a SET final_run_status=(SELECT run_status FROM msbf_ctl.run_registry WHERE run_id=a.run_id),final_contract_status=(SELECT contract_status FROM msbf_ctl.m2_2_pricing_structure_contract_registry WHERE module1_run_id=a.run_id),gate_status=(SELECT result_status FROM msbf_ctl.acceptance_gate_result WHERE run_id=a.run_id AND gate_id='M2_2_PRICING_STRUCTURE_COUNTEROFFER' AND review_version=1) WHERE a.run_id IS NOT NULL;
DO $$ DECLARE v record; BEGIN SELECT * INTO v FROM _m2_2_acceptance; IF v.final_run_status<>'M2_2_ACCEPTED' OR v.final_contract_status<>'ACCEPTED' OR v.gate_status<>'PASS' THEN RAISE EXCEPTION 'M2.2 final acceptance state failed: %',row_to_json(v); END IF; END $$;
COMMIT; SELECT * FROM _m2_2_acceptance;
