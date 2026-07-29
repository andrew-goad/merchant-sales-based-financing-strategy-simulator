/* ============================================================================
MSBF M1.15 Read-Only Generation Reconciliation Reconstruction
Program : 110A_msbf_m1_15_generation_reconciliation_reconstructed_v0_2R3.sql
Use     : Only if program 110 committed but its DBeaver result tab was lost.
============================================================================ */

WITH r AS (
    SELECT run_id,run_status
    FROM msbf_ctl.run_registry
    WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
), c AS (
    SELECT * FROM msbf_ctl.m1_15_consumption_contract_registry
    WHERE module1_run_id=(SELECT run_id FROM r)
), rows AS (
    SELECT
      (SELECT count(*) FROM msbf_m1.application_module1_latest
       WHERE module1_run_id=(SELECT run_id FROM r)) AS latest_rows,
      (SELECT count(*) FROM msbf_m1.application_module1_archive
       WHERE module1_run_id=(SELECT run_id FROM r)) AS archive_rows,
      (SELECT count(*) FROM msbf_m1.application_module1_scenario_comparison
       WHERE module1_run_id=(SELECT run_id FROM r)) AS comparison_rows,
      (SELECT count(*) FROM msbf_m1.application_module1_latest l
       WHERE l.module1_run_id=(SELECT run_id FROM r)
         AND l.contract_row_hash IS DISTINCT FROM
             msbf_m1.m1_15_hash_jsonb(to_jsonb(l)-'contract_row_hash'-'created_at'))
          AS latest_mismatches,
      (SELECT count(*) FROM msbf_m1.application_module1_archive a
       JOIN msbf_m1.application_module1_latest l
         ON l.module1_run_id=a.module1_run_id
        AND l.scenario_id=a.scenario_id
        AND l.merchant_application_id=a.merchant_application_id
       WHERE a.module1_run_id=(SELECT run_id FROM r)
         AND (a.contract_row_hash IS DISTINCT FROM l.contract_row_hash
           OR a.contract_payload IS DISTINCT FROM to_jsonb(l)-'created_at'))
          AS archive_mismatches,
      (SELECT count(*) FROM msbf_m1.application_module1_scenario_comparison x
       WHERE x.module1_run_id=(SELECT run_id FROM r)
         AND x.comparison_row_hash IS DISTINCT FROM
             msbf_m1.m1_15_hash_jsonb(to_jsonb(x)-'comparison_row_hash'-'created_at'))
          AS comparison_mismatches
), actual AS (
    SELECT 'LATEST|'||scenario_id||'|'||merchant_application_id AS entity_key,
           contract_row_hash AS row_hash
    FROM msbf_m1.application_module1_latest
    WHERE module1_run_id=(SELECT run_id FROM r)
    UNION ALL
    SELECT ('ARCHIVE|'||contract_version::text||'|'||scenario_id::text||'|'||merchant_application_id)::text,
           contract_row_hash::text
    FROM msbf_m1.application_module1_archive
    WHERE module1_run_id=(SELECT run_id FROM r)
    UNION ALL
    SELECT ('COMPARE|'||merchant_application_id)::text,comparison_row_hash::text
    FROM msbf_m1.application_module1_scenario_comparison
    WHERE module1_run_id=(SELECT run_id FROM r)
    UNION ALL
    SELECT ('CONTRACT|'||contract_code||'|'||contract_version::text||'|'||module1_run_id::text)::text,
           contract_row_hash::text
    FROM c
), h AS (
    SELECT count(*) AS canonical_entities,
           md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key))
               AS actual_combined_hash
    FROM actual
)
SELECT r.run_id,r.run_status,c.contract_code,c.contract_version,c.schema_version,
       c.contract_status,
       rows.latest_rows,
       rows.archive_rows,
       rows.comparison_rows,
       rows.latest_mismatches,
       rows.archive_mismatches,
       rows.comparison_mismatches,
       h.canonical_entities,
       c.latest_set_hash,c.archive_set_hash,c.comparison_set_hash,
       c.contract_set_hash,c.combined_set_hash,h.actual_combined_hash,
       CASE WHEN r.run_status IN ('M1_15_GENERATED','M1_15_VALIDATED','M1_15_ACCEPTED')
              AND rows.latest_rows=1500 AND rows.archive_rows=1500
              AND rows.comparison_rows=750
              AND rows.latest_mismatches=0 AND rows.archive_mismatches=0
              AND rows.comparison_mismatches=0
              AND h.canonical_entities=3751
              AND c.combined_set_hash=h.actual_combined_hash
            THEN 'PASS' ELSE 'FAIL' END AS generation_reconciliation_status
FROM r CROSS JOIN c CROSS JOIN rows CROSS JOIN h;
