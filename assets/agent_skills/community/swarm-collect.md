---
name: swarm-collect
description: Collect worktree artifacts from completed swarm agents — copy files, verify tests, batch commit, with optional CAID recycling pool support
version: 1.1.0
execution-mode: side_effecting
argument-hint: "[--commit] [--clean] [--pool]"
category: dev-tools
status: candidate
---
# Swarm Collect

Collect artifacts from completed swarm agent worktrees into the main working tree. Copies new/modified files, verifies tests pass, and optionally commits and cleans up. Supports both standard git worktrees and pre-warmed CAID worktree recycling pools.

## Arguments
- `--commit` — Stage and batch commit collected files after verification
- `--clean` — Remove worktrees after successful collection (or recycle slots if `--pool`)
- `--pool` — Use CAID Worktree Recycling Pool (`scripts/worktree_pool.py`) to manage bounded slots
- No args — Dry run: list what would be collected without modifying main

## Procedure

### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=swarm-collect] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

### 1. Enumerate Worktrees

```bash
git worktree list --porcelain
```

Identify all worktrees except the main one. For each, extract:
- Path, branch name, HEAD commit SHA
- Skip any worktree whose path matches the main working tree

### 2. Identify Changed Files Per Worktree

For each agent worktree at `<wt_path>`:

```bash
git -C <wt_path> diff --name-only main...HEAD
git -C <wt_path> diff --name-only HEAD          # unstaged changes
git -C <wt_path> diff --name-only --cached HEAD  # staged but uncommitted
```

Build a manifest: `{ worktree_path, branch, files_changed[], commits_ahead }`.
Flag conflicts where two worktrees modified the same file.

### 3. Copy Files to Main

For each non-conflicting file in the manifest:

```bash
cp <wt_path>/<file> <main_path>/<file>
```

If a file was modified in multiple worktrees, STOP and report the conflict. Do not overwrite. The user must resolve manually or choose a worktree winner.

### 4. Verify Tests

Run targeted tests on collected files:

```bash
python -m pytest $PROJECT_ROOT/tests/ -k "<test_pattern>" --tb=short -q
```

If `--commit` was requested but tests fail, abort the commit and report failures.

### 5. Batch Commit (if `--commit`)

```bash
git add <collected_files...>
git commit -m "$(cat <<'EOF'
feat(swarm): collect artifacts from <N> agent worktrees

Worktrees: <branch1>, <branch2>, ...
Files collected: <count>

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

### 6. Clean Worktrees (if `--clean`)

Only after successful commit:

```bash
git worktree remove <wt_path> --force
```

For each removed worktree, also delete the associated branch if it was fully merged:

```bash
git branch -d <branch_name>
```

### 6b. CAID Recycling Pool Mode (with `--pool`)

When scaling to high-concurrency swarms (e.g. 50+ concurrent agents), rapid creation and deletion of ephemeral git worktrees triggers git index lock contention (`index.lock`), high filesystem inode churn, and race conditions.

The **CAID Worktree Recycling Pool** (`scripts/worktree_pool.py`) maintains a bounded pre-warmed pool of slots (`slot-00` through `slot-49`) that are leased, reset, and reused in-place.

#### 1. Initialize Pool
```bash
python3 scripts/worktree_pool.py init --slots 50 --base main
```

#### 2. Worker Acquisition & Execution
Each swarm subagent acquires an idle slot with an isolated branch and a TTL lease:
```bash
# --owner-pid defaults to parent process PID ($$), ensuring child processes don't falsely trigger early reaping
SLOT_JSON=$(python3 scripts/worktree_pool.py acquire --task <task_id> --lease 15 --timeout 30 --owner-pid $$)
SLOT_PATH=$(echo "$SLOT_JSON" | jq -r .path)
SLOT_ID=$(echo "$SLOT_JSON" | jq -r .slot_id)

# Subagent works inside $SLOT_PATH on branch task/<task_id>
```

For long-running tasks, leases can be extended before expiry:
```bash
python3 scripts/worktree_pool.py renew --slot <slot_id> --task <task_id> --minutes 15
```

#### 3. Artifact Collection
Instead of parsing raw `git worktree list`, inspect active pool slots:
```bash
python3 scripts/worktree_pool.py status
# Diff changed files per slot
git -C <slot_path> diff --name-only main...HEAD
```
Follow steps 3-5 to verify and batch commit.

#### 4. Slot Recycling (Release)
Instead of `git worktree remove`, release the slot back to the idle pool:
```bash
python3 scripts/worktree_pool.py release --slot <slot_id> --task <task_id>
```
This resets the working tree to `--base`, cleans untracked files with `git clean -fdx`, deletes the ephemeral `task/<task_id>` branch, and marks the slot idle for the next agent.

#### 5. Automatic Zombie & Stale Lease Reaping
```bash
python3 scripts/worktree_pool.py sweep
```
Automatically resets and frees slots whose holding PID has exited and whose lease TTL has expired. If a lease has expired but the owner PID is still verified alive, the sweep preserves active work (fail-closed protection).

## Output Format

```
Swarm Collect | <repo_name>

Worktrees Found: <N>
  [1] <branch>  <path>  (<commits_ahead> commits, <files> files)
  [2] <branch>  <path>  (<commits_ahead> commits, <files> files)

Conflicts: <none | list of files with multiple sources>

Files Collected: <N>
  <file1>  (from <branch>)
  <file2>  (from <branch>)

Tests: PASS | FAIL (<details>)
Commit: <sha> | SKIPPED (no --commit) | ABORTED (tests failed)
Cleanup: <N worktrees removed> | SKIPPED (no --clean)

Next action: <suggestion>
```

## Safety Rules

- Never overwrite files with unresolved conflicts between worktrees
- Never clean worktrees before commit succeeds
- Never force-remove a worktree with uncommitted changes unless `--clean` is explicit
- Always run tests before committing
- Report files outside `$PROJECT_ROOT/` scope for manual review

## Skill Chains

### Mandatory (MUST pass before commit/clean)

- **`[test-run]`** MUST pass on collected files before `--commit` (already enforced in step 4)
- **`[dod]`** MUST pass for the task type before `--commit`

### Advisory

| After completing... | Consider... |
|---|---|
| `[swarm-collect] --commit` | `[test-run]` (full suite), `[changelog]` |
| `[swarm-collect] --clean` | `[stale-cleanup]` (leftover branches) |
| Conflicts found | Manual merge, then re-run `[swarm-collect]` |

## Authority

- **T1 (TRUSTED)**: May collect + commit + clean with `[test-run]` passed
- **T2 (Active/High)**: May collect + commit with `[test-run]` passed; clean requires operator approval
- **T3 (Medium)**: May collect (dry-run only); commit/clean require operator approval
- **T4 (Probationary)**: BLOCKED — cannot invoke this skill
- **Operator**: Override any restriction
