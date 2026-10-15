---
name: self-review
description: Grade Codex's own session, plan, artifact, or workflow performance. Use when the user asks for a self-review, grade, score, critique, retrospective of Codex work, or asks whether the session met evidence, quality, protocol, and user-outcome standards; when the user asks for sub-agents, dialectical review, debate, or multi-agent analysis, chain through poly-agent and cross-agent before the Principal Agent reports.
version: 1.1.0
execution-mode: advisory
argument-hint: "\"<session, artifact, plan, or workflow to review>\""
category: fleet-ops
status: candidate
---
# Self Review

## Workflow

1. Gather evidence before grading.
   - Use chat-visible outcomes, created files, diffs, command outputs, bus receipts, source URLs, and explicit user constraints.
   - Separate confirmed facts from inferred judgments.
   - Do not grade based on intention when execution evidence exists.
   - For multi-agent self-review, preserve the context packet, sub-agent prompts,
     and each sub-agent output so `[cross-agent]` can audit the chain.

2. Select the review topology.
   - Default: single-agent self-review using the rubric below.
   - If the user asks for sub-agents, debate, dialectical analysis, poly-agent
     analysis, cross-watch, or multiple reviewers, chain to `[poly-agent]`.
   - If the user asks specifically for thesis -> antithesis -> synthesis, use
     `[dialectical-analysis]` as the topology inside the poly-agent context.
   - After two or more sub-agent outputs exist, route them to `[cross-agent]`
     for chief-synthesis-officer reconciliation before the Principal Agent
     reports to the Human.

3. Score the session on a 100-point rubric.
   - Outcome delivery: 25 points
   - Evidence and truthfulness: 20 points
   - User-fit and prioritization: 15 points
   - Protocol and coordination: 15 points
   - Artifact quality: 15 points
   - Efficiency and reversibility: 10 points

4. Apply penalties.
   - Minus 10 to 30: fabricated source, path, claim, or status.
   - Minus 10 to 20: ignored explicit user constraint.
   - Minus 5 to 15: unnecessary mutation, collision with another lane, or missing bus receipt when required.
   - Minus 5 to 10: shipped artifact with unverified placeholders, stale dates, broken format, or preventable usability flaw.

5. Assign a letter grade.
   - A: 90-100, strong execution with only minor defects.
   - B: 80-89, useful execution with clear correctable gaps.
   - C: 70-79, partial success with material misses.
   - D: 60-69, weak execution; user outcome at risk.
   - F: below 60, failed the task or created unacceptable risk.

## Dimension Checks

### Outcome Delivery

Grade whether the user got the thing they needed, in usable form, at the right depth.

Check:
- Did Codex solve the actual latest request?
- Did artifacts land where the user can use them?
- Did Codex carry through verification instead of stopping at a proposal?
- Did the final answer expose the next concrete action?

### Evidence And Truthfulness

Grade whether claims were grounded.

Check:
- Were current facts verified when likely to drift?
- Were local paths and generated files verified?
- Were sources cited or named when external role data shaped decisions?
- Were uncertain facts labeled as uncertain?

### User Fit And Prioritization

Grade whether the work matched the operator's constraints and style.

Check:
- Did Codex honor urgency, compensation, role constraints, and hard-no sectors?
- Did Codex rank work instead of producing an undifferentiated list?
- Did Codex avoid over-questioning when execution was possible?
- Did Codex correct course when better evidence changed the ranking?

### Protocol And Coordination

Grade whether shared-state discipline was followed.

Check:
- CRAB checks were done when relevant.
- Shared lane mutations were isolated or avoided.
- Required bus receipts were posted.
- No prohibited bus types, direct main pushes, unsafe git commands, or silent self-approval occurred.

#### Shared-state artifact checklist

A **shared-state artifact** is any file created or modified in a git-tracked
repo directory. This includes new governance documents, research docs,
config files, scripts, and code files. It does NOT include:
- Files in `/tmp/` or other temporary directories
- Files in `_internal/scratch/` or untracked working notes
- Files in gitignored paths

**Rule: any new file in a git-tracked repo → post bus STATUS within the same session.**

When reviewing a session, check:
- [ ] Every new file created in a tracked repo has a corresponding bus STATUS
- [ ] Bus STATUS was posted immediately after creation, not deferred to session end
- [ ] Bus STATUS includes: file path, repo name, and brief description
- [ ] Files in `/tmp/`, `_internal/scratch/`, or untracked paths were NOT bus-posted (avoid noise)

If any tracked-repo file lacks a bus STATUS, flag it as a protocol gap.
Origin: AAR 2026-09-02 — governance documents created without bus receipt
until self-review flagged it 20 minutes later.

### Artifact Quality

Grade whether files were fit for purpose.

Check:
- Upload-ready formats exist.
- Generated formats were validated.
- Content is role-specific and public-safe.
- Placeholder or risky claims were removed.
- File names and folder organization are clear.

### Efficiency And Reversibility

Grade whether Codex minimized needless work and kept actions reversible.

Check:
- Used existing artifacts and skills before creating new structure.
- Avoided destructive operations.
- Kept edits small and auditable.
- Avoided expensive or irrelevant detours.

## Multi-Agent Self-Review

When the user requests a multi-agent, dialectical, debate, or sub-agent
self-review, use this chain:

1. Principal Agent creates the review context packet.
2. `[poly-agent]` declares the topology and sub-agent roles.
3. Sub-agents produce independent or sequential outputs according to topology.
4. `[cross-agent]` receives the context packet, sub-agent prompts, and outputs.
5. Principal Agent audits the cross-agent synthesis and reports to the Human.

For dialectical self-review, preserve this sequence:

1. Thesis sub-agent receives the context packet and forms the strongest review
   thesis.
2. Antithesis sub-agent receives the context packet plus thesis output and
   rebuts it.
3. Synthesis sub-agent receives all prior context and produces synthesis.
4. Cross-agent reviews the chain integrity, contradictions, blind spots, and
   residual uncertainty.
5. Principal Agent issues the final grade, findings, and action list.

Same-session sub-agents are analysis support, not independent non-author
governance review unless the Human explicitly accepts that as a waiver.

## Output Format

Use this format:

```markdown
**Grade**
<letter> / <score>/100

**Evidence**
- <key confirmed evidence>

**Scorecard**
- Outcome delivery: <x>/25 - <one-line rationale>
- Evidence and truthfulness: <x>/20 - <one-line rationale>
- User-fit and prioritization: <x>/15 - <one-line rationale>
- Protocol and coordination: <x>/15 - <one-line rationale>
- Artifact quality: <x>/15 - <one-line rationale>
- Efficiency and reversibility: <x>/10 - <one-line rationale>

**Findings**
- P1/P2/P3: <issue, impact, correction>

**What To Repeat**
- <pattern>

**Outstanding items**
- [ ] <specific improvement>
```

Keep the review direct. Do not praise intent. Penalize actual misses even when the final user outcome was mostly good.

## Skill Chains

| After completing... | Consider... |
|---------------------|-------------|
| `[self-review]` default single-agent review | `[aar]` if the workflow itself needs a durable retrospective |
| `[self-review]` with sub-agents, debate, or dialectical analysis | `[poly-agent]` to declare topology and lane roles |
| `[poly-agent]` self-review lanes complete | `[cross-agent]` for chief-synthesis-officer reconciliation |
| `[self-review]` produces durable governance findings | `[decision-log]` or `[ledger]` only if the Human approves persistence |
