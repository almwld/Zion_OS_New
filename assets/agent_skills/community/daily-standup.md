---
name: daily-standup
description: Async daily standup from git commits, bus activity, calendar, and blockers.
version: 0.1.1
execution-mode: side_effecting
argument-hint: "[today | yesterday | date YYYY-MM-DD]"
category: dev-tools
status: candidate
---

> **Post shortcut**: Run `standup-post [date]` to gather git + bus +
> blocker activity and post a standup summary to the bus in one command.
> Add `--dry-run` to preview without posting, `--test-bus` for safe
> testing. Uses UTC date by default.
## Context Gathering

Before executing this skill, gather the following context:
- **Today's commits**: Run `git log --oneline --since="6am" --all 2>/dev/null | wc -l || echo "0"`
- **Bus messages today**: Run `grep "$(date +%Y-%m-%d)" _state/coordination/messages.tsv 2>/dev/null | wc -l || echo "0"`

# Daily Standup

Generate an async standup report synthesizing all activity sources.

## Execution

Gather these in parallel, then synthesize:

### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=daily-standup] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

### 1. Git activity
```bash
git log --oneline --since="yesterday 6am" --until="today 11:59pm" --all --author-date-order
```

### 2. Bus activity
```bash
grep "$(date +%Y-%m-%d)" _state/coordination/messages.tsv | awk -F'\t' '{print $2, $4, substr($5,1,80)}' | column -t
```

### 3. Blockers (from bus)
```bash
grep "$(date +%Y-%m-%d)" _state/coordination/messages.tsv | grep -i "BLOCKED\|ERROR\|FAIL" | tail -5
```

### 4. Calendar (if OAuth active)
```bash
source .venv/bin/activate
python3 -c "from hummbl_governance.integrations.google_calendar_adapter import fetch_events; print(fetch_events())" 2>/dev/null || echo "(calendar unavailable)"
```

## Output Format
```
Daily Standup | <date>
════════════════════════════

## Done
- <completed work from git + bus milestones>

## In Progress
- <active branches, WIP bus messages>

## Blocked
- <BLOCKED bus messages, failing CI, unresolved issues>

## Today's Plan
- <inferred from calendar + sprint goals + unfinished work>
```

## Skill Chains

### Mandatory

None — this skill is a read-only aggregation of git, bus, calendar, and blocker signals; no upstream chain is required.

### Advisory

- After standup → `[find-work]` if blockers or open items need attention
- Recurring → `[weekly-review]` for broader weekly synthesis

## Authority

- **T1 (TRUSTED)**: Full access — read-only aggregation, post standup
- **T2 (Active/High)**: Full access — read-only aggregation, post standup
- **T3 (Medium)**: Full access — read-only aggregation, post standup
- **T4 (Probationary)**: May run — read-only aggregation only
- **Operator**: Override any restriction
