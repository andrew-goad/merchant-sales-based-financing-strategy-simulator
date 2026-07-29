/* ============================================================================
MSBF M1.14 Unit Economics & Risk-Adjusted Contribution
Atomic Recovery, Blocked-Contract Repair & Readiness Preparation
Program : 100E_msbf_m1_14_atomic_contract_repair_and_recovery_v0_2R3.sql
Version : v0.2R3
Purpose : Replace the separate R2 recovery and schema-remediation steps with one
          fail-closed, idempotent preparation program. The program proves the
          current database is still at the accepted M1.13 boundary, identifies
          the installed blocked-evidence contract, upgrades the legacy contract
          when safe, validates the approved V2 contract, and returns one
          filterable preparation result.
Inputs  : Accepted M1.13 database state and the M1.14 schema extension created
          by program 100 v0.2.
Outputs : Schema-contract correction only. No M1.14 business row, governed
          economic formula, policy parameter, accepted upstream row, run status,
          evidence record, or acceptance gate is changed.
Safety  : Unknown constraint definitions, nonempty M1.14 targets, M1.14 evidence,
          M1.14 gate rows, downstream outputs, or blocking errors fail closed.
Required: preparation_status = PASS.
============================================================================ */

BEGIN;
SET LOCAL lock_timeout = '10s';
SET LOCAL statement_timeout = '5min';

DROP TABLE IF EXISTS _m1_14_r3_preparation;
CREATE TEMP TABLE _m1_14_r3_preparation (
    run_id bigint,
    run_status text,
    prior_contract_state text,
    preparation_action text,
    prior_constraint_definition text,
    final_constraint_definition text,
    final_constraint_comment text,
    baseline_blocked_rows bigint,
    stress_blocked_rows bigint,
    matched_blocked_rows bigint,
    baseline_supported_stress_blocked_rows bigint,
    snapshot_rows bigint,
    component_rows bigint,
    m1_14_evidence_rows bigint,
    m1_14_gate_rows bigint,
    downstream_rows bigint,
    blocking_errors bigint,
    constraint_validated boolean,
    baseline_reference_allowed boolean,
    current_blocked_metrics_gated boolean,
    contract_marker_present boolean,
    preparation_status text
) ON COMMIT PRESERVE ROWS;

LOCK TABLE msbf_m1.application_unit_economics_snapshot
    IN ACCESS EXCLUSIVE MODE;

DO $prepare$
DECLARE
    v_run_id bigint;
    v_run_status text;
    v_prior_def text;
    v_final_def text;
    v_final_comment text;
    v_validated boolean;
    v_all_current boolean;
    v_baseline_absent boolean;
    v_baseline_present boolean;
    v_prior_state text;
    v_action text;
    v_snapshot_rows bigint;
    v_component_rows bigint;
    v_evidence_rows bigint;
    v_gate_rows bigint;
    v_downstream_rows bigint;
    v_blocking_errors bigint;
    v_baseline_blocked bigint;
    v_stress_blocked bigint;
    v_matched_blocked bigint;
    v_baseline_supported_stress_blocked bigint;
BEGIN
    IF to_regclass('msbf_m1.application_unit_economics_snapshot') IS NULL THEN
        RAISE EXCEPTION 'M1.14 unit-economics snapshot table does not exist; run the governed schema extension first.';
    END IF;

    SELECT run_id, run_status
    INTO STRICT v_run_id, v_run_status
    FROM msbf_ctl.run_registry
    WHERE run_code='M1_V0_2_BASELINE_BUILD'
      AND run_version=1;

    SELECT count(*) INTO v_snapshot_rows
    FROM msbf_m1.application_unit_economics_snapshot
    WHERE module1_run_id=v_run_id;

    SELECT count(*) INTO v_component_rows
    FROM msbf_m1.unit_economics_component_value
    WHERE module1_run_id=v_run_id;

    SELECT count(*) INTO v_evidence_rows
    FROM msbf_ctl.run_evidence
    WHERE run_id=v_run_id
      AND evidence_code LIKE 'M1_14_%';

    SELECT count(*) INTO v_gate_rows
    FROM msbf_ctl.acceptance_gate_result
    WHERE run_id=v_run_id
      AND gate_id='M1_14_UNIT_ECONOMICS_CONTRIBUTION';

    SELECT
        (SELECT count(*) FROM msbf_m1.module1_latest WHERE module1_run_id=v_run_id)
      + (SELECT count(*) FROM msbf_m1.module1_archive WHERE module1_run_id=v_run_id)
    INTO v_downstream_rows;

    SELECT count(*) INTO v_blocking_errors
    FROM msbf_ctl.profile_resolution_error
    WHERE run_id=v_run_id
      AND severity='BLOCKING';

    WITH paired AS (
        SELECT
            b.loss_evidence_status AS baseline_status,
            s.loss_evidence_status AS stress_status
        FROM msbf_m1.application_exposure_recovery_loss_snapshot b
        JOIN msbf_ctl.scenario_registry bsr
          ON bsr.scenario_id=b.scenario_id
        JOIN msbf_m1.application_exposure_recovery_loss_snapshot s
          ON s.module1_run_id=b.module1_run_id
         AND s.merchant_application_id=b.merchant_application_id
        JOIN msbf_ctl.scenario_registry ssr
          ON ssr.scenario_id=s.scenario_id
        WHERE b.module1_run_id=v_run_id
          AND bsr.scenario_code='BASELINE'
          AND ssr.scenario_code='RECESSION_ENERGY'
    )
    SELECT
        count(*) FILTER (WHERE baseline_status='BLOCKED'),
        count(*) FILTER (WHERE stress_status='BLOCKED'),
        count(*) FILTER (WHERE baseline_status='BLOCKED' AND stress_status='BLOCKED'),
        count(*) FILTER (WHERE baseline_status<>'BLOCKED' AND stress_status='BLOCKED')
    INTO
        v_baseline_blocked,
        v_stress_blocked,
        v_matched_blocked,
        v_baseline_supported_stress_blocked
    FROM paired;

    SELECT pg_get_constraintdef(c.oid), c.convalidated
    INTO STRICT v_prior_def, v_validated
    FROM pg_constraint c
    JOIN pg_class t ON t.oid=c.conrelid
    JOIN pg_namespace n ON n.oid=t.relnamespace
    WHERE n.nspname='msbf_m1'
      AND t.relname='application_unit_economics_snapshot'
      AND c.conname='ck_m1_14_blocked';

    v_all_current :=
       position('(comparative_expected_loss_amount is null)' in lower(v_prior_def))>0
       AND position('(contribution_after_comparative_loss_amount is null)' in lower(v_prior_def))>0
       AND position('(independent_risk_adjusted_contribution_amount is null)' in lower(v_prior_def))>0
       AND position('(risk_adjusted_contribution_amount is null)' in lower(v_prior_def))>0
       AND position('(contribution_after_loss_margin_rate is null)' in lower(v_prior_def))>0
       AND position('(independent_risk_adjusted_contribution_margin_rate is null)' in lower(v_prior_def))>0
       AND position('(risk_adjusted_contribution_margin_rate is null)' in lower(v_prior_def))>0
       AND position('(independent_annualized_risk_adjusted_return_rate is null)' in lower(v_prior_def))>0
       AND position('(annualized_risk_adjusted_return_rate is null)' in lower(v_prior_def))>0
       AND position('(economic_surplus_amount is null)' in lower(v_prior_def))>0;
    v_baseline_absent :=
       position('(baseline_risk_adjusted_contribution_amount is null)' in lower(v_prior_def))=0
       AND position('(baseline_annualized_risk_adjusted_return_rate is null)' in lower(v_prior_def))=0;
    v_baseline_present :=
       position('(baseline_risk_adjusted_contribution_amount is null)' in lower(v_prior_def))>0
       AND position('(baseline_annualized_risk_adjusted_return_rate is null)' in lower(v_prior_def))>0;

    v_prior_state := CASE
        WHEN v_validated AND v_all_current AND v_baseline_absent
            THEN 'APPROVED_V2'
        WHEN v_validated AND v_all_current AND v_baseline_present
            THEN 'LEGACY_V1'
        ELSE 'UNKNOWN'
    END;

    IF v_run_status<>'M1_13_ACCEPTED'
       OR v_snapshot_rows<>0
       OR v_component_rows<>0
       OR v_evidence_rows<>0
       OR v_gate_rows<>0
       OR v_downstream_rows<>0
       OR v_blocking_errors<>0
       OR v_baseline_blocked<>160
       OR v_stress_blocked<>438
       OR v_matched_blocked<>160
       OR v_baseline_supported_stress_blocked<>278
       OR v_prior_state='UNKNOWN' THEN
        RAISE EXCEPTION
            'M1.14 R3 preparation preconditions failed: status %, contract %, snapshots %, components %, evidence %, gate %, downstream %, blocking %, baseline-blocked %, stress-blocked %, matched-blocked %, baseline-supported-stress-blocked %, definition %.',
            v_run_status, v_prior_state, v_snapshot_rows, v_component_rows,
            v_evidence_rows, v_gate_rows, v_downstream_rows, v_blocking_errors,
            v_baseline_blocked, v_stress_blocked, v_matched_blocked,
            v_baseline_supported_stress_blocked, v_prior_def;
    END IF;

    IF v_prior_state='LEGACY_V1' THEN
        EXECUTE 'ALTER TABLE msbf_m1.application_unit_economics_snapshot DROP CONSTRAINT ck_m1_14_blocked';
        EXECUTE $ddl$
            ALTER TABLE msbf_m1.application_unit_economics_snapshot
            ADD CONSTRAINT ck_m1_14_blocked CHECK (
        unit_economics_evidence_status <> 'BLOCKED'
        OR (
            comparative_expected_loss_amount IS NULL
            AND contribution_after_comparative_loss_amount IS NULL
            AND independent_risk_adjusted_contribution_amount IS NULL
            AND risk_adjusted_contribution_amount IS NULL
            AND contribution_after_loss_margin_rate IS NULL
            AND independent_risk_adjusted_contribution_margin_rate IS NULL
            AND risk_adjusted_contribution_margin_rate IS NULL
            AND independent_annualized_risk_adjusted_return_rate IS NULL
            AND annualized_risk_adjusted_return_rate IS NULL
            AND economic_surplus_amount IS NULL
        )
    ) NOT VALID
        $ddl$;
        EXECUTE 'ALTER TABLE msbf_m1.application_unit_economics_snapshot VALIDATE CONSTRAINT ck_m1_14_blocked';
        v_action := 'REMEDIATED_LEGACY_V1_TO_APPROVED_V2';
    ELSE
        v_action := 'NO_CHANGE_ALREADY_APPROVED_V2';
    END IF;

    EXECUTE format(
        'COMMENT ON CONSTRAINT ck_m1_14_blocked ON msbf_m1.application_unit_economics_snapshot IS %L',
        'MSBF_M1_14_BLOCKED_CONTRACT_V2 | Blocked current-scenario loss-dependent economics remain NULL. Matched-baseline contribution and return references may remain populated for comparison, lineage, and adverse-scenario non-improvement controls.'
    );

    SELECT
        pg_get_constraintdef(c.oid),
        c.convalidated,
        obj_description(c.oid,'pg_constraint')
    INTO STRICT v_final_def, v_validated, v_final_comment
    FROM pg_constraint c
    JOIN pg_class t ON t.oid=c.conrelid
    JOIN pg_namespace n ON n.oid=t.relnamespace
    WHERE n.nspname='msbf_m1'
      AND t.relname='application_unit_economics_snapshot'
      AND c.conname='ck_m1_14_blocked';

    v_all_current :=
       position('(comparative_expected_loss_amount is null)' in lower(v_final_def))>0
       AND position('(contribution_after_comparative_loss_amount is null)' in lower(v_final_def))>0
       AND position('(independent_risk_adjusted_contribution_amount is null)' in lower(v_final_def))>0
       AND position('(risk_adjusted_contribution_amount is null)' in lower(v_final_def))>0
       AND position('(contribution_after_loss_margin_rate is null)' in lower(v_final_def))>0
       AND position('(independent_risk_adjusted_contribution_margin_rate is null)' in lower(v_final_def))>0
       AND position('(risk_adjusted_contribution_margin_rate is null)' in lower(v_final_def))>0
       AND position('(independent_annualized_risk_adjusted_return_rate is null)' in lower(v_final_def))>0
       AND position('(annualized_risk_adjusted_return_rate is null)' in lower(v_final_def))>0
       AND position('(economic_surplus_amount is null)' in lower(v_final_def))>0;
    v_baseline_absent :=
       position('(baseline_risk_adjusted_contribution_amount is null)' in lower(v_final_def))=0
       AND position('(baseline_annualized_risk_adjusted_return_rate is null)' in lower(v_final_def))=0;

    IF NOT v_validated
       OR NOT v_all_current
       OR NOT v_baseline_absent
       OR coalesce(v_final_comment,'') NOT LIKE 'MSBF_M1_14_BLOCKED_CONTRACT_V2%' THEN
        RAISE EXCEPTION
            'M1.14 R3 approved blocked contract failed postcondition: validated %, current-gated %, baseline-allowed %, marker %, definition %.',
            v_validated, v_all_current, v_baseline_absent,
            coalesce(v_final_comment,''), v_final_def;
    END IF;

    INSERT INTO _m1_14_r3_preparation (
        run_id, run_status, prior_contract_state, preparation_action,
        prior_constraint_definition, final_constraint_definition,
        final_constraint_comment, baseline_blocked_rows, stress_blocked_rows,
        matched_blocked_rows, baseline_supported_stress_blocked_rows,
        snapshot_rows, component_rows, m1_14_evidence_rows, m1_14_gate_rows,
        downstream_rows, blocking_errors, constraint_validated,
        baseline_reference_allowed, current_blocked_metrics_gated,
        contract_marker_present, preparation_status
    ) VALUES (
        v_run_id, v_run_status, v_prior_state, v_action,
        v_prior_def, v_final_def, v_final_comment,
        v_baseline_blocked, v_stress_blocked, v_matched_blocked,
        v_baseline_supported_stress_blocked, v_snapshot_rows,
        v_component_rows, v_evidence_rows, v_gate_rows, v_downstream_rows,
        v_blocking_errors, v_validated, v_baseline_absent, v_all_current,
        coalesce(v_final_comment,'') LIKE 'MSBF_M1_14_BLOCKED_CONTRACT_V2%', 'PASS'
    );
END;
$prepare$;

COMMIT;

SELECT *
FROM _m1_14_r3_preparation;
