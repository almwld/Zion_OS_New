---
name: mesh-sync
description: Sync .agents/ content across the fleet via hummbl-io/agents GitHub remote. Git-based — push from any machine, pull on any machine. Replaces the old tar-over-ssh approach.
version: 0.3.1
execution-mode: side_effecting
argument-hint: "[--status|--check]  # read-only Git alignment; mutations use explicitly authorized Git commands"
category: fleet-ops
status: candidate
providers:
  required: [python]
---
# mesh-sync

## When to invoke

Use whenever:
- You add, modify, or delete skills/rules/agents on any machine
- A target machine is missing a skill or rule (e.g., `nexus` not found)
- You need a health check of fleet alignment
- After any session that changes `.agents/` content

## How to run

### Platform selection

On Linux and macOS, use the Bash examples below. On Windows, use PowerShell and
replace `~/.agents` with `$HOME\.agents`; use the Git CLI directly unless Git
Bash is installed.

From **any machine** (git-based, no SSH required):

```bash
# Show local sync status (git remote, branch, ahead/behind; no network)
bash ~/.agents/scripts/mesh-sync.sh --status

# Check if local is behind remote (dry-run, no changes)
cd ~/.agents && git fetch origin && git log --oneline HEAD..origin/main

# Pull latest from canonical remote only when the worktree is clean
cd ~/.agents && git pull --ff-only origin main

# Prepare a scoped change for review; never push directly to main
cd ~/.agents
git status --short --branch
git switch -c <type>/<caller>/<short-desc>
git add -- <scoped-paths>
git commit -S -m "<type>: <description>"
git push -u origin HEAD
```

## Canonical Source

**`hummbl-io/agents`** (private GitHub repo) is the canonical source for `.agents/` content across the fleet. Machines pull clean, fast-forward updates from `main`; changes are proposed on scoped branches and land through reviewed pull requests, never direct pushes to `main`.

| Machine | .agents path | Remote | Branch |
|---------|-------------|--------|--------|
| Delta | `~/.agents` | `hummbl-io/agents` | `main` |
| Workstation | `%USERPROFILE%\.agents` | `hummbl-io/agents` | `main` |
| Huxley | `~/.agents` | `hummbl-io/agents` | `main` |
| remote-node | (dormant since 2026-07-01) | — | — |

## What syncs via git

| Asset | Path | Syncs? |
|-------|------|--------|
| `.agents/skills/` | Skills | Yes |
| `.agents/rules/` | Rules | Yes |
| `.agents/agents/` | Agent profiles | Yes |
| `.agents/playbooks/` | Playbooks | Yes |
| `.agents/runbooks/` | Runbooks | Yes |
| `.agents/scripts/` | Scripts | Yes |
| `.agents/skills/` | Full skill archive | Yes |
| Fleet metadata (TOPICS.md, ROSTER.md, etc.) | Root files | Yes |

## What does NOT sync (gitignored)

- `.git/` — git internal state
- `goal-harness/state/` — runtime state (machine-local)
- `goal-harness/seeds/` — runtime-generated seeds (machine-local)
- `*.lock` — lock files
- `__pycache__/`, `*.pyc`, `*.pyo` — Python caches
- `.pytest_cache/` — test caches
- `*.egg-info/` — package metadata
- `state/__pycache__/` — state module caches

## Standard Operating Procedure (mandatory)

1. **After every session that modifies `.agents/` content**, inspect the
   worktree and prepare only the explicitly scoped paths on a topic branch:
   ```bash
   cd ~/.agents
   git status --short --branch
   git switch -c <type>/<caller>/<short-desc>
   git add -- <scoped-paths>
   git commit -S -m "<type>: <description>"
   git push -u origin HEAD
   ```
   Open or update the corresponding pull request; do not push directly to
   `main`.
2. **Before starting a session on any machine**, run:
   ```bash
   cd ~/.agents
   git status --short --branch
   git fetch origin
   git log --oneline HEAD..origin/main
   ```
   If the worktree is clean and local `main` is behind, fast-forward before
   proceeding:
   ```bash
   cd ~/.agents && git pull --ff-only origin main
   ```
3. **When onboarding a new machine**, clone the repo:
   ```bash
   git clone https://github.com/hummbl-io/agents.git ~/.agents
   ```
4. **Quarterly**, audit fleet alignment:
   ```bash
   # On each machine:
   cd ~/.agents && git rev-parse HEAD
   # Compare hashes — all machines should be at the same commit (or close)
   ```

## Conflict resolution

If a fast-forward pull cannot proceed:
1. Do not stash, overwrite, rebase, or merge automatically.
2. Record the branch, worktree status, and divergent refs.
3. Request direction from the owner of the local changes before reconciling.

For a machine with an unrelated pre-existing `.agents` directory, preserve it
and obtain an explicit migration plan; do not use `--allow-unrelated-histories`
as a routine sync operation.

## Skill Chains

### Mandatory

- **[MANDATORY]** Before a pull, commit, push, or bus post, obtain explicit
  user or delegated scope naming the repository, direction of sync, affected
  paths, and target branch or pull request.
- **[MANDATORY]** Inspect the worktree, branch, remote, and ahead/behind state
  before any stateful sync action. Stop when unrelated changes, a dirty
  worktree, or divergence is present.

## Authority

- **T1 (TRUSTED)**: May inspect and perform an explicitly scoped
  fast-forward pull or topic-branch update; may not force-push, overwrite, or
  push directly to `main`.
- **T2 (Active/High)**: May inspect and perform an explicitly scoped
  fast-forward pull or topic-branch update; may not force-push, overwrite, or
  push directly to `main`.
- **T3 (Medium)**: BLOCKED — may report sync state only; may not pull, commit,
  push, change remotes, or post coordination instructions.
- **T4 (Probationary)**: BLOCKED — may not invoke this skill.
- **Operator**: Required for remote changes, divergence resolution, bulk or
  machine-wide synchronization, force operations, or exceptions.

## Notes

- **No SSH required** — git over HTTPS with `gh` auth. Works from any machine with `gh` CLI authenticated.
- **No tar-over-ssh** — the old `mesh-sync.sh` script used tar-over-ssh to agent-node. This is deprecated. Git is the sync mechanism now.
- **Runtime state is machine-local** — `goal-harness/state/`, `goal-harness/seeds/`, and `*.lock` are gitignored. They will not sync and will not conflict.
- **`~/bin/` scripts are NOT synced via this repo** — `bus-global.py` and other bin scripts are tracked in `hummbl-io/apex-nexus` under `hosts/<machine>/bin/`. Update them there and deploy manually.
- **Push before posting bus instructions** — when posting deploy instructions to the bus, always push first so the commit hash is available for verification.

## Migration from old mesh-sync

The old `mesh-sync.sh` script (v0.1.0) used tar-over-ssh from agent-node as source of truth. The new approach (v0.3.0) uses reviewed GitHub pull-request updates to `hummbl-io/agents`. Key differences:
- Source of truth: GitHub repo (not a single machine)
- Sync method: git (not tar-over-ssh)
- Works from: any machine (not just Workstation)
- Requires: `gh` CLI auth (not SSH access to agent-node)
- Runtime state: gitignored (not excluded by script logic)

## Version

0.3.1 — 2026-09-05. Retired the executable tar-over-SSH path and restricted
the compatibility command to read-only Git status and alignment checks.
