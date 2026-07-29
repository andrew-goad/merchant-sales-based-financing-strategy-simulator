# Parameter, Policy, and Regulatory Precedence
## Merchant Sales-Based Financing Strategy Simulator v0.1R1

# 1. Purpose

The system must resolve global parameters, product and segment overlays, strategies, experiments, regulatory requirements, and authorized exceptions deterministically.

# 2. Parameter taxonomy

| Category | Examples | Owner |
|---|---|---|
| Population | merchant count, industry mix, relationship mix | Analytics |
| Source/data | history length, completeness, freshness, fallback | Data Owner |
| POS/cash flow | trend, volatility, seasonality, conversion margins | Credit Risk |
| Risk | base risk, component weights, bounds, tiers | Credit Risk/Validation |
| Product mechanics | amount, remittance, horizon, minimum progress | Product/Credit |
| Pricing | fee/payback multiple, cost of funds, partner cost | Pricing/Finance |
| Elasticity | acceptance, competition, adverse selection | Pricing/Analytics |
| Collateral/LGD | eligibility, haircuts, costs, timing, stress | Credit/Workout |
| Covenants | threshold, frequency, cure, action | Credit Policy |
| Portfolio | budget, concentrations, target mix | Portfolio/Credit Committee |
| Lifecycle | health, line, renewal, workout thresholds | Portfolio/Operations |
| Stress | macro shocks, dependency weights, lags, damping, caps | Stress/Portfolio |
| Regulatory | applicability, disclosures, permissions, reporting, retention | Legal/Compliance |
| Security/financial crime | data scope, verification, role assignment | Security/BSA/AML |

# 3. Resolution hierarchy

## 3.1 Non-overridable controls

```text
Unsupported feature catalog
→ Legal/compliance block
→ Expired/missing permission
→ Data-security or financial-crime block
→ Enterprise risk-appetite hard limit
```

These cannot be relaxed by strategy, experiment, Sales, or pricing.

## 3.2 Credit configuration hierarchy

```text
Global product policy
→ Product structure profile
→ Jurisdiction-approved product constraint
→ Industry overlay
→ Partner/channel overlay
→ Relationship-stage overlay
→ Strategy profile
→ Experiment cell
→ Authorized credit exception
```

The most specific approved value applies, subject to non-overridable controls.

# 4. Conflict resolution

A conflict is raised when:

- two active profiles claim the same scope and priority;
- a lower layer attempts to exceed a hard maximum or fall below a hard minimum;
- a strategy enables an unsupported feature;
- a credit rule conflicts with a compliance disposition;
- a parameter has incompatible units or meaning;
- an experiment changes more levers than its design permits.

Conflicts fail before run execution.

# 5. Exception standard

An exception requires:

```text
exception_id
scope and affected rows
original rule
requested override
business rationale
risk impact
customer impact
legal/compliance confirmation where relevant
approval authority
start/end date
monitoring plan
exit criteria
```

Regulatory blocks and unsupported features are not credit exceptions.

# 6. Profile snapshot

Each run freezes all resolved values into a profile snapshot. Downstream modules read the snapshot rather than resolving live tables again. This prevents mid-run changes and makes comparisons reproducible.

# 7. Unit and naming standard

- rates use decimal storage with explicit display unit;
- basis points use `_bps`;
- dollars use `_amount` and documented currency;
- days use `_days`;
- percentages of sales use `_rate` or `_pct` consistently;
- horizons are separated from maturity;
- risk proxy fields include `_proxy` unless calibrated;
- expected values include method/version.

# 8. P0 validation

- one resolved value per mandatory parameter path;
- no unresolved conflict;
- no unit mismatch;
- frozen snapshot hash reproduces;
- strategy and experiment changes remain within approved dimensions;
- non-overridable controls are never weakened;
- exception is effective-dated and within authority;
- compliance and security blocks cannot be overridden.
