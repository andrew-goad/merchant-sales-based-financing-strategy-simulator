/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.10 — Portfolio Performance, KPI & Servicing Analytics

Program     : 208B_msbf_m2_10_kpi_applicability_constraint_repair_v0_2R2.sql
Version     : v0.2R2

Purpose
-------
Atomically replace the legacy KPI-applicability CHECK constraint with an
explicit, NULL-safe contract. The repair rejects inconsistent combinations
such as applicable_flag=false with a numeric KPI value, while preserving all
validated M2.10 rows, hashes, canonical identities, evidence, and lifecycle
status.

Stage boundary
--------------
This is a schema-control repair only. It performs no portfolio regeneration,
KPI recalculation, row mutation, canonical rehash, evidence rewrite, or
acceptance action.

Required result
---------------
repair_status = PASS; 72 existing KPI rows; zero strict violations; registry
and physical canonical identities unchanged.
============================================================================ */

BEGIN;

SET LOCAL lock_timeout='10s';
SET LOCAL statement_timeout='25min';
SET LOCAL jit=off;

DROP TABLE IF EXISTS _m2_10_208b_result;
CREATE TEMP TABLE _m2_10_208b_result
(
    run_status text,
    contract_status text,
    before_constraint_definition text,
    after_constraint_definition text,
    kpi_rows bigint,
    before_strict_violations bigint,
    after_strict_violations bigint,
    before_registry_combined_set_hash text,
    after_registry_combined_set_hash text,
    before_physical_combined_set_hash text,
    after_physical_combined_set_hash text,
    before_canonical_entities bigint,
    after_canonical_entities bigint,
    positive_evidence_rows bigint,
    negative_evidence_rows bigint,
    generation_evidence_rows bigint,
    acceptance_evidence_rows bigint,
    acceptance_gate_rows bigint,
    repair_status text
)
ON COMMIT PRESERVE ROWS;

DO $m2_10_208b_repair$
DECLARE
    v_run_id bigint;
    v_run_status text;
    v_contract_status text;
    v_before_constraint text;
    v_after_constraint text;
    v_constraint_validated boolean;
    v_kpi_rows bigint;
    v_before_violations bigint;
    v_after_violations bigint;
    v_before_registry_hash text;
    v_after_registry_hash text;
    v_before_physical_hash text;
    v_after_physical_hash text;
    v_before_registry_canonical bigint;
    v_after_registry_canonical bigint;
    v_before_physical_canonical bigint;
    v_after_physical_canonical bigint;
    v_positive bigint;
    v_negative bigint;
    v_generation bigint;
    v_acceptance_evidence bigint;
    v_gate bigint;
BEGIN
    SELECT run_id,run_status
    INTO v_run_id,v_run_status
    FROM msbf_ctl.run_registry
    WHERE run_code='M1_V0_2_BASELINE_BUILD'
      AND run_version=1;

    SELECT contract_status,combined_set_hash,canonical_entities
    INTO v_contract_status,v_before_registry_hash,v_before_registry_canonical
    FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry
    WHERE module1_run_id=v_run_id;

    SELECT combined_set_hash,canonical_entities
    INTO v_before_physical_hash,v_before_physical_canonical
    FROM msbf_m2.v_m2_10_canonical_hash
    WHERE module1_run_id=v_run_id;

    SELECT pg_get_constraintdef(constraint_record.oid)
    INTO v_before_constraint
    FROM pg_constraint AS constraint_record
    WHERE constraint_record.conrelid=
          'msbf_m2.portfolio_kpi_snapshot'::regclass
      AND constraint_record.conname='ck_m2_10_kpi_applicability';

    SELECT
        count(*),
        count(*) FILTER
        (
            WHERE NOT
            (
                (
                    applicable_flag IS TRUE
                    AND kpi_value_numeric IS NOT NULL
                    AND kpi_value_text IS NULL
                )
                OR
                (
                    applicable_flag IS FALSE
                    AND kpi_value_numeric IS NULL
                    AND kpi_value_text IS NOT NULL
                    AND kpi_value_text='NOT_APPLICABLE'
                )
            )
        )
    INTO v_kpi_rows,v_before_violations
    FROM msbf_m2.portfolio_kpi_snapshot
    WHERE module1_run_id=v_run_id;

    SELECT
        count(*) FILTER
        (
            WHERE evidence_code LIKE 'M2_10_POS_%'
              AND status='PASS'
        ),
        count(*) FILTER
        (
            WHERE evidence_code LIKE 'M2_10_NEG_%'
        ),
        count(*) FILTER
        (
            WHERE evidence_code LIKE 'M2_10_%'
              AND evidence_code NOT LIKE 'M2_10_POS_%'
              AND evidence_code NOT LIKE 'M2_10_NEG_%'
              AND evidence_code<>'M2_10_ACCEPTANCE_SUMMARY'
        ),
        count(*) FILTER
        (
            WHERE evidence_code='M2_10_ACCEPTANCE_SUMMARY'
        )
    INTO v_positive,v_negative,v_generation,v_acceptance_evidence
    FROM msbf_ctl.run_evidence
    WHERE run_id=v_run_id;

    SELECT count(*)
    INTO v_gate
    FROM msbf_ctl.acceptance_gate_result
    WHERE run_id=v_run_id
      AND gate_id='M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS';

    IF v_run_status<>'M2_10_VALIDATED'
       OR v_contract_status<>'VALIDATED'
       OR v_kpi_rows<>72
       OR v_before_violations<>0
       OR v_before_registry_hash IS DISTINCT FROM v_before_physical_hash
       OR v_before_registry_canonical<>370
       OR v_before_physical_canonical<>370
       OR v_positive<>120
       OR v_negative<>0
       OR v_generation<>24
       OR v_acceptance_evidence<>0
       OR v_gate<>0
       OR v_before_constraint IS NULL
    THEN
        RAISE EXCEPTION
            'M2.10 KPI applicability repair preconditions failed: run %, contract %, KPI rows %, violations %, positive %, negative %, generation %, acceptance evidence %, gate %, registry hash %, physical hash %.',
            v_run_status,v_contract_status,v_kpi_rows,
            v_before_violations,v_positive,v_negative,v_generation,
            v_acceptance_evidence,v_gate,
            v_before_registry_hash,v_before_physical_hash;
    END IF;

    ALTER TABLE msbf_m2.portfolio_kpi_snapshot
        DROP CONSTRAINT ck_m2_10_kpi_applicability;

    ALTER TABLE msbf_m2.portfolio_kpi_snapshot
        ADD CONSTRAINT ck_m2_10_kpi_applicability
        CHECK
        (
            (
                applicable_flag IS TRUE
                AND kpi_value_numeric IS NOT NULL
                AND kpi_value_text IS NULL
            )
            OR
            (
                applicable_flag IS FALSE
                AND kpi_value_numeric IS NULL
                AND kpi_value_text IS NOT NULL
                AND kpi_value_text='NOT_APPLICABLE'
            )
        )
        NOT VALID;

    ALTER TABLE msbf_m2.portfolio_kpi_snapshot
        VALIDATE CONSTRAINT ck_m2_10_kpi_applicability;

    SELECT
        pg_get_constraintdef(constraint_record.oid),
        constraint_record.convalidated
    INTO v_after_constraint,v_constraint_validated
    FROM pg_constraint AS constraint_record
    WHERE constraint_record.conrelid=
          'msbf_m2.portfolio_kpi_snapshot'::regclass
      AND constraint_record.conname='ck_m2_10_kpi_applicability';

    SELECT count(*) FILTER
    (
        WHERE NOT
        (
            (
                applicable_flag IS TRUE
                AND kpi_value_numeric IS NOT NULL
                AND kpi_value_text IS NULL
            )
            OR
            (
                applicable_flag IS FALSE
                AND kpi_value_numeric IS NULL
                AND kpi_value_text IS NOT NULL
                AND kpi_value_text='NOT_APPLICABLE'
            )
        )
    )
    INTO v_after_violations
    FROM msbf_m2.portfolio_kpi_snapshot
    WHERE module1_run_id=v_run_id;

    SELECT combined_set_hash,canonical_entities
    INTO v_after_registry_hash,v_after_registry_canonical
    FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry
    WHERE module1_run_id=v_run_id;

    SELECT combined_set_hash,canonical_entities
    INTO v_after_physical_hash,v_after_physical_canonical
    FROM msbf_m2.v_m2_10_canonical_hash
    WHERE module1_run_id=v_run_id;

    IF NOT v_constraint_validated
       OR position('kpi_value_numeric IS NULL' IN v_after_constraint)=0
       OR position('kpi_value_text IS NULL' IN v_after_constraint)=0
       OR position('kpi_value_text IS NOT NULL' IN v_after_constraint)=0
       OR v_after_violations<>0
       OR v_after_registry_hash IS DISTINCT FROM v_before_registry_hash
       OR v_after_physical_hash IS DISTINCT FROM v_before_physical_hash
       OR v_after_registry_hash IS DISTINCT FROM v_after_physical_hash
       OR v_after_registry_canonical<>370
       OR v_after_physical_canonical<>370
    THEN
        RAISE EXCEPTION
            'M2.10 KPI applicability repair verification failed: validated %, violations %, before registry %, after registry %, before physical %, after physical %, canonical %.',
            v_constraint_validated,v_after_violations,
            v_before_registry_hash,v_after_registry_hash,
            v_before_physical_hash,v_after_physical_hash,
            v_after_registry_canonical;
    END IF;

    INSERT INTO _m2_10_208b_result
    VALUES
    (
        v_run_status,v_contract_status,
        v_before_constraint,v_after_constraint,
        v_kpi_rows,v_before_violations,v_after_violations,
        v_before_registry_hash,v_after_registry_hash,
        v_before_physical_hash,v_after_physical_hash,
        v_before_registry_canonical,v_after_registry_canonical,
        v_positive,v_negative,v_generation,
        v_acceptance_evidence,v_gate,'PASS'
    );
END;
$m2_10_208b_repair$;

COMMIT;

SELECT *
FROM _m2_10_208b_result;
