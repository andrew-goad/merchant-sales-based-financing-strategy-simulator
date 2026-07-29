/* ============================================================================
MSBF M1.2 Failed-Generation Recovery State Check
Version : v0.2R2
Purpose : Confirm that the failed v0.2R1 generation transaction rolled back and
          that accepted G1 state remains eligible for a clean v0.2R2 rerun.

This script is read-only.
============================================================================ */

WITH ctx AS (
    SELECT r.run_id, r.run_code, r.run_version, r.run_status,
           r.population_id, r.parameter_snapshot_hash,
           r.profile_snapshot_hash, r.source_snapshot_hash,
           p.population_status
    FROM msbf_ctl.run_registry r
    JOIN msbf_m1.population_registry p ON p.population_id=r.population_id
    WHERE r.run_code='M1_V0_2_BASELINE_BUILD'
      AND r.run_version=1
), counts AS (
    SELECT
      (SELECT COUNT(*) FROM msbf_m1.merchant_master m
        WHERE m.population_id=(SELECT population_id FROM ctx)) AS merchants,
      (SELECT COUNT(*) FROM msbf_m1.merchant_owner_guarantor o
        JOIN msbf_m1.merchant_master m ON m.merchant_id=o.merchant_id
        WHERE m.population_id=(SELECT population_id FROM ctx)) AS owners,
      (SELECT COUNT(*) FROM msbf_m1.merchant_industry_assignment i
        JOIN msbf_m1.merchant_master m ON m.merchant_id=i.merchant_id
        WHERE m.population_id=(SELECT population_id FROM ctx)) AS industry_rows,
      (SELECT COUNT(*) FROM msbf_m1.partner_channel
        WHERE created_by_run_id=(SELECT run_id FROM ctx)) AS partner_channels,
      (SELECT COUNT(*) FROM msbf_m1.processor_account
        WHERE created_by_run_id=(SELECT run_id FROM ctx)) AS processor_accounts,
      (SELECT COUNT(*) FROM msbf_m1.merchant_relationship_snapshot
        WHERE created_by_run_id=(SELECT run_id FROM ctx)) AS relationship_rows,
      (SELECT COUNT(*) FROM msbf_m1.merchant_application
        WHERE created_by_run_id=(SELECT run_id FROM ctx)) AS applications,
      (SELECT COUNT(*) FROM msbf_m1.module1_latest
        WHERE module1_run_id=(SELECT run_id FROM ctx)) AS latest_rows,
      (SELECT COUNT(*) FROM msbf_m1.module1_archive
        WHERE module1_run_id=(SELECT run_id FROM ctx)) AS archive_rows
)
SELECT clock_timestamp() AS report_timestamp,
       current_database() AS database_name,
       current_user AS database_user,
       ctx.*,
       counts.*,
       CASE
         WHEN ctx.run_status='G1_READY'
          AND ctx.population_status='READY_FOR_GENERATION'
          AND ctx.parameter_snapshot_hash='bd09e598c82db96e47459d77fd11e7c8'
          AND ctx.profile_snapshot_hash='462cbd2ed92f68e5bdecf6b17537a973'
          AND ctx.source_snapshot_hash='93c3d1368fb2450ab4a08e2b721f92d3'
          AND counts.merchants=0
          AND counts.owners=0
          AND counts.industry_rows=0
          AND counts.partner_channels=0
          AND counts.processor_accounts=0
          AND counts.relationship_rows=0
          AND counts.applications=0
          AND counts.latest_rows=0
          AND counts.archive_rows=0
         THEN 'PASS'
         ELSE 'FAIL'
       END AS recovery_state_status
FROM ctx CROSS JOIN counts;
