---
name: contract-review
description: Review and validate contract schemas for breaking changes and compatibility.
version: 0.1.0
execution-mode: advisory
argument-hint: "<contract path or \"all\">"
category: dev-tools
status: candidate
---
# Contract Review

Review contract schemas in `contracts/` for breaking changes, compatibility, and completeness.

## When to Use
- Before bumping `fm-contracts-vX.Y` baseline
- When modifying any schema in `contracts/`
- During release prep
- After another agent proposes schema changes

## Execution

### 1. Diff against frozen baseline
```bash
# Current baseline: $FROZEN_BASELINE_TAG
git diff $FROZEN_BASELINE_TAG..HEAD -- contracts/
```

### 2. Classify changes
| Change Type | Breaking? | Action Required |
|-------------|-----------|----------------|
| New optional field | No | Document |
| New required field | **YES** | Major version bump |
| Removed field | **YES** | Major version bump |
| Type change | **YES** | Major version bump |
| Enum value added | No | Minor version bump |
| Enum value removed | **YES** | Major version bump |
| Description change | No | None |

### 3. Validate schemas
```bash
source .venv/bin/activate
python -m your_package.cognition validate  # CLP schemas
# Add other schema validators as they exist
```

### 4. Check cross-references
- Do any services import contract types that changed?
- Do any tests assert on contract shapes that changed?
- Do any bus messages reference contract fields that changed?

### 5. Governance check
Per CLAUDE.md governance rules:
- Contracts are canonical (source of truth)
- Breaking changes require SemVer major bump
- Breaking changes require a new `fm-contracts-vX.Y` baseline tag

## Output Format
```
Contract Review | <scope>
═══════════════════════════

## Changes Since Baseline ($FROZEN_BASELINE_TAG)
<diff summary>

## Breaking Changes
<list or "None found">

## Required Actions
- [ ] Version bump: <major/minor/patch>
- [ ] New baseline tag: fm-contracts-vX.Y
- [ ] Update consuming services: <list>
- [ ] Update tests: <list>

## Validation
<schema validation results>
```
