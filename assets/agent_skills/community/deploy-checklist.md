---
name: deploy-checklist
description: Environment-specific deploy verification -- tests, health, changelog, tag.
version: 0.1.0
execution-mode: advisory
argument-hint: "[--env staging|production] [--service NAME]"
category: backend-infra
status: candidate
---
# Deploy Checklist

Structured verification before deploying any service or release.

## When to Use
- Before deploying dashboard, API, or any service
- Before pushing to production environments
- As final gate in CI/CD pipeline

## Execution

1. **Clean state**: `git status` -- no uncommitted changes
2. **Tests pass**: `python -m pytest` -- all green
3. **Security clear**: `[security-scan]` -- no HIGH findings
4. **Health probes**: `[health]` -- all adapters responding
5. **Changelog updated**: Verify CHANGELOG.md has current version entry
6. **Tag created**: Version tag exists and matches
7. **Dependencies frozen**: `pip freeze` matches requirements
8. **Env config**: Verify environment variables set for target env
9. **Rollback plan**: Document rollback commit hash
10. **Notify**: Post to bus that deploy is starting

## Output Format

```
Deploy Checklist | <service> → <env>
======================================
| # | Check | Status | Detail |
|---|-------|--------|--------|
| 1 | Clean state | PASS | ... |
...
| 10 | Bus notify | DONE | ... |

Deploy: GO / NO-GO
Rollback to: <commit-hash>
```

## Skill Chains
- Pre-deploy → `[ship-check]`, then `[deploy-checklist]`
- Post-deploy → `[health]`, `[smoke]`
- Failure → `[rollback]`, `[incident]`
