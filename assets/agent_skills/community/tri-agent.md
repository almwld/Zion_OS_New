---
name: tri-agent
description: Three-agent workflow with selectable topology — extends dual-agent to include a third role (triage, research, or adversarial red-team)
version: 1.0.0
argument-hint: "<topology> [task description]"
execution-mode: side_effecting
category: fleet-ops
status: tested
providers:
  required: [bash, python]
---

# /tri-agent — Three-Agent Workflow

Extends `/dual-agent` to three agents. The third agent adds a capability the dual-agent loop lacks: fast pre-filtering (T-F-V), independent research (R-D-B), or adversarial pressure (P-R-A).

**Prerequisite**: Read `.claude/rules/handoff-packet.md` before dispatching. Every inter-agent handoff uses a handoff packet.

---

## Topologies

### `tfv` — Triage → Fix → Validate (Security Pipeline)

```
qwen3.5:9b (remote inference host) → Codex → Claude
```

**When to use**: Security findings, diff review, finding prioritization before implementation.

**Agent roles:**
- **qwen3.5:9b** (Push): Classifies findings as HIGH/MED/LOW. Fast, cheap, no reasoning. Output: JSON list.
- **Codex** (Pull): Receives HIGH items only. Implements fixes. Posts STATUS with PR.
- **Claude** (Push): Audits fix against policy. Posts PASS or FIX FIRST.

**Executing T-F-V:**

Step 1 — Dispatch to qwen3.5:9b (via remote inference host SSH):
```bash
ssh $INFERENCE_HOST "curl -s http://localhost:11434/api/generate -d '{
  \"model\": \"qwen3.5:9b\",
  \"prompt\": \"Classify each finding as HIGH/MED/LOW. Output JSON array with fields: finding, severity, rationale.\\n\\nFindings:\\n<paste findings>\",
  \"stream\": false
}'" | python3 -c "import sys,json; r=json.load(sys.stdin); print(r['response'])"
```

Step 2 — Filter to HIGH, build handoff packet for Codex:
```markdown
---
packet-version: 1.0.0
from: <your-canonical-identity>
to: codex
type: DISPATCH
task-id: <slug>
priority: HIGH
execution-mode: side_effecting
---
## Finding
qwen3.5:9b triage complete. HIGH severity items: [paste JSON subset]

## Recommended Action
Fix each HIGH item. One PR per logical group.

## Verification Criteria
Tests pass; each HIGH finding resolved; no new HIGH findings introduced
```

Step 3 — After Codex posts STATUS, Claude audits (same as dual-agent Phase 4).

---

### `rdb` — Research → Design → Build

```
Gemini (or Claude+/deep-research) → Claude → Codex
```

**When to use**: New features where competitive landscape should inform architecture before implementation. Gemini fills Slot 1 when off probation; use `/deep-research` as substitute while Gemini is on probation.

**Agent roles:**
- **Slot 1** (Pull/research): Landscape research, prior art, scope estimate. Output: `LANDSCAPE.md` in `docs/research/`.
- **Claude** (Push): Architecture decision + acceptance criteria. Bounds the solution space. No open-ended design.
- **Codex** (Pull): Implements against the bounded spec. No new design decisions.

**Critical constraint**: Slot 1 output must be in `docs/research/` (not root `docs/`). Gemini probation rule applies.

**Handoff packet Claude → Codex:**
```markdown
---
packet-version: 1.0.0
from: <your-canonical-identity>
to: codex
type: DISPATCH
task-id: <slug>
priority: MEDIUM
execution-mode: side_effecting
---
## Context
Research complete. Architecture scoped.

## Finding
Landscape: docs/research/<filename>.md
Architecture decision: [summary]

## Recommended Action
Implement per acceptance criteria below. No new design decisions.

## Verification Criteria
[acceptance criteria from Claude's design step]
```

---

### `pra` — Propose → Red-Team → Arbitrate (Decision Pipeline)

```
Claude (propose) ∥ deepseek-r1:32b (red-team) → Human (decide) → Codex (execute)
```

**When to use**: Architecture decisions, policy choices, security design — any decision where you want genuine adversarial pressure before committing.

**Agent roles:**
- **Claude** (Push): Generates Options A/B/C with rationale.
- **deepseek-r1:32b** (Pull): Independently red-teams each option. Different training, different failure modes — disagreement is signal.
- **Human**: Reads both. Makes DECISION. Routes to Codex.
- **Codex** (Pull): Executes the decision.

**Dispatching deepseek-r1:32b (remote inference host):**
```bash
ssh $INFERENCE_HOST "curl -s http://localhost:11434/api/generate -d '{
  \"model\": \"deepseek-r1:32b\",
  \"prompt\": \"Adversarially review these options. For each: what assumption breaks under adversarial conditions? What did the proposer miss?\\n\\n<paste Claude options>\",
  \"stream\": false
}'" | python3 -c "import sys,json; r=json.load(sys.stdin); print(r['response'])"
```

**Note**: deepseek-r1:32b is slow (~60-120s on remote inference host for complex prompts). Use for decisions worth the wait. Use qwen3.5:9b for fast classification.

---

## Output Format

```
/tri-agent | <topology> | <task-id>
═══════════════════════════════════

## Topology
<tfv | rdb | pra>

## Stage 1: <agent name>
Status: COMPLETE / IN PROGRESS / BLOCKED
Output: <summary or file path>

## Stage 2: <agent name>
Status: COMPLETE / IN PROGRESS / BLOCKED
Handoff packet: [link or inline]

## Stage 3: <agent name>
Status: COMPLETE / IN PROGRESS / BLOCKED
Verdict: PASS / FIX FIRST / PENDING DECISION

## Next Hand-off
Route to: <agent | human>
```

---

## Routing Decision Tree

```
Is the task security/quality review?
  └→ YES: use tfv (qwen triage → Codex fix → Claude audit)

Is the task a new feature needing research first?
  └→ YES: is Gemini off probation?
      ├→ YES: use rdb (Gemini → Claude → Codex)
      └→ NO: use rdb with /deep-research in Slot 1

Is the task an architecture or policy DECISION?
  └→ YES: use pra (Claude propose ∥ deepseek red-team → Human → Codex)

None of the above?
  └→ Use /dual-agent (simpler, fewer coordination seams)
```

---

## Prerequisites for Each Topology

| Topology | Requires |
|----------|---------|
| `tfv` | SSH to remote inference host, Ollama running, qwen3.5:9b pulled |
| `rdb` | Gemini off probation OR Claude with web research; remote inference host not required |
| `pra` | SSH to remote inference host, Ollama running, deepseek-r1:32b pulled |

**Verify remote inference host before dispatching:**
```bash
ssh -o ConnectTimeout=5 $INFERENCE_HOST "curl -s http://localhost:11434/api/tags" | python3 -c "import sys,json; models=[m['name'] for m in json.load(sys.stdin)['models']]; print('\n'.join(models))"
```

---

## Anti-Patterns

- Don't use `tfv` when you already know severity — skip qwen and go straight to `/dual-agent`
- Don't use `rdb` without a bounded scope — open-ended research with no design checkpoint produces Gemini-style theater
- Don't use `pra` for implementation decisions — use it for design/policy decisions only; Codex doesn't need an adversarial layer for routine fixes
- Don't run two Pull agents back-to-back without a Push agent between them — output variance compounds

---

## Chain
- Before using tri-agent → verify remote inference host connectivity (`ssh $INFERENCE_HOST hostname`)
- After `tfv` → `/aar` on the triage quality (did qwen classify correctly?)
- After `rdb` → `/ledger` the architecture decision before Codex builds
- After `pra` → post DECISION to bus before routing to Codex
- When tri-agent proves stable → `/quad-agent` for full RDIV pipeline
- For opencode lane delegation → `[cross-runtime-bridge]` (`python ~/bin/cross_runtime_bridge.py delegate "<task>" --workdir <dir> --auto`)

## Lexicon

This skill uses the canonical swarm lexicon (`~/.agents/rules/swarm-lexicon.md`).
Key terms: swarm, lane, topology, handoff packet, slot. Conflicts between
this skill's local vernacular and the lexicon resolve in favor of the lexicon.

## Skill Chains
- For inference for the triage slot via free-tier -> `[reasoning-router]` (`python ~/bin/reasoning_router.py route`)

## Mandatory

None — workflow orchestration; individual agents execute within their own authority.

## Authority

- **T1 (TRUSTED)**: May run
- **T2 (Active/High)**: May run
- **T3 (Medium)**: Operator notification required
- **T4 (Probationary)**: May not run
- **Operator**: Override any restriction
