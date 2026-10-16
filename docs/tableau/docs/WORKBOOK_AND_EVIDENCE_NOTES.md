# Tableau workbook and evidence notes

[Tableau overview](../README.md) · [Asset manifest](../manifests/ASSET_MANIFEST.json)

## Supplied workbook identity

- File: `release/MCI_Risk_Decision_Scenario_Review.twb`
- Bytes: 538,188
- SHA-256: `21ec53b067a7950b8bb09b52ed47aa7c54c12d783fcd79f53a261ae6594fe43d`
- Authored with the Tableau Public build recorded in the file: `2026.2.3 (20262.26.0912.1023)`.
- Contents inspected: one dashboard, 14 worksheets and five workbook parameters.
- The original workbook bytes have not been changed by this documentation update.

The file retains author-local connection references and Tableau-generated machine/author metadata. The recorded connection password is empty; this is not an assertion that arbitrary future workbook revisions are cleared for public disclosure. The authoring definition must be reviewed as an intentional source artifact, not advertised as a portable data package.

## Open the right artifact

**For a quick review**, use the [carousel PDF](MCI_Risk_Decision_Scenario_Review_Carousel.pdf) and its linked PNG pages. These are complete, static evidence artifacts.

**For local authoring**, the `.twb` references `MCI_Matched_Applications_With_Narratives.csv` and an enabled temporary Hyper extract. Neither data file is present in the supplied Tableau folder. A reviewer without those resources must reconnect the original data, or obtain a packaged workbook saved by the author with its data. Renaming `.twb` to `.twbx` does not package the dependencies. See [Tableau's packaged-workbook guidance](https://help.tableau.com/current/pro/desktop/en-us/save_savework_packagedworkbooks.htm).

**For the live dashboard**, use the exact Tableau Public Share URL when supplied by the owner. The recorded repository workbook ID alone does not establish a verified public view URL. This file does not invent a live link or claim an externally tested session.

## Interaction contract

| Control | Scope |
| --- | --- |
| Industry / Acquisition Source filters | Define the reviewed portfolio; apply to portfolio indicators, narrative, comparisons and investigation. |
| Review Segment By | Changes the grouping used by both segment charts. |
| Segment Analysis Mode | Chooses Portfolio Authorization or Selected Pairing. |
| Matrix filter action | Narrows application detail and individual narrative targets. |
| Matrix parameter actions | Store the two selected decision codes; do not remove segment denominator rows. |
| Application action | Selects one matched application for the two scenario explanations. |
| Narrative Detail | Changes Decision / Evidence / Structure / Source rationale. |

The supplied workbook's two filter-action exclusion lists preserve the four portfolio indicator sheets, executive narrative and both segment charts. Both selected-decision parameter domains contain the seven source decision codes and the `ALL` reset value.

Select one matrix cell for the paired-code parameter workflow. A row/header or multi-cell selection is not equivalent to one decision pairing. Clear an individual application before changing the pairing if the old application would otherwise intersect the new scope. `ALL` is a no-pairing/reset sentinel in the provided calculation; its zero flag is not evidence of zero incidence for a substantive pairing.

## Reference checks

| Check | Expected value |
| --- | --- |
| All portfolio filters cleared | 750 matched; 236 different; 103 Baseline and 27 stress authorized. |
| Healthcare Services; all acquisition sources | 82 matched; 29 different; 15 Baseline and 4 stress authorized. |
| Counteroffer review required / Evidence decline, all portfolio filters | 88 matched in the pairing; Healthcare incidence 10 / 82 = 12.2%. |
| Merchant 003, Decision / Evidence | Baseline review; stress evidence decline with 28 usable sales days against 30 required. |
| Merchant 098, Structure | $5,200 requested/Baseline authorized; $2,500 stress authorized counteroffer. |
| Merchant 258, Structure | Same review category; $80,400 and $69,800 selected alternatives. |
| Policy hard stop / Policy hard stop | 117 matched applications; no individual binding rule inferred without selecting a merchant. |

These are reference observations from the supplied Tableau captures and retained project material. The documentation preparation does not certify every native interaction, browser behavior or future data refresh.

## Carousel identity and filename corrections

The PDF is unchanged: **3,167,866 bytes**, SHA-256 `94ee881fc35d5c7134eed69bb89fa732b299190f313fcdb822e7a341b5ae0eed`. Its 13 page PNGs are the original rendered pages, not newly generated Tableau charts. The manifest maps original uploaded names to corrected subject names. The excluded concentration screenshots are not introduced by this update.

No screenshot was recolored, sharpened, recreated or otherwise edited here. Changing a filename changes navigation only; it does not change the visual evidence.

## Scope of this update

This is a documentation and portfolio addition. It does not create a release, increment a simulator or workbook version, alter tags, modify the accepted Power BI file, change source policy/data, run SQL, execute a campaign, or convert historical audit findings into current Tableau acceptance. Historical authority records and release metadata remain unchanged.
