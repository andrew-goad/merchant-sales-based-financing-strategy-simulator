# MSBF - Campaign Scale 750 - 2,500 - 25,000

Part 06 · [Conversation index](README.md) · [History home](../../README.md)

> Historical dialogue: commands and approvals below describe past events. They are not current execution or publication instructions. Attachment references do not establish recovered bytes.

[Previous part](part-05.md)
[Next part](part-07.md)

<a id="m-ab287a6e-a9c7-4e41-9878-8ee9556b7991"></a>
## Andrew / user · C093-M00104

C093-M00104 · 2026-08-20T20:30:27.915000-04:00 · active path

Preceding visible parent: [C093-M00103](part-05.md#m-9ba4e8be-be57-4713-84b6-b25f4629e7ee)

<!-- BEGIN_SOURCE_MESSAGE -->
PS D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000> $Results = Import-Csv `
>>     (Join-Path $EvidenceRoot "R4_NATIVE_ADVERSARIAL_AND_PRODUCTION_PATH_RESULTS.csv")
PS D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000> $Results |
>>     Where-Object status -eq "FAIL" |
>>     Format-List *

test_id        : R4-NAT-016A
expected       : 435_GOVERNED_QUERY_RENDERS_PASS
actual         : RENDER_FAILURE
status         : FAIL
detail         : renders=363 failures=001_g0_00.checkpoint.json|CS_0750_ACCEPTED_FIDELITY|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                 001_g0_00.checkpoint.json|CS_2500_PERFORMANCE_SHAKEDOWN|The property 'Name' cannot be found on this object. Verify that the property exists. || 001_g0_00.checkpoint.json|CS_25000_FULL_CAMPAIGN|The property 'Name'
                 cannot be found on this object. Verify that the property exists. || 002_g0_01.checkpoint.json|CS_0750_ACCEPTED_FIDELITY|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                 002_g0_01.checkpoint.json|CS_2500_PERFORMANCE_SHAKEDOWN|The property 'Name' cannot be found on this object. Verify that the property exists. || 002_g0_01.checkpoint.json|CS_25000_FULL_CAMPAIGN|The property 'Name'
                 cannot be found on this object. Verify that the property exists. || 055_m1_8_52.checkpoint.json|CS_0750_ACCEPTED_FIDELITY|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                 055_m1_8_52.checkpoint.json|CS_2500_PERFORMANCE_SHAKEDOWN|The property 'Name' cannot be found on this object. Verify that the property exists. || 055_m1_8_52.checkpoint.json|CS_25000_FULL_CAMPAIGN|The property 'Name'
                 cannot be found on this object. Verify that the property exists. || 063_m1_9_60.checkpoint.json|CS_0750_ACCEPTED_FIDELITY|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                 063_m1_9_60.checkpoint.json|CS_2500_PERFORMANCE_SHAKEDOWN|The property 'Name' cannot be found on this object. Verify that the property exists. || 063_m1_9_60.checkpoint.json|CS_25000_FULL_CAMPAIGN|The property 'Name'
                 cannot be found on this object. Verify that the property exists. || 071_m1_10_68.checkpoint.json|CS_0750_ACCEPTED_FIDELITY|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                 071_m1_10_68.checkpoint.json|CS_2500_PERFORMANCE_SHAKEDOWN|The property 'Name' cannot be found on this object. Verify that the property exists. || 071_m1_10_68.checkpoint.json|CS_25000_FULL_CAMPAIGN|The property 'Name'
                 cannot be found on this object. Verify that the property exists. || 079_m1_11_76.checkpoint.json|CS_0750_ACCEPTED_FIDELITY|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                 079_m1_11_76.checkpoint.json|CS_2500_PERFORMANCE_SHAKEDOWN|The property 'Name' cannot be found on this object. Verify that the property exists. || 079_m1_11_76.checkpoint.json|CS_25000_FULL_CAMPAIGN|The property 'Name'
                 cannot be found on this object. Verify that the property exists. || 087_m1_12_84.checkpoint.json|CS_0750_ACCEPTED_FIDELITY|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                 087_m1_12_84.checkpoint.json|CS_2500_PERFORMANCE_SHAKEDOWN|The property 'Name' cannot be found on this object. Verify that the property exists. || 087_m1_12_84.checkpoint.json|CS_25000_FULL_CAMPAIGN|The property 'Name'
                 cannot be found on this object. Verify that the property exists. || 095_m1_13_92.checkpoint.json|CS_0750_ACCEPTED_FIDELITY|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                 095_m1_13_92.checkpoint.json|CS_2500_PERFORMANCE_SHAKEDOWN|The property 'Name' cannot be found on this object. Verify that the property exists. || 095_m1_13_92.checkpoint.json|CS_25000_FULL_CAMPAIGN|The property 'Name'
                 cannot be found on this object. Verify that the property exists. || 103_m1_14_100.checkpoint.json|CS_0750_ACCEPTED_FIDELITY|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                 103_m1_14_100.checkpoint.json|CS_2500_PERFORMANCE_SHAKEDOWN|The property 'Name' cannot be found on this object. Verify that the property exists. || 103_m1_14_100.checkpoint.json|CS_25000_FULL_CAMPAIGN|The property
                 'Name' cannot be found on this object. Verify that the property exists. || 111_m1_15_108.checkpoint.json|CS_0750_ACCEPTED_FIDELITY|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                 111_m1_15_108.checkpoint.json|CS_2500_PERFORMANCE_SHAKEDOWN|The property 'Name' cannot be found on this object. Verify that the property exists. || 111_m1_15_108.checkpoint.json|CS_25000_FULL_CAMPAIGN|The property
                 'Name' cannot be found on this object. Verify that the property exists. || 119_m1_16_116.checkpoint.json|CS_0750_ACCEPTED_FIDELITY|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                 119_m1_16_116.checkpoint.json|CS_2500_PERFORMANCE_SHAKEDOWN|The property 'Name' cannot be found on this object. Verify that the property exists. || 119_m1_16_116.checkpoint.json|CS_25000_FULL_CAMPAIGN|The property
                 'Name' cannot be found on this object. Verify that the property exists. || 127_m1_17_124.checkpoint.json|CS_0750_ACCEPTED_FIDELITY|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                 127_m1_17_124.checkpoint.json|CS_2500_PERFORMANCE_SHAKEDOWN|The property 'Name' cannot be found on this object. Verify that the property exists. || 127_m1_17_124.checkpoint.json|CS_25000_FULL_CAMPAIGN|The property
                 'Name' cannot be found on this object. Verify that the property exists. || 135_m2_1_132.checkpoint.json|CS_0750_ACCEPTED_FIDELITY|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                 135_m2_1_132.checkpoint.json|CS_2500_PERFORMANCE_SHAKEDOWN|The property 'Name' cannot be found on this object. Verify that the property exists. || 135_m2_1_132.checkpoint.json|CS_25000_FULL_CAMPAIGN|The property 'Name'
                 cannot be found on this object. Verify that the property exists. || 143_m2_2_140.checkpoint.json|CS_0750_ACCEPTED_FIDELITY|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                 143_m2_2_140.checkpoint.json|CS_2500_PERFORMANCE_SHAKEDOWN|The property 'Name' cannot be found on this object. Verify that the property exists. || 143_m2_2_140.checkpoint.json|CS_25000_FULL_CAMPAIGN|The property 'Name'
                 cannot be found on this object. Verify that the property exists. || 151_m2_3_148.checkpoint.json|CS_0750_ACCEPTED_FIDELITY|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                 151_m2_3_148.checkpoint.json|CS_2500_PERFORMANCE_SHAKEDOWN|The property 'Name' cannot be found on this object. Verify that the property exists. || 151_m2_3_148.checkpoint.json|CS_25000_FULL_CAMPAIGN|The property 'Name'
                 cannot be found on this object. Verify that the property exists. || 159_m2_4_156.checkpoint.json|CS_0750_ACCEPTED_FIDELITY|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                 159_m2_4_156.checkpoint.json|CS_2500_PERFORMANCE_SHAKEDOWN|The property 'Name' cannot be found on this object. Verify that the property exists. || 159_m2_4_156.checkpoint.json|CS_25000_FULL_CAMPAIGN|The property 'Name'
                 cannot be found on this object. Verify that the property exists. || 167_m2_5_164.checkpoint.json|CS_0750_ACCEPTED_FIDELITY|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                 167_m2_5_164.checkpoint.json|CS_2500_PERFORMANCE_SHAKEDOWN|The property 'Name' cannot be found on this object. Verify that the property exists. || 167_m2_5_164.checkpoint.json|CS_25000_FULL_CAMPAIGN|The property 'Name'
                 cannot be found on this object. Verify that the property exists. || 175_m2_6_172.checkpoint.json|CS_0750_ACCEPTED_FIDELITY|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                 175_m2_6_172.checkpoint.json|CS_2500_PERFORMANCE_SHAKEDOWN|The property 'Name' cannot be found on this object. Verify that the property exists. || 175_m2_6_172.checkpoint.json|CS_25000_FULL_CAMPAIGN|The property 'Name'
                 cannot be found on this object. Verify that the property exists. || 183_m2_7_180.checkpoint.json|CS_0750_ACCEPTED_FIDELITY|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                 183_m2_7_180.checkpoint.json|CS_2500_PERFORMANCE_SHAKEDOWN|The property 'Name' cannot be found on this object. Verify that the property exists. || 183_m2_7_180.checkpoint.json|CS_25000_FULL_CAMPAIGN|The property 'Name'
                 cannot be found on this object. Verify that the property exists. || 191_m2_8_188.checkpoint.json|CS_0750_ACCEPTED_FIDELITY|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                 191_m2_8_188.checkpoint.json|CS_2500_PERFORMANCE_SHAKEDOWN|The property 'Name' cannot be found on this object. Verify that the property exists. || 191_m2_8_188.checkpoint.json|CS_25000_FULL_CAMPAIGN|The property 'Name'
                 cannot be found on this object. Verify that the property exists. || 199_m2_9_196.checkpoint.json|CS_0750_ACCEPTED_FIDELITY|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                 199_m2_9_196.checkpoint.json|CS_2500_PERFORMANCE_SHAKEDOWN|The property 'Name' cannot be found on this object. Verify that the property exists. || 199_m2_9_196.checkpoint.json|CS_25000_FULL_CAMPAIGN|The property 'Name'
                 cannot be found on this object. Verify that the property exists. || 207_m2_10_204.checkpoint.json|CS_0750_ACCEPTED_FIDELITY|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                 207_m2_10_204.checkpoint.json|CS_2500_PERFORMANCE_SHAKEDOWN|The property 'Name' cannot be found on this object. Verify that the property exists. || 207_m2_10_204.checkpoint.json|CS_25000_FULL_CAMPAIGN|The property
                 'Name' cannot be found on this object. Verify that the property exists. || 215_m2_11_212.checkpoint.json|CS_0750_ACCEPTED_FIDELITY|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                 215_m2_11_212.checkpoint.json|CS_2500_PERFORMANCE_SHAKEDOWN|The property 'Name' cannot be found on this object. Verify that the property exists. || 215_m2_11_212.checkpoint.json|CS_25000_FULL_CAMPAIGN|The property
                 'Name' cannot be found on this object. Verify that the property exists. || 223_m2_12_220.checkpoint.json|CS_0750_ACCEPTED_FIDELITY|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                 223_m2_12_220.checkpoint.json|CS_2500_PERFORMANCE_SHAKEDOWN|The property 'Name' cannot be found on this object. Verify that the property exists. || 223_m2_12_220.checkpoint.json|CS_25000_FULL_CAMPAIGN|The property
                 'Name' cannot be found on this object. Verify that the property exists.
carrier_sha256 : d57a90256adfa265c9f1777a01f88158e4499c57d42c1d2571bc56f174a15342

test_id        : R4-NAT-017
expected       : TRANSCRIPT_PASS
actual         : REJECT
status         : FAIL
detail         : Cannot overwrite variable PID because it is read-only or constant.
carrier_sha256 : d57a90256adfa265c9f1777a01f88158e4499c57d42c1d2571bc56f174a15342

test_id        : R4-NAT-018
expected       : REJECT
actual         : REJECT_OTHER
status         : FAIL
detail         : Cannot overwrite variable PID because it is read-only or constant.
carrier_sha256 : d57a90256adfa265c9f1777a01f88158e4499c57d42c1d2571bc56f174a15342

test_id        : R4-NAT-019
expected       : REJECT
actual         : REJECT_OTHER
status         : FAIL
detail         : Cannot overwrite variable PID because it is read-only or constant.
carrier_sha256 : d57a90256adfa265c9f1777a01f88158e4499c57d42c1d2571bc56f174a15342

test_id        : R4-NAT-020
expected       : REJECT
actual         : REJECT_OTHER
status         : FAIL
detail         : Cannot overwrite variable PID because it is read-only or constant.
carrier_sha256 : d57a90256adfa265c9f1777a01f88158e4499c57d42c1d2571bc56f174a15342

test_id        : R4-NAT-021
expected       : PRODUCTION_CHAIN_PASS
actual         : REJECT
status         : FAIL
detail         : Canonical profile-binding mismatch: source_plan_lock_path
carrier_sha256 : d57a90256adfa265c9f1777a01f88158e4499c57d42c1d2571bc56f174a15342

test_id        : R4-NAT-021A
expected       : PARAMETERIZED_PRODUCTION_CHAIN_PASS
actual         : REJECT
status         : FAIL
detail         : Canonical profile-binding mismatch: source_plan_lock_path
carrier_sha256 : d57a90256adfa265c9f1777a01f88158e4499c57d42c1d2571bc56f174a15342

test_id        : R4-NAT-022
expected       : REJECT
actual         : REJECT_OTHER
status         : FAIL
detail         : Canonical profile-binding mismatch: source_plan_lock_path
carrier_sha256 : d57a90256adfa265c9f1777a01f88158e4499c57d42c1d2571bc56f174a15342

test_id        : R4-NAT-023
expected       : REJECT
actual         : REJECT_OTHER
status         : FAIL
detail         : Canonical profile-binding mismatch: source_plan_lock_path
carrier_sha256 : d57a90256adfa265c9f1777a01f88158e4499c57d42c1d2571bc56f174a15342

test_id        : R4-NAT-024
expected       : REJECT
actual         : REJECT_OTHER
status         : FAIL
detail         : Canonical profile-binding mismatch: source_plan_lock_path
carrier_sha256 : d57a90256adfa265c9f1777a01f88158e4499c57d42c1d2571bc56f174a15342

test_id        : R4-NAT-025
expected       : REJECT
actual         : REJECT_OTHER
status         : FAIL
detail         : Canonical profile-binding mismatch: source_plan_lock_path
carrier_sha256 : d57a90256adfa265c9f1777a01f88158e4499c57d42c1d2571bc56f174a15342

test_id        : R4-NAT-026
expected       : REJECT
actual         : REJECT_OTHER
status         : FAIL
detail         : Canonical profile-binding mismatch: source_plan_lock_path
carrier_sha256 : d57a90256adfa265c9f1777a01f88158e4499c57d42c1d2571bc56f174a15342

test_id        : R4-NAT-027
expected       : REJECT
actual         : REJECT_OTHER
status         : FAIL
detail         : Canonical profile-binding mismatch: source_plan_lock_path
carrier_sha256 : d57a90256adfa265c9f1777a01f88158e4499c57d42c1d2571bc56f174a15342

test_id        : R4-NAT-027A
expected       : REJECT
actual         : REJECT_OTHER
status         : FAIL
detail         : Canonical profile-binding mismatch: source_plan_lock_path
carrier_sha256 : d57a90256adfa265c9f1777a01f88158e4499c57d42c1d2571bc56f174a15342

test_id        : R4-NAT-028
expected       : REJECT
actual         : REJECT_OTHER
status         : FAIL
detail         : Canonical profile-binding mismatch: source_plan_lock_path
carrier_sha256 : d57a90256adfa265c9f1777a01f88158e4499c57d42c1d2571bc56f174a15342

test_id        : R4-NAT-029
expected       : REJECT
actual         : REJECT_OTHER
status         : FAIL
detail         : Canonical profile-binding mismatch: source_plan_lock_path
carrier_sha256 : d57a90256adfa265c9f1777a01f88158e4499c57d42c1d2571bc56f174a15342

test_id        : R4-NAT-038
expected       : FAILURE_QUARANTINED
actual         : QUARANTINE_MISSING
status         : FAIL
detail         : Canonical profile-binding mismatch: source_plan_lock_path
carrier_sha256 : d57a90256adfa265c9f1777a01f88158e4499c57d42c1d2571bc56f174a15342

PS D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000> $Results |
>>     Where-Object status -eq "FAIL" |
>>     Select-Object test_id, expected, actual, status, detail |
>>     Format-Table -Wrap -AutoSize

test_id     expected                            actual             status detail
-------     --------                            ------             ------ ------
R4-NAT-016A 435_GOVERNED_QUERY_RENDERS_PASS     RENDER_FAILURE     FAIL   renders=363 failures=001_g0_00.checkpoint.json|CS_0750_ACCEPTED_FIDELITY|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                                                                          001_g0_00.checkpoint.json|CS_2500_PERFORMANCE_SHAKEDOWN|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                                                                          001_g0_00.checkpoint.json|CS_25000_FULL_CAMPAIGN|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                                                                          002_g0_01.checkpoint.json|CS_0750_ACCEPTED_FIDELITY|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                                                                          002_g0_01.checkpoint.json|CS_2500_PERFORMANCE_SHAKEDOWN|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                                                                          002_g0_01.checkpoint.json|CS_25000_FULL_CAMPAIGN|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                                                                          055_m1_8_52.checkpoint.json|CS_0750_ACCEPTED_FIDELITY|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                                                                          055_m1_8_52.checkpoint.json|CS_2500_PERFORMANCE_SHAKEDOWN|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                                                                          055_m1_8_52.checkpoint.json|CS_25000_FULL_CAMPAIGN|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                                                                          063_m1_9_60.checkpoint.json|CS_0750_ACCEPTED_FIDELITY|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                                                                          063_m1_9_60.checkpoint.json|CS_2500_PERFORMANCE_SHAKEDOWN|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                                                                          063_m1_9_60.checkpoint.json|CS_25000_FULL_CAMPAIGN|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                                                                          071_m1_10_68.checkpoint.json|CS_0750_ACCEPTED_FIDELITY|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                                                                          071_m1_10_68.checkpoint.json|CS_2500_PERFORMANCE_SHAKEDOWN|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                                                                          071_m1_10_68.checkpoint.json|CS_25000_FULL_CAMPAIGN|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                                                                          079_m1_11_76.checkpoint.json|CS_0750_ACCEPTED_FIDELITY|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                                                                          079_m1_11_76.checkpoint.json|CS_2500_PERFORMANCE_SHAKEDOWN|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                                                                          079_m1_11_76.checkpoint.json|CS_25000_FULL_CAMPAIGN|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                                                                          087_m1_12_84.checkpoint.json|CS_0750_ACCEPTED_FIDELITY|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                                                                          087_m1_12_84.checkpoint.json|CS_2500_PERFORMANCE_SHAKEDOWN|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                                                                          087_m1_12_84.checkpoint.json|CS_25000_FULL_CAMPAIGN|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                                                                          095_m1_13_92.checkpoint.json|CS_0750_ACCEPTED_FIDELITY|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                                                                          095_m1_13_92.checkpoint.json|CS_2500_PERFORMANCE_SHAKEDOWN|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                                                                          095_m1_13_92.checkpoint.json|CS_25000_FULL_CAMPAIGN|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                                                                          103_m1_14_100.checkpoint.json|CS_0750_ACCEPTED_FIDELITY|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                                                                          103_m1_14_100.checkpoint.json|CS_2500_PERFORMANCE_SHAKEDOWN|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                                                                          103_m1_14_100.checkpoint.json|CS_25000_FULL_CAMPAIGN|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                                                                          111_m1_15_108.checkpoint.json|CS_0750_ACCEPTED_FIDELITY|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                                                                          111_m1_15_108.checkpoint.json|CS_2500_PERFORMANCE_SHAKEDOWN|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                                                                          111_m1_15_108.checkpoint.json|CS_25000_FULL_CAMPAIGN|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                                                                          119_m1_16_116.checkpoint.json|CS_0750_ACCEPTED_FIDELITY|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                                                                          119_m1_16_116.checkpoint.json|CS_2500_PERFORMANCE_SHAKEDOWN|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                                                                          119_m1_16_116.checkpoint.json|CS_25000_FULL_CAMPAIGN|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                                                                          127_m1_17_124.checkpoint.json|CS_0750_ACCEPTED_FIDELITY|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                                                                          127_m1_17_124.checkpoint.json|CS_2500_PERFORMANCE_SHAKEDOWN|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                                                                          127_m1_17_124.checkpoint.json|CS_25000_FULL_CAMPAIGN|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                                                                          135_m2_1_132.checkpoint.json|CS_0750_ACCEPTED_FIDELITY|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                                                                          135_m2_1_132.checkpoint.json|CS_2500_PERFORMANCE_SHAKEDOWN|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                                                                          135_m2_1_132.checkpoint.json|CS_25000_FULL_CAMPAIGN|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                                                                          143_m2_2_140.checkpoint.json|CS_0750_ACCEPTED_FIDELITY|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                                                                          143_m2_2_140.checkpoint.json|CS_2500_PERFORMANCE_SHAKEDOWN|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                                                                          143_m2_2_140.checkpoint.json|CS_25000_FULL_CAMPAIGN|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                                                                          151_m2_3_148.checkpoint.json|CS_0750_ACCEPTED_FIDELITY|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                                                                          151_m2_3_148.checkpoint.json|CS_2500_PERFORMANCE_SHAKEDOWN|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                                                                          151_m2_3_148.checkpoint.json|CS_25000_FULL_CAMPAIGN|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                                                                          159_m2_4_156.checkpoint.json|CS_0750_ACCEPTED_FIDELITY|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                                                                          159_m2_4_156.checkpoint.json|CS_2500_PERFORMANCE_SHAKEDOWN|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                                                                          159_m2_4_156.checkpoint.json|CS_25000_FULL_CAMPAIGN|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                                                                          167_m2_5_164.checkpoint.json|CS_0750_ACCEPTED_FIDELITY|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                                                                          167_m2_5_164.checkpoint.json|CS_2500_PERFORMANCE_SHAKEDOWN|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                                                                          167_m2_5_164.checkpoint.json|CS_25000_FULL_CAMPAIGN|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                                                                          175_m2_6_172.checkpoint.json|CS_0750_ACCEPTED_FIDELITY|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                                                                          175_m2_6_172.checkpoint.json|CS_2500_PERFORMANCE_SHAKEDOWN|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                                                                          175_m2_6_172.checkpoint.json|CS_25000_FULL_CAMPAIGN|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                                                                          183_m2_7_180.checkpoint.json|CS_0750_ACCEPTED_FIDELITY|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                                                                          183_m2_7_180.checkpoint.json|CS_2500_PERFORMANCE_SHAKEDOWN|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                                                                          183_m2_7_180.checkpoint.json|CS_25000_FULL_CAMPAIGN|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                                                                          191_m2_8_188.checkpoint.json|CS_0750_ACCEPTED_FIDELITY|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                                                                          191_m2_8_188.checkpoint.json|CS_2500_PERFORMANCE_SHAKEDOWN|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                                                                          191_m2_8_188.checkpoint.json|CS_25000_FULL_CAMPAIGN|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                                                                          199_m2_9_196.checkpoint.json|CS_0750_ACCEPTED_FIDELITY|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                                                                          199_m2_9_196.checkpoint.json|CS_2500_PERFORMANCE_SHAKEDOWN|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                                                                          199_m2_9_196.checkpoint.json|CS_25000_FULL_CAMPAIGN|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                                                                          207_m2_10_204.checkpoint.json|CS_0750_ACCEPTED_FIDELITY|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                                                                          207_m2_10_204.checkpoint.json|CS_2500_PERFORMANCE_SHAKEDOWN|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                                                                          207_m2_10_204.checkpoint.json|CS_25000_FULL_CAMPAIGN|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                                                                          215_m2_11_212.checkpoint.json|CS_0750_ACCEPTED_FIDELITY|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                                                                          215_m2_11_212.checkpoint.json|CS_2500_PERFORMANCE_SHAKEDOWN|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                                                                          215_m2_11_212.checkpoint.json|CS_25000_FULL_CAMPAIGN|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                                                                          223_m2_12_220.checkpoint.json|CS_0750_ACCEPTED_FIDELITY|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                                                                          223_m2_12_220.checkpoint.json|CS_2500_PERFORMANCE_SHAKEDOWN|The property 'Name' cannot be found on this object. Verify that the property exists. ||
                                                                          223_m2_12_220.checkpoint.json|CS_25000_FULL_CAMPAIGN|The property 'Name' cannot be found on this object. Verify that the property exists.
R4-NAT-017  TRANSCRIPT_PASS                     REJECT             FAIL   Cannot overwrite variable PID because it is read-only or constant.
R4-NAT-018  REJECT                              REJECT_OTHER       FAIL   Cannot overwrite variable PID because it is read-only or constant.
R4-NAT-019  REJECT                              REJECT_OTHER       FAIL   Cannot overwrite variable PID because it is read-only or constant.
R4-NAT-020  REJECT                              REJECT_OTHER       FAIL   Cannot overwrite variable PID because it is read-only or constant.
R4-NAT-021  PRODUCTION_CHAIN_PASS               REJECT             FAIL   Canonical profile-binding mismatch: source_plan_lock_path
R4-NAT-021A PARAMETERIZED_PRODUCTION_CHAIN_PASS REJECT             FAIL   Canonical profile-binding mismatch: source_plan_lock_path
R4-NAT-022  REJECT                              REJECT_OTHER       FAIL   Canonical profile-binding mismatch: source_plan_lock_path
R4-NAT-023  REJECT                              REJECT_OTHER       FAIL   Canonical profile-binding mismatch: source_plan_lock_path
R4-NAT-024  REJECT                              REJECT_OTHER       FAIL   Canonical profile-binding mismatch: source_plan_lock_path
R4-NAT-025  REJECT                              REJECT_OTHER       FAIL   Canonical profile-binding mismatch: source_plan_lock_path
R4-NAT-026  REJECT                              REJECT_OTHER       FAIL   Canonical profile-binding mismatch: source_plan_lock_path
R4-NAT-027  REJECT                              REJECT_OTHER       FAIL   Canonical profile-binding mismatch: source_plan_lock_path
R4-NAT-027A REJECT                              REJECT_OTHER       FAIL   Canonical profile-binding mismatch: source_plan_lock_path
R4-NAT-028  REJECT                              REJECT_OTHER       FAIL   Canonical profile-binding mismatch: source_plan_lock_path
R4-NAT-029  REJECT                              REJECT_OTHER       FAIL   Canonical profile-binding mismatch: source_plan_lock_path
R4-NAT-038  FAILURE_QUARANTINED                 QUARANTINE_MISSING FAIL   Canonical profile-binding mismatch: source_plan_lock_path

PS D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000> $Results |
>>     Select-Object test_id, status, expected, actual |
>>     Format-Table -AutoSize

test_id     status expected                            actual
-------     ------ --------                            ------
R4-NAT-001  PASS   ALL_AST_PASS                        ALL_AST_PASS
R4-NAT-002  PASS   IMPORT_PASS                         IMPORT_PASS
R4-NAT-003  PASS   PARAMETERS_ALIGNED                  PARAMETERS_ALIGNED
R4-NAT-004  PASS   SUPPORTED_HASH_BOUND_IMPORTS        SUPPORTED_HASH_BOUND_IMPORTS
R4-NAT-004A PASS   REJECT                              REJECT
R4-NAT-005  PASS   230_UNIQUE_HASHED_BINDINGS          230_UNIQUE_HASHED_BINDINGS
R4-NAT-006  PASS   3_UNIQUE_HASHED_PROFILES            3_UNIQUE_HASHED_PROFILES
R4-NAT-007  PASS   REJECT                              REJECT
R4-NAT-008  PASS   REJECT                              REJECT
R4-NAT-009  PASS   REJECT                              REJECT
R4-NAT-010  PASS   REJECT                              REJECT
R4-NAT-011  PASS   REJECT                              REJECT
R4-NAT-012  PASS   REJECT                              REJECT
R4-NAT-013  PASS   REJECT                              REJECT
R4-NAT-014  PASS   REJECT                              REJECT
R4-NAT-015  PASS   REJECT                              REJECT
R4-NAT-016  PASS   ACCEPT_READ_ONLY                    ACCEPT_READ_ONLY
R4-NAT-016A FAIL   435_GOVERNED_QUERY_RENDERS_PASS     RENDER_FAILURE
R4-NAT-016B PASS   EXACT_PROFILE_RENDER_PASS           EXACT_PROFILE_RENDER_PASS
R4-NAT-016C PASS   REJECT                              REJECT
R4-NAT-016D PASS   REJECT                              REJECT
R4-NAT-016E PASS   REJECT                              REJECT
R4-NAT-017  FAIL   TRANSCRIPT_PASS                     REJECT
R4-NAT-018  FAIL   REJECT                              REJECT_OTHER
R4-NAT-019  FAIL   REJECT                              REJECT_OTHER
R4-NAT-020  FAIL   REJECT                              REJECT_OTHER
R4-NAT-021  FAIL   PRODUCTION_CHAIN_PASS               REJECT
R4-NAT-021A FAIL   PARAMETERIZED_PRODUCTION_CHAIN_PASS REJECT
R4-NAT-022  FAIL   REJECT                              REJECT_OTHER
R4-NAT-023  FAIL   REJECT                              REJECT_OTHER
R4-NAT-024  FAIL   REJECT                              REJECT_OTHER
R4-NAT-025  FAIL   REJECT                              REJECT_OTHER
R4-NAT-026  FAIL   REJECT                              REJECT_OTHER
R4-NAT-027  FAIL   REJECT                              REJECT_OTHER
R4-NAT-027A FAIL   REJECT                              REJECT_OTHER
R4-NAT-028  FAIL   REJECT                              REJECT_OTHER
R4-NAT-029  FAIL   REJECT                              REJECT_OTHER
R4-NAT-029A PASS   REJECT                              REJECT
R4-NAT-029B PASS   REJECT                              REJECT
R4-NAT-030  PASS   REJECT                              REJECT
R4-NAT-031  PASS   REJECT                              REJECT
R4-NAT-031A PASS   REJECT                              REJECT
R4-NAT-032  PASS   REJECT                              REJECT
R4-NAT-033  PASS   REJECT                              REJECT
R4-NAT-034A PASS   REJECT                              REJECT
R4-NAT-034B PASS   REJECT                              REJECT
R4-NAT-034C PASS   REJECT                              REJECT
R4-NAT-034D PASS   REJECT                              REJECT
R4-NAT-034  PASS   REJECT                              REJECT
R4-NAT-035  PASS   REJECT                              REJECT
R4-NAT-036  PASS   FAKE_PSQL_NO_NETWORK                FAKE_PSQL_NO_NETWORK
R4-NAT-037  PASS   HF07_PROVENANCE_PRESERVED           HF07_PROVENANCE_PRESERVED
R4-NAT-038  FAIL   FAILURE_QUARANTINED                 QUARANTINE_MISSING
<!-- END_SOURCE_MESSAGE -->


<a id="m-d176d980-389b-4631-b919-434547bc938e"></a>
## Assistant · C093-M00105

C093-M00105 · 2026-08-20T20:31:22.469303-04:00 · active path

Preceding visible parent: [C093-M00104](part-06.md#m-ab287a6e-a9c7-4e41-9878-8ee9556b7991)

<!-- BEGIN_SOURCE_MESSAGE -->
This is a very clean diagnostic result. The **17 failures collapse to exactly three root causes**, rather than 17 independent defects:

1. **Governed-query renderer — 1 failed control (`R4-NAT-016A`).** The renderer uses `$bindingsProperty.Value.PSObject.Properties.Name`. Under `Set-StrictMode`, definitions with an empty `psql_variable_bindings` object can yield an empty property collection on which `.Name` is invalid. That accounts for exactly **72 failed renders**: `435 expected − 363 successful = 72`, or **24 checkpoint definitions × 3 profiles**. The bounded correction is to enumerate property names explicitly, e.g. `@($bindingsProperty.Value.PSObject.Properties | ForEach-Object { $_.Name })`.

2. **Synthetic transcript helper — 4 failed controls (`R4-NAT-017` through `020`).** `New-SyntheticTranscript` assigns `$pid = '91001'`. PowerShell variable names are case-insensitive, so `$pid` collides with the read-only automatic `$PID` variable. Renaming this local variable to something such as `$backendPid` fixes the positive transcript test and lets the three adversarial transcript tests reach their intended rejection conditions.

3. **Canonical source-plan binding — 12 failed controls (`R4-NAT-021`, `021A`, `022–029`, and `038`).** Both the production driver and independent trust gate compare the profile catalog's relative `source_plan_lock_path` against authorization `source_plan_relative_path` **after converting both as though they were absolute paths**. The row path is correctly resolved relative to the package; the authorization's relative path is incorrectly resolved relative to the host working directory. The correct canonical mapping is for profile `source_plan_lock_path` to resolve against the signed absolute **`source_plan_path`**, while the adapter-binding catalog separately continues to bind the relative **`source_plan_relative_path`**. This one defect prematurely rejects every production-path case—including the quarantine case—before those tests reach their intended assertions.

The accounting is exact:

```text
Renderer defect                  1 failed control
$PID collision                   4 failed controls
Source-plan canonicalization    12 failed controls
                               ------------------
Total                           17 failed controls
```

This is encouraging because the important R4 controls already demonstrated that the **actual production chain was entered using the fake-psql process**, while real `psql`, PostgreSQL connections, database actions, recovery, and replay all remained false. The failures are implementation/test-harness defects around that path, not evidence that the no-database boundary failed.

The next bounded action should therefore be **CR-WP5 R4 Correction R2**, limited to those three root causes: harden empty binding-name enumeration, rename the synthetic `$pid` variable, correct the source-plan absolute/relative comparison in both the independent trust gate and production driver, then regenerate every affected binding/protected/package identity and issue a fresh exact-byte native runner. I would also add static non-regression checks specifically proving **24 empty-binding definitions are accepted, no assignment to `$PID`/`$pid` exists, and both trust gate and driver use the same source-plan mapping**, before you run PowerShell again.
<!-- END_SOURCE_MESSAGE -->


<a id="m-fbc14fa9-0956-4005-ac97-c684f40cffcb"></a>
## Andrew / user · C093-M00106

C093-M00106 · 2026-08-20T20:33:35.171000-04:00 · active path

Preceding visible parent: [C093-M00105](part-06.md#m-d176d980-389b-4631-b919-434547bc938e)

<!-- BEGIN_SOURCE_MESSAGE -->
Perform the next bounded action: **CR-WP5 R4 Correction R2**, limited to those three root causes: harden empty binding-name enumeration, rename the synthetic `$pid` variable, correct the source-plan absolute/relative comparison in both the independent trust gate and production driver, then regenerate every affected binding/protected/package identity and issue a fresh exact-byte native runner. I would also add static non-regression checks specifically proving **24 empty-binding definitions are accepted, no assignment to** **`$PID`****/****`$pid`** **exists, and both trust gate and driver use the same source-plan mapping**, before you run PowerShell again.  
<!-- END_SOURCE_MESSAGE -->


<a id="m-1faf4383-c7ff-428d-b029-aa7df302a374"></a>
## Assistant · C093-M00107

C093-M00107 · 2026-08-20T20:39:00.831986-04:00 · active path

Preceding visible parent: [C093-M00106](part-06.md#m-fbc14fa9-0956-4005-ac97-c684f40cffcb)

<!-- BEGIN_SOURCE_MESSAGE -->
I’ve confirmed the R1 carrier has exactly the three diagnosed implementation defects and that the affected physical-query population is exactly **24 empty-binding definitions out of 145 package-relative checkpoint queries**. I’m rebuilding R2 with only those fixes plus the required identity propagation and three explicit non-regression controls.
<!-- END_SOURCE_MESSAGE -->


<a id="m-4a2a75b7-5a2e-4edb-8788-08644149ad46"></a>
## Assistant · C093-M00108

C093-M00108 · 2026-08-20T20:41:14.951985-04:00 · active path

Preceding visible parent: [C093-M00107](part-06.md#m-1faf4383-c7ff-428d-b029-aa7df302a374)

<!-- BEGIN_SOURCE_MESSAGE -->
## CR-WP5 R4 Correction R2 complete

The bounded R2 source correction is complete and remains within the authorized static-remediation boundary. The three diagnosed R1 root causes were corrected, all dependent definition/binding/protected/package identities were regenerated, and no PostgreSQL, real `psql`, database, checkpoint/report, recovery, or campaign execution occurred. That remains consistent with the governing R4 instruction. [export reference: filecite | turn20file1 | L7-L17] [export reference: filecite | turn20file1 | L19-L30]

The requested non-regression checks now pass:

| Control | Result |
|---|---:|
| Empty-binding physical query definitions | **24 / 24 PASS** |
| `$PID` / `$pid` assignments across PowerShell population | **0** |
| Trust-gate/driver source-plan mapping | **PASS — identical** |
| R1 bare-command/comma syntax regression | **0 hits** |
| Definitions rebound to corrected executable identities | **230 / 230** |
| Canonical adapter-binding rows rebuilt | **230 / 230** |
| Static control register | **32 / 32 PASS** |
| R2 correction-specific controls | **6 / 6 PASS** |
| Standalone static validator | **PASS** |
| Native PowerShell evidence | **PENDING** |

### Controlling R2 identities

```text
Source carrier
MSBF_CR_WP5_R4_CORRECTION_R2_STATIC_REMEDIATION_20260820.zip

SHA-256
ad1ed9334b268330f547e2e3222501a1202b84cb9f777a1c72131bab51036c98

Bytes
44,080,310

ZIP entries
1,069

Manifest rows
1,065

Manifest SHA-256
0eb665b96682925045fd5c282ff481d92d2ff748bfb1936bf1167fb8471b6e76

Package payload-tree SHA-256
dbd422e7f103506c28eac5c45adf0262b9b018e437eee45678f8acaf30acd431

Bootstrap SHA-256
c98ed93ab8b4f8321e69995362881b0ab481a56da886341caf11e113d9fe5d8e

Production driver SHA-256
b18c33d6cb9379cc4a4eabb0dffef69d20102d56b9f9fab889249472a9794d85

Module SHA-256
2f4574cd0b56e27a7887ccc4e6d0ba7eb333dac16336080713a02c5c08fa9b3d

Native harness SHA-256
b695c45104bf890bffb19c8bdd91e188c7d55bcba8337859fa590a75518b53d1

Adapter-binding catalog SHA-256
f5e40075784937c19d95603a0e4dcdd03bb3183510b1e9e2a698f648f230e361

Protected-manifest SHA-256
57c1c82bd9b6706d5982cbe1da457dd31624ee00a859a66047f5a94ea1c24085

Protected-tree SHA-256
105136929d01c707df032addad31cd8d6c4627ba39a40b4f96d2dc6ac25138be
```

The external bootstrap/trust-anchor/signer package was also regenerated against the corrected bootstrap bytes and remains explicitly **pending independent approval**, not self-approved.

| Deliverable | File |
|---|---|
| R2 source carrier | Download (historical reference: `sandbox:[session]/MSBF_CR_WP5_R4_CORRECTION_R2_STATIC_REMEDIATION_20260820.zip`; referenced bytes not established here) |
| Source SHA-256 sidecar | Download (historical reference: `sandbox:[session]/MSBF_CR_WP5_R4_CORRECTION_R2_STATIC_REMEDIATION_20260820.zip.sha256`; referenced bytes not established here) |
| External validation report | Open (historical reference: `sandbox:[session]/MSBF_CR_WP5_R4_CORRECTION_R2_STATIC_REMEDIATION_20260820_VALIDATION_REPORT.md`; referenced bytes not established here) |
| Machine validation | Download (historical reference: `sandbox:[session]/MSBF_CR_WP5_R4_CORRECTION_R2_STATIC_REMEDIATION_20260820_VALIDATION_REPORT.json`; referenced bytes not established here) |
| Standalone static validation | Download (historical reference: `sandbox:[session]/MSBF_CR_WP5_R4_CORRECTION_R2_STATIC_REMEDIATION_20260820_STANDALONE_VALIDATION.json`; referenced bytes not established here) |
| Correction R2 report | Open (historical reference: `sandbox:[session]/_crwp5_r4_correction_r2_build/16_CORRECTION_R2/CR_WP5_R4_CORRECTION_R2_REPORT.md`; referenced bytes not established here) |
| R2 non-regression controls | Download (historical reference: `sandbox:[session]/_crwp5_r4_correction_r2_build/16_CORRECTION_R2/CORRECTION_R2_NONREGRESSION_CONTROLS.csv`; referenced bytes not established here) |
| 24 empty-binding definition inventory | Download (historical reference: `sandbox:[session]/_crwp5_r4_correction_r2_build/16_CORRECTION_R2/EMPTY_BINDING_PHYSICAL_QUERY_DEFINITIONS.csv`; referenced bytes not established here) |
| `$PID` scan evidence | Download (historical reference: `sandbox:[session]/_crwp5_r4_correction_r2_build/16_CORRECTION_R2/POWERSHELL_PID_ASSIGNMENT_SCAN.csv`; referenced bytes not established here) |
| Source-plan reconciliation | Download (historical reference: `sandbox:[session]/_crwp5_r4_correction_r2_build/16_CORRECTION_R2/SOURCE_PLAN_MAPPING_RECONCILIATION.json`; referenced bytes not established here) |
| R1→R2 exact source diff | Download (historical reference: `sandbox:[session]/_crwp5_r4_correction_r2_build/16_CORRECTION_R2/CORRECTION_R1_TO_R2_SOURCE_DIFF.csv`; referenced bytes not established here) |
| R2 bootstrap candidate | Download (historical reference: `sandbox:[session]/MSBF_CR_WP5_R4_CORRECTION_R2_PREIMPORT_BOOTSTRAP_CANDIDATE_20260820.zip`; referenced bytes not established here) |
| Bootstrap sidecar | Download (historical reference: `sandbox:[session]/MSBF_CR_WP5_R4_CORRECTION_R2_PREIMPORT_BOOTSTRAP_CANDIDATE_20260820.zip.sha256`; referenced bytes not established here) |
| External authority approval request | Download (historical reference: `sandbox:[session]/MSBF_CR_WP5_R4_CORRECTION_R2_EXTERNAL_AUTHORITY_APPROVAL_REQUEST_20260820.zip`; referenced bytes not established here) |
| Approval-request sidecar | Download (historical reference: `sandbox:[session]/MSBF_CR_WP5_R4_CORRECTION_R2_EXTERNAL_AUTHORITY_APPROVAL_REQUEST_20260820.zip.sha256`; referenced bytes not established here) |
| Fresh R2 native runner | Download (historical reference: `sandbox:[session]/Run-CRWP5R4CorrectionR2NativeEvidence.ps1`; referenced bytes not established here) |
| Runner sidecar | Download (historical reference: `sandbox:[session]/Run-CRWP5R4CorrectionR2NativeEvidence.ps1.sha256`; referenced bytes not established here) |
| Native-run instructions | Open (historical reference: `sandbox:[session]/CR_WP5_R4_CORRECTION_R2_NATIVE_RUN_INSTRUCTIONS.md`; referenced bytes not established here) |

The fresh runner is bound to the exact R2 carrier above. Its SHA-256 is:

```text
0e1bb17d915397453c3d8184dbf0b008174bc9b40d87768ef41b118c20da27b0
```

Run it in PowerShell 7.6.5/Core from a clean directory containing the R2 carrier and runner:

```powershell
$PSVersionTable.PSVersion
$PSVersionTable.PSEdition

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

& .\Run-CRWP5R4CorrectionR2NativeEvidence.ps1 `
    -BasePath (Get-Location).Path
```

If successful, it should create:

```text
CR_WP5_R4_CORRECTION_R2_NATIVE_EVIDENCE.zip
CR_WP5_R4_CORRECTION_R2_NATIVE_EVIDENCE.zip.sha256
```

Upload those two files unchanged. I would not prepare the final `ER-CAM-004/005/006/007` wrapper until that exact-byte native run passes.
<!-- END_SOURCE_MESSAGE -->


<a id="m-f22c04e0-2488-4833-b32c-bade529fae68"></a>
## Andrew / user · C093-M00109

C093-M00109 · 2026-08-20T21:09:57.276000-04:00 · active path

Preceding visible parent: [C093-M00108](part-06.md#m-4a2a75b7-5a2e-4edb-8788-08644149ad46)

<!-- BEGIN_SOURCE_MESSAGE -->
PS D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000> $PSVersionTable.PSVersion
>> $PSVersionTable.PSEdition
>>
>> Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
>>
>> & .\Run-CRWP5R4CorrectionR2NativeEvidence.ps1 `
>>     -BasePath (Get-Location).Path

Major  Minor  Patch  PreReleaseLabel BuildLabel
-----  -----  -----  --------------- ----------
7      6      5
Core
{
  "schema_version": "MSBF_CR_WP5_R4_NATIVE_OFFLINE_TEST_SUMMARY_V1",
  "carrier_sha256": "ad1ed9334b268330f547e2e3222501a1202b84cb9f777a1c72131bab51036c98",
  "package_manifest_sha256": "0eb665b96682925045fd5c282ff481d92d2ff748bfb1936bf1167fb8471b6e76",
  "package_payload_tree_sha256": "dbd422e7f103506c28eac5c45adf0262b9b018e437eee45678f8acaf30acd431",
  "complete_extracted_tree_sha256": "339884275dafc7b4bb10a3ccd5f554ef10ea4918fa4f89a10f8696989c65a64f",
  "protected_tree_manifest_sha256": "57c1c82bd9b6706d5982cbe1da457dd31624ee00a859a66047f5a94ea1c24085",
  "protected_tree_sha256": "105136929d01c707df032addad31cd8d6c4627ba39a40b4f96d2dc6ac25138be",
  "ast_files": 6,
  "ast_pass": 6,
  "tests": 53,
  "pass": 52,
  "fail": 1,
  "overall_status": "FAIL",
  "production_chain_tested": true,
  "fake_psql_process_invoked": true,
  "real_psql_process_invoked": false,
  "postgresql_connection_attempted": false,
  "database_action_performed": false,
  "checkpoint_report_executed_against_database": false,
  "recovery_invoked": false,
  "campaign_replay_invoked": false,
  "tested_at_utc": "2026-08-21T01:06:54.8391294+00:00"
}
Exception: D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\Run-CRWP5R4CorrectionR2NativeEvidence.ps1:61
Line |
  61 |      throw 'R4 native suite did not pass.'
     |      ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     | R4 native suite did not pass.
<!-- END_SOURCE_MESSAGE -->


<a id="m-42e37eb2-f928-4edf-80b6-fd06c56385a4"></a>
## Assistant · C093-M00110

C093-M00110 · 2026-08-20T21:10:03.702934-04:00 · active path

Preceding visible parent: [C093-M00109](part-06.md#m-f22c04e0-2488-4833-b32c-bade529fae68)

<!-- BEGIN_SOURCE_MESSAGE -->
This is very close: Correction R2 completed the full native suite and the exact fake-`psql` production path with **52/53 PASS**. The database-safety boundary also held completely—real `psql`, PostgreSQL, database actions, checkpoint/report execution, recovery, and replay all remain false.

Do **not** rerun R2 yet. We need the single failed control before changing any bytes.

Run this in the same PowerShell window:

```powershell
$EvidenceRoot = Join-Path (Get-Location).Path `
    "CR_WP5_R4_CORRECTION_R2_NATIVE_EVIDENCE"

$Results = Import-Csv `
    (Join-Path $EvidenceRoot "R4_NATIVE_ADVERSARIAL_AND_PRODUCTION_PATH_RESULTS.csv")

$Results |
    Where-Object status -eq "FAIL" |
    Format-List *
```

Then run the compact view:

```powershell
$Results |
    Where-Object status -eq "FAIL" |
    Select-Object test_id, expected, actual, status, detail
```

And, for context, show the tests immediately around the failed test:

```powershell
$Failed = $Results | Where-Object status -eq "FAIL"

$Results |
    Select-Object test_id, status, expected, actual |
    Format-Table -AutoSize
```

Paste those outputs here.

The important progression is:

```text
R4 original native attempt        parse failure
Correction R1                     36 / 53 PASS
Correction R2                     52 / 53 PASS

AST                               6 / 6 PASS
Production chain tested           true
Fake psql invoked                 true
Real psql invoked                 false
PostgreSQL attempted              false
Database action                   false
Recovery / replay                 false
```

So the three R2 root-cause corrections appear to have eliminated **16 of the 17** prior failures. We should identify the remaining row before deciding whether this needs a very narrow Correction R3 or is merely a stale native-test expectation.
<!-- END_SOURCE_MESSAGE -->


<a id="m-9aeb3eb3-5ced-4f6f-9648-cf3e768ab2e2"></a>
## Andrew / user · C093-M00111

C093-M00111 · 2026-08-20T21:13:06.556000-04:00 · active path

Preceding visible parent: [C093-M00110](part-06.md#m-42e37eb2-f928-4edf-80b6-fd06c56385a4)

<!-- BEGIN_SOURCE_MESSAGE -->
PS D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000> $EvidenceRoot = Join-Path (Get-Location).Path `
>>     "CR_WP5_R4_CORRECTION_R2_NATIVE_EVIDENCE"
>>
>> $Results = Import-Csv `
>>     (Join-Path $EvidenceRoot "R4_NATIVE_ADVERSARIAL_AND_PRODUCTION_PATH_RESULTS.csv")
>>
>> $Results |
>>     Where-Object status -eq "FAIL" |
>>     Format-List *

test_id        : R4-NAT-024
expected       : REJECT
actual         : REJECT_OTHER
status         : FAIL
detail         : The property 'execution_attempt_id' cannot be found on this object. Verify that the property exists.
carrier_sha256 : ad1ed9334b268330f547e2e3222501a1202b84cb9f777a1c72131bab51036c98

PS D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000> $Results |
>>     Where-Object status -eq "FAIL" |
>>     Select-Object test_id, expected, actual, status, detail

test_id  : R4-NAT-024
expected : REJECT
actual   : REJECT_OTHER
status   : FAIL
detail   : The property 'execution_attempt_id' cannot be found on this object. Verify that the property exists.

PS D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000> $Failed = $Results | Where-Object status -eq "FAIL"
>>
>> $Results |
>>     Select-Object test_id, status, expected, actual |
>>     Format-Table -AutoSize

test_id     status expected                            actual
-------     ------ --------                            ------
R4-NAT-001  PASS   ALL_AST_PASS                        ALL_AST_PASS
R4-NAT-002  PASS   IMPORT_PASS                         IMPORT_PASS
R4-NAT-003  PASS   PARAMETERS_ALIGNED                  PARAMETERS_ALIGNED
R4-NAT-004  PASS   SUPPORTED_HASH_BOUND_IMPORTS        SUPPORTED_HASH_BOUND_IMPORTS
R4-NAT-004A PASS   REJECT                              REJECT
R4-NAT-005  PASS   230_UNIQUE_HASHED_BINDINGS          230_UNIQUE_HASHED_BINDINGS
R4-NAT-006  PASS   3_UNIQUE_HASHED_PROFILES            3_UNIQUE_HASHED_PROFILES
R4-NAT-007  PASS   REJECT                              REJECT
R4-NAT-008  PASS   REJECT                              REJECT
R4-NAT-009  PASS   REJECT                              REJECT
R4-NAT-010  PASS   REJECT                              REJECT
R4-NAT-011  PASS   REJECT                              REJECT
R4-NAT-012  PASS   REJECT                              REJECT
R4-NAT-013  PASS   REJECT                              REJECT
R4-NAT-014  PASS   REJECT                              REJECT
R4-NAT-015  PASS   REJECT                              REJECT
R4-NAT-016  PASS   ACCEPT_READ_ONLY                    ACCEPT_READ_ONLY
R4-NAT-016A PASS   435_GOVERNED_QUERY_RENDERS_PASS     435_GOVERNED_QUERY_RENDERS_PASS
R4-NAT-016B PASS   EXACT_PROFILE_RENDER_PASS           EXACT_PROFILE_RENDER_PASS
R4-NAT-016C PASS   REJECT                              REJECT
R4-NAT-016D PASS   REJECT                              REJECT
R4-NAT-016E PASS   REJECT                              REJECT
R4-NAT-017  PASS   TRANSCRIPT_PASS                     TRANSCRIPT_PASS
R4-NAT-018  PASS   REJECT                              REJECT
R4-NAT-019  PASS   REJECT                              REJECT
R4-NAT-020  PASS   REJECT                              REJECT
R4-NAT-021  PASS   PRODUCTION_CHAIN_PASS               PRODUCTION_CHAIN_PASS
R4-NAT-021A PASS   PARAMETERIZED_PRODUCTION_CHAIN_PASS PARAMETERIZED_PRODUCTION_CHAIN_PASS
R4-NAT-022  PASS   REJECT                              REJECT
R4-NAT-023  PASS   REJECT                              REJECT
R4-NAT-024  FAIL   REJECT                              REJECT_OTHER
R4-NAT-025  PASS   REJECT                              REJECT
R4-NAT-026  PASS   REJECT                              REJECT
R4-NAT-027  PASS   REJECT                              REJECT
R4-NAT-027A PASS   REJECT                              REJECT
R4-NAT-028  PASS   REJECT                              REJECT
R4-NAT-029  PASS   REJECT                              REJECT
R4-NAT-029A PASS   REJECT                              REJECT
R4-NAT-029B PASS   REJECT                              REJECT
R4-NAT-030  PASS   REJECT                              REJECT
R4-NAT-031  PASS   REJECT                              REJECT
R4-NAT-031A PASS   REJECT                              REJECT
R4-NAT-032  PASS   REJECT                              REJECT
R4-NAT-033  PASS   REJECT                              REJECT
R4-NAT-034A PASS   REJECT                              REJECT
R4-NAT-034B PASS   REJECT                              REJECT
R4-NAT-034C PASS   REJECT                              REJECT
R4-NAT-034D PASS   REJECT                              REJECT
R4-NAT-034  PASS   REJECT                              REJECT
R4-NAT-035  PASS   REJECT                              REJECT
R4-NAT-036  PASS   FAKE_PSQL_NO_NETWORK                FAKE_PSQL_NO_NETWORK
R4-NAT-037  PASS   HF07_PROVENANCE_PRESERVED           HF07_PROVENANCE_PRESERVED
R4-NAT-038  PASS   FAILURE_QUARANTINED                 FAILURE_QUARANTINED
<!-- END_SOURCE_MESSAGE -->


<a id="m-7b062d08-dee5-47b3-b4c2-5de9c1bc52d8"></a>
## Assistant · C093-M00112

C093-M00112 · 2026-08-20T21:13:59.104616-04:00 · active path

Preceding visible parent: [C093-M00111](part-06.md#m-9aeb3eb3-5ced-4f6f-9648-cf3e768ab2e2)

<!-- BEGIN_SOURCE_MESSAGE -->
The remaining failure is now isolated to **one narrow assertion-order defect**, not a production-path or trust-control failure.

`R4-NAT-024` deliberately emits this spoofed marker payload:

```text
__MSBF_ACTUAL_TARGET_IDENTITY__|{}
```

The production transcript validator currently evaluates:

```powershell
$record.execution_attempt_id
```

before checking whether the record even contains the required fields. Under `Set-StrictMode`, the missing property throws:

```text
The property 'execution_attempt_id' cannot be found on this object.
```

So the spoof is correctly rejected, but it is rejected by PowerShell’s missing-property exception rather than by the intended governed failure:

```text
Transcript backend PID missing ...
```

Everything else in R2 now passes:

```text
AST                              6 / 6 PASS
Native controls                 52 / 53 PASS
435 governed query renders     PASS
Synthetic transcript baseline  PASS
Production baseline            PASS
Parameterized production path  PASS
Quarantine                     PASS
Fake psql no-network           PASS

Real psql invoked              false
PostgreSQL attempted           false
Database action                false
Recovery / replay              false
```

So the appropriate next action is a very small **CR-WP5 R4 Correction R3**: harden the transcript-field presence checks so missing `execution_attempt_id` / `backend_pid` fields fail through explicit governed rejection rather than StrictMode property access, preserve the `MARKER_ONLY_SPOOF` fixture unchanged, add a static test proving missing marker fields are handled explicitly, regenerate affected module/definition/binding/protected/package identities, and run the exact-byte native suite again.

I would **not change the R4-NAT-024 expectation or fake-psql fixture**. The adversarial test is valid; the validator should handle malformed marker JSON deliberately rather than relying on an incidental PowerShell exception.
<!-- END_SOURCE_MESSAGE -->


<a id="m-16ee0f94-0401-4bb0-b1c1-91484826aa1c"></a>
## Andrew / user · C093-M00113

C093-M00113 · 2026-08-20T21:15:59.145000-04:00 · active path

Preceding visible parent: [C093-M00112](part-06.md#m-7b062d08-dee5-47b3-b4c2-5de9c1bc52d8)

<!-- BEGIN_SOURCE_MESSAGE -->
Perform a very small **CR-WP5 R4 Correction R3**: harden the transcript-field presence checks so missing `execution_attempt_id` / `backend_pid` fields fail through explicit governed rejection rather than StrictMode property access, preserve the `MARKER_ONLY_SPOOF` fixture unchanged, add a static test proving missing marker fields are handled explicitly, regenerate affected module/definition/binding/protected/package identities, and run the exact-byte native suite again.

I would **not change the R4-NAT-024 expectation or fake-psql fixture**. The adversarial test is valid; the validator should handle malformed marker JSON deliberately rather than relying on an incidental PowerShell exception.
<!-- END_SOURCE_MESSAGE -->


<a id="m-f0e65d1e-bd1c-44e4-961d-b6c777728b0e"></a>
## Assistant · C093-M00114

C093-M00114 · 2026-08-20T21:16:01.975743-04:00 · active path

Preceding visible parent: [C093-M00113](part-06.md#m-16ee0f94-0401-4bb0-b1c1-91484826aa1c)

<!-- BEGIN_SOURCE_MESSAGE -->
I’m applying only the malformed-transcript hardening: explicit field-presence validation before any `execution_attempt_id` or `backend_pid` dereference, leaving `R4-NAT-024` and the `MARKER_ONLY_SPOOF` fixture unchanged. I’ll then propagate only the resulting module/definition/binding/protected/package identities, add the static non-regression control, and attempt the exact-byte native suite if PowerShell 7 is available in this runtime.
<!-- END_SOURCE_MESSAGE -->
