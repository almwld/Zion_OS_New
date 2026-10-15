---
name: ai-risk-assessment
description: Full AI system risk assessment aligned to NIST AI RMF. Maps risks across GOVERN/MAP/MEASURE/MANAGE, scores severity, and produces a board-ready audit artifact. Saves to _internal/compliance/. Powered by compliance-advisor agent.
version: 1.0.0
execution-mode: advisory
argument-hint: "\"SYSTEM_NAME\" \"USE_CASE\" [--framework nist|iso42001|eu-ai-act|all] [--tier high|limited|minimal]"
category: governance-compliance
status: candidate
---
# AI Risk Assessment

Produce a structured AI system risk assessment — risk identification, severity scoring, control gap analysis, and remediation priorities — aligned to NIST AI RMF or requested framework.

## When to Use

- Before deploying a new AI system into production
- After an AI incident or near-miss
- As part of a periodic governance review cycle
- When a board, auditor, or regulator asks "what are your AI risks?"
- During vendor due diligence (assess the system, not just the vendor)
- When a new LLM use case is being evaluated

## Required Inputs

| Field | Example |
|-------|---------|
| System name | Customer service chatbot / Fraud detection model / LLM-assisted underwriting |
| Use case | Automated loan decisioning / Claims triage / Employee productivity assistant |
| Model type | LLM (GPT-4o) / Classification model / Generative AI / Recommendation system |
| Data used | Customer PII / Medical records / Financial transactions / Public data |
| Decision type | Automated / Human-in-the-loop / Human-on-the-loop / Informational only |
| Affected population | External customers / Employees / Patients / Students |
| Regulatory context | Financial services / Healthcare / Federal / General commercial |
| Current controls | [What governance is already in place — or "none"] |

## Risk Assessment Format

```
AI RISK ASSESSMENT
System:     [Name]
Use Case:   [Description]
Date:       [Date]
Framework:  [NIST AI RMF / ISO 42001 / EU AI Act / combined]
Assessor:   compliance-advisor (HUMMBL AI)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

EXECUTIVE SUMMARY
[2-3 sentences: overall risk posture, most critical finding, immediate recommendation]
Overall risk rating: [Critical / High / Medium / Low]

────────────────────────────────────────────────────────
SYSTEM PROFILE
Model type:         [LLM / Classifier / Generative / Recommender / Ensemble]
Decision authority: [Automated / HITL / HOTL / Advisory]
Data sensitivity:   [PII / PHI / Financial / Proprietary / Public]
Affected parties:   [Who is impacted by the system's outputs]
EU AI Act tier:     [Prohibited / High-risk / Limited / Minimal risk]
NIST RMF context:   [Which RMF functions are most relevant to this system]

────────────────────────────────────────────────────────
RISK REGISTER

| Risk ID | Risk Category | Description | Likelihood | Impact | Severity | Control Status |
|---------|--------------|-------------|-----------|--------|----------|----------------|
| R-01 | [Category] | [Description] | H/M/L | H/M/L | [Score] | Adequate / Gap / Missing |
| R-02 | | | | | | |
...

Risk Categories: Algorithmic Bias · Data Quality · Security (OWASP LLM) · Privacy ·
Transparency · Human Oversight · Drift/Degradation · Third-Party Dependency ·
Regulatory Non-Compliance · Misuse/Abuse

────────────────────────────────────────────────────────
NIST AI RMF ALIGNMENT

GOVERN (Policies & accountability):
  [G1] AI risk governance policy exists: [✓ Adequate / ⚠ Partial / ✗ Missing]
  [G2] Roles and responsibilities defined: [✓ / ⚠ / ✗]
  [G3] AI risk tolerance documented: [✓ / ⚠ / ✗]
  [G4] Oversight mechanisms in place: [✓ / ⚠ / ✗]

MAP (Context & stakeholders):
  [M1] Use case impact assessment completed: [✓ / ⚠ / ✗]
  [M2] Affected populations identified: [✓ / ⚠ / ✗]
  [M3] Data provenance documented: [✓ / ⚠ / ✗]

MEASURE (Testing & monitoring):
  [ME1] Pre-deployment testing documented: [✓ / ⚠ / ✗]
  [ME2] Bias/fairness evaluation completed: [✓ / ⚠ / ✗]
  [ME3] Production monitoring active: [✓ / ⚠ / ✗]
  [ME4] Drift detection in place: [✓ / ⚠ / ✗]

MANAGE (Response & improvement):
  [MG1] Incident response plan exists: [✓ / ⚠ / ✗]
  [MG2] Model retirement/sunset criteria defined: [✓ / ⚠ / ✗]
  [MG3] Continuous improvement process: [✓ / ⚠ / ✗]

────────────────────────────────────────────────────────
OWASP LLM TOP 10 (if applicable)
[LLM01] Prompt injection:       [Risk level + control status]
[LLM02] Insecure output handling: [Risk level + control status]
[LLM03] Training data poisoning:  [Risk level + control status]
[LLM04] Model denial of service:  [Risk level + control status]
[LLM05] Supply chain vulnerabilities: [Risk level + control status]
[LLM06] Sensitive info disclosure: [Risk level + control status]
[LLM07] Insecure plugin design:   [Risk level + control status — if plugins used]
[LLM08] Excessive agency:         [Risk level + control status — if agentic]
[LLM09] Overreliance:             [Risk level + control status]
[LLM10] Model theft:              [Risk level + control status]

────────────────────────────────────────────────────────
CRITICAL FINDINGS (require immediate action)
1. [Finding — framework reference — business risk — recommended action]
2. [Finding]

HIGH FINDINGS (address within 90 days)
1. [Finding — framework reference — recommended action]

MEDIUM FINDINGS (address within 180 days)
1. [Finding]

────────────────────────────────────────────────────────
REMEDIATION ROADMAP
Priority 1 (Immediate — 0-30 days):
  [ ] [Action] — owner: [Role] — estimated effort: [Small/Medium/Large]
Priority 2 (Short-term — 30-90 days):
  [ ] [Action]
Priority 3 (Medium-term — 90-180 days):
  [ ] [Action]

────────────────────────────────────────────────────────
GOVERNANCE RECEIPT (append to system record)
Assessment completed: [Date]
Risk rating:          [Critical / High / Medium / Low]
Framework coverage:   [NIST AI RMF / ISO 42001 / OWASP LLM Top 10]
Open findings:        [N] Critical, [N] High, [N] Medium
Next review:          [Date — recommend annual or after material change]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

AI GOVERNANCE RECEIPT
Document type:  AI Risk Assessment
System:         [Name]
Generated:      [Date]
Agent:          compliance-advisor (<model>)
Frameworks:     NIST AI RMF, OWASP LLM Top 10 [+ others as applicable]
Attestation:    DRAFT — requires qualified AI risk officer review before regulatory use
Estimated human equivalent: $1,500-3,500 (AI risk officer + security analyst, 8-15 hrs)
Time saved:     8-15 hours
Confidence:     Medium — accuracy depends on completeness of system inputs provided
⚠ Not legal advice. Do not submit to regulators without human review and sign-off.
```

## Severity Scoring Matrix

| Likelihood \ Impact | Low | Medium | High |
|--------------------|-----|--------|------|
| High | Medium | High | Critical |
| Medium | Low | Medium | High |
| Low | Low | Low | Medium |

## Human Cost Equivalent

- Lightweight assessment (single system, limited scope): $800-1,500
- Full NIST AI RMF assessment: $1,500-3,500
- Full assessment + EU AI Act conformity: $3,000-6,000
- Enterprise-wide AI inventory + assessment: $8,000-20,000

## Skill Chains

- `[ai-risk-assessment]` → `[nist-map]` (detailed framework mapping)
- `[ai-risk-assessment]` → `[remediation-plan]` (build the fix roadmap)
- `[ai-risk-assessment]` → `[gap-analysis]` (compare to framework requirements)
- `[ai-risk-assessment]` → `[governance-report]` (board-ready summary)
- `[ai-risk-assessment]` → `[incident-response-plan]` (if high/critical rating)
- For vendor systems → `[vendor-ai-review]` (assess vendor's governance claims first)
