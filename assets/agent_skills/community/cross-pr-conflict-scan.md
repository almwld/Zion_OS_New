---
name: cross-pr-conflict-scan
description: Detect semantic and merge conflicts BETWEEN open sibling PRs — same-file collisions, merge-order semantic hazards, and superset/stacked relationships. Pairwise merge-tree + overlapping-file analysis across a repo's open PR list.
version: 0.1.0
execution-mode: advisory
argument-hint: "<repo> [--prs N,M,...] [--pairs] [--vs-main]"
category: fleet-ops
status: candidate
---
# Cross-PR Conflict Scan

PRs are reviewed independently but merge into shared state. This scan finds three hazard classes that per-PR review cannot see:

1. **File-level merge conflicts** — two open PRs editing the same lines (git-level collision → second merger conflicts)
2. **Merge-order semantic hazards** — PR-A's semantics silently revert PR-B's change depending on merge order (no git conflict, worse than a conflict)
3. **Superset/stacked relationships** — PR-B contains all of PR-A's hunks (review once, not twice)

**Origin (2026-09-27 coronal shift):** found `general-claim-validator#26/#27` — #26's refactor carried a broad hidden-path deny that could revert #27's narrowing depending on merge order (verified post-merge: resolved OK, luck not mechanism). Found `workstation-bin#58` CONFLICTING on `aar-finalize.py`+`bus-global.py` sibling collisions. Found `#287 ⊃ #286` (strict superset — one review covered both).

## When to use

- A repo has 2+ open PRs and you see overlapping file lists
- Before flagging a PR "adopt" when a sibling touches the same function
- When `mergeable=CONFLICTING` appears on the board — identify which files and which merged PR caused it
- When titles look like twins ("fix X" appearing in two repos/PRs — byte-compare the diffs)

## Execution

### 1. File-overlap map

```bash
for pr in $(gh pr list --repo <repo> --state open --json number -q '.[].number'); do
  echo "=== #$pr"; gh pr diff $pr --repo <repo> --name-only
done
```

Group PRs by shared files. Any pair sharing a file gets a closer look — shared FUNCTIONS (not just files) are where semantic hazards live.

### 2. Merge-tree for git conflicts (vs main)

```bash
git fetch origin pull/<n>/head:pr<n> main
BASE=$(git merge-base main pr<n>)
git merge-tree $BASE main pr<n> | grep -B5 "changed in both"
```

Each "changed in both" block names a file where main moved under the PR — the conflict set.

### 3. Semantic merge-order check (the hard part)

For each overlapping file pair, compare what each PR does to the SAME guard/function/constant:

- Same file, different hunks → likely fine
- Same file, same function, same direction → duplicate work (close one)
- Same function, opposite directions → merge-order hazard — flag explicitly with "if #A merges after #B, X happens"
- One PR's hunk list ⊂ other's → superset; review the superset only, note the subset is absorbed

### 4. Byte-identical twin check

For suspected cross-PR/cross-repo twins:

```bash
gh pr diff <a> --repo <r1> > /tmp/a.patch; gh pr diff <b> --repo <r2> > /tmp/b.patch
diff /tmp/a.patch /tmp/b.patch && echo "BYTE-IDENTICAL"
```

## Output

Post as a review finding on BOTH involved PRs (each needs the context):

- `MERGE-ORDER: #A vs #B — if A lands after B, <semantic consequence>`
- `CONFLICTING: files <list> changed-in-both vs main; rebase needed`
- `SUPERSET: #B contains #A verbatim — review B, absorb A`
- `TWIN: byte-identical to <repo>#<n> — one canonical, close the other`

## Failure modes this prevents

- Approving two sibling PRs whose combination is wrong (the #26/#27 class)
- A PR rotting into CONFLICTING state with no one knowing which sibling caused it
- Double-reviewing stacked PRs (the #287⊃#286 waste)
- Twin PRs in sibling repos diverging silently
