---
name: ci-monitor
description: Monitor GitHub Actions -- list runs, check status, view logs, retry failed jobs.
version: 0.1.0
execution-mode: advisory
argument-hint: "[status | runs | logs RUN_ID | retry RUN_ID | watch]"
category: backend-infra
status: candidate
---
## Context Gathering

Before executing this skill, gather the following context:
- **Latest CI**: Run `gh run list --limit 3 --json status,conclusion,workflowName,headBranch --jq '.[] | "\(.status)/\(.conclusion // "—") \(.workflowName) [\(.headBranch)]"' 2>/dev/null || echo "(gh unavailable)"`

# CI Monitor

GitHub Actions monitoring beyond what `[ci-wait]` provides.

## Operations

### status
Quick dashboard of all recent CI runs:
```bash
gh run list --limit 10 --json status,conclusion,workflowName,headBranch,createdAt \
  --jq '.[] | "\(.status)/\(.conclusion // "—") \(.workflowName) [\(.headBranch)] \(.createdAt[:10])"'
```

### runs
List runs filtered by workflow or branch:
```bash
# By workflow
gh run list --workflow ci.yml --limit 5

# By branch
gh run list --branch main --limit 5

# Failed only
gh run list --status failure --limit 10
```

### logs
View logs for a specific run:
```bash
gh run view RUN_ID --log-failed  # Only failed job logs
gh run view RUN_ID --log          # All logs
```

### retry
Retry a failed run:
```bash
gh run rerun RUN_ID --failed  # Only retry failed jobs
```

### watch
Watch a run in progress (blocks until complete):
```bash
gh run watch RUN_ID
```

## Our Workflows (13 total)

| Workflow | Triggers | What It Checks |
|----------|----------|----------------|
| `ci.yml` | Push, PR | Tests on Python 3.11 + 3.12 |
| `security.yml` | Push, PR | Bandit + Semgrep + pip-audit |
| `lint-and-schema.yml` | Push, PR | Script lint, schema validation, secret scan |
| `coordination-scripts.yml` | Push, PR | Coordination script smoke tests |
| `contracts-all.yml` | Push, PR | Contract schema validation |
| `packages-runtime.yml` | Push, PR | Runtime package validation |
| `platform-configs.yml` | Push, PR | Cost-governor config validation |
| `pr-guardrails.yml` | PR | Size/churn guardrails (warn 500 LOC, block 3000) |
| `mutation-testing.yml` | Schedule | Mutation testing |
| `lexicon-lint.yml` | Push | Lexicon/terminology consistency |
| `$REMOTE_HOST-compliance.yml` | Push | remote-node-specific checks |
| `risk-classifier.yml` | PR | Risk classification |
| `toolchain-verify.yml` | Push | Toolchain integrity |

## Triage Pattern
1. Check which workflow failed: `gh run list --status failure --limit 5`
2. View failed logs: `gh run view RUN_ID --log-failed`
3. If flaky (passes on retry): `gh run rerun RUN_ID --failed`
4. If real failure: use `[debug-test]` to fix locally, then push
