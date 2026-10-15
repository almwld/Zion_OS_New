---
name: decision-log
description: Record architectural or process decisions as ADRs with context and consequences.
version: 0.1.0
execution-mode: side_effecting
argument-hint: "\"DECISION TITLE\""
category: data-science
status: candidate
---
# Decision Log

Record a decision as an Architecture Decision Record (ADR) and persist to the cognitive ledger.

## Execution

### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=decision-log] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

### 1. Capture the decision
- **Title**: Short, imperative ("Use stdlib-only for core modules")
- **Status**: Proposed / Accepted / Deprecated / Superseded
- **Context**: What prompted this decision?
- **Decision**: What did we decide?
- **Consequences**: What are the tradeoffs?
- **Alternatives considered**: What else was evaluated?

### 2. Persist to CLP

> **Local dev fallback:** The `hummbl_governance.cognition` module is a VPS-runtime
> component. In local dev environments where the package is not installed, this
> step will fail with `ModuleNotFoundError: No module named hummbl_governance.cognition`.
> In that case, skip ledger persistence and rely on the ADR file (step 1) + bus
> STATUS post (step 3) as the durable record. Note the ledger gap in the ADR.

```bash
source .venv/bin/activate
python -m hummbl_governance.cognition post \
  --vendor "${AGENT_VENDOR:?set AGENT_VENDOR to the provider actually running}" --model "${AGENT_MODEL:?set AGENT_MODEL to the model actually running}" \
  --type decision --scope project \
  --content "DECISION: <title>. CONTEXT: <why>. CHOSE: <what>. TRADEOFF: <consequences>." \
  --tags "adr,<category>"
# The skill invocation runtime injects the caller's canonical identity as agent.
```

### 3. Output format
```
ADR-<number> | <title>
════════════════════════════

Status: <Accepted>
Date: <YYYY-MM-DD>
Deciders: <who was involved>

## Context
<what problem or question prompted this>

## Decision
<what we decided to do>

## Consequences
### Positive
- <benefit>
### Negative
- <tradeoff>
### Risks
- <what could go wrong>

## Alternatives Considered
1. <option> -- rejected because <reason>
2. <option> -- rejected because <reason>

## References
- <links to related decisions, docs, or discussions>
```

## When to Use
- Choosing between competing approaches
- Adopting or rejecting a technology
- Changing a process or convention
- Any decision that future-you will wonder "why did we do this?"

## Skill Chains

### Mandatory

- None — decision-log is the persistence layer for ADRs. The ADR format (step 1) is the built-in check.

### Advisory

- **Before logging**: `[adr-review]` (review existing ADRs for staleness/supersession)
- **After logging**: `[bus]` (STATUS post), `[ledger]` (persist to CLP — already done in step 2)
- **For architectural decisions**: `[threat-model]` (security implications), `[contract-review]` (if breaking changes)

## Authority

- **T1 (TRUSTED)**: May log decisions without restriction
- **T2 (Active/High)**: May log decisions without restriction (append-only is low-risk)
- **T3 (Medium)**: May log `proposed` status; `accepted` status requires operator notification
- **T4 (Probationary)**: May draft ADRs but NOT mark as `accepted`; requires operator approval
- **Operator**: Override any restriction
