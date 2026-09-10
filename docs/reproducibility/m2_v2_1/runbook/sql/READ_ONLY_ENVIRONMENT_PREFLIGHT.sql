-- PUB-RUN-001: metadata inspection only. Run with psql -X -v ON_ERROR_STOP=1.
-- Connect to maintenance database postgres on the isolated/local test server.
-- This is not a substitute for the source runtime's exact database preflight.
BEGIN READ ONLY;
SET LOCAL statement_timeout = '30s';
SELECT current_database() AS connected_database,
       current_user AS connected_user,
       current_setting('server_version') AS server_version,
       current_setting('server_version_num') AS server_version_num,
       current_setting('data_directory') AS data_directory,
       current_setting('transaction_read_only') AS transaction_read_only;
SELECT system_identifier::text AS server_system_identifier
FROM pg_control_system();
SELECT datname AS database_name,
       oid::text AS database_oid,
       pg_database_size(oid) AS size_bytes,
       pg_encoding_to_char(encoding) AS encoding,
       datcollate AS collation,
       datctype AS ctype
FROM pg_database
WHERE datname IN (
    'msbf_r1_m2_4_r6_20260830_030634',
    'msbf_r1_r26_g3v2_20260902_024119',
    'msbf_r1_r26_resume_g3v2_20260902_070655'
)
ORDER BY datname;
COMMIT;
