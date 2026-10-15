---
name: weekly-review
description: Weekly planning and review -- what shipped, what's next, what to deprioritize.
version: 0.1.0
execution-mode: side_effecting
argument-hint: "[review | plan | both]"
category: dev-tools
status: candidate
---
# Weekly Review

### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=weekly-review] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

Structured weekly review and planning cycle. Run Sunday evening or Monday morning.

## Review Phase

### 1. What shipped this week?
```bash
git log --oneline --since="7 days ago" --all | head -30
echo "---"
echo "Commits: $(git log --oneline --since='7 days ago' --all | wc -l)"
echo "PRs merged: $(gh pr list --state merged --search "merged:>=$(date -v-7d +%Y-%m-%d)" --limit 20 --json number --jq 'length' 2>/dev/null || echo '?')"
```

### 2. Bus milestones
```bash
grep "MILESTONE\|RECEIPT" $PROJECT_ROOT/_state/coordination/messages.tsv | tail -20
```

### 3. What didn't ship? Why?
- Check for BLOCKED messages in bus
- Check for stale branches: `git branch --no-merged main | head -10`
- Check for open PRs: `gh pr list --limit 10`

### 4. Health trend
- Compare this week's health status to last week
- Any adapters that degraded?
- Any recurring incidents?

## Planning Phase

### 5. What's the ONE thing for next week?
Not a list of 20 tasks. The single most important outcome.

### 6. What to say no to?
- Tasks that seemed important but aren't on the critical path
- Requests from agents that don't align with sprint goals
- Technical debt that can wait another week

### 7. Update intent.md
```bash
# Update the current intent for all agents
cat > _state/cognition/intent.md << 'EOF'
# Current Intent

## Sprint
<sprint name>

## Goals
1. <THE one thing>
2. <supporting goal>
3. <supporting goal>

## Ground Rules
<carried forward from previous>
EOF
```

## Output Format
```
Weekly Review | Week of <date>
══════════════════════════════

## Shipped
- <N commits, M PRs, key milestones>

## Didn't Ship
- <what and why>

## Health
- <trend: improving/stable/degrading>

## Next Week: THE One Thing
<single most important outcome>

## Saying No To
- <deprioritized items>

## Updated Intent
<link to intent.md>
```

## Skill Chains

### Mandatory

None — this skill is a read-only aggregation and planning cycle; no upstream chain is required.

### Advisory

- After review → `[find-work]` to select next task from the plan
- If health degraded → `[incident-response-plan]` to update IRP
- If blockers persist → `[retrospective]` to identify root causes

## Authority

- **T1 (TRUSTED)**: Full access — review, plan, update intent.md
- **T2 (Active/High)**: Full access — review, plan, update intent.md
- **T3 (Medium)**: Full access — review, plan, update intent.md
- **T4 (Probationary)**: May run — read-only aggregation only (no intent.md updates)
- **Operator**: Override any restriction
