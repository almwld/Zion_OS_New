---
name: study-plan
description: Generate structured study plan with spaced repetition schedule
version: 0.1.0
execution-mode: advisory
argument-hint: "<topic> [exam-date] [hours-per-day]"
category: data-science
status: candidate
---
# [study-plan]

## When to Use
- Preparing for a certification exam (CCA-F, AWS, Anthropic Certified Architect)
- Structuring self-study on a new technical topic
- Building a day-by-day schedule with spaced repetition
- Reviewing or adjusting an existing study plan

## Execution

### Inputs
- **topic** (required): Certification or subject (e.g., "CCA-F", "AWS SAA", "Rust")
- **exam-date** (optional): Target date, default 4 weeks from today
- **hours-per-day** (optional): Available study hours, default 2

### Steps
1. Calculate total available study days and hours
2. Break topic into domains/modules (use official exam guide if certification)
3. Weight domains by exam percentage or complexity
4. Assign domains to days with progressive difficulty
5. Insert spaced repetition reviews:
   - Day+1: quick review of previous day (15 min)
   - Day+3: review of 3 days ago (15 min)
   - Day+7: weekly comprehensive review (30 min)
   - Day+14: bi-weekly full review (45 min)
6. Schedule practice exams in final 20% of timeline
7. Save plan to `_state/study/<topic>/plan.md`

### Known Certifications
- **CCA-F**: 5 domains, materials at `$PROJECTS_DIR/your-study-repo/`
- **AWS SAA**: Use official exam guide domain weights
- **Anthropic Certified Architect**: Use published certification requirements

## Output Format

```
Study Plan | CCA-F
============================================================
Exam date: 2026-04-22 (28 days)
Pace: 2 hrs/day | Total: 56 hours

## Domain Breakdown
| Domain                    | Weight | Hours | Days    |
|---------------------------|--------|-------|---------|
| AI Governance Fundamentals| 25%    | 14    | D1-D7   |
| Risk Management           | 20%    | 11    | D8-D13  |
| Responsible AI            | 20%    | 11    | D14-D19 |
| Compliance & Standards    | 20%    | 11    | D20-D24 |
| Implementation            | 15%    | 9     | D25-D28 |

## Week 1 Schedule
- D1 (Tue): AI Governance intro (2h) + generate flashcards
- D2 (Wed): Governance frameworks (2h) + D1 review (15m)
- D3 (Thu): Policy development (2h) + D2 review (15m)
- D4 (Fri): Stakeholder roles (2h) + D1 review (15m)
- D5 (Sat): Board oversight (2h) + D2 review (15m)
- D6 (Sun): Case studies (2h) + D3 review (15m)
- D7 (Mon): Weekly review + practice quiz (2h)

## Review Schedule
- Weekly reviews: D7, D14, D21
- Practice exam 1: D24
- Practice exam 2: D27
- Final review: D28

Saved to: _state/study/cca-f/plan.md
------------------------------------------------------------
Next: [flashcard] CCA-F domain-1 (generate study cards)
```

## Skill Chains
- After `[study-plan]` -> suggest `[flashcard]` for first domain
- During study -> use `[quiz]` for self-assessment
- Track progress with `[cert-tracker]`
