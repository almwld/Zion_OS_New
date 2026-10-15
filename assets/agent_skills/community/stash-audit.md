---
name: stash-audit
description: Detect stashes across PROJECTS repos, classify each by contamination risk (stash branch != current branch), age (>=14d = stale), and missing manifest (MYSTERY). Read-only — never drops or applies. Use before any cross-branch git op, in session-start hook, or as a periodic loop.
version: 1.0.0
execution-mode: advisory
category: dev-tools
status: tested
providers:
  required: [bash, python]
---
# Stash Audit

Stashes are git's foot-gun. `git stash apply` on the wrong branch silently contaminates a PR with another lane's work. Origin: 2026-04-26 PR drain incident at HUMMBL — DEV_PROGRAMS_INVENTORY edits traveled across worktrees via stash, detected only at rebase pre-flight.

This skill audits stashes across all PROJECTS repos, classifies each, and recommends per-stash action. **It never executes destructive ops.** Operator decides what to drop, apply, or migrate.

## When to use

- Before any cross-branch operation (rebase, branch switch, cherry-pick)
- Session start (silent unless risk found)
- Weekly hygiene to drain stale + mystery stashes
- During long PR-drain sessions where stashes accumulate fast

## Invocation

```bash
# Full report (markdown) — default scans ~/PROJECTS and $HOME/PROJECTS
python ~/.agents/skills/stash-audit/audit.py

# JSON for filtering / piping
python ~/.agents/skills/stash-audit/audit.py --json | jq '.[] | select(.classification | contains("CONTAMINATION"))'

# Silent unless stashes exist — for hooks
python ~/.agents/skills/stash-audit/audit.py --quiet-on-clean

# Only print if CONTAMINATION-RISK or MYSTERY present — strictest hook variant
python ~/.agents/skills/stash-audit/audit.py --risk-only

# Specific repo
python ~/.agents/skills/stash-audit/audit.py --repo ~/.agents

# Custom roots (repeatable)
python ~/.agents/skills/stash-audit/audit.py --root $HOME/PROJECTS --root /d/altrepos
```

## Classification

| Class | Definition | Recommended action |
|---|---|---|
| **TIDY-MATCH** | stash branch == current branch | OK to apply when ready |
| **CONTAMINATION-RISK** | stash branch != current branch | NEVER `git stash apply` here. Switch branch first. |
| **MYSTERY** | no `On <branch>:` parseable | View `git stash show -p <ref>`; recover or drop |
| **+ STALE** | any class, age >= 14 days | Commit-to-branch or drop |

## Loop wiring options

The operator chooses one or more:

### A. Session-start hook (always-on, low-touch)
Add to `~/.agents/hooks/session-start.sh`:
```bash
python ~/.agents/skills/stash-audit/audit.py --risk-only 2>/dev/null
```
Silent unless CONTAMINATION-RISK or MYSTERY stashes exist; surfaces them at every session start. Zero noise on clean fleet.

### B. Daily Windows Task Scheduler
Run once per day, log to `~/.claude/logs/stash-audit-YYYY-MM-DD.md`. Suggested time: 04:00 local.
```powershell
schtasks [create] [tn] "ClaudeStashAudit" [tr] "python $env:USERPROFILE\.claude\skills\stash-audit\audit.py > $env:USERPROFILE\.claude\logs\stash-audit-$(Get-Date -Format yyyy-MM-dd).md" [sc] daily [st] 04:00
```

### C. In-session loop (active monitoring)
During long multi-lane work where stashes accumulate fast:
```
[loop] 1h [stash-audit]
```
or self-paced:
```
[loop] [stash-audit]
```

### D. Pre-rebase / pre-merge guard (manual habit)
Run before any cross-branch op:
```bash
python ~/.agents/skills/stash-audit/audit.py --risk-only && echo "OK to proceed" || echo "RESOLVE STASHES FIRST"
```

## Decision: never auto-drop

This skill is **strictly advisory**. It never runs `git stash drop`, `git stash apply`, `git stash pop`, or any destructive op. Reasoning: stashes are operator intent expressed in shorthand; auto-disposing them is a CRDT-level mistake. Even STALE stashes may encode a recovery path the operator hasn't executed yet.

## Pre-drop verification protocol (when the operator decides to drain)

When the operator authorizes drops, the agent executing them MUST follow this checklist before running `git stash drop` on any stash. Sample-verification has known-failed before — see origin note.

1. **List ALL files in the stash, not a sample**:
   ```bash
   git stash show -u --name-only stash@{N}     # NOTE: -u flag mandatory; bare --stat misses untracked-only stashes
   ```
2. **Per-file on-main check** — every file path must be tested individually:
   ```bash
   for f in $(git stash show -u --name-only stash@{N}); do
     printf "%-65s " "$f"
     git cat-file -e "main:$f" 2>/dev/null && echo "ON MAIN" || echo "NOT on main"
   done
   ```
3. **For files NOT on main**: search history across all branches:
   ```bash
   git log --all --oneline -- <path>
   ```
   Empty result = unique unshipped work; do NOT drop without preserving.
4. **Reverse-apply check** — does main already contain the stashed *content*?
   ```bash
   git stash show -p stash@{N} | git apply --check --reverse 2>&1 | head -5
   ```
   - Clean: stash content is already on main, safe to drop.
   - Errors: stash diverged from main (typical for WIP captured before squash-merge); safe to drop only if PR is canonical.
5. **PR state for the stash branch** — confirm the work shipped:
   ```bash
   gh pr list --head "$(git stash list --pretty='%gs' | sed -n "$((N+1))p" | sed -E 's/(WIP )?[Oo]n ([^:]+):.*/\2/')" --state all
   ```

**Hard rule**: 100% of files in the stash must clear (1)+(2)+(3) OR the stash must be preserved before drop. Sample-based verification is the known failure mode.

Origin: 2026-05-07 stash drain — 7 unique stashes (35 displayed across 5 worktrees). Initial drop recommendation on stash{1} based on 3/8 files clearing; apex re-verification caught the remaining 5 files were unique unshipped work (803 lines of publication drafts with zero git history). Without the second pass, the work would have been silently lost.

## Park-branch preserve-then-drain pattern

To safely drain a stash containing unique unshipped work:

```bash
# 1. Create a permanent ref pointing at the stash commit (does NOT switch HEAD)
git branch park/<descriptive-slug> stash@{N}

# 2. Drop the stash entry — the branch ref keeps the commit alive in the graph
git stash drop stash@{N}

# 3. Recover later via:
git stash apply park/<descriptive-slug>           # apply modifications + untracked
git show park/<descriptive-slug>:<path>           # tracked-file modifications only
git show park/<descriptive-slug>^3:<path>         # untracked files (3rd parent)
```

Why `git branch <name> stash@{N}` and not `git stash branch`:
- `git stash branch` switches HEAD on the current worktree (may dirty active work).
- Raw `git branch <name> stash@{N}` is non-destructive — preserves the stash commit graph (including the `^3` untracked-files parent) without switching.
- Stashes are reachability-rooted at their reflog entry; branch refs survive `git gc`.

Stash commit structure (relevant for recovery):
- 1st parent: HEAD at stash time
- 2nd parent: index state at stash time
- 3rd parent: untracked files (only when stash created with `-u`)

Convention: park branches are named `park/<descriptive-slug>` (e.g. `park/governance-sync-leftovers`, `park/agent-kernel-safety-snapshot`). Schedule a 30-day review to either promote them to `feat/...` PRs or retire them.

## Output

Markdown report grouped by repo:

```
# Stash Audit

Total stashes: 7 across 1 repo(s)

- CONTAMINATION-RISK: 6
- STALE (>= 14d): 2
- MYSTERY: 0

## ~/.agents

Current branch: `docs/claude/proposal-002-fleet-coherence`

| ref | stash branch | age (d) | classification | recommendation |
|---|---|---|---|---|
| `stash@{0}` | `chore/devin/project-config-bootstrap` | 2 | CONTAMINATION-RISK | SWITCH BRANCH FIRST: ... |
...
```

## Cross-machine note

Stashes are local-only — they don't replicate across the mesh. This skill must run on each machine independently. Sync the skill via `[mesh-sync]` to install on remote-node (dormant since 2026-07-01 — skip) + huxley.

## See also

- `~/.agents/rules/skill-quality.md` — skill creation invariants
- `[branch-strategy]` — branch topology and stale-branch detection
- `[worktree]` — worktree management
- `[stale-cleanup]` — orphaned-branch cleanup (does NOT touch stashes)
- Memory `feedback_anvil_unexpected_shutdowns.md` — adjacent volatility risk
