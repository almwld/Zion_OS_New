---
name: gdpr-check
description: GDPR compliance audit -- data inventory, consent mechanisms, retention policies, right to erasure, DPAs
version: 0.1.0
execution-mode: advisory
argument-hint: "[--scope app|service|full] [--action audit|checklist]"
category: governance-compliance
status: candidate
---
# GDPR Check

Audit an application or service for GDPR compliance, covering data inventory, lawful basis for processing, consent mechanisms, data retention policies, right to erasure implementation, Data Processing Agreements, and cross-border transfer safeguards.

## When to Use
- Before launching a product or feature that handles EU personal data
- Periodic compliance review for existing services
- After a data handling change to verify continued compliance
- Preparing for a client engagement that requires GDPR compliance evidence

## Execution
1. Parse `$ARGUMENTS` for `--scope` (default: app) and `--action` (default: audit).
2. For `audit`: scan codebase for personal data handling patterns (email, name, IP, cookies, analytics).
3. Inventory data flows: collection points, storage locations, third-party sharing, retention periods.
4. Check for consent mechanisms: cookie banners, opt-in forms, preference centers.
5. Verify right to erasure: can user data be fully deleted? Are there orphaned references?
6. Check for Data Processing Agreements with third-party processors.
7. Review cross-border transfer mechanisms (SCCs, adequacy decisions).
8. For `checklist`: output a structured GDPR compliance checklist with pass/fail/unknown status.

## Output Format
```
GDPR Check | audit | app scope

| Area | Status | Finding |
|------|--------|---------|
| Data Inventory | PARTIAL | 3 collection points found, 1 undocumented |
| Lawful Basis | OK | Consent for marketing, legitimate interest for analytics |
| Consent Mechanism | WARNING | Cookie banner present but no granular opt-out |
| Right to Erasure | FAIL | User deletion endpoint missing from API |
| Retention Policy | OK | 90-day log retention, documented |
| DPAs | WARNING | No DPA on file for analytics provider |
| Cross-border Transfer | OK | EU-only hosting, no third-country transfers |

Score: 4/7 areas compliant | 2 warnings | 1 failure

Next action: Implement user deletion endpoint and obtain DPA from analytics provider.
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| Compliance gaps found | `[compliance-calendar]` to track remediation deadlines |
| Legal review needed | `[legal-check]` for license and IP concerns |
| State privacy laws also apply | `[privacy-audit]` for CCPA/state requirements |
