---
name: incentive-design
description: Design reward structures that align individual agent/user actions with system goals. Maps to SY13.
version: 0.1.0
execution-mode: advisory
argument-hint: "\"SYSTEM or FEATURE to design incentives for\""
category: fleet-ops
status: candidate
---
# Incentive Design (SY13: Incentive Architecture)

Design reward, penalty, and feedback structures that align behavior with desired outcomes -- for agents, users, or markets.

## When to Use
- Designing GaaS pricing tiers
- Setting agent trust/probation rules
- Designing contributor incentives for open-source
- Aligning cost-governor budget thresholds with team behavior
- Any system where actors have choices and you want to shape which choices they make

## Execution

### 1. Map the actors
Who has agency in this system?
- Human operators (team members)
- AI agents (Claude, Codex, Gemini)
- External users (future GaaS customers)
- Automated processes (briefing pipeline, consolidator)

### 2. Map desired behaviors
For each actor, what do you WANT them to do?

| Actor | Desired Behavior | Current Incentive | Gap |
|-------|-----------------|-------------------|-----|
| Agent | Stay within scope | Guardrails (negative) | No positive incentive |
| Agent | Write tests | TDD skill exists | No enforcement |
| User | Report bugs | GitHub issues | No reward |

### 3. Identify misaligned incentives
Where do current incentives encourage WRONG behavior?
- Agents rewarded for volume (bus messages) not quality?
- Cost budget encourages hoarding rather than efficient use?
- Agent trust score never improves (no path from PROBATION to TRUSTED)?

### 4. Design the mechanism
For each gap, choose an incentive type:

| Type | Mechanism | Example |
|------|-----------|---------|
| **Positive reward** | Grant capability/trust on good behavior | Agent trust score increases after N verified commits |
| **Negative penalty** | Restrict on bad behavior | PROBATION on guardrail violation |
| **Social** | Visibility/recognition | Bus MILESTONE posts, AAR mentions |
| **Economic** | Cost/budget impact | Cost-governor budget allocation per agent |
| **Structural** | Architecture shapes behavior | Circuit breakers make failures visible |
| **Information** | Transparency shapes choices | Health dashboard makes status public |

### 5. Check for perverse incentives
- Does this incentive create gaming opportunities?
- Does it punish risk-taking that should be encouraged?
- Does it create a race to the bottom on quality?
- Does it advantage incumbents over newcomers?

## Output Format
```
Incentive Design | <system>
══════════════════════════════

## Actor Map
<who has agency>

## Current Incentives
<what behaviors are currently rewarded/punished>

## Misalignments
<where incentives drive wrong behavior>

## Proposed Design
| Behavior | Incentive | Mechanism | Metric |
|----------|-----------|-----------|--------|

## Perverse Incentive Check
<potential gaming or unintended consequences>

## Implementation
<specific code/config changes to enact the design>
```

## Base120 Context
- Primary: **SY13** (Incentive Architecture)
- Related: **SY11** (Governance Patterns), **RE2** (Feedback Loops), **SY17** (Policy Feedbacks)
