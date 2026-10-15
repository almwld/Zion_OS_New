---
name: compliance-calendar
description: Generate and track compliance deadlines, audit windows, certification expirations
version: 0.1.0
execution-mode: advisory
argument-hint: "<view: month|quarter|year> [--add <event>] [--check]"
category: governance-compliance
status: candidate
---
# [compliance-calendar]

## When to Use
- Planning audit schedules for client engagements
- Tracking certification renewal deadlines
- Monthly/quarterly compliance review cadence
- Before client meetings to check upcoming obligations

## Execution

### 1. Load Calendar State
Check for existing compliance calendar data:
```bash
# Check for calendar data
find . -path "*compliance*calendar*" -o -path "*compliance*deadline*" 2>/dev/null | head -10
find PROJECTS/ -name "*.json" -path "*compliance*" 2>/dev/null | head -10
# Check for existing assessment data
ls PROJECTS/$REPO_NAME/dashboard* 2>/dev/null
```

### 2. Parse Arguments
- `month` -- show current month deadlines (default)
- `quarter` -- show current quarter view
- `year` -- show full year timeline
- `--add <event>` -- add a new deadline (format: "YYYY-MM-DD | Framework | Event | Owner")
- `--check` -- highlight overdue and upcoming-within-7-days items

### 3. Standard Compliance Cadence
Pre-populate with known recurring events:
- **Monthly**: security scan review, cost governance check, bus audit
- **Quarterly**: SOC 2 control testing, risk assessment update, policy review
- **Annual**: ISO 27001 surveillance audit, ISO 42001 recertification, penetration test
- **Ad-hoc**: client audit windows, certification exams (CCA-F), partner reviews

### 4. Status Check
For each deadline, determine status:
- **DONE**: completed with evidence
- **ON TRACK**: upcoming, work in progress
- **AT RISK**: upcoming within 14 days, not started
- **OVERDUE**: past due date

## Output Format

```
Compliance Calendar | <view> | <date>
============================================

March 2026
----------
  03-15  [DONE]     Agent review
  03-23  [DONE]     Partner application submitted
  03-25  [ON TRACK] Weekly security scan review
  03-31  [AT RISK]  Q1 risk assessment update

April 2026
----------
  04-02  [ON TRACK] App alpha release
  04-15  [PENDING]  Q1 SOC 2 control evidence collection
  04-30  [PENDING]  Certification coursework checkpoint

Upcoming (next 7 days)
----------------------
  03-25  Weekly security scan review -- run [security-scan]
  03-31  Q1 risk assessment -- run [soc2-check], update risk register

Overdue
-------
  None

Next action: <recommendation>
```

## Skill Chains
- After `[compliance-calendar]` -> `[soc2-check]` for items needing evidence
- After `[compliance-calendar] --add` -> `[ledger]` to persist the entry
- After `[compliance-calendar] --check` -> `[send-email]` to notify stakeholders of at-risk items
