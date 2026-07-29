/* ============================================================================
MSBF M1.7 Source Quality & Data Confidence — Detail Report
Version : v0.2
Result sets : 15
Empty sets : 13 Row-Level Deterministic Mismatches
             15 Blocking Resolution Errors
Performance : Operates only on the persisted 5,250-row source snapshot.
============================================================================ */
BEGIN;
SET LOCAL work_mem='64MB';
SET LOCAL jit=off;
SET LOCAL statement_timeout='10min';

CREATE TEMP TABLE _m1_7_dctx ON COMMIT DROP AS
SELECT
    r.run_id,
    r.run_status,
    r.population_id,
    r.as_of_date,
    max((s.resolved_value->>'value_numeric')::numeric)
        FILTER (WHERE s.parameter_name='missing_pos_source_confidence_penalty'
                AND s.scope_key='GLOBAL') AS missing_pos_penalty,
    max((s.resolved_value->>'value_numeric')::numeric)
        FILTER (WHERE s.parameter_name='missing_deposit_source_confidence_penalty'
                AND s.scope_key='GLOBAL') AS missing_deposit_penalty,
    (max((s.resolved_value->>'value_numeric')::numeric)
        FILTER (WHERE s.parameter_name='source_conflict_manual_review_threshold'
                AND s.scope_key='GLOBAL'))::integer AS conflict_threshold
FROM msbf_ctl.run_registry r
JOIN msbf_ctl.run_parameter_snapshot s
  ON s.run_id=r.run_id
WHERE r.run_code='M1_V0_2_BASELINE_BUILD'
  AND r.run_version=1
GROUP BY r.run_id,r.run_status,r.population_id,r.as_of_date;

CREATE TEMP TABLE _m1_7_ds ON COMMIT DROP AS
SELECT
    s.*,
    a.merchant_id,
    a.partner_channel_id,
    ia.industry_code,
    rel.relationship_stage,
    sc.required_history_days,
    sc.freshness_sla_hours,
    sc.minimum_completeness_rate,
    sc.reconciliation_tolerance_rate
FROM msbf_m1.source_snapshot s
JOIN msbf_m1.merchant_application a
  ON a.merchant_application_id=s.merchant_application_id
JOIN msbf_m1.merchant_industry_assignment ia
  ON ia.merchant_id=a.merchant_id
 AND ia.assignment_type='PRIMARY'
JOIN msbf_m1.merchant_relationship_snapshot rel
  ON rel.merchant_id=a.merchant_id
 AND rel.as_of_date=a.as_of_date
JOIN msbf_ctl.source_contract sc
  ON sc.source_contract_id=s.source_contract_id
WHERE s.module1_run_id=(SELECT run_id FROM _m1_7_dctx);
CREATE INDEX ON _m1_7_ds(source_code,quality_status);
CREATE UNIQUE INDEX ON _m1_7_ds(merchant_application_id,source_code);

CREATE TEMP TABLE _m1_7_dapp ON COMMIT DROP AS
SELECT
    merchant_application_id,
    merchant_id,
    industry_code,
    partner_channel_id,
    relationship_stage,
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
                max((SELECT missing_pos_penalty FROM _m1_7_dctx))
                    FILTER (WHERE source_code='POS_DAILY'
                            AND availability_status='UNAVAILABLE'),
                0
              )
            - coalesce(
                max((SELECT missing_deposit_penalty FROM _m1_7_dctx))
                    FILTER (WHERE source_code='DEPOSIT_DAILY'
                            AND availability_status='UNAVAILABLE'),
                0
              )
        )
    )::numeric AS application_confidence_score,
    count(*) FILTER (WHERE quality_status='CONFLICT') AS conflict_count,
    count(*) FILTER (WHERE quality_status<>'PASS') AS nonpass_count,
    bool_or(source_code='POS_DAILY' AND availability_status='UNAVAILABLE') AS pos_fail_closed,
    bool_or(source_code='VERIFICATION' AND availability_status='UNAVAILABLE') AS verification_fail_closed,
    bool_or(source_code='DEPOSIT_DAILY' AND availability_status='UNAVAILABLE') AS deposit_pos_only,
    string_agg(
        source_code || ':' || quality_status || ':' || coalesce(fallback_path_code,'<NULL>'),
        ', ' ORDER BY source_code
    ) AS source_profile
FROM _m1_7_ds
GROUP BY
    merchant_application_id,
    merchant_id,
    industry_code,
    partner_channel_id,
    relationship_stage;
CREATE UNIQUE INDEX ON _m1_7_dapp(merchant_application_id);
ANALYZE _m1_7_ds;
ANALYZE _m1_7_dapp;

-- 1. Run and Acceptance State
SELECT
    r.run_id,
    r.run_status,
    r.population_id,
    r.as_of_date,
    a.gate_id,
    a.review_version,
    a.result_status,
    a.finding,
    a.residual_limitation,
    a.reviewed_at
FROM msbf_ctl.run_registry r
JOIN LATERAL (
    SELECT *
    FROM msbf_ctl.acceptance_gate_result x
    WHERE x.run_id=r.run_id
      AND x.gate_id='M1_7_SOURCE_QUALITY_CONFIDENCE'
    ORDER BY review_version DESC
    LIMIT 1
) a ON true
WHERE r.run_id=(SELECT run_id FROM _m1_7_dctx);

-- 2. Entity and Stage-Boundary Row Counts
SELECT 'source_snapshot' AS entity,count(*) AS rows FROM _m1_7_ds
UNION ALL SELECT 'applications',count(DISTINCT merchant_application_id) FROM _m1_7_ds
UNION ALL SELECT 'source_codes',count(DISTINCT source_code) FROM _m1_7_ds
UNION ALL SELECT 'obligations',
    (SELECT count(*) FROM msbf_m1.application_obligation_snapshot
      WHERE created_by_run_id=(SELECT run_id FROM _m1_7_dctx))
UNION ALL SELECT 'collateral',
    (SELECT count(*) FROM msbf_m1.collateral_availability_snapshot
      WHERE created_by_run_id=(SELECT run_id FROM _m1_7_dctx))
UNION ALL SELECT 'guarantees',
    (SELECT count(*) FROM msbf_m1.guarantee_availability_snapshot
      WHERE created_by_run_id=(SELECT run_id FROM _m1_7_dctx))
UNION ALL SELECT 'business_credit',
    (SELECT count(*) FROM msbf_m1.application_business_credit_snapshot
      WHERE created_by_run_id=(SELECT run_id FROM _m1_7_dctx))
UNION ALL SELECT 'owner_credit',
    (SELECT count(*) FROM msbf_m1.application_owner_credit_snapshot
      WHERE created_by_run_id=(SELECT run_id FROM _m1_7_dctx))
UNION ALL SELECT 'verification',
    (SELECT count(*) FROM msbf_m1.verification_result
      WHERE created_by_run_id=(SELECT run_id FROM _m1_7_dctx))
UNION ALL SELECT 'features',
    (SELECT count(*) FROM msbf_m1.merchant_feature_snapshot
      WHERE module1_run_id=(SELECT run_id FROM _m1_7_dctx))
UNION ALL SELECT 'risk',
    (SELECT count(*) FROM msbf_m1.merchant_risk_snapshot
      WHERE module1_run_id=(SELECT run_id FROM _m1_7_dctx))
UNION ALL SELECT 'ead',
    (SELECT count(*) FROM msbf_m1.ead_path_snapshot
      WHERE module1_run_id=(SELECT run_id FROM _m1_7_dctx))
UNION ALL SELECT 'latest',
    (SELECT count(*) FROM msbf_m1.module1_latest
      WHERE module1_run_id=(SELECT run_id FROM _m1_7_dctx))
UNION ALL SELECT 'archive',
    (SELECT count(*) FROM msbf_m1.module1_archive
      WHERE module1_run_id=(SELECT run_id FROM _m1_7_dctx));

-- 3. Source-Level Quality Summary
SELECT
    source_code,
    count(*) AS rows,
    count(*) FILTER (WHERE availability_status='AVAILABLE') AS available,
    count(*) FILTER (WHERE availability_status='PARTIAL') AS partial,
    count(*) FILTER (WHERE availability_status='UNAVAILABLE') AS unavailable,
    count(*) FILTER (WHERE quality_status='PASS') AS pass,
    count(*) FILTER (WHERE quality_status='WARNING') AS warning,
    count(*) FILTER (WHERE quality_status='FAIL') AS fail,
    count(*) FILTER (WHERE quality_status='CONFLICT') AS conflict,
    round(avg(data_confidence_score),6) AS average_confidence
FROM _m1_7_ds
GROUP BY source_code
ORDER BY source_code;

-- 4. Availability and Fallback Diagnostics
SELECT
    source_code,
    availability_status,
    quality_status,
    fallback_path_code,
    count(*) AS rows,
    round(avg(data_confidence_score),6) AS average_confidence
FROM _m1_7_ds
GROUP BY source_code,availability_status,quality_status,fallback_path_code
ORDER BY source_code,availability_status,quality_status,fallback_path_code;

-- 5. Completeness, Freshness, and Contract Diagnostics
SELECT
    source_code,
    count(*) AS rows,
    round(avg(completeness_rate),6) AS average_completeness,
    min(completeness_rate) AS minimum_completeness,
    max(completeness_rate) AS maximum_completeness,
    round(avg(freshness_age_hours) FILTER (
        WHERE availability_status<>'UNAVAILABLE'
    ),2) AS average_available_freshness_hours,
    min(freshness_age_hours) FILTER (
        WHERE availability_status<>'UNAVAILABLE'
    ) AS minimum_available_freshness_hours,
    max(freshness_age_hours) FILTER (
        WHERE availability_status<>'UNAVAILABLE'
    ) AS maximum_available_freshness_hours,
    min(required_history_days) AS contract_required_history_days,
    min(freshness_sla_hours) AS contract_freshness_sla_hours,
    min(minimum_completeness_rate) AS contract_minimum_completeness,
    min(reconciliation_tolerance_rate) AS contract_reconciliation_tolerance
FROM _m1_7_ds
GROUP BY source_code
ORDER BY source_code;

-- 6. POS/Deposit Reconciliation Diagnostics
SELECT
    p.quality_status AS pos_quality_status,
    d.quality_status AS deposit_quality_status,
    count(*) AS applications,
    count(*) FILTER (WHERE p.reconciliation_rate IS NULL) AS unavailable_pair_rows,
    round(avg(p.reconciliation_rate),6) AS average_reconciliation,
    min(p.reconciliation_rate) AS minimum_reconciliation,
    max(p.reconciliation_rate) AS maximum_reconciliation
FROM _m1_7_ds p
JOIN _m1_7_ds d
  ON d.merchant_application_id=p.merchant_application_id
 AND d.source_code='DEPOSIT_DAILY'
WHERE p.source_code='POS_DAILY'
GROUP BY p.quality_status,d.quality_status
ORDER BY p.quality_status,d.quality_status;

-- 7. Application-Level Confidence Tiers
SELECT *
FROM (
    SELECT
        CASE
            WHEN application_confidence_score>=0.90 THEN 'HIGH'
            WHEN application_confidence_score>=0.75 THEN 'MEDIUM'
            WHEN application_confidence_score>=0.60 THEN 'LOW'
            ELSE 'REVIEW'
        END AS confidence_tier,
        count(*) AS applications,
        round(avg(application_confidence_score),6) AS average_score,
        round(avg(nonpass_count),2) AS average_nonpass_sources,
        count(*) FILTER (WHERE conflict_count>0) AS conflict_applications
    FROM _m1_7_dapp
    GROUP BY 1
) q
ORDER BY CASE confidence_tier
    WHEN 'HIGH' THEN 1
    WHEN 'MEDIUM' THEN 2
    WHEN 'LOW' THEN 3
    ELSE 4
END;

-- 8. Critical-Source and Manual-Review Diagnostics
SELECT
    count(*) AS applications,
    count(*) FILTER (
        WHERE conflict_count>=(SELECT conflict_threshold FROM _m1_7_dctx)
    ) AS source_conflict_review_applications,
    count(*) FILTER (WHERE pos_fail_closed) AS pos_fail_closed_applications,
    count(*) FILTER (WHERE verification_fail_closed) AS verification_fail_closed_applications,
    count(*) FILTER (WHERE deposit_pos_only) AS deposit_pos_only_applications,
    count(*) FILTER (
        WHERE pos_fail_closed OR verification_fail_closed
    ) AS critical_source_stop_applications
FROM _m1_7_dapp;

-- 9. Conflict, Failure, and Warning Diagnostics
SELECT
    source_code,
    availability_status,
    quality_status,
    fallback_path_code,
    count(*) AS rows,
    round(avg(data_confidence_score),6) AS average_confidence
FROM _m1_7_ds
WHERE quality_status<>'PASS'
GROUP BY source_code,availability_status,quality_status,fallback_path_code
ORDER BY
    CASE quality_status
        WHEN 'CONFLICT' THEN 1
        WHEN 'FAIL' THEN 2
        WHEN 'UNAVAILABLE' THEN 3
        WHEN 'WARNING' THEN 4
        ELSE 5
    END,
    source_code,
    fallback_path_code;

-- 10. Partner/Channel Diagnostics
SELECT
    coalesce(pc.channel_type,'UNASSIGNED') AS channel_type,
    count(*) AS applications,
    round(avg(d.application_confidence_score),6) AS average_confidence,
    round(avg(d.nonpass_count),2) AS average_nonpass_sources,
    count(*) FILTER (WHERE d.conflict_count>0) AS conflict_applications,
    count(*) FILTER (WHERE d.pos_fail_closed OR d.verification_fail_closed)
        AS critical_source_stop_applications
FROM _m1_7_dapp d
LEFT JOIN msbf_m1.partner_channel pc
  ON pc.partner_channel_id=d.partner_channel_id
GROUP BY coalesce(pc.channel_type,'UNASSIGNED')
ORDER BY channel_type;

-- 11. Industry Diagnostics
SELECT
    industry_code,
    count(*) AS applications,
    round(avg(application_confidence_score),6) AS average_confidence,
    round(avg(nonpass_count),2) AS average_nonpass_sources,
    count(*) FILTER (WHERE conflict_count>0) AS conflict_applications,
    count(*) FILTER (WHERE pos_fail_closed OR verification_fail_closed)
        AS critical_source_stop_applications
FROM _m1_7_dapp
GROUP BY industry_code
ORDER BY industry_code;

-- 12. Sample Application/Source Profiles
SELECT
    merchant_application_id,
    merchant_id,
    industry_code,
    relationship_stage,
    round(application_confidence_score,6) AS application_confidence_score,
    nonpass_count,
    conflict_count,
    pos_fail_closed,
    verification_fail_closed,
    deposit_pos_only,
    source_profile
FROM _m1_7_dapp
ORDER BY
    (pos_fail_closed OR verification_fail_closed) DESC,
    conflict_count DESC,
    nonpass_count DESC,
    application_confidence_score,
    merchant_application_id
LIMIT 30;

-- 13. Row-Level Deterministic Mismatches — must contain zero rows
SELECT
    s.merchant_application_id,
    s.source_code,
    s.source_hash AS stored_hash,
    a.row_hash AS recomputed_hash
FROM _m1_7_ds s
JOIN msbf_m1.m1_7_actual_source_snapshot((SELECT run_id FROM _m1_7_dctx)) a
  ON a.entity_key=s.merchant_application_id || '|' || s.source_code
WHERE s.source_hash IS DISTINCT FROM a.row_hash
ORDER BY s.merchant_application_id,s.source_code;

-- 14. M1.7 Evidence
SELECT
    evidence_code,
    segment_key,
    metric_name,
    metric_value_text,
    status,
    interpretation,
    created_at
FROM msbf_ctl.run_evidence
WHERE run_id=(SELECT run_id FROM _m1_7_dctx)
  AND evidence_code LIKE 'M1_7_%'
ORDER BY evidence_code,segment_key;

-- 15. Blocking Resolution Errors — must contain zero rows
SELECT
    profile_domain,
    scope_key,
    error_code,
    severity,
    error_message,
    created_at
FROM msbf_ctl.profile_resolution_error
WHERE run_id=(SELECT run_id FROM _m1_7_dctx)
  AND severity='BLOCKING'
ORDER BY created_at;

COMMIT;
