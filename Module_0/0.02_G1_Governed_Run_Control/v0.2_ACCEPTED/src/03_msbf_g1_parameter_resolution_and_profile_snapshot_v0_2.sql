/* ============================================================================
MSBF G1 Parameter Resolution and Profile Snapshot
Version : v0.2
Purpose : Validate and freeze the complete run-scoped parameter and profile
          configuration for M1_V0_2_BASELINE_BUILD.

Immutability rule:
- Rebuild is permitted only while run_status is READY_FOR_G1_VALIDATION,
  G1_VALIDATED, or G1_FAILED.
- Once the run is G1_READY, this script fails closed.
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
        RAISE EXCEPTION 'Run % is G1_READY; parameter and profile snapshots are frozen.', v_run_id;
    END IF;

    IF v_run_status NOT IN ('READY_FOR_G1_VALIDATION','G1_VALIDATED','G1_FAILED') THEN
        RAISE EXCEPTION 'Run % has unsupported status % for G1 snapshot construction.', v_run_id, v_run_status;
    END IF;

    DELETE FROM msbf_ctl.profile_resolution_error
     WHERE run_id = v_run_id
       AND profile_domain IN ('PARAMETER','PROFILE');
END
$$;

/* -------------------------------------------------------------------------
   Parameter ambiguity: more than one effective row for the same parameter
   and scope in the selected parameter set.
   ---------------------------------------------------------------------- */
WITH ctx AS (
    SELECT run_id, parameter_set_id, as_of_date
    FROM msbf_ctl.run_registry
    WHERE run_code = 'M1_V0_2_BASELINE_BUILD' AND run_version = 1
), active_values AS (
    SELECT pv.parameter_name, pv.scope_key, COUNT(*) AS active_count
    FROM ctx
    JOIN msbf_ctl.parameter_value pv
      ON pv.parameter_set_id = ctx.parameter_set_id
     AND pv.effective_start_date <= ctx.as_of_date
     AND (pv.effective_end_date IS NULL OR pv.effective_end_date > ctx.as_of_date)
    GROUP BY pv.parameter_name, pv.scope_key
    HAVING COUNT(*) > 1
)
INSERT INTO msbf_ctl.profile_resolution_error (
    run_id, profile_domain, scope_key, error_code, severity, error_message
)
SELECT
    ctx.run_id,
    'PARAMETER',
    av.parameter_name || '|' || av.scope_key,
    'AMBIGUOUS_EFFECTIVE_PARAMETER',
    'BLOCKING',
    format('Parameter %s scope %s has %s simultaneously effective values.',
           av.parameter_name, av.scope_key, av.active_count)
FROM ctx
CROSS JOIN active_values av;

/* Required parameter definitions without any effective value. */
WITH ctx AS (
    SELECT run_id, parameter_set_id, as_of_date
    FROM msbf_ctl.run_registry
    WHERE run_code = 'M1_V0_2_BASELINE_BUILD' AND run_version = 1
), active_names AS (
    SELECT DISTINCT pv.parameter_name
    FROM ctx
    JOIN msbf_ctl.parameter_value pv
      ON pv.parameter_set_id = ctx.parameter_set_id
     AND pv.effective_start_date <= ctx.as_of_date
     AND (pv.effective_end_date IS NULL OR pv.effective_end_date > ctx.as_of_date)
)
INSERT INTO msbf_ctl.profile_resolution_error (
    run_id, profile_domain, scope_key, error_code, severity, error_message
)
SELECT
    ctx.run_id,
    'PARAMETER',
    pd.parameter_name,
    'MISSING_REQUIRED_PARAMETER',
    'BLOCKING',
    format('Required active parameter %s has no effective value in the selected parameter set.', pd.parameter_name)
FROM ctx
CROSS JOIN msbf_ctl.parameter_definition pd
LEFT JOIN active_names an ON an.parameter_name = pd.parameter_name
WHERE pd.required_flag
  AND pd.status = 'ACTIVE'
  AND an.parameter_name IS NULL;

/* Type conformance. */
WITH ctx AS (
    SELECT run_id, parameter_set_id, as_of_date
    FROM msbf_ctl.run_registry
    WHERE run_code = 'M1_V0_2_BASELINE_BUILD' AND run_version = 1
), active_values AS (
    SELECT pv.*, pd.data_type
    FROM ctx
    JOIN msbf_ctl.parameter_value pv
      ON pv.parameter_set_id = ctx.parameter_set_id
     AND pv.effective_start_date <= ctx.as_of_date
     AND (pv.effective_end_date IS NULL OR pv.effective_end_date > ctx.as_of_date)
    JOIN msbf_ctl.parameter_definition pd
      ON pd.parameter_name = pv.parameter_name
)
INSERT INTO msbf_ctl.profile_resolution_error (
    run_id, profile_domain, scope_key, error_code, severity, error_message
)
SELECT
    ctx.run_id,
    'PARAMETER',
    av.parameter_name || '|' || av.scope_key,
    'PARAMETER_TYPE_MISMATCH',
    'BLOCKING',
    format('Parameter %s scope %s does not conform to declared type %s.',
           av.parameter_name, av.scope_key, av.data_type)
FROM ctx
CROSS JOIN active_values av
WHERE CASE av.data_type
        WHEN 'INTEGER' THEN av.value_numeric IS NULL OR av.value_numeric <> trunc(av.value_numeric)
        WHEN 'NUMERIC' THEN av.value_numeric IS NULL
        WHEN 'TEXT'    THEN av.value_text IS NULL
        WHEN 'BOOLEAN' THEN av.value_boolean IS NULL
        WHEN 'DATE'    THEN av.value_date IS NULL
        WHEN 'JSON'    THEN av.value_json IS NULL
        ELSE true
      END;

/* Numeric range conformance. */
WITH ctx AS (
    SELECT run_id, parameter_set_id, as_of_date
    FROM msbf_ctl.run_registry
    WHERE run_code = 'M1_V0_2_BASELINE_BUILD' AND run_version = 1
), active_values AS (
    SELECT pv.*, pd.data_type, pd.minimum_value_numeric, pd.maximum_value_numeric
    FROM ctx
    JOIN msbf_ctl.parameter_value pv
      ON pv.parameter_set_id = ctx.parameter_set_id
     AND pv.effective_start_date <= ctx.as_of_date
     AND (pv.effective_end_date IS NULL OR pv.effective_end_date > ctx.as_of_date)
    JOIN msbf_ctl.parameter_definition pd
      ON pd.parameter_name = pv.parameter_name
)
INSERT INTO msbf_ctl.profile_resolution_error (
    run_id, profile_domain, scope_key, error_code, severity, error_message
)
SELECT
    ctx.run_id,
    'PARAMETER',
    av.parameter_name || '|' || av.scope_key,
    'PARAMETER_OUT_OF_RANGE',
    'BLOCKING',
    format('Parameter %s scope %s value %s is outside the governed numeric range [%s,%s].',
           av.parameter_name, av.scope_key, av.value_numeric,
           COALESCE(av.minimum_value_numeric::text, '-infinity'),
           COALESCE(av.maximum_value_numeric::text, '+infinity'))
FROM ctx
CROSS JOIN active_values av
WHERE av.data_type IN ('INTEGER','NUMERIC')
  AND (
       (av.minimum_value_numeric IS NOT NULL AND av.value_numeric < av.minimum_value_numeric)
    OR (av.maximum_value_numeric IS NOT NULL AND av.value_numeric > av.maximum_value_numeric)
  );

/* Allowed-value conformance for enumerated text parameters. */
WITH ctx AS (
    SELECT run_id, parameter_set_id, as_of_date
    FROM msbf_ctl.run_registry
    WHERE run_code = 'M1_V0_2_BASELINE_BUILD' AND run_version = 1
), active_values AS (
    SELECT pv.*, pd.data_type, pd.allowed_values
    FROM ctx
    JOIN msbf_ctl.parameter_value pv
      ON pv.parameter_set_id = ctx.parameter_set_id
     AND pv.effective_start_date <= ctx.as_of_date
     AND (pv.effective_end_date IS NULL OR pv.effective_end_date > ctx.as_of_date)
    JOIN msbf_ctl.parameter_definition pd
      ON pd.parameter_name = pv.parameter_name
)
INSERT INTO msbf_ctl.profile_resolution_error (
    run_id, profile_domain, scope_key, error_code, severity, error_message
)
SELECT
    ctx.run_id,
    'PARAMETER',
    av.parameter_name || '|' || av.scope_key,
    'PARAMETER_VALUE_NOT_ALLOWED',
    'BLOCKING',
    format('Parameter %s scope %s value %s is not in the approved allowed-value list.',
           av.parameter_name, av.scope_key, av.value_text)
FROM ctx
CROSS JOIN active_values av
WHERE av.data_type = 'TEXT'
  AND av.allowed_values IS NOT NULL
  AND NOT EXISTS (
      SELECT 1
      FROM jsonb_array_elements_text(av.allowed_values) allowed(value)
      WHERE allowed.value = av.value_text
  );

/* Scope-key conformance to the definition's declared dimensions. */
WITH ctx AS (
    SELECT run_id, parameter_set_id, as_of_date
    FROM msbf_ctl.run_registry
    WHERE run_code = 'M1_V0_2_BASELINE_BUILD' AND run_version = 1
), active_values AS (
    SELECT pv.parameter_name, pv.scope_key, pd.scope_dimensions
    FROM ctx
    JOIN msbf_ctl.parameter_value pv
      ON pv.parameter_set_id = ctx.parameter_set_id
     AND pv.effective_start_date <= ctx.as_of_date
     AND (pv.effective_end_date IS NULL OR pv.effective_end_date > ctx.as_of_date)
    JOIN msbf_ctl.parameter_definition pd
      ON pd.parameter_name = pv.parameter_name
)
INSERT INTO msbf_ctl.profile_resolution_error (
    run_id, profile_domain, scope_key, error_code, severity, error_message
)
SELECT
    ctx.run_id,
    'PARAMETER',
    av.parameter_name || '|' || av.scope_key,
    'INVALID_PARAMETER_SCOPE',
    'BLOCKING',
    format('Parameter %s uses scope %s, inconsistent with declared dimensions %s.',
           av.parameter_name, av.scope_key, av.scope_dimensions::text)
FROM ctx
CROSS JOIN active_values av
WHERE (
        cardinality(av.scope_dimensions) = 0
        AND av.scope_key <> 'GLOBAL'
      )
   OR (
        cardinality(av.scope_dimensions) > 0
        AND av.scope_key <> 'GLOBAL'
        AND NOT (split_part(av.scope_key, ':', 1) = ANY(av.scope_dimensions))
      );

/* -------------------------------------------------------------------------
   Profile cardinality, approval, and effective-date checks.
   ---------------------------------------------------------------------- */
WITH ctx AS (
    SELECT *
    FROM msbf_ctl.run_registry
    WHERE run_code = 'M1_V0_2_BASELINE_BUILD' AND run_version = 1
), profile_checks AS (
    SELECT 'PRODUCT_LEGAL_STRUCTURE'::text AS profile_domain, 'PDR_001'::text AS scope_key,
           COUNT(*) AS observed_count
      FROM ctx JOIN msbf_ctl.product_legal_structure_profile p
        ON p.product_structure_profile_id = ctx.product_structure_profile_id
       AND p.status = 'APPROVED'
       AND p.effective_start_date <= ctx.as_of_date
       AND (p.effective_end_date IS NULL OR p.effective_end_date > ctx.as_of_date)
    UNION ALL
    SELECT 'OPERATING_MODEL', 'DEMO_PROCESSOR_LINKED', COUNT(*)
      FROM ctx JOIN msbf_ctl.operating_model_profile p
        ON p.operating_model_profile_id = ctx.operating_model_profile_id
       AND p.status = 'APPROVED'
       AND p.effective_start_date <= ctx.as_of_date
       AND (p.effective_end_date IS NULL OR p.effective_end_date > ctx.as_of_date)
    UNION ALL
    SELECT 'POLICY', 'M1_G1_BASELINE_POLICY', COUNT(*)
      FROM ctx JOIN msbf_ctl.policy_profile p
        ON p.policy_profile_id = ctx.policy_profile_id
       AND p.status = 'APPROVED'
       AND p.effective_start_date <= ctx.as_of_date
       AND (p.effective_end_date IS NULL OR p.effective_end_date > ctx.as_of_date)
    UNION ALL
    SELECT 'STRATEGY', 'M1_G1_BASELINE_STRATEGY', COUNT(*)
      FROM ctx JOIN msbf_ctl.strategy_profile p
        ON p.strategy_profile_id = ctx.strategy_profile_id
       AND p.status = 'APPROVED'
       AND p.effective_start_date <= ctx.as_of_date
       AND (p.effective_end_date IS NULL OR p.effective_end_date > ctx.as_of_date)
    UNION ALL
    SELECT 'JURISDICTION', 'DEMO_US_PUBLIC_SIM', COUNT(*)
      FROM ctx JOIN msbf_ctl.jurisdiction_profile p
        ON p.jurisdiction_profile_id = ctx.jurisdiction_profile_id
       AND p.status = 'APPROVED'
       AND p.effective_start_date <= ctx.as_of_date
       AND (p.effective_end_date IS NULL OR p.effective_end_date > ctx.as_of_date)
    UNION ALL
    SELECT 'PARAMETER_SET', 'M1_G1_BASELINE_DEMO', COUNT(*)
      FROM ctx JOIN msbf_ctl.parameter_set p
        ON p.parameter_set_id = ctx.parameter_set_id
       AND p.status = 'APPROVED'
       AND p.effective_start_date <= ctx.as_of_date
       AND (p.effective_end_date IS NULL OR p.effective_end_date > ctx.as_of_date)
    UNION ALL
    SELECT 'SCENARIO', 'BASELINE', COUNT(*)
      FROM ctx JOIN msbf_ctl.scenario_registry p
        ON p.scenario_id = ctx.scenario_id
       AND p.status = 'APPROVED'
       AND p.effective_start_date <= ctx.as_of_date
       AND (p.effective_end_date IS NULL OR p.effective_end_date > ctx.as_of_date)
    UNION ALL
    SELECT 'OUTPUT_CONTRACT', 'M1_APPLICATION_RISK_SNAPSHOT', COUNT(*)
      FROM ctx JOIN msbf_ctl.contract_registry p
        ON p.contract_id = ctx.contract_id
       AND p.status = 'APPROVED'
       AND p.effective_start_date <= ctx.as_of_date
       AND (p.effective_end_date IS NULL OR p.effective_end_date > ctx.as_of_date)
    UNION ALL
    SELECT 'THIRD_PARTY_RELATIONSHIP', 'DEMO_PROCESSOR_RELATIONSHIP', COUNT(*)
      FROM ctx CROSS JOIN msbf_ctl.third_party_relationship_profile p
     WHERE p.profile_code = 'DEMO_PROCESSOR_RELATIONSHIP' AND p.profile_version = 1
       AND p.operating_model_profile_id = ctx.operating_model_profile_id
       AND p.status = 'APPROVED'
       AND p.effective_start_date <= ctx.as_of_date
       AND (p.effective_end_date IS NULL OR p.effective_end_date > ctx.as_of_date)
    UNION ALL
    SELECT 'DATA_SEGREGATION', 'DEMO_SYNTHETIC_DATA_ONLY', COUNT(*)
      FROM ctx CROSS JOIN msbf_ctl.data_segregation_profile p
     WHERE p.profile_code = 'DEMO_SYNTHETIC_DATA_ONLY' AND p.profile_version = 1
       AND p.status = 'APPROVED'
       AND p.effective_start_date <= ctx.as_of_date
       AND (p.effective_end_date IS NULL OR p.effective_end_date > ctx.as_of_date)
    UNION ALL
    SELECT 'RECORD_RETENTION', 'DEMO_PROJECT_EVIDENCE_60M', COUNT(*)
      FROM ctx CROSS JOIN msbf_ctl.record_retention_profile p
     WHERE p.profile_code = 'DEMO_PROJECT_EVIDENCE_60M' AND p.profile_version = 1
       AND p.status = 'APPROVED'
       AND p.effective_start_date <= ctx.as_of_date
       AND (p.effective_end_date IS NULL OR p.effective_end_date > ctx.as_of_date)
    UNION ALL
    SELECT 'FINANCIAL_CRIME', 'DEMO_FINCRIME_RESPONSIBILITY', COUNT(*)
      FROM ctx CROSS JOIN msbf_ctl.financial_crime_profile p
     WHERE p.profile_code = 'DEMO_FINCRIME_RESPONSIBILITY' AND p.profile_version = 1
       AND p.operating_model_profile_id = ctx.operating_model_profile_id
       AND p.status = 'APPROVED'
       AND p.effective_start_date <= ctx.as_of_date
       AND (p.effective_end_date IS NULL OR p.effective_end_date > ctx.as_of_date)
    UNION ALL
    SELECT 'PAYMENT_DATA_SCOPE', 'DEMO_NO_PAYMENT_ACCOUNT_DATA', COUNT(*)
      FROM ctx CROSS JOIN msbf_ctl.payment_data_scope_profile p
     WHERE p.profile_code = 'DEMO_NO_PAYMENT_ACCOUNT_DATA' AND p.profile_version = 1
       AND p.status = 'APPROVED'
       AND p.effective_start_date <= ctx.as_of_date
       AND (p.effective_end_date IS NULL OR p.effective_end_date > ctx.as_of_date)
    UNION ALL
    SELECT 'RISK_APPETITE_LIMIT_SET', 'M1_G1_LIMITS', COUNT(*)
      FROM ctx CROSS JOIN msbf_ctl.risk_appetite_limit p
     WHERE p.policy_profile_id = ctx.policy_profile_id
       AND p.status = 'APPROVED'
       AND p.effective_start_date <= ctx.as_of_date
       AND (p.effective_end_date IS NULL OR p.effective_end_date > ctx.as_of_date)
    UNION ALL
    SELECT 'FEATURE_DEFINITION_SET', 'M1_ACTIVE_FEATURES', COUNT(*)
      FROM ctx CROSS JOIN msbf_m1.feature_definition p
     WHERE p.active_flag
)
INSERT INTO msbf_ctl.profile_resolution_error (
    run_id, profile_domain, scope_key, error_code, severity, error_message
)
SELECT
    ctx.run_id,
    pc.profile_domain,
    pc.scope_key,
    'PROFILE_CARDINALITY_OR_APPROVAL_FAILURE',
    'BLOCKING',
    format('Expected exactly %s approved/effective object(s) for %s; observed %s.',
           CASE WHEN pc.profile_domain = 'RISK_APPETITE_LIMIT_SET' THEN 4
                WHEN pc.profile_domain = 'FEATURE_DEFINITION_SET' THEN 32
                ELSE 1 END,
           pc.profile_domain,
           pc.observed_count)
FROM ctx
CROSS JOIN profile_checks pc
WHERE pc.observed_count <> CASE WHEN pc.profile_domain = 'RISK_APPETITE_LIMIT_SET' THEN 4
                                WHEN pc.profile_domain = 'FEATURE_DEFINITION_SET' THEN 32
                                ELSE 1 END;

/* -------------------------------------------------------------------------
   If no blocking errors exist, rebuild the frozen parameter and profile
   snapshots. Otherwise retain errors and set G1_FAILED.
   ---------------------------------------------------------------------- */
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
               notes = 'G1 parameter/profile resolution failed; review msbf_ctl.profile_resolution_error.'
         WHERE run_id = v_run_id;
    ELSE
        DELETE FROM msbf_ctl.run_parameter_snapshot WHERE run_id = v_run_id;
        DELETE FROM msbf_ctl.run_profile_snapshot WHERE run_id = v_run_id;

        UPDATE msbf_ctl.run_registry
           SET run_status = 'READY_FOR_G1_VALIDATION',
               parameter_snapshot_hash = NULL,
               profile_snapshot_hash = NULL,
               notes = 'G1 parameter/profile resolution passed; snapshot construction in progress.'
         WHERE run_id = v_run_id;
    END IF;
END
$$;

/* Parameter snapshot rows. */
WITH ctx AS (
    SELECT run_id, parameter_set_id, as_of_date
    FROM msbf_ctl.run_registry
    WHERE run_code = 'M1_V0_2_BASELINE_BUILD'
      AND run_version = 1
      AND run_status <> 'G1_FAILED'
), resolved AS (
    SELECT
        ctx.run_id,
        pv.parameter_name,
        pv.scope_key,
        jsonb_strip_nulls(jsonb_build_object(
            'definition_version', pd.definition_version,
            'data_type', pd.data_type,
            'unit_code', COALESCE(pv.unit_code, pd.unit_code),
            'scope_payload', pv.scope_payload,
            'effective_start_date', pv.effective_start_date,
            'effective_end_date', pv.effective_end_date,
            'value_numeric', CASE WHEN pd.data_type IN ('INTEGER','NUMERIC') THEN pv.value_numeric END,
            'value_text', CASE WHEN pd.data_type = 'TEXT' THEN pv.value_text END,
            'value_boolean', CASE WHEN pd.data_type = 'BOOLEAN' THEN pv.value_boolean END,
            'value_date', CASE WHEN pd.data_type = 'DATE' THEN pv.value_date END,
            'value_json', CASE WHEN pd.data_type = 'JSON' THEN pv.value_json END
        )) AS resolved_value,
        CASE split_part(pv.scope_key, ':', 1)
            WHEN 'GLOBAL' THEN 10
            WHEN 'SOURCE' THEN 20
            WHEN 'INDUSTRY' THEN 30
            WHEN 'REGION' THEN 30
            WHEN 'MERCHANT_SIZE_TIER' THEN 30
            WHEN 'LEGAL_ENTITY_TYPE' THEN 30
            WHEN 'PARTNER_CHANNEL' THEN 30
            WHEN 'RELATIONSHIP_STAGE' THEN 30
            WHEN 'USE_OF_PROCEEDS' THEN 30
            WHEN 'EXPECTED_PAYOFF_DAYS' THEN 30
            WHEN 'VERIFICATION_CHECK' THEN 30
            WHEN 'CASHFLOW_ARCHETYPE' THEN 30
            WHEN 'RISK_TIER' THEN 40
            WHEN 'RISK_ZONE' THEN 40
            WHEN 'PATH_DAY_BUCKET' THEN 40
            WHEN 'SCENARIO' THEN 50
            ELSE 90
        END::smallint AS resolution_rank,
        pv.parameter_value_id AS source_parameter_value_id
    FROM ctx
    JOIN msbf_ctl.parameter_value pv
      ON pv.parameter_set_id = ctx.parameter_set_id
     AND pv.effective_start_date <= ctx.as_of_date
     AND (pv.effective_end_date IS NULL OR pv.effective_end_date > ctx.as_of_date)
    JOIN msbf_ctl.parameter_definition pd
      ON pd.parameter_name = pv.parameter_name
)
INSERT INTO msbf_ctl.run_parameter_snapshot (
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
    md5(parameter_name || '|' || scope_key || '|' || resolved_value::text)
FROM resolved;

/* Calculate and persist the deterministic parameter hash. */
WITH ctx AS (
    SELECT run_id, parameter_set_id
    FROM msbf_ctl.run_registry
    WHERE run_code = 'M1_V0_2_BASELINE_BUILD' AND run_version = 1
), hashes AS (
    SELECT
        s.run_id,
        md5(string_agg(
            s.parameter_name || '|' || s.scope_key || '|' || s.snapshot_hash,
            '||' ORDER BY s.parameter_name, s.scope_key
        )) AS parameter_hash
    FROM msbf_ctl.run_parameter_snapshot s
    JOIN ctx ON ctx.run_id = s.run_id
    GROUP BY s.run_id
)
UPDATE msbf_ctl.run_registry r
   SET parameter_snapshot_hash = h.parameter_hash
  FROM hashes h
 WHERE r.run_id = h.run_id;

UPDATE msbf_ctl.parameter_set ps
   SET parameter_set_hash = r.parameter_snapshot_hash
  FROM msbf_ctl.run_registry r
 WHERE ps.parameter_set_id = r.parameter_set_id
   AND r.run_code = 'M1_V0_2_BASELINE_BUILD'
   AND r.run_version = 1;

/* Profile snapshots, including the feature-definition set and four limits. */
WITH ctx AS (
    SELECT *
    FROM msbf_ctl.run_registry
    WHERE run_code = 'M1_V0_2_BASELINE_BUILD'
      AND run_version = 1
      AND run_status <> 'G1_FAILED'
), profile_rows AS (
    SELECT 'PRODUCT_LEGAL_STRUCTURE'::text AS profile_domain,
           p.profile_code, p.profile_version,
           p.product_structure_profile_id AS resolved_profile_id,
           to_jsonb(p) - 'created_at' - 'created_by' - 'approval_timestamp' AS payload
    FROM ctx JOIN msbf_ctl.product_legal_structure_profile p
      ON p.product_structure_profile_id = ctx.product_structure_profile_id

    UNION ALL
    SELECT 'OPERATING_MODEL', p.profile_code, p.profile_version,
           p.operating_model_profile_id,
           to_jsonb(p) - 'created_at' - 'created_by' - 'approval_timestamp'
    FROM ctx JOIN msbf_ctl.operating_model_profile p
      ON p.operating_model_profile_id = ctx.operating_model_profile_id

    UNION ALL
    SELECT 'POLICY', p.profile_code, p.profile_version,
           p.policy_profile_id,
           to_jsonb(p) - 'created_at' - 'created_by' - 'approval_timestamp'
    FROM ctx JOIN msbf_ctl.policy_profile p
      ON p.policy_profile_id = ctx.policy_profile_id

    UNION ALL
    SELECT 'STRATEGY', p.profile_code, p.profile_version,
           p.strategy_profile_id,
           to_jsonb(p) - 'created_at' - 'created_by' - 'approval_timestamp'
    FROM ctx JOIN msbf_ctl.strategy_profile p
      ON p.strategy_profile_id = ctx.strategy_profile_id

    UNION ALL
    SELECT 'JURISDICTION', p.profile_code, p.profile_version,
           p.jurisdiction_profile_id,
           to_jsonb(p) - 'created_at' - 'created_by' - 'approval_timestamp'
    FROM ctx JOIN msbf_ctl.jurisdiction_profile p
      ON p.jurisdiction_profile_id = ctx.jurisdiction_profile_id

    UNION ALL
    SELECT 'PARAMETER_SET', p.parameter_set_code, p.parameter_set_version,
           p.parameter_set_id,
           to_jsonb(p) - 'created_at' - 'approval_timestamp'
    FROM ctx JOIN msbf_ctl.parameter_set p
      ON p.parameter_set_id = ctx.parameter_set_id

    UNION ALL
    SELECT 'SCENARIO', p.scenario_code, p.scenario_version,
           p.scenario_id,
           to_jsonb(p)
    FROM ctx JOIN msbf_ctl.scenario_registry p
      ON p.scenario_id = ctx.scenario_id

    UNION ALL
    SELECT 'OUTPUT_CONTRACT', p.contract_code, p.contract_version,
           p.contract_id,
           to_jsonb(p)
    FROM ctx JOIN msbf_ctl.contract_registry p
      ON p.contract_id = ctx.contract_id

    UNION ALL
    SELECT 'THIRD_PARTY_RELATIONSHIP', p.profile_code, p.profile_version,
           p.third_party_relationship_profile_id,
           to_jsonb(p) - 'created_at' - 'created_by' - 'approval_timestamp'
    FROM ctx CROSS JOIN msbf_ctl.third_party_relationship_profile p
    WHERE p.profile_code = 'DEMO_PROCESSOR_RELATIONSHIP' AND p.profile_version = 1

    UNION ALL
    SELECT 'DATA_SEGREGATION', p.profile_code, p.profile_version,
           p.data_segregation_profile_id,
           to_jsonb(p) - 'created_at' - 'created_by' - 'approval_timestamp'
    FROM ctx CROSS JOIN msbf_ctl.data_segregation_profile p
    WHERE p.profile_code = 'DEMO_SYNTHETIC_DATA_ONLY' AND p.profile_version = 1

    UNION ALL
    SELECT 'RECORD_RETENTION', p.profile_code, p.profile_version,
           p.record_retention_profile_id,
           to_jsonb(p) - 'created_at' - 'created_by' - 'approval_timestamp'
    FROM ctx CROSS JOIN msbf_ctl.record_retention_profile p
    WHERE p.profile_code = 'DEMO_PROJECT_EVIDENCE_60M' AND p.profile_version = 1

    UNION ALL
    SELECT 'FINANCIAL_CRIME', p.profile_code, p.profile_version,
           p.financial_crime_profile_id,
           to_jsonb(p) - 'created_at' - 'created_by' - 'approval_timestamp'
    FROM ctx CROSS JOIN msbf_ctl.financial_crime_profile p
    WHERE p.profile_code = 'DEMO_FINCRIME_RESPONSIBILITY' AND p.profile_version = 1

    UNION ALL
    SELECT 'PAYMENT_DATA_SCOPE', p.profile_code, p.profile_version,
           p.payment_data_scope_profile_id,
           to_jsonb(p) - 'created_at' - 'created_by' - 'approval_timestamp'
    FROM ctx CROSS JOIN msbf_ctl.payment_data_scope_profile p
    WHERE p.profile_code = 'DEMO_NO_PAYMENT_ACCOUNT_DATA' AND p.profile_version = 1

    UNION ALL
    SELECT 'RISK_APPETITE_LIMIT', p.limit_code, p.limit_version,
           p.limit_id,
           to_jsonb(p)
    FROM ctx CROSS JOIN msbf_ctl.risk_appetite_limit p
    WHERE p.policy_profile_id = ctx.policy_profile_id
      AND p.status = 'APPROVED'
      AND p.effective_start_date <= ctx.as_of_date
      AND (p.effective_end_date IS NULL OR p.effective_end_date > ctx.as_of_date)

    UNION ALL
    SELECT 'FEATURE_DEFINITION_SET', 'M1_ACTIVE_FEATURES', 1,
           1::bigint,
           jsonb_build_object(
               'active_feature_count', COUNT(*),
               'feature_set_hash', md5(string_agg(
                   f.feature_code || '|' || f.feature_version::text || '|' ||
                   f.formula_description || '|' || f.production_boundary,
                   '||' ORDER BY f.feature_code, f.feature_version
               )),
               'contract_code', 'M1_APPLICATION_RISK_SNAPSHOT',
               'contract_version', 1
           )
    FROM ctx CROSS JOIN msbf_m1.feature_definition f
    WHERE f.active_flag
    GROUP BY ctx.run_id
)
INSERT INTO msbf_ctl.run_profile_snapshot (
    run_id, profile_domain, profile_code, profile_version,
    resolved_profile_id, profile_hash, snapshot_payload
)
SELECT
    ctx.run_id,
    pr.profile_domain,
    pr.profile_code,
    pr.profile_version,
    pr.resolved_profile_id,
    md5(pr.payload::text),
    pr.payload
FROM ctx
CROSS JOIN profile_rows pr;

WITH ctx AS (
    SELECT run_id
    FROM msbf_ctl.run_registry
    WHERE run_code = 'M1_V0_2_BASELINE_BUILD' AND run_version = 1
), hashes AS (
    SELECT
        s.run_id,
        md5(string_agg(
            s.profile_domain || '|' || s.profile_code || '|' ||
            s.profile_version::text || '|' || s.profile_hash,
            '||' ORDER BY s.profile_domain, s.profile_code
        )) AS profile_hash
    FROM msbf_ctl.run_profile_snapshot s
    JOIN ctx ON ctx.run_id = s.run_id
    GROUP BY s.run_id
)
UPDATE msbf_ctl.run_registry r
   SET profile_snapshot_hash = h.profile_hash,
       notes = 'G1 parameter and profile snapshots constructed; source snapshot pending.'
  FROM hashes h
 WHERE r.run_id = h.run_id;

COMMIT;

SELECT
    r.run_id,
    r.run_status,
    COUNT(DISTINCT ps.parameter_name) AS parameter_name_count,
    COUNT(*) AS parameter_snapshot_rows,
    r.parameter_snapshot_hash,
    (SELECT COUNT(*) FROM msbf_ctl.run_profile_snapshot p WHERE p.run_id = r.run_id) AS profile_snapshot_rows,
    r.profile_snapshot_hash,
    (SELECT COUNT(*) FROM msbf_ctl.profile_resolution_error e WHERE e.run_id = r.run_id AND e.severity = 'BLOCKING') AS blocking_resolution_errors
FROM msbf_ctl.run_registry r
JOIN msbf_ctl.run_parameter_snapshot ps ON ps.run_id = r.run_id
WHERE r.run_code = 'M1_V0_2_BASELINE_BUILD'
  AND r.run_version = 1
GROUP BY r.run_id, r.run_status, r.parameter_snapshot_hash, r.profile_snapshot_hash;
