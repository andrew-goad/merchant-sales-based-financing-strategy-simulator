# M1.16 Acquisition-Source Taxonomy

M1.16 preserves the accepted M1.2 parent channels and records a more granular normalized source family beneath each one.

| Accepted parent | M1.16 normalized families |
|---|---|
| CH_PROCESSOR_DIRECT | PROCESSOR_EMBEDDED |
| CH_BANK_RELATIONSHIP | RELATIONSHIP |
| CH_DIGITAL_DIRECT | PAID, OWNED, ORGANIC |
| CH_STRATEGIC_PARTNER | STRATEGIC_PARTNER |
| CH_BROKER_NETWORK | BROKER_OR_LEAD |

The profile table stores both `accepted_partner_channel_id` and `normalized_source_family`. A database check enforces alignment between normalized family and governed classification; parent-channel mapping is validated separately.

See `catalogs/M1_16_SOURCE_PROFILE_DICTIONARY.csv`.
