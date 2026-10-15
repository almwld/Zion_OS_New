---
name: proposal-write
description: Generate client proposal from scope, timeline, rate, and deliverables.
version: 0.1.0
execution-mode: advisory
argument-hint: "\"CLIENT\" \"PROJECT\" [--rate HOURLY] [--hours EST]"
category: finance-legal
status: candidate
---
# Proposal Write

Generate a professional consulting proposal with your organization's branding.

## When to Use
- New consulting engagement opportunity
- Responding to an RFP or inquiry
- After `[meeting-prep]` identifies a potential project

## Execution

1. **Gather inputs**: Client name, project scope, timeline, rate, deliverables
2. **Structure proposal**:
   - Executive Summary (2-3 sentences)
   - Scope of Work (bulleted deliverables)
   - Approach & Methodology
   - Timeline & Milestones
   - Investment (hours × rate, payment terms)
   - About Your Organization (standard boilerplate)
   - Terms & Conditions (standard)
3. **Output**: Markdown file at `_state/proposals/<client>-<date>.md`

## Output Format

```markdown
# Proposal: <Project Name>
**Prepared for**: <Client>
**Prepared by**: Your Organization | Your Name
**Date**: <date>

## Executive Summary
...

## Scope of Work
- [ ] Deliverable 1
- [ ] Deliverable 2

## Investment
| Item | Hours | Rate | Total |
|------|-------|------|-------|
| ... | ... | ... | ... |
**Total**: $X,XXX
```

## Skill Chains
- After proposal accepted → `[sow-generate]`
- Pricing analysis → `[automation-roi]`
- Competitive positioning → `[competitive-intel]`
