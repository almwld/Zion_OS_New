---
name: find-work
description: Discover what needs doing -- scan bus, git, tests, health, tech debt, and open items to surface the highest-value next task.
version: 0.2.0
execution-mode: side_effecting
argument-hint: "[quick | deep | iteratively | category CATEGORY]"
category: fleet-ops
status: candidate
---
## Context Gathering

Before executing this skill, gather the following context:
- **Open PRs**: Run `gh pr list --limit 3 --json number,title --jq '.[] | "#\(.number) \(.title)"' 2>/dev/null || echo "(none)"`
- **Failing CI**: Run `gh run list --status failure --limit 3 --json workflowName,headBranch --jq '.[] | "\(.workflowName) [\(.headBranch)]"' 2>/dev/null || echo "(none)"`
- **Stale branches**: Run `git branch --no-merged main 2>/dev/null | wc -l | tr -d ' '`
- **Bus blockers**: Run `grep "BLOCKED" $PROJECT_ROOT/_state/coordination/messages.tsv 2>/dev/null | tail -1 | cut -f5 | head -c 60`

# Find Work

Surface the highest-value thing to do next. Scans all signal sources and ranks by urgency x impact.

## When to Use
- "What should I work on?"
- Start of a session after `[gm]`
- When current task is done and you need the next one
- When feeling directionless
- Throughout a session with `[iteratively]` to track changes and pivot as needed

## Operations

### quick
Fast scan (~30 seconds) -- check the obvious sources:

```bash
echo "=== P0: BROKEN (fix now) ==="
# Failing CI
gh run list --status failure --limit 5 2>/dev/null | head -3

# Failing tests (last known)
# Check bus for recent ERROR/FAIL messages
grep -E "ERROR|FAIL" _state/coordination/messages.tsv 2>/dev/null | tail -3 | awk -F'\t' '{printf "  [%s] %s: %.60s\n", substr($1,12,5), $2, $5}'

# Health degraded
grep "HEALTH_TRANSITION.*unhealthy\|HEALTH_TRANSITION.*degraded\|CRITICAL" _state/coordination/messages.tsv 2>/dev/null | tail -2 | awk -F'\t' '{printf "  [%s] %.60s\n", substr($1,12,5), $5}'

echo
echo "=== P1: OPEN ITEMS ==="
# Open PRs needing review or merge
gh pr list --limit 5 --json number,title,headRefName --jq '.[] | "  PR #\(.number): \(.title)"' 2>/dev/null

# Stale branches
echo "  Stale branches: $(git branch --no-merged main 2>/dev/null | wc -l | tr -d ' ')"

# Bus BLOCKED messages
grep "BLOCKED" _state/coordination/messages.tsv 2>/dev/null | tail -2 | awk -F'\t' '{printf "  [%s] %s: %.50s\n", substr($1,12,5), $2, $5}'

echo
echo "=== P2: IMPROVEMENT ==="
# Recent deferred-item additions
git log --oneline --since="7 days ago" --all -p 2>/dev/null | grep "^+.*TODO\|^+.*FIXME" | head -5

# Dirty files that have been sitting
git status --short | head -5
```

### deep
Thorough scan (~2 minutes) -- all sources including code analysis:

Run `[quick]` first, then add:

### 0a. Pre-cache GitHub label lists
For each hummbl-io repo that may receive issue creation, cache the label
list so that issue creation uses correct label names without per-repo
lookup failures:

```bash
# Cache labels for all hummbl-io repos with open issues/PRs
for repo in $(gh repo list hummbl-io --limit 100 --json name -q '.[].name'); do
  gh label list --repo "hummbl-io/$repo" --json name -q '.[].name' > "/tmp/labels-${repo}.txt" 2>/dev/null || true
done
```

When creating issues, validate label names against the cache before
calling `gh issue create`. If a label is not in the cache, skip it or
look up the closest match. This eliminates "could not add label" errors
without requiring fleet-wide label standardization.

(Origin: 2026-09-02 AAR — issue creation failed on label mismatches
because label names vary across repos.)

### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=find-work] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

1. **Sprint intent check**: Read `_state/cognition/intent.md` -- are we on track?
2. **Ledger actions**: Query CLP for recent `decision` and `correction` entries that may have follow-up actions
3. **Test debt**: Run `[coverage]` to find uncovered modules
4. **Tech debt scan**: Quick deferred-item count across core dirs
5. **Bus pattern analysis**: What are agents requesting that nobody's doing?
6. **Residual from last session**: Check end-session handoff on bus

### iteratively
Interactive continuous scan -- run `[quick]` at key transition points throughout a session:

**When to run iteratively:**
- After completing a task (before starting the next)
- After a significant code change or deployment
- When context shifts (new PR, new blocker, health change)
- Before asking "what should I do next?"
- Every 30-60 minutes during long sessions

**Workflow:**
1. Run `[quick]` to get current state
2. Compare against previous scan (track changes over time)
3. Ask user: "Is the current P0/P1 still the right focus, or should we pivot?"
4. If user confirms focus, continue; if pivot, re-rank and select new task
5. Log the decision to bus or session notes for traceability

**Tracking state:**
Maintain a simple session state in memory or a temp file:
```bash
# Track last scan timestamp and top recommendation
LAST_SCAN_TIME=$(date -Iseconds)
LAST_RECOMMENDATION="<task description>"
LAST_PRIORITY="<P0/P1/P2>"
```

**Change detection:**
- New failing CI since last scan?
- New BLOCKED messages?
- PR count changed?
- Health status changed?
- New urgent items appeared?

**Output format for iterative mode:**
```
Find Work | iteratively | <timestamp>
══════════════════

## Since Last Scan (<time delta>)
- CI failures: +2 (was 0)
- PRs: -1 (was 5, now 4)
- Health: unchanged

## Current State
[P0/P1/P2 as per quick scan]

## Recommendation
THE NEXT THING: <task>
Estimated effort: <S/M/L>
Why: <justification>

## Pivot?
Should we change focus? (current: <last task>)
```

**Implementation:**
```bash
# State file for tracking between iterations
STATE_FILE="/tmp/find-work-iterative-state.txt"

# Load previous state if exists
if [ -f "$STATE_FILE" ]; then
  LAST_SCAN_TIME=$(cat "$STATE_FILE" | head -1)
  LAST_CI_COUNT=$(cat "$STATE_FILE" | head -2 | tail -1)
  LAST_PR_COUNT=$(cat "$STATE_FILE" | head -3 | tail -1)
  LAST_RECOMMENDATION=$(cat "$STATE_FILE" | tail -1)
else
  LAST_SCAN_TIME="first scan"
  LAST_CI_COUNT="0"
  LAST_PR_COUNT="0"
  LAST_RECOMMENDATION="none"
fi

# Get current state
CURRENT_TIME=$(date -Iseconds)
CURRENT_CI_COUNT=$(gh run list --status failure --limit 100 2>/dev/null | wc -l | tr -d ' ')
CURRENT_PR_COUNT=$(gh pr list --limit 100 2>/dev/null | wc -l | tr -d ' ')

# Calculate deltas
CI_DELTA=$((CURRENT_CI_COUNT - LAST_CI_COUNT))
PR_DELTA=$((CURRENT_PR_COUNT - LAST_PR_COUNT))

# Calculate time delta if not first scan
if [ "$LAST_SCAN_TIME" != "first scan" ]; then
  # Portable time delta calculation (works on both GNU and BSD date)
  if date -d "$LAST_SCAN_TIME" +%s >/dev/null 2>&1; then
    # GNU date (Linux/git-bash)
    TIME_DELTA=$(date -d "$LAST_SCAN_TIME" +%s)
  else
    # BSD date (macOS)
    TIME_DELTA=$(date -j -f "%Y-%m-%dT%H:%M:%S%z" "$LAST_SCAN_TIME" +%s 2>/dev/null || echo "0")
  fi
  CURRENT_TS=$(date +%s)
  if [ "$TIME_DELTA" != "0" ]; then
    ELAPSED_MINUTES=$(( (CURRENT_TS - TIME_DELTA) / 60 ))
    TIME_DISPLAY="${ELAPSED_MINUTES} minutes ago"
  else
    TIME_DISPLAY="unknown time ago"
  fi
else
  TIME_DISPLAY="first scan"
fi

# Run quick scan to get current state
echo "Find Work | iteratively | $CURRENT_TIME"
echo "══════════════════"
echo
echo "## Since Last Scan ($TIME_DISPLAY)"
echo "- CI failures: $CI_DELTA (was $LAST_CI_COUNT, now $CURRENT_CI_COUNT)"
echo "- PRs: $PR_DELTA (was $LAST_PR_COUNT, now $CURRENT_PR_COUNT)"
echo

# Run the quick scan
echo "## Current State"
echo "=== P0: BROKEN (fix now) ==="
gh run list --status failure --limit 5 2>/dev/null | head -3
grep -E "ERROR|FAIL" _state/coordination/messages.tsv 2>/dev/null | tail -3 | awk -F'\t' '{printf "  [%s] %s: %.60s\n", substr($1,12,5), $2, $5}'
grep "HEALTH_TRANSITION.*unhealthy\|HEALTH_TRANSITION.*degraded\|CRITICAL" _state/coordination/messages.tsv 2>/dev/null | tail -2 | awk -F'\t' '{printf "  [%s] %.60s\n", substr($1,12,5), $5}'
echo
echo "=== P1: OPEN ITEMS ==="
gh pr list --limit 5 --json number,title,headRefName --jq '.[] | "  PR #\(.number): \(.title)"' 2>/dev/null
echo "  Stale branches: $(git branch --no-merged main 2>/dev/null | wc -l | tr -d ' ')"
grep "BLOCKED" _state/coordination/messages.tsv 2>/dev/null | tail -2 | awk -F'\t' '{printf "  [%s] %s: %.50s\n", substr($1,12,5), $2, $5}'
echo
echo "=== P2: IMPROVEMENT ==="
git log --oneline --since="7 days ago" --all -p 2>/dev/null | grep "^+.*TODO\|^+.*FIXME" | head -5
git status --short | head -5
echo

# Determine top recommendation based on current state
if [ "$CURRENT_CI_COUNT" -gt 0 ]; then
  RECOMMENDATION="Fix failing CI (highest priority)"
  EFFORT="M"
  JUSTIFICATION="CI failures block all merges"
elif [ "$CURRENT_PR_COUNT" -gt 0 ]; then
  RECOMMENDATION="Review open PRs"
  EFFORT="S"
  JUSTIFICATION="PRs waiting for review"
else
  RECOMMENDATION="Check P2 improvement items"
  EFFORT="L"
  JUSTIFICATION="No urgent blockers, focus on improvement"
fi

echo "## Recommendation"
echo "THE NEXT THING: $RECOMMENDATION"
echo "Estimated effort: $EFFORT"
echo "Why: $JUSTIFICATION"
echo
echo "## Pivot?"
echo "Should we change focus? (current: $LAST_RECOMMENDATION)"

# Save current state for next iteration
echo "$CURRENT_TIME" > "$STATE_FILE"
echo "$CURRENT_CI_COUNT" >> "$STATE_FILE"
echo "$CURRENT_PR_COUNT" >> "$STATE_FILE"
echo "$RECOMMENDATION" >> "$STATE_FILE"
```

### category
Filter by work category:

| Category | What to Check |
|----------|--------------|
| `security` | `[secret-scan]`, `[security-scan]`, `[env-audit]` findings |
| `tests` | Failing tests, low coverage modules, flaky test patterns |
| `ops` | Health probes, service status, disk, $REMOTE_HOST |
| `docs` | Stale CLAUDE.md counts, missing docstrings, stale research |
| `skills` | `[skill-test]` failures, missing routing, missing from index |
| `agents` | Bus BLOCKED from agents, trust reviews due, onboarding |
| `product` | Sprint goals, user stories, feature backlog |
| `debt` | deferred-item count, large files, dead code, bare excepts |

## Prioritization

Rank findings by:

| Priority | Criteria | Examples |
|----------|----------|---------|
| **P0** | Broken now, blocking work | Failing CI, health DOWN, test suite broken |
| **P1** | Open items with deadlines or dependencies | PRs waiting, BLOCKED agents, sprint goals at risk |
| **P2** | Improvement with clear ROI | Test coverage gaps, tech debt, skill compliance |
| **P3** | Nice to have, no urgency | Code polish, doc updates, experimental features |

## Output Format
```
Find Work | <mode>
══════════════════

## P0: Fix Now
- <broken thing with link/path>

## P1: Open Items
- <item with owner and age>

## P2: Improve
- <item with estimated effort>

## Recommendation
THE NEXT THING: <single most valuable task>
Estimated effort: <S/M/L>
Why: <1 sentence justification>
```

## Chain
After finding work:
- P0 item -> `[debug-test]` or `[incident]`
- P1 PR -> `[review-pr]`
- P1 sprint goal -> `[scope-decompose]`
- P2 debt -> `[tech-debt]` or `[full-audit]`
- If nothing urgent -> `[weekly-review]` or `[retrospective]`
- After any task completes -> `[iteratively]` to reassess and find next task

## Base120 Context
- Primary: **DE7** (Pareto 80/20 -- find the vital few)
- Related: **SY1** (Leverage Points), **DE12** (Constraint Isolation)

## Skill Chains

### Mandatory

None — this skill is a read-only scan of bus, git, tests, health, and tech debt; no upstream chain is required.

### Advisory

- P0 item → `[debug-test]` or `[incident]`
- P1 PR → `[review-pr]`
- P1 sprint goal → `[scope-decompose]`
- P2 debt → `[tech-debt]` or `[full-audit]`
- Nothing urgent → `[weekly-review]` or `[retrospective]`
- After any task completes → `[iteratively]` to reassess and find next task

## Authority

- **T1 (TRUSTED)**: Full access — scan all sources, post recommendations
- **T2 (Active/High)**: Full access — scan all sources, post recommendations
- **T3 (Medium)**: Full access — scan all sources, post recommendations
- **T4 (Probationary)**: May run — read-only scan only
- **Operator**: Override any restriction
