---
name: dual-agent
description: Structured two-agent workflow — Push-dominant agent (Claude) advises; Pull-dominant agent (Codex) investigates and fixes; human routes findings between them
version: 1.0.0
execution-mode: advisory
argument-hint: "[task description]"
category: fleet-ops
status: tested
providers:
  required: [bash, python]
---

# /dual-agent — Structured Dual-Agent Workflow

The dual-agent pattern discovered during the Apr 8 2026 bus security fix. Push and Pull agents have complementary bias; routing findings between them produces better outcomes than either alone.

**Core principle: Pull Once, Push Forever**
- **Push** = cheap determinism (registry lookups, routing rules, schema validation, test runs, bus reads)
- **Pull** = expensive reasoning (root cause analysis, security investigation, novel code generation, judgment calls)

**Agent roles:**
- **Claude (Push-dominant)** — validates, advises, audits, routes. Treats skill output as advisory. Bias: "here's what I see, here are options."
- **Codex (Pull-dominant)** — investigates, fixes, ships. Treats skill output as directive. Bias: "I'll fix it now."

---

## When to Use

- Security findings that need investigation + fix (like the bus sender bypass, Apr 8 2026)
- Code quality issues that need both audit + implementation
- Any task where advisory review and implementation are naturally separate concerns
- When you want validation before Codex acts (Codex has strong fix-bias — unguided it ships immediately)

---

## Workflow

### Phase 1 — Claude Executes (Push)

Run the relevant diagnostic skill inline. Output advisory findings:

```
[ADVISORY — for Codex routing]
Finding: <what was found>
Root cause hypothesis: <why it exists>
Risk: LOW / MEDIUM / HIGH / CRITICAL
Options:
  A. <minimal fix — safest>
  B. <preferred fix — policy change + code>
  C. <full fix — maximum coverage>
Recommended: Option <X>
Evidence: <file:line or command output>
Tests to add: <list>
```

### Phase 2 — Human Routes to Codex (Hand-off)

User copies the advisory to Codex with a prompt like:
```
[advisory output above]
Execute Option B. Post to bus when done. Branch: fix/codex/<slug>
```

### Phase 3 — Codex Executes (Pull)

Codex investigates, implements the fix, runs tests, commits, opens PR, posts STATUS to bus.
Monitor: `bus-global.py tail 5`

### Phase 4 — Claude Audits (Push)

When Codex posts STATUS ("fix complete"), Claude runs the peer review:

```bash
# Check what Codex did
git log --oneline feat/codex/<branch>..HEAD 2>/dev/null || \
  gh pr view <pr-number> --json title,additions,deletions,files
git diff main...fix/codex/<slug> -- <relevant files>
```

Peer review checklist:
- [ ] Fix addresses root cause (not just symptom)
- [ ] Tests cover the failure mode
- [ ] No new security issues introduced
- [ ] Scope within approved bounds
- [ ] Policy/docs updated if behavior changed

Output:
```
Peer Review | PR #<N> | <branch>
══════════════════════════════

Fix quality: PASS / WARN / FAIL
Root cause addressed: YES / PARTIAL / NO
Test coverage: <what's covered, what's missing>
Policy updated: YES / NO
Scope: CLEAN / <violations>

Verdict: SHIP | FIX FIRST | NEEDS REVIEW
<rationale>
```

### Phase 5 — Human Merges (optional Codex follow-up)

If Phase 4 verdict is FIX FIRST, route specific items back to Codex.
If SHIP, squash-merge the PR.

---

## Handoff Prompts (copy-paste ready)

### Claude → Codex initial dispatch
```
[DUAL-AGENT DISPATCH]
Task: <description>
Advisory: [paste Claude's finding]
Execute: Option <X>
Branch: fix/codex/<slug>
When done: post STATUS to bus with PR number
```

### Claude → Codex follow-up (after audit)
```
[DUAL-AGENT FOLLOW-UP — PR #<N>]
Audit finding: <what needs changing>
Specific ask: <exact change needed>
Push to same branch.
```

---

## Output Format

```
Dual-Agent | <task> | Phase <N>
══════════════════════════════

## Phase
<current phase name>

## Finding / Advisory / Verdict
<content per phase>

## Next Hand-off
Route to: Claude / Codex / Human
Message: <what to tell them>
```

---

## Session History

**PR #322 (Apr 8 2026)** — canonical example:
1. Claude ran /ship-check → found bridge_server trust gap + sender bypass
2. Claude produced advisory with Options A/B/C
3. Human relayed to Codex: "fix the bridge trust gap and underlying sender-validation bypass"
4. Codex: isolated branch, fixed both issues, 65 tests green, opened PR #322, posted STATUS
5. Claude: full peer review — PASS, policy update noted, verdict SHIP
6. Codex: ingested feedback, added hardened error message + docs (commit 640afed)
7. Claude: final audit — PASS, squash-merge ready

Four handoffs. One security fix. Both agents did what they're good at.

---

## Anti-Patterns

- Don't use dual-agent for simple tasks — sequential is faster when there's no advisory/implementation split
- Don't skip the advisory phase — Codex without guidance ships the first plausible fix, not the best one
- Don't route Codex output back to Codex without Claude audit — you lose the validation loop
- Don't merge without Claude peer review — Codex has strong fix-bias, may fix symptom not root cause

---

## Lexicon

This skill uses the canonical swarm lexicon (`~/.agents/rules/swarm-lexicon.md`).
Key terms: swarm, lane, Push, Pull, handoff. Conflicts between this skill's
local vernacular and the lexicon resolve in favor of the lexicon.

## Chain
- After finding a security issue → `/dual-agent` immediately
- After `/ship-check` with FAIL → `/dual-agent`
- After `/agent-audit` with violations → `/dual-agent`
- After merge → `/aar` to capture learnings
