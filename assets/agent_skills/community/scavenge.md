---
name: scavenge
description: "Read a retirement index from apex-nexus and execute scavenger-mode work items in dependency order. Use when the operator says 'scavenge', 'do the scavenger work', 'clean up after archive', or references post-archive migration items."
version: 0.1.0
execution-mode: side_effecting
argument-hint: "[<repo-name>]  - e.g., 'hummbl-governance' (defaults to scanning all retirement indexes)"
category: fleet-ops
status: candidate
---
# [scavenge]

> The repo is archived. The local checkout still runs everything. Scavenger-mode is the controlled migration from local checkout to successor packages — on-demand, not rushed.

## When to Use

- After a repo has been archived via `gh repo archive` and the operator wants to migrate runtime dependencies to successor packages
- Operator says "scavenge", "do the scavenger work", "clean up the archived repo references", "migrate the MCP servers"
- A retirement index exists in `apex-nexus/docs/operations/` with a scavenger-mode work item list

## When NOT to Use

- The repo is NOT yet archived — use the retirement index gate process instead
- No retirement index exists — create one first per `cross-repo-retirement-scan.md` rule
- Operator wants to unarchive — use `gh repo unarchive <repo>` directly

## Procedure

### 1. Load the retirement index

```
Get-ChildItem "$HOME\PROJECTS\apex-nexus\docs\operations" -Filter "*RETIREMENT_INDEX*"
```

Read the index for the target repo. If no repo specified, list all retirement indexes and ask the operator which one to scavenge.

### 2. Extract scavenger-mode work items

The retirement index contains a "Scavenger-mode work items" section. Each item has:
- A description (what to migrate)
- A current state (where it runs now — local checkout)
- A target state (where it should run — successor package)
- Dependencies (what must complete first)

### 3. Determine dependency order

Apply this ordering:
1. **Import repointing** (bus-global.py, scripts) — no dependencies, unblocks everything
2. **MCP server relocation** — depends on import repointing for the target package
3. **Scheduled task relocation** — depends on MCP server relocation if tasks call MCP servers
4. **Env var unbinding** — depends on import repointing (paths must be valid first)
5. **Reference scrub** — last, after all runtime paths are repointed
6. **Service extraction** (280 services to successor repos) — largest effort, needs RFC, defer unless operator directs
7. **PyPI publication** — defer until extraction is complete

### 4. Execute items

For each item in order:
1. Read the current configuration (MCP config, scheduled task XML, env var, script)
2. Identify the exact string/path to change
3. Verify the successor package exists and is importable
4. **Diff-direction check** (before saving any modified file from a dirty
   worktree): run `git diff --stat --no-index <main-version> <worktree-version>`
   to determine whether the worktree file is ahead of or behind main. If main
   has more insertions (i.e., main has superseded the worktree version), skip
   the file and annotate `stale — main superseded by <commit>`. Only scavenge
   files where the worktree has MORE content OR introduces files not in main.
   - Worked example: `bus-lexicon.md` on a stale branch showed main ahead
     27/47 — the worktree version was a stale regression from 3 merged PRs
     ago. Skipping it saved 29% of scavenge effort that would have been
     wasted on a regression.
5. Make the change
6. Test the change (run the MCP server, trigger the scheduled task, source the env var)
7. Post a STATUS receipt to the bus: `host=<machine> [lane=scavenge/<repo>] <item> COMPLETE. <what changed>. <test result>.`
8. Update the retirement index: mark the item as `migrated` in the JSON capability index

### 4b. Pre-push CI trigger check

Before pushing any branch during scavenge work, verify the branch will get
CI coverage. [RETIRED: founder-mode archived 2026-08-18] Origin: 2026-08-18 — `scavenge/founder-mode-import` was pushed
but no CI triggered; `gh run list` showed runs only on `main` and
`feat/devin/extract-observability-modules`. The cause was unverified (AAR
flagged as Improve #4).

**Steps:**
1. Read the workflow `on:` triggers:
   ```bash
   cat .github/workflows/ci.yml | grep -A 10 "^on:"
   ```
2. Check whether the target branch matches the `on: push: branches:` list
   or `on: pull_request:` triggers.
3. If the branch is NOT covered by any trigger:
   - **Option A (preferred):** Open a PR (`gh pr create`) — PR CI often
     covers branches that push CI does not.
   - **Option B:** Add the branch pattern to the workflow `on:` section
     (requires a separate commit to the workflow file).
   - **Option C:** Consciously accept no-CI and note it in the SITREP:
     `host=<machine> [lane=scavenge/<repo>] <branch> pushed with NO CI
     coverage — operator accepted.`
4. After push, verify CI triggered:
   ```bash
   gh run list --branch <branch> --limit 3
   ```
5. If no runs appear and CI was expected, do NOT assume "CI will run
   eventually" — investigate the workflow triggers before proceeding.

**Do not push blind and assume CI will run.** An unverified push is a
silent gap in the safety net.

### 5. Verify zero runtime dependency

After all items are complete:
1. `grep -rn "<repo_name>\|<repo-name>" --include="*.py" --include="*.json" --include="*.yaml" --include="*.toml"` across all fleet surfaces
2. Confirm no runtime import path references <repo_name>
3. Confirm no MCP config points to a <repo_name> venv
4. Confirm no scheduled task references a <repo-name> script path
5. Confirm no env var binds to a <repo-name> repo path

### 6. Post completion receipt

```
<timestamp> devin all STATUS host=<machine> [lane=scavenge/<repo>] SCAVENGER-MODE COMPLETE. <N> items migrated. Zero runtime dependencies on <repo> remain. Retirement index updated to v<version>. Local checkout can now be deleted if operator directs.
```

## Constraints

- **Do NOT delete local checkouts** — the operator directs checkout deletion, not the agent. Scavenger-mode migrates dependencies; it does not delete source.
- **Test after every change** — each migration item must be verified before moving to the next. A broken MCP server or scheduled task is worse than a lingering <repo_name> reference.
- **Post bus receipts** — every item completion gets a STATUS post for fleet visibility.
- **Update the retirement index** — mark items as `migrated` in the JSON capability index as they complete.
- **Stop on failure** — if a migration item fails and cannot be resolved in 3 attempts, post a BLOCKED to the bus and ask the operator for guidance.

## Origin

AAR 2026-08-17 — [RETIRED: founder-mode archived 2026-08-18] founder-mode archival created 8 scavenger-mode work items that were deferred to on-demand post-archive migration. This skill provides the structured execution path so the operator can invoke scavenger-mode when ready without re-planning from scratch.

## Mandatory

- A retirement index for the target repo must exist in `apex-nexus/docs/operations/` before scavenger-mode runs — do not scavenge a repo with no retirement index (create one first per `cross-repo-retirement-scan.md`).
- The target repo must already be archived (`gh repo archive`) — scavenger-mode migrates dependencies off an already-decommissioned repo; it is not a live-repo refactor tool.
- Every migration item must be tested (§4 step 6) and receipted (§4 step 7) before moving to the next item.

## Authority

- **T1 (TRUSTED)**: May run with retirement index + archived-repo preconditions satisfied
- **T2 (Active/High)**: May run with retirement index + archived-repo preconditions satisfied
- **T3 (Medium)**: May run with retirement index + archived-repo preconditions satisfied
- **T4 (Probationary)**: BLOCKED
- **Operator**: Override any restriction; only the operator directs local-checkout deletion (never this skill)

## Status

DRAFT v0.1.0 — pending Phase -1/0/1 pipeline validation via skills-factory. Functional but not yet eval-tested.
