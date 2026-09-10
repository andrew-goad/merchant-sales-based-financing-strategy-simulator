# Independent Windows qualification

Select the route first. Mark every row PASS / FAIL / NOT APPLICABLE with a reason; never mark an unexecuted check PASS. Use the operator record template.

| Check | Evidence required |
|---|---|
| Document/version | Exact runbook ZIP and trusted SHA-256 comparison |
| Independent operator | Name, experience, no access to author-only unlisted dependencies |
| Environment | Windows build, Python, PowerShell, PostgreSQL server/client versions; Desktop for viewer route |
| Workspace | Short new paths, writable evidence location, unmodified input archives |
| Software/source | Tools resolve correctly; complete exact source files and artifact locks match |
| Database scope (B/D) | Approved isolated host, system identifier, source/target OIDs and names; capacity assessment |
| No hidden bootstrap | Required checkpoint/seed or full generation sources are supplied and verified |
| Execution | Exact commands, original logs, stage checkpoint evidence, native exit codes |
| Failure handling | Validate reject behavior on disposable fixture/copies; do not damage accepted databases |
| Result | Correct populations, grains, scenarios, monetary sums, canonical roots and full expected control population |
| Preservation | Accepted source/PBIX unchanged; failed attempts retained |
| Report viewing (C) | Accepted master hash; separate working copy; P01–P04 scope and source/as-of labels |
| Native extraction | Actual Windows-native extraction evidence plus exact byte comparison |
| Reviewer conclusion | Scope, deviations, limitations and disposition explicitly recorded |

The injected-fault Python tests delivered here cover archive/source/evidence rejection without a database. They are not a substitute for wrong-target/transaction-boundary testing of a future database executor. Keep those two test populations separate.
