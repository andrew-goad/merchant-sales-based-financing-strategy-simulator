/* ============================================================================
Merchant Sales-Based Financing Strategy Simulator
Module 2.7 — Operational Activation & Account Setup
============================================================================ */

/* ============================================================================
Program     : 182_msbf_m2_7_operational_activation_generation_v0_2R1.sql
Version     : v0.2R1

Purpose
-------
Materialize the accepted M2.6 latest contract exactly once and generate:
- an immutable M2.6 source snapshot;
- deterministic operational setup outcomes and actions;
- synthetic operational case, account-setup, and servicing-plan identifiers;
- synthetic effective and reassessment dates;
- scenario summaries;
- latest and immutable archive contracts;
- set, contract, and canonical identities;
- 24 governed generation-evidence rows.

Performance design
------------------
The accepted source is materialized once, indexed, and ANALYZED. Target-typed
staging is reused downstream. No accepted blueprint is regenerated and no
large self-join is used where grouped aggregation suffices.

Stage boundary
--------------
All outputs are synthetic setup blueprints. No production action is executed.

Required result
---------------
generation_status = PASS, 341 canonical entities, zero row mismatches,
57 no-setup rows, 1 temporary blueprint, 1 review row, and zero stress
improvements.

Revision v0.2R1
---------------
`CREATE TABLE ... LIKE` copies PostgreSQL NOT NULL attributes even when
`EXCLUDING CONSTRAINTS` is specified. The v0.2 target-typed latest staging
table therefore inherited `contract_row_hash NOT NULL` and rejected the
intentional NULL placeholder before its physical hash could be populated.

v0.2R1:
- temporarily drops NOT NULL from the staging-only hash column;
- populates every target-typed contract hash;
- fails closed if any hash remains NULL or malformed;
- restores NOT NULL before the persistent latest/archive insert;
- changes no mapping, setup term, lifecycle identity, expected count, or
  accepted M2.6 source boundary.
============================================================================ */

BEGIN;

SET LOCAL work_mem='192MB';
SET LOCAL lock_timeout='10s';
SET LOCAL statement_timeout='60min';
SET LOCAL jit=off;

/* Section 1 — Session checkpoint and context. */

DROP TABLE IF EXISTS _m2_7_result;

CREATE TEMP TABLE _m2_7_result
(
    run_id bigint,
    run_status text,
    policy_rows bigint,
    outcome_rows bigint,
    action_rows bigint,
    reason_rows bigint,
    source_rows bigint,
    activation_rows bigint,
    account_setup_rows bigint,
    portfolio_summary_rows bigint,
    latest_rows bigint,
    archive_rows bigint,
    comparison_rows bigint,
    registry_rows bigint,

    no_setup_required_rows bigint,
    standard_setup_rows bigint,
    temporary_adjustment_setup_rows bigint,
    restructure_setup_rows bigint,
    recovery_setup_rows bigint,
    charge_off_setup_rows bigint,
    review_required_rows bigint,
    setup_authorized_rows bigint,
    setup_authorized_amount numeric(24,2),
    review_required_amount numeric(24,2),

    expected_canonical_entities bigint,
    actual_canonical_entities bigint,
    row_level_mismatches bigint,
    stress_setup_permission_improvements bigint,
    stress_priority_improvements bigint,

    policy_set_hash text,
    outcome_set_hash text,
    action_set_hash text,
    reason_set_hash text,
    source_set_hash text,
    activation_set_hash text,
    account_setup_set_hash text,
    portfolio_summary_set_hash text,
    latest_set_hash text,
    archive_set_hash text,
    contract_set_hash text,
    combined_set_hash text,
    generation_status text
)
ON COMMIT PRESERVE ROWS;

DROP TABLE IF EXISTS _m2_7_ctx;

CREATE TEMP TABLE _m2_7_ctx
ON COMMIT DROP
AS
SELECT
    run.run_id,
    run.as_of_date,
    policy.configuration_hash,
    policy.default_temporary_payment_factor,
    policy.default_setup_duration_days,
    policy.default_reassessment_interval_days,
    policy.activation_effective_lag_days,
    policy.source_combined_set_hash
FROM msbf_ctl.run_registry AS run
JOIN msbf_ctl.m2_7_policy_profile AS policy
  ON policy.module1_run_id=run.run_id
WHERE run.run_code='M1_V0_2_BASELINE_BUILD'
  AND run.run_version=1;

DO $m2_7_generation_ready$
BEGIN
    PERFORM msbf_ctl.m2_7_assert_generation_ready
    (
        (SELECT run_id FROM _m2_7_ctx)
    );
END;
$m2_7_generation_ready$;

/* Section 2 — Materialize accepted M2.6 source once. */

DROP TABLE IF EXISTS _m2_7_source_input;

CREATE TEMP TABLE _m2_7_source_input
ON COMMIT DROP
AS
SELECT
    source.module1_run_id::bigint AS module1_run_id,
    source.scenario_id::bigint AS scenario_id,
    source.scenario_code::text AS scenario_code,
    source.merchant_application_id::text AS merchant_application_id,
    source.merchant_id::text AS merchant_id,
    source.synthetic_account_id::text AS synthetic_account_id,
    source.synthetic_advance_id::text AS synthetic_advance_id,

    source.strategy_outcome_code::text AS source_strategy_outcome_code,
    source.servicing_action_code::text AS source_servicing_action_code,
    source.recommended_action_flag::boolean AS source_recommended_action_flag,
    source.review_required_flag::boolean AS source_review_required_flag,
    source.recommended_action_exposure_amount::numeric(18,2)
        AS source_recommended_action_exposure_amount,
    source.temporary_remittance_rate_factor::numeric(9,6)
        AS source_temporary_payment_factor,
    source.recommended_review_duration_days::integer
        AS source_review_duration_days,
    source.reassessment_interval_days::integer
        AS source_reassessment_interval_days,

    source.contract_row_hash::text AS source_contract_row_hash,
    ctx.source_combined_set_hash::text AS source_combined_set_hash,
    to_jsonb(source) AS source_payload

FROM msbf_m2.advance_intervention_strategy_latest AS source
CROSS JOIN _m2_7_ctx AS ctx
WHERE source.module1_run_id=ctx.run_id;

CREATE UNIQUE INDEX
ON _m2_7_source_input
(module1_run_id,scenario_id,merchant_application_id);

CREATE INDEX
ON _m2_7_source_input
(module1_run_id,source_strategy_outcome_code,source_servicing_action_code);

ANALYZE _m2_7_source_input;

/* Section 3 — Target-typed accepted source snapshot. */

DROP TABLE IF EXISTS _m2_7_source_expected;

CREATE TEMP TABLE _m2_7_source_expected
(
    module1_run_id bigint NOT NULL,
    scenario_id bigint NOT NULL,
    scenario_code text NOT NULL,
    merchant_application_id text NOT NULL,
    merchant_id text NOT NULL,
    synthetic_account_id text NOT NULL,
    synthetic_advance_id text NOT NULL,

    source_strategy_outcome_code text NOT NULL,
    source_servicing_action_code text NOT NULL,
    source_recommended_action_flag boolean NOT NULL,
    source_review_required_flag boolean NOT NULL,
    source_recommended_action_exposure_amount numeric(18,2) NOT NULL,
    source_temporary_payment_factor numeric(9,6),
    source_review_duration_days integer,
    source_reassessment_interval_days integer,

    source_contract_row_hash text NOT NULL,
    source_combined_set_hash text NOT NULL,
    source_payload jsonb NOT NULL,
    row_hash text
)
ON COMMIT DROP;

INSERT INTO _m2_7_source_expected
(
    module1_run_id,scenario_id,scenario_code,merchant_application_id,
    merchant_id,synthetic_account_id,synthetic_advance_id,
    source_strategy_outcome_code,source_servicing_action_code,
    source_recommended_action_flag,source_review_required_flag,
    source_recommended_action_exposure_amount,
    source_temporary_payment_factor,source_review_duration_days,
    source_reassessment_interval_days,source_contract_row_hash,
    source_combined_set_hash,source_payload,row_hash
)
SELECT
    module1_run_id,scenario_id,scenario_code,merchant_application_id,
    merchant_id,synthetic_account_id,synthetic_advance_id,
    source_strategy_outcome_code,source_servicing_action_code,
    source_recommended_action_flag,source_review_required_flag,
    source_recommended_action_exposure_amount,
    source_temporary_payment_factor,source_review_duration_days,
    source_reassessment_interval_days,source_contract_row_hash,
    source_combined_set_hash,source_payload,NULL::text
FROM _m2_7_source_input;

UPDATE _m2_7_source_expected AS source
SET row_hash=msbf_ctl.m2_7_hash_jsonb(to_jsonb(source)-'row_hash')
WHERE source.row_hash IS NULL;

CREATE UNIQUE INDEX
ON _m2_7_source_expected
(module1_run_id,scenario_id,merchant_application_id);

ANALYZE _m2_7_source_expected;

DO $m2_7_source_guard$
DECLARE
    v record;
BEGIN
    SELECT
        count(*) AS source_rows,
        count
        (
            DISTINCT scenario_id::text||'|'||merchant_application_id
        ) AS distinct_rows,
        count(*) FILTER
        (
            WHERE row_hash IS NULL
               OR source_contract_row_hash IS NULL
               OR source_combined_set_hash<>'868125bff29270490cab4d2e55cb1388'
        ) AS invalid_rows,
        count(*) FILTER
        (
            WHERE source_strategy_outcome_code='CLOSED_NO_FURTHER_ACTION'
              AND source_servicing_action_code='NO_ACTION_CLOSED'
        ) AS closed_rows,
        count(*) FILTER
        (
            WHERE source_strategy_outcome_code=
                  'TEMPORARY_REMITTANCE_ADJUSTMENT_REVIEW'
              AND source_servicing_action_code='TEMPORARY_REMITTANCE_REVIEW'
        ) AS temporary_rows,
        count(*) FILTER
        (
            WHERE source_strategy_outcome_code=
                  'TARGETED_MERCHANT_OUTREACH_REVIEW'
              AND source_servicing_action_code='OUTREACH_REVIEW_QUEUE'
        ) AS outreach_rows
    INTO v
    FROM _m2_7_source_expected;

    IF v.source_rows<>59
       OR v.distinct_rows<>59
       OR v.invalid_rows<>0
       OR v.closed_rows<>57
       OR v.temporary_rows<>1
       OR v.outreach_rows<>1
    THEN
        RAISE EXCEPTION
            'M2.7 source materialization failed: %.',
            row_to_json(v);
    END IF;
END;
$m2_7_source_guard$;

INSERT INTO msbf_m2.operational_activation_source_snapshot
(
    module1_run_id,scenario_id,scenario_code,merchant_application_id,
    merchant_id,synthetic_account_id,synthetic_advance_id,
    source_strategy_outcome_code,source_servicing_action_code,
    source_recommended_action_flag,source_review_required_flag,
    source_recommended_action_exposure_amount,
    source_temporary_payment_factor,source_review_duration_days,
    source_reassessment_interval_days,source_contract_row_hash,
    source_combined_set_hash,source_payload,row_hash
)
SELECT
    module1_run_id,scenario_id,scenario_code,merchant_application_id,
    merchant_id,synthetic_account_id,synthetic_advance_id,
    source_strategy_outcome_code,source_servicing_action_code,
    source_recommended_action_flag,source_review_required_flag,
    source_recommended_action_exposure_amount,
    source_temporary_payment_factor,source_review_duration_days,
    source_reassessment_interval_days,source_contract_row_hash,
    source_combined_set_hash,source_payload,row_hash
FROM _m2_7_source_expected;

/* Section 4 — Exact source-to-operational mapping. */

DROP TABLE IF EXISTS _m2_7_mapping;

CREATE TEMP TABLE _m2_7_mapping
ON COMMIT DROP
AS
SELECT
    source.*,

    CASE
        WHEN source.source_strategy_outcome_code='CLOSED_NO_FURTHER_ACTION'
         AND source.source_servicing_action_code='NO_ACTION_CLOSED'
        THEN 'NO_OPERATIONAL_SETUP_REQUIRED'

        WHEN source.source_strategy_outcome_code=
             'TEMPORARY_REMITTANCE_ADJUSTMENT_REVIEW'
         AND source.source_servicing_action_code=
             'TEMPORARY_REMITTANCE_REVIEW'
        THEN 'TEMPORARY_PAYMENT_ADJUSTMENT_SETUP_READY'

        WHEN source.source_strategy_outcome_code=
             'TARGETED_MERCHANT_OUTREACH_REVIEW'
         AND source.source_servicing_action_code='OUTREACH_REVIEW_QUEUE'
        THEN 'OPERATIONAL_SETUP_REVIEW_REQUIRED'

        WHEN source.source_strategy_outcome_code='CONTINUE_STANDARD_MONITORING'
         AND source.source_servicing_action_code='CONTINUE_STANDARD_MONITORING'
        THEN 'STANDARD_SERVICING_SETUP_READY'

        WHEN source.source_strategy_outcome_code='WORKOUT_RESTRUCTURE_REVIEW'
        THEN 'RESTRUCTURE_SETUP_READY'

        WHEN source.source_strategy_outcome_code=
             'CONTROLLED_EXIT_RECOVERY_REVIEW'
        THEN 'CONTROLLED_RECOVERY_SETUP_READY'

        ELSE 'OPERATIONAL_SETUP_REVIEW_REQUIRED'
    END AS operational_setup_outcome_code

FROM _m2_7_source_expected AS source;

ALTER TABLE _m2_7_mapping
    ADD COLUMN operational_setup_action_code text,
    ADD COLUMN operational_setup_priority_rank integer,
    ADD COLUMN operational_setup_queue_code text,
    ADD COLUMN setup_authorized_flag boolean,
    ADD COLUMN blueprint_created_flag boolean,
    ADD COLUMN setup_review_required_flag boolean,
    ADD COLUMN no_setup_required_flag boolean,
    ADD COLUMN primary_setup_reason_code text,
    ADD COLUMN setup_reason_codes jsonb;

UPDATE _m2_7_mapping AS mapping
SET
    operational_setup_action_code=
        CASE operational_setup_outcome_code
            WHEN 'NO_OPERATIONAL_SETUP_REQUIRED'
            THEN 'CLOSE_WITHOUT_SETUP'
            WHEN 'STANDARD_SERVICING_SETUP_READY'
            THEN 'CREATE_STANDARD_SERVICING_BLUEPRINT'
            WHEN 'TEMPORARY_PAYMENT_ADJUSTMENT_SETUP_READY'
            THEN 'CREATE_TEMPORARY_ADJUSTMENT_BLUEPRINT'
            WHEN 'RESTRUCTURE_SETUP_READY'
            THEN 'CREATE_RESTRUCTURE_BLUEPRINT'
            WHEN 'CONTROLLED_RECOVERY_SETUP_READY'
            THEN 'CREATE_RECOVERY_BLUEPRINT'
            WHEN 'CHARGE_OFF_SETUP_READY'
            THEN 'CREATE_CHARGE_OFF_BLUEPRINT'
            ELSE 'ROUTE_OPERATIONAL_GOVERNANCE_REVIEW'
        END,

    operational_setup_priority_rank=
        CASE operational_setup_outcome_code
            WHEN 'NO_OPERATIONAL_SETUP_REQUIRED' THEN 0
            WHEN 'STANDARD_SERVICING_SETUP_READY' THEN 1
            WHEN 'TEMPORARY_PAYMENT_ADJUSTMENT_SETUP_READY' THEN 2
            WHEN 'RESTRUCTURE_SETUP_READY' THEN 3
            WHEN 'CONTROLLED_RECOVERY_SETUP_READY' THEN 4
            WHEN 'CHARGE_OFF_SETUP_READY' THEN 5
            ELSE 9
        END,

    operational_setup_queue_code=
        CASE operational_setup_outcome_code
            WHEN 'NO_OPERATIONAL_SETUP_REQUIRED' THEN 'CLOSED'
            WHEN 'STANDARD_SERVICING_SETUP_READY'
            THEN 'STANDARD_SERVICING_SETUP'
            WHEN 'TEMPORARY_PAYMENT_ADJUSTMENT_SETUP_READY'
            THEN 'TEMPORARY_ADJUSTMENT_SETUP'
            WHEN 'RESTRUCTURE_SETUP_READY' THEN 'RESTRUCTURE_SETUP'
            WHEN 'CONTROLLED_RECOVERY_SETUP_READY'
            THEN 'CONTROLLED_RECOVERY_SETUP'
            WHEN 'CHARGE_OFF_SETUP_READY' THEN 'CHARGE_OFF_SETUP'
            ELSE 'OPERATIONAL_GOVERNANCE_REVIEW'
        END,

    setup_authorized_flag=
        operational_setup_outcome_code IN
        (
            'STANDARD_SERVICING_SETUP_READY',
            'TEMPORARY_PAYMENT_ADJUSTMENT_SETUP_READY',
            'RESTRUCTURE_SETUP_READY',
            'CONTROLLED_RECOVERY_SETUP_READY',
            'CHARGE_OFF_SETUP_READY'
        ),

    blueprint_created_flag=
        operational_setup_outcome_code IN
        (
            'STANDARD_SERVICING_SETUP_READY',
            'TEMPORARY_PAYMENT_ADJUSTMENT_SETUP_READY',
            'RESTRUCTURE_SETUP_READY',
            'CONTROLLED_RECOVERY_SETUP_READY',
            'CHARGE_OFF_SETUP_READY'
        ),

    setup_review_required_flag=
        operational_setup_outcome_code='OPERATIONAL_SETUP_REVIEW_REQUIRED',

    no_setup_required_flag=
        operational_setup_outcome_code='NO_OPERATIONAL_SETUP_REQUIRED',

    primary_setup_reason_code=
        CASE operational_setup_outcome_code
            WHEN 'NO_OPERATIONAL_SETUP_REQUIRED'
            THEN 'M2_7_REASON_SOURCE_NO_SETUP'
            WHEN 'STANDARD_SERVICING_SETUP_READY'
            THEN 'M2_7_REASON_SOURCE_STANDARD_SETUP'
            WHEN 'TEMPORARY_PAYMENT_ADJUSTMENT_SETUP_READY'
            THEN 'M2_7_REASON_SOURCE_TEMPORARY_ADJUSTMENT'
            WHEN 'RESTRUCTURE_SETUP_READY'
            THEN 'M2_7_REASON_SOURCE_RESTRUCTURE'
            WHEN 'CONTROLLED_RECOVERY_SETUP_READY'
            THEN 'M2_7_REASON_SOURCE_CONTROLLED_RECOVERY'
            WHEN 'CHARGE_OFF_SETUP_READY'
            THEN 'M2_7_REASON_SOURCE_CHARGE_OFF'
            WHEN 'OPERATIONAL_SETUP_REVIEW_REQUIRED'
            THEN
                CASE
                    WHEN source_strategy_outcome_code=
                         'TARGETED_MERCHANT_OUTREACH_REVIEW'
                    THEN 'M2_7_REASON_SOURCE_REVIEW_ONLY'
                    ELSE 'M2_7_REASON_SOURCE_UNRESOLVED'
                END
        END
WHERE operational_setup_action_code IS NULL;

UPDATE _m2_7_mapping AS mapping
SET setup_reason_codes=to_jsonb
(
    array_remove
    (
        ARRAY
        [
            mapping.primary_setup_reason_code,
            'M2_7_REASON_ACCOUNT_ID_PRESENT',
            'M2_7_REASON_ADVANCE_ID_PRESENT',
            CASE
                WHEN mapping.source_recommended_action_exposure_amount>0
                THEN 'M2_7_REASON_EXPOSURE_PRESENT'
                ELSE 'M2_7_REASON_EXPOSURE_ZERO'
            END,
            CASE
                WHEN mapping.operational_setup_outcome_code=
                     'TEMPORARY_PAYMENT_ADJUSTMENT_SETUP_READY'
                 AND mapping.source_temporary_payment_factor IS NOT NULL
                THEN 'M2_7_REASON_TEMPORARY_FACTOR_PRESENT'
                WHEN mapping.operational_setup_outcome_code=
                     'TEMPORARY_PAYMENT_ADJUSTMENT_SETUP_READY'
                THEN 'M2_7_REASON_TEMPORARY_FACTOR_DEFAULTED'
            END,
            CASE
                WHEN mapping.scenario_code='BASELINE'
                THEN 'M2_7_REASON_BASELINE_SCENARIO'
                WHEN mapping.scenario_code='RECESSION_ENERGY'
                THEN 'M2_7_REASON_STRESS_SCENARIO'
            END,
            'M2_7_REASON_SOURCE_HASH_PRESENT',
            'M2_7_REASON_SOURCE_CONTRACT_ACCEPTED',
            'M2_7_REASON_HISTORY_PRESERVED',
            'M2_7_REASON_REAL_EXECUTION_PROHIBITED',
            'M2_7_REASON_SYNTHETIC_ONLY'
        ]::text[],
        NULL
    )
)
WHERE setup_reason_codes IS NULL;

CREATE UNIQUE INDEX
ON _m2_7_mapping
(module1_run_id,scenario_id,merchant_application_id);

CREATE INDEX
ON _m2_7_mapping
(module1_run_id,operational_setup_outcome_code);

ANALYZE _m2_7_mapping;

DO $m2_7_mapping_guard$
DECLARE
    v record;
BEGIN
    SELECT
        count(*) AS mapping_rows,
        count(*) FILTER
        (
            WHERE operational_setup_outcome_code=
                  'NO_OPERATIONAL_SETUP_REQUIRED'
        ) AS no_setup_rows,
        count(*) FILTER
        (
            WHERE operational_setup_outcome_code=
                  'TEMPORARY_PAYMENT_ADJUSTMENT_SETUP_READY'
        ) AS temporary_rows,
        count(*) FILTER
        (
            WHERE operational_setup_outcome_code=
                  'OPERATIONAL_SETUP_REVIEW_REQUIRED'
        ) AS review_rows,
        count(*) FILTER
        (
            WHERE operational_setup_outcome_code NOT IN
            (
                'NO_OPERATIONAL_SETUP_REQUIRED',
                'TEMPORARY_PAYMENT_ADJUSTMENT_SETUP_READY',
                'OPERATIONAL_SETUP_REVIEW_REQUIRED'
            )
        ) AS other_rows,
        round
        (
            sum
            (
                CASE WHEN setup_authorized_flag
                     THEN source_recommended_action_exposure_amount
                     ELSE 0 END
            ),
            2
        ) AS setup_amount,
        round
        (
            sum
            (
                CASE WHEN setup_review_required_flag
                     THEN source_recommended_action_exposure_amount
                     ELSE 0 END
            ),
            2
        ) AS review_amount
    INTO v
    FROM _m2_7_mapping;

    IF v.mapping_rows<>59
       OR v.no_setup_rows<>57
       OR v.temporary_rows<>1
       OR v.review_rows<>1
       OR v.other_rows<>0
       OR v.setup_amount<>518.04
       OR v.review_amount<>461.69
    THEN
        RAISE EXCEPTION
            'M2.7 exact source mapping failed: %.',
            row_to_json(v);
    END IF;
END;
$m2_7_mapping_guard$;

/* Section 5 — Target-typed activation snapshot. */

DROP TABLE IF EXISTS _m2_7_activation_expected;

CREATE TEMP TABLE _m2_7_activation_expected
(
    module1_run_id bigint NOT NULL,
    scenario_id bigint NOT NULL,
    scenario_code text NOT NULL,
    merchant_application_id text NOT NULL,
    merchant_id text NOT NULL,
    synthetic_account_id text NOT NULL,
    synthetic_advance_id text NOT NULL,

    source_strategy_outcome_code text NOT NULL,
    source_servicing_action_code text NOT NULL,
    source_recommended_action_exposure_amount numeric(18,2) NOT NULL,

    operational_setup_outcome_code text NOT NULL,
    operational_setup_action_code text NOT NULL,
    operational_setup_priority_rank integer NOT NULL,
    operational_setup_queue_code text NOT NULL,

    setup_authorized_flag boolean NOT NULL,
    blueprint_created_flag boolean NOT NULL,
    setup_review_required_flag boolean NOT NULL,
    no_setup_required_flag boolean NOT NULL,

    synthetic_operational_case_id text NOT NULL,
    primary_setup_reason_code text NOT NULL,
    setup_reason_codes jsonb NOT NULL,

    real_core_account_created_flag boolean NOT NULL,
    real_payment_change_executed_flag boolean NOT NULL,
    bank_account_data_present_flag boolean NOT NULL,
    ach_or_network_transmission_flag boolean NOT NULL,
    external_notice_generated_flag boolean NOT NULL,
    merchant_contact_executed_flag boolean NOT NULL,
    write_off_posted_flag boolean NOT NULL,
    collection_or_legal_executed_flag boolean NOT NULL,
    production_adverse_action_flag boolean NOT NULL,

    source_contract_row_hash text NOT NULL,
    source_snapshot_row_hash text NOT NULL,
    policy_configuration_hash text NOT NULL,
    row_hash text
)
ON COMMIT DROP;

INSERT INTO _m2_7_activation_expected
(
    module1_run_id,scenario_id,scenario_code,merchant_application_id,
    merchant_id,synthetic_account_id,synthetic_advance_id,
    source_strategy_outcome_code,source_servicing_action_code,
    source_recommended_action_exposure_amount,
    operational_setup_outcome_code,operational_setup_action_code,
    operational_setup_priority_rank,operational_setup_queue_code,
    setup_authorized_flag,blueprint_created_flag,
    setup_review_required_flag,no_setup_required_flag,
    synthetic_operational_case_id,primary_setup_reason_code,
    setup_reason_codes,
    real_core_account_created_flag,real_payment_change_executed_flag,
    bank_account_data_present_flag,ach_or_network_transmission_flag,
    external_notice_generated_flag,merchant_contact_executed_flag,
    write_off_posted_flag,collection_or_legal_executed_flag,
    production_adverse_action_flag,source_contract_row_hash,
    source_snapshot_row_hash,policy_configuration_hash,row_hash
)
SELECT
    mapping.module1_run_id,mapping.scenario_id,mapping.scenario_code,
    mapping.merchant_application_id,mapping.merchant_id,
    mapping.synthetic_account_id,mapping.synthetic_advance_id,
    mapping.source_strategy_outcome_code,mapping.source_servicing_action_code,
    mapping.source_recommended_action_exposure_amount,
    mapping.operational_setup_outcome_code,
    mapping.operational_setup_action_code,
    mapping.operational_setup_priority_rank,
    mapping.operational_setup_queue_code,
    mapping.setup_authorized_flag,mapping.blueprint_created_flag,
    mapping.setup_review_required_flag,mapping.no_setup_required_flag,

    'MSBF_OPS_CASE_'||
    upper
    (
        substr
        (
            md5
            (
                mapping.module1_run_id::text||'|'||
                mapping.scenario_id::text||'|'||
                mapping.merchant_application_id||'|M2_7_CASE'
            ),
            1,20
        )
    ),

    mapping.primary_setup_reason_code,mapping.setup_reason_codes,
    FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,
    mapping.source_contract_row_hash,mapping.row_hash,
    ctx.configuration_hash,NULL::text
FROM _m2_7_mapping AS mapping
CROSS JOIN _m2_7_ctx AS ctx;

UPDATE _m2_7_activation_expected AS activation
SET row_hash=msbf_ctl.m2_7_hash_jsonb(to_jsonb(activation)-'row_hash')
WHERE activation.row_hash IS NULL;

CREATE UNIQUE INDEX
ON _m2_7_activation_expected
(module1_run_id,scenario_id,merchant_application_id);

ANALYZE _m2_7_activation_expected;

INSERT INTO msbf_m2.application_operational_activation_snapshot
(
    module1_run_id,scenario_id,scenario_code,merchant_application_id,
    merchant_id,synthetic_account_id,synthetic_advance_id,
    source_strategy_outcome_code,source_servicing_action_code,
    source_recommended_action_exposure_amount,
    operational_setup_outcome_code,operational_setup_action_code,
    operational_setup_priority_rank,operational_setup_queue_code,
    setup_authorized_flag,blueprint_created_flag,
    setup_review_required_flag,no_setup_required_flag,
    synthetic_operational_case_id,primary_setup_reason_code,
    setup_reason_codes,real_core_account_created_flag,
    real_payment_change_executed_flag,bank_account_data_present_flag,
    ach_or_network_transmission_flag,external_notice_generated_flag,
    merchant_contact_executed_flag,write_off_posted_flag,
    collection_or_legal_executed_flag,production_adverse_action_flag,
    source_contract_row_hash,source_snapshot_row_hash,
    policy_configuration_hash,row_hash
)
SELECT
    module1_run_id,scenario_id,scenario_code,merchant_application_id,
    merchant_id,synthetic_account_id,synthetic_advance_id,
    source_strategy_outcome_code,source_servicing_action_code,
    source_recommended_action_exposure_amount,
    operational_setup_outcome_code,operational_setup_action_code,
    operational_setup_priority_rank,operational_setup_queue_code,
    setup_authorized_flag,blueprint_created_flag,
    setup_review_required_flag,no_setup_required_flag,
    synthetic_operational_case_id,primary_setup_reason_code,
    setup_reason_codes,real_core_account_created_flag,
    real_payment_change_executed_flag,bank_account_data_present_flag,
    ach_or_network_transmission_flag,external_notice_generated_flag,
    merchant_contact_executed_flag,write_off_posted_flag,
    collection_or_legal_executed_flag,production_adverse_action_flag,
    source_contract_row_hash,source_snapshot_row_hash,
    policy_configuration_hash,row_hash
FROM _m2_7_activation_expected;

/* Section 6 — Synthetic account-setup blueprints. */

DROP TABLE IF EXISTS _m2_7_setup_expected;

CREATE TEMP TABLE _m2_7_setup_expected
(
    module1_run_id bigint NOT NULL,
    scenario_id bigint NOT NULL,
    scenario_code text NOT NULL,
    merchant_application_id text NOT NULL,
    synthetic_account_id text NOT NULL,
    synthetic_advance_id text NOT NULL,

    operational_setup_outcome_code text NOT NULL,
    operational_setup_action_code text NOT NULL,
    account_setup_status_code text NOT NULL,
    operational_setup_queue_code text NOT NULL,

    synthetic_account_setup_id text NOT NULL,
    synthetic_servicing_plan_id text,
    operational_activation_date date,
    next_reassessment_date date,

    applied_temporary_payment_factor numeric(9,6),
    applied_setup_duration_days integer,
    applied_reassessment_interval_days integer,
    setup_parameter_payload jsonb NOT NULL,

    real_core_account_created_flag boolean NOT NULL,
    real_payment_change_executed_flag boolean NOT NULL,
    bank_account_data_present_flag boolean NOT NULL,
    ach_or_network_transmission_flag boolean NOT NULL,
    external_notice_generated_flag boolean NOT NULL,
    merchant_contact_executed_flag boolean NOT NULL,
    write_off_posted_flag boolean NOT NULL,
    collection_or_legal_executed_flag boolean NOT NULL,
    production_adverse_action_flag boolean NOT NULL,

    source_activation_row_hash text NOT NULL,
    row_hash text
)
ON COMMIT DROP;

INSERT INTO _m2_7_setup_expected
(
    module1_run_id,scenario_id,scenario_code,merchant_application_id,
    synthetic_account_id,synthetic_advance_id,
    operational_setup_outcome_code,operational_setup_action_code,
    account_setup_status_code,operational_setup_queue_code,
    synthetic_account_setup_id,synthetic_servicing_plan_id,
    operational_activation_date,next_reassessment_date,
    applied_temporary_payment_factor,applied_setup_duration_days,
    applied_reassessment_interval_days,setup_parameter_payload,
    real_core_account_created_flag,real_payment_change_executed_flag,
    bank_account_data_present_flag,ach_or_network_transmission_flag,
    external_notice_generated_flag,merchant_contact_executed_flag,
    write_off_posted_flag,collection_or_legal_executed_flag,
    production_adverse_action_flag,source_activation_row_hash,row_hash
)
SELECT
    activation.module1_run_id,activation.scenario_id,
    activation.scenario_code,activation.merchant_application_id,
    activation.synthetic_account_id,activation.synthetic_advance_id,
    activation.operational_setup_outcome_code,
    activation.operational_setup_action_code,

    CASE
        WHEN activation.setup_authorized_flag
        THEN 'SIMULATED_BLUEPRINT_READY'
        WHEN activation.setup_review_required_flag
        THEN 'OPERATIONAL_REVIEW_REQUIRED'
        ELSE 'NOT_REQUIRED'
    END,

    activation.operational_setup_queue_code,

    'MSBF_SETUP_'||
    upper
    (
        substr
        (
            md5
            (
                activation.module1_run_id::text||'|'||
                activation.scenario_id::text||'|'||
                activation.merchant_application_id||'|M2_7_SETUP'
            ),
            1,20
        )
    ),

    CASE
        WHEN activation.setup_authorized_flag
        THEN
            'MSBF_PLAN_'||
            upper
            (
                substr
                (
                    md5
                    (
                        activation.module1_run_id::text||'|'||
                        activation.scenario_id::text||'|'||
                        activation.merchant_application_id||'|M2_7_PLAN'
                    ),
                    1,20
                )
            )
    END,

    CASE
        WHEN activation.setup_authorized_flag
        THEN (ctx.as_of_date+ctx.activation_effective_lag_days)::date
    END,

    CASE
        WHEN activation.setup_authorized_flag
        THEN
            (
                ctx.as_of_date+ctx.activation_effective_lag_days+
                CASE
                    WHEN activation.operational_setup_outcome_code=
                         'TEMPORARY_PAYMENT_ADJUSTMENT_SETUP_READY'
                    THEN coalesce
                         (
                             source.source_reassessment_interval_days,
                             ctx.default_reassessment_interval_days
                         )
                    ELSE ctx.default_reassessment_interval_days
                END
            )::date
    END,

    CASE
        WHEN activation.operational_setup_outcome_code=
             'TEMPORARY_PAYMENT_ADJUSTMENT_SETUP_READY'
        THEN coalesce
             (
                 source.source_temporary_payment_factor,
                 ctx.default_temporary_payment_factor
             )
    END,

    CASE
        WHEN activation.operational_setup_outcome_code=
             'TEMPORARY_PAYMENT_ADJUSTMENT_SETUP_READY'
        THEN coalesce
             (
                 source.source_review_duration_days,
                 ctx.default_setup_duration_days
             )
    END,

    CASE
        WHEN activation.operational_setup_outcome_code=
             'TEMPORARY_PAYMENT_ADJUSTMENT_SETUP_READY'
        THEN coalesce
             (
                 source.source_reassessment_interval_days,
                 ctx.default_reassessment_interval_days
             )
    END,

    jsonb_build_object
    (
        'source_strategy_outcome_code',
            activation.source_strategy_outcome_code,
        'source_servicing_action_code',
            activation.source_servicing_action_code,
        'source_recommended_action_exposure_amount',
            activation.source_recommended_action_exposure_amount,
        'operational_setup_outcome_code',
            activation.operational_setup_outcome_code,
        'operational_setup_action_code',
            activation.operational_setup_action_code,
        'operational_setup_queue_code',
            activation.operational_setup_queue_code,
        'temporary_payment_factor',
            CASE
                WHEN activation.operational_setup_outcome_code=
                     'TEMPORARY_PAYMENT_ADJUSTMENT_SETUP_READY'
                THEN coalesce
                     (
                         source.source_temporary_payment_factor,
                         ctx.default_temporary_payment_factor
                     )
            END,
        'setup_duration_days',
            CASE
                WHEN activation.operational_setup_outcome_code=
                     'TEMPORARY_PAYMENT_ADJUSTMENT_SETUP_READY'
                THEN coalesce
                     (
                         source.source_review_duration_days,
                         ctx.default_setup_duration_days
                     )
            END,
        'synthetic_only',TRUE,
        'real_execution_prohibited',TRUE
    ),

    FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,
    activation.row_hash,NULL::text

FROM _m2_7_activation_expected AS activation
JOIN _m2_7_source_expected AS source
  ON source.module1_run_id=activation.module1_run_id
 AND source.scenario_id=activation.scenario_id
 AND source.merchant_application_id=activation.merchant_application_id
CROSS JOIN _m2_7_ctx AS ctx;

UPDATE _m2_7_setup_expected AS setup
SET row_hash=msbf_ctl.m2_7_hash_jsonb(to_jsonb(setup)-'row_hash')
WHERE setup.row_hash IS NULL;

CREATE UNIQUE INDEX
ON _m2_7_setup_expected
(module1_run_id,scenario_id,merchant_application_id);

ANALYZE _m2_7_setup_expected;

INSERT INTO msbf_m2.operational_account_setup_snapshot
(
    module1_run_id,scenario_id,scenario_code,merchant_application_id,
    synthetic_account_id,synthetic_advance_id,
    operational_setup_outcome_code,operational_setup_action_code,
    account_setup_status_code,operational_setup_queue_code,
    synthetic_account_setup_id,synthetic_servicing_plan_id,
    operational_activation_date,next_reassessment_date,
    applied_temporary_payment_factor,applied_setup_duration_days,
    applied_reassessment_interval_days,setup_parameter_payload,
    real_core_account_created_flag,real_payment_change_executed_flag,
    bank_account_data_present_flag,ach_or_network_transmission_flag,
    external_notice_generated_flag,merchant_contact_executed_flag,
    write_off_posted_flag,collection_or_legal_executed_flag,
    production_adverse_action_flag,source_activation_row_hash,row_hash
)
SELECT
    module1_run_id,scenario_id,scenario_code,merchant_application_id,
    synthetic_account_id,synthetic_advance_id,
    operational_setup_outcome_code,operational_setup_action_code,
    account_setup_status_code,operational_setup_queue_code,
    synthetic_account_setup_id,synthetic_servicing_plan_id,
    operational_activation_date,next_reassessment_date,
    applied_temporary_payment_factor,applied_setup_duration_days,
    applied_reassessment_interval_days,setup_parameter_payload,
    real_core_account_created_flag,real_payment_change_executed_flag,
    bank_account_data_present_flag,ach_or_network_transmission_flag,
    external_notice_generated_flag,merchant_contact_executed_flag,
    write_off_posted_flag,collection_or_legal_executed_flag,
    production_adverse_action_flag,source_activation_row_hash,row_hash
FROM _m2_7_setup_expected;

/* Section 7 — Scenario summary. */

DROP TABLE IF EXISTS _m2_7_portfolio_expected;

CREATE TEMP TABLE _m2_7_portfolio_expected
(
    module1_run_id bigint NOT NULL,
    scenario_code text NOT NULL,
    source_rows bigint NOT NULL,
    setup_ready_rows bigint NOT NULL,
    review_required_rows bigint NOT NULL,
    no_setup_required_rows bigint NOT NULL,
    standard_setup_rows bigint NOT NULL,
    temporary_adjustment_setup_rows bigint NOT NULL,
    restructure_setup_rows bigint NOT NULL,
    recovery_setup_rows bigint NOT NULL,
    charge_off_setup_rows bigint NOT NULL,
    setup_authorized_amount numeric(24,2) NOT NULL,
    review_required_amount numeric(24,2) NOT NULL,
    maximum_setup_priority_rank integer NOT NULL,
    row_hash text
)
ON COMMIT DROP;

INSERT INTO _m2_7_portfolio_expected
(
    module1_run_id,scenario_code,source_rows,setup_ready_rows,
    review_required_rows,no_setup_required_rows,standard_setup_rows,
    temporary_adjustment_setup_rows,restructure_setup_rows,
    recovery_setup_rows,charge_off_setup_rows,setup_authorized_amount,
    review_required_amount,maximum_setup_priority_rank,row_hash
)
SELECT
    module1_run_id,scenario_code,count(*)::bigint,
    count(*) FILTER(WHERE setup_authorized_flag)::bigint,
    count(*) FILTER(WHERE setup_review_required_flag)::bigint,
    count(*) FILTER(WHERE no_setup_required_flag)::bigint,
    count(*) FILTER
    (
        WHERE operational_setup_outcome_code=
              'STANDARD_SERVICING_SETUP_READY'
    )::bigint,
    count(*) FILTER
    (
        WHERE operational_setup_outcome_code=
              'TEMPORARY_PAYMENT_ADJUSTMENT_SETUP_READY'
    )::bigint,
    count(*) FILTER
    (
        WHERE operational_setup_outcome_code='RESTRUCTURE_SETUP_READY'
    )::bigint,
    count(*) FILTER
    (
        WHERE operational_setup_outcome_code=
              'CONTROLLED_RECOVERY_SETUP_READY'
    )::bigint,
    count(*) FILTER
    (
        WHERE operational_setup_outcome_code='CHARGE_OFF_SETUP_READY'
    )::bigint,
    round
    (
        sum
        (
            CASE WHEN setup_authorized_flag
                 THEN source_recommended_action_exposure_amount ELSE 0 END
        ),
        2
    ),
    round
    (
        sum
        (
            CASE WHEN setup_review_required_flag
                 THEN source_recommended_action_exposure_amount ELSE 0 END
        ),
        2
    ),
    max(operational_setup_priority_rank),
    NULL::text
FROM _m2_7_activation_expected
GROUP BY module1_run_id,scenario_code;

UPDATE _m2_7_portfolio_expected AS portfolio
SET row_hash=msbf_ctl.m2_7_hash_jsonb(to_jsonb(portfolio)-'row_hash')
WHERE portfolio.row_hash IS NULL;

INSERT INTO msbf_m2.operational_activation_portfolio_summary
(
    module1_run_id,scenario_code,source_rows,setup_ready_rows,
    review_required_rows,no_setup_required_rows,standard_setup_rows,
    temporary_adjustment_setup_rows,restructure_setup_rows,
    recovery_setup_rows,charge_off_setup_rows,setup_authorized_amount,
    review_required_amount,maximum_setup_priority_rank,row_hash
)
SELECT
    module1_run_id,scenario_code,source_rows,setup_ready_rows,
    review_required_rows,no_setup_required_rows,standard_setup_rows,
    temporary_adjustment_setup_rows,restructure_setup_rows,
    recovery_setup_rows,charge_off_setup_rows,setup_authorized_amount,
    review_required_amount,maximum_setup_priority_rank,row_hash
FROM _m2_7_portfolio_expected;

/* Section 8 — Latest and immutable archive contracts. */

DROP TABLE IF EXISTS _m2_7_latest_expected;

CREATE TEMP TABLE _m2_7_latest_expected
(
    LIKE msbf_m2.application_operational_activation_latest
    EXCLUDING DEFAULTS
    EXCLUDING CONSTRAINTS
);

ALTER TABLE _m2_7_latest_expected DROP COLUMN created_at;

/*
PostgreSQL LIKE copies NOT NULL attributes independently of CHECK constraints.
The staging hash must remain nullable only until the target-typed row hash is
calculated below.
*/
ALTER TABLE _m2_7_latest_expected
    ALTER COLUMN contract_row_hash DROP NOT NULL;

INSERT INTO _m2_7_latest_expected
(
    module1_run_id,contract_code,contract_version,schema_version,
    methodology_version,scenario_id,scenario_code,
    merchant_application_id,merchant_id,synthetic_account_id,
    synthetic_advance_id,source_strategy_outcome_code,
    source_servicing_action_code,
    source_recommended_action_exposure_amount,
    operational_setup_outcome_code,operational_setup_action_code,
    operational_setup_priority_rank,operational_setup_queue_code,
    account_setup_status_code,setup_authorized_flag,
    blueprint_created_flag,setup_review_required_flag,
    no_setup_required_flag,synthetic_operational_case_id,
    synthetic_account_setup_id,synthetic_servicing_plan_id,
    operational_activation_date,next_reassessment_date,
    applied_temporary_payment_factor,applied_setup_duration_days,
    applied_reassessment_interval_days,primary_setup_reason_code,
    setup_reason_codes,setup_parameter_payload,
    source_contract_row_hash,source_snapshot_row_hash,
    activation_snapshot_row_hash,account_setup_snapshot_row_hash,
    policy_configuration_hash,contract_row_hash
)
SELECT
    activation.module1_run_id,'M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION',1,'M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_SCHEMA_V1','M2_7_METHOD_V1',
    activation.scenario_id,activation.scenario_code,
    activation.merchant_application_id,activation.merchant_id,
    activation.synthetic_account_id,activation.synthetic_advance_id,
    activation.source_strategy_outcome_code,
    activation.source_servicing_action_code,
    activation.source_recommended_action_exposure_amount,
    activation.operational_setup_outcome_code,
    activation.operational_setup_action_code,
    activation.operational_setup_priority_rank,
    activation.operational_setup_queue_code,
    setup.account_setup_status_code,
    activation.setup_authorized_flag,activation.blueprint_created_flag,
    activation.setup_review_required_flag,activation.no_setup_required_flag,
    activation.synthetic_operational_case_id,
    setup.synthetic_account_setup_id,setup.synthetic_servicing_plan_id,
    setup.operational_activation_date,setup.next_reassessment_date,
    setup.applied_temporary_payment_factor,
    setup.applied_setup_duration_days,
    setup.applied_reassessment_interval_days,
    activation.primary_setup_reason_code,activation.setup_reason_codes,
    setup.setup_parameter_payload,activation.source_contract_row_hash,
    activation.source_snapshot_row_hash,activation.row_hash,setup.row_hash,
    activation.policy_configuration_hash,NULL::text
FROM _m2_7_activation_expected AS activation
JOIN _m2_7_setup_expected AS setup
  ON setup.module1_run_id=activation.module1_run_id
 AND setup.scenario_id=activation.scenario_id
 AND setup.merchant_application_id=activation.merchant_application_id;

UPDATE _m2_7_latest_expected AS latest
SET contract_row_hash=
    msbf_ctl.m2_7_hash_jsonb(to_jsonb(latest)-'contract_row_hash')
WHERE latest.contract_row_hash IS NULL;

DO $m2_7_latest_staging_hash_guard$
DECLARE
    v_null_hash_rows bigint;
    v_invalid_hash_rows bigint;
BEGIN
    SELECT
        count(*) FILTER
        (
            WHERE latest.contract_row_hash IS NULL
        ),
        count(*) FILTER
        (
            WHERE latest.contract_row_hash IS NOT NULL
              AND
              (
                  length(latest.contract_row_hash)<>32
                  OR latest.contract_row_hash !~ '^[0-9a-f]+$'
              )
        )
    INTO
        v_null_hash_rows,
        v_invalid_hash_rows
    FROM _m2_7_latest_expected AS latest;

    IF v_null_hash_rows<>0 OR v_invalid_hash_rows<>0 THEN
        RAISE EXCEPTION
            'M2.7 latest staging hash population failed: null %, invalid %.',
            v_null_hash_rows,
            v_invalid_hash_rows;
    END IF;
END;
$m2_7_latest_staging_hash_guard$;

ALTER TABLE _m2_7_latest_expected
    ALTER COLUMN contract_row_hash SET NOT NULL;

INSERT INTO msbf_m2.application_operational_activation_latest
(
    module1_run_id,contract_code,contract_version,schema_version,
    methodology_version,scenario_id,scenario_code,
    merchant_application_id,merchant_id,synthetic_account_id,
    synthetic_advance_id,source_strategy_outcome_code,
    source_servicing_action_code,
    source_recommended_action_exposure_amount,
    operational_setup_outcome_code,operational_setup_action_code,
    operational_setup_priority_rank,operational_setup_queue_code,
    account_setup_status_code,setup_authorized_flag,
    blueprint_created_flag,setup_review_required_flag,
    no_setup_required_flag,synthetic_operational_case_id,
    synthetic_account_setup_id,synthetic_servicing_plan_id,
    operational_activation_date,next_reassessment_date,
    applied_temporary_payment_factor,applied_setup_duration_days,
    applied_reassessment_interval_days,primary_setup_reason_code,
    setup_reason_codes,setup_parameter_payload,
    source_contract_row_hash,source_snapshot_row_hash,
    activation_snapshot_row_hash,account_setup_snapshot_row_hash,
    policy_configuration_hash,contract_row_hash
)
SELECT
    latest.module1_run_id,
    latest.contract_code,
    latest.contract_version,
    latest.schema_version,
    latest.methodology_version,
    latest.scenario_id,
    latest.scenario_code,
    latest.merchant_application_id,
    latest.merchant_id,
    latest.synthetic_account_id,
    latest.synthetic_advance_id,
    latest.source_strategy_outcome_code,
    latest.source_servicing_action_code,
    latest.source_recommended_action_exposure_amount,
    latest.operational_setup_outcome_code,
    latest.operational_setup_action_code,
    latest.operational_setup_priority_rank,
    latest.operational_setup_queue_code,
    latest.account_setup_status_code,
    latest.setup_authorized_flag,
    latest.blueprint_created_flag,
    latest.setup_review_required_flag,
    latest.no_setup_required_flag,
    latest.synthetic_operational_case_id,
    latest.synthetic_account_setup_id,
    latest.synthetic_servicing_plan_id,
    latest.operational_activation_date,
    latest.next_reassessment_date,
    latest.applied_temporary_payment_factor,
    latest.applied_setup_duration_days,
    latest.applied_reassessment_interval_days,
    latest.primary_setup_reason_code,
    latest.setup_reason_codes,
    latest.setup_parameter_payload,
    latest.source_contract_row_hash,
    latest.source_snapshot_row_hash,
    latest.activation_snapshot_row_hash,
    latest.account_setup_snapshot_row_hash,
    latest.policy_configuration_hash,
    latest.contract_row_hash
FROM _m2_7_latest_expected AS latest;

DROP TABLE IF EXISTS _m2_7_archive_expected;

CREATE TEMP TABLE _m2_7_archive_expected
ON COMMIT DROP
AS
SELECT
    latest.*,
    to_jsonb(latest) AS contract_payload,
    NULL::text AS archive_row_hash
FROM _m2_7_latest_expected AS latest;

UPDATE _m2_7_archive_expected AS archive
SET archive_row_hash=
    msbf_ctl.m2_7_hash_jsonb(to_jsonb(archive)-'archive_row_hash')
WHERE archive.archive_row_hash IS NULL;

INSERT INTO msbf_m2.application_operational_activation_archive
(
    module1_run_id,contract_code,contract_version,schema_version,
    methodology_version,scenario_id,scenario_code,
    merchant_application_id,merchant_id,synthetic_account_id,
    synthetic_advance_id,source_strategy_outcome_code,
    source_servicing_action_code,
    source_recommended_action_exposure_amount,
    operational_setup_outcome_code,operational_setup_action_code,
    operational_setup_priority_rank,operational_setup_queue_code,
    account_setup_status_code,setup_authorized_flag,
    blueprint_created_flag,setup_review_required_flag,
    no_setup_required_flag,synthetic_operational_case_id,
    synthetic_account_setup_id,synthetic_servicing_plan_id,
    operational_activation_date,next_reassessment_date,
    applied_temporary_payment_factor,applied_setup_duration_days,
    applied_reassessment_interval_days,primary_setup_reason_code,
    setup_reason_codes,setup_parameter_payload,
    source_contract_row_hash,source_snapshot_row_hash,
    activation_snapshot_row_hash,account_setup_snapshot_row_hash,
    policy_configuration_hash,contract_row_hash,
    contract_payload,archive_row_hash
)
SELECT
    archive.module1_run_id,
    archive.contract_code,
    archive.contract_version,
    archive.schema_version,
    archive.methodology_version,
    archive.scenario_id,
    archive.scenario_code,
    archive.merchant_application_id,
    archive.merchant_id,
    archive.synthetic_account_id,
    archive.synthetic_advance_id,
    archive.source_strategy_outcome_code,
    archive.source_servicing_action_code,
    archive.source_recommended_action_exposure_amount,
    archive.operational_setup_outcome_code,
    archive.operational_setup_action_code,
    archive.operational_setup_priority_rank,
    archive.operational_setup_queue_code,
    archive.account_setup_status_code,
    archive.setup_authorized_flag,
    archive.blueprint_created_flag,
    archive.setup_review_required_flag,
    archive.no_setup_required_flag,
    archive.synthetic_operational_case_id,
    archive.synthetic_account_setup_id,
    archive.synthetic_servicing_plan_id,
    archive.operational_activation_date,
    archive.next_reassessment_date,
    archive.applied_temporary_payment_factor,
    archive.applied_setup_duration_days,
    archive.applied_reassessment_interval_days,
    archive.primary_setup_reason_code,
    archive.setup_reason_codes,
    archive.setup_parameter_payload,
    archive.source_contract_row_hash,
    archive.source_snapshot_row_hash,
    archive.activation_snapshot_row_hash,
    archive.account_setup_snapshot_row_hash,
    archive.policy_configuration_hash,
    archive.contract_row_hash,
    archive.contract_payload,
    archive.archive_row_hash
FROM _m2_7_archive_expected AS archive;

ANALYZE msbf_m2.operational_activation_source_snapshot;
ANALYZE msbf_m2.application_operational_activation_snapshot;
ANALYZE msbf_m2.operational_account_setup_snapshot;
ANALYZE msbf_m2.operational_activation_portfolio_summary;
ANALYZE msbf_m2.application_operational_activation_latest;
ANALYZE msbf_m2.application_operational_activation_archive;

/* Section 9 — Set hashes and registry. */

DROP TABLE IF EXISTS _m2_7_hashes;

CREATE TEMP TABLE _m2_7_hashes
ON COMMIT DROP
AS
SELECT
    (
        SELECT md5(string_agg(row_hash,'|' ORDER BY module1_run_id))
        FROM msbf_ctl.m2_7_policy_profile
        WHERE module1_run_id=(SELECT run_id FROM _m2_7_ctx)
    ) AS policy_set_hash,
    (
        SELECT md5(string_agg(row_hash,'|' ORDER BY operational_setup_outcome_rank,operational_setup_outcome_code))
        FROM msbf_m2.operational_setup_outcome_definition
        WHERE module1_run_id=(SELECT run_id FROM _m2_7_ctx)
    ) AS outcome_set_hash,
    (
        SELECT md5(string_agg(row_hash,'|' ORDER BY operational_setup_action_rank,operational_setup_action_code))
        FROM msbf_m2.operational_setup_action_definition
        WHERE module1_run_id=(SELECT run_id FROM _m2_7_ctx)
    ) AS action_set_hash,
    (
        SELECT md5(string_agg(row_hash,'|' ORDER BY operational_setup_reason_code))
        FROM msbf_m2.operational_setup_reason_definition
        WHERE module1_run_id=(SELECT run_id FROM _m2_7_ctx)
    ) AS reason_set_hash,
    (
        SELECT md5(string_agg(scenario_id::text||'|'||merchant_application_id||'|'||row_hash,'|' ORDER BY scenario_id,merchant_application_id))
        FROM _m2_7_source_expected
    ) AS source_set_hash,
    (
        SELECT md5(string_agg(scenario_id::text||'|'||merchant_application_id||'|'||row_hash,'|' ORDER BY scenario_id,merchant_application_id))
        FROM _m2_7_activation_expected
    ) AS activation_set_hash,
    (
        SELECT md5(string_agg(scenario_id::text||'|'||merchant_application_id||'|'||row_hash,'|' ORDER BY scenario_id,merchant_application_id))
        FROM _m2_7_setup_expected
    ) AS account_setup_set_hash,
    (
        SELECT md5(string_agg(scenario_code||'|'||row_hash,'|' ORDER BY scenario_code))
        FROM _m2_7_portfolio_expected
    ) AS portfolio_summary_set_hash,
    (
        SELECT md5(string_agg(scenario_id::text||'|'||merchant_application_id||'|'||contract_row_hash,'|' ORDER BY scenario_id,merchant_application_id))
        FROM _m2_7_latest_expected
    ) AS latest_set_hash,
    (
        SELECT md5(string_agg(scenario_id::text||'|'||merchant_application_id||'|'||archive_row_hash,'|' ORDER BY scenario_id,merchant_application_id))
        FROM _m2_7_archive_expected
    ) AS archive_set_hash;

DROP TABLE IF EXISTS _m2_7_registry_expected;

CREATE TEMP TABLE _m2_7_registry_expected
ON COMMIT DROP
AS
SELECT
    ctx.run_id AS module1_run_id,
    'M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION'::text AS contract_code,
    1::integer AS contract_version,
    'M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_SCHEMA_V1'::text AS schema_version,
    'M2_7_METHOD_V1'::text AS methodology_version,
    'M2_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_CONSUMPTION'::text AS source_contract_code,
    1::integer AS source_contract_version,
    'M2_6_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_SCHEMA_V1'::text AS source_schema_version,
    'M2_6_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY'::text AS source_acceptance_gate_id,
    '868125bff29270490cab4d2e55cb1388'::text AS source_combined_set_hash,
    ctx.configuration_hash AS policy_configuration_hash,

    1::bigint AS policy_rows,
    7::bigint AS outcome_rows,
    7::bigint AS action_rows,
    28::bigint AS reason_rows,
    59::bigint AS source_rows,
    59::bigint AS activation_rows,
    59::bigint AS account_setup_rows,
    2::bigint AS portfolio_summary_rows,
    59::bigint AS latest_rows,
    59::bigint AS archive_rows,
    (
        SELECT count(*) FROM msbf_m2.v_m2_7_matched_scenario_comparison
        WHERE module1_run_id=ctx.run_id
    )::bigint AS comparison_rows,
    1::bigint AS registry_rows,
    341::bigint AS canonical_entities,

    (
        SELECT count(*) FROM _m2_7_activation_expected
        WHERE no_setup_required_flag
    )::bigint AS no_setup_required_rows,
    (
        SELECT count(*) FROM _m2_7_activation_expected
        WHERE operational_setup_outcome_code=
              'STANDARD_SERVICING_SETUP_READY'
    )::bigint AS standard_setup_rows,
    (
        SELECT count(*) FROM _m2_7_activation_expected
        WHERE operational_setup_outcome_code=
              'TEMPORARY_PAYMENT_ADJUSTMENT_SETUP_READY'
    )::bigint AS temporary_adjustment_setup_rows,
    (
        SELECT count(*) FROM _m2_7_activation_expected
        WHERE operational_setup_outcome_code='RESTRUCTURE_SETUP_READY'
    )::bigint AS restructure_setup_rows,
    (
        SELECT count(*) FROM _m2_7_activation_expected
        WHERE operational_setup_outcome_code=
              'CONTROLLED_RECOVERY_SETUP_READY'
    )::bigint AS recovery_setup_rows,
    (
        SELECT count(*) FROM _m2_7_activation_expected
        WHERE operational_setup_outcome_code='CHARGE_OFF_SETUP_READY'
    )::bigint AS charge_off_setup_rows,
    (
        SELECT count(*) FROM _m2_7_activation_expected
        WHERE setup_review_required_flag
    )::bigint AS review_required_rows,
    (
        SELECT count(*) FROM _m2_7_activation_expected
        WHERE setup_authorized_flag
    )::bigint AS setup_authorized_rows,
    (
        SELECT round
        (
            sum
            (
                CASE WHEN setup_authorized_flag
                     THEN source_recommended_action_exposure_amount ELSE 0 END
            ),
            2
        )
        FROM _m2_7_activation_expected
    )::numeric(24,2) AS setup_authorized_amount,
    (
        SELECT round
        (
            sum
            (
                CASE WHEN setup_review_required_flag
                     THEN source_recommended_action_exposure_amount ELSE 0 END
            ),
            2
        )
        FROM _m2_7_activation_expected
    )::numeric(24,2) AS review_required_amount,

    hashes.policy_set_hash,hashes.outcome_set_hash,hashes.action_set_hash,
    hashes.reason_set_hash,hashes.source_set_hash,hashes.activation_set_hash,
    hashes.account_setup_set_hash,hashes.portfolio_summary_set_hash,
    hashes.latest_set_hash,hashes.archive_set_hash,
    NULL::text AS contract_set_hash,
    NULL::text AS combined_set_hash,
    'GENERATED'::text AS contract_status,
    clock_timestamp() AS generated_at,
    NULL::timestamptz AS validated_at,
    NULL::timestamptz AS accepted_at,
    NULL::text AS row_hash
FROM _m2_7_ctx AS ctx
CROSS JOIN _m2_7_hashes AS hashes;

UPDATE _m2_7_registry_expected AS registry
SET row_hash=msbf_ctl.m2_7_registry_row_hash(to_jsonb(registry))
WHERE registry.row_hash IS NULL;

UPDATE _m2_7_registry_expected AS registry
SET contract_set_hash=md5(registry.row_hash)
WHERE registry.contract_set_hash IS NULL;

/* Section 10 — Canonical expected universe and combined hash. */

DROP TABLE IF EXISTS _m2_7_canonical_expected;

CREATE TEMP TABLE _m2_7_canonical_expected
(
    entity_type text NOT NULL,
    entity_key text NOT NULL,
    row_hash text NOT NULL,
    PRIMARY KEY(entity_type,entity_key)
)
ON COMMIT DROP;

INSERT INTO _m2_7_canonical_expected
SELECT 'POLICY',policy_code||'|v'||policy_version::text,row_hash
FROM msbf_ctl.m2_7_policy_profile
WHERE module1_run_id=(SELECT run_id FROM _m2_7_ctx)
UNION ALL
SELECT 'OUTCOME_DEFINITION',operational_setup_outcome_code,row_hash
FROM msbf_m2.operational_setup_outcome_definition
WHERE module1_run_id=(SELECT run_id FROM _m2_7_ctx)
UNION ALL
SELECT 'ACTION_DEFINITION',operational_setup_action_code,row_hash
FROM msbf_m2.operational_setup_action_definition
WHERE module1_run_id=(SELECT run_id FROM _m2_7_ctx)
UNION ALL
SELECT 'REASON_DEFINITION',operational_setup_reason_code,row_hash
FROM msbf_m2.operational_setup_reason_definition
WHERE module1_run_id=(SELECT run_id FROM _m2_7_ctx)
UNION ALL
SELECT 'SOURCE',scenario_id::text||'|'||merchant_application_id,row_hash
FROM _m2_7_source_expected
UNION ALL
SELECT 'ACTIVATION',scenario_id::text||'|'||merchant_application_id,row_hash
FROM _m2_7_activation_expected
UNION ALL
SELECT 'ACCOUNT_SETUP',scenario_id::text||'|'||merchant_application_id,row_hash
FROM _m2_7_setup_expected
UNION ALL
SELECT 'PORTFOLIO_SUMMARY',scenario_code,row_hash
FROM _m2_7_portfolio_expected
UNION ALL
SELECT 'LATEST',scenario_id::text||'|'||merchant_application_id,contract_row_hash
FROM _m2_7_latest_expected
UNION ALL
SELECT 'ARCHIVE',scenario_id::text||'|'||merchant_application_id,archive_row_hash
FROM _m2_7_archive_expected
UNION ALL
SELECT 'REGISTRY',contract_code||'|v'||contract_version::text,row_hash
FROM _m2_7_registry_expected;

UPDATE _m2_7_registry_expected AS registry
SET combined_set_hash=
(
    SELECT md5
    (
        string_agg
        (
            entity_type||'|'||entity_key||'|'||row_hash,
            '|' ORDER BY entity_type,entity_key
        )
    )
    FROM _m2_7_canonical_expected
)
WHERE registry.combined_set_hash IS NULL;

INSERT INTO msbf_ctl.m2_7_operational_activation_contract_registry
(
    module1_run_id,contract_code,contract_version,schema_version,
    methodology_version,source_contract_code,source_contract_version,
    source_schema_version,source_acceptance_gate_id,
    source_combined_set_hash,policy_configuration_hash,
    policy_rows,outcome_rows,action_rows,reason_rows,source_rows,
    activation_rows,account_setup_rows,portfolio_summary_rows,
    latest_rows,archive_rows,comparison_rows,registry_rows,
    canonical_entities,no_setup_required_rows,standard_setup_rows,
    temporary_adjustment_setup_rows,restructure_setup_rows,
    recovery_setup_rows,charge_off_setup_rows,review_required_rows,
    setup_authorized_rows,setup_authorized_amount,review_required_amount,
    policy_set_hash,outcome_set_hash,action_set_hash,reason_set_hash,
    source_set_hash,activation_set_hash,account_setup_set_hash,
    portfolio_summary_set_hash,latest_set_hash,archive_set_hash,
    contract_set_hash,combined_set_hash,contract_status,generated_at,
    validated_at,accepted_at,row_hash
)
SELECT
    registry.module1_run_id,
    registry.contract_code,
    registry.contract_version,
    registry.schema_version,
    registry.methodology_version,
    registry.source_contract_code,
    registry.source_contract_version,
    registry.source_schema_version,
    registry.source_acceptance_gate_id,
    registry.source_combined_set_hash,
    registry.policy_configuration_hash,
    registry.policy_rows,
    registry.outcome_rows,
    registry.action_rows,
    registry.reason_rows,
    registry.source_rows,
    registry.activation_rows,
    registry.account_setup_rows,
    registry.portfolio_summary_rows,
    registry.latest_rows,
    registry.archive_rows,
    registry.comparison_rows,
    registry.registry_rows,
    registry.canonical_entities,
    registry.no_setup_required_rows,
    registry.standard_setup_rows,
    registry.temporary_adjustment_setup_rows,
    registry.restructure_setup_rows,
    registry.recovery_setup_rows,
    registry.charge_off_setup_rows,
    registry.review_required_rows,
    registry.setup_authorized_rows,
    registry.setup_authorized_amount,
    registry.review_required_amount,
    registry.policy_set_hash,
    registry.outcome_set_hash,
    registry.action_set_hash,
    registry.reason_set_hash,
    registry.source_set_hash,
    registry.activation_set_hash,
    registry.account_setup_set_hash,
    registry.portfolio_summary_set_hash,
    registry.latest_set_hash,
    registry.archive_set_hash,
    registry.contract_set_hash,
    registry.combined_set_hash,
    registry.contract_status,
    registry.generated_at,
    registry.validated_at,
    registry.accepted_at,
    registry.row_hash
FROM _m2_7_registry_expected AS registry;

/* Section 11 — Physical reconstruction, reconciliation, and evidence. */

DROP TABLE IF EXISTS _m2_7_mismatch;

CREATE TEMP TABLE _m2_7_mismatch
ON COMMIT DROP
AS
SELECT
    coalesce(expected.entity_type,actual.entity_type) AS entity_type,
    coalesce(expected.entity_key,actual.entity_key) AS entity_key,
    expected.row_hash AS expected_row_hash,
    actual.row_hash AS actual_row_hash
FROM _m2_7_canonical_expected AS expected
FULL OUTER JOIN
(
    SELECT entity_type,entity_key,row_hash
    FROM msbf_m2.v_m2_7_canonical_entity
    WHERE module1_run_id=(SELECT run_id FROM _m2_7_ctx)
) AS actual
  ON actual.entity_type=expected.entity_type
 AND actual.entity_key=expected.entity_key
WHERE expected.row_hash IS DISTINCT FROM actual.row_hash;

DROP TABLE IF EXISTS _m2_7_diagnostics;

CREATE TEMP TABLE _m2_7_diagnostics
ON COMMIT PRESERVE ROWS
AS
SELECT
    (SELECT count(*) FROM _m2_7_canonical_expected)::bigint
        AS expected_canonical_entities,
    (
        SELECT count(*) FROM msbf_m2.v_m2_7_canonical_entity
        WHERE module1_run_id=(SELECT run_id FROM _m2_7_ctx)
    )::bigint AS actual_canonical_entities,
    (SELECT count(*) FROM _m2_7_mismatch)::bigint
        AS row_level_mismatches,
    (
        SELECT count(*) FROM msbf_m2.v_m2_7_matched_scenario_comparison
        WHERE module1_run_id=(SELECT run_id FROM _m2_7_ctx)
    )::bigint AS comparison_rows,
    (
        SELECT count(*) FROM msbf_m2.v_m2_7_matched_scenario_comparison
        WHERE module1_run_id=(SELECT run_id FROM _m2_7_ctx)
          AND stress_setup_permission_improvement_flag
    )::bigint AS stress_setup_permission_improvements,
    (
        SELECT count(*) FROM msbf_m2.v_m2_7_matched_scenario_comparison
        WHERE module1_run_id=(SELECT run_id FROM _m2_7_ctx)
          AND stress_priority_improvement_flag
    )::bigint AS stress_priority_improvements;

DO $m2_7_generation_guard$
DECLARE
    v record;
BEGIN
    SELECT * INTO v FROM _m2_7_diagnostics;

    IF v.expected_canonical_entities<>341
       OR v.actual_canonical_entities<>341
       OR v.row_level_mismatches<>0
       OR v.comparison_rows<>15
       OR v.stress_setup_permission_improvements<>0
       OR v.stress_priority_improvements<>0
    THEN
        RAISE EXCEPTION
            'M2.7 generation reconciliation failed: %.',
            row_to_json(v);
    END IF;
END;
$m2_7_generation_guard$;

DROP TABLE IF EXISTS _m2_7_generation_evidence;

CREATE TEMP TABLE _m2_7_generation_evidence
(
    run_id bigint NOT NULL,
    evidence_code text NOT NULL,
    segment_key text NOT NULL,
    metric_name text NOT NULL,
    metric_value_numeric numeric(28,10),
    metric_value_text text,
    unit_code text NOT NULL,
    status text NOT NULL,
    interpretation text NOT NULL,

    CHECK(num_nonnulls(metric_value_numeric,metric_value_text)=1)
)
ON COMMIT DROP;

INSERT INTO _m2_7_generation_evidence
(
    run_id,evidence_code,segment_key,metric_name,
    metric_value_numeric,metric_value_text,unit_code,status,interpretation
)
SELECT
    registry.module1_run_id,evidence.evidence_code,'PORTFOLIO',
    evidence.metric_name,evidence.metric_value_numeric,
    evidence.metric_value_text,evidence.unit_code,'PASS',
    evidence.interpretation
FROM _m2_7_registry_expected AS registry
CROSS JOIN LATERAL
(
    VALUES
    ('M2_7_POLICY_SET_HASH','POLICY_SET_HASH',NULL::numeric(28,10),registry.policy_set_hash,'HASH','M2.7 policy set hash.'),
    ('M2_7_OUTCOME_SET_HASH','OUTCOME_SET_HASH',NULL::numeric(28,10),registry.outcome_set_hash,'HASH','Outcome-definition set hash.'),
    ('M2_7_ACTION_SET_HASH','ACTION_SET_HASH',NULL::numeric(28,10),registry.action_set_hash,'HASH','Action-definition set hash.'),
    ('M2_7_REASON_SET_HASH','REASON_SET_HASH',NULL::numeric(28,10),registry.reason_set_hash,'HASH','Reason-definition set hash.'),
    ('M2_7_SOURCE_SET_HASH','SOURCE_SET_HASH',NULL::numeric(28,10),registry.source_set_hash,'HASH','Accepted M2.6 source set hash.'),
    ('M2_7_ACTIVATION_SET_HASH','ACTIVATION_SET_HASH',NULL::numeric(28,10),registry.activation_set_hash,'HASH','Activation set hash.'),
    ('M2_7_ACCOUNT_SETUP_SET_HASH','ACCOUNT_SETUP_SET_HASH',NULL::numeric(28,10),registry.account_setup_set_hash,'HASH','Account setup set hash.'),
    ('M2_7_PORTFOLIO_SET_HASH','PORTFOLIO_SET_HASH',NULL::numeric(28,10),registry.portfolio_summary_set_hash,'HASH','Portfolio summary set hash.'),
    ('M2_7_LATEST_SET_HASH','LATEST_SET_HASH',NULL::numeric(28,10),registry.latest_set_hash,'HASH','Latest contract set hash.'),
    ('M2_7_ARCHIVE_SET_HASH','ARCHIVE_SET_HASH',NULL::numeric(28,10),registry.archive_set_hash,'HASH','Archive set hash.'),
    ('M2_7_CONTRACT_SET_HASH','CONTRACT_SET_HASH',NULL::numeric(28,10),registry.contract_set_hash,'HASH','Contract registry set hash.'),
    ('M2_7_COMBINED_SET_HASH','COMBINED_SET_HASH',NULL::numeric(28,10),registry.combined_set_hash,'HASH','Complete M2.7 canonical hash.'),

    ('M2_7_SOURCE_ROWS','SOURCE_ROWS',registry.source_rows::numeric(28,10),NULL::text,'ROWS','Accepted source rows.'),
    ('M2_7_ACTIVATION_ROWS','ACTIVATION_ROWS',registry.activation_rows::numeric(28,10),NULL::text,'ROWS','Activation rows.'),
    ('M2_7_SETUP_ROWS','SETUP_ROWS',registry.account_setup_rows::numeric(28,10),NULL::text,'ROWS','Account setup rows.'),
    ('M2_7_PORTFOLIO_ROWS','PORTFOLIO_ROWS',registry.portfolio_summary_rows::numeric(28,10),NULL::text,'ROWS','Portfolio summary rows.'),
    ('M2_7_LATEST_ROWS','LATEST_ROWS',registry.latest_rows::numeric(28,10),NULL::text,'ROWS','Latest rows.'),
    ('M2_7_ARCHIVE_ROWS','ARCHIVE_ROWS',registry.archive_rows::numeric(28,10),NULL::text,'ROWS','Archive rows.'),
    ('M2_7_COMPARISON_ROWS','COMPARISON_ROWS',registry.comparison_rows::numeric(28,10),NULL::text,'ROWS','Matched comparison rows.'),
    ('M2_7_CANONICAL_ENTITIES','CANONICAL_ENTITIES',registry.canonical_entities::numeric(28,10),NULL::text,'ROWS','Canonical entities.'),
    ('M2_7_NO_SETUP_ROWS','NO_SETUP_ROWS',registry.no_setup_required_rows::numeric(28,10),NULL::text,'ROWS','No-setup rows.'),
    ('M2_7_SETUP_AUTHORIZED_ROWS','SETUP_AUTHORIZED_ROWS',registry.setup_authorized_rows::numeric(28,10),NULL::text,'ROWS','Setup-authorized rows.'),
    ('M2_7_SETUP_AUTHORIZED_AMOUNT','SETUP_AUTHORIZED_AMOUNT',registry.setup_authorized_amount::numeric(28,10),NULL::text,'USD','Setup-authorized exposure.'),
    ('M2_7_REVIEW_REQUIRED_AMOUNT','REVIEW_REQUIRED_AMOUNT',registry.review_required_amount::numeric(28,10),NULL::text,'USD','Review-only exposure.')
) AS evidence
(
    evidence_code,metric_name,metric_value_numeric,
    metric_value_text,unit_code,interpretation
);

INSERT INTO msbf_ctl.run_evidence
(
    run_id,evidence_code,segment_key,metric_name,
    metric_value_numeric,metric_value_text,unit_code,status,interpretation
)
SELECT
    run_id,evidence_code,segment_key,metric_name,
    metric_value_numeric,metric_value_text,unit_code,status,interpretation
FROM _m2_7_generation_evidence;

/* Section 12 — Lifecycle and final checkpoint. */

UPDATE msbf_ctl.run_registry
SET
    run_status='M2_7_GENERATED',
    notes=coalesce(notes,'')||
        ' | M2.7 operational activation and account setup generated.'
WHERE run_id=(SELECT run_id FROM _m2_7_ctx);

INSERT INTO _m2_7_result
SELECT
    registry.module1_run_id,'M2_7_GENERATED',
    registry.policy_rows,registry.outcome_rows,registry.action_rows,
    registry.reason_rows,registry.source_rows,registry.activation_rows,
    registry.account_setup_rows,registry.portfolio_summary_rows,
    registry.latest_rows,registry.archive_rows,registry.comparison_rows,
    registry.registry_rows,registry.no_setup_required_rows,
    registry.standard_setup_rows,registry.temporary_adjustment_setup_rows,
    registry.restructure_setup_rows,registry.recovery_setup_rows,
    registry.charge_off_setup_rows,registry.review_required_rows,
    registry.setup_authorized_rows,registry.setup_authorized_amount,
    registry.review_required_amount,341,
    diagnostics.actual_canonical_entities,
    diagnostics.row_level_mismatches,
    diagnostics.stress_setup_permission_improvements,
    diagnostics.stress_priority_improvements,
    registry.policy_set_hash,registry.outcome_set_hash,
    registry.action_set_hash,registry.reason_set_hash,
    registry.source_set_hash,registry.activation_set_hash,
    registry.account_setup_set_hash,registry.portfolio_summary_set_hash,
    registry.latest_set_hash,registry.archive_set_hash,
    registry.contract_set_hash,registry.combined_set_hash,'PASS'
FROM msbf_ctl.m2_7_operational_activation_contract_registry AS registry
CROSS JOIN _m2_7_diagnostics AS diagnostics
WHERE registry.module1_run_id=(SELECT run_id FROM _m2_7_ctx);

COMMIT;

SELECT * FROM _m2_7_result;
