---
name: deprecation-track
description: Track deprecated APIs, functions, and config with expiry dates, migration paths, and usage counts
version: 0.1.0
execution-mode: advisory
argument-hint: "[--action scan|add|report] [--expiry DATE]"
category: fleet-ops
status: candidate
---
# Deprecation Tracker

Track the full lifecycle of deprecated code -- from marking something deprecated to removing it. Scans for deprecation warnings, tracks expiry dates, counts remaining usages, and generates migration guides.

## When to Use
- Before a release, to check if any deprecations have reached their expiry date
- When marking a function or API as deprecated and need to set a removal timeline
- To generate a report of all active deprecations with usage counts and migration paths
- During tech debt sprints to identify deprecated code ready for removal

## Execution
1. Parse `$ARGUMENTS` for `--action` (default: `scan`) and optional `--expiry DATE`
2. For `scan`: grep codebase for deprecation patterns (`@deprecated`, `warnings.warn(DeprecationWarning)`, `# DEPRECATED`, docstring markers)
3. For each deprecation found, count remaining call sites and importers
4. For `add`: create or update a deprecation entry with item name, replacement, expiry date, and migration notes
5. For `report`: generate a summary grouped by urgency (overdue, due this month, future)
6. Cross-reference with git history to determine when each deprecation was introduced
7. Output actionable items: what can be removed now, what needs migration work first

## Output Format
```
Deprecation Tracker | {action}
────────────────────────────────
Total deprecations: {N}
Overdue: {N} | Due soon: {N} | Future: {N}

| Item | Replacement | Added | Expiry | Usages | Status |
|------|-------------|-------|--------|--------|--------|
| old_func() | new_func() | 2026-01 | 2026-04 | 3 | OVERDUE |

Migration needed for {N} items before removal.
Action: {next steps or "No further action needed"}
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| Report shows overdue items | `[tech-debt]` to prioritize removal work |
| Deprecation removed | `[changelog]` to document the breaking change |
| Many call sites to update | `[bulk-edit]` for mechanical replacement across files |
