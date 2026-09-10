# Repository integration plan — full publication scope

## Baseline and construction

1. Reconstruct the current public repository from exact owner `HEAD=46fb1f9...` in a **staging directory outside the Git worktree**.
2. Apply the exact accepted pre-R26 R23 overlay as historical/integration predecessor material. Do not treat R23 rc2 authority as a shortcut around R26.
3. Add a new neutral `successor_candidates/m2-g3-v2.1-r26-integration/` layer rather than rewriting rc2 bytes. It carries the exact R26 runtime/source projection, technical locks, and links to the change-control evidence. The final stable tag remains a later owner/audit decision.
4. Add the accepted PBI R3 projection, current cohort editorial edition, approved visual tree, runbook, release integration records, and a pre-audit history status.
5. Synchronize root navigation/status surfaces by prepending a current-candidate section while retaining predecessor prose below for review.
6. Regenerate candidate root manifests/checksums from the staged tree. Do not mutate the user repository.

## Candidate path conventions

- `successor_candidates/m2-g3-v2.1-r26-integration/` — exact technical successor integration candidate.
- `docs/release_change_control/module_2_g3_v2_1/` — accepted change-control public projection.
- `docs/power_bi/m2_v2_1/` — accepted PBI R3 public projection.
- `docs/cohort/m2_v2_1/` — current cohort public edition and bounded editorial patch evidence.
- `docs/portfolio_visuals/` — approved visual publication tree.
- `docs/reproducibility/m2_v2_1/` — runbook R1 plus final-binding overlay/evidence.
- `docs/release_integration/module_2_g3_v2_1/` — current locks, authority, public/private boundary, candidate receipt.
- `docs/project_history/preaudit/` — pre-audit cutoff record only; final public history is rebuilt after final IA determination.

## Release assets kept outside the Git tree during audit

The exact R26 runtime ZIP, Power BI support ZIP, visual-publication ZIP and cohort patch ZIP are carried in this audit package as release assets. In particular the 125 MB visual ZIP exceeds GitHub's normal repository-file limit and is a release-asset candidate, not a file to commit into the repository tree.

## Prohibited during staging

No commit, branch change, tag, push, remote upload, database execution, PBIX refresh/save, history deletion or accepted-byte rewrite.
