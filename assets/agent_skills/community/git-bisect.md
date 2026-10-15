---
name: git-bisect
description: Binary search for the commit that introduced a bug using automated test verification.
version: 0.1.0
execution-mode: side_effecting
argument-hint: "<good_ref> <bad_ref> [--test COMMAND] [--auto]"
category: dev-tools
status: candidate
---
# Git Bisect

Automated binary search through git history to find the exact commit that introduced a regression. Wraps `git bisect` with structured output and optional automated test verification.

## When to Use
- A test that was passing now fails, and you don't know which commit broke it
- A behavior changed and you need to find when
- When user says "bisect", "find the commit that broke", "when did this break"

## Execution

### Manual mode (default)
### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=git-bisect] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

1. Start bisect: `git bisect start`
2. Mark bad: `git bisect bad {bad_ref}` (default: HEAD)
3. Mark good: `git bisect good {good_ref}`
4. At each step: show the commit, run relevant test if specified, ask user good/bad
5. Report the first bad commit with full context (diff, author, message)

### Auto mode (--auto)
1. Start bisect with good/bad refs
2. Run `git bisect run {test_command}` (e.g., `python -m pytest test_example.py.py -x`)
3. Wait for completion
4. Report the first bad commit

## Output Format

```
Git Bisect | {good_ref}..{bad_ref}
===================================

## Search Space
Good: {good_ref} ({date}, {message})
Bad: {bad_ref} ({date}, {message})
Commits to search: {N}
Estimated steps: {log2(N)}

## Result
First bad commit: {hash}
Author: {author}
Date: {date}
Message: {message}

## Changes in bad commit
Files changed: {N}
{summary diff}

## Likely cause
{Analysis of what changed in the commit that could cause the regression}

## Next Steps
- [ ] Review the diff above
- [ ] Verify with: `git stash && git checkout {hash}~1 && {test} && git checkout {hash} && {test}`
- [ ] Fix or revert
```

## Skill Chains

### Mandatory

- None — git-bisect is a diagnostic tool. It modifies HEAD during operation but
  returns to original HEAD on completion. Warn the user about working tree state
  before starting.

### Advisory

| After this skill... | Consider... |
|--------------------|-------------|
| Bad commit found | `[debug-test]` (fix the regression) |
| Commit is large | `[review-pr]` (review the original PR) |
| Pattern found | `[retrospective]` (prevent recurrence) |
| Need to revert | `[rollback]` (structured revert with `[deploy-health]` confirming) |

## Authority

- **T1 (TRUSTED)**: May run without restriction
- **T2 (Active/High)**: May run without restriction (diagnostic — returns to original HEAD)
- **T3 (Medium)**: May run with operator notification
- **T4 (Probationary)**: May run (diagnostic only — no destructive outcome)
- **Operator**: Override any restriction

## Guardrails

- **Warn before starting**: `git bisect` checks out commits during operation.
  Stash uncommitted changes first or run in a clean worktree.
- **Auto mode**: `git bisect run` will execute arbitrary test commands — verify
  the test command is safe before starting.
- **Cleanup**: Always run `git bisect reset` to return to original branch.
