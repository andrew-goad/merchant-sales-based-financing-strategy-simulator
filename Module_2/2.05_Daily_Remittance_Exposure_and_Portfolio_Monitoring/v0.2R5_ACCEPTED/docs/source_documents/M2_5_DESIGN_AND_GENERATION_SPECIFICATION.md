# M2.5 Design and Generation Specification

M2.5 monitors only the 59 M2.4 records with synthetic portfolio activation. Each activated scenario/application receives 120 deterministic monitoring days, yielding 7,080 daily rows. The most recent 120 accepted M1.6 POS and deposit observations are replayed into the operational horizon. Window functions calculate cumulative remittance, expected pace, shortfall, trailing remittance, zero-sales streak and receivable exposure.

Raw statuses are assigned from governed pace, interruption, zero-sales, liquidity and horizon thresholds. For the 15 applications activated in both baseline and recession/energy scenarios, the stress status is floored so stress cannot be more favorable than baseline. Latest and immutable archive contracts are published at day 120, and 240 scenario/day portfolio summary rows support executive and Power BI consumption.
