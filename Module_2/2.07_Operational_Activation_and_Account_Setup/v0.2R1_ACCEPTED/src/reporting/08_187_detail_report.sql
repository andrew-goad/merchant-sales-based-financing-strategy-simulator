/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.7 — Operational Activation & Account Setup
============================================================================ */

/* ============================================================================
Program     : 187_MSBF_M2_7_Detail_Report_v0_2.sql
Version     : v0.2

Purpose
-------
Produce 24 read-only governed evidence result sets covering lifecycle, policy,
definitions, accepted M2.6 source, exact operational mapping, synthetic setup
terms, portfolio summaries, matched stress diagnostics, latest/archive
reproduction, hashes, evidence, Power BI consumption, deterministic
mismatches, and stage-boundary violations.

Required result
---------------
24 result sets. Result Sets 23 and 24 retain headers and contain zero rows.
============================================================================ */

SET statement_timeout='45min';
SET jit=off;

DROP TABLE IF EXISTS _m2_7_dctx;

CREATE TEMP TABLE _m2_7_dctx
ON COMMIT PRESERVE ROWS
AS
SELECT run_id
FROM msbf_ctl.run_registry
WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1;

CREATE INDEX ON _m2_7_dctx(run_id);
ANALYZE _m2_7_dctx;

/* Result Set 01 — Lifecycle and Acceptance */
SELECT
    run.run_id,run.run_code,run.run_version,run.run_status,
    registry.contract_code,registry.contract_version,
    registry.schema_version,registry.methodology_version,
    registry.contract_status,gate.gate_id,
    gate.result_status AS gate_status,
    registry.generated_at,registry.validated_at,registry.accepted_at
FROM msbf_ctl.run_registry AS run
JOIN msbf_ctl.m2_7_operational_activation_contract_registry AS registry
  ON registry.module1_run_id=run.run_id
LEFT JOIN msbf_ctl.acceptance_gate_result AS gate
  ON gate.run_id=run.run_id
 AND gate.gate_id='M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP'
 AND gate.review_version=1
WHERE run.run_id=(SELECT run_id FROM _m2_7_dctx);

/* Result Set 02 — Policy and Source Boundary */
SELECT *
FROM msbf_ctl.m2_7_policy_profile
WHERE module1_run_id=(SELECT run_id FROM _m2_7_dctx);

/* Result Set 03 — Operational Setup Outcome Definitions */
SELECT
    operational_setup_outcome_code,operational_setup_outcome_rank,
    setup_authorized_flag,blueprint_created_flag,
    setup_review_required_flag,no_setup_required_flag,
    real_core_account_created_flag,real_payment_change_executed_flag,
    external_notice_generated_flag,production_adverse_action_flag,
    definition_status,description,row_hash
FROM msbf_m2.operational_setup_outcome_definition
WHERE module1_run_id=(SELECT run_id FROM _m2_7_dctx)
ORDER BY operational_setup_outcome_rank,operational_setup_outcome_code;

/* Result Set 04 — Operational Setup Action Definitions */
SELECT
    operational_setup_action_code,operational_setup_action_rank,
    account_blueprint_review_flag,temporary_adjustment_setup_flag,
    restructure_setup_flag,recovery_setup_flag,charge_off_setup_flag,
    governance_review_flag,real_core_account_created_flag,
    real_payment_change_executed_flag,ach_or_network_transmission_flag,
    merchant_contact_executed_flag,write_off_posted_flag,
    collection_or_legal_executed_flag,external_notice_generated_flag,
    production_adverse_action_flag,definition_status,description,row_hash
FROM msbf_m2.operational_setup_action_definition
WHERE module1_run_id=(SELECT run_id FROM _m2_7_dctx)
ORDER BY operational_setup_action_rank,operational_setup_action_code;

/* Result Set 05 — Operational Setup Reason Definitions */
SELECT
    operational_setup_reason_code,mapped_outcome_code,mapped_action_code,
    executed_action_flag,production_adverse_action_flag,
    definition_status,description,row_hash
FROM msbf_m2.operational_setup_reason_definition
WHERE module1_run_id=(SELECT run_id FROM _m2_7_dctx)
ORDER BY operational_setup_reason_code;

/* Result Set 06 — Entity Counts */
SELECT
    policy_rows,outcome_rows,action_rows,reason_rows,source_rows,
    activation_rows,account_setup_rows,portfolio_summary_rows,
    latest_rows,archive_rows,comparison_rows,registry_rows,
    canonical_entities
FROM msbf_ctl.m2_7_operational_activation_contract_registry
WHERE module1_run_id=(SELECT run_id FROM _m2_7_dctx);

/* Result Set 07 — Accepted M2.6 Source Distribution */
SELECT
    scenario_code,source_strategy_outcome_code,source_servicing_action_code,
    count(*) AS source_rows,
    round(sum(source_recommended_action_exposure_amount),2)
        AS source_recommended_action_exposure_amount
FROM msbf_m2.operational_activation_source_snapshot
WHERE module1_run_id=(SELECT run_id FROM _m2_7_dctx)
GROUP BY
    scenario_code,source_strategy_outcome_code,source_servicing_action_code
ORDER BY
    scenario_code,source_strategy_outcome_code,source_servicing_action_code;

/* Result Set 08 — Operational Setup Outcome Distribution */
SELECT
    scenario_code,operational_setup_outcome_code,
    min(operational_setup_priority_rank) AS operational_setup_priority_rank,
    count(*) AS activation_rows,
    count(*) FILTER(WHERE setup_authorized_flag) AS setup_authorized_rows,
    count(*) FILTER(WHERE setup_review_required_flag) AS review_required_rows,
    count(*) FILTER(WHERE no_setup_required_flag) AS no_setup_required_rows,
    round
    (
        sum
        (
            CASE WHEN setup_authorized_flag
                 THEN source_recommended_action_exposure_amount ELSE 0 END
        ),
        2
    ) AS setup_authorized_amount,
    round
    (
        sum
        (
            CASE WHEN setup_review_required_flag
                 THEN source_recommended_action_exposure_amount ELSE 0 END
        ),
        2
    ) AS review_required_amount
FROM msbf_m2.application_operational_activation_latest
WHERE module1_run_id=(SELECT run_id FROM _m2_7_dctx)
GROUP BY scenario_code,operational_setup_outcome_code
ORDER BY
    scenario_code,operational_setup_priority_rank,
    operational_setup_outcome_code;

/* Result Set 09 — Operational Action and Queue Distribution */
SELECT
    scenario_code,operational_setup_action_code,
    operational_setup_queue_code,account_setup_status_code,
    min(operational_setup_priority_rank) AS operational_setup_priority_rank,
    count(*) AS setup_rows,
    round
    (
        sum
        (
            CASE WHEN setup_authorized_flag
                 THEN source_recommended_action_exposure_amount ELSE 0 END
        ),
        2
    ) AS setup_authorized_amount,
    round
    (
        sum
        (
            CASE WHEN setup_review_required_flag
                 THEN source_recommended_action_exposure_amount ELSE 0 END
        ),
        2
    ) AS review_required_amount
FROM msbf_m2.application_operational_activation_latest
WHERE module1_run_id=(SELECT run_id FROM _m2_7_dctx)
GROUP BY
    scenario_code,operational_setup_action_code,
    operational_setup_queue_code,account_setup_status_code
ORDER BY
    scenario_code,operational_setup_priority_rank,
    operational_setup_action_code;

/* Result Set 10 — Setup-Authorized Detail */
SELECT
    scenario_code,merchant_application_id,synthetic_account_id,
    synthetic_advance_id,source_strategy_outcome_code,
    source_servicing_action_code,
    source_recommended_action_exposure_amount,
    operational_setup_outcome_code,operational_setup_action_code,
    operational_setup_priority_rank,operational_setup_queue_code,
    account_setup_status_code,synthetic_operational_case_id,
    synthetic_account_setup_id,synthetic_servicing_plan_id,
    operational_activation_date,next_reassessment_date,
    applied_temporary_payment_factor,applied_setup_duration_days,
    applied_reassessment_interval_days,primary_setup_reason_code,
    setup_reason_codes
FROM msbf_m2.application_operational_activation_latest
WHERE module1_run_id=(SELECT run_id FROM _m2_7_dctx)
  AND setup_authorized_flag
ORDER BY
    operational_setup_priority_rank DESC,
    scenario_code,merchant_application_id;

/* Result Set 11 — No-Setup Detail */
SELECT
    scenario_code,merchant_application_id,synthetic_account_id,
    synthetic_advance_id,source_strategy_outcome_code,
    source_servicing_action_code,
    source_recommended_action_exposure_amount,
    operational_setup_outcome_code,operational_setup_action_code,
    account_setup_status_code,synthetic_operational_case_id,
    synthetic_account_setup_id,primary_setup_reason_code,
    setup_reason_codes
FROM msbf_m2.application_operational_activation_latest
WHERE module1_run_id=(SELECT run_id FROM _m2_7_dctx)
  AND no_setup_required_flag
ORDER BY scenario_code,merchant_application_id;

/* Result Set 12 — Operational Review Detail */
SELECT
    scenario_code,merchant_application_id,synthetic_account_id,
    synthetic_advance_id,source_strategy_outcome_code,
    source_servicing_action_code,
    source_recommended_action_exposure_amount,
    operational_setup_outcome_code,operational_setup_action_code,
    operational_setup_queue_code,account_setup_status_code,
    synthetic_operational_case_id,primary_setup_reason_code,
    setup_reason_codes
FROM msbf_m2.application_operational_activation_latest
WHERE module1_run_id=(SELECT run_id FROM _m2_7_dctx)
  AND setup_review_required_flag
ORDER BY scenario_code,merchant_application_id;

/* Result Set 13 — Account Setup Status Distribution */
SELECT
    scenario_code,account_setup_status_code,
    count(*) AS setup_rows,
    count(*) FILTER
    (
        WHERE synthetic_servicing_plan_id IS NOT NULL
    ) AS plan_rows,
    min(operational_activation_date) AS earliest_activation_date,
    max(next_reassessment_date) AS latest_reassessment_date
FROM msbf_m2.application_operational_activation_latest
WHERE module1_run_id=(SELECT run_id FROM _m2_7_dctx)
GROUP BY scenario_code,account_setup_status_code
ORDER BY scenario_code,account_setup_status_code;

/* Result Set 14 — Temporary Adjustment Terms */
SELECT
    scenario_code,merchant_application_id,synthetic_account_id,
    synthetic_advance_id,source_recommended_action_exposure_amount,
    applied_temporary_payment_factor,applied_setup_duration_days,
    applied_reassessment_interval_days,operational_activation_date,
    next_reassessment_date,synthetic_servicing_plan_id,
    setup_parameter_payload
FROM msbf_m2.application_operational_activation_latest
WHERE module1_run_id=(SELECT run_id FROM _m2_7_dctx)
  AND operational_setup_outcome_code=
      'TEMPORARY_PAYMENT_ADJUSTMENT_SETUP_READY'
ORDER BY scenario_code,merchant_application_id;

/* Result Set 15 — Portfolio Operational Setup Summary */
SELECT *
FROM msbf_m2.operational_activation_portfolio_summary
WHERE module1_run_id=(SELECT run_id FROM _m2_7_dctx)
ORDER BY scenario_code;

/* Result Set 16 — Matched Baseline / Stress Comparison */
SELECT
    merchant_application_id,
    baseline_operational_setup_outcome_code,
    stress_operational_setup_outcome_code,
    baseline_operational_setup_priority_rank,
    stress_operational_setup_priority_rank,
    baseline_setup_authorized_flag,stress_setup_authorized_flag,
    baseline_source_exposure_amount,stress_source_exposure_amount,
    stress_setup_permission_improvement_flag,
    stress_priority_improvement_flag
FROM msbf_m2.v_m2_7_matched_scenario_comparison
WHERE module1_run_id=(SELECT run_id FROM _m2_7_dctx)
ORDER BY merchant_application_id;

/* Result Set 17 — Stress Non-Improvement Summary */
SELECT
    count(*) AS matched_rows,
    count(*) FILTER
    (
        WHERE stress_setup_permission_improvement_flag
    ) AS stress_setup_permission_improvements,
    count(*) FILTER
    (
        WHERE stress_priority_improvement_flag
    ) AS stress_priority_improvements
FROM msbf_m2.v_m2_7_matched_scenario_comparison
WHERE module1_run_id=(SELECT run_id FROM _m2_7_dctx);

/* Result Set 18 — Latest / Archive Reproduction */
SELECT
    count(*) AS joined_rows,
    count(*) FILTER
    (
        WHERE l.contract_row_hash IS DISTINCT FROM a.contract_row_hash
           OR a.contract_payload IS DISTINCT FROM
              (to_jsonb(l)-'created_at')
    ) AS reproduction_mismatches
FROM msbf_m2.application_operational_activation_latest AS l
FULL OUTER JOIN msbf_m2.application_operational_activation_archive AS a
  ON a.module1_run_id=l.module1_run_id
 AND a.contract_version=l.contract_version
 AND a.scenario_id=l.scenario_id
 AND a.merchant_application_id=l.merchant_application_id
WHERE coalesce(l.module1_run_id,a.module1_run_id)=
      (SELECT run_id FROM _m2_7_dctx);

/* Result Set 19 — Contract Registry and Hash Summary */
SELECT *
FROM msbf_ctl.m2_7_operational_activation_contract_registry
WHERE module1_run_id=(SELECT run_id FROM _m2_7_dctx);

/* Result Set 20 — Canonical Hash Summary */
SELECT module1_run_id,canonical_entities,combined_set_hash
FROM msbf_m2.v_m2_7_canonical_hash
WHERE module1_run_id=(SELECT run_id FROM _m2_7_dctx);

/* Result Set 21 — Governed Evidence Summary */
SELECT
    CASE
        WHEN evidence_code LIKE 'M2_7_POS_%' THEN 'POSITIVE'
        WHEN evidence_code LIKE 'M2_7_NEG_%' THEN 'NEGATIVE'
        WHEN evidence_code='M2_7_ACCEPTANCE_SUMMARY' THEN 'ACCEPTANCE'
        ELSE 'GENERATION'
    END AS family,
    status,count(*) AS rows
FROM msbf_ctl.run_evidence
WHERE run_id=(SELECT run_id FROM _m2_7_dctx)
  AND evidence_code LIKE 'M2_7_%'
GROUP BY family,status
ORDER BY family,status;

/* Result Set 22 — Power BI Operational Setup Sample */
SELECT *
FROM msbf_m2.v_m2_7_power_bi_operational_setup
WHERE module1_run_id=(SELECT run_id FROM _m2_7_dctx)
ORDER BY
    operational_setup_priority_rank DESC,
    scenario_code,merchant_application_id
LIMIT 40;

/* Result Set 23 — Deterministic Mismatches */
WITH mismatches AS
(
    SELECT
        'POLICY'::text AS entity_type,
        policy_code||'|v'||policy_version::text AS entity_key,
        row_hash AS stored_hash,
        msbf_ctl.m2_7_hash_jsonb
        (
            to_jsonb(p)-'row_hash'-'created_at'-'updated_at'
        ) AS reconstructed_hash
    FROM msbf_ctl.m2_7_policy_profile AS p
    WHERE module1_run_id=(SELECT run_id FROM _m2_7_dctx)

    UNION ALL

    SELECT
        'OUTCOME_DEFINITION',operational_setup_outcome_code,row_hash,
        msbf_ctl.m2_7_hash_jsonb(to_jsonb(o)-'row_hash'-'created_at')
    FROM msbf_m2.operational_setup_outcome_definition AS o
    WHERE module1_run_id=(SELECT run_id FROM _m2_7_dctx)

    UNION ALL

    SELECT
        'ACTION_DEFINITION',operational_setup_action_code,row_hash,
        msbf_ctl.m2_7_hash_jsonb(to_jsonb(a)-'row_hash'-'created_at')
    FROM msbf_m2.operational_setup_action_definition AS a
    WHERE module1_run_id=(SELECT run_id FROM _m2_7_dctx)

    UNION ALL

    SELECT
        'REASON_DEFINITION',operational_setup_reason_code,row_hash,
        msbf_ctl.m2_7_hash_jsonb(to_jsonb(r)-'row_hash'-'created_at')
    FROM msbf_m2.operational_setup_reason_definition AS r
    WHERE module1_run_id=(SELECT run_id FROM _m2_7_dctx)

    UNION ALL

    SELECT
        'SOURCE',scenario_id::text||'|'||merchant_application_id,row_hash,
        msbf_ctl.m2_7_hash_jsonb(to_jsonb(s)-'row_hash'-'created_at')
    FROM msbf_m2.operational_activation_source_snapshot AS s
    WHERE module1_run_id=(SELECT run_id FROM _m2_7_dctx)

    UNION ALL

    SELECT
        'ACTIVATION',scenario_id::text||'|'||merchant_application_id,row_hash,
        msbf_ctl.m2_7_hash_jsonb(to_jsonb(a)-'row_hash'-'created_at')
    FROM msbf_m2.application_operational_activation_snapshot AS a
    WHERE module1_run_id=(SELECT run_id FROM _m2_7_dctx)

    UNION ALL

    SELECT
        'ACCOUNT_SETUP',scenario_id::text||'|'||merchant_application_id,row_hash,
        msbf_ctl.m2_7_hash_jsonb(to_jsonb(s)-'row_hash'-'created_at')
    FROM msbf_m2.operational_account_setup_snapshot AS s
    WHERE module1_run_id=(SELECT run_id FROM _m2_7_dctx)

    UNION ALL

    SELECT
        'PORTFOLIO_SUMMARY',scenario_code,row_hash,
        msbf_ctl.m2_7_hash_jsonb(to_jsonb(p)-'row_hash'-'created_at')
    FROM msbf_m2.operational_activation_portfolio_summary AS p
    WHERE module1_run_id=(SELECT run_id FROM _m2_7_dctx)

    UNION ALL

    SELECT
        'LATEST',scenario_id::text||'|'||merchant_application_id,
        contract_row_hash,
        msbf_ctl.m2_7_hash_jsonb
        (
            to_jsonb(l)-'contract_row_hash'-'created_at'
        )
    FROM msbf_m2.application_operational_activation_latest AS l
    WHERE module1_run_id=(SELECT run_id FROM _m2_7_dctx)

    UNION ALL

    SELECT
        'ARCHIVE',scenario_id::text||'|'||merchant_application_id,
        archive_row_hash,
        msbf_ctl.m2_7_hash_jsonb
        (
            to_jsonb(a)-'archive_id'-'archive_row_hash'-
            'archived_at'-'created_at'
        )
    FROM msbf_m2.application_operational_activation_archive AS a
    WHERE module1_run_id=(SELECT run_id FROM _m2_7_dctx)

    UNION ALL

    SELECT
        'REGISTRY',contract_code||'|v'||contract_version::text,row_hash,
        msbf_ctl.m2_7_registry_row_hash(to_jsonb(r))
    FROM msbf_ctl.m2_7_operational_activation_contract_registry AS r
    WHERE module1_run_id=(SELECT run_id FROM _m2_7_dctx)
)
SELECT entity_type,entity_key,stored_hash,reconstructed_hash
FROM mismatches
WHERE stored_hash IS DISTINCT FROM reconstructed_hash
ORDER BY entity_type,entity_key;

/* Result Set 24 — Blocking Errors and Stage-Boundary Violations */
SELECT
    'FAILED_EVIDENCE'::text AS violation_type,
    evidence_code AS detail
FROM msbf_ctl.run_evidence
WHERE run_id=(SELECT run_id FROM _m2_7_dctx)
  AND evidence_code LIKE 'M2_7_%'
  AND status='FAIL'

UNION ALL

SELECT
    'ACCEPTANCE_NOT_PASS',
    coalesce(result_status,'<NULL>')
FROM msbf_ctl.acceptance_gate_result
WHERE run_id=(SELECT run_id FROM _m2_7_dctx)
  AND gate_id='M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP'
  AND result_status<>'PASS'

UNION ALL

SELECT
    'ACTIVATION_EXECUTION_BOUNDARY',
    scenario_code||'|'||merchant_application_id
FROM msbf_m2.application_operational_activation_snapshot
WHERE module1_run_id=(SELECT run_id FROM _m2_7_dctx)
  AND
  (
      real_core_account_created_flag
      OR real_payment_change_executed_flag
      OR bank_account_data_present_flag
      OR ach_or_network_transmission_flag
      OR external_notice_generated_flag
      OR merchant_contact_executed_flag
      OR write_off_posted_flag
      OR collection_or_legal_executed_flag
      OR production_adverse_action_flag
  )

UNION ALL

SELECT
    'SETUP_EXECUTION_BOUNDARY',
    scenario_code||'|'||merchant_application_id
FROM msbf_m2.operational_account_setup_snapshot
WHERE module1_run_id=(SELECT run_id FROM _m2_7_dctx)
  AND
  (
      real_core_account_created_flag
      OR real_payment_change_executed_flag
      OR bank_account_data_present_flag
      OR ach_or_network_transmission_flag
      OR external_notice_generated_flag
      OR merchant_contact_executed_flag
      OR write_off_posted_flag
      OR collection_or_legal_executed_flag
      OR production_adverse_action_flag
  )

UNION ALL

SELECT
    'STRESS_IMPROVEMENT',
    merchant_application_id
FROM msbf_m2.v_m2_7_matched_scenario_comparison
WHERE module1_run_id=(SELECT run_id FROM _m2_7_dctx)
  AND
  (
      stress_setup_permission_improvement_flag
      OR stress_priority_improvement_flag
  )

UNION ALL

SELECT
    'PROHIBITED_COLUMN',
    table_schema||'.'||table_name||'.'||column_name
FROM information_schema.columns
WHERE table_schema='msbf_m2'
  AND table_name IN
  (
      'application_operational_activation_snapshot',
      'operational_account_setup_snapshot',
      'application_operational_activation_latest',
      'application_operational_activation_archive'
  )
  AND lower(column_name) IN
  (
      'real_core_account_number',
      'bank_account_number',
      'routing_number',
      'settlement_account_number',
      'ach_trace_number',
      'payment_network_confirmation',
      'external_notice_payload',
      'production_adverse_action_notice'
  )

UNION ALL

SELECT
    'PREMATURE_M2_8_OBJECT',
    table_schema||'.'||table_name
FROM information_schema.tables
WHERE table_schema IN ('msbf_ctl','msbf_m2')
  AND lower(table_name) LIKE 'm2_8%';
