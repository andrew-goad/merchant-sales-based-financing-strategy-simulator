# Legacy-to-native reconciliation

[History home](README.md) · [Coverage](COVERAGE_AND_PROVENANCE.md) · [Record-by-record crosswalk](indexes/legacy_reconciliation.csv)

The supplied project-history ZIP matches the current remote history folder byte-for-byte. The new reader is additive: the older archives and their destinations remain intact.

| Earlier archive | Exact original/published-text hash | Normalized text equality | Candidate alignment only | Unresolved native mapping |
|---|---:|---:|---:|---:|
| [chatgpt_logs_through_2026-08-12](chatgpt_logs_through_2026-08-12/README.md) | 965 | 115 | 124 | 140 |
| [chatgpt_logs_through_2026-09-09](chatgpt_logs_through_2026-09-09/README.md) | 2243 | 263 | 270 | 677 |

Exact matches compare supplied text hashes and actual retained text. Normalized equality removes export citation markers, formatting punctuation and whitespace before comparison; it is separately labeled and is not byte equality. Sparse five-word shingles nominate possible OCR/page-fragment alignments; these are **candidate mappings only**, not accepted equivalence. The CSV retains source class, historical identity/file/line and native destinations so a reviewer can inspect both sides.

The September archive contains 3,040 structured-export records, 329 OCR-assisted page transcriptions, 45 retained visible continuations, 27 image-PDF continuations, 10 text-extracted records, one active-chat-context record and one boundary summary. These classes are not collapsed into native-message counts. One historical record can combine or fragment multiple messages.

## Material additions

- Campaign Scale Part 2 is now represented as its own native conversation, with September performance investigation and later lessons; it is absent as a separate conversation from the September archive, whose cutoff predates that continuation.
- Remediation Part 5 now includes later campaign support, HITL report review, Tableau development and October 16 publication discussion.
- Mixed-purpose production conversations retain the substantial September 24–25 report-development sequence, including human-carried feedback and final title revisions.
- Native branch paths preserve alternatives and shared ancestors explicitly. September titles and local `conv_` record codes are not assumed to equal platform identities.
- The report's Power BI return / remediation uptake is recoverable as two distinct native messages. R23's response timestamp is also recoverable; the approved report is not edited.

## What remains supplemental

Unresolved mappings can reflect OCR, sanitation, missing attachment text, summary/relay events, differing export cutoffs or a genuinely absent source. They are not automatically called omissions or duplicates. All earlier records remain retained; no old fragment is discarded because the new export does not match it. `preaudit/` remains historical evidence and is not silently promoted to accepted authority.
