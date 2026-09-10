# R26 Policy and Authority Boundary

R26 is a newly versioned successor correction. It does not rewrite R17 or R19 and does not activate publication authority.

## Owner-approved policy

Daily evidence begins at the existing first expected remittance date. The payoff-pace benchmark uses selected total repayment divided by selected horizon. Pace WATCH becomes eligible on day 21 and requires three consecutive eligible-day breaches; pace-only WATCH therefore first qualifies on day 23. Pace UNDERPERFORMING and SEVERE become eligible on day 30 and require three consecutive eligible-day breaches; pace-only adverse status therefore first qualifies on day 32.

The accepted hard-trigger timing is preserved rather than accelerated: liquidity can drive WATCH from day 7; no-remittance, zero-sales and horizon adverse classification remains behind the existing day-14 status boundary. Raw day-level conditions remain available as evidence. R26 separately materializes five operational alert families: PACE, NO_REMITTANCE, SALES_DORMANCY, LIQUIDITY and HORIZON.

## Compatibility carrier

The accepted M2.5 schema hard-codes the legacy V1 contract identity. R26 therefore preserves that physical contract as a compatibility carrier while adding `msbf_m12r1e.r26_m2_5_policy_overlay` as the explicit V2 successor policy record. The Wave A successor registry binds the effective policy payload, including the R26 overlay, into the successor policy-method hash. The R26 operational-family rows additionally bind the source daily-row hash to the R26 policy SHA-256.

This avoids overwriting predecessor authority while still producing a cryptographically distinct successor.

## Authority after a physical PASS

A physical R26 PASS is **candidate authority only** pending focused Independent Audit. It does not supersede the accepted predecessor, authorize GitHub publication, authorize Campaign Scale runtime, or authorize Module 3 database/runtime execution.
