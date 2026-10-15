---
name: inbox-zero
description: Process all pending items to zero -- open PRs, stale issues, unanswered bus messages, dirty repos, unread alerts
version: 0.1.0
execution-mode: side_effecting
argument-hint: "[--scope prs|issues|bus|repos|all]"
category: fleet-ops
status: candidate
---
# Inbox Zero

Systematically process all pending work items across the project ecosystem to reach a clean state. Scans open PRs, stale issues, unanswered bus messages, dirty repos, and unread alerts, then triages each item with a recommended action.

## When to Use
- Start of day or session to clear the backlog before new work
- Feeling overwhelmed by accumulated notifications and open items
- Before a sprint or planning session to ensure nothing is forgotten
- After a long break to catch up on what needs attention

## Execution
### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=inbox-zero] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

1. Parse `$ARGUMENTS` for scope filter. Default to `all`.
2. **PRs**: Run `gh pr list --state open` across relevant repos. Note age, review status, CI state.
3. **Issues**: Run `gh issue list --state open` and flag stale (>7 days no activity).
4. **Bus**: Scan `_state/coordination/messages.tsv` for unanswered QUESTIONs, unresolved BLOCKEDs, and PROPOSALs without ACK.
5. **Repos**: Run `git status` across PROJECTS/ repos for uncommitted changes, unpushed commits.
6. **Alerts**: Check health probes, CI failures, and cost alerts for unacknowledged items.
7. For each item, classify as: ACT (do now), DELEGATE (assign), DEFER (schedule), DROP (close/dismiss).
8. Present a prioritized action list with recommended disposition for each item.

## Output Format
```
Inbox Zero | {date}

## Open Items: {total count}

### PRs ({N})
| # | Repo | Title | Age | CI | Action |
|---|------|-------|-----|-----|--------|
| {num} | {repo} | {title} | {days}d | {pass/fail} | {ACT/DELEGATE/DEFER/DROP} |

### Issues ({N})
| # | Repo | Title | Age | Action |
|---|------|-------|-----|--------|

### Bus ({N} unanswered)
| Time | From | Type | Message | Action |
|------|------|------|---------|--------|

### Dirty Repos ({N})
| Repo | Status | Action |
|------|--------|--------|

### Alerts ({N})
| Source | Severity | Message | Action |
|--------|----------|---------|--------|

## Recommended Next Actions
1. {highest priority action}
2. {next action}
3. {next action}

Inbox score: {N} items remaining after triage.
```

## Skill Chains

### Mandatory

None — batch processing; individual items have their own chains.

### Advisory

- Items triaged to ACT → `[find-work]` to prioritize the action items
- Stale issues found → `[issue-triage]` to label and assign
- Dirty repos found → `[stale-cleanup]` to clean branches and stashes

## Authority

- **T1 (TRUSTED)**: May run
- **T2 (Active/High)**: May run
- **T3 (Medium)**: Operator approval for bulk actions
- **T4 (Probationary)**: BLOCKED (batch processing authority)
- **Operator**: Override any restriction
