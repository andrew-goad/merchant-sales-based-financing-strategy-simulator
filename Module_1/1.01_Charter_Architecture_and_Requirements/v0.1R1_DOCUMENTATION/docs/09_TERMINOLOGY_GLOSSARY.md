# Terminology Glossary
## Merchant Sales-Based Financing Strategy Simulator v0.1R2

The glossary uses legal-neutral terminology unless a configured product structure requires otherwise.

| Term | Working definition | Important boundary |
|---|---|---|
| **Merchant** | The small business receiving financing and generating POS sales | Not the retailer in a consumer BNPL borrower relationship |
| **Processor-linked financing** | Financing underwritten and/or repaid using payment-processor data and settlement flows | Does not establish legal form |
| **Sales-based financing** | Umbrella term for financing whose repayment or delivery is linked to future sales or receivables | May include loans, receivables purchases, or hybrids |
| **Merchant cash advance (MCA)** | A commonly used market term often associated with purchase of future receivables and sales-linked delivery | Use only when the legal/product structure is explicitly selected |
| **Sales-based business loan** | A business loan with payment tied partly or fully to sales | Contractual and regulatory treatment differs from a receivables purchase |
| **Facility** | The governed relationship-level amount available for current or future advances | Separate from an individual advance |
| **Advance** | A specific funded transaction under a facility | May be a loan advance or receivables-purchase transaction depending on configuration |
| **Funded amount** | Cash provided to the merchant at origination | Not necessarily the total repayment amount |
| **Fixed finance fee** | Fixed dollar cost added to the funded amount | Not automatically interest or APR |
| **Total repayment amount** | Funded amount plus fixed fee, or the total purchased/delivered amount under the selected structure | Legal label may vary |
| **Payback multiple** | Total repayment amount divided by funded amount | Neutral analytical label; do not automatically call it a factor rate |
| **Factor rate** | Market term sometimes used for MCA pricing | Use only when appropriate to the selected structure |
| **Remittance percentage** | Percentage of eligible sales applied to repayment or receivables delivery | Sometimes called holdback; treatment is product-specific |
| **Eligible daily POS sales** | Sales included in the remittance base after governed exclusions and adjustments | Must preserve gross, net, settlement, and eligible values separately |
| **Expected daily remittance** | Eligible daily sales multiplied by contractual remittance percentage | Varies with realized sales |
| **Actual daily remittance** | Amount actually received or withheld for the financing on a date | May differ because of sales, operations, diversion, or data issues |
| **Expected payoff horizon** | Estimated number of days needed to complete repayment based on expected sales and remittance | Not the same as contractual maturity |
| **Contractual maturity** | Legally defined final due date where applicable | May not exist or may differ by structure |
| **Projected payoff date** | Current estimate of completion using realized performance and forecast sales | Dynamic monitoring output |
| **Minimum-progress requirement** | Required cumulative repayment by a defined checkpoint | Separate from daily percentage-of-sales compliance |
| **Reconciliation** | Governed process to compare actual sales, processor routing, remittance, and contractual obligations | May revise expectations or trigger review depending on product |
| **Remittance fulfillment ratio** | Actual cumulative remittance divided by expected cumulative remittance based on actual eligible sales | Measures sales-linked compliance, not expected-horizon progress alone |
| **Repayment progress index** | Actual repaid percentage divided by expected repaid percentage at current account age | Normalizes performance across expected horizons |
| **Payoff slippage** | Difference between current projected payoff and original expected payoff | May reflect lower sales without contractual breach |
| **Remittance interruption** | Consecutive expected collection events without actual remittance | Requires diagnosis of sales, processor, data, and contract context |
| **Processor continuity** | Whether expected POS processing and settlement remain visible through the approved channel | Operational or fraud dimension, not credit quality alone |
| **Receivables diversion** | Sales routed away from the agreed processor or account in violation of governed terms | Requires evidence and legal/product-specific interpretation |
| **Credit risk proxy** | Synthetic relative measure of default risk | Not a calibrated production PD |
| **Fraud risk tier** | Separate synthetic indicator of identity, application, transaction, or diversion risk | Should not be collapsed automatically into credit risk |
| **Data confidence tier** | Assessment of source completeness, freshness, reconciliation, and reliability | Controls reliance and decision path |
| **Operational continuity** | Status of source connections, processor routing, settlement, and system availability | Distinct from merchant economic deterioration |
| **EAD** | Expected exposure at default along the rapidly declining repayment path | Should not default to original funded amount for all timing assumptions |
| **LGD** | Expected loss severity after collateral, guarantees, costs, control, and recovery timing | Comparative synthetic estimate unless empirically calibrated |
| **Expected Loss** | Credit risk × LGD × EAD | Comparative simulation measure, not production reserve or forecast |
| **Expected contribution** | Expected revenue less funding, acquisition, servicing, Expected Loss, and risk/capital charge | Illustrative until real costs and behavior are available |
| **Acceptance elasticity** | Change in merchant acceptance associated with price or offer changes | Synthetic in initial version |
| **Competitive elasticity** | Change in acceptance or retention associated with competitor offer differences | Requires competitor assumptions or observed data |
| **Adverse selection** | Shift toward weaker booked merchants as stronger merchants reject less attractive pricing | Must be considered in pricing strategy |
| **Low-and-grow** | Controlled small initial exposure followed by governed step-ups based on performance | Not indiscriminate credit expansion |
| **Collateral** | Assets, receivables, cash, or other support available for recovery | Requires eligibility, valuation, control, and enforceability evidence |
| **Personal guarantee** | Contractual guarantee from an owner or other guarantor | Not identical to collateral and requires separate recovery assumptions |
| **Covenant** | Governed condition monitored after origination | Must have a test, threshold, cure, action, and owner |
| **Covenant early warning** | Condition approaching breach | May trigger monitoring or mitigation before breach |
| **Covenant breach** | Failure of a governed covenant test | Consequence depends on contract and policy |
| **Cure** | Resolution of a breach or performance problem within permitted terms | Distinct from recovery after default |
| **Merchant health** | Composite view of cash flow, liquidity, remittance, covenants, collateral, industry, relationship, and operational status | Should remain explainable by component |
| **Line increase** | Increase in facility availability | Requires performance, capacity, concentration, and relationship evidence |
| **Line reduction** | Temporary or permanent decrease in facility availability | Should avoid mechanical procyclicality and consider customer impact |
| **Workout** | Managed treatment of a distressed exposure | May include relief, restructure, collateral, settlement, or exit |
| **Loss mitigation** | Actions intended to reduce ultimate loss while considering cure, recovery, cost, time, and relationship value | Broader than collections status |
| **Default** | Governed contractual or policy event indicating severe failure | Definition depends on selected legal structure |
| **Charge-off** | Accounting or management recognition that all or part of exposure is unlikely to be collected | Separate from default and outside legal conclusions |
| **Industry dependency** | Degree to which one industry's revenue or costs depend on another | Synthetic weights require explicit channels, damping, lags, and caps |
| **Strategy robustness** | Ability of a strategy to preserve acceptable outcomes across multiple scenarios | Not the same as highest base-case profit |
| **Risk appetite** | Governed limits, early warnings, actions, owners, and review cadence | Must exist at account, segment, and portfolio levels |
| **Matched comparison** | Comparison of the same merchant/account population under different controlled scenarios or strategies | Requires stable identity and deterministic generation |
| **Latest-run output** | Replaceable current output for one selected run | Not a historical archive |
| **Archive** | Persistent, uniquely keyed history used for comparison and evidence | Timestamps are audit fields, not match keys |
| **Product legal-structure profile** | Effective-dated configuration describing the working legal form and approved interpretation status | Does not itself constitute a legal opinion |
| **Operating-model profile** | Configuration of provider, bank partner, processor, broker, servicer, and funding roles | Drives responsibility and applicability; not inferred from product label |
| **Jurisdiction profile** | Effective-dated record of the merchant/provider jurisdiction context and approved rule set | Must be approved and periodically recertified |
| **Regulatory requirement registry** | Versioned inventory of obligations, applicability dimensions, official sources, owners, dates, and implementation mappings | Draft research cannot generate compliance-ready status |
| **Regulatory applicability snapshot** | Frozen record of offer context and the approved requirements determined applicable at that time | Supports reproducibility and audit; not a legal opinion |
| **Compliance disposition** | `CLEAR`, `CONDITIONED`, `REVIEW`, or `BLOCK` result separate from credit outcome | Credit approval cannot override a block |
| **Offer compliance package** | Versioned set of disclosures, calculations, documents, license/registration checks, reporting flags, retention, and data controls associated with an offer | Exact package must be archived with the offer |
| **Disclosure calculation profile** | Approved method and version for calculating required cost, payment, or annualized metrics | Product- and jurisdiction-specific |
| **License/registration profile** | Approved record of entity permissions required for a product, role, and jurisdiction | Status and expiration must be validated before use |
| **Section 1071 profile** | Effective-dated configuration for covered institutions, covered and excluded transactions, compliance dates, data, firewall/separation, reporting, and retention | Must follow the then-current approved CFPB rule. As of 2026-07-23, a qualifying MCA is expressly excluded under the rule effective June 30, 2026; other sales-based products require separate classification |
| **Firewall/data separation** | Controls restricting access to specified demographic information by employees involved in credit determinations where required | Requires role, storage, access, and audit design |
| **Financial-crime role matrix** | Assignment of KYB, identification, beneficial-owner, sanctions, AML, monitoring, and reporting responsibilities across parties | Depends on actual bank/nonbank operating model |
| **Payment-data scope profile** | Record of whether an environment stores, processes, transmits, or can impact payment account data | Used to assess security obligations; simulator defaults to no real cardholder data |
| **Official-source register** | Dated catalog of primary agency/statutory/regulatory sources supporting design assumptions | Must distinguish current, superseded, proposed, and archived sources |
| **Regulatory staleness** | Condition in which a requirement/profile has passed its review date or its source has changed | Fails closed until recertified |
| **Legal-review status** | Controlled lifecycle state for a product interpretation or requirement | Typical states: draft, under review, approved, superseded, retired |
| **Unsupported contract feature** | Feature intentionally excluded because it is outside scope, legally sensitive, or unsuitable for recommendation | Includes confessions of judgment in this simulator |

