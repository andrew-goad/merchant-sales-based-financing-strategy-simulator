# M2.7 Validation and Correction History

```text
180 v0.2    PASS
181 v0.2    PASS
182A v0.2   failed-generation rollback and recovery PASS
182 v0.2R1  PASS
183 v0.2    120 / 120 PASS
184 v0.2    20 / 20 PASS
185 v0.2    M2_7_ACCEPTED / ACCEPTED / PASS
186 v0.2    overall_m2_7_status = PASS
187 v0.2    24 result sets
```

## Program 182 correction

The original Program 182 staging table inherited
`contract_row_hash NOT NULL` through PostgreSQL `CREATE TABLE ... LIKE`.
Revision v0.2R1 temporarily relaxes that staging-only attribute, populates and
validates the deterministic hash, and restores NOT NULL before persistence.

```text
Accepted M2.6 source changed          false
Operational mapping changed          false
Temporary setup terms changed        false
Expected counts changed              false
Persistent accepted output changed   false
Stage boundary changed               false
```

The clean Program 182A evidence confirms that failed generation attempts
rolled back without partial M2.7 data. The final accepted generation used
Program 182 v0.2R1.

Final accepted revision: `v0.2R1`.
