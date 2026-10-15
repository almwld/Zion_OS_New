---
name: stale-head-check
description: Verify the PR head SHA you reviewed is still the PR head at post/merge time — catches reviews posted against stale commits and post-merge state. Cheap check, run it every time.
version: 0.1.0
execution-mode: advisory
argument-hint: "<PR_NUMBER> <repo> [<reviewed-head-sha>]"
category: fleet-ops
status: candidate
---
# Stale-Head Check

A review is bound to a commit. If the PR head moved since you read the diff, your verdict applies to a commit that may no longer be under review — and if the PR already merged, your review is noise (or worse, an uninformed opinion about closed work).

**Origin (2026-09-27 coronal shift):** claude-code posted a P1 review on agents#577 at 08:20Z *after* it merged at 08:10Z — a stale-state read, wasted review slot. Also: agents#579's head moved between my review (`42ba2457`) and merge (`9f4be878`) — the delta was same-class content so the verdict held, but I only knew that by checking.

## When to use

- **Every review post**: fetch `headRefOid` fresh in the same command that posts — never reuse a SHA read minutes earlier
- Before flagging a PR as reviewed — confirm the head you read is the head on the board
- When another seat's review lands near a merge timestamp — check whether they reviewed pre- or post-merge state
- Before re-reviewing — if head unchanged, your prior verdict still binds; if moved, diff the delta only

## Execution

### 1. Fresh head fetch (in the same shell as the post)

```bash
HEAD=$(gh pr view <n> --repo <repo> --json headRefOid -q '.headRefOid[0:8]')
gh pr view <n> --repo <repo> --json state -q '.state'   # OPEN? MERGED? CLOSED?
```

Post with `artifact_state=head:$HEAD` — the bus review already carries this field; keep it accurate.

### 2. Head-moved delta assessment

If `headRefOid` changed since your review:

```bash
gh pr diff <n> --repo <repo> | head -5                    # new head diff shape
git log <old-head>..<new-head> --oneline                  # what commits landed
```

- Delta is same-class (docs lines, comment fixes) → verdict stands, note "head moved, delta same-class, adopt holds"
- Delta is new logic → re-review the delta hunks, amend verdict
- PR state changed to MERGED/CLOSED → do NOT post a review; post a `STATUS` noting the lifecycle state instead

### 3. Stale-review detection for other seats

If a review lands within ~15 min of a merge timestamp on the same PR:

```bash
gh pr view <n> --repo <repo> --json mergedAt -q '.mergedAt'
```

Compare the review's `artifact_state` head vs `mergeCommit` — if it reviewed pre-merge state post-merge, flag as stale-read (informational, not blame).

## Output

- Post reviews only with a fresh `head:<sha8>` artifact_state
- On head-moved: state whether verdict holds + why (delta classified)
- On lifecycle-changed: report state, never review a closed PR as if open

## Failure modes this prevents

- Reviews landing on already-merged state (the #577 event)
- "adopt" verdicts silently applying to commits you never read
- Duplicate re-reviews when head is unchanged (verdict already binds)
- Missing that a "new commits" notification is a force-push, not an update (compare SHA, not timestamps)
