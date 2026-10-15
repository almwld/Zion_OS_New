---
name: privacy-audit
description: State privacy law scan (CCPA, CTDPA, VCDPA, etc.) for data handling practices
version: 0.1.0
execution-mode: advisory
argument-hint: "[--jurisdiction CA|CT|VA|CO|all] [--action audit|requirements]"
category: backend-infra
status: candidate
---
# Privacy Audit

Scan an application's data handling practices against US state privacy laws including CCPA/CPRA (California), CTDPA (Connecticut), VCDPA (Virginia), CPA (Colorado), and others. Identifies gaps in consumer rights implementation, disclosure requirements, and opt-out mechanisms.

## When to Use
- Expanding service to new US states with privacy laws
- Annual privacy compliance review
- After adding new data collection or processing activities
- Preparing privacy impact assessment for a new feature

## Execution
1. Parse `$ARGUMENTS` for `--jurisdiction` (default: all) and `--action` (default: audit).
2. For `requirements`: output the specific requirements for each selected jurisdiction.
3. For `audit`: scan codebase and configs for data collection points, storage, sharing, and sale.
4. Check consumer rights implementation per jurisdiction: access, deletion, correction, portability, opt-out of sale.
5. Verify privacy notice/policy covers required disclosures for each jurisdiction.
6. Check for universal opt-out signal (GPC) recognition where required.
7. Review data processing agreements and vendor management practices.
8. Flag jurisdictions where current practices do not meet requirements.

## Output Format
```
Privacy Audit | all jurisdictions

| Jurisdiction | Rights Impl | Disclosures | Opt-Out | DPAs | Status |
|-------------|-------------|-------------|---------|------|--------|
| CA (CCPA/CPRA) | 4/5 | OK | OK | OK | PARTIAL |
| VA (VCDPA) | 3/5 | OK | MISSING | OK | FAIL |
| CT (CTDPA) | 3/5 | WARNING | MISSING | OK | FAIL |
| CO (CPA) | 3/5 | OK | MISSING | OK | FAIL |

Findings:
- [FAIL] Universal opt-out (GPC signal) not implemented -- required by CA, CO, CT
- [PARTIAL] CA: data correction right not yet implemented
- [OK] Privacy notice covers required categories for all jurisdictions

Next action: Implement GPC signal recognition to satisfy 3 state requirements at once.
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| Inherits context from | `[gdpr-check]` for EU requirements |
| Gaps identified | `[assessment-report]` to document findings formally |
| Multiple frameworks apply | `[compliance-calendar]` to track remediation deadlines |
