---
name: watch-session
description: Monitor a parallel agent session's work across bus, git, and filesystem surfaces.
version: 0.1.0
execution-mode: advisory
argument-hint: "[--surfaces bus,git,fs] [--interval 60] [--checks 10] [--branch <name>] [--glob <pattern>]"
category: fleet-ops
status: candidate
---
# Watch Session

Monitor a parallel agent session's work across 3 surfaces: coordination bus, git, and filesystem. Codifies the ad-hoc observation pattern from Apr 17 multi-session work.

## When to Use
- Running parallel agent sessions and want to track the other session's progress
- Monitoring a Codex or Gemini agent working in a worktree
- Watching for a specific PR, branch, or file to land before continuing your own work
- Post-dispatch monitoring after `[swarm]` or `[dispatch]`

## Usage

```
[watch-session]                                          # all 3 surfaces, 10 checks at 60s
[watch-session] --surfaces bus,git --interval 30         # bus + git only, every 30s
[watch-session] --branch feat/codex/new-feature          # watch a specific branch
[watch-session] --glob "hummbl_governance/services/*.py"      # watch specific files
[watch-session] --checks 5 --interval 120                # 5 checks, 2 min apart
```

## Arguments

| Arg | Default | Description |
|-----|---------|-------------|
| `--surfaces` | `bus,git,fs` | Comma-separated: `bus`, `git`, `fs` (any combination) |
| `--interval` | `60` | Seconds between checks |
| `--checks` | `10` | Number of check cycles before stopping |
| `--branch` | *(auto-detect)* | Specific branch to watch for changes |
| `--glob` | `**/*` | File glob pattern for filesystem surface |
| `--since` | *(session start)* | ISO timestamp or relative (e.g., `10m`, `1h`) for baseline |

## Execution

### 1. Capture Baseline (once, at start)

Before the first check cycle, snapshot the current state of each surface:

```bash
# Bus baseline: line count
BUS_BASELINE=$(wc -l < hummbl_governance/_state/coordination/messages.tsv)

# Git baseline: HEAD hash + branch list
GIT_BASELINE=$(git rev-parse HEAD)
GIT_BRANCHES_BASELINE=$(git branch -r --no-merged origin/main 2>/dev/null | wc -l)

# Filesystem baseline: timestamp for find
FS_BASELINE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
```

### 2. Check Cycle (repeat N times)

For each check, scan the active surfaces and diff against baseline:

#### Surface: Bus
```bash
# New messages since baseline
BUS_NOW=$(wc -l < hummbl_governance/_state/coordination/messages.tsv)
BUS_DELTA=$((BUS_NOW - BUS_BASELINE))

# If new messages, show them
if [ $BUS_DELTA -gt 0 ]; then
  tail -$BUS_DELTA hummbl_governance/_state/coordination/messages.tsv
fi
```

Extract from new messages:
- **Sender** identity (which agent is active)
- **Message type** (STATUS, MILESTONE, BLOCKED, HANDOFF — important signals)
- **Content summary** (first 120 chars of message field)

Flag immediately if: `BLOCKED`, `HANDOFF`, or `MILESTONE` type detected.

#### Surface: Git
```bash
# Check for new commits
GIT_NOW=$(git rev-parse HEAD)
git fetch origin --quiet 2>/dev/null

# New branches
git branch -r --no-merged origin/main 2>/dev/null

# If watching a specific branch
if [ -n "$WATCH_BRANCH" ]; then
  git log --oneline origin/$WATCH_BRANCH..origin/$WATCH_BRANCH 2>/dev/null | head -5
fi

# Recent commits across all branches (last N minutes)
git log --all --oneline --since="$INTERVAL seconds ago" 2>/dev/null | head -10
```

Extract:
- **New commits** (hash, message, author)
- **New branches** (created since baseline)
- **PR activity** (if `gh` available: `gh pr list --state open --json number,title,headRefName`)

#### Surface: Filesystem
```bash
# Files modified since baseline timestamp, matching glob
find . -name "$GLOB_PATTERN" -newer "$FS_BASELINE_FILE" -type f 2>/dev/null | \
  grep -v '.git/' | grep -v 'node_modules/' | grep -v '__pycache__/' | head -20
```

Extract:
- **New files** (created since baseline)
- **Modified files** (changed since baseline)
- **Deleted files** (if tracking specific paths)

### 3. Unified Timeline Entry

After each check, produce a single timeline entry:

```
[3/10] 14:23:05 | bus: +4 msgs (claude-code STATUS x2, MILESTONE x1, codex ACK x1)
                 | git: +2 commits on feat/codex/new-feature (abc1234, def5678)
                 | fs:  3 files changed (services/new_thing.py, tests/test_new_thing.py, CLAUDE.md)
```

### 4. Change Detection & Alerts

Post a summary to the bus when significant changes are detected:

**Significant = any of:**
- `BLOCKED` message on bus (any agent)
- `HANDOFF` or `MILESTONE` message (session lifecycle event)
- New branch created or PR opened
- >10 files changed in a single check interval
- Watched branch updated

Post a STATUS to the bus naming the detected milestone.
```
Type: STATUS
To: all
Message: watch-session: [MILESTONE detected] <agent> posted MILESTONE on <branch> — '<one-line summary>'
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

### 5. Final Summary

After all checks complete (or on interrupt), produce a summary report.

## Output Format

```
Watch Session | <surfaces> | <checks>x<interval>s
========================================

## Baseline
- Bus: <N> messages at <timestamp>
- Git: HEAD <hash> on <branch>, <N> remote branches
- Filesystem: watching <glob> from <timestamp>

## Timeline
[1/10] HH:MM:SS | bus: <delta> | git: <delta> | fs: <delta>
[2/10] HH:MM:SS | bus: <delta> | git: <delta> | fs: <delta>
...

## Summary
- Bus: <total new messages>, <breakdown by type>
- Git: <total new commits>, <branches created/updated>
- Filesystem: <total files changed>, <top 5 most-changed paths>
- Alerts fired: <count> (<types>)

## Notable Events
- [HH:MM:SS] MILESTONE: <summary>
- [HH:MM:SS] BLOCKED: <summary>
- [HH:MM:SS] New PR: #<N> <title>

## Next Action
<suggestion based on what was observed>
```

## Constraints

- **Read-only.** This skill never modifies files, commits, or pushes. Advisory only.
- **Bus posts are STATUS only.** Watch-session posts are informational, never DECISION or DIRECTIVE.
- **Respects bus protocol.** Uses `python3 -m hummbl_governance.bus.bus_writer` for any bus posts.
- **Ceiling.** Maximum 30 checks. Default timeout 20 minutes. No infinite loops.
- **Interruptible.** On interrupt, show partial timeline and summary collected so far.
- **Minimal bus noise.** Only post to bus on significant events (BLOCKED, MILESTONE, HANDOFF), not every check cycle.

## Chain

After `[watch-session]`, consider:
- `[sitrep]` — if the watched session completed and you need to assess overall state
- `[review-pr]` — if a PR was opened by the watched session
- `[conflict-resolve]` — if both sessions touched the same files
- `[handoff]` — if you're picking up work from the completed session

## Skill Chains
- For monitor opencode sessions delegated via the bridge -> `[cross-runtime-bridge]` (`python ~/bin/cross_runtime_bridge.py sessions`)
