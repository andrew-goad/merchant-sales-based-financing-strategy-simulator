# Required Power BI Desktop evidence

Before audit submission, the owner must produce evidence that the candidate project:

1. opens from the exact PBIP source asset;
2. resolves `pSuccessorRoot` to `C:\MSBF\R20\power_bi\carrier`;
3. refreshes all predecessor and successor tables without error;
4. retains the expected 54 tables, 52 relationships, 164 measures, 52 expressions, and six report pages;
5. preserves the four accepted page-directory byte roots;
6. renders P05 and P06 without broken fields or hidden strategy reconstruction;
7. saves, closes, and reopens successfully;
8. produces the requested screenshots, model inventory, and post-save hashes.

Until those artifacts are returned, the Power BI gate is `PENDING_OWNER_DESKTOP_REPERFORMANCE`.
