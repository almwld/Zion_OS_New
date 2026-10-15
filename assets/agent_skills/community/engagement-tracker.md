---
name: engagement-tracker
description: Track active client engagements with milestones, health status, risk indicators, and renewal dates
version: 0.2.0
execution-mode: side_effecting
argument-hint: "[--action list|update|health] [--client NAME]"
category: fleet-ops
status: candidate
---
# Engagement Tracker

Track active client engagements including milestones, health status, risk indicators, and renewal dates. All engagement data is stored in `_state/engagements.jsonl` as append-only entries with timestamps. Provides a unified view of client relationship health across all active contracts.

`list` and `health` are read-only. `update` appends durable engagement state,
so it requires evidence for the update and the mandatory pre-write receipt
below.

## When to Use
- When checking the status of active client engagements
- When updating milestone completion or engagement health
- When preparing for client meetings and needing a quick status overview
- When identifying at-risk engagements needing attention

## Execution

### 0. **MANDATORY** — Record intent before an update

Only after an explicit user request or authorized delegated task requests an
`update` for a named engagement, post a `SKILL_INVOKE` receipt before appending
to `_state/engagements.jsonl`.

```
Type: SKILL_INVOKE
To: all
Message: [skill=engagement-tracker] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```

The skill invocation runtime injects the caller's canonical identity as
`from_id`. Do not post a receipt or write an update for `list` or `health`.

### 1. Parse and validate inputs

1. Parse `$ARGUMENTS` for action (`list`, `update`, or `health`) and an
   optional client filter.
2. For `update`, require both authorization to write the named engagement and
   a supplied or authoritative source for every new milestone, status, risk,
   or renewal value. If either is absent, return a draft update and ask for
   confirmation rather than recording a guess.

### 2. Read current engagement state

Read `_state/engagements.jsonl` and identify the latest record for each
engagement before classifying or appending anything.

### 3. Execute the requested mode

- `list`: display active engagements with key dates and status.
- `update`: append one timestamped record; never rewrite or delete historical
  records.
- `health`: compute a health assessment from evidenced on-time deliverables,
  communication records, and risk flags. Mark unavailable inputs as
  `UNKNOWN` rather than estimating them.

### 4. Surface follow-up work

1. Flag engagements within 30 days of renewal or with unresolved risk
   indicators.
2. Cross-reference `[time-track]` data when available for utilization metrics.

## Output Format
```
Engagement Tracker | <action>
==============================

## Active Engagements
| Client | SOW | Start | End | Health | Next Milestone |
|--------|-----|-------|-----|--------|----------------|
| ... | ... | ... | ... | GREEN/YELLOW/RED | ... |

## Risk Indicators
- [CLIENT]: <risk description> — <recommended action>

## Upcoming Renewals
- [CLIENT]: Expires <date> (<N> days) — <renewal status>

## Next Action
- ...
```

## Constraints

- Never fabricate milestone completion, client sentiment, renewal dates, or
  health inputs.
- `update` is append-only and local to `_state/engagements.jsonl`; it does not
  amend a SOW, send a client communication, create an invoice, or make a
  commitment on the operator's behalf.
- If an update implies a changed contractual scope, prepare the evidence and
  chain to `[scope-change]`; do not silently re-baseline the engagement.
- If `_state/engagements.jsonl` is absent, report the condition and offer a
  draft first record. Do not create durable engagement state without a
  user-authorized `update` request.

## Skill Chains

### Mandatory

- Before `update`, complete the receipt in **MANDATORY Step 0** and verify
  both the named-engagement authorization and explicit evidence source.

### Advisory

| After this skill... | Consider... |
|--------------------|-------------|
| SOW just signed | `[sow-generate]` to formalize, then update tracker |
| Milestone completed, ready to bill | `[invoice-generate]` for the milestone payment |
| Client health declining | `[governance-report]` for detailed status to stakeholders |

## Authority

- **T1 (TRUSTED)**: May list and assess. May append only when the
  invocation explicitly authorizes an evidence-backed update to the named
  engagement within assigned scope.
- **T2 (Active/High)**: May list and assess. May append only when the
  invocation explicitly delegates the named-engagement update and its source
  and scope are explicit.
- **T3 (Medium)**: Read-only; operator approval is required before `update`.
- **T4 (Probationary)**: Read-only; may not append engagement state.
- **Operator**: May authorize any scoped update or override a restriction.
