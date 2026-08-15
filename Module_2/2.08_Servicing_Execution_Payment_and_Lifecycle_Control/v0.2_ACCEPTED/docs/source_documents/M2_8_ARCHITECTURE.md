# M2.8 Architecture

```text
Accepted M2.7 latest (59)
       |
       v
Source snapshot (59) -> exact 57 / 1 / 1 mapping
       |
       +-> account execution (59)
       +-> payment ledger (7; 5 settled / 1 return / 1 retry)
       +-> lifecycle transitions (67)
       v
Portfolio (2) -> latest/archive (59/59) -> canonical identity (367)
```

The source is scanned once. Target-typed staging is indexed and ANALYZED. Cumulative payment values use window functions.
