/**********************************************************************
MSBF M1.2 Deterministic Merchant Population — Master Report
Version : v0.2R2
Purpose : One-row exportable acceptance evidence after M1.2 finalization.
**********************************************************************/

WITH ctx AS (
    SELECT r.*,p.population_version,p.population_status,p.deterministic_seed_version,
           p.merchant_count,p.history_start_date,p.history_end_date,p.population_hash
    FROM msbf_ctl.run_registry r
    JOIN msbf_m1.population_registry p ON p.population_id=r.population_id
    WHERE r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1
), latest_g1 AS (
    SELECT result_status,review_version,reviewed_at,finding
    FROM msbf_ctl.acceptance_gate_result
    WHERE run_id=(SELECT run_id FROM ctx) AND gate_id='G1_CONTROL_PLANE'
    ORDER BY review_version DESC LIMIT 1
), latest_m12 AS (
    SELECT result_status,review_version,reviewed_at,finding,residual_limitation
    FROM msbf_ctl.acceptance_gate_result
    WHERE run_id=(SELECT run_id FROM ctx) AND gate_id='M1_2_POPULATION'
    ORDER BY review_version DESC LIMIT 1
), g1_hashes AS (
    SELECT
      (SELECT md5(string_agg(parameter_name||'|'||scope_key||'|'||snapshot_hash,'||' ORDER BY parameter_name,scope_key)) FROM msbf_ctl.run_parameter_snapshot WHERE run_id=(SELECT run_id FROM ctx)) AS parameter_hash,
      (SELECT md5(string_agg(profile_domain||'|'||profile_code||'|'||profile_version::text||'|'||profile_hash,'||' ORDER BY profile_domain,profile_code)) FROM msbf_ctl.run_profile_snapshot WHERE run_id=(SELECT run_id FROM ctx)) AS profile_hash,
      (SELECT md5(string_agg(source_code||'|'||to_char(source_cutoff_timestamp AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS.US')||'|'||source_hash||'|'||quality_status,'||' ORDER BY source_code)) FROM msbf_ctl.run_source_snapshot WHERE run_id=(SELECT run_id FROM ctx)) AS source_hash
), table_obs AS (
    SELECT
      (SELECT COUNT(*) FROM msbf_m1.merchant_master WHERE population_id=(SELECT population_id FROM ctx)) AS merchants,
      (SELECT COUNT(*) FROM msbf_m1.merchant_owner_guarantor o JOIN msbf_m1.merchant_master m ON m.merchant_id=o.merchant_id WHERE m.population_id=(SELECT population_id FROM ctx)) AS owner_rows,
      (SELECT COUNT(*) FROM msbf_m1.merchant_industry_assignment i JOIN msbf_m1.merchant_master m ON m.merchant_id=i.merchant_id WHERE m.population_id=(SELECT population_id FROM ctx)) AS industry_rows,
      (SELECT COUNT(*) FROM msbf_m1.partner_channel WHERE created_by_run_id=(SELECT run_id FROM ctx)) AS partner_channels,
      (SELECT COUNT(*) FROM msbf_m1.processor_account WHERE created_by_run_id=(SELECT run_id FROM ctx)) AS processor_accounts,
      (SELECT COUNT(*) FROM msbf_m1.merchant_relationship_snapshot WHERE created_by_run_id=(SELECT run_id FROM ctx)) AS relationship_rows
), entity_obs AS (
    SELECT
      (SELECT COUNT(*) FROM msbf_m1.m1_2_expected_entity_snapshot((SELECT run_id FROM ctx))) AS expected_entity_rows,
      (SELECT COUNT(*) FROM msbf_m1.m1_2_actual_entity_snapshot((SELECT run_id FROM ctx))) AS actual_entity_rows,
      (SELECT COUNT(*) FROM msbf_m1.m1_2_expected_entity_snapshot((SELECT run_id FROM ctx)) e FULL JOIN msbf_m1.m1_2_actual_entity_snapshot((SELECT run_id FROM ctx)) a USING(entity_type,entity_key) WHERE e.row_hash IS DISTINCT FROM a.row_hash) AS row_mismatches,
      (SELECT md5(string_agg(entity_type||'|'||entity_key||'|'||row_hash,'||' ORDER BY entity_type,entity_key)) FROM msbf_m1.m1_2_expected_entity_snapshot((SELECT run_id FROM ctx))) AS expected_population_hash,
      (SELECT md5(string_agg(entity_type||'|'||entity_key||'|'||row_hash,'||' ORDER BY entity_type,entity_key)) FROM msbf_m1.m1_2_actual_entity_snapshot((SELECT run_id FROM ctx))) AS actual_population_hash
), evidence_obs AS (
    SELECT COUNT(*) FILTER (WHERE evidence_code LIKE 'M1_2_POS_%') AS positive_checks,
           COUNT(*) FILTER (WHERE evidence_code LIKE 'M1_2_POS_%' AND status='PASS') AS positive_passes,
           COUNT(*) FILTER (WHERE evidence_code LIKE 'M1_2_NEG_%') AS negative_controls,
           COUNT(*) FILTER (WHERE evidence_code LIKE 'M1_2_NEG_%' AND status='PASS') AS negative_passes,
           COUNT(*) FILTER (WHERE (evidence_code LIKE 'M1_2_POS_%' OR evidence_code LIKE 'M1_2_NEG_%') AND status='FAIL') AS failed_evidence
    FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM ctx)
), owner_obs AS (
    SELECT MIN(owner_credit_score) AS min_owner_score,MAX(owner_credit_score) AS max_owner_score,
           COUNT(*) FILTER (WHERE major_derogatory_flag) AS major_derogatory_rows,
           COUNT(*) FILTER (WHERE bankruptcy_flag) AS bankruptcy_rows,
           COUNT(*) FILTER (WHERE personal_guarantee_available_flag) AS guarantee_available_rows,
           COUNT(DISTINCT merchant_id) AS merchants_with_owner_rows
    FROM msbf_m1.merchant_owner_guarantor
    WHERE created_by_run_id=(SELECT run_id FROM ctx)
), age_obs AS (
    SELECT
      MIN(((extract(year from age(ctx.as_of_date,m.incorporation_date))*12)+extract(month from age(ctx.as_of_date,m.incorporation_date)))::integer) AS min_business_months,
      MAX(((extract(year from age(ctx.as_of_date,m.incorporation_date))*12)+extract(month from age(ctx.as_of_date,m.incorporation_date)))::integer) AS max_business_months,
      MIN(((extract(year from age(ctx.as_of_date,p.processor_account_open_date))*12)+extract(month from age(ctx.as_of_date,p.processor_account_open_date)))::integer) AS min_processor_months,
      MAX(((extract(year from age(ctx.as_of_date,p.processor_account_open_date))*12)+extract(month from age(ctx.as_of_date,p.processor_account_open_date)))::integer) AS max_processor_months
    FROM msbf_m1.merchant_master m
    JOIN msbf_m1.processor_account p ON p.merchant_id=m.merchant_id AND p.created_by_run_id=(SELECT run_id FROM ctx)
    CROSS JOIN ctx
    WHERE m.population_id=ctx.population_id
), mixed_obs AS (
    SELECT COUNT(*) FILTER (WHERE
        (o.owner_credit_score>=700 AND (s.relationship_stage='RETURNING_MIXED' OR s.prior_payment_interruption_flag OR s.prior_default_flag))
     OR (o.owner_credit_score<640 AND s.relationship_stage='RETURNING_GOOD' AND NOT s.prior_default_flag)
     OR ((((extract(year from age(s.as_of_date,m.incorporation_date))*12)+extract(month from age(s.as_of_date,m.incorporation_date)))::integer)<24 AND o.owner_credit_score>=720)
     OR (m.merchant_size_tier IN ('LOWER_MIDDLE','MIDDLE') AND o.owner_credit_score<620)
    ) AS mixed_signal_rows,COUNT(*) AS total_rows
    FROM msbf_m1.merchant_master m
    JOIN msbf_m1.merchant_relationship_snapshot s ON s.merchant_id=m.merchant_id AND s.created_by_run_id=(SELECT run_id FROM ctx)
    JOIN msbf_m1.merchant_owner_guarantor o ON o.merchant_id=m.merchant_id
                                                AND o.party_role='PRIMARY_OWNER_GUARANTOR'
                                                AND o.created_by_run_id=(SELECT run_id FROM ctx)
    WHERE m.population_id=(SELECT population_id FROM ctx)
), mixed_limit AS (
    SELECT (snapshot_payload->>'hard_limit_value')::numeric AS hard_limit
    FROM msbf_ctl.run_profile_snapshot
    WHERE run_id=(SELECT run_id FROM ctx)
      AND profile_domain='RISK_APPETITE_LIMIT'
      AND profile_code='M1_MIN_MIXED_SIGNAL_SHARE'
), resolution_obs AS (
    SELECT COUNT(*) FILTER (WHERE severity='BLOCKING') AS blocking_errors
    FROM msbf_ctl.profile_resolution_error WHERE run_id=(SELECT run_id FROM ctx)
), downstream_obs AS (
    SELECT
      (SELECT COUNT(*) FROM msbf_m1.merchant_application WHERE created_by_run_id=(SELECT run_id FROM ctx)) AS applications,
      (SELECT COUNT(*) FROM msbf_m1.merchant_pos_daily_base WHERE generated_by_run_id=(SELECT run_id FROM ctx)) AS pos_base_rows,
      (SELECT COUNT(*) FROM msbf_m1.merchant_deposit_daily_base WHERE generated_by_run_id=(SELECT run_id FROM ctx)) AS deposit_base_rows,
      (SELECT COUNT(*) FROM msbf_m1.merchant_feature_snapshot WHERE module1_run_id=(SELECT run_id FROM ctx)) AS feature_rows,
      (SELECT COUNT(*) FROM msbf_m1.merchant_risk_snapshot WHERE module1_run_id=(SELECT run_id FROM ctx)) AS risk_rows,
      (SELECT COUNT(*) FROM msbf_m1.ead_path_snapshot WHERE module1_run_id=(SELECT run_id FROM ctx)) AS ead_rows,
      (SELECT COUNT(*) FROM msbf_m1.module1_latest WHERE module1_run_id=(SELECT run_id FROM ctx)) AS latest_rows,
      (SELECT COUNT(*) FROM msbf_m1.module1_archive WHERE module1_run_id=(SELECT run_id FROM ctx)) AS archive_rows
)
SELECT
    clock_timestamp() AS report_timestamp,
    current_database() AS database_name,
    current_user AS database_user,
    current_setting('server_version') AS postgresql_version,
    ctx.run_id,ctx.run_code,ctx.run_version,ctx.run_status,ctx.as_of_date,
    ctx.population_id,ctx.population_version,ctx.population_status,ctx.deterministic_seed_version,
    ctx.merchant_count AS planned_merchant_count,ctx.history_start_date,ctx.history_end_date,
    ctx.parameter_snapshot_hash,g1_hashes.parameter_hash AS recomputed_parameter_hash,
    ctx.profile_snapshot_hash,g1_hashes.profile_hash AS recomputed_profile_hash,
    ctx.source_snapshot_hash,g1_hashes.source_hash AS recomputed_source_hash,
    latest_g1.result_status AS g1_gate_status,
    table_obs.merchants,table_obs.owner_rows,table_obs.industry_rows,table_obs.partner_channels,
    table_obs.processor_accounts,table_obs.relationship_rows,
    entity_obs.expected_entity_rows,entity_obs.actual_entity_rows,entity_obs.row_mismatches,
    ctx.population_hash AS stored_population_hash,
    entity_obs.expected_population_hash,entity_obs.actual_population_hash,
    owner_obs.min_owner_score,owner_obs.max_owner_score,owner_obs.major_derogatory_rows,
    owner_obs.bankruptcy_rows,owner_obs.guarantee_available_rows,owner_obs.merchants_with_owner_rows,
    age_obs.min_business_months,age_obs.max_business_months,age_obs.min_processor_months,age_obs.max_processor_months,
    mixed_obs.mixed_signal_rows,round(mixed_obs.mixed_signal_rows::numeric/NULLIF(mixed_obs.total_rows,0),6) AS mixed_signal_share,
    mixed_limit.hard_limit AS mixed_signal_minimum,
    evidence_obs.positive_checks,evidence_obs.positive_passes,evidence_obs.negative_controls,evidence_obs.negative_passes,evidence_obs.failed_evidence,
    resolution_obs.blocking_errors,
    downstream_obs.applications,downstream_obs.pos_base_rows,downstream_obs.deposit_base_rows,
    downstream_obs.feature_rows,downstream_obs.risk_rows,downstream_obs.ead_rows,downstream_obs.latest_rows,downstream_obs.archive_rows,
    latest_m12.result_status AS m1_2_gate_status,latest_m12.review_version AS m1_2_gate_review_version,
    latest_m12.reviewed_at AS m1_2_gate_reviewed_at,latest_m12.finding AS m1_2_gate_finding,
    CASE WHEN
      ctx.run_status='M1_2_ACCEPTED'
      AND ctx.population_status='M1_2_ACCEPTED'
      AND latest_g1.result_status='PASS'
      AND latest_m12.result_status='PASS'
      AND ctx.parameter_snapshot_hash='bd09e598c82db96e47459d77fd11e7c8'
      AND ctx.profile_snapshot_hash='462cbd2ed92f68e5bdecf6b17537a973'
      AND ctx.source_snapshot_hash='93c3d1368fb2450ab4a08e2b721f92d3'
      AND ctx.parameter_snapshot_hash=g1_hashes.parameter_hash
      AND ctx.profile_snapshot_hash=g1_hashes.profile_hash
      AND ctx.source_snapshot_hash=g1_hashes.source_hash
      AND table_obs.merchants=750
      AND table_obs.owner_rows=1347
      AND table_obs.industry_rows=750
      AND table_obs.partner_channels=5
      AND table_obs.processor_accounts=750
      AND table_obs.relationship_rows=750
      AND owner_obs.merchants_with_owner_rows=750
      AND entity_obs.expected_entity_rows=4352
      AND entity_obs.actual_entity_rows=4352
      AND entity_obs.row_mismatches=0
      AND ctx.population_hash=entity_obs.expected_population_hash
      AND ctx.population_hash=entity_obs.actual_population_hash
      AND evidence_obs.positive_checks=36
      AND evidence_obs.positive_passes=36
      AND evidence_obs.negative_controls=3
      AND evidence_obs.negative_passes=3
      AND evidence_obs.failed_evidence=0
      AND resolution_obs.blocking_errors=0
      AND mixed_obs.mixed_signal_rows::numeric/NULLIF(mixed_obs.total_rows,0)>=mixed_limit.hard_limit
      AND downstream_obs.applications=0 AND downstream_obs.pos_base_rows=0 AND downstream_obs.deposit_base_rows=0
      AND downstream_obs.feature_rows=0 AND downstream_obs.risk_rows=0 AND downstream_obs.ead_rows=0
      AND downstream_obs.latest_rows=0 AND downstream_obs.archive_rows=0
    THEN 'PASS' ELSE 'FAIL' END AS overall_m1_2_status
FROM ctx
CROSS JOIN g1_hashes
CROSS JOIN table_obs
CROSS JOIN entity_obs
CROSS JOIN evidence_obs
CROSS JOIN owner_obs
CROSS JOIN age_obs
CROSS JOIN mixed_obs
CROSS JOIN mixed_limit
CROSS JOIN resolution_obs
CROSS JOIN downstream_obs
LEFT JOIN latest_g1 ON true
LEFT JOIN latest_m12 ON true;
