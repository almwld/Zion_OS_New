---
name: canary-deploy
description: Gradual rollout verification -- deploy to subset, compare metrics, promote or rollback
version: 0.1.0
execution-mode: side_effecting
argument-hint: "<version> [--percentage 10|25|50|100] [--metric METRIC] [--rollback-threshold PCT]"
category: backend-infra
status: candidate
---
# Canary Deploy

Manage gradual rollouts by deploying to a subset of traffic, comparing key metrics against the baseline, and deciding whether to promote to full rollout or trigger a rollback. Supports percentage-based traffic splitting and configurable rollback thresholds.

## When to Use
- Deploying a risky change that needs progressive validation
- Rolling out a new version and want to compare error rates before full promotion
- Need a structured promote-or-rollback decision framework
- Validating performance metrics (latency, error rate, resource usage) at partial traffic

## Execution
### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=canary-deploy] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

1. Parse `$ARGUMENTS` for version, `--percentage` (default: 10), `--metric` (default: error_rate), `--rollback-threshold` (default: 5% regression)
2. Document the baseline metrics from the current production version
3. Define the canary deployment plan: percentage stages (10 -> 25 -> 50 -> 100)
4. At each stage, compare canary metrics against baseline
5. If regression exceeds `--rollback-threshold`, recommend immediate rollback with evidence
6. If metrics are stable or improved, recommend promotion to next percentage
7. Generate a deployment report with metric comparisons at each stage
8. Log the deployment decision to the coordination bus

## Output Format
```
Canary Deploy | {version} at {percentage}%
────────────────────────────────
Baseline version: {current}
Canary version: {new}

| Stage | Traffic | Error Rate | Latency p99 | Decision |
|-------|---------|------------|-------------|----------|
| 10%   | canary  | 0.12%      | 145ms       | PROMOTE  |
| 25%   | canary  | 0.11%      | 142ms       | PROMOTE  |

Verdict: {PROMOTE to next stage | ROLLBACK | FULL PROMOTION}
Evidence: {metric comparison details}
Action: {next steps}
```

## Skill Chains

### Mandatory (MUST pass before canary execution)

- **`[deploy-checklist]`** MUST pass — environment-specific deploy verification
- **`[health]`** MUST confirm baseline health before canary traffic split

### Advisory

| After this skill... | Consider... |
|--------------------|-------------|
| Canary approved for full rollout | `[deploy-checklist]` to verify final promotion |
| Metrics show regression | `[rollback]` to revert safely (with `[deploy-health]` confirming) |
| Deployment complete | `[health]` to verify all probes pass post-deploy |

## Authority

- **T1 (TRUSTED)**: May manage canary with all mandatory chains passed
- **T2 (Active/High)**: MUST get operator approval AND all mandatory chains passed
- **T3 (Medium)**: MUST get operator approval AND all mandatory chains passed
- **T4 (Probationary)**: BLOCKED — cannot invoke this skill
- **Operator**: Override any restriction
