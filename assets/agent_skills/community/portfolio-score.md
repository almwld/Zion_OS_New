---
name: portfolio-score
description: Score all repos against Arbiter quality standards — identify which need work before showcasing
version: 1.0.0
execution-mode: advisory
argument-hint: "[--repos all|pinned] [--org $GITHUB_ORG]"
category: dev-tools
status: candidate
---
# Portfolio Score

Score repositories across the portfolio on quality signals. Identifies which repos are showcase-ready and which need work before public visibility.

## Arguments
- `--repos <all|pinned>` — Scope: all repos or just pinned (default: all)
- `--org <name>` — GitHub org to scan (default: $GITHUB_ORG)
- `--local` — Score only repos cloned in PROJECTS/ (skip GitHub API)

## Procedure

### 1. Enumerate Repos

For local scanning:
```bash
ls -d PROJECTS/*/  # List all project directories
```

For GitHub org:
```bash
gh repo list <org> --limit 100 --json name,description,isPrivate,pushedAt,stargazerCount,primaryLanguage,isArchived
```

Filter out archived repos unless `--repos all` is explicit.

### 2. Score Each Repo (8 Dimensions)

For each repo at `<path>`:

**a. README Quality (0-10)**
```bash
test -f <path>/README.md && wc -l <path>/README.md
```
- 0: No README
- 3: README exists but <20 lines
- 6: README >50 lines with sections
- 8: README >100 lines with badges, install, usage
- 10: README with badges, GEO-optimized, FAQ, llms.txt reference

**b. License (0-5)**
```bash
test -f <path>/LICENSE || test -f <path>/LICENSE.md
```
- 0: No license file
- 5: License present

**c. Tests (0-15)**
```bash
find <path> -name "test_*.py" -o -name "*_test.py" -o -name "*.test.ts" | wc -l
```
- 0: No test files
- 5: 1-5 test files
- 10: 6-20 test files
- 15: >20 test files

**d. CI/CD (0-10)**
```bash
ls <path>/.github/workflows/*.yml 2>/dev/null | wc -l
```
- 0: No workflows
- 5: 1-2 workflows
- 8: 3-5 workflows
- 10: >5 workflows

**e. Freshness (0-10)**
```bash
git -C <path> log --oneline -1 --format="%ar %h %s"
```
- 0: >1 year since last commit
- 3: 3-12 months
- 6: 1-3 months
- 8: 1-4 weeks
- 10: Within last week

**f. .gitignore (0-5)**
```bash
test -f <path>/.gitignore && wc -l <path>/.gitignore
```
- 0: No .gitignore
- 3: Minimal .gitignore (<5 lines)
- 5: Comprehensive .gitignore

**g. Documentation (0-10)**
```bash
find <path> -name "*.md" -not -name "README.md" -not -path "*node_modules*" | wc -l
```
- 0: README only
- 5: 1-5 additional docs
- 8: 6-15 docs
- 10: >15 docs or dedicated docs/ directory

**h. Code Quality Signals (0-10)**
```bash
# Check for linting config, type hints, pyproject.toml/package.json
test -f <path>/pyproject.toml || test -f <path>/package.json
test -f <path>/.flake8 || test -f <path>/.eslintrc* || test -f <path>/ruff.toml
```
- 0: No project config
- 5: Has project manifest
- 8: Has linter config + manifest
- 10: Has manifest + linter + type checking config

### 3. Compute Grade

**Total: 0-75 points**

| Grade | Points | Meaning |
|-------|--------|---------|
| A | 60-75 | Showcase-ready, pin this repo |
| B | 45-59 | Good shape, minor improvements needed |
| C | 30-44 | Needs work before showcasing |
| D | 15-29 | Significant gaps, not ready for public |
| F | 0-14 | Skeleton or abandoned, archive candidate |

### 4. Generate Improvement Plan

For each repo scoring below A, list the top 3 improvements by point value:
- e.g., "Add 10 test files: +10 points (D -> C)"
- e.g., "Add CI workflow: +5 points"
- e.g., "Expand README to 100+ lines: +4 points"

## Output Format

```
Portfolio Score | <org> | <date>

Repos scanned: <N> (<public>/<private>, <archived> excluded)

Scorecard (sorted by grade):
  Grade  Score  Repo                    README  License  Tests  CI  Fresh  Ignore  Docs  Quality
  A      68/75  hummbl-governance       10      5        15     10  10     5       8     5
  A      62/75  hummbl-governance            8       5        15     10  10     5       5     4
  B      51/75  foundermode-app         6       5        10     8   10     5       3     4
  C      35/75  swarm-test              6       5        5      5   10     3       1     0
  ...

Summary:
  A-grade: <N> repos
  B-grade: <N> repos
  C-grade: <N> repos
  D-grade: <N> repos
  F-grade: <N> repos

Top Improvements (highest ROI):
  1. <repo>: Add LICENSE (+5) and CI (+5) -> B to A
  2. <repo>: Add tests (+10) -> D to C
  3. <repo>: Expand README (+4) -> C to B

Next action: Fix highest-ROI improvements, then re-score
```

## Notes

- Pinned repos should all be A-grade before showcasing
- Private repos still scored (for internal quality tracking)
- Archived repos excluded by default but can be included
- Score is relative to portfolio; compare against peer orgs for absolute quality

## Skill Chains

| After completing... | Consider... |
|---|---|
| Low scores found | `[readme-gen]`, `[tdd]`, `[license-audit]` per repo |
| All A-grade | `[seo-check]` (optimize discoverability) |
| Archival candidates | `[stale-cleanup]` (archive low-value repos) |
| Pre-job-sprint | Ensure top 5 repos are A-grade |
