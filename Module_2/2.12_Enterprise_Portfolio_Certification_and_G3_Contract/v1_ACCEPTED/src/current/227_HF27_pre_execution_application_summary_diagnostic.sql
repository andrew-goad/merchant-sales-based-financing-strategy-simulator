/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.12 — Enterprise Portfolio Certification & Consumption Contract

Diagnostic  : 227_HF27_pre_execution_application_summary_diagnostic.sql
Revision    : HF27
Purpose     : Reconstruct Result Set 10 directly from the accepted application
              consumption view, prove the COMPLETE/PARTIAL/BLOCKED evidence
              domain, preserve legitimate BLOCKED counts as reportable data,
              and emit only three read-only evidence grids.

Persistent-state boundary
-------------------------
PERSISTENT-STATE READ ONLY. The transaction remains write-capable only so PostgreSQL can create and populate temporary relations; the source contains no persistent mutation and ends with ROLLBACK.
============================================================================ */
BEGIN;
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SET LOCAL search_path = pg_catalog, msbf_ctl, msbf_m1, msbf_m2;
SET LOCAL lock_timeout = '15s';
SET LOCAL statement_timeout = '30min';
SET LOCAL idle_in_transaction_session_timeout = '0';
SET LOCAL jit = off;

CREATE TEMP TABLE tmp_p227_hf27_app_context ON COMMIT DROP AS
SELECT rr.run_id::bigint AS module1_run_id,
       rr.run_code::text AS run_code,
       rr.run_version::integer AS run_version,
       rr.run_status::text AS run_status,
       r.bundle_code::text AS bundle_code,
       r.contract_version::integer AS contract_version,
       r.contract_status::text AS contract_status
  FROM msbf_ctl.run_registry rr
  JOIN msbf_ctl.m2_12_g3_bundle_registry r
    ON r.module1_run_id=rr.run_id
   AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE'
   AND r.contract_version=1
   AND r.contract_status='ACCEPTED'
 WHERE rr.run_code='M1_V0_2_BASELINE_BUILD'
   AND rr.run_version=1
   AND rr.run_status='M2_12_ACCEPTED';

DO $m212_p227_hf27_app_context_gate$
DECLARE v_rows integer;
BEGIN
  SELECT count(*) INTO v_rows FROM tmp_p227_hf27_app_context;
  IF v_rows<>1 THEN
    RAISE EXCEPTION USING ERRCODE='P0001',
      MESSAGE='Program 227 HF27 application-summary diagnostic requires one accepted context',
      DETAIL='observed='||v_rows::text;
  END IF;
END;
$m212_p227_hf27_app_context_gate$;

CREATE TEMP TABLE tmp_p227_hf27_application_summary ON COMMIT PRESERVE ROWS AS
WITH scopes(reporting_scope_rank,reporting_scope_code,expected_rows,expected_distinct_applications) AS
(
  VALUES
    (1,'BASELINE'::text,750::bigint,750::bigint),
    (2,'RECESSION_ENERGY'::text,750::bigint,750::bigint),
    (3,'ALL'::text,1500::bigint,750::bigint)
),
base AS
(
  SELECT a.module1_run_id,a.scenario_code,a.merchant_application_id,a.merchant_id,
         a.m1_15_contract_row_hash,a.m1_16_contract_row_hash,a.m2_1_source_g2_combined_hash,
         a.m2_1_contract_row_hash,a.m2_2_request_contract_row_hash,a.m2_2_pricing_contract_row_hash,
         a.m2_3_contract_row_hash,a.m2_4_contract_row_hash,a.evidence_status
    FROM msbf_m2.v_m2_12_application_origination_consumption a
    JOIN tmp_p227_hf27_app_context c ON c.module1_run_id=a.module1_run_id
),
observed AS
(
  SELECT s.reporting_scope_rank,s.reporting_scope_code,s.expected_rows,s.expected_distinct_applications,
         count(v.module1_run_id)::bigint AS row_count,
         count(DISTINCT v.merchant_application_id)::bigint AS distinct_application_count,
         count(v.module1_run_id) FILTER (WHERE v.merchant_application_id IS NULL OR v.merchant_id IS NULL)::bigint AS orphan_count,
         (count(v.module1_run_id)-count(DISTINCT (v.scenario_code,v.merchant_application_id)))::bigint AS multiplicity_error_count,
         count(DISTINCT concat_ws('|',v.m1_15_contract_row_hash,v.m1_16_contract_row_hash,v.m2_1_source_g2_combined_hash,
                                      v.m2_1_contract_row_hash,v.m2_2_request_contract_row_hash,v.m2_2_pricing_contract_row_hash,
                                      v.m2_3_contract_row_hash,v.m2_4_contract_row_hash))::integer AS source_contract_count,
         count(v.module1_run_id) FILTER (WHERE v.evidence_status='COMPLETE')::bigint AS complete_evidence_count,
         count(v.module1_run_id) FILTER (WHERE v.evidence_status='PARTIAL')::bigint AS partial_evidence_count,
         count(v.module1_run_id) FILTER (WHERE v.evidence_status='BLOCKED')::bigint AS blocked_evidence_count,
         count(v.module1_run_id) FILTER (WHERE v.evidence_status IS NULL OR v.evidence_status NOT IN ('COMPLETE','PARTIAL','BLOCKED'))::bigint AS invalid_evidence_status_count,
         count(v.module1_run_id) FILTER (WHERE v.m1_15_contract_row_hash IS NULL
                                         OR v.m1_16_contract_row_hash IS NULL
                                         OR v.m2_1_source_g2_combined_hash IS NULL
                                         OR v.m2_1_contract_row_hash IS NULL
                                         OR v.m2_2_request_contract_row_hash IS NULL
                                         OR v.m2_2_pricing_contract_row_hash IS NULL
                                         OR v.m2_3_contract_row_hash IS NULL
                                         OR v.m2_4_contract_row_hash IS NULL)::bigint AS missing_lineage_count
    FROM scopes s
    LEFT JOIN base v
      ON s.reporting_scope_code='ALL' OR v.scenario_code=s.reporting_scope_code
   GROUP BY s.reporting_scope_rank,s.reporting_scope_code,s.expected_rows,s.expected_distinct_applications
)
SELECT o.*,
       CASE WHEN o.row_count=o.expected_rows
                  AND o.distinct_application_count=o.expected_distinct_applications
                  AND o.orphan_count=0
                  AND o.multiplicity_error_count=0
                  AND o.invalid_evidence_status_count=0
                  AND o.missing_lineage_count=0
                  AND o.complete_evidence_count+o.partial_evidence_count+o.blocked_evidence_count=o.row_count
                  AND o.source_contract_count>0
                  AND o.source_contract_count<=o.row_count
            THEN 'PASS' ELSE 'FAIL' END::text AS scope_status
  FROM observed o;

CREATE TEMP TABLE tmp_p227_hf27_application_summary_failures ON COMMIT PRESERVE ROWS AS
SELECT *
  FROM tmp_p227_hf27_application_summary
 WHERE scope_status<>'PASS';

CREATE TEMP TABLE tmp_p227_hf27_application_summary_diagnostic_summary ON COMMIT PRESERVE ROWS AS
SELECT count(*)::integer AS scope_rows,
       count(*) FILTER (WHERE scope_status='PASS')::integer AS scope_pass_rows,
       count(*) FILTER (WHERE scope_status<>'PASS')::integer AS failure_rows,
       coalesce(sum(row_count),0)::bigint AS scope_row_count_sum,
       coalesce(sum(complete_evidence_count),0)::bigint AS complete_evidence_count_sum,
       coalesce(sum(partial_evidence_count),0)::bigint AS partial_evidence_count_sum,
       coalesce(sum(blocked_evidence_count),0)::bigint AS blocked_evidence_count_sum,
       coalesce(sum(invalid_evidence_status_count),0)::bigint AS invalid_evidence_status_count_sum,
       coalesce(sum(missing_lineage_count),0)::bigint AS missing_lineage_count_sum,
       CASE WHEN count(*)=3
                  AND count(*) FILTER (WHERE scope_status='PASS')=3
                  AND count(*) FILTER (WHERE scope_status<>'PASS')=0
            THEN 'PASS' ELSE 'FAIL' END::text AS diagnostic_status,
       CASE WHEN count(*)=3
                  AND count(*) FILTER (WHERE scope_status='PASS')=3
                  AND count(*) FILTER (WHERE scope_status<>'PASS')=0
            THEN 'READY_TO_EXECUTE_PROGRAM_227_HF26'
            ELSE 'STOP_PROGRAM_227_HF26' END::text AS disposition
  FROM tmp_p227_hf27_application_summary;

/* GRID 1 — Three reporting-scope rows, including the legitimate evidence-status distribution. */
SELECT reporting_scope_code,expected_rows,row_count,expected_distinct_applications,distinct_application_count,
       orphan_count,multiplicity_error_count,source_contract_count,
       complete_evidence_count,partial_evidence_count,blocked_evidence_count,
       invalid_evidence_status_count,missing_lineage_count,scope_status
  FROM tmp_p227_hf27_application_summary
 ORDER BY reporting_scope_rank;

/* GRID 2 — Header-only on success. */
SELECT reporting_scope_code,expected_rows,row_count,expected_distinct_applications,distinct_application_count,
       orphan_count,multiplicity_error_count,source_contract_count,
       complete_evidence_count,partial_evidence_count,blocked_evidence_count,
       invalid_evidence_status_count,missing_lineage_count,scope_status
  FROM tmp_p227_hf27_application_summary_failures
 ORDER BY reporting_scope_rank;

/* GRID 3 — One-row diagnostic summary. */
SELECT scope_rows,scope_pass_rows,failure_rows,scope_row_count_sum,
       complete_evidence_count_sum,partial_evidence_count_sum,blocked_evidence_count_sum,
       invalid_evidence_status_count_sum,missing_lineage_count_sum,
       diagnostic_status,disposition
  FROM tmp_p227_hf27_application_summary_diagnostic_summary;

ROLLBACK;
