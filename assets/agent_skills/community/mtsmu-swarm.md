---
name: mtsmu-swarm
description: Swarm-style coordination for high-rigor implementation, debugging, review, and operations work. Use when the task benefits from lane decomposition, coordination-bus receipts, explicit handoffs, progress telemetry, or cross-agent work allocation without losing auditability.
version: 0.1.0
execution-mode: side_effecting
argument-hint: <decomposable task for parallel execution>
category: dev-tools
status: candidate
---
# MTSMU Swarm

### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=mtsmu-swarm] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

## Quick Start

- Split work into 1-3 lanes with clear scope boundaries.
- Choose lanes that can be verified independently.
- Post a kickoff when starting material work and a receipt when a lane lands.
- Keep the bus concise: decision, scope, verification, blocker.
- Prefer fewer strong lanes over many vague ones.

## Lane Design

Use lanes like these:

- `debug lane`: reproduce, isolate, patch, verify
- `telemetry lane`: measure, validate, harden signals
- `review lane`: inspect risk, regressions, missing tests
- `skill lane`: encode the repeated workflow into a reusable skill

Each lane should have: one objective, one main artifact or code surface, one verification path, one clear done condition.

## Coordination Workflow

1. Read current bus state and local repo state.
2. Propose lane split with priorities.
3. Start the highest-value lane first.
4. Post concise `STATUS`, `ACK`, `BLOCKED`, or `MILESTONE` messages when they add real coordination value.
5. Merge lane outcomes into one coherent result with explicit residual risk.

## Handoff Rules

- Handoffs must include current state, exact blocker or next action, and the verification already completed.
- Do not hand off vague intentions.
- If a lane is blocked by missing credentials, external infra, or conflicting local changes, say that directly.
- If a lane is complete, post the receipt before starting another lane.

## Output Contract

Use this compact shape:

- `Lane plan`
- `Active lane`
- `Receipts`
- `Blockers`
- `Next lane`

## Swarm Patterns

Good lane splits: separate product code from telemetry code, separate bug fix from regression-test work when the test path is non-trivial, separate coordination/admin work from implementation, separate high-confidence local work from external-dependency work.

Bad lane splits: two lanes editing the same function without a merge plan, a lane that only says "investigate", a lane with no verification target, too many lanes for the actual work.

Good receipts: what changed, what verified it, what remains uncertain. Avoid generic progress chatter, repeating earlier status without new evidence, long narrative when one line would do.

Merge discipline: finish or park one lane cleanly before switching if work overlaps, restate merge assumptions before editing shared surfaces, reduce parallelism and increase clarity when in doubt.

## Skill Chains

### Mandatory

- `[swarm-manifest]` SHOULD be generated — lane allocation, budget, and coordination plan before dispatching parallel work

### Advisory

- `[mobile-bus]` — post STATUS/MILESTONE receipts as lanes complete
- `[find-work]` — identify candidate tasks for swarm decomposition

## Authority

- **T1 (TRUSTED)**: May run with swarm-manifest
- **T2 (Active/High)**: May run with swarm-manifest
- **T3 (Medium)**: Operator approval + swarm-manifest
- **T4 (Probationary)**: BLOCKED (multi-agent dispatch)
- **Operator**: Override any restriction
