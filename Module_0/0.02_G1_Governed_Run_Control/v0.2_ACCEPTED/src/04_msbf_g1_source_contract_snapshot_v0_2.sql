/* ============================================================================
MSBF G1 Source and Contract Snapshot
Version : v0.2
Purpose : Freeze the approved/effective source contracts, source cutoffs, output
          contract identity, and source-set hash before analytical generation.
============================================================================ */

BEGIN;

DO $$
DECLARE
    v_run_id bigint;
    v_run_status text;
BEGIN
    SELECT run_id, run_status
      INTO STRICT v_run_id, v_run_status
      FROM msbf_ctl.run_registry
     WHERE run_code = 'M1_V0_2_BASELINE_BUILD'
       AND run_version = 1
     FOR UPDATE;

    IF v_run_status = 'G1_READY' THEN
        RAISE EXCEPTION 'Run % is G1_READY; source snapshots are frozen.', v_run_id;
    END IF;

    IF v_run_status NOT IN ('READY_FOR_G1_VALIDATION','G1_VALIDATED','G1_FAILED') THEN
        RAISE EXCEPTION 'Run % has unsupported status % for source snapshot construction.', v_run_id, v_run_status;
    END IF;

    DELETE FROM msbf_ctl.profile_resolution_error
     WHERE run_id = v_run_id
       AND profile_domain = 'SOURCE';
END
$$;

/* Missing approved/effective source contracts. */
WITH ctx AS (
    SELECT run_id, as_of_date
    FROM msbf_ctl.run_registry
    WHERE run_code = 'M1_V0_2_BASELINE_BUILD' AND run_version = 1
), effective_contracts AS (
    SELECT sc.source_code, COUNT(*) AS contract_count
    FROM ctx
    JOIN msbf_ctl.source_contract sc
      ON sc.effective_start_date <= ctx.as_of_date
     AND (sc.effective_end_date IS NULL OR sc.effective_end_date > ctx.as_of_date)
     AND sc.status = 'APPROVED'
    GROUP BY sc.source_code
)
INSERT INTO msbf_ctl.profile_resolution_error (
    run_id, profile_domain, scope_key, error_code, severity, error_message
)
SELECT
    ctx.run_id,
    'SOURCE',
    src.source_code,
    CASE WHEN COALESCE(ec.contract_count,0) = 0
         THEN 'MISSING_APPROVED_SOURCE_CONTRACT'
         ELSE 'AMBIGUOUS_APPROVED_SOURCE_CONTRACT' END,
    'BLOCKING',
    format('Expected exactly one approved/effective source contract for %s; observed %s.',
           src.source_code, COALESCE(ec.contract_count,0))
FROM ctx
CROSS JOIN msbf_ref.source_code src
LEFT JOIN effective_contracts ec ON ec.source_code = src.source_code
WHERE src.active_flag
  AND COALESCE(ec.contract_count,0) <> 1;

/* Contract and feature-set identity checks. */
WITH ctx AS (
    SELECT *
    FROM msbf_ctl.run_registry
    WHERE run_code = 'M1_V0_2_BASELINE_BUILD' AND run_version = 1
)
INSERT INTO msbf_ctl.profile_resolution_error (
    run_id, profile_domain, scope_key, error_code, severity, error_message
)
SELECT
    ctx.run_id,
    'SOURCE',
    'M1_APPLICATION_RISK_SNAPSHOT',
    'OUTPUT_CONTRACT_NOT_APPROVED_OR_EFFECTIVE',
    'BLOCKING',
    'The selected Module 1 output contract is missing, unapproved, stale, or not version 1.'
FROM ctx
LEFT JOIN msbf_ctl.contract_registry c
  ON c.contract_id = ctx.contract_id
 AND c.contract_code = 'M1_APPLICATION_RISK_SNAPSHOT'
 AND c.contract_version = 1
 AND c.status = 'APPROVED'
 AND c.effective_start_date <= ctx.as_of_date
 AND (c.effective_end_date IS NULL OR c.effective_end_date > ctx.as_of_date)
WHERE c.contract_id IS NULL;

WITH ctx AS (
    SELECT run_id
    FROM msbf_ctl.run_registry
    WHERE run_code = 'M1_V0_2_BASELINE_BUILD' AND run_version = 1
)
INSERT INTO msbf_ctl.profile_resolution_error (
    run_id, profile_domain, scope_key, error_code, severity, error_message
)
SELECT
    ctx.run_id,
    'SOURCE',
    'M1_ACTIVE_FEATURES',
    'FEATURE_DEFINITION_SET_NOT_FROZEN',
    'BLOCKING',
    'The active Module 1 feature-definition set was not frozen in the run profile snapshot.'
FROM ctx
WHERE NOT EXISTS (
    SELECT 1
    FROM msbf_ctl.run_profile_snapshot p
    WHERE p.run_id = ctx.run_id
      AND p.profile_domain = 'FEATURE_DEFINITION_SET'
      AND p.profile_code = 'M1_ACTIVE_FEATURES'
);

DO $$
DECLARE
    v_run_id bigint;
    v_blocking_errors integer;
BEGIN
    SELECT run_id INTO STRICT v_run_id
    FROM msbf_ctl.run_registry
    WHERE run_code = 'M1_V0_2_BASELINE_BUILD' AND run_version = 1
    FOR UPDATE;

    SELECT COUNT(*) INTO v_blocking_errors
    FROM msbf_ctl.profile_resolution_error
    WHERE run_id = v_run_id AND severity = 'BLOCKING';

    IF v_blocking_errors > 0 THEN
        UPDATE msbf_ctl.run_registry
           SET run_status = 'G1_FAILED',
               notes = 'G1 source/contract resolution failed; review msbf_ctl.profile_resolution_error.'
         WHERE run_id = v_run_id;
    ELSE
        DELETE FROM msbf_ctl.run_source_snapshot WHERE run_id = v_run_id;
        UPDATE msbf_ctl.run_registry
           SET run_status = 'READY_FOR_G1_VALIDATION',
               source_snapshot_hash = NULL,
               notes = 'G1 profile and parameter snapshots complete; source snapshot construction in progress.'
         WHERE run_id = v_run_id;
    END IF;
END
$$;

WITH ctx AS (
    SELECT run_id, as_of_date
    FROM msbf_ctl.run_registry
    WHERE run_code = 'M1_V0_2_BASELINE_BUILD'
      AND run_version = 1
      AND run_status <> 'G1_FAILED'
), selected_contracts AS (
    SELECT DISTINCT ON (sc.source_code)
        ctx.run_id,
        ctx.as_of_date,
        sc.*
    FROM ctx
    JOIN msbf_ctl.source_contract sc
      ON sc.effective_start_date <= ctx.as_of_date
     AND (sc.effective_end_date IS NULL OR sc.effective_end_date > ctx.as_of_date)
     AND sc.status = 'APPROVED'
    JOIN msbf_ref.source_code src
      ON src.source_code = sc.source_code
     AND src.active_flag
    ORDER BY sc.source_code, sc.contract_version DESC, sc.source_contract_id DESC
)
INSERT INTO msbf_ctl.run_source_snapshot (
    run_id, source_code, source_contract_id, source_cutoff_timestamp,
    source_row_count, source_hash, quality_status
)
SELECT
    run_id,
    source_code,
    source_contract_id,
    (((as_of_date + 1)::timestamp AT TIME ZONE 'UTC') - interval '1 microsecond') AS source_cutoff_timestamp,
    0::bigint AS source_row_count,
    md5(concat_ws('|',
        source_code,
        contract_version::text,
        business_name,
        expected_grain,
        required_history_days::text,
        COALESCE(freshness_sla_hours::text,''),
        minimum_completeness_rate::text,
        COALESCE(reconciliation_tolerance_rate::text,''),
        effective_start_date::text,
        COALESCE(effective_end_date::text,''),
        schema_definition::text,
        quality_rules::text
    )),
    'CONTRACT_READY_PRE_GENERATION'
FROM selected_contracts;

WITH ctx AS (
    SELECT run_id
    FROM msbf_ctl.run_registry
    WHERE run_code = 'M1_V0_2_BASELINE_BUILD' AND run_version = 1
), hashes AS (
    SELECT
        s.run_id,
        md5(string_agg(
            s.source_code || '|' ||
            to_char(s.source_cutoff_timestamp AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US') || '|' || s.source_hash || '|' ||
            s.quality_status,
            '||' ORDER BY s.source_code
        )) AS source_hash
    FROM msbf_ctl.run_source_snapshot s
    JOIN ctx ON ctx.run_id = s.run_id
    GROUP BY s.run_id
)
UPDATE msbf_ctl.run_registry r
   SET source_snapshot_hash = h.source_hash,
       notes = 'G1 parameter, profile, and source snapshots complete; readiness validation pending.'
  FROM hashes h
 WHERE r.run_id = h.run_id;

COMMIT;

SELECT
    r.run_id,
    r.run_status,
    COUNT(s.source_code) AS source_snapshot_rows,
    r.source_snapshot_hash,
    MIN(s.source_cutoff_timestamp) AS minimum_source_cutoff,
    MAX(s.source_cutoff_timestamp) AS maximum_source_cutoff,
    COUNT(*) FILTER (WHERE s.quality_status = 'CONTRACT_READY_PRE_GENERATION') AS contract_ready_rows,
    (SELECT COUNT(*)
       FROM msbf_ctl.profile_resolution_error e
      WHERE e.run_id = r.run_id AND e.severity = 'BLOCKING') AS blocking_resolution_errors
FROM msbf_ctl.run_registry r
LEFT JOIN msbf_ctl.run_source_snapshot s ON s.run_id = r.run_id
WHERE r.run_code = 'M1_V0_2_BASELINE_BUILD'
  AND r.run_version = 1
GROUP BY r.run_id, r.run_status, r.source_snapshot_hash;
