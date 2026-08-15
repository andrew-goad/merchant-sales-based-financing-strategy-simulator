/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.11 — Portfolio Optimization & Strategy Simulation

Program     : 217_msbf_m2_11_acceptance_finalizer_v1.sql
Version     : v1
Work package: M2.11 Work Package 4
Revision    : LIVE_EXECUTION_ACCEPTANCE_HASH_RECON_CORRECTION_R1

Purpose
-------
Fail closed unless the fixed Programs 212–216 generated and validated state
satisfies every formal M2.11 acceptance prerequisite. Independently reconcile
accepted-source identities, validation evidence, exact baseline replay,
nineteen canonical families, 19,298 canonical entities, ordered set hashes,
latest/archive reproduction, stress non-improvement, governance boundaries,
and the non-production/stage boundary before issuing formal acceptance.

Mutation boundary
-----------------
Permitted persistent writes are limited to:
1. one M2.11 acceptance-gate result;
2. one M2_11_ACCEPTANCE_SUMMARY run-evidence row;
3. m2_11 contract registry contract_status and accepted_at; and
4. run_registry run_status.

The program may not alter any generated strategy row, source snapshot, summary,
frontier row, comparison, latest value, archive value, contract hash, registry
row hash, combined-set hash, or accepted upstream source.

Required starting state
-----------------------
run_status       = M2_11_VALIDATED
contract_status  = VALIDATED
positive evidence = 120 / 120 PASS
negative evidence = 20 / 20 PASS
acceptance evidence and gate rows = 0

Required ending state
---------------------
run_status       = M2_11_ACCEPTED
contract_status  = ACCEPTED
acceptance gate  = PASS
acceptance evidence rows = 1

Execution
---------
Execute as one SQL script. Stop on the first error. This source is statically
built and has not been parsed or executed by PostgreSQL in the build
environment.
============================================================================ */

BEGIN;
SET LOCAL work_mem='192MB';
SET LOCAL statement_timeout='75min';
SET LOCAL lock_timeout='15s';
SET LOCAL jit=off;

/* ============================================================================
Section 1 — Lock and establish the single governed acceptance context
============================================================================ */
DO $m211_acceptance_lock$
DECLARE
    v_run_id bigint;
    v_run_status text;
    v_contract_status text;
BEGIN
    SELECT r.run_id,r.run_status,c.contract_status
    INTO v_run_id,v_run_status,v_contract_status
    FROM msbf_ctl.run_registry r
    JOIN msbf_ctl.m2_11_portfolio_strategy_contract_registry c
      ON c.module1_run_id=r.run_id AND c.contract_version=1
    WHERE r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1
    FOR UPDATE OF r,c;

    IF v_run_id IS NULL THEN
        RAISE EXCEPTION 'Program 217 requires exactly one governed M2.11 context';
    END IF;
    IF v_run_status<>'M2_11_VALIDATED' OR v_contract_status<>'VALIDATED' THEN
        RAISE EXCEPTION 'Program 217 requires M2_11_VALIDATED/VALIDATED; found %/%',
          v_run_status,v_contract_status;
    END IF;
END;
$m211_acceptance_lock$;

CREATE TEMP TABLE tmp_accept_m2_11_context ON COMMIT DROP AS
SELECT
    r.run_id,
    r.run_code,
    r.run_version,
    r.run_status,
    r.as_of_date,
    c.registry_id,
    c.contract_code,
    c.contract_version,
    c.schema_version,
    c.methodology_version,
    c.acceptance_gate_id,
    c.contract_status,
    c.generated_at,
    c.validated_at,
    c.accepted_at,
    c.row_hash AS registry_row_hash,
    c.contract_set_hash,
    c.combined_set_hash
FROM msbf_ctl.run_registry r
JOIN msbf_ctl.m2_11_portfolio_strategy_contract_registry c
  ON c.module1_run_id=r.run_id AND c.contract_version=1
WHERE r.run_code='M1_V0_2_BASELINE_BUILD'
  AND r.run_version=1;

DO $m211_acceptance_context$
DECLARE
    v_rows bigint;
BEGIN
    SELECT count(*) INTO v_rows FROM tmp_accept_m2_11_context;
    IF v_rows<>1 THEN
        RAISE EXCEPTION 'Program 217 acceptance context expected one row; found %',v_rows;
    END IF;
END;
$m211_acceptance_context$;

CREATE TEMP TABLE tmp_accept_m2_11_immutable_checkpoint_before ON COMMIT DROP AS
SELECT
    c.module1_run_id,
    c.row_hash AS registry_row_hash,
    c.combined_set_hash,
    c.contract_set_hash,
    c.latest_set_hash,
    c.archive_set_hash,
    (SELECT count(*) FROM msbf_m2.portfolio_strategy_simulation_latest l
      WHERE l.module1_run_id=c.module1_run_id) AS latest_rows,
    (SELECT count(*) FROM msbf_m2.portfolio_strategy_simulation_archive a
      WHERE a.module1_run_id=c.module1_run_id AND a.contract_version=1) AS archive_rows
FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry c
WHERE c.module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context)
  AND c.contract_version=1;

/* ============================================================================
Section 2 — Acceptance requirement table and helper
============================================================================ */
CREATE TEMP TABLE tmp_accept_m2_11_requirement
(
    requirement_sequence integer PRIMARY KEY,
    requirement_code text NOT NULL UNIQUE,
    requirement_family text NOT NULL,
    requirement_description text NOT NULL,
    observed_value text,
    threshold_value text NOT NULL,
    status text NOT NULL CHECK(status IN ('PASS','FAIL')),
    failure_detail text,
    freeze_trace text NOT NULL
) ON COMMIT PRESERVE ROWS;

CREATE OR REPLACE FUNCTION pg_temp.m2_11_add_acceptance_requirement
(
    p_sequence integer,
    p_code text,
    p_family text,
    p_description text,
    p_observed text,
    p_threshold text,
    p_pass boolean,
    p_failure_detail text,
    p_freeze_trace text
)
RETURNS void
LANGUAGE plpgsql
AS $function$
BEGIN
    INSERT INTO tmp_accept_m2_11_requirement
    (
      requirement_sequence,requirement_code,requirement_family,
      requirement_description,observed_value,threshold_value,status,
      failure_detail,freeze_trace
    )
    VALUES
    (
      p_sequence,p_code,p_family,p_description,p_observed,p_threshold,
      CASE WHEN coalesce(p_pass,FALSE) THEN 'PASS' ELSE 'FAIL' END,
      p_failure_detail,p_freeze_trace
    );
END;
$function$;

/* ============================================================================
Section 3 — Materialized acceptance diagnostics
============================================================================ */
CREATE TEMP TABLE tmp_accept_m2_11_evidence_summary ON COMMIT DROP AS
SELECT
    count(*) FILTER(WHERE evidence_code LIKE 'M2_11_POS_%')::bigint AS positive_rows,
    count(*) FILTER(WHERE evidence_code LIKE 'M2_11_POS_%' AND status='PASS')::bigint AS positive_pass_rows,
    count(*) FILTER(WHERE evidence_code LIKE 'M2_11_POS_%' AND status<>'PASS')::bigint AS positive_nonpass_rows,
    count(*) FILTER(WHERE evidence_code LIKE 'M2_11_NEG_%')::bigint AS negative_rows,
    count(*) FILTER(WHERE evidence_code LIKE 'M2_11_NEG_%' AND status='PASS')::bigint AS negative_pass_rows,
    count(*) FILTER(WHERE evidence_code LIKE 'M2_11_NEG_%' AND status<>'PASS')::bigint AS negative_nonpass_rows,
    count(*) FILTER(WHERE evidence_code LIKE 'M2_11_GENERATION_%')::bigint AS generation_rows,
    count(*) FILTER(WHERE evidence_code LIKE 'M2_11_GENERATION_%' AND status='PASS')::bigint AS generation_pass_rows,
    count(*) FILTER(WHERE evidence_code LIKE 'M2_11_GENERATION_%' AND status<>'PASS')::bigint AS generation_nonpass_rows,
    count(*) FILTER(WHERE evidence_code='M2_11_ACCEPTANCE_SUMMARY')::bigint AS prior_acceptance_rows,
    count(*) FILTER(WHERE evidence_code LIKE 'M2_11_%' AND status<>'PASS')::bigint AS all_nonpass_rows
FROM msbf_ctl.run_evidence
WHERE run_id=(SELECT run_id FROM tmp_accept_m2_11_context);

/*
Program 217 R11 correction:
Reconstruct every canonical family directly from target-typed physical fields
and the exact Program 214/215 business-key ordering. The canonical hash-source
view is a reporting/count surface; its text business_key is not the governed
set-hash ordering authority for summary, frontier, comparison, latest or
archive families.
*/
CREATE TEMP TABLE tmp_accept_m2_11_canonical_reconstruction
(
    catalog_sequence integer PRIMARY KEY,
    object_code text NOT NULL UNIQUE,
    physical_row_count bigint NOT NULL,
    reconstructed_set_hash text NOT NULL,
    registry_field_name text
) ON COMMIT DROP;

INSERT INTO tmp_accept_m2_11_canonical_reconstruction
(
    catalog_sequence,
    object_code,
    physical_row_count,
    reconstructed_set_hash,
    registry_field_name
)
VALUES
(
  1,
  'msbf_ctl.m2_11_policy_profile',
  (SELECT count(*)::bigint
     FROM msbf_ctl.m2_11_policy_profile t
    WHERE t.module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context)),
  (SELECT md5(string_agg(
              msbf_ctl.m2_11_hash_jsonb(t.configuration_payload),
              '|' ORDER BY t.module1_run_id))
     FROM msbf_ctl.m2_11_policy_profile t
    WHERE t.module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context)),
  'policy_set_hash'
),
(
  2,
  'msbf_m2.portfolio_strategy_profile',
  (SELECT count(*)::bigint
     FROM msbf_m2.portfolio_strategy_profile t
    WHERE t.module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context)),
  (SELECT md5(string_agg(
              msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'),
              '|' ORDER BY t.module1_run_id,t.strategy_profile_code))
     FROM msbf_m2.portfolio_strategy_profile t
    WHERE t.module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context)),
  'strategy_profile_set_hash'
),
(
  3,
  'msbf_m2.portfolio_strategy_objective_definition',
  (SELECT count(*)::bigint
     FROM msbf_m2.portfolio_strategy_objective_definition t
    WHERE t.module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context)),
  (SELECT md5(string_agg(
              msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'),
              '|' ORDER BY t.module1_run_id,t.objective_code))
     FROM msbf_m2.portfolio_strategy_objective_definition t
    WHERE t.module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context)),
  'objective_definition_set_hash'
),
(
  4,
  'msbf_m2.portfolio_strategy_constraint_definition',
  (SELECT count(*)::bigint
     FROM msbf_m2.portfolio_strategy_constraint_definition t
    WHERE t.module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context)),
  (SELECT md5(string_agg(
              msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'),
              '|' ORDER BY t.module1_run_id,t.constraint_code))
     FROM msbf_m2.portfolio_strategy_constraint_definition t
    WHERE t.module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context)),
  'constraint_definition_set_hash'
),
(
  5,
  'msbf_m2.portfolio_strategy_reason_definition',
  (SELECT count(*)::bigint
     FROM msbf_m2.portfolio_strategy_reason_definition t
    WHERE t.module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context)),
  (SELECT md5(string_agg(
              msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'),
              '|' ORDER BY t.module1_run_id,t.reason_code))
     FROM msbf_m2.portfolio_strategy_reason_definition t
    WHERE t.module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context)),
  'reason_definition_set_hash'
),
(
  6,
  'msbf_m2.portfolio_strategy_application_source_snapshot',
  (SELECT count(*)::bigint
     FROM msbf_m2.portfolio_strategy_application_source_snapshot t
    WHERE t.module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context)),
  (SELECT md5(string_agg(
              msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'),
              '|' ORDER BY t.module1_run_id,t.scenario_id,t.merchant_application_id))
     FROM msbf_m2.portfolio_strategy_application_source_snapshot t
    WHERE t.module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context)),
  'application_source_set_hash'
),
(
  7,
  'msbf_m2.portfolio_strategy_candidate_source_snapshot',
  (SELECT count(*)::bigint
     FROM msbf_m2.portfolio_strategy_candidate_source_snapshot t
    WHERE t.module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context)),
  (SELECT md5(string_agg(
              msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'),
              '|' ORDER BY t.module1_run_id,t.scenario_id,t.merchant_application_id,t.candidate_template_code))
     FROM msbf_m2.portfolio_strategy_candidate_source_snapshot t
    WHERE t.module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context)),
  'candidate_source_set_hash'
),
(
  8,
  'msbf_m2.portfolio_strategy_account_source_snapshot',
  (SELECT count(*)::bigint
     FROM msbf_m2.portfolio_strategy_account_source_snapshot t
    WHERE t.module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context)),
  (SELECT md5(string_agg(
              msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'),
              '|' ORDER BY t.module1_run_id,t.scenario_id,t.merchant_application_id))
     FROM msbf_m2.portfolio_strategy_account_source_snapshot t
    WHERE t.module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context)),
  'account_source_set_hash'
),
(
  9,
  'msbf_m2.portfolio_strategy_kpi_source_snapshot',
  (SELECT count(*)::bigint
     FROM msbf_m2.portfolio_strategy_kpi_source_snapshot t
    WHERE t.module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context)),
  (SELECT md5(string_agg(
              msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'),
              '|' ORDER BY t.module1_run_id,t.scope_code,t.kpi_code))
     FROM msbf_m2.portfolio_strategy_kpi_source_snapshot t
    WHERE t.module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context)),
  'kpi_source_set_hash'
),
(
  10,
  'msbf_m2.portfolio_strategy_queue_source_snapshot',
  (SELECT count(*)::bigint
     FROM msbf_m2.portfolio_strategy_queue_source_snapshot t
    WHERE t.module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context)),
  (SELECT md5(string_agg(
              msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'),
              '|' ORDER BY t.module1_run_id,t.servicing_queue_code))
     FROM msbf_m2.portfolio_strategy_queue_source_snapshot t
    WHERE t.module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context)),
  'queue_source_set_hash'
),
(
  11,
  'msbf_m2.application_strategy_candidate_evaluation',
  (SELECT count(*)::bigint
     FROM msbf_m2.application_strategy_candidate_evaluation t
    WHERE t.module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context)),
  (SELECT md5(string_agg(
              msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'),
              '|' ORDER BY t.module1_run_id,t.scenario_id,t.merchant_application_id,t.candidate_template_code,t.strategy_profile_code))
     FROM msbf_m2.application_strategy_candidate_evaluation t
    WHERE t.module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context)),
  'candidate_evaluation_set_hash'
),
(
  12,
  'msbf_m2.application_portfolio_strategy_simulation',
  (SELECT count(*)::bigint
     FROM msbf_m2.application_portfolio_strategy_simulation t
    WHERE t.module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context)),
  (SELECT md5(string_agg(
              msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'),
              '|' ORDER BY t.module1_run_id,t.scenario_id,t.merchant_application_id,t.strategy_profile_code))
     FROM msbf_m2.application_portfolio_strategy_simulation t
    WHERE t.module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context)),
  'application_simulation_set_hash'
),
(
  13,
  'msbf_m2.account_servicing_strategy_simulation',
  (SELECT count(*)::bigint
     FROM msbf_m2.account_servicing_strategy_simulation t
    WHERE t.module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context)),
  (SELECT md5(string_agg(
              msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'),
              '|' ORDER BY t.module1_run_id,t.scenario_id,t.merchant_application_id,t.strategy_profile_code))
     FROM msbf_m2.account_servicing_strategy_simulation t
    WHERE t.module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context)),
  'account_simulation_set_hash'
),
(
  14,
  'msbf_m2.portfolio_strategy_summary',
  (SELECT count(*)::bigint
     FROM msbf_m2.portfolio_strategy_summary t
    WHERE t.module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context)),
  (SELECT md5(string_agg(
              msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'),
              '|' ORDER BY t.module1_run_id,t.reporting_scope_code,t.strategy_profile_code))
     FROM msbf_m2.portfolio_strategy_summary t
    WHERE t.module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context)),
  'strategy_summary_set_hash'
),
(
  15,
  'msbf_m2.portfolio_strategy_frontier',
  (SELECT count(*)::bigint
     FROM msbf_m2.portfolio_strategy_frontier t
    WHERE t.module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context)),
  (SELECT md5(string_agg(
              msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'),
              '|' ORDER BY t.module1_run_id,t.reporting_scope_code,t.strategy_profile_code))
     FROM msbf_m2.portfolio_strategy_frontier t
    WHERE t.module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context)),
  'frontier_set_hash'
),
(
  16,
  'msbf_m2.portfolio_strategy_comparison',
  (SELECT count(*)::bigint
     FROM msbf_m2.portfolio_strategy_comparison t
    WHERE t.module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context)),
  (SELECT md5(string_agg(
              msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'row_hash'-'created_at'),
              '|' ORDER BY t.module1_run_id,t.reporting_scope_code,t.challenger_strategy_profile_code))
     FROM msbf_m2.portfolio_strategy_comparison t
    WHERE t.module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context)),
  'comparison_set_hash'
),
(
  17,
  'msbf_m2.portfolio_strategy_simulation_latest',
  (SELECT count(*)::bigint
     FROM msbf_m2.portfolio_strategy_simulation_latest t
    WHERE t.module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context)
      AND t.contract_version=1),
  (SELECT md5(string_agg(
              msbf_ctl.m2_11_hash_jsonb(to_jsonb(t)-'contract_row_hash'-'created_at'),
              '|' ORDER BY t.module1_run_id,t.reporting_scope_code,t.strategy_profile_code))
     FROM msbf_m2.portfolio_strategy_simulation_latest t
    WHERE t.module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context)
      AND t.contract_version=1),
  'latest_set_hash'
),
(
  18,
  'msbf_m2.portfolio_strategy_simulation_archive',
  (SELECT count(*)::bigint
     FROM msbf_m2.portfolio_strategy_simulation_archive t
    WHERE t.module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context)
      AND t.contract_version=1),
  (SELECT md5(string_agg(
              msbf_ctl.m2_11_hash_jsonb(
                jsonb_build_object(
                  'module1_run_id',t.module1_run_id,
                  'contract_code',t.contract_code,
                  'contract_version',t.contract_version,
                  'strategy_profile_code',t.strategy_profile_code,
                  'reporting_scope_code',t.reporting_scope_code,
                  'contract_payload',t.contract_payload,
                  'source_latest_row_hash',t.contract_row_hash
                )),
              '|' ORDER BY t.module1_run_id,t.contract_version,t.reporting_scope_code,t.strategy_profile_code))
     FROM msbf_m2.portfolio_strategy_simulation_archive t
    WHERE t.module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context)
      AND t.contract_version=1),
  'archive_set_hash'
),
(
  19,
  'msbf_ctl.m2_11_portfolio_strategy_contract_registry',
  (SELECT count(*)::bigint
     FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry t
    WHERE t.module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context)
      AND t.contract_version=1),
  (SELECT md5(string_agg(
              msbf_ctl.m2_11_registry_row_hash(to_jsonb(t)),
              '|' ORDER BY t.module1_run_id,t.contract_version))
     FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry t
    WHERE t.module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context)
      AND t.contract_version=1),
  NULL
);

CREATE UNIQUE INDEX tmp_accept_m2_11_canonical_reconstruction_u1
ON tmp_accept_m2_11_canonical_reconstruction(object_code);
ANALYZE tmp_accept_m2_11_canonical_reconstruction;

CREATE TEMP TABLE tmp_accept_m2_11_registry_family ON COMMIT DROP AS
SELECT x.*
FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry c
CROSS JOIN LATERAL
(
 VALUES
 (1,'msbf_ctl.m2_11_policy_profile',c.policy_rows,c.policy_set_hash),
 (2,'msbf_m2.portfolio_strategy_profile',c.strategy_profile_rows,c.strategy_profile_set_hash),
 (3,'msbf_m2.portfolio_strategy_objective_definition',c.objective_definition_rows,c.objective_definition_set_hash),
 (4,'msbf_m2.portfolio_strategy_constraint_definition',c.constraint_definition_rows,c.constraint_definition_set_hash),
 (5,'msbf_m2.portfolio_strategy_reason_definition',c.reason_definition_rows,c.reason_definition_set_hash),
 (6,'msbf_m2.portfolio_strategy_application_source_snapshot',c.application_source_rows,c.application_source_set_hash),
 (7,'msbf_m2.portfolio_strategy_candidate_source_snapshot',c.candidate_source_rows,c.candidate_source_set_hash),
 (8,'msbf_m2.portfolio_strategy_account_source_snapshot',c.account_source_rows,c.account_source_set_hash),
 (9,'msbf_m2.portfolio_strategy_kpi_source_snapshot',c.kpi_source_rows,c.kpi_source_set_hash),
 (10,'msbf_m2.portfolio_strategy_queue_source_snapshot',c.queue_source_rows,c.queue_source_set_hash),
 (11,'msbf_m2.application_strategy_candidate_evaluation',c.candidate_evaluation_rows,c.candidate_evaluation_set_hash),
 (12,'msbf_m2.application_portfolio_strategy_simulation',c.application_simulation_rows,c.application_simulation_set_hash),
 (13,'msbf_m2.account_servicing_strategy_simulation',c.account_simulation_rows,c.account_simulation_set_hash),
 (14,'msbf_m2.portfolio_strategy_summary',c.strategy_summary_rows,c.strategy_summary_set_hash),
 (15,'msbf_m2.portfolio_strategy_frontier',c.frontier_rows,c.frontier_set_hash),
 (16,'msbf_m2.portfolio_strategy_comparison',c.comparison_rows,c.comparison_set_hash),
 (17,'msbf_m2.portfolio_strategy_simulation_latest',c.latest_rows,c.latest_set_hash),
 (18,'msbf_m2.portfolio_strategy_simulation_archive',c.archive_rows,c.archive_set_hash),
 (19,'msbf_ctl.m2_11_portfolio_strategy_contract_registry',c.registry_rows,
      md5(c.row_hash))
) AS x(catalog_sequence,object_code,expected_row_count,registry_set_hash)
WHERE c.module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context)
  AND c.contract_version=1;

CREATE UNIQUE INDEX tmp_accept_m2_11_registry_family_u1
ON tmp_accept_m2_11_registry_family(object_code);
ANALYZE tmp_accept_m2_11_registry_family;

CREATE TEMP TABLE tmp_accept_m2_11_canonical_mismatch ON COMMIT DROP AS
SELECT
    coalesce(r.catalog_sequence,p.catalog_sequence) AS catalog_sequence,
    coalesce(r.object_code,p.object_code) AS object_code,
    r.expected_row_count,
    p.physical_row_count,
    r.registry_set_hash,
    p.reconstructed_set_hash,
    (r.object_code IS NULL OR p.object_code IS NULL
     OR r.expected_row_count IS DISTINCT FROM p.physical_row_count) AS count_mismatch_flag,
    (r.object_code IS NULL OR p.object_code IS NULL
     OR r.registry_set_hash IS DISTINCT FROM p.reconstructed_set_hash) AS set_hash_mismatch_flag
FROM tmp_accept_m2_11_registry_family r
FULL JOIN tmp_accept_m2_11_canonical_reconstruction p
  USING(object_code);

CREATE TEMP TABLE tmp_accept_m2_11_source_status
(
    source_sequence integer PRIMARY KEY,
    source_code text NOT NULL UNIQUE,
    registry_identity_pass_flag boolean NOT NULL,
    acceptance_gate_pass_flag boolean NOT NULL,
    registry_lineage_pass_flag boolean NOT NULL,
    observed_value text NOT NULL
) ON COMMIT DROP;

INSERT INTO tmp_accept_m2_11_source_status
(
    source_sequence,source_code,registry_identity_pass_flag,
    acceptance_gate_pass_flag,registry_lineage_pass_flag,observed_value
)
VALUES
(
  1,'M1_17',
  (SELECT count(*)=1 FROM msbf_ctl.m1_17_g2_bundle_registry s
   WHERE s.module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context)
     AND (s.bundle_code,s.bundle_version,s.schema_version,s.methodology_version,
          s.integrated_consumption_rows,s.combined_g2_hash,s.bundle_status)
       IS NOT DISTINCT FROM
         ('M1_G2_CONSUMPTION_BUNDLE',1,'M1_G2_BUNDLE_SCHEMA_V1',
          'M1_17_METHOD_V1',1500::bigint,'7d9e466da28cad2551aa99c4c40c912b','ACCEPTED')),
  (SELECT count(*)=1 AND bool_and(result_status='PASS')
   FROM msbf_ctl.acceptance_gate_result
   WHERE run_id=(SELECT run_id FROM tmp_accept_m2_11_context)
     AND gate_id='G2_M1_CONTRACT'),
  (SELECT count(*)=1
   FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry c
   JOIN msbf_ctl.m1_17_g2_bundle_registry s ON s.module1_run_id=c.module1_run_id
   WHERE c.module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context)
     AND c.contract_version=1
     AND (c.source_m1_17_contract_code,c.source_m1_17_contract_version,
          c.source_m1_17_schema_version,c.source_m1_17_methodology_version,
          c.source_m1_17_acceptance_gate_id,c.source_m1_17_combined_hash,
          c.source_m1_17_registry_row_hash)
       IS NOT DISTINCT FROM
         (s.bundle_code,s.bundle_version,s.schema_version,s.methodology_version,
          'G2_M1_CONTRACT',s.combined_g2_hash,s.row_hash)),
  'M1.17 accepted bundle, gate, and lineage'
),
(
  2,'M2_2',
  (SELECT count(*)=1 FROM msbf_ctl.m2_2_pricing_structure_contract_registry s
   WHERE s.module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context)
     AND (s.pricing_contract_code,s.pricing_contract_version,s.pricing_schema_version,
          s.methodology_version,s.pricing_latest_rows,s.candidate_rows,
          s.combined_set_hash,s.contract_status)
       IS NOT DISTINCT FROM
         ('M2_PRICING_STRUCTURE_CONSUMPTION',1,'M2_2_PRICING_STRUCTURE_SCHEMA_V1',
          'M2_2_METHOD_V1',1500::bigint,557::bigint,
          'bbe83b187b31ea561789797322031fc6','ACCEPTED')),
  (SELECT count(*)=1 AND bool_and(result_status='PASS')
   FROM msbf_ctl.acceptance_gate_result
   WHERE run_id=(SELECT run_id FROM tmp_accept_m2_11_context)
     AND gate_id='M2_2_PRICING_STRUCTURE_COUNTEROFFER'),
  (SELECT count(*)=1
   FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry c
   JOIN msbf_ctl.m2_2_pricing_structure_contract_registry s
     ON s.module1_run_id=c.module1_run_id
   WHERE c.module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context)
     AND c.contract_version=1
     AND (c.source_m2_2_contract_code,c.source_m2_2_contract_version,
          c.source_m2_2_schema_version,c.source_m2_2_methodology_version,
          c.source_m2_2_acceptance_gate_id,c.source_m2_2_combined_hash,
          c.source_m2_2_registry_row_hash)
       IS NOT DISTINCT FROM
         (s.pricing_contract_code,s.pricing_contract_version,s.pricing_schema_version,
          s.methodology_version,'M2_2_PRICING_STRUCTURE_COUNTEROFFER',
          s.combined_set_hash,s.row_hash)),
  'M2.2 accepted latest/candidate contract, gate, and lineage'
),
(
  3,'M2_4',
  (SELECT count(*)=1 FROM msbf_ctl.m2_4_portfolio_activation_contract_registry s
   WHERE s.module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context)
     AND (s.contract_code,s.contract_version,s.schema_version,s.methodology_version,
          s.activation_latest_rows,s.combined_set_hash,s.contract_status)
       IS NOT DISTINCT FROM
         ('M2_PORTFOLIO_ACTIVATION_CONSUMPTION',1,
          'M2_4_PORTFOLIO_ACTIVATION_SCHEMA_V1','M2_4_METHOD_V1',
          1500::bigint,'117450a3eea7bb3d3c74d18cc3c8e96a','ACCEPTED')),
  (SELECT count(*)=1 AND bool_and(result_status='PASS')
   FROM msbf_ctl.acceptance_gate_result
   WHERE run_id=(SELECT run_id FROM tmp_accept_m2_11_context)
     AND gate_id='M2_4_BOOKING_FUNDING_PORTFOLIO_ACTIVATION'),
  (SELECT count(*)=1
   FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry c
   JOIN msbf_ctl.m2_4_portfolio_activation_contract_registry s
     ON s.module1_run_id=c.module1_run_id
   WHERE c.module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context)
     AND c.contract_version=1
     AND (c.source_m2_4_contract_code,c.source_m2_4_contract_version,
          c.source_m2_4_schema_version,c.source_m2_4_methodology_version,
          c.source_m2_4_acceptance_gate_id,c.source_m2_4_combined_hash,
          c.source_m2_4_registry_row_hash)
       IS NOT DISTINCT FROM
         (s.contract_code,s.contract_version,s.schema_version,s.methodology_version,
          'M2_4_BOOKING_FUNDING_PORTFOLIO_ACTIVATION',
          s.combined_set_hash,s.row_hash)),
  'M2.4 accepted activation contract, gate, and lineage'
),
(
  4,'M2_7',
  (SELECT count(*)=1 FROM msbf_ctl.m2_7_operational_activation_contract_registry s
   WHERE s.module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context)
     AND (s.contract_code,s.contract_version,s.schema_version,s.methodology_version,
          s.latest_rows,s.combined_set_hash,s.contract_status)
       IS NOT DISTINCT FROM
         ('M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION',1,
          'M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_SCHEMA_V1','M2_7_METHOD_V1',
          59::bigint,'c8e3a472afd2a16b1183677324e9db98','ACCEPTED')),
  (SELECT count(*)=1 AND bool_and(result_status='PASS')
   FROM msbf_ctl.acceptance_gate_result
   WHERE run_id=(SELECT run_id FROM tmp_accept_m2_11_context)
     AND gate_id='M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP'),
  (SELECT count(*)=1
   FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry c
   JOIN msbf_ctl.m2_7_operational_activation_contract_registry s
     ON s.module1_run_id=c.module1_run_id
   WHERE c.module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context)
     AND c.contract_version=1
     AND (c.source_m2_7_contract_code,c.source_m2_7_contract_version,
          c.source_m2_7_schema_version,c.source_m2_7_methodology_version,
          c.source_m2_7_acceptance_gate_id,c.source_m2_7_combined_hash,
          c.source_m2_7_registry_row_hash)
       IS NOT DISTINCT FROM
         (s.contract_code,s.contract_version,s.schema_version,s.methodology_version,
          'M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP',
          s.combined_set_hash,s.row_hash)),
  'M2.7 accepted operational-account contract, gate, and lineage'
),
(
  5,'M2_10',
  (SELECT count(*)=1 FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry s
   WHERE s.module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context)
     AND (s.contract_code,s.contract_version,s.schema_version,s.methodology_version,
          s.latest_rows,s.kpi_snapshot_rows,s.queue_summary_rows,
          s.baseline_account_rows,s.stress_account_rows,s.portfolio_account_rows,
          s.combined_set_hash,s.contract_status)
       IS NOT DISTINCT FROM
         ('M2_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_CONSUMPTION',1,
          'M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_SCHEMA_V1',
          'M2_10_METHOD_V1',59::bigint,72::bigint,3::bigint,
          44::bigint,15::bigint,59::bigint,
          '24fca7263a04397ebf21d30639f9069b','ACCEPTED')),
  (SELECT count(*)=1 AND bool_and(result_status='PASS')
   FROM msbf_ctl.acceptance_gate_result
   WHERE run_id=(SELECT run_id FROM tmp_accept_m2_11_context)
     AND gate_id='M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS'),
  (SELECT count(*)=1
   FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry c
   JOIN msbf_ctl.m2_10_portfolio_analytics_contract_registry s
     ON s.module1_run_id=c.module1_run_id
   WHERE c.module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context)
     AND c.contract_version=1
     AND (c.source_m2_10_contract_code,c.source_m2_10_contract_version,
          c.source_m2_10_schema_version,c.source_m2_10_methodology_version,
          c.source_m2_10_acceptance_gate_id,c.source_m2_10_combined_hash,
          c.source_m2_10_registry_row_hash)
       IS NOT DISTINCT FROM
         (s.contract_code,s.contract_version,s.schema_version,s.methodology_version,
          'M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS',
          s.combined_set_hash,s.row_hash)),
  'M2.10 accepted portfolio analytics contract, gate, and lineage'
);

ANALYZE tmp_accept_m2_11_source_status;

CREATE TEMP TABLE tmp_accept_m2_11_baseline_replay ON COMMIT DROP AS
SELECT
  (SELECT count(*) FROM msbf_m2.application_portfolio_strategy_simulation
    WHERE module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context)
      AND strategy_profile_code='BASELINE_REPLAY')::bigint AS app_rows,
  (SELECT count(*) FROM msbf_m2.application_portfolio_strategy_simulation
    WHERE module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context)
      AND strategy_profile_code='BASELINE_REPLAY'
      AND NOT baseline_replay_match_flag)::bigint AS app_flag_mismatches,
  (SELECT count(*) FROM msbf_m2.account_servicing_strategy_simulation
    WHERE module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context)
      AND strategy_profile_code='BASELINE_REPLAY')::bigint AS account_rows,
  (SELECT count(*) FROM msbf_m2.account_servicing_strategy_simulation
    WHERE module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context)
      AND strategy_profile_code='BASELINE_REPLAY'
      AND NOT source_replay_match_flag)::bigint AS account_flag_mismatches,
  (SELECT count(*) FROM msbf_ctl.run_evidence
    WHERE run_id=(SELECT run_id FROM tmp_accept_m2_11_context)
      AND evidence_code='M2_11_POS_066_BASELINE_APP_REPLAY'
      AND status='PASS')::bigint AS app_validation_rows,
  (SELECT count(*) FROM msbf_ctl.run_evidence
    WHERE run_id=(SELECT run_id FROM tmp_accept_m2_11_context)
      AND evidence_code='M2_11_POS_068_BASELINE_ACCOUNT_REPLAY'
      AND status='PASS')::bigint AS account_validation_rows;

CREATE TEMP TABLE tmp_accept_m2_11_latest_archive_mismatch ON COMMIT DROP AS
SELECT
    coalesce(l.strategy_profile_code,a.strategy_profile_code) AS strategy_profile_code,
    coalesce(l.reporting_scope_code,a.reporting_scope_code) AS reporting_scope_code,
    CASE
      WHEN l.module1_run_id IS NULL THEN 'MISSING_LATEST'
      WHEN a.module1_run_id IS NULL THEN 'MISSING_ARCHIVE'
      WHEN l.contract_row_hash IS DISTINCT FROM a.contract_row_hash THEN 'CONTRACT_ROW_HASH_MISMATCH'
      WHEN a.contract_payload IS DISTINCT FROM (to_jsonb(l)-'created_at') THEN 'ARCHIVE_PAYLOAD_MISMATCH'
      ELSE NULL
    END AS mismatch_code
FROM msbf_m2.portfolio_strategy_simulation_latest l
FULL JOIN msbf_m2.portfolio_strategy_simulation_archive a
  ON a.module1_run_id=l.module1_run_id
 AND a.contract_version=l.contract_version
 AND a.strategy_profile_code=l.strategy_profile_code
 AND a.reporting_scope_code=l.reporting_scope_code
WHERE coalesce(l.module1_run_id,a.module1_run_id)=(SELECT run_id FROM tmp_accept_m2_11_context)
  AND
  (
    l.module1_run_id IS NULL OR a.module1_run_id IS NULL
    OR l.contract_row_hash IS DISTINCT FROM a.contract_row_hash
    OR a.contract_payload IS DISTINCT FROM (to_jsonb(l)-'created_at')
  );

CREATE TEMP TABLE tmp_accept_m2_11_boundary_violation
(
    violation_family text NOT NULL,
    object_name text NOT NULL,
    violation_count bigint NOT NULL,
    detail text NOT NULL
) ON COMMIT DROP;

INSERT INTO tmp_accept_m2_11_boundary_violation
(
    violation_family,object_name,violation_count,detail
)
SELECT 'NON_PRODUCTION','portfolio_strategy_application_source_snapshot',count(*),
       'Source snapshot production/funds/notice flags must all be false'
FROM msbf_m2.portfolio_strategy_application_source_snapshot
WHERE module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context)
  AND (real_funds_movement_flag OR external_notice_generation_authorized_flag
       OR external_notice_transmitted_flag OR production_adverse_action_notice_flag)
HAVING count(*)>0
UNION ALL
SELECT 'NON_PRODUCTION','portfolio_strategy_reason_definition',count(*),
       'Reason definitions may not authorize production, external update, contact, or adverse action'
FROM msbf_m2.portfolio_strategy_reason_definition
WHERE module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context)
  AND (production_action_flag OR external_system_update_flag
       OR merchant_contact_flag OR production_adverse_action_flag)
HAVING count(*)>0
UNION ALL
SELECT 'BLOCKING_ERROR','msbf_ctl.profile_resolution_error',count(*),
       'No blocking profile-resolution error may exist'
FROM msbf_ctl.profile_resolution_error
WHERE run_id=(SELECT run_id FROM tmp_accept_m2_11_context)
  AND severity='BLOCKING'
HAVING count(*)>0
UNION ALL
SELECT 'STAGE_BOUNDARY','information_schema.tables',count(*),
       'M2.12 physical tables or views are premature at M2.11 acceptance'
FROM
(
  SELECT table_schema,table_name
  FROM information_schema.tables
  WHERE table_schema IN ('msbf_ctl','msbf_m1','msbf_m2','msbf_ref')
    AND lower(table_name) LIKE '%m2_12%'
) x
HAVING count(*)>0;

CREATE TEMP TABLE tmp_accept_m2_11_priority_violation ON COMMIT DROP AS
SELECT reporting_scope_code,'MULTIPLE_PRIMARY_PRIORITIES'::text AS violation_code,
       count(*)::bigint AS violation_count
FROM msbf_m2.portfolio_strategy_frontier
WHERE module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context)
  AND primary_governance_review_flag
GROUP BY reporting_scope_code
HAVING count(*)>1
UNION ALL
SELECT reporting_scope_code,'INVALID_PRIMARY_PRIORITY'::text,count(*)::bigint
FROM msbf_m2.portfolio_strategy_frontier
WHERE module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context)
  AND primary_governance_review_flag
  AND
  (
    strategy_profile_code='BASELINE_REPLAY'
    OR frontier_rank IS DISTINCT FROM 1
    OR NOT frontier_eligible_flag
    OR governance_review_priority_code<>'PRIMARY_GOVERNANCE_REVIEW'
  )
GROUP BY reporting_scope_code
HAVING count(*)>0;

/* ============================================================================
Section 4 — Evaluate exactly 45 formal acceptance requirements
============================================================================ */
SELECT pg_temp.m2_11_add_acceptance_requirement(
  1,'M2_11_ACC_001_RUN_VALIDATED','LIFECYCLE',
  'The governed run is exactly M2_11_VALIDATED before acceptance.',
  (SELECT run_status FROM tmp_accept_m2_11_context)::text,
  'M2_11_VALIDATED',
  (SELECT run_status='M2_11_VALIDATED' FROM tmp_accept_m2_11_context),
  'Run lifecycle is not validated.',
  'Final lifecycle'
);

SELECT pg_temp.m2_11_add_acceptance_requirement(
  2,'M2_11_ACC_002_CONTRACT_VALIDATED','LIFECYCLE',
  'The M2.11 contract registry is exactly VALIDATED before acceptance.',
  (SELECT contract_status FROM tmp_accept_m2_11_context)::text,
  'VALIDATED',
  (SELECT contract_status='VALIDATED' FROM tmp_accept_m2_11_context),
  'Contract lifecycle is not validated.',
  'Amendment A17 / B6'
);

SELECT pg_temp.m2_11_add_acceptance_requirement(
  3,'M2_11_ACC_003_VALIDATION_TIMESTAMP','LIFECYCLE',
  'The validation timestamp is populated and accepted timestamp is absent.',
  (SELECT coalesce(validated_at::text,'<NULL>')||'|'||coalesce(accepted_at::text,'<NULL>') FROM tmp_accept_m2_11_context)::text,
  'validated_at present; accepted_at null',
  (SELECT validated_at IS NOT NULL AND accepted_at IS NULL FROM tmp_accept_m2_11_context),
  'Validation timestamp or pre-acceptance timestamp state is invalid.',
  'Program 215 boundary'
);

SELECT pg_temp.m2_11_add_acceptance_requirement(
  4,'M2_11_ACC_004_NO_PRIOR_ACCEPTANCE_EVIDENCE','LIFECYCLE',
  'No M2.11 acceptance evidence row exists before finalization.',
  (SELECT prior_acceptance_rows FROM tmp_accept_m2_11_evidence_summary)::text,
  '0 rows',
  (SELECT prior_acceptance_rows=0 FROM tmp_accept_m2_11_evidence_summary),
  'Prior acceptance evidence exists.',
  'Program 217 boundary'
);

SELECT pg_temp.m2_11_add_acceptance_requirement(
  5,'M2_11_ACC_005_NO_PRIOR_ACCEPTANCE_GATE','LIFECYCLE',
  'No M2.11 acceptance-gate result exists before finalization.',
  (SELECT count(*) FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM tmp_accept_m2_11_context) AND gate_id='M2_11_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION')::text,
  '0 rows',
  (SELECT count(*)=0 FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM tmp_accept_m2_11_context) AND gate_id='M2_11_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION'),
  'Prior M2.11 gate result exists.',
  'Program 217 boundary'
);

SELECT pg_temp.m2_11_add_acceptance_requirement(
  6,'M2_11_ACC_006_GATE_CATALOG','GOVERNANCE',
  'The M2.11 gate catalog definition is active, BLOCKING severity, and exact.',
  (SELECT count(*) FROM msbf_ref.acceptance_gate_catalog WHERE gate_id='M2_11_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION')::text,
  '1 exact active BLOCKING-severity row',
  (SELECT count(*)=1 FROM msbf_ref.acceptance_gate_catalog WHERE gate_id='M2_11_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION' AND gate_name='M2.11 Portfolio Optimization & Strategy Simulation' AND module_code='M2.11' AND severity='BLOCKING' AND active_flag),
  'M2.11 gate catalog definition is absent or incompatible.',
  'Final freeze identity'
);

SELECT pg_temp.m2_11_add_acceptance_requirement(
  7,'M2_11_ACC_007_POSITIVE_COUNT','VALIDATION',
  'Exactly 120 positive-control evidence rows exist.',
  (SELECT positive_rows FROM tmp_accept_m2_11_evidence_summary)::text,
  '120 rows',
  (SELECT positive_rows=120 FROM tmp_accept_m2_11_evidence_summary),
  'Positive-control evidence count is not 120.',
  'Frozen validation count'
);

SELECT pg_temp.m2_11_add_acceptance_requirement(
  8,'M2_11_ACC_008_POSITIVE_ALL_PASS','VALIDATION',
  'All 120 positive controls are PASS and none fail.',
  (SELECT positive_pass_rows||'|'||positive_nonpass_rows FROM tmp_accept_m2_11_evidence_summary)::text,
  '120 PASS / 0 non-PASS',
  (SELECT positive_pass_rows=120 AND positive_nonpass_rows=0 FROM tmp_accept_m2_11_evidence_summary),
  'Not all positive controls passed.',
  'Program 215'
);

SELECT pg_temp.m2_11_add_acceptance_requirement(
  9,'M2_11_ACC_009_NEGATIVE_COUNT','VALIDATION',
  'Exactly 20 negative-control evidence rows exist.',
  (SELECT negative_rows FROM tmp_accept_m2_11_evidence_summary)::text,
  '20 rows',
  (SELECT negative_rows=20 FROM tmp_accept_m2_11_evidence_summary),
  'Negative-control evidence count is not 20.',
  'Frozen negative-control count'
);

SELECT pg_temp.m2_11_add_acceptance_requirement(
  10,'M2_11_ACC_010_NEGATIVE_ALL_PASS','VALIDATION',
  'All 20 isolated negative controls are PASS and none fail.',
  (SELECT negative_pass_rows||'|'||negative_nonpass_rows FROM tmp_accept_m2_11_evidence_summary)::text,
  '20 PASS / 0 non-PASS',
  (SELECT negative_pass_rows=20 AND negative_nonpass_rows=0 FROM tmp_accept_m2_11_evidence_summary),
  'Not all negative controls passed.',
  'Program 216'
);

SELECT pg_temp.m2_11_add_acceptance_requirement(
  11,'M2_11_ACC_011_GENERATION_COUNT','GENERATION',
  'Exactly 24 generated strategy-and-scope evidence rows exist.',
  (SELECT generation_rows FROM tmp_accept_m2_11_evidence_summary)::text,
  '24 rows',
  (SELECT generation_rows=24 FROM tmp_accept_m2_11_evidence_summary),
  'Generation evidence count is not 24.',
  'Frozen generation evidence count'
);

SELECT pg_temp.m2_11_add_acceptance_requirement(
  12,'M2_11_ACC_012_GENERATION_ALL_PASS','GENERATION',
  'All 24 generation evidence rows are PASS.',
  (SELECT generation_pass_rows||'|'||generation_nonpass_rows FROM tmp_accept_m2_11_evidence_summary)::text,
  '24 PASS / 0 non-PASS',
  (SELECT generation_pass_rows=24 AND generation_nonpass_rows=0 FROM tmp_accept_m2_11_evidence_summary),
  'Not all generation evidence rows passed.',
  'Program 214'
);

SELECT pg_temp.m2_11_add_acceptance_requirement(
  13,'M2_11_ACC_013_NO_FAILED_EVIDENCE','VALIDATION',
  'No persisted M2.11 evidence row has a non-PASS status before acceptance.',
  (SELECT all_nonpass_rows FROM tmp_accept_m2_11_evidence_summary)::text,
  '0 non-PASS rows',
  (SELECT all_nonpass_rows=0 FROM tmp_accept_m2_11_evidence_summary),
  'A persisted M2.11 evidence row is not PASS.',
  'Acceptance fail-closed boundary'
);

SELECT pg_temp.m2_11_add_acceptance_requirement(
  14,'M2_11_ACC_014_M1_17_SOURCE_ACCEPTED','SOURCE_IDENTITY',
  'The accepted M1.17 contract identity, count, hash, status, and registry lineage match the M2.11 registry.',
  (SELECT observed_value||'|registry_identity_pass_flag='||registry_identity_pass_flag FROM tmp_accept_m2_11_source_status WHERE source_code='M1_17')::text,
  '1 exact accepted row',
  (SELECT registry_identity_pass_flag FROM tmp_accept_m2_11_source_status WHERE source_code='M1_17'),
  'M1_17 source or gate requirement failed.',
  'Source family 2'
);

SELECT pg_temp.m2_11_add_acceptance_requirement(
  15,'M2_11_ACC_015_M1_17_GATE_PASS','SOURCE_IDENTITY',
  'The accepted M1.17 G2 gate has exactly one PASS result.',
  (SELECT observed_value||'|acceptance_gate_pass_flag='||acceptance_gate_pass_flag FROM tmp_accept_m2_11_source_status WHERE source_code='M1_17')::text,
  '1 PASS row',
  (SELECT acceptance_gate_pass_flag FROM tmp_accept_m2_11_source_status WHERE source_code='M1_17'),
  'M1_17 source or gate requirement failed.',
  'Source family 2'
);

SELECT pg_temp.m2_11_add_acceptance_requirement(
  16,'M2_11_ACC_016_M2_2_SOURCE_ACCEPTED','SOURCE_IDENTITY',
  'The accepted M2.2 identity, 1,500 latest rows, 557 candidates, hash, status, and lineage match.',
  (SELECT observed_value||'|registry_identity_pass_flag='||registry_identity_pass_flag FROM tmp_accept_m2_11_source_status WHERE source_code='M2_2')::text,
  '1 exact accepted row',
  (SELECT registry_identity_pass_flag FROM tmp_accept_m2_11_source_status WHERE source_code='M2_2'),
  'M2_2 source or gate requirement failed.',
  'Source family 3'
);

SELECT pg_temp.m2_11_add_acceptance_requirement(
  17,'M2_11_ACC_017_M2_2_GATE_PASS','SOURCE_IDENTITY',
  'The accepted M2.2 gate has exactly one PASS result.',
  (SELECT observed_value||'|acceptance_gate_pass_flag='||acceptance_gate_pass_flag FROM tmp_accept_m2_11_source_status WHERE source_code='M2_2')::text,
  '1 PASS row',
  (SELECT acceptance_gate_pass_flag FROM tmp_accept_m2_11_source_status WHERE source_code='M2_2'),
  'M2_2 source or gate requirement failed.',
  'Source family 3'
);

SELECT pg_temp.m2_11_add_acceptance_requirement(
  18,'M2_11_ACC_018_M2_4_SOURCE_ACCEPTED','SOURCE_IDENTITY',
  'The accepted M2.4 identity, 1,500 rows, hash, status, and lineage match.',
  (SELECT observed_value||'|registry_identity_pass_flag='||registry_identity_pass_flag FROM tmp_accept_m2_11_source_status WHERE source_code='M2_4')::text,
  '1 exact accepted row',
  (SELECT registry_identity_pass_flag FROM tmp_accept_m2_11_source_status WHERE source_code='M2_4'),
  'M2_4 source or gate requirement failed.',
  'Source family 4'
);

SELECT pg_temp.m2_11_add_acceptance_requirement(
  19,'M2_11_ACC_019_M2_4_GATE_PASS','SOURCE_IDENTITY',
  'The accepted M2.4 gate has exactly one PASS result.',
  (SELECT observed_value||'|acceptance_gate_pass_flag='||acceptance_gate_pass_flag FROM tmp_accept_m2_11_source_status WHERE source_code='M2_4')::text,
  '1 PASS row',
  (SELECT acceptance_gate_pass_flag FROM tmp_accept_m2_11_source_status WHERE source_code='M2_4'),
  'M2_4 source or gate requirement failed.',
  'Source family 4'
);

SELECT pg_temp.m2_11_add_acceptance_requirement(
  20,'M2_11_ACC_020_M2_7_SOURCE_ACCEPTED','SOURCE_IDENTITY',
  'The accepted M2.7 identity, 59 rows, hash, status, and lineage match.',
  (SELECT observed_value||'|registry_identity_pass_flag='||registry_identity_pass_flag FROM tmp_accept_m2_11_source_status WHERE source_code='M2_7')::text,
  '1 exact accepted row',
  (SELECT registry_identity_pass_flag FROM tmp_accept_m2_11_source_status WHERE source_code='M2_7'),
  'M2_7 source or gate requirement failed.',
  'Source family 5'
);

SELECT pg_temp.m2_11_add_acceptance_requirement(
  21,'M2_11_ACC_021_M2_7_GATE_PASS','SOURCE_IDENTITY',
  'The accepted M2.7 gate has exactly one PASS result.',
  (SELECT observed_value||'|acceptance_gate_pass_flag='||acceptance_gate_pass_flag FROM tmp_accept_m2_11_source_status WHERE source_code='M2_7')::text,
  '1 PASS row',
  (SELECT acceptance_gate_pass_flag FROM tmp_accept_m2_11_source_status WHERE source_code='M2_7'),
  'M2_7 source or gate requirement failed.',
  'Source family 5'
);

SELECT pg_temp.m2_11_add_acceptance_requirement(
  22,'M2_11_ACC_022_M2_10_SOURCE_ACCEPTED','SOURCE_IDENTITY',
  'The accepted M2.10 identity, 59 latest rows, 72 KPI rows, 3 queue rows, 59 total scenario-account rows, 44 BASELINE rows, 15 RECESSION_ENERGY rows, hash, status, and lineage match.',
  (SELECT observed_value||'|registry_identity_pass_flag='||registry_identity_pass_flag FROM tmp_accept_m2_11_source_status WHERE source_code='M2_10')::text,
  '1 exact accepted row',
  (SELECT registry_identity_pass_flag FROM tmp_accept_m2_11_source_status WHERE source_code='M2_10'),
  'M2_10 source or gate requirement failed.',
  'Source family 1'
);

SELECT pg_temp.m2_11_add_acceptance_requirement(
  23,'M2_11_ACC_023_M2_10_GATE_PASS','SOURCE_IDENTITY',
  'The accepted M2.10 gate has exactly one PASS result.',
  (SELECT observed_value||'|acceptance_gate_pass_flag='||acceptance_gate_pass_flag FROM tmp_accept_m2_11_source_status WHERE source_code='M2_10')::text,
  '1 PASS row',
  (SELECT acceptance_gate_pass_flag FROM tmp_accept_m2_11_source_status WHERE source_code='M2_10'),
  'M2_10 source or gate requirement failed.',
  'Source family 1'
);

SELECT pg_temp.m2_11_add_acceptance_requirement(
  24,'M2_11_ACC_024_REGISTRY_SOURCE_LINEAGE','SOURCE_IDENTITY',
  'All five accepted source registry row hashes and combined hashes are preserved in the M2.11 registry.',
  (SELECT count(*) FILTER(WHERE NOT registry_lineage_pass_flag) FROM tmp_accept_m2_11_source_status)::text,
  '0 lineage mismatches',
  (SELECT count(*) FILTER(WHERE NOT registry_lineage_pass_flag)=0 FROM tmp_accept_m2_11_source_status),
  'One or more accepted source registry hashes or identities do not match the M2.11 registry.',
  'Five-source hierarchy'
);

SELECT pg_temp.m2_11_add_acceptance_requirement(
  25,'M2_11_ACC_025_POLICY_IDENTITY_BOUNDARY','POLICY',
  'The policy identity, counts, precision, inherited M2.2 bounds, and non-production flags remain exact.',
  (SELECT count(*) FROM msbf_ctl.m2_11_policy_profile WHERE module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context))::text,
  '1 exact governed policy row',
  (SELECT count(*)=1
FROM msbf_ctl.m2_11_policy_profile p
WHERE p.module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context)
  AND (p.policy_code,p.policy_version,p.methodology_version,p.contract_code,
       p.contract_version,p.schema_version,p.acceptance_gate_id,
       p.strategy_profile_rows,p.objective_definition_rows,p.constraint_definition_rows,
       p.reason_definition_rows,p.reporting_scope_count,p.canonical_entities,
       p.positive_controls,p.negative_controls,p.generation_evidence_rows,
       p.acceptance_evidence_rows,p.detail_result_sets,p.score_precision_scale,
       p.normalized_precision_scale,p.candidate_score_tolerance,
       p.servicing_burden_coverage_code)
    IS NOT DISTINCT FROM
      ('M2_11_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_POLICY_V1',1,
       'M2_11_METHOD_V1','M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION',
       1,'M2_11_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_SCHEMA_V1',
       'M2_11_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION',
       8::bigint,8::bigint,12::bigint,32::bigint,3::bigint,19298::bigint,
       120::bigint,20::bigint,24::bigint,1::bigint,24::bigint,
       12::smallint,10::smallint,0.000000000001::numeric(22,12),
       'ACCEPTED_OPERATIONAL_ACCOUNTS_ONLY')
  AND p.synthetic_data_only_flag
  AND p.non_production_boundary_flag
  AND p.no_external_system_update_flag
  AND p.no_merchant_contact_flag
  AND p.no_real_funds_movement_flag
  AND p.no_production_decisioning_flag
  AND NOT p.new_access_servicing_burden_estimated_flag
  AND p.configuration_hash=msbf_ctl.m2_11_hash_jsonb(p.configuration_payload)
  AND p.configuration_payload#>>'{inherited_m2_2_structure_bounds,source_policy_configuration_hash}'
      ='9e03c9ee37880e3ed16e12fb0c0ce0d4'),
  'Policy identity, precision, counts, inherited bounds, hash, or non-production boundary changed.',
  'Original freeze + Amendments A/B'
);

SELECT pg_temp.m2_11_add_acceptance_requirement(
  26,'M2_11_ACC_026_CANONICAL_FAMILY_COUNT','CANONICAL_IDENTITY',
  'Exactly nineteen canonical object families are present.',
  (SELECT count(*) FROM tmp_accept_m2_11_canonical_reconstruction)::text,
  '19 families',
  (SELECT count(*)=19 FROM tmp_accept_m2_11_canonical_reconstruction),
  'Canonical family count is not nineteen.',
  'Frozen canonical inventory'
);

SELECT pg_temp.m2_11_add_acceptance_requirement(
  27,'M2_11_ACC_027_CANONICAL_ENTITY_COUNT','CANONICAL_IDENTITY',
  'Exactly 19,298 canonical entities are present for the governed run.',
  (SELECT coalesce(sum(physical_row_count),0) FROM tmp_accept_m2_11_canonical_reconstruction)::text,
  '19,298 rows',
  (SELECT coalesce(sum(physical_row_count),0)=19298 FROM tmp_accept_m2_11_canonical_reconstruction),
  'Canonical entity count is not 19,298.',
  'Frozen canonical count'
);

SELECT pg_temp.m2_11_add_acceptance_requirement(
  28,'M2_11_ACC_028_CANONICAL_COUNT_REGISTRY_RECON','CANONICAL_IDENTITY',
  'Each physical family count equals its registry count and the registry total is 19,298.',
  (SELECT count(*) FILTER(WHERE count_mismatch_flag) FROM tmp_accept_m2_11_canonical_mismatch)::text,
  '0 count mismatches',
  (SELECT count(*)=19
                  AND count(*) FILTER(WHERE count_mismatch_flag)=0
                  AND (SELECT canonical_entities=19298
                       FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry
                       WHERE module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context)
                         AND contract_version=1)
            FROM tmp_accept_m2_11_canonical_mismatch),
  'A physical canonical count differs from the registry.',
  'Program 214 physical reconciliation'
);

SELECT pg_temp.m2_11_add_acceptance_requirement(
  29,'M2_11_ACC_029_ORDERED_SET_HASH_RECON','HASH',
  'All nineteen target-typed physical canonical family hashes reconstruct with the exact Program 214/215 business-key ordering and equal the registry hashes.',
  (SELECT count(*) FILTER(WHERE set_hash_mismatch_flag) FROM tmp_accept_m2_11_canonical_mismatch)::text,
  '0 set-hash mismatches',
  (SELECT count(*)=19 AND count(*) FILTER(WHERE set_hash_mismatch_flag)=0 FROM tmp_accept_m2_11_canonical_mismatch),
  'One or more ordered canonical set hashes do not reconcile.',
  'Program 214/215 target-typed physical hash reconstruction'
);

SELECT pg_temp.m2_11_add_acceptance_requirement(
  30,'M2_11_ACC_030_CONTRACT_SET_HASH_RECON','HASH',
  'The contract set hash equals md5(latest_set_hash | archive_set_hash).',
  (SELECT contract_set_hash FROM tmp_accept_m2_11_context)::text,
  'md5(latest_set_hash|archive_set_hash)',
  (SELECT c.contract_set_hash=
                  md5(c.latest_set_hash||'|'||c.archive_set_hash)
            FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry c
            WHERE c.module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context)
              AND c.contract_version=1),
  'Contract set hash does not reconcile.',
  'Amendment A17 / B6'
);

SELECT pg_temp.m2_11_add_acceptance_requirement(
  31,'M2_11_ACC_031_COMBINED_SET_HASH_RECON','HASH',
  'The combined set hash equals the catalog-sequence aggregation of all nineteen target-typed reconstructed family hashes.',
  (SELECT combined_set_hash FROM tmp_accept_m2_11_context)::text,
  'ordered md5 across nineteen family hashes',
  (SELECT c.combined_set_hash=
                  (SELECT md5(string_agg(object_code||'|'||reconstructed_set_hash,
                                         '|' ORDER BY catalog_sequence))
                   FROM tmp_accept_m2_11_canonical_reconstruction)
            FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry c
            WHERE c.module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context)
              AND c.contract_version=1),
  'Combined set hash does not reconcile.',
  'Canonical combined identity'
);

SELECT pg_temp.m2_11_add_acceptance_requirement(
  32,'M2_11_ACC_032_REGISTRY_ROW_HASH_RECON','HASH',
  'The immutable registry row hash reconstructs from the accepted physical registry row.',
  (SELECT registry_row_hash FROM tmp_accept_m2_11_context)::text,
  'exact physical registry row hash',
  (SELECT c.row_hash=msbf_ctl.m2_11_registry_row_hash(to_jsonb(c))
            FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry c
            WHERE c.module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context)
              AND c.contract_version=1),
  'Registry row hash does not reconstruct.',
  'WP2 hash preimage specification'
);

SELECT pg_temp.m2_11_add_acceptance_requirement(
  33,'M2_11_ACC_033_BASELINE_APP_REPLAY','BASELINE_REPLAY',
  'BASELINE_REPLAY has 1,500 rows, all baseline replay flags are true, and independent Positive Control 066 passed.',
  (SELECT app_rows||'|'||app_flag_mismatches||'|'||app_validation_rows FROM tmp_accept_m2_11_baseline_replay)::text,
  '1,500 rows; 0 flag mismatches; Positive 066 PASS',
  (SELECT app_rows=1500 AND app_flag_mismatches=0 AND app_validation_rows=1 FROM tmp_accept_m2_11_baseline_replay),
  'Application baseline replay does not reconcile.',
  'Amendment A8'
);

SELECT pg_temp.m2_11_add_acceptance_requirement(
  34,'M2_11_ACC_034_BASELINE_ACCOUNT_REPLAY','BASELINE_REPLAY',
  'BASELINE_REPLAY has 59 account rows, all source replay flags are true, and Positive Control 068 passed.',
  (SELECT account_rows||'|'||account_flag_mismatches||'|'||account_validation_rows FROM tmp_accept_m2_11_baseline_replay)::text,
  '59 rows; 0 flag mismatches; Positive 068 PASS',
  (SELECT account_rows=59 AND account_flag_mismatches=0 AND account_validation_rows=1 FROM tmp_accept_m2_11_baseline_replay),
  'Account baseline replay does not reconcile.',
  'Amendment A8 / B4'
);

SELECT pg_temp.m2_11_add_acceptance_requirement(
  35,'M2_11_ACC_035_SELECTED_CANDIDATE_INVENTORY','CANDIDATE_BOUNDARY',
  'Every selected candidate resolves to the accepted M2.2 candidate snapshot.',
  (SELECT count(*) FROM msbf_m2.application_portfolio_strategy_simulation s
            WHERE s.module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context)
              AND s.selected_candidate_template_code IS NOT NULL
              AND NOT EXISTS
              (
                SELECT 1
                FROM msbf_m2.portfolio_strategy_candidate_source_snapshot c
                WHERE c.module1_run_id=s.module1_run_id
                  AND c.scenario_id=s.scenario_id
                  AND c.merchant_application_id=s.merchant_application_id
                  AND c.candidate_template_code=s.selected_candidate_template_code
                  AND c.source_candidate_row_hash=s.selected_candidate_source_row_hash
              ))::text,
  '0 unaccepted selections',
  (SELECT count(*)=0 FROM msbf_m2.application_portfolio_strategy_simulation s
            WHERE s.module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context)
              AND s.selected_candidate_template_code IS NOT NULL
              AND NOT EXISTS
              (
                SELECT 1
                FROM msbf_m2.portfolio_strategy_candidate_source_snapshot c
                WHERE c.module1_run_id=s.module1_run_id
                  AND c.scenario_id=s.scenario_id
                  AND c.merchant_application_id=s.merchant_application_id
                  AND c.candidate_template_code=s.selected_candidate_template_code
                  AND c.source_candidate_row_hash=s.selected_candidate_source_row_hash
              )),
  'A selected candidate is outside accepted M2.2 inventory.',
  'Accepted-candidate restriction'
);

SELECT pg_temp.m2_11_add_acceptance_requirement(
  36,'M2_11_ACC_036_POLICY_DECLINE_PRESERVATION','OUTCOME_BOUNDARY',
  'Every source policy decline remains NO_ACCESS_POLICY_DECLINE for all eight strategies.',
  (SELECT count(*) FROM msbf_m2.application_portfolio_strategy_simulation s
            JOIN msbf_m2.portfolio_strategy_application_source_snapshot a
              USING(module1_run_id,scenario_id,scenario_code,merchant_application_id)
            WHERE s.module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context)
              AND a.pricing_disposition_code='NO_STRUCTURE_POLICY_DECLINE'
              AND s.strategy_outcome_code<>'NO_ACCESS_POLICY_DECLINE')::text,
  '0 favorable overrides',
  (SELECT count(*)=0 FROM msbf_m2.application_portfolio_strategy_simulation s
            JOIN msbf_m2.portfolio_strategy_application_source_snapshot a
              USING(module1_run_id,scenario_id,scenario_code,merchant_application_id)
            WHERE s.module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context)
              AND a.pricing_disposition_code='NO_STRUCTURE_POLICY_DECLINE'
              AND s.strategy_outcome_code<>'NO_ACCESS_POLICY_DECLINE'),
  'A policy decline was not preserved.',
  'Hard constraint 3'
);

SELECT pg_temp.m2_11_add_acceptance_requirement(
  37,'M2_11_ACC_037_INSUFFICIENT_PRESERVATION','OUTCOME_BOUNDARY',
  'Every source insufficient-evidence outcome remains NO_ACCESS_INSUFFICIENT_EVIDENCE for all eight strategies.',
  (SELECT count(*) FROM msbf_m2.application_portfolio_strategy_simulation s
            JOIN msbf_m2.portfolio_strategy_application_source_snapshot a
              USING(module1_run_id,scenario_id,scenario_code,merchant_application_id)
            WHERE s.module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context)
              AND a.pricing_disposition_code='NO_STRUCTURE_INSUFFICIENT_EVIDENCE'
              AND s.strategy_outcome_code<>'NO_ACCESS_INSUFFICIENT_EVIDENCE')::text,
  '0 favorable overrides',
  (SELECT count(*)=0 FROM msbf_m2.application_portfolio_strategy_simulation s
            JOIN msbf_m2.portfolio_strategy_application_source_snapshot a
              USING(module1_run_id,scenario_id,scenario_code,merchant_application_id)
            WHERE s.module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context)
              AND a.pricing_disposition_code='NO_STRUCTURE_INSUFFICIENT_EVIDENCE'
              AND s.strategy_outcome_code<>'NO_ACCESS_INSUFFICIENT_EVIDENCE'),
  'An insufficient-evidence outcome was not preserved.',
  'Hard constraint 4'
);

SELECT pg_temp.m2_11_add_acceptance_requirement(
  38,'M2_11_ACC_038_STRESS_NONIMPROVEMENT','STRESS',
  'All six stress-improvement violation types are zero and all strategy/scope summaries pass.',
  (SELECT
 (SELECT count(*) FROM msbf_m2.application_portfolio_strategy_simulation
   WHERE module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context)
     AND (source_risk_improvement_violation_flag
       OR source_return_improvement_violation_flag
       OR strategy_access_improvement_violation_flag
       OR strategy_feasibility_improvement_violation_flag
       OR comparable_payment_burden_improvement_violation_flag
       OR comparable_servicing_burden_improvement_violation_flag))::text
 ||'|'||
 (SELECT count(*) FROM msbf_m2.portfolio_strategy_summary
   WHERE module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context)
     AND (stress_improvement_violation_count<>0 OR NOT stress_nonimprovement_pass_flag))::text
 ||'|'||
 (SELECT count(*) FROM msbf_m2.portfolio_strategy_comparison
   WHERE module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context)
     AND (challenger_stress_improvement_violation_count<>0
       OR NOT challenger_stress_nonimprovement_pass_flag))::text)::text,
  '0 application / 0 summary / 0 comparison violations',
  (SELECT
 (SELECT count(*) FROM msbf_m2.application_portfolio_strategy_simulation
   WHERE module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context)
     AND (source_risk_improvement_violation_flag
       OR source_return_improvement_violation_flag
       OR strategy_access_improvement_violation_flag
       OR strategy_feasibility_improvement_violation_flag
       OR comparable_payment_burden_improvement_violation_flag
       OR comparable_servicing_burden_improvement_violation_flag))=0
 AND
 (SELECT count(*) FROM msbf_m2.portfolio_strategy_summary
   WHERE module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context)
     AND (stress_improvement_violation_count<>0 OR NOT stress_nonimprovement_pass_flag))=0
 AND
 (SELECT count(*) FROM msbf_m2.portfolio_strategy_comparison
   WHERE module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context)
     AND (challenger_stress_improvement_violation_count<>0
       OR NOT challenger_stress_nonimprovement_pass_flag))=0),
  'Stress non-improvement requirements are violated.',
  'Amendment A15'
);

SELECT pg_temp.m2_11_add_acceptance_requirement(
  39,'M2_11_ACC_039_LATEST_ARCHIVE_EXACT','ARCHIVE',
  'All 24 latest rows have exact immutable archive reproduction and matching contract hashes.',
  (SELECT (SELECT count(*) FROM msbf_m2.portfolio_strategy_simulation_latest WHERE module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context))||'|'||(SELECT count(*) FROM msbf_m2.portfolio_strategy_simulation_archive WHERE module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context) AND contract_version=1)||'|'||(SELECT count(*) FROM tmp_accept_m2_11_latest_archive_mismatch))::text,
  '24 latest / 24 archive / 0 mismatch',
  (SELECT
           (SELECT count(*) FROM msbf_m2.portfolio_strategy_simulation_latest
             WHERE module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context))=24
           AND
           (SELECT count(*) FROM msbf_m2.portfolio_strategy_simulation_archive
             WHERE module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context)
               AND contract_version=1)=24
           AND (SELECT count(*) FROM tmp_accept_m2_11_latest_archive_mismatch)=0),
  'Latest/archive reproduction is not exact.',
  'Amendment A17 / B6'
);

SELECT pg_temp.m2_11_add_acceptance_requirement(
  40,'M2_11_ACC_040_ARCHIVE_IMMUTABILITY_TRIGGER','ARCHIVE',
  'The governed BEFORE UPDATE OR DELETE archive trigger is installed and enabled.',
  (SELECT count(*) FROM pg_trigger t
            JOIN pg_proc p ON p.oid=t.tgfoid
            JOIN pg_namespace n ON n.oid=p.pronamespace
            WHERE t.tgrelid='msbf_m2.portfolio_strategy_simulation_archive'::regclass
              AND t.tgname='trg_m2_11_archive_immutable'
              AND t.tgfoid='msbf_ctl.m2_11_block_archive_mutation()'::regprocedure
              AND NOT t.tgisinternal AND t.tgenabled='O' AND t.tgtype=27
              AND n.nspname='msbf_ctl' AND p.proname='m2_11_block_archive_mutation')::text,
  '1 exact enabled BEFORE UPDATE OR DELETE trigger',
  (SELECT count(*)=1 FROM pg_trigger t
            JOIN pg_proc p ON p.oid=t.tgfoid
            JOIN pg_namespace n ON n.oid=p.pronamespace
            WHERE t.tgrelid='msbf_m2.portfolio_strategy_simulation_archive'::regclass
              AND t.tgname='trg_m2_11_archive_immutable'
              AND t.tgfoid='msbf_ctl.m2_11_block_archive_mutation()'::regprocedure
              AND NOT t.tgisinternal AND t.tgenabled='O' AND t.tgtype=27
              AND n.nspname='msbf_ctl' AND p.proname='m2_11_block_archive_mutation'),
  'Archive immutability trigger is absent, disabled, or incompatible.',
  'Archive immutability'
);

SELECT pg_temp.m2_11_add_acceptance_requirement(
  41,'M2_11_ACC_041_GOVERNANCE_PRIORITY_BOUNDARY','GOVERNANCE',
  'Each scope has at most one primary governance-review priority; baseline is never primary; primary rows are eligible Rank 1 challengers.',
  (SELECT count(*) FROM tmp_accept_m2_11_priority_violation)::text,
  '0 priority violations',
  (SELECT count(*)=0 FROM tmp_accept_m2_11_priority_violation),
  'Governance-review priority exceeds or violates the frozen boundary.',
  'Amendment A14'
);

SELECT pg_temp.m2_11_add_acceptance_requirement(
  42,'M2_11_ACC_042_NON_PRODUCTION_BOUNDARY','BOUNDARY',
  'No source snapshot or reason definition authorizes funds movement, external notices, merchant contact, production action, or adverse action.',
  (SELECT coalesce(sum(violation_count),0) FROM tmp_accept_m2_11_boundary_violation WHERE violation_family='NON_PRODUCTION')::text,
  '0 non-production violations',
  (SELECT count(*)=0 FROM tmp_accept_m2_11_boundary_violation WHERE violation_family='NON_PRODUCTION'),
  'A persisted row authorizes prohibited production or external behavior.',
  'Hard constraint 12'
);

SELECT pg_temp.m2_11_add_acceptance_requirement(
  43,'M2_11_ACC_043_BLOCKING_ERRORS_ZERO','BOUNDARY',
  'No blocking profile-resolution error exists for the governed run.',
  (SELECT coalesce(sum(violation_count),0) FROM tmp_accept_m2_11_boundary_violation WHERE violation_family='BLOCKING_ERROR')::text,
  '0 blocking rows',
  (SELECT count(*)=0 FROM tmp_accept_m2_11_boundary_violation WHERE violation_family='BLOCKING_ERROR'),
  'A blocking profile-resolution error exists.',
  'Fail-closed governance'
);

SELECT pg_temp.m2_11_add_acceptance_requirement(
  44,'M2_11_ACC_044_M2_12_STAGE_BOUNDARY','BOUNDARY',
  'No premature M2.12 physical table or view exists.',
  (SELECT coalesce(sum(violation_count),0) FROM tmp_accept_m2_11_boundary_violation WHERE violation_family='STAGE_BOUNDARY')::text,
  '0 premature M2.12 objects',
  (SELECT count(*)=0 FROM tmp_accept_m2_11_boundary_violation WHERE violation_family='STAGE_BOUNDARY'),
  'A premature M2.12 object exists.',
  'M2.12 handoff boundary'
);

SELECT pg_temp.m2_11_add_acceptance_requirement(
  45,'M2_11_ACC_045_EXACT_CONTRACT_COUNTS','CONTRACT',
  'The exact 24 summary, 24 frontier, 21 comparison, 24 latest, 24 archive, and one registry counts remain intact.',
  (SELECT
          (SELECT count(*) FROM msbf_m2.portfolio_strategy_summary WHERE module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context))||'|'||
          (SELECT count(*) FROM msbf_m2.portfolio_strategy_frontier WHERE module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context))||'|'||
          (SELECT count(*) FROM msbf_m2.portfolio_strategy_comparison WHERE module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context))||'|'||
          (SELECT count(*) FROM msbf_m2.portfolio_strategy_simulation_latest WHERE module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context))||'|'||
          (SELECT count(*) FROM msbf_m2.portfolio_strategy_simulation_archive WHERE module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context) AND contract_version=1)||'|'||
          (SELECT count(*) FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry WHERE module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context) AND contract_version=1))::text,
  '24|24|21|24|24|1',
  (SELECT
          (SELECT count(*) FROM msbf_m2.portfolio_strategy_summary WHERE module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context))=24
          AND (SELECT count(*) FROM msbf_m2.portfolio_strategy_frontier WHERE module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context))=24
          AND (SELECT count(*) FROM msbf_m2.portfolio_strategy_comparison WHERE module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context))=21
          AND (SELECT count(*) FROM msbf_m2.portfolio_strategy_simulation_latest WHERE module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context))=24
          AND (SELECT count(*) FROM msbf_m2.portfolio_strategy_simulation_archive WHERE module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context) AND contract_version=1)=24
          AND (SELECT count(*) FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry WHERE module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context) AND contract_version=1)=1),
  'One or more contract-layer counts differ from the freeze.',
  'Frozen physical counts'
);

/* ============================================================================
Section 5 — Fail-closed requirement reconciliation
============================================================================ */
DO $m211_acceptance_requirement_guard$
DECLARE
    v_total bigint;
    v_pass bigint;
    v_fail bigint;
    v_failed text;
BEGIN
    SELECT
      count(*),
      count(*) FILTER(WHERE status='PASS'),
      count(*) FILTER(WHERE status='FAIL'),
      string_agg(requirement_code||'['||coalesce(observed_value,'<NULL>')||
        ' versus '||threshold_value||']','; ' ORDER BY requirement_sequence)
        FILTER(WHERE status='FAIL')
    INTO v_total,v_pass,v_fail,v_failed
    FROM tmp_accept_m2_11_requirement;

    IF v_total<>45
       OR (SELECT count(DISTINCT requirement_code) FROM tmp_accept_m2_11_requirement)<>45
       OR (SELECT min(requirement_sequence) FROM tmp_accept_m2_11_requirement)<>1
       OR (SELECT max(requirement_sequence) FROM tmp_accept_m2_11_requirement)<>45 THEN
      RAISE EXCEPTION
        'Program 217 acceptance requirement inventory mismatch: total %, unique %, range %..%',
        v_total,
        (SELECT count(DISTINCT requirement_code) FROM tmp_accept_m2_11_requirement),
        (SELECT min(requirement_sequence) FROM tmp_accept_m2_11_requirement),
        (SELECT max(requirement_sequence) FROM tmp_accept_m2_11_requirement);
    END IF;

    IF v_pass<>45 OR v_fail<>0 THEN
      RAISE EXCEPTION 'Program 217 acceptance prerequisites failed: pass %, fail %. %',
        v_pass,v_fail,coalesce(v_failed,'<NO FAILURE DETAIL>');
    END IF;
END;
$m211_acceptance_requirement_guard$;

/* ============================================================================
Section 6 — Persist only formal acceptance evidence and lifecycle
============================================================================ */
INSERT INTO msbf_ctl.acceptance_gate_result
(
    run_id,gate_id,review_version,result_status,observed_value,threshold_value,
    finding,residual_limitation,reviewer_role
)
SELECT
    c.run_id,
    'M2_11_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION',
    1,
    'PASS',
    c.combined_set_hash,
    '45/45 acceptance prerequisites; 120/120 positive; 20/20 negative; 19 canonical families; 19,298 canonical entities; exact source lineage, baseline replay, stress, latest/archive, hashes, and boundaries',
    'M2.11 finite governed strategy simulation accepted for synthetic governance consumption.',
    'Synthetic deterministic comparative evidence only. The 59 accepted scenario-account rows comprise 44 BASELINE and 15 RECESSION_ENERGY records and do not support production optimization, causal uplift, autonomous deployment, Module 2 closure, or Module 3 authorization.',
    'Independent Validation / Project Owner'
FROM tmp_accept_m2_11_context c;

DO $m211_acceptance_gate_insert_guard$
DECLARE
    v_rows bigint;
BEGIN
    SELECT count(*) INTO v_rows
    FROM msbf_ctl.acceptance_gate_result
    WHERE run_id=(SELECT run_id FROM tmp_accept_m2_11_context)
      AND gate_id='M2_11_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION'
      AND review_version=1
      AND result_status='PASS';
    IF v_rows<>1 THEN
      RAISE EXCEPTION 'Program 217 expected exactly one PASS acceptance-gate row; found %',v_rows;
    END IF;
END;
$m211_acceptance_gate_insert_guard$;

INSERT INTO msbf_ctl.run_evidence
(
    run_id,evidence_code,segment_key,metric_name,
    metric_value_numeric,metric_value_text,unit_code,status,interpretation
)
SELECT
    c.run_id,
    'M2_11_ACCEPTANCE_SUMMARY',
    'PORTFOLIO',
    'M2_11_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_ACCEPTANCE',
    NULL::numeric(24,10),
    c.combined_set_hash,
    'ACCEPTANCE',
    'PASS',
    'Formal M2.11 acceptance after 45/45 prerequisites, 120 positive controls, 20 isolated negative controls, exact five-source lineage, baseline replay, nineteen ordered canonical hashes, 19,298 canonical entities, zero stress-improvement violations, exact latest/archive reproduction, and zero prohibited production or stage-boundary behavior. Frontier position and governance-review priority remain analytical evidence and do not authorize deployment.'
FROM tmp_accept_m2_11_context c;

DO $m211_acceptance_evidence_insert_guard$
DECLARE
    v_rows bigint;
BEGIN
    SELECT count(*) INTO v_rows
    FROM msbf_ctl.run_evidence
    WHERE run_id=(SELECT run_id FROM tmp_accept_m2_11_context)
      AND evidence_code='M2_11_ACCEPTANCE_SUMMARY'
      AND segment_key='PORTFOLIO'
      AND status='PASS';
    IF v_rows<>1 THEN
      RAISE EXCEPTION 'Program 217 expected exactly one acceptance evidence row; found %',v_rows;
    END IF;
END;
$m211_acceptance_evidence_insert_guard$;

UPDATE msbf_ctl.m2_11_portfolio_strategy_contract_registry
SET contract_status='ACCEPTED',
    accepted_at=clock_timestamp()
WHERE module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context)
  AND contract_version=1
  AND contract_status='VALIDATED'
  AND validated_at IS NOT NULL
  AND accepted_at IS NULL;

DO $m211_acceptance_registry_update_guard$
DECLARE
    v_rows bigint;
BEGIN
    SELECT count(*) INTO v_rows
    FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry
    WHERE module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context)
      AND contract_version=1
      AND contract_status='ACCEPTED'
      AND accepted_at IS NOT NULL;
    IF v_rows<>1 THEN
      RAISE EXCEPTION 'Program 217 registry acceptance update expected one accepted row; found %',v_rows;
    END IF;
END;
$m211_acceptance_registry_update_guard$;

UPDATE msbf_ctl.run_registry
SET run_status='M2_11_ACCEPTED'
WHERE run_id=(SELECT run_id FROM tmp_accept_m2_11_context)
  AND run_status='M2_11_VALIDATED';

DO $m211_acceptance_run_update_guard$
DECLARE
    v_rows bigint;
BEGIN
    SELECT count(*) INTO v_rows
    FROM msbf_ctl.run_registry
    WHERE run_id=(SELECT run_id FROM tmp_accept_m2_11_context)
      AND run_status='M2_11_ACCEPTED';
    IF v_rows<>1 THEN
      RAISE EXCEPTION 'Program 217 run acceptance update expected one accepted row; found %',v_rows;
    END IF;
END;
$m211_acceptance_run_update_guard$;

/* ============================================================================
Section 7 — Post-write immutable-state and final-lifecycle reconciliation
============================================================================ */
CREATE TEMP TABLE tmp_accept_m2_11_immutable_checkpoint_after ON COMMIT DROP AS
SELECT
    c.module1_run_id,
    c.row_hash AS registry_row_hash,
    c.combined_set_hash,
    c.contract_set_hash,
    c.latest_set_hash,
    c.archive_set_hash,
    (SELECT count(*) FROM msbf_m2.portfolio_strategy_simulation_latest l
      WHERE l.module1_run_id=c.module1_run_id) AS latest_rows,
    (SELECT count(*) FROM msbf_m2.portfolio_strategy_simulation_archive a
      WHERE a.module1_run_id=c.module1_run_id AND a.contract_version=1) AS archive_rows
FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry c
WHERE c.module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context)
  AND c.contract_version=1;

DO $m211_acceptance_final_guard$
DECLARE
    v_run_status text;
    v_contract_status text;
    v_gate_status text;
    v_acceptance_rows bigint;
    v_checkpoint_changes bigint;
BEGIN
    SELECT run_status INTO v_run_status
    FROM msbf_ctl.run_registry
    WHERE run_id=(SELECT run_id FROM tmp_accept_m2_11_context);

    SELECT contract_status INTO v_contract_status
    FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry
    WHERE module1_run_id=(SELECT run_id FROM tmp_accept_m2_11_context)
      AND contract_version=1;

    SELECT result_status INTO v_gate_status
    FROM msbf_ctl.acceptance_gate_result
    WHERE run_id=(SELECT run_id FROM tmp_accept_m2_11_context)
      AND gate_id='M2_11_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION'
      AND review_version=1;

    SELECT count(*) INTO v_acceptance_rows
    FROM msbf_ctl.run_evidence
    WHERE run_id=(SELECT run_id FROM tmp_accept_m2_11_context)
      AND evidence_code='M2_11_ACCEPTANCE_SUMMARY'
      AND status='PASS';

    SELECT count(*) INTO v_checkpoint_changes
    FROM tmp_accept_m2_11_immutable_checkpoint_before b
    FULL JOIN tmp_accept_m2_11_immutable_checkpoint_after a
      USING(module1_run_id)
    WHERE b.module1_run_id IS NULL OR a.module1_run_id IS NULL
       OR (b.registry_row_hash,b.combined_set_hash,b.contract_set_hash,
           b.latest_set_hash,b.archive_set_hash,b.latest_rows,b.archive_rows)
          IS DISTINCT FROM
          (a.registry_row_hash,a.combined_set_hash,a.contract_set_hash,
           a.latest_set_hash,a.archive_set_hash,a.latest_rows,a.archive_rows);

    IF v_run_status<>'M2_11_ACCEPTED'
       OR v_contract_status<>'ACCEPTED'
       OR v_gate_status<>'PASS'
       OR v_acceptance_rows<>1
       OR v_checkpoint_changes<>0 THEN
      RAISE EXCEPTION
       'Program 217 final state failed: run %, contract %, gate %, acceptance rows %, immutable checkpoint changes %',
       v_run_status,v_contract_status,v_gate_status,v_acceptance_rows,v_checkpoint_changes;
    END IF;
END;
$m211_acceptance_final_guard$;

CREATE TEMP TABLE tmp_accept_m2_11_result ON COMMIT PRESERVE ROWS AS
SELECT
    c.run_id,
    c.run_code,
    c.run_version,
    r.run_status AS final_run_status,
    reg.contract_status AS final_contract_status,
    g.result_status AS acceptance_gate_status,
    reg.accepted_at,
    reg.combined_set_hash,
    (SELECT count(*) FROM tmp_accept_m2_11_requirement) AS acceptance_requirements,
    (SELECT count(*) FROM tmp_accept_m2_11_requirement WHERE status='PASS') AS acceptance_requirements_passed,
    (SELECT positive_pass_rows FROM tmp_accept_m2_11_evidence_summary) AS positive_controls_passed,
    (SELECT negative_pass_rows FROM tmp_accept_m2_11_evidence_summary) AS negative_controls_passed,
    reg.canonical_entities,
    'ACCEPTED_FOR_SYNTHETIC_GOVERNANCE_CONSUMPTION'::text AS acceptance_scope,
    'NOT_AUTHORIZED'::text AS deployment_authorization_status,
    'M2_12_REQUIRED'::text AS module2_closure_status,
    'NOT_AUTHORIZED'::text AS module3_authorization_status,
    'PASS'::text AS acceptance_status
FROM tmp_accept_m2_11_context c
JOIN msbf_ctl.run_registry r ON r.run_id=c.run_id
JOIN msbf_ctl.m2_11_portfolio_strategy_contract_registry reg
  ON reg.module1_run_id=c.run_id AND reg.contract_version=1
JOIN msbf_ctl.acceptance_gate_result g
  ON g.run_id=c.run_id
 AND g.gate_id='M2_11_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION'
 AND g.review_version=1;

COMMIT;

SELECT
    run_id,run_code,run_version,final_run_status,final_contract_status,
    acceptance_gate_status,accepted_at,combined_set_hash,
    acceptance_requirements,acceptance_requirements_passed,
    positive_controls_passed,negative_controls_passed,canonical_entities,
    acceptance_scope,deployment_authorization_status,module2_closure_status,
    module3_authorization_status,acceptance_status
FROM tmp_accept_m2_11_result;
