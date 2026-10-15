---
name: cherry-pick-safe
description: Cherry-pick commits with conflict detection, test verification, and bus notification.
version: 0.1.0
execution-mode: side_effecting
argument-hint: "<commit_hash...> [--onto BRANCH] [--dry-run]"
category: dev-tools
status: candidate
---
# Cherry Pick Safe

Safe cherry-picking with pre-flight checks, automatic test verification, and coordination bus notification. Prevents silent breakage from cherry-picks.

## When to Use
- Backporting a fix to a release branch
- Selectively pulling commits from a feature branch
- When user says "cherry pick" or "backport"

## Execution

### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=cherry-pick-safe] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

1. **Pre-flight**: Check target branch is clean, commits exist, no conflicts predicted
2. **Dry run**: `git cherry-pick --no-commit` to preview changes
3. **Conflict check**: If conflicts, delegate to `[conflict-resolve]`
4. **Apply**: `git cherry-pick {commits}`
5. **Test**: Run affected test files
6. **Report**: Summary with test results

## Output Format

```
Cherry Pick Safe | {N} commits → {target_branch}
=================================================

## Commits
| Hash | Message | Files | Conflicts |
|------|---------|-------|-----------|

## Test Results
{pass/fail summary}

## Applied
{Success or failure details}
```

## Skill Chains

### Mandatory (MUST pass before cherry-pick apply)

- **`[test-run]`** MUST pass on affected test files after dry-run preview

### Advisory

| After this skill... | Consider... |
|--------------------|-------------|
| Conflicts found | `[conflict-resolve]` |
| Tests pass | `[commit]` (if --no-commit mode) |
| Backport to release | `[tag-release]` |
| Multiple branches | `[worktree]` (parallel cherry-picks) |

## Authority

- **T1 (TRUSTED)**: May cherry-pick with `[test-run]` passed
- **T2 (Active/High)**: May cherry-pick with `[test-run]` passed
- **T3 (Medium)**: MUST get operator approval AND `[test-run]` passed
- **T4 (Probationary)**: BLOCKED — cannot invoke this skill
- **Operator**: Override any restriction
