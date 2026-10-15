---
name: gap-analysis
description: Compare current controls against target framework requirements, quantify gaps, prioritize remediation.
version: 0.1.0
execution-mode: advisory
argument-hint: "[--framework nist|iso|soc2] [--target-level LEVEL] [--org NAME]"
category: governance-compliance
status: candidate
---
# Gap Analysis

Systematic comparison of current governance controls against framework requirements. Produces a scored gap report that feeds directly into proposals and remediation plans.

## When to Use
- After `[governance-maturity]` assessment identifies gaps
- Client wants to know "what's missing" for compliance
- Preparing for an audit or certification
- When user says "gap analysis" or "what's missing for compliance"

## Execution

1. **Load controls**: Read from `[control-catalog]` or assess fresh
2. **Load framework**: Full requirements list for target framework
3. **Map**: Match existing controls to requirements
4. **Score each gap**:
   - `COVERED` -- control exists and is implemented
   - `PARTIAL` -- control exists but incomplete
   - `MISSING` -- no control addresses this requirement
   - `N/A` -- requirement doesn't apply
5. **Prioritize**: Rank gaps by risk and effort to close
6. **Report**: Gap matrix with remediation recommendations

## Output Format

```
Gap Analysis | {framework} | {org}
===================================

## Summary
Requirements assessed: {N}
Covered: {N} ({%})
Partial: {N} ({%})
Missing: {N} ({%})
N/A: {N} ({%})

## Compliance Score: {%}

## Gap Matrix
| Req ID | Requirement | Status | Current Control | Gap | Priority |
|--------|------------|--------|----------------|-----|----------|
| GOVERN 1.1 | AI system inventory | COVERED | CTL-001 | — | — |
| MAP 1.1 | Risk categorization | MISSING | — | No risk taxonomy | HIGH |

## Critical Gaps (must address)
1. {Gap}: {what's needed}, effort: {est}, risk if not addressed: {risk}

## Quick Wins
1. {Gap}: {simple fix}, effort: LOW

## Remediation Estimate
| Priority | Gaps | Est. Effort | Timeline |
|----------|------|-------------|----------|
| Critical | {N} | {hours/days} | {weeks} |
| High | {N} | ... | ... |
| Medium | {N} | ... | ... |
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| Gaps quantified | `[remediation-plan]` (build the plan) |
| Client-facing | `[proposal-write]` (sell the remediation work) |
| Many gaps | `[rice-prioritize]` (prioritize by impact) |
| Few gaps | `[audit-prep]` (prepare for certification) |
| Internal | `[evidence-pack]` (bundle what we have) |
