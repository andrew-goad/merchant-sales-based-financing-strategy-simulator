/* ============================================================================
MSBF M1.2 Deterministic Merchant Population — Positive Validation
Version : v0.2R2
Purpose : Recompute the M1.2 blueprint, reconcile persisted records, validate
          exact governed mixes, temporal integrity, mixed-signal realism, and
          unchanged G1 configuration hashes.
============================================================================ */

BEGIN;

DO $$
DECLARE
    v_run_id bigint;
    v_status text;
BEGIN
    SELECT run_id,run_status INTO STRICT v_run_id,v_status
    FROM msbf_ctl.run_registry
    WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
    FOR UPDATE;

    IF v_status='M1_2_ACCEPTED' THEN
        RAISE EXCEPTION 'M1.2 is already accepted; positive validation evidence is frozen.';
    END IF;
    IF v_status NOT IN ('M1_2_GENERATED','M1_2_VALIDATED','M1_2_FAILED') THEN
        RAISE EXCEPTION 'M1.2 validation requires generated population; observed run_status=%',v_status;
    END IF;

    DELETE FROM msbf_ctl.run_evidence
    WHERE run_id=v_run_id AND evidence_code LIKE 'M1_2_POS_%';
END
$$;

CREATE TEMP TABLE _m1_2_checks (
    evidence_code text PRIMARY KEY,
    metric_name text NOT NULL,
    observed_value text NOT NULL,
    expected_value text NOT NULL,
    pass_flag boolean NOT NULL,
    interpretation text NOT NULL
) ON COMMIT DROP;

/* 01 — run stage status */
INSERT INTO _m1_2_checks
SELECT 'M1_2_POS_01_RUN_STAGE_STATUS','Run stage status',run_status,
       'M1_2_GENERATED or M1_2_VALIDATED or M1_2_FAILED',
       run_status IN ('M1_2_GENERATED','M1_2_VALIDATED','M1_2_FAILED'),
       'Population must exist before validation.'
FROM msbf_ctl.run_registry
WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1;

/* 02 — accepted G1 gate */
INSERT INTO _m1_2_checks
SELECT 'M1_2_POS_02_G1_GATE','Latest G1 gate status',COALESCE(result_status,'MISSING'),'PASS',
       result_status='PASS','M1.2 remains dependent on accepted G1 configuration.'
FROM (
  SELECT result_status FROM msbf_ctl.acceptance_gate_result
  WHERE run_id=(SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1)
    AND gate_id='G1_CONTROL_PLANE'
  ORDER BY review_version DESC LIMIT 1
) x;

/* 03 — exact accepted G1 hashes */
INSERT INTO _m1_2_checks
SELECT 'M1_2_POS_03_ACCEPTED_G1_HASHES','Accepted G1 hashes',
       parameter_snapshot_hash||'|'||profile_snapshot_hash||'|'||source_snapshot_hash,
       'bd09e598c82db96e47459d77fd11e7c8|462cbd2ed92f68e5bdecf6b17537a973|93c3d1368fb2450ab4a08e2b721f92d3',
       parameter_snapshot_hash='bd09e598c82db96e47459d77fd11e7c8'
       AND profile_snapshot_hash='462cbd2ed92f68e5bdecf6b17537a973'
       AND source_snapshot_hash='93c3d1368fb2450ab4a08e2b721f92d3',
       'M1.2 must not alter the formally accepted G1 snapshots.'
FROM msbf_ctl.run_registry
WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1;

/* 04 — independent G1 hash recomputation */
INSERT INTO _m1_2_checks
WITH ctx AS (
  SELECT * FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
), h AS (
  SELECT
   (SELECT md5(string_agg(parameter_name||'|'||scope_key||'|'||snapshot_hash,'||' ORDER BY parameter_name,scope_key))
      FROM msbf_ctl.run_parameter_snapshot WHERE run_id=ctx.run_id) AS ph,
   (SELECT md5(string_agg(profile_domain||'|'||profile_code||'|'||profile_version::text||'|'||profile_hash,'||' ORDER BY profile_domain,profile_code))
      FROM msbf_ctl.run_profile_snapshot WHERE run_id=ctx.run_id) AS prh,
   (SELECT md5(string_agg(source_code||'|'||to_char(source_cutoff_timestamp AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS.US')||'|'||source_hash||'|'||quality_status,'||' ORDER BY source_code))
      FROM msbf_ctl.run_source_snapshot WHERE run_id=ctx.run_id) AS sh
  FROM ctx
)
SELECT 'M1_2_POS_04_RECOMPUTED_G1_HASHES','Recomputed G1 hash reconciliation',
       h.ph||'|'||h.prh||'|'||h.sh,
       ctx.parameter_snapshot_hash||'|'||ctx.profile_snapshot_hash||'|'||ctx.source_snapshot_hash,
       h.ph=ctx.parameter_snapshot_hash AND h.prh=ctx.profile_snapshot_hash AND h.sh=ctx.source_snapshot_hash,
       'Frozen parameter, profile, and source content independently reconcile.'
FROM ctx CROSS JOIN h;

/* 05 — population status */
INSERT INTO _m1_2_checks
SELECT 'M1_2_POS_05_POPULATION_STATUS','Population status',population_status,'M1_2_GENERATED',
       population_status='M1_2_GENERATED','Population registry reflects generated but not yet accepted status.'
FROM msbf_m1.population_registry
WHERE population_id='MSBF_POP_0001';

/* 06 — generation specification integrity */
INSERT INTO _m1_2_checks
WITH r AS (
  SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
), s AS (
  SELECT metric_value_text FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM r) AND evidence_code='M1_2_GENERATION_SPEC' AND segment_key='PORTFOLIO'
), h AS (
  SELECT metric_value_text FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM r) AND evidence_code='M1_2_GENERATION_SPEC_HASH' AND segment_key='PORTFOLIO'
)
SELECT 'M1_2_POS_06_GENERATION_SPEC','Generation specification hash',COALESCE(h.metric_value_text,'MISSING'),
       COALESCE(md5((s.metric_value_text::jsonb)::text),'MISSING'),
       h.metric_value_text=md5((s.metric_value_text::jsonb)::text),
       'Code-owned M1.2 structural assumptions are frozen and hash-reconciled.'
FROM s FULL JOIN h ON true;

/* 07 — merchant row count */
INSERT INTO _m1_2_checks
WITH ctx AS (SELECT population_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1)
SELECT 'M1_2_POS_07_MERCHANT_COUNT','Merchant row count',COUNT(*)::text,'750',COUNT(*)=750,
       'One merchant row exists for every planned population member.'
FROM msbf_m1.merchant_master m CROSS JOIN ctx WHERE m.population_id=ctx.population_id;

/* 08 — merchant identity uniqueness and contiguous sequence */
INSERT INTO _m1_2_checks
WITH ctx AS (SELECT population_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), x AS (
 SELECT COUNT(*) AS rows,COUNT(DISTINCT merchant_id) AS ids,
        MIN(substring(merchant_id from '_M([0-9]{6})$')::integer) AS min_seq,
        MAX(substring(merchant_id from '_M([0-9]{6})$')::integer) AS max_seq,
        COUNT(DISTINCT substring(merchant_id from '_M([0-9]{6})$')::integer) AS seqs
 FROM msbf_m1.merchant_master m CROSS JOIN ctx WHERE m.population_id=ctx.population_id
)
SELECT 'M1_2_POS_08_MERCHANT_IDENTITY','Merchant identity and sequence',
       format('rows=%s ids=%s min=%s max=%s seqs=%s',rows,ids,min_seq,max_seq,seqs),
       'rows=750 ids=750 min=1 max=750 seqs=750',
       rows=750 AND ids=750 AND min_seq=1 AND max_seq=750 AND seqs=750,
       'Merchant keys and population sequence are unique and complete.' FROM x;

/* 09 — synthetic identity boundary */
INSERT INTO _m1_2_checks
WITH ctx AS (SELECT population_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), x AS (
 SELECT COUNT(*) FILTER (WHERE synthetic_data_flag AND synthetic_business_name ~ '^Synthetic Merchant [0-9]{6}$' AND base_currency='USD') AS valid_rows,
        COUNT(*) AS total_rows
 FROM msbf_m1.merchant_master m CROSS JOIN ctx WHERE m.population_id=ctx.population_id
)
SELECT 'M1_2_POS_09_SYNTHETIC_IDENTITY','Synthetic identity boundary',valid_rows::text,total_rows::text,
       valid_rows=total_rows AND total_rows=750,
       'No real business names, payment-account data, or PII are generated.' FROM x;

/* 10 — primary industry assignment completeness */
INSERT INTO _m1_2_checks
WITH ctx AS (SELECT population_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), x AS (
 SELECT COUNT(*) AS rows,COUNT(DISTINCT i.merchant_id) AS merchants,
        COUNT(*) FILTER (WHERE assignment_type='PRIMARY' AND revenue_share_rate=1) AS valid_rows
 FROM msbf_m1.merchant_industry_assignment i JOIN msbf_m1.merchant_master m ON m.merchant_id=i.merchant_id CROSS JOIN ctx
 WHERE m.population_id=ctx.population_id
)
SELECT 'M1_2_POS_10_INDUSTRY_COMPLETENESS','Primary industry assignment',
       format('rows=%s merchants=%s valid=%s',rows,merchants,valid_rows),'rows=750 merchants=750 valid=750',
       rows=750 AND merchants=750 AND valid_rows=750,
       'Every merchant has exactly one complete primary industry assignment.' FROM x;

/* 11-15 — exact governed mix reconciliation */
INSERT INTO _m1_2_checks
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1),
exp AS (SELECT category_code,target_count FROM msbf_m1.m1_2_weighted_assignment((SELECT run_id FROM r),'industry_mix_weight','INDUSTRY','INDUSTRY') GROUP BY category_code,target_count),
act AS (SELECT i.industry_code AS category_code,COUNT(*) AS actual_count FROM msbf_m1.merchant_industry_assignment i JOIN msbf_m1.merchant_master m ON m.merchant_id=i.merchant_id WHERE m.population_id='MSBF_POP_0001' GROUP BY i.industry_code),
d AS (SELECT COUNT(*) AS mismatches FROM exp FULL JOIN act USING(category_code) WHERE COALESCE(exp.target_count,0)<>COALESCE(act.actual_count,0))
SELECT 'M1_2_POS_11_INDUSTRY_MIX','Industry mix mismatch count',mismatches::text,'0',mismatches=0,'Largest-remainder industry quotas reconcile exactly.' FROM d;

INSERT INTO _m1_2_checks
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1),
exp AS (SELECT category_code,target_count FROM msbf_m1.m1_2_weighted_assignment((SELECT run_id FROM r),'region_mix_weight','REGION','REGION') GROUP BY category_code,target_count),
act AS (SELECT region_code AS category_code,COUNT(*) AS actual_count FROM msbf_m1.merchant_master WHERE population_id='MSBF_POP_0001' GROUP BY region_code),
d AS (SELECT COUNT(*) AS mismatches FROM exp FULL JOIN act USING(category_code) WHERE COALESCE(exp.target_count,0)<>COALESCE(act.actual_count,0))
SELECT 'M1_2_POS_12_REGION_MIX','Region mix mismatch count',mismatches::text,'0',mismatches=0,'Synthetic region quotas reconcile exactly.' FROM d;

INSERT INTO _m1_2_checks
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1),
exp AS (SELECT category_code,target_count FROM msbf_m1.m1_2_weighted_assignment((SELECT run_id FROM r),'merchant_size_mix_weight','MERCHANT_SIZE_TIER','MERCHANT_SIZE') GROUP BY category_code,target_count),
act AS (SELECT merchant_size_tier AS category_code,COUNT(*) AS actual_count FROM msbf_m1.merchant_master WHERE population_id='MSBF_POP_0001' GROUP BY merchant_size_tier),
d AS (SELECT COUNT(*) AS mismatches FROM exp FULL JOIN act USING(category_code) WHERE COALESCE(exp.target_count,0)<>COALESCE(act.actual_count,0))
SELECT 'M1_2_POS_13_SIZE_MIX','Merchant-size mix mismatch count',mismatches::text,'0',mismatches=0,'Merchant-size quotas reconcile exactly.' FROM d;

INSERT INTO _m1_2_checks
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1),
exp AS (SELECT category_code,target_count FROM msbf_m1.m1_2_weighted_assignment((SELECT run_id FROM r),'relationship_stage_mix_weight','RELATIONSHIP_STAGE','RELATIONSHIP') GROUP BY category_code,target_count),
act AS (SELECT relationship_stage AS category_code,COUNT(*) AS actual_count FROM msbf_m1.merchant_relationship_snapshot WHERE created_by_run_id=(SELECT run_id FROM r) GROUP BY relationship_stage),
d AS (SELECT COUNT(*) AS mismatches FROM exp FULL JOIN act USING(category_code) WHERE COALESCE(exp.target_count,0)<>COALESCE(act.actual_count,0))
SELECT 'M1_2_POS_14_RELATIONSHIP_MIX','Relationship-stage mix mismatch count',mismatches::text,'0',mismatches=0,'Relationship-stage quotas reconcile exactly.' FROM d;

INSERT INTO _m1_2_checks
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1),
exp AS (SELECT category_code,target_count FROM msbf_m1.m1_2_weighted_assignment((SELECT run_id FROM r),'legal_entity_mix_weight','LEGAL_ENTITY_TYPE','LEGAL_ENTITY') GROUP BY category_code,target_count),
act AS (SELECT legal_entity_type AS category_code,COUNT(*) AS actual_count FROM msbf_m1.merchant_master WHERE population_id='MSBF_POP_0001' GROUP BY legal_entity_type),
d AS (SELECT COUNT(*) AS mismatches FROM exp FULL JOIN act USING(category_code) WHERE COALESCE(exp.target_count,0)<>COALESCE(act.actual_count,0))
SELECT 'M1_2_POS_15_LEGAL_ENTITY_MIX','Legal-entity mix mismatch count',mismatches::text,'0',mismatches=0,'Legal-entity quotas reconcile exactly.' FROM d;

/* 16 — partner channel catalog */
INSERT INTO _m1_2_checks
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), d AS (
 SELECT COUNT(*) AS rows,
        COUNT(*) FILTER (WHERE entity_type='PARTNER_CHANNEL') AS actual_entities,
        (SELECT COUNT(*) FROM msbf_m1.m1_2_expected_entity_snapshot((SELECT run_id FROM r)) WHERE entity_type='PARTNER_CHANNEL') AS expected_entities,
        (SELECT COUNT(*) FROM (
          SELECT e.entity_key,e.row_hash,a.row_hash actual_hash
          FROM msbf_m1.m1_2_expected_entity_snapshot((SELECT run_id FROM r)) e
          FULL JOIN msbf_m1.m1_2_actual_entity_snapshot((SELECT run_id FROM r)) a USING(entity_type,entity_key)
          WHERE COALESCE(e.entity_type,a.entity_type)='PARTNER_CHANNEL' AND e.row_hash IS DISTINCT FROM a.row_hash
        ) q) AS mismatches
 FROM msbf_m1.m1_2_actual_entity_snapshot((SELECT run_id FROM r)) WHERE entity_type='PARTNER_CHANNEL'
)
SELECT 'M1_2_POS_16_PARTNER_CHANNELS','Partner-channel definitions',
       format('rows=%s expected=%s mismatches=%s',actual_entities,expected_entities,mismatches),
       'rows=5 expected=5 mismatches=0',
       actual_entities=5 AND expected_entities=5 AND mismatches=0,
       'Five synthetic channel definitions match the governed M1.2 generation specification.' FROM d;

/* 17 — exact channel assignment mix */
INSERT INTO _m1_2_checks
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1),
exp AS (SELECT category_code,target_count FROM msbf_m1.m1_2_weighted_assignment_json((SELECT run_id FROM r),'{"CH_PROCESSOR_DIRECT":0.34,"CH_BANK_RELATIONSHIP":0.18,"CH_DIGITAL_DIRECT":0.20,"CH_STRATEGIC_PARTNER":0.16,"CH_BROKER_NETWORK":0.12}'::jsonb,'CHANNEL') GROUP BY category_code,target_count),
act AS (SELECT partner_channel_id AS category_code,COUNT(*) AS actual_count FROM msbf_m1.processor_account WHERE created_by_run_id=(SELECT run_id FROM r) GROUP BY partner_channel_id),
d AS (SELECT COUNT(*) AS mismatches FROM exp FULL JOIN act USING(category_code) WHERE COALESCE(exp.target_count,0)<>COALESCE(act.actual_count,0))
SELECT 'M1_2_POS_17_CHANNEL_MIX','Partner-channel assignment mismatch count',mismatches::text,'0',mismatches=0,'Code-owned exact channel quotas reconcile.' FROM d;

/* 18 — one processor account per merchant */
INSERT INTO _m1_2_checks
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), x AS (
 SELECT COUNT(*) AS rows,COUNT(DISTINCT merchant_id) AS merchants,
        COUNT(*) FILTER (WHERE processor_status='ACTIVE' AND data_connection_status='CONNECTED') AS ready_rows
 FROM msbf_m1.processor_account WHERE created_by_run_id=(SELECT run_id FROM r)
)
SELECT 'M1_2_POS_18_PROCESSOR_COMPLETENESS','Processor-account completeness',
       format('rows=%s merchants=%s ready=%s',rows,merchants,ready_rows),'rows=750 merchants=750 ready=750',
       rows=750 AND merchants=750 AND ready_rows=750,
       'Every merchant has one active, connected synthetic processor account.' FROM x;

/* 19 — months-in-business bounds */
INSERT INTO _m1_2_checks
WITH r AS (SELECT run_id,as_of_date FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), p AS (
 SELECT
  (SELECT ((NULLIF(resolved_value ->> 'value_numeric',''))::numeric)::integer FROM msbf_ctl.run_parameter_snapshot WHERE run_id=(SELECT run_id FROM r) AND parameter_name='months_in_business_min' AND scope_key='GLOBAL') AS min_m,
  (SELECT ((NULLIF(resolved_value ->> 'value_numeric',''))::numeric)::integer FROM msbf_ctl.run_parameter_snapshot WHERE run_id=(SELECT run_id FROM r) AND parameter_name='months_in_business_max' AND scope_key='GLOBAL') AS max_m
), x AS (
 SELECT MIN(((extract(year from age(r.as_of_date,m.incorporation_date))*12)+extract(month from age(r.as_of_date,m.incorporation_date)))::integer) AS obs_min,
        MAX(((extract(year from age(r.as_of_date,m.incorporation_date))*12)+extract(month from age(r.as_of_date,m.incorporation_date)))::integer) AS obs_max,
        COUNT(*) FILTER (WHERE ((extract(year from age(r.as_of_date,m.incorporation_date))*12)+extract(month from age(r.as_of_date,m.incorporation_date)))::integer NOT BETWEEN p.min_m AND p.max_m) AS violations
 FROM msbf_m1.merchant_master m CROSS JOIN r CROSS JOIN p WHERE m.population_id='MSBF_POP_0001'
)
SELECT 'M1_2_POS_19_BUSINESS_AGE','Months-in-business bounds',format('min=%s max=%s violations=%s',obs_min,obs_max,violations),
       format('within %s-%s months; 0 violations',(SELECT min_m FROM p),(SELECT max_m FROM p)),
       violations=0,'Business age remains within governed bounds.' FROM x;

/* 20 — processor tenure bounds and business-age relationship */
INSERT INTO _m1_2_checks
WITH r AS (SELECT run_id,as_of_date FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), p AS (
 SELECT
  (SELECT ((NULLIF(resolved_value ->> 'value_numeric',''))::numeric)::integer FROM msbf_ctl.run_parameter_snapshot WHERE run_id=(SELECT run_id FROM r) AND parameter_name='processor_tenure_min_months' AND scope_key='GLOBAL') AS min_p,
  (SELECT ((NULLIF(resolved_value ->> 'value_numeric',''))::numeric)::integer FROM msbf_ctl.run_parameter_snapshot WHERE run_id=(SELECT run_id FROM r) AND parameter_name='processor_tenure_max_months' AND scope_key='GLOBAL') AS max_p
), x AS (
 SELECT MIN(((extract(year from age(r.as_of_date,a.processor_account_open_date))*12)+extract(month from age(r.as_of_date,a.processor_account_open_date)))::integer) AS obs_min,
        MAX(((extract(year from age(r.as_of_date,a.processor_account_open_date))*12)+extract(month from age(r.as_of_date,a.processor_account_open_date)))::integer) AS obs_max,
        COUNT(*) FILTER (WHERE ((extract(year from age(r.as_of_date,a.processor_account_open_date))*12)+extract(month from age(r.as_of_date,a.processor_account_open_date)))::integer NOT BETWEEN p.min_p AND p.max_p
             OR a.processor_account_open_date<m.incorporation_date) AS violations
 FROM msbf_m1.processor_account a JOIN msbf_m1.merchant_master m ON m.merchant_id=a.merchant_id CROSS JOIN r CROSS JOIN p
 WHERE a.created_by_run_id=r.run_id
)
SELECT 'M1_2_POS_20_PROCESSOR_TENURE','Processor tenure and chronology',format('min=%s max=%s violations=%s',obs_min,obs_max,violations),
       format('within %s-%s months; 0 chronology violations',(SELECT min_p FROM p),(SELECT max_p FROM p)),
       violations=0,'Processor tenure is bounded and never exceeds business age.' FROM x;

/* 21 — owner row count matches regenerated blueprint */
INSERT INTO _m1_2_checks
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), x AS (
 SELECT (SELECT COUNT(*) FROM msbf_m1.m1_2_owner_blueprint((SELECT run_id FROM r))) AS expected_rows,
        (SELECT COUNT(*) FROM msbf_m1.merchant_owner_guarantor o JOIN msbf_m1.merchant_master m ON m.merchant_id=o.merchant_id WHERE m.population_id='MSBF_POP_0001') AS actual_rows
)
SELECT 'M1_2_POS_21_OWNER_ROW_COUNT','Owner/guarantor row count',actual_rows::text,'1347',
       actual_rows=expected_rows AND actual_rows=1347,
       'Owner/guarantor density matches the deterministic blueprint and the frozen v0.2 regression count.' FROM x;

/* 22 — owner count per merchant */
INSERT INTO _m1_2_checks
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), x AS (
 SELECT COUNT(*) AS mismatch_count,
        MIN(actual_count) AS observed_min,MAX(actual_count) AS observed_max
 FROM (
   SELECT b.merchant_id,b.owner_count,COUNT(o.party_id)::integer AS actual_count
   FROM msbf_m1.m1_2_population_blueprint((SELECT run_id FROM r)) b
   LEFT JOIN msbf_m1.merchant_owner_guarantor o ON o.merchant_id=b.merchant_id
   GROUP BY b.merchant_id,b.owner_count
   HAVING COUNT(o.party_id)::integer<>b.owner_count
 ) d
), bounds AS (
 SELECT MIN(c) AS observed_min,MAX(c) AS observed_max FROM (
  SELECT merchant_id,COUNT(*) AS c
  FROM msbf_m1.merchant_owner_guarantor
  WHERE created_by_run_id=(SELECT run_id FROM r)
  GROUP BY merchant_id
 ) q
)
SELECT 'M1_2_POS_22_OWNER_COUNT_PER_MERCHANT','Owner count per merchant',
       format('mismatches=%s min=%s max=%s',x.mismatch_count,bounds.observed_min,bounds.observed_max),
       'mismatches=0 min>=1 max<=3',
       x.mismatch_count=0 AND bounds.observed_min>=1 AND bounds.observed_max<=3,
       'Every merchant has the expected one-to-three owner/guarantor records.' FROM x CROSS JOIN bounds;

/* 23 — ownership shares */
INSERT INTO _m1_2_checks
WITH r AS (
 SELECT run_id FROM msbf_ctl.run_registry
 WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
), x AS (
 SELECT COUNT(*) AS violations FROM (
  SELECT merchant_id,SUM(ownership_rate) AS ownership_sum
  FROM msbf_m1.merchant_owner_guarantor
  WHERE created_by_run_id=(SELECT run_id FROM r)
  GROUP BY merchant_id
  HAVING abs(SUM(ownership_rate)-1.0)>0.000001
 ) q
)
SELECT 'M1_2_POS_23_OWNERSHIP_SUM','Owner ownership-rate reconciliation',violations::text,'0',violations=0,
       'Ownership rates sum to one for each merchant.' FROM x;

/* 24 — owner score and band consistency */
INSERT INTO _m1_2_checks
WITH r AS (
 SELECT run_id FROM msbf_ctl.run_registry
 WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
), x AS (
 SELECT COUNT(*) FILTER (WHERE owner_credit_score NOT BETWEEN 300 AND 850) AS score_violations,
        COUNT(*) FILTER (WHERE owner_credit_band IS DISTINCT FROM CASE
             WHEN owner_credit_score>=760 THEN 'SUPER_PRIME'
             WHEN owner_credit_score>=700 THEN 'PRIME'
             WHEN owner_credit_score>=640 THEN 'NEAR_PRIME'
             WHEN owner_credit_score>=580 THEN 'SUBPRIME'
             ELSE 'DEEP_SUBPRIME' END) AS band_violations,
        MIN(owner_credit_score) AS min_score,MAX(owner_credit_score) AS max_score
 FROM msbf_m1.merchant_owner_guarantor
 WHERE created_by_run_id=(SELECT run_id FROM r)
)
SELECT 'M1_2_POS_24_OWNER_CREDIT','Owner credit-score and band integrity',
       format('min=%s max=%s score_violations=%s band_violations=%s',min_score,max_score,score_violations,band_violations),
       'scores 300-850; 0 score and band violations',score_violations=0 AND band_violations=0,
       'Synthetic owner scores are bounded and bands are derived consistently.' FROM x;

/* 25 — owner synthetic data boundary */
INSERT INTO _m1_2_checks
WITH r AS (
 SELECT run_id FROM msbf_ctl.run_registry
 WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
), x AS (
 SELECT COUNT(*) AS rows,
        COUNT(*) FILTER (WHERE synthetic_data_flag AND party_id ~ '^MSBF_POP_0001_M[0-9]{6}_O[0-9]{2}$') AS valid_rows
 FROM msbf_m1.merchant_owner_guarantor
 WHERE created_by_run_id=(SELECT run_id FROM r)
)
SELECT 'M1_2_POS_25_OWNER_SYNTHETIC_BOUNDARY','Owner synthetic-data boundary',valid_rows::text,rows::text,
       valid_rows=rows AND rows>0,'Owner records contain only synthetic identifiers and modeled risk fields.' FROM x;

/* 26 — relationship snapshot completeness */
INSERT INTO _m1_2_checks
WITH r AS (SELECT run_id,as_of_date FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), x AS (
 SELECT COUNT(*) AS rows,COUNT(DISTINCT merchant_id) AS merchants,
        COUNT(*) FILTER (WHERE as_of_date=(SELECT as_of_date FROM r)) AS asof_rows
 FROM msbf_m1.merchant_relationship_snapshot WHERE created_by_run_id=(SELECT run_id FROM r)
)
SELECT 'M1_2_POS_26_RELATIONSHIP_COMPLETENESS','Relationship snapshot completeness',
       format('rows=%s merchants=%s asof=%s',rows,merchants,asof_rows),'rows=750 merchants=750 asof=750',
       rows=750 AND merchants=750 AND asof_rows=750,
       'One as-of relationship snapshot exists per merchant.' FROM x;

/* 27 — relationship values match regenerated blueprint */
INSERT INTO _m1_2_checks
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), d AS (
 SELECT COUNT(*) AS mismatches
 FROM msbf_m1.m1_2_expected_entity_snapshot((SELECT run_id FROM r)) e
 FULL JOIN msbf_m1.m1_2_actual_entity_snapshot((SELECT run_id FROM r)) a USING(entity_type,entity_key)
 WHERE COALESCE(e.entity_type,a.entity_type)='RELATIONSHIP_SNAPSHOT'
   AND e.row_hash IS DISTINCT FROM a.row_hash
)
SELECT 'M1_2_POS_27_RELATIONSHIP_REPRODUCIBILITY','Relationship snapshot row mismatches',mismatches::text,'0',mismatches=0,
       'Relationship history and wallet fields exactly match regenerated values.' FROM d;

/* 28 — temporal integrity */
INSERT INTO _m1_2_checks
WITH r AS (SELECT run_id,as_of_date FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), x AS (
 SELECT
   (SELECT COUNT(*) FROM msbf_m1.merchant_master WHERE population_id='MSBF_POP_0001' AND (incorporation_date>(SELECT as_of_date FROM r) OR created_date>(SELECT as_of_date FROM r)))
 + (SELECT COUNT(*) FROM msbf_m1.merchant_owner_guarantor WHERE created_by_run_id=(SELECT run_id FROM r) AND ( effective_start_date>(SELECT as_of_date FROM r) OR (effective_end_date IS NOT NULL AND effective_end_date<=effective_start_date)))
 + (SELECT COUNT(*) FROM msbf_m1.merchant_industry_assignment WHERE created_by_run_id=(SELECT run_id FROM r) AND ( effective_start_date>(SELECT as_of_date FROM r) OR (effective_end_date IS NOT NULL AND effective_end_date<=effective_start_date)))
 + (SELECT COUNT(*) FROM msbf_m1.partner_channel WHERE created_by_run_id=(SELECT run_id FROM r) AND (effective_start_date>(SELECT as_of_date FROM r) OR (effective_end_date IS NOT NULL AND effective_end_date<=effective_start_date)))
 + (SELECT COUNT(*) FROM msbf_m1.processor_account WHERE created_by_run_id=(SELECT run_id FROM r) AND (processor_account_open_date>(SELECT as_of_date FROM r) OR effective_start_date>(SELECT as_of_date FROM r) OR (effective_end_date IS NOT NULL AND effective_end_date<=effective_start_date)))
 + (SELECT COUNT(*) FROM msbf_m1.merchant_relationship_snapshot WHERE created_by_run_id=(SELECT run_id FROM r) AND as_of_date>(SELECT as_of_date FROM r)) AS violations
)
SELECT 'M1_2_POS_28_TEMPORAL_INTEGRITY','Future-date and effective-date violations',violations::text,'0',violations=0,
       'No generated intrinsic or relationship attribute uses future information.' FROM x;

/* 29 — mixed-signal realism */
INSERT INTO _m1_2_checks
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), lim AS (
 SELECT (snapshot_payload->>'hard_limit_value')::numeric AS hard_limit
 FROM msbf_ctl.run_profile_snapshot WHERE run_id=(SELECT run_id FROM r)
   AND profile_domain='RISK_APPETITE_LIMIT' AND profile_code='M1_MIN_MIXED_SIGNAL_SHARE'
), primary_owner AS (
 SELECT * FROM msbf_m1.merchant_owner_guarantor WHERE party_role='PRIMARY_OWNER_GUARANTOR' AND created_by_run_id=(SELECT run_id FROM r)
), x AS (
 SELECT COUNT(*) FILTER (WHERE
        (o.owner_credit_score>=700 AND (s.relationship_stage='RETURNING_MIXED' OR s.prior_payment_interruption_flag OR s.prior_default_flag))
     OR (o.owner_credit_score<640 AND s.relationship_stage='RETURNING_GOOD' AND NOT s.prior_default_flag)
     OR ((((extract(year from age(s.as_of_date,m.incorporation_date))*12)+extract(month from age(s.as_of_date,m.incorporation_date)))::integer)<24 AND o.owner_credit_score>=720)
     OR (m.merchant_size_tier IN ('LOWER_MIDDLE','MIDDLE') AND o.owner_credit_score<620)
 ) AS mixed_rows,COUNT(*) AS total_rows
 FROM msbf_m1.merchant_master m
 JOIN msbf_m1.merchant_relationship_snapshot s ON s.merchant_id=m.merchant_id AND s.created_by_run_id=(SELECT run_id FROM r)
 JOIN primary_owner o ON o.merchant_id=m.merchant_id
 WHERE m.population_id='MSBF_POP_0001'
)
SELECT 'M1_2_POS_29_MIXED_SIGNAL_REALISM','Mixed-signal merchant share',
       round(mixed_rows::numeric/NULLIF(total_rows,0),6)::text,(SELECT hard_limit::text FROM lim),
       mixed_rows::numeric/NULLIF(total_rows,0)>=(SELECT hard_limit FROM lim),
       'Population preserves meaningful overlap between owner quality, relationship history, age, and size.' FROM x;

/* 30 — expected and actual entity counts */
INSERT INTO _m1_2_checks
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), x AS (
 SELECT (SELECT COUNT(*) FROM msbf_m1.m1_2_expected_entity_snapshot((SELECT run_id FROM r))) AS expected_rows,
        (SELECT COUNT(*) FROM msbf_m1.m1_2_actual_entity_snapshot((SELECT run_id FROM r))) AS actual_rows
)
SELECT 'M1_2_POS_30_ENTITY_COUNTS','Canonical entity row counts',actual_rows::text,'4352',
       actual_rows=expected_rows AND actual_rows=4352,
       'Persisted and regenerated entity universes match the frozen v0.2 regression cardinality.' FROM x;

/* 31 — exact row-level deterministic comparison */
INSERT INTO _m1_2_checks
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), d AS (
 SELECT COUNT(*) AS mismatches
 FROM msbf_m1.m1_2_expected_entity_snapshot((SELECT run_id FROM r)) e
 FULL JOIN msbf_m1.m1_2_actual_entity_snapshot((SELECT run_id FROM r)) a USING(entity_type,entity_key)
 WHERE e.row_hash IS DISTINCT FROM a.row_hash
)
SELECT 'M1_2_POS_31_ROW_LEVEL_RERUN','Row-level deterministic rerun mismatches',mismatches::text,'0',mismatches=0,
       'A complete regenerated blueprint exactly matches every persisted M1.2 entity row.' FROM d;

/* 32 — comprehensive population hash */
INSERT INTO _m1_2_checks
WITH r AS (SELECT run_id,population_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), x AS (
 SELECT
  (SELECT md5(string_agg(entity_type||'|'||entity_key||'|'||row_hash,'||' ORDER BY entity_type,entity_key)) FROM msbf_m1.m1_2_expected_entity_snapshot((SELECT run_id FROM r))) AS expected_hash,
  (SELECT md5(string_agg(entity_type||'|'||entity_key||'|'||row_hash,'||' ORDER BY entity_type,entity_key)) FROM msbf_m1.m1_2_actual_entity_snapshot((SELECT run_id FROM r))) AS actual_hash,
  (SELECT population_hash FROM msbf_m1.population_registry WHERE population_id=(SELECT population_id FROM r)) AS stored_hash
)
SELECT 'M1_2_POS_32_POPULATION_HASH','Population hash reconciliation',stored_hash,expected_hash,
       stored_hash=expected_hash AND actual_hash=expected_hash,
       'Stored, regenerated, and actual comprehensive population hashes are identical.' FROM x;

/* 33 — no applications */
INSERT INTO _m1_2_checks
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), x AS (
 SELECT COUNT(*) AS rows FROM msbf_m1.merchant_application WHERE created_by_run_id=(SELECT run_id FROM r)
)
SELECT 'M1_2_POS_33_NO_APPLICATIONS','Application rows after M1.2',rows::text,'0',rows=0,
       'Application generation remains outside the M1.2 boundary.' FROM x;

/* 34 — no downstream analytical rows */
INSERT INTO _m1_2_checks
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), x AS (
 SELECT
      (SELECT COUNT(*) FROM msbf_m1.source_snapshot WHERE module1_run_id=(SELECT run_id FROM r))
    + (SELECT COUNT(*) FROM msbf_m1.application_obligation_snapshot WHERE created_by_run_id=(SELECT run_id FROM r))
    + (SELECT COUNT(*) FROM msbf_m1.collateral_availability_snapshot WHERE created_by_run_id=(SELECT run_id FROM r))
    + (SELECT COUNT(*) FROM msbf_m1.guarantee_availability_snapshot WHERE created_by_run_id=(SELECT run_id FROM r))
    + (SELECT COUNT(*) FROM msbf_m1.application_business_credit_snapshot WHERE created_by_run_id=(SELECT run_id FROM r))
    + (SELECT COUNT(*) FROM msbf_m1.application_owner_credit_snapshot WHERE created_by_run_id=(SELECT run_id FROM r))
    + (SELECT COUNT(*) FROM msbf_m1.merchant_pos_daily_base WHERE generated_by_run_id=(SELECT run_id FROM r))
    + (SELECT COUNT(*) FROM msbf_m1.merchant_pos_daily_scenario WHERE generated_by_run_id=(SELECT run_id FROM r))
    + (SELECT COUNT(*) FROM msbf_m1.merchant_deposit_daily_base WHERE generated_by_run_id=(SELECT run_id FROM r))
    + (SELECT COUNT(*) FROM msbf_m1.merchant_deposit_daily_scenario WHERE generated_by_run_id=(SELECT run_id FROM r))
    + (SELECT COUNT(*) FROM msbf_m1.verification_result WHERE created_by_run_id=(SELECT run_id FROM r))
    + (SELECT COUNT(*) FROM msbf_m1.merchant_feature_snapshot WHERE module1_run_id=(SELECT run_id FROM r))
    + (SELECT COUNT(*) FROM msbf_m1.feature_value WHERE module1_run_id=(SELECT run_id FROM r))
    + (SELECT COUNT(*) FROM msbf_m1.merchant_risk_snapshot WHERE module1_run_id=(SELECT run_id FROM r))
    + (SELECT COUNT(*) FROM msbf_m1.risk_component_detail WHERE module1_run_id=(SELECT run_id FROM r))
    + (SELECT COUNT(*) FROM msbf_m1.ead_path_snapshot WHERE module1_run_id=(SELECT run_id FROM r))
    + (SELECT COUNT(*) FROM msbf_m1.module1_latest WHERE module1_run_id=(SELECT run_id FROM r))
    + (SELECT COUNT(*) FROM msbf_m1.module1_archive WHERE module1_run_id=(SELECT run_id FROM r)) AS rows
)
SELECT 'M1_2_POS_34_NO_DOWNSTREAM_ROWS','Downstream analytical rows after M1.2',rows::text,'0',rows=0,
       'POS, deposit, feature, risk, EAD, latest, and archive stages remain unexecuted.' FROM x;

/* 35 — source-contract snapshot unchanged */
INSERT INTO _m1_2_checks
WITH r AS (SELECT run_id,source_snapshot_hash FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), x AS (
 SELECT COUNT(*) AS rows,
        COUNT(*) FILTER (WHERE quality_status='CONTRACT_READY_PRE_GENERATION') AS ready_rows,
        COUNT(*) FILTER (WHERE source_row_count=0) AS zero_rows,
        md5(string_agg(source_code||'|'||to_char(source_cutoff_timestamp AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS.US')||'|'||source_hash||'|'||quality_status,'||' ORDER BY source_code)) AS hash
 FROM msbf_ctl.run_source_snapshot WHERE run_id=(SELECT run_id FROM r)
)
SELECT 'M1_2_POS_35_SOURCE_SNAPSHOT','G1 source snapshot unchanged',
       format('rows=%s ready=%s zero=%s hash=%s',rows,ready_rows,zero_rows,hash),
       format('rows=7 ready=7 zero=7 hash=%s',(SELECT source_snapshot_hash FROM r)),
       rows=7 AND ready_rows=7 AND zero_rows=7 AND hash=(SELECT source_snapshot_hash FROM r),
       'M1.2 creates intrinsic population records without changing source-contract evidence.' FROM x;

/* 36 — no blocking configuration errors */
INSERT INTO _m1_2_checks
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1), x AS (
 SELECT COUNT(*) AS rows FROM msbf_ctl.profile_resolution_error WHERE run_id=(SELECT run_id FROM r) AND severity='BLOCKING'
)
SELECT 'M1_2_POS_36_NO_BLOCKING_ERRORS','Blocking configuration errors',rows::text,'0',rows=0,
       'No unresolved blocking parameter, profile, or source issue exists.' FROM x;

/* Persist evidence and set validation status. */
WITH r AS (SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1)
INSERT INTO msbf_ctl.run_evidence (
    run_id,evidence_code,segment_key,metric_name,
    metric_value_text,unit_code,status,interpretation
)
SELECT r.run_id,c.evidence_code,'PORTFOLIO',c.metric_name,
       c.observed_value || ' | expected=' || c.expected_value,
       'TEXT',CASE WHEN c.pass_flag THEN 'PASS' ELSE 'FAIL' END,c.interpretation
FROM r CROSS JOIN _m1_2_checks c
ON CONFLICT (run_id,evidence_code,segment_key) DO UPDATE SET
    metric_name=EXCLUDED.metric_name,metric_value_numeric=NULL,
    metric_value_text=EXCLUDED.metric_value_text,unit_code=EXCLUDED.unit_code,
    status=EXCLUDED.status,threshold_value_numeric=NULL,
    interpretation=EXCLUDED.interpretation,created_at=clock_timestamp();

DO $$
DECLARE
    v_run_id bigint;
    v_count integer;
    v_pass integer;
BEGIN
    SELECT run_id INTO STRICT v_run_id FROM msbf_ctl.run_registry
    WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1 FOR UPDATE;
    SELECT COUNT(*),COUNT(*) FILTER (WHERE pass_flag) INTO v_count,v_pass FROM _m1_2_checks;
    IF v_count<>36 THEN
        RAISE EXCEPTION 'M1.2 positive validation expected 36 checks; observed %.',v_count;
    END IF;
    UPDATE msbf_ctl.run_registry
       SET run_status=CASE WHEN v_pass=36 THEN 'M1_2_VALIDATED' ELSE 'M1_2_FAILED' END,
           notes=CASE WHEN v_pass=36
                      THEN 'M1.2 positive validation passed. Negative controls and acceptance finalization remain.'
                      ELSE 'M1.2 positive validation failed; generation remains unaccepted.' END
     WHERE run_id=v_run_id;
END
$$;

COMMIT;

SELECT evidence_code,metric_name,status,metric_value_text,interpretation
FROM msbf_ctl.run_evidence
WHERE run_id=(SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1)
  AND evidence_code LIKE 'M1_2_POS_%'
ORDER BY evidence_code;
