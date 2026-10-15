---
name: security-scan
description: On-demand Bandit + Semgrep security scan.
version: 0.1.0
execution-mode: advisory
argument-hint: "[<file-or-dir>]"
authority: operator
status: tested
category: security
providers:
  required: [bash, python]
---
## Context Gathering

Before executing this skill, gather the following context:
- **Changed Python files**: Run `git diff --name-only main 2>/dev/null | grep "\.py$" | wc -l || echo "0"`

# Security Scan Command

Run Bandit and Semgrep security analysis on the codebase or specific files.

## Usage

```bash
[security-scan]                        # Scan entire $PROJECT_ROOT/
[security-scan] services/scheduler.py  # Scan a specific file
[security-scan] integrations/          # Scan a directory
```

## Execution

### 1. Bandit scan
```bash
bandit -r $PROJECT_ROOT/<target> -ll -f json 2>/dev/null
```
If targeting a specific file: `bandit <file> -ll -f json`

### 2. Semgrep scan
```bash
semgrep --config auto $PROJECT_ROOT/<target> --json 2>/dev/null
```

### 3. Parse results
Categorize findings by severity: CRITICAL, HIGH, MEDIUM, LOW.

### 4. Delta analysis (if on a branch)
Compare findings against main:
```bash
git stash && bandit -r $PROJECT_ROOT/ -ll -f json > /tmp/baseline.json 2>/dev/null && git stash pop
```
Show new findings vs baseline.

## Output Format

```
Security Scan | <YYYY-MM-DD HH:MMZ>
════════════════════════════════════

Target: <file or directory>

## Bandit Results
| Severity | Count | Issues |
|----------|-------|--------|
| HIGH | 0 | — |
| MEDIUM | 2 | B108 (hardcoded tmp), B301 (pickle) |
| LOW | 1 | B101 (assert) |

## Semgrep Results
| Severity | Count | Rule |
|----------|-------|------|
| ERROR | 0 | — |
| WARNING | 1 | python.lang.security.audit.exec |

## Findings Detail
<for each finding: file, line, description, recommendation>

## Summary
- Total findings: N
- Blockers (HIGH/ERROR): N
- CI would: PASS/FAIL
```

## Constraints

- READ-ONLY analysis. Do not auto-fix findings.
- If Bandit or Semgrep is not installed, report it and suggest installation.
- Do not fabricate findings -- always run actual scans.
- CI policy: Bandit fails on HIGH; Semgrep blocks on ERROR.
