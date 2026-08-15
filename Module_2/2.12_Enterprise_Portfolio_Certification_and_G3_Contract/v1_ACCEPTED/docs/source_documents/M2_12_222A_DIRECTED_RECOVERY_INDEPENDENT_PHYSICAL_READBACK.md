# M2.12 Recovery 222A R1 — Independent Physical Readback

```text
Package                              M2_12_DIRECTED_RECOVERY_222A_R1.zip
Bytes                                27,258
SHA-256                              881344ff7342efa33acc1977920ab719bff7d37a44c10a5a4704abadcdb19b70
ZIP entries                          19
Total uncompressed bytes             79,257
ZIP CRC                              PASS
Independent controls                 45 / 45 PASS
Blocking failures                    0

Path mismatches                      0
Size mismatches                      0
SHA-256 mismatches                   0
Duplicate paths                      0
Case-insensitive duplicate paths     0
Unsafe paths                         0
Symbolic links                       0
MANIFEST.csv mismatches              0
manifest.json mismatches              0
SHA256SUMS.txt mismatches             0
PACKAGE_INVENTORY.csv mismatches      0
```

## Recovery source

```text
Filename
222A_msbf_m2_12_failed_precommit_certification_generation_sequence_state_recovery_v1.sql

Bytes
22,425

SHA-256
8087d51cd6d1dbcf89371d4219e787b53221ddf3a5959053af1306fef0967627

Approved identity match
PASS
```

## Scope

The package contains one executable source: approved Recovery 222A. It contains no executable normal program and no other recovery source. Program 222 HF9 remains unchanged and must be retried only after pre-recovery verification, 222A execution, post-recovery verification, and a fresh exact HF9 pre-execution verifier PASS.
