---
name: skills-fix
description: Auto-remediate skill format issues found by /skill-test (dry-run by default; --apply to execute). Backfills missing version/index/routing entries with batch paging and idempotency guarantees.
version: 1.2.0
execution-mode: remedial
argument-hint: "[--apply | --class=missing-version|not-in-index|not-in-routing] [--batch N --offset M]"
category: hummbl-research
status: tested
providers:
  required: [bash, python]
---
# Skills Fix Command

Auto-remediation pair to `[skill-test]`. Lints all SKILL.md files, then backfills missing `version:` frontmatter, missing `_index/SKILL.md` entries, and missing `skill-routing.md` patterns. Dry-run by default — `--apply` required for writes.

## When to Use
- After `[skill-test]` reports format failures
- After a batch of `[skill-create]` invocations (typical batch creates a few gaps)
- Periodic catalog hygiene (monthly)
- Before `[mesh-sync] push` (sync clean state)

## Execution

### 1. Run [skill-test] logic inline
Reuse `[skill-test]`'s issue taxonomy. Do not invent a parallel checklist — if `[skill-test]` says a skill is clean, this skill must agree.

**Self-referential scan:** The skills-fix skill itself is in scope. Include `~/.agents/skills/skills-fix/SKILL.md` in every scan. A drift-remediation skill with its own drift is a credibility problem. (Origin: 2026-09-02 self-review — skills-fix had `skills-full/` path drift in its own step 4 that wasn't caught until operator asked.)

### 2. Bucket findings by class
- `missing-version` — frontmatter has no `version:` field
- `missing-markdown-heading` — no H1 (`# Title`) line after the frontmatter `---` delimiter
- `missing-frontmatter-fields` — missing any of the 7 canonical keys: `name`, `description`, `version`, `execution-mode`, `argument-hint`, `allowed-tools`, `model` (per DOTFILE_MAP.md sync-overlay policy)
- `nested-duplicate` — skill has a stale nested `skill-name/skill-name/SKILL.md` copy (common from mesh-sync or manual copy errors)
- `not-in-index` — skill not present in `~/.agents/skills/_index/SKILL.md`
- `not-in-routing` — skill not present in `~/.agents/skill-routing.md`
- `skills-full-path-drift` — references to `~/.agents/skills-full/` which does not exist on agent-node (per DOTFILE_MAP.md, `~/.agents/skills/` is canonical). Workstation junction target leaked into skill content via mesh-sync.
- `founder-mode-purge` — unannotated `founder_mode`/`founder-mode`/`C:\FM\` references (per ADR-FM-PURGE-001, `[RETIRED:]`-annotated references are allowed)

`your_project.*` template placeholders are explicitly OUT OF SCOPE — they are intentional generic placeholders in 139+ skills meant to be portable across projects. Substituting to a fixed value would break portability with no clean rollback.

**Routing triggers:** Use skill-name echoes as canonical format. Do NOT manually curate action-verb triggers — concurrent sessions or `skill-create` invocations may regenerate the backfill section and overwrite manual curation. If trigger quality is a concern, update `skill-create/SKILL.md` step 5 to specify the desired format, so all agents generate triggers consistently. Note: `build_routing_index.py` reads from `skill-routing.md` (does not generate triggers) — it is not the source of the format gap. (Origin: 2026-09-02 — action-verb triggers were manually added, then reverted by concurrent session's backfill regeneration.)

### 3. Dry-run mode (default)
Print proposed remediation as a unified diff. No file writes. Output the exact command to apply.

### 4. Apply mode (--apply)
Pre-flight:
- **Branch gate:** For bulk runs (>10 files), create a feature branch first: `fix/devin/skills-drift-remediation-<date>`. Per ADR-BRANCH-FIT-001, bulk remediations benefit from branch isolation and PR review. Single-file fixes may commit to main directly.
- **Cherry-pick tool:** When cherry-picking onto main in `~/.agents`, use `~/bin/devin-cherry-pick` instead of raw `git cherry-pick`. This works around the cherry-pick GPG trap (see AGENTS.md). For multi-commit branches, use `git merge --no-ff` instead of cherry-pick (per AGENTS.md multi-commit branch policy).
- Tarball snapshot of every file that will be modified to `~/.agents/skills/_proposals/skills-fix-runs/<ISO>/snapshot.tar.gz`
- Set `~/.agents/.snapshot-paused` for the duration of the run

Execution:
- Frontmatter version: python3 in-place injection after `description:` (preserving multi-line continuation lines)
- Index: append to dated section "Backfilled YYYY-MM-DD" — never insert into existing categorized sections
- Routing: same append-to-dated-section pattern

Per-file verify-after-edit: `grep -c "<unique phrase>" <file>` must return ≥1.

### 5. Batch paging for large corpora
For 850+ skills, full-corpus runs hit context window limits. Default batch size: 100 skills.
- `--batch 100 --offset 0` → first 100
- `--batch 100 --offset 100` → next 100
- `--batch 100 --offset 200` → next 100, etc.
Operator chains invocations across context-fresh sessions when needed.

### 6. Idempotency
Second `--apply` run on the same scope MUST produce zero changes. Verify by re-running `[skill-test]` after apply — the targeted classes should report zero failures.

### 7. Re-run lint, report delta
Print `before: 50 failures → after: 0 failures` summary.

## Output Format
```
Skills Fix | dry-run | scope=all (or batch N/M)
═══════════════════════════════════════════════
Lint scan: 850+ skills, X failures across N classes
## missing-version (Y skills): [list]
## missing-markdown-heading (Y skills): [list]
## missing-frontmatter-fields (Y skills): [list]
## nested-duplicate (Y skills): [list]
## not-in-index (Z skills): [list]
## not-in-routing (W skills): [list]
## skills-full-path-drift (W files): [list]
## founder-mode-purge (W files): [list or CLEAN]

To apply: [skills-fix] --apply
For large corpora: [skills-fix] --apply --batch 100 --offset 0
```

## Acceptance Criteria
- Dry-run completes in <10s on 850+ skills
- `--apply` achieves zero `[skill-test]` failures for targeted classes in single pass
- Idempotent: 2nd `--apply` on same scope = 0 changes
- No SKILL.md frontmatter rendered invalid YAML (test: yaml.safe_load post-write)
- Snapshot tarball exists at `_proposals/skills-fix-runs/<ISO>/snapshot.tar.gz` before any write

## SoT References
- `~/.agents/DOTFILE_MAP.md` — canonical path is `~/.agents/skills/` (NOT `skills-full/`)
- `~/.agents/docs/adr/ADR-FM-PURGE-001.md` — founder-mode purge scope and allowlist
- `~/.agents/docs/adr/ADR-BRANCH-FIT-001.md` — branch-fit gate (bulk runs need feature branches)
- `~/.agents/AGENT-DIRECTORY-REVIEW-2026-07-29.md` — 7 canonical frontmatter keys, execution modes
- `~/.agents/skills/_index/SKILL.md` — generated index (regen: `python _regen_index.py`)
- `~/.agents/skill-routing.md` — routing table (append-only, dated sections)

## Skill Chains
| After completing... | Consider... |
|--------------------|-----------------------|
| `[skill-test]` (failures found) | `[skills-fix]` to remediate |
| `[skills-fix] --apply` | `[skill-test]` to verify, `[skill-evolve]` to rescore |
| `[skill-create]` (batch) | `[skills-fix]` to backfill any gaps |
