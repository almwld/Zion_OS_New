---
name: orphan-scan
description: Detect orphan files in any directory that maintains an index — files exist on disk but no index entry references them. Generalizes the orphan-detection pattern from /memory-evolve to any directory + index pair.
version: 0.1.0
execution-mode: advisory
argument-hint: "[DIRECTORY] [INDEX_FILE]"
category: cognitive
status: candidate
---
# Orphan Scan

Identify orphans (file-on-disk-without-index-entry) and phantoms (index-entry-without-file) in any indexed directory. Read-only.

## When to Use

- Memory directories (`memory/` + `MEMORY.md`)
- Skill catalogs (`skills/` + `_index/SKILL.md`)
- Documentation directories (`docs/` + `README.md` or `docs/index.md`)
- Rule directories (`rules/` + `rules/README.md`)
- Any directory where additions should be reflected in an index file but drift accumulates

## Arguments

- `DIRECTORY` — the directory to scan (default: `.`)
- `INDEX_FILE` — the file expected to reference every entry (default: `INDEX.md`, `README.md`, or `<dirname>.md`)

If arguments not provided, prompt the user or pick sensible defaults from the working directory.

## Pattern

```bash
DIR="${1:-.}"
INDEX="${2:-$DIR/README.md}"

# 1. List all candidate files in the directory (one level deep, .md by default)
find "$DIR" -maxdepth 1 -name '*.md' ! -name "$(basename $INDEX)" -printf '%f\n' 2>/dev/null | sort > /tmp/orphan-scan-files.txt

# 2. Extract file references from the index file
grep -oP '[a-z0-9_-]+\.md' "$INDEX" 2>/dev/null | sort -u > /tmp/orphan-scan-refs.txt

# 3. Orphans = files exist but not referenced
comm -23 /tmp/orphan-scan-files.txt /tmp/orphan-scan-refs.txt > /tmp/orphan-scan-orphans.txt

# 4. Phantoms = referenced but no file
comm -13 /tmp/orphan-scan-files.txt /tmp/orphan-scan-refs.txt > /tmp/orphan-scan-phantoms.txt

# Report
echo "=== Orphan Scan: $DIR vs $INDEX ==="
echo "Files: $(wc -l < /tmp/orphan-scan-files.txt)"
echo "Indexed: $(wc -l < /tmp/orphan-scan-refs.txt)"
echo ""
echo "ORPHANS ($(wc -l < /tmp/orphan-scan-orphans.txt)):"
cat /tmp/orphan-scan-orphans.txt | sed 's/^/  /'
echo ""
echo "PHANTOMS ($(wc -l < /tmp/orphan-scan-phantoms.txt)):"
cat /tmp/orphan-scan-phantoms.txt | sed 's/^/  /'
```

## False-positive sources

The simple regex-based approach has known false positives:

1. **Bundle references** — index entries like "frameworks (12): A · B · C" don't match individual filenames. Solution: scan also for stem references (sans `.md`) OR accept bundle-listed files as indexed.
2. **Path references** — index entries that reference paths (e.g., `intent.md` referenced as `PROJECTS/.../intent.md`) get matched by the basename regex but the actual file isn't in the scan directory. Result: false-positive phantom.
3. **Glob artifacts** — partial filename matches from other content can yield phantom-looking entries (e.g., `0.md` from a numbered list item).

After running, manually inspect the orphan/phantom lists for these patterns before treating them as actionable.

## Output Format

```
Orphan Scan | <directory> vs <index_file>
═══════════════════════════════════════════

INVENTORY
  Files in directory: N
  Indexed references: M

ORPHANS (file exists, not indexed): K
  - file1.md
  - file2.md
  ...

PHANTOMS (indexed, no file): J
  - missing1.md
  - missing2.md
  ...

LIKELY FALSE POSITIVES
  - <bundle-referenced files if detected>
  - <glob artifacts like "_suffix.md">
```

## Next Action

- Orphans should be either indexed (add to INDEX_FILE) or archived (move to `_archived/` subdir)
- Phantoms should be either removed from index OR the missing file should be restored
- Bundle false positives should be documented in the scan output for human review

This skill is **read-only**. It never modifies the directory or index file.

## Related

- `[skill-audit]` — security audit for skill files (companion check)
- `[memory-evolve]` — full memory-system scoring (includes orphan-scan as one component)
- `[stale-cleanup]` — broader cleanup including stale branches + orphaned worktrees

## Rules

- Read-only — never delete files or modify the index
- Print results to stdout — do not write modifications
- Flag known false positives explicitly so the consumer doesn't over-prune
- Cap output at 50 orphans / 20 phantoms inline — write full lists to `/tmp/orphan-scan-*.txt` for downstream consumption
