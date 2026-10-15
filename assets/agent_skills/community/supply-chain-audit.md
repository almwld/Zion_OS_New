---
name: supply-chain-audit
description: Audit software supply chain including lockfile integrity, typosquatting detection, provenance verification, and dependency graph analysis
version: 0.1.0
execution-mode: advisory
argument-hint: "[--scope deps|lockfile|provenance|all]"
category: security
status: candidate
---
# Supply Chain Audit

Inspect the software supply chain for integrity and security risks. Checks lockfile consistency, detects potential typosquatting in package names, verifies provenance of dependencies, and analyzes the dependency graph for transitive risk. Designed for projects that take supply chain security seriously.

## When to Use
- Before a release or deployment to verify supply chain integrity
- After adding new dependencies to check for typosquatting
- Periodic audit of dependency provenance and trust
- When investigating a suspected supply chain compromise

## Execution
1. **Lockfile integrity** (if scope includes `lockfile` or `all`):
   - Verify lockfile exists and is in sync with requirements/pyproject.toml
   - Check for hash mismatches or missing entries
   - Flag lockfile modifications not accompanied by manifest changes
2. **Typosquatting detection** (if scope includes `deps` or `all`):
   - Compare each dependency name against known popular packages
   - Flag names within edit distance 1-2 of popular packages
   - Check for suspicious naming patterns (extra hyphens, swapped characters)
3. **Provenance verification** (if scope includes `provenance` or `all`):
   - Check package publish dates and maintainer history
   - Flag packages with recent ownership transfers
   - Verify packages are from expected registries
4. **Dependency graph analysis** (all scopes):
   - Map transitive dependency tree
   - Identify deeply nested dependencies (high blast radius)
   - Flag dependencies with no recent maintenance (>2 years)
5. **Report** -- consolidate findings by severity.

## Output Format
```
Supply Chain Audit | scope: {scope}

## Summary
- Direct dependencies: {N}
- Transitive dependencies: {N}
- Findings: {critical} critical, {high} high, {medium} medium, {low} low

## Findings
### CRITICAL
- {finding with evidence}

### HIGH
- {finding with evidence}

## Lockfile Status
- Sync: {in-sync|out-of-sync}
- Hash verification: {pass|fail}

## Dependency Graph
- Max depth: {N}
- Unmaintained (>2yr): {list}

## Next Actions
- {prioritized remediation steps}
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| License concerns found | `[license-audit]` for detailed license compatibility |
| Outdated deps found | `[dep-update]` to plan version upgrades |
| Security issues found | `[security-scan]` for code-level vulnerability check |
| Transitive dependency CVEs | `[free-apis]` — NVD/OSV for vulnerability data on transitive deps (`python ~/bin/free_apis.py nvd "<cve-id>"` or `python ~/bin/free_apis.py osv "<package>"`) |
