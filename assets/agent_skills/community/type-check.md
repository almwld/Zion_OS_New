---
name: type-check
description: Run mypy or pyright type checking, report untyped functions, suggest type annotations for worst offenders
version: 0.1.0
execution-mode: remedial
argument-hint: "[PATH] [--strict] [--fix]"
category: dev-tools
status: candidate
---
# Type Check

Run static type checking on Python code using mypy or pyright, identify untyped functions and parameters, and suggest type annotations for the worst offenders. Reports type coverage percentage and prioritizes fixes by impact.

## When to Use
- Before merging a feature to catch type-related bugs early
- Auditing type coverage across the codebase or a specific module
- Adding type annotations incrementally to an untyped codebase
- After refactoring to verify type contracts still hold

## Execution
1. Parse `$ARGUMENTS` for target path (default: current directory), strict mode, and fix mode.
2. Check available type checkers: try `mypy --version`, then `pyright --version`.
3. Run the type checker on the target path. If `--strict`, use `mypy --strict` or pyright strict mode.
4. Parse output into categorized findings: errors, warnings, notes.
5. Scan target files with AST analysis to find functions missing type annotations (parameters and return types).
6. Rank untyped functions by: (a) number of callers, (b) module importance, (c) function complexity.
7. If `--fix`, generate suggested type annotations for the top offenders using signature analysis, docstrings, and usage patterns.
8. Report type coverage as a percentage of annotated vs total function signatures.

## Output Format
```
Type Check | {path}

## Type Checker Results
- Tool: {mypy|pyright} {version}
- Mode: {standard|strict}
- Errors: {N} | Warnings: {N} | Notes: {N}

## Top Errors
| File | Line | Code | Message |
|------|------|------|---------|
| {file} | {line} | {code} | {message} |

## Type Coverage
- Functions with full annotations: {N}/{total} ({pct}%)
- Parameters missing types: {N}
- Missing return types: {N}

## Worst Offenders (untyped, high-impact)
| Function | File | Callers | Suggested Fix |
|----------|------|---------|---------------|
| {func} | {file} | {N} | {annotation suggestion} |

No further action needed. | Consider [bulk-edit] to apply annotations.
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| Many type errors found | `[full-audit]` for broader code quality check |
| Untyped functions identified | `[tech-debt]` to track as debt items |
| Annotations needed across many files | `[bulk-edit]` to apply mechanical fixes |
