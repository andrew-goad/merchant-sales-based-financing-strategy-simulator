# Module 0 · Establish the foundation before generating evidence

[Portfolio home](../../README.md) · [Documentation portal](../README.md) · [Current use](CURRENT_USE.md)

A controlled result needs a physical schema and an identified run. Those are different gates, and neither is itself a merchant portfolio.


## G0: the physical contract

[G0 · Physical data foundation](stages/G0.md) explains schemas, designed parent tables, partition children, reference/parameter seed and the empty analytical boundary. The original guide records 70 designed parent/non-child tables plus four table partitions. Counting every inherited catalog relation would incorrectly include index inheritance.

## G1: the selected run

[G1 · Governed run control](stages/G1.md) explains parameter/profile resolution, source contracts, snapshot identities and the transition to `G1_READY`. The seven source-contract rows precede business observations; they do not prove seven populated source feeds.

## Why the distinction matters

A reviewer comparing outputs must be able to distinguish a new evidence population from a changed policy or configuration. G0 establishes the containers and integrity rules. G1 binds the selected configuration and source identities. M1.2 then owns merchant population generation; the M1.1 charter is a design entry, not an intervening executable stage.

[Continue to Module 1](MODULE_1.md) · [Read environment and provenance boundaries](SOURCE_VERSIONS.md)

## Original requirements and evidence

The two companions retain direct links to the physical original README, schema/seed or control SQL, execution guide and evidence reports. [The requirements/validation hub](REQUIREMENTS_AND_VALIDATION.md) gives a whole-stage route without rewriting those records. The current documentation is not an instruction to bootstrap a new database or treat the historical 230-position catalog as an executable loop.


*Deterministic synthetic demonstration · Non-production · No real funds. This current-reading page does not alter source-of-record evidence.*
