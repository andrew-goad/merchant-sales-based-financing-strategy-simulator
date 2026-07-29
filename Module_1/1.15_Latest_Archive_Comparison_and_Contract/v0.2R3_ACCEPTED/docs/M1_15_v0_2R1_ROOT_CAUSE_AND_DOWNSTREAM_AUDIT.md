# M1.15 v0.2R1 Root-Cause and Downstream Audit

## Root cause

The failed statement joined `run_registry` and `application_unit_economics_snapshot`, both of which exposed `scenario_id`, and then attempted `JOIN scenario_registry USING (scenario_id)`. PostgreSQL correctly rejected the ambiguous common column.

## Consolidated audit findings

- Program 110 contained two scenario-registry `USING` joins; both are explicit in R1.
- Program 111 contained multiple `USING` joins and one chained join whose left relation already carried duplicate run/application keys; all are explicit in R1.
- Program 108 installed a recursively self-referential prerequisite function; R1 repairs it.
- Program 113 used star expansion from CTEs that both exposed `combined_hash`, creating a latent duplicate-column CTAS failure; R1 explicitly names every field.
- Programs 112, 114, and 115 retain their executable business logic, with version-aligned headers only.

## Preserved business contract

The 1,500 latest rows, 1,500 immutable archive rows, 750 matched comparisons, one contract registry row, 3,751 canonical entities, source payloads, lineage payloads, worsening identities, and all control thresholds are unchanged.
