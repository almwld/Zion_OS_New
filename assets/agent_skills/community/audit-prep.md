---
name: audit-prep
description: Prepare for external audit -- evidence checklist, gap identification, document organization, timeline
version: 0.1.0
execution-mode: advisory
argument-hint: "[--framework nist|soc2|iso|custom] [--date AUDIT_DATE]"
category: governance-compliance
status: candidate
---
# Audit Prep

Prepare for an external audit by generating an evidence checklist, identifying documentation gaps, organizing artifacts, and building a timeline. Covers framework-specific requirements and maps existing controls to audit expectations.

## When to Use
- An external audit is scheduled and you need to prepare evidence
- Pre-audit readiness assessment to identify gaps before the auditor arrives
- Organizing governance artifacts across multiple frameworks
- Building a timeline for audit milestones and evidence collection deadlines

## Execution
1. Parse `$ARGUMENTS` for `--framework` (default: nist) and `--date` of the audit.
2. Load the framework's control requirements (NIST CSF 2.0, SOC 2 TSC, ISO 27001/42001).
3. For each control area, check for existing evidence: policies, procedures, logs, test results, configurations.
4. Scan existing artifacts: governance bus logs, ADRs, test reports, security scans, IDP governance logs.
5. Generate evidence checklist with status: READY (evidence exists and is current), PARTIAL (evidence exists but incomplete or stale), MISSING (no evidence found).
6. If `--date` provided: build a countdown timeline with milestones for evidence collection, internal review, and mock audit.
7. Identify high-risk gaps that could lead to findings or non-conformities.

## Output Format
```
Audit Prep | NIST CSF 2.0 | Audit date: 2026-05-15

Evidence Readiness: 67% (42/63 controls covered)

| Category | Controls | Ready | Partial | Missing | Status |
|----------|----------|-------|---------|---------|--------|
| Govern (GV) | 12 | 8 | 3 | 1 | PARTIAL |
| Identify (ID) | 10 | 7 | 2 | 1 | PARTIAL |
| Protect (PR) | 15 | 12 | 2 | 1 | PARTIAL |
| Detect (DE) | 10 | 8 | 1 | 1 | PARTIAL |
| Respond (RS) | 8 | 4 | 2 | 2 | AT RISK |
| Recover (RC) | 8 | 3 | 2 | 3 | AT RISK |

High-Risk Gaps:
- [MISSING] RS.AN-03: No documented incident analysis procedure
- [MISSING] RC.RP-01: No recovery plan tested in last 12 months
- [PARTIAL] GV.PO-02: AI governance policy drafted but not approved

Timeline (47 days to audit):
- Week 1-2: Draft missing policies (RS.AN-03, RC.RP-01)
- Week 3-4: Collect and organize evidence artifacts
- Week 5: Internal mock audit review
- Week 6: Address mock audit findings
- Day of: Evidence package ready

Next action: Start with RS.AN-03 -- draft incident analysis procedure.
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| Evidence gaps found | `[compliance-calendar]` to track collection deadlines |
| Inherits context from | `[evidence-pack]` for existing artifact bundles |
| Framework gaps identified | `[gap-analysis]` for detailed control-level analysis |
