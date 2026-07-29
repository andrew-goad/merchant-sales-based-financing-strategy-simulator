# M1.12 Validation and Reporting History

## v0.2 live execution

Programs 84 through 90 completed successfully: schema/policy extension, preflight, generation, 80-of-80 positive validation, 7-of-7 negative controls, acceptance, and master reporting all passed.

## Detail-report defect

The original v0.2 program 91 returned result sets 1–19 and then failed in result set 20 because `profile_resolution_error` has no `error_id` column. Its primary key is `resolution_error_id`.

## v0.2R1 report correction

The corrected report explicitly projects the final blocking-error fields and orders by `resolution_error_id`. It performs no persistent DML and changes no M1.12 generation, validation, acceptance, business, or hash logic.

The corrected program produced all twenty result sets. Result set 19 and result set 20 retain headers and contain zero rows.
