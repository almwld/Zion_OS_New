---
name: idea-pack
description: Create a structured IDEA PACK at Phase C of the Intent-to-Spec pipeline. Generates a schema-conformant file under hummbl_governance/docs/research/idea-packs/ and drafts a bus PROPOSAL. Use when an agent has a candidate decision to surface for fleet review before ADR/spec work.
version: 0.2.0
execution-mode: remedial
argument-hint: "<bucket>/<topic> | <bucket>/<topic> [- <one-line summary>]"
category: governance-compliance
status: candidate
---
# IDEA PACK Skill

Create a structured IDEA PACK as defined in
`hummbl_governance/docs/operations/INTENT_TO_SPEC_PIPELINE.md`.

IDEA PACKs are Phase C candidate-decision artifacts. They do not accept a
decision. They make a decision reviewable.

## When to use

- A candidate decision needs fleet review before ADR/spec work.
- Multiple candidate decisions need a coordinated batch.
- Research suggests a possible architecture, governance, or product primitive.
- A proposal might collide with pre-existing infra and needs explicit review.

## When not to use

- The decision is already accepted: draft or update an ADR/spec instead.
- The work is implementation-only: create an issue or implementation plan.
- The topic is raw research only: write `hummbl_governance/docs/research/<topic>.md`.
- The output is a reusable behavior/tool: consider a skill proposal instead.

## Inputs

`<bucket>/<topic> [- <summary>]`

Examples:

```bash
[idea-pack] governance/policy-dsl - tracker fields encode policy preconditions
[idea-pack] blender-mcp/runtime-guardrails
[idea-pack] quest-agents/human-benefits - evidence that quests benefit humans and how that maps to AI agents
```

## Execution

### 1. Verify preconditions

From the hummbl-governance repo root (docs live at top-level `docs/`, not
`hummbl_governance/docs/`):

```bash
test -f docs/operations/INTENT_TO_SPEC_PIPELINE.md \
  || echo "WARN: INTENT_TO_SPEC_PIPELINE.md not found — follow the schema in this SKILL.md body"

test -d docs/research/idea-packs/ \
  || mkdir -p docs/research/idea-packs/
```

### 2. Run the pre-existing infra check

This is mandatory. It prevents the F1 failure mode: proposing a new shape while
missing existing services, schemas, docs, ADRs, or skills.

Search at minimum:

```bash
rg -n -i "<bucket-keyword>|<topic-keyword>" hummbl_governance/services hummbl_governance/integrations hummbl_governance/docs
rg -n -i "<topic-keyword>" hummbl_governance/docs/research/hummbl_governance_adrs hummbl_governance/docs/governance hummbl_governance/docs/operations
```

Also check installed skills when relevant:

```bash
ls ~/.agents/skills | grep -i "<keyword>"
ls ~/.agents/skills-full | grep -i "<keyword>"
```

The `Pre-existing infra check` must name concrete files, modules, ADRs,
services, skills, or state that none were found in checked paths as of a
specific date. Do not write `TBD`.

### 3. Choose template

Use ordinary template for normal candidate decisions:

```text
docs/templates/IDEA_PACK_TEMPLATE.md
```

Use evidence template when the pack depends on external research, public claims,
health/cognition claims, safety claims, model/agent capability claims, or adoption
of an external project:

```text
docs/templates/IDEA_PACK_EVIDENCE_TEMPLATE.md
```

If a template file is absent, follow the schema described in this SKILL.md body
(status, author, bus seed, pre-existing infra check, review ask, and the evidence
sections below when the pack is evidence-backed).

Evidence-backed packs must include:

- Claim-strength ladder.
- Source-tier grading.
- Strict definition or definition discipline.
- Non-goals and safety boundary.
- Evaluation criteria.
- Falsification tests.

### 4. Set lifecycle fields correctly

Allowed artifact statuses:

- `DRAFT`: local authoring only.
- `PROPOSED`: bus-seeded or explicitly queued for fleet review.
- `PROMOTED`: downstream ADR/spec/issue/skill work started.
- `DEFERRED`: intentionally paused.
- `DROPPED`: closed without promotion.

Reviewer verdicts are `ADOPT`, `ADAPT`, or `AVOID`. They are not artifact
statuses.

Use one of these `Bus seed` values:

- `DRAFT/local`: no bus proposal exists.
- `PENDING/queued`: draft PROPOSAL exists but is not posted yet.
- `POSTED/<ISO 8601 UTC>`: bus PROPOSAL was posted.

Do not represent `PENDING/queued` as an opened review window.

### 5. Draft the bus PROPOSAL

Do not post automatically if the operator asked for draft-only work or if the
pack is still being self-grilled.

Shape:

```text
[lane=<bucket>/<topic>] IDEA PACK seed: <summary>. File: docs/research/idea-packs/<YYYY-MM-DD>-<bucket>-<topic>.md. Review ask: <ask>.
```

Codex must not post `DECISION` or `DIRECTIVE`.

### 6. Self-grill before review

Before posting the PROPOSAL, check:

- Is the key term tightly defined?
- Are claim strengths separated from speculation?
- Are source tiers explicit for evidence-heavy packs?
- Is the pre-existing infra check pack-specific?
- Is the review ask concrete and answerable with `ADOPT`, `ADAPT`, or `AVOID`?
- Are adoption/drop criteria present?
- Are safety boundaries and falsification tests present when needed?

### 7. Open fleet review only after the gate

When the operator or workflow gate approves review:

1. Post the bus `PROPOSAL`.
2. Update `Bus seed` to `POSTED/<ISO 8601 UTC>`.
3. Keep status `PROPOSED`.
4. Record reviewer verdicts in `## Verdicts`.

## Output format

```text
IDEA PACK Drafted | <bucket>/<topic>

File: docs/research/idea-packs/<YYYY-MM-DD>-<bucket>-<topic>.md
Status: DRAFT or PROPOSED
Bus seed: DRAFT/local, PENDING/queued, or POSTED/<timestamp>
Review: not open until bus PROPOSAL is posted or explicitly queued

Schema checks:
- Status present
- Author present
- Bus seed present
- Pre-existing infra check populated
- Review ask present
- Evidence sections present when needed
```
