/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.10 — Portfolio Performance, KPI & Servicing Analytics

Program     : 207C_msbf_m2_10_definition_hash_repair_and_identity_reconciliation_v0_2R3.sql
Version     : v0.2R3

Purpose
-------
Atomically normalize the four Program 204 dictionary row hashes to their
persisted physical column names, then reconcile the four affected definition
set hashes, registry row hash, contract hash, complete canonical hash, and six
existing governed generation-evidence hash records. Preserve all Program 206
business rows, counts, amounts, timestamps, source boundaries, and lifecycle
status.

Preconditions
-------------
Run only after stopping failed Program 207, executing ROLLBACK, and obtaining
`diagnostic_status = PASS` from Program 207B.

Required result
---------------
repair_status = PASS; all four physical mismatch counts = 0; canonical
entities = 370; registry, contract, canonical, and governed evidence hashes
reconcile; run_status and contract_status remain GENERATED.
============================================================================ */

BEGIN;

SET LOCAL lock_timeout='10s';
SET LOCAL statement_timeout='35min';
SET LOCAL jit=off;

DROP TABLE IF EXISTS _m2_10_hash_repair_result;
CREATE TEMP TABLE _m2_10_hash_repair_result
(
    run_id bigint,
    run_status text,
    contract_status text,
    before_kpi_mismatches bigint,
    before_tier_mismatches bigint,
    before_queue_mismatches bigint,
    before_reason_mismatches bigint,
    after_kpi_mismatches bigint,
    after_tier_mismatches bigint,
    after_queue_mismatches bigint,
    after_reason_mismatches bigint,
    before_kpi_definition_set_hash text,
    after_kpi_definition_set_hash text,
    before_performance_tier_set_hash text,
    after_performance_tier_set_hash text,
    before_servicing_queue_set_hash text,
    after_servicing_queue_set_hash text,
    before_reason_set_hash text,
    after_reason_set_hash text,
    before_contract_set_hash text,
    after_contract_set_hash text,
    before_combined_set_hash text,
    after_combined_set_hash text,
    canonical_entities bigint,
    registry_hash_errors bigint,
    contract_hash_errors bigint,
    generation_hash_evidence_errors bigint,
    generation_evidence_rows bigint,
    positive_evidence_rows bigint,
    negative_evidence_rows bigint,
    acceptance_evidence_rows bigint,
    acceptance_gate_rows bigint,
    repair_status text
)
ON COMMIT PRESERVE ROWS;

DROP TABLE IF EXISTS _m2_10_hash_repair_before;
CREATE TEMP TABLE _m2_10_hash_repair_before
ON COMMIT DROP
AS
WITH run_context AS
(
    SELECT run_id,run_status
    FROM msbf_ctl.run_registry
    WHERE run_code='M1_V0_2_BASELINE_BUILD'
      AND run_version=1
),
registry AS
(
    SELECT *
    FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry
    WHERE module1_run_id=(SELECT run_id FROM run_context)
),
hash_state AS
(
    SELECT
        (
            SELECT count(*)
            FROM msbf_m2.portfolio_kpi_definition AS definition
            WHERE definition.module1_run_id=(SELECT run_id FROM run_context)
              AND definition.row_hash IS DISTINCT FROM
                  msbf_ctl.m2_10_hash_jsonb
                  (to_jsonb(definition)-'row_hash'-'created_at')
        )::bigint AS kpi_mismatches,
        (
            SELECT count(*)
            FROM msbf_m2.portfolio_performance_tier_definition AS definition
            WHERE definition.module1_run_id=(SELECT run_id FROM run_context)
              AND definition.row_hash IS DISTINCT FROM
                  msbf_ctl.m2_10_hash_jsonb
                  (to_jsonb(definition)-'row_hash'-'created_at')
        )::bigint AS tier_mismatches,
        (
            SELECT count(*)
            FROM msbf_m2.servicing_queue_definition AS definition
            WHERE definition.module1_run_id=(SELECT run_id FROM run_context)
              AND definition.row_hash IS DISTINCT FROM
                  msbf_ctl.m2_10_hash_jsonb
                  (to_jsonb(definition)-'row_hash'-'created_at')
        )::bigint AS queue_mismatches,
        (
            SELECT count(*)
            FROM msbf_m2.portfolio_analytics_reason_definition AS definition
            WHERE definition.module1_run_id=(SELECT run_id FROM run_context)
              AND definition.row_hash IS DISTINCT FROM
                  msbf_ctl.m2_10_hash_jsonb
                  (to_jsonb(definition)-'row_hash'-'created_at')
        )::bigint AS reason_mismatches
),
evidence_state AS
(
    SELECT
        count(*) FILTER(WHERE evidence_code LIKE 'M2_10_POS_%')::bigint
            AS positive_rows,
        count(*) FILTER(WHERE evidence_code LIKE 'M2_10_NEG_%')::bigint
            AS negative_rows,
        count(*) FILTER
        (
            WHERE evidence_code LIKE 'M2_10_%'
              AND evidence_code NOT LIKE 'M2_10_POS_%'
              AND evidence_code NOT LIKE 'M2_10_NEG_%'
              AND evidence_code<>'M2_10_ACCEPTANCE_SUMMARY'
        )::bigint AS generation_rows,
        count(*) FILTER
        (WHERE evidence_code='M2_10_ACCEPTANCE_SUMMARY')::bigint
            AS acceptance_rows
    FROM msbf_ctl.run_evidence
    WHERE run_id=(SELECT run_id FROM run_context)
),
gate_state AS
(
    SELECT count(*)::bigint AS gate_rows
    FROM msbf_ctl.acceptance_gate_result
    WHERE run_id=(SELECT run_id FROM run_context)
      AND gate_id='M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS'
)
SELECT
    run_context.run_id,
    run_context.run_status,
    registry.contract_status,
    hash_state.*,
    registry.kpi_definition_set_hash,
    registry.performance_tier_set_hash,
    registry.servicing_queue_set_hash,
    registry.reason_set_hash,
    registry.contract_set_hash,
    registry.combined_set_hash,
    registry.canonical_entities,
    evidence_state.*,
    gate_state.gate_rows
FROM run_context
CROSS JOIN registry
CROSS JOIN hash_state
CROSS JOIN evidence_state
CROSS JOIN gate_state;

DO $m2_10_hash_repair_precondition$
DECLARE
    v record;
BEGIN
    SELECT * INTO v FROM _m2_10_hash_repair_before;

    IF v.run_status<>'M2_10_GENERATED'
       OR v.contract_status<>'GENERATED'
       OR v.canonical_entities<>370
       OR v.positive_rows<>0
       OR v.negative_rows<>0
       OR v.generation_rows<>24
       OR v.acceptance_rows<>0
       OR v.gate_rows<>0
       OR NOT
          (
              (
                  v.kpi_mismatches=24
                  AND v.tier_mismatches=3
                  AND v.queue_mismatches=3
                  AND v.reason_mismatches=24
              )
              OR
              (
                  v.kpi_mismatches=0
                  AND v.tier_mismatches=0
                  AND v.queue_mismatches=0
                  AND v.reason_mismatches=0
              )
          )
    THEN
        RAISE EXCEPTION
            'M2.10 dictionary-hash repair preconditions failed: %.',
            row_to_json(v);
    END IF;
END;
$m2_10_hash_repair_precondition$;

/* Normalize the four persisted dictionary row hashes. */
UPDATE msbf_m2.portfolio_kpi_definition AS definition
SET row_hash=msbf_ctl.m2_10_hash_jsonb
    (to_jsonb(definition)-'row_hash'-'created_at')
WHERE definition.module1_run_id=
      (SELECT run_id FROM _m2_10_hash_repair_before)
  AND definition.row_hash IS DISTINCT FROM
      msbf_ctl.m2_10_hash_jsonb
      (to_jsonb(definition)-'row_hash'-'created_at');

UPDATE msbf_m2.portfolio_performance_tier_definition AS definition
SET row_hash=msbf_ctl.m2_10_hash_jsonb
    (to_jsonb(definition)-'row_hash'-'created_at')
WHERE definition.module1_run_id=
      (SELECT run_id FROM _m2_10_hash_repair_before)
  AND definition.row_hash IS DISTINCT FROM
      msbf_ctl.m2_10_hash_jsonb
      (to_jsonb(definition)-'row_hash'-'created_at');

UPDATE msbf_m2.servicing_queue_definition AS definition
SET row_hash=msbf_ctl.m2_10_hash_jsonb
    (to_jsonb(definition)-'row_hash'-'created_at')
WHERE definition.module1_run_id=
      (SELECT run_id FROM _m2_10_hash_repair_before)
  AND definition.row_hash IS DISTINCT FROM
      msbf_ctl.m2_10_hash_jsonb
      (to_jsonb(definition)-'row_hash'-'created_at');

UPDATE msbf_m2.portfolio_analytics_reason_definition AS definition
SET row_hash=msbf_ctl.m2_10_hash_jsonb
    (to_jsonb(definition)-'row_hash'-'created_at')
WHERE definition.module1_run_id=
      (SELECT run_id FROM _m2_10_hash_repair_before)
  AND definition.row_hash IS DISTINCT FROM
      msbf_ctl.m2_10_hash_jsonb
      (to_jsonb(definition)-'row_hash'-'created_at');

DROP TABLE IF EXISTS _m2_10_repaired_definition_set_hashes;
CREATE TEMP TABLE _m2_10_repaired_definition_set_hashes
ON COMMIT DROP
AS
SELECT
    (
        SELECT md5(string_agg(row_hash,'|' ORDER BY kpi_rank,kpi_code))
        FROM msbf_m2.portfolio_kpi_definition
        WHERE module1_run_id=(SELECT run_id FROM _m2_10_hash_repair_before)
    ) AS kpi_definition_set_hash,
    (
        SELECT md5
        (
            string_agg
            (row_hash,'|' ORDER BY performance_tier_rank,performance_tier_code)
        )
        FROM msbf_m2.portfolio_performance_tier_definition
        WHERE module1_run_id=(SELECT run_id FROM _m2_10_hash_repair_before)
    ) AS performance_tier_set_hash,
    (
        SELECT md5
        (
            string_agg
            (row_hash,'|' ORDER BY servicing_queue_rank,servicing_queue_code)
        )
        FROM msbf_m2.servicing_queue_definition
        WHERE module1_run_id=(SELECT run_id FROM _m2_10_hash_repair_before)
    ) AS servicing_queue_set_hash,
    (
        SELECT md5
        (
            string_agg
            (row_hash,'|' ORDER BY portfolio_analytics_reason_code)
        )
        FROM msbf_m2.portfolio_analytics_reason_definition
        WHERE module1_run_id=(SELECT run_id FROM _m2_10_hash_repair_before)
    ) AS reason_set_hash;

/* Reconcile the registry in dependency order. */
UPDATE msbf_ctl.m2_10_portfolio_analytics_contract_registry AS registry
SET
    kpi_definition_set_hash=hashes.kpi_definition_set_hash,
    performance_tier_set_hash=hashes.performance_tier_set_hash,
    servicing_queue_set_hash=hashes.servicing_queue_set_hash,
    reason_set_hash=hashes.reason_set_hash
FROM _m2_10_repaired_definition_set_hashes AS hashes
WHERE registry.module1_run_id=
      (SELECT run_id FROM _m2_10_hash_repair_before);

UPDATE msbf_ctl.m2_10_portfolio_analytics_contract_registry AS registry
SET row_hash=msbf_ctl.m2_10_registry_row_hash(to_jsonb(registry))
WHERE registry.module1_run_id=
      (SELECT run_id FROM _m2_10_hash_repair_before);

UPDATE msbf_ctl.m2_10_portfolio_analytics_contract_registry AS registry
SET contract_set_hash=md5(registry.row_hash)
WHERE registry.module1_run_id=
      (SELECT run_id FROM _m2_10_hash_repair_before);

UPDATE msbf_ctl.m2_10_portfolio_analytics_contract_registry AS registry
SET combined_set_hash=canonical.combined_set_hash
FROM msbf_m2.v_m2_10_canonical_hash AS canonical
WHERE canonical.module1_run_id=registry.module1_run_id
  AND registry.module1_run_id=
      (SELECT run_id FROM _m2_10_hash_repair_before);

/* Reconcile the six existing generation-evidence hash records in place. */
UPDATE msbf_ctl.run_evidence AS evidence
SET
    metric_value_text=
        CASE evidence.evidence_code
            WHEN 'M2_10_KPI_DEFINITION_SET_HASH'
            THEN registry.kpi_definition_set_hash
            WHEN 'M2_10_PERFORMANCE_TIER_SET_HASH'
            THEN registry.performance_tier_set_hash
            WHEN 'M2_10_SERVICING_QUEUE_SET_HASH'
            THEN registry.servicing_queue_set_hash
            WHEN 'M2_10_REASON_SET_HASH'
            THEN registry.reason_set_hash
            WHEN 'M2_10_CONTRACT_SET_HASH'
            THEN registry.contract_set_hash
            WHEN 'M2_10_COMBINED_SET_HASH'
            THEN registry.combined_set_hash
        END,
    interpretation=
        CASE
            WHEN evidence.interpretation LIKE
                 '%v0.2R4 physical dictionary hash normalization%'
            THEN evidence.interpretation
            ELSE evidence.interpretation||
                 ' M2.10 v0.2R4 physical dictionary hash normalization.'
        END
FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry AS registry
WHERE evidence.run_id=registry.module1_run_id
  AND registry.module1_run_id=
      (SELECT run_id FROM _m2_10_hash_repair_before)
  AND evidence.segment_key='PORTFOLIO'
  AND evidence.evidence_code IN
      (
          'M2_10_KPI_DEFINITION_SET_HASH',
          'M2_10_PERFORMANCE_TIER_SET_HASH',
          'M2_10_SERVICING_QUEUE_SET_HASH',
          'M2_10_REASON_SET_HASH',
          'M2_10_CONTRACT_SET_HASH',
          'M2_10_COMBINED_SET_HASH'
      );

UPDATE msbf_ctl.run_registry AS run
SET notes=
    CASE
        WHEN coalesce(run.notes,'') LIKE
             '%M2.10 v0.2R4 physical dictionary hash normalization%'
        THEN run.notes
        ELSE coalesce(run.notes,'')||
             ' | M2.10 v0.2R4 physical dictionary hash normalization applied.'
    END
WHERE run.run_id=(SELECT run_id FROM _m2_10_hash_repair_before);

/* Reconstruct and verify every repaired identity. */
INSERT INTO _m2_10_hash_repair_result
WITH run_context AS
(
    SELECT run_id,run_status
    FROM msbf_ctl.run_registry
    WHERE run_id=(SELECT run_id FROM _m2_10_hash_repair_before)
),
registry AS
(
    SELECT *
    FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry
    WHERE module1_run_id=(SELECT run_id FROM run_context)
),
after_hash_state AS
(
    SELECT
        (
            SELECT count(*)
            FROM msbf_m2.portfolio_kpi_definition AS definition
            WHERE definition.module1_run_id=(SELECT run_id FROM run_context)
              AND definition.row_hash IS DISTINCT FROM
                  msbf_ctl.m2_10_hash_jsonb
                  (to_jsonb(definition)-'row_hash'-'created_at')
        )::bigint AS kpi_mismatches,
        (
            SELECT count(*)
            FROM msbf_m2.portfolio_performance_tier_definition AS definition
            WHERE definition.module1_run_id=(SELECT run_id FROM run_context)
              AND definition.row_hash IS DISTINCT FROM
                  msbf_ctl.m2_10_hash_jsonb
                  (to_jsonb(definition)-'row_hash'-'created_at')
        )::bigint AS tier_mismatches,
        (
            SELECT count(*)
            FROM msbf_m2.servicing_queue_definition AS definition
            WHERE definition.module1_run_id=(SELECT run_id FROM run_context)
              AND definition.row_hash IS DISTINCT FROM
                  msbf_ctl.m2_10_hash_jsonb
                  (to_jsonb(definition)-'row_hash'-'created_at')
        )::bigint AS queue_mismatches,
        (
            SELECT count(*)
            FROM msbf_m2.portfolio_analytics_reason_definition AS definition
            WHERE definition.module1_run_id=(SELECT run_id FROM run_context)
              AND definition.row_hash IS DISTINCT FROM
                  msbf_ctl.m2_10_hash_jsonb
                  (to_jsonb(definition)-'row_hash'-'created_at')
        )::bigint AS reason_mismatches
),
identity_state AS
(
    SELECT
        count(*) FILTER
        (
            WHERE registry.row_hash IS DISTINCT FROM
                  msbf_ctl.m2_10_registry_row_hash(to_jsonb(registry))
        )::bigint AS registry_hash_errors,
        count(*) FILTER
        (
            WHERE registry.contract_set_hash IS DISTINCT FROM
                  md5(registry.row_hash)
        )::bigint AS contract_hash_errors
    FROM registry
),
canonical AS
(
    SELECT canonical_entities,combined_set_hash
    FROM msbf_m2.v_m2_10_canonical_hash
    WHERE module1_run_id=(SELECT run_id FROM run_context)
),
evidence_state AS
(
    SELECT
        count(*) FILTER
        (
            WHERE evidence.evidence_code IN
                  (
                      'M2_10_KPI_DEFINITION_SET_HASH',
                      'M2_10_PERFORMANCE_TIER_SET_HASH',
                      'M2_10_SERVICING_QUEUE_SET_HASH',
                      'M2_10_REASON_SET_HASH',
                      'M2_10_CONTRACT_SET_HASH',
                      'M2_10_COMBINED_SET_HASH'
                  )
              AND evidence.metric_value_text IS DISTINCT FROM
                  CASE evidence.evidence_code
                      WHEN 'M2_10_KPI_DEFINITION_SET_HASH'
                      THEN registry.kpi_definition_set_hash
                      WHEN 'M2_10_PERFORMANCE_TIER_SET_HASH'
                      THEN registry.performance_tier_set_hash
                      WHEN 'M2_10_SERVICING_QUEUE_SET_HASH'
                      THEN registry.servicing_queue_set_hash
                      WHEN 'M2_10_REASON_SET_HASH'
                      THEN registry.reason_set_hash
                      WHEN 'M2_10_CONTRACT_SET_HASH'
                      THEN registry.contract_set_hash
                      WHEN 'M2_10_COMBINED_SET_HASH'
                      THEN registry.combined_set_hash
                  END
        )::bigint AS generation_hash_evidence_errors,
        count(*) FILTER
        (
            WHERE evidence.evidence_code LIKE 'M2_10_%'
              AND evidence.evidence_code NOT LIKE 'M2_10_POS_%'
              AND evidence.evidence_code NOT LIKE 'M2_10_NEG_%'
              AND evidence.evidence_code<>'M2_10_ACCEPTANCE_SUMMARY'
        )::bigint AS generation_rows,
        count(*) FILTER
        (WHERE evidence.evidence_code LIKE 'M2_10_POS_%')::bigint
            AS positive_rows,
        count(*) FILTER
        (WHERE evidence.evidence_code LIKE 'M2_10_NEG_%')::bigint
            AS negative_rows,
        count(*) FILTER
        (WHERE evidence.evidence_code='M2_10_ACCEPTANCE_SUMMARY')::bigint
            AS acceptance_rows
    FROM msbf_ctl.run_evidence AS evidence
    CROSS JOIN registry
    WHERE evidence.run_id=(SELECT run_id FROM run_context)
),
gate_state AS
(
    SELECT count(*)::bigint AS gate_rows
    FROM msbf_ctl.acceptance_gate_result
    WHERE run_id=(SELECT run_id FROM run_context)
      AND gate_id='M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS'
)
SELECT
    run_context.run_id,
    run_context.run_status,
    registry.contract_status,
    before.kpi_mismatches,
    before.tier_mismatches,
    before.queue_mismatches,
    before.reason_mismatches,
    after_hash_state.kpi_mismatches,
    after_hash_state.tier_mismatches,
    after_hash_state.queue_mismatches,
    after_hash_state.reason_mismatches,
    before.kpi_definition_set_hash,
    registry.kpi_definition_set_hash,
    before.performance_tier_set_hash,
    registry.performance_tier_set_hash,
    before.servicing_queue_set_hash,
    registry.servicing_queue_set_hash,
    before.reason_set_hash,
    registry.reason_set_hash,
    before.contract_set_hash,
    registry.contract_set_hash,
    before.combined_set_hash,
    registry.combined_set_hash,
    canonical.canonical_entities,
    identity_state.registry_hash_errors,
    identity_state.contract_hash_errors,
    evidence_state.generation_hash_evidence_errors,
    evidence_state.generation_rows,
    evidence_state.positive_rows,
    evidence_state.negative_rows,
    evidence_state.acceptance_rows,
    gate_state.gate_rows,
    CASE
        WHEN run_context.run_status='M2_10_GENERATED'
         AND registry.contract_status='GENERATED'
         AND after_hash_state.kpi_mismatches=0
         AND after_hash_state.tier_mismatches=0
         AND after_hash_state.queue_mismatches=0
         AND after_hash_state.reason_mismatches=0
         AND canonical.canonical_entities=370
         AND registry.canonical_entities=370
         AND registry.combined_set_hash IS NOT DISTINCT FROM
             canonical.combined_set_hash
         AND identity_state.registry_hash_errors=0
         AND identity_state.contract_hash_errors=0
         AND evidence_state.generation_hash_evidence_errors=0
         AND evidence_state.generation_rows=24
         AND evidence_state.positive_rows=0
         AND evidence_state.negative_rows=0
         AND evidence_state.acceptance_rows=0
         AND gate_state.gate_rows=0
        THEN 'PASS'
        ELSE 'FAIL'
    END
FROM run_context
CROSS JOIN registry
CROSS JOIN _m2_10_hash_repair_before AS before
CROSS JOIN after_hash_state
CROSS JOIN identity_state
CROSS JOIN canonical
CROSS JOIN evidence_state
CROSS JOIN gate_state;

DO $m2_10_hash_repair_final_guard$
DECLARE
    v_status text;
    v_detail json;
BEGIN
    SELECT repair_status,row_to_json(result)
    INTO v_status,v_detail
    FROM _m2_10_hash_repair_result AS result;

    IF v_status<>'PASS'
    THEN
        RAISE EXCEPTION
            'M2.10 dictionary-hash repair reconciliation failed: %.',
            v_detail;
    END IF;
END;
$m2_10_hash_repair_final_guard$;

COMMIT;

SELECT *
FROM _m2_10_hash_repair_result;
