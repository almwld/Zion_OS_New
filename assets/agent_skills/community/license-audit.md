---
name: license-audit
description: Deep license compatibility check across all dependencies, flag GPL contamination, generate SBOM summary
version: 0.1.0
execution-mode: advisory
argument-hint: "[--format summary|detailed|sbom] [--policy permissive|copyleft-ok]"
status: tested
category: security
providers:
  required: [python]
---
# License Audit

Perform a deep license compatibility audit across all project dependencies. Checks for GPL contamination, license conflicts, missing license declarations, and generates a Software Bill of Materials (SBOM) summary. Enforces a configurable license policy.

## When to Use
- Before releasing software as open source or proprietary
- When adding new dependencies to verify license compatibility
- During compliance audits or due diligence for acquisitions
- When a client requires an SBOM or license attestation

## Execution
1. Parse `$ARGUMENTS` for format (default: summary) and policy (default: permissive)
2. Scan `pyproject.toml`, `package.json`, or equivalent for declared dependencies
3. For each dependency, determine license type from package metadata
4. Check compatibility against the policy: permissive (reject copyleft), copyleft-ok (allow GPL)
5. Flag: GPL contamination in permissive projects, missing licenses, unknown licenses, dual-licensed packages
6. For `sbom` format: generate SPDX-compatible SBOM summary
7. Check for license file presence in the project itself

## Output Format
```
License Audit | <policy> policy
==================================

## Summary
- Dependencies scanned: N
- Compliant: N | Non-compliant: M | Unknown: K
- Policy: <permissive|copyleft-ok>

## Dependency Licenses
| Package | Version | License | Status |
|---------|---------|---------|--------|
| ... | ... | MIT | PASS |
| ... | ... | GPL-3.0 | FAIL |
| ... | ... | UNKNOWN | REVIEW |

## Violations
- [FAIL] <package>: <license> — incompatible with <policy> policy
- [REVIEW] <package>: license not found in metadata

## Project License
- Declared: <license or MISSING>
- LICENSE file: PRESENT / MISSING

## SBOM (if requested)
<SPDX-compatible listing>

## Next Action
- ...
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| Found stdlib-only violations | `[dep-check]` for detailed import analysis |
| Legal concerns identified | `[legal-check]` for broader IP review |
