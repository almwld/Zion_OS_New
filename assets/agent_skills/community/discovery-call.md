---
name: discovery-call
description: Pre-call research on prospect with question list, note template, and follow-up draft
version: 0.1.0
execution-mode: advisory
argument-hint: "<company> [--contact NAME] [--focus governance|security|ai]"
category: cognitive
status: candidate
---
# Discovery Call Prep

Prepares for a discovery call by researching the prospect company, generating tailored questions based on their industry and pain points, providing a structured note-taking template, and drafting a follow-up email. Focus areas can be narrowed to governance, security, or AI topics.

## When to Use
- Before a first meeting with a potential client or partner
- When preparing for a sales or partnership discovery conversation
- When you need structured questions tailored to a specific company's context
- Before any call where you want to arrive informed and organized

## Execution
1. Research the company: website, LinkedIn, recent news, funding, tech stack, industry
2. Identify the contact's role and likely priorities based on title and department
3. Generate 8-12 tailored discovery questions organized by category (pain points, current state, goals, budget/timeline)
4. Build a note-taking template with sections: attendees, key quotes, pain points identified, next steps, objections
5. Draft a follow-up email template with placeholders for call-specific details
6. Flag any competitive intel or existing relationships in CRM if available

## Output Format
```
Discovery Call Prep | <company>
================================

## Company Profile
- Industry: ...
- Size: ...
- Recent news: ...
- Likely pain points: ...

## Contact: <name> (<role>)
- Background: ...
- Priorities (inferred): ...

## Discovery Questions
### Pain Points & Current State
1. ...
### Goals & Success Criteria
2. ...
### Budget & Timeline
3. ...

## Note-Taking Template
| Section | Notes |
|---------|-------|
| Attendees | |
| Key quotes | |
| Pain points | |
| Current tools | |
| Budget signals | |
| Next steps | |
| Objections | |

## Follow-Up Email Draft
Subject: ...
Body: ...

## Next Action
- ...
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| Call went well, prospect interested | `[proposal-write]` to draft a proposal |
| Need to prep logistics or agenda | `[meeting-prep]` for calendar and agenda |
| New contact to track | `[crm]` to add to pipeline |
