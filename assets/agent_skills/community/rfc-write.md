---
name: rfc-write
description: Write Request for Comments documents for technical proposals with problem statement, alternatives, and decision criteria
version: 0.1.0
execution-mode: advisory
argument-hint: "<title> [--template standard|lightweight|adr-style]"
category: data-science
status: candidate
---
# RFC Write

Generate structured Request for Comments (RFC) documents for technical proposals. Produces a complete document with problem statement, proposed solution, alternatives considered, decision criteria, and migration plan. Designed to drive consensus before implementation begins.

## When to Use
- Proposing a significant architectural or infrastructure change
- Introducing a new technology, pattern, or convention to the codebase
- Making a decision that affects multiple teams or agents
- Documenting a design choice that needs stakeholder review before proceeding

## Execution
1. Parse `$ARGUMENTS` for title (required) and template (default: `standard`).
2. Research context: check git history, existing ADRs in `docs/`, CLAUDE.md, and bus messages for related decisions.
3. Draft the RFC using the selected template:
   - **standard**: Full RFC with all sections (problem, background, proposal, alternatives, criteria, migration, risks).
   - **lightweight**: Abbreviated format for smaller changes (problem, proposal, alternatives, decision).
   - **adr-style**: Architecture Decision Record format (context, decision, consequences).
4. For each alternative, include a pros/cons analysis and evaluation against decision criteria.
5. Include estimated effort, risk level, and reversibility assessment.
6. Generate a unique RFC number based on existing RFCs in the repo.
7. Write the RFC to `docs/rfcs/RFC-NNNN-{slug}.md`.

## Output Format
```
RFC Write | RFC-NNNN | title | template

## RFC-NNNN: {Title}
- Status: DRAFT
- Author: {from context}
- Date: {today}
- Reviewers: {suggested}

### Problem Statement
{What problem does this solve? Why now?}

### Background
{Context needed to understand the proposal}

### Proposed Solution
{Detailed description of the proposed approach}

### Alternatives Considered
#### Alternative A: {name}
- Pros: {list}
- Cons: {list}

### Decision Criteria
| Criterion | Weight | Proposal | Alt A | Alt B |
|----------|--------|----------|-------|-------|
| {criterion} | {H/M/L} | {score} | {score} | {score} |

### Migration Plan
{How to get from here to there}

### Risks
{What could go wrong}

Next action: {share RFC for review or "No further action needed"}
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| RFC approved | `[decision-log]` to record the decision |
| RFC proposing API changes | `[proposal-write]` if client-facing |
| RFC with code implications | `[diff-explain]` after implementation to verify alignment |
