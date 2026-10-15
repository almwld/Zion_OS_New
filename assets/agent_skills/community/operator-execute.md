---
name: operator-execute
description: Walk operator through executing one specific operator-owned item (NOW or SCHEDULED). Capture receipt when DONE. Playbook at ~/.agents/playbooks/operator-owned-work.md.
version: 0.1.0
execution-mode: side_effecting
argument-hint: <slug>
category: fleet-ops
status: candidate
---
# Operator Queue — Execute

### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=operator-execute] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

Opens a specific item from the operator queue and walks operator through completing it. Captures DONE receipt automatically.

## Queue file

`$HOME/_internal/operator-queue/queue.md`

## Behavior

### `[operator-execute] <slug>`

1. **Find item** by slug in queue.md. If not found → list closest matches.
2. **Check state**:
   - NOW or SCHEDULED → proceed
   - GATED → check if gate has cleared; if yes, proceed; if no, surface gate status + ask if operator wants to override
   - CLARIFY-THEN-DELEGATE → process the clarification then continue as a normal agent task
   - DEFERRED / DONE / DROPPED → ask operator if they want to re-open + change state
3. **Walk through steps**:
   - If item has explicit Steps section in queue.md, follow them
   - Otherwise, infer from Summary + Block type
   - Surface any prep needed (open dashboard, find document, schedule slot)
   - Execute the operator-facing steps
   - Capture intermediate state for receipt
4. **Capture receipt**: ask operator for closing artifact (path / decision / bus post / "no artifact, just done")
5. **Update queue.md**: state → DONE, append receipt to item's Receipt field
6. **Suggest next**: based on remaining NOW items, propose `[operator-execute] <next>` OR end-session

## Receipt schema

Every DONE item gets a receipt line. Format:

```
- **Receipt**: <date> — <closing artifact OR decision summary>; <link to artifact path OR bus post OR "no artifact, operator self-confirmed">
```

## Examples

### `[operator-execute] openrouter-workspace-attribution`

1. Item state: NOW, 5 min slot
2. Open https://openrouter.ai/activity in browser
3. Walk operator through: switch view to per-workspace costs, find legal-class workspace
4. Operator reports: "yes, all 4 test calls attributed to legal-class workspace, $0.61 total"
5. Capture receipt: "2026-05-17 — verified legal-class workspace correctly receiving costs from 2026-05-17 18:26-18:28 OpenCode test calls; $0.61 total; OpenRouter Activity dashboard"
6. Update queue.md: state → DONE
7. Suggest next: `[operator-execute] hermes-optimization-continuation` if quota reset, else next NOW item

### `[operator-execute] g2-counsel-review` (GATED)

1. Check gate: "Finding/scheduling legal counsel — has this moved?"
2. If yes (counsel scheduled): walk through prep — what to send counsel, what to ask, expected response time
3. If no: surface gate status; ask if operator wants to take a gate-clearing action now (e.g., open call to GA bar referral, ask Travis Morrison for referral, etc.)
4. Either way: capture progress in queue.md (don't transition to DONE until counsel review actually happens)

## When to skip

- Item is GATED with no movement and operator doesn't want to act on gate
- Operator just wants to read item, not execute → use `[operator-queue]` or `[operator-status]` instead

## Constraints

- Only one `[operator-execute]` should run at a time per item
- Receipt is REQUIRED on DONE transition — if operator can't articulate what closed it, the item isn't actually done; leave in current state
- Don't auto-execute multi-step external work (e.g., counsel calls) — walk operator through it; operator does the external interaction

## Related

- Playbook: `~/.agents/playbooks/operator-owned-work.md`
- Sister skills: `[operator-queue]`, `[operator-triage]`, `[operator-status]`
- Item-specific receipt patterns may emerge over time — capture in playbook anti-patterns section

## Skill Chains

### Mandatory

None — operator workflow; operator-driven by definition.

### Advisory

- After completing an item → `[operator-queue]` to check remaining items
- Item needs re-prioritization → `[operator-triage]` to reassign state

## Authority

- **T1 (TRUSTED)**: May run (operator-guided)
- **T2 (Active/High)**: May run (operator-guided)
- **T3 (Medium)**: May run (operator-guided)
- **T4 (Probationary)**: May run (operator-guided — operator is in control)
- **Operator**: Override any restriction
