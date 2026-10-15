---
name: nist-map
description: Map controls to NIST CSF 2.0 and AI RMF categories with gap analysis
version: 0.1.0
execution-mode: advisory
argument-hint: "<project_or_control_set> [--framework csf|airmf|both] [--gaps-only]"
category: governance-compliance
status: candidate
---
# nist-map | NIST Framework Control Mapping

## When to Use
- Preparing governance assessments for clients
- Mapping hummbl-governance controls to NIST frameworks
- Gap analysis for compliance readiness
- Building crosswalk documentation for your organization services
- Supporting CCA-F certification study with practical mapping

## Execution

### 1. Identify Control Source
From `$ARGUMENTS`, determine what to map:
- Project controls (from code: kill switch, circuit breaker, governance bus, IDP)
- Client control inventory (from assessment output)
- hummbl-governance modules (from PyPI package)
- Custom control set (from provided list)

### 1.5 Fetch Canonical NIST Sources
Always map against the live NIST documentation, not cached/memorized text:

```bash
export SUPADATA_API_KEY="$(cat ~/supadata\ api.txt | grep sd_)"

# NIST CSF 2.0 — core document
python3 ~/bin/supadata.py scrape "https://www.nist.gov/cyberframework"

# NIST AI RMF 1.0 — full framework
python3 ~/bin/supadata.py scrape "https://www.nist.gov/itl/ai-ri[REDACTED_API_KEY]"

# NIST AI RMF Playbook — implementation guidance
python3 ~/bin/supadata.py scrape "https://airc.nist.gov/AI-RMF-Playbook"

# NIST SP 800-53 Rev 5 — security controls (cross-reference for tech infra)
python3 ~/bin/supadata.py scrape "https://csrc.nist.gov/publications/detail/sp/800-53/rev-5/final"

# Discover updates — NIST adds resources regularly
python3 ~/bin/supadata.py map "https://www.nist.gov/itl/ai-ri[REDACTED_API_KEY]"
```

**Why**: NIST updates frameworks, publishes new playbooks, and revises SPs without announcement. Mapping against stale documents produces stale compliance advice. Scrape the live pages before every assessment.

### 2. NIST CSF 2.0 Categories
Map each control to CSF 2.0 functions and categories:

| Function   | ID  | Categories                                    |
|------------|-----|-----------------------------------------------|
| GOVERN     | GV  | Organizational Context, Risk Management Strategy, Roles/Responsibilities, Policy, Oversight, Supply Chain |
| IDENTIFY   | ID  | Asset Management, Risk Assessment, Improvement |
| PROTECT    | PR  | Identity Management, Awareness/Training, Data Security, Platform Security, Technology Infra Resilience |
| DETECT     | DE  | Continuous Monitoring, Adverse Event Analysis  |
| RESPOND    | RS  | Incident Management, Incident Analysis, Incident Response Reporting, Incident Mitigation |
| RECOVER    | RC  | Incident Recovery Plan Execution, Incident Recovery Communication |

### 3. NIST AI RMF Categories (if --framework airmf or both)
Map to AI Risk Management Framework:

| Function   | Categories                                          |
|------------|-----------------------------------------------------|
| GOVERN     | Policies, Processes, Accountability, Culture         |
| MAP        | Context, Requirements, Benefits/Costs, Risks         |
| MEASURE    | Metrics, Assessment, Tracking, Feedback              |
| MANAGE     | Risk Response, Monitoring, Documentation, Prioritize |

### 4. Gap Analysis
For each framework category:
- **COVERED**: control exists and is implemented (cite evidence: file, test, CI)
- **PARTIAL**: control exists but incomplete (note what is missing)
- **GAP**: no control mapped to this category
- **N/A**: category not applicable to this context

### 5. Priority Rating
For each gap:
- **P1 (Critical)**: regulatory requirement or high-risk gap
- **P2 (Important)**: best practice, client expectation
- **P3 (Nice-to-have)**: maturity improvement, not urgent

## Output Format

```
nist-map | <project>

## Framework: NIST CSF 2.0 + AI RMF

## Control Inventory
- Controls mapped: 15
- Source: hummbl-governance v0.2.0 + your_project services

## CSF 2.0 Mapping

| CSF Category        | Control                  | Status  | Evidence                    |
|---------------------|--------------------------|---------|------------------------------|
| GV.RM (Risk Mgmt)  | Kill Switch              | COVERED | services/kill_switch_core.py |
| GV.OV (Oversight)   | Governance Bus           | COVERED | services/governance_bus.py   |
| PR.IR (Resilience)  | Circuit Breaker          | COVERED | services/circuit_breaker.py  |
| DE.CM (Monitoring)  | Health Probes            | COVERED | services/health.py (14 probes) |
| DE.AE (Analysis)    | Alert System             | PARTIAL | services/alerts.py (no ML anomaly) |
| RS.MI (Mitigation)  | --                       | GAP     | No automated incident response |
| RC.RP (Recovery)    | --                       | GAP     | No disaster recovery plan    |

## AI RMF Mapping

| AI RMF Category     | Control                  | Status  | Evidence                    |
|---------------------|--------------------------|---------|------------------------------|
| GOV.1 (Policies)    | Governance schemas       | COVERED | contracts/governance/        |
| MAP.1 (Context)     | Agent intent spec        | COVERED | services/agent_intent.py     |
| MEASURE.1 (Metrics) | Cost tracking            | COVERED | integrations/cost_tracker.py |
| MANAGE.2 (Monitor)  | Coordination bus         | COVERED | _state/coordination/         |

## Gap Analysis Summary
- COVERED: 11 (73%)
- PARTIAL: 2 (13%)
- GAP: 2 (13%)

## Priority Gaps
| Gap                      | Category | Priority | Recommendation                |
|--------------------------|----------|----------|-------------------------------|
| Incident response        | RS.MI    | P1       | Add automated rollback playbook |
| Disaster recovery        | RC.RP    | P2       | Document recovery procedures  |

## Next Actions
- [ ] P1: Implement incident response automation
- [ ] P2: Create disaster recovery documentation
```

## Skill Chains
- After mapping -> `[case-study]` to package findings for clients
- For deeper security -> `[security-scan]` and `[threat-model]`
- For client delivery -> pair with your organization compliance calendar
- For CCA-F study -> use as practical exercise material
