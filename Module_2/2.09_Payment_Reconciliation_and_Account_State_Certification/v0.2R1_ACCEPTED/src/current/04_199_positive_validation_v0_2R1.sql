/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.9 — Payment Reconciliation, Exception Resolution
             & Account State Certification

Program     : 199_msbf_m2_9_payment_reconciliation_certification_validation_v0_2R1.sql
Version     : v0.2R1

Purpose
-------
Execute 120 substantive positive controls across lifecycle, accepted M2.8
identity, dictionaries, account/payment/transition sources, event and account
reconciliation, exception resolution, account-state certification, portfolio,
latest/archive reproduction, stress non-improvement, hashes, canonical
identity, and acceptance readiness.

Required result
---------------
120 / 120 PASS and run_status=M2_9_VALIDATED.
============================================================================ */
BEGIN; SET LOCAL work_mem='160MB'; SET LOCAL statement_timeout='55min'; SET LOCAL jit=off;
DROP TABLE IF EXISTS _m2_9_validation;
CREATE TEMP TABLE _m2_9_validation(evidence_code text PRIMARY KEY,metric_name text NOT NULL,observed_value text,
threshold_value text,status text NOT NULL,interpretation text NOT NULL) ON COMMIT PRESERVE ROWS;
DROP TABLE IF EXISTS _m2_9_vctx;
CREATE TEMP TABLE _m2_9_vctx ON COMMIT DROP AS SELECT run_id,run_status FROM msbf_ctl.run_registry
WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1;
DO $ready$ BEGIN PERFORM msbf_ctl.m2_9_assert_validation_ready((SELECT run_id FROM _m2_9_vctx)); END;$ready$;
CREATE OR REPLACE FUNCTION pg_temp.m2_9_add_check(p_code text,p_metric text,p_observed text,p_threshold text,p_pass boolean,p_interpretation text)
RETURNS void LANGUAGE plpgsql AS $function$ BEGIN INSERT INTO _m2_9_validation VALUES(p_code,p_metric,p_observed,p_threshold,CASE WHEN p_pass THEN 'PASS' ELSE 'FAIL' END,p_interpretation); END;$function$;
/* ============================================================================
Section 1 — One hundred twenty governed positive controls
============================================================================ */
DO $controls$ BEGIN
    /* Controls 001–015 — lifecycle, policy, accepted M2.8 identity, and registry. */
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_001_RUN_STATUS','RUN_STATUS',((SELECT run_status FROM _m2_9_vctx))::text,'M2_9_GENERATED|M2_9_VALIDATED',
        coalesce(((SELECT run_status IN('M2_9_GENERATED','M2_9_VALIDATED') FROM _m2_9_vctx)),FALSE),'Validation begins from aligned generated or validated state.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_002_CONTRACT_STATUS','CONTRACT_STATUS',((SELECT contract_status FROM msbf_ctl.m2_9_reconciliation_certification_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx)))::text,'GENERATED|VALIDATED',
        coalesce(((SELECT contract_status IN('GENERATED','VALIDATED') FROM msbf_ctl.m2_9_reconciliation_certification_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx))),FALSE),'Registry lifecycle is aligned.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_003_POLICY_STATUS','POLICY_STATUS',((SELECT policy_status FROM msbf_ctl.m2_9_policy_profile WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx)))::text,'APPROVED',
        coalesce(((SELECT policy_status='APPROVED' FROM msbf_ctl.m2_9_policy_profile WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx))),FALSE),'M2.9 policy is approved.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_004_METHOD_CONTRACT','METHOD_CONTRACT',((SELECT methodology_version||'|'||contract_code||'|'||contract_version||'|'||schema_version FROM msbf_ctl.m2_9_policy_profile WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx)))::text,'M2_9_METHOD_V1|M2_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_CONSUMPTION|1|M2_9_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_SCHEMA_V1',
        coalesce(((SELECT methodology_version='M2_9_METHOD_V1' AND contract_code='M2_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_CONSUMPTION' AND contract_version=1 AND schema_version='M2_9_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_SCHEMA_V1' FROM msbf_ctl.m2_9_policy_profile WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx))),FALSE),'Methodology and contract identity are exact.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_005_SOURCE_IDENTITY','SOURCE_IDENTITY',((SELECT source_contract_code||'|'||source_contract_version||'|'||source_schema_version||'|'||source_combined_set_hash FROM msbf_ctl.m2_9_policy_profile WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx)))::text,'M2_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONSUMPTION|1|M2_8_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_SCHEMA_V1|ab32d80ba20c2c8f0a6ec9ec97c2ed26',
        coalesce(((SELECT source_contract_code='M2_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONSUMPTION' AND source_contract_version=1 AND source_schema_version='M2_8_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_SCHEMA_V1' AND source_combined_set_hash='ab32d80ba20c2c8f0a6ec9ec97c2ed26' FROM msbf_ctl.m2_9_policy_profile WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx))),FALSE),'Accepted M2.8 identity is frozen.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_006_SOURCE_REGISTRY','SOURCE_REGISTRY',((SELECT contract_status||'|'||contract_code||'|'||contract_version||'|'||schema_version||'|'||combined_set_hash FROM msbf_ctl.m2_8_servicing_execution_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx)))::text,'ACCEPTED|M2_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONSUMPTION|1|M2_8_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_SCHEMA_V1|ab32d80ba20c2c8f0a6ec9ec97c2ed26',
        coalesce(((SELECT contract_status='ACCEPTED' AND contract_code='M2_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONSUMPTION' AND contract_version=1 AND schema_version='M2_8_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_SCHEMA_V1' AND combined_set_hash='ab32d80ba20c2c8f0a6ec9ec97c2ed26' FROM msbf_ctl.m2_8_servicing_execution_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx))),FALSE),'Physical accepted M2.8 registry is exact.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_007_SOURCE_GATE','SOURCE_GATE',((SELECT result_status FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM _m2_9_vctx) AND gate_id='M2_8_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONTROL' AND review_version=1))::text,'PASS',
        coalesce(((SELECT result_status='PASS' FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM _m2_9_vctx) AND gate_id='M2_8_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONTROL' AND review_version=1)),FALSE),'M2.8 acceptance gate is PASS.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_008_CONFIGURATION_HASH','CONFIGURATION_HASH',((SELECT configuration_hash FROM msbf_ctl.m2_9_policy_profile WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx)))::text,'physical configuration hash',
        coalesce(((SELECT configuration_hash=msbf_ctl.m2_9_hash_jsonb(configuration_payload) FROM msbf_ctl.m2_9_policy_profile WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx))),FALSE),'Configuration hash reconstructs.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_009_POLICY_ROW_HASH','POLICY_ROW_HASH_ERRORS',((SELECT count(*) FROM msbf_ctl.m2_9_policy_profile AS p WHERE p.module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND p.row_hash IS DISTINCT FROM msbf_ctl.m2_9_hash_jsonb(to_jsonb(p)-'row_hash'-'created_at'-'updated_at')))::text,'0',
        coalesce(((SELECT count(*)=0 FROM msbf_ctl.m2_9_policy_profile AS p WHERE p.module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND p.row_hash IS DISTINCT FROM msbf_ctl.m2_9_hash_jsonb(to_jsonb(p)-'row_hash'-'created_at'-'updated_at'))),FALSE),'Policy row hash reconstructs.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_010_POLICY_BOUNDARIES','POLICY_BOUNDARIES',((SELECT synthetic_data_only_flag AND reconciliation_certification_only_flag AND preserve_m2_8_history_flag AND no_real_funds_movement_flag AND no_bank_account_data_flag AND no_ach_or_network_transmission_flag AND no_external_processor_call_flag AND no_real_merchant_contact_flag AND no_write_off_or_collection_execution_flag AND no_external_notice_generation_flag AND no_production_adverse_action_flag FROM msbf_ctl.m2_9_policy_profile WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx)))::text,'true',
        coalesce(((SELECT synthetic_data_only_flag AND reconciliation_certification_only_flag AND preserve_m2_8_history_flag AND no_real_funds_movement_flag AND no_bank_account_data_flag AND no_ach_or_network_transmission_flag AND no_external_processor_call_flag AND no_real_merchant_contact_flag AND no_write_off_or_collection_execution_flag AND no_external_notice_generation_flag AND no_production_adverse_action_flag FROM msbf_ctl.m2_9_policy_profile WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx))),FALSE),'All policy boundaries are enabled.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_011_POLICY_TOLERANCES','POLICY_TOLERANCES',((SELECT reconciliation_tolerance_amount||'|'||exposure_tolerance_amount||'|'||maximum_exception_resolution_days FROM msbf_ctl.m2_9_policy_profile WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx)))::text,'0.00|0.00|1',
        coalesce(((SELECT reconciliation_tolerance_amount=0 AND exposure_tolerance_amount=0 AND maximum_exception_resolution_days=1 FROM msbf_ctl.m2_9_policy_profile WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx))),FALSE),'Tolerance and exception-resolution parameters are exact.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_012_GATE_CATALOG','GATE_CATALOG_ROWS',((SELECT count(*) FROM msbf_ref.acceptance_gate_catalog WHERE gate_id='M2_9_PAYMENT_RECONCILIATION_EXCEPTION_RESOLUTION_ACCOUNT_STATE_CERTIFICATION' AND active_flag))::text,'1',
        coalesce(((SELECT count(*)=1 FROM msbf_ref.acceptance_gate_catalog WHERE gate_id='M2_9_PAYMENT_RECONCILIATION_EXCEPTION_RESOLUTION_ACCOUNT_STATE_CERTIFICATION' AND active_flag)),FALSE),'M2.9 gate is registered.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_013_REGISTRY_ROW_COUNT','REGISTRY_ROWS',((SELECT count(*) FROM msbf_ctl.m2_9_reconciliation_certification_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx)))::text,'1',
        coalesce(((SELECT count(*)=1 FROM msbf_ctl.m2_9_reconciliation_certification_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx))),FALSE),'Exactly one registry row exists.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_014_REGISTRY_COUNTS','REGISTRY_COUNTS',((SELECT account_source_rows||'|'||payment_source_rows||'|'||transition_source_rows||'|'||payment_reconciliation_rows||'|'||exception_case_rows||'|'||account_reconciliation_rows||'|'||state_certification_rows||'|'||latest_rows||'|'||archive_rows||'|'||comparison_rows||'|'||canonical_entities FROM msbf_ctl.m2_9_reconciliation_certification_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx)))::text,'59|7|67|7|1|59|59|59|59|15|438',
        coalesce(((SELECT account_source_rows=59 AND payment_source_rows=7 AND transition_source_rows=67 AND payment_reconciliation_rows=7 AND exception_case_rows=1 AND account_reconciliation_rows=59 AND state_certification_rows=59 AND latest_rows=59 AND archive_rows=59 AND comparison_rows=15 AND canonical_entities=438 FROM msbf_ctl.m2_9_reconciliation_certification_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx))),FALSE),'Registry cardinalities are exact.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_015_REGISTRY_TOTALS','REGISTRY_TOTALS',((SELECT no_payment_activity_rows||'|'||reconciled_after_retry_rows||'|'||review_hold_rows||'|'||exception_resolved_rows||'|'||unresolved_exception_rows||'|'||processed_payment_amount||'|'||portfolio_certified_exposure_amount FROM msbf_ctl.m2_9_reconciliation_certification_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx)))::text,'57|1|1|1|0|194.25|785.48',
        coalesce(((SELECT no_payment_activity_rows=57 AND reconciled_after_retry_rows=1 AND review_hold_rows=1 AND exception_resolved_rows=1 AND unresolved_exception_rows=0 AND processed_payment_amount=194.25 AND portfolio_certified_exposure_amount=785.48 FROM msbf_ctl.m2_9_reconciliation_certification_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx))),FALSE),'Registry business totals are exact.'
    );
    /* Controls 016–035 — governed dictionaries, domains, hashes, and references. */
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_016_OUTCOME_COUNT','OUTCOME_COUNT',((SELECT count(*) FROM msbf_m2.payment_reconciliation_outcome_definition WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx)))::text,'7',
        coalesce(((SELECT count(*)=7 FROM msbf_m2.payment_reconciliation_outcome_definition WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx))),FALSE),'Outcome Count is exact.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_017_ACTION_COUNT','ACTION_COUNT',((SELECT count(*) FROM msbf_m2.exception_resolution_action_definition WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx)))::text,'7',
        coalesce(((SELECT count(*)=7 FROM msbf_m2.exception_resolution_action_definition WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx))),FALSE),'Action Count is exact.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_018_CERTIFICATION_COUNT','CERTIFICATION_COUNT',((SELECT count(*) FROM msbf_m2.account_state_certification_definition WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx)))::text,'7',
        coalesce(((SELECT count(*)=7 FROM msbf_m2.account_state_certification_definition WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx))),FALSE),'Certification Count is exact.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_019_REASON_COUNT','REASON_COUNT',((SELECT count(*) FROM msbf_m2.payment_reconciliation_reason_definition WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx)))::text,'36',
        coalesce(((SELECT count(*)=36 FROM msbf_m2.payment_reconciliation_reason_definition WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx))),FALSE),'Reason Count is exact.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_020_DEFINITIONS_APPROVED','NONAPPROVED_DEFINITIONS',((SELECT (SELECT count(*) FROM msbf_m2.payment_reconciliation_outcome_definition WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND definition_status<>'APPROVED')+(SELECT count(*) FROM msbf_m2.exception_resolution_action_definition WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND definition_status<>'APPROVED')+(SELECT count(*) FROM msbf_m2.account_state_certification_definition WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND definition_status<>'APPROVED')+(SELECT count(*) FROM msbf_m2.payment_reconciliation_reason_definition WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND definition_status<>'APPROVED')))::text,'0',
        coalesce(((SELECT (SELECT count(*) FROM msbf_m2.payment_reconciliation_outcome_definition WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND definition_status<>'APPROVED')+(SELECT count(*) FROM msbf_m2.exception_resolution_action_definition WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND definition_status<>'APPROVED')+(SELECT count(*) FROM msbf_m2.account_state_certification_definition WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND definition_status<>'APPROVED')+(SELECT count(*) FROM msbf_m2.payment_reconciliation_reason_definition WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND definition_status<>'APPROVED')=0)),FALSE),'All definitions are approved.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_021_DEFINITION_BOUNDARY','DEFINITION_BOUNDARY_ROWS',((SELECT (SELECT count(*) FROM msbf_m2.payment_reconciliation_outcome_definition WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND (real_funds_moved_flag OR production_state_updated_flag))+(SELECT count(*) FROM msbf_m2.exception_resolution_action_definition WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND (real_funds_moved_flag OR external_system_called_flag))+(SELECT count(*) FROM msbf_m2.account_state_certification_definition WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND production_account_state_flag)+(SELECT count(*) FROM msbf_m2.payment_reconciliation_reason_definition WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND (real_execution_reason_flag OR production_adverse_action_flag))))::text,'0',
        coalesce(((SELECT (SELECT count(*) FROM msbf_m2.payment_reconciliation_outcome_definition WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND (real_funds_moved_flag OR production_state_updated_flag))+(SELECT count(*) FROM msbf_m2.exception_resolution_action_definition WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND (real_funds_moved_flag OR external_system_called_flag))+(SELECT count(*) FROM msbf_m2.account_state_certification_definition WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND production_account_state_flag)+(SELECT count(*) FROM msbf_m2.payment_reconciliation_reason_definition WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND (real_execution_reason_flag OR production_adverse_action_flag))=0)),FALSE),'Definition boundaries are non-production.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_022_OUTCOME_HASH','OUTCOME_HASH_ERRORS',((SELECT count(*) FROM msbf_m2.payment_reconciliation_outcome_definition AS d WHERE d.module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND d.row_hash IS DISTINCT FROM msbf_ctl.m2_9_hash_jsonb(to_jsonb(d)-'row_hash'-'created_at')))::text,'0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.payment_reconciliation_outcome_definition AS d WHERE d.module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND d.row_hash IS DISTINCT FROM msbf_ctl.m2_9_hash_jsonb(to_jsonb(d)-'row_hash'-'created_at'))),FALSE),'Outcome Hash reconstructs.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_023_ACTION_HASH','ACTION_HASH_ERRORS',((SELECT count(*) FROM msbf_m2.exception_resolution_action_definition AS d WHERE d.module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND d.row_hash IS DISTINCT FROM msbf_ctl.m2_9_hash_jsonb(to_jsonb(d)-'row_hash'-'created_at')))::text,'0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.exception_resolution_action_definition AS d WHERE d.module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND d.row_hash IS DISTINCT FROM msbf_ctl.m2_9_hash_jsonb(to_jsonb(d)-'row_hash'-'created_at'))),FALSE),'Action Hash reconstructs.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_024_CERTIFICATION_HASH','CERTIFICATION_HASH_ERRORS',((SELECT count(*) FROM msbf_m2.account_state_certification_definition AS d WHERE d.module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND d.row_hash IS DISTINCT FROM msbf_ctl.m2_9_hash_jsonb(to_jsonb(d)-'row_hash'-'created_at')))::text,'0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.account_state_certification_definition AS d WHERE d.module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND d.row_hash IS DISTINCT FROM msbf_ctl.m2_9_hash_jsonb(to_jsonb(d)-'row_hash'-'created_at'))),FALSE),'Certification Hash reconstructs.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_025_REASON_HASH','REASON_HASH_ERRORS',((SELECT count(*) FROM msbf_m2.payment_reconciliation_reason_definition AS d WHERE d.module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND d.row_hash IS DISTINCT FROM msbf_ctl.m2_9_hash_jsonb(to_jsonb(d)-'row_hash'-'created_at')))::text,'0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.payment_reconciliation_reason_definition AS d WHERE d.module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND d.row_hash IS DISTINCT FROM msbf_ctl.m2_9_hash_jsonb(to_jsonb(d)-'row_hash'-'created_at'))),FALSE),'Reason Hash reconstructs.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_026_OUTCOME_RANKS','OUTCOME_RANK_DUPLICATES',((SELECT count(*)-count(DISTINCT reconciliation_outcome_rank) FROM msbf_m2.payment_reconciliation_outcome_definition WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx)))::text,'0',
        coalesce(((SELECT count(*)=count(DISTINCT reconciliation_outcome_rank) FROM msbf_m2.payment_reconciliation_outcome_definition WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx))),FALSE),'Outcome ranks are unique.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_027_ACTION_RANKS','ACTION_RANK_DUPLICATES',((SELECT count(*)-count(DISTINCT resolution_action_rank) FROM msbf_m2.exception_resolution_action_definition WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx)))::text,'0',
        coalesce(((SELECT count(*)=count(DISTINCT resolution_action_rank) FROM msbf_m2.exception_resolution_action_definition WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx))),FALSE),'Action ranks are unique.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_028_CERT_RANKS','CERT_RANK_DUPLICATES',((SELECT count(*)-count(DISTINCT certification_state_rank) FROM msbf_m2.account_state_certification_definition WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx)))::text,'0',
        coalesce(((SELECT count(*)=count(DISTINCT certification_state_rank) FROM msbf_m2.account_state_certification_definition WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx))),FALSE),'Certification ranks are unique.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_029_REASON_OUTCOME_FK','REASON_OUTCOME_ERRORS',((SELECT count(*) FROM msbf_m2.payment_reconciliation_reason_definition AS r LEFT JOIN msbf_m2.payment_reconciliation_outcome_definition AS o ON o.module1_run_id=r.module1_run_id AND o.reconciliation_outcome_code=r.mapped_outcome_code WHERE r.module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND o.reconciliation_outcome_code IS NULL))::text,'0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.payment_reconciliation_reason_definition AS r LEFT JOIN msbf_m2.payment_reconciliation_outcome_definition AS o ON o.module1_run_id=r.module1_run_id AND o.reconciliation_outcome_code=r.mapped_outcome_code WHERE r.module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND o.reconciliation_outcome_code IS NULL)),FALSE),'Every reason maps to an outcome.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_030_REASON_ACTION_FK','REASON_ACTION_ERRORS',((SELECT count(*) FROM msbf_m2.payment_reconciliation_reason_definition AS r LEFT JOIN msbf_m2.exception_resolution_action_definition AS a ON a.module1_run_id=r.module1_run_id AND a.resolution_action_code=r.mapped_action_code WHERE r.module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND a.resolution_action_code IS NULL))::text,'0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.payment_reconciliation_reason_definition AS r LEFT JOIN msbf_m2.exception_resolution_action_definition AS a ON a.module1_run_id=r.module1_run_id AND a.resolution_action_code=r.mapped_action_code WHERE r.module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND a.resolution_action_code IS NULL)),FALSE),'Every reason maps to an action.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_031_OUTCOME_DOMAIN','OUTCOME_DOMAIN_ROWS',((SELECT count(*) FROM msbf_m2.payment_reconciliation_outcome_definition WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND reconciliation_outcome_code IN('NO_PAYMENT_ACTIVITY_RECONCILED','PAYMENT_ACTIVITY_RECONCILED','PAYMENT_ACTIVITY_RECONCILED_AFTER_RETRY','PAYMENT_ACTIVITY_VARIANCE','PAYMENT_EXCEPTION_UNRESOLVED','RECONCILIATION_REVIEW_HOLD','RECONCILIATION_CERTIFICATION_FAILED')))::text,'7',
        coalesce(((SELECT count(*)=7 FROM msbf_m2.payment_reconciliation_outcome_definition WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND reconciliation_outcome_code IN('NO_PAYMENT_ACTIVITY_RECONCILED','PAYMENT_ACTIVITY_RECONCILED','PAYMENT_ACTIVITY_RECONCILED_AFTER_RETRY','PAYMENT_ACTIVITY_VARIANCE','PAYMENT_EXCEPTION_UNRESOLVED','RECONCILIATION_REVIEW_HOLD','RECONCILIATION_CERTIFICATION_FAILED'))),FALSE),'Complete outcome domain is present.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_032_ACTION_DOMAIN','ACTION_DOMAIN_ROWS',((SELECT count(*) FROM msbf_m2.exception_resolution_action_definition WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND resolution_action_code IN('NO_EXCEPTION_ACTION_REQUIRED','CERTIFY_NO_PAYMENT_ACTIVITY','CERTIFY_RECONCILED_PAYMENT_HISTORY','RESOLVE_RETURN_WITH_RETRY','HOLD_FOR_ACCOUNT_STATE_REVIEW','ESCALATE_UNRESOLVED_PAYMENT_EXCEPTION','BLOCK_ACCOUNT_STATE_CERTIFICATION')))::text,'7',
        coalesce(((SELECT count(*)=7 FROM msbf_m2.exception_resolution_action_definition WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND resolution_action_code IN('NO_EXCEPTION_ACTION_REQUIRED','CERTIFY_NO_PAYMENT_ACTIVITY','CERTIFY_RECONCILED_PAYMENT_HISTORY','RESOLVE_RETURN_WITH_RETRY','HOLD_FOR_ACCOUNT_STATE_REVIEW','ESCALATE_UNRESOLVED_PAYMENT_EXCEPTION','BLOCK_ACCOUNT_STATE_CERTIFICATION'))),FALSE),'Complete action domain is present.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_033_CERT_DOMAIN','CERT_DOMAIN_ROWS',((SELECT count(*) FROM msbf_m2.account_state_certification_definition WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND certification_state_code IN('CERTIFIED_CLOSED_NO_PROCESSING','CERTIFIED_ACTIVE_CURRENT','CERTIFIED_ACTIVE_AFTER_RETRY','CERTIFIED_REASSESSMENT_DUE_AFTER_RETRY','CERTIFIED_REVIEW_HOLD','CERTIFICATION_PENDING','CERTIFICATION_FAILED')))::text,'7',
        coalesce(((SELECT count(*)=7 FROM msbf_m2.account_state_certification_definition WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND certification_state_code IN('CERTIFIED_CLOSED_NO_PROCESSING','CERTIFIED_ACTIVE_CURRENT','CERTIFIED_ACTIVE_AFTER_RETRY','CERTIFIED_REASSESSMENT_DUE_AFTER_RETRY','CERTIFIED_REVIEW_HOLD','CERTIFICATION_PENDING','CERTIFICATION_FAILED'))),FALSE),'Complete certification domain is present.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_034_EXPECTED_COUNTS','EXPECTED_COUNTS',((SELECT expected_account_source_rows||'|'||expected_payment_source_rows||'|'||expected_transition_source_rows||'|'||expected_payment_reconciliation_rows||'|'||expected_exception_case_rows||'|'||expected_account_reconciliation_rows||'|'||expected_state_certification_rows||'|'||expected_canonical_entities FROM msbf_ctl.m2_9_policy_profile WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx)))::text,'59|7|67|7|1|59|59|438',
        coalesce(((SELECT expected_account_source_rows=59 AND expected_payment_source_rows=7 AND expected_transition_source_rows=67 AND expected_payment_reconciliation_rows=7 AND expected_exception_case_rows=1 AND expected_account_reconciliation_rows=59 AND expected_state_certification_rows=59 AND expected_canonical_entities=438 FROM msbf_ctl.m2_9_policy_profile WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx))),FALSE),'Expected counts are exact.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_035_CONTROL_COUNTS','CONTROL_COUNTS',((SELECT expected_positive_controls||'|'||expected_negative_controls||'|'||expected_generation_evidence_rows||'|'||expected_detail_result_sets FROM msbf_ctl.m2_9_policy_profile WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx)))::text,'120|20|24|24',
        coalesce(((SELECT expected_positive_controls=120 AND expected_negative_controls=20 AND expected_generation_evidence_rows=24 AND expected_detail_result_sets=24 FROM msbf_ctl.m2_9_policy_profile WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx))),FALSE),'Control and reporting inventory is exact.'
    );
    /* Controls 036–050 — accepted account, payment-event, and transition sources. */
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_036_ACCOUNT_SOURCE_COUNT','ACCOUNT_SOURCE_COUNT',((SELECT count(*) FROM msbf_m2.account_reconciliation_source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx)))::text,'59',
        coalesce(((SELECT count(*)=59 FROM msbf_m2.account_reconciliation_source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx))),FALSE),'Account Source Count is exact.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_037_PAYMENT_SOURCE_COUNT','PAYMENT_SOURCE_COUNT',((SELECT count(*) FROM msbf_m2.payment_reconciliation_source_event WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx)))::text,'7',
        coalesce(((SELECT count(*)=7 FROM msbf_m2.payment_reconciliation_source_event WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx))),FALSE),'Payment Source Count is exact.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_038_TRANSITION_SOURCE_COUNT','TRANSITION_SOURCE_COUNT',((SELECT count(*) FROM msbf_m2.lifecycle_certification_source_transition WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx)))::text,'67',
        coalesce(((SELECT count(*)=67 FROM msbf_m2.lifecycle_certification_source_transition WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx))),FALSE),'Transition Source Count is exact.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_039_ACCOUNT_SOURCE_GRAIN','ACCOUNT_SOURCE_DUPLICATES',((SELECT count(*)-count(DISTINCT scenario_id::text||'|'||merchant_application_id) FROM msbf_m2.account_reconciliation_source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx)))::text,'0',
        coalesce(((SELECT count(*)=count(DISTINCT scenario_id::text||'|'||merchant_application_id) FROM msbf_m2.account_reconciliation_source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx))),FALSE),'Account source grain is unique.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_040_PAYMENT_SOURCE_GRAIN','PAYMENT_SOURCE_DUPLICATES',((SELECT count(*)-count(DISTINCT scenario_id::text||'|'||merchant_application_id||'|'||event_sequence) FROM msbf_m2.payment_reconciliation_source_event WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx)))::text,'0',
        coalesce(((SELECT count(*)=count(DISTINCT scenario_id::text||'|'||merchant_application_id||'|'||event_sequence) FROM msbf_m2.payment_reconciliation_source_event WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx))),FALSE),'Payment source grain is unique.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_041_TRANSITION_SOURCE_GRAIN','TRANSITION_SOURCE_DUPLICATES',((SELECT count(*)-count(DISTINCT scenario_id::text||'|'||merchant_application_id||'|'||transition_sequence) FROM msbf_m2.lifecycle_certification_source_transition WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx)))::text,'0',
        coalesce(((SELECT count(*)=count(DISTINCT scenario_id::text||'|'||merchant_application_id||'|'||transition_sequence) FROM msbf_m2.lifecycle_certification_source_transition WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx))),FALSE),'Transition source grain is unique.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_042_ACCOUNT_SOURCE_POSTURE','ACCOUNT_SOURCE_POSTURE',((SELECT count(*) FILTER(WHERE source_no_processing_required_flag)||'|'||count(*) FILTER(WHERE source_processing_authorized_flag)||'|'||count(*) FILTER(WHERE source_processing_review_required_flag) FROM msbf_m2.account_reconciliation_source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx)))::text,'57|1|1',
        coalesce(((SELECT count(*) FILTER(WHERE source_no_processing_required_flag)=57 AND count(*) FILTER(WHERE source_processing_authorized_flag)=1 AND count(*) FILTER(WHERE source_processing_review_required_flag)=1 FROM msbf_m2.account_reconciliation_source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx))),FALSE),'Accepted account posture is 57/1/1.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_043_ACCOUNT_SOURCE_AMOUNTS','ACCOUNT_SOURCE_AMOUNTS',((SELECT round(sum(source_exposure_amount),2)||'|'||round(sum(source_processed_payment_amount),2)||'|'||round(sum(source_ending_exposure_amount),2) FROM msbf_m2.account_reconciliation_source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx)))::text,'979.73|194.25|785.48',
        coalesce(((SELECT round(sum(source_exposure_amount),2)=979.73 AND round(sum(source_processed_payment_amount),2)=194.25 AND round(sum(source_ending_exposure_amount),2)=785.48 FROM msbf_m2.account_reconciliation_source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx))),FALSE),'Accepted account source amounts are exact.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_044_PAYMENT_SOURCE_STATUS','PAYMENT_SOURCE_STATUS',((SELECT count(*) FILTER(WHERE payment_status_code='SIMULATED_SETTLED')||'|'||count(*) FILTER(WHERE payment_status_code='SIMULATED_RETURNED')||'|'||count(*) FILTER(WHERE payment_status_code='SIMULATED_RETRY_SETTLED') FROM msbf_m2.payment_reconciliation_source_event WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx)))::text,'5|1|1',
        coalesce(((SELECT count(*) FILTER(WHERE payment_status_code='SIMULATED_SETTLED')=5 AND count(*) FILTER(WHERE payment_status_code='SIMULATED_RETURNED')=1 AND count(*) FILTER(WHERE payment_status_code='SIMULATED_RETRY_SETTLED')=1 FROM msbf_m2.payment_reconciliation_source_event WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx))),FALSE),'Accepted payment status counts are exact.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_045_PAYMENT_SOURCE_AMOUNTS','PAYMENT_SOURCE_AMOUNTS',((SELECT round(sum(scheduled_payment_amount),2)||'|'||round(sum(processed_payment_amount),2)||'|'||round(sum(returned_payment_amount),2)||'|'||round(sum(retry_payment_amount),2) FROM msbf_m2.payment_reconciliation_source_event WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx)))::text,'194.25|194.25|27.75|27.75',
        coalesce(((SELECT round(sum(scheduled_payment_amount),2)=194.25 AND round(sum(processed_payment_amount),2)=194.25 AND round(sum(returned_payment_amount),2)=27.75 AND round(sum(retry_payment_amount),2)=27.75 FROM msbf_m2.payment_reconciliation_source_event WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx))),FALSE),'Accepted payment amounts are exact.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_046_TRANSITION_SOURCE_POSTURE','TRANSITION_SOURCE_POSTURE',((SELECT count(*) FILTER(WHERE transition_sequence=0)||'|'||count(*) FILTER(WHERE transition_type_code IN('PAYMENT_PROCESSING_EVENT','PAYMENT_RETURN_EVENT','PAYMENT_RETRY_EVENT'))||'|'||count(*) FILTER(WHERE transition_type_code='REASSESSMENT_CHECKPOINT') FROM msbf_m2.lifecycle_certification_source_transition WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx)))::text,'59|7|1',
        coalesce(((SELECT count(*) FILTER(WHERE transition_sequence=0)=59 AND count(*) FILTER(WHERE transition_type_code IN('PAYMENT_PROCESSING_EVENT','PAYMENT_RETURN_EVENT','PAYMENT_RETRY_EVENT'))=7 AND count(*) FILTER(WHERE transition_type_code='REASSESSMENT_CHECKPOINT')=1 FROM msbf_m2.lifecycle_certification_source_transition WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx))),FALSE),'Accepted transition posture is exact.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_047_ACCOUNT_SOURCE_HASH','ACCOUNT_SOURCE_HASH_ERRORS',((SELECT count(*) FROM msbf_m2.account_reconciliation_source_snapshot AS s WHERE s.module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND s.row_hash IS DISTINCT FROM msbf_ctl.m2_9_hash_jsonb(to_jsonb(s)-'row_hash'-'created_at')))::text,'0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.account_reconciliation_source_snapshot AS s WHERE s.module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND s.row_hash IS DISTINCT FROM msbf_ctl.m2_9_hash_jsonb(to_jsonb(s)-'row_hash'-'created_at'))),FALSE),'Account Source Hash reconstructs.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_048_PAYMENT_SOURCE_HASH','PAYMENT_SOURCE_HASH_ERRORS',((SELECT count(*) FROM msbf_m2.payment_reconciliation_source_event AS s WHERE s.module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND s.row_hash IS DISTINCT FROM msbf_ctl.m2_9_hash_jsonb(to_jsonb(s)-'row_hash'-'created_at')))::text,'0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.payment_reconciliation_source_event AS s WHERE s.module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND s.row_hash IS DISTINCT FROM msbf_ctl.m2_9_hash_jsonb(to_jsonb(s)-'row_hash'-'created_at'))),FALSE),'Payment Source Hash reconstructs.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_049_TRANSITION_SOURCE_HASH','TRANSITION_SOURCE_HASH_ERRORS',((SELECT count(*) FROM msbf_m2.lifecycle_certification_source_transition AS s WHERE s.module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND s.row_hash IS DISTINCT FROM msbf_ctl.m2_9_hash_jsonb(to_jsonb(s)-'row_hash'-'created_at')))::text,'0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.lifecycle_certification_source_transition AS s WHERE s.module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND s.row_hash IS DISTINCT FROM msbf_ctl.m2_9_hash_jsonb(to_jsonb(s)-'row_hash'-'created_at'))),FALSE),'Transition Source Hash reconstructs.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_050_SOURCE_COMBINED_HASH','SOURCE_COMBINED_HASH_ERRORS',((SELECT (SELECT count(*) FROM msbf_m2.account_reconciliation_source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND source_combined_set_hash<>'ab32d80ba20c2c8f0a6ec9ec97c2ed26')+(SELECT count(*) FROM msbf_m2.payment_reconciliation_source_event WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND source_combined_set_hash<>'ab32d80ba20c2c8f0a6ec9ec97c2ed26')+(SELECT count(*) FROM msbf_m2.lifecycle_certification_source_transition WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND source_combined_set_hash<>'ab32d80ba20c2c8f0a6ec9ec97c2ed26')))::text,'0',
        coalesce(((SELECT (SELECT count(*) FROM msbf_m2.account_reconciliation_source_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND source_combined_set_hash<>'ab32d80ba20c2c8f0a6ec9ec97c2ed26')+(SELECT count(*) FROM msbf_m2.payment_reconciliation_source_event WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND source_combined_set_hash<>'ab32d80ba20c2c8f0a6ec9ec97c2ed26')+(SELECT count(*) FROM msbf_m2.lifecycle_certification_source_transition WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND source_combined_set_hash<>'ab32d80ba20c2c8f0a6ec9ec97c2ed26')=0)),FALSE),'All source rows preserve the accepted M2.8 combined hash.'
    );
    /* Controls 051–075 — payment-event reconciliation and resolved exception evidence. */
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_051_PAYMENT_RECON_COUNT','PAYMENT_RECON_ROWS',((SELECT count(*) FROM msbf_m2.payment_event_reconciliation_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx)))::text,'7',
        coalesce(((SELECT count(*)=7 FROM msbf_m2.payment_event_reconciliation_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx))),FALSE),'Seven payment events are reconciled.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_052_PAYMENT_RECON_GRAIN','PAYMENT_RECON_DUPLICATES',((SELECT count(*)-count(DISTINCT scenario_id::text||'|'||merchant_application_id||'|'||event_sequence) FROM msbf_m2.payment_event_reconciliation_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx)))::text,'0',
        coalesce(((SELECT count(*)=count(DISTINCT scenario_id::text||'|'||merchant_application_id||'|'||event_sequence) FROM msbf_m2.payment_event_reconciliation_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx))),FALSE),'Payment reconciliation grain is unique.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_053_EVENT_STATUS_COUNTS','EVENT_STATUS_COUNTS',((SELECT count(*) FILTER(WHERE event_reconciliation_status_code='RECONCILED_SETTLED')||'|'||count(*) FILTER(WHERE event_reconciliation_status_code='RECONCILED_RETURN')||'|'||count(*) FILTER(WHERE event_reconciliation_status_code='RECONCILED_RETRY_SETTLED') FROM msbf_m2.payment_event_reconciliation_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx)))::text,'5|1|1',
        coalesce(((SELECT count(*) FILTER(WHERE event_reconciliation_status_code='RECONCILED_SETTLED')=5 AND count(*) FILTER(WHERE event_reconciliation_status_code='RECONCILED_RETURN')=1 AND count(*) FILTER(WHERE event_reconciliation_status_code='RECONCILED_RETRY_SETTLED')=1 FROM msbf_m2.payment_event_reconciliation_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx))),FALSE),'Event reconciliation statuses are exact.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_054_EVENT_FORMULA','EVENT_FORMULA_ERRORS',((SELECT count(*) FROM msbf_m2.payment_event_reconciliation_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND expected_effective_processed_amount<>(scheduled_payment_amount-returned_payment_amount+retry_payment_amount)))::text,'0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.payment_event_reconciliation_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND expected_effective_processed_amount<>(scheduled_payment_amount-returned_payment_amount+retry_payment_amount))),FALSE),'Event net formula is exact.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_055_EVENT_VARIANCE','EVENT_VARIANCE_AMOUNT',((SELECT round(sum(reconciliation_variance_amount),2) FROM msbf_m2.payment_event_reconciliation_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx)))::text,'0.00',
        coalesce(((SELECT round(sum(reconciliation_variance_amount),2)=0 FROM msbf_m2.payment_event_reconciliation_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx))),FALSE),'Event reconciliation variance is zero.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_056_RETURN_EXCEPTION','RETURN_EXCEPTION_ROWS',((SELECT count(*) FROM msbf_m2.payment_event_reconciliation_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND payment_status_code='SIMULATED_RETURNED' AND exception_case_required_flag AND NOT exception_resolved_flag))::text,'1',
        coalesce(((SELECT count(*)=1 FROM msbf_m2.payment_event_reconciliation_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND payment_status_code='SIMULATED_RETURNED' AND exception_case_required_flag AND NOT exception_resolved_flag)),FALSE),'Returned event opens the shared exception case; the subsequent retry event records resolution.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_057_RETRY_RESOLUTION','RETRY_RESOLUTION_ROWS',((SELECT count(*) FROM msbf_m2.payment_event_reconciliation_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND payment_status_code='SIMULATED_RETRY_SETTLED' AND exception_resolved_flag))::text,'1',
        coalesce(((SELECT count(*)=1 FROM msbf_m2.payment_event_reconciliation_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND payment_status_code='SIMULATED_RETRY_SETTLED' AND exception_resolved_flag)),FALSE),'Retry event resolves the exception.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_058_EXCEPTION_COUNT','EXCEPTION_CASE_ROWS',((SELECT count(*) FROM msbf_m2.payment_exception_case_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx)))::text,'1',
        coalesce(((SELECT count(*)=1 FROM msbf_m2.payment_exception_case_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx))),FALSE),'Exactly one exception case exists.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_059_EXCEPTION_RESOLVED','RESOLVED_EXCEPTION_ROWS',((SELECT count(*) FROM msbf_m2.payment_exception_case_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND exception_status_code='RESOLVED_BY_RETRY' AND NOT unresolved_exception_flag))::text,'1',
        coalesce(((SELECT count(*)=1 FROM msbf_m2.payment_exception_case_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND exception_status_code='RESOLVED_BY_RETRY' AND NOT unresolved_exception_flag)),FALSE),'Exception is resolved by retry.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_060_EXCEPTION_SEQUENCE','EXCEPTION_SEQUENCE',((SELECT originating_event_sequence||'|'||resolving_event_sequence FROM msbf_m2.payment_exception_case_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx)))::text,'4|5',
        coalesce(((SELECT originating_event_sequence=4 AND resolving_event_sequence=5 FROM msbf_m2.payment_exception_case_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx))),FALSE),'Exception originates at event four and resolves at event five.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_061_EXCEPTION_DATES','EXCEPTION_DATES',((SELECT originating_event_date||'|'||resolving_event_date FROM msbf_m2.payment_exception_case_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx)))::text,'2026-07-27|2026-07-28',
        coalesce(((SELECT originating_event_date=DATE '2026-07-27' AND resolving_event_date=DATE '2026-07-28' FROM msbf_m2.payment_exception_case_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx))),FALSE),'Exception dates are exact.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_062_EXCEPTION_AMOUNT','EXCEPTION_AMOUNT',((SELECT exception_amount FROM msbf_m2.payment_exception_case_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx)))::text,'27.75',
        coalesce(((SELECT exception_amount=27.75 FROM msbf_m2.payment_exception_case_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx))),FALSE),'Exception amount is $27.75.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_063_EXCEPTION_OPEN_DAYS','EXCEPTION_OPEN_DAYS',((SELECT exception_open_days FROM msbf_m2.payment_exception_case_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx)))::text,'1',
        coalesce(((SELECT exception_open_days=1 FROM msbf_m2.payment_exception_case_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx))),FALSE),'Exception resolves in one day.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_064_EXCEPTION_ID_SHAPE','EXCEPTION_ID_ERRORS',((SELECT count(*) FROM msbf_m2.payment_exception_case_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND synthetic_exception_case_id NOT LIKE 'MSBF_EXC_%'))::text,'0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.payment_exception_case_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND synthetic_exception_case_id NOT LIKE 'MSBF_EXC_%')),FALSE),'Exception case identifier has governed shape.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_065_EVENT_EXCEPTION_ID','EVENT_EXCEPTION_ID_ERRORS',((SELECT count(*) FROM msbf_m2.payment_event_reconciliation_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND payment_status_code IN('SIMULATED_RETURNED','SIMULATED_RETRY_SETTLED') AND synthetic_exception_case_id IS NULL))::text,'0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.payment_event_reconciliation_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND payment_status_code IN('SIMULATED_RETURNED','SIMULATED_RETRY_SETTLED') AND synthetic_exception_case_id IS NULL)),FALSE),'Return and retry rows retain exception identity.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_066_EVENT_SOURCE_LINEAGE','EVENT_SOURCE_LINEAGE_ERRORS',((SELECT count(*) FROM msbf_m2.payment_event_reconciliation_snapshot AS r LEFT JOIN msbf_m2.payment_reconciliation_source_event AS s ON s.module1_run_id=r.module1_run_id AND s.scenario_id=r.scenario_id AND s.merchant_application_id=r.merchant_application_id AND s.event_sequence=r.event_sequence WHERE r.module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND (s.row_hash IS NULL OR r.source_event_row_hash IS DISTINCT FROM s.row_hash)))::text,'0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.payment_event_reconciliation_snapshot AS r LEFT JOIN msbf_m2.payment_reconciliation_source_event AS s ON s.module1_run_id=r.module1_run_id AND s.scenario_id=r.scenario_id AND s.merchant_application_id=r.merchant_application_id AND s.event_sequence=r.event_sequence WHERE r.module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND (s.row_hash IS NULL OR r.source_event_row_hash IS DISTINCT FROM s.row_hash))),FALSE),'Event reconciliation preserves the M2.9 source-snapshot row hash; that source snapshot separately retains the accepted M2.8 event hash.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_067_PAYMENT_RECON_HASH','PAYMENT_RECON_HASH_ERRORS',((SELECT count(*) FROM msbf_m2.payment_event_reconciliation_snapshot AS x WHERE x.module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND x.row_hash IS DISTINCT FROM msbf_ctl.m2_9_hash_jsonb(to_jsonb(x)-'row_hash'-'created_at')))::text,'0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.payment_event_reconciliation_snapshot AS x WHERE x.module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND x.row_hash IS DISTINCT FROM msbf_ctl.m2_9_hash_jsonb(to_jsonb(x)-'row_hash'-'created_at'))),FALSE),'Payment Recon Hash reconstructs.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_068_EXCEPTION_HASH','EXCEPTION_HASH_ERRORS',((SELECT count(*) FROM msbf_m2.payment_exception_case_snapshot AS x WHERE x.module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND x.row_hash IS DISTINCT FROM msbf_ctl.m2_9_hash_jsonb(to_jsonb(x)-'row_hash'-'created_at')))::text,'0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.payment_exception_case_snapshot AS x WHERE x.module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND x.row_hash IS DISTINCT FROM msbf_ctl.m2_9_hash_jsonb(to_jsonb(x)-'row_hash'-'created_at'))),FALSE),'Exception Hash reconstructs.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_069_PAYMENT_RECON_BOUNDARY','PAYMENT_RECON_BOUNDARY_ROWS',((SELECT count(*) FROM msbf_m2.payment_event_reconciliation_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND (real_funds_moved_flag OR external_system_called_flag)))::text,'0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.payment_event_reconciliation_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND (real_funds_moved_flag OR external_system_called_flag))),FALSE),'Payment reconciliation is non-production.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_070_EXCEPTION_BOUNDARY','EXCEPTION_BOUNDARY_ROWS',((SELECT count(*) FROM msbf_m2.payment_exception_case_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND (real_funds_moved_flag OR external_system_called_flag)))::text,'0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.payment_exception_case_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND (real_funds_moved_flag OR external_system_called_flag))),FALSE),'Exception resolution is non-production.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_071_EVENT_AMOUNT_TOTALS','EVENT_AMOUNT_TOTALS',((SELECT round(sum(scheduled_payment_amount),2)||'|'||round(sum(processed_payment_amount),2)||'|'||round(sum(returned_payment_amount),2)||'|'||round(sum(retry_payment_amount),2) FROM msbf_m2.payment_event_reconciliation_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx)))::text,'194.25|194.25|27.75|27.75',
        coalesce(((SELECT round(sum(scheduled_payment_amount),2)=194.25 AND round(sum(processed_payment_amount),2)=194.25 AND round(sum(returned_payment_amount),2)=27.75 AND round(sum(retry_payment_amount),2)=27.75 FROM msbf_m2.payment_event_reconciliation_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx))),FALSE),'Reconciled event totals are exact.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_072_EVENT_REASON_FK','EVENT_REASON_ERRORS',((SELECT count(*) FROM msbf_m2.payment_event_reconciliation_snapshot AS e LEFT JOIN msbf_m2.payment_reconciliation_reason_definition AS r ON r.module1_run_id=e.module1_run_id AND r.reconciliation_reason_code=e.primary_reconciliation_reason_code WHERE e.module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND r.reconciliation_reason_code IS NULL))::text,'0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.payment_event_reconciliation_snapshot AS e LEFT JOIN msbf_m2.payment_reconciliation_reason_definition AS r ON r.module1_run_id=e.module1_run_id AND r.reconciliation_reason_code=e.primary_reconciliation_reason_code WHERE e.module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND r.reconciliation_reason_code IS NULL)),FALSE),'Every event reason is governed.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_073_EXCEPTION_ACTION_FK','EXCEPTION_ACTION_ERRORS',((SELECT count(*) FROM msbf_m2.payment_exception_case_snapshot AS e LEFT JOIN msbf_m2.exception_resolution_action_definition AS a ON a.module1_run_id=e.module1_run_id AND a.resolution_action_code=e.resolution_action_code WHERE e.module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND a.resolution_action_code IS NULL))::text,'0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.payment_exception_case_snapshot AS e LEFT JOIN msbf_m2.exception_resolution_action_definition AS a ON a.module1_run_id=e.module1_run_id AND a.resolution_action_code=e.resolution_action_code WHERE e.module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND a.resolution_action_code IS NULL)),FALSE),'Exception action is governed.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_074_EXCEPTION_HASH_LINEAGE','EXCEPTION_HASH_LINEAGE_ERRORS',((SELECT count(*) FROM msbf_m2.payment_exception_case_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND (originating_event_row_hash IS NULL OR resolving_event_row_hash IS NULL)))::text,'0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.payment_exception_case_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND (originating_event_row_hash IS NULL OR resolving_event_row_hash IS NULL))),FALSE),'Exception case preserves originating and resolving hashes.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_075_UNRESOLVED_ZERO','UNRESOLVED_EXCEPTION_ROWS',((SELECT count(*) FROM msbf_m2.payment_exception_case_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND unresolved_exception_flag))::text,'0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.payment_exception_case_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND unresolved_exception_flag)),FALSE),'No unresolved exception remains.'
    );
    /* Controls 076–095 — account reconciliation and state certification. */
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_076_ACCOUNT_RECON_COUNT','ACCOUNT_RECON_ROWS',((SELECT count(*) FROM msbf_m2.account_payment_reconciliation_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx)))::text,'59',
        coalesce(((SELECT count(*)=59 FROM msbf_m2.account_payment_reconciliation_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx))),FALSE),'Fifty-nine accounts are reconciled.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_077_ACCOUNT_RECON_GRAIN','ACCOUNT_RECON_DUPLICATES',((SELECT count(*)-count(DISTINCT scenario_id::text||'|'||merchant_application_id) FROM msbf_m2.account_payment_reconciliation_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx)))::text,'0',
        coalesce(((SELECT count(*)=count(DISTINCT scenario_id::text||'|'||merchant_application_id) FROM msbf_m2.account_payment_reconciliation_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx))),FALSE),'Account reconciliation grain is unique.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_078_ACCOUNT_OUTCOMES','ACCOUNT_OUTCOMES',((SELECT count(*) FILTER(WHERE reconciliation_outcome_code='NO_PAYMENT_ACTIVITY_RECONCILED')||'|'||count(*) FILTER(WHERE reconciliation_outcome_code='PAYMENT_ACTIVITY_RECONCILED_AFTER_RETRY')||'|'||count(*) FILTER(WHERE reconciliation_outcome_code='RECONCILIATION_REVIEW_HOLD') FROM msbf_m2.account_payment_reconciliation_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx)))::text,'57|1|1',
        coalesce(((SELECT count(*) FILTER(WHERE reconciliation_outcome_code='NO_PAYMENT_ACTIVITY_RECONCILED')=57 AND count(*) FILTER(WHERE reconciliation_outcome_code='PAYMENT_ACTIVITY_RECONCILED_AFTER_RETRY')=1 AND count(*) FILTER(WHERE reconciliation_outcome_code='RECONCILIATION_REVIEW_HOLD')=1 FROM msbf_m2.account_payment_reconciliation_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx))),FALSE),'Account outcomes are 57/1/1.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_079_ACCOUNT_CERTIFIED','ACCOUNT_CERTIFIED_ROWS',((SELECT count(*) FROM msbf_m2.account_payment_reconciliation_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND reconciliation_certified_flag))::text,'59',
        coalesce(((SELECT count(*)=59 FROM msbf_m2.account_payment_reconciliation_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND reconciliation_certified_flag)),FALSE),'All accounts are reconciliation-certified.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_080_ACCOUNT_VARIANCE','ACCOUNT_VARIANCE',((SELECT round(sum(reconciliation_variance_amount),2)||'|'||round(sum(exposure_variance_amount),2) FROM msbf_m2.account_payment_reconciliation_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx)))::text,'0.00|0.00',
        coalesce(((SELECT round(sum(reconciliation_variance_amount),2)=0 AND round(sum(exposure_variance_amount),2)=0 FROM msbf_m2.account_payment_reconciliation_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx))),FALSE),'Account payment and exposure variance are zero.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_081_ACCOUNT_FORMULA','ACCOUNT_FORMULA_ERRORS',((SELECT count(*) FROM msbf_m2.account_payment_reconciliation_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND expected_net_processed_amount<>(scheduled_payment_amount-returned_payment_amount+retry_payment_amount)))::text,'0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.account_payment_reconciliation_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND expected_net_processed_amount<>(scheduled_payment_amount-returned_payment_amount+retry_payment_amount))),FALSE),'Account net processed formula is exact.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_082_ACCOUNT_EXPOSURE','ACCOUNT_EXPOSURE_ERRORS',((SELECT count(*) FROM msbf_m2.account_payment_reconciliation_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND source_ending_exposure_amount<>expected_ending_exposure_amount))::text,'0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.account_payment_reconciliation_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND source_ending_exposure_amount<>expected_ending_exposure_amount)),FALSE),'Certified ending exposure equals expected exposure.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_083_ACCOUNT_EXCEPTION_COUNTS','ACCOUNT_EXCEPTION_COUNTS',((SELECT sum(exception_case_count)||'|'||sum(resolved_exception_count)||'|'||sum(unresolved_exception_count) FROM msbf_m2.account_payment_reconciliation_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx)))::text,'1|1|0',
        coalesce(((SELECT sum(exception_case_count)=1 AND sum(resolved_exception_count)=1 AND sum(unresolved_exception_count)=0 FROM msbf_m2.account_payment_reconciliation_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx))),FALSE),'Account exception counts reconcile.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_084_ACCOUNT_REASON_ARRAY','ACCOUNT_REASON_ARRAY_ERRORS',((SELECT count(*) FROM msbf_m2.account_payment_reconciliation_snapshot AS a WHERE a.module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND (jsonb_typeof(a.reconciliation_reason_codes)<>'array' OR jsonb_array_length(a.reconciliation_reason_codes)=0 OR NOT EXISTS(SELECT 1 FROM jsonb_array_elements_text(a.reconciliation_reason_codes) AS x(reason_code) WHERE x.reason_code=a.primary_reconciliation_reason_code))))::text,'0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.account_payment_reconciliation_snapshot AS a WHERE a.module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND (jsonb_typeof(a.reconciliation_reason_codes)<>'array' OR jsonb_array_length(a.reconciliation_reason_codes)=0 OR NOT EXISTS(SELECT 1 FROM jsonb_array_elements_text(a.reconciliation_reason_codes) AS x(reason_code) WHERE x.reason_code=a.primary_reconciliation_reason_code)))),FALSE),'Every account has a nonempty reason array containing its primary reason.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_085_ACCOUNT_LINEAGE','ACCOUNT_LINEAGE_ERRORS',((SELECT count(*) FROM msbf_m2.account_payment_reconciliation_snapshot AS a LEFT JOIN msbf_m2.account_reconciliation_source_snapshot AS s ON s.module1_run_id=a.module1_run_id AND s.scenario_id=a.scenario_id AND s.merchant_application_id=a.merchant_application_id WHERE a.module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND (s.row_hash IS NULL OR a.account_source_row_hash IS DISTINCT FROM s.row_hash OR a.source_contract_row_hash IS DISTINCT FROM s.source_contract_row_hash)))::text,'0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.account_payment_reconciliation_snapshot AS a LEFT JOIN msbf_m2.account_reconciliation_source_snapshot AS s ON s.module1_run_id=a.module1_run_id AND s.scenario_id=a.scenario_id AND s.merchant_application_id=a.merchant_application_id WHERE a.module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND (s.row_hash IS NULL OR a.account_source_row_hash IS DISTINCT FROM s.row_hash OR a.source_contract_row_hash IS DISTINCT FROM s.source_contract_row_hash))),FALSE),'Account reconciliation preserves source lineage.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_086_ACCOUNT_HASH','ACCOUNT_HASH_ERRORS',((SELECT count(*) FROM msbf_m2.account_payment_reconciliation_snapshot AS a WHERE a.module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND a.row_hash IS DISTINCT FROM msbf_ctl.m2_9_hash_jsonb(to_jsonb(a)-'row_hash'-'created_at')))::text,'0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.account_payment_reconciliation_snapshot AS a WHERE a.module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND a.row_hash IS DISTINCT FROM msbf_ctl.m2_9_hash_jsonb(to_jsonb(a)-'row_hash'-'created_at'))),FALSE),'Account reconciliation hashes reconstruct.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_087_ACCOUNT_BOUNDARY','ACCOUNT_BOUNDARY_ROWS',((SELECT count(*) FROM msbf_m2.account_payment_reconciliation_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND (real_funds_moved_flag OR bank_account_data_present_flag OR ach_or_network_transmitted_flag OR external_processor_called_flag OR merchant_contact_executed_flag OR write_off_or_collection_flag OR external_notice_generated_flag OR production_adverse_action_flag)))::text,'0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.account_payment_reconciliation_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND (real_funds_moved_flag OR bank_account_data_present_flag OR ach_or_network_transmitted_flag OR external_processor_called_flag OR merchant_contact_executed_flag OR write_off_or_collection_flag OR external_notice_generated_flag OR production_adverse_action_flag))),FALSE),'Account reconciliation remains non-production.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_088_CERTIFICATION_COUNT','CERTIFICATION_ROWS',((SELECT count(*) FROM msbf_m2.account_state_certification_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx)))::text,'59',
        coalesce(((SELECT count(*)=59 FROM msbf_m2.account_state_certification_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx))),FALSE),'Fifty-nine account states are certified.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_089_CERTIFICATION_STATES','CERTIFICATION_STATES',((SELECT count(*) FILTER(WHERE certified_state_code='CERTIFIED_CLOSED_NO_PROCESSING')||'|'||count(*) FILTER(WHERE certified_state_code='CERTIFIED_REASSESSMENT_DUE_AFTER_RETRY')||'|'||count(*) FILTER(WHERE certified_state_code='CERTIFIED_REVIEW_HOLD') FROM msbf_m2.account_state_certification_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx)))::text,'57|1|1',
        coalesce(((SELECT count(*) FILTER(WHERE certified_state_code='CERTIFIED_CLOSED_NO_PROCESSING')=57 AND count(*) FILTER(WHERE certified_state_code='CERTIFIED_REASSESSMENT_DUE_AFTER_RETRY')=1 AND count(*) FILTER(WHERE certified_state_code='CERTIFIED_REVIEW_HOLD')=1 FROM msbf_m2.account_state_certification_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx))),FALSE),'Certification states are 57/1/1.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_090_STATE_CERTIFIED','STATE_CERTIFIED_ROWS',((SELECT count(*) FROM msbf_m2.account_state_certification_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND state_certified_flag))::text,'59',
        coalesce(((SELECT count(*)=59 FROM msbf_m2.account_state_certification_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND state_certified_flag)),FALSE),'All account states are certified.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_091_CERTIFIED_EXPOSURE','CERTIFIED_EXPOSURE',((SELECT round(sum(certified_exposure_amount),2) FROM msbf_m2.account_state_certification_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx)))::text,'785.48',
        coalesce(((SELECT round(sum(certified_exposure_amount),2)=785.48 FROM msbf_m2.account_state_certification_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx))),FALSE),'Certified portfolio exposure is $785.48.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_092_ACTIVE_EXPOSURE','ACTIVE_CERTIFIED_EXPOSURE',((SELECT round(sum(certified_exposure_amount),2) FROM msbf_m2.account_state_certification_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND active_state_flag))::text,'323.79',
        coalesce(((SELECT round(sum(certified_exposure_amount),2)=323.79 FROM msbf_m2.account_state_certification_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND active_state_flag)),FALSE),'Active certified exposure is $323.79.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_093_REVIEW_EXPOSURE','REVIEW_CERTIFIED_EXPOSURE',((SELECT round(sum(certified_exposure_amount),2) FROM msbf_m2.account_state_certification_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND review_hold_state_flag))::text,'461.69',
        coalesce(((SELECT round(sum(certified_exposure_amount),2)=461.69 FROM msbf_m2.account_state_certification_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND review_hold_state_flag)),FALSE),'Review-hold certified exposure is $461.69.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_094_CERTIFICATION_LINEAGE','CERTIFICATION_LINEAGE_ERRORS',((SELECT count(*) FROM msbf_m2.account_state_certification_snapshot AS c LEFT JOIN msbf_m2.account_payment_reconciliation_snapshot AS a ON a.module1_run_id=c.module1_run_id AND a.scenario_id=c.scenario_id AND a.merchant_application_id=c.merchant_application_id WHERE c.module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND (a.row_hash IS NULL OR c.source_account_reconciliation_row_hash IS DISTINCT FROM a.row_hash)))::text,'0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.account_state_certification_snapshot AS c LEFT JOIN msbf_m2.account_payment_reconciliation_snapshot AS a ON a.module1_run_id=c.module1_run_id AND a.scenario_id=c.scenario_id AND a.merchant_application_id=c.merchant_application_id WHERE c.module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND (a.row_hash IS NULL OR c.source_account_reconciliation_row_hash IS DISTINCT FROM a.row_hash))),FALSE),'Certification preserves account reconciliation lineage.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_095_CERTIFICATION_HASH_BOUNDARY','CERTIFICATION_HASH_BOUNDARY_ERRORS',((SELECT (SELECT count(*) FROM msbf_m2.account_state_certification_snapshot AS c WHERE c.module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND c.row_hash IS DISTINCT FROM msbf_ctl.m2_9_hash_jsonb(to_jsonb(c)-'row_hash'-'created_at'))+(SELECT count(*) FROM msbf_m2.account_state_certification_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND (real_funds_moved_flag OR production_account_state_flag OR external_system_update_flag))))::text,'0',
        coalesce(((SELECT (SELECT count(*) FROM msbf_m2.account_state_certification_snapshot AS c WHERE c.module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND c.row_hash IS DISTINCT FROM msbf_ctl.m2_9_hash_jsonb(to_jsonb(c)-'row_hash'-'created_at'))+(SELECT count(*) FROM msbf_m2.account_state_certification_snapshot WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND (real_funds_moved_flag OR production_account_state_flag OR external_system_update_flag))=0)),FALSE),'Certification hashes reconstruct and boundaries remain false.'
    );
    /* Controls 096–108 — portfolio, latest, archive, and stress comparison. */
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_096_PORTFOLIO_COUNT','PORTFOLIO_ROWS',((SELECT count(*) FROM msbf_m2.payment_reconciliation_portfolio_summary WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx)))::text,'2',
        coalesce(((SELECT count(*)=2 FROM msbf_m2.payment_reconciliation_portfolio_summary WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx))),FALSE),'Two portfolio summaries exist.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_097_PORTFOLIO_COUNTS','PORTFOLIO_COUNTS',((SELECT sum(source_rows)||'|'||sum(certified_rows)||'|'||sum(no_payment_activity_rows)||'|'||sum(reconciled_after_retry_rows)||'|'||sum(review_hold_rows)||'|'||sum(exception_case_rows)||'|'||sum(unresolved_exception_rows) FROM msbf_m2.payment_reconciliation_portfolio_summary WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx)))::text,'59|59|57|1|1|1|0',
        coalesce(((SELECT sum(source_rows)=59 AND sum(certified_rows)=59 AND sum(no_payment_activity_rows)=57 AND sum(reconciled_after_retry_rows)=1 AND sum(review_hold_rows)=1 AND sum(exception_case_rows)=1 AND sum(unresolved_exception_rows)=0 FROM msbf_m2.payment_reconciliation_portfolio_summary WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx))),FALSE),'Portfolio counts reconcile.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_098_PORTFOLIO_AMOUNTS','PORTFOLIO_AMOUNTS',((SELECT round(sum(processed_payment_amount),2)||'|'||round(sum(reconciliation_variance_amount),2)||'|'||round(sum(certified_exposure_amount),2)||'|'||round(sum(exposure_variance_amount),2) FROM msbf_m2.payment_reconciliation_portfolio_summary WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx)))::text,'194.25|0.00|785.48|0.00',
        coalesce(((SELECT round(sum(processed_payment_amount),2)=194.25 AND round(sum(reconciliation_variance_amount),2)=0 AND round(sum(certified_exposure_amount),2)=785.48 AND round(sum(exposure_variance_amount),2)=0 FROM msbf_m2.payment_reconciliation_portfolio_summary WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx))),FALSE),'Portfolio amounts reconcile.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_099_PORTFOLIO_HASH','PORTFOLIO_HASH_ERRORS',((SELECT count(*) FROM msbf_m2.payment_reconciliation_portfolio_summary AS p WHERE p.module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND p.row_hash IS DISTINCT FROM msbf_ctl.m2_9_hash_jsonb(to_jsonb(p)-'row_hash'-'created_at')))::text,'0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.payment_reconciliation_portfolio_summary AS p WHERE p.module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND p.row_hash IS DISTINCT FROM msbf_ctl.m2_9_hash_jsonb(to_jsonb(p)-'row_hash'-'created_at'))),FALSE),'Portfolio hashes reconstruct.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_100_LATEST_COUNT','LATEST_ROWS',((SELECT count(*) FROM msbf_m2.application_payment_reconciliation_certification_latest WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx)))::text,'59',
        coalesce(((SELECT count(*)=59 FROM msbf_m2.application_payment_reconciliation_certification_latest WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx))),FALSE),'Latest contract has 59 rows.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_101_LATEST_GRAIN','LATEST_DUPLICATES',((SELECT count(*)-count(DISTINCT scenario_id::text||'|'||merchant_application_id) FROM msbf_m2.application_payment_reconciliation_certification_latest WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx)))::text,'0',
        coalesce(((SELECT count(*)=count(DISTINCT scenario_id::text||'|'||merchant_application_id) FROM msbf_m2.application_payment_reconciliation_certification_latest WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx))),FALSE),'Latest grain is unique.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_102_LATEST_IDENTITY','LATEST_IDENTITY_ERRORS',((SELECT count(*) FROM msbf_m2.application_payment_reconciliation_certification_latest WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND (contract_code<>'M2_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_CONSUMPTION' OR contract_version<>1 OR schema_version<>'M2_9_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_SCHEMA_V1' OR methodology_version<>'M2_9_METHOD_V1')))::text,'0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_payment_reconciliation_certification_latest WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND (contract_code<>'M2_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_CONSUMPTION' OR contract_version<>1 OR schema_version<>'M2_9_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_SCHEMA_V1' OR methodology_version<>'M2_9_METHOD_V1'))),FALSE),'Latest contract identity is exact.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_103_LATEST_LINEAGE','LATEST_LINEAGE_ERRORS',((SELECT count(*) FROM msbf_m2.application_payment_reconciliation_certification_latest AS l JOIN msbf_m2.account_payment_reconciliation_snapshot AS a ON a.module1_run_id=l.module1_run_id AND a.scenario_id=l.scenario_id AND a.merchant_application_id=l.merchant_application_id JOIN msbf_m2.account_state_certification_snapshot AS c ON c.module1_run_id=l.module1_run_id AND c.scenario_id=l.scenario_id AND c.merchant_application_id=l.merchant_application_id WHERE l.module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND (l.account_reconciliation_row_hash IS DISTINCT FROM a.row_hash OR l.state_certification_row_hash IS DISTINCT FROM c.row_hash)))::text,'0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_payment_reconciliation_certification_latest AS l JOIN msbf_m2.account_payment_reconciliation_snapshot AS a ON a.module1_run_id=l.module1_run_id AND a.scenario_id=l.scenario_id AND a.merchant_application_id=l.merchant_application_id JOIN msbf_m2.account_state_certification_snapshot AS c ON c.module1_run_id=l.module1_run_id AND c.scenario_id=l.scenario_id AND c.merchant_application_id=l.merchant_application_id WHERE l.module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND (l.account_reconciliation_row_hash IS DISTINCT FROM a.row_hash OR l.state_certification_row_hash IS DISTINCT FROM c.row_hash))),FALSE),'Latest preserves reconciliation and certification lineage.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_104_LATEST_HASH','LATEST_HASH_ERRORS',((SELECT count(*) FROM msbf_m2.application_payment_reconciliation_certification_latest AS l WHERE l.module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND l.contract_row_hash IS DISTINCT FROM msbf_ctl.m2_9_hash_jsonb(to_jsonb(l)-'contract_row_hash'-'created_at')))::text,'0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_payment_reconciliation_certification_latest AS l WHERE l.module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND l.contract_row_hash IS DISTINCT FROM msbf_ctl.m2_9_hash_jsonb(to_jsonb(l)-'contract_row_hash'-'created_at'))),FALSE),'Latest hashes reconstruct.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_105_ARCHIVE_COUNT','ARCHIVE_ROWS',((SELECT count(*) FROM msbf_m2.application_payment_reconciliation_certification_archive WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx)))::text,'59',
        coalesce(((SELECT count(*)=59 FROM msbf_m2.application_payment_reconciliation_certification_archive WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx))),FALSE),'Archive has 59 rows.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_106_LATEST_ARCHIVE','LATEST_ARCHIVE_ERRORS',((SELECT count(*) FROM msbf_m2.application_payment_reconciliation_certification_latest AS latest FULL OUTER JOIN msbf_m2.application_payment_reconciliation_certification_archive AS archive ON archive.module1_run_id=latest.module1_run_id AND archive.contract_version=latest.contract_version AND archive.scenario_id=latest.scenario_id AND archive.merchant_application_id=latest.merchant_application_id WHERE coalesce(latest.module1_run_id,archive.module1_run_id)=(SELECT run_id FROM _m2_9_vctx) AND (latest.contract_row_hash IS DISTINCT FROM archive.contract_row_hash OR archive.contract_payload IS DISTINCT FROM (to_jsonb(latest)-'created_at'))))::text,'0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.application_payment_reconciliation_certification_latest AS latest FULL OUTER JOIN msbf_m2.application_payment_reconciliation_certification_archive AS archive ON archive.module1_run_id=latest.module1_run_id AND archive.contract_version=latest.contract_version AND archive.scenario_id=latest.scenario_id AND archive.merchant_application_id=latest.merchant_application_id WHERE coalesce(latest.module1_run_id,archive.module1_run_id)=(SELECT run_id FROM _m2_9_vctx) AND (latest.contract_row_hash IS DISTINCT FROM archive.contract_row_hash OR archive.contract_payload IS DISTINCT FROM (to_jsonb(latest)-'created_at')))),FALSE),'Latest and archive reproduce exactly.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_107_ARCHIVE_HASH_TRIGGER','ARCHIVE_HASH_TRIGGER_ERRORS',((SELECT (SELECT count(*) FROM msbf_m2.application_payment_reconciliation_certification_archive AS a WHERE a.module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND a.archive_row_hash IS DISTINCT FROM msbf_ctl.m2_9_hash_jsonb(to_jsonb(a)-'archive_id'-'archive_row_hash'-'archived_at'-'created_at'))+(SELECT CASE WHEN count(*)=1 THEN 0 ELSE 1 END FROM pg_trigger WHERE tgrelid='msbf_m2.application_payment_reconciliation_certification_archive'::regclass AND tgname='trg_m2_9_archive_immutable' AND NOT tgisinternal)))::text,'0',
        coalesce(((SELECT (SELECT count(*) FROM msbf_m2.application_payment_reconciliation_certification_archive AS a WHERE a.module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND a.archive_row_hash IS DISTINCT FROM msbf_ctl.m2_9_hash_jsonb(to_jsonb(a)-'archive_id'-'archive_row_hash'-'archived_at'-'created_at'))+(SELECT CASE WHEN count(*)=1 THEN 0 ELSE 1 END FROM pg_trigger WHERE tgrelid='msbf_m2.application_payment_reconciliation_certification_archive'::regclass AND tgname='trg_m2_9_archive_immutable' AND NOT tgisinternal)=0)),FALSE),'Archive hashes and immutability trigger are valid.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_108_STRESS_NONIMPROVEMENT','STRESS_IMPROVEMENT_ROWS',((SELECT count(*) FROM msbf_m2.v_m2_9_matched_scenario_comparison WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND (stress_certification_permission_improvement_flag OR stress_certification_rank_improvement_flag OR stress_exposure_improvement_flag)))::text,'0',
        coalesce(((SELECT count(*)=0 FROM msbf_m2.v_m2_9_matched_scenario_comparison WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND (stress_certification_permission_improvement_flag OR stress_certification_rank_improvement_flag OR stress_exposure_improvement_flag))),FALSE),'Stress has no certification or exposure improvement.'
    );
    /* Controls 109–120 — deterministic sets, canonical identity, and acceptance readiness. */
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_109_POLICY_SET_HASH','POLICY_SET_HASH',((SELECT policy_set_hash FROM msbf_ctl.m2_9_reconciliation_certification_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx)))::text,'32 lowercase hexadecimal characters',
        coalesce(((SELECT length(policy_set_hash)=32 AND policy_set_hash~'^[0-9a-f]+$' FROM msbf_ctl.m2_9_reconciliation_certification_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx))),FALSE),'Policy Set Hash has valid shape.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_110_OUTCOME_SET_HASH','OUTCOME_SET_HASH',((SELECT reconciliation_outcome_set_hash FROM msbf_ctl.m2_9_reconciliation_certification_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx)))::text,'32 lowercase hexadecimal characters',
        coalesce(((SELECT length(reconciliation_outcome_set_hash)=32 AND reconciliation_outcome_set_hash~'^[0-9a-f]+$' FROM msbf_ctl.m2_9_reconciliation_certification_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx))),FALSE),'Outcome Set Hash has valid shape.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_111_ACTION_SET_HASH','ACTION_SET_HASH',((SELECT resolution_action_set_hash FROM msbf_ctl.m2_9_reconciliation_certification_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx)))::text,'32 lowercase hexadecimal characters',
        coalesce(((SELECT length(resolution_action_set_hash)=32 AND resolution_action_set_hash~'^[0-9a-f]+$' FROM msbf_ctl.m2_9_reconciliation_certification_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx))),FALSE),'Action Set Hash has valid shape.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_112_CERT_STATE_SET_HASH','CERT_STATE_SET_HASH',((SELECT certification_state_set_hash FROM msbf_ctl.m2_9_reconciliation_certification_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx)))::text,'32 lowercase hexadecimal characters',
        coalesce(((SELECT length(certification_state_set_hash)=32 AND certification_state_set_hash~'^[0-9a-f]+$' FROM msbf_ctl.m2_9_reconciliation_certification_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx))),FALSE),'Cert State Set Hash has valid shape.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_113_REASON_SET_HASH','REASON_SET_HASH',((SELECT reason_set_hash FROM msbf_ctl.m2_9_reconciliation_certification_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx)))::text,'32 lowercase hexadecimal characters',
        coalesce(((SELECT length(reason_set_hash)=32 AND reason_set_hash~'^[0-9a-f]+$' FROM msbf_ctl.m2_9_reconciliation_certification_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx))),FALSE),'Reason Set Hash has valid shape.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_114_ACCOUNT_SOURCE_SET_HASH','ACCOUNT_SOURCE_SET_HASH',((SELECT account_source_set_hash FROM msbf_ctl.m2_9_reconciliation_certification_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx)))::text,'32 lowercase hexadecimal characters',
        coalesce(((SELECT length(account_source_set_hash)=32 AND account_source_set_hash~'^[0-9a-f]+$' FROM msbf_ctl.m2_9_reconciliation_certification_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx))),FALSE),'Account Source Set Hash has valid shape.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_115_PAYMENT_SOURCE_SET_HASH','PAYMENT_SOURCE_SET_HASH',((SELECT payment_source_set_hash FROM msbf_ctl.m2_9_reconciliation_certification_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx)))::text,'32 lowercase hexadecimal characters',
        coalesce(((SELECT length(payment_source_set_hash)=32 AND payment_source_set_hash~'^[0-9a-f]+$' FROM msbf_ctl.m2_9_reconciliation_certification_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx))),FALSE),'Payment Source Set Hash has valid shape.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_116_TRANSITION_SOURCE_SET_HASH','TRANSITION_SOURCE_SET_HASH',((SELECT transition_source_set_hash FROM msbf_ctl.m2_9_reconciliation_certification_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx)))::text,'32 lowercase hexadecimal characters',
        coalesce(((SELECT length(transition_source_set_hash)=32 AND transition_source_set_hash~'^[0-9a-f]+$' FROM msbf_ctl.m2_9_reconciliation_certification_contract_registry WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx))),FALSE),'Transition Source Set Hash has valid shape.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_117_REGISTRY_HASH','REGISTRY_HASH_ERRORS',((SELECT count(*) FROM msbf_ctl.m2_9_reconciliation_certification_contract_registry AS r WHERE r.module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND r.row_hash IS DISTINCT FROM msbf_ctl.m2_9_registry_row_hash(to_jsonb(r))))::text,'0',
        coalesce(((SELECT count(*)=0 FROM msbf_ctl.m2_9_reconciliation_certification_contract_registry AS r WHERE r.module1_run_id=(SELECT run_id FROM _m2_9_vctx) AND r.row_hash IS DISTINCT FROM msbf_ctl.m2_9_registry_row_hash(to_jsonb(r)))),FALSE),'Registry hash reconstructs.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_118_CANONICAL_IDENTITY','CANONICAL_IDENTITY',((SELECT canonical_entities||'|'||combined_set_hash FROM msbf_m2.v_m2_9_canonical_hash WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx)))::text,'438|registry combined hash',
        coalesce(((SELECT c.canonical_entities=438 AND c.combined_set_hash IS NOT DISTINCT FROM r.combined_set_hash FROM msbf_m2.v_m2_9_canonical_hash AS c JOIN msbf_ctl.m2_9_reconciliation_certification_contract_registry AS r ON r.module1_run_id=c.module1_run_id WHERE c.module1_run_id=(SELECT run_id FROM _m2_9_vctx))),FALSE),'Canonical identity reconciles.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_119_GENERATION_EVIDENCE','GENERATION_EVIDENCE_ROWS',((SELECT count(*) FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM _m2_9_vctx) AND evidence_code LIKE 'M2_9_%' AND evidence_code NOT LIKE 'M2_9_POS_%' AND evidence_code NOT LIKE 'M2_9_NEG_%' AND evidence_code<>'M2_9_ACCEPTANCE_SUMMARY'))::text,'24',
        coalesce(((SELECT count(*)=24 FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM _m2_9_vctx) AND evidence_code LIKE 'M2_9_%' AND evidence_code NOT LIKE 'M2_9_POS_%' AND evidence_code NOT LIKE 'M2_9_NEG_%' AND evidence_code<>'M2_9_ACCEPTANCE_SUMMARY')),FALSE),'Twenty-four generation evidence rows are present.'
    );
    PERFORM pg_temp.m2_9_add_check(
        'M2_9_POS_120_ACCEPTANCE_NOT_WRITTEN','ACCEPTANCE_ROWS',((SELECT count(*) FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM _m2_9_vctx) AND gate_id='M2_9_PAYMENT_RECONCILIATION_EXCEPTION_RESOLUTION_ACCOUNT_STATE_CERTIFICATION'))::text,'0',
        coalesce(((SELECT count(*)=0 FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM _m2_9_vctx) AND gate_id='M2_9_PAYMENT_RECONCILIATION_EXCEPTION_RESOLUTION_ACCOUNT_STATE_CERTIFICATION')),FALSE),'Acceptance is not written before controls pass.'
    );
END;$controls$;
/* ============================================================================
Section 2 — Persist evidence and transition validated lifecycle
============================================================================ */
DO $finalize$ DECLARE vt bigint;vp bigint;vf bigint;
BEGIN SELECT count(*),count(*) FILTER(WHERE status='PASS'),count(*) FILTER(WHERE status='FAIL') INTO vt,vp,vf FROM _m2_9_validation;
IF vt<>120 THEN RAISE EXCEPTION 'M2.9 positive-control inventory failed: total %, expected 120.',vt; END IF;
INSERT INTO msbf_ctl.run_evidence(run_id,evidence_code,segment_key,metric_name,metric_value_numeric,metric_value_text,unit_code,status,interpretation)
SELECT (SELECT run_id FROM _m2_9_vctx),evidence_code,'PORTFOLIO',metric_name,NULL::numeric(28,10),coalesce(observed_value,'<NULL>'),'VALIDATION',status,interpretation||' Threshold: '||coalesce(threshold_value,'<NULL>')
FROM _m2_9_validation ON CONFLICT(run_id,evidence_code,segment_key) DO UPDATE SET metric_name=EXCLUDED.metric_name,metric_value_numeric=NULL,
metric_value_text=EXCLUDED.metric_value_text,unit_code=EXCLUDED.unit_code,status=EXCLUDED.status,interpretation=EXCLUDED.interpretation,created_at=clock_timestamp();
IF vp=120 AND vf=0 THEN UPDATE msbf_ctl.run_registry SET run_status='M2_9_VALIDATED' WHERE run_id=(SELECT run_id FROM _m2_9_vctx);
UPDATE msbf_ctl.m2_9_reconciliation_certification_contract_registry SET contract_status='VALIDATED',validated_at=clock_timestamp()
WHERE module1_run_id=(SELECT run_id FROM _m2_9_vctx); ELSE RAISE EXCEPTION 'M2.9 positive validation failed: pass %, fail %.',vp,vf; END IF;
END;$finalize$;
COMMIT;
SELECT evidence_code,metric_name,observed_value,threshold_value,status,interpretation FROM _m2_9_validation ORDER BY evidence_code;
