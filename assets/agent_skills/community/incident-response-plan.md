---
name: incident-response-plan
description: Build an AI-specific incident response plan — detection, classification, containment, notification, and post-incident review. NIST AI RMF MANAGE function aligned. Saves to _internal/compliance/. Powered by compliance-advisor agent.
version: 1.0.0
execution-mode: side_effecting
argument-hint: "\"ORGANIZATION\" [--scope system|enterprise] [--ai-types llm|classifier|generative|all] [--regulatory context]"
category: governance-compliance
status: tested
providers:
  required: [bash, python]
---
# AI Incident Response Plan

### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=incident-response-plan] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

Build a complete AI-specific incident response plan — covering detection, classification, escalation, containment, notification, remediation, and post-incident review.

## When to Use

- Building initial AI governance infrastructure (every AI deployment needs an IRP)
- After an AI incident or near-miss (update plan with lessons learned)
- When a CISO, board, or regulator asks "what happens when your AI makes a mistake?"
- When onboarding a high-risk AI system into production
- When updating the general IT incident response plan to cover AI-specific scenarios

## Required Inputs

| Field | Example |
|-------|---------|
| Organization | ACME Corp |
| AI systems in scope | Customer chatbot, fraud detection model, LLM-assisted underwriting |
| Regulatory context | FINRA / HIPAA / GDPR / EU AI Act / General commercial |
| Existing IR structure | General IT incident response team / No IR function / CISO-led |
| Key stakeholders | CISO, Chief Data Officer, General Counsel, PR / Comms |
| Notification obligations | 72-hour GDPR / 30-day HIPAA / No formal obligation |

## AI Incident Response Plan Format

```
AI INCIDENT RESPONSE PLAN
Organization:   [Name]
Version:        1.0
Effective:      [Date]
Owner:          [Title — e.g., Chief AI Officer / CISO / VP Engineering]
Next review:    [Date — recommend annual or after any AI incident]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

SCOPE
AI systems covered:    [List systems by name/type]
Incident types:        [See classification below]
Exclusions:            [General IT incidents not involving AI — covered by separate IRP]

────────────────────────────────────────────────────────
INCIDENT CLASSIFICATION

SEVERITY 1 — CRITICAL (respond within 1 hour)
- AI system produces output that causes direct harm to a person
- Personal data exposed due to AI system failure or prompt injection
- AI system is compromised (adversarial attack, model poisoning)
- Autonomous AI takes action that causes material financial loss
- Regulatory reportable incident (GDPR Art. 33, HIPAA Breach Rule)

SEVERITY 2 — HIGH (respond within 4 hours)
- AI system produces systematically biased outputs affecting protected classes
- AI system makes automated decisions with unexpectedly high error rate
- AI system behavior deviates materially from validated baseline
- Third-party AI vendor incident that affects your systems

SEVERITY 3 — MEDIUM (respond within 24 hours)
- AI system produces outputs that are factually incorrect in high-stakes context
- Drift detected in model performance metrics (below threshold but trending)
- User complaint about potential AI discrimination (single case)
- Third-party AI vendor discloses data breach not confirmed to affect your data

SEVERITY 4 — LOW (respond within 5 business days)
- AI system produces incorrect but non-harmful outputs
- User experience issue attributable to AI behavior
- Near-miss (incident that almost happened — document and learn)

────────────────────────────────────────────────────────
RESPONSE PHASES

PHASE 1 — DETECTION & REPORTING
Who can report:  Any employee, customer, or automated monitoring alert
How to report:   [Reporting channel — ticketing system, email alias, hotline]
Response SLA:    Acknowledge within [X hours] based on severity tier

Initial questions to answer immediately:
□ Which AI system is involved?
□ What happened? (human harm / data exposure / erroneous output / security breach)
□ Who is affected and how many people?
□ Is the system still running?
□ Is there an immediate regulatory notification obligation?

────────────────────────────────────────────────────────
PHASE 2 — TRIAGE & ESCALATION

Incident Commander: [Role] — responsible for all decisions during active incident
Technical Lead:     [Role] — owns containment and investigation
Legal/Compliance:   [Role] — owns notification obligations and privilege
Comms:              [Role] — owns internal and external communications

Escalation matrix:
| Severity | Initial responder | Escalate to | Executive notify |
|----------|-----------------|-------------|-----------------|
| 1 — Critical | On-call engineer | Incident Commander + Legal + CISO | CEO + Board (within 2 hrs) |
| 2 — High | On-call engineer | Incident Commander + Legal | CISO (within 4 hrs) |
| 3 — Medium | Assigned engineer | Team lead | CISO (within 24 hrs) |
| 4 — Low | Assigned engineer | Team lead | Not required |

────────────────────────────────────────────────────────
PHASE 3 — CONTAINMENT

Immediate containment options (select based on risk):
□ Kill switch — disable AI system entirely (Severity 1 default)
□ HITL override — route all outputs to human review before action
□ Output suppression — suspend specific output type or use case
□ Input filtering — add temporary guard against identified attack vector
□ Rate limiting — reduce throughput to limit blast radius
□ Rollback — revert to previous model version if drift/attack suspected

Containment decision authority:
| Action | Authority required |
|--------|------------------|
| Kill switch | Incident Commander |
| HITL override | Technical Lead |
| Output suppression | Technical Lead |
| Input filtering | Senior engineer |
| Rollback | Incident Commander + Technical Lead |

────────────────────────────────────────────────────────
PHASE 4 — INVESTIGATION & EVIDENCE PRESERVATION

Preserve immediately:
□ Model inference logs for the incident window
□ Input prompts / queries that triggered the incident
□ Model version and configuration at time of incident
□ Any monitoring alerts that fired
□ User reports and timestamps

Investigation questions:
□ Root cause: model failure / prompt injection / data poisoning / training defect / human misuse?
□ Scope: single instance / systemic / limited to specific input patterns?
□ Impact: how many people / decisions / outputs were affected?
□ Existing controls: which controls failed to prevent this?

────────────────────────────────────────────────────────
PHASE 5 — NOTIFICATION OBLIGATIONS

GDPR (if EU personal data involved):
  □ Notify supervisory authority within 72 hours of becoming aware
  □ Notify affected individuals if high risk to their rights
  □ Document in breach register regardless of notification obligation

HIPAA (if protected health information involved):
  □ Notify affected individuals within 60 days
  □ Notify HHS within 60 days (same as individual notification)
  □ If >500 individuals: notify prominent media outlets in affected state

Industry-specific:
  □ [Financial services: notify prudential regulator per applicable guidance]
  □ [Federal: notify agency CIO per FISMA requirements]
  □ [EU AI Act high-risk: notify national authority per applicable timeline]

Customer/stakeholder notification:
  □ Template: [Link to pre-approved notification template]
  □ Authority to send: [Legal / CEO / CISO]
  □ Timing: [Within X hours of confirmed incident]

────────────────────────────────────────────────────────
PHASE 6 — REMEDIATION & RECOVERY

Before restoring normal operations:
□ Root cause identified and documented
□ Fix validated in non-production environment
□ Legal/compliance cleared to restore
□ Monitoring enhanced for recurrence detection
□ Incident Commander authorizes restart

Recovery criteria:
[Specific conditions that must be met before the AI system resumes normal operation]

────────────────────────────────────────────────────────
PHASE 7 — POST-INCIDENT REVIEW (within 5 business days)

Post-incident review outputs:
□ Incident report (internal) — full timeline, root cause, impact
□ Lessons learned document — what the IRP missed, what worked
□ Control improvements — what new controls prevent recurrence
□ Policy/procedure updates — does the IRP need revision?
□ Board/audit summary (for Severity 1-2 incidents)

────────────────────────────────────────────────────────
CONTACT LIST
Role | Name | Primary contact | Backup contact
Incident Commander | [Name] | [Phone/email] | [Backup]
Technical Lead | [Name] | [Phone/email] | [Backup]
Legal Counsel | [Name] | [Phone/email] | [Backup]
PR/Comms | [Name] | [Phone/email] | [Backup]
Regulator hotline | [Regulator] | [Phone/portal] | —
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

AI GOVERNANCE RECEIPT
Document type:  AI Incident Response Plan
Organization:   [Name]
Generated:      [Date]
Agent:          compliance-advisor (<model>)
Frameworks:     NIST AI RMF (MANAGE), GDPR Art. 33-34, HIPAA Breach Rule
Attestation:    DRAFT — requires qualified legal and operational review before activation
Estimated human equivalent: $1,200-2,500 (CISO + AI counsel, 6-12 hrs)
Time saved:     6-12 hours
Confidence:     Medium — notification timelines and authorities must be verified for jurisdiction
⚠ Not legal advice. Notification obligations are jurisdiction-specific. Verify with qualified counsel.
```

## Human Cost Equivalent

- AI IRP for single system: $600-1,200
- Enterprise AI IRP (all systems): $1,200-2,500
- Full IR program build (IRP + tabletop + training): $3,000-8,000

## Skill Chains

### Mandatory

None — this skill generates a plan document; no upstream chain is required before producing the output.

### Advisory

- `[incident-response-plan]` → `[ai-risk-assessment]` (risk assessment informs which severity tiers to emphasize)
- `[incident-response-plan]` → `[governance-report]` (include IRP status in board summary)
- After an actual incident → `[aar]` (after-action review to improve the plan)
- `[incident-response-plan]` → `[runbook-write]` (ops runbook for the technical response steps)
- Annually → tabletop exercise against this plan (`[chaos-test]` for AI scenario)

## Authority

- **T1 (TRUSTED)**: Full access — generate and save IRP document
- **T2 (Active/High)**: Full access — generate and save IRP document
- **T3 (Medium)**: Operator approval required before generating IRP
- **T4 (Probationary)**: May run — file generation only (document output)
- **Operator**: Override any restriction
