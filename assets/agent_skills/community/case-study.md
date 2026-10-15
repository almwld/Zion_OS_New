---
name: case-study
description: Generate a structured case study from project data with metrics and outcomes
version: 0.1.0
execution-mode: advisory
argument-hint: "<project_or_topic> [--format brief|full] [--audience technical|executive]"
category: sales-marketing
status: candidate
---
# case-study | Case Study Generator

## When to Use
- Building portfolio evidence for consulting pitches
- Creating content for hummbl.io service pages
- Preparing Anthropic partner application supporting materials
- Newsletter or blog content from real project work
- Sales collateral for governance consulting engagements

## Execution

### 1. Gather Project Data
From `$ARGUMENTS` project, collect:
- Git history: first commit date, total commits, contributors
- Test metrics: test count, coverage if available
- LOC: `find . -name "*.py" | xargs wc -l`
- Architecture: key directories, module count
- CI: workflow count, pass rate from recent runs
- Milestones: releases, PyPI publishes, key PRs

### 2. Identify Narrative Arc
- **Challenge**: What problem existed? What was the pain?
- **Approach**: What methodology or framework was chosen? Why?
- **Solution**: What was built? Key technical decisions.
- **Results**: Measurable outcomes. Before/after.
- **Lessons**: What would be done differently?

### 3. Draft Case Study

**Brief format (1 page):**
- 1 paragraph per section
- 3-5 key metrics in a callout box
- Single testimonial placeholder

**Full format (2-3 pages):**
- 2-3 paragraphs per section
- Architecture diagram description
- Detailed metrics table
- Timeline of milestones
- Testimonial + attribution placeholder

### 4. Metrics Extraction
Pull real numbers -- never fabricate:
- Test count from `pytest --collect-only`
- LOC from actual file counts
- CI pass rate from `gh run list`
- Timeline from git log
- Label estimates as "ESTIMATE" per rule 11

### 5. Audience Adaptation
- **Technical**: include architecture details, code patterns, tooling choices
- **Executive**: focus on outcomes, risk reduction, time savings, ROI

## Output & Persistence

Case studies must be saved to the central registry:
* **Destination**: `~/.agents/docs/case-studies/<domain>/cs-<dom>-<slug>.md`
  (where `<domain>` is one of `commercial`, `governance`, `engineering`, or `research`).
* **Post-Drafting Action**: Run `python3 ~/.agents/scripts/index_case_studies.py` to regenerate `index.json` and `README.md`.
* **Verification**: Run `[case-study-verify] ~/.agents/docs/case-studies/<domain>/cs-<dom>-<slug>.md` to validate factual patterns.

```markdown
---
id: cs-<dom>-<slug>-001
title: "<Project Name>: <One-line Outcome Statement>"
domain: <commercial|governance|engineering|research>
audience: <technical|executive>
date: YYYY-MM-DD
status: draft
verification_level: R1
---

# <Project Name>: <One-line Outcome Statement>

### Challenge
<2-3 sentences describing the problem>

### Approach
<2-3 sentences on methodology and key decisions>

### Solution
<3-4 sentences on what was built>

**Key Architecture Decisions:**
- Decision 1: rationale
- Decision 2: rationale

### Results

| Metric              | Before | After   | Change    |
|---------------------|--------|---------|-----------|
| Test coverage       | 0%     | 85%     | +85%      |
| Deploy confidence   | Low    | High    | Automated |
| Governance controls | 0      | 20      | +20       |
| Incident response   | Hours  | Minutes | -90%      |

### Lessons Learned
1. <lesson>
2. <lesson>

---
*Generated from project data. Metrics are VERIFIED_LOCAL unless marked ESTIMATE.*
```

## Skill Chains
- After case study -> `[case-study-verify]` to validate factual claims
- After verification -> `[social-post]` to promote
- After case study -> `[newsletter-submit]` with the content
- Need SEO optimization -> `[seo-check]` on published version
- For sales use -> pair with `[nist-map]` for compliance angle
