---
name: mtsmu-orchestrator
description: "Evidence-first orchestration for high-rigor coding, debugging, review, and ops work with lane decomposition, confidence, telemetry, decision traces, and receipts."
version: 0.1.0
execution-mode: advisory
argument-hint: <task or question requiring high-rigor execution>
category: dev-tools
status: candidate
providers:
  required: [python]
---
# MTSMU Orchestrator

## Quick Start

- Treat `MTSMU`, `maximally truth seeking`, and `maximally useful` as a request for an evidence-first operating loop.
- Do not expose private chain-of-thought. Provide concise decision traces instead: evidence, uncertainties, decision, verification, next lanes.
- Prefer live local evidence over memory. For unstable facts, probe or browse before making claims.
- Optimize for useful forward motion. Choose the highest-value lane first and keep tightening the model as evidence arrives.
- If the work starts collapsing into process-on-process scaffolding without producing new evidence or repo value, stop and pivot to a live task, verification gap, or real defect.

## Operating Loop

1. Frame the objective, constraints, and success condition.
2. Gather live evidence before proposing conclusions.
3. Build 1-3 execution lanes and choose the best lane by expected value and reversibility.
4. Emit telemetry as you work: tests, probes, diffs, bus state, runtime signals, or command receipts.
5. Quantify confidence with explicit uncertainty. Use `0-1` scores tied to evidence quality, not vibes.
6. Verify the changed behavior directly. If evidence contradicts the plan, update the model and keep going.
7. Leave receipts: bus messages, test results, file references, and concise outcome statements.

## Output Contract

Use this response shape unless the user asks for something else:

- `Evidence`: measured facts, file reads, test results, command outcomes
- `Uncertainties`: what is still inferred or weakly supported
- `Action`: what lane you chose and why
- `Verification`: what proved the result
- `Next lanes`: the next highest-value tasks if more work remains

Keep the output compressed. The point is auditability and usefulness, not verbosity.

## Coordination

- When the repo has a coordination bus, post a kickoff when work begins and a receipt when meaningful verification completes.
- Use the canonical bus writer, not raw shell appends.
- Respect dirty worktrees and operational state. Never overwrite unrelated changes.
- If a task naturally splits, assign conceptual lanes and execute them serially or in parallel as the environment allows.

## Confidence Rules

- `0.9+`: directly verified by tests, probes, or source inspection
- `0.7-0.89`: strong evidence, but at least one important assumption remains
- `0.4-0.69`: partial evidence or unverified integration behavior
- `<0.4`: speculative; say so plainly and reduce scope

## Telemetry Rules

- Distinguish measured telemetry from inference.
- Prefer small, repeatable checks over broad claims.
- Call out telemetry that is known-bad or weakly trustworthy and fix it if it affects decisions.

## Dispatch Guide

Route to the narrowest skill that fits. If the real task is already clear, go directly -- do not stay at the orchestrator layer.

| Trigger | Skill |
|---|---|
| Reproduce/isolate/patch a bug | `mtsmu-debug` |
| Code review, risk assessment, merge readiness | `mtsmu-review` |
| Multi-lane decomposition, bus coordination, handoffs | `mtsmu-swarm` |
| Source gathering, contradiction handling, uncertainty | `mtsmu-research` |
| General evidence-first execution | `mtsmu-orchestrator` (this skill) |

## Signal Quality

Good signals: direct test results, live process checks, fresh log/bus rows, explicit exit codes, env/config reads tied to behavior.

Weak signals: old heartbeat rows, process substring matches counting wrappers, defaults mistaken for configured state, one green check with contradictory surrounding evidence, tool success output without filesystem verification.

Repair order: fix broken measurement first, re-run, compare old vs new signal, only then update confidence.

## Skill Promotion

Before creating a new MTSMU skill, answer these five questions. Most should be yes:

1. Did this workflow help in more than one session?
2. Can the trigger be described in one sentence?
3. Can the instructions stay short without losing usefulness?
4. Is there a clear boundary between this skill and existing skills?
5. Will this save future time or reduce mistakes?

If yes: name the skill after the action, write a compact SKILL.md with a concrete workflow, add one reference file if detail is needed, validate on disk.

## Suite Overview (5 skills)

- `mtsmu-orchestrator`: umbrella evidence-first loop, dispatch, signal quality, skill promotion
- `mtsmu-debug`: reproduce, isolate, instrument, patch, verify
- `mtsmu-review`: bug-first review with severity ordering and testing gaps
- `mtsmu-swarm`: lane decomposition, coordination-bus receipts, cross-agent handoffs
- `mtsmu-research`: source weighting, contradiction handling, uncertainty tracking

## Skill Chains
- For free-tier inference for orchestration lane tasks -> `[reasoning-router]` (`route`)
