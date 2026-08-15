# Sanitization and Publication Report

## Result

```text
Source conversations                         5
Source message records                       4,669
Published visible-message records            1,344
Excluded internal-reasoning records          3,325
Source export files                          20
Duplicate visible fingerprints               407
Duplicate visible occurrences                820
```

## Redactions applied

```text
Credential-like strings        0
Email addresses                15
Telephone numbers              11
Temporary session links        3400
Temporary Unix paths           3
Local Windows paths            60
```

## Publication controls

- internal thoughts and reasoning recaps are not published;
- raw source exports are not committed;
- source archive and constituent-file hashes are retained;
- Markdown and JSONL derive from one sanitized record set;
- message order and timestamps are preserved;
- duplicate cross-conversation history is retained and disclosed;
- the archive is explicitly subordinate to accepted source and evidence.

## Limitations

Automated redaction reduces common privacy and credential risks but is not a legal discovery or privacy certification. Reviewers should treat the public archive as curated project history rather than a forensic copy of the original platform export.
