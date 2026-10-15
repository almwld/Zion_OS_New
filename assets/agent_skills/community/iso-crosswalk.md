---
name: iso-crosswalk
description: Cross-reference controls across ISO 27001, ISO 42001, NIST CSF, SOC 2
version: 0.1.0
execution-mode: advisory
argument-hint: "<frameworks: iso27001|iso42001|nist-csf|soc2|all> [--gaps-only]"
category: governance-compliance
status: candidate
---
# [iso-crosswalk]

## When to Use
- Client needs multi-framework compliance mapping
- Building a unified control matrix for audit preparation
- Identifying which controls satisfy multiple frameworks simultaneously
- Scoping new framework adoption when one is already in place

## Execution

### 1. Load Framework Definitions
Canonical control sets:
- **ISO 27001:2022** -- Annex A controls (93 controls, 4 themes: Organizational, People, Physical, Technological)
- **ISO 42001:2023** -- AI management system controls (Annex B objectives + Annex D risk controls)
- **NIST CSF 2.0** -- 6 functions (Govern, Identify, Protect, Detect, Respond, Recover)
- **SOC 2** -- 5 trust service criteria (Security CC1-CC9, Availability, PI, Confidentiality, Privacy)

### 2. Map Existing Controls
Scan the codebase and documentation for implemented controls:
```bash
# Governance controls
find $PROJECT_ROOT/services/ -name "*.py" | head -30
grep -r "governance\|policy\|audit\|compliance" your_project/ --include="*.py" -l
# Risk management
grep -r "risk\|threat\|vulnerability\|circuit_breaker\|kill_switch" your_project/ --include="*.py" -l
# AI-specific (ISO 42001)
grep -r "model\|inference\|bias\|fairness\|transparency" your_project/ --include="*.py" -l
# Check existing crosswalk data
find . -name "*crosswalk*" -o -name "*mapping*" -o -name "*compliance*" 2>/dev/null | head -10
```

### 3. Build Mapping Table
For each control, identify which framework requirements it satisfies. Mark coverage:
- **FULL**: control fully satisfies the requirement
- **PARTIAL**: control partially addresses it
- **GAP**: no corresponding control implemented
- **SHARED**: single control satisfies multiple frameworks

### 4. Gap Analysis
If `--gaps-only` flag: show only GAP and PARTIAL entries.
For each gap, identify the minimum effort to close it.

## Output Format

```
ISO Crosswalk | <frameworks> | <date>
============================================

Control Mapping Matrix
----------------------
Control                  | ISO 27001 | ISO 42001 | NIST CSF  | SOC 2
-------------------------|-----------|-----------|-----------|--------
governance_bus.py        | A.5.1     | B.2       | GV.OC-01  | CC1.1
  Audit logging          | FULL      | FULL      | FULL      | FULL
delegation_token.py      | A.8.3     | --        | PR.AA-01  | CC6.1
  Access control         | PARTIAL   | N/A       | PARTIAL   | PARTIAL
circuit_breaker.py       | A.8.14    | B.6       | RS.MI-01  | A1.1
  Resilience             | FULL      | PARTIAL   | FULL      | FULL

Coverage Summary
----------------
  ISO 27001: 34/93 controls mapped (37%)
  ISO 42001: 12/38 controls mapped (32%)
  NIST CSF:  28/106 subcategories mapped (26%)
  SOC 2:     14/32 criteria mapped (44%)

Shared Controls (highest ROI)
-----------------------------
  governance_bus.py satisfies 4 frameworks (audit logging)
  health.py satisfies 3 frameworks (monitoring)

Top Gaps
--------
  [GAP] ISO 42001 B.4 -- AI impact assessment: no implementation
  [GAP] NIST CSF ID.AM -- Asset management: no inventory

Next action: <recommendation>
```

## Skill Chains
- After `[iso-crosswalk]` -> `[soc2-check]` for deep-dive on SOC 2 gaps
- After `[iso-crosswalk]` -> `[compliance-calendar]` to schedule framework audits
- After `[iso-crosswalk]` -> `[threat-model]` for risk-based gap prioritization
