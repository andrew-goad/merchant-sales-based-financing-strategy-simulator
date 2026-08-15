# M2.10 Architecture

```text
Accepted M2.9 certified accounts (59)
             |
             v
Run-scoped source snapshot (59)
             |
             v
Account performance fact (59)
  57 closed stable | 1 active reconciled | 1 controlled review
             |
      +------+------------------+
      |                         |
      v                         v
Portfolio/scenario scopes (3)  Servicing queues (3)
      |                         |
      v                         v
24 KPIs × 3 scopes = 72 facts  Burden = 7.000000 units
      +-------------+-----------+
                    v
Latest + immutable archive + Power BI + comparison + canonical hash
```

The accepted source is scanned once. Reusable intermediates are materialized,
indexed, and ANALYZED. Scope and queue summaries avoid account self-joins.
