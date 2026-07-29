# M1.13 Parameter Dictionary

M1.13 uses two governed parameter sources:

1. The accepted frozen `run_parameter_snapshot` created at G1.
2. The approved M1.13 policy profile `M1_13_EXPOSURE_RECOVERY_LOSS_FOUNDATIONS` v1.

## Approved policy values

```json
{
  "blocked_loss_behavior": "NULL_WITH_REVIEW",
  "default_timing_basis_code": "EARLY_MIDDLE_LATE",
  "ead_method_code": "WEIGHTED_DAILY_BALANCE",
  "exposure_basis_code": "CONTRACTUAL_RECEIVABLE",
  "generation_enabled": true,
  "industry_stress_multiplier": {
    "CONSTRUCTION_TRADES": 0.7,
    "ECOMMERCE_DIGITAL": 0.4,
    "ENERGY_SERVICES": 1.0,
    "GENERAL_RETAIL": 0.5,
    "HEALTHCARE_SERVICES": 0.2,
    "PROFESSIONAL_SERVICES": 0.3,
    "RESTAURANT_FOOD_SERVICE": 0.6,
    "TRANSPORTATION_LOGISTICS": 0.8
  },
  "manual_review_lgd_threshold": 0.85,
  "manual_review_loss_rate_threshold": 0.15,
  "methodology_version": "M1_13_METHOD_V1",
  "recovery_credit_cap_rate": 0.25,
  "risk_proxy_basis_code": "SYNTHETIC_MERCHANT_RISK_PROXY",
  "stress_ead_floor_to_baseline": true,
  "stress_lgd_addon_base_rate": 0.08,
  "stress_lgd_floor_to_baseline": true,
  "stress_loss_floor_to_baseline": true,
  "stress_payment_cap_to_baseline": true
}
```

## Frozen parameter families

| Parameter | Scope | Role |
|---|---|---|
| `ead_method_code` | GLOBAL | Requires `WEIGHTED_DAILY_BALANCE` |
| `default_timing_weight` | EARLY / MIDDLE / LATE | Default-timing distribution; must sum to one |
| `paydown_curve_shape` | 30 / 60 / 90 days | Governs exposure-path curvature |
| `industry_lgd_baseline` | Eight industries | Base synthetic loss severity |
| `collateral_availability_lgd_haircut` | GLOBAL | Supported collateral recovery credit |
| `guarantee_availability_lgd_haircut` | GLOBAL | Supported guarantee recovery credit |
| `lgd_floor` / `lgd_cap` | GLOBAL | Bounds LGD foundations |
| `expected_loss_tolerance_amount` | GLOBAL | Comparative-loss identity tolerance |
| `ead_weight_tolerance` | GLOBAL | Timing/EAD reconciliation tolerance |
| `simple_el_publish_flag` | GLOBAL | Enables simple comparative measure |
| `schedule_adjusted_el_publish_flag` | GLOBAL | Enables schedule-adjusted measure |

All parameters are synthetic demonstration assumptions.
