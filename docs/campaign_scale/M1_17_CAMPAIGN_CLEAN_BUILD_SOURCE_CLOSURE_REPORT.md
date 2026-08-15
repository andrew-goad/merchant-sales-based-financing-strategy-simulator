# M1.17 Campaign Clean-Build Source Closure

## Determination

**STATIC SOURCE CLOSURE COMPLETE — POSTGRESQL NOT EXECUTED**

```text
Normal program sources                     8 / 8
Exact historical/recovered sources          6 / 8
New bounded clean-build replacements        2 / 8
Recovery sources in normal chain             0
Static controls                            73 / 73 PASS
PostgreSQL executions                        0
Accepted repository modifications            0
```

## Current clean-build source set

```text
124  exact recovered R2 synchronized source
125  exact executed R2 source
126  exact executed R2 source
127  new v0.2CB1 clean-build replacement
128  exact executed R2 source
129  new v0.2CB1 accepted-correction composition
130  exact executed R6 master report
131  exact executed R8 detail report
```

## Program 127

The recovered R2 source is retained in source history. CB1 changes only:

1. the source header/provenance;
2. a read-only fail-closed guard before any positive-evidence or lifecycle mutation;
3. the accepted POS007 implementation.

The initial invocation boundary is exact:

```text
run status                          M1_17_GENERATED
G2 bundle status                    GENERATED
prior positive evidence rows        0
prior negative evidence rows        0
prior acceptance evidence rows      0
prior G2 gate-result rows            0
```

Any validated, accepted, failed, partially evidenced or noncanonical rerun aborts
before DELETE, INSERT or UPDATE.

POS007 now requires all four accepted conditions:

```text
character length                                  32
byte length                                       32
lowercase hexadecimal domain                    TRUE
configuration hash = deterministic policy hash  TRUE
```

## Program 129

CB1 uses the accepted R6 finalizer byte stream as its primary base. The only
executable additions are the two R2 gate prerequisites:

```sql
msbf_ctl.m1_17_gate_defined('G2_M1_CONTRACT') AS g2_gate_defined
AND physical.g2_gate_defined
```

R6 exactly-one-value acceptance evidence remains unchanged:

```text
metric_value_numeric   NULL
metric_value_text      combined G2 hash
```

## Source-set identity

```text
Ordered source-set SHA-256
c4a0eddaacff0516a709faec33b5722795be9024cff5854ffd704987a0e36b4f
```

Preimage:

```text
1|124|8e8d9058255cbfd47462592452afc5f626747181272e66785c9b5d495910c3b3
2|125|54892d19182d18490182d51007bcaf21cfed3873b0ada0a610c2850d5da3f620
3|126|16330dda3fd3f5301c4485de0a31f52fe3834cdb85059611c378aeaa696eb857
4|127|7ce0bb51935ab320a83b1e76e5dfe18ace869d796573ecb1e5c923f0deae1d87
5|128|f49f341b42fb379b53768a0b307903ee1e1f24e7dcebd52447b72ac3221b6579
6|129|5a2c0e5b8273e50bca7670ffecb66a8f83c8ca30f10d9ab72a1826072afb9ca3
7|130|9761bc547d613ae5627f8c412c234de8975cc30dcfc5c2be699be2c499c93175
8|131|435525e2579eea716a87e0ab426b40a6cd542c1b95db3cc56ee196ff2723b703
```

## Boundary

This package closes the M1.17 physical clean-build source gap for campaign planning.
It does not prove runtime equivalence. Runtime certification remains a required part
of the future disposable 750-application golden replay.

Do not insert these files into the accepted M2.12 repository or claim that Programs
127/129 are the historical executed bytes.
