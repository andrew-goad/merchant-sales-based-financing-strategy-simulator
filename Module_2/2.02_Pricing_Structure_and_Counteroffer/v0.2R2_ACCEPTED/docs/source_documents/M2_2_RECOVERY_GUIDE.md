# M2.2 Recovery Guide

- Stop at the first error; never use Retry, Skip, or Skip All.
- Execute `ROLLBACK;` after a failed transactional program.
- Use Program 140A only after failed/cancelled Program 142 generation.
- Use Program 142A only when Program 142 committed but its result tab was lost.
- Do not regenerate committed business outputs to repair validation or report-only defects.
