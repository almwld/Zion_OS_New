---
name: time-track
description: Log and summarize billable time by project, client, and category
version: 0.1.0
execution-mode: side_effecting
argument-hint: "<start|stop|log|summary> [project] [client] [category] [notes]"
category: finance-legal
status: candidate
---
# [time-track]

## When to Use
- Starting or stopping work on a billable task
- Logging a completed block of time after the fact
- Generating time summaries for invoicing or review
- Checking how much time was spent on a project/client this week or month

## Execution

### Storage
- Log file: `_state/time/log.tsv`
- Format: `date\tstart\tstop\tduration_min\tproject\tclient\tcategory\tnotes`
- Create directory and header row if they don't exist
- Breadcrumb for active timer: `_state/time/.tracking`

### Commands

**start [project] [client] [category]**
### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=time-track] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

1. Check for existing active timer in `_state/time/.tracking`; warn if one exists
2. Write breadcrumb with: start time (UTC), project, client, category
3. Confirm start time and what is being tracked

**stop [notes]**
1. Read `_state/time/.tracking` breadcrumb
2. Calculate duration from start to now (round to nearest 5 min)
3. Append completed entry to `_state/time/log.tsv`
4. Remove breadcrumb file
5. Report duration logged

**log [duration] [project] [client] [category] [notes]**
1. Parse duration (e.g., "1h30m", "90m", "1.5h", "2h")
2. Append entry with today's date and given duration (no start/stop times)
3. Confirm what was logged

**summary [period] [filter]**
1. Read `_state/time/log.tsv`
2. Filter by period: `today`, `week`, `month`, `YYYY-MM`, or date range
3. Optionally filter by project, client, or category
4. Group and subtotal by the most useful dimension
5. Show total hours and breakdown

## Output Format

```
Time Track | <command>
============================================================
<command-specific output>

| Project       | Client | Hours | Entries |
|---------------|--------|-------|---------|
| hummbl-governance  | team lead    | 12.5  | 8       |
| project-b    | your organization | 4.0   | 3       |
| **Total**     |        | **16.5** | **11** |

Period: 2026-03-18 to 2026-03-25
------------------------------------------------------------
Next: [time-track] summary month (for monthly invoice prep)
```

## Skill Chains

### Mandatory

None — ledger append. No pre-chain required; this skill appends to a local time log.

### Advisory

- `[time-track] summary month` → `[send-email]` — for invoice delivery
- `[time-track] summary` → `[runway]` — for burn rate context
- `[time-track]` + `[expense-log]` — for a complete financial picture

## Authority

- **T1 (TRUSTED)**: Full run — start, stop, log, and summary
- **T2 (Active/High)**: Full run — start, stop, log, and summary
- **T3 (Medium)**: Summary and stop only; `start` and `log` (add) require operator notification before appending to ledger
- **T4 (Probationary)**: Summary only — may not start timers or append entries
- **Operator**: Override any restriction
