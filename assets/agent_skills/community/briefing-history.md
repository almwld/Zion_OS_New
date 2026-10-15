---
name: briefing-history
description: List, search, compare, and show past morning briefings.
version: 0.1.0
execution-mode: advisory
argument-hint: "[list | show <date> | diff <date1> <date2> | search <pattern>]"
category: fleet-ops
status: candidate
---
## Context Gathering

Before executing this skill, gather the following context:
- **Recent briefings**: Run `ls -t ~/state/briefings/*.md 2>/dev/null | head -5 || echo "none"`

# Briefing History Command

Browse and analyze past morning briefings.

## Usage

```bash
[briefing-history]                    # List last 10 briefings
[briefing-history] list               # Same as above
[briefing-history] show 2026-02-24    # Show a specific day's briefing
[briefing-history] diff 2026-02-23 2026-02-24   # Compare two briefings
[briefing-history] search "Linear"    # Search across all briefings
```

## Execution

### list (default)
```bash
ls -lt state/briefings/*.md | head -10
```
For each file, show date, line count, and first heading.

### show <date>
```bash
cat state/briefings/<date>.md
```
Display the full briefing content.

### diff <date1> <date2>
Read both briefings and produce a structured comparison:
- Sections added/removed
- Key metric changes (costs, PR counts, calendar items)
- New issues or resolved issues

### search <pattern>
```bash
grep -l "<pattern>" state/briefings/*.md
grep -n "<pattern>" state/briefings/*.md | head -20
```
Show which briefings mention the pattern and the matching lines.

## Output Format

### list
```
Briefing History
════════════════

| Date | Lines | Adapters | Summary |
|------|-------|----------|---------|
| 2026-02-24 | 142 | 6/7 | 3 PRs, 5 meetings |
| 2026-02-23 | 138 | 7/7 | Release prep |
| ... | ... | ... | ... |
```

### diff
```
Briefing Diff | 2026-02-23 → 2026-02-24
════════════════════════════════════════

## Changes
- PRs: 5 → 3 (-2)
- Calendar items: 3 → 5 (+2)
- New: "CI pipeline degraded" warning
- Resolved: "Linear sync issue" from yesterday
```

## Constraints

- READ-ONLY. Do not modify briefing files.
- Briefing files are in `state/briefings/` with `YYYY-MM-DD.md` naming.
- Do not fabricate briefing content -- always read actual files.
