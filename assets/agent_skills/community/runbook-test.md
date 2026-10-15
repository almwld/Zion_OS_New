---
name: runbook-test
description: Dry-run runbook steps to verify procedures still work — commands exist, paths valid, services reachable
version: 1.0.0
execution-mode: advisory
argument-hint: <runbook-path>
category: governance-compliance
status: candidate
---
# Runbook Test | `$ARGUMENTS`

Dry-run a markdown runbook to verify every command, path, and service reference is still valid. No destructive operations executed.

## Context Gathering

Before executing this skill, gather the following context:
- Run `ls -1 playbooks/*.md docs/operations/*.md 2>/dev/null | head -20`
- Run `uname -s`
- Run `python3 --version 2>&1`

## Procedure

Parse `$ARGUMENTS` for the runbook file path. If not provided, list available runbooks from `playbooks/` and `docs/operations/` and ask the user to pick one.

### Step 1 — Parse Runbook

Read the target runbook file. Extract all fenced code blocks (```bash, ```sh, ```shell, ```) and inline code commands that look executable.

For each extracted command, classify as:
- **CHECK**: Non-destructive, safe to validate (ls, cat, which, curl health, test -d)
- **SKIP**: Destructive or mutating (rm, kill, launchctl unload, pip install)
- **PARTIAL**: Can validate prerequisites but not execute (verify binary exists for a deploy command)

### Step 2 — Validate Commands

For each extracted command, run the appropriate checks:

```bash
# Binary existence check
which <binary> >/dev/null 2>&1 && echo "PASS: <binary> found at $(which <binary>)" || echo "FAIL: <binary> not found"
```

```bash
# Path validity check
test -e <path> && echo "PASS: <path> exists" || echo "FAIL: <path> missing"
test -d <path> && echo "PASS: <path> is directory" || echo "FAIL: <path> is not directory"
test -f <path> && echo "PASS: <path> is file" || echo "FAIL: <path> is not file"
```

```bash
# Service reachability check (HTTP endpoints)
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 3 <url>)
if [ "$HTTP_CODE" -ge 200 ] && [ "$HTTP_CODE" -lt 500 ]; then
    echo "PASS: <url> responded $HTTP_CODE"
else
    echo "FAIL: <url> responded $HTTP_CODE (or unreachable)"
fi
```

```bash
# Port check (for localhost services)
lsof -i :<port> >/dev/null 2>&1 && echo "PASS: port <port> is listening" || echo "FAIL: port <port> not listening"
```

```bash
# Python import check
python3 -c "import <module>" 2>&1 && echo "PASS: <module> importable" || echo "FAIL: <module> not importable"
```

```bash
# Environment variable check
[ -n "${VAR_NAME}" ] && echo "PASS: $VAR_NAME is set" || echo "FAIL: $VAR_NAME is unset"
```

### Step 3 — Cross-Reference Dependencies

Check if the runbook references other runbooks or external docs:

```bash
# Find cross-references to other docs
grep -oE '\[.*?\]\(.*?\.md\)' <runbook-path> 2>/dev/null | while read -r ref; do
    target=$(echo "$ref" | grep -oE '\(.*?\)' | tr -d '()')
    test -f "$target" && echo "PASS: ref $target exists" || echo "FAIL: ref $target missing"
done
```

### Step 4 — Version Checks

If the runbook specifies version requirements, validate them:

```bash
# Python version
python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}')"
# Git version
git --version 2>&1
# Node/Bun version (if referenced)
node --version 2>/dev/null || echo "node not installed"
bun --version 2>/dev/null || echo "bun not installed"
```

### Step 5 — Generate Report

Count results per category and produce the structured output.

## Output Format

```
Runbook Test | <runbook-name> | <date>
======================================

Source: <path>
Total Steps: N
  CHECK:   X extracted (safe to validate)
  SKIP:    Y extracted (destructive, not run)
  PARTIAL: Z extracted (prerequisites only)

Results:
  Step  1: [PASS] which python3 -> /usr/bin/python3
  Step  2: [PASS] test -d .venv -> exists
  Step  3: [FAIL] curl localhost:8080 -> connection refused
  Step  4: [SKIP] launchctl unload ... (destructive)
  Step  5: [PASS] python3 -c "import your_project" -> OK
  ...

Summary:
  PASS:    X / N
  FAIL:    Y / N
  SKIP:    Z / N

Failed Steps:
  Step 3 — Service unreachable: configured messaging service on port 8080
    Fix: brew services start configured messaging service (or check launchd plist)
  ...

Staleness Risk:
  Last modified: <runbook mtime>
  Days since update: <N>
  Verdict: <FRESH (<30d) | STALE (30-90d) | ROTTEN (>90d)>

Next action: <fix N failures | runbook is current | update stale sections>
```

## Skill Chains
- After: `[runbook-write]` (rewrite stale sections), `[health]` (if service checks failed), `[incident]` (if critical paths broken)

## External References (Supplement)

- `anthropics/knowledge-work-plugins@runbook` — useful sectioning conventions for validation/report output.
- `sickn33/antigravity-awesome-skills@incident-runbook-templates` — incident dry-run structure ideas that align with service testing.
