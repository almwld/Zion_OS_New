---
name: identity-map
description: Map how identities shape system behavior -- agent roles, user personas, org context. Maps to P16.
version: 0.2.0
execution-mode: advisory
argument-hint: <system or organization to map>
category: dev-tools
status: candidate
---
# Identity Map (P16: Identity-Context Reciprocity)

Map how identities (agent, user, org) shape interpretations and how contexts reinforce those identities. Useful for understanding why agents behave differently in different contexts.

## When to Use
- Understanding why Gemini behaves differently than Codex (identity shapes output)
- Designing agent SOUL.md files (identity definition)
- Understanding why the same feature request means different things to different stakeholders
- Analyzing how org structure shapes technical decisions

## Execution

### 1. Enumerate identities in the system

| Identity | Role | Context | Behavior Shaped By |
|----------|------|---------|-------------------|
| Codex | Trusted engineering and critical-review peer | Operator-directed, task-specific routing and execution | AGENTS.md + `.agents/ROSTER.md` + guardrails |
| Devin | Supervised delegated runtime | ACTIVE-AIP retained scope | Operator or named task-coordinator assignment + Devin guardrail |
| Claude Code | On-demand specialist | Human-guided, quota-constrained named task | Claude Pro plan + Claude Code guardrail |
| Agy | On-demand GitOps specialist | Human-guided, quota-constrained named task | Google AI Pro plan + Agy guardrail |
| OpenCode | Routed runtime agent | Guardrail-bounded assigned work | AGENTS.md + `.agents/rules/` + runtime-specific docs |
| Gemini | Probationary agent | Restricted | Guardrails + audit history |
| Founder | CEO | Strategy + ops | Business goals + technical depth |
| Technical co-founder | Technical partner | Infrastructure + code | Engineering standards |

### 2. Map identity-context feedback loops

```
Agent identity (SOUL.md) -> shapes how agent interprets tasks
  -> produces outputs with characteristic style
  -> outputs reinforce reputation (trust score)
  -> reputation shapes future task assignment
  -> task assignment reinforces identity
```

### 3. Find identity conflicts
Where does the same entity have conflicting identities?
- Stale Claude Code "autonomous/default agent" descriptions vs its current
  on-demand, quota-constrained specialist role
- Stale Devin primary/default descriptions vs its current supervised AIP role
- User as "founder" (move fast) vs "security engineer" (be careful)
- remote-node as "co-founder's computer" vs "shared server"

### 4. Design for identity awareness
- Agent SOUL.md files should acknowledge the identity they're creating
- Guardrails should account for identity-driven blind spots
- Multi-agent coordination should expect identity-shaped disagreements

## Output Format
```
Identity Map | <system>
═════════════════════════

## Identities
<identity table>

## Feedback Loops
<how identities reinforce themselves>

## Conflicts
<where identities clash>

## Design Implications
<how to account for identity effects in system design>
```

## Base120 Context
- Primary: **P16** (Identity-Context Reciprocity)
- Related: **P3** (Identity Stack), **P11** (Role Perspective-Taking), **SY13** (Incentive Architecture)
