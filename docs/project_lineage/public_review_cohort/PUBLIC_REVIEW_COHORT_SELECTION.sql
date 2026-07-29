/*
Merchant Sales-Based Financing Strategy Simulator
Public Review Cohort V1 - deterministic selection and extraction helper

Boundary:
- Read-only publication helper.
- Does not write to accepted PostgreSQL tables.
- Public Review IDs exist only in the GitHub publication layer.
*/
WITH channel_ranked AS (
    SELECT
        a.merchant_application_id,
        a.merchant_id,
        p.partner_channel_id,
        row_number() OVER (
            PARTITION BY p.partner_channel_id
            ORDER BY md5(a.merchant_application_id || '|PUBLIC_REVIEW_COHORT_V1'),
                     a.merchant_application_id
        ) AS channel_rank
    FROM msbf_m1.merchant_application a
    JOIN msbf_m1.processor_account p
      ON p.merchant_id = a.merchant_id
    WHERE a.created_by_run_id = 1
), channel_core AS (
    SELECT * FROM channel_ranked WHERE channel_rank <= 8
), governed_anchor(application_id, anchor_order) AS (
    VALUES
      ('MSBF_POP_0001_M000001_A01',1),
      ('MSBF_POP_0001_M000002_A01',2),
      ('MSBF_POP_0001_M000003_A01',3),
      ('MSBF_POP_0001_M000004_A01',4),
      ('MSBF_POP_0001_M000005_A01',5),
      ('MSBF_POP_0001_M000006_A01',6),
      ('MSBF_POP_0001_M000007_A01',7),
      ('MSBF_POP_0001_M000009_A01',8),
      ('MSBF_POP_0001_M000010_A01',9),
      ('MSBF_POP_0001_M000012_A01',10)
)
SELECT * FROM channel_core ORDER BY partner_channel_id, channel_rank;

-- Use PUBLIC_REVIEW_COHORT_REGISTRY.csv as the immutable public ID mapping.
-- Join its canonical_application_id to accepted contract views for stage-specific exports.
