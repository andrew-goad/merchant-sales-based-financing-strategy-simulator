/* Recovery check after failed Program 172. */
SELECT run_status, (SELECT count(*) FROM information_schema.tables WHERE table_schema IN ('msbf_ctl','msbf_m2') AND lower(table_name) LIKE '%m2_6%') AS m2_6_object_count, CASE WHEN run_status='M2_5_ACCEPTED' THEN 'PASS' ELSE 'FAIL' END AS recovery_status FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1;
