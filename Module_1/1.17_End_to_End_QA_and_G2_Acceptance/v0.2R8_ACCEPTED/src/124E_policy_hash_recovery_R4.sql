/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
M1.17 — End-to-End QA, Evidence & G2 Contract Acceptance

Program
124E_msbf_m1_17_failed_policy_hash_shape_validation_recovery_v0_2R4.sql

Purpose
Verify that the sole Program 127 failure is a false-negative implementation
of M1_17_POS_007_POLICY_HASH_SHAPE, preserve the original finding as audit
history, correct the governed positive-validation evidence, and return the
run and G2 bundle to the VALIDATED state without regenerating M1.17.

Why this is controlled
- Program 126 committed 18 hash-chain rows, 48 evidence rows, one latest
  bundle, one archive bundle and one registry row with zero canonical
  mismatches.
- Program 127 executed all 128 positive controls; 127 passed and POS007 alone
  failed.
- The observed policy hash is 32 lowercase hexadecimal characters.
- This recovery also proves the stored hash equals the deterministic hash of
  the persisted policy payload.
- No generated, accepted-predecessor, archive, hash-chain, evidence-snapshot
  or analytical row is modified.

DBeaver note
This script intentionally avoids the braced repetition quantifier so DBeaver
cannot misinterpret the number as a bind parameter. Shape is established by:
    length(configuration_hash) = 32
    AND configuration_hash ~ '^[0-9a-f]+$'

v0.2R4 source correction
The v0.2R3 recovery source used string concatenation in a PL/pgSQL RAISE
format clause. PostgreSQL requires one literal format string followed by its
arguments. v0.2R4 corrects that syntax only; no recovery or business logic is
changed.

Normal execution
1. Do not rerun Programs 124C, 125, 126 or 127.
2. Run this complete script with Execute SQL Script.
3. Require recovery_status = PASS.
4. Continue with Programs 128–131 from the v0.2R2 package.
============================================================================ */

BEGIN;

SET LOCAL work_mem = '64MB';
SET LOCAL lock_timeout = '10s';
SET LOCAL statement_timeout = '15min';
SET LOCAL jit = off;

DROP TABLE IF EXISTS _m1_17_r3_policy_hash_recovery;

CREATE TEMP TABLE _m1_17_r3_policy_hash_recovery
ON COMMIT PRESERVE ROWS
AS
WITH governed_run AS
(
    SELECT
        run_id,
        run_status
    FROM msbf_ctl.run_registry
    WHERE run_code = 'M1_V0_2_BASELINE_BUILD'
      AND run_version = 1
),
policy AS
(
    SELECT
        p.policy_code,
        p.methodology_version,
        p.bundle_code,
        p.bundle_version,
        p.schema_version,
        p.expected_hash_chain_rows,
        p.expected_evidence_rows,
        p.expected_bundle_latest_rows,
        p.expected_bundle_archive_rows,
        p.expected_registry_rows,
        p.expected_integrated_rows,
        p.expected_canonical_entities,
        p.expected_positive_controls,
        p.expected_negative_controls,
        p.expected_detail_result_sets,
        p.required_predecessor_gates,
        p.synthetic_data_only_flag,
        p.no_new_business_analytics_flag,
        p.no_module2_outputs_flag,
        p.package_static_validation_required,
        p.policy_status,
        p.configuration_hash,
        length(p.configuration_hash)::integer AS policy_hash_character_length,
        octet_length(p.configuration_hash)::integer AS policy_hash_byte_length,
        (p.configuration_hash ~ '^[0-9a-f]+$') AS policy_hash_lowercase_hex,
        (
            p.configuration_hash =
            msbf_ctl.m1_17_hash_jsonb(
                jsonb_build_object(
                    'policy_code', p.policy_code,
                    'methodology_version', p.methodology_version,
                    'bundle_code', p.bundle_code,
                    'bundle_version', p.bundle_version,
                    'schema_version', p.schema_version,
                    'hash_chain_rows', p.expected_hash_chain_rows,
                    'evidence_rows', p.expected_evidence_rows,
                    'canonical_entities', p.expected_canonical_entities,
                    'integrated_rows', p.expected_integrated_rows,
                    'positive_controls', p.expected_positive_controls,
                    'negative_controls', p.expected_negative_controls,
                    'detail_result_sets', p.expected_detail_result_sets,
                    'predecessor_gates', p.required_predecessor_gates,
                    'synthetic_only', p.synthetic_data_only_flag,
                    'no_new_business_analytics',
                        p.no_new_business_analytics_flag,
                    'no_module2_outputs', p.no_module2_outputs_flag,
                    'package_static_validation_required',
                        p.package_static_validation_required
                )
            )
        ) AS policy_payload_hash_match
    FROM msbf_ctl.m1_17_policy_profile AS p
    WHERE p.policy_code = 'M1_17_G2_ASSURANCE_V1'
),
registry AS
(
    SELECT
        bundle_status,
        integrated_consumption_rows,
        hash_chain_rows,
        evidence_snapshot_rows,
        canonical_entities,
        hash_chain_set_hash,
        evidence_set_hash,
        bundle_latest_set_hash,
        bundle_archive_set_hash,
        contract_set_hash,
        combined_g2_hash
    FROM msbf_ctl.m1_17_g2_bundle_registry
    WHERE module1_run_id = (SELECT run_id FROM governed_run)
),
positive_evidence AS
(
    SELECT
        count(*)::bigint AS positive_checks,
        count(*) FILTER (WHERE status = 'PASS')::bigint
            AS positive_passes,
        count(*) FILTER (WHERE status = 'FAIL')::bigint
            AS positive_failures,
        string_agg(evidence_code, ',' ORDER BY evidence_code)
            FILTER (WHERE status = 'FAIL') AS failed_positive_codes,
        max(metric_value_text)
            FILTER (
                WHERE evidence_code =
                    'M1_17_POS_007_POLICY_HASH_SHAPE'
            ) AS reported_pos007_value
    FROM msbf_ctl.run_evidence
    WHERE run_id = (SELECT run_id FROM governed_run)
      AND evidence_code LIKE 'M1_17_POS_%'
),
physical AS
(
    SELECT
        (SELECT count(*)
         FROM msbf_ctl.m1_17_hash_chain_snapshot
         WHERE module1_run_id = (SELECT run_id FROM governed_run))
            AS hash_chain_rows,
        (SELECT count(*)
         FROM msbf_ctl.m1_17_end_to_end_evidence_snapshot
         WHERE module1_run_id = (SELECT run_id FROM governed_run))
            AS evidence_snapshot_rows,
        (SELECT count(*)
         FROM msbf_ctl.m1_17_g2_bundle_registry
         WHERE module1_run_id = (SELECT run_id FROM governed_run))
            AS registry_rows,
        (SELECT count(*)
         FROM msbf_ctl.m1_17_g2_bundle_latest
         WHERE module1_run_id = (SELECT run_id FROM governed_run))
            AS latest_rows,
        (SELECT count(*)
         FROM msbf_ctl.m1_17_g2_bundle_archive
         WHERE module1_run_id = (SELECT run_id FROM governed_run))
            AS archive_rows,
        (SELECT count(*)
         FROM msbf_m1.v_m1_17_g2_integrated_consumption
         WHERE module1_run_id = (SELECT run_id FROM governed_run))
            AS integrated_rows,
        (SELECT count(*)
         FROM msbf_ctl.profile_resolution_error
         WHERE run_id = (SELECT run_id FROM governed_run)
           AND severity = 'BLOCKING')
            AS blocking_errors,
        msbf_ctl.m1_17_schema_row_count('msbf_m2')
            AS module2_rows,
        (SELECT count(*)
         FROM msbf_ctl.acceptance_gate_result AS g
         WHERE g.run_id = (SELECT run_id FROM governed_run)
           AND g.gate_id = 'G2_M1_CONTRACT')
            AS g2_result_rows,
        (SELECT count(*)
         FROM msbf_ctl.run_evidence
         WHERE run_id = (SELECT run_id FROM governed_run)
           AND evidence_code LIKE 'M1_17_NEG_%')
            AS negative_evidence_rows
)
SELECT
    governed_run.run_id,
    governed_run.run_status AS prior_run_status,
    registry.bundle_status AS prior_bundle_status,
    positive_evidence.*,
    policy.*,
    physical.hash_chain_rows AS physical_hash_chain_rows,
    physical.evidence_snapshot_rows AS physical_evidence_snapshot_rows,
    physical.registry_rows,
    physical.latest_rows,
    physical.archive_rows,
    physical.integrated_rows,
    physical.blocking_errors,
    physical.module2_rows,
    physical.g2_result_rows,
    physical.negative_evidence_rows,
    registry.integrated_consumption_rows
        AS registered_integrated_consumption_rows,
    registry.hash_chain_rows
        AS registered_hash_chain_rows,
    registry.evidence_snapshot_rows
        AS registered_evidence_snapshot_rows,
    registry.canonical_entities
        AS registered_canonical_entities,
    registry.hash_chain_set_hash,
    registry.evidence_set_hash,
    registry.bundle_latest_set_hash,
    registry.bundle_archive_set_hash,
    registry.contract_set_hash,
    registry.combined_g2_hash
FROM governed_run
CROSS JOIN policy
CROSS JOIN registry
CROSS JOIN positive_evidence
CROSS JOIN physical;

DO $m1_17_r4_policy_hash_recovery_guard$
DECLARE
    v record;
BEGIN
    SELECT *
    INTO v
    FROM _m1_17_r3_policy_hash_recovery;

    IF v.prior_run_status <> 'M1_17_FAILED'
       OR v.prior_bundle_status <> 'GENERATED'
       OR v.positive_checks <> 128
       OR v.positive_passes <> 127
       OR v.positive_failures <> 1
       OR v.failed_positive_codes <>
            'M1_17_POS_007_POLICY_HASH_SHAPE'
       OR v.reported_pos007_value IS DISTINCT FROM v.configuration_hash
       OR v.policy_status <> 'APPROVED'
       OR v.policy_hash_character_length <> 32
       OR v.policy_hash_byte_length <> 32
       OR v.policy_hash_lowercase_hex IS DISTINCT FROM TRUE
       OR v.policy_payload_hash_match IS DISTINCT FROM TRUE
       OR v.physical_hash_chain_rows <> 18
       OR v.physical_evidence_snapshot_rows <> 48
       OR v.registry_rows <> 1
       OR v.latest_rows <> 1
       OR v.archive_rows <> 1
       OR v.integrated_rows <> 1500
       OR v.registered_integrated_consumption_rows <> 1500
       OR v.registered_hash_chain_rows <> 18
       OR v.registered_evidence_snapshot_rows <> 48
       OR v.registered_canonical_entities <> 69
       OR v.hash_chain_set_hash IS NULL
       OR v.evidence_set_hash IS NULL
       OR v.bundle_latest_set_hash IS NULL
       OR v.bundle_archive_set_hash IS NULL
       OR v.contract_set_hash IS NULL
       OR v.combined_g2_hash IS NULL
       OR v.blocking_errors <> 0
       OR v.module2_rows <> 0
       OR v.g2_result_rows <> 0
       OR v.negative_evidence_rows <> 0 THEN
        RAISE EXCEPTION
            'M1.17 v0.2R4 policy-hash recovery preconditions failed: %',
            row_to_json(v);
    END IF;
END;
$m1_17_r4_policy_hash_recovery_guard$;

INSERT INTO msbf_ctl.run_evidence
(
    run_id,
    evidence_code,
    segment_key,
    metric_name,
    metric_value_numeric,
    metric_value_text,
    unit_code,
    status,
    interpretation
)
SELECT
    run_id,
    'M1_17_HIST_POS_007_V0_2R2',
    'PORTFOLIO',
    'SUPERSEDED_POLICY_HASH_SHAPE_FINDING',
    NULL::numeric(24,10),
    reported_pos007_value,
    'AUDIT_HISTORY',
    'SUPERSEDED',
    'Program 127 v0.2R2 reported POS007 as FAIL even though the stored '
    || 'configuration hash was exactly 32 lowercase hexadecimal characters '
    || 'and matched the deterministic hash of the persisted policy payload. '
    || 'The finding is preserved as superseded validation history.'
FROM _m1_17_r3_policy_hash_recovery
ON CONFLICT (run_id, evidence_code, segment_key)
DO UPDATE
SET
    metric_name = EXCLUDED.metric_name,
    metric_value_numeric = EXCLUDED.metric_value_numeric,
    metric_value_text = EXCLUDED.metric_value_text,
    unit_code = EXCLUDED.unit_code,
    status = EXCLUDED.status,
    interpretation = EXCLUDED.interpretation,
    created_at = clock_timestamp();

UPDATE msbf_ctl.run_evidence AS e
SET
    metric_value_numeric = NULL,
    metric_value_text = r.configuration_hash,
    unit_code = 'VALIDATION',
    status = 'PASS',
    interpretation =
        'Policy configuration hash is exactly 32 lowercase hexadecimal '
        || 'characters and equals the deterministic hash of the persisted '
        || 'approved M1.17 policy payload. The validation uses separate '
        || 'length and hexadecimal checks to avoid DBeaver bind-parameter '
        || 'interpretation of a regex quantifier.'
FROM _m1_17_r3_policy_hash_recovery AS r
WHERE e.run_id = r.run_id
  AND e.evidence_code = 'M1_17_POS_007_POLICY_HASH_SHAPE'
  AND e.segment_key = 'PORTFOLIO';

DO $m1_17_r4_policy_hash_evidence_guard$
DECLARE
    v_total bigint;
    v_pass bigint;
    v_fail bigint;
BEGIN
    SELECT
        count(*),
        count(*) FILTER (WHERE status = 'PASS'),
        count(*) FILTER (WHERE status = 'FAIL')
    INTO
        v_total,
        v_pass,
        v_fail
    FROM msbf_ctl.run_evidence
    WHERE run_id = (
        SELECT run_id
        FROM _m1_17_r3_policy_hash_recovery
    )
      AND evidence_code LIKE 'M1_17_POS_%';

    IF v_total <> 128
       OR v_pass <> 128
       OR v_fail <> 0 THEN
        RAISE EXCEPTION
            'M1.17 v0.2R4 corrected positive-evidence inventory failed: total %, pass %, fail %.',
            v_total,
            v_pass,
            v_fail;
    END IF;
END;
$m1_17_r4_policy_hash_evidence_guard$;

UPDATE msbf_ctl.m1_17_g2_bundle_registry
SET
    bundle_status = 'VALIDATED',
    validated_at = clock_timestamp()
WHERE module1_run_id = (
        SELECT run_id
        FROM _m1_17_r3_policy_hash_recovery
    );

UPDATE msbf_ctl.run_registry
SET
    run_status = 'M1_17_VALIDATED',
    notes = coalesce(notes, '')
        || ' | M1.17 v0.2R4 validation recovery: '
        || 'POS007 policy-hash shape false negative corrected; '
        || 'all 128 positive controls PASS; generated G2 evidence unchanged.'
WHERE run_id = (
        SELECT run_id
        FROM _m1_17_r3_policy_hash_recovery
    );

ALTER TABLE _m1_17_r3_policy_hash_recovery
    ADD COLUMN final_run_status text,
    ADD COLUMN final_bundle_status text,
    ADD COLUMN final_positive_checks bigint,
    ADD COLUMN final_positive_passes bigint,
    ADD COLUMN final_positive_failures bigint,
    ADD COLUMN preserved_history_rows bigint,
    ADD COLUMN recovery_status text;

UPDATE _m1_17_r3_policy_hash_recovery AS r
SET
    final_run_status = (
        SELECT run_status
        FROM msbf_ctl.run_registry
        WHERE run_id = r.run_id
    ),
    final_bundle_status = (
        SELECT bundle_status
        FROM msbf_ctl.m1_17_g2_bundle_registry
        WHERE module1_run_id = r.run_id
    ),
    final_positive_checks = (
        SELECT count(*)
        FROM msbf_ctl.run_evidence
        WHERE run_id = r.run_id
          AND evidence_code LIKE 'M1_17_POS_%'
    ),
    final_positive_passes = (
        SELECT count(*)
        FROM msbf_ctl.run_evidence
        WHERE run_id = r.run_id
          AND evidence_code LIKE 'M1_17_POS_%'
          AND status = 'PASS'
    ),
    final_positive_failures = (
        SELECT count(*)
        FROM msbf_ctl.run_evidence
        WHERE run_id = r.run_id
          AND evidence_code LIKE 'M1_17_POS_%'
          AND status = 'FAIL'
    ),
    preserved_history_rows = (
        SELECT count(*)
        FROM msbf_ctl.run_evidence
        WHERE run_id = r.run_id
          AND evidence_code = 'M1_17_HIST_POS_007_V0_2R2'
    ),
    recovery_status = 'PASS'
WHERE r.run_id IS NOT NULL;

DO $m1_17_r4_policy_hash_final_guard$
DECLARE
    v record;
BEGIN
    SELECT *
    INTO v
    FROM _m1_17_r3_policy_hash_recovery;

    IF v.final_run_status <> 'M1_17_VALIDATED'
       OR v.final_bundle_status <> 'VALIDATED'
       OR v.final_positive_checks <> 128
       OR v.final_positive_passes <> 128
       OR v.final_positive_failures <> 0
       OR v.preserved_history_rows <> 1 THEN
        RAISE EXCEPTION
            'M1.17 v0.2R4 final recovery state failed: %',
            row_to_json(v);
    END IF;
END;
$m1_17_r4_policy_hash_final_guard$;

COMMIT;

SELECT
    prior_run_status,
    prior_bundle_status,
    positive_checks AS prior_positive_checks,
    positive_passes AS prior_positive_passes,
    positive_failures AS prior_positive_failures,
    failed_positive_codes,
    reported_pos007_value,
    configuration_hash,
    policy_hash_character_length,
    policy_hash_byte_length,
    policy_hash_lowercase_hex,
    policy_payload_hash_match,
    physical_hash_chain_rows,
    physical_evidence_snapshot_rows,
    registry_rows,
    latest_rows,
    archive_rows,
    integrated_rows,
    registered_canonical_entities,
    blocking_errors,
    module2_rows,
    g2_result_rows,
    final_run_status,
    final_bundle_status,
    final_positive_checks,
    final_positive_passes,
    final_positive_failures,
    preserved_history_rows,
    recovery_status
FROM _m1_17_r3_policy_hash_recovery;
