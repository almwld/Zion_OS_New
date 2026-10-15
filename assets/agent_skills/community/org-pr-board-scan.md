---
name: org-pr-board-scan
description: Cross-repo inventory of every open PR in the org — grouped by repo/author, sized by additions/deletions/file-count, with anomaly counters (mass deletions, binary artifacts, stale heads). Drives the review queue so no PR is unaccounted for.
version: 0.1.0
execution-mode: advisory
argument-hint: "[--owner hummbl-io] [--newer-than ISO_TS] [--authors-set X,Y]"
category: fleet-ops
status: candidate
---
# Org PR Board Scan

Build the complete open-PR board across the org, then split it into actionable segments: gate-eligible (non-fleet-author) items needing real review, uniform wave items needing characterization, and anomalies needing forensic attention.

**Why this exists (origin: 2026-09-27 coronal shift):** hand-rolled board scripts found the session's two best catches — a `.pyc` binary committed under a "lint" title and a 201-file deletion hidden behind "decompose utility complexity". Neither shows up in content sampling; both show up in file-mode/size counters.

## When to use

- At the start of any multi-PR review shift (establishes the queue before diving into any single diff)
- After every merge sweep (board changes wholesale; stale counts produce stale plans)
- Before claiming "the queue is uniform" — run the anomaly counters first
- When a lane reports "all remaining items are wave items" — verify, don't trust

## Execution

### 1. Inventory — all open PRs with size fields

```bash
gh search prs --owner hummbl-io --state open --limit 200 \
  --json repository,number,title,author,createdAt
```

`gh search` does NOT expose additions/deletions/changedFiles — fetch per-repo for the repos that matter:

```bash
gh pr list --repo hummbl-io/<repo> --state open --limit 40 \
  --json number,title,additions,deletions,changedFiles,author,updatedAt
```

### 2. Segment the board

- **Gate-eligible**: `author` is not a fleet agent seat (dependabot, external contributors). These carry the only reviews that count as gate evidence.
- **Uniform wave**: fleet-authored remediation batches. Characterize via sampling, never rubber-stamp — the wave hides anomalies (see §3).
- **HOLD/blockers**: titles with `[MERGE HOLD]`, disclosed merge-blocks, or CONFLICTING mergeable state.

### 3. Anomaly counters (the value-bearing step)

Flag for individual forensic review — NOT characterization:

- `deletions > 1000` or `changedFiles > 40` — scope-vs-title check (see `pr-scope-check`)
- Any PR whose diff adds binary/cache artifacts (`.pyc`, `.png` outside `docs/`/`assets/`, `.wasm`, `node_modules/`, lockfiles where repo has none)
- `mergeable == "CONFLICTING"` — file-level conflict report (see `cross-pr-conflict-scan`)
- Title keywords ("lint", "decompose", "refactor") paired with large deletion counts

File-mode scan per PR:

```bash
gh pr diff <n> --repo hummbl-io/<repo> | grep -cE "^deleted file mode|^new file mode"
gh pr diff <n> --repo hummbl-io/<repo> --name-only | grep -cE "\.pyc$|\.wasm$|\.bin$|__pycache__"
```

### 4. Report the board with receipts

Post the segmented board to the bus (`post_bus_review.py` or `bus_post`) with: total open, per-repo counts, gate-eligible list, anomaly flags with the counter values as `proof`. Never report a PR count without the query that produced it.

## Output

| Segment | Items | Action |
|---------|-------|--------|
| Gate-eligible | list | individual review |
| Uniform wave | count + sampled repos | characterize + artifact-scan |
| Anomalies | list + counter values | forensic diff review |
| HOLDs/blocks | list | park with reason |

## Failure modes this prevents

- Reviewing every wave item individually (waste) OR declaring the wave uniform unread (risk) — sample + artifact-scan is the middle path that caught the `.pyc` commit
- Stale queue claims — a count taken an hour ago is not the board now
- Treating advisory reviews on devin-seat items as gate evidence (they aren't — see `rules/peer-review-trust-tiers.md`)
