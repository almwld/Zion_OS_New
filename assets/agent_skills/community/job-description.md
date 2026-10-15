---
name: job-description
description: Write a job description / job posting. Role summary, responsibilities, requirements (must-have vs nice-to-have), comp band, and EEO statement. Saves to _internal/hr/. Powered by hr-specialist agent.
version: 1.0.0
execution-mode: advisory
argument-hint: "\"ROLE_TITLE\" \"LEVEL\" [--dept engineering|sales|ops] [--remote yes|no|hybrid] [--comp \"$X-$Y\"]"
category: sales-marketing
status: candidate
---
# Job Description

Generate a complete job description for posting or internal role definition.

## When to Use

- Opening a new role (before posting publicly)
- Defining role expectations for a new hire
- Evaluating whether a role should be employee vs contractor
- Creating an interview scorecard (JD is the foundation)

## Required Inputs

| Field | Example |
|-------|---------|
| Role title | Senior AI Governance Consultant |
| Level | Senior / IC4 / Lead |
| Department | Consulting / Engineering / Sales |
| Location | Atlanta, GA / Remote / Hybrid |
| Employment type | Full-time / Contract |
| Comp band | $120,000–$160,000 + equity (or "Competitive, DOE") |
| Key responsibilities (3-5 bullets) | Client assessments, framework design, delivery |
| Must-have requirements | 5+ years enterprise software, AI/ML familiarity |
| Nice-to-have | NIST AI RMF certification, big-4 consulting |

## JD Structure

```
[COMPANY]: [1-line company pitch — what you do, why it matters]

ABOUT THE ROLE
[2-3 sentences: what this person owns, why it matters now]

WHAT YOU'LL DO
- [Key responsibility 1]
- [Key responsibility 2]
- [Key responsibility 3]
- [Key responsibility 4-5 as needed]

WHAT YOU BRING (Required)
- [Must-have requirement 1]
- [Must-have requirement 2]
- [Must-have requirement 3]

WHAT WOULD SET YOU APART (Preferred)
- [Nice-to-have 1]
- [Nice-to-have 2]

COMPENSATION & BENEFITS
[Range] + [equity if applicable] + [key benefits]

LOCATION: [detail]
TYPE: [Full-time / Contract]

[Company] is an equal opportunity employer. We do not discriminate on the basis of race,
color, religion, sex, national origin, age, disability, or any other characteristic
protected by applicable law.
```

## EEO / Bias Flags

The agent will flag language that could create legal exposure or reduce candidate diversity:
- Age-coded terms: "digital native", "recent graduate", "young and hungry"
- Gender-coded terms: "rockstar", "ninja", "aggressive"
- Requirement inflation: requiring 10+ years for tools that are <5 years old
- Unnecessary degree requirements when skills matter more

## Human Cost Equivalent

- Basic job posting: $100-200 HR consultant or recruiter time
- Detailed JD with levels/bands: $200-400

## Skill Chains

- JD → `[offer-letter]` (when ready to make the hire)
- JD posted → `[crm]` (track applicants)
