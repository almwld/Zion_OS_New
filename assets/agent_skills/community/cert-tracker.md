---
name: cert-tracker
description: Track certification progress with deadlines, study hours, and requirements
version: 0.1.0
execution-mode: advisory
argument-hint: "<status|add|log-hours|update> [cert-name]"
category: data-science
status: candidate
---
# [cert-tracker]

## When to Use
- Checking progress on active certifications
- Logging study hours for a certification
- Adding a new certification to track
- Reviewing upcoming deadlines and requirements

## Execution

### Storage
- Tracker: `_state/certs/tracker.json`
- Schema: `{"certs": [{"name", "target_date", "estimated_hours", "logged_hours", "requirements": [{"name", "status", "hours"}], "quiz_scores": []}]}`

### Known Certifications
- Add your certifications here (e.g., CCA-F, AWS SAA, CISSP)

### Commands

**status [cert-name]**
1. Load tracker from `_state/certs/tracker.json`
2. If cert-name given, show detailed view with requirements checklist
3. If no cert-name, show summary table of all active certs
4. Calculate: days remaining, hours logged vs estimated, completion %, pace needed
5. Flag at-risk certs (behind schedule based on remaining time vs hours needed)

**add [cert-name] [target-date] [estimated-hours]**
1. Create new certification entry with requirements checklist
2. Use known templates for recognized certifications
3. Initialize hours at 0, save to tracker

**log-hours [cert-name] [hours] [notes]**
1. Add study hours to the certification entry
2. Update last-studied date to today
3. Recalculate pace: on-track / behind / ahead

**update [cert-name] [requirement] [status]**
1. Mark requirement as `complete`, `in-progress`, or `not-started`
2. Recalculate overall completion percentage

## Output Format

```
Cert Tracker | status
============================================================

| Certification | Target     | Progress | Hours    | Status    |
|---------------|------------|----------|----------|-----------|
| CCA-F         | 2026-04-22 | 35%      | 20/56h   | ON TRACK  |
| Anthropic CA  | TBD        | 10%      | 5h       | PLANNING  |

## CCA-F Detail
Target: Apr 22, 2026 (28 days remaining)
Pace needed: 1.3 hrs/day (current avg: 1.5 hrs/day) -- ON TRACK

Requirements:
  [x] Domain 1: AI Governance Fundamentals (8h logged)
  [~] Domain 2: Risk Management (6/11h)
  [ ] Domain 3: Responsible AI
  [ ] Domain 4: Compliance & Standards
  [ ] Domain 5: Implementation
  [ ] Practice Exam 1
  [ ] Practice Exam 2

Last studied: 2026-03-24
Quiz scores: 80% avg (3 quizzes taken)
------------------------------------------------------------
Next: [study-plan] CCA-F (adjust schedule) or [quiz] CCA-F
```

## Skill Chains
- After `[cert-tracker] status` showing behind -> suggest `[study-plan]` adjustment
- After `[cert-tracker] log-hours` -> suggest `[quiz]` for assessment
- Pair with `[time-track]` to log study as billable education time
