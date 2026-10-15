---
name: client-report
description: Generate periodic client progress report from time logs, deliverables, and milestones
version: 0.1.0
execution-mode: advisory
argument-hint: "<client> [--period weekly|monthly] [--format md|pdf]"
category: sales-marketing
status: candidate
---
# Client Report

Generate a periodic progress report for a client engagement by aggregating time tracking data, completed deliverables, milestone status, and upcoming work. Supports weekly and monthly cadences with markdown or PDF output.

## When to Use
- At the end of a billing period to summarize progress
- Before a client check-in meeting to prepare talking points
- When a client requests a status update on their engagement
- For internal review of engagement utilization and velocity

## Execution
1. Parse `$ARGUMENTS` for client name, period (default: weekly), and format (default: md)
2. Pull time entries from `[time-track]` data for the specified period and client
3. Pull milestone status from `_state/engagements.jsonl` for the client
4. Aggregate: hours worked, deliverables completed, milestones hit, blockers encountered
5. Calculate utilization rate (hours worked vs hours budgeted)
6. Generate the report in the requested format
7. If `--format pdf`, use `[docgen]` skill to render

## Output Format
```
Client Report | <client> | <period>
=====================================

## Period: <start_date> to <end_date>

## Summary
- Hours logged: X / Y budgeted (Z% utilization)
- Deliverables completed: N
- Milestones: N completed, M in progress

## Deliverables Completed
1. <deliverable> — <date completed>

## Milestone Status
| Milestone | Status | Due | Notes |
|-----------|--------|-----|-------|
| ... | ... | ... | ... |

## Hours Breakdown
| Category | Hours | % of Total |
|----------|-------|------------|
| ... | ... | ... |

## Upcoming Work
- ...

## Blockers / Risks
- ...

## Next Action
- ...
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| Report generated, ready to send | `[send-email]` to deliver to client |
| Hours look off or need adjustment | `[time-track]` to review and correct entries |
