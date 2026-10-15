---
name: oss-graduation
description: Checklist and gate for graduating a local HUMMBL package to the hummbl-io/oss monorepo for public PyPI publishing.
version: 0.1.0
execution-mode: advisory
category: fleet-ops
status: candidate
providers:
  required: [python]
---
# oss-graduation

Checklist and gate for graduating a local HUMMBL package to the `hummbl-io/oss` monorepo for public PyPI publishing.

## When to use

- A local package in `~/PROJECTS/<name>/` is approaching v0.1.0
- Operator asks "is this ready to publish?"
- Before moving any code from a private repo to `hummbl-io/oss/packages/python/<name>/`

## When NOT to use

- The package is not yet v0.1.0 (keep incubating locally)
- The package has unresolved PII/sensitive data issues
- The operator has not approved publication

## Procedure

### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.

### 1. PII / PHI Sanitization Scan

Run the sensitive data scanner against the package source:

```bash
python scripts/scan-sensitive-pre-commit.py --path <package-root>
```

If no scanner exists, run manual grep:
```bash
grep -rE "hummbl-vps|workstation|hummbl-runner|tail093e19|tail16e16c|ts\.net|100\.[0-9]+\.[0-9]+\.[0-9]+|gho_|sk-or-v1|DASHBOARD_TOKEN|BUS_TOKEN|~|/c/Users/Owner|_state/|_internal/" <package-root>/
```

**FAIL if**: any internal hostnames, IPs, tokens, operator names, internal paths, or fleet infrastructure details are found.

**Action**: redact or remove before proceeding.

### 2. Internal Reference Audit

Check for references to fleet-internal concepts that have no place in a public package:

```bash
grep -rE "delta|workstation|remote-node|remote-node|remote-node|huxley|fleet|bus-global|coordination bus|HUMMBL fleet|operator|Reuben|Jarvis" <package-root>/
```

**Exceptions**: the word "fleet" in generic documentation (e.g., "multi-agent fleet") is acceptable. References to specific machines, operators, or internal tools are not.

**FAIL if**: specific machine names, operator names, or internal tool references are found in code or docs.

### 3. Documentation Rewrite

Verify the README.md is written for a public audience:
- No internal context (fleet, operators, bus, machines)
- No internal architecture references
- Generic examples that work for any user
- Clear install instructions (`pip install <name>`)
- Public-facing description of what the package does

**FAIL if**: README contains internal references or assumes fleet context.

### 4. Test Suite

```bash
cd <package-root>
python -m pytest tests/ -v --cov=<package-name> --cov-report=term --cov-fail-under=80
```

**FAIL if**: any tests fail or coverage is below 80%.

### 5. Zero Runtime Dependencies Verification

```bash
pip install <package-name> --dry-run  # or check pyproject.toml
```

Verify `dependencies = []` in `pyproject.toml` (or that all dependencies are in optional extras with documented justification).

**FAIL if**: any runtime dependency is not in an optional extra with a documented reason.

### 6. Dependency Justification Audit

For each optional dependency (in `[project.optional-dependencies]`):
- Is there a comment at the import site explaining why the dependency is needed?
- Is the dependency documented in the README?
- Is the reason specific (not just "useful")?

**FAIL if**: any optional dependency lacks import-site documentation or README justification.

### 7. CHANGELOG.md

Verify `CHANGELOG.md` exists with a `## [0.1.0]` section listing:
- Features added
- Known limitations
- Breaking changes (should be none for v0.1.0)

**FAIL if**: no CHANGELOG.md or no v0.1.0 section.

### 8. SECURITY.md

Verify `SECURITY.md` exists with a vulnerability reporting policy.

**FAIL if**: no SECURITY.md.

### 9. LICENSE

Verify `LICENSE` file exists (Apache 2.0 for HUMMBL packages).

**FAIL if**: no LICENSE or wrong license.

### 10. Operator Approval

Present the graduation report to the operator:
- Package name and version
- Test results (pass/fail, coverage %)
- Sanitization scan results
- Dependency list (runtime + optional with justifications)
- Any flagged items from steps 1-9

**FAIL if**: operator does not explicitly approve.

### 11. CI Matrix Update (post-approval)

Add the package to the oss CI matrix in `.github/workflows/ci.yml`:

```yaml
matrix:
  package: [..., <new-package-name>]
```

### 12. Trusted-Publishing Config (post-approval)

If the package needs PyPI publishing, ensure the trusted-publishing workflow in `.github/workflows/publish-pypi.yml` covers the new package tag pattern (`<package-name>/v*`).

### 13. Migration

```bash
# Copy package to oss
cp -r ~/PROJECTS/<name>/ ~/PROJECTS/oss/packages/python/<name>/

# Adjust structure for oss (src/ layout if not already)
# Remove internal docs, _state/, _internal/, .venv/, etc.
# Update pyproject.toml URLs to point to oss repo

# Commit to oss
cd ~/PROJECTS/oss
git checkout -b feat/<name>-graduation
git add packages/python/<name>/
git commit -m "feat: graduate <name> v0.1.0 from local incubation"
```

### 14. Post-Migration Verification

```bash
cd ~/PROJECTS/oss/packages/python/<name>
python -m pytest tests/ -v
pip install -e ".[test]" && python -m pytest tests/ -v
```

**FAIL if**: tests don't pass in the oss location.

### 15. Tag and Publish

Follow `RELEASE.md` in oss:
1. Merge feature branch to main
2. Tag the merge commit: `git tag <package-name>/v0.1.0`
3. Push tag: `git push origin <package-name>/v0.1.0`
4. Verify on PyPI

## Output Format

```
oss-graduation | <package-name> | <date>
══════════════════════════════════════════

1. PII scan:          PASS / FAIL
2. Internal refs:     PASS / FAIL
3. Docs rewrite:      PASS / FAIL
4. Tests:             PASS (N passed, X% cov) / FAIL
5. Zero runtime deps: PASS / FAIL
6. Dep justification: PASS / FAIL
7. CHANGELOG:         PASS / FAIL
8. SECURITY.md:       PASS / FAIL
9. LICENSE:           PASS / FAIL
10. Operator approval: PENDING / APPROVED / DENIED

Overall: READY FOR GRADUATION / NOT READY

Next: <action item or "await operator approval">
```

## Authority

- **T1 (TRUSTED)**: May run the checklist and present results. Cannot approve graduation (operator only).
- **T2 (Active/High)**: May run the checklist and present results. Cannot approve graduation.
- **T3 (Medium)**: May run the checklist. Cannot approve graduation.
- **T4 (Probationary)**: May run read-only checks (1-3, 7-9). Cannot execute migration.
- **Operator**: Only authority who can approve graduation (step 10).

## Constraints

- READ-ONLY on the target package until operator approval (step 10)
- Do not modify the oss repo until operator approval
- Do not publish to PyPI directly — all publishing goes through oss trusted-publishing workflow
- Do not skip sanitization steps even if the package "looks clean"

## Skill Chains

### Mandatory
- None — this is a gate skill, not a chain link.

### Advisory
- **Before**: `[self-review]` or `[report-card]` on the package
- **After**: `[commit]` (for the oss migration commit) and `[aar]` (for the graduation session)

## Changelog

### v0.1.0 (2026-09-01)
- Initial skill created for hummbl-gitops graduation
- 15-step checklist covering sanitization, tests, deps, docs, approval, migration
- Designed to be reusable for any HUMMBL package graduation
