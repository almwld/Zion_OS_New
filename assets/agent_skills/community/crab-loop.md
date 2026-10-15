---
name: crab-loop
description: CRAB-wrapped bounded iteration -- one WIP_START, a /loop converge/retry/watch body, one WIP_END with final snapshot. Prevents per-iteration bus spam and orphaned lanes. [Maps to CO13.]
version: 0.1.0
execution-mode: side_effecting
argument-hint: "<mode> <check> [fix <fix>] [every <interval>] [until <cond>] [max <N>] [--lane <full-lane>]"
category: dev-tools
status: candidate
---

## Context Gathering

### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus **before** any stateful action:
```
Type: SKILL_INVOKE
To: all
Message: [skill=crab-loop] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
Then gather live state. On Windows (PowerShell):
```powershell
pwd
git status --short --branch
git stash list
python $HOME\bin\bus-global.py status
python $HOME\bin\bus-global.py tail 5
```
On Unix (bash/zsh):
```bash
pwd
git status --short --branch
git stash list
python ~/bin/bus-global.py status
python ~/bin/bus-global.py tail 5
```
If a command errors, report "(<surface> unavailable)" -- do not abort the whole turn.

# CRAB-Loop

**CRAB outside, Loop inside.** CRAB is the turn wrapper (once); Loop is the iteration
engine (many). This skill bakes in the WIP_START / WIP_END bookending so a bounded
iteration over shared state stays auditable without per-iteration bus spam.

**Canonical sources** (do not duplicate): `.agents/rules/crab-protocol.md`,
`~/.agents/skills/crab/SKILL.md`, `~/.agents/skills/loop/SKILL.md`.

## When to Use
- A fix-check-fix cycle, retry, or poll touches shared state (repo, bus, CI, deploy).
- You want bounded iteration BUT need a lane claim + final snapshot receipt.
- Replacing the anti-pattern `[loop] /crab ...` (re-runs Act + re-posts WIP_START every iter).

## When to Skip
- Pure read-only polling with no shared-state mutation -- use `/loop` directly, no lane needed.
- A single consequential turn -- use `/crab` directly, no loop needed.

## Execution

### Step 1 -- Outer CRAB (once, before the loop)
- **CRAWL**: answer Context/Repo/Agents/Wire/Limits from the gathered state.
- **GitHub identity pre-check**: Before listing PR approval or review items,
  run `gh auth status` to capture the authenticated GitHub login. For each
  open PR, compare the PR author against the authenticated login. If they
  match, flag the PR as "BLOCKED: self-approval not permitted — needs
  different reviewer" instead of listing it as an actionable approval item.
  Do not attempt self-approval or list structurally impossible action items.
  (Origin: 2026-09-02 AAR — surface scan listed "approve PRs #75 and #77"
  without checking that the authenticated identity authored them.)
- **Stop before Act** if a bus `BLOCKED`/unresolved `PROPOSAL`/lane claim affects your scope,
  or stash/dirty state would collide.
- **Reason**: is the loop command reversible? Loop's "no destructive retries" constraint
  applies -- if the body mutates state (push, delete, deploy), get operator approval first.
- **Act**: post ONE `WIP_START` with `repo=`, `branch=`, `head=`, `dirty_total=`, `stash=`,
  `scope=<what the loop converges on>`, `next_owner=`, and `projects=` / `surfaces=` when
  the loop touches multiple PROJECTS/apex-nexus surfaces. Then launch the loop.

### Step 2 -- Loop body (delegated to /loop)
Pick a mode and run `/loop` with the parsed args:
- `converge "<check>" fix "<fix>"` -- check/fix/re-check until clean (default max 5)
- `retry <command>` -- repeat on failure until first success (default max 5)
- `watch <command> every <interval> until "<cond>"` -- poll until target (default max 20)
- `each "<items>" do "<per-item>"` -- map across items, one summary at the end

**Do NOT run full CRAB inside each iteration.** Loop's ceiling/interrupt/diff-aware
constraints replace per-iteration discipline. Mid-loop `STATUS` only on milestone or
convergence -- never one per poll. For `each` mode over N items, post ONE summary at end.

### Step 3 -- Closing CRAB (once, after convergence or ceiling)
Capture a FRESH snapshot (do not reuse loop variables):
```bash
git status -sb
git status --short --untracked-files=all
git stash list
git rev-parse --short HEAD
git rev-parse --abbrev-ref --symbolic-full-name '@{u}'
git rev-list --left-right --count <base>...HEAD
```
Then post the closer:
- **Converged** -> `WIP_END` with the standard receipt schema + verification performed.
- **Hit ceiling / blocked** -> `BLOCKED` with `blocked_by=ceiling`, `evidence=`, `next_owner=`.
Run `check-orphaned-wips.py --sender <identity> --lane <full-lane> --quiet`; non-zero exit
means the lane is still open -- post `WIP_END` (or `HANDOFF`+`WIP_END` if transferring).

## Output Format
```
CRAB-Loop | <date> <time UTC> | <repo> | <branch> | <mode>
══════════════════════════════════════════════════
OPEN   : WIP_START posted -- scope=<...> lane=<...>
LOOP   : <mode> -- <N/max iters> -- <last check result>
CLOSE  : <WIP_END|BLOCKED> -- converged at iter <n> | ceiling hit
SNAP   : head=<sha> upstream=<ref|none> ahead=<n> behind=<n> dirty=<n> stash=<n>
NEXT   : <concrete next step or next_owner>
```

## Base120 Context
- Primary: **CO13** (Multi-Agent Coordination / Turn Execution Discipline)
- Related: **IN6** (Evidence Verification -- fresh final snapshot, no reused loop vars)

## Skill Chains

### Mandatory
- None -- this composes `/crab` and `/loop`; both have their own chains.

### Advisory
- After `[crab-loop]` converge -> `[commit]` if code changed, `[retrospective]` if a
  recurring pattern surfaced, `[ledger]` if the loop took many retries to converge.
- If blocked at ceiling -> `[handoff]`, `[sitrep]`.

## Authority
- **T1 (TRUSTED)**: Full access -- all loop modes including destructive bodies
- **T2 (Active/High)**: Full access -- all loop modes including destructive bodies
- **T3 (Medium)**: Operator approval required for destructive bodies; read-only bodies freely
- **T4 (Probationary)**: Read-only bodies only (watch, converge with read-only checks)
- **Operator**: Override any restriction
