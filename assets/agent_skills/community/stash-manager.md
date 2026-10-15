---
name: stash-manager
description: Autonomous stash lifecycle management for agent fleets (detect, classify, extract, park, drop)
version: 0.1.0
execution-mode: side_effecting
category: dev-tools
status: candidate
providers:
  required: [python]
---
# Stash Manager

Autonomous stash lifecycle management for agent fleets. Replaces manual
stash inspection with a decision pipeline: **detect → classify → decide →
verify → execute → receipt**.

## Why this exists

The `stash-audit` skill detects stash risk but is read-only. In a
multi-agent fleet where Codex, Gemini, Claude, and Devin all create
stashes during interrupted work, stashes accumulate faster than humans
can triage. This skill gives **trusted agents** the authority to:

- Extract valuable WIP into focused PRs
- Park unshipped unique work as permanent branches
- Safely drop redundant stashes after full verification
- Alert the operator when human judgment is required

## Trust model

| Agent tier | Allowed actions |
|---|---|
| **Tier 0 — Operator** | Override any decision, force drop/apply |
| **Tier 1 — Apex** | All actions including drop after full verification |
| **Tier 2 — Codex / Claude / Devin** | Extract to PR, park-branch, alert. **No auto-drop.** |
| **Tier 3 — Background / Scheduled** | Detect + classify + alert only. No execution. |

Current session agent tier is determined by `AGENT_TIER` env var or
bus identity lookup. Default = Tier 2.

## Decision pipeline

### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=stash-manager] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

### Phase 1 — Detect (invoke stash-audit)

```bash
python ~/.agents/skills/stash-audit/audit.py --json --repo <repo>
```

Produces classified stash list with:
- `ref` (stash@{N})
- `branch` (stash creation branch)
- `current_branch` (HEAD now)
- `classification`: TIDY-MATCH | CONTAMINATION-RISK | MYSTERY
- `age_days`
- `stale` (age >= 14)
- `files` (list from `git stash show -u --name-only`)

### Phase 2 — Classify content value

For each stash, run the **Content Value Heuristic** (CVH):

```python
class StashValue:
    REDUNDANT = 0      # All files on main, content already shipped
    CLEANUP   = 1      # Minor fixes (import sys, typo, skipif)
    FEATURE   = 2      # New functionality worth extracting
    CRITICAL  = 3      # Security fix, data recovery, or core fix
    UNKNOWN   = -1     # Cannot determine without operator review
```

**CVH scoring rules:**

1. **REDUNDANT**: Every file in stash exists on `main` AND
   `git stash show -p | git apply --check --reverse` is clean.
   → Safe to drop (with full verification).

2. **CLEANUP**: Files exist on main but stash diverges slightly.
   → Extract to `chore/agent/stash-cleanup-<desc>` if >1 file,
     or apply-and-commit directly if single file and CI green.

3. **FEATURE/CRITICAL**: Any file NOT on main, or any file whose
   `git log --all -- <path>` returns empty.
   → **Park-branch** immediately. Open PR only after operator
     review or CI evidence.

4. **UNKNOWN**: MYSTERY classification, binary files, or >20 files.
   → Alert operator with full stash dump.

### Phase 3 — Decide

| Classification + Value | Age < 14 | Age >= 14 | Action |
|---|---|---|---|
| TIDY-MATCH + REDUNDANT | — | Drop after verification | Drop |
| TIDY-MATCH + CLEANUP | Extract to PR | Extract to PR or park | PR |
| TIDY-MATCH + FEATURE/CRITICAL | Extract to PR | Park + alert | Park |
| CONTAMINATION + any | Park + alert | Park + alert | Park |
| MYSTERY + any | Alert | Alert | Alert |

**Hard rules:**
- No agent below Tier 1 may drop a stash containing any file NOT on main.
- No agent may `git stash apply` on a branch mismatch (CONTAMINATION-RISK).
- PARK always before DROP for any stash with `value >= FEATURE`.
- ALERT always for MYSTERY.

### Phase 4 — Execute

#### Action: EXTRACT-TO-PR

```bash
# 1. Create branch from stash creation branch or main
STASH_BRANCH=$(git stash list --pretty='%gs' | sed -n "$((N+1))p" | sed -E 's/(WIP )?[Oo]n ([^:]+):.*/\2/')
git checkout -b feat/<agent>/stash-extract-<slug> "$STASH_BRANCH" 2>/dev/null || \
  git checkout -b feat/<agent>/stash-extract-<slug> main

# 2. Apply stash (with conflict detection)
git stash apply stash@{N} || { git checkout main; git branch -D feat/...; ALERT }

# 3. Commit with stash provenance
# Use explicit file list, NOT git add -A (may include build artifacts)
git add -- $(git diff --name-only --staged stash@{N} 2>/dev/null || git diff --name-only)
git commit -m "$(cat <<'EOF'
<original-stash-desc>

Extracted from stash@{N} on <stash-branch> by <agent>.
Stash age: <age_days>d. Classification: <class>.

Generated with [Devin](https://cli.devin.ai/docs)
Co-Authored-By: <agent> <...>
EOF
)"

# 4. Push and open PR
git push -u origin feat/<agent>/stash-extract-<slug>
# → invoke pr-summary skill or gh pr create
```

#### Action: PARK-BRANCH

Uses the park-branch pattern from `stash-audit`:

```bash
git branch park/<agent>-<slug>-$(date +%Y%m%d) stash@{N}
# Stash remains until operator confirms branch integrity, then:
git stash drop stash@{N}
```

Park branches are prefixed with `park/<agent>-` so the operator knows
which agent created them and can query by agent name.

#### Action: DROP

**Full verification protocol (mandatory, no exceptions):**

```bash
# Step 1: list ALL files
files=$(git stash show -u --name-only stash@{N})

# Step 2: every file must exist on main
for f in $files; do
  git cat-file -e "main:$f" || { echo "FAIL: $f not on main"; exit 1; }
done

# Step 3: content must be redundant
patch=$(git stash show -p stash@{N})
echo "$patch" | git apply --check --reverse 2>/dev/null || \
  { echo "FAIL: content diverges from main"; exit 1; }

# Step 4: PR state check — stash branch must have merged PR
stash_branch=$(git stash list --pretty='%gs' | sed -n "$((N+1))p" | sed -E 's/.*[Oo]n ([^:]+):.*/\1/')
pr_state=$(gh pr list --head "$stash_branch" --state merged --json number -q '.[0].number')
[ -n "$pr_state" ] || { echo "WARN: no merged PR for $stash_branch"; }

# Step 5: execute
git stash drop stash@{N}
```

If any step fails, convert to **PARK-BRANCH** instead.

### Phase 5 — Receipt

Every action posts to the coordination bus:

```
from=<agent>  to=all  type=STASH-RECEIPT  ts=<ISO8601>
body: {
  "repo": "hummbl-io/hummbl-governance",
  "stash_ref": "stash@{4}",
  "action": "PARK-BRANCH",
  "target_branch": "park/devin-exception-docs-20260601",
  "classification": "CONTAMINATION-RISK",
  "value": "CRITICAL",
  "age_days": 0,
  "files_count": 4,
  "files_on_main": 4,
  "verification_passed": true,
  "pr_url": null,
  "operator_review_required": true
}
```

## Invocation

### Manual (operator-directed)
```bash
# Scan current repo, propose actions only (dry-run)
python ~/.agents/skills/stash-manager/manager.py --dry-run

# Execute proposed actions for this agent's tier
python ~/.agents/skills/stash-manager/manager.py --execute

# Force a specific action on a specific stash (operator only)
python ~/.agents/skills/stash-manager/manager.py --stash stash@{2} --action park --reason "Windows fix, needs CI"
```

### Autonomous (agent self-directed)
An agent may invoke this skill when:
- Session-start hook detects stashes
- Long-running work is interrupted (save WIP → stash → manager extracts later)
- Weekly hygiene loop triggers
- Bus message `STASH-TRIAGE-REQUEST` received

Autonomous invocation requires:
1. Current repo has clean working tree
2. Agent tier >= 2
3. No uncommitted changes in target repo
4. `--execute` flag is explicitly passed (no accidental execution)

## Bus protocol

### Inbound messages (triggers)

| Message type | Payload | Response |
|---|---|---|
| `STASH-TRIAGE-REQUEST` | `{repo, urgency: now|soon|hygiene}` | Run full pipeline, post receipt |
| `STASH-OVERRIDE` | `{stash_ref, action, reason}` | Force action (operator only) |
| `STASH-PARK-CONFIRMED` | `{branch}` | Drop the parked stash |

### Outbound messages (receipts)

| Message type | When |
|---|---|
| `STASH-RECEIPT` | After any action |
| `STASH-ALERT` | When operator review required |
| `STASH-DROP-DENIED` | When tier or verification blocks drop |

## Safety invariants

1. **Never drop without full file-level verification.**
2. **Never apply on branch mismatch.**
3. **Park before drop for any unique work.**
4. **Every action produces a bus receipt.**
5. **Dry-run default.** `--execute` must be explicit.
6. **No recursive stashing.** If applying a stash creates dirty state, abort and alert.
7. **Timestamped park branches.** `park/<agent>-<slug>-YYYYMMDD` so operator can sort by age.
8. **Agent attribution.** Every commit, branch, and receipt names the acting agent.

## Dependencies

- `git` >= 2.40
- `gh` CLI (for PR creation)
- `stash-audit` skill (read-only classification)
- `branch-strategy` skill (for stale branch cleanup of old park branches)
- `bus` skill (for receipt posting)
- `pr-summary` skill (for PR creation)

## Skill Chains

### Mandatory (MUST pass before any execution phase)

- **`[stash-audit]`** MUST run first — no stash management without classification
  This skill already invokes stash-audit in Phase 1; this documents it as mandatory.

### Advisory

- **After extract**: `[pr-summary]` (if extracted to PR), `[commit]` (if extracted to branch)
- **After park**: `[branch-strategy]` (for stale branch cleanup later)
- **After drop**: `[bus]` (receipt posting mandatory)

## Authority

Already documented above in the **Trust model** section. Summary:

- **Tier 0 (Operator)**: Override any decision, force drop/apply
- **Tier 1 (Apex)**: All actions including drop after full verification
- **Tier 2 (Codex/Claude/Devin)**: Extract to PR, park-branch, alert. No auto-drop.
- **Tier 3 (Background/Scheduled)**: Detect + classify + alert only. No execution.

## Changelog

- v0.1.0 (2026-06-01): Initial design. Four-tier trust model, CVH heuristic,
  park-branch pattern, full verification protocol, bus receipt schema.
