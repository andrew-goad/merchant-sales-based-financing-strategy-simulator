# Successor candidate data dictionary

| Object | Grain | Purpose |
|---|---|---|
| `R1DimApplicationScenario` | application × scenario | Canonical R4 decision population and stable joins |
| `R1FactFeatureAvailability` | application × scenario | Decision-critical feature availability and evidence |
| `R1FactDecisionGate` | application × scenario × gate | Exact capacity, economics, risk, resilience and authority gates |
| `R1FactOfferCandidate` | application × scenario × candidate | Candidate search, feasibility, economics and selection facts |
| `R1FactFinalDecision` | application × scenario | Governed final decision and selected structure |
| `R1FactNoFeasibleProof` | application × scenario | Exact no-feasible-structure proof population |
| `R1FactDailyMonitoring` | application × scenario × monitoring day | Daily remittance and exposure |
| `R1FactIntervention` | application × scenario | Governed servicing recommendation |
| `R1FactOperationalSetup` | application × scenario | Operational setup outcome |
| `R1FactServicingExecution` | application × scenario | Payment and lifecycle execution |
| `R1FactAccountCertification` | application × scenario | Reconciliation and terminal-state certification |
| `R1FactPortfolioPerformance` | application × scenario | Portfolio performance and servicing burden |
| `R1DimStrategyProfile` | strategy profile | Eight governed strategy profiles |
| `R1FactCandidateEvaluation` | application × scenario × candidate × profile | Candidate feasibility and objective facts |
| `R1FactApplicationStrategySimulation` | application × scenario × profile | Selected strategy outcomes |
| `R1FactAccountStrategySimulation` | account × scenario × profile | Analytic servicing posture |
| `R1FactPortfolioStrategyAnalysis` | scope × profile | Frontier and portfolio economics |
| `R1FactG3v2Certification` | control | Seventy G3-v2 controls |
| `R1DimReportingScope` | reporting scope | Baseline, stress and portfolio scopes |
| `R1AuthorityStatus` | one candidate authority row | Audit and publication boundary |
| `R1Measures` | measures only | Aggregations; no hidden strategy reconstruction |
