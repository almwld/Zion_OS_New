---
name: dx-audit
description: Audit developer experience including build time, test time, and docs quality
version: 0.1.0
execution-mode: advisory
argument-hint: "[--scope build|test|docs|errors|all]"
category: dev-tools
status: candidate
---
# DX Audit

Audit developer experience: build time, test time, docs quality, error message clarity, and onboarding friction. Identifies where the development workflow creates unnecessary pain and recommends improvements.

## When to Use
- Periodically review the health of the dev workflow
- After onboarding someone and hearing friction reports
- Before a major refactor to baseline the experience
- When velocity feels lower than it should be

## Execution
1. Parse `$ARGUMENTS` for `--scope` (default: `all`)
2. For each scope area, measure and assess:

   **build**:
   - Time to install dependencies (`pip install -e ".[test]"`)
   - Number of manual setup steps
   - Are there cached/incremental build options?

   **test**:
   - Full test suite runtime
   - Time to run a single test file
   - Test discovery reliability
   - Flaky test count (from CI history if available)

   **docs**:
   - CLAUDE.md completeness (commands, architecture, conventions)
   - README presence and accuracy
   - Inline code documentation (docstring coverage)
   - Are common tasks documented?

   **errors**:
   - Sample error messages from the codebase
   - Do errors tell you what went wrong AND what to do?
   - Stack trace readability
   - Missing error handling (bare except, silent failures)

3. Score each area: GOOD (no friction) / FAIR (minor friction) / POOR (significant friction)
4. Prioritize improvements by impact-to-effort ratio
5. Compare against DX best practices (fast feedback loops, clear errors, minimal setup)

## Output Format
```
DX Audit | scope: {scope}

Overall DX Score: {GOOD|FAIR|POOR}

Build: {score}
- Install time: {seconds}s
- Setup steps: {N}
- {findings}

Test: {score}
- Full suite: {seconds}s
- Single file: {seconds}s
- {findings}

Docs: {score}
- {findings}

Errors: {score}
- {findings}

Top Improvements (by impact/effort):
1. {improvement} -- impact: {H/M/L} -- effort: {H/M/L}

Next action: {recommendation}
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| Velocity issues found | `[velocity-tune]` for workflow optimization |
| Observability gaps | `[observability-audit]` for monitoring |
| Error quality poor | `[error-message]` to improve error messages |
