---
name: dependency-health
description: Monitor upstream dependency health including CVE history, maintenance activity, bus factor, and alternatives
version: 0.1.0
execution-mode: advisory
argument-hint: "[--scope runtime|dev|all] [--threshold RISK_LEVEL]"
category: dev-tools
status: candidate
---
# Dependency Health

Assess the health and risk profile of project dependencies beyond simple version checks. Evaluates CVE history, maintenance cadence, contributor diversity (bus factor), download trends, and license compatibility. Flags dependencies that are abandoned, under-maintained, or high-risk, and suggests alternatives.

## When to Use
- Quarterly dependency health review
- Before adding a new dependency to evaluate its risk profile
- After a CVE advisory to assess exposure across the dependency tree
- When planning a migration away from a problematic dependency

## Execution
1. Parse `$ARGUMENTS` for scope (default: `all`) and risk threshold (default: `medium`).
2. Extract dependency list from `pyproject.toml`, `requirements.txt`, or `package.json` as appropriate.
3. For each dependency, assess health signals:
   - **Maintenance**: Last commit date, release cadence, open issue count, PR response time.
   - **Security**: Known CVEs (check via `pip-audit` output or web search), severity distribution.
   - **Bus factor**: Number of active contributors in the last 6 months.
   - **Adoption**: Download trends (growing, stable, declining).
   - **License**: Compatibility with project license, any copyleft concerns.
4. Score each dependency: GREEN (healthy), YELLOW (watch), RED (action needed).
5. For RED dependencies, research and suggest alternatives.
6. Note: This project has a stdlib-only runtime policy. Runtime dependencies should be flagged as policy violations.

## Output Format
```
Dependency Health | scope | threshold

## Summary
- Dependencies scanned: N
- GREEN: N | YELLOW: N | RED: N
- Policy violations: N (runtime deps in stdlib-only project)

## Health Matrix
| Dependency | Version | Last Release | CVEs | Bus Factor | Score |
|-----------|---------|-------------|------|------------|-------|
| {name} | {ver} | {date} | {N} | {N contribs} | {GREEN|YELLOW|RED} |

## Action Items
### {Dependency} -- RED
- Risk: {specific risk description}
- CVEs: {list if any}
- Alternative: {suggested replacement}
- Migration effort: {LOW|MEDIUM|HIGH}

## License Summary
| License | Count | Compatible |
|---------|-------|-----------|
| {license} | N | {YES|NO|REVIEW} |

Next action: {suggestion or "No further action needed"}
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| Finding outdated dependencies | `[dep-update]` to plan version bumps |
| Discovering supply chain risks | `[supply-chain-audit]` for deeper analysis |
| Identifying risks needing tracking | `[risk-register]` to add dependency risks |
| CVE history lookup needed | `[free-apis]` — NVD/OSV for CVE severity and history (`python ~/bin/free_apis.py nvd "<cve-id>"` or `python ~/bin/free_apis.py osv "<package>"`) |
