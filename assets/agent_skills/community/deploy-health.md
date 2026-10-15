---
name: deploy-health
description: Run post-deploy smoke and health validation for a service, environment, or release. Use after deployment, promotion, rollback, or when checking whether a shipped change is healthy.
version: 0.1.0
execution-mode: advisory
argument-hint: "<target-env-or-url> [--deep]"
category: backend-infra
status: candidate
---
# Deploy Health

## Purpose

Answer: "Is the deployed thing healthy enough to keep rolled out?"

This is a CD validation skill. It can use CI-style tests only when those tests validate the deployed surface, not just the source tree.

## Workflow

1. Identify target:
   - URL, host, service name, environment, release SHA, or PR.
2. Establish expected state:
   - What should be deployed?
   - Which commit/tag/config should the environment report?
   - What user-visible or API behavior must work?
3. Run checks from least disruptive to deepest:
   - Health endpoint or status command.
   - One smoke request per critical route/API.
   - Logs for recent errors with `[log-analyze]`.
   - Performance check for web surfaces with `cloudflare:web-perf` or browser tooling when relevant.
   - Optional deeper acceptance tests only when they are safe for the environment.
4. Classify:
   - `HEALTHY`
   - `DEGRADED`
   - `FAILED`
   - `UNKNOWN`
5. Recommend:
   - continue rollout
   - hold rollout
   - investigate
   - rollback

## Output

```markdown
Deploy Health: <HEALTHY | DEGRADED | FAILED | UNKNOWN>
Target: <env/url/service>
Expected version: <sha/tag/config | unknown>
Observed version: <sha/tag/config | unknown>
Checks: <pass/fail/unknown summary>
Logs: <clean/errors/unknown>
Decision: <continue | hold | rollback | investigate>
```

## Rules

- Do not claim healthy from a single deploy success signal.
- Do not run destructive or load-heavy probes without approval.
- If the target or expected version is unknown, say `UNKNOWN` and state what evidence is missing.
