---
name: release-notes
description: Release prep -- changelog, breaking changes, migration notes.
version: 0.1.0
execution-mode: advisory
argument-hint: <version-tag>
category: backend-infra
status: candidate
---
## Context Gathering

Before executing this skill, gather the following context:
- **Recent tags**: Run `git tag --sort=-v:refname 2>/dev/null | head -5 || echo "no tags"`
- **Current version**: Run `grep -o 'version.*=.*"[^"]*"' $PROJECT_ROOT/your_project/__init__.py 2>/dev/null || grep -o 'version.*=.*"[^"]*"' $PROJECT_ROOT/pyproject.toml 2>/dev/null | head -1 || echo "unknown"`

# Release Notes Command

Generate a comprehensive release document for a version tag.

## Usage

```bash
[release-notes] v0.3.0         # Generate release notes for v0.3.0
```

## Execution

### 1. Determine range
Find the previous tag:
```bash
git tag --sort=-v:refname | head -5
```
Range: `<previous-tag>..HEAD` (or `<previous-tag>..<target-tag>` if the tag exists).

### 2. Generate changelog
Use the same categorization as `[changelog]`.

### 3. Identify breaking changes
```bash
git log --oneline <range> | grep -i "BREAKING\|breaking"
```
Also check for: removed public APIs, changed function signatures, renamed modules.

### 4. Generate migration notes
For each breaking change, write a concrete migration step.

### 5. Compile PR links
```bash
git log <range> --format="%s" | grep -o "#[0-9]*" | sort -u
```

### 6. Test summary
```bash
python -m pytest tests/ -q --tb=no 2>&1 | tail -1
```

## Output Format

```
# Release Notes: <version>
Date: <YYYY-MM-DD>
Previous: <previous-tag>
Commits: N | PRs: N | Contributors: N

## Highlights
<2-3 sentence summary of the most important changes>

## Breaking Changes
- **<change>**: <description>
  - Migration: <steps to update>

## Added
- <feature> (#PR)

## Changed
- <change> (#PR)

## Fixed
- <fix> (#PR)

## Security
- <security change> (#PR)

## Test Summary
- Total tests: NNNN
- Pass rate: 100%
- New tests added: N

## Full Changelog
<link or reference to git log>
```

## Constraints

- Do not fabricate commits, PRs, or test results.
- Breaking changes section is mandatory even if empty (state "None").
- Migration notes must be actionable, not vague.
- Include actual PR numbers from git history.
