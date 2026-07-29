/**********************************************************************
MSBF Physical Foundation Live Execution Validation Report
Version : v0.2
Purpose : Enterprise Physical Build Acceptance Evidence
**********************************************************************/

WITH

-----------------------------------------------------------------------
-- Designed Parent and Non-Partition Tables
-----------------------------------------------------------------------

designed_tables AS (

    SELECT c.oid

    FROM pg_class c

    JOIN pg_namespace n
        ON n.oid = c.relnamespace

    WHERE n.nspname LIKE 'msbf_%'
      AND c.relkind IN ('r', 'p')

      AND NOT EXISTS (

            SELECT 1

            FROM pg_inherits i

            WHERE i.inhrelid = c.oid

      )

),

-----------------------------------------------------------------------
-- Child Table Partitions
-- pg_inherits also tracks partitioned-index inheritance. Restricting
-- relkind to ordinary tables prevents index partitions from entering
-- table and column counts.
-----------------------------------------------------------------------

child_partitions AS (

    SELECT c.oid

    FROM pg_class c

    JOIN pg_namespace n
        ON n.oid = c.relnamespace

    WHERE n.nspname LIKE 'msbf_%'
      AND c.relkind = 'r'

      AND EXISTS (

            SELECT 1

            FROM pg_inherits i

            WHERE i.inhrelid = c.oid

      )

),

-----------------------------------------------------------------------
-- Views
-----------------------------------------------------------------------

project_views AS (

    SELECT c.oid

    FROM pg_class c

    JOIN pg_namespace n
        ON n.oid = c.relnamespace

    WHERE n.nspname LIKE 'msbf_%'
      AND c.relkind = 'v'

)

SELECT

    CURRENT_TIMESTAMP AS execution_timestamp,

    current_database() AS database_name,

    current_user AS database_user,

    version() AS postgresql_version,

    -------------------------------------------------------------------
    -- Schemas
    -------------------------------------------------------------------

    (
        SELECT COUNT(*)
        FROM information_schema.schemata
        WHERE schema_name LIKE 'msbf_%'
    ) AS schema_count,

    -------------------------------------------------------------------
    -- Tables
    -------------------------------------------------------------------

    (
        SELECT COUNT(*)
        FROM designed_tables
    ) AS designed_tables,

    (
        SELECT COUNT(*)
        FROM child_partitions
    ) AS child_partition_tables,

    (
        SELECT COUNT(*)
        FROM information_schema.tables
        WHERE table_schema LIKE 'msbf_%'
          AND table_type = 'BASE TABLE'
    ) AS physical_table_relations,

    -------------------------------------------------------------------
    -- Columns
    -------------------------------------------------------------------

    (
        SELECT COUNT(*)
        FROM pg_attribute a
        WHERE a.attrelid IN (SELECT oid FROM designed_tables)
          AND a.attnum > 0
          AND NOT a.attisdropped
    ) AS designed_table_columns,

    (
        SELECT COUNT(*)
        FROM pg_attribute a
        WHERE a.attrelid IN (SELECT oid FROM child_partitions)
          AND a.attnum > 0
          AND NOT a.attisdropped
    ) AS child_partition_table_columns,

    (
        SELECT COUNT(*)
        FROM pg_attribute a
        WHERE a.attrelid IN (SELECT oid FROM project_views)
          AND a.attnum > 0
          AND NOT a.attisdropped
    ) AS view_columns,

    (
        SELECT COUNT(*)
        FROM information_schema.columns
        WHERE table_schema LIKE 'msbf_%'
    ) AS information_schema_columns,

    -------------------------------------------------------------------
    -- Views
    -------------------------------------------------------------------

    (
        SELECT COUNT(*)
        FROM project_views
    ) AS views,

    -------------------------------------------------------------------
    -- Functions
    -------------------------------------------------------------------

    (
        SELECT COUNT(*)
        FROM pg_proc p
        JOIN pg_namespace n
            ON n.oid = p.pronamespace
        WHERE n.nspname LIKE 'msbf_%'
          AND p.prokind = 'f'
    ) AS functions,

    -------------------------------------------------------------------
    -- Constraints
    -------------------------------------------------------------------

    (
        SELECT COUNT(*)
        FROM pg_constraint con
        WHERE con.conrelid IN (SELECT oid FROM designed_tables)
          AND con.contype = 'p'
    ) AS primary_keys,

    (
        SELECT COUNT(*)
        FROM pg_constraint con
        WHERE con.conrelid IN (SELECT oid FROM designed_tables)
          AND con.contype = 'f'
    ) AS designed_foreign_keys,

    (
        SELECT COUNT(*)
        FROM pg_constraint con
        WHERE con.conrelid IN (SELECT oid FROM child_partitions)
          AND con.contype = 'f'
    ) AS child_partition_foreign_keys,

    (
        SELECT COUNT(*)
        FROM pg_constraint con
        JOIN pg_class c
            ON c.oid = con.conrelid
        JOIN pg_namespace n
            ON n.oid = c.relnamespace
        WHERE n.nspname LIKE 'msbf_%'
          AND con.contype = 'f'
    ) AS total_foreign_keys,

    -------------------------------------------------------------------
    -- Seed Validation
    -------------------------------------------------------------------

    (
        SELECT COUNT(*)
        FROM msbf_ctl.parameter_definition
    ) AS parameter_definitions,

    (
        SELECT COUNT(*)
        FROM msbf_ctl.parameter_set
    ) AS parameter_sets,

    (
        SELECT COUNT(*)
        FROM msbf_ctl.parameter_value
    ) AS parameter_values,

    (
        SELECT COUNT(*)
        FROM msbf_m1.feature_definition
    ) AS feature_definitions,

    (
        SELECT COUNT(*)
        FROM msbf_ref.industry
    ) AS industries,

    -------------------------------------------------------------------
    -- Operational State Before Module 1 Generation
    -------------------------------------------------------------------

    (
        SELECT COUNT(*)
        FROM msbf_m1.merchant_master
    ) AS merchants,

    (
        SELECT COUNT(*)
        FROM msbf_m1.merchant_application
    ) AS applications,

    (
        SELECT COUNT(*)
        FROM msbf_m1.module1_latest
    ) AS latest_results,

    (
        SELECT COUNT(*)
        FROM msbf_m1.module1_archive
    ) AS archive_results;