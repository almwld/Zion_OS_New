---
provider-specific: true
name: vendor-ai-review
description: AI governance due diligence review for a vendor or third-party AI tool. Grades transparency, controls, contractual protections, and regulatory alignment. Saves to _internal/compliance/. Powered by compliance-advisor agent.
version: 1.0.0
execution-mode: advisory
argument-hint: "\"VENDOR\" \"PRODUCT\" [--use-case \"...\"] [--risk-tier high|medium|low] [--output scorecard|full]"
category: governance-compliance
status: candidate
---
# Vendor AI Review

Conduct governance due diligence on a third-party AI tool or vendor. Grades transparency, security controls, contractual protections, and regulatory alignment before procurement.

## When to Use

- Before procuring any AI tool that processes customer data, makes decisions, or assists regulated processes
- When an existing AI vendor relationship needs governance review
- When a board or compliance committee asks "what AI tools are we using and are they safe?"
- During M&A due diligence when the target uses AI in core operations
- When a regulator asks about third-party model risk

## Required Inputs

| Field | Example |
|-------|---------|
| Vendor name | OpenAI / Salesforce / Workday / Cohere / Vendor X |
| Product | ChatGPT Enterprise / Einstein GPT / AI recruitment tool |
| Use case | Customer support / Financial analysis / Hiring decisions |
| Data shared | Customer PII / Employee data / Financial records / None |
| Decision impact | Low (informational) / Medium (influenced decision) / High (automated decision) |
| Regulatory context | FINRA / HIPAA / FCRA / GDPR / EU AI Act / None specified |
| Vendor documentation | [Provide AI transparency card, terms, DPA, security report if available] |

## Supadata Vendor Research

Before filling the scorecard, scrape vendor documentation directly:

```bash
export SUPADATA_API_KEY="$(cat ~/supadata\ api.txt | grep sd_)"

# Fetch vendor's AI policy / transparency page
python3 ~/bin/supadata.py scrape "https://vendor.com/ai-policy"

# Fetch terms of service and privacy policy
python3 ~/bin/supadata.py scrape "https://vendor.com/terms"
python3 ~/bin/supadata.py scrape "https://vendor.com/privacy"

# Discover documentation pages (security, DPA, SOC 2 reports)
python3 ~/bin/supadata.py map "https://vendor.com/trust"
python3 ~/bin/supadata.py map "https://vendor.com/security"

# For vendors with changelogs — find recent AI-related changes
python3 ~/bin/supadata.py scrape "https://vendor.com/changelog"

# Crawl vendor docs for AI-specific claims (cap depth to avoid credit burn)
python3 ~/bin/supadata.py crawl "https://docs.vendor.com" --max-pages 15
```

**Why**: Vendor AI reviews are only as good as the documentation you can verify. Supadata lets you scrape terms, privacy policies, security pages, and changelogs directly — then extract specific AI governance claims for the scorecard. Without it, you're grading on what the vendor chooses to tell you.

## Vendor AI Review Format

```
VENDOR AI REVIEW
Vendor:     [Name]
Product:    [Name + version]
Use Case:   [Description]
Date:       [Review date]
Reviewer:   compliance-advisor (HUMMBL AI)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

PROCUREMENT RECOMMENDATION
[APPROVE / APPROVE WITH CONDITIONS / DEFER PENDING DOCUMENTATION / DO NOT APPROVE]
[One sentence: the primary reason for this recommendation]

OVERALL GOVERNANCE SCORE: [A / B / C / D / F]

────────────────────────────────────────────────────────
SCORECARD

| Domain | Score | Key Finding |
|--------|-------|-------------|
| Transparency & Explainability | [A-F] | [Finding] |
| Data Governance | [A-F] | [Finding] |
| Security Controls | [A-F] | [Finding] |
| Human Oversight | [A-F] | [Finding] |
| Contractual Protections | [A-F] | [Finding] |
| Regulatory Alignment | [A-F] | [Finding] |
| Incident Response | [A-F] | [Finding] |

────────────────────────────────────────────────────────
TRANSPARENCY & EXPLAINABILITY
Model documentation:  [Available / Partial / None]
Training data:        [Disclosed / Partial / Undisclosed]
Output explainability: [High / Medium / Low / None]
Bias testing:         [Published results / Claims testing / No evidence]
AI product card:      [Available / Not available]

Assessment:
[Does the vendor provide adequate transparency for this use case? Specific gaps?]

────────────────────────────────────────────────────────
DATA GOVERNANCE
Data used for training: [Yes — opt-out available / Yes — no opt-out / No / Unknown]
Data processing agreement: [Signed / Available / Not provided]
Data residency:          [US only / EU available / Unknown]
Data retention:          [Policy stated / Unclear / No policy]
Right to erasure:        [Supported / Partial / Not supported]
Sub-processors:          [Listed / Disclosed on request / Undisclosed]

Key data risks:
[List specific data governance concerns for this use case]

────────────────────────────────────────────────────────
SECURITY CONTROLS
SOC 2 Type II:    [Current / Expired / Not available]
ISO 27001:        [Certified / In progress / Not certified]
Pen testing:      [Annual / On request / Unknown]
OWASP LLM mitigations: [Documented / Partial / Not documented]
Vulnerability disclosure: [Published policy / On request / None]

────────────────────────────────────────────────────────
HUMAN OVERSIGHT
Can outputs be overridden: [Yes / Partial / No]
Audit trail:              [Full / Partial / None]
Human review requirement: [Enforced / Optional / No mechanism]
Kill switch:              [Immediate / With notice / None]

────────────────────────────────────────────────────────
CONTRACTUAL PROTECTIONS REQUIRED
Before procurement, ensure the contract includes:

[ ] AI-specific data processing agreement (not just standard DPA)
[ ] No training on customer data without explicit consent
[ ] Incident notification within 72 hours (GDPR standard)
[ ] Right to audit (or right to audit report)
[ ] Liability for AI-specific harms (not just general indemnification)
[ ] SLA for AI system availability and accuracy degradation notification
[ ] Exit rights if governance standards change materially
[ ] Right to receive updated bias/fairness testing results annually

Gaps in current contract (if reviewed):
[List specific missing clauses found in draft contract]

────────────────────────────────────────────────────────
REGULATORY ALIGNMENT
EU AI Act:   [Prohibited / High-risk requires conformity / Limited / Minimal / Unknown]
Industry-specific: [Applicable regulations and vendor compliance status]
Certifications: [List any third-party certifications vendor holds]

────────────────────────────────────────────────────────
OPEN QUESTIONS FOR VENDOR
Before approving procurement, request:
1. [Document or clarification needed]
2. [Document or clarification needed]
3. [Document or clarification needed]

────────────────────────────────────────────────────────
CONDITIONS FOR APPROVAL (if applicable)
If APPROVE WITH CONDITIONS:
1. [Condition — what must be in place before go-live]
2. [Condition]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

AI GOVERNANCE RECEIPT
Document type:  Vendor AI Review
Vendor:         [Name / Product]
Generated:      [Date]
Agent:          compliance-advisor (claude-opus-4-6)
Frameworks:     NIST AI RMF, OWASP LLM Top 10, EU AI Act, SOC 2, ISO 27001
Attestation:    DRAFT — requires qualified procurement/legal review before finalizing
Estimated human equivalent: $600-1,500 (AI risk officer + procurement counsel, 3-6 hrs)
Time saved:     3-6 hours
Confidence:     Medium — gaps exist where vendor documentation was unavailable
⚠ Not legal advice. Contract terms must be reviewed by qualified legal counsel.
```

## Human Cost Equivalent

- Lightweight scorecard (standard SaaS tool): $300-600
- Full vendor AI review (high-risk system): $600-1,500
- Enterprise AI vendor management program (all vendors): $5,000-15,000

## Skill Chains

- `[vendor-ai-review]` → `[nda-draft]` (if vendor requires NDA before sharing documentation)
- `[vendor-ai-review]` → `[contractor-agreement]` or `[service-agreement]` (add AI governance clauses)
- `[vendor-ai-review]` → `[ai-risk-assessment]` (assess the deployed system after procurement)
- `[vendor-ai-review]` → `[governance-report]` (include vendor risk in board update)
- Annually → re-run `[vendor-ai-review]` on high-risk vendors
