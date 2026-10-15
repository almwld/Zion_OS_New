---
name: founder-check
description: 'Am I doing founder work? 5-question diagnostic. Revenue-moving, building vs maintaining, customer contact, agents unblocked, energy. Score 1-3 each. Flags infrastructure loop.'
version: 1.0.0
execution-mode: advisory
argument-hint: "[quick | weekly]"
category: dev-tools
status: candidate
---
# [founder-check]

> The system has health checks. So does the operator.

Zero health checks exist for the founder — only for the machines and agents. This fills that gap. Five questions, honest answers, one recommended action.

**Run:** any time you feel busy but not productive; Monday mornings as part of weekly rhythm; whenever the infrastructure loop has captured your attention for > 2 days.

## The 5 Questions

Score each **1–3**:
- 1 = No / bad
- 2 = Partially / okay
- 3 = Yes / good

---

**Q1: Is today's primary work moving toward revenue?**
- 3: Working on something a paying client would directly value (product, outreach, pitch)
- 2: Enabling work (infrastructure that makes revenue work faster/better)
- 1: Meta-enabling work (infrastructure for the infrastructure)

*The trap: building the agent system that will automate the outreach that will enable the pipeline. You've got 3 levels of indirection from money.*

---

**Q2: Am I building new things or maintaining existing ones?**
- 3: New product capability, new customer relationship, new insight
- 2: Improving existing things that customers/prospects would notice
- 1: Maintenance, debugging, keeping lights on, refactoring

*The trap: 80% of time in ops mode feels like work but isn't founder work.*

---

**Q3: When did I last have a substantive conversation with a customer or prospect?**
- 3: This week
- 2: Last week
- 1: More than 2 weeks ago

*The trap: building a product you've stopped asking customers about. The last conversation was Apr 7 (meeting capture). If it's been more than 7 days, that's a flag.*

---

**Q4: Are my agents and systems operating without needing me?**
- 3: Agents running, CI green, no fires — I'm freed up for founder work
- 2: Some things need attention but nothing blocking
- 1: I'm in operator mode — fixing, debugging, watching, managing

*The trap: agents are supposed to free you up. If you're spending > 2h/day on agent ops, the system is working on you, not for you.*

---

**Q5: What's my energy level right now?**
- 3: High — ideas coming, execution feels clean, motivated
- 2: Medium — functional but not generative
- 1: Low — going through motions, decisions feel hard

*Energy is information. 1 doesn't mean stop — it means change what you're working on, not how hard you're working.*

---

## Scoring

| Score | Interpretation |
|-------|---------------|
| 13–15 | Founder mode — stay the course |
| 10–12 | Mostly on track — one thing to adjust |
| 7–9 | Slipping — flag the specific Q that scored 1 |
| < 7 | Operator mode — stop and reorient before next action |

## Recommended Actions by Failing Question

| Q | Score 1 Action |
|---|---------------|
| Q1 | Open pipeline-review; do one revenue-touching action before anything else |
| Q2 | Check sprint intent: is the goal a new thing or maintenance? |
| Q3 | Schedule a coffee chat or send one follow-up email right now |
| Q4 | Run [sitrep] — identify one agent task to offload |
| Q5 | Take a break, change environment, or run [reframe] on current work |

## Output Format

```
Founder Check | <date> <time>
═══════════════════════════════

Q1 Revenue-moving:     [1/2/3] — <one-line note>
Q2 Building vs maint:  [1/2/3] — <one-line note>
Q3 Customer contact:   [1/2/3] — last contact: <date>
Q4 Agents operating:   [1/2/3] — <one-line note>
Q5 Energy:             [1/2/3] — <one-line note>

TOTAL: [N]/15

## Assessment
[FOUNDER MODE / ON TRACK / SLIPPING / OPERATOR MODE]

## The One Action
<specific thing to do right now to get back to founder mode>
```

## Chain
- Score < 7 → `[reframe]` current work before continuing
- Q3 = 1 → `[pipeline-review]` then `[follow-up]`
- Q4 = 1 → `[sitrep]` to find what to offload to agents
- Q5 = 1 → `[focus-block]` with a different type of task
- Run weekly → log to `[ledger]` with tag `founder-health` to track trend
