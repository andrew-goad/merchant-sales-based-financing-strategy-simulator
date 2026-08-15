/*
Recovery 223A — M2.12 Failed Positive-Validation Recovery
Source revision: WP3 R1 clean rebuild against approved WP2 Source R4
Execution status: SOURCE ONLY — NOT EXECUTED IN THIS PACKAGE

Authority boundary:
- Operates only on a diagnosed partial Program 223 evidence/lifecycle state.
- Requires the generated nine-family/134-entity canonical checkpoint and all stored hashes to remain exact.
- Deletes only partial M2_12_POS_* evidence and restores mutable validation lifecycle to GENERATED.
- Refuses complete validation, any negative or acceptance state, any G3 gate row, accepted lifecycle, or canonical/hash ambiguity.
- Performs no canonical business/hash regeneration or mutation.
*/

\set ON_ERROR_STOP on
SET client_min_messages = warning;
SET lock_timeout = '15s';
SET statement_timeout = '0';
BEGIN;
SET LOCAL search_path = pg_catalog, msbf_ctl, msbf_m1, msbf_m2;

CREATE TEMP TABLE tmp_recover_m2_12_run_context ON COMMIT DROP AS
SELECT rr.run_id::bigint AS module1_run_id,rr.run_code,rr.run_version,rr.run_status,
       p.policy_code,p.policy_version,r.registry_id,r.contract_status,r.generated_at,r.validated_at,r.accepted_at
FROM msbf_ctl.run_registry rr
JOIN msbf_ctl.m2_12_policy_profile p ON p.module1_run_id=rr.run_id
 AND p.policy_code='M2_12_ENTERPRISE_PORTFOLIO_CERTIFICATION_POLICY_V1' AND p.policy_version=1 AND p.policy_status='APPROVED'
JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=rr.run_id
 AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1
WHERE rr.run_code='M1_V0_2_BASELINE_BUILD' AND rr.run_version=1;
CREATE UNIQUE INDEX ux_tmp_recover_m2_12_run_context ON tmp_recover_m2_12_run_context(module1_run_id);
ANALYZE tmp_recover_m2_12_run_context;

CREATE TEMP TABLE tmp_hash_m2_12_recovery_reconciliation ON COMMIT DROP AS
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
WITH row_detail AS ((SELECT 'POLICY'::text AS family_code, 1::bigint AS expected_rows, count(*)::bigint AS observed_rows, (count(*)<>1)::integer AS family_count_mismatch_count, count(*) FILTER (WHERE t.row_hash IS DISTINCT FROM md5((to_jsonb(t)-'policy_profile_id'-'row_hash'-'created_at'-'updated_at')::text))::bigint AS row_hash_mismatch_count FROM msbf_ctl.m2_12_policy_profile t JOIN tmp_recover_m2_12_run_context ctx ON ctx.module1_run_id=t.module1_run_id) UNION ALL (SELECT 'STAGE_CERTIFICATION'::text AS family_code, 12::bigint AS expected_rows, count(*)::bigint AS observed_rows, (count(*)<>12)::integer AS family_count_mismatch_count, count(*) FILTER (WHERE t.row_hash IS DISTINCT FROM md5((to_jsonb(t)-'row_hash'-'created_at')::text))::bigint AS row_hash_mismatch_count FROM msbf_m2.module2_stage_certification_snapshot t JOIN tmp_recover_m2_12_run_context ctx ON ctx.module1_run_id=t.module1_run_id) UNION ALL (SELECT 'CONTRACT_COMPONENT'::text AS family_code, 13::bigint AS expected_rows, count(*)::bigint AS observed_rows, (count(*)<>13)::integer AS family_count_mismatch_count, count(*) FILTER (WHERE t.row_hash IS DISTINCT FROM md5((to_jsonb(t)-'row_hash'-'created_at')::text))::bigint AS row_hash_mismatch_count FROM msbf_m2.module2_contract_component_snapshot t JOIN tmp_recover_m2_12_run_context ctx ON ctx.module1_run_id=t.module1_run_id) UNION ALL (SELECT 'EVIDENCE_CERTIFICATION'::text AS family_code, 72::bigint AS expected_rows, count(*)::bigint AS observed_rows, (count(*)<>72)::integer AS family_count_mismatch_count, count(*) FILTER (WHERE t.row_hash IS DISTINCT FROM md5((to_jsonb(t)-'row_hash'-'created_at')::text))::bigint AS row_hash_mismatch_count FROM msbf_m2.module2_evidence_certification_snapshot t JOIN tmp_recover_m2_12_run_context ctx ON ctx.module1_run_id=t.module1_run_id) UNION ALL (SELECT 'CONTRACT_REPRODUCTION'::text AS family_code, 13::bigint AS expected_rows, count(*)::bigint AS observed_rows, (count(*)<>13)::integer AS family_count_mismatch_count, count(*) FILTER (WHERE t.row_hash IS DISTINCT FROM md5((to_jsonb(t)-'row_hash'-'created_at')::text))::bigint AS row_hash_mismatch_count FROM msbf_m2.module2_contract_reproduction_snapshot t JOIN tmp_recover_m2_12_run_context ctx ON ctx.module1_run_id=t.module1_run_id) UNION ALL (SELECT 'CAPABILITY_COVERAGE'::text AS family_code, 20::bigint AS expected_rows, count(*)::bigint AS observed_rows, (count(*)<>20)::integer AS family_count_mismatch_count, count(*) FILTER (WHERE t.row_hash IS DISTINCT FROM md5((to_jsonb(t)-'row_hash'-'created_at')::text))::bigint AS row_hash_mismatch_count FROM msbf_m2.module2_capability_coverage_snapshot t JOIN tmp_recover_m2_12_run_context ctx ON ctx.module1_run_id=t.module1_run_id) UNION ALL (SELECT 'LATEST'::text AS family_code, 1::bigint AS expected_rows, count(*)::bigint AS observed_rows, (count(*)<>1)::integer AS family_count_mismatch_count, count(*) FILTER (WHERE t.row_hash IS DISTINCT FROM md5((to_jsonb(t)-'row_hash'-'created_at')::text))::bigint AS row_hash_mismatch_count FROM msbf_ctl.m2_12_g3_bundle_latest t JOIN tmp_recover_m2_12_run_context ctx ON ctx.module1_run_id=t.module1_run_id) UNION ALL (SELECT 'ARCHIVE'::text AS family_code, 1::bigint AS expected_rows, count(*)::bigint AS observed_rows, (count(*)<>1)::integer AS family_count_mismatch_count, count(*) FILTER (WHERE t.archive_row_hash IS DISTINCT FROM md5((to_jsonb(t)-'archive_id'-'archive_row_hash'-'created_at')::text))::bigint AS row_hash_mismatch_count FROM msbf_ctl.m2_12_g3_bundle_archive t JOIN tmp_recover_m2_12_run_context ctx ON ctx.module1_run_id=t.module1_run_id) UNION ALL (SELECT 'REGISTRY'::text AS family_code, 1::bigint AS expected_rows, count(*)::bigint AS observed_rows, (count(*)<>1)::integer AS family_count_mismatch_count, count(*) FILTER (WHERE t.row_hash IS DISTINCT FROM md5((to_jsonb(t)-'registry_id'-'contract_status'-'generated_at'-'validated_at'-'accepted_at'-'created_at'-'updated_at'-'row_hash'-'policy_set_hash'-'stage_certification_set_hash'-'contract_component_set_hash'-'evidence_certification_set_hash'-'contract_reproduction_set_hash'-'capability_coverage_set_hash'-'latest_set_hash'-'archive_set_hash'-'registry_set_hash'-'contract_set_hash'-'combined_set_hash')::text))::bigint AS row_hash_mismatch_count FROM msbf_ctl.m2_12_g3_bundle_registry t JOIN tmp_recover_m2_12_run_context ctx ON ctx.module1_run_id=t.module1_run_id)),
rowd AS (SELECT sum(family_count_mismatch_count)::bigint family_count_mismatch_count,sum(row_hash_mismatch_count)::bigint row_hash_mismatch_count FROM row_detail),
set_detail AS ((SELECT 'POLICY'::text AS family_code, md5(string_agg(concat_ws('|',t.policy_code::text,t.policy_version::text,t.row_hash::text),'|' ORDER BY t.policy_code, t.policy_version))::text AS reconstructed_set_hash, r.policy_set_hash::text AS stored_set_hash, (md5(string_agg(concat_ws('|',t.policy_code::text,t.policy_version::text,t.row_hash::text),'|' ORDER BY t.policy_code, t.policy_version)) IS DISTINCT FROM r.policy_set_hash)::integer AS set_hash_mismatch_count FROM msbf_ctl.m2_12_policy_profile t JOIN tmp_recover_m2_12_run_context ctx ON ctx.module1_run_id=t.module1_run_id JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1 GROUP BY r.policy_set_hash) UNION ALL (SELECT 'STAGE_CERTIFICATION'::text AS family_code, md5(string_agg(concat_ws('|',t.certification_node_sequence::text,t.stage_code::text,t.row_hash::text),'|' ORDER BY t.certification_node_sequence, t.stage_code))::text AS reconstructed_set_hash, r.stage_certification_set_hash::text AS stored_set_hash, (md5(string_agg(concat_ws('|',t.certification_node_sequence::text,t.stage_code::text,t.row_hash::text),'|' ORDER BY t.certification_node_sequence, t.stage_code)) IS DISTINCT FROM r.stage_certification_set_hash)::integer AS set_hash_mismatch_count FROM msbf_m2.module2_stage_certification_snapshot t JOIN tmp_recover_m2_12_run_context ctx ON ctx.module1_run_id=t.module1_run_id JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1 GROUP BY r.stage_certification_set_hash) UNION ALL (SELECT 'CONTRACT_COMPONENT'::text AS family_code, md5(string_agg(concat_ws('|',t.component_sequence::text,t.component_contract_code::text,t.contract_version::text,t.row_hash::text),'|' ORDER BY t.component_sequence, t.component_contract_code, t.contract_version))::text AS reconstructed_set_hash, r.contract_component_set_hash::text AS stored_set_hash, (md5(string_agg(concat_ws('|',t.component_sequence::text,t.component_contract_code::text,t.contract_version::text,t.row_hash::text),'|' ORDER BY t.component_sequence, t.component_contract_code, t.contract_version)) IS DISTINCT FROM r.contract_component_set_hash)::integer AS set_hash_mismatch_count FROM msbf_m2.module2_contract_component_snapshot t JOIN tmp_recover_m2_12_run_context ctx ON ctx.module1_run_id=t.module1_run_id JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1 GROUP BY r.contract_component_set_hash) UNION ALL (SELECT 'EVIDENCE_CERTIFICATION'::text AS family_code, md5(string_agg(concat_ws('|',t.node_sequence::text,t.evidence_family_sequence::text,t.evidence_family_code::text,t.row_hash::text),'|' ORDER BY t.node_sequence, t.evidence_family_sequence, t.evidence_family_code))::text AS reconstructed_set_hash, r.evidence_certification_set_hash::text AS stored_set_hash, (md5(string_agg(concat_ws('|',t.node_sequence::text,t.evidence_family_sequence::text,t.evidence_family_code::text,t.row_hash::text),'|' ORDER BY t.node_sequence, t.evidence_family_sequence, t.evidence_family_code)) IS DISTINCT FROM r.evidence_certification_set_hash)::integer AS set_hash_mismatch_count FROM msbf_m2.module2_evidence_certification_snapshot t JOIN tmp_recover_m2_12_run_context ctx ON ctx.module1_run_id=t.module1_run_id JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1 GROUP BY r.evidence_certification_set_hash) UNION ALL (SELECT 'CONTRACT_REPRODUCTION'::text AS family_code, md5(string_agg(concat_ws('|',t.component_sequence::text,t.component_contract_code::text,t.contract_version::text,t.row_hash::text),'|' ORDER BY t.component_sequence, t.component_contract_code, t.contract_version))::text AS reconstructed_set_hash, r.contract_reproduction_set_hash::text AS stored_set_hash, (md5(string_agg(concat_ws('|',t.component_sequence::text,t.component_contract_code::text,t.contract_version::text,t.row_hash::text),'|' ORDER BY t.component_sequence, t.component_contract_code, t.contract_version)) IS DISTINCT FROM r.contract_reproduction_set_hash)::integer AS set_hash_mismatch_count FROM msbf_m2.module2_contract_reproduction_snapshot t JOIN tmp_recover_m2_12_run_context ctx ON ctx.module1_run_id=t.module1_run_id JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1 GROUP BY r.contract_reproduction_set_hash) UNION ALL (SELECT 'CAPABILITY_COVERAGE'::text AS family_code, md5(string_agg(concat_ws('|',t.capability_sequence::text,t.capability_code::text,t.row_hash::text),'|' ORDER BY t.capability_sequence, t.capability_code))::text AS reconstructed_set_hash, r.capability_coverage_set_hash::text AS stored_set_hash, (md5(string_agg(concat_ws('|',t.capability_sequence::text,t.capability_code::text,t.row_hash::text),'|' ORDER BY t.capability_sequence, t.capability_code)) IS DISTINCT FROM r.capability_coverage_set_hash)::integer AS set_hash_mismatch_count FROM msbf_m2.module2_capability_coverage_snapshot t JOIN tmp_recover_m2_12_run_context ctx ON ctx.module1_run_id=t.module1_run_id JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1 GROUP BY r.capability_coverage_set_hash) UNION ALL (SELECT 'LATEST'::text AS family_code, md5(string_agg(concat_ws('|',t.bundle_code::text,t.contract_version::text,t.row_hash::text),'|' ORDER BY t.bundle_code, t.contract_version))::text AS reconstructed_set_hash, r.latest_set_hash::text AS stored_set_hash, (md5(string_agg(concat_ws('|',t.bundle_code::text,t.contract_version::text,t.row_hash::text),'|' ORDER BY t.bundle_code, t.contract_version)) IS DISTINCT FROM r.latest_set_hash)::integer AS set_hash_mismatch_count FROM msbf_ctl.m2_12_g3_bundle_latest t JOIN tmp_recover_m2_12_run_context ctx ON ctx.module1_run_id=t.module1_run_id JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1 GROUP BY r.latest_set_hash) UNION ALL (SELECT 'ARCHIVE'::text AS family_code, md5(string_agg(concat_ws('|',t.bundle_code::text,t.contract_version::text,t.archive_row_hash::text),'|' ORDER BY t.bundle_code, t.contract_version))::text AS reconstructed_set_hash, r.archive_set_hash::text AS stored_set_hash, (md5(string_agg(concat_ws('|',t.bundle_code::text,t.contract_version::text,t.archive_row_hash::text),'|' ORDER BY t.bundle_code, t.contract_version)) IS DISTINCT FROM r.archive_set_hash)::integer AS set_hash_mismatch_count FROM msbf_ctl.m2_12_g3_bundle_archive t JOIN tmp_recover_m2_12_run_context ctx ON ctx.module1_run_id=t.module1_run_id JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1 GROUP BY r.archive_set_hash) UNION ALL (SELECT 'REGISTRY'::text AS family_code, md5(string_agg(concat_ws('|',t.bundle_code::text,t.contract_version::text,t.row_hash::text),'|' ORDER BY t.bundle_code, t.contract_version))::text AS reconstructed_set_hash, r.registry_set_hash::text AS stored_set_hash, (md5(string_agg(concat_ws('|',t.bundle_code::text,t.contract_version::text,t.row_hash::text),'|' ORDER BY t.bundle_code, t.contract_version)) IS DISTINCT FROM r.registry_set_hash)::integer AS set_hash_mismatch_count FROM msbf_ctl.m2_12_g3_bundle_registry t JOIN tmp_recover_m2_12_run_context ctx ON ctx.module1_run_id=t.module1_run_id JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1 GROUP BY r.registry_set_hash)),
setd AS (SELECT sum(set_hash_mismatch_count)::bigint set_hash_mismatch_count FROM set_detail),
ch AS (SELECT r.module1_run_id,
       md5(concat_ws('|',r.bundle_code::text,r.contract_version::text,r.schema_version::text,r.methodology_version::text,r.policy_configuration_hash::text,r.policy_set_hash::text,r.stage_certification_set_hash::text,r.contract_component_set_hash::text,r.evidence_certification_set_hash::text,r.contract_reproduction_set_hash::text,r.capability_coverage_set_hash::text,r.latest_set_hash::text,r.archive_set_hash::text,r.registry_set_hash::text,r.latest_contract_row_hash::text,r.archive_contract_row_hash::text,r.row_hash::text,r.accepted_m2_11_contract_set_hash::text,r.accepted_m2_11_combined_set_hash::text,r.accepted_m2_11_registry_row_hash::text))::text AS reconstructed_contract_set_hash,
       r.contract_set_hash::text AS stored_contract_set_hash,
       (md5(concat_ws('|',r.bundle_code::text,r.contract_version::text,r.schema_version::text,r.methodology_version::text,r.policy_configuration_hash::text,r.policy_set_hash::text,r.stage_certification_set_hash::text,r.contract_component_set_hash::text,r.evidence_certification_set_hash::text,r.contract_reproduction_set_hash::text,r.capability_coverage_set_hash::text,r.latest_set_hash::text,r.archive_set_hash::text,r.registry_set_hash::text,r.latest_contract_row_hash::text,r.archive_contract_row_hash::text,r.row_hash::text,r.accepted_m2_11_contract_set_hash::text,r.accepted_m2_11_combined_set_hash::text,r.accepted_m2_11_registry_row_hash::text)) IS DISTINCT FROM r.contract_set_hash)::integer AS contract_hash_mismatch_count
FROM msbf_ctl.m2_12_g3_bundle_registry r
JOIN tmp_recover_m2_12_run_context ctx ON ctx.module1_run_id=r.module1_run_id
WHERE r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1), cb AS (SELECT u.module1_run_id, count(*)::integer AS canonical_entities, count(DISTINCT u.entity_type)::integer AS canonical_families, md5(string_agg(u.entity_type||'|'||u.entity_key||'|'||u.row_hash,'|' ORDER BY u.entity_type,u.entity_key))::text AS reconstructed_combined_set_hash, r.combined_set_hash::text AS stored_combined_set_hash, (md5(string_agg(u.entity_type||'|'||u.entity_key||'|'||u.row_hash,'|' ORDER BY u.entity_type,u.entity_key)) IS DISTINCT FROM r.combined_set_hash)::integer AS combined_hash_mismatch_count FROM (SELECT t.module1_run_id, 'POLICY'::text AS entity_type, concat_ws('|',t.policy_code::text,t.policy_version::text)::text AS entity_key, t.row_hash::text AS row_hash FROM msbf_ctl.m2_12_policy_profile t JOIN tmp_recover_m2_12_run_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT t.module1_run_id, 'STAGE_CERTIFICATION'::text AS entity_type, concat_ws('|',t.certification_node_sequence::text,t.stage_code::text)::text AS entity_key, t.row_hash::text AS row_hash FROM msbf_m2.module2_stage_certification_snapshot t JOIN tmp_recover_m2_12_run_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT t.module1_run_id, 'CONTRACT_COMPONENT'::text AS entity_type, concat_ws('|',t.component_sequence::text,t.component_contract_code::text,t.contract_version::text)::text AS entity_key, t.row_hash::text AS row_hash FROM msbf_m2.module2_contract_component_snapshot t JOIN tmp_recover_m2_12_run_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT t.module1_run_id, 'EVIDENCE_CERTIFICATION'::text AS entity_type, concat_ws('|',t.node_sequence::text,t.evidence_family_sequence::text,t.evidence_family_code::text)::text AS entity_key, t.row_hash::text AS row_hash FROM msbf_m2.module2_evidence_certification_snapshot t JOIN tmp_recover_m2_12_run_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT t.module1_run_id, 'CONTRACT_REPRODUCTION'::text AS entity_type, concat_ws('|',t.component_sequence::text,t.component_contract_code::text,t.contract_version::text)::text AS entity_key, t.row_hash::text AS row_hash FROM msbf_m2.module2_contract_reproduction_snapshot t JOIN tmp_recover_m2_12_run_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT t.module1_run_id, 'CAPABILITY_COVERAGE'::text AS entity_type, concat_ws('|',t.capability_sequence::text,t.capability_code::text)::text AS entity_key, t.row_hash::text AS row_hash FROM msbf_m2.module2_capability_coverage_snapshot t JOIN tmp_recover_m2_12_run_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT t.module1_run_id, 'LATEST'::text AS entity_type, concat_ws('|',t.bundle_code::text,t.contract_version::text)::text AS entity_key, t.row_hash::text AS row_hash FROM msbf_ctl.m2_12_g3_bundle_latest t JOIN tmp_recover_m2_12_run_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT t.module1_run_id, 'ARCHIVE'::text AS entity_type, concat_ws('|',t.bundle_code::text,t.contract_version::text)::text AS entity_key, t.archive_row_hash::text AS row_hash FROM msbf_ctl.m2_12_g3_bundle_archive t JOIN tmp_recover_m2_12_run_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT t.module1_run_id, 'REGISTRY'::text AS entity_type, concat_ws('|',t.bundle_code::text,t.contract_version::text)::text AS entity_key, t.row_hash::text AS row_hash FROM msbf_ctl.m2_12_g3_bundle_registry t JOIN tmp_recover_m2_12_run_context ctx ON ctx.module1_run_id=t.module1_run_id) u JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=u.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1 GROUP BY u.module1_run_id,r.combined_set_hash), seq AS (SELECT ctx.module1_run_id,
       p.last_value::bigint AS policy_last_value,p.is_called AS policy_is_called,
       a.last_value::bigint AS archive_last_value,a.is_called AS archive_is_called,
       r.last_value::bigint AS registry_last_value,r.is_called AS registry_is_called,
       ((p.last_value<>1 OR NOT p.is_called)::integer
        +(a.last_value<>1 OR NOT a.is_called)::integer
        +(r.last_value<>1 OR NOT r.is_called)::integer)::integer AS sequence_state_mismatch_count
FROM tmp_recover_m2_12_run_context ctx
CROSS JOIN msbf_ctl.m2_12_policy_profile_policy_profile_id_seq p
CROSS JOIN msbf_ctl.m2_12_g3_bundle_archive_archive_id_seq a
CROSS JOIN msbf_ctl.m2_12_g3_bundle_registry_registry_id_seq r)
SELECT ctx.module1_run_id,
       rowd.family_count_mismatch_count,rowd.row_hash_mismatch_count,setd.set_hash_mismatch_count,
       ch.contract_hash_mismatch_count::integer,cb.combined_hash_mismatch_count::integer,
       seq.sequence_state_mismatch_count::integer,cb.canonical_families::integer,cb.canonical_entities::integer,
       (rowd.family_count_mismatch_count+rowd.row_hash_mismatch_count+setd.set_hash_mismatch_count+ch.contract_hash_mismatch_count+cb.combined_hash_mismatch_count+seq.sequence_state_mismatch_count)::bigint AS total_mismatch_count
FROM tmp_recover_m2_12_run_context ctx CROSS JOIN rowd CROSS JOIN setd CROSS JOIN ch CROSS JOIN cb CROSS JOIN seq
) p;;
CREATE UNIQUE INDEX ux_tmp_hash_m2_12_recovery_reconciliation ON tmp_hash_m2_12_recovery_reconciliation(module1_run_id);
ANALYZE tmp_hash_m2_12_recovery_reconciliation;


CREATE TEMP VIEW tmp_hash_m2_12_recovery_current_fingerprint AS
WITH canonical_rows AS (
    SELECT 'POLICY'::text AS family_code,
           concat_ws('|',p.policy_code,p.policy_version::text)::text AS business_key,
           p.row_hash::text AS row_hash
    FROM msbf_ctl.m2_12_policy_profile p
    JOIN tmp_recover_m2_12_run_context ctx ON ctx.module1_run_id=p.module1_run_id
    UNION ALL
    SELECT 'STAGE_CERTIFICATION',concat_ws('|',s.certification_node_sequence::text,s.stage_code),s.row_hash
    FROM msbf_m2.module2_stage_certification_snapshot s
    JOIN tmp_recover_m2_12_run_context ctx ON ctx.module1_run_id=s.module1_run_id
    UNION ALL
    SELECT 'CONTRACT_COMPONENT',concat_ws('|',c.component_sequence::text,c.component_contract_code,c.contract_version::text),c.row_hash
    FROM msbf_m2.module2_contract_component_snapshot c
    JOIN tmp_recover_m2_12_run_context ctx ON ctx.module1_run_id=c.module1_run_id
    UNION ALL
    SELECT 'EVIDENCE_CERTIFICATION',concat_ws('|',e.node_sequence::text,e.evidence_family_sequence::text,e.evidence_family_code),e.row_hash
    FROM msbf_m2.module2_evidence_certification_snapshot e
    JOIN tmp_recover_m2_12_run_context ctx ON ctx.module1_run_id=e.module1_run_id
    UNION ALL
    SELECT 'CONTRACT_REPRODUCTION',concat_ws('|',r.component_sequence::text,r.component_contract_code,r.contract_version::text),r.row_hash
    FROM msbf_m2.module2_contract_reproduction_snapshot r
    JOIN tmp_recover_m2_12_run_context ctx ON ctx.module1_run_id=r.module1_run_id
    UNION ALL
    SELECT 'CAPABILITY_COVERAGE',concat_ws('|',c.capability_sequence::text,c.capability_code),c.row_hash
    FROM msbf_m2.module2_capability_coverage_snapshot c
    JOIN tmp_recover_m2_12_run_context ctx ON ctx.module1_run_id=c.module1_run_id
    UNION ALL
    SELECT 'LATEST',concat_ws('|',l.bundle_code,l.contract_version::text),l.row_hash
    FROM msbf_ctl.m2_12_g3_bundle_latest l
    JOIN tmp_recover_m2_12_run_context ctx ON ctx.module1_run_id=l.module1_run_id
    UNION ALL
    SELECT 'ARCHIVE',concat_ws('|',a.bundle_code,a.contract_version::text),a.archive_row_hash
    FROM msbf_ctl.m2_12_g3_bundle_archive a
    JOIN tmp_recover_m2_12_run_context ctx ON ctx.module1_run_id=a.module1_run_id
    UNION ALL
    SELECT 'REGISTRY',concat_ws('|',g.bundle_code,g.contract_version::text),g.row_hash
    FROM msbf_ctl.m2_12_g3_bundle_registry g
    JOIN tmp_recover_m2_12_run_context ctx ON ctx.module1_run_id=g.module1_run_id
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
    JOIN tmp_recover_m2_12_run_context ctx ON ctx.module1_run_id=g.module1_run_id
    WHERE g.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND g.contract_version=1
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
    JOIN tmp_recover_m2_12_run_context ctx ON ctx.module1_run_id=rr.run_id
    JOIN msbf_ctl.m2_12_g3_bundle_registry g ON g.module1_run_id=rr.run_id
       AND g.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND g.contract_version=1
)
SELECT c.canonical_family_count,c.canonical_entity_count,c.canonical_fingerprint,
       h.stored_hash_fingerprint,s.sequence_fingerprint,l.lifecycle_fingerprint
FROM canonical c CROSS JOIN stored_hashes h CROSS JOIN sequences s CROSS JOIN lifecycle l;

CREATE TEMP TABLE tmp_hash_m2_12_recovery_baseline ON COMMIT DROP AS
SELECT * FROM tmp_hash_m2_12_recovery_current_fingerprint;
CREATE UNIQUE INDEX ux_tmp_hash_m2_12_recovery_baseline ON tmp_hash_m2_12_recovery_baseline(canonical_entity_count);
ANALYZE tmp_hash_m2_12_recovery_baseline;

CREATE TEMP TABLE tmp_recover_m2_12_diagnosis ON COMMIT PRESERVE ROWS AS
WITH evidence AS (
 SELECT count(*) FILTER (WHERE e.evidence_code LIKE 'M2_12_POS_%')::integer positive_rows,
        count(*) FILTER (WHERE e.evidence_code LIKE 'M2_12_POS_%' AND e.status='PASS')::integer positive_pass,
        count(DISTINCT e.evidence_code) FILTER (WHERE e.evidence_code LIKE 'M2_12_POS_%')::integer positive_codes,
        count(*) FILTER (WHERE e.evidence_code LIKE 'M2_12_NEG_%')::integer negative_rows,
        count(*) FILTER (WHERE e.evidence_code='M2_12_ACCEPTANCE_SUMMARY')::integer acceptance_rows,
        count(*) FILTER (WHERE e.evidence_code IN ('M2_12_POLICY_SET_HASH','M2_12_STAGE_CERTIFICATION_SET_HASH','M2_12_CONTRACT_COMPONENT_SET_HASH','M2_12_EVIDENCE_CERTIFICATION_SET_HASH','M2_12_CONTRACT_REPRODUCTION_SET_HASH','M2_12_CAPABILITY_COVERAGE_SET_HASH','M2_12_LATEST_SET_HASH','M2_12_ARCHIVE_SET_HASH','M2_12_REGISTRY_SET_HASH','M2_12_CONTRACT_SET_HASH','M2_12_COMBINED_SET_HASH','M2_12_STAGE_CERTIFICATION_ROWS','M2_12_CONTRACT_COMPONENT_ROWS','M2_12_EVIDENCE_CERTIFICATION_ROWS','M2_12_CONTRACT_REPRODUCTION_ROWS','M2_12_CAPABILITY_COVERAGE_ROWS','M2_12_CANONICAL_ENTITIES','M2_12_COMPONENT_LATEST_ARCHIVE_ROWS_TOTAL','M2_12_APPLICATION_CONSUMPTION_ROWS','M2_12_OPERATIONAL_ACCOUNT_CONSUMPTION_ROWS','M2_12_STRATEGY_SCOPE_CONSUMPTION_ROWS','M2_12_SOURCE_GRAPH_EDGES','M2_12_DETERMINISTIC_MISMATCHES','M2_12_BLOCKING_STAGE_BOUNDARY_FINDINGS') AND e.status='PASS')::integer generation_pass,
        count(DISTINCT e.evidence_code) FILTER (WHERE e.evidence_code IN ('M2_12_POLICY_SET_HASH','M2_12_STAGE_CERTIFICATION_SET_HASH','M2_12_CONTRACT_COMPONENT_SET_HASH','M2_12_EVIDENCE_CERTIFICATION_SET_HASH','M2_12_CONTRACT_REPRODUCTION_SET_HASH','M2_12_CAPABILITY_COVERAGE_SET_HASH','M2_12_LATEST_SET_HASH','M2_12_ARCHIVE_SET_HASH','M2_12_REGISTRY_SET_HASH','M2_12_CONTRACT_SET_HASH','M2_12_COMBINED_SET_HASH','M2_12_STAGE_CERTIFICATION_ROWS','M2_12_CONTRACT_COMPONENT_ROWS','M2_12_EVIDENCE_CERTIFICATION_ROWS','M2_12_CONTRACT_REPRODUCTION_ROWS','M2_12_CAPABILITY_COVERAGE_ROWS','M2_12_CANONICAL_ENTITIES','M2_12_COMPONENT_LATEST_ARCHIVE_ROWS_TOTAL','M2_12_APPLICATION_CONSUMPTION_ROWS','M2_12_OPERATIONAL_ACCOUNT_CONSUMPTION_ROWS','M2_12_STRATEGY_SCOPE_CONSUMPTION_ROWS','M2_12_SOURCE_GRAPH_EDGES','M2_12_DETERMINISTIC_MISMATCHES','M2_12_BLOCKING_STAGE_BOUNDARY_FINDINGS') AND e.status='PASS')::integer generation_codes
 FROM msbf_ctl.run_evidence e JOIN tmp_recover_m2_12_run_context ctx ON ctx.module1_run_id=e.run_id
), gate AS (
 SELECT count(*)::integer gate_rows FROM msbf_ctl.acceptance_gate_result g
 JOIN tmp_recover_m2_12_run_context ctx ON ctx.module1_run_id=g.run_id WHERE g.gate_id='G3_M2_CONTRACT'
), canonical AS (
 SELECT count(*)::integer reconciliation_rows,
        count(*) FILTER (WHERE total_mismatch_count=0 AND canonical_families=9 AND canonical_entities=134 AND reconciliation_status='PASS')::integer exact_rows
 FROM tmp_hash_m2_12_recovery_reconciliation
)
SELECT ctx.module1_run_id,ctx.run_status,ctx.contract_status,ctx.generated_at,ctx.validated_at,ctx.accepted_at,
       e.positive_rows,e.positive_pass,e.positive_codes,e.negative_rows,e.acceptance_rows,e.generation_pass,e.generation_codes,
       g.gate_rows,c.reconciliation_rows,c.exact_rows,
       CASE WHEN (ctx.run_status IN ('M2_12_GENERATED','M2_12_VALIDATED'))
                  AND (ctx.contract_status IN ('GENERATED','VALIDATED'))
                  AND ctx.generated_at IS NOT NULL AND ctx.accepted_at IS NULL
                  AND e.generation_pass=24 AND e.generation_codes=24
                  AND e.positive_rows<128
                  AND (e.positive_rows>0 OR ctx.run_status='M2_12_VALIDATED' OR ctx.contract_status='VALIDATED'
                       OR (ctx.run_status='M2_12_GENERATED') IS DISTINCT FROM (ctx.contract_status='GENERATED'))
                  AND e.negative_rows=0 AND e.acceptance_rows=0 AND g.gate_rows=0
                  AND c.reconciliation_rows=1 AND c.exact_rows=1
                  AND (SELECT canonical_family_count=9 AND canonical_entity_count=134 FROM tmp_hash_m2_12_recovery_baseline)
            THEN 'RECOVERABLE_PARTIAL_223'
            ELSE 'REFUSE' END AS diagnosis_status
FROM tmp_recover_m2_12_run_context ctx CROSS JOIN evidence e CROSS JOIN gate g CROSS JOIN canonical c;

DO $m212_p223a_precondition$
BEGIN
  IF (SELECT count(*) FROM tmp_recover_m2_12_diagnosis)<>1
     OR (SELECT diagnosis_status FROM tmp_recover_m2_12_diagnosis)<>'RECOVERABLE_PARTIAL_223' THEN
    RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 Recovery 223A refused nonrecoverable or ambiguous state';
  END IF;
  IF (SELECT positive_rows FROM tmp_recover_m2_12_diagnosis)>=128
     OR (SELECT negative_rows FROM tmp_recover_m2_12_diagnosis)<>0
     OR (SELECT acceptance_rows FROM tmp_recover_m2_12_diagnosis)<>0
     OR (SELECT gate_rows FROM tmp_recover_m2_12_diagnosis)<>0 THEN
    RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 Recovery 223A cannot run after complete validation, negative controls, or acceptance state';
  END IF;
  IF NOT ((SELECT last_value=1 AND is_called FROM msbf_ctl.m2_12_policy_profile_policy_profile_id_seq)
      AND (SELECT last_value=1 AND is_called FROM msbf_ctl.m2_12_g3_bundle_archive_archive_id_seq)
      AND (SELECT last_value=1 AND is_called FROM msbf_ctl.m2_12_g3_bundle_registry_registry_id_seq)) THEN
    RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 Recovery 223A owned-sequence checkpoint is not exact';
  END IF;
END;
$m212_p223a_precondition$;

CREATE TEMP TABLE tmp_recover_m2_12_mutation_ledger
(
 mutation_sequence smallint PRIMARY KEY,
 mutation_code text UNIQUE NOT NULL,
 expected_rows integer NOT NULL,
 affected_rows integer NOT NULL,
 status text NOT NULL
) ON COMMIT PRESERVE ROWS;

DO $m212_p223a_delete_partial_evidence$
DECLARE
  v_expected integer;
  v_affected integer;
BEGIN
  SELECT positive_rows INTO v_expected FROM tmp_recover_m2_12_diagnosis;
  DELETE FROM msbf_ctl.run_evidence e
   USING tmp_recover_m2_12_run_context ctx
   WHERE e.run_id=ctx.module1_run_id AND e.evidence_code LIKE 'M2_12_POS_%';
  GET DIAGNOSTICS v_affected=ROW_COUNT;
  INSERT INTO tmp_recover_m2_12_mutation_ledger
  VALUES (1,'DELETE_PARTIAL_POSITIVE_EVIDENCE',v_expected,v_affected,CASE WHEN v_affected=v_expected THEN 'PASS' ELSE 'FAIL' END);
  IF v_affected<>v_expected THEN
    RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 Recovery 223A partial positive-evidence delete count mismatch';
  END IF;
END;
$m212_p223a_delete_partial_evidence$;

DO $m212_p223a_restore_registry$
DECLARE v_affected integer;
BEGIN
  UPDATE msbf_ctl.m2_12_g3_bundle_registry r
     SET contract_status='GENERATED',validated_at=NULL,accepted_at=NULL,updated_at=clock_timestamp()
    FROM tmp_recover_m2_12_run_context ctx
   WHERE r.module1_run_id=ctx.module1_run_id
     AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1
     AND r.contract_status IN ('GENERATED','VALIDATED')
     AND r.generated_at IS NOT NULL AND r.accepted_at IS NULL;
  GET DIAGNOSTICS v_affected=ROW_COUNT;
  INSERT INTO tmp_recover_m2_12_mutation_ledger
  VALUES (2,'RESTORE_REGISTRY_TO_GENERATED',1,v_affected,CASE WHEN v_affected=1 THEN 'PASS' ELSE 'FAIL' END);
  IF v_affected<>1 THEN
    RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 Recovery 223A registry lifecycle restoration affected an unexpected row count';
  END IF;
END;
$m212_p223a_restore_registry$;

DO $m212_p223a_restore_run$
DECLARE v_affected integer;
BEGIN
  UPDATE msbf_ctl.run_registry rr
     SET run_status='M2_12_GENERATED'
    FROM tmp_recover_m2_12_run_context ctx
   WHERE rr.run_id=ctx.module1_run_id AND rr.run_code='M1_V0_2_BASELINE_BUILD' AND rr.run_version=1
     AND rr.run_status IN ('M2_12_GENERATED','M2_12_VALIDATED');
  GET DIAGNOSTICS v_affected=ROW_COUNT;
  INSERT INTO tmp_recover_m2_12_mutation_ledger
  VALUES (3,'RESTORE_RUN_TO_M2_12_GENERATED',1,v_affected,CASE WHEN v_affected=1 THEN 'PASS' ELSE 'FAIL' END);
  IF v_affected<>1 THEN
    RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 Recovery 223A run lifecycle restoration affected an unexpected row count';
  END IF;
END;
$m212_p223a_restore_run$;

CREATE TEMP TABLE tmp_hash_m2_12_recovery_postflight ON COMMIT DROP AS
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
WITH row_detail AS ((SELECT 'POLICY'::text AS family_code, 1::bigint AS expected_rows, count(*)::bigint AS observed_rows, (count(*)<>1)::integer AS family_count_mismatch_count, count(*) FILTER (WHERE t.row_hash IS DISTINCT FROM md5((to_jsonb(t)-'policy_profile_id'-'row_hash'-'created_at'-'updated_at')::text))::bigint AS row_hash_mismatch_count FROM msbf_ctl.m2_12_policy_profile t JOIN tmp_recover_m2_12_run_context ctx ON ctx.module1_run_id=t.module1_run_id) UNION ALL (SELECT 'STAGE_CERTIFICATION'::text AS family_code, 12::bigint AS expected_rows, count(*)::bigint AS observed_rows, (count(*)<>12)::integer AS family_count_mismatch_count, count(*) FILTER (WHERE t.row_hash IS DISTINCT FROM md5((to_jsonb(t)-'row_hash'-'created_at')::text))::bigint AS row_hash_mismatch_count FROM msbf_m2.module2_stage_certification_snapshot t JOIN tmp_recover_m2_12_run_context ctx ON ctx.module1_run_id=t.module1_run_id) UNION ALL (SELECT 'CONTRACT_COMPONENT'::text AS family_code, 13::bigint AS expected_rows, count(*)::bigint AS observed_rows, (count(*)<>13)::integer AS family_count_mismatch_count, count(*) FILTER (WHERE t.row_hash IS DISTINCT FROM md5((to_jsonb(t)-'row_hash'-'created_at')::text))::bigint AS row_hash_mismatch_count FROM msbf_m2.module2_contract_component_snapshot t JOIN tmp_recover_m2_12_run_context ctx ON ctx.module1_run_id=t.module1_run_id) UNION ALL (SELECT 'EVIDENCE_CERTIFICATION'::text AS family_code, 72::bigint AS expected_rows, count(*)::bigint AS observed_rows, (count(*)<>72)::integer AS family_count_mismatch_count, count(*) FILTER (WHERE t.row_hash IS DISTINCT FROM md5((to_jsonb(t)-'row_hash'-'created_at')::text))::bigint AS row_hash_mismatch_count FROM msbf_m2.module2_evidence_certification_snapshot t JOIN tmp_recover_m2_12_run_context ctx ON ctx.module1_run_id=t.module1_run_id) UNION ALL (SELECT 'CONTRACT_REPRODUCTION'::text AS family_code, 13::bigint AS expected_rows, count(*)::bigint AS observed_rows, (count(*)<>13)::integer AS family_count_mismatch_count, count(*) FILTER (WHERE t.row_hash IS DISTINCT FROM md5((to_jsonb(t)-'row_hash'-'created_at')::text))::bigint AS row_hash_mismatch_count FROM msbf_m2.module2_contract_reproduction_snapshot t JOIN tmp_recover_m2_12_run_context ctx ON ctx.module1_run_id=t.module1_run_id) UNION ALL (SELECT 'CAPABILITY_COVERAGE'::text AS family_code, 20::bigint AS expected_rows, count(*)::bigint AS observed_rows, (count(*)<>20)::integer AS family_count_mismatch_count, count(*) FILTER (WHERE t.row_hash IS DISTINCT FROM md5((to_jsonb(t)-'row_hash'-'created_at')::text))::bigint AS row_hash_mismatch_count FROM msbf_m2.module2_capability_coverage_snapshot t JOIN tmp_recover_m2_12_run_context ctx ON ctx.module1_run_id=t.module1_run_id) UNION ALL (SELECT 'LATEST'::text AS family_code, 1::bigint AS expected_rows, count(*)::bigint AS observed_rows, (count(*)<>1)::integer AS family_count_mismatch_count, count(*) FILTER (WHERE t.row_hash IS DISTINCT FROM md5((to_jsonb(t)-'row_hash'-'created_at')::text))::bigint AS row_hash_mismatch_count FROM msbf_ctl.m2_12_g3_bundle_latest t JOIN tmp_recover_m2_12_run_context ctx ON ctx.module1_run_id=t.module1_run_id) UNION ALL (SELECT 'ARCHIVE'::text AS family_code, 1::bigint AS expected_rows, count(*)::bigint AS observed_rows, (count(*)<>1)::integer AS family_count_mismatch_count, count(*) FILTER (WHERE t.archive_row_hash IS DISTINCT FROM md5((to_jsonb(t)-'archive_id'-'archive_row_hash'-'created_at')::text))::bigint AS row_hash_mismatch_count FROM msbf_ctl.m2_12_g3_bundle_archive t JOIN tmp_recover_m2_12_run_context ctx ON ctx.module1_run_id=t.module1_run_id) UNION ALL (SELECT 'REGISTRY'::text AS family_code, 1::bigint AS expected_rows, count(*)::bigint AS observed_rows, (count(*)<>1)::integer AS family_count_mismatch_count, count(*) FILTER (WHERE t.row_hash IS DISTINCT FROM md5((to_jsonb(t)-'registry_id'-'contract_status'-'generated_at'-'validated_at'-'accepted_at'-'created_at'-'updated_at'-'row_hash'-'policy_set_hash'-'stage_certification_set_hash'-'contract_component_set_hash'-'evidence_certification_set_hash'-'contract_reproduction_set_hash'-'capability_coverage_set_hash'-'latest_set_hash'-'archive_set_hash'-'registry_set_hash'-'contract_set_hash'-'combined_set_hash')::text))::bigint AS row_hash_mismatch_count FROM msbf_ctl.m2_12_g3_bundle_registry t JOIN tmp_recover_m2_12_run_context ctx ON ctx.module1_run_id=t.module1_run_id)),
rowd AS (SELECT sum(family_count_mismatch_count)::bigint family_count_mismatch_count,sum(row_hash_mismatch_count)::bigint row_hash_mismatch_count FROM row_detail),
set_detail AS ((SELECT 'POLICY'::text AS family_code, md5(string_agg(concat_ws('|',t.policy_code::text,t.policy_version::text,t.row_hash::text),'|' ORDER BY t.policy_code, t.policy_version))::text AS reconstructed_set_hash, r.policy_set_hash::text AS stored_set_hash, (md5(string_agg(concat_ws('|',t.policy_code::text,t.policy_version::text,t.row_hash::text),'|' ORDER BY t.policy_code, t.policy_version)) IS DISTINCT FROM r.policy_set_hash)::integer AS set_hash_mismatch_count FROM msbf_ctl.m2_12_policy_profile t JOIN tmp_recover_m2_12_run_context ctx ON ctx.module1_run_id=t.module1_run_id JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1 GROUP BY r.policy_set_hash) UNION ALL (SELECT 'STAGE_CERTIFICATION'::text AS family_code, md5(string_agg(concat_ws('|',t.certification_node_sequence::text,t.stage_code::text,t.row_hash::text),'|' ORDER BY t.certification_node_sequence, t.stage_code))::text AS reconstructed_set_hash, r.stage_certification_set_hash::text AS stored_set_hash, (md5(string_agg(concat_ws('|',t.certification_node_sequence::text,t.stage_code::text,t.row_hash::text),'|' ORDER BY t.certification_node_sequence, t.stage_code)) IS DISTINCT FROM r.stage_certification_set_hash)::integer AS set_hash_mismatch_count FROM msbf_m2.module2_stage_certification_snapshot t JOIN tmp_recover_m2_12_run_context ctx ON ctx.module1_run_id=t.module1_run_id JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1 GROUP BY r.stage_certification_set_hash) UNION ALL (SELECT 'CONTRACT_COMPONENT'::text AS family_code, md5(string_agg(concat_ws('|',t.component_sequence::text,t.component_contract_code::text,t.contract_version::text,t.row_hash::text),'|' ORDER BY t.component_sequence, t.component_contract_code, t.contract_version))::text AS reconstructed_set_hash, r.contract_component_set_hash::text AS stored_set_hash, (md5(string_agg(concat_ws('|',t.component_sequence::text,t.component_contract_code::text,t.contract_version::text,t.row_hash::text),'|' ORDER BY t.component_sequence, t.component_contract_code, t.contract_version)) IS DISTINCT FROM r.contract_component_set_hash)::integer AS set_hash_mismatch_count FROM msbf_m2.module2_contract_component_snapshot t JOIN tmp_recover_m2_12_run_context ctx ON ctx.module1_run_id=t.module1_run_id JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1 GROUP BY r.contract_component_set_hash) UNION ALL (SELECT 'EVIDENCE_CERTIFICATION'::text AS family_code, md5(string_agg(concat_ws('|',t.node_sequence::text,t.evidence_family_sequence::text,t.evidence_family_code::text,t.row_hash::text),'|' ORDER BY t.node_sequence, t.evidence_family_sequence, t.evidence_family_code))::text AS reconstructed_set_hash, r.evidence_certification_set_hash::text AS stored_set_hash, (md5(string_agg(concat_ws('|',t.node_sequence::text,t.evidence_family_sequence::text,t.evidence_family_code::text,t.row_hash::text),'|' ORDER BY t.node_sequence, t.evidence_family_sequence, t.evidence_family_code)) IS DISTINCT FROM r.evidence_certification_set_hash)::integer AS set_hash_mismatch_count FROM msbf_m2.module2_evidence_certification_snapshot t JOIN tmp_recover_m2_12_run_context ctx ON ctx.module1_run_id=t.module1_run_id JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1 GROUP BY r.evidence_certification_set_hash) UNION ALL (SELECT 'CONTRACT_REPRODUCTION'::text AS family_code, md5(string_agg(concat_ws('|',t.component_sequence::text,t.component_contract_code::text,t.contract_version::text,t.row_hash::text),'|' ORDER BY t.component_sequence, t.component_contract_code, t.contract_version))::text AS reconstructed_set_hash, r.contract_reproduction_set_hash::text AS stored_set_hash, (md5(string_agg(concat_ws('|',t.component_sequence::text,t.component_contract_code::text,t.contract_version::text,t.row_hash::text),'|' ORDER BY t.component_sequence, t.component_contract_code, t.contract_version)) IS DISTINCT FROM r.contract_reproduction_set_hash)::integer AS set_hash_mismatch_count FROM msbf_m2.module2_contract_reproduction_snapshot t JOIN tmp_recover_m2_12_run_context ctx ON ctx.module1_run_id=t.module1_run_id JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1 GROUP BY r.contract_reproduction_set_hash) UNION ALL (SELECT 'CAPABILITY_COVERAGE'::text AS family_code, md5(string_agg(concat_ws('|',t.capability_sequence::text,t.capability_code::text,t.row_hash::text),'|' ORDER BY t.capability_sequence, t.capability_code))::text AS reconstructed_set_hash, r.capability_coverage_set_hash::text AS stored_set_hash, (md5(string_agg(concat_ws('|',t.capability_sequence::text,t.capability_code::text,t.row_hash::text),'|' ORDER BY t.capability_sequence, t.capability_code)) IS DISTINCT FROM r.capability_coverage_set_hash)::integer AS set_hash_mismatch_count FROM msbf_m2.module2_capability_coverage_snapshot t JOIN tmp_recover_m2_12_run_context ctx ON ctx.module1_run_id=t.module1_run_id JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1 GROUP BY r.capability_coverage_set_hash) UNION ALL (SELECT 'LATEST'::text AS family_code, md5(string_agg(concat_ws('|',t.bundle_code::text,t.contract_version::text,t.row_hash::text),'|' ORDER BY t.bundle_code, t.contract_version))::text AS reconstructed_set_hash, r.latest_set_hash::text AS stored_set_hash, (md5(string_agg(concat_ws('|',t.bundle_code::text,t.contract_version::text,t.row_hash::text),'|' ORDER BY t.bundle_code, t.contract_version)) IS DISTINCT FROM r.latest_set_hash)::integer AS set_hash_mismatch_count FROM msbf_ctl.m2_12_g3_bundle_latest t JOIN tmp_recover_m2_12_run_context ctx ON ctx.module1_run_id=t.module1_run_id JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1 GROUP BY r.latest_set_hash) UNION ALL (SELECT 'ARCHIVE'::text AS family_code, md5(string_agg(concat_ws('|',t.bundle_code::text,t.contract_version::text,t.archive_row_hash::text),'|' ORDER BY t.bundle_code, t.contract_version))::text AS reconstructed_set_hash, r.archive_set_hash::text AS stored_set_hash, (md5(string_agg(concat_ws('|',t.bundle_code::text,t.contract_version::text,t.archive_row_hash::text),'|' ORDER BY t.bundle_code, t.contract_version)) IS DISTINCT FROM r.archive_set_hash)::integer AS set_hash_mismatch_count FROM msbf_ctl.m2_12_g3_bundle_archive t JOIN tmp_recover_m2_12_run_context ctx ON ctx.module1_run_id=t.module1_run_id JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1 GROUP BY r.archive_set_hash) UNION ALL (SELECT 'REGISTRY'::text AS family_code, md5(string_agg(concat_ws('|',t.bundle_code::text,t.contract_version::text,t.row_hash::text),'|' ORDER BY t.bundle_code, t.contract_version))::text AS reconstructed_set_hash, r.registry_set_hash::text AS stored_set_hash, (md5(string_agg(concat_ws('|',t.bundle_code::text,t.contract_version::text,t.row_hash::text),'|' ORDER BY t.bundle_code, t.contract_version)) IS DISTINCT FROM r.registry_set_hash)::integer AS set_hash_mismatch_count FROM msbf_ctl.m2_12_g3_bundle_registry t JOIN tmp_recover_m2_12_run_context ctx ON ctx.module1_run_id=t.module1_run_id JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1 GROUP BY r.registry_set_hash)),
setd AS (SELECT sum(set_hash_mismatch_count)::bigint set_hash_mismatch_count FROM set_detail),
ch AS (SELECT r.module1_run_id,
       md5(concat_ws('|',r.bundle_code::text,r.contract_version::text,r.schema_version::text,r.methodology_version::text,r.policy_configuration_hash::text,r.policy_set_hash::text,r.stage_certification_set_hash::text,r.contract_component_set_hash::text,r.evidence_certification_set_hash::text,r.contract_reproduction_set_hash::text,r.capability_coverage_set_hash::text,r.latest_set_hash::text,r.archive_set_hash::text,r.registry_set_hash::text,r.latest_contract_row_hash::text,r.archive_contract_row_hash::text,r.row_hash::text,r.accepted_m2_11_contract_set_hash::text,r.accepted_m2_11_combined_set_hash::text,r.accepted_m2_11_registry_row_hash::text))::text AS reconstructed_contract_set_hash,
       r.contract_set_hash::text AS stored_contract_set_hash,
       (md5(concat_ws('|',r.bundle_code::text,r.contract_version::text,r.schema_version::text,r.methodology_version::text,r.policy_configuration_hash::text,r.policy_set_hash::text,r.stage_certification_set_hash::text,r.contract_component_set_hash::text,r.evidence_certification_set_hash::text,r.contract_reproduction_set_hash::text,r.capability_coverage_set_hash::text,r.latest_set_hash::text,r.archive_set_hash::text,r.registry_set_hash::text,r.latest_contract_row_hash::text,r.archive_contract_row_hash::text,r.row_hash::text,r.accepted_m2_11_contract_set_hash::text,r.accepted_m2_11_combined_set_hash::text,r.accepted_m2_11_registry_row_hash::text)) IS DISTINCT FROM r.contract_set_hash)::integer AS contract_hash_mismatch_count
FROM msbf_ctl.m2_12_g3_bundle_registry r
JOIN tmp_recover_m2_12_run_context ctx ON ctx.module1_run_id=r.module1_run_id
WHERE r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1), cb AS (SELECT u.module1_run_id, count(*)::integer AS canonical_entities, count(DISTINCT u.entity_type)::integer AS canonical_families, md5(string_agg(u.entity_type||'|'||u.entity_key||'|'||u.row_hash,'|' ORDER BY u.entity_type,u.entity_key))::text AS reconstructed_combined_set_hash, r.combined_set_hash::text AS stored_combined_set_hash, (md5(string_agg(u.entity_type||'|'||u.entity_key||'|'||u.row_hash,'|' ORDER BY u.entity_type,u.entity_key)) IS DISTINCT FROM r.combined_set_hash)::integer AS combined_hash_mismatch_count FROM (SELECT t.module1_run_id, 'POLICY'::text AS entity_type, concat_ws('|',t.policy_code::text,t.policy_version::text)::text AS entity_key, t.row_hash::text AS row_hash FROM msbf_ctl.m2_12_policy_profile t JOIN tmp_recover_m2_12_run_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT t.module1_run_id, 'STAGE_CERTIFICATION'::text AS entity_type, concat_ws('|',t.certification_node_sequence::text,t.stage_code::text)::text AS entity_key, t.row_hash::text AS row_hash FROM msbf_m2.module2_stage_certification_snapshot t JOIN tmp_recover_m2_12_run_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT t.module1_run_id, 'CONTRACT_COMPONENT'::text AS entity_type, concat_ws('|',t.component_sequence::text,t.component_contract_code::text,t.contract_version::text)::text AS entity_key, t.row_hash::text AS row_hash FROM msbf_m2.module2_contract_component_snapshot t JOIN tmp_recover_m2_12_run_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT t.module1_run_id, 'EVIDENCE_CERTIFICATION'::text AS entity_type, concat_ws('|',t.node_sequence::text,t.evidence_family_sequence::text,t.evidence_family_code::text)::text AS entity_key, t.row_hash::text AS row_hash FROM msbf_m2.module2_evidence_certification_snapshot t JOIN tmp_recover_m2_12_run_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT t.module1_run_id, 'CONTRACT_REPRODUCTION'::text AS entity_type, concat_ws('|',t.component_sequence::text,t.component_contract_code::text,t.contract_version::text)::text AS entity_key, t.row_hash::text AS row_hash FROM msbf_m2.module2_contract_reproduction_snapshot t JOIN tmp_recover_m2_12_run_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT t.module1_run_id, 'CAPABILITY_COVERAGE'::text AS entity_type, concat_ws('|',t.capability_sequence::text,t.capability_code::text)::text AS entity_key, t.row_hash::text AS row_hash FROM msbf_m2.module2_capability_coverage_snapshot t JOIN tmp_recover_m2_12_run_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT t.module1_run_id, 'LATEST'::text AS entity_type, concat_ws('|',t.bundle_code::text,t.contract_version::text)::text AS entity_key, t.row_hash::text AS row_hash FROM msbf_ctl.m2_12_g3_bundle_latest t JOIN tmp_recover_m2_12_run_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT t.module1_run_id, 'ARCHIVE'::text AS entity_type, concat_ws('|',t.bundle_code::text,t.contract_version::text)::text AS entity_key, t.archive_row_hash::text AS row_hash FROM msbf_ctl.m2_12_g3_bundle_archive t JOIN tmp_recover_m2_12_run_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT t.module1_run_id, 'REGISTRY'::text AS entity_type, concat_ws('|',t.bundle_code::text,t.contract_version::text)::text AS entity_key, t.row_hash::text AS row_hash FROM msbf_ctl.m2_12_g3_bundle_registry t JOIN tmp_recover_m2_12_run_context ctx ON ctx.module1_run_id=t.module1_run_id) u JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=u.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1 GROUP BY u.module1_run_id,r.combined_set_hash), seq AS (SELECT ctx.module1_run_id,
       p.last_value::bigint AS policy_last_value,p.is_called AS policy_is_called,
       a.last_value::bigint AS archive_last_value,a.is_called AS archive_is_called,
       r.last_value::bigint AS registry_last_value,r.is_called AS registry_is_called,
       ((p.last_value<>1 OR NOT p.is_called)::integer
        +(a.last_value<>1 OR NOT a.is_called)::integer
        +(r.last_value<>1 OR NOT r.is_called)::integer)::integer AS sequence_state_mismatch_count
FROM tmp_recover_m2_12_run_context ctx
CROSS JOIN msbf_ctl.m2_12_policy_profile_policy_profile_id_seq p
CROSS JOIN msbf_ctl.m2_12_g3_bundle_archive_archive_id_seq a
CROSS JOIN msbf_ctl.m2_12_g3_bundle_registry_registry_id_seq r)
SELECT ctx.module1_run_id,
       rowd.family_count_mismatch_count,rowd.row_hash_mismatch_count,setd.set_hash_mismatch_count,
       ch.contract_hash_mismatch_count::integer,cb.combined_hash_mismatch_count::integer,
       seq.sequence_state_mismatch_count::integer,cb.canonical_families::integer,cb.canonical_entities::integer,
       (rowd.family_count_mismatch_count+rowd.row_hash_mismatch_count+setd.set_hash_mismatch_count+ch.contract_hash_mismatch_count+cb.combined_hash_mismatch_count+seq.sequence_state_mismatch_count)::bigint AS total_mismatch_count
FROM tmp_recover_m2_12_run_context ctx CROSS JOIN rowd CROSS JOIN setd CROSS JOIN ch CROSS JOIN cb CROSS JOIN seq
) p;;
CREATE UNIQUE INDEX ux_tmp_hash_m2_12_recovery_postflight ON tmp_hash_m2_12_recovery_postflight(module1_run_id);
ANALYZE tmp_hash_m2_12_recovery_postflight;

CREATE TEMP TABLE tmp_recover_m2_12_result ON COMMIT PRESERVE ROWS AS
WITH state AS (
 SELECT rr.run_id,rr.run_status,r.contract_status,r.generated_at,r.validated_at,r.accepted_at
 FROM msbf_ctl.run_registry rr
 JOIN tmp_recover_m2_12_run_context ctx ON ctx.module1_run_id=rr.run_id
 JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=rr.run_id
   AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1
), evidence AS (
 SELECT count(*) FILTER (WHERE e.evidence_code LIKE 'M2_12_POS_%')::integer positive_rows,
        count(*) FILTER (WHERE e.evidence_code LIKE 'M2_12_NEG_%')::integer negative_rows,
        count(*) FILTER (WHERE e.evidence_code='M2_12_ACCEPTANCE_SUMMARY')::integer acceptance_rows,
        count(*) FILTER (WHERE e.evidence_code IN ('M2_12_POLICY_SET_HASH','M2_12_STAGE_CERTIFICATION_SET_HASH','M2_12_CONTRACT_COMPONENT_SET_HASH','M2_12_EVIDENCE_CERTIFICATION_SET_HASH','M2_12_CONTRACT_REPRODUCTION_SET_HASH','M2_12_CAPABILITY_COVERAGE_SET_HASH','M2_12_LATEST_SET_HASH','M2_12_ARCHIVE_SET_HASH','M2_12_REGISTRY_SET_HASH','M2_12_CONTRACT_SET_HASH','M2_12_COMBINED_SET_HASH','M2_12_STAGE_CERTIFICATION_ROWS','M2_12_CONTRACT_COMPONENT_ROWS','M2_12_EVIDENCE_CERTIFICATION_ROWS','M2_12_CONTRACT_REPRODUCTION_ROWS','M2_12_CAPABILITY_COVERAGE_ROWS','M2_12_CANONICAL_ENTITIES','M2_12_COMPONENT_LATEST_ARCHIVE_ROWS_TOTAL','M2_12_APPLICATION_CONSUMPTION_ROWS','M2_12_OPERATIONAL_ACCOUNT_CONSUMPTION_ROWS','M2_12_STRATEGY_SCOPE_CONSUMPTION_ROWS','M2_12_SOURCE_GRAPH_EDGES','M2_12_DETERMINISTIC_MISMATCHES','M2_12_BLOCKING_STAGE_BOUNDARY_FINDINGS') AND e.status='PASS')::integer generation_pass
 FROM msbf_ctl.run_evidence e JOIN tmp_recover_m2_12_run_context ctx ON ctx.module1_run_id=e.run_id
), gate AS (
 SELECT count(*)::integer gate_rows FROM msbf_ctl.acceptance_gate_result g
 JOIN tmp_recover_m2_12_run_context ctx ON ctx.module1_run_id=g.run_id WHERE g.gate_id='G3_M2_CONTRACT'
), hash_parity AS (
 SELECT b.total_mismatch_count=0 AND a.total_mismatch_count=0
    AND ROW(b.family_count_mismatch_count,b.row_hash_mismatch_count,b.set_hash_mismatch_count,
            b.contract_hash_mismatch_count,b.combined_hash_mismatch_count,b.sequence_state_mismatch_count,
            b.canonical_families,b.canonical_entities,b.total_mismatch_count,b.reconciliation_status)
        IS NOT DISTINCT FROM
        ROW(a.family_count_mismatch_count,a.row_hash_mismatch_count,a.set_hash_mismatch_count,
            a.contract_hash_mismatch_count,a.combined_hash_mismatch_count,a.sequence_state_mismatch_count,
            a.canonical_families,a.canonical_entities,a.total_mismatch_count,a.reconciliation_status) AS exact_flag
 FROM tmp_hash_m2_12_recovery_reconciliation b
 JOIN tmp_hash_m2_12_recovery_postflight a USING(module1_run_id)
), fingerprint AS (
 SELECT b.canonical_fingerprint IS NOT DISTINCT FROM a.canonical_fingerprint
    AND b.stored_hash_fingerprint IS NOT DISTINCT FROM a.stored_hash_fingerprint
    AND b.sequence_fingerprint IS NOT DISTINCT FROM a.sequence_fingerprint
    AND b.canonical_entity_count=134 AND a.canonical_entity_count=134 AS exact_flag
 FROM tmp_hash_m2_12_recovery_baseline b CROSS JOIN tmp_hash_m2_12_recovery_current_fingerprint a
), mutation AS (
 SELECT count(*)::integer rows,count(*) FILTER (WHERE status='PASS')::integer pass_rows FROM tmp_recover_m2_12_mutation_ledger
)
SELECT s.run_id,s.run_status,s.contract_status,s.generated_at,s.validated_at,s.accepted_at,
       e.positive_rows,e.negative_rows,e.acceptance_rows,e.generation_pass,g.gate_rows,
       h.exact_flag AS hash_exact,f.exact_flag AS fingerprint_exact,m.rows AS mutation_rows,m.pass_rows AS mutation_pass_rows,
       CASE WHEN s.run_status='M2_12_GENERATED' AND s.contract_status='GENERATED'
                  AND s.generated_at IS NOT NULL AND s.validated_at IS NULL AND s.accepted_at IS NULL
                  AND e.positive_rows=0 AND e.negative_rows=0 AND e.acceptance_rows=0 AND e.generation_pass=24
                  AND g.gate_rows=0 AND h.exact_flag AND f.exact_flag AND m.rows=3 AND m.pass_rows=3
            THEN 'PASS' ELSE 'FAIL' END AS recovery_status
FROM state s CROSS JOIN evidence e CROSS JOIN gate g CROSS JOIN hash_parity h CROSS JOIN fingerprint f CROSS JOIN mutation m;

DO $m212_p223a_final_gate$
BEGIN
  IF (SELECT count(*) FROM tmp_recover_m2_12_result)<>1
     OR (SELECT recovery_status FROM tmp_recover_m2_12_result)<>'PASS' THEN
    RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 Recovery 223A final generated-checkpoint postflight failed';
  END IF;
END;
$m212_p223a_final_gate$;

COMMIT;

SELECT * FROM tmp_recover_m2_12_result;
SELECT * FROM tmp_recover_m2_12_mutation_ledger ORDER BY mutation_sequence;
