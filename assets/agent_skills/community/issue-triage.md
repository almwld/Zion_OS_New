---
name: issue-triage
description: Triage GitHub issues -- auto-label, prioritize by severity/type, identify stale issues, suggest assignees
version: 0.1.0
execution-mode: advisory
argument-hint: "[--repo OWNER/REPO] [--action triage|stale|stats]"
category: fleet-ops
status: candidate
---
# Issue Triage

Triage GitHub issues by analyzing titles, descriptions, and labels to auto-categorize, prioritize, identify stale issues, and suggest assignees based on code ownership patterns.

## When to Use
- During weekly issue grooming sessions
- When a backlog has grown and needs prioritization
- When looking for stale issues that should be closed or revived
- When new issues come in and need quick categorization

## Execution
1. Parse `$ARGUMENTS` for repo (default: current repo) and action (default: triage)
2. For `triage`: fetch open issues via `gh issue list`, analyze each for type (bug, feature, docs, chore) and severity (P1-P4)
3. For `stale`: identify issues with no activity in 30+ days, suggest close or ping
4. For `stats`: generate issue metrics -- open count, avg age, label distribution, close rate
5. Suggest labels based on title/description keyword analysis
6. Suggest assignees based on git blame of related files mentioned in issues
7. Generate a prioritized triage list

## Output Format
```
Issue Triage | <repo> | <action>
==================================

## Triage Queue (prioritized)
| # | Title | Type | Severity | Suggested Labels | Suggested Assignee |
|---|-------|------|----------|-----------------|-------------------|
| ... | ... | bug | P1 | bug, urgent | ... |

## Stale Issues (>30d no activity)
| # | Title | Last Activity | Recommendation |
|---|-------|--------------|----------------|
| ... | ... | <date> | CLOSE / PING / KEEP |

## Stats
- Open: N | Closed (30d): M | Avg age: X days
- By type: N bugs, M features, K chores
- Unlabeled: N issues

## Next Action
- ...
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| Issues prioritized, need ordering | `[rice-prioritize]` to score by RICE |
| Issues inform sprint planning | `[sprint-status]` to check capacity |
