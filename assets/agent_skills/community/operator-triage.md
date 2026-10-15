---
name: operator-triage
description: Walk operator through QUEUED items, assign state (NOW/SCHEDULED/GATED/CLARIFY/DEFERRED/DROPPED). Weekly cadence or on-demand. Playbook at ~/.agents/playbooks/operator-owned-work.md.
version: 0.1.0
execution-mode: side_effecting
argument-hint: "[all | queued-only | gated-revisit]"
category: fleet-ops
status: candidate
---
# Operator Queue — Triage

### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=operator-triage] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

Walks operator through items needing triage decisions. Updates the queue file in place.

## Queue file

`$HOME/_internal/operator-queue/queue.md`

## Modes

### `[operator-triage]` (default: queued-only)

Process all `QUEUED` items. For each:

1. **Read the item** to operator (summary + block type + surfaced date)
2. **Ask**: NOW / SCHEDULED / GATED / CLARIFY / DEFERRED / DROPPED?
3. **Follow-up by state**:
   - NOW → ask estimated minutes
   - SCHEDULED → ask date + duration
   - GATED → ask what unblocks
   - CLARIFY → ask the 1 question
   - DEFERRED → ask the revisit trigger
   - DROPPED → ask reason for receipt
4. **Update queue.md** in-place: new state + any new fields
5. **Move to next QUEUED item**

### `[operator-triage] all`

Same as default + revisit ALL non-terminal items (NOW, SCHEDULED, GATED, CLARIFY, DEFERRED). For each, ask: "still right state? still right slot/gate? want to update?"

### `[operator-triage] gated-revisit`

Only revisit GATED items >30 days old. Ask each: "still gated? gate moved? escalate to NOW/SCHEDULED, DEFER, or DROP?"

## Cadence (recommended)

- **Weekly**: `[operator-triage]` (queued-only) — typically Monday morning or after `[weekly-review]`
- **Monthly**: `[operator-triage] all` — fuller pass
- **Quarterly**: `[operator-triage] gated-revisit` — catch stale GATED

## Output

After triage:

```
[operator-triage] | <date>
══════════════════════════

Triaged: N items
  → NOW: <count>
  → SCHEDULED: <count>
  → GATED: <count>
  → CLARIFY: <count>
  → DEFERRED: <count>
  → DROPPED: <count>

NOW items added to today's plate:
  - <slug> (~X min)

Suggested next: [operator-execute] <highest-leverage-now-slug>
```

## Constraints

- Triage is operator-driven; do NOT auto-classify QUEUED items even if state seems obvious
- Capture decisions in queue.md immediately; don't batch
- If operator wants to defer the triage decision itself ("I'll come back to this one"), leave as QUEUED — that IS a valid triage outcome

## Related

- Playbook: `~/.agents/playbooks/operator-owned-work.md`
- Sister skills: `[operator-queue]`, `[operator-execute]`, `[operator-status]`

## Skill Chains

### Mandatory

None — triage workflow; operator-driven by definition.

### Advisory

- After triage completes → `[operator-execute]` for highest-leverage NOW item
- New items surface during triage → `[operator-queue] add` to capture them

## Authority

- **T1 (TRUSTED)**: May run (operator-guided)
- **T2 (Active/High)**: May run (operator-guided)
- **T3 (Medium)**: May run (operator-guided)
- **T4 (Probationary)**: May run (operator-guided — operator is in control)
- **Operator**: Override any restriction
