---
name: sow-generate
description: Generate Statement of Work from proposal with milestones and payment schedule.
version: 0.1.0
execution-mode: advisory
argument-hint: "<proposal-path> | \"CLIENT\" \"PROJECT\""
category: finance-legal
status: candidate
---
# SOW Generate

Produce a formal Statement of Work from an accepted proposal.

## When to Use
- Client accepts a proposal
- Formalizing a consulting engagement
- Before starting billable work

## Execution

1. **Read proposal** (if path provided) or gather inputs
2. **Structure SOW**:
   - Parties (Your Organization + Client)
   - Scope & Deliverables (from proposal)
   - Milestones with acceptance criteria
   - Payment schedule (per milestone or monthly)
   - Timeline (start, milestones, end)
   - Change management process
   - IP ownership terms
   - Confidentiality
   - Termination clause
3. **Output**: Markdown at `_state/contracts/<client>-sow-<date>.md`

## Output Format

```markdown
# Statement of Work
**Between**: Your Organization and <Client>
**Effective Date**: <date>
**Project**: <name>

## Milestones
| # | Milestone | Deliverable | Due | Payment |
|---|-----------|-------------|-----|---------|
| 1 | ... | ... | ... | $X,XXX |

## Total: $XX,XXX
```

## Skill Chains
- Before SOW → `[proposal-write]`
- After SOW signed → `[time-track]` (start tracking), `[invoice-generate]` (at milestones)
- Scope changes → `[decision-log]`
