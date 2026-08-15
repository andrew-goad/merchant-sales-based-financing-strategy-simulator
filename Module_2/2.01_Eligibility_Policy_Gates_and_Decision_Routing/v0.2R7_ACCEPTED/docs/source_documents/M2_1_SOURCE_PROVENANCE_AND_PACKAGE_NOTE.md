# M2.1 Source Provenance and Packaging Note

The final accepted package preserves:

- the exact original M2.1 v0.2 source package;
- compact source and root-cause records for revisions R1 through R7;
- the exact source files used in the accepted live execution sequence;
- the synchronized v0.2R7 clean-build source;
- all supplied program checkpoints, recovery evidence, final controls, acceptance output, master report, and 24 detailed result sets;
- the original error screenshots and stage-boundary diagnostics.

The exact source provenance is indexed in `accepted_execution/SOURCE_PROVENANCE.csv`. The accepted database sequence used mixed revisions by design: generation remained at v0.2R1, the final positive and negative controls were v0.2R6, and the final acceptance/report layer was v0.2R7. The clean-build source folds the accepted corrections into one pristine v0.2R7 module without falsely representing that every clean-build file was the revision originally executed.

Accepted M1.17 baseline archive:

```text
MSBF_Project_v0_2_M1_17_COMPLETE_FINAL_Windows.zip
SHA-256: cd89f292ee2909e60428fa507996cbd99d17aca87b49af0a62bf389cc567fa0b
```

Final M2.1 hotfix source archive:

```text
MSBF_M2_1_v0_2R7_Acceptance_Column_Qualification_Hotfix.zip
SHA-256: c4b8eb84f6911b7ccc47b6eec611a341271202e33b065a8e125e4aba88ae9000
```
