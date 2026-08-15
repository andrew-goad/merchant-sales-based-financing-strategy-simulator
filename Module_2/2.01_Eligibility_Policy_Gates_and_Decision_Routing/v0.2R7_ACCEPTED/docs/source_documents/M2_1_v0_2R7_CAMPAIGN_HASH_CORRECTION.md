# M2.1 v0.2R7 Campaign Physical-Row-Hash Correction

The original campaign seed CTE named its run key `run_id`, while the physical
campaign table names the field `module1_run_id`. Hashing `to_jsonb(seed)`
therefore produced a seed-record identity rather than the physical-row
identity.

The v0.2R7 clean build constructs the campaign row hash from the exact
physical column names. All dependent set, registry, contract and combined
hashes are then generated from that physical identity.

No campaign attributes, gate rules, routes, reasons, counts, grains or
acceptance thresholds changed.
