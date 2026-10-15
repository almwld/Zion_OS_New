---
name: governance-maturity
description: Score an organization's AI governance maturity on a 5-level scale with actionable roadmap.
version: 0.1.0
execution-mode: advisory
argument-hint: "[--org NAME] [--framework nist|iso|custom] [--depth quick|full]"
category: governance-compliance
status: candidate
---
# Governance Maturity

Assess AI governance maturity using a structured 5-level model. Core consulting deliverable for your organization -- used in initial assessments, proposals, and progress tracking.

## When to Use
- Initial client assessment meeting
- Proposal development (establish baseline, sell the roadmap)
- Progress tracking (re-assess after engagement)
- Internal self-assessment of hummbl-governance governance
- When user says "governance maturity" or "maturity assessment"

## Maturity Levels

| Level | Name | Description | Characteristics |
|-------|------|------------|----------------|
| 1 | **Ad Hoc** | No formal governance | No policies, no oversight, reactive only |
| 2 | **Emerging** | Awareness exists | Some policies written, no enforcement, sporadic reviews |
| 3 | **Defined** | Processes established | Documented policies, assigned roles, regular reviews |
| 4 | **Managed** | Metrics-driven | KPIs tracked, automated enforcement, continuous monitoring |
| 5 | **Optimizing** | Continuous improvement | Predictive controls, self-healing, industry leadership |

## Assessment Domains (8)

| Domain | What It Covers |
|--------|---------------|
| **Policy** | AI use policies, acceptable use, ethical guidelines |
| **Risk** | Risk identification, assessment, mitigation for AI systems |
| **Data** | Data governance, quality, privacy, consent, retention |
| **Model** | Model inventory, validation, monitoring, lifecycle |
| **Security** | AI-specific threats, adversarial robustness, access control |
| **Compliance** | Regulatory mapping, audit readiness, reporting |
| **People** | Roles, training, awareness, accountability |
| **Operations** | Incident response, change management, monitoring |

## Execution

### quick (15 min)
1. Score each domain 1-5 based on interview/evidence
2. Compute overall maturity (weighted average)
3. Output: maturity scorecard with radar chart

### full (60 min)
1. Detailed assessment per domain with sub-criteria
2. Evidence collection for each score
3. Gap analysis against target maturity
4. Roadmap with prioritized recommendations
5. Output: full assessment report

## Output Format

```
Governance Maturity | {org} | {framework}
==========================================

## Overall Maturity: Level {N} — {name}

## Domain Scores
| Domain | Score | Evidence | Gap to L{target} |
|--------|-------|----------|-------------------|
| Policy | 2 | Written but not enforced | Need enforcement mechanism |
| Risk | 1 | No formal risk assessment | Need risk register |
| Data | 3 | GDPR-compliant, DPA in place | Meets target |
| ...

## Maturity Radar
{ASCII radar chart or description}

## Roadmap to Level {target}
| Priority | Domain | Current | Target | Action | Effort | Timeline |
|----------|--------|---------|--------|--------|--------|----------|
| 1 | Risk | 1 | 3 | Implement risk register | Medium | 4 weeks |
| 2 | Security | 2 | 3 | Deploy input guardrails | Low | 2 weeks |

## Quick Wins (achieve in <2 weeks)
- {Low-effort, high-impact actions}

## Strategic Initiatives (2-6 months)
- {Larger efforts that move multiple domains}
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| Assessment done | `[gap-analysis]` (detailed gap work) |
| Low maturity found | `[proposal-write]` (sell the engagement) |
| For client | `[assessment-report]` (formal deliverable) |
| Internal use | `[evidence-pack]` (bundle our own evidence) |
| Re-assessment | `[decision-log]` (track progress over time) |
