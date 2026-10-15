---
name: env-parity
description: Compare environment configs across dev/staging/prod for drift, missing vars, and type mismatches
version: 0.1.0
execution-mode: side_effecting
argument-hint: "[--envs dev,staging,prod] [--source .env|vault|cloud]"
category: backend-infra
status: candidate
---
# Environment Parity Check

Compare environment configurations across dev, staging, and production to detect drift, missing variables, type mismatches, and inconsistent defaults. Prevents deploy failures caused by config divergence between environments.

## When to Use
- Before deploying to staging or production to catch missing config
- After adding new environment variables to dev and need to propagate
- Debugging environment-specific failures that work locally but fail in prod
- Regular maintenance to ensure all environments stay in sync

## Execution
### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=env-parity] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

1. Parse `$ARGUMENTS` for `--envs` (default: `dev,staging,prod`) and `--source` (default: `.env`)
2. Load config from each environment source (.env files, vault exports, cloud config)
3. Build a union of all variable names across all environments
4. For each variable, compare: presence (missing in some envs), value type consistency (string vs int vs bool), placeholder vs real values
5. Flag variables present in prod but missing in dev (potential local failures)
6. Flag variables present in dev but missing in prod (potential deploy failures)
7. Flag type mismatches (e.g., `"true"` in dev vs `"1"` in prod)
8. Generate a parity report with drift score (0-100, where 100 is full parity)

## Output Format
```
Env Parity | {envs}
────────────────────────────────
Parity score: {N}/100
Variables checked: {N} | Drifted: {N} | Missing: {N}

| Variable | dev | staging | prod | Issue |
|----------|-----|---------|------|-------|
| DB_HOST  | localhost | db.stg | db.prod | OK (expected) |
| NEW_FLAG | true | MISSING | MISSING | Missing in staging, prod |

Critical: {N} vars missing in prod that exist in dev
Warning: {N} type mismatches across environments
Action: {next steps or "No further action needed"}
```

## Skill Chains

### Mandatory

None — environment parity is a read-only comparison that diffs configs without modifying them.

### Advisory

- If drift detected → `[config-drift]` for deeper machine-level analysis
- After missing vars documented → `[env-doc]` to update variable documentation
- Ready to deploy with fixes → `[deploy-checklist]` to verify the target environment

## Authority

- **T1 (TRUSTED)**: May run
- **T2 (Active/High)**: May run
- **T3 (Medium)**: May run
- **T4 (Probationary)**: May run (read-only)
- **Operator**: Override any restriction
