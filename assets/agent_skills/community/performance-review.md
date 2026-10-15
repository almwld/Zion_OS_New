---
name: performance-review
description: Draft a performance review with competency ratings, narrative, and development plan. Calibration-ready. Saves to _internal/hr/. Powered by hr-specialist agent.
version: 1.0.0
execution-mode: advisory
argument-hint: "\"EMPLOYEE\" \"ROLE\" \"PERIOD\" [--rating exceeds|meets|below] [--format narrative|bullet|calibration]"
category: sales-marketing
status: candidate
---
# Performance Review

Draft a complete performance review for an employee — competency ratings, narrative, and development plan — ready for calibration and delivery.

## When to Use

- Annual or mid-year review cycle
- Writing a review for a direct report before calibration
- Drafting self-review language for an employee
- Creating a written record before a PIP or termination
- Structuring feedback after a major project or milestone

## Required Inputs

| Field | Example |
|-------|---------|
| Employee name | Jordan Smith |
| Role | Senior Software Engineer |
| Review period | Jan–Dec 2025 |
| Key accomplishments | Shipped auth refactor, reduced p99 latency 40% |
| Areas for development | Communication in cross-functional meetings |
| Overall rating | Meets / Exceeds / Below Expectations |
| Reviewer name | [Manager name] |
| Company competency model | Optional — defaults to standard 6-competency model |

## Performance Review Format

```
PERFORMANCE REVIEW
Employee:    [Name] — [Role]
Period:      [Review period]
Reviewer:    [Manager]
Rating:      [Overall: Exceeds / Meets / Below / Does Not Meet Expectations]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

OVERALL SUMMARY
[2-3 sentences capturing the employee's overall performance, most significant contribution,
and growth theme for the period. Positive, direct, and specific. No filler language.]

────────────────────────────────────────────────────────
COMPETENCY RATINGS (1=Below, 2=Approaching, 3=Meets, 4=Exceeds, 5=Outstanding)

| Competency                  | Rating | Evidence |
|-----------------------------|--------|---------|
| Technical Excellence        | [1-5]  | [specific example] |
| Delivery & Execution        | [1-5]  | [specific example] |
| Collaboration & Teamwork    | [1-5]  | [specific example] |
| Communication               | [1-5]  | [specific example] |
| Initiative & Growth         | [1-5]  | [specific example] |
| Leadership & Influence      | [1-5]  | [specific example] |

────────────────────────────────────────────────────────
KEY ACCOMPLISHMENTS
1. [Accomplishment — quantified if possible: "Reduced p99 latency from 800ms to 480ms by refactoring auth middleware"]
2. [Accomplishment]
3. [Accomplishment]

────────────────────────────────────────────────────────
DEVELOPMENT AREAS
1. [Area] — [specific, behavioral, non-punitive framing]
   Suggested action: [concrete next step]
2. [Area]
   Suggested action: [concrete next step]

────────────────────────────────────────────────────────
GOALS FOR NEXT PERIOD
1. [Goal — SMART format: specific, measurable, agreed, realistic, time-bound]
2. [Goal]
3. [Goal]

────────────────────────────────────────────────────────
EMPLOYEE SELF-ASSESSMENT NOTES (if applicable)
[Summary of employee's own reflection, or placeholder if not yet received]

MANAGER SIGNATURE: _______________  DATE: _______
EMPLOYEE SIGNATURE: ______________  DATE: _______
(Signature confirms receipt, not necessarily agreement)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

HR GOVERNANCE RECEIPT
Document type:  Performance Review
Generated:      [Date]
Agent:          hr-specialist (<model>)
Calibration:    REQUIRED before delivery — ratings must go through manager calibration
Legal review:   REQUIRED if employee is on PIP track or pre-termination
Estimated human equivalent: $150-300 (HR generalist time for drafting + calibration prep)
Time saved:     2-4 hours
Confidence:     Medium — accuracy depends on specificity of inputs
⚠ This document is a draft. Do not deliver to employee without manager review and HR sign-off.
```

## Rating Guide

| Rating | Label | Calibration guidance |
|--------|-------|---------------------|
| 5 | Outstanding | Top 5-10% of level. Rare. Requires concrete above-and-beyond evidence. |
| 4 | Exceeds Expectations | Consistently above role expectations. Strong evidence required. |
| 3 | Meets Expectations | Fully meets the requirements of the role. Not a negative rating. |
| 2 | Approaching Expectations | Working toward role expectations. Common for new hires or transitioning roles. |
| 1 | Below Expectations | Not meeting role requirements. Typically precedes a PIP. |

## Writing Quality Flags

The agent will flag:
- **Vague language**: "good communication" without specifics → prompts for behavioral example
- **Recency bias**: accomplishments only from last 30 days → prompts for full-period reflection
- **Leniency inflation**: all 4s and 5s without differentiation → flags for calibration discussion
- **Harshness without evidence**: ratings below 3 without documented examples → legal risk flag
- **Gender-coded language**: "aggressive" (male-coded), "emotional" (female-coded) → rephrases to behavioral
- **Protected class language**: any reference to age, family status, health, religion → removed

## Human Cost Equivalent

- Simple narrative review (no equity, no PIP): $150-250 HR generalist time
- Full calibration-ready review with development plan: $250-400
- Pre-PIP documentation review: $400-800 (requires HR/legal review; not fully automatable)

## Skill Chains

- `[performance-review]` → `[offer-letter]` (if promotion offer follows)
- `[performance-review]` → `[policy-draft]` (if PIP documentation needed)
- Before cycle → `[job-description]` (verify role definition matches review criteria)
- After calibration → `[stakeholder-update]` (team-level performance summary for leadership)
