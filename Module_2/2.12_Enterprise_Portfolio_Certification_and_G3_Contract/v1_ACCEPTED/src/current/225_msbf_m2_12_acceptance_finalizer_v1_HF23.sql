    /* ============================================================================
    Merchant Sales-Based Financing Strategy Simulator
    Module 2.12 — Enterprise Portfolio Certification & Consumption Contract

    Program     : 225_msbf_m2_12_acceptance_finalizer_v1_HF23.sql
    Version     : HF23
    Work package: M2.12 Work Package 4
    Source state: BOUNDED LIVE-EXECUTION CONTINUATION — NOT EXECUTED HERE

    Purpose
    -------
    Fail closed unless all forty-seven frozen pre-write acceptance requirements
reconstruct from persisted state; then atomically write the one G3 gate row,
one acceptance-evidence row, and the two mutable acceptance lifecycle fields.
Requirement 048 proves post-write atomicity and immutable-state preservation.

    Mutation boundary
    -----------------
    Permitted persistent writes are limited to one G3_M2_CONTRACT gate result,
one M2_12_ACCEPTANCE_SUMMARY evidence row, m2_12_g3_bundle_registry
contract_status/accepted_at/updated_at, and run_registry.run_status. No canonical
business field, row hash, set hash, latest/archive row, or owned sequence may change.

    Required starting state
    -----------------------
    run_status=M2_12_VALIDATED; registry=VALIDATED; 128/128 positive PASS;
20/20 negative PASS; 24/24 generation PASS; no prior G3 acceptance rows.

    Required ending state
    ---------------------
    run_status=M2_12_ACCEPTED; registry=ACCEPTED; one G3 gate PASS; one
acceptance summary PASS; 48/48 requirements PASS; immutable fingerprint exact.

    Execution boundary
    ------------------
    Controlled live execution remains one-program-at-a-time and conditional on
    exact Program 224 evidence. HF23 corrects Requirements 027 and 045,
    suppresses intermediate requirement result grids, and retains all accepted write authorities.
    First-error-stop behavior must be configured in
    the database client; this file contains no psql meta-commands.
    ============================================================================ */
BEGIN;
SET LOCAL search_path = pg_catalog, msbf_ctl, msbf_m1, msbf_m2;
SET LOCAL work_mem = '256MB';
SET LOCAL lock_timeout = '15s';
SET LOCAL statement_timeout = '75min';
SET LOCAL idle_in_transaction_session_timeout = '0';
SET LOCAL jit = off;
/* Phase 1 — lock and establish the single validated acceptance context. */
DO $m212_p225_hf15_lock$
DECLARE
    v_run_id bigint;
    v_registry_id bigint;
    v_run_status text;
    v_contract_status text;
BEGIN
    BEGIN
        SELECT rr.run_id,
               r.registry_id,
               rr.run_status,
               r.contract_status
          INTO STRICT v_run_id,
                      v_registry_id,
                      v_run_status,
                      v_contract_status
          FROM msbf_ctl.run_registry rr
          JOIN msbf_ctl.m2_12_g3_bundle_registry r
            ON r.module1_run_id=rr.run_id
           AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE'
           AND r.contract_version=1
         WHERE rr.run_code='M1_V0_2_BASELINE_BUILD'
           AND rr.run_version=1
           AND rr.run_status='M2_12_VALIDATED'
           AND r.contract_status='VALIDATED'
           AND r.generated_at IS NOT NULL
           AND r.validated_at IS NOT NULL
           AND r.accepted_at IS NULL
         FOR UPDATE OF rr,r;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE EXCEPTION USING ERRCODE='P0001',
              MESSAGE='Program 225 HF23 requires one exact M2_12_VALIDATED/VALIDATED governed context',
              DETAIL='observed_rows=0 or lifecycle/timestamp identity mismatch';
        WHEN TOO_MANY_ROWS THEN
            RAISE EXCEPTION USING ERRCODE='P0001',
              MESSAGE='Program 225 HF23 requires one exact M2_12_VALIDATED/VALIDATED governed context',
              DETAIL='observed_rows>1';
    END;
END;
$m212_p225_hf15_lock$;

CREATE TEMP TABLE tmp_accept_m2_12_context ON COMMIT PRESERVE ROWS AS
SELECT rr.run_id::bigint AS module1_run_id,
       rr.run_code::text AS run_code,
       rr.run_version::integer AS run_version,
       rr.run_status::text AS run_status,
       rr.as_of_date::date AS as_of_date,
       r.registry_id::bigint AS registry_id,
       r.bundle_code::text AS bundle_code,
       r.contract_version::integer AS contract_version,
       r.schema_version::text AS schema_version,
       r.methodology_version::text AS methodology_version,
       r.acceptance_gate_id::text AS acceptance_gate_id,
       r.contract_status::text AS contract_status,
       r.row_hash::text AS registry_row_hash,
       r.contract_set_hash::text AS contract_set_hash,
       r.combined_set_hash::text AS combined_set_hash
  FROM msbf_ctl.run_registry rr
  JOIN msbf_ctl.m2_12_g3_bundle_registry r
    ON r.module1_run_id=rr.run_id
   AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE'
   AND r.contract_version=1
 WHERE rr.run_code='M1_V0_2_BASELINE_BUILD'
   AND rr.run_version=1
   AND rr.run_status='M2_12_VALIDATED'
   AND r.contract_status='VALIDATED'
   AND r.generated_at IS NOT NULL
   AND r.validated_at IS NOT NULL
   AND r.accepted_at IS NULL;
CREATE UNIQUE INDEX ux_tmp_accept_m2_12_context ON tmp_accept_m2_12_context(module1_run_id);
ANALYZE tmp_accept_m2_12_context;

DO $m212_p225_hf15_pristine_acceptance_state$
DECLARE
    v_context integer;
    v_gate integer;
    v_evidence integer;
BEGIN
    SELECT count(*) INTO v_context FROM tmp_accept_m2_12_context;
    SELECT count(*) INTO v_gate
      FROM msbf_ctl.acceptance_gate_result g
      JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=g.run_id
     WHERE g.gate_id='G3_M2_CONTRACT' AND g.review_version=1;
    SELECT count(*) INTO v_evidence
      FROM msbf_ctl.run_evidence e
      JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=e.run_id
     WHERE e.evidence_code='M2_12_ACCEPTANCE_SUMMARY';
    IF v_context<>1 OR v_gate<>0 OR v_evidence<>0 THEN
        RAISE EXCEPTION USING ERRCODE='P0001',
          MESSAGE='Program 225 HF23 requires a pristine G3 acceptance-write boundary',
          DETAIL=format('context=%s prior_gate=%s prior_acceptance_evidence=%s',v_context,v_gate,v_evidence);
    END IF;
END;
$m212_p225_hf15_pristine_acceptance_state$;
CREATE TEMP TABLE tmp_accept_m2_12_capability_authority
(
    capability_sequence smallint PRIMARY KEY,
    capability_code text NOT NULL UNIQUE,
    coverage_status_code text NOT NULL,
    certifying_stage_code text NOT NULL,
    claim_boundary text NOT NULL,
    production_action_authorized_flag boolean NOT NULL,
    legal_or_regulatory_certified_flag boolean NOT NULL,
    notes text NOT NULL
) ON COMMIT DROP;
INSERT INTO tmp_accept_m2_12_capability_authority VALUES
(1::smallint,'M1_G2_APPLICATION_RISK_FOUNDATION'::text,'IMPLEMENTED_CERTIFIED'::text,'M1_17_G2_FOUNDATION'::text,'Accepted application, risk, economics, acquisition, evidence, and scenario foundation.'::text,false::boolean,false::boolean,'Module 2 source boundary'::text),
(2::smallint,'ELIGIBILITY_POLICY_ROUTING'::text,'IMPLEMENTED_CERTIFIED'::text,'M2_1_ELIGIBILITY_ROUTING'::text,'Governed eligibility gates, policy results, reasons, and routing outcomes.'::text,false::boolean,false::boolean,'As-built accepted scope'::text),
(3::smallint,'PRICING_STRUCTURE_COUNTEROFFER'::text,'IMPLEMENTED_CERTIFIED'::text,'M2_2_PRICING_STRUCTURE'::text,'Accepted request structures, finite pricing candidates, counteroffer foundations, and scenario results.'::text,false::boolean,false::boolean,'As-built accepted scope'::text),
(4::smallint,'FINAL_OFFER_DECISION_AUTHORIZATION'::text,'IMPLEMENTED_CERTIFIED_SYNTHETIC'::text,'M2_3_FINAL_DECISION'::text,'Synthetic final offer and decision authorization evidence only.'::text,false::boolean,false::boolean,'Not a production credit decision'::text),
(5::smallint,'BOOKING_FUNDING_PORTFOLIO_ACTIVATION'::text,'IMPLEMENTED_BOUNDED_SYNTHETIC'::text,'M2_4_PORTFOLIO_ACTIVATION'::text,'Synthetic booking, funding, account, advance, and portfolio activation records.'::text,false::boolean,false::boolean,'No real booking or funds movement'::text),
(6::smallint,'DAILY_REMITTANCE_EXPOSURE_MONITORING'::text,'IMPLEMENTED_BOUNDED_SYNTHETIC'::text,'M2_5_DAILY_MONITORING'::text,'Synthetic daily remittance, exposure, monitoring, alert, and portfolio summaries.'::text,false::boolean,false::boolean,'No production ledger or processor execution'::text),
(7::smallint,'EARLY_WARNING_INTERVENTION_SERVICING'::text,'IMPLEMENTED_BOUNDED_RECOMMENDATION'::text,'M2_6_INTERVENTION_STRATEGY'::text,'Synthetic early-warning and servicing-action recommendations.'::text,false::boolean,false::boolean,'Recommendation evidence only'::text),
(8::smallint,'OPERATIONAL_ACTIVATION_ACCOUNT_SETUP'::text,'IMPLEMENTED_BOUNDED_SYNTHETIC'::text,'M2_7_OPERATIONAL_ACTIVATION'::text,'Synthetic operational account setup and reassessment evidence.'::text,false::boolean,false::boolean,'No external system update'::text),
(9::smallint,'SERVICING_PAYMENT_LIFECYCLE_SIMULATION'::text,'IMPLEMENTED_BOUNDED_SYNTHETIC'::text,'M2_8_SERVICING_EXECUTION'::text,'Synthetic payment-processing events and lifecycle transitions.'::text,false::boolean,false::boolean,'No payment-network or bank-account activity'::text),
(10::smallint,'PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION'::text,'IMPLEMENTED_CERTIFIED_SYNTHETIC'::text,'M2_9_RECONCILIATION_CERTIFICATION'::text,'Reconciled synthetic payment evidence and certified synthetic account states.'::text,false::boolean,false::boolean,'Not production accounting certification'::text),
(11::smallint,'PORTFOLIO_KPI_SERVICING_ANALYTICS'::text,'IMPLEMENTED_CERTIFIED_ANALYTICS'::text,'M2_10_PORTFOLIO_ANALYTICS'::text,'Governed KPI, performance-tier, servicing-queue, exposure, payment, and exception analytics.'::text,false::boolean,false::boolean,'Synthetic analytics only'::text),
(12::smallint,'PORTFOLIO_STRATEGY_FRONTIER'::text,'IMPLEMENTED_CERTIFIED_COMPARATIVE'::text,'M2_11_STRATEGY_SIMULATION'::text,'Finite deterministic strategy comparison, Pareto frontier, and governance-review priority evidence.'::text,false::boolean,false::boolean,'Not a champion or deployment decision'::text),
(13::smallint,'COLLATERAL_GUARANTEE_PACKAGE'::text,'DEFERRED_NOT_IMPLEMENTED'::text,'NONE'::text,'Original charter capability not implemented in the accepted M2.1-M2.11 chain.'::text,false::boolean,false::boolean,'Requires separate future design and data'::text),
(14::smallint,'COVENANT_PACKAGE_AND_TESTING'::text,'DEFERRED_NOT_IMPLEMENTED'::text,'NONE'::text,'Original charter capability not implemented as a governed covenant package or test framework.'::text,false::boolean,false::boolean,'Requires separate future lifecycle design'::text),
(15::smallint,'REGULATORY_APPLICABILITY_LEGAL_COMPLIANCE'::text,'DEFERRED_NOT_CERTIFIED'::text,'NONE'::text,'No jurisdiction, licensing, disclosure, legal-form, UDAAP, fair-lending, or regulatory applicability certification.'::text,false::boolean,false::boolean,'Legal/compliance review required before production'::text),
(16::smallint,'PORTFOLIO_FUNDING_BUDGET_ALLOCATION'::text,'DEFERRED_NOT_IMPLEMENTED'::text,'NONE'::text,'No production funding-budget, capital-allocation, or concentration-allocation engine.'::text,false::boolean,false::boolean,'Strategy exposure comparisons are not allocation authority'::text),
(17::smallint,'PRODUCTION_DECISION_ACCOUNT_PAYMENT_EXECUTION'::text,'PROHIBITED_NOT_AUTHORIZED'::text,'NONE'::text,'No production decision, account creation, payment instruction, processor call, or funds movement.'::text,false::boolean,false::boolean,'Production execution expressly prohibited'::text),
(18::smallint,'ACCOUNTING_CECL_CAPITAL_TREASURY'::text,'DEFERRED_NOT_CERTIFIED'::text,'NONE'::text,'No GAAP accounting, CECL reserve, economic capital, regulatory capital, or treasury certification.'::text,false::boolean,false::boolean,'Comparative expected loss and contribution are synthetic'::text),
(19::smallint,'EMPIRICAL_CAUSAL_OPTIMIZATION_CHAMPION'::text,'NOT_SUPPORTED_NOT_AUTHORIZED'::text,'NONE'::text,'No causal uplift, calibrated treatment effect, autonomous optimization, production champion, or statistical generalization.'::text,false::boolean,false::boolean,'M2.11 priority is governance review only'::text),
(20::smallint,'CUSTOMER_MERCHANT_NOTICE_ADVERSE_ACTION'::text,'PROHIBITED_NOT_AUTHORIZED'::text,'NONE'::text,'No merchant-facing offer, notice, adverse-action communication, collection notice, or legal communication.'::text,false::boolean,false::boolean,'Synthetic reason evidence is not customer communication'::text);
ANALYZE tmp_accept_m2_12_capability_authority;

CREATE TEMP TABLE tmp_accept_m2_12_source_edges ON COMMIT DROP AS
(SELECT x.module1_run_id,
       x.edge_sequence,
       x.edge_code,
       x.target_node_code,
       x.expected_source_hash,
       x.observed_accepted_source_hash,
       x.observed_target_recorded_source_hash,
       x.source_gate_status,
       x.source_registry_row_count,
       x.target_registry_row_count,
       (x.observed_accepted_source_hash IS DISTINCT FROM x.expected_source_hash) AS source_hash_mismatch_flag,
       (x.observed_target_recorded_source_hash IS DISTINCT FROM x.expected_source_hash) AS target_hash_mismatch_flag,
       CASE WHEN x.source_registry_row_count=1
                  AND x.target_registry_row_count=1
                  AND x.source_gate_status='PASS'
                  AND x.observed_accepted_source_hash=x.expected_source_hash
                  AND x.observed_target_recorded_source_hash=x.expected_source_hash
            THEN 'PASS'::text ELSE 'FAIL'::text END AS edge_status
FROM (
SELECT ctx.module1_run_id,
       1::smallint AS edge_sequence,
       'M1_15_TO_M1_17_APPLICATION_CONTRACT'::text AS edge_code,
       'M1_17_G2_FOUNDATION'::text AS target_node_code,
       'fcd2704e17ec0d2e73191ea36061d74b'::text AS expected_source_hash,
       ((SELECT src.combined_set_hash::text FROM msbf_ctl.m1_15_consumption_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_code='M1_APPLICATION_CONSUMPTION' AND src.contract_version=1 AND src.contract_status='ACCEPTED'))::text AS observed_accepted_source_hash,
       ((SELECT tgt.source_m1_15_combined_hash::text FROM msbf_ctl.m1_17_g2_bundle_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.bundle_code='M1_G2_CONSUMPTION_BUNDLE' AND tgt.bundle_version=1 AND tgt.bundle_status='ACCEPTED'))::text AS observed_target_recorded_source_hash,
       ((SELECT agr.result_status::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='M1_15_CONSUMPTION_CONTRACT' AND agr.review_version=1))::text AS source_gate_status,
       (SELECT count(*)::bigint FROM (SELECT src.combined_set_hash::text FROM msbf_ctl.m1_15_consumption_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_code='M1_APPLICATION_CONSUMPTION' AND src.contract_version=1 AND src.contract_status='ACCEPTED') src_count) AS source_registry_row_count,
       (SELECT count(*)::bigint FROM (SELECT tgt.source_m1_15_combined_hash::text FROM msbf_ctl.m1_17_g2_bundle_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.bundle_code='M1_G2_CONSUMPTION_BUNDLE' AND tgt.bundle_version=1 AND tgt.bundle_status='ACCEPTED') tgt_count) AS target_registry_row_count
FROM tmp_accept_m2_12_context ctx
) x)
UNION ALL
(SELECT x.module1_run_id,
       x.edge_sequence,
       x.edge_code,
       x.target_node_code,
       x.expected_source_hash,
       x.observed_accepted_source_hash,
       x.observed_target_recorded_source_hash,
       x.source_gate_status,
       x.source_registry_row_count,
       x.target_registry_row_count,
       (x.observed_accepted_source_hash IS DISTINCT FROM x.expected_source_hash) AS source_hash_mismatch_flag,
       (x.observed_target_recorded_source_hash IS DISTINCT FROM x.expected_source_hash) AS target_hash_mismatch_flag,
       CASE WHEN x.source_registry_row_count=1
                  AND x.target_registry_row_count=1
                  AND x.source_gate_status='PASS'
                  AND x.observed_accepted_source_hash=x.expected_source_hash
                  AND x.observed_target_recorded_source_hash=x.expected_source_hash
            THEN 'PASS'::text ELSE 'FAIL'::text END AS edge_status
FROM (
SELECT ctx.module1_run_id,
       2::smallint AS edge_sequence,
       'M1_16_TO_M1_17_ACQUISITION_CONTRACT'::text AS edge_code,
       'M1_17_G2_FOUNDATION'::text AS target_node_code,
       '86df51a0ca68d84096d00ff0f1b19f33'::text AS expected_source_hash,
       ((SELECT src.combined_set_hash::text FROM msbf_ctl.m1_16_acquisition_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_code='M1_ACQUISITION_CONSUMPTION' AND src.contract_version=1 AND src.contract_status='ACCEPTED'))::text AS observed_accepted_source_hash,
       ((SELECT tgt.source_m1_16_combined_hash::text FROM msbf_ctl.m1_17_g2_bundle_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.bundle_code='M1_G2_CONSUMPTION_BUNDLE' AND tgt.bundle_version=1 AND tgt.bundle_status='ACCEPTED'))::text AS observed_target_recorded_source_hash,
       ((SELECT agr.result_status::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='M1_16_ACQUISITION_MARKETING_COST_FOUNDATIONS' AND agr.review_version=1))::text AS source_gate_status,
       (SELECT count(*)::bigint FROM (SELECT src.combined_set_hash::text FROM msbf_ctl.m1_16_acquisition_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_code='M1_ACQUISITION_CONSUMPTION' AND src.contract_version=1 AND src.contract_status='ACCEPTED') src_count) AS source_registry_row_count,
       (SELECT count(*)::bigint FROM (SELECT tgt.source_m1_16_combined_hash::text FROM msbf_ctl.m1_17_g2_bundle_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.bundle_code='M1_G2_CONSUMPTION_BUNDLE' AND tgt.bundle_version=1 AND tgt.bundle_status='ACCEPTED') tgt_count) AS target_registry_row_count
FROM tmp_accept_m2_12_context ctx
) x)
UNION ALL
(SELECT x.module1_run_id,
       x.edge_sequence,
       x.edge_code,
       x.target_node_code,
       x.expected_source_hash,
       x.observed_accepted_source_hash,
       x.observed_target_recorded_source_hash,
       x.source_gate_status,
       x.source_registry_row_count,
       x.target_registry_row_count,
       (x.observed_accepted_source_hash IS DISTINCT FROM x.expected_source_hash) AS source_hash_mismatch_flag,
       (x.observed_target_recorded_source_hash IS DISTINCT FROM x.expected_source_hash) AS target_hash_mismatch_flag,
       CASE WHEN x.source_registry_row_count=1
                  AND x.target_registry_row_count=1
                  AND x.source_gate_status='PASS'
                  AND x.observed_accepted_source_hash=x.expected_source_hash
                  AND x.observed_target_recorded_source_hash=x.expected_source_hash
            THEN 'PASS'::text ELSE 'FAIL'::text END AS edge_status
FROM (
SELECT ctx.module1_run_id,
       3::smallint AS edge_sequence,
       'M1_17_TO_M2_1'::text AS edge_code,
       'M2_1_ELIGIBILITY_ROUTING'::text AS target_node_code,
       '7d9e466da28cad2551aa99c4c40c912b'::text AS expected_source_hash,
       ((SELECT src.combined_g2_hash::text FROM msbf_ctl.m1_17_g2_bundle_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.bundle_code='M1_G2_CONSUMPTION_BUNDLE' AND src.bundle_version=1 AND src.bundle_status='ACCEPTED'))::text AS observed_accepted_source_hash,
       ((SELECT tgt.source_g2_combined_hash::text FROM msbf_ctl.m2_1_strategy_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_ELIGIBILITY_ROUTING_CONSUMPTION' AND tgt.contract_version=1 AND tgt.contract_status='ACCEPTED'))::text AS observed_target_recorded_source_hash,
       ((SELECT agr.result_status::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='G2_M1_CONTRACT' AND agr.review_version=1))::text AS source_gate_status,
       (SELECT count(*)::bigint FROM (SELECT src.combined_g2_hash::text FROM msbf_ctl.m1_17_g2_bundle_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.bundle_code='M1_G2_CONSUMPTION_BUNDLE' AND src.bundle_version=1 AND src.bundle_status='ACCEPTED') src_count) AS source_registry_row_count,
       (SELECT count(*)::bigint FROM (SELECT tgt.source_g2_combined_hash::text FROM msbf_ctl.m2_1_strategy_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_ELIGIBILITY_ROUTING_CONSUMPTION' AND tgt.contract_version=1 AND tgt.contract_status='ACCEPTED') tgt_count) AS target_registry_row_count
FROM tmp_accept_m2_12_context ctx
) x)
UNION ALL
(SELECT x.module1_run_id,
       x.edge_sequence,
       x.edge_code,
       x.target_node_code,
       x.expected_source_hash,
       x.observed_accepted_source_hash,
       x.observed_target_recorded_source_hash,
       x.source_gate_status,
       x.source_registry_row_count,
       x.target_registry_row_count,
       (x.observed_accepted_source_hash IS DISTINCT FROM x.expected_source_hash) AS source_hash_mismatch_flag,
       (x.observed_target_recorded_source_hash IS DISTINCT FROM x.expected_source_hash) AS target_hash_mismatch_flag,
       CASE WHEN x.source_registry_row_count=1
                  AND x.target_registry_row_count=1
                  AND x.source_gate_status='PASS'
                  AND x.observed_accepted_source_hash=x.expected_source_hash
                  AND x.observed_target_recorded_source_hash=x.expected_source_hash
            THEN 'PASS'::text ELSE 'FAIL'::text END AS edge_status
FROM (
SELECT ctx.module1_run_id,
       4::smallint AS edge_sequence,
       'M2_1_TO_M2_2'::text AS edge_code,
       'M2_2_PRICING_STRUCTURE'::text AS target_node_code,
       'e5ace7f32060ffb191c7bd0f8dd0c863'::text AS expected_source_hash,
       ((SELECT src.combined_set_hash::text FROM msbf_ctl.m2_1_strategy_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_code='M2_ELIGIBILITY_ROUTING_CONSUMPTION' AND src.contract_version=1 AND src.contract_status='ACCEPTED'))::text AS observed_accepted_source_hash,
       ((SELECT tgt.source_m2_1_combined_hash::text FROM msbf_ctl.m2_2_pricing_structure_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.request_contract_code='M2_REQUEST_STRUCTURE_CONSUMPTION' AND tgt.request_contract_version=1 AND tgt.pricing_contract_code='M2_PRICING_STRUCTURE_CONSUMPTION' AND tgt.pricing_contract_version=1 AND tgt.contract_status='ACCEPTED'))::text AS observed_target_recorded_source_hash,
       ((SELECT agr.result_status::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='M2_1_ELIGIBILITY_POLICY_ROUTING' AND agr.review_version=1))::text AS source_gate_status,
       (SELECT count(*)::bigint FROM (SELECT src.combined_set_hash::text FROM msbf_ctl.m2_1_strategy_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_code='M2_ELIGIBILITY_ROUTING_CONSUMPTION' AND src.contract_version=1 AND src.contract_status='ACCEPTED') src_count) AS source_registry_row_count,
       (SELECT count(*)::bigint FROM (SELECT tgt.source_m2_1_combined_hash::text FROM msbf_ctl.m2_2_pricing_structure_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.request_contract_code='M2_REQUEST_STRUCTURE_CONSUMPTION' AND tgt.request_contract_version=1 AND tgt.pricing_contract_code='M2_PRICING_STRUCTURE_CONSUMPTION' AND tgt.pricing_contract_version=1 AND tgt.contract_status='ACCEPTED') tgt_count) AS target_registry_row_count
FROM tmp_accept_m2_12_context ctx
) x)
UNION ALL
(SELECT x.module1_run_id,
       x.edge_sequence,
       x.edge_code,
       x.target_node_code,
       x.expected_source_hash,
       x.observed_accepted_source_hash,
       x.observed_target_recorded_source_hash,
       x.source_gate_status,
       x.source_registry_row_count,
       x.target_registry_row_count,
       (x.observed_accepted_source_hash IS DISTINCT FROM x.expected_source_hash) AS source_hash_mismatch_flag,
       (x.observed_target_recorded_source_hash IS DISTINCT FROM x.expected_source_hash) AS target_hash_mismatch_flag,
       CASE WHEN x.source_registry_row_count=1
                  AND x.target_registry_row_count=1
                  AND x.source_gate_status='PASS'
                  AND x.observed_accepted_source_hash=x.expected_source_hash
                  AND x.observed_target_recorded_source_hash=x.expected_source_hash
            THEN 'PASS'::text ELSE 'FAIL'::text END AS edge_status
FROM (
SELECT ctx.module1_run_id,
       5::smallint AS edge_sequence,
       'M1_3_TO_M2_2_REQUEST_AUTHORITY'::text AS edge_code,
       'M2_2_PRICING_STRUCTURE'::text AS target_node_code,
       '01485256b9b5748fb412743d35ced602'::text AS expected_source_hash,
       ((SELECT (agr.observed_value::jsonb ->> 'application_set_hash')::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='M1_3_APPLICATION_REQUEST' AND agr.review_version=2 AND agr.result_status='PASS'))::text AS observed_accepted_source_hash,
       ((SELECT tgt.source_m1_3_application_hash::text FROM msbf_ctl.m2_2_pricing_structure_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.request_contract_code='M2_REQUEST_STRUCTURE_CONSUMPTION' AND tgt.request_contract_version=1 AND tgt.pricing_contract_code='M2_PRICING_STRUCTURE_CONSUMPTION' AND tgt.pricing_contract_version=1 AND tgt.source_m1_3_gate_id='M1_3_APPLICATION_REQUEST' AND tgt.contract_status='ACCEPTED'))::text AS observed_target_recorded_source_hash,
       ((SELECT agr.result_status::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='M1_3_APPLICATION_REQUEST' AND agr.review_version=2))::text AS source_gate_status,
       (SELECT count(*)::bigint FROM (SELECT (agr.observed_value::jsonb ->> 'application_set_hash')::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='M1_3_APPLICATION_REQUEST' AND agr.review_version=2 AND agr.result_status='PASS') src_count) AS source_registry_row_count,
       (SELECT count(*)::bigint FROM (SELECT tgt.source_m1_3_application_hash::text FROM msbf_ctl.m2_2_pricing_structure_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.request_contract_code='M2_REQUEST_STRUCTURE_CONSUMPTION' AND tgt.request_contract_version=1 AND tgt.pricing_contract_code='M2_PRICING_STRUCTURE_CONSUMPTION' AND tgt.pricing_contract_version=1 AND tgt.source_m1_3_gate_id='M1_3_APPLICATION_REQUEST' AND tgt.contract_status='ACCEPTED') tgt_count) AS target_registry_row_count
FROM tmp_accept_m2_12_context ctx
) x)
UNION ALL
(SELECT x.module1_run_id,
       x.edge_sequence,
       x.edge_code,
       x.target_node_code,
       x.expected_source_hash,
       x.observed_accepted_source_hash,
       x.observed_target_recorded_source_hash,
       x.source_gate_status,
       x.source_registry_row_count,
       x.target_registry_row_count,
       (x.observed_accepted_source_hash IS DISTINCT FROM x.expected_source_hash) AS source_hash_mismatch_flag,
       (x.observed_target_recorded_source_hash IS DISTINCT FROM x.expected_source_hash) AS target_hash_mismatch_flag,
       CASE WHEN x.source_registry_row_count=1
                  AND x.target_registry_row_count=1
                  AND x.source_gate_status='PASS'
                  AND x.observed_accepted_source_hash=x.expected_source_hash
                  AND x.observed_target_recorded_source_hash=x.expected_source_hash
            THEN 'PASS'::text ELSE 'FAIL'::text END AS edge_status
FROM (
SELECT ctx.module1_run_id,
       6::smallint AS edge_sequence,
       'M2_2_TO_M2_3'::text AS edge_code,
       'M2_3_FINAL_DECISION'::text AS target_node_code,
       'bbe83b187b31ea561789797322031fc6'::text AS expected_source_hash,
       ((SELECT src.combined_set_hash::text FROM msbf_ctl.m2_2_pricing_structure_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.request_contract_code='M2_REQUEST_STRUCTURE_CONSUMPTION' AND src.request_contract_version=1 AND src.pricing_contract_code='M2_PRICING_STRUCTURE_CONSUMPTION' AND src.pricing_contract_version=1 AND src.contract_status='ACCEPTED'))::text AS observed_accepted_source_hash,
       ((SELECT tgt.source_m2_2_combined_hash::text FROM msbf_ctl.m2_3_final_decision_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_FINAL_OFFER_DECISION_CONSUMPTION' AND tgt.contract_version=1 AND tgt.contract_status='ACCEPTED'))::text AS observed_target_recorded_source_hash,
       ((SELECT agr.result_status::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='M2_2_PRICING_STRUCTURE_COUNTEROFFER' AND agr.review_version=1))::text AS source_gate_status,
       (SELECT count(*)::bigint FROM (SELECT src.combined_set_hash::text FROM msbf_ctl.m2_2_pricing_structure_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.request_contract_code='M2_REQUEST_STRUCTURE_CONSUMPTION' AND src.request_contract_version=1 AND src.pricing_contract_code='M2_PRICING_STRUCTURE_CONSUMPTION' AND src.pricing_contract_version=1 AND src.contract_status='ACCEPTED') src_count) AS source_registry_row_count,
       (SELECT count(*)::bigint FROM (SELECT tgt.source_m2_2_combined_hash::text FROM msbf_ctl.m2_3_final_decision_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_FINAL_OFFER_DECISION_CONSUMPTION' AND tgt.contract_version=1 AND tgt.contract_status='ACCEPTED') tgt_count) AS target_registry_row_count
FROM tmp_accept_m2_12_context ctx
) x)
UNION ALL
(SELECT x.module1_run_id,
       x.edge_sequence,
       x.edge_code,
       x.target_node_code,
       x.expected_source_hash,
       x.observed_accepted_source_hash,
       x.observed_target_recorded_source_hash,
       x.source_gate_status,
       x.source_registry_row_count,
       x.target_registry_row_count,
       (x.observed_accepted_source_hash IS DISTINCT FROM x.expected_source_hash) AS source_hash_mismatch_flag,
       (x.observed_target_recorded_source_hash IS DISTINCT FROM x.expected_source_hash) AS target_hash_mismatch_flag,
       CASE WHEN x.source_registry_row_count=1
                  AND x.target_registry_row_count=1
                  AND x.source_gate_status='PASS'
                  AND x.observed_accepted_source_hash=x.expected_source_hash
                  AND x.observed_target_recorded_source_hash=x.expected_source_hash
            THEN 'PASS'::text ELSE 'FAIL'::text END AS edge_status
FROM (
SELECT ctx.module1_run_id,
       7::smallint AS edge_sequence,
       'M2_3_TO_M2_4'::text AS edge_code,
       'M2_4_PORTFOLIO_ACTIVATION'::text AS target_node_code,
       'bf09349b06ede7e5a2ec830c2f9ffe90'::text AS expected_source_hash,
       ((SELECT src.combined_set_hash::text FROM msbf_ctl.m2_3_final_decision_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_code='M2_FINAL_OFFER_DECISION_CONSUMPTION' AND src.contract_version=1 AND src.contract_status='ACCEPTED'))::text AS observed_accepted_source_hash,
       ((SELECT tgt.source_m2_3_combined_hash::text FROM msbf_ctl.m2_4_portfolio_activation_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_PORTFOLIO_ACTIVATION_CONSUMPTION' AND tgt.contract_version=1 AND tgt.contract_status='ACCEPTED'))::text AS observed_target_recorded_source_hash,
       ((SELECT agr.result_status::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='M2_3_FINAL_OFFER_DECISION_AUTHORIZATION' AND agr.review_version=1))::text AS source_gate_status,
       (SELECT count(*)::bigint FROM (SELECT src.combined_set_hash::text FROM msbf_ctl.m2_3_final_decision_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_code='M2_FINAL_OFFER_DECISION_CONSUMPTION' AND src.contract_version=1 AND src.contract_status='ACCEPTED') src_count) AS source_registry_row_count,
       (SELECT count(*)::bigint FROM (SELECT tgt.source_m2_3_combined_hash::text FROM msbf_ctl.m2_4_portfolio_activation_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_PORTFOLIO_ACTIVATION_CONSUMPTION' AND tgt.contract_version=1 AND tgt.contract_status='ACCEPTED') tgt_count) AS target_registry_row_count
FROM tmp_accept_m2_12_context ctx
) x)
UNION ALL
(SELECT x.module1_run_id,
       x.edge_sequence,
       x.edge_code,
       x.target_node_code,
       x.expected_source_hash,
       x.observed_accepted_source_hash,
       x.observed_target_recorded_source_hash,
       x.source_gate_status,
       x.source_registry_row_count,
       x.target_registry_row_count,
       (x.observed_accepted_source_hash IS DISTINCT FROM x.expected_source_hash) AS source_hash_mismatch_flag,
       (x.observed_target_recorded_source_hash IS DISTINCT FROM x.expected_source_hash) AS target_hash_mismatch_flag,
       CASE WHEN x.source_registry_row_count=1
                  AND x.target_registry_row_count=1
                  AND x.source_gate_status='PASS'
                  AND x.observed_accepted_source_hash=x.expected_source_hash
                  AND x.observed_target_recorded_source_hash=x.expected_source_hash
            THEN 'PASS'::text ELSE 'FAIL'::text END AS edge_status
FROM (
SELECT ctx.module1_run_id,
       8::smallint AS edge_sequence,
       'M2_4_TO_M2_5'::text AS edge_code,
       'M2_5_DAILY_MONITORING'::text AS target_node_code,
       '117450a3eea7bb3d3c74d18cc3c8e96a'::text AS expected_source_hash,
       ((SELECT src.combined_set_hash::text FROM msbf_ctl.m2_4_portfolio_activation_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_code='M2_PORTFOLIO_ACTIVATION_CONSUMPTION' AND src.contract_version=1 AND src.contract_status='ACCEPTED'))::text AS observed_accepted_source_hash,
       ((SELECT tgt.source_m2_4_combined_hash::text FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_DAILY_REMITTANCE_EXPOSURE_MONITORING_CONSUMPTION' AND tgt.contract_version=1 AND tgt.contract_status='ACCEPTED'))::text AS observed_target_recorded_source_hash,
       ((SELECT agr.result_status::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='M2_4_BOOKING_FUNDING_PORTFOLIO_ACTIVATION' AND agr.review_version=1))::text AS source_gate_status,
       (SELECT count(*)::bigint FROM (SELECT src.combined_set_hash::text FROM msbf_ctl.m2_4_portfolio_activation_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_code='M2_PORTFOLIO_ACTIVATION_CONSUMPTION' AND src.contract_version=1 AND src.contract_status='ACCEPTED') src_count) AS source_registry_row_count,
       (SELECT count(*)::bigint FROM (SELECT tgt.source_m2_4_combined_hash::text FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_DAILY_REMITTANCE_EXPOSURE_MONITORING_CONSUMPTION' AND tgt.contract_version=1 AND tgt.contract_status='ACCEPTED') tgt_count) AS target_registry_row_count
FROM tmp_accept_m2_12_context ctx
) x)
UNION ALL
(SELECT x.module1_run_id,
       x.edge_sequence,
       x.edge_code,
       x.target_node_code,
       x.expected_source_hash,
       x.observed_accepted_source_hash,
       x.observed_target_recorded_source_hash,
       x.source_gate_status,
       x.source_registry_row_count,
       x.target_registry_row_count,
       (x.observed_accepted_source_hash IS DISTINCT FROM x.expected_source_hash) AS source_hash_mismatch_flag,
       (x.observed_target_recorded_source_hash IS DISTINCT FROM x.expected_source_hash) AS target_hash_mismatch_flag,
       CASE WHEN x.source_registry_row_count=1
                  AND x.target_registry_row_count=1
                  AND x.source_gate_status='PASS'
                  AND x.observed_accepted_source_hash=x.expected_source_hash
                  AND x.observed_target_recorded_source_hash=x.expected_source_hash
            THEN 'PASS'::text ELSE 'FAIL'::text END AS edge_status
FROM (
SELECT ctx.module1_run_id,
       9::smallint AS edge_sequence,
       'M1_6_TO_M2_5_SCENARIO_AUTHORITY'::text AS edge_code,
       'M2_5_DAILY_MONITORING'::text AS target_node_code,
       '3f85921bf6fc30ddc6cee146085e58c5'::text AS expected_source_hash,
       ((SELECT (agr.observed_value::jsonb->>'combined_hash')::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='M1_6_MATCHED_SCENARIO_OVERLAYS' AND agr.review_version=1 AND agr.result_status='PASS'))::text AS observed_accepted_source_hash,
       ((SELECT tgt.source_m1_6_combined_hash::text FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_DAILY_REMITTANCE_EXPOSURE_MONITORING_CONSUMPTION' AND tgt.contract_version=1 AND tgt.source_m1_6_acceptance_gate_id='M1_6_MATCHED_SCENARIO_OVERLAYS' AND tgt.contract_status='ACCEPTED'))::text AS observed_target_recorded_source_hash,
       ((SELECT agr.result_status::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='M1_6_MATCHED_SCENARIO_OVERLAYS' AND agr.review_version=1))::text AS source_gate_status,
       (SELECT count(*)::bigint FROM (SELECT (agr.observed_value::jsonb->>'combined_hash')::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='M1_6_MATCHED_SCENARIO_OVERLAYS' AND agr.review_version=1 AND agr.result_status='PASS') src_count) AS source_registry_row_count,
       (SELECT count(*)::bigint FROM (SELECT tgt.source_m1_6_combined_hash::text FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_DAILY_REMITTANCE_EXPOSURE_MONITORING_CONSUMPTION' AND tgt.contract_version=1 AND tgt.source_m1_6_acceptance_gate_id='M1_6_MATCHED_SCENARIO_OVERLAYS' AND tgt.contract_status='ACCEPTED') tgt_count) AS target_registry_row_count
FROM tmp_accept_m2_12_context ctx
) x)
UNION ALL
(SELECT x.module1_run_id,
       x.edge_sequence,
       x.edge_code,
       x.target_node_code,
       x.expected_source_hash,
       x.observed_accepted_source_hash,
       x.observed_target_recorded_source_hash,
       x.source_gate_status,
       x.source_registry_row_count,
       x.target_registry_row_count,
       (x.observed_accepted_source_hash IS DISTINCT FROM x.expected_source_hash) AS source_hash_mismatch_flag,
       (x.observed_target_recorded_source_hash IS DISTINCT FROM x.expected_source_hash) AS target_hash_mismatch_flag,
       CASE WHEN x.source_registry_row_count=1
                  AND x.target_registry_row_count=1
                  AND x.source_gate_status='PASS'
                  AND x.observed_accepted_source_hash=x.expected_source_hash
                  AND x.observed_target_recorded_source_hash=x.expected_source_hash
            THEN 'PASS'::text ELSE 'FAIL'::text END AS edge_status
FROM (
SELECT ctx.module1_run_id,
       10::smallint AS edge_sequence,
       'M2_5_TO_M2_6'::text AS edge_code,
       'M2_6_INTERVENTION_STRATEGY'::text AS target_node_code,
       '18e1c444aa1b02ee5bd3539d7c477adc'::text AS expected_source_hash,
       ((SELECT src.combined_set_hash::text FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_code='M2_DAILY_REMITTANCE_EXPOSURE_MONITORING_CONSUMPTION' AND src.contract_version=1 AND src.contract_status='ACCEPTED'))::text AS observed_accepted_source_hash,
       ((SELECT tgt.source_m2_5_combined_hash::text FROM msbf_ctl.m2_6_intervention_strategy_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_CONSUMPTION' AND tgt.contract_version=1 AND tgt.contract_status='ACCEPTED'))::text AS observed_target_recorded_source_hash,
       ((SELECT agr.result_status::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='M2_5_DAILY_REMITTANCE_EXPOSURE_PORTFOLIO_MONITORING' AND agr.review_version=1))::text AS source_gate_status,
       (SELECT count(*)::bigint FROM (SELECT src.combined_set_hash::text FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_code='M2_DAILY_REMITTANCE_EXPOSURE_MONITORING_CONSUMPTION' AND src.contract_version=1 AND src.contract_status='ACCEPTED') src_count) AS source_registry_row_count,
       (SELECT count(*)::bigint FROM (SELECT tgt.source_m2_5_combined_hash::text FROM msbf_ctl.m2_6_intervention_strategy_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_CONSUMPTION' AND tgt.contract_version=1 AND tgt.contract_status='ACCEPTED') tgt_count) AS target_registry_row_count
FROM tmp_accept_m2_12_context ctx
) x)
UNION ALL
(SELECT x.module1_run_id,
       x.edge_sequence,
       x.edge_code,
       x.target_node_code,
       x.expected_source_hash,
       x.observed_accepted_source_hash,
       x.observed_target_recorded_source_hash,
       x.source_gate_status,
       x.source_registry_row_count,
       x.target_registry_row_count,
       (x.observed_accepted_source_hash IS DISTINCT FROM x.expected_source_hash) AS source_hash_mismatch_flag,
       (x.observed_target_recorded_source_hash IS DISTINCT FROM x.expected_source_hash) AS target_hash_mismatch_flag,
       CASE WHEN x.source_registry_row_count=1
                  AND x.target_registry_row_count=1
                  AND x.source_gate_status='PASS'
                  AND x.observed_accepted_source_hash=x.expected_source_hash
                  AND x.observed_target_recorded_source_hash=x.expected_source_hash
            THEN 'PASS'::text ELSE 'FAIL'::text END AS edge_status
FROM (
SELECT ctx.module1_run_id,
       11::smallint AS edge_sequence,
       'M2_6_TO_M2_7'::text AS edge_code,
       'M2_7_OPERATIONAL_ACTIVATION'::text AS target_node_code,
       '868125bff29270490cab4d2e55cb1388'::text AS expected_source_hash,
       ((SELECT src.combined_set_hash::text FROM msbf_ctl.m2_6_intervention_strategy_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_code='M2_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_CONSUMPTION' AND src.contract_version=1 AND src.contract_status='ACCEPTED'))::text AS observed_accepted_source_hash,
       ((SELECT tgt.source_combined_set_hash::text FROM msbf_ctl.m2_7_operational_activation_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION' AND tgt.contract_version=1 AND tgt.contract_status='ACCEPTED'))::text AS observed_target_recorded_source_hash,
       ((SELECT agr.result_status::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='M2_6_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY' AND agr.review_version=1))::text AS source_gate_status,
       (SELECT count(*)::bigint FROM (SELECT src.combined_set_hash::text FROM msbf_ctl.m2_6_intervention_strategy_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_code='M2_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_CONSUMPTION' AND src.contract_version=1 AND src.contract_status='ACCEPTED') src_count) AS source_registry_row_count,
       (SELECT count(*)::bigint FROM (SELECT tgt.source_combined_set_hash::text FROM msbf_ctl.m2_7_operational_activation_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION' AND tgt.contract_version=1 AND tgt.contract_status='ACCEPTED') tgt_count) AS target_registry_row_count
FROM tmp_accept_m2_12_context ctx
) x)
UNION ALL
(SELECT x.module1_run_id,
       x.edge_sequence,
       x.edge_code,
       x.target_node_code,
       x.expected_source_hash,
       x.observed_accepted_source_hash,
       x.observed_target_recorded_source_hash,
       x.source_gate_status,
       x.source_registry_row_count,
       x.target_registry_row_count,
       (x.observed_accepted_source_hash IS DISTINCT FROM x.expected_source_hash) AS source_hash_mismatch_flag,
       (x.observed_target_recorded_source_hash IS DISTINCT FROM x.expected_source_hash) AS target_hash_mismatch_flag,
       CASE WHEN x.source_registry_row_count=1
                  AND x.target_registry_row_count=1
                  AND x.source_gate_status='PASS'
                  AND x.observed_accepted_source_hash=x.expected_source_hash
                  AND x.observed_target_recorded_source_hash=x.expected_source_hash
            THEN 'PASS'::text ELSE 'FAIL'::text END AS edge_status
FROM (
SELECT ctx.module1_run_id,
       12::smallint AS edge_sequence,
       'M2_7_TO_M2_8'::text AS edge_code,
       'M2_8_SERVICING_EXECUTION'::text AS target_node_code,
       'c8e3a472afd2a16b1183677324e9db98'::text AS expected_source_hash,
       ((SELECT src.combined_set_hash::text FROM msbf_ctl.m2_7_operational_activation_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_code='M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION' AND src.contract_version=1 AND src.contract_status='ACCEPTED'))::text AS observed_accepted_source_hash,
       ((SELECT tgt.source_combined_set_hash::text FROM msbf_ctl.m2_8_servicing_execution_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONSUMPTION' AND tgt.contract_version=1 AND tgt.contract_status='ACCEPTED'))::text AS observed_target_recorded_source_hash,
       ((SELECT agr.result_status::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP' AND agr.review_version=1))::text AS source_gate_status,
       (SELECT count(*)::bigint FROM (SELECT src.combined_set_hash::text FROM msbf_ctl.m2_7_operational_activation_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_code='M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION' AND src.contract_version=1 AND src.contract_status='ACCEPTED') src_count) AS source_registry_row_count,
       (SELECT count(*)::bigint FROM (SELECT tgt.source_combined_set_hash::text FROM msbf_ctl.m2_8_servicing_execution_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONSUMPTION' AND tgt.contract_version=1 AND tgt.contract_status='ACCEPTED') tgt_count) AS target_registry_row_count
FROM tmp_accept_m2_12_context ctx
) x)
UNION ALL
(SELECT x.module1_run_id,
       x.edge_sequence,
       x.edge_code,
       x.target_node_code,
       x.expected_source_hash,
       x.observed_accepted_source_hash,
       x.observed_target_recorded_source_hash,
       x.source_gate_status,
       x.source_registry_row_count,
       x.target_registry_row_count,
       (x.observed_accepted_source_hash IS DISTINCT FROM x.expected_source_hash) AS source_hash_mismatch_flag,
       (x.observed_target_recorded_source_hash IS DISTINCT FROM x.expected_source_hash) AS target_hash_mismatch_flag,
       CASE WHEN x.source_registry_row_count=1
                  AND x.target_registry_row_count=1
                  AND x.source_gate_status='PASS'
                  AND x.observed_accepted_source_hash=x.expected_source_hash
                  AND x.observed_target_recorded_source_hash=x.expected_source_hash
            THEN 'PASS'::text ELSE 'FAIL'::text END AS edge_status
FROM (
SELECT ctx.module1_run_id,
       13::smallint AS edge_sequence,
       'M2_8_TO_M2_9'::text AS edge_code,
       'M2_9_RECONCILIATION_CERTIFICATION'::text AS target_node_code,
       'ab32d80ba20c2c8f0a6ec9ec97c2ed26'::text AS expected_source_hash,
       ((SELECT src.combined_set_hash::text FROM msbf_ctl.m2_8_servicing_execution_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_code='M2_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONSUMPTION' AND src.contract_version=1 AND src.contract_status='ACCEPTED'))::text AS observed_accepted_source_hash,
       ((SELECT tgt.source_combined_set_hash::text FROM msbf_ctl.m2_9_reconciliation_certification_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_CONSUMPTION' AND tgt.contract_version=1 AND tgt.contract_status='ACCEPTED'))::text AS observed_target_recorded_source_hash,
       ((SELECT agr.result_status::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='M2_8_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONTROL' AND agr.review_version=1))::text AS source_gate_status,
       (SELECT count(*)::bigint FROM (SELECT src.combined_set_hash::text FROM msbf_ctl.m2_8_servicing_execution_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_code='M2_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONSUMPTION' AND src.contract_version=1 AND src.contract_status='ACCEPTED') src_count) AS source_registry_row_count,
       (SELECT count(*)::bigint FROM (SELECT tgt.source_combined_set_hash::text FROM msbf_ctl.m2_9_reconciliation_certification_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_CONSUMPTION' AND tgt.contract_version=1 AND tgt.contract_status='ACCEPTED') tgt_count) AS target_registry_row_count
FROM tmp_accept_m2_12_context ctx
) x)
UNION ALL
(SELECT x.module1_run_id,
       x.edge_sequence,
       x.edge_code,
       x.target_node_code,
       x.expected_source_hash,
       x.observed_accepted_source_hash,
       x.observed_target_recorded_source_hash,
       x.source_gate_status,
       x.source_registry_row_count,
       x.target_registry_row_count,
       (x.observed_accepted_source_hash IS DISTINCT FROM x.expected_source_hash) AS source_hash_mismatch_flag,
       (x.observed_target_recorded_source_hash IS DISTINCT FROM x.expected_source_hash) AS target_hash_mismatch_flag,
       CASE WHEN x.source_registry_row_count=1
                  AND x.target_registry_row_count=1
                  AND x.source_gate_status='PASS'
                  AND x.observed_accepted_source_hash=x.expected_source_hash
                  AND x.observed_target_recorded_source_hash=x.expected_source_hash
            THEN 'PASS'::text ELSE 'FAIL'::text END AS edge_status
FROM (
SELECT ctx.module1_run_id,
       14::smallint AS edge_sequence,
       'M2_9_TO_M2_10'::text AS edge_code,
       'M2_10_PORTFOLIO_ANALYTICS'::text AS target_node_code,
       '6af76d0059b47623619ebc09330b15fe'::text AS expected_source_hash,
       ((SELECT src.combined_set_hash::text FROM msbf_ctl.m2_9_reconciliation_certification_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_code='M2_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_CONSUMPTION' AND src.contract_version=1 AND src.contract_status='ACCEPTED'))::text AS observed_accepted_source_hash,
       ((SELECT tgt.source_combined_set_hash::text FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_CONSUMPTION' AND tgt.contract_version=1 AND tgt.contract_status='ACCEPTED'))::text AS observed_target_recorded_source_hash,
       ((SELECT agr.result_status::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='M2_9_PAYMENT_RECONCILIATION_EXCEPTION_RESOLUTION_ACCOUNT_STATE_CERTIFICATION' AND agr.review_version=1))::text AS source_gate_status,
       (SELECT count(*)::bigint FROM (SELECT src.combined_set_hash::text FROM msbf_ctl.m2_9_reconciliation_certification_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_code='M2_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_CONSUMPTION' AND src.contract_version=1 AND src.contract_status='ACCEPTED') src_count) AS source_registry_row_count,
       (SELECT count(*)::bigint FROM (SELECT tgt.source_combined_set_hash::text FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_CONSUMPTION' AND tgt.contract_version=1 AND tgt.contract_status='ACCEPTED') tgt_count) AS target_registry_row_count
FROM tmp_accept_m2_12_context ctx
) x)
UNION ALL
(SELECT x.module1_run_id,
       x.edge_sequence,
       x.edge_code,
       x.target_node_code,
       x.expected_source_hash,
       x.observed_accepted_source_hash,
       x.observed_target_recorded_source_hash,
       x.source_gate_status,
       x.source_registry_row_count,
       x.target_registry_row_count,
       (x.observed_accepted_source_hash IS DISTINCT FROM x.expected_source_hash) AS source_hash_mismatch_flag,
       (x.observed_target_recorded_source_hash IS DISTINCT FROM x.expected_source_hash) AS target_hash_mismatch_flag,
       CASE WHEN x.source_registry_row_count=1
                  AND x.target_registry_row_count=1
                  AND x.source_gate_status='PASS'
                  AND x.observed_accepted_source_hash=x.expected_source_hash
                  AND x.observed_target_recorded_source_hash=x.expected_source_hash
            THEN 'PASS'::text ELSE 'FAIL'::text END AS edge_status
FROM (
SELECT ctx.module1_run_id,
       15::smallint AS edge_sequence,
       'M1_17_TO_M2_11'::text AS edge_code,
       'M2_11_STRATEGY_SIMULATION'::text AS target_node_code,
       '7d9e466da28cad2551aa99c4c40c912b'::text AS expected_source_hash,
       ((SELECT src.combined_g2_hash::text FROM msbf_ctl.m1_17_g2_bundle_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.bundle_code='M1_G2_CONSUMPTION_BUNDLE' AND src.bundle_version=1 AND src.bundle_status='ACCEPTED'))::text AS observed_accepted_source_hash,
       ((SELECT tgt.source_m1_17_combined_hash::text FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION' AND tgt.contract_version=1 AND tgt.contract_status='ACCEPTED'))::text AS observed_target_recorded_source_hash,
       ((SELECT agr.result_status::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='G2_M1_CONTRACT' AND agr.review_version=1))::text AS source_gate_status,
       (SELECT count(*)::bigint FROM (SELECT src.combined_g2_hash::text FROM msbf_ctl.m1_17_g2_bundle_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.bundle_code='M1_G2_CONSUMPTION_BUNDLE' AND src.bundle_version=1 AND src.bundle_status='ACCEPTED') src_count) AS source_registry_row_count,
       (SELECT count(*)::bigint FROM (SELECT tgt.source_m1_17_combined_hash::text FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION' AND tgt.contract_version=1 AND tgt.contract_status='ACCEPTED') tgt_count) AS target_registry_row_count
FROM tmp_accept_m2_12_context ctx
) x)
UNION ALL
(SELECT x.module1_run_id,
       x.edge_sequence,
       x.edge_code,
       x.target_node_code,
       x.expected_source_hash,
       x.observed_accepted_source_hash,
       x.observed_target_recorded_source_hash,
       x.source_gate_status,
       x.source_registry_row_count,
       x.target_registry_row_count,
       (x.observed_accepted_source_hash IS DISTINCT FROM x.expected_source_hash) AS source_hash_mismatch_flag,
       (x.observed_target_recorded_source_hash IS DISTINCT FROM x.expected_source_hash) AS target_hash_mismatch_flag,
       CASE WHEN x.source_registry_row_count=1
                  AND x.target_registry_row_count=1
                  AND x.source_gate_status='PASS'
                  AND x.observed_accepted_source_hash=x.expected_source_hash
                  AND x.observed_target_recorded_source_hash=x.expected_source_hash
            THEN 'PASS'::text ELSE 'FAIL'::text END AS edge_status
FROM (
SELECT ctx.module1_run_id,
       16::smallint AS edge_sequence,
       'M2_2_TO_M2_11'::text AS edge_code,
       'M2_11_STRATEGY_SIMULATION'::text AS target_node_code,
       'bbe83b187b31ea561789797322031fc6'::text AS expected_source_hash,
       ((SELECT src.combined_set_hash::text FROM msbf_ctl.m2_2_pricing_structure_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.request_contract_code='M2_REQUEST_STRUCTURE_CONSUMPTION' AND src.request_contract_version=1 AND src.pricing_contract_code='M2_PRICING_STRUCTURE_CONSUMPTION' AND src.pricing_contract_version=1 AND src.contract_status='ACCEPTED'))::text AS observed_accepted_source_hash,
       ((SELECT tgt.source_m2_2_combined_hash::text FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION' AND tgt.contract_version=1 AND tgt.contract_status='ACCEPTED'))::text AS observed_target_recorded_source_hash,
       ((SELECT agr.result_status::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='M2_2_PRICING_STRUCTURE_COUNTEROFFER' AND agr.review_version=1))::text AS source_gate_status,
       (SELECT count(*)::bigint FROM (SELECT src.combined_set_hash::text FROM msbf_ctl.m2_2_pricing_structure_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.request_contract_code='M2_REQUEST_STRUCTURE_CONSUMPTION' AND src.request_contract_version=1 AND src.pricing_contract_code='M2_PRICING_STRUCTURE_CONSUMPTION' AND src.pricing_contract_version=1 AND src.contract_status='ACCEPTED') src_count) AS source_registry_row_count,
       (SELECT count(*)::bigint FROM (SELECT tgt.source_m2_2_combined_hash::text FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION' AND tgt.contract_version=1 AND tgt.contract_status='ACCEPTED') tgt_count) AS target_registry_row_count
FROM tmp_accept_m2_12_context ctx
) x)
UNION ALL
(SELECT x.module1_run_id,
       x.edge_sequence,
       x.edge_code,
       x.target_node_code,
       x.expected_source_hash,
       x.observed_accepted_source_hash,
       x.observed_target_recorded_source_hash,
       x.source_gate_status,
       x.source_registry_row_count,
       x.target_registry_row_count,
       (x.observed_accepted_source_hash IS DISTINCT FROM x.expected_source_hash) AS source_hash_mismatch_flag,
       (x.observed_target_recorded_source_hash IS DISTINCT FROM x.expected_source_hash) AS target_hash_mismatch_flag,
       CASE WHEN x.source_registry_row_count=1
                  AND x.target_registry_row_count=1
                  AND x.source_gate_status='PASS'
                  AND x.observed_accepted_source_hash=x.expected_source_hash
                  AND x.observed_target_recorded_source_hash=x.expected_source_hash
            THEN 'PASS'::text ELSE 'FAIL'::text END AS edge_status
FROM (
SELECT ctx.module1_run_id,
       17::smallint AS edge_sequence,
       'M2_4_TO_M2_11'::text AS edge_code,
       'M2_11_STRATEGY_SIMULATION'::text AS target_node_code,
       '117450a3eea7bb3d3c74d18cc3c8e96a'::text AS expected_source_hash,
       ((SELECT src.combined_set_hash::text FROM msbf_ctl.m2_4_portfolio_activation_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_code='M2_PORTFOLIO_ACTIVATION_CONSUMPTION' AND src.contract_version=1 AND src.contract_status='ACCEPTED'))::text AS observed_accepted_source_hash,
       ((SELECT tgt.source_m2_4_combined_hash::text FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION' AND tgt.contract_version=1 AND tgt.contract_status='ACCEPTED'))::text AS observed_target_recorded_source_hash,
       ((SELECT agr.result_status::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='M2_4_BOOKING_FUNDING_PORTFOLIO_ACTIVATION' AND agr.review_version=1))::text AS source_gate_status,
       (SELECT count(*)::bigint FROM (SELECT src.combined_set_hash::text FROM msbf_ctl.m2_4_portfolio_activation_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_code='M2_PORTFOLIO_ACTIVATION_CONSUMPTION' AND src.contract_version=1 AND src.contract_status='ACCEPTED') src_count) AS source_registry_row_count,
       (SELECT count(*)::bigint FROM (SELECT tgt.source_m2_4_combined_hash::text FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION' AND tgt.contract_version=1 AND tgt.contract_status='ACCEPTED') tgt_count) AS target_registry_row_count
FROM tmp_accept_m2_12_context ctx
) x)
UNION ALL
(SELECT x.module1_run_id,
       x.edge_sequence,
       x.edge_code,
       x.target_node_code,
       x.expected_source_hash,
       x.observed_accepted_source_hash,
       x.observed_target_recorded_source_hash,
       x.source_gate_status,
       x.source_registry_row_count,
       x.target_registry_row_count,
       (x.observed_accepted_source_hash IS DISTINCT FROM x.expected_source_hash) AS source_hash_mismatch_flag,
       (x.observed_target_recorded_source_hash IS DISTINCT FROM x.expected_source_hash) AS target_hash_mismatch_flag,
       CASE WHEN x.source_registry_row_count=1
                  AND x.target_registry_row_count=1
                  AND x.source_gate_status='PASS'
                  AND x.observed_accepted_source_hash=x.expected_source_hash
                  AND x.observed_target_recorded_source_hash=x.expected_source_hash
            THEN 'PASS'::text ELSE 'FAIL'::text END AS edge_status
FROM (
SELECT ctx.module1_run_id,
       18::smallint AS edge_sequence,
       'M2_7_TO_M2_11'::text AS edge_code,
       'M2_11_STRATEGY_SIMULATION'::text AS target_node_code,
       'c8e3a472afd2a16b1183677324e9db98'::text AS expected_source_hash,
       ((SELECT src.combined_set_hash::text FROM msbf_ctl.m2_7_operational_activation_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_code='M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION' AND src.contract_version=1 AND src.contract_status='ACCEPTED'))::text AS observed_accepted_source_hash,
       ((SELECT tgt.source_m2_7_combined_hash::text FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION' AND tgt.contract_version=1 AND tgt.contract_status='ACCEPTED'))::text AS observed_target_recorded_source_hash,
       ((SELECT agr.result_status::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP' AND agr.review_version=1))::text AS source_gate_status,
       (SELECT count(*)::bigint FROM (SELECT src.combined_set_hash::text FROM msbf_ctl.m2_7_operational_activation_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_code='M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION' AND src.contract_version=1 AND src.contract_status='ACCEPTED') src_count) AS source_registry_row_count,
       (SELECT count(*)::bigint FROM (SELECT tgt.source_m2_7_combined_hash::text FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION' AND tgt.contract_version=1 AND tgt.contract_status='ACCEPTED') tgt_count) AS target_registry_row_count
FROM tmp_accept_m2_12_context ctx
) x)
UNION ALL
(SELECT x.module1_run_id,
       x.edge_sequence,
       x.edge_code,
       x.target_node_code,
       x.expected_source_hash,
       x.observed_accepted_source_hash,
       x.observed_target_recorded_source_hash,
       x.source_gate_status,
       x.source_registry_row_count,
       x.target_registry_row_count,
       (x.observed_accepted_source_hash IS DISTINCT FROM x.expected_source_hash) AS source_hash_mismatch_flag,
       (x.observed_target_recorded_source_hash IS DISTINCT FROM x.expected_source_hash) AS target_hash_mismatch_flag,
       CASE WHEN x.source_registry_row_count=1
                  AND x.target_registry_row_count=1
                  AND x.source_gate_status='PASS'
                  AND x.observed_accepted_source_hash=x.expected_source_hash
                  AND x.observed_target_recorded_source_hash=x.expected_source_hash
            THEN 'PASS'::text ELSE 'FAIL'::text END AS edge_status
FROM (
SELECT ctx.module1_run_id,
       19::smallint AS edge_sequence,
       'M2_10_TO_M2_11'::text AS edge_code,
       'M2_11_STRATEGY_SIMULATION'::text AS target_node_code,
       '24fca7263a04397ebf21d30639f9069b'::text AS expected_source_hash,
       ((SELECT src.combined_set_hash::text FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_code='M2_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_CONSUMPTION' AND src.contract_version=1 AND src.contract_status='ACCEPTED'))::text AS observed_accepted_source_hash,
       ((SELECT tgt.source_m2_10_combined_hash::text FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION' AND tgt.contract_version=1 AND tgt.contract_status='ACCEPTED'))::text AS observed_target_recorded_source_hash,
       ((SELECT agr.result_status::text FROM msbf_ctl.acceptance_gate_result agr WHERE agr.run_id=ctx.module1_run_id AND agr.gate_id='M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS' AND agr.review_version=1))::text AS source_gate_status,
       (SELECT count(*)::bigint FROM (SELECT src.combined_set_hash::text FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry src WHERE src.module1_run_id=ctx.module1_run_id AND src.contract_code='M2_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_CONSUMPTION' AND src.contract_version=1 AND src.contract_status='ACCEPTED') src_count) AS source_registry_row_count,
       (SELECT count(*)::bigint FROM (SELECT tgt.source_m2_10_combined_hash::text FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry tgt WHERE tgt.module1_run_id=ctx.module1_run_id AND tgt.contract_code='M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION' AND tgt.contract_version=1 AND tgt.contract_status='ACCEPTED') tgt_count) AS target_registry_row_count
FROM tmp_accept_m2_12_context ctx
) x);
CREATE UNIQUE INDEX ux_tmp_accept_m2_12_source_edges ON tmp_accept_m2_12_source_edges(edge_sequence,edge_code);
ANALYZE tmp_accept_m2_12_source_edges;

DO $m212_225_hf15_source_graph_precheck$
DECLARE
    v_edge_detail text;
BEGIN
    IF NOT ((SELECT count(*)=19
                    AND count(*) FILTER (WHERE edge_status='PASS')=19
                    AND count(DISTINCT edge_sequence)=19
                    AND count(DISTINCT edge_code)=19
               FROM tmp_accept_m2_12_source_edges)) THEN
        SELECT string_agg(
                   format('edge=%s|code=%s|status=%s|source_rows=%s|target_rows=%s|gate=%s|expected=%s|source=%s|target=%s',
                          edge_sequence,edge_code,edge_status,source_registry_row_count,target_registry_row_count,
                          source_gate_status,expected_source_hash,observed_accepted_source_hash,
                          observed_target_recorded_source_hash),
                   '; ' ORDER BY edge_sequence)
          INTO v_edge_detail
          FROM tmp_accept_m2_12_source_edges
         WHERE edge_status IS DISTINCT FROM 'PASS';
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 Program 225 HF23 verifier pre-execution source-graph verification failed',
            DETAIL=coalesce(v_edge_detail,
                            'rows='||(SELECT count(*) FROM tmp_accept_m2_12_source_edges)::text||
                            '|pass_rows='||(SELECT count(*) FILTER (WHERE edge_status='PASS') FROM tmp_accept_m2_12_source_edges)::text||
                            '|distinct_sequences='||(SELECT count(DISTINCT edge_sequence) FROM tmp_accept_m2_12_source_edges)::text||
                            '|distinct_codes='||(SELECT count(DISTINCT edge_code) FROM tmp_accept_m2_12_source_edges)::text),
            HINT='Stop. Preserve the transcript and do not execute Program 222 HF9.';
    END IF;
END;
$m212_225_hf15_source_graph_precheck$;

/***************************************************************************************************
HF23 COMPLETE PHYSICAL STAGE-BOUNDARY RECONSTRUCTION
- 66 controls from msbf_ctl.run_evidence
- 3 M1.17 controls from msbf_ctl.m1_17_end_to_end_evidence_snapshot
- M2_3_POLICY_BOUNDARY from the accepted reason definition plus complete latest/archive marker coverage
***************************************************************************************************/
CREATE TEMP TABLE tmp_accept_m2_12_stage_boundary_method ON COMMIT DROP AS
SELECT v.acceptance_evidence_code::text AS acceptance_evidence_code,
       v.acceptance_gate_id::text AS acceptance_gate_id,
       v.acceptance_gate_review_version::integer AS acceptance_gate_review_version,
       v.accepted_detail_actual_rows::integer AS accepted_detail_actual_rows,
       v.accepted_detail_expected_rows::integer AS accepted_detail_expected_rows,
       v.accepted_detail_report_authority_path::text AS accepted_detail_report_authority_path,
       v.accepted_detail_report_sha256::text AS accepted_detail_report_sha256,
       v.boundary_pattern_1::text AS boundary_pattern_1,
       v.boundary_pattern_2::text AS boundary_pattern_2,
       v.matrix_sequence::smallint AS matrix_sequence,
       ctx.module1_run_id::bigint AS module1_run_id,
       v.certification_node_sequence::smallint AS node_sequence,
       v.registry_relation::text AS registry_relation,
       v.report_exists_status::text AS report_exists_status,
       v.required_evidence_code_count::integer AS required_evidence_code_count,
       string_to_array(v.required_evidence_codes,'|')::text[] AS required_evidence_codes,
       v.stage_code::text AS stage_code
FROM (VALUES
    ('M1_17_ACCEPTANCE_SUMMARY'::text,'G2_M1_CONTRACT'::text,'1'::text,'0'::text,'0'::text,'19_M1_17/evidence/final/D24_Blocking_Stage_Violations.csv'::text,'4efd6882af220b190426e4a897ba1d1280c3d7af6174290d1d23af36b1fde300'::text,'M1_17_%BOUNDARY%'::text,'M1_17_%BLOCKING%'::text,'6'::text,'1'::text,'msbf_ctl.m1_17_g2_bundle_registry'::text,'PASS'::text,'3'::text,'M1_17_E2E_045_BLOCKING_ERRORS|M1_17_E2E_046_MODULE2_ROWS|M1_17_E2E_047_PII_COLUMNS'::text,'M1_17_G2_FOUNDATION'::text),
    ('M2_1_ACCEPTANCE_SUMMARY'::text,'M2_1_ELIGIBILITY_POLICY_ROUTING'::text,'1'::text,'0'::text,'0'::text,'20_M2_1/evidence/final/24_MSBF_M2_1_Eligibility_Policy_Gates_Decision_Routing_Foundations_Detail_Report_v0_2R7_Blocking_Errors_And_Stage_Boundary_Violations_20260730.csv'::text,'2a9b9b7b5354d529e19d981854baaffa782083ab5d0fdd2f21ef857f66329efb'::text,'M2_1_%BOUNDARY%'::text,'M2_1_%BLOCKING%'::text,'12'::text,'2'::text,'msbf_ctl.m2_1_strategy_contract_registry'::text,'PASS'::text,'3'::text,'M2_1_POS_109_ZERO_BLOCKING_ERRORS|M2_1_NEG_004_FINAL_OFFER_BOUNDARY|M2_1_NEG_005_ACQUISITION_CREDIT_BOUNDARY'::text,'M2_1_ELIGIBILITY_ROUTING'::text),
    ('M2_2_ACCEPTANCE_SUMMARY'::text,'M2_2_PRICING_STRUCTURE_COUNTEROFFER'::text,'1'::text,'0'::text,'0'::text,'21_M2_2/evidence/final/24_blocking_stage_boundary_violations.csv'::text,'d5e9991bf2fd0248204517bf0b947fa76af898e6d33da117d7f4229cf4ee85cb'::text,'M2_2_%BOUNDARY%'::text,'M2_2_%BLOCKING%'::text,'18'::text,'3'::text,'msbf_ctl.m2_2_pricing_structure_contract_registry'::text,'PASS'::text,'3'::text,'M2_2_POS_012_BOUNDARY_FLAGS|M2_2_NEG_002_FINAL_DECISION_BOUNDARY|M2_2_NEG_003_ACQUISITION_NONCREDIT_BOUNDARY'::text,'M2_2_PRICING_STRUCTURE'::text),
    ('M2_3_ACCEPTANCE_SUMMARY'::text,'M2_3_FINAL_OFFER_DECISION_AUTHORIZATION'::text,'1'::text,'0'::text,'0'::text,'22_M2_3/evidence/final/24_blocking_errors_and_stage_boundary_violations.csv'::text,'d5e9991bf2fd0248204517bf0b947fa76af898e6d33da117d7f4229cf4ee85cb'::text,'M2_3_%BOUNDARY%'::text,'M2_3_%BLOCKING%'::text,'24'::text,'4'::text,'msbf_ctl.m2_3_final_decision_contract_registry'::text,'PASS'::text,'6'::text,'M2_3_POLICY_BOUNDARY|M2_3_POS_011_OUTCOME_BOUNDARY_FLAGS|M2_3_POS_012_REASON_BOUNDARY_FLAGS|M2_3_NEG_002_BOOKING_BOUNDARY_FLAG|M2_3_NEG_003_EXTERNAL_NOTICE_BOUNDARY|M2_3_NEG_004_ADVERSE_ACTION_BOUNDARY'::text,'M2_3_FINAL_DECISION'::text),
    ('M2_4_ACCEPTANCE_SUMMARY'::text,'M2_4_BOOKING_FUNDING_PORTFOLIO_ACTIVATION'::text,'1'::text,'0'::text,'0'::text,'23_M2_4/evidence/final/24_blocking_errors_and_stage_boundary_violations.csv'::text,'d5e9991bf2fd0248204517bf0b947fa76af898e6d33da117d7f4229cf4ee85cb'::text,'M2_4_%BOUNDARY%'::text,'M2_4_%BLOCKING%'::text,'30'::text,'5'::text,'msbf_ctl.m2_4_portfolio_activation_contract_registry'::text,'PASS'::text,'4'::text,'M2_4_POS_060_OPERATIONAL_BOUNDARY_FLAGS|M2_4_NEG_002_REAL_FUNDS_POLICY_BOUNDARY|M2_4_NEG_003_EXTERNAL_NOTICE_POLICY_BOUNDARY|M2_4_NEG_004_ADVERSE_ACTION_POLICY_BOUNDARY'::text,'M2_4_PORTFOLIO_ACTIVATION'::text),
    ('M2_5_ACCEPTANCE_SUMMARY'::text,'M2_5_DAILY_REMITTANCE_EXPOSURE_PORTFOLIO_MONITORING'::text,'1'::text,'0'::text,'0'::text,'24_M2_5/evidence/raw/csv/MSBF_M2_5_Daily_Remittance_Exposure_&_Portfolio_Monitoring_Detail_Report_v0_2R5_Blocking_Errors_And_Stage_Boundary_Violations_20260801.csv'::text,'d5e9991bf2fd0248204517bf0b947fa76af898e6d33da117d7f4229cf4ee85cb'::text,'M2_5_%BOUNDARY%'::text,'M2_5_%BLOCKING%'::text,'36'::text,'6'::text,'msbf_ctl.m2_5_portfolio_monitoring_contract_registry'::text,'PASS'::text,'6'::text,'M2_5_POS_018_REASON_BOUNDARY_FLAGS|M2_5_NEG_002_REAL_DEBIT_BOUNDARY|M2_5_NEG_003_EXTERNAL_NOTICE_BOUNDARY|M2_5_NEG_004_ADVERSE_NOTICE_BOUNDARY|M2_5_NEG_005_WRITE_OFF_RESTRUCTURE_BOUNDARY|M2_5_NEG_006_MONITORING_ONLY_BOUNDARY'::text,'M2_5_DAILY_MONITORING'::text),
    ('M2_6_ACCEPTANCE_SUMMARY'::text,'M2_6_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY'::text,'1'::text,'0'::text,'0'::text,'25_M2_6/evidence/raw/csv/179_24_blocking_errors_and_stage_boundary_violations.csv'::text,'1721443af6fdf32b7ee5133ff02df3b36c199a2778815257010c2140977e7491'::text,'M2_6_%BOUNDARY%'::text,'M2_6_%BLOCKING%'::text,'42'::text,'7'::text,'msbf_ctl.m2_6_intervention_strategy_contract_registry'::text,'PASS'::text,'4'::text,'M2_6_NEG_017_PAYLOAD_BOUNDARY|M2_6_NEG_018_PAYLOAD_BOUNDARY|M2_6_NEG_019_PAYLOAD_BOUNDARY|M2_6_NEG_020_PAYLOAD_BOUNDARY'::text,'M2_6_INTERVENTION_STRATEGY'::text),
    ('M2_7_ACCEPTANCE_SUMMARY'::text,'M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP'::text,'1'::text,'0'::text,'0'::text,'26_M2_7/evidence/raw/csv/187_24_blocking_errors_and_stage_boundary_violations.csv'::text,'1721443af6fdf32b7ee5133ff02df3b36c199a2778815257010c2140977e7491'::text,'M2_7_%BOUNDARY%'::text,'M2_7_%BLOCKING%'::text,'48'::text,'8'::text,'msbf_ctl.m2_7_operational_activation_contract_registry'::text,'PASS'::text,'7'::text,'M2_7_POS_018_DEFINITION_BOUNDARY|M2_7_NEG_002_SIMULATED_SETUP_BOUNDARY|M2_7_NEG_003_REAL_ACCOUNT_BOUNDARY|M2_7_NEG_004_PAYMENT_CHANGE_BOUNDARY|M2_7_NEG_005_BANK_DATA_BOUNDARY|M2_7_NEG_006_ACH_NETWORK_BOUNDARY|M2_7_NEG_007_EXTERNAL_NOTICE_BOUNDARY'::text,'M2_7_OPERATIONAL_ACTIVATION'::text),
    ('M2_8_ACCEPTANCE_SUMMARY'::text,'M2_8_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONTROL'::text,'1'::text,'0'::text,'0'::text,'27_M2_8/evidence/raw/csv/195_24_blocking_errors_and_stage_boundary_violations.csv'::text,'1721443af6fdf32b7ee5133ff02df3b36c199a2778815257010c2140977e7491'::text,'M2_8_%BOUNDARY%'::text,'M2_8_%BLOCKING%'::text,'54'::text,'9'::text,'msbf_ctl.m2_8_servicing_execution_contract_registry'::text,'PASS'::text,'8'::text,'M2_8_POS_022_DEFINITION_BOUNDARY|M2_8_POS_089_PAYMENT_BOUNDARY|M2_8_POS_095_TRANSITION_BOUNDARY|M2_8_NEG_002_SIMULATION_BOUNDARY|M2_8_NEG_003_REAL_FUNDS_BOUNDARY|M2_8_NEG_004_BANK_DATA_BOUNDARY|M2_8_NEG_005_ACH_NETWORK_BOUNDARY|M2_8_NEG_006_PROCESSOR_CALL_BOUNDARY'::text,'M2_8_SERVICING_EXECUTION'::text),
    ('M2_9_ACCEPTANCE_SUMMARY'::text,'M2_9_PAYMENT_RECONCILIATION_EXCEPTION_RESOLUTION_ACCOUNT_STATE_CERTIFICATION'::text,'1'::text,'0'::text,'0'::text,'28_M2_9/evidence/raw/csv/203_24_blocking_errors_and_stage_boundary_violations.csv'::text,'1721443af6fdf32b7ee5133ff02df3b36c199a2778815257010c2140977e7491'::text,'M2_9_%BOUNDARY%'::text,'M2_9_%BLOCKING%'::text,'60'::text,'10'::text,'msbf_ctl.m2_9_reconciliation_certification_contract_registry'::text,'PASS'::text,'10'::text,'M2_9_POS_021_DEFINITION_BOUNDARY|M2_9_POS_069_PAYMENT_RECON_BOUNDARY|M2_9_POS_070_EXCEPTION_BOUNDARY|M2_9_POS_087_ACCOUNT_BOUNDARY|M2_9_POS_095_CERTIFICATION_HASH_BOUNDARY|M2_9_NEG_002_CERTIFICATION_BOUNDARY|M2_9_NEG_003_REAL_FUNDS_BOUNDARY|M2_9_NEG_004_BANK_DATA_BOUNDARY|M2_9_NEG_005_NETWORK_BOUNDARY|M2_9_NEG_006_PROCESSOR_BOUNDARY'::text,'M2_9_RECONCILIATION_CERTIFICATION'::text),
    ('M2_10_ACCEPTANCE_SUMMARY'::text,'M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS'::text,'1'::text,'0'::text,'0'::text,'29_M2_10/evidence/raw/csv/211_24_blocking_errors_and_stage_boundary_violations.csv'::text,'1721443af6fdf32b7ee5133ff02df3b36c199a2778815257010c2140977e7491'::text,'M2_10_%BOUNDARY%'::text,'M2_10_%BLOCKING%'::text,'66'::text,'11'::text,'msbf_ctl.m2_10_portfolio_analytics_contract_registry'::text,'PASS'::text,'10'::text,'M2_10_POS_010_POLICY_BOUNDARY|M2_10_POS_021_REASON_BOUNDARY|M2_10_POS_056_PERFORMANCE_BOUNDARY_DECISION|M2_10_POS_057_PERFORMANCE_BOUNDARY_SYSTEM|M2_10_POS_058_PERFORMANCE_BOUNDARY_CONTACT|M2_10_NEG_002_ANALYTICS_BOUNDARY|M2_10_NEG_003_DECISION_BOUNDARY|M2_10_NEG_004_FUNDS_BOUNDARY|M2_10_NEG_005_SYSTEM_BOUNDARY|M2_10_NEG_006_CONTACT_BOUNDARY'::text,'M2_10_PORTFOLIO_ANALYTICS'::text),
    ('M2_11_ACCEPTANCE_SUMMARY'::text,'M2_11_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION'::text,'1'::text,'0'::text,'0'::text,'30_M2_11/10_live_execution_evidence/exports/MSBF_M2_11_Portfolio_Optimization_&_Strategy_Simulation_Detail_Report_v1_Blocking_And_Stage_Boundary_Violations_20260806.csv'::text,'6fe5fce149762a76e6b230832834471ba08efec6a7b2621fbe818a3c74025a1c'::text,'M2_11_%BOUNDARY%'::text,'M2_11_%BLOCKING%'::text,'72'::text,'12'::text,'msbf_ctl.m2_11_portfolio_strategy_contract_registry'::text,'PASS'::text,'6'::text,'M2_11_POS_009_POLICY_BOUNDARY|M2_11_POS_036_CONSTRAINT_BLOCKING|M2_11_POS_120_CANONICAL_BOUNDARY|M2_11_NEG_017_PRODUCTION_ACTION|M2_11_NEG_018_EXTERNAL_BEHAVIOR|M2_11_NEG_020_UNAUTHORIZED_STAGE_SOURCE'::text,'M2_11_STRATEGY_SIMULATION'::text)) AS v(acceptance_evidence_code,acceptance_gate_id,acceptance_gate_review_version,accepted_detail_actual_rows,accepted_detail_expected_rows,accepted_detail_report_authority_path,accepted_detail_report_sha256,boundary_pattern_1,boundary_pattern_2,matrix_sequence,certification_node_sequence,registry_relation,report_exists_status,required_evidence_code_count,required_evidence_codes,stage_code)
CROSS JOIN tmp_accept_m2_12_context ctx;

CREATE TEMP TABLE tmp_accept_m2_12_stage_boundary_base ON COMMIT DROP AS
WITH generic_required_evidence AS
(
    SELECT
        sbm.module1_run_id::bigint AS module1_run_id,
        sbm.node_sequence::smallint AS node_sequence,
        sbm.stage_code::text AS stage_code,
        e.evidence_code::text AS evidence_code,
        e.segment_key::text AS segment_key,
        e.metric_name::text AS metric_name,
        coalesce(e.metric_value_text,e.metric_value_numeric::text)::text AS observed_value_text,
        NULL::text AS expected_value_text,
        e.status::text AS evidence_status,
        'msbf_ctl.run_evidence'::text AS source_relation,
        md5(concat_ws('|',e.evidence_code,e.segment_key,e.metric_name,
                      coalesce(e.metric_value_text,e.metric_value_numeric::text),e.status))::text AS source_row_hash
    FROM tmp_accept_m2_12_stage_boundary_method sbm
    JOIN msbf_ctl.run_evidence e
      ON e.run_id=sbm.module1_run_id
     AND e.evidence_code=ANY(sbm.required_evidence_codes)
    WHERE sbm.node_sequence<>1
      AND NOT (sbm.node_sequence=4 AND e.evidence_code='M2_3_POLICY_BOUNDARY')
),
m117_required_evidence AS
(
    SELECT
        sbm.module1_run_id::bigint AS module1_run_id,
        sbm.node_sequence::smallint AS node_sequence,
        sbm.stage_code::text AS stage_code,
        e.evidence_code::text AS evidence_code,
        e.evidence_family::text AS segment_key,
        e.metric_name::text AS metric_name,
        e.observed_value_text::text AS observed_value_text,
        e.expected_value_text::text AS expected_value_text,
        CASE
            WHEN e.evidence_status='PASS'
             AND e.observed_value_text IS NOT DISTINCT FROM e.expected_value_text
             AND e.row_hash ~ '^[0-9a-f]{32}$'
            THEN 'PASS' ELSE 'FAIL'
        END::text AS evidence_status,
        'msbf_ctl.m1_17_end_to_end_evidence_snapshot'::text AS source_relation,
        e.row_hash::text AS source_row_hash
    FROM tmp_accept_m2_12_stage_boundary_method sbm
    JOIN msbf_ctl.m1_17_end_to_end_evidence_snapshot e
      ON e.module1_run_id=sbm.module1_run_id
     AND e.evidence_code=ANY(sbm.required_evidence_codes)
    WHERE sbm.node_sequence=1
),
m23_boundary_stats AS
(
    SELECT
        sbm.module1_run_id::bigint AS module1_run_id,
        sbm.node_sequence::smallint AS node_sequence,
        sbm.stage_code::text AS stage_code,
        (SELECT count(*)::integer
           FROM msbf_ctl.m2_3_final_decision_contract_registry r
          WHERE r.module1_run_id=sbm.module1_run_id
            AND r.contract_code='M2_FINAL_OFFER_DECISION_CONSUMPTION'
            AND r.contract_version=1
            AND r.contract_status='ACCEPTED') AS registry_rows,
        coalesce((SELECT min(r.decision_latest_rows)::bigint
                    FROM msbf_ctl.m2_3_final_decision_contract_registry r
                   WHERE r.module1_run_id=sbm.module1_run_id
                     AND r.contract_code='M2_FINAL_OFFER_DECISION_CONSUMPTION'
                     AND r.contract_version=1
                     AND r.contract_status='ACCEPTED'),-1::bigint) AS expected_latest_rows,
        coalesce((SELECT min(r.decision_archive_rows)::bigint
                    FROM msbf_ctl.m2_3_final_decision_contract_registry r
                   WHERE r.module1_run_id=sbm.module1_run_id
                     AND r.contract_code='M2_FINAL_OFFER_DECISION_CONSUMPTION'
                     AND r.contract_version=1
                     AND r.contract_status='ACCEPTED'),-1::bigint) AS expected_archive_rows,
        (SELECT count(*)::integer
           FROM msbf_m2.final_decision_reason_definition d
          WHERE d.module1_run_id=sbm.module1_run_id
            AND d.decision_reason_code='M2_3_POLICY_BOUNDARY') AS reason_definition_rows,
        (SELECT count(*)::integer
           FROM msbf_m2.final_decision_reason_definition d
          WHERE d.module1_run_id=sbm.module1_run_id
            AND d.decision_reason_code='M2_3_POLICY_BOUNDARY'
            AND d.mapped_decision_outcome_code='FINAL_OFFER_AUTHORIZED'
            AND d.production_adverse_action_notice_flag=false
            AND d.reason_status='APPROVED'
            AND d.row_hash ~ '^[0-9a-f]{32}$') AS approved_reason_definition_rows,
        (SELECT count(*)::bigint
           FROM msbf_m2.application_final_offer_decision_latest l
          WHERE l.module1_run_id=sbm.module1_run_id
            AND l.contract_code='M2_FINAL_OFFER_DECISION_CONSUMPTION'
            AND l.contract_version=1) AS observed_latest_rows,
        (SELECT count(*)::bigint
           FROM msbf_m2.application_final_offer_decision_latest l
          WHERE l.module1_run_id=sbm.module1_run_id
            AND l.contract_code='M2_FINAL_OFFER_DECISION_CONSUMPTION'
            AND l.contract_version=1
            AND l.decision_reason_codes ? 'M2_3_POLICY_BOUNDARY') AS latest_marker_rows,
        (SELECT count(*)::bigint
           FROM msbf_m2.application_final_offer_decision_archive a
          WHERE a.module1_run_id=sbm.module1_run_id
            AND a.contract_code='M2_FINAL_OFFER_DECISION_CONSUMPTION'
            AND a.contract_version=1) AS observed_archive_rows,
        (SELECT count(*)::bigint
           FROM msbf_m2.application_final_offer_decision_archive a
          WHERE a.module1_run_id=sbm.module1_run_id
            AND a.contract_code='M2_FINAL_OFFER_DECISION_CONSUMPTION'
            AND a.contract_version=1
            AND a.decision_reason_codes ? 'M2_3_POLICY_BOUNDARY') AS archive_marker_rows
    FROM tmp_accept_m2_12_stage_boundary_method sbm
    WHERE sbm.node_sequence=4
),
m23_boundary_evidence AS
(
    SELECT
        s.module1_run_id::bigint AS module1_run_id,
        s.node_sequence::smallint AS node_sequence,
        s.stage_code::text AS stage_code,
        'M2_3_POLICY_BOUNDARY'::text AS evidence_code,
        'PHYSICAL_BOUNDARY'::text AS segment_key,
        'M2_3_POLICY_BOUNDARY_PHYSICAL_RECONCILIATION'::text AS metric_name,
        format('registry=%s|reason=%s|approved_reason=%s|latest_expected=%s|latest_observed=%s|latest_marker=%s|archive_expected=%s|archive_observed=%s|archive_marker=%s',
               s.registry_rows,s.reason_definition_rows,s.approved_reason_definition_rows,
               s.expected_latest_rows,s.observed_latest_rows,s.latest_marker_rows,
               s.expected_archive_rows,s.observed_archive_rows,s.archive_marker_rows)::text AS observed_value_text,
        'registry=1|reason=1|approved_reason=1|latest_expected=1500|latest_observed=1500|latest_marker=1500|archive_expected=1500|archive_observed=1500|archive_marker=1500'::text AS expected_value_text,
        CASE
            WHEN s.registry_rows=1
             AND s.reason_definition_rows=1
             AND s.approved_reason_definition_rows=1
             AND s.expected_latest_rows=1500
             AND s.observed_latest_rows=s.expected_latest_rows
             AND s.latest_marker_rows=s.expected_latest_rows
             AND s.expected_archive_rows=1500
             AND s.observed_archive_rows=s.expected_archive_rows
             AND s.archive_marker_rows=s.expected_archive_rows
            THEN 'PASS' ELSE 'FAIL'
        END::text AS evidence_status,
        'msbf_ctl.m2_3_final_decision_contract_registry+msbf_m2.final_decision_reason_definition+msbf_m2.application_final_offer_decision_latest+msbf_m2.application_final_offer_decision_archive'::text AS source_relation,
        md5(concat_ws('|',s.registry_rows::text,s.reason_definition_rows::text,s.approved_reason_definition_rows::text,
                      s.expected_latest_rows::text,s.observed_latest_rows::text,s.latest_marker_rows::text,
                      s.expected_archive_rows::text,s.observed_archive_rows::text,s.archive_marker_rows::text))::text AS source_row_hash
    FROM m23_boundary_stats s
),
normalized_required_evidence AS
(
    SELECT * FROM generic_required_evidence
    UNION ALL
    SELECT * FROM m117_required_evidence
    UNION ALL
    SELECT * FROM m23_boundary_evidence
),
acceptance_summary_stats AS
(
    SELECT
        sbm.module1_run_id,
        sbm.node_sequence,
        (SELECT count(*)::integer
           FROM msbf_ctl.run_evidence e
          WHERE e.run_id=sbm.module1_run_id
            AND e.evidence_code=sbm.acceptance_evidence_code) AS acceptance_summary_rows,
        (SELECT count(*)::integer
           FROM msbf_ctl.run_evidence e
          WHERE e.run_id=sbm.module1_run_id
            AND e.evidence_code=sbm.acceptance_evidence_code
            AND e.status='PASS') AS acceptance_summary_pass_rows
    FROM tmp_accept_m2_12_stage_boundary_method sbm
),
normalized_stats AS
(
    SELECT
        n.module1_run_id,
        n.node_sequence,
        count(*)::integer AS physical_required_evidence_rows,
        count(DISTINCT n.evidence_code)::integer AS observed_required_evidence_rows,
        (count(*)-count(DISTINCT n.evidence_code))::integer AS duplicate_required_evidence_rows,
        count(*) FILTER (WHERE n.evidence_status<>'PASS')::integer AS nonpass_evidence_rows,
        coalesce(string_agg(n.evidence_code,'|' ORDER BY n.evidence_code)
                 FILTER (WHERE n.evidence_status<>'PASS'),'')::text AS nonpass_evidence_codes,
        string_agg(DISTINCT n.source_relation,'|' ORDER BY n.source_relation)::text AS source_relation_set,
        md5(coalesce(string_agg(concat_ws('|',n.evidence_code,n.segment_key,n.metric_name,
                                          n.observed_value_text,n.expected_value_text,n.evidence_status,
                                          n.source_relation,n.source_row_hash),
                                '|' ORDER BY n.evidence_code,n.source_relation,n.segment_key,n.metric_name),''))::text AS source_evidence_row_hash
    FROM normalized_required_evidence n
    GROUP BY n.module1_run_id,n.node_sequence
),
missing_stats AS
(
    SELECT
        sbm.module1_run_id,
        sbm.node_sequence,
        string_agg(req.evidence_code,'|' ORDER BY req.evidence_code)::text AS missing_required_evidence_codes
    FROM tmp_accept_m2_12_stage_boundary_method sbm
    CROSS JOIN LATERAL unnest(sbm.required_evidence_codes) AS req(evidence_code)
    WHERE NOT EXISTS
          (SELECT 1
             FROM normalized_required_evidence n
            WHERE n.module1_run_id=sbm.module1_run_id
              AND n.node_sequence=sbm.node_sequence
              AND n.evidence_code=req.evidence_code)
    GROUP BY sbm.module1_run_id,sbm.node_sequence
),
violation_evidence AS
(
    SELECT DISTINCT
        sbm.module1_run_id,
        sbm.node_sequence,
        e.evidence_code::text AS evidence_code,
        e.status::text AS evidence_status,
        'msbf_ctl.run_evidence'::text AS source_relation
    FROM tmp_accept_m2_12_stage_boundary_method sbm
    JOIN msbf_ctl.run_evidence e
      ON e.run_id=sbm.module1_run_id
     AND (e.evidence_code LIKE sbm.boundary_pattern_1 OR e.evidence_code LIKE sbm.boundary_pattern_2)
    WHERE e.status<>'PASS'
    UNION ALL
    SELECT DISTINCT
        sbm.module1_run_id,
        sbm.node_sequence,
        e.evidence_code::text,
        e.evidence_status::text,
        'msbf_ctl.m1_17_end_to_end_evidence_snapshot'::text
    FROM tmp_accept_m2_12_stage_boundary_method sbm
    JOIN msbf_ctl.m1_17_end_to_end_evidence_snapshot e
      ON e.module1_run_id=sbm.module1_run_id
     AND (e.evidence_code LIKE sbm.boundary_pattern_1 OR e.evidence_code LIKE sbm.boundary_pattern_2)
    WHERE sbm.node_sequence=1
      AND e.evidence_status<>'PASS'
    UNION ALL
    SELECT
        m.module1_run_id,
        m.node_sequence,
        m.evidence_code,
        m.evidence_status,
        m.source_relation
    FROM m23_boundary_evidence m
    WHERE m.evidence_status<>'PASS'
),
violation_stats AS
(
    SELECT
        v.module1_run_id,
        v.node_sequence,
        count(DISTINCT (v.source_relation,v.evidence_code))::integer AS violation_rows,
        string_agg(DISTINCT v.source_relation||':'||v.evidence_code,'|' ORDER BY v.source_relation||':'||v.evidence_code)::text AS violation_evidence_codes
    FROM violation_evidence v
    GROUP BY v.module1_run_id,v.node_sequence
)
SELECT
       sbm.accepted_detail_actual_rows::integer AS accepted_detail_actual_rows,
       (sbm.report_exists_status='PASS')::boolean AS accepted_detail_report_exists_flag,
       sbm.accepted_detail_report_sha256::text AS accepted_detail_report_sha256,
       ast.acceptance_summary_rows::integer AS acceptance_summary_rows,
       ast.acceptance_summary_pass_rows::integer AS acceptance_summary_pass_rows,
       (ast.acceptance_summary_rows=1
        AND ast.acceptance_summary_pass_rows=1
        AND coalesce(ns.physical_required_evidence_rows,0)=sbm.required_evidence_code_count
        AND coalesce(ns.observed_required_evidence_rows,0)=sbm.required_evidence_code_count
        AND coalesce(ns.duplicate_required_evidence_rows,0)=0
        AND coalesce(ms.missing_required_evidence_codes,'')='')::boolean AS governing_source_present_flag,
       sbm.matrix_sequence::smallint AS matrix_sequence,
       coalesce(ms.missing_required_evidence_codes,'')::text AS missing_required_evidence_codes,
       sbm.module1_run_id::bigint AS module1_run_id,
       sbm.node_sequence::smallint AS node_sequence,
       coalesce(ns.nonpass_evidence_codes,'')::text AS nonpass_evidence_codes,
       coalesce(ns.nonpass_evidence_rows,0)::integer AS nonpass_evidence_rows,
       coalesce(ns.observed_required_evidence_rows,0)::integer AS observed_required_evidence_rows,
       coalesce(ns.physical_required_evidence_rows,0)::integer AS physical_required_evidence_rows,
       coalesce(ns.duplicate_required_evidence_rows,0)::integer AS duplicate_required_evidence_rows,
       sbm.required_evidence_code_count::integer AS required_evidence_rows,
       coalesce(ns.source_evidence_row_hash,md5(''))::text AS source_evidence_row_hash,
       coalesce(ns.source_relation_set,'')::text AS source_relation_set,
       sbm.stage_code::text AS stage_code,
       coalesce(vs.violation_evidence_codes,'')::text AS violation_evidence_codes,
       coalesce(vs.violation_rows,0)::integer AS violation_rows
FROM tmp_accept_m2_12_context ctx
JOIN tmp_accept_m2_12_stage_boundary_method sbm
  ON sbm.module1_run_id=ctx.module1_run_id
JOIN acceptance_summary_stats ast
  ON ast.module1_run_id=sbm.module1_run_id
 AND ast.node_sequence=sbm.node_sequence
LEFT JOIN normalized_stats ns
  ON ns.module1_run_id=sbm.module1_run_id
 AND ns.node_sequence=sbm.node_sequence
LEFT JOIN missing_stats ms
  ON ms.module1_run_id=sbm.module1_run_id
 AND ms.node_sequence=sbm.node_sequence
LEFT JOIN violation_stats vs
  ON vs.module1_run_id=sbm.module1_run_id
 AND vs.node_sequence=sbm.node_sequence;

DO $m212_225_hf15_stage_boundary_base_assert$
BEGIN
    IF NOT coalesce(
        (SELECT count(*)=12
             AND count(DISTINCT (module1_run_id,matrix_sequence))=12
             AND count(DISTINCT node_sequence)=12
             AND min(node_sequence)=1
             AND max(node_sequence)=12
             AND sum(required_evidence_rows)=70
         FROM tmp_accept_m2_12_stage_boundary_base),false)
    THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 P223 HF12 verifier stage-boundary observation-base structural mismatch',
            DETAIL=format('rows=%s distinct_matrix=%s distinct_nodes=%s required_controls=%s',
                          (SELECT count(*) FROM tmp_accept_m2_12_stage_boundary_base),
                          (SELECT count(DISTINCT (module1_run_id,matrix_sequence)) FROM tmp_accept_m2_12_stage_boundary_base),
                          (SELECT count(DISTINCT node_sequence) FROM tmp_accept_m2_12_stage_boundary_base),
                          (SELECT coalesce(sum(required_evidence_rows),0) FROM tmp_accept_m2_12_stage_boundary_base));
    END IF;
END;
$m212_225_hf15_stage_boundary_base_assert$;

CREATE TEMP TABLE tmp_accept_m2_12_stage_boundary ON COMMIT DROP AS
SELECT
       CASE
           WHEN sbb.governing_source_present_flag
            AND sbb.accepted_detail_report_exists_flag
            AND sbb.accepted_detail_actual_rows=0
            AND sbb.acceptance_summary_rows=1
            AND sbb.acceptance_summary_pass_rows=1
            AND sbb.physical_required_evidence_rows=sbb.required_evidence_rows
            AND sbb.observed_required_evidence_rows=sbb.required_evidence_rows
            AND sbb.duplicate_required_evidence_rows=0
            AND sbb.missing_required_evidence_codes=''
            AND sbb.nonpass_evidence_rows=0
            AND sbb.violation_rows=0
           THEN 'PASS' ELSE 'FAIL'
       END::text AS certification_status,
       sbb.governing_source_present_flag::boolean AS governing_source_present_flag,
       sbb.matrix_sequence::smallint AS matrix_sequence,
       sbb.module1_run_id::bigint AS module1_run_id,
       sbb.node_sequence::smallint AS node_sequence,
       sbb.nonpass_evidence_rows::integer AS nonpass_evidence_rows,
       format('required=%s; physical=%s; distinct=%s; duplicates=%s; missing=%s; nonpass=%s; violations=%s; acceptance=%s/%s; report_rows=%s',
              sbb.required_evidence_rows,sbb.physical_required_evidence_rows,sbb.observed_required_evidence_rows,
              sbb.duplicate_required_evidence_rows,coalesce(nullif(sbb.missing_required_evidence_codes,''),'<NONE>'),
              sbb.nonpass_evidence_rows,sbb.violation_rows,sbb.acceptance_summary_pass_rows,sbb.acceptance_summary_rows,
              sbb.accepted_detail_actual_rows)::text AS observed_count_or_identity,
       md5(concat_ws('|',sbb.stage_code,sbb.accepted_detail_report_sha256,
                     sbb.acceptance_summary_rows::text,sbb.acceptance_summary_pass_rows::text,
                     sbb.required_evidence_rows::text,sbb.physical_required_evidence_rows::text,
                     sbb.observed_required_evidence_rows::text,sbb.duplicate_required_evidence_rows::text,
                     sbb.missing_required_evidence_codes,sbb.nonpass_evidence_rows::text,sbb.nonpass_evidence_codes,
                     sbb.violation_rows::text,sbb.violation_evidence_codes,sbb.source_relation_set,
                     sbb.source_evidence_row_hash))::text AS observed_hash,
       sbb.observed_required_evidence_rows::integer AS observed_required_evidence_rows,
       CASE
           WHEN sbb.governing_source_present_flag
            AND sbb.accepted_detail_report_exists_flag
            AND sbb.accepted_detail_actual_rows=0
            AND sbb.acceptance_summary_rows=1
            AND sbb.acceptance_summary_pass_rows=1
            AND sbb.physical_required_evidence_rows=sbb.required_evidence_rows
            AND sbb.observed_required_evidence_rows=sbb.required_evidence_rows
            AND sbb.duplicate_required_evidence_rows=0
            AND sbb.missing_required_evidence_codes=''
            AND sbb.nonpass_evidence_rows=0
            AND sbb.violation_rows=0
           THEN 'PASS' ELSE 'FAIL'
       END::text AS observed_status,
       sbb.required_evidence_rows::integer AS required_evidence_rows,
       sbb.source_evidence_row_hash::text AS source_evidence_row_hash,
       sbb.stage_code::text AS stage_code,
       sbb.violation_rows::integer AS violation_rows,
       sbb.acceptance_summary_rows::integer AS acceptance_summary_rows,
       sbb.acceptance_summary_pass_rows::integer AS acceptance_summary_pass_rows,
       sbb.physical_required_evidence_rows::integer AS physical_required_evidence_rows,
       sbb.duplicate_required_evidence_rows::integer AS duplicate_required_evidence_rows,
       sbb.missing_required_evidence_codes::text AS missing_required_evidence_codes,
       sbb.nonpass_evidence_codes::text AS nonpass_evidence_codes,
       sbb.violation_evidence_codes::text AS violation_evidence_codes,
       sbb.source_relation_set::text AS source_relation_set
FROM tmp_accept_m2_12_context ctx
JOIN tmp_accept_m2_12_stage_boundary_base sbb
  ON sbb.module1_run_id=ctx.module1_run_id;

DO $m212_225_hf15_stage_boundary_assert$
BEGIN
    IF NOT coalesce(
        (SELECT count(*)=12
             AND count(DISTINCT (module1_run_id,matrix_sequence))=12
             AND count(DISTINCT node_sequence)=12
             AND min(node_sequence)=1
             AND max(node_sequence)=12
             AND bool_and(certification_status='PASS')
         FROM tmp_accept_m2_12_stage_boundary),false)
    THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 P223 HF12 verifier stage-boundary certification mismatch',
            DETAIL=coalesce(
                (SELECT string_agg(
                    'node='||node_sequence::text||':'||stage_code||
                    '|status='||coalesce(certification_status,'<NULL>')||
                    '|acceptance='||acceptance_summary_pass_rows::text||'/'||acceptance_summary_rows::text||
                    '|required='||required_evidence_rows::text||
                    '|physical='||physical_required_evidence_rows::text||
                    '|distinct='||observed_required_evidence_rows::text||
                    '|duplicates='||duplicate_required_evidence_rows::text||
                    '|missing='||coalesce(nullif(missing_required_evidence_codes,''),'<NONE>')||
                    '|nonpass='||coalesce(nullif(nonpass_evidence_codes,''),'<NONE>')||
                    '|violations='||coalesce(nullif(violation_evidence_codes,''),'<NONE>')||
                    '|sources='||coalesce(nullif(source_relation_set,''),'<NONE>'),
                    '; ' ORDER BY node_sequence)
                 FROM tmp_accept_m2_12_stage_boundary
                 WHERE certification_status IS DISTINCT FROM 'PASS'),
                'rows='||(SELECT count(*) FROM tmp_accept_m2_12_stage_boundary)::text);
    END IF;
END;
$m212_225_hf15_stage_boundary_assert$;

CREATE TEMP TABLE tmp_hash_m2_12_acceptance_reconciliation ON COMMIT DROP AS
SELECT
       p.module1_run_id::bigint AS module1_run_id,
       p.family_count_mismatch_count::bigint AS family_count_mismatch_count,
       p.row_hash_mismatch_count::bigint AS row_hash_mismatch_count,
       p.set_hash_mismatch_count::bigint AS set_hash_mismatch_count,
       p.contract_hash_mismatch_count::integer AS contract_hash_mismatch_count,
       p.combined_hash_mismatch_count::integer AS combined_hash_mismatch_count,
       p.sequence_state_mismatch_count::integer AS sequence_state_mismatch_count,
       p.canonical_families::integer AS canonical_families,
       p.canonical_entities::integer AS canonical_entities,
       p.total_mismatch_count::bigint AS total_mismatch_count,
       CASE WHEN p.total_mismatch_count=0 THEN 'PASS'::text ELSE 'FAIL'::text END AS reconciliation_status
FROM (
WITH row_detail AS ((SELECT 'POLICY'::text AS family_code, 1::bigint AS expected_rows, count(*)::bigint AS observed_rows, (count(*)<>1)::integer AS family_count_mismatch_count, count(*) FILTER (WHERE t.row_hash IS DISTINCT FROM md5((to_jsonb(t)-'policy_profile_id'-'row_hash'-'created_at'-'updated_at')::text))::bigint AS row_hash_mismatch_count FROM msbf_ctl.m2_12_policy_profile t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id) UNION ALL (SELECT 'STAGE_CERTIFICATION'::text AS family_code, 12::bigint AS expected_rows, count(*)::bigint AS observed_rows, (count(*)<>12)::integer AS family_count_mismatch_count, count(*) FILTER (WHERE t.row_hash IS DISTINCT FROM md5((to_jsonb(t)-'row_hash'-'created_at')::text))::bigint AS row_hash_mismatch_count FROM msbf_m2.module2_stage_certification_snapshot t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id) UNION ALL (SELECT 'CONTRACT_COMPONENT'::text AS family_code, 13::bigint AS expected_rows, count(*)::bigint AS observed_rows, (count(*)<>13)::integer AS family_count_mismatch_count, count(*) FILTER (WHERE t.row_hash IS DISTINCT FROM md5((to_jsonb(t)-'row_hash'-'created_at')::text))::bigint AS row_hash_mismatch_count FROM msbf_m2.module2_contract_component_snapshot t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id) UNION ALL (SELECT 'EVIDENCE_CERTIFICATION'::text AS family_code, 72::bigint AS expected_rows, count(*)::bigint AS observed_rows, (count(*)<>72)::integer AS family_count_mismatch_count, count(*) FILTER (WHERE t.row_hash IS DISTINCT FROM md5((to_jsonb(t)-'row_hash'-'created_at')::text))::bigint AS row_hash_mismatch_count FROM msbf_m2.module2_evidence_certification_snapshot t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id) UNION ALL (SELECT 'CONTRACT_REPRODUCTION'::text AS family_code, 13::bigint AS expected_rows, count(*)::bigint AS observed_rows, (count(*)<>13)::integer AS family_count_mismatch_count, count(*) FILTER (WHERE t.row_hash IS DISTINCT FROM md5((to_jsonb(t)-'row_hash'-'created_at')::text))::bigint AS row_hash_mismatch_count FROM msbf_m2.module2_contract_reproduction_snapshot t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id) UNION ALL (SELECT 'CAPABILITY_COVERAGE'::text AS family_code, 20::bigint AS expected_rows, count(*)::bigint AS observed_rows, (count(*)<>20)::integer AS family_count_mismatch_count, count(*) FILTER (WHERE t.row_hash IS DISTINCT FROM md5((to_jsonb(t)-'row_hash'-'created_at')::text))::bigint AS row_hash_mismatch_count FROM msbf_m2.module2_capability_coverage_snapshot t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id) UNION ALL (SELECT 'LATEST'::text AS family_code, 1::bigint AS expected_rows, count(*)::bigint AS observed_rows, (count(*)<>1)::integer AS family_count_mismatch_count, count(*) FILTER (WHERE t.row_hash IS DISTINCT FROM md5((to_jsonb(t)-'row_hash'-'created_at')::text))::bigint AS row_hash_mismatch_count FROM msbf_ctl.m2_12_g3_bundle_latest t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id) UNION ALL (SELECT 'ARCHIVE'::text AS family_code, 1::bigint AS expected_rows, count(*)::bigint AS observed_rows, (count(*)<>1)::integer AS family_count_mismatch_count, count(*) FILTER (WHERE t.archive_row_hash IS DISTINCT FROM md5((to_jsonb(t)-'archive_id'-'archive_row_hash'-'created_at')::text))::bigint AS row_hash_mismatch_count FROM msbf_ctl.m2_12_g3_bundle_archive t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id) UNION ALL (SELECT 'REGISTRY'::text AS family_code, 1::bigint AS expected_rows, count(*)::bigint AS observed_rows, (count(*)<>1)::integer AS family_count_mismatch_count, count(*) FILTER (WHERE t.row_hash IS DISTINCT FROM md5((to_jsonb(t)-'registry_id'-'contract_status'-'generated_at'-'validated_at'-'accepted_at'-'created_at'-'updated_at'-'row_hash'-'policy_set_hash'-'stage_certification_set_hash'-'contract_component_set_hash'-'evidence_certification_set_hash'-'contract_reproduction_set_hash'-'capability_coverage_set_hash'-'latest_set_hash'-'archive_set_hash'-'registry_set_hash'-'contract_set_hash'-'combined_set_hash')::text))::bigint AS row_hash_mismatch_count FROM msbf_ctl.m2_12_g3_bundle_registry t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id)),
rowd AS (SELECT sum(family_count_mismatch_count)::bigint family_count_mismatch_count,sum(row_hash_mismatch_count)::bigint row_hash_mismatch_count FROM row_detail),
set_detail AS ((SELECT 'POLICY'::text AS family_code, md5(string_agg(concat_ws('|',t.policy_code::text,t.policy_version::text,t.row_hash::text),'|' ORDER BY t.policy_code, t.policy_version))::text AS reconstructed_set_hash, r.policy_set_hash::text AS stored_set_hash, (md5(string_agg(concat_ws('|',t.policy_code::text,t.policy_version::text,t.row_hash::text),'|' ORDER BY t.policy_code, t.policy_version)) IS DISTINCT FROM r.policy_set_hash)::integer AS set_hash_mismatch_count FROM msbf_ctl.m2_12_policy_profile t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1 GROUP BY r.policy_set_hash) UNION ALL (SELECT 'STAGE_CERTIFICATION'::text AS family_code, md5(string_agg(concat_ws('|',t.certification_node_sequence::text,t.stage_code::text,t.row_hash::text),'|' ORDER BY t.certification_node_sequence, t.stage_code))::text AS reconstructed_set_hash, r.stage_certification_set_hash::text AS stored_set_hash, (md5(string_agg(concat_ws('|',t.certification_node_sequence::text,t.stage_code::text,t.row_hash::text),'|' ORDER BY t.certification_node_sequence, t.stage_code)) IS DISTINCT FROM r.stage_certification_set_hash)::integer AS set_hash_mismatch_count FROM msbf_m2.module2_stage_certification_snapshot t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1 GROUP BY r.stage_certification_set_hash) UNION ALL (SELECT 'CONTRACT_COMPONENT'::text AS family_code, md5(string_agg(concat_ws('|',t.component_sequence::text,t.component_contract_code::text,t.contract_version::text,t.row_hash::text),'|' ORDER BY t.component_sequence, t.component_contract_code, t.contract_version))::text AS reconstructed_set_hash, r.contract_component_set_hash::text AS stored_set_hash, (md5(string_agg(concat_ws('|',t.component_sequence::text,t.component_contract_code::text,t.contract_version::text,t.row_hash::text),'|' ORDER BY t.component_sequence, t.component_contract_code, t.contract_version)) IS DISTINCT FROM r.contract_component_set_hash)::integer AS set_hash_mismatch_count FROM msbf_m2.module2_contract_component_snapshot t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1 GROUP BY r.contract_component_set_hash) UNION ALL (SELECT 'EVIDENCE_CERTIFICATION'::text AS family_code, md5(string_agg(concat_ws('|',t.node_sequence::text,t.evidence_family_sequence::text,t.row_hash::text),'|' ORDER BY t.node_sequence, t.evidence_family_sequence))::text AS reconstructed_set_hash, r.evidence_certification_set_hash::text AS stored_set_hash, (md5(string_agg(concat_ws('|',t.node_sequence::text,t.evidence_family_sequence::text,t.row_hash::text),'|' ORDER BY t.node_sequence, t.evidence_family_sequence)) IS DISTINCT FROM r.evidence_certification_set_hash)::integer AS set_hash_mismatch_count FROM msbf_m2.module2_evidence_certification_snapshot t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1 GROUP BY r.evidence_certification_set_hash) UNION ALL (SELECT 'CONTRACT_REPRODUCTION'::text AS family_code, md5(string_agg(concat_ws('|',t.component_sequence::text,t.component_contract_code::text,t.contract_version::text,t.row_hash::text),'|' ORDER BY t.component_sequence, t.component_contract_code, t.contract_version))::text AS reconstructed_set_hash, r.contract_reproduction_set_hash::text AS stored_set_hash, (md5(string_agg(concat_ws('|',t.component_sequence::text,t.component_contract_code::text,t.contract_version::text,t.row_hash::text),'|' ORDER BY t.component_sequence, t.component_contract_code, t.contract_version)) IS DISTINCT FROM r.contract_reproduction_set_hash)::integer AS set_hash_mismatch_count FROM msbf_m2.module2_contract_reproduction_snapshot t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1 GROUP BY r.contract_reproduction_set_hash) UNION ALL (SELECT 'CAPABILITY_COVERAGE'::text AS family_code, md5(string_agg(concat_ws('|',t.capability_sequence::text,t.capability_code::text,t.row_hash::text),'|' ORDER BY t.capability_sequence, t.capability_code))::text AS reconstructed_set_hash, r.capability_coverage_set_hash::text AS stored_set_hash, (md5(string_agg(concat_ws('|',t.capability_sequence::text,t.capability_code::text,t.row_hash::text),'|' ORDER BY t.capability_sequence, t.capability_code)) IS DISTINCT FROM r.capability_coverage_set_hash)::integer AS set_hash_mismatch_count FROM msbf_m2.module2_capability_coverage_snapshot t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1 GROUP BY r.capability_coverage_set_hash) UNION ALL (SELECT 'LATEST'::text AS family_code, md5(string_agg(concat_ws('|',t.bundle_code::text,t.contract_version::text,t.row_hash::text),'|' ORDER BY t.bundle_code, t.contract_version))::text AS reconstructed_set_hash, r.latest_set_hash::text AS stored_set_hash, (md5(string_agg(concat_ws('|',t.bundle_code::text,t.contract_version::text,t.row_hash::text),'|' ORDER BY t.bundle_code, t.contract_version)) IS DISTINCT FROM r.latest_set_hash)::integer AS set_hash_mismatch_count FROM msbf_ctl.m2_12_g3_bundle_latest t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1 GROUP BY r.latest_set_hash) UNION ALL (SELECT 'ARCHIVE'::text AS family_code, md5(string_agg(concat_ws('|',t.bundle_code::text,t.contract_version::text,t.archive_row_hash::text),'|' ORDER BY t.bundle_code, t.contract_version))::text AS reconstructed_set_hash, r.archive_set_hash::text AS stored_set_hash, (md5(string_agg(concat_ws('|',t.bundle_code::text,t.contract_version::text,t.archive_row_hash::text),'|' ORDER BY t.bundle_code, t.contract_version)) IS DISTINCT FROM r.archive_set_hash)::integer AS set_hash_mismatch_count FROM msbf_ctl.m2_12_g3_bundle_archive t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1 GROUP BY r.archive_set_hash) UNION ALL (SELECT 'REGISTRY'::text AS family_code, md5(string_agg(concat_ws('|',t.bundle_code::text,t.contract_version::text,t.row_hash::text),'|' ORDER BY t.bundle_code, t.contract_version))::text AS reconstructed_set_hash, r.registry_set_hash::text AS stored_set_hash, (md5(string_agg(concat_ws('|',t.bundle_code::text,t.contract_version::text,t.row_hash::text),'|' ORDER BY t.bundle_code, t.contract_version)) IS DISTINCT FROM r.registry_set_hash)::integer AS set_hash_mismatch_count FROM msbf_ctl.m2_12_g3_bundle_registry t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1 GROUP BY r.registry_set_hash)),
setd AS (SELECT sum(set_hash_mismatch_count)::bigint set_hash_mismatch_count FROM set_detail),
ch AS (SELECT r.module1_run_id,
       md5(concat_ws('|',r.bundle_code::text,r.contract_version::text,r.schema_version::text,r.methodology_version::text,r.policy_configuration_hash::text,r.policy_set_hash::text,r.stage_certification_set_hash::text,r.contract_component_set_hash::text,r.evidence_certification_set_hash::text,r.contract_reproduction_set_hash::text,r.capability_coverage_set_hash::text,r.latest_set_hash::text,r.archive_set_hash::text,r.registry_set_hash::text,r.latest_contract_row_hash::text,r.archive_contract_row_hash::text,r.row_hash::text,r.accepted_m2_11_contract_set_hash::text,r.accepted_m2_11_combined_set_hash::text,r.accepted_m2_11_registry_row_hash::text))::text AS reconstructed_contract_set_hash,
       r.contract_set_hash::text AS stored_contract_set_hash,
       (md5(concat_ws('|',r.bundle_code::text,r.contract_version::text,r.schema_version::text,r.methodology_version::text,r.policy_configuration_hash::text,r.policy_set_hash::text,r.stage_certification_set_hash::text,r.contract_component_set_hash::text,r.evidence_certification_set_hash::text,r.contract_reproduction_set_hash::text,r.capability_coverage_set_hash::text,r.latest_set_hash::text,r.archive_set_hash::text,r.registry_set_hash::text,r.latest_contract_row_hash::text,r.archive_contract_row_hash::text,r.row_hash::text,r.accepted_m2_11_contract_set_hash::text,r.accepted_m2_11_combined_set_hash::text,r.accepted_m2_11_registry_row_hash::text)) IS DISTINCT FROM r.contract_set_hash)::integer AS contract_hash_mismatch_count
FROM msbf_ctl.m2_12_g3_bundle_registry r
JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=r.module1_run_id
WHERE r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1), cb AS (SELECT u.module1_run_id, count(*)::integer AS canonical_entities, count(DISTINCT u.entity_type)::integer AS canonical_families, md5(string_agg(u.entity_type||'|'||u.entity_key||'|'||u.row_hash,'|' ORDER BY u.entity_type,u.entity_key))::text AS reconstructed_combined_set_hash, r.combined_set_hash::text AS stored_combined_set_hash, (md5(string_agg(u.entity_type||'|'||u.entity_key||'|'||u.row_hash,'|' ORDER BY u.entity_type,u.entity_key)) IS DISTINCT FROM r.combined_set_hash)::integer AS combined_hash_mismatch_count FROM (SELECT t.module1_run_id, 'POLICY'::text AS entity_type, concat_ws('|',t.policy_code::text,t.policy_version::text)::text AS entity_key, t.row_hash::text AS row_hash FROM msbf_ctl.m2_12_policy_profile t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT t.module1_run_id, 'STAGE_CERTIFICATION'::text AS entity_type, concat_ws('|',t.certification_node_sequence::text,t.stage_code::text)::text AS entity_key, t.row_hash::text AS row_hash FROM msbf_m2.module2_stage_certification_snapshot t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT t.module1_run_id, 'CONTRACT_COMPONENT'::text AS entity_type, concat_ws('|',t.component_sequence::text,t.component_contract_code::text,t.contract_version::text)::text AS entity_key, t.row_hash::text AS row_hash FROM msbf_m2.module2_contract_component_snapshot t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT t.module1_run_id, 'EVIDENCE_CERTIFICATION'::text AS entity_type, concat_ws('|',t.node_sequence::text,t.evidence_family_sequence::text)::text AS entity_key, t.row_hash::text AS row_hash FROM msbf_m2.module2_evidence_certification_snapshot t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT t.module1_run_id, 'CONTRACT_REPRODUCTION'::text AS entity_type, concat_ws('|',t.component_sequence::text,t.component_contract_code::text,t.contract_version::text)::text AS entity_key, t.row_hash::text AS row_hash FROM msbf_m2.module2_contract_reproduction_snapshot t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT t.module1_run_id, 'CAPABILITY_COVERAGE'::text AS entity_type, concat_ws('|',t.capability_sequence::text,t.capability_code::text)::text AS entity_key, t.row_hash::text AS row_hash FROM msbf_m2.module2_capability_coverage_snapshot t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT t.module1_run_id, 'LATEST'::text AS entity_type, concat_ws('|',t.bundle_code::text,t.contract_version::text)::text AS entity_key, t.row_hash::text AS row_hash FROM msbf_ctl.m2_12_g3_bundle_latest t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT t.module1_run_id, 'ARCHIVE'::text AS entity_type, concat_ws('|',t.bundle_code::text,t.contract_version::text)::text AS entity_key, t.archive_row_hash::text AS row_hash FROM msbf_ctl.m2_12_g3_bundle_archive t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT t.module1_run_id, 'REGISTRY'::text AS entity_type, concat_ws('|',t.bundle_code::text,t.contract_version::text)::text AS entity_key, t.row_hash::text AS row_hash FROM msbf_ctl.m2_12_g3_bundle_registry t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id) u JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=u.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1 GROUP BY u.module1_run_id,r.combined_set_hash), seq AS (SELECT ctx.module1_run_id,
       p.last_value::bigint AS policy_last_value,p.is_called AS policy_is_called,
       a.last_value::bigint AS archive_last_value,a.is_called AS archive_is_called,
       r.last_value::bigint AS registry_last_value,r.is_called AS registry_is_called,
       ((p.last_value<>1 OR NOT p.is_called)::integer
        +(a.last_value<>1 OR NOT a.is_called)::integer
        +(r.last_value<>1 OR NOT r.is_called)::integer)::integer AS sequence_state_mismatch_count
FROM tmp_accept_m2_12_context ctx
CROSS JOIN msbf_ctl.m2_12_policy_profile_policy_profile_id_seq p
CROSS JOIN msbf_ctl.m2_12_g3_bundle_archive_archive_id_seq a
CROSS JOIN msbf_ctl.m2_12_g3_bundle_registry_registry_id_seq r)
SELECT ctx.module1_run_id,
       rowd.family_count_mismatch_count,rowd.row_hash_mismatch_count,setd.set_hash_mismatch_count,
       ch.contract_hash_mismatch_count::integer,cb.combined_hash_mismatch_count::integer,
       seq.sequence_state_mismatch_count::integer,cb.canonical_families::integer,cb.canonical_entities::integer,
       (rowd.family_count_mismatch_count+rowd.row_hash_mismatch_count+setd.set_hash_mismatch_count+ch.contract_hash_mismatch_count+cb.combined_hash_mismatch_count+seq.sequence_state_mismatch_count)::bigint AS total_mismatch_count
FROM tmp_accept_m2_12_context ctx CROSS JOIN rowd CROSS JOIN setd CROSS JOIN ch CROSS JOIN cb CROSS JOIN seq
) p;
CREATE UNIQUE INDEX ux_tmp_hash_m2_12_acceptance_reconciliation ON tmp_hash_m2_12_acceptance_reconciliation(module1_run_id);
ANALYZE tmp_hash_m2_12_acceptance_reconciliation;

    CREATE TEMP TABLE tmp_hash_m2_12_acceptance_detail ON COMMIT DROP AS
    SELECT 1::smallint AS hash_sequence, 'POLICY_SET_HASH'::text AS hash_code,
       r.policy_set_hash::text AS stored_hash,
       md5(string_agg(concat_ws('|',t.policy_code::text,t.policy_version::text,t.row_hash::text),'|' ORDER BY t.policy_code,t.policy_version))::text AS reconstructed_hash,
       (r.policy_set_hash IS DISTINCT FROM md5(string_agg(concat_ws('|',t.policy_code::text,t.policy_version::text,t.row_hash::text),'|' ORDER BY t.policy_code,t.policy_version))) AS mismatch_flag,
       'msbf_ctl.m2_12_policy_profile'::text AS authoritative_source,
       'policy_code,policy_version'::text AS ordered_business_key
FROM msbf_ctl.m2_12_policy_profile t
JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id
JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1
GROUP BY r.policy_set_hash
UNION ALL
SELECT 2::smallint AS hash_sequence, 'STAGE_CERTIFICATION_SET_HASH'::text AS hash_code,
       r.stage_certification_set_hash::text AS stored_hash,
       md5(string_agg(concat_ws('|',t.certification_node_sequence::text,t.stage_code::text,t.row_hash::text),'|' ORDER BY t.certification_node_sequence,t.stage_code))::text AS reconstructed_hash,
       (r.stage_certification_set_hash IS DISTINCT FROM md5(string_agg(concat_ws('|',t.certification_node_sequence::text,t.stage_code::text,t.row_hash::text),'|' ORDER BY t.certification_node_sequence,t.stage_code))) AS mismatch_flag,
       'msbf_m2.module2_stage_certification_snapshot'::text AS authoritative_source,
       'certification_node_sequence,stage_code'::text AS ordered_business_key
FROM msbf_m2.module2_stage_certification_snapshot t
JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id
JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1
GROUP BY r.stage_certification_set_hash
UNION ALL
SELECT 3::smallint AS hash_sequence, 'CONTRACT_COMPONENT_SET_HASH'::text AS hash_code,
       r.contract_component_set_hash::text AS stored_hash,
       md5(string_agg(concat_ws('|',t.component_sequence::text,t.component_contract_code::text,t.contract_version::text,t.row_hash::text),'|' ORDER BY t.component_sequence,t.component_contract_code,t.contract_version))::text AS reconstructed_hash,
       (r.contract_component_set_hash IS DISTINCT FROM md5(string_agg(concat_ws('|',t.component_sequence::text,t.component_contract_code::text,t.contract_version::text,t.row_hash::text),'|' ORDER BY t.component_sequence,t.component_contract_code,t.contract_version))) AS mismatch_flag,
       'msbf_m2.module2_contract_component_snapshot'::text AS authoritative_source,
       'component_sequence,component_contract_code,contract_version'::text AS ordered_business_key
FROM msbf_m2.module2_contract_component_snapshot t
JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id
JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1
GROUP BY r.contract_component_set_hash
UNION ALL
SELECT 4::smallint AS hash_sequence, 'EVIDENCE_CERTIFICATION_SET_HASH'::text AS hash_code,
       r.evidence_certification_set_hash::text AS stored_hash,
       md5(string_agg(concat_ws('|',t.node_sequence::text,t.evidence_family_sequence::text,t.row_hash::text),'|' ORDER BY t.node_sequence,t.evidence_family_sequence))::text AS reconstructed_hash,
       (r.evidence_certification_set_hash IS DISTINCT FROM md5(string_agg(concat_ws('|',t.node_sequence::text,t.evidence_family_sequence::text,t.row_hash::text),'|' ORDER BY t.node_sequence,t.evidence_family_sequence))) AS mismatch_flag,
       'msbf_m2.module2_evidence_certification_snapshot'::text AS authoritative_source,
       'node_sequence,evidence_family_sequence'::text AS ordered_business_key
FROM msbf_m2.module2_evidence_certification_snapshot t
JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id
JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1
GROUP BY r.evidence_certification_set_hash
UNION ALL
SELECT 5::smallint AS hash_sequence, 'CONTRACT_REPRODUCTION_SET_HASH'::text AS hash_code,
       r.contract_reproduction_set_hash::text AS stored_hash,
       md5(string_agg(concat_ws('|',t.component_sequence::text,t.component_contract_code::text,t.contract_version::text,t.row_hash::text),'|' ORDER BY t.component_sequence,t.component_contract_code,t.contract_version))::text AS reconstructed_hash,
       (r.contract_reproduction_set_hash IS DISTINCT FROM md5(string_agg(concat_ws('|',t.component_sequence::text,t.component_contract_code::text,t.contract_version::text,t.row_hash::text),'|' ORDER BY t.component_sequence,t.component_contract_code,t.contract_version))) AS mismatch_flag,
       'msbf_m2.module2_contract_reproduction_snapshot'::text AS authoritative_source,
       'component_sequence,component_contract_code,contract_version'::text AS ordered_business_key
FROM msbf_m2.module2_contract_reproduction_snapshot t
JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id
JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1
GROUP BY r.contract_reproduction_set_hash
UNION ALL
SELECT 6::smallint AS hash_sequence, 'CAPABILITY_COVERAGE_SET_HASH'::text AS hash_code,
       r.capability_coverage_set_hash::text AS stored_hash,
       md5(string_agg(concat_ws('|',t.capability_sequence::text,t.capability_code::text,t.row_hash::text),'|' ORDER BY t.capability_sequence,t.capability_code))::text AS reconstructed_hash,
       (r.capability_coverage_set_hash IS DISTINCT FROM md5(string_agg(concat_ws('|',t.capability_sequence::text,t.capability_code::text,t.row_hash::text),'|' ORDER BY t.capability_sequence,t.capability_code))) AS mismatch_flag,
       'msbf_m2.module2_capability_coverage_snapshot'::text AS authoritative_source,
       'capability_sequence,capability_code'::text AS ordered_business_key
FROM msbf_m2.module2_capability_coverage_snapshot t
JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id
JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1
GROUP BY r.capability_coverage_set_hash
UNION ALL
SELECT 7::smallint AS hash_sequence, 'LATEST_SET_HASH'::text AS hash_code,
       r.latest_set_hash::text AS stored_hash,
       md5(string_agg(concat_ws('|',t.bundle_code::text,t.contract_version::text,t.row_hash::text),'|' ORDER BY t.bundle_code,t.contract_version))::text AS reconstructed_hash,
       (r.latest_set_hash IS DISTINCT FROM md5(string_agg(concat_ws('|',t.bundle_code::text,t.contract_version::text,t.row_hash::text),'|' ORDER BY t.bundle_code,t.contract_version))) AS mismatch_flag,
       'msbf_ctl.m2_12_g3_bundle_latest'::text AS authoritative_source,
       'bundle_code,contract_version'::text AS ordered_business_key
FROM msbf_ctl.m2_12_g3_bundle_latest t
JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id
JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1
GROUP BY r.latest_set_hash
UNION ALL
SELECT 8::smallint AS hash_sequence, 'ARCHIVE_SET_HASH'::text AS hash_code,
       r.archive_set_hash::text AS stored_hash,
       md5(string_agg(concat_ws('|',t.bundle_code::text,t.contract_version::text,t.archive_row_hash::text),'|' ORDER BY t.bundle_code,t.contract_version))::text AS reconstructed_hash,
       (r.archive_set_hash IS DISTINCT FROM md5(string_agg(concat_ws('|',t.bundle_code::text,t.contract_version::text,t.archive_row_hash::text),'|' ORDER BY t.bundle_code,t.contract_version))) AS mismatch_flag,
       'msbf_ctl.m2_12_g3_bundle_archive'::text AS authoritative_source,
       'bundle_code,contract_version'::text AS ordered_business_key
FROM msbf_ctl.m2_12_g3_bundle_archive t
JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id
JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1
GROUP BY r.archive_set_hash
UNION ALL
SELECT 9::smallint AS hash_sequence, 'REGISTRY_SET_HASH'::text AS hash_code,
       r.registry_set_hash::text AS stored_hash,
       md5(string_agg(concat_ws('|',t.bundle_code::text,t.contract_version::text,t.row_hash::text),'|' ORDER BY t.bundle_code,t.contract_version))::text AS reconstructed_hash,
       (r.registry_set_hash IS DISTINCT FROM md5(string_agg(concat_ws('|',t.bundle_code::text,t.contract_version::text,t.row_hash::text),'|' ORDER BY t.bundle_code,t.contract_version))) AS mismatch_flag,
       'msbf_ctl.m2_12_g3_bundle_registry'::text AS authoritative_source,
       'bundle_code,contract_version'::text AS ordered_business_key
FROM msbf_ctl.m2_12_g3_bundle_registry t
JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id
JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1
GROUP BY r.registry_set_hash
UNION ALL
SELECT 10::smallint,'REGISTRY_ROW_HASH'::text,r.row_hash::text,
       md5((to_jsonb(r)-ARRAY['registry_id','contract_status','generated_at','validated_at','accepted_at','created_at','updated_at','row_hash','policy_set_hash','stage_certification_set_hash','contract_component_set_hash','evidence_certification_set_hash','contract_reproduction_set_hash','capability_coverage_set_hash','latest_set_hash','archive_set_hash','registry_set_hash','contract_set_hash','combined_set_hash']::text[])::text)::text,
       (r.row_hash IS DISTINCT FROM md5((to_jsonb(r)-ARRAY['registry_id','contract_status','generated_at','validated_at','accepted_at','created_at','updated_at','row_hash','policy_set_hash','stage_certification_set_hash','contract_component_set_hash','evidence_certification_set_hash','contract_reproduction_set_hash','capability_coverage_set_hash','latest_set_hash','archive_set_hash','registry_set_hash','contract_set_hash','combined_set_hash']::text[])::text)),
       'msbf_ctl.m2_12_g3_bundle_registry'::text,
       'bundle_code,contract_version; immutable registry preimage'::text
FROM msbf_ctl.m2_12_g3_bundle_registry r
JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=r.module1_run_id
WHERE r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1
UNION ALL
SELECT 11::smallint,'CONTRACT_SET_HASH'::text,r.contract_set_hash::text,
       md5(concat_ws('|',r.bundle_code::text,r.contract_version::text,r.schema_version::text,r.methodology_version::text,r.policy_configuration_hash::text,r.policy_set_hash::text,r.stage_certification_set_hash::text,r.contract_component_set_hash::text,r.evidence_certification_set_hash::text,r.contract_reproduction_set_hash::text,r.capability_coverage_set_hash::text,r.latest_set_hash::text,r.archive_set_hash::text,r.registry_set_hash::text,r.latest_contract_row_hash::text,r.archive_contract_row_hash::text,r.row_hash::text,r.accepted_m2_11_contract_set_hash::text,r.accepted_m2_11_combined_set_hash::text,r.accepted_m2_11_registry_row_hash::text))::text,
       (r.contract_set_hash IS DISTINCT FROM md5(concat_ws('|',r.bundle_code::text,r.contract_version::text,r.schema_version::text,r.methodology_version::text,r.policy_configuration_hash::text,r.policy_set_hash::text,r.stage_certification_set_hash::text,r.contract_component_set_hash::text,r.evidence_certification_set_hash::text,r.contract_reproduction_set_hash::text,r.capability_coverage_set_hash::text,r.latest_set_hash::text,r.archive_set_hash::text,r.registry_set_hash::text,r.latest_contract_row_hash::text,r.archive_contract_row_hash::text,r.row_hash::text,r.accepted_m2_11_contract_set_hash::text,r.accepted_m2_11_combined_set_hash::text,r.accepted_m2_11_registry_row_hash::text))),
       'msbf_ctl.m2_12_g3_bundle_registry'::text,
       'frozen G3 contract-hash field order'::text
FROM msbf_ctl.m2_12_g3_bundle_registry r
JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=r.module1_run_id
WHERE r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1
UNION ALL
SELECT 12::smallint,'COMBINED_SET_HASH'::text,r.combined_set_hash::text,
       md5(string_agg(c.family_code||'|'||c.entity_key||'|'||c.stored_hash,'|' ORDER BY c.family_code,c.entity_key))::text,
       (r.combined_set_hash IS DISTINCT FROM md5(string_agg(c.family_code||'|'||c.entity_key||'|'||c.stored_hash,'|' ORDER BY c.family_code,c.entity_key))),
       'all nine M2.12 canonical families'::text,
       'family_code,entity_key'::text
FROM (
    SELECT 'POLICY'::text family_code, concat_ws('|',t.policy_code,t.policy_version::text) entity_key, t.row_hash::text stored_hash, md5((to_jsonb(t)-'policy_profile_id'-'row_hash'-'created_at'-'updated_at')::text)::text physical_hash FROM msbf_ctl.m2_12_policy_profile t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT 'STAGE_CERTIFICATION', concat_ws('|',t.certification_node_sequence::text,t.stage_code), t.row_hash, md5((to_jsonb(t)-'row_hash'-'created_at')::text) FROM msbf_m2.module2_stage_certification_snapshot t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT 'CONTRACT_COMPONENT', concat_ws('|',t.component_sequence::text,t.component_contract_code,t.contract_version::text), t.row_hash, md5((to_jsonb(t)-'row_hash'-'created_at')::text) FROM msbf_m2.module2_contract_component_snapshot t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT 'EVIDENCE_CERTIFICATION', concat_ws('|',t.node_sequence::text,t.evidence_family_sequence::text), t.row_hash, md5((to_jsonb(t)-'row_hash'-'created_at')::text) FROM msbf_m2.module2_evidence_certification_snapshot t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT 'CONTRACT_REPRODUCTION', concat_ws('|',t.component_sequence::text,t.component_contract_code,t.contract_version::text), t.row_hash, md5((to_jsonb(t)-'row_hash'-'created_at')::text) FROM msbf_m2.module2_contract_reproduction_snapshot t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT 'CAPABILITY_COVERAGE', concat_ws('|',t.capability_sequence::text,t.capability_code), t.row_hash, md5((to_jsonb(t)-'row_hash'-'created_at')::text) FROM msbf_m2.module2_capability_coverage_snapshot t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT 'LATEST', concat_ws('|',t.bundle_code,t.contract_version::text), t.row_hash, md5((to_jsonb(t)-'row_hash'-'created_at')::text) FROM msbf_ctl.m2_12_g3_bundle_latest t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT 'ARCHIVE', concat_ws('|',t.bundle_code,t.contract_version::text), t.archive_row_hash, md5((to_jsonb(t)-'archive_id'-'archive_row_hash'-'created_at')::text) FROM msbf_ctl.m2_12_g3_bundle_archive t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT 'REGISTRY', concat_ws('|',t.bundle_code,t.contract_version::text), t.row_hash, md5((to_jsonb(t)-ARRAY['registry_id','contract_status','generated_at','validated_at','accepted_at','created_at','updated_at','row_hash','policy_set_hash','stage_certification_set_hash','contract_component_set_hash','evidence_certification_set_hash','contract_reproduction_set_hash','capability_coverage_set_hash','latest_set_hash','archive_set_hash','registry_set_hash','contract_set_hash','combined_set_hash']::text[])::text) FROM msbf_ctl.m2_12_g3_bundle_registry t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id
) c
CROSS JOIN msbf_ctl.m2_12_g3_bundle_registry r
JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=r.module1_run_id
WHERE r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1
GROUP BY r.combined_set_hash;
    CREATE UNIQUE INDEX ux_tmp_hash_m2_12_acceptance_detail ON tmp_hash_m2_12_acceptance_detail(hash_sequence);
    ANALYZE tmp_hash_m2_12_acceptance_detail;
CREATE TEMP TABLE tmp_hash_m2_12_acceptance_prewrite_reconstruction ON COMMIT DROP AS
WITH canonical AS (
    SELECT 'POLICY'::text family_code, concat_ws('|',t.policy_code,t.policy_version::text) entity_key, t.row_hash::text stored_hash, md5((to_jsonb(t)-'policy_profile_id'-'row_hash'-'created_at'-'updated_at')::text)::text physical_hash FROM msbf_ctl.m2_12_policy_profile t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT 'STAGE_CERTIFICATION', concat_ws('|',t.certification_node_sequence::text,t.stage_code), t.row_hash, md5((to_jsonb(t)-'row_hash'-'created_at')::text) FROM msbf_m2.module2_stage_certification_snapshot t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT 'CONTRACT_COMPONENT', concat_ws('|',t.component_sequence::text,t.component_contract_code,t.contract_version::text), t.row_hash, md5((to_jsonb(t)-'row_hash'-'created_at')::text) FROM msbf_m2.module2_contract_component_snapshot t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT 'EVIDENCE_CERTIFICATION', concat_ws('|',t.node_sequence::text,t.evidence_family_sequence::text), t.row_hash, md5((to_jsonb(t)-'row_hash'-'created_at')::text) FROM msbf_m2.module2_evidence_certification_snapshot t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT 'CONTRACT_REPRODUCTION', concat_ws('|',t.component_sequence::text,t.component_contract_code,t.contract_version::text), t.row_hash, md5((to_jsonb(t)-'row_hash'-'created_at')::text) FROM msbf_m2.module2_contract_reproduction_snapshot t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT 'CAPABILITY_COVERAGE', concat_ws('|',t.capability_sequence::text,t.capability_code), t.row_hash, md5((to_jsonb(t)-'row_hash'-'created_at')::text) FROM msbf_m2.module2_capability_coverage_snapshot t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT 'LATEST', concat_ws('|',t.bundle_code,t.contract_version::text), t.row_hash, md5((to_jsonb(t)-'row_hash'-'created_at')::text) FROM msbf_ctl.m2_12_g3_bundle_latest t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT 'ARCHIVE', concat_ws('|',t.bundle_code,t.contract_version::text), t.archive_row_hash, md5((to_jsonb(t)-'archive_id'-'archive_row_hash'-'created_at')::text) FROM msbf_ctl.m2_12_g3_bundle_archive t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT 'REGISTRY', concat_ws('|',t.bundle_code,t.contract_version::text), t.row_hash, md5((to_jsonb(t)-ARRAY['registry_id','contract_status','generated_at','validated_at','accepted_at','created_at','updated_at','row_hash','policy_set_hash','stage_certification_set_hash','contract_component_set_hash','evidence_certification_set_hash','contract_reproduction_set_hash','capability_coverage_set_hash','latest_set_hash','archive_set_hash','registry_set_hash','contract_set_hash','combined_set_hash']::text[])::text) FROM msbf_ctl.m2_12_g3_bundle_registry t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id
), registry AS (
    SELECT
        r.policy_set_hash,r.stage_certification_set_hash,r.contract_component_set_hash,
        r.evidence_certification_set_hash,r.contract_reproduction_set_hash,r.capability_coverage_set_hash,
        r.latest_set_hash,r.archive_set_hash,r.registry_set_hash,r.latest_contract_row_hash,
        r.archive_contract_row_hash,r.contract_set_hash,r.combined_set_hash,r.row_hash,
        r.accepted_m2_11_contract_set_hash,r.accepted_m2_11_combined_set_hash,
        r.accepted_m2_11_registry_row_hash
    FROM msbf_ctl.m2_12_g3_bundle_registry r
    JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=r.module1_run_id
    WHERE r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1
), sequence_state AS (
    SELECT concat_ws('|',
        p.last_value::text,p.is_called::text,
        a.last_value::text,a.is_called::text,
        r.last_value::text,r.is_called::text) AS sequence_fingerprint
    FROM msbf_ctl.m2_12_policy_profile_policy_profile_id_seq p
    CROSS JOIN msbf_ctl.m2_12_g3_bundle_archive_archive_id_seq a
    CROSS JOIN msbf_ctl.m2_12_g3_bundle_registry_registry_id_seq r
)
SELECT
    count(*)::integer AS canonical_entity_count,
    count(DISTINCT family_code)::integer AS canonical_family_count,
    count(*) FILTER (WHERE stored_hash IS DISTINCT FROM physical_hash)::integer AS row_hash_mismatch_count,
    md5(string_agg(concat_ws('|',family_code,entity_key,stored_hash,physical_hash),'|' ORDER BY family_code,entity_key))::text AS canonical_physical_fingerprint,
    (SELECT md5(concat_ws('|',
        policy_set_hash,stage_certification_set_hash,contract_component_set_hash,
        evidence_certification_set_hash,contract_reproduction_set_hash,capability_coverage_set_hash,
        latest_set_hash,archive_set_hash,registry_set_hash,latest_contract_row_hash,
        archive_contract_row_hash,contract_set_hash,combined_set_hash,row_hash,
        accepted_m2_11_contract_set_hash,accepted_m2_11_combined_set_hash,
        accepted_m2_11_registry_row_hash)) FROM registry)::text AS governed_hash_fingerprint,
    (SELECT sequence_fingerprint FROM sequence_state)::text AS sequence_fingerprint
FROM canonical;
CREATE UNIQUE INDEX ux_tmp_hash_m2_12_acceptance_prewrite_reconstruction ON tmp_hash_m2_12_acceptance_prewrite_reconstruction(canonical_entity_count);
ANALYZE tmp_hash_m2_12_acceptance_prewrite_reconstruction;
/* Phase 1 continued — frozen 48-row acceptance requirement ledger. */
CREATE TEMP TABLE tmp_accept_m2_12_requirement
(
    requirement_sequence smallint PRIMARY KEY,
    requirement_code text NOT NULL UNIQUE,
    acceptance_phase text NOT NULL,
    requirement_family text NOT NULL,
    requirement_description text NOT NULL,
    observed_value text NOT NULL,
    expected_value text NOT NULL,
    status text NOT NULL CHECK(status IN ('PASS','FAIL')),
    failure_detail text,
    authority_trace text NOT NULL
) ON COMMIT PRESERVE ROWS;

CREATE OR REPLACE FUNCTION pg_temp.m2_12_add_acceptance_requirement
(
    p_sequence smallint,
    p_code text,
    p_family text,
    p_description text,
    p_observed text,
    p_expected text,
    p_pass boolean,
    p_failure_detail text,
    p_trace text
) RETURNS void
LANGUAGE plpgsql
AS $m212_p225_hf15_add_requirement$
BEGIN
    INSERT INTO tmp_accept_m2_12_requirement
    (requirement_sequence,requirement_code,acceptance_phase,requirement_family,
     requirement_description,observed_value,expected_value,status,failure_detail,authority_trace)
    VALUES
    (p_sequence,p_code,CASE WHEN p_sequence<48 THEN 'PRE_WRITE' ELSE 'POST_WRITE_ATOMICITY' END,
     p_family,p_description,p_observed,p_expected,
     CASE WHEN coalesce(p_pass,false) THEN 'PASS' ELSE 'FAIL' END,
     p_failure_detail,p_trace);
END;
$m212_p225_hf15_add_requirement$;
/* Compact pre-write registration: Requirements 001-047 emit no intermediate result grids. */
DO $m212_p225_hf23_prewrite_requirement_registration$
BEGIN
/* HF23_ACCEPTANCE_REQUIREMENT M2_12_ACC_001 */
    PERFORM pg_temp.m2_12_add_acceptance_requirement(
    1::smallint,
    'M2_12_ACC_001'::text,
    'LIFECYCLE'::text,
    'Run status before finalization is M2_12_VALIDATED'::text,
    COALESCE(((SELECT concat_ws('|',count(*)::text,min(run_status)) FROM tmp_accept_m2_12_context))::text,'<NULL>'),
    'M2_12_VALIDATED'::text,
    COALESCE(((SELECT count(*)=1 AND min(run_status)='M2_12_VALIDATED' FROM tmp_accept_m2_12_context)),false),
    CASE WHEN COALESCE(((SELECT count(*)=1 AND min(run_status)='M2_12_VALIDATED' FROM tmp_accept_m2_12_context)),false) THEN NULL ELSE 'M2_12_ACC_001 physical requirement mismatch'::text END,
    'run_registry physical row locked before writes'::text
);
/* HF23_ACCEPTANCE_REQUIREMENT M2_12_ACC_002 */
    PERFORM pg_temp.m2_12_add_acceptance_requirement(
    2::smallint,
    'M2_12_ACC_002'::text,
    'LIFECYCLE'::text,
    'G3 bundle registry status before finalization is VALIDATED'::text,
    COALESCE(((SELECT concat_ws('|',count(*)::text,min(contract_status)) FROM tmp_accept_m2_12_context))::text,'<NULL>'),
    'VALIDATED'::text,
    COALESCE(((SELECT count(*)=1 AND min(contract_status)='VALIDATED' FROM tmp_accept_m2_12_context)),false),
    CASE WHEN COALESCE(((SELECT count(*)=1 AND min(contract_status)='VALIDATED' FROM tmp_accept_m2_12_context)),false) THEN NULL ELSE 'M2_12_ACC_002 physical requirement mismatch'::text END,
    'm2_12_g3_bundle_registry physical row locked before writes'::text
);
/* HF23_ACCEPTANCE_REQUIREMENT M2_12_ACC_003 */
    PERFORM pg_temp.m2_12_add_acceptance_requirement(
    3::smallint,
    'M2_12_ACC_003'::text,
    'POLICY'::text,
    'M2.12 policy is approved and configuration hash reconstructs'::text,
    COALESCE(((SELECT concat_ws('|',count(*)::text,min(p.policy_status),sum((p.configuration_hash IS DISTINCT FROM md5(p.configuration_payload::text))::integer)::text) FROM msbf_ctl.m2_12_policy_profile p JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=p.module1_run_id))::text,'<NULL>'),
    'APPROVED / 0 mismatches'::text,
    COALESCE(((SELECT count(*)=1 AND min(p.policy_status)='APPROVED' AND sum((p.configuration_hash IS DISTINCT FROM md5(p.configuration_payload::text))::integer)=0 FROM msbf_ctl.m2_12_policy_profile p JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=p.module1_run_id)),false),
    CASE WHEN COALESCE(((SELECT count(*)=1 AND min(p.policy_status)='APPROVED' AND sum((p.configuration_hash IS DISTINCT FROM md5(p.configuration_payload::text))::integer)=0 FROM msbf_ctl.m2_12_policy_profile p JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=p.module1_run_id)),false) THEN NULL ELSE 'M2_12_ACC_003 physical requirement mismatch'::text END,
    'policy row and independent configuration_payload MD5 reconstruction'::text
);
/* HF23_ACCEPTANCE_REQUIREMENT M2_12_ACC_004 */
    PERFORM pg_temp.m2_12_add_acceptance_requirement(
    4::smallint,
    'M2_12_ACC_004'::text,
    'IDENTITY'::text,
    'Bundle/version/schema/methodology identities and complete existing G3 gate catalog identity are exact'::text,
    COALESCE(((SELECT concat_ws('|',p.bundle_code,p.bundle_version::text,p.schema_version,p.methodology_version,p.acceptance_gate_id,g.gate_name,g.module_code,g.severity,g.active_flag::text,g.description) FROM msbf_ctl.m2_12_policy_profile p JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=p.module1_run_id JOIN msbf_ref.acceptance_gate_catalog g ON g.gate_id=p.acceptance_gate_id))::text,'<NULL>'),
    'M2_G3_CONSUMPTION_BUNDLE v1 | M2_G3_BUNDLE_SCHEMA_V1 | M2_12_METHOD_V1 | G3_M2_CONTRACT | Module 2 Contract | M2 | BLOCKING | true | Offer contract accepted.'::text,
    COALESCE(((SELECT count(*)=1 AND bool_and((p.bundle_code,p.bundle_version,p.schema_version,p.methodology_version,p.acceptance_gate_id,g.gate_name,g.module_code,g.severity,g.active_flag,g.description) IS NOT DISTINCT FROM ('M2_G3_CONSUMPTION_BUNDLE',1,'M2_G3_BUNDLE_SCHEMA_V1','M2_12_METHOD_V1','G3_M2_CONTRACT','Module 2 Contract','M2','BLOCKING',true,'Offer contract accepted.')) FROM msbf_ctl.m2_12_policy_profile p JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=p.module1_run_id JOIN msbf_ref.acceptance_gate_catalog g ON g.gate_id=p.acceptance_gate_id)),false),
    CASE WHEN COALESCE(((SELECT count(*)=1 AND bool_and((p.bundle_code,p.bundle_version,p.schema_version,p.methodology_version,p.acceptance_gate_id,g.gate_name,g.module_code,g.severity,g.active_flag,g.description) IS NOT DISTINCT FROM ('M2_G3_CONSUMPTION_BUNDLE',1,'M2_G3_BUNDLE_SCHEMA_V1','M2_12_METHOD_V1','G3_M2_CONTRACT','Module 2 Contract','M2','BLOCKING',true,'Offer contract accepted.')) FROM msbf_ctl.m2_12_policy_profile p JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=p.module1_run_id JOIN msbf_ref.acceptance_gate_catalog g ON g.gate_id=p.acceptance_gate_id)),false) THEN NULL ELSE 'M2_12_ACC_004 physical requirement mismatch'::text END,
    'frozen policy identity plus complete pre-existing G3 gate catalog row'::text
);
/* HF23_ACCEPTANCE_REQUIREMENT M2_12_ACC_005 */
    PERFORM pg_temp.m2_12_add_acceptance_requirement(
    5::smallint,
    'M2_12_ACC_005'::text,
    'SOURCE'::text,
    'M1.17 G2 registry, review-version-1 gate, and acceptance evidence/provenance are accepted'::text,
    COALESCE(((SELECT concat_ws('|',(SELECT count(*) FROM msbf_ctl.m1_17_g2_bundle_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M1_G2_CONSUMPTION_BUNDLE' AND r.bundle_version=1 AND r.bundle_status='ACCEPTED'),(SELECT count(*) FROM msbf_ctl.acceptance_gate_result g WHERE g.run_id=ctx.module1_run_id AND g.gate_id='G2_M1_CONTRACT' AND g.review_version=1 AND g.result_status='PASS'),(SELECT count(*) FROM msbf_ctl.run_evidence e WHERE e.run_id=ctx.module1_run_id AND e.evidence_code='M1_17_ACCEPTANCE_SUMMARY' AND e.status='PASS')) FROM tmp_accept_m2_12_context ctx))::text,'<NULL>'),
    'ACCEPTED | PASS review_version 1 | acceptance evidence present'::text,
    COALESCE(((SELECT (SELECT count(*) FROM msbf_ctl.m1_17_g2_bundle_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M1_G2_CONSUMPTION_BUNDLE' AND r.bundle_version=1 AND r.bundle_status='ACCEPTED')=1 AND (SELECT count(*) FROM msbf_ctl.acceptance_gate_result g WHERE g.run_id=ctx.module1_run_id AND g.gate_id='G2_M1_CONTRACT' AND g.review_version=1 AND g.result_status='PASS')=1 AND (SELECT count(*) FROM msbf_ctl.run_evidence e WHERE e.run_id=ctx.module1_run_id AND e.evidence_code='M1_17_ACCEPTANCE_SUMMARY' AND e.status='PASS')=1 FROM tmp_accept_m2_12_context ctx)),false),
    CASE WHEN COALESCE(((SELECT (SELECT count(*) FROM msbf_ctl.m1_17_g2_bundle_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M1_G2_CONSUMPTION_BUNDLE' AND r.bundle_version=1 AND r.bundle_status='ACCEPTED')=1 AND (SELECT count(*) FROM msbf_ctl.acceptance_gate_result g WHERE g.run_id=ctx.module1_run_id AND g.gate_id='G2_M1_CONTRACT' AND g.review_version=1 AND g.result_status='PASS')=1 AND (SELECT count(*) FROM msbf_ctl.run_evidence e WHERE e.run_id=ctx.module1_run_id AND e.evidence_code='M1_17_ACCEPTANCE_SUMMARY' AND e.status='PASS')=1 FROM tmp_accept_m2_12_context ctx)),false) THEN NULL ELSE 'M2_12_ACC_005 physical requirement mismatch'::text END,
    'direct M1.17 registry, G2 gate, and acceptance evidence reads'::text
);
/* HF23_ACCEPTANCE_REQUIREMENT M2_12_ACC_006 */
    PERFORM pg_temp.m2_12_add_acceptance_requirement(
    6::smallint,
    'M2_12_ACC_006'::text,
    'SOURCE'::text,
    'All eleven historical M2.1-M2.11 stage contracts remain ACCEPTED with a recorded acceptance method'::text,
    COALESCE(((SELECT concat_ws('|',
        count(*)::text,
        count(*) FILTER (WHERE s.contract_status='ACCEPTED')::text,
        count(*) FILTER (WHERE nullif(s.historical_acceptance_method,'') IS NOT NULL)::text)
      FROM msbf_m2.module2_stage_certification_snapshot s
      JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=s.module1_run_id
     WHERE s.certification_node_sequence BETWEEN 2 AND 12))::text,'<NULL>'),
    '11|11|11'::text,
    COALESCE(((SELECT count(*)=11
       AND count(*) FILTER (WHERE s.contract_status='ACCEPTED')=11
       AND count(*) FILTER (WHERE nullif(s.historical_acceptance_method,'') IS NOT NULL)=11
      FROM msbf_m2.module2_stage_certification_snapshot s
      JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=s.module1_run_id
     WHERE s.certification_node_sequence BETWEEN 2 AND 12)),false),
    CASE WHEN COALESCE(((SELECT count(*)=11
       AND count(*) FILTER (WHERE s.contract_status='ACCEPTED')=11
       AND count(*) FILTER (WHERE nullif(s.historical_acceptance_method,'') IS NOT NULL)=11
      FROM msbf_m2.module2_stage_certification_snapshot s
      JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=s.module1_run_id
     WHERE s.certification_node_sequence BETWEEN 2 AND 12)),false)
      THEN NULL ELSE 'M2_12_ACC_006 physical requirement mismatch'::text END,
    'eleven exact persisted historical acceptance checkpoints; current lifecycle is controlled by Requirements 001-002'::text
);
/* HF23_ACCEPTANCE_REQUIREMENT M2_12_ACC_007 */
    PERFORM pg_temp.m2_12_add_acceptance_requirement(
    7::smallint,
    'M2_12_ACC_007'::text,
    'SOURCE'::text,
    'All eleven M2.1-M2.11 stages and the separate M1.17 G2 stage have exact PASS gate/evidence certification'::text,
    COALESCE(((SELECT concat_ws('|',
        count(*)::text,
        count(*) FILTER (WHERE certification_status='PASS')::text,
        count(*) FILTER (WHERE node_sequence BETWEEN 2 AND 12 AND certification_status='PASS')::text,
        count(*) FILTER (WHERE node_sequence=1 AND certification_status='PASS')::text,
        count(*) FILTER (WHERE acceptance_summary_rows=1 AND acceptance_summary_pass_rows=1)::text,
        count(*) FILTER (WHERE duplicate_required_evidence_rows=0
                            AND coalesce(nullif(missing_required_evidence_codes,''),'')=''
                            AND coalesce(nullif(nonpass_evidence_codes,''),'')=''
                            AND coalesce(nullif(violation_evidence_codes,''),'')='')::text)
      FROM tmp_accept_m2_12_stage_boundary))::text,'<NULL>'),
    '12|12|11|1|12|12'::text,
    COALESCE(((SELECT count(*)=12
       AND count(*) FILTER (WHERE certification_status='PASS')=12
       AND count(*) FILTER (WHERE node_sequence BETWEEN 2 AND 12 AND certification_status='PASS')=11
       AND count(*) FILTER (WHERE node_sequence=1 AND certification_status='PASS')=1
       AND count(*) FILTER (WHERE acceptance_summary_rows=1 AND acceptance_summary_pass_rows=1)=12
       AND count(*) FILTER (WHERE duplicate_required_evidence_rows=0
                            AND coalesce(nullif(missing_required_evidence_codes,''),'')=''
                            AND coalesce(nullif(nonpass_evidence_codes,''),'')=''
                            AND coalesce(nullif(violation_evidence_codes,''),'')='')=12
      FROM tmp_accept_m2_12_stage_boundary)),false),
    CASE WHEN COALESCE(((SELECT count(*)=12
       AND count(*) FILTER (WHERE certification_status='PASS')=12
       AND count(*) FILTER (WHERE node_sequence BETWEEN 2 AND 12 AND certification_status='PASS')=11
       AND count(*) FILTER (WHERE node_sequence=1 AND certification_status='PASS')=1
       AND count(*) FILTER (WHERE acceptance_summary_rows=1 AND acceptance_summary_pass_rows=1)=12
       AND count(*) FILTER (WHERE duplicate_required_evidence_rows=0
                            AND coalesce(nullif(missing_required_evidence_codes,''),'')=''
                            AND coalesce(nullif(nonpass_evidence_codes,''),'')=''
                            AND coalesce(nullif(violation_evidence_codes,''),'')='')=12
      FROM tmp_accept_m2_12_stage_boundary)),false)
      THEN NULL ELSE 'M2_12_ACC_007 physical requirement mismatch'::text END,
    'independently reconstructed 12-node physical gate/evidence boundary with exact row-count and duplicate controls'::text
);
/* HF23_ACCEPTANCE_REQUIREMENT M2_12_ACC_008 */
    PERFORM pg_temp.m2_12_add_acceptance_requirement(
    8::smallint,
    'M2_12_ACC_008'::text,
    'COUNT'::text,
    'Stage certification rows reconcile'::text,
    COALESCE(((SELECT count(*)::text FROM msbf_m2.module2_stage_certification_snapshot t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id))::text,'<NULL>'),
    '12'::text,
    COALESCE(((SELECT count(*)=12 FROM msbf_m2.module2_stage_certification_snapshot t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id)),false),
    CASE WHEN COALESCE(((SELECT count(*)=12 FROM msbf_m2.module2_stage_certification_snapshot t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id)),false) THEN NULL ELSE 'M2_12_ACC_008 physical requirement mismatch'::text END,
    'direct physical count from msbf_m2.module2_stage_certification_snapshot'::text
);
/* HF23_ACCEPTANCE_REQUIREMENT M2_12_ACC_009 */
    PERFORM pg_temp.m2_12_add_acceptance_requirement(
    9::smallint,
    'M2_12_ACC_009'::text,
    'COUNT'::text,
    'Component contract rows reconcile'::text,
    COALESCE(((SELECT count(*)::text FROM msbf_m2.module2_contract_component_snapshot t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id))::text,'<NULL>'),
    '13'::text,
    COALESCE(((SELECT count(*)=13 FROM msbf_m2.module2_contract_component_snapshot t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id)),false),
    CASE WHEN COALESCE(((SELECT count(*)=13 FROM msbf_m2.module2_contract_component_snapshot t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id)),false) THEN NULL ELSE 'M2_12_ACC_009 physical requirement mismatch'::text END,
    'direct physical count from msbf_m2.module2_contract_component_snapshot'::text
);
/* HF23_ACCEPTANCE_REQUIREMENT M2_12_ACC_010 */
    PERFORM pg_temp.m2_12_add_acceptance_requirement(
    10::smallint,
    'M2_12_ACC_010'::text,
    'COUNT'::text,
    'Evidence certification rows reconcile'::text,
    COALESCE(((SELECT count(*)::text FROM msbf_m2.module2_evidence_certification_snapshot t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id))::text,'<NULL>'),
    '72'::text,
    COALESCE(((SELECT count(*)=72 FROM msbf_m2.module2_evidence_certification_snapshot t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id)),false),
    CASE WHEN COALESCE(((SELECT count(*)=72 FROM msbf_m2.module2_evidence_certification_snapshot t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id)),false) THEN NULL ELSE 'M2_12_ACC_010 physical requirement mismatch'::text END,
    'direct physical count from msbf_m2.module2_evidence_certification_snapshot'::text
);
/* HF23_ACCEPTANCE_REQUIREMENT M2_12_ACC_011 */
    PERFORM pg_temp.m2_12_add_acceptance_requirement(
    11::smallint,
    'M2_12_ACC_011'::text,
    'COUNT'::text,
    'Contract reproduction rows reconcile'::text,
    COALESCE(((SELECT count(*)::text FROM msbf_m2.module2_contract_reproduction_snapshot t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id))::text,'<NULL>'),
    '13'::text,
    COALESCE(((SELECT count(*)=13 FROM msbf_m2.module2_contract_reproduction_snapshot t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id)),false),
    CASE WHEN COALESCE(((SELECT count(*)=13 FROM msbf_m2.module2_contract_reproduction_snapshot t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id)),false) THEN NULL ELSE 'M2_12_ACC_011 physical requirement mismatch'::text END,
    'direct physical count from msbf_m2.module2_contract_reproduction_snapshot'::text
);
/* HF23_ACCEPTANCE_REQUIREMENT M2_12_ACC_012 */
    PERFORM pg_temp.m2_12_add_acceptance_requirement(
    12::smallint,
    'M2_12_ACC_012'::text,
    'COUNT'::text,
    'Capability coverage rows reconcile'::text,
    COALESCE(((SELECT count(*)::text FROM msbf_m2.module2_capability_coverage_snapshot t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id))::text,'<NULL>'),
    '20'::text,
    COALESCE(((SELECT count(*)=20 FROM msbf_m2.module2_capability_coverage_snapshot t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id)),false),
    CASE WHEN COALESCE(((SELECT count(*)=20 FROM msbf_m2.module2_capability_coverage_snapshot t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id)),false) THEN NULL ELSE 'M2_12_ACC_012 physical requirement mismatch'::text END,
    'direct physical count from msbf_m2.module2_capability_coverage_snapshot'::text
);
/* HF23_ACCEPTANCE_REQUIREMENT M2_12_ACC_013 */
    PERFORM pg_temp.m2_12_add_acceptance_requirement(
    13::smallint,
    'M2_12_ACC_013'::text,
    'COUNT'::text,
    'G3 latest rows reconcile'::text,
    COALESCE(((SELECT count(*)::text FROM msbf_ctl.m2_12_g3_bundle_latest t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id))::text,'<NULL>'),
    '1'::text,
    COALESCE(((SELECT count(*)=1 FROM msbf_ctl.m2_12_g3_bundle_latest t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id)),false),
    CASE WHEN COALESCE(((SELECT count(*)=1 FROM msbf_ctl.m2_12_g3_bundle_latest t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id)),false) THEN NULL ELSE 'M2_12_ACC_013 physical requirement mismatch'::text END,
    'direct physical count from msbf_ctl.m2_12_g3_bundle_latest'::text
);
/* HF23_ACCEPTANCE_REQUIREMENT M2_12_ACC_014 */
    PERFORM pg_temp.m2_12_add_acceptance_requirement(
    14::smallint,
    'M2_12_ACC_014'::text,
    'COUNT'::text,
    'G3 archive rows reconcile'::text,
    COALESCE(((SELECT count(*)::text FROM msbf_ctl.m2_12_g3_bundle_archive t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id))::text,'<NULL>'),
    '1'::text,
    COALESCE(((SELECT count(*)=1 FROM msbf_ctl.m2_12_g3_bundle_archive t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id)),false),
    CASE WHEN COALESCE(((SELECT count(*)=1 FROM msbf_ctl.m2_12_g3_bundle_archive t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id)),false) THEN NULL ELSE 'M2_12_ACC_014 physical requirement mismatch'::text END,
    'direct physical count from msbf_ctl.m2_12_g3_bundle_archive'::text
);
/* HF23_ACCEPTANCE_REQUIREMENT M2_12_ACC_015 */
    PERFORM pg_temp.m2_12_add_acceptance_requirement(
    15::smallint,
    'M2_12_ACC_015'::text,
    'COUNT'::text,
    'G3 registry rows reconcile'::text,
    COALESCE(((SELECT count(*)::text FROM msbf_ctl.m2_12_g3_bundle_registry t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id))::text,'<NULL>'),
    '1'::text,
    COALESCE(((SELECT count(*)=1 FROM msbf_ctl.m2_12_g3_bundle_registry t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id)),false),
    CASE WHEN COALESCE(((SELECT count(*)=1 FROM msbf_ctl.m2_12_g3_bundle_registry t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id)),false) THEN NULL ELSE 'M2_12_ACC_015 physical requirement mismatch'::text END,
    'direct physical count from msbf_ctl.m2_12_g3_bundle_registry'::text
);
/* HF23_ACCEPTANCE_REQUIREMENT M2_12_ACC_016 */
    PERFORM pg_temp.m2_12_add_acceptance_requirement(
    16::smallint,
    'M2_12_ACC_016'::text,
    'CANONICAL'::text,
    'M2.12 canonical entity count reconciles'::text,
    COALESCE(((SELECT (SELECT count(*) FROM msbf_ctl.m2_12_policy_profile p WHERE p.module1_run_id=ctx.module1_run_id)+(SELECT count(*) FROM msbf_m2.module2_stage_certification_snapshot s WHERE s.module1_run_id=ctx.module1_run_id)+(SELECT count(*) FROM msbf_m2.module2_contract_component_snapshot c WHERE c.module1_run_id=ctx.module1_run_id)+(SELECT count(*) FROM msbf_m2.module2_evidence_certification_snapshot e WHERE e.module1_run_id=ctx.module1_run_id)+(SELECT count(*) FROM msbf_m2.module2_contract_reproduction_snapshot r WHERE r.module1_run_id=ctx.module1_run_id)+(SELECT count(*) FROM msbf_m2.module2_capability_coverage_snapshot c WHERE c.module1_run_id=ctx.module1_run_id)+(SELECT count(*) FROM msbf_ctl.m2_12_g3_bundle_latest l WHERE l.module1_run_id=ctx.module1_run_id)+(SELECT count(*) FROM msbf_ctl.m2_12_g3_bundle_archive a WHERE a.module1_run_id=ctx.module1_run_id)+(SELECT count(*) FROM msbf_ctl.m2_12_g3_bundle_registry r WHERE r.module1_run_id=ctx.module1_run_id) FROM tmp_accept_m2_12_context ctx))::text,'<NULL>'),
    '134'::text,
    COALESCE((((SELECT (SELECT count(*) FROM msbf_ctl.m2_12_policy_profile p WHERE p.module1_run_id=ctx.module1_run_id)+(SELECT count(*) FROM msbf_m2.module2_stage_certification_snapshot s WHERE s.module1_run_id=ctx.module1_run_id)+(SELECT count(*) FROM msbf_m2.module2_contract_component_snapshot c WHERE c.module1_run_id=ctx.module1_run_id)+(SELECT count(*) FROM msbf_m2.module2_evidence_certification_snapshot e WHERE e.module1_run_id=ctx.module1_run_id)+(SELECT count(*) FROM msbf_m2.module2_contract_reproduction_snapshot r WHERE r.module1_run_id=ctx.module1_run_id)+(SELECT count(*) FROM msbf_m2.module2_capability_coverage_snapshot c WHERE c.module1_run_id=ctx.module1_run_id)+(SELECT count(*) FROM msbf_ctl.m2_12_g3_bundle_latest l WHERE l.module1_run_id=ctx.module1_run_id)+(SELECT count(*) FROM msbf_ctl.m2_12_g3_bundle_archive a WHERE a.module1_run_id=ctx.module1_run_id)+(SELECT count(*) FROM msbf_ctl.m2_12_g3_bundle_registry r WHERE r.module1_run_id=ctx.module1_run_id) FROM tmp_accept_m2_12_context ctx))=134),false),
    CASE WHEN COALESCE((((SELECT (SELECT count(*) FROM msbf_ctl.m2_12_policy_profile p WHERE p.module1_run_id=ctx.module1_run_id)+(SELECT count(*) FROM msbf_m2.module2_stage_certification_snapshot s WHERE s.module1_run_id=ctx.module1_run_id)+(SELECT count(*) FROM msbf_m2.module2_contract_component_snapshot c WHERE c.module1_run_id=ctx.module1_run_id)+(SELECT count(*) FROM msbf_m2.module2_evidence_certification_snapshot e WHERE e.module1_run_id=ctx.module1_run_id)+(SELECT count(*) FROM msbf_m2.module2_contract_reproduction_snapshot r WHERE r.module1_run_id=ctx.module1_run_id)+(SELECT count(*) FROM msbf_m2.module2_capability_coverage_snapshot c WHERE c.module1_run_id=ctx.module1_run_id)+(SELECT count(*) FROM msbf_ctl.m2_12_g3_bundle_latest l WHERE l.module1_run_id=ctx.module1_run_id)+(SELECT count(*) FROM msbf_ctl.m2_12_g3_bundle_archive a WHERE a.module1_run_id=ctx.module1_run_id)+(SELECT count(*) FROM msbf_ctl.m2_12_g3_bundle_registry r WHERE r.module1_run_id=ctx.module1_run_id) FROM tmp_accept_m2_12_context ctx))=134),false) THEN NULL ELSE 'M2_12_ACC_016 physical requirement mismatch'::text END,
    'sum of all nine physical canonical families'::text
);
/* HF23_ACCEPTANCE_REQUIREMENT M2_12_ACC_017 */
    PERFORM pg_temp.m2_12_add_acceptance_requirement(
    17::smallint,
    'M2_12_ACC_017'::text,
    'GRAIN'::text,
    'Stage certification business keys are unique'::text,
    COALESCE(((SELECT (count(*)-count(DISTINCT (t.certification_node_sequence,t.stage_code)))::text FROM msbf_m2.module2_stage_certification_snapshot t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id))::text,'<NULL>'),
    '0 duplicates'::text,
    COALESCE(((SELECT count(*)=count(DISTINCT (t.certification_node_sequence,t.stage_code)) FROM msbf_m2.module2_stage_certification_snapshot t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id)),false),
    CASE WHEN COALESCE(((SELECT count(*)=count(DISTINCT (t.certification_node_sequence,t.stage_code)) FROM msbf_m2.module2_stage_certification_snapshot t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id)),false) THEN NULL ELSE 'M2_12_ACC_017 physical requirement mismatch'::text END,
    'physical business grain msbf_m2.module2_stage_certification_snapshot(certification_node_sequence,stage_code)'::text
);
/* HF23_ACCEPTANCE_REQUIREMENT M2_12_ACC_018 */
    PERFORM pg_temp.m2_12_add_acceptance_requirement(
    18::smallint,
    'M2_12_ACC_018'::text,
    'GRAIN'::text,
    'Component contract business keys are unique'::text,
    COALESCE(((SELECT (count(*)-count(DISTINCT (t.component_sequence,t.component_contract_code,t.contract_version)))::text FROM msbf_m2.module2_contract_component_snapshot t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id))::text,'<NULL>'),
    '0 duplicates'::text,
    COALESCE(((SELECT count(*)=count(DISTINCT (t.component_sequence,t.component_contract_code,t.contract_version)) FROM msbf_m2.module2_contract_component_snapshot t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id)),false),
    CASE WHEN COALESCE(((SELECT count(*)=count(DISTINCT (t.component_sequence,t.component_contract_code,t.contract_version)) FROM msbf_m2.module2_contract_component_snapshot t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id)),false) THEN NULL ELSE 'M2_12_ACC_018 physical requirement mismatch'::text END,
    'physical business grain msbf_m2.module2_contract_component_snapshot(component_sequence,component_contract_code,contract_version)'::text
);
/* HF23_ACCEPTANCE_REQUIREMENT M2_12_ACC_019 */
    PERFORM pg_temp.m2_12_add_acceptance_requirement(
    19::smallint,
    'M2_12_ACC_019'::text,
    'GRAIN'::text,
    'Evidence certification stage/family keys are unique'::text,
    COALESCE(((SELECT (count(*)-count(DISTINCT (t.node_sequence,t.evidence_family_sequence)))::text FROM msbf_m2.module2_evidence_certification_snapshot t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id))::text,'<NULL>'),
    '0 duplicates'::text,
    COALESCE(((SELECT count(*)=count(DISTINCT (t.node_sequence,t.evidence_family_sequence)) FROM msbf_m2.module2_evidence_certification_snapshot t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id)),false),
    CASE WHEN COALESCE(((SELECT count(*)=count(DISTINCT (t.node_sequence,t.evidence_family_sequence)) FROM msbf_m2.module2_evidence_certification_snapshot t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id)),false) THEN NULL ELSE 'M2_12_ACC_019 physical requirement mismatch'::text END,
    'physical business grain msbf_m2.module2_evidence_certification_snapshot(node_sequence,evidence_family_sequence)'::text
);
/* HF23_ACCEPTANCE_REQUIREMENT M2_12_ACC_020 */
    PERFORM pg_temp.m2_12_add_acceptance_requirement(
    20::smallint,
    'M2_12_ACC_020'::text,
    'GRAIN'::text,
    'Contract reproduction component keys are unique'::text,
    COALESCE(((SELECT (count(*)-count(DISTINCT (t.component_sequence,t.component_contract_code,t.contract_version)))::text FROM msbf_m2.module2_contract_reproduction_snapshot t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id))::text,'<NULL>'),
    '0 duplicates'::text,
    COALESCE(((SELECT count(*)=count(DISTINCT (t.component_sequence,t.component_contract_code,t.contract_version)) FROM msbf_m2.module2_contract_reproduction_snapshot t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id)),false),
    CASE WHEN COALESCE(((SELECT count(*)=count(DISTINCT (t.component_sequence,t.component_contract_code,t.contract_version)) FROM msbf_m2.module2_contract_reproduction_snapshot t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id)),false) THEN NULL ELSE 'M2_12_ACC_020 physical requirement mismatch'::text END,
    'physical business grain msbf_m2.module2_contract_reproduction_snapshot(component_sequence,component_contract_code,contract_version)'::text
);
/* HF23_ACCEPTANCE_REQUIREMENT M2_12_ACC_021 */
    PERFORM pg_temp.m2_12_add_acceptance_requirement(
    21::smallint,
    'M2_12_ACC_021'::text,
    'GRAIN'::text,
    'Capability coverage codes are unique'::text,
    COALESCE(((SELECT (count(*)-count(DISTINCT (t.capability_sequence,t.capability_code)))::text FROM msbf_m2.module2_capability_coverage_snapshot t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id))::text,'<NULL>'),
    '0 duplicates'::text,
    COALESCE(((SELECT count(*)=count(DISTINCT (t.capability_sequence,t.capability_code)) FROM msbf_m2.module2_capability_coverage_snapshot t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id)),false),
    CASE WHEN COALESCE(((SELECT count(*)=count(DISTINCT (t.capability_sequence,t.capability_code)) FROM msbf_m2.module2_capability_coverage_snapshot t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id)),false) THEN NULL ELSE 'M2_12_ACC_021 physical requirement mismatch'::text END,
    'physical business grain msbf_m2.module2_capability_coverage_snapshot(capability_sequence,capability_code)'::text
);
/* HF23_ACCEPTANCE_REQUIREMENT M2_12_ACC_022 */
    PERFORM pg_temp.m2_12_add_acceptance_requirement(
    22::smallint,
    'M2_12_ACC_022'::text,
    'VALIDATION'::text,
    'All positive controls pass'::text,
    COALESCE(((SELECT concat_ws('|',count(*)::text,count(*) FILTER (WHERE status='PASS')::text,count(DISTINCT evidence_code)::text) FROM msbf_ctl.run_evidence e JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=e.run_id WHERE left(e.evidence_code,10)='M2_12_POS_'))::text,'<NULL>'),
    '128 / 128'::text,
    COALESCE(((SELECT count(*)=128 AND count(*) FILTER (WHERE status='PASS')=128 AND count(DISTINCT evidence_code)=128 FROM msbf_ctl.run_evidence e JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=e.run_id WHERE left(e.evidence_code,10)='M2_12_POS_')),false),
    CASE WHEN COALESCE(((SELECT count(*)=128 AND count(*) FILTER (WHERE status='PASS')=128 AND count(DISTINCT evidence_code)=128 FROM msbf_ctl.run_evidence e JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=e.run_id WHERE left(e.evidence_code,10)='M2_12_POS_')),false) THEN NULL ELSE 'M2_12_ACC_022 physical requirement mismatch'::text END,
    'persisted Program 223 evidence rows'::text
);
/* HF23_ACCEPTANCE_REQUIREMENT M2_12_ACC_023 */
    PERFORM pg_temp.m2_12_add_acceptance_requirement(
    23::smallint,
    'M2_12_ACC_023'::text,
    'VALIDATION'::text,
    'All negative controls pass'::text,
    COALESCE(((SELECT concat_ws('|',count(*)::text,count(*) FILTER (WHERE status='PASS')::text,count(DISTINCT evidence_code)::text) FROM msbf_ctl.run_evidence e JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=e.run_id WHERE left(e.evidence_code,10)='M2_12_NEG_'))::text,'<NULL>'),
    '20 / 20'::text,
    COALESCE(((SELECT count(*)=20 AND count(*) FILTER (WHERE status='PASS')=20 AND count(DISTINCT evidence_code)=20 FROM msbf_ctl.run_evidence e JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=e.run_id WHERE left(e.evidence_code,10)='M2_12_NEG_')),false),
    CASE WHEN COALESCE(((SELECT count(*)=20 AND count(*) FILTER (WHERE status='PASS')=20 AND count(DISTINCT evidence_code)=20 FROM msbf_ctl.run_evidence e JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=e.run_id WHERE left(e.evidence_code,10)='M2_12_NEG_')),false) THEN NULL ELSE 'M2_12_ACC_023 physical requirement mismatch'::text END,
    'persisted Program 224 evidence rows'::text
);
/* HF23_ACCEPTANCE_REQUIREMENT M2_12_ACC_024 */
    PERFORM pg_temp.m2_12_add_acceptance_requirement(
    24::smallint,
    'M2_12_ACC_024'::text,
    'EVIDENCE'::text,
    'Generation evidence is complete and passing'::text,
    COALESCE(((SELECT concat_ws('|',count(*)::text,count(*) FILTER (WHERE status='PASS')::text,count(DISTINCT evidence_code)::text) FROM msbf_ctl.run_evidence e JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=e.run_id WHERE e.evidence_code=ANY(ARRAY['M2_12_POLICY_SET_HASH','M2_12_STAGE_CERTIFICATION_SET_HASH','M2_12_CONTRACT_COMPONENT_SET_HASH','M2_12_EVIDENCE_CERTIFICATION_SET_HASH','M2_12_CONTRACT_REPRODUCTION_SET_HASH','M2_12_CAPABILITY_COVERAGE_SET_HASH','M2_12_LATEST_SET_HASH','M2_12_ARCHIVE_SET_HASH','M2_12_REGISTRY_SET_HASH','M2_12_CONTRACT_SET_HASH','M2_12_COMBINED_SET_HASH','M2_12_STAGE_CERTIFICATION_ROWS','M2_12_CONTRACT_COMPONENT_ROWS','M2_12_EVIDENCE_CERTIFICATION_ROWS','M2_12_CONTRACT_REPRODUCTION_ROWS','M2_12_CAPABILITY_COVERAGE_ROWS','M2_12_CANONICAL_ENTITIES','M2_12_COMPONENT_LATEST_ARCHIVE_ROWS_TOTAL','M2_12_APPLICATION_CONSUMPTION_ROWS','M2_12_OPERATIONAL_ACCOUNT_CONSUMPTION_ROWS','M2_12_STRATEGY_SCOPE_CONSUMPTION_ROWS','M2_12_SOURCE_GRAPH_EDGES','M2_12_DETERMINISTIC_MISMATCHES','M2_12_BLOCKING_STAGE_BOUNDARY_FINDINGS']::text[])))::text,'<NULL>'),
    '24 / 24'::text,
    COALESCE(((SELECT count(*)=24 AND count(*) FILTER (WHERE status='PASS')=24 AND count(DISTINCT evidence_code)=24 FROM msbf_ctl.run_evidence e JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=e.run_id WHERE e.evidence_code=ANY(ARRAY['M2_12_POLICY_SET_HASH','M2_12_STAGE_CERTIFICATION_SET_HASH','M2_12_CONTRACT_COMPONENT_SET_HASH','M2_12_EVIDENCE_CERTIFICATION_SET_HASH','M2_12_CONTRACT_REPRODUCTION_SET_HASH','M2_12_CAPABILITY_COVERAGE_SET_HASH','M2_12_LATEST_SET_HASH','M2_12_ARCHIVE_SET_HASH','M2_12_REGISTRY_SET_HASH','M2_12_CONTRACT_SET_HASH','M2_12_COMBINED_SET_HASH','M2_12_STAGE_CERTIFICATION_ROWS','M2_12_CONTRACT_COMPONENT_ROWS','M2_12_EVIDENCE_CERTIFICATION_ROWS','M2_12_CONTRACT_REPRODUCTION_ROWS','M2_12_CAPABILITY_COVERAGE_ROWS','M2_12_CANONICAL_ENTITIES','M2_12_COMPONENT_LATEST_ARCHIVE_ROWS_TOTAL','M2_12_APPLICATION_CONSUMPTION_ROWS','M2_12_OPERATIONAL_ACCOUNT_CONSUMPTION_ROWS','M2_12_STRATEGY_SCOPE_CONSUMPTION_ROWS','M2_12_SOURCE_GRAPH_EDGES','M2_12_DETERMINISTIC_MISMATCHES','M2_12_BLOCKING_STAGE_BOUNDARY_FINDINGS']::text[]))),false),
    CASE WHEN COALESCE(((SELECT count(*)=24 AND count(*) FILTER (WHERE status='PASS')=24 AND count(DISTINCT evidence_code)=24 FROM msbf_ctl.run_evidence e JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=e.run_id WHERE e.evidence_code=ANY(ARRAY['M2_12_POLICY_SET_HASH','M2_12_STAGE_CERTIFICATION_SET_HASH','M2_12_CONTRACT_COMPONENT_SET_HASH','M2_12_EVIDENCE_CERTIFICATION_SET_HASH','M2_12_CONTRACT_REPRODUCTION_SET_HASH','M2_12_CAPABILITY_COVERAGE_SET_HASH','M2_12_LATEST_SET_HASH','M2_12_ARCHIVE_SET_HASH','M2_12_REGISTRY_SET_HASH','M2_12_CONTRACT_SET_HASH','M2_12_COMBINED_SET_HASH','M2_12_STAGE_CERTIFICATION_ROWS','M2_12_CONTRACT_COMPONENT_ROWS','M2_12_EVIDENCE_CERTIFICATION_ROWS','M2_12_CONTRACT_REPRODUCTION_ROWS','M2_12_CAPABILITY_COVERAGE_ROWS','M2_12_CANONICAL_ENTITIES','M2_12_COMPONENT_LATEST_ARCHIVE_ROWS_TOTAL','M2_12_APPLICATION_CONSUMPTION_ROWS','M2_12_OPERATIONAL_ACCOUNT_CONSUMPTION_ROWS','M2_12_STRATEGY_SCOPE_CONSUMPTION_ROWS','M2_12_SOURCE_GRAPH_EDGES','M2_12_DETERMINISTIC_MISMATCHES','M2_12_BLOCKING_STAGE_BOUNDARY_FINDINGS']::text[]))),false) THEN NULL ELSE 'M2_12_ACC_024 physical requirement mismatch'::text END,
    'exact frozen 24-code generation evidence authority'::text
);
/* HF23_ACCEPTANCE_REQUIREMENT M2_12_ACC_025 */
    PERFORM pg_temp.m2_12_add_acceptance_requirement(
    25::smallint,
    'M2_12_ACC_025'::text,
    'EVIDENCE'::text,
    'No failed M2.12 evidence rows exist'::text,
    COALESCE(((SELECT count(*)::text FROM msbf_ctl.run_evidence e JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=e.run_id WHERE left(e.evidence_code,6)='M2_12_' AND e.status<>'PASS'))::text,'<NULL>'),
    '0'::text,
    COALESCE(((SELECT count(*)=0 FROM msbf_ctl.run_evidence e JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=e.run_id WHERE left(e.evidence_code,6)='M2_12_' AND e.status<>'PASS')),false),
    CASE WHEN COALESCE(((SELECT count(*)=0 FROM msbf_ctl.run_evidence e JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=e.run_id WHERE left(e.evidence_code,6)='M2_12_' AND e.status<>'PASS')),false) THEN NULL ELSE 'M2_12_ACC_025 physical requirement mismatch'::text END,
    'all persisted M2.12 evidence before acceptance write'::text
);
/* HF23_ACCEPTANCE_REQUIREMENT M2_12_ACC_026 */
    PERFORM pg_temp.m2_12_add_acceptance_requirement(
    26::smallint,
    'M2_12_ACC_026'::text,
    'RECONCILIATION'::text,
    'Deterministic M2.12 expected-versus-actual mismatches are zero'::text,
    COALESCE(((SELECT concat_ws('|',r.total_mismatch_count::text,(SELECT count(*) FROM tmp_hash_m2_12_acceptance_detail WHERE mismatch_flag)::text) FROM tmp_hash_m2_12_acceptance_reconciliation r))::text,'<NULL>'),
    '0'::text,
    COALESCE(((SELECT r.total_mismatch_count=0 AND (SELECT count(*) FROM tmp_hash_m2_12_acceptance_detail WHERE mismatch_flag)=0 FROM tmp_hash_m2_12_acceptance_reconciliation r)),false),
    CASE WHEN COALESCE(((SELECT r.total_mismatch_count=0 AND (SELECT count(*) FROM tmp_hash_m2_12_acceptance_detail WHERE mismatch_flag)=0 FROM tmp_hash_m2_12_acceptance_reconciliation r)),false) THEN NULL ELSE 'M2_12_ACC_026 physical requirement mismatch'::text END,
    'independent physical row/set/contract/combined/sequence reconstruction'::text
);
/* HF23_ACCEPTANCE_REQUIREMENT M2_12_ACC_027 */
    PERFORM pg_temp.m2_12_add_acceptance_requirement(
    27::smallint,
    'M2_12_ACC_027'::text,
    'BOUNDARY'::text,
    'Blocking and physical stage-boundary findings are zero'::text,
    COALESCE(((SELECT concat_ws('|',
        count(*)::text,
        count(*) FILTER (WHERE certification_status='PASS')::text,
        coalesce(sum(required_evidence_rows),0)::text,
        coalesce(sum(physical_required_evidence_rows),0)::text,
        coalesce(sum(duplicate_required_evidence_rows),0)::text,
        count(*) FILTER (WHERE coalesce(nullif(missing_required_evidence_codes,''),'')<>'')::text,
        count(*) FILTER (WHERE coalesce(nullif(nonpass_evidence_codes,''),'')<>'')::text,
        count(*) FILTER (WHERE coalesce(nullif(violation_evidence_codes,''),'')<>'')::text,
        (SELECT count(*) FROM tmp_accept_m2_12_source_edges)::text,
        (SELECT count(*) FILTER (WHERE edge_status='PASS') FROM tmp_accept_m2_12_source_edges)::text,
        (SELECT coalesce(min(e.metric_value_text),'<MISSING>') FROM msbf_ctl.run_evidence e JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=e.run_id WHERE e.evidence_code='M2_12_BLOCKING_STAGE_BOUNDARY_FINDINGS' AND e.status='PASS')::text)
      FROM tmp_accept_m2_12_stage_boundary))::text,'<NULL>'),
    '12/12 stages PASS | 70/70 controls | 19/19 edges | 0 findings'::text,
    COALESCE(((SELECT count(*)=12
       AND count(*) FILTER (WHERE certification_status='PASS')=12
       AND coalesce(sum(required_evidence_rows),0)=70
       AND coalesce(sum(physical_required_evidence_rows),0)=70
       AND coalesce(sum(duplicate_required_evidence_rows),0)=0
       AND count(*) FILTER (WHERE coalesce(nullif(missing_required_evidence_codes,''),'')<>'')=0
       AND count(*) FILTER (WHERE coalesce(nullif(nonpass_evidence_codes,''),'')<>'')=0
       AND count(*) FILTER (WHERE coalesce(nullif(violation_evidence_codes,''),'')<>'')=0
       AND (SELECT count(*) FROM tmp_accept_m2_12_source_edges)=19
       AND (SELECT count(*) FILTER (WHERE edge_status='PASS') FROM tmp_accept_m2_12_source_edges)=19
       AND (SELECT count(*) FROM msbf_ctl.run_evidence e JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=e.run_id WHERE e.evidence_code='M2_12_BLOCKING_STAGE_BOUNDARY_FINDINGS')=1
       AND (SELECT count(*) FROM msbf_ctl.run_evidence e JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=e.run_id WHERE e.evidence_code='M2_12_BLOCKING_STAGE_BOUNDARY_FINDINGS' AND e.segment_key='M2_12' AND e.metric_name='M2_12_BLOCKING_STAGE_BOUNDARY_FINDINGS' AND e.status='PASS' AND e.metric_value_numeric IS NULL AND e.metric_value_text='0' AND e.unit_code='ROWS' AND e.threshold_value_numeric IS NULL)=1
      FROM tmp_accept_m2_12_stage_boundary)),false),
    CASE WHEN COALESCE(((SELECT count(*)=12
       AND count(*) FILTER (WHERE certification_status='PASS')=12
       AND coalesce(sum(required_evidence_rows),0)=70
       AND coalesce(sum(physical_required_evidence_rows),0)=70
       AND coalesce(sum(duplicate_required_evidence_rows),0)=0
       AND count(*) FILTER (WHERE coalesce(nullif(missing_required_evidence_codes,''),'')<>'')=0
       AND count(*) FILTER (WHERE coalesce(nullif(nonpass_evidence_codes,''),'')<>'')=0
       AND count(*) FILTER (WHERE coalesce(nullif(violation_evidence_codes,''),'')<>'')=0
       AND (SELECT count(*) FROM tmp_accept_m2_12_source_edges)=19
       AND (SELECT count(*) FILTER (WHERE edge_status='PASS') FROM tmp_accept_m2_12_source_edges)=19
       AND (SELECT count(*) FROM msbf_ctl.run_evidence e JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=e.run_id WHERE e.evidence_code='M2_12_BLOCKING_STAGE_BOUNDARY_FINDINGS')=1
       AND (SELECT count(*) FROM msbf_ctl.run_evidence e JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=e.run_id WHERE e.evidence_code='M2_12_BLOCKING_STAGE_BOUNDARY_FINDINGS' AND e.segment_key='M2_12' AND e.metric_name='M2_12_BLOCKING_STAGE_BOUNDARY_FINDINGS' AND e.status='PASS' AND e.metric_value_numeric IS NULL AND e.metric_value_text='0' AND e.unit_code='ROWS' AND e.threshold_value_numeric IS NULL)=1
      FROM tmp_accept_m2_12_stage_boundary)),false) THEN NULL ELSE 'M2_12_ACC_027 physical requirement mismatch'::text END,
    'Program-225-HF23-owned persisted-state reconstruction of 12 stages, 70 controls, and 19 edges'::text
);
/* HF23_ACCEPTANCE_REQUIREMENT M2_12_ACC_028 */
    PERFORM pg_temp.m2_12_add_acceptance_requirement(
    28::smallint,
    'M2_12_ACC_028'::text,
    'CHAIN'::text,
    'Fourteen non-M2.11 source edges (two M1.17 component, ten linear Module 2, two auxiliary anchors) reconcile'::text,
    COALESCE(((SELECT concat_ws('|',count(*)::text,count(*) FILTER (WHERE edge_status='PASS')::text,count(*) FILTER (WHERE source_hash_mismatch_flag OR target_hash_mismatch_flag)::text) FROM tmp_accept_m2_12_source_edges WHERE edge_sequence BETWEEN 1 AND 14))::text,'<NULL>'),
    '14/14 PASS | 0 breaks'::text,
    COALESCE(((SELECT count(*)=14 AND count(*) FILTER (WHERE edge_status='PASS')=14 AND count(*) FILTER (WHERE source_hash_mismatch_flag OR target_hash_mismatch_flag)=0 FROM tmp_accept_m2_12_source_edges WHERE edge_sequence BETWEEN 1 AND 14)),false),
    CASE WHEN COALESCE(((SELECT count(*)=14 AND count(*) FILTER (WHERE edge_status='PASS')=14 AND count(*) FILTER (WHERE source_hash_mismatch_flag OR target_hash_mismatch_flag)=0 FROM tmp_accept_m2_12_source_edges WHERE edge_sequence BETWEEN 1 AND 14)),false) THEN NULL ELSE 'M2_12_ACC_028 physical requirement mismatch'::text END,
    'Program-225-HF23-owned reconstruction of edge sequences 1-14'::text
);
/* HF23_ACCEPTANCE_REQUIREMENT M2_12_ACC_029 */
    PERFORM pg_temp.m2_12_add_acceptance_requirement(
    29::smallint,
    'M2_12_ACC_029'::text,
    'CHAIN'::text,
    'M2.11 five-source graph reconciles'::text,
    COALESCE(((SELECT concat_ws('|',count(*)::text,count(*) FILTER (WHERE edge_status='PASS')::text,count(*) FILTER (WHERE source_hash_mismatch_flag OR target_hash_mismatch_flag)::text) FROM tmp_accept_m2_12_source_edges WHERE edge_sequence BETWEEN 15 AND 19))::text,'<NULL>'),
    '5/5 PASS | 0 mismatches'::text,
    COALESCE(((SELECT count(*)=5 AND count(*) FILTER (WHERE edge_status='PASS')=5 AND count(*) FILTER (WHERE source_hash_mismatch_flag OR target_hash_mismatch_flag)=0 FROM tmp_accept_m2_12_source_edges WHERE edge_sequence BETWEEN 15 AND 19)),false),
    CASE WHEN COALESCE(((SELECT count(*)=5 AND count(*) FILTER (WHERE edge_status='PASS')=5 AND count(*) FILTER (WHERE source_hash_mismatch_flag OR target_hash_mismatch_flag)=0 FROM tmp_accept_m2_12_source_edges WHERE edge_sequence BETWEEN 15 AND 19)),false) THEN NULL ELSE 'M2_12_ACC_029 physical requirement mismatch'::text END,
    'Program-225-HF23-owned reconstruction of five direct M2.11 edges'::text
);
/* HF23_ACCEPTANCE_REQUIREMENT M2_12_ACC_030 */
    PERFORM pg_temp.m2_12_add_acceptance_requirement(
    30::smallint,
    'M2_12_ACC_030'::text,
    'ARCHIVE'::text,
    'All thirteen component latest/archive reproduction mismatch counts are zero'::text,
    COALESCE(((SELECT concat_ws('|',count(*)::text,sum(payload_mismatch_count+missing_latest_rows+missing_archive_rows+latest_duplicate_key_rows+archive_duplicate_key_rows)::text,count(*) FILTER (WHERE reproduction_status='PASS')::text) FROM msbf_m2.module2_contract_reproduction_snapshot r JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=r.module1_run_id))::text,'<NULL>'),
    '0'::text,
    COALESCE(((SELECT count(*)=13 AND coalesce(sum(payload_mismatch_count+missing_latest_rows+missing_archive_rows+latest_duplicate_key_rows+archive_duplicate_key_rows),0)=0 AND count(*) FILTER (WHERE reproduction_status='PASS')=13 AND bool_and(observed_latest_rows=expected_latest_rows AND observed_archive_rows=expected_archive_rows AND observed_latest_set_hash=expected_latest_set_hash AND observed_archive_set_hash=expected_archive_set_hash) FROM msbf_m2.module2_contract_reproduction_snapshot r JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=r.module1_run_id)),false),
    CASE WHEN COALESCE(((SELECT count(*)=13 AND coalesce(sum(payload_mismatch_count+missing_latest_rows+missing_archive_rows+latest_duplicate_key_rows+archive_duplicate_key_rows),0)=0 AND count(*) FILTER (WHERE reproduction_status='PASS')=13 AND bool_and(observed_latest_rows=expected_latest_rows AND observed_archive_rows=expected_archive_rows AND observed_latest_set_hash=expected_latest_set_hash AND observed_archive_set_hash=expected_archive_set_hash) FROM msbf_m2.module2_contract_reproduction_snapshot r JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=r.module1_run_id)),false) THEN NULL ELSE 'M2_12_ACC_030 physical requirement mismatch'::text END,
    'all thirteen persisted component reproduction rows'::text
);
/* HF23_ACCEPTANCE_REQUIREMENT M2_12_ACC_031 */
    PERFORM pg_temp.m2_12_add_acceptance_requirement(
    31::smallint,
    'M2_12_ACC_031'::text,
    'ARCHIVE'::text,
    'G3 archive immutability control is present and proven'::text,
    COALESCE(((SELECT concat_ws('|',(SELECT count(*) FROM pg_catalog.pg_trigger t WHERE t.tgrelid='msbf_ctl.m2_12_g3_bundle_archive'::regclass AND t.tgname='trg_m2_12_g3_archive_immutable' AND NOT t.tgisinternal),(SELECT count(*) FROM msbf_ctl.run_evidence e JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=e.run_id WHERE e.evidence_code IN ('M2_12_NEG_008_ARCHIVE_UPDATE','M2_12_NEG_009_ARCHIVE_DELETE') AND e.status='PASS'))))::text,'<NULL>'),
    'PASS'::text,
    COALESCE(((SELECT (SELECT count(*) FROM pg_catalog.pg_trigger t WHERE t.tgrelid='msbf_ctl.m2_12_g3_bundle_archive'::regclass AND t.tgname='trg_m2_12_g3_archive_immutable' AND NOT t.tgisinternal)=1 AND (SELECT count(*) FROM msbf_ctl.run_evidence e JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=e.run_id WHERE e.evidence_code IN ('M2_12_NEG_008_ARCHIVE_UPDATE','M2_12_NEG_009_ARCHIVE_DELETE') AND e.status='PASS')=2)),false),
    CASE WHEN COALESCE(((SELECT (SELECT count(*) FROM pg_catalog.pg_trigger t WHERE t.tgrelid='msbf_ctl.m2_12_g3_bundle_archive'::regclass AND t.tgname='trg_m2_12_g3_archive_immutable' AND NOT t.tgisinternal)=1 AND (SELECT count(*) FROM msbf_ctl.run_evidence e JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=e.run_id WHERE e.evidence_code IN ('M2_12_NEG_008_ARCHIVE_UPDATE','M2_12_NEG_009_ARCHIVE_DELETE') AND e.status='PASS')=2)),false) THEN NULL ELSE 'M2_12_ACC_031 physical requirement mismatch'::text END,
    'catalog-native trigger identity plus isolated negative controls 008/009'::text
);
/* HF23_ACCEPTANCE_REQUIREMENT M2_12_ACC_032 */
    PERFORM pg_temp.m2_12_add_acceptance_requirement(
    32::smallint,
    'M2_12_ACC_032'::text,
    'CONSUMPTION'::text,
    'Application origination view has exact row count'::text,
    COALESCE(((SELECT count(*)::text FROM msbf_m2.v_m2_12_application_origination_consumption v JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=v.module1_run_id))::text,'<NULL>'),
    '1500'::text,
    COALESCE(((SELECT count(*)=1500 FROM msbf_m2.v_m2_12_application_origination_consumption v JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=v.module1_run_id)),false),
    CASE WHEN COALESCE(((SELECT count(*)=1500 FROM msbf_m2.v_m2_12_application_origination_consumption v JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=v.module1_run_id)),false) THEN NULL ELSE 'M2_12_ACC_032 physical requirement mismatch'::text END,
    'physical application consumption view'::text
);
/* HF23_ACCEPTANCE_REQUIREMENT M2_12_ACC_033 */
    PERFORM pg_temp.m2_12_add_acceptance_requirement(
    33::smallint,
    'M2_12_ACC_033'::text,
    'CONSUMPTION'::text,
    'Application origination view has exact grain, 750 applications, two scenarios, and complete physical lineage anchors'::text,
    COALESCE(((SELECT concat_ws('|',
        count(*)::text,
        count(DISTINCT v.merchant_application_id)::text,
        count(DISTINCT v.scenario_code)::text,
        (count(*)-count(DISTINCT (v.scenario_code,v.merchant_application_id)))::text,
        count(*) FILTER (WHERE
            v.merchant_application_id IS NULL
            OR v.merchant_id IS NULL
            OR v.m1_15_contract_row_hash IS NULL
            OR v.m1_16_contract_row_hash IS NULL
            OR v.m2_1_source_g2_combined_hash IS NULL
            OR v.m2_1_contract_row_hash IS NULL
            OR v.m2_2_request_contract_row_hash IS NULL
            OR v.m2_2_pricing_contract_row_hash IS NULL
            OR v.m2_3_contract_row_hash IS NULL
            OR v.m2_4_contract_row_hash IS NULL
        )::text)
      FROM msbf_m2.v_m2_12_application_origination_consumption v
      JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=v.module1_run_id))::text,'<NULL>'),
    '1500 rows / 750 applications / 2 scenarios / 0 errors'::text,
    COALESCE(((SELECT count(*)=1500
        AND count(DISTINCT v.merchant_application_id)=750
        AND count(DISTINCT v.scenario_code)=2
        AND count(*)=count(DISTINCT (v.scenario_code,v.merchant_application_id))
        AND count(*) FILTER (WHERE
            v.merchant_application_id IS NULL
            OR v.merchant_id IS NULL
            OR v.m1_15_contract_row_hash IS NULL
            OR v.m1_16_contract_row_hash IS NULL
            OR v.m2_1_source_g2_combined_hash IS NULL
            OR v.m2_1_contract_row_hash IS NULL
            OR v.m2_2_request_contract_row_hash IS NULL
            OR v.m2_2_pricing_contract_row_hash IS NULL
            OR v.m2_3_contract_row_hash IS NULL
            OR v.m2_4_contract_row_hash IS NULL
        )=0
      FROM msbf_m2.v_m2_12_application_origination_consumption v
      JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=v.module1_run_id)),false),
    CASE WHEN COALESCE(((SELECT count(*)=1500
        AND count(DISTINCT v.merchant_application_id)=750
        AND count(DISTINCT v.scenario_code)=2
        AND count(*)=count(DISTINCT (v.scenario_code,v.merchant_application_id))
        AND count(*) FILTER (WHERE
            v.merchant_application_id IS NULL
            OR v.merchant_id IS NULL
            OR v.m1_15_contract_row_hash IS NULL
            OR v.m1_16_contract_row_hash IS NULL
            OR v.m2_1_source_g2_combined_hash IS NULL
            OR v.m2_1_contract_row_hash IS NULL
            OR v.m2_2_request_contract_row_hash IS NULL
            OR v.m2_2_pricing_contract_row_hash IS NULL
            OR v.m2_3_contract_row_hash IS NULL
            OR v.m2_4_contract_row_hash IS NULL
        )=0
      FROM msbf_m2.v_m2_12_application_origination_consumption v
      JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=v.module1_run_id)),false)
      THEN NULL ELSE 'M2_12_ACC_033 physical requirement mismatch'::text END,
    'application view exact scenario/application grain plus M1.15, M1.16, M1.17/G2, and M2.1-M2.4 physical lineage anchors'::text
);
/* HF23_ACCEPTANCE_REQUIREMENT M2_12_ACC_034 */
    PERFORM pg_temp.m2_12_add_acceptance_requirement(
    34::smallint,
    'M2_12_ACC_034'::text,
    'CONSUMPTION'::text,
    'Operational-account view has exact row count'::text,
    COALESCE(((SELECT count(*)::text FROM msbf_m2.v_m2_12_operational_account_consumption v JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=v.module1_run_id))::text,'<NULL>'),
    '59'::text,
    COALESCE(((SELECT count(*)=59 FROM msbf_m2.v_m2_12_operational_account_consumption v JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=v.module1_run_id)),false),
    CASE WHEN COALESCE(((SELECT count(*)=59 FROM msbf_m2.v_m2_12_operational_account_consumption v JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=v.module1_run_id)),false) THEN NULL ELSE 'M2_12_ACC_034 physical requirement mismatch'::text END,
    'physical operational-account consumption view'::text
);
/* HF23_ACCEPTANCE_REQUIREMENT M2_12_ACC_035 */
    PERFORM pg_temp.m2_12_add_acceptance_requirement(
    35::smallint,
    'M2_12_ACC_035'::text,
    'CONSUMPTION'::text,
    'Operational-account view has exact grain and no orphans/multiplicity'::text,
    COALESCE(((SELECT concat_ws('|',count(*)::text,(count(*)-count(DISTINCT (scenario_code,merchant_application_id,synthetic_account_id,synthetic_advance_id)))::text,count(*) FILTER (WHERE merchant_application_id IS NULL OR synthetic_account_id IS NULL OR synthetic_advance_id IS NULL OR m2_4_contract_row_hash IS NULL OR m2_10_contract_row_hash IS NULL)::text) FROM msbf_m2.v_m2_12_operational_account_consumption v JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=v.module1_run_id))::text,'<NULL>'),
    '59 rows / 0 errors'::text,
    COALESCE(((SELECT count(*)=59 AND count(*)=count(DISTINCT (scenario_code,merchant_application_id,synthetic_account_id,synthetic_advance_id)) AND count(*) FILTER (WHERE merchant_application_id IS NULL OR synthetic_account_id IS NULL OR synthetic_advance_id IS NULL OR m2_4_contract_row_hash IS NULL OR m2_10_contract_row_hash IS NULL)=0 FROM msbf_m2.v_m2_12_operational_account_consumption v JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=v.module1_run_id)),false),
    CASE WHEN COALESCE(((SELECT count(*)=59 AND count(*)=count(DISTINCT (scenario_code,merchant_application_id,synthetic_account_id,synthetic_advance_id)) AND count(*) FILTER (WHERE merchant_application_id IS NULL OR synthetic_account_id IS NULL OR synthetic_advance_id IS NULL OR m2_4_contract_row_hash IS NULL OR m2_10_contract_row_hash IS NULL)=0 FROM msbf_m2.v_m2_12_operational_account_consumption v JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=v.module1_run_id)),false) THEN NULL ELSE 'M2_12_ACC_035 physical requirement mismatch'::text END,
    'operational view exact account/advance grain and lineage anchors'::text
);
/* HF23_ACCEPTANCE_REQUIREMENT M2_12_ACC_036 */
    PERFORM pg_temp.m2_12_add_acceptance_requirement(
    36::smallint,
    'M2_12_ACC_036'::text,
    'CONSUMPTION'::text,
    'Operational-account scenario posture is exact'::text,
    COALESCE(((SELECT concat_ws('|',count(*) FILTER (WHERE scenario_code='BASELINE')::text,count(*) FILTER (WHERE scenario_code='RECESSION_ENERGY')::text) FROM msbf_m2.v_m2_12_operational_account_consumption v JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=v.module1_run_id))::text,'<NULL>'),
    '44 BASELINE / 15 RECESSION_ENERGY'::text,
    COALESCE(((SELECT count(*) FILTER (WHERE scenario_code='BASELINE')=44 AND count(*) FILTER (WHERE scenario_code='RECESSION_ENERGY')=15 AND count(*)=59 FROM msbf_m2.v_m2_12_operational_account_consumption v JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=v.module1_run_id)),false),
    CASE WHEN COALESCE(((SELECT count(*) FILTER (WHERE scenario_code='BASELINE')=44 AND count(*) FILTER (WHERE scenario_code='RECESSION_ENERGY')=15 AND count(*)=59 FROM msbf_m2.v_m2_12_operational_account_consumption v JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=v.module1_run_id)),false) THEN NULL ELSE 'M2_12_ACC_036 physical requirement mismatch'::text END,
    'frozen BASELINE and RECESSION_ENERGY operational posture'::text
);
/* HF23_ACCEPTANCE_REQUIREMENT M2_12_ACC_037 */
    PERFORM pg_temp.m2_12_add_acceptance_requirement(
    37::smallint,
    'M2_12_ACC_037'::text,
    'CONSUMPTION'::text,
    'Strategy-scope view has exact row count and grain'::text,
    COALESCE(((SELECT concat_ws('|',count(*)::text,count(DISTINCT strategy_profile_code)::text,count(DISTINCT reporting_scope_code)::text,(count(*)-count(DISTINCT (strategy_profile_code,reporting_scope_code)))::text) FROM msbf_m2.v_m2_12_strategy_scope_consumption v JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=v.module1_run_id))::text,'<NULL>'),
    '24 rows / 8 strategies x 3 scopes'::text,
    COALESCE(((SELECT count(*)=24 AND count(DISTINCT strategy_profile_code)=8 AND count(DISTINCT reporting_scope_code)=3 AND count(*)=count(DISTINCT (strategy_profile_code,reporting_scope_code)) FROM msbf_m2.v_m2_12_strategy_scope_consumption v JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=v.module1_run_id)),false),
    CASE WHEN COALESCE(((SELECT count(*)=24 AND count(DISTINCT strategy_profile_code)=8 AND count(DISTINCT reporting_scope_code)=3 AND count(*)=count(DISTINCT (strategy_profile_code,reporting_scope_code)) FROM msbf_m2.v_m2_12_strategy_scope_consumption v JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=v.module1_run_id)),false) THEN NULL ELSE 'M2_12_ACC_037 physical requirement mismatch'::text END,
    'strategy-profile × reporting-scope physical view grain'::text
);
/* HF23_ACCEPTANCE_REQUIREMENT M2_12_ACC_038 */
    PERFORM pg_temp.m2_12_add_acceptance_requirement(
    38::smallint,
    'M2_12_ACC_038'::text,
    'M2_11'::text,
    'Accepted frontier evidence reconciles'::text,
    COALESCE(((SELECT concat_ws('|',count(*) FILTER (WHERE frontier_eligible_flag)::text,count(*) FILTER (WHERE non_dominated_flag)::text,count(*) FILTER (WHERE frontier_rank=1)::text) FROM msbf_m2.v_m2_12_strategy_scope_consumption v JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=v.module1_run_id))::text,'<NULL>'),
    '18 eligible / 16 non-dominated / 16 rank-1'::text,
    COALESCE(((SELECT count(*) FILTER (WHERE frontier_eligible_flag)=18 AND count(*) FILTER (WHERE non_dominated_flag)=16 AND count(*) FILTER (WHERE frontier_rank=1)=16 FROM msbf_m2.v_m2_12_strategy_scope_consumption v JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=v.module1_run_id)),false),
    CASE WHEN COALESCE(((SELECT count(*) FILTER (WHERE frontier_eligible_flag)=18 AND count(*) FILTER (WHERE non_dominated_flag)=16 AND count(*) FILTER (WHERE frontier_rank=1)=16 FROM msbf_m2.v_m2_12_strategy_scope_consumption v JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=v.module1_run_id)),false) THEN NULL ELSE 'M2_12_ACC_038 physical requirement mismatch'::text END,
    'accepted M2.11 frontier fields copied into the M2.12 strategy scope view'::text
);
/* HF23_ACCEPTANCE_REQUIREMENT M2_12_ACC_039 */
    PERFORM pg_temp.m2_12_add_acceptance_requirement(
    39::smallint,
    'M2_12_ACC_039'::text,
    'M2_11'::text,
    'Accepted governance-review priorities reconcile without deployment interpretation'::text,
    COALESCE(((SELECT concat_ws('|',count(*) FILTER (WHERE primary_governance_review_flag AND governance_review_priority_code='PRIMARY_GOVERNANCE_REVIEW')::text,count(*) FILTER (WHERE deployment_authorized_flag OR module3_execution_authorized_flag)::text,count(*) FILTER (WHERE primary_governance_review_flag AND NOT ((reporting_scope_code='BASELINE' AND strategy_profile_code='BALANCED_FRONTIER') OR (reporting_scope_code IN ('PORTFOLIO','RECESSION_ENERGY') AND strategy_profile_code='PRICE_FOR_RISK')))::text) FROM msbf_m2.v_m2_12_strategy_scope_consumption v JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=v.module1_run_id))::text,'<NULL>'),
    '3 PRIMARY_GOVERNANCE_REVIEW / deployment NOT_AUTHORIZED'::text,
    COALESCE(((SELECT count(*) FILTER (WHERE primary_governance_review_flag AND governance_review_priority_code='PRIMARY_GOVERNANCE_REVIEW')=3 AND count(*) FILTER (WHERE deployment_authorized_flag OR module3_execution_authorized_flag)=0 AND count(*) FILTER (WHERE primary_governance_review_flag AND NOT ((reporting_scope_code='BASELINE' AND strategy_profile_code='BALANCED_FRONTIER') OR (reporting_scope_code IN ('PORTFOLIO','RECESSION_ENERGY') AND strategy_profile_code='PRICE_FOR_RISK')))=0 FROM msbf_m2.v_m2_12_strategy_scope_consumption v JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=v.module1_run_id)),false),
    CASE WHEN COALESCE(((SELECT count(*) FILTER (WHERE primary_governance_review_flag AND governance_review_priority_code='PRIMARY_GOVERNANCE_REVIEW')=3 AND count(*) FILTER (WHERE deployment_authorized_flag OR module3_execution_authorized_flag)=0 AND count(*) FILTER (WHERE primary_governance_review_flag AND NOT ((reporting_scope_code='BASELINE' AND strategy_profile_code='BALANCED_FRONTIER') OR (reporting_scope_code IN ('PORTFOLIO','RECESSION_ENERGY') AND strategy_profile_code='PRICE_FOR_RISK')))=0 FROM msbf_m2.v_m2_12_strategy_scope_consumption v JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=v.module1_run_id)),false) THEN NULL ELSE 'M2_12_ACC_039 physical requirement mismatch'::text END,
    'three exact governance-review priority rows; deployment interpretation prohibited'::text
);
/* HF23_ACCEPTANCE_REQUIREMENT M2_12_ACC_040 */
    PERFORM pg_temp.m2_12_add_acceptance_requirement(
    40::smallint,
    'M2_12_ACC_040'::text,
    'M2_11'::text,
    'M2.11 stress/non-improvement, accepted PARTIAL posture, and latest/archive reproduction remain exact'::text,
    COALESCE(((SELECT concat_ws('|',
        count(*)::text,
        count(*) FILTER (WHERE strategy_evidence_status='PARTIAL')::text,
        count(*) FILTER (WHERE stress_nonimprovement_pass_flag)::text,
        coalesce(sum(hard_constraint_violation_count+source_risk_improvement_violation_count+source_return_improvement_violation_count+strategy_access_improvement_violation_count+strategy_feasibility_improvement_violation_count+comparable_payment_burden_improvement_violation_count+comparable_servicing_burden_improvement_violation_count+stress_improvement_violation_count),0)::text,
        (SELECT count(*)::text FROM msbf_m2.module2_contract_reproduction_snapshot r WHERE r.module1_run_id=ctx.module1_run_id AND r.component_sequence=13),
        (SELECT coalesce(sum(payload_mismatch_count+missing_latest_rows+missing_archive_rows+latest_duplicate_key_rows+archive_duplicate_key_rows),0)::text FROM msbf_m2.module2_contract_reproduction_snapshot r WHERE r.module1_run_id=ctx.module1_run_id AND r.component_sequence=13))
      FROM msbf_m2.v_m2_12_strategy_scope_consumption v
      JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=v.module1_run_id
     GROUP BY ctx.module1_run_id))::text,'<NULL>'),
    '24|24|24|0|1|0'::text,
    COALESCE(((SELECT count(*)=24
       AND count(*) FILTER (WHERE strategy_evidence_status='PARTIAL')=24
       AND count(*) FILTER (WHERE stress_nonimprovement_pass_flag)=24
       AND coalesce(sum(hard_constraint_violation_count+source_risk_improvement_violation_count+source_return_improvement_violation_count+strategy_access_improvement_violation_count+strategy_feasibility_improvement_violation_count+comparable_payment_burden_improvement_violation_count+comparable_servicing_burden_improvement_violation_count+stress_improvement_violation_count),0)=0
       AND (SELECT count(*) FROM msbf_m2.module2_contract_reproduction_snapshot r WHERE r.module1_run_id=ctx.module1_run_id AND r.component_sequence=13)=1
       AND (SELECT coalesce(sum(payload_mismatch_count+missing_latest_rows+missing_archive_rows+latest_duplicate_key_rows+archive_duplicate_key_rows),0) FROM msbf_m2.module2_contract_reproduction_snapshot r WHERE r.module1_run_id=ctx.module1_run_id AND r.component_sequence=13)=0
      FROM msbf_m2.v_m2_12_strategy_scope_consumption v
      JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=v.module1_run_id
     GROUP BY ctx.module1_run_id)),false),
    CASE WHEN COALESCE(((SELECT count(*)=24
       AND count(*) FILTER (WHERE strategy_evidence_status='PARTIAL')=24
       AND count(*) FILTER (WHERE stress_nonimprovement_pass_flag)=24
       AND coalesce(sum(hard_constraint_violation_count+source_risk_improvement_violation_count+source_return_improvement_violation_count+strategy_access_improvement_violation_count+strategy_feasibility_improvement_violation_count+comparable_payment_burden_improvement_violation_count+comparable_servicing_burden_improvement_violation_count+stress_improvement_violation_count),0)=0
       AND (SELECT count(*) FROM msbf_m2.module2_contract_reproduction_snapshot r WHERE r.module1_run_id=ctx.module1_run_id AND r.component_sequence=13)=1
       AND (SELECT coalesce(sum(payload_mismatch_count+missing_latest_rows+missing_archive_rows+latest_duplicate_key_rows+archive_duplicate_key_rows),0) FROM msbf_m2.module2_contract_reproduction_snapshot r WHERE r.module1_run_id=ctx.module1_run_id AND r.component_sequence=13)=0
      FROM msbf_m2.v_m2_12_strategy_scope_consumption v
      JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=v.module1_run_id
     GROUP BY ctx.module1_run_id)),false)
      THEN NULL ELSE 'M2_12_ACC_040 physical requirement mismatch'::text END,
    'exact 24-row accepted M2.11 PARTIAL strategy posture plus one clean component-13 reproduction row'::text
);
/* HF23_ACCEPTANCE_REQUIREMENT M2_12_ACC_041 */
    PERFORM pg_temp.m2_12_add_acceptance_requirement(
    41::smallint,
    'M2_12_ACC_041'::text,
    'SCOPE'::text,
    'Capability coverage catalog has all twenty frozen codes and statuses'::text,
    COALESCE(((SELECT concat_ws('|',(SELECT count(*) FROM tmp_accept_m2_12_capability_authority),(SELECT count(*) FROM msbf_m2.module2_capability_coverage_snapshot s JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=s.module1_run_id),(SELECT count(*) FROM ((SELECT capability_sequence,capability_code,coverage_status_code,certifying_stage_code,claim_boundary,production_action_authorized_flag,legal_or_regulatory_certified_flag,notes FROM tmp_accept_m2_12_capability_authority EXCEPT SELECT capability_sequence,capability_code,coverage_status_code,certifying_stage_code,claim_boundary,production_action_authorized_flag,legal_or_regulatory_certified_flag,notes FROM msbf_m2.module2_capability_coverage_snapshot s JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=s.module1_run_id) UNION ALL (SELECT capability_sequence,capability_code,coverage_status_code,certifying_stage_code,claim_boundary,production_action_authorized_flag,legal_or_regulatory_certified_flag,notes FROM msbf_m2.module2_capability_coverage_snapshot s JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=s.module1_run_id EXCEPT SELECT capability_sequence,capability_code,coverage_status_code,certifying_stage_code,claim_boundary,production_action_authorized_flag,legal_or_regulatory_certified_flag,notes FROM tmp_accept_m2_12_capability_authority)) d))))::text,'<NULL>'),
    '20 / 20'::text,
    COALESCE((((SELECT count(*) FROM tmp_accept_m2_12_capability_authority)=20 AND (SELECT count(*) FROM msbf_m2.module2_capability_coverage_snapshot s JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=s.module1_run_id)=20 AND (SELECT count(*) FROM ((SELECT capability_sequence,capability_code,coverage_status_code,certifying_stage_code,claim_boundary,production_action_authorized_flag,legal_or_regulatory_certified_flag,notes FROM tmp_accept_m2_12_capability_authority EXCEPT SELECT capability_sequence,capability_code,coverage_status_code,certifying_stage_code,claim_boundary,production_action_authorized_flag,legal_or_regulatory_certified_flag,notes FROM msbf_m2.module2_capability_coverage_snapshot s JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=s.module1_run_id) UNION ALL (SELECT capability_sequence,capability_code,coverage_status_code,certifying_stage_code,claim_boundary,production_action_authorized_flag,legal_or_regulatory_certified_flag,notes FROM msbf_m2.module2_capability_coverage_snapshot s JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=s.module1_run_id EXCEPT SELECT capability_sequence,capability_code,coverage_status_code,certifying_stage_code,claim_boundary,production_action_authorized_flag,legal_or_regulatory_certified_flag,notes FROM tmp_accept_m2_12_capability_authority)) d)=0)),false),
    CASE WHEN COALESCE((((SELECT count(*) FROM tmp_accept_m2_12_capability_authority)=20 AND (SELECT count(*) FROM msbf_m2.module2_capability_coverage_snapshot s JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=s.module1_run_id)=20 AND (SELECT count(*) FROM ((SELECT capability_sequence,capability_code,coverage_status_code,certifying_stage_code,claim_boundary,production_action_authorized_flag,legal_or_regulatory_certified_flag,notes FROM tmp_accept_m2_12_capability_authority EXCEPT SELECT capability_sequence,capability_code,coverage_status_code,certifying_stage_code,claim_boundary,production_action_authorized_flag,legal_or_regulatory_certified_flag,notes FROM msbf_m2.module2_capability_coverage_snapshot s JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=s.module1_run_id) UNION ALL (SELECT capability_sequence,capability_code,coverage_status_code,certifying_stage_code,claim_boundary,production_action_authorized_flag,legal_or_regulatory_certified_flag,notes FROM msbf_m2.module2_capability_coverage_snapshot s JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=s.module1_run_id EXCEPT SELECT capability_sequence,capability_code,coverage_status_code,certifying_stage_code,claim_boundary,production_action_authorized_flag,legal_or_regulatory_certified_flag,notes FROM tmp_accept_m2_12_capability_authority)) d)=0)),false) THEN NULL ELSE 'M2_12_ACC_041 physical requirement mismatch'::text END,
    'exact eight-field physical comparison to frozen twenty-row capability authority'::text
);
/* HF23_ACCEPTANCE_REQUIREMENT M2_12_ACC_042 */
    PERFORM pg_temp.m2_12_add_acceptance_requirement(
    42::smallint,
    'M2_12_ACC_042'::text,
    'SCOPE'::text,
    'Deferred collateral, covenant, regulatory, allocation, accounting, and empirical capabilities are not certified'::text,
    COALESCE(((SELECT concat_ws('|',count(*)::text,count(*) FILTER (WHERE coverage_status_code LIKE 'IMPLEMENTED%' OR production_action_authorized_flag OR legal_or_regulatory_certified_flag)::text) FROM msbf_m2.module2_capability_coverage_snapshot s JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=s.module1_run_id WHERE capability_sequence BETWEEN 13 AND 20))::text,'<NULL>'),
    '0 overclaims'::text,
    COALESCE(((SELECT count(*)=8 AND count(*) FILTER (WHERE coverage_status_code LIKE 'IMPLEMENTED%' OR production_action_authorized_flag OR legal_or_regulatory_certified_flag)=0 FROM msbf_m2.module2_capability_coverage_snapshot s JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=s.module1_run_id WHERE capability_sequence BETWEEN 13 AND 20)),false),
    CASE WHEN COALESCE(((SELECT count(*)=8 AND count(*) FILTER (WHERE coverage_status_code LIKE 'IMPLEMENTED%' OR production_action_authorized_flag OR legal_or_regulatory_certified_flag)=0 FROM msbf_m2.module2_capability_coverage_snapshot s JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=s.module1_run_id WHERE capability_sequence BETWEEN 13 AND 20)),false) THEN NULL ELSE 'M2_12_ACC_042 physical requirement mismatch'::text END,
    'deferred/prohibited capability rows 13-20'::text
);
/* HF23_ACCEPTANCE_REQUIREMENT M2_12_ACC_043 */
    PERFORM pg_temp.m2_12_add_acceptance_requirement(
    43::smallint,
    'M2_12_ACC_043'::text,
    'BOUNDARY'::text,
    'Synthetic-data, no-PII, non-production, no-external-action boundaries are enabled'::text,
    COALESCE(((SELECT concat_ws('|',p.synthetic_data_only_flag,p.no_pii_flag,p.certification_only_flag,p.production_action_authorized_flag,p.external_system_update_authorized_flag,p.legal_or_regulatory_certified_flag,p.empirical_or_causal_optimization_authorized_flag,l.deployment_authorized_flag,l.module3_execution_authorized_flag) FROM msbf_ctl.m2_12_policy_profile p JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=p.module1_run_id JOIN msbf_ctl.m2_12_g3_bundle_latest l ON l.module1_run_id=ctx.module1_run_id AND l.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND l.contract_version=1))::text,'<NULL>'),
    'true'::text,
    COALESCE(((SELECT count(*)=1 AND bool_and(p.synthetic_data_only_flag AND p.no_pii_flag AND p.certification_only_flag AND NOT p.production_action_authorized_flag AND NOT p.external_system_update_authorized_flag AND NOT p.legal_or_regulatory_certified_flag AND NOT p.empirical_or_causal_optimization_authorized_flag AND NOT l.deployment_authorized_flag AND NOT l.module3_execution_authorized_flag) FROM msbf_ctl.m2_12_policy_profile p JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=p.module1_run_id JOIN msbf_ctl.m2_12_g3_bundle_latest l ON l.module1_run_id=ctx.module1_run_id AND l.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND l.contract_version=1)),false),
    CASE WHEN COALESCE(((SELECT count(*)=1 AND bool_and(p.synthetic_data_only_flag AND p.no_pii_flag AND p.certification_only_flag AND NOT p.production_action_authorized_flag AND NOT p.external_system_update_authorized_flag AND NOT p.legal_or_regulatory_certified_flag AND NOT p.empirical_or_causal_optimization_authorized_flag AND NOT l.deployment_authorized_flag AND NOT l.module3_execution_authorized_flag) FROM msbf_ctl.m2_12_policy_profile p JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=p.module1_run_id JOIN msbf_ctl.m2_12_g3_bundle_latest l ON l.module1_run_id=ctx.module1_run_id AND l.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND l.contract_version=1)),false) THEN NULL ELSE 'M2_12_ACC_043 physical requirement mismatch'::text END,
    'policy plus G3 latest non-production and non-external boundaries'::text
);
/* HF23_ACCEPTANCE_REQUIREMENT M2_12_ACC_044 */
    PERFORM pg_temp.m2_12_add_acceptance_requirement(
    44::smallint,
    'M2_12_ACC_044'::text,
    'BOUNDARY'::text,
    'No premature Module 3 business object or execution authority exists on the exact validated policy and registry rows'::text,
    COALESCE(((SELECT concat_ws('|',
      (SELECT count(*) FROM pg_catalog.pg_class c JOIN pg_catalog.pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname IN ('msbf_ctl','msbf_m1','msbf_m2','msbf_ref') AND lower(c.relname) ~ '^(m3_|module3_)'),
      (SELECT count(*) FROM msbf_ctl.m2_12_policy_profile p JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=p.module1_run_id WHERE p.policy_code='M2_12_ENTERPRISE_PORTFOLIO_CERTIFICATION_POLICY_V1' AND p.policy_version=1 AND p.policy_status='APPROVED'),
      (SELECT count(*) FROM msbf_ctl.m2_12_policy_profile p JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=p.module1_run_id WHERE p.policy_code='M2_12_ENTERPRISE_PORTFOLIO_CERTIFICATION_POLICY_V1' AND p.policy_version=1 AND p.policy_status='APPROVED' AND (p.module3_sql_authorized_flag OR p.module3_execution_authorized_flag)),
      (SELECT count(*) FROM msbf_ctl.m2_12_g3_bundle_registry r JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=r.module1_run_id WHERE r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1 AND r.contract_status='VALIDATED'),
      (SELECT count(*) FROM msbf_ctl.m2_12_g3_bundle_registry r JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=r.module1_run_id WHERE r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1 AND r.contract_status='VALIDATED' AND r.module3_execution_authorized_flag))))::text,'<NULL>'),
    '0|1|0|1|0'::text,
    COALESCE((((SELECT count(*) FROM pg_catalog.pg_class c JOIN pg_catalog.pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname IN ('msbf_ctl','msbf_m1','msbf_m2','msbf_ref') AND lower(c.relname) ~ '^(m3_|module3_)')=0
      AND (SELECT count(*) FROM msbf_ctl.m2_12_policy_profile p JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=p.module1_run_id WHERE p.policy_code='M2_12_ENTERPRISE_PORTFOLIO_CERTIFICATION_POLICY_V1' AND p.policy_version=1 AND p.policy_status='APPROVED')=1
      AND (SELECT count(*) FROM msbf_ctl.m2_12_policy_profile p JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=p.module1_run_id WHERE p.policy_code='M2_12_ENTERPRISE_PORTFOLIO_CERTIFICATION_POLICY_V1' AND p.policy_version=1 AND p.policy_status='APPROVED' AND (p.module3_sql_authorized_flag OR p.module3_execution_authorized_flag))=0
      AND (SELECT count(*) FROM msbf_ctl.m2_12_g3_bundle_registry r JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=r.module1_run_id WHERE r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1 AND r.contract_status='VALIDATED')=1
      AND (SELECT count(*) FROM msbf_ctl.m2_12_g3_bundle_registry r JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=r.module1_run_id WHERE r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1 AND r.contract_status='VALIDATED' AND r.module3_execution_authorized_flag)=0)),false),
    CASE WHEN COALESCE((((SELECT count(*) FROM pg_catalog.pg_class c JOIN pg_catalog.pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname IN ('msbf_ctl','msbf_m1','msbf_m2','msbf_ref') AND lower(c.relname) ~ '^(m3_|module3_)')=0
      AND (SELECT count(*) FROM msbf_ctl.m2_12_policy_profile p JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=p.module1_run_id WHERE p.policy_code='M2_12_ENTERPRISE_PORTFOLIO_CERTIFICATION_POLICY_V1' AND p.policy_version=1 AND p.policy_status='APPROVED')=1
      AND (SELECT count(*) FROM msbf_ctl.m2_12_policy_profile p JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=p.module1_run_id WHERE p.policy_code='M2_12_ENTERPRISE_PORTFOLIO_CERTIFICATION_POLICY_V1' AND p.policy_version=1 AND p.policy_status='APPROVED' AND (p.module3_sql_authorized_flag OR p.module3_execution_authorized_flag))=0
      AND (SELECT count(*) FROM msbf_ctl.m2_12_g3_bundle_registry r JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=r.module1_run_id WHERE r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1 AND r.contract_status='VALIDATED')=1
      AND (SELECT count(*) FROM msbf_ctl.m2_12_g3_bundle_registry r JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=r.module1_run_id WHERE r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1 AND r.contract_status='VALIDATED' AND r.module3_execution_authorized_flag)=0)),false)
      THEN NULL ELSE 'M2_12_ACC_044 physical requirement mismatch'::text END,
    'catalog-native Module 3 object absence plus exact approved policy and validated G3 registry authority flags'::text
);
/* HF23_ACCEPTANCE_REQUIREMENT M2_12_ACC_045 */
    PERFORM pg_temp.m2_12_add_acceptance_requirement(
    45::smallint,
    'M2_12_ACC_045'::text,
    'HASH'::text,
    'G3 latest and archive row hashes reconstruct physically'::text,
    COALESCE(((SELECT concat_ws('|',count(*) FILTER (WHERE l.row_hash IS DISTINCT FROM md5((to_jsonb(l)-'row_hash'-'created_at')::text))::text,count(*) FILTER (WHERE a.archive_row_hash IS DISTINCT FROM md5((to_jsonb(a)-'archive_id'-'archive_row_hash'-'created_at')::text))::text,count(*) FILTER (WHERE a.source_latest_row_hash IS DISTINCT FROM l.row_hash OR a.contract_row_hash IS DISTINCT FROM l.contract_row_hash OR a.contract_payload IS DISTINCT FROM (to_jsonb(l)-'created_at'))::text) FROM msbf_ctl.m2_12_g3_bundle_latest l JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=l.module1_run_id JOIN msbf_ctl.m2_12_g3_bundle_archive a ON a.module1_run_id=l.module1_run_id AND a.bundle_code=l.bundle_code AND a.contract_version=l.contract_version))::text,'<NULL>'),
    '0 mismatches'::text,
    COALESCE(((SELECT count(*)=1 AND count(*) FILTER (WHERE l.row_hash IS DISTINCT FROM md5((to_jsonb(l)-'row_hash'-'created_at')::text))=0 AND count(*) FILTER (WHERE a.archive_row_hash IS DISTINCT FROM md5((to_jsonb(a)-'archive_id'-'archive_row_hash'-'created_at')::text))=0 AND count(*) FILTER (WHERE a.source_latest_row_hash IS DISTINCT FROM l.row_hash OR a.contract_row_hash IS DISTINCT FROM l.contract_row_hash OR a.contract_payload IS DISTINCT FROM (to_jsonb(l)-'created_at'))=0 FROM msbf_ctl.m2_12_g3_bundle_latest l JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=l.module1_run_id JOIN msbf_ctl.m2_12_g3_bundle_archive a ON a.module1_run_id=l.module1_run_id AND a.bundle_code=l.bundle_code AND a.contract_version=l.contract_version)),false),
    CASE WHEN COALESCE(((SELECT count(*)=1 AND count(*) FILTER (WHERE l.row_hash IS DISTINCT FROM md5((to_jsonb(l)-'row_hash'-'created_at')::text))=0 AND count(*) FILTER (WHERE a.archive_row_hash IS DISTINCT FROM md5((to_jsonb(a)-'archive_id'-'archive_row_hash'-'created_at')::text))=0 AND count(*) FILTER (WHERE a.source_latest_row_hash IS DISTINCT FROM l.row_hash OR a.contract_row_hash IS DISTINCT FROM l.contract_row_hash OR a.contract_payload IS DISTINCT FROM (to_jsonb(l)-'created_at'))=0 FROM msbf_ctl.m2_12_g3_bundle_latest l JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=l.module1_run_id JOIN msbf_ctl.m2_12_g3_bundle_archive a ON a.module1_run_id=l.module1_run_id AND a.bundle_code=l.bundle_code AND a.contract_version=l.contract_version)),false) THEN NULL ELSE 'M2_12_ACC_045 physical requirement mismatch'::text END,
    'independent latest/archive row-hash preimages and copied contract payload identity'::text
);
/* HF23_ACCEPTANCE_REQUIREMENT M2_12_ACC_046 */
    PERFORM pg_temp.m2_12_add_acceptance_requirement(
    46::smallint,
    'M2_12_ACC_046'::text,
    'HASH'::text,
    'G3 registry row hash and contract set hash reconstruct physically'::text,
    COALESCE(((SELECT concat_ws('|',count(*)::text,count(*) FILTER (WHERE mismatch_flag)::text) FROM tmp_hash_m2_12_acceptance_detail WHERE hash_sequence IN (10,11)))::text,'<NULL>'),
    '0 mismatches'::text,
    COALESCE(((SELECT count(*)=2 AND count(*) FILTER (WHERE mismatch_flag)=0 FROM tmp_hash_m2_12_acceptance_detail WHERE hash_sequence IN (10,11))),false),
    CASE WHEN COALESCE(((SELECT count(*)=2 AND count(*) FILTER (WHERE mismatch_flag)=0 FROM tmp_hash_m2_12_acceptance_detail WHERE hash_sequence IN (10,11))),false) THEN NULL ELSE 'M2_12_ACC_046 physical requirement mismatch'::text END,
    'independent registry-row and contract-set hash detail rows'::text
);
/* HF23_ACCEPTANCE_REQUIREMENT M2_12_ACC_047 */
    PERFORM pg_temp.m2_12_add_acceptance_requirement(
    47::smallint,
    'M2_12_ACC_047'::text,
    'HASH'::text,
    'Ordered 134-entity combined G3 hash reconstructs physically'::text,
    COALESCE(((SELECT concat_ws('|',d.stored_hash,d.reconstructed_hash,d.mismatch_flag::text,f.canonical_entity_count::text,f.canonical_family_count::text) FROM tmp_hash_m2_12_acceptance_detail d CROSS JOIN tmp_hash_m2_12_acceptance_prewrite_reconstruction f WHERE d.hash_sequence=12))::text,'<NULL>'),
    '0 mismatches'::text,
    COALESCE(((SELECT count(*)=1 AND bool_and(NOT d.mismatch_flag AND f.canonical_entity_count=134 AND f.canonical_family_count=9 AND f.row_hash_mismatch_count=0) FROM tmp_hash_m2_12_acceptance_detail d CROSS JOIN tmp_hash_m2_12_acceptance_prewrite_reconstruction f WHERE d.hash_sequence=12)),false),
    CASE WHEN COALESCE(((SELECT count(*)=1 AND bool_and(NOT d.mismatch_flag AND f.canonical_entity_count=134 AND f.canonical_family_count=9 AND f.row_hash_mismatch_count=0) FROM tmp_hash_m2_12_acceptance_detail d CROSS JOIN tmp_hash_m2_12_acceptance_prewrite_reconstruction f WHERE d.hash_sequence=12)),false) THEN NULL ELSE 'M2_12_ACC_047 physical requirement mismatch'::text END,
    'ordered 134-entity physical union plus independent row preimages'::text
);
END;
$m212_p225_hf23_prewrite_requirement_registration$;
/* Hard pre-write gate: no persistent write is reachable unless 47/47 PASS. */
DO $m212_p225_hf15_prewrite_gate$
DECLARE
    v_rows integer;
    v_pass integer;
    v_fail_detail text;
BEGIN
    SELECT count(*),count(*) FILTER (WHERE status='PASS'),
           string_agg(requirement_code||':'||coalesce(failure_detail,''),'; ' ORDER BY requirement_sequence)
             FILTER (WHERE status<>'PASS')
      INTO v_rows,v_pass,v_fail_detail
      FROM tmp_accept_m2_12_requirement;
    IF v_rows<>47 OR v_pass<>47 THEN
        RAISE EXCEPTION USING ERRCODE='P0001',
          MESSAGE='Program 225 HF23 pre-write acceptance gate failed',
          DETAIL=format('rows=%s pass=%s failures=%s',v_rows,v_pass,coalesce(v_fail_detail,'<none>'));
    END IF;
END;
$m212_p225_hf15_prewrite_gate$;

/* Phase 2 — capture the immutable pre-write fingerprint only after 47/47 PASS. */
CREATE TEMP TABLE tmp_hash_m2_12_acceptance_fingerprint_before ON COMMIT DROP AS
SELECT canonical_entity_count,
       canonical_family_count,
       row_hash_mismatch_count,
       canonical_physical_fingerprint,
       governed_hash_fingerprint,
       sequence_fingerprint
  FROM tmp_hash_m2_12_acceptance_prewrite_reconstruction;
CREATE UNIQUE INDEX ux_tmp_hash_m2_12_acceptance_fingerprint_before
    ON tmp_hash_m2_12_acceptance_fingerprint_before(canonical_entity_count);
ANALYZE tmp_hash_m2_12_acceptance_fingerprint_before;

DO $m212_p225_hf15_phase2_fingerprint_gate$
DECLARE v_rows integer;
BEGIN
    SELECT count(*) INTO v_rows
      FROM tmp_hash_m2_12_acceptance_fingerprint_before
     WHERE canonical_entity_count=134
       AND canonical_family_count=9
       AND row_hash_mismatch_count=0
       AND canonical_physical_fingerprint IS NOT NULL
       AND governed_hash_fingerprint IS NOT NULL
       AND sequence_fingerprint IS NOT NULL;
    IF v_rows<>1 THEN
        RAISE EXCEPTION USING ERRCODE='P0001',
          MESSAGE='Program 225 HF23 Phase-2 immutable pre-write fingerprint capture failed',
          DETAIL='qualifying_rows='||v_rows::text;
    END IF;
END;
$m212_p225_hf15_phase2_fingerprint_gate$;

/* Phase 3 — one exact G3 gate result. */
INSERT INTO msbf_ctl.acceptance_gate_result
(run_id,gate_id,review_version,result_status,observed_value,threshold_value,
 finding,residual_limitation,reviewer_role)
SELECT module1_run_id,'G3_M2_CONTRACT',1,'PASS',
       '48/48 acceptance requirements; 128/128 positive; 20/20 negative; immutable fingerprint exact',
       '48/48 PASS',
       'M2.12 as-built synthetic enterprise portfolio certification and G3 consumption contract accepted.',
       'No production, deployment, legal/regulatory certification, causal optimization, champion, external action, or Module 3 authority.',
       'M2_12_GOVERNED_ACCEPTANCE_FINALIZER'
  FROM tmp_accept_m2_12_context;

/* Phase 4 — one exact acceptance evidence row. */
INSERT INTO msbf_ctl.run_evidence
(run_id,evidence_code,segment_key,metric_name,metric_value_numeric,
 metric_value_text,unit_code,status,interpretation)
SELECT module1_run_id,'M2_12_ACCEPTANCE_SUMMARY','ENTERPRISE_PORTFOLIO_G3',
       'G3_ACCEPTANCE_STATUS',NULL,
       'M2_12_ACCEPTED|ACCEPTED|PASS|48/48','ACCEPTANCE','PASS',
       'As-built synthetic certification and governed consumption acceptance only; no deployment, production, legal/regulatory, causal, champion, external-action, or Module 3 authority.'
  FROM tmp_accept_m2_12_context;

/* Phase 5 — update only mutable acceptance lifecycle fields. */
DO $m212_p225_hf15_lifecycle_transition$
DECLARE
    v_registry_rows integer;
    v_run_rows integer;
BEGIN
    UPDATE msbf_ctl.m2_12_g3_bundle_registry r
       SET contract_status='ACCEPTED',accepted_at=clock_timestamp(),updated_at=clock_timestamp()
      FROM tmp_accept_m2_12_context ctx
     WHERE r.module1_run_id=ctx.module1_run_id
       AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE'
       AND r.contract_version=1
       AND r.contract_status='VALIDATED'
       AND r.accepted_at IS NULL;
    GET DIAGNOSTICS v_registry_rows=ROW_COUNT;

    UPDATE msbf_ctl.run_registry rr
       SET run_status='M2_12_ACCEPTED'
      FROM tmp_accept_m2_12_context ctx
     WHERE rr.run_id=ctx.module1_run_id
       AND rr.run_status='M2_12_VALIDATED';
    GET DIAGNOSTICS v_run_rows=ROW_COUNT;

    IF v_registry_rows<>1 OR v_run_rows<>1 THEN
        RAISE EXCEPTION USING ERRCODE='P0001',
          MESSAGE='Program 225 HF23 lifecycle transition affected an unexpected row count',
          DETAIL=format('registry_rows=%s run_rows=%s',v_registry_rows,v_run_rows);
    END IF;
END;
$m212_p225_hf15_lifecycle_transition$;

/* Phase 6 — exact post-write atomicity count check: 1|1|1|1. */
CREATE TEMP TABLE tmp_accept_m2_12_postwrite_atomicity ON COMMIT DROP AS
SELECT
    (SELECT count(*)::integer FROM msbf_ctl.acceptance_gate_result g
      WHERE g.run_id=ctx.module1_run_id AND g.gate_id='G3_M2_CONTRACT'
        AND g.review_version=1 AND g.result_status='PASS') AS gate_rows,
    (SELECT count(*)::integer FROM msbf_ctl.run_evidence e
      WHERE e.run_id=ctx.module1_run_id AND e.evidence_code='M2_12_ACCEPTANCE_SUMMARY'
        AND e.segment_key='ENTERPRISE_PORTFOLIO_G3' AND e.metric_name='G3_ACCEPTANCE_STATUS'
        AND e.metric_value_text='M2_12_ACCEPTED|ACCEPTED|PASS|48/48'
        AND e.unit_code='ACCEPTANCE' AND e.status='PASS') AS evidence_rows,
    (SELECT count(*)::integer FROM msbf_ctl.run_registry rr
      WHERE rr.run_id=ctx.module1_run_id AND rr.run_code='M1_V0_2_BASELINE_BUILD'
        AND rr.run_version=1 AND rr.run_status='M2_12_ACCEPTED') AS accepted_run_rows,
    (SELECT count(*)::integer FROM msbf_ctl.m2_12_g3_bundle_registry r
      WHERE r.module1_run_id=ctx.module1_run_id
        AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1
        AND r.contract_status='ACCEPTED') AS accepted_registry_rows
  FROM tmp_accept_m2_12_context ctx;
CREATE UNIQUE INDEX ux_tmp_accept_m2_12_postwrite_atomicity
    ON tmp_accept_m2_12_postwrite_atomicity(gate_rows,evidence_rows,accepted_run_rows,accepted_registry_rows);
ANALYZE tmp_accept_m2_12_postwrite_atomicity;

DO $m212_p225_hf15_postwrite_atomicity$
DECLARE v_observed text;
BEGIN
    SELECT concat_ws('|',gate_rows,evidence_rows,accepted_run_rows,accepted_registry_rows)
      INTO v_observed FROM tmp_accept_m2_12_postwrite_atomicity;
    IF v_observed IS DISTINCT FROM '1|1|1|1' THEN
        RAISE EXCEPTION USING ERRCODE='P0001',
          MESSAGE='M2.12 acceptance post-write atomicity mismatch',
          DETAIL='observed='||coalesce(v_observed,'<null>')||' expected=1|1|1|1';
    END IF;
END;
$m212_p225_hf15_postwrite_atomicity$;
CREATE TEMP TABLE tmp_hash_m2_12_acceptance_fingerprint_after ON COMMIT DROP AS
WITH canonical AS (
    SELECT 'POLICY'::text family_code, concat_ws('|',t.policy_code,t.policy_version::text) entity_key, t.row_hash::text stored_hash, md5((to_jsonb(t)-'policy_profile_id'-'row_hash'-'created_at'-'updated_at')::text)::text physical_hash FROM msbf_ctl.m2_12_policy_profile t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT 'STAGE_CERTIFICATION', concat_ws('|',t.certification_node_sequence::text,t.stage_code), t.row_hash, md5((to_jsonb(t)-'row_hash'-'created_at')::text) FROM msbf_m2.module2_stage_certification_snapshot t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT 'CONTRACT_COMPONENT', concat_ws('|',t.component_sequence::text,t.component_contract_code,t.contract_version::text), t.row_hash, md5((to_jsonb(t)-'row_hash'-'created_at')::text) FROM msbf_m2.module2_contract_component_snapshot t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT 'EVIDENCE_CERTIFICATION', concat_ws('|',t.node_sequence::text,t.evidence_family_sequence::text), t.row_hash, md5((to_jsonb(t)-'row_hash'-'created_at')::text) FROM msbf_m2.module2_evidence_certification_snapshot t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT 'CONTRACT_REPRODUCTION', concat_ws('|',t.component_sequence::text,t.component_contract_code,t.contract_version::text), t.row_hash, md5((to_jsonb(t)-'row_hash'-'created_at')::text) FROM msbf_m2.module2_contract_reproduction_snapshot t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT 'CAPABILITY_COVERAGE', concat_ws('|',t.capability_sequence::text,t.capability_code), t.row_hash, md5((to_jsonb(t)-'row_hash'-'created_at')::text) FROM msbf_m2.module2_capability_coverage_snapshot t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT 'LATEST', concat_ws('|',t.bundle_code,t.contract_version::text), t.row_hash, md5((to_jsonb(t)-'row_hash'-'created_at')::text) FROM msbf_ctl.m2_12_g3_bundle_latest t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT 'ARCHIVE', concat_ws('|',t.bundle_code,t.contract_version::text), t.archive_row_hash, md5((to_jsonb(t)-'archive_id'-'archive_row_hash'-'created_at')::text) FROM msbf_ctl.m2_12_g3_bundle_archive t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id
UNION ALL
SELECT 'REGISTRY', concat_ws('|',t.bundle_code,t.contract_version::text), t.row_hash, md5((to_jsonb(t)-ARRAY['registry_id','contract_status','generated_at','validated_at','accepted_at','created_at','updated_at','row_hash','policy_set_hash','stage_certification_set_hash','contract_component_set_hash','evidence_certification_set_hash','contract_reproduction_set_hash','capability_coverage_set_hash','latest_set_hash','archive_set_hash','registry_set_hash','contract_set_hash','combined_set_hash']::text[])::text) FROM msbf_ctl.m2_12_g3_bundle_registry t JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=t.module1_run_id
), registry AS (
    SELECT
        r.policy_set_hash,r.stage_certification_set_hash,r.contract_component_set_hash,
        r.evidence_certification_set_hash,r.contract_reproduction_set_hash,r.capability_coverage_set_hash,
        r.latest_set_hash,r.archive_set_hash,r.registry_set_hash,r.latest_contract_row_hash,
        r.archive_contract_row_hash,r.contract_set_hash,r.combined_set_hash,r.row_hash,
        r.accepted_m2_11_contract_set_hash,r.accepted_m2_11_combined_set_hash,
        r.accepted_m2_11_registry_row_hash
    FROM msbf_ctl.m2_12_g3_bundle_registry r
    JOIN tmp_accept_m2_12_context ctx ON ctx.module1_run_id=r.module1_run_id
    WHERE r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1
), sequence_state AS (
    SELECT concat_ws('|',
        p.last_value::text,p.is_called::text,
        a.last_value::text,a.is_called::text,
        r.last_value::text,r.is_called::text) AS sequence_fingerprint
    FROM msbf_ctl.m2_12_policy_profile_policy_profile_id_seq p
    CROSS JOIN msbf_ctl.m2_12_g3_bundle_archive_archive_id_seq a
    CROSS JOIN msbf_ctl.m2_12_g3_bundle_registry_registry_id_seq r
)
SELECT
    count(*)::integer AS canonical_entity_count,
    count(DISTINCT family_code)::integer AS canonical_family_count,
    count(*) FILTER (WHERE stored_hash IS DISTINCT FROM physical_hash)::integer AS row_hash_mismatch_count,
    md5(string_agg(concat_ws('|',family_code,entity_key,stored_hash,physical_hash),'|' ORDER BY family_code,entity_key))::text AS canonical_physical_fingerprint,
    (SELECT md5(concat_ws('|',
        policy_set_hash,stage_certification_set_hash,contract_component_set_hash,
        evidence_certification_set_hash,contract_reproduction_set_hash,capability_coverage_set_hash,
        latest_set_hash,archive_set_hash,registry_set_hash,latest_contract_row_hash,
        archive_contract_row_hash,contract_set_hash,combined_set_hash,row_hash,
        accepted_m2_11_contract_set_hash,accepted_m2_11_combined_set_hash,
        accepted_m2_11_registry_row_hash)) FROM registry)::text AS governed_hash_fingerprint,
    (SELECT sequence_fingerprint FROM sequence_state)::text AS sequence_fingerprint
FROM canonical;
CREATE UNIQUE INDEX ux_tmp_hash_m2_12_acceptance_fingerprint_after ON tmp_hash_m2_12_acceptance_fingerprint_after(canonical_entity_count);
ANALYZE tmp_hash_m2_12_acceptance_fingerprint_after;
/* Compact post-write registration: Requirement 048 emits no intermediate result grid. */
DO $m212_p225_hf23_postwrite_requirement_registration$
BEGIN
/* HF23_ACCEPTANCE_REQUIREMENT M2_12_ACC_048 */
    PERFORM pg_temp.m2_12_add_acceptance_requirement(
    48::smallint,
    'M2_12_ACC_048'::text,
    'GATE'::text,
    'Program 225 HF23 atomically writes exactly one G3 gate row and one acceptance evidence row, transitions lifecycle, and preserves the immutable canonical fingerprint'::text,
    COALESCE(((SELECT concat_ws('|',a.gate_rows,a.evidence_rows,a.accepted_run_rows,a.accepted_registry_rows,(SELECT count(*) FROM tmp_hash_m2_12_acceptance_fingerprint_before b FULL JOIN tmp_hash_m2_12_acceptance_fingerprint_after f USING(canonical_entity_count) WHERE b.canonical_entity_count IS NULL OR f.canonical_entity_count IS NULL OR (b.canonical_family_count,b.row_hash_mismatch_count,b.canonical_physical_fingerprint,b.governed_hash_fingerprint,b.sequence_fingerprint) IS DISTINCT FROM (f.canonical_family_count,f.row_hash_mismatch_count,f.canonical_physical_fingerprint,f.governed_hash_fingerprint,f.sequence_fingerprint))) FROM tmp_accept_m2_12_postwrite_atomicity a))::text,'<NULL>'),
    'review_version=1 | 1 gate PASS | 1 M2_12_ACCEPTANCE_SUMMARY | M2_12_ACCEPTED | ACCEPTED | pre/post fingerprint identical'::text,
    COALESCE((((SELECT gate_rows=1 AND evidence_rows=1 AND accepted_run_rows=1 AND accepted_registry_rows=1 FROM tmp_accept_m2_12_postwrite_atomicity) AND (SELECT count(*) FROM tmp_hash_m2_12_acceptance_fingerprint_before b FULL JOIN tmp_hash_m2_12_acceptance_fingerprint_after f USING(canonical_entity_count) WHERE b.canonical_entity_count IS NULL OR f.canonical_entity_count IS NULL OR (b.canonical_family_count,b.row_hash_mismatch_count,b.canonical_physical_fingerprint,b.governed_hash_fingerprint,b.sequence_fingerprint) IS DISTINCT FROM (f.canonical_family_count,f.row_hash_mismatch_count,f.canonical_physical_fingerprint,f.governed_hash_fingerprint,f.sequence_fingerprint))=0)),false),
    CASE WHEN COALESCE((((SELECT gate_rows=1 AND evidence_rows=1 AND accepted_run_rows=1 AND accepted_registry_rows=1 FROM tmp_accept_m2_12_postwrite_atomicity) AND (SELECT count(*) FROM tmp_hash_m2_12_acceptance_fingerprint_before b FULL JOIN tmp_hash_m2_12_acceptance_fingerprint_after f USING(canonical_entity_count) WHERE b.canonical_entity_count IS NULL OR f.canonical_entity_count IS NULL OR (b.canonical_family_count,b.row_hash_mismatch_count,b.canonical_physical_fingerprint,b.governed_hash_fingerprint,b.sequence_fingerprint) IS DISTINCT FROM (f.canonical_family_count,f.row_hash_mismatch_count,f.canonical_physical_fingerprint,f.governed_hash_fingerprint,f.sequence_fingerprint))=0)),false) THEN NULL ELSE 'M2_12_ACC_048 physical requirement mismatch'::text END,
    'post-write exact gate/evidence/lifecycle state plus independent pre/post immutable physical fingerprint'::text
);
END;
$m212_p225_hf23_postwrite_requirement_registration$;
/* Phase 8 — final 48-of-48 release gate and single commit. */
DO $m212_p225_hf15_final_gate$
DECLARE
    v_rows integer;
    v_pass integer;
    v_fail text;
BEGIN
    SELECT count(*),count(*) FILTER (WHERE status='PASS'),
           string_agg(requirement_code||':'||coalesce(failure_detail,''),'; ' ORDER BY requirement_sequence)
             FILTER (WHERE status<>'PASS')
      INTO v_rows,v_pass,v_fail
      FROM tmp_accept_m2_12_requirement;
    IF v_rows<>48 OR v_pass<>48 THEN
        RAISE EXCEPTION USING ERRCODE='P0001',
          MESSAGE='Program 225 HF23 final acceptance release gate failed',
          DETAIL=format('rows=%s pass=%s failures=%s',v_rows,v_pass,coalesce(v_fail,'<none>'));
    END IF;
END;
$m212_p225_hf15_final_gate$;

CREATE TEMP TABLE tmp_accept_m2_12_result ON COMMIT PRESERVE ROWS AS
SELECT
    ctx.module1_run_id AS run_id,
    ctx.run_code,
    ctx.run_version,
    rr.run_status AS final_run_status,
    r.bundle_code,
    r.contract_version,
    r.contract_status AS final_contract_status,
    g.gate_id,
    g.review_version,
    g.result_status AS acceptance_gate_status,
    e.evidence_code AS acceptance_evidence_code,
    e.status AS acceptance_evidence_status,
    (SELECT count(*) FROM tmp_accept_m2_12_requirement) AS acceptance_requirements,
    (SELECT count(*) FROM tmp_accept_m2_12_requirement WHERE status='PASS') AS acceptance_requirements_passed,
    (SELECT count(*) FROM msbf_ctl.run_evidence x WHERE x.run_id=ctx.module1_run_id AND left(x.evidence_code,10)='M2_12_POS_' AND x.status='PASS') AS positive_controls_passed,
    (SELECT count(*) FROM msbf_ctl.run_evidence x WHERE x.run_id=ctx.module1_run_id AND left(x.evidence_code,10)='M2_12_NEG_' AND x.status='PASS') AS negative_controls_passed,
    r.canonical_entity_count,
    r.contract_set_hash,
    r.combined_set_hash,
    r.row_hash AS registry_row_hash,
    'ACCEPTED_AS_BUILT_SYNTHETIC_G3_CONSUMPTION'::text AS acceptance_scope,
    'NOT_AUTHORIZED'::text AS deployment_authorization_status,
    'NOT_AUTHORIZED'::text AS legal_or_regulatory_certification_status,
    'NOT_AUTHORIZED'::text AS autonomous_champion_status,
    'NOT_AUTHORIZED'::text AS module3_authorization_status,
    'PASS'::text AS acceptance_status
FROM tmp_accept_m2_12_context ctx
JOIN msbf_ctl.run_registry rr ON rr.run_id=ctx.module1_run_id
JOIN msbf_ctl.m2_12_g3_bundle_registry r ON r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND r.contract_version=1
JOIN msbf_ctl.acceptance_gate_result g ON g.run_id=ctx.module1_run_id AND g.gate_id='G3_M2_CONTRACT' AND g.review_version=1
JOIN msbf_ctl.run_evidence e ON e.run_id=ctx.module1_run_id AND e.evidence_code='M2_12_ACCEPTANCE_SUMMARY' AND e.segment_key='ENTERPRISE_PORTFOLIO_G3';

COMMIT;

SELECT run_id,run_code,run_version,final_run_status,bundle_code,contract_version,
       final_contract_status,gate_id,review_version,acceptance_gate_status,
       acceptance_evidence_code,acceptance_evidence_status,acceptance_requirements,
       acceptance_requirements_passed,positive_controls_passed,negative_controls_passed,
       canonical_entity_count,contract_set_hash,combined_set_hash,registry_row_hash,
       acceptance_scope,deployment_authorization_status,
       legal_or_regulatory_certification_status,autonomous_champion_status,
       module3_authorization_status,acceptance_status
  FROM tmp_accept_m2_12_result;