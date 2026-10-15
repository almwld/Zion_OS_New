---
name: newsletter-submit
description: Prepare and track newsletter submissions to Python Weekly, PyCoders, and awesome lists
version: 0.1.0
execution-mode: side_effecting
argument-hint: "<project_or_topic> [--outlet python-weekly|pycoders|awesome-list] [--track]"
category: sales-marketing
status: candidate
---
# newsletter-submit | Newsletter Submission Workflow

## When to Use
- After shipping a notable feature or release
- When a project hits a maturity milestone (PyPI publish, 1000+ tests)
- Weekly/biweekly submission cadence for visibility
- After creating a blog post or case study to amplify

## Execution

### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=newsletter-submit] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

### 1. Select Outlet
- **Python Weekly**: https://pythonweekly.com/submit -- community newsletter, ~25K subscribers
- **PyCoder's Weekly**: https://pycoders.com/submissions -- curated, high signal
- **Awesome Python**: PR to github.com/vinta/awesome-python -- permanent listing
- **Awesome lists**: topic-specific (awesome-ai-governance, awesome-mcp, etc.)

### 2. Gather Project Data
From repo metadata:
- Project name, URL, description
- Key metrics: tests, LOC, version, Python versions supported
- Unique angle: stdlib-only, multi-agent, governance focus
- Recent notable changes (from CHANGELOG or recent commits)

### 3. Draft Submission (per outlet)

**Python Weekly / PyCoder's Weekly template:**
```
Title: <concise, benefit-focused title>
URL: <repo or blog post URL>
Category: [Library/Tool/Article/Tutorial]
Description: <2-3 sentences. What it does, why it matters, what's unique.>
```

**Awesome list PR template:**
```
- [project-name](url) - One-line description emphasizing unique value.
```

### 4. Pre-Submit Checklist
- [ ] README has clear install instructions
- [ ] README has usage examples
- [ ] CI badge is green
- [ ] PyPI package is published (if applicable)
- [ ] License file present
- [ ] No broken links in README

### 5. Track Submission (if --track)
Append to `_state/marketing/submissions.tsv`:
```
date	outlet	project	url	status	response_date	notes
```

## Output Format

```
newsletter-submit | <project>

## Submissions Prepared

### Python Weekly
- Title: hummbl-governance: Stdlib-Only AI Governance for Python
- URL: https://github.com/$GITHUB_ORG/hummbl-governance
- Category: Library
- Description: Zero-dependency governance toolkit for AI systems...
- Submit at: https://pythonweekly.com/submit

### PyCoder's Weekly
- Title: (same or adjusted)
- Submit at: https://pycoders.com/submissions

## Pre-Submit Checklist
- [x] README: clear install
- [x] CI: green
- [x] PyPI: published (v0.2.0)
- [ ] Blog post: not yet written

## Tracking
- Logged to _state/marketing/submissions.tsv
- Follow up: 7 days if no response
```

## Skill Chains

### Mandatory

- `[content-review]` MUST pass before submitting to any external outlet (Python Weekly, PyCoders, awesome lists). The submission draft may be prepared without it, but no external submission without a passed content review.

### Advisory

- Before submitting → `[seo-check]` on the README
- After submission accepted → `[social-post]` to amplify
- Need a blog post first → `[case-study]` to generate content

## Authority

- **T1 (TRUSTED)**: Full run — prepare and submit (with `[content-review]` pass)
- **T2 (Active/High)**: Prepare and submit with `[content-review]` pass
- **T3 (Medium)**: Prepare only; submission requires operator approval + `[content-review]` pass
- **T4 (Probationary)**: BLOCKED — may not prepare or submit newsletter submissions
- **Operator**: Override any restriction
