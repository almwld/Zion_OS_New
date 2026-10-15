---
name: base120-verify
description: Grade Base120 alignment reports as draft or receipt using artifact evidence fields — rejected-set log, teeth field, external trace — never self-report.
version: 0.1.0
execution-mode: advisory
argument-hint: '<base120 report or framed problem to grade>'
triggers:
  - verify base120
  - draft or receipt
  - grade this frame
  - stamp check
  - is this verified
chains:
  - base120
  - claim-verify
  - evidence-grade
  - aar
base120:
  - base120-evidence-002
  - base120-inversion-018
  - base120-feedback-003
status: candidate
category: reasoning
---

# Base120 Verify — Draft or Receipt

Grades a Base120 application by inspecting its artifact, not its author's self-report. A solo pass is construction, not perception: this skill encodes the fields that let an artifact carry evidence of its own construction, and the derived verdict that follows.

## Workflow

1. **DECLARE** — capture the frame, the owned observer, and the provenance tag (`[DERIVED]` / `[IMPORTED]`). Self-reported confidence is capped at 0.5 when no external artifact was touched.
2. **TEST** — the report MUST carry a rejected-set log: operators considered and not run, with one-line reasons. Reasons should be ragged (fit, overlap, coin-flip). A rejected set that uniformly points at the conclusion is fabricated suspicion — count it against, not for.
3. **GATE** — the frame MUST name a teeth field: one observation that would kill it, checkable within the review horizon. "Dies if cosmology changes" is decoration, not teeth.
4. **STAMP** — the verdict is derived, never chosen:
   - `receipt` — requires an external trace: a blind re-derivation of TEST/GATE by a verifier with disjoint context who never saw the author's rationale
   - `draft` — default for all solo output; also forced by missing rejected-set log, missing teeth, or zero-tension findings
5. **AUDIT** — TRUST-ANCHOR fields (external trace) spot-audit SIGNAL-ONLY fields (logs, teeth) via exogenous triggers: operator request, external coordinator on a clock, or counterparty challenge. The audited agent MUST NOT set its own audit rate or initiate its own audits.

### Edge cases

- MCP unavailable: grade from artifact fields alone; tag verdict `[UNVERIFIED - MCP unavailable]` for any operator citations.
- No report exists yet: emit the required fields as a checklist, not a verdict.
- Rejected-set log absent: the pass is unverifiable, not merely weak — auto-draft.

## Constraints

- MUST NOT self-stamp receipt without an external trace — same-entity write-and-stamp is a variety violation by construction.
- MUST NOT choose the verdict word; the stamp is derived from the fields, not asserted by the author.
- MUST NOT let the audited agent own its audit trigger or sampling rate — author-initiated audits do not count as audits.
- MUST NOT paraphrase Base120 operator definitions — exact text from the MCP server or "unable to verify".
- SHOULD treat a protocol change that loosens a gate under which the change itself would fail as rejected — no voting to lower the bar that stops you.

## Examples

**Example 1: Solo pass**

> User: grade this alignment report I just produced
> Agent: rejected-set log absent, no teeth field, no external trace → `draft`. Emits the three missing fields as the fix, not just the verdict.

**Example 2: Verified pass**

> User: codex re-ran TEST/GATE blind and converged on the same frame
> Agent: external trace populated by an independent verifier → `receipt`, citing the trace, not the convergence claim.

## Evidence

- [ ] Graded report with rejected-set log, teeth field, field classes (TRUST-ANCHOR vs SIGNAL-ONLY)
- [ ] Derived verdict (`draft` or `receipt`) with the field-level reason
- [ ] External trace reference when verdict is `receipt`
