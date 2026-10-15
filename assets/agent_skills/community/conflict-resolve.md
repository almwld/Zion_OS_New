---
name: conflict-resolve
description: Guided merge conflict resolution with context from both sides and semantic understanding.
version: 0.1.0
execution-mode: side_effecting
argument-hint: "[--strategy ours|theirs|manual] [--file PATH]"
category: fleet-ops
status: candidate
---
# Conflict Resolve

Intelligent merge conflict resolution. Reads both sides of a conflict, understands the intent of each change, and suggests the correct resolution -- or applies it automatically for mechanical conflicts.

## When to Use
- After `git merge` or `git rebase` produces conflicts
- When user says "merge conflict" or "resolve conflict"
- After `[cherry-pick-safe]` finds conflicts

## Execution

### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=conflict-resolve] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

1. **Detect conflicts**: `git diff --name-only --diff-filter=U`
2. **For each conflicted file**:
   a. Read the conflict markers
   b. Identify the ours/theirs changes
   c. Check git log for both sides to understand intent
   d. Classify conflict type:
      - **Mechanical** (both sides changed whitespace, imports, etc.) → auto-resolve
      - **Additive** (both sides added different things) → combine
      - **Semantic** (both sides changed the same logic differently) → needs judgment
   e. Suggest or apply resolution
3. **Verify**: Run tests on resolved files
4. **Report**: Summary of all resolutions

## Output Format

```
Conflict Resolve | {N} files
=============================

## Conflicts Found
| File | Type | Resolution | Confidence |
|------|------|-----------|------------|
| services/scheduler.py | Semantic | Manual | LOW |
| tests/test_health.py | Additive | Auto-combined | HIGH |
| CLAUDE.md | Mechanical | Auto-ours | HIGH |

## Detailed Resolutions
### {file}
**Ours** ({branch}): {what our side did}
**Theirs** ({branch}): {what their side did}
**Resolution**: {what we chose and why}
```

## Skill Chains

### Mandatory

None — conflict resolution is a normal dev workflow; the working tree is already in a conflicted state that must be resolved.

### Advisory

- After conflicts resolved → `[test-run]` (verify nothing broke)
- Complex semantic conflict → `[git-archaeology]` (understand history)
- Frequent conflicts in same file → `[tech-debt]` (file needs decomposition)
- All resolved → `[commit]` (commit the merge)

## Authority

- **T1 (TRUSTED)**: May run freely
- **T2 (Active/High)**: May run freely
- **T3 (Medium)**: May run freely
- **T4 (Probationary)**: May run with operator notification (working-tree modifications require awareness)
- **Operator**: Override any restriction
