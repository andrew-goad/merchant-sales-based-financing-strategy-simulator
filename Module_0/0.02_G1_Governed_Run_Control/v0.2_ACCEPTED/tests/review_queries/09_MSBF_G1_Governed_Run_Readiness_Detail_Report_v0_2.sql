/**********************************************************************
MSBF G1 Governed Run and Configuration Readiness Detail Report
Version : v0.2
Purpose : Multi-result-set audit evidence after G1 finalization
**********************************************************************/

-- 1. Run identity and latest acceptance result.
SELECT
    r.*,
    p.population_version,
    p.population_status,
    p.deterministic_seed_version,
    p.merchant_count,
    p.history_start_date,
    p.history_end_date,
    g.gate_id,
    g.review_version,
    g.result_status,
    g.observed_value,
    g.threshold_value,
    g.finding,
    g.residual_limitation,
    g.reviewer_role,
    g.reviewed_at
FROM msbf_ctl.run_registry r
LEFT JOIN msbf_m1.population_registry p ON p.population_id=r.population_id
LEFT JOIN LATERAL (
    SELECT *
    FROM msbf_ctl.acceptance_gate_result x
    WHERE x.run_id=r.run_id AND x.gate_id='G1_CONTROL_PLANE'
    ORDER BY x.review_version DESC
    LIMIT 1
) g ON true
WHERE r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1;

-- 2. Positive and negative validation evidence.
SELECT
    evidence_code,
    metric_name,
    status,
    metric_value_text,
    interpretation,
    created_at
FROM msbf_ctl.run_evidence
WHERE run_id=(SELECT run_id FROM msbf_ctl.run_registry
              WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1)
  AND evidence_code LIKE 'G1_%'
ORDER BY evidence_code;

-- 3. Frozen profile inventory.
SELECT
    profile_domain,
    profile_code,
    profile_version,
    resolved_profile_id,
    profile_hash,
    snapshot_payload,
    created_at
FROM msbf_ctl.run_profile_snapshot
WHERE run_id=(SELECT run_id FROM msbf_ctl.run_registry
              WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1)
ORDER BY profile_domain, profile_code;

-- 4. Frozen source contracts.
SELECT
    s.source_code,
    s.source_contract_id,
    c.contract_version,
    c.business_name,
    c.expected_grain,
    c.required_history_days,
    c.freshness_sla_hours,
    c.minimum_completeness_rate,
    c.reconciliation_tolerance_rate,
    s.source_cutoff_timestamp,
    s.source_row_count,
    s.quality_status,
    s.source_hash
FROM msbf_ctl.run_source_snapshot s
JOIN msbf_ctl.source_contract c ON c.source_contract_id=s.source_contract_id
WHERE s.run_id=(SELECT run_id FROM msbf_ctl.run_registry
                WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1)
ORDER BY s.source_code;

-- 5. Parameter snapshot counts by governed scope.
SELECT
    split_part(scope_key,':',1) AS scope_domain,
    COUNT(*) AS scoped_value_count,
    COUNT(DISTINCT parameter_name) AS distinct_parameter_names,
    MIN(resolution_rank) AS minimum_resolution_rank,
    MAX(resolution_rank) AS maximum_resolution_rank
FROM msbf_ctl.run_parameter_snapshot
WHERE run_id=(SELECT run_id FROM msbf_ctl.run_registry
              WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1)
GROUP BY split_part(scope_key,':',1)
ORDER BY scope_domain;

-- 6. The four G1-added merchant-size funding/sales centers.
SELECT
    parameter_name,
    scope_key,
    resolved_value,
    source_parameter_value_id,
    snapshot_hash
FROM msbf_ctl.run_parameter_snapshot
WHERE run_id=(SELECT run_id FROM msbf_ctl.run_registry
              WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1)
  AND parameter_name='funding_to_annualized_sales_center'
ORDER BY scope_key;

-- 7. Any resolution errors. Expected: zero rows.
SELECT *
FROM msbf_ctl.profile_resolution_error
WHERE run_id=(SELECT run_id FROM msbf_ctl.run_registry
              WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1)
ORDER BY severity, profile_domain, scope_key, error_code;
