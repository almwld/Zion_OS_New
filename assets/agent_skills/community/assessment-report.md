---
name: assessment-report
description: Generate governance assessment report from checklist results and scores.
version: 0.1.0
execution-mode: advisory
argument-hint: "\"CLIENT\" [--type governance|security|compliance|ai-risk]"
category: governance-compliance
status: candidate
---
# Assessment Report

Generate a professional governance assessment report from your organization's interactive assessments.

## When to Use
- Client completes one of the your assessment questionnaires
- After a governance audit engagement
- Producing deliverables for consulting clients

## Execution

1. **Collect scores** from assessment questionnaire results
2. **Calculate ratings** per domain (A-F scale)
3. **Structure report**:
   - Executive Summary with overall score
   - Domain-by-domain findings
   - Gap analysis (current vs target state)
   - Risk heat map (likelihood × impact)
   - Prioritized recommendations (P1/P2/P3)
   - Roadmap (30/60/90 day)
   - Appendix: full question-by-question results
4. **Output**: Markdown at `_state/reports/<client>-assessment-<date>.md`

## Output Format

```
Assessment Report | <client> | <type>
=======================================
Overall Score: B+ (78/100)

| Domain | Score | Rating | Key Gap |
|--------|-------|--------|---------|
| ... | ... | ... | ... |

Top 3 Recommendations:
1. [P1] ...
2. [P1] ...
3. [P2] ...
```

## Skill Chains
- Assessment leads to engagement → `[proposal-write]`
- Compliance mapping needed → `[nist-map]`, `[iso-crosswalk]`
- Detailed analysis → `[threat-model]`
