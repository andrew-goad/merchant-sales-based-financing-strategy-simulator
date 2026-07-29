# M1.15 v0.2R3 Root-Cause and Logic-Alignment Review

## Evidence

M1.15 generation completed with 3,751 canonical entities and zero mismatches.
Positive validation then returned one failure: POS62 reported one continuous
resilience-score increase. All of the following passed:

- M1.11 exact reproduction;
- resilience delta identity;
- resilience worsening-flag identity;
- risk, capacity, LGD, contribution, return, and tier non-improvement controls;
- all physical and set hashes.

## Authoritative upstream design

Accepted M1.11 validation enforces:

- `M1_11_POS_45_STRESS_TIER_NONIMPROVEMENT`; and
- `M1_11_POS_48_STRESS_ARCHETYPE_NONIMPROVEMENT`.

It does not enforce continuous-score non-improvement. Its generation applies
floors to final tier and archetype risk rank, not to the continuous score.

## Resolution

M1.15 now validates the same accepted interpretation contract. The score
increase remains visible as descriptive scenario evidence and is not erased,
floored, or reclassified.

## Logic preservation

No generation, contract, comparison, row-hash, set-hash, payload, lineage,
routing, review, hard-stop, or upstream-reproduction logic changed. Programs
112–115 are executable-logic equivalent to v0.2R2 after revision comments are
removed. Only program 111's POS62 validation specification and the supporting
archetype-pair materialization changed.
