# M2.12 Program 224 HF14 — Final Independent Release Validation

## Determination

**PASS**

```text
Independent controls            140 / 140 PASS
Blocking failures               0

AMBIGUITY             10 / 10  PASS
CATALOG                7 / 7   PASS
CONTROL               29 / 29  PASS
EVIDENCE              15 / 15  PASS
METADATA              16 / 16  PASS
MUTATION              11 / 11  PASS
PACKAGE               15 / 15  PASS
PARSER                15 / 15  PASS
ROOT_CAUSE             3 / 3   PASS
SCOPE                  4 / 4   PASS
SOURCE                15 / 15  PASS
```

## Physical package

```text
Package                         M2_12_LIVE_EXECUTION_CONTINUATION_AFTER_223_HF14.zip
Bytes                           148619
SHA-256                         fc3356842b527fe82863dcc8fccf877ecac5fbb1a76e017119ce322e7f878900
ZIP entries                     55
Total uncompressed bytes        914517
ZIP CRC                         PASS
Extraction path mismatches      0
Extraction size mismatches      0
Extraction SHA-256 mismatches   0
Duplicate paths                 0
Case-insensitive duplicates     0
Unsafe paths                    0
Symbolic links                  0
Manifest mismatches             0
manifest.json mismatches        0
SHA256SUMS mismatches           0
Package-inventory mismatches    0
```

## Current physical sources

```text
Program 224 HF14
Bytes                           153481
SHA-256                         d549f90da4ec3d9364d4f1e5bd1b8fc8a9e5e65d1c3d6af646bf48689ee9146e
Top-level statements            47
Negative controls               20

Negative-control diagnostic
Bytes                           151397
SHA-256                         347420f0fe47d2995367bcc8ad7dde8b5b39d423d42057640f8097ee9e847bff
Top-level statements            47
Negative controls               20

Validated-checkpoint verifier
Bytes                           174020
SHA-256                         ca5ab6d164ef567be8f5fedf362e56f91766022770e57a4cb06266dac2560374
Top-level statements            27
```

## Root cause and bounded correction

The supplied HF13 diagnostic produced exactly one control failure: Control 003, `M2_12_NEG_003_STAGE_STATUS_NOT_ACCEPTED`, observed SQLSTATE `42702` with message `column reference "contract_status" is ambiguous`. All 20 isolation checks passed and the before/after canonical, hash, sequence, and lifecycle fingerprints remained exact.

HF14 fully qualifies the joined fixture projection and ordering in Control 003. It proactively applies the same qualification discipline to Controls 001, 002, 006, and 012. Exactly five control blocks changed from HF13; the other fifteen remain byte-identical.

## Scope and mutation boundary

```text
Main/diagnostic control parity  20 / 20 exact
Control sequences               1–20 exact
Catalog definitions             20 / 20 byte/hash reconciled
Family allocations              14 / 14 PASS
Isolated persistent probes      6 exact
Committed persistent writes     1 run_evidence INSERT after 20/20 gate
Lifecycle updates               0
Owned sequence mutations        0
Persistent DDL                  0
Programs 225–227 in package     0
Recovery SQL in package         0
```

This is a physical, source, static, isolation-boundary, package, and supplied-evidence validation. PostgreSQL execution of Program 224 HF14 was not performed here.
