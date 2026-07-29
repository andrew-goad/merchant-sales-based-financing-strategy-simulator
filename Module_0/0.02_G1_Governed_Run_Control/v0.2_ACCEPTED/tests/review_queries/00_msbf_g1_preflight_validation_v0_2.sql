/* ============================================================================
MSBF G1 Preflight Validation
Version : v0.2
Purpose : Confirm the accepted G0 physical foundation is present and unchanged
          before G1 configuration objects are created.

Execution: Run once, before sql/02_msbf_g1_run_configuration_bootstrap_v0_2.sql.
Expected : Completes without exception and returns one PASS row.
Boundary : This script is read-only.
============================================================================ */

DO $$
DECLARE
    v_server_version_num integer := current_setting('server_version_num')::integer;
    v_schema_count integer;
    v_designed_tables integer;
    v_child_tables integer;
    v_physical_relations integer;
    v_designed_columns integer;
    v_child_columns integer;
    v_view_columns integer;
    v_view_count integer;
    v_function_count integer;
    v_primary_keys integer;
    v_designed_fks integer;
    v_child_fks integer;
    v_parameter_definitions integer;
    v_parameter_sets integer;
    v_parameter_values integer;
    v_feature_definitions integer;
    v_industries integer;
    v_operational_rows bigint;
BEGIN
    IF current_database() <> 'msbf_strategy' THEN
        RAISE EXCEPTION 'G1 preflight must run in database msbf_strategy; current database is %', current_database();
    END IF;

    IF v_server_version_num < 140000 THEN
        RAISE EXCEPTION 'PostgreSQL 14 or later is required; server_version_num=%', v_server_version_num;
    END IF;

    SELECT COUNT(*) INTO v_schema_count
    FROM information_schema.schemata
    WHERE schema_name LIKE 'msbf_%';

    WITH designed_tables AS (
        SELECT c.oid
        FROM pg_class c
        JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE n.nspname LIKE 'msbf_%'
          AND c.relkind IN ('r','p')
          AND NOT EXISTS (
              SELECT 1 FROM pg_inherits i WHERE i.inhrelid = c.oid
          )
    ),
    child_partitions AS (
        SELECT c.oid
        FROM pg_class c
        JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE n.nspname LIKE 'msbf_%'
          AND c.relkind = 'r'
          AND EXISTS (
              SELECT 1 FROM pg_inherits i WHERE i.inhrelid = c.oid
          )
    ),
    project_views AS (
        SELECT c.oid
        FROM pg_class c
        JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE n.nspname LIKE 'msbf_%'
          AND c.relkind = 'v'
    )
    SELECT
        (SELECT COUNT(*) FROM designed_tables),
        (SELECT COUNT(*) FROM child_partitions),
        (SELECT COUNT(*)
           FROM information_schema.tables
          WHERE table_schema LIKE 'msbf_%'
            AND table_type = 'BASE TABLE'),
        (SELECT COUNT(*)
           FROM pg_attribute a
          WHERE a.attrelid IN (SELECT oid FROM designed_tables)
            AND a.attnum > 0
            AND NOT a.attisdropped),
        (SELECT COUNT(*)
           FROM pg_attribute a
          WHERE a.attrelid IN (SELECT oid FROM child_partitions)
            AND a.attnum > 0
            AND NOT a.attisdropped),
        (SELECT COUNT(*)
           FROM pg_attribute a
          WHERE a.attrelid IN (SELECT oid FROM project_views)
            AND a.attnum > 0
            AND NOT a.attisdropped),
        (SELECT COUNT(*) FROM project_views),
        (SELECT COUNT(*)
           FROM pg_proc p
           JOIN pg_namespace n ON n.oid = p.pronamespace
          WHERE n.nspname LIKE 'msbf_%'
            AND p.prokind = 'f'),
        (SELECT COUNT(*)
           FROM pg_constraint con
          WHERE con.conrelid IN (SELECT oid FROM designed_tables)
            AND con.contype = 'p'),
        (SELECT COUNT(*)
           FROM pg_constraint con
          WHERE con.conrelid IN (SELECT oid FROM designed_tables)
            AND con.contype = 'f'),
        (SELECT COUNT(*)
           FROM pg_constraint con
          WHERE con.conrelid IN (SELECT oid FROM child_partitions)
            AND con.contype = 'f')
    INTO
        v_designed_tables,
        v_child_tables,
        v_physical_relations,
        v_designed_columns,
        v_child_columns,
        v_view_columns,
        v_view_count,
        v_function_count,
        v_primary_keys,
        v_designed_fks,
        v_child_fks;

    SELECT COUNT(*) INTO v_parameter_definitions FROM msbf_ctl.parameter_definition;
    SELECT COUNT(*) INTO v_parameter_sets FROM msbf_ctl.parameter_set;
    SELECT COUNT(*) INTO v_parameter_values FROM msbf_ctl.parameter_value;
    SELECT COUNT(*) INTO v_feature_definitions FROM msbf_m1.feature_definition;
    SELECT COUNT(*) INTO v_industries FROM msbf_ref.industry;

    SELECT
          (SELECT COUNT(*) FROM msbf_m1.merchant_master)
        + (SELECT COUNT(*) FROM msbf_m1.merchant_application)
        + (SELECT COUNT(*) FROM msbf_m1.merchant_pos_daily_base)
        + (SELECT COUNT(*) FROM msbf_m1.merchant_deposit_daily_base)
        + (SELECT COUNT(*) FROM msbf_m1.merchant_feature_snapshot)
        + (SELECT COUNT(*) FROM msbf_m1.merchant_risk_snapshot)
        + (SELECT COUNT(*) FROM msbf_m1.module1_latest)
        + (SELECT COUNT(*) FROM msbf_m1.module1_archive)
    INTO v_operational_rows;

    IF v_schema_count <> 8 THEN RAISE EXCEPTION 'Expected 8 project schemas; observed %', v_schema_count; END IF;
    IF v_designed_tables <> 70 THEN RAISE EXCEPTION 'Expected 70 designed tables; observed %', v_designed_tables; END IF;
    IF v_child_tables <> 4 THEN RAISE EXCEPTION 'Expected 4 child table partitions; observed %', v_child_tables; END IF;
    IF v_physical_relations <> 74 THEN RAISE EXCEPTION 'Expected 74 physical base-table relations; observed %', v_physical_relations; END IF;
    IF v_designed_columns <> 1041 THEN RAISE EXCEPTION 'Expected 1041 designed-table columns; observed %', v_designed_columns; END IF;
    IF v_child_columns <> 80 THEN RAISE EXCEPTION 'Expected 80 child-partition columns; observed %', v_child_columns; END IF;
    IF v_view_columns <> 92 THEN RAISE EXCEPTION 'Expected 92 view columns; observed %', v_view_columns; END IF;
    IF v_view_count <> 5 THEN RAISE EXCEPTION 'Expected 5 views; observed %', v_view_count; END IF;
    IF v_function_count <> 3 THEN RAISE EXCEPTION 'Expected 3 functions; observed %', v_function_count; END IF;
    IF v_primary_keys <> 70 THEN RAISE EXCEPTION 'Expected 70 designed-table primary keys; observed %', v_primary_keys; END IF;
    IF v_designed_fks <> 141 THEN RAISE EXCEPTION 'Expected 141 designed-table foreign keys; observed %', v_designed_fks; END IF;
    IF v_child_fks <> 20 THEN RAISE EXCEPTION 'Expected 20 child-partition foreign keys; observed %', v_child_fks; END IF;
    IF v_parameter_definitions <> 155 THEN RAISE EXCEPTION 'Expected 155 parameter definitions; observed %', v_parameter_definitions; END IF;
    IF v_parameter_sets <> 1 THEN RAISE EXCEPTION 'Expected 1 G0 parameter set before G1; observed %', v_parameter_sets; END IF;
    IF v_parameter_values <> 397 THEN RAISE EXCEPTION 'Expected 397 G0 parameter values before G1; observed %', v_parameter_values; END IF;
    IF v_feature_definitions <> 32 THEN RAISE EXCEPTION 'Expected 32 feature definitions; observed %', v_feature_definitions; END IF;
    IF v_industries <> 8 THEN RAISE EXCEPTION 'Expected 8 industry segments; observed %', v_industries; END IF;
    IF v_operational_rows <> 0 THEN RAISE EXCEPTION 'G1 preflight requires empty Module 1 analytical state; observed % rows', v_operational_rows; END IF;
END
$$;

SELECT
    clock_timestamp() AS validation_timestamp,
    current_database() AS database_name,
    current_user AS database_user,
    current_setting('server_version') AS postgresql_version,
    'PASS'::text AS preflight_status,
    'G0 physical foundation reconciles and Module 1 analytical state is empty.'::text AS finding;
