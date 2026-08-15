/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.3 — Final Offer & Decision Authorization

Program     : 155_MSBF_M2_3_Detail_Report_v0_2R2.sql
Version     : v0.2R2
Purpose     : Twenty-four governed read-only result sets for M2.3 evidence.
Writes      : None.
Required    : Result Sets 23 and 24 retain headers and contain zero rows.
============================================================================ */

SET statement_timeout = '30min';
SET jit = off;

DROP TABLE IF EXISTS _m2_3_dctx;

CREATE TEMP TABLE _m2_3_dctx
ON COMMIT PRESERVE ROWS
AS
SELECT run_id
FROM msbf_ctl.run_registry
WHERE run_code='M1_V0_2_BASELINE_BUILD'
  AND run_version=1;

CREATE INDEX ON _m2_3_dctx(run_id);
ANALYZE _m2_3_dctx;

/* Result Set 01 — Run, Contract Lifecycle and Acceptance Gate */
SELECT
    run.run_id,
    run.run_code,
    run.run_version,
    run.run_status,
    registry.contract_code,
    registry.contract_version,
    registry.schema_version,
    registry.contract_status,
    gate.gate_id,
    gate.result_status AS gate_status,
    registry.generated_at,
    registry.validated_at,
    registry.accepted_at
FROM msbf_ctl.run_registry AS run
JOIN msbf_ctl.m2_3_final_decision_contract_registry AS registry
  ON registry.module1_run_id=run.run_id
LEFT JOIN msbf_ctl.acceptance_gate_result AS gate
  ON gate.run_id=run.run_id
 AND gate.gate_id='M2_3_FINAL_OFFER_DECISION_AUTHORIZATION'
 AND gate.review_version=1
WHERE run.run_id=(SELECT run_id FROM _m2_3_dctx);

/* Result Set 02 — Policy and Stage Boundary */
SELECT
    policy_code,
    policy_version,
    policy_status,
    methodology_version,
    contract_code,
    contract_version,
    schema_version,
    source_m2_2_contract_code,
    source_m2_2_contract_version,
    source_m2_2_schema_version,
    source_m2_2_combined_hash,
    final_offer_authorization_enabled_flag,
    decline_authorization_enabled_flag,
    manual_review_authorization_enabled_flag,
    synthetic_data_only_flag,
    no_booking_funding_flag,
    no_external_notice_generation_flag,
    no_production_adverse_action_notice_flag,
    configuration_hash
FROM msbf_ctl.m2_3_policy_profile
WHERE module1_run_id=(SELECT run_id FROM _m2_3_dctx);

/* Result Set 03 — Decision Outcome Definitions */
SELECT
    decision_outcome_code,
    decision_outcome_rank,
    customer_offer_flag,
    decline_flag,
    manual_review_flag,
    production_adverse_action_notice_flag,
    booking_funding_flag,
    outcome_status,
    description
FROM msbf_m2.final_decision_outcome_definition
WHERE module1_run_id=(SELECT run_id FROM _m2_3_dctx)
ORDER BY decision_outcome_rank, decision_outcome_code;

/* Result Set 04 — Decision Reason Definitions */
SELECT
    decision_reason_code,
    mapped_decision_outcome_code,
    production_adverse_action_notice_flag,
    reason_status,
    description
FROM msbf_m2.final_decision_reason_definition
WHERE module1_run_id=(SELECT run_id FROM _m2_3_dctx)
ORDER BY decision_reason_code;

/* Result Set 05 — Entity Cardinality and Governed Grains */
SELECT
    registry.policy_rows,
    registry.outcome_rows,
    registry.reason_rows,
    registry.source_rows,
    registry.decision_snapshot_rows,
    registry.decision_latest_rows,
    registry.decision_archive_rows,
    registry.comparison_rows,
    registry.registry_rows,
    registry.canonical_entities
FROM msbf_ctl.m2_3_final_decision_contract_registry AS registry
WHERE registry.module1_run_id=(SELECT run_id FROM _m2_3_dctx);

/* Result Set 06 — Source Pricing Disposition Distribution */
SELECT
    pricing_disposition_code,
    structure_available_flag,
    review_required_flag,
    count(*) AS rows
FROM msbf_m2.application_final_decision_source_snapshot
WHERE module1_run_id=(SELECT run_id FROM _m2_3_dctx)
GROUP BY pricing_disposition_code, structure_available_flag, review_required_flag
ORDER BY pricing_disposition_code;

/* Result Set 07 — Final Decision Distribution by Scenario */
SELECT
    scenario_code,
    final_decision_outcome_code,
    final_authorization_evidence_status,
    count(*) AS rows
FROM msbf_m2.application_final_offer_decision_latest
WHERE module1_run_id=(SELECT run_id FROM _m2_3_dctx)
GROUP BY scenario_code, final_decision_outcome_code, final_authorization_evidence_status
ORDER BY scenario_code, final_decision_outcome_code;

/* Result Set 08 — Final Offer Authorized Population */
SELECT
    scenario_code,
    count(*) AS offer_rows,
    round(avg(final_offer_amount),2) AS average_offer_amount,
    round(avg(final_remittance_rate),6) AS average_remittance_rate,
    round(avg(final_payback_multiple),6) AS average_payback_multiple,
    round(avg(final_collection_horizon_days),2) AS average_horizon_days
FROM msbf_m2.application_final_offer_decision_latest
WHERE module1_run_id=(SELECT run_id FROM _m2_3_dctx)
  AND final_offer_authorized_flag
GROUP BY scenario_code
ORDER BY scenario_code;

/* Result Set 09 — Manual Review Population */
SELECT
    scenario_code,
    primary_decision_reason_code,
    count(*) AS rows
FROM msbf_m2.application_final_offer_decision_latest
WHERE module1_run_id=(SELECT run_id FROM _m2_3_dctx)
  AND counteroffer_review_required_flag
GROUP BY scenario_code, primary_decision_reason_code
ORDER BY scenario_code, primary_decision_reason_code;

/* Result Set 10 — Decline Authorization Population */
SELECT
    scenario_code,
    final_decision_outcome_code,
    primary_decision_reason_code,
    count(*) AS rows
FROM msbf_m2.application_final_offer_decision_latest
WHERE module1_run_id=(SELECT run_id FROM _m2_3_dctx)
  AND decline_authorized_flag
GROUP BY scenario_code, final_decision_outcome_code, primary_decision_reason_code
ORDER BY scenario_code, final_decision_outcome_code;

/* Result Set 11 — Final Offer Amount Distribution */
SELECT
    scenario_code,
    min(final_offer_amount) AS min_offer_amount,
    percentile_cont(0.25) WITHIN GROUP (ORDER BY final_offer_amount) AS p25_offer_amount,
    percentile_cont(0.50) WITHIN GROUP (ORDER BY final_offer_amount) AS median_offer_amount,
    percentile_cont(0.75) WITHIN GROUP (ORDER BY final_offer_amount) AS p75_offer_amount,
    max(final_offer_amount) AS max_offer_amount
FROM msbf_m2.application_final_offer_decision_latest
WHERE module1_run_id=(SELECT run_id FROM _m2_3_dctx)
  AND final_offer_authorized_flag
GROUP BY scenario_code
ORDER BY scenario_code;

/* Result Set 12 — Final Remittance and Payback Distribution */
SELECT
    scenario_code,
    min(final_remittance_rate) AS min_remittance_rate,
    avg(final_remittance_rate) AS avg_remittance_rate,
    max(final_remittance_rate) AS max_remittance_rate,
    min(final_payback_multiple) AS min_payback_multiple,
    avg(final_payback_multiple) AS avg_payback_multiple,
    max(final_payback_multiple) AS max_payback_multiple
FROM msbf_m2.application_final_offer_decision_latest
WHERE module1_run_id=(SELECT run_id FROM _m2_3_dctx)
  AND final_offer_authorized_flag
GROUP BY scenario_code
ORDER BY scenario_code;

/* Result Set 13 — Matched Baseline / Stress Decision Migration */
SELECT
    baseline_decision_outcome_code,
    stress_decision_outcome_code,
    count(*) AS matched_applications,
    count(*) FILTER(WHERE stress_decision_improvement_flag) AS stress_decision_improvements,
    count(*) FILTER(WHERE stress_offer_term_improvement_flag) AS stress_offer_term_improvements
FROM msbf_m2.v_m2_3_matched_scenario_comparison
WHERE module1_run_id=(SELECT run_id FROM _m2_3_dctx)
GROUP BY baseline_decision_outcome_code, stress_decision_outcome_code
ORDER BY baseline_decision_outcome_code, stress_decision_outcome_code;

/* Result Set 14 — Stress Non-Improvement Diagnostics */
SELECT
    count(*) AS matched_applications,
    count(*) FILTER(WHERE stress_decision_improvement_flag) AS stress_decision_improvements,
    count(*) FILTER(WHERE stress_offer_term_improvement_flag) AS stress_offer_term_improvements,
    count(*) FILTER(WHERE stress_offer_authorized_flag AND baseline_offer_authorized_flag) AS both_offer_authorized_rows
FROM msbf_m2.v_m2_3_matched_scenario_comparison
WHERE module1_run_id=(SELECT run_id FROM _m2_3_dctx);

/* Result Set 15 — Source to Final Decision Mapping */
SELECT
    source_pricing_disposition_code,
    final_decision_outcome_code,
    final_offer_authorized_flag,
    counteroffer_review_required_flag,
    decline_authorized_flag,
    count(*) AS rows
FROM msbf_m2.application_final_offer_decision_latest
WHERE module1_run_id=(SELECT run_id FROM _m2_3_dctx)
GROUP BY source_pricing_disposition_code, final_decision_outcome_code,
         final_offer_authorized_flag, counteroffer_review_required_flag,
         decline_authorized_flag
ORDER BY source_pricing_disposition_code, final_decision_outcome_code;

/* Result Set 16 — Primary Reason Distribution */
SELECT
    primary_decision_reason_code,
    final_decision_outcome_code,
    count(*) AS rows
FROM msbf_m2.application_final_offer_decision_latest
WHERE module1_run_id=(SELECT run_id FROM _m2_3_dctx)
GROUP BY primary_decision_reason_code, final_decision_outcome_code
ORDER BY rows DESC, primary_decision_reason_code;

/* Result Set 17 — Latest / Archive Reproduction */
SELECT
    count(*) AS joined_rows,
    count(*) FILTER
    (
        WHERE latest.contract_row_hash IS DISTINCT FROM archive.contract_row_hash
           OR archive.contract_payload IS DISTINCT FROM (to_jsonb(latest)-'created_at')
    ) AS reproduction_mismatches
FROM msbf_m2.application_final_offer_decision_latest AS latest
FULL OUTER JOIN msbf_m2.application_final_offer_decision_archive AS archive
  ON archive.module1_run_id=latest.module1_run_id
 AND archive.contract_version=latest.contract_version
 AND archive.scenario_id=latest.scenario_id
 AND archive.merchant_application_id=latest.merchant_application_id
WHERE coalesce(latest.module1_run_id,archive.module1_run_id)=
      (SELECT run_id FROM _m2_3_dctx);

/* Result Set 18 — Contract Registry and Hash Summary */
SELECT *
FROM msbf_ctl.m2_3_final_decision_contract_registry
WHERE module1_run_id=(SELECT run_id FROM _m2_3_dctx);

/* Result Set 19 — Governed Evidence Summary */
SELECT
    CASE
        WHEN evidence_code LIKE 'M2_3_POS_%' THEN 'POSITIVE_VALIDATION'
        WHEN evidence_code LIKE 'M2_3_NEG_%' THEN 'NEGATIVE_CONTROL'
        WHEN evidence_code = 'M2_3_ACCEPTANCE_SUMMARY' THEN 'ACCEPTANCE'
        ELSE 'GENERATION'
    END AS evidence_family,
    status,
    count(*) AS evidence_rows
FROM msbf_ctl.run_evidence
WHERE run_id=(SELECT run_id FROM _m2_3_dctx)
  AND evidence_code LIKE 'M2_3_%'
GROUP BY evidence_family, status
ORDER BY evidence_family, status;

/* Result Set 20 — Sample Final Offer and Decision Profiles */
SELECT
    scenario_code,
    merchant_application_id,
    source_pricing_disposition_code,
    final_decision_outcome_code,
    final_offer_authorized_flag,
    decline_authorized_flag,
    manual_review_required_flag,
    final_offer_amount,
    final_remittance_rate,
    final_payback_multiple,
    final_collection_horizon_days,
    primary_decision_reason_code
FROM msbf_m2.application_final_offer_decision_latest
WHERE module1_run_id=(SELECT run_id FROM _m2_3_dctx)
ORDER BY scenario_code, final_decision_outcome_code, merchant_application_id
LIMIT 40;

/* Result Set 21 — Stage Boundary Check */
SELECT
    'NON_OFFER_TERMS' AS check_name,
    count(*) AS violation_rows
FROM msbf_m2.application_final_offer_decision_latest
WHERE module1_run_id=(SELECT run_id FROM _m2_3_dctx)
  AND NOT final_offer_authorized_flag
  AND final_offer_amount IS NOT NULL
UNION ALL
SELECT
    'PRODUCTION_ADVERSE_ACTION_FLAGS',
    count(*)
FROM msbf_m2.final_decision_reason_definition
WHERE module1_run_id=(SELECT run_id FROM _m2_3_dctx)
  AND production_adverse_action_notice_flag
UNION ALL
SELECT
    'BOOKING_FUNDING_OUTCOME_FLAGS',
    count(*)
FROM msbf_m2.final_decision_outcome_definition
WHERE module1_run_id=(SELECT run_id FROM _m2_3_dctx)
  AND booking_funding_flag;

/* Result Set 22 — Power BI Consumption Snapshot */
SELECT *
FROM msbf_m2.v_m2_3_power_bi_final_decision
WHERE module1_run_id=(SELECT run_id FROM _m2_3_dctx)
ORDER BY scenario_code, merchant_application_id
LIMIT 100;

/* Result Set 23 — Deterministic Mismatches */
WITH mismatches AS
(
    SELECT
        'SOURCE' AS entity_type,
        source.scenario_id::text || '|' || source.merchant_application_id AS entity_key,
        source.row_hash AS stored_hash,
        msbf_ctl.m2_3_hash_jsonb(to_jsonb(source)-'row_hash'-'created_at') AS reconstructed_hash
    FROM msbf_m2.application_final_decision_source_snapshot AS source
    WHERE source.module1_run_id=(SELECT run_id FROM _m2_3_dctx)

    UNION ALL

    SELECT
        'DECISION_SNAPSHOT',
        snapshot.scenario_id::text || '|' || snapshot.merchant_application_id,
        snapshot.row_hash,
        msbf_ctl.m2_3_hash_jsonb(to_jsonb(snapshot)-'row_hash'-'created_at')
    FROM msbf_m2.application_final_offer_decision_snapshot AS snapshot
    WHERE snapshot.module1_run_id=(SELECT run_id FROM _m2_3_dctx)

    UNION ALL

    SELECT
        'LATEST',
        latest.scenario_id::text || '|' || latest.merchant_application_id,
        latest.contract_row_hash,
        msbf_ctl.m2_3_hash_jsonb(to_jsonb(latest)-'contract_row_hash'-'created_at')
    FROM msbf_m2.application_final_offer_decision_latest AS latest
    WHERE latest.module1_run_id=(SELECT run_id FROM _m2_3_dctx)

    UNION ALL

    SELECT
        'ARCHIVE',
        archive.scenario_id::text || '|' || archive.merchant_application_id,
        archive.archive_row_hash,
        msbf_ctl.m2_3_hash_jsonb(to_jsonb(archive)-'archive_id'-'archive_row_hash'-'archived_at'-'created_at')
    FROM msbf_m2.application_final_offer_decision_archive AS archive
    WHERE archive.module1_run_id=(SELECT run_id FROM _m2_3_dctx)
)
SELECT
    entity_type,
    entity_key,
    stored_hash,
    reconstructed_hash
FROM mismatches
WHERE stored_hash IS DISTINCT FROM reconstructed_hash
ORDER BY entity_type, entity_key;

/* Result Set 24 — Blocking Errors and Stage-Boundary Violations */
SELECT
    'FAILED_EVIDENCE' AS violation_type,
    'msbf_ctl.run_evidence' AS object_name,
    evidence_code AS violation_detail
FROM msbf_ctl.run_evidence
WHERE run_id=(SELECT run_id FROM _m2_3_dctx)
  AND evidence_code LIKE 'M2_3_%'
  AND status='FAIL'

UNION ALL

SELECT
    'ACCEPTANCE_NOT_PASS',
    'msbf_ctl.acceptance_gate_result',
    coalesce(result_status,'<NULL>')
FROM msbf_ctl.acceptance_gate_result
WHERE run_id=(SELECT run_id FROM _m2_3_dctx)
  AND gate_id='M2_3_FINAL_OFFER_DECISION_AUTHORIZATION'
  AND result_status <> 'PASS'

UNION ALL

SELECT
    'PROHIBITED_BOOKING_OR_FUNDING_COLUMN',
    table_schema || '.' || table_name,
    column_name
FROM information_schema.columns
WHERE table_schema='msbf_m2'
  AND table_name IN
  (
      'application_final_offer_decision_snapshot',
      'application_final_offer_decision_latest',
      'application_final_offer_decision_archive'
  )
  AND lower(column_name) IN
  (
      'booking_status',
      'funding_status',
      'funded_amount',
      'loan_number',
      'account_number',
      'external_notice_payload'
  )

UNION ALL

SELECT
    'STRESS_IMPROVEMENT',
    'msbf_m2.v_m2_3_matched_scenario_comparison',
    merchant_application_id
FROM msbf_m2.v_m2_3_matched_scenario_comparison
WHERE module1_run_id=(SELECT run_id FROM _m2_3_dctx)
  AND
  (
      stress_decision_improvement_flag
      OR stress_offer_term_improvement_flag
  );
