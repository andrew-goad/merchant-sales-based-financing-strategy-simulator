/* ============================================================================
MSBF M1.14 Unit Economics & Risk-Adjusted Contribution
Failed Snapshot Row-Hash Validation Recovery & Governed Reset
Program : 100F_msbf_m1_14_failed_snapshot_row_hash_validation_recovery_v0_2R4.sql
Version : v0.2R4
Purpose : Prove that committed M1.14 generation is internally valid and that
          the sole positive-control failure was caused by hashing an enriched
          validation row containing the nonphysical scenario_code column.
          Preserve the original finding, restore the run to M1_14_GENERATED,
          and authorize corrected validation from program 103 onward.
Inputs  : Committed M1.14 v0.2R3 generation; 82 positive controls with only
          M1_14_POS_26 failed; seven passed negative controls; failed first
          acceptance review; approved blocked-evidence contract V2.
Outputs : One durable defect-history evidence record, a governed run-status
          reset to M1_14_GENERATED, and one filterable recovery result.
Safety  : No M1.14 snapshot, component, parameter, policy, hash, accepted
          upstream record, or acceptance-history row is deleted or changed.
          Any state other than the exact diagnosed failure fails closed.
Required: recovery_status = PASS.
============================================================================ */

BEGIN;
SET LOCAL lock_timeout = '10s';
SET LOCAL statement_timeout = '10min';

DROP TABLE IF EXISTS _m1_14_r4_hash_validation_recovery;
CREATE TEMP TABLE _m1_14_r4_hash_validation_recovery (
    run_id bigint,
    prior_run_status text,
    final_run_status text,
    snapshot_rows bigint,
    component_rows bigint,
    positive_checks bigint,
    positive_passes bigint,
    positive_failures bigint,
    failed_positive_codes text,
    reported_pos26_mismatches bigint,
    physical_snapshot_hash_mismatches bigint,
    enriched_snapshot_hash_mismatches bigint,
    component_hash_mismatches bigint,
    negative_controls bigint,
    negative_passes bigint,
    negative_failures bigint,
    acceptance_gate_rows bigint,
    latest_acceptance_review_version integer,
    latest_acceptance_gate_status text,
    acceptance_summary_status text,
    canonical_entities bigint,
    stored_canonical_mismatches bigint,
    recomputed_snapshot_hash text,
    stored_snapshot_hash text,
    recomputed_component_hash text,
    stored_component_hash text,
    recomputed_combined_hash text,
    stored_combined_hash text,
    blocked_contract_state text,
    downstream_rows bigint,
    blocking_errors bigint,
    recovery_action text,
    recovery_status text
) ON COMMIT PRESERVE ROWS;

DO $recover$
DECLARE
    v_run_id bigint;
    v_prior_status text;
    v_snapshot_rows bigint;
    v_component_rows bigint;
    v_pos_checks bigint;
    v_pos_passes bigint;
    v_pos_failures bigint;
    v_failed_codes text;
    v_reported_pos26 bigint;
    v_physical_snapshot_mismatches bigint;
    v_enriched_snapshot_mismatches bigint;
    v_component_mismatches bigint;
    v_neg_controls bigint;
    v_neg_passes bigint;
    v_neg_failures bigint;
    v_gate_rows bigint;
    v_latest_gate_review integer;
    v_latest_gate_status text;
    v_acceptance_summary_status text;
    v_canonical_entities bigint;
    v_stored_mismatches bigint;
    v_snapshot_hash text;
    v_component_hash text;
    v_combined_hash text;
    v_stored_snapshot_hash text;
    v_stored_component_hash text;
    v_stored_combined_hash text;
    v_constraint_def text;
    v_constraint_validated boolean;
    v_constraint_comment text;
    v_contract_state text;
    v_downstream_rows bigint;
    v_blocking_errors bigint;
BEGIN
    SELECT run_id, run_status
    INTO STRICT v_run_id, v_prior_status
    FROM msbf_ctl.run_registry
    WHERE run_code='M1_V0_2_BASELINE_BUILD'
      AND run_version=1
    FOR UPDATE;

    SELECT count(*)
    INTO v_snapshot_rows
    FROM msbf_m1.application_unit_economics_snapshot
    WHERE module1_run_id=v_run_id;

    SELECT count(*)
    INTO v_component_rows
    FROM msbf_m1.unit_economics_component_value
    WHERE module1_run_id=v_run_id;

    SELECT
        count(*),
        count(*) FILTER (WHERE status='PASS'),
        count(*) FILTER (WHERE status='FAIL'),
        string_agg(evidence_code,',' ORDER BY evidence_code)
            FILTER (WHERE status='FAIL')
    INTO
        v_pos_checks,
        v_pos_passes,
        v_pos_failures,
        v_failed_codes
    FROM msbf_ctl.run_evidence
    WHERE run_id=v_run_id
      AND evidence_code LIKE 'M1_14_POS_%';

    SELECT metric_value_text::bigint
    INTO v_reported_pos26
    FROM msbf_ctl.run_evidence
    WHERE run_id=v_run_id
      AND evidence_code='M1_14_POS_26_SNAPSHOT_ROW_HASH'
      AND segment_key='PORTFOLIO';

    /* Authoritative physical-row reconstruction: no reporting enrichment. */
    SELECT count(*)
    INTO v_physical_snapshot_mismatches
    FROM msbf_m1.application_unit_economics_snapshot e
    WHERE e.module1_run_id=v_run_id
      AND e.row_hash IS DISTINCT FROM
          msbf_m1.m1_14_hash_jsonb(to_jsonb(e)-'row_hash'-'created_at');

    /* Reproduce the legacy defect exactly: scenario_code is not a physical
       snapshot column, so adding it to the record changes every JSON hash. */
    WITH enriched AS (
        SELECT e.*, sr.scenario_code
        FROM msbf_m1.application_unit_economics_snapshot e
        JOIN msbf_ctl.scenario_registry sr USING(scenario_id)
        WHERE e.module1_run_id=v_run_id
    )
    SELECT count(*)
    INTO v_enriched_snapshot_mismatches
    FROM enriched e
    WHERE e.row_hash IS DISTINCT FROM
          msbf_m1.m1_14_hash_jsonb(to_jsonb(e)-'row_hash'-'created_at');

    SELECT count(*)
    INTO v_component_mismatches
    FROM msbf_m1.unit_economics_component_value c
    WHERE c.module1_run_id=v_run_id
      AND c.calculation_hash IS DISTINCT FROM
          msbf_m1.m1_14_hash_jsonb(to_jsonb(c)-'calculation_hash'-'created_at');

    SELECT
        count(*),
        count(*) FILTER (WHERE status='PASS'),
        count(*) FILTER (WHERE status='FAIL')
    INTO
        v_neg_controls,
        v_neg_passes,
        v_neg_failures
    FROM msbf_ctl.run_evidence
    WHERE run_id=v_run_id
      AND evidence_code LIKE 'M1_14_NEG_%';

    SELECT count(*)
    INTO v_gate_rows
    FROM msbf_ctl.acceptance_gate_result
    WHERE run_id=v_run_id
      AND gate_id='M1_14_UNIT_ECONOMICS_CONTRIBUTION';

    SELECT review_version, result_status
    INTO v_latest_gate_review, v_latest_gate_status
    FROM msbf_ctl.acceptance_gate_result
    WHERE run_id=v_run_id
      AND gate_id='M1_14_UNIT_ECONOMICS_CONTRIBUTION'
    ORDER BY review_version DESC
    LIMIT 1;

    SELECT max(status)
    INTO v_acceptance_summary_status
    FROM msbf_ctl.run_evidence
    WHERE run_id=v_run_id
      AND evidence_code='M1_14_ACCEPTANCE_SUMMARY'
      AND segment_key='PORTFOLIO';

    WITH actual AS (
        SELECT * FROM msbf_m1.m1_14_actual_snapshot(v_run_id)
        UNION ALL
        SELECT * FROM msbf_m1.m1_14_actual_component_snapshot(v_run_id)
    )
    SELECT
        count(*),
        (SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key))
         FROM actual WHERE entity_key LIKE 'ECON|%'),
        (SELECT md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key))
         FROM actual WHERE entity_key LIKE 'COMP|%'),
        md5(string_agg(entity_key||'|'||row_hash,'||' ORDER BY entity_key))
    INTO
        v_canonical_entities,
        v_snapshot_hash,
        v_component_hash,
        v_combined_hash
    FROM actual;

    SELECT
        max(metric_value_text) FILTER (WHERE evidence_code='M1_14_SNAPSHOT_SET_HASH'),
        max(metric_value_text) FILTER (WHERE evidence_code='M1_14_COMPONENT_SET_HASH'),
        max(metric_value_text) FILTER (WHERE evidence_code='M1_14_COMBINED_SET_HASH'),
        (max(metric_value_numeric)
            FILTER (WHERE evidence_code='M1_14_CANONICAL_MISMATCH_COUNT'))::bigint
    INTO
        v_stored_snapshot_hash,
        v_stored_component_hash,
        v_stored_combined_hash,
        v_stored_mismatches
    FROM msbf_ctl.run_evidence
    WHERE run_id=v_run_id;

    SELECT
        pg_get_constraintdef(c.oid),
        c.convalidated,
        obj_description(c.oid,'pg_constraint')
    INTO STRICT
        v_constraint_def,
        v_constraint_validated,
        v_constraint_comment
    FROM pg_constraint c
    JOIN pg_class t ON t.oid=c.conrelid
    JOIN pg_namespace n ON n.oid=t.relnamespace
    WHERE n.nspname='msbf_m1'
      AND t.relname='application_unit_economics_snapshot'
      AND c.conname='ck_m1_14_blocked';

    v_contract_state := CASE
        WHEN v_constraint_validated
         AND coalesce(v_constraint_comment,'') LIKE 'MSBF_M1_14_BLOCKED_CONTRACT_V2%'
         AND position('(baseline_risk_adjusted_contribution_amount is null)' in lower(v_constraint_def))=0
         AND position('(baseline_annualized_risk_adjusted_return_rate is null)' in lower(v_constraint_def))=0
         AND position('(comparative_expected_loss_amount is null)' in lower(v_constraint_def))>0
         AND position('(risk_adjusted_contribution_amount is null)' in lower(v_constraint_def))>0
         AND position('(annualized_risk_adjusted_return_rate is null)' in lower(v_constraint_def))>0
        THEN 'APPROVED_V2'
        ELSE 'NOT_APPROVED_V2'
    END;

    SELECT
        (SELECT count(*) FROM msbf_m1.module1_latest WHERE module1_run_id=v_run_id)
      + (SELECT count(*) FROM msbf_m1.module1_archive WHERE module1_run_id=v_run_id)
    INTO v_downstream_rows;

    SELECT count(*)
    INTO v_blocking_errors
    FROM msbf_ctl.profile_resolution_error
    WHERE run_id=v_run_id
      AND severity='BLOCKING';

    IF v_prior_status<>'M1_14_FAILED'
       OR v_snapshot_rows<>1500
       OR v_component_rows<>21000
       OR v_pos_checks<>82
       OR v_pos_passes<>81
       OR v_pos_failures<>1
       OR v_failed_codes IS DISTINCT FROM 'M1_14_POS_26_SNAPSHOT_ROW_HASH'
       OR v_reported_pos26<>1500
       OR v_physical_snapshot_mismatches<>0
       OR v_enriched_snapshot_mismatches<>1500
       OR v_component_mismatches<>0
       OR v_neg_controls<>7
       OR v_neg_passes<>7
       OR v_neg_failures<>0
       OR v_gate_rows<1
       OR v_latest_gate_status IS DISTINCT FROM 'FAIL'
       OR v_acceptance_summary_status IS DISTINCT FROM 'FAIL'
       OR v_canonical_entities<>22500
       OR v_stored_mismatches<>0
       OR v_snapshot_hash IS DISTINCT FROM v_stored_snapshot_hash
       OR v_component_hash IS DISTINCT FROM v_stored_component_hash
       OR v_combined_hash IS DISTINCT FROM v_stored_combined_hash
       OR v_contract_state<>'APPROVED_V2'
       OR v_downstream_rows<>0
       OR v_blocking_errors<>0 THEN
        RAISE EXCEPTION
            'M1.14 R4 recovery preconditions failed: status %, snapshots %, components %, positive %/%/% codes %, reported POS26 %, physical %, enriched %, component %, negative %/%/%, gate rows % latest %/% acceptance %, canonical % stored mismatches %, hashes %/% | %/% | %/%, contract %, downstream %, blocking %.',
            v_prior_status,v_snapshot_rows,v_component_rows,
            v_pos_checks,v_pos_passes,v_pos_failures,v_failed_codes,
            v_reported_pos26,v_physical_snapshot_mismatches,
            v_enriched_snapshot_mismatches,v_component_mismatches,
            v_neg_controls,v_neg_passes,v_neg_failures,
            v_gate_rows,v_latest_gate_review,v_latest_gate_status,
            v_acceptance_summary_status,v_canonical_entities,v_stored_mismatches,
            v_snapshot_hash,v_stored_snapshot_hash,
            v_component_hash,v_stored_component_hash,
            v_combined_hash,v_stored_combined_hash,
            v_contract_state,v_downstream_rows,v_blocking_errors;
    END IF;

    /* Preserve the original failed control before program 103 overwrites the
       operational POS26 evidence with the corrected physical-row result. */
    INSERT INTO msbf_ctl.run_evidence(
        run_id,evidence_code,segment_key,metric_name,
        metric_value_text,unit_code,status,interpretation
    )
    VALUES(
        v_run_id,
        'M1_14_R4_POS26_VALIDATION_DEFECT_HISTORY',
        'PORTFOLIO',
        'M1.14 POS26 enriched-row validation defect history',
        format(
            'reported=%s|physical=%s|enriched=%s|components=%s|cause=NONPHYSICAL_SCENARIO_CODE_INCLUDED_IN_JSON_HASH',
            v_reported_pos26,v_physical_snapshot_mismatches,
            v_enriched_snapshot_mismatches,v_component_mismatches
        ),
        'TEXT',
        'PASS',
        'The original POS26 failure is preserved as audit history. Committed snapshot hashes reconstruct exactly from physical table fields; the failed validation hashed an enriched row containing scenario_code.'
    )
    ON CONFLICT(run_id,evidence_code,segment_key) DO UPDATE SET
        metric_name=EXCLUDED.metric_name,
        metric_value_text=EXCLUDED.metric_value_text,
        metric_value_numeric=NULL,
        unit_code=EXCLUDED.unit_code,
        status=EXCLUDED.status,
        interpretation=EXCLUDED.interpretation,
        created_at=clock_timestamp();

    UPDATE msbf_ctl.run_registry
    SET run_status='M1_14_GENERATED',
        notes=coalesce(notes,'')
            || E'\nM1.14 v0.2R4 recovery confirmed the sole POS26 failure was a validation-row enrichment defect; committed generation and physical hashes were preserved.'
    WHERE run_id=v_run_id;

    INSERT INTO _m1_14_r4_hash_validation_recovery VALUES(
        v_run_id,
        v_prior_status,
        'M1_14_GENERATED',
        v_snapshot_rows,
        v_component_rows,
        v_pos_checks,
        v_pos_passes,
        v_pos_failures,
        v_failed_codes,
        v_reported_pos26,
        v_physical_snapshot_mismatches,
        v_enriched_snapshot_mismatches,
        v_component_mismatches,
        v_neg_controls,
        v_neg_passes,
        v_neg_failures,
        v_gate_rows,
        v_latest_gate_review,
        v_latest_gate_status,
        v_acceptance_summary_status,
        v_canonical_entities,
        v_stored_mismatches,
        v_snapshot_hash,
        v_stored_snapshot_hash,
        v_component_hash,
        v_stored_component_hash,
        v_combined_hash,
        v_stored_combined_hash,
        v_contract_state,
        v_downstream_rows,
        v_blocking_errors,
        'PRESERVED_GENERATION_RESET_FOR_CORRECTED_VALIDATION',
        'PASS'
    );
END;
$recover$;

COMMIT;

SELECT *
FROM _m1_14_r4_hash_validation_recovery;
