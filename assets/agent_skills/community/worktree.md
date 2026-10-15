---
name: worktree
description: Manage git worktrees for parallel development -- create, list, clean up.
version: 0.1.0
execution-mode: side_effecting
argument-hint: "[create BRANCH | list | clean | switch BRANCH]"
category: dev-tools
status: candidate
---
## Context Gathering

### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=worktree] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

Before executing this skill, gather the following context:
- **Active worktrees**: Run `git worktree list 2>/dev/null | wc -l || echo "0"`

# Worktree Command

Manage git worktrees for parallel branches without stashing or switching.

## Operations

### create
Create a new worktree for a feature branch:
```bash
git worktree add ../hummbl-governance-<branch> -b <type>/<agent>/<branch>
```

Convention: worktrees go in the parent directory as `hummbl-governance-<shortname>`.

Branch naming: `type/agent/short-desc` (e.g., `feat/claude/ledger-search`)

### list
Show all active worktrees:
```bash
git worktree list
```

### clean
Remove stale worktrees (merged branches):
```bash
git worktree list | while read path commit branch; do
  branch_name=$(echo "$branch" | tr -d '[]')
  if [ "$branch_name" != "main" ]; then
    merged=$(git branch --merged main | grep -w "$branch_name")
    if [ -n "$merged" ]; then
      echo "STALE (merged): $path [$branch_name]"
    fi
  fi
done
```

To remove: `git worktree remove <path>`

### switch
Context-switch to an existing worktree:
```bash
cd <worktree-path>
```

## Best Practices
- One worktree per feature branch
- Don't edit the same files across worktrees simultaneously
- Run tests from within the worktree, not the main tree
- Clean up after merge: `git worktree remove <path> && git branch -d <branch>`
- The main worktree at `$HOME` should stay on `main`

## Skill Chains

### Mandatory

None — git worktree management; local dev workflow.

### Advisory

- → `[stale-cleanup]` (clean up stale worktrees after merge)
- → `[test-run]` (run tests from within the worktree)

## Authority

- **T1 (TRUSTED)**: May run
- **T2 (Active/High)**: May run
- **T3 (Medium)**: May run
- **T4 (Probationary)**: May run with operator notification (worktree creation is reversible)
- **Operator**: Override any restriction
