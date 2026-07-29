/* ============================================================================
MSBF M1.15 Acceptance Finalizer
Program : 113_msbf_m1_15_acceptance_finalize_v0_2R3.sql
Version : v0.2R3
Purpose : Reconcile positive and negative controls, physical cardinalities,
          archive immutability, latest/archive identity, matched comparison,
          canonical hashes, contract lifecycle, and downstream boundaries.
Output  : One filterable acceptance result preserved after COMMIT.
============================================================================ */

BEGIN;
SET LOCAL work_mem='64MB';
SET LOCAL jit=off;
SET LOCAL statement_timeout='15min';

DROP TABLE IF EXISTS _m1_15_acceptance;
CREATE TEMP TABLE _m1_15_acceptance ON COMMIT PRESERVE ROWS AS
WITH r AS (
    SELECT run_id,run_status,population_id,as_of_date
    FROM msbf_ctl.run_registry
    WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
), pos AS (
    SELECT count(*) AS checks,
           count(*) FILTER(WHERE status='PASS') AS passes,
           count(*) FILTER(WHERE status='FAIL') AS failures
    FROM msbf_ctl.run_evidence
    WHERE run_id=(SELECT run_id FROM r) AND evidence_code LIKE 'M1_15_POS_%'
), neg AS (
    SELECT count(*) AS controls,
           count(*) FILTER(WHERE status='PASS') AS passes,
           count(*) FILTER(WHERE status='FAIL') AS failures
    FROM msbf_ctl.run_evidence
    WHERE run_id=(SELECT run_id FROM r) AND evidence_code LIKE 'M1_15_NEG_%'
), c AS (
    SELECT * FROM msbf_ctl.m1_15_consumption_contract_registry
    WHERE module1_run_id=(SELECT run_id FROM r)
), rows AS (
    SELECT
      (SELECT count(*) FROM msbf_m1.application_module1_latest
       WHERE module1_run_id=(SELECT run_id FROM r)) AS latest_rows,
      (SELECT count(*) FROM msbf_m1.application_module1_archive
       WHERE module1_run_id=(SELECT run_id FROM r)) AS archive_rows,
      (SELECT count(*) FROM msbf_m1.application_module1_scenario_comparison
       WHERE module1_run_id=(SELECT run_id FROM r)) AS comparison_rows,
      (SELECT count(*) FROM msbf_m1.application_module1_latest l
       WHERE l.module1_run_id=(SELECT run_id FROM r)
         AND l.contract_row_hash IS DISTINCT FROM
             msbf_m1.m1_15_hash_jsonb(to_jsonb(l)-'contract_row_hash'-'created_at'))
          AS latest_hash_mismatches,
      (SELECT count(*) FROM msbf_m1.application_module1_archive a
       JOIN msbf_m1.application_module1_latest l
         ON l.module1_run_id=a.module1_run_id
        AND l.scenario_id=a.scenario_id
        AND l.merchant_application_id=a.merchant_application_id
       WHERE a.module1_run_id=(SELECT run_id FROM r)
         AND (a.contract_row_hash IS DISTINCT FROM l.contract_row_hash
              OR a.contract_payload IS DISTINCT FROM to_jsonb(l)-'created_at'))
          AS archive_mismatches,
      (SELECT count(*) FROM msbf_m1.application_module1_scenario_comparison x
       WHERE x.module1_run_id=(SELECT run_id FROM r)
         AND x.comparison_row_hash IS DISTINCT FROM
             msbf_m1.m1_15_hash_jsonb(to_jsonb(x)-'comparison_row_hash'-'created_at'))
          AS comparison_hash_mismatches,
      (SELECT count(*) FROM msbf_ctl.m1_15_consumption_contract_registry x
       WHERE x.module1_run_id=(SELECT run_id FROM r)
         AND x.contract_row_hash IS DISTINCT FROM
             msbf_m1.m1_15_hash_jsonb(
               to_jsonb(x)-'contract_row_hash'-'combined_set_hash'
                          -'contract_status'-'generated_at'-'validated_at'
             )) AS contract_hash_mismatches,
      (SELECT count(*) FROM pg_trigger
       WHERE tgname='trg_m1_15_archive_immutable' AND tgenabled<>'D')
          AS archive_trigger_count,
      (SELECT count(*) FROM msbf_ctl.profile_resolution_error
       WHERE run_id=(SELECT run_id FROM r) AND severity='BLOCKING')
          AS blocking_errors,
      (SELECT count(*) FROM msbf_m1.module1_latest
       WHERE module1_run_id=(SELECT run_id FROM r))
      +(SELECT count(*) FROM msbf_m1.module1_archive
       WHERE module1_run_id=(SELECT run_id FROM r))
          AS legacy_rows
), hashes AS (
    WITH all_entities AS (
      SELECT ('LATEST|'||scenario_id::text||'|'||merchant_application_id)::text AS entity_key,
             contract_row_hash::text AS row_hash
      FROM msbf_m1.application_module1_latest
      WHERE module1_run_id=(SELECT run_id FROM r)
      UNION ALL
      SELECT ('ARCHIVE|'||contract_version::text||'|'||scenario_id::text||'|'||merchant_application_id)::text,
             contract_row_hash::text
      FROM msbf_m1.application_module1_archive
      WHERE module1_run_id=(SELECT run_id FROM r)
      UNION ALL
      SELECT ('COMPARE|'||merchant_application_id)::text,comparison_row_hash::text
      FROM msbf_m1.application_module1_scenario_comparison
      WHERE module1_run_id=(SELECT run_id FROM r)
      UNION ALL
      SELECT ('CONTRACT|'||contract_code||'|'||contract_version::text||'|'||module1_run_id::text)::text,
             contract_row_hash::text
      FROM c
    )
    SELECT count(*) AS canonical_entities,
           md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key))
               AS combined_hash
    FROM all_entities
), stored AS (
    SELECT
      max(metric_value_text) FILTER(WHERE evidence_code='M1_15_LATEST_SET_HASH')
          AS latest_hash,
      max(metric_value_text) FILTER(WHERE evidence_code='M1_15_ARCHIVE_SET_HASH')
          AS archive_hash,
      max(metric_value_text) FILTER(WHERE evidence_code='M1_15_COMPARISON_SET_HASH')
          AS comparison_hash,
      max(metric_value_text) FILTER(WHERE evidence_code='M1_15_CONTRACT_SET_HASH')
          AS contract_hash,
      max(metric_value_text) FILTER(WHERE evidence_code='M1_15_COMBINED_SET_HASH')
          AS combined_hash,
      (max(metric_value_numeric)
       FILTER(WHERE evidence_code='M1_15_CANONICAL_MISMATCH_COUNT'))::bigint
          AS mismatches
    FROM msbf_ctl.run_evidence
    WHERE run_id=(SELECT run_id FROM r)
)
SELECT
    r.run_id,
    r.run_status,
    pos.checks AS positive_checks,
    pos.passes AS positive_passes,
    pos.failures AS positive_failures,
    neg.controls AS negative_controls,
    neg.passes AS negative_passes,
    neg.failures AS negative_failures,
    rows.latest_rows,
    rows.archive_rows,
    rows.comparison_rows,
    rows.latest_hash_mismatches,
    rows.archive_mismatches,
    rows.comparison_hash_mismatches,
    rows.contract_hash_mismatches,
    rows.archive_trigger_count,
    rows.blocking_errors,
    rows.legacy_rows,
    hashes.canonical_entities,
    hashes.combined_hash AS recomputed_combined_hash,
    stored.latest_hash AS stored_latest_set_hash,
    stored.archive_hash AS stored_archive_set_hash,
    stored.comparison_hash AS stored_comparison_set_hash,
    stored.contract_hash AS stored_contract_set_hash,
    stored.combined_hash AS stored_combined_set_hash,
    stored.mismatches AS stored_mismatches,
    c.contract_code,
    c.contract_version,
    c.schema_version,
    c.contract_status,
    c.latest_set_hash AS registry_latest_set_hash,
    c.archive_set_hash AS registry_archive_set_hash,
    c.comparison_set_hash AS registry_comparison_set_hash,
    c.contract_set_hash AS registry_contract_set_hash,
    c.combined_set_hash,
    CASE
      WHEN r.run_status='M1_15_VALIDATED'
       AND pos.checks=84 AND pos.passes=84 AND pos.failures=0
       AND neg.controls=7 AND neg.passes=7 AND neg.failures=0
       AND rows.latest_rows=1500
       AND rows.archive_rows=1500
       AND rows.comparison_rows=750
       AND rows.latest_hash_mismatches=0
       AND rows.archive_mismatches=0
       AND rows.comparison_hash_mismatches=0
       AND rows.contract_hash_mismatches=0
       AND rows.archive_trigger_count=1
       AND rows.blocking_errors=0
       AND rows.legacy_rows=0
       AND hashes.canonical_entities=3751
       AND stored.mismatches=0
       AND stored.latest_hash=c.latest_set_hash
       AND stored.archive_hash=c.archive_set_hash
       AND stored.comparison_hash=c.comparison_set_hash
       AND stored.contract_hash=c.contract_set_hash
       AND hashes.combined_hash=stored.combined_hash
       AND hashes.combined_hash=c.combined_set_hash
       AND c.contract_code='M1_APPLICATION_CONSUMPTION'
       AND c.contract_version=1
       AND c.schema_version='M1_CONTRACT_SCHEMA_V1'
       AND c.contract_status='VALIDATED'
      THEN 'PASS' ELSE 'FAIL'
    END AS acceptance_status
FROM r
CROSS JOIN pos
CROSS JOIN neg
CROSS JOIN rows
CROSS JOIN hashes
CROSS JOIN stored
CROSS JOIN c;

INSERT INTO msbf_ctl.acceptance_gate_result(
    run_id,gate_id,review_version,result_status,observed_value,threshold_value,
    finding,residual_limitation,reviewer_role,reviewed_at
)
SELECT
    a.run_id,'M1_15_CONSUMPTION_CONTRACT',
    coalesce((
      SELECT max(review_version)+1
      FROM msbf_ctl.acceptance_gate_result
      WHERE run_id=a.run_id AND gate_id='M1_15_CONSUMPTION_CONTRACT'
    ),1),
    a.acceptance_status,
    format(
      'positive=%s/%s|negative=%s/%s|latest=%s|archive=%s|comparison=%s|canonical=%s|mismatches=%s',
      a.positive_passes,a.positive_checks,a.negative_passes,a.negative_controls,
      a.latest_rows,a.archive_rows,a.comparison_rows,a.canonical_entities,a.stored_mismatches
    ),
    '84/84 positive; 7/7 negative; 1,500 latest; 1,500 archive; 750 comparisons; 3,751 canonical entities; zero mismatches',
    CASE WHEN a.acceptance_status='PASS'
         THEN 'M1.15 latest, archive, matched comparison, and consumption contract accepted.'
         ELSE 'M1.15 acceptance requirements were not fully satisfied.' END,
    'Synthetic Module 1 consumption contract only; no pricing, approval, counteroffer, decline, adverse-action, or portfolio decision.',
    'Independent Validation',clock_timestamp()
FROM _m1_15_acceptance a;

INSERT INTO msbf_ctl.run_evidence(
    run_id,evidence_code,segment_key,metric_name,metric_value_text,
    unit_code,status,interpretation
)
SELECT
    run_id,'M1_15_ACCEPTANCE_SUMMARY','PORTFOLIO','M1.15 acceptance summary',
    format(
      'positive=%s/%s|negative=%s/%s|latest=%s|archive=%s|comparison=%s|canonical=%s|hash=%s',
      positive_passes,positive_checks,negative_passes,negative_controls,
      latest_rows,archive_rows,comparison_rows,canonical_entities,combined_set_hash
    ),
    'TEXT',acceptance_status,'Formal M1.15 acceptance summary.'
FROM _m1_15_acceptance
ON CONFLICT(run_id,evidence_code,segment_key) DO UPDATE SET
    metric_name=EXCLUDED.metric_name,
    metric_value_text=EXCLUDED.metric_value_text,
    metric_value_numeric=NULL,
    unit_code=EXCLUDED.unit_code,
    status=EXCLUDED.status,
    interpretation=EXCLUDED.interpretation,
    created_at=clock_timestamp();

UPDATE msbf_ctl.m1_15_consumption_contract_registry c
SET contract_status=CASE
      WHEN a.acceptance_status='PASS' THEN 'ACCEPTED' ELSE 'VALIDATED' END,
    validated_at=CASE
      WHEN a.acceptance_status='PASS' THEN clock_timestamp() ELSE c.validated_at END
FROM _m1_15_acceptance a
WHERE c.module1_run_id=a.run_id;

UPDATE msbf_ctl.run_registry r
SET run_status=CASE
      WHEN a.acceptance_status='PASS' THEN 'M1_15_ACCEPTED' ELSE 'M1_15_FAILED' END,
    completed_at=CASE
      WHEN a.acceptance_status='PASS' THEN clock_timestamp() ELSE NULL END,
    notes=concat_ws(E'\n',r.notes,
      CASE WHEN a.acceptance_status='PASS'
           THEN 'M1.15 latest/archive/comparison consumption contract accepted.'
           ELSE 'M1.15 acceptance failed.' END)
FROM _m1_15_acceptance a
WHERE r.run_id=a.run_id;

COMMIT;

SELECT * FROM _m1_15_acceptance;
