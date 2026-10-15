---
name: blocker-scanner
description: Scan local fleet surfaces for P0-P3 blockers — git, bus, rules, skills, tests, security, governance, CI, health. Mesh aggregation is reserved until implemented. Posts findings to the coordination bus.
version: 0.1.0
execution-mode: advisory
argument-hint: "[--local] [--priority P0|P1|P2|P3|all] [--since DATE] [--output json|table|bus] [--dry-run]"
category: governance-compliance
status: candidate
---
# Blocker Scanner

Scan local canonical fleet surfaces for blockers categorized by priority (P0-P3). Use this as a **resident agent runtime** — it can run on-demand, on a schedule, or as part of a morning kickoff / evening touchdown ritual. Cross-machine mesh aggregation is reserved until an SSH implementation lands.

## When to Use
- Morning kickoff: identify what blocked overnight before planning the day
- Pre-release gate: verify no P0 blockers before merging or deploying
- Post-incident: scan for secondary damage or lingering issues
- Weekly review: quantify technical debt and governance drift
- Local blocker audit before a separate mesh-sync or health pass

## Priority Taxonomy

| Priority | Severity | Examples | Response SLA |
|----------|----------|----------|-------------|
| **P0** | Critical | Broken main branch, leaked secrets, bus write failure, CI red, dirty production state, unmerged hotfix | Immediate |
| **P1** | High | Stale branches (>14d), unmerged PRs, skill/rules drift, health check failure, unprefixed Phase/Tier/mode in new commits | Same day |
| **P2** | Medium | Outdated dependencies, test gaps, dead code, slow tests, missing docs | This week |
| **P3** | Low | Formatting, typos, unused imports, minor refactors | Next sprint |

## Surfaces Scanned

1. **Git repos** — dirty state, unmerged branches, stale branches, diverged remotes, unmerged PRs
2. **Bus health** — write path, recent messages (last 24h), orphaned agents, duplicate request IDs
3. **Rules & skills** — drift from canonical Git commits, stale files, missing indices
4. **Tests** — failing tests, flaky tests, coverage gaps, timeout regressions
5. **Security** — leaked secrets, unsigned commits, weak permissions
6. **Governance** — unprefixed Phase/Tier/mode in new commits since `--since`, missing ADRs
7. **CI/CD** — red builds, stale checks, broken workflows
8. **Health** — disk space, services down, port conflicts, agent processes missing
9. **Operator queue** — stale QUEUED items, GATED items with approaching triggers
10. **Documentation** — broken links, stale references, missing README updates

## Execution

### Arguments
- `--local` — scan only the current machine (default)
- `--mesh` — reserved; current implementation rejects this flag instead of pretending to scan remote machines
- `--priority P0|P1|P2|P3|all` — filter to a priority level (default: `all`)
- `--since DATE` — only consider changes since DATE (ISO 8601, default: 7 days ago)
- `--output json|table|bus` — output format (default: `table`)
- `--dry-run` — scan but do not post to bus or write state

### Local Mode
1. Resolve all known git repos under `PROJECTS/` and `$PROJECTS_DIR`
2. For each repo: `git status`, `git branch --merged`, `git branch --list --format`, `git log --since`
3. Check bus write path: attempt a test post and rollback
4. Check rules/skills drift: compare `.agents/` against known-good checksums
5. Run security scan: `git-secrets` / `truffleHog` equivalent (scan for `AKIA`, `sk-`, `ghp_`, etc.)
6. Run governance lint: `rg '\bPhase\s+\d+|\bTier\s+\d+\bmode\s*='` on changed files since `--since`
7. Check CI: query Gitea/GitHub for open PRs and failing checks
8. Run health checks: disk free, key services, port map
9. Check operator queue: read `~/.agents/playbooks/operator-owned-work.md` for stale items
10. Aggregate findings, assign priority, deduplicate

### Mesh Mode
Reserved. Until implemented, run local scans on each machine and aggregate the JSON outside this skill. The CLI rejects `--mesh` so bus receipts cannot mislabel a local-only scan as fleet-wide coverage.

### Bus Posting
If `--output bus` or `--output table` (default includes bus post for P0/P1):
- Post a `STATUS` message to `all` with:
  - `blocker_scan` tag
  - `priority_counts` summary
  - `top_blockers` list (max 10)
  - `machine` origin
  - `scan_id` (UUID for correlation)
- For each P0 blocker: post an individual `BLOCKED` message with full details

## Output Format

### Table (default)
```
Blocker Scan | 2026-06-03T13:00:00Z | machine: workstation

| Priority | Category | Finding | Location | Age |
|----------|----------|---------|----------|-----|
| P0 | security | Leaked AWS key in commit abc123 | hummbl_governance/scripts/deploy.sh | 2h |
| P0 | ci | Main branch CI red (test_bus_writer.py) | gitea/workstation | 4h |
| P1 | git | Stale branch feat/kai/phase-refactor (14d) | hummbl-governance | 14d |
| P1 | governance | Unprefixed "Phase 1" in bus message | bus-2026-06-03.tsv | 1h |
| P2 | tests | Coverage gap in bus_writer_core.py | hummbl_governance/tests/unit/ | 7d |
| P3 | docs | Broken link to DOC_LAYER_CONVENTION.md | AGENTS.md | 3d |

Priority counts: P0=2, P1=2, P2=1, P3=1
Action: 2 P0 blockers require immediate attention. Run with --output json for full details.
```

### JSON
```json
{
  "scan_id": "blk-20260603-abc123",
  "timestamp": "2026-06-03T13:00:00Z",
  "machine": "workstation",
  "mode": "local",
  "priority_counts": {"P0": 2, "P1": 2, "P2": 1, "P3": 1},
  "blockers": [
    {
      "priority": "P0",
      "category": "security",
      "finding": "Leaked AWS key in commit abc123",
      "location": "hummbl_governance/scripts/deploy.sh",
      "line": 45,
      "age_hours": 2,
      "remediation": "Rotate key, rewrite history, audit access logs"
    }
  ],
  "recommendations": [
    "Rotate AWS key immediately (P0 security)",
    "Rebase stale branch or delete (P1 git)"
  ]
}
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| P0 blockers found | `[ops]` for incident response, `[redteam]` for security blockers |
| P1 governance blockers | `[govern]` for compliance session |
| P1 git blockers | `[stale-cleanup]` or `[stash-manager]` |
| P2 test gaps | `[coverage]` or `[test-run]` |
| P2 dependency drift | `[dep-update]` |
| P3 formatting | `[deslop]` or bulk-edit |
| Mesh scan complete | `[mesh-sync]` for drift remediation |

## Notes
- The scanner is **read-only** by default. No files are modified.
- Secret scanning uses regex heuristics, not cryptanalysis. Files whose path matches a fragment in `SECURITY_SKIP_PATH_FRAGMENTS` (e.g., `tests/`, `test_fixtures/`, `node_modules/`, `.git/`) are skipped entirely (not scanned, not flagged). For all other paths, false positives are flagged as P1 (investigate) unless the pattern is a known key format.
- Governance lint for unprefixed Phase/Tier/mode only scans files changed since `--since` to avoid flagging historical content.
- The scanner can be scheduled via cron/launchd/Task Scheduler as a resident agent check. Recommended cadence: every 4 hours for P0, daily for P1–P3.
- Scan results are cached in `_state/coordination/blocker_scan_latest.json` for fast retrieval by other agents.
- Use `--dry-run` in CI to fail builds on P0 blockers without side effects.
