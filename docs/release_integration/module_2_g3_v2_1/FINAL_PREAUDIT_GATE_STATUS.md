# Final pre-audit gate status

The integrated candidate is ready for the **combined Independent Audit integration/publication determination**. No live publication or supersession has occurred.

| Gate | State entering final IA | Boundary |
|---|---|---|
| R26 technical successor | CLOSED — `IA-D-R15-M12-001` PASS_WITH_OBSERVATIONS | Do not rerun absent concrete integration regression |
| R26 version-separated integration | AUTHORIZED — `IA-INT-R15-R26-001` | Final combined IA must accept this exact candidate |
| Power BI R3 | CLOSED — `IA-D-R17-PBI-001 = ACCEPT` | Exact support/PBIX/DataModel bytes frozen |
| PBI publication handoff | AUTHORIZED — `IA-PBI-PUB-HANDOFF-001` | Handoff only; no live upload yet |
| Cohort current edition | OWNER-APPROVED PATCH1 | Combined IA adjudicates integrated/publication placement; do not attribute to R17 |
| Visual publication family | OWNER APPROVED / FROZEN | Eight visual units; public/private boundary frozen |
| Physical Git baseline | VERIFIED | `main == origin/main == 46fb1f9...` before candidate assembly |
| Integrated staged candidate | FINAL PRE-AUDIT CANDIDATE | Version-separated; historical tags/accepted bytes preserved |
| PUB-RUN-001 Route B | WINDOWS QUALIFIED / READY FOR IA DISPOSITION | Portable checkpoint restore + isolated M2.11/M2.12/G3-v2 replay; 90/90 reconciliation |
| PUB-RUN-001 Route D | NOT QUALIFIED | No cold-start claim |
| Project history | PRE-AUDIT CONTINUATION PREPARED | Final IA interaction appended once after decision |
| Hosted release verification | POST-PUBLICATION | Exact hosted hashes/size/Windows extraction remain downstream closure |

The final Independent Audit is asked to determine whether the exact integrated candidate and bounded Route-B qualification support public v2.1-family supersession/publication, and to identify any mandatory pre-push condition separately from post-publication hosted verification.
