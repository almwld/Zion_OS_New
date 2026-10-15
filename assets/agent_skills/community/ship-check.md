---
name: ship-check
description: Pre-ship checklist -- run before merging or deploying any feature. Chains pre-mortem, test-run, dep-check, security-scan.
version: 0.1.0
execution-mode: advisory
argument-hint: "[BRANCH or \"current\"]"
category: security
status: candidate
---
# Ship Check

Composite pre-ship verification. Runs multiple checks in sequence to validate a feature is ready to merge.

## Working Directory

Run all `git`, `gh`, `pytest`, and `rg` commands from the fleet repo root (`~/.agents` or the active worktree equivalent). Never assume a package-relative CWD. (The prior canonical repo `hummbl-governance` is archived; `~/.agents` is the live fleet repo on agent-node.)

## Worktree Isolation

Before fixing anything discovered during `ship-check`, decide where the remediation belongs:

- If the current branch already backs an unrelated PR, or the worktree is dirty beyond the target files, create a clean worktree from the correct base branch before editing.
- If the current branch and dirty files are part of the same target PR, stay in place and patch there.
- Never stack benchmark follow-up fixes onto an unrelated active branch just because it is already checked out.

## When to Use
- Before merging a feature branch to main
- Before tagging a release
- Before demoing to stakeholders
- When you feel "done" but want confidence

## Execution (run in order)

### 1. Test suite
Run `[test-run]` -- all tests must pass.

### 2. Dependency check
Run `[dep-check] scan` -- no third-party imports in core.

### 3. Security scan
Run `[security-scan]` -- no HIGH severity Bandit findings.

### 4. Secret scan
Run `[secret-scan]` -- no credentials in diff.

### 5. Quality gate (Arbiter)
Run Arbiter diff analysis against the changed files:
```bash
PYTHONPATH=$PROJECTS_DIR/arbiter/src python -m arbiter diff . --base main --json
```
- **PASS**: overall >= 70
- **WARN**: overall 60-70 (note in verdict)
- **FAIL**: overall < 60 or any CRITICAL security finding
- **SKIP**: if Arbiter not installed or no Python files changed

### 6. Pre-mortem
Run `[pre-mortem]` on the changed modules -- what could go wrong?

### 7. Contract review (if schemas changed)
Run `[contract-review]` -- no breaking changes without version bump.

### 8. PR conversations resolved
Check for unresolved comments from other agents (especially chatgpt-codex-connector):
```bash
OWNER="${OWNER:-hummbl-io}"
REPO="${REPO:-hummbl-governance}"
gh api repos/$OWNER/$REPO/pulls/$PR_NUMBER/reviews --jq '.[] | "reviewer=\(.user.login) state=\(.state) author_association=\(.author_association)"'
```
Then resolve each blocking conversation from the review surface (and fallback to
`pr-comment-protocol.md` thread-state query for unresolved `reviewThreads` on the
PR). All blocking conversations must be responded to and resolved before merge.

### 9. Coverage check
Run `[coverage]` -- no uncovered critical paths.

### 10. Bus review gate
Verify the canonical author from commit/lane provenance and the assigned
reviewer's current scope and REVIEW permission. Shared GitHub logins do not
establish agent authorship; roster trust alone does not establish reviewer
scope. Then check the canonical bus from the current repository checkout:
```bash
python scripts/check_bus_review_gate.py --repo <owner/repo> --pr <N> --author <author-identity> --reviewer <assigned-reviewer> --verbose
```
- **PASS (exit 0)**: eligible non-author receipts bind the live full head SHA;
  every latest eligible review accepts with valid proof and no unresolved
  P0/P1 or understated risk. At least one must match the reviewer assignment.
  Selecting an approver never hides other eligible reviewers' blockers.
- **FAIL (exit 1)**: missing, stale, rejecting, malformed, or blocking evidence.
  **ERROR (exit 2)**: bus/head/roster/input failure; stop the merge.
- Search by artifact and full SHA across bus lanes before dispatching another
  reviewer. Send a nonempty actual patch with exact base/head refs and request
  progress during long reviews. Re-check after a fresh non-author REVIEW.
- A head change requires fresh review. Offline `--current-head` needs a
  freshly verified full 40-character SHA. `--receipt <path>` additionally
  checks structured closeout/CI evidence against this PR, head, and reviewer.
- Same-session adversarial review is useful pre-review support. Even with
  `review_lane_authorized=true`, the author never satisfies this automated
  gate. An explicit operator waiver is recorded separately, not as a PASS.
- Canonical bus provenance and reviewer authority remain caller checks.
  Repeat `--reviewer` for multiple assigned reviewers. Keep unrelated provider
  skip notes in findings or `advisory_note`; the reviewer's own `proof` and
  `review_method` must attest completed work.

This gate is a complement to step 8 (PR conversations), not a replacement.
Both must pass before merge. See `pr-review-protocol.md` § "Pre-Merge Gate".

## Output Format
```
Ship Check | <branch>
══════════════════════

## Results
| Check | Status | Notes |
|-------|--------|-------|
| Tests | PASS/FAIL | N/N passed |
| Dependencies | PASS/FAIL | stdlib-only verified |
| Security | PASS/FAIL | N findings |
| Secrets | PASS/FAIL | clean/N leaked |
| Quality (Arbiter) | PASS/WARN/SKIP | score/100 (grade) |
| Pre-mortem | N scenarios | P0: N, P1: N |
| Contracts | PASS/N/A | no breaking changes |
| Coverage | X% | N uncovered modules |
| Bus review gate | PASS/FAIL | N independent reviews, N blocking findings |

## Verdict: [SHIP | FIX FIRST | NEEDS REVIEW]
<rationale>
```

## Skip Conditions
- Docs-only change: skip security-scan, dep-check, coverage
- Test-only change: skip pre-mortem, contract-review
- Config-only change: skip dep-check, coverage
