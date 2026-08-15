/* ============================================================================
Revision v0.2R2 correction
- Adds a selected-structure matched-scenario floor after candidate ranking.
- Handles route/template transitions where per-template floors cannot compare
  the selected baseline and stress structures.
- Floors the stress selected structure across all four governed dimensions:
  funding amount, remittance rate, payback multiple, and collection horizon.
- Recalculates all dependent candidate economics before target-typed hashing.
- Records the actual stress-floor application flag only on adjusted rows.
- Adds a pre/post floor diagnostic guard: 66 matched selected structures,
  9 pre-floor improvements, 9 adjusted rows, and 0 post-floor improvements.
- Does not change candidate templates, route logic, candidate count, contract
  grain, expected canonical entities, or final-decision boundaries.
============================================================================ */

/* ============================================================================
M2.2 Program 142 — Deterministic Pricing and Structure Generation v0.2R2
Materializes accepted sources once, uses window functions for ranking and
matched stress controls, persists generation separately from validation, and
commits only after complete 7,336-entity reconciliation.
============================================================================ */
BEGIN;
SET LOCAL work_mem='128MB'; SET LOCAL lock_timeout='10s'; SET LOCAL statement_timeout='45min'; SET LOCAL jit=off;
DROP TABLE IF EXISTS _m2_2_result;
CREATE TEMP TABLE _m2_2_result(module1_run_id bigint,run_status text,policy_rows bigint,template_rows bigint,reason_rows bigint,disposition_rows bigint,request_snapshot_rows bigint,request_latest_rows bigint,request_archive_rows bigint,candidate_rows bigint,pricing_snapshot_rows bigint,pricing_latest_rows bigint,pricing_archive_rows bigint,comparison_rows bigint,expected_canonical_entities bigint,actual_canonical_entities bigint,row_level_mismatches bigint,policy_set_hash text,template_set_hash text,reason_set_hash text,disposition_set_hash text,request_snapshot_set_hash text,request_latest_set_hash text,request_archive_set_hash text,candidate_set_hash text,pricing_snapshot_set_hash text,pricing_latest_set_hash text,pricing_archive_set_hash text,request_contract_set_hash text,pricing_contract_set_hash text,combined_set_hash text,generation_status text) ON COMMIT PRESERVE ROWS;
DROP TABLE IF EXISTS _m2_2_ctx;
CREATE TEMP TABLE _m2_2_ctx ON COMMIT DROP AS SELECT r.run_id,p.* FROM msbf_ctl.run_registry r CROSS JOIN msbf_ctl.m2_2_policy_profile p WHERE r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1 AND p.policy_code='M2_2_PRICING_STRUCTURE_POLICY_V1';
DO $ready$ BEGIN PERFORM msbf_ctl.m2_2_assert_generation_ready((SELECT run_id FROM _m2_2_ctx)); END; $ready$;

DROP TABLE IF EXISTS _m2_2_g2;
CREATE TEMP TABLE _m2_2_g2 ON COMMIT DROP AS SELECT * FROM msbf_m1.v_m1_17_g2_integrated_consumption WHERE module1_run_id=(SELECT run_id FROM _m2_2_ctx);
CREATE UNIQUE INDEX ON _m2_2_g2(scenario_id,merchant_application_id); ANALYZE _m2_2_g2;
DROP TABLE IF EXISTS _m2_2_route;
CREATE TEMP TABLE _m2_2_route ON COMMIT DROP AS SELECT * FROM msbf_m2.application_eligibility_routing_latest WHERE module1_run_id=(SELECT run_id FROM _m2_2_ctx);
CREATE UNIQUE INDEX ON _m2_2_route(scenario_id,merchant_application_id); ANALYZE _m2_2_route;
DROP TABLE IF EXISTS _m2_2_request;
CREATE TEMP TABLE _m2_2_request ON COMMIT DROP AS SELECT a.* FROM msbf_m1.merchant_application a WHERE a.created_by_run_id=(SELECT run_id FROM _m2_2_ctx);
CREATE UNIQUE INDEX ON _m2_2_request(merchant_application_id); ANALYZE _m2_2_request;

DROP TABLE IF EXISTS _m2_2_request_expected;
CREATE TEMP TABLE _m2_2_request_expected ON COMMIT DROP AS
SELECT c.run_id AS module1_run_id,a.merchant_application_id,a.population_id,a.merchant_id,a.as_of_date,a.application_date,a.requested_funding_amount,a.requested_remittance_rate,a.requested_expected_payoff_days::integer,a.requested_total_repayment_amount,a.requested_finance_charge_amount,round(a.requested_total_repayment_amount/nullif(a.requested_funding_amount,0),6) AS requested_payback_multiple,a.requested_use_of_proceeds,a.application_channel,a.request_hash AS source_request_hash,'01485256b9b5748fb412743d35ced602'::text AS source_m1_3_application_hash,c.configuration_hash AS policy_configuration_hash,NULL::text AS row_hash
FROM _m2_2_request a CROSS JOIN _m2_2_ctx c;
UPDATE _m2_2_request_expected x SET row_hash=msbf_ctl.m2_2_hash_jsonb(to_jsonb(x)-'row_hash');
CREATE UNIQUE INDEX ON _m2_2_request_expected(merchant_application_id); ANALYZE _m2_2_request_expected;
INSERT INTO msbf_m2.application_request_structure_snapshot(module1_run_id,merchant_application_id,population_id,merchant_id,as_of_date,application_date,requested_funding_amount,requested_remittance_rate,requested_expected_payoff_days,requested_total_repayment_amount,requested_finance_charge_amount,requested_payback_multiple,requested_use_of_proceeds,application_channel,source_request_hash,source_m1_3_application_hash,policy_configuration_hash,row_hash)
SELECT module1_run_id,merchant_application_id,population_id,merchant_id,as_of_date,application_date,requested_funding_amount,requested_remittance_rate,requested_expected_payoff_days,requested_total_repayment_amount,requested_finance_charge_amount,requested_payback_multiple,requested_use_of_proceeds,application_channel,source_request_hash,source_m1_3_application_hash,policy_configuration_hash,row_hash FROM _m2_2_request_expected;

DROP TABLE IF EXISTS _m2_2_request_latest_expected;
CREATE TEMP TABLE _m2_2_request_latest_expected ON COMMIT DROP AS
SELECT x.module1_run_id,'M2_REQUEST_STRUCTURE_CONSUMPTION'::text AS contract_code,1::integer AS contract_version,'M2_2_REQUEST_STRUCTURE_SCHEMA_V1'::text AS schema_version,'M2_2_METHOD_V1'::text AS methodology_version,x.merchant_application_id,x.population_id,x.merchant_id,x.as_of_date,x.requested_funding_amount,x.requested_remittance_rate,x.requested_expected_payoff_days,x.requested_total_repayment_amount,x.requested_finance_charge_amount,x.requested_payback_multiple,x.requested_use_of_proceeds,x.application_channel,x.source_request_hash,x.row_hash AS source_snapshot_row_hash,x.source_m1_3_application_hash,x.policy_configuration_hash,NULL::text AS contract_row_hash FROM _m2_2_request_expected x;
UPDATE _m2_2_request_latest_expected x SET contract_row_hash=msbf_ctl.m2_2_hash_jsonb(to_jsonb(x)-'contract_row_hash');
INSERT INTO msbf_m2.application_request_structure_latest(module1_run_id,contract_code,contract_version,schema_version,methodology_version,merchant_application_id,population_id,merchant_id,as_of_date,requested_funding_amount,requested_remittance_rate,requested_expected_payoff_days,requested_total_repayment_amount,requested_finance_charge_amount,requested_payback_multiple,requested_use_of_proceeds,application_channel,source_request_hash,source_snapshot_row_hash,source_m1_3_application_hash,policy_configuration_hash,contract_row_hash)
SELECT module1_run_id,contract_code,contract_version,schema_version,methodology_version,merchant_application_id,population_id,merchant_id,as_of_date,requested_funding_amount,requested_remittance_rate,requested_expected_payoff_days,requested_total_repayment_amount,requested_finance_charge_amount,requested_payback_multiple,requested_use_of_proceeds,application_channel,source_request_hash,source_snapshot_row_hash,source_m1_3_application_hash,policy_configuration_hash,contract_row_hash FROM _m2_2_request_latest_expected;

DROP TABLE IF EXISTS _m2_2_request_archive_expected;
CREATE TEMP TABLE _m2_2_request_archive_expected ON COMMIT DROP AS SELECT l.module1_run_id,l.contract_code,l.contract_version,l.schema_version,l.merchant_application_id,to_jsonb(l) AS contract_payload,l.contract_row_hash,l.contract_row_hash AS source_latest_row_hash,NULL::text AS archive_row_hash FROM _m2_2_request_latest_expected l;
UPDATE _m2_2_request_archive_expected a SET archive_row_hash=msbf_ctl.m2_2_hash_jsonb(to_jsonb(a)-'archive_row_hash');
INSERT INTO msbf_m2.application_request_structure_archive(module1_run_id,contract_code,contract_version,schema_version,merchant_application_id,contract_payload,contract_row_hash,source_latest_row_hash,archive_row_hash)
SELECT module1_run_id,contract_code,contract_version,schema_version,merchant_application_id,contract_payload,contract_row_hash,source_latest_row_hash,archive_row_hash FROM _m2_2_request_archive_expected;

DROP TABLE IF EXISTS _m2_2_candidate_raw;
CREATE TEMP TABLE _m2_2_candidate_raw ON COMMIT DROP AS
SELECT c.run_id AS module1_run_id,g.scenario_id,g.scenario_code,g.merchant_application_id,t.candidate_template_code,t.template_sequence,r.final_route_code AS source_route_code,r.final_route_rank AS source_route_rank,q.requested_funding_amount,
 greatest(c.minimum_candidate_amount,least(q.requested_funding_amount,round((q.requested_funding_amount*t.amount_multiplier)/c.amount_rounding_increment)*c.amount_rounding_increment,round((g.avg_daily_eligible_sales_30d*greatest(30,least(c.maximum_collection_horizon_days,round(q.requested_expected_payoff_days*t.horizon_multiplier)))*greatest(c.minimum_remittance_rate,least(c.maximum_remittance_rate,q.requested_remittance_rate*t.remittance_multiplier)))/c.amount_rounding_increment)*c.amount_rounding_increment)) AS base_candidate_amount,
 greatest(c.minimum_remittance_rate,least(c.maximum_remittance_rate,q.requested_remittance_rate*t.remittance_multiplier + CASE WHEN coalesce(g.integrated_risk_tier,5)>=5 THEN 0.020 WHEN coalesce(g.integrated_risk_tier,5)=4 THEN 0.010 ELSE 0 END + CASE WHEN g.scenario_code='RECESSION_ENERGY' THEN 0.010 ELSE 0 END + CASE WHEN coalesce(g.relationship_stage,'') IN('RETURNING_GOOD','LOW_AND_GROW') THEN c.relationship_pricing_adjustment ELSE 0 END)) AS base_candidate_rate,
 greatest(c.minimum_payback_multiple,least(c.maximum_payback_multiple,round((q.requested_payback_multiple*t.payback_multiplier + CASE WHEN coalesce(g.integrated_risk_tier,5)>=5 THEN 0.05 WHEN coalesce(g.integrated_risk_tier,5)=4 THEN 0.025 ELSE 0 END + CASE WHEN g.scenario_code='RECESSION_ENERGY' THEN 0.025 ELSE 0 END)::numeric,6))) AS base_candidate_payback,
 greatest(1,least(c.maximum_collection_horizon_days,round(q.requested_expected_payoff_days*t.horizon_multiplier)))::integer AS base_candidate_horizon,
 g.avg_daily_eligible_sales_30d,g.integrated_risk_tier,g.resilience_tier,g.economic_tier,g.economic_status,g.schedule_adjusted_comparative_expected_loss_amount,g.risk_adjusted_contribution_amount,g.annualized_risk_adjusted_return_rate,g.enhanced_total_acquisition_cost_if_booked,
 t.counteroffer_foundation_flag,r.contract_row_hash AS source_m2_1_contract_row_hash,q.contract_row_hash AS source_request_contract_row_hash,g.m1_15_contract_row_hash,g.m1_16_contract_row_hash,'e5ace7f32060ffb191c7bd0f8dd0c863'::text AS source_g2_combined_hash,c.configuration_hash AS policy_configuration_hash
FROM _m2_2_ctx c JOIN _m2_2_route r ON TRUE JOIN _m2_2_g2 g ON g.scenario_id=r.scenario_id AND g.merchant_application_id=r.merchant_application_id JOIN _m2_2_request_latest_expected q ON q.merchant_application_id=r.merchant_application_id JOIN msbf_m2.pricing_structure_candidate_template t ON t.module1_run_id=c.run_id AND t.applicable_route_code=r.final_route_code AND t.active_flag;
CREATE INDEX ON _m2_2_candidate_raw(merchant_application_id,candidate_template_code,scenario_code); ANALYZE _m2_2_candidate_raw;

DROP TABLE IF EXISTS _m2_2_candidate_floor;
CREATE TEMP TABLE _m2_2_candidate_floor ON COMMIT DROP AS
SELECT x.*,
 CASE WHEN scenario_code='RECESSION_ENERGY' THEN least(base_candidate_amount,max(base_candidate_amount) FILTER(WHERE scenario_code='BASELINE') OVER(PARTITION BY merchant_application_id,candidate_template_code)) ELSE base_candidate_amount END AS candidate_funding_amount,
 CASE WHEN scenario_code='RECESSION_ENERGY' THEN greatest(base_candidate_rate,max(base_candidate_rate) FILTER(WHERE scenario_code='BASELINE') OVER(PARTITION BY merchant_application_id,candidate_template_code)) ELSE base_candidate_rate END AS candidate_remittance_rate,
 CASE WHEN scenario_code='RECESSION_ENERGY' THEN greatest(base_candidate_payback,max(base_candidate_payback) FILTER(WHERE scenario_code='BASELINE') OVER(PARTITION BY merchant_application_id,candidate_template_code)) ELSE base_candidate_payback END AS candidate_payback_multiple,
 CASE WHEN scenario_code='RECESSION_ENERGY' THEN greatest(base_candidate_horizon,max(base_candidate_horizon) FILTER(WHERE scenario_code='BASELINE') OVER(PARTITION BY merchant_application_id,candidate_template_code)) ELSE base_candidate_horizon END AS candidate_collection_horizon_days
FROM _m2_2_candidate_raw x;

DROP TABLE IF EXISTS _m2_2_candidate_scored;
CREATE TEMP TABLE _m2_2_candidate_scored ON COMMIT DROP AS
SELECT x.*,
 round(candidate_funding_amount*candidate_payback_multiple,2) AS candidate_total_repayment_amount,
 round(candidate_funding_amount*(candidate_payback_multiple-1),2) AS candidate_finance_charge_amount,
 round(avg_daily_eligible_sales_30d*candidate_remittance_rate,2) AS implied_daily_collection_amount,
 round((candidate_funding_amount*candidate_payback_multiple)/nullif(avg_daily_eligible_sales_30d*candidate_remittance_rate,0),4) AS implied_payoff_days,
 round(candidate_funding_amount/nullif(requested_funding_amount,0),8) AS amount_to_request_ratio,
 round(candidate_funding_amount/nullif(avg_daily_eligible_sales_30d*candidate_collection_horizon_days*candidate_remittance_rate,0),8) AS capacity_alignment_ratio,
 greatest(0,candidate_remittance_rate-base_candidate_rate) AS stress_load_rate,
 greatest(0,candidate_remittance_rate-0.05) AS risk_load_rate,
 greatest(0,coalesce(resilience_tier,5)-3)*0.0025 AS resilience_load_rate,
 CASE WHEN economic_status='ABOVE_HURDLE' THEN 0 WHEN economic_status='BELOW_HURDLE' THEN 0.005 WHEN economic_status='NEGATIVE_CONTRIBUTION' THEN 0.010 ELSE 0.015 END AS economic_load_rate,
 (candidate_funding_amount>=2500 AND candidate_funding_amount<=requested_funding_amount AND candidate_remittance_rate BETWEEN 0.05 AND 0.20 AND candidate_payback_multiple BETWEEN 1.05 AND 1.40 AND candidate_collection_horizon_days BETWEEN 1 AND 120) AS candidate_eligible_flag,
 row_number() OVER(PARTITION BY scenario_id,merchant_application_id ORDER BY template_sequence,candidate_funding_amount DESC,candidate_remittance_rate ASC,candidate_template_code) AS candidate_rank
FROM _m2_2_candidate_floor x;

/* --------------------------------------------------------------------------
Selected-structure matched-scenario stress floor

The earlier per-template floor correctly prevents improvement when baseline
and stress use the same candidate template. Ten accepted M2.1 applications
move from ELIGIBLE_FOR_OFFER_DESIGN in baseline to MANUAL_REVIEW in stress.
That route change also changes the selected template family, so a second floor
must compare the selected baseline structure to the selected stress structure.

The accepted source deterministically produces:
- 66 matched baseline/stress selected structures;
- 10 ELIGIBLE_FOR_OFFER_DESIGN → MANUAL_REVIEW transitions;
- 9 selected stress structures with at least one improved dimension.

Only those 9 selected stress candidates are adjusted. No candidate is added
or removed, and no template ranking changes.
-------------------------------------------------------------------------- */
DROP TABLE IF EXISTS _m2_2_selected_stress_floor_audit;

CREATE TEMP TABLE _m2_2_selected_stress_floor_audit
ON COMMIT DROP
AS
SELECT
    stress.merchant_application_id,

    baseline.source_route_code
        AS baseline_source_route_code,
    stress.source_route_code
        AS stress_source_route_code,

    baseline.candidate_template_code
        AS baseline_candidate_template_code,
    stress.candidate_template_code
        AS stress_candidate_template_code,

    baseline.candidate_funding_amount
        AS baseline_funding_amount,
    stress.candidate_funding_amount
        AS stress_funding_amount_before,

    baseline.candidate_remittance_rate
        AS baseline_remittance_rate,
    stress.candidate_remittance_rate
        AS stress_remittance_rate_before,

    baseline.candidate_payback_multiple
        AS baseline_payback_multiple,
    stress.candidate_payback_multiple
        AS stress_payback_multiple_before,

    baseline.candidate_collection_horizon_days
        AS baseline_collection_horizon_days,
    stress.candidate_collection_horizon_days
        AS stress_collection_horizon_days_before,

    (
        stress.candidate_funding_amount >
        baseline.candidate_funding_amount
    ) AS amount_improvement_flag,

    (
        stress.candidate_remittance_rate <
        baseline.candidate_remittance_rate
    ) AS remittance_improvement_flag,

    (
        stress.candidate_payback_multiple <
        baseline.candidate_payback_multiple
    ) AS payback_improvement_flag,

    (
        stress.candidate_collection_horizon_days <
        baseline.candidate_collection_horizon_days
    ) AS horizon_improvement_flag,

    (
        stress.candidate_funding_amount >
            baseline.candidate_funding_amount
        OR
        stress.candidate_remittance_rate <
            baseline.candidate_remittance_rate
        OR
        stress.candidate_payback_multiple <
            baseline.candidate_payback_multiple
        OR
        stress.candidate_collection_horizon_days <
            baseline.candidate_collection_horizon_days
    ) AS floor_required_flag

FROM _m2_2_candidate_scored AS baseline

JOIN _m2_2_candidate_scored AS stress
  ON stress.merchant_application_id =
     baseline.merchant_application_id
 AND stress.scenario_code = 'RECESSION_ENERGY'

WHERE baseline.scenario_code = 'BASELINE'
  AND baseline.candidate_rank = 1
  AND stress.candidate_rank = 1
  AND baseline.candidate_eligible_flag
  AND stress.candidate_eligible_flag;

CREATE UNIQUE INDEX
ON _m2_2_selected_stress_floor_audit
(
    merchant_application_id
);

ANALYZE _m2_2_selected_stress_floor_audit;

DROP TABLE IF EXISTS _m2_2_selected_stress_floor_values;

CREATE TEMP TABLE _m2_2_selected_stress_floor_values
ON COMMIT DROP
AS
SELECT
    audit.merchant_application_id,
    audit.stress_candidate_template_code,

    least(
        audit.stress_funding_amount_before,
        audit.baseline_funding_amount
    ) AS floored_funding_amount,

    greatest(
        audit.stress_remittance_rate_before,
        audit.baseline_remittance_rate
    ) AS floored_remittance_rate,

    greatest(
        audit.stress_payback_multiple_before,
        audit.baseline_payback_multiple
    ) AS floored_payback_multiple,

    greatest(
        audit.stress_collection_horizon_days_before,
        audit.baseline_collection_horizon_days
    ) AS floored_collection_horizon_days

FROM _m2_2_selected_stress_floor_audit AS audit

WHERE audit.floor_required_flag;

CREATE UNIQUE INDEX
ON _m2_2_selected_stress_floor_values
(
    merchant_application_id,
    stress_candidate_template_code
);

ANALYZE _m2_2_selected_stress_floor_values;

DROP TABLE IF EXISTS _m2_2_selected_stress_floor_applied;

CREATE TEMP TABLE _m2_2_selected_stress_floor_applied
(
    merchant_application_id   text NOT NULL,
    candidate_template_code   text NOT NULL,
    PRIMARY KEY
    (
        merchant_application_id,
        candidate_template_code
    )
)
ON COMMIT DROP;

WITH updated AS
(
    UPDATE _m2_2_candidate_scored AS stress

    SET
        candidate_funding_amount =
            floor.floored_funding_amount,

        candidate_remittance_rate =
            floor.floored_remittance_rate,

        candidate_payback_multiple =
            floor.floored_payback_multiple,

        candidate_collection_horizon_days =
            floor.floored_collection_horizon_days,

        candidate_total_repayment_amount =
            round(
                floor.floored_funding_amount *
                floor.floored_payback_multiple,
                2
            ),

        candidate_finance_charge_amount =
            round(
                floor.floored_funding_amount *
                (
                    floor.floored_payback_multiple - 1
                ),
                2
            ),

        implied_daily_collection_amount =
            round(
                stress.avg_daily_eligible_sales_30d *
                floor.floored_remittance_rate,
                2
            ),

        implied_payoff_days =
            round(
                (
                    floor.floored_funding_amount *
                    floor.floored_payback_multiple
                )
                /
                nullif(
                    stress.avg_daily_eligible_sales_30d *
                    floor.floored_remittance_rate,
                    0
                ),
                4
            ),

        amount_to_request_ratio =
            round(
                floor.floored_funding_amount
                /
                nullif(
                    stress.requested_funding_amount,
                    0
                ),
                8
            ),

        capacity_alignment_ratio =
            round(
                floor.floored_funding_amount
                /
                nullif(
                    stress.avg_daily_eligible_sales_30d *
                    floor.floored_collection_horizon_days *
                    floor.floored_remittance_rate,
                    0
                ),
                8
            ),

        stress_load_rate =
            greatest(
                0,
                floor.floored_remittance_rate -
                stress.base_candidate_rate
            ),

        risk_load_rate =
            greatest(
                0,
                floor.floored_remittance_rate - 0.05
            ),

        candidate_eligible_flag =
        (
            floor.floored_funding_amount >= 2500
            AND
            floor.floored_funding_amount <=
                stress.requested_funding_amount
            AND
            floor.floored_remittance_rate
                BETWEEN 0.05 AND 0.20
            AND
            floor.floored_payback_multiple
                BETWEEN 1.05 AND 1.40
            AND
            floor.floored_collection_horizon_days
                BETWEEN 1 AND 120
        )

    FROM _m2_2_selected_stress_floor_values AS floor

    WHERE stress.scenario_code = 'RECESSION_ENERGY'
      AND stress.merchant_application_id =
          floor.merchant_application_id
      AND stress.candidate_template_code =
          floor.stress_candidate_template_code
      AND stress.candidate_rank = 1
      AND stress.candidate_eligible_flag

    RETURNING
        stress.merchant_application_id,
        stress.candidate_template_code
)

INSERT INTO _m2_2_selected_stress_floor_applied
(
    merchant_application_id,
    candidate_template_code
)
SELECT
    merchant_application_id,
    candidate_template_code
FROM updated;

DROP TABLE IF EXISTS _m2_2_stress_floor_summary;

CREATE TEMP TABLE _m2_2_stress_floor_summary
ON COMMIT PRESERVE ROWS
AS
WITH post_floor AS
(
    SELECT
        count(*) FILTER
        (
            WHERE
                stress.candidate_funding_amount >
                    baseline.candidate_funding_amount
                OR
                stress.candidate_remittance_rate <
                    baseline.candidate_remittance_rate
                OR
                stress.candidate_payback_multiple <
                    baseline.candidate_payback_multiple
                OR
                stress.candidate_collection_horizon_days <
                    baseline.candidate_collection_horizon_days
        )::bigint AS post_floor_improvement_rows

    FROM _m2_2_candidate_scored AS baseline

    JOIN _m2_2_candidate_scored AS stress
      ON stress.merchant_application_id =
         baseline.merchant_application_id
     AND stress.scenario_code = 'RECESSION_ENERGY'

    WHERE baseline.scenario_code = 'BASELINE'
      AND baseline.candidate_rank = 1
      AND stress.candidate_rank = 1
      AND baseline.candidate_eligible_flag
      AND stress.candidate_eligible_flag
)

SELECT
    count(*)::bigint
        AS matched_selected_structure_rows,

    count(*) FILTER
    (
        WHERE baseline_source_route_code =
              'ELIGIBLE_FOR_OFFER_DESIGN'
          AND stress_source_route_code =
              'MANUAL_REVIEW'
    )::bigint
        AS eligible_to_review_transition_rows,

    count(*) FILTER
    (
        WHERE floor_required_flag
    )::bigint
        AS pre_floor_improvement_rows,

    count(*) FILTER
    (
        WHERE amount_improvement_flag
    )::bigint
        AS pre_floor_amount_improvement_rows,

    count(*) FILTER
    (
        WHERE remittance_improvement_flag
    )::bigint
        AS pre_floor_remittance_improvement_rows,

    count(*) FILTER
    (
        WHERE payback_improvement_flag
    )::bigint
        AS pre_floor_payback_improvement_rows,

    count(*) FILTER
    (
        WHERE horizon_improvement_flag
    )::bigint
        AS pre_floor_horizon_improvement_rows,

    (
        SELECT count(*)
        FROM _m2_2_selected_stress_floor_applied
    )::bigint
        AS stress_floor_applied_rows,

    post_floor.post_floor_improvement_rows

FROM _m2_2_selected_stress_floor_audit
CROSS JOIN post_floor

GROUP BY
    post_floor.post_floor_improvement_rows;

DO $selected_stress_floor_guard$
DECLARE
    v record;
BEGIN
    SELECT *
    INTO v
    FROM _m2_2_stress_floor_summary;

    IF v.matched_selected_structure_rows <> 66
       OR v.eligible_to_review_transition_rows <> 10
       OR v.pre_floor_improvement_rows <> 9
       OR v.stress_floor_applied_rows <> 9
       OR v.post_floor_improvement_rows <> 0 THEN
        RAISE EXCEPTION
            'M2.2 selected stress floor failed: matched %, '
            'eligible-to-review %, pre-floor improvements %, '
            'applied %, post-floor improvements %.',
            v.matched_selected_structure_rows,
            v.eligible_to_review_transition_rows,
            v.pre_floor_improvement_rows,
            v.stress_floor_applied_rows,
            v.post_floor_improvement_rows;
    END IF;
END;
$selected_stress_floor_guard$;

/* --------------------------------------------------------------------------
Target-typed candidate staging

The persisted candidate contract uses explicit numeric typmods. Candidate
expressions are first assigned into this target-typed temporary table and only
then hashed. This guarantees that the deterministic hash sees the exact
physical numeric scale that PostgreSQL will persist.
-------------------------------------------------------------------------- */
DROP TABLE IF EXISTS _m2_2_candidate_expected;

CREATE TEMP TABLE _m2_2_candidate_expected
(
    module1_run_id                     bigint        NOT NULL,
    scenario_id                        bigint        NOT NULL,
    scenario_code                      text          NOT NULL,
    merchant_application_id            text          NOT NULL,
    candidate_template_code            text          NOT NULL,
    template_sequence                  integer       NOT NULL,
    source_route_code                  text          NOT NULL,
    source_route_rank                  integer       NOT NULL,
    requested_funding_amount           numeric(18,2) NOT NULL,
    candidate_funding_amount           numeric(18,2) NOT NULL,
    candidate_remittance_rate          numeric(9,6)  NOT NULL,
    candidate_payback_multiple         numeric(9,6)  NOT NULL,
    candidate_collection_horizon_days  integer       NOT NULL,
    candidate_total_repayment_amount   numeric(18,2) NOT NULL,
    candidate_finance_charge_amount    numeric(18,2) NOT NULL,
    implied_daily_collection_amount    numeric(18,2) NOT NULL,
    implied_payoff_days                numeric(18,4) NOT NULL,
    amount_to_request_ratio            numeric(12,8) NOT NULL,
    capacity_alignment_ratio           numeric(12,8),
    risk_load_rate                     numeric(9,6)  NOT NULL,
    resilience_load_rate               numeric(9,6)  NOT NULL,
    economic_load_rate                 numeric(9,6)  NOT NULL,
    stress_load_rate                   numeric(9,6)  NOT NULL,
    acquisition_economics_amount       numeric(18,2),
    expected_loss_amount               numeric(18,2),
    risk_adjusted_contribution_amount  numeric(18,2),
    annualized_return_rate             numeric(12,8),
    counteroffer_foundation_flag       boolean       NOT NULL,
    candidate_eligible_flag            boolean       NOT NULL,
    selected_foundation_flag           boolean       NOT NULL,
    candidate_rank                     integer       NOT NULL,
    primary_reason_code                text          NOT NULL,
    secondary_reason_codes             jsonb         NOT NULL,
    source_m2_1_contract_row_hash      text          NOT NULL,
    source_request_contract_row_hash   text          NOT NULL,
    source_m1_15_contract_row_hash     text          NOT NULL,
    source_m1_16_contract_row_hash     text          NOT NULL,
    source_g2_combined_hash            text          NOT NULL,
    policy_configuration_hash          text          NOT NULL,
    row_hash                           text
)
ON COMMIT DROP;

INSERT INTO _m2_2_candidate_expected
(
    module1_run_id,
    scenario_id,
    scenario_code,
    merchant_application_id,
    candidate_template_code,
    template_sequence,
    source_route_code,
    source_route_rank,
    requested_funding_amount,
    candidate_funding_amount,
    candidate_remittance_rate,
    candidate_payback_multiple,
    candidate_collection_horizon_days,
    candidate_total_repayment_amount,
    candidate_finance_charge_amount,
    implied_daily_collection_amount,
    implied_payoff_days,
    amount_to_request_ratio,
    capacity_alignment_ratio,
    risk_load_rate,
    resilience_load_rate,
    economic_load_rate,
    stress_load_rate,
    acquisition_economics_amount,
    expected_loss_amount,
    risk_adjusted_contribution_amount,
    annualized_return_rate,
    counteroffer_foundation_flag,
    candidate_eligible_flag,
    selected_foundation_flag,
    candidate_rank,
    primary_reason_code,
    secondary_reason_codes,
    source_m2_1_contract_row_hash,
    source_request_contract_row_hash,
    source_m1_15_contract_row_hash,
    source_m1_16_contract_row_hash,
    source_g2_combined_hash,
    policy_configuration_hash,
    row_hash
)
SELECT
    x.module1_run_id,
    x.scenario_id,
    x.scenario_code,
    x.merchant_application_id,
    x.candidate_template_code,
    x.template_sequence,
    x.source_route_code,
    x.source_route_rank,
    x.requested_funding_amount,
    x.candidate_funding_amount,
    x.candidate_remittance_rate,
    x.candidate_payback_multiple,
    x.candidate_collection_horizon_days,
    x.candidate_total_repayment_amount,
    x.candidate_finance_charge_amount,
    x.implied_daily_collection_amount,
    x.implied_payoff_days,
    x.amount_to_request_ratio,
    x.capacity_alignment_ratio,
    x.risk_load_rate,
    x.resilience_load_rate,
    x.economic_load_rate,
    x.stress_load_rate,
    x.enhanced_total_acquisition_cost_if_booked,
    x.schedule_adjusted_comparative_expected_loss_amount,
    x.risk_adjusted_contribution_amount,
    x.annualized_risk_adjusted_return_rate,
    x.counteroffer_foundation_flag,
    x.candidate_eligible_flag,
    (x.candidate_rank = 1 AND x.candidate_eligible_flag),
    x.candidate_rank,
    CASE
        WHEN x.candidate_template_code LIKE '%REQUEST_REFERENCE'
            THEN 'M2_2_REQUEST_REFERENCE'
        WHEN x.candidate_template_code LIKE '%COUNTEROFFER%'
            THEN 'M2_2_COUNTEROFFER_RESERVE'
        WHEN x.source_route_code = 'MANUAL_REVIEW'
            THEN 'M2_2_REVIEW_CAPACITY'
        ELSE 'M2_2_CAPACITY_ALIGNED'
    END,
    jsonb_build_array(
        'M2_2_AMOUNT_REQUEST_CAP',
        'M2_2_ACQUISITION_NONCREDIT',
        CASE
            WHEN x.scenario_code = 'RECESSION_ENERGY'
                THEN 'M2_2_STRESS_FLOOR'
            ELSE 'M2_2_CAPACITY_ALIGNED'
        END
    ),
    x.source_m2_1_contract_row_hash,
    x.source_request_contract_row_hash,
    x.m1_15_contract_row_hash,
    x.m1_16_contract_row_hash,
    x.source_g2_combined_hash,
    x.policy_configuration_hash,
    NULL::text
FROM _m2_2_candidate_scored AS x;

UPDATE _m2_2_candidate_expected AS x
SET row_hash = msbf_ctl.m2_2_hash_jsonb(
    to_jsonb(x) - 'row_hash'
)
WHERE x.row_hash IS NULL;

CREATE UNIQUE INDEX
ON _m2_2_candidate_expected
(
    scenario_id,
    merchant_application_id,
    candidate_template_code
);

CREATE INDEX
ON _m2_2_candidate_expected
(
    scenario_id,
    merchant_application_id,
    selected_foundation_flag
);

ANALYZE _m2_2_candidate_expected;

INSERT INTO msbf_m2.application_pricing_structure_candidate
(
    module1_run_id,
    scenario_id,
    scenario_code,
    merchant_application_id,
    candidate_template_code,
    template_sequence,
    source_route_code,
    source_route_rank,
    requested_funding_amount,
    candidate_funding_amount,
    candidate_remittance_rate,
    candidate_payback_multiple,
    candidate_collection_horizon_days,
    candidate_total_repayment_amount,
    candidate_finance_charge_amount,
    implied_daily_collection_amount,
    implied_payoff_days,
    amount_to_request_ratio,
    capacity_alignment_ratio,
    risk_load_rate,
    resilience_load_rate,
    economic_load_rate,
    stress_load_rate,
    acquisition_economics_amount,
    expected_loss_amount,
    risk_adjusted_contribution_amount,
    annualized_return_rate,
    counteroffer_foundation_flag,
    candidate_eligible_flag,
    selected_foundation_flag,
    candidate_rank,
    primary_reason_code,
    secondary_reason_codes,
    source_m2_1_contract_row_hash,
    source_request_contract_row_hash,
    source_m1_15_contract_row_hash,
    source_m1_16_contract_row_hash,
    source_g2_combined_hash,
    policy_configuration_hash,
    row_hash
)
SELECT
    module1_run_id,
    scenario_id,
    scenario_code,
    merchant_application_id,
    candidate_template_code,
    template_sequence,
    source_route_code,
    source_route_rank,
    requested_funding_amount,
    candidate_funding_amount,
    candidate_remittance_rate,
    candidate_payback_multiple,
    candidate_collection_horizon_days,
    candidate_total_repayment_amount,
    candidate_finance_charge_amount,
    implied_daily_collection_amount,
    implied_payoff_days,
    amount_to_request_ratio,
    capacity_alignment_ratio,
    risk_load_rate,
    resilience_load_rate,
    economic_load_rate,
    stress_load_rate,
    acquisition_economics_amount,
    expected_loss_amount,
    risk_adjusted_contribution_amount,
    annualized_return_rate,
    counteroffer_foundation_flag,
    candidate_eligible_flag,
    selected_foundation_flag,
    candidate_rank,
    primary_reason_code,
    secondary_reason_codes,
    source_m2_1_contract_row_hash,
    source_request_contract_row_hash,
    source_m1_15_contract_row_hash,
    source_m1_16_contract_row_hash,
    source_g2_combined_hash,
    policy_configuration_hash,
    row_hash
FROM _m2_2_candidate_expected;

/* --------------------------------------------------------------------------
Target-typed pricing snapshot staging

Only the 249 candidate-bearing routing rows populate selected numeric fields.
Those fields are assigned to the exact persistent typmods before the snapshot
hash is calculated. No-design records retain null selected fields.
-------------------------------------------------------------------------- */
DROP TABLE IF EXISTS _m2_2_snapshot_expected;

CREATE TEMP TABLE _m2_2_snapshot_expected
(
    module1_run_id                        bigint        NOT NULL,
    scenario_id                           bigint        NOT NULL,
    scenario_code                         text          NOT NULL,
    merchant_application_id               text          NOT NULL,
    population_id                         text          NOT NULL,
    merchant_id                           text          NOT NULL,
    as_of_date                            date          NOT NULL,
    source_route_code                     text          NOT NULL,
    source_route_rank                     integer       NOT NULL,
    pricing_disposition_code              text          NOT NULL,
    structure_available_flag              boolean       NOT NULL,
    review_required_flag                  boolean       NOT NULL,
    selected_candidate_template_code      text,
    selected_candidate_row_hash           text,
    requested_funding_amount              numeric(18,2) NOT NULL,
    selected_funding_amount               numeric(18,2),
    selected_remittance_rate              numeric(9,6),
    selected_payback_multiple             numeric(9,6),
    selected_collection_horizon_days      integer,
    selected_total_repayment_amount       numeric(18,2),
    selected_finance_charge_amount        numeric(18,2),
    selected_implied_daily_collection_amount numeric(18,2),
    selected_implied_payoff_days          numeric(18,4),
    selected_amount_to_request_ratio      numeric(12,8),
    candidate_count                       integer       NOT NULL,
    counteroffer_foundation_flag          boolean       NOT NULL,
    stress_nonimprovement_applied_flag    boolean       NOT NULL,
    primary_reason_code                   text          NOT NULL,
    reason_codes                          jsonb         NOT NULL,
    routing_evidence_status               text          NOT NULL,
    source_m2_1_contract_row_hash         text          NOT NULL,
    source_request_contract_row_hash      text          NOT NULL,
    source_g2_combined_hash               text          NOT NULL,
    policy_configuration_hash             text          NOT NULL,
    row_hash                              text
)
ON COMMIT DROP;

INSERT INTO _m2_2_snapshot_expected
(
    module1_run_id,
    scenario_id,
    scenario_code,
    merchant_application_id,
    population_id,
    merchant_id,
    as_of_date,
    source_route_code,
    source_route_rank,
    pricing_disposition_code,
    structure_available_flag,
    review_required_flag,
    selected_candidate_template_code,
    selected_candidate_row_hash,
    requested_funding_amount,
    selected_funding_amount,
    selected_remittance_rate,
    selected_payback_multiple,
    selected_collection_horizon_days,
    selected_total_repayment_amount,
    selected_finance_charge_amount,
    selected_implied_daily_collection_amount,
    selected_implied_payoff_days,
    selected_amount_to_request_ratio,
    candidate_count,
    counteroffer_foundation_flag,
    stress_nonimprovement_applied_flag,
    primary_reason_code,
    reason_codes,
    routing_evidence_status,
    source_m2_1_contract_row_hash,
    source_request_contract_row_hash,
    source_g2_combined_hash,
    policy_configuration_hash,
    row_hash
)
SELECT
    c.run_id,
    r.scenario_id,
    r.scenario_code,
    r.merchant_application_id,
    r.population_id,
    r.merchant_id,
    r.as_of_date,
    r.final_route_code,
    r.final_route_rank,
    CASE r.final_route_code
        WHEN 'ELIGIBLE_FOR_OFFER_DESIGN'
            THEN 'STRUCTURE_READY'
        WHEN 'MANUAL_REVIEW'
            THEN 'COUNTEROFFER_FOUNDATION_REVIEW'
        WHEN 'INSUFFICIENT_EVIDENCE'
            THEN 'NO_STRUCTURE_INSUFFICIENT_EVIDENCE'
        ELSE 'NO_STRUCTURE_POLICY_DECLINE'
    END,
    r.final_route_code IN(
        'ELIGIBLE_FOR_OFFER_DESIGN',
        'MANUAL_REVIEW'
    ),
    r.final_route_code = 'MANUAL_REVIEW',
    cand.candidate_template_code,
    cand.row_hash,
    q.requested_funding_amount,
    cand.candidate_funding_amount,
    cand.candidate_remittance_rate,
    cand.candidate_payback_multiple,
    cand.candidate_collection_horizon_days,
    cand.candidate_total_repayment_amount,
    cand.candidate_finance_charge_amount,
    cand.implied_daily_collection_amount,
    cand.implied_payoff_days,
    cand.amount_to_request_ratio,
    coalesce(cnt.candidate_count,0)::integer,
    coalesce(cand.counteroffer_foundation_flag,FALSE),
    EXISTS
    (
        SELECT 1
        FROM _m2_2_selected_stress_floor_applied AS floor_applied
        WHERE floor_applied.merchant_application_id =
              r.merchant_application_id
          AND floor_applied.candidate_template_code =
              cand.candidate_template_code
    ),
    CASE r.final_route_code
        WHEN 'ELIGIBLE_FOR_OFFER_DESIGN'
            THEN coalesce(
                cand.primary_reason_code,
                'M2_2_CAPACITY_ALIGNED'
            )
        WHEN 'MANUAL_REVIEW'
            THEN coalesce(
                cand.primary_reason_code,
                'M2_2_REVIEW_CAPACITY'
            )
        WHEN 'INSUFFICIENT_EVIDENCE'
            THEN 'M2_2_NO_STRUCTURE_INSUFFICIENT'
        ELSE 'M2_2_NO_STRUCTURE_POLICY'
    END,
    CASE
        WHEN cand.row_hash IS NULL THEN
            jsonb_build_array(
                CASE
                    WHEN r.final_route_code = 'INSUFFICIENT_EVIDENCE'
                        THEN 'M2_2_NO_STRUCTURE_INSUFFICIENT'
                    ELSE 'M2_2_NO_STRUCTURE_POLICY'
                END
            )
        ELSE cand.secondary_reason_codes
    END,
    r.routing_evidence_status,
    r.contract_row_hash,
    q.contract_row_hash,
    'e5ace7f32060ffb191c7bd0f8dd0c863'::text,
    c.configuration_hash,
    NULL::text
FROM _m2_2_ctx AS c
JOIN _m2_2_route AS r
  ON TRUE
JOIN _m2_2_request_latest_expected AS q
  ON q.merchant_application_id = r.merchant_application_id
LEFT JOIN _m2_2_candidate_expected AS cand
  ON cand.scenario_id = r.scenario_id
 AND cand.merchant_application_id = r.merchant_application_id
 AND cand.selected_foundation_flag
LEFT JOIN
(
    SELECT
        scenario_id,
        merchant_application_id,
        count(*)::integer AS candidate_count
    FROM _m2_2_candidate_expected
    GROUP BY
        scenario_id,
        merchant_application_id
) AS cnt
  ON cnt.scenario_id = r.scenario_id
 AND cnt.merchant_application_id = r.merchant_application_id;

UPDATE _m2_2_snapshot_expected AS x
SET row_hash = msbf_ctl.m2_2_hash_jsonb(
    to_jsonb(x) - 'row_hash'
)
WHERE x.row_hash IS NULL;

CREATE UNIQUE INDEX
ON _m2_2_snapshot_expected
(
    scenario_id,
    merchant_application_id
);

ANALYZE _m2_2_snapshot_expected;

INSERT INTO msbf_m2.application_pricing_structure_snapshot
(
    module1_run_id,
    scenario_id,
    scenario_code,
    merchant_application_id,
    population_id,
    merchant_id,
    as_of_date,
    source_route_code,
    source_route_rank,
    pricing_disposition_code,
    structure_available_flag,
    review_required_flag,
    selected_candidate_template_code,
    selected_candidate_row_hash,
    requested_funding_amount,
    selected_funding_amount,
    selected_remittance_rate,
    selected_payback_multiple,
    selected_collection_horizon_days,
    selected_total_repayment_amount,
    selected_finance_charge_amount,
    selected_implied_daily_collection_amount,
    selected_implied_payoff_days,
    selected_amount_to_request_ratio,
    candidate_count,
    counteroffer_foundation_flag,
    stress_nonimprovement_applied_flag,
    primary_reason_code,
    reason_codes,
    routing_evidence_status,
    source_m2_1_contract_row_hash,
    source_request_contract_row_hash,
    source_g2_combined_hash,
    policy_configuration_hash,
    row_hash
)
SELECT
    module1_run_id,
    scenario_id,
    scenario_code,
    merchant_application_id,
    population_id,
    merchant_id,
    as_of_date,
    source_route_code,
    source_route_rank,
    pricing_disposition_code,
    structure_available_flag,
    review_required_flag,
    selected_candidate_template_code,
    selected_candidate_row_hash,
    requested_funding_amount,
    selected_funding_amount,
    selected_remittance_rate,
    selected_payback_multiple,
    selected_collection_horizon_days,
    selected_total_repayment_amount,
    selected_finance_charge_amount,
    selected_implied_daily_collection_amount,
    selected_implied_payoff_days,
    selected_amount_to_request_ratio,
    candidate_count,
    counteroffer_foundation_flag,
    stress_nonimprovement_applied_flag,
    primary_reason_code,
    reason_codes,
    routing_evidence_status,
    source_m2_1_contract_row_hash,
    source_request_contract_row_hash,
    source_g2_combined_hash,
    policy_configuration_hash,
    row_hash
FROM _m2_2_snapshot_expected;

DROP TABLE IF EXISTS _m2_2_latest_expected;
CREATE TEMP TABLE _m2_2_latest_expected ON COMMIT DROP AS SELECT x.module1_run_id,'M2_PRICING_STRUCTURE_CONSUMPTION'::text AS contract_code,1::integer AS contract_version,'M2_2_PRICING_STRUCTURE_SCHEMA_V1'::text AS schema_version,'M2_2_METHOD_V1'::text AS methodology_version,x.scenario_id,x.scenario_code,x.merchant_application_id,x.population_id,x.merchant_id,x.as_of_date,x.source_route_code,x.source_route_rank,x.pricing_disposition_code,x.structure_available_flag,x.review_required_flag,x.selected_candidate_template_code,x.selected_candidate_row_hash,x.requested_funding_amount,x.selected_funding_amount,x.selected_remittance_rate,x.selected_payback_multiple,x.selected_collection_horizon_days,x.selected_total_repayment_amount,x.selected_finance_charge_amount,x.selected_implied_daily_collection_amount,x.selected_implied_payoff_days,x.selected_amount_to_request_ratio,x.candidate_count,x.counteroffer_foundation_flag,x.stress_nonimprovement_applied_flag,x.primary_reason_code,x.reason_codes,x.routing_evidence_status,x.source_m2_1_contract_row_hash,x.source_request_contract_row_hash,x.source_g2_combined_hash,x.policy_configuration_hash,x.row_hash AS source_snapshot_row_hash,NULL::text AS contract_row_hash FROM _m2_2_snapshot_expected x;
UPDATE _m2_2_latest_expected x SET contract_row_hash=msbf_ctl.m2_2_hash_jsonb(to_jsonb(x)-'contract_row_hash');
INSERT INTO msbf_m2.application_pricing_structure_latest(module1_run_id,contract_code,contract_version,schema_version,methodology_version,scenario_id,scenario_code,merchant_application_id,population_id,merchant_id,as_of_date,source_route_code,source_route_rank,pricing_disposition_code,structure_available_flag,review_required_flag,selected_candidate_template_code,selected_candidate_row_hash,requested_funding_amount,selected_funding_amount,selected_remittance_rate,selected_payback_multiple,selected_collection_horizon_days,selected_total_repayment_amount,selected_finance_charge_amount,selected_implied_daily_collection_amount,selected_implied_payoff_days,selected_amount_to_request_ratio,candidate_count,counteroffer_foundation_flag,stress_nonimprovement_applied_flag,primary_reason_code,reason_codes,routing_evidence_status,source_m2_1_contract_row_hash,source_request_contract_row_hash,source_g2_combined_hash,policy_configuration_hash,source_snapshot_row_hash,contract_row_hash)
SELECT module1_run_id,contract_code,contract_version,schema_version,methodology_version,scenario_id,scenario_code,merchant_application_id,population_id,merchant_id,as_of_date,source_route_code,source_route_rank,pricing_disposition_code,structure_available_flag,review_required_flag,selected_candidate_template_code,selected_candidate_row_hash,requested_funding_amount,selected_funding_amount,selected_remittance_rate,selected_payback_multiple,selected_collection_horizon_days,selected_total_repayment_amount,selected_finance_charge_amount,selected_implied_daily_collection_amount,selected_implied_payoff_days,selected_amount_to_request_ratio,candidate_count,counteroffer_foundation_flag,stress_nonimprovement_applied_flag,primary_reason_code,reason_codes,routing_evidence_status,source_m2_1_contract_row_hash,source_request_contract_row_hash,source_g2_combined_hash,policy_configuration_hash,source_snapshot_row_hash,contract_row_hash FROM _m2_2_latest_expected;

DROP TABLE IF EXISTS _m2_2_archive_expected;
CREATE TEMP TABLE _m2_2_archive_expected ON COMMIT DROP AS SELECT l.module1_run_id,l.contract_code,l.contract_version,l.schema_version,l.scenario_id,l.merchant_application_id,to_jsonb(l) AS contract_payload,l.contract_row_hash,l.contract_row_hash AS source_latest_row_hash,NULL::text AS archive_row_hash FROM _m2_2_latest_expected l;
UPDATE _m2_2_archive_expected a SET archive_row_hash=msbf_ctl.m2_2_hash_jsonb(to_jsonb(a)-'archive_row_hash');
INSERT INTO msbf_m2.application_pricing_structure_archive(module1_run_id,contract_code,contract_version,schema_version,scenario_id,merchant_application_id,contract_payload,contract_row_hash,source_latest_row_hash,archive_row_hash)
SELECT module1_run_id,contract_code,contract_version,schema_version,scenario_id,merchant_application_id,contract_payload,contract_row_hash,source_latest_row_hash,archive_row_hash FROM _m2_2_archive_expected;

ANALYZE msbf_m2.application_request_structure_snapshot; ANALYZE msbf_m2.application_request_structure_latest; ANALYZE msbf_m2.application_request_structure_archive; ANALYZE msbf_m2.application_pricing_structure_candidate; ANALYZE msbf_m2.application_pricing_structure_snapshot; ANALYZE msbf_m2.application_pricing_structure_latest; ANALYZE msbf_m2.application_pricing_structure_archive;

DROP TABLE IF EXISTS _m2_2_hashes;
CREATE TEMP TABLE _m2_2_hashes ON COMMIT DROP AS SELECT
 (SELECT md5(string_agg(p.configuration_hash,'|' ORDER BY p.policy_code)) FROM msbf_ctl.m2_2_policy_profile p WHERE p.policy_code='M2_2_PRICING_STRUCTURE_POLICY_V1') AS policy_set_hash,
 (SELECT md5(string_agg(t.row_hash,'|' ORDER BY t.template_sequence,t.candidate_template_code)) FROM msbf_m2.pricing_structure_candidate_template t WHERE t.module1_run_id=(SELECT run_id FROM _m2_2_ctx)) AS template_set_hash,
 (SELECT md5(string_agg(d.row_hash,'|' ORDER BY d.reason_priority,d.reason_code)) FROM msbf_m2.pricing_structure_reason_definition d WHERE d.module1_run_id=(SELECT run_id FROM _m2_2_ctx)) AS reason_set_hash,
 (SELECT md5(string_agg(d.row_hash,'|' ORDER BY d.disposition_rank,d.disposition_code)) FROM msbf_m2.pricing_structure_disposition_definition d WHERE d.module1_run_id=(SELECT run_id FROM _m2_2_ctx)) AS disposition_set_hash,
 (SELECT md5(string_agg(x.row_hash,'|' ORDER BY x.merchant_application_id)) FROM _m2_2_request_expected x) AS request_snapshot_set_hash,
 (SELECT md5(string_agg(x.contract_row_hash,'|' ORDER BY x.merchant_application_id)) FROM _m2_2_request_latest_expected x) AS request_latest_set_hash,
 (SELECT md5(string_agg(x.archive_row_hash,'|' ORDER BY x.merchant_application_id)) FROM _m2_2_request_archive_expected x) AS request_archive_set_hash,
 (SELECT md5(string_agg(x.row_hash,'|' ORDER BY x.scenario_id,x.merchant_application_id,x.template_sequence)) FROM _m2_2_candidate_expected x) AS candidate_set_hash,
 (SELECT md5(string_agg(x.row_hash,'|' ORDER BY x.scenario_id,x.merchant_application_id)) FROM _m2_2_snapshot_expected x) AS pricing_snapshot_set_hash,
 (SELECT md5(string_agg(x.contract_row_hash,'|' ORDER BY x.scenario_id,x.merchant_application_id)) FROM _m2_2_latest_expected x) AS pricing_latest_set_hash,
 (SELECT md5(string_agg(x.archive_row_hash,'|' ORDER BY x.scenario_id,x.merchant_application_id)) FROM _m2_2_archive_expected x) AS pricing_archive_set_hash;

DROP TABLE IF EXISTS _m2_2_registry_expected;
CREATE TEMP TABLE _m2_2_registry_expected ON COMMIT DROP AS
SELECT c.run_id AS module1_run_id,'M2_REQUEST_STRUCTURE_CONSUMPTION'::text AS request_contract_code,1::integer AS request_contract_version,'M2_2_REQUEST_STRUCTURE_SCHEMA_V1'::text AS request_schema_version,'M2_PRICING_STRUCTURE_CONSUMPTION'::text AS pricing_contract_code,1::integer AS pricing_contract_version,'M2_2_PRICING_STRUCTURE_SCHEMA_V1'::text AS pricing_schema_version,'M2_2_METHOD_V1'::text AS methodology_version,'M2_ELIGIBILITY_ROUTING_CONSUMPTION'::text AS source_m2_1_contract_code,1::integer AS source_m2_1_contract_version,'M2_1_ROUTING_SCHEMA_V1'::text AS source_m2_1_schema_version,'e5ace7f32060ffb191c7bd0f8dd0c863'::text AS source_m2_1_combined_hash,'M1_3_APPLICATION_REQUEST'::text AS source_m1_3_gate_id,'01485256b9b5748fb412743d35ced602'::text AS source_m1_3_application_hash,c.configuration_hash AS policy_configuration_hash,
1::bigint AS policy_rows,5::bigint AS template_rows,18::bigint AS reason_rows,4::bigint AS disposition_rows,750::bigint AS request_snapshot_rows,750::bigint AS request_latest_rows,750::bigint AS request_archive_rows,557::bigint AS candidate_rows,1500::bigint AS pricing_snapshot_rows,1500::bigint AS pricing_latest_rows,1500::bigint AS pricing_archive_rows,750::bigint AS comparison_rows,7336::bigint AS canonical_entities,h.policy_set_hash,h.template_set_hash,h.reason_set_hash,h.disposition_set_hash,h.request_snapshot_set_hash,h.request_latest_set_hash,h.request_archive_set_hash,h.candidate_set_hash,h.pricing_snapshot_set_hash,h.pricing_latest_set_hash,h.pricing_archive_set_hash,md5(h.request_latest_set_hash||'|'||h.request_archive_set_hash) AS request_contract_set_hash,md5(h.pricing_latest_set_hash||'|'||h.pricing_archive_set_hash) AS pricing_contract_set_hash,NULL::text AS combined_set_hash,'GENERATED'::text AS contract_status,NULL::text AS row_hash
FROM _m2_2_ctx c CROSS JOIN _m2_2_hashes h;
UPDATE _m2_2_registry_expected r SET row_hash=msbf_ctl.m2_2_hash_jsonb(to_jsonb(r)-'row_hash'-'combined_set_hash'-'contract_status');

DROP TABLE IF EXISTS _m2_2_canonical;
CREATE TEMP TABLE _m2_2_canonical(entity_type text,entity_key text,row_hash text,PRIMARY KEY(entity_type,entity_key)) ON COMMIT DROP;
INSERT INTO _m2_2_canonical
SELECT 'POLICY',p.policy_code,p.configuration_hash FROM msbf_ctl.m2_2_policy_profile p WHERE p.policy_code='M2_2_PRICING_STRUCTURE_POLICY_V1' UNION ALL
SELECT 'TEMPLATE',t.candidate_template_code,t.row_hash FROM msbf_m2.pricing_structure_candidate_template t WHERE t.module1_run_id=(SELECT run_id FROM _m2_2_ctx) UNION ALL
SELECT 'REASON',d.reason_code,d.row_hash FROM msbf_m2.pricing_structure_reason_definition d WHERE d.module1_run_id=(SELECT run_id FROM _m2_2_ctx) UNION ALL
SELECT 'DISPOSITION',d.disposition_code,d.row_hash FROM msbf_m2.pricing_structure_disposition_definition d WHERE d.module1_run_id=(SELECT run_id FROM _m2_2_ctx) UNION ALL
SELECT 'REQUEST_SNAPSHOT',x.merchant_application_id,x.row_hash FROM _m2_2_request_expected x UNION ALL
SELECT 'REQUEST_LATEST',x.merchant_application_id,x.contract_row_hash FROM _m2_2_request_latest_expected x UNION ALL
SELECT 'REQUEST_ARCHIVE',x.merchant_application_id,x.archive_row_hash FROM _m2_2_request_archive_expected x UNION ALL
SELECT 'CANDIDATE',x.scenario_id::text||'|'||x.merchant_application_id||'|'||x.candidate_template_code,x.row_hash FROM _m2_2_candidate_expected x UNION ALL
SELECT 'PRICING_SNAPSHOT',x.scenario_id::text||'|'||x.merchant_application_id,x.row_hash FROM _m2_2_snapshot_expected x UNION ALL
SELECT 'PRICING_LATEST',x.scenario_id::text||'|'||x.merchant_application_id,x.contract_row_hash FROM _m2_2_latest_expected x UNION ALL
SELECT 'PRICING_ARCHIVE',x.scenario_id::text||'|'||x.merchant_application_id,x.archive_row_hash FROM _m2_2_archive_expected x UNION ALL
SELECT 'REGISTRY',r.pricing_contract_code||'|v'||r.pricing_contract_version,r.row_hash FROM _m2_2_registry_expected r;
CREATE INDEX ON _m2_2_canonical(entity_type,entity_key); ANALYZE _m2_2_canonical;
UPDATE _m2_2_registry_expected r SET combined_set_hash=(SELECT md5(string_agg(entity_type||'|'||entity_key||'|'||row_hash,'|' ORDER BY entity_type,entity_key)) FROM _m2_2_canonical);

INSERT INTO msbf_ctl.m2_2_pricing_structure_contract_registry(module1_run_id,request_contract_code,request_contract_version,request_schema_version,pricing_contract_code,pricing_contract_version,pricing_schema_version,methodology_version,source_m2_1_contract_code,source_m2_1_contract_version,source_m2_1_schema_version,source_m2_1_combined_hash,source_m1_3_gate_id,source_m1_3_application_hash,policy_configuration_hash,policy_rows,template_rows,reason_rows,disposition_rows,request_snapshot_rows,request_latest_rows,request_archive_rows,candidate_rows,pricing_snapshot_rows,pricing_latest_rows,pricing_archive_rows,comparison_rows,canonical_entities,policy_set_hash,template_set_hash,reason_set_hash,disposition_set_hash,request_snapshot_set_hash,request_latest_set_hash,request_archive_set_hash,candidate_set_hash,pricing_snapshot_set_hash,pricing_latest_set_hash,pricing_archive_set_hash,request_contract_set_hash,pricing_contract_set_hash,combined_set_hash,contract_status,generated_at,row_hash)
SELECT module1_run_id,request_contract_code,request_contract_version,request_schema_version,pricing_contract_code,pricing_contract_version,pricing_schema_version,methodology_version,source_m2_1_contract_code,source_m2_1_contract_version,source_m2_1_schema_version,source_m2_1_combined_hash,source_m1_3_gate_id,source_m1_3_application_hash,policy_configuration_hash,policy_rows,template_rows,reason_rows,disposition_rows,request_snapshot_rows,request_latest_rows,request_archive_rows,candidate_rows,pricing_snapshot_rows,pricing_latest_rows,pricing_archive_rows,comparison_rows,canonical_entities,policy_set_hash,template_set_hash,reason_set_hash,disposition_set_hash,request_snapshot_set_hash,request_latest_set_hash,request_archive_set_hash,candidate_set_hash,pricing_snapshot_set_hash,pricing_latest_set_hash,pricing_archive_set_hash,request_contract_set_hash,pricing_contract_set_hash,combined_set_hash,contract_status,clock_timestamp(),row_hash FROM _m2_2_registry_expected;

/* --------------------------------------------------------------------------
Physical-row reconciliation

The family-level counts are included in the failure message so a future
reconciliation defect is immediately localized.
-------------------------------------------------------------------------- */
DROP TABLE IF EXISTS _m2_2_mismatch;

CREATE TEMP TABLE _m2_2_mismatch
ON COMMIT DROP
AS
SELECT
    'REQUEST_SNAPSHOT'::text AS entity_type,
    x.merchant_application_id AS entity_key,
    x.row_hash AS stored_hash,
    msbf_ctl.m2_2_hash_jsonb(
        to_jsonb(x) - 'row_hash' - 'created_at'
    ) AS reconstructed_hash
FROM msbf_m2.application_request_structure_snapshot AS x
WHERE x.module1_run_id = (SELECT run_id FROM _m2_2_ctx)
  AND x.row_hash IS DISTINCT FROM
      msbf_ctl.m2_2_hash_jsonb(
          to_jsonb(x) - 'row_hash' - 'created_at'
      )

UNION ALL

SELECT
    'CANDIDATE',
    x.scenario_id::text || '|' ||
        x.merchant_application_id || '|' ||
        x.candidate_template_code,
    x.row_hash,
    msbf_ctl.m2_2_hash_jsonb(
        to_jsonb(x) - 'row_hash' - 'created_at'
    )
FROM msbf_m2.application_pricing_structure_candidate AS x
WHERE x.module1_run_id = (SELECT run_id FROM _m2_2_ctx)
  AND x.row_hash IS DISTINCT FROM
      msbf_ctl.m2_2_hash_jsonb(
          to_jsonb(x) - 'row_hash' - 'created_at'
      )

UNION ALL

SELECT
    'PRICING_SNAPSHOT',
    x.scenario_id::text || '|' || x.merchant_application_id,
    x.row_hash,
    msbf_ctl.m2_2_hash_jsonb(
        to_jsonb(x) - 'row_hash' - 'created_at'
    )
FROM msbf_m2.application_pricing_structure_snapshot AS x
WHERE x.module1_run_id = (SELECT run_id FROM _m2_2_ctx)
  AND x.row_hash IS DISTINCT FROM
      msbf_ctl.m2_2_hash_jsonb(
          to_jsonb(x) - 'row_hash' - 'created_at'
      );

DO $reconcile$
DECLARE
    v_canonical bigint;
    v_mismatches bigint;
    v_candidates bigint;
    v_comparisons bigint;
    v_request_mismatches bigint;
    v_candidate_mismatches bigint;
    v_snapshot_mismatches bigint;
BEGIN
    SELECT count(*)
    INTO v_canonical
    FROM _m2_2_canonical;

    SELECT
        count(*),
        count(*) FILTER (
            WHERE entity_type = 'REQUEST_SNAPSHOT'
        ),
        count(*) FILTER (
            WHERE entity_type = 'CANDIDATE'
        ),
        count(*) FILTER (
            WHERE entity_type = 'PRICING_SNAPSHOT'
        )
    INTO
        v_mismatches,
        v_request_mismatches,
        v_candidate_mismatches,
        v_snapshot_mismatches
    FROM _m2_2_mismatch;

    SELECT count(*)
    INTO v_candidates
    FROM _m2_2_candidate_expected;

    SELECT count(*)
    INTO v_comparisons
    FROM msbf_m2.v_m2_2_matched_scenario_comparison
    WHERE module1_run_id = (SELECT run_id FROM _m2_2_ctx);

    IF v_canonical <> 7336
       OR v_mismatches <> 0
       OR v_candidates <> 557
       OR v_comparisons <> 750 THEN
        RAISE EXCEPTION
            'M2.2 reconciliation failed: canonical %, mismatches % '
            '(request %, candidate %, pricing_snapshot %), candidates %, '
            'comparisons %.',
            v_canonical,
            v_mismatches,
            v_request_mismatches,
            v_candidate_mismatches,
            v_snapshot_mismatches,
            v_candidates,
            v_comparisons;
    END IF;

    PERFORM msbf_ctl.m2_2_assert_stress_nonimprovement(
        (SELECT run_id FROM _m2_2_ctx)
    );
END;
$reconcile$;

DROP TABLE IF EXISTS _m2_2_generation_evidence;
CREATE TEMP TABLE _m2_2_generation_evidence(evidence_code text,metric_name text,metric_value_numeric numeric(24,10),metric_value_text text,unit_code text,interpretation text,CHECK(num_nonnulls(metric_value_numeric,metric_value_text)=1)) ON COMMIT DROP;
INSERT INTO _m2_2_generation_evidence VALUES
('M2_2_POLICY_SET_HASH','POLICY_SET_HASH',NULL,(SELECT policy_set_hash FROM _m2_2_hashes),'HASH','Policy set hash.'),
('M2_2_TEMPLATE_SET_HASH','TEMPLATE_SET_HASH',NULL,(SELECT template_set_hash FROM _m2_2_hashes),'HASH','Template set hash.'),
('M2_2_REASON_SET_HASH','REASON_SET_HASH',NULL,(SELECT reason_set_hash FROM _m2_2_hashes),'HASH','Reason set hash.'),
('M2_2_DISPOSITION_SET_HASH','DISPOSITION_SET_HASH',NULL,(SELECT disposition_set_hash FROM _m2_2_hashes),'HASH','Disposition set hash.'),
('M2_2_REQUEST_SNAPSHOT_SET_HASH','REQUEST_SNAPSHOT_SET_HASH',NULL,(SELECT request_snapshot_set_hash FROM _m2_2_hashes),'HASH','Request snapshot set hash.'),
('M2_2_REQUEST_LATEST_SET_HASH','REQUEST_LATEST_SET_HASH',NULL,(SELECT request_latest_set_hash FROM _m2_2_hashes),'HASH','Request latest set hash.'),
('M2_2_REQUEST_ARCHIVE_SET_HASH','REQUEST_ARCHIVE_SET_HASH',NULL,(SELECT request_archive_set_hash FROM _m2_2_hashes),'HASH','Request archive set hash.'),
('M2_2_CANDIDATE_SET_HASH','CANDIDATE_SET_HASH',NULL,(SELECT candidate_set_hash FROM _m2_2_hashes),'HASH','Candidate set hash.'),
('M2_2_PRICING_SNAPSHOT_SET_HASH','PRICING_SNAPSHOT_SET_HASH',NULL,(SELECT pricing_snapshot_set_hash FROM _m2_2_hashes),'HASH','Pricing snapshot set hash.'),
('M2_2_PRICING_LATEST_SET_HASH','PRICING_LATEST_SET_HASH',NULL,(SELECT pricing_latest_set_hash FROM _m2_2_hashes),'HASH','Pricing latest set hash.'),
('M2_2_PRICING_ARCHIVE_SET_HASH','PRICING_ARCHIVE_SET_HASH',NULL,(SELECT pricing_archive_set_hash FROM _m2_2_hashes),'HASH','Pricing archive set hash.'),
('M2_2_REQUEST_CONTRACT_SET_HASH','REQUEST_CONTRACT_SET_HASH',NULL,(SELECT request_contract_set_hash FROM _m2_2_registry_expected),'HASH','Request contract set hash.'),
('M2_2_PRICING_CONTRACT_SET_HASH','PRICING_CONTRACT_SET_HASH',NULL,(SELECT pricing_contract_set_hash FROM _m2_2_registry_expected),'HASH','Pricing contract set hash.'),
('M2_2_COMBINED_SET_HASH','COMBINED_SET_HASH',NULL,(SELECT combined_set_hash FROM _m2_2_registry_expected),'HASH','Combined canonical set hash.'),
('M2_2_REQUEST_ROWS','REQUEST_ROWS',750,NULL,'ROWS','Request rows.'),
('M2_2_CANDIDATE_ROWS','CANDIDATE_ROWS',557,NULL,'ROWS','Candidate rows.'),
('M2_2_PRICING_ROWS','PRICING_ROWS',1500,NULL,'ROWS','Pricing rows.'),
('M2_2_COMPARISON_ROWS','COMPARISON_ROWS',750,NULL,'ROWS','Matched comparison rows.'),
('M2_2_CANONICAL_ENTITIES','CANONICAL_ENTITIES',7336,NULL,'ROWS','Canonical entities.'),
('M2_2_ROW_LEVEL_MISMATCHES','ROW_LEVEL_MISMATCHES',0,NULL,'ROWS','Row-level deterministic mismatches.');
INSERT INTO msbf_ctl.run_evidence(run_id,evidence_code,segment_key,metric_name,metric_value_numeric,metric_value_text,unit_code,status,interpretation)
SELECT (SELECT run_id FROM _m2_2_ctx),evidence_code,'PORTFOLIO',metric_name,metric_value_numeric,metric_value_text,unit_code,'PASS',interpretation FROM _m2_2_generation_evidence;
UPDATE msbf_ctl.run_registry SET run_status='M2_2_GENERATED',notes=coalesce(notes,'')||' | M2.2 pricing, structure and counteroffer foundations generated.' WHERE run_id=(SELECT run_id FROM _m2_2_ctx);
INSERT INTO _m2_2_result SELECT c.run_id,'M2_2_GENERATED',1,5,18,4,750,750,750,557,1500,1500,1500,750,7336,(SELECT count(*) FROM _m2_2_canonical),(SELECT count(*) FROM _m2_2_mismatch),h.policy_set_hash,h.template_set_hash,h.reason_set_hash,h.disposition_set_hash,h.request_snapshot_set_hash,h.request_latest_set_hash,h.request_archive_set_hash,h.candidate_set_hash,h.pricing_snapshot_set_hash,h.pricing_latest_set_hash,h.pricing_archive_set_hash,r.request_contract_set_hash,r.pricing_contract_set_hash,r.combined_set_hash,'PASS' FROM _m2_2_ctx c CROSS JOIN _m2_2_hashes h CROSS JOIN _m2_2_registry_expected r;
COMMIT;

SELECT
    result.*,
    stress_floor.matched_selected_structure_rows,
    stress_floor.eligible_to_review_transition_rows,
    stress_floor.pre_floor_improvement_rows,
    stress_floor.pre_floor_amount_improvement_rows,
    stress_floor.pre_floor_remittance_improvement_rows,
    stress_floor.pre_floor_payback_improvement_rows,
    stress_floor.pre_floor_horizon_improvement_rows,
    stress_floor.stress_floor_applied_rows,
    stress_floor.post_floor_improvement_rows

FROM _m2_2_result AS result

CROSS JOIN _m2_2_stress_floor_summary AS stress_floor;
