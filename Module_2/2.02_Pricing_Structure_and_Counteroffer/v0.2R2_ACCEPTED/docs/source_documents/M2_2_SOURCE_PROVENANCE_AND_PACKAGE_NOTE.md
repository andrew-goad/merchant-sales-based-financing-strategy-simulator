# M2.2 Source Provenance and Package Note

The accepted source chain is:

```text
Programs 140 and 141        original v0.2
Program 140B                v0.2R1
Program 140C                v0.2R2
Programs 142–147            v0.2R2
```

The accepted M2.1 full-project baseline was checksum-verified before packaging:

```text
Archive  MSBF_Project_v0_2_M2_1_COMPLETE_FINAL_Windows.zip
SHA-256 40fc6cdf927740a017c245fe84d89bf427b9fd3e9ba47c223b1d99fe463a4fc5
Files    2801
```

The final module preserves the original v0.2 source, the R1 target-typed hash
correction, and the R2 selected-structure stress-floor correction under
`source_history`.

Direct result exports for Programs 140C and 142–145 were not included in the
user-supplied evidence batches. They were not recreated or mislabeled as live
exports. Their committed state is proven by the accepted master report,
contract registry, evidence summary, counts, hashes, zero-reproduction
mismatches, and zero exception outputs.
