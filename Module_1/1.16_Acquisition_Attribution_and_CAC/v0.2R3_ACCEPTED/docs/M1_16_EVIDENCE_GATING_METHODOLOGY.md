# M1.16 Evidence Gating

`COMPLETE`, `PARTIAL`, and `BLOCKED` are applied separately to attribution, cost, overlap, and the overall acquisition contract.

- Unknown cost is not zero cost.
- Organic and relationship sources are not assumed free.
- Supported zero requires `SUPPORTED_ZERO`.
- `NOT_APPLICABLE` is distinct from zero.
- Known components and accepted M1.14 legacy amounts remain visible when a total is blocked.
- Blocked fully loaded totals remain null and cannot be interpreted as favorable low cost.
