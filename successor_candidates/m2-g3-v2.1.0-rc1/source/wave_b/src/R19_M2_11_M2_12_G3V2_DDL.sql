DROP SCHEMA IF EXISTS msbf_r1_g3v2_r19 CASCADE;

CREATE SCHEMA msbf_r1_g3v2_r19;

CREATE TABLE msbf_r1_g3v2_r19.m2_11_strategy_profile (
  strategy_profile_code text NOT NULL,
  profile_sequence integer NOT NULL UNIQUE,
  selection_mode text NOT NULL,
  exposure_direction text NOT NULL,
  access_weight numeric NOT NULL,
  exposure_weight numeric NOT NULL,
  finance_weight numeric NOT NULL,
  loss_weight numeric NOT NULL,
  contribution_weight numeric NOT NULL,
  return_weight numeric NOT NULL,
  servicing_weight numeric NOT NULL,
  payment_weight numeric NOT NULL,
  candidate_weight_total numeric NOT NULL,
  scope_weight_total numeric NOT NULL,
  profile_contract_sha256 text NOT NULL,
  PRIMARY KEY (strategy_profile_code)
);

CREATE TABLE msbf_r1_g3v2_r19.m2_11_candidate_profile_evaluation (
  module1_run_id text NOT NULL,
  scenario_id text NOT NULL,
  scenario_code text NOT NULL,
  merchant_application_id text NOT NULL,
  candidate_id text NOT NULL,
  strategy_profile_code text NOT NULL REFERENCES msbf_r1_g3v2_r19.m2_11_strategy_profile(strategy_profile_code),
  profile_sequence integer NOT NULL,
  selection_mode text NOT NULL,
  source_candidate_row_hash text NOT NULL,
  candidate_feasibility_status text NOT NULL,
  feasibility_class text NOT NULL,
  feasibility_rank integer NOT NULL,
  hard_constraint_violation_count integer NOT NULL,
  infeasibility_reasons text NOT NULL,
  strict_pass_flag boolean NOT NULL,
  review_eligible_flag boolean NOT NULL,
  human_review_required_flag boolean NOT NULL,
  funded_amount numeric NOT NULL,
  finance_charge_amount numeric NOT NULL,
  loss_density numeric NOT NULL,
  risk_adjusted_contribution numeric NOT NULL,
  annualized_return numeric NOT NULL,
  payment_burden_rate numeric NOT NULL,
  access_normalized numeric,
  exposure_normalized numeric,
  finance_normalized numeric,
  loss_normalized numeric,
  contribution_normalized numeric,
  return_normalized numeric,
  payment_normalized numeric,
  objective_score numeric,
  candidate_selected_flag boolean NOT NULL,
  source_root_sha256 text NOT NULL,
  row_hash text PRIMARY KEY,
  UNIQUE (module1_run_id, scenario_code, merchant_application_id, candidate_id, strategy_profile_code)
);

CREATE TABLE msbf_r1_g3v2_r19.m2_11_application_strategy_simulation (
  module1_run_id text NOT NULL,
  scenario_id text NOT NULL,
  scenario_code text NOT NULL,
  merchant_application_id text NOT NULL,
  merchant_id text NOT NULL,
  strategy_profile_code text NOT NULL REFERENCES msbf_r1_g3v2_r19.m2_11_strategy_profile(strategy_profile_code),
  profile_sequence integer NOT NULL,
  source_final_outcome_code text NOT NULL,
  source_selected_candidate_id text,
  strategy_outcome_code text NOT NULL,
  selected_candidate_id text,
  selected_feasibility_class text NOT NULL,
  selected_funding_amount numeric NOT NULL,
  selected_finance_charge_amount numeric NOT NULL,
  selected_expected_loss_amount numeric NOT NULL,
  selected_loss_density numeric,
  selected_risk_adjusted_contribution numeric NOT NULL,
  selected_annualized_return numeric,
  selected_payment_burden_rate numeric,
  source_search_required_flag boolean NOT NULL,
  source_search_complete_flag boolean NOT NULL,
  source_no_feasible_proof_flag boolean NOT NULL,
  funded_source_flag boolean NOT NULL,
  m2_7_joined_flag boolean NOT NULL,
  m2_10_joined_flag boolean NOT NULL,
  operational_setup_outcome_code text,
  portfolio_performance_tier_code text,
  simulation_authority_state text NOT NULL,
  source_root_sha256 text NOT NULL,
  row_hash text PRIMARY KEY,
  UNIQUE (module1_run_id, scenario_code, merchant_application_id, strategy_profile_code)
);

CREATE TABLE msbf_r1_g3v2_r19.m2_11_account_strategy_simulation (
  module1_run_id text NOT NULL,
  scenario_code text NOT NULL,
  merchant_application_id text NOT NULL,
  strategy_profile_code text NOT NULL REFERENCES msbf_r1_g3v2_r19.m2_11_strategy_profile(strategy_profile_code),
  synthetic_account_id text NOT NULL,
  source_performance_tier_code text NOT NULL,
  source_servicing_queue_code text NOT NULL,
  source_servicing_burden_units numeric NOT NULL,
  incremental_servicing_burden_units numeric NOT NULL,
  simulated_servicing_burden_units numeric NOT NULL,
  treatment_code text NOT NULL,
  source_operational_activation_date date,
  source_next_reassessment_date date,
  payment_factor_changed_flag boolean NOT NULL,
  exposure_changed_flag boolean NOT NULL,
  treatment_effect_claimed_flag boolean NOT NULL,
  source_root_sha256 text NOT NULL,
  row_hash text PRIMARY KEY,
  UNIQUE (module1_run_id, scenario_code, merchant_application_id, strategy_profile_code)
);

CREATE TABLE msbf_r1_g3v2_r19.m2_11_portfolio_strategy_summary (
  reporting_scope_code text NOT NULL,
  strategy_profile_code text NOT NULL REFERENCES msbf_r1_g3v2_r19.m2_11_strategy_profile(strategy_profile_code),
  application_count integer NOT NULL,
  access_count integer NOT NULL,
  controlled_review_count integer NOT NULL,
  no_access_count integer NOT NULL,
  access_rate numeric NOT NULL,
  selected_exposure_amount numeric NOT NULL,
  finance_charge_amount numeric NOT NULL,
  expected_loss_density numeric NOT NULL,
  risk_adjusted_contribution numeric NOT NULL,
  annualized_risk_adjusted_return numeric NOT NULL,
  servicing_burden_units numeric NOT NULL,
  payment_burden_rate numeric NOT NULL,
  strategy_evidence_status text NOT NULL,
  hard_constraint_violation_count integer NOT NULL,
  stress_improvement_violation_count integer NOT NULL,
  source_root_sha256 text NOT NULL,
  row_hash text PRIMARY KEY,
  UNIQUE (reporting_scope_code, strategy_profile_code)
);

CREATE TABLE msbf_r1_g3v2_r19.m2_11_portfolio_strategy_frontier (
  reporting_scope_code text NOT NULL,
  strategy_profile_code text NOT NULL REFERENCES msbf_r1_g3v2_r19.m2_11_strategy_profile(strategy_profile_code),
  frontier_eligible_flag boolean NOT NULL,
  frontier_rank integer NOT NULL,
  dominated_by_count integer NOT NULL,
  governance_balance_score numeric NOT NULL,
  governance_priority_code text NOT NULL,
  source_root_sha256 text NOT NULL,
  row_hash text PRIMARY KEY,
  UNIQUE (reporting_scope_code, strategy_profile_code)
);

CREATE TABLE msbf_r1_g3v2_r19.m2_11_portfolio_strategy_comparison (
  reporting_scope_code text NOT NULL,
  challenger_strategy_profile_code text NOT NULL REFERENCES msbf_r1_g3v2_r19.m2_11_strategy_profile(strategy_profile_code),
  baseline_strategy_profile_code text NOT NULL REFERENCES msbf_r1_g3v2_r19.m2_11_strategy_profile(strategy_profile_code),
  frontier_rank integer NOT NULL,
  access_rate_delta numeric NOT NULL,
  selected_exposure_delta numeric NOT NULL,
  finance_charge_delta numeric NOT NULL,
  expected_loss_density_delta numeric NOT NULL,
  risk_adjusted_contribution_delta numeric NOT NULL,
  annualized_return_delta numeric NOT NULL,
  servicing_burden_delta numeric NOT NULL,
  payment_burden_delta numeric NOT NULL,
  governance_priority_code text NOT NULL,
  source_root_sha256 text NOT NULL,
  row_hash text PRIMARY KEY,
  UNIQUE (reporting_scope_code, challenger_strategy_profile_code)
);

CREATE TABLE msbf_r1_g3v2_r19.m2_12_g3v2_certification_detail (
  control_id text NOT NULL,
  control_scope text NOT NULL,
  status text NOT NULL,
  observed text NOT NULL,
  expected text NOT NULL,
  evidence_sha256 text NOT NULL,
  source_root_sha256 text NOT NULL,
  simulation_bundle_sha256 text NOT NULL,
  PRIMARY KEY (control_id)
);

CREATE TABLE msbf_r1_g3v2_r19.m2_12_g3v2_certification_master (
  certification_id text NOT NULL,
  certification_status text NOT NULL,
  control_count integer NOT NULL,
  pass_count integer NOT NULL,
  fail_count integer NOT NULL,
  source_root_sha256 text NOT NULL,
  simulation_bundle_sha256 text NOT NULL,
  control_root_sha256 text NOT NULL,
  power_bi_bundle_sha256 text NOT NULL,
  report_root_sha256 text NOT NULL,
  authority_state text NOT NULL,
  audit_state text NOT NULL,
  publication_state text NOT NULL,
  PRIMARY KEY (certification_id)
);

CREATE TABLE msbf_r1_g3v2_r19.m2_12_report_manifest (
  report_id text NOT NULL,
  report_type text NOT NULL,
  object_name text NOT NULL,
  grain text NOT NULL,
  row_count integer NOT NULL,
  content_sha256 text NOT NULL,
  source_root_sha256 text NOT NULL,
  PRIMARY KEY (report_id)
);

CREATE VIEW msbf_r1_g3v2_r19.v_p05_strategy_profile AS
SELECT * FROM msbf_r1_g3v2_r19.m2_11_strategy_profile;

CREATE VIEW msbf_r1_g3v2_r19.v_p05_candidate_evaluation AS
SELECT * FROM msbf_r1_g3v2_r19.m2_11_candidate_profile_evaluation;

CREATE VIEW msbf_r1_g3v2_r19.v_p05_application_strategy_simulation AS
SELECT * FROM msbf_r1_g3v2_r19.m2_11_application_strategy_simulation;

CREATE VIEW msbf_r1_g3v2_r19.v_p06_account_strategy_simulation AS
SELECT * FROM msbf_r1_g3v2_r19.m2_11_account_strategy_simulation;

CREATE VIEW msbf_r1_g3v2_r19.v_p06_portfolio_strategy_analysis AS
SELECT s.*,
       f.frontier_eligible_flag,
       f.frontier_rank,
       f.dominated_by_count,
       f.governance_balance_score,
       f.governance_priority_code,
       c.access_rate_delta,
       c.selected_exposure_delta,
       c.finance_charge_delta,
       c.expected_loss_density_delta,
       c.risk_adjusted_contribution_delta,
       c.annualized_return_delta,
       c.servicing_burden_delta,
       c.payment_burden_delta
FROM msbf_r1_g3v2_r19.m2_11_portfolio_strategy_summary AS s
JOIN msbf_r1_g3v2_r19.m2_11_portfolio_strategy_frontier AS f
  USING (reporting_scope_code, strategy_profile_code)
LEFT JOIN msbf_r1_g3v2_r19.m2_11_portfolio_strategy_comparison AS c
  ON c.reporting_scope_code = s.reporting_scope_code
 AND c.challenger_strategy_profile_code = s.strategy_profile_code;

CREATE VIEW msbf_r1_g3v2_r19.v_p06_g3v2_certification AS
SELECT * FROM msbf_r1_g3v2_r19.m2_12_g3v2_certification_detail;
