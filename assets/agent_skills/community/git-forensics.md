---
name: git-forensics
description: >-
  Forensically analyze git repositories across the fleet — reconstruct commit
  timelines, trace agent attribution, detect anomalies (unsigned commits, bad
  signatures, force-pushes, identity mismatches, convention violations), map
  branch topology (stale, diverged, stranded), track file churn, correlate
  cross-repo activity, and produce a structured forensic report. Supports
  per-repo, per-author, time-window, and pattern filtering. Use this skill
  when the user asks to audit, analyze, investigate, or forensically examine
  git history — "what landed in the repos?", "git forensics", "audit fleet
  repos", "find unsigned commits", "trace this commit across repos", "which
  agent committed what?", "branch cleanup analysis", or "repo health check".
version: 0.1.0
execution-mode: advisory
category: dev-tools
status: candidate
providers:
  required: [python]
  optional: [eval-spec(md-scored)]
---

# Git Forensics

Forensically analyze git repositories across the fleet. Reconstruct what
landed, trace agent attribution, detect anomalies, and produce a structured
forensic report.

## When to use

- "Audit/analyze/investigate git repos" or "git forensics"
- "What landed in the repos recently?"
- "Find unsigned commits" or "GPG signing audit"
- "Which agent committed what?"
- "Branch cleanup analysis" or "find stale branches"
- "Repo health check" or "fleet repo audit"
- "Trace this commit/file/pattern across repos"
- Post-incident git audit (what actually changed during an event?)
- Agent attribution audit (did the agent that claimed to commit actually commit?)
- Cross-referencing with session-forensics and bus-forensics

## How it works

This skill uses a hybrid approach:

1. **`scripts/git_forensics.py`** — a stdlib-only Python script that discovers
   all git repos in the projects directory, extracts commit history, branch
   topology, GPG signing status, author attribution, file churn, and runs 10
   automated analysis modules: overview, repo health, commit analysis, branch
   topology, timeline, anomaly detection, agent attribution, file churn,
   cross-repo correlation, and GPG provenance.

2. **This SKILL.md** — guides you through interpreting the extracted data and
   producing a human-readable forensic report.

## Step 1: Run the extraction script

```bash
# Default: scan all repos in ~/Projects, analyze last 50 commits each
python <skill-dir>/scripts/git_forensics.py

# Single repo
python <skill-dir>/scripts/git_forensics.py --repo delta-agents

# Time window: last 24 hours
python <skill-dir>/scripts/git_forensics.py --window 24h

# More commits per repo
python <skill-dir>/scripts/git_forensics.py --count 100

# Filter by author
python <skill-dir>/scripts/git_forensics.py --author "Reuben Bowlby"

# Only unsigned commits
python <skill-dir>/scripts/git_forensics.py --unsigned

# Trace a pattern in commit messages
python <skill-dir>/scripts/git_forensics.py --trace "bus-forensics"

# List repos only (quick inventory)
python <skill-dir>/scripts/git_forensics.py --list-repos

# Full JSON output for detailed analysis
python <skill-dir>/scripts/git_forensics.py --json

# Save full JSON to a file
python <skill-dir>/scripts/git_forensics.py --out forensic-data.json --full

# Custom projects directory
python <skill-dir>/scripts/git_forensics.py --projects-dir /path/to/repos

# Combine filters
python <skill-dir>/scripts/git_forensics.py --window 7d --author devin --json
```

The script auto-discovers repos by scanning for `.git` directories in the
projects directory (default: `~/Projects/` or `$PROJECTS_DIR`).

## Step 2: Read the script output

The script produces a structured data package with these analysis modules:

- **`overview`** — repo count, commits analyzed, unique authors, dirty/unpushed counts
- **`repo_health`** — per-repo status (healthy, dirty, unpushed, no_upstream, branch_bloat)
- **`commit_analysis`** — per-author counts, GPG status distribution, convention compliance, co-authors
- **`branch_topology`** — stale branches (>14d), local/remote counts, branch age
- **`timeline`** — recent commits across all repos, chronological
- **`anomalies`** — unsigned commits, bad signatures, identity mismatches, convention violations, force-pushes, dirty repos, unpushed repos, branch bloat, email anomalies
- **`agent_attribution`** — which agent (devin/codex/claude/copilot/gemini/dependabot/human) authored what, signed vs unsigned
- **`file_churn`** — most-modified files per repo (hotspots)
- **`cross_repo_correlation`** — same commit message in multiple repos, shared authors
- **`gpg_provenance`** — per-repo GPG status, unsigned commit clusters (>=3 consecutive)

For large analyses, use `--full` to avoid content truncation.

## Step 3: Produce the forensic report

After reading the extracted data, produce a structured report. The report
should help the reader understand what landed in the repos, whether git
hygiene was maintained, where it broke down, and whether anything looks
suspicious.

### Report template

```markdown
# Git Forensics Report: <time range or filter description>

## Overview
- **Projects directory**: <path>
- **Repos scanned**: <count>
- **Commits analyzed**: <count>
- **Unique authors**: <list>
- **Dirty repos**: <count>
- **Unpushed repos**: <count>

## Repo Health
<Per-repo status: healthy, dirty, unpushed, no_upstream, branch_bloat.
Flag any repos with issues and explain what needs attention.>

## Commit Analysis
<Author distribution — who commits most? GPG signing status — what percentage
are signed? Convention compliance — are commits following Conventional Commits?
Co-author attribution — which agents are credited?>

## Branch Topology
<Stale branches (>14d no commits), branch count per repo, repos with branch
bloat. Recommend cleanup for stale branches that are merged to main.>

## Timeline
<Chronological summary of recent commits across all repos. Group by phase or
theme if the window has natural phases.>

## Anomalies
<Each anomaly found, with context:
- Unsigned commits (non-bot, should be signed per fleet policy)
- Bad signatures (GPG key issues)
- Identity mismatches (author != committer — possible impersonation)
- Convention violations (non-Conventional Commits format)
- Force pushes (history rewrites)
- Dirty repos (uncommitted changes)
- Unpushed repos (work not yet shared)
- Branch bloat (>50 branches)
- Email anomalies (unexpected email domains)>

## Agent Attribution
<Which agents authored what: devin, codex, claude, copilot, gemini,
dependabot, hummbl-agent, hummbl-io, human. Signed vs unsigned per agent.
Which repos each agent touched.>

## File Churn
<Most-modified files per repo. Hotspots that change frequently may indicate
instability or active development areas.>

## Cross-Repo Correlation
<Same commit message in multiple repos — may indicate coordinated changes or
copy-paste. Authors active in multiple repos — fleet-wide contributors.>

## GPG Provenance
<Per-repo signing status. Unsigned commit clusters (>=3 consecutive unsigned
commits from non-bot authors) — may indicate a signing configuration issue
or a period when GPG was unavailable.>

## Behavioral Observations
<Patterns the human should know about:
- Did agents follow git conventions (Conventional Commits, branch naming)?
- Were commits properly signed per fleet policy?
- Did any agent commit to repos it shouldn't have?
- Were there force-pushes that rewrote shared history?
- Are there repos with persistent dirty state (work never committed)?
- Were there identity mismatches suggesting impersonation or misconfiguration?
- Are stale branches accumulating (cleanup needed)?>

## Conclusion
<One-paragraph summary: what landed in the repos during this window, whether
git hygiene was maintained, and any recommendations for the operator (clean
up stale branches, push unpushed commits, fix GPG signing, investigate
identity mismatches, etc.)>
```

## Interpretation guidance

### Reading between the lines

The raw data tells you *what* happened. Your job is to also assess *why* and
*whether it was right*. Look for:

- **Claim vs. commit gaps**: An agent says on the bus "I've committed the fix"
  but the git log shows no commit — the agent hallucinated or the commit was
  lost. Cross-reference with `bus-forensics` and `session-forensics`.
- **Unsigned commit clusters**: 3+ consecutive unsigned commits from a non-bot
  author — GPG agent may have crashed or signing was disabled. Check if this
  correlates with a session crash or daemon failure.
- **Identity mismatches**: Author name doesn't match committer name — may
  indicate squash-merge (normal), cherry-pick (normal), or impersonation
  (suspicious). Check if the committer is GitHub (normal for web merges) or
  an unknown identity.
- **Convention drift**: Commits not following Conventional Commits format —
  may indicate a non-fleet contributor or an agent not following conventions.
- **Branch bloat**: >50 branches in a repo — stale branches accumulating,
  cleanup needed. Check if they're merged to main and safe to delete.
- **Persistent dirty state**: A repo that's been dirty across multiple
  analysis runs — work is never being committed, possibly because the agent
  is stuck or the changes are experimental.

### Security considerations

When reviewing git history, pay attention to:
- Commits authored by unknown identities (not in the fleet author list)
- Email domains that don't match known fleet domains (hummbl.io, hummbl.dev)
- Force-pushes to shared branches (main, develop) — history rewrites
- Files with secrets committed (check for .env, key files, tokens in diffs)
- GPG key changes (a different key ID appearing may indicate key rotation
  or compromise)

Report security concerns prominently in the report, but do not reproduce
secret values — reference them by file path and commit hash.

### Cross-surface forensics

Git forensics is the third leg of the forensic triangle:

1. **bus-forensics** — what agents *said* (coordination bus)
2. **session-forensics** — what agents *did* (transcript, tool calls)
3. **git-forensics** — what *landed* (commits, branches, files)

Cross-referencing all three enables detecting:
- An agent that posted on the bus but never committed (all talk, no action)
- An agent that committed but didn't post on the bus (silent changes)
- A session that edited files but the edits weren't committed (lost work)
- A commit that no session claims credit for (mysterious authorship)

### Agent identity enforcement

Some repos have per-repo git identity enforcement (e.g., hummbl-governance requires
`hummbl-io <noreply@hummbl.dev>`). The git-forensics script detects identity
mismatches where the author name doesn't match the committer name — this can
catch identity enforcement violations.

## Limitations

- **Git subprocess dependency**: The script calls `git` via subprocess. Git
  must be installed and on PATH.
- **Commit count limit**: Default is 50 commits per repo. For deep history
  analysis, use `--count 500` or higher (slower).
- **Branch topology**: Remote branches are included but may include stale
  remote-tracking refs that no longer exist on the remote.
- **Force-push detection**: Uses reflog, which is local and may not capture
  force-pushes from other machines.
- **File churn**: Only counts file modifications, not insertions/deletions.
  For line-level churn, use `git log --stat` separately.
- **Cross-repo correlation**: Same-message matching is exact (after trim).
  Similar but not identical messages won't match.
- **GPG status**: `git log --format=%G?` requires git to have GPG configured.
  If GPG is not installed, all commits will show as "no signature".

## Skill Chains

### Mandatory

- None — git-forensics is a read-only analysis tool.

### Advisory

- **After git-forensics**: `[session-forensics]` (to drill into a session
  that made specific commits), `[bus-forensics]` (to see what was
  communicated about the work), `[branch-strategy]` (for cleanup planning)
- **Before git-forensics**: `[start-session]` (for session-scoped context)

## Authority

- **T1 (TRUSTED)**: Run without restriction
- **T2 (Active/High)**: Run without restriction (read-only forensic tool)
- **T3 (Medium)**: Run without restriction (read-only forensic tool)
- **T4 (Probationary)**: Run (read-only — no destructive actions)
- **Operator**: Override any restriction

## Constraints

- READ-ONLY — never writes to any repo, never modifies any file
- No side effects beyond git subprocess calls (read operations only)
- All analysis is local to the script process
