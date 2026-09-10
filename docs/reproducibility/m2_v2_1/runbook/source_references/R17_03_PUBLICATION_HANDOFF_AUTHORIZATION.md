# Power BI Publication Handoff Authorization

**Authorization ID:** `IA-PBI-PUB-HANDOFF-001`  
**Decision:** `IA-D-R17-PBI-001`  
**Status:** `AUTHORIZED`

The corrected R3 Power BI publication candidate is independently accepted for direct handoff to the separately controlled GitHub publication action.

## Frozen accepted identities

```text
Publication-support package SHA-256
1fe42707eabfb53512729581ded0dc2d1addf7ca4f6e4d4de594f3f3ea37551a

Client-facing PBIX SHA-256
ca46e8551860836a0cf4ff9239c42fcf8df02f1705596b9f8ca1bd047b5294e4

Embedded DataModel SHA-256
24396d02c0fbcb782cc9918e842886711146b8ff9455c8822d2aeaf009b96061
```

## Publication boundary

This authorization permits handoff only. It does not itself:
- publish to GitHub;
- activate public supersession;
- authorize production use;
- authorize causal, CECL, audited-profitability, autonomous-decision, real-merchant, or real-funds claims.

Post-publication hosted-asset hash/size and Windows-native extraction verification remain part of the separate release-closure action.
