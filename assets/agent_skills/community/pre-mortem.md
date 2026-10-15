---
name: pre-mortem
description: Identify fragile code and write realistic failure scenarios before they happen.
version: 0.1.0
execution-mode: advisory
argument-hint: <module or feature to analyze>
category: dev-tools
status: candidate
---
# Pre-Mortem

Assume the feature/module has failed catastrophically. Work backward to identify what went wrong.

## Execution

### 1. Identify the target
Read the module/feature code thoroughly. Understand all dependencies, external calls, state mutations, and error paths.

### 2. Generate failure scenarios
For each scenario, write a realistic incident report as if it already happened:

**Template per scenario:**
```
INCIDENT: <title>
SEVERITY: P0/P1/P2
TRIGGER: <what caused it>
IMPACT: <who/what was affected, for how long>
ROOT CAUSE: <the actual code path that failed>
DETECTION: <how long until someone noticed>
EVIDENCE: <file:line that contains the vulnerability>
```

### 3. Prioritize by likelihood x impact
Rank scenarios. Focus on:
- **Single points of failure**: What has no fallback?
- **Silent failures**: What fails without alerting anyone?
- **Cascade risks**: What failure triggers other failures?
- **Data corruption**: What can write bad state permanently?
- **Security**: What can be exploited by a malicious input?

### 4. Recommend mitigations
For each P0/P1 scenario, propose a specific code change:
- Add a guard/assertion
- Add a circuit breaker
- Add monitoring/alerting
- Add a test that would have caught it

## Output Format
```
Pre-Mortem | <target>
═══════════════════════════

## Scenario 1: <title> [P0]
<incident report>
Mitigation: <specific code change>

## Scenario 2: <title> [P1]
...

## Summary
- P0 scenarios: N (must fix)
- P1 scenarios: N (should fix)
- P2 scenarios: N (backlog)
- Highest-risk path: <file:line>
```

## When to Use
- Before shipping a new feature
- Before a release
- After adding a new external dependency
- When a module has grown complex
- During sprint planning (to prioritize hardening)
