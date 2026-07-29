# Module and Release Index

The table below is the public release index for the accepted Module 1 G2 boundary.

| Public stage | Canonical stage | Accepted revision | Status | Principal identity | Output scale |
|---|---|---:|---:|---|---|
| [1.01](./Module_1/1.01_Charter_Architecture_and_Requirements/README.md) | `DESIGN` | `v0.1R1_DOCUMENTATION` | **DOCUMENTATION** | `Documentation / baseline metadata` | Architecture charters, logical model, data-contract catalog, stage boundaries, and long-horizon roadmap. |
| [0.01](./Module_0/0.01_G0_Physical_Data_Foundation/README.md) | `G0` | `v0.2` | **ACCEPTED** | `Documentation / baseline metadata` | G0 baseline: 70 physical parent tables, 1,041 designed columns, plus four partition children. |
| [0.02](./Module_0/0.02_G1_Governed_Run_Control/README.md) | `G1` | `v0.2` | **ACCEPTED** | `bd09e598... / 462cbd2... / 93c3d136...` | Governed run M1_V0_2_BASELINE_BUILD, version 1, with three accepted snapshot identities. |
| [1.02](./Module_1/1.02_Deterministic_Merchant_Population/README.md) | `M1.2` | `v0.2R2` | **ACCEPTED** | `9b706c926260a3ef1ae8ac95eed5d0bf` | 750 merchants and 4,352 canonical entities. |
| [1.03](./Module_1/1.03_Application_and_Requested_Structure/README.md) | `M1.3` | `v0.2R1` | **ACCEPTED** | `01485256b9b5748fb412743d35ced602` | 750 applications and requested financing structures. |
| [1.04](./Module_1/1.04_Daily_POS_Settlement_and_Ecosystem/README.md) | `M1.4` | `v0.2` | **ACCEPTED** | `d1971e8d319483c187ec0c0483a31e33` | 135,000 baseline daily POS and settlement rows. |
| [1.05](./Module_1/1.05_Daily_Deposit_and_Liquidity_History/README.md) | `M1.5` | `v0.2R2` | **ACCEPTED** | `bbe96dd24fbbba3af4a587dd475a88d0` | 135,000 daily deposit and liquidity rows. |
| [1.06](./Module_1/1.06_Matched_POS_and_Deposit_Scenarios/README.md) | `M1.6` | `v0.2R3` | **ACCEPTED** | `3f85921bf6fc30ddc6cee146085e58c5` | 270,000 POS scenario rows + 270,000 deposit scenario rows; 540,000 canonical entities. |
| [1.07](./Module_1/1.07_Source_Quality_and_Data_Confidence/README.md) | `M1.7` | `v0.2` | **ACCEPTED** | `de56a458d9ec0b344886850592c4e6c8` | 5,250 source-quality records across 750 applications. |
| [1.08](./Module_1/1.08_Verification_Fraud_and_Continuity/README.md) | `M1.8` | `v0.2R1` | **ACCEPTED** | `604a5640a25da92a850840dbe13e3d56` | 4,500 atomic checks + 750 application summaries; 5,250 canonical entities. |
| [1.09](./Module_1/1.09_As_Of_Cash_Flow_Features/README.md) | `M1.9` | `v0.2R5` | **ACCEPTED** | `7c25acac533179f42789a6daa79d0cc3` | 1,500 wide snapshots + 54,000 long-form values across 36 features; 55,500 canonical entities. |
| [1.10](./Module_1/1.10_Obligations_Liquidity_and_Capacity/README.md) | `M1.10` | `v0.2R2` | **ACCEPTED** | `a91e82a315305a98953d013043a17d9a` | 906 atomic obligations + 1,500 capacity snapshots; 2,406 canonical entities. |
| [1.11](./Module_1/1.11_Cash_Flow_Archetypes_and_Resilience/README.md) | `M1.11` | `v0.2R2` | **ACCEPTED** | `d219b2a0cb6d32f400b1ab71be6521fb` | 1,500 snapshots + 7,500 component rows; 9,000 canonical entities. |
| [1.12](./Module_1/1.12_Merchant_Risk_and_Integrated_Proxy/README.md) | `M1.12` | `v0.2R1` | **ACCEPTED** | `fb583c3fdd92f141ba5af1ddf942ffba` | 1,500 risk snapshots + 10,500 component rows; 12,000 canonical entities. |
| [1.13](./Module_1/1.13_Exposure_Recovery_and_Expected_Loss/README.md) | `M1.13` | `v0.2R1` | **ACCEPTED** | `11dca65763f4062ad9002244ee6452f9` | 93,720 exposure-path rows + 1,500 snapshots; 95,220 canonical entities. |
| [1.14](./Module_1/1.14_Unit_Economics_and_Contribution/README.md) | `M1.14` | `v0.2R4` | **ACCEPTED** | `3a47f59b56fa158c18c111caa1c64909` | 1,500 snapshots + 21,000 component rows; 22,500 canonical entities. |
| [1.15](./Module_1/1.15_Latest_Archive_Comparison_and_Contract/README.md) | `M1.15` | `v0.2R3` | **ACCEPTED** | `fcd2704e17ec0d2e73191ea36061d74b` | 1 registry + 1,500 latest + 1,500 archive + 750 comparisons; 3,751 canonical entities. |
| [1.16](./Module_1/1.16_Acquisition_Attribution_and_CAC/README.md) | `M1.16` | `v0.2R3` | **ACCEPTED** | `86df51a0ca68d84096d00ff0f1b19f33` | 13,274 canonical entities, including 750 acquisition contracts and a 1,500-row integrated M1.15 x M1.16 view. |
| [1.17](./Module_1/1.17_End_to_End_QA_and_G2_Acceptance/README.md) | `M1.17` | `v0.2R8` | **ACCEPTED** | `7d9e466da28cad2551aa99c4c40c912b` | 18 hash-chain rows + 48 assurance records + one latest/archive/registry bundle; 69 canonical entities. |

## Final G2 Release

- **Release tag:** `module-1-g2-v1.0.0`
- **Canonical source ZIP SHA-256:** `cd89f292ee2909e60428fa507996cbd99d17aca87b49af0a62bf389cc567fa0b`
- **Combined G2 canonical set:** `7d9e466da28cad2551aa99c4c40c912b`
- **Final gate:** `G2_M1_CONTRACT - PASS`
- **Next authorized macro-stage:** Module 2 - Strategy and Offer Decisioning
