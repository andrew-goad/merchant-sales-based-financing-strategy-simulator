/* ============================================================================
MSBF M1.11 Cash-Flow Archetypes & Operating Resilience — Detailed Evidence Report
Version : v0.2R2
Purpose : Produce the 19 governed evidence result sets supporting final M1.11
          review, including population coverage, archetype migration, component
          diagnostics, deterministic reconciliation, and stage-boundary checks.
Mode    : Read-only. Session-scoped temporary tables survive COMMIT so result
          sets remain sortable and filterable in the current DBeaver session.
Expected: Result Set 17 and Result Set 19 retain headers and contain zero rows.
============================================================================ */

BEGIN;

SET LOCAL work_mem = '64MB';
SET LOCAL jit = off;

/* ---------------------------------------------------------------------------
A. Session-scoped reporting tables
--------------------------------------------------------------------------- */
DROP TABLE IF EXISTS _m1_11_detail_snap;
DROP TABLE IF EXISTS _m1_11_detail_comp;
DROP TABLE IF EXISTS _m1_11_detail_mismatch;

CREATE TEMP TABLE _m1_11_detail_snap
ON COMMIT PRESERVE ROWS AS
SELECT
    s.*,
    sr.scenario_code
FROM msbf_m1.application_operating_resilience_snapshot s
JOIN msbf_ctl.scenario_registry sr USING (scenario_id)
WHERE s.module1_run_id = (
    SELECT run_id
    FROM msbf_ctl.run_registry
    WHERE run_code = 'M1_V0_2_BASELINE_BUILD'
      AND run_version = 1
);

CREATE TEMP TABLE _m1_11_detail_comp
ON COMMIT PRESERVE ROWS AS
SELECT
    c.*,
    sr.scenario_code
FROM msbf_m1.operating_resilience_component_value c
JOIN msbf_ctl.scenario_registry sr USING (scenario_id)
WHERE c.module1_run_id = (
    SELECT run_id
    FROM msbf_ctl.run_registry
    WHERE run_code = 'M1_V0_2_BASELINE_BUILD'
      AND run_version = 1
);

CREATE TEMP TABLE _m1_11_detail_mismatch
ON COMMIT PRESERVE ROWS AS
SELECT
    'RESILIENCE|' || scenario_id || '|' || merchant_application_id entity_key,
    row_hash stored_hash,
    msbf_m1.m1_11_hash_jsonb(
        to_jsonb(s) - 'row_hash' - 'created_at'
    ) recomputed_hash
FROM msbf_m1.application_operating_resilience_snapshot s
WHERE module1_run_id = (
    SELECT run_id
    FROM msbf_ctl.run_registry
    WHERE run_code = 'M1_V0_2_BASELINE_BUILD'
      AND run_version = 1
)
  AND row_hash IS DISTINCT FROM
      msbf_m1.m1_11_hash_jsonb(
          to_jsonb(s) - 'row_hash' - 'created_at'
      )

UNION ALL

SELECT
    'COMPONENT|' || scenario_id || '|' || merchant_application_id
        || '|' || component_code || '|' || component_version,
    calculation_hash,
    msbf_m1.m1_11_hash_jsonb(
        to_jsonb(c) - 'calculation_hash' - 'created_at'
    )
FROM msbf_m1.operating_resilience_component_value c
WHERE module1_run_id = (
    SELECT run_id
    FROM msbf_ctl.run_registry
    WHERE run_code = 'M1_V0_2_BASELINE_BUILD'
      AND run_version = 1
)
  AND calculation_hash IS DISTINCT FROM
      msbf_m1.m1_11_hash_jsonb(
          to_jsonb(c) - 'calculation_hash' - 'created_at'
      );

/* ===========================================================================
RESULT SET 01 — Run and Acceptance State
=========================================================================== */
SELECT
    r.run_id,
    r.run_status,
    r.population_id,
    r.as_of_date,
    g.gate_id,
    g.review_version,
    g.result_status gate_status,
    g.reviewed_at
FROM msbf_ctl.run_registry r
LEFT JOIN LATERAL (
    SELECT *
    FROM msbf_ctl.acceptance_gate_result a
    WHERE a.run_id = r.run_id
      AND a.gate_id = 'M1_11_CASHFLOW_ARCHETYPE_RESILIENCE'
    ORDER BY review_version DESC
    LIMIT 1
) g ON true
WHERE r.run_code = 'M1_V0_2_BASELINE_BUILD'
  AND r.run_version = 1;

/* ===========================================================================
RESULT SET 02 — Entity and Stage-Boundary Row Counts
=========================================================================== */
SELECT
    (SELECT count(*) FROM _m1_11_detail_snap) snapshot_rows,
    (SELECT count(*) FROM _m1_11_detail_comp) component_rows,
    (SELECT count(DISTINCT merchant_application_id)
     FROM _m1_11_detail_snap) applications,
    (SELECT count(DISTINCT scenario_id)
     FROM _m1_11_detail_snap) scenarios,
    (
        SELECT count(*)
        FROM _m1_11_detail_snap s
        JOIN (
            SELECT
                module1_run_id,
                scenario_id,
                merchant_application_id,
                round(sum(weighted_score), 6)::numeric(9,6) score,
                count(weighted_score) n
            FROM _m1_11_detail_comp
            GROUP BY 1, 2, 3
        ) c USING (
            module1_run_id,
            scenario_id,
            merchant_application_id
        )
        WHERE s.operating_resilience_score IS DISTINCT FROM
              CASE
                  WHEN s.operating_resilience_evidence_status = 'BLOCKED'
                    OR c.n <> 5
                  THEN NULL
                  ELSE c.score
              END
    ) composite_identity_violations,
    (
        SELECT count(*)
        FROM msbf_m1.merchant_risk_snapshot
        WHERE module1_run_id = (
            SELECT min(module1_run_id)
            FROM _m1_11_detail_snap
        )
    ) risk_rows,
    (
        SELECT count(*)
        FROM msbf_m1.ead_path_snapshot
        WHERE module1_run_id = (
            SELECT min(module1_run_id)
            FROM _m1_11_detail_snap
        )
    ) ead_rows,
    (
        SELECT count(*)
        FROM msbf_m1.module1_latest
        WHERE module1_run_id = (
            SELECT min(module1_run_id)
            FROM _m1_11_detail_snap
        )
    ) latest_rows,
    (
        SELECT count(*)
        FROM msbf_m1.module1_archive
        WHERE module1_run_id = (
            SELECT min(module1_run_id)
            FROM _m1_11_detail_snap
        )
    ) archive_rows;

/* ===========================================================================
RESULT SET 03 — Archetype Distribution
=========================================================================== */
SELECT
    scenario_code,
    archetype_code,
    archetype_risk_rank,
    count(*) applications,
    round(avg(operating_resilience_score), 4) avg_resilience_score,
    count(*) FILTER (WHERE manual_review_recommended_flag) manual_review_rows
FROM _m1_11_detail_snap
GROUP BY 1, 2, 3
ORDER BY 1, 3, 2;

/* ===========================================================================
RESULT SET 04 — Matched Archetype Migration
=========================================================================== */
SELECT
    baseline_archetype_code,
    archetype_code,
    count(*) applications,
    count(*) FILTER (WHERE stress_archetype_worsening_flag) worsened
FROM _m1_11_detail_snap
WHERE scenario_code = 'RECESSION_ENERGY'
GROUP BY 1, 2
ORDER BY 1, 2;

/* ===========================================================================
RESULT SET 05 — Resilience Tier and Status
=========================================================================== */
SELECT
    scenario_code,
    resilience_tier,
    resilience_status,
    count(*) applications,
    round(avg(operating_resilience_score), 4) avg_score,
    count(*) FILTER (WHERE manual_review_recommended_flag) review_rows
FROM _m1_11_detail_snap
GROUP BY 1, 2, 3
ORDER BY 1, 2;

/* ===========================================================================
RESULT SET 06 — Component Score Summary
=========================================================================== */
SELECT
    scenario_code,
    component_code,
    component_status,
    count(*) rows,
    round(avg(component_score), 4) avg_score,
    round(min(component_score), 4) min_score,
    round(max(component_score), 4) max_score
FROM _m1_11_detail_comp
GROUP BY 1, 2, 3
ORDER BY 1, 2, 3;

/* ===========================================================================
RESULT SET 07 — Revenue Diagnostics
=========================================================================== */
SELECT
    scenario_code,
    archetype_code,
    count(*) applications,
    round(avg(avg_daily_eligible_sales_30d), 2) avg_sales,
    round(avg(sales_growth_30d_vs_90d), 6) avg_growth,
    round(avg(daily_sales_cv_90d), 6) avg_cv,
    round(avg(zero_sales_day_rate_30d), 6) avg_zero_rate,
    round(avg(revenue_resilience_score), 4) avg_revenue_score
FROM _m1_11_detail_snap
GROUP BY 1, 2
ORDER BY 1, 2;

/* ===========================================================================
RESULT SET 08 — Liquidity Diagnostics
=========================================================================== */
SELECT
    scenario_code,
    resilience_tier,
    count(*) applications,
    round(avg(negative_balance_day_rate_30d), 6) avg_negative_rate,
    round(avg(nsf_count_30d), 4) avg_nsf,
    round(avg(cash_flow_buffer_days), 4) avg_cash_buffer,
    round(avg(post_financing_buffer_days), 4) avg_post_buffer,
    round(avg(liquidity_resilience_score), 4) avg_liquidity_score
FROM _m1_11_detail_snap
GROUP BY 1, 2
ORDER BY 1, 2;

/* ===========================================================================
RESULT SET 09 — Burden Diagnostics
=========================================================================== */
SELECT
    scenario_code,
    resilience_tier,
    count(*) applications,
    round(avg(sales_linked_payment_coverage_ratio), 6) avg_coverage,
    round(avg(total_obligation_to_sales_rate), 6) avg_burden,
    round(avg(residual_daily_operating_cash_flow), 2) avg_residual,
    round(avg(stacking_depth), 4) avg_stacking,
    round(avg(burden_resilience_score), 4) avg_burden_score
FROM _m1_11_detail_snap
GROUP BY 1, 2
ORDER BY 1, 2;

/* ===========================================================================
RESULT SET 10 — Processor Continuity Diagnostics
=========================================================================== */
SELECT
    scenario_code,
    processor_continuity_risk_tier,
    count(*) applications,
    round(avg(processor_outage_day_rate_30d), 6) avg_outage,
    round(avg(processor_degraded_day_rate_30d), 6) avg_degraded,
    round(avg(continuity_resilience_score), 4) avg_continuity_score
FROM _m1_11_detail_snap
GROUP BY 1, 2
ORDER BY 1, 2;

/* ===========================================================================
RESULT SET 11 — Data Confidence Diagnostics
=========================================================================== */
SELECT
    scenario_code,
    data_confidence_tier,
    feature_completeness_status,
    operating_resilience_evidence_status,
    count(*) applications,
    round(avg(source_confidence_score), 6) avg_source_confidence,
    round(avg(data_confidence_resilience_score), 4) avg_data_score
FROM _m1_11_detail_snap
GROUP BY 1, 2, 3, 4
ORDER BY 1, 2, 3, 4;

/* ===========================================================================
RESULT SET 12 — Industry Diagnostics
=========================================================================== */
SELECT
    scenario_code,
    industry_code,
    archetype_code,
    count(*) applications,
    round(avg(operating_resilience_score), 4) avg_score,
    round(avg(resilience_tier), 4) avg_tier
FROM _m1_11_detail_snap
GROUP BY 1, 2, 3
ORDER BY 1, 2, 3;

/* ===========================================================================
RESULT SET 13 — Merchant Size Diagnostics
=========================================================================== */
SELECT
    scenario_code,
    merchant_size_tier,
    archetype_code,
    count(*) applications,
    round(avg(operating_resilience_score), 4) avg_score,
    count(*) FILTER (WHERE manual_review_recommended_flag) review_rows
FROM _m1_11_detail_snap
GROUP BY 1, 2, 3
ORDER BY 1, 2, 3;

/* ===========================================================================
RESULT SET 14 — Relationship Stage Diagnostics
=========================================================================== */
SELECT
    scenario_code,
    relationship_stage,
    archetype_code,
    count(*) applications,
    round(avg(operating_resilience_score), 4) avg_score,
    round(avg(resilience_tier), 4) avg_tier
FROM _m1_11_detail_snap
GROUP BY 1, 2, 3
ORDER BY 1, 2, 3;

/* ===========================================================================
RESULT SET 15 — Fallback and Reason Diagnostics
=========================================================================== */
SELECT
    scenario_code,
    fallback_path_code,
    primary_resilience_reason_code,
    count(*) applications,
    count(*) FILTER (WHERE manual_review_recommended_flag) review_rows
FROM _m1_11_detail_snap
GROUP BY 1, 2, 3
ORDER BY 1, 2, 3;

/* ===========================================================================
RESULT SET 16 — Sample Matched Application Profiles
=========================================================================== */
SELECT
    merchant_application_id,
    scenario_code,
    industry_code,
    merchant_size_tier,
    relationship_stage,
    independent_archetype_code,
    archetype_code,
    operating_resilience_score,
    resilience_tier,
    resilience_status,
    manual_review_recommended_flag,
    fallback_path_code,
    primary_resilience_reason_code
FROM _m1_11_detail_snap
WHERE merchant_application_id IN (
    SELECT merchant_application_id
    FROM _m1_11_detail_snap
    GROUP BY 1
    ORDER BY max(abs(coalesce(sales_growth_30d_vs_90d, 0))) DESC
    LIMIT 12
)
ORDER BY merchant_application_id, scenario_code;

/* ===========================================================================
RESULT SET 17 — Row-Level Deterministic Mismatches
Expected: headers only; zero data rows.
=========================================================================== */
SELECT *
FROM _m1_11_detail_mismatch
ORDER BY entity_key;

/* ===========================================================================
RESULT SET 18 — M1.11 Evidence
=========================================================================== */
SELECT
    evidence_code,
    segment_key,
    metric_name,
    metric_value_numeric,
    metric_value_text,
    unit_code,
    status,
    threshold_value_numeric,
    interpretation,
    created_at
FROM msbf_ctl.run_evidence
WHERE run_id = (
    SELECT min(module1_run_id)
    FROM _m1_11_detail_snap
)
  AND evidence_code LIKE 'M1_11_%'
ORDER BY evidence_code, segment_key;

/* ===========================================================================
RESULT SET 19 — Blocking Resolution Errors
Expected: headers only; zero data rows.
=========================================================================== */
SELECT
    resolution_error_id,
    run_id,
    profile_domain,
    scope_key,
    error_code,
    severity,
    error_message,
    created_at
FROM msbf_ctl.profile_resolution_error
WHERE run_id = (
    SELECT min(module1_run_id)
    FROM _m1_11_detail_snap
)
  AND severity = 'BLOCKING'
ORDER BY resolution_error_id;

COMMIT;
