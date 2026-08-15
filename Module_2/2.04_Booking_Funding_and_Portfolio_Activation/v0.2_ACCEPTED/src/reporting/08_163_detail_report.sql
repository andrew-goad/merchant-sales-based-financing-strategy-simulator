/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.4 — Booking, Funding & Portfolio Activation

Program     : 163_MSBF_M2_4_Detail_Report_v0_2.sql
Version     : v0.2
Purpose     : Produce twenty-four governed, read-only result sets covering the
              complete M2.4 contract, activation outcomes, synthetic account/
              advance/portfolio sub-ledgers, lineage, controls, hashes,
              stress comparisons and stage-boundary diagnostics.

Writes      : Session-scoped context only.
Required    : Result Sets 23 and 24 retain headers and contain zero rows.
============================================================================ */

SET statement_timeout = '35min';
SET jit = off;

DROP TABLE IF EXISTS _m2_4_dctx;

CREATE TEMP TABLE _m2_4_dctx
ON COMMIT PRESERVE ROWS
AS
SELECT run_id
FROM msbf_ctl.run_registry
WHERE run_code = 'M1_V0_2_BASELINE_BUILD'
  AND run_version = 1;

CREATE UNIQUE INDEX ON _m2_4_dctx(run_id);
ANALYZE _m2_4_dctx;

/* Result Set 01 — Run, Contract Lifecycle and Acceptance Gate */
SELECT
    run.run_id,
    run.run_code,
    run.run_version,
    run.run_status,
    registry.contract_code,
    registry.contract_version,
    registry.schema_version,
    registry.methodology_version,
    registry.contract_status,
    gate.gate_id,
    gate.review_version,
    gate.result_status AS gate_status,
    gate.observed_value,
    gate.threshold_value,
    gate.reviewer_role,
    registry.generated_at,
    registry.validated_at,
    registry.accepted_at
FROM msbf_ctl.run_registry AS run
JOIN msbf_ctl.m2_4_portfolio_activation_contract_registry AS registry
  ON registry.module1_run_id = run.run_id
LEFT JOIN msbf_ctl.acceptance_gate_result AS gate
  ON gate.run_id = run.run_id
 AND gate.gate_id = 'M2_4_BOOKING_FUNDING_PORTFOLIO_ACTIVATION'
 AND gate.review_version = 1
WHERE run.run_id = (SELECT run_id FROM _m2_4_dctx);

/* Result Set 02 — Policy and Stage Boundary */
SELECT
    policy_code,
    policy_version,
    policy_status,
    methodology_version,
    contract_code,
    contract_version,
    schema_version,
    source_m2_3_contract_code,
    source_m2_3_contract_version,
    source_m2_3_schema_version,
    source_m2_3_combined_hash,
    synthetic_booking_enabled_flag,
    synthetic_funding_enabled_flag,
    portfolio_activation_enabled_flag,
    synthetic_offer_acceptance_assumed_flag,
    real_funds_movement_prohibited_flag,
    external_notice_transmission_prohibited_flag,
    production_adverse_action_notice_prohibited_flag,
    review_routes_not_bookable_flag,
    decline_routes_not_bookable_flag,
    duplicate_activation_prohibited_flag,
    source_decision_immutable_flag,
    stress_nonimprovement_required_flag,
    booking_lag_days,
    funding_lag_days,
    first_remittance_lag_days,
    monitoring_start_lag_days,
    configuration_hash
FROM msbf_ctl.m2_4_policy_profile
WHERE module1_run_id = (SELECT run_id FROM _m2_4_dctx);

/* Result Set 03 — Activation Outcome Definitions */
SELECT
    activation_outcome_code,
    activation_outcome_rank,
    booking_authorized_flag,
    funding_authorized_flag,
    portfolio_activated_flag,
    operational_review_required_flag,
    external_notice_transmission_flag,
    production_adverse_action_notice_flag,
    real_funds_movement_flag,
    outcome_status,
    description
FROM msbf_m2.booking_funding_activation_outcome_definition
WHERE module1_run_id = (SELECT run_id FROM _m2_4_dctx)
ORDER BY activation_outcome_rank, activation_outcome_code;

/* Result Set 04 — Activation Reason Definitions */
SELECT
    activation_reason_code,
    mapped_activation_outcome_code,
    production_adverse_action_notice_flag,
    reason_status,
    description
FROM msbf_m2.booking_funding_reason_definition
WHERE module1_run_id = (SELECT run_id FROM _m2_4_dctx)
ORDER BY activation_reason_code;

/* Result Set 05 — External Notice Control Definitions */
SELECT
    notice_control_code,
    notice_audience_code,
    external_transmission_authorized_flag,
    production_adverse_action_notice_flag,
    control_status,
    description
FROM msbf_m2.external_notice_control_definition
WHERE module1_run_id = (SELECT run_id FROM _m2_4_dctx)
ORDER BY notice_control_code;

/* Result Set 06 — Entity Cardinality and Governed Grains */
SELECT
    policy_rows,
    outcome_rows,
    reason_rows,
    notice_control_rows,
    source_rows,
    activation_snapshot_rows,
    activation_latest_rows,
    activation_archive_rows,
    account_rows,
    advance_rows,
    portfolio_rows,
    comparison_rows,
    registry_rows,
    canonical_entities
FROM msbf_ctl.m2_4_portfolio_activation_contract_registry
WHERE module1_run_id = (SELECT run_id FROM _m2_4_dctx);

/* Result Set 07 — Source Final-Decision Distribution */
SELECT
    scenario_code,
    final_decision_outcome_code,
    final_offer_authorized_flag,
    counteroffer_review_required_flag,
    decline_authorized_flag,
    count(*) AS rows
FROM msbf_m2.application_booking_funding_source_snapshot
WHERE module1_run_id = (SELECT run_id FROM _m2_4_dctx)
GROUP BY
    scenario_code,
    final_decision_outcome_code,
    final_offer_authorized_flag,
    counteroffer_review_required_flag,
    decline_authorized_flag
ORDER BY scenario_code, final_decision_outcome_code;

/* Result Set 08 — Activation Outcome Distribution by Scenario */
SELECT
    scenario_code,
    activation_outcome_code,
    activation_evidence_status,
    booking_authorized_flag,
    funding_completed_flag,
    portfolio_activated_flag,
    count(*) AS rows
FROM msbf_m2.application_booking_funding_activation_latest
WHERE module1_run_id = (SELECT run_id FROM _m2_4_dctx)
GROUP BY
    scenario_code,
    activation_outcome_code,
    activation_evidence_status,
    booking_authorized_flag,
    funding_completed_flag,
    portfolio_activated_flag
ORDER BY scenario_code, activation_outcome_code;

/* Result Set 09 — Activated Population Economics */
SELECT
    scenario_code,
    count(*) AS activated_rows,
    round(sum(funded_amount),2) AS total_funded_amount,
    round(avg(funded_amount),2) AS average_funded_amount,
    min(funded_amount) AS minimum_funded_amount,
    max(funded_amount) AS maximum_funded_amount,
    round(avg(activation_remittance_rate),6)
        AS average_remittance_rate,
    round(avg(activation_payback_multiple),6)
        AS average_payback_multiple,
    round(avg(activation_collection_horizon_days),2)
        AS average_collection_horizon_days
FROM msbf_m2.application_booking_funding_activation_latest
WHERE module1_run_id = (SELECT run_id FROM _m2_4_dctx)
  AND portfolio_activated_flag
GROUP BY scenario_code
ORDER BY scenario_code;

/* Result Set 10 — Review and Non-Activated Population */
SELECT
    scenario_code,
    activation_outcome_code,
    operational_review_required_flag,
    primary_activation_reason_code,
    count(*) AS rows
FROM msbf_m2.application_booking_funding_activation_latest
WHERE module1_run_id = (SELECT run_id FROM _m2_4_dctx)
  AND NOT portfolio_activated_flag
GROUP BY
    scenario_code,
    activation_outcome_code,
    operational_review_required_flag,
    primary_activation_reason_code
ORDER BY scenario_code, activation_outcome_code,
         primary_activation_reason_code;

/* Result Set 11 — Synthetic Account Activation */
SELECT
    scenario_code,
    account_status,
    min(account_open_date) AS earliest_account_open_date,
    max(account_open_date) AS latest_account_open_date,
    count(*) AS account_rows,
    count(DISTINCT synthetic_account_id) AS distinct_account_ids
FROM msbf_m2.synthetic_account_activation
WHERE module1_run_id = (SELECT run_id FROM _m2_4_dctx)
GROUP BY scenario_code, account_status
ORDER BY scenario_code, account_status;

/* Result Set 12 — Synthetic Advance Funding */
SELECT
    scenario_code,
    funding_status,
    real_funds_movement_flag,
    count(*) AS advance_rows,
    round(sum(funded_amount),2) AS total_funded_amount,
    round(avg(funded_amount),2) AS average_funded_amount,
    min(funding_date) AS earliest_funding_date,
    max(funding_date) AS latest_funding_date,
    min(first_expected_remittance_date)
        AS earliest_first_remittance_date,
    max(first_expected_remittance_date)
        AS latest_first_remittance_date
FROM msbf_m2.synthetic_advance_funding
WHERE module1_run_id = (SELECT run_id FROM _m2_4_dctx)
GROUP BY scenario_code, funding_status, real_funds_movement_flag
ORDER BY scenario_code, funding_status;

/* Result Set 13 — Initial Portfolio Activation */
SELECT
    scenario_code,
    portfolio_status,
    count(*) AS portfolio_rows,
    round(sum(original_funded_amount),2)
        AS total_original_funded_amount,
    round(sum(current_outstanding_balance_proxy),2)
        AS total_outstanding_balance_proxy,
    round(sum(initial_expected_collection_amount),2)
        AS total_initial_expected_collection_amount,
    min(portfolio_activation_date)
        AS earliest_portfolio_activation_date,
    max(portfolio_activation_date)
        AS latest_portfolio_activation_date,
    min(monitoring_start_date) AS earliest_monitoring_start_date,
    max(monitoring_start_date) AS latest_monitoring_start_date
FROM msbf_m2.initial_portfolio_activation
WHERE module1_run_id = (SELECT run_id FROM _m2_4_dctx)
GROUP BY scenario_code, portfolio_status
ORDER BY scenario_code, portfolio_status;

/* Result Set 14 — Operational Date and Lag Diagnostics */
SELECT
    scenario_code,
    count(*) AS activated_rows,
    min(booking_date - as_of_date) AS minimum_booking_lag_days,
    max(booking_date - as_of_date) AS maximum_booking_lag_days,
    min(funding_date - as_of_date) AS minimum_funding_lag_days,
    max(funding_date - as_of_date) AS maximum_funding_lag_days,
    min(first_expected_remittance_date - as_of_date)
        AS minimum_first_remittance_lag_days,
    max(first_expected_remittance_date - as_of_date)
        AS maximum_first_remittance_lag_days,
    min(monitoring_start_date - as_of_date)
        AS minimum_monitoring_start_lag_days,
    max(monitoring_start_date - as_of_date)
        AS maximum_monitoring_start_lag_days
FROM msbf_m2.application_booking_funding_activation_latest
WHERE module1_run_id = (SELECT run_id FROM _m2_4_dctx)
  AND portfolio_activated_flag
GROUP BY scenario_code
ORDER BY scenario_code;

/* Result Set 15 — Source Decision to Activation Mapping */
SELECT
    source_final_decision_outcome_code,
    activation_outcome_code,
    booking_eligible_flag,
    booking_authorized_flag,
    funding_authorized_flag,
    portfolio_activated_flag,
    operational_review_required_flag,
    count(*) AS rows
FROM msbf_m2.application_booking_funding_activation_latest
WHERE module1_run_id = (SELECT run_id FROM _m2_4_dctx)
GROUP BY
    source_final_decision_outcome_code,
    activation_outcome_code,
    booking_eligible_flag,
    booking_authorized_flag,
    funding_authorized_flag,
    portfolio_activated_flag,
    operational_review_required_flag
ORDER BY source_final_decision_outcome_code,
         activation_outcome_code;

/* Result Set 16 — Primary Activation Reason Distribution */
SELECT
    primary_activation_reason_code,
    activation_outcome_code,
    count(*) AS rows
FROM msbf_m2.application_booking_funding_activation_latest
WHERE module1_run_id = (SELECT run_id FROM _m2_4_dctx)
GROUP BY primary_activation_reason_code, activation_outcome_code
ORDER BY rows DESC, primary_activation_reason_code;

/* Result Set 17 — Notice-Control Distribution */
SELECT
    latest.notice_control_code,
    notice.notice_audience_code,
    notice.external_transmission_authorized_flag,
    notice.production_adverse_action_notice_flag,
    count(*) AS rows
FROM msbf_m2.application_booking_funding_activation_latest AS latest
JOIN msbf_m2.external_notice_control_definition AS notice
  ON notice.module1_run_id = latest.module1_run_id
 AND notice.notice_control_code = latest.notice_control_code
WHERE latest.module1_run_id = (SELECT run_id FROM _m2_4_dctx)
GROUP BY
    latest.notice_control_code,
    notice.notice_audience_code,
    notice.external_transmission_authorized_flag,
    notice.production_adverse_action_notice_flag
ORDER BY latest.notice_control_code;

/* Result Set 18 — Matched Baseline / Stress Activation Migration */
SELECT
    baseline_activation_outcome_code,
    stress_activation_outcome_code,
    count(*) AS matched_applications,
    count(*) FILTER
    (
        WHERE stress_activation_improvement_flag
    ) AS stress_activation_improvements,
    count(*) FILTER
    (
        WHERE stress_funded_amount_improvement_flag
    ) AS stress_funded_amount_improvements
FROM msbf_m2.v_m2_4_matched_scenario_comparison
WHERE module1_run_id = (SELECT run_id FROM _m2_4_dctx)
GROUP BY baseline_activation_outcome_code,
         stress_activation_outcome_code
ORDER BY baseline_activation_outcome_code,
         stress_activation_outcome_code;

/* Result Set 19 — Stress Non-Improvement Diagnostics */
SELECT
    count(*) AS matched_applications,
    count(*) FILTER
    (
        WHERE stress_activation_improvement_flag
    ) AS stress_activation_improvements,
    count(*) FILTER
    (
        WHERE stress_funded_amount_improvement_flag
    ) AS stress_funded_amount_improvements,
    count(*) FILTER
    (
        WHERE baseline_portfolio_activated_flag
          AND stress_portfolio_activated_flag
    ) AS both_scenarios_activated_rows,
    count(*) FILTER
    (
        WHERE stress_funded_amount <= baseline_funded_amount
           OR stress_funded_amount IS NULL
           OR baseline_funded_amount IS NULL
    ) AS nonincreasing_funded_amount_rows
FROM msbf_m2.v_m2_4_matched_scenario_comparison
WHERE module1_run_id = (SELECT run_id FROM _m2_4_dctx);

/* Result Set 20 — Latest / Archive Reproduction */
SELECT
    count(*) AS joined_rows,
    count(*) FILTER
    (
        WHERE latest.contract_row_hash IS DISTINCT FROM
              archive.contract_row_hash
           OR archive.contract_payload IS DISTINCT FROM
              (to_jsonb(latest) - 'created_at')
    ) AS reproduction_mismatches
FROM msbf_m2.application_booking_funding_activation_latest AS latest
FULL OUTER JOIN
     msbf_m2.application_booking_funding_activation_archive AS archive
  ON archive.module1_run_id = latest.module1_run_id
 AND archive.contract_version = latest.contract_version
 AND archive.scenario_id = latest.scenario_id
 AND archive.merchant_application_id = latest.merchant_application_id
WHERE coalesce(latest.module1_run_id,archive.module1_run_id) =
      (SELECT run_id FROM _m2_4_dctx);

/* Result Set 21 — Contract Registry and Hash Summary */
SELECT
    registry_id,
    module1_run_id,
    contract_code,
    contract_version,
    schema_version,
    methodology_version,
    source_m2_3_contract_code,
    source_m2_3_contract_version,
    source_m2_3_schema_version,
    source_m2_3_combined_hash,
    source_m2_3_acceptance_gate_id,
    policy_configuration_hash,
    policy_rows,
    outcome_rows,
    reason_rows,
    notice_control_rows,
    source_rows,
    activation_snapshot_rows,
    activation_latest_rows,
    activation_archive_rows,
    account_rows,
    advance_rows,
    portfolio_rows,
    comparison_rows,
    registry_rows,
    canonical_entities,
    activated_rows,
    review_required_rows,
    not_activated_insufficient_rows,
    not_activated_policy_rows,
    policy_set_hash,
    outcome_set_hash,
    reason_set_hash,
    notice_control_set_hash,
    source_set_hash,
    activation_snapshot_set_hash,
    activation_latest_set_hash,
    activation_archive_set_hash,
    account_set_hash,
    advance_set_hash,
    portfolio_set_hash,
    contract_set_hash,
    combined_set_hash,
    contract_status,
    generated_at,
    validated_at,
    accepted_at,
    row_hash
FROM msbf_ctl.m2_4_portfolio_activation_contract_registry
WHERE module1_run_id = (SELECT run_id FROM _m2_4_dctx);

/* Result Set 22 — Governed Evidence and Sample Activation Profiles */
WITH evidence_summary AS
(
    SELECT
        CASE
            WHEN evidence_code LIKE 'M2_4_POS_%'
                THEN 'POSITIVE_VALIDATION'
            WHEN evidence_code LIKE 'M2_4_NEG_%'
                THEN 'NEGATIVE_CONTROL'
            WHEN evidence_code = 'M2_4_ACCEPTANCE_SUMMARY'
                THEN 'ACCEPTANCE'
            ELSE 'GENERATION'
        END AS evidence_family,
        status,
        count(*) AS evidence_rows
    FROM msbf_ctl.run_evidence
    WHERE run_id = (SELECT run_id FROM _m2_4_dctx)
      AND evidence_code LIKE 'M2_4_%'
    GROUP BY evidence_family, status
),
sample_profiles AS
(
    SELECT
        scenario_code,
        merchant_application_id,
        source_final_decision_outcome_code,
        activation_outcome_code,
        portfolio_activated_flag,
        operational_review_required_flag,
        synthetic_account_id,
        synthetic_advance_id,
        funded_amount,
        booking_date,
        funding_date,
        portfolio_activation_date,
        primary_activation_reason_code,
        row_number() OVER
        (
            PARTITION BY scenario_code,activation_outcome_code
            ORDER BY merchant_application_id
        ) AS sample_rank
    FROM msbf_m2.application_booking_funding_activation_latest
    WHERE module1_run_id = (SELECT run_id FROM _m2_4_dctx)
)
SELECT
    'EVIDENCE'::text AS record_type,
    evidence_summary.evidence_family AS category,
    evidence_summary.status AS status,
    evidence_summary.evidence_rows::text AS record_value,
    NULL::text AS merchant_application_id,
    NULL::text AS synthetic_account_id,
    NULL::text AS synthetic_advance_id,
    NULL::numeric(18,2) AS funded_amount,
    NULL::date AS activation_date
FROM evidence_summary

UNION ALL

SELECT
    'SAMPLE_PROFILE',
    sample_profiles.scenario_code || '|' ||
        sample_profiles.activation_outcome_code,
    CASE
        WHEN sample_profiles.portfolio_activated_flag THEN 'ACTIVATED'
        WHEN sample_profiles.operational_review_required_flag THEN 'REVIEW'
        ELSE 'NOT_ACTIVATED'
    END,
    sample_profiles.primary_activation_reason_code,
    sample_profiles.merchant_application_id,
    sample_profiles.synthetic_account_id,
    sample_profiles.synthetic_advance_id,
    sample_profiles.funded_amount,
    sample_profiles.portfolio_activation_date
FROM sample_profiles
WHERE sample_rank <= 5
ORDER BY record_type,category,merchant_application_id;

/* Result Set 23 — Deterministic Mismatches */
WITH mismatches AS
(
    SELECT
        'POLICY'::text AS entity_type,
        policy.policy_code || '|v' || policy.policy_version::text
            AS entity_key,
        policy.row_hash AS stored_hash,
        msbf_ctl.m2_4_hash_jsonb
        (
            to_jsonb(policy)
            - 'row_hash'
            - 'created_at'
            - 'updated_at'
        ) AS reconstructed_hash
    FROM msbf_ctl.m2_4_policy_profile AS policy
    WHERE policy.module1_run_id = (SELECT run_id FROM _m2_4_dctx)

    UNION ALL

    SELECT
        'OUTCOME',
        outcome.activation_outcome_code,
        outcome.row_hash,
        msbf_ctl.m2_4_hash_jsonb
        (
            to_jsonb(outcome) - 'row_hash' - 'created_at'
        )
    FROM msbf_m2.booking_funding_activation_outcome_definition AS outcome
    WHERE outcome.module1_run_id = (SELECT run_id FROM _m2_4_dctx)

    UNION ALL

    SELECT
        'REASON',
        reason.activation_reason_code,
        reason.row_hash,
        msbf_ctl.m2_4_hash_jsonb
        (
            to_jsonb(reason) - 'row_hash' - 'created_at'
        )
    FROM msbf_m2.booking_funding_reason_definition AS reason
    WHERE reason.module1_run_id = (SELECT run_id FROM _m2_4_dctx)

    UNION ALL

    SELECT
        'NOTICE_CONTROL',
        notice.notice_control_code,
        notice.row_hash,
        msbf_ctl.m2_4_hash_jsonb
        (
            to_jsonb(notice) - 'row_hash' - 'created_at'
        )
    FROM msbf_m2.external_notice_control_definition AS notice
    WHERE notice.module1_run_id = (SELECT run_id FROM _m2_4_dctx)

    UNION ALL

    SELECT
        'SOURCE',
        source.scenario_id::text || '|' ||
            source.merchant_application_id,
        source.row_hash,
        msbf_ctl.m2_4_hash_jsonb
        (
            to_jsonb(source) - 'row_hash' - 'created_at'
        )
    FROM msbf_m2.application_booking_funding_source_snapshot AS source
    WHERE source.module1_run_id = (SELECT run_id FROM _m2_4_dctx)

    UNION ALL

    SELECT
        'ACTIVATION_SNAPSHOT',
        snapshot.scenario_id::text || '|' ||
            snapshot.merchant_application_id,
        snapshot.row_hash,
        msbf_ctl.m2_4_hash_jsonb
        (
            to_jsonb(snapshot) - 'row_hash' - 'created_at'
        )
    FROM msbf_m2.application_booking_funding_activation_snapshot AS snapshot
    WHERE snapshot.module1_run_id = (SELECT run_id FROM _m2_4_dctx)

    UNION ALL

    SELECT
        'LATEST',
        latest.scenario_id::text || '|' ||
            latest.merchant_application_id,
        latest.contract_row_hash,
        msbf_ctl.m2_4_hash_jsonb
        (
            to_jsonb(latest) - 'contract_row_hash' - 'created_at'
        )
    FROM msbf_m2.application_booking_funding_activation_latest AS latest
    WHERE latest.module1_run_id = (SELECT run_id FROM _m2_4_dctx)

    UNION ALL

    SELECT
        'ARCHIVE',
        archive.scenario_id::text || '|' ||
            archive.merchant_application_id,
        archive.archive_row_hash,
        msbf_ctl.m2_4_hash_jsonb
        (
            to_jsonb(archive)
            - 'archive_id'
            - 'archive_row_hash'
            - 'archived_at'
            - 'created_at'
        )
    FROM msbf_m2.application_booking_funding_activation_archive AS archive
    WHERE archive.module1_run_id = (SELECT run_id FROM _m2_4_dctx)

    UNION ALL

    SELECT
        'ACCOUNT',
        account.scenario_id::text || '|' ||
            account.merchant_application_id,
        account.row_hash,
        msbf_ctl.m2_4_hash_jsonb
        (
            to_jsonb(account) - 'row_hash' - 'created_at'
        )
    FROM msbf_m2.synthetic_account_activation AS account
    WHERE account.module1_run_id = (SELECT run_id FROM _m2_4_dctx)

    UNION ALL

    SELECT
        'ADVANCE',
        advance.scenario_id::text || '|' ||
            advance.merchant_application_id,
        advance.row_hash,
        msbf_ctl.m2_4_hash_jsonb
        (
            to_jsonb(advance) - 'row_hash' - 'created_at'
        )
    FROM msbf_m2.synthetic_advance_funding AS advance
    WHERE advance.module1_run_id = (SELECT run_id FROM _m2_4_dctx)

    UNION ALL

    SELECT
        'PORTFOLIO',
        portfolio.scenario_id::text || '|' ||
            portfolio.merchant_application_id,
        portfolio.row_hash,
        msbf_ctl.m2_4_hash_jsonb
        (
            to_jsonb(portfolio) - 'row_hash' - 'created_at'
        )
    FROM msbf_m2.initial_portfolio_activation AS portfolio
    WHERE portfolio.module1_run_id = (SELECT run_id FROM _m2_4_dctx)

    UNION ALL

    SELECT
        'REGISTRY',
        registry.contract_code || '|v' ||
            registry.contract_version::text,
        registry.row_hash,
        msbf_ctl.m2_4_registry_row_hash(to_jsonb(registry))
    FROM msbf_ctl.m2_4_portfolio_activation_contract_registry AS registry
    WHERE registry.module1_run_id = (SELECT run_id FROM _m2_4_dctx)
)
SELECT
    entity_type,
    entity_key,
    stored_hash,
    reconstructed_hash
FROM mismatches
WHERE stored_hash IS DISTINCT FROM reconstructed_hash
ORDER BY entity_type,entity_key;

/* Result Set 24 — Blocking Errors and Stage-Boundary Violations */
SELECT
    'FAILED_EVIDENCE'::text AS violation_type,
    'msbf_ctl.run_evidence'::text AS object_name,
    evidence_code AS violation_detail
FROM msbf_ctl.run_evidence
WHERE run_id = (SELECT run_id FROM _m2_4_dctx)
  AND evidence_code LIKE 'M2_4_%'
  AND status = 'FAIL'

UNION ALL

SELECT
    'ACCEPTANCE_NOT_PASS',
    'msbf_ctl.acceptance_gate_result',
    coalesce(result_status,'<NULL>')
FROM msbf_ctl.acceptance_gate_result
WHERE run_id = (SELECT run_id FROM _m2_4_dctx)
  AND gate_id = 'M2_4_BOOKING_FUNDING_PORTFOLIO_ACTIVATION'
  AND result_status <> 'PASS'

UNION ALL

SELECT
    'PROHIBITED_REAL_WORLD_COLUMN',
    table_schema || '.' || table_name,
    column_name
FROM information_schema.columns
WHERE table_schema = 'msbf_m2'
  AND table_name IN
  (
      'application_booking_funding_activation_snapshot',
      'application_booking_funding_activation_latest',
      'application_booking_funding_activation_archive',
      'synthetic_account_activation',
      'synthetic_advance_funding',
      'initial_portfolio_activation'
  )
  AND lower(column_name) IN
  (
      'ach_trace_number',
      'bank_account_number',
      'settlement_account_number',
      'routing_number',
      'real_account_number',
      'core_booking_id',
      'external_notice_payload',
      'production_adverse_action_notice'
  )

UNION ALL

SELECT
    'PROHIBITED_OPERATIONAL_FLAG',
    'msbf_m2.application_booking_funding_activation_latest',
    scenario_code || '|' || merchant_application_id
FROM msbf_m2.application_booking_funding_activation_latest
WHERE module1_run_id = (SELECT run_id FROM _m2_4_dctx)
  AND
  (
      real_funds_movement_flag
      OR external_notice_generation_authorized_flag
      OR external_notice_transmitted_flag
      OR production_adverse_action_notice_flag
  )

UNION ALL

SELECT
    'NONACTIVATED_OPERATIONAL_PAYLOAD',
    'msbf_m2.application_booking_funding_activation_latest',
    scenario_code || '|' || merchant_application_id
FROM msbf_m2.application_booking_funding_activation_latest
WHERE module1_run_id = (SELECT run_id FROM _m2_4_dctx)
  AND NOT portfolio_activated_flag
  AND
  (
      synthetic_account_id IS NOT NULL
      OR synthetic_advance_id IS NOT NULL
      OR funded_amount IS NOT NULL
      OR booking_date IS NOT NULL
      OR funding_date IS NOT NULL
      OR portfolio_activation_date IS NOT NULL
  )

UNION ALL

SELECT
    'STRESS_IMPROVEMENT',
    'msbf_m2.v_m2_4_matched_scenario_comparison',
    merchant_application_id
FROM msbf_m2.v_m2_4_matched_scenario_comparison
WHERE module1_run_id = (SELECT run_id FROM _m2_4_dctx)
  AND
  (
      stress_activation_improvement_flag
      OR stress_funded_amount_improvement_flag
  )

UNION ALL

SELECT
    'SUBLEDGER_LINK_MISMATCH',
    'M2.4 activation/account/advance/portfolio',
    latest.scenario_code || '|' || latest.merchant_application_id
FROM msbf_m2.application_booking_funding_activation_latest AS latest
LEFT JOIN msbf_m2.synthetic_account_activation AS account
  ON account.module1_run_id = latest.module1_run_id
 AND account.scenario_id = latest.scenario_id
 AND account.merchant_application_id = latest.merchant_application_id
LEFT JOIN msbf_m2.synthetic_advance_funding AS advance
  ON advance.module1_run_id = latest.module1_run_id
 AND advance.scenario_id = latest.scenario_id
 AND advance.merchant_application_id = latest.merchant_application_id
LEFT JOIN msbf_m2.initial_portfolio_activation AS portfolio
  ON portfolio.module1_run_id = latest.module1_run_id
 AND portfolio.scenario_id = latest.scenario_id
 AND portfolio.merchant_application_id = latest.merchant_application_id
WHERE latest.module1_run_id = (SELECT run_id FROM _m2_4_dctx)
  AND latest.portfolio_activated_flag
  AND
  (
      account.synthetic_account_id IS DISTINCT FROM latest.synthetic_account_id
      OR advance.synthetic_advance_id IS DISTINCT FROM latest.synthetic_advance_id
      OR portfolio.synthetic_advance_id IS DISTINCT FROM latest.synthetic_advance_id
  )

UNION ALL

SELECT
    'REASON_OUTCOME_MAPPING_MISMATCH',
    'msbf_m2.application_booking_funding_activation_latest',
    activation.scenario_code || '|' ||
        activation.merchant_application_id || '|' ||
        reason_value.value
FROM msbf_m2.application_booking_funding_activation_latest AS activation
CROSS JOIN LATERAL jsonb_array_elements_text
     (activation.activation_reason_codes) AS reason_value
WHERE activation.module1_run_id = (SELECT run_id FROM _m2_4_dctx)
  AND NOT EXISTS
  (
      SELECT 1
      FROM msbf_m2.booking_funding_reason_definition AS reason
      WHERE reason.module1_run_id = activation.module1_run_id
        AND reason.activation_reason_code = reason_value.value
        AND reason.mapped_activation_outcome_code =
            activation.activation_outcome_code
  );
