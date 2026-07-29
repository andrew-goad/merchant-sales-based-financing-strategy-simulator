# M1.14 Parameter Dictionary

M1.14 parameters are frozen within the approved
`M1_14_UNIT_ECONOMICS_CONTRIBUTION` policy profile.

| Parameter | Value | Unit | Purpose |
|---|---:|---|---|
| `processor_payment_cost_rate` | 0.006 | rate | Processor/payment-network cost on total repayment |
| `default_partner_acquisition_cost_rate` | 0.03 | rate | Fallback acquisition cost when no supported channel rate exists |
| `partner_acquisition_cost_rate_cap` | 0.08 | rate | Maximum governed partner acquisition cost rate |
| `funding_cost_annual_rate` | 0.09 | annual rate | Synthetic annual cost of funds |
| `servicing_daily_cost_amount` | 1.50 | USD/day | Fixed daily servicing cost |
| `servicing_variable_cost_rate` | 0.0015 | rate | Variable servicing cost on total repayment |
| `operating_cost_fixed_amount` | 125.00 | USD | Fixed operating cost per booked structure |
| `operating_cost_variable_rate` | 0.0025 | rate | Variable operating cost on funded amount |
| `risk_capital_allocation_rate` | 0.12 | rate | Synthetic capital allocation against path-weighted EAD |
| `risk_capital_cost_annual_rate` | 0.15 | annual rate | Synthetic annual cost of allocated capital |
| `hurdle_annual_return_rate` | 0.18 | annual rate | Minimum annualized contribution hurdle |
| `economic_tier_1_return_threshold` | 0.25 | annual rate | Tier 1 lower bound |
| `economic_tier_2_return_threshold` | 0.18 | annual rate | Tier 2 lower bound |
| `economic_tier_3_return_threshold` | 0.10 | annual rate | Tier 3 lower bound |
| `annualization_days` | 365 | days | Annualization basis |
| `currency_tolerance_amount` | 0.01 | USD | Validation tolerance for currency identities |
| `rate_tolerance` | 0.00000001 | rate | Validation tolerance for rate identities |

## Frozen methodology controls

```text
methodology_version                         M1_14_METHOD_V1
contribution_basis_code                     CONDITIONAL_IF_BOOKED
comparative_loss_basis_code                 M1_13_SCHEDULE_ADJUSTED_COMPARATIVE_LOSS
funding_cost_basis_code                     PATH_WEIGHTED_EAD_X_ANNUAL_RATE_X_TERM
risk_capital_charge_basis_code              PATH_WEIGHTED_EAD_X_CAPITAL_X_COST_OF_CAPITAL_X_TERM
hurdle_basis_code                           FUNDED_AMOUNT_X_ANNUAL_HURDLE_X_TERM
stress_contribution_cap_to_baseline         true
stress_return_cap_to_baseline               true
stress_economic_tier_floor_to_baseline      true
```
