---
name: hummbl-research-institute-foundations
description: Session-start context grounding for HUMMBL, LLC. Scans all hummbl-io repos, research coverage, strategy posture, and cognition state into one briefing.
version: 0.1.0
execution-mode: side_effecting
category: governance-compliance
status: candidate
---

## Live Context

!`ls ~/PROJECTS/ 2>/dev/null | grep -i hummbl | wc -l` hummbl-io repos
!`ls ~/PROJECTS/ 2>/dev/null | grep -i hummbl | tr '\n' ' '` repo names
!`ls ~/PROJECTS/axis/docs/research/ 2>/dev/null | wc -l` axis research docs
!`find ~/PROJECTS -maxdepth 2 -name "AGENTS.md" 2>/dev/null | wc -l` repos with AGENTS.md
!`cat ~/PROJECTS/axis/docs/research/source_validation_2026-06-23.md 2>/dev/null | grep "Sources checked" | head -1` latest validation totals
!`ls ~/PROJECTS/hummbl-research/ 2>/dev/null | head -5` hummbl-research contents
!`ls ~/PROJECTS/hummbl-bibliography/ 2>/dev/null | head -5` hummbl-bibliography contents
!`cat ~/PROJECTS/hummbl-doctrine/README.md 2>/dev/null | head -3` doctrine summary
!`find ~/PROJECTS -maxdepth 3 -name "*.md" -path "*/research/*" 2>/dev/null | wc -l` total research markdown files
!`git -C ~/PROJECTS/axis log --oneline -3 2>/dev/null` axis recent commits

# HUMMBL, LLC Foundations

Session-start context grounding for all work across the HUMMBL, LLC ecosystem. Injects live state from all hummbl-io repos, the axis knowledge base, research coverage, strategy posture, and cognition systems into one briefing. Run at the start of every session before doing any HUMMBL-related work.

**This skill is designed to be embedded into every hummbl-io repo.** It grounds the agent in the full institute landscape, not just the current repo.

## When to Use

- At the start of every session that will touch any hummbl-io repo
- When the user says "start", "session", "what's the state", or begins HUMMBL work
- Before any research, strategy, architecture, or cognition work in the institute
- When switching between hummbl-io repos mid-session

## Execution

### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=hummbl-research-institute-foundations] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```

### 1. Repo Inventory (parallel)
Scan all hummbl-io repos and categorize them:
```bash
ls ~/PROJECTS/ | grep -i hummbl | while read repo; do
  echo "$repo: $(git -C ~/PROJECTS/$repo log --oneline -1 2>/dev/null || echo 'no-git')"
done
```

### 2. Research Coverage Matrix
Scan axis and hummbl-research for active research lanes and source counts:
```bash
find ~/PROJECTS/axis/docs/research/ -name "*.md" -type f 2>/dev/null | head -20
find ~/PROJECTS/hummbl-research/ -name "*.md" -type f 2>/dev/null | head -20
```

### 3. Strategy & Doctrine Posture
Read the doctrine and strategy surfaces:
```bash
head -20 ~/PROJECTS/hummbl-doctrine/README.md 2>/dev/null
head -20 ~/PROJECTS/hummbl-theory/README.md 2>/dev/null
```

### 4. Cognition & Memory State
Check the cognitive ledger and memory systems:
```bash
cat ~/PROJECTS/hummbl-cognition/README.md 2>/dev/null | head -10
find ~/PROJECTS -maxdepth 3 -name "ledger.jsonl" -o -name "MEMORY.md" 2>/dev/null | head -10
```

### 5. Post SESSION_START to bus
```
Type: STATUS
To: all
Message: [hummbl-research-institute-foundations] Session grounded. <N> repos, <N> research docs, <N> doctrine surfaces scanned.
```

## Output Format

```
HUMMBL, LLC Foundations | Session Start
â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
REPOS: <N> hummbl-io repos | <N> with AGENTS.md | <N> git-active
RESEARCH: <N> axis docs | <N> hummbl-research docs | <N> total research MDs
VALIDATION: <latest source validation totals>
DOCTRINE: <doctrine summary line>
COGNITION: <ledger/memory state line>
CURRENT REPO: <repo name> | <last commit>
â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
Ready. Focus: <inferred focus from context>
```

## Embedded Deployment

To embed this skill into a hummbl-io repo, symlink or copy:
```bash
ln -s ~/.agents/skills/hummbl-research-institute-foundations ~/PROJECTS/<repo>/.agents/skills/hummbl-research-institute-foundations
```

## Chains

- After this skill â†’ `[start-session]` for operational state recovery
- After this skill â†’ `[nexus]` for governance surface scan
- After this skill â†’ `[apex]` for task-scoped assessment
- After this skill â†’ `[research-pipeline]` if research work is planned
- After this skill â†’ `[gm]` if this is a morning launch

### Mandatory

Before executing any stateful action (posting bus messages, writing state files):
1. **Read-only context gathering**: This skill is primarily advisory â€” it gathers and presents context. Stateful actions are limited to bus receipts and state file updates.
2. **Bus receipt**: Post a `STATUS` bus receipt with the session-start context summary before completing.
3. **No autonomous decisions**: This skill surfaces context; it does not make decisions. Any suggested next actions are candidates awaiting operator confirmation.

## Authority

- **MAY**: Read all hummbl-io repos, research docs, cognition state, doctrine files, validation results
- **MAY**: Post `STATUS` bus receipts with context summary
- **MAY**: Suggest next skills (start-session, nexus, apex, research-pipeline, gm) as candidates
- **MAY NOT**: Modify any repo files, doctrine, or cognition state (read-only context gathering)
- **MAY NOT**: Autonomously invoke other skills without operator confirmation
- **MAY NOT**: Post `DECISION` or `PROPOSAL` bus messages â€” this skill gathers context, it does not propose actions
