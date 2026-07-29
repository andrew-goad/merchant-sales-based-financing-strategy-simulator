/* ============================================================================
MSBF M1.2 Deterministic Merchant Population Generation
Version : v0.2R2
Purpose : Generate the governed 750-merchant intrinsic and relationship
          population authorized by accepted G1 configuration.

Stage boundary:
- Creates merchant, owner/guarantor, primary industry, partner channel,
  processor account, and relationship snapshot records.
- Does not create applications, daily POS/deposit history, features, risk,
  EAD, Expected Loss, latest, or archive outputs.
============================================================================ */

BEGIN;

INSERT INTO msbf_ref.acceptance_gate_catalog (
    gate_id, gate_name, module_code, severity, description
)
VALUES (
    'M1_2_POPULATION',
    'M1.2 Deterministic Merchant Population',
    'M1',
    'BLOCKING',
    'Deterministic merchant, owner, industry, processor, channel, and relationship population accepted.'
)
ON CONFLICT (gate_id) DO NOTHING;

/* -------------------------------------------------------------------------
   Fail-closed generation authorization.
   ---------------------------------------------------------------------- */
CREATE OR REPLACE FUNCTION msbf_m1.m1_2_assert_generation_ready(p_run_id bigint)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    v_run_status text;
    v_population_status text;
    v_population_id text;
    v_parameter_hash text;
    v_profile_hash text;
    v_source_hash text;
    v_recomputed_parameter_hash text;
    v_recomputed_profile_hash text;
    v_recomputed_source_hash text;
    v_g1_status text;
    v_existing_rows bigint;
    v_downstream_rows bigint;
BEGIN
    SELECT r.run_status, p.population_status, r.population_id,
           r.parameter_snapshot_hash, r.profile_snapshot_hash, r.source_snapshot_hash
      INTO STRICT v_run_status, v_population_status, v_population_id,
                  v_parameter_hash, v_profile_hash, v_source_hash
      FROM msbf_ctl.run_registry r
      JOIN msbf_m1.population_registry p ON p.population_id=r.population_id
     WHERE r.run_id=p_run_id;

    SELECT result_status
      INTO v_g1_status
      FROM msbf_ctl.acceptance_gate_result
     WHERE run_id=p_run_id AND gate_id='G1_CONTROL_PLANE'
     ORDER BY review_version DESC
     LIMIT 1;

    SELECT md5(string_agg(parameter_name || '|' || scope_key || '|' || snapshot_hash,
                          '||' ORDER BY parameter_name, scope_key))
      INTO v_recomputed_parameter_hash
      FROM msbf_ctl.run_parameter_snapshot
     WHERE run_id=p_run_id;

    SELECT md5(string_agg(profile_domain || '|' || profile_code || '|' ||
                          profile_version::text || '|' || profile_hash,
                          '||' ORDER BY profile_domain, profile_code))
      INTO v_recomputed_profile_hash
      FROM msbf_ctl.run_profile_snapshot
     WHERE run_id=p_run_id;

    SELECT md5(string_agg(source_code || '|' ||
                          to_char(source_cutoff_timestamp AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US') || '|' ||
                          source_hash || '|' || quality_status,
                          '||' ORDER BY source_code))
      INTO v_recomputed_source_hash
      FROM msbf_ctl.run_source_snapshot
     WHERE run_id=p_run_id;

    SELECT
          (SELECT COUNT(*) FROM msbf_m1.merchant_master WHERE population_id=v_population_id)
        + (SELECT COUNT(*) FROM msbf_m1.merchant_owner_guarantor o
            JOIN msbf_m1.merchant_master m ON m.merchant_id=o.merchant_id
           WHERE m.population_id=v_population_id)
        + (SELECT COUNT(*) FROM msbf_m1.merchant_industry_assignment i
            JOIN msbf_m1.merchant_master m ON m.merchant_id=i.merchant_id
           WHERE m.population_id=v_population_id)
        + (SELECT COUNT(*) FROM msbf_m1.partner_channel WHERE created_by_run_id=p_run_id)
        + (SELECT COUNT(*) FROM msbf_m1.processor_account WHERE created_by_run_id=p_run_id)
        + (SELECT COUNT(*) FROM msbf_m1.merchant_relationship_snapshot WHERE created_by_run_id=p_run_id)
      INTO v_existing_rows;

    SELECT
          (SELECT COUNT(*) FROM msbf_m1.merchant_application WHERE created_by_run_id=p_run_id)
        + (SELECT COUNT(*) FROM msbf_m1.source_snapshot WHERE module1_run_id=p_run_id)
        + (SELECT COUNT(*) FROM msbf_m1.application_obligation_snapshot WHERE created_by_run_id=p_run_id)
        + (SELECT COUNT(*) FROM msbf_m1.collateral_availability_snapshot WHERE created_by_run_id=p_run_id)
        + (SELECT COUNT(*) FROM msbf_m1.guarantee_availability_snapshot WHERE created_by_run_id=p_run_id)
        + (SELECT COUNT(*) FROM msbf_m1.application_business_credit_snapshot WHERE created_by_run_id=p_run_id)
        + (SELECT COUNT(*) FROM msbf_m1.application_owner_credit_snapshot WHERE created_by_run_id=p_run_id)
        + (SELECT COUNT(*) FROM msbf_m1.merchant_pos_daily_base WHERE generated_by_run_id=p_run_id)
        + (SELECT COUNT(*) FROM msbf_m1.merchant_pos_daily_scenario WHERE generated_by_run_id=p_run_id)
        + (SELECT COUNT(*) FROM msbf_m1.merchant_deposit_daily_base WHERE generated_by_run_id=p_run_id)
        + (SELECT COUNT(*) FROM msbf_m1.merchant_deposit_daily_scenario WHERE generated_by_run_id=p_run_id)
        + (SELECT COUNT(*) FROM msbf_m1.verification_result WHERE created_by_run_id=p_run_id)
        + (SELECT COUNT(*) FROM msbf_m1.merchant_feature_snapshot WHERE module1_run_id=p_run_id)
        + (SELECT COUNT(*) FROM msbf_m1.feature_value WHERE module1_run_id=p_run_id)
        + (SELECT COUNT(*) FROM msbf_m1.merchant_risk_snapshot WHERE module1_run_id=p_run_id)
        + (SELECT COUNT(*) FROM msbf_m1.risk_component_detail WHERE module1_run_id=p_run_id)
        + (SELECT COUNT(*) FROM msbf_m1.ead_path_snapshot WHERE module1_run_id=p_run_id)
        + (SELECT COUNT(*) FROM msbf_m1.module1_latest WHERE module1_run_id=p_run_id)
        + (SELECT COUNT(*) FROM msbf_m1.module1_archive WHERE module1_run_id=p_run_id)
      INTO v_downstream_rows;

    IF v_run_status <> 'G1_READY' THEN
        RAISE EXCEPTION 'M1.2 generation requires run_status=G1_READY; observed %.', v_run_status;
    END IF;
    IF v_population_status <> 'READY_FOR_GENERATION' THEN
        RAISE EXCEPTION 'M1.2 generation requires population_status=READY_FOR_GENERATION; observed %.', v_population_status;
    END IF;
    IF v_g1_status IS DISTINCT FROM 'PASS' THEN
        RAISE EXCEPTION 'M1.2 generation requires latest G1_CONTROL_PLANE result PASS; observed %.', v_g1_status;
    END IF;
    IF v_parameter_hash <> 'bd09e598c82db96e47459d77fd11e7c8'
       OR v_profile_hash <> '462cbd2ed92f68e5bdecf6b17537a973'
       OR v_source_hash <> '93c3d1368fb2450ab4a08e2b721f92d3' THEN
        RAISE EXCEPTION 'Accepted G1 hashes do not match the approved M1.2 baseline.';
    END IF;
    IF v_parameter_hash IS DISTINCT FROM v_recomputed_parameter_hash
       OR v_profile_hash IS DISTINCT FROM v_recomputed_profile_hash
       OR v_source_hash IS DISTINCT FROM v_recomputed_source_hash THEN
        RAISE EXCEPTION 'One or more G1 snapshot hashes do not reconcile to frozen snapshot content.';
    END IF;
    IF v_existing_rows <> 0 THEN
        RAISE EXCEPTION 'M1.2 population rows already exist (% rows); regeneration is prohibited.', v_existing_rows;
    END IF;
    IF v_downstream_rows <> 0 THEN
        RAISE EXCEPTION 'Downstream analytical rows already exist (% rows); M1.2 generation is prohibited.', v_downstream_rows;
    END IF;
END
$$;

/* -------------------------------------------------------------------------
   Exact weighted assignment from frozen scoped parameters.
   Uses largest-remainder quotas and deterministic rank ordering.
   ---------------------------------------------------------------------- */
CREATE OR REPLACE FUNCTION msbf_m1.m1_2_weighted_assignment(
    p_run_id bigint,
    p_parameter_name text,
    p_scope_prefix text,
    p_seed_label text
)
RETURNS TABLE (
    merchant_sequence integer,
    category_code text,
    target_count integer
)
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    v_population_id text;
    v_merchant_count integer;
    v_seed_version text;
    v_weight_count integer;
    v_weight_sum numeric;
BEGIN
    SELECT r.population_id, p.merchant_count, p.deterministic_seed_version
      INTO STRICT v_population_id, v_merchant_count, v_seed_version
      FROM msbf_ctl.run_registry r
      JOIN msbf_m1.population_registry p ON p.population_id=r.population_id
     WHERE r.run_id=p_run_id;

    SELECT COUNT(*), COALESCE(SUM((NULLIF(rps.resolved_value ->> 'value_numeric',''))::numeric),0)
      INTO v_weight_count, v_weight_sum
      FROM msbf_ctl.run_parameter_snapshot rps
     WHERE rps.run_id=p_run_id
       AND rps.parameter_name=p_parameter_name
       AND rps.scope_key LIKE p_scope_prefix || ':%';

    IF v_weight_count=0 THEN
        RAISE EXCEPTION 'M1.2 weighted assignment found no scoped values for parameter % and prefix %.',
            p_parameter_name, p_scope_prefix;
    END IF;
    IF abs(v_weight_sum-1.0)>0.000000001 THEN
        RAISE EXCEPTION 'M1.2 weighted assignment requires weights summing to one; parameter % sums to %.',
            p_parameter_name, v_weight_sum;
    END IF;

    RETURN QUERY
    WITH weights AS (
        SELECT split_part(rps.scope_key,':',2) AS cat_code,
               (NULLIF(rps.resolved_value ->> 'value_numeric',''))::numeric AS weight
        FROM msbf_ctl.run_parameter_snapshot rps
        WHERE rps.run_id=p_run_id
          AND rps.parameter_name=p_parameter_name
          AND rps.scope_key LIKE p_scope_prefix || ':%'
    ), base AS (
        SELECT w.cat_code, w.weight,
               floor(w.weight*v_merchant_count)::integer AS base_count,
               (w.weight*v_merchant_count)-floor(w.weight*v_merchant_count) AS remainder
        FROM weights w
    ), ranked_quota AS (
        SELECT b.cat_code, b.base_count, b.remainder,
               row_number() OVER (ORDER BY b.remainder DESC, b.cat_code) AS remainder_rank,
               v_merchant_count-sum(b.base_count) OVER () AS residual_count
        FROM base b
    ), quotas AS (
        SELECT rq.cat_code,
               rq.base_count + CASE WHEN rq.remainder_rank<=rq.residual_count THEN 1 ELSE 0 END AS category_target_count
        FROM ranked_quota rq
    ), ranges AS (
        SELECT q.cat_code, q.category_target_count,
               1 + COALESCE(sum(q.category_target_count) OVER (
                   ORDER BY q.cat_code ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
               ),0) AS start_rank,
               sum(q.category_target_count) OVER (ORDER BY q.cat_code) AS end_rank
        FROM quotas q
    ), merchants AS (
        SELECT g.seq_no::integer AS seq_no,
               row_number() OVER (
                   ORDER BY msbf_ctl.deterministic_uniform(
                                v_population_id || '|' || lpad(g.seq_no::text,6,'0'),
                                v_seed_version || ':M1_2:' || p_seed_label
                            ), g.seq_no
               ) AS assignment_rank
        FROM generate_series(1,v_merchant_count) AS g(seq_no)
    )
    SELECT m.seq_no, r.cat_code, r.category_target_count::integer
    FROM merchants m
    JOIN ranges r ON m.assignment_rank BETWEEN r.start_rank AND r.end_rank
    ORDER BY m.seq_no;
END
$$;

CREATE OR REPLACE FUNCTION msbf_m1.m1_2_weighted_assignment_json(
    p_run_id bigint,
    p_weights jsonb,
    p_seed_label text
)
RETURNS TABLE (
    merchant_sequence integer,
    category_code text,
    target_count integer
)
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    v_population_id text;
    v_merchant_count integer;
    v_seed_version text;
    v_weight_count integer;
    v_weight_sum numeric;
BEGIN
    SELECT r.population_id, p.merchant_count, p.deterministic_seed_version
      INTO STRICT v_population_id, v_merchant_count, v_seed_version
      FROM msbf_ctl.run_registry r
      JOIN msbf_m1.population_registry p ON p.population_id=r.population_id
     WHERE r.run_id=p_run_id;

    SELECT COUNT(*), COALESCE(SUM(j.value::numeric),0)
      INTO v_weight_count, v_weight_sum
      FROM jsonb_each_text(p_weights) j;

    IF v_weight_count=0 THEN
        RAISE EXCEPTION 'M1.2 JSON weighted assignment requires at least one category.';
    END IF;
    IF abs(v_weight_sum-1.0)>0.000000001 THEN
        RAISE EXCEPTION 'M1.2 JSON weighted assignment requires weights summing to one; observed %.', v_weight_sum;
    END IF;

    RETURN QUERY
    WITH weights AS (
        SELECT j.key AS cat_code, j.value::numeric AS weight
        FROM jsonb_each_text(p_weights) j
    ), base AS (
        SELECT w.cat_code, w.weight,
               floor(w.weight*v_merchant_count)::integer AS base_count,
               (w.weight*v_merchant_count)-floor(w.weight*v_merchant_count) AS remainder
        FROM weights w
    ), ranked_quota AS (
        SELECT b.cat_code, b.base_count, b.remainder,
               row_number() OVER (ORDER BY b.remainder DESC, b.cat_code) AS remainder_rank,
               v_merchant_count-sum(b.base_count) OVER () AS residual_count
        FROM base b
    ), quotas AS (
        SELECT rq.cat_code,
               rq.base_count + CASE WHEN rq.remainder_rank<=rq.residual_count THEN 1 ELSE 0 END AS category_target_count
        FROM ranked_quota rq
    ), ranges AS (
        SELECT q.cat_code, q.category_target_count,
               1 + COALESCE(sum(q.category_target_count) OVER (
                   ORDER BY q.cat_code ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
               ),0) AS start_rank,
               sum(q.category_target_count) OVER (ORDER BY q.cat_code) AS end_rank
        FROM quotas q
    ), merchants AS (
        SELECT g.seq_no::integer AS seq_no,
               row_number() OVER (
                   ORDER BY msbf_ctl.deterministic_uniform(
                                v_population_id || '|' || lpad(g.seq_no::text,6,'0'),
                                v_seed_version || ':M1_2:' || p_seed_label
                            ), g.seq_no
               ) AS assignment_rank
        FROM generate_series(1,v_merchant_count) AS g(seq_no)
    )
    SELECT m.seq_no, r.cat_code, r.category_target_count::integer
    FROM merchants m
    JOIN ranges r ON m.assignment_rank BETWEEN r.start_rank AND r.end_rank
    ORDER BY m.seq_no;
END
$$;

/* -------------------------------------------------------------------------
   Merchant-level deterministic blueprint.
   ---------------------------------------------------------------------- */
CREATE OR REPLACE FUNCTION msbf_m1.m1_2_population_blueprint(p_run_id bigint)
RETURNS TABLE (
    merchant_sequence integer,
    run_id bigint,
    population_id text,
    as_of_date date,
    merchant_id text,
    synthetic_business_name text,
    legal_entity_type text,
    region_code text,
    incorporation_date date,
    months_in_business integer,
    merchant_size_tier text,
    annual_sales_band text,
    industry_code text,
    relationship_stage text,
    owner_count integer,
    partner_channel_id text,
    processor_account_id text,
    processor_name_synthetic text,
    processor_tenure_months integer,
    processor_account_open_date date,
    split_funding_capable_flag boolean,
    settlement_delay_days smallint,
    processor_risk_tier smallint,
    prior_advance_count integer,
    completed_advance_count integer,
    prior_default_flag boolean,
    prior_payment_interruption_flag boolean,
    total_prior_funded_amount numeric(18,2),
    total_prior_repaid_amount numeric(18,2),
    deposit_relationship_flag boolean,
    merchant_services_relationship_flag boolean,
    wallet_share_proxy numeric(9,6),
    relationship_quality_tier smallint,
    intrinsic_profile_hash text,
    relationship_snapshot_hash text
)
LANGUAGE sql
STABLE
AS $$
WITH ctx AS (
    SELECT r.run_id, r.population_id, r.as_of_date,
           p.merchant_count, p.deterministic_seed_version,
           (SELECT ((NULLIF(resolved_value ->> 'value_numeric',''))::numeric)::integer FROM msbf_ctl.run_parameter_snapshot
             WHERE run_id=p_run_id AND parameter_name='months_in_business_min' AND scope_key='GLOBAL') AS months_min,
           (SELECT ((NULLIF(resolved_value ->> 'value_numeric',''))::numeric)::integer FROM msbf_ctl.run_parameter_snapshot
             WHERE run_id=p_run_id AND parameter_name='months_in_business_max' AND scope_key='GLOBAL') AS months_max,
           (SELECT ((NULLIF(resolved_value ->> 'value_numeric',''))::numeric)::integer FROM msbf_ctl.run_parameter_snapshot
             WHERE run_id=p_run_id AND parameter_name='processor_tenure_min_months' AND scope_key='GLOBAL') AS processor_min,
           (SELECT ((NULLIF(resolved_value ->> 'value_numeric',''))::numeric)::integer FROM msbf_ctl.run_parameter_snapshot
             WHERE run_id=p_run_id AND parameter_name='processor_tenure_max_months' AND scope_key='GLOBAL') AS processor_max,
           (SELECT ((NULLIF(resolved_value ->> 'value_numeric',''))::numeric)::integer FROM msbf_ctl.run_parameter_snapshot
             WHERE run_id=p_run_id AND parameter_name='owner_count_min' AND scope_key='GLOBAL') AS owner_min,
           (SELECT ((NULLIF(resolved_value ->> 'value_numeric',''))::numeric)::integer FROM msbf_ctl.run_parameter_snapshot
             WHERE run_id=p_run_id AND parameter_name='owner_count_max' AND scope_key='GLOBAL') AS owner_max
    FROM msbf_ctl.run_registry r
    JOIN msbf_m1.population_registry p ON p.population_id=r.population_id
    WHERE r.run_id=p_run_id
), industry_a AS (
    SELECT * FROM msbf_m1.m1_2_weighted_assignment(p_run_id,'industry_mix_weight','INDUSTRY','INDUSTRY')
), region_a AS (
    SELECT * FROM msbf_m1.m1_2_weighted_assignment(p_run_id,'region_mix_weight','REGION','REGION')
), size_a AS (
    SELECT * FROM msbf_m1.m1_2_weighted_assignment(p_run_id,'merchant_size_mix_weight','MERCHANT_SIZE_TIER','MERCHANT_SIZE')
), relationship_a AS (
    SELECT * FROM msbf_m1.m1_2_weighted_assignment(p_run_id,'relationship_stage_mix_weight','RELATIONSHIP_STAGE','RELATIONSHIP')
), legal_a AS (
    SELECT * FROM msbf_m1.m1_2_weighted_assignment(p_run_id,'legal_entity_mix_weight','LEGAL_ENTITY_TYPE','LEGAL_ENTITY')
), channel_a AS (
    SELECT *
    FROM msbf_m1.m1_2_weighted_assignment_json(
        p_run_id,
        '{"CH_PROCESSOR_DIRECT":0.34,"CH_BANK_RELATIONSHIP":0.18,"CH_DIGITAL_DIRECT":0.20,"CH_STRATEGIC_PARTNER":0.16,"CH_BROKER_NETWORK":0.12}'::jsonb,
        'CHANNEL'
    )
), stage_prob AS (
    SELECT split_part(scope_key,':',2) AS relationship_stage,
           max((NULLIF(resolved_value ->> 'value_numeric',''))::numeric) FILTER (WHERE parameter_name='prior_advance_probability') AS prior_advance_probability,
           max((NULLIF(resolved_value ->> 'value_numeric',''))::numeric) FILTER (WHERE parameter_name='prior_default_probability') AS prior_default_probability
    FROM msbf_ctl.run_parameter_snapshot
    WHERE run_id=p_run_id
      AND parameter_name IN ('prior_advance_probability','prior_default_probability')
      AND scope_key LIKE 'RELATIONSHIP_STAGE:%'
    GROUP BY split_part(scope_key,':',2)
), seeded AS (
    SELECT g.merchant_sequence::integer AS merchant_sequence,
           c.*,
           ia.category_code AS industry_code,
           ra.category_code AS region_code,
           sa.category_code AS merchant_size_tier,
           rla.category_code AS relationship_stage,
           la.category_code AS legal_entity_type,
           ca.category_code AS partner_channel_id,
           msbf_ctl.deterministic_uniform(c.population_id || '|' || lpad(g.merchant_sequence::text,6,'0'), c.deterministic_seed_version || ':M1_2:MONTHS_IN_BUSINESS') AS u_age,
           msbf_ctl.deterministic_uniform(c.population_id || '|' || lpad(g.merchant_sequence::text,6,'0'), c.deterministic_seed_version || ':M1_2:PROCESSOR_TENURE') AS u_processor,
           msbf_ctl.deterministic_uniform(c.population_id || '|' || lpad(g.merchant_sequence::text,6,'0'), c.deterministic_seed_version || ':M1_2:OWNER_COUNT') AS u_owner_count,
           msbf_ctl.deterministic_uniform(c.population_id || '|' || lpad(g.merchant_sequence::text,6,'0'), c.deterministic_seed_version || ':M1_2:PRIOR_ADVANCE') AS u_prior_advance,
           msbf_ctl.deterministic_uniform(c.population_id || '|' || lpad(g.merchant_sequence::text,6,'0'), c.deterministic_seed_version || ':M1_2:PRIOR_DEFAULT') AS u_prior_default,
           msbf_ctl.deterministic_uniform(c.population_id || '|' || lpad(g.merchant_sequence::text,6,'0'), c.deterministic_seed_version || ':M1_2:PRIOR_INTERRUPTION') AS u_prior_interruption,
           msbf_ctl.deterministic_uniform(c.population_id || '|' || lpad(g.merchant_sequence::text,6,'0'), c.deterministic_seed_version || ':M1_2:PRIOR_ADVANCE_COUNT') AS u_prior_count,
           msbf_ctl.deterministic_uniform(c.population_id || '|' || lpad(g.merchant_sequence::text,6,'0'), c.deterministic_seed_version || ':M1_2:PRIOR_FUNDED') AS u_prior_funded,
           msbf_ctl.deterministic_uniform(c.population_id || '|' || lpad(g.merchant_sequence::text,6,'0'), c.deterministic_seed_version || ':M1_2:PRIOR_REPAY') AS u_prior_repay,
           msbf_ctl.deterministic_uniform(c.population_id || '|' || lpad(g.merchant_sequence::text,6,'0'), c.deterministic_seed_version || ':M1_2:DEPOSIT_RELATIONSHIP') AS u_deposit,
           msbf_ctl.deterministic_uniform(c.population_id || '|' || lpad(g.merchant_sequence::text,6,'0'), c.deterministic_seed_version || ':M1_2:WALLET_SHARE') AS u_wallet,
           msbf_ctl.deterministic_uniform(c.population_id || '|' || lpad(g.merchant_sequence::text,6,'0'), c.deterministic_seed_version || ':M1_2:SPLIT_FUNDING') AS u_split,
           msbf_ctl.deterministic_uniform(c.population_id || '|' || lpad(g.merchant_sequence::text,6,'0'), c.deterministic_seed_version || ':M1_2:SETTLEMENT_DELAY') AS u_settlement
    FROM ctx c
    CROSS JOIN LATERAL generate_series(1,c.merchant_count) AS g(merchant_sequence)
    JOIN industry_a ia ON ia.merchant_sequence=g.merchant_sequence
    JOIN region_a ra ON ra.merchant_sequence=g.merchant_sequence
    JOIN size_a sa ON sa.merchant_sequence=g.merchant_sequence
    JOIN relationship_a rla ON rla.merchant_sequence=g.merchant_sequence
    JOIN legal_a la ON la.merchant_sequence=g.merchant_sequence
    JOIN channel_a ca ON ca.merchant_sequence=g.merchant_sequence
), age_owner AS (
    SELECT s.*,
           least(s.months_max,
               s.months_min
               + floor((s.months_max-s.months_min+1)*power(s.u_age,1.45))::integer
               + CASE s.merchant_size_tier WHEN 'MICRO' THEN 0 WHEN 'SMALL' THEN 6 WHEN 'LOWER_MIDDLE' THEN 24 ELSE 48 END
               + CASE s.relationship_stage WHEN 'RETURNING_GOOD' THEN 12 WHEN 'RETURNING_MIXED' THEN 8 WHEN 'LOW_AND_GROW' THEN 4 ELSE 0 END
           )::integer AS months_in_business,
           least(s.owner_max, greatest(s.owner_min,
               CASE
                 WHEN s.legal_entity_type='SOLE_PROPRIETOR' THEN 1
                 WHEN s.legal_entity_type='PARTNERSHIP' THEN 2 + CASE WHEN s.u_owner_count>=0.65 THEN 1 ELSE 0 END
                 ELSE 1 + floor(s.u_owner_count*3)::integer
               END
           ))::integer AS owner_count
    FROM seeded s
), tenure AS (
    SELECT a.*,
           least(a.processor_max,a.months_in_business) AS processor_tenure_ceiling,
           least(
               least(a.processor_max,a.months_in_business),
               a.processor_min + floor(
                   (least(a.processor_max,a.months_in_business)-a.processor_min+1)*power(a.u_processor,1.25)
               )::integer
           )::integer AS processor_tenure_months
    FROM age_owner a
), ranked AS (
    SELECT t.*, sp.prior_advance_probability, sp.prior_default_probability,
           row_number() OVER (
               PARTITION BY t.relationship_stage
               ORDER BY t.u_prior_advance, t.merchant_sequence
           ) AS advance_rank,
           count(*) OVER (PARTITION BY t.relationship_stage) AS stage_count
    FROM tenure t
    JOIN stage_prob sp USING (relationship_stage)
), advance_flagged AS (
    SELECT r.*,
           (r.advance_rank<=round(r.stage_count*r.prior_advance_probability)::integer) AS prior_advance_flag
    FROM ranked r
), relationship_ranked AS (
    SELECT a.*,
           sum(CASE WHEN a.prior_advance_flag THEN 1 ELSE 0 END) OVER (
               PARTITION BY a.relationship_stage
               ORDER BY a.u_prior_default, a.merchant_sequence
               ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
           ) AS default_rank_among_advance,
           sum(CASE WHEN a.prior_advance_flag THEN 1 ELSE 0 END) OVER (
               PARTITION BY a.relationship_stage
               ORDER BY a.u_prior_interruption, a.merchant_sequence
               ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
           ) AS interruption_rank_among_advance
    FROM advance_flagged a
), flags AS (
    SELECT r.*,
           (r.prior_advance_flag AND
            r.default_rank_among_advance<=round(r.stage_count*r.prior_default_probability)::integer) AS prior_default_flag,
           (r.prior_advance_flag AND
            r.interruption_rank_among_advance<=round(r.stage_count *
                CASE r.relationship_stage
                    WHEN 'RETURNING_GOOD' THEN 0.03
                    WHEN 'RETURNING_MIXED' THEN 0.35
                    WHEN 'LOW_AND_GROW' THEN 0.15
                    ELSE 0.00
                END
            )::integer) AS interruption_base_flag
    FROM relationship_ranked r
), relationship_counts AS (
    SELECT f.*,
           (f.prior_default_flag OR f.interruption_base_flag) AS prior_payment_interruption_flag,
           CASE
             WHEN NOT f.prior_advance_flag THEN 0
             WHEN f.relationship_stage='NEW' THEN 1
             WHEN f.relationship_stage IN ('RETURNING_GOOD','RETURNING_MIXED') THEN 1+floor(f.u_prior_count*4)::integer
             ELSE 1+floor(f.u_prior_count*2)::integer
           END AS prior_advance_count
    FROM flags f
), relationship_amounts AS (
    SELECT r.*,
           greatest(0, r.prior_advance_count - CASE WHEN r.prior_default_flag OR r.prior_payment_interruption_flag THEN 1 ELSE 0 END) AS completed_advance_count,
           (CASE WHEN r.prior_advance_count=0 THEN 0.00::numeric
                 ELSE round((CASE r.merchant_size_tier
                     WHEN 'MICRO' THEN 15000
                     WHEN 'SMALL' THEN 35000
                     WHEN 'LOWER_MIDDLE' THEN 75000
                     ELSE 125000 END
                     * r.prior_advance_count * (0.8 + 0.4*r.u_prior_funded))::numeric,2)
            END)::numeric(18,2) AS total_prior_funded_amount,
           (r.u_deposit < least(0.95,
                CASE r.relationship_stage
                  WHEN 'NEW' THEN 0.22
                  WHEN 'RETURNING_GOOD' THEN 0.68
                  WHEN 'RETURNING_MIXED' THEN 0.48
                  ELSE 0.35 END
                + CASE WHEN r.partner_channel_id='CH_BANK_RELATIONSHIP' THEN 0.18 ELSE 0 END
           )) AS deposit_relationship_flag
    FROM relationship_counts r
), relationship_final AS (
    SELECT a.*,
           round((a.total_prior_funded_amount *
             CASE
               WHEN a.prior_default_flag THEN 0.72 + 0.12*a.u_prior_repay
               WHEN a.prior_payment_interruption_flag THEN 0.90 + 0.07*a.u_prior_repay
               ELSE 1.00
             END)::numeric,2)::numeric(18,2) AS total_prior_repaid_amount,
           round(least(0.95,greatest(0.05,
             CASE a.relationship_stage
               WHEN 'NEW' THEN 0.10 + 0.25*a.u_wallet
               WHEN 'RETURNING_GOOD' THEN 0.45 + 0.40*a.u_wallet
               WHEN 'RETURNING_MIXED' THEN 0.25 + 0.40*a.u_wallet
               ELSE 0.15 + 0.35*a.u_wallet
             END + CASE WHEN a.deposit_relationship_flag THEN 0.08 ELSE 0 END
           ))::numeric,6)::numeric(9,6) AS wallet_share_proxy
    FROM relationship_amounts a
), prepared AS (
    SELECT r.*,
           r.population_id || '_M' || lpad(r.merchant_sequence::text,6,'0') AS merchant_id,
           'Synthetic Merchant ' || lpad(r.merchant_sequence::text,6,'0') AS synthetic_business_name,
           (r.as_of_date-make_interval(months=>r.months_in_business))::date AS incorporation_date,
           CASE r.merchant_size_tier
             WHEN 'MICRO' THEN 'UNDER_250K'
             WHEN 'SMALL' THEN '250K_TO_1M'
             WHEN 'LOWER_MIDDLE' THEN '1M_TO_5M'
             ELSE '5M_TO_20M' END AS annual_sales_band,
           r.population_id || '_M' || lpad(r.merchant_sequence::text,6,'0') || '_P01' AS processor_account_id,
           CASE r.partner_channel_id
             WHEN 'CH_PROCESSOR_DIRECT' THEN 'Synthetic Processor Alpha'
             WHEN 'CH_BANK_RELATIONSHIP' THEN 'Synthetic Processor Beta'
             WHEN 'CH_DIGITAL_DIRECT' THEN 'Synthetic Processor Gamma'
             WHEN 'CH_STRATEGIC_PARTNER' THEN 'Synthetic Processor Delta'
             ELSE 'Synthetic Processor Epsilon' END AS processor_name_synthetic,
           (r.as_of_date-make_interval(months=>r.processor_tenure_months))::date AS processor_account_open_date,
           CASE
             WHEN r.partner_channel_id='CH_BROKER_NETWORK' THEN r.u_split<0.88
             WHEN r.partner_channel_id='CH_STRATEGIC_PARTNER' THEN r.u_split<0.95
             ELSE true END AS split_funding_capable_flag,
           (CASE r.partner_channel_id
             WHEN 'CH_PROCESSOR_DIRECT' THEN floor(r.u_settlement*2)::integer
             WHEN 'CH_BANK_RELATIONSHIP' THEN 1
             WHEN 'CH_DIGITAL_DIRECT' THEN 1+floor(r.u_settlement*2)::integer
             WHEN 'CH_STRATEGIC_PARTNER' THEN 1+floor(r.u_settlement*3)::integer
             ELSE 2+floor(r.u_settlement*3)::integer END)::smallint AS settlement_delay_days,
           (CASE r.partner_channel_id
             WHEN 'CH_PROCESSOR_DIRECT' THEN 1
             WHEN 'CH_BANK_RELATIONSHIP' THEN 1
             WHEN 'CH_DIGITAL_DIRECT' THEN 2
             WHEN 'CH_STRATEGIC_PARTNER' THEN 2
             ELSE 3 END)::smallint AS processor_risk_tier,
           (CASE
             WHEN r.prior_default_flag THEN 5
             WHEN r.relationship_stage='RETURNING_GOOD' THEN CASE WHEN r.wallet_share_proxy>=0.65 THEN 1 ELSE 2 END
             WHEN r.relationship_stage='RETURNING_MIXED' THEN CASE WHEN r.prior_payment_interruption_flag THEN 4 ELSE 3 END
             WHEN r.relationship_stage='LOW_AND_GROW' THEN 3
             ELSE CASE WHEN r.wallet_share_proxy>=0.25 THEN 2 ELSE 3 END
           END)::smallint AS relationship_quality_tier
    FROM relationship_final r
), hashed AS (
    SELECT p.*,
           md5(jsonb_build_object(
               'merchant_id',p.merchant_id,
               'population_id',p.population_id,
               'legal_entity_type',p.legal_entity_type,
               'region_code',p.region_code,
               'incorporation_date',p.incorporation_date,
               'merchant_size_tier',p.merchant_size_tier,
               'annual_sales_band',p.annual_sales_band,
               'industry_code',p.industry_code,
               'relationship_stage',p.relationship_stage,
               'owner_count',p.owner_count,
               'partner_channel_id',p.partner_channel_id,
               'processor_tenure_months',p.processor_tenure_months
           )::text) AS intrinsic_profile_hash,
           md5(jsonb_build_object(
               'merchant_id',p.merchant_id,
               'as_of_date',p.as_of_date,
               'relationship_stage',p.relationship_stage,
               'prior_advance_count',p.prior_advance_count,
               'completed_advance_count',p.completed_advance_count,
               'prior_default_flag',p.prior_default_flag,
               'prior_payment_interruption_flag',p.prior_payment_interruption_flag,
               'total_prior_funded_amount',p.total_prior_funded_amount::numeric(18,2),
               'total_prior_repaid_amount',p.total_prior_repaid_amount::numeric(18,2),
               'deposit_relationship_flag',p.deposit_relationship_flag,
               'merchant_services_relationship_flag',true,
               'wallet_share_proxy',p.wallet_share_proxy::numeric(9,6),
               'relationship_quality_tier',p.relationship_quality_tier
           )::text) AS relationship_snapshot_hash
    FROM prepared p
)
SELECT merchant_sequence, run_id, population_id, as_of_date,
       merchant_id, synthetic_business_name, legal_entity_type, region_code,
       incorporation_date, months_in_business, merchant_size_tier, annual_sales_band,
       industry_code, relationship_stage, owner_count, partner_channel_id,
       processor_account_id, processor_name_synthetic, processor_tenure_months,
       processor_account_open_date, split_funding_capable_flag,
       settlement_delay_days, processor_risk_tier,
       prior_advance_count, completed_advance_count, prior_default_flag,
       prior_payment_interruption_flag, total_prior_funded_amount,
       total_prior_repaid_amount, deposit_relationship_flag,
       true AS merchant_services_relationship_flag,
       wallet_share_proxy, relationship_quality_tier,
       intrinsic_profile_hash, relationship_snapshot_hash
FROM hashed
ORDER BY merchant_sequence;
$$;

/* -------------------------------------------------------------------------
   Owner/guarantor deterministic blueprint.
   ---------------------------------------------------------------------- */
CREATE OR REPLACE FUNCTION msbf_m1.m1_2_owner_blueprint(p_run_id bigint)
RETURNS TABLE (
    merchant_id text,
    party_id text,
    party_role text,
    effective_start_date date,
    ownership_rate numeric(9,6),
    owner_credit_score smallint,
    owner_credit_band text,
    major_derogatory_flag boolean,
    bankruptcy_flag boolean,
    personal_guarantee_available_flag boolean,
    guarantee_capacity_amount numeric(18,2),
    owner_row_hash text
)
LANGUAGE sql
STABLE
AS $$
WITH ctx AS (
    SELECT p.deterministic_seed_version
    FROM msbf_ctl.run_registry r
    JOIN msbf_m1.population_registry p ON p.population_id=r.population_id
    WHERE r.run_id=p_run_id
), b AS (
    SELECT * FROM msbf_m1.m1_2_population_blueprint(p_run_id)
), expanded AS (
    SELECT b.*, ctx.deterministic_seed_version, g.owner_sequence::integer AS owner_sequence,
           b.merchant_id || '_O' || lpad(g.owner_sequence::text,2,'0') AS party_id,
           b.population_id || '|' || lpad(b.merchant_sequence::text,6,'0') || '|O' || lpad(g.owner_sequence::text,2,'0') AS owner_key,
           CASE
             WHEN b.owner_count=1 THEN 1.000000
             WHEN b.owner_count=2 AND g.owner_sequence=1 THEN 0.600000
             WHEN b.owner_count=2 AND g.owner_sequence=2 THEN 0.400000
             WHEN b.owner_count=3 AND g.owner_sequence=1 THEN 0.500000
             WHEN b.owner_count=3 AND g.owner_sequence=2 THEN 0.300000
             ELSE 0.200000 END::numeric(9,6) AS ownership_rate
    FROM b
    CROSS JOIN ctx
    CROSS JOIN LATERAL generate_series(1,b.owner_count) AS g(owner_sequence)
), scored_raw AS (
    SELECT e.*,
           greatest(500,least(830,round(
             CASE e.relationship_stage
               WHEN 'NEW' THEN 680
               WHEN 'RETURNING_GOOD' THEN 725
               WHEN 'RETURNING_MIXED' THEN 635
               ELSE 650 END
             + CASE e.merchant_size_tier
               WHEN 'MICRO' THEN -20
               WHEN 'SMALL' THEN 0
               WHEN 'LOWER_MIDDLE' THEN 15
               ELSE 25 END
             + least(20,floor(e.months_in_business/24.0))
             + 45*msbf_ctl.deterministic_normal(e.owner_key,e.deterministic_seed_version || ':M1_2:OWNER_SCORE')
           )))::smallint AS owner_credit_score
    FROM expanded e
), banded AS (
    SELECT s.*,
           CASE
             WHEN s.owner_credit_score>=760 THEN 'SUPER_PRIME'
             WHEN s.owner_credit_score>=700 THEN 'PRIME'
             WHEN s.owner_credit_score>=640 THEN 'NEAR_PRIME'
             WHEN s.owner_credit_score>=580 THEN 'SUBPRIME'
             ELSE 'DEEP_SUBPRIME' END AS owner_credit_band,
           CASE
             WHEN s.owner_credit_score>=760 THEN 0.005
             WHEN s.owner_credit_score>=700 THEN 0.015
             WHEN s.owner_credit_score>=640 THEN 0.040
             WHEN s.owner_credit_score>=580 THEN 0.100
             ELSE 0.180 END AS derogatory_probability
    FROM scored_raw s
), adverse AS (
    SELECT b.*,
           (msbf_ctl.deterministic_uniform(b.owner_key,b.deterministic_seed_version || ':M1_2:OWNER_DEROG') < b.derogatory_probability) AS major_derogatory_flag
    FROM banded b
), bankruptcy AS (
    SELECT a.*,
           (a.major_derogatory_flag AND
            msbf_ctl.deterministic_uniform(a.owner_key,a.deterministic_seed_version || ':M1_2:OWNER_BANKRUPTCY') <
                CASE WHEN a.owner_credit_score>=640 THEN 0.08
                     WHEN a.owner_credit_score>=580 THEN 0.18 ELSE 0.30 END
           ) AS bankruptcy_flag
    FROM adverse a
), guarantee AS (
    SELECT b.*,
           (msbf_ctl.deterministic_uniform(b.owner_key,b.deterministic_seed_version || ':M1_2:GUARANTEE_AVAILABLE') <
             greatest(0,least(1,
               CASE WHEN b.legal_entity_type='SOLE_PROPRIETOR' THEN 0.95
                    WHEN b.owner_sequence=1 THEN 0.90 ELSE 0.55 END
               - CASE WHEN b.owner_credit_score<600 THEN 0.20 ELSE 0 END
               - CASE WHEN b.major_derogatory_flag THEN 0.15 ELSE 0 END
               - CASE WHEN b.bankruptcy_flag THEN 1.00 ELSE 0 END
             ))
           ) AS personal_guarantee_available_flag
    FROM bankruptcy b
), final AS (
    SELECT g.*,
           (CASE WHEN NOT g.personal_guarantee_available_flag THEN 0.00::numeric
                 ELSE round((CASE g.merchant_size_tier
                     WHEN 'MICRO' THEN 15000
                     WHEN 'SMALL' THEN 40000
                     WHEN 'LOWER_MIDDLE' THEN 90000
                     ELSE 160000 END
                   * g.ownership_rate
                   * greatest(0.35,least(1.40,(g.owner_credit_score-480)/250.0))
                   * (0.8+0.4*msbf_ctl.deterministic_uniform(g.owner_key,g.deterministic_seed_version || ':M1_2:GUARANTEE_CAPACITY'))
                 )::numeric,2)
            END)::numeric(18,2) AS guarantee_capacity_amount
    FROM guarantee g
)
SELECT f.merchant_id,
       f.party_id,
       CASE WHEN f.owner_sequence=1 THEN 'PRIMARY_OWNER_GUARANTOR' ELSE 'SECONDARY_OWNER_GUARANTOR' END AS party_role,
       f.incorporation_date AS effective_start_date,
       f.ownership_rate,
       f.owner_credit_score,
       f.owner_credit_band,
       f.major_derogatory_flag,
       f.bankruptcy_flag,
       f.personal_guarantee_available_flag,
       f.guarantee_capacity_amount::numeric(18,2),
       md5(jsonb_build_object(
           'merchant_id',f.merchant_id,
           'party_id',f.party_id,
           'party_role',CASE WHEN f.owner_sequence=1 THEN 'PRIMARY_OWNER_GUARANTOR' ELSE 'SECONDARY_OWNER_GUARANTOR' END,
           'effective_start_date',f.incorporation_date,
           'ownership_rate',f.ownership_rate::numeric(9,6),
           'owner_credit_score',f.owner_credit_score,
           'owner_credit_band',f.owner_credit_band,
           'major_derogatory_flag',f.major_derogatory_flag,
           'bankruptcy_flag',f.bankruptcy_flag,
           'personal_guarantee_available_flag',f.personal_guarantee_available_flag,
           'guarantee_capacity_amount',f.guarantee_capacity_amount::numeric(18,2)
       )::text) AS owner_row_hash
FROM final f
ORDER BY f.merchant_id, f.owner_sequence;
$$;

/* -------------------------------------------------------------------------
   Expected and actual canonical entity snapshots for deterministic rerun QA.
   ---------------------------------------------------------------------- */
CREATE OR REPLACE FUNCTION msbf_m1.m1_2_expected_entity_snapshot(p_run_id bigint)
RETURNS TABLE (entity_type text, entity_key text, row_hash text)
LANGUAGE sql
STABLE
AS $$
WITH ctx AS (
    SELECT r.run_id, p.history_start_date
    FROM msbf_ctl.run_registry r
    JOIN msbf_m1.population_registry p ON p.population_id=r.population_id
    WHERE r.run_id=p_run_id
), partner_expected AS (
    SELECT * FROM (VALUES
      ('CH_PROCESSOR_DIRECT','Synthetic Processor Direct','PROCESSOR_DIRECT',1::smallint,0.010000::numeric,true),
      ('CH_BANK_RELATIONSHIP','Synthetic Bank Relationship','BANK_RELATIONSHIP',1::smallint,0.007500::numeric,false),
      ('CH_DIGITAL_DIRECT','Synthetic Digital Direct','DIGITAL_DIRECT',2::smallint,0.018000::numeric,false),
      ('CH_STRATEGIC_PARTNER','Synthetic Strategic Partner','STRATEGIC_PARTNER',2::smallint,0.025000::numeric,false),
      ('CH_BROKER_NETWORK','Synthetic Broker Network','BROKER_NETWORK',3::smallint,0.045000::numeric,false)
    ) v(partner_channel_id,partner_name_synthetic,channel_type,partner_risk_tier,acquisition_cost_rate,processor_affiliated_flag)
), b AS (
    SELECT * FROM msbf_m1.m1_2_population_blueprint(p_run_id)
), o AS (
    SELECT * FROM msbf_m1.m1_2_owner_blueprint(p_run_id)
)
SELECT 'PARTNER_CHANNEL'::text,
       p.partner_channel_id,
       md5(jsonb_build_object(
         'partner_channel_id',p.partner_channel_id,
         'partner_name_synthetic',p.partner_name_synthetic,
         'channel_type',p.channel_type,
         'partner_risk_tier',p.partner_risk_tier,
         'acquisition_cost_rate',p.acquisition_cost_rate::numeric(9,6),
         'processor_affiliated_flag',p.processor_affiliated_flag,
         'effective_start_date',ctx.history_start_date,
         'status','ACTIVE'
       )::text)
FROM partner_expected p CROSS JOIN ctx
UNION ALL
SELECT 'MERCHANT_MASTER', b.merchant_id, b.intrinsic_profile_hash FROM b
UNION ALL
SELECT 'OWNER_GUARANTOR',
       o.merchant_id || '|' || o.party_id || '|' || o.party_role || '|' || o.effective_start_date::text,
       o.owner_row_hash
FROM o
UNION ALL
SELECT 'INDUSTRY_ASSIGNMENT',
       b.merchant_id || '|' || b.industry_code || '|' || b.incorporation_date::text,
       md5(jsonb_build_object(
         'merchant_id',b.merchant_id,'industry_code',b.industry_code,
         'assignment_type','PRIMARY','effective_start_date',b.incorporation_date,
         'revenue_share_rate',1.000000::numeric
       )::text)
FROM b
UNION ALL
SELECT 'PROCESSOR_ACCOUNT', b.processor_account_id,
       md5(jsonb_build_object(
         'processor_account_id',b.processor_account_id,'merchant_id',b.merchant_id,
         'partner_channel_id',b.partner_channel_id,'processor_name_synthetic',b.processor_name_synthetic,
         'processor_account_open_date',b.processor_account_open_date,'effective_start_date',b.processor_account_open_date,
         'processor_status','ACTIVE','data_connection_status','CONNECTED',
         'split_funding_capable_flag',b.split_funding_capable_flag,
         'settlement_delay_days',b.settlement_delay_days,'processor_risk_tier',b.processor_risk_tier
       )::text)
FROM b
UNION ALL
SELECT 'RELATIONSHIP_SNAPSHOT', b.merchant_id || '|' || b.as_of_date::text, b.relationship_snapshot_hash FROM b;
$$;

CREATE OR REPLACE FUNCTION msbf_m1.m1_2_actual_entity_snapshot(p_run_id bigint)
RETURNS TABLE (entity_type text, entity_key text, row_hash text)
LANGUAGE sql
STABLE
AS $$
WITH ctx AS (
    SELECT r.population_id, r.as_of_date
    FROM msbf_ctl.run_registry r
    WHERE r.run_id=p_run_id
), owner_counts AS (
    SELECT o.merchant_id, COUNT(*)::integer AS owner_count
    FROM msbf_m1.merchant_owner_guarantor o
    WHERE o.created_by_run_id=p_run_id
    GROUP BY o.merchant_id
), primary_industry AS (
    SELECT i.merchant_id, i.industry_code
    FROM msbf_m1.merchant_industry_assignment i
    WHERE i.created_by_run_id=p_run_id
      AND i.assignment_type='PRIMARY'
), merchant_context AS (
    SELECT m.*, pi.industry_code, rs.relationship_stage,
           oc.owner_count, pa.partner_channel_id,
           ((extract(year from age(ctx.as_of_date,pa.processor_account_open_date))*12)
             + extract(month from age(ctx.as_of_date,pa.processor_account_open_date)))::integer AS processor_tenure_months
    FROM msbf_m1.merchant_master m
    CROSS JOIN ctx
    JOIN primary_industry pi ON pi.merchant_id=m.merchant_id
    JOIN msbf_m1.merchant_relationship_snapshot rs
      ON rs.merchant_id=m.merchant_id
     AND rs.created_by_run_id=p_run_id
     AND rs.as_of_date=ctx.as_of_date
    JOIN owner_counts oc ON oc.merchant_id=m.merchant_id
    JOIN msbf_m1.processor_account pa
      ON pa.merchant_id=m.merchant_id
     AND pa.created_by_run_id=p_run_id
    WHERE m.population_id=ctx.population_id
      AND m.created_by_run_id=p_run_id
)
SELECT 'PARTNER_CHANNEL'::text,
       p.partner_channel_id,
       md5(jsonb_build_object(
         'partner_channel_id',p.partner_channel_id,
         'partner_name_synthetic',p.partner_name_synthetic,
         'channel_type',p.channel_type,
         'partner_risk_tier',p.partner_risk_tier,
         'acquisition_cost_rate',p.acquisition_cost_rate::numeric(9,6),
         'processor_affiliated_flag',p.processor_affiliated_flag,
         'effective_start_date',p.effective_start_date,
         'status',p.status
       )::text)
FROM msbf_m1.partner_channel p
WHERE p.created_by_run_id=p_run_id
UNION ALL
SELECT 'MERCHANT_MASTER', mc.merchant_id,
       md5(jsonb_build_object(
         'merchant_id',mc.merchant_id,
         'population_id',mc.population_id,
         'legal_entity_type',mc.legal_entity_type,
         'region_code',mc.region_code,
         'incorporation_date',mc.incorporation_date,
         'merchant_size_tier',mc.merchant_size_tier,
         'annual_sales_band',mc.annual_sales_band,
         'industry_code',mc.industry_code,
         'relationship_stage',mc.relationship_stage,
         'owner_count',mc.owner_count,
         'partner_channel_id',mc.partner_channel_id,
         'processor_tenure_months',mc.processor_tenure_months
       )::text)
FROM merchant_context mc
UNION ALL
SELECT 'OWNER_GUARANTOR',
       o.merchant_id || '|' || o.party_id || '|' || o.party_role || '|' || o.effective_start_date::text,
       md5(jsonb_build_object(
           'merchant_id',o.merchant_id,'party_id',o.party_id,'party_role',o.party_role,
           'effective_start_date',o.effective_start_date,'ownership_rate',o.ownership_rate::numeric(9,6),
           'owner_credit_score',o.owner_credit_score,'owner_credit_band',o.owner_credit_band,
           'major_derogatory_flag',o.major_derogatory_flag,'bankruptcy_flag',o.bankruptcy_flag,
           'personal_guarantee_available_flag',o.personal_guarantee_available_flag,
           'guarantee_capacity_amount',o.guarantee_capacity_amount::numeric(18,2)
       )::text)
FROM msbf_m1.merchant_owner_guarantor o
JOIN merchant_context mc ON mc.merchant_id=o.merchant_id
WHERE o.created_by_run_id=p_run_id
UNION ALL
SELECT 'INDUSTRY_ASSIGNMENT',
       i.merchant_id || '|' || i.industry_code || '|' || i.effective_start_date::text,
       md5(jsonb_build_object(
         'merchant_id',i.merchant_id,'industry_code',i.industry_code,
         'assignment_type',i.assignment_type,'effective_start_date',i.effective_start_date,
         'revenue_share_rate',i.revenue_share_rate::numeric(9,6)
       )::text)
FROM msbf_m1.merchant_industry_assignment i
JOIN merchant_context mc ON mc.merchant_id=i.merchant_id
WHERE i.created_by_run_id=p_run_id
UNION ALL
SELECT 'PROCESSOR_ACCOUNT', pa.processor_account_id,
       md5(jsonb_build_object(
         'processor_account_id',pa.processor_account_id,'merchant_id',pa.merchant_id,
         'partner_channel_id',pa.partner_channel_id,'processor_name_synthetic',pa.processor_name_synthetic,
         'processor_account_open_date',pa.processor_account_open_date,'effective_start_date',pa.effective_start_date,
         'processor_status',pa.processor_status,'data_connection_status',pa.data_connection_status,
         'split_funding_capable_flag',pa.split_funding_capable_flag,
         'settlement_delay_days',pa.settlement_delay_days,'processor_risk_tier',pa.processor_risk_tier
       )::text)
FROM msbf_m1.processor_account pa
JOIN merchant_context mc ON mc.merchant_id=pa.merchant_id
WHERE pa.created_by_run_id=p_run_id
UNION ALL
SELECT 'RELATIONSHIP_SNAPSHOT', rs.merchant_id || '|' || rs.as_of_date::text,
       md5(jsonb_build_object(
         'merchant_id',rs.merchant_id,
         'as_of_date',rs.as_of_date,
         'relationship_stage',rs.relationship_stage,
         'prior_advance_count',rs.prior_advance_count,
         'completed_advance_count',rs.completed_advance_count,
         'prior_default_flag',rs.prior_default_flag,
         'prior_payment_interruption_flag',rs.prior_payment_interruption_flag,
         'total_prior_funded_amount',rs.total_prior_funded_amount::numeric(18,2),
         'total_prior_repaid_amount',rs.total_prior_repaid_amount::numeric(18,2),
         'deposit_relationship_flag',rs.deposit_relationship_flag,
         'merchant_services_relationship_flag',rs.merchant_services_relationship_flag,
         'wallet_share_proxy',rs.wallet_share_proxy::numeric(9,6),
         'relationship_quality_tier',rs.relationship_quality_tier
       )::text)
FROM msbf_m1.merchant_relationship_snapshot rs
JOIN merchant_context mc ON mc.merchant_id=rs.merchant_id
WHERE rs.created_by_run_id=p_run_id;
$$;

/* -------------------------------------------------------------------------
   Generate the accepted baseline population exactly once.
   ---------------------------------------------------------------------- */
DO $$
DECLARE
    v_run_id bigint;
    v_history_start date;
    v_as_of_date date;
    v_expected_entities bigint;
    v_actual_entities bigint;
    v_mismatch_count bigint;
    v_mismatch_summary text;
    v_mismatch_examples text;
    v_expected_hash text;
    v_actual_hash text;
    v_generation_spec jsonb;
    v_generation_spec_hash text;
BEGIN
    SELECT r.run_id, p.history_start_date, r.as_of_date
      INTO STRICT v_run_id, v_history_start, v_as_of_date
      FROM msbf_ctl.run_registry r
      JOIN msbf_m1.population_registry p ON p.population_id=r.population_id
     WHERE r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1;

    PERFORM msbf_m1.m1_2_assert_generation_ready(v_run_id);

    v_generation_spec := jsonb_build_object(
      'stage_code','M1.2',
      'stage_version','v0.2',
      'population_method','largest_remainder_exact_mix_plus_deterministic_rank',
      'channel_weights',jsonb_build_object(
        'CH_PROCESSOR_DIRECT',0.34,'CH_BANK_RELATIONSHIP',0.18,
        'CH_DIGITAL_DIRECT',0.20,'CH_STRATEGIC_PARTNER',0.16,
        'CH_BROKER_NETWORK',0.12
      ),
      'age_transform_power',1.45,
      'processor_tenure_transform_power',1.25,
      'relationship_interruption_rates',jsonb_build_object(
        'NEW',0.00,'RETURNING_GOOD',0.03,'RETURNING_MIXED',0.35,'LOW_AND_GROW',0.15
      ),
      'owner_score_rule_version','OWNER_SCORE_V1',
      'synthetic_only',true,
      'production_use',false
    );
    v_generation_spec_hash := md5(v_generation_spec::text);

    INSERT INTO msbf_ctl.run_evidence (
        run_id,evidence_code,segment_key,metric_name,
        metric_value_text,unit_code,status,interpretation
    ) VALUES
      (v_run_id,'M1_2_GENERATION_SPEC','PORTFOLIO','M1.2 generation specification',
       v_generation_spec::text,'JSON_TEXT','INFO',
       'Code-owned deterministic structural assumptions supplement the frozen parameter set without altering G1 hashes.'),
      (v_run_id,'M1_2_GENERATION_SPEC_HASH','PORTFOLIO','M1.2 generation specification hash',
       v_generation_spec_hash,'MD5','PASS','Stable code-level generation specification identity.')
    ON CONFLICT (run_id,evidence_code,segment_key) DO UPDATE SET
      metric_name=EXCLUDED.metric_name, metric_value_numeric=NULL,
      metric_value_text=EXCLUDED.metric_value_text, unit_code=EXCLUDED.unit_code,
      status=EXCLUDED.status, threshold_value_numeric=NULL,
      interpretation=EXCLUDED.interpretation, created_at=clock_timestamp();

    INSERT INTO msbf_m1.partner_channel (
      partner_channel_id,partner_name_synthetic,channel_type,partner_risk_tier,
      acquisition_cost_rate,processor_affiliated_flag,effective_start_date,status,created_by_run_id
    ) VALUES
      ('CH_PROCESSOR_DIRECT','Synthetic Processor Direct','PROCESSOR_DIRECT',1,0.010000,true,v_history_start,'ACTIVE',v_run_id),
      ('CH_BANK_RELATIONSHIP','Synthetic Bank Relationship','BANK_RELATIONSHIP',1,0.007500,false,v_history_start,'ACTIVE',v_run_id),
      ('CH_DIGITAL_DIRECT','Synthetic Digital Direct','DIGITAL_DIRECT',2,0.018000,false,v_history_start,'ACTIVE',v_run_id),
      ('CH_STRATEGIC_PARTNER','Synthetic Strategic Partner','STRATEGIC_PARTNER',2,0.025000,false,v_history_start,'ACTIVE',v_run_id),
      ('CH_BROKER_NETWORK','Synthetic Broker Network','BROKER_NETWORK',3,0.045000,false,v_history_start,'ACTIVE',v_run_id);

    INSERT INTO msbf_m1.merchant_master (
      merchant_id,population_id,synthetic_business_name,legal_entity_type,region_code,
      incorporation_date,merchant_size_tier,annual_sales_band,base_currency,
      active_flag,synthetic_data_flag,created_date,intrinsic_profile_hash,created_by_run_id
    )
    SELECT merchant_id,population_id,synthetic_business_name,legal_entity_type,region_code,
           incorporation_date,merchant_size_tier,annual_sales_band,'USD',
           true,true,as_of_date,intrinsic_profile_hash,run_id
    FROM msbf_m1.m1_2_population_blueprint(v_run_id);

    INSERT INTO msbf_m1.merchant_industry_assignment (
      merchant_id,industry_code,assignment_type,effective_start_date,
      revenue_share_rate,created_by_run_id
    )
    SELECT merchant_id,industry_code,'PRIMARY',incorporation_date,1.000000,run_id
    FROM msbf_m1.m1_2_population_blueprint(v_run_id);

    INSERT INTO msbf_m1.processor_account (
      processor_account_id,merchant_id,partner_channel_id,processor_name_synthetic,
      processor_account_open_date,effective_start_date,processor_status,
      data_connection_status,split_funding_capable_flag,settlement_delay_days,
      processor_risk_tier,created_by_run_id
    )
    SELECT processor_account_id,merchant_id,partner_channel_id,processor_name_synthetic,
           processor_account_open_date,processor_account_open_date,'ACTIVE','CONNECTED',
           split_funding_capable_flag,settlement_delay_days,processor_risk_tier,run_id
    FROM msbf_m1.m1_2_population_blueprint(v_run_id);

    INSERT INTO msbf_m1.merchant_relationship_snapshot (
      merchant_id,as_of_date,relationship_stage,prior_advance_count,
      completed_advance_count,prior_default_flag,prior_payment_interruption_flag,
      total_prior_funded_amount,total_prior_repaid_amount,deposit_relationship_flag,
      merchant_services_relationship_flag,wallet_share_proxy,relationship_quality_tier,
      snapshot_hash,created_by_run_id
    )
    SELECT merchant_id,as_of_date,relationship_stage,prior_advance_count,
           completed_advance_count,prior_default_flag,prior_payment_interruption_flag,
           total_prior_funded_amount,total_prior_repaid_amount,deposit_relationship_flag,
           merchant_services_relationship_flag,wallet_share_proxy,relationship_quality_tier,
           relationship_snapshot_hash,run_id
    FROM msbf_m1.m1_2_population_blueprint(v_run_id);

    INSERT INTO msbf_m1.merchant_owner_guarantor (
      merchant_id,party_id,party_role,effective_start_date,ownership_rate,
      owner_credit_score,owner_credit_band,major_derogatory_flag,bankruptcy_flag,
      personal_guarantee_available_flag,guarantee_capacity_amount,
      synthetic_data_flag,created_by_run_id
    )
    SELECT merchant_id,party_id,party_role,effective_start_date,ownership_rate,
           owner_credit_score,owner_credit_band,major_derogatory_flag,bankruptcy_flag,
           personal_guarantee_available_flag,guarantee_capacity_amount,true,v_run_id
    FROM msbf_m1.m1_2_owner_blueprint(v_run_id);

    SELECT COUNT(*), md5(string_agg(entity_type || '|' || entity_key || '|' || row_hash,
                                    '||' ORDER BY entity_type,entity_key))
      INTO v_expected_entities, v_expected_hash
      FROM msbf_m1.m1_2_expected_entity_snapshot(v_run_id);

    SELECT COUNT(*), md5(string_agg(entity_type || '|' || entity_key || '|' || row_hash,
                                    '||' ORDER BY entity_type,entity_key))
      INTO v_actual_entities, v_actual_hash
      FROM msbf_m1.m1_2_actual_entity_snapshot(v_run_id);

    SELECT COUNT(*)
      INTO v_mismatch_count
      FROM (
        SELECT COALESCE(e.entity_type,a.entity_type) AS entity_type,
               COALESCE(e.entity_key,a.entity_key) AS entity_key,
               e.row_hash AS expected_hash,
               a.row_hash AS actual_hash
        FROM msbf_m1.m1_2_expected_entity_snapshot(v_run_id) e
        FULL JOIN msbf_m1.m1_2_actual_entity_snapshot(v_run_id) a
          ON a.entity_type=e.entity_type AND a.entity_key=e.entity_key
        WHERE e.row_hash IS DISTINCT FROM a.row_hash
      ) d;

    SELECT string_agg(entity_type || '=' || mismatch_rows::text, ', ' ORDER BY entity_type)
      INTO v_mismatch_summary
      FROM (
        SELECT COALESCE(e.entity_type,a.entity_type) AS entity_type,
               COUNT(*) AS mismatch_rows
        FROM msbf_m1.m1_2_expected_entity_snapshot(v_run_id) e
        FULL JOIN msbf_m1.m1_2_actual_entity_snapshot(v_run_id) a
          ON a.entity_type=e.entity_type AND a.entity_key=e.entity_key
        WHERE e.row_hash IS DISTINCT FROM a.row_hash
        GROUP BY COALESCE(e.entity_type,a.entity_type)
      ) s;

    SELECT string_agg(entity_type || ':' || entity_key, ', ' ORDER BY entity_type,entity_key)
      INTO v_mismatch_examples
      FROM (
        SELECT COALESCE(e.entity_type,a.entity_type) AS entity_type,
               COALESCE(e.entity_key,a.entity_key) AS entity_key
        FROM msbf_m1.m1_2_expected_entity_snapshot(v_run_id) e
        FULL JOIN msbf_m1.m1_2_actual_entity_snapshot(v_run_id) a
          ON a.entity_type=e.entity_type AND a.entity_key=e.entity_key
        WHERE e.row_hash IS DISTINCT FROM a.row_hash
        ORDER BY COALESCE(e.entity_type,a.entity_type),COALESCE(e.entity_key,a.entity_key)
        LIMIT 10
      ) x;

    IF v_expected_entities<>4352 THEN
        RAISE EXCEPTION 'M1.2 v0.2 expected 4,352 canonical entity rows; regenerated blueprint produced %.',
          v_expected_entities;
    END IF;

    IF v_expected_entities<>v_actual_entities OR v_mismatch_count<>0 OR v_expected_hash IS DISTINCT FROM v_actual_hash THEN
        RAISE EXCEPTION 'M1.2 persisted population does not match regenerated blueprint: expected entities %, actual %, mismatches %, mismatch summary %, examples %, expected hash %, actual hash %.',
          v_expected_entities,v_actual_entities,v_mismatch_count,
          COALESCE(v_mismatch_summary,'NONE'),COALESCE(v_mismatch_examples,'NONE'),
          v_expected_hash,v_actual_hash;
    END IF;

    UPDATE msbf_m1.population_registry
       SET population_status='M1_2_GENERATED',
           population_hash=v_actual_hash
     WHERE population_id=(SELECT population_id FROM msbf_ctl.run_registry WHERE run_id=v_run_id);

    UPDATE msbf_ctl.run_registry
       SET run_status='M1_2_GENERATED',
           started_at=COALESCE(started_at,clock_timestamp()),
           notes='M1.2 deterministic merchant population generated; validation and acceptance pending.'
     WHERE run_id=v_run_id;

    INSERT INTO msbf_ctl.run_evidence (
      run_id,evidence_code,segment_key,metric_name,
      metric_value_text,unit_code,status,interpretation
    ) VALUES (
      v_run_id,'M1_2_GENERATION_SUMMARY','PORTFOLIO','M1.2 deterministic generation summary',
      jsonb_build_object(
        'expected_entity_rows',v_expected_entities,
        'actual_entity_rows',v_actual_entities,
        'row_level_mismatches',v_mismatch_count,
        'population_hash',v_actual_hash,
        'generation_spec_hash',v_generation_spec_hash
      )::text,
      'JSON_TEXT','PASS',
      'Persisted M1.2 records exactly match the regenerated deterministic blueprint.'
    )
    ON CONFLICT (run_id,evidence_code,segment_key) DO UPDATE SET
      metric_name=EXCLUDED.metric_name,metric_value_numeric=NULL,
      metric_value_text=EXCLUDED.metric_value_text,unit_code=EXCLUDED.unit_code,
      status=EXCLUDED.status,threshold_value_numeric=NULL,
      interpretation=EXCLUDED.interpretation,created_at=clock_timestamp();
END
$$;

COMMIT;

WITH ctx AS (
  SELECT r.run_id,r.run_code,r.run_version,r.run_status,r.population_id,r.as_of_date,
         p.population_status,p.population_hash,p.merchant_count
  FROM msbf_ctl.run_registry r
  JOIN msbf_m1.population_registry p ON p.population_id=r.population_id
  WHERE r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1
)
SELECT ctx.*,
       (SELECT COUNT(*) FROM msbf_m1.merchant_master WHERE population_id=ctx.population_id) AS merchants,
       (SELECT COUNT(*) FROM msbf_m1.merchant_owner_guarantor o JOIN msbf_m1.merchant_master m ON m.merchant_id=o.merchant_id WHERE m.population_id=ctx.population_id) AS owner_rows,
       (SELECT COUNT(*) FROM msbf_m1.merchant_industry_assignment i JOIN msbf_m1.merchant_master m ON m.merchant_id=i.merchant_id WHERE m.population_id=ctx.population_id) AS industry_rows,
       (SELECT COUNT(*) FROM msbf_m1.partner_channel WHERE created_by_run_id=ctx.run_id) AS partner_channels,
       (SELECT COUNT(*) FROM msbf_m1.processor_account WHERE created_by_run_id=ctx.run_id) AS processor_accounts,
       (SELECT COUNT(*) FROM msbf_m1.merchant_relationship_snapshot WHERE created_by_run_id=ctx.run_id) AS relationship_snapshots,
       (SELECT COUNT(*) FROM msbf_m1.m1_2_expected_entity_snapshot(ctx.run_id)) AS expected_entity_rows,
       (SELECT COUNT(*) FROM msbf_m1.m1_2_actual_entity_snapshot(ctx.run_id)) AS actual_entity_rows
FROM ctx;
