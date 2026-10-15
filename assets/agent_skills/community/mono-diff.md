---
name: mono-diff
description: Show changes across multiple repos since a date with commit summaries
version: 0.1.0
execution-mode: advisory
argument-hint: "[since-date] [--repo filter] [--author filter]"
category: dev-tools
status: candidate
---
# [mono-diff]

## When to Use
- Weekly review: what changed across all repos?
- After a multi-repo work session: summarize all changes
- Preparing a changelog or status update for stakeholders
- Understanding cross-repo impact of a coordinated change

## Execution

### Inputs
- **since-date** (optional): Default 7 days ago. Accepts: `YYYY-MM-DD`, `yesterday`, `last-week`, `last-month`
- **--repo**: Only include specific repo(s), comma-separated
- **--author**: Filter by git author name or email

### Steps
1. Enumerate all git repos under `~/PROJECTS/` and root `~/`
2. For each repo:
   a. `git log --oneline --since=<date>` -- list commits
   b. `git diff --stat HEAD~N..HEAD` or since-based diff -- get committed change stats
   c. `git status --short --untracked-files=all` -- flag current uncommitted/untracked work separately
   d. Count: commits, committed files changed, insertions, deletions, plus dirty/untracked counts
3. Skip repos with zero commits in the period only if their worktree is also clean; otherwise include a "dirty but no commits" section
4. Sort by activity (most commits first)
5. Group commits by conventional commit type (feat, fix, refactor, test, etc.)
6. Aggregate cross-repo totals

## Output Format

```
Mono Diff | since 2026-03-18 (7 days)
============================================================
Active repos: 5/20 | Total: 47 commits, +3,218 -620

## hummbl-governance (28 commits, +1,840 -620)
  feat: agentic modules system + 10-arbiter quality suite (#221)
  refactor: The Forge -> The Foundry (#223)
  fix(ci): route toolchain-verify to self-hosted runner (#228)
  ci: temporarily switch to GitHub-hosted runners (#227)
  ... (24 more)

## hummbl-governance (12 commits, +476 -89)
  feat: add delegation token module
  test: 476 tests passing
  fix: schema validator edge case
  ... (9 more)

## swarm-test (5 commits, +180 -23)
  feat: experiment 015 context ingestion
  fix: tmux dispatch YAML whitespace

## foundermode-app (2 commits, +30 -5)
  ci: migrate to self-hosted runners
  fix: editable install flag

## Summary by Type
  feat: 15 | fix: 12 | refactor: 8 | ci: 6 | test: 4 | docs: 2
------------------------------------------------------------
Next: [changelog] (for release notes) or [repo-sync] (current state)
```

## Skill Chains
- After `[mono-diff]` -> suggest `[changelog]` for release notes
- After `[mono-diff]` -> suggest `[pr-summary]` for open PRs
- Use after `[repo-sync]` for full picture (state + history)
