/* M2.12 Program 226 HF24 — accepted checkpoint verifier (persistent-state read-only). */
BEGIN;
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SET LOCAL search_path = pg_catalog, msbf_ctl, msbf_m1, msbf_m2;
SET LOCAL work_mem='256MB';
SET LOCAL lock_timeout='15s';
SET LOCAL statement_timeout='75min';
SET LOCAL idle_in_transaction_session_timeout='0';
SET LOCAL jit=off;

/* HF24 accepted context — exact lifecycle, gate, evidence, counts, boundaries, and predecessor hash identity. */
CREATE TEMP TABLE tmp_v226_context ON COMMIT DROP AS
WITH gate AS (
    SELECT g.run_id,
           count(*)::integer AS gate_rows,
           count(*) FILTER (WHERE g.result_status='PASS'
                              AND g.observed_value='48/48 acceptance requirements; 128/128 positive; 20/20 negative; immutable fingerprint exact'
                              AND g.threshold_value='48/48 PASS'
                              AND g.finding='M2.12 as-built synthetic enterprise portfolio certification and G3 consumption contract accepted.'
                              AND g.residual_limitation='No production, deployment, legal/regulatory certification, causal optimization, champion, external action, or Module 3 authority.'
                              AND g.reviewer_role='M2_12_GOVERNED_ACCEPTANCE_FINALIZER')::integer AS exact_gate_rows,
           min(g.result_status)::text AS gate_status
      FROM msbf_ctl.acceptance_gate_result g
     WHERE g.gate_id='G3_M2_CONTRACT' AND g.review_version=1
     GROUP BY g.run_id
), acceptance AS (
    SELECT e.run_id,
           count(*)::integer AS acceptance_rows,
           count(*) FILTER (WHERE e.segment_key='ENTERPRISE_PORTFOLIO_G3'
                              AND e.metric_name='G3_ACCEPTANCE_STATUS'
                              AND e.metric_value_numeric IS NULL
                              AND e.metric_value_text='M2_12_ACCEPTED|ACCEPTED|PASS|48/48'
                              AND e.unit_code='ACCEPTANCE'
                              AND e.status='PASS'
                              AND e.interpretation='As-built synthetic certification and governed consumption acceptance only; no deployment, production, legal/regulatory, causal, champion, external-action, or Module 3 authority.')::integer AS exact_acceptance_rows,
           min(e.status)::text AS acceptance_evidence_status
      FROM msbf_ctl.run_evidence e
     WHERE e.evidence_code='M2_12_ACCEPTANCE_SUMMARY'
     GROUP BY e.run_id
)
SELECT rr.run_id::bigint AS governed_run_id,
       rr.run_id::bigint AS module1_run_id,
       rr.run_code::text AS run_code,
       rr.run_version::integer AS run_version,
       rr.run_status::text AS run_status,
       rr.as_of_date::date AS as_of_date,
       r.registry_id::bigint AS registry_id,
       r.bundle_code::text AS bundle_code,
       r.contract_version::integer AS contract_version,
       r.schema_version::text AS schema_version,
       r.methodology_version::text AS methodology_version,
       r.acceptance_gate_id::text AS acceptance_gate_id,
       r.accepted_m2_11_project_sha256::text AS accepted_m2_11_project_sha256,
       r.accepted_m2_11_contract_set_hash::text AS accepted_m2_11_contract_set_hash,
       r.accepted_m2_11_combined_set_hash::text AS accepted_m2_11_combined_set_hash,
       r.accepted_m2_11_registry_row_hash::text AS accepted_m2_11_registry_row_hash,
       r.source_node_count::integer AS source_node_count,
       r.component_contract_count::integer AS component_contract_count,
       r.source_graph_edge_count::integer AS source_graph_edge_count,
       r.evidence_certification_count::integer AS evidence_certification_count,
       r.contract_reproduction_count::integer AS contract_reproduction_count,
       r.capability_coverage_count::integer AS capability_coverage_count,
       r.canonical_family_count::integer AS canonical_family_count,
       r.canonical_entity_count::integer AS canonical_entity_count,
       r.application_consumption_rows::bigint AS application_consumption_rows,
       r.operational_account_consumption_rows::integer AS operational_account_consumption_rows,
       r.strategy_scope_consumption_rows::integer AS strategy_scope_consumption_rows,
       r.component_latest_rows_total::bigint AS component_latest_rows_total,
       r.component_archive_rows_total::bigint AS component_archive_rows_total,
       r.stage_local_canonical_reference_total::bigint AS stage_local_canonical_reference_total,
       r.all_stage_certification_pass_flag::boolean AS all_stage_certification_pass_flag,
       r.all_component_contract_pass_flag::boolean AS all_component_contract_pass_flag,
       r.all_evidence_certification_pass_flag::boolean AS all_evidence_certification_pass_flag,
       r.all_contract_reproduction_pass_flag::boolean AS all_contract_reproduction_pass_flag,
       r.all_capability_boundary_pass_flag::boolean AS all_capability_boundary_pass_flag,
       r.all_source_graph_edges_pass_flag::boolean AS all_source_graph_edges_pass_flag,
       r.as_built_certification_scope_code::text AS as_built_certification_scope_code,
       r.residual_limitation_payload::jsonb AS residual_limitation_payload,
       r.deferred_capability_payload::jsonb AS deferred_capability_payload,
       r.synthetic_data_only_flag::boolean AS synthetic_data_only_flag,
       r.no_pii_flag::boolean AS no_pii_flag,
       r.certification_only_flag::boolean AS certification_only_flag,
       r.production_action_authorized_flag::boolean AS production_action_authorized_flag,
       r.external_system_update_authorized_flag::boolean AS external_system_update_authorized_flag,
       r.legal_or_regulatory_certified_flag::boolean AS legal_or_regulatory_certified_flag,
       r.empirical_or_causal_optimization_authorized_flag::boolean AS empirical_or_causal_optimization_authorized_flag,
       r.deployment_authorized_flag::boolean AS deployment_authorized_flag,
       r.module3_execution_authorized_flag::boolean AS module3_execution_authorized_flag,
       r.policy_set_hash::text AS policy_set_hash,
       r.stage_certification_set_hash::text AS stage_certification_set_hash,
       r.contract_component_set_hash::text AS contract_component_set_hash,
       r.evidence_certification_set_hash::text AS evidence_certification_set_hash,
       r.contract_reproduction_set_hash::text AS contract_reproduction_set_hash,
       r.capability_coverage_set_hash::text AS capability_coverage_set_hash,
       r.latest_set_hash::text AS latest_set_hash,
       r.archive_set_hash::text AS archive_set_hash,
       r.registry_set_hash::text AS registry_set_hash,
       r.latest_contract_row_hash::text AS latest_contract_row_hash,
       r.archive_contract_row_hash::text AS archive_contract_row_hash,
       r.contract_set_hash::text AS contract_set_hash,
       r.combined_set_hash::text AS combined_set_hash,
       r.contract_status::text AS contract_status,
       r.generated_at::timestamptz AS generated_at,
       r.validated_at::timestamptz AS validated_at,
       r.accepted_at::timestamptz AS accepted_at,
       r.row_hash::text AS row_hash,
       l.capability_summary::jsonb AS capability_summary,
       g.gate_rows,g.exact_gate_rows,g.gate_status,
       a.acceptance_rows,a.exact_acceptance_rows,a.acceptance_evidence_status
  FROM msbf_ctl.run_registry rr
  JOIN msbf_ctl.m2_12_g3_bundle_registry r
    ON r.module1_run_id=rr.run_id
   AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE'
   AND r.contract_version=1
  JOIN msbf_ctl.m2_12_g3_bundle_latest l
    ON l.module1_run_id=r.module1_run_id
   AND l.bundle_code=r.bundle_code
   AND l.contract_version=r.contract_version
  JOIN gate g ON g.run_id=rr.run_id
  JOIN acceptance a ON a.run_id=rr.run_id
 WHERE rr.run_code='M1_V0_2_BASELINE_BUILD'
   AND rr.run_version=1
   AND rr.run_status='M2_12_ACCEPTED'
   AND r.contract_status='ACCEPTED'
   AND r.generated_at IS NOT NULL
   AND r.validated_at IS NOT NULL
   AND r.accepted_at IS NOT NULL
   AND g.gate_rows=1 AND g.exact_gate_rows=1
   AND a.acceptance_rows=1 AND a.exact_acceptance_rows=1
   AND r.source_node_count=12
   AND r.component_contract_count=13
   AND r.source_graph_edge_count=19
   AND r.evidence_certification_count=72
   AND r.contract_reproduction_count=13
   AND r.capability_coverage_count=20
   AND r.canonical_family_count=9
   AND r.canonical_entity_count=134
   AND r.application_consumption_rows=1500
   AND r.operational_account_consumption_rows=59
   AND r.strategy_scope_consumption_rows=24
   AND r.component_latest_rows_total=7129
   AND r.component_archive_rows_total=7129
   AND r.stage_local_canonical_reference_total=70821
   AND r.all_stage_certification_pass_flag
   AND r.all_component_contract_pass_flag
   AND r.all_evidence_certification_pass_flag
   AND r.all_contract_reproduction_pass_flag
   AND r.all_capability_boundary_pass_flag
   AND r.all_source_graph_edges_pass_flag
   AND r.as_built_certification_scope_code='SYNTHETIC_AS_BUILT_MODULE2_G3'
   AND r.synthetic_data_only_flag
   AND r.no_pii_flag
   AND r.certification_only_flag
   AND NOT r.production_action_authorized_flag
   AND NOT r.external_system_update_authorized_flag
   AND NOT r.legal_or_regulatory_certified_flag
   AND NOT r.empirical_or_causal_optimization_authorized_flag
   AND NOT r.deployment_authorized_flag
   AND NOT r.module3_execution_authorized_flag
   AND r.contract_set_hash='38e76e3e05f19064f2f1de41b7c33d52'
   AND r.combined_set_hash='28d832719a63d5669a18016f15ba43fb'
   AND r.row_hash='16268274b151eeab60f4423ec094f4b5';
CREATE UNIQUE INDEX ux_tmp_v226_context ON tmp_v226_context(module1_run_id);
ANALYZE tmp_v226_context;

DO $m212_v226_hf24_context_gate$
DECLARE v_rows integer;
BEGIN
    SELECT count(*) INTO v_rows FROM tmp_v226_context;
    IF v_rows<>1 THEN
        RAISE EXCEPTION USING ERRCODE='P0001',
          MESSAGE='Program 226 HF24 verifier requires exactly one accepted M2.12 G3 context',
          DETAIL='observed='||v_rows::text;
    END IF;
END;
$m212_v226_hf24_context_gate$;
CREATE TEMP TABLE tmp_v226_source_edges ON COMMIT DROP AS
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
FROM tmp_v226_context ctx
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
FROM tmp_v226_context ctx
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
FROM tmp_v226_context ctx
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
FROM tmp_v226_context ctx
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
FROM tmp_v226_context ctx
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
FROM tmp_v226_context ctx
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
FROM tmp_v226_context ctx
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
FROM tmp_v226_context ctx
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
FROM tmp_v226_context ctx
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
FROM tmp_v226_context ctx
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
FROM tmp_v226_context ctx
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
FROM tmp_v226_context ctx
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
FROM tmp_v226_context ctx
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
FROM tmp_v226_context ctx
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
FROM tmp_v226_context ctx
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
FROM tmp_v226_context ctx
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
FROM tmp_v226_context ctx
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
FROM tmp_v226_context ctx
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
FROM tmp_v226_context ctx
) x);
CREATE UNIQUE INDEX ux_tmp_v226_source_edges ON tmp_v226_source_edges(edge_sequence,edge_code);
ANALYZE tmp_v226_source_edges;

DO $m212_v226_hf24_source_graph_precheck$
DECLARE
    v_edge_detail text;
BEGIN
    IF NOT ((SELECT count(*)=19
                    AND count(*) FILTER (WHERE edge_status='PASS')=19
                    AND count(DISTINCT edge_sequence)=19
                    AND count(DISTINCT edge_code)=19
               FROM tmp_v226_source_edges)) THEN
        SELECT string_agg(
                   format('edge=%s|code=%s|status=%s|source_rows=%s|target_rows=%s|gate=%s|expected=%s|source=%s|target=%s',
                          edge_sequence,edge_code,edge_status,source_registry_row_count,target_registry_row_count,
                          source_gate_status,expected_source_hash,observed_accepted_source_hash,
                          observed_target_recorded_source_hash),
                   '; ' ORDER BY edge_sequence)
          INTO v_edge_detail
          FROM tmp_v226_source_edges
         WHERE edge_status IS DISTINCT FROM 'PASS';
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 225 HF23 verifier pre-execution source-graph verification failed',
            DETAIL=coalesce(v_edge_detail,
                            'rows='||(SELECT count(*) FROM tmp_v226_source_edges)::text||
                            '|pass_rows='||(SELECT count(*) FILTER (WHERE edge_status='PASS') FROM tmp_v226_source_edges)::text||
                            '|distinct_sequences='||(SELECT count(DISTINCT edge_sequence) FROM tmp_v226_source_edges)::text||
                            '|distinct_codes='||(SELECT count(DISTINCT edge_code) FROM tmp_v226_source_edges)::text),
            HINT='Stop. Preserve the transcript and do not execute Program 222 HF9.';
    END IF;
END;
$m212_v226_hf24_source_graph_precheck$;

/***************************************************************************************************
HF23 COMPLETE PHYSICAL STAGE-BOUNDARY RECONSTRUCTION
- 66 controls from msbf_ctl.run_evidence
- 3 M1.17 controls from msbf_ctl.m1_17_end_to_end_evidence_snapshot
- M2_3_POLICY_BOUNDARY from the accepted reason definition plus complete latest/archive marker coverage
***************************************************************************************************/
CREATE TEMP TABLE tmp_v226_stage_boundary_method ON COMMIT DROP AS
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
CROSS JOIN tmp_v226_context ctx;

CREATE TEMP TABLE tmp_v226_stage_boundary_base ON COMMIT DROP AS
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
    FROM tmp_v226_stage_boundary_method sbm
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
    FROM tmp_v226_stage_boundary_method sbm
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
    FROM tmp_v226_stage_boundary_method sbm
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
    FROM tmp_v226_stage_boundary_method sbm
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
    FROM tmp_v226_stage_boundary_method sbm
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
    FROM tmp_v226_stage_boundary_method sbm
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
    FROM tmp_v226_stage_boundary_method sbm
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
FROM tmp_v226_context ctx
JOIN tmp_v226_stage_boundary_method sbm
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

DO $m212_v226_hf24_stage_boundary_base_assert$
BEGIN
    IF NOT coalesce(
        (SELECT count(*)=12
             AND count(DISTINCT (module1_run_id,matrix_sequence))=12
             AND count(DISTINCT node_sequence)=12
             AND min(node_sequence)=1
             AND max(node_sequence)=12
             AND sum(required_evidence_rows)=70
         FROM tmp_v226_stage_boundary_base),false)
    THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 226 HF24 stage-boundary observation-base structural mismatch',
            DETAIL=format('rows=%s distinct_matrix=%s distinct_nodes=%s required_controls=%s',
                          (SELECT count(*) FROM tmp_v226_stage_boundary_base),
                          (SELECT count(DISTINCT (module1_run_id,matrix_sequence)) FROM tmp_v226_stage_boundary_base),
                          (SELECT count(DISTINCT node_sequence) FROM tmp_v226_stage_boundary_base),
                          (SELECT coalesce(sum(required_evidence_rows),0) FROM tmp_v226_stage_boundary_base));
    END IF;
END;
$m212_v226_hf24_stage_boundary_base_assert$;

CREATE TEMP TABLE tmp_v226_stage_boundary ON COMMIT DROP AS
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
FROM tmp_v226_context ctx
JOIN tmp_v226_stage_boundary_base sbb
  ON sbb.module1_run_id=ctx.module1_run_id;

DO $m212_v226_hf24_stage_boundary_assert$
BEGIN
    IF NOT coalesce(
        (SELECT count(*)=12
             AND count(DISTINCT (module1_run_id,matrix_sequence))=12
             AND count(DISTINCT node_sequence)=12
             AND min(node_sequence)=1
             AND max(node_sequence)=12
             AND bool_and(certification_status='PASS')
         FROM tmp_v226_stage_boundary),false)
    THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 226 HF24 stage-boundary certification mismatch',
            DETAIL=coalesce(
                (SELECT string_agg(
                    'node='||node_sequence::text||':'||stage_code||
                    '|status='||coalesce(certification_status,'<NULL>')||
                    '|acceptance='||acceptance_summary_pass_rows::text||'/'||acceptance_summary_rows::text||
                    '|required='||required_evidence_rows::text||
                    '|physical='||physical_required_evidence_rows::text||
                    '|distinct='||observed_required_evidence_rows::text||
                    '|duplicates='||duplicate_required_evidence_rows::text||
                    '|missing='||coalesce(nullif(missing_required_evidence_codes,''),'<NONE>')||
                    '|nonpass='||coalesce(nullif(nonpass_evidence_codes,''),'<NONE>')||
                    '|violations='||coalesce(nullif(violation_evidence_codes,''),'<NONE>')||
                    '|sources='||coalesce(nullif(source_relation_set,''),'<NONE>'),
                    '; ' ORDER BY node_sequence)
                 FROM tmp_v226_stage_boundary
                 WHERE certification_status IS DISTINCT FROM 'PASS'),
                'rows='||(SELECT count(*) FROM tmp_v226_stage_boundary)::text);
    END IF;
END;
$m212_v226_hf24_stage_boundary_assert$;

CREATE TEMP TABLE tmp_v226_reconciliation ON COMMIT DROP AS
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
WITH row_detail AS ((SELECT 'POLICY'::text AS family_code, 1::bigint AS expected_rows, count(*)::bigint AS observed_rows, (count(*)<>1)::integer AS family_count_mismatch_count, count(*) FILTER (WHERE t.row_hash IS DISTINCT FROM md5((to_jsonb(t)-'policy_profile_id'-'row_hash'-'created_at'-'updated_at')::text))::bigint AS row_hash_mismatch_count FROM msbf_ctl.m2_12_policy_profile t JOIN tmp_v226_context ctx ON ctx.module1_run_id=t.module1_run_id) UNION ALL (SELECT 'STAGE_CERTIFICATION'::text AS family_code, 12::bigint AS expected_rows, count(*)::bigint AS observed_rows, (count(*)<>12)::integer AS family_count_mismatch_count, count(*) FILTER (WHERE t.row_hash IS DISTINCT FROM md5((to_jsonb(t)-'row_hash'-'created_at')::text))::bigint AS row_hash_mismatch_count FROM msbf_m2.module2_stage_certification_snapshot t JOIN tmp_v226_context ctx ON ctx.module1_run_id=t.module1_run_id) UNION ALL (SELECT 'CONTRACT_COMPONENT'::text AS family_code, 13::bigint AS expected_rows, count(*)::bigint AS observed_rows, (count(*)<>13)::integer AS family_count_mismatch_count, count(*) FILTER (WHERE t.row_hash IS DISTINCT FROM md5((to_jsonb(t)-'row_hash'-'created_at')::text))::bigint AS row_hash_mismatch_count FROM msbf_m2.module2_contract_component_snapshot t JOIN tmp_v226_context ctx ON ctx.module1_run_id=t.module1_run_id) UNION ALL (SELECT 'EVIDENCE_CERTIFICATION'::text AS family_code, 72::bigint AS expected_rows, count(*)::bigint AS observed_rows, (count(*)<>72)::integer AS family_count_mismatch_count, count(*) FILTER (WHERE t.row_hash IS DISTINCT FROM md5((to_jsonb(t)-'row_hash'-'created_at')::text))::bigint AS row_hash_mismatch_count FROM msbf_m2.module2_evidence_certification_snapshot t JOIN tmp_v226_context ctx ON ctx.module1_run_id=t.module1_run_id) UNION ALL (SELECT 'CONTRACT_REPRODUCTION'::text AS family_code, 13::bigint AS expected_rows, count(*)::bigint AS observed_rows, (count(*)<>13)::integer AS family_count_mismatch_count, count(*) FILTER (WHERE t.row_hash IS DISTINCT FROM md5((to_jsonb(t)-'row_hash'-'created_at')::text))::bigint AS row_hash_mismatch_count FROM msbf_m2.module2_contract_reproduction_snapshot t JOIN tmp_v226_context ctx ON ctx.module1_run_id=t.module1_run_id) UNION ALL (SELECT 'CAPABILITY_COVERAGE'::text AS family_code, 20::bigint AS expected_rows, count(*)::bigint AS observed_rows, (count(*)<>20)::integer AS family_count_mismatch_count, count(*) FILTER (WHERE t.row_hash IS DISTINCT FROM md5((to_jsonb(t)-'row_hash'-'created_at')::text))::bigint AS row_hash_mismatch_count FROM msbf_m2.module2_capability_coverage_snapshot t JOIN tmp_v226_context ctx ON ctx.module1_run_id=t.module1_run_id) UNION ALL (SELECT 'LATEST'::text AS family_code, 1::bigint AS expected_rows, count(*)::bigint AS observed_rows, (count(*)<>1)::integer AS family_count_mismatch_count, count(*) FILTER (WHERE t.row_hash IS DISTINCT FROM md5((to_jsonb(t)-'row_hash'-'created_at')::text))::bigint AS row_hash_mismatch_count FROM msbf_ctl.m2_12_g3_bundle_latest t JOIN tmp_v226_context ctx ON ctx.module1_run_id=t.module1_run_id) UNION ALL (SELECT 'ARCHIVE'::text AS family_code, 1::bigint AS expected_rows, count(*)::bigint AS observed_rows, (count(*)<>1)::integer AS family_count_mismatch_count, count(*) FILTER (WHERE t.archive_row_hash IS DISTINCT FROM md5((to_jsonb(t)-'archive_id'-'archive_row_hash'-'created_at')::text))::bigint AS row_hash_mismatch_count FROM msbf_ctl.m2_12_g3_bundle_archive t JOIN tmp_v226_context ctx ON ctx.module1_run_id=t.module1_run_id) UNION ALL (SELECT 'REGISTRY'::text AS family_code, 1::bigint AS expected_rows, count(*)::bigint AS observed_rows, (count(*)<>1)::integer AS family_count_mismatch_count, count(*) FILTER (WHERE t.row_hash IS DISTINCT FROM md5((to_jsonb(t)-'registry_id'-'contract_status'-'generated_at'-'validated_at'-'accepted_at'-'created_at'-'updated_at'-'row_hash'-'policy_set_hash'-'stage_certification_set_hash'-'contract_component_set_hash'-'evidence_certification_set_hash'-'contract_reproduction_set_hash'-'capability_coverage_set_hash'-'latest_set_hash'-'archive_set_hash'-'registry_set_hash'-'contract_set_hash'-'combined_set_hash')::text))::bigint AS row_hash_mismatch_count FROM msbf_ctl.m2_12_g3_bundle_registry t JOIN tmp_v226_context ctx ON ctx.module1_run_id=t.module1_run_id)),
rowd AS (SELECT sum(family_count_mismatch_count)::bigint family_count_mismatch_count,sum(row_hash_mismatch_count)::bigint row_hash_mismatch_count FROM row_detail),
set_detail AS ((SELECT 'POLICY'::text AS family_code, md5(string_agg(concat_ws('|',t.policy_code::text,t.policy_version::text,t.row_hash::text),'|' ORDER BY t.policy_code, t.policy_version))::text AS reconstructed_set_hash, r.policy_set_hash::text AS stored_set_hash, (md5(string_agg(concat_ws('|',t.policy_code::text,t.policy_version::text,t.row_hash::text),'|' ORDER BY t.policy_code, t.policy_version)) IS DISTINCT FROM r.policy_set_hash)::integer AS set_hash_mismatch_count FROM msbf_ctl.m2_12_policy_profile t JOIN tmp_v226_context ctx ON ctx.module1_run_id=t.module1_run_id JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1 GROUP BY r.policy_set_hash) UNION ALL (SELECT 'STAGE_CERTIFICATION'::text AS family_code, md5(string_agg(concat_ws('|',t.certification_node_sequence::text,t.stage_code::text,t.row_hash::text),'|' ORDER BY t.certification_node_sequence, t.stage_code))::text AS reconstructed_set_hash, r.stage_certification_set_hash::text AS stored_set_hash, (md5(string_agg(concat_ws('|',t.certification_node_sequence::text,t.stage_code::text,t.row_hash::text),'|' ORDER BY t.certification_node_sequence, t.stage_code)) IS DISTINCT FROM r.stage_certification_set_hash)::integer AS set_hash_mismatch_count FROM msbf_m2.module2_stage_certification_snapshot t JOIN tmp_v226_context ctx ON ctx.module1_run_id=t.module1_run_id JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1 GROUP BY r.stage_certification_set_hash) UNION ALL (SELECT 'CONTRACT_COMPONENT'::text AS family_code, md5(string_agg(concat_ws('|',t.component_sequence::text,t.component_contract_code::text,t.contract_version::text,t.row_hash::text),'|' ORDER BY t.component_sequence, t.component_contract_code, t.contract_version))::text AS reconstructed_set_hash, r.contract_component_set_hash::text AS stored_set_hash, (md5(string_agg(concat_ws('|',t.component_sequence::text,t.component_contract_code::text,t.contract_version::text,t.row_hash::text),'|' ORDER BY t.component_sequence, t.component_contract_code, t.contract_version)) IS DISTINCT FROM r.contract_component_set_hash)::integer AS set_hash_mismatch_count FROM msbf_m2.module2_contract_component_snapshot t JOIN tmp_v226_context ctx ON ctx.module1_run_id=t.module1_run_id JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1 GROUP BY r.contract_component_set_hash) UNION ALL (SELECT 'EVIDENCE_CERTIFICATION'::text AS family_code, md5(string_agg(concat_ws('|',t.node_sequence::text,t.evidence_family_sequence::text,t.row_hash::text),'|' ORDER BY t.node_sequence, t.evidence_family_sequence))::text AS reconstructed_set_hash, r.evidence_certification_set_hash::text AS stored_set_hash, (md5(string_agg(concat_ws('|',t.node_sequence::text,t.evidence_family_sequence::text,t.row_hash::text),'|' ORDER BY t.node_sequence, t.evidence_family_sequence)) IS DISTINCT FROM r.evidence_certification_set_hash)::integer AS set_hash_mismatch_count FROM msbf_m2.module2_evidence_certification_snapshot t JOIN tmp_v226_context ctx ON ctx.module1_run_id=t.module1_run_id JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1 GROUP BY r.evidence_certification_set_hash) UNION ALL (SELECT 'CONTRACT_REPRODUCTION'::text AS family_code, md5(string_agg(concat_ws('|',t.component_sequence::text,t.component_contract_code::text,t.contract_version::text,t.row_hash::text),'|' ORDER BY t.component_sequence, t.component_contract_code, t.contract_version))::text AS reconstructed_set_hash, r.contract_reproduction_set_hash::text AS stored_set_hash, (md5(string_agg(concat_ws('|',t.component_sequence::text,t.component_contract_code::text,t.contract_version::text,t.row_hash::text),'|' ORDER BY t.component_sequence, t.component_contract_code, t.contract_version)) IS DISTINCT FROM r.contract_reproduction_set_hash)::integer AS set_hash_mismatch_count FROM msbf_m2.module2_contract_reproduction_snapshot t JOIN tmp_v226_context ctx ON ctx.module1_run_id=t.module1_run_id JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1 GROUP BY r.contract_reproduction_set_hash) UNION ALL (SELECT 'CAPABILITY_COVERAGE'::text AS family_code, md5(string_agg(concat_ws('|',t.capability_sequence::text,t.capability_code::text,t.row_hash::text),'|' ORDER BY t.capability_sequence, t.capability_code))::text AS reconstructed_set_hash, r.capability_coverage_set_hash::text AS stored_set_hash, (md5(string_agg(concat_ws('|',t.capability_sequence::text,t.capability_code::text,t.row_hash::text),'|' ORDER BY t.capability_sequence, t.capability_code)) IS DISTINCT FROM r.capability_coverage_set_hash)::integer AS set_hash_mismatch_count FROM msbf_m2.module2_capability_coverage_snapshot t JOIN tmp_v226_context ctx ON ctx.module1_run_id=t.module1_run_id JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1 GROUP BY r.capability_coverage_set_hash) UNION ALL (SELECT 'LATEST'::text AS family_code, md5(string_agg(concat_ws('|',t.bundle_code::text,t.contract_version::text,t.row_hash::text),'|' ORDER BY t.bundle_code, t.contract_version))::text AS reconstructed_set_hash, r.latest_set_hash::text AS stored_set_hash, (md5(string_agg(concat_ws('|',t.bundle_code::text,t.contract_version::text,t.row_hash::text),'|' ORDER BY t.bundle_code, t.contract_version)) IS DISTINCT FROM r.latest_set_hash)::integer AS set_hash_mismatch_count FROM msbf_ctl.m2_12_g3_bundle_latest t JOIN tmp_v226_context ctx ON ctx.module1_run_id=t.module1_run_id JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1 GROUP BY r.latest_set_hash) UNION ALL (SELECT 'ARCHIVE'::text AS family_code, md5(string_agg(concat_ws('|',t.bundle_code::text,t.contract_version::text,t.archive_row_hash::text),'|' ORDER BY t.bundle_code, t.contract_version))::text AS reconstructed_set_hash, r.archive_set_hash::text AS stored_set_hash, (md5(string_agg(concat_ws('|',t.bundle_code::text,t.contract_version::text,t.archive_row_hash::text),'|' ORDER BY t.bundle_code, t.contract_version)) IS DISTINCT FROM r.archive_set_hash)::integer AS set_hash_mismatch_count FROM msbf_ctl.m2_12_g3_bundle_archive t JOIN tmp_v226_context ctx ON ctx.module1_run_id=t.module1_run_id JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1 GROUP BY r.archive_set_hash) UNION ALL (SELECT 'REGISTRY'::text AS family_code, md5(string_agg(concat_ws('|',t.bundle_code::text,t.contract_version::text,t.row_hash::text),'|' ORDER BY t.bundle_code, t.contract_version))::text AS reconstructed_set_hash, r.registry_set_hash::text AS stored_set_hash, (md5(string_agg(concat_ws('|',t.bundle_code::text,t.contract_version::text,t.row_hash::text),'|' ORDER BY t.bundle_code, t.contract_version)) IS DISTINCT FROM r.registry_set_hash)::integer AS set_hash_mismatch_count FROM msbf_ctl.m2_12_g3_bundle_registry t JOIN tmp_v226_context ctx ON ctx.module1_run_id=t.module1_run_id JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1 GROUP BY r.registry_set_hash)),
setd AS (SELECT sum(set_hash_mismatch_count)::bigint set_hash_mismatch_count FROM set_detail),
ch AS (SELECT r.module1_run_id,
       md5(concat_ws('|',r.bundle_code::text,r.contract_version::text,r.schema_version::text,r.methodology_version::text,r.policy_configuration_hash::text,r.policy_set_hash::text,r.stage_certification_set_hash::text,r.contract_component_set_hash::text,r.evidence_certification_set_hash::text,r.contract_reproduction_set_hash::text,r.capability_coverage_set_hash::text,r.latest_set_hash::text,r.archive_set_hash::text,r.registry_set_hash::text,r.latest_contract_row_hash::text,r.archive_contract_row_hash::text,r.row_hash::text,r.accepted_m2_11_contract_set_hash::text,r.accepted_m2_11_combined_set_hash::text,r.accepted_m2_11_registry_row_hash::text))::text AS reconstructed_contract_set_hash,
       r.contract_set_hash::text AS stored_contract_set_hash,
       (md5(concat_ws('|',r.bundle_code::text,r.contract_version::text,r.schema_version::text,r.methodology_version::text,r.policy_configuration_hash::text,r.policy_set_hash::text,r.stage_certification_set_hash::text,r.contract_component_set_hash::text,r.evidence_certification_set_hash::text,r.contract_reproduction_set_hash::text,r.capability_coverage_set_hash::text,r.latest_set_hash::text,r.archive_set_hash::text,r.registry_set_hash::text,r.latest_contract_row_hash::text,r.archive_contract_row_hash::text,r.row_hash::text,r.accepted_m2_11_contract_set_hash::text,r.accepted_m2_11_combined_set_hash::text,r.accepted_m2_11_registry_row_hash::text)) IS DISTINCT FROM r.contract_set_hash)::integer AS contract_hash_mismatch_count
FROM msbf_ctl.m2_12_g3_bundle_registry r
JOIN tmp_v226_context ctx ON ctx.module1_run_id=r.module1_run_id
WHERE r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1), cb AS (SELECT u.module1_run_id, count(*)::integer AS canonical_entities, count(DISTINCT u.entity_type)::integer AS canonical_families, md5(string_agg(u.entity_type||'|'||u.entity_key||'|'||u.row_hash,'|' ORDER BY u.entity_type,u.entity_key))::text AS reconstructed_combined_set_hash, r.combined_set_hash::text AS stored_combined_set_hash, (md5(string_agg(u.entity_type||'|'||u.entity_key||'|'||u.row_hash,'|' ORDER BY u.entity_type,u.entity_key)) IS DISTINCT FROM r.combined_set_hash)::integer AS combined_hash_mismatch_count FROM (SELECT t.module1_run_id, 'POLICY'::text AS entity_type, concat_ws('|',t.policy_code::text,t.policy_version::text)::text AS entity_key, t.row_hash::text AS row_hash FROM msbf_ctl.m2_12_policy_profile t JOIN tmp_v226_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT t.module1_run_id, 'STAGE_CERTIFICATION'::text AS entity_type, concat_ws('|',t.certification_node_sequence::text,t.stage_code::text)::text AS entity_key, t.row_hash::text AS row_hash FROM msbf_m2.module2_stage_certification_snapshot t JOIN tmp_v226_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT t.module1_run_id, 'CONTRACT_COMPONENT'::text AS entity_type, concat_ws('|',t.component_sequence::text,t.component_contract_code::text,t.contract_version::text)::text AS entity_key, t.row_hash::text AS row_hash FROM msbf_m2.module2_contract_component_snapshot t JOIN tmp_v226_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT t.module1_run_id, 'EVIDENCE_CERTIFICATION'::text AS entity_type, concat_ws('|',t.node_sequence::text,t.evidence_family_sequence::text)::text AS entity_key, t.row_hash::text AS row_hash FROM msbf_m2.module2_evidence_certification_snapshot t JOIN tmp_v226_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT t.module1_run_id, 'CONTRACT_REPRODUCTION'::text AS entity_type, concat_ws('|',t.component_sequence::text,t.component_contract_code::text,t.contract_version::text)::text AS entity_key, t.row_hash::text AS row_hash FROM msbf_m2.module2_contract_reproduction_snapshot t JOIN tmp_v226_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT t.module1_run_id, 'CAPABILITY_COVERAGE'::text AS entity_type, concat_ws('|',t.capability_sequence::text,t.capability_code::text)::text AS entity_key, t.row_hash::text AS row_hash FROM msbf_m2.module2_capability_coverage_snapshot t JOIN tmp_v226_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT t.module1_run_id, 'LATEST'::text AS entity_type, concat_ws('|',t.bundle_code::text,t.contract_version::text)::text AS entity_key, t.row_hash::text AS row_hash FROM msbf_ctl.m2_12_g3_bundle_latest t JOIN tmp_v226_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT t.module1_run_id, 'ARCHIVE'::text AS entity_type, concat_ws('|',t.bundle_code::text,t.contract_version::text)::text AS entity_key, t.archive_row_hash::text AS row_hash FROM msbf_ctl.m2_12_g3_bundle_archive t JOIN tmp_v226_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT t.module1_run_id, 'REGISTRY'::text AS entity_type, concat_ws('|',t.bundle_code::text,t.contract_version::text)::text AS entity_key, t.row_hash::text AS row_hash FROM msbf_ctl.m2_12_g3_bundle_registry t JOIN tmp_v226_context ctx ON ctx.module1_run_id=t.module1_run_id) u JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=u.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1 GROUP BY u.module1_run_id,r.combined_set_hash), seq AS (SELECT ctx.module1_run_id,
       p.last_value::bigint AS policy_last_value,p.is_called AS policy_is_called,
       a.last_value::bigint AS archive_last_value,a.is_called AS archive_is_called,
       r.last_value::bigint AS registry_last_value,r.is_called AS registry_is_called,
       ((p.last_value<>1 OR NOT p.is_called)::integer
        +(a.last_value<>1 OR NOT a.is_called)::integer
        +(r.last_value<>1 OR NOT r.is_called)::integer)::integer AS sequence_state_mismatch_count
FROM tmp_v226_context ctx
CROSS JOIN msbf_ctl.m2_12_policy_profile_policy_profile_id_seq p
CROSS JOIN msbf_ctl.m2_12_g3_bundle_archive_archive_id_seq a
CROSS JOIN msbf_ctl.m2_12_g3_bundle_registry_registry_id_seq r)
SELECT ctx.module1_run_id,
       rowd.family_count_mismatch_count,rowd.row_hash_mismatch_count,setd.set_hash_mismatch_count,
       ch.contract_hash_mismatch_count::integer,cb.combined_hash_mismatch_count::integer,
       seq.sequence_state_mismatch_count::integer,cb.canonical_families::integer,cb.canonical_entities::integer,
       (rowd.family_count_mismatch_count+rowd.row_hash_mismatch_count+setd.set_hash_mismatch_count+ch.contract_hash_mismatch_count+cb.combined_hash_mismatch_count+seq.sequence_state_mismatch_count)::bigint AS total_mismatch_count
FROM tmp_v226_context ctx CROSS JOIN rowd CROSS JOIN setd CROSS JOIN ch CROSS JOIN cb CROSS JOIN seq
) p;
CREATE UNIQUE INDEX ux_tmp_v226_reconciliation ON tmp_v226_reconciliation(module1_run_id);
ANALYZE tmp_v226_reconciliation;

    CREATE TEMP TABLE tmp_v226_hash_detail ON COMMIT DROP AS
    SELECT 1::smallint AS hash_sequence, 'POLICY_SET_HASH'::text AS hash_code,
       r.policy_set_hash::text AS stored_hash,
       md5(string_agg(concat_ws('|',t.policy_code::text,t.policy_version::text,t.row_hash::text),'|' ORDER BY t.policy_code,t.policy_version))::text AS reconstructed_hash,
       (r.policy_set_hash IS DISTINCT FROM md5(string_agg(concat_ws('|',t.policy_code::text,t.policy_version::text,t.row_hash::text),'|' ORDER BY t.policy_code,t.policy_version))) AS mismatch_flag,
       'msbf_ctl.m2_12_policy_profile'::text AS authoritative_source,
       'policy_code,policy_version'::text AS ordered_business_key
FROM msbf_ctl.m2_12_policy_profile t
JOIN tmp_v226_context ctx ON ctx.module1_run_id=t.module1_run_id
JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1
GROUP BY r.policy_set_hash
UNION ALL
SELECT 2::smallint AS hash_sequence, 'STAGE_CERTIFICATION_SET_HASH'::text AS hash_code,
       r.stage_certification_set_hash::text AS stored_hash,
       md5(string_agg(concat_ws('|',t.certification_node_sequence::text,t.stage_code::text,t.row_hash::text),'|' ORDER BY t.certification_node_sequence,t.stage_code))::text AS reconstructed_hash,
       (r.stage_certification_set_hash IS DISTINCT FROM md5(string_agg(concat_ws('|',t.certification_node_sequence::text,t.stage_code::text,t.row_hash::text),'|' ORDER BY t.certification_node_sequence,t.stage_code))) AS mismatch_flag,
       'msbf_m2.module2_stage_certification_snapshot'::text AS authoritative_source,
       'certification_node_sequence,stage_code'::text AS ordered_business_key
FROM msbf_m2.module2_stage_certification_snapshot t
JOIN tmp_v226_context ctx ON ctx.module1_run_id=t.module1_run_id
JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1
GROUP BY r.stage_certification_set_hash
UNION ALL
SELECT 3::smallint AS hash_sequence, 'CONTRACT_COMPONENT_SET_HASH'::text AS hash_code,
       r.contract_component_set_hash::text AS stored_hash,
       md5(string_agg(concat_ws('|',t.component_sequence::text,t.component_contract_code::text,t.contract_version::text,t.row_hash::text),'|' ORDER BY t.component_sequence,t.component_contract_code,t.contract_version))::text AS reconstructed_hash,
       (r.contract_component_set_hash IS DISTINCT FROM md5(string_agg(concat_ws('|',t.component_sequence::text,t.component_contract_code::text,t.contract_version::text,t.row_hash::text),'|' ORDER BY t.component_sequence,t.component_contract_code,t.contract_version))) AS mismatch_flag,
       'msbf_m2.module2_contract_component_snapshot'::text AS authoritative_source,
       'component_sequence,component_contract_code,contract_version'::text AS ordered_business_key
FROM msbf_m2.module2_contract_component_snapshot t
JOIN tmp_v226_context ctx ON ctx.module1_run_id=t.module1_run_id
JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1
GROUP BY r.contract_component_set_hash
UNION ALL
SELECT 4::smallint AS hash_sequence, 'EVIDENCE_CERTIFICATION_SET_HASH'::text AS hash_code,
       r.evidence_certification_set_hash::text AS stored_hash,
       md5(string_agg(concat_ws('|',t.node_sequence::text,t.evidence_family_sequence::text,t.row_hash::text),'|' ORDER BY t.node_sequence,t.evidence_family_sequence))::text AS reconstructed_hash,
       (r.evidence_certification_set_hash IS DISTINCT FROM md5(string_agg(concat_ws('|',t.node_sequence::text,t.evidence_family_sequence::text,t.row_hash::text),'|' ORDER BY t.node_sequence,t.evidence_family_sequence))) AS mismatch_flag,
       'msbf_m2.module2_evidence_certification_snapshot'::text AS authoritative_source,
       'node_sequence,evidence_family_sequence'::text AS ordered_business_key
FROM msbf_m2.module2_evidence_certification_snapshot t
JOIN tmp_v226_context ctx ON ctx.module1_run_id=t.module1_run_id
JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1
GROUP BY r.evidence_certification_set_hash
UNION ALL
SELECT 5::smallint AS hash_sequence, 'CONTRACT_REPRODUCTION_SET_HASH'::text AS hash_code,
       r.contract_reproduction_set_hash::text AS stored_hash,
       md5(string_agg(concat_ws('|',t.component_sequence::text,t.component_contract_code::text,t.contract_version::text,t.row_hash::text),'|' ORDER BY t.component_sequence,t.component_contract_code,t.contract_version))::text AS reconstructed_hash,
       (r.contract_reproduction_set_hash IS DISTINCT FROM md5(string_agg(concat_ws('|',t.component_sequence::text,t.component_contract_code::text,t.contract_version::text,t.row_hash::text),'|' ORDER BY t.component_sequence,t.component_contract_code,t.contract_version))) AS mismatch_flag,
       'msbf_m2.module2_contract_reproduction_snapshot'::text AS authoritative_source,
       'component_sequence,component_contract_code,contract_version'::text AS ordered_business_key
FROM msbf_m2.module2_contract_reproduction_snapshot t
JOIN tmp_v226_context ctx ON ctx.module1_run_id=t.module1_run_id
JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1
GROUP BY r.contract_reproduction_set_hash
UNION ALL
SELECT 6::smallint AS hash_sequence, 'CAPABILITY_COVERAGE_SET_HASH'::text AS hash_code,
       r.capability_coverage_set_hash::text AS stored_hash,
       md5(string_agg(concat_ws('|',t.capability_sequence::text,t.capability_code::text,t.row_hash::text),'|' ORDER BY t.capability_sequence,t.capability_code))::text AS reconstructed_hash,
       (r.capability_coverage_set_hash IS DISTINCT FROM md5(string_agg(concat_ws('|',t.capability_sequence::text,t.capability_code::text,t.row_hash::text),'|' ORDER BY t.capability_sequence,t.capability_code))) AS mismatch_flag,
       'msbf_m2.module2_capability_coverage_snapshot'::text AS authoritative_source,
       'capability_sequence,capability_code'::text AS ordered_business_key
FROM msbf_m2.module2_capability_coverage_snapshot t
JOIN tmp_v226_context ctx ON ctx.module1_run_id=t.module1_run_id
JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1
GROUP BY r.capability_coverage_set_hash
UNION ALL
SELECT 7::smallint AS hash_sequence, 'LATEST_SET_HASH'::text AS hash_code,
       r.latest_set_hash::text AS stored_hash,
       md5(string_agg(concat_ws('|',t.bundle_code::text,t.contract_version::text,t.row_hash::text),'|' ORDER BY t.bundle_code,t.contract_version))::text AS reconstructed_hash,
       (r.latest_set_hash IS DISTINCT FROM md5(string_agg(concat_ws('|',t.bundle_code::text,t.contract_version::text,t.row_hash::text),'|' ORDER BY t.bundle_code,t.contract_version))) AS mismatch_flag,
       'msbf_ctl.m2_12_g3_bundle_latest'::text AS authoritative_source,
       'bundle_code,contract_version'::text AS ordered_business_key
FROM msbf_ctl.m2_12_g3_bundle_latest t
JOIN tmp_v226_context ctx ON ctx.module1_run_id=t.module1_run_id
JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1
GROUP BY r.latest_set_hash
UNION ALL
SELECT 8::smallint AS hash_sequence, 'ARCHIVE_SET_HASH'::text AS hash_code,
       r.archive_set_hash::text AS stored_hash,
       md5(string_agg(concat_ws('|',t.bundle_code::text,t.contract_version::text,t.archive_row_hash::text),'|' ORDER BY t.bundle_code,t.contract_version))::text AS reconstructed_hash,
       (r.archive_set_hash IS DISTINCT FROM md5(string_agg(concat_ws('|',t.bundle_code::text,t.contract_version::text,t.archive_row_hash::text),'|' ORDER BY t.bundle_code,t.contract_version))) AS mismatch_flag,
       'msbf_ctl.m2_12_g3_bundle_archive'::text AS authoritative_source,
       'bundle_code,contract_version'::text AS ordered_business_key
FROM msbf_ctl.m2_12_g3_bundle_archive t
JOIN tmp_v226_context ctx ON ctx.module1_run_id=t.module1_run_id
JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1
GROUP BY r.archive_set_hash
UNION ALL
SELECT 9::smallint AS hash_sequence, 'REGISTRY_SET_HASH'::text AS hash_code,
       r.registry_set_hash::text AS stored_hash,
       md5(string_agg(concat_ws('|',t.bundle_code::text,t.contract_version::text,t.row_hash::text),'|' ORDER BY t.bundle_code,t.contract_version))::text AS reconstructed_hash,
       (r.registry_set_hash IS DISTINCT FROM md5(string_agg(concat_ws('|',t.bundle_code::text,t.contract_version::text,t.row_hash::text),'|' ORDER BY t.bundle_code,t.contract_version))) AS mismatch_flag,
       'msbf_ctl.m2_12_g3_bundle_registry'::text AS authoritative_source,
       'bundle_code,contract_version'::text AS ordered_business_key
FROM msbf_ctl.m2_12_g3_bundle_registry t
JOIN tmp_v226_context ctx ON ctx.module1_run_id=t.module1_run_id
JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1
GROUP BY r.registry_set_hash
UNION ALL
SELECT 10::smallint,'REGISTRY_ROW_HASH'::text,r.row_hash::text,
       md5((to_jsonb(r)-ARRAY['registry_id','contract_status','generated_at','validated_at','accepted_at','created_at','updated_at','row_hash','policy_set_hash','stage_certification_set_hash','contract_component_set_hash','evidence_certification_set_hash','contract_reproduction_set_hash','capability_coverage_set_hash','latest_set_hash','archive_set_hash','registry_set_hash','contract_set_hash','combined_set_hash']::text[])::text)::text,
       (r.row_hash IS DISTINCT FROM md5((to_jsonb(r)-ARRAY['registry_id','contract_status','generated_at','validated_at','accepted_at','created_at','updated_at','row_hash','policy_set_hash','stage_certification_set_hash','contract_component_set_hash','evidence_certification_set_hash','contract_reproduction_set_hash','capability_coverage_set_hash','latest_set_hash','archive_set_hash','registry_set_hash','contract_set_hash','combined_set_hash']::text[])::text)),
       'msbf_ctl.m2_12_g3_bundle_registry'::text,
       'bundle_code,contract_version; immutable registry preimage'::text
FROM msbf_ctl.m2_12_g3_bundle_registry r
JOIN tmp_v226_context ctx ON ctx.module1_run_id=r.module1_run_id
WHERE r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1
UNION ALL
SELECT 11::smallint,'CONTRACT_SET_HASH'::text,r.contract_set_hash::text,
       md5(concat_ws('|',r.bundle_code::text,r.contract_version::text,r.schema_version::text,r.methodology_version::text,r.policy_configuration_hash::text,r.policy_set_hash::text,r.stage_certification_set_hash::text,r.contract_component_set_hash::text,r.evidence_certification_set_hash::text,r.contract_reproduction_set_hash::text,r.capability_coverage_set_hash::text,r.latest_set_hash::text,r.archive_set_hash::text,r.registry_set_hash::text,r.latest_contract_row_hash::text,r.archive_contract_row_hash::text,r.row_hash::text,r.accepted_m2_11_contract_set_hash::text,r.accepted_m2_11_combined_set_hash::text,r.accepted_m2_11_registry_row_hash::text))::text,
       (r.contract_set_hash IS DISTINCT FROM md5(concat_ws('|',r.bundle_code::text,r.contract_version::text,r.schema_version::text,r.methodology_version::text,r.policy_configuration_hash::text,r.policy_set_hash::text,r.stage_certification_set_hash::text,r.contract_component_set_hash::text,r.evidence_certification_set_hash::text,r.contract_reproduction_set_hash::text,r.capability_coverage_set_hash::text,r.latest_set_hash::text,r.archive_set_hash::text,r.registry_set_hash::text,r.latest_contract_row_hash::text,r.archive_contract_row_hash::text,r.row_hash::text,r.accepted_m2_11_contract_set_hash::text,r.accepted_m2_11_combined_set_hash::text,r.accepted_m2_11_registry_row_hash::text))),
       'msbf_ctl.m2_12_g3_bundle_registry'::text,
       'frozen G3 contract-hash field order'::text
FROM msbf_ctl.m2_12_g3_bundle_registry r
JOIN tmp_v226_context ctx ON ctx.module1_run_id=r.module1_run_id
WHERE r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1
UNION ALL
SELECT 12::smallint,'COMBINED_SET_HASH'::text,r.combined_set_hash::text,
       md5(string_agg(c.family_code||'|'||c.entity_key||'|'||c.stored_hash,'|' ORDER BY c.family_code,c.entity_key))::text,
       (r.combined_set_hash IS DISTINCT FROM md5(string_agg(c.family_code||'|'||c.entity_key||'|'||c.stored_hash,'|' ORDER BY c.family_code,c.entity_key))),
       'all nine M2.12 canonical families'::text,
       'family_code,entity_key'::text
FROM (
    SELECT 'POLICY'::text family_code, concat_ws('|',t.policy_code,t.policy_version::text) entity_key, t.row_hash::text stored_hash, md5((to_jsonb(t)-'policy_profile_id'-'row_hash'-'created_at'-'updated_at')::text)::text physical_hash FROM msbf_ctl.m2_12_policy_profile t JOIN tmp_v226_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT 'STAGE_CERTIFICATION', concat_ws('|',t.certification_node_sequence::text,t.stage_code), t.row_hash, md5((to_jsonb(t)-'row_hash'-'created_at')::text) FROM msbf_m2.module2_stage_certification_snapshot t JOIN tmp_v226_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT 'CONTRACT_COMPONENT', concat_ws('|',t.component_sequence::text,t.component_contract_code,t.contract_version::text), t.row_hash, md5((to_jsonb(t)-'row_hash'-'created_at')::text) FROM msbf_m2.module2_contract_component_snapshot t JOIN tmp_v226_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT 'EVIDENCE_CERTIFICATION', concat_ws('|',t.node_sequence::text,t.evidence_family_sequence::text), t.row_hash, md5((to_jsonb(t)-'row_hash'-'created_at')::text) FROM msbf_m2.module2_evidence_certification_snapshot t JOIN tmp_v226_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT 'CONTRACT_REPRODUCTION', concat_ws('|',t.component_sequence::text,t.component_contract_code,t.contract_version::text), t.row_hash, md5((to_jsonb(t)-'row_hash'-'created_at')::text) FROM msbf_m2.module2_contract_reproduction_snapshot t JOIN tmp_v226_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT 'CAPABILITY_COVERAGE', concat_ws('|',t.capability_sequence::text,t.capability_code), t.row_hash, md5((to_jsonb(t)-'row_hash'-'created_at')::text) FROM msbf_m2.module2_capability_coverage_snapshot t JOIN tmp_v226_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT 'LATEST', concat_ws('|',t.bundle_code,t.contract_version::text), t.row_hash, md5((to_jsonb(t)-'row_hash'-'created_at')::text) FROM msbf_ctl.m2_12_g3_bundle_latest t JOIN tmp_v226_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT 'ARCHIVE', concat_ws('|',t.bundle_code,t.contract_version::text), t.archive_row_hash, md5((to_jsonb(t)-'archive_id'-'archive_row_hash'-'created_at')::text) FROM msbf_ctl.m2_12_g3_bundle_archive t JOIN tmp_v226_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT 'REGISTRY', concat_ws('|',t.bundle_code,t.contract_version::text), t.row_hash, md5((to_jsonb(t)-ARRAY['registry_id','contract_status','generated_at','validated_at','accepted_at','created_at','updated_at','row_hash','policy_set_hash','stage_certification_set_hash','contract_component_set_hash','evidence_certification_set_hash','contract_reproduction_set_hash','capability_coverage_set_hash','latest_set_hash','archive_set_hash','registry_set_hash','contract_set_hash','combined_set_hash']::text[])::text) FROM msbf_ctl.m2_12_g3_bundle_registry t JOIN tmp_v226_context ctx ON ctx.module1_run_id=t.module1_run_id
) c
CROSS JOIN msbf_ctl.m2_12_g3_bundle_registry r
JOIN tmp_v226_context ctx ON ctx.module1_run_id=r.module1_run_id
WHERE r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1
GROUP BY r.combined_set_hash;
    CREATE UNIQUE INDEX ux_tmp_v226_hash_detail ON tmp_v226_hash_detail(hash_sequence);
    ANALYZE tmp_v226_hash_detail;
CREATE TEMP TABLE tmp_v226_reconstruction ON COMMIT DROP AS
WITH canonical AS (
    SELECT 'POLICY'::text family_code, concat_ws('|',t.policy_code,t.policy_version::text) entity_key, t.row_hash::text stored_hash, md5((to_jsonb(t)-'policy_profile_id'-'row_hash'-'created_at'-'updated_at')::text)::text physical_hash FROM msbf_ctl.m2_12_policy_profile t JOIN tmp_v226_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT 'STAGE_CERTIFICATION', concat_ws('|',t.certification_node_sequence::text,t.stage_code), t.row_hash, md5((to_jsonb(t)-'row_hash'-'created_at')::text) FROM msbf_m2.module2_stage_certification_snapshot t JOIN tmp_v226_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT 'CONTRACT_COMPONENT', concat_ws('|',t.component_sequence::text,t.component_contract_code,t.contract_version::text), t.row_hash, md5((to_jsonb(t)-'row_hash'-'created_at')::text) FROM msbf_m2.module2_contract_component_snapshot t JOIN tmp_v226_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT 'EVIDENCE_CERTIFICATION', concat_ws('|',t.node_sequence::text,t.evidence_family_sequence::text), t.row_hash, md5((to_jsonb(t)-'row_hash'-'created_at')::text) FROM msbf_m2.module2_evidence_certification_snapshot t JOIN tmp_v226_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT 'CONTRACT_REPRODUCTION', concat_ws('|',t.component_sequence::text,t.component_contract_code,t.contract_version::text), t.row_hash, md5((to_jsonb(t)-'row_hash'-'created_at')::text) FROM msbf_m2.module2_contract_reproduction_snapshot t JOIN tmp_v226_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT 'CAPABILITY_COVERAGE', concat_ws('|',t.capability_sequence::text,t.capability_code), t.row_hash, md5((to_jsonb(t)-'row_hash'-'created_at')::text) FROM msbf_m2.module2_capability_coverage_snapshot t JOIN tmp_v226_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT 'LATEST', concat_ws('|',t.bundle_code,t.contract_version::text), t.row_hash, md5((to_jsonb(t)-'row_hash'-'created_at')::text) FROM msbf_ctl.m2_12_g3_bundle_latest t JOIN tmp_v226_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT 'ARCHIVE', concat_ws('|',t.bundle_code,t.contract_version::text), t.archive_row_hash, md5((to_jsonb(t)-'archive_id'-'archive_row_hash'-'created_at')::text) FROM msbf_ctl.m2_12_g3_bundle_archive t JOIN tmp_v226_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT 'REGISTRY', concat_ws('|',t.bundle_code,t.contract_version::text), t.row_hash, md5((to_jsonb(t)-ARRAY['registry_id','contract_status','generated_at','validated_at','accepted_at','created_at','updated_at','row_hash','policy_set_hash','stage_certification_set_hash','contract_component_set_hash','evidence_certification_set_hash','contract_reproduction_set_hash','capability_coverage_set_hash','latest_set_hash','archive_set_hash','registry_set_hash','contract_set_hash','combined_set_hash']::text[])::text) FROM msbf_ctl.m2_12_g3_bundle_registry t JOIN tmp_v226_context ctx ON ctx.module1_run_id=t.module1_run_id
), registry AS (
    SELECT
        r.policy_set_hash,r.stage_certification_set_hash,r.contract_component_set_hash,
        r.evidence_certification_set_hash,r.contract_reproduction_set_hash,r.capability_coverage_set_hash,
        r.latest_set_hash,r.archive_set_hash,r.registry_set_hash,r.latest_contract_row_hash,
        r.archive_contract_row_hash,r.contract_set_hash,r.combined_set_hash,r.row_hash,
        r.accepted_m2_11_contract_set_hash,r.accepted_m2_11_combined_set_hash,
        r.accepted_m2_11_registry_row_hash
    FROM msbf_ctl.m2_12_g3_bundle_registry r
    JOIN tmp_v226_context ctx ON ctx.module1_run_id=r.module1_run_id
    WHERE r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1
), sequence_state AS (
    SELECT concat_ws('|',
        p.last_value::text,p.is_called::text,
        a.last_value::text,a.is_called::text,
        r.last_value::text,r.is_called::text) AS sequence_fingerprint
    FROM msbf_ctl.m2_12_policy_profile_policy_profile_id_seq p
    CROSS JOIN msbf_ctl.m2_12_g3_bundle_archive_archive_id_seq a
    CROSS JOIN msbf_ctl.m2_12_g3_bundle_registry_registry_id_seq r
)
SELECT
    count(*)::integer AS canonical_entity_count,
    count(DISTINCT family_code)::integer AS canonical_family_count,
    count(*) FILTER (WHERE stored_hash IS DISTINCT FROM physical_hash)::integer AS row_hash_mismatch_count,
    md5(string_agg(concat_ws('|',family_code,entity_key,stored_hash,physical_hash),'|' ORDER BY family_code,entity_key))::text AS canonical_physical_fingerprint,
    (SELECT md5(concat_ws('|',
        policy_set_hash,stage_certification_set_hash,contract_component_set_hash,
        evidence_certification_set_hash,contract_reproduction_set_hash,capability_coverage_set_hash,
        latest_set_hash,archive_set_hash,registry_set_hash,latest_contract_row_hash,
        archive_contract_row_hash,contract_set_hash,combined_set_hash,row_hash,
        accepted_m2_11_contract_set_hash,accepted_m2_11_combined_set_hash,
        accepted_m2_11_registry_row_hash)) FROM registry)::text AS governed_hash_fingerprint,
    (SELECT sequence_fingerprint FROM sequence_state)::text AS sequence_fingerprint
FROM canonical;
CREATE UNIQUE INDEX ux_tmp_v226_reconstruction ON tmp_v226_reconstruction(canonical_entity_count);
ANALYZE tmp_v226_reconstruction;

/* Exact G3 latest/archive physical parity. */
CREATE TEMP TABLE tmp_v226_g3_parity ON COMMIT DROP AS
SELECT count(*)::integer AS joined_rows,
       count(*) FILTER (WHERE l.row_hash IS DISTINCT FROM md5((to_jsonb(l)-'row_hash'-'created_at')::text))::integer AS latest_row_hash_mismatches,
       count(*) FILTER (WHERE a.archive_row_hash IS DISTINCT FROM md5((to_jsonb(a)-'archive_id'-'archive_row_hash'-'created_at')::text))::integer AS archive_row_hash_mismatches,
       count(*) FILTER (WHERE a.source_latest_row_hash IS DISTINCT FROM l.row_hash
                          OR a.contract_row_hash IS DISTINCT FROM l.contract_row_hash
                          OR a.contract_payload IS DISTINCT FROM (to_jsonb(l)-'created_at'))::integer AS archive_payload_mismatches,
       CASE WHEN count(*)=1
                  AND count(*) FILTER (WHERE l.row_hash IS DISTINCT FROM md5((to_jsonb(l)-'row_hash'-'created_at')::text))=0
                  AND count(*) FILTER (WHERE a.archive_row_hash IS DISTINCT FROM md5((to_jsonb(a)-'archive_id'-'archive_row_hash'-'created_at')::text))=0
                  AND count(*) FILTER (WHERE a.source_latest_row_hash IS DISTINCT FROM l.row_hash
                                         OR a.contract_row_hash IS DISTINCT FROM l.contract_row_hash
                                         OR a.contract_payload IS DISTINCT FROM (to_jsonb(l)-'created_at'))=0
            THEN 'PASS' ELSE 'FAIL' END::text AS parity_status
  FROM msbf_ctl.m2_12_g3_bundle_latest l
  JOIN tmp_v226_context c ON c.module1_run_id=l.module1_run_id
  JOIN msbf_ctl.m2_12_g3_bundle_archive a
    ON a.module1_run_id=l.module1_run_id AND a.bundle_code=l.bundle_code AND a.contract_version=l.contract_version;
ANALYZE tmp_v226_g3_parity;

/* Exact governed evidence and acceptance state. */
CREATE TEMP TABLE tmp_v226_evidence ON COMMIT DROP AS
SELECT
  (SELECT count(*) FROM msbf_ctl.run_evidence e WHERE e.run_id=c.module1_run_id AND left(e.evidence_code,10)='M2_12_POS_')::integer AS positive_rows,
  (SELECT count(*) FROM msbf_ctl.run_evidence e WHERE e.run_id=c.module1_run_id AND left(e.evidence_code,10)='M2_12_POS_' AND e.status='PASS')::integer AS positive_pass_rows,
  (SELECT count(DISTINCT e.evidence_code) FROM msbf_ctl.run_evidence e WHERE e.run_id=c.module1_run_id AND left(e.evidence_code,10)='M2_12_POS_')::integer AS positive_distinct_codes,
  (SELECT count(*) FROM msbf_ctl.run_evidence e WHERE e.run_id=c.module1_run_id AND left(e.evidence_code,10)='M2_12_NEG_')::integer AS negative_rows,
  (SELECT count(*) FROM msbf_ctl.run_evidence e WHERE e.run_id=c.module1_run_id AND left(e.evidence_code,10)='M2_12_NEG_' AND e.status='PASS')::integer AS negative_pass_rows,
  (SELECT count(DISTINCT e.evidence_code) FROM msbf_ctl.run_evidence e WHERE e.run_id=c.module1_run_id AND left(e.evidence_code,10)='M2_12_NEG_')::integer AS negative_distinct_codes,
  (SELECT count(*) FROM msbf_ctl.run_evidence e WHERE e.run_id=c.module1_run_id AND e.evidence_code=ANY(ARRAY[
      'M2_12_POLICY_SET_HASH','M2_12_STAGE_CERTIFICATION_SET_HASH','M2_12_CONTRACT_COMPONENT_SET_HASH',
      'M2_12_EVIDENCE_CERTIFICATION_SET_HASH','M2_12_CONTRACT_REPRODUCTION_SET_HASH','M2_12_CAPABILITY_COVERAGE_SET_HASH',
      'M2_12_LATEST_SET_HASH','M2_12_ARCHIVE_SET_HASH','M2_12_REGISTRY_SET_HASH','M2_12_CONTRACT_SET_HASH',
      'M2_12_COMBINED_SET_HASH','M2_12_STAGE_CERTIFICATION_ROWS','M2_12_CONTRACT_COMPONENT_ROWS',
      'M2_12_EVIDENCE_CERTIFICATION_ROWS','M2_12_CONTRACT_REPRODUCTION_ROWS','M2_12_CAPABILITY_COVERAGE_ROWS',
      'M2_12_CANONICAL_ENTITIES','M2_12_COMPONENT_LATEST_ARCHIVE_ROWS_TOTAL','M2_12_APPLICATION_CONSUMPTION_ROWS',
      'M2_12_OPERATIONAL_ACCOUNT_CONSUMPTION_ROWS','M2_12_STRATEGY_SCOPE_CONSUMPTION_ROWS','M2_12_SOURCE_GRAPH_EDGES',
      'M2_12_DETERMINISTIC_MISMATCHES','M2_12_BLOCKING_STAGE_BOUNDARY_FINDINGS']::text[]))::integer AS generation_rows,
  (SELECT count(*) FROM msbf_ctl.run_evidence e WHERE e.run_id=c.module1_run_id AND e.evidence_code=ANY(ARRAY[
      'M2_12_POLICY_SET_HASH','M2_12_STAGE_CERTIFICATION_SET_HASH','M2_12_CONTRACT_COMPONENT_SET_HASH',
      'M2_12_EVIDENCE_CERTIFICATION_SET_HASH','M2_12_CONTRACT_REPRODUCTION_SET_HASH','M2_12_CAPABILITY_COVERAGE_SET_HASH',
      'M2_12_LATEST_SET_HASH','M2_12_ARCHIVE_SET_HASH','M2_12_REGISTRY_SET_HASH','M2_12_CONTRACT_SET_HASH',
      'M2_12_COMBINED_SET_HASH','M2_12_STAGE_CERTIFICATION_ROWS','M2_12_CONTRACT_COMPONENT_ROWS',
      'M2_12_EVIDENCE_CERTIFICATION_ROWS','M2_12_CONTRACT_REPRODUCTION_ROWS','M2_12_CAPABILITY_COVERAGE_ROWS',
      'M2_12_CANONICAL_ENTITIES','M2_12_COMPONENT_LATEST_ARCHIVE_ROWS_TOTAL','M2_12_APPLICATION_CONSUMPTION_ROWS',
      'M2_12_OPERATIONAL_ACCOUNT_CONSUMPTION_ROWS','M2_12_STRATEGY_SCOPE_CONSUMPTION_ROWS','M2_12_SOURCE_GRAPH_EDGES',
      'M2_12_DETERMINISTIC_MISMATCHES','M2_12_BLOCKING_STAGE_BOUNDARY_FINDINGS']::text[]) AND e.status='PASS')::integer AS generation_pass_rows,
  (SELECT count(DISTINCT e.evidence_code) FROM msbf_ctl.run_evidence e WHERE e.run_id=c.module1_run_id AND e.evidence_code=ANY(ARRAY[
      'M2_12_POLICY_SET_HASH','M2_12_STAGE_CERTIFICATION_SET_HASH','M2_12_CONTRACT_COMPONENT_SET_HASH',
      'M2_12_EVIDENCE_CERTIFICATION_SET_HASH','M2_12_CONTRACT_REPRODUCTION_SET_HASH','M2_12_CAPABILITY_COVERAGE_SET_HASH',
      'M2_12_LATEST_SET_HASH','M2_12_ARCHIVE_SET_HASH','M2_12_REGISTRY_SET_HASH','M2_12_CONTRACT_SET_HASH',
      'M2_12_COMBINED_SET_HASH','M2_12_STAGE_CERTIFICATION_ROWS','M2_12_CONTRACT_COMPONENT_ROWS',
      'M2_12_EVIDENCE_CERTIFICATION_ROWS','M2_12_CONTRACT_REPRODUCTION_ROWS','M2_12_CAPABILITY_COVERAGE_ROWS',
      'M2_12_CANONICAL_ENTITIES','M2_12_COMPONENT_LATEST_ARCHIVE_ROWS_TOTAL','M2_12_APPLICATION_CONSUMPTION_ROWS',
      'M2_12_OPERATIONAL_ACCOUNT_CONSUMPTION_ROWS','M2_12_STRATEGY_SCOPE_CONSUMPTION_ROWS','M2_12_SOURCE_GRAPH_EDGES',
      'M2_12_DETERMINISTIC_MISMATCHES','M2_12_BLOCKING_STAGE_BOUNDARY_FINDINGS']::text[]))::integer AS generation_distinct_codes,
  (SELECT count(*) FROM msbf_ctl.run_evidence e WHERE e.run_id=c.module1_run_id AND e.evidence_code='M2_12_ACCEPTANCE_SUMMARY')::integer AS acceptance_rows,
  (SELECT count(*) FROM msbf_ctl.run_evidence e WHERE e.run_id=c.module1_run_id AND e.evidence_code='M2_12_ACCEPTANCE_SUMMARY' AND e.status='PASS')::integer AS acceptance_pass_rows,
  (SELECT count(*) FROM msbf_ctl.run_evidence e WHERE e.run_id=c.module1_run_id AND left(e.evidence_code,6)='M2_12_' AND e.status<>'PASS')::integer AS nonpass_rows,
  c.gate_rows::integer AS gate_rows,c.exact_gate_rows::integer AS exact_gate_rows,
  c.acceptance_rows::integer AS exact_acceptance_total_rows,c.exact_acceptance_rows::integer AS exact_acceptance_rows
FROM tmp_v226_context c;
ANALYZE tmp_v226_evidence;

/* Consumption, strategy, and accepted M2.11 posture. */
CREATE TEMP TABLE tmp_v226_consumption ON COMMIT DROP AS
SELECT
  (SELECT count(*) FROM msbf_m2.v_m2_12_application_origination_consumption v WHERE v.module1_run_id=c.module1_run_id)::bigint AS application_rows,
  (SELECT count(DISTINCT v.merchant_application_id) FROM msbf_m2.v_m2_12_application_origination_consumption v WHERE v.module1_run_id=c.module1_run_id)::integer AS distinct_application_rows,
  (SELECT count(DISTINCT v.scenario_code) FROM msbf_m2.v_m2_12_application_origination_consumption v WHERE v.module1_run_id=c.module1_run_id)::integer AS application_scenarios,
  (SELECT count(*)-count(DISTINCT (v.scenario_code,v.merchant_application_id)) FROM msbf_m2.v_m2_12_application_origination_consumption v WHERE v.module1_run_id=c.module1_run_id)::integer AS application_duplicate_keys,
  (SELECT count(*) FILTER (WHERE v.merchant_id IS NULL OR v.m1_15_contract_row_hash IS NULL OR v.m1_16_contract_row_hash IS NULL OR v.m2_1_source_g2_combined_hash IS NULL OR v.m2_4_contract_row_hash IS NULL) FROM msbf_m2.v_m2_12_application_origination_consumption v WHERE v.module1_run_id=c.module1_run_id)::integer AS application_missing_lineage_rows,
  (SELECT count(*) FROM msbf_m2.v_m2_12_operational_account_consumption v WHERE v.module1_run_id=c.module1_run_id)::integer AS operational_rows,
  (SELECT count(*)-count(DISTINCT (v.scenario_code,v.merchant_application_id,v.synthetic_account_id,v.synthetic_advance_id)) FROM msbf_m2.v_m2_12_operational_account_consumption v WHERE v.module1_run_id=c.module1_run_id)::integer AS operational_duplicate_keys,
  (SELECT count(*) FILTER (WHERE v.merchant_application_id IS NULL OR v.synthetic_account_id IS NULL OR v.synthetic_advance_id IS NULL OR v.m2_4_contract_row_hash IS NULL OR v.m2_10_contract_row_hash IS NULL) FROM msbf_m2.v_m2_12_operational_account_consumption v WHERE v.module1_run_id=c.module1_run_id)::integer AS operational_orphan_rows,
  (SELECT count(*) FROM msbf_m2.v_m2_12_strategy_scope_consumption v WHERE v.module1_run_id=c.module1_run_id)::integer AS strategy_rows,
  (SELECT count(DISTINCT v.strategy_profile_code) FROM msbf_m2.v_m2_12_strategy_scope_consumption v WHERE v.module1_run_id=c.module1_run_id)::integer AS strategy_profiles,
  (SELECT count(DISTINCT v.reporting_scope_code) FROM msbf_m2.v_m2_12_strategy_scope_consumption v WHERE v.module1_run_id=c.module1_run_id)::integer AS reporting_scopes,
  (SELECT count(*) FILTER (WHERE v.strategy_evidence_status='PARTIAL') FROM msbf_m2.v_m2_12_strategy_scope_consumption v WHERE v.module1_run_id=c.module1_run_id)::integer AS strategy_partial_rows,
  (SELECT count(*) FILTER (WHERE v.stress_nonimprovement_pass_flag) FROM msbf_m2.v_m2_12_strategy_scope_consumption v WHERE v.module1_run_id=c.module1_run_id)::integer AS stress_nonimprovement_pass_rows,
  (SELECT count(*) FILTER (WHERE v.frontier_eligible_flag) FROM msbf_m2.v_m2_12_strategy_scope_consumption v WHERE v.module1_run_id=c.module1_run_id)::integer AS frontier_eligible_rows,
  (SELECT count(*) FILTER (WHERE v.non_dominated_flag) FROM msbf_m2.v_m2_12_strategy_scope_consumption v WHERE v.module1_run_id=c.module1_run_id)::integer AS nondominated_rows,
  (SELECT count(*) FILTER (WHERE v.frontier_rank=1) FROM msbf_m2.v_m2_12_strategy_scope_consumption v WHERE v.module1_run_id=c.module1_run_id)::integer AS frontier_rank1_rows,
  (SELECT count(*) FILTER (WHERE v.primary_governance_review_flag AND v.governance_review_priority_code='PRIMARY_GOVERNANCE_REVIEW') FROM msbf_m2.v_m2_12_strategy_scope_consumption v WHERE v.module1_run_id=c.module1_run_id)::integer AS primary_governance_review_rows,
  (SELECT coalesce(sum(v.hard_constraint_violation_count+v.source_risk_improvement_violation_count+v.source_return_improvement_violation_count+v.strategy_access_improvement_violation_count+v.strategy_feasibility_improvement_violation_count+v.comparable_payment_burden_improvement_violation_count+v.comparable_servicing_burden_improvement_violation_count+v.stress_improvement_violation_count),0) FROM msbf_m2.v_m2_12_strategy_scope_consumption v WHERE v.module1_run_id=c.module1_run_id)::bigint AS m2_11_strategy_violation_count
FROM tmp_v226_context c;
ANALYZE tmp_v226_consumption;

/* Exact accepted source anchors. */
CREATE TEMP TABLE tmp_v226_source_anchors ON COMMIT DROP AS
SELECT g2.bundle_code::text AS m1_17_bundle_code,
       g2.bundle_version::integer AS m1_17_bundle_version,
       g2.schema_version::text AS m1_17_schema_version,
       g2.methodology_version::text AS m1_17_methodology_version,
       g2.combined_g2_hash::text AS m1_17_combined_hash,
       g2.row_hash::text AS m1_17_registry_row_hash,
       m211.contract_code::text AS m2_11_contract_code,
       m211.contract_version::integer AS m2_11_contract_version,
       m211.schema_version::text AS m2_11_schema_version,
       m211.methodology_version::text AS m2_11_methodology_version,
       m211.contract_set_hash::text AS m2_11_contract_set_hash,
       m211.combined_set_hash::text AS m2_11_combined_set_hash,
       m211.row_hash::text AS m2_11_registry_row_hash,
       ((g2.combined_g2_hash IS DISTINCT FROM '7d9e466da28cad2551aa99c4c40c912b')::integer
        +(m211.contract_set_hash IS DISTINCT FROM c.accepted_m2_11_contract_set_hash)::integer
        +(m211.combined_set_hash IS DISTINCT FROM c.accepted_m2_11_combined_set_hash)::integer
        +(m211.row_hash IS DISTINCT FROM c.accepted_m2_11_registry_row_hash)::integer)::integer AS anchor_mismatch_count
  FROM tmp_v226_context c
  JOIN msbf_ctl.m1_17_g2_bundle_registry g2
    ON g2.module1_run_id=c.module1_run_id
   AND g2.bundle_code='M1_G2_CONSUMPTION_BUNDLE'
   AND g2.bundle_version=1
   AND g2.bundle_status='ACCEPTED'
  JOIN msbf_ctl.m2_11_portfolio_strategy_contract_registry m211
    ON m211.module1_run_id=c.module1_run_id
   AND m211.contract_code='M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION'
   AND m211.contract_version=1
   AND m211.contract_status='ACCEPTED';
CREATE UNIQUE INDEX ux_tmp_v226_source_anchors ON tmp_v226_source_anchors(m1_17_bundle_code,m2_11_contract_code);
ANALYZE tmp_v226_source_anchors;

/* Consolidated findings. */
CREATE TEMP TABLE tmp_v226_findings ON COMMIT DROP AS
SELECT
  (SELECT count(*) FROM tmp_v226_source_edges WHERE edge_status<>'PASS' OR source_hash_mismatch_flag OR target_hash_mismatch_flag)::integer AS chain_findings,
  (SELECT coalesce(sum(r.payload_mismatch_count+r.missing_latest_rows+r.missing_archive_rows+r.latest_duplicate_key_rows+r.archive_duplicate_key_rows),0) FROM msbf_m2.module2_contract_reproduction_snapshot r WHERE r.module1_run_id=c.module1_run_id)::bigint AS reproduction_findings,
  ((SELECT count(*) FROM tmp_v226_hash_detail WHERE mismatch_flag)
    +(SELECT latest_row_hash_mismatches+archive_row_hash_mismatches+archive_payload_mismatches FROM tmp_v226_g3_parity))::integer AS deterministic_hash_findings,
  ((SELECT total_mismatch_count FROM tmp_v226_reconciliation)
    +(SELECT latest_row_hash_mismatches+archive_row_hash_mismatches+archive_payload_mismatches FROM tmp_v226_g3_parity))::bigint AS deterministic_total_findings,
  ((SELECT count(*) FROM tmp_v226_stage_boundary WHERE certification_status<>'PASS'
       OR duplicate_required_evidence_rows<>0 OR missing_required_evidence_codes<>''
       OR nonpass_evidence_rows<>0 OR violation_rows<>0)
    +(SELECT count(*) FROM msbf_ctl.run_evidence e WHERE e.run_id=c.module1_run_id
       AND e.evidence_code='M2_12_BLOCKING_STAGE_BOUNDARY_FINDINGS'
       AND NOT (e.segment_key='M2_12' AND e.metric_name='M2_12_BLOCKING_STAGE_BOUNDARY_FINDINGS'
                AND e.metric_value_numeric IS NULL AND e.metric_value_text='0'
                AND e.unit_code='ROWS' AND e.status='PASS' AND e.threshold_value_numeric IS NULL)))::integer AS boundary_findings,
  (SELECT count(*) FROM msbf_m2.module2_capability_coverage_snapshot x WHERE x.module1_run_id=c.module1_run_id
       AND (x.production_action_authorized_flag OR x.legal_or_regulatory_certified_flag
            OR (x.capability_sequence BETWEEN 13 AND 20 AND x.coverage_status_code LIKE 'IMPLEMENTED%')))::integer AS capability_overclaim_findings
FROM tmp_v226_context c;
ANALYZE tmp_v226_findings;

CREATE TEMP TABLE tmp_v226_summary ON COMMIT DROP AS
SELECT c.module1_run_id,c.run_code,c.run_version,c.run_status,c.contract_status,c.gate_status,
       c.contract_set_hash,c.combined_set_hash,c.row_hash AS registry_row_hash,
       e.positive_rows,e.positive_pass_rows,e.positive_distinct_codes,
       e.negative_rows,e.negative_pass_rows,e.negative_distinct_codes,
       e.generation_rows,e.generation_pass_rows,e.generation_distinct_codes,
       e.acceptance_rows,e.acceptance_pass_rows,e.nonpass_rows,
       (SELECT count(*) FROM tmp_v226_source_edges)::integer AS source_graph_rows,
       (SELECT count(*) FILTER (WHERE edge_status='PASS') FROM tmp_v226_source_edges)::integer AS source_graph_pass_rows,
       (SELECT count(*) FROM tmp_v226_stage_boundary)::integer AS stage_boundary_rows,
       (SELECT count(*) FILTER (WHERE certification_status='PASS') FROM tmp_v226_stage_boundary)::integer AS stage_boundary_pass_rows,
       (SELECT coalesce(sum(required_evidence_rows),0) FROM tmp_v226_stage_boundary)::integer AS stage_boundary_required_controls,
       (SELECT coalesce(sum(physical_required_evidence_rows),0) FROM tmp_v226_stage_boundary)::integer AS stage_boundary_physical_controls,
       (SELECT canonical_families FROM tmp_v226_reconciliation)::integer AS canonical_families,
       (SELECT canonical_entities FROM tmp_v226_reconciliation)::integer AS canonical_entities,
       (SELECT total_mismatch_count FROM tmp_v226_reconciliation)::bigint AS deterministic_mismatches,
       (SELECT parity_status FROM tmp_v226_g3_parity)::text AS g3_parity_status,
       (SELECT chain_findings FROM tmp_v226_findings)::integer AS chain_findings,
       (SELECT boundary_findings FROM tmp_v226_findings)::integer AS boundary_findings,
       x.application_rows,x.operational_rows,x.strategy_rows,x.strategy_partial_rows,x.stress_nonimprovement_pass_rows,
       CASE WHEN c.run_status='M2_12_ACCEPTED' AND c.contract_status='ACCEPTED' AND c.gate_status='PASS'
                  AND e.positive_rows=128 AND e.positive_pass_rows=128 AND e.positive_distinct_codes=128
                  AND e.negative_rows=20 AND e.negative_pass_rows=20 AND e.negative_distinct_codes=20
                  AND e.generation_rows=24 AND e.generation_pass_rows=24 AND e.generation_distinct_codes=24
                  AND e.acceptance_rows=1 AND e.acceptance_pass_rows=1 AND e.nonpass_rows=0
                  AND (SELECT count(*)=19 AND count(*) FILTER (WHERE edge_status='PASS')=19 FROM tmp_v226_source_edges)
                  AND (SELECT count(*)=12 AND count(*) FILTER (WHERE certification_status='PASS')=12
                              AND coalesce(sum(required_evidence_rows),0)=70
                              AND coalesce(sum(physical_required_evidence_rows),0)=70 FROM tmp_v226_stage_boundary)
                  AND (SELECT canonical_families=9 AND canonical_entities=134 AND total_mismatch_count=0 FROM tmp_v226_reconciliation)
                  AND (SELECT parity_status='PASS' FROM tmp_v226_g3_parity)
                  AND (SELECT chain_findings=0 AND reproduction_findings=0 AND deterministic_hash_findings=0
                              AND deterministic_total_findings=0 AND boundary_findings=0 AND capability_overclaim_findings=0
                         FROM tmp_v226_findings)
                  AND x.application_rows=1500 AND x.operational_rows=59 AND x.strategy_rows=24
                  AND x.strategy_partial_rows=24 AND x.stress_nonimprovement_pass_rows=24
             THEN 'PASS' ELSE 'FAIL' END::text AS verification_status,
       CASE WHEN c.run_status='M2_12_ACCEPTED' AND c.contract_status='ACCEPTED'
                  AND e.positive_rows=128 AND e.negative_rows=20 AND e.acceptance_rows=1
                  AND (SELECT total_mismatch_count=0 FROM tmp_v226_reconciliation)
                  AND (SELECT chain_findings=0 AND boundary_findings=0 FROM tmp_v226_findings)
             THEN 'READY_TO_EXECUTE_PROGRAM_226_HF24' ELSE 'STOP_PROGRAM_226_HF24' END::text AS disposition
FROM tmp_v226_context c CROSS JOIN tmp_v226_evidence e CROSS JOIN tmp_v226_consumption x;

DO $m212_v226_hf24_summary_gate$
DECLARE v_rows integer; v_status text;
BEGIN
    SELECT count(*),min(verification_status) INTO v_rows,v_status FROM tmp_v226_summary;
    IF v_rows<>1 OR v_status<>'PASS' THEN
       RAISE EXCEPTION USING ERRCODE='P0001',MESSAGE='Program 226 HF24 pre-execution verifier failed closed',
         DETAIL=format('rows=%s status=%s',v_rows,coalesce(v_status,'<NULL>'));
    END IF;
END;
$m212_v226_hf24_summary_gate$;

SELECT edge_sequence,edge_code,target_node_code,expected_source_hash,
       observed_accepted_source_hash,observed_target_recorded_source_hash,
       source_gate_status,source_registry_row_count,target_registry_row_count,
       source_hash_mismatch_flag,target_hash_mismatch_flag,edge_status
  FROM tmp_v226_source_edges ORDER BY edge_sequence;

SELECT node_sequence,stage_code,certification_status,acceptance_summary_pass_rows,
       acceptance_summary_rows,required_evidence_rows,physical_required_evidence_rows,
       observed_required_evidence_rows,duplicate_required_evidence_rows,
       missing_required_evidence_codes,nonpass_evidence_codes,violation_evidence_codes,
       source_relation_set,source_evidence_row_hash,observed_count_or_identity
  FROM tmp_v226_stage_boundary ORDER BY node_sequence;

SELECT hash_sequence,hash_code,stored_hash,reconstructed_hash,mismatch_flag,authoritative_source,ordered_business_key
  FROM tmp_v226_hash_detail ORDER BY hash_sequence;

SELECT positive_rows,positive_pass_rows,positive_distinct_codes,
       negative_rows,negative_pass_rows,negative_distinct_codes,
       generation_rows,generation_pass_rows,generation_distinct_codes,
       acceptance_rows,acceptance_pass_rows,nonpass_rows,gate_rows,exact_gate_rows,
       exact_acceptance_total_rows,exact_acceptance_rows
  FROM tmp_v226_evidence;

SELECT module1_run_id,run_code,run_version,run_status,contract_status,gate_status,
       contract_set_hash,combined_set_hash,registry_row_hash,
       positive_rows,positive_pass_rows,positive_distinct_codes,
       negative_rows,negative_pass_rows,negative_distinct_codes,
       generation_rows,generation_pass_rows,generation_distinct_codes,
       acceptance_rows,acceptance_pass_rows,nonpass_rows,
       source_graph_rows,source_graph_pass_rows,stage_boundary_rows,stage_boundary_pass_rows,
       stage_boundary_required_controls,stage_boundary_physical_controls,
       canonical_families,canonical_entities,deterministic_mismatches,g3_parity_status,
       chain_findings,boundary_findings,application_rows,operational_rows,strategy_rows,
       strategy_partial_rows,stress_nonimprovement_pass_rows,verification_status,disposition
  FROM tmp_v226_summary;
ROLLBACK;
