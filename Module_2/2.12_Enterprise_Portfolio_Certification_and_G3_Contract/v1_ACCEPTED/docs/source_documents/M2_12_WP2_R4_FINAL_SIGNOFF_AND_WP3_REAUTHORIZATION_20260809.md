# M2.12 WP2 Source R4 Final Signoff and WP3 Reauthorization

## Determination

**APPROVED.**

```text
M2.12 WP2 Source R4                       APPROVED
WP3 source construction                    REAUTHORIZED

Programs 223 and 224                       AUTHORIZED FOR SQL SOURCE GENERATION
Recovery 223A                              AUTHORIZED FOR SQL SOURCE GENERATION

PostgreSQL execution                       NOT AUTHORIZED
Programs 225–227                           NOT AUTHORIZED
Execution packaging                        NOT AUTHORIZED
M2.12 validation or acceptance             NOT CLAIMED
Module 3                                   NOT AUTHORIZED
Production                                 NOT AUTHORIZED
```

## Governing WP2 package

```text
M2_12_Build_WP2_R4.zip

SHA-256
aa234e534c8dbed7cdd7ba5ed6041e498df4c9046cbac4663477a08647e73592
```

## Current SQL source identities

```text
220 R4
757462b1d3c323be9cbe3a98fd5c9a822719ca6e9a15b698644c0650b5413298

221
774f96643c16a8f2191b057afa01f311c1b663f79e2bf353dcd0d6cd5cc6c909

222 R3
6e29dba9043675094fb9c399895895b9230e1b96976e5e4af7a7a48e094d51fe

220A
7510697598eb033e95d4d0fb3ff540c41dd0df810577312949b8ef57f1076d93

222A
8087d51cd6d1dbcf89371d4219e787b53221ddf3a5959053af1306fef0967627

222B
056f277eb07ef2144cb06e6afdd0158ea5ad07b96ecc56f0e34813852c1c790a
```

The former Program 220 R3 identity
`db65f55547ceb20fdca9cd32e30c0be9c0d87736e73be6804917eb2695406de4`
is historical, noncurrent, and prohibited for execution.

Any partial WP3 work built against Program 220 R3 is noncurrent and must not be
promoted. WP3 must be regenerated against Program 220 R4 while preserving Program 222
R3 and all other WP2 R4 sources byte-identically.
