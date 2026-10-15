---
name: docstring-audit
description: Audit docstring coverage, style consistency (Google/NumPy/Sphinx), and parameter accuracy against signatures
version: 0.1.0
execution-mode: advisory
argument-hint: "[PATH] [--style google|numpy|sphinx] [--coverage-threshold PCT]"
category: dev-tools
status: candidate
---
# Docstring Audit

Audit Python code for docstring coverage, style consistency, and accuracy. Checks that docstrings exist for public functions and classes, follow a consistent style convention, and accurately document all parameters, return types, and exceptions.

## When to Use
- Before generating API documentation to ensure source material is complete
- As part of a code quality review to identify documentation gaps
- When enforcing a docstring style standard across a team
- After refactoring to verify docstrings still match their function signatures

## Execution
1. Parse `$ARGUMENTS` for target path, preferred style (default: google), and coverage threshold (default: 80%).
2. Use Python AST to find all public functions, methods, and classes in the target path.
3. For each item, check: (a) docstring exists, (b) docstring is non-empty and non-trivial.
4. Detect docstring style by pattern matching (Google: `Args:`, NumPy: `Parameters\n----------`, Sphinx: `:param`).
5. For functions with docstrings, cross-reference documented parameters against the actual signature.
6. Flag: missing params, extra params (documented but not in signature), wrong types, missing return docs, missing exception docs for `raise` statements.
7. Calculate coverage percentage: (items with valid docstrings / total public items).
8. Report style inconsistencies (mixed styles in the same module).

## Output Format
```
Docstring Audit | {path}

## Coverage
- Public items: {N}
- With docstrings: {N} ({pct}%)
- Threshold: {threshold}% | {PASS|FAIL}

## Style Consistency
- Dominant style: {google|numpy|sphinx|mixed}
- Files with mixed styles: {N}

## Parameter Accuracy
| Function | File | Issue |
|----------|------|-------|
| {func} | {file} | Missing param: {name} |
| {func} | {file} | Extra param: {name} (not in signature) |
| {func} | {file} | Missing return type documentation |
| {func} | {file} | Undocumented raise: {ExceptionType} |

## Missing Docstrings (top priority)
| Item | File:Line | Type |
|------|-----------|------|
| {name} | {file}:{line} | {function|class|method} |

No further action needed. | Consider [api-docs] to generate documentation.
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| Coverage meets threshold | `[api-docs]` to generate documentation from docstrings |
| Many undocumented functions | `[dead-code]` to check if they are actually used |
| Parameter mismatches found | `[bulk-edit]` if fixes are mechanical |
