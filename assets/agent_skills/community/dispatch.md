---
name: dispatch
description: Spawn parallel subagents for decomposable work.
version: 0.1.0
execution-mode: side_effecting
meta-skill: dispatch
meta-skill-mode: invocation-time
meta-skill-topology: fan
argument-hint: <task description to decompose>
category: fleet-ops
status: candidate
---
# Dispatch Command

## When to Use
- Task has 3+ independent subtasks that can run in parallel
- Research across multiple topics simultaneously
- Running multiple audits at once
- Any "do X, Y, and Z" where X, Y, Z are independent
Analyze a task, decompose it into independent subtasks, and spawn parallel agents.

## Usage

```bash
[dispatch] Research all 7 adapter error handling patterns
[dispatch] Run security scan, coverage report, and health check simultaneously
[dispatch] Audit all test files for missing edge cases
```

## Delegation Contract

Information flows are strictly one-directional:

1. **Context goes DOWN**: Each subagent receives an explicit, self-contained prompt with all necessary context. No shared state, no implicit assumptions.
2. **Summary comes UP**: Each subagent returns a concise result (target: 300 words max). The parent never sees the subagent's internal back-and-forth.
3. **No shared memory during execution**: Subagents do not read or write to the cognitive ledger, coordination bus, or shared state during their task. They operate in isolation.

This contract keeps the parent's context window efficient and prevents cross-contamination between subtasks.

## Execution

### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=dispatch] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

### 1. Load project context (parent does this, not subagents)
Read `~/.claude/projects/-Users-others/SUBAGENT_CONTEXT.md`. Prepend its full content to the top of every subagent prompt you construct. Subagents receive this as static context — they do not read files themselves during cold-start. This eliminates the 3-5 message orientation tax each subagent would otherwise spend learning the repo layout, constraints, and machine fleet.

### 2. Analyze the task
Break `$ARGUMENTS` into independent subtasks. Each subtask must be:
- Self-contained (no dependency on other subtask results)
- Clearly scoped (specific files, modules, or questions)
- Completable in a single agent turn

#### Decomposition strategy (evidence-based)

Choose domain-based vs function-based lanes by task type. Backed by sandbox
experiment `experiment-2026-07-26-lane-decomposition-task-type-interaction.md`
(interaction F=204, p=0.01; domain-based d=1.63 on cross-domain synthesis,
d=0.09 on single-domain, d=-0.37 on narrative).

- **Cross-domain synthesis** (risk audit, compliance, strategic analysis spanning 3+ domains) → **domain-based** lanes (security, governance, ops, legal...)
- **Single-domain deep** (code review, bug fix, perf profile) → **underpowered to distinguish** (d=0.09, 95% CI [-0.79, 0.97], n=10). Pick whichever is natural — do not claim equivalence.
- **Narrative** (docs, blog post, exec summary, onboarding) → **function-based** lanes (research, outline, draft, edit)

See `swarm-subagent` SKILL.md for full routing table and mixed-task guidance.

### 3. Present the decomposition
Show the user the proposed subtasks before launching:

```
Dispatch Plan | <task summary>
═══════════════════════════════

Subtasks:
1. [Explore] Audit GitHub adapter error paths
2. [Explore] Audit Calendar adapter error paths
3. [Explore] Audit Linear adapter error paths
...

Launch N parallel agents? [Y/n]
```

### 4. Launch agents
Use the `Agent` tool with appropriate `subagent_type`:
- `Explore` for codebase research and file analysis
- `general-purpose` for mixed research tasks
- `general-purpose` for complex multi-step tasks requiring web access

Every subagent prompt MUST end with:
> Return a concise summary of your findings (300 words max). Lead with conclusions, then supporting evidence. Do not include your internal reasoning steps.

### 5. Collect results
Wait for all agents to complete, then synthesize results into a unified report. Do not pass raw subagent output to the user -- synthesize across all subtasks.

### 6. Post to bus
Post a completion summary to the coordination bus.
```
Type: MILESTONE
To: all
Message: Dispatch complete: <summary>
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

## Output Format

```
Dispatch Results | <task summary>
═════════════════════════════════

## Subtask 1: <name>
<synthesized findings>

## Subtask 2: <name>
<synthesized findings>

...

## Summary
<unified conclusions across all subtasks>
```

## Rate-limit discipline

Per `~/.agents/rules/staggered-subagent-deploy-rate-limit.md`:

- **Default stagger**: 300ms between sub-agent launches (jittered ±50ms)
- **Default concurrency cap**: 5
- **Override env vars**: `STAGGER_MS` (set to 0 to disable), `DISPATCH_CONCURRENCY`
- **On 429 / spend-cap**: stop further spawns, post bus `BLOCKED` identifying limiter (RPM/ITPM/OTPM/SPEND_CAP), retry with exponential backoff (1s, 2s, 4s, 8s, cap 60s)
- **Override logging**: every `STAGGER_MS=0` or `CONCURRENCY_OVERRIDE` use posts a bus STATUS

## Constraints

- **Maximum 5 parallel agents.** If more subtasks exist, batch them.
- Always show the decomposition plan and get user approval before launching.
- Each agent gets a clear, self-contained prompt with all necessary context.
- Each agent prompt ends with the output budget instruction (300 words max).
- Do not launch agents for trivially sequential work (use direct execution instead).
- Post completion to the coordination bus.
- **Never pass subagent raw output directly to the user.** Always synthesize.

## Lexicon

This skill uses the canonical swarm lexicon (`~/.agents/rules/swarm-lexicon.md`).
Key terms: swarm, batch, lane, orchestrator, fan-out, delegation contract,
orientation tax. Conflicts between this skill's local vernacular and the lexicon
resolve in favor of the lexicon.

## Skill Chains

### Mandatory

- None — dispatch is the orchestration layer. The user approval gate (step 3)
  is the built-in mandatory check.

### Advisory

- **After dispatch**: `[retrospective]` (review effectiveness), `[decision-log]` (record findings)
- **For cross-machine**: `[swarm]` (machine-level fan-out, not session-level)

## Authority

- **T1 (TRUSTED)**: May dispatch with user approval (built-in gate)
- **T2 (Active/High)**: May dispatch with user approval (built-in gate)
- **T3 (Medium)**: MUST get operator approval (the built-in gate satisfies this)
- **T4 (Probationary)**: BLOCKED — cannot invoke this skill (spawns parallel agents)
- **Operator**: Override any restriction
