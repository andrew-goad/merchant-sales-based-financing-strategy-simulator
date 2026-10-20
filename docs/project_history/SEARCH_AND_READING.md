# Read and search the history

[History home](README.md) · [Conversations](CONVERSATIONS.md) · [HITL guide](HITL_guide.md)

## On GitHub

Start with the leadership guide or development chronology. Conversation indexes link to manageable parts and stable native-message anchors. Each occurrence names the speaker, Eastern timestamp and active/alternate path. A preceding-parent link follows the actual visible lineage.

Shared ancestors link to one canonical body. This saves repeated reading while preserving every branch occurrence in the index and JSONL. Identical wording from a later, different message identity remains a separate event. A relayed response inside a human message remains part of that human return event; it is not counted as the original assistant event.

## Offline reader

Download the repository or retain the complete `docs/project_history` folder, then open `reader/index.html` in a browser. No server, account, network access or external JavaScript library is needed. GitHub displays HTML source; it does not automatically host this reader.

Search matches phrases case-insensitively across canonical native-message text. The conversation filter also recognizes inherited occurrences. Results link to the canonical full message; branch occurrence locations remain in the conversation indexes. Up to 60 results appear at once; refine the phrase for a smaller set. Search does not include the unchanged legacy archives or unavailable attachment bytes.

For exact machine-readable inspection, use `indexes/messages.csv`, `indexes/conversations.csv`, `indexes/legacy_reconciliation.csv`, and `records/*.jsonl`. All selected occurrences carry full public text in JSONL. The reader escapes raw source HTML, does not load historical images, and renders code/tables without executing historical commands.

## What a link means

- A message link resolves to retained transcript evidence.
- An external artifact link is a separate source, not an embedded attachment.
- “Historical reference” preserves a referenced destination in inert text. Old session links are not functioning downloads.
- An attachment filename establishes a reference only. This transcript package does not recover the thousands of referenced attachment bytes.
- Editorial privacy omissions and mixed-purpose excerpt boundaries remain visible. Source and public-text hashes distinguish transformation from original text.
