# M1.6 Design and Generation Specification

## 1. Business purpose

M1.6 creates matched scenario histories so the same merchants and dates can be compared under a reference environment and a controlled recession/energy sensitivity. The design isolates scenario effects from population noise and preserves all accepted baseline evidence.

## 2. Scenario architecture

### BASELINE v1

The BASELINE scenario exactly copies every accepted M1.4 POS field and every accepted M1.5 deposit field while attaching governed scenario identity, base-row lineage, overlay payload, and scenario row hashes.

### RECESSION_ENERGY v1

The stress scenario activates during the final 60 days. Direct industry effects begin on the governed shock date. Dependent-industry propagation begins seven days later and is damped by the global scenario damping factor.

```text
History window           180 days
Stress window             60 days
Direct rows               45,000
Propagation lag            7 days
Propagated window         53 days
Propagated rows           39,750
```

## 3. Industry transmission

The scenario uses a code-owned but evidence-frozen eight-industry matrix. Each industry has:

- a direct sensitivity;
- an energy-dependency weight;
- a transparent transmission channel;
- a bounded direct factor;
- a bounded propagated factor.

The weights are synthetic demonstration assumptions and are not estimated industry elasticities.

## 4. POS overlay sequence

```text
Accepted baseline POS row
→ scenario and industry profile
→ shock-window determination
→ direct factor
→ lagged propagated factor
→ bounded deterministic volatility
→ incremental zero-sales / outage events
→ transaction-quality overlays
→ eligible sales
→ settlement-lag reproduction
→ processor fee and net proceeds
→ payload and canonical row hash
```

### Direct factor

```text
max(1 − direct shock cap,
    1 − (1 − scenario sales multiplier) × direct sensitivity)
```

### Propagated factor

```text
max(1 − propagated shock cap,
    1 − (1 − scenario sales multiplier)
        × energy dependency
        × damping factor)
```

### Volatility

The deterministic volatility overlay is bounded between 0.65 and 1.35. It may create daily variation above or below the level-adjusted path while the aggregate stress remains directionally adverse.

### Pre-shock preservation

Every RECESSION_ENERGY row before the governed shock date copies all accepted POS values exactly. The overlay payload identifies that the stress scenario is selected but not yet active.

## 5. Deposit and liquidity overlay sequence

```text
Accepted baseline deposit row
+ matched scenario POS row
+ accepted M1.5 merchant liquidity profile
→ scenario POS-linked deposit
→ obligation-scaled withdrawal
→ temporary hold
→ bounded support-deposit algorithm
→ opening / closing / available / minimum balance
→ monotonic NSF and negative-balance stress treatment
→ payload and canonical row hash
```

The stress design does not allow matched stress to remove an NSF or negative-balance event already present in the baseline. It may preserve or add adverse events.

### Pre-shock preservation

All stress-scenario deposit fields before the shock date copy the accepted M1.5 values exactly.

## 6. Matched comparison

The comparison keys are:

```text
scenario_id
population_id
merchant_id
observation_date
```

POS additionally retains `processor_account_id`. Every scenario merchant-day must have both a POS and deposit row. The minimum matched share is 100%.

## 7. Lineage and determinism

Every scenario row retains:

- `base_row_hash` from the accepted baseline row;
- approved source contract identity;
- accepted run identity;
- scenario-overlay payload;
- deterministic row hash.

Three full-set hashes are retained:

- POS scenario set;
- deposit scenario set;
- combined scenario set.

Expected and persisted rows must reproduce exactly.

## 8. Stage boundary

M1.6 does not derive final underwriting features, risk estimates, exposure at default, loss given default, Expected Loss, pricing, or decisions. Those later stages consume accepted scenario histories without rewriting them.
