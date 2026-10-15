---
name: incident
description: Run non-mutating incident triage with explicit health, bus, kill-switch, repository-bound CI, ports, and error checks.
version: 0.2.0
execution-mode: advisory
argument-hint: "[triage | investigate DESCRIPTION] [--repo owner/repo]"
category: security
status: candidate
---

# Incident Command

Run every non-mutating check even if one fails. Escalate critical findings before remediation.

## Context

- Set `PROJECT_ROOT` to the exact hummbl-governance checkout being inspected.
- Set `INCIDENT_REPO=owner/repo` from the incident scope.
- Print both paths before executing checks.
- If either value is ambiguous, report `CONTEXT_MISSING`; do not inherit a repository from the current directory.

## Checks

### 1. Health

```bash
python -m hummbl_governance.services.health --pretty
```

### 2. Canonical bus

```bash
test -n "$PROJECT_ROOT"
printf 'Project root: %s\n' "$PROJECT_ROOT"
tail -200 "$PROJECT_ROOT/_state/coordination/messages.tsv" |
  grep -E 'BLOCKED|EMERGENCY|ALERT|FAIL|ERROR' |
  tail -20
```

Confirm that `PROJECT_ROOT` points to the canonical host ledger before interpreting results.

### 3. Kill switch

```python
from hummbl_governance.services.kill_switch_core import KillSwitch

ks = KillSwitch()
print(ks.mode.name)
```

`KillSwitch` exposes `mode`; `current_mode` is not part of the verified interface. Reading status does not authorize engagement or disengagement.

### 4. Repository-bound CI

```bash
: "${INCIDENT_REPO:?Set INCIDENT_REPO=owner/repo for this incident}"
printf 'GitHub repository: %s\n' "$INCIDENT_REPO"
gh run list \
  --repo "$INCIDENT_REPO" \
  --limit 3 \
  --json databaseId,conclusion,status,displayTitle,headSha
```

If the repository cannot be selected unambiguously, report `CI_CONTEXT_MISSING` and skip the query.

### 5. Listening ports

On macOS/Linux:

```bash
lsof -iTCP -sTCP:LISTEN -P -n 2>/dev/null
```

On Windows:

```powershell
Get-NetTCPConnection -State Listen |
  Sort-Object LocalPort |
  Select-Object LocalAddress,LocalPort,OwningProcess
```

### 6. Recent errors

```bash
tail -200 "$PROJECT_ROOT/_state/coordination/messages.tsv" |
  grep -Ei 'error|fail|blocked|emergency|alert' |
  tail -50
```

## Output

| Check | State | Evidence source |
|---|---|---|
| Health | `OK/WARN/CRIT/UNKNOWN` | command and exact checkout |
| Bus | `OK/WARN/CRIT/CONTEXT_MISSING` | canonical path and latest timestamp |
| Kill switch | exact mode or `ERROR` | verified API |
| CI | `PASS/FAIL/PENDING/CI_CONTEXT_MISSING` | printed `owner/repo` |
| Ports | `OK/WARN/UNKNOWN` | platform command |
| Errors | `NONE/FOUND/UNKNOWN` | bounded bus window |

List issues by severity, separate observations from inferences, and provide reversible recommendations.

## Constraints

- Diagnostic only. Do not remediate without explicit approval.
- Run all safe checks even if an earlier check fails.
- Never suppress all stderr when it is needed to classify a failure.
- Bind every `gh` query to the printed `INCIDENT_REPO`.
- Ask for explicit confirmation before changing kill-switch state.

