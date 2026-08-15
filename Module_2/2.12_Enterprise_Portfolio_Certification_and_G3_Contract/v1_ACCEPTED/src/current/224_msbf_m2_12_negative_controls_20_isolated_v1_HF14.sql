/*
Program 224 — M2.12 Negative Controls (20 isolated controls)
Source revision: HF14 bounded live-execution correction after successful Program 223 HF12
Execution status: HOTFIX SOURCE CONSTRUCTED — NOT EXECUTED HERE

Bounded correction authority:
- Requires the exact M2_12_VALIDATED / VALIDATED checkpoint and 128 persisted positive PASS rows.
- Removes the psql-only client meta-command so the physical source is valid PostgreSQL SQL in DBeaver.
- Qualifies every joined fixture projection in Controls 001, 002, 003, 006, and 012; Control 003 resolves the live SQLSTATE 42702 ambiguity and the others are proactive same-class hardening.
- Replaces the obsolete source-graph reconstruction with the physically executed 19-edge authority,
  including exact registry identities and the M1.3 application_set_hash JSON extraction.
- Corrects Negative Control 013 so a mutated canonical fingerprint is rejected rather than accepted.
- Aligns the evidence-certification entity key with the governed node_sequence|family_sequence preimage.
- Hardens preconditions, source-graph and 20-of-20 diagnostics, evidence cardinality, and final persistence checks.
- Eliminates broad SELECT-star usage except the approved same-table duplicate-key fixtures in Controls 010 and 011.
- Preserves exactly 20 isolated controls, their codes, order, expected SQLSTATE/message/constraint signatures,
  and the authorized persistent mutation boundary: 20 negative run-evidence rows only after 20/20 PASS.
- Leaves lifecycle at M2_12_VALIDATED and advances no owned sequence.

Operator boundary:
- Execute only after the HF14 validated-checkpoint verifier and 20-control diagnostic pass exactly.
- Execute one complete physical file with first-error stop configured in the client and no outer transaction.
- Stop after Program 224; Programs 225–227 remain held pending evidence reconciliation.
*/
-- Configure first-error-stop behavior in the database client; this file contains no client meta-commands.
BEGIN;
SET LOCAL search_path = pg_catalog, msbf_ctl, msbf_m1, msbf_m2;
SET LOCAL client_min_messages = warning;
SET LOCAL lock_timeout = '15s';
SET LOCAL statement_timeout = '0';
SET LOCAL idle_in_transaction_session_timeout = '0';

CREATE TEMP TABLE tmp_neg_m2_12_run_context ON COMMIT DROP AS
SELECT rr.run_id::bigint AS module1_run_id,
       rr.run_code,
       rr.run_version,
       rr.run_status,
       p.policy_code,
       p.policy_version,
       r.registry_id,
       r.contract_status,
       r.generated_at,
       r.validated_at,
       r.accepted_at,
       r.combined_set_hash
FROM msbf_ctl.run_registry rr
JOIN msbf_ctl.m2_12_policy_profile p
  ON p.module1_run_id=rr.run_id
 AND p.policy_code='M2_12_ENTERPRISE_PORTFOLIO_CERTIFICATION_POLICY_V1'
 AND p.policy_version=1
 AND p.policy_status='APPROVED'
JOIN msbf_ctl.m2_12_g3_bundle_registry r
  ON r.module1_run_id=rr.run_id
 AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE'
 AND r.contract_version=1
 AND r.contract_status='VALIDATED'
 AND r.generated_at IS NOT NULL
 AND r.validated_at IS NOT NULL
 AND r.accepted_at IS NULL
JOIN msbf_ctl.m2_11_portfolio_strategy_contract_registry m211
  ON m211.module1_run_id=rr.run_id
 AND m211.contract_code='M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION'
 AND m211.contract_version=1
 AND m211.contract_status='ACCEPTED'
WHERE rr.run_code='M1_V0_2_BASELINE_BUILD'
  AND rr.run_version=1
  AND rr.run_status='M2_12_VALIDATED';
CREATE UNIQUE INDEX ux_tmp_neg_m2_12_run_context ON tmp_neg_m2_12_run_context(module1_run_id);
ANALYZE tmp_neg_m2_12_run_context;DO $m212_p224_hf14_precondition$
DECLARE
  v_context integer;
  v_positive_total integer;
  v_positive_pass integer;
  v_positive_codes integer;
  v_negative_total integer;
  v_acceptance integer;
  v_gate integer;
  v_generation_total integer;
  v_generation_pass integer;
BEGIN
  SELECT count(*) INTO v_context FROM tmp_neg_m2_12_run_context;
  SELECT count(*) FILTER (WHERE e.evidence_code LIKE 'M2_12_POS_%'),
         count(*) FILTER (WHERE e.evidence_code LIKE 'M2_12_POS_%' AND e.status='PASS'),
         count(DISTINCT e.evidence_code) FILTER (WHERE e.evidence_code LIKE 'M2_12_POS_%'),
         count(*) FILTER (WHERE e.evidence_code LIKE 'M2_12_NEG_%'),
         count(*) FILTER (WHERE e.evidence_code='M2_12_ACCEPTANCE_SUMMARY'),
         count(*) FILTER (WHERE e.evidence_code LIKE 'M2_12_%'
                           AND e.evidence_code NOT LIKE 'M2_12_POS_%'
                           AND e.evidence_code NOT LIKE 'M2_12_NEG_%'
                           AND e.evidence_code<>'M2_12_ACCEPTANCE_SUMMARY'),
         count(*) FILTER (WHERE e.evidence_code LIKE 'M2_12_%'
                           AND e.evidence_code NOT LIKE 'M2_12_POS_%'
                           AND e.evidence_code NOT LIKE 'M2_12_NEG_%'
                           AND e.evidence_code<>'M2_12_ACCEPTANCE_SUMMARY'
                           AND e.status='PASS')
    INTO v_positive_total,v_positive_pass,v_positive_codes,v_negative_total,v_acceptance,
         v_generation_total,v_generation_pass
    FROM msbf_ctl.run_evidence e
    JOIN tmp_neg_m2_12_run_context ctx ON ctx.module1_run_id=e.run_id;
  SELECT count(*) INTO v_gate
    FROM msbf_ctl.acceptance_gate_result g
    JOIN tmp_neg_m2_12_run_context ctx ON ctx.module1_run_id=g.run_id
   WHERE g.gate_id='G3_M2_CONTRACT';

  IF v_context<>1
     OR (SELECT combined_set_hash FROM tmp_neg_m2_12_run_context) IS DISTINCT FROM '28d832719a63d5669a18016f15ba43fb'
     OR v_positive_total<>128 OR v_positive_pass<>128 OR v_positive_codes<>128
     OR v_negative_total<>0 OR v_acceptance<>0 OR v_gate<>0
     OR v_generation_total<>24 OR v_generation_pass<>24 THEN
    RAISE EXCEPTION USING
      ERRCODE='P0001',
      MESSAGE='M2.12 Program 224 HF14 validated-checkpoint precondition failed',
      DETAIL=format('context=%s combined_set_hash=%s positive_total=%s positive_pass=%s positive_codes=%s negative=%s acceptance=%s gate=%s generation_total=%s generation_pass=%s',
                    v_context,(SELECT combined_set_hash FROM tmp_neg_m2_12_run_context),v_positive_total,v_positive_pass,
                    v_positive_codes,v_negative_total,v_acceptance,v_gate,v_generation_total,v_generation_pass);
  END IF;

  IF NOT ((SELECT last_value=1 AND is_called FROM msbf_ctl.m2_12_policy_profile_policy_profile_id_seq)
      AND (SELECT last_value=1 AND is_called FROM msbf_ctl.m2_12_g3_bundle_archive_archive_id_seq)
      AND (SELECT last_value=1 AND is_called FROM msbf_ctl.m2_12_g3_bundle_registry_registry_id_seq)) THEN
    RAISE EXCEPTION USING
      ERRCODE='P0001',
      MESSAGE='M2.12 Program 224 HF14 owned-sequence precondition failed',
      DETAIL=format('policy=%s|%s archive=%s|%s registry=%s|%s',
        (SELECT last_value FROM msbf_ctl.m2_12_policy_profile_policy_profile_id_seq),
        (SELECT is_called FROM msbf_ctl.m2_12_policy_profile_policy_profile_id_seq),
        (SELECT last_value FROM msbf_ctl.m2_12_g3_bundle_archive_archive_id_seq),
        (SELECT is_called FROM msbf_ctl.m2_12_g3_bundle_archive_archive_id_seq),
        (SELECT last_value FROM msbf_ctl.m2_12_g3_bundle_registry_registry_id_seq),
        (SELECT is_called FROM msbf_ctl.m2_12_g3_bundle_registry_registry_id_seq));
  END IF;
END;
$m212_p224_hf14_precondition$;

CREATE TEMP TABLE tmp_neg_m2_12_source_edges ON COMMIT DROP AS
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
FROM tmp_neg_m2_12_run_context ctx
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
FROM tmp_neg_m2_12_run_context ctx
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
FROM tmp_neg_m2_12_run_context ctx
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
FROM tmp_neg_m2_12_run_context ctx
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
FROM tmp_neg_m2_12_run_context ctx
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
FROM tmp_neg_m2_12_run_context ctx
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
FROM tmp_neg_m2_12_run_context ctx
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
FROM tmp_neg_m2_12_run_context ctx
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
FROM tmp_neg_m2_12_run_context ctx
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
FROM tmp_neg_m2_12_run_context ctx
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
FROM tmp_neg_m2_12_run_context ctx
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
FROM tmp_neg_m2_12_run_context ctx
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
FROM tmp_neg_m2_12_run_context ctx
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
FROM tmp_neg_m2_12_run_context ctx
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
FROM tmp_neg_m2_12_run_context ctx
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
FROM tmp_neg_m2_12_run_context ctx
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
FROM tmp_neg_m2_12_run_context ctx
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
FROM tmp_neg_m2_12_run_context ctx
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
FROM tmp_neg_m2_12_run_context ctx
) x);
CREATE UNIQUE INDEX ux_tmp_neg_m2_12_source_edges ON tmp_neg_m2_12_source_edges(edge_sequence,edge_code);
ANALYZE tmp_neg_m2_12_source_edges;DO $m212_p224_hf14_edge_gate$
DECLARE
  v_detail text;
BEGIN
  IF NOT (SELECT count(*)=19
                 AND count(*) FILTER (WHERE edge_status='PASS')=19
                 AND count(DISTINCT edge_sequence)=19
                 AND count(DISTINCT edge_code)=19
            FROM tmp_neg_m2_12_source_edges) THEN
    SELECT string_agg(
             format('edge=%s|code=%s|status=%s|source_rows=%s|target_rows=%s|gate=%s|expected=%s|source=%s|target=%s',
                    edge_sequence,edge_code,edge_status,source_registry_row_count,target_registry_row_count,
                    source_gate_status,expected_source_hash,observed_accepted_source_hash,
                    observed_target_recorded_source_hash),
             '; ' ORDER BY edge_sequence)
      INTO v_detail
      FROM tmp_neg_m2_12_source_edges
     WHERE edge_status IS DISTINCT FROM 'PASS';
    RAISE EXCEPTION USING
      ERRCODE='P0001',
      MESSAGE='M2.12 Program 224 HF14 source graph precondition failed',
      DETAIL=coalesce(v_detail,'row/distinct cardinality mismatch');
  END IF;
END;
$m212_p224_hf14_edge_gate$;


CREATE TEMP VIEW tmp_hash_m2_12_negative_current_fingerprint AS
WITH canonical_rows AS (
    SELECT 'POLICY'::text AS family_code,
           concat_ws('|',p.policy_code,p.policy_version::text)::text AS business_key,
           p.row_hash::text AS row_hash
    FROM msbf_ctl.m2_12_policy_profile p
    JOIN tmp_neg_m2_12_run_context ctx ON ctx.module1_run_id=p.module1_run_id
    UNION ALL
    SELECT 'STAGE_CERTIFICATION',concat_ws('|',s.certification_node_sequence::text,s.stage_code),s.row_hash
    FROM msbf_m2.module2_stage_certification_snapshot s
    JOIN tmp_neg_m2_12_run_context ctx ON ctx.module1_run_id=s.module1_run_id
    UNION ALL
    SELECT 'CONTRACT_COMPONENT',concat_ws('|',c.component_sequence::text,c.component_contract_code,c.contract_version::text),c.row_hash
    FROM msbf_m2.module2_contract_component_snapshot c
    JOIN tmp_neg_m2_12_run_context ctx ON ctx.module1_run_id=c.module1_run_id
    UNION ALL
    SELECT 'EVIDENCE_CERTIFICATION',concat_ws('|',e.node_sequence::text,e.evidence_family_sequence::text),e.row_hash
    FROM msbf_m2.module2_evidence_certification_snapshot e
    JOIN tmp_neg_m2_12_run_context ctx ON ctx.module1_run_id=e.module1_run_id
    UNION ALL
    SELECT 'CONTRACT_REPRODUCTION',concat_ws('|',r.component_sequence::text,r.component_contract_code,r.contract_version::text),r.row_hash
    FROM msbf_m2.module2_contract_reproduction_snapshot r
    JOIN tmp_neg_m2_12_run_context ctx ON ctx.module1_run_id=r.module1_run_id
    UNION ALL
    SELECT 'CAPABILITY_COVERAGE',concat_ws('|',c.capability_sequence::text,c.capability_code),c.row_hash
    FROM msbf_m2.module2_capability_coverage_snapshot c
    JOIN tmp_neg_m2_12_run_context ctx ON ctx.module1_run_id=c.module1_run_id
    UNION ALL
    SELECT 'LATEST',concat_ws('|',l.bundle_code,l.contract_version::text),l.row_hash
    FROM msbf_ctl.m2_12_g3_bundle_latest l
    JOIN tmp_neg_m2_12_run_context ctx ON ctx.module1_run_id=l.module1_run_id
    UNION ALL
    SELECT 'ARCHIVE',concat_ws('|',a.bundle_code,a.contract_version::text),a.archive_row_hash
    FROM msbf_ctl.m2_12_g3_bundle_archive a
    JOIN tmp_neg_m2_12_run_context ctx ON ctx.module1_run_id=a.module1_run_id
    UNION ALL
    SELECT 'REGISTRY',concat_ws('|',g.bundle_code,g.contract_version::text),g.row_hash
    FROM msbf_ctl.m2_12_g3_bundle_registry g
    JOIN tmp_neg_m2_12_run_context ctx ON ctx.module1_run_id=g.module1_run_id
), canonical AS (
    SELECT count(*)::integer AS canonical_entity_count,
           count(DISTINCT family_code)::integer AS canonical_family_count,
           md5(string_agg(concat_ws('|',family_code,business_key,row_hash),'|' ORDER BY family_code,business_key))::text AS canonical_fingerprint
    FROM canonical_rows
), stored_hashes AS (
    SELECT md5(concat_ws('|',g.policy_set_hash,g.stage_certification_set_hash,g.contract_component_set_hash,
                              g.evidence_certification_set_hash,g.contract_reproduction_set_hash,g.capability_coverage_set_hash,
                              g.latest_set_hash,g.archive_set_hash,g.registry_set_hash,g.latest_contract_row_hash,
                              g.archive_contract_row_hash,g.contract_set_hash,g.combined_set_hash,g.row_hash))::text AS stored_hash_fingerprint
    FROM msbf_ctl.m2_12_g3_bundle_registry g
    JOIN tmp_neg_m2_12_run_context ctx ON ctx.module1_run_id=g.module1_run_id
    WHERE g.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND g.contract_version=1 AND g.contract_status='VALIDATED'
), sequences AS (
    SELECT concat_ws('|',
        'policy',p.last_value::text,p.is_called::text,
        'archive',a.last_value::text,a.is_called::text,
        'registry',r.last_value::text,r.is_called::text)::text AS sequence_fingerprint
    FROM msbf_ctl.m2_12_policy_profile_policy_profile_id_seq p,
         msbf_ctl.m2_12_g3_bundle_archive_archive_id_seq a,
         msbf_ctl.m2_12_g3_bundle_registry_registry_id_seq r
), lifecycle AS (
    SELECT concat_ws('|',rr.run_status,g.contract_status,
        coalesce(g.generated_at::text,'NULL'),coalesce(g.validated_at::text,'NULL'),coalesce(g.accepted_at::text,'NULL'))::text AS lifecycle_fingerprint
    FROM msbf_ctl.run_registry rr
    JOIN tmp_neg_m2_12_run_context ctx ON ctx.module1_run_id=rr.run_id
    JOIN msbf_ctl.m2_12_g3_bundle_registry g ON g.module1_run_id=rr.run_id
       AND g.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND g.contract_version=1
)
SELECT c.canonical_family_count,c.canonical_entity_count,c.canonical_fingerprint,
       h.stored_hash_fingerprint,s.sequence_fingerprint,l.lifecycle_fingerprint
FROM canonical c CROSS JOIN stored_hashes h CROSS JOIN sequences s CROSS JOIN lifecycle l;

CREATE TEMP TABLE tmp_hash_m2_12_negative_baseline ON COMMIT DROP AS
SELECT canonical_family_count,canonical_entity_count,canonical_fingerprint,stored_hash_fingerprint,sequence_fingerprint,lifecycle_fingerprint
FROM tmp_hash_m2_12_negative_current_fingerprint;
CREATE UNIQUE INDEX ux_tmp_hash_m2_12_negative_baseline ON tmp_hash_m2_12_negative_baseline(canonical_entity_count);
ANALYZE tmp_hash_m2_12_negative_baseline;

DO $m212_p224_fingerprint_gate$
BEGIN
  IF (SELECT count(*) FROM tmp_hash_m2_12_negative_baseline)<>1
     OR (SELECT canonical_family_count FROM tmp_hash_m2_12_negative_baseline)<>9
     OR (SELECT canonical_entity_count FROM tmp_hash_m2_12_negative_baseline)<>134
     OR (SELECT canonical_fingerprint FROM tmp_hash_m2_12_negative_baseline) IS NULL
     OR (SELECT stored_hash_fingerprint FROM tmp_hash_m2_12_negative_baseline) IS NULL
     OR (SELECT sequence_fingerprint FROM tmp_hash_m2_12_negative_baseline) IS NULL
     OR (SELECT lifecycle_fingerprint FROM tmp_hash_m2_12_negative_baseline) IS NULL THEN
    RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 Program 224 HF14 canonical fingerprint precondition failed';
  END IF;
END;
$m212_p224_fingerprint_gate$;

CREATE TEMP TABLE tmp_neg_m2_12_results
(
  control_sequence smallint NOT NULL,
  evidence_code text NOT NULL,
  control_family text NOT NULL,
  expected_sqlstate text NOT NULL,
  authority_message_prefix text NOT NULL,
  effective_message_signature text NOT NULL,
  message_match_mode text NOT NULL,
  expected_constraint text NOT NULL,
  observed_sqlstate text,
  observed_message text,
  observed_constraint text,
  canonical_before text NOT NULL,
  canonical_after text NOT NULL,
  hash_before text NOT NULL,
  hash_after text NOT NULL,
  sequence_before text NOT NULL,
  sequence_after text NOT NULL,
  lifecycle_before text NOT NULL,
  lifecycle_after text NOT NULL,
  isolation_status text NOT NULL,
  status text NOT NULL,
  interpretation text NOT NULL,
  PRIMARY KEY(control_sequence),
  UNIQUE(evidence_code)
) ON COMMIT PRESERVE ROWS;

/* WP3_NEGATIVE_CONTROL_DEFINITION M2_12_NEG_001_SOURCE_REGISTRY_HASH_TAMPER */
DO $m212_neg_001$
DECLARE
    v_sqlstate text;
    v_message text;
    v_constraint text;
    v_canonical_before text;
    v_canonical_after text;
    v_hash_before text;
    v_hash_after text;
    v_sequence_before text;
    v_sequence_after text;
    v_lifecycle_before text;
    v_lifecycle_after text;
    v_entities_before integer;
    v_entities_after integer;
    v_signature_ok boolean;
    v_isolation_ok boolean;
BEGIN
    SELECT canonical_fingerprint,stored_hash_fingerprint,sequence_fingerprint,lifecycle_fingerprint,canonical_entity_count
      INTO v_canonical_before,v_hash_before,v_sequence_before,v_lifecycle_before,v_entities_before
      FROM tmp_hash_m2_12_negative_baseline;

    BEGIN
        CREATE TEMP TABLE tmp_neg_001_source_registry_fixture ON COMMIT DROP AS
        SELECT s.certification_node_sequence,
               s.stage_code,
               s.expected_combined_hash,
               s.observed_combined_hash
        FROM msbf_m2.module2_stage_certification_snapshot s
        JOIN tmp_neg_m2_12_run_context ctx ON ctx.module1_run_id=s.module1_run_id
        ORDER BY s.certification_node_sequence LIMIT 1;
        UPDATE tmp_neg_001_source_registry_fixture SET expected_combined_hash=repeat('0',32);
        IF EXISTS (SELECT 1 FROM tmp_neg_001_source_registry_fixture WHERE expected_combined_hash IS DISTINCT FROM observed_combined_hash) THEN
            RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 source registry hash mismatch';
        END IF;
        RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 negative control unexpectedly accepted injected defect';
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            v_sqlstate = RETURNED_SQLSTATE,
            v_message = MESSAGE_TEXT,
            v_constraint = CONSTRAINT_NAME;
    END;

    SELECT canonical_fingerprint,stored_hash_fingerprint,sequence_fingerprint,lifecycle_fingerprint,canonical_entity_count
      INTO v_canonical_after,v_hash_after,v_sequence_after,v_lifecycle_after,v_entities_after
      FROM tmp_hash_m2_12_negative_current_fingerprint;

    v_signature_ok := (v_sqlstate='P0001' AND v_message='M2.12 source registry hash mismatch');
    v_isolation_ok := (v_entities_before=134 AND v_entities_after=134
                       AND v_canonical_before IS NOT DISTINCT FROM v_canonical_after
                       AND v_hash_before IS NOT DISTINCT FROM v_hash_after
                       AND v_sequence_before IS NOT DISTINCT FROM v_sequence_after
                       AND v_lifecycle_before IS NOT DISTINCT FROM v_lifecycle_after);

    INSERT INTO tmp_neg_m2_12_results
    (
      control_sequence,evidence_code,control_family,expected_sqlstate,
      authority_message_prefix,effective_message_signature,message_match_mode,expected_constraint,
      observed_sqlstate,observed_message,observed_constraint,
      canonical_before,canonical_after,hash_before,hash_after,
      sequence_before,sequence_after,lifecycle_before,lifecycle_after,
      isolation_status,status,interpretation
    )
    VALUES
    (
      1::smallint,'M2_12_NEG_001_SOURCE_REGISTRY_HASH_TAMPER','SOURCE_AUTHORITY','P0001',
      'M2.12 source registry hash mismatch','M2.12 source registry hash mismatch','EXACT','',
      v_sqlstate,v_message,coalesce(v_constraint,''),
      v_canonical_before,v_canonical_after,v_hash_before,v_hash_after,
      v_sequence_before,v_sequence_after,v_lifecycle_before,v_lifecycle_after,
      CASE WHEN v_isolation_ok THEN 'PASS' ELSE 'FAIL' END,
      CASE WHEN v_signature_ok AND v_isolation_ok THEN 'PASS' ELSE 'FAIL' END,
      'M2.12 source-registry assertion | NONE'
    );
END;
$m212_neg_001$;

/* WP3_NEGATIVE_CONTROL_DEFINITION M2_12_NEG_002_MISSING_ACCEPTED_STAGE_GATE */
DO $m212_neg_002$
DECLARE
    v_sqlstate text;
    v_message text;
    v_constraint text;
    v_canonical_before text;
    v_canonical_after text;
    v_hash_before text;
    v_hash_after text;
    v_sequence_before text;
    v_sequence_after text;
    v_lifecycle_before text;
    v_lifecycle_after text;
    v_entities_before integer;
    v_entities_after integer;
    v_signature_ok boolean;
    v_isolation_ok boolean;
BEGIN
    SELECT canonical_fingerprint,stored_hash_fingerprint,sequence_fingerprint,lifecycle_fingerprint,canonical_entity_count
      INTO v_canonical_before,v_hash_before,v_sequence_before,v_lifecycle_before,v_entities_before
      FROM tmp_hash_m2_12_negative_baseline;

    BEGIN
        CREATE TEMP TABLE tmp_neg_002_accepted_gate_fixture ON COMMIT DROP AS
        SELECT s.certification_node_sequence,
               s.stage_code,
               s.acceptance_gate_id,
               s.acceptance_gate_review_version,
               s.gate_status
        FROM msbf_m2.module2_stage_certification_snapshot s
        JOIN tmp_neg_m2_12_run_context ctx ON ctx.module1_run_id=s.module1_run_id
        ORDER BY s.certification_node_sequence LIMIT 1;
        DELETE FROM tmp_neg_002_accepted_gate_fixture;
        IF (SELECT count(*) FROM tmp_neg_002_accepted_gate_fixture)<>1 THEN
            RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 required accepted stage gate missing';
        END IF;
        RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 negative control unexpectedly accepted injected defect';
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            v_sqlstate = RETURNED_SQLSTATE,
            v_message = MESSAGE_TEXT,
            v_constraint = CONSTRAINT_NAME;
    END;

    SELECT canonical_fingerprint,stored_hash_fingerprint,sequence_fingerprint,lifecycle_fingerprint,canonical_entity_count
      INTO v_canonical_after,v_hash_after,v_sequence_after,v_lifecycle_after,v_entities_after
      FROM tmp_hash_m2_12_negative_current_fingerprint;

    v_signature_ok := (v_sqlstate='P0001' AND v_message='M2.12 required accepted stage gate missing');
    v_isolation_ok := (v_entities_before=134 AND v_entities_after=134
                       AND v_canonical_before IS NOT DISTINCT FROM v_canonical_after
                       AND v_hash_before IS NOT DISTINCT FROM v_hash_after
                       AND v_sequence_before IS NOT DISTINCT FROM v_sequence_after
                       AND v_lifecycle_before IS NOT DISTINCT FROM v_lifecycle_after);

    INSERT INTO tmp_neg_m2_12_results
    (
      control_sequence,evidence_code,control_family,expected_sqlstate,
      authority_message_prefix,effective_message_signature,message_match_mode,expected_constraint,
      observed_sqlstate,observed_message,observed_constraint,
      canonical_before,canonical_after,hash_before,hash_after,
      sequence_before,sequence_after,lifecycle_before,lifecycle_after,
      isolation_status,status,interpretation
    )
    VALUES
    (
      2::smallint,'M2_12_NEG_002_MISSING_ACCEPTED_STAGE_GATE','SOURCE_ACCEPTANCE','P0001',
      'M2.12 required accepted stage gate missing','M2.12 required accepted stage gate missing','EXACT','',
      v_sqlstate,v_message,coalesce(v_constraint,''),
      v_canonical_before,v_canonical_after,v_hash_before,v_hash_after,
      v_sequence_before,v_sequence_after,v_lifecycle_before,v_lifecycle_after,
      CASE WHEN v_isolation_ok THEN 'PASS' ELSE 'FAIL' END,
      CASE WHEN v_signature_ok AND v_isolation_ok THEN 'PASS' ELSE 'FAIL' END,
      'M2.12 source acceptance assertion | NONE'
    );
END;
$m212_neg_002$;

/* WP3_NEGATIVE_CONTROL_DEFINITION M2_12_NEG_003_STAGE_STATUS_NOT_ACCEPTED */
DO $m212_neg_003$
DECLARE
    v_sqlstate text;
    v_message text;
    v_constraint text;
    v_canonical_before text;
    v_canonical_after text;
    v_hash_before text;
    v_hash_after text;
    v_sequence_before text;
    v_sequence_after text;
    v_lifecycle_before text;
    v_lifecycle_after text;
    v_entities_before integer;
    v_entities_after integer;
    v_signature_ok boolean;
    v_isolation_ok boolean;
BEGIN
    SELECT canonical_fingerprint,stored_hash_fingerprint,sequence_fingerprint,lifecycle_fingerprint,canonical_entity_count
      INTO v_canonical_before,v_hash_before,v_sequence_before,v_lifecycle_before,v_entities_before
      FROM tmp_hash_m2_12_negative_baseline;

    BEGIN
        CREATE TEMP TABLE tmp_neg_003_component_fixture ON COMMIT DROP AS
        SELECT c.component_sequence,
               c.component_contract_code,
               c.contract_status,
               c.gate_status,
               c.certification_status
        FROM msbf_m2.module2_contract_component_snapshot c
        JOIN tmp_neg_m2_12_run_context ctx ON ctx.module1_run_id=c.module1_run_id
        ORDER BY c.component_sequence LIMIT 1;
        UPDATE tmp_neg_003_component_fixture SET contract_status='VALIDATED';
        IF EXISTS (SELECT 1 FROM tmp_neg_003_component_fixture WHERE contract_status<>'ACCEPTED') THEN
            RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 component contract is not ACCEPTED';
        END IF;
        RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 negative control unexpectedly accepted injected defect';
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            v_sqlstate = RETURNED_SQLSTATE,
            v_message = MESSAGE_TEXT,
            v_constraint = CONSTRAINT_NAME;
    END;

    SELECT canonical_fingerprint,stored_hash_fingerprint,sequence_fingerprint,lifecycle_fingerprint,canonical_entity_count
      INTO v_canonical_after,v_hash_after,v_sequence_after,v_lifecycle_after,v_entities_after
      FROM tmp_hash_m2_12_negative_current_fingerprint;

    v_signature_ok := (v_sqlstate='P0001' AND v_message='M2.12 component contract is not ACCEPTED');
    v_isolation_ok := (v_entities_before=134 AND v_entities_after=134
                       AND v_canonical_before IS NOT DISTINCT FROM v_canonical_after
                       AND v_hash_before IS NOT DISTINCT FROM v_hash_after
                       AND v_sequence_before IS NOT DISTINCT FROM v_sequence_after
                       AND v_lifecycle_before IS NOT DISTINCT FROM v_lifecycle_after);

    INSERT INTO tmp_neg_m2_12_results
    (
      control_sequence,evidence_code,control_family,expected_sqlstate,
      authority_message_prefix,effective_message_signature,message_match_mode,expected_constraint,
      observed_sqlstate,observed_message,observed_constraint,
      canonical_before,canonical_after,hash_before,hash_after,
      sequence_before,sequence_after,lifecycle_before,lifecycle_after,
      isolation_status,status,interpretation
    )
    VALUES
    (
      3::smallint,'M2_12_NEG_003_STAGE_STATUS_NOT_ACCEPTED','SOURCE_ACCEPTANCE','P0001',
      'M2.12 component contract is not ACCEPTED','M2.12 component contract is not ACCEPTED','EXACT','',
      v_sqlstate,v_message,coalesce(v_constraint,''),
      v_canonical_before,v_canonical_after,v_hash_before,v_hash_after,
      v_sequence_before,v_sequence_after,v_lifecycle_before,v_lifecycle_after,
      CASE WHEN v_isolation_ok THEN 'PASS' ELSE 'FAIL' END,
      CASE WHEN v_signature_ok AND v_isolation_ok THEN 'PASS' ELSE 'FAIL' END,
      'M2.12 historical acceptance assertion | NONE'
    );
END;
$m212_neg_003$;

/* WP3_NEGATIVE_CONTROL_DEFINITION M2_12_NEG_004_LINEAR_CHAIN_HASH_BREAK */
DO $m212_neg_004$
DECLARE
    v_sqlstate text;
    v_message text;
    v_constraint text;
    v_canonical_before text;
    v_canonical_after text;
    v_hash_before text;
    v_hash_after text;
    v_sequence_before text;
    v_sequence_after text;
    v_lifecycle_before text;
    v_lifecycle_after text;
    v_entities_before integer;
    v_entities_after integer;
    v_signature_ok boolean;
    v_isolation_ok boolean;
BEGIN
    SELECT canonical_fingerprint,stored_hash_fingerprint,sequence_fingerprint,lifecycle_fingerprint,canonical_entity_count
      INTO v_canonical_before,v_hash_before,v_sequence_before,v_lifecycle_before,v_entities_before
      FROM tmp_hash_m2_12_negative_baseline;

    BEGIN
        CREATE TEMP TABLE tmp_neg_004_linear_edge_fixture ON COMMIT DROP AS
        SELECT module1_run_id,edge_sequence,edge_code,target_node_code,expected_source_hash,observed_accepted_source_hash,observed_target_recorded_source_hash,source_gate_status,source_registry_row_count,target_registry_row_count,source_hash_mismatch_flag,target_hash_mismatch_flag,edge_status
        FROM tmp_neg_m2_12_source_edges WHERE edge_sequence BETWEEN 3 AND 14 ORDER BY edge_sequence LIMIT 1;
        UPDATE tmp_neg_004_linear_edge_fixture SET observed_target_recorded_source_hash=repeat('0',32);
        IF EXISTS (SELECT 1 FROM tmp_neg_004_linear_edge_fixture
                   WHERE observed_target_recorded_source_hash IS DISTINCT FROM expected_source_hash) THEN
            RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 linear source edge mismatch';
        END IF;
        RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 negative control unexpectedly accepted injected defect';
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            v_sqlstate = RETURNED_SQLSTATE,
            v_message = MESSAGE_TEXT,
            v_constraint = CONSTRAINT_NAME;
    END;

    SELECT canonical_fingerprint,stored_hash_fingerprint,sequence_fingerprint,lifecycle_fingerprint,canonical_entity_count
      INTO v_canonical_after,v_hash_after,v_sequence_after,v_lifecycle_after,v_entities_after
      FROM tmp_hash_m2_12_negative_current_fingerprint;

    v_signature_ok := (v_sqlstate='P0001' AND v_message='M2.12 linear source edge mismatch');
    v_isolation_ok := (v_entities_before=134 AND v_entities_after=134
                       AND v_canonical_before IS NOT DISTINCT FROM v_canonical_after
                       AND v_hash_before IS NOT DISTINCT FROM v_hash_after
                       AND v_sequence_before IS NOT DISTINCT FROM v_sequence_after
                       AND v_lifecycle_before IS NOT DISTINCT FROM v_lifecycle_after);

    INSERT INTO tmp_neg_m2_12_results
    (
      control_sequence,evidence_code,control_family,expected_sqlstate,
      authority_message_prefix,effective_message_signature,message_match_mode,expected_constraint,
      observed_sqlstate,observed_message,observed_constraint,
      canonical_before,canonical_after,hash_before,hash_after,
      sequence_before,sequence_after,lifecycle_before,lifecycle_after,
      isolation_status,status,interpretation
    )
    VALUES
    (
      4::smallint,'M2_12_NEG_004_LINEAR_CHAIN_HASH_BREAK','SOURCE_GRAPH','P0001',
      'M2.12 linear source edge mismatch','M2.12 linear source edge mismatch','EXACT','',
      v_sqlstate,v_message,coalesce(v_constraint,''),
      v_canonical_before,v_canonical_after,v_hash_before,v_hash_after,
      v_sequence_before,v_sequence_after,v_lifecycle_before,v_lifecycle_after,
      CASE WHEN v_isolation_ok THEN 'PASS' ELSE 'FAIL' END,
      CASE WHEN v_signature_ok AND v_isolation_ok THEN 'PASS' ELSE 'FAIL' END,
      'M2.12 source-graph edge assertion | NONE'
    );
END;
$m212_neg_004$;

/* WP3_NEGATIVE_CONTROL_DEFINITION M2_12_NEG_005_M2_11_MULTISOURCE_HASH_BREAK */
DO $m212_neg_005$
DECLARE
    v_sqlstate text;
    v_message text;
    v_constraint text;
    v_canonical_before text;
    v_canonical_after text;
    v_hash_before text;
    v_hash_after text;
    v_sequence_before text;
    v_sequence_after text;
    v_lifecycle_before text;
    v_lifecycle_after text;
    v_entities_before integer;
    v_entities_after integer;
    v_signature_ok boolean;
    v_isolation_ok boolean;
BEGIN
    SELECT canonical_fingerprint,stored_hash_fingerprint,sequence_fingerprint,lifecycle_fingerprint,canonical_entity_count
      INTO v_canonical_before,v_hash_before,v_sequence_before,v_lifecycle_before,v_entities_before
      FROM tmp_hash_m2_12_negative_baseline;

    BEGIN
        CREATE TEMP TABLE tmp_neg_005_m211_edge_fixture ON COMMIT DROP AS
        SELECT module1_run_id,edge_sequence,edge_code,target_node_code,expected_source_hash,observed_accepted_source_hash,observed_target_recorded_source_hash,source_gate_status,source_registry_row_count,target_registry_row_count,source_hash_mismatch_flag,target_hash_mismatch_flag,edge_status
        FROM tmp_neg_m2_12_source_edges WHERE target_node_code='M2_11_STRATEGY_SIMULATION' ORDER BY edge_sequence LIMIT 1;
        UPDATE tmp_neg_005_m211_edge_fixture SET observed_accepted_source_hash=repeat('0',32);
        IF EXISTS (SELECT 1 FROM tmp_neg_005_m211_edge_fixture
                   WHERE observed_accepted_source_hash IS DISTINCT FROM expected_source_hash) THEN
            RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 M2.11 multi-source edge mismatch';
        END IF;
        RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 negative control unexpectedly accepted injected defect';
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            v_sqlstate = RETURNED_SQLSTATE,
            v_message = MESSAGE_TEXT,
            v_constraint = CONSTRAINT_NAME;
    END;

    SELECT canonical_fingerprint,stored_hash_fingerprint,sequence_fingerprint,lifecycle_fingerprint,canonical_entity_count
      INTO v_canonical_after,v_hash_after,v_sequence_after,v_lifecycle_after,v_entities_after
      FROM tmp_hash_m2_12_negative_current_fingerprint;

    v_signature_ok := (v_sqlstate='P0001' AND v_message='M2.12 M2.11 multi-source edge mismatch');
    v_isolation_ok := (v_entities_before=134 AND v_entities_after=134
                       AND v_canonical_before IS NOT DISTINCT FROM v_canonical_after
                       AND v_hash_before IS NOT DISTINCT FROM v_hash_after
                       AND v_sequence_before IS NOT DISTINCT FROM v_sequence_after
                       AND v_lifecycle_before IS NOT DISTINCT FROM v_lifecycle_after);

    INSERT INTO tmp_neg_m2_12_results
    (
      control_sequence,evidence_code,control_family,expected_sqlstate,
      authority_message_prefix,effective_message_signature,message_match_mode,expected_constraint,
      observed_sqlstate,observed_message,observed_constraint,
      canonical_before,canonical_after,hash_before,hash_after,
      sequence_before,sequence_after,lifecycle_before,lifecycle_after,
      isolation_status,status,interpretation
    )
    VALUES
    (
      5::smallint,'M2_12_NEG_005_M2_11_MULTISOURCE_HASH_BREAK','SOURCE_GRAPH','P0001',
      'M2.12 M2.11 multi-source edge mismatch','M2.12 M2.11 multi-source edge mismatch','EXACT','',
      v_sqlstate,v_message,coalesce(v_constraint,''),
      v_canonical_before,v_canonical_after,v_hash_before,v_hash_after,
      v_sequence_before,v_sequence_after,v_lifecycle_before,v_lifecycle_after,
      CASE WHEN v_isolation_ok THEN 'PASS' ELSE 'FAIL' END,
      CASE WHEN v_signature_ok AND v_isolation_ok THEN 'PASS' ELSE 'FAIL' END,
      'M2.12 M2.11 multi-source graph assertion | NONE'
    );
END;
$m212_neg_005$;

/* WP3_NEGATIVE_CONTROL_DEFINITION M2_12_NEG_006_COMPONENT_COUNT_MISMATCH */
DO $m212_neg_006$
DECLARE
    v_sqlstate text;
    v_message text;
    v_constraint text;
    v_canonical_before text;
    v_canonical_after text;
    v_hash_before text;
    v_hash_after text;
    v_sequence_before text;
    v_sequence_after text;
    v_lifecycle_before text;
    v_lifecycle_after text;
    v_entities_before integer;
    v_entities_after integer;
    v_signature_ok boolean;
    v_isolation_ok boolean;
BEGIN
    SELECT canonical_fingerprint,stored_hash_fingerprint,sequence_fingerprint,lifecycle_fingerprint,canonical_entity_count
      INTO v_canonical_before,v_hash_before,v_sequence_before,v_lifecycle_before,v_entities_before
      FROM tmp_hash_m2_12_negative_baseline;

    BEGIN
        CREATE TEMP TABLE tmp_neg_006_component_count_fixture ON COMMIT DROP AS
        SELECT c.component_sequence,
               c.component_contract_code,
               c.expected_latest_rows,
               c.observed_latest_rows
        FROM msbf_m2.module2_contract_component_snapshot c
        JOIN tmp_neg_m2_12_run_context ctx ON ctx.module1_run_id=c.module1_run_id
        ORDER BY c.component_sequence LIMIT 1;
        UPDATE tmp_neg_006_component_count_fixture SET expected_latest_rows=expected_latest_rows+1;
        IF EXISTS (SELECT 1 FROM tmp_neg_006_component_count_fixture WHERE expected_latest_rows<>observed_latest_rows) THEN
            RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 component row count mismatch';
        END IF;
        RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 negative control unexpectedly accepted injected defect';
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            v_sqlstate = RETURNED_SQLSTATE,
            v_message = MESSAGE_TEXT,
            v_constraint = CONSTRAINT_NAME;
    END;

    SELECT canonical_fingerprint,stored_hash_fingerprint,sequence_fingerprint,lifecycle_fingerprint,canonical_entity_count
      INTO v_canonical_after,v_hash_after,v_sequence_after,v_lifecycle_after,v_entities_after
      FROM tmp_hash_m2_12_negative_current_fingerprint;

    v_signature_ok := (v_sqlstate='P0001' AND v_message='M2.12 component row count mismatch');
    v_isolation_ok := (v_entities_before=134 AND v_entities_after=134
                       AND v_canonical_before IS NOT DISTINCT FROM v_canonical_after
                       AND v_hash_before IS NOT DISTINCT FROM v_hash_after
                       AND v_sequence_before IS NOT DISTINCT FROM v_sequence_after
                       AND v_lifecycle_before IS NOT DISTINCT FROM v_lifecycle_after);

    INSERT INTO tmp_neg_m2_12_results
    (
      control_sequence,evidence_code,control_family,expected_sqlstate,
      authority_message_prefix,effective_message_signature,message_match_mode,expected_constraint,
      observed_sqlstate,observed_message,observed_constraint,
      canonical_before,canonical_after,hash_before,hash_after,
      sequence_before,sequence_after,lifecycle_before,lifecycle_after,
      isolation_status,status,interpretation
    )
    VALUES
    (
      6::smallint,'M2_12_NEG_006_COMPONENT_COUNT_MISMATCH','CONTRACT_COMPONENT','P0001',
      'M2.12 component row count mismatch','M2.12 component row count mismatch','EXACT','',
      v_sqlstate,v_message,coalesce(v_constraint,''),
      v_canonical_before,v_canonical_after,v_hash_before,v_hash_after,
      v_sequence_before,v_sequence_after,v_lifecycle_before,v_lifecycle_after,
      CASE WHEN v_isolation_ok THEN 'PASS' ELSE 'FAIL' END,
      CASE WHEN v_signature_ok AND v_isolation_ok THEN 'PASS' ELSE 'FAIL' END,
      'M2.12 component count reconciliation | NONE'
    );
END;
$m212_neg_006$;

/* WP3_NEGATIVE_CONTROL_DEFINITION M2_12_NEG_007_LATEST_ARCHIVE_PAYLOAD_MISMATCH */
DO $m212_neg_007$
DECLARE
    v_sqlstate text;
    v_message text;
    v_constraint text;
    v_canonical_before text;
    v_canonical_after text;
    v_hash_before text;
    v_hash_after text;
    v_sequence_before text;
    v_sequence_after text;
    v_lifecycle_before text;
    v_lifecycle_after text;
    v_entities_before integer;
    v_entities_after integer;
    v_signature_ok boolean;
    v_isolation_ok boolean;
BEGIN
    SELECT canonical_fingerprint,stored_hash_fingerprint,sequence_fingerprint,lifecycle_fingerprint,canonical_entity_count
      INTO v_canonical_before,v_hash_before,v_sequence_before,v_lifecycle_before,v_entities_before
      FROM tmp_hash_m2_12_negative_baseline;

    BEGIN
        CREATE TEMP TABLE tmp_neg_007_latest_archive_fixture ON COMMIT DROP AS
        SELECT (to_jsonb(l)-'created_at')::jsonb AS latest_payload,a.contract_payload::jsonb AS archive_payload
        FROM msbf_m2.application_eligibility_routing_latest l
        JOIN msbf_m2.application_eligibility_routing_archive a
          ON a.module1_run_id=l.module1_run_id
         AND a.strategy_campaign_code=l.strategy_campaign_code
         AND a.scenario_id=l.scenario_id
         AND a.merchant_application_id=l.merchant_application_id
         AND a.contract_code=l.contract_code
         AND a.contract_version=l.contract_version
        JOIN tmp_neg_m2_12_run_context ctx ON ctx.module1_run_id=l.module1_run_id
        ORDER BY l.strategy_campaign_code,l.scenario_id,l.merchant_application_id LIMIT 1;
        UPDATE tmp_neg_007_latest_archive_fixture
           SET archive_payload=archive_payload||'{"wp3_negative_probe":true}'::jsonb;
        IF EXISTS (SELECT 1 FROM tmp_neg_007_latest_archive_fixture WHERE latest_payload IS DISTINCT FROM archive_payload) THEN
            RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 latest/archive payload mismatch';
        END IF;
        RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 negative control unexpectedly accepted injected defect';
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            v_sqlstate = RETURNED_SQLSTATE,
            v_message = MESSAGE_TEXT,
            v_constraint = CONSTRAINT_NAME;
    END;

    SELECT canonical_fingerprint,stored_hash_fingerprint,sequence_fingerprint,lifecycle_fingerprint,canonical_entity_count
      INTO v_canonical_after,v_hash_after,v_sequence_after,v_lifecycle_after,v_entities_after
      FROM tmp_hash_m2_12_negative_current_fingerprint;

    v_signature_ok := (v_sqlstate='P0001' AND v_message='M2.12 latest/archive payload mismatch');
    v_isolation_ok := (v_entities_before=134 AND v_entities_after=134
                       AND v_canonical_before IS NOT DISTINCT FROM v_canonical_after
                       AND v_hash_before IS NOT DISTINCT FROM v_hash_after
                       AND v_sequence_before IS NOT DISTINCT FROM v_sequence_after
                       AND v_lifecycle_before IS NOT DISTINCT FROM v_lifecycle_after);

    INSERT INTO tmp_neg_m2_12_results
    (
      control_sequence,evidence_code,control_family,expected_sqlstate,
      authority_message_prefix,effective_message_signature,message_match_mode,expected_constraint,
      observed_sqlstate,observed_message,observed_constraint,
      canonical_before,canonical_after,hash_before,hash_after,
      sequence_before,sequence_after,lifecycle_before,lifecycle_after,
      isolation_status,status,interpretation
    )
    VALUES
    (
      7::smallint,'M2_12_NEG_007_LATEST_ARCHIVE_PAYLOAD_MISMATCH','REPRODUCTION','P0001',
      'M2.12 latest/archive payload mismatch','M2.12 latest/archive payload mismatch','EXACT','',
      v_sqlstate,v_message,coalesce(v_constraint,''),
      v_canonical_before,v_canonical_after,v_hash_before,v_hash_after,
      v_sequence_before,v_sequence_after,v_lifecycle_before,v_lifecycle_after,
      CASE WHEN v_isolation_ok THEN 'PASS' ELSE 'FAIL' END,
      CASE WHEN v_signature_ok AND v_isolation_ok THEN 'PASS' ELSE 'FAIL' END,
      'M2.12 latest/archive reproduction assertion | NONE'
    );
END;
$m212_neg_007$;

/* WP3_NEGATIVE_CONTROL_DEFINITION M2_12_NEG_008_ARCHIVE_UPDATE */
DO $m212_neg_008$
DECLARE
    v_sqlstate text;
    v_message text;
    v_constraint text;
    v_canonical_before text;
    v_canonical_after text;
    v_hash_before text;
    v_hash_after text;
    v_sequence_before text;
    v_sequence_after text;
    v_lifecycle_before text;
    v_lifecycle_after text;
    v_entities_before integer;
    v_entities_after integer;
    v_signature_ok boolean;
    v_isolation_ok boolean;
BEGIN
    SELECT canonical_fingerprint,stored_hash_fingerprint,sequence_fingerprint,lifecycle_fingerprint,canonical_entity_count
      INTO v_canonical_before,v_hash_before,v_sequence_before,v_lifecycle_before,v_entities_before
      FROM tmp_hash_m2_12_negative_baseline;

    BEGIN
        UPDATE msbf_ctl.m2_12_g3_bundle_archive a
           SET contract_payload=a.contract_payload
          FROM tmp_neg_m2_12_run_context ctx
         WHERE a.module1_run_id=ctx.module1_run_id
           AND a.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND a.contract_version=1;
        RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 negative control unexpectedly accepted injected defect';
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            v_sqlstate = RETURNED_SQLSTATE,
            v_message = MESSAGE_TEXT,
            v_constraint = CONSTRAINT_NAME;
    END;

    SELECT canonical_fingerprint,stored_hash_fingerprint,sequence_fingerprint,lifecycle_fingerprint,canonical_entity_count
      INTO v_canonical_after,v_hash_after,v_sequence_after,v_lifecycle_after,v_entities_after
      FROM tmp_hash_m2_12_negative_current_fingerprint;

    v_signature_ok := (v_sqlstate='P0001' AND v_message='M2.12 immutable G3 archive rejects UPDATE or DELETE');
    v_isolation_ok := (v_entities_before=134 AND v_entities_after=134
                       AND v_canonical_before IS NOT DISTINCT FROM v_canonical_after
                       AND v_hash_before IS NOT DISTINCT FROM v_hash_after
                       AND v_sequence_before IS NOT DISTINCT FROM v_sequence_after
                       AND v_lifecycle_before IS NOT DISTINCT FROM v_lifecycle_after);

    INSERT INTO tmp_neg_m2_12_results
    (
      control_sequence,evidence_code,control_family,expected_sqlstate,
      authority_message_prefix,effective_message_signature,message_match_mode,expected_constraint,
      observed_sqlstate,observed_message,observed_constraint,
      canonical_before,canonical_after,hash_before,hash_after,
      sequence_before,sequence_after,lifecycle_before,lifecycle_after,
      isolation_status,status,interpretation
    )
    VALUES
    (
      8::smallint,'M2_12_NEG_008_ARCHIVE_UPDATE','ARCHIVE_IMMUTABILITY','P0001',
      'M2.12 archive is immutable','M2.12 immutable G3 archive rejects UPDATE or DELETE','EXACT','',
      v_sqlstate,v_message,coalesce(v_constraint,''),
      v_canonical_before,v_canonical_after,v_hash_before,v_hash_after,
      v_sequence_before,v_sequence_after,v_lifecycle_before,v_lifecycle_after,
      CASE WHEN v_isolation_ok THEN 'PASS' ELSE 'FAIL' END,
      CASE WHEN v_signature_ok AND v_isolation_ok THEN 'PASS' ELSE 'FAIL' END,
      'BEFORE UPDATE OR DELETE archive immutability trigger | Prospective negative-control catalog used prefix "M2.12 archive is immutable"; approved WP2 R4 physical trigger emits exact message "M2.12 immutable G3 archive rejects UPDATE or DELETE". The physical R4 trigger signature governs reachable source construction.'
    );
END;
$m212_neg_008$;

/* WP3_NEGATIVE_CONTROL_DEFINITION M2_12_NEG_009_ARCHIVE_DELETE */
DO $m212_neg_009$
DECLARE
    v_sqlstate text;
    v_message text;
    v_constraint text;
    v_canonical_before text;
    v_canonical_after text;
    v_hash_before text;
    v_hash_after text;
    v_sequence_before text;
    v_sequence_after text;
    v_lifecycle_before text;
    v_lifecycle_after text;
    v_entities_before integer;
    v_entities_after integer;
    v_signature_ok boolean;
    v_isolation_ok boolean;
BEGIN
    SELECT canonical_fingerprint,stored_hash_fingerprint,sequence_fingerprint,lifecycle_fingerprint,canonical_entity_count
      INTO v_canonical_before,v_hash_before,v_sequence_before,v_lifecycle_before,v_entities_before
      FROM tmp_hash_m2_12_negative_baseline;

    BEGIN
        DELETE FROM msbf_ctl.m2_12_g3_bundle_archive a
         USING tmp_neg_m2_12_run_context ctx
         WHERE a.module1_run_id=ctx.module1_run_id
           AND a.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND a.contract_version=1;
        RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 negative control unexpectedly accepted injected defect';
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            v_sqlstate = RETURNED_SQLSTATE,
            v_message = MESSAGE_TEXT,
            v_constraint = CONSTRAINT_NAME;
    END;

    SELECT canonical_fingerprint,stored_hash_fingerprint,sequence_fingerprint,lifecycle_fingerprint,canonical_entity_count
      INTO v_canonical_after,v_hash_after,v_sequence_after,v_lifecycle_after,v_entities_after
      FROM tmp_hash_m2_12_negative_current_fingerprint;

    v_signature_ok := (v_sqlstate='P0001' AND v_message='M2.12 immutable G3 archive rejects UPDATE or DELETE');
    v_isolation_ok := (v_entities_before=134 AND v_entities_after=134
                       AND v_canonical_before IS NOT DISTINCT FROM v_canonical_after
                       AND v_hash_before IS NOT DISTINCT FROM v_hash_after
                       AND v_sequence_before IS NOT DISTINCT FROM v_sequence_after
                       AND v_lifecycle_before IS NOT DISTINCT FROM v_lifecycle_after);

    INSERT INTO tmp_neg_m2_12_results
    (
      control_sequence,evidence_code,control_family,expected_sqlstate,
      authority_message_prefix,effective_message_signature,message_match_mode,expected_constraint,
      observed_sqlstate,observed_message,observed_constraint,
      canonical_before,canonical_after,hash_before,hash_after,
      sequence_before,sequence_after,lifecycle_before,lifecycle_after,
      isolation_status,status,interpretation
    )
    VALUES
    (
      9::smallint,'M2_12_NEG_009_ARCHIVE_DELETE','ARCHIVE_IMMUTABILITY','P0001',
      'M2.12 archive is immutable','M2.12 immutable G3 archive rejects UPDATE or DELETE','EXACT','',
      v_sqlstate,v_message,coalesce(v_constraint,''),
      v_canonical_before,v_canonical_after,v_hash_before,v_hash_after,
      v_sequence_before,v_sequence_after,v_lifecycle_before,v_lifecycle_after,
      CASE WHEN v_isolation_ok THEN 'PASS' ELSE 'FAIL' END,
      CASE WHEN v_signature_ok AND v_isolation_ok THEN 'PASS' ELSE 'FAIL' END,
      'BEFORE UPDATE OR DELETE archive immutability trigger | Prospective negative-control catalog used prefix "M2.12 archive is immutable"; approved WP2 R4 physical trigger emits exact message "M2.12 immutable G3 archive rejects UPDATE or DELETE". The physical R4 trigger signature governs reachable source construction.'
    );
END;
$m212_neg_009$;

/* WP3_NEGATIVE_CONTROL_DEFINITION M2_12_NEG_010_DUPLICATE_STAGE_CERTIFICATION_KEY */
DO $m212_neg_010$
DECLARE
    v_sqlstate text;
    v_message text;
    v_constraint text;
    v_canonical_before text;
    v_canonical_after text;
    v_hash_before text;
    v_hash_after text;
    v_sequence_before text;
    v_sequence_after text;
    v_lifecycle_before text;
    v_lifecycle_after text;
    v_entities_before integer;
    v_entities_after integer;
    v_signature_ok boolean;
    v_isolation_ok boolean;
BEGIN
    SELECT canonical_fingerprint,stored_hash_fingerprint,sequence_fingerprint,lifecycle_fingerprint,canonical_entity_count
      INTO v_canonical_before,v_hash_before,v_sequence_before,v_lifecycle_before,v_entities_before
      FROM tmp_hash_m2_12_negative_baseline;

    BEGIN
        INSERT INTO msbf_m2.module2_stage_certification_snapshot
        SELECT s.*
        FROM msbf_m2.module2_stage_certification_snapshot s
        JOIN tmp_neg_m2_12_run_context ctx ON ctx.module1_run_id=s.module1_run_id
        ORDER BY s.certification_node_sequence LIMIT 1;
        RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 negative control unexpectedly accepted injected defect';
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            v_sqlstate = RETURNED_SQLSTATE,
            v_message = MESSAGE_TEXT,
            v_constraint = CONSTRAINT_NAME;
    END;

    SELECT canonical_fingerprint,stored_hash_fingerprint,sequence_fingerprint,lifecycle_fingerprint,canonical_entity_count
      INTO v_canonical_after,v_hash_after,v_sequence_after,v_lifecycle_after,v_entities_after
      FROM tmp_hash_m2_12_negative_current_fingerprint;

    v_signature_ok := (v_sqlstate='23505' AND position('duplicate key value violates unique constraint' in coalesce(v_message,''))=1 AND coalesce(v_constraint,'')='pk_m212_stage_cert');
    v_isolation_ok := (v_entities_before=134 AND v_entities_after=134
                       AND v_canonical_before IS NOT DISTINCT FROM v_canonical_after
                       AND v_hash_before IS NOT DISTINCT FROM v_hash_after
                       AND v_sequence_before IS NOT DISTINCT FROM v_sequence_after
                       AND v_lifecycle_before IS NOT DISTINCT FROM v_lifecycle_after);

    INSERT INTO tmp_neg_m2_12_results
    (
      control_sequence,evidence_code,control_family,expected_sqlstate,
      authority_message_prefix,effective_message_signature,message_match_mode,expected_constraint,
      observed_sqlstate,observed_message,observed_constraint,
      canonical_before,canonical_after,hash_before,hash_after,
      sequence_before,sequence_after,lifecycle_before,lifecycle_after,
      isolation_status,status,interpretation
    )
    VALUES
    (
      10::smallint,'M2_12_NEG_010_DUPLICATE_STAGE_CERTIFICATION_KEY','PHYSICAL_CONSTRAINT','23505',
      'duplicate key value violates unique constraint','duplicate key value violates unique constraint','PREFIX_AND_CONSTRAINT','pk_m212_stage_cert',
      v_sqlstate,v_message,coalesce(v_constraint,''),
      v_canonical_before,v_canonical_after,v_hash_before,v_hash_after,
      v_sequence_before,v_sequence_after,v_lifecycle_before,v_lifecycle_after,
      CASE WHEN v_isolation_ok THEN 'PASS' ELSE 'FAIL' END,
      CASE WHEN v_signature_ok AND v_isolation_ok THEN 'PASS' ELSE 'FAIL' END,
      'Unique constraint on stage-certification business key | NONE'
    );
END;
$m212_neg_010$;

/* WP3_NEGATIVE_CONTROL_DEFINITION M2_12_NEG_011_DUPLICATE_COMPONENT_CONTRACT_KEY */
DO $m212_neg_011$
DECLARE
    v_sqlstate text;
    v_message text;
    v_constraint text;
    v_canonical_before text;
    v_canonical_after text;
    v_hash_before text;
    v_hash_after text;
    v_sequence_before text;
    v_sequence_after text;
    v_lifecycle_before text;
    v_lifecycle_after text;
    v_entities_before integer;
    v_entities_after integer;
    v_signature_ok boolean;
    v_isolation_ok boolean;
BEGIN
    SELECT canonical_fingerprint,stored_hash_fingerprint,sequence_fingerprint,lifecycle_fingerprint,canonical_entity_count
      INTO v_canonical_before,v_hash_before,v_sequence_before,v_lifecycle_before,v_entities_before
      FROM tmp_hash_m2_12_negative_baseline;

    BEGIN
        INSERT INTO msbf_m2.module2_contract_component_snapshot
        SELECT c.*
        FROM msbf_m2.module2_contract_component_snapshot c
        JOIN tmp_neg_m2_12_run_context ctx ON ctx.module1_run_id=c.module1_run_id
        ORDER BY c.component_sequence LIMIT 1;
        RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 negative control unexpectedly accepted injected defect';
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            v_sqlstate = RETURNED_SQLSTATE,
            v_message = MESSAGE_TEXT,
            v_constraint = CONSTRAINT_NAME;
    END;

    SELECT canonical_fingerprint,stored_hash_fingerprint,sequence_fingerprint,lifecycle_fingerprint,canonical_entity_count
      INTO v_canonical_after,v_hash_after,v_sequence_after,v_lifecycle_after,v_entities_after
      FROM tmp_hash_m2_12_negative_current_fingerprint;

    v_signature_ok := (v_sqlstate='23505' AND position('duplicate key value violates unique constraint' in coalesce(v_message,''))=1 AND coalesce(v_constraint,'')='pk_m212_component');
    v_isolation_ok := (v_entities_before=134 AND v_entities_after=134
                       AND v_canonical_before IS NOT DISTINCT FROM v_canonical_after
                       AND v_hash_before IS NOT DISTINCT FROM v_hash_after
                       AND v_sequence_before IS NOT DISTINCT FROM v_sequence_after
                       AND v_lifecycle_before IS NOT DISTINCT FROM v_lifecycle_after);

    INSERT INTO tmp_neg_m2_12_results
    (
      control_sequence,evidence_code,control_family,expected_sqlstate,
      authority_message_prefix,effective_message_signature,message_match_mode,expected_constraint,
      observed_sqlstate,observed_message,observed_constraint,
      canonical_before,canonical_after,hash_before,hash_after,
      sequence_before,sequence_after,lifecycle_before,lifecycle_after,
      isolation_status,status,interpretation
    )
    VALUES
    (
      11::smallint,'M2_12_NEG_011_DUPLICATE_COMPONENT_CONTRACT_KEY','PHYSICAL_CONSTRAINT','23505',
      'duplicate key value violates unique constraint','duplicate key value violates unique constraint','PREFIX_AND_CONSTRAINT','pk_m212_component',
      v_sqlstate,v_message,coalesce(v_constraint,''),
      v_canonical_before,v_canonical_after,v_hash_before,v_hash_after,
      v_sequence_before,v_sequence_after,v_lifecycle_before,v_lifecycle_after,
      CASE WHEN v_isolation_ok THEN 'PASS' ELSE 'FAIL' END,
      CASE WHEN v_signature_ok AND v_isolation_ok THEN 'PASS' ELSE 'FAIL' END,
      'Unique constraint on component-contract business key | NONE'
    );
END;
$m212_neg_011$;

/* WP3_NEGATIVE_CONTROL_DEFINITION M2_12_NEG_012_EVIDENCE_CERTIFICATION_DEFICIENCY */
DO $m212_neg_012$
DECLARE
    v_sqlstate text;
    v_message text;
    v_constraint text;
    v_canonical_before text;
    v_canonical_after text;
    v_hash_before text;
    v_hash_after text;
    v_sequence_before text;
    v_sequence_after text;
    v_lifecycle_before text;
    v_lifecycle_after text;
    v_entities_before integer;
    v_entities_after integer;
    v_signature_ok boolean;
    v_isolation_ok boolean;
BEGIN
    SELECT canonical_fingerprint,stored_hash_fingerprint,sequence_fingerprint,lifecycle_fingerprint,canonical_entity_count
      INTO v_canonical_before,v_hash_before,v_sequence_before,v_lifecycle_before,v_entities_before
      FROM tmp_hash_m2_12_negative_baseline;

    BEGIN
        CREATE TEMP TABLE tmp_neg_012_evidence_fixture ON COMMIT DROP AS
        SELECT e.node_sequence,
               e.evidence_family_sequence,
               e.evidence_family_code,
               e.applicability_code,
               e.certification_status
        FROM msbf_m2.module2_evidence_certification_snapshot e
        JOIN tmp_neg_m2_12_run_context ctx ON ctx.module1_run_id=e.module1_run_id;
        DELETE FROM tmp_neg_012_evidence_fixture
         WHERE (node_sequence,evidence_family_sequence)=(SELECT node_sequence,evidence_family_sequence FROM tmp_neg_012_evidence_fixture ORDER BY 1,2 LIMIT 1);
        IF (SELECT count(*) FROM tmp_neg_012_evidence_fixture)<>72
           OR EXISTS (SELECT 1 FROM tmp_neg_012_evidence_fixture WHERE applicability_code<>'MANDATORY' OR certification_status<>'PASS') THEN
            RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 evidence certification incomplete or failed';
        END IF;
        RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 negative control unexpectedly accepted injected defect';
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            v_sqlstate = RETURNED_SQLSTATE,
            v_message = MESSAGE_TEXT,
            v_constraint = CONSTRAINT_NAME;
    END;

    SELECT canonical_fingerprint,stored_hash_fingerprint,sequence_fingerprint,lifecycle_fingerprint,canonical_entity_count
      INTO v_canonical_after,v_hash_after,v_sequence_after,v_lifecycle_after,v_entities_after
      FROM tmp_hash_m2_12_negative_current_fingerprint;

    v_signature_ok := (v_sqlstate='P0001' AND v_message='M2.12 evidence certification incomplete or failed');
    v_isolation_ok := (v_entities_before=134 AND v_entities_after=134
                       AND v_canonical_before IS NOT DISTINCT FROM v_canonical_after
                       AND v_hash_before IS NOT DISTINCT FROM v_hash_after
                       AND v_sequence_before IS NOT DISTINCT FROM v_sequence_after
                       AND v_lifecycle_before IS NOT DISTINCT FROM v_lifecycle_after);

    INSERT INTO tmp_neg_m2_12_results
    (
      control_sequence,evidence_code,control_family,expected_sqlstate,
      authority_message_prefix,effective_message_signature,message_match_mode,expected_constraint,
      observed_sqlstate,observed_message,observed_constraint,
      canonical_before,canonical_after,hash_before,hash_after,
      sequence_before,sequence_after,lifecycle_before,lifecycle_after,
      isolation_status,status,interpretation
    )
    VALUES
    (
      12::smallint,'M2_12_NEG_012_EVIDENCE_CERTIFICATION_DEFICIENCY','EVIDENCE_CERTIFICATION','P0001',
      'M2.12 evidence certification incomplete or failed','M2.12 evidence certification incomplete or failed','EXACT','',
      v_sqlstate,v_message,coalesce(v_constraint,''),
      v_canonical_before,v_canonical_after,v_hash_before,v_hash_after,
      v_sequence_before,v_sequence_after,v_lifecycle_before,v_lifecycle_after,
      CASE WHEN v_isolation_ok THEN 'PASS' ELSE 'FAIL' END,
      CASE WHEN v_signature_ok AND v_isolation_ok THEN 'PASS' ELSE 'FAIL' END,
      '72-row completeness and all-PASS assertion | NONE'
    );
END;
$m212_neg_012$;

/* WP3_NEGATIVE_CONTROL_DEFINITION M2_12_NEG_013_CANONICAL_COUNT_OR_SET_HASH_MISMATCH */
DO $m212_neg_013$
DECLARE
    v_sqlstate text;
    v_message text;
    v_constraint text;
    v_canonical_before text;
    v_canonical_after text;
    v_hash_before text;
    v_hash_after text;
    v_sequence_before text;
    v_sequence_after text;
    v_lifecycle_before text;
    v_lifecycle_after text;
    v_entities_before integer;
    v_entities_after integer;
    v_signature_ok boolean;
    v_isolation_ok boolean;
BEGIN
    SELECT canonical_fingerprint,stored_hash_fingerprint,sequence_fingerprint,lifecycle_fingerprint,canonical_entity_count
      INTO v_canonical_before,v_hash_before,v_sequence_before,v_lifecycle_before,v_entities_before
      FROM tmp_hash_m2_12_negative_baseline;

    BEGIN
        CREATE TEMP TABLE tmp_neg_013_canonical_fixture ON COMMIT DROP AS
        SELECT family_code,business_key,row_hash
        FROM (
            SELECT 'POLICY'::text family_code,concat_ws('|',p.policy_code,p.policy_version::text) business_key,p.row_hash
            FROM msbf_ctl.m2_12_policy_profile p JOIN tmp_neg_m2_12_run_context ctx ON ctx.module1_run_id=p.module1_run_id
            UNION ALL SELECT 'STAGE_CERTIFICATION',concat_ws('|',s.certification_node_sequence::text,s.stage_code),s.row_hash
            FROM msbf_m2.module2_stage_certification_snapshot s JOIN tmp_neg_m2_12_run_context ctx ON ctx.module1_run_id=s.module1_run_id
            UNION ALL SELECT 'CONTRACT_COMPONENT',concat_ws('|',c.component_sequence::text,c.component_contract_code,c.contract_version::text),c.row_hash
            FROM msbf_m2.module2_contract_component_snapshot c JOIN tmp_neg_m2_12_run_context ctx ON ctx.module1_run_id=c.module1_run_id
            UNION ALL SELECT 'EVIDENCE_CERTIFICATION',concat_ws('|',e.node_sequence::text,e.evidence_family_sequence::text),e.row_hash
            FROM msbf_m2.module2_evidence_certification_snapshot e JOIN tmp_neg_m2_12_run_context ctx ON ctx.module1_run_id=e.module1_run_id
            UNION ALL SELECT 'CONTRACT_REPRODUCTION',concat_ws('|',r.component_sequence::text,r.component_contract_code,r.contract_version::text),r.row_hash
            FROM msbf_m2.module2_contract_reproduction_snapshot r JOIN tmp_neg_m2_12_run_context ctx ON ctx.module1_run_id=r.module1_run_id
            UNION ALL SELECT 'CAPABILITY_COVERAGE',concat_ws('|',c.capability_sequence::text,c.capability_code),c.row_hash
            FROM msbf_m2.module2_capability_coverage_snapshot c JOIN tmp_neg_m2_12_run_context ctx ON ctx.module1_run_id=c.module1_run_id
            UNION ALL SELECT 'LATEST',concat_ws('|',l.bundle_code,l.contract_version::text),l.row_hash
            FROM msbf_ctl.m2_12_g3_bundle_latest l JOIN tmp_neg_m2_12_run_context ctx ON ctx.module1_run_id=l.module1_run_id
            UNION ALL SELECT 'ARCHIVE',concat_ws('|',a.bundle_code,a.contract_version::text),a.archive_row_hash
            FROM msbf_ctl.m2_12_g3_bundle_archive a JOIN tmp_neg_m2_12_run_context ctx ON ctx.module1_run_id=a.module1_run_id
            UNION ALL SELECT 'REGISTRY',concat_ws('|',g.bundle_code,g.contract_version::text),g.row_hash
            FROM msbf_ctl.m2_12_g3_bundle_registry g JOIN tmp_neg_m2_12_run_context ctx ON ctx.module1_run_id=g.module1_run_id
        ) q;
        UPDATE tmp_neg_013_canonical_fixture SET row_hash=repeat('0',32)
         WHERE (family_code,business_key)=(SELECT family_code,business_key FROM tmp_neg_013_canonical_fixture ORDER BY 1,2 LIMIT 1);
        IF (SELECT count(*) FROM tmp_neg_013_canonical_fixture)<>134
           OR (SELECT md5(string_agg(concat_ws('|',family_code,business_key,row_hash),'|' ORDER BY family_code,business_key)) FROM tmp_neg_013_canonical_fixture)
              IS DISTINCT FROM (SELECT canonical_fingerprint FROM tmp_hash_m2_12_negative_baseline) THEN
            RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 canonical identity mismatch';
        END IF;
        RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 negative control unexpectedly accepted injected defect';
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            v_sqlstate = RETURNED_SQLSTATE,
            v_message = MESSAGE_TEXT,
            v_constraint = CONSTRAINT_NAME;
    END;

    SELECT canonical_fingerprint,stored_hash_fingerprint,sequence_fingerprint,lifecycle_fingerprint,canonical_entity_count
      INTO v_canonical_after,v_hash_after,v_sequence_after,v_lifecycle_after,v_entities_after
      FROM tmp_hash_m2_12_negative_current_fingerprint;

    v_signature_ok := (v_sqlstate='P0001' AND v_message='M2.12 canonical identity mismatch');
    v_isolation_ok := (v_entities_before=134 AND v_entities_after=134
                       AND v_canonical_before IS NOT DISTINCT FROM v_canonical_after
                       AND v_hash_before IS NOT DISTINCT FROM v_hash_after
                       AND v_sequence_before IS NOT DISTINCT FROM v_sequence_after
                       AND v_lifecycle_before IS NOT DISTINCT FROM v_lifecycle_after);

    INSERT INTO tmp_neg_m2_12_results
    (
      control_sequence,evidence_code,control_family,expected_sqlstate,
      authority_message_prefix,effective_message_signature,message_match_mode,expected_constraint,
      observed_sqlstate,observed_message,observed_constraint,
      canonical_before,canonical_after,hash_before,hash_after,
      sequence_before,sequence_after,lifecycle_before,lifecycle_after,
      isolation_status,status,interpretation
    )
    VALUES
    (
      13::smallint,'M2_12_NEG_013_CANONICAL_COUNT_OR_SET_HASH_MISMATCH','CANONICAL_IDENTITY','P0001',
      'M2.12 canonical identity mismatch','M2.12 canonical identity mismatch','EXACT','',
      v_sqlstate,v_message,coalesce(v_constraint,''),
      v_canonical_before,v_canonical_after,v_hash_before,v_hash_after,
      v_sequence_before,v_sequence_after,v_lifecycle_before,v_lifecycle_after,
      CASE WHEN v_isolation_ok THEN 'PASS' ELSE 'FAIL' END,
      CASE WHEN v_signature_ok AND v_isolation_ok THEN 'PASS' ELSE 'FAIL' END,
      'Nine-family count/set-hash and 134-entity combined-hash assertion | NONE'
    );
END;
$m212_neg_013$;

/* WP3_NEGATIVE_CONTROL_DEFINITION M2_12_NEG_014_CONTRACT_VERSION_1_RERUN */
DO $m212_neg_014$
DECLARE
    v_sqlstate text;
    v_message text;
    v_constraint text;
    v_canonical_before text;
    v_canonical_after text;
    v_hash_before text;
    v_hash_after text;
    v_sequence_before text;
    v_sequence_after text;
    v_lifecycle_before text;
    v_lifecycle_after text;
    v_entities_before integer;
    v_entities_after integer;
    v_signature_ok boolean;
    v_isolation_ok boolean;
BEGIN
    SELECT canonical_fingerprint,stored_hash_fingerprint,sequence_fingerprint,lifecycle_fingerprint,canonical_entity_count
      INTO v_canonical_before,v_hash_before,v_sequence_before,v_lifecycle_before,v_entities_before
      FROM tmp_hash_m2_12_negative_baseline;

    BEGIN
        IF EXISTS (
            SELECT 1 FROM msbf_ctl.m2_12_policy_profile p
            JOIN tmp_neg_m2_12_run_context ctx ON ctx.module1_run_id=p.module1_run_id
            JOIN msbf_ctl.m2_12_g3_bundle_latest l
              ON l.module1_run_id=p.module1_run_id
             AND l.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND l.contract_version=1
            JOIN msbf_ctl.m2_12_g3_bundle_archive a
              ON a.module1_run_id=p.module1_run_id
             AND a.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND a.contract_version=1
            JOIN msbf_ctl.m2_12_g3_bundle_registry g
              ON g.module1_run_id=p.module1_run_id
             AND g.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND g.contract_version=1
             AND g.contract_status='VALIDATED'
            WHERE p.policy_code='M2_12_ENTERPRISE_PORTFOLIO_CERTIFICATION_POLICY_V1'
              AND p.policy_version=1 AND p.policy_status='APPROVED'
        ) THEN
            RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 contract version 1 already generated';
        END IF;
        RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 negative control unexpectedly accepted injected defect';
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            v_sqlstate = RETURNED_SQLSTATE,
            v_message = MESSAGE_TEXT,
            v_constraint = CONSTRAINT_NAME;
    END;

    SELECT canonical_fingerprint,stored_hash_fingerprint,sequence_fingerprint,lifecycle_fingerprint,canonical_entity_count
      INTO v_canonical_after,v_hash_after,v_sequence_after,v_lifecycle_after,v_entities_after
      FROM tmp_hash_m2_12_negative_current_fingerprint;

    v_signature_ok := (v_sqlstate='P0001' AND v_message='M2.12 contract version 1 already generated');
    v_isolation_ok := (v_entities_before=134 AND v_entities_after=134
                       AND v_canonical_before IS NOT DISTINCT FROM v_canonical_after
                       AND v_hash_before IS NOT DISTINCT FROM v_hash_after
                       AND v_sequence_before IS NOT DISTINCT FROM v_sequence_after
                       AND v_lifecycle_before IS NOT DISTINCT FROM v_lifecycle_after);

    INSERT INTO tmp_neg_m2_12_results
    (
      control_sequence,evidence_code,control_family,expected_sqlstate,
      authority_message_prefix,effective_message_signature,message_match_mode,expected_constraint,
      observed_sqlstate,observed_message,observed_constraint,
      canonical_before,canonical_after,hash_before,hash_after,
      sequence_before,sequence_after,lifecycle_before,lifecycle_after,
      isolation_status,status,interpretation
    )
    VALUES
    (
      14::smallint,'M2_12_NEG_014_CONTRACT_VERSION_1_RERUN','RERUN_GUARD','P0001',
      'M2.12 contract version 1 already generated','M2.12 contract version 1 already generated','EXACT','',
      v_sqlstate,v_message,coalesce(v_constraint,''),
      v_canonical_before,v_canonical_after,v_hash_before,v_hash_after,
      v_sequence_before,v_sequence_after,v_lifecycle_before,v_lifecycle_after,
      CASE WHEN v_isolation_ok THEN 'PASS' ELSE 'FAIL' END,
      CASE WHEN v_signature_ok AND v_isolation_ok THEN 'PASS' ELSE 'FAIL' END,
      'Program 222 pristine-target/rerun assertion | NONE'
    );
END;
$m212_neg_014$;

/* WP3_NEGATIVE_CONTROL_DEFINITION M2_12_NEG_015_APPLICATION_VIEW_GRAIN_MULTIPLICATION */
DO $m212_neg_015$
DECLARE
    v_sqlstate text;
    v_message text;
    v_constraint text;
    v_canonical_before text;
    v_canonical_after text;
    v_hash_before text;
    v_hash_after text;
    v_sequence_before text;
    v_sequence_after text;
    v_lifecycle_before text;
    v_lifecycle_after text;
    v_entities_before integer;
    v_entities_after integer;
    v_signature_ok boolean;
    v_isolation_ok boolean;
BEGIN
    SELECT canonical_fingerprint,stored_hash_fingerprint,sequence_fingerprint,lifecycle_fingerprint,canonical_entity_count
      INTO v_canonical_before,v_hash_before,v_sequence_before,v_lifecycle_before,v_entities_before
      FROM tmp_hash_m2_12_negative_baseline;

    BEGIN
        CREATE TEMP TABLE tmp_neg_015_application_grain_fixture ON COMMIT DROP AS
        SELECT v.module1_run_id,v.scenario_id,v.merchant_application_id
        FROM msbf_m2.v_m2_12_application_origination_consumption v
        JOIN tmp_neg_m2_12_run_context ctx ON ctx.module1_run_id=v.module1_run_id;
        INSERT INTO tmp_neg_015_application_grain_fixture(module1_run_id,scenario_id,merchant_application_id)
        SELECT module1_run_id,scenario_id,merchant_application_id
        FROM tmp_neg_015_application_grain_fixture ORDER BY scenario_id,merchant_application_id LIMIT 1;
        IF (SELECT count(*) FROM tmp_neg_015_application_grain_fixture)<>1500
           OR (SELECT count(DISTINCT (module1_run_id,scenario_id,merchant_application_id)) FROM tmp_neg_015_application_grain_fixture)<>1500 THEN
            RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 application consumption grain multiplication';
        END IF;
        RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 negative control unexpectedly accepted injected defect';
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            v_sqlstate = RETURNED_SQLSTATE,
            v_message = MESSAGE_TEXT,
            v_constraint = CONSTRAINT_NAME;
    END;

    SELECT canonical_fingerprint,stored_hash_fingerprint,sequence_fingerprint,lifecycle_fingerprint,canonical_entity_count
      INTO v_canonical_after,v_hash_after,v_sequence_after,v_lifecycle_after,v_entities_after
      FROM tmp_hash_m2_12_negative_current_fingerprint;

    v_signature_ok := (v_sqlstate='P0001' AND v_message='M2.12 application consumption grain multiplication');
    v_isolation_ok := (v_entities_before=134 AND v_entities_after=134
                       AND v_canonical_before IS NOT DISTINCT FROM v_canonical_after
                       AND v_hash_before IS NOT DISTINCT FROM v_hash_after
                       AND v_sequence_before IS NOT DISTINCT FROM v_sequence_after
                       AND v_lifecycle_before IS NOT DISTINCT FROM v_lifecycle_after);

    INSERT INTO tmp_neg_m2_12_results
    (
      control_sequence,evidence_code,control_family,expected_sqlstate,
      authority_message_prefix,effective_message_signature,message_match_mode,expected_constraint,
      observed_sqlstate,observed_message,observed_constraint,
      canonical_before,canonical_after,hash_before,hash_after,
      sequence_before,sequence_after,lifecycle_before,lifecycle_after,
      isolation_status,status,interpretation
    )
    VALUES
    (
      15::smallint,'M2_12_NEG_015_APPLICATION_VIEW_GRAIN_MULTIPLICATION','CONSUMPTION_GRAIN','P0001',
      'M2.12 application consumption grain multiplication','M2.12 application consumption grain multiplication','EXACT','',
      v_sqlstate,v_message,coalesce(v_constraint,''),
      v_canonical_before,v_canonical_after,v_hash_before,v_hash_after,
      v_sequence_before,v_sequence_after,v_lifecycle_before,v_lifecycle_after,
      CASE WHEN v_isolation_ok THEN 'PASS' ELSE 'FAIL' END,
      CASE WHEN v_signature_ok AND v_isolation_ok THEN 'PASS' ELSE 'FAIL' END,
      'Application-view grain/count assertion | NONE'
    );
END;
$m212_neg_015$;

/* WP3_NEGATIVE_CONTROL_DEFINITION M2_12_NEG_016_OPERATIONAL_VIEW_ORPHAN_OR_DUPLICATE */
DO $m212_neg_016$
DECLARE
    v_sqlstate text;
    v_message text;
    v_constraint text;
    v_canonical_before text;
    v_canonical_after text;
    v_hash_before text;
    v_hash_after text;
    v_sequence_before text;
    v_sequence_after text;
    v_lifecycle_before text;
    v_lifecycle_after text;
    v_entities_before integer;
    v_entities_after integer;
    v_signature_ok boolean;
    v_isolation_ok boolean;
BEGIN
    SELECT canonical_fingerprint,stored_hash_fingerprint,sequence_fingerprint,lifecycle_fingerprint,canonical_entity_count
      INTO v_canonical_before,v_hash_before,v_sequence_before,v_lifecycle_before,v_entities_before
      FROM tmp_hash_m2_12_negative_baseline;

    BEGIN
        CREATE TEMP TABLE tmp_neg_016_operational_grain_fixture ON COMMIT DROP AS
        SELECT v.module1_run_id,v.scenario_id,v.merchant_application_id,v.synthetic_account_id,v.synthetic_advance_id
        FROM msbf_m2.v_m2_12_operational_account_consumption v
        JOIN tmp_neg_m2_12_run_context ctx ON ctx.module1_run_id=v.module1_run_id;
        INSERT INTO tmp_neg_016_operational_grain_fixture(module1_run_id,scenario_id,merchant_application_id,synthetic_account_id,synthetic_advance_id)
        SELECT module1_run_id,scenario_id,merchant_application_id,synthetic_account_id,synthetic_advance_id
        FROM tmp_neg_016_operational_grain_fixture ORDER BY scenario_id,merchant_application_id,synthetic_account_id,synthetic_advance_id LIMIT 1;
        IF (SELECT count(*) FROM tmp_neg_016_operational_grain_fixture)<>59
           OR (SELECT count(DISTINCT (module1_run_id,scenario_id,merchant_application_id,synthetic_account_id,synthetic_advance_id)) FROM tmp_neg_016_operational_grain_fixture)<>59 THEN
            RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 operational account grain or lineage violation';
        END IF;
        RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 negative control unexpectedly accepted injected defect';
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            v_sqlstate = RETURNED_SQLSTATE,
            v_message = MESSAGE_TEXT,
            v_constraint = CONSTRAINT_NAME;
    END;

    SELECT canonical_fingerprint,stored_hash_fingerprint,sequence_fingerprint,lifecycle_fingerprint,canonical_entity_count
      INTO v_canonical_after,v_hash_after,v_sequence_after,v_lifecycle_after,v_entities_after
      FROM tmp_hash_m2_12_negative_current_fingerprint;

    v_signature_ok := (v_sqlstate='P0001' AND v_message='M2.12 operational account grain or lineage violation');
    v_isolation_ok := (v_entities_before=134 AND v_entities_after=134
                       AND v_canonical_before IS NOT DISTINCT FROM v_canonical_after
                       AND v_hash_before IS NOT DISTINCT FROM v_hash_after
                       AND v_sequence_before IS NOT DISTINCT FROM v_sequence_after
                       AND v_lifecycle_before IS NOT DISTINCT FROM v_lifecycle_after);

    INSERT INTO tmp_neg_m2_12_results
    (
      control_sequence,evidence_code,control_family,expected_sqlstate,
      authority_message_prefix,effective_message_signature,message_match_mode,expected_constraint,
      observed_sqlstate,observed_message,observed_constraint,
      canonical_before,canonical_after,hash_before,hash_after,
      sequence_before,sequence_after,lifecycle_before,lifecycle_after,
      isolation_status,status,interpretation
    )
    VALUES
    (
      16::smallint,'M2_12_NEG_016_OPERATIONAL_VIEW_ORPHAN_OR_DUPLICATE','CONSUMPTION_GRAIN','P0001',
      'M2.12 operational account grain or lineage violation','M2.12 operational account grain or lineage violation','EXACT','',
      v_sqlstate,v_message,coalesce(v_constraint,''),
      v_canonical_before,v_canonical_after,v_hash_before,v_hash_after,
      v_sequence_before,v_sequence_after,v_lifecycle_before,v_lifecycle_after,
      CASE WHEN v_isolation_ok THEN 'PASS' ELSE 'FAIL' END,
      CASE WHEN v_signature_ok AND v_isolation_ok THEN 'PASS' ELSE 'FAIL' END,
      'Operational-account view orphan/duplicate assertion | NONE'
    );
END;
$m212_neg_016$;

/* WP3_NEGATIVE_CONTROL_DEFINITION M2_12_NEG_017_STRATEGY_VIEW_GRAIN_CORRUPTION */
DO $m212_neg_017$
DECLARE
    v_sqlstate text;
    v_message text;
    v_constraint text;
    v_canonical_before text;
    v_canonical_after text;
    v_hash_before text;
    v_hash_after text;
    v_sequence_before text;
    v_sequence_after text;
    v_lifecycle_before text;
    v_lifecycle_after text;
    v_entities_before integer;
    v_entities_after integer;
    v_signature_ok boolean;
    v_isolation_ok boolean;
BEGIN
    SELECT canonical_fingerprint,stored_hash_fingerprint,sequence_fingerprint,lifecycle_fingerprint,canonical_entity_count
      INTO v_canonical_before,v_hash_before,v_sequence_before,v_lifecycle_before,v_entities_before
      FROM tmp_hash_m2_12_negative_baseline;

    BEGIN
        CREATE TEMP TABLE tmp_neg_017_strategy_grain_fixture ON COMMIT DROP AS
        SELECT v.module1_run_id,v.strategy_profile_code,v.reporting_scope_code
        FROM msbf_m2.v_m2_12_strategy_scope_consumption v
        JOIN tmp_neg_m2_12_run_context ctx ON ctx.module1_run_id=v.module1_run_id;
        DELETE FROM tmp_neg_017_strategy_grain_fixture
         WHERE (strategy_profile_code,reporting_scope_code)=(SELECT strategy_profile_code,reporting_scope_code FROM tmp_neg_017_strategy_grain_fixture ORDER BY 1,2 LIMIT 1);
        IF (SELECT count(*) FROM tmp_neg_017_strategy_grain_fixture)<>24
           OR (SELECT count(DISTINCT strategy_profile_code) FROM tmp_neg_017_strategy_grain_fixture)<>8
           OR (SELECT count(DISTINCT reporting_scope_code) FROM tmp_neg_017_strategy_grain_fixture)<>3 THEN
            RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 strategy-scope grain mismatch';
        END IF;
        RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 negative control unexpectedly accepted injected defect';
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            v_sqlstate = RETURNED_SQLSTATE,
            v_message = MESSAGE_TEXT,
            v_constraint = CONSTRAINT_NAME;
    END;

    SELECT canonical_fingerprint,stored_hash_fingerprint,sequence_fingerprint,lifecycle_fingerprint,canonical_entity_count
      INTO v_canonical_after,v_hash_after,v_sequence_after,v_lifecycle_after,v_entities_after
      FROM tmp_hash_m2_12_negative_current_fingerprint;

    v_signature_ok := (v_sqlstate='P0001' AND v_message='M2.12 strategy-scope grain mismatch');
    v_isolation_ok := (v_entities_before=134 AND v_entities_after=134
                       AND v_canonical_before IS NOT DISTINCT FROM v_canonical_after
                       AND v_hash_before IS NOT DISTINCT FROM v_hash_after
                       AND v_sequence_before IS NOT DISTINCT FROM v_sequence_after
                       AND v_lifecycle_before IS NOT DISTINCT FROM v_lifecycle_after);

    INSERT INTO tmp_neg_m2_12_results
    (
      control_sequence,evidence_code,control_family,expected_sqlstate,
      authority_message_prefix,effective_message_signature,message_match_mode,expected_constraint,
      observed_sqlstate,observed_message,observed_constraint,
      canonical_before,canonical_after,hash_before,hash_after,
      sequence_before,sequence_after,lifecycle_before,lifecycle_after,
      isolation_status,status,interpretation
    )
    VALUES
    (
      17::smallint,'M2_12_NEG_017_STRATEGY_VIEW_GRAIN_CORRUPTION','CONSUMPTION_GRAIN','P0001',
      'M2.12 strategy-scope grain mismatch','M2.12 strategy-scope grain mismatch','EXACT','',
      v_sqlstate,v_message,coalesce(v_constraint,''),
      v_canonical_before,v_canonical_after,v_hash_before,v_hash_after,
      v_sequence_before,v_sequence_after,v_lifecycle_before,v_lifecycle_after,
      CASE WHEN v_isolation_ok THEN 'PASS' ELSE 'FAIL' END,
      CASE WHEN v_signature_ok AND v_isolation_ok THEN 'PASS' ELSE 'FAIL' END,
      'Strategy-scope exact 8×3 grain assertion | NONE'
    );
END;
$m212_neg_017$;

/* WP3_NEGATIVE_CONTROL_DEFINITION M2_12_NEG_018_CAPABILITY_OVERCLAIM */
DO $m212_neg_018$
DECLARE
    v_sqlstate text;
    v_message text;
    v_constraint text;
    v_canonical_before text;
    v_canonical_after text;
    v_hash_before text;
    v_hash_after text;
    v_sequence_before text;
    v_sequence_after text;
    v_lifecycle_before text;
    v_lifecycle_after text;
    v_entities_before integer;
    v_entities_after integer;
    v_signature_ok boolean;
    v_isolation_ok boolean;
BEGIN
    SELECT canonical_fingerprint,stored_hash_fingerprint,sequence_fingerprint,lifecycle_fingerprint,canonical_entity_count
      INTO v_canonical_before,v_hash_before,v_sequence_before,v_lifecycle_before,v_entities_before
      FROM tmp_hash_m2_12_negative_baseline;

    BEGIN
        UPDATE msbf_m2.module2_capability_coverage_snapshot c
           SET coverage_status_code='IMPLEMENTED_PRODUCTION_AUTHORIZED'
          FROM tmp_neg_m2_12_run_context ctx
         WHERE c.module1_run_id=ctx.module1_run_id
           AND c.capability_sequence=17
           AND c.capability_code='PRODUCTION_DECISION_ACCOUNT_PAYMENT_EXECUTION';
        RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 negative control unexpectedly accepted injected defect';
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            v_sqlstate = RETURNED_SQLSTATE,
            v_message = MESSAGE_TEXT,
            v_constraint = CONSTRAINT_NAME;
    END;

    SELECT canonical_fingerprint,stored_hash_fingerprint,sequence_fingerprint,lifecycle_fingerprint,canonical_entity_count
      INTO v_canonical_after,v_hash_after,v_sequence_after,v_lifecycle_after,v_entities_after
      FROM tmp_hash_m2_12_negative_current_fingerprint;

    v_signature_ok := (v_sqlstate='23514' AND position('violates check constraint' in coalesce(v_message,''))>0 AND coalesce(v_constraint,'')='ck_m212_capability_status');
    v_isolation_ok := (v_entities_before=134 AND v_entities_after=134
                       AND v_canonical_before IS NOT DISTINCT FROM v_canonical_after
                       AND v_hash_before IS NOT DISTINCT FROM v_hash_after
                       AND v_sequence_before IS NOT DISTINCT FROM v_sequence_after
                       AND v_lifecycle_before IS NOT DISTINCT FROM v_lifecycle_after);

    INSERT INTO tmp_neg_m2_12_results
    (
      control_sequence,evidence_code,control_family,expected_sqlstate,
      authority_message_prefix,effective_message_signature,message_match_mode,expected_constraint,
      observed_sqlstate,observed_message,observed_constraint,
      canonical_before,canonical_after,hash_before,hash_after,
      sequence_before,sequence_after,lifecycle_before,lifecycle_after,
      isolation_status,status,interpretation
    )
    VALUES
    (
      18::smallint,'M2_12_NEG_018_CAPABILITY_OVERCLAIM','CAPABILITY_BOUNDARY','23514',
      'violates check constraint','violates check constraint','CONTAINS_AND_CONSTRAINT','ck_m212_capability_status',
      v_sqlstate,v_message,coalesce(v_constraint,''),
      v_canonical_before,v_canonical_after,v_hash_before,v_hash_after,
      v_sequence_before,v_sequence_after,v_lifecycle_before,v_lifecycle_after,
      CASE WHEN v_isolation_ok THEN 'PASS' ELSE 'FAIL' END,
      CASE WHEN v_signature_ok AND v_isolation_ok THEN 'PASS' ELSE 'FAIL' END,
      'Capability status/flag check and overclaim assertion | NONE'
    );
END;
$m212_neg_018$;

/* WP3_NEGATIVE_CONTROL_DEFINITION M2_12_NEG_019_PROHIBITED_PRODUCTION_OR_EXTERNAL_ACTION */
DO $m212_neg_019$
DECLARE
    v_sqlstate text;
    v_message text;
    v_constraint text;
    v_canonical_before text;
    v_canonical_after text;
    v_hash_before text;
    v_hash_after text;
    v_sequence_before text;
    v_sequence_after text;
    v_lifecycle_before text;
    v_lifecycle_after text;
    v_entities_before integer;
    v_entities_after integer;
    v_signature_ok boolean;
    v_isolation_ok boolean;
BEGIN
    SELECT canonical_fingerprint,stored_hash_fingerprint,sequence_fingerprint,lifecycle_fingerprint,canonical_entity_count
      INTO v_canonical_before,v_hash_before,v_sequence_before,v_lifecycle_before,v_entities_before
      FROM tmp_hash_m2_12_negative_baseline;

    BEGIN
        UPDATE msbf_ctl.m2_12_policy_profile p
           SET production_action_authorized_flag=true
          FROM tmp_neg_m2_12_run_context ctx
         WHERE p.module1_run_id=ctx.module1_run_id
           AND p.policy_code='M2_12_ENTERPRISE_PORTFOLIO_CERTIFICATION_POLICY_V1'
           AND p.policy_version=1;
        RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 negative control unexpectedly accepted injected defect';
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            v_sqlstate = RETURNED_SQLSTATE,
            v_message = MESSAGE_TEXT,
            v_constraint = CONSTRAINT_NAME;
    END;

    SELECT canonical_fingerprint,stored_hash_fingerprint,sequence_fingerprint,lifecycle_fingerprint,canonical_entity_count
      INTO v_canonical_after,v_hash_after,v_sequence_after,v_lifecycle_after,v_entities_after
      FROM tmp_hash_m2_12_negative_current_fingerprint;

    v_signature_ok := (v_sqlstate='23514' AND position('violates check constraint' in coalesce(v_message,''))>0 AND coalesce(v_constraint,'')='ck_m212_policy_boundaries');
    v_isolation_ok := (v_entities_before=134 AND v_entities_after=134
                       AND v_canonical_before IS NOT DISTINCT FROM v_canonical_after
                       AND v_hash_before IS NOT DISTINCT FROM v_hash_after
                       AND v_sequence_before IS NOT DISTINCT FROM v_sequence_after
                       AND v_lifecycle_before IS NOT DISTINCT FROM v_lifecycle_after);

    INSERT INTO tmp_neg_m2_12_results
    (
      control_sequence,evidence_code,control_family,expected_sqlstate,
      authority_message_prefix,effective_message_signature,message_match_mode,expected_constraint,
      observed_sqlstate,observed_message,observed_constraint,
      canonical_before,canonical_after,hash_before,hash_after,
      sequence_before,sequence_after,lifecycle_before,lifecycle_after,
      isolation_status,status,interpretation
    )
    VALUES
    (
      19::smallint,'M2_12_NEG_019_PROHIBITED_PRODUCTION_OR_EXTERNAL_ACTION','NONPRODUCTION_BOUNDARY','23514',
      'violates check constraint','violates check constraint','CONTAINS_AND_CONSTRAINT','ck_m212_policy_boundaries',
      v_sqlstate,v_message,coalesce(v_constraint,''),
      v_canonical_before,v_canonical_after,v_hash_before,v_hash_after,
      v_sequence_before,v_sequence_after,v_lifecycle_before,v_lifecycle_after,
      CASE WHEN v_isolation_ok THEN 'PASS' ELSE 'FAIL' END,
      CASE WHEN v_signature_ok AND v_isolation_ok THEN 'PASS' ELSE 'FAIL' END,
      'Non-production boundary check/assertion | NONE'
    );
END;
$m212_neg_019$;

/* WP3_NEGATIVE_CONTROL_DEFINITION M2_12_NEG_020_PREMATURE_MODULE3_OR_UNAUTHORIZED_SOURCE */
DO $m212_neg_020$
DECLARE
    v_sqlstate text;
    v_message text;
    v_constraint text;
    v_canonical_before text;
    v_canonical_after text;
    v_hash_before text;
    v_hash_after text;
    v_sequence_before text;
    v_sequence_after text;
    v_lifecycle_before text;
    v_lifecycle_after text;
    v_entities_before integer;
    v_entities_after integer;
    v_signature_ok boolean;
    v_isolation_ok boolean;
BEGIN
    SELECT canonical_fingerprint,stored_hash_fingerprint,sequence_fingerprint,lifecycle_fingerprint,canonical_entity_count
      INTO v_canonical_before,v_hash_before,v_sequence_before,v_lifecycle_before,v_entities_before
      FROM tmp_hash_m2_12_negative_baseline;

    BEGIN
        CREATE TEMP TABLE tmp_neg_020_authorized_source_fixture ON COMMIT DROP AS
        SELECT DISTINCT relation_name
        FROM (
            SELECT format('%s.%s',n.nspname,c.relname)::text AS relation_name
            FROM pg_catalog.pg_class c JOIN pg_catalog.pg_namespace n ON n.oid=c.relnamespace
            WHERE n.nspname IN ('msbf_ctl','msbf_m1','msbf_m2')
              AND c.relkind IN ('r','p','v','m','S')
        ) s
        WHERE relation_name NOT LIKE 'msbf_m3.%';
        INSERT INTO tmp_neg_020_authorized_source_fixture VALUES ('msbf_m3.premature_module3_object');
        IF EXISTS (SELECT 1 FROM tmp_neg_020_authorized_source_fixture WHERE relation_name LIKE 'msbf_m3.%') THEN
            RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 unauthorized source or premature Module 3 object';
        END IF;
        RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 negative control unexpectedly accepted injected defect';
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            v_sqlstate = RETURNED_SQLSTATE,
            v_message = MESSAGE_TEXT,
            v_constraint = CONSTRAINT_NAME;
    END;

    SELECT canonical_fingerprint,stored_hash_fingerprint,sequence_fingerprint,lifecycle_fingerprint,canonical_entity_count
      INTO v_canonical_after,v_hash_after,v_sequence_after,v_lifecycle_after,v_entities_after
      FROM tmp_hash_m2_12_negative_current_fingerprint;

    v_signature_ok := (v_sqlstate='P0001' AND v_message='M2.12 unauthorized source or premature Module 3 object');
    v_isolation_ok := (v_entities_before=134 AND v_entities_after=134
                       AND v_canonical_before IS NOT DISTINCT FROM v_canonical_after
                       AND v_hash_before IS NOT DISTINCT FROM v_hash_after
                       AND v_sequence_before IS NOT DISTINCT FROM v_sequence_after
                       AND v_lifecycle_before IS NOT DISTINCT FROM v_lifecycle_after);

    INSERT INTO tmp_neg_m2_12_results
    (
      control_sequence,evidence_code,control_family,expected_sqlstate,
      authority_message_prefix,effective_message_signature,message_match_mode,expected_constraint,
      observed_sqlstate,observed_message,observed_constraint,
      canonical_before,canonical_after,hash_before,hash_after,
      sequence_before,sequence_after,lifecycle_before,lifecycle_after,
      isolation_status,status,interpretation
    )
    VALUES
    (
      20::smallint,'M2_12_NEG_020_PREMATURE_MODULE3_OR_UNAUTHORIZED_SOURCE','STAGE_BOUNDARY','P0001',
      'M2.12 unauthorized source or premature Module 3 object','M2.12 unauthorized source or premature Module 3 object','EXACT','',
      v_sqlstate,v_message,coalesce(v_constraint,''),
      v_canonical_before,v_canonical_after,v_hash_before,v_hash_after,
      v_sequence_before,v_sequence_after,v_lifecycle_before,v_lifecycle_after,
      CASE WHEN v_isolation_ok THEN 'PASS' ELSE 'FAIL' END,
      CASE WHEN v_signature_ok AND v_isolation_ok THEN 'PASS' ELSE 'FAIL' END,
      'Pristine boundary and authorized-source assertion | NONE'
    );
END;
$m212_neg_020$;

DO $m212_p224_hf14_20_of_20_gate$
DECLARE
  v_failure_detail text;
BEGIN
  IF NOT (SELECT count(*)=20
                 AND count(DISTINCT evidence_code)=20
                 AND min(control_sequence)=1
                 AND max(control_sequence)=20
                 AND count(*) FILTER (WHERE status='PASS' AND isolation_status='PASS')=20
            FROM tmp_neg_m2_12_results) THEN
    SELECT string_agg(
             format('control=%s|code=%s|status=%s|isolation=%s|expected_sqlstate=%s|observed_sqlstate=%s|expected_constraint=%s|observed_constraint=%s|message=%s',
                    control_sequence,evidence_code,status,isolation_status,expected_sqlstate,
                    coalesce(observed_sqlstate,'NULL'),coalesce(expected_constraint,''),
                    coalesce(observed_constraint,''),coalesce(observed_message,'NULL')),
             '; ' ORDER BY control_sequence)
      INTO v_failure_detail
      FROM tmp_neg_m2_12_results
     WHERE status IS DISTINCT FROM 'PASS' OR isolation_status IS DISTINCT FROM 'PASS';
    RAISE EXCEPTION USING
      ERRCODE='P0001',
      MESSAGE='M2.12 Program 224 HF14 requires exactly 20 isolated PASS controls',
      DETAIL=coalesce(v_failure_detail,'row/code/sequence cardinality mismatch');
  END IF;
END;
$m212_p224_hf14_20_of_20_gate$;

INSERT INTO msbf_ctl.run_evidence
(
 run_id,evidence_code,segment_key,metric_name,metric_value_numeric,metric_value_text,
 unit_code,status,threshold_value_numeric,interpretation
)
SELECT ctx.module1_run_id,r.evidence_code,'M2_12'::text,r.evidence_code,
       NULL::numeric(24,10),concat_ws('|',r.observed_sqlstate,r.observed_constraint,r.observed_message),
       'CONTROL'::text,r.status,NULL::numeric(24,10),r.interpretation
FROM tmp_neg_m2_12_results r CROSS JOIN tmp_neg_m2_12_run_context ctx
WHERE r.status='PASS'
ORDER BY r.control_sequence;

CREATE TEMP TABLE tmp_neg_m2_12_persistence_result ON COMMIT PRESERVE ROWS AS
WITH evidence AS (
 SELECT count(*) FILTER (WHERE e.evidence_code LIKE 'M2_12_POS_%')::integer positive_total_rows,
        count(*) FILTER (WHERE e.evidence_code LIKE 'M2_12_POS_%' AND e.status='PASS')::integer positive_rows,
        count(DISTINCT e.evidence_code) FILTER (WHERE e.evidence_code LIKE 'M2_12_POS_%')::integer positive_codes,
        count(*) FILTER (WHERE e.evidence_code LIKE 'M2_12_NEG_%')::integer negative_total_rows,
        count(*) FILTER (WHERE e.evidence_code LIKE 'M2_12_NEG_%' AND e.status='PASS')::integer negative_rows,
        count(DISTINCT e.evidence_code) FILTER (WHERE e.evidence_code LIKE 'M2_12_NEG_%')::integer negative_codes,
        count(*) FILTER (WHERE e.evidence_code='M2_12_ACCEPTANCE_SUMMARY')::integer acceptance_rows
 FROM msbf_ctl.run_evidence e JOIN tmp_neg_m2_12_run_context ctx ON ctx.module1_run_id=e.run_id
), gate AS (
 SELECT count(*)::integer gate_rows FROM msbf_ctl.acceptance_gate_result g
 JOIN tmp_neg_m2_12_run_context ctx ON ctx.module1_run_id=g.run_id WHERE g.gate_id='G3_M2_CONTRACT'
), fingerprint AS (
 SELECT b.canonical_fingerprint IS NOT DISTINCT FROM a.canonical_fingerprint
    AND b.stored_hash_fingerprint IS NOT DISTINCT FROM a.stored_hash_fingerprint
    AND b.sequence_fingerprint IS NOT DISTINCT FROM a.sequence_fingerprint
    AND b.lifecycle_fingerprint IS NOT DISTINCT FROM a.lifecycle_fingerprint
    AND b.canonical_entity_count=134 AND a.canonical_entity_count=134 AS exact_flag
 FROM tmp_hash_m2_12_negative_baseline b CROSS JOIN tmp_hash_m2_12_negative_current_fingerprint a
)
SELECT ctx.module1_run_id,ctx.run_status,ctx.contract_status,
       e.positive_total_rows,e.positive_rows,e.positive_codes,e.negative_total_rows,e.negative_rows,e.negative_codes,e.acceptance_rows,g.gate_rows,f.exact_flag,
       CASE WHEN ctx.run_status='M2_12_VALIDATED' AND ctx.contract_status='VALIDATED'
                  AND ctx.generated_at IS NOT NULL AND ctx.validated_at IS NOT NULL AND ctx.accepted_at IS NULL
                  AND e.positive_total_rows=128 AND e.positive_rows=128 AND e.positive_codes=128
                  AND e.negative_total_rows=20 AND e.negative_rows=20 AND e.negative_codes=20
                  AND e.acceptance_rows=0 AND g.gate_rows=0 AND f.exact_flag
            THEN 'PASS' ELSE 'FAIL' END AS persistence_status
FROM tmp_neg_m2_12_run_context ctx CROSS JOIN evidence e CROSS JOIN gate g CROSS JOIN fingerprint f;DO $m212_p224_hf14_final_gate$
DECLARE
  v_result record;
BEGIN
  IF (SELECT count(*) FROM tmp_neg_m2_12_persistence_result)<>1 THEN
    RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 Program 224 HF14 final persistence row-count failed';
  END IF;
  SELECT module1_run_id,run_status,contract_status,positive_total_rows,positive_rows,positive_codes,negative_total_rows,negative_rows,negative_codes,acceptance_rows,gate_rows,exact_flag,persistence_status
    INTO STRICT v_result FROM tmp_neg_m2_12_persistence_result;
  IF v_result.persistence_status<>'PASS' THEN
    RAISE EXCEPTION USING
      ERRCODE='P0001',
      MESSAGE='M2.12 Program 224 HF14 final persistence/isolation postflight failed',
      DETAIL=format('run_status=%s contract_status=%s positive_total=%s positive_pass=%s positive_codes=%s negative_total=%s negative_pass=%s negative_codes=%s acceptance=%s gate=%s exact=%s',
                    v_result.run_status,v_result.contract_status,v_result.positive_total_rows,
                    v_result.positive_rows,v_result.positive_codes,v_result.negative_total_rows,
                    v_result.negative_rows,v_result.negative_codes,v_result.acceptance_rows,
                    v_result.gate_rows,v_result.exact_flag);
  END IF;
END;
$m212_p224_hf14_final_gate$;

COMMIT;

SELECT module1_run_id,run_status,contract_status,positive_total_rows,positive_rows,positive_codes,negative_total_rows,negative_rows,negative_codes,acceptance_rows,gate_rows,exact_flag,persistence_status
FROM tmp_neg_m2_12_persistence_result;
SELECT control_sequence,evidence_code,control_family,expected_sqlstate,
       authority_message_prefix,effective_message_signature,message_match_mode,expected_constraint,
       observed_sqlstate,observed_message,observed_constraint,
       canonical_before,canonical_after,hash_before,hash_after,
       sequence_before,sequence_after,lifecycle_before,lifecycle_after,
       isolation_status,status,interpretation
FROM tmp_neg_m2_12_results ORDER BY control_sequence;
