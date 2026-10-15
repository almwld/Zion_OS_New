---
name: memory-dedup
description: Compact MEMORY.md back under the auto-load limit by truncating long index lines, splitting compound entries, and archiving DATED entries. Index compaction only — semantic merging is /memory-evolve's lane.
version: 1.0.0
execution-mode: remedial
argument-hint: "[--apply | --truncate-only | --target-kb N]"
category: cognitive
status: tested
providers:
  required: [bash, python]
---
# Memory Dedup Command

Compact `MEMORY.md` (the auto-memory index) when its byte count exceeds the auto-load limit. Truncates over-long index lines, splits compound entries jammed onto one line by the auto-memory writer, and archives entries explicitly marked DATED.

**Scope split**: this skill is byte-budget compaction only. For semantic pruning, merging, and health scoring of topic file *contents*, use `[memory-evolve]`.

## When to Use
- System warning shows MEMORY.md exceeds auto-load limit (typically 24.4 KB)
- "Only part of it was loaded" notice appears at session start
- Periodic hygiene (monthly)

## Execution

### 1. Pre-flight inventory
- Read MEMORY.md, record byte count and SHA256
- Count link-format entries (`- [name](file.md) - desc`)
- Identify compound lines (single line containing 2+ topic-file references)
- Identify lines with description >200 chars (truncation candidates)
- Identify entries with "DATED ARCHIVE" or "DATED" tag in description (archive candidates)

### 2. Optimistic concurrency control (CRITICAL)
The auto-memory system writes to MEMORY.md during active sessions (`userMemoryEnabled: true`). To prevent silent data loss from race conditions:
1. Read file → record SHA256 (call it `pre_hash`)
2. Compute proposed changes
3. Re-read file → compute `post_hash`
4. If `pre_hash != post_hash`: ABORT with "MEMORY.md was modified during analysis. Rerun when no other sessions are active."
5. Only then write

### 3. Four compaction levers (no semantic merging)

**Truncate** (line >200 chars → ≤200 chars):
- Target the trailing detail clauses, not the topic essence
- Never go below 80 chars
- Preserve link syntax and date markers

**Split compound lines**:
- A single index line containing 2+ `[file](file.md)` references is split into separate lines
- Each retains its own description (not merged)

**Archive DATED entries**:
- Tag detection: line description contains "DATED ARCHIVE" or "DATED" prefix
- Archive = move topic file to `memory/_archive/<file>.md`, remove its index line
- Topic file is NEVER deleted — only moved

**Strip consecutive blank lines** (line-cap lever, added 2026-05-15):
- Auto-memory writer occasionally inserts 2+ consecutive blank lines between index entries
- Detection: `awk 'NR>1 && prev=="" && $0=="" {print NR}'` flags adjacent empty lines
- Collapse to single blank line; preserves visual grouping but stops invisible bloat
- Origin: AAR_2026-05-15 PR #765 fix-up — auto-load truncation at line 200 surfaced when blank-line accumulation pushed material index content past the cutoff. Single-blank-line invariant restores ~5-15 lines of usable budget without semantic change.
- Apply BEFORE truncate/split/archive — cheapest lever, often eliminates need for the others

### 4. Backup before any write
- Backup location: same directory as MEMORY.md, named `MEMORY.md.bak-<ISO-timestamp>`
- Operator can manually clean up `.bak-*` files older than 7 days

### 5. Apply (only with --apply)
- Re-confirm pre/post hash match (concurrency guard)
- Write new MEMORY.md
- Move archive candidates to `_archive/`
- Verify: file size ≤ target; all `[name](file.md)` links resolve to existing file or `_archive/file.md`

## Output Format
```
Memory Dedup | dry-run | MEMORY.md = 32.9 KB / target 24.4 KB
═══════════════════════════════════════════════════════════════
## Compound lines to split: 3
## Truncation candidates (>200 chars): 23
## Archive candidates (DATED-tagged): 6
═══════════════════════════════════════════════════════════════
Estimated post-dedup size: 22.1 KB
Concurrency status: pre_hash recorded; will verify before write
To apply: [memory-dedup] --apply
```

## Acceptance Criteria
- Post-apply size ≤ target-kb (default 24.4 KB)
- Pre-hash and post-hash compared before write; abort on mismatch
- All remaining `(file.md)` links resolve to existing files
- No topic file deleted (only moved to `_archive/`)
- `MEMORY.md.bak-<ISO>` exists in memory dir before any write
- Operator-reviewable diff before any write

## Skill Chains
| After completing... | Consider... |
|--------------------|-----------------------|
| MEMORY.md auto-load warning | `[memory-dedup]` to compact |
| `[memory-dedup] --apply` | restart session to verify full memory loads |
| Topic-file content review | `[memory-evolve]` (semantic, not byte-budget) |
