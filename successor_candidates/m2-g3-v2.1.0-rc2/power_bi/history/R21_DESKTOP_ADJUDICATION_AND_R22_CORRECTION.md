# R21 Desktop adjudication and R22 correction

## R21 physical evidence that passed

- Power BI Desktop 2.157.879.0 64-bit refreshed and applied query changes.
- The semantic model remained 54 tables, 52 relationships, 164 measures, and 52 expressions.
- P01-P04 remained functional.
- P05 rendered without visual exceptions and showed 100.0% no-feasible-proof coverage.
- P06 rendered without an exception panel and showed multiple strategy profiles.
- The project survived save, close, and reopen.
- The immutable source PBIP remained unchanged.

## Finding requiring correction

The R21 owner attestation recorded `flag_dependent_cards_render_values = PASS`. The captured P06 page instead displays `--` for **Treatment-effect claims**. That is Power BI's blank marker, not numeric zero. The DAX measure was a filtered `COUNTROWS` without `COALESCE`; a zero-row filtered table therefore produced BLANK.

The Early Intervention test also displayed `--` for **Primary frontier profiles**, where zero is the correct governed count. In addition, the P06 comparison chart used `R1 Portfolio Servicing Burden`; under Reporting Scope = Portfolio this source summary contains zeros for every profile even though the account-level strategy simulation correctly records four incremental Early Intervention interventions and four burden units.

## R22 bounded correction

R22 makes four filtered count measures zero-safe:

- R1 Selected Candidate Count
- R1 Treatment Effect Claims
- R1 Frontier Eligible Profiles
- R1 Primary Governance Profiles

R22 changes the P06 comparison visual from `R1 Portfolio Servicing Burden` to `R1 Incremental Servicing Burden` and retitles it **Incremental servicing burden by profile**.

No strategy, carrier, lineage, authority, accepted P01-P04, or business-fact change is introduced.
