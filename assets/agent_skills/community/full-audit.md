---
name: full-audit
description: Comprehensive codebase audit -- chains dep-check, dead-code, try-except-audit, absence-audit, observability-audit, tech-debt.
version: 0.1.0
execution-mode: advisory
meta-skill: validate
meta-skill-mode: invocation-time
meta-skill-topology: fan
argument-hint: "[MODULE or \"all\"]"
category: dev-tools
status: candidate
---
# Full Audit

Composite deep audit. Runs every code quality check we have against a module or the full codebase.

## When to Use
- Quarterly codebase health review
- Before a major release
- When onboarding a new team member (show them the state)
- After a period of rapid development (shipped fast, now check quality)

## Execution (parallel where possible)

### Phase 1: Structural (parallel)
- `[dep-check] scan` -- third-party imports
- `[dead-code] $TARGET` -- unused functions/imports
- `[dependency-graph] $TARGET` -- circular deps, coupling

### Phase 2: Quality (parallel)
- `[try-except-audit] $TARGET` -- exception handling
- `[absence-audit] $TARGET` -- what's missing
- `[observability-audit] $TARGET` -- logging/metrics gaps

### Phase 3: Synthesis
- `[tech-debt]` -- inventory all findings
- `[rice-prioritize]` -- rank by impact/effort

### Phase 4: Remediation Plan
- Create a structured remediation plan covering ALL findings (not just the top 5)
- Group findings into workstreams with dependencies and sequencing
- Mark each finding with: P0/P1/P2 priority, owner, risk level, reversibility
- Flag any decision made with insufficient evidence as `[low-evidence]` with a verification step
- Enumerate operator decisions needed (with defaults if no answer)
- Include a post-remediation verification checklist
- Post the plan to the coordination bus for fleet visibility
- **Do NOT skip this phase.** Synthesis without remediation leaves the operator
  to request the plan separately. (Origin: 2026-08-19 fleet audit -- synthesis
  was completed but remediation plan was not, requiring a follow-up session.)

## Output Format
```
Full Audit | <target> | <date>
══════════════════════════════

## Summary
| Audit | Findings | Critical | Medium | Low |
|-------|----------|----------|--------|-----|
| Dependencies | N | -- | -- | -- |
| Dead code | N | -- | -- | -- |
| Dependency graph | N cycles | -- | -- | -- |
| Exception handling | N | N | N | N |
| Absences | N | N | N | N |
| Observability | N | N | N | N |

## Total: N findings (C critical, M medium, L low)

## Top 5 Actions (RICE-prioritized)
1. <highest impact fix>
2. ...

## Tech Debt Score: <X/100>
<brief assessment of overall codebase health>
```
