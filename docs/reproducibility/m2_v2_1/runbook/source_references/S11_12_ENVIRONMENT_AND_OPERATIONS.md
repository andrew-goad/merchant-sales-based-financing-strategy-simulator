# Operator Environment and Execution Discipline

## Desktop environment

```text
OS / shell      Windows 10/11 desktop; PowerShell 7 preferred
PowerShell      7.6.5 observed
PostgreSQL      17.9 local service
psql            C:\Program Files\PostgreSQL\17\bin\psql.exe
Python          3.14.7
Host/port       localhost:5432
Database user   postgres
```

## Operating rules

- The PostgreSQL password is entered interactively and not stored.
- Source checks run read-only.
- Every failed run is fail-closed and retained for diagnosis unless a controlled cleanup is explicitly authorized.
- Do not rerun the same package after PASS or FAIL.
- Before cloning, check actual PostgreSQL data-directory free space.
- Prefer checkpoint resume only when the retained state is exactly proven and simpler than a fresh compiler.
- Avoid `return` in Python `finally` blocks.
- Use ASCII-only or UTF-8-BOM PowerShell launchers and prefer `pwsh.exe`.
- Compile every custom query and export before a final clone is created.
- Report source mutation, clone existence, and retained database names truthfully from PostgreSQL—not from intended control flow.
