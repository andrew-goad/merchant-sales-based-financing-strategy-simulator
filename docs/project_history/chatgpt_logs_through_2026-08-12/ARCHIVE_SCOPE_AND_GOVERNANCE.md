# Archive Scope and Governance

## Purpose

The archive supports transparent review of how the simulator was designed, challenged, corrected, executed, audited, and prepared for public release. It is not an executable source package and is not a substitute for formal evidence.

## Included

- visible user prompts and assistant responses from five supplied conversations;
- source timestamps, message order, and conversation metadata;
- readable Markdown transcripts;
- machine-readable JSONL transcripts;
- source-export identities and publication inventories;
- project chronology and decision/milestone navigation.

## Excluded from public publication

- model-internal reasoning or chain-of-thought records;
- machine-only reasoning recaps;
- credential-like strings;
- email addresses and telephone numbers;
- machine-specific local paths and temporary session links;
- redundant raw HTML, CSV, and JSON exports containing the same conversation content.

Exclusion of internal reasoning does not change the visible user/assistant record. It enforces a public documentation boundary and prevents hidden machine process from being misrepresented as governed project evidence.

## Authority hierarchy

```text
Accepted SQL and package identities
→ Formal validation, independent audit, and acceptance
→ Current BRDs, architecture, catalogs, and stage documentation
→ Campaign-readiness and publication documentation
→ Conversation history
```

The lower tier may explain a decision but cannot supersede a higher-tier authority.

## Synthetic and non-production boundary

The project is a deterministic synthetic simulator. The archive does not establish production deployment, empirical model calibration, causal optimization, autonomous decisioning, legal compliance, or lending authorization.
