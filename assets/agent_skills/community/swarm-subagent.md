---
name: swarm-subagent
description: Fan-out/fan-in orchestration using your runtime's sub-agent dispatch. Dispatch parallel sub-agents, collect results, synthesize. No SSH required.
version: 1.0.0
execution-mode: side_effecting
argument-hint: "<task_description> [--lanes N] [--roles explorer,apex,executor] [--synthesize] [--persist] [--bus]"
category: fleet-ops
status: candidate
---
## Runtime binding

This skill uses neutral verbs. Bind them to your runtime before executing:

| Neutral | Claude Code | Devin CLI |
|---|---|---|
| `DISPATCH` | `Agent` tool | `run_subagent` |
| `COLLECT` | result returned inline | `read_subagent` |
| `--role explorer` | `subagent_type: Explore` | `--profile subagent_explore` |
| `--role executor` | `subagent_type: general-purpose` | `--profile subagent_general` |
| `--background` | `run_in_background: true` | `--is_background true` |

Canonical table: `rules/skill-provider-neutrality.md`.

# Swarm Subagent

Dispatch parallel sub-agents using your runtime's sub-agent dispatch capability. Each agent gets a fresh context window, runs autonomously, writes results. Optional synthesis step combines all outputs. No SSH required — all agents run on the current machine.

## When to Use
- Task is decomposable into 2-6 independent lanes
- Single context window is too small for the full task
- Want agent diversity (`explorer` for read-only, `apex` for strategic assessment, `executor` for execution)
- SSH not available or not needed (all work on current machine)
- When `[swarm]` (SSH-based) is overkill or SSH connectivity is unavailable

### Pre-Dispatch 3-Gate Validation Test (OpenNash Heuristic)

Before dispatching a subagent, validate each proposed lane against the 3-gate test to avoid wasteful role-casting:

1. **Context Budget (10:1 Compression)**: Does the lane ingest large or diverse inputs and compress them by $\ge 10:1$ before returning to the parent orchestrator, preventing context window exhaustion?
2. **Permission Scope**: Does the lane require a distinct, isolated permission boundary (e.g. read-only sandboxed exploration vs. filesystem/git writes) that differs from the parent?
3. **Failure Containment**: Does the lane perform risky, non-deterministic, or crash-prone operations that must be isolated so that failure cannot crash or stall the parent session?

**Gate Rule**:
- **Dispatch as Subagent**: The lane passes **at least one** of the three gates. Do not block dispatch if any gate passes.
- **Run Inline**: The lane fails **all three** gates. Flag the lane as an **inline candidate** and execute it directly in the parent session.

*(Dry-run reference: A retrospective evaluation on the 5 ARCANA lens subagents shows they fail all three gates when applied to already-loaded text — context ratio < 10:1, identical read permissions, zero crash risk — correctly identifying them as inline candidates rather than dispatch candidates.)*

## Architecture

```
                    ┌─────────────┐
                    │  Orchestrator│  (this session)
                    │  writes prompts, launches, collects
                    └──────┬──────┘
                           │ fan-out (DISPATCH)     
              ┌────────────┼────────────┐
              ▼            ▼            ▼
         ┌─────────┐ ┌─────────┐ ┌─────────┐
         │ subagent_     │ subagent_     │ subagent_  │
         │ explore       │ apex          │ general       │
         │ (read-only)   │ (strategic)   │ (execution)   │
         └────┬────┘ └────┬────┘ └────┬────┘
              │            │            │
              ▼            ▼            ▼
         results/     results/     results/
         lane-1.md    lane-2.md    lane-3.md
                           │
                    ┌──────┴──────┐
                    │  Synthesizer │  (this session)
                    │  manual or agent
                    └─────────────┘
```

## Arguments
- `<task_description>` — High-level description of what the swarm should accomplish
- `--lanes N` — Number of parallel lanes (default: 4)
- `--roles <list>` — Comma-separated roles to use (default: explorer,apex,executor)
- `--synthesize` — Run synthesis step after all lanes complete
- `--persist` — Save results to `_state/swarm-reports/`
- `--bus` — Post SITREP summary to coordination bus

## Execution

### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=swarm-subagent] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

### 1. Decompose Task
Break the user's task into independent lanes. Each lane gets:
- A name (e.g., `nexus-codebase`, `apex-technical`, `apex-governance`)
- A role selection (`explorer` for read-only scans, `apex` for strategic assessment, `executor` for execution)
- A self-contained prompt (must include all context -- no shared state)

#### Lane Decomposition Strategy (evidence-based routing)

Choose the decomposition strategy based on task type. This routing rule is
backed by sandbox experiment `experiment-2026-07-26-lane-decomposition-task-type-interaction.md`
(interaction F=204, p=0.01; domain-based d=1.63 on cross-domain, d=0.09 on
single-domain, d=-0.37 on narrative).

| Task type | Strategy | Why |
|-----------|----------|-----|
| **Cross-domain synthesis** (risk audit, compliance review, strategic analysis, incident postmortem spanning security+governance+ops) | **Domain-based** (lanes = security, governance, operations, legal, research...) | Surfaces emergent cross-domain connections (d=1.63). Domain lanes naturally identify shared patterns and risks no single function would find. |
| **Single-domain deep** (code review, bug fix, perf profile, security scan of one module) | **Underpowered to distinguish** (d=0.09, 95% CI [-0.79, 0.97], only 6.5% power for small effects at n=10) | Study could not detect small/medium effects. Pick whichever is natural for the task — do not claim equivalence. |
| **Narrative** (documentation, blog post, explainer, executive summary, onboarding guide) | **Function-based** (lanes = research, outline, draft, edit/format) | Domain-based suffers a coherence penalty (d=-0.37) — parallel domain perspectives fragment the narrative. Function-based preserves linear flow. |

**How to classify**: If the task requires integrating findings from 3+ distinct
domains (security AND governance AND operations, etc.), use domain-based. If
the task is deep within one domain, either works. If the task's primary value
is coherent narrative output, use function-based.

**Mixed tasks**: If a task has both synthesis and narrative components
(e.g., "write a compliance audit report"), split into two phases: domain-based
lanes for the analysis phase, then a single function-based writing lane for
the narrative phase.

### 2. Write Prompt Files
For each lane, write a prompt file to `/tmp/swarm-subagent/`:
```bash
mkdir -p /tmp/swarm-subagent/prompts /tmp/swarm-subagent/results
```

Each prompt file should:
- Be fully self-contained (the subagent has no context from this session)
- Include the repo path on the target machine
- Include specific instructions and success criteria
- Include a git-state constraint: "Do not switch branches, create new branches, or run git checkout. Stay on the current branch." (the `executor` role has full git access; without this constraint, a subagent may switch branches in a shared repo and corrupt the orchestrator's working tree)
- Include the progress signal block (see step 4) so the orchestrator has live visibility
- End with: "Write your complete findings. Be concise and structured."

### 3. Launch Subagents
```bash
# Launch 4 parallel background subagents
DISPATCH --title "Lane 1" --task "$(cat /tmp/swarm-subagent/prompts/lane-1.md)" --role explorer --background
AGENT1=$!

DISPATCH --title "Lane 2" --task "$(cat /tmp/swarm-subagent/prompts/lane-2.md)" --role explorer --background
AGENT2=$!

DISPATCH --title "Lane 3" --task "$(cat /tmp/swarm-subagent/prompts/lane-3.md)" --role apex --background
AGENT3=$!

DISPATCH --title "Lane 4" --task "$(cat /tmp/swarm-subagent/prompts/lane-4.md)" --role apex --background
AGENT4=$!

echo "Launched: Agent $AGENT1, Agent $AGENT2, Agent $AGENT3, Agent $AGENT4"
```

### 4. Monitor Progress

**Live observability via swarm-signal.py** (mandatory for swarms of 2+ agents):

Each subagent prompt MUST include instructions to emit progress signals at milestones using `swarm-signal.py` (at `~/bin/swarm-signal.py` on Linux or `%USERPROFILE%\bin\swarm-signal.py` on Windows, stdlib-only, no deps). This gives the orchestrator and operator live visibility into what subagents are doing — without it, background subagents are black boxes that either return a result or hang silently.

The signal writes to a shared JSONL progress file AND posts a STATUS to the coordination bus. The orchestrator can read the progress file anytime:

```bash
# Tail the live progress file to see all subagent signals
tail -f /tmp/swarm-progress.jsonl
# Or on Windows:
Get-Content "$env:TEMP\swarm-progress.jsonl" -Wait -Tail 20
```

Progress file fields: `ts` (ISO 8601 UTC), `agent_id`, `role`, `phase`, `msg`, `host`, `pid`, `swarm_id` (optional).

**Add this block to every subagent prompt** (adapt agent-id and role per lane):

```
## Progress signals (mandatory)

Emit a progress signal at each milestone using swarm-signal.py:
  python ~/bin/swarm-signal.py --agent-id <lane-id> --role <role> --phase <phase> --msg "<message>" --swarm-id <swarm-id>

Phases: STARTED (begin), COMMAND_RUN (running a key command), FINDING (discovery), PHASE_COMPLETE (finished a sub-task), BLOCKED (stuck/needs input), DONE (finished).

Emit STARTED at the beginning, DONE at the end, and 1-3 signals in between at meaningful milestones. Keep msg under 200 chars. Do NOT emit secrets in msg.
```

```bash
# Check which agents are still running
COLLECT --id $AGENT1 --block false
COLLECT --id $AGENT2 --block false
COLLECT --id $AGENT3 --block false
COLLECT --id $AGENT4 --block false

# Check live progress signals (independent of COLLECT)
tail -5 /tmp/swarm-progress.jsonl 2>/dev/null || Get-Content "$env:TEMP\swarm-progress.jsonl" -Tail 5
```

### 5. Wait for Completion
```bash
# Block until all agents complete
COLLECT --id $AGENT1 --block true
COLLECT --id $AGENT2 --block true
COLLECT --id $AGENT3 --block true
COLLECT --id $AGENT4 --block true

echo "All lanes complete"
```

### 6. Collect Results
```bash
# Read each agent's output and save to results directory
COLLECT --id $AGENT1 --block true > /tmp/swarm-subagent/results/lane-1.md
COLLECT --id $AGENT2 --block true > /tmp/swarm-subagent/results/lane-2.md
COLLECT --id $AGENT3 --block true > /tmp/swarm-subagent/results/lane-3.md
COLLECT --id $AGENT4 --block true > /tmp/swarm-subagent/results/lane-4.md
```

### 7. Synthesize (if --synthesize)
```bash
# Create synthesis prompt
cat > /tmp/swarm-subagent/synthesis-prompt.md <<EOF
Synthesize these independent agent reports into a single coherent summary.
Resolve any contradictions. Highlight consensus findings.
Output a structured report with: Summary, Key Findings, Contradictions, Recommendations.

---

$(cat /tmp/swarm-subagent/results/lane-1.md)

---

$(cat /tmp/swarm-subagent/results/lane-2.md)

---

$(cat /tmp/swarm-subagent/results/lane-3.md)

---

$(cat /tmp/swarm-subagent/results/lane-4.md)
EOF

# Run synthesis (can use current agent or dispatch another)
# Option A: Manual synthesis by current agent
# Read synthesis-prompt.md and produce synthesis manually

# Option B: Dispatch synthesis agent
DISPATCH --title "Synthesis" --task "$(cat /tmp/swarm-subagent/synthesis-prompt.md)" --role executor --foreground
```

### 8. Persist Results (if --persist)
```bash
# Create timestamped report directory
TIMESTAMP=$(date -u +"%Y%m%d-%H%M%SZ")
REPORT_DIR="_state/swarm-reports/swarm-subagent-${TIMESTAMP}"
mkdir -p "$REPORT_DIR"

# Copy all results
cp /tmp/swarm-subagent/results/*.md "$REPORT_DIR/"

# Create summary index
cat > "$REPORT_DIR/INDEX.md" <<EOF
# Swarm Subagent Report | ${TIMESTAMP}

Operation: ${TASK_DESCRIPTION}
Lanes: ${N}
Profiles: ${PROFILES}
Synthesis: synthesis.md

## Artifacts
$(ls -1 "$REPORT_DIR"/*.md | sed 's/^/- /')
EOF

echo "Report persisted to: $REPORT_DIR"
```

### 9. Bus Integration (if --bus)
```bash
# Post SITREP summary to coordination bus
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
BUS_ENTRY="${TIMESTAMP}\t${AGENT_ID}\tall\tSITREP\tSwarm: ${TASK_DESCRIPTION} -- ${KEY_FINDING} + ${TOP_RECOMMENDATION}"

# Write to canonical bus (remote-node — dormant since 2026-07-01, use Workstation) or local mirror
if [ -n "$BUS_CANONICAL_BRIDGE_URL" ]; then
  curl -X POST "$BUS_CANONICAL_BRIDGE_URL" -d "$BUS_ENTRY"
else
  echo "$BUS_ENTRY" >> _state/coordination/messages.tsv
fi

echo "Bus entry posted"
```

## Output Format

```
Swarm Subagent | {task} | {N} lanes
═══════════════════════════════════════

## Lanes
| # | Name | Profile | Status | Output |
|---|------|---------|--------|--------|
| 1 | nexus-codebase | explorer | DONE (45s) | 2.1 KB |
| 2 | apex-technical | apex | DONE (32s) | 3.8 KB |
| 3 | apex-governance | apex | DONE (28s) | 4.2 KB |
| 4 | nexus-governance | explorer | DONE (35s) | 2.3 KB |

## Synthesis
{Combined findings from all lanes}

## Contradictions
{Where agents disagreed, if any}

## Recommendations
{Prioritized actions from combined analysis}

## Artifacts
- _state/swarm-reports/swarm-subagent-{timestamp}/lane-1.md
- _state/swarm-reports/swarm-subagent-{timestamp}/lane-2.md
- _state/swarm-reports/swarm-subagent-{timestamp}/lane-3.md
- _state/swarm-reports/swarm-subagent-{timestamp}/lane-4.md
- _state/swarm-reports/swarm-subagent-{timestamp}/synthesis.md
```

## Predefined Swarm Patterns

### "NEXUS-APEX Assessment" (4 lanes)
```
Lane 1 (explorer): NEXUS codebase scan
Lane 2 (explorer): NEXUS governance scan
Lane 3 (apex): APEX technical assessment
Lane 4 (apex): APEX governance assessment
Synthesize: Cross-surface analysis with contradictions and recommendations
```

### "Full Surface Scan" (3 lanes)
```
Lane 1 (explorer): Rules and agents scan
Lane 2 (explorer): Skills and memory scan
Lane 3 (explorer): Architecture and ADR scan
Synthesize: Surface consistency report
```

### "Dual Assessment" (2 lanes)
```
Lane 1 (apex): Technical posture assessment
Lane 2 (apex): Governance maturity assessment
Synthesize: Combined health score with prioritized risks
```

## Constraints

- Max 5 concurrent subagents (canonical fleet cap enforced by subagent-quota hook; wave limits up to 10)
- Each subagent consumes its own context window independently
- Prompts must be self-contained -- subagents cannot access this session's context
- Subagents run on current machine only (no cross-machine dispatch)
- Results in /tmp/swarm-subagent/ are ephemeral -- **automatically persisted to `_state/swarm-reports/` if --persist flag used**
- **Bus integration**: If --bus flag used, posts SITREP summary to coordination bus after synthesis

## Differences from [swarm]

| Feature | [swarm] | [swarm-subagent] |
|---------|--------|----------------|
| Dispatch method | SSH + remote CLI | in-process dispatch |
| Cross-machine | Yes (via SSH) | No (current machine only) |
| API credit | Required (claude -p) | Not required (free subagents) |
| Selection | Model tier (large/mid/small) | Agent roles (explorer/apex/executor) |
| Use case | Cross-machine GPU/inference | Read-only scans, strategic assessments |

## Rate-limit discipline

Per `~/.agents/rules/staggered-subagent-deploy-rate-limit.md`:

- **Default stagger**: 350ms between subagent launches (jittered ±50ms)
- **Default concurrency cap**: 5
- **Override env vars**: `STAGGER_MS` (set to 0 to disable), `SWARM_SUBAGENT_CONCURRENCY`
- **On 429 / spend-cap**: stop further spawns to that provider, post bus `BLOCKED` identifying limiter (RPM/ITPM/OTPM/SPEND_CAP), retry with exponential backoff (1s, 2s, 4s, 8s, cap 60s)
- **Override logging**: every `STAGGER_MS=0` or `CONCURRENCY_OVERRIDE` use posts a bus STATUS

## Lexicon

This skill uses the canonical swarm lexicon (`~/.agents/rules/swarm-lexicon.md`).
Key terms: swarm, wave, batch, lane, orchestrator, fan-out, fan-in,
progress signal. Conflicts between this skill's local vernacular and the lexicon
resolve in favor of the lexicon.

## Skill Chains
- For inference for subagent tasks -> `[reasoning-router]` (`python ~/bin/reasoning_router.py route`)

### Mandatory

- `[swarm-manifest]` SHOULD be generated first — provides lane allocation, budget estimation, and pre-flight checks for the dispatch.

### Advisory

- → `[retrospective]` (review swarm effectiveness after completion)
- → `[decision-log]` (record findings after synthesis)
- → `[evidence-pack]` (bundle results for external use)
- → `[nexus]` (canonical-surface verification after surface scan)
- → `[govern]` (compliance surge mode after governance swarm)
- → `[cross-runtime-bridge]` for lanes needing opencode runtime (`python ~/bin/cross_runtime_bridge.py delegate "<task>" --workdir <dir> --auto`)

## Authority

- **T1 (TRUSTED)**: May run with `[swarm-manifest]`
- **T2 (Active/High)**: May run with `[swarm-manifest]`
- **T3 (Medium)**: Operator approval required + `[swarm-manifest]`
- **T4 (Probationary)**: BLOCKED (multi-agent dispatch)
- **Operator**: Override any restriction
