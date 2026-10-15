---
name: coronal-mission-pack
description: The Coronal Agent's pre-loaded skill set — everything an overnight/multi-PR coordination shift needs, in the order the shift needs it. Invoke at session start when taking a coordination seat; do not re-derive the chain per task.
version: 0.1.0
execution-mode: advisory
argument-hint: "[shift-type: pr-drain|issue-triage|website-verify|incident]"
category: fleet-ops
status: candidate
---
# Coronal Mission Pack

Role-based skill pre-load. **Why this exists**: fleet skill discovery is pull-based and fails mid-task (agent attention is on the work, not the inventory). A coordination shift has a known shape — load the set at start instead of discovering piecemeal.

Origin: 2026-09-27 coronal shift — ~90 reviews posted while hand-rolling workflows that already existed as skills (`pr-scope-check`, `claim-verify`, `dns-check`, `smoke`). This pack is the failure's fix.

## The set, in shift order

### 1. Orientation (first 15 min)
- `org-pr-board-scan` — build the complete queue; segment gate-eligible vs wave vs anomaly before touching any single diff
- `bus-read`/`bus-forensics` — what other lanes are live (avoid double-work)
- `stale-head-check` — habit from now on: fresh head SHA in every post

### 2. Per-PR review loop (the bulk of the shift)
- `review-pr` — the verdict workflow itself
- `pr-scope-check` — on any Wave/Batch/refactor title or >5 files
- `cross-pr-conflict-scan` — on any repo with 2+ open PRs touching shared files
- `claim-verify` — when a body claims external facts (versions, licenses, endpoints)
- `diff-report`/`diff-explain` — on mega-diffs for coverage mapping (the #578 lesson: name your review seam)

### 3. Cross-lane verification (the novelty lane)
- `deployed-claim-verify` — any "deployed to X" claim, before accepting it
- `dns-check` — subdomain existence before HTTPS even matters
- `smoke`/`deploy-health` — production routes after merges land

### 4. Evidence & closure
- `bus-post-check` — durable receipt verification for every claim
- `aar` — at shift end (post the SITREP; the finalize script handles it)
- `agents-md-update` — durable learnings worth keeping

## Anti-patterns this prevents

- Scripting `pr-triage.py` from scratch (that's `org-pr-board-scan`)
- Reviewing sibling PRs independently (that's `cross-pr-conflict-scan`)
- Posting "adopt" on a head that moved (that's `stale-head-check`)
- Accepting a "deployed" milestone without a DNS probe (that's `deployed-claim-verify`)
- Declaring a wave uniform without artifact-type scanning (that's `org-pr-board-scan` §3)

## When NOT to use

- Single-PR review requests — invoke `review-pr` directly, don't load the whole pack
- Authoring/implementation lanes — this is a *coordination* pack, not a build pack
- Sessions under 30 min — the pack pays off at shift scale, not task scale
