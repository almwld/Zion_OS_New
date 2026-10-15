---
name: branch-strategy
description: Visualize branch topology, find stale/diverged branches, suggest cleanup.
version: 0.1.0
execution-mode: side_effecting
argument-hint: "[--action overview|stale|diverged|cleanup] [--remote]"
category: dev-tools
status: candidate
---
# Branch Strategy

Understand and manage branch topology. Find stale branches, detect dangerous divergence, visualize the branch graph, and plan cleanup.

## When to Use
- Before starting new work (what branches exist?)
- Periodic cleanup (which branches are stale?)
- After a release (which branches can be deleted?)
- When user says "branch topology", "stale branches", "branch cleanup"

## Execution

### overview
### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=branch-strategy] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

1. List all local and remote branches with last commit date
2. Show branch graph (simplified)
3. Highlight: current branch, branches ahead/behind main, merge status

### stale
1. Find branches with no commits in >14 days (configurable)
2. Check if merged to main (safe to delete)
3. Check if has open PR (don't delete)
4. Recommend: delete, keep, or investigate

### diverged
1. Find branches that have diverged significantly from main
2. Show commit count ahead/behind
3. Flag potential merge conflicts
4. Recommend: rebase, merge, or abandon

### cleanup
1. Run stale analysis
2. Delete branches that are merged and have no open PR
3. Report what was deleted and what was kept

## Output Format

```
Branch Strategy | {action}
==========================

## Branch Overview
| Branch | Last Commit | Ahead | Behind | PR | Status |
|--------|------------|-------|--------|-----|--------|
| main | 2h ago | - | - | - | CURRENT |
| feat/claude/fcntl | 1d ago | 0 | 0 | #239 merged | STALE-MERGED |
| feat/gemini/nist | 2d ago | 47 | 12 | none | DIVERGED |

## Recommendations
- DELETE: {list of safe-to-delete branches}
- REBASE: {list of branches that need rebasing}
- INVESTIGATE: {list of branches with unclear status}
```

## Skill Chains

### Mandatory

None — read-only git analysis; no branches are created, deleted, or merged by this skill.

### Advisory

- After stale branches found → `[stale-cleanup]` (delete them)
- After diverged branches found → `[conflict-resolve]` (prepare for merge)
- Many branches detected → `[worktree]` (work on multiple in parallel)
- After cleanup done → `[sitrep]` (verify clean state)

## Authority

- **T1 (TRUSTED)**: May run freely
- **T2 (Active/High)**: May run freely
- **T3 (Medium)**: May run freely
- **T4 (Probationary)**: May run (read-only git analysis — no state modified)
- **Operator**: Override any restriction
