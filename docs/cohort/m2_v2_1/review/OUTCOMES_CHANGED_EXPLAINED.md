# Origin of “Outcomes Changed — 31.5%”

**Compared field:** `governed_final_outcome_code`. **Matched identity:** retained run and `merchant_application_id`. **Compared scenarios:** Baseline vs. Recession Energy.

The source contains 1,500 unique application-scenario keys forming 750 complete two-scenario pairs. Count one pair when the two final categorical outcomes differ.

- Different outcome: **236 / 750 = 31.4666…% → 31.5%**.
- Same outcome: **514 / 750 = 68.5333…% → 68.5%**.

The page-14 matrix’s diagonal sums to 514; its off-diagonal cells sum to 236. The largest changed cells are counteroffer review → evidence decline (88), counteroffer review → no feasible structure (51), and approve as requested → evidence decline (47). The other off-diagonal transitions sum to 50.

Two approve-as-requested paths become authorized counteroffers; those count as category changes, although they remain authorized. Conversely, a changed amount or rate with the same final category is not counted by this metric.

The report’s original derivation is in `private/scripts/derive_cohort.py`, migration block lines 108–116. The output is `private/derived/outcome_transitions.csv`, with 49 cells. The present check independently reread the exact retained final-decision CSV, verified uniqueness and complete pairing, and matched every derived cell. It did not run the financing engine or overwrite any historical output.

This figure does not compare the old and new software releases; nor does it compare strategy profiles or represent chronological merchant outcomes. The denominator is 750 pairs, not 1,500 independent merchants.
