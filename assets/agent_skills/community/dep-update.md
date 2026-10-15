---
name: dep-update
description: Check for outdated dependencies, preview breaking changes, and generate update plan or PR
version: 0.1.0
execution-mode: remedial
argument-hint: "[--check|--update|--security-only] [--dry-run]"
category: dev-tools
status: candidate
---
# Dependency Updater

Check for outdated dependencies, assess breaking change risk, and generate a structured update plan. Supports security-only updates for minimal-risk patching and dry-run mode for preview without changes.

## When to Use
- Regular maintenance to keep dependencies current and secure
- After a security advisory to patch only vulnerable packages
- Before a release to ensure all deps are at known-good versions
- When pip-audit or Dependabot flags outdated packages

## Execution
1. Parse `$ARGUMENTS` for mode (`--check` default, `--update`, `--security-only`) and `--dry-run`
2. Run `pip list --outdated --format=json` to identify outdated packages
3. For each outdated package, check changelog/release notes for breaking changes
4. Cross-reference with `pip-audit` output for known vulnerabilities (CVE IDs)
5. Classify each update: PATCH (safe), MINOR (review needed), MAJOR (breaking risk)
6. For `--security-only`: filter to only packages with known CVEs
7. For `--update`: generate updated requirements or pyproject.toml entries
8. For `--dry-run`: show what would change without modifying files
9. Verify stdlib-only rule is maintained -- no new runtime deps introduced

## Output Format
```
Dep Update | {mode}
────────────────────────────────
Outdated: {N} | Security: {N CVEs} | Breaking: {N major}

| Package | Current | Latest | Type | CVEs | Risk |
|---------|---------|--------|------|------|------|
| pytest  | 8.1.0   | 8.3.2  | MINOR | 0   | LOW  |

Update plan: {N} packages to update
Breaking changes: {details if any}
Action: {next steps or "No further action needed"}
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| Updates applied | `[ship-check]` to verify nothing broke |
| Security CVEs found | `[security-scan]` to check for exploitability |
| Breaking changes identified | `[changelog-subscribe]` to monitor upstream for migration guides |
| CVE enrichment needed | `[free-apis]` — NVD/OSV for CVE details (`python ~/bin/free_apis.py nvd "<cve-id>"` or `python ~/bin/free_apis.py osv "<package>"`) |
