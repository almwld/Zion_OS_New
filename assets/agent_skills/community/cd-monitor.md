---
name: cd-monitor
description: Monitor deployment, rollout, promotion, and post-release health status. Use when the user asks about CD, deploy status, rollout health, release gates, environment promotion, or whether a shipped change is healthy.
version: 0.1.0
execution-mode: advisory
argument-hint: "[status | watch | env ENV | release PR_OR_SHA]"
category: backend-infra
status: candidate
---
# CD Monitor

## Purpose

Answer: "Is this release deployed, healthy, and safe to continue?"

This differs from `ci-monitor`, which answers whether a PR/check is safe to merge. Use `cd-monitor` after merge, during deployment, during environment promotion, or while validating runtime health.

## Workflow

1. Identify target: PR, commit SHA, release tag, environment, or deployment provider.
2. Read deployment source of truth first:
   - GitHub Actions deployment jobs: `gh run list --branch <branch> --limit 10`
   - Provider CLI/status if named, for example `wrangler`, Cloudflare dashboard/API, or service-specific health.
   - Bus receipts for operator-approved deployment or rollback state.
3. Classify status:
   - `NOT_DEPLOYED`
   - `DEPLOYING`
   - `DEPLOYED_UNVERIFIED`
   - `HEALTHY`
   - `DEGRADED`
   - `ROLLED_BACK`
   - `UNKNOWN`
4. Verify health with the narrowest available checks:
   - `[health]` for service health endpoint.
   - `[deploy-health]` for post-deploy smoke checks.
   - `[log-analyze]` for deploy or runtime logs.
   - `cloudflare:web-perf` for web performance after frontend deploys.
5. Report blockers and next action. Do not treat a passed deploy job as healthy without health evidence.

## Output

```markdown
CD Status: <status>
Target: <env/release/sha>
Deployment evidence: <run/provider/bus receipt>
Health evidence: <probe/log/check>
Blockers: <none | list>
Next action: <continue | wait | investigate | rollback>
```

## Bus

Post a `STATUS` receipt to the bus when monitoring changes a rollout decision.
```
Type: STATUS
To: all
Message: [lane=cd-monitor/<target>] status=<status>; target=<target>; blockers=<n>; next=<action>
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)
