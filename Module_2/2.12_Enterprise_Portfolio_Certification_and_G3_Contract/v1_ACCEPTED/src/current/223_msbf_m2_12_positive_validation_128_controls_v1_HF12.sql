/*
Program 223 — M2.12 Positive Validation (128 controls)
Source revision: HF12 bounded live-execution correction after the prior 128-control rollback
Execution status: HOTFIX SOURCE CONSTRUCTED — NOT EXECUTED HERE

Bounded correction authority:
- Corrects Control 009 to compare the G3 archive payload with the exact Program 222 HF9
  archive builder preimage: to_jsonb(latest)-created_at, retaining the latest row_hash.
- Corrects Control 114 to preserve the accepted M2.11 strategy-evidence posture of
  exactly 24 PARTIAL rows, zero guard violations, and 24 stress non-improvement passes.
- Adds exact failed-control diagnostics to the 128/128 release gate.
- Preserves all 128 control identities, sequences, and family allocation.
- Retains the prior persisted-state reconstruction, exact source graph, physical stage
  boundary, deterministic hash, lifecycle, mutation, and sequence controls.
- Persists positive evidence and transitions lifecycle only after 128/128 PASS.
- Performs no canonical business/hash mutation and advances no owned sequence.

Operator boundary:
- Execute only after both HF12 read-only pre-execution verifiers pass exactly.
- Execute one complete physical file with first-error stop and no outer transaction.
- Stop after Program 223; Program 224 remains held pending evidence reconciliation.
*/
-- Configure first-error-stop behavior in the database client; this file contains no client meta-commands.
BEGIN;

SET LOCAL search_path = pg_catalog, msbf_ctl, msbf_m1, msbf_m2;

SET LOCAL lock_timeout = '5s';

SET LOCAL statement_timeout = '0';

SET LOCAL idle_in_transaction_session_timeout = '0';


/* Program-223-owned governed run context. */
CREATE TEMP TABLE tmp_src_m2_12_validation_run_context ON COMMIT DROP AS
SELECT rr.run_id::bigint AS module1_run_id,
       rr.run_code::text AS run_code,
       rr.run_version::integer AS run_version,
       rr.run_status::text AS run_status
FROM msbf_ctl.run_registry rr
JOIN msbf_ctl.m2_12_policy_profile p ON p.module1_run_id=rr.run_id
WHERE rr.run_code='M1_V0_2_BASELINE_BUILD'
  AND rr.run_version=1
  AND rr.run_status='M2_12_GENERATED'
  AND p.policy_code='M2_12_ENTERPRISE_PORTFOLIO_CERTIFICATION_POLICY_V1'
  AND p.policy_version=1
  AND p.policy_status='APPROVED';

CREATE UNIQUE INDEX ux_tmp_src_m2_12_validation_run_context ON tmp_src_m2_12_validation_run_context(module1_run_id);

ANALYZE tmp_src_m2_12_validation_run_context;


/* Fail-closed generated-checkpoint precondition. */
DO $m212_p223_hf12_precondition$
DECLARE
    v_context_rows integer;
    v_policy_rows integer;
    v_stage_rows integer;
    v_component_rows integer;
    v_evidence_snapshot_rows integer;
    v_reproduction_rows integer;
    v_capability_rows integer;
    v_latest_rows integer;
    v_archive_rows integer;
    v_registry_rows integer;
    v_generation_rows integer;
    v_generation_pass_rows integer;
    v_generation_codes integer;
    v_m212_rows integer;
    v_prior_positive integer;
    v_prior_negative integer;
    v_prior_acceptance integer;
    v_gate_rows integer;
BEGIN
    SELECT count(*) INTO v_context_rows FROM tmp_src_m2_12_validation_run_context;
    IF v_context_rows<>1 THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 223 HF12 requires exactly one M2_12_GENERATED governed run',
            DETAIL='observed='||v_context_rows::text;
    END IF;

    SELECT count(*) INTO v_policy_rows
      FROM msbf_ctl.m2_12_policy_profile p
      JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=p.module1_run_id
     WHERE p.policy_code='M2_12_ENTERPRISE_PORTFOLIO_CERTIFICATION_POLICY_V1'
       AND p.policy_version=1
       AND p.policy_status='APPROVED';

    SELECT count(*) INTO v_stage_rows
      FROM msbf_m2.module2_stage_certification_snapshot t
      JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id;
    SELECT count(*) INTO v_component_rows
      FROM msbf_m2.module2_contract_component_snapshot t
      JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id;
    SELECT count(*) INTO v_evidence_snapshot_rows
      FROM msbf_m2.module2_evidence_certification_snapshot t
      JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id;
    SELECT count(*) INTO v_reproduction_rows
      FROM msbf_m2.module2_contract_reproduction_snapshot t
      JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id;
    SELECT count(*) INTO v_capability_rows
      FROM msbf_m2.module2_capability_coverage_snapshot t
      JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id;
    SELECT count(*) INTO v_latest_rows
      FROM msbf_ctl.m2_12_g3_bundle_latest t
      JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id
     WHERE t.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND t.contract_version=1;
    SELECT count(*) INTO v_archive_rows
      FROM msbf_ctl.m2_12_g3_bundle_archive t
      JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id
     WHERE t.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND t.contract_version=1;
    SELECT count(*) INTO v_registry_rows
      FROM msbf_ctl.m2_12_g3_bundle_registry t
      JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id
     WHERE t.bundle_code='M2_G3_CONSUMPTION_BUNDLE'
       AND t.contract_version=1
       AND t.contract_status='GENERATED'
       AND t.generated_at IS NOT NULL
       AND t.validated_at IS NULL
       AND t.accepted_at IS NULL;

    IF ROW(v_policy_rows,v_stage_rows,v_component_rows,v_evidence_snapshot_rows,
           v_reproduction_rows,v_capability_rows,v_latest_rows,v_archive_rows,v_registry_rows)
       IS DISTINCT FROM ROW(1,12,13,72,13,20,1,1,1) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 223 HF12 generated canonical family checkpoint mismatch',
            DETAIL=format('policy=%s stage=%s component=%s evidence=%s reproduction=%s capability=%s latest=%s archive=%s registry=%s',
                          v_policy_rows,v_stage_rows,v_component_rows,v_evidence_snapshot_rows,
                          v_reproduction_rows,v_capability_rows,v_latest_rows,v_archive_rows,v_registry_rows);
    END IF;

    SELECT count(*),
           count(*) FILTER (WHERE e.status='PASS'),
           count(DISTINCT e.evidence_code)
      INTO v_generation_rows,v_generation_pass_rows,v_generation_codes
      FROM msbf_ctl.run_evidence e
      JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=e.run_id
     WHERE e.evidence_code=ANY(ARRAY[
       'M2_12_POLICY_SET_HASH','M2_12_STAGE_CERTIFICATION_SET_HASH','M2_12_CONTRACT_COMPONENT_SET_HASH',
       'M2_12_EVIDENCE_CERTIFICATION_SET_HASH','M2_12_CONTRACT_REPRODUCTION_SET_HASH','M2_12_CAPABILITY_COVERAGE_SET_HASH',
       'M2_12_LATEST_SET_HASH','M2_12_ARCHIVE_SET_HASH','M2_12_REGISTRY_SET_HASH','M2_12_CONTRACT_SET_HASH',
       'M2_12_COMBINED_SET_HASH','M2_12_STAGE_CERTIFICATION_ROWS','M2_12_CONTRACT_COMPONENT_ROWS',
       'M2_12_EVIDENCE_CERTIFICATION_ROWS','M2_12_CONTRACT_REPRODUCTION_ROWS','M2_12_CAPABILITY_COVERAGE_ROWS',
       'M2_12_CANONICAL_ENTITIES','M2_12_COMPONENT_LATEST_ARCHIVE_ROWS_TOTAL','M2_12_APPLICATION_CONSUMPTION_ROWS',
       'M2_12_OPERATIONAL_ACCOUNT_CONSUMPTION_ROWS','M2_12_STRATEGY_SCOPE_CONSUMPTION_ROWS','M2_12_SOURCE_GRAPH_EDGES',
       'M2_12_DETERMINISTIC_MISMATCHES','M2_12_BLOCKING_STAGE_BOUNDARY_FINDINGS']::text[]);

    SELECT count(*) INTO v_m212_rows
      FROM msbf_ctl.run_evidence e
      JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=e.run_id
     WHERE e.evidence_code LIKE 'M2_12_%';
    SELECT count(*) INTO v_prior_positive
      FROM msbf_ctl.run_evidence e JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=e.run_id
     WHERE e.evidence_code LIKE 'M2_12_POS_%';
    SELECT count(*) INTO v_prior_negative
      FROM msbf_ctl.run_evidence e JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=e.run_id
     WHERE e.evidence_code LIKE 'M2_12_NEG_%';
    SELECT count(*) INTO v_prior_acceptance
      FROM msbf_ctl.run_evidence e JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=e.run_id
     WHERE e.evidence_code='M2_12_ACCEPTANCE_SUMMARY';
    SELECT count(*) INTO v_gate_rows
      FROM msbf_ctl.acceptance_gate_result g JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=g.run_id
     WHERE g.gate_id='G3_M2_CONTRACT';

    IF v_generation_rows<>24 OR v_generation_pass_rows<>24 OR v_generation_codes<>24
       OR v_m212_rows<>24 OR v_prior_positive<>0 OR v_prior_negative<>0
       OR v_prior_acceptance<>0 OR v_gate_rows<>0 THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 223 HF12 requires exact pristine WP3 evidence and acceptance state',
            DETAIL=format('generation_rows=%s generation_pass=%s generation_codes=%s m212_rows=%s positive=%s negative=%s acceptance=%s gate=%s',
                          v_generation_rows,v_generation_pass_rows,v_generation_codes,v_m212_rows,
                          v_prior_positive,v_prior_negative,v_prior_acceptance,v_gate_rows);
    END IF;

    IF NOT ((SELECT last_value=1 AND is_called FROM msbf_ctl.m2_12_policy_profile_policy_profile_id_seq)
        AND (SELECT last_value=1 AND is_called FROM msbf_ctl.m2_12_g3_bundle_archive_archive_id_seq)
        AND (SELECT last_value=1 AND is_called FROM msbf_ctl.m2_12_g3_bundle_registry_registry_id_seq)) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 223 HF12 owned sequence checkpoint mismatch';
    END IF;
END;
$m212_p223_hf12_precondition$;


/* Frozen expected-value authorities owned by Program 223. */
CREATE TEMP TABLE tmp_src_m2_12_evidence_authority
(
 matrix_sequence smallint NOT NULL,node_sequence smallint NOT NULL,stage_code text NOT NULL,
 evidence_family_sequence smallint NOT NULL,evidence_family_code text NOT NULL,
 applicability_code text NOT NULL,allowed_certification_status text NOT NULL,
 authoritative_source_locator text NOT NULL,evidence_code_or_method_pattern text NOT NULL,
 expected_count_or_identity text NOT NULL,expected_status text NOT NULL,expected_hash text NOT NULL,
 PRIMARY KEY(matrix_sequence), UNIQUE(node_sequence,evidence_family_sequence,evidence_family_code)
) ON COMMIT DROP;

INSERT INTO tmp_src_m2_12_evidence_authority VALUES
('1','1','M1_17_G2_FOUNDATION','1','ACCEPTANCE_LIFECYCLE','MANDATORY','PASS','msbf_ctl.m1_17_g2_bundle_registry|msbf_ctl.acceptance_gate_result|msbf_ctl.run_evidence','M1_17_ACCEPTANCE_SUMMARY','1 registry accepted | 1 gate PASS | 1 acceptance summary','PASS','7d9e466da28cad2551aa99c4c40c912b'),
('2','1','M1_17_G2_FOUNDATION','2','POSITIVE_VALIDATION','MANDATORY','PASS','msbf_ctl.run_evidence','M1_17_POS_%','128','PASS',''),
('3','1','M1_17_G2_FOUNDATION','3','NEGATIVE_CONTROLS','MANDATORY','PASS','msbf_ctl.run_evidence','M1_17_NEG_%','20','PASS',''),
('4','1','M1_17_G2_FOUNDATION','4','CANONICAL_IDENTITY','MANDATORY','PASS','msbf_ctl.m1_17_g2_bundle_registry','PHYSICAL_CANONICAL_RECONSTRUCTION','69','PASS','7d9e466da28cad2551aa99c4c40c912b'),
('5','1','M1_17_G2_FOUNDATION','5','LATEST_ARCHIVE_REPRODUCTION','MANDATORY','PASS','msbf_ctl.m1_17_g2_bundle_latest|msbf_ctl.m1_17_g2_bundle_archive','EXACT_PAYLOAD_AND_CONTRACT_HASH_REPRODUCTION','1 latest | 1 archive | 0 mismatches','PASS',''),
('6','1','M1_17_G2_FOUNDATION','6','STAGE_BOUNDARY','MANDATORY','PASS','msbf_ctl.m1_17_g2_bundle_registry|msbf_ctl.run_evidence|accepted detail-report boundary output','M1_17_%BOUNDARY%|M1_17_%BLOCKING%','0 blocking or stage-boundary findings','PASS',''),
('7','2','M2_1_ELIGIBILITY_ROUTING','1','ACCEPTANCE_LIFECYCLE','MANDATORY','PASS','msbf_ctl.m2_1_strategy_contract_registry|msbf_ctl.acceptance_gate_result|msbf_ctl.run_evidence','M2_1_ACCEPTANCE_SUMMARY','1 registry accepted | 1 gate PASS | 1 acceptance summary','PASS','e5ace7f32060ffb191c7bd0f8dd0c863'),
('8','2','M2_1_ELIGIBILITY_ROUTING','2','POSITIVE_VALIDATION','MANDATORY','PASS','msbf_ctl.run_evidence','M2_1_POS_%','112','PASS',''),
('9','2','M2_1_ELIGIBILITY_ROUTING','3','NEGATIVE_CONTROLS','MANDATORY','PASS','msbf_ctl.run_evidence','M2_1_NEG_%','20','PASS',''),
('10','2','M2_1_ELIGIBILITY_ROUTING','4','CANONICAL_IDENTITY','MANDATORY','PASS','msbf_ctl.m2_1_strategy_contract_registry','PHYSICAL_CANONICAL_RECONSTRUCTION','22541','PASS','e5ace7f32060ffb191c7bd0f8dd0c863'),
('11','2','M2_1_ELIGIBILITY_ROUTING','5','LATEST_ARCHIVE_REPRODUCTION','MANDATORY','PASS','msbf_m2.application_eligibility_routing_latest|msbf_m2.application_eligibility_routing_archive','EXACT_PAYLOAD_AND_CONTRACT_HASH_REPRODUCTION','1500 latest | 1500 archive | 0 mismatches','PASS',''),
('12','2','M2_1_ELIGIBILITY_ROUTING','6','STAGE_BOUNDARY','MANDATORY','PASS','msbf_ctl.m2_1_strategy_contract_registry|msbf_ctl.run_evidence|accepted detail-report boundary output','M2_1_%BOUNDARY%|M2_1_%BLOCKING%','0 blocking or stage-boundary findings','PASS',''),
('13','3','M2_2_PRICING_STRUCTURE','1','ACCEPTANCE_LIFECYCLE','MANDATORY','PASS','msbf_ctl.m2_2_pricing_structure_contract_registry|msbf_ctl.acceptance_gate_result|msbf_ctl.run_evidence','M2_2_ACCEPTANCE_SUMMARY','1 registry accepted | 1 gate PASS | 1 acceptance summary','PASS','bbe83b187b31ea561789797322031fc6'),
('14','3','M2_2_PRICING_STRUCTURE','2','POSITIVE_VALIDATION','MANDATORY','PASS','msbf_ctl.run_evidence','M2_2_POS_%','120','PASS',''),
('15','3','M2_2_PRICING_STRUCTURE','3','NEGATIVE_CONTROLS','MANDATORY','PASS','msbf_ctl.run_evidence','M2_2_NEG_%','20','PASS',''),
('16','3','M2_2_PRICING_STRUCTURE','4','CANONICAL_IDENTITY','MANDATORY','PASS','msbf_ctl.m2_2_pricing_structure_contract_registry','PHYSICAL_CANONICAL_RECONSTRUCTION','7336','PASS','bbe83b187b31ea561789797322031fc6'),
('17','3','M2_2_PRICING_STRUCTURE','5','LATEST_ARCHIVE_REPRODUCTION','MANDATORY','PASS','msbf_m2.application_request_structure_latest|msbf_m2.application_pricing_structure_latest|msbf_m2.application_request_structure_archive|msbf_m2.application_pricing_structure_archive','EXACT_PAYLOAD_AND_CONTRACT_HASH_REPRODUCTION','2250 latest | 2250 archive | 0 mismatches','PASS',''),
('18','3','M2_2_PRICING_STRUCTURE','6','STAGE_BOUNDARY','MANDATORY','PASS','msbf_ctl.m2_2_pricing_structure_contract_registry|msbf_ctl.run_evidence|accepted detail-report boundary output','M2_2_%BOUNDARY%|M2_2_%BLOCKING%','0 blocking or stage-boundary findings','PASS',''),
('19','4','M2_3_FINAL_DECISION','1','ACCEPTANCE_LIFECYCLE','MANDATORY','PASS','msbf_ctl.m2_3_final_decision_contract_registry|msbf_ctl.acceptance_gate_result|msbf_ctl.run_evidence','M2_3_ACCEPTANCE_SUMMARY','1 registry accepted | 1 gate PASS | 1 acceptance summary','PASS','bf09349b06ede7e5a2ec830c2f9ffe90'),
('20','4','M2_3_FINAL_DECISION','2','POSITIVE_VALIDATION','MANDATORY','PASS','msbf_ctl.run_evidence','M2_3_POS_%','120','PASS',''),
('21','4','M2_3_FINAL_DECISION','3','NEGATIVE_CONTROLS','MANDATORY','PASS','msbf_ctl.run_evidence','M2_3_NEG_%','20','PASS',''),
('22','4','M2_3_FINAL_DECISION','4','CANONICAL_IDENTITY','MANDATORY','PASS','msbf_ctl.m2_3_final_decision_contract_registry','PHYSICAL_CANONICAL_RECONSTRUCTION','6029','PASS','bf09349b06ede7e5a2ec830c2f9ffe90'),
('23','4','M2_3_FINAL_DECISION','5','LATEST_ARCHIVE_REPRODUCTION','MANDATORY','PASS','msbf_m2.application_final_offer_decision_latest|msbf_m2.application_final_offer_decision_archive','EXACT_PAYLOAD_AND_CONTRACT_HASH_REPRODUCTION','1500 latest | 1500 archive | 0 mismatches','PASS',''),
('24','4','M2_3_FINAL_DECISION','6','STAGE_BOUNDARY','MANDATORY','PASS','msbf_ctl.m2_3_final_decision_contract_registry|msbf_ctl.run_evidence|accepted detail-report boundary output','M2_3_%BOUNDARY%|M2_3_%BLOCKING%','0 blocking or stage-boundary findings','PASS',''),
('25','5','M2_4_PORTFOLIO_ACTIVATION','1','ACCEPTANCE_LIFECYCLE','MANDATORY','PASS','msbf_ctl.m2_4_portfolio_activation_contract_registry|msbf_ctl.acceptance_gate_result|msbf_ctl.run_evidence','M2_4_ACCEPTANCE_SUMMARY','1 registry accepted | 1 gate PASS | 1 acceptance summary','PASS','117450a3eea7bb3d3c74d18cc3c8e96a'),
('26','5','M2_4_PORTFOLIO_ACTIVATION','2','POSITIVE_VALIDATION','MANDATORY','PASS','msbf_ctl.run_evidence','M2_4_POS_%','120','PASS',''),
('27','5','M2_4_PORTFOLIO_ACTIVATION','3','NEGATIVE_CONTROLS','MANDATORY','PASS','msbf_ctl.run_evidence','M2_4_NEG_%','20','PASS',''),
('28','5','M2_4_PORTFOLIO_ACTIVATION','4','CANONICAL_IDENTITY','MANDATORY','PASS','msbf_ctl.m2_4_portfolio_activation_contract_registry','PHYSICAL_CANONICAL_RECONSTRUCTION','6212','PASS','117450a3eea7bb3d3c74d18cc3c8e96a'),
('29','5','M2_4_PORTFOLIO_ACTIVATION','5','LATEST_ARCHIVE_REPRODUCTION','MANDATORY','PASS','msbf_m2.application_booking_funding_activation_latest|msbf_m2.application_booking_funding_activation_archive','EXACT_PAYLOAD_AND_CONTRACT_HASH_REPRODUCTION','1500 latest | 1500 archive | 0 mismatches','PASS',''),
('30','5','M2_4_PORTFOLIO_ACTIVATION','6','STAGE_BOUNDARY','MANDATORY','PASS','msbf_ctl.m2_4_portfolio_activation_contract_registry|msbf_ctl.run_evidence|accepted detail-report boundary output','M2_4_%BOUNDARY%|M2_4_%BLOCKING%','0 blocking or stage-boundary findings','PASS',''),
('31','6','M2_5_DAILY_MONITORING','1','ACCEPTANCE_LIFECYCLE','MANDATORY','PASS','msbf_ctl.m2_5_portfolio_monitoring_contract_registry|msbf_ctl.acceptance_gate_result|msbf_ctl.run_evidence','M2_5_ACCEPTANCE_SUMMARY','1 registry accepted | 1 gate PASS | 1 acceptance summary','PASS','18e1c444aa1b02ee5bd3539d7c477adc'),
('32','6','M2_5_DAILY_MONITORING','2','POSITIVE_VALIDATION','MANDATORY','PASS','msbf_ctl.run_evidence','M2_5_POS_%','120','PASS',''),
('33','6','M2_5_DAILY_MONITORING','3','NEGATIVE_CONTROLS','MANDATORY','PASS','msbf_ctl.run_evidence','M2_5_NEG_%','20','PASS',''),
('34','6','M2_5_DAILY_MONITORING','4','CANONICAL_IDENTITY','MANDATORY','PASS','msbf_ctl.m2_5_portfolio_monitoring_contract_registry','PHYSICAL_CANONICAL_RECONSTRUCTION','7536','PASS','18e1c444aa1b02ee5bd3539d7c477adc'),
('35','6','M2_5_DAILY_MONITORING','5','LATEST_ARCHIVE_REPRODUCTION','MANDATORY','PASS','msbf_m2.advance_portfolio_monitoring_latest|msbf_m2.advance_portfolio_monitoring_archive','EXACT_PAYLOAD_AND_CONTRACT_HASH_REPRODUCTION','59 latest | 59 archive | 0 mismatches','PASS',''),
('36','6','M2_5_DAILY_MONITORING','6','STAGE_BOUNDARY','MANDATORY','PASS','msbf_ctl.m2_5_portfolio_monitoring_contract_registry|msbf_ctl.run_evidence|accepted detail-report boundary output','M2_5_%BOUNDARY%|M2_5_%BLOCKING%','0 blocking or stage-boundary findings','PASS',''),
('37','7','M2_6_INTERVENTION_STRATEGY','1','ACCEPTANCE_LIFECYCLE','MANDATORY','PASS','msbf_ctl.m2_6_intervention_strategy_contract_registry|msbf_ctl.acceptance_gate_result|msbf_ctl.run_evidence','M2_6_ACCEPTANCE_SUMMARY','1 registry accepted | 1 gate PASS | 1 acceptance summary','PASS','868125bff29270490cab4d2e55cb1388'),
('38','7','M2_6_INTERVENTION_STRATEGY','2','POSITIVE_VALIDATION','MANDATORY','PASS','msbf_ctl.run_evidence','M2_6_POS_%','120','PASS',''),
('39','7','M2_6_INTERVENTION_STRATEGY','3','NEGATIVE_CONTROLS','MANDATORY','PASS','msbf_ctl.run_evidence','M2_6_NEG_%','20','PASS',''),
('40','7','M2_6_INTERVENTION_STRATEGY','4','CANONICAL_IDENTITY','MANDATORY','PASS','msbf_ctl.m2_6_intervention_strategy_contract_registry','PHYSICAL_CANONICAL_RECONSTRUCTION','284','PASS','868125bff29270490cab4d2e55cb1388'),
('41','7','M2_6_INTERVENTION_STRATEGY','5','LATEST_ARCHIVE_REPRODUCTION','MANDATORY','PASS','msbf_m2.advance_intervention_strategy_latest|msbf_m2.advance_intervention_strategy_archive','EXACT_PAYLOAD_AND_CONTRACT_HASH_REPRODUCTION','59 latest | 59 archive | 0 mismatches','PASS',''),
('42','7','M2_6_INTERVENTION_STRATEGY','6','STAGE_BOUNDARY','MANDATORY','PASS','msbf_ctl.m2_6_intervention_strategy_contract_registry|msbf_ctl.run_evidence|accepted detail-report boundary output','M2_6_%BOUNDARY%|M2_6_%BLOCKING%','0 blocking or stage-boundary findings','PASS',''),
('43','8','M2_7_OPERATIONAL_ACTIVATION','1','ACCEPTANCE_LIFECYCLE','MANDATORY','PASS','msbf_ctl.m2_7_operational_activation_contract_registry|msbf_ctl.acceptance_gate_result|msbf_ctl.run_evidence','M2_7_ACCEPTANCE_SUMMARY','1 registry accepted | 1 gate PASS | 1 acceptance summary','PASS','c8e3a472afd2a16b1183677324e9db98'),
('44','8','M2_7_OPERATIONAL_ACTIVATION','2','POSITIVE_VALIDATION','MANDATORY','PASS','msbf_ctl.run_evidence','M2_7_POS_%','120','PASS',''),
('45','8','M2_7_OPERATIONAL_ACTIVATION','3','NEGATIVE_CONTROLS','MANDATORY','PASS','msbf_ctl.run_evidence','M2_7_NEG_%','20','PASS',''),
('46','8','M2_7_OPERATIONAL_ACTIVATION','4','CANONICAL_IDENTITY','MANDATORY','PASS','msbf_ctl.m2_7_operational_activation_contract_registry','PHYSICAL_CANONICAL_RECONSTRUCTION','341','PASS','c8e3a472afd2a16b1183677324e9db98'),
('47','8','M2_7_OPERATIONAL_ACTIVATION','5','LATEST_ARCHIVE_REPRODUCTION','MANDATORY','PASS','msbf_m2.application_operational_activation_latest|msbf_m2.application_operational_activation_archive','EXACT_PAYLOAD_AND_CONTRACT_HASH_REPRODUCTION','59 latest | 59 archive | 0 mismatches','PASS',''),
('48','8','M2_7_OPERATIONAL_ACTIVATION','6','STAGE_BOUNDARY','MANDATORY','PASS','msbf_ctl.m2_7_operational_activation_contract_registry|msbf_ctl.run_evidence|accepted detail-report boundary output','M2_7_%BOUNDARY%|M2_7_%BLOCKING%','0 blocking or stage-boundary findings','PASS',''),
('49','9','M2_8_SERVICING_EXECUTION','1','ACCEPTANCE_LIFECYCLE','MANDATORY','PASS','msbf_ctl.m2_8_servicing_execution_contract_registry|msbf_ctl.acceptance_gate_result|msbf_ctl.run_evidence','M2_8_ACCEPTANCE_SUMMARY','1 registry accepted | 1 gate PASS | 1 acceptance summary','PASS','ab32d80ba20c2c8f0a6ec9ec97c2ed26'),
('50','9','M2_8_SERVICING_EXECUTION','2','POSITIVE_VALIDATION','MANDATORY','PASS','msbf_ctl.run_evidence','M2_8_POS_%','120','PASS',''),
('51','9','M2_8_SERVICING_EXECUTION','3','NEGATIVE_CONTROLS','MANDATORY','PASS','msbf_ctl.run_evidence','M2_8_NEG_%','20','PASS',''),
('52','9','M2_8_SERVICING_EXECUTION','4','CANONICAL_IDENTITY','MANDATORY','PASS','msbf_ctl.m2_8_servicing_execution_contract_registry','PHYSICAL_CANONICAL_RECONSTRUCTION','367','PASS','ab32d80ba20c2c8f0a6ec9ec97c2ed26'),
('53','9','M2_8_SERVICING_EXECUTION','5','LATEST_ARCHIVE_REPRODUCTION','MANDATORY','PASS','msbf_m2.application_servicing_execution_latest|msbf_m2.application_servicing_execution_archive','EXACT_PAYLOAD_AND_CONTRACT_HASH_REPRODUCTION','59 latest | 59 archive | 0 mismatches','PASS',''),
('54','9','M2_8_SERVICING_EXECUTION','6','STAGE_BOUNDARY','MANDATORY','PASS','msbf_ctl.m2_8_servicing_execution_contract_registry|msbf_ctl.run_evidence|accepted detail-report boundary output','M2_8_%BOUNDARY%|M2_8_%BLOCKING%','0 blocking or stage-boundary findings','PASS',''),
('55','10','M2_9_RECONCILIATION_CERTIFICATION','1','ACCEPTANCE_LIFECYCLE','MANDATORY','PASS','msbf_ctl.m2_9_reconciliation_certification_contract_registry|msbf_ctl.acceptance_gate_result|msbf_ctl.run_evidence','M2_9_ACCEPTANCE_SUMMARY','1 registry accepted | 1 gate PASS | 1 acceptance summary','PASS','6af76d0059b47623619ebc09330b15fe'),
('56','10','M2_9_RECONCILIATION_CERTIFICATION','2','POSITIVE_VALIDATION','MANDATORY','PASS','msbf_ctl.run_evidence','M2_9_POS_%','120','PASS',''),
('57','10','M2_9_RECONCILIATION_CERTIFICATION','3','NEGATIVE_CONTROLS','MANDATORY','PASS','msbf_ctl.run_evidence','M2_9_NEG_%','20','PASS',''),
('58','10','M2_9_RECONCILIATION_CERTIFICATION','4','CANONICAL_IDENTITY','MANDATORY','PASS','msbf_ctl.m2_9_reconciliation_certification_contract_registry','PHYSICAL_CANONICAL_RECONSTRUCTION','438','PASS','6af76d0059b47623619ebc09330b15fe'),
('59','10','M2_9_RECONCILIATION_CERTIFICATION','5','LATEST_ARCHIVE_REPRODUCTION','MANDATORY','PASS','msbf_m2.application_payment_reconciliation_certification_latest|msbf_m2.application_payment_reconciliation_certification_archive','EXACT_PAYLOAD_AND_CONTRACT_HASH_REPRODUCTION','59 latest | 59 archive | 0 mismatches','PASS',''),
('60','10','M2_9_RECONCILIATION_CERTIFICATION','6','STAGE_BOUNDARY','MANDATORY','PASS','msbf_ctl.m2_9_reconciliation_certification_contract_registry|msbf_ctl.run_evidence|accepted detail-report boundary output','M2_9_%BOUNDARY%|M2_9_%BLOCKING%','0 blocking or stage-boundary findings','PASS',''),
('61','11','M2_10_PORTFOLIO_ANALYTICS','1','ACCEPTANCE_LIFECYCLE','MANDATORY','PASS','msbf_ctl.m2_10_portfolio_analytics_contract_registry|msbf_ctl.acceptance_gate_result|msbf_ctl.run_evidence','M2_10_ACCEPTANCE_SUMMARY','1 registry accepted | 1 gate PASS | 1 acceptance summary','PASS','24fca7263a04397ebf21d30639f9069b'),
('62','11','M2_10_PORTFOLIO_ANALYTICS','2','POSITIVE_VALIDATION','MANDATORY','PASS','msbf_ctl.run_evidence','M2_10_POS_%','120','PASS',''),
('63','11','M2_10_PORTFOLIO_ANALYTICS','3','NEGATIVE_CONTROLS','MANDATORY','PASS','msbf_ctl.run_evidence','M2_10_NEG_%','20','PASS',''),
('64','11','M2_10_PORTFOLIO_ANALYTICS','4','CANONICAL_IDENTITY','MANDATORY','PASS','msbf_ctl.m2_10_portfolio_analytics_contract_registry','PHYSICAL_CANONICAL_RECONSTRUCTION','370','PASS','24fca7263a04397ebf21d30639f9069b'),
('65','11','M2_10_PORTFOLIO_ANALYTICS','5','LATEST_ARCHIVE_REPRODUCTION','MANDATORY','PASS','msbf_m2.application_portfolio_performance_latest|msbf_m2.application_portfolio_performance_archive','EXACT_PAYLOAD_AND_CONTRACT_HASH_REPRODUCTION','59 latest | 59 archive | 0 mismatches','PASS',''),
('66','11','M2_10_PORTFOLIO_ANALYTICS','6','STAGE_BOUNDARY','MANDATORY','PASS','msbf_ctl.m2_10_portfolio_analytics_contract_registry|msbf_ctl.run_evidence|accepted detail-report boundary output','M2_10_%BOUNDARY%|M2_10_%BLOCKING%','0 blocking or stage-boundary findings','PASS',''),
('67','12','M2_11_STRATEGY_SIMULATION','1','ACCEPTANCE_LIFECYCLE','MANDATORY','PASS','msbf_ctl.m2_11_portfolio_strategy_contract_registry|msbf_ctl.acceptance_gate_result|msbf_ctl.run_evidence','M2_11_ACCEPTANCE_SUMMARY','1 registry accepted | 1 gate PASS | 1 acceptance summary','PASS','a67d375b9f9248b3eec8160cf3dc656d'),
('68','12','M2_11_STRATEGY_SIMULATION','2','POSITIVE_VALIDATION','MANDATORY','PASS','msbf_ctl.run_evidence','M2_11_POS_%','120','PASS',''),
('69','12','M2_11_STRATEGY_SIMULATION','3','NEGATIVE_CONTROLS','MANDATORY','PASS','msbf_ctl.run_evidence','M2_11_NEG_%','20','PASS',''),
('70','12','M2_11_STRATEGY_SIMULATION','4','CANONICAL_IDENTITY','MANDATORY','PASS','msbf_ctl.m2_11_portfolio_strategy_contract_registry','PHYSICAL_CANONICAL_RECONSTRUCTION','19298','PASS','a67d375b9f9248b3eec8160cf3dc656d'),
('71','12','M2_11_STRATEGY_SIMULATION','5','LATEST_ARCHIVE_REPRODUCTION','MANDATORY','PASS','msbf_m2.portfolio_strategy_simulation_latest|msbf_m2.portfolio_strategy_simulation_archive','EXACT_PAYLOAD_AND_CONTRACT_HASH_REPRODUCTION','24 latest | 24 archive | 0 mismatches','PASS',''),
('72','12','M2_11_STRATEGY_SIMULATION','6','STAGE_BOUNDARY','MANDATORY','PASS','msbf_ctl.m2_11_portfolio_strategy_contract_registry|msbf_ctl.run_evidence|accepted detail-report boundary output','M2_11_%BOUNDARY%|M2_11_%BLOCKING%','0 blocking or stage-boundary findings','PASS','');

ANALYZE tmp_src_m2_12_evidence_authority;


CREATE TEMP TABLE tmp_src_m2_12_capability_authority
(
 capability_sequence smallint NOT NULL,capability_code text NOT NULL,coverage_status_code text NOT NULL,
 certifying_stage_code text NOT NULL,claim_boundary text NOT NULL,
 production_action_authorized_flag boolean NOT NULL,legal_or_regulatory_certified_flag boolean NOT NULL,
 notes text NOT NULL,PRIMARY KEY(capability_sequence,capability_code)
) ON COMMIT DROP;

INSERT INTO tmp_src_m2_12_capability_authority VALUES
('1','M1_G2_APPLICATION_RISK_FOUNDATION','IMPLEMENTED_CERTIFIED','M1_17_G2_FOUNDATION','Accepted application, risk, economics, acquisition, evidence, and scenario foundation.',FALSE,FALSE,'Module 2 source boundary'),
('2','ELIGIBILITY_POLICY_ROUTING','IMPLEMENTED_CERTIFIED','M2_1_ELIGIBILITY_ROUTING','Governed eligibility gates, policy results, reasons, and routing outcomes.',FALSE,FALSE,'As-built accepted scope'),
('3','PRICING_STRUCTURE_COUNTEROFFER','IMPLEMENTED_CERTIFIED','M2_2_PRICING_STRUCTURE','Accepted request structures, finite pricing candidates, counteroffer foundations, and scenario results.',FALSE,FALSE,'As-built accepted scope'),
('4','FINAL_OFFER_DECISION_AUTHORIZATION','IMPLEMENTED_CERTIFIED_SYNTHETIC','M2_3_FINAL_DECISION','Synthetic final offer and decision authorization evidence only.',FALSE,FALSE,'Not a production credit decision'),
('5','BOOKING_FUNDING_PORTFOLIO_ACTIVATION','IMPLEMENTED_BOUNDED_SYNTHETIC','M2_4_PORTFOLIO_ACTIVATION','Synthetic booking, funding, account, advance, and portfolio activation records.',FALSE,FALSE,'No real booking or funds movement'),
('6','DAILY_REMITTANCE_EXPOSURE_MONITORING','IMPLEMENTED_BOUNDED_SYNTHETIC','M2_5_DAILY_MONITORING','Synthetic daily remittance, exposure, monitoring, alert, and portfolio summaries.',FALSE,FALSE,'No production ledger or processor execution'),
('7','EARLY_WARNING_INTERVENTION_SERVICING','IMPLEMENTED_BOUNDED_RECOMMENDATION','M2_6_INTERVENTION_STRATEGY','Synthetic early-warning and servicing-action recommendations.',FALSE,FALSE,'Recommendation evidence only'),
('8','OPERATIONAL_ACTIVATION_ACCOUNT_SETUP','IMPLEMENTED_BOUNDED_SYNTHETIC','M2_7_OPERATIONAL_ACTIVATION','Synthetic operational account setup and reassessment evidence.',FALSE,FALSE,'No external system update'),
('9','SERVICING_PAYMENT_LIFECYCLE_SIMULATION','IMPLEMENTED_BOUNDED_SYNTHETIC','M2_8_SERVICING_EXECUTION','Synthetic payment-processing events and lifecycle transitions.',FALSE,FALSE,'No payment-network or bank-account activity'),
('10','PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION','IMPLEMENTED_CERTIFIED_SYNTHETIC','M2_9_RECONCILIATION_CERTIFICATION','Reconciled synthetic payment evidence and certified synthetic account states.',FALSE,FALSE,'Not production accounting certification'),
('11','PORTFOLIO_KPI_SERVICING_ANALYTICS','IMPLEMENTED_CERTIFIED_ANALYTICS','M2_10_PORTFOLIO_ANALYTICS','Governed KPI, performance-tier, servicing-queue, exposure, payment, and exception analytics.',FALSE,FALSE,'Synthetic analytics only'),
('12','PORTFOLIO_STRATEGY_FRONTIER','IMPLEMENTED_CERTIFIED_COMPARATIVE','M2_11_STRATEGY_SIMULATION','Finite deterministic strategy comparison, Pareto frontier, and governance-review priority evidence.',FALSE,FALSE,'Not a champion or deployment decision'),
('13','COLLATERAL_GUARANTEE_PACKAGE','DEFERRED_NOT_IMPLEMENTED','NONE','Original charter capability not implemented in the accepted M2.1-M2.11 chain.',FALSE,FALSE,'Requires separate future design and data'),
('14','COVENANT_PACKAGE_AND_TESTING','DEFERRED_NOT_IMPLEMENTED','NONE','Original charter capability not implemented as a governed covenant package or test framework.',FALSE,FALSE,'Requires separate future lifecycle design'),
('15','REGULATORY_APPLICABILITY_LEGAL_COMPLIANCE','DEFERRED_NOT_CERTIFIED','NONE','No jurisdiction, licensing, disclosure, legal-form, UDAAP, fair-lending, or regulatory applicability certification.',FALSE,FALSE,'Legal/compliance review required before production'),
('16','PORTFOLIO_FUNDING_BUDGET_ALLOCATION','DEFERRED_NOT_IMPLEMENTED','NONE','No production funding-budget, capital-allocation, or concentration-allocation engine.',FALSE,FALSE,'Strategy exposure comparisons are not allocation authority'),
('17','PRODUCTION_DECISION_ACCOUNT_PAYMENT_EXECUTION','PROHIBITED_NOT_AUTHORIZED','NONE','No production decision, account creation, payment instruction, processor call, or funds movement.',FALSE,FALSE,'Production execution expressly prohibited'),
('18','ACCOUNTING_CECL_CAPITAL_TREASURY','DEFERRED_NOT_CERTIFIED','NONE','No GAAP accounting, CECL reserve, economic capital, regulatory capital, or treasury certification.',FALSE,FALSE,'Comparative expected loss and contribution are synthetic'),
('19','EMPIRICAL_CAUSAL_OPTIMIZATION_CHAMPION','NOT_SUPPORTED_NOT_AUTHORIZED','NONE','No causal uplift, calibrated treatment effect, autonomous optimization, production champion, or statistical generalization.',FALSE,FALSE,'M2.11 priority is governance review only'),
('20','CUSTOMER_MERCHANT_NOTICE_ADVERSE_ACTION','PROHIBITED_NOT_AUTHORIZED','NONE','No merchant-facing offer, notice, adverse-action communication, collection notice, or legal communication.',FALSE,FALSE,'Synthetic reason evidence is not customer communication');

ANALYZE tmp_src_m2_12_capability_authority;


/* Exact 19-edge physical reconstruction, owned by Program 223. */
CREATE TEMP TABLE tmp_eval_m2_12_validation_source_edges ON COMMIT DROP AS
(SELECT x.module1_run_id,
       x.edge_sequence,
       x.edge_code,
       x.target_node_code,
       x.expected_source_hash,
       x.observed_accepted_source_hash,
       x.observed_target_recorded_source_hash,
       x.source_gate_status,
       x.source_registry_row_count,
       x.target_registry_row_count,
       (x.observed_accepted_source_hash IS DISTINCT FROM x.expected_source_hash) AS source_hash_mismatch_flag,
       (x.observed_target_recorded_source_hash IS DISTINCT FROM x.expected_source_hash) AS target_hash_mismatch_flag,
       CASE WHEN x.source_registry_row_count=1
                  AND x.target_registry_row_count=1
                  AND x.source_gate_status='PASS'
                  AND x.observed_accepted_source_hash=x.expected_source_hash
                  AND x.observed_target_recorded_source_hash=x.expected_source_hash
            THEN 'PASS'::text ELSE 'FAIL'::text END AS edge_status
FROM (
SELECT ctx.module1_run_id,
       1::smallint AS edge_sequence,
       'M1_15_TO_M1_17_APPLICATION_CONTRACT'::text AS edge_code,
       'M1_17_G2_FOUNDATION'::text AS target_node_code,
       'fcd2704e17ec0d2e73191ea36061d74b'::text AS expected_source_hash,
       ((SELECT src.combined_set_hash::text FROM msbf_ctl.m1_15_consumption_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_code='M1_APPLICATION_CONSUMPTION' AND src.contract_version=1 AND src.contract_status='ACCEPTED'))::text AS observed_accepted_source_hash,
       ((SELECT tgt.source_m1_15_combined_hash::text FROM msbf_ctl.m1_17_g2_bundle_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.bundle_code='M1_G2_CONSUMPTION_BUNDLE' AND tgt.bundle_version=1 AND tgt.bundle_status='ACCEPTED'))::text AS observed_target_recorded_source_hash,
       ((SELECT agr.result_status::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='M1_15_CONSUMPTION_CONTRACT' AND agr.review_version=1))::text AS source_gate_status,
       (SELECT count(*)::bigint FROM (SELECT src.combined_set_hash::text FROM msbf_ctl.m1_15_consumption_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_code='M1_APPLICATION_CONSUMPTION' AND src.contract_version=1 AND src.contract_status='ACCEPTED') src_count) AS source_registry_row_count,
       (SELECT count(*)::bigint FROM (SELECT tgt.source_m1_15_combined_hash::text FROM msbf_ctl.m1_17_g2_bundle_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.bundle_code='M1_G2_CONSUMPTION_BUNDLE' AND tgt.bundle_version=1 AND tgt.bundle_status='ACCEPTED') tgt_count) AS target_registry_row_count
FROM tmp_src_m2_12_validation_run_context ctx
) x)
UNION ALL
(SELECT x.module1_run_id,
       x.edge_sequence,
       x.edge_code,
       x.target_node_code,
       x.expected_source_hash,
       x.observed_accepted_source_hash,
       x.observed_target_recorded_source_hash,
       x.source_gate_status,
       x.source_registry_row_count,
       x.target_registry_row_count,
       (x.observed_accepted_source_hash IS DISTINCT FROM x.expected_source_hash) AS source_hash_mismatch_flag,
       (x.observed_target_recorded_source_hash IS DISTINCT FROM x.expected_source_hash) AS target_hash_mismatch_flag,
       CASE WHEN x.source_registry_row_count=1
                  AND x.target_registry_row_count=1
                  AND x.source_gate_status='PASS'
                  AND x.observed_accepted_source_hash=x.expected_source_hash
                  AND x.observed_target_recorded_source_hash=x.expected_source_hash
            THEN 'PASS'::text ELSE 'FAIL'::text END AS edge_status
FROM (
SELECT ctx.module1_run_id,
       2::smallint AS edge_sequence,
       'M1_16_TO_M1_17_ACQUISITION_CONTRACT'::text AS edge_code,
       'M1_17_G2_FOUNDATION'::text AS target_node_code,
       '86df51a0ca68d84096d00ff0f1b19f33'::text AS expected_source_hash,
       ((SELECT src.combined_set_hash::text FROM msbf_ctl.m1_16_acquisition_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_code='M1_ACQUISITION_CONSUMPTION' AND src.contract_version=1 AND src.contract_status='ACCEPTED'))::text AS observed_accepted_source_hash,
       ((SELECT tgt.source_m1_16_combined_hash::text FROM msbf_ctl.m1_17_g2_bundle_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.bundle_code='M1_G2_CONSUMPTION_BUNDLE' AND tgt.bundle_version=1 AND tgt.bundle_status='ACCEPTED'))::text AS observed_target_recorded_source_hash,
       ((SELECT agr.result_status::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='M1_16_ACQUISITION_MARKETING_COST_FOUNDATIONS' AND agr.review_version=1))::text AS source_gate_status,
       (SELECT count(*)::bigint FROM (SELECT src.combined_set_hash::text FROM msbf_ctl.m1_16_acquisition_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_code='M1_ACQUISITION_CONSUMPTION' AND src.contract_version=1 AND src.contract_status='ACCEPTED') src_count) AS source_registry_row_count,
       (SELECT count(*)::bigint FROM (SELECT tgt.source_m1_16_combined_hash::text FROM msbf_ctl.m1_17_g2_bundle_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.bundle_code='M1_G2_CONSUMPTION_BUNDLE' AND tgt.bundle_version=1 AND tgt.bundle_status='ACCEPTED') tgt_count) AS target_registry_row_count
FROM tmp_src_m2_12_validation_run_context ctx
) x)
UNION ALL
(SELECT x.module1_run_id,
       x.edge_sequence,
       x.edge_code,
       x.target_node_code,
       x.expected_source_hash,
       x.observed_accepted_source_hash,
       x.observed_target_recorded_source_hash,
       x.source_gate_status,
       x.source_registry_row_count,
       x.target_registry_row_count,
       (x.observed_accepted_source_hash IS DISTINCT FROM x.expected_source_hash) AS source_hash_mismatch_flag,
       (x.observed_target_recorded_source_hash IS DISTINCT FROM x.expected_source_hash) AS target_hash_mismatch_flag,
       CASE WHEN x.source_registry_row_count=1
                  AND x.target_registry_row_count=1
                  AND x.source_gate_status='PASS'
                  AND x.observed_accepted_source_hash=x.expected_source_hash
                  AND x.observed_target_recorded_source_hash=x.expected_source_hash
            THEN 'PASS'::text ELSE 'FAIL'::text END AS edge_status
FROM (
SELECT ctx.module1_run_id,
       3::smallint AS edge_sequence,
       'M1_17_TO_M2_1'::text AS edge_code,
       'M2_1_ELIGIBILITY_ROUTING'::text AS target_node_code,
       '7d9e466da28cad2551aa99c4c40c912b'::text AS expected_source_hash,
       ((SELECT src.combined_g2_hash::text FROM msbf_ctl.m1_17_g2_bundle_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.bundle_code='M1_G2_CONSUMPTION_BUNDLE' AND src.bundle_version=1 AND src.bundle_status='ACCEPTED'))::text AS observed_accepted_source_hash,
       ((SELECT tgt.source_g2_combined_hash::text FROM msbf_ctl.m2_1_strategy_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_ELIGIBILITY_ROUTING_CONSUMPTION' AND tgt.contract_version=1 AND tgt.contract_status='ACCEPTED'))::text AS observed_target_recorded_source_hash,
       ((SELECT agr.result_status::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='G2_M1_CONTRACT' AND agr.review_version=1))::text AS source_gate_status,
       (SELECT count(*)::bigint FROM (SELECT src.combined_g2_hash::text FROM msbf_ctl.m1_17_g2_bundle_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.bundle_code='M1_G2_CONSUMPTION_BUNDLE' AND src.bundle_version=1 AND src.bundle_status='ACCEPTED') src_count) AS source_registry_row_count,
       (SELECT count(*)::bigint FROM (SELECT tgt.source_g2_combined_hash::text FROM msbf_ctl.m2_1_strategy_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_ELIGIBILITY_ROUTING_CONSUMPTION' AND tgt.contract_version=1 AND tgt.contract_status='ACCEPTED') tgt_count) AS target_registry_row_count
FROM tmp_src_m2_12_validation_run_context ctx
) x)
UNION ALL
(SELECT x.module1_run_id,
       x.edge_sequence,
       x.edge_code,
       x.target_node_code,
       x.expected_source_hash,
       x.observed_accepted_source_hash,
       x.observed_target_recorded_source_hash,
       x.source_gate_status,
       x.source_registry_row_count,
       x.target_registry_row_count,
       (x.observed_accepted_source_hash IS DISTINCT FROM x.expected_source_hash) AS source_hash_mismatch_flag,
       (x.observed_target_recorded_source_hash IS DISTINCT FROM x.expected_source_hash) AS target_hash_mismatch_flag,
       CASE WHEN x.source_registry_row_count=1
                  AND x.target_registry_row_count=1
                  AND x.source_gate_status='PASS'
                  AND x.observed_accepted_source_hash=x.expected_source_hash
                  AND x.observed_target_recorded_source_hash=x.expected_source_hash
            THEN 'PASS'::text ELSE 'FAIL'::text END AS edge_status
FROM (
SELECT ctx.module1_run_id,
       4::smallint AS edge_sequence,
       'M2_1_TO_M2_2'::text AS edge_code,
       'M2_2_PRICING_STRUCTURE'::text AS target_node_code,
       'e5ace7f32060ffb191c7bd0f8dd0c863'::text AS expected_source_hash,
       ((SELECT src.combined_set_hash::text FROM msbf_ctl.m2_1_strategy_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_code='M2_ELIGIBILITY_ROUTING_CONSUMPTION' AND src.contract_version=1 AND src.contract_status='ACCEPTED'))::text AS observed_accepted_source_hash,
       ((SELECT tgt.source_m2_1_combined_hash::text FROM msbf_ctl.m2_2_pricing_structure_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.request_contract_code='M2_REQUEST_STRUCTURE_CONSUMPTION' AND tgt.request_contract_version=1 AND tgt.pricing_contract_code='M2_PRICING_STRUCTURE_CONSUMPTION' AND tgt.pricing_contract_version=1 AND tgt.contract_status='ACCEPTED'))::text AS observed_target_recorded_source_hash,
       ((SELECT agr.result_status::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='M2_1_ELIGIBILITY_POLICY_ROUTING' AND agr.review_version=1))::text AS source_gate_status,
       (SELECT count(*)::bigint FROM (SELECT src.combined_set_hash::text FROM msbf_ctl.m2_1_strategy_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_code='M2_ELIGIBILITY_ROUTING_CONSUMPTION' AND src.contract_version=1 AND src.contract_status='ACCEPTED') src_count) AS source_registry_row_count,
       (SELECT count(*)::bigint FROM (SELECT tgt.source_m2_1_combined_hash::text FROM msbf_ctl.m2_2_pricing_structure_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.request_contract_code='M2_REQUEST_STRUCTURE_CONSUMPTION' AND tgt.request_contract_version=1 AND tgt.pricing_contract_code='M2_PRICING_STRUCTURE_CONSUMPTION' AND tgt.pricing_contract_version=1 AND tgt.contract_status='ACCEPTED') tgt_count) AS target_registry_row_count
FROM tmp_src_m2_12_validation_run_context ctx
) x)
UNION ALL
(SELECT x.module1_run_id,
       x.edge_sequence,
       x.edge_code,
       x.target_node_code,
       x.expected_source_hash,
       x.observed_accepted_source_hash,
       x.observed_target_recorded_source_hash,
       x.source_gate_status,
       x.source_registry_row_count,
       x.target_registry_row_count,
       (x.observed_accepted_source_hash IS DISTINCT FROM x.expected_source_hash) AS source_hash_mismatch_flag,
       (x.observed_target_recorded_source_hash IS DISTINCT FROM x.expected_source_hash) AS target_hash_mismatch_flag,
       CASE WHEN x.source_registry_row_count=1
                  AND x.target_registry_row_count=1
                  AND x.source_gate_status='PASS'
                  AND x.observed_accepted_source_hash=x.expected_source_hash
                  AND x.observed_target_recorded_source_hash=x.expected_source_hash
            THEN 'PASS'::text ELSE 'FAIL'::text END AS edge_status
FROM (
SELECT ctx.module1_run_id,
       5::smallint AS edge_sequence,
       'M1_3_TO_M2_2_REQUEST_AUTHORITY'::text AS edge_code,
       'M2_2_PRICING_STRUCTURE'::text AS target_node_code,
       '01485256b9b5748fb412743d35ced602'::text AS expected_source_hash,
       ((SELECT (agr.observed_value::jsonb ->> 'application_set_hash')::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='M1_3_APPLICATION_REQUEST' AND agr.review_version=2 AND agr.result_status='PASS'))::text AS observed_accepted_source_hash,
       ((SELECT tgt.source_m1_3_application_hash::text FROM msbf_ctl.m2_2_pricing_structure_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.request_contract_code='M2_REQUEST_STRUCTURE_CONSUMPTION' AND tgt.request_contract_version=1 AND tgt.pricing_contract_code='M2_PRICING_STRUCTURE_CONSUMPTION' AND tgt.pricing_contract_version=1 AND tgt.source_m1_3_gate_id='M1_3_APPLICATION_REQUEST' AND tgt.contract_status='ACCEPTED'))::text AS observed_target_recorded_source_hash,
       ((SELECT agr.result_status::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='M1_3_APPLICATION_REQUEST' AND agr.review_version=2))::text AS source_gate_status,
       (SELECT count(*)::bigint FROM (SELECT (agr.observed_value::jsonb ->> 'application_set_hash')::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='M1_3_APPLICATION_REQUEST' AND agr.review_version=2 AND agr.result_status='PASS') src_count) AS source_registry_row_count,
       (SELECT count(*)::bigint FROM (SELECT tgt.source_m1_3_application_hash::text FROM msbf_ctl.m2_2_pricing_structure_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.request_contract_code='M2_REQUEST_STRUCTURE_CONSUMPTION' AND tgt.request_contract_version=1 AND tgt.pricing_contract_code='M2_PRICING_STRUCTURE_CONSUMPTION' AND tgt.pricing_contract_version=1 AND tgt.source_m1_3_gate_id='M1_3_APPLICATION_REQUEST' AND tgt.contract_status='ACCEPTED') tgt_count) AS target_registry_row_count
FROM tmp_src_m2_12_validation_run_context ctx
) x)
UNION ALL
(SELECT x.module1_run_id,
       x.edge_sequence,
       x.edge_code,
       x.target_node_code,
       x.expected_source_hash,
       x.observed_accepted_source_hash,
       x.observed_target_recorded_source_hash,
       x.source_gate_status,
       x.source_registry_row_count,
       x.target_registry_row_count,
       (x.observed_accepted_source_hash IS DISTINCT FROM x.expected_source_hash) AS source_hash_mismatch_flag,
       (x.observed_target_recorded_source_hash IS DISTINCT FROM x.expected_source_hash) AS target_hash_mismatch_flag,
       CASE WHEN x.source_registry_row_count=1
                  AND x.target_registry_row_count=1
                  AND x.source_gate_status='PASS'
                  AND x.observed_accepted_source_hash=x.expected_source_hash
                  AND x.observed_target_recorded_source_hash=x.expected_source_hash
            THEN 'PASS'::text ELSE 'FAIL'::text END AS edge_status
FROM (
SELECT ctx.module1_run_id,
       6::smallint AS edge_sequence,
       'M2_2_TO_M2_3'::text AS edge_code,
       'M2_3_FINAL_DECISION'::text AS target_node_code,
       'bbe83b187b31ea561789797322031fc6'::text AS expected_source_hash,
       ((SELECT src.combined_set_hash::text FROM msbf_ctl.m2_2_pricing_structure_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.request_contract_code='M2_REQUEST_STRUCTURE_CONSUMPTION' AND src.request_contract_version=1 AND src.pricing_contract_code='M2_PRICING_STRUCTURE_CONSUMPTION' AND src.pricing_contract_version=1 AND src.contract_status='ACCEPTED'))::text AS observed_accepted_source_hash,
       ((SELECT tgt.source_m2_2_combined_hash::text FROM msbf_ctl.m2_3_final_decision_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_FINAL_OFFER_DECISION_CONSUMPTION' AND tgt.contract_version=1 AND tgt.contract_status='ACCEPTED'))::text AS observed_target_recorded_source_hash,
       ((SELECT agr.result_status::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='M2_2_PRICING_STRUCTURE_COUNTEROFFER' AND agr.review_version=1))::text AS source_gate_status,
       (SELECT count(*)::bigint FROM (SELECT src.combined_set_hash::text FROM msbf_ctl.m2_2_pricing_structure_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.request_contract_code='M2_REQUEST_STRUCTURE_CONSUMPTION' AND src.request_contract_version=1 AND src.pricing_contract_code='M2_PRICING_STRUCTURE_CONSUMPTION' AND src.pricing_contract_version=1 AND src.contract_status='ACCEPTED') src_count) AS source_registry_row_count,
       (SELECT count(*)::bigint FROM (SELECT tgt.source_m2_2_combined_hash::text FROM msbf_ctl.m2_3_final_decision_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_FINAL_OFFER_DECISION_CONSUMPTION' AND tgt.contract_version=1 AND tgt.contract_status='ACCEPTED') tgt_count) AS target_registry_row_count
FROM tmp_src_m2_12_validation_run_context ctx
) x)
UNION ALL
(SELECT x.module1_run_id,
       x.edge_sequence,
       x.edge_code,
       x.target_node_code,
       x.expected_source_hash,
       x.observed_accepted_source_hash,
       x.observed_target_recorded_source_hash,
       x.source_gate_status,
       x.source_registry_row_count,
       x.target_registry_row_count,
       (x.observed_accepted_source_hash IS DISTINCT FROM x.expected_source_hash) AS source_hash_mismatch_flag,
       (x.observed_target_recorded_source_hash IS DISTINCT FROM x.expected_source_hash) AS target_hash_mismatch_flag,
       CASE WHEN x.source_registry_row_count=1
                  AND x.target_registry_row_count=1
                  AND x.source_gate_status='PASS'
                  AND x.observed_accepted_source_hash=x.expected_source_hash
                  AND x.observed_target_recorded_source_hash=x.expected_source_hash
            THEN 'PASS'::text ELSE 'FAIL'::text END AS edge_status
FROM (
SELECT ctx.module1_run_id,
       7::smallint AS edge_sequence,
       'M2_3_TO_M2_4'::text AS edge_code,
       'M2_4_PORTFOLIO_ACTIVATION'::text AS target_node_code,
       'bf09349b06ede7e5a2ec830c2f9ffe90'::text AS expected_source_hash,
       ((SELECT src.combined_set_hash::text FROM msbf_ctl.m2_3_final_decision_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_code='M2_FINAL_OFFER_DECISION_CONSUMPTION' AND src.contract_version=1 AND src.contract_status='ACCEPTED'))::text AS observed_accepted_source_hash,
       ((SELECT tgt.source_m2_3_combined_hash::text FROM msbf_ctl.m2_4_portfolio_activation_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_PORTFOLIO_ACTIVATION_CONSUMPTION' AND tgt.contract_version=1 AND tgt.contract_status='ACCEPTED'))::text AS observed_target_recorded_source_hash,
       ((SELECT agr.result_status::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='M2_3_FINAL_OFFER_DECISION_AUTHORIZATION' AND agr.review_version=1))::text AS source_gate_status,
       (SELECT count(*)::bigint FROM (SELECT src.combined_set_hash::text FROM msbf_ctl.m2_3_final_decision_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_code='M2_FINAL_OFFER_DECISION_CONSUMPTION' AND src.contract_version=1 AND src.contract_status='ACCEPTED') src_count) AS source_registry_row_count,
       (SELECT count(*)::bigint FROM (SELECT tgt.source_m2_3_combined_hash::text FROM msbf_ctl.m2_4_portfolio_activation_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_PORTFOLIO_ACTIVATION_CONSUMPTION' AND tgt.contract_version=1 AND tgt.contract_status='ACCEPTED') tgt_count) AS target_registry_row_count
FROM tmp_src_m2_12_validation_run_context ctx
) x)
UNION ALL
(SELECT x.module1_run_id,
       x.edge_sequence,
       x.edge_code,
       x.target_node_code,
       x.expected_source_hash,
       x.observed_accepted_source_hash,
       x.observed_target_recorded_source_hash,
       x.source_gate_status,
       x.source_registry_row_count,
       x.target_registry_row_count,
       (x.observed_accepted_source_hash IS DISTINCT FROM x.expected_source_hash) AS source_hash_mismatch_flag,
       (x.observed_target_recorded_source_hash IS DISTINCT FROM x.expected_source_hash) AS target_hash_mismatch_flag,
       CASE WHEN x.source_registry_row_count=1
                  AND x.target_registry_row_count=1
                  AND x.source_gate_status='PASS'
                  AND x.observed_accepted_source_hash=x.expected_source_hash
                  AND x.observed_target_recorded_source_hash=x.expected_source_hash
            THEN 'PASS'::text ELSE 'FAIL'::text END AS edge_status
FROM (
SELECT ctx.module1_run_id,
       8::smallint AS edge_sequence,
       'M2_4_TO_M2_5'::text AS edge_code,
       'M2_5_DAILY_MONITORING'::text AS target_node_code,
       '117450a3eea7bb3d3c74d18cc3c8e96a'::text AS expected_source_hash,
       ((SELECT src.combined_set_hash::text FROM msbf_ctl.m2_4_portfolio_activation_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_code='M2_PORTFOLIO_ACTIVATION_CONSUMPTION' AND src.contract_version=1 AND src.contract_status='ACCEPTED'))::text AS observed_accepted_source_hash,
       ((SELECT tgt.source_m2_4_combined_hash::text FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_DAILY_REMITTANCE_EXPOSURE_MONITORING_CONSUMPTION' AND tgt.contract_version=1 AND tgt.contract_status='ACCEPTED'))::text AS observed_target_recorded_source_hash,
       ((SELECT agr.result_status::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='M2_4_BOOKING_FUNDING_PORTFOLIO_ACTIVATION' AND agr.review_version=1))::text AS source_gate_status,
       (SELECT count(*)::bigint FROM (SELECT src.combined_set_hash::text FROM msbf_ctl.m2_4_portfolio_activation_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_code='M2_PORTFOLIO_ACTIVATION_CONSUMPTION' AND src.contract_version=1 AND src.contract_status='ACCEPTED') src_count) AS source_registry_row_count,
       (SELECT count(*)::bigint FROM (SELECT tgt.source_m2_4_combined_hash::text FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_DAILY_REMITTANCE_EXPOSURE_MONITORING_CONSUMPTION' AND tgt.contract_version=1 AND tgt.contract_status='ACCEPTED') tgt_count) AS target_registry_row_count
FROM tmp_src_m2_12_validation_run_context ctx
) x)
UNION ALL
(SELECT x.module1_run_id,
       x.edge_sequence,
       x.edge_code,
       x.target_node_code,
       x.expected_source_hash,
       x.observed_accepted_source_hash,
       x.observed_target_recorded_source_hash,
       x.source_gate_status,
       x.source_registry_row_count,
       x.target_registry_row_count,
       (x.observed_accepted_source_hash IS DISTINCT FROM x.expected_source_hash) AS source_hash_mismatch_flag,
       (x.observed_target_recorded_source_hash IS DISTINCT FROM x.expected_source_hash) AS target_hash_mismatch_flag,
       CASE WHEN x.source_registry_row_count=1
                  AND x.target_registry_row_count=1
                  AND x.source_gate_status='PASS'
                  AND x.observed_accepted_source_hash=x.expected_source_hash
                  AND x.observed_target_recorded_source_hash=x.expected_source_hash
            THEN 'PASS'::text ELSE 'FAIL'::text END AS edge_status
FROM (
SELECT ctx.module1_run_id,
       9::smallint AS edge_sequence,
       'M1_6_TO_M2_5_SCENARIO_AUTHORITY'::text AS edge_code,
       'M2_5_DAILY_MONITORING'::text AS target_node_code,
       '3f85921bf6fc30ddc6cee146085e58c5'::text AS expected_source_hash,
       ((SELECT (agr.observed_value::jsonb->>'combined_hash')::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='M1_6_MATCHED_SCENARIO_OVERLAYS' AND agr.review_version=1 AND agr.result_status='PASS'))::text AS observed_accepted_source_hash,
       ((SELECT tgt.source_m1_6_combined_hash::text FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_DAILY_REMITTANCE_EXPOSURE_MONITORING_CONSUMPTION' AND tgt.contract_version=1 AND tgt.source_m1_6_acceptance_gate_id='M1_6_MATCHED_SCENARIO_OVERLAYS' AND tgt.contract_status='ACCEPTED'))::text AS observed_target_recorded_source_hash,
       ((SELECT agr.result_status::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='M1_6_MATCHED_SCENARIO_OVERLAYS' AND agr.review_version=1))::text AS source_gate_status,
       (SELECT count(*)::bigint FROM (SELECT (agr.observed_value::jsonb->>'combined_hash')::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='M1_6_MATCHED_SCENARIO_OVERLAYS' AND agr.review_version=1 AND agr.result_status='PASS') src_count) AS source_registry_row_count,
       (SELECT count(*)::bigint FROM (SELECT tgt.source_m1_6_combined_hash::text FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_DAILY_REMITTANCE_EXPOSURE_MONITORING_CONSUMPTION' AND tgt.contract_version=1 AND tgt.source_m1_6_acceptance_gate_id='M1_6_MATCHED_SCENARIO_OVERLAYS' AND tgt.contract_status='ACCEPTED') tgt_count) AS target_registry_row_count
FROM tmp_src_m2_12_validation_run_context ctx
) x)
UNION ALL
(SELECT x.module1_run_id,
       x.edge_sequence,
       x.edge_code,
       x.target_node_code,
       x.expected_source_hash,
       x.observed_accepted_source_hash,
       x.observed_target_recorded_source_hash,
       x.source_gate_status,
       x.source_registry_row_count,
       x.target_registry_row_count,
       (x.observed_accepted_source_hash IS DISTINCT FROM x.expected_source_hash) AS source_hash_mismatch_flag,
       (x.observed_target_recorded_source_hash IS DISTINCT FROM x.expected_source_hash) AS target_hash_mismatch_flag,
       CASE WHEN x.source_registry_row_count=1
                  AND x.target_registry_row_count=1
                  AND x.source_gate_status='PASS'
                  AND x.observed_accepted_source_hash=x.expected_source_hash
                  AND x.observed_target_recorded_source_hash=x.expected_source_hash
            THEN 'PASS'::text ELSE 'FAIL'::text END AS edge_status
FROM (
SELECT ctx.module1_run_id,
       10::smallint AS edge_sequence,
       'M2_5_TO_M2_6'::text AS edge_code,
       'M2_6_INTERVENTION_STRATEGY'::text AS target_node_code,
       '18e1c444aa1b02ee5bd3539d7c477adc'::text AS expected_source_hash,
       ((SELECT src.combined_set_hash::text FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_code='M2_DAILY_REMITTANCE_EXPOSURE_MONITORING_CONSUMPTION' AND src.contract_version=1 AND src.contract_status='ACCEPTED'))::text AS observed_accepted_source_hash,
       ((SELECT tgt.source_m2_5_combined_hash::text FROM msbf_ctl.m2_6_intervention_strategy_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_CONSUMPTION' AND tgt.contract_version=1 AND tgt.contract_status='ACCEPTED'))::text AS observed_target_recorded_source_hash,
       ((SELECT agr.result_status::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='M2_5_DAILY_REMITTANCE_EXPOSURE_PORTFOLIO_MONITORING' AND agr.review_version=1))::text AS source_gate_status,
       (SELECT count(*)::bigint FROM (SELECT src.combined_set_hash::text FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_code='M2_DAILY_REMITTANCE_EXPOSURE_MONITORING_CONSUMPTION' AND src.contract_version=1 AND src.contract_status='ACCEPTED') src_count) AS source_registry_row_count,
       (SELECT count(*)::bigint FROM (SELECT tgt.source_m2_5_combined_hash::text FROM msbf_ctl.m2_6_intervention_strategy_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_CONSUMPTION' AND tgt.contract_version=1 AND tgt.contract_status='ACCEPTED') tgt_count) AS target_registry_row_count
FROM tmp_src_m2_12_validation_run_context ctx
) x)
UNION ALL
(SELECT x.module1_run_id,
       x.edge_sequence,
       x.edge_code,
       x.target_node_code,
       x.expected_source_hash,
       x.observed_accepted_source_hash,
       x.observed_target_recorded_source_hash,
       x.source_gate_status,
       x.source_registry_row_count,
       x.target_registry_row_count,
       (x.observed_accepted_source_hash IS DISTINCT FROM x.expected_source_hash) AS source_hash_mismatch_flag,
       (x.observed_target_recorded_source_hash IS DISTINCT FROM x.expected_source_hash) AS target_hash_mismatch_flag,
       CASE WHEN x.source_registry_row_count=1
                  AND x.target_registry_row_count=1
                  AND x.source_gate_status='PASS'
                  AND x.observed_accepted_source_hash=x.expected_source_hash
                  AND x.observed_target_recorded_source_hash=x.expected_source_hash
            THEN 'PASS'::text ELSE 'FAIL'::text END AS edge_status
FROM (
SELECT ctx.module1_run_id,
       11::smallint AS edge_sequence,
       'M2_6_TO_M2_7'::text AS edge_code,
       'M2_7_OPERATIONAL_ACTIVATION'::text AS target_node_code,
       '868125bff29270490cab4d2e55cb1388'::text AS expected_source_hash,
       ((SELECT src.combined_set_hash::text FROM msbf_ctl.m2_6_intervention_strategy_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_code='M2_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_CONSUMPTION' AND src.contract_version=1 AND src.contract_status='ACCEPTED'))::text AS observed_accepted_source_hash,
       ((SELECT tgt.source_combined_set_hash::text FROM msbf_ctl.m2_7_operational_activation_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION' AND tgt.contract_version=1 AND tgt.contract_status='ACCEPTED'))::text AS observed_target_recorded_source_hash,
       ((SELECT agr.result_status::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='M2_6_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY' AND agr.review_version=1))::text AS source_gate_status,
       (SELECT count(*)::bigint FROM (SELECT src.combined_set_hash::text FROM msbf_ctl.m2_6_intervention_strategy_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_code='M2_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_CONSUMPTION' AND src.contract_version=1 AND src.contract_status='ACCEPTED') src_count) AS source_registry_row_count,
       (SELECT count(*)::bigint FROM (SELECT tgt.source_combined_set_hash::text FROM msbf_ctl.m2_7_operational_activation_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION' AND tgt.contract_version=1 AND tgt.contract_status='ACCEPTED') tgt_count) AS target_registry_row_count
FROM tmp_src_m2_12_validation_run_context ctx
) x)
UNION ALL
(SELECT x.module1_run_id,
       x.edge_sequence,
       x.edge_code,
       x.target_node_code,
       x.expected_source_hash,
       x.observed_accepted_source_hash,
       x.observed_target_recorded_source_hash,
       x.source_gate_status,
       x.source_registry_row_count,
       x.target_registry_row_count,
       (x.observed_accepted_source_hash IS DISTINCT FROM x.expected_source_hash) AS source_hash_mismatch_flag,
       (x.observed_target_recorded_source_hash IS DISTINCT FROM x.expected_source_hash) AS target_hash_mismatch_flag,
       CASE WHEN x.source_registry_row_count=1
                  AND x.target_registry_row_count=1
                  AND x.source_gate_status='PASS'
                  AND x.observed_accepted_source_hash=x.expected_source_hash
                  AND x.observed_target_recorded_source_hash=x.expected_source_hash
            THEN 'PASS'::text ELSE 'FAIL'::text END AS edge_status
FROM (
SELECT ctx.module1_run_id,
       12::smallint AS edge_sequence,
       'M2_7_TO_M2_8'::text AS edge_code,
       'M2_8_SERVICING_EXECUTION'::text AS target_node_code,
       'c8e3a472afd2a16b1183677324e9db98'::text AS expected_source_hash,
       ((SELECT src.combined_set_hash::text FROM msbf_ctl.m2_7_operational_activation_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_code='M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION' AND src.contract_version=1 AND src.contract_status='ACCEPTED'))::text AS observed_accepted_source_hash,
       ((SELECT tgt.source_combined_set_hash::text FROM msbf_ctl.m2_8_servicing_execution_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONSUMPTION' AND tgt.contract_version=1 AND tgt.contract_status='ACCEPTED'))::text AS observed_target_recorded_source_hash,
       ((SELECT agr.result_status::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP' AND agr.review_version=1))::text AS source_gate_status,
       (SELECT count(*)::bigint FROM (SELECT src.combined_set_hash::text FROM msbf_ctl.m2_7_operational_activation_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_code='M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION' AND src.contract_version=1 AND src.contract_status='ACCEPTED') src_count) AS source_registry_row_count,
       (SELECT count(*)::bigint FROM (SELECT tgt.source_combined_set_hash::text FROM msbf_ctl.m2_8_servicing_execution_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONSUMPTION' AND tgt.contract_version=1 AND tgt.contract_status='ACCEPTED') tgt_count) AS target_registry_row_count
FROM tmp_src_m2_12_validation_run_context ctx
) x)
UNION ALL
(SELECT x.module1_run_id,
       x.edge_sequence,
       x.edge_code,
       x.target_node_code,
       x.expected_source_hash,
       x.observed_accepted_source_hash,
       x.observed_target_recorded_source_hash,
       x.source_gate_status,
       x.source_registry_row_count,
       x.target_registry_row_count,
       (x.observed_accepted_source_hash IS DISTINCT FROM x.expected_source_hash) AS source_hash_mismatch_flag,
       (x.observed_target_recorded_source_hash IS DISTINCT FROM x.expected_source_hash) AS target_hash_mismatch_flag,
       CASE WHEN x.source_registry_row_count=1
                  AND x.target_registry_row_count=1
                  AND x.source_gate_status='PASS'
                  AND x.observed_accepted_source_hash=x.expected_source_hash
                  AND x.observed_target_recorded_source_hash=x.expected_source_hash
            THEN 'PASS'::text ELSE 'FAIL'::text END AS edge_status
FROM (
SELECT ctx.module1_run_id,
       13::smallint AS edge_sequence,
       'M2_8_TO_M2_9'::text AS edge_code,
       'M2_9_RECONCILIATION_CERTIFICATION'::text AS target_node_code,
       'ab32d80ba20c2c8f0a6ec9ec97c2ed26'::text AS expected_source_hash,
       ((SELECT src.combined_set_hash::text FROM msbf_ctl.m2_8_servicing_execution_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_code='M2_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONSUMPTION' AND src.contract_version=1 AND src.contract_status='ACCEPTED'))::text AS observed_accepted_source_hash,
       ((SELECT tgt.source_combined_set_hash::text FROM msbf_ctl.m2_9_reconciliation_certification_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_CONSUMPTION' AND tgt.contract_version=1 AND tgt.contract_status='ACCEPTED'))::text AS observed_target_recorded_source_hash,
       ((SELECT agr.result_status::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='M2_8_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONTROL' AND agr.review_version=1))::text AS source_gate_status,
       (SELECT count(*)::bigint FROM (SELECT src.combined_set_hash::text FROM msbf_ctl.m2_8_servicing_execution_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_code='M2_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONSUMPTION' AND src.contract_version=1 AND src.contract_status='ACCEPTED') src_count) AS source_registry_row_count,
       (SELECT count(*)::bigint FROM (SELECT tgt.source_combined_set_hash::text FROM msbf_ctl.m2_9_reconciliation_certification_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_CONSUMPTION' AND tgt.contract_version=1 AND tgt.contract_status='ACCEPTED') tgt_count) AS target_registry_row_count
FROM tmp_src_m2_12_validation_run_context ctx
) x)
UNION ALL
(SELECT x.module1_run_id,
       x.edge_sequence,
       x.edge_code,
       x.target_node_code,
       x.expected_source_hash,
       x.observed_accepted_source_hash,
       x.observed_target_recorded_source_hash,
       x.source_gate_status,
       x.source_registry_row_count,
       x.target_registry_row_count,
       (x.observed_accepted_source_hash IS DISTINCT FROM x.expected_source_hash) AS source_hash_mismatch_flag,
       (x.observed_target_recorded_source_hash IS DISTINCT FROM x.expected_source_hash) AS target_hash_mismatch_flag,
       CASE WHEN x.source_registry_row_count=1
                  AND x.target_registry_row_count=1
                  AND x.source_gate_status='PASS'
                  AND x.observed_accepted_source_hash=x.expected_source_hash
                  AND x.observed_target_recorded_source_hash=x.expected_source_hash
            THEN 'PASS'::text ELSE 'FAIL'::text END AS edge_status
FROM (
SELECT ctx.module1_run_id,
       14::smallint AS edge_sequence,
       'M2_9_TO_M2_10'::text AS edge_code,
       'M2_10_PORTFOLIO_ANALYTICS'::text AS target_node_code,
       '6af76d0059b47623619ebc09330b15fe'::text AS expected_source_hash,
       ((SELECT src.combined_set_hash::text FROM msbf_ctl.m2_9_reconciliation_certification_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_code='M2_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_CONSUMPTION' AND src.contract_version=1 AND src.contract_status='ACCEPTED'))::text AS observed_accepted_source_hash,
       ((SELECT tgt.source_combined_set_hash::text FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_CONSUMPTION' AND tgt.contract_version=1 AND tgt.contract_status='ACCEPTED'))::text AS observed_target_recorded_source_hash,
       ((SELECT agr.result_status::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='M2_9_PAYMENT_RECONCILIATION_EXCEPTION_RESOLUTION_ACCOUNT_STATE_CERTIFICATION' AND agr.review_version=1))::text AS source_gate_status,
       (SELECT count(*)::bigint FROM (SELECT src.combined_set_hash::text FROM msbf_ctl.m2_9_reconciliation_certification_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_code='M2_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_CONSUMPTION' AND src.contract_version=1 AND src.contract_status='ACCEPTED') src_count) AS source_registry_row_count,
       (SELECT count(*)::bigint FROM (SELECT tgt.source_combined_set_hash::text FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_CONSUMPTION' AND tgt.contract_version=1 AND tgt.contract_status='ACCEPTED') tgt_count) AS target_registry_row_count
FROM tmp_src_m2_12_validation_run_context ctx
) x)
UNION ALL
(SELECT x.module1_run_id,
       x.edge_sequence,
       x.edge_code,
       x.target_node_code,
       x.expected_source_hash,
       x.observed_accepted_source_hash,
       x.observed_target_recorded_source_hash,
       x.source_gate_status,
       x.source_registry_row_count,
       x.target_registry_row_count,
       (x.observed_accepted_source_hash IS DISTINCT FROM x.expected_source_hash) AS source_hash_mismatch_flag,
       (x.observed_target_recorded_source_hash IS DISTINCT FROM x.expected_source_hash) AS target_hash_mismatch_flag,
       CASE WHEN x.source_registry_row_count=1
                  AND x.target_registry_row_count=1
                  AND x.source_gate_status='PASS'
                  AND x.observed_accepted_source_hash=x.expected_source_hash
                  AND x.observed_target_recorded_source_hash=x.expected_source_hash
            THEN 'PASS'::text ELSE 'FAIL'::text END AS edge_status
FROM (
SELECT ctx.module1_run_id,
       15::smallint AS edge_sequence,
       'M1_17_TO_M2_11'::text AS edge_code,
       'M2_11_STRATEGY_SIMULATION'::text AS target_node_code,
       '7d9e466da28cad2551aa99c4c40c912b'::text AS expected_source_hash,
       ((SELECT src.combined_g2_hash::text FROM msbf_ctl.m1_17_g2_bundle_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.bundle_code='M1_G2_CONSUMPTION_BUNDLE' AND src.bundle_version=1 AND src.bundle_status='ACCEPTED'))::text AS observed_accepted_source_hash,
       ((SELECT tgt.source_m1_17_combined_hash::text FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION' AND tgt.contract_version=1 AND tgt.contract_status='ACCEPTED'))::text AS observed_target_recorded_source_hash,
       ((SELECT agr.result_status::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='G2_M1_CONTRACT' AND agr.review_version=1))::text AS source_gate_status,
       (SELECT count(*)::bigint FROM (SELECT src.combined_g2_hash::text FROM msbf_ctl.m1_17_g2_bundle_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.bundle_code='M1_G2_CONSUMPTION_BUNDLE' AND src.bundle_version=1 AND src.bundle_status='ACCEPTED') src_count) AS source_registry_row_count,
       (SELECT count(*)::bigint FROM (SELECT tgt.source_m1_17_combined_hash::text FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION' AND tgt.contract_version=1 AND tgt.contract_status='ACCEPTED') tgt_count) AS target_registry_row_count
FROM tmp_src_m2_12_validation_run_context ctx
) x)
UNION ALL
(SELECT x.module1_run_id,
       x.edge_sequence,
       x.edge_code,
       x.target_node_code,
       x.expected_source_hash,
       x.observed_accepted_source_hash,
       x.observed_target_recorded_source_hash,
       x.source_gate_status,
       x.source_registry_row_count,
       x.target_registry_row_count,
       (x.observed_accepted_source_hash IS DISTINCT FROM x.expected_source_hash) AS source_hash_mismatch_flag,
       (x.observed_target_recorded_source_hash IS DISTINCT FROM x.expected_source_hash) AS target_hash_mismatch_flag,
       CASE WHEN x.source_registry_row_count=1
                  AND x.target_registry_row_count=1
                  AND x.source_gate_status='PASS'
                  AND x.observed_accepted_source_hash=x.expected_source_hash
                  AND x.observed_target_recorded_source_hash=x.expected_source_hash
            THEN 'PASS'::text ELSE 'FAIL'::text END AS edge_status
FROM (
SELECT ctx.module1_run_id,
       16::smallint AS edge_sequence,
       'M2_2_TO_M2_11'::text AS edge_code,
       'M2_11_STRATEGY_SIMULATION'::text AS target_node_code,
       'bbe83b187b31ea561789797322031fc6'::text AS expected_source_hash,
       ((SELECT src.combined_set_hash::text FROM msbf_ctl.m2_2_pricing_structure_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.request_contract_code='M2_REQUEST_STRUCTURE_CONSUMPTION' AND src.request_contract_version=1 AND src.pricing_contract_code='M2_PRICING_STRUCTURE_CONSUMPTION' AND src.pricing_contract_version=1 AND src.contract_status='ACCEPTED'))::text AS observed_accepted_source_hash,
       ((SELECT tgt.source_m2_2_combined_hash::text FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION' AND tgt.contract_version=1 AND tgt.contract_status='ACCEPTED'))::text AS observed_target_recorded_source_hash,
       ((SELECT agr.result_status::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='M2_2_PRICING_STRUCTURE_COUNTEROFFER' AND agr.review_version=1))::text AS source_gate_status,
       (SELECT count(*)::bigint FROM (SELECT src.combined_set_hash::text FROM msbf_ctl.m2_2_pricing_structure_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.request_contract_code='M2_REQUEST_STRUCTURE_CONSUMPTION' AND src.request_contract_version=1 AND src.pricing_contract_code='M2_PRICING_STRUCTURE_CONSUMPTION' AND src.pricing_contract_version=1 AND src.contract_status='ACCEPTED') src_count) AS source_registry_row_count,
       (SELECT count(*)::bigint FROM (SELECT tgt.source_m2_2_combined_hash::text FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION' AND tgt.contract_version=1 AND tgt.contract_status='ACCEPTED') tgt_count) AS target_registry_row_count
FROM tmp_src_m2_12_validation_run_context ctx
) x)
UNION ALL
(SELECT x.module1_run_id,
       x.edge_sequence,
       x.edge_code,
       x.target_node_code,
       x.expected_source_hash,
       x.observed_accepted_source_hash,
       x.observed_target_recorded_source_hash,
       x.source_gate_status,
       x.source_registry_row_count,
       x.target_registry_row_count,
       (x.observed_accepted_source_hash IS DISTINCT FROM x.expected_source_hash) AS source_hash_mismatch_flag,
       (x.observed_target_recorded_source_hash IS DISTINCT FROM x.expected_source_hash) AS target_hash_mismatch_flag,
       CASE WHEN x.source_registry_row_count=1
                  AND x.target_registry_row_count=1
                  AND x.source_gate_status='PASS'
                  AND x.observed_accepted_source_hash=x.expected_source_hash
                  AND x.observed_target_recorded_source_hash=x.expected_source_hash
            THEN 'PASS'::text ELSE 'FAIL'::text END AS edge_status
FROM (
SELECT ctx.module1_run_id,
       17::smallint AS edge_sequence,
       'M2_4_TO_M2_11'::text AS edge_code,
       'M2_11_STRATEGY_SIMULATION'::text AS target_node_code,
       '117450a3eea7bb3d3c74d18cc3c8e96a'::text AS expected_source_hash,
       ((SELECT src.combined_set_hash::text FROM msbf_ctl.m2_4_portfolio_activation_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_code='M2_PORTFOLIO_ACTIVATION_CONSUMPTION' AND src.contract_version=1 AND src.contract_status='ACCEPTED'))::text AS observed_accepted_source_hash,
       ((SELECT tgt.source_m2_4_combined_hash::text FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION' AND tgt.contract_version=1 AND tgt.contract_status='ACCEPTED'))::text AS observed_target_recorded_source_hash,
       ((SELECT agr.result_status::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='M2_4_BOOKING_FUNDING_PORTFOLIO_ACTIVATION' AND agr.review_version=1))::text AS source_gate_status,
       (SELECT count(*)::bigint FROM (SELECT src.combined_set_hash::text FROM msbf_ctl.m2_4_portfolio_activation_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_code='M2_PORTFOLIO_ACTIVATION_CONSUMPTION' AND src.contract_version=1 AND src.contract_status='ACCEPTED') src_count) AS source_registry_row_count,
       (SELECT count(*)::bigint FROM (SELECT tgt.source_m2_4_combined_hash::text FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION' AND tgt.contract_version=1 AND tgt.contract_status='ACCEPTED') tgt_count) AS target_registry_row_count
FROM tmp_src_m2_12_validation_run_context ctx
) x)
UNION ALL
(SELECT x.module1_run_id,
       x.edge_sequence,
       x.edge_code,
       x.target_node_code,
       x.expected_source_hash,
       x.observed_accepted_source_hash,
       x.observed_target_recorded_source_hash,
       x.source_gate_status,
       x.source_registry_row_count,
       x.target_registry_row_count,
       (x.observed_accepted_source_hash IS DISTINCT FROM x.expected_source_hash) AS source_hash_mismatch_flag,
       (x.observed_target_recorded_source_hash IS DISTINCT FROM x.expected_source_hash) AS target_hash_mismatch_flag,
       CASE WHEN x.source_registry_row_count=1
                  AND x.target_registry_row_count=1
                  AND x.source_gate_status='PASS'
                  AND x.observed_accepted_source_hash=x.expected_source_hash
                  AND x.observed_target_recorded_source_hash=x.expected_source_hash
            THEN 'PASS'::text ELSE 'FAIL'::text END AS edge_status
FROM (
SELECT ctx.module1_run_id,
       18::smallint AS edge_sequence,
       'M2_7_TO_M2_11'::text AS edge_code,
       'M2_11_STRATEGY_SIMULATION'::text AS target_node_code,
       'c8e3a472afd2a16b1183677324e9db98'::text AS expected_source_hash,
       ((SELECT src.combined_set_hash::text FROM msbf_ctl.m2_7_operational_activation_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_code='M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION' AND src.contract_version=1 AND src.contract_status='ACCEPTED'))::text AS observed_accepted_source_hash,
       ((SELECT tgt.source_m2_7_combined_hash::text FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION' AND tgt.contract_version=1 AND tgt.contract_status='ACCEPTED'))::text AS observed_target_recorded_source_hash,
       ((SELECT agr.result_status::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP' AND agr.review_version=1))::text AS source_gate_status,
       (SELECT count(*)::bigint FROM (SELECT src.combined_set_hash::text FROM msbf_ctl.m2_7_operational_activation_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_code='M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION' AND src.contract_version=1 AND src.contract_status='ACCEPTED') src_count) AS source_registry_row_count,
       (SELECT count(*)::bigint FROM (SELECT tgt.source_m2_7_combined_hash::text FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION' AND tgt.contract_version=1 AND tgt.contract_status='ACCEPTED') tgt_count) AS target_registry_row_count
FROM tmp_src_m2_12_validation_run_context ctx
) x)
UNION ALL
(SELECT x.module1_run_id,
       x.edge_sequence,
       x.edge_code,
       x.target_node_code,
       x.expected_source_hash,
       x.observed_accepted_source_hash,
       x.observed_target_recorded_source_hash,
       x.source_gate_status,
       x.source_registry_row_count,
       x.target_registry_row_count,
       (x.observed_accepted_source_hash IS DISTINCT FROM x.expected_source_hash) AS source_hash_mismatch_flag,
       (x.observed_target_recorded_source_hash IS DISTINCT FROM x.expected_source_hash) AS target_hash_mismatch_flag,
       CASE WHEN x.source_registry_row_count=1
                  AND x.target_registry_row_count=1
                  AND x.source_gate_status='PASS'
                  AND x.observed_accepted_source_hash=x.expected_source_hash
                  AND x.observed_target_recorded_source_hash=x.expected_source_hash
            THEN 'PASS'::text ELSE 'FAIL'::text END AS edge_status
FROM (
SELECT ctx.module1_run_id,
       19::smallint AS edge_sequence,
       'M2_10_TO_M2_11'::text AS edge_code,
       'M2_11_STRATEGY_SIMULATION'::text AS target_node_code,
       '24fca7263a04397ebf21d30639f9069b'::text AS expected_source_hash,
       ((SELECT src.combined_set_hash::text FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_code='M2_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_CONSUMPTION' AND src.contract_version=1 AND src.contract_status='ACCEPTED'))::text AS observed_accepted_source_hash,
       ((SELECT tgt.source_m2_10_combined_hash::text FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION' AND tgt.contract_version=1 AND tgt.contract_status='ACCEPTED'))::text AS observed_target_recorded_source_hash,
       ((SELECT agr.result_status::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS' AND agr.review_version=1))::text AS source_gate_status,
       (SELECT count(*)::bigint FROM (SELECT src.combined_set_hash::text FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_code='M2_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_CONSUMPTION' AND src.contract_version=1 AND src.contract_status='ACCEPTED') src_count) AS source_registry_row_count,
       (SELECT count(*)::bigint FROM (SELECT tgt.source_m2_10_combined_hash::text FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION' AND tgt.contract_version=1 AND tgt.contract_status='ACCEPTED') tgt_count) AS target_registry_row_count
FROM tmp_src_m2_12_validation_run_context ctx
) x);



CREATE UNIQUE INDEX ux_tmp_eval_m2_12_validation_source_edges
    ON tmp_eval_m2_12_validation_source_edges(edge_sequence,edge_code);

ANALYZE tmp_eval_m2_12_validation_source_edges;


DO $m212_p223_hf12_source_graph_structure$
BEGIN
    IF NOT coalesce((SELECT count(*)=19
                            AND count(DISTINCT edge_sequence)=19
                            AND count(DISTINCT edge_code)=19
                            AND min(edge_sequence)=1
                            AND max(edge_sequence)=19
                       FROM tmp_eval_m2_12_validation_source_edges),false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 223 HF12 source-graph structural mismatch',
            DETAIL=format('rows=%s pass_rows=%s distinct_sequences=%s distinct_codes=%s',
                          (SELECT count(*) FROM tmp_eval_m2_12_validation_source_edges),
                          (SELECT count(*) FILTER (WHERE edge_status='PASS') FROM tmp_eval_m2_12_validation_source_edges),
                          (SELECT count(DISTINCT edge_sequence) FROM tmp_eval_m2_12_validation_source_edges),
                          (SELECT count(DISTINCT edge_code) FROM tmp_eval_m2_12_validation_source_edges));
    END IF;
END;
$m212_p223_hf12_source_graph_structure$;


/***************************************************************************************************
HF9 COMPLETE PHYSICAL STAGE-BOUNDARY RECONSTRUCTION
- 66 controls from msbf_ctl.run_evidence
- 3 M1.17 controls from msbf_ctl.m1_17_end_to_end_evidence_snapshot
- M2_3_POLICY_BOUNDARY from the accepted reason definition plus complete latest/archive marker coverage
***************************************************************************************************/
CREATE TEMP TABLE tmp_src_m2_12_stage_boundary_method ON COMMIT DROP AS
SELECT v.acceptance_evidence_code::text AS acceptance_evidence_code,
       v.acceptance_gate_id::text AS acceptance_gate_id,
       v.acceptance_gate_review_version::integer AS acceptance_gate_review_version,
       v.accepted_detail_actual_rows::integer AS accepted_detail_actual_rows,
       v.accepted_detail_expected_rows::integer AS accepted_detail_expected_rows,
       v.accepted_detail_report_authority_path::text AS accepted_detail_report_authority_path,
       v.accepted_detail_report_sha256::text AS accepted_detail_report_sha256,
       v.boundary_pattern_1::text AS boundary_pattern_1,
       v.boundary_pattern_2::text AS boundary_pattern_2,
       v.matrix_sequence::smallint AS matrix_sequence,
       ctx.module1_run_id::bigint AS module1_run_id,
       v.certification_node_sequence::smallint AS node_sequence,
       v.registry_relation::text AS registry_relation,
       v.report_exists_status::text AS report_exists_status,
       v.required_evidence_code_count::integer AS required_evidence_code_count,
       string_to_array(v.required_evidence_codes,'|')::text[] AS required_evidence_codes,
       v.stage_code::text AS stage_code
FROM (VALUES
    ('M1_17_ACCEPTANCE_SUMMARY'::text,'G2_M1_CONTRACT'::text,'1'::text,'0'::text,'0'::text,'19_M1_17/evidence/final/D24_Blocking_Stage_Violations.csv'::text,'4efd6882af220b190426e4a897ba1d1280c3d7af6174290d1d23af36b1fde300'::text,'M1_17_%BOUNDARY%'::text,'M1_17_%BLOCKING%'::text,'6'::text,'1'::text,'msbf_ctl.m1_17_g2_bundle_registry'::text,'PASS'::text,'3'::text,'M1_17_E2E_045_BLOCKING_ERRORS|M1_17_E2E_046_MODULE2_ROWS|M1_17_E2E_047_PII_COLUMNS'::text,'M1_17_G2_FOUNDATION'::text),
    ('M2_1_ACCEPTANCE_SUMMARY'::text,'M2_1_ELIGIBILITY_POLICY_ROUTING'::text,'1'::text,'0'::text,'0'::text,'20_M2_1/evidence/final/24_MSBF_M2_1_Eligibility_Policy_Gates_Decision_Routing_Foundations_Detail_Report_v0_2R7_Blocking_Errors_And_Stage_Boundary_Violations_20260730.csv'::text,'2a9b9b7b5354d529e19d981854baaffa782083ab5d0fdd2f21ef857f66329efb'::text,'M2_1_%BOUNDARY%'::text,'M2_1_%BLOCKING%'::text,'12'::text,'2'::text,'msbf_ctl.m2_1_strategy_contract_registry'::text,'PASS'::text,'3'::text,'M2_1_POS_109_ZERO_BLOCKING_ERRORS|M2_1_NEG_004_FINAL_OFFER_BOUNDARY|M2_1_NEG_005_ACQUISITION_CREDIT_BOUNDARY'::text,'M2_1_ELIGIBILITY_ROUTING'::text),
    ('M2_2_ACCEPTANCE_SUMMARY'::text,'M2_2_PRICING_STRUCTURE_COUNTEROFFER'::text,'1'::text,'0'::text,'0'::text,'21_M2_2/evidence/final/24_blocking_stage_boundary_violations.csv'::text,'d5e9991bf2fd0248204517bf0b947fa76af898e6d33da117d7f4229cf4ee85cb'::text,'M2_2_%BOUNDARY%'::text,'M2_2_%BLOCKING%'::text,'18'::text,'3'::text,'msbf_ctl.m2_2_pricing_structure_contract_registry'::text,'PASS'::text,'3'::text,'M2_2_POS_012_BOUNDARY_FLAGS|M2_2_NEG_002_FINAL_DECISION_BOUNDARY|M2_2_NEG_003_ACQUISITION_NONCREDIT_BOUNDARY'::text,'M2_2_PRICING_STRUCTURE'::text),
    ('M2_3_ACCEPTANCE_SUMMARY'::text,'M2_3_FINAL_OFFER_DECISION_AUTHORIZATION'::text,'1'::text,'0'::text,'0'::text,'22_M2_3/evidence/final/24_blocking_errors_and_stage_boundary_violations.csv'::text,'d5e9991bf2fd0248204517bf0b947fa76af898e6d33da117d7f4229cf4ee85cb'::text,'M2_3_%BOUNDARY%'::text,'M2_3_%BLOCKING%'::text,'24'::text,'4'::text,'msbf_ctl.m2_3_final_decision_contract_registry'::text,'PASS'::text,'6'::text,'M2_3_POLICY_BOUNDARY|M2_3_POS_011_OUTCOME_BOUNDARY_FLAGS|M2_3_POS_012_REASON_BOUNDARY_FLAGS|M2_3_NEG_002_BOOKING_BOUNDARY_FLAG|M2_3_NEG_003_EXTERNAL_NOTICE_BOUNDARY|M2_3_NEG_004_ADVERSE_ACTION_BOUNDARY'::text,'M2_3_FINAL_DECISION'::text),
    ('M2_4_ACCEPTANCE_SUMMARY'::text,'M2_4_BOOKING_FUNDING_PORTFOLIO_ACTIVATION'::text,'1'::text,'0'::text,'0'::text,'23_M2_4/evidence/final/24_blocking_errors_and_stage_boundary_violations.csv'::text,'d5e9991bf2fd0248204517bf0b947fa76af898e6d33da117d7f4229cf4ee85cb'::text,'M2_4_%BOUNDARY%'::text,'M2_4_%BLOCKING%'::text,'30'::text,'5'::text,'msbf_ctl.m2_4_portfolio_activation_contract_registry'::text,'PASS'::text,'4'::text,'M2_4_POS_060_OPERATIONAL_BOUNDARY_FLAGS|M2_4_NEG_002_REAL_FUNDS_POLICY_BOUNDARY|M2_4_NEG_003_EXTERNAL_NOTICE_POLICY_BOUNDARY|M2_4_NEG_004_ADVERSE_ACTION_POLICY_BOUNDARY'::text,'M2_4_PORTFOLIO_ACTIVATION'::text),
    ('M2_5_ACCEPTANCE_SUMMARY'::text,'M2_5_DAILY_REMITTANCE_EXPOSURE_PORTFOLIO_MONITORING'::text,'1'::text,'0'::text,'0'::text,'24_M2_5/evidence/raw/csv/MSBF_M2_5_Daily_Remittance_Exposure_&_Portfolio_Monitoring_Detail_Report_v0_2R5_Blocking_Errors_And_Stage_Boundary_Violations_20260801.csv'::text,'d5e9991bf2fd0248204517bf0b947fa76af898e6d33da117d7f4229cf4ee85cb'::text,'M2_5_%BOUNDARY%'::text,'M2_5_%BLOCKING%'::text,'36'::text,'6'::text,'msbf_ctl.m2_5_portfolio_monitoring_contract_registry'::text,'PASS'::text,'6'::text,'M2_5_POS_018_REASON_BOUNDARY_FLAGS|M2_5_NEG_002_REAL_DEBIT_BOUNDARY|M2_5_NEG_003_EXTERNAL_NOTICE_BOUNDARY|M2_5_NEG_004_ADVERSE_NOTICE_BOUNDARY|M2_5_NEG_005_WRITE_OFF_RESTRUCTURE_BOUNDARY|M2_5_NEG_006_MONITORING_ONLY_BOUNDARY'::text,'M2_5_DAILY_MONITORING'::text),
    ('M2_6_ACCEPTANCE_SUMMARY'::text,'M2_6_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY'::text,'1'::text,'0'::text,'0'::text,'25_M2_6/evidence/raw/csv/179_24_blocking_errors_and_stage_boundary_violations.csv'::text,'1721443af6fdf32b7ee5133ff02df3b36c199a2778815257010c2140977e7491'::text,'M2_6_%BOUNDARY%'::text,'M2_6_%BLOCKING%'::text,'42'::text,'7'::text,'msbf_ctl.m2_6_intervention_strategy_contract_registry'::text,'PASS'::text,'4'::text,'M2_6_NEG_017_PAYLOAD_BOUNDARY|M2_6_NEG_018_PAYLOAD_BOUNDARY|M2_6_NEG_019_PAYLOAD_BOUNDARY|M2_6_NEG_020_PAYLOAD_BOUNDARY'::text,'M2_6_INTERVENTION_STRATEGY'::text),
    ('M2_7_ACCEPTANCE_SUMMARY'::text,'M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP'::text,'1'::text,'0'::text,'0'::text,'26_M2_7/evidence/raw/csv/187_24_blocking_errors_and_stage_boundary_violations.csv'::text,'1721443af6fdf32b7ee5133ff02df3b36c199a2778815257010c2140977e7491'::text,'M2_7_%BOUNDARY%'::text,'M2_7_%BLOCKING%'::text,'48'::text,'8'::text,'msbf_ctl.m2_7_operational_activation_contract_registry'::text,'PASS'::text,'7'::text,'M2_7_POS_018_DEFINITION_BOUNDARY|M2_7_NEG_002_SIMULATED_SETUP_BOUNDARY|M2_7_NEG_003_REAL_ACCOUNT_BOUNDARY|M2_7_NEG_004_PAYMENT_CHANGE_BOUNDARY|M2_7_NEG_005_BANK_DATA_BOUNDARY|M2_7_NEG_006_ACH_NETWORK_BOUNDARY|M2_7_NEG_007_EXTERNAL_NOTICE_BOUNDARY'::text,'M2_7_OPERATIONAL_ACTIVATION'::text),
    ('M2_8_ACCEPTANCE_SUMMARY'::text,'M2_8_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONTROL'::text,'1'::text,'0'::text,'0'::text,'27_M2_8/evidence/raw/csv/195_24_blocking_errors_and_stage_boundary_violations.csv'::text,'1721443af6fdf32b7ee5133ff02df3b36c199a2778815257010c2140977e7491'::text,'M2_8_%BOUNDARY%'::text,'M2_8_%BLOCKING%'::text,'54'::text,'9'::text,'msbf_ctl.m2_8_servicing_execution_contract_registry'::text,'PASS'::text,'8'::text,'M2_8_POS_022_DEFINITION_BOUNDARY|M2_8_POS_089_PAYMENT_BOUNDARY|M2_8_POS_095_TRANSITION_BOUNDARY|M2_8_NEG_002_SIMULATION_BOUNDARY|M2_8_NEG_003_REAL_FUNDS_BOUNDARY|M2_8_NEG_004_BANK_DATA_BOUNDARY|M2_8_NEG_005_ACH_NETWORK_BOUNDARY|M2_8_NEG_006_PROCESSOR_CALL_BOUNDARY'::text,'M2_8_SERVICING_EXECUTION'::text),
    ('M2_9_ACCEPTANCE_SUMMARY'::text,'M2_9_PAYMENT_RECONCILIATION_EXCEPTION_RESOLUTION_ACCOUNT_STATE_CERTIFICATION'::text,'1'::text,'0'::text,'0'::text,'28_M2_9/evidence/raw/csv/203_24_blocking_errors_and_stage_boundary_violations.csv'::text,'1721443af6fdf32b7ee5133ff02df3b36c199a2778815257010c2140977e7491'::text,'M2_9_%BOUNDARY%'::text,'M2_9_%BLOCKING%'::text,'60'::text,'10'::text,'msbf_ctl.m2_9_reconciliation_certification_contract_registry'::text,'PASS'::text,'10'::text,'M2_9_POS_021_DEFINITION_BOUNDARY|M2_9_POS_069_PAYMENT_RECON_BOUNDARY|M2_9_POS_070_EXCEPTION_BOUNDARY|M2_9_POS_087_ACCOUNT_BOUNDARY|M2_9_POS_095_CERTIFICATION_HASH_BOUNDARY|M2_9_NEG_002_CERTIFICATION_BOUNDARY|M2_9_NEG_003_REAL_FUNDS_BOUNDARY|M2_9_NEG_004_BANK_DATA_BOUNDARY|M2_9_NEG_005_NETWORK_BOUNDARY|M2_9_NEG_006_PROCESSOR_BOUNDARY'::text,'M2_9_RECONCILIATION_CERTIFICATION'::text),
    ('M2_10_ACCEPTANCE_SUMMARY'::text,'M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS'::text,'1'::text,'0'::text,'0'::text,'29_M2_10/evidence/raw/csv/211_24_blocking_errors_and_stage_boundary_violations.csv'::text,'1721443af6fdf32b7ee5133ff02df3b36c199a2778815257010c2140977e7491'::text,'M2_10_%BOUNDARY%'::text,'M2_10_%BLOCKING%'::text,'66'::text,'11'::text,'msbf_ctl.m2_10_portfolio_analytics_contract_registry'::text,'PASS'::text,'10'::text,'M2_10_POS_010_POLICY_BOUNDARY|M2_10_POS_021_REASON_BOUNDARY|M2_10_POS_056_PERFORMANCE_BOUNDARY_DECISION|M2_10_POS_057_PERFORMANCE_BOUNDARY_SYSTEM|M2_10_POS_058_PERFORMANCE_BOUNDARY_CONTACT|M2_10_NEG_002_ANALYTICS_BOUNDARY|M2_10_NEG_003_DECISION_BOUNDARY|M2_10_NEG_004_FUNDS_BOUNDARY|M2_10_NEG_005_SYSTEM_BOUNDARY|M2_10_NEG_006_CONTACT_BOUNDARY'::text,'M2_10_PORTFOLIO_ANALYTICS'::text),
    ('M2_11_ACCEPTANCE_SUMMARY'::text,'M2_11_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION'::text,'1'::text,'0'::text,'0'::text,'30_M2_11/10_live_execution_evidence/exports/MSBF_M2_11_Portfolio_Optimization_&_Strategy_Simulation_Detail_Report_v1_Blocking_And_Stage_Boundary_Violations_20260806.csv'::text,'6fe5fce149762a76e6b230832834471ba08efec6a7b2621fbe818a3c74025a1c'::text,'M2_11_%BOUNDARY%'::text,'M2_11_%BLOCKING%'::text,'72'::text,'12'::text,'msbf_ctl.m2_11_portfolio_strategy_contract_registry'::text,'PASS'::text,'6'::text,'M2_11_POS_009_POLICY_BOUNDARY|M2_11_POS_036_CONSTRAINT_BLOCKING|M2_11_POS_120_CANONICAL_BOUNDARY|M2_11_NEG_017_PRODUCTION_ACTION|M2_11_NEG_018_EXTERNAL_BEHAVIOR|M2_11_NEG_020_UNAUTHORIZED_STAGE_SOURCE'::text,'M2_11_STRATEGY_SIMULATION'::text)) AS v(acceptance_evidence_code,acceptance_gate_id,acceptance_gate_review_version,accepted_detail_actual_rows,accepted_detail_expected_rows,accepted_detail_report_authority_path,accepted_detail_report_sha256,boundary_pattern_1,boundary_pattern_2,matrix_sequence,certification_node_sequence,registry_relation,report_exists_status,required_evidence_code_count,required_evidence_codes,stage_code)
CROSS JOIN tmp_src_m2_12_validation_run_context ctx;


CREATE TEMP TABLE tmp_cert_m2_12_stage_boundary_observation_base ON COMMIT DROP AS
WITH generic_required_evidence AS
(
    SELECT
        sbm.module1_run_id::bigint AS module1_run_id,
        sbm.node_sequence::smallint AS node_sequence,
        sbm.stage_code::text AS stage_code,
        e.evidence_code::text AS evidence_code,
        e.segment_key::text AS segment_key,
        e.metric_name::text AS metric_name,
        coalesce(e.metric_value_text,e.metric_value_numeric::text)::text AS observed_value_text,
        NULL::text AS expected_value_text,
        e.status::text AS evidence_status,
        'msbf_ctl.run_evidence'::text AS source_relation,
        md5(concat_ws('|',e.evidence_code,e.segment_key,e.metric_name,
                      coalesce(e.metric_value_text,e.metric_value_numeric::text),e.status))::text AS source_row_hash
    FROM tmp_src_m2_12_stage_boundary_method sbm
    JOIN msbf_ctl.run_evidence e
      ON e.run_id=sbm.module1_run_id
     AND e.evidence_code=ANY(sbm.required_evidence_codes)
    WHERE sbm.node_sequence<>1
      AND NOT (sbm.node_sequence=4 AND e.evidence_code='M2_3_POLICY_BOUNDARY')
),
m117_required_evidence AS
(
    SELECT
        sbm.module1_run_id::bigint AS module1_run_id,
        sbm.node_sequence::smallint AS node_sequence,
        sbm.stage_code::text AS stage_code,
        e.evidence_code::text AS evidence_code,
        e.evidence_family::text AS segment_key,
        e.metric_name::text AS metric_name,
        e.observed_value_text::text AS observed_value_text,
        e.expected_value_text::text AS expected_value_text,
        CASE
            WHEN e.evidence_status='PASS'
             AND e.observed_value_text IS NOT DISTINCT FROM e.expected_value_text
             AND e.row_hash ~ '^[0-9a-f]{32}$'
            THEN 'PASS' ELSE 'FAIL'
        END::text AS evidence_status,
        'msbf_ctl.m1_17_end_to_end_evidence_snapshot'::text AS source_relation,
        e.row_hash::text AS source_row_hash
    FROM tmp_src_m2_12_stage_boundary_method sbm
    JOIN msbf_ctl.m1_17_end_to_end_evidence_snapshot e
      ON e.module1_run_id=sbm.module1_run_id
     AND e.evidence_code=ANY(sbm.required_evidence_codes)
    WHERE sbm.node_sequence=1
),
m23_boundary_stats AS
(
    SELECT
        sbm.module1_run_id::bigint AS module1_run_id,
        sbm.node_sequence::smallint AS node_sequence,
        sbm.stage_code::text AS stage_code,
        (SELECT count(*)::integer
           FROM msbf_ctl.m2_3_final_decision_contract_registry r
          WHERE r.module1_run_id=sbm.module1_run_id
            AND r.contract_code='M2_FINAL_OFFER_DECISION_CONSUMPTION'
            AND r.contract_version=1
            AND r.contract_status='ACCEPTED') AS registry_rows,
        coalesce((SELECT min(r.decision_latest_rows)::bigint
                    FROM msbf_ctl.m2_3_final_decision_contract_registry r
                   WHERE r.module1_run_id=sbm.module1_run_id
                     AND r.contract_code='M2_FINAL_OFFER_DECISION_CONSUMPTION'
                     AND r.contract_version=1
                     AND r.contract_status='ACCEPTED'),-1::bigint) AS expected_latest_rows,
        coalesce((SELECT min(r.decision_archive_rows)::bigint
                    FROM msbf_ctl.m2_3_final_decision_contract_registry r
                   WHERE r.module1_run_id=sbm.module1_run_id
                     AND r.contract_code='M2_FINAL_OFFER_DECISION_CONSUMPTION'
                     AND r.contract_version=1
                     AND r.contract_status='ACCEPTED'),-1::bigint) AS expected_archive_rows,
        (SELECT count(*)::integer
           FROM msbf_m2.final_decision_reason_definition d
          WHERE d.module1_run_id=sbm.module1_run_id
            AND d.decision_reason_code='M2_3_POLICY_BOUNDARY') AS reason_definition_rows,
        (SELECT count(*)::integer
           FROM msbf_m2.final_decision_reason_definition d
          WHERE d.module1_run_id=sbm.module1_run_id
            AND d.decision_reason_code='M2_3_POLICY_BOUNDARY'
            AND d.mapped_decision_outcome_code='FINAL_OFFER_AUTHORIZED'
            AND d.production_adverse_action_notice_flag=false
            AND d.reason_status='APPROVED'
            AND d.row_hash ~ '^[0-9a-f]{32}$') AS approved_reason_definition_rows,
        (SELECT count(*)::bigint
           FROM msbf_m2.application_final_offer_decision_latest l
          WHERE l.module1_run_id=sbm.module1_run_id
            AND l.contract_code='M2_FINAL_OFFER_DECISION_CONSUMPTION'
            AND l.contract_version=1) AS observed_latest_rows,
        (SELECT count(*)::bigint
           FROM msbf_m2.application_final_offer_decision_latest l
          WHERE l.module1_run_id=sbm.module1_run_id
            AND l.contract_code='M2_FINAL_OFFER_DECISION_CONSUMPTION'
            AND l.contract_version=1
            AND l.decision_reason_codes ? 'M2_3_POLICY_BOUNDARY') AS latest_marker_rows,
        (SELECT count(*)::bigint
           FROM msbf_m2.application_final_offer_decision_archive a
          WHERE a.module1_run_id=sbm.module1_run_id
            AND a.contract_code='M2_FINAL_OFFER_DECISION_CONSUMPTION'
            AND a.contract_version=1) AS observed_archive_rows,
        (SELECT count(*)::bigint
           FROM msbf_m2.application_final_offer_decision_archive a
          WHERE a.module1_run_id=sbm.module1_run_id
            AND a.contract_code='M2_FINAL_OFFER_DECISION_CONSUMPTION'
            AND a.contract_version=1
            AND a.decision_reason_codes ? 'M2_3_POLICY_BOUNDARY') AS archive_marker_rows
    FROM tmp_src_m2_12_stage_boundary_method sbm
    WHERE sbm.node_sequence=4
),
m23_boundary_evidence AS
(
    SELECT
        s.module1_run_id::bigint AS module1_run_id,
        s.node_sequence::smallint AS node_sequence,
        s.stage_code::text AS stage_code,
        'M2_3_POLICY_BOUNDARY'::text AS evidence_code,
        'PHYSICAL_BOUNDARY'::text AS segment_key,
        'M2_3_POLICY_BOUNDARY_PHYSICAL_RECONCILIATION'::text AS metric_name,
        format('registry=%s|reason=%s|approved_reason=%s|latest_expected=%s|latest_observed=%s|latest_marker=%s|archive_expected=%s|archive_observed=%s|archive_marker=%s',
               s.registry_rows,s.reason_definition_rows,s.approved_reason_definition_rows,
               s.expected_latest_rows,s.observed_latest_rows,s.latest_marker_rows,
               s.expected_archive_rows,s.observed_archive_rows,s.archive_marker_rows)::text AS observed_value_text,
        'registry=1|reason=1|approved_reason=1|latest_expected=1500|latest_observed=1500|latest_marker=1500|archive_expected=1500|archive_observed=1500|archive_marker=1500'::text AS expected_value_text,
        CASE
            WHEN s.registry_rows=1
             AND s.reason_definition_rows=1
             AND s.approved_reason_definition_rows=1
             AND s.expected_latest_rows=1500
             AND s.observed_latest_rows=s.expected_latest_rows
             AND s.latest_marker_rows=s.expected_latest_rows
             AND s.expected_archive_rows=1500
             AND s.observed_archive_rows=s.expected_archive_rows
             AND s.archive_marker_rows=s.expected_archive_rows
            THEN 'PASS' ELSE 'FAIL'
        END::text AS evidence_status,
        'msbf_ctl.m2_3_final_decision_contract_registry+msbf_m2.final_decision_reason_definition+msbf_m2.application_final_offer_decision_latest+msbf_m2.application_final_offer_decision_archive'::text AS source_relation,
        md5(concat_ws('|',s.registry_rows::text,s.reason_definition_rows::text,s.approved_reason_definition_rows::text,
                      s.expected_latest_rows::text,s.observed_latest_rows::text,s.latest_marker_rows::text,
                      s.expected_archive_rows::text,s.observed_archive_rows::text,s.archive_marker_rows::text))::text AS source_row_hash
    FROM m23_boundary_stats s
),
normalized_required_evidence AS
(
    SELECT * FROM generic_required_evidence
    UNION ALL
    SELECT * FROM m117_required_evidence
    UNION ALL
    SELECT * FROM m23_boundary_evidence
),
acceptance_summary_stats AS
(
    SELECT
        sbm.module1_run_id,
        sbm.node_sequence,
        (SELECT count(*)::integer
           FROM msbf_ctl.run_evidence e
          WHERE e.run_id=sbm.module1_run_id
            AND e.evidence_code=sbm.acceptance_evidence_code) AS acceptance_summary_rows,
        (SELECT count(*)::integer
           FROM msbf_ctl.run_evidence e
          WHERE e.run_id=sbm.module1_run_id
            AND e.evidence_code=sbm.acceptance_evidence_code
            AND e.status='PASS') AS acceptance_summary_pass_rows
    FROM tmp_src_m2_12_stage_boundary_method sbm
),
normalized_stats AS
(
    SELECT
        n.module1_run_id,
        n.node_sequence,
        count(*)::integer AS physical_required_evidence_rows,
        count(DISTINCT n.evidence_code)::integer AS observed_required_evidence_rows,
        (count(*)-count(DISTINCT n.evidence_code))::integer AS duplicate_required_evidence_rows,
        count(*) FILTER (WHERE n.evidence_status<>'PASS')::integer AS nonpass_evidence_rows,
        coalesce(string_agg(n.evidence_code,'|' ORDER BY n.evidence_code)
                 FILTER (WHERE n.evidence_status<>'PASS'),'')::text AS nonpass_evidence_codes,
        string_agg(DISTINCT n.source_relation,'|' ORDER BY n.source_relation)::text AS source_relation_set,
        md5(coalesce(string_agg(concat_ws('|',n.evidence_code,n.segment_key,n.metric_name,
                                          n.observed_value_text,n.expected_value_text,n.evidence_status,
                                          n.source_relation,n.source_row_hash),
                                '|' ORDER BY n.evidence_code,n.source_relation,n.segment_key,n.metric_name),''))::text AS source_evidence_row_hash
    FROM normalized_required_evidence n
    GROUP BY n.module1_run_id,n.node_sequence
),
missing_stats AS
(
    SELECT
        sbm.module1_run_id,
        sbm.node_sequence,
        string_agg(req.evidence_code,'|' ORDER BY req.evidence_code)::text AS missing_required_evidence_codes
    FROM tmp_src_m2_12_stage_boundary_method sbm
    CROSS JOIN LATERAL unnest(sbm.required_evidence_codes) AS req(evidence_code)
    WHERE NOT EXISTS
          (SELECT 1
             FROM normalized_required_evidence n
            WHERE n.module1_run_id=sbm.module1_run_id
              AND n.node_sequence=sbm.node_sequence
              AND n.evidence_code=req.evidence_code)
    GROUP BY sbm.module1_run_id,sbm.node_sequence
),
violation_evidence AS
(
    SELECT DISTINCT
        sbm.module1_run_id,
        sbm.node_sequence,
        e.evidence_code::text AS evidence_code,
        e.status::text AS evidence_status,
        'msbf_ctl.run_evidence'::text AS source_relation
    FROM tmp_src_m2_12_stage_boundary_method sbm
    JOIN msbf_ctl.run_evidence e
      ON e.run_id=sbm.module1_run_id
     AND (e.evidence_code LIKE sbm.boundary_pattern_1 OR e.evidence_code LIKE sbm.boundary_pattern_2)
    WHERE e.status<>'PASS'
    UNION ALL
    SELECT DISTINCT
        sbm.module1_run_id,
        sbm.node_sequence,
        e.evidence_code::text,
        e.evidence_status::text,
        'msbf_ctl.m1_17_end_to_end_evidence_snapshot'::text
    FROM tmp_src_m2_12_stage_boundary_method sbm
    JOIN msbf_ctl.m1_17_end_to_end_evidence_snapshot e
      ON e.module1_run_id=sbm.module1_run_id
     AND (e.evidence_code LIKE sbm.boundary_pattern_1 OR e.evidence_code LIKE sbm.boundary_pattern_2)
    WHERE sbm.node_sequence=1
      AND e.evidence_status<>'PASS'
    UNION ALL
    SELECT
        m.module1_run_id,
        m.node_sequence,
        m.evidence_code,
        m.evidence_status,
        m.source_relation
    FROM m23_boundary_evidence m
    WHERE m.evidence_status<>'PASS'
),
violation_stats AS
(
    SELECT
        v.module1_run_id,
        v.node_sequence,
        count(DISTINCT (v.source_relation,v.evidence_code))::integer AS violation_rows,
        string_agg(DISTINCT v.source_relation||':'||v.evidence_code,'|' ORDER BY v.source_relation||':'||v.evidence_code)::text AS violation_evidence_codes
    FROM violation_evidence v
    GROUP BY v.module1_run_id,v.node_sequence
)
SELECT
       sbm.accepted_detail_actual_rows::integer AS accepted_detail_actual_rows,
       (sbm.report_exists_status='PASS')::boolean AS accepted_detail_report_exists_flag,
       sbm.accepted_detail_report_sha256::text AS accepted_detail_report_sha256,
       ast.acceptance_summary_rows::integer AS acceptance_summary_rows,
       ast.acceptance_summary_pass_rows::integer AS acceptance_summary_pass_rows,
       (ast.acceptance_summary_rows=1
        AND ast.acceptance_summary_pass_rows=1
        AND coalesce(ns.physical_required_evidence_rows,0)=sbm.required_evidence_code_count
        AND coalesce(ns.observed_required_evidence_rows,0)=sbm.required_evidence_code_count
        AND coalesce(ns.duplicate_required_evidence_rows,0)=0
        AND coalesce(ms.missing_required_evidence_codes,'')='')::boolean AS governing_source_present_flag,
       sbm.matrix_sequence::smallint AS matrix_sequence,
       coalesce(ms.missing_required_evidence_codes,'')::text AS missing_required_evidence_codes,
       sbm.module1_run_id::bigint AS module1_run_id,
       sbm.node_sequence::smallint AS node_sequence,
       coalesce(ns.nonpass_evidence_codes,'')::text AS nonpass_evidence_codes,
       coalesce(ns.nonpass_evidence_rows,0)::integer AS nonpass_evidence_rows,
       coalesce(ns.observed_required_evidence_rows,0)::integer AS observed_required_evidence_rows,
       coalesce(ns.physical_required_evidence_rows,0)::integer AS physical_required_evidence_rows,
       coalesce(ns.duplicate_required_evidence_rows,0)::integer AS duplicate_required_evidence_rows,
       sbm.required_evidence_code_count::integer AS required_evidence_rows,
       coalesce(ns.source_evidence_row_hash,md5(''))::text AS source_evidence_row_hash,
       coalesce(ns.source_relation_set,'')::text AS source_relation_set,
       sbm.stage_code::text AS stage_code,
       coalesce(vs.violation_evidence_codes,'')::text AS violation_evidence_codes,
       coalesce(vs.violation_rows,0)::integer AS violation_rows
FROM tmp_src_m2_12_validation_run_context ctx
JOIN tmp_src_m2_12_stage_boundary_method sbm
  ON sbm.module1_run_id=ctx.module1_run_id
JOIN acceptance_summary_stats ast
  ON ast.module1_run_id=sbm.module1_run_id
 AND ast.node_sequence=sbm.node_sequence
LEFT JOIN normalized_stats ns
  ON ns.module1_run_id=sbm.module1_run_id
 AND ns.node_sequence=sbm.node_sequence
LEFT JOIN missing_stats ms
  ON ms.module1_run_id=sbm.module1_run_id
 AND ms.node_sequence=sbm.node_sequence
LEFT JOIN violation_stats vs
  ON vs.module1_run_id=sbm.module1_run_id
 AND vs.node_sequence=sbm.node_sequence;


DO $m212_p223_hf12_stage_boundary_base_structure_assert$
BEGIN
    IF NOT coalesce(
        (SELECT count(*)=12
             AND count(DISTINCT (module1_run_id,matrix_sequence))=12
             AND count(DISTINCT node_sequence)=12
             AND min(node_sequence)=1
             AND max(node_sequence)=12
             AND sum(required_evidence_rows)=70
         FROM tmp_cert_m2_12_stage_boundary_observation_base),false)
    THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 223 HF12 stage-boundary observation-base structural mismatch',
            DETAIL=format('rows=%s distinct_matrix=%s distinct_nodes=%s required_controls=%s',
                          (SELECT count(*) FROM tmp_cert_m2_12_stage_boundary_observation_base),
                          (SELECT count(DISTINCT (module1_run_id,matrix_sequence)) FROM tmp_cert_m2_12_stage_boundary_observation_base),
                          (SELECT count(DISTINCT node_sequence) FROM tmp_cert_m2_12_stage_boundary_observation_base),
                          (SELECT coalesce(sum(required_evidence_rows),0) FROM tmp_cert_m2_12_stage_boundary_observation_base));
    END IF;
END;
$m212_p223_hf12_stage_boundary_base_structure_assert$;


CREATE TEMP TABLE tmp_cert_m2_12_stage_boundary_observation ON COMMIT DROP AS
SELECT
       CASE
           WHEN sbb.governing_source_present_flag
            AND sbb.accepted_detail_report_exists_flag
            AND sbb.accepted_detail_actual_rows=0
            AND sbb.acceptance_summary_rows=1
            AND sbb.acceptance_summary_pass_rows=1
            AND sbb.physical_required_evidence_rows=sbb.required_evidence_rows
            AND sbb.observed_required_evidence_rows=sbb.required_evidence_rows
            AND sbb.duplicate_required_evidence_rows=0
            AND sbb.missing_required_evidence_codes=''
            AND sbb.nonpass_evidence_rows=0
            AND sbb.violation_rows=0
           THEN 'PASS' ELSE 'FAIL'
       END::text AS certification_status,
       sbb.governing_source_present_flag::boolean AS governing_source_present_flag,
       sbb.matrix_sequence::smallint AS matrix_sequence,
       sbb.module1_run_id::bigint AS module1_run_id,
       sbb.node_sequence::smallint AS node_sequence,
       sbb.nonpass_evidence_rows::integer AS nonpass_evidence_rows,
       format('required=%s; physical=%s; distinct=%s; duplicates=%s; missing=%s; nonpass=%s; violations=%s; acceptance=%s/%s; report_rows=%s',
              sbb.required_evidence_rows,sbb.physical_required_evidence_rows,sbb.observed_required_evidence_rows,
              sbb.duplicate_required_evidence_rows,coalesce(nullif(sbb.missing_required_evidence_codes,''),'<NONE>'),
              sbb.nonpass_evidence_rows,sbb.violation_rows,sbb.acceptance_summary_pass_rows,sbb.acceptance_summary_rows,
              sbb.accepted_detail_actual_rows)::text AS observed_count_or_identity,
       md5(concat_ws('|',sbb.stage_code,sbb.accepted_detail_report_sha256,
                     sbb.acceptance_summary_rows::text,sbb.acceptance_summary_pass_rows::text,
                     sbb.required_evidence_rows::text,sbb.physical_required_evidence_rows::text,
                     sbb.observed_required_evidence_rows::text,sbb.duplicate_required_evidence_rows::text,
                     sbb.missing_required_evidence_codes,sbb.nonpass_evidence_rows::text,sbb.nonpass_evidence_codes,
                     sbb.violation_rows::text,sbb.violation_evidence_codes,sbb.source_relation_set,
                     sbb.source_evidence_row_hash))::text AS observed_hash,
       sbb.observed_required_evidence_rows::integer AS observed_required_evidence_rows,
       CASE
           WHEN sbb.governing_source_present_flag
            AND sbb.accepted_detail_report_exists_flag
            AND sbb.accepted_detail_actual_rows=0
            AND sbb.acceptance_summary_rows=1
            AND sbb.acceptance_summary_pass_rows=1
            AND sbb.physical_required_evidence_rows=sbb.required_evidence_rows
            AND sbb.observed_required_evidence_rows=sbb.required_evidence_rows
            AND sbb.duplicate_required_evidence_rows=0
            AND sbb.missing_required_evidence_codes=''
            AND sbb.nonpass_evidence_rows=0
            AND sbb.violation_rows=0
           THEN 'PASS' ELSE 'FAIL'
       END::text AS observed_status,
       sbb.required_evidence_rows::integer AS required_evidence_rows,
       sbb.source_evidence_row_hash::text AS source_evidence_row_hash,
       sbb.stage_code::text AS stage_code,
       sbb.violation_rows::integer AS violation_rows,
       sbb.acceptance_summary_rows::integer AS acceptance_summary_rows,
       sbb.acceptance_summary_pass_rows::integer AS acceptance_summary_pass_rows,
       sbb.physical_required_evidence_rows::integer AS physical_required_evidence_rows,
       sbb.duplicate_required_evidence_rows::integer AS duplicate_required_evidence_rows,
       sbb.missing_required_evidence_codes::text AS missing_required_evidence_codes,
       sbb.nonpass_evidence_codes::text AS nonpass_evidence_codes,
       sbb.violation_evidence_codes::text AS violation_evidence_codes,
       sbb.source_relation_set::text AS source_relation_set
FROM tmp_src_m2_12_validation_run_context ctx
JOIN tmp_cert_m2_12_stage_boundary_observation_base sbb
  ON sbb.module1_run_id=ctx.module1_run_id;



CREATE UNIQUE INDEX ux_tmp_cert_m2_12_stage_boundary_observation
    ON tmp_cert_m2_12_stage_boundary_observation(module1_run_id,node_sequence,stage_code);

ANALYZE tmp_cert_m2_12_stage_boundary_observation;

/* HF12 pre-write deterministic reconstruction: exact successfully executed Program 222 HF9 preimages. */
CREATE TEMP TABLE tmp_hash_m2_12_validation_reconciliation ON COMMIT DROP AS
SELECT
       p.module1_run_id::bigint AS module1_run_id,
       p.family_count_mismatch_count::bigint AS family_count_mismatch_count,
       p.row_hash_mismatch_count::bigint AS row_hash_mismatch_count,
       p.set_hash_mismatch_count::bigint AS set_hash_mismatch_count,
       p.contract_hash_mismatch_count::integer AS contract_hash_mismatch_count,
       p.combined_hash_mismatch_count::integer AS combined_hash_mismatch_count,
       p.sequence_state_mismatch_count::integer AS sequence_state_mismatch_count,
       p.canonical_families::integer AS canonical_families,
       p.canonical_entities::integer AS canonical_entities,
       p.total_mismatch_count::bigint AS total_mismatch_count,
       CASE WHEN p.total_mismatch_count=0 THEN 'PASS'::text ELSE 'FAIL'::text END AS reconciliation_status
FROM (
WITH row_detail AS ((SELECT 'POLICY'::text AS family_code, 1::bigint AS expected_rows, count(*)::bigint AS observed_rows, (count(*)<>1)::integer AS family_count_mismatch_count, count(*) FILTER (WHERE t.row_hash IS DISTINCT FROM md5((to_jsonb(t)-'policy_profile_id'-'row_hash'-'created_at'-'updated_at')::text))::bigint AS row_hash_mismatch_count FROM msbf_ctl.m2_12_policy_profile t JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id) UNION ALL (SELECT 'STAGE_CERTIFICATION'::text AS family_code, 12::bigint AS expected_rows, count(*)::bigint AS observed_rows, (count(*)<>12)::integer AS family_count_mismatch_count, count(*) FILTER (WHERE t.row_hash IS DISTINCT FROM md5((to_jsonb(t)-'row_hash'-'created_at')::text))::bigint AS row_hash_mismatch_count FROM msbf_m2.module2_stage_certification_snapshot t JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id) UNION ALL (SELECT 'CONTRACT_COMPONENT'::text AS family_code, 13::bigint AS expected_rows, count(*)::bigint AS observed_rows, (count(*)<>13)::integer AS family_count_mismatch_count, count(*) FILTER (WHERE t.row_hash IS DISTINCT FROM md5((to_jsonb(t)-'row_hash'-'created_at')::text))::bigint AS row_hash_mismatch_count FROM msbf_m2.module2_contract_component_snapshot t JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id) UNION ALL (SELECT 'EVIDENCE_CERTIFICATION'::text AS family_code, 72::bigint AS expected_rows, count(*)::bigint AS observed_rows, (count(*)<>72)::integer AS family_count_mismatch_count, count(*) FILTER (WHERE t.row_hash IS DISTINCT FROM md5((to_jsonb(t)-'row_hash'-'created_at')::text))::bigint AS row_hash_mismatch_count FROM msbf_m2.module2_evidence_certification_snapshot t JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id) UNION ALL (SELECT 'CONTRACT_REPRODUCTION'::text AS family_code, 13::bigint AS expected_rows, count(*)::bigint AS observed_rows, (count(*)<>13)::integer AS family_count_mismatch_count, count(*) FILTER (WHERE t.row_hash IS DISTINCT FROM md5((to_jsonb(t)-'row_hash'-'created_at')::text))::bigint AS row_hash_mismatch_count FROM msbf_m2.module2_contract_reproduction_snapshot t JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id) UNION ALL (SELECT 'CAPABILITY_COVERAGE'::text AS family_code, 20::bigint AS expected_rows, count(*)::bigint AS observed_rows, (count(*)<>20)::integer AS family_count_mismatch_count, count(*) FILTER (WHERE t.row_hash IS DISTINCT FROM md5((to_jsonb(t)-'row_hash'-'created_at')::text))::bigint AS row_hash_mismatch_count FROM msbf_m2.module2_capability_coverage_snapshot t JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id) UNION ALL (SELECT 'LATEST'::text AS family_code, 1::bigint AS expected_rows, count(*)::bigint AS observed_rows, (count(*)<>1)::integer AS family_count_mismatch_count, count(*) FILTER (WHERE t.row_hash IS DISTINCT FROM md5((to_jsonb(t)-'row_hash'-'created_at')::text))::bigint AS row_hash_mismatch_count FROM msbf_ctl.m2_12_g3_bundle_latest t JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id) UNION ALL (SELECT 'ARCHIVE'::text AS family_code, 1::bigint AS expected_rows, count(*)::bigint AS observed_rows, (count(*)<>1)::integer AS family_count_mismatch_count, count(*) FILTER (WHERE t.archive_row_hash IS DISTINCT FROM md5((to_jsonb(t)-'archive_id'-'archive_row_hash'-'created_at')::text))::bigint AS row_hash_mismatch_count FROM msbf_ctl.m2_12_g3_bundle_archive t JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id) UNION ALL (SELECT 'REGISTRY'::text AS family_code, 1::bigint AS expected_rows, count(*)::bigint AS observed_rows, (count(*)<>1)::integer AS family_count_mismatch_count, count(*) FILTER (WHERE t.row_hash IS DISTINCT FROM md5((to_jsonb(t)-'registry_id'-'contract_status'-'generated_at'-'validated_at'-'accepted_at'-'created_at'-'updated_at'-'row_hash'-'policy_set_hash'-'stage_certification_set_hash'-'contract_component_set_hash'-'evidence_certification_set_hash'-'contract_reproduction_set_hash'-'capability_coverage_set_hash'-'latest_set_hash'-'archive_set_hash'-'registry_set_hash'-'contract_set_hash'-'combined_set_hash')::text))::bigint AS row_hash_mismatch_count FROM msbf_ctl.m2_12_g3_bundle_registry t JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id)),
rowd AS (SELECT sum(family_count_mismatch_count)::bigint family_count_mismatch_count,sum(row_hash_mismatch_count)::bigint row_hash_mismatch_count FROM row_detail),
set_detail AS ((SELECT 'POLICY'::text AS family_code, md5(string_agg(concat_ws('|',t.policy_code::text,t.policy_version::text,t.row_hash::text),'|' ORDER BY t.policy_code, t.policy_version))::text AS reconstructed_set_hash, r.policy_set_hash::text AS stored_set_hash, (md5(string_agg(concat_ws('|',t.policy_code::text,t.policy_version::text,t.row_hash::text),'|' ORDER BY t.policy_code, t.policy_version)) IS DISTINCT FROM r.policy_set_hash)::integer AS set_hash_mismatch_count FROM msbf_ctl.m2_12_policy_profile t JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1 GROUP BY r.policy_set_hash) UNION ALL (SELECT 'STAGE_CERTIFICATION'::text AS family_code, md5(string_agg(concat_ws('|',t.certification_node_sequence::text,t.stage_code::text,t.row_hash::text),'|' ORDER BY t.certification_node_sequence, t.stage_code))::text AS reconstructed_set_hash, r.stage_certification_set_hash::text AS stored_set_hash, (md5(string_agg(concat_ws('|',t.certification_node_sequence::text,t.stage_code::text,t.row_hash::text),'|' ORDER BY t.certification_node_sequence, t.stage_code)) IS DISTINCT FROM r.stage_certification_set_hash)::integer AS set_hash_mismatch_count FROM msbf_m2.module2_stage_certification_snapshot t JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1 GROUP BY r.stage_certification_set_hash) UNION ALL (SELECT 'CONTRACT_COMPONENT'::text AS family_code, md5(string_agg(concat_ws('|',t.component_sequence::text,t.component_contract_code::text,t.contract_version::text,t.row_hash::text),'|' ORDER BY t.component_sequence, t.component_contract_code, t.contract_version))::text AS reconstructed_set_hash, r.contract_component_set_hash::text AS stored_set_hash, (md5(string_agg(concat_ws('|',t.component_sequence::text,t.component_contract_code::text,t.contract_version::text,t.row_hash::text),'|' ORDER BY t.component_sequence, t.component_contract_code, t.contract_version)) IS DISTINCT FROM r.contract_component_set_hash)::integer AS set_hash_mismatch_count FROM msbf_m2.module2_contract_component_snapshot t JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1 GROUP BY r.contract_component_set_hash) UNION ALL (SELECT 'EVIDENCE_CERTIFICATION'::text AS family_code, md5(string_agg(concat_ws('|',t.node_sequence::text,t.evidence_family_sequence::text,t.row_hash::text),'|' ORDER BY t.node_sequence, t.evidence_family_sequence))::text AS reconstructed_set_hash, r.evidence_certification_set_hash::text AS stored_set_hash, (md5(string_agg(concat_ws('|',t.node_sequence::text,t.evidence_family_sequence::text,t.row_hash::text),'|' ORDER BY t.node_sequence, t.evidence_family_sequence)) IS DISTINCT FROM r.evidence_certification_set_hash)::integer AS set_hash_mismatch_count FROM msbf_m2.module2_evidence_certification_snapshot t JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1 GROUP BY r.evidence_certification_set_hash) UNION ALL (SELECT 'CONTRACT_REPRODUCTION'::text AS family_code, md5(string_agg(concat_ws('|',t.component_sequence::text,t.component_contract_code::text,t.contract_version::text,t.row_hash::text),'|' ORDER BY t.component_sequence, t.component_contract_code, t.contract_version))::text AS reconstructed_set_hash, r.contract_reproduction_set_hash::text AS stored_set_hash, (md5(string_agg(concat_ws('|',t.component_sequence::text,t.component_contract_code::text,t.contract_version::text,t.row_hash::text),'|' ORDER BY t.component_sequence, t.component_contract_code, t.contract_version)) IS DISTINCT FROM r.contract_reproduction_set_hash)::integer AS set_hash_mismatch_count FROM msbf_m2.module2_contract_reproduction_snapshot t JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1 GROUP BY r.contract_reproduction_set_hash) UNION ALL (SELECT 'CAPABILITY_COVERAGE'::text AS family_code, md5(string_agg(concat_ws('|',t.capability_sequence::text,t.capability_code::text,t.row_hash::text),'|' ORDER BY t.capability_sequence, t.capability_code))::text AS reconstructed_set_hash, r.capability_coverage_set_hash::text AS stored_set_hash, (md5(string_agg(concat_ws('|',t.capability_sequence::text,t.capability_code::text,t.row_hash::text),'|' ORDER BY t.capability_sequence, t.capability_code)) IS DISTINCT FROM r.capability_coverage_set_hash)::integer AS set_hash_mismatch_count FROM msbf_m2.module2_capability_coverage_snapshot t JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1 GROUP BY r.capability_coverage_set_hash) UNION ALL (SELECT 'LATEST'::text AS family_code, md5(string_agg(concat_ws('|',t.bundle_code::text,t.contract_version::text,t.row_hash::text),'|' ORDER BY t.bundle_code, t.contract_version))::text AS reconstructed_set_hash, r.latest_set_hash::text AS stored_set_hash, (md5(string_agg(concat_ws('|',t.bundle_code::text,t.contract_version::text,t.row_hash::text),'|' ORDER BY t.bundle_code, t.contract_version)) IS DISTINCT FROM r.latest_set_hash)::integer AS set_hash_mismatch_count FROM msbf_ctl.m2_12_g3_bundle_latest t JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1 GROUP BY r.latest_set_hash) UNION ALL (SELECT 'ARCHIVE'::text AS family_code, md5(string_agg(concat_ws('|',t.bundle_code::text,t.contract_version::text,t.archive_row_hash::text),'|' ORDER BY t.bundle_code, t.contract_version))::text AS reconstructed_set_hash, r.archive_set_hash::text AS stored_set_hash, (md5(string_agg(concat_ws('|',t.bundle_code::text,t.contract_version::text,t.archive_row_hash::text),'|' ORDER BY t.bundle_code, t.contract_version)) IS DISTINCT FROM r.archive_set_hash)::integer AS set_hash_mismatch_count FROM msbf_ctl.m2_12_g3_bundle_archive t JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1 GROUP BY r.archive_set_hash) UNION ALL (SELECT 'REGISTRY'::text AS family_code, md5(string_agg(concat_ws('|',t.bundle_code::text,t.contract_version::text,t.row_hash::text),'|' ORDER BY t.bundle_code, t.contract_version))::text AS reconstructed_set_hash, r.registry_set_hash::text AS stored_set_hash, (md5(string_agg(concat_ws('|',t.bundle_code::text,t.contract_version::text,t.row_hash::text),'|' ORDER BY t.bundle_code, t.contract_version)) IS DISTINCT FROM r.registry_set_hash)::integer AS set_hash_mismatch_count FROM msbf_ctl.m2_12_g3_bundle_registry t JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1 GROUP BY r.registry_set_hash)),
setd AS (SELECT sum(set_hash_mismatch_count)::bigint set_hash_mismatch_count FROM set_detail),
ch AS (SELECT r.module1_run_id,
       md5(concat_ws('|',r.bundle_code::text,r.contract_version::text,r.schema_version::text,r.methodology_version::text,r.policy_configuration_hash::text,r.policy_set_hash::text,r.stage_certification_set_hash::text,r.contract_component_set_hash::text,r.evidence_certification_set_hash::text,r.contract_reproduction_set_hash::text,r.capability_coverage_set_hash::text,r.latest_set_hash::text,r.archive_set_hash::text,r.registry_set_hash::text,r.latest_contract_row_hash::text,r.archive_contract_row_hash::text,r.row_hash::text,r.accepted_m2_11_contract_set_hash::text,r.accepted_m2_11_combined_set_hash::text,r.accepted_m2_11_registry_row_hash::text))::text AS reconstructed_contract_set_hash,
       r.contract_set_hash::text AS stored_contract_set_hash,
       (md5(concat_ws('|',r.bundle_code::text,r.contract_version::text,r.schema_version::text,r.methodology_version::text,r.policy_configuration_hash::text,r.policy_set_hash::text,r.stage_certification_set_hash::text,r.contract_component_set_hash::text,r.evidence_certification_set_hash::text,r.contract_reproduction_set_hash::text,r.capability_coverage_set_hash::text,r.latest_set_hash::text,r.archive_set_hash::text,r.registry_set_hash::text,r.latest_contract_row_hash::text,r.archive_contract_row_hash::text,r.row_hash::text,r.accepted_m2_11_contract_set_hash::text,r.accepted_m2_11_combined_set_hash::text,r.accepted_m2_11_registry_row_hash::text)) IS DISTINCT FROM r.contract_set_hash)::integer AS contract_hash_mismatch_count
FROM msbf_ctl.m2_12_g3_bundle_registry r
JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=r.module1_run_id
WHERE r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1), cb AS (SELECT u.module1_run_id, count(*)::integer AS canonical_entities, count(DISTINCT u.entity_type)::integer AS canonical_families, md5(string_agg(u.entity_type||'|'||u.entity_key||'|'||u.row_hash,'|' ORDER BY u.entity_type,u.entity_key))::text AS reconstructed_combined_set_hash, r.combined_set_hash::text AS stored_combined_set_hash, (md5(string_agg(u.entity_type||'|'||u.entity_key||'|'||u.row_hash,'|' ORDER BY u.entity_type,u.entity_key)) IS DISTINCT FROM r.combined_set_hash)::integer AS combined_hash_mismatch_count FROM (SELECT t.module1_run_id, 'POLICY'::text AS entity_type, concat_ws('|',t.policy_code::text,t.policy_version::text)::text AS entity_key, t.row_hash::text AS row_hash FROM msbf_ctl.m2_12_policy_profile t JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT t.module1_run_id, 'STAGE_CERTIFICATION'::text AS entity_type, concat_ws('|',t.certification_node_sequence::text,t.stage_code::text)::text AS entity_key, t.row_hash::text AS row_hash FROM msbf_m2.module2_stage_certification_snapshot t JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT t.module1_run_id, 'CONTRACT_COMPONENT'::text AS entity_type, concat_ws('|',t.component_sequence::text,t.component_contract_code::text,t.contract_version::text)::text AS entity_key, t.row_hash::text AS row_hash FROM msbf_m2.module2_contract_component_snapshot t JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT t.module1_run_id, 'EVIDENCE_CERTIFICATION'::text AS entity_type, concat_ws('|',t.node_sequence::text,t.evidence_family_sequence::text)::text AS entity_key, t.row_hash::text AS row_hash FROM msbf_m2.module2_evidence_certification_snapshot t JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT t.module1_run_id, 'CONTRACT_REPRODUCTION'::text AS entity_type, concat_ws('|',t.component_sequence::text,t.component_contract_code::text,t.contract_version::text)::text AS entity_key, t.row_hash::text AS row_hash FROM msbf_m2.module2_contract_reproduction_snapshot t JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT t.module1_run_id, 'CAPABILITY_COVERAGE'::text AS entity_type, concat_ws('|',t.capability_sequence::text,t.capability_code::text)::text AS entity_key, t.row_hash::text AS row_hash FROM msbf_m2.module2_capability_coverage_snapshot t JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT t.module1_run_id, 'LATEST'::text AS entity_type, concat_ws('|',t.bundle_code::text,t.contract_version::text)::text AS entity_key, t.row_hash::text AS row_hash FROM msbf_ctl.m2_12_g3_bundle_latest t JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT t.module1_run_id, 'ARCHIVE'::text AS entity_type, concat_ws('|',t.bundle_code::text,t.contract_version::text)::text AS entity_key, t.archive_row_hash::text AS row_hash FROM msbf_ctl.m2_12_g3_bundle_archive t JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT t.module1_run_id, 'REGISTRY'::text AS entity_type, concat_ws('|',t.bundle_code::text,t.contract_version::text)::text AS entity_key, t.row_hash::text AS row_hash FROM msbf_ctl.m2_12_g3_bundle_registry t JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id) u JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=u.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1 GROUP BY u.module1_run_id,r.combined_set_hash), seq AS (SELECT ctx.module1_run_id,
       p.last_value::bigint AS policy_last_value,p.is_called AS policy_is_called,
       a.last_value::bigint AS archive_last_value,a.is_called AS archive_is_called,
       r.last_value::bigint AS registry_last_value,r.is_called AS registry_is_called,
       ((p.last_value<>1 OR NOT p.is_called)::integer
        +(a.last_value<>1 OR NOT a.is_called)::integer
        +(r.last_value<>1 OR NOT r.is_called)::integer)::integer AS sequence_state_mismatch_count
FROM tmp_src_m2_12_validation_run_context ctx
CROSS JOIN msbf_ctl.m2_12_policy_profile_policy_profile_id_seq p
CROSS JOIN msbf_ctl.m2_12_g3_bundle_archive_archive_id_seq a
CROSS JOIN msbf_ctl.m2_12_g3_bundle_registry_registry_id_seq r)
SELECT ctx.module1_run_id,
       rowd.family_count_mismatch_count,rowd.row_hash_mismatch_count,setd.set_hash_mismatch_count,
       ch.contract_hash_mismatch_count::integer,cb.combined_hash_mismatch_count::integer,
       seq.sequence_state_mismatch_count::integer,cb.canonical_families::integer,cb.canonical_entities::integer,
       (rowd.family_count_mismatch_count+rowd.row_hash_mismatch_count+setd.set_hash_mismatch_count+ch.contract_hash_mismatch_count+cb.combined_hash_mismatch_count+seq.sequence_state_mismatch_count)::bigint AS total_mismatch_count
FROM tmp_src_m2_12_validation_run_context ctx CROSS JOIN rowd CROSS JOIN setd CROSS JOIN ch CROSS JOIN cb CROSS JOIN seq
) p;

CREATE UNIQUE INDEX ux_tmp_hash_m2_12_validation_reconciliation ON tmp_hash_m2_12_validation_reconciliation(module1_run_id);

ANALYZE tmp_hash_m2_12_validation_reconciliation;


DO $m212_p223_hf12_reconciliation_structure$
BEGIN
    IF NOT coalesce((SELECT count(*)=1
                            AND min(canonical_families)=9
                            AND min(canonical_entities)=134
                       FROM tmp_hash_m2_12_validation_reconciliation),false) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 223 HF12 canonical/hash reconciliation structure mismatch',
            DETAIL=format('rows=%s families=%s entities=%s',
                          (SELECT count(*) FROM tmp_hash_m2_12_validation_reconciliation),
                          (SELECT min(canonical_families) FROM tmp_hash_m2_12_validation_reconciliation),
                          (SELECT min(canonical_entities) FROM tmp_hash_m2_12_validation_reconciliation));
    END IF;
END;
$m212_p223_hf12_reconciliation_structure$;


CREATE TEMP TABLE tmp_eval_m2_12_positive_results
(
 control_sequence smallint NOT NULL,
 evidence_code text NOT NULL,
 control_family_sequence smallint NOT NULL,
 control_family_code text NOT NULL,
 control_title text NOT NULL,
 observed_value text,
 expected_value text,
 mismatch_count bigint NOT NULL,
 status text NOT NULL,
 interpretation text NOT NULL,
 PRIMARY KEY(control_sequence),
 UNIQUE(evidence_code)
) ON COMMIT PRESERVE ROWS;


/* Exactly 128 frozen positive-control definitions follow. */
/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_001_RUN_CONTEXT_EXACT */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    1::smallint,
    'M2_12_POS_001_RUN_CONTEXT_EXACT'::text,
    1::smallint,
    'IDENTITY'::text,
    'Governed run identity and generated lifecycle are exact'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    SELECT
        concat_ws('|',count(*)::text,min(run_code),min(run_version)::text,min(run_status)) AS observed_value,
        '1|M1_V0_2_BASELINE_BUILD|1|M2_12_GENERATED'::text AS expected_value,
        (CASE WHEN count(*)=1 AND min(run_code)='M1_V0_2_BASELINE_BUILD' AND min(run_version)=1 AND min(run_status)='M2_12_GENERATED' THEN 0 ELSE 1 END)::bigint AS mismatch_count,
        (count(*)=1 AND min(run_code)='M1_V0_2_BASELINE_BUILD' AND min(run_version)=1 AND min(run_status)='M2_12_GENERATED') AS pass_flag,
        'Program 223 is authorized only from the one generated M2.12 governed run.'::text AS interpretation
    FROM tmp_src_m2_12_validation_run_context
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_002_POLICY_IDENTITY_EXACT */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    2::smallint,
    'M2_12_POS_002_POLICY_IDENTITY_EXACT'::text,
    1::smallint,
    'IDENTITY'::text,
    'Policy, methodology, bundle, schema, and G3 gate identity are exact'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    SELECT
        concat_ws('|',p.policy_code,p.policy_version::text,p.policy_status,p.methodology_version,p.bundle_code,p.bundle_version::text,p.schema_version,p.acceptance_gate_id) AS observed_value,
        'M2_12_ENTERPRISE_PORTFOLIO_CERTIFICATION_POLICY_V1|1|APPROVED|M2_12_METHOD_V1|M2_G3_CONSUMPTION_BUNDLE|1|M2_G3_BUNDLE_SCHEMA_V1|G3_M2_CONTRACT'::text AS expected_value,
        (CASE WHEN count(*) OVER ()=1
                   AND p.policy_code='M2_12_ENTERPRISE_PORTFOLIO_CERTIFICATION_POLICY_V1'
                   AND p.policy_version=1 AND p.policy_status='APPROVED'
                   AND p.methodology_version='M2_12_METHOD_V1'
                   AND p.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND p.bundle_version=1
                   AND p.schema_version='M2_G3_BUNDLE_SCHEMA_V1' AND p.acceptance_gate_id='G3_M2_CONTRACT'
              THEN 0 ELSE 1 END)::bigint AS mismatch_count,
        (count(*) OVER ()=1
         AND p.policy_code='M2_12_ENTERPRISE_PORTFOLIO_CERTIFICATION_POLICY_V1'
         AND p.policy_version=1 AND p.policy_status='APPROVED'
         AND p.methodology_version='M2_12_METHOD_V1'
         AND p.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND p.bundle_version=1
         AND p.schema_version='M2_G3_BUNDLE_SCHEMA_V1' AND p.acceptance_gate_id='G3_M2_CONTRACT') AS pass_flag,
        'Frozen M2.12 and G3 policy identity.'::text AS interpretation
    FROM msbf_ctl.m2_12_policy_profile p
    JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=p.module1_run_id
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_003_ACCEPTED_M2_11_SOURCE_ANCHORS */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    3::smallint,
    'M2_12_POS_003_ACCEPTED_M2_11_SOURCE_ANCHORS'::text,
    1::smallint,
    'IDENTITY'::text,
    'Accepted M2.11 project, contract, combined, and registry anchors are exact'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    SELECT
        concat_ws('|',p.accepted_m2_11_project_sha256,p.accepted_m2_11_contract_set_hash,p.accepted_m2_11_combined_set_hash,p.accepted_m2_11_registry_row_hash) AS observed_value,
        concat_ws('|','92f0491eea26b0d546c85992e27433cd006a0b2f126c32a139d795b7749904fc',
            (SELECT accepted_m2_11_contract_set_hash FROM msbf_ctl.m2_12_g3_bundle_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1),
            (SELECT accepted_m2_11_combined_set_hash FROM msbf_ctl.m2_12_g3_bundle_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1),
            (SELECT accepted_m2_11_registry_row_hash FROM msbf_ctl.m2_12_g3_bundle_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1)) AS expected_value,
        (CASE WHEN p.accepted_m2_11_project_sha256='92f0491eea26b0d546c85992e27433cd006a0b2f126c32a139d795b7749904fc'
                   AND p.accepted_m2_11_contract_set_hash=(SELECT r.accepted_m2_11_contract_set_hash FROM msbf_ctl.m2_12_g3_bundle_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1)
                   AND p.accepted_m2_11_combined_set_hash=(SELECT r.accepted_m2_11_combined_set_hash FROM msbf_ctl.m2_12_g3_bundle_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1)
                   AND p.accepted_m2_11_registry_row_hash=(SELECT r.accepted_m2_11_registry_row_hash FROM msbf_ctl.m2_12_g3_bundle_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1)
              THEN 0 ELSE 1 END)::bigint AS mismatch_count,
        (p.accepted_m2_11_project_sha256='92f0491eea26b0d546c85992e27433cd006a0b2f126c32a139d795b7749904fc'
         AND p.accepted_m2_11_contract_set_hash=(SELECT r.accepted_m2_11_contract_set_hash FROM msbf_ctl.m2_12_g3_bundle_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1)
         AND p.accepted_m2_11_combined_set_hash=(SELECT r.accepted_m2_11_combined_set_hash FROM msbf_ctl.m2_12_g3_bundle_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1)
         AND p.accepted_m2_11_registry_row_hash=(SELECT r.accepted_m2_11_registry_row_hash FROM msbf_ctl.m2_12_g3_bundle_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1)) AS pass_flag,
        'The accepted M2.11 full-project ZIP and persisted G3 source anchors must agree.'::text AS interpretation
    FROM msbf_ctl.m2_12_policy_profile p
    JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=p.module1_run_id
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_004_POLICY_EXPECTED_COUNTS */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    4::smallint,
    'M2_12_POS_004_POLICY_EXPECTED_COUNTS'::text,
    1::smallint,
    'IDENTITY'::text,
    'Frozen policy counts and report cardinalities are exact'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    SELECT
        concat_ws('|',p.expected_source_node_rows,p.expected_component_contract_rows,p.expected_source_graph_edge_rows,
            p.expected_evidence_certification_rows,p.expected_contract_reproduction_rows,p.expected_capability_coverage_rows,
            p.expected_canonical_family_count,p.expected_canonical_entities,p.expected_application_consumption_rows,
            p.expected_operational_account_consumption_rows,p.expected_strategy_scope_consumption_rows,
            p.expected_generation_evidence_rows,p.expected_positive_controls,p.expected_negative_controls,
            p.expected_acceptance_requirements,p.expected_detail_result_sets) AS observed_value,
        '12|13|19|72|13|20|9|134|1500|59|24|24|128|20|48|24'::text AS expected_value,
        (CASE WHEN ROW(p.expected_source_node_rows,p.expected_component_contract_rows,p.expected_source_graph_edge_rows,
                         p.expected_evidence_certification_rows,p.expected_contract_reproduction_rows,p.expected_capability_coverage_rows,
                         p.expected_canonical_family_count,p.expected_canonical_entities,p.expected_application_consumption_rows,
                         p.expected_operational_account_consumption_rows,p.expected_strategy_scope_consumption_rows,
                         p.expected_generation_evidence_rows,p.expected_positive_controls,p.expected_negative_controls,
                         p.expected_acceptance_requirements,p.expected_detail_result_sets)
                    = ROW(12,13,19,72,13,20,9,134,1500::bigint,59,24,24,128,20,48,24)
              THEN 0 ELSE 1 END)::bigint AS mismatch_count,
        (ROW(p.expected_source_node_rows,p.expected_component_contract_rows,p.expected_source_graph_edge_rows,
             p.expected_evidence_certification_rows,p.expected_contract_reproduction_rows,p.expected_capability_coverage_rows,
             p.expected_canonical_family_count,p.expected_canonical_entities,p.expected_application_consumption_rows,
             p.expected_operational_account_consumption_rows,p.expected_strategy_scope_consumption_rows,
             p.expected_generation_evidence_rows,p.expected_positive_controls,p.expected_negative_controls,
             p.expected_acceptance_requirements,p.expected_detail_result_sets)
         = ROW(12,13,19,72,13,20,9,134,1500::bigint,59,24,24,128,20,48,24)) AS pass_flag,
        'Frozen cardinalities for M2.12 source, canonical, control, and reporting scope.'::text AS interpretation
    FROM msbf_ctl.m2_12_policy_profile p
    JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=p.module1_run_id
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_005_POLICY_NONPRODUCTION_BOUNDARY */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    5::smallint,
    'M2_12_POS_005_POLICY_NONPRODUCTION_BOUNDARY'::text,
    1::smallint,
    'IDENTITY'::text,
    'Policy non-production, no-PII, and no-Module-3 boundary is exact'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    SELECT
        concat_ws('|',p.synthetic_data_only_flag,p.no_pii_flag,p.certification_only_flag,
            p.production_action_authorized_flag,p.external_system_update_authorized_flag,
            p.legal_or_regulatory_certified_flag,p.empirical_or_causal_optimization_authorized_flag,
            p.module3_sql_authorized_flag,p.module3_execution_authorized_flag) AS observed_value,
        'true|true|true|false|false|false|false|false|false'::text AS expected_value,
        (CASE WHEN p.synthetic_data_only_flag AND p.no_pii_flag AND p.certification_only_flag
                   AND NOT p.production_action_authorized_flag AND NOT p.external_system_update_authorized_flag
                   AND NOT p.legal_or_regulatory_certified_flag AND NOT p.empirical_or_causal_optimization_authorized_flag
                   AND NOT p.module3_sql_authorized_flag AND NOT p.module3_execution_authorized_flag
              THEN 0 ELSE 1 END)::bigint AS mismatch_count,
        (p.synthetic_data_only_flag AND p.no_pii_flag AND p.certification_only_flag
         AND NOT p.production_action_authorized_flag AND NOT p.external_system_update_authorized_flag
         AND NOT p.legal_or_regulatory_certified_flag AND NOT p.empirical_or_causal_optimization_authorized_flag
         AND NOT p.module3_sql_authorized_flag AND NOT p.module3_execution_authorized_flag) AS pass_flag,
        'M2.12 certifies synthetic evidence only and grants no production or Module 3 authority.'::text AS interpretation
    FROM msbf_ctl.m2_12_policy_profile p
    JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=p.module1_run_id
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_006_POLICY_CONFIGURATION_HASH */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    6::smallint,
    'M2_12_POS_006_POLICY_CONFIGURATION_HASH'::text,
    1::smallint,
    'IDENTITY'::text,
    'Policy configuration hash independently reconstructs'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    SELECT
        concat_ws('|',p.configuration_hash,md5(p.configuration_payload::text)) AS observed_value,
        'stored_hash|independently_reconstructed_hash must match'::text AS expected_value,
        (p.configuration_hash IS DISTINCT FROM md5(p.configuration_payload::text))::integer::bigint AS mismatch_count,
        (p.configuration_hash IS NOT DISTINCT FROM md5(p.configuration_payload::text)) AS pass_flag,
        'Configuration payload identity is reconstructed without a Program 222 helper.'::text AS interpretation
    FROM msbf_ctl.m2_12_policy_profile p
    JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=p.module1_run_id
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_007_POLICY_ROW_HASH */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    7::smallint,
    'M2_12_POS_007_POLICY_ROW_HASH'::text,
    1::smallint,
    'IDENTITY'::text,
    'Policy canonical row hash independently reconstructs'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    SELECT
        concat_ws('|',p.row_hash,md5((to_jsonb(p)-'policy_profile_id'-'row_hash'-'created_at'-'updated_at')::text)) AS observed_value,
        'stored_hash|independently_reconstructed_hash must match'::text AS expected_value,
        (p.row_hash IS DISTINCT FROM md5((to_jsonb(p)-'policy_profile_id'-'row_hash'-'created_at'-'updated_at')::text))::integer::bigint AS mismatch_count,
        (p.row_hash IS NOT DISTINCT FROM md5((to_jsonb(p)-'policy_profile_id'-'row_hash'-'created_at'-'updated_at')::text)) AS pass_flag,
        'Policy row hash excludes the owned identity and mutable timestamps exactly.'::text AS interpretation
    FROM msbf_ctl.m2_12_policy_profile p
    JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=p.module1_run_id
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_008_G3_LATEST_IDENTITY */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    8::smallint,
    'M2_12_POS_008_G3_LATEST_IDENTITY'::text,
    1::smallint,
    'IDENTITY'::text,
    'G3 latest row identity, counts, boundaries, and row hashes are exact'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    SELECT
        concat_ws('|',count(*)::text,min(l.bundle_code),min(l.contract_version)::text,min(l.canonical_entity_count)::text,
            min(l.application_consumption_rows)::text,min(l.operational_account_consumption_rows)::text,min(l.strategy_scope_consumption_rows)::text,
            count(*) FILTER (WHERE l.production_action_authorized_flag OR l.external_system_update_authorized_flag OR l.legal_or_regulatory_certified_flag OR l.empirical_or_causal_optimization_authorized_flag OR l.deployment_authorized_flag OR l.module3_execution_authorized_flag)::text,
            count(*) FILTER (WHERE l.contract_row_hash IS DISTINCT FROM md5((to_jsonb(l)-'row_hash'-'contract_row_hash'-'created_at')::text))::text,
            count(*) FILTER (WHERE l.row_hash IS DISTINCT FROM md5((to_jsonb(l)-'row_hash'-'created_at')::text))::text) AS observed_value,
        '1|M2_G3_CONSUMPTION_BUNDLE|1|134|1500|59|24|0|0|0'::text AS expected_value,
        (CASE WHEN count(*)=1 AND min(l.bundle_code)='M2_G3_CONSUMPTION_BUNDLE' AND min(l.contract_version)=1
                   AND min(l.schema_version)='M2_G3_BUNDLE_SCHEMA_V1' AND min(l.methodology_version)='M2_12_METHOD_V1'
                   AND min(l.acceptance_gate_id)='G3_M2_CONTRACT' AND min(l.canonical_entity_count)=134
                   AND min(l.application_consumption_rows)=1500 AND min(l.operational_account_consumption_rows)=59 AND min(l.strategy_scope_consumption_rows)=24
                   AND bool_and(l.synthetic_data_only_flag AND l.no_pii_flag AND l.certification_only_flag)
                   AND count(*) FILTER (WHERE l.production_action_authorized_flag OR l.external_system_update_authorized_flag OR l.legal_or_regulatory_certified_flag OR l.empirical_or_causal_optimization_authorized_flag OR l.deployment_authorized_flag OR l.module3_execution_authorized_flag)=0
                   AND count(*) FILTER (WHERE l.contract_row_hash IS DISTINCT FROM md5((to_jsonb(l)-'row_hash'-'contract_row_hash'-'created_at')::text))=0
                   AND count(*) FILTER (WHERE l.row_hash IS DISTINCT FROM md5((to_jsonb(l)-'row_hash'-'created_at')::text))=0
              THEN 0 ELSE 1 END)::bigint AS mismatch_count,
        (count(*)=1 AND min(l.bundle_code)='M2_G3_CONSUMPTION_BUNDLE' AND min(l.contract_version)=1
         AND min(l.schema_version)='M2_G3_BUNDLE_SCHEMA_V1' AND min(l.methodology_version)='M2_12_METHOD_V1'
         AND min(l.acceptance_gate_id)='G3_M2_CONTRACT' AND min(l.canonical_entity_count)=134
         AND min(l.application_consumption_rows)=1500 AND min(l.operational_account_consumption_rows)=59 AND min(l.strategy_scope_consumption_rows)=24
         AND bool_and(l.synthetic_data_only_flag AND l.no_pii_flag AND l.certification_only_flag)
         AND count(*) FILTER (WHERE l.production_action_authorized_flag OR l.external_system_update_authorized_flag OR l.legal_or_regulatory_certified_flag OR l.empirical_or_causal_optimization_authorized_flag OR l.deployment_authorized_flag OR l.module3_execution_authorized_flag)=0
         AND count(*) FILTER (WHERE l.contract_row_hash IS DISTINCT FROM md5((to_jsonb(l)-'row_hash'-'contract_row_hash'-'created_at')::text))=0
         AND count(*) FILTER (WHERE l.row_hash IS DISTINCT FROM md5((to_jsonb(l)-'row_hash'-'created_at')::text))=0) AS pass_flag,
        'G3 latest is one complete, non-production certification bundle.'::text AS interpretation
    FROM msbf_ctl.m2_12_g3_bundle_latest l
    JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=l.module1_run_id
    WHERE l.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND l.contract_version=1
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_009_G3_ARCHIVE_IDENTITY_AND_GUARD */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    9::smallint,
    'M2_12_POS_009_G3_ARCHIVE_IDENTITY_AND_GUARD'::text,
    1::smallint,
    'IDENTITY'::text,
    'G3 archive identity, latest linkage, row hash, and immutability trigger are exact'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH a AS (
        SELECT ar.* FROM msbf_ctl.m2_12_g3_bundle_archive ar
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=ar.module1_run_id
        WHERE ar.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND ar.contract_version=1
    ), l AS (
        SELECT lt.* FROM msbf_ctl.m2_12_g3_bundle_latest lt
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=lt.module1_run_id
        WHERE lt.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND lt.contract_version=1
    ), trig AS (
        SELECT count(*)::integer AS n
        FROM pg_catalog.pg_trigger t
        JOIN pg_catalog.pg_proc p ON p.oid=t.tgfoid
        JOIN pg_catalog.pg_namespace n ON n.oid=p.pronamespace
        WHERE t.tgrelid='msbf_ctl.m2_12_g3_bundle_archive'::regclass
          AND NOT t.tgisinternal AND t.tgname='trg_m2_12_g3_archive_immutable'
          AND n.nspname||'.'||p.proname='msbf_ctl.m2_12_reject_g3_archive_mutation'
          AND (t.tgtype & 1)=1 AND (t.tgtype & 2)=2 AND (t.tgtype & 8)=8 AND (t.tgtype & 16)=16
          AND t.tgenabled IN ('O','A')
    )
    SELECT
        concat_ws('|',(SELECT count(*) FROM a),(SELECT count(*) FROM l),
            (SELECT count(*) FROM a JOIN l USING(module1_run_id,bundle_code,contract_version) WHERE a.source_latest_row_hash=l.row_hash AND a.contract_row_hash=l.contract_row_hash AND a.contract_payload=(to_jsonb(l)-'created_at')),
            (SELECT count(*) FROM a WHERE a.archive_row_hash=md5((to_jsonb(a)-'archive_id'-'archive_row_hash'-'created_at')::text)),(SELECT n FROM trig)) AS observed_value,
        '1|1|1|1|1'::text AS expected_value,
        ((SELECT (count(*)<>1)::integer FROM a)
         +(SELECT (count(*)<>1)::integer FROM l)
         +(SELECT (count(*)<>1)::integer FROM a JOIN l USING(module1_run_id,bundle_code,contract_version) WHERE a.source_latest_row_hash=l.row_hash AND a.contract_row_hash=l.contract_row_hash AND a.contract_payload=(to_jsonb(l)-'created_at'))
         +(SELECT (count(*)<>1)::integer FROM a WHERE a.archive_row_hash=md5((to_jsonb(a)-'archive_id'-'archive_row_hash'-'created_at')::text))
         +(SELECT (n<>1)::integer FROM trig))::bigint AS mismatch_count,
        ((SELECT count(*)=1 FROM a) AND (SELECT count(*)=1 FROM l)
         AND (SELECT count(*)=1 FROM a JOIN l USING(module1_run_id,bundle_code,contract_version) WHERE a.source_latest_row_hash=l.row_hash AND a.contract_row_hash=l.contract_row_hash AND a.contract_payload=(to_jsonb(l)-'created_at'))
         AND (SELECT count(*)=1 FROM a WHERE a.archive_row_hash=md5((to_jsonb(a)-'archive_id'-'archive_row_hash'-'created_at')::text))
         AND (SELECT n=1 FROM trig)) AS pass_flag,
        'G3 archive reproduces latest and is protected by the approved physical guard.'::text AS interpretation
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_010_G3_REGISTRY_GENERATED_CHECKPOINT */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    10::smallint,
    'M2_12_POS_010_G3_REGISTRY_GENERATED_CHECKPOINT'::text,
    1::smallint,
    'IDENTITY'::text,
    'G3 registry generated checkpoint and pristine downstream state are exact'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH r AS (
        SELECT g.* FROM msbf_ctl.m2_12_g3_bundle_registry g
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=g.module1_run_id
        WHERE g.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND g.contract_version=1
    ), ev AS (
        SELECT
            count(*) FILTER (WHERE e.evidence_code=ANY(ARRAY['M2_12_POLICY_SET_HASH','M2_12_STAGE_CERTIFICATION_SET_HASH','M2_12_CONTRACT_COMPONENT_SET_HASH','M2_12_EVIDENCE_CERTIFICATION_SET_HASH','M2_12_CONTRACT_REPRODUCTION_SET_HASH','M2_12_CAPABILITY_COVERAGE_SET_HASH','M2_12_LATEST_SET_HASH','M2_12_ARCHIVE_SET_HASH','M2_12_REGISTRY_SET_HASH','M2_12_CONTRACT_SET_HASH','M2_12_COMBINED_SET_HASH','M2_12_STAGE_CERTIFICATION_ROWS','M2_12_CONTRACT_COMPONENT_ROWS','M2_12_EVIDENCE_CERTIFICATION_ROWS','M2_12_CONTRACT_REPRODUCTION_ROWS','M2_12_CAPABILITY_COVERAGE_ROWS','M2_12_CANONICAL_ENTITIES','M2_12_COMPONENT_LATEST_ARCHIVE_ROWS_TOTAL','M2_12_APPLICATION_CONSUMPTION_ROWS','M2_12_OPERATIONAL_ACCOUNT_CONSUMPTION_ROWS','M2_12_STRATEGY_SCOPE_CONSUMPTION_ROWS','M2_12_SOURCE_GRAPH_EDGES','M2_12_DETERMINISTIC_MISMATCHES','M2_12_BLOCKING_STAGE_BOUNDARY_FINDINGS']::text[]) AND e.status='PASS')::integer AS generation_pass,
            count(DISTINCT e.evidence_code) FILTER (WHERE e.evidence_code=ANY(ARRAY['M2_12_POLICY_SET_HASH','M2_12_STAGE_CERTIFICATION_SET_HASH','M2_12_CONTRACT_COMPONENT_SET_HASH','M2_12_EVIDENCE_CERTIFICATION_SET_HASH','M2_12_CONTRACT_REPRODUCTION_SET_HASH','M2_12_CAPABILITY_COVERAGE_SET_HASH','M2_12_LATEST_SET_HASH','M2_12_ARCHIVE_SET_HASH','M2_12_REGISTRY_SET_HASH','M2_12_CONTRACT_SET_HASH','M2_12_COMBINED_SET_HASH','M2_12_STAGE_CERTIFICATION_ROWS','M2_12_CONTRACT_COMPONENT_ROWS','M2_12_EVIDENCE_CERTIFICATION_ROWS','M2_12_CONTRACT_REPRODUCTION_ROWS','M2_12_CAPABILITY_COVERAGE_ROWS','M2_12_CANONICAL_ENTITIES','M2_12_COMPONENT_LATEST_ARCHIVE_ROWS_TOTAL','M2_12_APPLICATION_CONSUMPTION_ROWS','M2_12_OPERATIONAL_ACCOUNT_CONSUMPTION_ROWS','M2_12_STRATEGY_SCOPE_CONSUMPTION_ROWS','M2_12_SOURCE_GRAPH_EDGES','M2_12_DETERMINISTIC_MISMATCHES','M2_12_BLOCKING_STAGE_BOUNDARY_FINDINGS']::text[]) AND e.status='PASS')::integer AS generation_distinct,
            count(*) FILTER (WHERE e.evidence_code LIKE 'M2_12_POS_%')::integer AS positive_rows,
            count(*) FILTER (WHERE e.evidence_code LIKE 'M2_12_NEG_%')::integer AS negative_rows,
            count(*) FILTER (WHERE e.evidence_code='M2_12_ACCEPTANCE_SUMMARY')::integer AS acceptance_rows
        FROM msbf_ctl.run_evidence e
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=e.run_id
    ), gate AS (
        SELECT count(*)::integer AS gate_rows FROM msbf_ctl.acceptance_gate_result g
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=g.run_id
        WHERE g.gate_id='G3_M2_CONTRACT' AND g.review_version=1
    )
    SELECT
        concat_ws('|',(SELECT count(*) FROM r),(SELECT min(contract_status) FROM r),(SELECT generation_pass FROM ev),(SELECT generation_distinct FROM ev),
            (SELECT positive_rows FROM ev),(SELECT negative_rows FROM ev),(SELECT acceptance_rows FROM ev),(SELECT gate_rows FROM gate)) AS observed_value,
        '1|GENERATED|24|24|0|0|0|0'::text AS expected_value,
        (CASE WHEN (SELECT count(*) FROM r)=1 AND (SELECT min(contract_status) FROM r)='GENERATED'
                   AND (SELECT count(*) FROM r WHERE generated_at IS NOT NULL AND validated_at IS NULL AND accepted_at IS NULL)=1
                   AND (SELECT generation_pass=24 AND generation_distinct=24 AND positive_rows=0 AND negative_rows=0 AND acceptance_rows=0 FROM ev)
                   AND (SELECT gate_rows=0 FROM gate)
              THEN 0 ELSE 1 END)::bigint AS mismatch_count,
        ((SELECT count(*) FROM r)=1 AND (SELECT min(contract_status) FROM r)='GENERATED'
         AND (SELECT count(*) FROM r WHERE generated_at IS NOT NULL AND validated_at IS NULL AND accepted_at IS NULL)=1
         AND (SELECT generation_pass=24 AND generation_distinct=24 AND positive_rows=0 AND negative_rows=0 AND acceptance_rows=0 FROM ev)
         AND (SELECT gate_rows=0 FROM gate)) AS pass_flag,
        'Positive validation starts only from the exact generated checkpoint and pristine WP3/acceptance state.'::text AS interpretation
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_011_NODE_01_M1_17_G2_FOUNDATION_CANONICAL */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    11::smallint,
    'M2_12_POS_011_NODE_01_M1_17_G2_FOUNDATION_CANONICAL'::text,
    2::smallint,
    'SOURCE_NODE_ACCEPTANCE'::text,
    'Node 01 M1_17_G2_FOUNDATION persisted certification is exact'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH s AS (
        SELECT t.* FROM msbf_m2.module2_stage_certification_snapshot t
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id
        WHERE t.certification_node_sequence=1 AND t.stage_code='M1_17_G2_FOUNDATION'
    )
    SELECT
        concat_ws('|',count(*)::text,min(stage_code),min(repository_stage),min(contract_status),min(gate_status),
            min(acceptance_evidence_status),min(observed_canonical_entities)::text,min(observed_positive_controls)::text,
            min(observed_negative_controls)::text,min(observed_combined_hash),min(source_graph_status),min(stage_boundary_status),
            min(certification_status),count(*) FILTER (WHERE row_hash IS DISTINCT FROM md5((to_jsonb(s)-'row_hash'-'created_at')::text))::text) AS observed_value,
        '1|M1_17_G2_FOUNDATION|19_M1_17|ACCEPTED|PASS|PASS|69|128|20|7d9e466da28cad2551aa99c4c40c912b|PASS|PASS|PASS|0'::text AS expected_value,
        (CASE WHEN count(*)=1 AND min(stage_code)='M1_17_G2_FOUNDATION' AND min(repository_stage)='19_M1_17'
                   AND min(module_title)='End-to-End QA, Evidence & G2 Contract Acceptance' AND min(acceptance_gate_id)='G2_M1_CONTRACT'
                   AND min(acceptance_gate_review_version)=1
                   AND min(acceptance_evidence_code)='M1_17_ACCEPTANCE_SUMMARY'
                   AND min(contract_status)='ACCEPTED' AND min(gate_status)='PASS' AND min(acceptance_evidence_status)='PASS'
                   AND min(expected_canonical_entities)=69 AND min(observed_canonical_entities)=69
                   AND min(expected_positive_controls)=128 AND min(observed_positive_controls)=128
                   AND min(expected_negative_controls)=20 AND min(observed_negative_controls)=20
                   AND min(expected_combined_hash)='7d9e466da28cad2551aa99c4c40c912b' AND min(observed_combined_hash)='7d9e466da28cad2551aa99c4c40c912b'
                   AND min(required_source_edge_count)=2 AND min(passed_source_edge_count)=2
                   AND min(source_graph_status)='PASS' AND min(canonical_identity_status)='PASS' AND min(stage_boundary_status)='PASS' AND min(certification_status)='PASS'
                   AND count(*) FILTER (WHERE row_hash IS DISTINCT FROM md5((to_jsonb(s)-'row_hash'-'created_at')::text))=0
              THEN 0 ELSE 1 END)::bigint AS mismatch_count,
        (count(*)=1 AND min(stage_code)='M1_17_G2_FOUNDATION' AND min(repository_stage)='19_M1_17'
         AND min(module_title)='End-to-End QA, Evidence & G2 Contract Acceptance' AND min(acceptance_gate_id)='G2_M1_CONTRACT'
         AND min(acceptance_gate_review_version)=1
         AND min(acceptance_evidence_code)='M1_17_ACCEPTANCE_SUMMARY'
         AND min(contract_status)='ACCEPTED' AND min(gate_status)='PASS' AND min(acceptance_evidence_status)='PASS'
         AND min(expected_canonical_entities)=69 AND min(observed_canonical_entities)=69
         AND min(expected_positive_controls)=128 AND min(observed_positive_controls)=128
         AND min(expected_negative_controls)=20 AND min(observed_negative_controls)=20
         AND min(expected_combined_hash)='7d9e466da28cad2551aa99c4c40c912b' AND min(observed_combined_hash)='7d9e466da28cad2551aa99c4c40c912b'
         AND min(required_source_edge_count)=2 AND min(passed_source_edge_count)=2
         AND min(source_graph_status)='PASS' AND min(canonical_identity_status)='PASS' AND min(stage_boundary_status)='PASS' AND min(certification_status)='PASS'
         AND count(*) FILTER (WHERE row_hash IS DISTINCT FROM md5((to_jsonb(s)-'row_hash'-'created_at')::text))=0) AS pass_flag,
        'Node M1_17_G2_FOUNDATION persisted certification is independently reconstructed from its physical canonical row.'::text AS interpretation
    FROM s
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_012_NODE_01_M1_17_G2_FOUNDATION_PHYSICAL_ACCEPTANCE */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    12::smallint,
    'M2_12_POS_012_NODE_01_M1_17_G2_FOUNDATION_PHYSICAL_ACCEPTANCE'::text,
    2::smallint,
    'SOURCE_NODE_ACCEPTANCE'::text,
    'Node 1 M1_17_G2_FOUNDATION gate, acceptance, physical boundary controls, and source edges are exact'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH gate AS (
        SELECT count(*)::integer AS n,
               count(*) FILTER (WHERE g.result_status='PASS')::integer AS pass_n
        FROM msbf_ctl.acceptance_gate_result g
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=g.run_id
        WHERE g.gate_id='G2_M1_CONTRACT' AND g.review_version=1
    ), acceptance AS (
        SELECT count(*)::integer AS n,
               count(*) FILTER (WHERE e.status='PASS')::integer AS pass_n
        FROM msbf_ctl.run_evidence e
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=e.run_id
        WHERE e.evidence_code='M1_17_ACCEPTANCE_SUMMARY'
    ), boundary AS (
        SELECT *
        FROM tmp_cert_m2_12_stage_boundary_observation b
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=b.module1_run_id
        WHERE b.node_sequence=1 AND b.stage_code='M1_17_G2_FOUNDATION'
    ), edges AS (
        SELECT count(*)::integer AS n,
               count(*) FILTER (WHERE edge_status='PASS')::integer AS pass_n,
               count(*) FILTER (WHERE source_hash_mismatch_flag OR target_hash_mismatch_flag)::integer AS mismatch_n
        FROM tmp_eval_m2_12_validation_source_edges
        WHERE target_node_code='M1_17_G2_FOUNDATION'
    )
    SELECT
        concat_ws('|',
            (SELECT n FROM gate),(SELECT pass_n FROM gate),
            (SELECT n FROM acceptance),(SELECT pass_n FROM acceptance),
            (SELECT required_evidence_rows FROM boundary),
            (SELECT physical_required_evidence_rows FROM boundary),
            (SELECT observed_required_evidence_rows FROM boundary),
            (SELECT duplicate_required_evidence_rows FROM boundary),
            (SELECT (missing_required_evidence_codes<>'')::integer FROM boundary),
            (SELECT nonpass_evidence_rows FROM boundary),
            (SELECT violation_rows FROM boundary),
            (SELECT certification_status FROM boundary),
            (SELECT n FROM edges),(SELECT pass_n FROM edges),(SELECT mismatch_n FROM edges)) AS observed_value,
        '1|1|1|1|3|3|3|0|0|0|0|PASS|2|2|0'::text AS expected_value,
        ((SELECT (n<>1 OR pass_n<>1)::integer FROM gate)
         +(SELECT (n<>1 OR pass_n<>1)::integer FROM acceptance)
         +(SELECT CASE WHEN count(*)=1
                         AND min(required_evidence_rows)=3
                         AND min(physical_required_evidence_rows)=3
                         AND min(observed_required_evidence_rows)=3
                         AND min(duplicate_required_evidence_rows)=0
                         AND min((missing_required_evidence_codes<>'')::integer)=0
                         AND min(nonpass_evidence_rows)=0
                         AND min(violation_rows)=0
                         AND min(certification_status)='PASS'
                       THEN 0 ELSE 1 END FROM boundary)
         +(SELECT (n<>2 OR pass_n<>2 OR mismatch_n<>0)::integer FROM edges))::bigint AS mismatch_count,
        ((SELECT n=1 AND pass_n=1 FROM gate)
         AND (SELECT n=1 AND pass_n=1 FROM acceptance)
         AND (SELECT count(*)=1
                     AND min(required_evidence_rows)=3
                     AND min(physical_required_evidence_rows)=3
                     AND min(observed_required_evidence_rows)=3
                     AND min(duplicate_required_evidence_rows)=0
                     AND min((missing_required_evidence_codes<>'')::integer)=0
                     AND min(nonpass_evidence_rows)=0
                     AND min(violation_rows)=0
                     AND min(certification_status)='PASS' FROM boundary)
         AND (SELECT n=2 AND pass_n=2 AND mismatch_n=0 FROM edges)) AS pass_flag,
        'Independent persisted-state reconstruction uses the exact acceptance gate and summary, the 70-control physical stage-boundary model, and the exact 19-edge source graph for M1_17_G2_FOUNDATION.'::text AS interpretation
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_013_NODE_02_M2_1_ELIGIBILITY_ROUTING_CANONICAL */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    13::smallint,
    'M2_12_POS_013_NODE_02_M2_1_ELIGIBILITY_ROUTING_CANONICAL'::text,
    2::smallint,
    'SOURCE_NODE_ACCEPTANCE'::text,
    'Node 02 M2_1_ELIGIBILITY_ROUTING persisted certification is exact'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH s AS (
        SELECT t.* FROM msbf_m2.module2_stage_certification_snapshot t
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id
        WHERE t.certification_node_sequence=2 AND t.stage_code='M2_1_ELIGIBILITY_ROUTING'
    )
    SELECT
        concat_ws('|',count(*)::text,min(stage_code),min(repository_stage),min(contract_status),min(gate_status),
            min(acceptance_evidence_status),min(observed_canonical_entities)::text,min(observed_positive_controls)::text,
            min(observed_negative_controls)::text,min(observed_combined_hash),min(source_graph_status),min(stage_boundary_status),
            min(certification_status),count(*) FILTER (WHERE row_hash IS DISTINCT FROM md5((to_jsonb(s)-'row_hash'-'created_at')::text))::text) AS observed_value,
        '1|M2_1_ELIGIBILITY_ROUTING|20_M2_1|ACCEPTED|PASS|PASS|22541|112|20|e5ace7f32060ffb191c7bd0f8dd0c863|PASS|PASS|PASS|0'::text AS expected_value,
        (CASE WHEN count(*)=1 AND min(stage_code)='M2_1_ELIGIBILITY_ROUTING' AND min(repository_stage)='20_M2_1'
                   AND min(module_title)='Eligibility, Policy Gates & Decision Routing Foundations' AND min(acceptance_gate_id)='M2_1_ELIGIBILITY_POLICY_ROUTING'
                   AND min(acceptance_gate_review_version)=1
                   AND min(acceptance_evidence_code)='M2_1_ACCEPTANCE_SUMMARY'
                   AND min(contract_status)='ACCEPTED' AND min(gate_status)='PASS' AND min(acceptance_evidence_status)='PASS'
                   AND min(expected_canonical_entities)=22541 AND min(observed_canonical_entities)=22541
                   AND min(expected_positive_controls)=112 AND min(observed_positive_controls)=112
                   AND min(expected_negative_controls)=20 AND min(observed_negative_controls)=20
                   AND min(expected_combined_hash)='e5ace7f32060ffb191c7bd0f8dd0c863' AND min(observed_combined_hash)='e5ace7f32060ffb191c7bd0f8dd0c863'
                   AND min(required_source_edge_count)=1 AND min(passed_source_edge_count)=1
                   AND min(source_graph_status)='PASS' AND min(canonical_identity_status)='PASS' AND min(stage_boundary_status)='PASS' AND min(certification_status)='PASS'
                   AND count(*) FILTER (WHERE row_hash IS DISTINCT FROM md5((to_jsonb(s)-'row_hash'-'created_at')::text))=0
              THEN 0 ELSE 1 END)::bigint AS mismatch_count,
        (count(*)=1 AND min(stage_code)='M2_1_ELIGIBILITY_ROUTING' AND min(repository_stage)='20_M2_1'
         AND min(module_title)='Eligibility, Policy Gates & Decision Routing Foundations' AND min(acceptance_gate_id)='M2_1_ELIGIBILITY_POLICY_ROUTING'
         AND min(acceptance_gate_review_version)=1
         AND min(acceptance_evidence_code)='M2_1_ACCEPTANCE_SUMMARY'
         AND min(contract_status)='ACCEPTED' AND min(gate_status)='PASS' AND min(acceptance_evidence_status)='PASS'
         AND min(expected_canonical_entities)=22541 AND min(observed_canonical_entities)=22541
         AND min(expected_positive_controls)=112 AND min(observed_positive_controls)=112
         AND min(expected_negative_controls)=20 AND min(observed_negative_controls)=20
         AND min(expected_combined_hash)='e5ace7f32060ffb191c7bd0f8dd0c863' AND min(observed_combined_hash)='e5ace7f32060ffb191c7bd0f8dd0c863'
         AND min(required_source_edge_count)=1 AND min(passed_source_edge_count)=1
         AND min(source_graph_status)='PASS' AND min(canonical_identity_status)='PASS' AND min(stage_boundary_status)='PASS' AND min(certification_status)='PASS'
         AND count(*) FILTER (WHERE row_hash IS DISTINCT FROM md5((to_jsonb(s)-'row_hash'-'created_at')::text))=0) AS pass_flag,
        'Node M2_1_ELIGIBILITY_ROUTING persisted certification is independently reconstructed from its physical canonical row.'::text AS interpretation
    FROM s
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_014_NODE_02_M2_1_ELIGIBILITY_ROUTING_PHYSICAL_ACCEPTANCE */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    14::smallint,
    'M2_12_POS_014_NODE_02_M2_1_ELIGIBILITY_ROUTING_PHYSICAL_ACCEPTANCE'::text,
    2::smallint,
    'SOURCE_NODE_ACCEPTANCE'::text,
    'Node 2 M2_1_ELIGIBILITY_ROUTING gate, acceptance, physical boundary controls, and source edges are exact'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH gate AS (
        SELECT count(*)::integer AS n,
               count(*) FILTER (WHERE g.result_status='PASS')::integer AS pass_n
        FROM msbf_ctl.acceptance_gate_result g
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=g.run_id
        WHERE g.gate_id='M2_1_ELIGIBILITY_POLICY_ROUTING' AND g.review_version=1
    ), acceptance AS (
        SELECT count(*)::integer AS n,
               count(*) FILTER (WHERE e.status='PASS')::integer AS pass_n
        FROM msbf_ctl.run_evidence e
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=e.run_id
        WHERE e.evidence_code='M2_1_ACCEPTANCE_SUMMARY'
    ), boundary AS (
        SELECT *
        FROM tmp_cert_m2_12_stage_boundary_observation b
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=b.module1_run_id
        WHERE b.node_sequence=2 AND b.stage_code='M2_1_ELIGIBILITY_ROUTING'
    ), edges AS (
        SELECT count(*)::integer AS n,
               count(*) FILTER (WHERE edge_status='PASS')::integer AS pass_n,
               count(*) FILTER (WHERE source_hash_mismatch_flag OR target_hash_mismatch_flag)::integer AS mismatch_n
        FROM tmp_eval_m2_12_validation_source_edges
        WHERE target_node_code='M2_1_ELIGIBILITY_ROUTING'
    )
    SELECT
        concat_ws('|',
            (SELECT n FROM gate),(SELECT pass_n FROM gate),
            (SELECT n FROM acceptance),(SELECT pass_n FROM acceptance),
            (SELECT required_evidence_rows FROM boundary),
            (SELECT physical_required_evidence_rows FROM boundary),
            (SELECT observed_required_evidence_rows FROM boundary),
            (SELECT duplicate_required_evidence_rows FROM boundary),
            (SELECT (missing_required_evidence_codes<>'')::integer FROM boundary),
            (SELECT nonpass_evidence_rows FROM boundary),
            (SELECT violation_rows FROM boundary),
            (SELECT certification_status FROM boundary),
            (SELECT n FROM edges),(SELECT pass_n FROM edges),(SELECT mismatch_n FROM edges)) AS observed_value,
        '1|1|1|1|3|3|3|0|0|0|0|PASS|1|1|0'::text AS expected_value,
        ((SELECT (n<>1 OR pass_n<>1)::integer FROM gate)
         +(SELECT (n<>1 OR pass_n<>1)::integer FROM acceptance)
         +(SELECT CASE WHEN count(*)=1
                         AND min(required_evidence_rows)=3
                         AND min(physical_required_evidence_rows)=3
                         AND min(observed_required_evidence_rows)=3
                         AND min(duplicate_required_evidence_rows)=0
                         AND min((missing_required_evidence_codes<>'')::integer)=0
                         AND min(nonpass_evidence_rows)=0
                         AND min(violation_rows)=0
                         AND min(certification_status)='PASS'
                       THEN 0 ELSE 1 END FROM boundary)
         +(SELECT (n<>1 OR pass_n<>1 OR mismatch_n<>0)::integer FROM edges))::bigint AS mismatch_count,
        ((SELECT n=1 AND pass_n=1 FROM gate)
         AND (SELECT n=1 AND pass_n=1 FROM acceptance)
         AND (SELECT count(*)=1
                     AND min(required_evidence_rows)=3
                     AND min(physical_required_evidence_rows)=3
                     AND min(observed_required_evidence_rows)=3
                     AND min(duplicate_required_evidence_rows)=0
                     AND min((missing_required_evidence_codes<>'')::integer)=0
                     AND min(nonpass_evidence_rows)=0
                     AND min(violation_rows)=0
                     AND min(certification_status)='PASS' FROM boundary)
         AND (SELECT n=1 AND pass_n=1 AND mismatch_n=0 FROM edges)) AS pass_flag,
        'Independent persisted-state reconstruction uses the exact acceptance gate and summary, the 70-control physical stage-boundary model, and the exact 19-edge source graph for M2_1_ELIGIBILITY_ROUTING.'::text AS interpretation
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_015_NODE_03_M2_2_PRICING_STRUCTURE_CANONICAL */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    15::smallint,
    'M2_12_POS_015_NODE_03_M2_2_PRICING_STRUCTURE_CANONICAL'::text,
    2::smallint,
    'SOURCE_NODE_ACCEPTANCE'::text,
    'Node 03 M2_2_PRICING_STRUCTURE persisted certification is exact'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH s AS (
        SELECT t.* FROM msbf_m2.module2_stage_certification_snapshot t
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id
        WHERE t.certification_node_sequence=3 AND t.stage_code='M2_2_PRICING_STRUCTURE'
    )
    SELECT
        concat_ws('|',count(*)::text,min(stage_code),min(repository_stage),min(contract_status),min(gate_status),
            min(acceptance_evidence_status),min(observed_canonical_entities)::text,min(observed_positive_controls)::text,
            min(observed_negative_controls)::text,min(observed_combined_hash),min(source_graph_status),min(stage_boundary_status),
            min(certification_status),count(*) FILTER (WHERE row_hash IS DISTINCT FROM md5((to_jsonb(s)-'row_hash'-'created_at')::text))::text) AS observed_value,
        '1|M2_2_PRICING_STRUCTURE|21_M2_2|ACCEPTED|PASS|PASS|7336|120|20|bbe83b187b31ea561789797322031fc6|PASS|PASS|PASS|0'::text AS expected_value,
        (CASE WHEN count(*)=1 AND min(stage_code)='M2_2_PRICING_STRUCTURE' AND min(repository_stage)='21_M2_2'
                   AND min(module_title)='Pricing, Structure & Counteroffer Foundations' AND min(acceptance_gate_id)='M2_2_PRICING_STRUCTURE_COUNTEROFFER'
                   AND min(acceptance_gate_review_version)=1
                   AND min(acceptance_evidence_code)='M2_2_ACCEPTANCE_SUMMARY'
                   AND min(contract_status)='ACCEPTED' AND min(gate_status)='PASS' AND min(acceptance_evidence_status)='PASS'
                   AND min(expected_canonical_entities)=7336 AND min(observed_canonical_entities)=7336
                   AND min(expected_positive_controls)=120 AND min(observed_positive_controls)=120
                   AND min(expected_negative_controls)=20 AND min(observed_negative_controls)=20
                   AND min(expected_combined_hash)='bbe83b187b31ea561789797322031fc6' AND min(observed_combined_hash)='bbe83b187b31ea561789797322031fc6'
                   AND min(required_source_edge_count)=2 AND min(passed_source_edge_count)=2
                   AND min(source_graph_status)='PASS' AND min(canonical_identity_status)='PASS' AND min(stage_boundary_status)='PASS' AND min(certification_status)='PASS'
                   AND count(*) FILTER (WHERE row_hash IS DISTINCT FROM md5((to_jsonb(s)-'row_hash'-'created_at')::text))=0
              THEN 0 ELSE 1 END)::bigint AS mismatch_count,
        (count(*)=1 AND min(stage_code)='M2_2_PRICING_STRUCTURE' AND min(repository_stage)='21_M2_2'
         AND min(module_title)='Pricing, Structure & Counteroffer Foundations' AND min(acceptance_gate_id)='M2_2_PRICING_STRUCTURE_COUNTEROFFER'
         AND min(acceptance_gate_review_version)=1
         AND min(acceptance_evidence_code)='M2_2_ACCEPTANCE_SUMMARY'
         AND min(contract_status)='ACCEPTED' AND min(gate_status)='PASS' AND min(acceptance_evidence_status)='PASS'
         AND min(expected_canonical_entities)=7336 AND min(observed_canonical_entities)=7336
         AND min(expected_positive_controls)=120 AND min(observed_positive_controls)=120
         AND min(expected_negative_controls)=20 AND min(observed_negative_controls)=20
         AND min(expected_combined_hash)='bbe83b187b31ea561789797322031fc6' AND min(observed_combined_hash)='bbe83b187b31ea561789797322031fc6'
         AND min(required_source_edge_count)=2 AND min(passed_source_edge_count)=2
         AND min(source_graph_status)='PASS' AND min(canonical_identity_status)='PASS' AND min(stage_boundary_status)='PASS' AND min(certification_status)='PASS'
         AND count(*) FILTER (WHERE row_hash IS DISTINCT FROM md5((to_jsonb(s)-'row_hash'-'created_at')::text))=0) AS pass_flag,
        'Node M2_2_PRICING_STRUCTURE persisted certification is independently reconstructed from its physical canonical row.'::text AS interpretation
    FROM s
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_016_NODE_03_M2_2_PRICING_STRUCTURE_PHYSICAL_ACCEPTANCE */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    16::smallint,
    'M2_12_POS_016_NODE_03_M2_2_PRICING_STRUCTURE_PHYSICAL_ACCEPTANCE'::text,
    2::smallint,
    'SOURCE_NODE_ACCEPTANCE'::text,
    'Node 3 M2_2_PRICING_STRUCTURE gate, acceptance, physical boundary controls, and source edges are exact'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH gate AS (
        SELECT count(*)::integer AS n,
               count(*) FILTER (WHERE g.result_status='PASS')::integer AS pass_n
        FROM msbf_ctl.acceptance_gate_result g
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=g.run_id
        WHERE g.gate_id='M2_2_PRICING_STRUCTURE_COUNTEROFFER' AND g.review_version=1
    ), acceptance AS (
        SELECT count(*)::integer AS n,
               count(*) FILTER (WHERE e.status='PASS')::integer AS pass_n
        FROM msbf_ctl.run_evidence e
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=e.run_id
        WHERE e.evidence_code='M2_2_ACCEPTANCE_SUMMARY'
    ), boundary AS (
        SELECT *
        FROM tmp_cert_m2_12_stage_boundary_observation b
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=b.module1_run_id
        WHERE b.node_sequence=3 AND b.stage_code='M2_2_PRICING_STRUCTURE'
    ), edges AS (
        SELECT count(*)::integer AS n,
               count(*) FILTER (WHERE edge_status='PASS')::integer AS pass_n,
               count(*) FILTER (WHERE source_hash_mismatch_flag OR target_hash_mismatch_flag)::integer AS mismatch_n
        FROM tmp_eval_m2_12_validation_source_edges
        WHERE target_node_code='M2_2_PRICING_STRUCTURE'
    )
    SELECT
        concat_ws('|',
            (SELECT n FROM gate),(SELECT pass_n FROM gate),
            (SELECT n FROM acceptance),(SELECT pass_n FROM acceptance),
            (SELECT required_evidence_rows FROM boundary),
            (SELECT physical_required_evidence_rows FROM boundary),
            (SELECT observed_required_evidence_rows FROM boundary),
            (SELECT duplicate_required_evidence_rows FROM boundary),
            (SELECT (missing_required_evidence_codes<>'')::integer FROM boundary),
            (SELECT nonpass_evidence_rows FROM boundary),
            (SELECT violation_rows FROM boundary),
            (SELECT certification_status FROM boundary),
            (SELECT n FROM edges),(SELECT pass_n FROM edges),(SELECT mismatch_n FROM edges)) AS observed_value,
        '1|1|1|1|3|3|3|0|0|0|0|PASS|2|2|0'::text AS expected_value,
        ((SELECT (n<>1 OR pass_n<>1)::integer FROM gate)
         +(SELECT (n<>1 OR pass_n<>1)::integer FROM acceptance)
         +(SELECT CASE WHEN count(*)=1
                         AND min(required_evidence_rows)=3
                         AND min(physical_required_evidence_rows)=3
                         AND min(observed_required_evidence_rows)=3
                         AND min(duplicate_required_evidence_rows)=0
                         AND min((missing_required_evidence_codes<>'')::integer)=0
                         AND min(nonpass_evidence_rows)=0
                         AND min(violation_rows)=0
                         AND min(certification_status)='PASS'
                       THEN 0 ELSE 1 END FROM boundary)
         +(SELECT (n<>2 OR pass_n<>2 OR mismatch_n<>0)::integer FROM edges))::bigint AS mismatch_count,
        ((SELECT n=1 AND pass_n=1 FROM gate)
         AND (SELECT n=1 AND pass_n=1 FROM acceptance)
         AND (SELECT count(*)=1
                     AND min(required_evidence_rows)=3
                     AND min(physical_required_evidence_rows)=3
                     AND min(observed_required_evidence_rows)=3
                     AND min(duplicate_required_evidence_rows)=0
                     AND min((missing_required_evidence_codes<>'')::integer)=0
                     AND min(nonpass_evidence_rows)=0
                     AND min(violation_rows)=0
                     AND min(certification_status)='PASS' FROM boundary)
         AND (SELECT n=2 AND pass_n=2 AND mismatch_n=0 FROM edges)) AS pass_flag,
        'Independent persisted-state reconstruction uses the exact acceptance gate and summary, the 70-control physical stage-boundary model, and the exact 19-edge source graph for M2_2_PRICING_STRUCTURE.'::text AS interpretation
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_017_NODE_04_M2_3_FINAL_DECISION_CANONICAL */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    17::smallint,
    'M2_12_POS_017_NODE_04_M2_3_FINAL_DECISION_CANONICAL'::text,
    2::smallint,
    'SOURCE_NODE_ACCEPTANCE'::text,
    'Node 04 M2_3_FINAL_DECISION persisted certification is exact'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH s AS (
        SELECT t.* FROM msbf_m2.module2_stage_certification_snapshot t
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id
        WHERE t.certification_node_sequence=4 AND t.stage_code='M2_3_FINAL_DECISION'
    )
    SELECT
        concat_ws('|',count(*)::text,min(stage_code),min(repository_stage),min(contract_status),min(gate_status),
            min(acceptance_evidence_status),min(observed_canonical_entities)::text,min(observed_positive_controls)::text,
            min(observed_negative_controls)::text,min(observed_combined_hash),min(source_graph_status),min(stage_boundary_status),
            min(certification_status),count(*) FILTER (WHERE row_hash IS DISTINCT FROM md5((to_jsonb(s)-'row_hash'-'created_at')::text))::text) AS observed_value,
        '1|M2_3_FINAL_DECISION|22_M2_3|ACCEPTED|PASS|PASS|6029|120|20|bf09349b06ede7e5a2ec830c2f9ffe90|PASS|PASS|PASS|0'::text AS expected_value,
        (CASE WHEN count(*)=1 AND min(stage_code)='M2_3_FINAL_DECISION' AND min(repository_stage)='22_M2_3'
                   AND min(module_title)='Final Offer & Decision Authorization' AND min(acceptance_gate_id)='M2_3_FINAL_OFFER_DECISION_AUTHORIZATION'
                   AND min(acceptance_gate_review_version)=1
                   AND min(acceptance_evidence_code)='M2_3_ACCEPTANCE_SUMMARY'
                   AND min(contract_status)='ACCEPTED' AND min(gate_status)='PASS' AND min(acceptance_evidence_status)='PASS'
                   AND min(expected_canonical_entities)=6029 AND min(observed_canonical_entities)=6029
                   AND min(expected_positive_controls)=120 AND min(observed_positive_controls)=120
                   AND min(expected_negative_controls)=20 AND min(observed_negative_controls)=20
                   AND min(expected_combined_hash)='bf09349b06ede7e5a2ec830c2f9ffe90' AND min(observed_combined_hash)='bf09349b06ede7e5a2ec830c2f9ffe90'
                   AND min(required_source_edge_count)=1 AND min(passed_source_edge_count)=1
                   AND min(source_graph_status)='PASS' AND min(canonical_identity_status)='PASS' AND min(stage_boundary_status)='PASS' AND min(certification_status)='PASS'
                   AND count(*) FILTER (WHERE row_hash IS DISTINCT FROM md5((to_jsonb(s)-'row_hash'-'created_at')::text))=0
              THEN 0 ELSE 1 END)::bigint AS mismatch_count,
        (count(*)=1 AND min(stage_code)='M2_3_FINAL_DECISION' AND min(repository_stage)='22_M2_3'
         AND min(module_title)='Final Offer & Decision Authorization' AND min(acceptance_gate_id)='M2_3_FINAL_OFFER_DECISION_AUTHORIZATION'
         AND min(acceptance_gate_review_version)=1
         AND min(acceptance_evidence_code)='M2_3_ACCEPTANCE_SUMMARY'
         AND min(contract_status)='ACCEPTED' AND min(gate_status)='PASS' AND min(acceptance_evidence_status)='PASS'
         AND min(expected_canonical_entities)=6029 AND min(observed_canonical_entities)=6029
         AND min(expected_positive_controls)=120 AND min(observed_positive_controls)=120
         AND min(expected_negative_controls)=20 AND min(observed_negative_controls)=20
         AND min(expected_combined_hash)='bf09349b06ede7e5a2ec830c2f9ffe90' AND min(observed_combined_hash)='bf09349b06ede7e5a2ec830c2f9ffe90'
         AND min(required_source_edge_count)=1 AND min(passed_source_edge_count)=1
         AND min(source_graph_status)='PASS' AND min(canonical_identity_status)='PASS' AND min(stage_boundary_status)='PASS' AND min(certification_status)='PASS'
         AND count(*) FILTER (WHERE row_hash IS DISTINCT FROM md5((to_jsonb(s)-'row_hash'-'created_at')::text))=0) AS pass_flag,
        'Node M2_3_FINAL_DECISION persisted certification is independently reconstructed from its physical canonical row.'::text AS interpretation
    FROM s
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_018_NODE_04_M2_3_FINAL_DECISION_PHYSICAL_ACCEPTANCE */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    18::smallint,
    'M2_12_POS_018_NODE_04_M2_3_FINAL_DECISION_PHYSICAL_ACCEPTANCE'::text,
    2::smallint,
    'SOURCE_NODE_ACCEPTANCE'::text,
    'Node 4 M2_3_FINAL_DECISION gate, acceptance, physical boundary controls, and source edges are exact'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH gate AS (
        SELECT count(*)::integer AS n,
               count(*) FILTER (WHERE g.result_status='PASS')::integer AS pass_n
        FROM msbf_ctl.acceptance_gate_result g
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=g.run_id
        WHERE g.gate_id='M2_3_FINAL_OFFER_DECISION_AUTHORIZATION' AND g.review_version=1
    ), acceptance AS (
        SELECT count(*)::integer AS n,
               count(*) FILTER (WHERE e.status='PASS')::integer AS pass_n
        FROM msbf_ctl.run_evidence e
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=e.run_id
        WHERE e.evidence_code='M2_3_ACCEPTANCE_SUMMARY'
    ), boundary AS (
        SELECT *
        FROM tmp_cert_m2_12_stage_boundary_observation b
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=b.module1_run_id
        WHERE b.node_sequence=4 AND b.stage_code='M2_3_FINAL_DECISION'
    ), edges AS (
        SELECT count(*)::integer AS n,
               count(*) FILTER (WHERE edge_status='PASS')::integer AS pass_n,
               count(*) FILTER (WHERE source_hash_mismatch_flag OR target_hash_mismatch_flag)::integer AS mismatch_n
        FROM tmp_eval_m2_12_validation_source_edges
        WHERE target_node_code='M2_3_FINAL_DECISION'
    )
    SELECT
        concat_ws('|',
            (SELECT n FROM gate),(SELECT pass_n FROM gate),
            (SELECT n FROM acceptance),(SELECT pass_n FROM acceptance),
            (SELECT required_evidence_rows FROM boundary),
            (SELECT physical_required_evidence_rows FROM boundary),
            (SELECT observed_required_evidence_rows FROM boundary),
            (SELECT duplicate_required_evidence_rows FROM boundary),
            (SELECT (missing_required_evidence_codes<>'')::integer FROM boundary),
            (SELECT nonpass_evidence_rows FROM boundary),
            (SELECT violation_rows FROM boundary),
            (SELECT certification_status FROM boundary),
            (SELECT n FROM edges),(SELECT pass_n FROM edges),(SELECT mismatch_n FROM edges)) AS observed_value,
        '1|1|1|1|6|6|6|0|0|0|0|PASS|1|1|0'::text AS expected_value,
        ((SELECT (n<>1 OR pass_n<>1)::integer FROM gate)
         +(SELECT (n<>1 OR pass_n<>1)::integer FROM acceptance)
         +(SELECT CASE WHEN count(*)=1
                         AND min(required_evidence_rows)=6
                         AND min(physical_required_evidence_rows)=6
                         AND min(observed_required_evidence_rows)=6
                         AND min(duplicate_required_evidence_rows)=0
                         AND min((missing_required_evidence_codes<>'')::integer)=0
                         AND min(nonpass_evidence_rows)=0
                         AND min(violation_rows)=0
                         AND min(certification_status)='PASS'
                       THEN 0 ELSE 1 END FROM boundary)
         +(SELECT (n<>1 OR pass_n<>1 OR mismatch_n<>0)::integer FROM edges))::bigint AS mismatch_count,
        ((SELECT n=1 AND pass_n=1 FROM gate)
         AND (SELECT n=1 AND pass_n=1 FROM acceptance)
         AND (SELECT count(*)=1
                     AND min(required_evidence_rows)=6
                     AND min(physical_required_evidence_rows)=6
                     AND min(observed_required_evidence_rows)=6
                     AND min(duplicate_required_evidence_rows)=0
                     AND min((missing_required_evidence_codes<>'')::integer)=0
                     AND min(nonpass_evidence_rows)=0
                     AND min(violation_rows)=0
                     AND min(certification_status)='PASS' FROM boundary)
         AND (SELECT n=1 AND pass_n=1 AND mismatch_n=0 FROM edges)) AS pass_flag,
        'Independent persisted-state reconstruction uses the exact acceptance gate and summary, the 70-control physical stage-boundary model, and the exact 19-edge source graph for M2_3_FINAL_DECISION.'::text AS interpretation
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_019_NODE_05_M2_4_PORTFOLIO_ACTIVATION_CANONICAL */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    19::smallint,
    'M2_12_POS_019_NODE_05_M2_4_PORTFOLIO_ACTIVATION_CANONICAL'::text,
    2::smallint,
    'SOURCE_NODE_ACCEPTANCE'::text,
    'Node 05 M2_4_PORTFOLIO_ACTIVATION persisted certification is exact'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH s AS (
        SELECT t.* FROM msbf_m2.module2_stage_certification_snapshot t
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id
        WHERE t.certification_node_sequence=5 AND t.stage_code='M2_4_PORTFOLIO_ACTIVATION'
    )
    SELECT
        concat_ws('|',count(*)::text,min(stage_code),min(repository_stage),min(contract_status),min(gate_status),
            min(acceptance_evidence_status),min(observed_canonical_entities)::text,min(observed_positive_controls)::text,
            min(observed_negative_controls)::text,min(observed_combined_hash),min(source_graph_status),min(stage_boundary_status),
            min(certification_status),count(*) FILTER (WHERE row_hash IS DISTINCT FROM md5((to_jsonb(s)-'row_hash'-'created_at')::text))::text) AS observed_value,
        '1|M2_4_PORTFOLIO_ACTIVATION|23_M2_4|ACCEPTED|PASS|PASS|6212|120|20|117450a3eea7bb3d3c74d18cc3c8e96a|PASS|PASS|PASS|0'::text AS expected_value,
        (CASE WHEN count(*)=1 AND min(stage_code)='M2_4_PORTFOLIO_ACTIVATION' AND min(repository_stage)='23_M2_4'
                   AND min(module_title)='Booking, Funding & Portfolio Activation' AND min(acceptance_gate_id)='M2_4_BOOKING_FUNDING_PORTFOLIO_ACTIVATION'
                   AND min(acceptance_gate_review_version)=1
                   AND min(acceptance_evidence_code)='M2_4_ACCEPTANCE_SUMMARY'
                   AND min(contract_status)='ACCEPTED' AND min(gate_status)='PASS' AND min(acceptance_evidence_status)='PASS'
                   AND min(expected_canonical_entities)=6212 AND min(observed_canonical_entities)=6212
                   AND min(expected_positive_controls)=120 AND min(observed_positive_controls)=120
                   AND min(expected_negative_controls)=20 AND min(observed_negative_controls)=20
                   AND min(expected_combined_hash)='117450a3eea7bb3d3c74d18cc3c8e96a' AND min(observed_combined_hash)='117450a3eea7bb3d3c74d18cc3c8e96a'
                   AND min(required_source_edge_count)=1 AND min(passed_source_edge_count)=1
                   AND min(source_graph_status)='PASS' AND min(canonical_identity_status)='PASS' AND min(stage_boundary_status)='PASS' AND min(certification_status)='PASS'
                   AND count(*) FILTER (WHERE row_hash IS DISTINCT FROM md5((to_jsonb(s)-'row_hash'-'created_at')::text))=0
              THEN 0 ELSE 1 END)::bigint AS mismatch_count,
        (count(*)=1 AND min(stage_code)='M2_4_PORTFOLIO_ACTIVATION' AND min(repository_stage)='23_M2_4'
         AND min(module_title)='Booking, Funding & Portfolio Activation' AND min(acceptance_gate_id)='M2_4_BOOKING_FUNDING_PORTFOLIO_ACTIVATION'
         AND min(acceptance_gate_review_version)=1
         AND min(acceptance_evidence_code)='M2_4_ACCEPTANCE_SUMMARY'
         AND min(contract_status)='ACCEPTED' AND min(gate_status)='PASS' AND min(acceptance_evidence_status)='PASS'
         AND min(expected_canonical_entities)=6212 AND min(observed_canonical_entities)=6212
         AND min(expected_positive_controls)=120 AND min(observed_positive_controls)=120
         AND min(expected_negative_controls)=20 AND min(observed_negative_controls)=20
         AND min(expected_combined_hash)='117450a3eea7bb3d3c74d18cc3c8e96a' AND min(observed_combined_hash)='117450a3eea7bb3d3c74d18cc3c8e96a'
         AND min(required_source_edge_count)=1 AND min(passed_source_edge_count)=1
         AND min(source_graph_status)='PASS' AND min(canonical_identity_status)='PASS' AND min(stage_boundary_status)='PASS' AND min(certification_status)='PASS'
         AND count(*) FILTER (WHERE row_hash IS DISTINCT FROM md5((to_jsonb(s)-'row_hash'-'created_at')::text))=0) AS pass_flag,
        'Node M2_4_PORTFOLIO_ACTIVATION persisted certification is independently reconstructed from its physical canonical row.'::text AS interpretation
    FROM s
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_020_NODE_05_M2_4_PORTFOLIO_ACTIVATION_PHYSICAL_ACCEPTANCE */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    20::smallint,
    'M2_12_POS_020_NODE_05_M2_4_PORTFOLIO_ACTIVATION_PHYSICAL_ACCEPTANCE'::text,
    2::smallint,
    'SOURCE_NODE_ACCEPTANCE'::text,
    'Node 5 M2_4_PORTFOLIO_ACTIVATION gate, acceptance, physical boundary controls, and source edges are exact'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH gate AS (
        SELECT count(*)::integer AS n,
               count(*) FILTER (WHERE g.result_status='PASS')::integer AS pass_n
        FROM msbf_ctl.acceptance_gate_result g
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=g.run_id
        WHERE g.gate_id='M2_4_BOOKING_FUNDING_PORTFOLIO_ACTIVATION' AND g.review_version=1
    ), acceptance AS (
        SELECT count(*)::integer AS n,
               count(*) FILTER (WHERE e.status='PASS')::integer AS pass_n
        FROM msbf_ctl.run_evidence e
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=e.run_id
        WHERE e.evidence_code='M2_4_ACCEPTANCE_SUMMARY'
    ), boundary AS (
        SELECT *
        FROM tmp_cert_m2_12_stage_boundary_observation b
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=b.module1_run_id
        WHERE b.node_sequence=5 AND b.stage_code='M2_4_PORTFOLIO_ACTIVATION'
    ), edges AS (
        SELECT count(*)::integer AS n,
               count(*) FILTER (WHERE edge_status='PASS')::integer AS pass_n,
               count(*) FILTER (WHERE source_hash_mismatch_flag OR target_hash_mismatch_flag)::integer AS mismatch_n
        FROM tmp_eval_m2_12_validation_source_edges
        WHERE target_node_code='M2_4_PORTFOLIO_ACTIVATION'
    )
    SELECT
        concat_ws('|',
            (SELECT n FROM gate),(SELECT pass_n FROM gate),
            (SELECT n FROM acceptance),(SELECT pass_n FROM acceptance),
            (SELECT required_evidence_rows FROM boundary),
            (SELECT physical_required_evidence_rows FROM boundary),
            (SELECT observed_required_evidence_rows FROM boundary),
            (SELECT duplicate_required_evidence_rows FROM boundary),
            (SELECT (missing_required_evidence_codes<>'')::integer FROM boundary),
            (SELECT nonpass_evidence_rows FROM boundary),
            (SELECT violation_rows FROM boundary),
            (SELECT certification_status FROM boundary),
            (SELECT n FROM edges),(SELECT pass_n FROM edges),(SELECT mismatch_n FROM edges)) AS observed_value,
        '1|1|1|1|4|4|4|0|0|0|0|PASS|1|1|0'::text AS expected_value,
        ((SELECT (n<>1 OR pass_n<>1)::integer FROM gate)
         +(SELECT (n<>1 OR pass_n<>1)::integer FROM acceptance)
         +(SELECT CASE WHEN count(*)=1
                         AND min(required_evidence_rows)=4
                         AND min(physical_required_evidence_rows)=4
                         AND min(observed_required_evidence_rows)=4
                         AND min(duplicate_required_evidence_rows)=0
                         AND min((missing_required_evidence_codes<>'')::integer)=0
                         AND min(nonpass_evidence_rows)=0
                         AND min(violation_rows)=0
                         AND min(certification_status)='PASS'
                       THEN 0 ELSE 1 END FROM boundary)
         +(SELECT (n<>1 OR pass_n<>1 OR mismatch_n<>0)::integer FROM edges))::bigint AS mismatch_count,
        ((SELECT n=1 AND pass_n=1 FROM gate)
         AND (SELECT n=1 AND pass_n=1 FROM acceptance)
         AND (SELECT count(*)=1
                     AND min(required_evidence_rows)=4
                     AND min(physical_required_evidence_rows)=4
                     AND min(observed_required_evidence_rows)=4
                     AND min(duplicate_required_evidence_rows)=0
                     AND min((missing_required_evidence_codes<>'')::integer)=0
                     AND min(nonpass_evidence_rows)=0
                     AND min(violation_rows)=0
                     AND min(certification_status)='PASS' FROM boundary)
         AND (SELECT n=1 AND pass_n=1 AND mismatch_n=0 FROM edges)) AS pass_flag,
        'Independent persisted-state reconstruction uses the exact acceptance gate and summary, the 70-control physical stage-boundary model, and the exact 19-edge source graph for M2_4_PORTFOLIO_ACTIVATION.'::text AS interpretation
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_021_NODE_06_M2_5_DAILY_MONITORING_CANONICAL */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    21::smallint,
    'M2_12_POS_021_NODE_06_M2_5_DAILY_MONITORING_CANONICAL'::text,
    2::smallint,
    'SOURCE_NODE_ACCEPTANCE'::text,
    'Node 06 M2_5_DAILY_MONITORING persisted certification is exact'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH s AS (
        SELECT t.* FROM msbf_m2.module2_stage_certification_snapshot t
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id
        WHERE t.certification_node_sequence=6 AND t.stage_code='M2_5_DAILY_MONITORING'
    )
    SELECT
        concat_ws('|',count(*)::text,min(stage_code),min(repository_stage),min(contract_status),min(gate_status),
            min(acceptance_evidence_status),min(observed_canonical_entities)::text,min(observed_positive_controls)::text,
            min(observed_negative_controls)::text,min(observed_combined_hash),min(source_graph_status),min(stage_boundary_status),
            min(certification_status),count(*) FILTER (WHERE row_hash IS DISTINCT FROM md5((to_jsonb(s)-'row_hash'-'created_at')::text))::text) AS observed_value,
        '1|M2_5_DAILY_MONITORING|24_M2_5|ACCEPTED|PASS|PASS|7536|120|20|18e1c444aa1b02ee5bd3539d7c477adc|PASS|PASS|PASS|0'::text AS expected_value,
        (CASE WHEN count(*)=1 AND min(stage_code)='M2_5_DAILY_MONITORING' AND min(repository_stage)='24_M2_5'
                   AND min(module_title)='Daily Remittance, Exposure & Portfolio Monitoring' AND min(acceptance_gate_id)='M2_5_DAILY_REMITTANCE_EXPOSURE_PORTFOLIO_MONITORING'
                   AND min(acceptance_gate_review_version)=1
                   AND min(acceptance_evidence_code)='M2_5_ACCEPTANCE_SUMMARY'
                   AND min(contract_status)='ACCEPTED' AND min(gate_status)='PASS' AND min(acceptance_evidence_status)='PASS'
                   AND min(expected_canonical_entities)=7536 AND min(observed_canonical_entities)=7536
                   AND min(expected_positive_controls)=120 AND min(observed_positive_controls)=120
                   AND min(expected_negative_controls)=20 AND min(observed_negative_controls)=20
                   AND min(expected_combined_hash)='18e1c444aa1b02ee5bd3539d7c477adc' AND min(observed_combined_hash)='18e1c444aa1b02ee5bd3539d7c477adc'
                   AND min(required_source_edge_count)=2 AND min(passed_source_edge_count)=2
                   AND min(source_graph_status)='PASS' AND min(canonical_identity_status)='PASS' AND min(stage_boundary_status)='PASS' AND min(certification_status)='PASS'
                   AND count(*) FILTER (WHERE row_hash IS DISTINCT FROM md5((to_jsonb(s)-'row_hash'-'created_at')::text))=0
              THEN 0 ELSE 1 END)::bigint AS mismatch_count,
        (count(*)=1 AND min(stage_code)='M2_5_DAILY_MONITORING' AND min(repository_stage)='24_M2_5'
         AND min(module_title)='Daily Remittance, Exposure & Portfolio Monitoring' AND min(acceptance_gate_id)='M2_5_DAILY_REMITTANCE_EXPOSURE_PORTFOLIO_MONITORING'
         AND min(acceptance_gate_review_version)=1
         AND min(acceptance_evidence_code)='M2_5_ACCEPTANCE_SUMMARY'
         AND min(contract_status)='ACCEPTED' AND min(gate_status)='PASS' AND min(acceptance_evidence_status)='PASS'
         AND min(expected_canonical_entities)=7536 AND min(observed_canonical_entities)=7536
         AND min(expected_positive_controls)=120 AND min(observed_positive_controls)=120
         AND min(expected_negative_controls)=20 AND min(observed_negative_controls)=20
         AND min(expected_combined_hash)='18e1c444aa1b02ee5bd3539d7c477adc' AND min(observed_combined_hash)='18e1c444aa1b02ee5bd3539d7c477adc'
         AND min(required_source_edge_count)=2 AND min(passed_source_edge_count)=2
         AND min(source_graph_status)='PASS' AND min(canonical_identity_status)='PASS' AND min(stage_boundary_status)='PASS' AND min(certification_status)='PASS'
         AND count(*) FILTER (WHERE row_hash IS DISTINCT FROM md5((to_jsonb(s)-'row_hash'-'created_at')::text))=0) AS pass_flag,
        'Node M2_5_DAILY_MONITORING persisted certification is independently reconstructed from its physical canonical row.'::text AS interpretation
    FROM s
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_022_NODE_06_M2_5_DAILY_MONITORING_PHYSICAL_ACCEPTANCE */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    22::smallint,
    'M2_12_POS_022_NODE_06_M2_5_DAILY_MONITORING_PHYSICAL_ACCEPTANCE'::text,
    2::smallint,
    'SOURCE_NODE_ACCEPTANCE'::text,
    'Node 6 M2_5_DAILY_MONITORING gate, acceptance, physical boundary controls, and source edges are exact'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH gate AS (
        SELECT count(*)::integer AS n,
               count(*) FILTER (WHERE g.result_status='PASS')::integer AS pass_n
        FROM msbf_ctl.acceptance_gate_result g
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=g.run_id
        WHERE g.gate_id='M2_5_DAILY_REMITTANCE_EXPOSURE_PORTFOLIO_MONITORING' AND g.review_version=1
    ), acceptance AS (
        SELECT count(*)::integer AS n,
               count(*) FILTER (WHERE e.status='PASS')::integer AS pass_n
        FROM msbf_ctl.run_evidence e
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=e.run_id
        WHERE e.evidence_code='M2_5_ACCEPTANCE_SUMMARY'
    ), boundary AS (
        SELECT *
        FROM tmp_cert_m2_12_stage_boundary_observation b
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=b.module1_run_id
        WHERE b.node_sequence=6 AND b.stage_code='M2_5_DAILY_MONITORING'
    ), edges AS (
        SELECT count(*)::integer AS n,
               count(*) FILTER (WHERE edge_status='PASS')::integer AS pass_n,
               count(*) FILTER (WHERE source_hash_mismatch_flag OR target_hash_mismatch_flag)::integer AS mismatch_n
        FROM tmp_eval_m2_12_validation_source_edges
        WHERE target_node_code='M2_5_DAILY_MONITORING'
    )
    SELECT
        concat_ws('|',
            (SELECT n FROM gate),(SELECT pass_n FROM gate),
            (SELECT n FROM acceptance),(SELECT pass_n FROM acceptance),
            (SELECT required_evidence_rows FROM boundary),
            (SELECT physical_required_evidence_rows FROM boundary),
            (SELECT observed_required_evidence_rows FROM boundary),
            (SELECT duplicate_required_evidence_rows FROM boundary),
            (SELECT (missing_required_evidence_codes<>'')::integer FROM boundary),
            (SELECT nonpass_evidence_rows FROM boundary),
            (SELECT violation_rows FROM boundary),
            (SELECT certification_status FROM boundary),
            (SELECT n FROM edges),(SELECT pass_n FROM edges),(SELECT mismatch_n FROM edges)) AS observed_value,
        '1|1|1|1|6|6|6|0|0|0|0|PASS|2|2|0'::text AS expected_value,
        ((SELECT (n<>1 OR pass_n<>1)::integer FROM gate)
         +(SELECT (n<>1 OR pass_n<>1)::integer FROM acceptance)
         +(SELECT CASE WHEN count(*)=1
                         AND min(required_evidence_rows)=6
                         AND min(physical_required_evidence_rows)=6
                         AND min(observed_required_evidence_rows)=6
                         AND min(duplicate_required_evidence_rows)=0
                         AND min((missing_required_evidence_codes<>'')::integer)=0
                         AND min(nonpass_evidence_rows)=0
                         AND min(violation_rows)=0
                         AND min(certification_status)='PASS'
                       THEN 0 ELSE 1 END FROM boundary)
         +(SELECT (n<>2 OR pass_n<>2 OR mismatch_n<>0)::integer FROM edges))::bigint AS mismatch_count,
        ((SELECT n=1 AND pass_n=1 FROM gate)
         AND (SELECT n=1 AND pass_n=1 FROM acceptance)
         AND (SELECT count(*)=1
                     AND min(required_evidence_rows)=6
                     AND min(physical_required_evidence_rows)=6
                     AND min(observed_required_evidence_rows)=6
                     AND min(duplicate_required_evidence_rows)=0
                     AND min((missing_required_evidence_codes<>'')::integer)=0
                     AND min(nonpass_evidence_rows)=0
                     AND min(violation_rows)=0
                     AND min(certification_status)='PASS' FROM boundary)
         AND (SELECT n=2 AND pass_n=2 AND mismatch_n=0 FROM edges)) AS pass_flag,
        'Independent persisted-state reconstruction uses the exact acceptance gate and summary, the 70-control physical stage-boundary model, and the exact 19-edge source graph for M2_5_DAILY_MONITORING.'::text AS interpretation
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_023_NODE_07_M2_6_INTERVENTION_STRATEGY_CANONICAL */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    23::smallint,
    'M2_12_POS_023_NODE_07_M2_6_INTERVENTION_STRATEGY_CANONICAL'::text,
    2::smallint,
    'SOURCE_NODE_ACCEPTANCE'::text,
    'Node 07 M2_6_INTERVENTION_STRATEGY persisted certification is exact'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH s AS (
        SELECT t.* FROM msbf_m2.module2_stage_certification_snapshot t
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id
        WHERE t.certification_node_sequence=7 AND t.stage_code='M2_6_INTERVENTION_STRATEGY'
    )
    SELECT
        concat_ws('|',count(*)::text,min(stage_code),min(repository_stage),min(contract_status),min(gate_status),
            min(acceptance_evidence_status),min(observed_canonical_entities)::text,min(observed_positive_controls)::text,
            min(observed_negative_controls)::text,min(observed_combined_hash),min(source_graph_status),min(stage_boundary_status),
            min(certification_status),count(*) FILTER (WHERE row_hash IS DISTINCT FROM md5((to_jsonb(s)-'row_hash'-'created_at')::text))::text) AS observed_value,
        '1|M2_6_INTERVENTION_STRATEGY|25_M2_6|ACCEPTED|PASS|PASS|284|120|20|868125bff29270490cab4d2e55cb1388|PASS|PASS|PASS|0'::text AS expected_value,
        (CASE WHEN count(*)=1 AND min(stage_code)='M2_6_INTERVENTION_STRATEGY' AND min(repository_stage)='25_M2_6'
                   AND min(module_title)='Early Warning, Intervention & Servicing Strategy' AND min(acceptance_gate_id)='M2_6_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY'
                   AND min(acceptance_gate_review_version)=1
                   AND min(acceptance_evidence_code)='M2_6_ACCEPTANCE_SUMMARY'
                   AND min(contract_status)='ACCEPTED' AND min(gate_status)='PASS' AND min(acceptance_evidence_status)='PASS'
                   AND min(expected_canonical_entities)=284 AND min(observed_canonical_entities)=284
                   AND min(expected_positive_controls)=120 AND min(observed_positive_controls)=120
                   AND min(expected_negative_controls)=20 AND min(observed_negative_controls)=20
                   AND min(expected_combined_hash)='868125bff29270490cab4d2e55cb1388' AND min(observed_combined_hash)='868125bff29270490cab4d2e55cb1388'
                   AND min(required_source_edge_count)=1 AND min(passed_source_edge_count)=1
                   AND min(source_graph_status)='PASS' AND min(canonical_identity_status)='PASS' AND min(stage_boundary_status)='PASS' AND min(certification_status)='PASS'
                   AND count(*) FILTER (WHERE row_hash IS DISTINCT FROM md5((to_jsonb(s)-'row_hash'-'created_at')::text))=0
              THEN 0 ELSE 1 END)::bigint AS mismatch_count,
        (count(*)=1 AND min(stage_code)='M2_6_INTERVENTION_STRATEGY' AND min(repository_stage)='25_M2_6'
         AND min(module_title)='Early Warning, Intervention & Servicing Strategy' AND min(acceptance_gate_id)='M2_6_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY'
         AND min(acceptance_gate_review_version)=1
         AND min(acceptance_evidence_code)='M2_6_ACCEPTANCE_SUMMARY'
         AND min(contract_status)='ACCEPTED' AND min(gate_status)='PASS' AND min(acceptance_evidence_status)='PASS'
         AND min(expected_canonical_entities)=284 AND min(observed_canonical_entities)=284
         AND min(expected_positive_controls)=120 AND min(observed_positive_controls)=120
         AND min(expected_negative_controls)=20 AND min(observed_negative_controls)=20
         AND min(expected_combined_hash)='868125bff29270490cab4d2e55cb1388' AND min(observed_combined_hash)='868125bff29270490cab4d2e55cb1388'
         AND min(required_source_edge_count)=1 AND min(passed_source_edge_count)=1
         AND min(source_graph_status)='PASS' AND min(canonical_identity_status)='PASS' AND min(stage_boundary_status)='PASS' AND min(certification_status)='PASS'
         AND count(*) FILTER (WHERE row_hash IS DISTINCT FROM md5((to_jsonb(s)-'row_hash'-'created_at')::text))=0) AS pass_flag,
        'Node M2_6_INTERVENTION_STRATEGY persisted certification is independently reconstructed from its physical canonical row.'::text AS interpretation
    FROM s
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_024_NODE_07_M2_6_INTERVENTION_STRATEGY_PHYSICAL_ACCEPTANCE */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    24::smallint,
    'M2_12_POS_024_NODE_07_M2_6_INTERVENTION_STRATEGY_PHYSICAL_ACCEPTANCE'::text,
    2::smallint,
    'SOURCE_NODE_ACCEPTANCE'::text,
    'Node 7 M2_6_INTERVENTION_STRATEGY gate, acceptance, physical boundary controls, and source edges are exact'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH gate AS (
        SELECT count(*)::integer AS n,
               count(*) FILTER (WHERE g.result_status='PASS')::integer AS pass_n
        FROM msbf_ctl.acceptance_gate_result g
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=g.run_id
        WHERE g.gate_id='M2_6_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY' AND g.review_version=1
    ), acceptance AS (
        SELECT count(*)::integer AS n,
               count(*) FILTER (WHERE e.status='PASS')::integer AS pass_n
        FROM msbf_ctl.run_evidence e
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=e.run_id
        WHERE e.evidence_code='M2_6_ACCEPTANCE_SUMMARY'
    ), boundary AS (
        SELECT *
        FROM tmp_cert_m2_12_stage_boundary_observation b
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=b.module1_run_id
        WHERE b.node_sequence=7 AND b.stage_code='M2_6_INTERVENTION_STRATEGY'
    ), edges AS (
        SELECT count(*)::integer AS n,
               count(*) FILTER (WHERE edge_status='PASS')::integer AS pass_n,
               count(*) FILTER (WHERE source_hash_mismatch_flag OR target_hash_mismatch_flag)::integer AS mismatch_n
        FROM tmp_eval_m2_12_validation_source_edges
        WHERE target_node_code='M2_6_INTERVENTION_STRATEGY'
    )
    SELECT
        concat_ws('|',
            (SELECT n FROM gate),(SELECT pass_n FROM gate),
            (SELECT n FROM acceptance),(SELECT pass_n FROM acceptance),
            (SELECT required_evidence_rows FROM boundary),
            (SELECT physical_required_evidence_rows FROM boundary),
            (SELECT observed_required_evidence_rows FROM boundary),
            (SELECT duplicate_required_evidence_rows FROM boundary),
            (SELECT (missing_required_evidence_codes<>'')::integer FROM boundary),
            (SELECT nonpass_evidence_rows FROM boundary),
            (SELECT violation_rows FROM boundary),
            (SELECT certification_status FROM boundary),
            (SELECT n FROM edges),(SELECT pass_n FROM edges),(SELECT mismatch_n FROM edges)) AS observed_value,
        '1|1|1|1|4|4|4|0|0|0|0|PASS|1|1|0'::text AS expected_value,
        ((SELECT (n<>1 OR pass_n<>1)::integer FROM gate)
         +(SELECT (n<>1 OR pass_n<>1)::integer FROM acceptance)
         +(SELECT CASE WHEN count(*)=1
                         AND min(required_evidence_rows)=4
                         AND min(physical_required_evidence_rows)=4
                         AND min(observed_required_evidence_rows)=4
                         AND min(duplicate_required_evidence_rows)=0
                         AND min((missing_required_evidence_codes<>'')::integer)=0
                         AND min(nonpass_evidence_rows)=0
                         AND min(violation_rows)=0
                         AND min(certification_status)='PASS'
                       THEN 0 ELSE 1 END FROM boundary)
         +(SELECT (n<>1 OR pass_n<>1 OR mismatch_n<>0)::integer FROM edges))::bigint AS mismatch_count,
        ((SELECT n=1 AND pass_n=1 FROM gate)
         AND (SELECT n=1 AND pass_n=1 FROM acceptance)
         AND (SELECT count(*)=1
                     AND min(required_evidence_rows)=4
                     AND min(physical_required_evidence_rows)=4
                     AND min(observed_required_evidence_rows)=4
                     AND min(duplicate_required_evidence_rows)=0
                     AND min((missing_required_evidence_codes<>'')::integer)=0
                     AND min(nonpass_evidence_rows)=0
                     AND min(violation_rows)=0
                     AND min(certification_status)='PASS' FROM boundary)
         AND (SELECT n=1 AND pass_n=1 AND mismatch_n=0 FROM edges)) AS pass_flag,
        'Independent persisted-state reconstruction uses the exact acceptance gate and summary, the 70-control physical stage-boundary model, and the exact 19-edge source graph for M2_6_INTERVENTION_STRATEGY.'::text AS interpretation
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_025_NODE_08_M2_7_OPERATIONAL_ACTIVATION_CANONICAL */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    25::smallint,
    'M2_12_POS_025_NODE_08_M2_7_OPERATIONAL_ACTIVATION_CANONICAL'::text,
    2::smallint,
    'SOURCE_NODE_ACCEPTANCE'::text,
    'Node 08 M2_7_OPERATIONAL_ACTIVATION persisted certification is exact'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH s AS (
        SELECT t.* FROM msbf_m2.module2_stage_certification_snapshot t
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id
        WHERE t.certification_node_sequence=8 AND t.stage_code='M2_7_OPERATIONAL_ACTIVATION'
    )
    SELECT
        concat_ws('|',count(*)::text,min(stage_code),min(repository_stage),min(contract_status),min(gate_status),
            min(acceptance_evidence_status),min(observed_canonical_entities)::text,min(observed_positive_controls)::text,
            min(observed_negative_controls)::text,min(observed_combined_hash),min(source_graph_status),min(stage_boundary_status),
            min(certification_status),count(*) FILTER (WHERE row_hash IS DISTINCT FROM md5((to_jsonb(s)-'row_hash'-'created_at')::text))::text) AS observed_value,
        '1|M2_7_OPERATIONAL_ACTIVATION|26_M2_7|ACCEPTED|PASS|PASS|341|120|20|c8e3a472afd2a16b1183677324e9db98|PASS|PASS|PASS|0'::text AS expected_value,
        (CASE WHEN count(*)=1 AND min(stage_code)='M2_7_OPERATIONAL_ACTIVATION' AND min(repository_stage)='26_M2_7'
                   AND min(module_title)='Operational Activation & Account Setup' AND min(acceptance_gate_id)='M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP'
                   AND min(acceptance_gate_review_version)=1
                   AND min(acceptance_evidence_code)='M2_7_ACCEPTANCE_SUMMARY'
                   AND min(contract_status)='ACCEPTED' AND min(gate_status)='PASS' AND min(acceptance_evidence_status)='PASS'
                   AND min(expected_canonical_entities)=341 AND min(observed_canonical_entities)=341
                   AND min(expected_positive_controls)=120 AND min(observed_positive_controls)=120
                   AND min(expected_negative_controls)=20 AND min(observed_negative_controls)=20
                   AND min(expected_combined_hash)='c8e3a472afd2a16b1183677324e9db98' AND min(observed_combined_hash)='c8e3a472afd2a16b1183677324e9db98'
                   AND min(required_source_edge_count)=1 AND min(passed_source_edge_count)=1
                   AND min(source_graph_status)='PASS' AND min(canonical_identity_status)='PASS' AND min(stage_boundary_status)='PASS' AND min(certification_status)='PASS'
                   AND count(*) FILTER (WHERE row_hash IS DISTINCT FROM md5((to_jsonb(s)-'row_hash'-'created_at')::text))=0
              THEN 0 ELSE 1 END)::bigint AS mismatch_count,
        (count(*)=1 AND min(stage_code)='M2_7_OPERATIONAL_ACTIVATION' AND min(repository_stage)='26_M2_7'
         AND min(module_title)='Operational Activation & Account Setup' AND min(acceptance_gate_id)='M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP'
         AND min(acceptance_gate_review_version)=1
         AND min(acceptance_evidence_code)='M2_7_ACCEPTANCE_SUMMARY'
         AND min(contract_status)='ACCEPTED' AND min(gate_status)='PASS' AND min(acceptance_evidence_status)='PASS'
         AND min(expected_canonical_entities)=341 AND min(observed_canonical_entities)=341
         AND min(expected_positive_controls)=120 AND min(observed_positive_controls)=120
         AND min(expected_negative_controls)=20 AND min(observed_negative_controls)=20
         AND min(expected_combined_hash)='c8e3a472afd2a16b1183677324e9db98' AND min(observed_combined_hash)='c8e3a472afd2a16b1183677324e9db98'
         AND min(required_source_edge_count)=1 AND min(passed_source_edge_count)=1
         AND min(source_graph_status)='PASS' AND min(canonical_identity_status)='PASS' AND min(stage_boundary_status)='PASS' AND min(certification_status)='PASS'
         AND count(*) FILTER (WHERE row_hash IS DISTINCT FROM md5((to_jsonb(s)-'row_hash'-'created_at')::text))=0) AS pass_flag,
        'Node M2_7_OPERATIONAL_ACTIVATION persisted certification is independently reconstructed from its physical canonical row.'::text AS interpretation
    FROM s
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_026_NODE_08_M2_7_OPERATIONAL_ACTIVATION_PHYSICAL_ACCEPTANCE */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    26::smallint,
    'M2_12_POS_026_NODE_08_M2_7_OPERATIONAL_ACTIVATION_PHYSICAL_ACCEPTANCE'::text,
    2::smallint,
    'SOURCE_NODE_ACCEPTANCE'::text,
    'Node 8 M2_7_OPERATIONAL_ACTIVATION gate, acceptance, physical boundary controls, and source edges are exact'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH gate AS (
        SELECT count(*)::integer AS n,
               count(*) FILTER (WHERE g.result_status='PASS')::integer AS pass_n
        FROM msbf_ctl.acceptance_gate_result g
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=g.run_id
        WHERE g.gate_id='M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP' AND g.review_version=1
    ), acceptance AS (
        SELECT count(*)::integer AS n,
               count(*) FILTER (WHERE e.status='PASS')::integer AS pass_n
        FROM msbf_ctl.run_evidence e
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=e.run_id
        WHERE e.evidence_code='M2_7_ACCEPTANCE_SUMMARY'
    ), boundary AS (
        SELECT *
        FROM tmp_cert_m2_12_stage_boundary_observation b
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=b.module1_run_id
        WHERE b.node_sequence=8 AND b.stage_code='M2_7_OPERATIONAL_ACTIVATION'
    ), edges AS (
        SELECT count(*)::integer AS n,
               count(*) FILTER (WHERE edge_status='PASS')::integer AS pass_n,
               count(*) FILTER (WHERE source_hash_mismatch_flag OR target_hash_mismatch_flag)::integer AS mismatch_n
        FROM tmp_eval_m2_12_validation_source_edges
        WHERE target_node_code='M2_7_OPERATIONAL_ACTIVATION'
    )
    SELECT
        concat_ws('|',
            (SELECT n FROM gate),(SELECT pass_n FROM gate),
            (SELECT n FROM acceptance),(SELECT pass_n FROM acceptance),
            (SELECT required_evidence_rows FROM boundary),
            (SELECT physical_required_evidence_rows FROM boundary),
            (SELECT observed_required_evidence_rows FROM boundary),
            (SELECT duplicate_required_evidence_rows FROM boundary),
            (SELECT (missing_required_evidence_codes<>'')::integer FROM boundary),
            (SELECT nonpass_evidence_rows FROM boundary),
            (SELECT violation_rows FROM boundary),
            (SELECT certification_status FROM boundary),
            (SELECT n FROM edges),(SELECT pass_n FROM edges),(SELECT mismatch_n FROM edges)) AS observed_value,
        '1|1|1|1|7|7|7|0|0|0|0|PASS|1|1|0'::text AS expected_value,
        ((SELECT (n<>1 OR pass_n<>1)::integer FROM gate)
         +(SELECT (n<>1 OR pass_n<>1)::integer FROM acceptance)
         +(SELECT CASE WHEN count(*)=1
                         AND min(required_evidence_rows)=7
                         AND min(physical_required_evidence_rows)=7
                         AND min(observed_required_evidence_rows)=7
                         AND min(duplicate_required_evidence_rows)=0
                         AND min((missing_required_evidence_codes<>'')::integer)=0
                         AND min(nonpass_evidence_rows)=0
                         AND min(violation_rows)=0
                         AND min(certification_status)='PASS'
                       THEN 0 ELSE 1 END FROM boundary)
         +(SELECT (n<>1 OR pass_n<>1 OR mismatch_n<>0)::integer FROM edges))::bigint AS mismatch_count,
        ((SELECT n=1 AND pass_n=1 FROM gate)
         AND (SELECT n=1 AND pass_n=1 FROM acceptance)
         AND (SELECT count(*)=1
                     AND min(required_evidence_rows)=7
                     AND min(physical_required_evidence_rows)=7
                     AND min(observed_required_evidence_rows)=7
                     AND min(duplicate_required_evidence_rows)=0
                     AND min((missing_required_evidence_codes<>'')::integer)=0
                     AND min(nonpass_evidence_rows)=0
                     AND min(violation_rows)=0
                     AND min(certification_status)='PASS' FROM boundary)
         AND (SELECT n=1 AND pass_n=1 AND mismatch_n=0 FROM edges)) AS pass_flag,
        'Independent persisted-state reconstruction uses the exact acceptance gate and summary, the 70-control physical stage-boundary model, and the exact 19-edge source graph for M2_7_OPERATIONAL_ACTIVATION.'::text AS interpretation
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_027_NODE_09_M2_8_SERVICING_EXECUTION_CANONICAL */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    27::smallint,
    'M2_12_POS_027_NODE_09_M2_8_SERVICING_EXECUTION_CANONICAL'::text,
    2::smallint,
    'SOURCE_NODE_ACCEPTANCE'::text,
    'Node 09 M2_8_SERVICING_EXECUTION persisted certification is exact'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH s AS (
        SELECT t.* FROM msbf_m2.module2_stage_certification_snapshot t
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id
        WHERE t.certification_node_sequence=9 AND t.stage_code='M2_8_SERVICING_EXECUTION'
    )
    SELECT
        concat_ws('|',count(*)::text,min(stage_code),min(repository_stage),min(contract_status),min(gate_status),
            min(acceptance_evidence_status),min(observed_canonical_entities)::text,min(observed_positive_controls)::text,
            min(observed_negative_controls)::text,min(observed_combined_hash),min(source_graph_status),min(stage_boundary_status),
            min(certification_status),count(*) FILTER (WHERE row_hash IS DISTINCT FROM md5((to_jsonb(s)-'row_hash'-'created_at')::text))::text) AS observed_value,
        '1|M2_8_SERVICING_EXECUTION|27_M2_8|ACCEPTED|PASS|PASS|367|120|20|ab32d80ba20c2c8f0a6ec9ec97c2ed26|PASS|PASS|PASS|0'::text AS expected_value,
        (CASE WHEN count(*)=1 AND min(stage_code)='M2_8_SERVICING_EXECUTION' AND min(repository_stage)='27_M2_8'
                   AND min(module_title)='Servicing Execution Simulation, Payment Processing & Account Lifecycle Control' AND min(acceptance_gate_id)='M2_8_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONTROL'
                   AND min(acceptance_gate_review_version)=1
                   AND min(acceptance_evidence_code)='M2_8_ACCEPTANCE_SUMMARY'
                   AND min(contract_status)='ACCEPTED' AND min(gate_status)='PASS' AND min(acceptance_evidence_status)='PASS'
                   AND min(expected_canonical_entities)=367 AND min(observed_canonical_entities)=367
                   AND min(expected_positive_controls)=120 AND min(observed_positive_controls)=120
                   AND min(expected_negative_controls)=20 AND min(observed_negative_controls)=20
                   AND min(expected_combined_hash)='ab32d80ba20c2c8f0a6ec9ec97c2ed26' AND min(observed_combined_hash)='ab32d80ba20c2c8f0a6ec9ec97c2ed26'
                   AND min(required_source_edge_count)=1 AND min(passed_source_edge_count)=1
                   AND min(source_graph_status)='PASS' AND min(canonical_identity_status)='PASS' AND min(stage_boundary_status)='PASS' AND min(certification_status)='PASS'
                   AND count(*) FILTER (WHERE row_hash IS DISTINCT FROM md5((to_jsonb(s)-'row_hash'-'created_at')::text))=0
              THEN 0 ELSE 1 END)::bigint AS mismatch_count,
        (count(*)=1 AND min(stage_code)='M2_8_SERVICING_EXECUTION' AND min(repository_stage)='27_M2_8'
         AND min(module_title)='Servicing Execution Simulation, Payment Processing & Account Lifecycle Control' AND min(acceptance_gate_id)='M2_8_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONTROL'
         AND min(acceptance_gate_review_version)=1
         AND min(acceptance_evidence_code)='M2_8_ACCEPTANCE_SUMMARY'
         AND min(contract_status)='ACCEPTED' AND min(gate_status)='PASS' AND min(acceptance_evidence_status)='PASS'
         AND min(expected_canonical_entities)=367 AND min(observed_canonical_entities)=367
         AND min(expected_positive_controls)=120 AND min(observed_positive_controls)=120
         AND min(expected_negative_controls)=20 AND min(observed_negative_controls)=20
         AND min(expected_combined_hash)='ab32d80ba20c2c8f0a6ec9ec97c2ed26' AND min(observed_combined_hash)='ab32d80ba20c2c8f0a6ec9ec97c2ed26'
         AND min(required_source_edge_count)=1 AND min(passed_source_edge_count)=1
         AND min(source_graph_status)='PASS' AND min(canonical_identity_status)='PASS' AND min(stage_boundary_status)='PASS' AND min(certification_status)='PASS'
         AND count(*) FILTER (WHERE row_hash IS DISTINCT FROM md5((to_jsonb(s)-'row_hash'-'created_at')::text))=0) AS pass_flag,
        'Node M2_8_SERVICING_EXECUTION persisted certification is independently reconstructed from its physical canonical row.'::text AS interpretation
    FROM s
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_028_NODE_09_M2_8_SERVICING_EXECUTION_PHYSICAL_ACCEPTANCE */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    28::smallint,
    'M2_12_POS_028_NODE_09_M2_8_SERVICING_EXECUTION_PHYSICAL_ACCEPTANCE'::text,
    2::smallint,
    'SOURCE_NODE_ACCEPTANCE'::text,
    'Node 9 M2_8_SERVICING_EXECUTION gate, acceptance, physical boundary controls, and source edges are exact'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH gate AS (
        SELECT count(*)::integer AS n,
               count(*) FILTER (WHERE g.result_status='PASS')::integer AS pass_n
        FROM msbf_ctl.acceptance_gate_result g
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=g.run_id
        WHERE g.gate_id='M2_8_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONTROL' AND g.review_version=1
    ), acceptance AS (
        SELECT count(*)::integer AS n,
               count(*) FILTER (WHERE e.status='PASS')::integer AS pass_n
        FROM msbf_ctl.run_evidence e
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=e.run_id
        WHERE e.evidence_code='M2_8_ACCEPTANCE_SUMMARY'
    ), boundary AS (
        SELECT *
        FROM tmp_cert_m2_12_stage_boundary_observation b
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=b.module1_run_id
        WHERE b.node_sequence=9 AND b.stage_code='M2_8_SERVICING_EXECUTION'
    ), edges AS (
        SELECT count(*)::integer AS n,
               count(*) FILTER (WHERE edge_status='PASS')::integer AS pass_n,
               count(*) FILTER (WHERE source_hash_mismatch_flag OR target_hash_mismatch_flag)::integer AS mismatch_n
        FROM tmp_eval_m2_12_validation_source_edges
        WHERE target_node_code='M2_8_SERVICING_EXECUTION'
    )
    SELECT
        concat_ws('|',
            (SELECT n FROM gate),(SELECT pass_n FROM gate),
            (SELECT n FROM acceptance),(SELECT pass_n FROM acceptance),
            (SELECT required_evidence_rows FROM boundary),
            (SELECT physical_required_evidence_rows FROM boundary),
            (SELECT observed_required_evidence_rows FROM boundary),
            (SELECT duplicate_required_evidence_rows FROM boundary),
            (SELECT (missing_required_evidence_codes<>'')::integer FROM boundary),
            (SELECT nonpass_evidence_rows FROM boundary),
            (SELECT violation_rows FROM boundary),
            (SELECT certification_status FROM boundary),
            (SELECT n FROM edges),(SELECT pass_n FROM edges),(SELECT mismatch_n FROM edges)) AS observed_value,
        '1|1|1|1|8|8|8|0|0|0|0|PASS|1|1|0'::text AS expected_value,
        ((SELECT (n<>1 OR pass_n<>1)::integer FROM gate)
         +(SELECT (n<>1 OR pass_n<>1)::integer FROM acceptance)
         +(SELECT CASE WHEN count(*)=1
                         AND min(required_evidence_rows)=8
                         AND min(physical_required_evidence_rows)=8
                         AND min(observed_required_evidence_rows)=8
                         AND min(duplicate_required_evidence_rows)=0
                         AND min((missing_required_evidence_codes<>'')::integer)=0
                         AND min(nonpass_evidence_rows)=0
                         AND min(violation_rows)=0
                         AND min(certification_status)='PASS'
                       THEN 0 ELSE 1 END FROM boundary)
         +(SELECT (n<>1 OR pass_n<>1 OR mismatch_n<>0)::integer FROM edges))::bigint AS mismatch_count,
        ((SELECT n=1 AND pass_n=1 FROM gate)
         AND (SELECT n=1 AND pass_n=1 FROM acceptance)
         AND (SELECT count(*)=1
                     AND min(required_evidence_rows)=8
                     AND min(physical_required_evidence_rows)=8
                     AND min(observed_required_evidence_rows)=8
                     AND min(duplicate_required_evidence_rows)=0
                     AND min((missing_required_evidence_codes<>'')::integer)=0
                     AND min(nonpass_evidence_rows)=0
                     AND min(violation_rows)=0
                     AND min(certification_status)='PASS' FROM boundary)
         AND (SELECT n=1 AND pass_n=1 AND mismatch_n=0 FROM edges)) AS pass_flag,
        'Independent persisted-state reconstruction uses the exact acceptance gate and summary, the 70-control physical stage-boundary model, and the exact 19-edge source graph for M2_8_SERVICING_EXECUTION.'::text AS interpretation
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_029_NODE_10_M2_9_RECONCILIATION_CERTIFICATION_CANONICAL */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    29::smallint,
    'M2_12_POS_029_NODE_10_M2_9_RECONCILIATION_CERTIFICATION_CANONICAL'::text,
    2::smallint,
    'SOURCE_NODE_ACCEPTANCE'::text,
    'Node 10 M2_9_RECONCILIATION_CERTIFICATION persisted certification is exact'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH s AS (
        SELECT t.* FROM msbf_m2.module2_stage_certification_snapshot t
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id
        WHERE t.certification_node_sequence=10 AND t.stage_code='M2_9_RECONCILIATION_CERTIFICATION'
    )
    SELECT
        concat_ws('|',count(*)::text,min(stage_code),min(repository_stage),min(contract_status),min(gate_status),
            min(acceptance_evidence_status),min(observed_canonical_entities)::text,min(observed_positive_controls)::text,
            min(observed_negative_controls)::text,min(observed_combined_hash),min(source_graph_status),min(stage_boundary_status),
            min(certification_status),count(*) FILTER (WHERE row_hash IS DISTINCT FROM md5((to_jsonb(s)-'row_hash'-'created_at')::text))::text) AS observed_value,
        '1|M2_9_RECONCILIATION_CERTIFICATION|28_M2_9|ACCEPTED|PASS|PASS|438|120|20|6af76d0059b47623619ebc09330b15fe|PASS|PASS|PASS|0'::text AS expected_value,
        (CASE WHEN count(*)=1 AND min(stage_code)='M2_9_RECONCILIATION_CERTIFICATION' AND min(repository_stage)='28_M2_9'
                   AND min(module_title)='Payment Reconciliation, Exception Resolution & Account State Certification' AND min(acceptance_gate_id)='M2_9_PAYMENT_RECONCILIATION_EXCEPTION_RESOLUTION_ACCOUNT_STATE_CERTIFICATION'
                   AND min(acceptance_gate_review_version)=1
                   AND min(acceptance_evidence_code)='M2_9_ACCEPTANCE_SUMMARY'
                   AND min(contract_status)='ACCEPTED' AND min(gate_status)='PASS' AND min(acceptance_evidence_status)='PASS'
                   AND min(expected_canonical_entities)=438 AND min(observed_canonical_entities)=438
                   AND min(expected_positive_controls)=120 AND min(observed_positive_controls)=120
                   AND min(expected_negative_controls)=20 AND min(observed_negative_controls)=20
                   AND min(expected_combined_hash)='6af76d0059b47623619ebc09330b15fe' AND min(observed_combined_hash)='6af76d0059b47623619ebc09330b15fe'
                   AND min(required_source_edge_count)=1 AND min(passed_source_edge_count)=1
                   AND min(source_graph_status)='PASS' AND min(canonical_identity_status)='PASS' AND min(stage_boundary_status)='PASS' AND min(certification_status)='PASS'
                   AND count(*) FILTER (WHERE row_hash IS DISTINCT FROM md5((to_jsonb(s)-'row_hash'-'created_at')::text))=0
              THEN 0 ELSE 1 END)::bigint AS mismatch_count,
        (count(*)=1 AND min(stage_code)='M2_9_RECONCILIATION_CERTIFICATION' AND min(repository_stage)='28_M2_9'
         AND min(module_title)='Payment Reconciliation, Exception Resolution & Account State Certification' AND min(acceptance_gate_id)='M2_9_PAYMENT_RECONCILIATION_EXCEPTION_RESOLUTION_ACCOUNT_STATE_CERTIFICATION'
         AND min(acceptance_gate_review_version)=1
         AND min(acceptance_evidence_code)='M2_9_ACCEPTANCE_SUMMARY'
         AND min(contract_status)='ACCEPTED' AND min(gate_status)='PASS' AND min(acceptance_evidence_status)='PASS'
         AND min(expected_canonical_entities)=438 AND min(observed_canonical_entities)=438
         AND min(expected_positive_controls)=120 AND min(observed_positive_controls)=120
         AND min(expected_negative_controls)=20 AND min(observed_negative_controls)=20
         AND min(expected_combined_hash)='6af76d0059b47623619ebc09330b15fe' AND min(observed_combined_hash)='6af76d0059b47623619ebc09330b15fe'
         AND min(required_source_edge_count)=1 AND min(passed_source_edge_count)=1
         AND min(source_graph_status)='PASS' AND min(canonical_identity_status)='PASS' AND min(stage_boundary_status)='PASS' AND min(certification_status)='PASS'
         AND count(*) FILTER (WHERE row_hash IS DISTINCT FROM md5((to_jsonb(s)-'row_hash'-'created_at')::text))=0) AS pass_flag,
        'Node M2_9_RECONCILIATION_CERTIFICATION persisted certification is independently reconstructed from its physical canonical row.'::text AS interpretation
    FROM s
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_030_NODE_10_M2_9_RECONCILIATION_CERTIFICATION_PHYSICAL_ACCEPTANCE */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    30::smallint,
    'M2_12_POS_030_NODE_10_M2_9_RECONCILIATION_CERTIFICATION_PHYSICAL_ACCEPTANCE'::text,
    2::smallint,
    'SOURCE_NODE_ACCEPTANCE'::text,
    'Node 10 M2_9_RECONCILIATION_CERTIFICATION gate, acceptance, physical boundary controls, and source edges are exact'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH gate AS (
        SELECT count(*)::integer AS n,
               count(*) FILTER (WHERE g.result_status='PASS')::integer AS pass_n
        FROM msbf_ctl.acceptance_gate_result g
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=g.run_id
        WHERE g.gate_id='M2_9_PAYMENT_RECONCILIATION_EXCEPTION_RESOLUTION_ACCOUNT_STATE_CERTIFICATION' AND g.review_version=1
    ), acceptance AS (
        SELECT count(*)::integer AS n,
               count(*) FILTER (WHERE e.status='PASS')::integer AS pass_n
        FROM msbf_ctl.run_evidence e
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=e.run_id
        WHERE e.evidence_code='M2_9_ACCEPTANCE_SUMMARY'
    ), boundary AS (
        SELECT *
        FROM tmp_cert_m2_12_stage_boundary_observation b
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=b.module1_run_id
        WHERE b.node_sequence=10 AND b.stage_code='M2_9_RECONCILIATION_CERTIFICATION'
    ), edges AS (
        SELECT count(*)::integer AS n,
               count(*) FILTER (WHERE edge_status='PASS')::integer AS pass_n,
               count(*) FILTER (WHERE source_hash_mismatch_flag OR target_hash_mismatch_flag)::integer AS mismatch_n
        FROM tmp_eval_m2_12_validation_source_edges
        WHERE target_node_code='M2_9_RECONCILIATION_CERTIFICATION'
    )
    SELECT
        concat_ws('|',
            (SELECT n FROM gate),(SELECT pass_n FROM gate),
            (SELECT n FROM acceptance),(SELECT pass_n FROM acceptance),
            (SELECT required_evidence_rows FROM boundary),
            (SELECT physical_required_evidence_rows FROM boundary),
            (SELECT observed_required_evidence_rows FROM boundary),
            (SELECT duplicate_required_evidence_rows FROM boundary),
            (SELECT (missing_required_evidence_codes<>'')::integer FROM boundary),
            (SELECT nonpass_evidence_rows FROM boundary),
            (SELECT violation_rows FROM boundary),
            (SELECT certification_status FROM boundary),
            (SELECT n FROM edges),(SELECT pass_n FROM edges),(SELECT mismatch_n FROM edges)) AS observed_value,
        '1|1|1|1|10|10|10|0|0|0|0|PASS|1|1|0'::text AS expected_value,
        ((SELECT (n<>1 OR pass_n<>1)::integer FROM gate)
         +(SELECT (n<>1 OR pass_n<>1)::integer FROM acceptance)
         +(SELECT CASE WHEN count(*)=1
                         AND min(required_evidence_rows)=10
                         AND min(physical_required_evidence_rows)=10
                         AND min(observed_required_evidence_rows)=10
                         AND min(duplicate_required_evidence_rows)=0
                         AND min((missing_required_evidence_codes<>'')::integer)=0
                         AND min(nonpass_evidence_rows)=0
                         AND min(violation_rows)=0
                         AND min(certification_status)='PASS'
                       THEN 0 ELSE 1 END FROM boundary)
         +(SELECT (n<>1 OR pass_n<>1 OR mismatch_n<>0)::integer FROM edges))::bigint AS mismatch_count,
        ((SELECT n=1 AND pass_n=1 FROM gate)
         AND (SELECT n=1 AND pass_n=1 FROM acceptance)
         AND (SELECT count(*)=1
                     AND min(required_evidence_rows)=10
                     AND min(physical_required_evidence_rows)=10
                     AND min(observed_required_evidence_rows)=10
                     AND min(duplicate_required_evidence_rows)=0
                     AND min((missing_required_evidence_codes<>'')::integer)=0
                     AND min(nonpass_evidence_rows)=0
                     AND min(violation_rows)=0
                     AND min(certification_status)='PASS' FROM boundary)
         AND (SELECT n=1 AND pass_n=1 AND mismatch_n=0 FROM edges)) AS pass_flag,
        'Independent persisted-state reconstruction uses the exact acceptance gate and summary, the 70-control physical stage-boundary model, and the exact 19-edge source graph for M2_9_RECONCILIATION_CERTIFICATION.'::text AS interpretation
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_031_NODE_11_M2_10_PORTFOLIO_ANALYTICS_CANONICAL */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    31::smallint,
    'M2_12_POS_031_NODE_11_M2_10_PORTFOLIO_ANALYTICS_CANONICAL'::text,
    2::smallint,
    'SOURCE_NODE_ACCEPTANCE'::text,
    'Node 11 M2_10_PORTFOLIO_ANALYTICS persisted certification is exact'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH s AS (
        SELECT t.* FROM msbf_m2.module2_stage_certification_snapshot t
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id
        WHERE t.certification_node_sequence=11 AND t.stage_code='M2_10_PORTFOLIO_ANALYTICS'
    )
    SELECT
        concat_ws('|',count(*)::text,min(stage_code),min(repository_stage),min(contract_status),min(gate_status),
            min(acceptance_evidence_status),min(observed_canonical_entities)::text,min(observed_positive_controls)::text,
            min(observed_negative_controls)::text,min(observed_combined_hash),min(source_graph_status),min(stage_boundary_status),
            min(certification_status),count(*) FILTER (WHERE row_hash IS DISTINCT FROM md5((to_jsonb(s)-'row_hash'-'created_at')::text))::text) AS observed_value,
        '1|M2_10_PORTFOLIO_ANALYTICS|29_M2_10|ACCEPTED|PASS|PASS|370|120|20|24fca7263a04397ebf21d30639f9069b|PASS|PASS|PASS|0'::text AS expected_value,
        (CASE WHEN count(*)=1 AND min(stage_code)='M2_10_PORTFOLIO_ANALYTICS' AND min(repository_stage)='29_M2_10'
                   AND min(module_title)='Portfolio Performance, KPI & Servicing Analytics' AND min(acceptance_gate_id)='M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS'
                   AND min(acceptance_gate_review_version)=1
                   AND min(acceptance_evidence_code)='M2_10_ACCEPTANCE_SUMMARY'
                   AND min(contract_status)='ACCEPTED' AND min(gate_status)='PASS' AND min(acceptance_evidence_status)='PASS'
                   AND min(expected_canonical_entities)=370 AND min(observed_canonical_entities)=370
                   AND min(expected_positive_controls)=120 AND min(observed_positive_controls)=120
                   AND min(expected_negative_controls)=20 AND min(observed_negative_controls)=20
                   AND min(expected_combined_hash)='24fca7263a04397ebf21d30639f9069b' AND min(observed_combined_hash)='24fca7263a04397ebf21d30639f9069b'
                   AND min(required_source_edge_count)=1 AND min(passed_source_edge_count)=1
                   AND min(source_graph_status)='PASS' AND min(canonical_identity_status)='PASS' AND min(stage_boundary_status)='PASS' AND min(certification_status)='PASS'
                   AND count(*) FILTER (WHERE row_hash IS DISTINCT FROM md5((to_jsonb(s)-'row_hash'-'created_at')::text))=0
              THEN 0 ELSE 1 END)::bigint AS mismatch_count,
        (count(*)=1 AND min(stage_code)='M2_10_PORTFOLIO_ANALYTICS' AND min(repository_stage)='29_M2_10'
         AND min(module_title)='Portfolio Performance, KPI & Servicing Analytics' AND min(acceptance_gate_id)='M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS'
         AND min(acceptance_gate_review_version)=1
         AND min(acceptance_evidence_code)='M2_10_ACCEPTANCE_SUMMARY'
         AND min(contract_status)='ACCEPTED' AND min(gate_status)='PASS' AND min(acceptance_evidence_status)='PASS'
         AND min(expected_canonical_entities)=370 AND min(observed_canonical_entities)=370
         AND min(expected_positive_controls)=120 AND min(observed_positive_controls)=120
         AND min(expected_negative_controls)=20 AND min(observed_negative_controls)=20
         AND min(expected_combined_hash)='24fca7263a04397ebf21d30639f9069b' AND min(observed_combined_hash)='24fca7263a04397ebf21d30639f9069b'
         AND min(required_source_edge_count)=1 AND min(passed_source_edge_count)=1
         AND min(source_graph_status)='PASS' AND min(canonical_identity_status)='PASS' AND min(stage_boundary_status)='PASS' AND min(certification_status)='PASS'
         AND count(*) FILTER (WHERE row_hash IS DISTINCT FROM md5((to_jsonb(s)-'row_hash'-'created_at')::text))=0) AS pass_flag,
        'Node M2_10_PORTFOLIO_ANALYTICS persisted certification is independently reconstructed from its physical canonical row.'::text AS interpretation
    FROM s
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_032_NODE_11_M2_10_PORTFOLIO_ANALYTICS_PHYSICAL_ACCEPTANCE */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    32::smallint,
    'M2_12_POS_032_NODE_11_M2_10_PORTFOLIO_ANALYTICS_PHYSICAL_ACCEPTANCE'::text,
    2::smallint,
    'SOURCE_NODE_ACCEPTANCE'::text,
    'Node 11 M2_10_PORTFOLIO_ANALYTICS gate, acceptance, physical boundary controls, and source edges are exact'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH gate AS (
        SELECT count(*)::integer AS n,
               count(*) FILTER (WHERE g.result_status='PASS')::integer AS pass_n
        FROM msbf_ctl.acceptance_gate_result g
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=g.run_id
        WHERE g.gate_id='M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS' AND g.review_version=1
    ), acceptance AS (
        SELECT count(*)::integer AS n,
               count(*) FILTER (WHERE e.status='PASS')::integer AS pass_n
        FROM msbf_ctl.run_evidence e
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=e.run_id
        WHERE e.evidence_code='M2_10_ACCEPTANCE_SUMMARY'
    ), boundary AS (
        SELECT *
        FROM tmp_cert_m2_12_stage_boundary_observation b
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=b.module1_run_id
        WHERE b.node_sequence=11 AND b.stage_code='M2_10_PORTFOLIO_ANALYTICS'
    ), edges AS (
        SELECT count(*)::integer AS n,
               count(*) FILTER (WHERE edge_status='PASS')::integer AS pass_n,
               count(*) FILTER (WHERE source_hash_mismatch_flag OR target_hash_mismatch_flag)::integer AS mismatch_n
        FROM tmp_eval_m2_12_validation_source_edges
        WHERE target_node_code='M2_10_PORTFOLIO_ANALYTICS'
    )
    SELECT
        concat_ws('|',
            (SELECT n FROM gate),(SELECT pass_n FROM gate),
            (SELECT n FROM acceptance),(SELECT pass_n FROM acceptance),
            (SELECT required_evidence_rows FROM boundary),
            (SELECT physical_required_evidence_rows FROM boundary),
            (SELECT observed_required_evidence_rows FROM boundary),
            (SELECT duplicate_required_evidence_rows FROM boundary),
            (SELECT (missing_required_evidence_codes<>'')::integer FROM boundary),
            (SELECT nonpass_evidence_rows FROM boundary),
            (SELECT violation_rows FROM boundary),
            (SELECT certification_status FROM boundary),
            (SELECT n FROM edges),(SELECT pass_n FROM edges),(SELECT mismatch_n FROM edges)) AS observed_value,
        '1|1|1|1|10|10|10|0|0|0|0|PASS|1|1|0'::text AS expected_value,
        ((SELECT (n<>1 OR pass_n<>1)::integer FROM gate)
         +(SELECT (n<>1 OR pass_n<>1)::integer FROM acceptance)
         +(SELECT CASE WHEN count(*)=1
                         AND min(required_evidence_rows)=10
                         AND min(physical_required_evidence_rows)=10
                         AND min(observed_required_evidence_rows)=10
                         AND min(duplicate_required_evidence_rows)=0
                         AND min((missing_required_evidence_codes<>'')::integer)=0
                         AND min(nonpass_evidence_rows)=0
                         AND min(violation_rows)=0
                         AND min(certification_status)='PASS'
                       THEN 0 ELSE 1 END FROM boundary)
         +(SELECT (n<>1 OR pass_n<>1 OR mismatch_n<>0)::integer FROM edges))::bigint AS mismatch_count,
        ((SELECT n=1 AND pass_n=1 FROM gate)
         AND (SELECT n=1 AND pass_n=1 FROM acceptance)
         AND (SELECT count(*)=1
                     AND min(required_evidence_rows)=10
                     AND min(physical_required_evidence_rows)=10
                     AND min(observed_required_evidence_rows)=10
                     AND min(duplicate_required_evidence_rows)=0
                     AND min((missing_required_evidence_codes<>'')::integer)=0
                     AND min(nonpass_evidence_rows)=0
                     AND min(violation_rows)=0
                     AND min(certification_status)='PASS' FROM boundary)
         AND (SELECT n=1 AND pass_n=1 AND mismatch_n=0 FROM edges)) AS pass_flag,
        'Independent persisted-state reconstruction uses the exact acceptance gate and summary, the 70-control physical stage-boundary model, and the exact 19-edge source graph for M2_10_PORTFOLIO_ANALYTICS.'::text AS interpretation
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_033_NODE_12_M2_11_STRATEGY_SIMULATION_CANONICAL */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    33::smallint,
    'M2_12_POS_033_NODE_12_M2_11_STRATEGY_SIMULATION_CANONICAL'::text,
    2::smallint,
    'SOURCE_NODE_ACCEPTANCE'::text,
    'Node 12 M2_11_STRATEGY_SIMULATION persisted certification is exact'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH s AS (
        SELECT t.* FROM msbf_m2.module2_stage_certification_snapshot t
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id
        WHERE t.certification_node_sequence=12 AND t.stage_code='M2_11_STRATEGY_SIMULATION'
    )
    SELECT
        concat_ws('|',count(*)::text,min(stage_code),min(repository_stage),min(contract_status),min(gate_status),
            min(acceptance_evidence_status),min(observed_canonical_entities)::text,min(observed_positive_controls)::text,
            min(observed_negative_controls)::text,min(observed_combined_hash),min(source_graph_status),min(stage_boundary_status),
            min(certification_status),count(*) FILTER (WHERE row_hash IS DISTINCT FROM md5((to_jsonb(s)-'row_hash'-'created_at')::text))::text) AS observed_value,
        '1|M2_11_STRATEGY_SIMULATION|30_M2_11|ACCEPTED|PASS|PASS|19298|120|20|a67d375b9f9248b3eec8160cf3dc656d|PASS|PASS|PASS|0'::text AS expected_value,
        (CASE WHEN count(*)=1 AND min(stage_code)='M2_11_STRATEGY_SIMULATION' AND min(repository_stage)='30_M2_11'
                   AND min(module_title)='Portfolio Optimization & Strategy Simulation' AND min(acceptance_gate_id)='M2_11_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION'
                   AND min(acceptance_gate_review_version)=1
                   AND min(acceptance_evidence_code)='M2_11_ACCEPTANCE_SUMMARY'
                   AND min(contract_status)='ACCEPTED' AND min(gate_status)='PASS' AND min(acceptance_evidence_status)='PASS'
                   AND min(expected_canonical_entities)=19298 AND min(observed_canonical_entities)=19298
                   AND min(expected_positive_controls)=120 AND min(observed_positive_controls)=120
                   AND min(expected_negative_controls)=20 AND min(observed_negative_controls)=20
                   AND min(expected_combined_hash)='a67d375b9f9248b3eec8160cf3dc656d' AND min(observed_combined_hash)='a67d375b9f9248b3eec8160cf3dc656d'
                   AND min(required_source_edge_count)=5 AND min(passed_source_edge_count)=5
                   AND min(source_graph_status)='PASS' AND min(canonical_identity_status)='PASS' AND min(stage_boundary_status)='PASS' AND min(certification_status)='PASS'
                   AND count(*) FILTER (WHERE row_hash IS DISTINCT FROM md5((to_jsonb(s)-'row_hash'-'created_at')::text))=0
              THEN 0 ELSE 1 END)::bigint AS mismatch_count,
        (count(*)=1 AND min(stage_code)='M2_11_STRATEGY_SIMULATION' AND min(repository_stage)='30_M2_11'
         AND min(module_title)='Portfolio Optimization & Strategy Simulation' AND min(acceptance_gate_id)='M2_11_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION'
         AND min(acceptance_gate_review_version)=1
         AND min(acceptance_evidence_code)='M2_11_ACCEPTANCE_SUMMARY'
         AND min(contract_status)='ACCEPTED' AND min(gate_status)='PASS' AND min(acceptance_evidence_status)='PASS'
         AND min(expected_canonical_entities)=19298 AND min(observed_canonical_entities)=19298
         AND min(expected_positive_controls)=120 AND min(observed_positive_controls)=120
         AND min(expected_negative_controls)=20 AND min(observed_negative_controls)=20
         AND min(expected_combined_hash)='a67d375b9f9248b3eec8160cf3dc656d' AND min(observed_combined_hash)='a67d375b9f9248b3eec8160cf3dc656d'
         AND min(required_source_edge_count)=5 AND min(passed_source_edge_count)=5
         AND min(source_graph_status)='PASS' AND min(canonical_identity_status)='PASS' AND min(stage_boundary_status)='PASS' AND min(certification_status)='PASS'
         AND count(*) FILTER (WHERE row_hash IS DISTINCT FROM md5((to_jsonb(s)-'row_hash'-'created_at')::text))=0) AS pass_flag,
        'Node M2_11_STRATEGY_SIMULATION persisted certification is independently reconstructed from its physical canonical row.'::text AS interpretation
    FROM s
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_034_NODE_12_M2_11_STRATEGY_SIMULATION_PHYSICAL_ACCEPTANCE */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    34::smallint,
    'M2_12_POS_034_NODE_12_M2_11_STRATEGY_SIMULATION_PHYSICAL_ACCEPTANCE'::text,
    2::smallint,
    'SOURCE_NODE_ACCEPTANCE'::text,
    'Node 12 M2_11_STRATEGY_SIMULATION gate, acceptance, physical boundary controls, and source edges are exact'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH gate AS (
        SELECT count(*)::integer AS n,
               count(*) FILTER (WHERE g.result_status='PASS')::integer AS pass_n
        FROM msbf_ctl.acceptance_gate_result g
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=g.run_id
        WHERE g.gate_id='M2_11_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION' AND g.review_version=1
    ), acceptance AS (
        SELECT count(*)::integer AS n,
               count(*) FILTER (WHERE e.status='PASS')::integer AS pass_n
        FROM msbf_ctl.run_evidence e
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=e.run_id
        WHERE e.evidence_code='M2_11_ACCEPTANCE_SUMMARY'
    ), boundary AS (
        SELECT *
        FROM tmp_cert_m2_12_stage_boundary_observation b
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=b.module1_run_id
        WHERE b.node_sequence=12 AND b.stage_code='M2_11_STRATEGY_SIMULATION'
    ), edges AS (
        SELECT count(*)::integer AS n,
               count(*) FILTER (WHERE edge_status='PASS')::integer AS pass_n,
               count(*) FILTER (WHERE source_hash_mismatch_flag OR target_hash_mismatch_flag)::integer AS mismatch_n
        FROM tmp_eval_m2_12_validation_source_edges
        WHERE target_node_code='M2_11_STRATEGY_SIMULATION'
    )
    SELECT
        concat_ws('|',
            (SELECT n FROM gate),(SELECT pass_n FROM gate),
            (SELECT n FROM acceptance),(SELECT pass_n FROM acceptance),
            (SELECT required_evidence_rows FROM boundary),
            (SELECT physical_required_evidence_rows FROM boundary),
            (SELECT observed_required_evidence_rows FROM boundary),
            (SELECT duplicate_required_evidence_rows FROM boundary),
            (SELECT (missing_required_evidence_codes<>'')::integer FROM boundary),
            (SELECT nonpass_evidence_rows FROM boundary),
            (SELECT violation_rows FROM boundary),
            (SELECT certification_status FROM boundary),
            (SELECT n FROM edges),(SELECT pass_n FROM edges),(SELECT mismatch_n FROM edges)) AS observed_value,
        '1|1|1|1|6|6|6|0|0|0|0|PASS|5|5|0'::text AS expected_value,
        ((SELECT (n<>1 OR pass_n<>1)::integer FROM gate)
         +(SELECT (n<>1 OR pass_n<>1)::integer FROM acceptance)
         +(SELECT CASE WHEN count(*)=1
                         AND min(required_evidence_rows)=6
                         AND min(physical_required_evidence_rows)=6
                         AND min(observed_required_evidence_rows)=6
                         AND min(duplicate_required_evidence_rows)=0
                         AND min((missing_required_evidence_codes<>'')::integer)=0
                         AND min(nonpass_evidence_rows)=0
                         AND min(violation_rows)=0
                         AND min(certification_status)='PASS'
                       THEN 0 ELSE 1 END FROM boundary)
         +(SELECT (n<>5 OR pass_n<>5 OR mismatch_n<>0)::integer FROM edges))::bigint AS mismatch_count,
        ((SELECT n=1 AND pass_n=1 FROM gate)
         AND (SELECT n=1 AND pass_n=1 FROM acceptance)
         AND (SELECT count(*)=1
                     AND min(required_evidence_rows)=6
                     AND min(physical_required_evidence_rows)=6
                     AND min(observed_required_evidence_rows)=6
                     AND min(duplicate_required_evidence_rows)=0
                     AND min((missing_required_evidence_codes<>'')::integer)=0
                     AND min(nonpass_evidence_rows)=0
                     AND min(violation_rows)=0
                     AND min(certification_status)='PASS' FROM boundary)
         AND (SELECT n=5 AND pass_n=5 AND mismatch_n=0 FROM edges)) AS pass_flag,
        'Independent persisted-state reconstruction uses the exact acceptance gate and summary, the 70-control physical stage-boundary model, and the exact 19-edge source graph for M2_11_STRATEGY_SIMULATION.'::text AS interpretation
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_035_COMPONENT_01_M1_G2_CONSUMPTION_BUNDLE_IDENTITY */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    35::smallint,
    'M2_12_POS_035_COMPONENT_01_M1_G2_CONSUMPTION_BUNDLE_IDENTITY'::text,
    3::smallint,
    'COMPONENT_CONTRACT'::text,
    'Component 01 M1_G2_CONSUMPTION_BUNDLE identity, counts, hashes, and statuses are exact'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH c AS (
        SELECT t.* FROM msbf_m2.module2_contract_component_snapshot t
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id
        WHERE t.component_sequence=1 AND t.component_contract_code='M1_G2_CONSUMPTION_BUNDLE' AND t.contract_version=1
    )
    SELECT
        concat_ws('|',count(*)::text,min(component_contract_code),min(contract_version)::text,min(schema_version),min(methodology_version),
            min(expected_latest_rows)::text,min(observed_latest_rows)::text,min(expected_archive_rows)::text,min(observed_archive_rows)::text,
            min(observed_contract_set_hash),min(observed_stage_combined_set_hash),min(observed_registry_row_hash),min(observed_latest_set_hash),min(observed_archive_set_hash),
            min(contract_status),min(gate_status),min(acceptance_evidence_status),min(certification_status),
            count(*) FILTER (WHERE row_hash IS DISTINCT FROM md5((to_jsonb(c)-'row_hash'-'created_at')::text))::text) AS observed_value,
        '1|M1_G2_CONSUMPTION_BUNDLE|1|M1_G2_BUNDLE_SCHEMA_V1|M1_17_METHOD_V1|1|1|1|1|d9cdb8309efdcc892f0a0c51b3d5fe94|7d9e466da28cad2551aa99c4c40c912b|27397e724a7d24a84601d5052f1b0c34|64250f8d027ad78650a1bf5ede7da6e5|020a5946318d6d73da58f723349ab18c|ACCEPTED|PASS|PASS|PASS|0'::text AS expected_value,
        (CASE WHEN count(*)=1 AND min(certification_node_sequence)=1
                   AND min(stage_code)='M1_17_G2_FOUNDATION' AND min(repository_stage)='19_M1_17'
                   AND min(component_contract_code)='M1_G2_CONSUMPTION_BUNDLE' AND min(contract_version)=1
                   AND min(schema_version)='M1_G2_BUNDLE_SCHEMA_V1' AND min(methodology_version)='M1_17_METHOD_V1'
                   AND min(acceptance_gate_id)='G2_M1_CONTRACT'
                   AND min(expected_latest_rows)=1 AND min(observed_latest_rows)=1
                   AND min(expected_archive_rows)=1 AND min(observed_archive_rows)=1
                   AND min(stage_expected_canonical_entities)=69
                   AND min(expected_positive_controls)=128 AND min(observed_positive_controls)=128
                   AND min(expected_negative_controls)=20 AND min(observed_negative_controls)=20
                   AND min(expected_contract_set_hash)='d9cdb8309efdcc892f0a0c51b3d5fe94' AND min(observed_contract_set_hash)='d9cdb8309efdcc892f0a0c51b3d5fe94'
                   AND min(expected_stage_combined_set_hash)='7d9e466da28cad2551aa99c4c40c912b' AND min(observed_stage_combined_set_hash)='7d9e466da28cad2551aa99c4c40c912b'
                   AND min(expected_registry_row_hash)='27397e724a7d24a84601d5052f1b0c34' AND min(observed_registry_row_hash)='27397e724a7d24a84601d5052f1b0c34'
                   AND min(expected_latest_set_hash)='64250f8d027ad78650a1bf5ede7da6e5' AND min(observed_latest_set_hash)='64250f8d027ad78650a1bf5ede7da6e5'
                   AND min(expected_archive_set_hash)='020a5946318d6d73da58f723349ab18c' AND min(observed_archive_set_hash)='020a5946318d6d73da58f723349ab18c'
                   AND min(contract_status)='ACCEPTED' AND min(gate_status)='PASS' AND min(acceptance_evidence_status)='PASS' AND min(certification_status)='PASS'
                   AND min(required_source_edge_count)=2 AND min(passed_source_edge_count)=2
                   AND count(*) FILTER (WHERE row_hash IS DISTINCT FROM md5((to_jsonb(c)-'row_hash'-'created_at')::text))=0
              THEN 0 ELSE 1 END)::bigint AS mismatch_count,
        (count(*)=1 AND min(certification_node_sequence)=1
         AND min(stage_code)='M1_17_G2_FOUNDATION' AND min(repository_stage)='19_M1_17'
         AND min(component_contract_code)='M1_G2_CONSUMPTION_BUNDLE' AND min(contract_version)=1
         AND min(schema_version)='M1_G2_BUNDLE_SCHEMA_V1' AND min(methodology_version)='M1_17_METHOD_V1'
         AND min(acceptance_gate_id)='G2_M1_CONTRACT'
         AND min(expected_latest_rows)=1 AND min(observed_latest_rows)=1
         AND min(expected_archive_rows)=1 AND min(observed_archive_rows)=1
         AND min(stage_expected_canonical_entities)=69
         AND min(expected_positive_controls)=128 AND min(observed_positive_controls)=128
         AND min(expected_negative_controls)=20 AND min(observed_negative_controls)=20
         AND min(expected_contract_set_hash)='d9cdb8309efdcc892f0a0c51b3d5fe94' AND min(observed_contract_set_hash)='d9cdb8309efdcc892f0a0c51b3d5fe94'
         AND min(expected_stage_combined_set_hash)='7d9e466da28cad2551aa99c4c40c912b' AND min(observed_stage_combined_set_hash)='7d9e466da28cad2551aa99c4c40c912b'
         AND min(expected_registry_row_hash)='27397e724a7d24a84601d5052f1b0c34' AND min(observed_registry_row_hash)='27397e724a7d24a84601d5052f1b0c34'
         AND min(expected_latest_set_hash)='64250f8d027ad78650a1bf5ede7da6e5' AND min(observed_latest_set_hash)='64250f8d027ad78650a1bf5ede7da6e5'
         AND min(expected_archive_set_hash)='020a5946318d6d73da58f723349ab18c' AND min(observed_archive_set_hash)='020a5946318d6d73da58f723349ab18c'
         AND min(contract_status)='ACCEPTED' AND min(gate_status)='PASS' AND min(acceptance_evidence_status)='PASS' AND min(certification_status)='PASS'
         AND min(required_source_edge_count)=2 AND min(passed_source_edge_count)=2
         AND count(*) FILTER (WHERE row_hash IS DISTINCT FROM md5((to_jsonb(c)-'row_hash'-'created_at')::text))=0) AS pass_flag,
        'Frozen contract identity and copied accepted-source hashes for component M1_G2_CONSUMPTION_BUNDLE.'::text AS interpretation
    FROM c
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_036_COMPONENT_01_M1_G2_CONSUMPTION_BUNDLE_LINEAGE */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    36::smallint,
    'M2_12_POS_036_COMPONENT_01_M1_G2_CONSUMPTION_BUNDLE_LINEAGE'::text,
    3::smallint,
    'COMPONENT_CONTRACT'::text,
    'Component 01 M1_G2_CONSUMPTION_BUNDLE physical relation, business-key, edge, and reproduction lineage is exact'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH c AS (
        SELECT t.* FROM msbf_m2.module2_contract_component_snapshot t
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id
        WHERE t.component_sequence=1 AND t.component_contract_code='M1_G2_CONSUMPTION_BUNDLE' AND t.contract_version=1
    ), r AS (
        SELECT t.* FROM msbf_m2.module2_contract_reproduction_snapshot t
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id
        WHERE t.component_sequence=1 AND t.component_contract_code='M1_G2_CONSUMPTION_BUNDLE' AND t.contract_version=1
    )
    SELECT
        concat_ws('|',(SELECT count(*) FROM c),(SELECT min(registry_relation) FROM c),(SELECT min(latest_relation) FROM c),(SELECT min(archive_relation) FROM c),
            (SELECT min(latest_business_grain) FROM c),(SELECT min(latest_business_key_columns::text) FROM c),(SELECT min(archive_business_key_columns::text) FROM c),
            (SELECT min(required_source_edge_count)::text FROM c),(SELECT min(passed_source_edge_count)::text FROM c),(SELECT count(*) FROM r),
            (SELECT min(reproduction_status) FROM r),(SELECT min(archive_trigger_status) FROM r)) AS observed_value,
        '1|msbf_ctl.m1_17_g2_bundle_registry|msbf_ctl.m1_17_g2_bundle_latest|msbf_ctl.m1_17_g2_bundle_archive|module1_run_id|["module1_run_id"]|["module1_run_id","bundle_code","bundle_version"]|2|2|1|PASS|PASS'::text AS expected_value,
        ((SELECT (count(*)<>1)::integer FROM c)
         +(SELECT count(*) FILTER (WHERE registry_relation<>'msbf_ctl.m1_17_g2_bundle_registry' OR latest_relation<>'msbf_ctl.m1_17_g2_bundle_latest' OR archive_relation<>'msbf_ctl.m1_17_g2_bundle_archive' OR latest_business_grain<>'module1_run_id'
                   OR latest_business_key_columns<>'["module1_run_id"]'::jsonb OR archive_business_key_columns<>'["module1_run_id","bundle_code","bundle_version"]'::jsonb
                   OR required_source_edge_codes<>ARRAY['M1_15_TO_M1_17_APPLICATION_CONTRACT','M1_16_TO_M1_17_ACQUISITION_CONTRACT']::text[] OR required_source_edge_count<>2 OR passed_source_edge_count<>2) FROM c)
         +(SELECT (count(*)<>1)::integer FROM r)
         +(SELECT count(*) FILTER (WHERE registry_relation<>'msbf_ctl.m1_17_g2_bundle_registry' OR latest_relation<>'msbf_ctl.m1_17_g2_bundle_latest' OR archive_relation<>'msbf_ctl.m1_17_g2_bundle_archive'
                   OR latest_business_key_columns<>'["module1_run_id"]'::jsonb OR archive_business_key_columns<>'["module1_run_id","bundle_code","bundle_version"]'::jsonb
                   OR expected_latest_rows<>1 OR observed_latest_rows<>1
                   OR expected_archive_rows<>1 OR observed_archive_rows<>1
                   OR expected_latest_set_hash<>'64250f8d027ad78650a1bf5ede7da6e5' OR observed_latest_set_hash<>'64250f8d027ad78650a1bf5ede7da6e5'
                   OR expected_archive_set_hash<>'020a5946318d6d73da58f723349ab18c' OR observed_archive_set_hash<>'020a5946318d6d73da58f723349ab18c'
                   OR payload_mismatch_count<>0 OR missing_latest_rows<>0 OR missing_archive_rows<>0 OR latest_duplicate_key_rows<>0 OR archive_duplicate_key_rows<>0
                   OR archive_trigger_status<>'PASS' OR reproduction_status<>'PASS' OR source_registry_row_hash<>'27397e724a7d24a84601d5052f1b0c34'
                   OR row_hash IS DISTINCT FROM md5((to_jsonb(r)-'row_hash'-'created_at')::text)) FROM r))::bigint AS mismatch_count,
        ((SELECT count(*)=1 FROM c)
         AND (SELECT count(*)=0 FROM c WHERE registry_relation<>'msbf_ctl.m1_17_g2_bundle_registry' OR latest_relation<>'msbf_ctl.m1_17_g2_bundle_latest' OR archive_relation<>'msbf_ctl.m1_17_g2_bundle_archive' OR latest_business_grain<>'module1_run_id'
              OR latest_business_key_columns<>'["module1_run_id"]'::jsonb OR archive_business_key_columns<>'["module1_run_id","bundle_code","bundle_version"]'::jsonb
              OR required_source_edge_codes<>ARRAY['M1_15_TO_M1_17_APPLICATION_CONTRACT','M1_16_TO_M1_17_ACQUISITION_CONTRACT']::text[] OR required_source_edge_count<>2 OR passed_source_edge_count<>2)
         AND (SELECT count(*)=1 FROM r)
         AND (SELECT count(*)=0 FROM r WHERE registry_relation<>'msbf_ctl.m1_17_g2_bundle_registry' OR latest_relation<>'msbf_ctl.m1_17_g2_bundle_latest' OR archive_relation<>'msbf_ctl.m1_17_g2_bundle_archive'
              OR latest_business_key_columns<>'["module1_run_id"]'::jsonb OR archive_business_key_columns<>'["module1_run_id","bundle_code","bundle_version"]'::jsonb
              OR expected_latest_rows<>1 OR observed_latest_rows<>1
              OR expected_archive_rows<>1 OR observed_archive_rows<>1
              OR expected_latest_set_hash<>'64250f8d027ad78650a1bf5ede7da6e5' OR observed_latest_set_hash<>'64250f8d027ad78650a1bf5ede7da6e5'
              OR expected_archive_set_hash<>'020a5946318d6d73da58f723349ab18c' OR observed_archive_set_hash<>'020a5946318d6d73da58f723349ab18c'
              OR payload_mismatch_count<>0 OR missing_latest_rows<>0 OR missing_archive_rows<>0 OR latest_duplicate_key_rows<>0 OR archive_duplicate_key_rows<>0
              OR archive_trigger_status<>'PASS' OR reproduction_status<>'PASS' OR source_registry_row_hash<>'27397e724a7d24a84601d5052f1b0c34'
              OR row_hash IS DISTINCT FROM md5((to_jsonb(r)-'row_hash'-'created_at')::text))) AS pass_flag,
        'Physical relation, business-key, source-edge, and reproduction lineage for component M1_G2_CONSUMPTION_BUNDLE.'::text AS interpretation
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_037_COMPONENT_02_M2_ELIGIBILITY_ROUTING_CONSUMPTION_IDENTITY */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    37::smallint,
    'M2_12_POS_037_COMPONENT_02_M2_ELIGIBILITY_ROUTING_CONSUMPTION_IDENTITY'::text,
    3::smallint,
    'COMPONENT_CONTRACT'::text,
    'Component 02 M2_ELIGIBILITY_ROUTING_CONSUMPTION identity, counts, hashes, and statuses are exact'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH c AS (
        SELECT t.* FROM msbf_m2.module2_contract_component_snapshot t
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id
        WHERE t.component_sequence=2 AND t.component_contract_code='M2_ELIGIBILITY_ROUTING_CONSUMPTION' AND t.contract_version=1
    )
    SELECT
        concat_ws('|',count(*)::text,min(component_contract_code),min(contract_version)::text,min(schema_version),min(methodology_version),
            min(expected_latest_rows)::text,min(observed_latest_rows)::text,min(expected_archive_rows)::text,min(observed_archive_rows)::text,
            min(observed_contract_set_hash),min(observed_stage_combined_set_hash),min(observed_registry_row_hash),min(observed_latest_set_hash),min(observed_archive_set_hash),
            min(contract_status),min(gate_status),min(acceptance_evidence_status),min(certification_status),
            count(*) FILTER (WHERE row_hash IS DISTINCT FROM md5((to_jsonb(c)-'row_hash'-'created_at')::text))::text) AS observed_value,
        '1|M2_ELIGIBILITY_ROUTING_CONSUMPTION|1|M2_1_ROUTING_SCHEMA_V1|M2_1_METHOD_V1|1500|1500|1500|1500|5ce0574b6e27c4b94b8e65997b40f805|e5ace7f32060ffb191c7bd0f8dd0c863|e3fe1ae397c76da8f6ba88649935cfa7|f813d2d8bfa4609f83b2bfd181de3e17|13d7db24aa254d8efe69b28998d91fd4|ACCEPTED|PASS|PASS|PASS|0'::text AS expected_value,
        (CASE WHEN count(*)=1 AND min(certification_node_sequence)=2
                   AND min(stage_code)='M2_1_ELIGIBILITY_ROUTING' AND min(repository_stage)='20_M2_1'
                   AND min(component_contract_code)='M2_ELIGIBILITY_ROUTING_CONSUMPTION' AND min(contract_version)=1
                   AND min(schema_version)='M2_1_ROUTING_SCHEMA_V1' AND min(methodology_version)='M2_1_METHOD_V1'
                   AND min(acceptance_gate_id)='M2_1_ELIGIBILITY_POLICY_ROUTING'
                   AND min(expected_latest_rows)=1500 AND min(observed_latest_rows)=1500
                   AND min(expected_archive_rows)=1500 AND min(observed_archive_rows)=1500
                   AND min(stage_expected_canonical_entities)=22541
                   AND min(expected_positive_controls)=112 AND min(observed_positive_controls)=112
                   AND min(expected_negative_controls)=20 AND min(observed_negative_controls)=20
                   AND min(expected_contract_set_hash)='5ce0574b6e27c4b94b8e65997b40f805' AND min(observed_contract_set_hash)='5ce0574b6e27c4b94b8e65997b40f805'
                   AND min(expected_stage_combined_set_hash)='e5ace7f32060ffb191c7bd0f8dd0c863' AND min(observed_stage_combined_set_hash)='e5ace7f32060ffb191c7bd0f8dd0c863'
                   AND min(expected_registry_row_hash)='e3fe1ae397c76da8f6ba88649935cfa7' AND min(observed_registry_row_hash)='e3fe1ae397c76da8f6ba88649935cfa7'
                   AND min(expected_latest_set_hash)='f813d2d8bfa4609f83b2bfd181de3e17' AND min(observed_latest_set_hash)='f813d2d8bfa4609f83b2bfd181de3e17'
                   AND min(expected_archive_set_hash)='13d7db24aa254d8efe69b28998d91fd4' AND min(observed_archive_set_hash)='13d7db24aa254d8efe69b28998d91fd4'
                   AND min(contract_status)='ACCEPTED' AND min(gate_status)='PASS' AND min(acceptance_evidence_status)='PASS' AND min(certification_status)='PASS'
                   AND min(required_source_edge_count)=1 AND min(passed_source_edge_count)=1
                   AND count(*) FILTER (WHERE row_hash IS DISTINCT FROM md5((to_jsonb(c)-'row_hash'-'created_at')::text))=0
              THEN 0 ELSE 1 END)::bigint AS mismatch_count,
        (count(*)=1 AND min(certification_node_sequence)=2
         AND min(stage_code)='M2_1_ELIGIBILITY_ROUTING' AND min(repository_stage)='20_M2_1'
         AND min(component_contract_code)='M2_ELIGIBILITY_ROUTING_CONSUMPTION' AND min(contract_version)=1
         AND min(schema_version)='M2_1_ROUTING_SCHEMA_V1' AND min(methodology_version)='M2_1_METHOD_V1'
         AND min(acceptance_gate_id)='M2_1_ELIGIBILITY_POLICY_ROUTING'
         AND min(expected_latest_rows)=1500 AND min(observed_latest_rows)=1500
         AND min(expected_archive_rows)=1500 AND min(observed_archive_rows)=1500
         AND min(stage_expected_canonical_entities)=22541
         AND min(expected_positive_controls)=112 AND min(observed_positive_controls)=112
         AND min(expected_negative_controls)=20 AND min(observed_negative_controls)=20
         AND min(expected_contract_set_hash)='5ce0574b6e27c4b94b8e65997b40f805' AND min(observed_contract_set_hash)='5ce0574b6e27c4b94b8e65997b40f805'
         AND min(expected_stage_combined_set_hash)='e5ace7f32060ffb191c7bd0f8dd0c863' AND min(observed_stage_combined_set_hash)='e5ace7f32060ffb191c7bd0f8dd0c863'
         AND min(expected_registry_row_hash)='e3fe1ae397c76da8f6ba88649935cfa7' AND min(observed_registry_row_hash)='e3fe1ae397c76da8f6ba88649935cfa7'
         AND min(expected_latest_set_hash)='f813d2d8bfa4609f83b2bfd181de3e17' AND min(observed_latest_set_hash)='f813d2d8bfa4609f83b2bfd181de3e17'
         AND min(expected_archive_set_hash)='13d7db24aa254d8efe69b28998d91fd4' AND min(observed_archive_set_hash)='13d7db24aa254d8efe69b28998d91fd4'
         AND min(contract_status)='ACCEPTED' AND min(gate_status)='PASS' AND min(acceptance_evidence_status)='PASS' AND min(certification_status)='PASS'
         AND min(required_source_edge_count)=1 AND min(passed_source_edge_count)=1
         AND count(*) FILTER (WHERE row_hash IS DISTINCT FROM md5((to_jsonb(c)-'row_hash'-'created_at')::text))=0) AS pass_flag,
        'Frozen contract identity and copied accepted-source hashes for component M2_ELIGIBILITY_ROUTING_CONSUMPTION.'::text AS interpretation
    FROM c
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_038_COMPONENT_02_M2_ELIGIBILITY_ROUTING_CONSUMPTION_LINEAGE */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    38::smallint,
    'M2_12_POS_038_COMPONENT_02_M2_ELIGIBILITY_ROUTING_CONSUMPTION_LINEAGE'::text,
    3::smallint,
    'COMPONENT_CONTRACT'::text,
    'Component 02 M2_ELIGIBILITY_ROUTING_CONSUMPTION physical relation, business-key, edge, and reproduction lineage is exact'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH c AS (
        SELECT t.* FROM msbf_m2.module2_contract_component_snapshot t
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id
        WHERE t.component_sequence=2 AND t.component_contract_code='M2_ELIGIBILITY_ROUTING_CONSUMPTION' AND t.contract_version=1
    ), r AS (
        SELECT t.* FROM msbf_m2.module2_contract_reproduction_snapshot t
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id
        WHERE t.component_sequence=2 AND t.component_contract_code='M2_ELIGIBILITY_ROUTING_CONSUMPTION' AND t.contract_version=1
    )
    SELECT
        concat_ws('|',(SELECT count(*) FROM c),(SELECT min(registry_relation) FROM c),(SELECT min(latest_relation) FROM c),(SELECT min(archive_relation) FROM c),
            (SELECT min(latest_business_grain) FROM c),(SELECT min(latest_business_key_columns::text) FROM c),(SELECT min(archive_business_key_columns::text) FROM c),
            (SELECT min(required_source_edge_count)::text FROM c),(SELECT min(passed_source_edge_count)::text FROM c),(SELECT count(*) FROM r),
            (SELECT min(reproduction_status) FROM r),(SELECT min(archive_trigger_status) FROM r)) AS observed_value,
        '1|msbf_ctl.m2_1_strategy_contract_registry|msbf_m2.application_eligibility_routing_latest|msbf_m2.application_eligibility_routing_archive|module1_run_id + strategy_campaign_code + scenario_id + merchant_application_id|["module1_run_id","strategy_campaign_code","scenario_id","merchant_application_id"]|["module1_run_id","contract_code","contract_version","strategy_campaign_code","scenario_id","merchant_application_id"]|1|1|1|PASS|PASS'::text AS expected_value,
        ((SELECT (count(*)<>1)::integer FROM c)
         +(SELECT count(*) FILTER (WHERE registry_relation<>'msbf_ctl.m2_1_strategy_contract_registry' OR latest_relation<>'msbf_m2.application_eligibility_routing_latest' OR archive_relation<>'msbf_m2.application_eligibility_routing_archive' OR latest_business_grain<>'module1_run_id + strategy_campaign_code + scenario_id + merchant_application_id'
                   OR latest_business_key_columns<>'["module1_run_id","strategy_campaign_code","scenario_id","merchant_application_id"]'::jsonb OR archive_business_key_columns<>'["module1_run_id","contract_code","contract_version","strategy_campaign_code","scenario_id","merchant_application_id"]'::jsonb
                   OR required_source_edge_codes<>ARRAY['M1_17_TO_M2_1']::text[] OR required_source_edge_count<>1 OR passed_source_edge_count<>1) FROM c)
         +(SELECT (count(*)<>1)::integer FROM r)
         +(SELECT count(*) FILTER (WHERE registry_relation<>'msbf_ctl.m2_1_strategy_contract_registry' OR latest_relation<>'msbf_m2.application_eligibility_routing_latest' OR archive_relation<>'msbf_m2.application_eligibility_routing_archive'
                   OR latest_business_key_columns<>'["module1_run_id","strategy_campaign_code","scenario_id","merchant_application_id"]'::jsonb OR archive_business_key_columns<>'["module1_run_id","contract_code","contract_version","strategy_campaign_code","scenario_id","merchant_application_id"]'::jsonb
                   OR expected_latest_rows<>1500 OR observed_latest_rows<>1500
                   OR expected_archive_rows<>1500 OR observed_archive_rows<>1500
                   OR expected_latest_set_hash<>'f813d2d8bfa4609f83b2bfd181de3e17' OR observed_latest_set_hash<>'f813d2d8bfa4609f83b2bfd181de3e17'
                   OR expected_archive_set_hash<>'13d7db24aa254d8efe69b28998d91fd4' OR observed_archive_set_hash<>'13d7db24aa254d8efe69b28998d91fd4'
                   OR payload_mismatch_count<>0 OR missing_latest_rows<>0 OR missing_archive_rows<>0 OR latest_duplicate_key_rows<>0 OR archive_duplicate_key_rows<>0
                   OR archive_trigger_status<>'PASS' OR reproduction_status<>'PASS' OR source_registry_row_hash<>'e3fe1ae397c76da8f6ba88649935cfa7'
                   OR row_hash IS DISTINCT FROM md5((to_jsonb(r)-'row_hash'-'created_at')::text)) FROM r))::bigint AS mismatch_count,
        ((SELECT count(*)=1 FROM c)
         AND (SELECT count(*)=0 FROM c WHERE registry_relation<>'msbf_ctl.m2_1_strategy_contract_registry' OR latest_relation<>'msbf_m2.application_eligibility_routing_latest' OR archive_relation<>'msbf_m2.application_eligibility_routing_archive' OR latest_business_grain<>'module1_run_id + strategy_campaign_code + scenario_id + merchant_application_id'
              OR latest_business_key_columns<>'["module1_run_id","strategy_campaign_code","scenario_id","merchant_application_id"]'::jsonb OR archive_business_key_columns<>'["module1_run_id","contract_code","contract_version","strategy_campaign_code","scenario_id","merchant_application_id"]'::jsonb
              OR required_source_edge_codes<>ARRAY['M1_17_TO_M2_1']::text[] OR required_source_edge_count<>1 OR passed_source_edge_count<>1)
         AND (SELECT count(*)=1 FROM r)
         AND (SELECT count(*)=0 FROM r WHERE registry_relation<>'msbf_ctl.m2_1_strategy_contract_registry' OR latest_relation<>'msbf_m2.application_eligibility_routing_latest' OR archive_relation<>'msbf_m2.application_eligibility_routing_archive'
              OR latest_business_key_columns<>'["module1_run_id","strategy_campaign_code","scenario_id","merchant_application_id"]'::jsonb OR archive_business_key_columns<>'["module1_run_id","contract_code","contract_version","strategy_campaign_code","scenario_id","merchant_application_id"]'::jsonb
              OR expected_latest_rows<>1500 OR observed_latest_rows<>1500
              OR expected_archive_rows<>1500 OR observed_archive_rows<>1500
              OR expected_latest_set_hash<>'f813d2d8bfa4609f83b2bfd181de3e17' OR observed_latest_set_hash<>'f813d2d8bfa4609f83b2bfd181de3e17'
              OR expected_archive_set_hash<>'13d7db24aa254d8efe69b28998d91fd4' OR observed_archive_set_hash<>'13d7db24aa254d8efe69b28998d91fd4'
              OR payload_mismatch_count<>0 OR missing_latest_rows<>0 OR missing_archive_rows<>0 OR latest_duplicate_key_rows<>0 OR archive_duplicate_key_rows<>0
              OR archive_trigger_status<>'PASS' OR reproduction_status<>'PASS' OR source_registry_row_hash<>'e3fe1ae397c76da8f6ba88649935cfa7'
              OR row_hash IS DISTINCT FROM md5((to_jsonb(r)-'row_hash'-'created_at')::text))) AS pass_flag,
        'Physical relation, business-key, source-edge, and reproduction lineage for component M2_ELIGIBILITY_ROUTING_CONSUMPTION.'::text AS interpretation
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_039_COMPONENT_03_M2_REQUEST_STRUCTURE_CONSUMPTION_IDENTITY */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    39::smallint,
    'M2_12_POS_039_COMPONENT_03_M2_REQUEST_STRUCTURE_CONSUMPTION_IDENTITY'::text,
    3::smallint,
    'COMPONENT_CONTRACT'::text,
    'Component 03 M2_REQUEST_STRUCTURE_CONSUMPTION identity, counts, hashes, and statuses are exact'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH c AS (
        SELECT t.* FROM msbf_m2.module2_contract_component_snapshot t
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id
        WHERE t.component_sequence=3 AND t.component_contract_code='M2_REQUEST_STRUCTURE_CONSUMPTION' AND t.contract_version=1
    )
    SELECT
        concat_ws('|',count(*)::text,min(component_contract_code),min(contract_version)::text,min(schema_version),min(methodology_version),
            min(expected_latest_rows)::text,min(observed_latest_rows)::text,min(expected_archive_rows)::text,min(observed_archive_rows)::text,
            min(observed_contract_set_hash),min(observed_stage_combined_set_hash),min(observed_registry_row_hash),min(observed_latest_set_hash),min(observed_archive_set_hash),
            min(contract_status),min(gate_status),min(acceptance_evidence_status),min(certification_status),
            count(*) FILTER (WHERE row_hash IS DISTINCT FROM md5((to_jsonb(c)-'row_hash'-'created_at')::text))::text) AS observed_value,
        '1|M2_REQUEST_STRUCTURE_CONSUMPTION|1|M2_2_REQUEST_STRUCTURE_SCHEMA_V1|M2_2_METHOD_V1|750|750|750|750|89d21438326f33a6df82ee667590497b|bbe83b187b31ea561789797322031fc6|32374a67d0f8ead18af4bc18139ffdd6|da27dcb509a8c0bf3bc7a046242a2c02|c397c86ab234243dc11ab84b9e98eb6f|ACCEPTED|PASS|PASS|PASS|0'::text AS expected_value,
        (CASE WHEN count(*)=1 AND min(certification_node_sequence)=3
                   AND min(stage_code)='M2_2_PRICING_STRUCTURE' AND min(repository_stage)='21_M2_2'
                   AND min(component_contract_code)='M2_REQUEST_STRUCTURE_CONSUMPTION' AND min(contract_version)=1
                   AND min(schema_version)='M2_2_REQUEST_STRUCTURE_SCHEMA_V1' AND min(methodology_version)='M2_2_METHOD_V1'
                   AND min(acceptance_gate_id)='M2_2_PRICING_STRUCTURE_COUNTEROFFER'
                   AND min(expected_latest_rows)=750 AND min(observed_latest_rows)=750
                   AND min(expected_archive_rows)=750 AND min(observed_archive_rows)=750
                   AND min(stage_expected_canonical_entities)=7336
                   AND min(expected_positive_controls)=120 AND min(observed_positive_controls)=120
                   AND min(expected_negative_controls)=20 AND min(observed_negative_controls)=20
                   AND min(expected_contract_set_hash)='89d21438326f33a6df82ee667590497b' AND min(observed_contract_set_hash)='89d21438326f33a6df82ee667590497b'
                   AND min(expected_stage_combined_set_hash)='bbe83b187b31ea561789797322031fc6' AND min(observed_stage_combined_set_hash)='bbe83b187b31ea561789797322031fc6'
                   AND min(expected_registry_row_hash)='32374a67d0f8ead18af4bc18139ffdd6' AND min(observed_registry_row_hash)='32374a67d0f8ead18af4bc18139ffdd6'
                   AND min(expected_latest_set_hash)='da27dcb509a8c0bf3bc7a046242a2c02' AND min(observed_latest_set_hash)='da27dcb509a8c0bf3bc7a046242a2c02'
                   AND min(expected_archive_set_hash)='c397c86ab234243dc11ab84b9e98eb6f' AND min(observed_archive_set_hash)='c397c86ab234243dc11ab84b9e98eb6f'
                   AND min(contract_status)='ACCEPTED' AND min(gate_status)='PASS' AND min(acceptance_evidence_status)='PASS' AND min(certification_status)='PASS'
                   AND min(required_source_edge_count)=2 AND min(passed_source_edge_count)=2
                   AND count(*) FILTER (WHERE row_hash IS DISTINCT FROM md5((to_jsonb(c)-'row_hash'-'created_at')::text))=0
              THEN 0 ELSE 1 END)::bigint AS mismatch_count,
        (count(*)=1 AND min(certification_node_sequence)=3
         AND min(stage_code)='M2_2_PRICING_STRUCTURE' AND min(repository_stage)='21_M2_2'
         AND min(component_contract_code)='M2_REQUEST_STRUCTURE_CONSUMPTION' AND min(contract_version)=1
         AND min(schema_version)='M2_2_REQUEST_STRUCTURE_SCHEMA_V1' AND min(methodology_version)='M2_2_METHOD_V1'
         AND min(acceptance_gate_id)='M2_2_PRICING_STRUCTURE_COUNTEROFFER'
         AND min(expected_latest_rows)=750 AND min(observed_latest_rows)=750
         AND min(expected_archive_rows)=750 AND min(observed_archive_rows)=750
         AND min(stage_expected_canonical_entities)=7336
         AND min(expected_positive_controls)=120 AND min(observed_positive_controls)=120
         AND min(expected_negative_controls)=20 AND min(observed_negative_controls)=20
         AND min(expected_contract_set_hash)='89d21438326f33a6df82ee667590497b' AND min(observed_contract_set_hash)='89d21438326f33a6df82ee667590497b'
         AND min(expected_stage_combined_set_hash)='bbe83b187b31ea561789797322031fc6' AND min(observed_stage_combined_set_hash)='bbe83b187b31ea561789797322031fc6'
         AND min(expected_registry_row_hash)='32374a67d0f8ead18af4bc18139ffdd6' AND min(observed_registry_row_hash)='32374a67d0f8ead18af4bc18139ffdd6'
         AND min(expected_latest_set_hash)='da27dcb509a8c0bf3bc7a046242a2c02' AND min(observed_latest_set_hash)='da27dcb509a8c0bf3bc7a046242a2c02'
         AND min(expected_archive_set_hash)='c397c86ab234243dc11ab84b9e98eb6f' AND min(observed_archive_set_hash)='c397c86ab234243dc11ab84b9e98eb6f'
         AND min(contract_status)='ACCEPTED' AND min(gate_status)='PASS' AND min(acceptance_evidence_status)='PASS' AND min(certification_status)='PASS'
         AND min(required_source_edge_count)=2 AND min(passed_source_edge_count)=2
         AND count(*) FILTER (WHERE row_hash IS DISTINCT FROM md5((to_jsonb(c)-'row_hash'-'created_at')::text))=0) AS pass_flag,
        'Frozen contract identity and copied accepted-source hashes for component M2_REQUEST_STRUCTURE_CONSUMPTION.'::text AS interpretation
    FROM c
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_040_COMPONENT_03_M2_REQUEST_STRUCTURE_CONSUMPTION_LINEAGE */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    40::smallint,
    'M2_12_POS_040_COMPONENT_03_M2_REQUEST_STRUCTURE_CONSUMPTION_LINEAGE'::text,
    3::smallint,
    'COMPONENT_CONTRACT'::text,
    'Component 03 M2_REQUEST_STRUCTURE_CONSUMPTION physical relation, business-key, edge, and reproduction lineage is exact'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH c AS (
        SELECT t.* FROM msbf_m2.module2_contract_component_snapshot t
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id
        WHERE t.component_sequence=3 AND t.component_contract_code='M2_REQUEST_STRUCTURE_CONSUMPTION' AND t.contract_version=1
    ), r AS (
        SELECT t.* FROM msbf_m2.module2_contract_reproduction_snapshot t
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id
        WHERE t.component_sequence=3 AND t.component_contract_code='M2_REQUEST_STRUCTURE_CONSUMPTION' AND t.contract_version=1
    )
    SELECT
        concat_ws('|',(SELECT count(*) FROM c),(SELECT min(registry_relation) FROM c),(SELECT min(latest_relation) FROM c),(SELECT min(archive_relation) FROM c),
            (SELECT min(latest_business_grain) FROM c),(SELECT min(latest_business_key_columns::text) FROM c),(SELECT min(archive_business_key_columns::text) FROM c),
            (SELECT min(required_source_edge_count)::text FROM c),(SELECT min(passed_source_edge_count)::text FROM c),(SELECT count(*) FROM r),
            (SELECT min(reproduction_status) FROM r),(SELECT min(archive_trigger_status) FROM r)) AS observed_value,
        '1|msbf_ctl.m2_2_pricing_structure_contract_registry|msbf_m2.application_request_structure_latest|msbf_m2.application_request_structure_archive|module1_run_id + merchant_application_id|["module1_run_id","merchant_application_id"]|["module1_run_id","contract_code","contract_version","merchant_application_id"]|2|2|1|PASS|PASS'::text AS expected_value,
        ((SELECT (count(*)<>1)::integer FROM c)
         +(SELECT count(*) FILTER (WHERE registry_relation<>'msbf_ctl.m2_2_pricing_structure_contract_registry' OR latest_relation<>'msbf_m2.application_request_structure_latest' OR archive_relation<>'msbf_m2.application_request_structure_archive' OR latest_business_grain<>'module1_run_id + merchant_application_id'
                   OR latest_business_key_columns<>'["module1_run_id","merchant_application_id"]'::jsonb OR archive_business_key_columns<>'["module1_run_id","contract_code","contract_version","merchant_application_id"]'::jsonb
                   OR required_source_edge_codes<>ARRAY['M2_1_TO_M2_2','M1_3_TO_M2_2_REQUEST_AUTHORITY']::text[] OR required_source_edge_count<>2 OR passed_source_edge_count<>2) FROM c)
         +(SELECT (count(*)<>1)::integer FROM r)
         +(SELECT count(*) FILTER (WHERE registry_relation<>'msbf_ctl.m2_2_pricing_structure_contract_registry' OR latest_relation<>'msbf_m2.application_request_structure_latest' OR archive_relation<>'msbf_m2.application_request_structure_archive'
                   OR latest_business_key_columns<>'["module1_run_id","merchant_application_id"]'::jsonb OR archive_business_key_columns<>'["module1_run_id","contract_code","contract_version","merchant_application_id"]'::jsonb
                   OR expected_latest_rows<>750 OR observed_latest_rows<>750
                   OR expected_archive_rows<>750 OR observed_archive_rows<>750
                   OR expected_latest_set_hash<>'da27dcb509a8c0bf3bc7a046242a2c02' OR observed_latest_set_hash<>'da27dcb509a8c0bf3bc7a046242a2c02'
                   OR expected_archive_set_hash<>'c397c86ab234243dc11ab84b9e98eb6f' OR observed_archive_set_hash<>'c397c86ab234243dc11ab84b9e98eb6f'
                   OR payload_mismatch_count<>0 OR missing_latest_rows<>0 OR missing_archive_rows<>0 OR latest_duplicate_key_rows<>0 OR archive_duplicate_key_rows<>0
                   OR archive_trigger_status<>'PASS' OR reproduction_status<>'PASS' OR source_registry_row_hash<>'32374a67d0f8ead18af4bc18139ffdd6'
                   OR row_hash IS DISTINCT FROM md5((to_jsonb(r)-'row_hash'-'created_at')::text)) FROM r))::bigint AS mismatch_count,
        ((SELECT count(*)=1 FROM c)
         AND (SELECT count(*)=0 FROM c WHERE registry_relation<>'msbf_ctl.m2_2_pricing_structure_contract_registry' OR latest_relation<>'msbf_m2.application_request_structure_latest' OR archive_relation<>'msbf_m2.application_request_structure_archive' OR latest_business_grain<>'module1_run_id + merchant_application_id'
              OR latest_business_key_columns<>'["module1_run_id","merchant_application_id"]'::jsonb OR archive_business_key_columns<>'["module1_run_id","contract_code","contract_version","merchant_application_id"]'::jsonb
              OR required_source_edge_codes<>ARRAY['M2_1_TO_M2_2','M1_3_TO_M2_2_REQUEST_AUTHORITY']::text[] OR required_source_edge_count<>2 OR passed_source_edge_count<>2)
         AND (SELECT count(*)=1 FROM r)
         AND (SELECT count(*)=0 FROM r WHERE registry_relation<>'msbf_ctl.m2_2_pricing_structure_contract_registry' OR latest_relation<>'msbf_m2.application_request_structure_latest' OR archive_relation<>'msbf_m2.application_request_structure_archive'
              OR latest_business_key_columns<>'["module1_run_id","merchant_application_id"]'::jsonb OR archive_business_key_columns<>'["module1_run_id","contract_code","contract_version","merchant_application_id"]'::jsonb
              OR expected_latest_rows<>750 OR observed_latest_rows<>750
              OR expected_archive_rows<>750 OR observed_archive_rows<>750
              OR expected_latest_set_hash<>'da27dcb509a8c0bf3bc7a046242a2c02' OR observed_latest_set_hash<>'da27dcb509a8c0bf3bc7a046242a2c02'
              OR expected_archive_set_hash<>'c397c86ab234243dc11ab84b9e98eb6f' OR observed_archive_set_hash<>'c397c86ab234243dc11ab84b9e98eb6f'
              OR payload_mismatch_count<>0 OR missing_latest_rows<>0 OR missing_archive_rows<>0 OR latest_duplicate_key_rows<>0 OR archive_duplicate_key_rows<>0
              OR archive_trigger_status<>'PASS' OR reproduction_status<>'PASS' OR source_registry_row_hash<>'32374a67d0f8ead18af4bc18139ffdd6'
              OR row_hash IS DISTINCT FROM md5((to_jsonb(r)-'row_hash'-'created_at')::text))) AS pass_flag,
        'Physical relation, business-key, source-edge, and reproduction lineage for component M2_REQUEST_STRUCTURE_CONSUMPTION.'::text AS interpretation
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_041_COMPONENT_04_M2_PRICING_STRUCTURE_CONSUMPTION_IDENTITY */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    41::smallint,
    'M2_12_POS_041_COMPONENT_04_M2_PRICING_STRUCTURE_CONSUMPTION_IDENTITY'::text,
    3::smallint,
    'COMPONENT_CONTRACT'::text,
    'Component 04 M2_PRICING_STRUCTURE_CONSUMPTION identity, counts, hashes, and statuses are exact'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH c AS (
        SELECT t.* FROM msbf_m2.module2_contract_component_snapshot t
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id
        WHERE t.component_sequence=4 AND t.component_contract_code='M2_PRICING_STRUCTURE_CONSUMPTION' AND t.contract_version=1
    )
    SELECT
        concat_ws('|',count(*)::text,min(component_contract_code),min(contract_version)::text,min(schema_version),min(methodology_version),
            min(expected_latest_rows)::text,min(observed_latest_rows)::text,min(expected_archive_rows)::text,min(observed_archive_rows)::text,
            min(observed_contract_set_hash),min(observed_stage_combined_set_hash),min(observed_registry_row_hash),min(observed_latest_set_hash),min(observed_archive_set_hash),
            min(contract_status),min(gate_status),min(acceptance_evidence_status),min(certification_status),
            count(*) FILTER (WHERE row_hash IS DISTINCT FROM md5((to_jsonb(c)-'row_hash'-'created_at')::text))::text) AS observed_value,
        '1|M2_PRICING_STRUCTURE_CONSUMPTION|1|M2_2_PRICING_STRUCTURE_SCHEMA_V1|M2_2_METHOD_V1|1500|1500|1500|1500|e2d8c2eeaddbb1a8f7d2baa10b4cdbd3|bbe83b187b31ea561789797322031fc6|32374a67d0f8ead18af4bc18139ffdd6|a69d1fca447bb573040bf697c43ce1af|9e43326cd8f79b98c19f02f971fb077f|ACCEPTED|PASS|PASS|PASS|0'::text AS expected_value,
        (CASE WHEN count(*)=1 AND min(certification_node_sequence)=3
                   AND min(stage_code)='M2_2_PRICING_STRUCTURE' AND min(repository_stage)='21_M2_2'
                   AND min(component_contract_code)='M2_PRICING_STRUCTURE_CONSUMPTION' AND min(contract_version)=1
                   AND min(schema_version)='M2_2_PRICING_STRUCTURE_SCHEMA_V1' AND min(methodology_version)='M2_2_METHOD_V1'
                   AND min(acceptance_gate_id)='M2_2_PRICING_STRUCTURE_COUNTEROFFER'
                   AND min(expected_latest_rows)=1500 AND min(observed_latest_rows)=1500
                   AND min(expected_archive_rows)=1500 AND min(observed_archive_rows)=1500
                   AND min(stage_expected_canonical_entities)=7336
                   AND min(expected_positive_controls)=120 AND min(observed_positive_controls)=120
                   AND min(expected_negative_controls)=20 AND min(observed_negative_controls)=20
                   AND min(expected_contract_set_hash)='e2d8c2eeaddbb1a8f7d2baa10b4cdbd3' AND min(observed_contract_set_hash)='e2d8c2eeaddbb1a8f7d2baa10b4cdbd3'
                   AND min(expected_stage_combined_set_hash)='bbe83b187b31ea561789797322031fc6' AND min(observed_stage_combined_set_hash)='bbe83b187b31ea561789797322031fc6'
                   AND min(expected_registry_row_hash)='32374a67d0f8ead18af4bc18139ffdd6' AND min(observed_registry_row_hash)='32374a67d0f8ead18af4bc18139ffdd6'
                   AND min(expected_latest_set_hash)='a69d1fca447bb573040bf697c43ce1af' AND min(observed_latest_set_hash)='a69d1fca447bb573040bf697c43ce1af'
                   AND min(expected_archive_set_hash)='9e43326cd8f79b98c19f02f971fb077f' AND min(observed_archive_set_hash)='9e43326cd8f79b98c19f02f971fb077f'
                   AND min(contract_status)='ACCEPTED' AND min(gate_status)='PASS' AND min(acceptance_evidence_status)='PASS' AND min(certification_status)='PASS'
                   AND min(required_source_edge_count)=2 AND min(passed_source_edge_count)=2
                   AND count(*) FILTER (WHERE row_hash IS DISTINCT FROM md5((to_jsonb(c)-'row_hash'-'created_at')::text))=0
              THEN 0 ELSE 1 END)::bigint AS mismatch_count,
        (count(*)=1 AND min(certification_node_sequence)=3
         AND min(stage_code)='M2_2_PRICING_STRUCTURE' AND min(repository_stage)='21_M2_2'
         AND min(component_contract_code)='M2_PRICING_STRUCTURE_CONSUMPTION' AND min(contract_version)=1
         AND min(schema_version)='M2_2_PRICING_STRUCTURE_SCHEMA_V1' AND min(methodology_version)='M2_2_METHOD_V1'
         AND min(acceptance_gate_id)='M2_2_PRICING_STRUCTURE_COUNTEROFFER'
         AND min(expected_latest_rows)=1500 AND min(observed_latest_rows)=1500
         AND min(expected_archive_rows)=1500 AND min(observed_archive_rows)=1500
         AND min(stage_expected_canonical_entities)=7336
         AND min(expected_positive_controls)=120 AND min(observed_positive_controls)=120
         AND min(expected_negative_controls)=20 AND min(observed_negative_controls)=20
         AND min(expected_contract_set_hash)='e2d8c2eeaddbb1a8f7d2baa10b4cdbd3' AND min(observed_contract_set_hash)='e2d8c2eeaddbb1a8f7d2baa10b4cdbd3'
         AND min(expected_stage_combined_set_hash)='bbe83b187b31ea561789797322031fc6' AND min(observed_stage_combined_set_hash)='bbe83b187b31ea561789797322031fc6'
         AND min(expected_registry_row_hash)='32374a67d0f8ead18af4bc18139ffdd6' AND min(observed_registry_row_hash)='32374a67d0f8ead18af4bc18139ffdd6'
         AND min(expected_latest_set_hash)='a69d1fca447bb573040bf697c43ce1af' AND min(observed_latest_set_hash)='a69d1fca447bb573040bf697c43ce1af'
         AND min(expected_archive_set_hash)='9e43326cd8f79b98c19f02f971fb077f' AND min(observed_archive_set_hash)='9e43326cd8f79b98c19f02f971fb077f'
         AND min(contract_status)='ACCEPTED' AND min(gate_status)='PASS' AND min(acceptance_evidence_status)='PASS' AND min(certification_status)='PASS'
         AND min(required_source_edge_count)=2 AND min(passed_source_edge_count)=2
         AND count(*) FILTER (WHERE row_hash IS DISTINCT FROM md5((to_jsonb(c)-'row_hash'-'created_at')::text))=0) AS pass_flag,
        'Frozen contract identity and copied accepted-source hashes for component M2_PRICING_STRUCTURE_CONSUMPTION.'::text AS interpretation
    FROM c
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_042_COMPONENT_04_M2_PRICING_STRUCTURE_CONSUMPTION_LINEAGE */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    42::smallint,
    'M2_12_POS_042_COMPONENT_04_M2_PRICING_STRUCTURE_CONSUMPTION_LINEAGE'::text,
    3::smallint,
    'COMPONENT_CONTRACT'::text,
    'Component 04 M2_PRICING_STRUCTURE_CONSUMPTION physical relation, business-key, edge, and reproduction lineage is exact'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH c AS (
        SELECT t.* FROM msbf_m2.module2_contract_component_snapshot t
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id
        WHERE t.component_sequence=4 AND t.component_contract_code='M2_PRICING_STRUCTURE_CONSUMPTION' AND t.contract_version=1
    ), r AS (
        SELECT t.* FROM msbf_m2.module2_contract_reproduction_snapshot t
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id
        WHERE t.component_sequence=4 AND t.component_contract_code='M2_PRICING_STRUCTURE_CONSUMPTION' AND t.contract_version=1
    )
    SELECT
        concat_ws('|',(SELECT count(*) FROM c),(SELECT min(registry_relation) FROM c),(SELECT min(latest_relation) FROM c),(SELECT min(archive_relation) FROM c),
            (SELECT min(latest_business_grain) FROM c),(SELECT min(latest_business_key_columns::text) FROM c),(SELECT min(archive_business_key_columns::text) FROM c),
            (SELECT min(required_source_edge_count)::text FROM c),(SELECT min(passed_source_edge_count)::text FROM c),(SELECT count(*) FROM r),
            (SELECT min(reproduction_status) FROM r),(SELECT min(archive_trigger_status) FROM r)) AS observed_value,
        '1|msbf_ctl.m2_2_pricing_structure_contract_registry|msbf_m2.application_pricing_structure_latest|msbf_m2.application_pricing_structure_archive|module1_run_id + scenario_id + merchant_application_id|["module1_run_id","scenario_id","merchant_application_id"]|["module1_run_id","contract_code","contract_version","scenario_id","merchant_application_id"]|2|2|1|PASS|PASS'::text AS expected_value,
        ((SELECT (count(*)<>1)::integer FROM c)
         +(SELECT count(*) FILTER (WHERE registry_relation<>'msbf_ctl.m2_2_pricing_structure_contract_registry' OR latest_relation<>'msbf_m2.application_pricing_structure_latest' OR archive_relation<>'msbf_m2.application_pricing_structure_archive' OR latest_business_grain<>'module1_run_id + scenario_id + merchant_application_id'
                   OR latest_business_key_columns<>'["module1_run_id","scenario_id","merchant_application_id"]'::jsonb OR archive_business_key_columns<>'["module1_run_id","contract_code","contract_version","scenario_id","merchant_application_id"]'::jsonb
                   OR required_source_edge_codes<>ARRAY['M2_1_TO_M2_2','M1_3_TO_M2_2_REQUEST_AUTHORITY']::text[] OR required_source_edge_count<>2 OR passed_source_edge_count<>2) FROM c)
         +(SELECT (count(*)<>1)::integer FROM r)
         +(SELECT count(*) FILTER (WHERE registry_relation<>'msbf_ctl.m2_2_pricing_structure_contract_registry' OR latest_relation<>'msbf_m2.application_pricing_structure_latest' OR archive_relation<>'msbf_m2.application_pricing_structure_archive'
                   OR latest_business_key_columns<>'["module1_run_id","scenario_id","merchant_application_id"]'::jsonb OR archive_business_key_columns<>'["module1_run_id","contract_code","contract_version","scenario_id","merchant_application_id"]'::jsonb
                   OR expected_latest_rows<>1500 OR observed_latest_rows<>1500
                   OR expected_archive_rows<>1500 OR observed_archive_rows<>1500
                   OR expected_latest_set_hash<>'a69d1fca447bb573040bf697c43ce1af' OR observed_latest_set_hash<>'a69d1fca447bb573040bf697c43ce1af'
                   OR expected_archive_set_hash<>'9e43326cd8f79b98c19f02f971fb077f' OR observed_archive_set_hash<>'9e43326cd8f79b98c19f02f971fb077f'
                   OR payload_mismatch_count<>0 OR missing_latest_rows<>0 OR missing_archive_rows<>0 OR latest_duplicate_key_rows<>0 OR archive_duplicate_key_rows<>0
                   OR archive_trigger_status<>'PASS' OR reproduction_status<>'PASS' OR source_registry_row_hash<>'32374a67d0f8ead18af4bc18139ffdd6'
                   OR row_hash IS DISTINCT FROM md5((to_jsonb(r)-'row_hash'-'created_at')::text)) FROM r))::bigint AS mismatch_count,
        ((SELECT count(*)=1 FROM c)
         AND (SELECT count(*)=0 FROM c WHERE registry_relation<>'msbf_ctl.m2_2_pricing_structure_contract_registry' OR latest_relation<>'msbf_m2.application_pricing_structure_latest' OR archive_relation<>'msbf_m2.application_pricing_structure_archive' OR latest_business_grain<>'module1_run_id + scenario_id + merchant_application_id'
              OR latest_business_key_columns<>'["module1_run_id","scenario_id","merchant_application_id"]'::jsonb OR archive_business_key_columns<>'["module1_run_id","contract_code","contract_version","scenario_id","merchant_application_id"]'::jsonb
              OR required_source_edge_codes<>ARRAY['M2_1_TO_M2_2','M1_3_TO_M2_2_REQUEST_AUTHORITY']::text[] OR required_source_edge_count<>2 OR passed_source_edge_count<>2)
         AND (SELECT count(*)=1 FROM r)
         AND (SELECT count(*)=0 FROM r WHERE registry_relation<>'msbf_ctl.m2_2_pricing_structure_contract_registry' OR latest_relation<>'msbf_m2.application_pricing_structure_latest' OR archive_relation<>'msbf_m2.application_pricing_structure_archive'
              OR latest_business_key_columns<>'["module1_run_id","scenario_id","merchant_application_id"]'::jsonb OR archive_business_key_columns<>'["module1_run_id","contract_code","contract_version","scenario_id","merchant_application_id"]'::jsonb
              OR expected_latest_rows<>1500 OR observed_latest_rows<>1500
              OR expected_archive_rows<>1500 OR observed_archive_rows<>1500
              OR expected_latest_set_hash<>'a69d1fca447bb573040bf697c43ce1af' OR observed_latest_set_hash<>'a69d1fca447bb573040bf697c43ce1af'
              OR expected_archive_set_hash<>'9e43326cd8f79b98c19f02f971fb077f' OR observed_archive_set_hash<>'9e43326cd8f79b98c19f02f971fb077f'
              OR payload_mismatch_count<>0 OR missing_latest_rows<>0 OR missing_archive_rows<>0 OR latest_duplicate_key_rows<>0 OR archive_duplicate_key_rows<>0
              OR archive_trigger_status<>'PASS' OR reproduction_status<>'PASS' OR source_registry_row_hash<>'32374a67d0f8ead18af4bc18139ffdd6'
              OR row_hash IS DISTINCT FROM md5((to_jsonb(r)-'row_hash'-'created_at')::text))) AS pass_flag,
        'Physical relation, business-key, source-edge, and reproduction lineage for component M2_PRICING_STRUCTURE_CONSUMPTION.'::text AS interpretation
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_043_COMPONENT_05_M2_FINAL_OFFER_DECISION_CONSUMPTION_IDENTITY */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    43::smallint,
    'M2_12_POS_043_COMPONENT_05_M2_FINAL_OFFER_DECISION_CONSUMPTION_IDENTITY'::text,
    3::smallint,
    'COMPONENT_CONTRACT'::text,
    'Component 05 M2_FINAL_OFFER_DECISION_CONSUMPTION identity, counts, hashes, and statuses are exact'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH c AS (
        SELECT t.* FROM msbf_m2.module2_contract_component_snapshot t
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id
        WHERE t.component_sequence=5 AND t.component_contract_code='M2_FINAL_OFFER_DECISION_CONSUMPTION' AND t.contract_version=1
    )
    SELECT
        concat_ws('|',count(*)::text,min(component_contract_code),min(contract_version)::text,min(schema_version),min(methodology_version),
            min(expected_latest_rows)::text,min(observed_latest_rows)::text,min(expected_archive_rows)::text,min(observed_archive_rows)::text,
            min(observed_contract_set_hash),min(observed_stage_combined_set_hash),min(observed_registry_row_hash),min(observed_latest_set_hash),min(observed_archive_set_hash),
            min(contract_status),min(gate_status),min(acceptance_evidence_status),min(certification_status),
            count(*) FILTER (WHERE row_hash IS DISTINCT FROM md5((to_jsonb(c)-'row_hash'-'created_at')::text))::text) AS observed_value,
        '1|M2_FINAL_OFFER_DECISION_CONSUMPTION|1|M2_3_FINAL_DECISION_SCHEMA_V1|M2_3_METHOD_V1|1500|1500|1500|1500|cbe8c4a4e5d5e4d6d084ce812a64eb84|bf09349b06ede7e5a2ec830c2f9ffe90|03ef3d5ffa4c49d982b3877c4002de2d|8f421bd27d52e18770cee8fb8a72edf1|06331f681706a5b9922865ccbe900755|ACCEPTED|PASS|PASS|PASS|0'::text AS expected_value,
        (CASE WHEN count(*)=1 AND min(certification_node_sequence)=4
                   AND min(stage_code)='M2_3_FINAL_DECISION' AND min(repository_stage)='22_M2_3'
                   AND min(component_contract_code)='M2_FINAL_OFFER_DECISION_CONSUMPTION' AND min(contract_version)=1
                   AND min(schema_version)='M2_3_FINAL_DECISION_SCHEMA_V1' AND min(methodology_version)='M2_3_METHOD_V1'
                   AND min(acceptance_gate_id)='M2_3_FINAL_OFFER_DECISION_AUTHORIZATION'
                   AND min(expected_latest_rows)=1500 AND min(observed_latest_rows)=1500
                   AND min(expected_archive_rows)=1500 AND min(observed_archive_rows)=1500
                   AND min(stage_expected_canonical_entities)=6029
                   AND min(expected_positive_controls)=120 AND min(observed_positive_controls)=120
                   AND min(expected_negative_controls)=20 AND min(observed_negative_controls)=20
                   AND min(expected_contract_set_hash)='cbe8c4a4e5d5e4d6d084ce812a64eb84' AND min(observed_contract_set_hash)='cbe8c4a4e5d5e4d6d084ce812a64eb84'
                   AND min(expected_stage_combined_set_hash)='bf09349b06ede7e5a2ec830c2f9ffe90' AND min(observed_stage_combined_set_hash)='bf09349b06ede7e5a2ec830c2f9ffe90'
                   AND min(expected_registry_row_hash)='03ef3d5ffa4c49d982b3877c4002de2d' AND min(observed_registry_row_hash)='03ef3d5ffa4c49d982b3877c4002de2d'
                   AND min(expected_latest_set_hash)='8f421bd27d52e18770cee8fb8a72edf1' AND min(observed_latest_set_hash)='8f421bd27d52e18770cee8fb8a72edf1'
                   AND min(expected_archive_set_hash)='06331f681706a5b9922865ccbe900755' AND min(observed_archive_set_hash)='06331f681706a5b9922865ccbe900755'
                   AND min(contract_status)='ACCEPTED' AND min(gate_status)='PASS' AND min(acceptance_evidence_status)='PASS' AND min(certification_status)='PASS'
                   AND min(required_source_edge_count)=1 AND min(passed_source_edge_count)=1
                   AND count(*) FILTER (WHERE row_hash IS DISTINCT FROM md5((to_jsonb(c)-'row_hash'-'created_at')::text))=0
              THEN 0 ELSE 1 END)::bigint AS mismatch_count,
        (count(*)=1 AND min(certification_node_sequence)=4
         AND min(stage_code)='M2_3_FINAL_DECISION' AND min(repository_stage)='22_M2_3'
         AND min(component_contract_code)='M2_FINAL_OFFER_DECISION_CONSUMPTION' AND min(contract_version)=1
         AND min(schema_version)='M2_3_FINAL_DECISION_SCHEMA_V1' AND min(methodology_version)='M2_3_METHOD_V1'
         AND min(acceptance_gate_id)='M2_3_FINAL_OFFER_DECISION_AUTHORIZATION'
         AND min(expected_latest_rows)=1500 AND min(observed_latest_rows)=1500
         AND min(expected_archive_rows)=1500 AND min(observed_archive_rows)=1500
         AND min(stage_expected_canonical_entities)=6029
         AND min(expected_positive_controls)=120 AND min(observed_positive_controls)=120
         AND min(expected_negative_controls)=20 AND min(observed_negative_controls)=20
         AND min(expected_contract_set_hash)='cbe8c4a4e5d5e4d6d084ce812a64eb84' AND min(observed_contract_set_hash)='cbe8c4a4e5d5e4d6d084ce812a64eb84'
         AND min(expected_stage_combined_set_hash)='bf09349b06ede7e5a2ec830c2f9ffe90' AND min(observed_stage_combined_set_hash)='bf09349b06ede7e5a2ec830c2f9ffe90'
         AND min(expected_registry_row_hash)='03ef3d5ffa4c49d982b3877c4002de2d' AND min(observed_registry_row_hash)='03ef3d5ffa4c49d982b3877c4002de2d'
         AND min(expected_latest_set_hash)='8f421bd27d52e18770cee8fb8a72edf1' AND min(observed_latest_set_hash)='8f421bd27d52e18770cee8fb8a72edf1'
         AND min(expected_archive_set_hash)='06331f681706a5b9922865ccbe900755' AND min(observed_archive_set_hash)='06331f681706a5b9922865ccbe900755'
         AND min(contract_status)='ACCEPTED' AND min(gate_status)='PASS' AND min(acceptance_evidence_status)='PASS' AND min(certification_status)='PASS'
         AND min(required_source_edge_count)=1 AND min(passed_source_edge_count)=1
         AND count(*) FILTER (WHERE row_hash IS DISTINCT FROM md5((to_jsonb(c)-'row_hash'-'created_at')::text))=0) AS pass_flag,
        'Frozen contract identity and copied accepted-source hashes for component M2_FINAL_OFFER_DECISION_CONSUMPTION.'::text AS interpretation
    FROM c
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_044_COMPONENT_05_M2_FINAL_OFFER_DECISION_CONSUMPTION_LINEAGE */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    44::smallint,
    'M2_12_POS_044_COMPONENT_05_M2_FINAL_OFFER_DECISION_CONSUMPTION_LINEAGE'::text,
    3::smallint,
    'COMPONENT_CONTRACT'::text,
    'Component 05 M2_FINAL_OFFER_DECISION_CONSUMPTION physical relation, business-key, edge, and reproduction lineage is exact'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH c AS (
        SELECT t.* FROM msbf_m2.module2_contract_component_snapshot t
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id
        WHERE t.component_sequence=5 AND t.component_contract_code='M2_FINAL_OFFER_DECISION_CONSUMPTION' AND t.contract_version=1
    ), r AS (
        SELECT t.* FROM msbf_m2.module2_contract_reproduction_snapshot t
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id
        WHERE t.component_sequence=5 AND t.component_contract_code='M2_FINAL_OFFER_DECISION_CONSUMPTION' AND t.contract_version=1
    )
    SELECT
        concat_ws('|',(SELECT count(*) FROM c),(SELECT min(registry_relation) FROM c),(SELECT min(latest_relation) FROM c),(SELECT min(archive_relation) FROM c),
            (SELECT min(latest_business_grain) FROM c),(SELECT min(latest_business_key_columns::text) FROM c),(SELECT min(archive_business_key_columns::text) FROM c),
            (SELECT min(required_source_edge_count)::text FROM c),(SELECT min(passed_source_edge_count)::text FROM c),(SELECT count(*) FROM r),
            (SELECT min(reproduction_status) FROM r),(SELECT min(archive_trigger_status) FROM r)) AS observed_value,
        '1|msbf_ctl.m2_3_final_decision_contract_registry|msbf_m2.application_final_offer_decision_latest|msbf_m2.application_final_offer_decision_archive|module1_run_id + scenario_id + merchant_application_id|["module1_run_id","scenario_id","merchant_application_id"]|["module1_run_id","contract_version","scenario_id","merchant_application_id"]|1|1|1|PASS|PASS'::text AS expected_value,
        ((SELECT (count(*)<>1)::integer FROM c)
         +(SELECT count(*) FILTER (WHERE registry_relation<>'msbf_ctl.m2_3_final_decision_contract_registry' OR latest_relation<>'msbf_m2.application_final_offer_decision_latest' OR archive_relation<>'msbf_m2.application_final_offer_decision_archive' OR latest_business_grain<>'module1_run_id + scenario_id + merchant_application_id'
                   OR latest_business_key_columns<>'["module1_run_id","scenario_id","merchant_application_id"]'::jsonb OR archive_business_key_columns<>'["module1_run_id","contract_version","scenario_id","merchant_application_id"]'::jsonb
                   OR required_source_edge_codes<>ARRAY['M2_2_TO_M2_3']::text[] OR required_source_edge_count<>1 OR passed_source_edge_count<>1) FROM c)
         +(SELECT (count(*)<>1)::integer FROM r)
         +(SELECT count(*) FILTER (WHERE registry_relation<>'msbf_ctl.m2_3_final_decision_contract_registry' OR latest_relation<>'msbf_m2.application_final_offer_decision_latest' OR archive_relation<>'msbf_m2.application_final_offer_decision_archive'
                   OR latest_business_key_columns<>'["module1_run_id","scenario_id","merchant_application_id"]'::jsonb OR archive_business_key_columns<>'["module1_run_id","contract_version","scenario_id","merchant_application_id"]'::jsonb
                   OR expected_latest_rows<>1500 OR observed_latest_rows<>1500
                   OR expected_archive_rows<>1500 OR observed_archive_rows<>1500
                   OR expected_latest_set_hash<>'8f421bd27d52e18770cee8fb8a72edf1' OR observed_latest_set_hash<>'8f421bd27d52e18770cee8fb8a72edf1'
                   OR expected_archive_set_hash<>'06331f681706a5b9922865ccbe900755' OR observed_archive_set_hash<>'06331f681706a5b9922865ccbe900755'
                   OR payload_mismatch_count<>0 OR missing_latest_rows<>0 OR missing_archive_rows<>0 OR latest_duplicate_key_rows<>0 OR archive_duplicate_key_rows<>0
                   OR archive_trigger_status<>'PASS' OR reproduction_status<>'PASS' OR source_registry_row_hash<>'03ef3d5ffa4c49d982b3877c4002de2d'
                   OR row_hash IS DISTINCT FROM md5((to_jsonb(r)-'row_hash'-'created_at')::text)) FROM r))::bigint AS mismatch_count,
        ((SELECT count(*)=1 FROM c)
         AND (SELECT count(*)=0 FROM c WHERE registry_relation<>'msbf_ctl.m2_3_final_decision_contract_registry' OR latest_relation<>'msbf_m2.application_final_offer_decision_latest' OR archive_relation<>'msbf_m2.application_final_offer_decision_archive' OR latest_business_grain<>'module1_run_id + scenario_id + merchant_application_id'
              OR latest_business_key_columns<>'["module1_run_id","scenario_id","merchant_application_id"]'::jsonb OR archive_business_key_columns<>'["module1_run_id","contract_version","scenario_id","merchant_application_id"]'::jsonb
              OR required_source_edge_codes<>ARRAY['M2_2_TO_M2_3']::text[] OR required_source_edge_count<>1 OR passed_source_edge_count<>1)
         AND (SELECT count(*)=1 FROM r)
         AND (SELECT count(*)=0 FROM r WHERE registry_relation<>'msbf_ctl.m2_3_final_decision_contract_registry' OR latest_relation<>'msbf_m2.application_final_offer_decision_latest' OR archive_relation<>'msbf_m2.application_final_offer_decision_archive'
              OR latest_business_key_columns<>'["module1_run_id","scenario_id","merchant_application_id"]'::jsonb OR archive_business_key_columns<>'["module1_run_id","contract_version","scenario_id","merchant_application_id"]'::jsonb
              OR expected_latest_rows<>1500 OR observed_latest_rows<>1500
              OR expected_archive_rows<>1500 OR observed_archive_rows<>1500
              OR expected_latest_set_hash<>'8f421bd27d52e18770cee8fb8a72edf1' OR observed_latest_set_hash<>'8f421bd27d52e18770cee8fb8a72edf1'
              OR expected_archive_set_hash<>'06331f681706a5b9922865ccbe900755' OR observed_archive_set_hash<>'06331f681706a5b9922865ccbe900755'
              OR payload_mismatch_count<>0 OR missing_latest_rows<>0 OR missing_archive_rows<>0 OR latest_duplicate_key_rows<>0 OR archive_duplicate_key_rows<>0
              OR archive_trigger_status<>'PASS' OR reproduction_status<>'PASS' OR source_registry_row_hash<>'03ef3d5ffa4c49d982b3877c4002de2d'
              OR row_hash IS DISTINCT FROM md5((to_jsonb(r)-'row_hash'-'created_at')::text))) AS pass_flag,
        'Physical relation, business-key, source-edge, and reproduction lineage for component M2_FINAL_OFFER_DECISION_CONSUMPTION.'::text AS interpretation
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_045_COMPONENT_06_M2_PORTFOLIO_ACTIVATION_CONSUMPTION_IDENTITY */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    45::smallint,
    'M2_12_POS_045_COMPONENT_06_M2_PORTFOLIO_ACTIVATION_CONSUMPTION_IDENTITY'::text,
    3::smallint,
    'COMPONENT_CONTRACT'::text,
    'Component 06 M2_PORTFOLIO_ACTIVATION_CONSUMPTION identity, counts, hashes, and statuses are exact'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH c AS (
        SELECT t.* FROM msbf_m2.module2_contract_component_snapshot t
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id
        WHERE t.component_sequence=6 AND t.component_contract_code='M2_PORTFOLIO_ACTIVATION_CONSUMPTION' AND t.contract_version=1
    )
    SELECT
        concat_ws('|',count(*)::text,min(component_contract_code),min(contract_version)::text,min(schema_version),min(methodology_version),
            min(expected_latest_rows)::text,min(observed_latest_rows)::text,min(expected_archive_rows)::text,min(observed_archive_rows)::text,
            min(observed_contract_set_hash),min(observed_stage_combined_set_hash),min(observed_registry_row_hash),min(observed_latest_set_hash),min(observed_archive_set_hash),
            min(contract_status),min(gate_status),min(acceptance_evidence_status),min(certification_status),
            count(*) FILTER (WHERE row_hash IS DISTINCT FROM md5((to_jsonb(c)-'row_hash'-'created_at')::text))::text) AS observed_value,
        '1|M2_PORTFOLIO_ACTIVATION_CONSUMPTION|1|M2_4_PORTFOLIO_ACTIVATION_SCHEMA_V1|M2_4_METHOD_V1|1500|1500|1500|1500|fba075bfd6b24e07dc669d6ce25010f1|117450a3eea7bb3d3c74d18cc3c8e96a|879e04636699b51113638ec81d76667b|f26248c112635ebe5254d614f42332d6|bf72bbed8c76db3ecdc6936e78718e04|ACCEPTED|PASS|PASS|PASS|0'::text AS expected_value,
        (CASE WHEN count(*)=1 AND min(certification_node_sequence)=5
                   AND min(stage_code)='M2_4_PORTFOLIO_ACTIVATION' AND min(repository_stage)='23_M2_4'
                   AND min(component_contract_code)='M2_PORTFOLIO_ACTIVATION_CONSUMPTION' AND min(contract_version)=1
                   AND min(schema_version)='M2_4_PORTFOLIO_ACTIVATION_SCHEMA_V1' AND min(methodology_version)='M2_4_METHOD_V1'
                   AND min(acceptance_gate_id)='M2_4_BOOKING_FUNDING_PORTFOLIO_ACTIVATION'
                   AND min(expected_latest_rows)=1500 AND min(observed_latest_rows)=1500
                   AND min(expected_archive_rows)=1500 AND min(observed_archive_rows)=1500
                   AND min(stage_expected_canonical_entities)=6212
                   AND min(expected_positive_controls)=120 AND min(observed_positive_controls)=120
                   AND min(expected_negative_controls)=20 AND min(observed_negative_controls)=20
                   AND min(expected_contract_set_hash)='fba075bfd6b24e07dc669d6ce25010f1' AND min(observed_contract_set_hash)='fba075bfd6b24e07dc669d6ce25010f1'
                   AND min(expected_stage_combined_set_hash)='117450a3eea7bb3d3c74d18cc3c8e96a' AND min(observed_stage_combined_set_hash)='117450a3eea7bb3d3c74d18cc3c8e96a'
                   AND min(expected_registry_row_hash)='879e04636699b51113638ec81d76667b' AND min(observed_registry_row_hash)='879e04636699b51113638ec81d76667b'
                   AND min(expected_latest_set_hash)='f26248c112635ebe5254d614f42332d6' AND min(observed_latest_set_hash)='f26248c112635ebe5254d614f42332d6'
                   AND min(expected_archive_set_hash)='bf72bbed8c76db3ecdc6936e78718e04' AND min(observed_archive_set_hash)='bf72bbed8c76db3ecdc6936e78718e04'
                   AND min(contract_status)='ACCEPTED' AND min(gate_status)='PASS' AND min(acceptance_evidence_status)='PASS' AND min(certification_status)='PASS'
                   AND min(required_source_edge_count)=1 AND min(passed_source_edge_count)=1
                   AND count(*) FILTER (WHERE row_hash IS DISTINCT FROM md5((to_jsonb(c)-'row_hash'-'created_at')::text))=0
              THEN 0 ELSE 1 END)::bigint AS mismatch_count,
        (count(*)=1 AND min(certification_node_sequence)=5
         AND min(stage_code)='M2_4_PORTFOLIO_ACTIVATION' AND min(repository_stage)='23_M2_4'
         AND min(component_contract_code)='M2_PORTFOLIO_ACTIVATION_CONSUMPTION' AND min(contract_version)=1
         AND min(schema_version)='M2_4_PORTFOLIO_ACTIVATION_SCHEMA_V1' AND min(methodology_version)='M2_4_METHOD_V1'
         AND min(acceptance_gate_id)='M2_4_BOOKING_FUNDING_PORTFOLIO_ACTIVATION'
         AND min(expected_latest_rows)=1500 AND min(observed_latest_rows)=1500
         AND min(expected_archive_rows)=1500 AND min(observed_archive_rows)=1500
         AND min(stage_expected_canonical_entities)=6212
         AND min(expected_positive_controls)=120 AND min(observed_positive_controls)=120
         AND min(expected_negative_controls)=20 AND min(observed_negative_controls)=20
         AND min(expected_contract_set_hash)='fba075bfd6b24e07dc669d6ce25010f1' AND min(observed_contract_set_hash)='fba075bfd6b24e07dc669d6ce25010f1'
         AND min(expected_stage_combined_set_hash)='117450a3eea7bb3d3c74d18cc3c8e96a' AND min(observed_stage_combined_set_hash)='117450a3eea7bb3d3c74d18cc3c8e96a'
         AND min(expected_registry_row_hash)='879e04636699b51113638ec81d76667b' AND min(observed_registry_row_hash)='879e04636699b51113638ec81d76667b'
         AND min(expected_latest_set_hash)='f26248c112635ebe5254d614f42332d6' AND min(observed_latest_set_hash)='f26248c112635ebe5254d614f42332d6'
         AND min(expected_archive_set_hash)='bf72bbed8c76db3ecdc6936e78718e04' AND min(observed_archive_set_hash)='bf72bbed8c76db3ecdc6936e78718e04'
         AND min(contract_status)='ACCEPTED' AND min(gate_status)='PASS' AND min(acceptance_evidence_status)='PASS' AND min(certification_status)='PASS'
         AND min(required_source_edge_count)=1 AND min(passed_source_edge_count)=1
         AND count(*) FILTER (WHERE row_hash IS DISTINCT FROM md5((to_jsonb(c)-'row_hash'-'created_at')::text))=0) AS pass_flag,
        'Frozen contract identity and copied accepted-source hashes for component M2_PORTFOLIO_ACTIVATION_CONSUMPTION.'::text AS interpretation
    FROM c
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_046_COMPONENT_06_M2_PORTFOLIO_ACTIVATION_CONSUMPTION_LINEAGE */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    46::smallint,
    'M2_12_POS_046_COMPONENT_06_M2_PORTFOLIO_ACTIVATION_CONSUMPTION_LINEAGE'::text,
    3::smallint,
    'COMPONENT_CONTRACT'::text,
    'Component 06 M2_PORTFOLIO_ACTIVATION_CONSUMPTION physical relation, business-key, edge, and reproduction lineage is exact'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH c AS (
        SELECT t.* FROM msbf_m2.module2_contract_component_snapshot t
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id
        WHERE t.component_sequence=6 AND t.component_contract_code='M2_PORTFOLIO_ACTIVATION_CONSUMPTION' AND t.contract_version=1
    ), r AS (
        SELECT t.* FROM msbf_m2.module2_contract_reproduction_snapshot t
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id
        WHERE t.component_sequence=6 AND t.component_contract_code='M2_PORTFOLIO_ACTIVATION_CONSUMPTION' AND t.contract_version=1
    )
    SELECT
        concat_ws('|',(SELECT count(*) FROM c),(SELECT min(registry_relation) FROM c),(SELECT min(latest_relation) FROM c),(SELECT min(archive_relation) FROM c),
            (SELECT min(latest_business_grain) FROM c),(SELECT min(latest_business_key_columns::text) FROM c),(SELECT min(archive_business_key_columns::text) FROM c),
            (SELECT min(required_source_edge_count)::text FROM c),(SELECT min(passed_source_edge_count)::text FROM c),(SELECT count(*) FROM r),
            (SELECT min(reproduction_status) FROM r),(SELECT min(archive_trigger_status) FROM r)) AS observed_value,
        '1|msbf_ctl.m2_4_portfolio_activation_contract_registry|msbf_m2.application_booking_funding_activation_latest|msbf_m2.application_booking_funding_activation_archive|module1_run_id + scenario_id + merchant_application_id|["module1_run_id","scenario_id","merchant_application_id"]|["module1_run_id","contract_version","scenario_id","merchant_application_id"]|1|1|1|PASS|PASS'::text AS expected_value,
        ((SELECT (count(*)<>1)::integer FROM c)
         +(SELECT count(*) FILTER (WHERE registry_relation<>'msbf_ctl.m2_4_portfolio_activation_contract_registry' OR latest_relation<>'msbf_m2.application_booking_funding_activation_latest' OR archive_relation<>'msbf_m2.application_booking_funding_activation_archive' OR latest_business_grain<>'module1_run_id + scenario_id + merchant_application_id'
                   OR latest_business_key_columns<>'["module1_run_id","scenario_id","merchant_application_id"]'::jsonb OR archive_business_key_columns<>'["module1_run_id","contract_version","scenario_id","merchant_application_id"]'::jsonb
                   OR required_source_edge_codes<>ARRAY['M2_3_TO_M2_4']::text[] OR required_source_edge_count<>1 OR passed_source_edge_count<>1) FROM c)
         +(SELECT (count(*)<>1)::integer FROM r)
         +(SELECT count(*) FILTER (WHERE registry_relation<>'msbf_ctl.m2_4_portfolio_activation_contract_registry' OR latest_relation<>'msbf_m2.application_booking_funding_activation_latest' OR archive_relation<>'msbf_m2.application_booking_funding_activation_archive'
                   OR latest_business_key_columns<>'["module1_run_id","scenario_id","merchant_application_id"]'::jsonb OR archive_business_key_columns<>'["module1_run_id","contract_version","scenario_id","merchant_application_id"]'::jsonb
                   OR expected_latest_rows<>1500 OR observed_latest_rows<>1500
                   OR expected_archive_rows<>1500 OR observed_archive_rows<>1500
                   OR expected_latest_set_hash<>'f26248c112635ebe5254d614f42332d6' OR observed_latest_set_hash<>'f26248c112635ebe5254d614f42332d6'
                   OR expected_archive_set_hash<>'bf72bbed8c76db3ecdc6936e78718e04' OR observed_archive_set_hash<>'bf72bbed8c76db3ecdc6936e78718e04'
                   OR payload_mismatch_count<>0 OR missing_latest_rows<>0 OR missing_archive_rows<>0 OR latest_duplicate_key_rows<>0 OR archive_duplicate_key_rows<>0
                   OR archive_trigger_status<>'PASS' OR reproduction_status<>'PASS' OR source_registry_row_hash<>'879e04636699b51113638ec81d76667b'
                   OR row_hash IS DISTINCT FROM md5((to_jsonb(r)-'row_hash'-'created_at')::text)) FROM r))::bigint AS mismatch_count,
        ((SELECT count(*)=1 FROM c)
         AND (SELECT count(*)=0 FROM c WHERE registry_relation<>'msbf_ctl.m2_4_portfolio_activation_contract_registry' OR latest_relation<>'msbf_m2.application_booking_funding_activation_latest' OR archive_relation<>'msbf_m2.application_booking_funding_activation_archive' OR latest_business_grain<>'module1_run_id + scenario_id + merchant_application_id'
              OR latest_business_key_columns<>'["module1_run_id","scenario_id","merchant_application_id"]'::jsonb OR archive_business_key_columns<>'["module1_run_id","contract_version","scenario_id","merchant_application_id"]'::jsonb
              OR required_source_edge_codes<>ARRAY['M2_3_TO_M2_4']::text[] OR required_source_edge_count<>1 OR passed_source_edge_count<>1)
         AND (SELECT count(*)=1 FROM r)
         AND (SELECT count(*)=0 FROM r WHERE registry_relation<>'msbf_ctl.m2_4_portfolio_activation_contract_registry' OR latest_relation<>'msbf_m2.application_booking_funding_activation_latest' OR archive_relation<>'msbf_m2.application_booking_funding_activation_archive'
              OR latest_business_key_columns<>'["module1_run_id","scenario_id","merchant_application_id"]'::jsonb OR archive_business_key_columns<>'["module1_run_id","contract_version","scenario_id","merchant_application_id"]'::jsonb
              OR expected_latest_rows<>1500 OR observed_latest_rows<>1500
              OR expected_archive_rows<>1500 OR observed_archive_rows<>1500
              OR expected_latest_set_hash<>'f26248c112635ebe5254d614f42332d6' OR observed_latest_set_hash<>'f26248c112635ebe5254d614f42332d6'
              OR expected_archive_set_hash<>'bf72bbed8c76db3ecdc6936e78718e04' OR observed_archive_set_hash<>'bf72bbed8c76db3ecdc6936e78718e04'
              OR payload_mismatch_count<>0 OR missing_latest_rows<>0 OR missing_archive_rows<>0 OR latest_duplicate_key_rows<>0 OR archive_duplicate_key_rows<>0
              OR archive_trigger_status<>'PASS' OR reproduction_status<>'PASS' OR source_registry_row_hash<>'879e04636699b51113638ec81d76667b'
              OR row_hash IS DISTINCT FROM md5((to_jsonb(r)-'row_hash'-'created_at')::text))) AS pass_flag,
        'Physical relation, business-key, source-edge, and reproduction lineage for component M2_PORTFOLIO_ACTIVATION_CONSUMPTION.'::text AS interpretation
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_047_COMPONENT_07_M2_DAILY_REMITTANCE_EXPOSURE_MONITORING_CONSUMPTION_IDENTITY */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    47::smallint,
    'M2_12_POS_047_COMPONENT_07_M2_DAILY_REMITTANCE_EXPOSURE_MONITORING_CONSUMPTION_IDENTITY'::text,
    3::smallint,
    'COMPONENT_CONTRACT'::text,
    'Component 07 M2_DAILY_REMITTANCE_EXPOSURE_MONITORING_CONSUMPTION identity, counts, hashes, and statuses are exact'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH c AS (
        SELECT t.* FROM msbf_m2.module2_contract_component_snapshot t
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id
        WHERE t.component_sequence=7 AND t.component_contract_code='M2_DAILY_REMITTANCE_EXPOSURE_MONITORING_CONSUMPTION' AND t.contract_version=1
    )
    SELECT
        concat_ws('|',count(*)::text,min(component_contract_code),min(contract_version)::text,min(schema_version),min(methodology_version),
            min(expected_latest_rows)::text,min(observed_latest_rows)::text,min(expected_archive_rows)::text,min(observed_archive_rows)::text,
            min(observed_contract_set_hash),min(observed_stage_combined_set_hash),min(observed_registry_row_hash),min(observed_latest_set_hash),min(observed_archive_set_hash),
            min(contract_status),min(gate_status),min(acceptance_evidence_status),min(certification_status),
            count(*) FILTER (WHERE row_hash IS DISTINCT FROM md5((to_jsonb(c)-'row_hash'-'created_at')::text))::text) AS observed_value,
        '1|M2_DAILY_REMITTANCE_EXPOSURE_MONITORING_CONSUMPTION|1|M2_5_DAILY_REMITTANCE_EXPOSURE_SCHEMA_V1|M2_5_METHOD_V1|59|59|59|59|decdc18973edb5f29d2e55ca8a139457|18e1c444aa1b02ee5bd3539d7c477adc|c50efd2f8ec5bf10216e5da889ff403d|ddb680b9f00e88483099d90e781337eb|c8c22762d49bbd58cf89bae187eaac9f|ACCEPTED|PASS|PASS|PASS|0'::text AS expected_value,
        (CASE WHEN count(*)=1 AND min(certification_node_sequence)=6
                   AND min(stage_code)='M2_5_DAILY_MONITORING' AND min(repository_stage)='24_M2_5'
                   AND min(component_contract_code)='M2_DAILY_REMITTANCE_EXPOSURE_MONITORING_CONSUMPTION' AND min(contract_version)=1
                   AND min(schema_version)='M2_5_DAILY_REMITTANCE_EXPOSURE_SCHEMA_V1' AND min(methodology_version)='M2_5_METHOD_V1'
                   AND min(acceptance_gate_id)='M2_5_DAILY_REMITTANCE_EXPOSURE_PORTFOLIO_MONITORING'
                   AND min(expected_latest_rows)=59 AND min(observed_latest_rows)=59
                   AND min(expected_archive_rows)=59 AND min(observed_archive_rows)=59
                   AND min(stage_expected_canonical_entities)=7536
                   AND min(expected_positive_controls)=120 AND min(observed_positive_controls)=120
                   AND min(expected_negative_controls)=20 AND min(observed_negative_controls)=20
                   AND min(expected_contract_set_hash)='decdc18973edb5f29d2e55ca8a139457' AND min(observed_contract_set_hash)='decdc18973edb5f29d2e55ca8a139457'
                   AND min(expected_stage_combined_set_hash)='18e1c444aa1b02ee5bd3539d7c477adc' AND min(observed_stage_combined_set_hash)='18e1c444aa1b02ee5bd3539d7c477adc'
                   AND min(expected_registry_row_hash)='c50efd2f8ec5bf10216e5da889ff403d' AND min(observed_registry_row_hash)='c50efd2f8ec5bf10216e5da889ff403d'
                   AND min(expected_latest_set_hash)='ddb680b9f00e88483099d90e781337eb' AND min(observed_latest_set_hash)='ddb680b9f00e88483099d90e781337eb'
                   AND min(expected_archive_set_hash)='c8c22762d49bbd58cf89bae187eaac9f' AND min(observed_archive_set_hash)='c8c22762d49bbd58cf89bae187eaac9f'
                   AND min(contract_status)='ACCEPTED' AND min(gate_status)='PASS' AND min(acceptance_evidence_status)='PASS' AND min(certification_status)='PASS'
                   AND min(required_source_edge_count)=2 AND min(passed_source_edge_count)=2
                   AND count(*) FILTER (WHERE row_hash IS DISTINCT FROM md5((to_jsonb(c)-'row_hash'-'created_at')::text))=0
              THEN 0 ELSE 1 END)::bigint AS mismatch_count,
        (count(*)=1 AND min(certification_node_sequence)=6
         AND min(stage_code)='M2_5_DAILY_MONITORING' AND min(repository_stage)='24_M2_5'
         AND min(component_contract_code)='M2_DAILY_REMITTANCE_EXPOSURE_MONITORING_CONSUMPTION' AND min(contract_version)=1
         AND min(schema_version)='M2_5_DAILY_REMITTANCE_EXPOSURE_SCHEMA_V1' AND min(methodology_version)='M2_5_METHOD_V1'
         AND min(acceptance_gate_id)='M2_5_DAILY_REMITTANCE_EXPOSURE_PORTFOLIO_MONITORING'
         AND min(expected_latest_rows)=59 AND min(observed_latest_rows)=59
         AND min(expected_archive_rows)=59 AND min(observed_archive_rows)=59
         AND min(stage_expected_canonical_entities)=7536
         AND min(expected_positive_controls)=120 AND min(observed_positive_controls)=120
         AND min(expected_negative_controls)=20 AND min(observed_negative_controls)=20
         AND min(expected_contract_set_hash)='decdc18973edb5f29d2e55ca8a139457' AND min(observed_contract_set_hash)='decdc18973edb5f29d2e55ca8a139457'
         AND min(expected_stage_combined_set_hash)='18e1c444aa1b02ee5bd3539d7c477adc' AND min(observed_stage_combined_set_hash)='18e1c444aa1b02ee5bd3539d7c477adc'
         AND min(expected_registry_row_hash)='c50efd2f8ec5bf10216e5da889ff403d' AND min(observed_registry_row_hash)='c50efd2f8ec5bf10216e5da889ff403d'
         AND min(expected_latest_set_hash)='ddb680b9f00e88483099d90e781337eb' AND min(observed_latest_set_hash)='ddb680b9f00e88483099d90e781337eb'
         AND min(expected_archive_set_hash)='c8c22762d49bbd58cf89bae187eaac9f' AND min(observed_archive_set_hash)='c8c22762d49bbd58cf89bae187eaac9f'
         AND min(contract_status)='ACCEPTED' AND min(gate_status)='PASS' AND min(acceptance_evidence_status)='PASS' AND min(certification_status)='PASS'
         AND min(required_source_edge_count)=2 AND min(passed_source_edge_count)=2
         AND count(*) FILTER (WHERE row_hash IS DISTINCT FROM md5((to_jsonb(c)-'row_hash'-'created_at')::text))=0) AS pass_flag,
        'Frozen contract identity and copied accepted-source hashes for component M2_DAILY_REMITTANCE_EXPOSURE_MONITORING_CONSUMPTION.'::text AS interpretation
    FROM c
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_048_COMPONENT_07_M2_DAILY_REMITTANCE_EXPOSURE_MONITORING_CONSUMPTION_LINEAGE */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    48::smallint,
    'M2_12_POS_048_COMPONENT_07_M2_DAILY_REMITTANCE_EXPOSURE_MONITORING_CONSUMPTION_LINEAGE'::text,
    3::smallint,
    'COMPONENT_CONTRACT'::text,
    'Component 07 M2_DAILY_REMITTANCE_EXPOSURE_MONITORING_CONSUMPTION physical relation, business-key, edge, and reproduction lineage is exact'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH c AS (
        SELECT t.* FROM msbf_m2.module2_contract_component_snapshot t
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id
        WHERE t.component_sequence=7 AND t.component_contract_code='M2_DAILY_REMITTANCE_EXPOSURE_MONITORING_CONSUMPTION' AND t.contract_version=1
    ), r AS (
        SELECT t.* FROM msbf_m2.module2_contract_reproduction_snapshot t
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id
        WHERE t.component_sequence=7 AND t.component_contract_code='M2_DAILY_REMITTANCE_EXPOSURE_MONITORING_CONSUMPTION' AND t.contract_version=1
    )
    SELECT
        concat_ws('|',(SELECT count(*) FROM c),(SELECT min(registry_relation) FROM c),(SELECT min(latest_relation) FROM c),(SELECT min(archive_relation) FROM c),
            (SELECT min(latest_business_grain) FROM c),(SELECT min(latest_business_key_columns::text) FROM c),(SELECT min(archive_business_key_columns::text) FROM c),
            (SELECT min(required_source_edge_count)::text FROM c),(SELECT min(passed_source_edge_count)::text FROM c),(SELECT count(*) FROM r),
            (SELECT min(reproduction_status) FROM r),(SELECT min(archive_trigger_status) FROM r)) AS observed_value,
        '1|msbf_ctl.m2_5_portfolio_monitoring_contract_registry|msbf_m2.advance_portfolio_monitoring_latest|msbf_m2.advance_portfolio_monitoring_archive|module1_run_id + scenario_id + merchant_application_id|["module1_run_id","scenario_id","merchant_application_id"]|["module1_run_id","contract_version","scenario_id","merchant_application_id"]|2|2|1|PASS|PASS'::text AS expected_value,
        ((SELECT (count(*)<>1)::integer FROM c)
         +(SELECT count(*) FILTER (WHERE registry_relation<>'msbf_ctl.m2_5_portfolio_monitoring_contract_registry' OR latest_relation<>'msbf_m2.advance_portfolio_monitoring_latest' OR archive_relation<>'msbf_m2.advance_portfolio_monitoring_archive' OR latest_business_grain<>'module1_run_id + scenario_id + merchant_application_id'
                   OR latest_business_key_columns<>'["module1_run_id","scenario_id","merchant_application_id"]'::jsonb OR archive_business_key_columns<>'["module1_run_id","contract_version","scenario_id","merchant_application_id"]'::jsonb
                   OR required_source_edge_codes<>ARRAY['M2_4_TO_M2_5','M1_6_TO_M2_5_SCENARIO_AUTHORITY']::text[] OR required_source_edge_count<>2 OR passed_source_edge_count<>2) FROM c)
         +(SELECT (count(*)<>1)::integer FROM r)
         +(SELECT count(*) FILTER (WHERE registry_relation<>'msbf_ctl.m2_5_portfolio_monitoring_contract_registry' OR latest_relation<>'msbf_m2.advance_portfolio_monitoring_latest' OR archive_relation<>'msbf_m2.advance_portfolio_monitoring_archive'
                   OR latest_business_key_columns<>'["module1_run_id","scenario_id","merchant_application_id"]'::jsonb OR archive_business_key_columns<>'["module1_run_id","contract_version","scenario_id","merchant_application_id"]'::jsonb
                   OR expected_latest_rows<>59 OR observed_latest_rows<>59
                   OR expected_archive_rows<>59 OR observed_archive_rows<>59
                   OR expected_latest_set_hash<>'ddb680b9f00e88483099d90e781337eb' OR observed_latest_set_hash<>'ddb680b9f00e88483099d90e781337eb'
                   OR expected_archive_set_hash<>'c8c22762d49bbd58cf89bae187eaac9f' OR observed_archive_set_hash<>'c8c22762d49bbd58cf89bae187eaac9f'
                   OR payload_mismatch_count<>0 OR missing_latest_rows<>0 OR missing_archive_rows<>0 OR latest_duplicate_key_rows<>0 OR archive_duplicate_key_rows<>0
                   OR archive_trigger_status<>'PASS' OR reproduction_status<>'PASS' OR source_registry_row_hash<>'c50efd2f8ec5bf10216e5da889ff403d'
                   OR row_hash IS DISTINCT FROM md5((to_jsonb(r)-'row_hash'-'created_at')::text)) FROM r))::bigint AS mismatch_count,
        ((SELECT count(*)=1 FROM c)
         AND (SELECT count(*)=0 FROM c WHERE registry_relation<>'msbf_ctl.m2_5_portfolio_monitoring_contract_registry' OR latest_relation<>'msbf_m2.advance_portfolio_monitoring_latest' OR archive_relation<>'msbf_m2.advance_portfolio_monitoring_archive' OR latest_business_grain<>'module1_run_id + scenario_id + merchant_application_id'
              OR latest_business_key_columns<>'["module1_run_id","scenario_id","merchant_application_id"]'::jsonb OR archive_business_key_columns<>'["module1_run_id","contract_version","scenario_id","merchant_application_id"]'::jsonb
              OR required_source_edge_codes<>ARRAY['M2_4_TO_M2_5','M1_6_TO_M2_5_SCENARIO_AUTHORITY']::text[] OR required_source_edge_count<>2 OR passed_source_edge_count<>2)
         AND (SELECT count(*)=1 FROM r)
         AND (SELECT count(*)=0 FROM r WHERE registry_relation<>'msbf_ctl.m2_5_portfolio_monitoring_contract_registry' OR latest_relation<>'msbf_m2.advance_portfolio_monitoring_latest' OR archive_relation<>'msbf_m2.advance_portfolio_monitoring_archive'
              OR latest_business_key_columns<>'["module1_run_id","scenario_id","merchant_application_id"]'::jsonb OR archive_business_key_columns<>'["module1_run_id","contract_version","scenario_id","merchant_application_id"]'::jsonb
              OR expected_latest_rows<>59 OR observed_latest_rows<>59
              OR expected_archive_rows<>59 OR observed_archive_rows<>59
              OR expected_latest_set_hash<>'ddb680b9f00e88483099d90e781337eb' OR observed_latest_set_hash<>'ddb680b9f00e88483099d90e781337eb'
              OR expected_archive_set_hash<>'c8c22762d49bbd58cf89bae187eaac9f' OR observed_archive_set_hash<>'c8c22762d49bbd58cf89bae187eaac9f'
              OR payload_mismatch_count<>0 OR missing_latest_rows<>0 OR missing_archive_rows<>0 OR latest_duplicate_key_rows<>0 OR archive_duplicate_key_rows<>0
              OR archive_trigger_status<>'PASS' OR reproduction_status<>'PASS' OR source_registry_row_hash<>'c50efd2f8ec5bf10216e5da889ff403d'
              OR row_hash IS DISTINCT FROM md5((to_jsonb(r)-'row_hash'-'created_at')::text))) AS pass_flag,
        'Physical relation, business-key, source-edge, and reproduction lineage for component M2_DAILY_REMITTANCE_EXPOSURE_MONITORING_CONSUMPTION.'::text AS interpretation
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_049_COMPONENT_08_M2_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_CONSUMPTION_IDENTITY */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    49::smallint,
    'M2_12_POS_049_COMPONENT_08_M2_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_CONSUMPTION_IDENTITY'::text,
    3::smallint,
    'COMPONENT_CONTRACT'::text,
    'Component 08 M2_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_CONSUMPTION identity, counts, hashes, and statuses are exact'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH c AS (
        SELECT t.* FROM msbf_m2.module2_contract_component_snapshot t
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id
        WHERE t.component_sequence=8 AND t.component_contract_code='M2_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_CONSUMPTION' AND t.contract_version=1
    )
    SELECT
        concat_ws('|',count(*)::text,min(component_contract_code),min(contract_version)::text,min(schema_version),min(methodology_version),
            min(expected_latest_rows)::text,min(observed_latest_rows)::text,min(expected_archive_rows)::text,min(observed_archive_rows)::text,
            min(observed_contract_set_hash),min(observed_stage_combined_set_hash),min(observed_registry_row_hash),min(observed_latest_set_hash),min(observed_archive_set_hash),
            min(contract_status),min(gate_status),min(acceptance_evidence_status),min(certification_status),
            count(*) FILTER (WHERE row_hash IS DISTINCT FROM md5((to_jsonb(c)-'row_hash'-'created_at')::text))::text) AS observed_value,
        '1|M2_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_CONSUMPTION|1|M2_6_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_SCHEMA_V1|M2_6_METHOD_V1|59|59|59|59|5e5c05dbe9d334cd64d4c6c178a7bacf|868125bff29270490cab4d2e55cb1388|4f145d5248bbc6ed5c45b172afa4d342|f3c42642b2a22b68ff2130d7b065afcd|72f26807f4d65fa6f813502df9dde3f0|ACCEPTED|PASS|PASS|PASS|0'::text AS expected_value,
        (CASE WHEN count(*)=1 AND min(certification_node_sequence)=7
                   AND min(stage_code)='M2_6_INTERVENTION_STRATEGY' AND min(repository_stage)='25_M2_6'
                   AND min(component_contract_code)='M2_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_CONSUMPTION' AND min(contract_version)=1
                   AND min(schema_version)='M2_6_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_SCHEMA_V1' AND min(methodology_version)='M2_6_METHOD_V1'
                   AND min(acceptance_gate_id)='M2_6_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY'
                   AND min(expected_latest_rows)=59 AND min(observed_latest_rows)=59
                   AND min(expected_archive_rows)=59 AND min(observed_archive_rows)=59
                   AND min(stage_expected_canonical_entities)=284
                   AND min(expected_positive_controls)=120 AND min(observed_positive_controls)=120
                   AND min(expected_negative_controls)=20 AND min(observed_negative_controls)=20
                   AND min(expected_contract_set_hash)='5e5c05dbe9d334cd64d4c6c178a7bacf' AND min(observed_contract_set_hash)='5e5c05dbe9d334cd64d4c6c178a7bacf'
                   AND min(expected_stage_combined_set_hash)='868125bff29270490cab4d2e55cb1388' AND min(observed_stage_combined_set_hash)='868125bff29270490cab4d2e55cb1388'
                   AND min(expected_registry_row_hash)='4f145d5248bbc6ed5c45b172afa4d342' AND min(observed_registry_row_hash)='4f145d5248bbc6ed5c45b172afa4d342'
                   AND min(expected_latest_set_hash)='f3c42642b2a22b68ff2130d7b065afcd' AND min(observed_latest_set_hash)='f3c42642b2a22b68ff2130d7b065afcd'
                   AND min(expected_archive_set_hash)='72f26807f4d65fa6f813502df9dde3f0' AND min(observed_archive_set_hash)='72f26807f4d65fa6f813502df9dde3f0'
                   AND min(contract_status)='ACCEPTED' AND min(gate_status)='PASS' AND min(acceptance_evidence_status)='PASS' AND min(certification_status)='PASS'
                   AND min(required_source_edge_count)=1 AND min(passed_source_edge_count)=1
                   AND count(*) FILTER (WHERE row_hash IS DISTINCT FROM md5((to_jsonb(c)-'row_hash'-'created_at')::text))=0
              THEN 0 ELSE 1 END)::bigint AS mismatch_count,
        (count(*)=1 AND min(certification_node_sequence)=7
         AND min(stage_code)='M2_6_INTERVENTION_STRATEGY' AND min(repository_stage)='25_M2_6'
         AND min(component_contract_code)='M2_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_CONSUMPTION' AND min(contract_version)=1
         AND min(schema_version)='M2_6_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_SCHEMA_V1' AND min(methodology_version)='M2_6_METHOD_V1'
         AND min(acceptance_gate_id)='M2_6_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY'
         AND min(expected_latest_rows)=59 AND min(observed_latest_rows)=59
         AND min(expected_archive_rows)=59 AND min(observed_archive_rows)=59
         AND min(stage_expected_canonical_entities)=284
         AND min(expected_positive_controls)=120 AND min(observed_positive_controls)=120
         AND min(expected_negative_controls)=20 AND min(observed_negative_controls)=20
         AND min(expected_contract_set_hash)='5e5c05dbe9d334cd64d4c6c178a7bacf' AND min(observed_contract_set_hash)='5e5c05dbe9d334cd64d4c6c178a7bacf'
         AND min(expected_stage_combined_set_hash)='868125bff29270490cab4d2e55cb1388' AND min(observed_stage_combined_set_hash)='868125bff29270490cab4d2e55cb1388'
         AND min(expected_registry_row_hash)='4f145d5248bbc6ed5c45b172afa4d342' AND min(observed_registry_row_hash)='4f145d5248bbc6ed5c45b172afa4d342'
         AND min(expected_latest_set_hash)='f3c42642b2a22b68ff2130d7b065afcd' AND min(observed_latest_set_hash)='f3c42642b2a22b68ff2130d7b065afcd'
         AND min(expected_archive_set_hash)='72f26807f4d65fa6f813502df9dde3f0' AND min(observed_archive_set_hash)='72f26807f4d65fa6f813502df9dde3f0'
         AND min(contract_status)='ACCEPTED' AND min(gate_status)='PASS' AND min(acceptance_evidence_status)='PASS' AND min(certification_status)='PASS'
         AND min(required_source_edge_count)=1 AND min(passed_source_edge_count)=1
         AND count(*) FILTER (WHERE row_hash IS DISTINCT FROM md5((to_jsonb(c)-'row_hash'-'created_at')::text))=0) AS pass_flag,
        'Frozen contract identity and copied accepted-source hashes for component M2_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_CONSUMPTION.'::text AS interpretation
    FROM c
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_050_COMPONENT_08_M2_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_CONSUMPTION_LINEAGE */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    50::smallint,
    'M2_12_POS_050_COMPONENT_08_M2_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_CONSUMPTION_LINEAGE'::text,
    3::smallint,
    'COMPONENT_CONTRACT'::text,
    'Component 08 M2_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_CONSUMPTION physical relation, business-key, edge, and reproduction lineage is exact'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH c AS (
        SELECT t.* FROM msbf_m2.module2_contract_component_snapshot t
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id
        WHERE t.component_sequence=8 AND t.component_contract_code='M2_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_CONSUMPTION' AND t.contract_version=1
    ), r AS (
        SELECT t.* FROM msbf_m2.module2_contract_reproduction_snapshot t
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id
        WHERE t.component_sequence=8 AND t.component_contract_code='M2_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_CONSUMPTION' AND t.contract_version=1
    )
    SELECT
        concat_ws('|',(SELECT count(*) FROM c),(SELECT min(registry_relation) FROM c),(SELECT min(latest_relation) FROM c),(SELECT min(archive_relation) FROM c),
            (SELECT min(latest_business_grain) FROM c),(SELECT min(latest_business_key_columns::text) FROM c),(SELECT min(archive_business_key_columns::text) FROM c),
            (SELECT min(required_source_edge_count)::text FROM c),(SELECT min(passed_source_edge_count)::text FROM c),(SELECT count(*) FROM r),
            (SELECT min(reproduction_status) FROM r),(SELECT min(archive_trigger_status) FROM r)) AS observed_value,
        '1|msbf_ctl.m2_6_intervention_strategy_contract_registry|msbf_m2.advance_intervention_strategy_latest|msbf_m2.advance_intervention_strategy_archive|module1_run_id + scenario_id + merchant_application_id|["module1_run_id","scenario_id","merchant_application_id"]|["module1_run_id","contract_version","scenario_id","merchant_application_id"]|1|1|1|PASS|PASS'::text AS expected_value,
        ((SELECT (count(*)<>1)::integer FROM c)
         +(SELECT count(*) FILTER (WHERE registry_relation<>'msbf_ctl.m2_6_intervention_strategy_contract_registry' OR latest_relation<>'msbf_m2.advance_intervention_strategy_latest' OR archive_relation<>'msbf_m2.advance_intervention_strategy_archive' OR latest_business_grain<>'module1_run_id + scenario_id + merchant_application_id'
                   OR latest_business_key_columns<>'["module1_run_id","scenario_id","merchant_application_id"]'::jsonb OR archive_business_key_columns<>'["module1_run_id","contract_version","scenario_id","merchant_application_id"]'::jsonb
                   OR required_source_edge_codes<>ARRAY['M2_5_TO_M2_6']::text[] OR required_source_edge_count<>1 OR passed_source_edge_count<>1) FROM c)
         +(SELECT (count(*)<>1)::integer FROM r)
         +(SELECT count(*) FILTER (WHERE registry_relation<>'msbf_ctl.m2_6_intervention_strategy_contract_registry' OR latest_relation<>'msbf_m2.advance_intervention_strategy_latest' OR archive_relation<>'msbf_m2.advance_intervention_strategy_archive'
                   OR latest_business_key_columns<>'["module1_run_id","scenario_id","merchant_application_id"]'::jsonb OR archive_business_key_columns<>'["module1_run_id","contract_version","scenario_id","merchant_application_id"]'::jsonb
                   OR expected_latest_rows<>59 OR observed_latest_rows<>59
                   OR expected_archive_rows<>59 OR observed_archive_rows<>59
                   OR expected_latest_set_hash<>'f3c42642b2a22b68ff2130d7b065afcd' OR observed_latest_set_hash<>'f3c42642b2a22b68ff2130d7b065afcd'
                   OR expected_archive_set_hash<>'72f26807f4d65fa6f813502df9dde3f0' OR observed_archive_set_hash<>'72f26807f4d65fa6f813502df9dde3f0'
                   OR payload_mismatch_count<>0 OR missing_latest_rows<>0 OR missing_archive_rows<>0 OR latest_duplicate_key_rows<>0 OR archive_duplicate_key_rows<>0
                   OR archive_trigger_status<>'PASS' OR reproduction_status<>'PASS' OR source_registry_row_hash<>'4f145d5248bbc6ed5c45b172afa4d342'
                   OR row_hash IS DISTINCT FROM md5((to_jsonb(r)-'row_hash'-'created_at')::text)) FROM r))::bigint AS mismatch_count,
        ((SELECT count(*)=1 FROM c)
         AND (SELECT count(*)=0 FROM c WHERE registry_relation<>'msbf_ctl.m2_6_intervention_strategy_contract_registry' OR latest_relation<>'msbf_m2.advance_intervention_strategy_latest' OR archive_relation<>'msbf_m2.advance_intervention_strategy_archive' OR latest_business_grain<>'module1_run_id + scenario_id + merchant_application_id'
              OR latest_business_key_columns<>'["module1_run_id","scenario_id","merchant_application_id"]'::jsonb OR archive_business_key_columns<>'["module1_run_id","contract_version","scenario_id","merchant_application_id"]'::jsonb
              OR required_source_edge_codes<>ARRAY['M2_5_TO_M2_6']::text[] OR required_source_edge_count<>1 OR passed_source_edge_count<>1)
         AND (SELECT count(*)=1 FROM r)
         AND (SELECT count(*)=0 FROM r WHERE registry_relation<>'msbf_ctl.m2_6_intervention_strategy_contract_registry' OR latest_relation<>'msbf_m2.advance_intervention_strategy_latest' OR archive_relation<>'msbf_m2.advance_intervention_strategy_archive'
              OR latest_business_key_columns<>'["module1_run_id","scenario_id","merchant_application_id"]'::jsonb OR archive_business_key_columns<>'["module1_run_id","contract_version","scenario_id","merchant_application_id"]'::jsonb
              OR expected_latest_rows<>59 OR observed_latest_rows<>59
              OR expected_archive_rows<>59 OR observed_archive_rows<>59
              OR expected_latest_set_hash<>'f3c42642b2a22b68ff2130d7b065afcd' OR observed_latest_set_hash<>'f3c42642b2a22b68ff2130d7b065afcd'
              OR expected_archive_set_hash<>'72f26807f4d65fa6f813502df9dde3f0' OR observed_archive_set_hash<>'72f26807f4d65fa6f813502df9dde3f0'
              OR payload_mismatch_count<>0 OR missing_latest_rows<>0 OR missing_archive_rows<>0 OR latest_duplicate_key_rows<>0 OR archive_duplicate_key_rows<>0
              OR archive_trigger_status<>'PASS' OR reproduction_status<>'PASS' OR source_registry_row_hash<>'4f145d5248bbc6ed5c45b172afa4d342'
              OR row_hash IS DISTINCT FROM md5((to_jsonb(r)-'row_hash'-'created_at')::text))) AS pass_flag,
        'Physical relation, business-key, source-edge, and reproduction lineage for component M2_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_CONSUMPTION.'::text AS interpretation
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_051_COMPONENT_09_M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION_IDENTITY */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    51::smallint,
    'M2_12_POS_051_COMPONENT_09_M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION_IDENTITY'::text,
    3::smallint,
    'COMPONENT_CONTRACT'::text,
    'Component 09 M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION identity, counts, hashes, and statuses are exact'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH c AS (
        SELECT t.* FROM msbf_m2.module2_contract_component_snapshot t
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id
        WHERE t.component_sequence=9 AND t.component_contract_code='M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION' AND t.contract_version=1
    )
    SELECT
        concat_ws('|',count(*)::text,min(component_contract_code),min(contract_version)::text,min(schema_version),min(methodology_version),
            min(expected_latest_rows)::text,min(observed_latest_rows)::text,min(expected_archive_rows)::text,min(observed_archive_rows)::text,
            min(observed_contract_set_hash),min(observed_stage_combined_set_hash),min(observed_registry_row_hash),min(observed_latest_set_hash),min(observed_archive_set_hash),
            min(contract_status),min(gate_status),min(acceptance_evidence_status),min(certification_status),
            count(*) FILTER (WHERE row_hash IS DISTINCT FROM md5((to_jsonb(c)-'row_hash'-'created_at')::text))::text) AS observed_value,
        '1|M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION|1|M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_SCHEMA_V1|M2_7_METHOD_V1|59|59|59|59|c74d986057de7b01d95d0b92bc820d8c|c8e3a472afd2a16b1183677324e9db98|8b210c34bdb12f8fb71638b48b374c14|e1fa837647489de56d66222447420549|9980f9ff49ca53790ec9af8c6988d44a|ACCEPTED|PASS|PASS|PASS|0'::text AS expected_value,
        (CASE WHEN count(*)=1 AND min(certification_node_sequence)=8
                   AND min(stage_code)='M2_7_OPERATIONAL_ACTIVATION' AND min(repository_stage)='26_M2_7'
                   AND min(component_contract_code)='M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION' AND min(contract_version)=1
                   AND min(schema_version)='M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_SCHEMA_V1' AND min(methodology_version)='M2_7_METHOD_V1'
                   AND min(acceptance_gate_id)='M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP'
                   AND min(expected_latest_rows)=59 AND min(observed_latest_rows)=59
                   AND min(expected_archive_rows)=59 AND min(observed_archive_rows)=59
                   AND min(stage_expected_canonical_entities)=341
                   AND min(expected_positive_controls)=120 AND min(observed_positive_controls)=120
                   AND min(expected_negative_controls)=20 AND min(observed_negative_controls)=20
                   AND min(expected_contract_set_hash)='c74d986057de7b01d95d0b92bc820d8c' AND min(observed_contract_set_hash)='c74d986057de7b01d95d0b92bc820d8c'
                   AND min(expected_stage_combined_set_hash)='c8e3a472afd2a16b1183677324e9db98' AND min(observed_stage_combined_set_hash)='c8e3a472afd2a16b1183677324e9db98'
                   AND min(expected_registry_row_hash)='8b210c34bdb12f8fb71638b48b374c14' AND min(observed_registry_row_hash)='8b210c34bdb12f8fb71638b48b374c14'
                   AND min(expected_latest_set_hash)='e1fa837647489de56d66222447420549' AND min(observed_latest_set_hash)='e1fa837647489de56d66222447420549'
                   AND min(expected_archive_set_hash)='9980f9ff49ca53790ec9af8c6988d44a' AND min(observed_archive_set_hash)='9980f9ff49ca53790ec9af8c6988d44a'
                   AND min(contract_status)='ACCEPTED' AND min(gate_status)='PASS' AND min(acceptance_evidence_status)='PASS' AND min(certification_status)='PASS'
                   AND min(required_source_edge_count)=1 AND min(passed_source_edge_count)=1
                   AND count(*) FILTER (WHERE row_hash IS DISTINCT FROM md5((to_jsonb(c)-'row_hash'-'created_at')::text))=0
              THEN 0 ELSE 1 END)::bigint AS mismatch_count,
        (count(*)=1 AND min(certification_node_sequence)=8
         AND min(stage_code)='M2_7_OPERATIONAL_ACTIVATION' AND min(repository_stage)='26_M2_7'
         AND min(component_contract_code)='M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION' AND min(contract_version)=1
         AND min(schema_version)='M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_SCHEMA_V1' AND min(methodology_version)='M2_7_METHOD_V1'
         AND min(acceptance_gate_id)='M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP'
         AND min(expected_latest_rows)=59 AND min(observed_latest_rows)=59
         AND min(expected_archive_rows)=59 AND min(observed_archive_rows)=59
         AND min(stage_expected_canonical_entities)=341
         AND min(expected_positive_controls)=120 AND min(observed_positive_controls)=120
         AND min(expected_negative_controls)=20 AND min(observed_negative_controls)=20
         AND min(expected_contract_set_hash)='c74d986057de7b01d95d0b92bc820d8c' AND min(observed_contract_set_hash)='c74d986057de7b01d95d0b92bc820d8c'
         AND min(expected_stage_combined_set_hash)='c8e3a472afd2a16b1183677324e9db98' AND min(observed_stage_combined_set_hash)='c8e3a472afd2a16b1183677324e9db98'
         AND min(expected_registry_row_hash)='8b210c34bdb12f8fb71638b48b374c14' AND min(observed_registry_row_hash)='8b210c34bdb12f8fb71638b48b374c14'
         AND min(expected_latest_set_hash)='e1fa837647489de56d66222447420549' AND min(observed_latest_set_hash)='e1fa837647489de56d66222447420549'
         AND min(expected_archive_set_hash)='9980f9ff49ca53790ec9af8c6988d44a' AND min(observed_archive_set_hash)='9980f9ff49ca53790ec9af8c6988d44a'
         AND min(contract_status)='ACCEPTED' AND min(gate_status)='PASS' AND min(acceptance_evidence_status)='PASS' AND min(certification_status)='PASS'
         AND min(required_source_edge_count)=1 AND min(passed_source_edge_count)=1
         AND count(*) FILTER (WHERE row_hash IS DISTINCT FROM md5((to_jsonb(c)-'row_hash'-'created_at')::text))=0) AS pass_flag,
        'Frozen contract identity and copied accepted-source hashes for component M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION.'::text AS interpretation
    FROM c
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_052_COMPONENT_09_M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION_LINEAGE */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    52::smallint,
    'M2_12_POS_052_COMPONENT_09_M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION_LINEAGE'::text,
    3::smallint,
    'COMPONENT_CONTRACT'::text,
    'Component 09 M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION physical relation, business-key, edge, and reproduction lineage is exact'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH c AS (
        SELECT t.* FROM msbf_m2.module2_contract_component_snapshot t
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id
        WHERE t.component_sequence=9 AND t.component_contract_code='M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION' AND t.contract_version=1
    ), r AS (
        SELECT t.* FROM msbf_m2.module2_contract_reproduction_snapshot t
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id
        WHERE t.component_sequence=9 AND t.component_contract_code='M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION' AND t.contract_version=1
    )
    SELECT
        concat_ws('|',(SELECT count(*) FROM c),(SELECT min(registry_relation) FROM c),(SELECT min(latest_relation) FROM c),(SELECT min(archive_relation) FROM c),
            (SELECT min(latest_business_grain) FROM c),(SELECT min(latest_business_key_columns::text) FROM c),(SELECT min(archive_business_key_columns::text) FROM c),
            (SELECT min(required_source_edge_count)::text FROM c),(SELECT min(passed_source_edge_count)::text FROM c),(SELECT count(*) FROM r),
            (SELECT min(reproduction_status) FROM r),(SELECT min(archive_trigger_status) FROM r)) AS observed_value,
        '1|msbf_ctl.m2_7_operational_activation_contract_registry|msbf_m2.application_operational_activation_latest|msbf_m2.application_operational_activation_archive|module1_run_id + scenario_id + merchant_application_id|["module1_run_id","scenario_id","merchant_application_id"]|["module1_run_id","contract_version","scenario_id","merchant_application_id"]|1|1|1|PASS|PASS'::text AS expected_value,
        ((SELECT (count(*)<>1)::integer FROM c)
         +(SELECT count(*) FILTER (WHERE registry_relation<>'msbf_ctl.m2_7_operational_activation_contract_registry' OR latest_relation<>'msbf_m2.application_operational_activation_latest' OR archive_relation<>'msbf_m2.application_operational_activation_archive' OR latest_business_grain<>'module1_run_id + scenario_id + merchant_application_id'
                   OR latest_business_key_columns<>'["module1_run_id","scenario_id","merchant_application_id"]'::jsonb OR archive_business_key_columns<>'["module1_run_id","contract_version","scenario_id","merchant_application_id"]'::jsonb
                   OR required_source_edge_codes<>ARRAY['M2_6_TO_M2_7']::text[] OR required_source_edge_count<>1 OR passed_source_edge_count<>1) FROM c)
         +(SELECT (count(*)<>1)::integer FROM r)
         +(SELECT count(*) FILTER (WHERE registry_relation<>'msbf_ctl.m2_7_operational_activation_contract_registry' OR latest_relation<>'msbf_m2.application_operational_activation_latest' OR archive_relation<>'msbf_m2.application_operational_activation_archive'
                   OR latest_business_key_columns<>'["module1_run_id","scenario_id","merchant_application_id"]'::jsonb OR archive_business_key_columns<>'["module1_run_id","contract_version","scenario_id","merchant_application_id"]'::jsonb
                   OR expected_latest_rows<>59 OR observed_latest_rows<>59
                   OR expected_archive_rows<>59 OR observed_archive_rows<>59
                   OR expected_latest_set_hash<>'e1fa837647489de56d66222447420549' OR observed_latest_set_hash<>'e1fa837647489de56d66222447420549'
                   OR expected_archive_set_hash<>'9980f9ff49ca53790ec9af8c6988d44a' OR observed_archive_set_hash<>'9980f9ff49ca53790ec9af8c6988d44a'
                   OR payload_mismatch_count<>0 OR missing_latest_rows<>0 OR missing_archive_rows<>0 OR latest_duplicate_key_rows<>0 OR archive_duplicate_key_rows<>0
                   OR archive_trigger_status<>'PASS' OR reproduction_status<>'PASS' OR source_registry_row_hash<>'8b210c34bdb12f8fb71638b48b374c14'
                   OR row_hash IS DISTINCT FROM md5((to_jsonb(r)-'row_hash'-'created_at')::text)) FROM r))::bigint AS mismatch_count,
        ((SELECT count(*)=1 FROM c)
         AND (SELECT count(*)=0 FROM c WHERE registry_relation<>'msbf_ctl.m2_7_operational_activation_contract_registry' OR latest_relation<>'msbf_m2.application_operational_activation_latest' OR archive_relation<>'msbf_m2.application_operational_activation_archive' OR latest_business_grain<>'module1_run_id + scenario_id + merchant_application_id'
              OR latest_business_key_columns<>'["module1_run_id","scenario_id","merchant_application_id"]'::jsonb OR archive_business_key_columns<>'["module1_run_id","contract_version","scenario_id","merchant_application_id"]'::jsonb
              OR required_source_edge_codes<>ARRAY['M2_6_TO_M2_7']::text[] OR required_source_edge_count<>1 OR passed_source_edge_count<>1)
         AND (SELECT count(*)=1 FROM r)
         AND (SELECT count(*)=0 FROM r WHERE registry_relation<>'msbf_ctl.m2_7_operational_activation_contract_registry' OR latest_relation<>'msbf_m2.application_operational_activation_latest' OR archive_relation<>'msbf_m2.application_operational_activation_archive'
              OR latest_business_key_columns<>'["module1_run_id","scenario_id","merchant_application_id"]'::jsonb OR archive_business_key_columns<>'["module1_run_id","contract_version","scenario_id","merchant_application_id"]'::jsonb
              OR expected_latest_rows<>59 OR observed_latest_rows<>59
              OR expected_archive_rows<>59 OR observed_archive_rows<>59
              OR expected_latest_set_hash<>'e1fa837647489de56d66222447420549' OR observed_latest_set_hash<>'e1fa837647489de56d66222447420549'
              OR expected_archive_set_hash<>'9980f9ff49ca53790ec9af8c6988d44a' OR observed_archive_set_hash<>'9980f9ff49ca53790ec9af8c6988d44a'
              OR payload_mismatch_count<>0 OR missing_latest_rows<>0 OR missing_archive_rows<>0 OR latest_duplicate_key_rows<>0 OR archive_duplicate_key_rows<>0
              OR archive_trigger_status<>'PASS' OR reproduction_status<>'PASS' OR source_registry_row_hash<>'8b210c34bdb12f8fb71638b48b374c14'
              OR row_hash IS DISTINCT FROM md5((to_jsonb(r)-'row_hash'-'created_at')::text))) AS pass_flag,
        'Physical relation, business-key, source-edge, and reproduction lineage for component M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION.'::text AS interpretation
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_053_COMPONENT_10_M2_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONSUMPTION_IDENTITY */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    53::smallint,
    'M2_12_POS_053_COMPONENT_10_M2_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONSUMPTION_IDENTITY'::text,
    3::smallint,
    'COMPONENT_CONTRACT'::text,
    'Component 10 M2_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONSUMPTION identity, counts, hashes, and statuses are exact'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH c AS (
        SELECT t.* FROM msbf_m2.module2_contract_component_snapshot t
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id
        WHERE t.component_sequence=10 AND t.component_contract_code='M2_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONSUMPTION' AND t.contract_version=1
    )
    SELECT
        concat_ws('|',count(*)::text,min(component_contract_code),min(contract_version)::text,min(schema_version),min(methodology_version),
            min(expected_latest_rows)::text,min(observed_latest_rows)::text,min(expected_archive_rows)::text,min(observed_archive_rows)::text,
            min(observed_contract_set_hash),min(observed_stage_combined_set_hash),min(observed_registry_row_hash),min(observed_latest_set_hash),min(observed_archive_set_hash),
            min(contract_status),min(gate_status),min(acceptance_evidence_status),min(certification_status),
            count(*) FILTER (WHERE row_hash IS DISTINCT FROM md5((to_jsonb(c)-'row_hash'-'created_at')::text))::text) AS observed_value,
        '1|M2_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONSUMPTION|1|M2_8_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_SCHEMA_V1|M2_8_METHOD_V1|59|59|59|59|37bd013240b1cd6a5db49a271c0c8cec|ab32d80ba20c2c8f0a6ec9ec97c2ed26|03b6c0ca3af4ab9d196e09cefa59be3d|9716224077ff6b7468c0b7b2fed6ab73|ea3a63d0bd9069cb5c061d09750d8d32|ACCEPTED|PASS|PASS|PASS|0'::text AS expected_value,
        (CASE WHEN count(*)=1 AND min(certification_node_sequence)=9
                   AND min(stage_code)='M2_8_SERVICING_EXECUTION' AND min(repository_stage)='27_M2_8'
                   AND min(component_contract_code)='M2_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONSUMPTION' AND min(contract_version)=1
                   AND min(schema_version)='M2_8_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_SCHEMA_V1' AND min(methodology_version)='M2_8_METHOD_V1'
                   AND min(acceptance_gate_id)='M2_8_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONTROL'
                   AND min(expected_latest_rows)=59 AND min(observed_latest_rows)=59
                   AND min(expected_archive_rows)=59 AND min(observed_archive_rows)=59
                   AND min(stage_expected_canonical_entities)=367
                   AND min(expected_positive_controls)=120 AND min(observed_positive_controls)=120
                   AND min(expected_negative_controls)=20 AND min(observed_negative_controls)=20
                   AND min(expected_contract_set_hash)='37bd013240b1cd6a5db49a271c0c8cec' AND min(observed_contract_set_hash)='37bd013240b1cd6a5db49a271c0c8cec'
                   AND min(expected_stage_combined_set_hash)='ab32d80ba20c2c8f0a6ec9ec97c2ed26' AND min(observed_stage_combined_set_hash)='ab32d80ba20c2c8f0a6ec9ec97c2ed26'
                   AND min(expected_registry_row_hash)='03b6c0ca3af4ab9d196e09cefa59be3d' AND min(observed_registry_row_hash)='03b6c0ca3af4ab9d196e09cefa59be3d'
                   AND min(expected_latest_set_hash)='9716224077ff6b7468c0b7b2fed6ab73' AND min(observed_latest_set_hash)='9716224077ff6b7468c0b7b2fed6ab73'
                   AND min(expected_archive_set_hash)='ea3a63d0bd9069cb5c061d09750d8d32' AND min(observed_archive_set_hash)='ea3a63d0bd9069cb5c061d09750d8d32'
                   AND min(contract_status)='ACCEPTED' AND min(gate_status)='PASS' AND min(acceptance_evidence_status)='PASS' AND min(certification_status)='PASS'
                   AND min(required_source_edge_count)=1 AND min(passed_source_edge_count)=1
                   AND count(*) FILTER (WHERE row_hash IS DISTINCT FROM md5((to_jsonb(c)-'row_hash'-'created_at')::text))=0
              THEN 0 ELSE 1 END)::bigint AS mismatch_count,
        (count(*)=1 AND min(certification_node_sequence)=9
         AND min(stage_code)='M2_8_SERVICING_EXECUTION' AND min(repository_stage)='27_M2_8'
         AND min(component_contract_code)='M2_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONSUMPTION' AND min(contract_version)=1
         AND min(schema_version)='M2_8_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_SCHEMA_V1' AND min(methodology_version)='M2_8_METHOD_V1'
         AND min(acceptance_gate_id)='M2_8_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONTROL'
         AND min(expected_latest_rows)=59 AND min(observed_latest_rows)=59
         AND min(expected_archive_rows)=59 AND min(observed_archive_rows)=59
         AND min(stage_expected_canonical_entities)=367
         AND min(expected_positive_controls)=120 AND min(observed_positive_controls)=120
         AND min(expected_negative_controls)=20 AND min(observed_negative_controls)=20
         AND min(expected_contract_set_hash)='37bd013240b1cd6a5db49a271c0c8cec' AND min(observed_contract_set_hash)='37bd013240b1cd6a5db49a271c0c8cec'
         AND min(expected_stage_combined_set_hash)='ab32d80ba20c2c8f0a6ec9ec97c2ed26' AND min(observed_stage_combined_set_hash)='ab32d80ba20c2c8f0a6ec9ec97c2ed26'
         AND min(expected_registry_row_hash)='03b6c0ca3af4ab9d196e09cefa59be3d' AND min(observed_registry_row_hash)='03b6c0ca3af4ab9d196e09cefa59be3d'
         AND min(expected_latest_set_hash)='9716224077ff6b7468c0b7b2fed6ab73' AND min(observed_latest_set_hash)='9716224077ff6b7468c0b7b2fed6ab73'
         AND min(expected_archive_set_hash)='ea3a63d0bd9069cb5c061d09750d8d32' AND min(observed_archive_set_hash)='ea3a63d0bd9069cb5c061d09750d8d32'
         AND min(contract_status)='ACCEPTED' AND min(gate_status)='PASS' AND min(acceptance_evidence_status)='PASS' AND min(certification_status)='PASS'
         AND min(required_source_edge_count)=1 AND min(passed_source_edge_count)=1
         AND count(*) FILTER (WHERE row_hash IS DISTINCT FROM md5((to_jsonb(c)-'row_hash'-'created_at')::text))=0) AS pass_flag,
        'Frozen contract identity and copied accepted-source hashes for component M2_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONSUMPTION.'::text AS interpretation
    FROM c
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_054_COMPONENT_10_M2_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONSUMPTION_LINEAGE */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    54::smallint,
    'M2_12_POS_054_COMPONENT_10_M2_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONSUMPTION_LINEAGE'::text,
    3::smallint,
    'COMPONENT_CONTRACT'::text,
    'Component 10 M2_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONSUMPTION physical relation, business-key, edge, and reproduction lineage is exact'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH c AS (
        SELECT t.* FROM msbf_m2.module2_contract_component_snapshot t
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id
        WHERE t.component_sequence=10 AND t.component_contract_code='M2_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONSUMPTION' AND t.contract_version=1
    ), r AS (
        SELECT t.* FROM msbf_m2.module2_contract_reproduction_snapshot t
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id
        WHERE t.component_sequence=10 AND t.component_contract_code='M2_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONSUMPTION' AND t.contract_version=1
    )
    SELECT
        concat_ws('|',(SELECT count(*) FROM c),(SELECT min(registry_relation) FROM c),(SELECT min(latest_relation) FROM c),(SELECT min(archive_relation) FROM c),
            (SELECT min(latest_business_grain) FROM c),(SELECT min(latest_business_key_columns::text) FROM c),(SELECT min(archive_business_key_columns::text) FROM c),
            (SELECT min(required_source_edge_count)::text FROM c),(SELECT min(passed_source_edge_count)::text FROM c),(SELECT count(*) FROM r),
            (SELECT min(reproduction_status) FROM r),(SELECT min(archive_trigger_status) FROM r)) AS observed_value,
        '1|msbf_ctl.m2_8_servicing_execution_contract_registry|msbf_m2.application_servicing_execution_latest|msbf_m2.application_servicing_execution_archive|module1_run_id + scenario_id + merchant_application_id|["module1_run_id","scenario_id","merchant_application_id"]|["module1_run_id","contract_version","scenario_id","merchant_application_id"]|1|1|1|PASS|PASS'::text AS expected_value,
        ((SELECT (count(*)<>1)::integer FROM c)
         +(SELECT count(*) FILTER (WHERE registry_relation<>'msbf_ctl.m2_8_servicing_execution_contract_registry' OR latest_relation<>'msbf_m2.application_servicing_execution_latest' OR archive_relation<>'msbf_m2.application_servicing_execution_archive' OR latest_business_grain<>'module1_run_id + scenario_id + merchant_application_id'
                   OR latest_business_key_columns<>'["module1_run_id","scenario_id","merchant_application_id"]'::jsonb OR archive_business_key_columns<>'["module1_run_id","contract_version","scenario_id","merchant_application_id"]'::jsonb
                   OR required_source_edge_codes<>ARRAY['M2_7_TO_M2_8']::text[] OR required_source_edge_count<>1 OR passed_source_edge_count<>1) FROM c)
         +(SELECT (count(*)<>1)::integer FROM r)
         +(SELECT count(*) FILTER (WHERE registry_relation<>'msbf_ctl.m2_8_servicing_execution_contract_registry' OR latest_relation<>'msbf_m2.application_servicing_execution_latest' OR archive_relation<>'msbf_m2.application_servicing_execution_archive'
                   OR latest_business_key_columns<>'["module1_run_id","scenario_id","merchant_application_id"]'::jsonb OR archive_business_key_columns<>'["module1_run_id","contract_version","scenario_id","merchant_application_id"]'::jsonb
                   OR expected_latest_rows<>59 OR observed_latest_rows<>59
                   OR expected_archive_rows<>59 OR observed_archive_rows<>59
                   OR expected_latest_set_hash<>'9716224077ff6b7468c0b7b2fed6ab73' OR observed_latest_set_hash<>'9716224077ff6b7468c0b7b2fed6ab73'
                   OR expected_archive_set_hash<>'ea3a63d0bd9069cb5c061d09750d8d32' OR observed_archive_set_hash<>'ea3a63d0bd9069cb5c061d09750d8d32'
                   OR payload_mismatch_count<>0 OR missing_latest_rows<>0 OR missing_archive_rows<>0 OR latest_duplicate_key_rows<>0 OR archive_duplicate_key_rows<>0
                   OR archive_trigger_status<>'PASS' OR reproduction_status<>'PASS' OR source_registry_row_hash<>'03b6c0ca3af4ab9d196e09cefa59be3d'
                   OR row_hash IS DISTINCT FROM md5((to_jsonb(r)-'row_hash'-'created_at')::text)) FROM r))::bigint AS mismatch_count,
        ((SELECT count(*)=1 FROM c)
         AND (SELECT count(*)=0 FROM c WHERE registry_relation<>'msbf_ctl.m2_8_servicing_execution_contract_registry' OR latest_relation<>'msbf_m2.application_servicing_execution_latest' OR archive_relation<>'msbf_m2.application_servicing_execution_archive' OR latest_business_grain<>'module1_run_id + scenario_id + merchant_application_id'
              OR latest_business_key_columns<>'["module1_run_id","scenario_id","merchant_application_id"]'::jsonb OR archive_business_key_columns<>'["module1_run_id","contract_version","scenario_id","merchant_application_id"]'::jsonb
              OR required_source_edge_codes<>ARRAY['M2_7_TO_M2_8']::text[] OR required_source_edge_count<>1 OR passed_source_edge_count<>1)
         AND (SELECT count(*)=1 FROM r)
         AND (SELECT count(*)=0 FROM r WHERE registry_relation<>'msbf_ctl.m2_8_servicing_execution_contract_registry' OR latest_relation<>'msbf_m2.application_servicing_execution_latest' OR archive_relation<>'msbf_m2.application_servicing_execution_archive'
              OR latest_business_key_columns<>'["module1_run_id","scenario_id","merchant_application_id"]'::jsonb OR archive_business_key_columns<>'["module1_run_id","contract_version","scenario_id","merchant_application_id"]'::jsonb
              OR expected_latest_rows<>59 OR observed_latest_rows<>59
              OR expected_archive_rows<>59 OR observed_archive_rows<>59
              OR expected_latest_set_hash<>'9716224077ff6b7468c0b7b2fed6ab73' OR observed_latest_set_hash<>'9716224077ff6b7468c0b7b2fed6ab73'
              OR expected_archive_set_hash<>'ea3a63d0bd9069cb5c061d09750d8d32' OR observed_archive_set_hash<>'ea3a63d0bd9069cb5c061d09750d8d32'
              OR payload_mismatch_count<>0 OR missing_latest_rows<>0 OR missing_archive_rows<>0 OR latest_duplicate_key_rows<>0 OR archive_duplicate_key_rows<>0
              OR archive_trigger_status<>'PASS' OR reproduction_status<>'PASS' OR source_registry_row_hash<>'03b6c0ca3af4ab9d196e09cefa59be3d'
              OR row_hash IS DISTINCT FROM md5((to_jsonb(r)-'row_hash'-'created_at')::text))) AS pass_flag,
        'Physical relation, business-key, source-edge, and reproduction lineage for component M2_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONSUMPTION.'::text AS interpretation
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_055_COMPONENT_11_M2_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_CONSUMPTION_IDENTITY */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    55::smallint,
    'M2_12_POS_055_COMPONENT_11_M2_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_CONSUMPTION_IDENTITY'::text,
    3::smallint,
    'COMPONENT_CONTRACT'::text,
    'Component 11 M2_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_CONSUMPTION identity, counts, hashes, and statuses are exact'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH c AS (
        SELECT t.* FROM msbf_m2.module2_contract_component_snapshot t
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id
        WHERE t.component_sequence=11 AND t.component_contract_code='M2_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_CONSUMPTION' AND t.contract_version=1
    )
    SELECT
        concat_ws('|',count(*)::text,min(component_contract_code),min(contract_version)::text,min(schema_version),min(methodology_version),
            min(expected_latest_rows)::text,min(observed_latest_rows)::text,min(expected_archive_rows)::text,min(observed_archive_rows)::text,
            min(observed_contract_set_hash),min(observed_stage_combined_set_hash),min(observed_registry_row_hash),min(observed_latest_set_hash),min(observed_archive_set_hash),
            min(contract_status),min(gate_status),min(acceptance_evidence_status),min(certification_status),
            count(*) FILTER (WHERE row_hash IS DISTINCT FROM md5((to_jsonb(c)-'row_hash'-'created_at')::text))::text) AS observed_value,
        '1|M2_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_CONSUMPTION|1|M2_9_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_SCHEMA_V1|M2_9_METHOD_V1|59|59|59|59|5976e2e037a53aa184d29b7bcfeaf09e|6af76d0059b47623619ebc09330b15fe|6df16ccd5d6d7f7bffbc0ca4a2539140|e1206bb355dac10fa8d97a81637ce965|0bbe110652afd2a01378d36c596e4379|ACCEPTED|PASS|PASS|PASS|0'::text AS expected_value,
        (CASE WHEN count(*)=1 AND min(certification_node_sequence)=10
                   AND min(stage_code)='M2_9_RECONCILIATION_CERTIFICATION' AND min(repository_stage)='28_M2_9'
                   AND min(component_contract_code)='M2_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_CONSUMPTION' AND min(contract_version)=1
                   AND min(schema_version)='M2_9_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_SCHEMA_V1' AND min(methodology_version)='M2_9_METHOD_V1'
                   AND min(acceptance_gate_id)='M2_9_PAYMENT_RECONCILIATION_EXCEPTION_RESOLUTION_ACCOUNT_STATE_CERTIFICATION'
                   AND min(expected_latest_rows)=59 AND min(observed_latest_rows)=59
                   AND min(expected_archive_rows)=59 AND min(observed_archive_rows)=59
                   AND min(stage_expected_canonical_entities)=438
                   AND min(expected_positive_controls)=120 AND min(observed_positive_controls)=120
                   AND min(expected_negative_controls)=20 AND min(observed_negative_controls)=20
                   AND min(expected_contract_set_hash)='5976e2e037a53aa184d29b7bcfeaf09e' AND min(observed_contract_set_hash)='5976e2e037a53aa184d29b7bcfeaf09e'
                   AND min(expected_stage_combined_set_hash)='6af76d0059b47623619ebc09330b15fe' AND min(observed_stage_combined_set_hash)='6af76d0059b47623619ebc09330b15fe'
                   AND min(expected_registry_row_hash)='6df16ccd5d6d7f7bffbc0ca4a2539140' AND min(observed_registry_row_hash)='6df16ccd5d6d7f7bffbc0ca4a2539140'
                   AND min(expected_latest_set_hash)='e1206bb355dac10fa8d97a81637ce965' AND min(observed_latest_set_hash)='e1206bb355dac10fa8d97a81637ce965'
                   AND min(expected_archive_set_hash)='0bbe110652afd2a01378d36c596e4379' AND min(observed_archive_set_hash)='0bbe110652afd2a01378d36c596e4379'
                   AND min(contract_status)='ACCEPTED' AND min(gate_status)='PASS' AND min(acceptance_evidence_status)='PASS' AND min(certification_status)='PASS'
                   AND min(required_source_edge_count)=1 AND min(passed_source_edge_count)=1
                   AND count(*) FILTER (WHERE row_hash IS DISTINCT FROM md5((to_jsonb(c)-'row_hash'-'created_at')::text))=0
              THEN 0 ELSE 1 END)::bigint AS mismatch_count,
        (count(*)=1 AND min(certification_node_sequence)=10
         AND min(stage_code)='M2_9_RECONCILIATION_CERTIFICATION' AND min(repository_stage)='28_M2_9'
         AND min(component_contract_code)='M2_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_CONSUMPTION' AND min(contract_version)=1
         AND min(schema_version)='M2_9_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_SCHEMA_V1' AND min(methodology_version)='M2_9_METHOD_V1'
         AND min(acceptance_gate_id)='M2_9_PAYMENT_RECONCILIATION_EXCEPTION_RESOLUTION_ACCOUNT_STATE_CERTIFICATION'
         AND min(expected_latest_rows)=59 AND min(observed_latest_rows)=59
         AND min(expected_archive_rows)=59 AND min(observed_archive_rows)=59
         AND min(stage_expected_canonical_entities)=438
         AND min(expected_positive_controls)=120 AND min(observed_positive_controls)=120
         AND min(expected_negative_controls)=20 AND min(observed_negative_controls)=20
         AND min(expected_contract_set_hash)='5976e2e037a53aa184d29b7bcfeaf09e' AND min(observed_contract_set_hash)='5976e2e037a53aa184d29b7bcfeaf09e'
         AND min(expected_stage_combined_set_hash)='6af76d0059b47623619ebc09330b15fe' AND min(observed_stage_combined_set_hash)='6af76d0059b47623619ebc09330b15fe'
         AND min(expected_registry_row_hash)='6df16ccd5d6d7f7bffbc0ca4a2539140' AND min(observed_registry_row_hash)='6df16ccd5d6d7f7bffbc0ca4a2539140'
         AND min(expected_latest_set_hash)='e1206bb355dac10fa8d97a81637ce965' AND min(observed_latest_set_hash)='e1206bb355dac10fa8d97a81637ce965'
         AND min(expected_archive_set_hash)='0bbe110652afd2a01378d36c596e4379' AND min(observed_archive_set_hash)='0bbe110652afd2a01378d36c596e4379'
         AND min(contract_status)='ACCEPTED' AND min(gate_status)='PASS' AND min(acceptance_evidence_status)='PASS' AND min(certification_status)='PASS'
         AND min(required_source_edge_count)=1 AND min(passed_source_edge_count)=1
         AND count(*) FILTER (WHERE row_hash IS DISTINCT FROM md5((to_jsonb(c)-'row_hash'-'created_at')::text))=0) AS pass_flag,
        'Frozen contract identity and copied accepted-source hashes for component M2_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_CONSUMPTION.'::text AS interpretation
    FROM c
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_056_COMPONENT_11_M2_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_CONSUMPTION_LINEAGE */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    56::smallint,
    'M2_12_POS_056_COMPONENT_11_M2_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_CONSUMPTION_LINEAGE'::text,
    3::smallint,
    'COMPONENT_CONTRACT'::text,
    'Component 11 M2_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_CONSUMPTION physical relation, business-key, edge, and reproduction lineage is exact'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH c AS (
        SELECT t.* FROM msbf_m2.module2_contract_component_snapshot t
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id
        WHERE t.component_sequence=11 AND t.component_contract_code='M2_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_CONSUMPTION' AND t.contract_version=1
    ), r AS (
        SELECT t.* FROM msbf_m2.module2_contract_reproduction_snapshot t
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id
        WHERE t.component_sequence=11 AND t.component_contract_code='M2_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_CONSUMPTION' AND t.contract_version=1
    )
    SELECT
        concat_ws('|',(SELECT count(*) FROM c),(SELECT min(registry_relation) FROM c),(SELECT min(latest_relation) FROM c),(SELECT min(archive_relation) FROM c),
            (SELECT min(latest_business_grain) FROM c),(SELECT min(latest_business_key_columns::text) FROM c),(SELECT min(archive_business_key_columns::text) FROM c),
            (SELECT min(required_source_edge_count)::text FROM c),(SELECT min(passed_source_edge_count)::text FROM c),(SELECT count(*) FROM r),
            (SELECT min(reproduction_status) FROM r),(SELECT min(archive_trigger_status) FROM r)) AS observed_value,
        '1|msbf_ctl.m2_9_reconciliation_certification_contract_registry|msbf_m2.application_payment_reconciliation_certification_latest|msbf_m2.application_payment_reconciliation_certification_archive|module1_run_id + scenario_id + merchant_application_id|["module1_run_id","scenario_id","merchant_application_id"]|["module1_run_id","contract_version","scenario_id","merchant_application_id"]|1|1|1|PASS|PASS'::text AS expected_value,
        ((SELECT (count(*)<>1)::integer FROM c)
         +(SELECT count(*) FILTER (WHERE registry_relation<>'msbf_ctl.m2_9_reconciliation_certification_contract_registry' OR latest_relation<>'msbf_m2.application_payment_reconciliation_certification_latest' OR archive_relation<>'msbf_m2.application_payment_reconciliation_certification_archive' OR latest_business_grain<>'module1_run_id + scenario_id + merchant_application_id'
                   OR latest_business_key_columns<>'["module1_run_id","scenario_id","merchant_application_id"]'::jsonb OR archive_business_key_columns<>'["module1_run_id","contract_version","scenario_id","merchant_application_id"]'::jsonb
                   OR required_source_edge_codes<>ARRAY['M2_8_TO_M2_9']::text[] OR required_source_edge_count<>1 OR passed_source_edge_count<>1) FROM c)
         +(SELECT (count(*)<>1)::integer FROM r)
         +(SELECT count(*) FILTER (WHERE registry_relation<>'msbf_ctl.m2_9_reconciliation_certification_contract_registry' OR latest_relation<>'msbf_m2.application_payment_reconciliation_certification_latest' OR archive_relation<>'msbf_m2.application_payment_reconciliation_certification_archive'
                   OR latest_business_key_columns<>'["module1_run_id","scenario_id","merchant_application_id"]'::jsonb OR archive_business_key_columns<>'["module1_run_id","contract_version","scenario_id","merchant_application_id"]'::jsonb
                   OR expected_latest_rows<>59 OR observed_latest_rows<>59
                   OR expected_archive_rows<>59 OR observed_archive_rows<>59
                   OR expected_latest_set_hash<>'e1206bb355dac10fa8d97a81637ce965' OR observed_latest_set_hash<>'e1206bb355dac10fa8d97a81637ce965'
                   OR expected_archive_set_hash<>'0bbe110652afd2a01378d36c596e4379' OR observed_archive_set_hash<>'0bbe110652afd2a01378d36c596e4379'
                   OR payload_mismatch_count<>0 OR missing_latest_rows<>0 OR missing_archive_rows<>0 OR latest_duplicate_key_rows<>0 OR archive_duplicate_key_rows<>0
                   OR archive_trigger_status<>'PASS' OR reproduction_status<>'PASS' OR source_registry_row_hash<>'6df16ccd5d6d7f7bffbc0ca4a2539140'
                   OR row_hash IS DISTINCT FROM md5((to_jsonb(r)-'row_hash'-'created_at')::text)) FROM r))::bigint AS mismatch_count,
        ((SELECT count(*)=1 FROM c)
         AND (SELECT count(*)=0 FROM c WHERE registry_relation<>'msbf_ctl.m2_9_reconciliation_certification_contract_registry' OR latest_relation<>'msbf_m2.application_payment_reconciliation_certification_latest' OR archive_relation<>'msbf_m2.application_payment_reconciliation_certification_archive' OR latest_business_grain<>'module1_run_id + scenario_id + merchant_application_id'
              OR latest_business_key_columns<>'["module1_run_id","scenario_id","merchant_application_id"]'::jsonb OR archive_business_key_columns<>'["module1_run_id","contract_version","scenario_id","merchant_application_id"]'::jsonb
              OR required_source_edge_codes<>ARRAY['M2_8_TO_M2_9']::text[] OR required_source_edge_count<>1 OR passed_source_edge_count<>1)
         AND (SELECT count(*)=1 FROM r)
         AND (SELECT count(*)=0 FROM r WHERE registry_relation<>'msbf_ctl.m2_9_reconciliation_certification_contract_registry' OR latest_relation<>'msbf_m2.application_payment_reconciliation_certification_latest' OR archive_relation<>'msbf_m2.application_payment_reconciliation_certification_archive'
              OR latest_business_key_columns<>'["module1_run_id","scenario_id","merchant_application_id"]'::jsonb OR archive_business_key_columns<>'["module1_run_id","contract_version","scenario_id","merchant_application_id"]'::jsonb
              OR expected_latest_rows<>59 OR observed_latest_rows<>59
              OR expected_archive_rows<>59 OR observed_archive_rows<>59
              OR expected_latest_set_hash<>'e1206bb355dac10fa8d97a81637ce965' OR observed_latest_set_hash<>'e1206bb355dac10fa8d97a81637ce965'
              OR expected_archive_set_hash<>'0bbe110652afd2a01378d36c596e4379' OR observed_archive_set_hash<>'0bbe110652afd2a01378d36c596e4379'
              OR payload_mismatch_count<>0 OR missing_latest_rows<>0 OR missing_archive_rows<>0 OR latest_duplicate_key_rows<>0 OR archive_duplicate_key_rows<>0
              OR archive_trigger_status<>'PASS' OR reproduction_status<>'PASS' OR source_registry_row_hash<>'6df16ccd5d6d7f7bffbc0ca4a2539140'
              OR row_hash IS DISTINCT FROM md5((to_jsonb(r)-'row_hash'-'created_at')::text))) AS pass_flag,
        'Physical relation, business-key, source-edge, and reproduction lineage for component M2_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_CONSUMPTION.'::text AS interpretation
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_057_COMPONENT_12_M2_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_CONSUMPTION_IDENTITY */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    57::smallint,
    'M2_12_POS_057_COMPONENT_12_M2_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_CONSUMPTION_IDENTITY'::text,
    3::smallint,
    'COMPONENT_CONTRACT'::text,
    'Component 12 M2_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_CONSUMPTION identity, counts, hashes, and statuses are exact'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH c AS (
        SELECT t.* FROM msbf_m2.module2_contract_component_snapshot t
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id
        WHERE t.component_sequence=12 AND t.component_contract_code='M2_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_CONSUMPTION' AND t.contract_version=1
    )
    SELECT
        concat_ws('|',count(*)::text,min(component_contract_code),min(contract_version)::text,min(schema_version),min(methodology_version),
            min(expected_latest_rows)::text,min(observed_latest_rows)::text,min(expected_archive_rows)::text,min(observed_archive_rows)::text,
            min(observed_contract_set_hash),min(observed_stage_combined_set_hash),min(observed_registry_row_hash),min(observed_latest_set_hash),min(observed_archive_set_hash),
            min(contract_status),min(gate_status),min(acceptance_evidence_status),min(certification_status),
            count(*) FILTER (WHERE row_hash IS DISTINCT FROM md5((to_jsonb(c)-'row_hash'-'created_at')::text))::text) AS observed_value,
        '1|M2_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_CONSUMPTION|1|M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_SCHEMA_V1|M2_10_METHOD_V1|59|59|59|59|98771133c07f0bdb9828cf233f32ad2f|24fca7263a04397ebf21d30639f9069b|944d8f676a5b7fb58700b2a66309f428|c34f6721bd7a6818d2492d564611ef2a|105691ceca00acc516296b19a64a1c25|ACCEPTED|PASS|PASS|PASS|0'::text AS expected_value,
        (CASE WHEN count(*)=1 AND min(certification_node_sequence)=11
                   AND min(stage_code)='M2_10_PORTFOLIO_ANALYTICS' AND min(repository_stage)='29_M2_10'
                   AND min(component_contract_code)='M2_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_CONSUMPTION' AND min(contract_version)=1
                   AND min(schema_version)='M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_SCHEMA_V1' AND min(methodology_version)='M2_10_METHOD_V1'
                   AND min(acceptance_gate_id)='M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS'
                   AND min(expected_latest_rows)=59 AND min(observed_latest_rows)=59
                   AND min(expected_archive_rows)=59 AND min(observed_archive_rows)=59
                   AND min(stage_expected_canonical_entities)=370
                   AND min(expected_positive_controls)=120 AND min(observed_positive_controls)=120
                   AND min(expected_negative_controls)=20 AND min(observed_negative_controls)=20
                   AND min(expected_contract_set_hash)='98771133c07f0bdb9828cf233f32ad2f' AND min(observed_contract_set_hash)='98771133c07f0bdb9828cf233f32ad2f'
                   AND min(expected_stage_combined_set_hash)='24fca7263a04397ebf21d30639f9069b' AND min(observed_stage_combined_set_hash)='24fca7263a04397ebf21d30639f9069b'
                   AND min(expected_registry_row_hash)='944d8f676a5b7fb58700b2a66309f428' AND min(observed_registry_row_hash)='944d8f676a5b7fb58700b2a66309f428'
                   AND min(expected_latest_set_hash)='c34f6721bd7a6818d2492d564611ef2a' AND min(observed_latest_set_hash)='c34f6721bd7a6818d2492d564611ef2a'
                   AND min(expected_archive_set_hash)='105691ceca00acc516296b19a64a1c25' AND min(observed_archive_set_hash)='105691ceca00acc516296b19a64a1c25'
                   AND min(contract_status)='ACCEPTED' AND min(gate_status)='PASS' AND min(acceptance_evidence_status)='PASS' AND min(certification_status)='PASS'
                   AND min(required_source_edge_count)=1 AND min(passed_source_edge_count)=1
                   AND count(*) FILTER (WHERE row_hash IS DISTINCT FROM md5((to_jsonb(c)-'row_hash'-'created_at')::text))=0
              THEN 0 ELSE 1 END)::bigint AS mismatch_count,
        (count(*)=1 AND min(certification_node_sequence)=11
         AND min(stage_code)='M2_10_PORTFOLIO_ANALYTICS' AND min(repository_stage)='29_M2_10'
         AND min(component_contract_code)='M2_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_CONSUMPTION' AND min(contract_version)=1
         AND min(schema_version)='M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_SCHEMA_V1' AND min(methodology_version)='M2_10_METHOD_V1'
         AND min(acceptance_gate_id)='M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS'
         AND min(expected_latest_rows)=59 AND min(observed_latest_rows)=59
         AND min(expected_archive_rows)=59 AND min(observed_archive_rows)=59
         AND min(stage_expected_canonical_entities)=370
         AND min(expected_positive_controls)=120 AND min(observed_positive_controls)=120
         AND min(expected_negative_controls)=20 AND min(observed_negative_controls)=20
         AND min(expected_contract_set_hash)='98771133c07f0bdb9828cf233f32ad2f' AND min(observed_contract_set_hash)='98771133c07f0bdb9828cf233f32ad2f'
         AND min(expected_stage_combined_set_hash)='24fca7263a04397ebf21d30639f9069b' AND min(observed_stage_combined_set_hash)='24fca7263a04397ebf21d30639f9069b'
         AND min(expected_registry_row_hash)='944d8f676a5b7fb58700b2a66309f428' AND min(observed_registry_row_hash)='944d8f676a5b7fb58700b2a66309f428'
         AND min(expected_latest_set_hash)='c34f6721bd7a6818d2492d564611ef2a' AND min(observed_latest_set_hash)='c34f6721bd7a6818d2492d564611ef2a'
         AND min(expected_archive_set_hash)='105691ceca00acc516296b19a64a1c25' AND min(observed_archive_set_hash)='105691ceca00acc516296b19a64a1c25'
         AND min(contract_status)='ACCEPTED' AND min(gate_status)='PASS' AND min(acceptance_evidence_status)='PASS' AND min(certification_status)='PASS'
         AND min(required_source_edge_count)=1 AND min(passed_source_edge_count)=1
         AND count(*) FILTER (WHERE row_hash IS DISTINCT FROM md5((to_jsonb(c)-'row_hash'-'created_at')::text))=0) AS pass_flag,
        'Frozen contract identity and copied accepted-source hashes for component M2_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_CONSUMPTION.'::text AS interpretation
    FROM c
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_058_COMPONENT_12_M2_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_CONSUMPTION_LINEAGE */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    58::smallint,
    'M2_12_POS_058_COMPONENT_12_M2_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_CONSUMPTION_LINEAGE'::text,
    3::smallint,
    'COMPONENT_CONTRACT'::text,
    'Component 12 M2_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_CONSUMPTION physical relation, business-key, edge, and reproduction lineage is exact'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH c AS (
        SELECT t.* FROM msbf_m2.module2_contract_component_snapshot t
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id
        WHERE t.component_sequence=12 AND t.component_contract_code='M2_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_CONSUMPTION' AND t.contract_version=1
    ), r AS (
        SELECT t.* FROM msbf_m2.module2_contract_reproduction_snapshot t
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id
        WHERE t.component_sequence=12 AND t.component_contract_code='M2_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_CONSUMPTION' AND t.contract_version=1
    )
    SELECT
        concat_ws('|',(SELECT count(*) FROM c),(SELECT min(registry_relation) FROM c),(SELECT min(latest_relation) FROM c),(SELECT min(archive_relation) FROM c),
            (SELECT min(latest_business_grain) FROM c),(SELECT min(latest_business_key_columns::text) FROM c),(SELECT min(archive_business_key_columns::text) FROM c),
            (SELECT min(required_source_edge_count)::text FROM c),(SELECT min(passed_source_edge_count)::text FROM c),(SELECT count(*) FROM r),
            (SELECT min(reproduction_status) FROM r),(SELECT min(archive_trigger_status) FROM r)) AS observed_value,
        '1|msbf_ctl.m2_10_portfolio_analytics_contract_registry|msbf_m2.application_portfolio_performance_latest|msbf_m2.application_portfolio_performance_archive|module1_run_id + scenario_id + merchant_application_id|["module1_run_id","scenario_id","merchant_application_id"]|["module1_run_id","contract_version","scenario_id","merchant_application_id"]|1|1|1|PASS|PASS'::text AS expected_value,
        ((SELECT (count(*)<>1)::integer FROM c)
         +(SELECT count(*) FILTER (WHERE registry_relation<>'msbf_ctl.m2_10_portfolio_analytics_contract_registry' OR latest_relation<>'msbf_m2.application_portfolio_performance_latest' OR archive_relation<>'msbf_m2.application_portfolio_performance_archive' OR latest_business_grain<>'module1_run_id + scenario_id + merchant_application_id'
                   OR latest_business_key_columns<>'["module1_run_id","scenario_id","merchant_application_id"]'::jsonb OR archive_business_key_columns<>'["module1_run_id","contract_version","scenario_id","merchant_application_id"]'::jsonb
                   OR required_source_edge_codes<>ARRAY['M2_9_TO_M2_10']::text[] OR required_source_edge_count<>1 OR passed_source_edge_count<>1) FROM c)
         +(SELECT (count(*)<>1)::integer FROM r)
         +(SELECT count(*) FILTER (WHERE registry_relation<>'msbf_ctl.m2_10_portfolio_analytics_contract_registry' OR latest_relation<>'msbf_m2.application_portfolio_performance_latest' OR archive_relation<>'msbf_m2.application_portfolio_performance_archive'
                   OR latest_business_key_columns<>'["module1_run_id","scenario_id","merchant_application_id"]'::jsonb OR archive_business_key_columns<>'["module1_run_id","contract_version","scenario_id","merchant_application_id"]'::jsonb
                   OR expected_latest_rows<>59 OR observed_latest_rows<>59
                   OR expected_archive_rows<>59 OR observed_archive_rows<>59
                   OR expected_latest_set_hash<>'c34f6721bd7a6818d2492d564611ef2a' OR observed_latest_set_hash<>'c34f6721bd7a6818d2492d564611ef2a'
                   OR expected_archive_set_hash<>'105691ceca00acc516296b19a64a1c25' OR observed_archive_set_hash<>'105691ceca00acc516296b19a64a1c25'
                   OR payload_mismatch_count<>0 OR missing_latest_rows<>0 OR missing_archive_rows<>0 OR latest_duplicate_key_rows<>0 OR archive_duplicate_key_rows<>0
                   OR archive_trigger_status<>'PASS' OR reproduction_status<>'PASS' OR source_registry_row_hash<>'944d8f676a5b7fb58700b2a66309f428'
                   OR row_hash IS DISTINCT FROM md5((to_jsonb(r)-'row_hash'-'created_at')::text)) FROM r))::bigint AS mismatch_count,
        ((SELECT count(*)=1 FROM c)
         AND (SELECT count(*)=0 FROM c WHERE registry_relation<>'msbf_ctl.m2_10_portfolio_analytics_contract_registry' OR latest_relation<>'msbf_m2.application_portfolio_performance_latest' OR archive_relation<>'msbf_m2.application_portfolio_performance_archive' OR latest_business_grain<>'module1_run_id + scenario_id + merchant_application_id'
              OR latest_business_key_columns<>'["module1_run_id","scenario_id","merchant_application_id"]'::jsonb OR archive_business_key_columns<>'["module1_run_id","contract_version","scenario_id","merchant_application_id"]'::jsonb
              OR required_source_edge_codes<>ARRAY['M2_9_TO_M2_10']::text[] OR required_source_edge_count<>1 OR passed_source_edge_count<>1)
         AND (SELECT count(*)=1 FROM r)
         AND (SELECT count(*)=0 FROM r WHERE registry_relation<>'msbf_ctl.m2_10_portfolio_analytics_contract_registry' OR latest_relation<>'msbf_m2.application_portfolio_performance_latest' OR archive_relation<>'msbf_m2.application_portfolio_performance_archive'
              OR latest_business_key_columns<>'["module1_run_id","scenario_id","merchant_application_id"]'::jsonb OR archive_business_key_columns<>'["module1_run_id","contract_version","scenario_id","merchant_application_id"]'::jsonb
              OR expected_latest_rows<>59 OR observed_latest_rows<>59
              OR expected_archive_rows<>59 OR observed_archive_rows<>59
              OR expected_latest_set_hash<>'c34f6721bd7a6818d2492d564611ef2a' OR observed_latest_set_hash<>'c34f6721bd7a6818d2492d564611ef2a'
              OR expected_archive_set_hash<>'105691ceca00acc516296b19a64a1c25' OR observed_archive_set_hash<>'105691ceca00acc516296b19a64a1c25'
              OR payload_mismatch_count<>0 OR missing_latest_rows<>0 OR missing_archive_rows<>0 OR latest_duplicate_key_rows<>0 OR archive_duplicate_key_rows<>0
              OR archive_trigger_status<>'PASS' OR reproduction_status<>'PASS' OR source_registry_row_hash<>'944d8f676a5b7fb58700b2a66309f428'
              OR row_hash IS DISTINCT FROM md5((to_jsonb(r)-'row_hash'-'created_at')::text))) AS pass_flag,
        'Physical relation, business-key, source-edge, and reproduction lineage for component M2_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_CONSUMPTION.'::text AS interpretation
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_059_COMPONENT_13_M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION_IDENTITY */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    59::smallint,
    'M2_12_POS_059_COMPONENT_13_M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION_IDENTITY'::text,
    3::smallint,
    'COMPONENT_CONTRACT'::text,
    'Component 13 M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION identity, counts, hashes, and statuses are exact'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH c AS (
        SELECT t.* FROM msbf_m2.module2_contract_component_snapshot t
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id
        WHERE t.component_sequence=13 AND t.component_contract_code='M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION' AND t.contract_version=1
    )
    SELECT
        concat_ws('|',count(*)::text,min(component_contract_code),min(contract_version)::text,min(schema_version),min(methodology_version),
            min(expected_latest_rows)::text,min(observed_latest_rows)::text,min(expected_archive_rows)::text,min(observed_archive_rows)::text,
            min(observed_contract_set_hash),min(observed_stage_combined_set_hash),min(observed_registry_row_hash),min(observed_latest_set_hash),min(observed_archive_set_hash),
            min(contract_status),min(gate_status),min(acceptance_evidence_status),min(certification_status),
            count(*) FILTER (WHERE row_hash IS DISTINCT FROM md5((to_jsonb(c)-'row_hash'-'created_at')::text))::text) AS observed_value,
        '1|M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION|1|M2_11_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_SCHEMA_V1|M2_11_METHOD_V1|24|24|24|24|19f1a9d842c9cb35617ca03e49445aad|a67d375b9f9248b3eec8160cf3dc656d|61c22f4f3f2e99905d05958fddf80671|634a9894d0241505582e0d89e4c5f27b|641deff3b776faa419cc6c0489f85024|ACCEPTED|PASS|PASS|PASS|0'::text AS expected_value,
        (CASE WHEN count(*)=1 AND min(certification_node_sequence)=12
                   AND min(stage_code)='M2_11_STRATEGY_SIMULATION' AND min(repository_stage)='30_M2_11'
                   AND min(component_contract_code)='M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION' AND min(contract_version)=1
                   AND min(schema_version)='M2_11_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_SCHEMA_V1' AND min(methodology_version)='M2_11_METHOD_V1'
                   AND min(acceptance_gate_id)='M2_11_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION'
                   AND min(expected_latest_rows)=24 AND min(observed_latest_rows)=24
                   AND min(expected_archive_rows)=24 AND min(observed_archive_rows)=24
                   AND min(stage_expected_canonical_entities)=19298
                   AND min(expected_positive_controls)=120 AND min(observed_positive_controls)=120
                   AND min(expected_negative_controls)=20 AND min(observed_negative_controls)=20
                   AND min(expected_contract_set_hash)='19f1a9d842c9cb35617ca03e49445aad' AND min(observed_contract_set_hash)='19f1a9d842c9cb35617ca03e49445aad'
                   AND min(expected_stage_combined_set_hash)='a67d375b9f9248b3eec8160cf3dc656d' AND min(observed_stage_combined_set_hash)='a67d375b9f9248b3eec8160cf3dc656d'
                   AND min(expected_registry_row_hash)='61c22f4f3f2e99905d05958fddf80671' AND min(observed_registry_row_hash)='61c22f4f3f2e99905d05958fddf80671'
                   AND min(expected_latest_set_hash)='634a9894d0241505582e0d89e4c5f27b' AND min(observed_latest_set_hash)='634a9894d0241505582e0d89e4c5f27b'
                   AND min(expected_archive_set_hash)='641deff3b776faa419cc6c0489f85024' AND min(observed_archive_set_hash)='641deff3b776faa419cc6c0489f85024'
                   AND min(contract_status)='ACCEPTED' AND min(gate_status)='PASS' AND min(acceptance_evidence_status)='PASS' AND min(certification_status)='PASS'
                   AND min(required_source_edge_count)=5 AND min(passed_source_edge_count)=5
                   AND count(*) FILTER (WHERE row_hash IS DISTINCT FROM md5((to_jsonb(c)-'row_hash'-'created_at')::text))=0
              THEN 0 ELSE 1 END)::bigint AS mismatch_count,
        (count(*)=1 AND min(certification_node_sequence)=12
         AND min(stage_code)='M2_11_STRATEGY_SIMULATION' AND min(repository_stage)='30_M2_11'
         AND min(component_contract_code)='M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION' AND min(contract_version)=1
         AND min(schema_version)='M2_11_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_SCHEMA_V1' AND min(methodology_version)='M2_11_METHOD_V1'
         AND min(acceptance_gate_id)='M2_11_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION'
         AND min(expected_latest_rows)=24 AND min(observed_latest_rows)=24
         AND min(expected_archive_rows)=24 AND min(observed_archive_rows)=24
         AND min(stage_expected_canonical_entities)=19298
         AND min(expected_positive_controls)=120 AND min(observed_positive_controls)=120
         AND min(expected_negative_controls)=20 AND min(observed_negative_controls)=20
         AND min(expected_contract_set_hash)='19f1a9d842c9cb35617ca03e49445aad' AND min(observed_contract_set_hash)='19f1a9d842c9cb35617ca03e49445aad'
         AND min(expected_stage_combined_set_hash)='a67d375b9f9248b3eec8160cf3dc656d' AND min(observed_stage_combined_set_hash)='a67d375b9f9248b3eec8160cf3dc656d'
         AND min(expected_registry_row_hash)='61c22f4f3f2e99905d05958fddf80671' AND min(observed_registry_row_hash)='61c22f4f3f2e99905d05958fddf80671'
         AND min(expected_latest_set_hash)='634a9894d0241505582e0d89e4c5f27b' AND min(observed_latest_set_hash)='634a9894d0241505582e0d89e4c5f27b'
         AND min(expected_archive_set_hash)='641deff3b776faa419cc6c0489f85024' AND min(observed_archive_set_hash)='641deff3b776faa419cc6c0489f85024'
         AND min(contract_status)='ACCEPTED' AND min(gate_status)='PASS' AND min(acceptance_evidence_status)='PASS' AND min(certification_status)='PASS'
         AND min(required_source_edge_count)=5 AND min(passed_source_edge_count)=5
         AND count(*) FILTER (WHERE row_hash IS DISTINCT FROM md5((to_jsonb(c)-'row_hash'-'created_at')::text))=0) AS pass_flag,
        'Frozen contract identity and copied accepted-source hashes for component M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION.'::text AS interpretation
    FROM c
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_060_COMPONENT_13_M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION_LINEAGE */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    60::smallint,
    'M2_12_POS_060_COMPONENT_13_M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION_LINEAGE'::text,
    3::smallint,
    'COMPONENT_CONTRACT'::text,
    'Component 13 M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION physical relation, business-key, edge, and reproduction lineage is exact'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH c AS (
        SELECT t.* FROM msbf_m2.module2_contract_component_snapshot t
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id
        WHERE t.component_sequence=13 AND t.component_contract_code='M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION' AND t.contract_version=1
    ), r AS (
        SELECT t.* FROM msbf_m2.module2_contract_reproduction_snapshot t
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id
        WHERE t.component_sequence=13 AND t.component_contract_code='M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION' AND t.contract_version=1
    )
    SELECT
        concat_ws('|',(SELECT count(*) FROM c),(SELECT min(registry_relation) FROM c),(SELECT min(latest_relation) FROM c),(SELECT min(archive_relation) FROM c),
            (SELECT min(latest_business_grain) FROM c),(SELECT min(latest_business_key_columns::text) FROM c),(SELECT min(archive_business_key_columns::text) FROM c),
            (SELECT min(required_source_edge_count)::text FROM c),(SELECT min(passed_source_edge_count)::text FROM c),(SELECT count(*) FROM r),
            (SELECT min(reproduction_status) FROM r),(SELECT min(archive_trigger_status) FROM r)) AS observed_value,
        '1|msbf_ctl.m2_11_portfolio_strategy_contract_registry|msbf_m2.portfolio_strategy_simulation_latest|msbf_m2.portfolio_strategy_simulation_archive|module1_run_id + strategy_profile_code + reporting_scope_code|["module1_run_id","strategy_profile_code","reporting_scope_code"]|["module1_run_id","contract_version","strategy_profile_code","reporting_scope_code"]|5|5|1|PASS|PASS'::text AS expected_value,
        ((SELECT (count(*)<>1)::integer FROM c)
         +(SELECT count(*) FILTER (WHERE registry_relation<>'msbf_ctl.m2_11_portfolio_strategy_contract_registry' OR latest_relation<>'msbf_m2.portfolio_strategy_simulation_latest' OR archive_relation<>'msbf_m2.portfolio_strategy_simulation_archive' OR latest_business_grain<>'module1_run_id + strategy_profile_code + reporting_scope_code'
                   OR latest_business_key_columns<>'["module1_run_id","strategy_profile_code","reporting_scope_code"]'::jsonb OR archive_business_key_columns<>'["module1_run_id","contract_version","strategy_profile_code","reporting_scope_code"]'::jsonb
                   OR required_source_edge_codes<>ARRAY['M1_17_TO_M2_11','M2_2_TO_M2_11','M2_4_TO_M2_11','M2_7_TO_M2_11','M2_10_TO_M2_11']::text[] OR required_source_edge_count<>5 OR passed_source_edge_count<>5) FROM c)
         +(SELECT (count(*)<>1)::integer FROM r)
         +(SELECT count(*) FILTER (WHERE registry_relation<>'msbf_ctl.m2_11_portfolio_strategy_contract_registry' OR latest_relation<>'msbf_m2.portfolio_strategy_simulation_latest' OR archive_relation<>'msbf_m2.portfolio_strategy_simulation_archive'
                   OR latest_business_key_columns<>'["module1_run_id","strategy_profile_code","reporting_scope_code"]'::jsonb OR archive_business_key_columns<>'["module1_run_id","contract_version","strategy_profile_code","reporting_scope_code"]'::jsonb
                   OR expected_latest_rows<>24 OR observed_latest_rows<>24
                   OR expected_archive_rows<>24 OR observed_archive_rows<>24
                   OR expected_latest_set_hash<>'634a9894d0241505582e0d89e4c5f27b' OR observed_latest_set_hash<>'634a9894d0241505582e0d89e4c5f27b'
                   OR expected_archive_set_hash<>'641deff3b776faa419cc6c0489f85024' OR observed_archive_set_hash<>'641deff3b776faa419cc6c0489f85024'
                   OR payload_mismatch_count<>0 OR missing_latest_rows<>0 OR missing_archive_rows<>0 OR latest_duplicate_key_rows<>0 OR archive_duplicate_key_rows<>0
                   OR archive_trigger_status<>'PASS' OR reproduction_status<>'PASS' OR source_registry_row_hash<>'61c22f4f3f2e99905d05958fddf80671'
                   OR row_hash IS DISTINCT FROM md5((to_jsonb(r)-'row_hash'-'created_at')::text)) FROM r))::bigint AS mismatch_count,
        ((SELECT count(*)=1 FROM c)
         AND (SELECT count(*)=0 FROM c WHERE registry_relation<>'msbf_ctl.m2_11_portfolio_strategy_contract_registry' OR latest_relation<>'msbf_m2.portfolio_strategy_simulation_latest' OR archive_relation<>'msbf_m2.portfolio_strategy_simulation_archive' OR latest_business_grain<>'module1_run_id + strategy_profile_code + reporting_scope_code'
              OR latest_business_key_columns<>'["module1_run_id","strategy_profile_code","reporting_scope_code"]'::jsonb OR archive_business_key_columns<>'["module1_run_id","contract_version","strategy_profile_code","reporting_scope_code"]'::jsonb
              OR required_source_edge_codes<>ARRAY['M1_17_TO_M2_11','M2_2_TO_M2_11','M2_4_TO_M2_11','M2_7_TO_M2_11','M2_10_TO_M2_11']::text[] OR required_source_edge_count<>5 OR passed_source_edge_count<>5)
         AND (SELECT count(*)=1 FROM r)
         AND (SELECT count(*)=0 FROM r WHERE registry_relation<>'msbf_ctl.m2_11_portfolio_strategy_contract_registry' OR latest_relation<>'msbf_m2.portfolio_strategy_simulation_latest' OR archive_relation<>'msbf_m2.portfolio_strategy_simulation_archive'
              OR latest_business_key_columns<>'["module1_run_id","strategy_profile_code","reporting_scope_code"]'::jsonb OR archive_business_key_columns<>'["module1_run_id","contract_version","strategy_profile_code","reporting_scope_code"]'::jsonb
              OR expected_latest_rows<>24 OR observed_latest_rows<>24
              OR expected_archive_rows<>24 OR observed_archive_rows<>24
              OR expected_latest_set_hash<>'634a9894d0241505582e0d89e4c5f27b' OR observed_latest_set_hash<>'634a9894d0241505582e0d89e4c5f27b'
              OR expected_archive_set_hash<>'641deff3b776faa419cc6c0489f85024' OR observed_archive_set_hash<>'641deff3b776faa419cc6c0489f85024'
              OR payload_mismatch_count<>0 OR missing_latest_rows<>0 OR missing_archive_rows<>0 OR latest_duplicate_key_rows<>0 OR archive_duplicate_key_rows<>0
              OR archive_trigger_status<>'PASS' OR reproduction_status<>'PASS' OR source_registry_row_hash<>'61c22f4f3f2e99905d05958fddf80671'
              OR row_hash IS DISTINCT FROM md5((to_jsonb(r)-'row_hash'-'created_at')::text))) AS pass_flag,
        'Physical relation, business-key, source-edge, and reproduction lineage for component M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION.'::text AS interpretation
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_061_NODE_01_M1_17_G2_FOUNDATION_EVIDENCE_MATRIX */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    61::smallint,
    'M2_12_POS_061_NODE_01_M1_17_G2_FOUNDATION_EVIDENCE_MATRIX'::text,
    4::smallint,
    'EVIDENCE_CERTIFICATION'::text,
    'Node 01 M1_17_G2_FOUNDATION has the complete frozen six-family evidence-certification matrix'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH a AS (
        SELECT * FROM tmp_src_m2_12_evidence_authority WHERE node_sequence=1
    ), p AS (
        SELECT e.* FROM msbf_m2.module2_evidence_certification_snapshot e
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=e.module1_run_id
        WHERE e.node_sequence=1
    ), cmp AS (
        SELECT count(*)::bigint AS joined_rows,
               count(*) FILTER (WHERE a.matrix_sequence IS NULL OR p.module1_run_id IS NULL
                 OR p.stage_code IS DISTINCT FROM a.stage_code
                 OR p.evidence_family_sequence IS DISTINCT FROM a.evidence_family_sequence
                 OR p.evidence_family_code IS DISTINCT FROM a.evidence_family_code
                 OR p.applicability_code IS DISTINCT FROM a.applicability_code
                 OR p.allowed_certification_status IS DISTINCT FROM a.allowed_certification_status
                 OR p.authoritative_source_locator IS DISTINCT FROM a.authoritative_source_locator
                 OR p.evidence_code_or_method_pattern IS DISTINCT FROM a.evidence_code_or_method_pattern
                 OR p.expected_count_or_identity IS DISTINCT FROM a.expected_count_or_identity
                 OR p.expected_status IS DISTINCT FROM a.expected_status
                 OR coalesce(p.expected_hash,'') IS DISTINCT FROM coalesce(a.expected_hash,'')
                 OR p.observed_status IS DISTINCT FROM 'PASS'
                 OR p.mismatch_count<>0 OR p.certification_status<>'PASS'
                 OR p.source_registry_row_hash !~ '^[0-9a-f]{32}$'
                 OR p.row_hash IS DISTINCT FROM md5((to_jsonb(p)-'row_hash'-'created_at')::text)
               )::bigint AS mismatch_rows
        FROM a FULL JOIN p
          ON p.node_sequence=a.node_sequence
         AND p.evidence_family_sequence=a.evidence_family_sequence
         AND p.evidence_family_code=a.evidence_family_code
    )
    SELECT concat_ws('|',(SELECT count(*) FROM a),(SELECT count(*) FROM p),(SELECT mismatch_rows FROM cmp)) AS observed_value,
           '6|6|0'::text AS expected_value,
           ((SELECT (count(*)<>6)::integer FROM a)+(SELECT (count(*)<>6)::integer FROM p)+(SELECT mismatch_rows FROM cmp))::bigint AS mismatch_count,
           ((SELECT count(*)=6 FROM a) AND (SELECT count(*)=6 FROM p) AND (SELECT mismatch_rows=0 FROM cmp)) AS pass_flag,
           'Node M1_17_G2_FOUNDATION independently reconciles all six mandatory evidence families to persisted PASS state.'::text AS interpretation
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_062_NODE_02_M2_1_ELIGIBILITY_ROUTING_EVIDENCE_MATRIX */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    62::smallint,
    'M2_12_POS_062_NODE_02_M2_1_ELIGIBILITY_ROUTING_EVIDENCE_MATRIX'::text,
    4::smallint,
    'EVIDENCE_CERTIFICATION'::text,
    'Node 02 M2_1_ELIGIBILITY_ROUTING has the complete frozen six-family evidence-certification matrix'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH a AS (
        SELECT * FROM tmp_src_m2_12_evidence_authority WHERE node_sequence=2
    ), p AS (
        SELECT e.* FROM msbf_m2.module2_evidence_certification_snapshot e
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=e.module1_run_id
        WHERE e.node_sequence=2
    ), cmp AS (
        SELECT count(*)::bigint AS joined_rows,
               count(*) FILTER (WHERE a.matrix_sequence IS NULL OR p.module1_run_id IS NULL
                 OR p.stage_code IS DISTINCT FROM a.stage_code
                 OR p.evidence_family_sequence IS DISTINCT FROM a.evidence_family_sequence
                 OR p.evidence_family_code IS DISTINCT FROM a.evidence_family_code
                 OR p.applicability_code IS DISTINCT FROM a.applicability_code
                 OR p.allowed_certification_status IS DISTINCT FROM a.allowed_certification_status
                 OR p.authoritative_source_locator IS DISTINCT FROM a.authoritative_source_locator
                 OR p.evidence_code_or_method_pattern IS DISTINCT FROM a.evidence_code_or_method_pattern
                 OR p.expected_count_or_identity IS DISTINCT FROM a.expected_count_or_identity
                 OR p.expected_status IS DISTINCT FROM a.expected_status
                 OR coalesce(p.expected_hash,'') IS DISTINCT FROM coalesce(a.expected_hash,'')
                 OR p.observed_status IS DISTINCT FROM 'PASS'
                 OR p.mismatch_count<>0 OR p.certification_status<>'PASS'
                 OR p.source_registry_row_hash !~ '^[0-9a-f]{32}$'
                 OR p.row_hash IS DISTINCT FROM md5((to_jsonb(p)-'row_hash'-'created_at')::text)
               )::bigint AS mismatch_rows
        FROM a FULL JOIN p
          ON p.node_sequence=a.node_sequence
         AND p.evidence_family_sequence=a.evidence_family_sequence
         AND p.evidence_family_code=a.evidence_family_code
    )
    SELECT concat_ws('|',(SELECT count(*) FROM a),(SELECT count(*) FROM p),(SELECT mismatch_rows FROM cmp)) AS observed_value,
           '6|6|0'::text AS expected_value,
           ((SELECT (count(*)<>6)::integer FROM a)+(SELECT (count(*)<>6)::integer FROM p)+(SELECT mismatch_rows FROM cmp))::bigint AS mismatch_count,
           ((SELECT count(*)=6 FROM a) AND (SELECT count(*)=6 FROM p) AND (SELECT mismatch_rows=0 FROM cmp)) AS pass_flag,
           'Node M2_1_ELIGIBILITY_ROUTING independently reconciles all six mandatory evidence families to persisted PASS state.'::text AS interpretation
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_063_NODE_03_M2_2_PRICING_STRUCTURE_EVIDENCE_MATRIX */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    63::smallint,
    'M2_12_POS_063_NODE_03_M2_2_PRICING_STRUCTURE_EVIDENCE_MATRIX'::text,
    4::smallint,
    'EVIDENCE_CERTIFICATION'::text,
    'Node 03 M2_2_PRICING_STRUCTURE has the complete frozen six-family evidence-certification matrix'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH a AS (
        SELECT * FROM tmp_src_m2_12_evidence_authority WHERE node_sequence=3
    ), p AS (
        SELECT e.* FROM msbf_m2.module2_evidence_certification_snapshot e
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=e.module1_run_id
        WHERE e.node_sequence=3
    ), cmp AS (
        SELECT count(*)::bigint AS joined_rows,
               count(*) FILTER (WHERE a.matrix_sequence IS NULL OR p.module1_run_id IS NULL
                 OR p.stage_code IS DISTINCT FROM a.stage_code
                 OR p.evidence_family_sequence IS DISTINCT FROM a.evidence_family_sequence
                 OR p.evidence_family_code IS DISTINCT FROM a.evidence_family_code
                 OR p.applicability_code IS DISTINCT FROM a.applicability_code
                 OR p.allowed_certification_status IS DISTINCT FROM a.allowed_certification_status
                 OR p.authoritative_source_locator IS DISTINCT FROM a.authoritative_source_locator
                 OR p.evidence_code_or_method_pattern IS DISTINCT FROM a.evidence_code_or_method_pattern
                 OR p.expected_count_or_identity IS DISTINCT FROM a.expected_count_or_identity
                 OR p.expected_status IS DISTINCT FROM a.expected_status
                 OR coalesce(p.expected_hash,'') IS DISTINCT FROM coalesce(a.expected_hash,'')
                 OR p.observed_status IS DISTINCT FROM 'PASS'
                 OR p.mismatch_count<>0 OR p.certification_status<>'PASS'
                 OR p.source_registry_row_hash !~ '^[0-9a-f]{32}$'
                 OR p.row_hash IS DISTINCT FROM md5((to_jsonb(p)-'row_hash'-'created_at')::text)
               )::bigint AS mismatch_rows
        FROM a FULL JOIN p
          ON p.node_sequence=a.node_sequence
         AND p.evidence_family_sequence=a.evidence_family_sequence
         AND p.evidence_family_code=a.evidence_family_code
    )
    SELECT concat_ws('|',(SELECT count(*) FROM a),(SELECT count(*) FROM p),(SELECT mismatch_rows FROM cmp)) AS observed_value,
           '6|6|0'::text AS expected_value,
           ((SELECT (count(*)<>6)::integer FROM a)+(SELECT (count(*)<>6)::integer FROM p)+(SELECT mismatch_rows FROM cmp))::bigint AS mismatch_count,
           ((SELECT count(*)=6 FROM a) AND (SELECT count(*)=6 FROM p) AND (SELECT mismatch_rows=0 FROM cmp)) AS pass_flag,
           'Node M2_2_PRICING_STRUCTURE independently reconciles all six mandatory evidence families to persisted PASS state.'::text AS interpretation
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_064_NODE_04_M2_3_FINAL_DECISION_EVIDENCE_MATRIX */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    64::smallint,
    'M2_12_POS_064_NODE_04_M2_3_FINAL_DECISION_EVIDENCE_MATRIX'::text,
    4::smallint,
    'EVIDENCE_CERTIFICATION'::text,
    'Node 04 M2_3_FINAL_DECISION has the complete frozen six-family evidence-certification matrix'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH a AS (
        SELECT * FROM tmp_src_m2_12_evidence_authority WHERE node_sequence=4
    ), p AS (
        SELECT e.* FROM msbf_m2.module2_evidence_certification_snapshot e
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=e.module1_run_id
        WHERE e.node_sequence=4
    ), cmp AS (
        SELECT count(*)::bigint AS joined_rows,
               count(*) FILTER (WHERE a.matrix_sequence IS NULL OR p.module1_run_id IS NULL
                 OR p.stage_code IS DISTINCT FROM a.stage_code
                 OR p.evidence_family_sequence IS DISTINCT FROM a.evidence_family_sequence
                 OR p.evidence_family_code IS DISTINCT FROM a.evidence_family_code
                 OR p.applicability_code IS DISTINCT FROM a.applicability_code
                 OR p.allowed_certification_status IS DISTINCT FROM a.allowed_certification_status
                 OR p.authoritative_source_locator IS DISTINCT FROM a.authoritative_source_locator
                 OR p.evidence_code_or_method_pattern IS DISTINCT FROM a.evidence_code_or_method_pattern
                 OR p.expected_count_or_identity IS DISTINCT FROM a.expected_count_or_identity
                 OR p.expected_status IS DISTINCT FROM a.expected_status
                 OR coalesce(p.expected_hash,'') IS DISTINCT FROM coalesce(a.expected_hash,'')
                 OR p.observed_status IS DISTINCT FROM 'PASS'
                 OR p.mismatch_count<>0 OR p.certification_status<>'PASS'
                 OR p.source_registry_row_hash !~ '^[0-9a-f]{32}$'
                 OR p.row_hash IS DISTINCT FROM md5((to_jsonb(p)-'row_hash'-'created_at')::text)
               )::bigint AS mismatch_rows
        FROM a FULL JOIN p
          ON p.node_sequence=a.node_sequence
         AND p.evidence_family_sequence=a.evidence_family_sequence
         AND p.evidence_family_code=a.evidence_family_code
    )
    SELECT concat_ws('|',(SELECT count(*) FROM a),(SELECT count(*) FROM p),(SELECT mismatch_rows FROM cmp)) AS observed_value,
           '6|6|0'::text AS expected_value,
           ((SELECT (count(*)<>6)::integer FROM a)+(SELECT (count(*)<>6)::integer FROM p)+(SELECT mismatch_rows FROM cmp))::bigint AS mismatch_count,
           ((SELECT count(*)=6 FROM a) AND (SELECT count(*)=6 FROM p) AND (SELECT mismatch_rows=0 FROM cmp)) AS pass_flag,
           'Node M2_3_FINAL_DECISION independently reconciles all six mandatory evidence families to persisted PASS state.'::text AS interpretation
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_065_NODE_05_M2_4_PORTFOLIO_ACTIVATION_EVIDENCE_MATRIX */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    65::smallint,
    'M2_12_POS_065_NODE_05_M2_4_PORTFOLIO_ACTIVATION_EVIDENCE_MATRIX'::text,
    4::smallint,
    'EVIDENCE_CERTIFICATION'::text,
    'Node 05 M2_4_PORTFOLIO_ACTIVATION has the complete frozen six-family evidence-certification matrix'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH a AS (
        SELECT * FROM tmp_src_m2_12_evidence_authority WHERE node_sequence=5
    ), p AS (
        SELECT e.* FROM msbf_m2.module2_evidence_certification_snapshot e
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=e.module1_run_id
        WHERE e.node_sequence=5
    ), cmp AS (
        SELECT count(*)::bigint AS joined_rows,
               count(*) FILTER (WHERE a.matrix_sequence IS NULL OR p.module1_run_id IS NULL
                 OR p.stage_code IS DISTINCT FROM a.stage_code
                 OR p.evidence_family_sequence IS DISTINCT FROM a.evidence_family_sequence
                 OR p.evidence_family_code IS DISTINCT FROM a.evidence_family_code
                 OR p.applicability_code IS DISTINCT FROM a.applicability_code
                 OR p.allowed_certification_status IS DISTINCT FROM a.allowed_certification_status
                 OR p.authoritative_source_locator IS DISTINCT FROM a.authoritative_source_locator
                 OR p.evidence_code_or_method_pattern IS DISTINCT FROM a.evidence_code_or_method_pattern
                 OR p.expected_count_or_identity IS DISTINCT FROM a.expected_count_or_identity
                 OR p.expected_status IS DISTINCT FROM a.expected_status
                 OR coalesce(p.expected_hash,'') IS DISTINCT FROM coalesce(a.expected_hash,'')
                 OR p.observed_status IS DISTINCT FROM 'PASS'
                 OR p.mismatch_count<>0 OR p.certification_status<>'PASS'
                 OR p.source_registry_row_hash !~ '^[0-9a-f]{32}$'
                 OR p.row_hash IS DISTINCT FROM md5((to_jsonb(p)-'row_hash'-'created_at')::text)
               )::bigint AS mismatch_rows
        FROM a FULL JOIN p
          ON p.node_sequence=a.node_sequence
         AND p.evidence_family_sequence=a.evidence_family_sequence
         AND p.evidence_family_code=a.evidence_family_code
    )
    SELECT concat_ws('|',(SELECT count(*) FROM a),(SELECT count(*) FROM p),(SELECT mismatch_rows FROM cmp)) AS observed_value,
           '6|6|0'::text AS expected_value,
           ((SELECT (count(*)<>6)::integer FROM a)+(SELECT (count(*)<>6)::integer FROM p)+(SELECT mismatch_rows FROM cmp))::bigint AS mismatch_count,
           ((SELECT count(*)=6 FROM a) AND (SELECT count(*)=6 FROM p) AND (SELECT mismatch_rows=0 FROM cmp)) AS pass_flag,
           'Node M2_4_PORTFOLIO_ACTIVATION independently reconciles all six mandatory evidence families to persisted PASS state.'::text AS interpretation
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_066_NODE_06_M2_5_DAILY_MONITORING_EVIDENCE_MATRIX */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    66::smallint,
    'M2_12_POS_066_NODE_06_M2_5_DAILY_MONITORING_EVIDENCE_MATRIX'::text,
    4::smallint,
    'EVIDENCE_CERTIFICATION'::text,
    'Node 06 M2_5_DAILY_MONITORING has the complete frozen six-family evidence-certification matrix'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH a AS (
        SELECT * FROM tmp_src_m2_12_evidence_authority WHERE node_sequence=6
    ), p AS (
        SELECT e.* FROM msbf_m2.module2_evidence_certification_snapshot e
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=e.module1_run_id
        WHERE e.node_sequence=6
    ), cmp AS (
        SELECT count(*)::bigint AS joined_rows,
               count(*) FILTER (WHERE a.matrix_sequence IS NULL OR p.module1_run_id IS NULL
                 OR p.stage_code IS DISTINCT FROM a.stage_code
                 OR p.evidence_family_sequence IS DISTINCT FROM a.evidence_family_sequence
                 OR p.evidence_family_code IS DISTINCT FROM a.evidence_family_code
                 OR p.applicability_code IS DISTINCT FROM a.applicability_code
                 OR p.allowed_certification_status IS DISTINCT FROM a.allowed_certification_status
                 OR p.authoritative_source_locator IS DISTINCT FROM a.authoritative_source_locator
                 OR p.evidence_code_or_method_pattern IS DISTINCT FROM a.evidence_code_or_method_pattern
                 OR p.expected_count_or_identity IS DISTINCT FROM a.expected_count_or_identity
                 OR p.expected_status IS DISTINCT FROM a.expected_status
                 OR coalesce(p.expected_hash,'') IS DISTINCT FROM coalesce(a.expected_hash,'')
                 OR p.observed_status IS DISTINCT FROM 'PASS'
                 OR p.mismatch_count<>0 OR p.certification_status<>'PASS'
                 OR p.source_registry_row_hash !~ '^[0-9a-f]{32}$'
                 OR p.row_hash IS DISTINCT FROM md5((to_jsonb(p)-'row_hash'-'created_at')::text)
               )::bigint AS mismatch_rows
        FROM a FULL JOIN p
          ON p.node_sequence=a.node_sequence
         AND p.evidence_family_sequence=a.evidence_family_sequence
         AND p.evidence_family_code=a.evidence_family_code
    )
    SELECT concat_ws('|',(SELECT count(*) FROM a),(SELECT count(*) FROM p),(SELECT mismatch_rows FROM cmp)) AS observed_value,
           '6|6|0'::text AS expected_value,
           ((SELECT (count(*)<>6)::integer FROM a)+(SELECT (count(*)<>6)::integer FROM p)+(SELECT mismatch_rows FROM cmp))::bigint AS mismatch_count,
           ((SELECT count(*)=6 FROM a) AND (SELECT count(*)=6 FROM p) AND (SELECT mismatch_rows=0 FROM cmp)) AS pass_flag,
           'Node M2_5_DAILY_MONITORING independently reconciles all six mandatory evidence families to persisted PASS state.'::text AS interpretation
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_067_NODE_07_M2_6_INTERVENTION_STRATEGY_EVIDENCE_MATRIX */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    67::smallint,
    'M2_12_POS_067_NODE_07_M2_6_INTERVENTION_STRATEGY_EVIDENCE_MATRIX'::text,
    4::smallint,
    'EVIDENCE_CERTIFICATION'::text,
    'Node 07 M2_6_INTERVENTION_STRATEGY has the complete frozen six-family evidence-certification matrix'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH a AS (
        SELECT * FROM tmp_src_m2_12_evidence_authority WHERE node_sequence=7
    ), p AS (
        SELECT e.* FROM msbf_m2.module2_evidence_certification_snapshot e
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=e.module1_run_id
        WHERE e.node_sequence=7
    ), cmp AS (
        SELECT count(*)::bigint AS joined_rows,
               count(*) FILTER (WHERE a.matrix_sequence IS NULL OR p.module1_run_id IS NULL
                 OR p.stage_code IS DISTINCT FROM a.stage_code
                 OR p.evidence_family_sequence IS DISTINCT FROM a.evidence_family_sequence
                 OR p.evidence_family_code IS DISTINCT FROM a.evidence_family_code
                 OR p.applicability_code IS DISTINCT FROM a.applicability_code
                 OR p.allowed_certification_status IS DISTINCT FROM a.allowed_certification_status
                 OR p.authoritative_source_locator IS DISTINCT FROM a.authoritative_source_locator
                 OR p.evidence_code_or_method_pattern IS DISTINCT FROM a.evidence_code_or_method_pattern
                 OR p.expected_count_or_identity IS DISTINCT FROM a.expected_count_or_identity
                 OR p.expected_status IS DISTINCT FROM a.expected_status
                 OR coalesce(p.expected_hash,'') IS DISTINCT FROM coalesce(a.expected_hash,'')
                 OR p.observed_status IS DISTINCT FROM 'PASS'
                 OR p.mismatch_count<>0 OR p.certification_status<>'PASS'
                 OR p.source_registry_row_hash !~ '^[0-9a-f]{32}$'
                 OR p.row_hash IS DISTINCT FROM md5((to_jsonb(p)-'row_hash'-'created_at')::text)
               )::bigint AS mismatch_rows
        FROM a FULL JOIN p
          ON p.node_sequence=a.node_sequence
         AND p.evidence_family_sequence=a.evidence_family_sequence
         AND p.evidence_family_code=a.evidence_family_code
    )
    SELECT concat_ws('|',(SELECT count(*) FROM a),(SELECT count(*) FROM p),(SELECT mismatch_rows FROM cmp)) AS observed_value,
           '6|6|0'::text AS expected_value,
           ((SELECT (count(*)<>6)::integer FROM a)+(SELECT (count(*)<>6)::integer FROM p)+(SELECT mismatch_rows FROM cmp))::bigint AS mismatch_count,
           ((SELECT count(*)=6 FROM a) AND (SELECT count(*)=6 FROM p) AND (SELECT mismatch_rows=0 FROM cmp)) AS pass_flag,
           'Node M2_6_INTERVENTION_STRATEGY independently reconciles all six mandatory evidence families to persisted PASS state.'::text AS interpretation
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_068_NODE_08_M2_7_OPERATIONAL_ACTIVATION_EVIDENCE_MATRIX */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    68::smallint,
    'M2_12_POS_068_NODE_08_M2_7_OPERATIONAL_ACTIVATION_EVIDENCE_MATRIX'::text,
    4::smallint,
    'EVIDENCE_CERTIFICATION'::text,
    'Node 08 M2_7_OPERATIONAL_ACTIVATION has the complete frozen six-family evidence-certification matrix'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH a AS (
        SELECT * FROM tmp_src_m2_12_evidence_authority WHERE node_sequence=8
    ), p AS (
        SELECT e.* FROM msbf_m2.module2_evidence_certification_snapshot e
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=e.module1_run_id
        WHERE e.node_sequence=8
    ), cmp AS (
        SELECT count(*)::bigint AS joined_rows,
               count(*) FILTER (WHERE a.matrix_sequence IS NULL OR p.module1_run_id IS NULL
                 OR p.stage_code IS DISTINCT FROM a.stage_code
                 OR p.evidence_family_sequence IS DISTINCT FROM a.evidence_family_sequence
                 OR p.evidence_family_code IS DISTINCT FROM a.evidence_family_code
                 OR p.applicability_code IS DISTINCT FROM a.applicability_code
                 OR p.allowed_certification_status IS DISTINCT FROM a.allowed_certification_status
                 OR p.authoritative_source_locator IS DISTINCT FROM a.authoritative_source_locator
                 OR p.evidence_code_or_method_pattern IS DISTINCT FROM a.evidence_code_or_method_pattern
                 OR p.expected_count_or_identity IS DISTINCT FROM a.expected_count_or_identity
                 OR p.expected_status IS DISTINCT FROM a.expected_status
                 OR coalesce(p.expected_hash,'') IS DISTINCT FROM coalesce(a.expected_hash,'')
                 OR p.observed_status IS DISTINCT FROM 'PASS'
                 OR p.mismatch_count<>0 OR p.certification_status<>'PASS'
                 OR p.source_registry_row_hash !~ '^[0-9a-f]{32}$'
                 OR p.row_hash IS DISTINCT FROM md5((to_jsonb(p)-'row_hash'-'created_at')::text)
               )::bigint AS mismatch_rows
        FROM a FULL JOIN p
          ON p.node_sequence=a.node_sequence
         AND p.evidence_family_sequence=a.evidence_family_sequence
         AND p.evidence_family_code=a.evidence_family_code
    )
    SELECT concat_ws('|',(SELECT count(*) FROM a),(SELECT count(*) FROM p),(SELECT mismatch_rows FROM cmp)) AS observed_value,
           '6|6|0'::text AS expected_value,
           ((SELECT (count(*)<>6)::integer FROM a)+(SELECT (count(*)<>6)::integer FROM p)+(SELECT mismatch_rows FROM cmp))::bigint AS mismatch_count,
           ((SELECT count(*)=6 FROM a) AND (SELECT count(*)=6 FROM p) AND (SELECT mismatch_rows=0 FROM cmp)) AS pass_flag,
           'Node M2_7_OPERATIONAL_ACTIVATION independently reconciles all six mandatory evidence families to persisted PASS state.'::text AS interpretation
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_069_NODE_09_M2_8_SERVICING_EXECUTION_EVIDENCE_MATRIX */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    69::smallint,
    'M2_12_POS_069_NODE_09_M2_8_SERVICING_EXECUTION_EVIDENCE_MATRIX'::text,
    4::smallint,
    'EVIDENCE_CERTIFICATION'::text,
    'Node 09 M2_8_SERVICING_EXECUTION has the complete frozen six-family evidence-certification matrix'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH a AS (
        SELECT * FROM tmp_src_m2_12_evidence_authority WHERE node_sequence=9
    ), p AS (
        SELECT e.* FROM msbf_m2.module2_evidence_certification_snapshot e
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=e.module1_run_id
        WHERE e.node_sequence=9
    ), cmp AS (
        SELECT count(*)::bigint AS joined_rows,
               count(*) FILTER (WHERE a.matrix_sequence IS NULL OR p.module1_run_id IS NULL
                 OR p.stage_code IS DISTINCT FROM a.stage_code
                 OR p.evidence_family_sequence IS DISTINCT FROM a.evidence_family_sequence
                 OR p.evidence_family_code IS DISTINCT FROM a.evidence_family_code
                 OR p.applicability_code IS DISTINCT FROM a.applicability_code
                 OR p.allowed_certification_status IS DISTINCT FROM a.allowed_certification_status
                 OR p.authoritative_source_locator IS DISTINCT FROM a.authoritative_source_locator
                 OR p.evidence_code_or_method_pattern IS DISTINCT FROM a.evidence_code_or_method_pattern
                 OR p.expected_count_or_identity IS DISTINCT FROM a.expected_count_or_identity
                 OR p.expected_status IS DISTINCT FROM a.expected_status
                 OR coalesce(p.expected_hash,'') IS DISTINCT FROM coalesce(a.expected_hash,'')
                 OR p.observed_status IS DISTINCT FROM 'PASS'
                 OR p.mismatch_count<>0 OR p.certification_status<>'PASS'
                 OR p.source_registry_row_hash !~ '^[0-9a-f]{32}$'
                 OR p.row_hash IS DISTINCT FROM md5((to_jsonb(p)-'row_hash'-'created_at')::text)
               )::bigint AS mismatch_rows
        FROM a FULL JOIN p
          ON p.node_sequence=a.node_sequence
         AND p.evidence_family_sequence=a.evidence_family_sequence
         AND p.evidence_family_code=a.evidence_family_code
    )
    SELECT concat_ws('|',(SELECT count(*) FROM a),(SELECT count(*) FROM p),(SELECT mismatch_rows FROM cmp)) AS observed_value,
           '6|6|0'::text AS expected_value,
           ((SELECT (count(*)<>6)::integer FROM a)+(SELECT (count(*)<>6)::integer FROM p)+(SELECT mismatch_rows FROM cmp))::bigint AS mismatch_count,
           ((SELECT count(*)=6 FROM a) AND (SELECT count(*)=6 FROM p) AND (SELECT mismatch_rows=0 FROM cmp)) AS pass_flag,
           'Node M2_8_SERVICING_EXECUTION independently reconciles all six mandatory evidence families to persisted PASS state.'::text AS interpretation
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_070_NODE_10_M2_9_RECONCILIATION_CERTIFICATION_EVIDENCE_MATRIX */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    70::smallint,
    'M2_12_POS_070_NODE_10_M2_9_RECONCILIATION_CERTIFICATION_EVIDENCE_MATRIX'::text,
    4::smallint,
    'EVIDENCE_CERTIFICATION'::text,
    'Node 10 M2_9_RECONCILIATION_CERTIFICATION has the complete frozen six-family evidence-certification matrix'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH a AS (
        SELECT * FROM tmp_src_m2_12_evidence_authority WHERE node_sequence=10
    ), p AS (
        SELECT e.* FROM msbf_m2.module2_evidence_certification_snapshot e
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=e.module1_run_id
        WHERE e.node_sequence=10
    ), cmp AS (
        SELECT count(*)::bigint AS joined_rows,
               count(*) FILTER (WHERE a.matrix_sequence IS NULL OR p.module1_run_id IS NULL
                 OR p.stage_code IS DISTINCT FROM a.stage_code
                 OR p.evidence_family_sequence IS DISTINCT FROM a.evidence_family_sequence
                 OR p.evidence_family_code IS DISTINCT FROM a.evidence_family_code
                 OR p.applicability_code IS DISTINCT FROM a.applicability_code
                 OR p.allowed_certification_status IS DISTINCT FROM a.allowed_certification_status
                 OR p.authoritative_source_locator IS DISTINCT FROM a.authoritative_source_locator
                 OR p.evidence_code_or_method_pattern IS DISTINCT FROM a.evidence_code_or_method_pattern
                 OR p.expected_count_or_identity IS DISTINCT FROM a.expected_count_or_identity
                 OR p.expected_status IS DISTINCT FROM a.expected_status
                 OR coalesce(p.expected_hash,'') IS DISTINCT FROM coalesce(a.expected_hash,'')
                 OR p.observed_status IS DISTINCT FROM 'PASS'
                 OR p.mismatch_count<>0 OR p.certification_status<>'PASS'
                 OR p.source_registry_row_hash !~ '^[0-9a-f]{32}$'
                 OR p.row_hash IS DISTINCT FROM md5((to_jsonb(p)-'row_hash'-'created_at')::text)
               )::bigint AS mismatch_rows
        FROM a FULL JOIN p
          ON p.node_sequence=a.node_sequence
         AND p.evidence_family_sequence=a.evidence_family_sequence
         AND p.evidence_family_code=a.evidence_family_code
    )
    SELECT concat_ws('|',(SELECT count(*) FROM a),(SELECT count(*) FROM p),(SELECT mismatch_rows FROM cmp)) AS observed_value,
           '6|6|0'::text AS expected_value,
           ((SELECT (count(*)<>6)::integer FROM a)+(SELECT (count(*)<>6)::integer FROM p)+(SELECT mismatch_rows FROM cmp))::bigint AS mismatch_count,
           ((SELECT count(*)=6 FROM a) AND (SELECT count(*)=6 FROM p) AND (SELECT mismatch_rows=0 FROM cmp)) AS pass_flag,
           'Node M2_9_RECONCILIATION_CERTIFICATION independently reconciles all six mandatory evidence families to persisted PASS state.'::text AS interpretation
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_071_NODE_11_M2_10_PORTFOLIO_ANALYTICS_EVIDENCE_MATRIX */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    71::smallint,
    'M2_12_POS_071_NODE_11_M2_10_PORTFOLIO_ANALYTICS_EVIDENCE_MATRIX'::text,
    4::smallint,
    'EVIDENCE_CERTIFICATION'::text,
    'Node 11 M2_10_PORTFOLIO_ANALYTICS has the complete frozen six-family evidence-certification matrix'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH a AS (
        SELECT * FROM tmp_src_m2_12_evidence_authority WHERE node_sequence=11
    ), p AS (
        SELECT e.* FROM msbf_m2.module2_evidence_certification_snapshot e
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=e.module1_run_id
        WHERE e.node_sequence=11
    ), cmp AS (
        SELECT count(*)::bigint AS joined_rows,
               count(*) FILTER (WHERE a.matrix_sequence IS NULL OR p.module1_run_id IS NULL
                 OR p.stage_code IS DISTINCT FROM a.stage_code
                 OR p.evidence_family_sequence IS DISTINCT FROM a.evidence_family_sequence
                 OR p.evidence_family_code IS DISTINCT FROM a.evidence_family_code
                 OR p.applicability_code IS DISTINCT FROM a.applicability_code
                 OR p.allowed_certification_status IS DISTINCT FROM a.allowed_certification_status
                 OR p.authoritative_source_locator IS DISTINCT FROM a.authoritative_source_locator
                 OR p.evidence_code_or_method_pattern IS DISTINCT FROM a.evidence_code_or_method_pattern
                 OR p.expected_count_or_identity IS DISTINCT FROM a.expected_count_or_identity
                 OR p.expected_status IS DISTINCT FROM a.expected_status
                 OR coalesce(p.expected_hash,'') IS DISTINCT FROM coalesce(a.expected_hash,'')
                 OR p.observed_status IS DISTINCT FROM 'PASS'
                 OR p.mismatch_count<>0 OR p.certification_status<>'PASS'
                 OR p.source_registry_row_hash !~ '^[0-9a-f]{32}$'
                 OR p.row_hash IS DISTINCT FROM md5((to_jsonb(p)-'row_hash'-'created_at')::text)
               )::bigint AS mismatch_rows
        FROM a FULL JOIN p
          ON p.node_sequence=a.node_sequence
         AND p.evidence_family_sequence=a.evidence_family_sequence
         AND p.evidence_family_code=a.evidence_family_code
    )
    SELECT concat_ws('|',(SELECT count(*) FROM a),(SELECT count(*) FROM p),(SELECT mismatch_rows FROM cmp)) AS observed_value,
           '6|6|0'::text AS expected_value,
           ((SELECT (count(*)<>6)::integer FROM a)+(SELECT (count(*)<>6)::integer FROM p)+(SELECT mismatch_rows FROM cmp))::bigint AS mismatch_count,
           ((SELECT count(*)=6 FROM a) AND (SELECT count(*)=6 FROM p) AND (SELECT mismatch_rows=0 FROM cmp)) AS pass_flag,
           'Node M2_10_PORTFOLIO_ANALYTICS independently reconciles all six mandatory evidence families to persisted PASS state.'::text AS interpretation
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_072_NODE_12_M2_11_STRATEGY_SIMULATION_EVIDENCE_MATRIX */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    72::smallint,
    'M2_12_POS_072_NODE_12_M2_11_STRATEGY_SIMULATION_EVIDENCE_MATRIX'::text,
    4::smallint,
    'EVIDENCE_CERTIFICATION'::text,
    'Node 12 M2_11_STRATEGY_SIMULATION has the complete frozen six-family evidence-certification matrix'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH a AS (
        SELECT * FROM tmp_src_m2_12_evidence_authority WHERE node_sequence=12
    ), p AS (
        SELECT e.* FROM msbf_m2.module2_evidence_certification_snapshot e
        JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=e.module1_run_id
        WHERE e.node_sequence=12
    ), cmp AS (
        SELECT count(*)::bigint AS joined_rows,
               count(*) FILTER (WHERE a.matrix_sequence IS NULL OR p.module1_run_id IS NULL
                 OR p.stage_code IS DISTINCT FROM a.stage_code
                 OR p.evidence_family_sequence IS DISTINCT FROM a.evidence_family_sequence
                 OR p.evidence_family_code IS DISTINCT FROM a.evidence_family_code
                 OR p.applicability_code IS DISTINCT FROM a.applicability_code
                 OR p.allowed_certification_status IS DISTINCT FROM a.allowed_certification_status
                 OR p.authoritative_source_locator IS DISTINCT FROM a.authoritative_source_locator
                 OR p.evidence_code_or_method_pattern IS DISTINCT FROM a.evidence_code_or_method_pattern
                 OR p.expected_count_or_identity IS DISTINCT FROM a.expected_count_or_identity
                 OR p.expected_status IS DISTINCT FROM a.expected_status
                 OR coalesce(p.expected_hash,'') IS DISTINCT FROM coalesce(a.expected_hash,'')
                 OR p.observed_status IS DISTINCT FROM 'PASS'
                 OR p.mismatch_count<>0 OR p.certification_status<>'PASS'
                 OR p.source_registry_row_hash !~ '^[0-9a-f]{32}$'
                 OR p.row_hash IS DISTINCT FROM md5((to_jsonb(p)-'row_hash'-'created_at')::text)
               )::bigint AS mismatch_rows
        FROM a FULL JOIN p
          ON p.node_sequence=a.node_sequence
         AND p.evidence_family_sequence=a.evidence_family_sequence
         AND p.evidence_family_code=a.evidence_family_code
    )
    SELECT concat_ws('|',(SELECT count(*) FROM a),(SELECT count(*) FROM p),(SELECT mismatch_rows FROM cmp)) AS observed_value,
           '6|6|0'::text AS expected_value,
           ((SELECT (count(*)<>6)::integer FROM a)+(SELECT (count(*)<>6)::integer FROM p)+(SELECT mismatch_rows FROM cmp))::bigint AS mismatch_count,
           ((SELECT count(*)=6 FROM a) AND (SELECT count(*)=6 FROM p) AND (SELECT mismatch_rows=0 FROM cmp)) AS pass_flag,
           'Node M2_11_STRATEGY_SIMULATION independently reconciles all six mandatory evidence families to persisted PASS state.'::text AS interpretation
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_073_COMPONENT_01_M1_G2_CONSUMPTION_BUNDLE_PHYSICAL_REPRODUCTION */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    73::smallint,
    'M2_12_POS_073_COMPONENT_01_M1_G2_CONSUMPTION_BUNDLE_PHYSICAL_REPRODUCTION'::text,
    5::smallint,
    'LATEST_ARCHIVE_REPRODUCTION'::text,
    'Component 01 M1_G2_CONSUMPTION_BUNDLE latest/archive state reproduces directly from physical rows'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH ctx AS (
        SELECT module1_run_id FROM tmp_src_m2_12_validation_run_context
    ), cd AS (
        SELECT c.* FROM msbf_m2.module2_contract_component_snapshot c
        JOIN ctx ON ctx.module1_run_id=c.module1_run_id
        WHERE c.component_sequence=1 AND c.component_contract_code='M1_G2_CONSUMPTION_BUNDLE' AND c.contract_version=1
    ), obs AS (
        SELECT
            (SELECT count(*)::bigint FROM msbf_ctl.m1_17_g2_bundle_latest l WHERE l.module1_run_id=ctx.module1_run_id) AS observed_latest_rows,
            (SELECT count(*)::bigint FROM msbf_ctl.m1_17_g2_bundle_archive a WHERE a.module1_run_id=ctx.module1_run_id AND a.bundle_version=cd.contract_version) AS observed_archive_rows,
            (SELECT md5('LATEST|'||l.contract_row_hash) FROM msbf_ctl.m1_17_g2_bundle_latest l WHERE l.module1_run_id=ctx.module1_run_id)::text AS reconstructed_latest_set_hash,
            (SELECT md5('ARCHIVE|'||a.archive_row_hash) FROM msbf_ctl.m1_17_g2_bundle_archive a WHERE a.module1_run_id=ctx.module1_run_id AND a.bundle_version=cd.contract_version)::text AS reconstructed_archive_set_hash,
            (SELECT count(*)::bigint FROM msbf_ctl.m1_17_g2_bundle_latest l FULL JOIN msbf_ctl.m1_17_g2_bundle_archive a ON a.module1_run_id=l.module1_run_id AND a.bundle_code=l.bundle_code AND a.bundle_version=l.bundle_version WHERE coalesce(l.module1_run_id,a.module1_run_id)=ctx.module1_run_id AND l.module1_run_id IS NOT NULL AND a.module1_run_id IS NOT NULL AND (((to_jsonb(l)-ARRAY['contract_row_hash','created_at']::text[]) IS DISTINCT FROM (to_jsonb(a)-ARRAY['g2_bundle_archive_id','source_latest_row_hash','archive_row_hash','archived_at','created_at']::text[])) OR (a.source_latest_row_hash IS DISTINCT FROM l.contract_row_hash) OR (l.contract_row_hash IS DISTINCT FROM msbf_ctl.m1_17_hash_jsonb(jsonb_build_object('module1_run_id',l.module1_run_id,'bundle_code',l.bundle_code,'bundle_version',l.bundle_version,'schema_version',l.schema_version,'methodology_version',l.methodology_version,'source_contract_count',l.source_contract_count,'integrated_consumption_rows',l.integrated_consumption_rows,'hash_chain_rows',l.hash_chain_rows,'evidence_snapshot_rows',l.evidence_snapshot_rows,'hash_chain_set_hash',l.hash_chain_set_hash,'evidence_set_hash',l.evidence_set_hash))) OR (a.archive_row_hash IS DISTINCT FROM msbf_ctl.m1_17_hash_jsonb(jsonb_build_object('module1_run_id',a.module1_run_id,'bundle_code',a.bundle_code,'bundle_version',a.bundle_version,'schema_version',a.schema_version,'methodology_version',a.methodology_version,'source_contract_count',a.source_contract_count,'integrated_consumption_rows',a.integrated_consumption_rows,'hash_chain_rows',a.hash_chain_rows,'evidence_snapshot_rows',a.evidence_snapshot_rows,'hash_chain_set_hash',a.hash_chain_set_hash,'evidence_set_hash',a.evidence_set_hash,'bundle_payload',a.bundle_payload,'source_latest_row_hash',a.source_latest_row_hash)))))::bigint AS payload_mismatch_count,
            (SELECT count(*)::bigint FROM msbf_ctl.m1_17_g2_bundle_latest l FULL JOIN msbf_ctl.m1_17_g2_bundle_archive a ON a.module1_run_id=l.module1_run_id AND a.bundle_code=l.bundle_code AND a.bundle_version=l.bundle_version WHERE coalesce(l.module1_run_id,a.module1_run_id)=ctx.module1_run_id AND l.module1_run_id IS NULL)::bigint AS missing_latest_rows,
            (SELECT count(*)::bigint FROM msbf_ctl.m1_17_g2_bundle_latest l FULL JOIN msbf_ctl.m1_17_g2_bundle_archive a ON a.module1_run_id=l.module1_run_id AND a.bundle_code=l.bundle_code AND a.bundle_version=l.bundle_version WHERE coalesce(l.module1_run_id,a.module1_run_id)=ctx.module1_run_id AND a.module1_run_id IS NULL)::bigint AS missing_archive_rows,
            (SELECT count(*)::bigint FROM (SELECT module1_run_id,count(*) c FROM msbf_ctl.m1_17_g2_bundle_latest WHERE module1_run_id=ctx.module1_run_id GROUP BY module1_run_id HAVING count(*)>1) d)::bigint AS latest_duplicate_key_rows,
            (SELECT count(*)::bigint FROM (SELECT module1_run_id,bundle_code,bundle_version,count(*) c FROM msbf_ctl.m1_17_g2_bundle_archive WHERE module1_run_id=ctx.module1_run_id AND bundle_version=cd.contract_version GROUP BY module1_run_id,bundle_code,bundle_version HAVING count(*)>1) d)::bigint AS archive_duplicate_key_rows,
            CASE WHEN (SELECT count(*) FROM pg_catalog.pg_trigger t WHERE t.tgrelid='msbf_ctl.m1_17_g2_bundle_archive'::regclass AND NOT t.tgisinternal AND t.tgname='trg_m1_17_g2_archive_immutable' AND (t.tgtype & 8)=8 AND (t.tgtype & 16)=16 AND t.tgenabled IN ('O','A'))=1 THEN 'PASS' ELSE 'FAIL' END::text::text AS archive_trigger_status
        FROM ctx CROSS JOIN cd
    ), snap AS (
        SELECT r.* FROM msbf_m2.module2_contract_reproduction_snapshot r
        JOIN ctx ON ctx.module1_run_id=r.module1_run_id
        WHERE r.component_sequence=1 AND r.component_contract_code='M1_G2_CONSUMPTION_BUNDLE' AND r.contract_version=1
    )
    SELECT
        concat_ws('|',(SELECT observed_latest_rows FROM obs),(SELECT observed_archive_rows FROM obs),
          (SELECT reconstructed_latest_set_hash FROM obs),(SELECT reconstructed_archive_set_hash FROM obs),
          (SELECT payload_mismatch_count FROM obs),(SELECT missing_latest_rows FROM obs),(SELECT missing_archive_rows FROM obs),
          (SELECT latest_duplicate_key_rows FROM obs),(SELECT archive_duplicate_key_rows FROM obs),(SELECT archive_trigger_status FROM obs),
          (SELECT count(*) FROM snap),(SELECT min(reproduction_status) FROM snap)) AS observed_value,
        '1|1|64250f8d027ad78650a1bf5ede7da6e5|020a5946318d6d73da58f723349ab18c|0|0|0|0|0|PASS|1|PASS'::text AS expected_value,
        (CASE WHEN (SELECT count(*) FROM cd)=1 AND (SELECT count(*) FROM obs)=1 AND (SELECT count(*) FROM snap)=1
                   AND (SELECT observed_latest_rows=1 AND observed_archive_rows=1
                               AND reconstructed_latest_set_hash='64250f8d027ad78650a1bf5ede7da6e5'
                               AND reconstructed_archive_set_hash='020a5946318d6d73da58f723349ab18c'
                               AND payload_mismatch_count=0 AND missing_latest_rows=0 AND missing_archive_rows=0
                               AND latest_duplicate_key_rows=0 AND archive_duplicate_key_rows=0 AND archive_trigger_status='PASS' FROM obs)
                   AND (SELECT observed_latest_rows=1 AND observed_archive_rows=1
                               AND observed_latest_set_hash='64250f8d027ad78650a1bf5ede7da6e5' AND observed_archive_set_hash='020a5946318d6d73da58f723349ab18c'
                               AND payload_mismatch_count=0 AND missing_latest_rows=0 AND missing_archive_rows=0
                               AND latest_duplicate_key_rows=0 AND archive_duplicate_key_rows=0 AND archive_trigger_status='PASS'
                               AND reproduction_status='PASS' AND source_registry_row_hash='27397e724a7d24a84601d5052f1b0c34'
                               AND row_hash IS NOT DISTINCT FROM md5((to_jsonb(snap)-'row_hash'-'created_at')::text) FROM snap)
              THEN 0 ELSE 1 END)::bigint AS mismatch_count,
        ((SELECT count(*) FROM cd)=1 AND (SELECT count(*) FROM obs)=1 AND (SELECT count(*) FROM snap)=1
         AND (SELECT observed_latest_rows=1 AND observed_archive_rows=1
                     AND reconstructed_latest_set_hash='64250f8d027ad78650a1bf5ede7da6e5'
                     AND reconstructed_archive_set_hash='020a5946318d6d73da58f723349ab18c'
                     AND payload_mismatch_count=0 AND missing_latest_rows=0 AND missing_archive_rows=0
                     AND latest_duplicate_key_rows=0 AND archive_duplicate_key_rows=0 AND archive_trigger_status='PASS' FROM obs)
         AND (SELECT observed_latest_rows=1 AND observed_archive_rows=1
                     AND observed_latest_set_hash='64250f8d027ad78650a1bf5ede7da6e5' AND observed_archive_set_hash='020a5946318d6d73da58f723349ab18c'
                     AND payload_mismatch_count=0 AND missing_latest_rows=0 AND missing_archive_rows=0
                     AND latest_duplicate_key_rows=0 AND archive_duplicate_key_rows=0 AND archive_trigger_status='PASS'
                     AND reproduction_status='PASS' AND source_registry_row_hash='27397e724a7d24a84601d5052f1b0c34'
                     AND row_hash IS NOT DISTINCT FROM md5((to_jsonb(snap)-'row_hash'-'created_at')::text) FROM snap)) AS pass_flag,
        'Direct persisted latest/archive reconstruction for component M1_G2_CONSUMPTION_BUNDLE; no Program 222 transaction-local helper is used.'::text AS interpretation
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_074_COMPONENT_02_M2_ELIGIBILITY_ROUTING_CONSUMPTION_PHYSICAL_REPRODUCTION */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    74::smallint,
    'M2_12_POS_074_COMPONENT_02_M2_ELIGIBILITY_ROUTING_CONSUMPTION_PHYSICAL_REPRODUCTION'::text,
    5::smallint,
    'LATEST_ARCHIVE_REPRODUCTION'::text,
    'Component 02 M2_ELIGIBILITY_ROUTING_CONSUMPTION latest/archive state reproduces directly from physical rows'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH ctx AS (
        SELECT module1_run_id FROM tmp_src_m2_12_validation_run_context
    ), cd AS (
        SELECT c.* FROM msbf_m2.module2_contract_component_snapshot c
        JOIN ctx ON ctx.module1_run_id=c.module1_run_id
        WHERE c.component_sequence=2 AND c.component_contract_code='M2_ELIGIBILITY_ROUTING_CONSUMPTION' AND c.contract_version=1
    ), obs AS (
        SELECT
            (SELECT count(*)::bigint FROM msbf_m2.application_eligibility_routing_latest l WHERE l.module1_run_id=ctx.module1_run_id) AS observed_latest_rows,
            (SELECT count(*)::bigint FROM msbf_m2.application_eligibility_routing_archive a WHERE a.module1_run_id=ctx.module1_run_id AND a.contract_version=cd.contract_version) AS observed_archive_rows,
            (SELECT md5(string_agg(l.contract_row_hash,'|' ORDER BY l.scenario_id,l.merchant_application_id)) FROM msbf_m2.application_eligibility_routing_latest l WHERE l.module1_run_id=ctx.module1_run_id)::text AS reconstructed_latest_set_hash,
            (SELECT md5(string_agg(a.archive_row_hash,'|' ORDER BY a.scenario_id,a.merchant_application_id)) FROM msbf_m2.application_eligibility_routing_archive a WHERE a.module1_run_id=ctx.module1_run_id AND a.contract_version=cd.contract_version)::text AS reconstructed_archive_set_hash,
            (SELECT count(*)::bigint FROM msbf_m2.application_eligibility_routing_latest l FULL JOIN msbf_m2.application_eligibility_routing_archive a ON a.module1_run_id=l.module1_run_id AND a.contract_code=l.contract_code AND a.contract_version=l.contract_version AND a.strategy_campaign_code=l.strategy_campaign_code AND a.scenario_id=l.scenario_id AND a.merchant_application_id=l.merchant_application_id WHERE coalesce(l.module1_run_id,a.module1_run_id)=ctx.module1_run_id AND l.module1_run_id IS NOT NULL AND a.module1_run_id IS NOT NULL AND ((a.contract_payload IS DISTINCT FROM (to_jsonb(l)-'created_at')) OR (a.contract_row_hash IS DISTINCT FROM l.contract_row_hash) OR (a.source_latest_row_hash IS DISTINCT FROM l.contract_row_hash) OR (l.contract_row_hash IS DISTINCT FROM msbf_ctl.m2_1_hash_jsonb(to_jsonb(l)-'contract_row_hash'-'created_at')) OR (a.archive_row_hash IS DISTINCT FROM msbf_ctl.m2_1_hash_jsonb(to_jsonb(a)-'archive_id'-'archive_row_hash'-'archived_at'-'created_at'))))::bigint AS payload_mismatch_count,
            (SELECT count(*)::bigint FROM msbf_m2.application_eligibility_routing_latest l FULL JOIN msbf_m2.application_eligibility_routing_archive a ON a.module1_run_id=l.module1_run_id AND a.contract_code=l.contract_code AND a.contract_version=l.contract_version AND a.strategy_campaign_code=l.strategy_campaign_code AND a.scenario_id=l.scenario_id AND a.merchant_application_id=l.merchant_application_id WHERE coalesce(l.module1_run_id,a.module1_run_id)=ctx.module1_run_id AND l.module1_run_id IS NULL)::bigint AS missing_latest_rows,
            (SELECT count(*)::bigint FROM msbf_m2.application_eligibility_routing_latest l FULL JOIN msbf_m2.application_eligibility_routing_archive a ON a.module1_run_id=l.module1_run_id AND a.contract_code=l.contract_code AND a.contract_version=l.contract_version AND a.strategy_campaign_code=l.strategy_campaign_code AND a.scenario_id=l.scenario_id AND a.merchant_application_id=l.merchant_application_id WHERE coalesce(l.module1_run_id,a.module1_run_id)=ctx.module1_run_id AND a.module1_run_id IS NULL)::bigint AS missing_archive_rows,
            (SELECT count(*)::bigint FROM (SELECT module1_run_id,strategy_campaign_code,scenario_id,merchant_application_id,count(*) c FROM msbf_m2.application_eligibility_routing_latest WHERE module1_run_id=ctx.module1_run_id GROUP BY module1_run_id,strategy_campaign_code,scenario_id,merchant_application_id HAVING count(*)>1) d)::bigint AS latest_duplicate_key_rows,
            (SELECT count(*)::bigint FROM (SELECT module1_run_id,contract_code,contract_version,strategy_campaign_code,scenario_id,merchant_application_id,count(*) c FROM msbf_m2.application_eligibility_routing_archive WHERE module1_run_id=ctx.module1_run_id AND contract_version=cd.contract_version GROUP BY module1_run_id,contract_code,contract_version,strategy_campaign_code,scenario_id,merchant_application_id HAVING count(*)>1) d)::bigint AS archive_duplicate_key_rows,
            CASE WHEN (SELECT count(*) FROM pg_catalog.pg_trigger t WHERE t.tgrelid='msbf_m2.application_eligibility_routing_archive'::regclass AND NOT t.tgisinternal AND t.tgname='trg_m2_1_archive_immutable' AND (t.tgtype & 8)=8 AND (t.tgtype & 16)=16 AND t.tgenabled IN ('O','A'))=1 THEN 'PASS' ELSE 'FAIL' END::text::text AS archive_trigger_status
        FROM ctx CROSS JOIN cd
    ), snap AS (
        SELECT r.* FROM msbf_m2.module2_contract_reproduction_snapshot r
        JOIN ctx ON ctx.module1_run_id=r.module1_run_id
        WHERE r.component_sequence=2 AND r.component_contract_code='M2_ELIGIBILITY_ROUTING_CONSUMPTION' AND r.contract_version=1
    )
    SELECT
        concat_ws('|',(SELECT observed_latest_rows FROM obs),(SELECT observed_archive_rows FROM obs),
          (SELECT reconstructed_latest_set_hash FROM obs),(SELECT reconstructed_archive_set_hash FROM obs),
          (SELECT payload_mismatch_count FROM obs),(SELECT missing_latest_rows FROM obs),(SELECT missing_archive_rows FROM obs),
          (SELECT latest_duplicate_key_rows FROM obs),(SELECT archive_duplicate_key_rows FROM obs),(SELECT archive_trigger_status FROM obs),
          (SELECT count(*) FROM snap),(SELECT min(reproduction_status) FROM snap)) AS observed_value,
        '1500|1500|f813d2d8bfa4609f83b2bfd181de3e17|13d7db24aa254d8efe69b28998d91fd4|0|0|0|0|0|PASS|1|PASS'::text AS expected_value,
        (CASE WHEN (SELECT count(*) FROM cd)=1 AND (SELECT count(*) FROM obs)=1 AND (SELECT count(*) FROM snap)=1
                   AND (SELECT observed_latest_rows=1500 AND observed_archive_rows=1500
                               AND reconstructed_latest_set_hash='f813d2d8bfa4609f83b2bfd181de3e17'
                               AND reconstructed_archive_set_hash='13d7db24aa254d8efe69b28998d91fd4'
                               AND payload_mismatch_count=0 AND missing_latest_rows=0 AND missing_archive_rows=0
                               AND latest_duplicate_key_rows=0 AND archive_duplicate_key_rows=0 AND archive_trigger_status='PASS' FROM obs)
                   AND (SELECT observed_latest_rows=1500 AND observed_archive_rows=1500
                               AND observed_latest_set_hash='f813d2d8bfa4609f83b2bfd181de3e17' AND observed_archive_set_hash='13d7db24aa254d8efe69b28998d91fd4'
                               AND payload_mismatch_count=0 AND missing_latest_rows=0 AND missing_archive_rows=0
                               AND latest_duplicate_key_rows=0 AND archive_duplicate_key_rows=0 AND archive_trigger_status='PASS'
                               AND reproduction_status='PASS' AND source_registry_row_hash='e3fe1ae397c76da8f6ba88649935cfa7'
                               AND row_hash IS NOT DISTINCT FROM md5((to_jsonb(snap)-'row_hash'-'created_at')::text) FROM snap)
              THEN 0 ELSE 1 END)::bigint AS mismatch_count,
        ((SELECT count(*) FROM cd)=1 AND (SELECT count(*) FROM obs)=1 AND (SELECT count(*) FROM snap)=1
         AND (SELECT observed_latest_rows=1500 AND observed_archive_rows=1500
                     AND reconstructed_latest_set_hash='f813d2d8bfa4609f83b2bfd181de3e17'
                     AND reconstructed_archive_set_hash='13d7db24aa254d8efe69b28998d91fd4'
                     AND payload_mismatch_count=0 AND missing_latest_rows=0 AND missing_archive_rows=0
                     AND latest_duplicate_key_rows=0 AND archive_duplicate_key_rows=0 AND archive_trigger_status='PASS' FROM obs)
         AND (SELECT observed_latest_rows=1500 AND observed_archive_rows=1500
                     AND observed_latest_set_hash='f813d2d8bfa4609f83b2bfd181de3e17' AND observed_archive_set_hash='13d7db24aa254d8efe69b28998d91fd4'
                     AND payload_mismatch_count=0 AND missing_latest_rows=0 AND missing_archive_rows=0
                     AND latest_duplicate_key_rows=0 AND archive_duplicate_key_rows=0 AND archive_trigger_status='PASS'
                     AND reproduction_status='PASS' AND source_registry_row_hash='e3fe1ae397c76da8f6ba88649935cfa7'
                     AND row_hash IS NOT DISTINCT FROM md5((to_jsonb(snap)-'row_hash'-'created_at')::text) FROM snap)) AS pass_flag,
        'Direct persisted latest/archive reconstruction for component M2_ELIGIBILITY_ROUTING_CONSUMPTION; no Program 222 transaction-local helper is used.'::text AS interpretation
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_075_COMPONENT_03_M2_REQUEST_STRUCTURE_CONSUMPTION_PHYSICAL_REPRODUCTION */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    75::smallint,
    'M2_12_POS_075_COMPONENT_03_M2_REQUEST_STRUCTURE_CONSUMPTION_PHYSICAL_REPRODUCTION'::text,
    5::smallint,
    'LATEST_ARCHIVE_REPRODUCTION'::text,
    'Component 03 M2_REQUEST_STRUCTURE_CONSUMPTION latest/archive state reproduces directly from physical rows'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH ctx AS (
        SELECT module1_run_id FROM tmp_src_m2_12_validation_run_context
    ), cd AS (
        SELECT c.* FROM msbf_m2.module2_contract_component_snapshot c
        JOIN ctx ON ctx.module1_run_id=c.module1_run_id
        WHERE c.component_sequence=3 AND c.component_contract_code='M2_REQUEST_STRUCTURE_CONSUMPTION' AND c.contract_version=1
    ), obs AS (
        SELECT
            (SELECT count(*)::bigint FROM msbf_m2.application_request_structure_latest l WHERE l.module1_run_id=ctx.module1_run_id) AS observed_latest_rows,
            (SELECT count(*)::bigint FROM msbf_m2.application_request_structure_archive a WHERE a.module1_run_id=ctx.module1_run_id AND a.contract_version=cd.contract_version) AS observed_archive_rows,
            (SELECT md5(string_agg(l.contract_row_hash,'|' ORDER BY l.merchant_application_id)) FROM msbf_m2.application_request_structure_latest l WHERE l.module1_run_id=ctx.module1_run_id)::text AS reconstructed_latest_set_hash,
            (SELECT md5(string_agg(a.archive_row_hash,'|' ORDER BY a.merchant_application_id)) FROM msbf_m2.application_request_structure_archive a WHERE a.module1_run_id=ctx.module1_run_id AND a.contract_version=cd.contract_version)::text AS reconstructed_archive_set_hash,
            (SELECT count(*)::bigint FROM msbf_m2.application_request_structure_latest l FULL JOIN msbf_m2.application_request_structure_archive a ON a.module1_run_id=l.module1_run_id AND a.contract_code=l.contract_code AND a.contract_version=l.contract_version AND a.merchant_application_id=l.merchant_application_id WHERE coalesce(l.module1_run_id,a.module1_run_id)=ctx.module1_run_id AND l.module1_run_id IS NOT NULL AND a.module1_run_id IS NOT NULL AND ((a.contract_payload IS DISTINCT FROM (to_jsonb(l)-'created_at')) OR (a.contract_row_hash IS DISTINCT FROM l.contract_row_hash) OR (a.source_latest_row_hash IS DISTINCT FROM l.contract_row_hash) OR (l.contract_row_hash IS DISTINCT FROM msbf_ctl.m2_2_hash_jsonb(to_jsonb(l)-'contract_row_hash'-'created_at')) OR (a.archive_row_hash IS DISTINCT FROM msbf_ctl.m2_2_hash_jsonb(to_jsonb(a)-'archive_id'-'archive_row_hash'-'archived_at'-'created_at'))))::bigint AS payload_mismatch_count,
            (SELECT count(*)::bigint FROM msbf_m2.application_request_structure_latest l FULL JOIN msbf_m2.application_request_structure_archive a ON a.module1_run_id=l.module1_run_id AND a.contract_code=l.contract_code AND a.contract_version=l.contract_version AND a.merchant_application_id=l.merchant_application_id WHERE coalesce(l.module1_run_id,a.module1_run_id)=ctx.module1_run_id AND l.module1_run_id IS NULL)::bigint AS missing_latest_rows,
            (SELECT count(*)::bigint FROM msbf_m2.application_request_structure_latest l FULL JOIN msbf_m2.application_request_structure_archive a ON a.module1_run_id=l.module1_run_id AND a.contract_code=l.contract_code AND a.contract_version=l.contract_version AND a.merchant_application_id=l.merchant_application_id WHERE coalesce(l.module1_run_id,a.module1_run_id)=ctx.module1_run_id AND a.module1_run_id IS NULL)::bigint AS missing_archive_rows,
            (SELECT count(*)::bigint FROM (SELECT module1_run_id,merchant_application_id,count(*) c FROM msbf_m2.application_request_structure_latest WHERE module1_run_id=ctx.module1_run_id GROUP BY module1_run_id,merchant_application_id HAVING count(*)>1) d)::bigint AS latest_duplicate_key_rows,
            (SELECT count(*)::bigint FROM (SELECT module1_run_id,contract_code,contract_version,merchant_application_id,count(*) c FROM msbf_m2.application_request_structure_archive WHERE module1_run_id=ctx.module1_run_id AND contract_version=cd.contract_version GROUP BY module1_run_id,contract_code,contract_version,merchant_application_id HAVING count(*)>1) d)::bigint AS archive_duplicate_key_rows,
            CASE WHEN (SELECT count(*) FROM pg_catalog.pg_trigger t WHERE t.tgrelid='msbf_m2.application_request_structure_archive'::regclass AND NOT t.tgisinternal AND t.tgname='trg_m2_2_request_archive_immutable' AND (t.tgtype & 8)=8 AND (t.tgtype & 16)=16 AND t.tgenabled IN ('O','A'))=1 THEN 'PASS' ELSE 'FAIL' END::text::text AS archive_trigger_status
        FROM ctx CROSS JOIN cd
    ), snap AS (
        SELECT r.* FROM msbf_m2.module2_contract_reproduction_snapshot r
        JOIN ctx ON ctx.module1_run_id=r.module1_run_id
        WHERE r.component_sequence=3 AND r.component_contract_code='M2_REQUEST_STRUCTURE_CONSUMPTION' AND r.contract_version=1
    )
    SELECT
        concat_ws('|',(SELECT observed_latest_rows FROM obs),(SELECT observed_archive_rows FROM obs),
          (SELECT reconstructed_latest_set_hash FROM obs),(SELECT reconstructed_archive_set_hash FROM obs),
          (SELECT payload_mismatch_count FROM obs),(SELECT missing_latest_rows FROM obs),(SELECT missing_archive_rows FROM obs),
          (SELECT latest_duplicate_key_rows FROM obs),(SELECT archive_duplicate_key_rows FROM obs),(SELECT archive_trigger_status FROM obs),
          (SELECT count(*) FROM snap),(SELECT min(reproduction_status) FROM snap)) AS observed_value,
        '750|750|da27dcb509a8c0bf3bc7a046242a2c02|c397c86ab234243dc11ab84b9e98eb6f|0|0|0|0|0|PASS|1|PASS'::text AS expected_value,
        (CASE WHEN (SELECT count(*) FROM cd)=1 AND (SELECT count(*) FROM obs)=1 AND (SELECT count(*) FROM snap)=1
                   AND (SELECT observed_latest_rows=750 AND observed_archive_rows=750
                               AND reconstructed_latest_set_hash='da27dcb509a8c0bf3bc7a046242a2c02'
                               AND reconstructed_archive_set_hash='c397c86ab234243dc11ab84b9e98eb6f'
                               AND payload_mismatch_count=0 AND missing_latest_rows=0 AND missing_archive_rows=0
                               AND latest_duplicate_key_rows=0 AND archive_duplicate_key_rows=0 AND archive_trigger_status='PASS' FROM obs)
                   AND (SELECT observed_latest_rows=750 AND observed_archive_rows=750
                               AND observed_latest_set_hash='da27dcb509a8c0bf3bc7a046242a2c02' AND observed_archive_set_hash='c397c86ab234243dc11ab84b9e98eb6f'
                               AND payload_mismatch_count=0 AND missing_latest_rows=0 AND missing_archive_rows=0
                               AND latest_duplicate_key_rows=0 AND archive_duplicate_key_rows=0 AND archive_trigger_status='PASS'
                               AND reproduction_status='PASS' AND source_registry_row_hash='32374a67d0f8ead18af4bc18139ffdd6'
                               AND row_hash IS NOT DISTINCT FROM md5((to_jsonb(snap)-'row_hash'-'created_at')::text) FROM snap)
              THEN 0 ELSE 1 END)::bigint AS mismatch_count,
        ((SELECT count(*) FROM cd)=1 AND (SELECT count(*) FROM obs)=1 AND (SELECT count(*) FROM snap)=1
         AND (SELECT observed_latest_rows=750 AND observed_archive_rows=750
                     AND reconstructed_latest_set_hash='da27dcb509a8c0bf3bc7a046242a2c02'
                     AND reconstructed_archive_set_hash='c397c86ab234243dc11ab84b9e98eb6f'
                     AND payload_mismatch_count=0 AND missing_latest_rows=0 AND missing_archive_rows=0
                     AND latest_duplicate_key_rows=0 AND archive_duplicate_key_rows=0 AND archive_trigger_status='PASS' FROM obs)
         AND (SELECT observed_latest_rows=750 AND observed_archive_rows=750
                     AND observed_latest_set_hash='da27dcb509a8c0bf3bc7a046242a2c02' AND observed_archive_set_hash='c397c86ab234243dc11ab84b9e98eb6f'
                     AND payload_mismatch_count=0 AND missing_latest_rows=0 AND missing_archive_rows=0
                     AND latest_duplicate_key_rows=0 AND archive_duplicate_key_rows=0 AND archive_trigger_status='PASS'
                     AND reproduction_status='PASS' AND source_registry_row_hash='32374a67d0f8ead18af4bc18139ffdd6'
                     AND row_hash IS NOT DISTINCT FROM md5((to_jsonb(snap)-'row_hash'-'created_at')::text) FROM snap)) AS pass_flag,
        'Direct persisted latest/archive reconstruction for component M2_REQUEST_STRUCTURE_CONSUMPTION; no Program 222 transaction-local helper is used.'::text AS interpretation
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_076_COMPONENT_04_M2_PRICING_STRUCTURE_CONSUMPTION_PHYSICAL_REPRODUCTION */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    76::smallint,
    'M2_12_POS_076_COMPONENT_04_M2_PRICING_STRUCTURE_CONSUMPTION_PHYSICAL_REPRODUCTION'::text,
    5::smallint,
    'LATEST_ARCHIVE_REPRODUCTION'::text,
    'Component 04 M2_PRICING_STRUCTURE_CONSUMPTION latest/archive state reproduces directly from physical rows'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH ctx AS (
        SELECT module1_run_id FROM tmp_src_m2_12_validation_run_context
    ), cd AS (
        SELECT c.* FROM msbf_m2.module2_contract_component_snapshot c
        JOIN ctx ON ctx.module1_run_id=c.module1_run_id
        WHERE c.component_sequence=4 AND c.component_contract_code='M2_PRICING_STRUCTURE_CONSUMPTION' AND c.contract_version=1
    ), obs AS (
        SELECT
            (SELECT count(*)::bigint FROM msbf_m2.application_pricing_structure_latest l WHERE l.module1_run_id=ctx.module1_run_id) AS observed_latest_rows,
            (SELECT count(*)::bigint FROM msbf_m2.application_pricing_structure_archive a WHERE a.module1_run_id=ctx.module1_run_id AND a.contract_version=cd.contract_version) AS observed_archive_rows,
            (SELECT md5(string_agg(l.contract_row_hash,'|' ORDER BY l.scenario_id,l.merchant_application_id)) FROM msbf_m2.application_pricing_structure_latest l WHERE l.module1_run_id=ctx.module1_run_id)::text AS reconstructed_latest_set_hash,
            (SELECT md5(string_agg(a.archive_row_hash,'|' ORDER BY a.scenario_id,a.merchant_application_id)) FROM msbf_m2.application_pricing_structure_archive a WHERE a.module1_run_id=ctx.module1_run_id AND a.contract_version=cd.contract_version)::text AS reconstructed_archive_set_hash,
            (SELECT count(*)::bigint FROM msbf_m2.application_pricing_structure_latest l FULL JOIN msbf_m2.application_pricing_structure_archive a ON a.module1_run_id=l.module1_run_id AND a.contract_code=l.contract_code AND a.contract_version=l.contract_version AND a.scenario_id=l.scenario_id AND a.merchant_application_id=l.merchant_application_id WHERE coalesce(l.module1_run_id,a.module1_run_id)=ctx.module1_run_id AND l.module1_run_id IS NOT NULL AND a.module1_run_id IS NOT NULL AND ((a.contract_payload IS DISTINCT FROM (to_jsonb(l)-'created_at')) OR (a.contract_row_hash IS DISTINCT FROM l.contract_row_hash) OR (a.source_latest_row_hash IS DISTINCT FROM l.contract_row_hash) OR (l.contract_row_hash IS DISTINCT FROM msbf_ctl.m2_2_hash_jsonb(to_jsonb(l)-'contract_row_hash'-'created_at')) OR (a.archive_row_hash IS DISTINCT FROM msbf_ctl.m2_2_hash_jsonb(to_jsonb(a)-'archive_id'-'archive_row_hash'-'archived_at'-'created_at'))))::bigint AS payload_mismatch_count,
            (SELECT count(*)::bigint FROM msbf_m2.application_pricing_structure_latest l FULL JOIN msbf_m2.application_pricing_structure_archive a ON a.module1_run_id=l.module1_run_id AND a.contract_code=l.contract_code AND a.contract_version=l.contract_version AND a.scenario_id=l.scenario_id AND a.merchant_application_id=l.merchant_application_id WHERE coalesce(l.module1_run_id,a.module1_run_id)=ctx.module1_run_id AND l.module1_run_id IS NULL)::bigint AS missing_latest_rows,
            (SELECT count(*)::bigint FROM msbf_m2.application_pricing_structure_latest l FULL JOIN msbf_m2.application_pricing_structure_archive a ON a.module1_run_id=l.module1_run_id AND a.contract_code=l.contract_code AND a.contract_version=l.contract_version AND a.scenario_id=l.scenario_id AND a.merchant_application_id=l.merchant_application_id WHERE coalesce(l.module1_run_id,a.module1_run_id)=ctx.module1_run_id AND a.module1_run_id IS NULL)::bigint AS missing_archive_rows,
            (SELECT count(*)::bigint FROM (SELECT module1_run_id,scenario_id,merchant_application_id,count(*) c FROM msbf_m2.application_pricing_structure_latest WHERE module1_run_id=ctx.module1_run_id GROUP BY module1_run_id,scenario_id,merchant_application_id HAVING count(*)>1) d)::bigint AS latest_duplicate_key_rows,
            (SELECT count(*)::bigint FROM (SELECT module1_run_id,contract_code,contract_version,scenario_id,merchant_application_id,count(*) c FROM msbf_m2.application_pricing_structure_archive WHERE module1_run_id=ctx.module1_run_id AND contract_version=cd.contract_version GROUP BY module1_run_id,contract_code,contract_version,scenario_id,merchant_application_id HAVING count(*)>1) d)::bigint AS archive_duplicate_key_rows,
            CASE WHEN (SELECT count(*) FROM pg_catalog.pg_trigger t WHERE t.tgrelid='msbf_m2.application_pricing_structure_archive'::regclass AND NOT t.tgisinternal AND t.tgname='trg_m2_2_pricing_archive_immutable' AND (t.tgtype & 8)=8 AND (t.tgtype & 16)=16 AND t.tgenabled IN ('O','A'))=1 THEN 'PASS' ELSE 'FAIL' END::text::text AS archive_trigger_status
        FROM ctx CROSS JOIN cd
    ), snap AS (
        SELECT r.* FROM msbf_m2.module2_contract_reproduction_snapshot r
        JOIN ctx ON ctx.module1_run_id=r.module1_run_id
        WHERE r.component_sequence=4 AND r.component_contract_code='M2_PRICING_STRUCTURE_CONSUMPTION' AND r.contract_version=1
    )
    SELECT
        concat_ws('|',(SELECT observed_latest_rows FROM obs),(SELECT observed_archive_rows FROM obs),
          (SELECT reconstructed_latest_set_hash FROM obs),(SELECT reconstructed_archive_set_hash FROM obs),
          (SELECT payload_mismatch_count FROM obs),(SELECT missing_latest_rows FROM obs),(SELECT missing_archive_rows FROM obs),
          (SELECT latest_duplicate_key_rows FROM obs),(SELECT archive_duplicate_key_rows FROM obs),(SELECT archive_trigger_status FROM obs),
          (SELECT count(*) FROM snap),(SELECT min(reproduction_status) FROM snap)) AS observed_value,
        '1500|1500|a69d1fca447bb573040bf697c43ce1af|9e43326cd8f79b98c19f02f971fb077f|0|0|0|0|0|PASS|1|PASS'::text AS expected_value,
        (CASE WHEN (SELECT count(*) FROM cd)=1 AND (SELECT count(*) FROM obs)=1 AND (SELECT count(*) FROM snap)=1
                   AND (SELECT observed_latest_rows=1500 AND observed_archive_rows=1500
                               AND reconstructed_latest_set_hash='a69d1fca447bb573040bf697c43ce1af'
                               AND reconstructed_archive_set_hash='9e43326cd8f79b98c19f02f971fb077f'
                               AND payload_mismatch_count=0 AND missing_latest_rows=0 AND missing_archive_rows=0
                               AND latest_duplicate_key_rows=0 AND archive_duplicate_key_rows=0 AND archive_trigger_status='PASS' FROM obs)
                   AND (SELECT observed_latest_rows=1500 AND observed_archive_rows=1500
                               AND observed_latest_set_hash='a69d1fca447bb573040bf697c43ce1af' AND observed_archive_set_hash='9e43326cd8f79b98c19f02f971fb077f'
                               AND payload_mismatch_count=0 AND missing_latest_rows=0 AND missing_archive_rows=0
                               AND latest_duplicate_key_rows=0 AND archive_duplicate_key_rows=0 AND archive_trigger_status='PASS'
                               AND reproduction_status='PASS' AND source_registry_row_hash='32374a67d0f8ead18af4bc18139ffdd6'
                               AND row_hash IS NOT DISTINCT FROM md5((to_jsonb(snap)-'row_hash'-'created_at')::text) FROM snap)
              THEN 0 ELSE 1 END)::bigint AS mismatch_count,
        ((SELECT count(*) FROM cd)=1 AND (SELECT count(*) FROM obs)=1 AND (SELECT count(*) FROM snap)=1
         AND (SELECT observed_latest_rows=1500 AND observed_archive_rows=1500
                     AND reconstructed_latest_set_hash='a69d1fca447bb573040bf697c43ce1af'
                     AND reconstructed_archive_set_hash='9e43326cd8f79b98c19f02f971fb077f'
                     AND payload_mismatch_count=0 AND missing_latest_rows=0 AND missing_archive_rows=0
                     AND latest_duplicate_key_rows=0 AND archive_duplicate_key_rows=0 AND archive_trigger_status='PASS' FROM obs)
         AND (SELECT observed_latest_rows=1500 AND observed_archive_rows=1500
                     AND observed_latest_set_hash='a69d1fca447bb573040bf697c43ce1af' AND observed_archive_set_hash='9e43326cd8f79b98c19f02f971fb077f'
                     AND payload_mismatch_count=0 AND missing_latest_rows=0 AND missing_archive_rows=0
                     AND latest_duplicate_key_rows=0 AND archive_duplicate_key_rows=0 AND archive_trigger_status='PASS'
                     AND reproduction_status='PASS' AND source_registry_row_hash='32374a67d0f8ead18af4bc18139ffdd6'
                     AND row_hash IS NOT DISTINCT FROM md5((to_jsonb(snap)-'row_hash'-'created_at')::text) FROM snap)) AS pass_flag,
        'Direct persisted latest/archive reconstruction for component M2_PRICING_STRUCTURE_CONSUMPTION; no Program 222 transaction-local helper is used.'::text AS interpretation
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_077_COMPONENT_05_M2_FINAL_OFFER_DECISION_CONSUMPTION_PHYSICAL_REPRODUCTION */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    77::smallint,
    'M2_12_POS_077_COMPONENT_05_M2_FINAL_OFFER_DECISION_CONSUMPTION_PHYSICAL_REPRODUCTION'::text,
    5::smallint,
    'LATEST_ARCHIVE_REPRODUCTION'::text,
    'Component 05 M2_FINAL_OFFER_DECISION_CONSUMPTION latest/archive state reproduces directly from physical rows'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH ctx AS (
        SELECT module1_run_id FROM tmp_src_m2_12_validation_run_context
    ), cd AS (
        SELECT c.* FROM msbf_m2.module2_contract_component_snapshot c
        JOIN ctx ON ctx.module1_run_id=c.module1_run_id
        WHERE c.component_sequence=5 AND c.component_contract_code='M2_FINAL_OFFER_DECISION_CONSUMPTION' AND c.contract_version=1
    ), obs AS (
        SELECT
            (SELECT count(*)::bigint FROM msbf_m2.application_final_offer_decision_latest l WHERE l.module1_run_id=ctx.module1_run_id) AS observed_latest_rows,
            (SELECT count(*)::bigint FROM msbf_m2.application_final_offer_decision_archive a WHERE a.module1_run_id=ctx.module1_run_id AND a.contract_version=cd.contract_version) AS observed_archive_rows,
            (SELECT md5(string_agg(l.scenario_id::text||'|'||l.merchant_application_id||'|'||l.contract_row_hash,'|' ORDER BY l.scenario_id,l.merchant_application_id)) FROM msbf_m2.application_final_offer_decision_latest l WHERE l.module1_run_id=ctx.module1_run_id)::text AS reconstructed_latest_set_hash,
            (SELECT md5(string_agg(a.scenario_id::text||'|'||a.merchant_application_id||'|'||a.archive_row_hash,'|' ORDER BY a.scenario_id,a.merchant_application_id)) FROM msbf_m2.application_final_offer_decision_archive a WHERE a.module1_run_id=ctx.module1_run_id AND a.contract_version=cd.contract_version)::text AS reconstructed_archive_set_hash,
            (SELECT count(*)::bigint FROM msbf_m2.application_final_offer_decision_latest l FULL JOIN msbf_m2.application_final_offer_decision_archive a ON a.module1_run_id=l.module1_run_id AND a.contract_version=l.contract_version AND a.scenario_id=l.scenario_id AND a.merchant_application_id=l.merchant_application_id WHERE coalesce(l.module1_run_id,a.module1_run_id)=ctx.module1_run_id AND l.module1_run_id IS NOT NULL AND a.module1_run_id IS NOT NULL AND ((a.contract_payload IS DISTINCT FROM (to_jsonb(l)-'created_at')) OR ((to_jsonb(a)-ARRAY['archive_id','contract_payload','archive_row_hash','archived_at','created_at']::text[]) IS DISTINCT FROM (to_jsonb(l)-'created_at')) OR (a.contract_row_hash IS DISTINCT FROM l.contract_row_hash) OR (l.contract_row_hash IS DISTINCT FROM msbf_ctl.m2_3_hash_jsonb(to_jsonb(l)-'contract_row_hash'-'created_at')) OR (a.archive_row_hash IS DISTINCT FROM msbf_ctl.m2_3_hash_jsonb(to_jsonb(a)-'archive_id'-'archive_row_hash'-'archived_at'-'created_at'))))::bigint AS payload_mismatch_count,
            (SELECT count(*)::bigint FROM msbf_m2.application_final_offer_decision_latest l FULL JOIN msbf_m2.application_final_offer_decision_archive a ON a.module1_run_id=l.module1_run_id AND a.contract_version=l.contract_version AND a.scenario_id=l.scenario_id AND a.merchant_application_id=l.merchant_application_id WHERE coalesce(l.module1_run_id,a.module1_run_id)=ctx.module1_run_id AND l.module1_run_id IS NULL)::bigint AS missing_latest_rows,
            (SELECT count(*)::bigint FROM msbf_m2.application_final_offer_decision_latest l FULL JOIN msbf_m2.application_final_offer_decision_archive a ON a.module1_run_id=l.module1_run_id AND a.contract_version=l.contract_version AND a.scenario_id=l.scenario_id AND a.merchant_application_id=l.merchant_application_id WHERE coalesce(l.module1_run_id,a.module1_run_id)=ctx.module1_run_id AND a.module1_run_id IS NULL)::bigint AS missing_archive_rows,
            (SELECT count(*)::bigint FROM (SELECT module1_run_id,scenario_id,merchant_application_id,count(*) c FROM msbf_m2.application_final_offer_decision_latest WHERE module1_run_id=ctx.module1_run_id GROUP BY module1_run_id,scenario_id,merchant_application_id HAVING count(*)>1) d)::bigint AS latest_duplicate_key_rows,
            (SELECT count(*)::bigint FROM (SELECT module1_run_id,contract_version,scenario_id,merchant_application_id,count(*) c FROM msbf_m2.application_final_offer_decision_archive WHERE module1_run_id=ctx.module1_run_id AND contract_version=cd.contract_version GROUP BY module1_run_id,contract_version,scenario_id,merchant_application_id HAVING count(*)>1) d)::bigint AS archive_duplicate_key_rows,
            CASE WHEN (SELECT count(*) FROM pg_catalog.pg_trigger t WHERE t.tgrelid='msbf_m2.application_final_offer_decision_archive'::regclass AND NOT t.tgisinternal AND t.tgname='trg_m2_3_decision_archive_immutable' AND (t.tgtype & 8)=8 AND (t.tgtype & 16)=16 AND t.tgenabled IN ('O','A'))=1 THEN 'PASS' ELSE 'FAIL' END::text::text AS archive_trigger_status
        FROM ctx CROSS JOIN cd
    ), snap AS (
        SELECT r.* FROM msbf_m2.module2_contract_reproduction_snapshot r
        JOIN ctx ON ctx.module1_run_id=r.module1_run_id
        WHERE r.component_sequence=5 AND r.component_contract_code='M2_FINAL_OFFER_DECISION_CONSUMPTION' AND r.contract_version=1
    )
    SELECT
        concat_ws('|',(SELECT observed_latest_rows FROM obs),(SELECT observed_archive_rows FROM obs),
          (SELECT reconstructed_latest_set_hash FROM obs),(SELECT reconstructed_archive_set_hash FROM obs),
          (SELECT payload_mismatch_count FROM obs),(SELECT missing_latest_rows FROM obs),(SELECT missing_archive_rows FROM obs),
          (SELECT latest_duplicate_key_rows FROM obs),(SELECT archive_duplicate_key_rows FROM obs),(SELECT archive_trigger_status FROM obs),
          (SELECT count(*) FROM snap),(SELECT min(reproduction_status) FROM snap)) AS observed_value,
        '1500|1500|8f421bd27d52e18770cee8fb8a72edf1|06331f681706a5b9922865ccbe900755|0|0|0|0|0|PASS|1|PASS'::text AS expected_value,
        (CASE WHEN (SELECT count(*) FROM cd)=1 AND (SELECT count(*) FROM obs)=1 AND (SELECT count(*) FROM snap)=1
                   AND (SELECT observed_latest_rows=1500 AND observed_archive_rows=1500
                               AND reconstructed_latest_set_hash='8f421bd27d52e18770cee8fb8a72edf1'
                               AND reconstructed_archive_set_hash='06331f681706a5b9922865ccbe900755'
                               AND payload_mismatch_count=0 AND missing_latest_rows=0 AND missing_archive_rows=0
                               AND latest_duplicate_key_rows=0 AND archive_duplicate_key_rows=0 AND archive_trigger_status='PASS' FROM obs)
                   AND (SELECT observed_latest_rows=1500 AND observed_archive_rows=1500
                               AND observed_latest_set_hash='8f421bd27d52e18770cee8fb8a72edf1' AND observed_archive_set_hash='06331f681706a5b9922865ccbe900755'
                               AND payload_mismatch_count=0 AND missing_latest_rows=0 AND missing_archive_rows=0
                               AND latest_duplicate_key_rows=0 AND archive_duplicate_key_rows=0 AND archive_trigger_status='PASS'
                               AND reproduction_status='PASS' AND source_registry_row_hash='03ef3d5ffa4c49d982b3877c4002de2d'
                               AND row_hash IS NOT DISTINCT FROM md5((to_jsonb(snap)-'row_hash'-'created_at')::text) FROM snap)
              THEN 0 ELSE 1 END)::bigint AS mismatch_count,
        ((SELECT count(*) FROM cd)=1 AND (SELECT count(*) FROM obs)=1 AND (SELECT count(*) FROM snap)=1
         AND (SELECT observed_latest_rows=1500 AND observed_archive_rows=1500
                     AND reconstructed_latest_set_hash='8f421bd27d52e18770cee8fb8a72edf1'
                     AND reconstructed_archive_set_hash='06331f681706a5b9922865ccbe900755'
                     AND payload_mismatch_count=0 AND missing_latest_rows=0 AND missing_archive_rows=0
                     AND latest_duplicate_key_rows=0 AND archive_duplicate_key_rows=0 AND archive_trigger_status='PASS' FROM obs)
         AND (SELECT observed_latest_rows=1500 AND observed_archive_rows=1500
                     AND observed_latest_set_hash='8f421bd27d52e18770cee8fb8a72edf1' AND observed_archive_set_hash='06331f681706a5b9922865ccbe900755'
                     AND payload_mismatch_count=0 AND missing_latest_rows=0 AND missing_archive_rows=0
                     AND latest_duplicate_key_rows=0 AND archive_duplicate_key_rows=0 AND archive_trigger_status='PASS'
                     AND reproduction_status='PASS' AND source_registry_row_hash='03ef3d5ffa4c49d982b3877c4002de2d'
                     AND row_hash IS NOT DISTINCT FROM md5((to_jsonb(snap)-'row_hash'-'created_at')::text) FROM snap)) AS pass_flag,
        'Direct persisted latest/archive reconstruction for component M2_FINAL_OFFER_DECISION_CONSUMPTION; no Program 222 transaction-local helper is used.'::text AS interpretation
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_078_COMPONENT_06_M2_PORTFOLIO_ACTIVATION_CONSUMPTION_PHYSICAL_REPRODUCTION */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    78::smallint,
    'M2_12_POS_078_COMPONENT_06_M2_PORTFOLIO_ACTIVATION_CONSUMPTION_PHYSICAL_REPRODUCTION'::text,
    5::smallint,
    'LATEST_ARCHIVE_REPRODUCTION'::text,
    'Component 06 M2_PORTFOLIO_ACTIVATION_CONSUMPTION latest/archive state reproduces directly from physical rows'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH ctx AS (
        SELECT module1_run_id FROM tmp_src_m2_12_validation_run_context
    ), cd AS (
        SELECT c.* FROM msbf_m2.module2_contract_component_snapshot c
        JOIN ctx ON ctx.module1_run_id=c.module1_run_id
        WHERE c.component_sequence=6 AND c.component_contract_code='M2_PORTFOLIO_ACTIVATION_CONSUMPTION' AND c.contract_version=1
    ), obs AS (
        SELECT
            (SELECT count(*)::bigint FROM msbf_m2.application_booking_funding_activation_latest l WHERE l.module1_run_id=ctx.module1_run_id) AS observed_latest_rows,
            (SELECT count(*)::bigint FROM msbf_m2.application_booking_funding_activation_archive a WHERE a.module1_run_id=ctx.module1_run_id AND a.contract_version=cd.contract_version) AS observed_archive_rows,
            (SELECT md5(string_agg(l.scenario_id::text||'|'||l.merchant_application_id||'|'||l.contract_row_hash,'|' ORDER BY l.scenario_id,l.merchant_application_id)) FROM msbf_m2.application_booking_funding_activation_latest l WHERE l.module1_run_id=ctx.module1_run_id)::text AS reconstructed_latest_set_hash,
            (SELECT md5(string_agg(a.scenario_id::text||'|'||a.merchant_application_id||'|'||a.archive_row_hash,'|' ORDER BY a.scenario_id,a.merchant_application_id)) FROM msbf_m2.application_booking_funding_activation_archive a WHERE a.module1_run_id=ctx.module1_run_id AND a.contract_version=cd.contract_version)::text AS reconstructed_archive_set_hash,
            (SELECT count(*)::bigint FROM msbf_m2.application_booking_funding_activation_latest l FULL JOIN msbf_m2.application_booking_funding_activation_archive a ON a.module1_run_id=l.module1_run_id AND a.contract_version=l.contract_version AND a.scenario_id=l.scenario_id AND a.merchant_application_id=l.merchant_application_id WHERE coalesce(l.module1_run_id,a.module1_run_id)=ctx.module1_run_id AND l.module1_run_id IS NOT NULL AND a.module1_run_id IS NOT NULL AND ((a.contract_payload IS DISTINCT FROM (to_jsonb(l)-'created_at')) OR ((to_jsonb(a)-ARRAY['archive_id','contract_payload','archive_row_hash','archived_at','created_at']::text[]) IS DISTINCT FROM (to_jsonb(l)-'created_at')) OR (a.contract_row_hash IS DISTINCT FROM l.contract_row_hash) OR (l.contract_row_hash IS DISTINCT FROM msbf_ctl.m2_4_hash_jsonb(to_jsonb(l)-'contract_row_hash'-'created_at')) OR (a.archive_row_hash IS DISTINCT FROM msbf_ctl.m2_4_hash_jsonb(to_jsonb(a)-'archive_id'-'archive_row_hash'-'archived_at'-'created_at'))))::bigint AS payload_mismatch_count,
            (SELECT count(*)::bigint FROM msbf_m2.application_booking_funding_activation_latest l FULL JOIN msbf_m2.application_booking_funding_activation_archive a ON a.module1_run_id=l.module1_run_id AND a.contract_version=l.contract_version AND a.scenario_id=l.scenario_id AND a.merchant_application_id=l.merchant_application_id WHERE coalesce(l.module1_run_id,a.module1_run_id)=ctx.module1_run_id AND l.module1_run_id IS NULL)::bigint AS missing_latest_rows,
            (SELECT count(*)::bigint FROM msbf_m2.application_booking_funding_activation_latest l FULL JOIN msbf_m2.application_booking_funding_activation_archive a ON a.module1_run_id=l.module1_run_id AND a.contract_version=l.contract_version AND a.scenario_id=l.scenario_id AND a.merchant_application_id=l.merchant_application_id WHERE coalesce(l.module1_run_id,a.module1_run_id)=ctx.module1_run_id AND a.module1_run_id IS NULL)::bigint AS missing_archive_rows,
            (SELECT count(*)::bigint FROM (SELECT module1_run_id,scenario_id,merchant_application_id,count(*) c FROM msbf_m2.application_booking_funding_activation_latest WHERE module1_run_id=ctx.module1_run_id GROUP BY module1_run_id,scenario_id,merchant_application_id HAVING count(*)>1) d)::bigint AS latest_duplicate_key_rows,
            (SELECT count(*)::bigint FROM (SELECT module1_run_id,contract_version,scenario_id,merchant_application_id,count(*) c FROM msbf_m2.application_booking_funding_activation_archive WHERE module1_run_id=ctx.module1_run_id AND contract_version=cd.contract_version GROUP BY module1_run_id,contract_version,scenario_id,merchant_application_id HAVING count(*)>1) d)::bigint AS archive_duplicate_key_rows,
            CASE WHEN (SELECT count(*) FROM pg_catalog.pg_trigger t WHERE t.tgrelid='msbf_m2.application_booking_funding_activation_archive'::regclass AND NOT t.tgisinternal AND t.tgname='trg_m2_4_activation_archive_immutable' AND (t.tgtype & 8)=8 AND (t.tgtype & 16)=16 AND t.tgenabled IN ('O','A'))=1 THEN 'PASS' ELSE 'FAIL' END::text::text AS archive_trigger_status
        FROM ctx CROSS JOIN cd
    ), snap AS (
        SELECT r.* FROM msbf_m2.module2_contract_reproduction_snapshot r
        JOIN ctx ON ctx.module1_run_id=r.module1_run_id
        WHERE r.component_sequence=6 AND r.component_contract_code='M2_PORTFOLIO_ACTIVATION_CONSUMPTION' AND r.contract_version=1
    )
    SELECT
        concat_ws('|',(SELECT observed_latest_rows FROM obs),(SELECT observed_archive_rows FROM obs),
          (SELECT reconstructed_latest_set_hash FROM obs),(SELECT reconstructed_archive_set_hash FROM obs),
          (SELECT payload_mismatch_count FROM obs),(SELECT missing_latest_rows FROM obs),(SELECT missing_archive_rows FROM obs),
          (SELECT latest_duplicate_key_rows FROM obs),(SELECT archive_duplicate_key_rows FROM obs),(SELECT archive_trigger_status FROM obs),
          (SELECT count(*) FROM snap),(SELECT min(reproduction_status) FROM snap)) AS observed_value,
        '1500|1500|f26248c112635ebe5254d614f42332d6|bf72bbed8c76db3ecdc6936e78718e04|0|0|0|0|0|PASS|1|PASS'::text AS expected_value,
        (CASE WHEN (SELECT count(*) FROM cd)=1 AND (SELECT count(*) FROM obs)=1 AND (SELECT count(*) FROM snap)=1
                   AND (SELECT observed_latest_rows=1500 AND observed_archive_rows=1500
                               AND reconstructed_latest_set_hash='f26248c112635ebe5254d614f42332d6'
                               AND reconstructed_archive_set_hash='bf72bbed8c76db3ecdc6936e78718e04'
                               AND payload_mismatch_count=0 AND missing_latest_rows=0 AND missing_archive_rows=0
                               AND latest_duplicate_key_rows=0 AND archive_duplicate_key_rows=0 AND archive_trigger_status='PASS' FROM obs)
                   AND (SELECT observed_latest_rows=1500 AND observed_archive_rows=1500
                               AND observed_latest_set_hash='f26248c112635ebe5254d614f42332d6' AND observed_archive_set_hash='bf72bbed8c76db3ecdc6936e78718e04'
                               AND payload_mismatch_count=0 AND missing_latest_rows=0 AND missing_archive_rows=0
                               AND latest_duplicate_key_rows=0 AND archive_duplicate_key_rows=0 AND archive_trigger_status='PASS'
                               AND reproduction_status='PASS' AND source_registry_row_hash='879e04636699b51113638ec81d76667b'
                               AND row_hash IS NOT DISTINCT FROM md5((to_jsonb(snap)-'row_hash'-'created_at')::text) FROM snap)
              THEN 0 ELSE 1 END)::bigint AS mismatch_count,
        ((SELECT count(*) FROM cd)=1 AND (SELECT count(*) FROM obs)=1 AND (SELECT count(*) FROM snap)=1
         AND (SELECT observed_latest_rows=1500 AND observed_archive_rows=1500
                     AND reconstructed_latest_set_hash='f26248c112635ebe5254d614f42332d6'
                     AND reconstructed_archive_set_hash='bf72bbed8c76db3ecdc6936e78718e04'
                     AND payload_mismatch_count=0 AND missing_latest_rows=0 AND missing_archive_rows=0
                     AND latest_duplicate_key_rows=0 AND archive_duplicate_key_rows=0 AND archive_trigger_status='PASS' FROM obs)
         AND (SELECT observed_latest_rows=1500 AND observed_archive_rows=1500
                     AND observed_latest_set_hash='f26248c112635ebe5254d614f42332d6' AND observed_archive_set_hash='bf72bbed8c76db3ecdc6936e78718e04'
                     AND payload_mismatch_count=0 AND missing_latest_rows=0 AND missing_archive_rows=0
                     AND latest_duplicate_key_rows=0 AND archive_duplicate_key_rows=0 AND archive_trigger_status='PASS'
                     AND reproduction_status='PASS' AND source_registry_row_hash='879e04636699b51113638ec81d76667b'
                     AND row_hash IS NOT DISTINCT FROM md5((to_jsonb(snap)-'row_hash'-'created_at')::text) FROM snap)) AS pass_flag,
        'Direct persisted latest/archive reconstruction for component M2_PORTFOLIO_ACTIVATION_CONSUMPTION; no Program 222 transaction-local helper is used.'::text AS interpretation
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_079_COMPONENT_07_M2_DAILY_REMITTANCE_EXPOSURE_MONITORING_CONSUMPTION_PHYSICAL_REPRODUCTION */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    79::smallint,
    'M2_12_POS_079_COMPONENT_07_M2_DAILY_REMITTANCE_EXPOSURE_MONITORING_CONSUMPTION_PHYSICAL_REPRODUCTION'::text,
    5::smallint,
    'LATEST_ARCHIVE_REPRODUCTION'::text,
    'Component 07 M2_DAILY_REMITTANCE_EXPOSURE_MONITORING_CONSUMPTION latest/archive state reproduces directly from physical rows'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH ctx AS (
        SELECT module1_run_id FROM tmp_src_m2_12_validation_run_context
    ), cd AS (
        SELECT c.* FROM msbf_m2.module2_contract_component_snapshot c
        JOIN ctx ON ctx.module1_run_id=c.module1_run_id
        WHERE c.component_sequence=7 AND c.component_contract_code='M2_DAILY_REMITTANCE_EXPOSURE_MONITORING_CONSUMPTION' AND c.contract_version=1
    ), obs AS (
        SELECT
            (SELECT count(*)::bigint FROM msbf_m2.advance_portfolio_monitoring_latest l WHERE l.module1_run_id=ctx.module1_run_id) AS observed_latest_rows,
            (SELECT count(*)::bigint FROM msbf_m2.advance_portfolio_monitoring_archive a WHERE a.module1_run_id=ctx.module1_run_id AND a.contract_version=cd.contract_version) AS observed_archive_rows,
            (SELECT md5(string_agg(l.scenario_id::text||'|'||l.merchant_application_id||'|'||l.contract_row_hash,'|' ORDER BY l.scenario_id,l.merchant_application_id)) FROM msbf_m2.advance_portfolio_monitoring_latest l WHERE l.module1_run_id=ctx.module1_run_id)::text AS reconstructed_latest_set_hash,
            (SELECT md5(string_agg(a.scenario_id::text||'|'||a.merchant_application_id||'|'||a.archive_row_hash,'|' ORDER BY a.scenario_id,a.merchant_application_id)) FROM msbf_m2.advance_portfolio_monitoring_archive a WHERE a.module1_run_id=ctx.module1_run_id AND a.contract_version=cd.contract_version)::text AS reconstructed_archive_set_hash,
            (SELECT count(*)::bigint FROM msbf_m2.advance_portfolio_monitoring_latest l FULL JOIN msbf_m2.advance_portfolio_monitoring_archive a ON a.module1_run_id=l.module1_run_id AND a.contract_version=l.contract_version AND a.scenario_id=l.scenario_id AND a.merchant_application_id=l.merchant_application_id WHERE coalesce(l.module1_run_id,a.module1_run_id)=ctx.module1_run_id AND l.module1_run_id IS NOT NULL AND a.module1_run_id IS NOT NULL AND ((a.contract_payload IS DISTINCT FROM (to_jsonb(l)-'created_at')) OR ((to_jsonb(a)-ARRAY['archive_id','contract_payload','archive_row_hash','archived_at','created_at']::text[]) IS DISTINCT FROM (to_jsonb(l)-'created_at')) OR (a.contract_row_hash IS DISTINCT FROM l.contract_row_hash) OR (l.contract_row_hash IS DISTINCT FROM msbf_ctl.m2_5_hash_jsonb(to_jsonb(l)-'contract_row_hash'-'created_at')) OR (a.archive_row_hash IS DISTINCT FROM msbf_ctl.m2_5_hash_jsonb(to_jsonb(a)-'archive_id'-'archive_row_hash'-'archived_at'-'created_at'))))::bigint AS payload_mismatch_count,
            (SELECT count(*)::bigint FROM msbf_m2.advance_portfolio_monitoring_latest l FULL JOIN msbf_m2.advance_portfolio_monitoring_archive a ON a.module1_run_id=l.module1_run_id AND a.contract_version=l.contract_version AND a.scenario_id=l.scenario_id AND a.merchant_application_id=l.merchant_application_id WHERE coalesce(l.module1_run_id,a.module1_run_id)=ctx.module1_run_id AND l.module1_run_id IS NULL)::bigint AS missing_latest_rows,
            (SELECT count(*)::bigint FROM msbf_m2.advance_portfolio_monitoring_latest l FULL JOIN msbf_m2.advance_portfolio_monitoring_archive a ON a.module1_run_id=l.module1_run_id AND a.contract_version=l.contract_version AND a.scenario_id=l.scenario_id AND a.merchant_application_id=l.merchant_application_id WHERE coalesce(l.module1_run_id,a.module1_run_id)=ctx.module1_run_id AND a.module1_run_id IS NULL)::bigint AS missing_archive_rows,
            (SELECT count(*)::bigint FROM (SELECT module1_run_id,scenario_id,merchant_application_id,count(*) c FROM msbf_m2.advance_portfolio_monitoring_latest WHERE module1_run_id=ctx.module1_run_id GROUP BY module1_run_id,scenario_id,merchant_application_id HAVING count(*)>1) d)::bigint AS latest_duplicate_key_rows,
            (SELECT count(*)::bigint FROM (SELECT module1_run_id,contract_version,scenario_id,merchant_application_id,count(*) c FROM msbf_m2.advance_portfolio_monitoring_archive WHERE module1_run_id=ctx.module1_run_id AND contract_version=cd.contract_version GROUP BY module1_run_id,contract_version,scenario_id,merchant_application_id HAVING count(*)>1) d)::bigint AS archive_duplicate_key_rows,
            CASE WHEN (SELECT count(*) FROM pg_catalog.pg_trigger t WHERE t.tgrelid='msbf_m2.advance_portfolio_monitoring_archive'::regclass AND NOT t.tgisinternal AND t.tgname='trg_m2_5_monitoring_archive_immutable' AND (t.tgtype & 8)=8 AND (t.tgtype & 16)=16 AND t.tgenabled IN ('O','A'))=1 THEN 'PASS' ELSE 'FAIL' END::text::text AS archive_trigger_status
        FROM ctx CROSS JOIN cd
    ), snap AS (
        SELECT r.* FROM msbf_m2.module2_contract_reproduction_snapshot r
        JOIN ctx ON ctx.module1_run_id=r.module1_run_id
        WHERE r.component_sequence=7 AND r.component_contract_code='M2_DAILY_REMITTANCE_EXPOSURE_MONITORING_CONSUMPTION' AND r.contract_version=1
    )
    SELECT
        concat_ws('|',(SELECT observed_latest_rows FROM obs),(SELECT observed_archive_rows FROM obs),
          (SELECT reconstructed_latest_set_hash FROM obs),(SELECT reconstructed_archive_set_hash FROM obs),
          (SELECT payload_mismatch_count FROM obs),(SELECT missing_latest_rows FROM obs),(SELECT missing_archive_rows FROM obs),
          (SELECT latest_duplicate_key_rows FROM obs),(SELECT archive_duplicate_key_rows FROM obs),(SELECT archive_trigger_status FROM obs),
          (SELECT count(*) FROM snap),(SELECT min(reproduction_status) FROM snap)) AS observed_value,
        '59|59|ddb680b9f00e88483099d90e781337eb|c8c22762d49bbd58cf89bae187eaac9f|0|0|0|0|0|PASS|1|PASS'::text AS expected_value,
        (CASE WHEN (SELECT count(*) FROM cd)=1 AND (SELECT count(*) FROM obs)=1 AND (SELECT count(*) FROM snap)=1
                   AND (SELECT observed_latest_rows=59 AND observed_archive_rows=59
                               AND reconstructed_latest_set_hash='ddb680b9f00e88483099d90e781337eb'
                               AND reconstructed_archive_set_hash='c8c22762d49bbd58cf89bae187eaac9f'
                               AND payload_mismatch_count=0 AND missing_latest_rows=0 AND missing_archive_rows=0
                               AND latest_duplicate_key_rows=0 AND archive_duplicate_key_rows=0 AND archive_trigger_status='PASS' FROM obs)
                   AND (SELECT observed_latest_rows=59 AND observed_archive_rows=59
                               AND observed_latest_set_hash='ddb680b9f00e88483099d90e781337eb' AND observed_archive_set_hash='c8c22762d49bbd58cf89bae187eaac9f'
                               AND payload_mismatch_count=0 AND missing_latest_rows=0 AND missing_archive_rows=0
                               AND latest_duplicate_key_rows=0 AND archive_duplicate_key_rows=0 AND archive_trigger_status='PASS'
                               AND reproduction_status='PASS' AND source_registry_row_hash='c50efd2f8ec5bf10216e5da889ff403d'
                               AND row_hash IS NOT DISTINCT FROM md5((to_jsonb(snap)-'row_hash'-'created_at')::text) FROM snap)
              THEN 0 ELSE 1 END)::bigint AS mismatch_count,
        ((SELECT count(*) FROM cd)=1 AND (SELECT count(*) FROM obs)=1 AND (SELECT count(*) FROM snap)=1
         AND (SELECT observed_latest_rows=59 AND observed_archive_rows=59
                     AND reconstructed_latest_set_hash='ddb680b9f00e88483099d90e781337eb'
                     AND reconstructed_archive_set_hash='c8c22762d49bbd58cf89bae187eaac9f'
                     AND payload_mismatch_count=0 AND missing_latest_rows=0 AND missing_archive_rows=0
                     AND latest_duplicate_key_rows=0 AND archive_duplicate_key_rows=0 AND archive_trigger_status='PASS' FROM obs)
         AND (SELECT observed_latest_rows=59 AND observed_archive_rows=59
                     AND observed_latest_set_hash='ddb680b9f00e88483099d90e781337eb' AND observed_archive_set_hash='c8c22762d49bbd58cf89bae187eaac9f'
                     AND payload_mismatch_count=0 AND missing_latest_rows=0 AND missing_archive_rows=0
                     AND latest_duplicate_key_rows=0 AND archive_duplicate_key_rows=0 AND archive_trigger_status='PASS'
                     AND reproduction_status='PASS' AND source_registry_row_hash='c50efd2f8ec5bf10216e5da889ff403d'
                     AND row_hash IS NOT DISTINCT FROM md5((to_jsonb(snap)-'row_hash'-'created_at')::text) FROM snap)) AS pass_flag,
        'Direct persisted latest/archive reconstruction for component M2_DAILY_REMITTANCE_EXPOSURE_MONITORING_CONSUMPTION; no Program 222 transaction-local helper is used.'::text AS interpretation
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_080_COMPONENT_08_M2_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_CONSUMPTION_PHYSICAL_REPRODUCTION */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    80::smallint,
    'M2_12_POS_080_COMPONENT_08_M2_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_CONSUMPTION_PHYSICAL_REPRODUCTION'::text,
    5::smallint,
    'LATEST_ARCHIVE_REPRODUCTION'::text,
    'Component 08 M2_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_CONSUMPTION latest/archive state reproduces directly from physical rows'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH ctx AS (
        SELECT module1_run_id FROM tmp_src_m2_12_validation_run_context
    ), cd AS (
        SELECT c.* FROM msbf_m2.module2_contract_component_snapshot c
        JOIN ctx ON ctx.module1_run_id=c.module1_run_id
        WHERE c.component_sequence=8 AND c.component_contract_code='M2_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_CONSUMPTION' AND c.contract_version=1
    ), obs AS (
        SELECT
            (SELECT count(*)::bigint FROM msbf_m2.advance_intervention_strategy_latest l WHERE l.module1_run_id=ctx.module1_run_id) AS observed_latest_rows,
            (SELECT count(*)::bigint FROM msbf_m2.advance_intervention_strategy_archive a WHERE a.module1_run_id=ctx.module1_run_id AND a.contract_version=cd.contract_version) AS observed_archive_rows,
            (SELECT md5(string_agg(l.scenario_id::text||'|'||l.merchant_application_id||'|'||l.contract_row_hash,'|' ORDER BY l.scenario_id,l.merchant_application_id)) FROM msbf_m2.advance_intervention_strategy_latest l WHERE l.module1_run_id=ctx.module1_run_id)::text AS reconstructed_latest_set_hash,
            (SELECT md5(string_agg(a.scenario_id::text||'|'||a.merchant_application_id||'|'||a.archive_row_hash,'|' ORDER BY a.scenario_id,a.merchant_application_id)) FROM msbf_m2.advance_intervention_strategy_archive a WHERE a.module1_run_id=ctx.module1_run_id AND a.contract_version=cd.contract_version)::text AS reconstructed_archive_set_hash,
            (SELECT count(*)::bigint FROM msbf_m2.advance_intervention_strategy_latest l FULL JOIN msbf_m2.advance_intervention_strategy_archive a ON a.module1_run_id=l.module1_run_id AND a.contract_version=l.contract_version AND a.scenario_id=l.scenario_id AND a.merchant_application_id=l.merchant_application_id WHERE coalesce(l.module1_run_id,a.module1_run_id)=ctx.module1_run_id AND l.module1_run_id IS NOT NULL AND a.module1_run_id IS NOT NULL AND ((a.contract_payload IS DISTINCT FROM (to_jsonb(l)-'created_at')) OR ((to_jsonb(a)-ARRAY['archive_id','contract_payload','archive_row_hash','archived_at','created_at']::text[]) IS DISTINCT FROM (to_jsonb(l)-'created_at')) OR (a.contract_row_hash IS DISTINCT FROM l.contract_row_hash) OR (l.contract_row_hash IS DISTINCT FROM msbf_ctl.m2_6_hash_jsonb(to_jsonb(l)-'contract_row_hash'-'created_at')) OR (a.archive_row_hash IS DISTINCT FROM msbf_ctl.m2_6_hash_jsonb(to_jsonb(a)-'archive_id'-'archive_row_hash'-'archived_at'-'created_at'))))::bigint AS payload_mismatch_count,
            (SELECT count(*)::bigint FROM msbf_m2.advance_intervention_strategy_latest l FULL JOIN msbf_m2.advance_intervention_strategy_archive a ON a.module1_run_id=l.module1_run_id AND a.contract_version=l.contract_version AND a.scenario_id=l.scenario_id AND a.merchant_application_id=l.merchant_application_id WHERE coalesce(l.module1_run_id,a.module1_run_id)=ctx.module1_run_id AND l.module1_run_id IS NULL)::bigint AS missing_latest_rows,
            (SELECT count(*)::bigint FROM msbf_m2.advance_intervention_strategy_latest l FULL JOIN msbf_m2.advance_intervention_strategy_archive a ON a.module1_run_id=l.module1_run_id AND a.contract_version=l.contract_version AND a.scenario_id=l.scenario_id AND a.merchant_application_id=l.merchant_application_id WHERE coalesce(l.module1_run_id,a.module1_run_id)=ctx.module1_run_id AND a.module1_run_id IS NULL)::bigint AS missing_archive_rows,
            (SELECT count(*)::bigint FROM (SELECT module1_run_id,scenario_id,merchant_application_id,count(*) c FROM msbf_m2.advance_intervention_strategy_latest WHERE module1_run_id=ctx.module1_run_id GROUP BY module1_run_id,scenario_id,merchant_application_id HAVING count(*)>1) d)::bigint AS latest_duplicate_key_rows,
            (SELECT count(*)::bigint FROM (SELECT module1_run_id,contract_version,scenario_id,merchant_application_id,count(*) c FROM msbf_m2.advance_intervention_strategy_archive WHERE module1_run_id=ctx.module1_run_id AND contract_version=cd.contract_version GROUP BY module1_run_id,contract_version,scenario_id,merchant_application_id HAVING count(*)>1) d)::bigint AS archive_duplicate_key_rows,
            CASE WHEN (SELECT count(*) FROM pg_catalog.pg_trigger t WHERE t.tgrelid='msbf_m2.advance_intervention_strategy_archive'::regclass AND NOT t.tgisinternal AND t.tgname='trg_m2_6_strategy_archive_immutable' AND (t.tgtype & 8)=8 AND (t.tgtype & 16)=16 AND t.tgenabled IN ('O','A'))=1 THEN 'PASS' ELSE 'FAIL' END::text::text AS archive_trigger_status
        FROM ctx CROSS JOIN cd
    ), snap AS (
        SELECT r.* FROM msbf_m2.module2_contract_reproduction_snapshot r
        JOIN ctx ON ctx.module1_run_id=r.module1_run_id
        WHERE r.component_sequence=8 AND r.component_contract_code='M2_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_CONSUMPTION' AND r.contract_version=1
    )
    SELECT
        concat_ws('|',(SELECT observed_latest_rows FROM obs),(SELECT observed_archive_rows FROM obs),
          (SELECT reconstructed_latest_set_hash FROM obs),(SELECT reconstructed_archive_set_hash FROM obs),
          (SELECT payload_mismatch_count FROM obs),(SELECT missing_latest_rows FROM obs),(SELECT missing_archive_rows FROM obs),
          (SELECT latest_duplicate_key_rows FROM obs),(SELECT archive_duplicate_key_rows FROM obs),(SELECT archive_trigger_status FROM obs),
          (SELECT count(*) FROM snap),(SELECT min(reproduction_status) FROM snap)) AS observed_value,
        '59|59|f3c42642b2a22b68ff2130d7b065afcd|72f26807f4d65fa6f813502df9dde3f0|0|0|0|0|0|PASS|1|PASS'::text AS expected_value,
        (CASE WHEN (SELECT count(*) FROM cd)=1 AND (SELECT count(*) FROM obs)=1 AND (SELECT count(*) FROM snap)=1
                   AND (SELECT observed_latest_rows=59 AND observed_archive_rows=59
                               AND reconstructed_latest_set_hash='f3c42642b2a22b68ff2130d7b065afcd'
                               AND reconstructed_archive_set_hash='72f26807f4d65fa6f813502df9dde3f0'
                               AND payload_mismatch_count=0 AND missing_latest_rows=0 AND missing_archive_rows=0
                               AND latest_duplicate_key_rows=0 AND archive_duplicate_key_rows=0 AND archive_trigger_status='PASS' FROM obs)
                   AND (SELECT observed_latest_rows=59 AND observed_archive_rows=59
                               AND observed_latest_set_hash='f3c42642b2a22b68ff2130d7b065afcd' AND observed_archive_set_hash='72f26807f4d65fa6f813502df9dde3f0'
                               AND payload_mismatch_count=0 AND missing_latest_rows=0 AND missing_archive_rows=0
                               AND latest_duplicate_key_rows=0 AND archive_duplicate_key_rows=0 AND archive_trigger_status='PASS'
                               AND reproduction_status='PASS' AND source_registry_row_hash='4f145d5248bbc6ed5c45b172afa4d342'
                               AND row_hash IS NOT DISTINCT FROM md5((to_jsonb(snap)-'row_hash'-'created_at')::text) FROM snap)
              THEN 0 ELSE 1 END)::bigint AS mismatch_count,
        ((SELECT count(*) FROM cd)=1 AND (SELECT count(*) FROM obs)=1 AND (SELECT count(*) FROM snap)=1
         AND (SELECT observed_latest_rows=59 AND observed_archive_rows=59
                     AND reconstructed_latest_set_hash='f3c42642b2a22b68ff2130d7b065afcd'
                     AND reconstructed_archive_set_hash='72f26807f4d65fa6f813502df9dde3f0'
                     AND payload_mismatch_count=0 AND missing_latest_rows=0 AND missing_archive_rows=0
                     AND latest_duplicate_key_rows=0 AND archive_duplicate_key_rows=0 AND archive_trigger_status='PASS' FROM obs)
         AND (SELECT observed_latest_rows=59 AND observed_archive_rows=59
                     AND observed_latest_set_hash='f3c42642b2a22b68ff2130d7b065afcd' AND observed_archive_set_hash='72f26807f4d65fa6f813502df9dde3f0'
                     AND payload_mismatch_count=0 AND missing_latest_rows=0 AND missing_archive_rows=0
                     AND latest_duplicate_key_rows=0 AND archive_duplicate_key_rows=0 AND archive_trigger_status='PASS'
                     AND reproduction_status='PASS' AND source_registry_row_hash='4f145d5248bbc6ed5c45b172afa4d342'
                     AND row_hash IS NOT DISTINCT FROM md5((to_jsonb(snap)-'row_hash'-'created_at')::text) FROM snap)) AS pass_flag,
        'Direct persisted latest/archive reconstruction for component M2_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_CONSUMPTION; no Program 222 transaction-local helper is used.'::text AS interpretation
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_081_COMPONENT_09_M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION_PHYSICAL_REPRODUCTION */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    81::smallint,
    'M2_12_POS_081_COMPONENT_09_M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION_PHYSICAL_REPRODUCTION'::text,
    5::smallint,
    'LATEST_ARCHIVE_REPRODUCTION'::text,
    'Component 09 M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION latest/archive state reproduces directly from physical rows'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH ctx AS (
        SELECT module1_run_id FROM tmp_src_m2_12_validation_run_context
    ), cd AS (
        SELECT c.* FROM msbf_m2.module2_contract_component_snapshot c
        JOIN ctx ON ctx.module1_run_id=c.module1_run_id
        WHERE c.component_sequence=9 AND c.component_contract_code='M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION' AND c.contract_version=1
    ), obs AS (
        SELECT
            (SELECT count(*)::bigint FROM msbf_m2.application_operational_activation_latest l WHERE l.module1_run_id=ctx.module1_run_id) AS observed_latest_rows,
            (SELECT count(*)::bigint FROM msbf_m2.application_operational_activation_archive a WHERE a.module1_run_id=ctx.module1_run_id AND a.contract_version=cd.contract_version) AS observed_archive_rows,
            (SELECT md5(string_agg(l.scenario_id::text||'|'||l.merchant_application_id||'|'||l.contract_row_hash,'|' ORDER BY l.scenario_id,l.merchant_application_id)) FROM msbf_m2.application_operational_activation_latest l WHERE l.module1_run_id=ctx.module1_run_id)::text AS reconstructed_latest_set_hash,
            (SELECT md5(string_agg(a.scenario_id::text||'|'||a.merchant_application_id||'|'||a.archive_row_hash,'|' ORDER BY a.scenario_id,a.merchant_application_id)) FROM msbf_m2.application_operational_activation_archive a WHERE a.module1_run_id=ctx.module1_run_id AND a.contract_version=cd.contract_version)::text AS reconstructed_archive_set_hash,
            (SELECT count(*)::bigint FROM msbf_m2.application_operational_activation_latest l FULL JOIN msbf_m2.application_operational_activation_archive a ON a.module1_run_id=l.module1_run_id AND a.contract_version=l.contract_version AND a.scenario_id=l.scenario_id AND a.merchant_application_id=l.merchant_application_id WHERE coalesce(l.module1_run_id,a.module1_run_id)=ctx.module1_run_id AND l.module1_run_id IS NOT NULL AND a.module1_run_id IS NOT NULL AND ((a.contract_payload IS DISTINCT FROM (to_jsonb(l)-'created_at')) OR ((to_jsonb(a)-ARRAY['archive_id','contract_payload','archive_row_hash','archived_at','created_at']::text[]) IS DISTINCT FROM (to_jsonb(l)-'created_at')) OR (a.contract_row_hash IS DISTINCT FROM l.contract_row_hash) OR (l.contract_row_hash IS DISTINCT FROM msbf_ctl.m2_7_hash_jsonb(to_jsonb(l)-'contract_row_hash'-'created_at')) OR (a.archive_row_hash IS DISTINCT FROM msbf_ctl.m2_7_hash_jsonb(to_jsonb(a)-'archive_id'-'archive_row_hash'-'archived_at'-'created_at'))))::bigint AS payload_mismatch_count,
            (SELECT count(*)::bigint FROM msbf_m2.application_operational_activation_latest l FULL JOIN msbf_m2.application_operational_activation_archive a ON a.module1_run_id=l.module1_run_id AND a.contract_version=l.contract_version AND a.scenario_id=l.scenario_id AND a.merchant_application_id=l.merchant_application_id WHERE coalesce(l.module1_run_id,a.module1_run_id)=ctx.module1_run_id AND l.module1_run_id IS NULL)::bigint AS missing_latest_rows,
            (SELECT count(*)::bigint FROM msbf_m2.application_operational_activation_latest l FULL JOIN msbf_m2.application_operational_activation_archive a ON a.module1_run_id=l.module1_run_id AND a.contract_version=l.contract_version AND a.scenario_id=l.scenario_id AND a.merchant_application_id=l.merchant_application_id WHERE coalesce(l.module1_run_id,a.module1_run_id)=ctx.module1_run_id AND a.module1_run_id IS NULL)::bigint AS missing_archive_rows,
            (SELECT count(*)::bigint FROM (SELECT module1_run_id,scenario_id,merchant_application_id,count(*) c FROM msbf_m2.application_operational_activation_latest WHERE module1_run_id=ctx.module1_run_id GROUP BY module1_run_id,scenario_id,merchant_application_id HAVING count(*)>1) d)::bigint AS latest_duplicate_key_rows,
            (SELECT count(*)::bigint FROM (SELECT module1_run_id,contract_version,scenario_id,merchant_application_id,count(*) c FROM msbf_m2.application_operational_activation_archive WHERE module1_run_id=ctx.module1_run_id AND contract_version=cd.contract_version GROUP BY module1_run_id,contract_version,scenario_id,merchant_application_id HAVING count(*)>1) d)::bigint AS archive_duplicate_key_rows,
            CASE WHEN (SELECT count(*) FROM pg_catalog.pg_trigger t WHERE t.tgrelid='msbf_m2.application_operational_activation_archive'::regclass AND NOT t.tgisinternal AND t.tgname='trg_m2_7_activation_archive_immutable' AND (t.tgtype & 8)=8 AND (t.tgtype & 16)=16 AND t.tgenabled IN ('O','A'))=1 THEN 'PASS' ELSE 'FAIL' END::text::text AS archive_trigger_status
        FROM ctx CROSS JOIN cd
    ), snap AS (
        SELECT r.* FROM msbf_m2.module2_contract_reproduction_snapshot r
        JOIN ctx ON ctx.module1_run_id=r.module1_run_id
        WHERE r.component_sequence=9 AND r.component_contract_code='M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION' AND r.contract_version=1
    )
    SELECT
        concat_ws('|',(SELECT observed_latest_rows FROM obs),(SELECT observed_archive_rows FROM obs),
          (SELECT reconstructed_latest_set_hash FROM obs),(SELECT reconstructed_archive_set_hash FROM obs),
          (SELECT payload_mismatch_count FROM obs),(SELECT missing_latest_rows FROM obs),(SELECT missing_archive_rows FROM obs),
          (SELECT latest_duplicate_key_rows FROM obs),(SELECT archive_duplicate_key_rows FROM obs),(SELECT archive_trigger_status FROM obs),
          (SELECT count(*) FROM snap),(SELECT min(reproduction_status) FROM snap)) AS observed_value,
        '59|59|e1fa837647489de56d66222447420549|9980f9ff49ca53790ec9af8c6988d44a|0|0|0|0|0|PASS|1|PASS'::text AS expected_value,
        (CASE WHEN (SELECT count(*) FROM cd)=1 AND (SELECT count(*) FROM obs)=1 AND (SELECT count(*) FROM snap)=1
                   AND (SELECT observed_latest_rows=59 AND observed_archive_rows=59
                               AND reconstructed_latest_set_hash='e1fa837647489de56d66222447420549'
                               AND reconstructed_archive_set_hash='9980f9ff49ca53790ec9af8c6988d44a'
                               AND payload_mismatch_count=0 AND missing_latest_rows=0 AND missing_archive_rows=0
                               AND latest_duplicate_key_rows=0 AND archive_duplicate_key_rows=0 AND archive_trigger_status='PASS' FROM obs)
                   AND (SELECT observed_latest_rows=59 AND observed_archive_rows=59
                               AND observed_latest_set_hash='e1fa837647489de56d66222447420549' AND observed_archive_set_hash='9980f9ff49ca53790ec9af8c6988d44a'
                               AND payload_mismatch_count=0 AND missing_latest_rows=0 AND missing_archive_rows=0
                               AND latest_duplicate_key_rows=0 AND archive_duplicate_key_rows=0 AND archive_trigger_status='PASS'
                               AND reproduction_status='PASS' AND source_registry_row_hash='8b210c34bdb12f8fb71638b48b374c14'
                               AND row_hash IS NOT DISTINCT FROM md5((to_jsonb(snap)-'row_hash'-'created_at')::text) FROM snap)
              THEN 0 ELSE 1 END)::bigint AS mismatch_count,
        ((SELECT count(*) FROM cd)=1 AND (SELECT count(*) FROM obs)=1 AND (SELECT count(*) FROM snap)=1
         AND (SELECT observed_latest_rows=59 AND observed_archive_rows=59
                     AND reconstructed_latest_set_hash='e1fa837647489de56d66222447420549'
                     AND reconstructed_archive_set_hash='9980f9ff49ca53790ec9af8c6988d44a'
                     AND payload_mismatch_count=0 AND missing_latest_rows=0 AND missing_archive_rows=0
                     AND latest_duplicate_key_rows=0 AND archive_duplicate_key_rows=0 AND archive_trigger_status='PASS' FROM obs)
         AND (SELECT observed_latest_rows=59 AND observed_archive_rows=59
                     AND observed_latest_set_hash='e1fa837647489de56d66222447420549' AND observed_archive_set_hash='9980f9ff49ca53790ec9af8c6988d44a'
                     AND payload_mismatch_count=0 AND missing_latest_rows=0 AND missing_archive_rows=0
                     AND latest_duplicate_key_rows=0 AND archive_duplicate_key_rows=0 AND archive_trigger_status='PASS'
                     AND reproduction_status='PASS' AND source_registry_row_hash='8b210c34bdb12f8fb71638b48b374c14'
                     AND row_hash IS NOT DISTINCT FROM md5((to_jsonb(snap)-'row_hash'-'created_at')::text) FROM snap)) AS pass_flag,
        'Direct persisted latest/archive reconstruction for component M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION; no Program 222 transaction-local helper is used.'::text AS interpretation
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_082_COMPONENT_10_M2_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONSUMPTION_PHYSICAL_REPRODUCTION */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    82::smallint,
    'M2_12_POS_082_COMPONENT_10_M2_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONSUMPTION_PHYSICAL_REPRODUCTION'::text,
    5::smallint,
    'LATEST_ARCHIVE_REPRODUCTION'::text,
    'Component 10 M2_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONSUMPTION latest/archive state reproduces directly from physical rows'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH ctx AS (
        SELECT module1_run_id FROM tmp_src_m2_12_validation_run_context
    ), cd AS (
        SELECT c.* FROM msbf_m2.module2_contract_component_snapshot c
        JOIN ctx ON ctx.module1_run_id=c.module1_run_id
        WHERE c.component_sequence=10 AND c.component_contract_code='M2_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONSUMPTION' AND c.contract_version=1
    ), obs AS (
        SELECT
            (SELECT count(*)::bigint FROM msbf_m2.application_servicing_execution_latest l WHERE l.module1_run_id=ctx.module1_run_id) AS observed_latest_rows,
            (SELECT count(*)::bigint FROM msbf_m2.application_servicing_execution_archive a WHERE a.module1_run_id=ctx.module1_run_id AND a.contract_version=cd.contract_version) AS observed_archive_rows,
            (SELECT md5(string_agg(l.scenario_id::text||'|'||l.merchant_application_id||'|'||l.contract_row_hash,'|' ORDER BY l.scenario_id,l.merchant_application_id)) FROM msbf_m2.application_servicing_execution_latest l WHERE l.module1_run_id=ctx.module1_run_id)::text AS reconstructed_latest_set_hash,
            (SELECT md5(string_agg(a.scenario_id::text||'|'||a.merchant_application_id||'|'||a.archive_row_hash,'|' ORDER BY a.scenario_id,a.merchant_application_id)) FROM msbf_m2.application_servicing_execution_archive a WHERE a.module1_run_id=ctx.module1_run_id AND a.contract_version=cd.contract_version)::text AS reconstructed_archive_set_hash,
            (SELECT count(*)::bigint FROM msbf_m2.application_servicing_execution_latest l FULL JOIN msbf_m2.application_servicing_execution_archive a ON a.module1_run_id=l.module1_run_id AND a.contract_version=l.contract_version AND a.scenario_id=l.scenario_id AND a.merchant_application_id=l.merchant_application_id WHERE coalesce(l.module1_run_id,a.module1_run_id)=ctx.module1_run_id AND l.module1_run_id IS NOT NULL AND a.module1_run_id IS NOT NULL AND ((a.contract_payload IS DISTINCT FROM (to_jsonb(l)-'created_at')) OR ((to_jsonb(a)-ARRAY['archive_id','contract_payload','archive_row_hash','archived_at','created_at']::text[]) IS DISTINCT FROM (to_jsonb(l)-'created_at')) OR (a.contract_row_hash IS DISTINCT FROM l.contract_row_hash) OR (l.contract_row_hash IS DISTINCT FROM msbf_ctl.m2_8_hash_jsonb(to_jsonb(l)-'contract_row_hash'-'created_at')) OR (a.archive_row_hash IS DISTINCT FROM msbf_ctl.m2_8_hash_jsonb(to_jsonb(a)-'archive_id'-'archive_row_hash'-'archived_at'-'created_at'))))::bigint AS payload_mismatch_count,
            (SELECT count(*)::bigint FROM msbf_m2.application_servicing_execution_latest l FULL JOIN msbf_m2.application_servicing_execution_archive a ON a.module1_run_id=l.module1_run_id AND a.contract_version=l.contract_version AND a.scenario_id=l.scenario_id AND a.merchant_application_id=l.merchant_application_id WHERE coalesce(l.module1_run_id,a.module1_run_id)=ctx.module1_run_id AND l.module1_run_id IS NULL)::bigint AS missing_latest_rows,
            (SELECT count(*)::bigint FROM msbf_m2.application_servicing_execution_latest l FULL JOIN msbf_m2.application_servicing_execution_archive a ON a.module1_run_id=l.module1_run_id AND a.contract_version=l.contract_version AND a.scenario_id=l.scenario_id AND a.merchant_application_id=l.merchant_application_id WHERE coalesce(l.module1_run_id,a.module1_run_id)=ctx.module1_run_id AND a.module1_run_id IS NULL)::bigint AS missing_archive_rows,
            (SELECT count(*)::bigint FROM (SELECT module1_run_id,scenario_id,merchant_application_id,count(*) c FROM msbf_m2.application_servicing_execution_latest WHERE module1_run_id=ctx.module1_run_id GROUP BY module1_run_id,scenario_id,merchant_application_id HAVING count(*)>1) d)::bigint AS latest_duplicate_key_rows,
            (SELECT count(*)::bigint FROM (SELECT module1_run_id,contract_version,scenario_id,merchant_application_id,count(*) c FROM msbf_m2.application_servicing_execution_archive WHERE module1_run_id=ctx.module1_run_id AND contract_version=cd.contract_version GROUP BY module1_run_id,contract_version,scenario_id,merchant_application_id HAVING count(*)>1) d)::bigint AS archive_duplicate_key_rows,
            CASE WHEN (SELECT count(*) FROM pg_catalog.pg_trigger t WHERE t.tgrelid='msbf_m2.application_servicing_execution_archive'::regclass AND NOT t.tgisinternal AND t.tgname='trg_m2_8_servicing_archive_immutable' AND (t.tgtype & 8)=8 AND (t.tgtype & 16)=16 AND t.tgenabled IN ('O','A'))=1 THEN 'PASS' ELSE 'FAIL' END::text::text AS archive_trigger_status
        FROM ctx CROSS JOIN cd
    ), snap AS (
        SELECT r.* FROM msbf_m2.module2_contract_reproduction_snapshot r
        JOIN ctx ON ctx.module1_run_id=r.module1_run_id
        WHERE r.component_sequence=10 AND r.component_contract_code='M2_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONSUMPTION' AND r.contract_version=1
    )
    SELECT
        concat_ws('|',(SELECT observed_latest_rows FROM obs),(SELECT observed_archive_rows FROM obs),
          (SELECT reconstructed_latest_set_hash FROM obs),(SELECT reconstructed_archive_set_hash FROM obs),
          (SELECT payload_mismatch_count FROM obs),(SELECT missing_latest_rows FROM obs),(SELECT missing_archive_rows FROM obs),
          (SELECT latest_duplicate_key_rows FROM obs),(SELECT archive_duplicate_key_rows FROM obs),(SELECT archive_trigger_status FROM obs),
          (SELECT count(*) FROM snap),(SELECT min(reproduction_status) FROM snap)) AS observed_value,
        '59|59|9716224077ff6b7468c0b7b2fed6ab73|ea3a63d0bd9069cb5c061d09750d8d32|0|0|0|0|0|PASS|1|PASS'::text AS expected_value,
        (CASE WHEN (SELECT count(*) FROM cd)=1 AND (SELECT count(*) FROM obs)=1 AND (SELECT count(*) FROM snap)=1
                   AND (SELECT observed_latest_rows=59 AND observed_archive_rows=59
                               AND reconstructed_latest_set_hash='9716224077ff6b7468c0b7b2fed6ab73'
                               AND reconstructed_archive_set_hash='ea3a63d0bd9069cb5c061d09750d8d32'
                               AND payload_mismatch_count=0 AND missing_latest_rows=0 AND missing_archive_rows=0
                               AND latest_duplicate_key_rows=0 AND archive_duplicate_key_rows=0 AND archive_trigger_status='PASS' FROM obs)
                   AND (SELECT observed_latest_rows=59 AND observed_archive_rows=59
                               AND observed_latest_set_hash='9716224077ff6b7468c0b7b2fed6ab73' AND observed_archive_set_hash='ea3a63d0bd9069cb5c061d09750d8d32'
                               AND payload_mismatch_count=0 AND missing_latest_rows=0 AND missing_archive_rows=0
                               AND latest_duplicate_key_rows=0 AND archive_duplicate_key_rows=0 AND archive_trigger_status='PASS'
                               AND reproduction_status='PASS' AND source_registry_row_hash='03b6c0ca3af4ab9d196e09cefa59be3d'
                               AND row_hash IS NOT DISTINCT FROM md5((to_jsonb(snap)-'row_hash'-'created_at')::text) FROM snap)
              THEN 0 ELSE 1 END)::bigint AS mismatch_count,
        ((SELECT count(*) FROM cd)=1 AND (SELECT count(*) FROM obs)=1 AND (SELECT count(*) FROM snap)=1
         AND (SELECT observed_latest_rows=59 AND observed_archive_rows=59
                     AND reconstructed_latest_set_hash='9716224077ff6b7468c0b7b2fed6ab73'
                     AND reconstructed_archive_set_hash='ea3a63d0bd9069cb5c061d09750d8d32'
                     AND payload_mismatch_count=0 AND missing_latest_rows=0 AND missing_archive_rows=0
                     AND latest_duplicate_key_rows=0 AND archive_duplicate_key_rows=0 AND archive_trigger_status='PASS' FROM obs)
         AND (SELECT observed_latest_rows=59 AND observed_archive_rows=59
                     AND observed_latest_set_hash='9716224077ff6b7468c0b7b2fed6ab73' AND observed_archive_set_hash='ea3a63d0bd9069cb5c061d09750d8d32'
                     AND payload_mismatch_count=0 AND missing_latest_rows=0 AND missing_archive_rows=0
                     AND latest_duplicate_key_rows=0 AND archive_duplicate_key_rows=0 AND archive_trigger_status='PASS'
                     AND reproduction_status='PASS' AND source_registry_row_hash='03b6c0ca3af4ab9d196e09cefa59be3d'
                     AND row_hash IS NOT DISTINCT FROM md5((to_jsonb(snap)-'row_hash'-'created_at')::text) FROM snap)) AS pass_flag,
        'Direct persisted latest/archive reconstruction for component M2_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONSUMPTION; no Program 222 transaction-local helper is used.'::text AS interpretation
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_083_COMPONENT_11_M2_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_CONSUMPTION_PHYSICAL_REPRODUCTION */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    83::smallint,
    'M2_12_POS_083_COMPONENT_11_M2_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_CONSUMPTION_PHYSICAL_REPRODUCTION'::text,
    5::smallint,
    'LATEST_ARCHIVE_REPRODUCTION'::text,
    'Component 11 M2_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_CONSUMPTION latest/archive state reproduces directly from physical rows'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH ctx AS (
        SELECT module1_run_id FROM tmp_src_m2_12_validation_run_context
    ), cd AS (
        SELECT c.* FROM msbf_m2.module2_contract_component_snapshot c
        JOIN ctx ON ctx.module1_run_id=c.module1_run_id
        WHERE c.component_sequence=11 AND c.component_contract_code='M2_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_CONSUMPTION' AND c.contract_version=1
    ), obs AS (
        SELECT
            (SELECT count(*)::bigint FROM msbf_m2.application_payment_reconciliation_certification_latest l WHERE l.module1_run_id=ctx.module1_run_id) AS observed_latest_rows,
            (SELECT count(*)::bigint FROM msbf_m2.application_payment_reconciliation_certification_archive a WHERE a.module1_run_id=ctx.module1_run_id AND a.contract_version=cd.contract_version) AS observed_archive_rows,
            (SELECT md5(string_agg(l.scenario_id::text||'|'||l.merchant_application_id||'|'||l.contract_row_hash,'|' ORDER BY l.scenario_id,l.merchant_application_id)) FROM msbf_m2.application_payment_reconciliation_certification_latest l WHERE l.module1_run_id=ctx.module1_run_id)::text AS reconstructed_latest_set_hash,
            (SELECT md5(string_agg(a.scenario_id::text||'|'||a.merchant_application_id||'|'||a.archive_row_hash,'|' ORDER BY a.scenario_id,a.merchant_application_id)) FROM msbf_m2.application_payment_reconciliation_certification_archive a WHERE a.module1_run_id=ctx.module1_run_id AND a.contract_version=cd.contract_version)::text AS reconstructed_archive_set_hash,
            (SELECT count(*)::bigint FROM msbf_m2.application_payment_reconciliation_certification_latest l FULL JOIN msbf_m2.application_payment_reconciliation_certification_archive a ON a.module1_run_id=l.module1_run_id AND a.contract_version=l.contract_version AND a.scenario_id=l.scenario_id AND a.merchant_application_id=l.merchant_application_id WHERE coalesce(l.module1_run_id,a.module1_run_id)=ctx.module1_run_id AND l.module1_run_id IS NOT NULL AND a.module1_run_id IS NOT NULL AND ((a.contract_payload IS DISTINCT FROM (to_jsonb(l)-'created_at')) OR ((to_jsonb(a)-ARRAY['archive_id','contract_payload','archive_row_hash','archived_at','created_at']::text[]) IS DISTINCT FROM (to_jsonb(l)-'created_at')) OR (a.contract_row_hash IS DISTINCT FROM l.contract_row_hash) OR (l.contract_row_hash IS DISTINCT FROM msbf_ctl.m2_9_hash_jsonb(to_jsonb(l)-'contract_row_hash'-'created_at')) OR (a.archive_row_hash IS DISTINCT FROM msbf_ctl.m2_9_hash_jsonb(to_jsonb(a)-'archive_id'-'archive_row_hash'-'archived_at'-'created_at'))))::bigint AS payload_mismatch_count,
            (SELECT count(*)::bigint FROM msbf_m2.application_payment_reconciliation_certification_latest l FULL JOIN msbf_m2.application_payment_reconciliation_certification_archive a ON a.module1_run_id=l.module1_run_id AND a.contract_version=l.contract_version AND a.scenario_id=l.scenario_id AND a.merchant_application_id=l.merchant_application_id WHERE coalesce(l.module1_run_id,a.module1_run_id)=ctx.module1_run_id AND l.module1_run_id IS NULL)::bigint AS missing_latest_rows,
            (SELECT count(*)::bigint FROM msbf_m2.application_payment_reconciliation_certification_latest l FULL JOIN msbf_m2.application_payment_reconciliation_certification_archive a ON a.module1_run_id=l.module1_run_id AND a.contract_version=l.contract_version AND a.scenario_id=l.scenario_id AND a.merchant_application_id=l.merchant_application_id WHERE coalesce(l.module1_run_id,a.module1_run_id)=ctx.module1_run_id AND a.module1_run_id IS NULL)::bigint AS missing_archive_rows,
            (SELECT count(*)::bigint FROM (SELECT module1_run_id,scenario_id,merchant_application_id,count(*) c FROM msbf_m2.application_payment_reconciliation_certification_latest WHERE module1_run_id=ctx.module1_run_id GROUP BY module1_run_id,scenario_id,merchant_application_id HAVING count(*)>1) d)::bigint AS latest_duplicate_key_rows,
            (SELECT count(*)::bigint FROM (SELECT module1_run_id,contract_version,scenario_id,merchant_application_id,count(*) c FROM msbf_m2.application_payment_reconciliation_certification_archive WHERE module1_run_id=ctx.module1_run_id AND contract_version=cd.contract_version GROUP BY module1_run_id,contract_version,scenario_id,merchant_application_id HAVING count(*)>1) d)::bigint AS archive_duplicate_key_rows,
            CASE WHEN (SELECT count(*) FROM pg_catalog.pg_trigger t WHERE t.tgrelid='msbf_m2.application_payment_reconciliation_certification_archive'::regclass AND NOT t.tgisinternal AND t.tgname='trg_m2_9_archive_immutable' AND (t.tgtype & 8)=8 AND (t.tgtype & 16)=16 AND t.tgenabled IN ('O','A'))=1 THEN 'PASS' ELSE 'FAIL' END::text::text AS archive_trigger_status
        FROM ctx CROSS JOIN cd
    ), snap AS (
        SELECT r.* FROM msbf_m2.module2_contract_reproduction_snapshot r
        JOIN ctx ON ctx.module1_run_id=r.module1_run_id
        WHERE r.component_sequence=11 AND r.component_contract_code='M2_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_CONSUMPTION' AND r.contract_version=1
    )
    SELECT
        concat_ws('|',(SELECT observed_latest_rows FROM obs),(SELECT observed_archive_rows FROM obs),
          (SELECT reconstructed_latest_set_hash FROM obs),(SELECT reconstructed_archive_set_hash FROM obs),
          (SELECT payload_mismatch_count FROM obs),(SELECT missing_latest_rows FROM obs),(SELECT missing_archive_rows FROM obs),
          (SELECT latest_duplicate_key_rows FROM obs),(SELECT archive_duplicate_key_rows FROM obs),(SELECT archive_trigger_status FROM obs),
          (SELECT count(*) FROM snap),(SELECT min(reproduction_status) FROM snap)) AS observed_value,
        '59|59|e1206bb355dac10fa8d97a81637ce965|0bbe110652afd2a01378d36c596e4379|0|0|0|0|0|PASS|1|PASS'::text AS expected_value,
        (CASE WHEN (SELECT count(*) FROM cd)=1 AND (SELECT count(*) FROM obs)=1 AND (SELECT count(*) FROM snap)=1
                   AND (SELECT observed_latest_rows=59 AND observed_archive_rows=59
                               AND reconstructed_latest_set_hash='e1206bb355dac10fa8d97a81637ce965'
                               AND reconstructed_archive_set_hash='0bbe110652afd2a01378d36c596e4379'
                               AND payload_mismatch_count=0 AND missing_latest_rows=0 AND missing_archive_rows=0
                               AND latest_duplicate_key_rows=0 AND archive_duplicate_key_rows=0 AND archive_trigger_status='PASS' FROM obs)
                   AND (SELECT observed_latest_rows=59 AND observed_archive_rows=59
                               AND observed_latest_set_hash='e1206bb355dac10fa8d97a81637ce965' AND observed_archive_set_hash='0bbe110652afd2a01378d36c596e4379'
                               AND payload_mismatch_count=0 AND missing_latest_rows=0 AND missing_archive_rows=0
                               AND latest_duplicate_key_rows=0 AND archive_duplicate_key_rows=0 AND archive_trigger_status='PASS'
                               AND reproduction_status='PASS' AND source_registry_row_hash='6df16ccd5d6d7f7bffbc0ca4a2539140'
                               AND row_hash IS NOT DISTINCT FROM md5((to_jsonb(snap)-'row_hash'-'created_at')::text) FROM snap)
              THEN 0 ELSE 1 END)::bigint AS mismatch_count,
        ((SELECT count(*) FROM cd)=1 AND (SELECT count(*) FROM obs)=1 AND (SELECT count(*) FROM snap)=1
         AND (SELECT observed_latest_rows=59 AND observed_archive_rows=59
                     AND reconstructed_latest_set_hash='e1206bb355dac10fa8d97a81637ce965'
                     AND reconstructed_archive_set_hash='0bbe110652afd2a01378d36c596e4379'
                     AND payload_mismatch_count=0 AND missing_latest_rows=0 AND missing_archive_rows=0
                     AND latest_duplicate_key_rows=0 AND archive_duplicate_key_rows=0 AND archive_trigger_status='PASS' FROM obs)
         AND (SELECT observed_latest_rows=59 AND observed_archive_rows=59
                     AND observed_latest_set_hash='e1206bb355dac10fa8d97a81637ce965' AND observed_archive_set_hash='0bbe110652afd2a01378d36c596e4379'
                     AND payload_mismatch_count=0 AND missing_latest_rows=0 AND missing_archive_rows=0
                     AND latest_duplicate_key_rows=0 AND archive_duplicate_key_rows=0 AND archive_trigger_status='PASS'
                     AND reproduction_status='PASS' AND source_registry_row_hash='6df16ccd5d6d7f7bffbc0ca4a2539140'
                     AND row_hash IS NOT DISTINCT FROM md5((to_jsonb(snap)-'row_hash'-'created_at')::text) FROM snap)) AS pass_flag,
        'Direct persisted latest/archive reconstruction for component M2_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_CONSUMPTION; no Program 222 transaction-local helper is used.'::text AS interpretation
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_084_COMPONENT_12_M2_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_CONSUMPTION_PHYSICAL_REPRODUCTION */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    84::smallint,
    'M2_12_POS_084_COMPONENT_12_M2_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_CONSUMPTION_PHYSICAL_REPRODUCTION'::text,
    5::smallint,
    'LATEST_ARCHIVE_REPRODUCTION'::text,
    'Component 12 M2_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_CONSUMPTION latest/archive state reproduces directly from physical rows'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH ctx AS (
        SELECT module1_run_id FROM tmp_src_m2_12_validation_run_context
    ), cd AS (
        SELECT c.* FROM msbf_m2.module2_contract_component_snapshot c
        JOIN ctx ON ctx.module1_run_id=c.module1_run_id
        WHERE c.component_sequence=12 AND c.component_contract_code='M2_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_CONSUMPTION' AND c.contract_version=1
    ), obs AS (
        SELECT
            (SELECT count(*)::bigint FROM msbf_m2.application_portfolio_performance_latest l WHERE l.module1_run_id=ctx.module1_run_id) AS observed_latest_rows,
            (SELECT count(*)::bigint FROM msbf_m2.application_portfolio_performance_archive a WHERE a.module1_run_id=ctx.module1_run_id AND a.contract_version=cd.contract_version) AS observed_archive_rows,
            (SELECT md5(string_agg(l.scenario_id::text||'|'||l.merchant_application_id||'|'||l.contract_row_hash,'|' ORDER BY l.scenario_id,l.merchant_application_id)) FROM msbf_m2.application_portfolio_performance_latest l WHERE l.module1_run_id=ctx.module1_run_id)::text AS reconstructed_latest_set_hash,
            (SELECT md5(string_agg(a.scenario_id::text||'|'||a.merchant_application_id||'|'||a.archive_row_hash,'|' ORDER BY a.scenario_id,a.merchant_application_id)) FROM msbf_m2.application_portfolio_performance_archive a WHERE a.module1_run_id=ctx.module1_run_id AND a.contract_version=cd.contract_version)::text AS reconstructed_archive_set_hash,
            (SELECT count(*)::bigint FROM msbf_m2.application_portfolio_performance_latest l FULL JOIN msbf_m2.application_portfolio_performance_archive a ON a.module1_run_id=l.module1_run_id AND a.contract_version=l.contract_version AND a.scenario_id=l.scenario_id AND a.merchant_application_id=l.merchant_application_id WHERE coalesce(l.module1_run_id,a.module1_run_id)=ctx.module1_run_id AND l.module1_run_id IS NOT NULL AND a.module1_run_id IS NOT NULL AND ((a.contract_payload IS DISTINCT FROM (to_jsonb(l)-'created_at')) OR ((to_jsonb(a)-ARRAY['archive_id','contract_payload','archive_row_hash','archived_at','created_at']::text[]) IS DISTINCT FROM (to_jsonb(l)-'created_at')) OR (a.contract_row_hash IS DISTINCT FROM l.contract_row_hash) OR (l.contract_row_hash IS DISTINCT FROM msbf_ctl.m2_10_hash_jsonb(to_jsonb(l)-'contract_row_hash'-'created_at')) OR (a.archive_row_hash IS DISTINCT FROM msbf_ctl.m2_10_hash_jsonb(to_jsonb(a)-'archive_id'-'archive_row_hash'-'archived_at'-'created_at'))))::bigint AS payload_mismatch_count,
            (SELECT count(*)::bigint FROM msbf_m2.application_portfolio_performance_latest l FULL JOIN msbf_m2.application_portfolio_performance_archive a ON a.module1_run_id=l.module1_run_id AND a.contract_version=l.contract_version AND a.scenario_id=l.scenario_id AND a.merchant_application_id=l.merchant_application_id WHERE coalesce(l.module1_run_id,a.module1_run_id)=ctx.module1_run_id AND l.module1_run_id IS NULL)::bigint AS missing_latest_rows,
            (SELECT count(*)::bigint FROM msbf_m2.application_portfolio_performance_latest l FULL JOIN msbf_m2.application_portfolio_performance_archive a ON a.module1_run_id=l.module1_run_id AND a.contract_version=l.contract_version AND a.scenario_id=l.scenario_id AND a.merchant_application_id=l.merchant_application_id WHERE coalesce(l.module1_run_id,a.module1_run_id)=ctx.module1_run_id AND a.module1_run_id IS NULL)::bigint AS missing_archive_rows,
            (SELECT count(*)::bigint FROM (SELECT module1_run_id,scenario_id,merchant_application_id,count(*) c FROM msbf_m2.application_portfolio_performance_latest WHERE module1_run_id=ctx.module1_run_id GROUP BY module1_run_id,scenario_id,merchant_application_id HAVING count(*)>1) d)::bigint AS latest_duplicate_key_rows,
            (SELECT count(*)::bigint FROM (SELECT module1_run_id,contract_version,scenario_id,merchant_application_id,count(*) c FROM msbf_m2.application_portfolio_performance_archive WHERE module1_run_id=ctx.module1_run_id AND contract_version=cd.contract_version GROUP BY module1_run_id,contract_version,scenario_id,merchant_application_id HAVING count(*)>1) d)::bigint AS archive_duplicate_key_rows,
            CASE WHEN (SELECT count(*) FROM pg_catalog.pg_trigger t WHERE t.tgrelid='msbf_m2.application_portfolio_performance_archive'::regclass AND NOT t.tgisinternal AND t.tgname='trg_m2_10_portfolio_archive_immutable' AND (t.tgtype & 8)=8 AND (t.tgtype & 16)=16 AND t.tgenabled IN ('O','A'))=1 THEN 'PASS' ELSE 'FAIL' END::text::text AS archive_trigger_status
        FROM ctx CROSS JOIN cd
    ), snap AS (
        SELECT r.* FROM msbf_m2.module2_contract_reproduction_snapshot r
        JOIN ctx ON ctx.module1_run_id=r.module1_run_id
        WHERE r.component_sequence=12 AND r.component_contract_code='M2_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_CONSUMPTION' AND r.contract_version=1
    )
    SELECT
        concat_ws('|',(SELECT observed_latest_rows FROM obs),(SELECT observed_archive_rows FROM obs),
          (SELECT reconstructed_latest_set_hash FROM obs),(SELECT reconstructed_archive_set_hash FROM obs),
          (SELECT payload_mismatch_count FROM obs),(SELECT missing_latest_rows FROM obs),(SELECT missing_archive_rows FROM obs),
          (SELECT latest_duplicate_key_rows FROM obs),(SELECT archive_duplicate_key_rows FROM obs),(SELECT archive_trigger_status FROM obs),
          (SELECT count(*) FROM snap),(SELECT min(reproduction_status) FROM snap)) AS observed_value,
        '59|59|c34f6721bd7a6818d2492d564611ef2a|105691ceca00acc516296b19a64a1c25|0|0|0|0|0|PASS|1|PASS'::text AS expected_value,
        (CASE WHEN (SELECT count(*) FROM cd)=1 AND (SELECT count(*) FROM obs)=1 AND (SELECT count(*) FROM snap)=1
                   AND (SELECT observed_latest_rows=59 AND observed_archive_rows=59
                               AND reconstructed_latest_set_hash='c34f6721bd7a6818d2492d564611ef2a'
                               AND reconstructed_archive_set_hash='105691ceca00acc516296b19a64a1c25'
                               AND payload_mismatch_count=0 AND missing_latest_rows=0 AND missing_archive_rows=0
                               AND latest_duplicate_key_rows=0 AND archive_duplicate_key_rows=0 AND archive_trigger_status='PASS' FROM obs)
                   AND (SELECT observed_latest_rows=59 AND observed_archive_rows=59
                               AND observed_latest_set_hash='c34f6721bd7a6818d2492d564611ef2a' AND observed_archive_set_hash='105691ceca00acc516296b19a64a1c25'
                               AND payload_mismatch_count=0 AND missing_latest_rows=0 AND missing_archive_rows=0
                               AND latest_duplicate_key_rows=0 AND archive_duplicate_key_rows=0 AND archive_trigger_status='PASS'
                               AND reproduction_status='PASS' AND source_registry_row_hash='944d8f676a5b7fb58700b2a66309f428'
                               AND row_hash IS NOT DISTINCT FROM md5((to_jsonb(snap)-'row_hash'-'created_at')::text) FROM snap)
              THEN 0 ELSE 1 END)::bigint AS mismatch_count,
        ((SELECT count(*) FROM cd)=1 AND (SELECT count(*) FROM obs)=1 AND (SELECT count(*) FROM snap)=1
         AND (SELECT observed_latest_rows=59 AND observed_archive_rows=59
                     AND reconstructed_latest_set_hash='c34f6721bd7a6818d2492d564611ef2a'
                     AND reconstructed_archive_set_hash='105691ceca00acc516296b19a64a1c25'
                     AND payload_mismatch_count=0 AND missing_latest_rows=0 AND missing_archive_rows=0
                     AND latest_duplicate_key_rows=0 AND archive_duplicate_key_rows=0 AND archive_trigger_status='PASS' FROM obs)
         AND (SELECT observed_latest_rows=59 AND observed_archive_rows=59
                     AND observed_latest_set_hash='c34f6721bd7a6818d2492d564611ef2a' AND observed_archive_set_hash='105691ceca00acc516296b19a64a1c25'
                     AND payload_mismatch_count=0 AND missing_latest_rows=0 AND missing_archive_rows=0
                     AND latest_duplicate_key_rows=0 AND archive_duplicate_key_rows=0 AND archive_trigger_status='PASS'
                     AND reproduction_status='PASS' AND source_registry_row_hash='944d8f676a5b7fb58700b2a66309f428'
                     AND row_hash IS NOT DISTINCT FROM md5((to_jsonb(snap)-'row_hash'-'created_at')::text) FROM snap)) AS pass_flag,
        'Direct persisted latest/archive reconstruction for component M2_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_CONSUMPTION; no Program 222 transaction-local helper is used.'::text AS interpretation
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_085_COMPONENT_13_M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION_PHYSICAL_REPRODUCTION */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    85::smallint,
    'M2_12_POS_085_COMPONENT_13_M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION_PHYSICAL_REPRODUCTION'::text,
    5::smallint,
    'LATEST_ARCHIVE_REPRODUCTION'::text,
    'Component 13 M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION latest/archive state reproduces directly from physical rows'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH ctx AS (
        SELECT module1_run_id FROM tmp_src_m2_12_validation_run_context
    ), cd AS (
        SELECT c.* FROM msbf_m2.module2_contract_component_snapshot c
        JOIN ctx ON ctx.module1_run_id=c.module1_run_id
        WHERE c.component_sequence=13 AND c.component_contract_code='M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION' AND c.contract_version=1
    ), obs AS (
        SELECT
            (SELECT count(*)::bigint FROM msbf_m2.portfolio_strategy_simulation_latest l WHERE l.module1_run_id=ctx.module1_run_id) AS observed_latest_rows,
            (SELECT count(*)::bigint FROM msbf_m2.portfolio_strategy_simulation_archive a WHERE a.module1_run_id=ctx.module1_run_id AND a.contract_version=cd.contract_version) AS observed_archive_rows,
            (SELECT md5(string_agg(msbf_ctl.m2_11_hash_jsonb(to_jsonb(l)-'contract_row_hash'-'created_at'),'|' ORDER BY l.module1_run_id,l.reporting_scope_code,l.strategy_profile_code)) FROM msbf_m2.portfolio_strategy_simulation_latest l WHERE l.module1_run_id=ctx.module1_run_id)::text AS reconstructed_latest_set_hash,
            (SELECT md5(string_agg(msbf_ctl.m2_11_hash_jsonb(jsonb_build_object('module1_run_id',a.module1_run_id,'contract_code',a.contract_code,'contract_version',a.contract_version,'strategy_profile_code',a.strategy_profile_code,'reporting_scope_code',a.reporting_scope_code,'contract_payload',a.contract_payload,'source_latest_row_hash',a.contract_row_hash)),'|' ORDER BY a.module1_run_id,a.contract_version,a.reporting_scope_code,a.strategy_profile_code)) FROM msbf_m2.portfolio_strategy_simulation_archive a WHERE a.module1_run_id=ctx.module1_run_id AND a.contract_version=cd.contract_version)::text AS reconstructed_archive_set_hash,
            (SELECT count(*)::bigint FROM msbf_m2.portfolio_strategy_simulation_latest l FULL JOIN msbf_m2.portfolio_strategy_simulation_archive a ON a.module1_run_id=l.module1_run_id AND a.contract_version=l.contract_version AND a.strategy_profile_code=l.strategy_profile_code AND a.reporting_scope_code=l.reporting_scope_code WHERE coalesce(l.module1_run_id,a.module1_run_id)=ctx.module1_run_id AND l.module1_run_id IS NOT NULL AND a.module1_run_id IS NOT NULL AND ((a.contract_payload IS DISTINCT FROM (to_jsonb(l)-'created_at')) OR (a.contract_row_hash IS DISTINCT FROM l.contract_row_hash) OR (l.contract_row_hash IS DISTINCT FROM msbf_ctl.m2_11_hash_jsonb(to_jsonb(l)-'contract_row_hash'-'created_at')) OR (a.archive_row_hash IS DISTINCT FROM msbf_ctl.m2_11_hash_jsonb(jsonb_build_object('module1_run_id',a.module1_run_id,'contract_code',a.contract_code,'contract_version',a.contract_version,'strategy_profile_code',a.strategy_profile_code,'reporting_scope_code',a.reporting_scope_code,'contract_payload',a.contract_payload,'source_latest_row_hash',a.contract_row_hash)))))::bigint AS payload_mismatch_count,
            (SELECT count(*)::bigint FROM msbf_m2.portfolio_strategy_simulation_latest l FULL JOIN msbf_m2.portfolio_strategy_simulation_archive a ON a.module1_run_id=l.module1_run_id AND a.contract_version=l.contract_version AND a.strategy_profile_code=l.strategy_profile_code AND a.reporting_scope_code=l.reporting_scope_code WHERE coalesce(l.module1_run_id,a.module1_run_id)=ctx.module1_run_id AND l.module1_run_id IS NULL)::bigint AS missing_latest_rows,
            (SELECT count(*)::bigint FROM msbf_m2.portfolio_strategy_simulation_latest l FULL JOIN msbf_m2.portfolio_strategy_simulation_archive a ON a.module1_run_id=l.module1_run_id AND a.contract_version=l.contract_version AND a.strategy_profile_code=l.strategy_profile_code AND a.reporting_scope_code=l.reporting_scope_code WHERE coalesce(l.module1_run_id,a.module1_run_id)=ctx.module1_run_id AND a.module1_run_id IS NULL)::bigint AS missing_archive_rows,
            (SELECT count(*)::bigint FROM (SELECT module1_run_id,strategy_profile_code,reporting_scope_code,count(*) c FROM msbf_m2.portfolio_strategy_simulation_latest WHERE module1_run_id=ctx.module1_run_id GROUP BY module1_run_id,strategy_profile_code,reporting_scope_code HAVING count(*)>1) d)::bigint AS latest_duplicate_key_rows,
            (SELECT count(*)::bigint FROM (SELECT module1_run_id,contract_version,strategy_profile_code,reporting_scope_code,count(*) c FROM msbf_m2.portfolio_strategy_simulation_archive WHERE module1_run_id=ctx.module1_run_id AND contract_version=cd.contract_version GROUP BY module1_run_id,contract_version,strategy_profile_code,reporting_scope_code HAVING count(*)>1) d)::bigint AS archive_duplicate_key_rows,
            CASE WHEN (SELECT count(*) FROM pg_catalog.pg_trigger t WHERE t.tgrelid='msbf_m2.portfolio_strategy_simulation_archive'::regclass AND NOT t.tgisinternal AND t.tgname='trg_m2_11_archive_immutable' AND (t.tgtype & 8)=8 AND (t.tgtype & 16)=16 AND t.tgenabled IN ('O','A'))=1 THEN 'PASS' ELSE 'FAIL' END::text::text AS archive_trigger_status
        FROM ctx CROSS JOIN cd
    ), snap AS (
        SELECT r.* FROM msbf_m2.module2_contract_reproduction_snapshot r
        JOIN ctx ON ctx.module1_run_id=r.module1_run_id
        WHERE r.component_sequence=13 AND r.component_contract_code='M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION' AND r.contract_version=1
    )
    SELECT
        concat_ws('|',(SELECT observed_latest_rows FROM obs),(SELECT observed_archive_rows FROM obs),
          (SELECT reconstructed_latest_set_hash FROM obs),(SELECT reconstructed_archive_set_hash FROM obs),
          (SELECT payload_mismatch_count FROM obs),(SELECT missing_latest_rows FROM obs),(SELECT missing_archive_rows FROM obs),
          (SELECT latest_duplicate_key_rows FROM obs),(SELECT archive_duplicate_key_rows FROM obs),(SELECT archive_trigger_status FROM obs),
          (SELECT count(*) FROM snap),(SELECT min(reproduction_status) FROM snap)) AS observed_value,
        '24|24|634a9894d0241505582e0d89e4c5f27b|641deff3b776faa419cc6c0489f85024|0|0|0|0|0|PASS|1|PASS'::text AS expected_value,
        (CASE WHEN (SELECT count(*) FROM cd)=1 AND (SELECT count(*) FROM obs)=1 AND (SELECT count(*) FROM snap)=1
                   AND (SELECT observed_latest_rows=24 AND observed_archive_rows=24
                               AND reconstructed_latest_set_hash='634a9894d0241505582e0d89e4c5f27b'
                               AND reconstructed_archive_set_hash='641deff3b776faa419cc6c0489f85024'
                               AND payload_mismatch_count=0 AND missing_latest_rows=0 AND missing_archive_rows=0
                               AND latest_duplicate_key_rows=0 AND archive_duplicate_key_rows=0 AND archive_trigger_status='PASS' FROM obs)
                   AND (SELECT observed_latest_rows=24 AND observed_archive_rows=24
                               AND observed_latest_set_hash='634a9894d0241505582e0d89e4c5f27b' AND observed_archive_set_hash='641deff3b776faa419cc6c0489f85024'
                               AND payload_mismatch_count=0 AND missing_latest_rows=0 AND missing_archive_rows=0
                               AND latest_duplicate_key_rows=0 AND archive_duplicate_key_rows=0 AND archive_trigger_status='PASS'
                               AND reproduction_status='PASS' AND source_registry_row_hash='61c22f4f3f2e99905d05958fddf80671'
                               AND row_hash IS NOT DISTINCT FROM md5((to_jsonb(snap)-'row_hash'-'created_at')::text) FROM snap)
              THEN 0 ELSE 1 END)::bigint AS mismatch_count,
        ((SELECT count(*) FROM cd)=1 AND (SELECT count(*) FROM obs)=1 AND (SELECT count(*) FROM snap)=1
         AND (SELECT observed_latest_rows=24 AND observed_archive_rows=24
                     AND reconstructed_latest_set_hash='634a9894d0241505582e0d89e4c5f27b'
                     AND reconstructed_archive_set_hash='641deff3b776faa419cc6c0489f85024'
                     AND payload_mismatch_count=0 AND missing_latest_rows=0 AND missing_archive_rows=0
                     AND latest_duplicate_key_rows=0 AND archive_duplicate_key_rows=0 AND archive_trigger_status='PASS' FROM obs)
         AND (SELECT observed_latest_rows=24 AND observed_archive_rows=24
                     AND observed_latest_set_hash='634a9894d0241505582e0d89e4c5f27b' AND observed_archive_set_hash='641deff3b776faa419cc6c0489f85024'
                     AND payload_mismatch_count=0 AND missing_latest_rows=0 AND missing_archive_rows=0
                     AND latest_duplicate_key_rows=0 AND archive_duplicate_key_rows=0 AND archive_trigger_status='PASS'
                     AND reproduction_status='PASS' AND source_registry_row_hash='61c22f4f3f2e99905d05958fddf80671'
                     AND row_hash IS NOT DISTINCT FROM md5((to_jsonb(snap)-'row_hash'-'created_at')::text) FROM snap)) AS pass_flag,
        'Direct persisted latest/archive reconstruction for component M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION; no Program 222 transaction-local helper is used.'::text AS interpretation
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_086_NODE_01_M1_17_G2_FOUNDATION_PHYSICAL_EDGES */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    86::smallint,
    'M2_12_POS_086_NODE_01_M1_17_G2_FOUNDATION_PHYSICAL_EDGES'::text,
    6::smallint,
    'SOURCE_GRAPH'::text,
    'Node 01 M1_17_G2_FOUNDATION has its exact independently reconstructed physical source-edge set'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH e AS (
        SELECT * FROM tmp_eval_m2_12_validation_source_edges WHERE target_node_code='M1_17_G2_FOUNDATION'
    )
    SELECT
        concat_ws('|',count(*),count(DISTINCT edge_sequence),array_agg(edge_code ORDER BY edge_sequence)::text,
            array_agg(expected_source_hash ORDER BY edge_sequence)::text,
            count(*) FILTER (WHERE edge_status<>'PASS' OR source_registry_row_count<>1 OR target_registry_row_count<>1
                                  OR source_gate_status<>'PASS' OR source_hash_mismatch_flag OR target_hash_mismatch_flag)) AS observed_value,
        concat_ws('|',2,2,ARRAY['M1_15_TO_M1_17_APPLICATION_CONTRACT','M1_16_TO_M1_17_ACQUISITION_CONTRACT']::text[]::text,ARRAY['fcd2704e17ec0d2e73191ea36061d74b','86df51a0ca68d84096d00ff0f1b19f33']::text[]::text,0) AS expected_value,
        (CASE WHEN count(*)=2 AND count(DISTINCT edge_sequence)=2
                   AND array_agg(edge_code ORDER BY edge_sequence)=ARRAY['M1_15_TO_M1_17_APPLICATION_CONTRACT','M1_16_TO_M1_17_ACQUISITION_CONTRACT']::text[]
                   AND array_agg(expected_source_hash ORDER BY edge_sequence)=ARRAY['fcd2704e17ec0d2e73191ea36061d74b','86df51a0ca68d84096d00ff0f1b19f33']::text[]
                   AND count(*) FILTER (WHERE edge_status<>'PASS' OR source_registry_row_count<>1 OR target_registry_row_count<>1
                                            OR source_gate_status<>'PASS' OR source_hash_mismatch_flag OR target_hash_mismatch_flag)=0
              THEN 0 ELSE 1 END)::bigint AS mismatch_count,
        (count(*)=2 AND count(DISTINCT edge_sequence)=2
         AND array_agg(edge_code ORDER BY edge_sequence)=ARRAY['M1_15_TO_M1_17_APPLICATION_CONTRACT','M1_16_TO_M1_17_ACQUISITION_CONTRACT']::text[]
         AND array_agg(expected_source_hash ORDER BY edge_sequence)=ARRAY['fcd2704e17ec0d2e73191ea36061d74b','86df51a0ca68d84096d00ff0f1b19f33']::text[]
         AND count(*) FILTER (WHERE edge_status<>'PASS' OR source_registry_row_count<>1 OR target_registry_row_count<>1
                                   OR source_gate_status<>'PASS' OR source_hash_mismatch_flag OR target_hash_mismatch_flag)=0) AS pass_flag,
        'Physical source graph reconstruction for target node M1_17_G2_FOUNDATION.'::text AS interpretation
    FROM e
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_087_NODE_02_M2_1_ELIGIBILITY_ROUTING_PHYSICAL_EDGES */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    87::smallint,
    'M2_12_POS_087_NODE_02_M2_1_ELIGIBILITY_ROUTING_PHYSICAL_EDGES'::text,
    6::smallint,
    'SOURCE_GRAPH'::text,
    'Node 02 M2_1_ELIGIBILITY_ROUTING has its exact independently reconstructed physical source-edge set'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH e AS (
        SELECT * FROM tmp_eval_m2_12_validation_source_edges WHERE target_node_code='M2_1_ELIGIBILITY_ROUTING'
    )
    SELECT
        concat_ws('|',count(*),count(DISTINCT edge_sequence),array_agg(edge_code ORDER BY edge_sequence)::text,
            array_agg(expected_source_hash ORDER BY edge_sequence)::text,
            count(*) FILTER (WHERE edge_status<>'PASS' OR source_registry_row_count<>1 OR target_registry_row_count<>1
                                  OR source_gate_status<>'PASS' OR source_hash_mismatch_flag OR target_hash_mismatch_flag)) AS observed_value,
        concat_ws('|',1,1,ARRAY['M1_17_TO_M2_1']::text[]::text,ARRAY['7d9e466da28cad2551aa99c4c40c912b']::text[]::text,0) AS expected_value,
        (CASE WHEN count(*)=1 AND count(DISTINCT edge_sequence)=1
                   AND array_agg(edge_code ORDER BY edge_sequence)=ARRAY['M1_17_TO_M2_1']::text[]
                   AND array_agg(expected_source_hash ORDER BY edge_sequence)=ARRAY['7d9e466da28cad2551aa99c4c40c912b']::text[]
                   AND count(*) FILTER (WHERE edge_status<>'PASS' OR source_registry_row_count<>1 OR target_registry_row_count<>1
                                            OR source_gate_status<>'PASS' OR source_hash_mismatch_flag OR target_hash_mismatch_flag)=0
              THEN 0 ELSE 1 END)::bigint AS mismatch_count,
        (count(*)=1 AND count(DISTINCT edge_sequence)=1
         AND array_agg(edge_code ORDER BY edge_sequence)=ARRAY['M1_17_TO_M2_1']::text[]
         AND array_agg(expected_source_hash ORDER BY edge_sequence)=ARRAY['7d9e466da28cad2551aa99c4c40c912b']::text[]
         AND count(*) FILTER (WHERE edge_status<>'PASS' OR source_registry_row_count<>1 OR target_registry_row_count<>1
                                   OR source_gate_status<>'PASS' OR source_hash_mismatch_flag OR target_hash_mismatch_flag)=0) AS pass_flag,
        'Physical source graph reconstruction for target node M2_1_ELIGIBILITY_ROUTING.'::text AS interpretation
    FROM e
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_088_NODE_03_M2_2_PRICING_STRUCTURE_PHYSICAL_EDGES */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    88::smallint,
    'M2_12_POS_088_NODE_03_M2_2_PRICING_STRUCTURE_PHYSICAL_EDGES'::text,
    6::smallint,
    'SOURCE_GRAPH'::text,
    'Node 03 M2_2_PRICING_STRUCTURE has its exact independently reconstructed physical source-edge set'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH e AS (
        SELECT * FROM tmp_eval_m2_12_validation_source_edges WHERE target_node_code='M2_2_PRICING_STRUCTURE'
    )
    SELECT
        concat_ws('|',count(*),count(DISTINCT edge_sequence),array_agg(edge_code ORDER BY edge_sequence)::text,
            array_agg(expected_source_hash ORDER BY edge_sequence)::text,
            count(*) FILTER (WHERE edge_status<>'PASS' OR source_registry_row_count<>1 OR target_registry_row_count<>1
                                  OR source_gate_status<>'PASS' OR source_hash_mismatch_flag OR target_hash_mismatch_flag)) AS observed_value,
        concat_ws('|',2,2,ARRAY['M2_1_TO_M2_2','M1_3_TO_M2_2_REQUEST_AUTHORITY']::text[]::text,ARRAY['e5ace7f32060ffb191c7bd0f8dd0c863','01485256b9b5748fb412743d35ced602']::text[]::text,0) AS expected_value,
        (CASE WHEN count(*)=2 AND count(DISTINCT edge_sequence)=2
                   AND array_agg(edge_code ORDER BY edge_sequence)=ARRAY['M2_1_TO_M2_2','M1_3_TO_M2_2_REQUEST_AUTHORITY']::text[]
                   AND array_agg(expected_source_hash ORDER BY edge_sequence)=ARRAY['e5ace7f32060ffb191c7bd0f8dd0c863','01485256b9b5748fb412743d35ced602']::text[]
                   AND count(*) FILTER (WHERE edge_status<>'PASS' OR source_registry_row_count<>1 OR target_registry_row_count<>1
                                            OR source_gate_status<>'PASS' OR source_hash_mismatch_flag OR target_hash_mismatch_flag)=0
              THEN 0 ELSE 1 END)::bigint AS mismatch_count,
        (count(*)=2 AND count(DISTINCT edge_sequence)=2
         AND array_agg(edge_code ORDER BY edge_sequence)=ARRAY['M2_1_TO_M2_2','M1_3_TO_M2_2_REQUEST_AUTHORITY']::text[]
         AND array_agg(expected_source_hash ORDER BY edge_sequence)=ARRAY['e5ace7f32060ffb191c7bd0f8dd0c863','01485256b9b5748fb412743d35ced602']::text[]
         AND count(*) FILTER (WHERE edge_status<>'PASS' OR source_registry_row_count<>1 OR target_registry_row_count<>1
                                   OR source_gate_status<>'PASS' OR source_hash_mismatch_flag OR target_hash_mismatch_flag)=0) AS pass_flag,
        'Physical source graph reconstruction for target node M2_2_PRICING_STRUCTURE.'::text AS interpretation
    FROM e
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_089_NODE_04_M2_3_FINAL_DECISION_PHYSICAL_EDGES */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    89::smallint,
    'M2_12_POS_089_NODE_04_M2_3_FINAL_DECISION_PHYSICAL_EDGES'::text,
    6::smallint,
    'SOURCE_GRAPH'::text,
    'Node 04 M2_3_FINAL_DECISION has its exact independently reconstructed physical source-edge set'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH e AS (
        SELECT * FROM tmp_eval_m2_12_validation_source_edges WHERE target_node_code='M2_3_FINAL_DECISION'
    )
    SELECT
        concat_ws('|',count(*),count(DISTINCT edge_sequence),array_agg(edge_code ORDER BY edge_sequence)::text,
            array_agg(expected_source_hash ORDER BY edge_sequence)::text,
            count(*) FILTER (WHERE edge_status<>'PASS' OR source_registry_row_count<>1 OR target_registry_row_count<>1
                                  OR source_gate_status<>'PASS' OR source_hash_mismatch_flag OR target_hash_mismatch_flag)) AS observed_value,
        concat_ws('|',1,1,ARRAY['M2_2_TO_M2_3']::text[]::text,ARRAY['bbe83b187b31ea561789797322031fc6']::text[]::text,0) AS expected_value,
        (CASE WHEN count(*)=1 AND count(DISTINCT edge_sequence)=1
                   AND array_agg(edge_code ORDER BY edge_sequence)=ARRAY['M2_2_TO_M2_3']::text[]
                   AND array_agg(expected_source_hash ORDER BY edge_sequence)=ARRAY['bbe83b187b31ea561789797322031fc6']::text[]
                   AND count(*) FILTER (WHERE edge_status<>'PASS' OR source_registry_row_count<>1 OR target_registry_row_count<>1
                                            OR source_gate_status<>'PASS' OR source_hash_mismatch_flag OR target_hash_mismatch_flag)=0
              THEN 0 ELSE 1 END)::bigint AS mismatch_count,
        (count(*)=1 AND count(DISTINCT edge_sequence)=1
         AND array_agg(edge_code ORDER BY edge_sequence)=ARRAY['M2_2_TO_M2_3']::text[]
         AND array_agg(expected_source_hash ORDER BY edge_sequence)=ARRAY['bbe83b187b31ea561789797322031fc6']::text[]
         AND count(*) FILTER (WHERE edge_status<>'PASS' OR source_registry_row_count<>1 OR target_registry_row_count<>1
                                   OR source_gate_status<>'PASS' OR source_hash_mismatch_flag OR target_hash_mismatch_flag)=0) AS pass_flag,
        'Physical source graph reconstruction for target node M2_3_FINAL_DECISION.'::text AS interpretation
    FROM e
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_090_NODE_05_M2_4_PORTFOLIO_ACTIVATION_PHYSICAL_EDGES */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    90::smallint,
    'M2_12_POS_090_NODE_05_M2_4_PORTFOLIO_ACTIVATION_PHYSICAL_EDGES'::text,
    6::smallint,
    'SOURCE_GRAPH'::text,
    'Node 05 M2_4_PORTFOLIO_ACTIVATION has its exact independently reconstructed physical source-edge set'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH e AS (
        SELECT * FROM tmp_eval_m2_12_validation_source_edges WHERE target_node_code='M2_4_PORTFOLIO_ACTIVATION'
    )
    SELECT
        concat_ws('|',count(*),count(DISTINCT edge_sequence),array_agg(edge_code ORDER BY edge_sequence)::text,
            array_agg(expected_source_hash ORDER BY edge_sequence)::text,
            count(*) FILTER (WHERE edge_status<>'PASS' OR source_registry_row_count<>1 OR target_registry_row_count<>1
                                  OR source_gate_status<>'PASS' OR source_hash_mismatch_flag OR target_hash_mismatch_flag)) AS observed_value,
        concat_ws('|',1,1,ARRAY['M2_3_TO_M2_4']::text[]::text,ARRAY['bf09349b06ede7e5a2ec830c2f9ffe90']::text[]::text,0) AS expected_value,
        (CASE WHEN count(*)=1 AND count(DISTINCT edge_sequence)=1
                   AND array_agg(edge_code ORDER BY edge_sequence)=ARRAY['M2_3_TO_M2_4']::text[]
                   AND array_agg(expected_source_hash ORDER BY edge_sequence)=ARRAY['bf09349b06ede7e5a2ec830c2f9ffe90']::text[]
                   AND count(*) FILTER (WHERE edge_status<>'PASS' OR source_registry_row_count<>1 OR target_registry_row_count<>1
                                            OR source_gate_status<>'PASS' OR source_hash_mismatch_flag OR target_hash_mismatch_flag)=0
              THEN 0 ELSE 1 END)::bigint AS mismatch_count,
        (count(*)=1 AND count(DISTINCT edge_sequence)=1
         AND array_agg(edge_code ORDER BY edge_sequence)=ARRAY['M2_3_TO_M2_4']::text[]
         AND array_agg(expected_source_hash ORDER BY edge_sequence)=ARRAY['bf09349b06ede7e5a2ec830c2f9ffe90']::text[]
         AND count(*) FILTER (WHERE edge_status<>'PASS' OR source_registry_row_count<>1 OR target_registry_row_count<>1
                                   OR source_gate_status<>'PASS' OR source_hash_mismatch_flag OR target_hash_mismatch_flag)=0) AS pass_flag,
        'Physical source graph reconstruction for target node M2_4_PORTFOLIO_ACTIVATION.'::text AS interpretation
    FROM e
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_091_NODE_06_M2_5_DAILY_MONITORING_PHYSICAL_EDGES */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    91::smallint,
    'M2_12_POS_091_NODE_06_M2_5_DAILY_MONITORING_PHYSICAL_EDGES'::text,
    6::smallint,
    'SOURCE_GRAPH'::text,
    'Node 06 M2_5_DAILY_MONITORING has its exact independently reconstructed physical source-edge set'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH e AS (
        SELECT * FROM tmp_eval_m2_12_validation_source_edges WHERE target_node_code='M2_5_DAILY_MONITORING'
    )
    SELECT
        concat_ws('|',count(*),count(DISTINCT edge_sequence),array_agg(edge_code ORDER BY edge_sequence)::text,
            array_agg(expected_source_hash ORDER BY edge_sequence)::text,
            count(*) FILTER (WHERE edge_status<>'PASS' OR source_registry_row_count<>1 OR target_registry_row_count<>1
                                  OR source_gate_status<>'PASS' OR source_hash_mismatch_flag OR target_hash_mismatch_flag)) AS observed_value,
        concat_ws('|',2,2,ARRAY['M2_4_TO_M2_5','M1_6_TO_M2_5_SCENARIO_AUTHORITY']::text[]::text,ARRAY['117450a3eea7bb3d3c74d18cc3c8e96a','3f85921bf6fc30ddc6cee146085e58c5']::text[]::text,0) AS expected_value,
        (CASE WHEN count(*)=2 AND count(DISTINCT edge_sequence)=2
                   AND array_agg(edge_code ORDER BY edge_sequence)=ARRAY['M2_4_TO_M2_5','M1_6_TO_M2_5_SCENARIO_AUTHORITY']::text[]
                   AND array_agg(expected_source_hash ORDER BY edge_sequence)=ARRAY['117450a3eea7bb3d3c74d18cc3c8e96a','3f85921bf6fc30ddc6cee146085e58c5']::text[]
                   AND count(*) FILTER (WHERE edge_status<>'PASS' OR source_registry_row_count<>1 OR target_registry_row_count<>1
                                            OR source_gate_status<>'PASS' OR source_hash_mismatch_flag OR target_hash_mismatch_flag)=0
              THEN 0 ELSE 1 END)::bigint AS mismatch_count,
        (count(*)=2 AND count(DISTINCT edge_sequence)=2
         AND array_agg(edge_code ORDER BY edge_sequence)=ARRAY['M2_4_TO_M2_5','M1_6_TO_M2_5_SCENARIO_AUTHORITY']::text[]
         AND array_agg(expected_source_hash ORDER BY edge_sequence)=ARRAY['117450a3eea7bb3d3c74d18cc3c8e96a','3f85921bf6fc30ddc6cee146085e58c5']::text[]
         AND count(*) FILTER (WHERE edge_status<>'PASS' OR source_registry_row_count<>1 OR target_registry_row_count<>1
                                   OR source_gate_status<>'PASS' OR source_hash_mismatch_flag OR target_hash_mismatch_flag)=0) AS pass_flag,
        'Physical source graph reconstruction for target node M2_5_DAILY_MONITORING.'::text AS interpretation
    FROM e
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_092_NODE_07_M2_6_INTERVENTION_STRATEGY_PHYSICAL_EDGES */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    92::smallint,
    'M2_12_POS_092_NODE_07_M2_6_INTERVENTION_STRATEGY_PHYSICAL_EDGES'::text,
    6::smallint,
    'SOURCE_GRAPH'::text,
    'Node 07 M2_6_INTERVENTION_STRATEGY has its exact independently reconstructed physical source-edge set'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH e AS (
        SELECT * FROM tmp_eval_m2_12_validation_source_edges WHERE target_node_code='M2_6_INTERVENTION_STRATEGY'
    )
    SELECT
        concat_ws('|',count(*),count(DISTINCT edge_sequence),array_agg(edge_code ORDER BY edge_sequence)::text,
            array_agg(expected_source_hash ORDER BY edge_sequence)::text,
            count(*) FILTER (WHERE edge_status<>'PASS' OR source_registry_row_count<>1 OR target_registry_row_count<>1
                                  OR source_gate_status<>'PASS' OR source_hash_mismatch_flag OR target_hash_mismatch_flag)) AS observed_value,
        concat_ws('|',1,1,ARRAY['M2_5_TO_M2_6']::text[]::text,ARRAY['18e1c444aa1b02ee5bd3539d7c477adc']::text[]::text,0) AS expected_value,
        (CASE WHEN count(*)=1 AND count(DISTINCT edge_sequence)=1
                   AND array_agg(edge_code ORDER BY edge_sequence)=ARRAY['M2_5_TO_M2_6']::text[]
                   AND array_agg(expected_source_hash ORDER BY edge_sequence)=ARRAY['18e1c444aa1b02ee5bd3539d7c477adc']::text[]
                   AND count(*) FILTER (WHERE edge_status<>'PASS' OR source_registry_row_count<>1 OR target_registry_row_count<>1
                                            OR source_gate_status<>'PASS' OR source_hash_mismatch_flag OR target_hash_mismatch_flag)=0
              THEN 0 ELSE 1 END)::bigint AS mismatch_count,
        (count(*)=1 AND count(DISTINCT edge_sequence)=1
         AND array_agg(edge_code ORDER BY edge_sequence)=ARRAY['M2_5_TO_M2_6']::text[]
         AND array_agg(expected_source_hash ORDER BY edge_sequence)=ARRAY['18e1c444aa1b02ee5bd3539d7c477adc']::text[]
         AND count(*) FILTER (WHERE edge_status<>'PASS' OR source_registry_row_count<>1 OR target_registry_row_count<>1
                                   OR source_gate_status<>'PASS' OR source_hash_mismatch_flag OR target_hash_mismatch_flag)=0) AS pass_flag,
        'Physical source graph reconstruction for target node M2_6_INTERVENTION_STRATEGY.'::text AS interpretation
    FROM e
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_093_NODE_08_M2_7_OPERATIONAL_ACTIVATION_PHYSICAL_EDGES */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    93::smallint,
    'M2_12_POS_093_NODE_08_M2_7_OPERATIONAL_ACTIVATION_PHYSICAL_EDGES'::text,
    6::smallint,
    'SOURCE_GRAPH'::text,
    'Node 08 M2_7_OPERATIONAL_ACTIVATION has its exact independently reconstructed physical source-edge set'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH e AS (
        SELECT * FROM tmp_eval_m2_12_validation_source_edges WHERE target_node_code='M2_7_OPERATIONAL_ACTIVATION'
    )
    SELECT
        concat_ws('|',count(*),count(DISTINCT edge_sequence),array_agg(edge_code ORDER BY edge_sequence)::text,
            array_agg(expected_source_hash ORDER BY edge_sequence)::text,
            count(*) FILTER (WHERE edge_status<>'PASS' OR source_registry_row_count<>1 OR target_registry_row_count<>1
                                  OR source_gate_status<>'PASS' OR source_hash_mismatch_flag OR target_hash_mismatch_flag)) AS observed_value,
        concat_ws('|',1,1,ARRAY['M2_6_TO_M2_7']::text[]::text,ARRAY['868125bff29270490cab4d2e55cb1388']::text[]::text,0) AS expected_value,
        (CASE WHEN count(*)=1 AND count(DISTINCT edge_sequence)=1
                   AND array_agg(edge_code ORDER BY edge_sequence)=ARRAY['M2_6_TO_M2_7']::text[]
                   AND array_agg(expected_source_hash ORDER BY edge_sequence)=ARRAY['868125bff29270490cab4d2e55cb1388']::text[]
                   AND count(*) FILTER (WHERE edge_status<>'PASS' OR source_registry_row_count<>1 OR target_registry_row_count<>1
                                            OR source_gate_status<>'PASS' OR source_hash_mismatch_flag OR target_hash_mismatch_flag)=0
              THEN 0 ELSE 1 END)::bigint AS mismatch_count,
        (count(*)=1 AND count(DISTINCT edge_sequence)=1
         AND array_agg(edge_code ORDER BY edge_sequence)=ARRAY['M2_6_TO_M2_7']::text[]
         AND array_agg(expected_source_hash ORDER BY edge_sequence)=ARRAY['868125bff29270490cab4d2e55cb1388']::text[]
         AND count(*) FILTER (WHERE edge_status<>'PASS' OR source_registry_row_count<>1 OR target_registry_row_count<>1
                                   OR source_gate_status<>'PASS' OR source_hash_mismatch_flag OR target_hash_mismatch_flag)=0) AS pass_flag,
        'Physical source graph reconstruction for target node M2_7_OPERATIONAL_ACTIVATION.'::text AS interpretation
    FROM e
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_094_NODE_09_M2_8_SERVICING_EXECUTION_PHYSICAL_EDGES */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    94::smallint,
    'M2_12_POS_094_NODE_09_M2_8_SERVICING_EXECUTION_PHYSICAL_EDGES'::text,
    6::smallint,
    'SOURCE_GRAPH'::text,
    'Node 09 M2_8_SERVICING_EXECUTION has its exact independently reconstructed physical source-edge set'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH e AS (
        SELECT * FROM tmp_eval_m2_12_validation_source_edges WHERE target_node_code='M2_8_SERVICING_EXECUTION'
    )
    SELECT
        concat_ws('|',count(*),count(DISTINCT edge_sequence),array_agg(edge_code ORDER BY edge_sequence)::text,
            array_agg(expected_source_hash ORDER BY edge_sequence)::text,
            count(*) FILTER (WHERE edge_status<>'PASS' OR source_registry_row_count<>1 OR target_registry_row_count<>1
                                  OR source_gate_status<>'PASS' OR source_hash_mismatch_flag OR target_hash_mismatch_flag)) AS observed_value,
        concat_ws('|',1,1,ARRAY['M2_7_TO_M2_8']::text[]::text,ARRAY['c8e3a472afd2a16b1183677324e9db98']::text[]::text,0) AS expected_value,
        (CASE WHEN count(*)=1 AND count(DISTINCT edge_sequence)=1
                   AND array_agg(edge_code ORDER BY edge_sequence)=ARRAY['M2_7_TO_M2_8']::text[]
                   AND array_agg(expected_source_hash ORDER BY edge_sequence)=ARRAY['c8e3a472afd2a16b1183677324e9db98']::text[]
                   AND count(*) FILTER (WHERE edge_status<>'PASS' OR source_registry_row_count<>1 OR target_registry_row_count<>1
                                            OR source_gate_status<>'PASS' OR source_hash_mismatch_flag OR target_hash_mismatch_flag)=0
              THEN 0 ELSE 1 END)::bigint AS mismatch_count,
        (count(*)=1 AND count(DISTINCT edge_sequence)=1
         AND array_agg(edge_code ORDER BY edge_sequence)=ARRAY['M2_7_TO_M2_8']::text[]
         AND array_agg(expected_source_hash ORDER BY edge_sequence)=ARRAY['c8e3a472afd2a16b1183677324e9db98']::text[]
         AND count(*) FILTER (WHERE edge_status<>'PASS' OR source_registry_row_count<>1 OR target_registry_row_count<>1
                                   OR source_gate_status<>'PASS' OR source_hash_mismatch_flag OR target_hash_mismatch_flag)=0) AS pass_flag,
        'Physical source graph reconstruction for target node M2_8_SERVICING_EXECUTION.'::text AS interpretation
    FROM e
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_095_NODE_10_M2_9_RECONCILIATION_CERTIFICATION_PHYSICAL_EDGES */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    95::smallint,
    'M2_12_POS_095_NODE_10_M2_9_RECONCILIATION_CERTIFICATION_PHYSICAL_EDGES'::text,
    6::smallint,
    'SOURCE_GRAPH'::text,
    'Node 10 M2_9_RECONCILIATION_CERTIFICATION has its exact independently reconstructed physical source-edge set'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH e AS (
        SELECT * FROM tmp_eval_m2_12_validation_source_edges WHERE target_node_code='M2_9_RECONCILIATION_CERTIFICATION'
    )
    SELECT
        concat_ws('|',count(*),count(DISTINCT edge_sequence),array_agg(edge_code ORDER BY edge_sequence)::text,
            array_agg(expected_source_hash ORDER BY edge_sequence)::text,
            count(*) FILTER (WHERE edge_status<>'PASS' OR source_registry_row_count<>1 OR target_registry_row_count<>1
                                  OR source_gate_status<>'PASS' OR source_hash_mismatch_flag OR target_hash_mismatch_flag)) AS observed_value,
        concat_ws('|',1,1,ARRAY['M2_8_TO_M2_9']::text[]::text,ARRAY['ab32d80ba20c2c8f0a6ec9ec97c2ed26']::text[]::text,0) AS expected_value,
        (CASE WHEN count(*)=1 AND count(DISTINCT edge_sequence)=1
                   AND array_agg(edge_code ORDER BY edge_sequence)=ARRAY['M2_8_TO_M2_9']::text[]
                   AND array_agg(expected_source_hash ORDER BY edge_sequence)=ARRAY['ab32d80ba20c2c8f0a6ec9ec97c2ed26']::text[]
                   AND count(*) FILTER (WHERE edge_status<>'PASS' OR source_registry_row_count<>1 OR target_registry_row_count<>1
                                            OR source_gate_status<>'PASS' OR source_hash_mismatch_flag OR target_hash_mismatch_flag)=0
              THEN 0 ELSE 1 END)::bigint AS mismatch_count,
        (count(*)=1 AND count(DISTINCT edge_sequence)=1
         AND array_agg(edge_code ORDER BY edge_sequence)=ARRAY['M2_8_TO_M2_9']::text[]
         AND array_agg(expected_source_hash ORDER BY edge_sequence)=ARRAY['ab32d80ba20c2c8f0a6ec9ec97c2ed26']::text[]
         AND count(*) FILTER (WHERE edge_status<>'PASS' OR source_registry_row_count<>1 OR target_registry_row_count<>1
                                   OR source_gate_status<>'PASS' OR source_hash_mismatch_flag OR target_hash_mismatch_flag)=0) AS pass_flag,
        'Physical source graph reconstruction for target node M2_9_RECONCILIATION_CERTIFICATION.'::text AS interpretation
    FROM e
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_096_NODE_11_M2_10_PORTFOLIO_ANALYTICS_PHYSICAL_EDGES */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    96::smallint,
    'M2_12_POS_096_NODE_11_M2_10_PORTFOLIO_ANALYTICS_PHYSICAL_EDGES'::text,
    6::smallint,
    'SOURCE_GRAPH'::text,
    'Node 11 M2_10_PORTFOLIO_ANALYTICS has its exact independently reconstructed physical source-edge set'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH e AS (
        SELECT * FROM tmp_eval_m2_12_validation_source_edges WHERE target_node_code='M2_10_PORTFOLIO_ANALYTICS'
    )
    SELECT
        concat_ws('|',count(*),count(DISTINCT edge_sequence),array_agg(edge_code ORDER BY edge_sequence)::text,
            array_agg(expected_source_hash ORDER BY edge_sequence)::text,
            count(*) FILTER (WHERE edge_status<>'PASS' OR source_registry_row_count<>1 OR target_registry_row_count<>1
                                  OR source_gate_status<>'PASS' OR source_hash_mismatch_flag OR target_hash_mismatch_flag)) AS observed_value,
        concat_ws('|',1,1,ARRAY['M2_9_TO_M2_10']::text[]::text,ARRAY['6af76d0059b47623619ebc09330b15fe']::text[]::text,0) AS expected_value,
        (CASE WHEN count(*)=1 AND count(DISTINCT edge_sequence)=1
                   AND array_agg(edge_code ORDER BY edge_sequence)=ARRAY['M2_9_TO_M2_10']::text[]
                   AND array_agg(expected_source_hash ORDER BY edge_sequence)=ARRAY['6af76d0059b47623619ebc09330b15fe']::text[]
                   AND count(*) FILTER (WHERE edge_status<>'PASS' OR source_registry_row_count<>1 OR target_registry_row_count<>1
                                            OR source_gate_status<>'PASS' OR source_hash_mismatch_flag OR target_hash_mismatch_flag)=0
              THEN 0 ELSE 1 END)::bigint AS mismatch_count,
        (count(*)=1 AND count(DISTINCT edge_sequence)=1
         AND array_agg(edge_code ORDER BY edge_sequence)=ARRAY['M2_9_TO_M2_10']::text[]
         AND array_agg(expected_source_hash ORDER BY edge_sequence)=ARRAY['6af76d0059b47623619ebc09330b15fe']::text[]
         AND count(*) FILTER (WHERE edge_status<>'PASS' OR source_registry_row_count<>1 OR target_registry_row_count<>1
                                   OR source_gate_status<>'PASS' OR source_hash_mismatch_flag OR target_hash_mismatch_flag)=0) AS pass_flag,
        'Physical source graph reconstruction for target node M2_10_PORTFOLIO_ANALYTICS.'::text AS interpretation
    FROM e
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_097_NODE_12_M2_11_STRATEGY_SIMULATION_PHYSICAL_EDGES */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    97::smallint,
    'M2_12_POS_097_NODE_12_M2_11_STRATEGY_SIMULATION_PHYSICAL_EDGES'::text,
    6::smallint,
    'SOURCE_GRAPH'::text,
    'Node 12 M2_11_STRATEGY_SIMULATION has its exact independently reconstructed physical source-edge set'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH e AS (
        SELECT * FROM tmp_eval_m2_12_validation_source_edges WHERE target_node_code='M2_11_STRATEGY_SIMULATION'
    )
    SELECT
        concat_ws('|',count(*),count(DISTINCT edge_sequence),array_agg(edge_code ORDER BY edge_sequence)::text,
            array_agg(expected_source_hash ORDER BY edge_sequence)::text,
            count(*) FILTER (WHERE edge_status<>'PASS' OR source_registry_row_count<>1 OR target_registry_row_count<>1
                                  OR source_gate_status<>'PASS' OR source_hash_mismatch_flag OR target_hash_mismatch_flag)) AS observed_value,
        concat_ws('|',5,5,ARRAY['M1_17_TO_M2_11','M2_2_TO_M2_11','M2_4_TO_M2_11','M2_7_TO_M2_11','M2_10_TO_M2_11']::text[]::text,ARRAY['7d9e466da28cad2551aa99c4c40c912b','bbe83b187b31ea561789797322031fc6','117450a3eea7bb3d3c74d18cc3c8e96a','c8e3a472afd2a16b1183677324e9db98','24fca7263a04397ebf21d30639f9069b']::text[]::text,0) AS expected_value,
        (CASE WHEN count(*)=5 AND count(DISTINCT edge_sequence)=5
                   AND array_agg(edge_code ORDER BY edge_sequence)=ARRAY['M1_17_TO_M2_11','M2_2_TO_M2_11','M2_4_TO_M2_11','M2_7_TO_M2_11','M2_10_TO_M2_11']::text[]
                   AND array_agg(expected_source_hash ORDER BY edge_sequence)=ARRAY['7d9e466da28cad2551aa99c4c40c912b','bbe83b187b31ea561789797322031fc6','117450a3eea7bb3d3c74d18cc3c8e96a','c8e3a472afd2a16b1183677324e9db98','24fca7263a04397ebf21d30639f9069b']::text[]
                   AND count(*) FILTER (WHERE edge_status<>'PASS' OR source_registry_row_count<>1 OR target_registry_row_count<>1
                                            OR source_gate_status<>'PASS' OR source_hash_mismatch_flag OR target_hash_mismatch_flag)=0
              THEN 0 ELSE 1 END)::bigint AS mismatch_count,
        (count(*)=5 AND count(DISTINCT edge_sequence)=5
         AND array_agg(edge_code ORDER BY edge_sequence)=ARRAY['M1_17_TO_M2_11','M2_2_TO_M2_11','M2_4_TO_M2_11','M2_7_TO_M2_11','M2_10_TO_M2_11']::text[]
         AND array_agg(expected_source_hash ORDER BY edge_sequence)=ARRAY['7d9e466da28cad2551aa99c4c40c912b','bbe83b187b31ea561789797322031fc6','117450a3eea7bb3d3c74d18cc3c8e96a','c8e3a472afd2a16b1183677324e9db98','24fca7263a04397ebf21d30639f9069b']::text[]
         AND count(*) FILTER (WHERE edge_status<>'PASS' OR source_registry_row_count<>1 OR target_registry_row_count<>1
                                   OR source_gate_status<>'PASS' OR source_hash_mismatch_flag OR target_hash_mismatch_flag)=0) AS pass_flag,
        'Physical source graph reconstruction for target node M2_11_STRATEGY_SIMULATION.'::text AS interpretation
    FROM e
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_098_APPLICATION_VIEW_GRAIN */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    98::smallint,
    'M2_12_POS_098_APPLICATION_VIEW_GRAIN'::text,
    7::smallint,
    'CONSUMPTION_INTERFACES'::text,
    'Application-origination consumption preserves the exact 1,500-row business grain'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    SELECT concat_ws('|',count(*),count(DISTINCT (v.module1_run_id,v.scenario_id,v.merchant_application_id)),
                     count(*)-count(DISTINCT (v.module1_run_id,v.scenario_id,v.merchant_application_id))) AS observed_value,
           '1500|1500|0'::text AS expected_value,
           (CASE WHEN count(*)=1500 AND count(DISTINCT (v.module1_run_id,v.scenario_id,v.merchant_application_id))=1500 THEN 0 ELSE 1 END)::bigint AS mismatch_count,
           (count(*)=1500 AND count(DISTINCT (v.module1_run_id,v.scenario_id,v.merchant_application_id))=1500) AS pass_flag,
           'The application interface retains the accepted Module 1 application grain without multiplication.'::text AS interpretation
    FROM msbf_m2.v_m2_12_application_origination_consumption v
    JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=v.module1_run_id
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_099_APPLICATION_VIEW_BASE_PARITY */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    99::smallint,
    'M2_12_POS_099_APPLICATION_VIEW_BASE_PARITY'::text,
    7::smallint,
    'CONSUMPTION_INTERFACES'::text,
    'Application-origination consumption has exact key parity with accepted M1.17 integrated consumption'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH b AS (
      SELECT g.module1_run_id,g.scenario_id,g.merchant_application_id
      FROM msbf_m1.v_m1_17_g2_integrated_consumption g
      JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=g.module1_run_id
    ), v AS (
      SELECT x.module1_run_id,x.scenario_id,x.merchant_application_id
      FROM msbf_m2.v_m2_12_application_origination_consumption x
      JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=x.module1_run_id
    ), p AS (
      SELECT count(*) FILTER (WHERE b.module1_run_id IS NULL)::bigint AS extra_rows,
             count(*) FILTER (WHERE v.module1_run_id IS NULL)::bigint AS missing_rows
      FROM b FULL JOIN v USING(module1_run_id,scenario_id,merchant_application_id)
    )
    SELECT concat_ws('|',(SELECT count(*) FROM b),(SELECT count(*) FROM v),(SELECT missing_rows FROM p),(SELECT extra_rows FROM p),
             (SELECT count(*) FROM (SELECT module1_run_id,scenario_id,merchant_application_id FROM v GROUP BY 1,2,3 HAVING count(*)>1) d)) AS observed_value,
           '1500|1500|0|0|0'::text AS expected_value,
           (CASE WHEN (SELECT count(*) FROM b)=1500 AND (SELECT count(*) FROM v)=1500
                       AND (SELECT missing_rows=0 AND extra_rows=0 FROM p)
                       AND (SELECT count(*) FROM (SELECT module1_run_id,scenario_id,merchant_application_id FROM v GROUP BY 1,2,3 HAVING count(*)>1) d)=0
                  THEN 0 ELSE 1 END)::bigint AS mismatch_count,
           ((SELECT count(*) FROM b)=1500 AND (SELECT count(*) FROM v)=1500
            AND (SELECT missing_rows=0 AND extra_rows=0 FROM p)
            AND (SELECT count(*) FROM (SELECT module1_run_id,scenario_id,merchant_application_id FROM v GROUP BY 1,2,3 HAVING count(*)>1) d)=0) AS pass_flag,
           'Accepted M1.17 applications and the M2.12 application interface have exact business-key parity.'::text AS interpretation
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_100_OPERATIONAL_VIEW_GRAIN */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    100::smallint,
    'M2_12_POS_100_OPERATIONAL_VIEW_GRAIN'::text,
    7::smallint,
    'CONSUMPTION_INTERFACES'::text,
    'Operational-account consumption preserves the exact 59-row account/advance grain'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    SELECT concat_ws('|',count(*),count(DISTINCT (v.module1_run_id,v.scenario_id,v.merchant_application_id,v.synthetic_account_id,v.synthetic_advance_id)),
                     count(*)-count(DISTINCT (v.module1_run_id,v.scenario_id,v.merchant_application_id,v.synthetic_account_id,v.synthetic_advance_id))) AS observed_value,
           '59|59|0'::text AS expected_value,
           (CASE WHEN count(*)=59 AND count(DISTINCT (v.module1_run_id,v.scenario_id,v.merchant_application_id,v.synthetic_account_id,v.synthetic_advance_id))=59 THEN 0 ELSE 1 END)::bigint AS mismatch_count,
           (count(*)=59 AND count(DISTINCT (v.module1_run_id,v.scenario_id,v.merchant_application_id,v.synthetic_account_id,v.synthetic_advance_id))=59) AS pass_flag,
           'Operational consumption retains one row per synthetic account/advance business key.'::text AS interpretation
    FROM msbf_m2.v_m2_12_operational_account_consumption v
    JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=v.module1_run_id
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_101_OPERATIONAL_VIEW_LINEAGE_COMPLETENESS */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    101::smallint,
    'M2_12_POS_101_OPERATIONAL_VIEW_LINEAGE_COMPLETENESS'::text,
    7::smallint,
    'CONSUMPTION_INTERFACES'::text,
    'Operational-account consumption has complete M2.4 through M2.10 contract lineage and no production-action flags'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    SELECT concat_ws('|',count(*) FILTER (WHERE m2_4_contract_row_hash IS NOT NULL AND m2_5_contract_row_hash IS NOT NULL
                                                AND m2_6_contract_row_hash IS NOT NULL AND m2_7_contract_row_hash IS NOT NULL
                                                AND m2_8_contract_row_hash IS NOT NULL AND m2_9_contract_row_hash IS NOT NULL
                                                AND m2_10_contract_row_hash IS NOT NULL),
                     count(*) FILTER (WHERE m2_4_real_funds_movement_flag OR m2_4_external_notice_generation_authorized_flag
                                           OR m2_4_external_notice_transmitted_flag OR m2_4_production_adverse_action_notice_flag)) AS observed_value,
           '59|0'::text AS expected_value,
           (CASE WHEN count(*)=59
                       AND count(*) FILTER (WHERE m2_4_contract_row_hash IS NOT NULL AND m2_5_contract_row_hash IS NOT NULL
                                                AND m2_6_contract_row_hash IS NOT NULL AND m2_7_contract_row_hash IS NOT NULL
                                                AND m2_8_contract_row_hash IS NOT NULL AND m2_9_contract_row_hash IS NOT NULL
                                                AND m2_10_contract_row_hash IS NOT NULL)=59
                       AND count(*) FILTER (WHERE m2_4_real_funds_movement_flag OR m2_4_external_notice_generation_authorized_flag
                                                OR m2_4_external_notice_transmitted_flag OR m2_4_production_adverse_action_notice_flag)=0
                  THEN 0 ELSE 1 END)::bigint AS mismatch_count,
           (count(*)=59
            AND count(*) FILTER (WHERE m2_4_contract_row_hash IS NOT NULL AND m2_5_contract_row_hash IS NOT NULL
                                      AND m2_6_contract_row_hash IS NOT NULL AND m2_7_contract_row_hash IS NOT NULL
                                      AND m2_8_contract_row_hash IS NOT NULL AND m2_9_contract_row_hash IS NOT NULL
                                      AND m2_10_contract_row_hash IS NOT NULL)=59
            AND count(*) FILTER (WHERE m2_4_real_funds_movement_flag OR m2_4_external_notice_generation_authorized_flag
                                      OR m2_4_external_notice_transmitted_flag OR m2_4_production_adverse_action_notice_flag)=0) AS pass_flag,
           'All operational rows retain complete accepted-stage lineage while remaining synthetic and non-production.'::text AS interpretation
    FROM msbf_m2.v_m2_12_operational_account_consumption v
    JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=v.module1_run_id
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_102_STRATEGY_VIEW_GRAIN */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    102::smallint,
    'M2_12_POS_102_STRATEGY_VIEW_GRAIN'::text,
    7::smallint,
    'CONSUMPTION_INTERFACES'::text,
    'Strategy-scope consumption preserves the exact eight-strategy by three-scope grain'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    SELECT concat_ws('|',count(*),count(DISTINCT strategy_profile_code),count(DISTINCT reporting_scope_code),
                     count(DISTINCT (strategy_profile_code,reporting_scope_code))) AS observed_value,
           '24|8|3|24'::text AS expected_value,
           (CASE WHEN count(*)=24 AND count(DISTINCT strategy_profile_code)=8 AND count(DISTINCT reporting_scope_code)=3
                       AND count(DISTINCT (strategy_profile_code,reporting_scope_code))=24 THEN 0 ELSE 1 END)::bigint AS mismatch_count,
           (count(*)=24 AND count(DISTINCT strategy_profile_code)=8 AND count(DISTINCT reporting_scope_code)=3
            AND count(DISTINCT (strategy_profile_code,reporting_scope_code))=24) AS pass_flag,
           'M2.11 strategy consumption is exactly eight strategies by three reporting scopes.'::text AS interpretation
    FROM msbf_m2.v_m2_12_strategy_scope_consumption v
    JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=v.module1_run_id
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_103_STRATEGY_VIEW_G3_LINKAGE */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    103::smallint,
    'M2_12_POS_103_STRATEGY_VIEW_G3_LINKAGE'::text,
    7::smallint,
    'CONSUMPTION_INTERFACES'::text,
    'All strategy-scope rows link to the exact generated G3 bundle with deployment and Module 3 prohibited'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    SELECT concat_ws('|',count(*) FILTER (WHERE g3_bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND g3_contract_version=1
                                                AND g3_schema_version='M2_G3_BUNDLE_SCHEMA_V1' AND g3_methodology_version='M2_12_METHOD_V1'
                                                AND g3_acceptance_gate_id='G3_M2_CONTRACT' AND g3_contract_status='GENERATED'
                                                AND g3_contract_set_hash IS NOT NULL AND g3_combined_set_hash IS NOT NULL AND g3_registry_row_hash IS NOT NULL),
                     count(*) FILTER (WHERE deployment_authorized_flag OR module3_execution_authorized_flag)) AS observed_value,
           '24|0'::text AS expected_value,
           (CASE WHEN count(*)=24
                       AND count(*) FILTER (WHERE g3_bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND g3_contract_version=1
                                                AND g3_schema_version='M2_G3_BUNDLE_SCHEMA_V1' AND g3_methodology_version='M2_12_METHOD_V1'
                                                AND g3_acceptance_gate_id='G3_M2_CONTRACT' AND g3_contract_status='GENERATED'
                                                AND g3_contract_set_hash IS NOT NULL AND g3_combined_set_hash IS NOT NULL AND g3_registry_row_hash IS NOT NULL)=24
                       AND count(*) FILTER (WHERE deployment_authorized_flag OR module3_execution_authorized_flag)=0
                  THEN 0 ELSE 1 END)::bigint AS mismatch_count,
           (count(*)=24
            AND count(*) FILTER (WHERE g3_bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND g3_contract_version=1
                                      AND g3_schema_version='M2_G3_BUNDLE_SCHEMA_V1' AND g3_methodology_version='M2_12_METHOD_V1'
                                      AND g3_acceptance_gate_id='G3_M2_CONTRACT' AND g3_contract_status='GENERATED'
                                      AND g3_contract_set_hash IS NOT NULL AND g3_combined_set_hash IS NOT NULL AND g3_registry_row_hash IS NOT NULL)=24
            AND count(*) FILTER (WHERE deployment_authorized_flag OR module3_execution_authorized_flag)=0) AS pass_flag,
           'The strategy interface is consumption-only and bound to the generated non-production G3 contract.'::text AS interpretation
    FROM msbf_m2.v_m2_12_strategy_scope_consumption v
    JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=v.module1_run_id
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_104_STAGE_LINEAGE_VIEW */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    104::smallint,
    'M2_12_POS_104_STAGE_LINEAGE_VIEW'::text,
    7::smallint,
    'CONSUMPTION_INTERFACES'::text,
    'Stage-lineage interface exposes exactly 12 PASS source nodes without multiplication'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    SELECT concat_ws('|',count(*),count(DISTINCT (certification_node_sequence,stage_code)),
                     count(*) FILTER (WHERE certification_status='PASS'),
                     count(*) FILTER (WHERE g3_bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND g3_contract_version=1 AND g3_contract_status='GENERATED')) AS observed_value,
           '12|12|12|12'::text AS expected_value,
           (CASE WHEN count(*)=12 AND count(DISTINCT (certification_node_sequence,stage_code))=12
                       AND count(*) FILTER (WHERE certification_status='PASS')=12
                       AND count(*) FILTER (WHERE g3_bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND g3_contract_version=1 AND g3_contract_status='GENERATED')=12
                  THEN 0 ELSE 1 END)::bigint AS mismatch_count,
           (count(*)=12 AND count(DISTINCT (certification_node_sequence,stage_code))=12
            AND count(*) FILTER (WHERE certification_status='PASS')=12
            AND count(*) FILTER (WHERE g3_bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND g3_contract_version=1 AND g3_contract_status='GENERATED')=12) AS pass_flag,
           'Stage lineage remains one row per frozen certification node.'::text AS interpretation
    FROM msbf_ctl.v_m2_12_stage_lineage v
    JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=v.module1_run_id
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_105_COMPONENT_LINEAGE_VIEW */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    105::smallint,
    'M2_12_POS_105_COMPONENT_LINEAGE_VIEW'::text,
    7::smallint,
    'CONSUMPTION_INTERFACES'::text,
    'Component-contract lineage interface exposes exactly 13 PASS components without multiplication'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    SELECT concat_ws('|',count(*),count(DISTINCT (component_sequence,component_contract_code,contract_version)),
                     count(*) FILTER (WHERE certification_status='PASS'),
                     count(*) FILTER (WHERE expected_latest_rows=observed_latest_rows AND expected_archive_rows=observed_archive_rows),
                     count(*) FILTER (WHERE g3_bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND g3_contract_version=1 AND g3_contract_status='GENERATED')) AS observed_value,
           '13|13|13|13|13'::text AS expected_value,
           (CASE WHEN count(*)=13 AND count(DISTINCT (component_sequence,component_contract_code,contract_version))=13
                       AND count(*) FILTER (WHERE certification_status='PASS')=13
                       AND count(*) FILTER (WHERE expected_latest_rows=observed_latest_rows AND expected_archive_rows=observed_archive_rows)=13
                       AND count(*) FILTER (WHERE g3_bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND g3_contract_version=1 AND g3_contract_status='GENERATED')=13
                  THEN 0 ELSE 1 END)::bigint AS mismatch_count,
           (count(*)=13 AND count(DISTINCT (component_sequence,component_contract_code,contract_version))=13
            AND count(*) FILTER (WHERE certification_status='PASS')=13
            AND count(*) FILTER (WHERE expected_latest_rows=observed_latest_rows AND expected_archive_rows=observed_archive_rows)=13
            AND count(*) FILTER (WHERE g3_bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND g3_contract_version=1 AND g3_contract_status='GENERATED')=13) AS pass_flag,
           'Component lineage remains one row per frozen component contract.'::text AS interpretation
    FROM msbf_ctl.v_m2_12_component_contract_lineage v
    JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=v.module1_run_id
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_106_G3_LINEAGE_VIEW */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    106::smallint,
    'M2_12_POS_106_G3_LINEAGE_VIEW'::text,
    7::smallint,
    'CONSUMPTION_INTERFACES'::text,
    'G3-lineage interface exposes one exact generated, non-production contract row'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    SELECT concat_ws('|',count(*),min(contract_status),min(canonical_entity_count),
                     count(*) FILTER (WHERE all_stage_certification_pass_flag AND all_component_contract_pass_flag
                                           AND all_evidence_certification_pass_flag AND all_contract_reproduction_pass_flag
                                           AND all_capability_boundary_pass_flag AND all_source_graph_edges_pass_flag),
                     count(*) FILTER (WHERE production_action_authorized_flag OR external_system_update_authorized_flag
                                           OR legal_or_regulatory_certified_flag OR empirical_or_causal_optimization_authorized_flag
                                           OR deployment_authorized_flag OR module3_execution_authorized_flag)) AS observed_value,
           '1|GENERATED|134|1|0'::text AS expected_value,
           (CASE WHEN count(*)=1 AND min(contract_status)='GENERATED' AND min(canonical_entity_count)=134
                       AND count(*) FILTER (WHERE all_stage_certification_pass_flag AND all_component_contract_pass_flag
                                                AND all_evidence_certification_pass_flag AND all_contract_reproduction_pass_flag
                                                AND all_capability_boundary_pass_flag AND all_source_graph_edges_pass_flag)=1
                       AND count(*) FILTER (WHERE production_action_authorized_flag OR external_system_update_authorized_flag
                                                OR legal_or_regulatory_certified_flag OR empirical_or_causal_optimization_authorized_flag
                                                OR deployment_authorized_flag OR module3_execution_authorized_flag)=0
                  THEN 0 ELSE 1 END)::bigint AS mismatch_count,
           (count(*)=1 AND min(contract_status)='GENERATED' AND min(canonical_entity_count)=134
            AND count(*) FILTER (WHERE all_stage_certification_pass_flag AND all_component_contract_pass_flag
                                      AND all_evidence_certification_pass_flag AND all_contract_reproduction_pass_flag
                                      AND all_capability_boundary_pass_flag AND all_source_graph_edges_pass_flag)=1
            AND count(*) FILTER (WHERE production_action_authorized_flag OR external_system_update_authorized_flag
                                      OR legal_or_regulatory_certified_flag OR empirical_or_causal_optimization_authorized_flag
                                      OR deployment_authorized_flag OR module3_execution_authorized_flag)=0) AS pass_flag,
           'The G3 lineage view is a one-row generated certification contract, not an acceptance or production authorization.'::text AS interpretation
    FROM msbf_ctl.v_m2_12_g3_lineage v
    JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=v.module1_run_id
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_107_POWER_BI_VIEW_PARITY */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    107::smallint,
    'M2_12_POS_107_POWER_BI_VIEW_PARITY'::text,
    7::smallint,
    'CONSUMPTION_INTERFACES'::text,
    'Power BI enterprise portfolio view has exact key and contract-row parity with strategy-scope consumption'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH s AS (
      SELECT module1_run_id,strategy_profile_code,reporting_scope_code,contract_row_hash
      FROM msbf_m2.v_m2_12_strategy_scope_consumption v
      JOIN tmp_src_m2_12_validation_run_context ctx USING(module1_run_id)
    ), b AS (
      SELECT module1_run_id,strategy_profile_code,reporting_scope_code,contract_row_hash
      FROM msbf_m2.v_m2_12_power_bi_enterprise_portfolio v
      JOIN tmp_src_m2_12_validation_run_context ctx USING(module1_run_id)
    ), p AS (
      SELECT count(*) FILTER (WHERE s.module1_run_id IS NULL)::bigint AS extra_rows,
             count(*) FILTER (WHERE b.module1_run_id IS NULL)::bigint AS missing_rows,
             count(*) FILTER (WHERE s.module1_run_id IS NOT NULL AND b.module1_run_id IS NOT NULL
                                   AND s.contract_row_hash IS DISTINCT FROM b.contract_row_hash)::bigint AS hash_mismatches
      FROM s FULL JOIN b USING(module1_run_id,strategy_profile_code,reporting_scope_code)
    )
    SELECT concat_ws('|',(SELECT count(*) FROM s),(SELECT count(*) FROM b),(SELECT missing_rows FROM p),(SELECT extra_rows FROM p),(SELECT hash_mismatches FROM p)) AS observed_value,
           '24|24|0|0|0'::text AS expected_value,
           (CASE WHEN (SELECT count(*) FROM s)=24 AND (SELECT count(*) FROM b)=24
                       AND (SELECT missing_rows=0 AND extra_rows=0 AND hash_mismatches=0 FROM p) THEN 0 ELSE 1 END)::bigint AS mismatch_count,
           ((SELECT count(*) FROM s)=24 AND (SELECT count(*) FROM b)=24
            AND (SELECT missing_rows=0 AND extra_rows=0 AND hash_mismatches=0 FROM p)) AS pass_flag,
           'The Power BI surface is a non-mutating projection of the governed 24-row strategy interface.'::text AS interpretation
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_108_VIEW_CATALOG_SCHEMA */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    108::smallint,
    'M2_12_POS_108_VIEW_CATALOG_SCHEMA'::text,
    7::smallint,
    'CONSUMPTION_INTERFACES'::text,
    'All seven M2.12 consumption/lineage views exist with the exact frozen column counts'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH expected(view_schema,view_name,expected_columns) AS (VALUES
      ('msbf_m2','v_m2_12_application_origination_consumption',223),
      ('msbf_m2','v_m2_12_operational_account_consumption',272),
      ('msbf_m2','v_m2_12_strategy_scope_consumption',102),
      ('msbf_ctl','v_m2_12_stage_lineage',34),
      ('msbf_ctl','v_m2_12_component_contract_lineage',49),
      ('msbf_ctl','v_m2_12_g3_lineage',63),
      ('msbf_m2','v_m2_12_power_bi_enterprise_portfolio',102)
    ), observed AS (
      SELECT e.*,c.oid,count(a.attnum) FILTER (WHERE a.attnum>0 AND NOT a.attisdropped)::integer AS observed_columns
      FROM expected e
      LEFT JOIN pg_catalog.pg_namespace n ON n.nspname=e.view_schema
      LEFT JOIN pg_catalog.pg_class c ON c.relnamespace=n.oid AND c.relname=e.view_name AND c.relkind='v'
      LEFT JOIN pg_catalog.pg_attribute a ON a.attrelid=c.oid
      GROUP BY e.view_schema,e.view_name,e.expected_columns,c.oid
    )
    SELECT concat_ws('|',count(*) FILTER (WHERE oid IS NOT NULL),sum(observed_columns),
                     string_agg(observed_columns::text,',' ORDER BY view_schema,view_name)) AS observed_value,
           concat_ws('|',7,845,string_agg(expected_columns::text,',' ORDER BY view_schema,view_name)) AS expected_value,
           count(*) FILTER (WHERE oid IS NULL OR observed_columns<>expected_columns)::bigint AS mismatch_count,
           (count(*)=7 AND count(*) FILTER (WHERE oid IS NULL OR observed_columns<>expected_columns)=0) AS pass_flag,
           'Catalog-native view identity check; no deparser or source-text comparison is used.'::text AS interpretation
    FROM observed
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_109_ALL_INTERFACE_CARDINALITIES_AND_RUN_SCOPE */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    109::smallint,
    'M2_12_POS_109_ALL_INTERFACE_CARDINALITIES_AND_RUN_SCOPE'::text,
    7::smallint,
    'CONSUMPTION_INTERFACES'::text,
    'All six primary consumption/lineage interfaces have exact cardinalities and are scoped only to the governed run'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH x AS (
      SELECT
        (SELECT count(*) FROM msbf_m2.v_m2_12_application_origination_consumption v JOIN tmp_src_m2_12_validation_run_context ctx USING(module1_run_id))::bigint a_rows,
        (SELECT count(DISTINCT module1_run_id) FROM msbf_m2.v_m2_12_application_origination_consumption v JOIN tmp_src_m2_12_validation_run_context ctx USING(module1_run_id))::bigint a_runs,
        (SELECT count(*) FROM msbf_m2.v_m2_12_operational_account_consumption v JOIN tmp_src_m2_12_validation_run_context ctx USING(module1_run_id))::bigint o_rows,
        (SELECT count(DISTINCT module1_run_id) FROM msbf_m2.v_m2_12_operational_account_consumption v JOIN tmp_src_m2_12_validation_run_context ctx USING(module1_run_id))::bigint o_runs,
        (SELECT count(*) FROM msbf_m2.v_m2_12_strategy_scope_consumption v JOIN tmp_src_m2_12_validation_run_context ctx USING(module1_run_id))::bigint s_rows,
        (SELECT count(DISTINCT module1_run_id) FROM msbf_m2.v_m2_12_strategy_scope_consumption v JOIN tmp_src_m2_12_validation_run_context ctx USING(module1_run_id))::bigint s_runs,
        (SELECT count(*) FROM msbf_ctl.v_m2_12_stage_lineage v JOIN tmp_src_m2_12_validation_run_context ctx USING(module1_run_id))::bigint st_rows,
        (SELECT count(*) FROM msbf_ctl.v_m2_12_component_contract_lineage v JOIN tmp_src_m2_12_validation_run_context ctx USING(module1_run_id))::bigint c_rows,
        (SELECT count(*) FROM msbf_ctl.v_m2_12_g3_lineage v JOIN tmp_src_m2_12_validation_run_context ctx USING(module1_run_id))::bigint g_rows
    )
    SELECT concat_ws('|',a_rows,o_rows,s_rows,st_rows,c_rows,g_rows,a_runs,o_runs,s_runs) AS observed_value,
           '1500|59|24|12|13|1|1|1|1'::text AS expected_value,
           (CASE WHEN ROW(a_rows,o_rows,s_rows,st_rows,c_rows,g_rows,a_runs,o_runs,s_runs)=ROW(1500::bigint,59::bigint,24::bigint,12::bigint,13::bigint,1::bigint,1::bigint,1::bigint,1::bigint) THEN 0 ELSE 1 END)::bigint AS mismatch_count,
           (ROW(a_rows,o_rows,s_rows,st_rows,c_rows,g_rows,a_runs,o_runs,s_runs)=ROW(1500::bigint,59::bigint,24::bigint,12::bigint,13::bigint,1::bigint,1::bigint,1::bigint,1::bigint)) AS pass_flag,
           'All consumption and lineage surfaces expose only the one governed run at frozen cardinality.'::text AS interpretation
    FROM x
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_110_ACCEPTED_M2_11_REGISTRY_ANCHORS */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    110::smallint,
    'M2_12_POS_110_ACCEPTED_M2_11_REGISTRY_ANCHORS'::text,
    8::smallint,
    'M2_11_BOUNDARY'::text,
    'Physical accepted M2.11 registry anchors match the copied M2.12 component and G3 source identities'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH src AS (
      SELECT r.* FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry r
      JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=r.module1_run_id
      WHERE r.contract_code='M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION' AND r.contract_version=1 AND r.contract_status='ACCEPTED'
    ), c AS (
      SELECT c.* FROM msbf_m2.module2_contract_component_snapshot c
      JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=c.module1_run_id
      WHERE c.component_sequence=13 AND c.component_contract_code='M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION' AND c.contract_version=1
    ), g AS (
      SELECT g.* FROM msbf_ctl.m2_12_g3_bundle_registry g
      JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=g.module1_run_id
      WHERE g.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND g.contract_version=1
    )
    SELECT concat_ws('|',(SELECT count(*) FROM src),(SELECT count(*) FROM c),(SELECT count(*) FROM g),
             (SELECT count(*) FROM src,c,g WHERE src.contract_set_hash=c.observed_contract_set_hash
               AND src.combined_set_hash=c.observed_stage_combined_set_hash AND src.row_hash=c.observed_registry_row_hash
               AND src.contract_set_hash=g.accepted_m2_11_contract_set_hash AND src.combined_set_hash=g.accepted_m2_11_combined_set_hash
               AND src.row_hash=g.accepted_m2_11_registry_row_hash)) AS observed_value,
           '1|1|1|1'::text AS expected_value,
           (CASE WHEN (SELECT count(*) FROM src)=1 AND (SELECT count(*) FROM c)=1 AND (SELECT count(*) FROM g)=1
                       AND (SELECT count(*) FROM src,c,g WHERE src.contract_set_hash=c.observed_contract_set_hash
                            AND src.combined_set_hash=c.observed_stage_combined_set_hash AND src.row_hash=c.observed_registry_row_hash
                            AND src.contract_set_hash=g.accepted_m2_11_contract_set_hash AND src.combined_set_hash=g.accepted_m2_11_combined_set_hash
                            AND src.row_hash=g.accepted_m2_11_registry_row_hash)=1 THEN 0 ELSE 1 END)::bigint AS mismatch_count,
           ((SELECT count(*) FROM src)=1 AND (SELECT count(*) FROM c)=1 AND (SELECT count(*) FROM g)=1
            AND (SELECT count(*) FROM src,c,g WHERE src.contract_set_hash=c.observed_contract_set_hash
                 AND src.combined_set_hash=c.observed_stage_combined_set_hash AND src.row_hash=c.observed_registry_row_hash
                 AND src.contract_set_hash=g.accepted_m2_11_contract_set_hash AND src.combined_set_hash=g.accepted_m2_11_combined_set_hash
                 AND src.row_hash=g.accepted_m2_11_registry_row_hash)=1) AS pass_flag,
           'M2.12 does not reinterpret M2.11; it certifies exact copied accepted source identities.'::text AS interpretation
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_111_STRATEGY_SCOPE_EXACT_DISTRIBUTION */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    111::smallint,
    'M2_12_POS_111_STRATEGY_SCOPE_EXACT_DISTRIBUTION'::text,
    8::smallint,
    'M2_11_BOUNDARY'::text,
    'M2.11 strategy scope is exactly 24 rows, eight strategies, and three reporting scopes'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    SELECT concat_ws('|',count(*),count(DISTINCT strategy_profile_code),count(DISTINCT reporting_scope_code),
                     count(*)-count(DISTINCT (strategy_profile_code,reporting_scope_code))) AS observed_value,
           '24|8|3|0'::text AS expected_value,
           (CASE WHEN count(*)=24 AND count(DISTINCT strategy_profile_code)=8 AND count(DISTINCT reporting_scope_code)=3
                       AND count(DISTINCT (strategy_profile_code,reporting_scope_code))=24 THEN 0 ELSE 1 END)::bigint AS mismatch_count,
           (count(*)=24 AND count(DISTINCT strategy_profile_code)=8 AND count(DISTINCT reporting_scope_code)=3
            AND count(DISTINCT (strategy_profile_code,reporting_scope_code))=24) AS pass_flag,
           'The accepted M2.11 strategy universe is finite and deterministic.'::text AS interpretation
    FROM msbf_m2.portfolio_strategy_simulation_latest s
    JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=s.module1_run_id
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_112_PRIMARY_GOVERNANCE_REVIEW_EXACT */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    112::smallint,
    'M2_12_POS_112_PRIMARY_GOVERNANCE_REVIEW_EXACT'::text,
    8::smallint,
    'M2_11_BOUNDARY'::text,
    'The three M2.11 primary governance-review selections are exact and are not deployment decisions'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    SELECT string_agg(reporting_scope_code||'='||strategy_profile_code,'|' ORDER BY reporting_scope_code) AS observed_value,
           'BASELINE=BALANCED_FRONTIER|PORTFOLIO=PRICE_FOR_RISK|RECESSION_ENERGY=PRICE_FOR_RISK'::text AS expected_value,
           (CASE WHEN count(*)=3
                       AND string_agg(reporting_scope_code||'='||strategy_profile_code,'|' ORDER BY reporting_scope_code)
                           ='BASELINE=BALANCED_FRONTIER|PORTFOLIO=PRICE_FOR_RISK|RECESSION_ENERGY=PRICE_FOR_RISK'
                       AND bool_and(governance_review_priority_code='PRIMARY_GOVERNANCE_REVIEW')
                  THEN 0 ELSE 1 END)::bigint AS mismatch_count,
           (count(*)=3
            AND string_agg(reporting_scope_code||'='||strategy_profile_code,'|' ORDER BY reporting_scope_code)
                ='BASELINE=BALANCED_FRONTIER|PORTFOLIO=PRICE_FOR_RISK|RECESSION_ENERGY=PRICE_FOR_RISK'
            AND bool_and(governance_review_priority_code='PRIMARY_GOVERNANCE_REVIEW')) AS pass_flag,
           'Priority rows are governance-review recommendations only; no champion or deployment authority is asserted.'::text AS interpretation
    FROM msbf_m2.portfolio_strategy_simulation_latest s
    JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=s.module1_run_id
    WHERE s.primary_governance_review_flag
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_113_FRONTIER_COUNTS_EXACT */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    113::smallint,
    'M2_12_POS_113_FRONTIER_COUNTS_EXACT'::text,
    8::smallint,
    'M2_11_BOUNDARY'::text,
    'M2.11 frontier eligibility, non-dominance, and rank-one counts are exact'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    SELECT concat_ws('|',count(*) FILTER (WHERE frontier_eligible_flag),count(*) FILTER (WHERE non_dominated_flag),
                     count(*) FILTER (WHERE frontier_rank=1)) AS observed_value,
           '18|16|16'::text AS expected_value,
           (CASE WHEN count(*)=24 AND count(*) FILTER (WHERE frontier_eligible_flag)=18
                       AND count(*) FILTER (WHERE non_dominated_flag)=16 AND count(*) FILTER (WHERE frontier_rank=1)=16
                  THEN 0 ELSE 1 END)::bigint AS mismatch_count,
           (count(*)=24 AND count(*) FILTER (WHERE frontier_eligible_flag)=18
            AND count(*) FILTER (WHERE non_dominated_flag)=16 AND count(*) FILTER (WHERE frontier_rank=1)=16) AS pass_flag,
           'Frontier classifications are reproduced as accepted comparative evidence.'::text AS interpretation
    FROM msbf_m2.portfolio_strategy_simulation_latest s
    JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=s.module1_run_id
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_114_STRESS_AND_IMPROVEMENT_GUARDS */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    114::smallint,
    'M2_12_POS_114_STRESS_AND_IMPROVEMENT_GUARDS'::text,
    8::smallint,
    'M2_11_BOUNDARY'::text,
    'All M2.11 hard-constraint, source-improvement, strategy-improvement, and stress guard violations are zero'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    SELECT concat_ws('|',sum(hard_constraint_violation_count+source_risk_improvement_violation_count+source_return_improvement_violation_count
                           +strategy_access_improvement_violation_count+strategy_feasibility_improvement_violation_count
                           +comparable_payment_burden_improvement_violation_count+comparable_servicing_burden_improvement_violation_count
                           +stress_improvement_violation_count),
                     count(*) FILTER (WHERE strategy_evidence_status='PARTIAL'),count(*) FILTER (WHERE stress_nonimprovement_pass_flag)) AS observed_value,
           '0|24|24'::text AS expected_value,
           (CASE WHEN count(*)=24
                       AND sum(hard_constraint_violation_count+source_risk_improvement_violation_count+source_return_improvement_violation_count
                           +strategy_access_improvement_violation_count+strategy_feasibility_improvement_violation_count
                           +comparable_payment_burden_improvement_violation_count+comparable_servicing_burden_improvement_violation_count
                           +stress_improvement_violation_count)=0
                       AND count(*) FILTER (WHERE strategy_evidence_status='PARTIAL')=24
                       AND count(*) FILTER (WHERE stress_nonimprovement_pass_flag)=24 THEN 0 ELSE 1 END)::bigint AS mismatch_count,
           (count(*)=24
            AND sum(hard_constraint_violation_count+source_risk_improvement_violation_count+source_return_improvement_violation_count
                +strategy_access_improvement_violation_count+strategy_feasibility_improvement_violation_count
                +comparable_payment_burden_improvement_violation_count+comparable_servicing_burden_improvement_violation_count
                +stress_improvement_violation_count)=0
            AND count(*) FILTER (WHERE strategy_evidence_status='PARTIAL')=24
            AND count(*) FILTER (WHERE stress_nonimprovement_pass_flag)=24) AS pass_flag,
           'M2.12 preserves M2.11''s 24 accepted bounded PARTIAL evidence rows, zero guard violations, and 24 stress non-improvement passes without converting them into optimization authority.'::text AS interpretation
    FROM msbf_m2.portfolio_strategy_simulation_latest s
    JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=s.module1_run_id
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_115_GOVERNANCE_ONLY_NO_DEPLOYMENT */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    115::smallint,
    'M2_12_POS_115_GOVERNANCE_ONLY_NO_DEPLOYMENT'::text,
    8::smallint,
    'M2_11_BOUNDARY'::text,
    'M2.11 strategy evidence remains governance-review-only with deployment and Module 3 prohibited'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    SELECT concat_ws('|',count(*) FILTER (WHERE primary_governance_review_flag),
                     count(*) FILTER (WHERE deployment_authorized_flag),count(*) FILTER (WHERE module3_execution_authorized_flag)) AS observed_value,
           '3|0|0'::text AS expected_value,
           (CASE WHEN count(*)=24 AND count(*) FILTER (WHERE primary_governance_review_flag)=3
                       AND count(*) FILTER (WHERE deployment_authorized_flag)=0
                       AND count(*) FILTER (WHERE module3_execution_authorized_flag)=0 THEN 0 ELSE 1 END)::bigint AS mismatch_count,
           (count(*)=24 AND count(*) FILTER (WHERE primary_governance_review_flag)=3
            AND count(*) FILTER (WHERE deployment_authorized_flag)=0
            AND count(*) FILTER (WHERE module3_execution_authorized_flag)=0) AS pass_flag,
           'Governance priority is not a champion, deployment, or production decision.'::text AS interpretation
    FROM msbf_m2.v_m2_12_strategy_scope_consumption v
    JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=v.module1_run_id
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_116_FIVE_DIRECT_SOURCE_EDGES */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    116::smallint,
    'M2_12_POS_116_FIVE_DIRECT_SOURCE_EDGES'::text,
    8::smallint,
    'M2_11_BOUNDARY'::text,
    'All five M2.11 direct-source edges reconcile exactly and independently'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    SELECT concat_ws('|',count(*),array_agg(edge_code ORDER BY edge_sequence)::text,
                     count(*) FILTER (WHERE edge_status<>'PASS' OR source_hash_mismatch_flag OR target_hash_mismatch_flag)) AS observed_value,
           concat_ws('|',5,ARRAY['M1_17_TO_M2_11','M2_2_TO_M2_11','M2_4_TO_M2_11','M2_7_TO_M2_11','M2_10_TO_M2_11']::text[]::text,0) AS expected_value,
           (CASE WHEN count(*)=5 AND array_agg(edge_code ORDER BY edge_sequence)=ARRAY['M1_17_TO_M2_11','M2_2_TO_M2_11','M2_4_TO_M2_11','M2_7_TO_M2_11','M2_10_TO_M2_11']::text[]
                       AND count(*) FILTER (WHERE edge_status<>'PASS' OR source_hash_mismatch_flag OR target_hash_mismatch_flag)=0
                  THEN 0 ELSE 1 END)::bigint AS mismatch_count,
           (count(*)=5 AND array_agg(edge_code ORDER BY edge_sequence)=ARRAY['M1_17_TO_M2_11','M2_2_TO_M2_11','M2_4_TO_M2_11','M2_7_TO_M2_11','M2_10_TO_M2_11']::text[]
            AND count(*) FILTER (WHERE edge_status<>'PASS' OR source_hash_mismatch_flag OR target_hash_mismatch_flag)=0) AS pass_flag,
           'M2.11 multi-source lineage is physically reconstructed rather than inferred from its accepted status.'::text AS interpretation
    FROM tmp_eval_m2_12_validation_source_edges
    WHERE target_node_code='M2_11_STRATEGY_SIMULATION'
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_117_CAPABILITY_CATALOG_EXACT */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    117::smallint,
    'M2_12_POS_117_CAPABILITY_CATALOG_EXACT'::text,
    9::smallint,
    'CAPABILITY_AND_NONPRODUCTION'::text,
    'All 20 persisted capability rows match the frozen R4 catalog exactly'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH a AS (SELECT * FROM tmp_src_m2_12_capability_authority),
    p AS (
      SELECT c.* FROM msbf_m2.module2_capability_coverage_snapshot c
      JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=c.module1_run_id
    ), cmp AS (
      SELECT count(*) FILTER (WHERE a.capability_sequence IS NULL OR p.module1_run_id IS NULL
        OR p.capability_code IS DISTINCT FROM a.capability_code
        OR p.coverage_status_code IS DISTINCT FROM a.coverage_status_code
        OR p.certifying_stage_code IS DISTINCT FROM a.certifying_stage_code
        OR p.claim_boundary IS DISTINCT FROM a.claim_boundary
        OR p.production_action_authorized_flag IS DISTINCT FROM a.production_action_authorized_flag
        OR p.legal_or_regulatory_certified_flag IS DISTINCT FROM a.legal_or_regulatory_certified_flag
        OR p.notes IS DISTINCT FROM a.notes
        OR p.row_hash IS DISTINCT FROM md5((to_jsonb(p)-'row_hash'-'created_at')::text))::bigint AS mismatch_rows
      FROM a FULL JOIN p USING(capability_sequence,capability_code)
    )
    SELECT concat_ws('|',(SELECT count(*) FROM a),(SELECT count(*) FROM p),(SELECT mismatch_rows FROM cmp)) AS observed_value,
           '20|20|0'::text AS expected_value,
           ((SELECT (count(*)<>20)::integer FROM a)+(SELECT (count(*)<>20)::integer FROM p)+(SELECT mismatch_rows FROM cmp))::bigint AS mismatch_count,
           ((SELECT count(*)=20 FROM a) AND (SELECT count(*)=20 FROM p) AND (SELECT mismatch_rows=0 FROM cmp)) AS pass_flag,
           'The persisted capability surface is exactly the frozen R4 catalog, including deferred and prohibited capabilities.'::text AS interpretation
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_118_CAPABILITY_STATUS_DISTRIBUTION */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    118::smallint,
    'M2_12_POS_118_CAPABILITY_STATUS_DISTRIBUTION'::text,
    9::smallint,
    'CAPABILITY_AND_NONPRODUCTION'::text,
    'Capability status distribution is exact across implemented, deferred, prohibited, and unsupported classes'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH expected(status_code,expected_rows) AS (VALUES ('DEFERRED_NOT_CERTIFIED',2),('DEFERRED_NOT_IMPLEMENTED',3),('IMPLEMENTED_BOUNDED_RECOMMENDATION',1),('IMPLEMENTED_BOUNDED_SYNTHETIC',4),('IMPLEMENTED_CERTIFIED',3),('IMPLEMENTED_CERTIFIED_ANALYTICS',1),('IMPLEMENTED_CERTIFIED_COMPARATIVE',1),('IMPLEMENTED_CERTIFIED_SYNTHETIC',2),('NOT_SUPPORTED_NOT_AUTHORIZED',1),('PROHIBITED_NOT_AUTHORIZED',2)),
    observed AS (
      SELECT coverage_status_code AS status_code,count(*)::integer observed_rows
      FROM msbf_m2.module2_capability_coverage_snapshot c
      JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=c.module1_run_id
      GROUP BY coverage_status_code
    ), cmp AS (
      SELECT coalesce(e.status_code,o.status_code) status_code,e.expected_rows,o.observed_rows
      FROM expected e FULL JOIN observed o USING(status_code)
    )
    SELECT string_agg(status_code||'='||coalesce(observed_rows,0)::text,'|' ORDER BY status_code) AS observed_value,
           'DEFERRED_NOT_CERTIFIED=2|DEFERRED_NOT_IMPLEMENTED=3|IMPLEMENTED_BOUNDED_RECOMMENDATION=1|IMPLEMENTED_BOUNDED_SYNTHETIC=4|IMPLEMENTED_CERTIFIED=3|IMPLEMENTED_CERTIFIED_ANALYTICS=1|IMPLEMENTED_CERTIFIED_COMPARATIVE=1|IMPLEMENTED_CERTIFIED_SYNTHETIC=2|NOT_SUPPORTED_NOT_AUTHORIZED=1|PROHIBITED_NOT_AUTHORIZED=2'::text AS expected_value,
           count(*) FILTER (WHERE expected_rows IS DISTINCT FROM observed_rows)::bigint AS mismatch_count,
           (count(*)=10 AND count(*) FILTER (WHERE expected_rows IS DISTINCT FROM observed_rows)=0) AS pass_flag,
           'Status totals preserve the precise R4 as-built, deferred, prohibited, and unsupported capability boundary.'::text AS interpretation
    FROM cmp
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_119_IMPLEMENTED_CAPABILITIES_STAGE_BOUND */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    119::smallint,
    'M2_12_POS_119_IMPLEMENTED_CAPABILITIES_STAGE_BOUND'::text,
    9::smallint,
    'CAPABILITY_AND_NONPRODUCTION'::text,
    'The 12 implemented capabilities are bound to their exact certifying stages'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    SELECT concat_ws('|',count(*),count(*) FILTER (WHERE coverage_status_code LIKE 'IMPLEMENTED_%' AND certifying_stage_code<>'NONE'),
                     count(*) FILTER (WHERE NOT EXISTS (
                       SELECT 1 FROM msbf_m2.module2_stage_certification_snapshot s
                       WHERE s.module1_run_id=c.module1_run_id AND s.stage_code=c.certifying_stage_code AND s.certification_status='PASS'))) AS observed_value,
           '12|12|0'::text AS expected_value,
           (CASE WHEN count(*)=12 AND count(*) FILTER (WHERE coverage_status_code LIKE 'IMPLEMENTED_%' AND certifying_stage_code<>'NONE')=12
                       AND count(*) FILTER (WHERE NOT EXISTS (
                         SELECT 1 FROM msbf_m2.module2_stage_certification_snapshot s
                         WHERE s.module1_run_id=c.module1_run_id AND s.stage_code=c.certifying_stage_code AND s.certification_status='PASS'))=0
                  THEN 0 ELSE 1 END)::bigint AS mismatch_count,
           (count(*)=12 AND count(*) FILTER (WHERE coverage_status_code LIKE 'IMPLEMENTED_%' AND certifying_stage_code<>'NONE')=12
            AND count(*) FILTER (WHERE NOT EXISTS (
              SELECT 1 FROM msbf_m2.module2_stage_certification_snapshot s
              WHERE s.module1_run_id=c.module1_run_id AND s.stage_code=c.certifying_stage_code AND s.certification_status='PASS'))=0) AS pass_flag,
           'Implemented claims are bounded to persisted accepted-stage certification evidence.'::text AS interpretation
    FROM msbf_m2.module2_capability_coverage_snapshot c
    JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=c.module1_run_id
    WHERE c.capability_sequence BETWEEN 1 AND 12
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_120_DEFERRED_PROHIBITED_CAPABILITIES_EXACT */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    120::smallint,
    'M2_12_POS_120_DEFERRED_PROHIBITED_CAPABILITIES_EXACT'::text,
    9::smallint,
    'CAPABILITY_AND_NONPRODUCTION'::text,
    'Capabilities 13-20 remain explicitly deferred, prohibited, or unsupported and have no certifying stage'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    SELECT concat_ws('|',count(*),count(*) FILTER (WHERE coverage_status_code LIKE 'IMPLEMENTED_%'),
                     count(*) FILTER (WHERE certifying_stage_code='NONE'),count(*) FILTER (WHERE length(btrim(claim_boundary))>0)) AS observed_value,
           '8|0|8|8'::text AS expected_value,
           (CASE WHEN count(*)=8 AND count(*) FILTER (WHERE coverage_status_code LIKE 'IMPLEMENTED_%')=0
                       AND count(*) FILTER (WHERE certifying_stage_code='NONE')=8
                       AND count(*) FILTER (WHERE length(btrim(claim_boundary))>0)=8 THEN 0 ELSE 1 END)::bigint AS mismatch_count,
           (count(*)=8 AND count(*) FILTER (WHERE coverage_status_code LIKE 'IMPLEMENTED_%')=0
            AND count(*) FILTER (WHERE certifying_stage_code='NONE')=8
            AND count(*) FILTER (WHERE length(btrim(claim_boundary))>0)=8) AS pass_flag,
           'Unimplemented or unauthorized capabilities remain explicit limitations rather than inferred coverage.'::text AS interpretation
    FROM msbf_m2.module2_capability_coverage_snapshot c
    JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=c.module1_run_id
    WHERE c.capability_sequence BETWEEN 13 AND 20
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_121_CAPABILITY_FLAGS_ALL_FALSE */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    121::smallint,
    'M2_12_POS_121_CAPABILITY_FLAGS_ALL_FALSE'::text,
    9::smallint,
    'CAPABILITY_AND_NONPRODUCTION'::text,
    'Every capability row has production-action and legal/regulatory certification flags false'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    SELECT concat_ws('|',count(*),count(*) FILTER (WHERE production_action_authorized_flag),
                     count(*) FILTER (WHERE legal_or_regulatory_certified_flag)) AS observed_value,
           '20|0|0'::text AS expected_value,
           (CASE WHEN count(*)=20 AND count(*) FILTER (WHERE production_action_authorized_flag)=0
                       AND count(*) FILTER (WHERE legal_or_regulatory_certified_flag)=0 THEN 0 ELSE 1 END)::bigint AS mismatch_count,
           (count(*)=20 AND count(*) FILTER (WHERE production_action_authorized_flag)=0
            AND count(*) FILTER (WHERE legal_or_regulatory_certified_flag)=0) AS pass_flag,
           'Capability coverage never grants production action or legal/regulatory certification.'::text AS interpretation
    FROM msbf_m2.module2_capability_coverage_snapshot c
    JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=c.module1_run_id
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_122_POLICY_LATEST_REGISTRY_BOUNDARY_COHERENCE */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    122::smallint,
    'M2_12_POS_122_POLICY_LATEST_REGISTRY_BOUNDARY_COHERENCE'::text,
    9::smallint,
    'CAPABILITY_AND_NONPRODUCTION'::text,
    'Policy, G3 latest, and G3 registry carry the same exact non-production boundary'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH b AS (
      SELECT module1_run_id,synthetic_data_only_flag,no_pii_flag,certification_only_flag,
             production_action_authorized_flag,external_system_update_authorized_flag,legal_or_regulatory_certified_flag,
             empirical_or_causal_optimization_authorized_flag,FALSE::boolean deployment_authorized_flag,
             module3_execution_authorized_flag
      FROM msbf_ctl.m2_12_policy_profile p JOIN tmp_src_m2_12_validation_run_context ctx USING(module1_run_id)
      UNION ALL
      SELECT module1_run_id,synthetic_data_only_flag,no_pii_flag,certification_only_flag,
             production_action_authorized_flag,external_system_update_authorized_flag,legal_or_regulatory_certified_flag,
             empirical_or_causal_optimization_authorized_flag,deployment_authorized_flag,module3_execution_authorized_flag
      FROM msbf_ctl.m2_12_g3_bundle_latest l JOIN tmp_src_m2_12_validation_run_context ctx USING(module1_run_id)
      UNION ALL
      SELECT module1_run_id,synthetic_data_only_flag,no_pii_flag,certification_only_flag,
             production_action_authorized_flag,external_system_update_authorized_flag,legal_or_regulatory_certified_flag,
             empirical_or_causal_optimization_authorized_flag,deployment_authorized_flag,module3_execution_authorized_flag
      FROM msbf_ctl.m2_12_g3_bundle_registry r JOIN tmp_src_m2_12_validation_run_context ctx USING(module1_run_id)
    )
    SELECT concat_ws('|',count(*),count(*) FILTER (WHERE synthetic_data_only_flag AND no_pii_flag AND certification_only_flag),
                     count(*) FILTER (WHERE production_action_authorized_flag OR external_system_update_authorized_flag
                                           OR legal_or_regulatory_certified_flag OR empirical_or_causal_optimization_authorized_flag
                                           OR deployment_authorized_flag OR module3_execution_authorized_flag)) AS observed_value,
           '3|3|0'::text AS expected_value,
           (CASE WHEN count(*)=3 AND count(*) FILTER (WHERE synthetic_data_only_flag AND no_pii_flag AND certification_only_flag)=3
                       AND count(*) FILTER (WHERE production_action_authorized_flag OR external_system_update_authorized_flag
                                                OR legal_or_regulatory_certified_flag OR empirical_or_causal_optimization_authorized_flag
                                                OR deployment_authorized_flag OR module3_execution_authorized_flag)=0 THEN 0 ELSE 1 END)::bigint AS mismatch_count,
           (count(*)=3 AND count(*) FILTER (WHERE synthetic_data_only_flag AND no_pii_flag AND certification_only_flag)=3
            AND count(*) FILTER (WHERE production_action_authorized_flag OR external_system_update_authorized_flag
                                      OR legal_or_regulatory_certified_flag OR empirical_or_causal_optimization_authorized_flag
                                      OR deployment_authorized_flag OR module3_execution_authorized_flag)=0) AS pass_flag,
           'The non-production boundary is coherent across policy, latest, and registry contract surfaces.'::text AS interpretation
    FROM b
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_123_NINE_FAMILY_COUNTS_AND_ROW_HASHES */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    123::smallint,
    'M2_12_POS_123_NINE_FAMILY_COUNTS_AND_ROW_HASHES'::text,
    10::smallint,
    'CANONICAL_AND_G3_HASHES'::text,
    'All nine canonical families contain exactly 134 entities with zero row-hash mismatch'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    SELECT concat_ws('|',canonical_families,canonical_entities,family_count_mismatch_count,row_hash_mismatch_count) AS observed_value,
           '9|134|0|0'::text AS expected_value,
           (CASE WHEN canonical_families=9 AND canonical_entities=134 AND family_count_mismatch_count=0 AND row_hash_mismatch_count=0 THEN 0 ELSE 1 END)::bigint AS mismatch_count,
           (canonical_families=9 AND canonical_entities=134 AND family_count_mismatch_count=0 AND row_hash_mismatch_count=0) AS pass_flag,
           'Canonical counts and row preimages are reconstructed from persisted physical rows.'::text AS interpretation
    FROM tmp_hash_m2_12_validation_reconciliation
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_124_NINE_FAMILY_SET_HASHES */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    124::smallint,
    'M2_12_POS_124_NINE_FAMILY_SET_HASHES'::text,
    10::smallint,
    'CANONICAL_AND_G3_HASHES'::text,
    'All nine canonical family set hashes reconstruct with zero mismatch'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    SELECT set_hash_mismatch_count::text AS observed_value,'0'::text AS expected_value,
           set_hash_mismatch_count::bigint AS mismatch_count,(set_hash_mismatch_count=0) AS pass_flag,
           'All ordered family set hashes are independently reconstructed.'::text AS interpretation
    FROM tmp_hash_m2_12_validation_reconciliation
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_125_CONTRACT_AND_COMBINED_HASH_CHAIN */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    125::smallint,
    'M2_12_POS_125_CONTRACT_AND_COMBINED_HASH_CHAIN'::text,
    10::smallint,
    'CANONICAL_AND_G3_HASHES'::text,
    'G3 contract-set and 134-entity combined hashes reconstruct with zero mismatch'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    SELECT concat_ws('|',contract_hash_mismatch_count,combined_hash_mismatch_count) AS observed_value,
           '0|0'::text AS expected_value,
           (contract_hash_mismatch_count+combined_hash_mismatch_count)::bigint AS mismatch_count,
           (contract_hash_mismatch_count=0 AND combined_hash_mismatch_count=0) AS pass_flag,
           'The acyclic G3 contract and combined hash chain is exact.'::text AS interpretation
    FROM tmp_hash_m2_12_validation_reconciliation
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_126_ACCEPTED_SOURCE_HASH_CHAIN */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    126::smallint,
    'M2_12_POS_126_ACCEPTED_SOURCE_HASH_CHAIN'::text,
    10::smallint,
    'CANONICAL_AND_G3_HASHES'::text,
    'Accepted M2.11 project and registry hashes are identical across policy, G3 latest, G3 registry, and physical M2.11 source'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH p AS (SELECT * FROM msbf_ctl.m2_12_policy_profile p JOIN tmp_src_m2_12_validation_run_context ctx USING(module1_run_id)),
    l AS (SELECT * FROM msbf_ctl.m2_12_g3_bundle_latest l JOIN tmp_src_m2_12_validation_run_context ctx USING(module1_run_id)),
    g AS (SELECT * FROM msbf_ctl.m2_12_g3_bundle_registry g JOIN tmp_src_m2_12_validation_run_context ctx USING(module1_run_id)),
    s AS (SELECT * FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry s JOIN tmp_src_m2_12_validation_run_context ctx USING(module1_run_id) WHERE s.contract_code='M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION' AND s.contract_version=1 AND s.contract_status='ACCEPTED')
    SELECT concat_ws('|',(SELECT count(*) FROM p),(SELECT count(*) FROM l),(SELECT count(*) FROM g),(SELECT count(*) FROM s),
             (SELECT count(*) FROM p,l,g,s WHERE p.accepted_m2_11_project_sha256='92f0491eea26b0d546c85992e27433cd006a0b2f126c32a139d795b7749904fc'
               AND p.accepted_m2_11_contract_set_hash=s.contract_set_hash AND p.accepted_m2_11_combined_set_hash=s.combined_set_hash AND p.accepted_m2_11_registry_row_hash=s.row_hash
               AND l.source_m2_11_contract_set_hash=s.contract_set_hash AND l.source_m2_11_combined_set_hash=s.combined_set_hash AND l.source_m2_11_registry_row_hash=s.row_hash
               AND g.accepted_m2_11_contract_set_hash=s.contract_set_hash AND g.accepted_m2_11_combined_set_hash=s.combined_set_hash AND g.accepted_m2_11_registry_row_hash=s.row_hash)) AS observed_value,
           '1|1|1|1|1'::text AS expected_value,
           (CASE WHEN (SELECT count(*) FROM p)=1 AND (SELECT count(*) FROM l)=1 AND (SELECT count(*) FROM g)=1 AND (SELECT count(*) FROM s)=1
                       AND (SELECT count(*) FROM p,l,g,s WHERE p.accepted_m2_11_project_sha256='92f0491eea26b0d546c85992e27433cd006a0b2f126c32a139d795b7749904fc'
                         AND p.accepted_m2_11_contract_set_hash=s.contract_set_hash AND p.accepted_m2_11_combined_set_hash=s.combined_set_hash AND p.accepted_m2_11_registry_row_hash=s.row_hash
                         AND l.source_m2_11_contract_set_hash=s.contract_set_hash AND l.source_m2_11_combined_set_hash=s.combined_set_hash AND l.source_m2_11_registry_row_hash=s.row_hash
                         AND g.accepted_m2_11_contract_set_hash=s.contract_set_hash AND g.accepted_m2_11_combined_set_hash=s.combined_set_hash AND g.accepted_m2_11_registry_row_hash=s.row_hash)=1
                  THEN 0 ELSE 1 END)::bigint AS mismatch_count,
           ((SELECT count(*) FROM p)=1 AND (SELECT count(*) FROM l)=1 AND (SELECT count(*) FROM g)=1 AND (SELECT count(*) FROM s)=1
            AND (SELECT count(*) FROM p,l,g,s WHERE p.accepted_m2_11_project_sha256='92f0491eea26b0d546c85992e27433cd006a0b2f126c32a139d795b7749904fc'
              AND p.accepted_m2_11_contract_set_hash=s.contract_set_hash AND p.accepted_m2_11_combined_set_hash=s.combined_set_hash AND p.accepted_m2_11_registry_row_hash=s.row_hash
              AND l.source_m2_11_contract_set_hash=s.contract_set_hash AND l.source_m2_11_combined_set_hash=s.combined_set_hash AND l.source_m2_11_registry_row_hash=s.row_hash
              AND g.accepted_m2_11_contract_set_hash=s.contract_set_hash AND g.accepted_m2_11_combined_set_hash=s.combined_set_hash AND g.accepted_m2_11_registry_row_hash=s.row_hash)=1) AS pass_flag,
           'Accepted M2.11 physical source identity is copied without reinterpretation.'::text AS interpretation
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_127_OWNED_SEQUENCE_STATES */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    127::smallint,
    'M2_12_POS_127_OWNED_SEQUENCE_STATES'::text,
    10::smallint,
    'CANONICAL_AND_G3_HASHES'::text,
    'All three M2.12-owned identity sequences remain exactly at last_value 1 and is_called true'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    SELECT concat_ws('|',p.last_value,p.is_called,a.last_value,a.is_called,r.last_value,r.is_called) AS observed_value,
           '1|true|1|true|1|true'::text AS expected_value,
           (CASE WHEN p.last_value=1 AND p.is_called AND a.last_value=1 AND a.is_called AND r.last_value=1 AND r.is_called THEN 0 ELSE 1 END)::bigint AS mismatch_count,
           (p.last_value=1 AND p.is_called AND a.last_value=1 AND a.is_called AND r.last_value=1 AND r.is_called) AS pass_flag,
           'Validation is noncanonical and must not advance any M2.12-owned sequence.'::text AS interpretation
    FROM msbf_ctl.m2_12_policy_profile_policy_profile_id_seq p
    CROSS JOIN msbf_ctl.m2_12_g3_bundle_archive_archive_id_seq a
    CROSS JOIN msbf_ctl.m2_12_g3_bundle_registry_registry_id_seq r
) control_observation;


/* WP3_POSITIVE_CONTROL_DEFINITION M2_12_POS_128_FULL_RECONCILIATION_AND_GENERATION_EVIDENCE */
INSERT INTO tmp_eval_m2_12_positive_results
(
    control_sequence,evidence_code,control_family_sequence,control_family_code,
    control_title,observed_value,expected_value,mismatch_count,status,interpretation
)
SELECT
    128::smallint,
    'M2_12_POS_128_FULL_RECONCILIATION_AND_GENERATION_EVIDENCE'::text,
    10::smallint,
    'CANONICAL_AND_G3_HASHES'::text,
    'Full deterministic reconstruction has zero mismatch and the exact 24 generation-evidence rows remain PASS'::text,
    control_observation.observed_value::text,
    control_observation.expected_value::text,
    control_observation.mismatch_count::bigint,
    CASE WHEN control_observation.pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END,
    control_observation.interpretation::text
FROM (
    WITH ev AS (
      SELECT count(*)::integer AS rows,
             count(DISTINCT evidence_code)::integer AS codes,
             count(*) FILTER (WHERE status<>'PASS')::integer AS nonpass,
             count(*) FILTER (WHERE evidence_code<>ALL(ARRAY['M2_12_POLICY_SET_HASH','M2_12_STAGE_CERTIFICATION_SET_HASH','M2_12_CONTRACT_COMPONENT_SET_HASH','M2_12_EVIDENCE_CERTIFICATION_SET_HASH','M2_12_CONTRACT_REPRODUCTION_SET_HASH','M2_12_CAPABILITY_COVERAGE_SET_HASH','M2_12_LATEST_SET_HASH','M2_12_ARCHIVE_SET_HASH','M2_12_REGISTRY_SET_HASH','M2_12_CONTRACT_SET_HASH','M2_12_COMBINED_SET_HASH','M2_12_STAGE_CERTIFICATION_ROWS','M2_12_CONTRACT_COMPONENT_ROWS','M2_12_EVIDENCE_CERTIFICATION_ROWS','M2_12_CONTRACT_REPRODUCTION_ROWS','M2_12_CAPABILITY_COVERAGE_ROWS','M2_12_CANONICAL_ENTITIES','M2_12_COMPONENT_LATEST_ARCHIVE_ROWS_TOTAL','M2_12_APPLICATION_CONSUMPTION_ROWS','M2_12_OPERATIONAL_ACCOUNT_CONSUMPTION_ROWS','M2_12_STRATEGY_SCOPE_CONSUMPTION_ROWS','M2_12_SOURCE_GRAPH_EDGES','M2_12_DETERMINISTIC_MISMATCHES','M2_12_BLOCKING_STAGE_BOUNDARY_FINDINGS']::text[]))::integer AS unexpected
      FROM msbf_ctl.run_evidence e JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=e.run_id
      WHERE e.evidence_code LIKE 'M2_12_%' AND e.evidence_code NOT LIKE 'M2_12_POS_%' AND e.evidence_code NOT LIKE 'M2_12_NEG_%'
    )
    SELECT concat_ws('|',(SELECT count(*) FROM tmp_hash_m2_12_validation_reconciliation),r.total_mismatch_count,r.reconciliation_status,
                         ev.rows,ev.codes,ev.nonpass,ev.unexpected) AS observed_value,
           '1|0|PASS|24|24|0|0'::text AS expected_value,
           (CASE WHEN (SELECT count(*) FROM tmp_hash_m2_12_validation_reconciliation)=1
                       AND r.total_mismatch_count=0 AND r.reconciliation_status='PASS'
                       AND ev.rows=24 AND ev.codes=24 AND ev.nonpass=0 AND ev.unexpected=0 THEN 0 ELSE 1 END)::bigint AS mismatch_count,
           ((SELECT count(*) FROM tmp_hash_m2_12_validation_reconciliation)=1
            AND r.total_mismatch_count=0 AND r.reconciliation_status='PASS'
            AND ev.rows=24 AND ev.codes=24 AND ev.nonpass=0 AND ev.unexpected=0) AS pass_flag,
           'Positive validation preserves the exact generated checkpoint while independently rebuilding its canonical proof.'::text AS interpretation
    FROM tmp_hash_m2_12_validation_reconciliation r CROSS JOIN ev
) control_observation;



/* 128/128 release gate before any persistent write. */
DO $m212_p223_128_gate$
DECLARE
    v_rows integer;
    v_codes integer;
    v_fail integer;
    v_family_mismatch integer;
    v_failure_detail text;
BEGIN
    SELECT count(*),count(DISTINCT evidence_code),count(*) FILTER (WHERE status<>'PASS' OR mismatch_count<>0)
      INTO v_rows,v_codes,v_fail FROM tmp_eval_m2_12_positive_results;
    SELECT count(*) INTO v_family_mismatch
    FROM (VALUES
      (1,'IDENTITY',10),(2,'SOURCE_NODE_ACCEPTANCE',24),(3,'COMPONENT_CONTRACT',26),
      (4,'EVIDENCE_CERTIFICATION',12),(5,'LATEST_ARCHIVE_REPRODUCTION',13),(6,'SOURCE_GRAPH',12),
      (7,'CONSUMPTION_INTERFACES',12),(8,'M2_11_BOUNDARY',7),(9,'CAPABILITY_AND_NONPRODUCTION',6),
      (10,'CANONICAL_AND_G3_HASHES',6)
    ) x(family_sequence,family_code,expected_rows)
    LEFT JOIN (
      SELECT control_family_sequence,control_family_code,count(*)::integer observed_rows
      FROM tmp_eval_m2_12_positive_results GROUP BY 1,2
    ) o ON o.control_family_sequence=x.family_sequence AND o.control_family_code=x.family_code
    WHERE o.observed_rows IS DISTINCT FROM x.expected_rows;

    SELECT string_agg(
             format('%s:%s|status=%s|mismatches=%s|observed=%s|expected=%s',
                    control_sequence,evidence_code,status,mismatch_count,
                    coalesce(observed_value,'<NULL>'),coalesce(expected_value,'<NULL>')),
             '; ' ORDER BY control_sequence)
      INTO v_failure_detail
      FROM tmp_eval_m2_12_positive_results
     WHERE status<>'PASS' OR mismatch_count<>0;

    IF v_rows<>128 OR v_codes<>128 OR v_fail<>0 OR v_family_mismatch<>0
       OR (SELECT min(control_sequence)<>1 OR max(control_sequence)<>128 FROM tmp_eval_m2_12_positive_results) THEN
        RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 Program 223 HF12 positive validation did not achieve 128/128 PASS',
          DETAIL=format('rows=%s codes=%s failures=%s family_mismatches=%s failed_controls=%s',
                        v_rows,v_codes,v_fail,v_family_mismatch,coalesce(v_failure_detail,'<NONE>'));
    END IF;
END;
$m212_p223_128_gate$;


/* Persist positive evidence only after 128/128 PASS. */
INSERT INTO msbf_ctl.run_evidence
(
 run_id,evidence_code,segment_key,metric_name,metric_value_numeric,metric_value_text,
 unit_code,status,threshold_value_numeric,interpretation
)
SELECT ctx.module1_run_id,r.evidence_code,'M2_12'::text,r.evidence_code,
       NULL::numeric(24,10),r.observed_value,'CONTROL'::text,'PASS'::text,
       NULL::numeric(24,10),r.interpretation
FROM tmp_eval_m2_12_positive_results r
CROSS JOIN tmp_src_m2_12_validation_run_context ctx
ORDER BY r.control_sequence;


DO $m212_p223_evidence_postwrite$
BEGIN
    IF (SELECT count(*) FROM msbf_ctl.run_evidence e JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=e.run_id
        WHERE e.evidence_code LIKE 'M2_12_POS_%' AND e.status='PASS')<>128
       OR (SELECT count(DISTINCT e.evidence_code) FROM msbf_ctl.run_evidence e JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=e.run_id
        WHERE e.evidence_code LIKE 'M2_12_POS_%' AND e.status='PASS')<>128 THEN
        RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 Program 223 HF12 positive evidence persistence mismatch';
    END IF;
END;
$m212_p223_evidence_postwrite$;


/* Lifecycle transition is the only non-evidence persistent mutation. */
DO $m212_p223_lifecycle$
DECLARE
    v_registry_rows integer;
    v_run_rows integer;
BEGIN
    UPDATE msbf_ctl.m2_12_g3_bundle_registry r
       SET contract_status='VALIDATED',validated_at=clock_timestamp(),updated_at=clock_timestamp()
      FROM tmp_src_m2_12_validation_run_context ctx
     WHERE r.module1_run_id=ctx.module1_run_id
       AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1
       AND r.contract_status='GENERATED' AND r.generated_at IS NOT NULL
       AND r.validated_at IS NULL AND r.accepted_at IS NULL;
    GET DIAGNOSTICS v_registry_rows=ROW_COUNT;

    UPDATE msbf_ctl.run_registry rr
       SET run_status='M2_12_VALIDATED'
      FROM tmp_src_m2_12_validation_run_context ctx
     WHERE rr.run_id=ctx.module1_run_id AND rr.run_code='M1_V0_2_BASELINE_BUILD'
       AND rr.run_version=1 AND rr.run_status='M2_12_GENERATED';
    GET DIAGNOSTICS v_run_rows=ROW_COUNT;

    IF v_registry_rows<>1 OR v_run_rows<>1 THEN
        RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 Program 223 HF12 lifecycle transition affected an unexpected row count',
          DETAIL=format('registry=%s run=%s',v_registry_rows,v_run_rows);
    END IF;
END;
$m212_p223_lifecycle$;

/* HF12 post-write deterministic reconstruction: exact successfully executed Program 222 HF9 preimages. */
CREATE TEMP TABLE tmp_hash_m2_12_validation_postflight ON COMMIT DROP AS
SELECT
       p.module1_run_id::bigint AS module1_run_id,
       p.family_count_mismatch_count::bigint AS family_count_mismatch_count,
       p.row_hash_mismatch_count::bigint AS row_hash_mismatch_count,
       p.set_hash_mismatch_count::bigint AS set_hash_mismatch_count,
       p.contract_hash_mismatch_count::integer AS contract_hash_mismatch_count,
       p.combined_hash_mismatch_count::integer AS combined_hash_mismatch_count,
       p.sequence_state_mismatch_count::integer AS sequence_state_mismatch_count,
       p.canonical_families::integer AS canonical_families,
       p.canonical_entities::integer AS canonical_entities,
       p.total_mismatch_count::bigint AS total_mismatch_count,
       CASE WHEN p.total_mismatch_count=0 THEN 'PASS'::text ELSE 'FAIL'::text END AS reconciliation_status
FROM (
WITH row_detail AS ((SELECT 'POLICY'::text AS family_code, 1::bigint AS expected_rows, count(*)::bigint AS observed_rows, (count(*)<>1)::integer AS family_count_mismatch_count, count(*) FILTER (WHERE t.row_hash IS DISTINCT FROM md5((to_jsonb(t)-'policy_profile_id'-'row_hash'-'created_at'-'updated_at')::text))::bigint AS row_hash_mismatch_count FROM msbf_ctl.m2_12_policy_profile t JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id) UNION ALL (SELECT 'STAGE_CERTIFICATION'::text AS family_code, 12::bigint AS expected_rows, count(*)::bigint AS observed_rows, (count(*)<>12)::integer AS family_count_mismatch_count, count(*) FILTER (WHERE t.row_hash IS DISTINCT FROM md5((to_jsonb(t)-'row_hash'-'created_at')::text))::bigint AS row_hash_mismatch_count FROM msbf_m2.module2_stage_certification_snapshot t JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id) UNION ALL (SELECT 'CONTRACT_COMPONENT'::text AS family_code, 13::bigint AS expected_rows, count(*)::bigint AS observed_rows, (count(*)<>13)::integer AS family_count_mismatch_count, count(*) FILTER (WHERE t.row_hash IS DISTINCT FROM md5((to_jsonb(t)-'row_hash'-'created_at')::text))::bigint AS row_hash_mismatch_count FROM msbf_m2.module2_contract_component_snapshot t JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id) UNION ALL (SELECT 'EVIDENCE_CERTIFICATION'::text AS family_code, 72::bigint AS expected_rows, count(*)::bigint AS observed_rows, (count(*)<>72)::integer AS family_count_mismatch_count, count(*) FILTER (WHERE t.row_hash IS DISTINCT FROM md5((to_jsonb(t)-'row_hash'-'created_at')::text))::bigint AS row_hash_mismatch_count FROM msbf_m2.module2_evidence_certification_snapshot t JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id) UNION ALL (SELECT 'CONTRACT_REPRODUCTION'::text AS family_code, 13::bigint AS expected_rows, count(*)::bigint AS observed_rows, (count(*)<>13)::integer AS family_count_mismatch_count, count(*) FILTER (WHERE t.row_hash IS DISTINCT FROM md5((to_jsonb(t)-'row_hash'-'created_at')::text))::bigint AS row_hash_mismatch_count FROM msbf_m2.module2_contract_reproduction_snapshot t JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id) UNION ALL (SELECT 'CAPABILITY_COVERAGE'::text AS family_code, 20::bigint AS expected_rows, count(*)::bigint AS observed_rows, (count(*)<>20)::integer AS family_count_mismatch_count, count(*) FILTER (WHERE t.row_hash IS DISTINCT FROM md5((to_jsonb(t)-'row_hash'-'created_at')::text))::bigint AS row_hash_mismatch_count FROM msbf_m2.module2_capability_coverage_snapshot t JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id) UNION ALL (SELECT 'LATEST'::text AS family_code, 1::bigint AS expected_rows, count(*)::bigint AS observed_rows, (count(*)<>1)::integer AS family_count_mismatch_count, count(*) FILTER (WHERE t.row_hash IS DISTINCT FROM md5((to_jsonb(t)-'row_hash'-'created_at')::text))::bigint AS row_hash_mismatch_count FROM msbf_ctl.m2_12_g3_bundle_latest t JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id) UNION ALL (SELECT 'ARCHIVE'::text AS family_code, 1::bigint AS expected_rows, count(*)::bigint AS observed_rows, (count(*)<>1)::integer AS family_count_mismatch_count, count(*) FILTER (WHERE t.archive_row_hash IS DISTINCT FROM md5((to_jsonb(t)-'archive_id'-'archive_row_hash'-'created_at')::text))::bigint AS row_hash_mismatch_count FROM msbf_ctl.m2_12_g3_bundle_archive t JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id) UNION ALL (SELECT 'REGISTRY'::text AS family_code, 1::bigint AS expected_rows, count(*)::bigint AS observed_rows, (count(*)<>1)::integer AS family_count_mismatch_count, count(*) FILTER (WHERE t.row_hash IS DISTINCT FROM md5((to_jsonb(t)-'registry_id'-'contract_status'-'generated_at'-'validated_at'-'accepted_at'-'created_at'-'updated_at'-'row_hash'-'policy_set_hash'-'stage_certification_set_hash'-'contract_component_set_hash'-'evidence_certification_set_hash'-'contract_reproduction_set_hash'-'capability_coverage_set_hash'-'latest_set_hash'-'archive_set_hash'-'registry_set_hash'-'contract_set_hash'-'combined_set_hash')::text))::bigint AS row_hash_mismatch_count FROM msbf_ctl.m2_12_g3_bundle_registry t JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id)),
rowd AS (SELECT sum(family_count_mismatch_count)::bigint family_count_mismatch_count,sum(row_hash_mismatch_count)::bigint row_hash_mismatch_count FROM row_detail),
set_detail AS ((SELECT 'POLICY'::text AS family_code, md5(string_agg(concat_ws('|',t.policy_code::text,t.policy_version::text,t.row_hash::text),'|' ORDER BY t.policy_code, t.policy_version))::text AS reconstructed_set_hash, r.policy_set_hash::text AS stored_set_hash, (md5(string_agg(concat_ws('|',t.policy_code::text,t.policy_version::text,t.row_hash::text),'|' ORDER BY t.policy_code, t.policy_version)) IS DISTINCT FROM r.policy_set_hash)::integer AS set_hash_mismatch_count FROM msbf_ctl.m2_12_policy_profile t JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1 GROUP BY r.policy_set_hash) UNION ALL (SELECT 'STAGE_CERTIFICATION'::text AS family_code, md5(string_agg(concat_ws('|',t.certification_node_sequence::text,t.stage_code::text,t.row_hash::text),'|' ORDER BY t.certification_node_sequence, t.stage_code))::text AS reconstructed_set_hash, r.stage_certification_set_hash::text AS stored_set_hash, (md5(string_agg(concat_ws('|',t.certification_node_sequence::text,t.stage_code::text,t.row_hash::text),'|' ORDER BY t.certification_node_sequence, t.stage_code)) IS DISTINCT FROM r.stage_certification_set_hash)::integer AS set_hash_mismatch_count FROM msbf_m2.module2_stage_certification_snapshot t JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1 GROUP BY r.stage_certification_set_hash) UNION ALL (SELECT 'CONTRACT_COMPONENT'::text AS family_code, md5(string_agg(concat_ws('|',t.component_sequence::text,t.component_contract_code::text,t.contract_version::text,t.row_hash::text),'|' ORDER BY t.component_sequence, t.component_contract_code, t.contract_version))::text AS reconstructed_set_hash, r.contract_component_set_hash::text AS stored_set_hash, (md5(string_agg(concat_ws('|',t.component_sequence::text,t.component_contract_code::text,t.contract_version::text,t.row_hash::text),'|' ORDER BY t.component_sequence, t.component_contract_code, t.contract_version)) IS DISTINCT FROM r.contract_component_set_hash)::integer AS set_hash_mismatch_count FROM msbf_m2.module2_contract_component_snapshot t JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1 GROUP BY r.contract_component_set_hash) UNION ALL (SELECT 'EVIDENCE_CERTIFICATION'::text AS family_code, md5(string_agg(concat_ws('|',t.node_sequence::text,t.evidence_family_sequence::text,t.row_hash::text),'|' ORDER BY t.node_sequence, t.evidence_family_sequence))::text AS reconstructed_set_hash, r.evidence_certification_set_hash::text AS stored_set_hash, (md5(string_agg(concat_ws('|',t.node_sequence::text,t.evidence_family_sequence::text,t.row_hash::text),'|' ORDER BY t.node_sequence, t.evidence_family_sequence)) IS DISTINCT FROM r.evidence_certification_set_hash)::integer AS set_hash_mismatch_count FROM msbf_m2.module2_evidence_certification_snapshot t JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1 GROUP BY r.evidence_certification_set_hash) UNION ALL (SELECT 'CONTRACT_REPRODUCTION'::text AS family_code, md5(string_agg(concat_ws('|',t.component_sequence::text,t.component_contract_code::text,t.contract_version::text,t.row_hash::text),'|' ORDER BY t.component_sequence, t.component_contract_code, t.contract_version))::text AS reconstructed_set_hash, r.contract_reproduction_set_hash::text AS stored_set_hash, (md5(string_agg(concat_ws('|',t.component_sequence::text,t.component_contract_code::text,t.contract_version::text,t.row_hash::text),'|' ORDER BY t.component_sequence, t.component_contract_code, t.contract_version)) IS DISTINCT FROM r.contract_reproduction_set_hash)::integer AS set_hash_mismatch_count FROM msbf_m2.module2_contract_reproduction_snapshot t JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1 GROUP BY r.contract_reproduction_set_hash) UNION ALL (SELECT 'CAPABILITY_COVERAGE'::text AS family_code, md5(string_agg(concat_ws('|',t.capability_sequence::text,t.capability_code::text,t.row_hash::text),'|' ORDER BY t.capability_sequence, t.capability_code))::text AS reconstructed_set_hash, r.capability_coverage_set_hash::text AS stored_set_hash, (md5(string_agg(concat_ws('|',t.capability_sequence::text,t.capability_code::text,t.row_hash::text),'|' ORDER BY t.capability_sequence, t.capability_code)) IS DISTINCT FROM r.capability_coverage_set_hash)::integer AS set_hash_mismatch_count FROM msbf_m2.module2_capability_coverage_snapshot t JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1 GROUP BY r.capability_coverage_set_hash) UNION ALL (SELECT 'LATEST'::text AS family_code, md5(string_agg(concat_ws('|',t.bundle_code::text,t.contract_version::text,t.row_hash::text),'|' ORDER BY t.bundle_code, t.contract_version))::text AS reconstructed_set_hash, r.latest_set_hash::text AS stored_set_hash, (md5(string_agg(concat_ws('|',t.bundle_code::text,t.contract_version::text,t.row_hash::text),'|' ORDER BY t.bundle_code, t.contract_version)) IS DISTINCT FROM r.latest_set_hash)::integer AS set_hash_mismatch_count FROM msbf_ctl.m2_12_g3_bundle_latest t JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1 GROUP BY r.latest_set_hash) UNION ALL (SELECT 'ARCHIVE'::text AS family_code, md5(string_agg(concat_ws('|',t.bundle_code::text,t.contract_version::text,t.archive_row_hash::text),'|' ORDER BY t.bundle_code, t.contract_version))::text AS reconstructed_set_hash, r.archive_set_hash::text AS stored_set_hash, (md5(string_agg(concat_ws('|',t.bundle_code::text,t.contract_version::text,t.archive_row_hash::text),'|' ORDER BY t.bundle_code, t.contract_version)) IS DISTINCT FROM r.archive_set_hash)::integer AS set_hash_mismatch_count FROM msbf_ctl.m2_12_g3_bundle_archive t JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1 GROUP BY r.archive_set_hash) UNION ALL (SELECT 'REGISTRY'::text AS family_code, md5(string_agg(concat_ws('|',t.bundle_code::text,t.contract_version::text,t.row_hash::text),'|' ORDER BY t.bundle_code, t.contract_version))::text AS reconstructed_set_hash, r.registry_set_hash::text AS stored_set_hash, (md5(string_agg(concat_ws('|',t.bundle_code::text,t.contract_version::text,t.row_hash::text),'|' ORDER BY t.bundle_code, t.contract_version)) IS DISTINCT FROM r.registry_set_hash)::integer AS set_hash_mismatch_count FROM msbf_ctl.m2_12_g3_bundle_registry t JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1 GROUP BY r.registry_set_hash)),
setd AS (SELECT sum(set_hash_mismatch_count)::bigint set_hash_mismatch_count FROM set_detail),
ch AS (SELECT r.module1_run_id,
       md5(concat_ws('|',r.bundle_code::text,r.contract_version::text,r.schema_version::text,r.methodology_version::text,r.policy_configuration_hash::text,r.policy_set_hash::text,r.stage_certification_set_hash::text,r.contract_component_set_hash::text,r.evidence_certification_set_hash::text,r.contract_reproduction_set_hash::text,r.capability_coverage_set_hash::text,r.latest_set_hash::text,r.archive_set_hash::text,r.registry_set_hash::text,r.latest_contract_row_hash::text,r.archive_contract_row_hash::text,r.row_hash::text,r.accepted_m2_11_contract_set_hash::text,r.accepted_m2_11_combined_set_hash::text,r.accepted_m2_11_registry_row_hash::text))::text AS reconstructed_contract_set_hash,
       r.contract_set_hash::text AS stored_contract_set_hash,
       (md5(concat_ws('|',r.bundle_code::text,r.contract_version::text,r.schema_version::text,r.methodology_version::text,r.policy_configuration_hash::text,r.policy_set_hash::text,r.stage_certification_set_hash::text,r.contract_component_set_hash::text,r.evidence_certification_set_hash::text,r.contract_reproduction_set_hash::text,r.capability_coverage_set_hash::text,r.latest_set_hash::text,r.archive_set_hash::text,r.registry_set_hash::text,r.latest_contract_row_hash::text,r.archive_contract_row_hash::text,r.row_hash::text,r.accepted_m2_11_contract_set_hash::text,r.accepted_m2_11_combined_set_hash::text,r.accepted_m2_11_registry_row_hash::text)) IS DISTINCT FROM r.contract_set_hash)::integer AS contract_hash_mismatch_count
FROM msbf_ctl.m2_12_g3_bundle_registry r
JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=r.module1_run_id
WHERE r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1), cb AS (SELECT u.module1_run_id, count(*)::integer AS canonical_entities, count(DISTINCT u.entity_type)::integer AS canonical_families, md5(string_agg(u.entity_type||'|'||u.entity_key||'|'||u.row_hash,'|' ORDER BY u.entity_type,u.entity_key))::text AS reconstructed_combined_set_hash, r.combined_set_hash::text AS stored_combined_set_hash, (md5(string_agg(u.entity_type||'|'||u.entity_key||'|'||u.row_hash,'|' ORDER BY u.entity_type,u.entity_key)) IS DISTINCT FROM r.combined_set_hash)::integer AS combined_hash_mismatch_count FROM (SELECT t.module1_run_id, 'POLICY'::text AS entity_type, concat_ws('|',t.policy_code::text,t.policy_version::text)::text AS entity_key, t.row_hash::text AS row_hash FROM msbf_ctl.m2_12_policy_profile t JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT t.module1_run_id, 'STAGE_CERTIFICATION'::text AS entity_type, concat_ws('|',t.certification_node_sequence::text,t.stage_code::text)::text AS entity_key, t.row_hash::text AS row_hash FROM msbf_m2.module2_stage_certification_snapshot t JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT t.module1_run_id, 'CONTRACT_COMPONENT'::text AS entity_type, concat_ws('|',t.component_sequence::text,t.component_contract_code::text,t.contract_version::text)::text AS entity_key, t.row_hash::text AS row_hash FROM msbf_m2.module2_contract_component_snapshot t JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT t.module1_run_id, 'EVIDENCE_CERTIFICATION'::text AS entity_type, concat_ws('|',t.node_sequence::text,t.evidence_family_sequence::text)::text AS entity_key, t.row_hash::text AS row_hash FROM msbf_m2.module2_evidence_certification_snapshot t JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT t.module1_run_id, 'CONTRACT_REPRODUCTION'::text AS entity_type, concat_ws('|',t.component_sequence::text,t.component_contract_code::text,t.contract_version::text)::text AS entity_key, t.row_hash::text AS row_hash FROM msbf_m2.module2_contract_reproduction_snapshot t JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT t.module1_run_id, 'CAPABILITY_COVERAGE'::text AS entity_type, concat_ws('|',t.capability_sequence::text,t.capability_code::text)::text AS entity_key, t.row_hash::text AS row_hash FROM msbf_m2.module2_capability_coverage_snapshot t JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT t.module1_run_id, 'LATEST'::text AS entity_type, concat_ws('|',t.bundle_code::text,t.contract_version::text)::text AS entity_key, t.row_hash::text AS row_hash FROM msbf_ctl.m2_12_g3_bundle_latest t JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT t.module1_run_id, 'ARCHIVE'::text AS entity_type, concat_ws('|',t.bundle_code::text,t.contract_version::text)::text AS entity_key, t.archive_row_hash::text AS row_hash FROM msbf_ctl.m2_12_g3_bundle_archive t JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT t.module1_run_id, 'REGISTRY'::text AS entity_type, concat_ws('|',t.bundle_code::text,t.contract_version::text)::text AS entity_key, t.row_hash::text AS row_hash FROM msbf_ctl.m2_12_g3_bundle_registry t JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=t.module1_run_id) u JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=u.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1 GROUP BY u.module1_run_id,r.combined_set_hash), seq AS (SELECT ctx.module1_run_id,
       p.last_value::bigint AS policy_last_value,p.is_called AS policy_is_called,
       a.last_value::bigint AS archive_last_value,a.is_called AS archive_is_called,
       r.last_value::bigint AS registry_last_value,r.is_called AS registry_is_called,
       ((p.last_value<>1 OR NOT p.is_called)::integer
        +(a.last_value<>1 OR NOT a.is_called)::integer
        +(r.last_value<>1 OR NOT r.is_called)::integer)::integer AS sequence_state_mismatch_count
FROM tmp_src_m2_12_validation_run_context ctx
CROSS JOIN msbf_ctl.m2_12_policy_profile_policy_profile_id_seq p
CROSS JOIN msbf_ctl.m2_12_g3_bundle_archive_archive_id_seq a
CROSS JOIN msbf_ctl.m2_12_g3_bundle_registry_registry_id_seq r)
SELECT ctx.module1_run_id,
       rowd.family_count_mismatch_count,rowd.row_hash_mismatch_count,setd.set_hash_mismatch_count,
       ch.contract_hash_mismatch_count::integer,cb.combined_hash_mismatch_count::integer,
       seq.sequence_state_mismatch_count::integer,cb.canonical_families::integer,cb.canonical_entities::integer,
       (rowd.family_count_mismatch_count+rowd.row_hash_mismatch_count+setd.set_hash_mismatch_count+ch.contract_hash_mismatch_count+cb.combined_hash_mismatch_count+seq.sequence_state_mismatch_count)::bigint AS total_mismatch_count
FROM tmp_src_m2_12_validation_run_context ctx CROSS JOIN rowd CROSS JOIN setd CROSS JOIN ch CROSS JOIN cb CROSS JOIN seq
) p;

CREATE UNIQUE INDEX ux_tmp_hash_m2_12_validation_postflight ON tmp_hash_m2_12_validation_postflight(module1_run_id);

ANALYZE tmp_hash_m2_12_validation_postflight;


CREATE TEMP TABLE tmp_eval_m2_12_validation_persistence_result ON COMMIT PRESERVE ROWS AS
WITH state AS (
 SELECT rr.run_id,rr.run_status,r.contract_status,r.generated_at,r.validated_at,r.accepted_at
 FROM msbf_ctl.run_registry rr
 JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=rr.run_id
 JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=rr.run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1
), evidence AS (
 SELECT count(*) FILTER (WHERE e.evidence_code LIKE 'M2_12_POS_%' AND e.status='PASS')::integer AS positive_pass,
        count(DISTINCT e.evidence_code) FILTER (WHERE e.evidence_code LIKE 'M2_12_POS_%' AND e.status='PASS')::integer AS positive_codes,
        count(*) FILTER (WHERE e.evidence_code LIKE 'M2_12_NEG_%')::integer AS negative_rows,
        count(*) FILTER (WHERE e.evidence_code='M2_12_ACCEPTANCE_SUMMARY')::integer AS acceptance_rows
 FROM msbf_ctl.run_evidence e JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=e.run_id
), gate AS (
 SELECT count(*)::integer AS gate_rows FROM msbf_ctl.acceptance_gate_result g
 JOIN tmp_src_m2_12_validation_run_context ctx ON ctx.module1_run_id=g.run_id
 WHERE g.gate_id='G3_M2_CONTRACT'
), hash_parity AS (
 SELECT count(*)::integer AS rows,
        count(*) FILTER (WHERE b.total_mismatch_count=0 AND a.total_mismatch_count=0
          AND ROW(b.family_count_mismatch_count,b.row_hash_mismatch_count,b.set_hash_mismatch_count,
                  b.contract_hash_mismatch_count,b.combined_hash_mismatch_count,b.sequence_state_mismatch_count,
                  b.canonical_families,b.canonical_entities,b.total_mismatch_count,b.reconciliation_status)
              IS NOT DISTINCT FROM
              ROW(a.family_count_mismatch_count,a.row_hash_mismatch_count,a.set_hash_mismatch_count,
                  a.contract_hash_mismatch_count,a.combined_hash_mismatch_count,a.sequence_state_mismatch_count,
                  a.canonical_families,a.canonical_entities,a.total_mismatch_count,a.reconciliation_status))::integer AS exact_rows
 FROM tmp_hash_m2_12_validation_reconciliation b
 JOIN tmp_hash_m2_12_validation_postflight a USING(module1_run_id)
)
SELECT s.run_id,s.run_status,s.contract_status,
       e.positive_pass,e.positive_codes,e.negative_rows,e.acceptance_rows,g.gate_rows,
       h.rows AS hash_compare_rows,h.exact_rows AS hash_exact_rows,
       CASE WHEN s.run_status='M2_12_VALIDATED' AND s.contract_status='VALIDATED'
                  AND s.generated_at IS NOT NULL AND s.validated_at IS NOT NULL AND s.accepted_at IS NULL
                  AND e.positive_pass=128 AND e.positive_codes=128 AND e.negative_rows=0 AND e.acceptance_rows=0
                  AND g.gate_rows=0 AND h.rows=1 AND h.exact_rows=1
             THEN 'PASS'::text ELSE 'FAIL'::text END AS persistence_status
FROM state s CROSS JOIN evidence e CROSS JOIN gate g CROSS JOIN hash_parity h;


DO $m212_p223_final_gate$
BEGIN
    IF (SELECT count(*) FROM tmp_eval_m2_12_validation_persistence_result)<>1
       OR (SELECT persistence_status FROM tmp_eval_m2_12_validation_persistence_result)<>'PASS' THEN
        RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 Program 223 HF12 final persistence/hash postflight failed';
    END IF;
    IF NOT ((SELECT last_value=1 AND is_called FROM msbf_ctl.m2_12_policy_profile_policy_profile_id_seq)
        AND (SELECT last_value=1 AND is_called FROM msbf_ctl.m2_12_g3_bundle_archive_archive_id_seq)
        AND (SELECT last_value=1 AND is_called FROM msbf_ctl.m2_12_g3_bundle_registry_registry_id_seq)) THEN
        RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 Program 223 HF12 advanced an owned sequence';
    END IF;
END;
$m212_p223_final_gate$;


COMMIT;


SELECT * FROM tmp_eval_m2_12_validation_persistence_result;

SELECT control_sequence,evidence_code,control_family_code,observed_value,expected_value,mismatch_count,status,interpretation
FROM tmp_eval_m2_12_positive_results ORDER BY control_sequence;
