/* ============================================================================
MSBF M1.8 Verification, Fraud & Processor Continuity — Schema and Policy Extension
Version : v0.2R1
Purpose : Extend verification-result evidence, add an application-level
          verification/fraud/continuity summary, register the M1.8 gate, and
          persist the approved stage methodology profile.
Boundary:  This script changes schema and governed policy metadata only. It does
          not generate verification or fraud evidence and does not change the
          accepted M1.7 run status.
============================================================================ */
BEGIN;
SET LOCAL lock_timeout='10s';
SET LOCAL statement_timeout='5min';

INSERT INTO msbf_ref.acceptance_gate_catalog(
    gate_id, gate_name, module_code, severity, description
)
VALUES(
    'M1_8_VERIFICATION_FRAUD_CONTINUITY',
    'M1.8 Verification, Fraud and Processor Continuity',
    'M1',
    'BLOCKING',
    'Synthetic verification checks, independent fraud-risk evidence, processor-continuity status, deterministic reconciliation, routing recommendations, and stage-boundary acceptance.'
)
ON CONFLICT(gate_id) DO UPDATE SET
    gate_name=EXCLUDED.gate_name,
    module_code=EXCLUDED.module_code,
    severity=EXCLUDED.severity,
    description=EXCLUDED.description;

ALTER TABLE msbf_m1.verification_result
    ADD COLUMN IF NOT EXISTS manual_review_recommended_flag boolean DEFAULT false NOT NULL,
    ADD COLUMN IF NOT EXISTS result_reason_code text,
    ADD COLUMN IF NOT EXISTS row_hash text;

DO $ddl$
BEGIN
    IF EXISTS (
        SELECT 1 FROM msbf_m1.verification_result
        WHERE result_reason_code IS NULL OR row_hash IS NULL
    ) THEN
        RAISE EXCEPTION 'Existing verification_result rows must be fully populated before M1.8 not-null enforcement.';
    END IF;

    ALTER TABLE msbf_m1.verification_result
        ALTER COLUMN result_reason_code SET NOT NULL,
        ALTER COLUMN row_hash SET NOT NULL;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conrelid='msbf_m1.verification_result'::regclass
          AND conname='ck_verification_result_status'
    ) THEN
        ALTER TABLE msbf_m1.verification_result
            ADD CONSTRAINT ck_verification_result_status
            CHECK (result_status IN ('PASS','REVIEW','FAIL','UNAVAILABLE'));
    END IF;
END;
$ddl$;

CREATE TABLE IF NOT EXISTS msbf_m1.application_verification_fraud_snapshot (
    module1_run_id bigint NOT NULL,
    merchant_application_id text NOT NULL,
    as_of_timestamp timestamptz NOT NULL,
    verification_source_snapshot_id bigint NOT NULL,
    pos_source_snapshot_id bigint NOT NULL,
    deposit_source_snapshot_id bigint NOT NULL,
    verification_pass_count smallint NOT NULL,
    verification_review_count smallint NOT NULL,
    verification_fail_count smallint NOT NULL,
    verification_unavailable_count smallint NOT NULL,
    critical_fail_count smallint NOT NULL,
    fraud_score numeric(9,6) NOT NULL,
    fraud_risk_tier smallint NOT NULL,
    processor_continuity_status text NOT NULL,
    processor_continuity_risk_tier smallint NOT NULL,
    stress_processor_continuity_status text NOT NULL,
    stress_processor_continuity_risk_tier smallint NOT NULL,
    processor_active_day_rate numeric(9,6) NOT NULL,
    processor_degraded_day_rate numeric(9,6) NOT NULL,
    processor_outage_day_rate numeric(9,6) NOT NULL,
    recent_processor_outage_day_rate numeric(9,6) NOT NULL,
    data_connection_gap_day_rate numeric(9,6) NOT NULL,
    stress_processor_degraded_day_rate numeric(9,6) NOT NULL,
    stress_processor_outage_day_rate numeric(9,6) NOT NULL,
    stress_data_connection_gap_day_rate numeric(9,6) NOT NULL,
    continuity_stress_worsening_flag boolean NOT NULL,
    hard_stop_recommended_flag boolean NOT NULL,
    manual_review_recommended_flag boolean NOT NULL,
    verification_disposition text NOT NULL,
    primary_reason_code text NOT NULL,
    secondary_reason_codes text[] DEFAULT '{}'::text[] NOT NULL,
    fraud_reason_flags jsonb DEFAULT '{}'::jsonb NOT NULL,
    row_hash text NOT NULL,
    created_by_run_id bigint NOT NULL,
    created_at timestamptz DEFAULT clock_timestamp() NOT NULL,
    CONSTRAINT pk_msbf_m1_application_verification_fraud_snapshot
        PRIMARY KEY (module1_run_id, merchant_application_id),
    CONSTRAINT ck_m1_8_check_counts CHECK (
        verification_pass_count>=0 AND verification_review_count>=0
        AND verification_fail_count>=0 AND verification_unavailable_count>=0
        AND critical_fail_count>=0
        AND verification_pass_count+verification_review_count+
            verification_fail_count+verification_unavailable_count=6
    ),
    CONSTRAINT ck_m1_8_fraud_score CHECK (fraud_score BETWEEN 0 AND 100),
    CONSTRAINT ck_m1_8_fraud_tier CHECK (fraud_risk_tier BETWEEN 1 AND 5),
    CONSTRAINT ck_m1_8_continuity_tiers CHECK (
        processor_continuity_risk_tier BETWEEN 1 AND 5
        AND stress_processor_continuity_risk_tier BETWEEN 1 AND 5
    ),
    CONSTRAINT ck_m1_8_continuity_status CHECK (
        processor_continuity_status IN ('STABLE','MONITORED','WATCH','DISRUPTED','UNAVAILABLE')
        AND stress_processor_continuity_status IN ('STABLE','MONITORED','WATCH','DISRUPTED','UNAVAILABLE')
    ),
    CONSTRAINT ck_m1_8_rates CHECK (
        processor_active_day_rate BETWEEN 0 AND 1
        AND processor_degraded_day_rate BETWEEN 0 AND 1
        AND processor_outage_day_rate BETWEEN 0 AND 1
        AND recent_processor_outage_day_rate BETWEEN 0 AND 1
        AND data_connection_gap_day_rate BETWEEN 0 AND 1
        AND stress_processor_degraded_day_rate BETWEEN 0 AND 1
        AND stress_processor_outage_day_rate BETWEEN 0 AND 1
        AND stress_data_connection_gap_day_rate BETWEEN 0 AND 1
    ),
    CONSTRAINT ck_m1_8_disposition CHECK (
        verification_disposition IN ('CLEAR','REVIEW','STOP','INSUFFICIENT_EVIDENCE')
    ),
    CONSTRAINT ck_m1_8_disposition_flags CHECK (
        (verification_disposition='CLEAR' AND NOT hard_stop_recommended_flag AND NOT manual_review_recommended_flag)
        OR (verification_disposition='REVIEW' AND NOT hard_stop_recommended_flag AND manual_review_recommended_flag)
        OR (verification_disposition IN ('STOP','INSUFFICIENT_EVIDENCE') AND hard_stop_recommended_flag)
    ),
    CONSTRAINT fk_m1_8_summary_run FOREIGN KEY (module1_run_id)
        REFERENCES msbf_ctl.run_registry(run_id) ON DELETE CASCADE,
    CONSTRAINT fk_m1_8_summary_application FOREIGN KEY (merchant_application_id)
        REFERENCES msbf_m1.merchant_application(merchant_application_id) ON DELETE CASCADE,
    CONSTRAINT fk_m1_8_summary_created_run FOREIGN KEY (created_by_run_id)
        REFERENCES msbf_ctl.run_registry(run_id) ON DELETE RESTRICT,
    CONSTRAINT fk_m1_8_summary_verification_source FOREIGN KEY (verification_source_snapshot_id,module1_run_id)
        REFERENCES msbf_m1.source_snapshot(source_snapshot_id,module1_run_id) ON DELETE RESTRICT,
    CONSTRAINT fk_m1_8_summary_pos_source FOREIGN KEY (pos_source_snapshot_id,module1_run_id)
        REFERENCES msbf_m1.source_snapshot(source_snapshot_id,module1_run_id) ON DELETE RESTRICT,
    CONSTRAINT fk_m1_8_summary_deposit_source FOREIGN KEY (deposit_source_snapshot_id,module1_run_id)
        REFERENCES msbf_m1.source_snapshot(source_snapshot_id,module1_run_id) ON DELETE RESTRICT
);

COMMENT ON TABLE msbf_m1.application_verification_fraud_snapshot IS
'Application-level M1.8 verification disposition, independent synthetic fraud-risk tier, baseline/stress processor-continuity evidence, and controlled routing recommendation.';

CREATE INDEX IF NOT EXISTS ix_m1_8_summary_disposition
    ON msbf_m1.application_verification_fraud_snapshot
       (module1_run_id,verification_disposition,fraud_risk_tier);
CREATE INDEX IF NOT EXISTS ix_m1_8_summary_continuity
    ON msbf_m1.application_verification_fraud_snapshot
       (module1_run_id,processor_continuity_risk_tier,stress_processor_continuity_risk_tier);
CREATE INDEX IF NOT EXISTS ix_m1_8_verification_run_check
    ON msbf_m1.verification_result(created_by_run_id,check_code,result_status);

INSERT INTO msbf_ctl.policy_profile(
    profile_code,profile_version,business_name,effective_start_date,effective_end_date,
    status,owner_role,approver_role,approval_timestamp,last_review_date,next_review_date,
    change_reason,policy_domain,product_structure_profile_id,operating_model_profile_id,
    parameter_set_id,profile_payload
)
SELECT
    'M1_8_VERIFICATION_FRAUD_CONTINUITY',
    1,
    'M1.8 Verification, Fraud and Processor Continuity Policy',
    r.as_of_date,
    NULL,
    'APPROVED',
    'Fraud Risk',
    'Credit Risk and Compliance',
    coalesce(p.approval_timestamp,clock_timestamp()),
    r.as_of_date,
    r.as_of_date + 365,
    'Initial governed synthetic M1.8 methodology profile.',
    'VERIFICATION_FRAUD_CONTINUITY',
    r.product_structure_profile_id,
    r.operating_model_profile_id,
    r.parameter_set_id,
    '{"generation_enabled":true,"methodology_version":"M1_8_METHOD_V1_1","stress_continuity_tier_floor_to_baseline":true,"recent_window_days":30,"kyb_fail_multiplier":0.4,"beneficial_owner_fail_multiplier":0.55,"sanctions_fail_multiplier":0.05,"bank_account_mismatch_multiplier":0.75,"processor_mismatch_multiplier":0.65,"identity_conflict_multiplier":0.5,"review_band_multiplier":1.5,"refund_rate_multiplier_threshold":1.5,"refund_rate_absolute_floor":0.035,"chargeback_rate_multiplier_threshold":1.75,"chargeback_rate_absolute_floor":0.008,"continuity_tier_2_degraded_rate":0.01,"continuity_tier_3_degraded_rate":0.03,"continuity_tier_4_degraded_rate":0.08,"continuity_tier_2_outage_rate":0.001,"continuity_tier_3_outage_rate":0.005,"continuity_tier_4_outage_rate":0.015,"continuity_tier_2_connection_gap_rate":0.01,"continuity_tier_3_connection_gap_rate":0.03,"continuity_tier_4_connection_gap_rate":0.08,"continuity_tier_2_recent_outage_rate":0.0,"continuity_tier_3_recent_outage_rate":0.01,"continuity_tier_4_recent_outage_rate":0.03,"manual_review_fraud_tier":3,"hard_stop_fraud_tier":5,"manual_review_continuity_tier":3,"hard_stop_continuity_tier":5}'::jsonb
FROM msbf_ctl.run_registry r
LEFT JOIN msbf_ctl.policy_profile p
  ON p.profile_code='M1_8_VERIFICATION_FRAUD_CONTINUITY'
 AND p.profile_version=1
WHERE r.run_code='M1_V0_2_BASELINE_BUILD' AND r.run_version=1
ON CONFLICT(profile_code,profile_version)
DO UPDATE SET
    business_name=EXCLUDED.business_name,
    effective_start_date=EXCLUDED.effective_start_date,
    effective_end_date=EXCLUDED.effective_end_date,
    status='APPROVED',
    owner_role=EXCLUDED.owner_role,
    approver_role=EXCLUDED.approver_role,
    approval_timestamp=coalesce(msbf_ctl.policy_profile.approval_timestamp,EXCLUDED.approval_timestamp),
    last_review_date=EXCLUDED.last_review_date,
    next_review_date=EXCLUDED.next_review_date,
    change_reason=EXCLUDED.change_reason,
    policy_domain=EXCLUDED.policy_domain,
    product_structure_profile_id=EXCLUDED.product_structure_profile_id,
    operating_model_profile_id=EXCLUDED.operating_model_profile_id,
    parameter_set_id=EXCLUDED.parameter_set_id,
    profile_payload=EXCLUDED.profile_payload;

COMMIT;

WITH p AS (
    SELECT policy_profile_id,status,profile_payload,
           md5(profile_payload::text) AS policy_hash
    FROM msbf_ctl.policy_profile
    WHERE profile_code='M1_8_VERIFICATION_FRAUD_CONTINUITY' AND profile_version=1
)
SELECT
    (SELECT count(*) FROM information_schema.columns
      WHERE table_schema='msbf_m1' AND table_name='verification_result'
        AND column_name IN ('manual_review_recommended_flag','result_reason_code','row_hash')) AS verification_columns_added,
    to_regclass('msbf_m1.application_verification_fraud_snapshot') IS NOT NULL AS summary_table_exists,
    p.policy_profile_id,
    p.status AS policy_status,
    p.policy_hash,
    CASE
        WHEN (SELECT count(*) FROM information_schema.columns
              WHERE table_schema='msbf_m1' AND table_name='verification_result'
                AND column_name IN ('manual_review_recommended_flag','result_reason_code','row_hash'))=3
         AND to_regclass('msbf_m1.application_verification_fraud_snapshot') IS NOT NULL
         AND p.status='APPROVED'
        THEN 'PASS' ELSE 'FAIL'
    END AS schema_policy_extension_status
FROM p;
