
/* ============================================================================
 Merchant Sales-Based Financing Strategy Simulator
 M1.17 — End-to-End QA, Evidence & G2 Contract Acceptance
 Program 131 — Detailed G2 Evidence Report
 Version     — v0.2R8

 PURPOSE
 -------
 Produce 24 read-only, clearly labeled result sets covering the complete
 accepted G2 bundle, source contracts, hash chain, evidence, archive
 immutability, validation, stage boundaries and deterministic reconciliation.

 REQUIRED EMPTY SETS
 -------------------
 Result Set 23 — Deterministic Mismatches
 Result Set 24 — Blocking Errors and Stage-Boundary Violations
============================================================================ */

SET statement_timeout='20min';
SET jit=off;

DROP TABLE IF EXISTS _m1_17_detail_run;
CREATE TEMP TABLE _m1_17_detail_run ON COMMIT PRESERVE ROWS AS
SELECT run_id,run_code,run_version,run_status,population_id,as_of_date
FROM msbf_ctl.run_registry
WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1;

DROP TABLE IF EXISTS _m1_17_detail_integrated;
CREATE TEMP TABLE _m1_17_detail_integrated ON COMMIT PRESERVE ROWS AS
SELECT *
FROM msbf_m1.v_m1_17_g2_integrated_consumption
WHERE module1_run_id=(SELECT run_id FROM _m1_17_detail_run);

CREATE INDEX ON _m1_17_detail_integrated(merchant_application_id,scenario_id);
ANALYZE _m1_17_detail_integrated;

/* --------------------------------------------------------------------------
 Result Set 01 — Run, G2 bundle lifecycle and acceptance-gate status
-------------------------------------------------------------------------- */
SELECT
    r.run_code,
    r.run_version,
    r.run_status,
    r.population_id,
    r.as_of_date,
    b.bundle_code,
    b.bundle_version,
    b.schema_version,
    b.methodology_version,
    b.bundle_status,
    b.generated_at,
    b.validated_at,
    b.accepted_at,
    (
        SELECT coalesce(
            to_jsonb(g)->>'result_status',
            to_jsonb(g)->>'gate_status',
            to_jsonb(g)->>'status'
        )
        FROM msbf_ctl.acceptance_gate_result g
        WHERE g.run_id=r.run_id
          AND g.gate_id='G2_M1_CONTRACT'
        ORDER BY
            CASE
                WHEN (to_jsonb(g)->>'review_version') ~ '^[0-9]+$'
                THEN (to_jsonb(g)->>'review_version')::integer
                ELSE 0
            END DESC
        LIMIT 1
    ) AS g2_gate_status
FROM _m1_17_detail_run r
JOIN msbf_ctl.m1_17_g2_bundle_registry b
  ON b.module1_run_id=r.run_id;

/* --------------------------------------------------------------------------
 Result Set 02 — Approved M1.17 assurance policy and frozen parameters
-------------------------------------------------------------------------- */
SELECT
    policy_code,
    methodology_version,
    bundle_code,
    bundle_version,
    schema_version,
    expected_hash_chain_rows,
    expected_evidence_rows,
    expected_bundle_latest_rows,
    expected_bundle_archive_rows,
    expected_registry_rows,
    expected_integrated_rows,
    expected_canonical_entities,
    expected_positive_controls,
    expected_negative_controls,
    expected_detail_result_sets,
    required_predecessor_gates,
    synthetic_data_only_flag,
    no_new_business_analytics_flag,
    no_module2_outputs_flag,
    package_static_validation_required,
    policy_status,
    configuration_hash
FROM msbf_ctl.m1_17_policy_profile
WHERE policy_code='M1_17_G2_ASSURANCE_V1';

/* --------------------------------------------------------------------------
 Result Set 03 — G2 bundle registry, source contracts and set hashes
-------------------------------------------------------------------------- */
SELECT *
FROM msbf_ctl.v_m1_17_g2_lineage
WHERE module1_run_id=(SELECT run_id FROM _m1_17_detail_run);

/* --------------------------------------------------------------------------
 Result Set 04 — Ordered accepted G1-through-M1.16 hash chain
-------------------------------------------------------------------------- */
SELECT
    stage_sequence,
    stage_code,
    artifact_code,
    expected_hash,
    observed_hash,
    source_locator,
    verification_status,
    row_hash
FROM msbf_ctl.m1_17_hash_chain_snapshot
WHERE module1_run_id=(SELECT run_id FROM _m1_17_detail_run)
ORDER BY stage_sequence;

/* --------------------------------------------------------------------------
 Result Set 05 — Accepted predecessor-gate inventory
-------------------------------------------------------------------------- */
SELECT
    gate_id,
    count(*) AS review_rows,
    count(*) FILTER (
        WHERE coalesce(
            to_jsonb(g)->>'result_status',
            to_jsonb(g)->>'gate_status',
            to_jsonb(g)->>'status'
        )='PASS'
    ) AS pass_rows,
    max(
        CASE
            WHEN (to_jsonb(g)->>'review_version') ~ '^[0-9]+$'
            THEN (to_jsonb(g)->>'review_version')::integer
            ELSE 0
        END
    ) AS maximum_review_version
FROM msbf_ctl.acceptance_gate_result g
WHERE run_id=(SELECT run_id FROM _m1_17_detail_run)
GROUP BY gate_id
ORDER BY gate_id;

/* --------------------------------------------------------------------------
 Result Set 06 — Accepted M1.15 and M1.16 contract identities
-------------------------------------------------------------------------- */
SELECT
    'M1.15'::text AS source_module,
    to_jsonb(x)->>'contract_code' AS contract_code,
    to_jsonb(x)->>'contract_version' AS contract_version,
    to_jsonb(x)->>'schema_version' AS schema_version,
    to_jsonb(x)->>'contract_status' AS contract_status,
    to_jsonb(x)->>'combined_set_hash' AS combined_set_hash
FROM msbf_ctl.m1_15_consumption_contract_registry x
WHERE (to_jsonb(x)->>'module1_run_id')::bigint=
      (SELECT run_id FROM _m1_17_detail_run)
UNION ALL
SELECT
    'M1.16',
    to_jsonb(x)->>'contract_code',
    to_jsonb(x)->>'contract_version',
    to_jsonb(x)->>'schema_version',
    to_jsonb(x)->>'contract_status',
    to_jsonb(x)->>'combined_set_hash'
FROM msbf_ctl.m1_16_acquisition_contract_registry x
WHERE (to_jsonb(x)->>'module1_run_id')::bigint=
      (SELECT run_id FROM _m1_17_detail_run)
ORDER BY source_module;

/* --------------------------------------------------------------------------
 Result Set 07 — M1.15 contract cardinality and physical grains
-------------------------------------------------------------------------- */
SELECT
    (SELECT count(*) FROM msbf_m1.application_module1_latest
      WHERE module1_run_id=r.run_id) AS latest_rows,
    (SELECT count(*) FROM msbf_m1.application_module1_archive
      WHERE module1_run_id=r.run_id) AS archive_rows,
    (SELECT count(*) FROM msbf_m1.application_module1_scenario_comparison
      WHERE module1_run_id=r.run_id) AS comparison_rows,
    (SELECT count(DISTINCT merchant_application_id)
     FROM msbf_m1.application_module1_latest
     WHERE module1_run_id=r.run_id) AS applications,
    (SELECT count(DISTINCT scenario_id)
     FROM msbf_m1.application_module1_latest
     WHERE module1_run_id=r.run_id) AS scenarios,
    (SELECT count(*) FROM (
        SELECT scenario_id,merchant_application_id
        FROM msbf_m1.application_module1_latest
        WHERE module1_run_id=r.run_id
        GROUP BY scenario_id,merchant_application_id
        HAVING count(*)<>1
    ) q) AS latest_grain_violations
FROM _m1_17_detail_run r;

/* --------------------------------------------------------------------------
 Result Set 08 — M1.16 acquisition-contract cardinality and physical grains
-------------------------------------------------------------------------- */
SELECT
    (SELECT count(*) FROM msbf_m1.acquisition_source_profile
      WHERE module1_run_id=r.run_id) AS source_profiles,
    (SELECT count(*) FROM msbf_m1.acquisition_marketing_campaign
      WHERE module1_run_id=r.run_id) AS campaigns,
    (SELECT count(*) FROM msbf_m1.acquisition_campaign_funnel_stage
      WHERE module1_run_id=r.run_id) AS funnel_rows,
    (SELECT count(*) FROM msbf_m1.acquisition_cost_ledger
      WHERE module1_run_id=r.run_id) AS ledger_rows,
    (SELECT count(*) FROM msbf_m1.application_acquisition_touchpoint
      WHERE module1_run_id=r.run_id) AS touchpoints,
    (SELECT count(*) FROM msbf_m1.application_acquisition_attribution_snapshot
      WHERE module1_run_id=r.run_id) AS attribution_rows,
    (SELECT count(*) FROM msbf_m1.application_acquisition_cost_snapshot
      WHERE module1_run_id=r.run_id) AS cost_snapshot_rows,
    (SELECT count(*) FROM msbf_m1.application_acquisition_cost_component_value
      WHERE module1_run_id=r.run_id) AS component_rows,
    (SELECT count(*) FROM msbf_m1.application_acquisition_contract_latest
      WHERE module1_run_id=r.run_id) AS latest_rows,
    (SELECT count(*) FROM msbf_m1.application_acquisition_contract_archive
      WHERE module1_run_id=r.run_id) AS archive_rows,
    (SELECT count(*) FROM (
        SELECT merchant_application_id
        FROM msbf_m1.application_acquisition_contract_latest
        WHERE module1_run_id=r.run_id
        GROUP BY merchant_application_id
        HAVING count(*)<>1
    ) q) AS latest_grain_violations
FROM _m1_17_detail_run r;

/* --------------------------------------------------------------------------
 Result Set 09 — Integrated G2 consumption cardinality and join integrity
-------------------------------------------------------------------------- */
SELECT
    count(*) AS integrated_rows,
    count(DISTINCT merchant_application_id) AS applications,
    count(DISTINCT scenario_id) AS scenarios,
    count(*) - count(DISTINCT (scenario_id,merchant_application_id))
        AS duplicate_application_scenario_rows,
    (
        SELECT count(*)
        FROM (
            SELECT merchant_application_id
            FROM _m1_17_detail_integrated
            GROUP BY merchant_application_id
            HAVING count(*)<>2
        ) q
    ) AS application_scenario_count_violations
FROM _m1_17_detail_integrated;

/* --------------------------------------------------------------------------
 Result Set 10 — Integrated scenario distribution
-------------------------------------------------------------------------- */
SELECT
    i.scenario_id,
    coalesce(to_jsonb(sr)->>'scenario_code','<UNKNOWN>') AS scenario_code,
    count(*) AS rows,
    count(DISTINCT i.merchant_application_id) AS applications
FROM _m1_17_detail_integrated AS i
LEFT JOIN msbf_ctl.scenario_registry AS sr
  ON sr.scenario_id = i.scenario_id
GROUP BY
    i.scenario_id,
    coalesce(to_jsonb(sr)->>'scenario_code','<UNKNOWN>')
ORDER BY
    i.scenario_id;

/* --------------------------------------------------------------------------
 Result Set 11 — M1.15 latest/archive reproduction diagnostics
-------------------------------------------------------------------------- */
SELECT
    count(*) AS joined_rows,
    count(*) FILTER (
        WHERE l.contract_row_hash IS DISTINCT FROM a.contract_row_hash
    ) AS row_hash_mismatches
FROM msbf_m1.application_module1_latest AS l
JOIN msbf_m1.application_module1_archive AS a
  ON a.module1_run_id = l.module1_run_id
 AND a.scenario_id = l.scenario_id
 AND a.merchant_application_id = l.merchant_application_id
WHERE l.module1_run_id = (
    SELECT run_id
    FROM _m1_17_detail_run
);

/* --------------------------------------------------------------------------
 Result Set 12 — M1.16 latest/archive reproduction diagnostics
-------------------------------------------------------------------------- */
SELECT
    count(*) AS joined_rows,
    count(*) FILTER (
        WHERE l.contract_row_hash IS DISTINCT FROM a.contract_row_hash
    ) AS row_hash_mismatches
FROM msbf_m1.application_acquisition_contract_latest AS l
JOIN msbf_m1.application_acquisition_contract_archive AS a
  ON a.module1_run_id = l.module1_run_id
 AND a.merchant_application_id = l.merchant_application_id
WHERE l.module1_run_id = (
    SELECT run_id
    FROM _m1_17_detail_run
);

/* --------------------------------------------------------------------------
 Result Set 13 — G2 bundle latest/archive reproduction
-------------------------------------------------------------------------- */
SELECT
    l.bundle_code,
    l.bundle_version,
    l.schema_version,
    l.contract_row_hash,
    a.source_latest_row_hash,
    a.archive_row_hash,
    l.bundle_payload IS NOT DISTINCT FROM a.bundle_payload
        AS payload_reconciles,
    l.contract_row_hash IS NOT DISTINCT FROM a.source_latest_row_hash
        AS source_hash_reconciles
FROM msbf_ctl.m1_17_g2_bundle_latest l
JOIN msbf_ctl.m1_17_g2_bundle_archive a
  ON a.module1_run_id=l.module1_run_id
 AND a.bundle_code=l.bundle_code
 AND a.bundle_version=l.bundle_version
WHERE l.module1_run_id=(SELECT run_id FROM _m1_17_detail_run);

/* --------------------------------------------------------------------------
 Result Set 14 — End-to-end evidence summary by family
-------------------------------------------------------------------------- */
SELECT
    evidence_family,
    count(*) AS evidence_rows,
    count(*) FILTER(WHERE evidence_status='PASS') AS pass_rows,
    count(*) FILTER(WHERE evidence_status='FAIL') AS fail_rows
FROM msbf_ctl.m1_17_end_to_end_evidence_snapshot
WHERE module1_run_id=(SELECT run_id FROM _m1_17_detail_run)
GROUP BY evidence_family
ORDER BY evidence_family;

/* --------------------------------------------------------------------------
 Result Set 15 — Complete end-to-end evidence snapshot
-------------------------------------------------------------------------- */
SELECT
    evidence_sequence,
    evidence_family,
    evidence_code,
    metric_name,
    observed_value_text,
    expected_value_text,
    evidence_status,
    interpretation,
    source_locator,
    row_hash
FROM msbf_ctl.m1_17_end_to_end_evidence_snapshot
WHERE module1_run_id=(SELECT run_id FROM _m1_17_detail_run)
ORDER BY evidence_sequence;

/* --------------------------------------------------------------------------
 Result Set 16 — Positive-validation summary
-------------------------------------------------------------------------- */
SELECT
    count(*) AS positive_checks,
    count(*) FILTER(WHERE status='PASS') AS positive_passes,
    count(*) FILTER(WHERE status='FAIL') AS positive_failures,
    string_agg(evidence_code,',' ORDER BY evidence_code)
        FILTER(WHERE status='FAIL') AS failed_codes
FROM msbf_ctl.run_evidence
WHERE run_id=(SELECT run_id FROM _m1_17_detail_run)
  AND evidence_code LIKE 'M1_17_POS_%';

/* --------------------------------------------------------------------------
 Result Set 17 — Negative-control summary
-------------------------------------------------------------------------- */
SELECT
    count(*) AS negative_checks,
    count(*) FILTER(WHERE status='PASS') AS negative_passes,
    count(*) FILTER(WHERE status='FAIL') AS negative_failures,
    string_agg(evidence_code,',' ORDER BY evidence_code)
        FILTER(WHERE status='FAIL') AS failed_codes
FROM msbf_ctl.run_evidence
WHERE run_id=(SELECT run_id FROM _m1_17_detail_run)
  AND evidence_code LIKE 'M1_17_NEG_%';

/* --------------------------------------------------------------------------
 Result Set 18 — Archive-immutability trigger inventory
-------------------------------------------------------------------------- */
SELECT
    n.nspname AS table_schema,
    c.relname AS table_name,
    t.tgname AS trigger_name,
    pg_get_triggerdef(t.oid) AS trigger_definition
FROM pg_trigger t
JOIN pg_class c ON c.oid=t.tgrelid
JOIN pg_namespace n ON n.oid=c.relnamespace
WHERE NOT t.tgisinternal
  AND (
      (n.nspname='msbf_m1'
       AND c.relname IN (
           'application_module1_archive',
           'application_acquisition_contract_archive'
       ))
      OR
      (n.nspname='msbf_ctl'
       AND c.relname='m1_17_g2_bundle_archive')
  )
ORDER BY table_schema,table_name,trigger_name;

/* --------------------------------------------------------------------------
 Result Set 19 — Stage-boundary and prohibited-data summary
-------------------------------------------------------------------------- */
SELECT
    msbf_ctl.m1_17_schema_row_count('msbf_m2') AS module2_rows,
    (
        SELECT count(*)
        FROM information_schema.columns
        WHERE table_schema IN ('msbf_ctl','msbf_m1')
          AND table_name LIKE '%m1_17%'
          AND column_name ~* '(email|phone|cookie|device|ip_address|tracking_id|ssn|tax_id)'
    ) AS prohibited_pii_columns,
    (
        SELECT count(*)
        FROM msbf_ctl.profile_resolution_error
        WHERE run_id=(SELECT run_id FROM _m1_17_detail_run)
          AND severity='BLOCKING'
    ) AS blocking_errors;

/* --------------------------------------------------------------------------
 Result Set 20 — Sample integrated G2 consumption records
-------------------------------------------------------------------------- */
SELECT *
FROM _m1_17_detail_integrated
ORDER BY merchant_application_id,scenario_id
LIMIT 25;

/* --------------------------------------------------------------------------
 Result Set 21 — Stored and reconstructed G2 set-hash summary
-------------------------------------------------------------------------- */
WITH h AS (
    SELECT md5(string_agg(
        format('%03s|%s',stage_sequence,row_hash),
        '||' ORDER BY stage_sequence
    )) AS set_hash
    FROM msbf_ctl.m1_17_hash_chain_snapshot
    WHERE module1_run_id=(SELECT run_id FROM _m1_17_detail_run)
), e AS (
    SELECT md5(string_agg(
        format('%03s|%s',evidence_sequence,row_hash),
        '||' ORDER BY evidence_sequence
    )) AS set_hash
    FROM msbf_ctl.m1_17_end_to_end_evidence_snapshot
    WHERE module1_run_id=(SELECT run_id FROM _m1_17_detail_run)
), l AS (
    SELECT md5('LATEST|'||contract_row_hash) AS set_hash
    FROM msbf_ctl.m1_17_g2_bundle_latest
    WHERE module1_run_id=(SELECT run_id FROM _m1_17_detail_run)
), a AS (
    SELECT md5('ARCHIVE|'||archive_row_hash) AS set_hash
    FROM msbf_ctl.m1_17_g2_bundle_archive
    WHERE module1_run_id=(SELECT run_id FROM _m1_17_detail_run)
), c AS (
    SELECT md5('REGISTRY|'||row_hash) AS set_hash
    FROM msbf_ctl.m1_17_g2_bundle_registry
    WHERE module1_run_id=(SELECT run_id FROM _m1_17_detail_run)
)
SELECT
    r.hash_chain_set_hash AS stored_hash_chain_set_hash,
    h.set_hash AS reconstructed_hash_chain_set_hash,
    r.evidence_set_hash AS stored_evidence_set_hash,
    e.set_hash AS reconstructed_evidence_set_hash,
    r.bundle_latest_set_hash AS stored_latest_set_hash,
    l.set_hash AS reconstructed_latest_set_hash,
    r.bundle_archive_set_hash AS stored_archive_set_hash,
    a.set_hash AS reconstructed_archive_set_hash,
    r.contract_set_hash AS stored_contract_set_hash,
    c.set_hash AS reconstructed_contract_set_hash,
    r.combined_g2_hash AS stored_combined_g2_hash,
    md5(concat_ws('||',
        'HASH_CHAIN|'||h.set_hash,
        'EVIDENCE|'||e.set_hash,
        'LATEST|'||l.set_hash,
        'ARCHIVE|'||a.set_hash,
        'REGISTRY|'||c.set_hash
    )) AS reconstructed_combined_g2_hash
FROM msbf_ctl.m1_17_g2_bundle_registry r
CROSS JOIN h CROSS JOIN e CROSS JOIN l CROSS JOIN a CROSS JOIN c
WHERE r.module1_run_id=(SELECT run_id FROM _m1_17_detail_run);

/* --------------------------------------------------------------------------
 Result Set 22 — Governed M1.17 run evidence
-------------------------------------------------------------------------- */
SELECT
    evidence_code,
    segment_key,
    metric_name,
    metric_value_numeric,
    metric_value_text,
    unit_code,
    status,
    interpretation,
    created_at
FROM msbf_ctl.run_evidence
WHERE run_id=(SELECT run_id FROM _m1_17_detail_run)
  AND evidence_code LIKE 'M1_17_%'
ORDER BY evidence_code,segment_key;

/* --------------------------------------------------------------------------
 Result Set 23 — Deterministic Mismatches
 Required: headers retained, zero data rows.
-------------------------------------------------------------------------- */
SELECT
    'HASH_CHAIN'::text AS entity_family,
    format('%03s',h.stage_sequence) AS entity_key,
    h.row_hash AS stored_row_hash,
    msbf_ctl.m1_17_hash_jsonb(
        jsonb_build_object(
            'module1_run_id',h.module1_run_id,
            'stage_sequence',h.stage_sequence,
            'stage_code',h.stage_code,
            'artifact_code',h.artifact_code,
            'expected_hash',h.expected_hash,
            'observed_hash',h.observed_hash,
            'source_locator',h.source_locator,
            'verification_status',h.verification_status
        )
    ) AS reconstructed_row_hash
FROM msbf_ctl.m1_17_hash_chain_snapshot h
WHERE h.module1_run_id=(SELECT run_id FROM _m1_17_detail_run)
  AND h.row_hash IS DISTINCT FROM msbf_ctl.m1_17_hash_jsonb(
      jsonb_build_object(
          'module1_run_id',h.module1_run_id,
          'stage_sequence',h.stage_sequence,
          'stage_code',h.stage_code,
          'artifact_code',h.artifact_code,
          'expected_hash',h.expected_hash,
          'observed_hash',h.observed_hash,
          'source_locator',h.source_locator,
          'verification_status',h.verification_status
      )
  )
UNION ALL
SELECT
    'EVIDENCE',
    format('%03s',e.evidence_sequence),
    e.row_hash,
    msbf_ctl.m1_17_hash_jsonb(
        jsonb_build_object(
            'module1_run_id',e.module1_run_id,
            'evidence_sequence',e.evidence_sequence,
            'evidence_family',e.evidence_family,
            'evidence_code',e.evidence_code,
            'metric_name',e.metric_name,
            'observed_value_text',e.observed_value_text,
            'expected_value_text',e.expected_value_text,
            'evidence_status',e.evidence_status,
            'interpretation',e.interpretation,
            'source_locator',e.source_locator
        )
    )
FROM msbf_ctl.m1_17_end_to_end_evidence_snapshot e
WHERE e.module1_run_id=(SELECT run_id FROM _m1_17_detail_run)
  AND e.row_hash IS DISTINCT FROM msbf_ctl.m1_17_hash_jsonb(
      jsonb_build_object(
          'module1_run_id',e.module1_run_id,
          'evidence_sequence',e.evidence_sequence,
          'evidence_family',e.evidence_family,
          'evidence_code',e.evidence_code,
          'metric_name',e.metric_name,
          'observed_value_text',e.observed_value_text,
          'expected_value_text',e.expected_value_text,
          'evidence_status',e.evidence_status,
          'interpretation',e.interpretation,
          'source_locator',e.source_locator
      )
  )
UNION ALL
SELECT
    'LATEST','1',l.contract_row_hash,
    msbf_ctl.m1_17_hash_jsonb(
        jsonb_build_object(
            'module1_run_id',l.module1_run_id,
            'bundle_code',l.bundle_code,
            'bundle_version',l.bundle_version,
            'schema_version',l.schema_version,
            'methodology_version',l.methodology_version,
            'source_contract_count',l.source_contract_count,
            'integrated_consumption_rows',l.integrated_consumption_rows,
            'hash_chain_rows',l.hash_chain_rows,
            'evidence_snapshot_rows',l.evidence_snapshot_rows,
            'hash_chain_set_hash',l.hash_chain_set_hash,
            'evidence_set_hash',l.evidence_set_hash
        )
    )
FROM msbf_ctl.m1_17_g2_bundle_latest l
WHERE l.module1_run_id=(SELECT run_id FROM _m1_17_detail_run)
  AND l.contract_row_hash IS DISTINCT FROM msbf_ctl.m1_17_hash_jsonb(
      jsonb_build_object(
          'module1_run_id',l.module1_run_id,
          'bundle_code',l.bundle_code,
          'bundle_version',l.bundle_version,
          'schema_version',l.schema_version,
          'methodology_version',l.methodology_version,
          'source_contract_count',l.source_contract_count,
          'integrated_consumption_rows',l.integrated_consumption_rows,
          'hash_chain_rows',l.hash_chain_rows,
          'evidence_snapshot_rows',l.evidence_snapshot_rows,
          'hash_chain_set_hash',l.hash_chain_set_hash,
          'evidence_set_hash',l.evidence_set_hash
      )
  )
UNION ALL
SELECT
    'ARCHIVE','1',a.archive_row_hash,
    msbf_ctl.m1_17_hash_jsonb(
        jsonb_build_object(
            'module1_run_id',a.module1_run_id,
            'bundle_code',a.bundle_code,
            'bundle_version',a.bundle_version,
            'schema_version',a.schema_version,
            'methodology_version',a.methodology_version,
            'source_contract_count',a.source_contract_count,
            'integrated_consumption_rows',a.integrated_consumption_rows,
            'hash_chain_rows',a.hash_chain_rows,
            'evidence_snapshot_rows',a.evidence_snapshot_rows,
            'hash_chain_set_hash',a.hash_chain_set_hash,
            'evidence_set_hash',a.evidence_set_hash,
            'bundle_payload',a.bundle_payload,
            'source_latest_row_hash',a.source_latest_row_hash
        )
    )
FROM msbf_ctl.m1_17_g2_bundle_archive a
WHERE a.module1_run_id=(SELECT run_id FROM _m1_17_detail_run)
  AND a.archive_row_hash IS DISTINCT FROM msbf_ctl.m1_17_hash_jsonb(
      jsonb_build_object(
          'module1_run_id',a.module1_run_id,
          'bundle_code',a.bundle_code,
          'bundle_version',a.bundle_version,
          'schema_version',a.schema_version,
          'methodology_version',a.methodology_version,
          'source_contract_count',a.source_contract_count,
          'integrated_consumption_rows',a.integrated_consumption_rows,
          'hash_chain_rows',a.hash_chain_rows,
          'evidence_snapshot_rows',a.evidence_snapshot_rows,
          'hash_chain_set_hash',a.hash_chain_set_hash,
          'evidence_set_hash',a.evidence_set_hash,
          'bundle_payload',a.bundle_payload,
          'source_latest_row_hash',a.source_latest_row_hash
      )
  )
ORDER BY entity_family,entity_key;

/* --------------------------------------------------------------------------
 Result Set 24 — Blocking Errors and Stage-Boundary Violations
 Required: headers retained, zero data rows.
-------------------------------------------------------------------------- */
SELECT
    'BLOCKING_ERROR'::text AS issue_type,
    resolution_error_id::text AS issue_id,
    profile_domain::text AS domain,
    scope_key::text AS scope_key,
    error_code::text AS issue_code,
    severity::text AS severity,
    error_message::text AS issue_message,
    NULL::text AS observed_value,
    created_at
FROM msbf_ctl.profile_resolution_error
WHERE run_id=(SELECT run_id FROM _m1_17_detail_run)
  AND severity='BLOCKING'
UNION ALL
SELECT
    'MODULE2_STAGE_BOUNDARY',
    NULL::text,
    'msbf_m2',
    'ALL_TABLES',
    'PREMATURE_MODULE2_ROWS',
    'BLOCKING',
    'Module 2 business rows exist before or during G2 closure.',
    msbf_ctl.m1_17_schema_row_count('msbf_m2')::text,
    NULL::timestamptz
WHERE msbf_ctl.m1_17_schema_row_count('msbf_m2')<>0
UNION ALL
SELECT
    'PROHIBITED_COLUMN',
    NULL::text,
    table_schema,
    table_name,
    column_name,
    'BLOCKING',
    'Prohibited PII or tracking-like column exists in an M1.17 object.',
    data_type,
    NULL::timestamptz
FROM information_schema.columns
WHERE table_schema IN ('msbf_ctl','msbf_m1')
  AND table_name LIKE '%m1_17%'
  AND column_name ~* '(email|phone|cookie|device|ip_address|tracking_id|ssn|tax_id)'
ORDER BY issue_type,domain,scope_key,issue_code;
