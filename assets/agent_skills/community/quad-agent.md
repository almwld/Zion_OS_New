---
name: quad-agent
description: Four-agent workflow — full Research→Design→Implement→Validate pipeline or parallel investigation with synthesis
version: 1.0.0
argument-hint: "<topology> [task description]"
execution-mode: side_effecting
category: fleet-ops
status: tested
providers:
  required: [bash, python]
---

# /quad-agent — Four-Agent Workflow

Extends `/tri-agent` to four agents. Two topologies: the full product pipeline (RDIV) and parallel investigation with synthesis (PIS).

**Prerequisite**: Read `.claude/rules/handoff-packet.md`. Every handoff uses a packet.
**Check first**: Can this be done with `/tri-agent`? Only use quad when the fourth slot adds genuine value — don't add agents for symmetry.

---

## Topologies

### `rdiv` — Research → Design → Implement → Validate

```
Gemini (or /deep-research) → Claude → Codex → $REASONING_MODEL
```

**When to use**: New features where you want landscape before architecture, and independent validation after implementation. The complete product cycle.

**Agent roles:**
- **Slot 1 — Research** (Pull): Landscape, prior art, scope estimate. Output: `docs/research/<slug>-LANDSCAPE.md`. Use Gemini when off probation; use Claude + `/deep-research` while on probation.
- **Claude — Design** (Push): Architecture decision + acceptance criteria. Reads the landscape. Bounds the solution space. No implementation.
- **Codex — Implement** (Pull): Implements against the bounded spec. No new design decisions. Opens PR.
- **$REASONING_MODEL — Validate** (Pull/adversarial): Independent validation of the implementation. Red-teams the fix. Posts findings to bus.

**Handoff sequence:**

```
Slot1 → LANDSCAPE.md
       ↓ handoff packet (type: DISPATCH, to: claude-code)
Claude → Architecture decision + acceptance criteria
       ↓ handoff packet (type: DISPATCH, to: codex, execution-mode: side_effecting)
Codex → PR + STATUS on bus
       ↓ handoff packet (type: REVIEW, to: $REASONING_MODEL)
$REASONING_MODEL → SITREP with adversarial findings
       ↓ Claude final verdict
```

**Dispatching $REASONING_MODEL validation (remote inference host):**
```bash
ssh $INFERENCE_HOST "curl -s http://localhost:11434/api/generate -d '{
  \"model\": \"$REASONING_MODEL\",
  \"prompt\": \"You are an adversarial security reviewer. Given this implementation, find flaws the implementer missed. Be specific. Cite lines.\\n\\n<paste diff or key code>\",
  \"stream\": false
}'" | python3 -c "import sys,json; r=json.load(sys.stdin); print(r['response'])"
```

**Gemini slot substitute (while on probation):**
```bash
# Claude runs /deep-research inline, outputs to file
# Then proceeds to Design step
```

---

### `pis` — Parallel Investigation + Synthesis

```
         ┌→ Codex (implementation path A) ─┐
Claude → │                                  ├→ Claude (synthesize) → Human decision
         └→ $REASONING_MODEL (path B) ───────┘
```

**When to use**: When you're genuinely uncertain whether a problem is better solved by "write new code" (Codex) vs "reason about the existing system" ($REASONING_MODEL). Run both and compare empirically.

**Agent roles:**
- **Claude** (Push): Frames the problem. Produces two candidate approaches. Dispatches both agents simultaneously via bus PROPOSAL.
- **Codex** (Pull): Implements Approach A. Posts structured summary to bus (not full solution).
- **$REASONING_MODEL** (Pull): Analyzes/implements Approach B independently. Posts structured summary.
- **Claude** (Push): Reads both bus summaries. Synthesizes. Requests full diff only from the winner.

**Critical**: Agents receive the same input simultaneously (parallel, not sequential). Otherwise $REASONING_MODEL critiques Codex's framing rather than independently reaching a conclusion.

**Parallel dispatch via bus:**
```bash
# Resolve canonical identity first
QUAD_BUS_ID=$(python3 -c "import sys; sys.path.insert(0,'$HOME/.agents/scripts'); from bus_identity import require_bus_identity; print(require_bus_identity())")
# Claude posts PROPOSAL to both simultaneously
python -m bus.bus_writer "$QUAD_BUS_ID" "codex" "PROPOSAL" \
  "PIS task-id=<slug>: Approach A — <description>. Post structured summary when done."
python -m bus.bus_writer "$QUAD_BUS_ID" "all" "PROPOSAL" \
  "PIS task-id=<slug>: Approach B for $REASONING_MODEL — <description>. Post SITREP summary when done."
# Then SSH to remote inference host to trigger $REASONING_MODEL
```

**Synthesis prompt (Claude, after both summaries on bus):**
```
Read both summaries. Which approach actually solved the problem?
What did each miss? Recommend winner + one follow-up item per agent.
```

---

## Output Format

```
/quad-agent | <topology> | <task-id>
══════════════════════════════════════

## Topology
<rdiv | pis>

## Stage 1: <agent>
Status: COMPLETE / IN PROGRESS / BLOCKED
Output: <summary or file>

## Stage 2: <agent>
Status: COMPLETE / IN PROGRESS / BLOCKED
Output: <summary or file>

## Stage 3: <agent>
Status: COMPLETE / IN PROGRESS / BLOCKED
Output: PR #N or <summary>

## Stage 4: <agent>
Status: COMPLETE / IN PROGRESS / BLOCKED
Verdict: PASS / FIX FIRST / WINNER: <A|B>

## Next Hand-off
Route to: <agent | human>
```

---

## Routing Decision Tree

```
New feature needing full cycle (research → build → validate)?
  └→ YES: rdiv

Genuinely uncertain between two implementation approaches?
  └→ YES: pis (run both, compare)

Just need research + design + build?
  └→ NO, use /tri-agent rdb (simpler)

Just need triage + fix + validate?
  └→ NO, use /tri-agent tfv (simpler)

Just need advisory + fix?
  └→ NO, use /dual-agent (simplest)
```

---

## Prerequisites

| Topology | Requires |
|----------|---------|
| `rdiv` | Gemini off probation OR Claude + web research; remote inference host + $REASONING_MODEL for Slot 4 |
| `pis` | remote inference host + both $REASONING_MODEL and Codex available simultaneously |

**Verify before dispatching:**
```bash
# Confirm remote inference host models
ssh $INFERENCE_HOST "curl -s http://localhost:11434/api/tags" | python3 -c \
  "import sys,json; [print(m['name']) for m in json.load(sys.stdin)['models']]"
```

---

## Context Budget Warning

At four agents, context pressure on the synthesis/orchestrator role (Claude) is real. Mitigate:
- Each agent posts a **structured bus summary** (max 5 bullet points), not full output
- Claude reads bus summaries first; requests full diff/output only if needed
- If Claude's context window is near limit, use DREAM crystallization on remote inference host instead of inline synthesis

---

## Anti-Patterns

- Don't run quad when tri is sufficient — every agent adds a coordination seam
- Don't let Slot 1 (research) drift into design — strict LANDSCAPE.md only output
- Don't run PIS when you already have a preferred approach — use dual-agent instead
- Don't skip the bus summary step — full outputs from 4 agents will compact context

---

## Chain
- Before quad-agent → run `/tri-agent` at least once on a real task to validate remote inference host connectivity
- After rdiv → `/aar` on whether $REASONING_MODEL validation caught anything Codex missed
- After pis → `/ledger` the architecture decision with evidence from both paths
- When quad-agent proves stable → `/poly-agent` for N-agent manifest-driven dispatch

## Lexicon

This skill uses the canonical swarm lexicon (`~/.agents/rules/swarm-lexicon.md`).
Key terms: swarm, lane, topology, handoff packet, context budget,
bus summary. Conflicts between this skill's local vernacular and the lexicon
resolve in favor of the lexicon.

## Skill Chains
- For reasoning model for the validation slot -> `[reasoning-router]` (`python ~/bin/reasoning_router.py route`)

## Mandatory

None — workflow orchestration; individual agents execute within their own authority.

## Authority

- **T1 (TRUSTED)**: May run
- **T2 (Active/High)**: May run
- **T3 (Medium)**: Operator notification required
- **T4 (Probationary)**: May not run
- **Operator**: Override any restriction
