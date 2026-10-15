---
name: repo-sync
description: Check status across all $PROJECTS_DIR/ repos for dirty state, remote sync, and CI
version: 0.1.0
execution-mode: advisory
argument-hint: "[filter] [--fetch]"
category: dev-tools
status: candidate
---
# [repo-sync]

## When to Use
- Morning check: what repos need attention?
- Before a push session: which repos have uncommitted work?
- After multi-repo work: verify everything is clean and pushed
- Checking CI status across the fleet

## Execution

### Steps
1. Enumerate all git repos under `$PROJECTS_DIR/` (also check root `~/` repo)
2. For each repo:
   a. `git -C <path> status --porcelain` -- count dirty files
   b. `git -C <path> log --oneline -1 --format='%h %ar %s'` -- last commit
   c. `git -C <path> branch --show-current` -- current branch
   d. If `--fetch`: `git -C <path> fetch --quiet` then `git -C <path> status -sb` for ahead/behind
   e. If `.github/workflows/` exists and gh is authed: `gh run list --repo <remote> --limit 1 --json conclusion -q '.[0].conclusion'`
3. Sort by priority: dirty first, then behind remote, then stale (>7 days since last commit)
4. Summarize totals

### Filters
- `dirty` -- only repos with uncommitted changes
- `behind` -- only repos behind remote (requires --fetch)
- `stale` -- repos with no commits in >7 days
- `ci-red` -- repos with failing CI

## Output Format

```
Repo Sync | all repos
============================================================
Scanned: 20 repos in $PROJECTS_DIR/ + 1 root

| Repo              | Branch | Dirty | Remote     | Last Commit | CI   |
|-------------------|--------|-------|------------|-------------|------|
| hummbl-governance      | main   | 28    | UP TO DATE | 2h ago      | pass |
| your-package | main   | 0     | UP TO DATE | 1d ago      | pass |
| your-app   | main   | 3     | 2 BEHIND   | 3d ago      | fail |
| your-org        | main   | 0     | UP TO DATE | 5d ago      | --   |
| swarm-test        | main   | 0     | UP TO DATE | 2d ago      | pass |
| ...               |        |       |            |             |      |

Summary: 3 dirty, 1 behind remote, 1 CI failing, 2 stale (>7d)

Action needed:
  1. your-app: pull 2 commits + fix CI
  2. hummbl-governance: 28 dirty files (commit or stash)
------------------------------------------------------------
Next: [cross-repo-grep] or [mono-diff] (dig into changes)
```

## Skill Chains
- After `[repo-sync]` showing dirty repos -> suggest `[commit]` for each
- After `[repo-sync]` showing CI failures -> suggest `[ci-monitor]`
- Use before `[mono-diff]` to understand current state
