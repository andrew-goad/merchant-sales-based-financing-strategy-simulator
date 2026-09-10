# R20 Desktop adjudication and R21 correction

R20 proved physical refresh, table load, model relationships, save, close, and reopen. Two successor cards failed. Source inspection identified a deterministic semantic typing defect: the governed successor CSVs encode boolean flags as `t`/`f` text and the model intentionally imported them as text, while four R1 measures compared those columns to DAX `TRUE()`. R21 corrects all four measures at once.

R21 also fixes the comparison-page interaction contract: selected strategy remains the detail context, while charts explicitly titled *by strategy profile* ignore that slicer and show all eight profiles. P05 Industry and Source outcome, and P06 Control scope, open at All instead of forcing a first-category selection. A display-only strategy-profile label makes the profile axes readable. Zero intervention paths now render as `0`.

No business logic, source fact, R19 control, accepted P01-P04 page definition, repository authority, or publication state changes.
