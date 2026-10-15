---
name: repo-init-secured
description: "Initialize repos with redteam-before-ship: propose scaffold, threat-model the environment, and bake mitigations into code, research, swarm, or sandbox layouts."
version: 0.1.0
execution-mode: side_effecting
argument-hint: "<repo-name> [--type research|code|scratch|hybrid] [--public|--private]"
category: security
status: candidate
---
## Context Gathering

Before executing this skill, gather the following context:
- **Existing PROJECTS**: Run `ls $HOME/PROJECTS/ 2>/dev/null | head -8 || ls ~/PROJECTS/ 2>/dev/null | head -8`
- **Last scaffold**: Run `for d in $HOME/PROJECTS/*/.git ~/PROJECTS/*/.git; do [ -d "$d" ] && git -C "$(dirname "$d")" log --reverse --format='%cd %h %s' -1 -- 2>/dev/null; done | sort -r | head -1`

# [repo-init-secured]

Initialize a new repo with the redteam-before-ship pattern. Standard scaffolding writes files first and finds attack surfaces later. This skill flips the order: **propose → redteam → triage → build with mitigations baked in**. Cheaper than retrofitting hardening after the swarm has already started writing into an unsafe layout.

## When to Use
- Multi-agent work (swarm lanes, dispatched subagents) will land in this repo
- Mixes confidential strategy notes with shareable research
- Untrusted inputs (PDFs, web fetches, BibTeX, community mirrors) will be ingested by agents
- Repo will eventually be pushed to a public mirror, but starts private
- Worth 10 extra minutes for a multi-week working environment

Skip this skill -- use `[repo-scaffold]` directly -- when:
- Self-contained code package with no agent surface
- No privacy-sensitive content and no untrusted-input ingestion
- You're moving fast on a known-safe pattern

## Execution

### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=repo-init-secured] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

### 1. Scope-question pass (no file writes yet)
Establish before proposing:
- **Location**: `PROJECTS/<name>/` per Workstation CLAUDE.md "no top-level repos at $HOME/"
- **Type**: `code` | `research` | `scratch` | `hybrid` (governs scaffold)
- **Privacy**: `public` | `private` | `mixed` (mixed → `notes/private/` gitignored pattern)
- **Hosting**: `local-only` | Gitea (workstation) | GitHub | both -- defer remote push by default

### 2. Propose the scaffold (text only)
Lay out the directory tree and file list. Get explicit user approval before writing. The tree itself encodes redteam-relevant choices (e.g., `notes/` vs `notes/private/`).

### 3. Run [redteam] against the *proposed* environment
Adapt the standard categories to the specific repo type:

- **A -- Artifact injection**: PDFs, web fetches, BibTeX, community-editable mirrors
- **B -- Tool-result injection**: anything WebFetched into agent context
- **C -- Scope escape**: agent-specific guardrails (Gemini/Codex/Kimi blocked scope)
- **D -- Data exfiltration**: pushing confidential content to public mirrors
- **E -- Agent-specific risk**: fabrication / scope-creep patterns per agent's audit history
- **F -- Workflow risk**: circular references, propagation of unverified claims

For each: list AT-RISK surfaces and count PASS-by-design. Note: pre-build redteam often returns mostly AT-RISK -- that is the point. The number drops as mitigations move into the initial commit.

### 4. Triage mitigations
- **CRITICAL**: must be in initial commit (private/ gitignored, frozen canonical files, secret patterns in .gitignore)
- **HIGH**: in initial commit, lighter touch (AGENTS.md per-repo guardrails, README provenance block)
- **MEDIUM**: encode in templates / lane briefs (verification protocols, fabrication checklists)
- **LOW**: defer until pattern proves out (pre-commit hooks, scanners, automated mirror diffing)

### 5. Get approval for the revised plan
Show the user the mitigations and which tier each lands in. Pushback adjusts the plan, not the threat model.

### 6. Build with mitigations baked in
- `mkdir -p` the directory tree
- Write scaffold files in parallel batches
- For research / swarm repos, recurring artifacts:
  - `README.md` with provenance block ("UNVERIFIED until <upstream lane>")
  - `AGENTS.md` -- per-repo extension of `~/.agents/rules/{gemini,codex,kimi}-guardrails.md`
  - `.gitignore` covering secrets, private/, large binaries, scratch
  - Frozen canonical reference files (e.g., `bibliography/AUTHORS_CANONICAL.md`)
  - Lane / task brief template with mandatory verification protocol
- For code repos: delegate file generation to `[repo-scaffold]` then add redteam-mitigation files on top

### 7. Verify gitignore actually catches the critical patterns
```bash
git check-ignore -v <private-path>/test <secret-file> <large-binary>
```
Visible match means the pattern works. No output means a rule is missing.

### 8. First commit
Conventional Commits. Reference the redteam pass in the body: surfaces identified, mitigations tier-by-tier. The commit message itself becomes evidence the discipline ran.

### 9. Bus post (per CRAP protocol)
If the repo is under PROJECTS/, post a STATUS to the bus naming the commit SHA as evidence.
```
Type: STATUS
To: all
Message: [repo-init-secured] <repo-name> scaffolded. Commit: <sha>. Mitigations: <C> CRITICAL + <H> HIGH baked in.
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

## Output Format

```
Repo Init Secured | <name> | <type>
============================================================
Proposed:     <N> files, <M> dirs
Redteam:      <X>/<Y> surfaces AT-RISK before scaffold
Mitigations:  <C> CRITICAL + <H> HIGH baked in; <M> MEDIUM + <L> LOW deferred
Scaffold:     commit <sha>, <N> files, <L> insertions
Gitignore:    verified patterns: <list>
Bus:          posted | skipped (reason)
------------------------------------------------------------
Next: [redteam] against actual scaffold | start upstream lane | push to Gitea
```

## Skill Chains

### Mandatory

- `[threat-model]` MUST pass before execution — threat model the environment to identify attack surfaces and bake mitigations into the initial scaffold.

### Advisory

- After `[repo-init-secured]` → `[redteam]` (re-run against the *actual* scaffold to confirm mitigations are operative, not just on paper)
- After `[repo-init-secured]` for code repo → `[readme-gen]`, `[ci-monitor]` (post-push)
- After `[repo-init-secured]` for research repo → start the upstream lane (Lane A in swarm convention)

## Authority

- **T1 (TRUSTED)**: May run with `[threat-model]` passed
- **T2 (Active/High)**: May run with `[threat-model]` passed
- **T3 (Medium)**: Operator approval required + `[threat-model]` passed
- **T4 (Probationary)**: BLOCKED
- **Operator**: Override any restriction

## Constraints
- Never scaffold without the user's explicit approval of the proposed tree
- Never skip the redteam pass to save time -- the pass is the whole point
- Never ship CRITICAL mitigations as "we'll add it next commit" -- baked-in or pulled from scope
- Always validate `.gitignore` with `git check-ignore` before first commit, not after
