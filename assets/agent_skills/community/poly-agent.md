---
name: poly-agent
description: Manifest-driven N-agent dispatch (N≥5) — declare agents, topology, sync points, context budget, and a cross-agent synthesis gate in a manifest block; use this for multi-lane agent analysis where the orchestrator must preserve lane independence before chief-synthesis-officer reconciliation.
version: 1.0.0
execution-mode: side_effecting
argument-hint: "<topology> [manifest-slug or inline task]"
category: fleet-ops
status: tested
providers:
  required: [bash, python]
---
# [poly-agent] — Manifest-Driven N-Agent Dispatch

Extends single-agent orchestration to arbitrary N. The topology and agent roster are declared in a **manifest block** — not hardcoded. The Principal Agent manages sync points, context budget, and final synthesis routing.

**Prerequisite**: The selected topology must have been proven on a reversible advisory task before it is used for mission-critical work. Read `.claude/rules/handoff-packet.md` when handoff packets are used. Every inter-agent handoff uses a packet.

**Hard limit**: Do not use poly-agent when a single agent, a purpose-built topology such as `[dialectical-analysis]`, or a smaller direct sub-agent run is sufficient. Every agent adds a coordination seam and a context tax. Use the simplest topology that covers the problem.

**Synthesis officer**: For analytical poly-agent runs, final synthesis routes through `[cross-agent]`. The cross-agent lane receives the manifest, prompts, lane outputs, sync-point status, and human objective, then produces the chief-synthesis-officer report before the orchestrator reports to the Human.

---

## The Manifest

A poly-agent run is defined by a manifest block embedded at invocation. The manifest is the source of truth for the entire run.

```yaml
# poly-agent manifest
manifest-version: 1.0
task-id: <slug>
orchestrator: <principal-agent-canonical-id>
topology: fan | ladder | tournament | dag
context-budget: 400  # max words per agent bus summary
fault-policy: skip | retry | escalate  # what to do if a lane fails

lanes:
  - id: lane-1
    label: "<human-readable role>"
    agent: codex | claude-code | opencode | devin | gemini | <canonical-agent-id> | <named-role>
    mode: push | pull
    input: orchestrator | lane-N | manifest
    output: bus-summary | file | handoff-packet
    depends-on: []  # for dag topology; empty = starts immediately

sync-points:
  - after: [lane-1, lane-2, lane-3]  # all must complete before proceeding
    action: synthesize | cross-agent-synthesize | gate | tournament-round

output:
  format: bus-summary | file | recommendation  # advisory decision-support; not a DECISION bus message
  destination: bus | hummbl_governance/docs/research/<slug>.md | human
```

---

## Topologies

### `fan` — Parallel Investigation + Central Synthesis

```
                ┌→ Lane 1 (role A) ──┐
                ├→ Lane 2 (role B) ──┤
Orchestrator →  ├→ Lane 3 (role C) ──┼→ Sync Point → Synthesis → Output
                ├→ Lane 4 (role D) ──┤
                └→ Lane 5 (role E) ──┘
```

**When to use**: N independent analytical lenses on the same question. Each lane is role-prompted separately. All lanes receive identical input. No lane sees another's output (prevents anchoring). Synthesis happens only after all lanes complete.

**Context discipline** (critical at N≥5):
- Each lane posts a **structured bus summary** only (max 400 words)
- Orchestrator reads bus summaries to synthesize — never requests full output inline
- If a lane's full output is needed, request the file path, not the content

**Dispatching logical parallel lanes**:

Use native parallel sub-agents when the runtime supports them. If the runtime
can only run one lane at a time, execute lanes sequentially while preserving
logical independence: no lane reads another lane's output before the sync point.
For actual parallel execution, dispatch to separate guarded sessions or host
lanes and collect summaries through the manifest's declared sync points.

See `PROMPTS.md` in this directory for the canonical templates (Decision, Risk, Research).
Use the appropriate template. All lanes must include the 4 mandatory invariants:
1. "You are arriving at this problem from the domain of [DOMAIN]" (not a job title)
2. "Commit to a position. Do not hedge everything."
3. "Do not optimize for agreement or synthesis-readiness. Disagreement is signal."
4. Strict output format: `Claim / Evidence / Implication / Confidence / Lens`

```
[POLY-AGENT LANE DISPATCH — task-id=<slug>, topology=fan]
You are arriving at this problem from the domain of <DOMAIN>.
<Insert Template A / B / C from PROMPTS.md>
Input: <shared context — max 3 sentences>
Output: max 400 words, strict format per template
Do NOT read other lanes' outputs before completing your own.
```

**Fan synthesis prompt** (after all lanes complete):
```
Use [cross-agent] as chief synthesis officer. Read the manifest, shared context,
lane prompts, and N bus summaries from task-id=<slug>. For each:
1. What does this lens uniquely surface that others miss?
2. Where do multiple lenses converge? That convergence is load-bearing.
3. Where do lenses contradict? That contradiction is the decision point.
Synthesize into: Chain Integrity + Convergences + Contradictions + Blind Spots + Executive Verdict + Top 3 Actions + Key Uncertainty.
```

---

### `ladder` — N-Step Sequential Chain

```
Lane 1 → Lane 2 → Lane 3 → ... → Lane N → Output
```

**When to use**: Each step must read the previous step's output (e.g., Research → Design → Implement → Test → Document → Ship). Sequential dependency is real, not assumed.

**Handoff**: Each lane produces a handoff packet (not just a bus summary) because the next lane needs the full structured output to proceed.

---

### `tournament` — Elimination Bracket

```
Round 1: [L1 vs L2] [L3 vs L4] [L5 vs L6]
                ↓
Round 2: [Winner A vs Winner B] [Winner C]
                ↓
Final:   [Winner → Synthesis]
```

**When to use**: N competing approaches/options/designs. You want empirical comparison, not just a priori reasoning. The bracket structure prevents the "first option bias" that afflicts linear comparison.

**Tournament prompt per matchup**:
```
Option A: <summary from lane-1>
Option B: <summary from lane-2>
Evaluation criteria: <from manifest>
Winner: Pick one. State the deciding factor in one sentence.
```

---

### `dag` — Arbitrary Directed Acyclic Graph

**When to use**: Complex multi-phase pipelines where some lanes depend on specific prior lanes (not all lanes). Define `depends-on` in the manifest. The orchestrator respects the dependency graph.

**Constraint**: Runtime-level parallelism varies. If the current runtime cannot
run lanes simultaneously, pseudo-parallel means running lanes sequentially but
treating them as logically independent (no cross-reading). For true parallelism,
use SSH dispatch to remote-node (dormant since 2026-07-01 — use Workstation instead), separate guarded sessions, or another approved
runtime lane.

---

## Execution Protocol

### Step 1 — Manifest Declaration
The Principal Agent produces the manifest. Human reviews and approves before dispatch.

### Step 2 — Lane Dispatch
For `fan`/`dag` topologies: dispatch all lanes with zero-dependency simultaneously.
For `ladder`: dispatch Lane 1 only; wait for output before dispatching Lane 2.
For `tournament`: dispatch bracket pairs; synthesize round winners before next round.

### Step 3 — Sync Point Gate
When all lanes in a sync group complete (all post bus summaries):
- Orchestrator reads bus summaries in sequence
- Flags lanes that exceeded context budget (truncate, don't discard)
- Checks for lanes that BLOCKED or FAILED → apply fault-policy

### Step 4 — Cross-Agent Synthesis
For analytical, review, research, governance, strategy, self-review, or decision
runs, route synthesis through `[cross-agent]` before the final human-facing
output.

Cross-agent receives:
- poly-agent manifest;
- human objective;
- shared context packet;
- lane roster and prompts;
- lane outputs or bus summaries;
- sync-point status;
- unresolved failures, skips, or retries;
- requested synthesis mode.

Output: chain-integrity check, agent-output matrix, convergences,
contradictions, blind spots, structured verdict, top actions, and key
uncertainty.

Exception: For a pure ladder implementation pipeline where a single downstream
owner is explicitly responsible for integration, cross-agent may be marked
`N/A` in the output. The orchestrator must explain why synthesis was owned by
the downstream lane instead of the cross-agent lane.

### Step 5 — Red-Team (optional but recommended for high-stakes decisions)
Route synthesis to deepseek-r1:32b for adversarial review:
```bash
ssh -o ConnectTimeout=10 mini "curl -s http://localhost:11434/api/generate -d '{
  \"model\": \"deepseek-r1:32b\",
  \"prompt\": \"Adversarially review this synthesis. What assumption is most likely wrong? What did all N lenses miss collectively? What is the strongest argument against the recommended action?\\n\\n<paste synthesis>\",
  \"stream\": false
}'" | python3 -c "import sys,json; r=json.load(sys.stdin); print(r['response'])"
```

### Step 6 — Human Decision Gate
For mission-critical decisions: synthesis + red-team → human. The poly-agent output is advisory until human ACKs.

If the Human makes or approves a durable decision, record it through the
current runtime's allowed decision-log or ledger path. Agents do not post
`DECISION` unless a current canonical rule explicitly grants that authority.

Agents may post a closeout proposal or receipt with the runtime-specific
identity-hardcoded bus wrapper:
```text
$env:USERPROFILE\bin\codex-bus.cmd all PROPOSAL "host=agent-node task-id=<slug>: recommended decision=<one-line>. Evidence: poly-agent fan, N=<count> lanes; human_decision=required"
```

---

## Output Format

```
[poly-agent] | <topology> | <task-id> | N=<lane-count>
══════════════════════════════════════════════════════

## Manifest
topology: <fan|ladder|tournament|dag>
lanes: <count>
sync-points: <count>
context-budget: <words>/lane

## Lane Results
| Lane | Label | Status | Key Finding (1 line) |
|------|-------|--------|----------------------|
| 1 | <label> | COMPLETE / BLOCKED / FAILED | <finding> |
| 2 | <label> | COMPLETE | <finding> |
| ... | | | |

## Convergences (what multiple lenses agreed on)
- <convergence 1>
- <convergence 2>

## Contradictions (where lenses disagreed)
- <contradiction 1> — Lane X says A, Lane Y says B

## Synthesis
<Executive verdict, max 200 words>

## Cross-Agent Review
<chief synthesis officer chain-integrity finding, contradictions, blind spots, and residual uncertainty>

## Red-Team Finding
<deepseek adversarial result, if run>

## Top 3 Actions
1. <action> — <owner> — <timeline>
2. <action> — <owner> — <timeline>
3. <action> — <owner> — <timeline>

## Key Uncertainty
<The one thing we still don't know that would change the decision>

## Next Hand-off
Route to: <agent | human>
Decision gate: <required | optional>
```

---

## Context Budget Management

At N=6+ lanes, the orchestrator's context window is under real pressure. Strict discipline:

| N lanes | Risk level | Mitigation |
|---------|-----------|------------|
| 5–6 | Low | Standard bus summaries (400 words max) |
| 7–9 | Medium | Reduce to 200 words/lane; run synthesis on remote-node via deepseek (remote-node dormant since 2026-07-01 — use Workstation) |
| 10–14 | High | File-based output only (no inline); orchestrator reads file paths |
| 15+ | Critical | Use `[swarm]` instead — poly-agent is not designed for this scale |

**If context is near limit during synthesis**: Use DREAM crystallization on remote-node (dormant since 2026-07-01 — use Workstation instead):
```bash
# Write all bus summaries to a temp file, send to deepseek for synthesis
ssh -o ConnectTimeout=10 mini "curl -s http://localhost:11434/api/generate -d '{
  \"model\": \"deepseek-r1:32b\",
  \"prompt\": \"Synthesize these N analytical summaries into a verdict + 3 actions + key uncertainty:\\n\\n<paste summaries>\",
  \"stream\": false
}'" | python3 -c "import sys,json; r=json.load(sys.stdin); print(r['response'])"
```

---

## Fault Policy

| Policy | Behavior |
|--------|---------|
| `skip` | Proceed without the failed lane. Note in output. |
| `retry` | Re-run failed lane once. If still fails, apply `skip`. |
| `escalate` | Halt the run. Post BLOCKED to bus. Await human. |

Default: `skip` for research lanes, `escalate` for implement/validate lanes.

---

## Anti-Patterns

- Don't use poly-agent for tasks completable by a single agent — it is a coordination overhead machine
- Don't let lanes read each other's output during the parallel phase — destroys independence
- Don't skip the manifest — undeclared poly runs become ad-hoc chaos at N≥5
- Don't synthesize mid-run — all lanes must complete before the sync point
- Don't exceed 14 lanes without switching to `[swarm]`
- Don't use poly-agent without a human decision gate on mission-critical outputs — synthesis is advisory, not directive

---

## Routing Decision Tree

```
Task has N≥5 independent analytical dimensions?
  └→ YES: fan topology (all lenses see same input, no cross-talk)

Task has N≥5 sequential dependent steps?
  └→ YES: ladder topology (each step reads prior)

Task has N competing options to compare empirically?
  └→ YES: tournament topology (bracket elimination)

Task has complex step dependencies (some parallel, some sequential)?
  └→ YES: dag topology (declare depends-on in manifest)

N < 5?
  └→ Use a direct sub-agent run, [dialectical-analysis] for thesis -> antithesis -> synthesis, or a single-agent review. Do not invoke retired lower-N skill names unless their SKILL.md files exist in the current registry.

N > 14?
  └→ Use [swarm] (machine-level fan-out, not session-level)
```

---

## Canonical Use Case: HUMMBL Vertex GenAI Credit Strategy (Apr 8 2026)

The first poly-agent run. Fan topology, N=6 lanes, mission-critical resource allocation decision.

**Manifest**:
```yaml
manifest-version: 1.0
task-id: vertex-credit-strategy-apr8
orchestrator: <principal-agent-canonical-id>
topology: fan
context-budget: 400
fault-policy: skip

lanes:
  - id: lane-1
    label: "Strategic / Competitive Moat"
    agent: <canonical-agent-id> (role-prompted)
    mode: push
  - id: lane-2
    label: "Technical / Pipeline Feasibility"
    agent: <canonical-agent-id> (role-prompted)
    mode: push
  - id: lane-3
    label: "Financial / ROI & Credit Burn"
    agent: <canonical-agent-id> (role-prompted)
    mode: push
  - id: lane-4
    label: "Risk / Dependencies & Failure Modes"
    agent: <canonical-agent-id> (role-prompted)
    mode: push
  - id: lane-5
    label: "BKI + Governance Narrative"
    agent: <canonical-agent-id> (role-prompted)
    mode: push
  - id: lane-6
    label: "Market / Sales & Customer Validation"
    agent: <canonical-agent-id> (role-prompted)
    mode: push

sync-points:
  - after: [lane-1, lane-2, lane-3, lane-4, lane-5, lane-6]
    action: synthesize

output:
  format: file
  destination: hummbl_governance/docs/research/vertex-credit-strategy-apr8.md
```

---

## Lexicon

This skill uses the canonical swarm lexicon (`~/.agents/rules/swarm-lexicon.md`).
Key terms: swarm, wave, batch, team, lane, orchestrator, topology, fan-out,
fan-in, manifest, sync point, chief synthesis officer, context budget,
fault-policy. Conflicts between this skill's local vernacular and the lexicon
resolve in favor of the lexicon.

## Skill Chains
- For inference for agent lanes -> `[reasoning-router]` (`python ~/bin/reasoning_router.py route`)

### Mandatory (MUST pass before dispatch)

- **`[swarm-manifest]`** MUST be generated (lane allocation, budget, pre-flight)
- **Human decision gate** MUST be acknowledged for mission-critical outputs (per Step 6)
- **`[cross-agent]`** MUST be declared as the final synthesis officer for analytical poly-agent runs. If omitted, the manifest must state why cross-agent is `N/A`.

### Advisory

- Before poly-agent → prove the intended topology on a reversible advisory task
- During poly-agent → `[bus]` to monitor lane summaries as they arrive
- After cross-agent synthesis → deepseek red-team (Step 5 above) if adversarial review is warranted
- After decision → `[ledger]` the decision with poly-agent evidence
- After first poly-agent run → `[aar]` on coordination quality (did N lanes add value?)
- For opencode lane dispatch → `[cross-runtime-bridge]` (`python ~/bin/cross_runtime_bridge.py delegate "<task>" --workdir <dir> --auto`); track sessions with `python ~/bin/cross_runtime_bridge.py sessions`
- When poly-agent proves stable → document patterns in `[retrospective]`
- At N>14 → escalate to `[swarm]` (machine-level parallelism, not session-level)

## Rate-limit discipline

Per `~/.agents/rules/staggered-subagent-deploy-rate-limit.md`:

- **Default stagger**: 250ms between lane launches (jittered ±50ms)
- **Default concurrency cap**: 5 (N=5 lanes default)
- **Override env vars**: `STAGGER_MS` (set to 0 to disable), `POLY_CONCURRENCY`
- **On 429 / spend-cap**: stop further spawns to that provider, post bus `BLOCKED` identifying limiter (RPM/ITPM/OTPM/SPEND_CAP), retry with exponential backoff (1s, 2s, 4s, 8s, cap 60s)
- **Override logging**: every `STAGGER_MS=0` or `CONCURRENCY_OVERRIDE` use posts a bus STATUS

## Authority

- **T1 (TRUSTED)**: May dispatch poly-agent with `[swarm-manifest]` + human decision gate
- **T2 (Active/High)**: MUST get operator approval AND `[swarm-manifest]` passed
- **T3 (Medium)**: MUST get operator approval AND `[swarm-manifest]` passed
- **T4 (Probationary)**: BLOCKED — cannot invoke this skill (N≥5 agent dispatch)
- **Operator**: Override any restriction — poly-agent is advisory until human ACKs
