# Registers

These registers provide the machine-readable and audit-friendly detail behind the corrected final rc2 publication candidate. Canonical Source of Truth **R7** is controlling. The R3 requirements and traceability registers retain **142/142 requirements verified**. The R7 validation control register records **51 PASS / 0 DEFERRED / 1 PENDING**; the sole pending control is the separately authorized GitHub publication/public-supersession action after Independent Audit ACCEPT.

R16 correction evidence is explicit:

- `CURRENT_PHYSICAL_VISUAL_REFERENCES_R7.csv` - complete physical field-reference scan across all 96 visual JSON files;
- `CURRENT_PHYSICAL_FILTER_REFERENCES_R7.csv` - every physical `filterConfig` row and active predicate;
- `PHYSICAL_VISUAL_REFERENCE_SCAN_SUMMARY_R7.csv` - page/portfolio scan totals;
- `FOCUSED_CORRECTION_PBIX_MEMBER_DIFF_R7.csv` - exact four-member PBIX diff from the audited R2 candidate;
- `MSBF_MCI_POWER_BI_VALIDATION_CONTROL_REGISTER_R7_20260904.csv` - includes five focused-correction controls.

The current physical scan reports **0 predecessor-fact references and 0 predecessor-fact filter rows**. Some underlying semantic-model annotations retain construction-era text for lineage; they are physical metadata, not current authority. Current authority is accepted R26 technical authority, the corrected client-facing rc2 PBIX, Canonical Source of Truth R7, and the focused correction/persistence receipts.
