# Software and source references

Verified against official documentation during preparation, September 5, 2026 UTC (September 4 operator-local workstream date). Product documentation describes product behavior; it is not MSBF runtime certification.

| ID | Official source | Use in this procedure |
|---|---|---|
| O1 | [PostgreSQL 17 psql](https://www.postgresql.org/docs/17/app-psql.html) | Explicit connection arguments, -X, ON_ERROR_STOP, native exit codes and self-managed-transaction warning. |
| O2 | [Microsoft: Install PowerShell 7 on Windows](https://learn.microsoft.com/en-us/powershell/scripting/install/install-powershell-on-windows) | Supported install paths and use of pwsh; record installed version rather than assuming it. |
| O3 | [PostgreSQL Windows installers](https://www.postgresql.org/download/windows/) | Obtain the approved server/client tool distribution. |
| O4 | [Microsoft: Download Power BI Desktop](https://learn.microsoft.com/en-us/power-bi/fundamentals/desktop-get-the-desktop) | Desktop installation and supported release guidance. Keep the accepted master unchanged under any installed version. |
| O5 | [Python: Using Python on Windows](https://docs.python.org/3/using/windows.html) | Interpreter installation/PATH; confirm the actual python executable. |
| O6 | [DBeaver: SQL execution](https://dbeaver.com/docs/dbeaver/SQL-Execution/) | Optional complete-script execution; stage session/transaction behavior remains source-owned. |
| O7 | [PostgreSQL 17 password file](https://www.postgresql.org/docs/17/libpq-pgpass.html) | Alternative administrator-controlled authentication. The frozen launcher uses an interactive secure prompt and process environment instead; do not silently rewrite it. |

## Exact software treatment

Historical project records identify PostgreSQL 17.9, Python 3.14.7 and PowerShell 7.6.5 for the successor operations environment. Earlier public instructions identify PostgreSQL 15 and DBeaver. These are different reference contexts, not interchangeable installation instructions. The new Python toolkit and source-owned offline calculation were tested here on Python 3.13.5/Linux. Windows and the database route were not exercised here.

Use organization-supported patched software. Do not downgrade to a recorded point version merely to match a number; qualify and document any version difference. Supported product versions and installer options may change. No preview release is recommended by this runbook. The source runtime carries all its local Python modules and uses standard-library imports; no universal claim is made about dependencies of unrelated MSBF tools.

## Public versus private dependencies

The small runbook does not embed the runtime, accepted result ZIP, PBIX, repository bundle or checkpoint database backups. They are separately hash-bound inputs. Availability/classification for a future public clean-start user is a required release-binding decision, not presumed solved by this document.
