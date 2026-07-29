/* ============================================================================
MSBF M1.11 Cash-Flow Archetypes & Operating Resilience — Master Report
Version : v0.2R2
Purpose : Produce one executive control record summarizing the accepted M1.11
          population, validation evidence, stress migration, canonical hashes,
          policy settings, stage boundaries, and overall acceptance status.
Mode    : Read-only. No persistent data is created or modified.
Output  : One row. overall_m1_11_status must equal PASS.
============================================================================ */

/* ---------------------------------------------------------------------------
1. Governed run context
--------------------------------------------------------------------------- */
WITH r AS (
    SELECT
        run_id,
        run_status,
        population_id,
        as_of_date
    FROM msbf_ctl.run_registry
    WHERE run_code = 'M1_V0_2_BASELINE_BUILD'
      AND run_version = 1
),

/* ---------------------------------------------------------------------------
2. Latest M1.11 acceptance-gate result
--------------------------------------------------------------------------- */
gate AS (
    SELECT *
    FROM msbf_ctl.acceptance_gate_result
    WHERE run_id = (SELECT run_id FROM r)
      AND gate_id = 'M1_11_CASHFLOW_ARCHETYPE_RESILIENCE'
    ORDER BY review_version DESC
    LIMIT 1
),

/* ---------------------------------------------------------------------------
3. Persisted validation counts and governed set hashes
--------------------------------------------------------------------------- */
e AS (
    SELECT
        max(metric_value_text)
            FILTER (WHERE evidence_code = 'M1_11_SNAPSHOT_SET_HASH')
            snapshot_hash,
        max(metric_value_text)
            FILTER (WHERE evidence_code = 'M1_11_COMPONENT_SET_HASH')
            component_hash,
        max(metric_value_text)
            FILTER (WHERE evidence_code = 'M1_11_COMBINED_SET_HASH')
            combined_hash,
        count(*)
            FILTER (WHERE evidence_code LIKE 'M1_11_POS_%')
            positive_checks,
        count(*)
            FILTER (
                WHERE evidence_code LIKE 'M1_11_POS_%'
                  AND status = 'PASS'
            )
            positive_passes,
        count(*)
            FILTER (WHERE evidence_code LIKE 'M1_11_NEG_%')
            negative_controls,
        count(*)
            FILTER (
                WHERE evidence_code LIKE 'M1_11_NEG_%'
                  AND status = 'PASS'
            )
            negative_passes,
        count(*)
            FILTER (
                WHERE evidence_code LIKE 'M1_11_%'
                  AND status = 'FAIL'
            )
            failed_evidence
    FROM msbf_ctl.run_evidence
    WHERE run_id = (SELECT run_id FROM r)
),

/* ---------------------------------------------------------------------------
4. Scenario-aware resilience population and status distribution
--------------------------------------------------------------------------- */
s AS (
    SELECT
        count(*) snapshot_rows,
        count(DISTINCT merchant_application_id) applications,
        count(DISTINCT scenario_id) scenarios,
        count(DISTINCT archetype_code) archetypes,
        count(*)
            FILTER (WHERE manual_review_recommended_flag)
            manual_review_rows,
        round(avg(operating_resilience_score), 6)
            avg_resilience_score,
        count(*)
            FILTER (WHERE resilience_status = 'RESILIENT')
            resilient_rows,
        count(*)
            FILTER (WHERE resilience_status = 'ADEQUATE')
            adequate_rows,
        count(*)
            FILTER (WHERE resilience_status = 'WATCH')
            watch_rows,
        count(*)
            FILTER (WHERE resilience_status = 'VULNERABLE')
            vulnerable_rows,
        count(*)
            FILTER (WHERE resilience_status = 'FRAGILE')
            fragile_rows,
        count(*)
            FILTER (WHERE resilience_status = 'INSUFFICIENT_EVIDENCE')
            insufficient_rows
    FROM msbf_m1.application_operating_resilience_snapshot
    WHERE module1_run_id = (SELECT run_id FROM r)
),

/* ---------------------------------------------------------------------------
5. Long-form component population and availability
--------------------------------------------------------------------------- */
c AS (
    SELECT
        count(*) component_rows,
        count(*)
            FILTER (WHERE component_status = 'AVAILABLE')
            available_components,
        count(*)
            FILTER (WHERE component_status = 'NOT_AVAILABLE')
            unavailable_components
    FROM msbf_m1.operating_resilience_component_value
    WHERE module1_run_id = (SELECT run_id FROM r)
),

/* ---------------------------------------------------------------------------
6. Matched adverse-scenario migration
--------------------------------------------------------------------------- */
stress AS (
    SELECT
        count(*)
            FILTER (
                WHERE sr.scenario_code = 'RECESSION_ENERGY'
                  AND resilience_tier > baseline_resilience_tier
            )
            tier_worsenings,
        count(*)
            FILTER (
                WHERE sr.scenario_code = 'RECESSION_ENERGY'
                  AND resilience_tier < baseline_resilience_tier
            )
            tier_improvements,
        count(*)
            FILTER (
                WHERE sr.scenario_code = 'RECESSION_ENERGY'
                  AND stress_archetype_worsening_flag
            )
            archetype_worsenings,
        count(*)
            FILTER (
                WHERE sr.scenario_code = 'RECESSION_ENERGY'
                  AND archetype_risk_rank <
                      CASE baseline_archetype_code
                          WHEN 'GROWING' THEN 1
                          WHEN 'STABLE' THEN 1
                          WHEN 'SEASONAL' THEN 2
                          WHEN 'VOLATILE' THEN 3
                          WHEN 'DECLINING' THEN 4
                          WHEN 'DISRUPTED' THEN 4
                          ELSE 5
                      END
            )
            archetype_improvements
    FROM msbf_m1.application_operating_resilience_snapshot x
    JOIN msbf_ctl.scenario_registry sr USING (scenario_id)
    WHERE x.module1_run_id = (SELECT run_id FROM r)
),

/* ---------------------------------------------------------------------------
7. Visible wide/long composite-score identity
   BLOCKED snapshots intentionally retain a null wide composite.
--------------------------------------------------------------------------- */
composite AS (
    SELECT count(*) identity_violations
    FROM msbf_m1.application_operating_resilience_snapshot s
    JOIN (
        SELECT
            module1_run_id,
            scenario_id,
            merchant_application_id,
            round(sum(weighted_score), 6)::numeric(9,6) score,
            count(weighted_score) n
        FROM msbf_m1.operating_resilience_component_value
        WHERE module1_run_id = (SELECT run_id FROM r)
        GROUP BY 1, 2, 3
    ) c USING (
        module1_run_id,
        scenario_id,
        merchant_application_id
    )
    WHERE s.module1_run_id = (SELECT run_id FROM r)
      AND s.operating_resilience_score IS DISTINCT FROM
          CASE
              WHEN s.operating_resilience_evidence_status = 'BLOCKED'
                OR c.n <> 5
              THEN NULL
              ELSE c.score
          END
),

/* ---------------------------------------------------------------------------
8. Independent row-hash reconstruction
--------------------------------------------------------------------------- */
mismatch AS (
    SELECT count(*) mismatches
    FROM (
        SELECT
            'RESILIENCE|' || scenario_id || '|' || merchant_application_id
                entity_key,
            row_hash
        FROM msbf_m1.application_operating_resilience_snapshot
        WHERE module1_run_id = (SELECT run_id FROM r)

        UNION ALL

        SELECT
            'COMPONENT|' || scenario_id || '|' || merchant_application_id
                || '|' || component_code || '|' || component_version,
            calculation_hash
        FROM msbf_m1.operating_resilience_component_value
        WHERE module1_run_id = (SELECT run_id FROM r)
    ) st
    FULL JOIN (
        SELECT *
        FROM msbf_m1.m1_11_actual_resilience((SELECT run_id FROM r))

        UNION ALL

        SELECT *
        FROM msbf_m1.m1_11_actual_component((SELECT run_id FROM r))
    ) ac USING (entity_key)
    WHERE st.row_hash IS DISTINCT FROM ac.row_hash
),

/* ---------------------------------------------------------------------------
9. Downstream stage-boundary and blocking-configuration checks
--------------------------------------------------------------------------- */
b AS (
    SELECT
        (SELECT count(*)
         FROM msbf_m1.merchant_risk_snapshot
         WHERE module1_run_id = (SELECT run_id FROM r))
        +
        (SELECT count(*)
         FROM msbf_m1.ead_path_snapshot
         WHERE module1_run_id = (SELECT run_id FROM r))
        +
        (SELECT count(*)
         FROM msbf_m1.module1_latest
         WHERE module1_run_id = (SELECT run_id FROM r))
        +
        (SELECT count(*)
         FROM msbf_m1.module1_archive
         WHERE module1_run_id = (SELECT run_id FROM r))
            downstream_rows,
        (SELECT count(*)
         FROM msbf_ctl.profile_resolution_error
         WHERE run_id = (SELECT run_id FROM r)
           AND severity = 'BLOCKING')
            blocking_errors
),

/* ---------------------------------------------------------------------------
10. Accepted methodology and stress-floor policy
--------------------------------------------------------------------------- */
p AS (
    SELECT
        profile_payload ->> 'methodology_version'
            methodology_version,
        profile_payload ->> 'composite_score_basis'
            composite_score_basis,
        (profile_payload ->> 'stress_resilience_tier_floor_to_baseline')::boolean
            tier_floor_enabled,
        (profile_payload ->> 'stress_archetype_rank_floor_to_baseline')::boolean
            archetype_floor_enabled
    FROM msbf_ctl.policy_profile
    WHERE profile_code = 'M1_11_CASHFLOW_ARCHETYPE_RESILIENCE'
      AND profile_version = 1
      AND status = 'APPROVED'
)

/* ---------------------------------------------------------------------------
11. One-row executive acceptance report
--------------------------------------------------------------------------- */
SELECT
    current_database() database_name,
    current_user database_user,
    current_setting('server_version') postgresql_version,
    clock_timestamp() report_timestamp,
    r.*,
    gate.gate_id,
    gate.review_version,
    gate.result_status gate_status,
    s.*,
    c.*,
    stress.*,
    e.positive_checks,
    e.positive_passes,
    e.negative_controls,
    e.negative_passes,
    e.failed_evidence,
    composite.identity_violations AS composite_identity_violations,
    mismatch.mismatches,
    b.downstream_rows,
    b.blocking_errors,
    p.*,
    e.snapshot_hash,
    e.component_hash,
    e.combined_hash,
    CASE
        WHEN r.run_status = 'M1_11_ACCEPTED'
         AND gate.result_status = 'PASS'
         AND s.snapshot_rows = 1500
         AND c.component_rows = 7500
         AND s.applications = 750
         AND s.scenarios = 2
         AND e.positive_checks = 72
         AND e.positive_passes = 72
         AND e.negative_controls = 6
         AND e.negative_passes = 6
         AND e.failed_evidence = 0
         AND mismatch.mismatches = 0
         AND stress.tier_improvements = 0
         AND stress.archetype_improvements = 0
         AND b.downstream_rows = 0
         AND b.blocking_errors = 0
         AND composite.identity_violations = 0
         AND p.methodology_version = 'M1_11_METHOD_V1_1'
         AND p.composite_score_basis = 'SUM_PERSISTED_WEIGHTED_COMPONENTS'
         AND p.tier_floor_enabled
         AND p.archetype_floor_enabled
        THEN 'PASS'
        ELSE 'FAIL'
    END overall_m1_11_status
FROM r
CROSS JOIN gate
CROSS JOIN e
CROSS JOIN s
CROSS JOIN c
CROSS JOIN stress
CROSS JOIN composite
CROSS JOIN mismatch
CROSS JOIN b
CROSS JOIN p;
