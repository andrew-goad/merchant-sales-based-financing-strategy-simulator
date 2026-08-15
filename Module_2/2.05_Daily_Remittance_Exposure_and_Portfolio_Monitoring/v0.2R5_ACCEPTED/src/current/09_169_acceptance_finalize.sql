/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.5 — Daily Remittance, Exposure & Portfolio Monitoring

Program     : 169_msbf_m2_5_acceptance_finalize_v0_2R5.sql
Version     : v0.2R5

Purpose
-------
Independently verify validation evidence, physical cardinalities, daily and
latest/archive identities, portfolio summaries, run-scoped canonical hashes,
stress non-improvement, and monitoring-only stage boundaries before issuing
the M2.5 acceptance gate.

Revision v0.2R5 correction
--------------------------
Aligns acceptance-time `active_advance_count` reproduction to the generation
definition:

    active at day open = receivable_balance_before > 0

The prior v0.2 acceptance program incorrectly used `NOT paid_off_flag`, an
end-of-day state. A record that paid off during the day is active at day open
and paid off at day end, so the prior expression understated active advances
on payoff-event days. No generated row, hash, source contract, monitoring
status, alert, reason, portfolio summary, positive evidence, or negative
evidence changes.

Required result
---------------
acceptance_status = PASS
final_run_status = M2_5_ACCEPTED
final_contract_status = ACCEPTED
gate_status = PASS.
============================================================================ */

BEGIN;

SET LOCAL work_mem = '128MB';
SET LOCAL statement_timeout = '35min';
SET LOCAL jit = off;

DROP TABLE IF EXISTS _m2_5_acceptance;

CREATE TEMP TABLE _m2_5_acceptance
ON COMMIT PRESERVE ROWS
AS
WITH run_context AS
(
    SELECT
        run_id,
        run_status
    FROM msbf_ctl.run_registry
    WHERE run_code = 'M1_V0_2_BASELINE_BUILD'
      AND run_version = 1
),
registry AS
(
    SELECT
        contract_status,
        policy_rows,
        status_rows,
        alert_rows,
        reason_rows,
        source_rows,
        daily_rows,
        latest_rows,
        archive_rows,
        portfolio_daily_rows,
        comparison_rows,
        registry_rows,
        canonical_entities,
        paid_off_rows,
        open_monitoring_rows,
        stress_status_floor_rows,
        total_remittance_amount,
        ending_receivable_exposure_amount,
        contract_set_hash,
        combined_set_hash
    FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry
    WHERE module1_run_id = (SELECT run_id FROM run_context)
),
controls AS
(
    SELECT
        count(*) FILTER(WHERE evidence_code LIKE 'M2_5_POS_%')::bigint
            AS positive_checks,
        count(*) FILTER
        (
            WHERE evidence_code LIKE 'M2_5_POS_%'
              AND status = 'PASS'
        )::bigint AS positive_passes,
        count(*) FILTER
        (
            WHERE evidence_code LIKE 'M2_5_POS_%'
              AND status <> 'PASS'
        )::bigint AS positive_failures,
        count(*) FILTER(WHERE evidence_code LIKE 'M2_5_NEG_%')::bigint
            AS negative_checks,
        count(*) FILTER
        (
            WHERE evidence_code LIKE 'M2_5_NEG_%'
              AND status = 'PASS'
        )::bigint AS negative_passes,
        count(*) FILTER
        (
            WHERE evidence_code LIKE 'M2_5_NEG_%'
              AND status <> 'PASS'
        )::bigint AS negative_failures,
        count(*) FILTER
        (
            WHERE evidence_code LIKE 'M2_5_%'
              AND status = 'FAIL'
        )::bigint AS failed_evidence_rows
    FROM msbf_ctl.run_evidence
    WHERE run_id = (SELECT run_id FROM run_context)
),
physical AS
(
    SELECT
        (SELECT count(*) FROM msbf_ctl.m2_5_policy_profile
         WHERE module1_run_id=(SELECT run_id FROM run_context))::bigint
            AS policy_rows,
        (SELECT count(*) FROM msbf_m2.portfolio_monitoring_status_definition
         WHERE module1_run_id=(SELECT run_id FROM run_context))::bigint
            AS status_rows,
        (SELECT count(*) FROM msbf_m2.portfolio_monitoring_alert_definition
         WHERE module1_run_id=(SELECT run_id FROM run_context))::bigint
            AS alert_rows,
        (SELECT count(*) FROM msbf_m2.portfolio_monitoring_reason_definition
         WHERE module1_run_id=(SELECT run_id FROM run_context))::bigint
            AS reason_rows,
        (SELECT count(*) FROM msbf_m2.advance_monitoring_source_snapshot
         WHERE module1_run_id=(SELECT run_id FROM run_context))::bigint
            AS source_rows,
        (SELECT count(*) FROM msbf_m2.advance_daily_remittance_monitoring
         WHERE module1_run_id=(SELECT run_id FROM run_context))::bigint
            AS daily_rows,
        (SELECT count(*) FROM msbf_m2.advance_portfolio_monitoring_latest
         WHERE module1_run_id=(SELECT run_id FROM run_context))::bigint
            AS latest_rows,
        (SELECT count(*) FROM msbf_m2.advance_portfolio_monitoring_archive
         WHERE module1_run_id=(SELECT run_id FROM run_context))::bigint
            AS archive_rows,
        (SELECT count(*) FROM msbf_m2.portfolio_daily_monitoring_summary
         WHERE module1_run_id=(SELECT run_id FROM run_context))::bigint
            AS portfolio_daily_rows,
        (SELECT count(*) FROM msbf_m2.v_m2_5_matched_monitoring_comparison
         WHERE module1_run_id=(SELECT run_id FROM run_context))::bigint
            AS comparison_rows,
        (SELECT count(*) FROM msbf_m2.advance_portfolio_monitoring_latest
         WHERE module1_run_id=(SELECT run_id FROM run_context)
           AND paid_off_flag)::bigint AS paid_off_rows,
        (SELECT count(*) FROM msbf_m2.advance_portfolio_monitoring_latest
         WHERE module1_run_id=(SELECT run_id FROM run_context)
           AND NOT paid_off_flag)::bigint AS open_monitoring_rows,
        (SELECT count(*) FROM msbf_m2.advance_daily_remittance_monitoring
         WHERE module1_run_id=(SELECT run_id FROM run_context)
           AND stress_status_floor_applied_flag)::bigint
            AS stress_status_floor_rows,
        (SELECT round(sum(cumulative_remittance_amount),2)
         FROM msbf_m2.advance_portfolio_monitoring_latest
         WHERE module1_run_id=(SELECT run_id FROM run_context))
            AS total_remittance_amount,
        (SELECT round(sum(remaining_receivable_amount),2)
         FROM msbf_m2.advance_portfolio_monitoring_latest
         WHERE module1_run_id=(SELECT run_id FROM run_context))
            AS ending_receivable_exposure_amount,
        (SELECT count(*) FROM msbf_m2.v_m2_5_matched_monitoring_comparison
         WHERE module1_run_id=(SELECT run_id FROM run_context)
           AND stress_status_improvement_flag)::bigint
            AS stress_status_improvements,
        (SELECT count(*) FROM msbf_m2.advance_portfolio_monitoring_latest AS latest
         FULL OUTER JOIN msbf_m2.advance_portfolio_monitoring_archive AS archive
           ON archive.module1_run_id=latest.module1_run_id
          AND archive.contract_version=latest.contract_version
          AND archive.scenario_id=latest.scenario_id
          AND archive.merchant_application_id=latest.merchant_application_id
         WHERE coalesce(latest.module1_run_id,archive.module1_run_id)=
               (SELECT run_id FROM run_context)
           AND
           (
               latest.contract_row_hash IS DISTINCT FROM archive.contract_row_hash
               OR archive.contract_payload IS DISTINCT FROM
                  (to_jsonb(latest)-'created_at')
           ))::bigint AS archive_mismatches,
        (SELECT count(*) FROM msbf_m2.portfolio_daily_monitoring_summary AS summary
         JOIN
         (
             SELECT
                 module1_run_id,
                 scenario_id,
                 monitoring_day_index,
                 count(*)::integer AS opening_advance_count,
                 count(*) FILTER
                 (
                     WHERE receivable_balance_before > 0
                 )::integer AS active_advance_count,
                 count(*) FILTER(WHERE paid_off_flag)::integer AS paid_off_count,
                 round(sum(source_eligible_pos_sales),2)::numeric(24,2)
                     AS daily_eligible_pos_sales,
                 round(sum(actual_remittance_amount),2)::numeric(24,2)
                     AS daily_remittance_amount,
                 round(sum(cumulative_remittance_amount),2)::numeric(24,2)
                     AS cumulative_remittance_amount,
                 round(sum(receivable_balance_after),2)::numeric(24,2)
                     AS total_receivable_exposure_amount
             FROM msbf_m2.advance_daily_remittance_monitoring
             WHERE module1_run_id=(SELECT run_id FROM run_context)
             GROUP BY module1_run_id,scenario_id,monitoring_day_index
         ) AS daily
           ON daily.module1_run_id=summary.module1_run_id
          AND daily.scenario_id=summary.scenario_id
          AND daily.monitoring_day_index=summary.monitoring_day_index
         WHERE summary.module1_run_id=(SELECT run_id FROM run_context)
           AND
           (
               summary.opening_advance_count IS DISTINCT FROM daily.opening_advance_count
               OR summary.active_advance_count IS DISTINCT FROM daily.active_advance_count
               OR summary.paid_off_count IS DISTINCT FROM daily.paid_off_count
               OR summary.daily_eligible_pos_sales IS DISTINCT FROM daily.daily_eligible_pos_sales
               OR summary.daily_remittance_amount IS DISTINCT FROM daily.daily_remittance_amount
               OR summary.cumulative_remittance_amount IS DISTINCT FROM daily.cumulative_remittance_amount
               OR summary.total_receivable_exposure_amount IS DISTINCT FROM daily.total_receivable_exposure_amount
           ))::bigint AS portfolio_summary_mismatches,
        (SELECT count(*) FROM msbf_m2.portfolio_monitoring_reason_definition
         WHERE module1_run_id=(SELECT run_id FROM run_context)
           AND
           (
               production_adverse_action_notice_flag
               OR servicing_action_authorized_flag
           ))::bigint AS prohibited_reason_flags,
        (SELECT count(*) FROM information_schema.columns
         WHERE table_schema='msbf_m2'
           AND table_name IN
           (
               'advance_daily_remittance_monitoring',
               'advance_portfolio_monitoring_latest',
               'advance_portfolio_monitoring_archive',
               'portfolio_daily_monitoring_summary'
           )
           AND lower(column_name) IN
           (
               'debit_instruction','real_debit_instruction','ach_trace_number',
               'payment_network_confirmation','bank_account_number','routing_number',
               'account_number','collection_action','servicing_action','write_off',
               'charge_off','restructure_offer','workout_offer',
               'external_notice_payload','production_adverse_action_notice'
           ))::bigint AS prohibited_columns,
        (SELECT count(*) FROM msbf_ctl.acceptance_gate_result
         WHERE run_id=(SELECT run_id FROM run_context)
           AND gate_id='M2_5_DAILY_REMITTANCE_EXPOSURE_PORTFOLIO_MONITORING')::bigint AS existing_gate_rows,
        (SELECT canonical_entities FROM msbf_m2.v_m2_5_canonical_hash
         WHERE module1_run_id=(SELECT run_id FROM run_context))::bigint
            AS physical_canonical_entities,
        (SELECT combined_set_hash FROM msbf_m2.v_m2_5_canonical_hash
         WHERE module1_run_id=(SELECT run_id FROM run_context))
            AS physical_combined_set_hash
)
SELECT
    run_context.run_id,
    run_context.run_status AS prior_run_status,
    registry.contract_status AS prior_contract_status,
    controls.positive_checks,
    controls.positive_passes,
    controls.positive_failures,
    controls.negative_checks,
    controls.negative_passes,
    controls.negative_failures,
    controls.failed_evidence_rows,
    physical.policy_rows,
    physical.status_rows,
    physical.alert_rows,
    physical.reason_rows,
    physical.source_rows,
    physical.daily_rows,
    physical.latest_rows,
    physical.archive_rows,
    physical.portfolio_daily_rows,
    physical.comparison_rows,
    physical.paid_off_rows,
    physical.open_monitoring_rows,
    physical.stress_status_floor_rows,
    physical.total_remittance_amount,
    physical.ending_receivable_exposure_amount,
    physical.stress_status_improvements,
    physical.archive_mismatches,
    physical.portfolio_summary_mismatches,
    physical.prohibited_reason_flags,
    physical.prohibited_columns,
    physical.existing_gate_rows,
    physical.physical_canonical_entities,
    physical.physical_combined_set_hash,
    registry.canonical_entities,
    registry.contract_set_hash,
    registry.combined_set_hash,
    CASE
        WHEN run_context.run_status='M2_5_VALIDATED'
         AND registry.contract_status='VALIDATED'
         AND controls.positive_checks=120
         AND controls.positive_passes=120
         AND controls.positive_failures=0
         AND controls.negative_checks=20
         AND controls.negative_passes=20
         AND controls.negative_failures=0
         AND controls.failed_evidence_rows=0
         AND physical.policy_rows=1
         AND physical.status_rows=6
         AND physical.alert_rows=7
         AND physical.reason_rows=24
         AND physical.source_rows=59
         AND physical.daily_rows=7080
         AND physical.latest_rows=59
         AND physical.archive_rows=59
         AND physical.portfolio_daily_rows=240
         AND physical.comparison_rows=15
         AND physical.paid_off_rows+physical.open_monitoring_rows=59
         AND physical.stress_status_floor_rows=registry.stress_status_floor_rows
         AND physical.total_remittance_amount IS NOT DISTINCT FROM
             registry.total_remittance_amount
         AND physical.ending_receivable_exposure_amount IS NOT DISTINCT FROM
             registry.ending_receivable_exposure_amount
         AND physical.stress_status_improvements=0
         AND physical.archive_mismatches=0
         AND physical.portfolio_summary_mismatches=0
         AND physical.prohibited_reason_flags=0
         AND physical.prohibited_columns=0
         AND physical.existing_gate_rows=0
         AND registry.canonical_entities=7536
         AND physical.physical_canonical_entities=7536
         AND registry.combined_set_hash IS NOT DISTINCT FROM
             physical.physical_combined_set_hash
         AND registry.contract_set_hash IS NOT NULL
         AND registry.combined_set_hash IS NOT NULL
        THEN 'PASS'
        ELSE 'FAIL'
    END AS acceptance_status
FROM run_context
CROSS JOIN registry
CROSS JOIN controls
CROSS JOIN physical;

DO $m2_5_acceptance_guard$
DECLARE
    v_diagnostic json;
    v_run_id bigint;
BEGIN
    SELECT
        row_to_json(acceptance),
        acceptance.run_id
    INTO
        v_diagnostic,
        v_run_id
    FROM _m2_5_acceptance AS acceptance;

    IF v_diagnostic->>'acceptance_status' <> 'PASS' THEN
        RAISE EXCEPTION
            'M2.5 acceptance preconditions failed: %.',
            v_diagnostic;
    END IF;

    PERFORM msbf_ctl.m2_5_assert_acceptance_ready(v_run_id);
END;
$m2_5_acceptance_guard$;

DROP TABLE IF EXISTS _m2_5_acceptance_evidence;

CREATE TEMP TABLE _m2_5_acceptance_evidence
(
    run_id                  bigint NOT NULL,
    evidence_code           text NOT NULL,
    segment_key             text NOT NULL,
    metric_name             text NOT NULL,
    metric_value_numeric    numeric(24,10),
    metric_value_text       text,
    unit_code               text NOT NULL,
    status                  text NOT NULL,
    interpretation          text NOT NULL,
    CHECK
    (
        num_nonnulls(metric_value_numeric,metric_value_text)=1
    )
)
ON COMMIT DROP;

INSERT INTO _m2_5_acceptance_evidence
(
    run_id,evidence_code,segment_key,metric_name,
    metric_value_numeric,metric_value_text,unit_code,status,interpretation
)
SELECT
    acceptance.run_id,
    'M2_5_ACCEPTANCE_SUMMARY',
    'PORTFOLIO',
    'M2_5_DAILY_REMITTANCE_EXPOSURE_MONITORING_ACCEPTANCE',
    NULL::numeric(24,10),
    acceptance.combined_set_hash,
    'ACCEPTANCE',
    'PASS',
    'Formal M2.5 acceptance: daily remittance, exposure, liquidity, monitoring '
    || 'status, alert, latest/archive, portfolio summary, and matched stress '
    || 'evidence accepted with 120 positive controls, 20 negative controls, '
    || 'zero deterministic/archive/portfolio-summary/stress violations, and '
    || 'no real debit, servicing action, external notice, write-off, restructure, '
    || 'or production adverse-action notice.'
FROM _m2_5_acceptance AS acceptance;

UPDATE msbf_ctl.m2_5_portfolio_monitoring_contract_registry
SET
    contract_status='ACCEPTED',
    accepted_at=clock_timestamp()
WHERE module1_run_id=(SELECT run_id FROM _m2_5_acceptance);

UPDATE msbf_ctl.run_registry
SET
    run_status='M2_5_ACCEPTED',
    notes=coalesce(notes,'') ||
        ' | M2.5 daily remittance, exposure and portfolio monitoring accepted.'
WHERE run_id=(SELECT run_id FROM _m2_5_acceptance);

INSERT INTO msbf_ctl.acceptance_gate_result
(
    run_id,gate_id,review_version,result_status,observed_value,
    threshold_value,finding,residual_limitation,reviewer_role
)
SELECT
    acceptance.run_id,
    'M2_5_DAILY_REMITTANCE_EXPOSURE_PORTFOLIO_MONITORING',
    1,
    'PASS',
    acceptance.combined_set_hash,
    '120/120 positive; 20/20 negative; 59 monitored advances; 7,080 daily rows; zero deterministic, stress, archive, portfolio-summary, servicing-action, or notice violations',
    'M2.5 daily remittance, exposure and portfolio monitoring accepted.',
    'M2.5 is monitoring only. It does not initiate debit, collections, servicing action, write-off, restructure, external notice, or production adverse-action notice.',
    'Independent Validation / Project Owner'
FROM _m2_5_acceptance AS acceptance;

INSERT INTO msbf_ctl.run_evidence
(
    run_id,evidence_code,segment_key,metric_name,
    metric_value_numeric,metric_value_text,unit_code,status,interpretation
)
SELECT
    evidence.run_id,evidence.evidence_code,evidence.segment_key,
    evidence.metric_name,evidence.metric_value_numeric,evidence.metric_value_text,
    evidence.unit_code,evidence.status,evidence.interpretation
FROM _m2_5_acceptance_evidence AS evidence;

ALTER TABLE _m2_5_acceptance
    ADD COLUMN final_run_status text,
    ADD COLUMN final_contract_status text,
    ADD COLUMN gate_status text;

UPDATE _m2_5_acceptance AS acceptance
SET
    final_run_status=
    (
        SELECT run_status
        FROM msbf_ctl.run_registry
        WHERE run_id=acceptance.run_id
    ),
    final_contract_status=
    (
        SELECT contract_status
        FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry
        WHERE module1_run_id=acceptance.run_id
    ),
    gate_status=
    (
        SELECT result_status
        FROM msbf_ctl.acceptance_gate_result
        WHERE run_id=acceptance.run_id
          AND gate_id='M2_5_DAILY_REMITTANCE_EXPOSURE_PORTFOLIO_MONITORING'
          AND review_version=1
    );

DO $m2_5_acceptance_final_guard$
DECLARE
    v record;
BEGIN
    SELECT
        acceptance.final_run_status,
        acceptance.final_contract_status,
        acceptance.gate_status
    INTO v
    FROM _m2_5_acceptance AS acceptance;

    IF v.final_run_status <> 'M2_5_ACCEPTED'
       OR v.final_contract_status <> 'ACCEPTED'
       OR v.gate_status <> 'PASS' THEN
        RAISE EXCEPTION
            'M2.5 final acceptance state failed: %.',
            row_to_json(v);
    END IF;
END;
$m2_5_acceptance_final_guard$;

COMMIT;

SELECT
    acceptance.run_id,
    acceptance.prior_run_status,
    acceptance.prior_contract_status,
    acceptance.positive_checks,
    acceptance.positive_passes,
    acceptance.positive_failures,
    acceptance.negative_checks,
    acceptance.negative_passes,
    acceptance.negative_failures,
    acceptance.failed_evidence_rows,
    acceptance.policy_rows,
    acceptance.status_rows,
    acceptance.alert_rows,
    acceptance.reason_rows,
    acceptance.source_rows,
    acceptance.daily_rows,
    acceptance.latest_rows,
    acceptance.archive_rows,
    acceptance.portfolio_daily_rows,
    acceptance.comparison_rows,
    acceptance.paid_off_rows,
    acceptance.open_monitoring_rows,
    acceptance.stress_status_floor_rows,
    acceptance.total_remittance_amount,
    acceptance.ending_receivable_exposure_amount,
    acceptance.stress_status_improvements,
    acceptance.archive_mismatches,
    acceptance.portfolio_summary_mismatches,
    acceptance.prohibited_reason_flags,
    acceptance.prohibited_columns,
    acceptance.existing_gate_rows,
    acceptance.physical_canonical_entities,
    acceptance.canonical_entities,
    acceptance.contract_set_hash,
    acceptance.combined_set_hash,
    acceptance.acceptance_status,
    acceptance.final_run_status,
    acceptance.final_contract_status,
    acceptance.gate_status
FROM _m2_5_acceptance AS acceptance;
