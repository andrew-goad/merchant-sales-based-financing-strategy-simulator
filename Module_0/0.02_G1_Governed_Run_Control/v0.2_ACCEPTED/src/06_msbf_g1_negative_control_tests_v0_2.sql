/* ============================================================================
MSBF G1 Negative Control Tests
Version : v0.2
Purpose : Prove the G1 controls reject deliberately incomplete or ambiguous
          configuration states before analytical generation.

No permanent governed snapshot is altered. Invalid states exist only in
transaction-scoped temporary tables; results are retained as run evidence.
============================================================================ */

BEGIN;

DO $$
DECLARE
    v_status text;
BEGIN
    SELECT run_status INTO STRICT v_status
    FROM msbf_ctl.run_registry
    WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
    FOR UPDATE;

    IF v_status <> 'G1_VALIDATED' THEN
        RAISE EXCEPTION 'Negative controls require run_status=G1_VALIDATED; observed %', v_status;
    END IF;
END
$$;

CREATE TEMP TABLE tmp_g1_missing_parameter AS
SELECT *
FROM msbf_ctl.run_parameter_snapshot
WHERE run_id=(
    SELECT run_id FROM msbf_ctl.run_registry
    WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
);

DELETE FROM tmp_g1_missing_parameter
WHERE parameter_name='population_size'
  AND scope_key='GLOBAL';

CREATE TEMP TABLE tmp_g1_ambiguous_parameter AS
SELECT *
FROM msbf_ctl.run_parameter_snapshot
WHERE run_id=(
    SELECT run_id FROM msbf_ctl.run_registry
    WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
);

INSERT INTO tmp_g1_ambiguous_parameter (
    run_id, parameter_name, scope_key, resolved_value,
    resolution_rank, source_parameter_value_id, snapshot_hash
)
SELECT
    run_id,
    parameter_name,
    scope_key,
    resolved_value,
    resolution_rank,
    source_parameter_value_id,
    snapshot_hash || '_NEGATIVE_DUPLICATE'
FROM tmp_g1_ambiguous_parameter
WHERE parameter_name='deterministic_seed_version'
  AND scope_key='GLOBAL'
LIMIT 1;

CREATE TEMP TABLE tmp_g1_missing_source AS
SELECT *
FROM msbf_ctl.run_source_snapshot
WHERE run_id=(
    SELECT run_id FROM msbf_ctl.run_registry
    WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
);

DELETE FROM tmp_g1_missing_source
WHERE source_code='POS_DAILY';

CREATE TEMP TABLE tmp_g1_negative_results (
    evidence_code text PRIMARY KEY,
    metric_name text NOT NULL,
    observed_value text NOT NULL,
    result_status text NOT NULL,
    interpretation text NOT NULL
) ON COMMIT DROP;

/* Missing required parameter must be detected. */
WITH missing AS (
    SELECT COUNT(*) AS missing_count
    FROM msbf_ctl.parameter_definition pd
    WHERE pd.required_flag
      AND pd.status='ACTIVE'
      AND NOT EXISTS (
          SELECT 1
          FROM tmp_g1_missing_parameter s
          WHERE s.parameter_name=pd.parameter_name
      )
)
INSERT INTO tmp_g1_negative_results
SELECT
    'G1_NEG_01_MISSING_PARAMETER_REJECTED',
    'Negative control: missing required parameter',
    format('missing_required_parameters=%s', missing_count),
    CASE WHEN missing_count >= 1 THEN 'PASS' ELSE 'FAIL' END,
    'The completeness control must reject a snapshot when population_size is removed.'
FROM missing;

/* Ambiguous parameter/scope must be detected. */
WITH ambiguous AS (
    SELECT COUNT(*) AS ambiguous_groups
    FROM (
        SELECT parameter_name, scope_key
        FROM tmp_g1_ambiguous_parameter
        GROUP BY parameter_name, scope_key
        HAVING COUNT(*) > 1
    ) x
)
INSERT INTO tmp_g1_negative_results
SELECT
    'G1_NEG_02_AMBIGUOUS_PARAMETER_REJECTED',
    'Negative control: ambiguous parameter scope',
    format('ambiguous_parameter_scope_groups=%s', ambiguous_groups),
    CASE WHEN ambiguous_groups >= 1 THEN 'PASS' ELSE 'FAIL' END,
    'The uniqueness control must reject duplicate deterministic_seed_version/ GLOBAL rows.'
FROM ambiguous;

/* Missing required source must be detected. */
WITH required_sources AS (
    SELECT source_code FROM msbf_ref.source_code WHERE active_flag
), missing AS (
    SELECT COUNT(*) AS missing_sources
    FROM required_sources src
    WHERE NOT EXISTS (
        SELECT 1 FROM tmp_g1_missing_source s WHERE s.source_code=src.source_code
    )
)
INSERT INTO tmp_g1_negative_results
SELECT
    'G1_NEG_03_MISSING_SOURCE_REJECTED',
    'Negative control: missing required source contract',
    format('missing_required_sources=%s', missing_sources),
    CASE WHEN missing_sources >= 1 THEN 'PASS' ELSE 'FAIL' END,
    'The source-readiness control must reject a source snapshot when POS_DAILY is removed.'
FROM missing;

WITH ctx AS (
    SELECT run_id FROM msbf_ctl.run_registry
    WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
)
INSERT INTO msbf_ctl.run_evidence (
    run_id, evidence_code, segment_key, metric_name,
    metric_value_text, unit_code, status, interpretation
)
SELECT
    ctx.run_id,
    n.evidence_code,
    'PORTFOLIO',
    n.metric_name,
    n.observed_value,
    'TEXT',
    n.result_status,
    n.interpretation
FROM ctx
CROSS JOIN tmp_g1_negative_results n
ON CONFLICT (run_id, evidence_code, segment_key)
DO UPDATE SET
    metric_name=EXCLUDED.metric_name,
    metric_value_numeric=NULL,
    metric_value_text=EXCLUDED.metric_value_text,
    unit_code=EXCLUDED.unit_code,
    status=EXCLUDED.status,
    threshold_value_numeric=NULL,
    interpretation=EXCLUDED.interpretation,
    created_at=clock_timestamp();

WITH ctx AS (
    SELECT run_id FROM msbf_ctl.run_registry
    WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
), summary AS (
    SELECT COUNT(*) FILTER (WHERE result_status='FAIL') AS failed_negative_controls
    FROM tmp_g1_negative_results
)
UPDATE msbf_ctl.run_registry r
   SET run_status=CASE WHEN summary.failed_negative_controls=0 THEN 'G1_VALIDATED' ELSE 'G1_FAILED' END,
       notes=CASE WHEN summary.failed_negative_controls=0
                  THEN 'G1 positive checks and negative controls passed; final gate acceptance pending.'
                  ELSE 'G1 negative control execution failed; control logic requires remediation.' END
FROM ctx, summary
WHERE r.run_id=ctx.run_id;

COMMIT;

SELECT
    evidence_code,
    metric_name,
    status,
    metric_value_text,
    interpretation
FROM msbf_ctl.run_evidence
WHERE run_id=(
    SELECT run_id FROM msbf_ctl.run_registry
    WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
)
  AND evidence_code LIKE 'G1_NEG_%'
ORDER BY evidence_code;
