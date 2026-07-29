
/* ============================================================================
 Merchant Sales-Based Financing Strategy Simulator
 M1.17 — End-to-End QA, Evidence & G2 Contract Acceptance
 Program 124 — Schema, Policy, G2 Bundle, Archive, Functions & Views
 Version     — v0.2

 PURPOSE
 -------
 Create the bounded control-plane objects required to certify the complete
 Module 1 foundation after M1.16 acceptance. This program creates no new
 merchant analytics and writes no M1.17 business/QA evidence rows.

 PREREQUISITE
 ------------
 The database must contain the accepted G1–M1.16 project state. Program 125
 performs the hard-stop live prerequisite validation before generation.

 OUTPUTS
 -------
 - Approved M1.17 policy profile
 - G2 bundle registry, latest and immutable archive tables
 - End-to-end hash-chain and evidence-snapshot tables
 - Archive immutability trigger
 - Assertion, hashing, schema-boundary and gate-writing functions
 - Explicitly projected G2 integrated-consumption and lineage views
 - One schema/policy checkpoint row

 STAGE BOUNDARY
 --------------
 No pricing, approval, counteroffer, decline, adverse-action, marketing
 optimization, new risk analytics or other Module 2 output is created.
============================================================================ */

BEGIN;

SET LOCAL lock_timeout = '10s';
SET LOCAL statement_timeout = '15min';
SET LOCAL jit = off;

CREATE TABLE IF NOT EXISTS msbf_ctl.m1_17_policy_profile (
    policy_profile_id                    bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    policy_code                          text NOT NULL UNIQUE,
    methodology_version                  text NOT NULL,
    bundle_code                          text NOT NULL,
    bundle_version                       integer NOT NULL,
    schema_version                       text NOT NULL,
    expected_hash_chain_rows             integer NOT NULL,
    expected_evidence_rows               integer NOT NULL,
    expected_bundle_latest_rows          integer NOT NULL,
    expected_bundle_archive_rows         integer NOT NULL,
    expected_registry_rows               integer NOT NULL,
    expected_integrated_rows             integer NOT NULL,
    expected_canonical_entities          integer NOT NULL,
    expected_positive_controls           integer NOT NULL,
    expected_negative_controls           integer NOT NULL,
    expected_detail_result_sets          integer NOT NULL,
    required_predecessor_gates           integer NOT NULL,
    synthetic_data_only_flag             boolean NOT NULL,
    no_new_business_analytics_flag       boolean NOT NULL,
    no_module2_outputs_flag              boolean NOT NULL,
    package_static_validation_required   boolean NOT NULL,
    policy_status                        text NOT NULL,
    configuration_hash                   text NOT NULL,
    created_at                           timestamptz NOT NULL DEFAULT clock_timestamp(),
    updated_at                           timestamptz NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT ck_m1_17_policy_status CHECK (policy_status IN ('DRAFT','APPROVED','RETIRED')),
    CONSTRAINT ck_m1_17_policy_counts CHECK (
        expected_hash_chain_rows > 0
        AND expected_evidence_rows > 0
        AND expected_bundle_latest_rows = 1
        AND expected_bundle_archive_rows = 1
        AND expected_registry_rows = 1
        AND expected_integrated_rows = 1500
        AND expected_canonical_entities =
            expected_hash_chain_rows + expected_evidence_rows
            + expected_bundle_latest_rows + expected_bundle_archive_rows
            + expected_registry_rows
    )
);

CREATE TABLE IF NOT EXISTS msbf_ctl.m1_17_hash_chain_snapshot (
    module1_run_id        bigint NOT NULL,
    stage_sequence        integer NOT NULL,
    stage_code            text NOT NULL,
    artifact_code         text NOT NULL,
    expected_hash         text NOT NULL,
    observed_hash         text,
    source_locator        text NOT NULL,
    verification_status   text NOT NULL,
    row_hash              text NOT NULL,
    created_at            timestamptz NOT NULL DEFAULT clock_timestamp(),
    PRIMARY KEY (module1_run_id, stage_sequence),
    UNIQUE (module1_run_id, stage_code),
    CONSTRAINT ck_m1_17_hash_status CHECK (verification_status IN ('PASS','FAIL')),
    CONSTRAINT ck_m1_17_hash_shape CHECK (
        expected_hash ~ '^[0-9a-f]{32}$'
        AND (observed_hash IS NULL OR observed_hash ~ '^[0-9a-f]{32}$')
        AND row_hash ~ '^[0-9a-f]{32}$'
    )
);

CREATE TABLE IF NOT EXISTS msbf_ctl.m1_17_end_to_end_evidence_snapshot (
    module1_run_id       bigint NOT NULL,
    evidence_sequence    integer NOT NULL,
    evidence_family      text NOT NULL,
    evidence_code        text NOT NULL,
    metric_name          text NOT NULL,
    observed_value_text  text,
    expected_value_text  text,
    evidence_status      text NOT NULL,
    interpretation       text NOT NULL,
    source_locator       text NOT NULL,
    row_hash             text NOT NULL,
    created_at           timestamptz NOT NULL DEFAULT clock_timestamp(),
    PRIMARY KEY (module1_run_id, evidence_sequence),
    UNIQUE (module1_run_id, evidence_code),
    CONSTRAINT ck_m1_17_evidence_status CHECK (evidence_status IN ('PASS','FAIL')),
    CONSTRAINT ck_m1_17_evidence_hash CHECK (row_hash ~ '^[0-9a-f]{32}$')
);

CREATE TABLE IF NOT EXISTS msbf_ctl.m1_17_g2_bundle_registry (
    g2_bundle_registry_id              bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    module1_run_id                     bigint NOT NULL UNIQUE,
    bundle_code                        text NOT NULL,
    bundle_version                     integer NOT NULL,
    schema_version                     text NOT NULL,
    methodology_version                text NOT NULL,
    source_m1_15_contract_code         text NOT NULL,
    source_m1_15_contract_version      integer NOT NULL,
    source_m1_15_schema_version        text NOT NULL,
    source_m1_15_combined_hash         text NOT NULL,
    source_m1_16_contract_code         text NOT NULL,
    source_m1_16_contract_version      integer NOT NULL,
    source_m1_16_schema_version        text NOT NULL,
    source_m1_16_combined_hash         text NOT NULL,
    accepted_scenario_set_hash         text NOT NULL,
    policy_configuration_hash          text NOT NULL,
    predecessor_gate_count             integer NOT NULL,
    integrated_consumption_rows        bigint NOT NULL,
    hash_chain_rows                    bigint NOT NULL,
    evidence_snapshot_rows             bigint NOT NULL,
    canonical_entities                 bigint NOT NULL,
    hash_chain_set_hash                text,
    evidence_set_hash                  text,
    bundle_latest_set_hash             text,
    bundle_archive_set_hash            text,
    contract_set_hash                  text,
    combined_g2_hash                   text,
    bundle_status                      text NOT NULL,
    generated_at                       timestamptz,
    validated_at                       timestamptz,
    accepted_at                        timestamptz,
    row_hash                           text NOT NULL,
    created_at                         timestamptz NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT uq_m1_17_bundle_identity UNIQUE (bundle_code, bundle_version),
    CONSTRAINT ck_m1_17_bundle_status CHECK (
        bundle_status IN ('GENERATED','VALIDATED','ACCEPTED')
    ),
    CONSTRAINT ck_m1_17_bundle_hashes CHECK (
        source_m1_15_combined_hash ~ '^[0-9a-f]{32}$'
        AND source_m1_16_combined_hash ~ '^[0-9a-f]{32}$'
        AND accepted_scenario_set_hash ~ '^[0-9a-f]{32}$'
        AND policy_configuration_hash ~ '^[0-9a-f]{32}$'
        AND row_hash ~ '^[0-9a-f]{32}$'
    )
);

CREATE TABLE IF NOT EXISTS msbf_ctl.m1_17_g2_bundle_latest (
    module1_run_id                  bigint NOT NULL PRIMARY KEY,
    bundle_code                    text NOT NULL,
    bundle_version                 integer NOT NULL,
    schema_version                 text NOT NULL,
    methodology_version            text NOT NULL,
    source_contract_count          integer NOT NULL,
    integrated_consumption_rows    bigint NOT NULL,
    hash_chain_rows                bigint NOT NULL,
    evidence_snapshot_rows         bigint NOT NULL,
    hash_chain_set_hash            text NOT NULL,
    evidence_set_hash              text NOT NULL,
    bundle_payload                 jsonb NOT NULL,
    contract_row_hash              text NOT NULL,
    created_at                     timestamptz NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT uq_m1_17_latest_identity UNIQUE (bundle_code, bundle_version),
    CONSTRAINT ck_m1_17_latest_counts CHECK (
        source_contract_count = 2
        AND integrated_consumption_rows = 1500
        AND hash_chain_rows = 18
        AND evidence_snapshot_rows = 48
    )
);

CREATE TABLE IF NOT EXISTS msbf_ctl.m1_17_g2_bundle_archive (
    g2_bundle_archive_id            bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    module1_run_id                  bigint NOT NULL,
    bundle_code                    text NOT NULL,
    bundle_version                 integer NOT NULL,
    schema_version                 text NOT NULL,
    methodology_version            text NOT NULL,
    source_contract_count          integer NOT NULL,
    integrated_consumption_rows    bigint NOT NULL,
    hash_chain_rows                bigint NOT NULL,
    evidence_snapshot_rows         bigint NOT NULL,
    hash_chain_set_hash            text NOT NULL,
    evidence_set_hash              text NOT NULL,
    bundle_payload                 jsonb NOT NULL,
    source_latest_row_hash         text NOT NULL,
    archive_row_hash               text NOT NULL,
    archived_at                    timestamptz NOT NULL DEFAULT clock_timestamp(),
    created_at                     timestamptz NOT NULL DEFAULT clock_timestamp(),
    UNIQUE (module1_run_id, bundle_code, bundle_version),
    CONSTRAINT ck_m1_17_archive_counts CHECK (
        source_contract_count = 2
        AND integrated_consumption_rows = 1500
        AND hash_chain_rows = 18
        AND evidence_snapshot_rows = 48
    )
);

CREATE INDEX IF NOT EXISTS ix_m1_17_hash_stage
    ON msbf_ctl.m1_17_hash_chain_snapshot(module1_run_id, stage_code);
CREATE INDEX IF NOT EXISTS ix_m1_17_evidence_family
    ON msbf_ctl.m1_17_end_to_end_evidence_snapshot(module1_run_id, evidence_family);
CREATE INDEX IF NOT EXISTS ix_m1_17_registry_status
    ON msbf_ctl.m1_17_g2_bundle_registry(module1_run_id, bundle_status);
CREATE INDEX IF NOT EXISTS ix_m1_17_archive_run
    ON msbf_ctl.m1_17_g2_bundle_archive(module1_run_id, bundle_version);

CREATE OR REPLACE FUNCTION msbf_ctl.m1_17_hash_jsonb(p_value jsonb)
RETURNS text
LANGUAGE sql
IMMUTABLE
STRICT
AS $$
    SELECT md5(p_value::text);
$$;

CREATE OR REPLACE FUNCTION msbf_ctl.m1_17_hash_present(
    p_run_id bigint,
    p_expected_hash text
)
RETURNS boolean
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    v_found boolean := false;
    v_relation text;
BEGIN
    IF p_expected_hash IS NULL THEN
        RETURN false;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM msbf_ctl.run_evidence
        WHERE run_id = p_run_id
          AND metric_value_text = p_expected_hash
    ) THEN
        RETURN true;
    END IF;

    FOREACH v_relation IN ARRAY ARRAY[
        'msbf_ctl.run_registry',
        'msbf_m1.population_registry',
        'msbf_ctl.m1_15_consumption_contract_registry',
        'msbf_ctl.m1_16_acquisition_contract_registry'
    ]
    LOOP
        IF to_regclass(v_relation) IS NOT NULL THEN
            EXECUTE format(
                'SELECT EXISTS (
                    SELECT 1 FROM %s t
                    WHERE to_jsonb(t)::text LIKE ''%%'' || $1 || ''%%''
                )',
                v_relation
            )
            INTO v_found
            USING p_expected_hash;

            IF v_found THEN
                RETURN true;
            END IF;
        END IF;
    END LOOP;

    RETURN false;
END;
$$;

CREATE OR REPLACE FUNCTION msbf_ctl.m1_17_schema_row_count(p_schema text)
RETURNS bigint
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    v_table record;
    v_count bigint;
    v_total bigint := 0;
BEGIN
    FOR v_table IN
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = p_schema
          AND table_type = 'BASE TABLE'
        ORDER BY table_name
    LOOP
        EXECUTE format('SELECT count(*) FROM %I.%I', p_schema, v_table.table_name)
        INTO v_count;
        v_total := v_total + coalesce(v_count, 0);
    END LOOP;
    RETURN v_total;
END;
$$;

CREATE OR REPLACE FUNCTION msbf_ctl.m1_17_assert_configuration()
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    v record;
BEGIN
    SELECT * INTO v
    FROM msbf_ctl.m1_17_policy_profile
    WHERE policy_code = 'M1_17_G2_ASSURANCE_V1';

    IF NOT FOUND
       OR v.policy_status <> 'APPROVED'
       OR v.methodology_version <> 'M1_17_METHOD_V1'
       OR v.bundle_code <> 'M1_G2_CONSUMPTION_BUNDLE'
       OR v.bundle_version <> 1
       OR v.schema_version <> 'M1_G2_BUNDLE_SCHEMA_V1'
       OR v.expected_hash_chain_rows <> 18
       OR v.expected_evidence_rows <> 48
       OR v.expected_bundle_latest_rows <> 1
       OR v.expected_bundle_archive_rows <> 1
       OR v.expected_registry_rows <> 1
       OR v.expected_integrated_rows <> 1500
       OR v.expected_canonical_entities <> 69
       OR v.expected_positive_controls <> 128
       OR v.expected_negative_controls <> 20
       OR v.expected_detail_result_sets <> 24
       OR v.required_predecessor_gates <> 16
       OR NOT v.synthetic_data_only_flag
       OR NOT v.no_new_business_analytics_flag
       OR NOT v.no_module2_outputs_flag
       OR NOT v.package_static_validation_required
       OR v.configuration_hash !~ '^[0-9a-f]{32}$' THEN
        RAISE EXCEPTION 'M1.17 approved policy/configuration is missing or invalid.';
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION msbf_ctl.m1_17_assert_prerequisite_status(p_run_id bigint)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    v_run_status text;
    v_m15_status text;
    v_m16_status text;
BEGIN
    SELECT run_status INTO v_run_status
    FROM msbf_ctl.run_registry
    WHERE run_id = p_run_id;

    SELECT to_jsonb(t)->>'contract_status'
    INTO v_m15_status
    FROM msbf_ctl.m1_15_consumption_contract_registry t
    WHERE (to_jsonb(t)->>'module1_run_id')::bigint = p_run_id
    LIMIT 1;

    SELECT to_jsonb(t)->>'contract_status'
    INTO v_m16_status
    FROM msbf_ctl.m1_16_acquisition_contract_registry t
    WHERE (to_jsonb(t)->>'module1_run_id')::bigint = p_run_id
    LIMIT 1;

    IF v_run_status <> 'M1_16_ACCEPTED'
       OR v_m15_status <> 'ACCEPTED'
       OR v_m16_status <> 'ACCEPTED' THEN
        RAISE EXCEPTION
            'M1.17 requires M1_16_ACCEPTED and both source contracts ACCEPTED; observed run %, M1.15 %, M1.16 %.',
            v_run_status, v_m15_status, v_m16_status;
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION msbf_ctl.m1_17_assert_pristine(p_run_id bigint)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    v_target_rows bigint;
    v_evidence_rows bigint;
    v_gate_rows bigint;
BEGIN
    SELECT
          (SELECT count(*) FROM msbf_ctl.m1_17_hash_chain_snapshot
            WHERE module1_run_id = p_run_id)
        + (SELECT count(*) FROM msbf_ctl.m1_17_end_to_end_evidence_snapshot
            WHERE module1_run_id = p_run_id)
        + (SELECT count(*) FROM msbf_ctl.m1_17_g2_bundle_registry
            WHERE module1_run_id = p_run_id)
        + (SELECT count(*) FROM msbf_ctl.m1_17_g2_bundle_latest
            WHERE module1_run_id = p_run_id)
        + (SELECT count(*) FROM msbf_ctl.m1_17_g2_bundle_archive
            WHERE module1_run_id = p_run_id)
    INTO v_target_rows;

    SELECT count(*) INTO v_evidence_rows
    FROM msbf_ctl.run_evidence
    WHERE run_id = p_run_id
      AND evidence_code LIKE 'M1_17_%';

    SELECT count(*) INTO v_gate_rows
    FROM msbf_ctl.acceptance_gate_result
    WHERE run_id = p_run_id
      AND gate_id = 'G2_M1_CONTRACT';

    IF v_target_rows <> 0 OR v_evidence_rows <> 0 OR v_gate_rows <> 0 THEN
        RAISE EXCEPTION
            'M1.17 targets are not pristine: target %, evidence %, G2 gate %.',
            v_target_rows, v_evidence_rows, v_gate_rows;
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION msbf_ctl.m1_17_assert_generation_ready(p_run_id bigint)
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
    PERFORM msbf_ctl.m1_17_assert_configuration();
    PERFORM msbf_ctl.m1_17_assert_prerequisite_status(p_run_id);
    PERFORM msbf_ctl.m1_17_assert_pristine(p_run_id);
END;
$$;

CREATE OR REPLACE FUNCTION msbf_ctl.m1_17_archive_immutable_guard()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION
        'M1.17 G2 bundle archive is immutable; % is prohibited.',
        TG_OP;
END;
$$;

DROP TRIGGER IF EXISTS trg_m1_17_g2_archive_immutable
    ON msbf_ctl.m1_17_g2_bundle_archive;
CREATE TRIGGER trg_m1_17_g2_archive_immutable
BEFORE UPDATE OR DELETE ON msbf_ctl.m1_17_g2_bundle_archive
FOR EACH ROW
EXECUTE FUNCTION msbf_ctl.m1_17_archive_immutable_guard();

CREATE OR REPLACE FUNCTION msbf_ctl.m1_17_write_acceptance_gate(
    p_run_id bigint,
    p_result_status text,
    p_summary text
)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    v_cols text[] := ARRAY['run_id','gate_id'];
    v_expr text[] := ARRAY['$1','$2'];
    v_review integer;
    v_status_col text;
    v_sql text;
BEGIN
    SELECT coalesce(max(
        CASE
            WHEN (to_jsonb(g)->>'review_version') ~ '^[0-9]+$'
            THEN (to_jsonb(g)->>'review_version')::integer
            ELSE 0
        END
    ), 0) + 1
    INTO v_review
    FROM msbf_ctl.acceptance_gate_result g
    WHERE run_id = p_run_id
      AND gate_id = 'G2_M1_CONTRACT';

    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='msbf_ctl'
          AND table_name='acceptance_gate_result'
          AND column_name='review_version'
    ) THEN
        v_cols := array_append(v_cols, 'review_version');
        v_expr := array_append(v_expr, '$3');
    END IF;

    SELECT column_name INTO v_status_col
    FROM information_schema.columns
    WHERE table_schema='msbf_ctl'
      AND table_name='acceptance_gate_result'
      AND column_name IN ('result_status','gate_status','status')
    ORDER BY CASE column_name
        WHEN 'result_status' THEN 1
        WHEN 'gate_status' THEN 2
        ELSE 3 END
    LIMIT 1;

    IF v_status_col IS NULL THEN
        RAISE EXCEPTION 'Acceptance-gate result status column cannot be resolved.';
    END IF;

    v_cols := array_append(v_cols, v_status_col);
    v_expr := array_append(v_expr, '$4');

    IF EXISTS (SELECT 1 FROM information_schema.columns
               WHERE table_schema='msbf_ctl'
                 AND table_name='acceptance_gate_result'
                 AND column_name='reviewed_by') THEN
        v_cols := array_append(v_cols, 'reviewed_by');
        v_expr := array_append(v_expr, quote_literal('M1_17_AUTOMATED_G2'));
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.columns
               WHERE table_schema='msbf_ctl'
                 AND table_name='acceptance_gate_result'
                 AND column_name='reviewed_at') THEN
        v_cols := array_append(v_cols, 'reviewed_at');
        v_expr := array_append(v_expr, 'clock_timestamp()');
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.columns
               WHERE table_schema='msbf_ctl'
                 AND table_name='acceptance_gate_result'
                 AND column_name='result_summary') THEN
        v_cols := array_append(v_cols, 'result_summary');
        v_expr := array_append(v_expr, '$5');
    ELSIF EXISTS (SELECT 1 FROM information_schema.columns
                  WHERE table_schema='msbf_ctl'
                    AND table_name='acceptance_gate_result'
                    AND column_name='notes') THEN
        v_cols := array_append(v_cols, 'notes');
        v_expr := array_append(v_expr, '$5');
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.columns
               WHERE table_schema='msbf_ctl'
                 AND table_name='acceptance_gate_result'
                 AND column_name='evidence_reference') THEN
        v_cols := array_append(v_cols, 'evidence_reference');
        v_expr := array_append(v_expr, quote_literal('M1_17_G2_EVIDENCE'));
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.columns
               WHERE table_schema='msbf_ctl'
                 AND table_name='acceptance_gate_result'
                 AND column_name='module_code') THEN
        v_cols := array_append(v_cols, 'module_code');
        v_expr := array_append(v_expr, quote_literal('M1_17'));
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.columns
               WHERE table_schema='msbf_ctl'
                 AND table_name='acceptance_gate_result'
                 AND column_name='created_at') THEN
        v_cols := array_append(v_cols, 'created_at');
        v_expr := array_append(v_expr, 'clock_timestamp()');
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.columns
               WHERE table_schema='msbf_ctl'
                 AND table_name='acceptance_gate_result'
                 AND column_name='updated_at') THEN
        v_cols := array_append(v_cols, 'updated_at');
        v_expr := array_append(v_expr, 'clock_timestamp()');
    END IF;

    v_sql := format(
        'INSERT INTO msbf_ctl.acceptance_gate_result (%s) VALUES (%s)',
        array_to_string(ARRAY(SELECT format('%I', x) FROM unnest(v_cols) x), ','),
        array_to_string(v_expr, ',')
    );

    EXECUTE v_sql
    USING p_run_id, 'G2_M1_CONTRACT', v_review, p_result_status, p_summary;
END;
$$;

INSERT INTO msbf_ctl.m1_17_policy_profile (
    policy_code,
    methodology_version,
    bundle_code,
    bundle_version,
    schema_version,
    expected_hash_chain_rows,
    expected_evidence_rows,
    expected_bundle_latest_rows,
    expected_bundle_archive_rows,
    expected_registry_rows,
    expected_integrated_rows,
    expected_canonical_entities,
    expected_positive_controls,
    expected_negative_controls,
    expected_detail_result_sets,
    required_predecessor_gates,
    synthetic_data_only_flag,
    no_new_business_analytics_flag,
    no_module2_outputs_flag,
    package_static_validation_required,
    policy_status,
    configuration_hash,
    updated_at
)
SELECT
    'M1_17_G2_ASSURANCE_V1',
    'M1_17_METHOD_V1',
    'M1_G2_CONSUMPTION_BUNDLE',
    1,
    'M1_G2_BUNDLE_SCHEMA_V1',
    18,
    48,
    1,
    1,
    1,
    1500,
    69,
    128,
    20,
    24,
    16,
    true,
    true,
    true,
    true,
    'APPROVED',
    msbf_ctl.m1_17_hash_jsonb(
        jsonb_build_object(
            'policy_code','M1_17_G2_ASSURANCE_V1',
            'methodology_version','M1_17_METHOD_V1',
            'bundle_code','M1_G2_CONSUMPTION_BUNDLE',
            'bundle_version',1,
            'schema_version','M1_G2_BUNDLE_SCHEMA_V1',
            'hash_chain_rows',18,
            'evidence_rows',48,
            'canonical_entities',69,
            'integrated_rows',1500,
            'positive_controls',128,
            'negative_controls',20,
            'detail_result_sets',24,
            'predecessor_gates',16,
            'synthetic_only',true,
            'no_new_business_analytics',true,
            'no_module2_outputs',true,
            'package_static_validation_required',true
        )
    ),
    clock_timestamp()
ON CONFLICT (policy_code) DO UPDATE SET
    methodology_version = EXCLUDED.methodology_version,
    bundle_code = EXCLUDED.bundle_code,
    bundle_version = EXCLUDED.bundle_version,
    schema_version = EXCLUDED.schema_version,
    expected_hash_chain_rows = EXCLUDED.expected_hash_chain_rows,
    expected_evidence_rows = EXCLUDED.expected_evidence_rows,
    expected_bundle_latest_rows = EXCLUDED.expected_bundle_latest_rows,
    expected_bundle_archive_rows = EXCLUDED.expected_bundle_archive_rows,
    expected_registry_rows = EXCLUDED.expected_registry_rows,
    expected_integrated_rows = EXCLUDED.expected_integrated_rows,
    expected_canonical_entities = EXCLUDED.expected_canonical_entities,
    expected_positive_controls = EXCLUDED.expected_positive_controls,
    expected_negative_controls = EXCLUDED.expected_negative_controls,
    expected_detail_result_sets = EXCLUDED.expected_detail_result_sets,
    required_predecessor_gates = EXCLUDED.required_predecessor_gates,
    synthetic_data_only_flag = EXCLUDED.synthetic_data_only_flag,
    no_new_business_analytics_flag = EXCLUDED.no_new_business_analytics_flag,
    no_module2_outputs_flag = EXCLUDED.no_module2_outputs_flag,
    package_static_validation_required = EXCLUDED.package_static_validation_required,
    policy_status = EXCLUDED.policy_status,
    configuration_hash = EXCLUDED.configuration_hash,
    updated_at = clock_timestamp();

DO $views$
DECLARE
    v_cols text;
    v_pb_cols text;
BEGIN
    SELECT string_agg(format('v.%I', column_name), ', ' ORDER BY ordinal_position)
    INTO v_cols
    FROM information_schema.columns
    WHERE table_schema='msbf_m1'
      AND table_name='v_m1_16_module1_integrated_consumption';

    IF v_cols IS NULL THEN
        RAISE EXCEPTION
            'Required accepted view msbf_m1.v_m1_16_module1_integrated_consumption is missing.';
    END IF;

    EXECUTE format(
        'CREATE OR REPLACE VIEW msbf_m1.v_m1_17_g2_integrated_consumption AS
         SELECT %s
         FROM msbf_m1.v_m1_16_module1_integrated_consumption v',
        v_cols
    );

    v_pb_cols := v_cols ||
        ', r.bundle_code AS g2_bundle_code' ||
        ', r.bundle_version AS g2_bundle_version' ||
        ', r.schema_version AS g2_schema_version' ||
        ', r.bundle_status AS g2_bundle_status' ||
        ', r.combined_g2_hash AS g2_combined_hash';

    EXECUTE format(
        'CREATE OR REPLACE VIEW msbf_m1.v_m1_17_power_bi_g2_contract AS
         SELECT %s
         FROM msbf_m1.v_m1_16_module1_integrated_consumption v
         JOIN msbf_ctl.m1_17_g2_bundle_registry r
           ON r.module1_run_id =
              (to_jsonb(v)->>''module1_run_id'')::bigint',
        v_pb_cols
    );
END;
$views$;

CREATE OR REPLACE VIEW msbf_ctl.v_m1_17_g2_lineage AS
SELECT
    r.module1_run_id,
    r.bundle_code,
    r.bundle_version,
    r.schema_version,
    r.methodology_version,
    r.source_m1_15_contract_code,
    r.source_m1_15_contract_version,
    r.source_m1_15_schema_version,
    r.source_m1_15_combined_hash,
    r.source_m1_16_contract_code,
    r.source_m1_16_contract_version,
    r.source_m1_16_schema_version,
    r.source_m1_16_combined_hash,
    r.accepted_scenario_set_hash,
    r.policy_configuration_hash,
    r.predecessor_gate_count,
    r.integrated_consumption_rows,
    r.hash_chain_rows,
    r.evidence_snapshot_rows,
    r.canonical_entities,
    r.hash_chain_set_hash,
    r.evidence_set_hash,
    r.bundle_latest_set_hash,
    r.bundle_archive_set_hash,
    r.contract_set_hash,
    r.combined_g2_hash,
    r.bundle_status,
    r.generated_at,
    r.validated_at,
    r.accepted_at,
    r.row_hash
FROM msbf_ctl.m1_17_g2_bundle_registry r;

CREATE OR REPLACE VIEW msbf_ctl.v_m1_17_hash_chain AS
SELECT
    module1_run_id,
    stage_sequence,
    stage_code,
    artifact_code,
    expected_hash,
    observed_hash,
    source_locator,
    verification_status,
    row_hash
FROM msbf_ctl.m1_17_hash_chain_snapshot;

ANALYZE msbf_ctl.m1_17_policy_profile;

COMMIT;

SELECT
    p.policy_code,
    p.methodology_version,
    p.bundle_code,
    p.bundle_version,
    p.schema_version,
    p.expected_hash_chain_rows,
    p.expected_evidence_rows,
    p.expected_canonical_entities,
    p.expected_positive_controls,
    p.expected_negative_controls,
    p.configuration_hash,
    p.policy_status,
    to_regclass('msbf_ctl.m1_17_g2_bundle_registry') IS NOT NULL
        AS registry_exists,
    to_regclass('msbf_ctl.m1_17_g2_bundle_latest') IS NOT NULL
        AS latest_exists,
    to_regclass('msbf_ctl.m1_17_g2_bundle_archive') IS NOT NULL
        AS archive_exists,
    to_regclass('msbf_m1.v_m1_17_g2_integrated_consumption') IS NOT NULL
        AS integrated_view_exists,
    CASE
        WHEN p.policy_status='APPROVED'
         AND p.configuration_hash ~ '^[0-9a-f]{32}$'
         AND to_regclass('msbf_ctl.m1_17_g2_bundle_registry') IS NOT NULL
         AND to_regclass('msbf_ctl.m1_17_g2_bundle_latest') IS NOT NULL
         AND to_regclass('msbf_ctl.m1_17_g2_bundle_archive') IS NOT NULL
         AND to_regclass('msbf_m1.v_m1_17_g2_integrated_consumption') IS NOT NULL
        THEN 'PASS'
        ELSE 'FAIL'
    END AS schema_policy_extension_status
FROM msbf_ctl.m1_17_policy_profile p
WHERE p.policy_code='M1_17_G2_ASSURANCE_V1';
