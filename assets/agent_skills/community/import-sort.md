---
name: import-sort
description: Audit and fix import ordering (stdlib -> third-party -> local) with isort-compatible rules
version: 0.1.0
execution-mode: remedial
argument-hint: "[PATH] [--check|--fix] [--style pep8|google]"
category: dev-tools
status: candidate
---
# Import Sort

Audit and fix Python import ordering to follow PEP 8 conventions: stdlib imports first, then third-party, then local. Detects misordered imports, missing blank lines between sections, and unused imports. Compatible with isort conventions.

## When to Use
- Before committing code to ensure consistent import style
- As part of a code quality pass across the codebase
- When imports have grown messy after many additions
- After adding new dependencies to verify proper grouping

## Execution
1. Parse `$ARGUMENTS` for target path (default: current directory), mode (check or fix, default: check), and style.
2. For each `.py` file in the target path, parse imports using Python AST.
3. Classify each import as: stdlib, third-party, or local (first-party).
4. Check ordering within each section (alphabetical by default).
5. Check blank line separators between sections (one blank line per PEP 8).
6. Detect unused imports by cross-referencing with name usage in the file.
7. If `--check`: report violations without modifying files.
8. If `--fix`: rewrite import blocks with correct ordering, preserving comments.
9. Report summary of files checked, violations found, and fixes applied.

## Output Format
```
Import Sort | {path} | {check|fix}

## Summary
- Files scanned: {N}
- Files with violations: {N}
- Total violations: {N}
- Unused imports: {N}

## Violations
| File | Line | Issue |
|------|------|-------|
| {file} | {line} | {misordered|missing separator|unused import} |

## Unused Imports
| File | Import | Used |
|------|--------|------|
| {file} | {import} | No |

## Fixes Applied (if --fix)
- {N} files reformatted
- {N} unused imports removed

No further action needed. | Consider [commit] to save changes.
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| Fixes applied | `[deslop]` for broader code cleanup |
| Many files reformatted | `[bulk-edit]` if other mechanical fixes needed |
| Ready to save | `[commit]` to commit the formatting changes |
