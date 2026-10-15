---
name: investor-update
description: Draft monthly investor/stakeholder update from metrics, milestones, and roadmap.
version: 0.1.0
execution-mode: side_effecting
argument-hint: "[monthly | weekly | custom \"PERIOD\"]"
category: sales-marketing
status: candidate
---
# Investor Update

Generate a structured update suitable for investors, advisors, or board members.

## Execution

### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=investor-update] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

### 1. Gather metrics
- Git: commits, PRs merged, contributors active in period
- Tests: current count, pass rate, coverage delta
- Bus: message volume, agent activity, incident count
- Cost: spend vs budget (from cost-governor)
- Infrastructure: uptime, service count, health probe results

### 2. Gather milestones
```bash
git log --oneline --since="30 days ago" | head -20
grep "MILESTONE" _state/coordination/messages.tsv | tail -10
```

### 3. Synthesize

## Output Format
```
your organization | Founder Update | <period>
══════════════════════════════════════

## Highlights
- <top 3 achievements, quantified>

## Product Progress
- <features shipped, integrations added, tests passing>

## Technical Metrics
| Metric | Last Month | This Month | Delta |
|--------|-----------|------------|-------|
| Tests | X | Y | +Z |
| Services | X | Y | +Z |
| Agents | X | Y | +Z |
| Uptime | X% | Y% | +Z% |

## Challenges & Risks
- <blockers, technical debt, resource constraints>

## Next Month
- <roadmap items, priorities, milestones targeted>

## Ask
- <what you need from investors/advisors>
```

## Tips
- Lead with outcomes, not activity
- Quantify everything possible
- Be honest about challenges -- investors respect transparency
- Keep it to 1 page (500 words max)

## Skill Chains

### Mandatory

- `[content-review]` MUST pass before sending the update externally to investors, advisors, or board members. The draft may be generated without it, but no external delivery without a passed content review.

### Advisory

- `[investor-update]` → `[send-email]` — deliver the update (requires `[content-review]` pass first)
- `[investor-update]` → `[financial-model]` or `[runway]` — pull current metrics before drafting
- `[investor-update]` → `[exec-summary]` — condense to a 1-pager if needed

## Authority

- **T1 (TRUSTED)**: Full run — draft and send (with `[content-review]` pass)
- **T2 (Active/High)**: Draft and send with `[content-review]` pass
- **T3 (Medium)**: Draft only; sending requires operator approval + `[content-review]` pass
- **T4 (Probationary)**: BLOCKED — may not draft or send investor updates
- **Operator**: Override any restriction
