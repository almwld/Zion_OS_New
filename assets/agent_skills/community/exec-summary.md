---
name: exec-summary
description: Produce 1-page executive summary from any long-form document or analysis.
version: 0.1.0
execution-mode: advisory
argument-hint: "<source-file-or-topic> [--audience technical|executive|board]"
category: data-science
status: candidate
---
# Executive Summary

Distill any long document into a concise, actionable 1-page summary.

## When to Use
- Briefing stakeholders or stakeholders on a technical topic
- Summarizing research findings for non-technical audience
- Creating cover pages for assessment reports
- Preparing for investor or partner meetings

## Execution

1. **Read source** document or analysis
2. **Identify** key findings, decisions, risks, and next steps
3. **Adapt tone** for audience (technical detail vs business impact)
4. **Structure**:
   - Situation (1-2 sentences)
   - Key Findings (3-5 bullets)
   - Recommendations (2-3 prioritized)
   - Next Steps (with owners and dates)
   - Risk/Opportunity callout (if applicable)
5. **Constrain** to ~300 words / 1 printed page

## Output Format

```
Executive Summary | <topic>
============================
**Audience**: <technical|executive|board>

## Situation
<1-2 sentences>

## Key Findings
- ...

## Recommendations
1. ...

## Next Steps
- [ ] <action> -- <owner> by <date>
```

## Skill Chains
- Source from → `[assessment-report]`, `[deep-research]`, `[daily-research]`
- Deliver via → `[send-email]`, `[docgen]` (PDF)
- Deeper analysis → `[nested-story]`
