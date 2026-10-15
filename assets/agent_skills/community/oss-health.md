---
name: oss-health
description: Assess open source project health -- contributors, commit frequency, issue response time, bus factor, license
version: 0.1.0
execution-mode: advisory
argument-hint: "[REPO_URL_OR_PATH] [--compare REPO2]"
category: dev-tools
status: candidate
---
# OSS Health Check

Assess the health of an open source project by analyzing contributor diversity, commit frequency, issue response time, bus factor, dependency freshness, and license compatibility. Optionally compare two projects side by side.

## When to Use
- Before adopting an open source dependency to assess maintenance risk
- When evaluating competing libraries for the same functionality
- When auditing existing dependencies for abandonment or security risk
- When contributing to or forking a project and needing to understand its health

## Execution
1. Parse `$ARGUMENTS` for repo URL/path and optional comparison repo
2. Analyze contributor metrics: number of active contributors (last 90 days), bus factor, top contributor concentration
3. Analyze activity metrics: commit frequency, last commit date, release cadence
4. Analyze community metrics: open issues count, median issue response time, PR merge time
5. Check license type and compatibility with project requirements
6. Check for security advisories or known vulnerabilities
7. If `--compare` provided, generate side-by-side comparison
8. Calculate overall health score (0-100)

## Output Format
```
OSS Health | <repo>
====================

## Health Score: <0-100> / 100

## Activity
- Last commit: <date> (<N> days ago)
- Commits (90d): <count>
- Release cadence: <frequency>
- Latest release: <version> (<date>)

## Contributors
- Active (90d): <count>
- Bus factor: <N>
- Top contributor: <name> (<X>% of commits)

## Community
- Open issues: <count>
- Median response time: <duration>
- PR merge time (median): <duration>
- Stars: <count> | Forks: <count>

## License
- Type: <license>
- Compatible: YES/NO/REVIEW_NEEDED

## Security
- Known advisories: <count>
- Last audit: <date or UNKNOWN>

## Risk Assessment
- <risk factor>: <severity>

## Next Action
- ...
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| Identified risky dependency | `[risk-register]` to track (if available), `[dep-check]` to audit imports |
| Need license compatibility check | `[dep-check]` for stdlib-only compliance |
| Need live vulnerability data | `python ~/bin/free_apis.py osv query --package <pkg> --ecosystem <PyPI\|npm\|Go>` or `python ~/bin/free_apis.py nvd search --keyword <pkg>` |
