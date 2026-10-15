---
name: cross-agent
description: Chief synthesis officer for multi-agent analysis. Use this after two or more agents, lanes, reviewers, or sub-agents have produced prompts, findings, or outputs that need cross-watching, contradiction mapping, evidence reconciliation, dialectical synthesis, or final human-facing synthesis; this is analytic synthesis, not a red/blue/purple wargame.
version: 0.1.0
execution-mode: advisory
argument-hint: "\"<mode>\" [agent prompts and outputs]"
category: security
status: candidate
---
# Cross Agent

## Purpose

Use this skill as the chief synthesis officer for a multi-agent run.

`cross-agent` receives the prompts, context packets, constraints, and outputs
from two or more agents and cross-watches them for chain integrity, blind spots,
contradictions, evidence gaps, role bleed, unsupported convergence, and
synthesis opportunities.

This skill is different from `[wargame]`, `[redteam]`, `[blueteam]`, and
`[purpleteam]`. Color-team skills simulate adversarial security, defense, or
resilience roles. `cross-agent` reconciles multi-agent analytical work products.

## When To Use

Use `cross-agent` when:

- A `[poly-agent]`, `[swarm]`, board, or sub-agent run has produced multiple
  lane outputs that need a final synthesis.
- A self-review uses multiple sub-agents and the Principal Agent needs a
  separate synthesis layer before reporting to the Human.
- The user asks one agent to "cross watch" other agents.
- The user provides prompts sent to multiple agents and wants synthesis across
  their outputs.
- The task needs dialectical, comparative, arbitration, consensus plus dissent,
  decision, root-cause, or meta-analysis across multiple agent views.

Use `[dialectical-analysis]` for the specific thesis -> antithesis -> synthesis
sequence. Use `cross-agent` as the broader synthesis officer that can consume a
dialectical chain or any other multi-agent analysis topology.

## Routing Boundaries

Use this routing split:

| User need | Prefer | Reason |
|-----------|--------|--------|
| Reconcile prompts and outputs from multiple agents | `[cross-agent]` | Preserves disagreements, evidence gaps, and synthesis opportunities |
| Run Thesis -> Antithesis -> Synthesis in order | `[dialectical-analysis]` | The topology is sequential and concept-development focused |
| Have several agents critique a proposal or artifact from different lenses | `[redline]` | The goal is adversarial review and critique, not synthesis governance |
| Run red -> blue -> purple security simulation with posture grade | `[wargame]` | The goal is adversarial security/resilience testing |
| Review Codex's own work | `[self-review]` | The goal is scoring execution quality; use cross-agent only after multiple review outputs exist |

`cross-agent` may synthesize, recommend, and identify required gates. It may
not canonize doctrine, approve promotion, waive review, decide authority, or
erase unresolved disagreement.

## Required Inputs

Before synthesizing, collect or reconstruct:

- Human objective and current decision question.
- Shared context packet and constraints.
- Agent roster, role of each agent, and topology if known.
- Prompt or assignment given to each agent.
- Output, status, and evidence from each agent.
- Requested synthesis mode: `dialectical`, `comparative`, `arbitration`,
  `consensus-dissent`, `decision`, `risk-register`, `root-cause`, or `meta`.
- Any required human approval, review, receipt, or promotion gate.

If an input is unavailable, mark it as `MISSING` instead of inventing it.

## Workflow

1. Reconstruct the chain of analysis.
   - Identify which agent saw which context.
   - Verify whether any downstream agent was supposed to read a prior output.
   - Preserve ordering for sequential chains such as dialectical analysis.

2. Build an agent-output matrix.
   - Agent or lane name.
   - Role or lens.
   - Prompt received.
   - Core claim.
   - Evidence cited.
   - Confidence.
   - Known limitations.

3. Cross-watch the outputs.
   - Contradictions: where agents disagree on facts, interpretation, risk, or
     recommendation.
   - Shared assumptions: premises all agents accepted without testing.
   - Unsupported convergence: agreement that lacks evidence.
   - Unsupported dissent: disagreement that lacks evidence.
   - Evidence gaps: claims that need source, command, file, receipt, or test
     backing.
   - Role bleed: agents acting outside their assigned lane.
   - Context insufficiency: agents missing material context.
   - Protocol drift: agents violating routing, approval, safety, or output
     constraints.

4. Preserve dissent before synthesis.
   - Do not flatten disagreement into premature consensus.
   - Keep minority reports when they identify real residual risk.
   - Mark unresolved contradictions explicitly.

5. Produce the Chief Synthesis Officer report.
   - Separate confirmed facts, contested interpretations, unresolved questions,
     and recommendation.
   - Identify the best next action and the required review or human decision
     gate.

## Output Format

```markdown
Cross-Agent Synthesis | <topic>

Inputs
- Objective:
- Mode:
- Agents reviewed:
- Shared evidence base:
- Missing inputs:

Chain Integrity
- Topology:
- Ordering:
- Context propagation:
- Protocol concerns:

Agent Matrix
| Agent | Role | Prompt Seen | Core Claim | Evidence | Confidence |
|---|---|---|---|---|---|
| <agent> | <role> | <summary> | <claim> | <evidence> | <level> |

Convergences
- <agreement that appears load-bearing>

Contradictions
- <disagreement, why it matters, what evidence would resolve it>

Blind Spots
- <shared assumption, missing evidence, or omitted stakeholder/risk>

Synthesis
- Confirmed:
- Contested:
- Unresolved:
- Recommendation:

Decision Gate
- Human approval required:
- Review required:
- Receipt or artifact required:
```

## Quality Rules

- Do not fabricate missing prompts, outputs, or evidence.
- Do not collapse the agent roster into one blended opinion before mapping
  disagreements.
- Do not call the final synthesis independent review if every sub-agent was
  controlled by the same session; label it as same-session synthesis unless the
  Human explicitly accepts it as a review waiver.
- Do not route to `[wargame]` or color-team skills unless the user asks for an
  adversarial/security exercise or the artifact is high-stakes enough to require
  that separate mode.
- Prefer concise synthesis over copying all agent outputs into the final answer.

## Lexicon

This skill uses the canonical swarm lexicon (`~/.agents/rules/swarm-lexicon.md`).
This skill is the authority for: chief synthesis officer, cross-watch,
chain integrity, role bleed, unsupported convergence, unsupported dissent,
protocol drift, minority reports. Conflicts between this skill's local
vernacular and the lexicon resolve in favor of the lexicon.

## Skill Chains

| After completing... | Consider... |
|---------------------|-------------|
| `[cross-agent]` with a resolved decision | `[decision-log]` or `[ledger]` if the result becomes durable |
| `[cross-agent]` with unresolved contradictions | `[uncertainty-map]` or another targeted agent lane |
| `[cross-agent]` on high-stakes security/governance claims | `[wargame]` only if adversarial stress testing is required |
| `[cross-agent]` after a complex run | `[aar]` to improve future multi-agent topology |
| independent synthesis inference | `[reasoning-router]` (`python ~/bin/reasoning_router.py route`) |
