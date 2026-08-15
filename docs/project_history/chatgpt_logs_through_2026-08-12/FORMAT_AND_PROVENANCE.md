# Format and Provenance

## Supplied source package

```text
Archive      ChatGPT_Logs.zip
Bytes        5,974,369
SHA-256      7a17f1ccdb2b77f85deab6d1803cb4ae2853bc4246f3c9e8781ee02406b10f5d
Files        20
```

The package contained JSON, CSV, standard HTML, and alternate vertical-view HTML exports. The canonical structured JSON exports were used to create the public transcripts. CSV and HTML copies are retained in the source inventory as provenance identities but are not committed as redundant raw content.

## Published representations

| Representation | Purpose |
|---|---|
| `conversations/*.md` | Human-readable, GitHub-native transcripts |
| `machine_readable/*.jsonl` | One published message per line for programmatic analysis |
| `CONVERSATION_INDEX.*` | Conversation-level navigation and counts |
| `SOURCE_FILE_INVENTORY.*` | Source-export identity and treatment |
| `source_provenance/*` | Source ZIP and constituent SHA-256 authority |

## Derivation rules

1. Read each canonical JSON export using UTF-8 with BOM support.
2. Preserve conversation and visible-message order.
3. Exclude records identified as internal thoughts or reasoning recaps.
4. Apply deterministic privacy and path redaction.
5. Write Markdown and JSONL from the same sanitized message objects.
6. Reconcile published counts to the conversation index.
