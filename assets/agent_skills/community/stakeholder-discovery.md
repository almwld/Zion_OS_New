---
name: stakeholder-discovery
description: >
  Discover all stakeholders in a decision, project, or system — who has
  authority, who is affected, who needs to be consulted or informed. Produces
  a stakeholder register, power/interest grid, and RACI matrix. Composes crm,
  deal-memo stakeholder map, knowledge-map, board-meeting-orchestrator,
  escalation-policy, and incentive-design. Operationalizes Base120 P2
  (Stakeholder Mapping). Invoke when an agent says "who are the stakeholders",
  "stakeholder analysis", "who is involved", "stakeholder map", "RACI",
  "power interest grid", or before decisions that affect multiple parties.
version: 0.1.0
execution-mode: advisory
argument-hint: "<decision, project, or system> [optional: --register | --analyze | --engage | --monitor]"
category: fleet-ops
status: candidate
---

# Stakeholder-Discovery

Discover all stakeholders in a decision, project, or system. This is the
lateral-facing complement to `[self-discovery]`: self-discovery answers "what
am I?" while stakeholder-discovery answers "who else is involved and who
matters?"

This skill operationalizes Base120 P2 (Stakeholder Mapping — Identify all
interested parties) as a structured procedure.

## Why Stakeholder-Discovery Matters

Agents that don't know their stakeholders make avoidable mistakes:

- An agent makes a decision that affects someone who wasn't consulted
- An agent communicates to the wrong audience in the wrong register
- An agent misses a blocker who has veto power
- An agent over-communicates to low-interest parties and under-communicates to
  high-power ones
- An agent doesn't know who the champion is and fails to leverage them
- An agent doesn't know the escalation chain when something goes wrong

Stakeholder-discovery is not bureaucracy — it is decision calibration. Know
who matters before you act.

## The Discovery Procedure

Follow these 5 phases in order. Each phase has probe commands and reflection
questions.

### Phase 1: Stakeholder Discovery (Who are they?)

**What to discover:** All parties with an interest in the decision, project, or
system.

**Probe commands:**

```
[crm] view  (existing contacts related to the topic)
[crm] search "<topic or project name>"
[meeting-capture]  (recent meeting participants — check _state/meetings/)
[knowledge-map]  (who knows what about this topic)
[onboard-client]  (if new client — kickoff stakeholder identification)
```

**Reflection questions:**
- Who is the operator? (Always the primary stakeholder — Tier 0)
- Who is the economic buyer? (Who controls budget)
- Who is the primary contact? (Day-to-day interface)
- Who is the champion? (Internal advocate)
- Who are the influencers? (People whose opinion matters)
- Who are the blockers? (People who can stop the decision)
- Who is affected but not in the room? (End-users, downstream teams)
- Who has expertise relevant to this decision? (knowledge-map)
- Who has been in meetings about this topic? (meeting-capture)

**Record:** `stakeholder_register: [{ name, role, organization, relationship_type, contact_info, knowledge_areas, source: crm|meeting|knowledge-map|inferred }]`

### Phase 2: Stakeholder Analysis (Power, Interest, Influence)

**What to discover:** Each stakeholder's power, interest, influence, and
involvement level.

**Probe commands:**

```
[deal-memo]  (if deal-related — extract STAKEHOLDER MAP section)
[icp-profile] "<stakeholder organization>"  (if external party)
[escalation-policy]  (authority chains — who to contact, when, how)
[incentive-design]  (actor mapping — what motivates each stakeholder)
```

**For each stakeholder, assess:**

| Dimension | Source | Question |
|-----------|--------|----------|
| Power | deal-memo, escalation-policy | Can they make or break this decision? |
| Interest | CRM interaction frequency, meeting attendance | How much do they care? |
| Influence | knowledge-map (bus factor), incentive-design | Can they sway others? |
| Legitimacy | governance-maturity People domain | Do they have formal authority? |
| Urgency | escalation-policy severity | Do they need to be involved now? |

**Plot on Power/Interest Grid (Mendelow's Matrix):**

```
                    HIGH INTEREST
                         |
     KEEP INFORMED       |    MANAGE CLOSELY
     (low power,         |    (high power,
      high interest)     |     high interest)
                         |
  ──────── LOW ─────────┼──────── HIGH ──────── POWER
  POWER                  |              POWER
                         |
     MONITOR             |    KEEP SATISFIED
     (low power,         |    (high power,
      low interest)      |     low interest)
                         |
                    LOW INTEREST
```

**Assign RACI roles:**

| Role | Meaning |
|------|---------|
| R — Responsible | Does the work |
| A — Accountable | Owns the outcome (one person) |
| C — Consulted | Provides input before decision |
| I — Informed | Notified after decision |

**Record:** `stakeholder_analysis: { power_interest_grid: { manage_closely: [...], keep_satisfied: [...], keep_informed: [...], monitor: [...] }, raci: [{ stakeholder, role: R|A|C|I, task: ... }], influence_map: [...] }`

### Phase 3: Engagement Planning

**What to discover:** How to manage each stakeholder category.

**Probe commands:**

```
[stakeholder-update]  (for "Manage Closely" stakeholders)
[async-update]  (for "Keep Satisfied" stakeholders)
[internal-comms]  (for "Keep Informed" stakeholders)
[weekly-digest]  (for "Monitor" stakeholders)
```

**Engagement strategy by category:**

| Category | Strategy | Skills |
|----------|----------|--------|
| Manage Closely | Formal updates, structured meetings, board participation | stakeholder-update, meeting-prep, board-meeting-orchestrator |
| Keep Satisfied | Lightweight pings, periodic briefings | async-update, exec-summary, one-pager |
| Keep Informed | Newsletters, operational summaries | internal-comms, weekly-digest |
| Monitor | Passive monitoring, stale detection | crm stale, churn-analysis |
| At-Risk | Re-engagement, escalation | follow-up, escalation-policy |
| New Acquisition | Outreach, discovery, intake | outreach-strategy, discovery-call, lead-intake |

**Record:** `engagement_plan: [{ stakeholder, category, strategy, frequency, channel, skill_chain: [...] }]`

### Phase 4: Ongoing Monitoring

**What to discover:** Stakeholder health and relationship changes over time.

**Probe commands:**

```
[engagement-tracker]  (relationship health scoring)
[churn-analysis]  (early warning detection)
[meeting-capture]  (ongoing meeting participant tracking)
[decision-log]  (decision provenance — who decided what)
```

**Reflection questions:**
- Has any stakeholder's engagement health changed?
- Are there churn signals from key stakeholders?
- Have meeting participants changed? (New stakeholders appearing, old ones
  disappearing)
- Are decisions being made by the expected stakeholders?
- Has any champion departed or changed role?

**Record:** `monitoring: { health_scores: [...], churn_signals: [...], participant_changes: [...], decision_patterns: [...] }`

### Phase 5: Governance Integration

**What to discover:** How stakeholder analysis connects to governance
structures.

**Probe commands:**

```
[board-meeting-orchestrator]  (if high-stakes — structured deliberation)
[governance-maturity]  (People domain assessment)
[succession-mode]  (authority continuity)
[risk-register]  (risk ownership — who owns what risk)
```

**Reflection questions:**
- Should this decision go through the board-meeting-orchestrator?
- What governance maturity level does the stakeholder structure imply?
- Are there succession risks for key stakeholders?
- Who owns the risks associated with this decision?
- Are escalation chains clear and current?

**Record:** `governance: { board_warranted: true|false, maturity_level: ..., succession_risks: [...], risk_owners: [...] }`

## Producing the Stakeholder Profile

### Stakeholder Profile (human-readable)

```markdown
# Stakeholder Profile

## Stakeholder Register
| Name | Role | Organization | Relationship | Knowledge Areas |
|------|------|-------------|--------------|-----------------|
| ... | ... | ... | ... | ... |

## Power/Interest Grid
- Manage Closely: [stakeholders]
- Keep Satisfied: [stakeholders]
- Keep Informed: [stakeholders]
- Monitor: [stakeholders]

## RACI Matrix
| Task | R | A | C | I |
|------|---|---|---|---|
| ... | ... | ... | ... | ... |

## Influence Map
- [who influences whom, formal vs informal channels]

## Engagement Plan
| Stakeholder | Category | Strategy | Frequency | Channel |
|-------------|----------|----------|-----------|---------|
| ... | ... | ... | ... | ... |

## Governance
- Board deliberation warranted: [yes/no]
- Succession risks: [list]
- Risk owners: [list]

## What This Agent Should Know
- [3-5 actionable insights for managing these stakeholders]
```

### Stakeholder Profile (bus summary)

```
STAKEHOLDER_PROFILE: project=<project> stakeholders=<N> manage_closely=<N> keep_satisfied=<N> keep_informed=<N> monitor=<N> board_warranted=<yes|no> intel_type=TOPOINT
```

### Stakeholder Profile (ledger persistence)

```
[ledger] post --type stakeholder-profile --tags stakeholder,discovery,p2,raci --content "<profile JSON>"
```

## When to Re-Run Stakeholder-Discovery

- **Before major decisions**: Identify who needs to be consulted
- **Project kickoff**: Establish the full stakeholder map
- **Quarterly**: Refresh power/interest assessments
- **After stakeholder changes**: Champion departure, decision-maker change,
  new participant
- **After organizational change**: Restructuring, merger, leadership change
- **When asked**: "Who are the stakeholders?" / "Who should I consult?"

## Argument Modes

- `[stakeholder-discovery] "<project>"` — Full 5-phase procedure (default)
- `[stakeholder-discovery] "<project>" --register` — Phase 1 only (stakeholder
  identification)
- `[stakeholder-discovery] "<project>" --analyze` — Phase 2 only (power/interest
  + RACI, requires existing register)
- `[stakeholder-discovery] "<project>" --engage` — Phase 3 only (engagement
  planning, requires existing analysis)
- `[stakeholder-discovery] "<project>" --monitor` — Phase 4 only (health
  monitoring, requires existing engagement plan)

## Composition Chain

- `[self-discovery]` → `[stakeholder-discovery]` — Know yourself before you
  map others
- `[stakeholder-discovery]` → `[stakeholder-update]` — Engagement plan drives
  communication
- `[stakeholder-discovery]` → `[board-meeting-orchestrator]` — Stakeholder
  analysis determines if board deliberation is warranted
- `[stakeholder-discovery]` → `[risk-register]` — Stakeholder analysis
  identifies risk owners
- `[stakeholder-discovery]` → `[decision-log]` — RACI assignments are recorded
  with decisions

## Anti-Patterns

- **Don't assume stakeholders are known**: The biggest risk is the stakeholder
  you didn't identify. Run Phase 1 systematically.
- **Don't skip the power/interest grid**: Categorizing stakeholders changes
  how you communicate with each one.
- **Don't forget the absent stakeholders**: End-users and downstream teams are
  often affected but not in the room. Identify them.
- **Don't confuse influence and authority**: The person with the title isn't
  always the person with the influence. Check the knowledge-map for informal
  influence.
- **Don't make it static**: Stakeholder maps decay. Champions leave. Decision-
  makers change. Re-run periodically.

## Known Limitations

- No dedicated stakeholder-relationship-mapping skill exists (who reports to
  whom, who influences whom). Influence is inferred from knowledge-map and
  meeting patterns.
- No stakeholder-salience-model skill exists (Mitchell's Power + Legitimacy +
  Urgency). The power/interest grid is a simpler approximation.
- No stakeholder-communication-plan skill exists as a standalone. Engagement
  planning is composed from existing communication skills.
- CRM data may be incomplete or stale. Use `[crm] stale` to identify contacts
  needing refresh.

## After This Skill Runs

- `[stakeholder-update]` — Execute engagement plan for high-priority
  stakeholders
- `[board-meeting-orchestrator]` — If governance deliberation is warranted
- `[risk-register]` — Assign risk owners based on stakeholder analysis
- `[decision-log]` — Record RACI assignments with decisions
- `[empathy-map]` — Deepen understanding of key stakeholders' experience
