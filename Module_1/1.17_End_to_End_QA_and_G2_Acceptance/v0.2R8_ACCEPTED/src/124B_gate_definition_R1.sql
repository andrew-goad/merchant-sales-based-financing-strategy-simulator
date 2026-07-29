/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
M1.17 — End-to-End QA, Evidence & G2 Contract Acceptance

Program
124B_msbf_m1_17_g2_gate_definition_recovery_v0_2R1.sql

Purpose
Repair the governed G2 acceptance-gate catalog definition required by the
M1.17 hard-stop preflight. Program 125 reported that every other prerequisite
passed but `g2_gate_defined = false`.

Authoritative definition
The original governed G0 reference seed defines:
    gate_id      = G2_M1_CONTRACT
    gate_name    = Module 1 Contract
    module_code  = M1
    severity     = BLOCKING
    active_flag  = true

Scope
- Idempotently inserts or repairs only the G2 reference-catalog row.
- Does not create an acceptance result.
- Does not issue the G2 gate.
- Does not modify the governed run status.
- Does not modify M1.14, M1.15, M1.16, or M1.17 business/evidence rows.
- Does not mutate accepted G1 snapshots or their hashes.

Execution
1. After stopping failed Program 125, execute ROLLBACK.
2. Run this complete script with DBeaver Execute SQL Script.
3. Require remediation_status = PASS.
4. Rerun Program 125.
============================================================================ */

BEGIN;

SET LOCAL lock_timeout = '10s';
SET LOCAL statement_timeout = '5min';
SET LOCAL jit = off;

DROP TABLE IF EXISTS _m1_17_g2_gate_recovery;

CREATE TEMP TABLE _m1_17_g2_gate_recovery
ON COMMIT PRESERVE ROWS
AS
SELECT
    COUNT(*)::bigint AS prior_gate_rows,
    MAX(gate_name) AS prior_gate_name,
    MAX(module_code) AS prior_module_code,
    MAX(severity) AS prior_severity,
    BOOL_OR(active_flag) AS prior_active_flag
FROM msbf_ref.acceptance_gate_catalog
WHERE gate_id = 'G2_M1_CONTRACT';

INSERT INTO msbf_ref.acceptance_gate_catalog
(
    gate_id,
    gate_name,
    module_code,
    severity,
    active_flag,
    description
)
VALUES
(
    'G2_M1_CONTRACT',
    'Module 1 Contract',
    'M1',
    'BLOCKING',
    TRUE,
    'Deterministic leakage-free M1 contract accepted.'
)
ON CONFLICT (gate_id)
DO UPDATE
SET
    gate_name   = EXCLUDED.gate_name,
    module_code = EXCLUDED.module_code,
    severity    = EXCLUDED.severity,
    active_flag = TRUE,
    description = EXCLUDED.description;

ALTER TABLE _m1_17_g2_gate_recovery
    ADD COLUMN final_gate_rows bigint,
    ADD COLUMN final_gate_name text,
    ADD COLUMN final_module_code text,
    ADD COLUMN final_severity text,
    ADD COLUMN final_active_flag boolean,
    ADD COLUMN g2_gate_defined boolean,
    ADD COLUMN remediation_status text;

UPDATE _m1_17_g2_gate_recovery
SET
    final_gate_rows = x.final_gate_rows,
    final_gate_name = x.final_gate_name,
    final_module_code = x.final_module_code,
    final_severity = x.final_severity,
    final_active_flag = x.final_active_flag,
    g2_gate_defined = (
        x.final_gate_rows = 1
        AND x.final_gate_name = 'Module 1 Contract'
        AND x.final_module_code = 'M1'
        AND x.final_severity = 'BLOCKING'
        AND x.final_active_flag IS TRUE
    ),
    remediation_status = CASE
        WHEN x.final_gate_rows = 1
         AND x.final_gate_name = 'Module 1 Contract'
         AND x.final_module_code = 'M1'
         AND x.final_severity = 'BLOCKING'
         AND x.final_active_flag IS TRUE
        THEN 'PASS'
        ELSE 'FAIL'
    END
FROM
(
    SELECT
        COUNT(*)::bigint AS final_gate_rows,
        MAX(gate_name) AS final_gate_name,
        MAX(module_code) AS final_module_code,
        MAX(severity) AS final_severity,
        BOOL_OR(active_flag) AS final_active_flag
    FROM msbf_ref.acceptance_gate_catalog
    WHERE gate_id = 'G2_M1_CONTRACT'
) AS x
WHERE TRUE;

DO $m1_17_g2_gate_guard$
DECLARE
    v_record record;
BEGIN
    SELECT *
    INTO v_record
    FROM _m1_17_g2_gate_recovery;

    IF v_record.remediation_status IS DISTINCT FROM 'PASS'
       OR v_record.g2_gate_defined IS DISTINCT FROM TRUE THEN
        RAISE EXCEPTION
            'M1.17 G2 gate-definition remediation failed: %',
            row_to_json(v_record);
    END IF;
END;
$m1_17_g2_gate_guard$;

COMMIT;

SELECT
    prior_gate_rows,
    prior_gate_name,
    prior_module_code,
    prior_severity,
    prior_active_flag,
    final_gate_rows,
    final_gate_name,
    final_module_code,
    final_severity,
    final_active_flag,
    g2_gate_defined,
    remediation_status
FROM _m1_17_g2_gate_recovery;
