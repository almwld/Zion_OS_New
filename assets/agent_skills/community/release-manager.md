---
name: release-manager
description: Plan and coordinate release promotion from merge-ready change to deployed, verified, and recoverable release. Use for release plans, deployment sequencing, rollout gates, rollback planning, and release closeout.
version: 0.1.0
execution-mode: side_effecting
argument-hint: "[plan | promote | closeout] <PR-or-SHA-or-release>"
category: backend-infra
status: candidate
---
# Release Manager

## Purpose

Own the release transaction: what ships, where it ships, how it is verified, and how it is rolled back.

Use this when CI is already understood and the question shifts from "can this merge?" to "can this release safely move through environments?"

## Workflow

### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=release-manager] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

1. Scope:
   - PRs, commits, tags, migrations, config changes, and host-local changes.
   - Explicitly separate repo-tracked changes from machine-local operations.
2. Preconditions:
   - CI status from `[ci-monitor]`.
   - Required reviews and merge authorization.
   - Secrets/config readiness without exposing values.
   - Environment readiness from `[fleet-status]`, `[machine-health]`, or provider status.
3. Promotion sequence:
   - Target environment order.
   - Expected deploy command or workflow.
   - Manual gates and approval holders.
4. Verification:
   - `[deploy-health]` smoke checks.
   - `[health]` endpoint.
   - `[log-analyze]` for runtime/deploy logs.
   - Provider-specific checks such as `cloudflare:wrangler` or `cloudflare:web-perf`.
5. Rollback:
   - Last known good commit/tag/config.
   - Rollback command or manual steps.
   - Health checks after rollback.
6. Closeout:
   - Bus receipt.
   - Evidence pack or AAR for consequential releases.

## Output

```markdown
Release: <target>
Authority: <operator/reviewer/gate>
Scope: <files/services/envs>
Preconditions: <pass/block/unknown>
Promotion: <steps>
Verification: <checks>
Rollback: <path>
Decision: <ready | blocked | deployed | rolled_back>
```

## Rules

- Do not deploy or promote without explicit operator authority or an existing approved release gate.
- Never post secret values to the bus or chat.
- Do not merge your own PR as part of release management unless the operator explicitly waives peer review.
- If verification is unavailable, mark `UNKNOWN`; do not infer health from deployment success.

## Skill Chains

### Mandatory (MUST pass before promotion)

- **`[deploy-checklist]`** MUST pass — environment-specific deploy verification
- **`[ci-wait]`** MUST be green — CI passing on the merge commit

### Advisory

- **Preconditions**: `[ci-monitor]`, `[fleet-status]`, `[machine-health]`
- **Verification**: `[deploy-health]`, `[health]`, `[log-analyze]`
- **Rollback path**: `[rollback]` (with `[deploy-health]` confirming degradation)
- **Closeout**: `[bus]` (receipt), `[evidence-pack]` or `[aar]` for consequential releases

## Authority

- **T1 (TRUSTED)**: May manage release with all mandatory chains passed
- **T2 (Active/High)**: MUST get operator approval AND all mandatory chains passed
- **T3 (Medium)**: MUST get operator approval AND all mandatory chains passed
- **T4 (Probationary)**: BLOCKED — cannot invoke this skill
- **Operator**: Override any restriction
