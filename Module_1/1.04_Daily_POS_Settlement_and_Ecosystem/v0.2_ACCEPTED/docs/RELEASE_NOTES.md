# Release Notes — MSBF M1.4 v0.2

## Release purpose

This package implements the controlled source, validation, and evidence framework for **M1.4 — Enterprise Merchant Ecosystem: Daily POS & Settlement History**.

## New capabilities

- Deterministic 180-day baseline POS and settlement history for 750 accepted merchants.
- Exact 135,000-row merchant-day output at the governed merchant/processor/date grain.
- Industry-conditioned sales centers, volatility, zero-sales behavior, seasonality, weekends, average ticket, refunds, and chargebacks.
- Stable, growing, declining, seasonal, volatile, recent-disruption, and thin-history operating archetypes.
- Processor-active, degraded, outage, and pre-open states with corresponding connection diagnostics.
- Lagged processor-settlement reproduction and processor-fee economics.
- Three governed calendar effects and bounded merchant-level disruption, demand-shock, and expansion events.
- Canonical row hashes, full-history hash, expected/actual deterministic reproduction, and fail-closed generation controls.
- Fifty-two positive validations, four negative controls, one acceptance finalizer, one master report, and fourteen detailed evidence result sets.

## Stage boundary

This release creates only baseline `msbf_m1.merchant_pos_daily_base` history. It does not create scenarios, deposits, underwriting features, risk outputs, EAD, Expected Loss, or latest/archive contract outputs.

## Validation status

Static package validation: **PASS**.

Live PostgreSQL execution: **required before acceptance**.

## Authorized next step after acceptance

**M1.5 — Daily Deposit & Liquidity History Generation**.
