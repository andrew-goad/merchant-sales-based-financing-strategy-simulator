# M2.12 Program 227 HF27 — Final Independent Release Validation

## Determination

```text
PASS
Independent controls       45 / 45 PASS
Blocking failures          0
```

## Canonical continuation package

```text
Filename
M2_12_LIVE_EXECUTION_CONTINUATION_AFTER_226_HF27.zip

Bytes
105,188

SHA-256
992a76977cb5d96193657ee0f84985a6d5d0b275b27e0067bbe5143ff2f03774

ZIP entries
42

Total uncompressed bytes
564,889

ZIP CRC
PASS
```

## Corrected diagnostic

```text
Filename
227_HF27_pre_execution_application_summary_diagnostic.sql

Bytes
8,952

SHA-256
08089fc3a8c8a5f21d9bed9fcf12faffcde106828d6551f9961232aba79487c8

Top-level statements
16

Temporary CTAS
4

Final evidence grids
3

Persistent mutations
0

Final action
ROLLBACK
```

## Preserved current sources

```text
Program 227 executable HF26
7b7fa0103fda0f1e1bd043aa14e926fa748db291dcb63873ca576d34ea54ab11

Full accepted-checkpoint verifier HF26
412376c0ad3f1375168cd02a576abde39e3c70d585de51f1d99482a2b36461c8
```

Both preserved sources are byte-identical to the prior HF26 continuation package.

## Root-cause closure

The HF26 narrow diagnostic declared the transaction SQL-level `READ ONLY` and then attempted `CREATE TEMP TABLE ... AS`. HF27 removes only the incompatible SQL transaction characteristic and uses repeatable-read isolation. Persistent-state mutation remains zero and the diagnostic ends with `ROLLBACK`.

## Physical release checks

```text
Complete extraction                    PASS
Source/extraction path mismatches       0
Source/extraction size mismatches       0
Source/extraction SHA-256 mismatches    0
Duplicate paths                         0
Case-insensitive duplicate paths        0
Unsafe paths                            0
Symbolic links                          0
Manifest mismatches                     0
manifest.json mismatches                0
SHA256SUMS mismatches                   0
Package-inventory mismatches            0
Unauthorized SQL files                  0
Superseded HF26 diagnostic inside ZIP   0
Sidecar filename/hash pairing           PASS
```

## Boundary

This validates the physical hotfix package and corrected source. It does not claim PostgreSQL execution of HF27 or successful completion of Program 227.
