---
name: operator-queue
description: Add to or list the operator-owned work queue. Items the agent is structurally blocked from doing (authority/access/judgment/interface). Auto-loaded by /gm, /start-session, /end-session. Playbook at ~/.agents/playbooks/operator-owned-work.md.
version: 0.1.0
execution-mode: side_effecting
argument-hint: "[add <description> | list]"
category: fleet-ops
status: candidate
---
# Operator Queue — Add or List

### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=operator-queue] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

## Queue file

`$HOME/_internal/operator-queue/queue.md`

## Behavior

### `[operator-queue]` (no args, or `list`)

Read the queue file. Show:
1. State summary table (counts per state)
2. NOW items (full detail)
3. SCHEDULED items due within 7 days (full detail)
4. GATED items with gate-trigger description (one line each)
5. Anything else summarized as one line

Default: tight read, no full-text dump of all items. Operator can `[operator-status]` for snapshot or `[operator-triage]` for deep pass.

### `[operator-queue] add <description>`

Append a new item to the queue. If $ARGUMENTS contains item description:

1. Auto-generate slug from description (kebab-case, ≤40 chars)
2. Prompt operator (or infer from chat context) for required fields:
   - Block type (Authority / Access / Judgment / Interface — multiple OK)
   - Summary (1 sentence)
   - Initial state (default: QUEUED for operator to triage; or NOW/SCHEDULED/GATED if obvious)
   - Owner (default: operator)
   - Depends-on (other slugs; default: none)
3. Append item block to queue.md per the existing format
4. Update state summary table at top

If $ARGUMENTS empty, prompt operator: "What's the item? Block type? Initial state guess?"

### Agent-side `[operator-queue] add`

When an agent (claude-code, codex, hermes) hits a structural block during work:

1. Recognize the block class per playbook 4 types
2. Surface in bus STATUS / chat that this is being queued
3. Invoke `[operator-queue] add` with all fields pre-filled
4. Continue work where possible; defer to queue what's blocked

## Output format

```
[operator-queue] | <date>
═══════════════════════════

State: QUEUED 0 | NOW 1 | SCHEDULED 1 | GATED 3 | CLARIFY 1 | DEFERRED 0

▶ NOW (today-eligible):
  - openrouter-workspace-attribution (~5 min) — verify per-workspace cost in OpenRouter dashboard

▶ This week SCHEDULED:
  (none — next is quarterly-competence-review-2026-08-17)

▶ GATED watch:
  - g2-counsel-review — finding counsel
  - hermes-optimization-continuation — quota reset ~2026-05-19 00:43 UTC
  - bar-status-hummbl-legal-paralegal — counsel call OR solo decision

▶ CLARIFY:
  - ga-bar-gai-research — needs bar-status answer
```

## When to skip / when to ask

- **Skip queue add** for tasks agent CAN do that are just deferred ("I'll get to it next session" is not operator-owned)
- **Always queue** structural blocks per playbook 4 types
- **Ask first** if uncertain whether item is operator-owned vs delegable

## Constraints

- Queue file is operator-local; never propagate to bus or PROJECTS/ repos
- Append-only by convention (in-place state updates OK; deletions discouraged — use DROPPED state instead)
- Slug must be unique within the queue; if collision, append `-2`, `-3`, etc.

## Related

- Playbook: `~/.agents/playbooks/operator-owned-work.md`
- Sister skills: `[operator-triage]`, `[operator-execute]`, `[operator-status]`
- Auto-load hooks: `[gm]`, `[start-session]`, `[end-session]`, `[weekly-review]`

## Skill Chains

### Mandatory

None — queue management; local state only.

### Advisory

- After adding items → `[operator-triage]` to assign states
- Ready to execute a NOW item → `[operator-execute]` to walk through it
- Session start/end → auto-loaded by `[gm]`, `[start-session]`, `[end-session]`

## Authority

- **T1 (TRUSTED)**: May run
- **T2 (Active/High)**: May run
- **T3 (Medium)**: May run
- **T4 (Probationary)**: May run (queue is advisory — operator decides)
- **Operator**: Override any restriction
