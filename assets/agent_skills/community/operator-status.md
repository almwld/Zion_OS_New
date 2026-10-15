---
name: operator-status
description: Read-only snapshot of operator-owned queue. State counts, this-week SCHEDULED, GATED items with approaching triggers, stale QUEUED. Playbook at ~/.agents/playbooks/operator-owned-work.md.
version: 0.1.0
execution-mode: advisory
category: fleet-ops
status: candidate
---
# Operator Queue — Status

Read-only snapshot of the operator queue. No mutations.

## Queue file

`$HOME/_internal/operator-queue/queue.md`

## Behavior

1. Read queue.md
2. Surface state counts
3. Highlight time-sensitive items, in this priority order:
   - **TIME-GATE ELAPSED** (HIGHEST PRIORITY): GATED items whose date-bound gate-trigger timestamp has already passed relative to current session date. A passed time-gate is more urgent than an upcoming one because the item is no longer blocked — surface BEFORE the state-counts table. Only applies to gates with parseable timestamps in the `Gate` field (e.g., `~2026-05-19 00:43 UTC`); external-trigger gates without timestamps stay in the standard GATED WATCH bucket.
   - NOW (today-eligible)
   - SCHEDULED within 7 days
   - GATED with gate-trigger approaching (within 7 days if date-bound, or external-trigger description for non-date gates)
4. Flag stale items:
   - QUEUED >7 days untriaged
   - GATED >90 days without movement
   - CLARIFY-THEN-DELEGATE >14 days without operator answer
5. Suggest next action (typically `[operator-execute]` for top NOW item, OR `[operator-triage]` if QUEUED items present)

## Output format

```
[operator-status] | <date> <time>
══════════════════════════════════

▶ TIME-GATE ELAPSED (gates whose timestamp is in the past — items may be unblocked):
  - <slug>: gate was "<gate-description>"; elapsed ~<duration> ago; operator decision needed on whether to resume

QUEUE STATE (queue.md last modified <date>)

| State | Count | Notes |
|---|---|---|
| QUEUED | N | <stale flag if any >7d> |
| NOW | N | |
| SCHEDULED | N | next: <slug> on <date> |
| GATED | N | <approaching-trigger count if any; flag elapsed-gate count separately> |
| CLARIFY | N | <stale flag if any >14d> |
| DEFERRED | N | |

▶ TODAY-ELIGIBLE (NOW):
  - <slug> (~X min): <one-line summary>

▶ THIS WEEK SCHEDULED:
  - <slug> on <date>: <summary>

▶ GATED WATCH (approaching <7d):
  - <slug>: gate-trigger = <description>

▶ STALE FLAGS:
  - <slug> [QUEUED 12d]: needs triage
  - <slug> [CLARIFY 21d]: needs operator answer

▶ SUGGESTED NEXT:
  [operator-execute] <top-now-slug>
```

## When to use

- Quick "what's on my plate?" check
- After `[gm]` if morning kickoff suggested it
- Before deciding what to spend the next 30 min on
- Before `[end-session]` to confirm nothing critical was missed

## Constraints

- READ-ONLY: no mutations to queue.md
- If queue.md missing → suggest `[operator-queue] add <item>` to seed
- If queue.md has parse issues (malformed state summary) → flag for operator repair

## Related

- Playbook: `~/.agents/playbooks/operator-owned-work.md`
- Sister skills: `[operator-queue]`, `[operator-triage]`, `[operator-execute]`
- Auto-suggest hooks: `[gm]`, `[start-session]`, `[end-session]`
