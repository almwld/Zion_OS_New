---
name: policy-draft
description: Draft internal policies -- AI acceptable use, data handling, incident response, access control
version: 0.1.0
execution-mode: advisory
argument-hint: "<policy_type> [--audience internal|client] [--template standard|minimal]"
category: governance-compliance
status: candidate
---
# Policy Draft

Draft structured internal policies covering AI acceptable use, data handling, incident response, access control, and other governance areas. Produces professional policy documents with standard sections, review workflows, and version tracking.

## When to Use
- Creating a new internal policy from scratch
- Updating an existing policy to meet new regulatory requirements
- Drafting a client-facing policy document for an engagement
- Filling a gap identified by a governance audit or compliance check

## Execution
1. Parse `$ARGUMENTS` for policy type, `--audience` (default: internal), and `--template` (default: standard).
2. Select the appropriate policy template based on type: AI acceptable use, data handling, incident response, access control, change management, vendor management.
3. **Supadata research** — scrape reference policies and templates for best-practice language:
   ```bash
   export SUPADATA_API_KEY="$(cat ~/supadata\ api.txt | grep sd_)"
   # Scrape NIST's template/resource pages for policy structure
   python3 ~/bin/supadata.py scrape "https://www.nist.gov/itl/ai-ri[REDACTED_API_KEY]"
   # Scrape regulatory requirements that policies must address
   python3 ~/bin/supadata.py scrape "https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX:32024R1689"
   # Scrape industry-standard policy templates (e.g., SANS, CIS)
   python3 ~/bin/supadata.py scrape "https://www.sans.org/information-security-policy"
   # Crawl a competitor's trust center for benchmarking
   python3 ~/bin/supadata.py crawl "https://vendor.com/trust" --max-pages 10
   ```
4. For `standard` template: include purpose, scope, definitions, roles and responsibilities, policy statements, procedures, exceptions, enforcement, review schedule.
4. For `minimal` template: include purpose, scope, key policy statements, and review schedule.
5. Pre-fill with organization-specific context from existing docs (CLAUDE.md, governance artifacts).
6. For `client` audience: adjust tone, add confidentiality notice, include regulatory references.
7. Mark sections requiring human review with [REVIEW NEEDED] tags.
8. Include version tracking header and approval workflow.

## Output Format
```
Policy Draft | AI Acceptable Use Policy | internal | standard

---
Policy: AI Acceptable Use Policy
Version: 1.0-DRAFT
Author: [REVIEW NEEDED]
Effective Date: [REVIEW NEEDED]
Review Cycle: Annual
---

1. PURPOSE
This policy establishes acceptable use guidelines for AI systems...

2. SCOPE
Applies to all team members and AI agents operating within...

3. DEFINITIONS
- AI System: [definition]
- High-Risk Use: [definition]

4. ROLES AND RESPONSIBILITIES
[REVIEW NEEDED] - assign specific roles

5. POLICY STATEMENTS
5.1 All AI-generated output must be reviewed before...
5.2 No AI system may access production data without...

[... remaining sections ...]

Review Items: 3 sections marked [REVIEW NEEDED]

Next action: Review and fill [REVIEW NEEDED] sections, then route for approval.
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| Policy drafted | `[legal-check]` for legal review of language |
| Policy for client | `[assessment-report]` to include in deliverables |
| Policy content ready | `[content-review]` for tone and accuracy check |
