/* ============================================================================
MSBF M1.15 Positive Validation
Program : 111_msbf_m1_15_consumption_contract_validation_v0_2R3.sql
Version : v0.2R3
Purpose : Validate contract cardinality, lineage, immutability, latest/archive
          identity, matched comparisons, worsening indicators, physical hashes,
          set hashes, source reproduction, and stage boundaries.
Output  : One filterable 84-row result set preserved after COMMIT.
============================================================================ */

BEGIN;
SET LOCAL work_mem='64MB';
SET LOCAL jit=off;
SET LOCAL statement_timeout='15min';

DROP TABLE IF EXISTS _m1_15_vctx;
CREATE TEMP TABLE _m1_15_vctx ON COMMIT PRESERVE ROWS AS
SELECT run_id,run_status,population_id,as_of_date
FROM msbf_ctl.run_registry
WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1;

DROP TABLE IF EXISTS _m1_15_vlatest;
CREATE TEMP TABLE _m1_15_vlatest ON COMMIT PRESERVE ROWS AS
SELECT * FROM msbf_m1.application_module1_latest
WHERE module1_run_id=(SELECT run_id FROM _m1_15_vctx);
CREATE UNIQUE INDEX ON _m1_15_vlatest(module1_run_id,scenario_id,merchant_application_id);

DROP TABLE IF EXISTS _m1_15_varchive;
CREATE TEMP TABLE _m1_15_varchive ON COMMIT PRESERVE ROWS AS
SELECT * FROM msbf_m1.application_module1_archive
WHERE module1_run_id=(SELECT run_id FROM _m1_15_vctx);
CREATE UNIQUE INDEX ON _m1_15_varchive(module1_run_id,contract_version,scenario_id,merchant_application_id);

DROP TABLE IF EXISTS _m1_15_vcomparison;
CREATE TEMP TABLE _m1_15_vcomparison ON COMMIT PRESERVE ROWS AS
SELECT * FROM msbf_m1.application_module1_scenario_comparison
WHERE module1_run_id=(SELECT run_id FROM _m1_15_vctx);
CREATE UNIQUE INDEX ON _m1_15_vcomparison(module1_run_id,merchant_application_id);

/* ---------------------------------------------------------------------------
Matched M1.11 archetype interpretation

M1.11's accepted adverse-scenario contract floors the final resilience tier and
the archetype risk rank. It does not floor the continuous resilience score.
This materialized pair allows M1.15 to validate the accepted interpretation
contract without overwriting or reinterpreting the upstream score evidence.
--------------------------------------------------------------------------- */
DROP TABLE IF EXISTS _m1_15_varchetype_pair;
CREATE TEMP TABLE _m1_15_varchetype_pair ON COMMIT PRESERVE ROWS AS
SELECT
    b.module1_run_id,
    b.merchant_application_id,
    b.archetype_code AS baseline_archetype_code,
    s.archetype_code AS stress_archetype_code,
    CASE b.archetype_code
      WHEN 'GROWING' THEN 1
      WHEN 'STABLE' THEN 1
      WHEN 'SEASONAL' THEN 2
      WHEN 'VOLATILE' THEN 3
      WHEN 'DECLINING' THEN 4
      WHEN 'DISRUPTED' THEN 4
      ELSE 5
    END::smallint AS baseline_archetype_risk_rank,
    CASE s.archetype_code
      WHEN 'GROWING' THEN 1
      WHEN 'STABLE' THEN 1
      WHEN 'SEASONAL' THEN 2
      WHEN 'VOLATILE' THEN 3
      WHEN 'DECLINING' THEN 4
      WHEN 'DISRUPTED' THEN 4
      ELSE 5
    END::smallint AS stress_archetype_risk_rank
FROM _m1_15_vlatest b
JOIN _m1_15_vlatest s
  ON s.module1_run_id=b.module1_run_id
 AND s.merchant_application_id=b.merchant_application_id
WHERE b.scenario_code='BASELINE'
  AND s.scenario_code='RECESSION_ENERGY';
CREATE UNIQUE INDEX ON _m1_15_varchetype_pair(module1_run_id,merchant_application_id);
ANALYZE _m1_15_varchetype_pair;

DROP TABLE IF EXISTS _m1_15_vcontract;
CREATE TEMP TABLE _m1_15_vcontract ON COMMIT PRESERVE ROWS AS
SELECT * FROM msbf_ctl.m1_15_consumption_contract_registry
WHERE module1_run_id=(SELECT run_id FROM _m1_15_vctx);

ANALYZE _m1_15_vlatest;
ANALYZE _m1_15_varchive;
ANALYZE _m1_15_vcomparison;

DROP TABLE IF EXISTS _m1_15_validation;
CREATE TEMP TABLE _m1_15_validation(
    evidence_code text PRIMARY KEY,
    metric_name text NOT NULL,
    observed_value text,
    threshold_value text,
    status text NOT NULL,
    interpretation text NOT NULL
) ON COMMIT PRESERVE ROWS;

CREATE OR REPLACE FUNCTION pg_temp.m1_15_add_check(
    p_code text,p_name text,p_observed text,p_threshold text,
    p_pass boolean,p_interpretation text
)
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO _m1_15_validation(
        evidence_code,metric_name,observed_value,threshold_value,status,interpretation
    )
    VALUES(
        p_code,p_name,coalesce(p_observed,'NULL'),coalesce(p_threshold,'NULL'),
        CASE WHEN p_pass THEN 'PASS' ELSE 'FAIL' END,
        p_interpretation
    );
END;
$$;

DO $checks$
BEGIN
    PERFORM pg_temp.m1_15_add_check(
        'M1_15_POS_01_RUN_STATUS',
        'Run status',
        ((SELECT run_status FROM _m1_15_vctx))::text,
        ('M1_15_GENERATED')::text,
        coalesce(((SELECT run_status='M1_15_GENERATED' FROM _m1_15_vctx)),false),
        'Validation begins only from committed M1.15 generation.'
    );
    PERFORM pg_temp.m1_15_add_check(
        'M1_15_POS_02_M1_14_GATE',
        'M1.14 accepted gate',
        ((SELECT count(*)::text FROM msbf_ctl.acceptance_gate_result g WHERE g.run_id=(SELECT run_id FROM _m1_15_vctx) AND g.gate_id='M1_14_UNIT_ECONOMICS_CONTRIBUTION' AND g.result_status='PASS'))::text,
        ('at least 1')::text,
        coalesce(((SELECT count(*)>0 FROM msbf_ctl.acceptance_gate_result g WHERE g.run_id=(SELECT run_id FROM _m1_15_vctx) AND g.gate_id='M1_14_UNIT_ECONOMICS_CONTRIBUTION' AND g.result_status='PASS')),false),
        'M1.15 depends on accepted M1.14.'
    );
    PERFORM pg_temp.m1_15_add_check(
        'M1_15_POS_03_M1_14_HASH',
        'M1.14 combined hash',
        ((SELECT metric_value_text FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM _m1_15_vctx) AND evidence_code='M1_14_COMBINED_SET_HASH' AND segment_key='PORTFOLIO'))::text,
        ('non-null')::text,
        coalesce(((SELECT metric_value_text IS NOT NULL FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM _m1_15_vctx) AND evidence_code='M1_14_COMBINED_SET_HASH' AND segment_key='PORTFOLIO')),false),
        'Accepted upstream M1.14 identity remains present.'
    );
    PERFORM pg_temp.m1_15_add_check(
        'M1_15_POS_04_POLICY',
        'Approved policy',
        ((SELECT count(*)::text FROM msbf_ctl.policy_profile WHERE profile_code='M1_15_CONSUMPTION_CONTRACT' AND profile_version=1 AND status='APPROVED'))::text,
        ('1')::text,
        coalesce(((SELECT count(*)=1 FROM msbf_ctl.policy_profile WHERE profile_code='M1_15_CONSUMPTION_CONTRACT' AND profile_version=1 AND status='APPROVED')),false),
        'Exactly one approved M1.15 policy.'
    );
    PERFORM pg_temp.m1_15_add_check(
        'M1_15_POS_05_CONTRACT_REGISTRY_COUNT',
        'Contract registry rows',
        ((SELECT count(*)::text FROM _m1_15_vcontract))::text,
        ('1')::text,
        coalesce(((SELECT count(*)=1 FROM _m1_15_vcontract)),false),
        'One governed contract registry row.'
    );
    PERFORM pg_temp.m1_15_add_check(
        'M1_15_POS_06_LATEST_COUNT',
        'Latest rows',
        ((SELECT count(*)::text FROM _m1_15_vlatest))::text,
        ('1500')::text,
        coalesce(((SELECT count(*)=1500 FROM _m1_15_vlatest)),false),
        'One latest row per application and accepted scenario.'
    );
    PERFORM pg_temp.m1_15_add_check(
        'M1_15_POS_07_ARCHIVE_COUNT',
        'Archive rows',
        ((SELECT count(*)::text FROM _m1_15_varchive))::text,
        ('1500')::text,
        coalesce(((SELECT count(*)=1500 FROM _m1_15_varchive)),false),
        'Archive exactly reproduces latest cardinality.'
    );
    PERFORM pg_temp.m1_15_add_check(
        'M1_15_POS_08_COMPARISON_COUNT',
        'Comparison rows',
        ((SELECT count(*)::text FROM _m1_15_vcomparison))::text,
        ('750')::text,
        coalesce(((SELECT count(*)=750 FROM _m1_15_vcomparison)),false),
        'One matched comparison per application.'
    );
    PERFORM pg_temp.m1_15_add_check(
        'M1_15_POS_09_APPLICATION_COUNT',
        'Applications',
        ((SELECT count(DISTINCT merchant_application_id)::text FROM _m1_15_vlatest))::text,
        ('750')::text,
        coalesce(((SELECT count(DISTINCT merchant_application_id)=750 FROM _m1_15_vlatest)),false),
        'All applications represented.'
    );
    PERFORM pg_temp.m1_15_add_check(
        'M1_15_POS_10_SCENARIO_COUNT',
        'Scenarios',
        ((SELECT count(DISTINCT scenario_id)::text FROM _m1_15_vlatest))::text,
        ('2')::text,
        coalesce(((SELECT count(DISTINCT scenario_id)=2 FROM _m1_15_vlatest)),false),
        'Exactly two accepted scenarios.'
    );
    PERFORM pg_temp.m1_15_add_check(
        'M1_15_POS_11_BASELINE_COUNT',
        'Baseline rows',
        ((SELECT count(*)::text FROM _m1_15_vlatest WHERE scenario_code='BASELINE'))::text,
        ('750')::text,
        coalesce(((SELECT count(*)=750 FROM _m1_15_vlatest WHERE scenario_code='BASELINE')),false),
        'Baseline coverage complete.'
    );
    PERFORM pg_temp.m1_15_add_check(
        'M1_15_POS_12_STRESS_COUNT',
        'Stress rows',
        ((SELECT count(*)::text FROM _m1_15_vlatest WHERE scenario_code='RECESSION_ENERGY'))::text,
        ('750')::text,
        coalesce(((SELECT count(*)=750 FROM _m1_15_vlatest WHERE scenario_code='RECESSION_ENERGY')),false),
        'Stress coverage complete.'
    );
    PERFORM pg_temp.m1_15_add_check(
        'M1_15_POS_13_LATEST_UNIQUE',
        'Latest unique grain',
        ((SELECT count(*)-count(DISTINCT (module1_run_id,scenario_id,merchant_application_id)) FROM _m1_15_vlatest)::text)::text,
        ('0')::text,
        coalesce(((SELECT count(*)=count(DISTINCT (module1_run_id,scenario_id,merchant_application_id)) FROM _m1_15_vlatest)),false),
        'Latest grain is unique.'
    );
    PERFORM pg_temp.m1_15_add_check(
        'M1_15_POS_14_ARCHIVE_UNIQUE',
        'Archive unique grain',
        ((SELECT count(*)-count(DISTINCT (module1_run_id,contract_version,scenario_id,merchant_application_id)) FROM _m1_15_varchive)::text)::text,
        ('0')::text,
        coalesce(((SELECT count(*)=count(DISTINCT (module1_run_id,contract_version,scenario_id,merchant_application_id)) FROM _m1_15_varchive)),false),
        'Archive grain is unique.'
    );
    PERFORM pg_temp.m1_15_add_check(
        'M1_15_POS_15_COMPARISON_UNIQUE',
        'Comparison unique grain',
        ((SELECT count(*)-count(DISTINCT (module1_run_id,merchant_application_id)) FROM _m1_15_vcomparison)::text)::text,
        ('0')::text,
        coalesce(((SELECT count(*)=count(DISTINCT (module1_run_id,merchant_application_id)) FROM _m1_15_vcomparison)),false),
        'Comparison grain is unique.'
    );
    PERFORM pg_temp.m1_15_add_check(
        'M1_15_POS_16_CONTRACT_IDENTITY',
        'Contract identity',
        ((SELECT contract_code||'|v'||contract_version FROM _m1_15_vcontract))::text,
        ('M1_APPLICATION_CONSUMPTION|v1')::text,
        coalesce(((SELECT contract_code='M1_APPLICATION_CONSUMPTION' AND contract_version=1 FROM _m1_15_vcontract)),false),
        'Governed contract identity is stable.'
    );
    PERFORM pg_temp.m1_15_add_check(
        'M1_15_POS_17_SCHEMA_VERSION',
        'Schema version',
        ((SELECT schema_version FROM _m1_15_vcontract))::text,
        ('M1_CONTRACT_SCHEMA_V1')::text,
        coalesce(((SELECT schema_version='M1_CONTRACT_SCHEMA_V1' FROM _m1_15_vcontract)),false),
        'Schema version is controlled.'
    );
    PERFORM pg_temp.m1_15_add_check(
        'M1_15_POS_18_CONTRACT_STATUS',
        'Contract lifecycle status',
        ((SELECT contract_status FROM _m1_15_vcontract))::text,
        ('GENERATED')::text,
        coalesce(((SELECT contract_status='GENERATED' FROM _m1_15_vcontract)),false),
        'Validation begins from generated contract state.'
    );
    PERFORM pg_temp.m1_15_add_check(
        'M1_15_POS_19_SCENARIO_LINEAGE',
        'Scenario lineage violations',
        ((SELECT count(*)::text FROM _m1_15_vlatest l LEFT JOIN msbf_ctl.scenario_registry sr ON sr.scenario_id=l.scenario_id WHERE sr.scenario_id IS NULL OR l.scenario_code<>sr.scenario_code))::text,
        ('0')::text,
        coalesce(((SELECT count(*)=0 FROM _m1_15_vlatest l LEFT JOIN msbf_ctl.scenario_registry sr ON sr.scenario_id=l.scenario_id WHERE sr.scenario_id IS NULL OR l.scenario_code<>sr.scenario_code)),false),
        'Scenario identifiers and codes reconcile.'
    );
    PERFORM pg_temp.m1_15_add_check(
        'M1_15_POS_20_APPLICATION_LINEAGE',
        'Application lineage violations',
        ((SELECT count(*)::text FROM _m1_15_vlatest l LEFT JOIN msbf_m1.merchant_application a ON a.merchant_application_id=l.merchant_application_id WHERE a.merchant_application_id IS NULL OR a.merchant_id<>l.merchant_id OR a.population_id<>l.population_id))::text,
        ('0')::text,
        coalesce(((SELECT count(*)=0 FROM _m1_15_vlatest l LEFT JOIN msbf_m1.merchant_application a ON a.merchant_application_id=l.merchant_application_id WHERE a.merchant_application_id IS NULL OR a.merchant_id<>l.merchant_id OR a.population_id<>l.population_id)),false),
        'Application, merchant, and population lineage reconcile.'
    );
    PERFORM pg_temp.m1_15_add_check(
        'M1_15_POS_21_SOURCE_HASH_COMPLETENESS',
        'Source hash missing rows',
        ((SELECT count(*)::text FROM _m1_15_vlatest WHERE num_nonnulls(m1_8_row_hash,m1_9_row_hash,m1_10_row_hash,m1_11_row_hash,m1_12_row_hash,m1_13_row_hash,m1_14_row_hash)<>7))::text,
        ('0')::text,
        coalesce(((SELECT count(*)=0 FROM _m1_15_vlatest WHERE num_nonnulls(m1_8_row_hash,m1_9_row_hash,m1_10_row_hash,m1_11_row_hash,m1_12_row_hash,m1_13_row_hash,m1_14_row_hash)<>7)),false),
        'All upstream lineage hashes are present.'
    );
    PERFORM pg_temp.m1_15_add_check(
        'M1_15_POS_22_CONTRACT_EVIDENCE_DOMAIN',
        'Invalid contract evidence statuses',
        ((SELECT count(*)::text FROM _m1_15_vlatest WHERE contract_evidence_status NOT IN ('COMPLETE','PARTIAL','BLOCKED')))::text,
        ('0')::text,
        coalesce(((SELECT count(*)=0 FROM _m1_15_vlatest WHERE contract_evidence_status NOT IN ('COMPLETE','PARTIAL','BLOCKED'))),false),
        'Contract evidence status is governed.'
    );
    PERFORM pg_temp.m1_15_add_check(
        'M1_15_POS_23_DATA_CONFIDENCE_DOMAIN',
        'Invalid data-confidence tiers',
        ((SELECT count(*)::text FROM _m1_15_vlatest WHERE data_confidence_tier NOT IN ('HIGH','MEDIUM','LOW','REVIEW')))::text,
        ('0')::text,
        coalesce(((SELECT count(*)=0 FROM _m1_15_vlatest WHERE data_confidence_tier NOT IN ('HIGH','MEDIUM','LOW','REVIEW'))),false),
        'Data confidence remains in its accepted domain.'
    );
    PERFORM pg_temp.m1_15_add_check(
        'M1_15_POS_24_VERIFICATION_DOMAIN',
        'Invalid verification dispositions',
        ((SELECT count(*)::text FROM _m1_15_vlatest WHERE verification_disposition NOT IN ('CLEAR','REVIEW','STOP','INSUFFICIENT_EVIDENCE')))::text,
        ('0')::text,
        coalesce(((SELECT count(*)=0 FROM _m1_15_vlatest WHERE verification_disposition NOT IN ('CLEAR','REVIEW','STOP','INSUFFICIENT_EVIDENCE'))),false),
        'Verification disposition remains governed.'
    );
    PERFORM pg_temp.m1_15_add_check(
        'M1_15_POS_25_RISK_TIER_BOUNDS',
        'Invalid integrated-risk tiers',
        ((SELECT count(*)::text FROM _m1_15_vlatest WHERE integrated_risk_tier NOT BETWEEN 1 AND 5))::text,
        ('0')::text,
        coalesce(((SELECT count(*)=0 FROM _m1_15_vlatest WHERE integrated_risk_tier NOT BETWEEN 1 AND 5)),false),
        'Integrated-risk tiers remain bounded.'
    );
    PERFORM pg_temp.m1_15_add_check(
        'M1_15_POS_26_ECONOMIC_TIER_BOUNDS',
        'Invalid economic tiers',
        ((SELECT count(*)::text FROM _m1_15_vlatest WHERE economic_tier NOT BETWEEN 1 AND 5))::text,
        ('0')::text,
        coalesce(((SELECT count(*)=0 FROM _m1_15_vlatest WHERE economic_tier NOT BETWEEN 1 AND 5)),false),
        'Economic tiers remain bounded.'
    );
    PERFORM pg_temp.m1_15_add_check(
        'M1_15_POS_27_LATEST_ROW_HASH',
        'Latest physical row-hash mismatches',
        ((SELECT count(*)::text FROM msbf_m1.application_module1_latest l WHERE l.module1_run_id=(SELECT run_id FROM _m1_15_vctx) AND l.contract_row_hash IS DISTINCT FROM msbf_m1.m1_15_hash_jsonb(to_jsonb(l)-'contract_row_hash'-'created_at')))::text,
        ('0')::text,
        coalesce(((SELECT count(*)=0 FROM msbf_m1.application_module1_latest l WHERE l.module1_run_id=(SELECT run_id FROM _m1_15_vctx) AND l.contract_row_hash IS DISTINCT FROM msbf_m1.m1_15_hash_jsonb(to_jsonb(l)-'contract_row_hash'-'created_at'))),false),
        'Latest physical row hashes reconstruct exactly.'
    );
    PERFORM pg_temp.m1_15_add_check(
        'M1_15_POS_28_ARCHIVE_EXACT_COPY',
        'Latest/archive copy mismatches',
        ((SELECT count(*)::text FROM _m1_15_varchive a JOIN _m1_15_vlatest l ON l.module1_run_id=a.module1_run_id AND l.scenario_id=a.scenario_id AND l.merchant_application_id=a.merchant_application_id WHERE a.contract_row_hash IS DISTINCT FROM l.contract_row_hash OR a.contract_payload IS DISTINCT FROM to_jsonb(l)-'created_at'))::text,
        ('0')::text,
        coalesce(((SELECT count(*)=0 FROM _m1_15_varchive a JOIN _m1_15_vlatest l ON l.module1_run_id=a.module1_run_id AND l.scenario_id=a.scenario_id AND l.merchant_application_id=a.merchant_application_id WHERE a.contract_row_hash IS DISTINCT FROM l.contract_row_hash OR a.contract_payload IS DISTINCT FROM to_jsonb(l)-'created_at')),false),
        'Archive exactly reproduces the latest contract.'
    );
    PERFORM pg_temp.m1_15_add_check(
        'M1_15_POS_29_ARCHIVE_TRIGGER',
        'Archive immutability trigger',
        ((SELECT count(*)::text FROM pg_trigger WHERE tgname='trg_m1_15_archive_immutable' AND tgenabled<>'D'))::text,
        ('1')::text,
        coalesce(((SELECT count(*)=1 FROM pg_trigger WHERE tgname='trg_m1_15_archive_immutable' AND tgenabled<>'D')),false),
        'Archive mutation is database-enforced.'
    );
    PERFORM pg_temp.m1_15_add_check(
        'M1_15_POS_30_COMPARISON_ROW_HASH',
        'Comparison row-hash mismatches',
        ((SELECT count(*)::text FROM msbf_m1.application_module1_scenario_comparison c WHERE c.module1_run_id=(SELECT run_id FROM _m1_15_vctx) AND c.comparison_row_hash IS DISTINCT FROM msbf_m1.m1_15_hash_jsonb(to_jsonb(c)-'comparison_row_hash'-'created_at')))::text,
        ('0')::text,
        coalesce(((SELECT count(*)=0 FROM msbf_m1.application_module1_scenario_comparison c WHERE c.module1_run_id=(SELECT run_id FROM _m1_15_vctx) AND c.comparison_row_hash IS DISTINCT FROM msbf_m1.m1_15_hash_jsonb(to_jsonb(c)-'comparison_row_hash'-'created_at'))),false),
        'Comparison physical row hashes reconstruct exactly.'
    );
    PERFORM pg_temp.m1_15_add_check(
        'M1_15_POS_31_CONTRACT_ROW_HASH',
        'Contract row-hash mismatches',
        ((SELECT count(*)::text FROM _m1_15_vcontract c WHERE c.contract_row_hash IS DISTINCT FROM msbf_m1.m1_15_hash_jsonb(to_jsonb(c)-'contract_row_hash'-'combined_set_hash'-'contract_status'-'generated_at'-'validated_at')))::text,
        ('0')::text,
        coalesce(((SELECT count(*)=0 FROM _m1_15_vcontract c WHERE c.contract_row_hash IS DISTINCT FROM msbf_m1.m1_15_hash_jsonb(to_jsonb(c)-'contract_row_hash'-'combined_set_hash'-'contract_status'-'generated_at'-'validated_at'))),false),
        'Contract identity hash reconstructs exactly.'
    );
    PERFORM pg_temp.m1_15_add_check(
        'M1_15_POS_32_LATEST_SET_HASH',
        'Latest set hash',
        ((SELECT md5(string_agg('LATEST|'||scenario_id||'|'||merchant_application_id||'|'||contract_row_hash,'||' ORDER BY scenario_id,merchant_application_id)) FROM _m1_15_vlatest))::text,
        ((SELECT latest_set_hash FROM _m1_15_vcontract))::text,
        coalesce(((SELECT md5(string_agg('LATEST|'||scenario_id||'|'||merchant_application_id||'|'||contract_row_hash,'||' ORDER BY scenario_id,merchant_application_id)) FROM _m1_15_vlatest)=(SELECT latest_set_hash FROM _m1_15_vcontract)),false),
        'Latest set hash reconciles.'
    );
    PERFORM pg_temp.m1_15_add_check(
        'M1_15_POS_33_ARCHIVE_SET_HASH',
        'Archive set hash',
        ((SELECT md5(string_agg('ARCHIVE|'||contract_version||'|'||scenario_id||'|'||merchant_application_id||'|'||contract_row_hash,'||' ORDER BY contract_version,scenario_id,merchant_application_id)) FROM _m1_15_varchive))::text,
        ((SELECT archive_set_hash FROM _m1_15_vcontract))::text,
        coalesce(((SELECT md5(string_agg('ARCHIVE|'||contract_version||'|'||scenario_id||'|'||merchant_application_id||'|'||contract_row_hash,'||' ORDER BY contract_version,scenario_id,merchant_application_id)) FROM _m1_15_varchive)=(SELECT archive_set_hash FROM _m1_15_vcontract)),false),
        'Archive set hash reconciles.'
    );
    PERFORM pg_temp.m1_15_add_check(
        'M1_15_POS_34_COMPARISON_SET_HASH',
        'Comparison set hash',
        ((SELECT md5(string_agg('COMPARE|'||merchant_application_id||'|'||comparison_row_hash,'||' ORDER BY merchant_application_id)) FROM _m1_15_vcomparison))::text,
        ((SELECT comparison_set_hash FROM _m1_15_vcontract))::text,
        coalesce(((SELECT md5(string_agg('COMPARE|'||merchant_application_id||'|'||comparison_row_hash,'||' ORDER BY merchant_application_id)) FROM _m1_15_vcomparison)=(SELECT comparison_set_hash FROM _m1_15_vcontract)),false),
        'Comparison set hash reconciles.'
    );
    PERFORM pg_temp.m1_15_add_check(
        'M1_15_POS_35_CONTRACT_SET_HASH',
        'Contract set hash',
        ((SELECT contract_set_hash FROM _m1_15_vcontract))::text,
        ('non-null')::text,
        coalesce(((SELECT contract_set_hash IS NOT NULL AND length(contract_set_hash)=32 FROM _m1_15_vcontract)),false),
        'Contract set hash is present.'
    );
    PERFORM pg_temp.m1_15_add_check(
        'M1_15_POS_36_COMBINED_SET_HASH',
        'Combined set hash',
        ((WITH all_entities AS (
SELECT ('LATEST|'||scenario_id::text||'|'||merchant_application_id)::text AS entity_key,contract_row_hash::text AS row_hash FROM _m1_15_vlatest
UNION ALL SELECT ('ARCHIVE|'||contract_version::text||'|'||scenario_id::text||'|'||merchant_application_id)::text,contract_row_hash::text FROM _m1_15_varchive
UNION ALL SELECT ('COMPARE|'||merchant_application_id)::text,comparison_row_hash::text FROM _m1_15_vcomparison
UNION ALL SELECT ('CONTRACT|'||contract_code||'|'||contract_version::text||'|'||module1_run_id::text)::text,contract_row_hash::text FROM _m1_15_vcontract)
SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) FROM all_entities))::text,
        ((SELECT combined_set_hash FROM _m1_15_vcontract))::text,
        coalesce(((WITH all_entities AS (
SELECT ('LATEST|'||scenario_id::text||'|'||merchant_application_id)::text AS entity_key,contract_row_hash::text AS row_hash FROM _m1_15_vlatest
UNION ALL SELECT ('ARCHIVE|'||contract_version::text||'|'||scenario_id::text||'|'||merchant_application_id)::text,contract_row_hash::text FROM _m1_15_varchive
UNION ALL SELECT ('COMPARE|'||merchant_application_id)::text,comparison_row_hash::text FROM _m1_15_vcomparison
UNION ALL SELECT ('CONTRACT|'||contract_code||'|'||contract_version::text||'|'||module1_run_id::text)::text,contract_row_hash::text FROM _m1_15_vcontract)
SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key)) FROM all_entities)=(SELECT combined_set_hash FROM _m1_15_vcontract)),false),
        'Combined 3,751-entity hash reconciles.'
    );
    PERFORM pg_temp.m1_15_add_check(
        'M1_15_POS_37_GENERATION_MISMATCH_EVIDENCE',
        'Stored generation mismatches',
        ((SELECT metric_value_numeric::text FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM _m1_15_vctx) AND evidence_code='M1_15_CANONICAL_MISMATCH_COUNT' AND segment_key='PORTFOLIO'))::text,
        ('0')::text,
        coalesce(((SELECT metric_value_numeric=0 FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM _m1_15_vctx) AND evidence_code='M1_15_CANONICAL_MISMATCH_COUNT' AND segment_key='PORTFOLIO')),false),
        'Generation recorded zero canonical mismatches.'
    );
    PERFORM pg_temp.m1_15_add_check(
        'M1_15_POS_38_LATEST_ARCHIVE_COUNT_IDENTITY',
        'Latest/archive count identity',
        ((SELECT ((SELECT count(*) FROM _m1_15_vlatest)-(SELECT count(*) FROM _m1_15_varchive))::text))::text,
        ('0')::text,
        coalesce((((SELECT count(*) FROM _m1_15_vlatest)=(SELECT count(*) FROM _m1_15_varchive))),false),
        'Latest and archive counts match.'
    );
    PERFORM pg_temp.m1_15_add_check(
        'M1_15_POS_39_LATEST_ARCHIVE_HASH_IDENTITY',
        'Latest/archive row-hash mismatches',
        ((SELECT count(*)::text FROM _m1_15_vlatest l FULL JOIN _m1_15_varchive a ON a.module1_run_id=l.module1_run_id AND a.scenario_id=l.scenario_id AND a.merchant_application_id=l.merchant_application_id WHERE l.contract_row_hash IS DISTINCT FROM a.contract_row_hash))::text,
        ('0')::text,
        coalesce(((SELECT count(*)=0 FROM _m1_15_vlatest l FULL JOIN _m1_15_varchive a ON a.module1_run_id=l.module1_run_id AND a.scenario_id=l.scenario_id AND a.merchant_application_id=l.merchant_application_id WHERE l.contract_row_hash IS DISTINCT FROM a.contract_row_hash)),false),
        'Latest and archive row hashes match.'
    );
    PERFORM pg_temp.m1_15_add_check(
        'M1_15_POS_40_MATCHED_COVERAGE',
        'Matched comparison coverage',
        ((SELECT count(*)::text FROM _m1_15_vcomparison c JOIN _m1_15_vlatest b ON b.module1_run_id=c.module1_run_id AND b.merchant_application_id=c.merchant_application_id AND b.scenario_id=c.baseline_scenario_id JOIN _m1_15_vlatest s ON s.module1_run_id=c.module1_run_id AND s.merchant_application_id=c.merchant_application_id AND s.scenario_id=c.stress_scenario_id))::text,
        ('750')::text,
        coalesce(((SELECT count(*)=750 FROM _m1_15_vcomparison c JOIN _m1_15_vlatest b ON b.module1_run_id=c.module1_run_id AND b.merchant_application_id=c.merchant_application_id AND b.scenario_id=c.baseline_scenario_id JOIN _m1_15_vlatest s ON s.module1_run_id=c.module1_run_id AND s.merchant_application_id=c.merchant_application_id AND s.scenario_id=c.stress_scenario_id)),false),
        'Every comparison has both matched contract rows.'
    );
    PERFORM pg_temp.m1_15_add_check(
        'M1_15_POS_41_SOURCE_CONFIDENCE_DELTA',
        'Source-confidence delta violations',
        ((SELECT count(*)::text FROM _m1_15_vcomparison WHERE source_confidence_delta IS DISTINCT FROM (stress_source_confidence_score-baseline_source_confidence_score)::numeric(12,8)))::text,
        ('0')::text,
        coalesce(((SELECT count(*)=0 FROM _m1_15_vcomparison WHERE source_confidence_delta IS DISTINCT FROM (stress_source_confidence_score-baseline_source_confidence_score)::numeric(12,8))),false),
        'Source-confidence delta reconciles.'
    );
    PERFORM pg_temp.m1_15_add_check(
        'M1_15_POS_42_SALES_DELTA',
        'Sales delta violations',
        ((SELECT count(*)::text FROM _m1_15_vcomparison WHERE sales_delta_amount IS DISTINCT FROM CASE WHEN stress_avg_daily_eligible_sales_30d IS NULL OR baseline_avg_daily_eligible_sales_30d IS NULL THEN NULL ELSE (stress_avg_daily_eligible_sales_30d-baseline_avg_daily_eligible_sales_30d)::numeric(18,2) END))::text,
        ('0')::text,
        coalesce(((SELECT count(*)=0 FROM _m1_15_vcomparison WHERE sales_delta_amount IS DISTINCT FROM CASE WHEN stress_avg_daily_eligible_sales_30d IS NULL OR baseline_avg_daily_eligible_sales_30d IS NULL THEN NULL ELSE (stress_avg_daily_eligible_sales_30d-baseline_avg_daily_eligible_sales_30d)::numeric(18,2) END)),false),
        'Sales delta reconciles.'
    );
    PERFORM pg_temp.m1_15_add_check(
        'M1_15_POS_43_BALANCE_DELTA',
        'Available-balance delta violations',
        ((SELECT count(*)::text FROM _m1_15_vcomparison WHERE available_balance_delta_amount IS DISTINCT FROM CASE WHEN stress_average_available_balance_30d IS NULL OR baseline_average_available_balance_30d IS NULL THEN NULL ELSE (stress_average_available_balance_30d-baseline_average_available_balance_30d)::numeric(18,2) END))::text,
        ('0')::text,
        coalesce(((SELECT count(*)=0 FROM _m1_15_vcomparison WHERE available_balance_delta_amount IS DISTINCT FROM CASE WHEN stress_average_available_balance_30d IS NULL OR baseline_average_available_balance_30d IS NULL THEN NULL ELSE (stress_average_available_balance_30d-baseline_average_available_balance_30d)::numeric(18,2) END)),false),
        'Available-balance delta reconciles.'
    );
    PERFORM pg_temp.m1_15_add_check(
        'M1_15_POS_44_CAPACITY_TIER_DELTA',
        'Capacity-tier delta violations',
        ((SELECT count(*)::text FROM _m1_15_vcomparison WHERE capacity_tier_delta IS DISTINCT FROM (stress_capacity_tier-baseline_capacity_tier)::smallint))::text,
        ('0')::text,
        coalesce(((SELECT count(*)=0 FROM _m1_15_vcomparison WHERE capacity_tier_delta IS DISTINCT FROM (stress_capacity_tier-baseline_capacity_tier)::smallint)),false),
        'Capacity-tier delta reconciles.'
    );
    PERFORM pg_temp.m1_15_add_check(
        'M1_15_POS_45_RESILIENCE_SCORE_DELTA',
        'Resilience-score delta violations',
        ((SELECT count(*)::text FROM _m1_15_vcomparison WHERE resilience_score_delta IS DISTINCT FROM CASE WHEN stress_operating_resilience_score IS NULL OR baseline_operating_resilience_score IS NULL THEN NULL ELSE (stress_operating_resilience_score-baseline_operating_resilience_score)::numeric(12,6) END))::text,
        ('0')::text,
        coalesce(((SELECT count(*)=0 FROM _m1_15_vcomparison WHERE resilience_score_delta IS DISTINCT FROM CASE WHEN stress_operating_resilience_score IS NULL OR baseline_operating_resilience_score IS NULL THEN NULL ELSE (stress_operating_resilience_score-baseline_operating_resilience_score)::numeric(12,6) END)),false),
        'Resilience-score delta reconciles.'
    );
    PERFORM pg_temp.m1_15_add_check(
        'M1_15_POS_46_RISK_SCORE_DELTA',
        'Integrated-risk-score delta violations',
        ((SELECT count(*)::text FROM _m1_15_vcomparison WHERE integrated_risk_score_delta IS DISTINCT FROM CASE WHEN stress_integrated_risk_score IS NULL OR baseline_integrated_risk_score IS NULL THEN NULL ELSE (stress_integrated_risk_score-baseline_integrated_risk_score)::numeric(12,6) END))::text,
        ('0')::text,
        coalesce(((SELECT count(*)=0 FROM _m1_15_vcomparison WHERE integrated_risk_score_delta IS DISTINCT FROM CASE WHEN stress_integrated_risk_score IS NULL OR baseline_integrated_risk_score IS NULL THEN NULL ELSE (stress_integrated_risk_score-baseline_integrated_risk_score)::numeric(12,6) END)),false),
        'Integrated-risk-score delta reconciles.'
    );
    PERFORM pg_temp.m1_15_add_check(
        'M1_15_POS_47_EAD_DELTA',
        'EAD delta violations',
        ((SELECT count(*)::text FROM _m1_15_vcomparison WHERE path_weighted_ead_delta_amount IS DISTINCT FROM (stress_path_weighted_ead_amount-baseline_path_weighted_ead_amount)::numeric(18,2)))::text,
        ('0')::text,
        coalesce(((SELECT count(*)=0 FROM _m1_15_vcomparison WHERE path_weighted_ead_delta_amount IS DISTINCT FROM (stress_path_weighted_ead_amount-baseline_path_weighted_ead_amount)::numeric(18,2))),false),
        'EAD delta reconciles.'
    );
    PERFORM pg_temp.m1_15_add_check(
        'M1_15_POS_48_LGD_DELTA',
        'LGD delta violations',
        ((SELECT count(*)::text FROM _m1_15_vcomparison WHERE lgd_delta_rate IS DISTINCT FROM (stress_lgd_input_rate-baseline_lgd_input_rate)::numeric(12,8)))::text,
        ('0')::text,
        coalesce(((SELECT count(*)=0 FROM _m1_15_vcomparison WHERE lgd_delta_rate IS DISTINCT FROM (stress_lgd_input_rate-baseline_lgd_input_rate)::numeric(12,8))),false),
        'LGD delta reconciles.'
    );
    PERFORM pg_temp.m1_15_add_check(
        'M1_15_POS_49_LOSS_DELTA',
        'Comparative-loss delta violations',
        ((SELECT count(*)::text FROM _m1_15_vcomparison WHERE comparative_loss_delta_amount IS DISTINCT FROM CASE WHEN stress_comparative_loss_amount IS NULL OR baseline_comparative_loss_amount IS NULL THEN NULL ELSE (stress_comparative_loss_amount-baseline_comparative_loss_amount)::numeric(18,2) END))::text,
        ('0')::text,
        coalesce(((SELECT count(*)=0 FROM _m1_15_vcomparison WHERE comparative_loss_delta_amount IS DISTINCT FROM CASE WHEN stress_comparative_loss_amount IS NULL OR baseline_comparative_loss_amount IS NULL THEN NULL ELSE (stress_comparative_loss_amount-baseline_comparative_loss_amount)::numeric(18,2) END)),false),
        'Comparative-loss delta reconciles.'
    );
    PERFORM pg_temp.m1_15_add_check(
        'M1_15_POS_50_CONTRIBUTION_DELTA',
        'Contribution delta violations',
        ((SELECT count(*)::text FROM _m1_15_vcomparison WHERE risk_adjusted_contribution_delta_amount IS DISTINCT FROM CASE WHEN stress_risk_adjusted_contribution_amount IS NULL OR baseline_risk_adjusted_contribution_amount IS NULL THEN NULL ELSE (stress_risk_adjusted_contribution_amount-baseline_risk_adjusted_contribution_amount)::numeric(18,2) END))::text,
        ('0')::text,
        coalesce(((SELECT count(*)=0 FROM _m1_15_vcomparison WHERE risk_adjusted_contribution_delta_amount IS DISTINCT FROM CASE WHEN stress_risk_adjusted_contribution_amount IS NULL OR baseline_risk_adjusted_contribution_amount IS NULL THEN NULL ELSE (stress_risk_adjusted_contribution_amount-baseline_risk_adjusted_contribution_amount)::numeric(18,2) END)),false),
        'Contribution delta reconciles.'
    );
    PERFORM pg_temp.m1_15_add_check(
        'M1_15_POS_51_RETURN_DELTA',
        'Annualized-return delta violations',
        ((SELECT count(*)::text FROM _m1_15_vcomparison WHERE annualized_return_delta_rate IS DISTINCT FROM CASE WHEN stress_annualized_return_rate IS NULL OR baseline_annualized_return_rate IS NULL THEN NULL ELSE (stress_annualized_return_rate-baseline_annualized_return_rate)::numeric(12,8) END))::text,
        ('0')::text,
        coalesce(((SELECT count(*)=0 FROM _m1_15_vcomparison WHERE annualized_return_delta_rate IS DISTINCT FROM CASE WHEN stress_annualized_return_rate IS NULL OR baseline_annualized_return_rate IS NULL THEN NULL ELSE (stress_annualized_return_rate-baseline_annualized_return_rate)::numeric(12,8) END)),false),
        'Annualized-return delta reconciles.'
    );
    PERFORM pg_temp.m1_15_add_check(
        'M1_15_POS_52_ECONOMIC_TIER_DELTA',
        'Economic-tier delta violations',
        ((SELECT count(*)::text FROM _m1_15_vcomparison WHERE economic_tier_delta IS DISTINCT FROM (stress_economic_tier-baseline_economic_tier)::smallint))::text,
        ('0')::text,
        coalesce(((SELECT count(*)=0 FROM _m1_15_vcomparison WHERE economic_tier_delta IS DISTINCT FROM (stress_economic_tier-baseline_economic_tier)::smallint)),false),
        'Economic-tier delta reconciles.'
    );
    PERFORM pg_temp.m1_15_add_check(
        'M1_15_POS_53_CAPACITY_WORSENING',
        'Capacity-worsening identity',
        ((SELECT count(*)::text FROM _m1_15_vcomparison WHERE capacity_worsening_flag IS DISTINCT FROM (stress_capacity_tier>baseline_capacity_tier)))::text,
        ('0')::text,
        coalesce(((SELECT count(*)=0 FROM _m1_15_vcomparison WHERE capacity_worsening_flag IS DISTINCT FROM (stress_capacity_tier>baseline_capacity_tier))),false),
        'Capacity worsening flag reconciles.'
    );
    PERFORM pg_temp.m1_15_add_check(
        'M1_15_POS_54_RESILIENCE_WORSENING',
        'Resilience-worsening identity',
        ((SELECT count(*)::text FROM _m1_15_vcomparison WHERE resilience_worsening_flag IS DISTINCT FROM ((stress_resilience_tier>baseline_resilience_tier) OR (stress_operating_resilience_score IS NOT NULL AND baseline_operating_resilience_score IS NOT NULL AND stress_operating_resilience_score<baseline_operating_resilience_score))))::text,
        ('0')::text,
        coalesce(((SELECT count(*)=0 FROM _m1_15_vcomparison WHERE resilience_worsening_flag IS DISTINCT FROM ((stress_resilience_tier>baseline_resilience_tier) OR (stress_operating_resilience_score IS NOT NULL AND baseline_operating_resilience_score IS NOT NULL AND stress_operating_resilience_score<baseline_operating_resilience_score)))),false),
        'Resilience worsening flag reconciles to visible score comparison.'
    );
    PERFORM pg_temp.m1_15_add_check(
        'M1_15_POS_55_RISK_WORSENING',
        'Risk-worsening identity',
        ((SELECT count(*)::text FROM _m1_15_vcomparison c JOIN _m1_15_vlatest b ON b.module1_run_id=c.module1_run_id AND b.scenario_id=c.baseline_scenario_id AND b.merchant_application_id=c.merchant_application_id JOIN _m1_15_vlatest s ON s.module1_run_id=c.module1_run_id AND s.scenario_id=c.stress_scenario_id AND s.merchant_application_id=c.merchant_application_id WHERE c.integrated_risk_worsening_flag IS DISTINCT FROM ((s.integrated_risk_tier>b.integrated_risk_tier) OR (s.integrated_risk_score IS NOT NULL AND b.integrated_risk_score IS NOT NULL AND s.integrated_risk_score>b.integrated_risk_score))))::text,
        ('0')::text,
        coalesce(((SELECT count(*)=0 FROM _m1_15_vcomparison c JOIN _m1_15_vlatest b ON b.module1_run_id=c.module1_run_id AND b.scenario_id=c.baseline_scenario_id AND b.merchant_application_id=c.merchant_application_id JOIN _m1_15_vlatest s ON s.module1_run_id=c.module1_run_id AND s.scenario_id=c.stress_scenario_id AND s.merchant_application_id=c.merchant_application_id WHERE c.integrated_risk_worsening_flag IS DISTINCT FROM ((s.integrated_risk_tier>b.integrated_risk_tier) OR (s.integrated_risk_score IS NOT NULL AND b.integrated_risk_score IS NOT NULL AND s.integrated_risk_score>b.integrated_risk_score)))),false),
        'Integrated-risk worsening flag reconciles to score and tier.'
    );
    PERFORM pg_temp.m1_15_add_check(
        'M1_15_POS_56_LOSS_WORSENING',
        'Loss-worsening identity',
        ((SELECT count(*)::text FROM _m1_15_vcomparison WHERE comparative_loss_worsening_flag IS DISTINCT FROM (stress_comparative_loss_amount IS NOT NULL AND baseline_comparative_loss_amount IS NOT NULL AND stress_comparative_loss_amount>baseline_comparative_loss_amount)))::text,
        ('0')::text,
        coalesce(((SELECT count(*)=0 FROM _m1_15_vcomparison WHERE comparative_loss_worsening_flag IS DISTINCT FROM (stress_comparative_loss_amount IS NOT NULL AND baseline_comparative_loss_amount IS NOT NULL AND stress_comparative_loss_amount>baseline_comparative_loss_amount))),false),
        'Comparative-loss worsening flag reconciles.'
    );
    PERFORM pg_temp.m1_15_add_check(
        'M1_15_POS_57_ECONOMIC_WORSENING',
        'Economic-worsening identity',
        ((SELECT count(*)::text FROM _m1_15_vcomparison WHERE economic_worsening_flag IS DISTINCT FROM ((stress_risk_adjusted_contribution_amount IS NOT NULL AND baseline_risk_adjusted_contribution_amount IS NOT NULL AND stress_risk_adjusted_contribution_amount<baseline_risk_adjusted_contribution_amount) OR (stress_annualized_return_rate IS NOT NULL AND baseline_annualized_return_rate IS NOT NULL AND stress_annualized_return_rate<baseline_annualized_return_rate) OR stress_economic_tier>baseline_economic_tier)))::text,
        ('0')::text,
        coalesce(((SELECT count(*)=0 FROM _m1_15_vcomparison WHERE economic_worsening_flag IS DISTINCT FROM ((stress_risk_adjusted_contribution_amount IS NOT NULL AND baseline_risk_adjusted_contribution_amount IS NOT NULL AND stress_risk_adjusted_contribution_amount<baseline_risk_adjusted_contribution_amount) OR (stress_annualized_return_rate IS NOT NULL AND baseline_annualized_return_rate IS NOT NULL AND stress_annualized_return_rate<baseline_annualized_return_rate) OR stress_economic_tier>baseline_economic_tier))),false),
        'Economic worsening includes contribution, return, and tier.'
    );
    PERFORM pg_temp.m1_15_add_check(
        'M1_15_POS_58_REVIEW_ESCALATION',
        'Manual-review escalation identity',
        ((SELECT count(*)::text FROM _m1_15_vcomparison c JOIN _m1_15_vlatest b ON b.module1_run_id=c.module1_run_id AND b.scenario_id=c.baseline_scenario_id AND b.merchant_application_id=c.merchant_application_id JOIN _m1_15_vlatest s ON s.module1_run_id=c.module1_run_id AND s.scenario_id=c.stress_scenario_id AND s.merchant_application_id=c.merchant_application_id WHERE c.manual_review_escalation_flag IS DISTINCT FROM (s.manual_review_recommended_flag AND NOT b.manual_review_recommended_flag)))::text,
        ('0')::text,
        coalesce(((SELECT count(*)=0 FROM _m1_15_vcomparison c JOIN _m1_15_vlatest b ON b.module1_run_id=c.module1_run_id AND b.scenario_id=c.baseline_scenario_id AND b.merchant_application_id=c.merchant_application_id JOIN _m1_15_vlatest s ON s.module1_run_id=c.module1_run_id AND s.scenario_id=c.stress_scenario_id AND s.merchant_application_id=c.merchant_application_id WHERE c.manual_review_escalation_flag IS DISTINCT FROM (s.manual_review_recommended_flag AND NOT b.manual_review_recommended_flag))),false),
        'Manual-review escalation reconciles.'
    );
    PERFORM pg_temp.m1_15_add_check(
        'M1_15_POS_59_HARD_STOP_ESCALATION',
        'Hard-stop escalation identity',
        ((SELECT count(*)::text FROM _m1_15_vcomparison c JOIN _m1_15_vlatest b ON b.module1_run_id=c.module1_run_id AND b.scenario_id=c.baseline_scenario_id AND b.merchant_application_id=c.merchant_application_id JOIN _m1_15_vlatest s ON s.module1_run_id=c.module1_run_id AND s.scenario_id=c.stress_scenario_id AND s.merchant_application_id=c.merchant_application_id WHERE c.hard_stop_escalation_flag IS DISTINCT FROM (s.hard_stop_recommended_flag AND NOT b.hard_stop_recommended_flag)))::text,
        ('0')::text,
        coalesce(((SELECT count(*)=0 FROM _m1_15_vcomparison c JOIN _m1_15_vlatest b ON b.module1_run_id=c.module1_run_id AND b.scenario_id=c.baseline_scenario_id AND b.merchant_application_id=c.merchant_application_id JOIN _m1_15_vlatest s ON s.module1_run_id=c.module1_run_id AND s.scenario_id=c.stress_scenario_id AND s.merchant_application_id=c.merchant_application_id WHERE c.hard_stop_escalation_flag IS DISTINCT FROM (s.hard_stop_recommended_flag AND NOT b.hard_stop_recommended_flag))),false),
        'Hard-stop escalation reconciles.'
    );
    PERFORM pg_temp.m1_15_add_check(
        'M1_15_POS_60_RISK_NONIMPROVEMENT',
        'Stress risk-score improvements',
        ((SELECT count(*)::text FROM _m1_15_vcomparison WHERE stress_integrated_risk_tier<baseline_integrated_risk_tier OR stress_integrated_risk_score<baseline_integrated_risk_score))::text,
        ('0')::text,
        coalesce(((SELECT count(*)=0 FROM _m1_15_vcomparison WHERE stress_integrated_risk_tier<baseline_integrated_risk_tier OR stress_integrated_risk_score<baseline_integrated_risk_score)),false),
        'Adverse scenario cannot improve final integrated risk score.'
    );
    PERFORM pg_temp.m1_15_add_check(
        'M1_15_POS_61_CAPACITY_NONIMPROVEMENT',
        'Stress capacity-tier improvements',
        ((SELECT count(*)::text FROM _m1_15_vcomparison WHERE stress_capacity_tier<baseline_capacity_tier))::text,
        ('0')::text,
        coalesce(((SELECT count(*)=0 FROM _m1_15_vcomparison WHERE stress_capacity_tier<baseline_capacity_tier)),false),
        'Adverse scenario cannot improve capacity tier.'
    );
    PERFORM pg_temp.m1_15_add_check(
        'M1_15_POS_62_RESILIENCE_NONIMPROVEMENT',
        'Stress resilience interpretation improvements',
        format(
            'tier=%s|archetype=%s|score_increases_diagnostic=%s',
            (SELECT count(*)
             FROM _m1_15_vcomparison
             WHERE stress_resilience_tier<baseline_resilience_tier),
            (SELECT count(*)
             FROM _m1_15_varchetype_pair
             WHERE stress_archetype_risk_rank<baseline_archetype_risk_rank),
            (SELECT count(*)
             FROM _m1_15_vcomparison
             WHERE stress_operating_resilience_score IS NOT NULL
               AND baseline_operating_resilience_score IS NOT NULL
               AND stress_operating_resilience_score>baseline_operating_resilience_score)
        )::text,
        ('tier=0|archetype=0|score_increases_diagnostic=descriptive')::text,
        coalesce((
            (SELECT count(*)=0
             FROM _m1_15_vcomparison
             WHERE stress_resilience_tier<baseline_resilience_tier)
            AND
            (SELECT count(*)=0
             FROM _m1_15_varchetype_pair
             WHERE stress_archetype_risk_rank<baseline_archetype_risk_rank)
        ),false),
        'Adverse stress cannot improve the governed M1.11 resilience tier or archetype risk rank. Continuous score increases within those accepted interpretation floors remain descriptive matched-scenario evidence.'
    );
    PERFORM pg_temp.m1_15_add_check(
        'M1_15_POS_63_LGD_NONIMPROVEMENT',
        'Stress LGD improvements',
        ((SELECT count(*)::text FROM _m1_15_vcomparison WHERE stress_lgd_input_rate<baseline_lgd_input_rate))::text,
        ('0')::text,
        coalesce(((SELECT count(*)=0 FROM _m1_15_vcomparison WHERE stress_lgd_input_rate<baseline_lgd_input_rate)),false),
        'Adverse scenario cannot improve LGD.'
    );
    PERFORM pg_temp.m1_15_add_check(
        'M1_15_POS_64_CONTRIBUTION_NONIMPROVEMENT',
        'Stress contribution improvements',
        ((SELECT count(*)::text FROM _m1_15_vcomparison WHERE stress_risk_adjusted_contribution_amount>baseline_risk_adjusted_contribution_amount))::text,
        ('0')::text,
        coalesce(((SELECT count(*)=0 FROM _m1_15_vcomparison WHERE stress_risk_adjusted_contribution_amount>baseline_risk_adjusted_contribution_amount)),false),
        'Adverse scenario cannot improve final contribution.'
    );
    PERFORM pg_temp.m1_15_add_check(
        'M1_15_POS_65_RETURN_NONIMPROVEMENT',
        'Stress return improvements',
        ((SELECT count(*)::text FROM _m1_15_vcomparison WHERE stress_annualized_return_rate>baseline_annualized_return_rate))::text,
        ('0')::text,
        coalesce(((SELECT count(*)=0 FROM _m1_15_vcomparison WHERE stress_annualized_return_rate>baseline_annualized_return_rate)),false),
        'Adverse scenario cannot improve final annualized return.'
    );
    PERFORM pg_temp.m1_15_add_check(
        'M1_15_POS_66_ECONOMIC_TIER_NONIMPROVEMENT',
        'Stress economic-tier improvements',
        ((SELECT count(*)::text FROM _m1_15_vcomparison WHERE stress_economic_tier<baseline_economic_tier))::text,
        ('0')::text,
        coalesce(((SELECT count(*)=0 FROM _m1_15_vcomparison WHERE stress_economic_tier<baseline_economic_tier)),false),
        'Adverse scenario cannot improve economic tier.'
    );
    PERFORM pg_temp.m1_15_add_check(
        'M1_15_POS_67_M1_14_REPRODUCTION',
        'M1.14 latest reproduction mismatches',
        ((SELECT count(*)::text FROM _m1_15_vlatest x JOIN msbf_m1.application_unit_economics_snapshot e ON e.module1_run_id=x.module1_run_id AND e.scenario_id=x.scenario_id AND e.merchant_application_id=x.merchant_application_id WHERE x.m1_14_row_hash<>e.row_hash OR x.economic_tier<>e.economic_tier OR x.economic_status<>e.economic_status OR x.risk_adjusted_contribution_amount IS DISTINCT FROM e.risk_adjusted_contribution_amount))::text,
        ('0')::text,
        coalesce(((SELECT count(*)=0 FROM _m1_15_vlatest x JOIN msbf_m1.application_unit_economics_snapshot e ON e.module1_run_id=x.module1_run_id AND e.scenario_id=x.scenario_id AND e.merchant_application_id=x.merchant_application_id WHERE x.m1_14_row_hash<>e.row_hash OR x.economic_tier<>e.economic_tier OR x.economic_status<>e.economic_status OR x.risk_adjusted_contribution_amount IS DISTINCT FROM e.risk_adjusted_contribution_amount)),false),
        'M1.14 economics reproduce exactly.'
    );
    PERFORM pg_temp.m1_15_add_check(
        'M1_15_POS_68_M1_12_REPRODUCTION',
        'M1.12 risk reproduction mismatches',
        ((SELECT count(*)::text FROM _m1_15_vlatest x JOIN msbf_m1.application_integrated_risk_proxy_snapshot r ON r.module1_run_id=x.module1_run_id AND r.scenario_id=x.scenario_id AND r.merchant_application_id=x.merchant_application_id WHERE x.m1_12_row_hash<>r.row_hash OR x.integrated_risk_score IS DISTINCT FROM r.integrated_risk_score OR x.integrated_risk_tier<>r.integrated_risk_tier))::text,
        ('0')::text,
        coalesce(((SELECT count(*)=0 FROM _m1_15_vlatest x JOIN msbf_m1.application_integrated_risk_proxy_snapshot r ON r.module1_run_id=x.module1_run_id AND r.scenario_id=x.scenario_id AND r.merchant_application_id=x.merchant_application_id WHERE x.m1_12_row_hash<>r.row_hash OR x.integrated_risk_score IS DISTINCT FROM r.integrated_risk_score OR x.integrated_risk_tier<>r.integrated_risk_tier)),false),
        'M1.12 integrated risk reproduces exactly.'
    );
    PERFORM pg_temp.m1_15_add_check(
        'M1_15_POS_69_M1_13_REPRODUCTION',
        'M1.13 loss reproduction mismatches',
        ((SELECT count(*)::text FROM _m1_15_vlatest x JOIN msbf_m1.application_exposure_recovery_loss_snapshot l ON l.module1_run_id=x.module1_run_id AND l.scenario_id=x.scenario_id AND l.merchant_application_id=x.merchant_application_id WHERE x.m1_13_row_hash<>l.row_hash OR x.path_weighted_ead_amount<>l.path_weighted_ead_amount OR x.lgd_input_rate<>l.lgd_input_rate OR x.schedule_adjusted_comparative_expected_loss_amount IS DISTINCT FROM l.schedule_adjusted_comparative_expected_loss_amount))::text,
        ('0')::text,
        coalesce(((SELECT count(*)=0 FROM _m1_15_vlatest x JOIN msbf_m1.application_exposure_recovery_loss_snapshot l ON l.module1_run_id=x.module1_run_id AND l.scenario_id=x.scenario_id AND l.merchant_application_id=x.merchant_application_id WHERE x.m1_13_row_hash<>l.row_hash OR x.path_weighted_ead_amount<>l.path_weighted_ead_amount OR x.lgd_input_rate<>l.lgd_input_rate OR x.schedule_adjusted_comparative_expected_loss_amount IS DISTINCT FROM l.schedule_adjusted_comparative_expected_loss_amount)),false),
        'M1.13 exposure/loss reproduces exactly.'
    );
    PERFORM pg_temp.m1_15_add_check(
        'M1_15_POS_70_M1_10_REPRODUCTION',
        'M1.10 capacity reproduction mismatches',
        ((SELECT count(*)::text FROM _m1_15_vlatest x JOIN msbf_m1.application_liquidity_capacity_snapshot c ON c.module1_run_id=x.module1_run_id AND c.scenario_id=x.scenario_id AND c.merchant_application_id=x.merchant_application_id WHERE x.m1_10_row_hash<>c.row_hash OR x.capacity_tier<>c.capacity_tier OR x.post_financing_liquidity_buffer_amount IS DISTINCT FROM c.post_financing_liquidity_buffer_amount))::text,
        ('0')::text,
        coalesce(((SELECT count(*)=0 FROM _m1_15_vlatest x JOIN msbf_m1.application_liquidity_capacity_snapshot c ON c.module1_run_id=x.module1_run_id AND c.scenario_id=x.scenario_id AND c.merchant_application_id=x.merchant_application_id WHERE x.m1_10_row_hash<>c.row_hash OR x.capacity_tier<>c.capacity_tier OR x.post_financing_liquidity_buffer_amount IS DISTINCT FROM c.post_financing_liquidity_buffer_amount)),false),
        'M1.10 capacity reproduces exactly.'
    );
    PERFORM pg_temp.m1_15_add_check(
        'M1_15_POS_71_M1_11_REPRODUCTION',
        'M1.11 resilience reproduction mismatches',
        ((SELECT count(*)::text FROM _m1_15_vlatest x JOIN msbf_m1.application_operating_resilience_snapshot o ON o.module1_run_id=x.module1_run_id AND o.scenario_id=x.scenario_id AND o.merchant_application_id=x.merchant_application_id WHERE x.m1_11_row_hash<>o.row_hash OR x.archetype_code<>o.archetype_code OR x.operating_resilience_score IS DISTINCT FROM o.operating_resilience_score))::text,
        ('0')::text,
        coalesce(((SELECT count(*)=0 FROM _m1_15_vlatest x JOIN msbf_m1.application_operating_resilience_snapshot o ON o.module1_run_id=x.module1_run_id AND o.scenario_id=x.scenario_id AND o.merchant_application_id=x.merchant_application_id WHERE x.m1_11_row_hash<>o.row_hash OR x.archetype_code<>o.archetype_code OR x.operating_resilience_score IS DISTINCT FROM o.operating_resilience_score)),false),
        'M1.11 resilience reproduces exactly.'
    );
    PERFORM pg_temp.m1_15_add_check(
        'M1_15_POS_72_M1_9_REPRODUCTION',
        'M1.9 cash-flow reproduction mismatches',
        ((SELECT count(*)::text FROM _m1_15_vlatest x JOIN msbf_m1.application_cashflow_feature_snapshot f ON f.module1_run_id=x.module1_run_id AND f.scenario_id=x.scenario_id AND f.merchant_application_id=x.merchant_application_id WHERE x.m1_9_row_hash<>f.feature_snapshot_hash OR x.source_confidence_score<>f.source_confidence_score OR x.avg_daily_eligible_sales_30d IS DISTINCT FROM f.avg_daily_eligible_sales_30d))::text,
        ('0')::text,
        coalesce(((SELECT count(*)=0 FROM _m1_15_vlatest x JOIN msbf_m1.application_cashflow_feature_snapshot f ON f.module1_run_id=x.module1_run_id AND f.scenario_id=x.scenario_id AND f.merchant_application_id=x.merchant_application_id WHERE x.m1_9_row_hash<>f.feature_snapshot_hash OR x.source_confidence_score<>f.source_confidence_score OR x.avg_daily_eligible_sales_30d IS DISTINCT FROM f.avg_daily_eligible_sales_30d)),false),
        'M1.9 cash-flow features reproduce exactly.'
    );
    PERFORM pg_temp.m1_15_add_check(
        'M1_15_POS_73_M1_8_REPRODUCTION',
        'M1.8 verification reproduction mismatches',
        ((SELECT count(*)::text FROM _m1_15_vlatest x JOIN msbf_m1.application_verification_fraud_snapshot v ON v.module1_run_id=x.module1_run_id AND v.merchant_application_id=x.merchant_application_id WHERE x.m1_8_row_hash<>v.row_hash OR x.verification_disposition<>v.verification_disposition OR x.fraud_risk_tier<>v.fraud_risk_tier))::text,
        ('0')::text,
        coalesce(((SELECT count(*)=0 FROM _m1_15_vlatest x JOIN msbf_m1.application_verification_fraud_snapshot v ON v.module1_run_id=x.module1_run_id AND v.merchant_application_id=x.merchant_application_id WHERE x.m1_8_row_hash<>v.row_hash OR x.verification_disposition<>v.verification_disposition OR x.fraud_risk_tier<>v.fraud_risk_tier)),false),
        'M1.8 verification/fraud reproduces exactly.'
    );
    PERFORM pg_temp.m1_15_add_check(
        'M1_15_POS_74_HARD_STOP_IDENTITY',
        'Hard-stop aggregate mismatches',
        ((SELECT count(*)::text FROM _m1_15_vlatest x JOIN msbf_m1.application_verification_fraud_snapshot v ON v.module1_run_id=x.module1_run_id AND v.merchant_application_id=x.merchant_application_id JOIN msbf_m1.application_integrated_risk_proxy_snapshot r ON r.module1_run_id=x.module1_run_id AND r.scenario_id=x.scenario_id AND r.merchant_application_id=x.merchant_application_id JOIN msbf_m1.application_exposure_recovery_loss_snapshot l ON l.module1_run_id=x.module1_run_id AND l.scenario_id=x.scenario_id AND l.merchant_application_id=x.merchant_application_id JOIN msbf_m1.application_unit_economics_snapshot e ON e.module1_run_id=x.module1_run_id AND e.scenario_id=x.scenario_id AND e.merchant_application_id=x.merchant_application_id WHERE x.hard_stop_recommended_flag IS DISTINCT FROM (v.hard_stop_recommended_flag OR r.hard_stop_recommended_flag OR l.hard_stop_recommended_flag OR e.hard_stop_recommended_flag)))::text,
        ('0')::text,
        coalesce(((SELECT count(*)=0 FROM _m1_15_vlatest x JOIN msbf_m1.application_verification_fraud_snapshot v ON v.module1_run_id=x.module1_run_id AND v.merchant_application_id=x.merchant_application_id JOIN msbf_m1.application_integrated_risk_proxy_snapshot r ON r.module1_run_id=x.module1_run_id AND r.scenario_id=x.scenario_id AND r.merchant_application_id=x.merchant_application_id JOIN msbf_m1.application_exposure_recovery_loss_snapshot l ON l.module1_run_id=x.module1_run_id AND l.scenario_id=x.scenario_id AND l.merchant_application_id=x.merchant_application_id JOIN msbf_m1.application_unit_economics_snapshot e ON e.module1_run_id=x.module1_run_id AND e.scenario_id=x.scenario_id AND e.merchant_application_id=x.merchant_application_id WHERE x.hard_stop_recommended_flag IS DISTINCT FROM (v.hard_stop_recommended_flag OR r.hard_stop_recommended_flag OR l.hard_stop_recommended_flag OR e.hard_stop_recommended_flag))),false),
        'Contract hard-stop is the governed upstream union.'
    );
    PERFORM pg_temp.m1_15_add_check(
        'M1_15_POS_75_MANUAL_REVIEW_IDENTITY',
        'Manual-review aggregate mismatches',
        ((SELECT count(*)::text FROM _m1_15_vlatest WHERE manual_review_recommended_flag=false AND contract_evidence_status<>'COMPLETE'))::text,
        ('0')::text,
        coalesce(((SELECT count(*)=0 FROM _m1_15_vlatest WHERE manual_review_recommended_flag=false AND contract_evidence_status<>'COMPLETE')),false),
        'Non-complete contracts remain reviewed.'
    );
    PERFORM pg_temp.m1_15_add_check(
        'M1_15_POS_76_FALLBACK_COMPLETENESS',
        'Missing fallback paths',
        ((SELECT count(*)::text FROM _m1_15_vlatest WHERE fallback_path_code IS NULL OR btrim(fallback_path_code)=''))::text,
        ('0')::text,
        coalesce(((SELECT count(*)=0 FROM _m1_15_vlatest WHERE fallback_path_code IS NULL OR btrim(fallback_path_code)='')),false),
        'Every contract has a fallback path.'
    );
    PERFORM pg_temp.m1_15_add_check(
        'M1_15_POS_77_REASON_COMPLETENESS',
        'Missing primary contract reasons',
        ((SELECT count(*)::text FROM _m1_15_vlatest WHERE primary_contract_reason_code IS NULL OR btrim(primary_contract_reason_code)=''))::text,
        ('0')::text,
        coalesce(((SELECT count(*)=0 FROM _m1_15_vlatest WHERE primary_contract_reason_code IS NULL OR btrim(primary_contract_reason_code)='')),false),
        'Every contract has a primary reason.'
    );
    PERFORM pg_temp.m1_15_add_check(
        'M1_15_POS_78_SOURCE_PAYLOAD',
        'Invalid source payloads',
        ((SELECT count(*)::text FROM _m1_15_vlatest WHERE jsonb_typeof(source_payload)<>'object'))::text,
        ('0')::text,
        coalesce(((SELECT count(*)=0 FROM _m1_15_vlatest WHERE jsonb_typeof(source_payload)<>'object')),false),
        'Source payloads are valid JSON objects.'
    );
    PERFORM pg_temp.m1_15_add_check(
        'M1_15_POS_79_LINEAGE_PAYLOAD',
        'Invalid lineage payloads',
        ((SELECT count(*)::text FROM _m1_15_vlatest WHERE jsonb_typeof(lineage_payload)<>'object' OR lineage_payload->>'m1_14'<>m1_14_row_hash))::text,
        ('0')::text,
        coalesce(((SELECT count(*)=0 FROM _m1_15_vlatest WHERE jsonb_typeof(lineage_payload)<>'object' OR lineage_payload->>'m1_14'<>m1_14_row_hash)),false),
        'Lineage payloads include the accepted M1.14 row hash.'
    );
    PERFORM pg_temp.m1_15_add_check(
        'M1_15_POS_80_UPSTREAM_COUNTS',
        'Upstream source count failures',
        ((SELECT count(*)::text FROM (VALUES ((SELECT count(*) FROM msbf_m1.application_verification_fraud_snapshot WHERE module1_run_id=(SELECT run_id FROM _m1_15_vctx)),750),((SELECT count(*) FROM msbf_m1.application_cashflow_feature_snapshot WHERE module1_run_id=(SELECT run_id FROM _m1_15_vctx)),1500),((SELECT count(*) FROM msbf_m1.application_liquidity_capacity_snapshot WHERE module1_run_id=(SELECT run_id FROM _m1_15_vctx)),1500),((SELECT count(*) FROM msbf_m1.application_operating_resilience_snapshot WHERE module1_run_id=(SELECT run_id FROM _m1_15_vctx)),1500),((SELECT count(*) FROM msbf_m1.application_integrated_risk_proxy_snapshot WHERE module1_run_id=(SELECT run_id FROM _m1_15_vctx)),1500),((SELECT count(*) FROM msbf_m1.application_exposure_recovery_loss_snapshot WHERE module1_run_id=(SELECT run_id FROM _m1_15_vctx)),1500),((SELECT count(*) FROM msbf_m1.application_unit_economics_snapshot WHERE module1_run_id=(SELECT run_id FROM _m1_15_vctx)),1500)) x(actual,expected) WHERE actual<>expected))::text,
        ('0')::text,
        coalesce(((SELECT count(*)=0 FROM (VALUES ((SELECT count(*) FROM msbf_m1.application_verification_fraud_snapshot WHERE module1_run_id=(SELECT run_id FROM _m1_15_vctx)),750),((SELECT count(*) FROM msbf_m1.application_cashflow_feature_snapshot WHERE module1_run_id=(SELECT run_id FROM _m1_15_vctx)),1500),((SELECT count(*) FROM msbf_m1.application_liquidity_capacity_snapshot WHERE module1_run_id=(SELECT run_id FROM _m1_15_vctx)),1500),((SELECT count(*) FROM msbf_m1.application_operating_resilience_snapshot WHERE module1_run_id=(SELECT run_id FROM _m1_15_vctx)),1500),((SELECT count(*) FROM msbf_m1.application_integrated_risk_proxy_snapshot WHERE module1_run_id=(SELECT run_id FROM _m1_15_vctx)),1500),((SELECT count(*) FROM msbf_m1.application_exposure_recovery_loss_snapshot WHERE module1_run_id=(SELECT run_id FROM _m1_15_vctx)),1500),((SELECT count(*) FROM msbf_m1.application_unit_economics_snapshot WHERE module1_run_id=(SELECT run_id FROM _m1_15_vctx)),1500)) x(actual,expected) WHERE actual<>expected)),false),
        'All accepted source populations remain complete.'
    );
    PERFORM pg_temp.m1_15_add_check(
        'M1_15_POS_81_LEGACY_OUTPUT_BOUNDARY',
        'Legacy latest/archive rows',
        ((SELECT ((SELECT count(*) FROM msbf_m1.module1_latest WHERE module1_run_id=(SELECT run_id FROM _m1_15_vctx))+(SELECT count(*) FROM msbf_m1.module1_archive WHERE module1_run_id=(SELECT run_id FROM _m1_15_vctx)))::text))::text,
        ('0')::text,
        coalesce(((SELECT (SELECT count(*) FROM msbf_m1.module1_latest WHERE module1_run_id=(SELECT run_id FROM _m1_15_vctx))+(SELECT count(*) FROM msbf_m1.module1_archive WHERE module1_run_id=(SELECT run_id FROM _m1_15_vctx))=0)),false),
        'Legacy placeholder outputs remain unused; M1.15 uses the versioned contract tables.'
    );
    PERFORM pg_temp.m1_15_add_check(
        'M1_15_POS_82_DECISION_BOUNDARY',
        'Premature risk-output rows',
        ((SELECT ((SELECT count(*) FROM msbf_m1.merchant_risk_snapshot WHERE module1_run_id=(SELECT run_id FROM _m1_15_vctx))+(SELECT count(*) FROM msbf_m1.risk_component_detail WHERE module1_run_id=(SELECT run_id FROM _m1_15_vctx)))::text))::text,
        ('0')::text,
        coalesce(((SELECT (SELECT count(*) FROM msbf_m1.merchant_risk_snapshot WHERE module1_run_id=(SELECT run_id FROM _m1_15_vctx))+(SELECT count(*) FROM msbf_m1.risk_component_detail WHERE module1_run_id=(SELECT run_id FROM _m1_15_vctx))=0)),false),
        'M1.15 does not create legacy decision outputs.'
    );
    PERFORM pg_temp.m1_15_add_check(
        'M1_15_POS_83_BLOCKING_ERRORS',
        'Blocking configuration errors',
        ((SELECT count(*)::text FROM msbf_ctl.profile_resolution_error WHERE run_id=(SELECT run_id FROM _m1_15_vctx) AND severity='BLOCKING'))::text,
        ('0')::text,
        coalesce(((SELECT count(*)=0 FROM msbf_ctl.profile_resolution_error WHERE run_id=(SELECT run_id FROM _m1_15_vctx) AND severity='BLOCKING')),false),
        'No blocking configuration errors remain.'
    );
    PERFORM pg_temp.m1_15_add_check(
        'M1_15_POS_84_CANONICAL_ENTITY_COUNT',
        'Canonical entities',
        ((SELECT ((SELECT count(*) FROM _m1_15_vlatest)+(SELECT count(*) FROM _m1_15_varchive)+(SELECT count(*) FROM _m1_15_vcomparison)+(SELECT count(*) FROM _m1_15_vcontract))::text))::text,
        ('3751')::text,
        coalesce(((SELECT (SELECT count(*) FROM _m1_15_vlatest)+(SELECT count(*) FROM _m1_15_varchive)+(SELECT count(*) FROM _m1_15_vcomparison)+(SELECT count(*) FROM _m1_15_vcontract)=3751)),false),
        'The complete contract reconciliation universe contains 3,751 entities.'
    );
END;
$checks$;

DO $inventory$
BEGIN
    IF (SELECT count(*) FROM _m1_15_validation)<>84 THEN
        RAISE EXCEPTION 'M1.15 expected 84 positive controls; observed %.',
            (SELECT count(*) FROM _m1_15_validation);
    END IF;
END;
$inventory$;

DELETE FROM msbf_ctl.run_evidence
WHERE run_id=(SELECT run_id FROM _m1_15_vctx)
  AND evidence_code LIKE 'M1_15_POS_%';

INSERT INTO msbf_ctl.run_evidence(
    run_id,evidence_code,segment_key,metric_name,metric_value_text,
    unit_code,status,interpretation
)
SELECT
    (SELECT run_id FROM _m1_15_vctx),
    evidence_code,'PORTFOLIO',metric_name,observed_value,
    'TEXT',status,
    interpretation||' Threshold: '||threshold_value
FROM _m1_15_validation;

UPDATE msbf_ctl.m1_15_consumption_contract_registry
SET contract_status=CASE
      WHEN (SELECT count(*) FILTER(WHERE status='FAIL') FROM _m1_15_validation)=0
      THEN 'VALIDATED' ELSE 'GENERATED' END,
    validated_at=CASE
      WHEN (SELECT count(*) FILTER(WHERE status='FAIL') FROM _m1_15_validation)=0
      THEN clock_timestamp() ELSE NULL END
WHERE module1_run_id=(SELECT run_id FROM _m1_15_vctx);

UPDATE msbf_ctl.run_registry
SET run_status=CASE
      WHEN (SELECT count(*) FILTER(WHERE status='FAIL') FROM _m1_15_validation)=0
      THEN 'M1_15_VALIDATED' ELSE 'M1_15_FAILED' END
WHERE run_id=(SELECT run_id FROM _m1_15_vctx);

COMMIT;

SELECT
    evidence_code,metric_name,observed_value,threshold_value,status,interpretation
FROM _m1_15_validation
ORDER BY evidence_code;
