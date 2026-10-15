---
name: remediation-plan
description: Generate prioritized remediation plan from gap analysis with effort estimates and milestones.
version: 0.1.0
execution-mode: advisory
argument-hint: "[--from gap-analysis|assessment|audit] [--timeline WEEKS] [--budget HOURS]"
category: governance-compliance
status: candidate
---
# Remediation Plan

Turn gap analysis findings into an actionable, prioritized remediation plan. The bridge between "here's what's wrong" and "here's how to fix it" -- core consulting deliverable.

## When to Use
- After `[gap-analysis]` identifies compliance gaps
- Client wants a roadmap to compliance
- Internal improvement planning
- When user says "remediation plan" or "fix the gaps"

## Execution

1. **Import gaps**: From gap analysis results or manual input
2. **Classify**: Group by domain and effort level
3. **Prioritize**: Score by risk reduction * inverse effort (bang for buck)
4. **Sequence**: Order considering dependencies (some controls build on others)
5. **Estimate**: Hours, timeline, and responsible party for each
6. **Milestone**: Define checkpoints for progress tracking

## Output Format

```
Remediation Plan | {source} | {timeline}
=========================================

## Plan Overview
Gaps to remediate: {N}
Estimated effort: {hours} hours
Timeline: {weeks} weeks
Budget constraint: {hours or "unconstrained"}

## Phase 1: Quick Wins (Weeks 1-2)
| # | Gap | Action | Effort | Owner | Deliverable |
|---|-----|--------|--------|-------|-------------|
| 1 | No AI use policy | Draft from template, review, publish | 4h | Legal | Policy doc |

## Phase 2: Foundation (Weeks 3-6)
| # | Gap | Action | Effort | Owner | Deliverable |
|---|-----|--------|--------|-------|-------------|

## Phase 3: Hardening (Weeks 7-12)
| # | Gap | Action | Effort | Owner | Deliverable |
|---|-----|--------|--------|-------|-------------|

## Milestones
| Week | Milestone | Gaps Closed | Compliance % |
|------|-----------|-------------|-------------|
| 2 | Quick wins complete | {N} | {%} |
| 6 | Foundation laid | {N} | {%} |
| 12 | Audit-ready | {N} | {%} |

## Dependencies
{Which remediations must happen before others}

## Risk: What Happens If We Don't
{Consequences of not remediating, by priority tier}
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| Plan created | `[sow-generate]` (formalize as engagement) |
| Client review | `[exec-summary]` (executive version) |
| Tracking progress | `[engagement-tracker]` (track milestones) |
| Plan changes | `[scope-change]` (document changes) |
| Plan complete | `[governance-maturity]` (re-assess) |
