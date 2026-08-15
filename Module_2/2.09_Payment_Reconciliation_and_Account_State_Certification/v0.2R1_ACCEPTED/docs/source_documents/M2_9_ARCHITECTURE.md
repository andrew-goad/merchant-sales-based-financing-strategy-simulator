# M2.9 Architecture

```text
Accepted M2.8 contract + payment ledger + lifecycle transitions
         59 accounts       7 events       67 transitions
                          |
                          v
       Run-scoped target-typed source snapshots
                          |
             +------------+-------------+
             |                          |
             v                          v
   7 event reconciliations     Latest-state window selection
             |                          |
             +------------+-------------+
                          |
                          v
             59 account reconciliations
                          |
                  1 return exception
                  resolved by retry
                          |
                          v
             59 certified account states
                          |
                          v
       2 portfolio summaries + latest + immutable archive
                          |
                          v
        Power BI + exception ledger + comparison + canonical hash
```

Each accepted M2.8 relation is scanned exactly once. Reusable intermediates are target-typed, indexed, and `ANALYZE`d. Payment and transition evidence are aggregated once. `ROW_NUMBER` selects the latest lifecycle state without an account-level self-join.
