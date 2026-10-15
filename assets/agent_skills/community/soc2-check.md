---
name: soc2-check
description: SOC 2 Type II readiness assessment against trust service criteria
version: 0.1.0
execution-mode: advisory
argument-hint: "<criteria: Security|Availability|PI|Confidentiality|Privacy|all>"
category: governance-compliance
status: candidate
---
# [soc2-check]

## When to Use
- Preparing for a SOC 2 Type II audit engagement
- Client asks "how SOC 2 ready are we?"
- Before scoping an audit with an assessor
- Quarterly self-assessment of control posture

## Execution

### 1. Identify Target Scope
Parse `$ARGUMENTS` for specific trust service criteria. Default: all five.
- **Security** (CC1-CC9): logical/physical access, system operations, change management, risk mitigation
- **Availability** (A1): uptime, disaster recovery, capacity planning
- **Processing Integrity** (PI1): accuracy, completeness, timeliness
- **Confidentiality** (C1): data classification, encryption, retention
- **Privacy** (P1-P8): notice, choice, collection, use, access, disclosure, quality, monitoring

### 2. Evidence Collection
For each criterion, check:
```bash
# Access controls
grep -r "auth\|permission\|token\|rbac" $PROJECT_ROOT/services/ --include="*.py" -l
# Logging/monitoring
grep -r "audit\|log\|event_store\|governance_bus" $PROJECT_ROOT/services/ --include="*.py" -l
# Change management
git log --oneline -20
gh pr list --state merged --limit 10
# Encryption
grep -r "hmac\|sha256\|encrypt\|tls\|ssl" $PROJECT_ROOT/ --include="*.py" -l
# Circuit breakers / availability
grep -r "circuit_breaker\|kill_switch\|health" $PROJECT_ROOT/services/ --include="*.py" -l
```

### 3. Control Mapping
Map discovered controls to SOC 2 criteria. Score each:
- **IMPLEMENTED**: control exists with evidence
- **PARTIAL**: control exists but gaps in documentation or monitoring
- **MISSING**: no control or evidence found
- **N/A**: criterion not applicable to scope

### 4. Gap Analysis
For each PARTIAL or MISSING control:
- Describe the gap
- Estimate remediation effort (hours)
- Assign priority (P1/P2/P3)
- Suggest specific implementation

## Output Format

```
SOC 2 Check | <scope> | <date>
============================================

Trust Service Criteria Assessment
---------------------------------

SECURITY (CC)
  CC1.1 Control Environment     [IMPLEMENTED] governance_bus.py audit log
  CC6.1 Logical Access           [PARTIAL]     delegation_token.py exists, no RBAC
  CC7.1 System Operations        [IMPLEMENTED] health.py 8 probes, circuit_breaker.py

AVAILABILITY (A)
  A1.1 Processing Capacity       [PARTIAL]     no load testing evidence
  A1.2 Recovery Objectives       [MISSING]     no documented RTO/RPO

Summary
-------
  Implemented: 14/32 (44%)
  Partial:      9/32 (28%)
  Missing:      7/32 (22%)
  N/A:          2/32 (6%)

Top Gaps (by priority)
----------------------
  P1: [CC6.1] RBAC enforcement -- ~8hr remediation
  P1: [A1.2]  Recovery objectives -- ~4hr documentation

Readiness: NOT READY / PARTIAL / AUDIT-READY
Next action: <specific recommendation>
```

## Skill Chains
- After `[soc2-check]` -> `[iso-crosswalk]` to map controls across frameworks
- After `[soc2-check]` -> `[compliance-calendar]` to schedule remediation deadlines
- After `[soc2-check]` -> `[threat-model]` for deeper security analysis
