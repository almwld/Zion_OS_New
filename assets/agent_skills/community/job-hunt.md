---
name: job-hunt
description: Daily job application tracker -- streak, targets, follow-ups, platform links, and proof pack status
version: 1.0.0
execution-mode: advisory
argument-hint: "[day-number | status | add <company> <role> | follow-up]"
category: sales-marketing
status: candidate
---
# [job-hunt]

## Context Gathering

Before executing this skill, gather the following context:
- Run `cat PROJECTS/$GITHUB_ORG-profile/job-hunt/tracker.csv`

## Behavior

### Default (no args): Daily Dashboard

1. Read `PROJECTS/$GITHUB_ORG-profile/job-hunt/tracker.csv`
2. Calculate:
   - **Sprint day**: days since 2026-03-25 + 1 (of 20)
   - **Total applied**: rows where status != "pending" and status != "drafting"
   - **Today's count**: rows with today's date where status = "applied" or beyond
   - **Today's target**: 5 - today's count
   - **Streak**: consecutive days with 5+ applications
   - **Follow-ups due**: rows where follow_up_date <= today and status = "applied"
   - **Tier breakdown**: count by tier (1 vs 2)
   - **Referral rate**: % of applied rows with referral = "y"
3. Display:

```
## Job Sprint | Day X/20

| Metric | Value |
|--------|-------|
| Applied today | X/5 |
| Total applied | X/100 |
| Streak | X days |
| Follow-ups due | X |
| Tier 1 / Tier 2 | X / X |
| Referral rate | X% |

### Follow-Ups Due Today
[list companies + roles where follow_up_date <= today]

### Platforms to Check
- LinkedIn saved search: Platform Engineer / SRE / AI Platform
- Indeed saved search: same
- Dice: dice.com (set up saved search)
- Wellfound: wellfound.com
- HN Hiring: hnhiring.com (filter: remote + platform)
- platformengineering.org/jobs
- 80,000 Hours: jobs.80000hours.org
- Google Jobs: search "[role] remote" on Google

### Proof Pack Status
- [ ] One-pager PDF
- [x] Case study (hummbl-governance)
- [x] Demo repo (hummbl-governance on PyPI)
- [ ] Screen recording (5-8 min)
- [ ] Endorsements (team lead + 1)
- [x] LinkedIn profile (LINKEDIN_FIX_NOW.md)
- [x] Resume bullets (3 variants)
- [x] Cover letter templates (3 variants)
```

### `status`: Summary only (no platform links)

Show the metrics table only.

### `add <company> <role>`: Add entry

Append a new row to tracker.csv with today's date, status=applied, tier=2 (override with `--tier 1`), follow_up_date = today + 7 days.

### `follow-up`: Show overdue follow-ups with draft templates

List all rows where follow_up_date <= today and status = "applied". For each, draft a 2-sentence follow-up email.

## Files

- Tracker: `PROJECTS/$GITHUB_ORG-profile/job-hunt/tracker.csv`
- Resume bullets: `PROJECTS/$GITHUB_ORG-profile/job-hunt/RESUME_BULLETS.md`
- Cover letters: `PROJECTS/$GITHUB_ORG-profile/job-hunt/COVER_LETTERS.md`
- LinkedIn fix: `PROJECTS/$GITHUB_ORG-profile/promotion/LINKEDIN_FIX_NOW.md`
- Case study: `PROJECTS/$GITHUB_ORG-profile/promotion/CASE_STUDY_your organization_GOVERNANCE.md`

## Chains

- After reaching 5/day → suggest `[end-session]` or next engineering task
- If proof pack items incomplete → suggest building them
- Weekly (Friday) → suggest `[weekly-review]` with job sprint metrics
