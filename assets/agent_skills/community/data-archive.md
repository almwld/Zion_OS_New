---
name: data-archive
description: Archive research or operational data for reproducibility and compliance with checksums and metadata
version: 0.1.0
execution-mode: advisory
argument-hint: "<dataset> [--destination s3|glacier|local] [--retention years]"
category: governance-compliance
status: candidate
---
# data-archive | Data Archival for Reproducibility

## When to Use
- Preserving research artifacts for reproducibility requirements
- Moving cold data to long-term storage for cost optimization
- Satisfying regulatory retention obligations (HIPAA, FINRA, SEC)
- Snapshotting a dataset before a destructive migration or deletion

## Execution

### 1. Parse Arguments
- `$ARGUMENTS`: `<dataset>` path, table, or directory to archive
- `--destination s3|glacier|local`: archive target (default local)
- `--retention years`: retention period in years (default 7)

### 2. Inventory Dataset
- Enumerate files, tables, or records to archive
- Record total size, file count, and modification timestamps
- Capture source location and connection metadata

### 3. Generate Manifest
- Compute checksum per file (SHA-256) and an aggregate checksum
- Record relative paths, sizes, and checksums in a manifest
- Include dataset metadata: schema, row count, profile snapshot

### 4. Package Archive
- Bundle dataset + manifest into a single archive (tar.gz or zip)
- Name with timestamp: `<dataset>_<YYYYMMDD>.tar.gz`
- Apply compression appropriate to destination (glacier: higher)

### 5. Transfer to Destination
- Upload to configured destination; verify transfer integrity
- Record archive location, ARN/URI, and storage class
- Set retention policy and lifecycle rules on the destination

### 6. Emit Archive Record
- Write archive metadata to `_state/archives/<dataset>.json`
- Include checksum, location, retention expiry, and manifest path

## Output Format

```
data-archive | <dataset> (dest=glacier, retention=7y)

## Inventory
- Files: 142 | Total size: 3.2 GB | Tables: 3
- Source: warehouse.facts.* | Modified: 2024-11-01

## Manifest
- Algorithm: SHA-256 | Files checksummed: 142
- Aggregate checksum: 9f2a...c41b
- Manifest file: _state/archives/dataset.manifest.json

## Archive
- Package: facts_20241108.tar.gz (3.1 GB compressed)
- Destination: glacier | ARN: arn:aws:glacier:...:vault/facts
- Retention: 7 years (expires 2031-11-08)

## Verification
- Transfer integrity: verified PASS
- Checksum match: PASS
- Lifecycle rule: GlacierExpeditedRetrieval after 90 days

## Verdict
PASS | 3.2 GB archived to glacier, retention 7y, checksum verified
```

## Skill Chains
- After archiving -> `[backup-verify]` to validate restore capability
- After archiving -> `[reproducibility-check]` to confirm reproducibility
- Before archiving -> `[data-govern]` to confirm retention requirements
