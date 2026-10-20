# Coverage and provenance

[History home](README.md) · [Full directory](CONVERSATIONS.md) · [Legacy reconciliation](LEGACY_RECONCILIATION.md)

## Defined source boundary

The two supplied native JSON segments contain **166 entries / 166 unique conversation identities**. All 166 parsed objects equal the objects embedded in the supplied HTML export; the HTML was parsed as data without executing scripts. The complete corpus contains 28,326 user/assistant text or multimodal-text occurrences. Internal reasoning, recap records, system/developer metadata and tool traces are not public dialogue.

The raw account-wide export, its HTML representation and unrestricted asset-name lookup remain private. The public layer contains 24 project conversations and excerpts from 12 mixed-purpose conversations. Exclusion accounting: 117 unrelated, 12 reference-only, and one unresolved generic image-dependent context. That unresolved conversation's relationship to MSBF cannot be established from its retained visible text alone.

| Measure | Count / interpretation |
|---|---|
| Retained native occurrences | 8,034 |
| Unique native message identities | 5,272 |
| Unique identity/role/source-text/public-text combinations | 5,272 |
| Unique original text bodies | 5,104; not a unique-event count |
| Alternate-path occurrences | 59 |
| Attachment metadata references | 6,255; inherited references can repeat |
| Occurrences with non-text parts | 720; original image bytes are not included |
| Historical August records | 1,344 retained, byte-identical |
| Historical September records/page fragments | 3,453 retained, byte-identical |

Project conversations contain explicit omissions of unrelated recruitment correspondence and private contact/background details. Mixed-purpose passages include the original project launch, reporting visual refinements, substantial report-production spans and later project-specific discussion. They are not complete reproductions of the unrelated conversations. Literal excerpt offsets and detailed account-wide classification remain private.

## Structure and identity

Parent pointers reconstruct the graph; `current_node` identifies the selected path. A deterministic parent-before-child traversal orders retained events, with timestamps used only to order siblings. Alternate paths remain labeled and retain visible-parent references. Source IDs and original/public text hashes remain in the message index. No included native identity has conflicting original role/text variants in this recovered source set.

Shared native identities with equal role and text are canonicalized. All occurrences remain in their original conversation paths and JSONL. Different identities with identical words are not erased. Quoted or relayed material remains a separate relay event and does not transfer authorship.

## Fidelity and safety

Native dialogue preserves original wording except visible privacy redaction, labeled excerpt selection, inert historical-link/citation treatment and session-path removal. It is not rewritten to improve the owner's historical performance. Source and public hashes document the distinction. Formatting added for reading is editorial. Historical code, commands, acceptance and publishing instructions are inert evidence.

Original report screenshots are not reconstructed. The supplied 35-page HITL PDF is byte-identical to the published PDF checked during this preparation (SHA-256 `fd58b1e66e1643d67c8162810c8dc44a14a9f46bb4e1a1e59fa439ec7836263f`). Its existing source guide supplies image-production references; native dialogue now resolves several previously incomplete locators. Numerical claims are traced documentarily, not newly reproduced through simulator execution.

## Cutoffs and completeness

The full project workstreams reach October 16; selected later portfolio-use excerpts reach October 17, 2026. Exact first/last visible-message times are in the conversation directory. An update timestamp, export filename or upload date does not establish a message cutoff. This candidate does not include the October 20 failed-attempt conversation beyond the separate supplied work instruction.

“Retained record” means the reconciled union of this native layer and the unchanged August/September/preaudit evidence. Unmatched historical records remain available. Candidate fuzzy alignments are not treated as exact matches or proof of missing native messages. No claim of universally complete attachment recovery or zero missing messages is made.

Prepared against repository commit `ebffbf94789c14e64d22fe93551c206f29f0d64d`. Simulator source, accepted artifacts, report PDFs, Tableau, Power BI, releases and tags are outside this documentation change.
