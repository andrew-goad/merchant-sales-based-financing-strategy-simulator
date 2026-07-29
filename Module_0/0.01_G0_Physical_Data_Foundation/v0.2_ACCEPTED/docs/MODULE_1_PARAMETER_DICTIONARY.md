# Module 1 Parameter Dictionary
## Merchant Sales-Based Financing Strategy Simulator v0.2

All values are synthetic demonstration assumptions. This dictionary does not provide production underwriting thresholds, calibrated model parameters, market prices, legal conclusions, or economic forecasts.

## Summary

- Parameter definitions: **155**
- Baseline scoped values: **397**
- Parameter categories: **13**
- Feature definitions: **32**

## Run And Population

| Parameter | Type | Unit | Scope | Default | Owner | Stage | Purpose |
|---|---|---|---|---:|---|---|---|
| `population_size` | INTEGER | COUNT | GLOBAL | 750 | Analytics | M1.1 | Number of synthetic merchants/applications. |
| `history_days` | INTEGER | DAYS | GLOBAL | 180 | Data Architecture | M1.1 | Days of baseline history before as-of date. |
| `application_count_per_merchant` | INTEGER | COUNT | GLOBAL | 1 | Credit Strategy | M1.3 | Applications generated per merchant. |
| `deterministic_seed_version` | TEXT | CODE | GLOBAL | DET_HASH_V1 | Model Development | M1.1 | Version label for hash-based pseudo-random generation. |
| `base_currency_code` | TEXT | ISO_CURRENCY | GLOBAL | USD | Finance | M1.1 | Currency for Version 1 amounts. |
| `default_timezone_code` | TEXT | TIMEZONE | GLOBAL | America/New_York | Data Architecture | M1.1 | Default processing time zone. |
| `enable_deposit_history_flag` | BOOLEAN | FLAG | GLOBAL | True | Data Owner | M1.5 | Generate synthetic deposit/liquidity history. |
| `enable_scenario_history_flag` | BOOLEAN | FLAG | GLOBAL | True | Portfolio Strategy | M1.6 | Persist scenario-adjusted history. |
| `archive_write_mode` | TEXT | CODE | GLOBAL | APPEND_ONLY | Data Architecture | M1.17 | Archive persistence behavior. |
| `module1_contract_version` | TEXT | VERSION | GLOBAL | M1_APPLICATION_RISK_SNAPSHOT_V1 | Data Architecture | M1.17 | Required output contract version. |
## Population Design

| Parameter | Type | Unit | Scope | Default | Owner | Stage | Purpose |
|---|---|---|---|---:|---|---|---|
| `industry_mix_weight` | NUMERIC | RATE | INDUSTRY |  | Portfolio Strategy | M1.2 | Share of merchants by industry. |
| `region_mix_weight` | NUMERIC | RATE | REGION |  | Portfolio Strategy | M1.2 | Share by synthetic region. |
| `merchant_size_mix_weight` | NUMERIC | RATE | MERCHANT_SIZE_TIER |  | Portfolio Strategy | M1.2 | Share by merchant size tier. |
| `relationship_stage_mix_weight` | NUMERIC | RATE | RELATIONSHIP_STAGE |  | Portfolio Strategy | M1.2 | Share by relationship stage. |
| `legal_entity_mix_weight` | NUMERIC | RATE | LEGAL_ENTITY_TYPE |  | Data Architecture | M1.2 | Share by legal entity type. |
| `months_in_business_min` | INTEGER | MONTHS | GLOBAL | 6 | Credit Risk | M1.2 | Minimum synthetic months in business. |
| `months_in_business_max` | INTEGER | MONTHS | GLOBAL | 240 | Credit Risk | M1.2 | Maximum synthetic months in business. |
| `processor_tenure_min_months` | INTEGER | MONTHS | GLOBAL | 3 | Credit Risk | M1.2 | Minimum processor tenure. |
| `processor_tenure_max_months` | INTEGER | MONTHS | GLOBAL | 120 | Credit Risk | M1.2 | Maximum processor tenure. |
| `owner_count_min` | INTEGER | COUNT | GLOBAL | 1 | Data Architecture | M1.2 | Minimum owners/guarantors. |
| `owner_count_max` | INTEGER | COUNT | GLOBAL | 3 | Data Architecture | M1.2 | Maximum owners/guarantors. |
| `prior_advance_probability` | NUMERIC | RATE | RELATIONSHIP_STAGE |  | Portfolio Strategy | M1.2 | Probability of prior financing by stage. |
| `prior_default_probability` | NUMERIC | RATE | RELATIONSHIP_STAGE |  | Credit Risk | M1.2 | Prior synthetic default probability. |
## Source And Data Quality

| Parameter | Type | Unit | Scope | Default | Owner | Stage | Purpose |
|---|---|---|---|---:|---|---|---|
| `pos_minimum_history_days` | INTEGER | DAYS | GLOBAL | 90 | Data Owner | M1.7 | POS minimum history. |
| `deposit_minimum_history_days` | INTEGER | DAYS | GLOBAL | 90 | Data Owner | M1.7 | Deposit minimum history. |
| `source_freshness_pass_days` | INTEGER | DAYS | GLOBAL | 2 | Data Owner | M1.7 | Freshness pass. |
| `source_freshness_warning_days` | INTEGER | DAYS | GLOBAL | 5 | Data Owner | M1.7 | Freshness warning. |
| `source_completeness_pass_rate` | NUMERIC | RATE | GLOBAL | 0.97 | Data Owner | M1.7 | Completeness pass. |
| `source_completeness_warning_rate` | NUMERIC | RATE | GLOBAL | 0.9 | Data Owner | M1.7 | Completeness warning. |
| `pos_deposit_reconciliation_pass_rate` | NUMERIC | RATE | GLOBAL | 0.9 | Data Owner | M1.7 | Reconciliation pass. |
| `pos_deposit_reconciliation_warning_rate` | NUMERIC | RATE | GLOBAL | 0.75 | Data Owner | M1.7 | Reconciliation warning. |
| `missing_pos_source_confidence_penalty` | NUMERIC | POINTS | GLOBAL | 0.7 | Data Owner | M1.7 | Missing POS penalty. |
| `missing_deposit_source_confidence_penalty` | NUMERIC | POINTS | GLOBAL | 0.15 | Data Owner | M1.7 | Missing deposit penalty. |
| `source_outage_probability` | NUMERIC | RATE | SOURCE |  | Data Owner | M1.7 | Source outage probability. |
| `source_conflict_manual_review_threshold` | NUMERIC | COUNT | GLOBAL | 1 | Data Owner | M1.7 | Conflict review threshold. |
## Pos Generation

| Parameter | Type | Unit | Scope | Default | Owner | Stage | Purpose |
|---|---|---|---|---:|---|---|---|
| `industry_daily_sales_center` | NUMERIC | CURRENCY_PER_DAY | INDUSTRY |  | Analytics | M1.4 | Daily sales center. |
| `industry_daily_sales_log_sigma` | NUMERIC | LOG_SIGMA | INDUSTRY |  | Analytics | M1.4 | Cross-merchant sales dispersion. |
| `industry_daily_sales_volatility` | NUMERIC | COEFFICIENT_OF_VARIATION | INDUSTRY |  | Analytics | M1.4 | Daily sales volatility. |
| `industry_zero_sales_day_probability` | NUMERIC | RATE | INDUSTRY |  | Analytics | M1.4 | Zero-sales probability. |
| `industry_seasonality_amplitude` | NUMERIC | RATE | INDUSTRY |  | Analytics | M1.4 | Seasonality amplitude. |
| `industry_weekend_sales_factor` | NUMERIC | MULTIPLIER | INDUSTRY |  | Analytics | M1.4 | Weekend factor. |
| `industry_average_ticket_center` | NUMERIC | CURRENCY | INDUSTRY |  | Analytics | M1.4 | Average ticket center. |
| `industry_refund_rate_center` | NUMERIC | RATE | INDUSTRY |  | Analytics | M1.4 | Refund rate center. |
| `industry_chargeback_rate_center` | NUMERIC | RATE | INDUSTRY |  | Analytics | M1.4 | Chargeback rate center. |
| `reversal_rate_center` | NUMERIC | RATE | GLOBAL | 0.003 | Analytics | M1.4 | Reversal rate center. |
| `card_not_present_share_center` | NUMERIC | RATE | INDUSTRY |  | Analytics | M1.4 | Card-not-present share. |
| `processor_fee_rate` | NUMERIC | RATE | PARTNER_CHANNEL |  | Analytics | M1.4 | Processor fee rate. |
| `settlement_delay_days` | INTEGER | DAYS | PARTNER_CHANNEL |  | Analytics | M1.4 | Settlement delay. |
| `merchant_growth_rate_center` | NUMERIC | ANNUAL_RATE | CASHFLOW_ARCHETYPE |  | Analytics | M1.4 | Archetype trend center. |
| `merchant_growth_rate_sigma` | NUMERIC | ANNUAL_RATE | GLOBAL | 0.12 | Analytics | M1.4 | Trend dispersion. |
## Deposit And Liquidity

| Parameter | Type | Unit | Scope | Default | Owner | Stage | Purpose |
|---|---|---|---|---:|---|---|---|
| `deposit_capture_rate_center` | NUMERIC | RATE | INDUSTRY |  | Analytics | M1.5 | Deposit capture center. |
| `deposit_capture_rate_sigma` | NUMERIC | RATE | GLOBAL | 0.08 | Analytics | M1.5 | Deposit capture dispersion. |
| `balance_buffer_days_center` | NUMERIC | DAYS_OF_SALES | INDUSTRY |  | Analytics | M1.5 | Balance buffer center. |
| `nsf_daily_probability` | NUMERIC | RATE | RISK_TIER |  | Analytics | M1.5 | NSF probability. |
| `negative_balance_daily_probability` | NUMERIC | RATE | RISK_TIER |  | Analytics | M1.5 | Negative-balance probability. |
| `withdrawal_to_deposit_rate_center` | NUMERIC | RATE | GLOBAL | 0.92 | Analytics | M1.5 | Withdrawal/deposit center. |
| `liquidity_shock_multiplier` | NUMERIC | MULTIPLIER | SCENARIO | 1 | Analytics | M1.5 | Liquidity scenario shock. |
| `deposit_history_missing_probability` | NUMERIC | RATE | GLOBAL | 0.08 | Analytics | M1.5 | Deposit history missingness. |
## Application And Product

| Parameter | Type | Unit | Scope | Default | Owner | Stage | Purpose |
|---|---|---|---|---:|---|---|---|
| `funding_amount_min` | NUMERIC | CURRENCY | GLOBAL | 5000 | Product/Credit Strategy | M1.3 | Minimum request. |
| `funding_amount_max` | NUMERIC | CURRENCY | GLOBAL | 150000 | Product/Credit Strategy | M1.3 | Maximum request. |
| `funding_to_annualized_sales_center` | NUMERIC | RATE | MERCHANT_SIZE_TIER |  | Product/Credit Strategy | M1.3 | Funding/sales center. |
| `funding_to_annualized_sales_max` | NUMERIC | RATE | GLOBAL | 0.25 | Product/Credit Strategy | M1.3 | Funding/sales maximum. |
| `payback_multiple_center` | NUMERIC | MULTIPLIER | RISK_TIER |  | Product/Credit Strategy | M1.3 | Payback multiple center. |
| `payback_multiple_min` | NUMERIC | MULTIPLIER | GLOBAL | 1.08 | Product/Credit Strategy | M1.3 | Payback multiple minimum. |
| `payback_multiple_max` | NUMERIC | MULTIPLIER | GLOBAL | 1.35 | Product/Credit Strategy | M1.3 | Payback multiple maximum. |
| `requested_remittance_rate_center` | NUMERIC | RATE | EXPECTED_PAYOFF_DAYS |  | Product/Credit Strategy | M1.3 | Remittance center. |
| `requested_remittance_rate_min` | NUMERIC | RATE | GLOBAL | 0.05 | Product/Credit Strategy | M1.3 | Remittance minimum. |
| `requested_remittance_rate_max` | NUMERIC | RATE | GLOBAL | 0.3 | Product/Credit Strategy | M1.3 | Remittance maximum. |
| `expected_payoff_day_weight` | NUMERIC | RATE | EXPECTED_PAYOFF_DAYS |  | Product/Credit Strategy | M1.3 | Payoff horizon mix. |
| `use_of_proceeds_mix_weight` | NUMERIC | RATE | USE_OF_PROCEEDS |  | Product/Credit Strategy | M1.3 | Use-of-proceeds mix. |
## Capacity And Burden

| Parameter | Type | Unit | Scope | Default | Owner | Stage | Purpose |
|---|---|---|---|---:|---|---|---|
| `industry_cash_flow_conversion_margin` | NUMERIC | RATE | INDUSTRY |  | Credit Risk | M1.12 | Cash-flow conversion margin. |
| `recent_revenue_haircut_floor` | NUMERIC | RATE | GLOBAL | 0.65 | Credit Risk | M1.12 | Recent revenue haircut floor. |
| `volatility_haircut_slope` | NUMERIC | MULTIPLIER | GLOBAL | 0.35 | Credit Risk | M1.12 | Volatility haircut slope. |
| `transaction_quality_haircut_slope` | NUMERIC | MULTIPLIER | GLOBAL | 0.5 | Credit Risk | M1.12 | Quality haircut slope. |
| `data_confidence_haircut_slope` | NUMERIC | MULTIPLIER | GLOBAL | 0.25 | Credit Risk | M1.12 | Confidence haircut slope. |
| `minimum_post_financing_coverage_ratio` | NUMERIC | RATIO | GLOBAL | 1.1 | Credit Risk | M1.12 | Minimum coverage guidance. |
| `coverage_review_threshold` | NUMERIC | RATIO | GLOBAL | 1.2 | Credit Risk | M1.12 | Coverage review threshold. |
| `maximum_total_remittance_to_sales_rate` | NUMERIC | RATE | INDUSTRY | 0.2 | Credit Risk | M1.12 | Total remittance cap. |
| `minimum_residual_daily_cash_flow` | NUMERIC | CURRENCY_PER_DAY | GLOBAL | 0 | Credit Risk | M1.12 | Residual cash-flow floor. |
| `stacking_capacity_haircut` | NUMERIC | RATE | GLOBAL | 0.35 | Credit Risk | M1.12 | Stacking capacity haircut. |
## Verification And Fraud

| Parameter | Type | Unit | Scope | Default | Owner | Stage | Purpose |
|---|---|---|---|---:|---|---|---|
| `verification_hard_stop_check` | BOOLEAN | FLAG | VERIFICATION_CHECK |  | Fraud/Financial Crime | M1.8 | Hard-stop check flag. |
| `verification_review_check` | BOOLEAN | FLAG | VERIFICATION_CHECK |  | Fraud/Financial Crime | M1.8 | Review check flag. |
| `fraud_base_probability` | NUMERIC | RATE | GLOBAL | 0.015 | Fraud/Financial Crime | M1.8 | Base fraud probability. |
| `bank_account_mismatch_fraud_points` | NUMERIC | POINTS | GLOBAL | 40 | Fraud/Financial Crime | M1.8 | Bank mismatch points. |
| `processor_mismatch_fraud_points` | NUMERIC | POINTS | GLOBAL | 35 | Fraud/Financial Crime | M1.8 | Processor mismatch points. |
| `identity_conflict_fraud_points` | NUMERIC | POINTS | GLOBAL | 30 | Fraud/Financial Crime | M1.8 | Identity conflict points. |
| `abnormal_refund_fraud_points` | NUMERIC | POINTS | GLOBAL | 12 | Fraud/Financial Crime | M1.8 | Abnormal refund points. |
| `abnormal_chargeback_fraud_points` | NUMERIC | POINTS | GLOBAL | 18 | Fraud/Financial Crime | M1.8 | Abnormal chargeback points. |
| `fraud_tier_2_threshold` | NUMERIC | POINTS | GLOBAL | 10 | Fraud/Financial Crime | M1.8 | Fraud tier 2. |
| `fraud_tier_3_threshold` | NUMERIC | POINTS | GLOBAL | 25 | Fraud/Financial Crime | M1.8 | Fraud tier 3. |
| `fraud_tier_4_threshold` | NUMERIC | POINTS | GLOBAL | 45 | Fraud/Financial Crime | M1.8 | Fraud tier 4. |
| `fraud_tier_5_threshold` | NUMERIC | POINTS | GLOBAL | 70 | Fraud/Financial Crime | M1.8 | Fraud tier 5. |
## Credit Risk Proxy

| Parameter | Type | Unit | Scope | Default | Owner | Stage | Purpose |
|---|---|---|---|---:|---|---|---|
| `base_risk_intercept` | NUMERIC | POINTS | GLOBAL | -3.2 | Credit Risk/Model Development | M1.13-14 | Base risk intercept. |
| `risk_logistic_scale` | NUMERIC | MULTIPLIER | GLOBAL | 1 | Credit Risk/Model Development | M1.13-14 | Logistic scale. |
| `risk_proxy_floor` | NUMERIC | RATE | GLOBAL | 0.005 | Credit Risk/Model Development | M1.13-14 | Risk floor. |
| `risk_proxy_cap` | NUMERIC | RATE | GLOBAL | 0.45 | Credit Risk/Model Development | M1.13-14 | Risk cap. |
| `sales_decline_points` | NUMERIC | POINTS | RISK_ZONE |  | Credit Risk/Model Development | M1.13-14 | Sales decline points. |
| `sales_volatility_points` | NUMERIC | POINTS | RISK_ZONE |  | Credit Risk/Model Development | M1.13-14 | Volatility points. |
| `zero_sales_points` | NUMERIC | POINTS | RISK_ZONE |  | Credit Risk/Model Development | M1.13-14 | Zero-sales points. |
| `refund_rate_points` | NUMERIC | POINTS | RISK_ZONE |  | Credit Risk/Model Development | M1.13-14 | Refund points. |
| `chargeback_rate_points` | NUMERIC | POINTS | RISK_ZONE |  | Credit Risk/Model Development | M1.13-14 | Chargeback points. |
| `liquidity_stress_points` | NUMERIC | POINTS | RISK_ZONE |  | Credit Risk/Model Development | M1.13-14 | Liquidity points. |
| `nsf_points` | NUMERIC | POINTS | RISK_ZONE |  | Credit Risk/Model Development | M1.13-14 | NSF points. |
| `negative_balance_points` | NUMERIC | POINTS | RISK_ZONE |  | Credit Risk/Model Development | M1.13-14 | Negative balance points. |
| `existing_obligation_points` | NUMERIC | POINTS | RISK_ZONE |  | Credit Risk/Model Development | M1.13-14 | Obligation points. |
| `stacking_points` | NUMERIC | POINTS | GLOBAL | 20 | Credit Risk/Model Development | M1.13-14 | Stacking points. |
| `business_age_points` | NUMERIC | POINTS | RISK_ZONE |  | Credit Risk/Model Development | M1.13-14 | Business age points. |
| `processor_tenure_points` | NUMERIC | POINTS | RISK_ZONE |  | Credit Risk/Model Development | M1.13-14 | Processor tenure points. |
| `business_credit_points` | NUMERIC | POINTS | RISK_ZONE |  | Credit Risk/Model Development | M1.13-14 | Business credit points. |
| `owner_credit_points` | NUMERIC | POINTS | RISK_ZONE |  | Credit Risk/Model Development | M1.13-14 | Owner credit points. |
| `industry_risk_points` | NUMERIC | POINTS | INDUSTRY |  | Credit Risk/Model Development | M1.13-14 | Industry risk points. |
| `requested_burden_points` | NUMERIC | POINTS | RISK_ZONE |  | Credit Risk/Model Development | M1.13-14 | Requested burden points. |
## Ead Lgd Expected Loss

| Parameter | Type | Unit | Scope | Default | Owner | Stage | Purpose |
|---|---|---|---|---:|---|---|---|
| `ead_method_code` | TEXT | CODE | GLOBAL | WEIGHTED_DAILY_BALANCE | Credit Risk/Finance | M1.15-16 | EAD method. |
| `default_timing_weight` | NUMERIC | RATE | PATH_DAY_BUCKET |  | Credit Risk/Finance | M1.15-16 | Default timing weight. |
| `paydown_curve_shape` | NUMERIC | MULTIPLIER | EXPECTED_PAYOFF_DAYS | 1 | Credit Risk/Finance | M1.15-16 | Paydown curve shape. |
| `industry_lgd_baseline` | NUMERIC | RATE | INDUSTRY |  | Credit Risk/Finance | M1.15-16 | Industry LGD baseline. |
| `collateral_availability_lgd_haircut` | NUMERIC | RATE | GLOBAL | 0.05 | Credit Risk/Finance | M1.15-16 | Availability LGD haircut. |
| `guarantee_availability_lgd_haircut` | NUMERIC | RATE | GLOBAL | 0.03 | Credit Risk/Finance | M1.15-16 | Guarantee LGD haircut. |
| `lgd_floor` | NUMERIC | RATE | GLOBAL | 0.2 | Credit Risk/Finance | M1.15-16 | LGD floor. |
| `lgd_cap` | NUMERIC | RATE | GLOBAL | 0.95 | Credit Risk/Finance | M1.15-16 | LGD cap. |
| `expected_loss_tolerance_amount` | NUMERIC | CURRENCY | GLOBAL | 0.02 | Credit Risk/Finance | M1.15-16 | EL identity tolerance. |
| `ead_weight_tolerance` | NUMERIC | RATE | GLOBAL | 1e-06 | Credit Risk/Finance | M1.15-16 | EAD weight tolerance. |
| `simple_el_publish_flag` | BOOLEAN | FLAG | GLOBAL | True | Credit Risk/Finance | M1.15-16 | Publish simple EL. |
| `schedule_adjusted_el_publish_flag` | BOOLEAN | FLAG | GLOBAL | True | Credit Risk/Finance | M1.15-16 | Publish adjusted EL. |
## Scenario Overlays

| Parameter | Type | Unit | Scope | Default | Owner | Stage | Purpose |
|---|---|---|---|---:|---|---|---|
| `scenario_sales_level_multiplier` | NUMERIC | MULTIPLIER | SCENARIO|INDUSTRY | 1 | Portfolio Stress | M1.6 | Sales-level shock. |
| `scenario_sales_volatility_multiplier` | NUMERIC | MULTIPLIER | SCENARIO|INDUSTRY | 1 | Portfolio Stress | M1.6 | Volatility shock. |
| `scenario_zero_sales_probability_multiplier` | NUMERIC | MULTIPLIER | SCENARIO|INDUSTRY | 1 | Portfolio Stress | M1.6 | Zero-sales shock. |
| `scenario_refund_rate_multiplier` | NUMERIC | MULTIPLIER | SCENARIO|INDUSTRY | 1 | Portfolio Stress | M1.6 | Refund shock. |
| `scenario_chargeback_rate_multiplier` | NUMERIC | MULTIPLIER | SCENARIO|INDUSTRY | 1 | Portfolio Stress | M1.6 | Chargeback shock. |
| `scenario_deposit_capture_multiplier` | NUMERIC | MULTIPLIER | SCENARIO|INDUSTRY | 1 | Portfolio Stress | M1.6 | Deposit shock. |
| `scenario_obligation_multiplier` | NUMERIC | MULTIPLIER | SCENARIO|INDUSTRY | 1 | Portfolio Stress | M1.6 | Obligation shock. |
| `scenario_processor_outage_rate` | NUMERIC | RATE | SCENARIO | 0 | Portfolio Stress | M1.6 | Processor outage stress. |
| `scenario_direct_shock_cap` | NUMERIC | RATE | GLOBAL | 0.6 | Portfolio Stress | M1.6 | Direct shock cap. |
| `scenario_propagated_shock_cap` | NUMERIC | RATE | GLOBAL | 0.35 | Portfolio Stress | M1.6 | Propagated shock cap. |
| `scenario_damping_factor` | NUMERIC | RATE | GLOBAL | 0.65 | Portfolio Stress | M1.6 | Propagation damping. |
| `scenario_lag_days` | INTEGER | DAYS | SCENARIO | 7 | Portfolio Stress | M1.6 | Scenario lag. |
## Qa And Acceptance

| Parameter | Type | Unit | Scope | Default | Owner | Stage | Purpose |
|---|---|---|---|---:|---|---|---|
| `qa_expected_population_count_tolerance` | INTEGER | COUNT | GLOBAL | 0 | Independent Validation | M1.18 | Population count tolerance. |
| `qa_mix_tolerance_rate` | NUMERIC | RATE | GLOBAL | 0.01 | Independent Validation | M1.18 | Mix tolerance. |
| `qa_reconciliation_tolerance_amount` | NUMERIC | CURRENCY | GLOBAL | 0.02 | Independent Validation | M1.18 | Financial reconciliation tolerance. |
| `qa_reproducibility_required_flag` | BOOLEAN | FLAG | GLOBAL | True | Independent Validation | M1.18 | Require reproducibility. |
| `qa_no_future_data_required_flag` | BOOLEAN | FLAG | GLOBAL | True | Independent Validation | M1.18 | Require no future data. |
| `qa_max_risk_cap_share` | NUMERIC | RATE | GLOBAL | 0.15 | Independent Validation | M1.18 | Maximum cap share. |
| `qa_min_mixed_signal_share` | NUMERIC | RATE | GLOBAL | 0.01 | Independent Validation | M1.18 | Minimum mixed-signal share. |
| `qa_max_source_conflict_share` | NUMERIC | RATE | GLOBAL | 0.1 | Independent Validation | M1.18 | Maximum conflict share. |
| `qa_min_scenario_matched_share` | NUMERIC | RATE | GLOBAL | 1.0 | Independent Validation | M1.18 | Minimum scenario match. |
| `qa_contract_row_hash_required_flag` | BOOLEAN | FLAG | GLOBAL | True | Independent Validation | M1.18 | Require row hash. |
| `qa_acceptance_gate_id` | TEXT | CODE | GLOBAL | G2_M1_CONTRACT | Independent Validation | M1.18 | Acceptance gate. |
## Control And Boundaries

| Parameter | Type | Unit | Scope | Default | Owner | Stage | Purpose |
|---|---|---|---|---:|---|---|---|
| `synthetic_data_only_flag` | BOOLEAN | FLAG | GLOBAL | True | Legal/Compliance/Security | M1.1 | Synthetic-only control. |
| `real_cardholder_data_allowed_flag` | BOOLEAN | FLAG | GLOBAL | False | Legal/Compliance/Security | M1.1 | Cardholder data control. |
| `real_merchant_pii_allowed_flag` | BOOLEAN | FLAG | GLOBAL | False | Legal/Compliance/Security | M1.1 | Merchant PII control. |
| `production_decisioning_allowed_flag` | BOOLEAN | FLAG | GLOBAL | False | Legal/Compliance/Security | M1.1 | Production decision control. |
| `legal_conclusion_allowed_flag` | BOOLEAN | FLAG | GLOBAL | False | Legal/Compliance/Security | M1.1 | Legal conclusion control. |
| `regulatory_certification_allowed_flag` | BOOLEAN | FLAG | GLOBAL | False | Legal/Compliance/Security | M1.1 | Regulatory certification control. |
| `fair_lending_conclusion_allowed_flag` | BOOLEAN | FLAG | GLOBAL | False | Legal/Compliance/Security | M1.1 | Fair lending conclusion control. |
| `unsupported_feature_fail_closed_flag` | BOOLEAN | FLAG | GLOBAL | True | Legal/Compliance/Security | M1.1 | Unsupported feature control. |
