/* ============================================================================
MSBF M1.7 Source Quality & Data Confidence — Master Report
Version : v0.2
Purpose : Produce the one-row executive and acceptance reconciliation result.
============================================================================ */
WITH ctx AS (
    SELECT
        run_id,
        run_status,
        population_id,
        as_of_date,
        parameter_snapshot_hash,
        profile_snapshot_hash,
        source_snapshot_hash
    FROM msbf_ctl.run_registry
    WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
),
penalties AS (
    SELECT
        max((resolved_value->>'value_numeric')::numeric)
            FILTER (WHERE parameter_name='missing_pos_source_confidence_penalty'
                    AND scope_key='GLOBAL') AS missing_pos_penalty,
        max((resolved_value->>'value_numeric')::numeric)
            FILTER (WHERE parameter_name='missing_deposit_source_confidence_penalty'
                    AND scope_key='GLOBAL') AS missing_deposit_penalty,
        max((resolved_value->>'value_numeric')::numeric)
            FILTER (WHERE parameter_name='source_conflict_manual_review_threshold'
                    AND scope_key='GLOBAL')::integer AS conflict_threshold
    FROM msbf_ctl.run_parameter_snapshot
    WHERE run_id=(SELECT run_id FROM ctx)
),
source_summary AS (
    SELECT
        count(*) AS source_rows,
        count(DISTINCT merchant_application_id) AS applications,
        count(DISTINCT source_code) AS source_families,
        count(*) FILTER (WHERE availability_status='AVAILABLE') AS available_rows,
        count(*) FILTER (WHERE availability_status='PARTIAL') AS partial_rows,
        count(*) FILTER (WHERE availability_status='UNAVAILABLE') AS unavailable_rows,
        count(*) FILTER (WHERE quality_status='PASS') AS pass_rows,
        count(*) FILTER (WHERE quality_status='WARNING') AS warning_rows,
        count(*) FILTER (WHERE quality_status='FAIL') AS fail_rows,
        count(*) FILTER (WHERE quality_status='CONFLICT') AS conflict_rows,
        count(*) FILTER (WHERE fallback_path_code<>'NONE') AS fallback_rows,
        round(avg(data_confidence_score),6) AS average_source_confidence
    FROM msbf_m1.source_snapshot
    WHERE module1_run_id=(SELECT run_id FROM ctx)
),
application_scores AS (
    SELECT
        merchant_application_id,
        greatest(
            0,
            least(
                1,
                sum(
                    data_confidence_score
                    * CASE source_code
                        WHEN 'POS_DAILY' THEN 0.35
                        WHEN 'DEPOSIT_DAILY' THEN 0.20
                        WHEN 'VERIFICATION' THEN 0.15
                        WHEN 'BUSINESS_CREDIT' THEN 0.10
                        WHEN 'OWNER_CREDIT' THEN 0.08
                        WHEN 'OBLIGATIONS' THEN 0.07
                        WHEN 'COLLATERAL_AVAILABILITY' THEN 0.05
                      END
                )
                - coalesce(
                    max((SELECT missing_pos_penalty FROM penalties))
                        FILTER (WHERE source_code='POS_DAILY'
                                AND availability_status='UNAVAILABLE'),
                    0
                  )
                - coalesce(
                    max((SELECT missing_deposit_penalty FROM penalties))
                        FILTER (WHERE source_code='DEPOSIT_DAILY'
                                AND availability_status='UNAVAILABLE'),
                    0
                  )
            )
        )::numeric AS application_confidence_score,
        count(*) FILTER (WHERE quality_status='CONFLICT') AS conflict_count,
        bool_or(source_code='POS_DAILY' AND availability_status='UNAVAILABLE') AS pos_fail_closed,
        bool_or(source_code='VERIFICATION' AND availability_status='UNAVAILABLE') AS verification_fail_closed
    FROM msbf_m1.source_snapshot
    WHERE module1_run_id=(SELECT run_id FROM ctx)
    GROUP BY merchant_application_id
),
application_summary AS (
    SELECT
        round(avg(application_confidence_score),6) AS average_application_confidence,
        count(*) FILTER (WHERE application_confidence_score>=0.90) AS high_confidence_applications,
        count(*) FILTER (WHERE application_confidence_score>=0.75
                          AND application_confidence_score<0.90) AS medium_confidence_applications,
        count(*) FILTER (WHERE application_confidence_score>=0.60
                          AND application_confidence_score<0.75) AS low_confidence_applications,
        count(*) FILTER (WHERE application_confidence_score<0.60) AS review_confidence_applications,
        count(*) FILTER (
            WHERE conflict_count>=(SELECT conflict_threshold FROM penalties)
        ) AS source_conflict_review_applications,
        count(*) FILTER (WHERE pos_fail_closed) AS pos_fail_closed_applications,
        count(*) FILTER (WHERE verification_fail_closed) AS verification_fail_closed_applications
    FROM application_scores
),
positive AS (
    SELECT
        count(*) AS positive_checks,
        count(*) FILTER (WHERE status='PASS') AS positive_passes
    FROM msbf_ctl.run_evidence
    WHERE run_id=(SELECT run_id FROM ctx)
      AND evidence_code~'^M1_7_POS_[0-9]{2}_'
),
negative AS (
    SELECT
        count(*) AS negative_controls,
        count(*) FILTER (WHERE status='PASS') AS negative_passes
    FROM msbf_ctl.run_evidence
    WHERE run_id=(SELECT run_id FROM ctx)
      AND evidence_code LIKE 'M1_7_NEG_%'
),
gate AS (
    SELECT result_status, review_version, reviewed_at, finding
    FROM msbf_ctl.acceptance_gate_result
    WHERE run_id=(SELECT run_id FROM ctx)
      AND gate_id='M1_7_SOURCE_QUALITY_CONFIDENCE'
    ORDER BY review_version DESC
    LIMIT 1
),
errors AS (
    SELECT count(*) AS blocking_errors
    FROM msbf_ctl.profile_resolution_error
    WHERE run_id=(SELECT run_id FROM ctx)
      AND severity='BLOCKING'
),
hashes AS (
    SELECT
        max(metric_value_text) FILTER (
            WHERE evidence_code='M1_7_SOURCE_SET_HASH'
        ) AS source_set_hash,
        max(metric_value_text) FILTER (
            WHERE evidence_code='M1_7_GENERATION_CANONICAL_RECON'
        ) AS canonical_reconciliation
    FROM msbf_ctl.run_evidence
    WHERE run_id=(SELECT run_id FROM ctx)
      AND evidence_code IN (
          'M1_7_SOURCE_SET_HASH',
          'M1_7_GENERATION_CANONICAL_RECON'
      )
)
SELECT
    c.*,
    s.*,
    a.*,
    p.positive_checks,
    p.positive_passes,
    n.negative_controls,
    n.negative_passes,
    g.result_status AS m1_7_gate_status,
    g.review_version,
    g.reviewed_at,
    g.finding,
    e.blocking_errors,
    h.source_set_hash,
    h.canonical_reconciliation,
    CASE
        WHEN c.run_status='M1_7_ACCEPTED'
         AND g.result_status='PASS'
         AND s.source_rows=5250
         AND s.applications=750
         AND s.source_families=7
         AND p.positive_checks=55
         AND p.positive_passes=55
         AND n.negative_controls=5
         AND n.negative_passes=5
         AND e.blocking_errors=0
         AND h.source_set_hash IS NOT NULL
         AND h.canonical_reconciliation='expected=5250 actual=5250 mismatches=0'
        THEN 'PASS'
        ELSE 'FAIL'
    END AS overall_m1_7_status
FROM ctx c
CROSS JOIN source_summary s
CROSS JOIN application_summary a
CROSS JOIN positive p
CROSS JOIN negative n
CROSS JOIN gate g
CROSS JOIN errors e
CROSS JOIN hashes h;
