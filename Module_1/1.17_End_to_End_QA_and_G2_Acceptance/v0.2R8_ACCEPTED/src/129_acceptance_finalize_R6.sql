
/* ============================================================================
 Merchant Sales-Based Financing Strategy Simulator
 M1.17 — End-to-End QA, Evidence & G2 Contract Acceptance
 Program 129 — G2 Acceptance Finalizer
 Version     — v0.2R6

 PURPOSE
 -------
 Independently require the complete positive/negative evidence inventory,
 physical hash reconstruction, accepted source contracts, exact G2 bundle
 counts, zero stage-boundary violations and zero blocking errors before
 issuing the formal `G2_M1_CONTRACT` gate.

 RESULT
 ------
 On success:
 - M1.17 bundle lifecycle becomes ACCEPTED
 - run status becomes M1_17_ACCEPTED
 - G2_M1_CONTRACT receives PASS
============================================================================ */

BEGIN;

SET LOCAL work_mem='128MB';
SET LOCAL lock_timeout='10s';
SET LOCAL statement_timeout='20min';
SET LOCAL jit=off;

DROP TABLE IF EXISTS _m1_17_acceptance;
CREATE TEMP TABLE _m1_17_acceptance ON COMMIT PRESERVE ROWS AS
WITH r AS (
    SELECT run_id,run_code,run_version,run_status
    FROM msbf_ctl.run_registry
    WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
), reg AS (
    SELECT *
    FROM msbf_ctl.m1_17_g2_bundle_registry
    WHERE module1_run_id=(SELECT run_id FROM r)
), evidence AS (
    SELECT
        count(*) FILTER (
            WHERE evidence_code LIKE 'M1_17_POS_%'
        ) AS positive_checks,
        count(*) FILTER (
            WHERE evidence_code LIKE 'M1_17_POS_%' AND status='PASS'
        ) AS positive_passes,
        count(*) FILTER (
            WHERE evidence_code LIKE 'M1_17_POS_%' AND status<>'PASS'
        ) AS positive_failures,
        count(*) FILTER (
            WHERE evidence_code LIKE 'M1_17_NEG_%'
        ) AS negative_checks,
        count(*) FILTER (
            WHERE evidence_code LIKE 'M1_17_NEG_%' AND status='PASS'
        ) AS negative_passes,
        count(*) FILTER (
            WHERE evidence_code LIKE 'M1_17_NEG_%' AND status<>'PASS'
        ) AS negative_failures
    FROM msbf_ctl.run_evidence
    WHERE run_id=(SELECT run_id FROM r)
), physical AS (
    SELECT
        (SELECT count(*) FROM msbf_ctl.m1_17_hash_chain_snapshot
          WHERE module1_run_id=(SELECT run_id FROM r)) AS hash_chain_rows,
        (SELECT count(*) FROM msbf_ctl.m1_17_end_to_end_evidence_snapshot
          WHERE module1_run_id=(SELECT run_id FROM r)) AS evidence_rows,
        (SELECT count(*) FROM msbf_ctl.m1_17_g2_bundle_latest
          WHERE module1_run_id=(SELECT run_id FROM r)) AS latest_rows,
        (SELECT count(*) FROM msbf_ctl.m1_17_g2_bundle_archive
          WHERE module1_run_id=(SELECT run_id FROM r)) AS archive_rows,
        (SELECT count(*) FROM msbf_ctl.m1_17_g2_bundle_registry
          WHERE module1_run_id=(SELECT run_id FROM r)) AS registry_rows,
        (SELECT count(*) FROM msbf_m1.v_m1_17_g2_integrated_consumption
          WHERE module1_run_id=(SELECT run_id FROM r)) AS integrated_rows,
        (SELECT count(*) FROM msbf_ctl.profile_resolution_error
          WHERE run_id=(SELECT run_id FROM r)
            AND severity='BLOCKING') AS blocking_errors,
        msbf_ctl.m1_17_schema_row_count('msbf_m2') AS module2_rows
), row_hashes AS (
    SELECT
        (SELECT count(*)
         FROM msbf_ctl.m1_17_hash_chain_snapshot h
         WHERE h.module1_run_id=(SELECT run_id FROM r)
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
           )) AS hash_row_mismatches,
        (SELECT count(*)
         FROM msbf_ctl.m1_17_end_to_end_evidence_snapshot e
         WHERE e.module1_run_id=(SELECT run_id FROM r)
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
           )) AS evidence_row_mismatches,
        (SELECT count(*)
         FROM msbf_ctl.m1_17_g2_bundle_latest l
         WHERE l.module1_run_id=(SELECT run_id FROM r)
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
           )) AS latest_row_mismatches,
        (SELECT count(*)
         FROM msbf_ctl.m1_17_g2_bundle_archive a
         WHERE a.module1_run_id=(SELECT run_id FROM r)
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
           )) AS archive_row_mismatches,
        (SELECT count(*)
         FROM msbf_ctl.m1_17_g2_bundle_registry x
         WHERE x.module1_run_id=(SELECT run_id FROM r)
           AND x.row_hash IS DISTINCT FROM msbf_ctl.m1_17_hash_jsonb(
               jsonb_build_object(
                   'module1_run_id',x.module1_run_id,
                   'bundle_code',x.bundle_code,
                   'bundle_version',x.bundle_version,
                   'schema_version',x.schema_version,
                   'methodology_version',x.methodology_version,
                   'source_m1_15_contract_code',x.source_m1_15_contract_code,
                   'source_m1_15_contract_version',x.source_m1_15_contract_version,
                   'source_m1_15_schema_version',x.source_m1_15_schema_version,
                   'source_m1_15_combined_hash',x.source_m1_15_combined_hash,
                   'source_m1_16_contract_code',x.source_m1_16_contract_code,
                   'source_m1_16_contract_version',x.source_m1_16_contract_version,
                   'source_m1_16_schema_version',x.source_m1_16_schema_version,
                   'source_m1_16_combined_hash',x.source_m1_16_combined_hash,
                   'accepted_scenario_set_hash',x.accepted_scenario_set_hash,
                   'policy_configuration_hash',x.policy_configuration_hash,
                   'predecessor_gate_count',x.predecessor_gate_count,
                   'integrated_consumption_rows',x.integrated_consumption_rows,
                   'hash_chain_rows',x.hash_chain_rows,
                   'evidence_snapshot_rows',x.evidence_snapshot_rows,
                   'canonical_entities',x.canonical_entities
               )
           )) AS registry_row_mismatches
), sets AS (
    WITH h AS (
        SELECT md5(string_agg(
            format('%03s|%s',stage_sequence,row_hash),
            '||' ORDER BY stage_sequence
        )) AS set_hash
        FROM msbf_ctl.m1_17_hash_chain_snapshot
        WHERE module1_run_id=(SELECT run_id FROM r)
    ), e AS (
        SELECT md5(string_agg(
            format('%03s|%s',evidence_sequence,row_hash),
            '||' ORDER BY evidence_sequence
        )) AS set_hash
        FROM msbf_ctl.m1_17_end_to_end_evidence_snapshot
        WHERE module1_run_id=(SELECT run_id FROM r)
    ), l AS (
        SELECT md5('LATEST|'||contract_row_hash) AS set_hash
        FROM msbf_ctl.m1_17_g2_bundle_latest
        WHERE module1_run_id=(SELECT run_id FROM r)
    ), a AS (
        SELECT md5('ARCHIVE|'||archive_row_hash) AS set_hash
        FROM msbf_ctl.m1_17_g2_bundle_archive
        WHERE module1_run_id=(SELECT run_id FROM r)
    ), c AS (
        SELECT md5('REGISTRY|'||row_hash) AS set_hash
        FROM msbf_ctl.m1_17_g2_bundle_registry
        WHERE module1_run_id=(SELECT run_id FROM r)
    )
    SELECT
        h.set_hash AS hash_chain_set_hash,
        e.set_hash AS evidence_set_hash,
        l.set_hash AS latest_set_hash,
        a.set_hash AS archive_set_hash,
        c.set_hash AS contract_set_hash,
        md5(concat_ws('||',
            'HASH_CHAIN|'||h.set_hash,
            'EVIDENCE|'||e.set_hash,
            'LATEST|'||l.set_hash,
            'ARCHIVE|'||a.set_hash,
            'REGISTRY|'||c.set_hash
        )) AS combined_set_hash
    FROM h CROSS JOIN e CROSS JOIN l CROSS JOIN a CROSS JOIN c
), archive_match AS (
    SELECT count(*) AS archive_reproduction_mismatches
    FROM msbf_ctl.m1_17_g2_bundle_latest l
    JOIN msbf_ctl.m1_17_g2_bundle_archive a
      ON a.module1_run_id=l.module1_run_id
     AND a.bundle_code=l.bundle_code
     AND a.bundle_version=l.bundle_version
    WHERE l.module1_run_id=(SELECT run_id FROM r)
      AND (
          l.contract_row_hash IS DISTINCT FROM a.source_latest_row_hash
          OR l.bundle_payload IS DISTINCT FROM a.bundle_payload
      )
)
SELECT
    r.run_id,
    r.run_status AS prior_run_status,
    reg.bundle_status AS prior_bundle_status,
    evidence.*,
    physical.*,
    row_hashes.*,
    archive_match.archive_reproduction_mismatches,
    sets.hash_chain_set_hash AS recomputed_hash_chain_set_hash,
    sets.evidence_set_hash AS recomputed_evidence_set_hash,
    sets.latest_set_hash AS recomputed_latest_set_hash,
    sets.archive_set_hash AS recomputed_archive_set_hash,
    sets.contract_set_hash AS recomputed_contract_set_hash,
    sets.combined_set_hash AS recomputed_combined_set_hash,
    reg.hash_chain_set_hash AS stored_hash_chain_set_hash,
    reg.evidence_set_hash AS stored_evidence_set_hash,
    reg.bundle_latest_set_hash AS stored_latest_set_hash,
    reg.bundle_archive_set_hash AS stored_archive_set_hash,
    reg.contract_set_hash AS stored_contract_set_hash,
    reg.combined_g2_hash AS stored_combined_set_hash,
    reg.canonical_entities,
    CASE
        WHEN r.run_status='M1_17_VALIDATED'
         AND reg.bundle_status='VALIDATED'
         AND evidence.positive_checks=128
         AND evidence.positive_passes=128
         AND evidence.positive_failures=0
         AND evidence.negative_checks=20
         AND evidence.negative_passes=20
         AND evidence.negative_failures=0
         AND physical.hash_chain_rows=18
         AND physical.evidence_rows=48
         AND physical.latest_rows=1
         AND physical.archive_rows=1
         AND physical.registry_rows=1
         AND physical.integrated_rows=1500
         AND physical.blocking_errors=0
         AND physical.module2_rows=0
         AND row_hashes.hash_row_mismatches=0
         AND row_hashes.evidence_row_mismatches=0
         AND row_hashes.latest_row_mismatches=0
         AND row_hashes.archive_row_mismatches=0
         AND row_hashes.registry_row_mismatches=0
         AND archive_match.archive_reproduction_mismatches=0
         AND sets.hash_chain_set_hash=reg.hash_chain_set_hash
         AND sets.evidence_set_hash=reg.evidence_set_hash
         AND sets.latest_set_hash=reg.bundle_latest_set_hash
         AND sets.archive_set_hash=reg.bundle_archive_set_hash
         AND sets.contract_set_hash=reg.contract_set_hash
         AND sets.combined_set_hash=reg.combined_g2_hash
         AND reg.canonical_entities=69
        THEN 'PASS'
        ELSE 'FAIL'
    END AS acceptance_status
FROM r
CROSS JOIN reg
CROSS JOIN evidence
CROSS JOIN physical
CROSS JOIN row_hashes
CROSS JOIN sets
CROSS JOIN archive_match;

DO $guard$
DECLARE
    v record;
BEGIN
    SELECT * INTO v FROM _m1_17_acceptance;
    IF v.acceptance_status<>'PASS' THEN
        RAISE EXCEPTION
            'M1.17 G2 acceptance prerequisites failed: %',
            row_to_json(v);
    END IF;
END;
$guard$;

/* --------------------------------------------------------------------------
 Acceptance evidence staging

 `msbf_ctl.run_evidence.ck_evidence_value` requires exactly one of
 `metric_value_numeric` and `metric_value_text` to be non-null. The governed
 acceptance-summary value is the final combined G2 hash. The canonical-entity
 count remains visible in the interpretation and in the G2 registry/master
 report rather than being stored as a second metric value in the same row.
-------------------------------------------------------------------------- */
DROP TABLE IF EXISTS _m1_17_acceptance_evidence;

CREATE TEMP TABLE _m1_17_acceptance_evidence
(
    run_id                 bigint         NOT NULL,
    evidence_code          text           NOT NULL,
    segment_key            text           NOT NULL,
    metric_name            text           NOT NULL,
    metric_value_numeric   numeric(24,10),
    metric_value_text      text,
    unit_code              text           NOT NULL,
    status                 text           NOT NULL,
    interpretation         text           NOT NULL,
    CONSTRAINT ck_m1_17_acceptance_evidence_value
        CHECK (num_nonnulls(metric_value_numeric,metric_value_text)=1)
)
ON COMMIT PRESERVE ROWS;

INSERT INTO _m1_17_acceptance_evidence
(
    run_id,evidence_code,segment_key,metric_name,
    metric_value_numeric,metric_value_text,unit_code,status,interpretation
)
SELECT
    run_id,
    'M1_17_ACCEPTANCE_SUMMARY',
    'PORTFOLIO',
    'G2_M1_CONTRACT_ACCEPTANCE',
    NULL::numeric(24,10),
    stored_combined_set_hash,
    'G2_ACCEPTANCE',
    'PASS',
    format(
        'Formal G2 Module 1 bundle acceptance: canonical_entities=%s; '
        || 'both source contracts accepted; complete hash chain preserved; '
        || 'latest/archive and integrated views reconciled.',
        canonical_entities
    )
FROM _m1_17_acceptance;

DO $acceptance_evidence_guard$
DECLARE
    v_count bigint;
    v_invalid bigint;
    v_hash_mismatches bigint;
BEGIN
    SELECT
        count(*),
        count(*) FILTER (WHERE num_nonnulls(metric_value_numeric,metric_value_text)<>1),
        count(*) FILTER (
            WHERE metric_value_numeric IS NOT NULL
               OR metric_value_text IS DISTINCT FROM (
                    SELECT stored_combined_set_hash FROM _m1_17_acceptance
               )
        )
    INTO v_count,v_invalid,v_hash_mismatches
    FROM _m1_17_acceptance_evidence;

    IF v_count<>1 OR v_invalid<>0 OR v_hash_mismatches<>0 THEN
        RAISE EXCEPTION
            'M1.17 v0.2R6 acceptance-evidence staging failed: rows %, invalid-value rows %, hash mismatches %.',
            v_count,v_invalid,v_hash_mismatches;
    END IF;
END;
$acceptance_evidence_guard$;

UPDATE msbf_ctl.m1_17_g2_bundle_registry
SET bundle_status='ACCEPTED',
    accepted_at=clock_timestamp()
WHERE module1_run_id=(SELECT run_id FROM _m1_17_acceptance);

UPDATE msbf_ctl.run_registry
SET run_status='M1_17_ACCEPTED',
    notes=coalesce(notes,'')||
        ' | M1.17 accepted: G2 Module 1 contract bundle passed end-to-end assurance.'
WHERE run_id=(SELECT run_id FROM _m1_17_acceptance);

SELECT msbf_ctl.m1_17_write_acceptance_gate(
    (SELECT run_id FROM _m1_17_acceptance),
    'PASS',
    'M1.17 End-to-End QA, Evidence & G2 Contract Acceptance passed: 128/128 positive controls, 20/20 negative controls, 69 canonical entities, 1,500 integrated contract rows, zero mismatches and zero blocking errors.'
);

INSERT INTO msbf_ctl.run_evidence
(
    run_id,evidence_code,segment_key,metric_name,
    metric_value_numeric,metric_value_text,unit_code,status,interpretation
)
SELECT
    run_id,evidence_code,segment_key,metric_name,
    metric_value_numeric,metric_value_text,unit_code,status,interpretation
FROM _m1_17_acceptance_evidence
ON CONFLICT(run_id,evidence_code,segment_key) DO UPDATE SET
    metric_name=EXCLUDED.metric_name,
    metric_value_numeric=NULL,
    metric_value_text=EXCLUDED.metric_value_text,
    unit_code=EXCLUDED.unit_code,
    status=EXCLUDED.status,
    interpretation=EXCLUDED.interpretation,
    created_at=clock_timestamp();

ALTER TABLE _m1_17_acceptance
ADD COLUMN final_run_status text,
ADD COLUMN final_bundle_status text,
ADD COLUMN gate_status text;

UPDATE _m1_17_acceptance a
SET final_run_status=(
        SELECT run_status
        FROM msbf_ctl.run_registry
        WHERE run_id=a.run_id
    ),
    final_bundle_status=(
        SELECT bundle_status
        FROM msbf_ctl.m1_17_g2_bundle_registry
        WHERE module1_run_id=a.run_id
    ),
    gate_status=(
        SELECT coalesce(
            to_jsonb(g)->>'result_status',
            to_jsonb(g)->>'gate_status',
            to_jsonb(g)->>'status'
        )
        FROM msbf_ctl.acceptance_gate_result g
        WHERE g.run_id=a.run_id
          AND g.gate_id='G2_M1_CONTRACT'
        ORDER BY
            CASE
                WHEN (to_jsonb(g)->>'review_version') ~ '^[0-9]+$'
                THEN (to_jsonb(g)->>'review_version')::integer
                ELSE 0
            END DESC
        LIMIT 1
    )
WHERE a.run_id IS NOT NULL;

DO $final_guard$
DECLARE
    v record;
BEGIN
    SELECT * INTO v FROM _m1_17_acceptance;
    IF v.final_run_status<>'M1_17_ACCEPTED'
       OR v.final_bundle_status<>'ACCEPTED'
       OR v.gate_status<>'PASS' THEN
        RAISE EXCEPTION
            'M1.17 final acceptance state failed: run %, bundle %, gate %.',
            v.final_run_status,v.final_bundle_status,v.gate_status;
    END IF;
END;
$final_guard$;

COMMIT;

SELECT *
FROM _m1_17_acceptance;
