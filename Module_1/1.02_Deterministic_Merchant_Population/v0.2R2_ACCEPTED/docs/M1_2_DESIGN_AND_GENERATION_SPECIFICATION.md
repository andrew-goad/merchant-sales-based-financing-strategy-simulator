# M1.2 Design and Generation Specification

## 1. Stage objective

M1.2 establishes a stable, deterministic merchant universe that later application, POS, cash-flow, risk, pricing, performance, and stress stages can reuse without population noise. The stage answers:

> Who are the synthetic merchants being tested, what intrinsic and relationship characteristics do they have as of the accepted run date, and can the same population be reproduced exactly from the frozen G1 configuration and versioned M1.2 rules?

## 2. Stage boundary

### Created

| Entity | Grain | Expected rows |
|---|---|---:|
| `merchant_master` | One row per merchant | 750 |
| `merchant_owner_guarantor` | One row per merchant-owner/guarantor | 1,347 |
| `merchant_industry_assignment` | One primary industry per merchant | 750 |
| `partner_channel` | One synthetic channel definition | 5 |
| `processor_account` | One active processor account per merchant | 750 |
| `merchant_relationship_snapshot` | One merchant as-of relationship snapshot | 750 |

### Not created

Applications, daily POS, daily deposits, source snapshots, obligations, collateral, guarantees, credit snapshots, verification results, features, risk, EAD, Expected Loss, latest, and archive outputs remain empty.

## 3. Deterministic identity

The stable merchant key is:

```text
MSBF_POP_0001_M000001 ... MSBF_POP_0001_M000750
```

Each pseudo-random element is generated through the pre-existing deterministic functions using:

```text
population_id | merchant_sequence
+
deterministic_seed_version
+
stage-specific seed label
```

Session-level `random()` is prohibited.

## 4. Exact governed mix allocation

The stage uses a largest-remainder quota method:

1. Multiply each governed weight by 750.
2. Assign the integer floor to every category.
3. Allocate residual rows by descending fractional remainder and category code.
4. Rank merchants deterministically for each dimension.
5. Map rank ranges to exact category quotas.

This produces zero stochastic mix drift. The exact targets are stored in `catalogs/M1_2_GOVERNED_MIX_TARGETS.csv`.

## 5. Code-owned stage specification

G1 parameter, profile, and source snapshots are immutable. M1.2 therefore stores stage-owned assumptions as a versioned JSON evidence object and MD5 hash, including:

- partner-channel weights and definitions;
- business-age and processor-tenure transformation versions;
- relationship interruption assumptions;
- owner-score and guarantee rule versions;
- synthetic-only and non-production boundaries.

These assumptions supplement—but do not rewrite—the accepted G1 snapshots.

## 6. Business and processor attributes

Business age is bounded by the frozen global minimum and maximum, then differentiated by merchant size and relationship stage. Processor tenure is separately generated, bounded by its frozen limits, and cannot precede business formation.

Each merchant receives:

- legal entity type;
- geography region;
- merchant size tier and annual-sales band;
- primary industry;
- relationship stage;
- one acquisition/processor channel;
- one active, connected processor account;
- processor tenure, split-funding capability, settlement delay, and processor risk tier.

## 7. Relationship history

Prior-advance and prior-default prevalence are governed by relationship-stage parameters. Interruption rates are stage-owned assumptions captured in the generation-specification hash. The stage derives:

- prior advance count;
- completed advance count;
- prior default and interruption flags;
- prior funded and repaid amounts;
- deposit relationship;
- merchant-services relationship;
- wallet-share proxy;
- relationship-quality tier.

The design intentionally permits mixed signals. A merchant can have a strong owner profile and adverse relationship history, or weaker owner credit and a positive prior relationship.

## 8. Owner and guarantor generation

Each merchant receives one to three owners. Legal structure influences ownership count, while ownership rates reconcile exactly to 100%. Owner score is a transparent synthetic function of relationship stage, merchant size, business maturity, and a deterministic normal draw.

Owner records include only:

- synthetic party ID;
- role and ownership percentage;
- synthetic owner-credit score and band;
- major-derogatory and bankruptcy flags;
- personal-guarantee availability;
- synthetic guarantee-capacity amount.

## 9. Canonical deterministic snapshot

M1.2 generates two independently derived canonical entity sets:

- **Expected:** regenerated directly from G1 and M1.2 rules.
- **Actual:** recomputed from persisted physical table values.

Every canonical row has:

```text
entity_type | entity_key | row_hash
```

The stage compares all 4,352 rows and creates a comprehensive population hash. Acceptance requires:

```text
expected row count = actual row count = 4,352
row-level mismatches = 0
expected population hash = actual population hash = stored population hash
```

## 10. Validation philosophy

M1.2 validates:

- G1 immutability;
- exact population and category counts;
- synthetic-data boundaries;
- temporal integrity;
- owner and relationship coherence;
- mixed-signal realism;
- deterministic rerun equality;
- absence of downstream analytical records;
- fail-closed behavior for missing, invalid, or unauthorized generation conditions.

## 11. State transitions

```text
G1_READY / READY_FOR_GENERATION
    -> M1_2_GENERATED
    -> M1_2_VALIDATED
    -> M1_2_ACCEPTED
```

Any failed validation moves the run to `M1_2_FAILED`; subsequent analytical stages remain unauthorized.

## 12. Known boundaries

The population is synthetic and structurally governed, not calibrated to a lender’s observed merchant portfolio. Industry, relationship, owner, channel, and guarantee assumptions support strategy simulation and validation only. They cannot be used for real customer selection, underwriting, pricing, disclosure, collections, capital, reserving, or regulatory conclusions.
