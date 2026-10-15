---
name: pipeline-review
description: Full sales funnel snapshot. Stage counts, conversion rates, stale contacts, action items. Weekly rhythm. Different from /follow-up (per-contact) -- this is the whole funnel.
version: 1.0.0
execution-mode: side_effecting
argument-hint: "[weekly | deep | stage STAGE_NAME]"
category: fleet-ops
status: tested
providers:
  required: [bash, python]
---
## Context Gathering

Before executing this skill, gather the following context:
- **Outreach files**: Run `ls ~/.agents/_internal/outreach/ 2>/dev/null | head -10 || echo "(no outreach dir)"`

# [pipeline-review]

> The funnel doesn't manage itself. This is the weekly read on whether the machine is running.

Full-funnel view of the HUMMBL sales pipeline. Not individual contact follow-ups (that's `[follow-up]`) — this is the aggregate health of the business development effort.

**Weekly rhythm: run Monday with `[weekly-plan]`, or any time the pipeline feels stale.**

## Funnel Stages

```
PROSPECT → CONTACTED → RESPONDED → DEMO/CALL → PROPOSAL → CLOSE
```

## Execution

### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=pipeline-review] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

### 1. Load pipeline data

```bash
# Wave 1 draft status
cat ~/.agents/_internal/outreach/wave1-drafts.md 2>/dev/null

# Send checklist
cat ~/.agents/_internal/outreach/wave1-send-checklist.md 2>/dev/null || \
cat ~/.agents/_internal/outreach/tuesday-send-checklist.md 2>/dev/null

# People files with prospect context (resolve runtime memory dir)
eval "$("$HOME/.agents/scripts/resolve-memory.sh")"
ls ${RUNTIME_MEM:+$RUNTIME_MEM/people_*.md} 2>/dev/null | while read f; do
    echo "=== $f ==="; grep -E "status|prospect|lead|contacted|demo|proposal|close|responded" "$f" -i | head -5
done

# CRM if exists
cat ~/.agents/_internal/crm/*.md 2>/dev/null | head -50
```

### 2. Build funnel snapshot

For each known prospect/contact, determine current stage:

| Stage | Count | Names | Avg days in stage |
|-------|-------|-------|------------------|
| Prospect (identified, not contacted) | | | |
| Contacted (email/message sent) | | | |
| Responded (any reply) | | | |
| Demo/Call (scheduled or completed) | | | |
| Proposal (SOW/proposal sent) | | | |
| Close (signed/contracted) | | | |

### 3. Identify stuck contacts

Any contact in the same stage for > 7 days needs an action:
- **No response after email**: LinkedIn view + follow-up
- **Responded but no demo scheduled**: send cal.com link
- **Demo completed but no proposal**: draft proposal
- **Proposal sent but no response > 5 days**: gentle nudge

### 4. Conversion math

```
Contact → Response rate: responded / contacted × 100
Response → Demo rate: demo / responded × 100
Demo → Proposal rate: proposal / demo × 100
```

Track these weekly. If response rate < 20%, the email copy needs work. If demo → proposal < 50%, the discovery call needs work.

### 5. Next week's pipeline actions

Output a prioritized list of pipeline actions for the week — feeds directly into `[weekly-plan]`.

## Output Format

```
Pipeline Review | <date>
═══════════════════════

## Funnel Snapshot
PROSPECT:  N  [names]
CONTACTED: N  [names — days since contact]
RESPONDED: N  [names]
DEMO:      N  [names — scheduled/completed]
PROPOSAL:  N  [names]
CLOSE:     N  [names]

## Conversion Rates
Contact → Response: N%  (target: >25%)
Response → Demo:    N%  (target: >50%)
Demo → Proposal:    N%  (target: >75%)

## Stuck Contacts (> 7 days in stage)
- [Name]: [stage] for [N] days — action: [specific next step]

## This Week's Pipeline Actions (prioritized)
1. [highest-value action]
2. [second action]
3. ...

## Pipeline Health
<GREEN: machine running> | <YELLOW: 1-2 stuck> | <RED: nothing moving>
```

## Chain
- Stuck contacts → `[follow-up]` for individual drafts
- Empty pipeline → `[outreach-strategy]` to design next wave
- After review → update `[weekly-plan]` pipeline commitment section
- Monthly → include in `[investor-update]` as pipeline section

## Skill Chains

### Mandatory

None — read-only CRM analysis; no state mutation.

### Advisory

- Stuck contacts → `[follow-up]` for individual drafts
- Empty pipeline → `[outreach-strategy]` to design next wave
- After review → update `[weekly-plan]` pipeline commitment section
- Monthly → include in `[investor-update]` as pipeline section

## Authority

- **T1 (TRUSTED)**: May run
- **T2 (Active/High)**: May run
- **T3 (Medium)**: May run
- **T4 (Probationary)**: May run (read-only)
- **Operator**: Override any restriction
