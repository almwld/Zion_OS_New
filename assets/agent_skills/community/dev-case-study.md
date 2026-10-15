---
name: dev-case-study
description: Generate, draft, or finalize developer portfolio case studies for hummbl-io/hummbl-io. Three modes — retroactive (past PR/work), predictive (upcoming feature), active (in-progress). Targets technical hiring managers and enterprise AI governance buyers.
version: 0.1.0
execution-mode: side_effecting
argument-hint: "<slug-or-pr-or-description> [--mode retroactive|predictive|active] [--update] [--finalize] [--dry-run]"
category: governance-compliance
status: candidate
---
# Dev Case Study | $ARGUMENTS

### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=dev-case-study] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

## Context Gathering

Before executing this skill, gather the following context:
- **Central case studies registry**: Inspect `~/.agents/docs/case-studies/index.json`
- **Existing case studies**: Check `~/.agents/docs/case-studies/README.md`
- **Output directory**: `~/.agents/docs/case-studies/engineering/`
- **Recent bus messages (last 5)**: Run `python3 ~/.agents/scripts/post_bus_review.py --status` or inspect coordination bus

## Mode Detection

Parse `$ARGUMENTS` in priority order:
1. Explicit `--mode retroactive|predictive|active` flag wins
2. Argument matches `pr/<N>` or `#<N>` → retroactive
3. Argument matches a merged branch (`git branch --merged main`) → retroactive
4. Argument matches an open branch with commits → active
5. Argument is free text with no matching branch/PR → predictive
6. No argument → ask the operator which mode

## Dry-Run Mode

If `--dry-run` is present: produce the full case study output as text, do not write any files or run any git commands. Label output `[DRY RUN]`.

---

## Workflow A — Retroactive

**Use when:** work is complete, PR merged, or branch merged to main.

### Data Collection

```bash
# 1. Resolve PR
gh pr view <N> --repo hummbl-io/hummbl-io \
  --json number,title,body,mergedAt,files,commits,comments

# 2. Commit summary on the branch
git log --oneline origin/main..<branch>
git diff origin/main..<branch> --stat

# 3. Test count at merge
cd <relevant-repo> && python3 -m pytest --collect-only -q 2>/dev/null | tail -3

# 4. Bus messages in merge window (±48h of mergedAt)
python ~/bin/bus-global.py tail 200 | awk -F'\t' '$1 >= "<start>" && $1 <= "<end>"' \
  | grep -E 'MILESTONE|DECISION|STATUS|SITREP' | head -20

# 5. Ledger entries for the feature
grep -i "<slug-keyword>" \
  /work/active/hummbl-cognition/_state/cognition/ledger.jsonl | tail -10
```

### Output

Write `case-studies/<slug>.md` to `hummbl-io-profile` on branch `feat/claude/case-study-<slug>`, then open a PR unless `--dry-run`.

---

## Workflow B — Predictive

**Use when:** feature is planned but not started. Generates a brief with `[PREDICTED]` / `[TO FILL]` placeholders.

### Steps

1. Populate Problem from input description or `gh issue view <N>`.
2. Seed Constraints from CLAUDE.md conventions (stdlib-only, < 300 LOC/PR, mobile-first).
3. Mark Architecture Decisions, Test Coverage, and Outcomes as `[TO FILL]`.
4. Set `status: draft`, `mode: predictive` in frontmatter.
5. Write to `case-studies/<slug>-brief.md`. Do not open a PR — brief is a working document.

---

## Workflow C — Active

**Use when:** work is in progress. Maintains a live `.draft.md` that is finalized on completion.

### Sub-phases

**Open** (`[dev-case-study] "<description>" --mode active`)
- Generate the schema as a draft with `[TO FILL]` placeholders
- Write to `case-studies/<slug>.draft.md`
- Append a `## Session Log` section (append-only rows during work)

**Update** (`[dev-case-study] <slug> --update`)
- Read current `.draft.md`
- Append one row to Session Log: `| <today> | <summary of latest bus/ledger activity> |`
- No commit required until finalize

**Finalize** (`[dev-case-study] <slug> --finalize`)
- Fill all `[TO FILL]` placeholders from merged PR data, bus, ledger
- Remove `## Session Log` section
- `git mv case-studies/<slug>.draft.md case-studies/<slug>.md`
- Set `status: published`, `finalized: <today>`
- Commit and open PR

---

## Case Study Schema

Every case study — regardless of mode — resolves to this structure:

```markdown
---
title: "<one-line outcome statement>"
slug: "<kebab-case identifier>"
status: draft | published
mode: retroactive | predictive | active
created: YYYY-MM-DD
finalized: YYYY-MM-DD
repo: "<github.com/hummbl-io/X or N/A>"
pr: "<#NNN or N/A>"
tags: []
---

# Case Study: <Title>

**Project:** <name>
**Architect:** Reuben Bowlby, Founder & Principal Architect
**Timeline:** <dates>
**Stack:** <technologies>

---

## Context
2-3 sentences. System state, team, environment — the grounding "when/where."

## Problem
The forcing function. Why was this built? What breaks without it?
Source: PR description, issue body, bus MILESTONE messages.

## Constraints
What was explicitly ruled out and why.
This section does the most work for enterprise buyers — governance judgment, not just execution.

## Architecture Decisions
Each significant decision as a short ADR-style entry:
- **Decision:** what was chosen
- **Alternatives considered:** what was rejected
- **Rationale:** why

## Implementation
What was built. Key files/modules. ASCII architecture diagram if warranted.

## Test Coverage
Quantitative: test count, key strategies. Never fabricate — source from pytest output or CI.

## Multi-Agent Coordination Evidence
| Timestamp | From | To | Type | Signal |
|---|---|---|---|---|

Excerpt 1-3 bus messages or ledger entries showing real multi-agent decision-making.
This is the differentiator section.

## Outcomes
Measurable results. Before/after table where possible.
Label inferences as `[INFERRED]`, estimates as `[ESTIMATE]`.

## Governance Primitives Used
Which hummbl-governance primitives were exercised, with links.

## Key Takeaways
3-5 bullet points for the target reader (hiring manager, CISO, enterprise buyer).
Frame as demonstrated capability.

## Related Work
Links to other case studies, PRs, blog posts.
```

---

## Evidence Standards

- **Never fabricate test counts** — run `pytest --collect-only` or quote from CI output
- **Never fabricate bus messages** — excerpt verbatim from messages.tsv or omit the section
- **Label all inferences** — `[INFERRED]` for reconstructed reasoning, `[ESTIMATE]` for approximations, `[PREDICTED]` for predictive mode outcomes
- **Source every statistic** — file:line, command output, or bus timestamp

---

## Storage & Indexing Protocol

Case studies produced by `dev-case-study` are committed to the central registry:

```bash
# 1. Save case study to central engineering folder
DEST=~/.agents/docs/case-studies/engineering/cs-eng-<slug>.md

# 2. Run source-verification gate
python3 ~/.agents/skills/case-study-verify/scripts/case_study_verify.py "$DEST"

# 3. Re-index central registry
python3 ~/.agents/scripts/index_case_studies.py

# 4. Commit to ~/.agents
git add ~/.agents/docs/case-studies/
git commit -m "feat(case-study): add cs-eng-<slug>"
```

---

## Skill Chains

### Mandatory

- `[content-review]` MUST pass before publishing — case studies are external-facing portfolio content representing the organization.

### Advisory

- After case study published → `[social-post]` to promote on LinkedIn/X
- After case study published → `[seo-check]` on the markdown file
- Before predictive brief → `[pre-mortem]` to anticipate failure modes
- Need deep commit history → `[git-archaeology]`
- Need PR body without writing → `[pr-summary] --dry-run`
- Bus evidence is sparse → `[bus-analytics]` for pattern analysis
- Want governance angle → `[nist-map]` to tag primitives to controls
- After first 3 case studies → `[portfolio-score]` to assess overall profile

## Authority

- **T1 (TRUSTED)**: May run
- **T2 (Active/High)**: May run
- **T3 (Medium)**: Run with operator approval + `[content-review]` before publishing
- **T4 (Probationary)**: May draft but may not publish
- **Operator**: Override any restriction
