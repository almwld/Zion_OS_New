---
name: feature-flag
description: Manage feature flags -- list, toggle, audit stale flags, clean up shipped features
version: 0.1.0
execution-mode: advisory
argument-hint: "[--action list|toggle|audit|clean] [--flag NAME]"
category: backend-infra
status: candidate
---
# Feature Flag Manager

Manage the lifecycle of feature flags across the codebase. List active flags, toggle them on/off, audit for stale flags that should be cleaned up, and remove shipped features that no longer need gating.

## When to Use
- You need to see which feature flags are currently active or dormant
- You want to toggle a flag on or off for testing or rollout
- Before a release, to audit stale flags that have been fully shipped
- During tech debt cleanup to remove dead flag branches from code

## Execution
1. Parse `$ARGUMENTS` for `--action` (default: `list`) and optional `--flag NAME`
2. Scan codebase for feature flag patterns: `ENABLE_*` env vars, `feature_flag(...)` calls, `is_enabled(...)` checks, config-based toggles
3. For `list`: display all flags with status (enabled/disabled), location, and age
4. For `toggle`: flip the specified flag and report affected code paths
5. For `audit`: identify flags older than 30 days that are always-on or always-off, flag them as candidates for removal
6. For `clean`: for a specified flag, show all conditional branches and generate a patch that removes the flag and dead branch
7. Report summary with flag count, stale count, and recommended actions

## Output Format
```
Feature Flag Manager | {action}
────────────────────────────────
Flags found: {N}

| Flag Name | Status | Age | Location | Recommendation |
|-----------|--------|-----|----------|----------------|
| ENABLE_X  | ON     | 45d | services/foo.py:12 | CLEAN (shipped) |

Stale flags: {N}
Action: {next steps or "No further action needed"}
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| Audit finds stale flags | `[config-matrix]` to verify flag combinations before removal |
| Clean removes a flag | `[deploy-checklist]` to verify safe rollout without the gate |
| Toggle changes a flag | `[test-run]` to verify behavior under new flag state |
