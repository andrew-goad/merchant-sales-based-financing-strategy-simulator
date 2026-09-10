from __future__ import annotations
import hashlib, json, re

POLICY = {
    'policy_code': 'R26_M2_5_MONITORING_CALIBRATION_POLICY_V2',
    'policy_version': 2,
    'daily_monitoring_start': 'FIRST_EXPECTED_REMITTANCE',
    'pace_expected_basis_code': 'SELECTED_TOTAL_REPAYMENT_DIVIDED_BY_SELECTED_HORIZON',
    'pace_watch_eligibility_day': 21,
    'pace_adverse_eligibility_day': 30,
    'pace_persistence_days': 3,
    'watch_pace_ratio': '0.900000',
    'underperforming_pace_ratio': '0.750000',
    'severe_pace_ratio': '0.500000',
    'underperforming_no_remittance_days': 7,
    'dormant_no_remittance_days': 14,
    'severe_zero_sales_streak_days': 10,
    'preserve_early_hard_triggers': ['NO_REMITTANCE','ZERO_SALES','LIQUIDITY','HORIZON_OVERRUN'],
    'preserved_hard_trigger_status_eligibility': {'liquidity_watch_day':7,'no_remittance_adverse_day':14,'zero_sales_severe_day':14,'horizon_overrun_severe_day':14},
    'raw_signal_preservation': True,
    'operational_alert_families': ['PACE','NO_REMITTANCE','SALES_DORMANCY','LIQUIDITY','HORIZON'],
    'owner_authority': 'APPROVED_2026-09-01',
}
POLICY_JSON = json.dumps(POLICY, sort_keys=True, separators=(',', ':'))
POLICY_SHA256 = hashlib.sha256(POLICY_JSON.encode('utf-8')).hexdigest()


def _once(text: str, old: str, new: str, label: str) -> str:
    n = text.count(old)
    if n != 1:
        raise RuntimeError(f'R26 patch anchor {label} expected once, found {n}')
    return text.replace(old, new, 1)


def patch_schema(sql: str) -> str:
    # Keep the legacy M2.5 contract identity as the compatibility carrier, but make
    # its parameter row accurately describe the R26 policy. The authoritative
    # successor identity is separately persisted in r26_m2_5_policy_overlay.
    replacements = [
        ('7::integer AS watch_start_day,', '21::integer AS watch_start_day,', 'seed watch day'),
        ('14::integer AS underperforming_start_day,', '30::integer AS underperforming_start_day,', 'seed underperforming day'),
        ('14::integer AS severe_start_day,', '30::integer AS severe_start_day,', 'seed severe day'),
        ("'watch_start_day', 7,", "'watch_start_day', 21,", 'payload watch day'),
        ("'underperforming_start_day', 14,", "'underperforming_start_day', 30,", 'payload underperforming day'),
        ("'severe_start_day', 14,", "'severe_start_day', 30,", 'payload severe day'),
        ('OR v.watch_start_day <> 7', 'OR v.watch_start_day <> 21', 'assert watch day'),
        ('OR v.underperforming_start_day <> 14', 'OR v.underperforming_start_day <> 30', 'assert underperforming day'),
        ('OR v.severe_start_day <> 14', 'OR v.severe_start_day <> 30', 'assert severe day'),
    ]
    for old,new,label in replacements:
        sql=_once(sql,old,new,label)

    extension = f"""

/* ============================================================================
R26 successor policy overlay and operational alert-family layer.
The legacy M2.5 contract objects remain the compatibility carrier; this overlay
is the authoritative policy/version record for the R26 successor correction.
============================================================================ */
CREATE TABLE IF NOT EXISTS msbf_m12r1e.r26_m2_5_policy_overlay
(
    module1_run_id bigint PRIMARY KEY,
    overlay_policy_code text NOT NULL,
    overlay_policy_version integer NOT NULL,
    overlay_status text NOT NULL,
    daily_monitoring_start_code text NOT NULL,
    pace_expected_basis_code text NOT NULL,
    pace_watch_eligibility_day integer NOT NULL,
    pace_adverse_eligibility_day integer NOT NULL,
    pace_persistence_days integer NOT NULL,
    watch_pace_ratio numeric(9,6) NOT NULL,
    underperforming_pace_ratio numeric(9,6) NOT NULL,
    severe_pace_ratio numeric(9,6) NOT NULL,
    preserve_early_no_remittance_flag boolean NOT NULL,
    preserve_early_zero_sales_flag boolean NOT NULL,
    preserve_early_liquidity_flag boolean NOT NULL,
    preserve_early_horizon_overrun_flag boolean NOT NULL,
    raw_signal_preservation_flag boolean NOT NULL,
    operational_family_separation_flag boolean NOT NULL,
    owner_authority text NOT NULL,
    policy_payload jsonb NOT NULL,
    policy_sha256 text NOT NULL,
    source_m2_4_combined_hash text NOT NULL,
    successor_m2_5_combined_hash text,
    created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT ck_r26_m2_5_overlay_identity CHECK
    (
      overlay_policy_code='R26_M2_5_MONITORING_CALIBRATION_POLICY_V2'
      AND overlay_policy_version=2
      AND overlay_status='APPROVED'
      AND daily_monitoring_start_code='FIRST_EXPECTED_REMITTANCE'
      AND pace_expected_basis_code='SELECTED_TOTAL_REPAYMENT_DIVIDED_BY_SELECTED_HORIZON'
      AND pace_watch_eligibility_day=21
      AND pace_adverse_eligibility_day=30
      AND pace_persistence_days=3
      AND raw_signal_preservation_flag
      AND operational_family_separation_flag
    ),
    CONSTRAINT ck_r26_m2_5_overlay_sha CHECK (policy_sha256 ~ '^[0-9a-f]{{64}}$')
);

INSERT INTO msbf_m12r1e.r26_m2_5_policy_overlay
(
 module1_run_id,overlay_policy_code,overlay_policy_version,overlay_status,
 daily_monitoring_start_code,pace_expected_basis_code,pace_watch_eligibility_day,
 pace_adverse_eligibility_day,pace_persistence_days,watch_pace_ratio,
 underperforming_pace_ratio,severe_pace_ratio,preserve_early_no_remittance_flag,
 preserve_early_zero_sales_flag,preserve_early_liquidity_flag,preserve_early_horizon_overrun_flag,
 raw_signal_preservation_flag,operational_family_separation_flag,owner_authority,
 policy_payload,policy_sha256,source_m2_4_combined_hash
)
SELECT
 policy.module1_run_id,
 'R26_M2_5_MONITORING_CALIBRATION_POLICY_V2',2,'APPROVED',
 'FIRST_EXPECTED_REMITTANCE','SELECTED_TOTAL_REPAYMENT_DIVIDED_BY_SELECTED_HORIZON',
 21,30,3,0.900000,0.750000,0.500000,TRUE,TRUE,TRUE,TRUE,TRUE,TRUE,
 'OWNER_APPROVED_2026_09_01',
 '{POLICY_JSON}'::jsonb,
 '{POLICY_SHA256}',
 policy.source_m2_4_combined_hash
FROM msbf_ctl.m2_5_policy_profile policy
ON CONFLICT(module1_run_id) DO NOTHING;

CREATE TABLE IF NOT EXISTS msbf_m2.monitoring_operational_alert_family_daily
(
 module1_run_id bigint NOT NULL,
 scenario_id bigint NOT NULL,
 scenario_code text NOT NULL,
 merchant_application_id text NOT NULL,
 synthetic_advance_id text NOT NULL,
 monitoring_day_index integer NOT NULL,
 monitoring_date date NOT NULL,
 raw_alert_condition_count integer NOT NULL,
 pace_family_active_flag boolean NOT NULL,
 pace_family_severity_code text NOT NULL,
 no_remittance_family_active_flag boolean NOT NULL,
 sales_dormancy_family_active_flag boolean NOT NULL,
 liquidity_family_active_flag boolean NOT NULL,
 horizon_family_active_flag boolean NOT NULL,
 operational_alert_family_count integer NOT NULL,
 primary_operational_alert_family_code text NOT NULL,
 operational_alert_payload jsonb NOT NULL,
 source_daily_row_hash text NOT NULL,
 policy_sha256 text NOT NULL,
 row_hash text NOT NULL,
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 PRIMARY KEY(module1_run_id,scenario_id,merchant_application_id,monitoring_day_index),
 CONSTRAINT ck_r26_operational_family_count CHECK (operational_alert_family_count BETWEEN 0 AND 5),
 CONSTRAINT ck_r26_raw_condition_count CHECK (raw_alert_condition_count BETWEEN 0 AND 6),
 CONSTRAINT ck_r26_operational_policy_sha CHECK (policy_sha256 ~ '^[0-9a-f]{{64}}$')
);

CREATE INDEX IF NOT EXISTS ix_r26_operational_alert_family_day
ON msbf_m2.monitoring_operational_alert_family_daily
(module1_run_id,scenario_code,monitoring_day_index,operational_alert_family_count);

CREATE OR REPLACE VIEW msbf_m2.v_m2_5_power_bi_daily_monitoring_r26 AS
SELECT
 d.module1_run_id,d.scenario_code,d.merchant_application_id,d.synthetic_advance_id,
 d.monitoring_day_index,d.monitoring_date,d.source_eligible_pos_sales,d.actual_remittance_amount,
 d.cumulative_remittance_amount,d.receivable_balance_after,d.principal_exposure_proxy,
 d.cumulative_shortfall_amount,d.cumulative_pace_ratio,d.monitoring_status_code,
 d.stress_status_floor_applied_flag,d.daily_shortfall_alert_flag,d.cumulative_pace_watch_alert_flag,
 d.cumulative_pace_high_alert_flag,d.zero_sales_streak_alert_flag,d.liquidity_stress_alert_flag,
 d.horizon_overrun_alert_flag,d.paid_off_flag,
 o.raw_alert_condition_count,o.pace_family_active_flag,o.pace_family_severity_code,
 o.no_remittance_family_active_flag,o.sales_dormancy_family_active_flag,
 o.liquidity_family_active_flag,o.horizon_family_active_flag,o.operational_alert_family_count,
 o.primary_operational_alert_family_code,o.operational_alert_payload,o.policy_sha256 AS r26_policy_sha256
FROM msbf_m2.advance_daily_remittance_monitoring d
LEFT JOIN msbf_m2.monitoring_operational_alert_family_daily o
  ON o.module1_run_id=d.module1_run_id
 AND o.scenario_id=d.scenario_id
 AND o.merchant_application_id=d.merchant_application_id
 AND o.monitoring_day_index=d.monitoring_day_index;
"""
    return sql.rstrip()+extension+'\n'


def patch_generation(sql: str) -> str:
    # Expected payoff pace: selected total repayment / selected horizon.
    old_due = """least
    (
        windows.implied_daily_collection_amount,
        greatest
        (
            windows.total_repayment_amount - windows.cumulative_raw_before,
            0
        )
    )::numeric(18,2) AS expected_due_today_amount,"""
    new_due = """least
    (
        round(windows.total_repayment_amount / nullif(windows.collection_horizon_days,0), 2),
        greatest
        (
            windows.total_repayment_amount - windows.cumulative_raw_before,
            0
        )
    )::numeric(18,2) AS expected_due_today_amount,"""
    sql=_once(sql,old_due,new_due,'expected due basis')

    old_cum = """least
    (
        windows.implied_daily_collection_amount * windows.monitoring_day_index,
        windows.total_repayment_amount
    )::numeric(18,2) AS cumulative_expected_remittance_amount"""
    new_cum = """least
    (
        round
        (
            (windows.total_repayment_amount / nullif(windows.collection_horizon_days,0)) *
            windows.monitoring_day_index,
            2
        ),
        windows.total_repayment_amount
    )::numeric(18,2) AS cumulative_expected_remittance_amount"""
    sql=_once(sql,old_cum,new_cum,'cumulative expected basis')

    # Persist the same horizon-based daily expectation in the governed daily table.
    sql=_once(sql,
        '    floor.implied_daily_collection_amount,\n    floor.expected_due_today_amount,',
        '    round(floor.total_repayment_amount / nullif(floor.collection_horizon_days,0), 2)::numeric(18,2),\n    floor.expected_due_today_amount,',
        'daily expected amount persistence')

    # Add two lagged pace observations to the activity relation used for status classification.
    old_from='FROM _m2_5_daily_activity AS activity;'
    new_from="""FROM
(
    SELECT
        a.*,
        lag(a.cumulative_pace_ratio,1) OVER
        (PARTITION BY a.module1_run_id,a.scenario_id,a.merchant_application_id ORDER BY a.monitoring_day_index)
            AS r26_pace_lag_1,
        lag(a.cumulative_pace_ratio,2) OVER
        (PARTITION BY a.module1_run_id,a.scenario_id,a.merchant_application_id ORDER BY a.monitoring_day_index)
            AS r26_pace_lag_2
    FROM _m2_5_daily_activity AS a
) AS activity;"""
    sql=_once(sql,old_from,new_from,'pace lag source')

    old_case="""CASE
        WHEN activity.receivable_balance_after = 0 THEN 0
        WHEN activity.monitoring_day_index >= 14
         AND activity.days_since_last_positive_remittance >= 14 THEN 5
        WHEN activity.monitoring_day_index >= 14
         AND
         (
             activity.cumulative_pace_ratio < 0.50000000
             OR activity.zero_sales_streak_days >= 10
             OR
             (
                 activity.monitoring_day_index > activity.collection_horizon_days
                 AND activity.receivable_balance_after > 0
             )
         ) THEN 4
        WHEN activity.monitoring_day_index >= 14
         AND
         (
             activity.cumulative_pace_ratio < 0.75000000
             OR activity.days_since_last_positive_remittance >= 7
         ) THEN 3
        WHEN activity.monitoring_day_index >= 7
         AND
         (
             activity.cumulative_pace_ratio < 0.90000000
             OR activity.remittance_coverage_ratio < 0.75000000
             OR activity.available_balance < 0
             OR activity.nsf_count > 0
             OR activity.negative_balance_flag
         ) THEN 2
        ELSE 1
    END::integer AS raw_monitoring_status_rank"""
    new_case="""CASE
        WHEN activity.receivable_balance_after = 0 THEN 0

        /* Hard no-remittance trigger remains available during seasoning. */
        WHEN activity.monitoring_day_index >= 14
         AND activity.days_since_last_positive_remittance >= 14 THEN 5

        /* Severe hard triggers remain immediate; pace-only severe waits for day 30
           eligibility plus three consecutive eligible-day breaches (first day 32). */
        WHEN (activity.monitoring_day_index >= 14 AND activity.zero_sales_streak_days >= 10)
          OR (activity.monitoring_day_index >= 14
              AND activity.monitoring_day_index > activity.collection_horizon_days
              AND activity.receivable_balance_after > 0)
          OR (
              activity.monitoring_day_index >= 32
              AND activity.cumulative_pace_ratio < 0.50000000
              AND activity.r26_pace_lag_1 < 0.50000000
              AND activity.r26_pace_lag_2 < 0.50000000
          ) THEN 4

        /* Seven-day no-remittance is preserved as an early adverse hard trigger;
           pace-only underperformance waits for day 30 + three-day persistence. */
        WHEN (activity.monitoring_day_index >= 14
              AND activity.days_since_last_positive_remittance >= 7)
          OR (
              activity.monitoring_day_index >= 32
              AND activity.cumulative_pace_ratio < 0.75000000
              AND activity.r26_pace_lag_1 < 0.75000000
              AND activity.r26_pace_lag_2 < 0.75000000
          ) THEN 3

        /* Liquidity remains an early hard trigger. Pace WATCH becomes persistent
           only after day-21 eligibility, therefore first qualifies on day 23. */
        WHEN (activity.monitoring_day_index >= 7
              AND (activity.available_balance < 0
                   OR activity.nsf_count > 0
                   OR activity.negative_balance_flag))
          OR (
              activity.monitoring_day_index >= 23
              AND activity.cumulative_pace_ratio < 0.90000000
              AND activity.r26_pace_lag_1 < 0.90000000
              AND activity.r26_pace_lag_2 < 0.90000000
          ) THEN 2
        ELSE 1
    END::integer AS raw_monitoring_status_rank"""
    sql=_once(sql,old_case,new_case,'R26 status classification')

    append=f"""

/* ============================================================================
R26 operational alert-family materialization. Raw M2.5 condition flags remain
unchanged; this table supplies non-overlapping operational-family semantics.
============================================================================ */
TRUNCATE TABLE msbf_m2.monitoring_operational_alert_family_daily;

WITH lagged AS
(
 SELECT d.*,
   lag(d.cumulative_pace_ratio,1) OVER
    (PARTITION BY d.module1_run_id,d.scenario_id,d.merchant_application_id ORDER BY d.monitoring_day_index) AS pace_lag_1,
   lag(d.cumulative_pace_ratio,2) OVER
    (PARTITION BY d.module1_run_id,d.scenario_id,d.merchant_application_id ORDER BY d.monitoring_day_index) AS pace_lag_2
 FROM msbf_m2.advance_daily_remittance_monitoring d
), flags AS
(
 SELECT l.*,
   (NOT l.paid_off_flag AND l.monitoring_day_index>=23 AND l.cumulative_pace_ratio<0.90000000
      AND l.pace_lag_1<0.90000000 AND l.pace_lag_2<0.90000000) AS pace_family,
   CASE
     WHEN NOT l.paid_off_flag AND l.monitoring_day_index>=32 AND l.cumulative_pace_ratio<0.50000000
       AND l.pace_lag_1<0.50000000 AND l.pace_lag_2<0.50000000 THEN 'SEVERE'
     WHEN NOT l.paid_off_flag AND l.monitoring_day_index>=32 AND l.cumulative_pace_ratio<0.75000000
       AND l.pace_lag_1<0.75000000 AND l.pace_lag_2<0.75000000 THEN 'UNDERPERFORMING'
     WHEN NOT l.paid_off_flag AND l.monitoring_day_index>=23 AND l.cumulative_pace_ratio<0.90000000
       AND l.pace_lag_1<0.90000000 AND l.pace_lag_2<0.90000000 THEN 'WATCH'
     ELSE 'NONE'
   END AS pace_severity,
   (NOT l.paid_off_flag AND l.monitoring_day_index>=14 AND l.days_since_last_positive_remittance>=7) AS no_remit_family,
   (NOT l.paid_off_flag AND l.monitoring_day_index>=14 AND l.zero_sales_streak_days>=10) AS sales_dormancy_family,
   (NOT l.paid_off_flag AND l.monitoring_day_index>=7
      AND (l.source_available_balance<0 OR l.source_nsf_count>0 OR l.source_negative_balance_flag)) AS liquidity_family,
   (NOT l.paid_off_flag AND l.monitoring_day_index>=14 AND l.horizon_overrun_alert_flag) AS horizon_family
 FROM lagged l
), payload AS
(
 SELECT f.*,
   (f.daily_shortfall_alert_flag::integer + f.cumulative_pace_watch_alert_flag::integer +
    f.cumulative_pace_high_alert_flag::integer + f.zero_sales_streak_alert_flag::integer +
    f.liquidity_stress_alert_flag::integer + f.horizon_overrun_alert_flag::integer) AS raw_count,
   (f.pace_family::integer + f.no_remit_family::integer + f.sales_dormancy_family::integer +
    f.liquidity_family::integer + f.horizon_family::integer) AS family_count
 FROM flags f
)
INSERT INTO msbf_m2.monitoring_operational_alert_family_daily
(
 module1_run_id,scenario_id,scenario_code,merchant_application_id,synthetic_advance_id,
 monitoring_day_index,monitoring_date,raw_alert_condition_count,pace_family_active_flag,
 pace_family_severity_code,no_remittance_family_active_flag,sales_dormancy_family_active_flag,
 liquidity_family_active_flag,horizon_family_active_flag,operational_alert_family_count,
 primary_operational_alert_family_code,operational_alert_payload,source_daily_row_hash,policy_sha256,row_hash
)
SELECT
 p.module1_run_id,p.scenario_id,p.scenario_code,p.merchant_application_id,p.synthetic_advance_id,
 p.monitoring_day_index,p.monitoring_date,p.raw_count,p.pace_family,p.pace_severity,p.no_remit_family,
 p.sales_dormancy_family,p.liquidity_family,p.horizon_family,p.family_count,
 CASE WHEN p.horizon_family THEN 'HORIZON'
      WHEN p.liquidity_family THEN 'LIQUIDITY'
      WHEN p.sales_dormancy_family THEN 'SALES_DORMANCY'
      WHEN p.no_remit_family THEN 'NO_REMITTANCE'
      WHEN p.pace_family THEN 'PACE'
      ELSE 'NONE' END,
 jsonb_build_object('pace',p.pace_family,'pace_severity',p.pace_severity,
   'no_remittance',p.no_remit_family,'sales_dormancy',p.sales_dormancy_family,
   'liquidity',p.liquidity_family,'horizon',p.horizon_family,
   'raw_condition_count',p.raw_count,'operational_family_count',p.family_count),
 p.row_hash,'{POLICY_SHA256}',
 msbf_ctl.m2_5_hash_jsonb(jsonb_build_object(
   'module1_run_id',p.module1_run_id,'scenario_id',p.scenario_id,
   'merchant_application_id',p.merchant_application_id,'monitoring_day_index',p.monitoring_day_index,
   'raw_count',p.raw_count,'pace_family',p.pace_family,'pace_severity',p.pace_severity,
   'no_remit_family',p.no_remit_family,'sales_dormancy_family',p.sales_dormancy_family,
   'liquidity_family',p.liquidity_family,'horizon_family',p.horizon_family,
   'family_count',p.family_count,'source_daily_row_hash',p.row_hash,'policy_sha256','{POLICY_SHA256}'))
FROM payload p;

UPDATE msbf_m12r1e.r26_m2_5_policy_overlay o
SET successor_m2_5_combined_hash=r.combined_set_hash
FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry r
WHERE r.module1_run_id=o.module1_run_id;
"""
    return sql.rstrip()+append+'\n'


def overlay_payload(stage: str, base_payload):
    if stage != '5':
        return base_payload
    return {'predecessor_successor_overlay': base_payload, 'r26_monitoring_policy': POLICY}


def static_checks(schema_sql: str, gen_sql: str) -> list[dict]:
    checks=[]
    def add(cid, ok, obs): checks.append({'control_id':cid,'status':'PASS' if ok else 'FAIL','observed':obs})
    add('R26_POLICY_SHA256_64', bool(re.fullmatch(r'[0-9a-f]{64}',POLICY_SHA256)), POLICY_SHA256)
    add('R26_SCHEMA_OVERLAY_TABLE', 'r26_m2_5_policy_overlay' in schema_sql, 'present' if 'r26_m2_5_policy_overlay' in schema_sql else 'absent')
    add('R26_SCHEMA_OPERATIONAL_FAMILY_TABLE', 'monitoring_operational_alert_family_daily' in schema_sql, 'present' if 'monitoring_operational_alert_family_daily' in schema_sql else 'absent')
    add('R26_SCHEMA_POWER_BI_VIEW', 'v_m2_5_power_bi_daily_monitoring_r26' in schema_sql, 'present' if 'v_m2_5_power_bi_daily_monitoring_r26' in schema_sql else 'absent')
    add('R26_SCHEMA_WATCH_DAY_21', 'v.watch_start_day <> 21' in schema_sql and "'watch_start_day', 21" in schema_sql, '21')
    add('R26_SCHEMA_ADVERSE_DAY_30', 'v.underperforming_start_day <> 30' in schema_sql and 'v.severe_start_day <> 30' in schema_sql, '30')
    add('R26_GEN_HORIZON_EXPECTATION', 'windows.total_repayment_amount / nullif(windows.collection_horizon_days,0)' in gen_sql, 'present')
    add('R26_GEN_WATCH_FIRST_DAY_23', 'activity.monitoring_day_index >= 23' in gen_sql, 'present')
    add('R26_GEN_ADVERSE_FIRST_DAY_32', gen_sql.count('activity.monitoring_day_index >= 32')>=2, gen_sql.count('activity.monitoring_day_index >= 32'))
    add('R26_GEN_THREE_DAY_PERSISTENCE', 'activity.r26_pace_lag_1' in gen_sql and 'activity.r26_pace_lag_2' in gen_sql, 'lag1+lag2')
    add('R26_GEN_EARLY_NO_REMIT', 'activity.monitoring_day_index >= 14' in gen_sql and 'activity.days_since_last_positive_remittance >= 7' in gen_sql and 'activity.days_since_last_positive_remittance >= 14' in gen_sql, 'day14 with 7+14 no-remit')
    add('R26_GEN_EARLY_ZERO_SALES', 'activity.zero_sales_streak_days >= 10' in gen_sql, '10')
    add('R26_GEN_EARLY_LIQUIDITY', 'activity.monitoring_day_index >= 7' in gen_sql and 'activity.available_balance < 0' in gen_sql, 'day7+')
    add('R26_GEN_HORIZON', 'activity.monitoring_day_index > activity.collection_horizon_days' in gen_sql, 'present')
    add('R26_GEN_OPERATIONAL_FAMILY_MATERIALIZATION', 'TRUNCATE TABLE msbf_m2.monitoring_operational_alert_family_daily' in gen_sql, 'present')
    add('R26_RAW_FLAGS_PRESERVED', all(tok in gen_sql for tok in ['daily_shortfall_alert_flag','cumulative_pace_watch_alert_flag','cumulative_pace_high_alert_flag','zero_sales_streak_alert_flag','liquidity_stress_alert_flag','horizon_overrun_alert_flag']), 'six raw flags')
    return checks
